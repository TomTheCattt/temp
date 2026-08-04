//
//  RequestInterceptor.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 26/7/26.
//

import Alamofire
import Foundation
import OSLog

// MARK: - AuthInterceptor

final class AuthInterceptor: @preconcurrency RequestInterceptor, Sendable {
    private let authManager: AuthManagerProtocol
    private let logger = AppLogger.network
    
    init(authManager: AuthManagerProtocol) {
        self.authManager = authManager
    }
    
    // MARK: - Adapt
    
    @MainActor func adapt(_ urlRequest: URLRequest,
               for session: Session,
               completion: @escaping (Result<URLRequest, any Error>) -> Void) {
        var request = urlRequest
        if let token = authManager.accessToken {
            request.setValue("Bearer \(token)",
                             forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(AppConfig.shared.clientVersion, forHTTPHeaderField: "X-Client-Version")
        request.setValue(AppConfig.shared.environment.rawValue, forHTTPHeaderField: "X-Environment")
        completion(.success(request))
    }
    
    // MARK: Retry

    func retry(_ request: Request,
               for session: Session,
               dueTo error: Error,
               completion: @escaping (RetryResult) -> Void) {
        guard
            let response = request.task?.response as? HTTPURLResponse,
            response.statusCode == 401,
            request.retryCount == 0
        else {
            completion(.doNotRetry)
            return
        }

        let completionBox = RetryCompletionBox(completion)
        Task { [authManager, logger] in
            do {
                // refreshToken() is NOT @MainActor — safe to call from background Task
                try await authManager.refreshToken()
                await completionBox.call(.retry)
            } catch {
                await logger.error("Token refresh failed: \(error.localizedDescription)")
                // logout() IS @MainActor — switch explicitly
                await MainActor.run { authManager.logout() }
                await completionBox.call(.doNotRetryWithError(APIError.unauthorized))
            }
        }
    }
}

private final class RetryCompletionBox: @unchecked Sendable {
    let call: (RetryResult) -> Void

    init(_ call: @escaping (RetryResult) -> Void) {
        self.call = call
    }
}

// MARK: - NetworkEventMonitor

// MARK: - Sendable rationale
// NetworkEventMonitor is @unchecked Sendable because:
// - `logger` (Logger/OSLog) is Sendable by design.
// - `isEnabled` (Bool) is a value type, set once at init, never mutated.
// - No mutable shared state — all EventMonitor methods are read-only callbacks.
final class NetworkEventMonitor: EventMonitor, @unchecked Sendable {
    private let logger = AppLogger.network
    private let isEnabled: Bool

    init() {
        isEnabled = true
    }

    func requestDidResume(_ request: Request) {
        guard isEnabled else { return }
        guard let urlRequest = request.request else {
            logger.debug("⬆️ [REQUEST] started with no URLRequest")
            return
        }
        let method = urlRequest.httpMethod ?? "UNKNOWN"
        let url = urlRequest.url?.absoluteString ?? "unknown"
        let headers = urlRequest.allHTTPHeaderFields ?? [:]
        let body = requestBodyString(from: urlRequest) ?? "<empty>"
        logger.info("⬆️ [REQUEST] \(method) \(url)")
        logger.debug("⬆️ [REQUEST] headers=\(headers)")
        logger.debug("⬆️ [REQUEST] body=\(body)")
    }

    func requestDidFinish(_ request: Request) {
        // Intentionally left empty — response logging is handled in didParseResponse
    }

    func request<Value>(_ request: DataRequest,
                        didParseResponse response: DataResponse<Value, AFError>) {
        guard isEnabled else { return }
        let code = response.response?.statusCode ?? 0
        let method = request.request?.httpMethod ?? "UNKNOWN"
        let url = request.request?.url?.absoluteString ?? "unknown"
        let body: String
        if let data = response.data, let string = String(data: data, encoding: .utf8) {
            body = string
        } else {
            body = "<empty>"
        }
        if let error = response.error {
            logger.error("⬇️ [RESPONSE] \(method) \(url) [\(code)] ❌ error=\(error.localizedDescription)")
            logger.debug("⬇️ [RESPONSE] body=\(body)")
        } else {
            logger.info("⬇️ [RESPONSE] \(method) \(url) [\(code)] ✅")
            logger.debug("⬇️ [RESPONSE] body=\(body)")
        }
    }

    private func requestBodyString(from request: URLRequest) -> String? {
        if let body = request.httpBody, !body.isEmpty {
            return String(data: body, encoding: .utf8)
        }
        if let query = request.url?.query, !query.isEmpty {
            return query
        }
        return nil
    }
}

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
    private let authManagerProvider: @Sendable () -> AuthManagerProtocol?
    private let logger = AppLogger.network

    init(authManagerProvider: @escaping @Sendable () -> AuthManagerProtocol?) {
        self.authManagerProvider = authManagerProvider
    }

    // MARK: - Adapt

    @MainActor func adapt(_ urlRequest: URLRequest,
               for session: Session,
               completion: @escaping (Result<URLRequest, any Error>) -> Void) {
        var request = urlRequest
        if let authManager = authManagerProvider(),
           let token = authManager.accessToken {
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
        Task { [authManagerProvider, logger] in
            guard let authManager = authManagerProvider() else {
                logger.error("AuthManager not available for token refresh")
                await completionBox.call(.doNotRetryWithError(APIError.unauthorized))
                return
            }
            do {
                // refreshToken() is NOT @MainActor — safe to call from background Task
                try await authManager.refreshToken()
                await completionBox.call(.retry)
            } catch {
                logger.error("Token refresh failed: \(error.localizedDescription)")
                // logout() IS @MainActor — switch explicitly
                await MainActor.run { authManager.logout(reason: .sessionExpired) }
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
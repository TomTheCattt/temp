//
//  NetworkEventMonitor.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 26/7/26.
//

import Alamofire
import Foundation
import OSLog

// MARK: - NetworkEventMonitor (Enhanced)

/// Enhanced network event monitor with structured logging
/// Logs requests/responses with timing, parameters, headers, and pretty JSON
final class NetworkEventMonitor: EventMonitor, @unchecked Sendable {
    private let logger = AppLogger.network
    private let isEnabled: Bool
    private var requestStartTimes: [UUID: Date] = [:]
    private let lock = NSLock()

    init() {
        self.isEnabled = true
    }

    func requestDidResume(_ request: Request) {
        guard isEnabled else { return }
        guard let urlRequest = request.request else {
            logger.debug("⬆️ [REQUEST] started with no URLRequest")
            return
        }

        let requestId = request.id
        lock.lock()
        requestStartTimes[requestId] = Date()
        lock.unlock()

        logger.logRequest(urlRequest)
    }

    func requestDidFinish(_ request: Request) {
        // Response logging handled in didParseResponse
    }

    func request<Value>(_ request: DataRequest, didParseResponse response: DataResponse<Value, AFError>) {
        guard isEnabled else { return }

        let requestId = request.id
        let startTime: Date? = {
            lock.lock()
            defer { lock.unlock() }
            let time = requestStartTimes[requestId]
            requestStartTimes.removeValue(forKey: requestId)
            return time
        }()

        let latency = startTime.map { Date().timeIntervalSince($0) }
        logger.logResponse(
            request: request.request,
            response: response.response,
            data: response.data,
            error: response.error,
            latency: latency
        )
    }
}
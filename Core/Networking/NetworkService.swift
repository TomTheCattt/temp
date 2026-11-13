//
 //  NetworkService.swift
 //  Instagram
 //
 //  Created by Kiro on 26/7/26.
 //

import Foundation
import Alamofire
import Combine

// Empty response for error envelope decoding
nonisolated struct EmptyResponse: Decodable, Sendable {}

// MARK: - Circuit Breaker State

actor CircuitBreaker {
    enum State: Sendable {
        case closed
        case open(openedAt: Date)
        case halfOpen
    }

    private let policy: CircuitBreakerPolicy
    private var state: State = .closed
    private var failureCount = 0
    private var successCount = 0

    init(policy: CircuitBreakerPolicy) {
        self.policy = policy
    }

    var currentState: State { state }

    func recordSuccess() {
        switch state {
        case .closed:
            failureCount = 0
        case .halfOpen:
            successCount += 1
            if successCount >= policy.successThreshold {
                state = .closed
                failureCount = 0
                successCount = 0
            }
        case .open:
            break
        }
    }

    func recordFailure() {
        switch state {
        case .closed:
            failureCount += 1
            if failureCount >= policy.failureThreshold {
                state = .open(openedAt: Date())
            }
        case .halfOpen:
            state = .open(openedAt: Date())
            successCount = 0
        case .open(let openedAt):
            if Date().timeIntervalSince(openedAt) >= policy.timeout {
                state = .halfOpen
                successCount = 0
            }
        }
    }

    func canExecute() -> Bool {
        switch state {
        case .closed: return true
        case .halfOpen: return true
        case .open(let openedAt):
            if Date().timeIntervalSince(openedAt) >= policy.timeout {
                return true
            }
            return false
        }
    }

    func reset() {
        state = .closed
        failureCount = 0
        successCount = 0
    }
}

// MARK: - Rate Limiter (Token Bucket)

actor RateLimiter {
    private let policy: RateLimitPolicy
    private var tokens: Double
    private var lastRefill: Date

    init(policy: RateLimitPolicy) {
        self.policy = policy
        self.tokens = Double(policy.maxRequestsPerWindow)
        self.lastRefill = Date()
    }

    func acquire() async -> TimeInterval {
        refill()
        if tokens >= 1 {
            tokens -= 1
            return 0
        }
        // Calculate wait time for next token
        let tokensNeeded = 1 - tokens
        let waitTime = (tokensNeeded / Double(policy.maxRequestsPerWindow)) * policy.windowDuration
        tokens = 0
        return waitTime
    }

    private func refill() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastRefill)
        if elapsed >= policy.windowDuration {
            tokens = Double(policy.maxRequestsPerWindow)
            lastRefill = now
        } else {
            let tokensToAdd = (elapsed / policy.windowDuration) * Double(policy.maxRequestsPerWindow)
            tokens = min(Double(policy.maxRequestsPerWindow), tokens + tokensToAdd)
        }
    }

    func reset() {
        tokens = Double(policy.maxRequestsPerWindow)
        lastRefill = Date()
    }
}

// MARK: - Request Deduplication

struct DeduplicatedResponse: Sendable {
    let data: Data
    let statusCode: Int
    let etag: String?
    let lastModified: String?
}

actor RequestDeduplicator {
    private var pendingRequests: [String: Task<DeduplicatedResponse, Error>] = [:]
    private let logger = AppLogger.network

    func deduplicate(
        key: String,
        factory: @escaping @Sendable () async throws -> DeduplicatedResponse
    ) async throws -> DeduplicatedResponse {
        if let existingTask = pendingRequests[key] {
            logger.debug("Deduplicating request: \(key)")
            do {
                return try await existingTask.value
            } catch {
                // If existing task failed, remove it and create new one
                pendingRequests.removeValue(forKey: key)
            }
        }

        let task = Task<DeduplicatedResponse, Error> {
            try await factory()
        }
        pendingRequests[key] = task

        do {
            let result = try await task.value
            pendingRequests.removeValue(forKey: key)
            return result
        } catch {
            pendingRequests.removeValue(forKey: key)
            throw error
        }
    }

    func cancel(key: String) {
        pendingRequests[key]?.cancel()
        pendingRequests.removeValue(forKey: key)
    }

    func cancelAll() {
        for (_, task) in pendingRequests {
            task.cancel()
        }
        pendingRequests.removeAll()
    }
}

// MARK: - Network Metrics

struct NetworkMetrics: Sendable {
    let requestCount: Int
    let successCount: Int
    let failureCount: Int
    let totalLatency: TimeInterval
    let averageLatency: TimeInterval
    let lastRequestTime: Date?
    let lastError: String?

    nonisolated static let empty = NetworkMetrics(
        requestCount: 0,
        successCount: 0,
        failureCount: 0,
        totalLatency: 0,
        averageLatency: 0,
        lastRequestTime: nil,
        lastError: nil
    )
}

actor MetricsCollector {
    private var metrics = NetworkMetrics.empty

    func recordRequest(latency: TimeInterval, success: Bool, error: String? = nil) {
        let newCount = metrics.requestCount + 1
        let newSuccessCount = metrics.successCount + (success ? 1 : 0)
        let newFailureCount = metrics.failureCount + (success ? 0 : 1)
        let newTotalLatency = metrics.totalLatency + latency
        let newAverageLatency = newTotalLatency / Double(newCount)

        metrics = NetworkMetrics(
            requestCount: newCount,
            successCount: newSuccessCount,
            failureCount: newFailureCount,
            totalLatency: newTotalLatency,
            averageLatency: newAverageLatency,
            lastRequestTime: Date(),
            lastError: error
        )
    }

    func getMetrics() -> NetworkMetrics {
        metrics
    }

    func reset() {
        metrics = NetworkMetrics.empty
    }
}

// MARK: - Response Cache (ETag/If-None-Match)

struct CachedResponse: Sendable {
    let data: Data
    let etag: String?
    let lastModified: String?
    let timestamp: Date
    let statusCode: Int
}

actor ResponseCache {
    private var cache: [String: CachedResponse] = [:]
    private let maxSize: Int
    private let logger = AppLogger.network

    init(maxSize: Int = 100) {
        self.maxSize = maxSize
    }

    func get(key: String) -> CachedResponse? {
        cache[key]
    }

    func set(key: String, response: CachedResponse) {
        if cache.count >= maxSize {
            // Remove oldest entry
            if let oldestKey = cache.min(by: { $0.value.timestamp < $1.value.timestamp })?.key {
                cache.removeValue(forKey: oldestKey)
            }
        }
        cache[key] = response
    }

    func remove(key: String) {
        cache.removeValue(forKey: key)
    }

    func clear() {
        cache.removeAll()
    }

    func getConditionalHeaders(key: String) async -> (etag: String?, lastModified: String?) {
        await Task.yield()
        guard let cached = cache[key] else { return (nil, nil) }
        return (cached.etag, cached.lastModified)
    }

    var count: Int { cache.count }
}

// MARK: - Offline Request Queue

struct OfflineRequest: Sendable {
    let id: UUID
    let endpoint: APIEndpoint
    let endpointPath: String
    let priority: RequestPriority
    let timestamp: Date
    let retryCount: Int
    let operationType: OperationType

    enum OperationType: String, Sendable {
        case request
        case requestEnvelope
        case requestEnvelopeWithResponse
        case requestVoid
        case upload
    }
}

actor OfflineQueue {
    private var queue: [OfflineRequest] = []
    private let maxSize = 100
    private let logger = AppLogger.network

    func enqueue(_ request: OfflineRequest) {
        if queue.count >= maxSize {
            // Remove oldest request
            queue.removeFirst()
        }
        queue.append(request)
        logger.info("Offline request queued: \(request.operationType.rawValue) \(request.endpointPath) (queue size: \(queue.count))")
    }

    func dequeue() -> OfflineRequest? {
        queue.popLast()
    }

    func getAll() -> [OfflineRequest] {
        queue
    }

    func clear() {
        queue.removeAll()
    }

    /// Process all queued requests with a handler
    /// - Parameter handler: Async closure that takes an OfflineRequest and returns whether it succeeded
    func processQueue(handler: @Sendable @escaping (OfflineRequest) async throws -> Bool) async {
        let requests = queue
        queue.removeAll()

        for request in requests {
            do {
                let success = try await handler(request)
                if !success {
                    // Re-queue failed requests
                    queue.append(request)
                    logger.notice("Offline request failed, re-queued: \(request.endpointPath)")
                } else {
                    logger.info("Offline request succeeded: \(request.endpointPath)")
                }
            } catch {
                // Re-queue on error
                queue.append(request)
                logger.error("Offline request error, re-queued: \(request.endpointPath), error: \(error.localizedDescription)")
            }
        }
    }

    var count: Int { queue.count }
    var isEmpty: Bool { queue.isEmpty }
}

// MARK: - Request Priority Queue

actor RequestPriorityQueue {
    private struct QueueItem: Sendable {
        let priority: RequestPriority
        let operation: @Sendable () async throws -> Any
        let resume: @Sendable (Any) -> Void
        let resumeThrowing: @Sendable (Error) -> Void
    }

    private var queue: [QueueItem] = []
    private var activeCount = 0
    private let maxConcurrent = 6

    func enqueue<T: Sendable>(priority: RequestPriority, operation: @Sendable @escaping () async throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            let item = QueueItem(
                priority: priority,
                operation: { try await operation() },
                resume: { continuation.resume(returning: $0 as! T) },
                resumeThrowing: { continuation.resume(throwing: $0) }
            )
            queue.append(item)
            queue.sort { $0.priority.rawValue > $1.priority.rawValue } // Higher priority first
            processQueue()
        }
    }

    private func processQueue() {
        while activeCount < maxConcurrent && !queue.isEmpty {
            let item = queue.removeFirst()
            activeCount += 1

            Task {
                do {
                    let result = try await item.operation()
                    item.resume(result)
                } catch {
                    item.resumeThrowing(error)
                }
                activeCount -= 1
                processQueue()
            }
        }
    }
}

// MARK: - NetworkServiceProtocol

protocol NetworkServiceProtocol: Sendable {

    /// The underlying Alamofire Session for custom requests.
    var session: Session { get }

    /// The JSON decoder used for decoding responses.
    var decoder: JSONDecoder { get }

    /// Perform a request and decode the response into `T`.
    nonisolated func request<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint
    ) async throws -> sending T

    /// Perform a request expecting the standard server envelope `APIEnvelope<T>`,
    /// and return only the `data` field.
    nonisolated func requestEnvelope<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint
    ) async throws -> sending T

    /// Perform a request expecting the standard server envelope `APIEnvelope<T>`,
    /// and return both the `data` field and the HTTP response for header/cookie extraction.
    nonisolated func requestEnvelopeWithResponse<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint
    ) async throws -> (data: T, response: HTTPURLResponse)

    /// Perform a request with no expected response body (e.g. DELETE, 204).
    nonisolated func requestVoid(
        _ endpoint: APIEndpoint
    ) async throws

    /// Perform a request with no expected response body, returning a Combine publisher.
    nonisolated func requestVoidPublisher(
        _ endpoint: APIEndpoint
    ) -> AnyPublisher<Void, APIError>

    /// Perform a request expecting the standard server envelope `APIEnvelope<T>`,
    /// and return only the `data` field as a Combine publisher.
    nonisolated func requestEnvelopePublisher<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint
    ) -> AnyPublisher<T, APIError>

    /// Upload multipart form data, returning a Combine publisher.
    nonisolated func requestMultipart<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        data: Data,
        offset: Int64
    ) -> AnyPublisher<T, APIError>

    /// Upload multipart form data.
    nonisolated func upload<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        multipartFormData: @Sendable @escaping (MultipartFormData) -> Void
    ) async throws -> sending T

    /// Download a file to a temporary URL.
    func download(
        _ endpoint: APIEndpoint,
        to destination: DownloadRequest.Destination?
    ) async throws -> URL

    /// Get current network metrics
    func getMetrics() async -> NetworkMetrics

    /// Get current cache metrics
    func getCacheMetrics() async -> (count: Int, maxSize: Int)

    /// Process queued offline requests when network is restored
    func processOfflineQueue() async

    /// Refresh access token using refresh token in Cookie header (Better Auth)
    /// - Parameter refreshToken: The refresh token to send in Cookie header
    /// - Returns: RefreshTokenDTO with new accessToken, optional refreshToken, and expiresAt
    func refreshAccessToken(refreshToken: String) async throws -> RefreshTokenDTO
}

// MARK: - NetworkService

final class NetworkService: NetworkServiceProtocol, @unchecked Sendable {

    let session: Session
    let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
        return decoder
    }()

    private let logger = AppLogger.network
    private let config = AppConfig.shared

    // Network resilience components
    private let circuitBreaker: CircuitBreaker
    private let rateLimiter: RateLimiter
    private let deduplicator: RequestDeduplicator
    private let metricsCollector: MetricsCollector
    private let responseCache: ResponseCache
    private let offlineQueue = OfflineQueue()

    // Request prioritization queue
    private let requestQueue = RequestPriorityQueue()
    private let maxConcurrentRequests = 6
    private var activeRequestCount = 0

    init(session: Session) {
        self.session = session
        self.circuitBreaker = CircuitBreaker(policy: config.circuitBreakerPolicy)
        self.rateLimiter = RateLimiter(policy: config.rateLimitPolicy)
        self.deduplicator = RequestDeduplicator()
        self.metricsCollector = MetricsCollector()
        self.responseCache = ResponseCache(maxSize: 100)
    }

    /// Process queued offline requests when network is restored
    func processOfflineQueue() async {
        await offlineQueue.processQueue { [weak self] request in
            guard let self = self else { return false }

            do {
                switch request.operationType {
                case .request:
                    let _: (data: EmptyResponse, response: HTTPURLResponse?) = try await self.executeWithRetry(
                        endpoint: request.endpoint,
                        priority: request.priority
                    ) { [weak self] in
                        guard let self = self else { throw APIError.unknown(nil) }
                        // Execute request without caring about decoded data
                        let urlRequest = try request.endpoint.asURLRequest()
                        let dataResponse = await self.session
                            .request(urlRequest)
                            .validate(statusCode: 200..<300)
                            .serializingData()
                            .response
                        guard dataResponse.error == nil else {
                            throw self.mapError(dataResponse.error!, response: dataResponse.response)
                        }
                        return (EmptyResponse(), dataResponse.response)
                    }
                    return true
                case .requestEnvelope:
                    let _: (data: EmptyResponse, response: HTTPURLResponse?) = try await self.executeWithRetry(
                        endpoint: request.endpoint,
                        priority: request.priority
                    ) { [weak self] in
                        guard let self = self else { throw APIError.unknown(nil) }
                        let urlRequest = try request.endpoint.asURLRequest()
                        let dataResponse = await self.session
                            .request(urlRequest)
                            .validate(statusCode: 200..<300)
                            .serializingData()
                            .response
                        guard dataResponse.error == nil else {
                            throw self.mapError(dataResponse.error!, response: dataResponse.response)
                        }
                        return (EmptyResponse(), dataResponse.response)
                    }
                    return true
                case .requestEnvelopeWithResponse:
                    let _: (data: EmptyResponse, response: HTTPURLResponse?) = try await self.executeWithRetry(
                        endpoint: request.endpoint,
                        priority: request.priority
                    ) { [weak self] in
                        guard let self = self else { throw APIError.unknown(nil) }
                        let urlRequest = try request.endpoint.asURLRequest()
                        let dataResponse = await self.session
                            .request(urlRequest)
                            .validate(statusCode: 200..<300)
                            .serializingData()
                            .response
                        guard dataResponse.error == nil else {
                            throw self.mapError(dataResponse.error!, response: dataResponse.response)
                        }
                        return (EmptyResponse(), dataResponse.response)
                    }
                    return true
                case .requestVoid:
                    let _: (data: EmptyResponse, response: HTTPURLResponse?) = try await self.executeWithRetry(
                        endpoint: request.endpoint,
                        priority: request.priority
                    ) { [weak self] in
                        guard let self = self else { throw APIError.unknown(nil) }
                        return try await self.performVoidRequest(request.endpoint)
                    }
                    return true
                case .upload:
                    // Note: Upload requests would need multipart form data which we don't store
                    // For now, skip upload requests in offline queue
                    self.logger.notice("Upload request in offline queue not supported, skipping: \(request.endpointPath)")
                    return false
                }
            } catch {
                self.logger.error("Failed to process offline request: \(request.endpointPath), error: \(error.localizedDescription)")
                return false
            }
        }
    }

    // MARK: - Request Queue Processing

    private func enqueueRequest<T: Decodable & Sendable>(
        endpoint: APIEndpoint,
        priority: RequestPriority,
        operation: @Sendable @escaping () async throws -> (data: T, response: HTTPURLResponse?)
    ) async throws -> (data: T, response: HTTPURLResponse?) {
        return try await requestQueue.enqueue(priority: priority) { [weak self] in
            guard let self = self else { throw APIError.unknown(nil) }
            return try await self.executeWithRetry(endpoint: endpoint, priority: priority, operation: operation)
        }
    }

    // MARK: - Request with Retry Logic

    private func executeWithRetry<T: Decodable & Sendable>(
        endpoint: APIEndpoint,
        priority: RequestPriority = .normal,
        operation: @Sendable @escaping () async throws -> (data: T, response: HTTPURLResponse?)
    ) async throws -> (data: T, response: HTTPURLResponse?) {

        let retryPolicy = config.retryPolicy
        var attempt = 0

        while true {
            attempt += 1

            // Check circuit breaker
            let canExecute = await circuitBreaker.canExecute()
            if !canExecute {
                logger.notice("Circuit breaker open, rejecting request to \(endpoint.path)")
                throw APIError.networkError(NSError(domain: "CircuitBreaker", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service temporarily unavailable"]))
            }

            // Rate limiting
            let waitTime = await rateLimiter.acquire()
            if waitTime > 0 {
                logger.debug("Rate limited, waiting \(waitTime)s")
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }

            let startTime = Date()

            do {
                let result = try await operation()

                let latency = Date().timeIntervalSince(startTime)
                await circuitBreaker.recordSuccess()
                await metricsCollector.recordRequest(latency: latency, success: true)

                // Log slow requests
                if latency > 5.0 {
                    logger.notice("Slow request: \(endpoint.path) took \(String(format: "%.2f", latency))s")
                }

                return result

            } catch {
                let latency = Date().timeIntervalSince(startTime)
                await circuitBreaker.recordFailure()
                await metricsCollector.recordRequest(latency: latency, success: false, error: error.localizedDescription)

                // Check if we should retry
                var shouldRetry = retryPolicy.shouldRetry(attempt: attempt, error: error)
                // Also check for AFError with retryable status codes
                if !shouldRetry,
                   let afError = error as? AFError,
                   let statusCode = afError.responseCode,
                   retryPolicy.retryableStatusCodes.contains(statusCode) {
                    shouldRetry = true
                }
                if shouldRetry {
                    let delay = retryPolicy.delay(for: attempt)
                    logger.info("Request failed (attempt \(attempt)/\(retryPolicy.maxAttempts)), retrying in \(String(format: "%.2f", delay))s: \(error.localizedDescription)")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }

                // No more retries, check if we should queue for offline retry
                let isNetworkError = error is URLError && (error as! URLError).code == .notConnectedToInternet
                let isMutatingRequest = isMutatingEndpoint(endpoint)
                // Capture path before actor call to avoid main actor isolation
                let endpointPath = endpoint.path

                if isNetworkError && isMutatingRequest && priority >= .high {
                    // Queue for offline retry
                    await offlineQueue.enqueue(OfflineRequest(
                        id: UUID(),
                        endpoint: endpoint,
                        endpointPath: endpointPath,
                        priority: priority,
                        timestamp: Date(),
                        retryCount: 0,
                        operationType: .request // This would need to be determined based on the calling method
                    ))
                    logger.info("Mutating request queued for offline retry: \(endpointPath)")
                }

                // Throw the error
                throw mapError(error, response: nil)
            }
        }
    }

    // Helper to check if endpoint is a mutating request
    private func isMutatingEndpoint(_ endpoint: APIEndpoint) -> Bool {
        do {
            let urlRequest = try endpoint.asURLRequest()
            let method = urlRequest.httpMethod ?? "GET"
            return ["POST", "PUT", "PATCH", "DELETE"].contains(method)
        } catch {
            return false
        }
    }

    // MARK: - Request<T>

    nonisolated func request<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint
    ) async throws -> sending T {
        let result: (data: T, response: HTTPURLResponse?) = try await enqueueRequest(endpoint: endpoint, priority: .normal) { [weak self] in
            guard let self = self else { throw APIError.unknown(nil) }
            return try await self.performRequest(endpoint)
        }
        return result.data
    }

    // MARK: - Request Envelope<T>

    nonisolated func requestEnvelope<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint
    ) async throws -> sending T {
        let result: (data: T, response: HTTPURLResponse) = try await requestEnvelopeWithResponse(endpoint)
        return result.data
    }

    nonisolated func requestEnvelopeWithResponse<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint
    ) async throws -> (data: T, response: HTTPURLResponse) {
        let result: (data: T, response: HTTPURLResponse?) = try await enqueueRequest(endpoint: endpoint, priority: .normal) { [weak self] in
            guard let self = self else { throw APIError.unknown(nil) }
            return try await self.performEnvelopeRequest(endpoint)
        }
        guard let response = result.response else {
            throw APIError.unknown(nil)
        }
        return (result.data, response)
    }

    // MARK: - Request Void

    nonisolated func requestVoid(
        _ endpoint: APIEndpoint
    ) async throws {
        let _: (data: EmptyResponse, response: HTTPURLResponse?) = try await enqueueRequest(endpoint: endpoint, priority: .high) { [weak self] in
            guard let self = self else { throw APIError.unknown(nil) }
            return try await self.performVoidRequest(endpoint)
        }
    }

    // MARK: - Upload

    nonisolated func upload<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        multipartFormData: @Sendable @escaping (MultipartFormData) -> Void
    ) async throws -> sending T {
        let result: (data: T, response: HTTPURLResponse?) = try await executeWithRetry(endpoint: endpoint, priority: .high) { [weak self] in
            guard let self = self else { throw APIError.unknown(nil) }
            return try await self.performUpload(endpoint, multipartFormData: multipartFormData)
        }
        return result.data
    }

    /// Upload multipart form data with raw data, returning a Combine publisher.
    /// Used for TUS chunked uploads.
    nonisolated func requestMultipart<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        data: Data,
        offset: Int64
    ) -> AnyPublisher<T, APIError> {
        Future<T, APIError> { [weak self] promise in
            guard let self else {
                promise(.failure(.unknown(nil)))
                return
            }
            Task {
                do {
                    // Create URLRequest on main actor since asURLRequest() accesses AppConfig.shared
                    let urlRequest = try await MainActor.run {
                        var request = try endpoint.asURLRequest()
                        request.setValue("application/offset+octet-stream", forHTTPHeaderField: "Content-Type")
                        request.setValue("bytes \(offset)-\(offset + Int64(data.count) - 1)/*", forHTTPHeaderField: "Content-Range")
                        request.httpBody = data
                        return request
                    }

                    let dataResponse = await self.session
                        .request(urlRequest)
                        .validate(statusCode: 200..<300)
                        .serializingData()
                        .response

                    guard let httpResponse = dataResponse.response else {
                        throw APIError.unknown(nil)
                    }

                    guard let responseData = dataResponse.data else {
                        throw APIError.unknown(httpResponse.statusCode)
                    }

                    let result = try self.decoder.decode(T.self, from: responseData)
                    promise(.success(result))
                } catch let error as APIError {
                    promise(.failure(error))
                } catch {
                    promise(.failure(.networkError(error)))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Download

    func download(
        _ endpoint: APIEndpoint,
        to destination: DownloadRequest.Destination? = nil
    ) async throws -> URL {
        let startTime = Date()

        let urlRequest = try endpoint.asURLRequest()
        let dest = destination ?? DownloadRequest.suggestedDownloadDestination(
            for: .cachesDirectory,
            in: .userDomainMask
        )

        let response = await session
            .download(urlRequest, to: dest)
            .validate(statusCode: 200..<300)
            .serializingDownloadedFileURL()
            .response

        let latency = Date().timeIntervalSince(startTime)
        await metricsCollector.recordRequest(latency: latency, success: response.error == nil)

        switch response.result {
        case .success(let fileURL):
            return fileURL
        case .failure(let afError):
            throw mapError(afError, response: response.response)
        }
    }

    // MARK: - Metrics

    func getMetrics() async -> NetworkMetrics {
        await metricsCollector.getMetrics()
    }

    func getCacheMetrics() async -> (count: Int, maxSize: Int) {
        let count = await responseCache.count
        return (count, 100) // maxSize is 100
    }

    // MARK: - Private Request Implementations

    private func performRequest<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint
    ) async throws -> (data: T, response: HTTPURLResponse?) {
        let urlRequest = try endpoint.asURLRequest()

        // Deduplication for GET requests
        if urlRequest.httpMethod == "GET" {
            let cacheKey = "\(urlRequest.url?.absoluteString ?? endpoint.path)"
            let dedupKey = cacheKey

            // Check cache for conditional request headers
            let (etag, lastModified) = await responseCache.getConditionalHeaders(key: cacheKey)

            // Fetch data with deduplication - returns DeduplicatedResponse with data and metadata
            let dedupResult = try await deduplicator.deduplicate(key: dedupKey) {
                var request = urlRequest
                if let etag = etag {
                    request.setValue(etag, forHTTPHeaderField: "If-None-Match")
                }
                if let lastModified = lastModified {
                    request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
                }

                let dataResponse = await self.session
                    .request(request)
                    .validate(statusCode: 200..<300)
                    .serializingData()
                    .response

                guard let httpResponse = dataResponse.response else {
                    throw APIError.unknown(nil)
                }

                // Handle 304 Not Modified - return cached data
                if httpResponse.statusCode == 304 {
                    self.logger.debug("Cache hit (304): \(cacheKey)")
                    if let cached = await self.responseCache.get(key: cacheKey) {
                        return DeduplicatedResponse(
                            data: cached.data,
                            statusCode: 304,
                            etag: cached.etag,
                            lastModified: cached.lastModified
                        )
                    }
                    // If cache miss after 304, fall through to normal decode
                }

                guard let responseData = dataResponse.data else {
                    throw APIError.unknown(httpResponse.statusCode)
                }

                // Extract headers for caching
                let newEtag = httpResponse.allHeaderFields["ETag"] as? String ??
                              httpResponse.allHeaderFields["Etag"] as? String
                let newLastModified = httpResponse.allHeaderFields["Last-Modified"] as? String

                // Cache successful GET responses
                if let etag = newEtag, httpResponse.statusCode == 200 {
                    let cachedResponse = CachedResponse(
                        data: responseData,
                        etag: etag,
                        lastModified: newLastModified,
                        timestamp: Date(),
                        statusCode: httpResponse.statusCode
                    )
                    await self.responseCache.set(key: cacheKey, response: cachedResponse)
                }

                return DeduplicatedResponse(
                    data: responseData,
                    statusCode: httpResponse.statusCode,
                    etag: newEtag,
                    lastModified: newLastModified
                )
            }

            // Handle 304 Not Modified
            if dedupResult.statusCode == 304 {
                if let cached = await self.responseCache.get(key: cacheKey) {
                    return (try self.decoder.decode(T.self, from: cached.data), nil)
                }
                // If cache miss, we still have the data in dedupResult
            }

            do {
                let decoded = try self.decoder.decode(T.self, from: dedupResult.data)
                // Create a minimal HTTPURLResponse for the caller
                // Note: We can't easily reconstruct the full response, so we pass nil for GET cached responses
                // The caller typically only needs the data for GET requests
                let httpResponse = dedupResult.statusCode == 304 ? nil : HTTPURLResponse()
                return (decoded, httpResponse)
            } catch {
                if let responseString = String(data: dedupResult.data, encoding: .utf8) {
                    self.logger.error("❌ Decode failed for \(urlRequest.url?.absoluteString ?? "unknown"): \(responseString)")
                }
                throw self.mapError(error, response: nil)
            }
        }

        // Non-GET requests
        let dataResponse = await session
            .request(urlRequest)
            .validate(statusCode: 200..<300)
            .serializingData()
            .response

        guard let httpResponse = dataResponse.response else {
            throw APIError.unknown(nil)
        }

        guard let responseData = dataResponse.data else {
            throw APIError.unknown(httpResponse.statusCode)
        }

        do {
            return (try decoder.decode(T.self, from: responseData), httpResponse)
        } catch {
            if let responseString = String(data: responseData, encoding: .utf8) {
                logger.error("❌ Decode failed for \(urlRequest.url?.absoluteString ?? "unknown"): \(responseString)")
            }
            throw mapError(error, response: httpResponse)
        }
    }

    private func performEnvelopeRequest<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint
    ) async throws -> (data: T, response: HTTPURLResponse) {
        let urlRequest = try endpoint.asURLRequest()

        // Deduplication for GET requests
        if urlRequest.httpMethod == "GET" {
            let cacheKey = "envelope:\(urlRequest.url?.absoluteString ?? endpoint.path)"
            let dedupKey = cacheKey

            // Check cache for conditional request headers
            let (etag, lastModified) = await responseCache.getConditionalHeaders(key: cacheKey)

            // Fetch data with deduplication - returns DeduplicatedResponse with data and metadata
            let dedupResult = try await deduplicator.deduplicate(key: dedupKey) {
                var request = urlRequest
                if let etag = etag {
                    request.setValue(etag, forHTTPHeaderField: "If-None-Match")
                }
                if let lastModified = lastModified {
                    request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
                }

                let dataResponse = await self.session
                    .request(request)
                    .validate(statusCode: 200..<300)
                    .serializingData()
                    .response

                guard let httpResponse = dataResponse.response else {
                    throw APIError.unknown(nil)
                }

                // Handle 304 Not Modified - return cached data
                if httpResponse.statusCode == 304 {
                    self.logger.debug("Cache hit (304): \(cacheKey)")
                    if let cached = await self.responseCache.get(key: cacheKey) {
                        return DeduplicatedResponse(
                            data: cached.data,
                            statusCode: 304,
                            etag: cached.etag,
                            lastModified: cached.lastModified
                        )
                    }
                    // If cache miss after 304, fall through to normal decode
                }

                guard let responseData = dataResponse.data else {
                    throw APIError.unknown(httpResponse.statusCode)
                }

                // Extract headers for caching
                let newEtag = httpResponse.allHeaderFields["ETag"] as? String ??
                              httpResponse.allHeaderFields["Etag"] as? String
                let newLastModified = httpResponse.allHeaderFields["Last-Modified"] as? String

                // Cache successful GET responses
                if let etag = newEtag, httpResponse.statusCode == 200 {
                    let cachedResponse = CachedResponse(
                        data: responseData,
                        etag: etag,
                        lastModified: newLastModified,
                        timestamp: Date(),
                        statusCode: httpResponse.statusCode
                    )
                    await self.responseCache.set(key: cacheKey, response: cachedResponse)
                }

                return DeduplicatedResponse(
                    data: responseData,
                    statusCode: httpResponse.statusCode,
                    etag: newEtag,
                    lastModified: newLastModified
                )
            }

            // Handle 304 Not Modified
            if dedupResult.statusCode == 304 {
                if let cached = await self.responseCache.get(key: cacheKey) {
                    let envelope = try self.decoder.decode(APIEnvelope<T>.self, from: cached.data)
                    guard let data = envelope.data else {
                        throw APIError.unknown(304)
                    }
                    // Create a minimal HTTPURLResponse for 304
                    let httpResponse = HTTPURLResponse()
                    return (data, httpResponse)
                }
                // If cache miss, fall through to decode from dedupResult
            }

            // Decode the envelope from deduplicated data
            do {
                let envelope = try self.decoder.decode(APIEnvelope<T>.self, from: dedupResult.data)
                guard let data = envelope.data else {
                    if let errorCode = envelope.error {
                        // Map backend error codes to appropriate APIError
                        switch errorCode.uppercased() {
                        case "NOT_FOUND":
                            throw APIError.notFound
                        case "UNAUTHORIZED", "TOKEN_EXPIRED", "INVALID_TOKEN":
                            throw APIError.unauthorized
                        case "FORBIDDEN", "ACCESS_DENIED":
                            throw APIError.forbidden
                        default:
                            if let errorMessage = envelope.message {
                                throw APIError.serverError(errorMessage)
                            }
                            throw APIError.unknown(dedupResult.statusCode)
                        }
                    }
                    if let errorMessage = envelope.message {
                        throw APIError.serverError(errorMessage)
                    }
                    throw APIError.unknown(dedupResult.statusCode)
                }
                // Create a minimal HTTPURLResponse for the caller
                let httpResponse = HTTPURLResponse()
                return (data, httpResponse)
            } catch {
                if let responseString = String(data: dedupResult.data, encoding: .utf8) {
                    self.logger.error("❌ Decode failed for \(urlRequest.url?.absoluteString ?? "unknown"): \(responseString)")
                }
                throw self.mapError(error, response: nil)
            }
        }

        // Non-GET requests
        let dataResponse = await session
            .request(urlRequest)
            .validate(statusCode: 200..<300)
            .serializingData()
            .response

        guard let httpResponse = dataResponse.response else {
            throw APIError.unknown(nil)
        }

        guard let responseData = dataResponse.data else {
            throw APIError.unknown(httpResponse.statusCode)
        }

        // Decode manually so we can log raw response on failure
        do {
            let envelope = try decoder.decode(APIEnvelope<T>.self, from: responseData)
            guard let data = envelope.data else {
                if let errorCode = envelope.error {
                    // Map backend error codes to appropriate APIError
                    switch errorCode.uppercased() {
                    case "NOT_FOUND":
                        throw APIError.notFound
                    case "UNAUTHORIZED", "TOKEN_EXPIRED", "INVALID_TOKEN":
                        throw APIError.unauthorized
                    case "FORBIDDEN", "ACCESS_DENIED":
                        throw APIError.forbidden
                    default:
                        if let errorMessage = envelope.message {
                            throw APIError.serverError(errorMessage)
                        }
                        throw APIError.unknown(httpResponse.statusCode)
                    }
                }
                if let errorMessage = envelope.message {
                    throw APIError.serverError(errorMessage)
                }
                throw APIError.unknown(httpResponse.statusCode)
            }
            return (data, httpResponse)
        } catch {
            // Log raw response for debugging
            if let responseString = String(data: responseData, encoding: .utf8) {
                logger.error("❌ Decode failed for \(urlRequest.url?.absoluteString ?? "unknown"): \(responseString)")
            }
            throw mapError(error, response: httpResponse)
        }
    }

    private func performVoidRequest(
        _ endpoint: APIEndpoint
    ) async throws -> (data: EmptyResponse, response: HTTPURLResponse?) {
        let urlRequest = try endpoint.asURLRequest()

        let response = await session
            .request(urlRequest)
            .validate(statusCode: 200..<300)
            .serializingData()
            .response

        if let afError = response.error {
            throw mapError(afError, response: response.response)
        }

        // Check for error envelope in successful responses (200 OK with error payload)
        if let data = response.data,
           let envelope = try? decoder.decode(APIEnvelope<EmptyResponse>.self, from: data),
           let errorCode = envelope.error {
            switch errorCode.uppercased() {
            case "NOT_FOUND":
                throw APIError.notFound
            case "UNAUTHORIZED", "TOKEN_EXPIRED", "INVALID_TOKEN":
                throw APIError.unauthorized
            case "FORBIDDEN", "ACCESS_DENIED":
                throw APIError.forbidden
            default:
                if let errorMessage = envelope.message {
                    throw APIError.serverError(errorMessage)
                }
                throw APIError.unknown(response.response?.statusCode)
            }
        }

        return (EmptyResponse(), response.response)
    }

    private func performUpload<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        multipartFormData: @Sendable @escaping (MultipartFormData) -> Void
    ) async throws -> (data: T, response: HTTPURLResponse?) {
        let urlRequest = try endpoint.asURLRequest()

        let dataResponse = await session
            .upload(multipartFormData: multipartFormData, with: urlRequest)
            .validate(statusCode: 200..<300)
            .serializingData()
            .response

        guard let httpResponse = dataResponse.response else {
            throw APIError.unknown(nil)
        }

        guard let responseData = dataResponse.data else {
            throw APIError.unknown(httpResponse.statusCode)
        }

        do {
            return (try decoder.decode(T.self, from: responseData), httpResponse)
        } catch {
            if let responseString = String(data: responseData, encoding: .utf8) {
                logger.error("❌ Decode failed for \(urlRequest.url?.absoluteString ?? "unknown"): \(responseString)")
            }
            throw mapError(error, response: httpResponse)
        }
    }

    // MARK: - Error Mapping

    nonisolated private func mapError(_ error: Error, response: HTTPURLResponse?) -> APIError {
        // Detect global, cross-cutting HTTP states and route them to AppState.
        // This is intentionally non-invasive: we still return the normal mapped
        // APIError so existing error handling/return flow is unaffected.
        detectGlobalState(from: response)

        let apiError: APIError
        if let afError = error as? AFError {
            apiError = APIError.from(afError, response: response)
        } else if error is APIError {
            apiError = error as! APIError
        } else {
            // For manual decoding errors and other errors
            apiError = APIError.decodingError(error)
        }
        logger.error("API Error: \(apiError.localizedDescription)")
        return apiError
    }

    /// Inspects the HTTP status for app-wide states that must block the whole UI.
    /// - 503 Service Unavailable → maintenance mode
    /// - 426 Upgrade Required     → force update
    /// Flags are published on `AppState.shared` (main actor). No APIError cases are added.
    nonisolated private func detectGlobalState(from response: HTTPURLResponse?) {
        guard let statusCode = response?.statusCode else { return }
        switch statusCode {
        case 503:
            Task { @MainActor in
                AppState.shared.isUnderMaintenance = true
            }
        case 426:
            Task { @MainActor in
                AppState.shared.forceUpdateRequired = true
            }
        default:
            break
        }
    }

    // MARK: - Token Refresh (Better Auth - Bearer Token based)

    /// Refresh access token using refresh token in Authorization header (Better Auth)
    /// The backend expects: Authorization: Bearer <refreshToken>
    /// Returns new accessToken, optional new refreshToken, and expiresAt in response body
    func refreshAccessToken(refreshToken: String) async throws -> RefreshTokenDTO {
        let url = URL(string: config.baseURL)!.appendingPathComponent("/v1/auth/refresh")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = config.timeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")

        let dataResponse = await session
            .request(request)
            .validate(statusCode: 200..<300)
            .serializingDecodable(APIEnvelope<RefreshTokenDTO>.self, decoder: decoder)
            .response

        switch dataResponse.result {
        case .success(let envelope):
            guard let data = envelope.data else {
                if let errorMessage = envelope.error ?? envelope.message {
                    throw APIError.serverError(errorMessage)
                }
                throw APIError.unknown(dataResponse.response?.statusCode)
            }
            return data

        case .failure(let afError):
            throw mapError(afError, response: dataResponse.response)
        }
    }
}

// MARK: - Combine Support

extension NetworkService {

    /// Convenience publisher that wraps the async `request<T>` method.
    func requestPublisher<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint
    ) -> AnyPublisher<T, APIError> {
        Future<T, APIError> { [weak self] promise in
            guard let self else {
                promise(.failure(.unknown(nil)))
                return
            }
            Task {
                do {
                    let result: T = try await self.request(endpoint)
                    promise(.success(result))
                } catch let error as APIError {
                    promise(.failure(error))
                } catch {
                    promise(.failure(.networkError(error)))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Convenience publisher that wraps the async `requestEnvelope<T>` method.
    func requestEnvelopePublisher<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint
    ) -> AnyPublisher<T, APIError> {
        Future<T, APIError> { [weak self] promise in
            guard let self else {
                promise(.failure(.unknown(nil)))
                return
            }
            Task {
                do {
                    let result: T = try await self.requestEnvelope(endpoint)
                    promise(.success(result))
                } catch let error as APIError {
                    promise(.failure(error))
                } catch {
                    promise(.failure(.networkError(error)))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Convenience publisher that wraps the async `requestVoid` method.
    nonisolated func requestVoidPublisher(
        _ endpoint: APIEndpoint
    ) -> AnyPublisher<Void, APIError> {
        Future<Void, APIError> { [weak self] promise in
            guard let self else {
                promise(.failure(.unknown(nil)))
                return
            }
            Task {
                do {
                    try await self.requestVoid(endpoint)
                    promise(.success(()))
                } catch let error as APIError {
                    promise(.failure(error))
                } catch {
                    promise(.failure(.networkError(error)))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
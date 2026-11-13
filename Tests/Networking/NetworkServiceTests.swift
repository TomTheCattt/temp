//
//  NetworkServiceTests.swift
//  InstagramTests
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Testing
import Alamofire
@testable import Instagram

// MARK: - Test Helpers

actor MockURLProtocol: URLProtocol {
    nonisolated static var requestHandler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data?))?
    nonisolated static var lastRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "MockURLProtocol", code: -1))
            return
        }

        Self.lastRequest = request

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - NetworkService Tests

@Suite("NetworkService Tests")
struct NetworkServiceTests {

    let session: Session
    let networkService: NetworkService

    init() async throws {
        // Configure session with mock protocol
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        self.session = Session(configuration: configuration)
        self.networkService = NetworkService(session: session)
    }

    @Test("GET request succeeds and decodes response")
    func testGetRequest() async throws {
        struct TestResponse: Decodable, Sendable {
            let id: String
            let name: String
        }

        let expectedResponse = TestResponse(id: "123", name: "Test")
        let responseData = try JSONEncoder().encode(expectedResponse)

        await MockURLProtocol.requestHandler = { request in
            #expect(request.httpMethod == "GET")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, responseData)
        }

        let endpoint = UserEndpoint.publicProfile(userId: "123")
        let result: TestResponse = try await networkService.request(endpoint)

        #expect(result.id == "123")
        #expect(result.name == "Test")
    }

    @Test("POST request with body succeeds")
    func testPostRequest() async throws {
        struct LoginRequest: Encodable, Sendable {
            let email: String
            let password: String
        }

        struct LoginResponse: Decodable, Sendable {
            let token: String
        }

        let expectedResponse = LoginResponse(token: "abc123")
        let responseData = try JSONEncoder().encode(expectedResponse)

        await MockURLProtocol.requestHandler = { request in
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, responseData)
        }

        let endpoint = AuthEndpoint.login(email: "test@example.com", password: "password123")
        let result: LoginResponse = try await networkService.request(endpoint)

        #expect(result.token == "abc123")
    }

    @Test("401 error throws unauthorized")
    func testUnauthorizedError() async throws {
        await MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            let errorData = try JSONEncoder().encode(["error": "UNAUTHORIZED", "message": "Invalid token"])
            return (response, errorData)
        }

        let endpoint = UserEndpoint.profile
        await #expect(throws: APIError.unauthorized) {
            let _: UserWrapperDTO = try await networkService.requestEnvelope(endpoint)
        }
    }

    @Test("500 error throws server error")
    func testServerError() async throws {
        await MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            let errorData = try JSONEncoder().encode(["error": "INTERNAL_ERROR", "message": "Server error"])
            return (response, errorData)
        }

        let endpoint = UserEndpoint.profile
        await #expect(throws: APIError.self) {
            let _: UserWrapperDTO = try await networkService.requestEnvelope(endpoint)
        }
    }

    @Test("Network error throws network error")
    func testNetworkError() async throws {
        await MockURLProtocol.requestHandler = { request in
            throw URLError(.notConnectedToInternet)
        }

        let endpoint = UserEndpoint.profile
        await #expect(throws: APIError.self) {
            let _: UserWrapperDTO = try await networkService.requestEnvelope(endpoint)
        }
    }

    @Test("Retry logic works for retryable errors")
    func testRetryLogic() async throws {
        var attemptCount = 0
        let expectedResponse = TestResponse(id: "123", name: "Test")
        let responseData = try JSONEncoder().encode(expectedResponse)

        await MockURLProtocol.requestHandler = { request in
            attemptCount += 1
            if attemptCount < 3 {
                throw URLError(.timedOut)
            }
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, responseData)
        }

        let endpoint = UserEndpoint.publicProfile(userId: "123")
        let result: TestResponse = try await networkService.request(endpoint)

        #expect(attemptCount == 3)
        #expect(result.id == "123")
    }

    @Test("Circuit breaker opens after threshold")
    func testCircuitBreaker() async throws {
        let policy = CircuitBreakerPolicy(failureThreshold: 2, successThreshold: 1, timeout: 60)
        let circuitBreaker = CircuitBreaker(policy: policy)

        #expect(await circuitBreaker.canExecute() == true)

        await circuitBreaker.recordFailure()
        #expect(await circuitBreaker.canExecute() == true)

        await circuitBreaker.recordFailure()
        #expect(await circuitBreaker.canExecute() == false)

        await circuitBreaker.recordSuccess()
        #expect(await circuitBreaker.canExecute() == false)

        await circuitBreaker.recordSuccess()
        #expect(await circuitBreaker.canExecute() == true)
    }

    @Test("Rate limiter allows requests within limit")
    func testRateLimiter() async throws {
        let policy = RateLimitPolicy(maxRequestsPerWindow: 5, windowDuration: 60)
        let rateLimiter = RateLimiter(policy: policy)

        for _ in 0..<5 {
            let waitTime = await rateLimiter.acquire()
            #expect(waitTime == 0)
        }

        let waitTime = await rateLimiter.acquire()
        #expect(waitTime > 0)
    }

    @Test("Request deduplication works")
    func testRequestDeduplication() async throws {
        var callCount = 0
        let deduplicator = RequestDeduplicator()

        let result1 = try await deduplicator.deduplicate(key: "test-key") {
            callCount += 1
            return DeduplicatedResponse(
                data: "result1".data(using: .utf8)!,
                statusCode: 200,
                etag: nil,
                lastModified: nil
            )
        }

        let result2 = try await deduplicator.deduplicate(key: "test-key") {
            callCount += 1
            return DeduplicatedResponse(
                data: "result2".data(using: .utf8)!,
                statusCode: 200,
                etag: nil,
                lastModified: nil
            )
        }

        #expect(callCount == 1) // Second call should be deduplicated
        #expect(result1.data == result2.data)
    }

    @Test("Response cache stores and retrieves")
    func testResponseCache() async throws {
        let cache = ResponseCache(maxSize: 10)
        let testData = "test data".data(using: .utf8)!
        let cachedResponse = CachedResponse(
            data: testData,
            etag: "etag123",
            lastModified: "Mon, 01 Jan 2024 00:00:00 GMT",
            timestamp: Date(),
            statusCode: 200
        )

        await cache.set(key: "test-key", response: cachedResponse)

        let retrieved = await cache.get(key: "test-key")
        #expect(retrieved != nil)
        #expect(retrieved?.data == testData)
        #expect(retrieved?.etag == "etag123")

        let headers = await cache.getConditionalHeaders(key: "test-key")
        #expect(headers.etag == "etag123")
        #expect(headers.lastModified == "Mon, 01 Jan 2024 00:00:00 GMT")
    }

    @Test("Offline queue enqueues and dequeues")
    func testOfflineQueue() async throws {
        let queue = OfflineQueue()
        let request = OfflineRequest(
            id: UUID(),
            endpoint: UserEndpoint.profile,
            endpointPath: "/v1/user/profile",
            priority: .high,
            timestamp: Date(),
            retryCount: 0,
            operationType: .request
        )

        await queue.enqueue(request)

        let dequeued = await queue.dequeue()
        #expect(dequeued != nil)
        #expect(dequeued?.id == request.id)

        let count = await queue.count
        #expect(count == 0)
    }

    @Test("Metrics collector records requests")
    func testMetricsCollector() async throws {
        let collector = MetricsCollector()

        await collector.recordRequest(latency: 0.5, success: true)
        await collector.recordRequest(latency: 1.0, success: false, error: "timeout")

        let metrics = await collector.getMetrics()

        #expect(metrics.requestCount == 2)
        #expect(metrics.successCount == 1)
        #expect(metrics.failureCount == 1)
        #expect(metrics.averageLatency == 0.75)
        #expect(metrics.lastError == "timeout")
    }
}

// MARK: - Test Response Types

private struct TestResponse: Decodable, Sendable {
    let id: String
    let name: String
}

private struct UserWrapperDTO: Decodable, Sendable {
    let user: UserDTO
}

private struct UserDTO: Decodable, Sendable {
    let id: String
    let username: String
    let email: String
}
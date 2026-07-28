//
//  NetworkService.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Alamofire
import Combine

// MARK: - NetworkServiceProtocol

protocol NetworkServiceProtocol: Sendable {

    /// Perform a request and decode the response into `T`.
    nonisolated func request<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint
    ) async throws -> sending T

    /// Perform a request expecting the standard server envelope `APIEnvelope<T>`,
    /// and return only the `data` field.
    nonisolated func requestEnvelope<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint
    ) async throws -> sending T

    /// Perform a request with no expected response body (e.g. DELETE, 204).
    nonisolated func requestVoid(
        _ endpoint: APIEndpoint
    ) async throws

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
}

// MARK: - NetworkService

final class NetworkService: NetworkServiceProtocol, @unchecked Sendable {

    private let session: Session
    private let logger = AppLogger.network
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
        return decoder
    }()

    init(session: Session) {
        self.session = session
    }

    // MARK: - Request<T>

    nonisolated func request<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint
    ) async throws -> sending T {
        let urlRequest = try endpoint.asURLRequest()

        let response = await session
            .request(urlRequest)
            .validate(statusCode: 200..<300)
            .serializingDecodable(T.self, decoder: decoder)
            .response

        switch response.result {
        case .success(let value):
            return value
        case .failure(let afError):
            throw mapError(afError, response: response.response)
        }
    }

    // MARK: - Request Envelope<T>

    nonisolated func requestEnvelope<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint
    ) async throws -> sending T {
        let urlRequest = try endpoint.asURLRequest()

        let response = await session
            .request(urlRequest)
            .validate(statusCode: 200..<300)
            .serializingDecodable(APIEnvelope<T>.self, decoder: decoder)
            .response

        switch response.result {
        case .success(let envelope):
            guard let data = envelope.data else {
                if let errorMessage = envelope.error ?? envelope.message {
                    throw APIError.serverError(errorMessage)
                }
                throw APIError.unknown(response.response?.statusCode)
            }
            return data
        case .failure(let afError):
            throw mapError(afError, response: response.response)
        }
    }

    // MARK: - Request Void

    nonisolated func requestVoid(
        _ endpoint: APIEndpoint
    ) async throws {
        let urlRequest = try endpoint.asURLRequest()

        let response = await session
            .request(urlRequest)
            .validate(statusCode: 200..<300)
            .serializingData()
            .response

        if let afError = response.error {
            throw mapError(afError, response: response.response)
        }
    }

    // MARK: - Upload

    nonisolated func upload<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        multipartFormData: @Sendable @escaping (MultipartFormData) -> Void
    ) async throws -> sending T {
        let urlRequest = try endpoint.asURLRequest()

        let response = await session
            .upload(multipartFormData: multipartFormData, with: urlRequest)
            .validate(statusCode: 200..<300)
            .serializingDecodable(T.self, decoder: decoder)
            .response

        switch response.result {
        case .success(let value):
            return value
        case .failure(let afError):
            throw mapError(afError, response: response.response)
        }
    }

    // MARK: - Download

    func download(
        _ endpoint: APIEndpoint,
        to destination: DownloadRequest.Destination? = nil
    ) async throws -> URL {
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

        switch response.result {
        case .success(let fileURL):
            return fileURL
        case .failure(let afError):
            throw mapError(afError, response: response.response)
        }
    }

    // MARK: - Error Mapping

    private func mapError(_ afError: AFError, response: HTTPURLResponse?) -> APIError {
        let apiError = APIError.from(afError, response: response)
        logger.error("API Error: \(apiError.localizedDescription)")
        return apiError
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
}

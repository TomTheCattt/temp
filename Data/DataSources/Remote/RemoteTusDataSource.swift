//
//  RemoteTusDataSource.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation
import Combine

// MARK: - RemoteTusDataSource Protocol

protocol RemoteTusDataSourceProtocol {
    func createTusUpload(fileSize: Int64, metadata: TusMetadata) -> AnyPublisher<TusCreateResponse, Error>
    func getTusUploadInfo(uploadId: String) -> AnyPublisher<TusUploadInfo, Error>
    func uploadTusChunk(uploadId: String, data: Data, offset: Int64) -> AnyPublisher<TusUploadInfo, Error>
    func completeTusUpload(uploadId: String, targetType: String, targetId: String?) -> AnyPublisher<TusCompleteResponse, Error>
    func deleteTusUpload(uploadId: String) -> AnyPublisher<Void, Error>
}

// MARK: - RemoteTusDataSource Implementation

final class RemoteTusDataSource: RemoteTusDataSourceProtocol {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    func createTusUpload(fileSize: Int64, metadata: TusMetadata) -> AnyPublisher<TusCreateResponse, Error> {
        let endpoint = TusEndpoint.createUpload(
            fileSize: fileSize,
            metadata: metadata,
            uploadLength: nil
        )
        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func getTusUploadInfo(uploadId: String) -> AnyPublisher<TusUploadInfo, Error> {
        let endpoint = TusEndpoint.getUploadInfo(uploadId: uploadId)
        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func uploadTusChunk(uploadId: String, data: Data, offset: Int64) -> AnyPublisher<TusUploadInfo, Error> {
        let endpoint = TusEndpoint.uploadChunk(
            uploadId: uploadId,
            data: data,
            offset: offset
        )
        // For TUS chunk upload, we need a custom request with raw data
        return networkService.requestMultipart(endpoint, data: data, offset: offset)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func completeTusUpload(uploadId: String, targetType: String, targetId: String?) -> AnyPublisher<TusCompleteResponse, Error> {
        let endpoint = TusEndpoint.completeUpload(
            uploadId: uploadId,
            targetType: targetType,
            targetId: targetId
        )
        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func deleteTusUpload(uploadId: String) -> AnyPublisher<Void, Error> {
        let endpoint = TusEndpoint.deleteUpload(uploadId: uploadId)
        return networkService.requestVoidPublisher(endpoint)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}
//
//  TusRepository.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation
import Combine

// MARK: - TusRepository Protocol

protocol TusRepositoryProtocol {
    func createTusUpload(
        fileSize: Int64,
        metadata: TusMetadata
    ) -> AnyPublisher<TusCreateResponse, Error>

    func uploadTusChunk(
        uploadId: String,
        data: Data,
        offset: Int64
    ) -> AnyPublisher<TusUploadInfo, Error>

    func completeTusUpload(
        uploadId: String,
        targetType: String,
        targetId: String?
    ) -> AnyPublisher<TusCompleteResponse, Error>

    func getTusUploadInfo(uploadId: String) -> AnyPublisher<TusUploadInfo, Error>

    func deleteTusUpload(uploadId: String) -> AnyPublisher<Void, Error>
}

// MARK: - TusRepository Implementation

final class TusRepository: TusRepositoryProtocol {
    private let dataSource: RemoteTusDataSourceProtocol

    init(dataSource: RemoteTusDataSourceProtocol) {
        self.dataSource = dataSource
    }

    func createTusUpload(
        fileSize: Int64,
        metadata: TusMetadata
    ) -> AnyPublisher<TusCreateResponse, Error> {
        return dataSource.createTusUpload(fileSize: fileSize, metadata: metadata)
    }

    func uploadTusChunk(
        uploadId: String,
        data: Data,
        offset: Int64
    ) -> AnyPublisher<TusUploadInfo, Error> {
        return dataSource.uploadTusChunk(uploadId: uploadId, data: data, offset: offset)
    }

    func completeTusUpload(
        uploadId: String,
        targetType: String,
        targetId: String?
    ) -> AnyPublisher<TusCompleteResponse, Error> {
        return dataSource.completeTusUpload(uploadId: uploadId, targetType: targetType, targetId: targetId)
    }

    func getTusUploadInfo(uploadId: String) -> AnyPublisher<TusUploadInfo, Error> {
        return dataSource.getTusUploadInfo(uploadId: uploadId)
    }

    func deleteTusUpload(uploadId: String) -> AnyPublisher<Void, Error> {
        return dataSource.deleteTusUpload(uploadId: uploadId)
    }
}
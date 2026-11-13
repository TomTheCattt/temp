//
//  TusUseCaseProtocols.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation
import Combine

// MARK: - TUS Use Case Protocols

protocol CreateTusUploadUseCaseProtocol {
    func execute(
        fileSize: Int64,
        filename: String,
        contentType: String,
        targetType: UploadTargetType,
        targetId: String?,
        userId: String
    ) -> AnyPublisher<TusCreateResponse, Error>
}

protocol UploadTusChunkUseCaseProtocol {
    func execute(
        uploadId: String,
        data: Data,
        offset: Int64
    ) -> AnyPublisher<TusUploadInfo, Error>
}

protocol CompleteTusUploadUseCaseProtocol {
    func execute(
        uploadId: String,
        targetType: String,
        targetId: String?
    ) -> AnyPublisher<TusCompleteResponse, Error>
}

protocol GetTusUploadInfoUseCaseProtocol {
    func execute(uploadId: String) -> AnyPublisher<TusUploadInfo, Error>
}

protocol DeleteTusUploadUseCaseProtocol {
    func execute(uploadId: String) -> AnyPublisher<Void, Error>
}
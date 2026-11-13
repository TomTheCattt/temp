//
//  TusUseCases.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation
import Combine

// MARK: - TUS Domain Models

nonisolated struct TusMetadata: Codable {
    let filename: String
    let contentType: String
    let targetType: String
    let targetId: String?
    let userId: String

    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "filename": filename,
            "contentType": contentType,
            "targetType": targetType,
            "userId": userId
        ]
        if let targetId { dict["targetId"] = targetId }
        return dict
    }

    var encoded: String {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self),
              let string = String(data: data, encoding: .utf8) else { return "{}" }
        return string
    }
}

nonisolated struct TusCreateResponse: Codable {
    let uploadId: String
    let uploadUrl: String
    let expiresAt: Date?
}

nonisolated struct TusUploadInfo: Codable {
    let uploadId: String
    let uploadUrl: String
    let offset: Int64
    let expiresAt: Date?
    let fileSize: Int64
}

nonisolated struct TusCompleteResponse: Codable {
    let success: Bool
    let targetUrl: String?
    let targetId: String?
}

// MARK: - TUS Use Cases

// Create TUS Upload Use Case
struct CreateTusUploadUseCase: CreateTusUploadUseCaseProtocol {
    private let repository: TusRepositoryProtocol

    init(repository: TusRepositoryProtocol) {
        self.repository = repository
    }

    func execute(
        fileSize: Int64,
        filename: String,
        contentType: String,
        targetType: UploadTargetType,
        targetId: String?,
        userId: String
    ) -> AnyPublisher<TusCreateResponse, Error> {
        let metadata = TusMetadata(
            filename: filename,
            contentType: contentType,
            targetType: targetType.rawValue,
            targetId: targetId,
            userId: userId
        )

        return repository.createTusUpload(
            fileSize: fileSize,
            metadata: metadata
        )
    }
}

// Upload TUS Chunk Use Case
struct UploadTusChunkUseCase: UploadTusChunkUseCaseProtocol {
    private let repository: TusRepositoryProtocol

    init(repository: TusRepositoryProtocol) {
        self.repository = repository
    }

    func execute(
        uploadId: String,
        data: Data,
        offset: Int64
    ) -> AnyPublisher<TusUploadInfo, Error> {
        return repository.uploadTusChunk(
            uploadId: uploadId,
            data: data,
            offset: offset
        )
    }
}

// Complete TUS Upload Use Case
struct CompleteTusUploadUseCase: CompleteTusUploadUseCaseProtocol {
    private let repository: TusRepositoryProtocol

    init(repository: TusRepositoryProtocol) {
        self.repository = repository
    }

    func execute(
        uploadId: String,
        targetType: String,
        targetId: String?
    ) -> AnyPublisher<TusCompleteResponse, Error> {
        return repository.completeTusUpload(
            uploadId: uploadId,
            targetType: targetType,
            targetId: targetId
        )
    }
}

// Get TUS Upload Info Use Case
struct GetTusUploadInfoUseCase: GetTusUploadInfoUseCaseProtocol {
    private let repository: TusRepositoryProtocol

    init(repository: TusRepositoryProtocol) {
        self.repository = repository
    }

    func execute(uploadId: String) -> AnyPublisher<TusUploadInfo, Error> {
        return repository.getTusUploadInfo(uploadId: uploadId)
    }
}

// Delete TUS Upload Use Case
struct DeleteTusUploadUseCase: DeleteTusUploadUseCaseProtocol {
    private let repository: TusRepositoryProtocol

    init(repository: TusRepositoryProtocol) {
        self.repository = repository
    }

    func execute(uploadId: String) -> AnyPublisher<Void, Error> {
        return repository.deleteTusUpload(uploadId: uploadId)
    }
}

// MARK: - TUS Errors

enum TusError: Error, LocalizedError {
    case uploadNotFound(String)
    case uploadExpired(String)
    case offsetMismatch(expected: Int64, received: Int64)
    case uploadComplete(String)
    case invalidChunkSize
    case serverError(statusCode: Int, message: String?)
    case networkError(Error)
    case fileTooLarge(maxSize: Int64)
    case unsupportedFileType

    var errorDescription: String? {
        switch self {
        case .uploadNotFound(let id):
            return "Upload not found: \(id)"
        case .uploadExpired(let id):
            return "Upload expired: \(id)"
        case .offsetMismatch(let expected, let received):
            return "Offset mismatch: expected \(expected), got \(received)"
        case .uploadComplete(let id):
            return "Upload already complete: \(id)"
        case .invalidChunkSize:
            return "Invalid chunk size"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown")"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .fileTooLarge(let maxSize):
            return "File too large. Maximum size: \(ByteCountFormatter.string(fromByteCount: maxSize, countStyle: .file))"
        case .unsupportedFileType:
            return "Unsupported file type"
        }
    }
}

// Note: TusError is defined here
// Note: UploadRepositoryProtocol is defined in Data/Repositories/TusRepository.swift
// Note: Domain models (TusMetadata, UploadTargetType, TusCreateResponse, TusUploadInfo, TusCompleteResponse) are defined in Domain/UseCases/Upload/TusUseCases.swift (they're used as domain models here)
// Note: TusConstants is defined in Shared/Enums.swift
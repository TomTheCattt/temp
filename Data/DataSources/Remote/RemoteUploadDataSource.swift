//
//  RemoteUploadDataSource.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - RemoteUploadDataSource

/// Handles file uploads via Neon Object Storage.
/// Supports two flows:
/// 1. Presigned URL flow (for large files - direct to S3)
///    - POST /v1/upload/presign → GET presigned URL
///    - PUT to presigned URL
///    - POST /v1/upload/confirm → confirm upload
/// 2. Direct multipart upload (for smaller files)
///    - POST /v1/upload/image, /v1/upload/video, /v1/upload/avatar
final class RemoteUploadDataSource: @unchecked Sendable {

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    // MARK: - Upload Types

    enum UploadCategory: String, Sendable {
        case image
        case video
        case avatar
        case story
        case reel

        var contentType: String {
            switch self {
            case .image: return "image/jpeg"
            case .video: return "video/mp4"
            case .avatar: return "image/jpeg"
            case .story: return "image/jpeg"
            case .reel: return "video/mp4"
            }
        }

        var fileExtension: String {
            switch self {
            case .image, .avatar, .story: return "jpg"
            case .video, .reel: return "mp4"
            }
        }

        /// BE targetType for confirm endpoint
        var targetType: String {
            switch self {
            case .image, .story: return "post"
            case .video: return "post"
            case .avatar: return "avatar"
            case .reel: return "reel"
            }
        }

        /// BE prefix for presign endpoint
        var prefix: String {
            switch self {
            case .image: return "posts/images"
            case .video: return "posts/videos"
            case .avatar: return "avatars"
            case .story: return "stories"
            case .reel: return "reels"
            }
        }

        /// Max file size in bytes
        var maxSize: Int {
            switch self {
            case .image, .avatar, .story: return 10 * 1024 * 1024      // 10MB
            case .video, .reel: return 100 * 1024 * 1024               // 100MB
            }
        }
    }

    // MARK: - Presigned URL Upload (for large files)

    /// Upload a file using presigned URL flow (recommended for videos/large files).
    /// - Parameters:
    ///   - data: The file data to upload
    ///   - category: The upload category (determines content type, prefix, etc.)
    ///   - targetId: Optional target resource ID (post, reel, story, message ID)
    /// - Returns: The final file URL and metadata
    func uploadPresigned(
        data: Data,
        category: UploadCategory,
        targetId: String? = nil
    ) async throws -> UploadResult {
        // Step 1: Request presigned URL from BE
        let presignedResponse: PresignedURLDTO = try await networkService.requestEnvelope(
            UploadEndpoint.presign(
                contentType: category.contentType,
                maxSize: category.maxSize,
                prefix: category.prefix
            )
        )

        // Step 2: Upload file to presigned URL (direct to S3)
        try await uploadToPresignedURL(
            url: presignedResponse.uploadUrl,
            data: data,
            contentType: category.contentType
        )

        // Step 3: Confirm upload with backend
        let confirmResponse: ConfirmUploadDTO = try await networkService.requestEnvelope(
            UploadEndpoint.confirm(
                pendingUploadId: presignedResponse.pendingUploadId,
                targetType: category.targetType,
                targetId: targetId
            )
        )

        // Return the final file URL
        return UploadResult(
            url: confirmResponse.url,
            uploadId: confirmResponse.pendingUploadId,
            width: presignedResponse.width,
            height: presignedResponse.height,
            duration: presignedResponse.duration
        )
    }

    // MARK: - Direct Multipart Upload (for smaller files)

    /// Upload image directly via multipart (for posts, stories)
    func uploadImage(
        data: Data,
        filename: String = "image.jpg"
    ) async throws -> DirectUploadResult {
        let result: DirectUploadDTO = try await networkService.upload(
            UploadEndpoint.uploadImage(data: data, filename: filename)
        ) { formData in
            formData.append(data, withName: "file", fileName: filename, mimeType: "image/jpeg")
        }
        return DirectUploadResult(
            url: result.url,
            width: result.width,
            height: result.height,
            pendingUploadId: result.pendingUploadId
        )
    }

    /// Upload video directly via multipart (for posts, reels)
    func uploadVideo(
        data: Data,
        filename: String = "video.mp4"
    ) async throws -> VideoUploadResult {
        let result: VideoUploadDTO = try await networkService.upload(
            UploadEndpoint.uploadVideo(data: data, filename: filename)
        ) { formData in
            formData.append(data, withName: "file", fileName: filename, mimeType: "video/mp4")
        }
        return VideoUploadResult(
            url: result.url,
            thumbnailUrl: result.thumbnailUrl,
            duration: result.duration,
            width: result.width,
            height: result.height,
            pendingUploadId: result.pendingUploadId
        )
    }

    /// Upload avatar directly via multipart (processed to 400x400 by BE)
    func uploadAvatar(
        data: Data,
        filename: String = "avatar.jpg"
    ) async throws -> String {
        let result: AvatarUploadDTO = try await networkService.upload(
            UploadEndpoint.uploadAvatar(data: data, filename: filename)
        ) { formData in
            formData.append(data, withName: "file", fileName: filename, mimeType: "image/jpeg")
        }
        return result.url
    }

    /// Upload multiple files sequentially using presigned flow
    func uploadMultiplePresigned(
        dataArray: [Data],
        category: UploadCategory,
        targetId: String? = nil
    ) async throws -> [UploadResult] {
        var results: [UploadResult] = []
        for data in dataArray {
            let result = try await uploadPresigned(data: data, category: category, targetId: targetId)
            results.append(result)
        }
        return results
    }

    // MARK: - Pending Upload Management

    /// Get status of a pending upload
    func getPendingStatus(pendingUploadId: String) async throws -> PendingUploadStatus {
        let response: PendingStatusDTO = try await networkService.requestEnvelope(
            UploadEndpoint.getPendingStatus(pendingUploadId: pendingUploadId)
        )
        return PendingUploadStatus(
            pendingUploadId: response.pendingUploadId,
            url: response.url,
            storagePath: response.storagePath,
            confirmed: response.confirmed,
            createdAt: response.createdAt
        )
    }

    /// Delete a pending upload (and its storage)
    func deletePendingUpload(pendingUploadId: String) async throws {
        try await networkService.requestVoid(
            UploadEndpoint.deletePending(pendingUploadId: pendingUploadId)
        )
    }

    // MARK: - Private Helpers

    private func uploadToPresignedURL(url: String, data: Data, contentType: String) async throws {
        guard let presignedURL = URL(string: url) else {
            throw UploadError.invalidPresignedURL
        }

        var request = URLRequest(url: presignedURL)
        request.httpMethod = "PUT"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
        request.httpBody = data

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw UploadError.uploadFailed(statusCode: statusCode)
        }
    }
}

// MARK: - DTOs (matching BE response exactly)

/// Response from POST /v1/upload/presign
nonisolated struct PresignedURLDTO: Decodable, Sendable {
    let uploadUrl: String
    let pendingUploadId: String
    let storagePath: String
    let url: String
    let expiresIn: Int
    let width: Int?
    let height: Int?
    let duration: Double?
}

/// Response from POST /v1/upload/confirm
nonisolated struct ConfirmUploadDTO: Decodable, Sendable {
    let pendingUploadId: String
    let url: String
    let storagePath: String
}

/// Response from POST /v1/upload/image
nonisolated struct DirectUploadDTO: Decodable, Sendable {
    let url: String
    let width: Int
    let height: Int
    let pendingUploadId: String
}

/// Response from POST /v1/upload/video
nonisolated struct VideoUploadDTO: Decodable, Sendable {
    let url: String
    let thumbnailUrl: String
    let duration: Double
    let width: Int
    let height: Int
    let pendingUploadId: String
}

/// Response from POST /v1/upload/avatar
nonisolated struct AvatarUploadDTO: Decodable, Sendable {
    let url: String
}

/// Response from GET /v1/upload/pending/:id
nonisolated struct PendingStatusDTO: Decodable, Sendable {
    let pendingUploadId: String
    let url: String
    let storagePath: String
    let confirmed: Bool
    let createdAt: String  // ISO8601 date string
}

// MARK: - Result Types

/// Result of a successful presigned upload
struct UploadResult: Sendable {
    let url: String
    let uploadId: String
    let width: Int?
    let height: Int?
    let duration: Double?
}

/// Result of direct image upload
struct DirectUploadResult: Sendable {
    let url: String
    let width: Int
    let height: Int
    let pendingUploadId: String
}

/// Result of direct video upload
struct VideoUploadResult: Sendable {
    let url: String
    let thumbnailUrl: String
    let duration: Double
    let width: Int
    let height: Int
    let pendingUploadId: String
}

/// Pending upload status
struct PendingUploadStatus: Sendable {
    let pendingUploadId: String
    let url: String
    let storagePath: String
    let confirmed: Bool
    let createdAt: String
}

// MARK: - UploadError

enum UploadError: LocalizedError {
    case invalidPresignedURL
    case uploadFailed(statusCode: Int)
    case confirmFailed
    case pendingNotFound
    case alreadyConfirmed

    var errorDescription: String? {
        switch self {
        case .invalidPresignedURL: return "Invalid presigned URL received from server"
        case .uploadFailed(let statusCode): return "Upload to storage failed with status \(statusCode)"
        case .confirmFailed: return "Failed to confirm upload with server"
        case .pendingNotFound: return "Pending upload not found"
        case .alreadyConfirmed: return "Upload already confirmed"
        }
    }
}
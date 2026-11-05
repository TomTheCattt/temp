//
//  RemoteUploadDataSource.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - RemoteUploadDataSource

/// Handles file uploads via Neon Object Storage presigned URLs.
/// Flow:
/// 1. Request presigned URL from backend
/// 2. Upload file directly to presigned URL (S3-compatible PUT)
/// 3. Confirm upload with backend (optional)
/// 4. Return the final file URL
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

        var folder: String {
            switch self {
            case .image: return "posts/images"
            case .video: return "posts/videos"
            case .avatar: return "avatars"
            case .story: return "stories"
            case .reel: return "reels"
            }
        }
    }

    // MARK: - Presigned URL Upload

    /// Upload a file using presigned URL flow.
    /// - Parameters:
    ///   - data: The file data to upload
    ///   - category: The upload category (determines content type, folder, etc.)
    ///   - filename: Optional custom filename
    /// - Returns: The final file URL and metadata
    func upload(
        data: Data,
        category: UploadCategory,
        filename: String? = nil
    ) async throws -> UploadResult {
        // Step 1: Request presigned URL
        let fileName = filename ?? "file_\(UUID().uuidString).\(category.fileExtension)"
        let presignedResponse: PresignedURLDTO = try await networkService.requestEnvelope(
            UploadEndpoint.presignedUrl(
                filename: fileName,
                contentType: category.contentType,
                folder: category.folder
            )
        )

        // Step 2: Upload file to presigned URL
        try await uploadToPresignedURL(
            url: presignedResponse.presignedUrl,
            data: data,
            contentType: category.contentType
        )

        // Step 3: Confirm upload with backend (optional, but good for tracking)
        let uploadId = presignedResponse.uploadId
        try await confirmUpload(uploadId: uploadId)

        // Return the final file URL
        return UploadResult(
            url: presignedResponse.fileUrl,
            uploadId: uploadId,
            width: presignedResponse.width,
            height: presignedResponse.height,
            duration: presignedResponse.duration
        )
    }

    /// Upload multiple files sequentially
    func uploadMultiple(
        dataArray: [Data],
        category: UploadCategory
    ) async throws -> [UploadResult] {
        var results: [UploadResult] = []
        for (index, data) in dataArray.enumerated() {
            let filename = "file_\(index)_\(UUID().uuidString).\(category.fileExtension)"
            let result = try await upload(data: data, category: category, filename: filename)
            results.append(result)
        }
        return results
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

    private func confirmUpload(uploadId: String) async throws {
        try await networkService.requestVoid(UploadEndpoint.confirmUpload(uploadId: uploadId))
    }
}

// MARK: - DTOs

/// Response from presigned URL request
nonisolated struct PresignedURLDTO: Decodable, Sendable {
    let presignedUrl: String
    let fileUrl: String
    let uploadId: String
    let width: Int?
    let height: Int?
    let duration: Double?
}

/// Result of a successful upload
struct UploadResult: Sendable {
    let url: String
    let uploadId: String
    let width: Int?
    let height: Int?
    let duration: Double?
}

// MARK: - UploadError

enum UploadError: LocalizedError {
    case invalidPresignedURL
    case uploadFailed(statusCode: Int)
    case confirmFailed

    var errorDescription: String? {
        switch self {
        case .invalidPresignedURL: return "Invalid presigned URL received from server"
        case .uploadFailed(let statusCode): return "Upload to storage failed with status \(statusCode)"
        case .confirmFailed: return "Failed to confirm upload with server"
        }
    }
}
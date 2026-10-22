//
//  FirebaseStorageService.swift
//  Instagram
//
//  Created by Antigravity on 17/10/26.
//

import Foundation
import CoreGraphics
import FirebaseStorage

// MARK: - FirebaseStorageError

public enum FirebaseStorageError: LocalizedError, Sendable {
    case invalidPath
    case invalidStorageURL(String)
    case uploadFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidPath:
            return "Firebase Storage path cannot be empty."
        case .invalidStorageURL(let url):
            return "Provided URL is not a valid Firebase Storage URL: \(url)"
        case .uploadFailed(let reason):
            return "Firebase Storage upload failed: \(reason)"
        }
    }
}

// MARK: - FirebaseStorageServiceProtocol

public protocol FirebaseStorageServiceProtocol: Sendable {
    /// Uploads an image to the specified path in Firebase Storage.
    /// Safely downsamples image data beforehand to prevent Out Of Memory (OOM) crashes.
    func uploadImage(data: Data, path: String) async throws -> URL

    /// Uploads video data to the specified path in Firebase Storage.
    func uploadVideo(data: Data, path: String) async throws -> URL

    /// Uploads audio data to the specified path in Firebase Storage.
    func uploadAudio(data: Data, path: String) async throws -> URL

    /// Deletes a file at the specified URL string or storage path in Firebase Storage.
    func deleteFile(at urlString: String) async throws
}

// MARK: - FirebaseStorageService

nonisolated public final class FirebaseStorageService: FirebaseStorageServiceProtocol, @unchecked Sendable {

    nonisolated public static let shared = FirebaseStorageService()

    private let storage: Storage

    public init(storage: Storage = Storage.storage()) {
        self.storage = storage
    }

    // MARK: - Downsampling Helper (Rule 1 of GEMINI.md)

    /// Safely downsamples raw image data using low-level Image I/O at decode time to prevent high RAM spikes.
    /// Wrapped in `@autoreleasepool` for zero memory leaks.
    public func downsampleImageIfNeeded(
        data: Data,
        maxDimension: CGFloat = 1080,
        compressionQuality: CGFloat = 0.85
    ) -> Data {
        autoreleasepool {
            if let downsampled = MainActor.assumeIsolated({
                ImageDownsampler.shared.downsampleToData(
                    data: data,
                    maxDimension: maxDimension,
                    compressionQuality: compressionQuality
                )
            }) {
                return downsampled
            }
            return data
        }
    }

    // MARK: - Upload Image

    public func uploadImage(data: Data, path: String) async throws -> URL {
        guard !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FirebaseStorageError.invalidPath
        }

        let optimizedData = downsampleImageIfNeeded(data: data)

        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(optimizedData, metadata: metadata)
        return try await ref.downloadURL()
    }

    // MARK: - Upload Video

    public func uploadVideo(data: Data, path: String) async throws -> URL {
        guard !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FirebaseStorageError.invalidPath
        }

        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "video/mp4"

        _ = try await ref.putDataAsync(data, metadata: metadata)
        return try await ref.downloadURL()
    }

    // MARK: - Upload Audio

    public func uploadAudio(data: Data, path: String) async throws -> URL {
        guard !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FirebaseStorageError.invalidPath
        }

        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "audio/m4a"

        _ = try await ref.putDataAsync(data, metadata: metadata)
        return try await ref.downloadURL()
    }

    // MARK: - Delete File

    public func deleteFile(at urlString: String) async throws {
        let ref = try resolveReference(for: urlString)
        try await ref.delete()
    }

    // MARK: - Reference Resolution

    private func resolveReference(for location: String) throws -> StorageReference {
        let trimmed = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw FirebaseStorageError.invalidPath
        }

        if trimmed.hasPrefix("gs://") || trimmed.contains("firebasestorage.googleapis.com") {
            return storage.reference(forURL: trimmed)
        }

        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            throw FirebaseStorageError.invalidStorageURL(trimmed)
        }

        return storage.reference().child(trimmed)
    }
}

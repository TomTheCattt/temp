//
//  PhotoLibraryService.swift
//  Instagram
//
//  Created by Kiro on 15/10/26.
//

import Photos
import UIKit
import SwiftUI

// MARK: - MediaAssetItem

public struct MediaAssetItem: Identifiable, Equatable, @unchecked Sendable {
    public let id: String
    public let phAsset: PHAsset
    public let mediaType: PHAssetMediaType
    public let duration: TimeInterval
    public let creationDate: Date?

    public init(phAsset: PHAsset) {
        self.id = phAsset.localIdentifier
        self.phAsset = phAsset
        self.mediaType = phAsset.mediaType
        self.duration = phAsset.duration
        self.creationDate = phAsset.creationDate
    }

    public var isVideo: Bool {
        mediaType == .video
    }

    public var formattedDuration: String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    public static func == (lhs: MediaAssetItem, rhs: MediaAssetItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - MediaAlbumItem

public struct MediaAlbumItem: Identifiable, Equatable, @unchecked Sendable {
    public let id: String
    public let title: String
    public let count: Int
    public let collection: PHAssetCollection?

    public init(id: String, title: String, count: Int, collection: PHAssetCollection?) {
        self.id = id
        self.title = title
        self.count = count
        self.collection = collection
    }

    public static func == (lhs: MediaAlbumItem, rhs: MediaAlbumItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - PhotoLibraryServiceProtocol

public protocol PhotoLibraryServiceProtocol: Sendable {
    func requestAuthorization() async -> Bool
    func checkAuthorization() -> Bool
    func fetchAlbums() async -> [MediaAlbumItem]
    func fetchAssets(in album: MediaAlbumItem?, limit: Int) async -> [MediaAssetItem]
    func loadThumbnail(for asset: PHAsset, targetSize: CGSize) async -> UIImage?
    func loadHighQualityImage(for asset: PHAsset) async -> UIImage?
    func loadImageData(for asset: PHAsset) async -> Data?
    func loadVideoURL(for asset: PHAsset) async -> URL?
    func saveImageData(_ data: Data) async throws
    func saveVideo(at url: URL) async throws
}

// MARK: - PhotoLibraryService

public actor PhotoLibraryService: PhotoLibraryServiceProtocol {

    public static let shared = PhotoLibraryService()

    private let imageManager = PHCachingImageManager.default()

    private init() {}

    // MARK: - Authorization

    public func requestAuthorization() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return status == .authorized || status == .limited
    }

    nonisolated public func checkAuthorization() -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        return status == .authorized || status == .limited
    }

    // MARK: - Fetch Albums

    public func fetchAlbums() async -> [MediaAlbumItem] {
        guard checkAuthorization() else { return [] }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var albums: [MediaAlbumItem] = []

                // 1. Recents / All Photos
                let allPhotosOptions = PHFetchOptions()
                allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                let allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
                albums.append(
                    MediaAlbumItem(
                        id: "all_photos",
                        title: "Gần đây",
                        count: allPhotos.count,
                        collection: nil
                    )
                )

                // 2. User & Smart Albums (Videos, Favorites, Screenshots)
                let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
                smartAlbums.enumerateObjects { collection, _, _ in
                    let fetchOptions = PHFetchOptions()
                    let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
                    if assets.count > 0 {
                        let localizedTitle = collection.localizedTitle ?? "Album"
                        albums.append(
                            MediaAlbumItem(
                                id: collection.localIdentifier,
                                title: localizedTitle,
                                count: assets.count,
                                collection: collection
                            )
                        )
                    }
                }

                continuation.resume(returning: albums)
            }
        }
    }

    // MARK: - Fetch Assets

    public func fetchAssets(in album: MediaAlbumItem? = nil, limit: Int = 200) async -> [MediaAssetItem] {
        guard checkAuthorization() else { return [] }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                fetchOptions.fetchLimit = limit

                let result: PHFetchResult<PHAsset>
                if let collection = album?.collection {
                    result = PHAsset.fetchAssets(in: collection, options: fetchOptions)
                } else {
                    result = PHAsset.fetchAssets(with: fetchOptions)
                }

                var items: [MediaAssetItem] = []
                result.enumerateObjects { asset, _, _ in
                    items.append(MediaAssetItem(phAsset: asset))
                }

                continuation.resume(returning: items)
            }
        }
    }

    // MARK: - Load Thumbnail

    public func loadThumbnail(for asset: PHAsset, targetSize: CGSize = CGSize(width: 250, height: 250)) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let singleResume = SingleResumeContinuation(continuation)
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                let isCancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                let hasError = info?[PHImageErrorKey] != nil

                if !isDegraded || isCancelled || hasError {
                    Task {
                        await singleResume.resume(returning: image)
                    }
                }
            }
        }
    }

    // MARK: - Load High Quality Image

    public func loadHighQualityImage(for asset: PHAsset) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let singleResume = SingleResumeContinuation(continuation)
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            let targetSize = CGSize(width: 1080, height: 1080)
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                let isCancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                let hasError = info?[PHImageErrorKey] != nil

                if !isDegraded || isCancelled || hasError {
                    Task {
                        await singleResume.resume(returning: image)
                    }
                }
            }
        }
    }

    // MARK: - Load Image Data

    public func loadImageData(for asset: PHAsset) async -> Data? {
        await withCheckedContinuation { continuation in
            let singleResume = SingleResumeContinuation(continuation)
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            imageManager.requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                Task {
                    await singleResume.resume(returning: data)
                }
            }
        }
    }

    // MARK: - Load Video URL

    public func loadVideoURL(for asset: PHAsset) async -> URL? {
        await withCheckedContinuation { continuation in
            let singleResume = SingleResumeContinuation(continuation)
            let options = PHVideoRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true

            imageManager.requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                let url = (avAsset as? AVURLAsset)?.url
                Task {
                    await singleResume.resume(returning: url)
                }
            }
        }
    }

    // MARK: - Save Media

    public func saveImageData(_ data: Data) async throws {
        guard await requestAuthorization() else {
            throw PhotoLibrarySaveError.authorizationDenied
        }
        guard let image = UIImage(data: data) else {
            throw PhotoLibrarySaveError.invalidImage
        }
        try await performPhotoLibraryChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }

    public func saveVideo(at url: URL) async throws {
        guard await requestAuthorization() else {
            throw PhotoLibrarySaveError.authorizationDenied
        }
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw PhotoLibrarySaveError.missingVideo
        }
        try await performPhotoLibraryChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }
    }

    private func performPhotoLibraryChanges(_ changes: @escaping @Sendable () -> Void) async throws {
        try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges(changes) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? PhotoLibrarySaveError.saveFailed)
                }
            }
        }
    }
}

public enum PhotoLibrarySaveError: LocalizedError {
    case authorizationDenied
    case invalidImage
    case missingVideo
    case saveFailed

    public var errorDescription: String? {
        switch self {
        case .authorizationDenied: return "Photo Library permission was denied."
        case .invalidImage: return "The exported image could not be read."
        case .missingVideo: return "The exported video file no longer exists."
        case .saveFailed: return "The media could not be saved to Photo Library."
        }
    }
}

// MARK: - Thread-Safe Single-Resume Continuation Actor

private actor SingleResumeContinuation<T> {
    private var continuation: CheckedContinuation<T, Never>?

    init(_ continuation: CheckedContinuation<T, Never>) {
        self.continuation = continuation
    }

    func resume(returning value: T) {
        guard let cont = continuation else { return }
        continuation = nil
        cont.resume(returning: value)
    }
}

//
//  SwiftDataStorage.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import SwiftData

// MARK: - SwiftDataStorage

/// Concrete implementation of `LocalStorageProtocol` using SwiftData.
/// Uses type-dispatching to route generic calls to typed SwiftData operations.
@ModelActor
actor SwiftDataStorage: LocalStorageProtocol {

    // MARK: - Fetch All

    func fetchAll<T: Storable>(
        _ type: T.Type,
        predicate: StoragePredicate?,
        sortBy: [StorageSortDescriptor]
    ) async throws -> [T] {
        switch type {
        case is Post.Type:
            let descriptor = FetchDescriptor<SDCachedPost>(
                sortBy: [SortDescriptor(\.feedIndex, order: .forward)]
            )
            let models = try modelContext.fetch(descriptor)
            return models.map { $0.toEntity() } as! [T]

        case is User.Type:
            let descriptor = FetchDescriptor<SDCachedUser>(
                sortBy: [SortDescriptor(\.cachedAt, order: .reverse)]
            )
            let models = try modelContext.fetch(descriptor)
            return models.map { $0.toEntity() } as! [T]

        default:
            return []
        }
    }

    // MARK: - Fetch by ID

    func fetch<T: Storable>(_ type: T.Type, id: String) async throws -> T? {
        switch type {
        case is Post.Type:
            let predicate = #Predicate<SDCachedPost> { $0.id == id }
            let descriptor = FetchDescriptor<SDCachedPost>(predicate: predicate)
            let models = try modelContext.fetch(descriptor)
            return models.first?.toEntity() as? T

        case is User.Type:
            let predicate = #Predicate<SDCachedUser> { $0.id == id }
            let descriptor = FetchDescriptor<SDCachedUser>(predicate: predicate)
            let models = try modelContext.fetch(descriptor)
            return models.first?.toEntity() as? T

        default:
            return nil
        }
    }

    // MARK: - Save

    func save<T: Storable>(_ object: T) async throws {
        if let post = object as? Post {
            // Upsert: delete existing then insert new
            try deleteModel(SDCachedPost.self, id: post.id)
            modelContext.insert(SDCachedPost(from: post))
        } else if let user = object as? User {
            try deleteModel(SDCachedUser.self, id: user.id)
            modelContext.insert(SDCachedUser(from: user))
        }
        try modelContext.save()
    }

    // MARK: - Save All

    func saveAll<T: Storable>(_ objects: [T]) async throws {
        for object in objects {
            if let post = object as? Post {
                try deleteModel(SDCachedPost.self, id: post.id)
                modelContext.insert(SDCachedPost(from: post, feedIndex: 0))
            } else if let user = object as? User {
                try deleteModel(SDCachedUser.self, id: user.id)
                modelContext.insert(SDCachedUser(from: user))
            }
        }
        try modelContext.save()
    }

    // MARK: - Delete

    func delete<T: Storable>(_ type: T.Type, id: String) async throws {
        switch type {
        case is Post.Type:
            try deleteModel(SDCachedPost.self, id: id)
        case is User.Type:
            try deleteModel(SDCachedUser.self, id: id)
        default:
            break
        }
        try modelContext.save()
    }

    // MARK: - Delete All

    func deleteAll<T: Storable>(_ type: T.Type, predicate: StoragePredicate?) async throws {
        switch type {
        case is Post.Type:
            try modelContext.delete(model: SDCachedPost.self)
        case is User.Type:
            try modelContext.delete(model: SDCachedUser.self)
        default:
            break
        }
        try modelContext.save()
    }

    // MARK: - Count

    func count<T: Storable>(_ type: T.Type, predicate: StoragePredicate?) async throws -> Int {
        switch type {
        case is Post.Type:
            let descriptor = FetchDescriptor<SDCachedPost>()
            return try modelContext.fetchCount(descriptor)
        case is User.Type:
            let descriptor = FetchDescriptor<SDCachedUser>()
            return try modelContext.fetchCount(descriptor)
        default:
            return 0
        }
    }

    // MARK: - Private

    private func deleteModel<M: PersistentModel>(_ modelType: M.Type, id: String) throws {
        // Fetch and delete by ID — SwiftData doesn't support predicate delete by arbitrary field easily,
        // so we fetch then delete.
        let descriptor = FetchDescriptor<M>()
        let all = try modelContext.fetch(descriptor)
        // Find by id attribute — models should have `id` property
        for model in all {
            if let idValue = Mirror(reflecting: model).children.first(where: { $0.label == "id" })?.value as? String,
               idValue == id {
                modelContext.delete(model)
                break
            }
        }
    }
}

// MARK: - StorageError

enum StorageError: LocalizedError {
    case unsupportedType(String)
    case notFound(String)
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .unsupportedType(let type):
            return "Unsupported storage type: \(type). Register the corresponding @Model."
        case .notFound(let id):
            return "Object not found with id: \(id)"
        case .saveFailed(let error):
            return "Save failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Domain Entities Storable Conformance

extension Post: Storable {}
extension User: Storable {}

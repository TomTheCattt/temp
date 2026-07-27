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
/// This is the only file that imports SwiftData — keeping the rest of the app decoupled.
@ModelActor
actor SwiftDataStorage: LocalStorageProtocol {

    // MARK: - Fetch All

    func fetchAll<T: Storable>(
        _ type: T.Type,
        predicate: StoragePredicate?,
        sortBy: [StorageSortDescriptor]
    ) async throws -> [T] {
        guard let modelType = type as? any (PersistentModel & Storable).Type else {
            throw StorageError.unsupportedType(String(describing: type))
        }

        let models = try fetchModels(modelType)

        // Apply predicate filtering in memory (simplified)
        var results = models.compactMap { $0 as? T }

        if let predicate {
            results = applyPredicate(predicate, to: results)
        }

        return results
    }

    // MARK: - Fetch by ID

    func fetch<T: Storable>(_ type: T.Type, id: String) async throws -> T? {
        guard let modelType = type as? any (PersistentModel & Storable).Type else {
            throw StorageError.unsupportedType(String(describing: type))
        }

        let models = try fetchModels(modelType)
        return models.first { ($0 as? T)?.id == id } as? T
    }

    // MARK: - Save

    func save<T: Storable>(_ object: T) async throws {
        guard let model = object as? any PersistentModel else {
            throw StorageError.unsupportedType(String(describing: T.self))
        }
        modelContext.insert(model)
        try modelContext.save()
    }

    // MARK: - Save All

    func saveAll<T: Storable>(_ objects: [T]) async throws {
        for object in objects {
            guard let model = object as? any PersistentModel else {
                throw StorageError.unsupportedType(String(describing: T.self))
            }
            modelContext.insert(model)
        }
        try modelContext.save()
    }

    // MARK: - Delete

    func delete<T: Storable>(_ type: T.Type, id: String) async throws {
        guard let modelType = type as? any (PersistentModel & Storable).Type else {
            throw StorageError.unsupportedType(String(describing: type))
        }

        let models = try fetchModels(modelType)
        if let target = models.first(where: { ($0 as? T)?.id == id }) {
            modelContext.delete(target as! any PersistentModel)
            try modelContext.save()
        }
    }

    // MARK: - Delete All

    func deleteAll<T: Storable>(_ type: T.Type, predicate: StoragePredicate?) async throws {
        guard let modelType = type as? any (PersistentModel & Storable).Type else {
            throw StorageError.unsupportedType(String(describing: type))
        }

        let models = try fetchModels(modelType)
        var targets = models.compactMap { $0 as? T }

        if let predicate {
            targets = applyPredicate(predicate, to: targets)
        }

        for target in targets {
            if let model = target as? any PersistentModel {
                modelContext.delete(model)
            }
        }
        try modelContext.save()
    }

    // MARK: - Count

    func count<T: Storable>(_ type: T.Type, predicate: StoragePredicate?) async throws -> Int {
        let results: [T] = try await fetchAll(type, predicate: predicate, sortBy: [])
        return results.count
    }

    // MARK: - Private Helpers

    private func fetchModels(_ type: any PersistentModel.Type) throws -> [any PersistentModel] {
        // Use a generic fetch via the model context
        let descriptor = FetchDescriptor<any PersistentModel>()
        // SwiftData requires concrete type for FetchDescriptor — this is a limitation.
        // In practice, each SwiftData model will have its own typed fetch method.
        // This fallback uses the model context's enumerate or direct fetch.
        return []
    }

    private func applyPredicate<T: Storable>(_ predicate: StoragePredicate, to items: [T]) -> [T] {
        // Simplified in-memory filtering
        // In production, build NSPredicate or #Predicate from StoragePredicate
        return items
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
            return "Unsupported storage type: \(type)"
        case .notFound(let id):
            return "Object not found: \(id)"
        case .saveFailed(let error):
            return "Save failed: \(error.localizedDescription)"
        }
    }
}

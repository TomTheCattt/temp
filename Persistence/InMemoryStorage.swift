//
//  InMemoryStorage.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - InMemoryStorage

/// A simple in-memory implementation of `LocalStorageProtocol`.
/// Useful for testing, previews, and early development before SwiftData models are ready.
actor InMemoryStorage: LocalStorageProtocol {

    private var store: [String: [any Storable]] = [:]

    private func key<T: Storable>(for type: T.Type) -> String {
        String(describing: type)
    }

    // MARK: - Fetch All

    func fetchAll<T: Storable>(
        _ type: T.Type,
        predicate: StoragePredicate?,
        sortBy: [StorageSortDescriptor]
    ) async throws -> [T] {
        let items = (store[key(for: type)] as? [T]) ?? []
        // Predicate and sort not applied in this simple implementation
        return items
    }

    // MARK: - Fetch by ID

    func fetch<T: Storable>(_ type: T.Type, id: String) async throws -> T? {
        let items = (store[key(for: type)] as? [T]) ?? []
        return items.first { $0.id == id }
    }

    // MARK: - Save

    func save<T: Storable>(_ object: T) async throws {
        let k = key(for: T.self)
        var items = (store[k] as? [T]) ?? []

        // Update existing or append
        if let index = items.firstIndex(where: { $0.id == object.id }) {
            items[index] = object
        } else {
            items.append(object)
        }

        store[k] = items
    }

    // MARK: - Save All

    func saveAll<T: Storable>(_ objects: [T]) async throws {
        for object in objects {
            try await save(object)
        }
    }

    // MARK: - Delete

    func delete<T: Storable>(_ type: T.Type, id: String) async throws {
        let k = key(for: T.self)
        var items = (store[k] as? [T]) ?? []
        items.removeAll { $0.id == id }
        store[k] = items
    }

    // MARK: - Delete All

    func deleteAll<T: Storable>(_ type: T.Type, predicate: StoragePredicate?) async throws {
        let k = key(for: T.self)
        if predicate == nil {
            store[k] = [T]()
        }
        // With predicate: simplified — clear all for now
    }

    // MARK: - Count

    func count<T: Storable>(_ type: T.Type, predicate: StoragePredicate?) async throws -> Int {
        let items = (store[key(for: type)] as? [T]) ?? []
        return items.count
    }
}

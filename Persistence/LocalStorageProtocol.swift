//
//  LocalStorageProtocol.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - LocalStorageProtocol

/// Abstract persistence layer. Implementations can be SwiftData, CoreData, Realm, etc.
/// The Domain layer never depends on a specific persistence framework.
protocol LocalStorageProtocol: Sendable {

    // MARK: - Generic CRUD

    /// Fetch all objects of a given storable type, with optional predicate and sort.
    func fetchAll<T: Storable>(
        _ type: T.Type,
        predicate: StoragePredicate?,
        sortBy: [StorageSortDescriptor]
    ) async throws -> [T]

    /// Fetch a single object by its ID.
    func fetch<T: Storable>(_ type: T.Type, id: String) async throws -> T?

    /// Save (insert or update) an object.
    func save<T: Storable>(_ object: T) async throws

    /// Save multiple objects in batch.
    func saveAll<T: Storable>(_ objects: [T]) async throws

    /// Delete an object by ID.
    func delete<T: Storable>(_ type: T.Type, id: String) async throws

    /// Delete all objects matching a predicate.
    func deleteAll<T: Storable>(_ type: T.Type, predicate: StoragePredicate?) async throws

    /// Count objects matching a predicate.
    func count<T: Storable>(_ type: T.Type, predicate: StoragePredicate?) async throws -> Int
}

// MARK: - Storable

/// Any domain object that can be persisted must conform to Storable.
protocol Storable: Sendable, Identifiable where ID == String {
    var id: String { get }
}

// MARK: - StoragePredicate

/// A framework-agnostic predicate representation.
struct StoragePredicate: Sendable {
    let field: String
    let operation: Operation
    let value: AnySendableValue

    enum Operation: Sendable {
        case equals
        case notEquals
        case greaterThan
        case lessThan
        case contains
        case `in`([AnySendableValue])
    }
}

// MARK: - AnySendableValue

/// Type-erased Sendable value for predicates.
enum AnySendableValue: Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case date(Date)
    case none
}

// MARK: - StorageSortDescriptor

struct StorageSortDescriptor: Sendable {
    let field: String
    let ascending: Bool

    init(_ field: String, ascending: Bool = true) {
        self.field = field
        self.ascending = ascending
    }
}

// MARK: - Convenience extensions

extension LocalStorageProtocol {

    func fetchAll<T: Storable>(_ type: T.Type) async throws -> [T] {
        try await fetchAll(type, predicate: nil, sortBy: [])
    }

    func fetchAll<T: Storable>(_ type: T.Type, predicate: StoragePredicate?) async throws -> [T] {
        try await fetchAll(type, predicate: predicate, sortBy: [])
    }

    func deleteAll<T: Storable>(_ type: T.Type) async throws {
        try await deleteAll(type, predicate: nil)
    }
}

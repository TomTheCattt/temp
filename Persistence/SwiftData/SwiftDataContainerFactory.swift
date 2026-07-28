//
//  SwiftDataContainerFactory.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import SwiftData

// MARK: - SwiftDataContainerFactory

/// Factory to create and configure the SwiftData ModelContainer.
/// Centralized here to make it easy to swap or extend schemas.
enum SwiftDataContainerFactory {

    /// Creates the shared ModelContainer with all app schemas.
    /// NOTE: Add @Model types here as they are created in Persistence/SwiftData/Models/.
    @MainActor
    static func create(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("[SwiftData] Failed to create ModelContainer: \(error)")
        }
    }

    /// Creates an in-memory container for previews and tests.
    @MainActor
    static func createPreview() -> ModelContainer {
        create(inMemory: true)
    }
}

// MARK: - Schema Versioning

/// Versioned schema — add @Model types here as they are created.
/// When adding new models, create a new schema version (SchemaV2, etc.) for migration support.
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            SDCachedUser.self,
            SDCachedPost.self,
            SDCachedConversation.self,
            SDCachedMessage.self,
        ]
    }
}

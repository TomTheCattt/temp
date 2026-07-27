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
    @MainActor
    static func create(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([
            // Register all SwiftData @Model types here:
            // SDUser.self,
            // SDPost.self,
            // SDStory.self,
            // SDMessage.self,
        ])

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

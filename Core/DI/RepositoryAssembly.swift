//
//  RepositoryAssembly.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Swinject

// MARK: - RepositoryAssembly

/// Registers data repositories (each repository abstracts remote + local data sources).
final class RepositoryAssembly: Assembly {

    func assemble(container: Container) {

        // MARK: AuthRepository

        container.register(AuthRepositoryProtocol.self) { _ in
            AuthRepository()
        }.inObjectScope(.container)

        // MARK: UserRepository

        container.register(UserRepositoryProtocol.self) { _ in
            UserRepository()
        }.inObjectScope(.container)

        // MARK: PostRepository

        container.register(PostRepositoryProtocol.self) { _ in
            PostRepository()
        }.inObjectScope(.container)

        // MARK: StoryRepository

        container.register(StoryRepositoryProtocol.self) { _ in
            StoryRepository()
        }.inObjectScope(.container)

        // MARK: NotificationRepository

        container.register(NotificationRepositoryProtocol.self) { _ in
            NotificationRepository()
        }.inObjectScope(.container)

        // MARK: MessageRepository

        container.register(MessageRepositoryProtocol.self) { _ in
            MessageRepository()
        }.inObjectScope(.container)
    }
}

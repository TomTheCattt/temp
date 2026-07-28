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

        container.register(UserRepositoryProtocol.self) { resolver in
            UserRepository(
                remoteDataSource: RemoteUserDataSource(
                    networkService: resolver.resolve(NetworkServiceProtocol.self)!
                )
            )
        }.inObjectScope(.container)

        // MARK: PostRepository

        container.register(PostRepositoryProtocol.self) { resolver in
            PostRepository(
                remoteDataSource: RemotePostDataSource(
                    networkService: resolver.resolve(NetworkServiceProtocol.self)!
                )
            )
        }.inObjectScope(.container)

        // MARK: StoryRepository

        container.register(StoryRepositoryProtocol.self) { resolver in
            StoryRepository(
                remoteDataSource: RemoteStoryDataSource(
                    networkService: resolver.resolve(NetworkServiceProtocol.self)!
                )
            )
        }.inObjectScope(.container)

        // MARK: NotificationRepository

        container.register(NotificationRepositoryProtocol.self) { resolver in
            NotificationRepository(
                remoteDataSource: RemoteNotificationDataSource(
                    networkService: resolver.resolve(NetworkServiceProtocol.self)!
                )
            )
        }.inObjectScope(.container)

        // MARK: MessageRepository

        container.register(MessageRepositoryProtocol.self) { resolver in
            MessageRepository(
                remoteDataSource: RemoteMessageDataSource(
                    networkService: resolver.resolve(NetworkServiceProtocol.self)!
                )
            )
        }.inObjectScope(.container)

        // MARK: CommentRepository

        container.register(CommentRepositoryProtocol.self) { resolver in
            CommentRepository(
                remoteDataSource: RemoteCommentDataSource(
                    networkService: resolver.resolve(NetworkServiceProtocol.self)!
                )
            )
        }.inObjectScope(.container)

        // MARK: ReelRepository

        container.register(ReelRepositoryProtocol.self) { resolver in
            ReelRepository(
                remoteDataSource: RemoteReelDataSource(
                    networkService: resolver.resolve(NetworkServiceProtocol.self)!
                )
            )
        }.inObjectScope(.container)
    }
}

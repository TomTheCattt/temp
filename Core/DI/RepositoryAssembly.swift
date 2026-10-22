//
//  RepositoryAssembly.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Swinject

// MARK: - RepositoryAssembly

/// Registers data repositories.
/// Uses Firebase (Cloud production) or Local Backend depending on configuration.
///
/// - **Instagram** scheme: Uses Firebase production repositories.
/// - **Instagram (Local BE)** scheme (`APP_USE_LOCAL_BACKEND=1`): Uses remote data sources with local backend.
final class RepositoryAssembly: Assembly {

    func assemble(container: Container) {

        // MARK: AuthRepository

        container.register(AuthRepositoryProtocol.self) { resolver in
            if AppConfig.shared.useLocalBackend {
                return AuthRepository(
                    remoteDataSource: RemoteAuthDataSource(
                        networkService: resolver.resolve(NetworkServiceProtocol.self)!
                    )
                )
            }
            return FirebaseAuthRepository()
        }.inObjectScope(.container)

        // MARK: UserRepository

        container.register(UserRepositoryProtocol.self) { resolver in
            if AppConfig.shared.useLocalBackend {
                return UserRepository(
                    remoteDataSource: RemoteUserDataSource(
                        networkService: resolver.resolve(NetworkServiceProtocol.self)!
                    )
                )
            }
            return FirebaseUserRepository()
        }.inObjectScope(.container)

        // MARK: PostRepository

        container.register(PostRepositoryProtocol.self) { resolver in
            if AppConfig.shared.useLocalBackend {
                return PostRepository(
                    remoteDataSource: RemotePostDataSource(
                        networkService: resolver.resolve(NetworkServiceProtocol.self)!
                    )
                )
            }
            return FirebasePostRepository()
        }.inObjectScope(.container)

        // MARK: StoryRepository

        container.register(StoryRepositoryProtocol.self) { resolver in
            if AppConfig.shared.useLocalBackend {
                return StoryRepository(
                    remoteDataSource: RemoteStoryDataSource(
                        networkService: resolver.resolve(NetworkServiceProtocol.self)!
                    ),
                    networkService: resolver.resolve(NetworkServiceProtocol.self)!
                )
            }
            return FirebaseStoryRepository()
        }.inObjectScope(.container)

        // MARK: NotificationRepository

        container.register(NotificationRepositoryProtocol.self) { resolver in
            if AppConfig.shared.useLocalBackend {
                return NotificationRepository(
                    remoteDataSource: RemoteNotificationDataSource(
                        networkService: resolver.resolve(NetworkServiceProtocol.self)!
                    )
                )
            }
            return FirebaseNotificationRepository()
        }.inObjectScope(.container)

        // MARK: MessageRepository

        container.register(MessageRepositoryProtocol.self) { resolver in
            if AppConfig.shared.useLocalBackend {
                return MessageRepository(
                    remoteDataSource: RemoteMessageDataSource(
                        networkService: resolver.resolve(NetworkServiceProtocol.self)!
                    )
                )
            }
            return FirebaseMessageRepository()
        }.inObjectScope(.container)

        // MARK: CommentRepository

        container.register(CommentRepositoryProtocol.self) { resolver in
            if AppConfig.shared.useLocalBackend {
                return CommentRepository(
                    remoteDataSource: RemoteCommentDataSource(
                        networkService: resolver.resolve(NetworkServiceProtocol.self)!
                    )
                )
            }
            return FirebaseCommentRepository()
        }.inObjectScope(.container)

        // MARK: ReelRepository

        container.register(ReelRepositoryProtocol.self) { resolver in
            if AppConfig.shared.useLocalBackend {
                return ReelRepository(
                    remoteDataSource: RemoteReelDataSource(
                        networkService: resolver.resolve(NetworkServiceProtocol.self)!
                    ),
                    networkService: resolver.resolve(NetworkServiceProtocol.self)!
                )
            }
            return FirebaseReelRepository()
        }.inObjectScope(.container)
    }
}

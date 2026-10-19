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
/// Switches between Mock and Remote implementations based on the current API mode
/// configured via Xcode scheme environment variables.
///
/// - **Instagram** scheme (`API_MODE=live`): Uses remote data sources with production API.
/// - **Instagram (Local BE)** scheme (`API_MODE=live`, `APP_USE_LOCAL_BACKEND=1`): Uses remote data sources with local backend.
/// - **Instagram (Mock)** scheme (`API_MODE=mock`): Uses mock repositories with locally generated data.
final class RepositoryAssembly: Assembly {

    func assemble(container: Container) {

        let useMock = AppConfig.shared.isMockAPI
        let useFirebase = AppConfig.shared.isFirebaseAPI

        // MARK: AuthRepository

        container.register(AuthRepositoryProtocol.self) { resolver in
            if useMock {
                return MockAuthRepository()
            }
            if useFirebase {
                return FirebaseAuthRepository()
            }
            return AuthRepository(
                remoteDataSource: RemoteAuthDataSource(
                    networkService: resolver.resolve(NetworkServiceProtocol.self)!
                )
            )
        }.inObjectScope(.container)

        // MARK: UserRepository

        container.register(UserRepositoryProtocol.self) { resolver in
            if useMock {
                return MockUserRepository()
            }
            if useFirebase {
                return FirebaseUserRepository()
            }
            return UserRepository(
                remoteDataSource: RemoteUserDataSource(
                    networkService: resolver.resolve(NetworkServiceProtocol.self)!
                )
            )
        }.inObjectScope(.container)

        // MARK: PostRepository

        container.register(PostRepositoryProtocol.self) { resolver in
            if useMock {
                return MockPostRepository()
            }
            if useFirebase {
                return FirebasePostRepository()
            }
            return PostRepository(
                remoteDataSource: RemotePostDataSource(
                    networkService: resolver.resolve(NetworkServiceProtocol.self)!
                )
            )
        }.inObjectScope(.container)

        // MARK: StoryRepository

        container.register(StoryRepositoryProtocol.self) { resolver in
            if useMock {
                return MockStoryRepository()
            }
            if useFirebase {
                return FirebaseStoryRepository()
            }
            return StoryRepository(
                remoteDataSource: RemoteStoryDataSource(
                    networkService: resolver.resolve(NetworkServiceProtocol.self)!
                ),
                networkService: resolver.resolve(NetworkServiceProtocol.self)!
            )
        }.inObjectScope(.container)

        // MARK: NotificationRepository

        container.register(NotificationRepositoryProtocol.self) { resolver in
            if useMock {
                return MockNotificationRepository()
            }
            if useFirebase {
                return FirebaseNotificationRepository()
            }
            return NotificationRepository(
                remoteDataSource: RemoteNotificationDataSource(
                    networkService: resolver.resolve(NetworkServiceProtocol.self)!
                )
            )
        }.inObjectScope(.container)

        // MARK: MessageRepository

        container.register(MessageRepositoryProtocol.self) { resolver in
            if useMock {
                return MockMessageRepository()
            }
            if useFirebase {
                return FirebaseMessageRepository()
            }
            return MessageRepository(
                remoteDataSource: RemoteMessageDataSource(
                    networkService: resolver.resolve(NetworkServiceProtocol.self)!
                )
            )
        }.inObjectScope(.container)

        // MARK: CommentRepository

        container.register(CommentRepositoryProtocol.self) { resolver in
            if useMock {
                return MockCommentRepository()
            }
            if useFirebase {
                return FirebaseCommentRepository()
            }
            return CommentRepository(
                remoteDataSource: RemoteCommentDataSource(
                    networkService: resolver.resolve(NetworkServiceProtocol.self)!
                )
            )
        }.inObjectScope(.container)

        // MARK: ReelRepository

        container.register(ReelRepositoryProtocol.self) { resolver in
            if useMock {
                return MockReelRepository()
            }
            if useFirebase {
                return FirebaseReelRepository()
            }
            return ReelRepository(
                remoteDataSource: RemoteReelDataSource(
                    networkService: resolver.resolve(NetworkServiceProtocol.self)!
                ),
                networkService: resolver.resolve(NetworkServiceProtocol.self)!
            )
        }.inObjectScope(.container)
    }
}

//
//  RepositoryAssembly.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Swinject

// MARK: - RepositoryAssembly

/// Registers data repositories using Remote (Neon) backend only.
final class RepositoryAssembly: Assembly {

    func assemble(container: Container) {
        // MARK: UploadDataSource (shared across repositories)

        container.register(RemoteUploadDataSource.self) { resolver in
            RemoteUploadDataSource(
                networkService: resolver.resolve(NetworkServiceProtocol.self)!
            )
        }.inObjectScope(.container)

        // MARK: AuthRepository

        container.register(AuthRepositoryProtocol.self) { resolver in
            AuthRepository(
                remoteDataSource: RemoteAuthDataSource(
                    networkService: resolver.resolve(NetworkServiceProtocol.self)!
                ),
                authManager: resolver.resolve(AuthManagerProtocol.self)!
            )
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
                ),
                uploadDataSource: resolver.resolve(RemoteUploadDataSource.self)!
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
                ),
                sessionStore: resolver.resolve(SessionStoreProtocol.self)!
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
                ),
                uploadDataSource: resolver.resolve(RemoteUploadDataSource.self)!
            )
        }.inObjectScope(.container)

        // MARK: ReportRepository

        container.register(ReportRepositoryProtocol.self) { resolver in
            ReportRepository(
                dataSource: RemoteReportDataSource(
                    networkService: resolver.resolve(NetworkServiceProtocol.self)!
                )
            )
        }.inObjectScope(.container)

        // MARK: SearchRepository

        container.register(SearchRepositoryProtocol.self) { resolver in
            SearchRepository(
                dataSource: RemoteSearchDataSource(
                    networkService: resolver.resolve(NetworkServiceProtocol.self)!
                )
            )
        }.inObjectScope(.container)

        // MARK: CallRepository

        container.register(CallRepositoryProtocol.self) { resolver in
            CallRepository(
                dataSource: RemoteCallDataSource(
                    networkService: resolver.resolve(NetworkServiceProtocol.self)!
                )
            )
        }.inObjectScope(.container)

        // MARK: TusRepository

        container.register(TusRepositoryProtocol.self) { resolver in
            TusRepository(
                dataSource: RemoteTusDataSource(
                    networkService: resolver.resolve(NetworkServiceProtocol.self)!
                )
            )
        }.inObjectScope(.container)
    }
}
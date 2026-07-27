//
//  ViewModelAssembly.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Swinject

// MARK: - ViewModelAssembly

/// Registers ViewModels.
/// ViewModels are typically `.transient` (new instance per resolve)
/// unless they need to be shared across screens.
final class ViewModelAssembly: Assembly {

    func assemble(container: Container) {

        // MARK: AuthViewModel

        container.register(AuthViewModel.self) { resolver in
            AuthViewModel(
                loginUseCase: resolver.resolve(LoginUseCaseProtocol.self)!,
                registerUseCase: resolver.resolve(RegisterUseCaseProtocol.self)!
            )
        }

        // MARK: FeedViewModel

        container.register(FeedViewModel.self) { resolver in
            FeedViewModel(
                fetchFeedUseCase: resolver.resolve(FetchFeedUseCaseProtocol.self)!,
                toggleLikeUseCase: resolver.resolve(ToggleLikePostUseCaseProtocol.self)!
            )
        }

        // MARK: ExploreViewModel

        container.register(ExploreViewModel.self) { resolver in
            ExploreViewModel(
                postRepository: resolver.resolve(PostRepositoryProtocol.self)!,
                searchUsersUseCase: resolver.resolve(SearchUsersUseCaseProtocol.self)!
            )
        }

        // MARK: NotificationsViewModel

        container.register(NotificationsViewModel.self) { resolver in
            NotificationsViewModel(
                fetchNotificationsUseCase: resolver.resolve(FetchNotificationsUseCaseProtocol.self)!,
                notificationRepository: resolver.resolve(NotificationRepositoryProtocol.self)!
            )
        }

        // MARK: DirectMessagesViewModel

        container.register(DirectMessagesViewModel.self) { resolver in
            DirectMessagesViewModel(
                messageRepository: resolver.resolve(MessageRepositoryProtocol.self)!
            )
        }
    }
}

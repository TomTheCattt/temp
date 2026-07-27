//
//  UseCaseAssembly.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Swinject

// MARK: - UseCaseAssembly

/// Registers all Domain UseCases.
final class UseCaseAssembly: Assembly {

    func assemble(container: Container) {

        // MARK: Auth

        container.register(LoginUseCaseProtocol.self) { resolver in
            LoginUseCase(
                authRepository: resolver.resolve(AuthRepositoryProtocol.self)!
            )
        }

        container.register(RegisterUseCaseProtocol.self) { resolver in
            RegisterUseCase(
                authRepository: resolver.resolve(AuthRepositoryProtocol.self)!
            )
        }

        // MARK: Feed

        container.register(FetchFeedUseCaseProtocol.self) { resolver in
            FetchFeedUseCase(
                postRepository: resolver.resolve(PostRepositoryProtocol.self)!
            )
        }

        container.register(ToggleLikePostUseCaseProtocol.self) { resolver in
            ToggleLikePostUseCase(
                postRepository: resolver.resolve(PostRepositoryProtocol.self)!
            )
        }

        // MARK: Profile

        container.register(FetchProfileUseCaseProtocol.self) { resolver in
            FetchProfileUseCase(
                userRepository: resolver.resolve(UserRepositoryProtocol.self)!
            )
        }

        container.register(ToggleFollowUseCaseProtocol.self) { resolver in
            ToggleFollowUseCase(
                userRepository: resolver.resolve(UserRepositoryProtocol.self)!
            )
        }

        // MARK: Story

        container.register(FetchStoriesUseCaseProtocol.self) { resolver in
            FetchStoriesUseCase(
                storyRepository: resolver.resolve(StoryRepositoryProtocol.self)!
            )
        }

        // MARK: Search

        container.register(SearchUsersUseCaseProtocol.self) { resolver in
            SearchUsersUseCase(
                userRepository: resolver.resolve(UserRepositoryProtocol.self)!
            )
        }

        // MARK: Notifications

        container.register(FetchNotificationsUseCaseProtocol.self) { resolver in
            FetchNotificationsUseCase(
                notificationRepository: resolver.resolve(NotificationRepositoryProtocol.self)!
            )
        }
    }
}

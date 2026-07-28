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

        // MARK: Comment

        container.register(FetchCommentsUseCaseProtocol.self) { resolver in
            FetchCommentsUseCase(
                commentRepository: resolver.resolve(CommentRepositoryProtocol.self)!
            )
        }

        container.register(AddCommentUseCaseProtocol.self) { resolver in
            AddCommentUseCase(
                commentRepository: resolver.resolve(CommentRepositoryProtocol.self)!
            )
        }

        // MARK: Post Detail / Create

        container.register(FetchPostDetailUseCaseProtocol.self) { resolver in
            FetchPostDetailUseCase(
                postRepository: resolver.resolve(PostRepositoryProtocol.self)!
            )
        }

        container.register(CreatePostUseCaseProtocol.self) { resolver in
            CreatePostUseCase(
                postRepository: resolver.resolve(PostRepositoryProtocol.self)!
            )
        }

        // MARK: Reel

        container.register(FetchReelsUseCaseProtocol.self) { resolver in
            FetchReelsUseCase(
                reelRepository: resolver.resolve(ReelRepositoryProtocol.self)!
            )
        }

        container.register(ToggleLikeReelUseCaseProtocol.self) { resolver in
            ToggleLikeReelUseCase(
                reelRepository: resolver.resolve(ReelRepositoryProtocol.self)!
            )
        }

        // MARK: Message

        container.register(FetchMessagesUseCaseProtocol.self) { resolver in
            FetchMessagesUseCase(
                messageRepository: resolver.resolve(MessageRepositoryProtocol.self)!
            )
        }

        container.register(SendMessageUseCaseProtocol.self) { resolver in
            SendMessageUseCase(
                messageRepository: resolver.resolve(MessageRepositoryProtocol.self)!
            )
        }

        // MARK: Profile Update

        container.register(UpdateProfileUseCaseProtocol.self) { resolver in
            UpdateProfileUseCase(
                userRepository: resolver.resolve(UserRepositoryProtocol.self)!
            )
        }

        // MARK: Follow List

        container.register(FetchFollowersUseCaseProtocol.self) { resolver in
            FetchFollowersUseCase(
                userRepository: resolver.resolve(UserRepositoryProtocol.self)!
            )
        }

        container.register(FetchFollowingUseCaseProtocol.self) { resolver in
            FetchFollowingUseCase(
                userRepository: resolver.resolve(UserRepositoryProtocol.self)!
            )
        }
    }
}

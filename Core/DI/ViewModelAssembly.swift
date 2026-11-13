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
                registerUseCase: resolver.resolve(RegisterUseCaseProtocol.self)!,
                biometricAuthUseCase: resolver.resolve(BiometricAuthUseCaseProtocol.self)!,
                webSocketConnectionManager: resolver.resolve(WebSocketConnectionManagerProtocol.self)!
            )
        }

        // MARK: FeedViewModel

        container.register(FeedViewModel.self) { resolver in
            FeedViewModel(
                fetchFeedUseCase: resolver.resolve(FetchFeedUseCaseProtocol.self)!,
                toggleLikeUseCase: resolver.resolve(ToggleLikePostUseCaseProtocol.self)!,
                toggleSaveUseCase: resolver.resolve(ToggleSavePostUseCaseProtocol.self)!,
                fetchUnreadNotificationCountUseCase: resolver.resolve(FetchUnreadNotificationCountUseCaseProtocol.self)!
            )
        }

        // MARK: ExploreViewModel

        container.register(ExploreViewModel.self) { resolver in
            ExploreViewModel(
                fetchExplorePostsUseCase: resolver.resolve(FetchExplorePostsUseCaseProtocol.self)!,
                searchUsersUseCase: resolver.resolve(SearchUsersUseCaseProtocol.self)!
            )
        }

        // MARK: NotificationsViewModel

        container.register(NotificationsViewModel.self) { resolver in
            NotificationsViewModel(
                fetchNotificationsUseCase: resolver.resolve(FetchNotificationsUseCaseProtocol.self)!,
                markNotificationsAsReadUseCase: resolver.resolve(MarkNotificationsAsReadUseCaseProtocol.self)!
            )
        }

        // MARK: DirectMessagesViewModel

        container.register(DirectMessagesViewModel.self) { resolver in
            DirectMessagesViewModel(
                fetchConversationsUseCase: resolver.resolve(FetchConversationsUseCaseProtocol.self)!,
                manageConversationUseCase: resolver.resolve(ManageConversationUseCaseProtocol.self)!,
                notesUseCase: resolver.resolve(NotesUseCaseProtocol.self)!
            )
        }

        // MARK: ChatViewModel

        container.register(ChatViewModel.self) { resolver in
            let sessionStore = resolver.resolve(SessionStoreProtocol.self)
            let currentUserId = sessionStore?.currentUserId ?? ""
            return ChatViewModel(
                conversationId: "",
                currentUserId: currentUserId,
                recipient: nil,
                fetchMessagesUseCase: resolver.resolve(FetchMessagesUseCaseProtocol.self)!,
                sendMessageUseCase: resolver.resolve(SendMessageUseCaseProtocol.self)!,
                manageMessageUseCase: resolver.resolve(ManageMessageUseCaseProtocol.self)!,
                chatSyncService: resolver.resolve(ChatSyncService.self)!
            )
        }

        // MARK: ReelsViewModel

        container.register(ReelsViewModel.self) { resolver in
            ReelsViewModel(
                fetchReelsUseCase: resolver.resolve(FetchReelsUseCaseProtocol.self)!,
                toggleLikeReelUseCase: resolver.resolve(ToggleLikeReelUseCaseProtocol.self)!,
                toggleFollowUseCase: resolver.resolve(ToggleFollowUseCaseProtocol.self)!,
                toggleSaveReelUseCase: resolver.resolve(ToggleSaveReelUseCaseProtocol.self)!
            )
        }

        // MARK: CreatePostViewModel

        container.register(CreatePostViewModel.self) { resolver in
            CreatePostViewModel(
                createPostUseCase: resolver.resolve(CreatePostUseCaseProtocol.self)!
            )
        }

        // MARK: EditProfileViewModel

        container.register(EditProfileViewModel.self) { resolver in
            EditProfileViewModel(
                updateProfileUseCase: resolver.resolve(UpdateProfileUseCaseProtocol.self)!
            )
        }

        // MARK: SettingsViewModel

        container.register(SettingsViewModel.self) { resolver in
            SettingsViewModel(
                logoutUseCase: resolver.resolve(LogoutUseCaseProtocol.self)!,
                userSettingsUseCase: resolver.resolve(UserSettingsUseCaseProtocol.self)!,
                biometricAuthUseCase: resolver.resolve(BiometricAuthUseCaseProtocol.self)!,
                keychainManager: resolver.resolve(KeychainManagerProtocol.self)! ,
                webSocketConnectionManager: resolver.resolve(WebSocketConnectionManagerProtocol.self)!
            )
        }

        // MARK: SavedPostsViewModel

        container.register(SavedPostsViewModel.self) { resolver in
            SavedPostsViewModel(
                fetchSavedPostsUseCase: resolver.resolve(FetchSavedPostsUseCaseProtocol.self)!
            )
        }

        // MARK: BlockedAccountsViewModel

        container.register(BlockedAccountsViewModel.self) { resolver in
            BlockedAccountsViewModel(
                blockedAccountsUseCase: resolver.resolve(BlockedAccountsUseCaseProtocol.self)!
            )
        }

        // MARK: CloseFriendsViewModel

        container.register(CloseFriendsViewModel.self) { resolver in
            CloseFriendsViewModel(
                closeFriendsUseCase: resolver.resolve(CloseFriendsUseCaseProtocol.self)!
            )
        }
    }
}

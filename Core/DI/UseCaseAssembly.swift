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

        container.register(ChangePasswordUseCaseProtocol.self) { resolver in
            ChangePasswordUseCase(
                authRepository: resolver.resolve(AuthRepositoryProtocol.self)!
            )
        }

        container.register(BiometricAuthUseCaseProtocol.self) { resolver in
            BiometricAuthUseCase(
                biometricAuthenticator: resolver.resolve(BiometricAuthenticating.self)!,
                keychainManager: resolver.resolve(KeychainManagerProtocol.self)!
            )
        }.inObjectScope(.container)

        // MARK: Auth - Password Reset & Email Verification

        container.register(ForgotPasswordUseCaseProtocol.self) { resolver in
            ForgotPasswordUseCase(
                authRepository: resolver.resolve(AuthRepositoryProtocol.self)!
            )
        }

        container.register(ResetPasswordUseCaseProtocol.self) { resolver in
            ResetPasswordUseCase(
                authRepository: resolver.resolve(AuthRepositoryProtocol.self)!
            )
        }

        container.register(VerifyEmailUseCaseProtocol.self) { resolver in
            VerifyEmailUseCase(
                authRepository: resolver.resolve(AuthRepositoryProtocol.self)!
            )
        }

        container.register(ResendVerificationUseCaseProtocol.self) { resolver in
            ResendVerificationUseCase(
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

        container.register(ToggleSavePostUseCaseProtocol.self) { resolver in
            ToggleSavePostUseCase(
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

        container.register(MarkStoryViewedUseCaseProtocol.self) { resolver in
            MarkStoryViewedUseCase(
                storyRepository: resolver.resolve(StoryRepositoryProtocol.self)!
            )
        }

        container.register(DeleteStoryUseCaseProtocol.self) { resolver in
            DeleteStoryUseCase(
                storyRepository: resolver.resolve(StoryRepositoryProtocol.self)!
            )
        }

        // MARK: Search

        container.register(SearchUsersUseCaseProtocol.self) { resolver in
            SearchUsersUseCase(
                userRepository: resolver.resolve(UserRepositoryProtocol.self)!
            )
        }

        // MARK: Search (New - from BE sync)

        container.register(SearchUseCaseProtocol.self) { resolver in
            SearchUseCase(
                repository: resolver.resolve(SearchRepositoryProtocol.self)!
            )
        }

        container.register(GetSearchSuggestionsUseCaseProtocol.self) { resolver in
            GetSearchSuggestionsUseCase(
                repository: resolver.resolve(SearchRepositoryProtocol.self)!
            )
        }

        container.register(GetRecentSearchesUseCaseProtocol.self) { resolver in
            GetRecentSearchesUseCase(
                repository: resolver.resolve(SearchRepositoryProtocol.self)!
            )
        }

        container.register(ClearSearchHistoryUseCaseProtocol.self) { resolver in
            ClearSearchHistoryUseCase(
                repository: resolver.resolve(SearchRepositoryProtocol.self)!
            )
        }

        container.register(GetTrendingHashtagsUseCaseProtocol.self) { resolver in
            GetTrendingHashtagsUseCase(
                repository: resolver.resolve(SearchRepositoryProtocol.self)!
            )
        }

        container.register(GetSearchAnalyticsUseCaseProtocol.self) { resolver in
            GetSearchAnalyticsUseCase(
                repository: resolver.resolve(SearchRepositoryProtocol.self)!
            )
        }

        container.register(GetHashtagPageUseCaseProtocol.self) { resolver in
            GetHashtagPageUseCase(
                repository: resolver.resolve(SearchRepositoryProtocol.self)!
            )
        }

        container.register(GetLocationPageUseCaseProtocol.self) { resolver in
            GetLocationPageUseCase(
                repository: resolver.resolve(SearchRepositoryProtocol.self)!
            )
        }

        // MARK: Notifications

        container.register(FetchNotificationsUseCaseProtocol.self) { resolver in
            FetchNotificationsUseCase(
                notificationRepository: resolver.resolve(NotificationRepositoryProtocol.self)!
            )
        }

        container.register(FetchUnreadNotificationCountUseCaseProtocol.self) { resolver in
            FetchUnreadNotificationCountUseCase(
                notificationRepository: resolver.resolve(NotificationRepositoryProtocol.self)!
            )
        }

        container.register(MarkNotificationsAsReadUseCaseProtocol.self) { resolver in
            MarkNotificationsAsReadUseCase(
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

        container.register(UpdatePostUseCaseProtocol.self) { resolver in
            UpdatePostUseCase(
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

        // MARK: Report (New - from BE sync)

        container.register(CreateReportUseCaseProtocol.self) { resolver in
            CreateReportUseCase(
                repository: resolver.resolve(ReportRepositoryProtocol.self)!
            )
        }

        container.register(GetMyReportsUseCaseProtocol.self) { resolver in
            GetMyReportsUseCase(
                repository: resolver.resolve(ReportRepositoryProtocol.self)!
            )
        }

        container.register(GetReportDetailUseCaseProtocol.self) { resolver in
            GetReportDetailUseCase(
                repository: resolver.resolve(ReportRepositoryProtocol.self)!
            )
        }

        container.register(GetAllReportsUseCaseProtocol.self) { resolver in
            GetAllReportsUseCase(
                repository: resolver.resolve(ReportRepositoryProtocol.self)!
            )
        }

        container.register(UpdateReportStatusUseCaseProtocol.self) { resolver in
            UpdateReportStatusUseCase(
                repository: resolver.resolve(ReportRepositoryProtocol.self)!
            )
        }

        // MARK: Call (New - from BE sync)

        container.register(GetCallHistoryUseCaseProtocol.self) { resolver in
            GetCallHistoryUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        container.register(GetCallDetailUseCaseProtocol.self) { resolver in
            GetCallDetailUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        container.register(CreateCallRecordUseCaseProtocol.self) { resolver in
            CreateCallRecordUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        container.register(UpdateCallRecordUseCaseProtocol.self) { resolver in
            UpdateCallRecordUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        container.register(RegisterCallKitDeviceUseCaseProtocol.self) { resolver in
            RegisterCallKitDeviceUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        container.register(ReportCallKitResultUseCaseProtocol.self) { resolver in
            ReportCallKitResultUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        // Additional Call use cases (New - from BE sync)

        container.register(JoinCallUseCaseProtocol.self) { resolver in
            JoinCallUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        container.register(LeaveCallUseCaseProtocol.self) { resolver in
            LeaveCallUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        container.register(EndCallUseCaseProtocol.self) { resolver in
            EndCallUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        container.register(InviteParticipantsUseCaseProtocol.self) { resolver in
            InviteParticipantsUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        container.register(KickParticipantUseCaseProtocol.self) { resolver in
            KickParticipantUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        container.register(UpdateParticipantUseCaseProtocol.self) { resolver in
            UpdateParticipantUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        container.register(TransferHostUseCaseProtocol.self) { resolver in
            TransferHostUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        container.register(GetCallRecordingUseCaseProtocol.self) { resolver in
            GetCallRecordingUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        container.register(RecordQualityMetricsUseCaseProtocol.self) { resolver in
            RecordQualityMetricsUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        container.register(GetQualityMetricsUseCaseProtocol.self) { resolver in
            GetQualityMetricsUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        container.register(UpdateVoipTokenUseCaseProtocol.self) { resolver in
            UpdateVoipTokenUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        container.register(UnregisterCallKitDeviceUseCaseProtocol.self) { resolver in
            UnregisterCallKitDeviceUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        container.register(ListCallKitDevicesUseCaseProtocol.self) { resolver in
            ListCallKitDevicesUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        container.register(GetIceServersUseCaseProtocol.self) { resolver in
            GetIceServersUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        container.register(TestIncomingCallUseCaseProtocol.self) { resolver in
            TestIncomingCallUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        container.register(TestCallEventUseCaseProtocol.self) { resolver in
            TestCallEventUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        container.register(CallInitiatedUseCaseProtocol.self) { resolver in
            CallInitiatedUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        container.register(CallEventUseCaseProtocol.self) { resolver in
            CallEventUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        container.register(GetCallKitStatsUseCaseProtocol.self) { resolver in
            GetCallKitStatsUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        container.register(CleanupCallKitDevicesUseCaseProtocol.self) { resolver in
            CleanupCallKitDevicesUseCase(
                repository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }

        // MARK: TUS Upload (New - from BE sync)

        container.register(CreateTusUploadUseCaseProtocol.self) { resolver in
            CreateTusUploadUseCase(
                repository: resolver.resolve(TusRepositoryProtocol.self)!
            )
        }

        container.register(UploadTusChunkUseCaseProtocol.self) { resolver in
            UploadTusChunkUseCase(
                repository: resolver.resolve(TusRepositoryProtocol.self)!
            )
        }

        container.register(CompleteTusUploadUseCaseProtocol.self) { resolver in
            CompleteTusUploadUseCase(
                repository: resolver.resolve(TusRepositoryProtocol.self)!
            )
        }

        container.register(GetTusUploadInfoUseCaseProtocol.self) { resolver in
            GetTusUploadInfoUseCase(
                repository: resolver.resolve(TusRepositoryProtocol.self)!
            )
        }

        container.register(DeleteTusUploadUseCaseProtocol.self) { resolver in
            DeleteTusUploadUseCase(
                repository: resolver.resolve(TusRepositoryProtocol.self)!
            )
        }

        // MARK: Clean Architecture Refactor UseCases

        container.register(FetchExplorePostsUseCaseProtocol.self) { resolver in
            FetchExplorePostsUseCase(
                postRepository: resolver.resolve(PostRepositoryProtocol.self)!
            )
        }

        container.register(FetchSavedPostsUseCaseProtocol.self) { resolver in
            FetchSavedPostsUseCase(
                postRepository: resolver.resolve(PostRepositoryProtocol.self)!
            )
        }

        container.register(FetchUserPostsUseCaseProtocol.self) { resolver in
            FetchUserPostsUseCase(
                postRepository: resolver.resolve(PostRepositoryProtocol.self)!
            )
        }

        container.register(FetchUserReelsUseCaseProtocol.self) { resolver in
            FetchUserReelsUseCase(
                reelRepository: resolver.resolve(ReelRepositoryProtocol.self)!
            )
        }

        container.register(ToggleSaveReelUseCaseProtocol.self) { resolver in
            ToggleSaveReelUseCase(
                reelRepository: resolver.resolve(ReelRepositoryProtocol.self)!
            )
        }

        container.register(FetchReelDetailUseCaseProtocol.self) { resolver in
            FetchReelDetailUseCase(
                reelRepository: resolver.resolve(ReelRepositoryProtocol.self)!
            )
        }

        container.register(DeleteReelUseCaseProtocol.self) { resolver in
            DeleteReelUseCase(
                reelRepository: resolver.resolve(ReelRepositoryProtocol.self)!
            )
        }

        container.register(FetchConversationsUseCaseProtocol.self) { resolver in
            FetchConversationsUseCase(
                messageRepository: resolver.resolve(MessageRepositoryProtocol.self)!
            )
        }

        container.register(FetchUnreadChatCountUseCaseProtocol.self) { resolver in
            FetchUnreadChatCountUseCase(
                messageRepository: resolver.resolve(MessageRepositoryProtocol.self)!
            )
        }

        container.register(ManageConversationUseCaseProtocol.self) { resolver in
            ManageConversationUseCase(
                messageRepository: resolver.resolve(MessageRepositoryProtocol.self)!
            )
        }

        container.register(ManageMessageUseCaseProtocol.self) { resolver in
            ManageMessageUseCase(
                messageRepository: resolver.resolve(MessageRepositoryProtocol.self)!
            )
        }

        container.register(NotesUseCaseProtocol.self) { resolver in
            NotesUseCase(
                messageRepository: resolver.resolve(MessageRepositoryProtocol.self)!
            )
        }

        container.register(GroupChatUseCaseProtocol.self) { resolver in
            GroupChatUseCase(
                messageRepository: resolver.resolve(MessageRepositoryProtocol.self)!
            )
        }

        container.register(BlockedAccountsUseCaseProtocol.self) { resolver in
            BlockedAccountsUseCase(
                userRepository: resolver.resolve(UserRepositoryProtocol.self)!
            )
        }

        container.register(CloseFriendsUseCaseProtocol.self) { resolver in
            CloseFriendsUseCase(
                userRepository: resolver.resolve(UserRepositoryProtocol.self)!
            )
        }

        container.register(FetchSuggestedUsersUseCaseProtocol.self) { resolver in
            FetchSuggestedUsersUseCase(
                userRepository: resolver.resolve(UserRepositoryProtocol.self)!
            )
        }

        container.register(UserSettingsUseCaseProtocol.self) { resolver in
            UserSettingsUseCase(
                userRepository: resolver.resolve(UserRepositoryProtocol.self)!
            )
        }

        container.register(LogoutUseCaseProtocol.self) { resolver in
            LogoutUseCase(
                authRepository: resolver.resolve(AuthRepositoryProtocol.self)!
            )
        }

        container.register(StoryRepliesUseCaseProtocol.self) { resolver in
            StoryRepliesUseCase(
                storyRepository: resolver.resolve(StoryRepositoryProtocol.self)!
            )
        }

        container.register(CallHistoryUseCaseProtocol.self) { resolver in
            CallHistoryUseCase(
                callRepository: resolver.resolve(CallRepositoryProtocol.self)!
            )
        }
    }
}
//
//  MainTabView.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI

// MARK: - MainTabView

struct MainTabView: View {

    @State private var router = AppRouter.shared
    @State private var appState = AppState.shared

    var body: some View {
        TabView(selection: $router.selectedTab) {
            // MARK: 1. Feed Tab
            NavigationStack(path: $router.feedPath) {
                FeedView()
                    .navigationDestination(for: AppRoute.self) { route in
                        routeDestination(route)
                    }
            }
            .tag(AppTab.feed)
            .tabItem { tabLabel(for: .feed) }

            // MARK: 2. Reels Tab
            NavigationStack(path: $router.reelsPath) {
                ReelsView(
                    viewModel: DIContainer.shared.resolve(ReelsViewModel.self)
                )
                .navigationDestination(for: AppRoute.self) { route in
                    routeDestination(route)
                }
            }
            .tag(AppTab.reels)
            .tabItem { tabLabel(for: .reels) }

            // MARK: 3. Chat Tab
            NavigationStack(path: $router.chatPath) {
                DirectMessagesView()
                    .navigationDestination(for: AppRoute.self) { route in
                        routeDestination(route)
                    }
            }
            .tag(AppTab.chat)
            .tabItem { tabLabel(for: .chat) }
            .badge(appState.unreadChatCount)

            // MARK: 4. Explore Tab
            NavigationStack(path: $router.explorePath) {
                ExploreView()
                    .navigationDestination(for: AppRoute.self) { route in
                        routeDestination(route)
                    }
            }
            .tag(AppTab.explore)
            .tabItem { tabLabel(for: .explore) }

            // MARK: 5. Profile Tab
            NavigationStack(path: $router.profilePath) {
                ProfileView(userId: nil)
                    .navigationDestination(for: AppRoute.self) { route in
                        routeDestination(route)
                    }
            }
            .tag(AppTab.profile)
            .tabItem { tabLabel(for: .profile) }
        }
        .tint(.primary)
        .sheet(item: $router.presentedSheet) { sheet in
            sheetContent(sheet)
        }
        .fullScreenCover(item: $router.presentedFullScreen) { fullScreen in
            fullScreenContent(fullScreen)
        }
    }

    // MARK: - Tab Label
    
    @ViewBuilder
    private func tabLabel(for tab: AppTab) -> some View {
        let isSelected = router.selectedTab == tab
        Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
    }

    // MARK: - Route Destination

    @ViewBuilder
    private func routeDestination(_ route: AppRoute) -> some View {
        switch route {
        case .userProfile(let userId):
            ProfileView(userId: userId)

        case .followers(let userId):
            FollowListView(
                viewModel: FollowListViewModel(
                    userId: userId,
                    mode: .followers,
                    fetchFollowersUseCase: DIContainer.shared.resolve(FetchFollowersUseCaseProtocol.self),
                    fetchFollowingUseCase: DIContainer.shared.resolve(FetchFollowingUseCaseProtocol.self),
                    toggleFollowUseCase: DIContainer.shared.resolve(ToggleFollowUseCaseProtocol.self)
                )
            )

        case .following(let userId):
            FollowListView(
                viewModel: FollowListViewModel(
                    userId: userId,
                    mode: .following,
                    fetchFollowersUseCase: DIContainer.shared.resolve(FetchFollowersUseCaseProtocol.self),
                    fetchFollowingUseCase: DIContainer.shared.resolve(FetchFollowingUseCaseProtocol.self),
                    toggleFollowUseCase: DIContainer.shared.resolve(ToggleFollowUseCaseProtocol.self)
                )
            )

        case .settings:
            SettingsView(
                viewModel: DIContainer.shared.resolve(SettingsViewModel.self)
            )

        case .postDetail(let postId):
            PostDetailView(
                viewModel: PostDetailViewModel(
                    postId: postId,
                    fetchPostDetailUseCase: DIContainer.shared.resolve(FetchPostDetailUseCaseProtocol.self),
                    fetchCommentsUseCase: DIContainer.shared.resolve(FetchCommentsUseCaseProtocol.self),
                    toggleLikeUseCase: DIContainer.shared.resolve(ToggleLikePostUseCaseProtocol.self),
                    addCommentUseCase: DIContainer.shared.resolve(AddCommentUseCaseProtocol.self)
                )
            )

        case .comments(let postId):
            CommentsView(
                viewModel: CommentsViewModel(
                    postId: postId,
                    fetchCommentsUseCase: DIContainer.shared.resolve(FetchCommentsUseCaseProtocol.self),
                    addCommentUseCase: DIContainer.shared.resolve(AddCommentUseCaseProtocol.self)
                )
            )

        case .likes(let postId):
            LikesListView(
                viewModel: LikesListViewModel(
                    postId: postId,
                    userRepository: DIContainer.shared.resolve(UserRepositoryProtocol.self),
                    toggleFollowUseCase: DIContainer.shared.resolve(ToggleFollowUseCaseProtocol.self)
                )
            )

        case .notifications:
            NotificationsView()

        case .directMessages:
            DirectMessagesView()

        case .conversation(let conversationId, let recipient):
            ChatView(
                viewModel: ChatViewModel(
                    conversationId: conversationId,
                    currentUserId: SessionStore.shared.currentUserId,
                    recipient: recipient,
                    fetchMessagesUseCase: DIContainer.shared.resolve(FetchMessagesUseCaseProtocol.self),
                    sendMessageUseCase: DIContainer.shared.resolve(SendMessageUseCaseProtocol.self),
                    messageRepository: DIContainer.shared.resolve(MessageRepositoryProtocol.self)
                )
            )

        case .conversationDetails(let conversationId, let recipient):
            ConversationDetailsView(conversationId: conversationId, recipient: recipient)

        case .searchResults(let query):
            SearchResultsView(
                viewModel: SearchResultsViewModel(
                    query: query,
                    searchUsersUseCase: DIContainer.shared.resolve(SearchUsersUseCaseProtocol.self),
                    postRepository: DIContainer.shared.resolve(PostRepositoryProtocol.self)
                )
            )

        case .hashtag(let name):
            HashtagView(
                viewModel: HashtagViewModel(
                    hashtagName: name,
                    postRepository: DIContainer.shared.resolve(PostRepositoryProtocol.self)
                )
            )

        case .location(let name):
            LocationView(
                viewModel: LocationViewModel(
                    locationName: name,
                    postRepository: DIContainer.shared.resolve(PostRepositoryProtocol.self)
                )
            )

        // Settings Sub-screens
        case .savedPosts:
            SavedPostsView(
                viewModel: SavedPostsViewModel(
                    postRepository: DIContainer.shared.resolve(PostRepositoryProtocol.self)
                )
            )

        case .closeFriends:
            CloseFriendsView(
                viewModel: CloseFriendsViewModel(
                    userRepository: DIContainer.shared.resolve(UserRepositoryProtocol.self)
                )
            )

        case .blockedAccounts:
            BlockedAccountsView(
                viewModel: BlockedAccountsViewModel(
                    userRepository: DIContainer.shared.resolve(UserRepositoryProtocol.self)
                )
            )

        case .changePassword:
            ChangePasswordView()

        case .twoFactorAuth:
            TwoFactorAuthView()

        case .termsOfService:
            TermsOfServiceView()

        case .privacyPolicy:
            PrivacyPolicyView()

        case .openSourceLicenses:
            OpenSourceLicensesView()
        }
    }

    // MARK: - Sheet Content

    @ViewBuilder
    private func sheetContent(_ sheet: AppSheet) -> some View {
        switch sheet {
        case .createMenu:
            CreateActionSheetView()

        case .createPost:
            UnifiedCreationHubView(initialMode: .post)

        case .createStory:
            UnifiedCreationHubView(initialMode: .story)

        case .createReel:
            UnifiedCreationHubView(initialMode: .reel)

        case .editProfile:
            EditProfileView(
                viewModel: EditProfileViewModel(
                    updateProfileUseCase: DIContainer.shared.resolve(UpdateProfileUseCaseProtocol.self),
                    userRepository: DIContainer.shared.resolve(UserRepositoryProtocol.self)
                )
            )

        case .sharePost(let postId):
            SharePostView(
                viewModel: SharePostViewModel(
                    postId: postId,
                    userRepository: DIContainer.shared.resolve(UserRepositoryProtocol.self),
                    messageRepository: DIContainer.shared.resolve(MessageRepositoryProtocol.self)
                )
            )

        case .reportPost(let postId):
            ReportPostView(postId: postId)

        case .editPost(let postId):
            EditPostView(
                viewModel: EditPostViewModel(
                    postId: postId,
                    fetchPostDetailUseCase: DIContainer.shared.resolve(FetchPostDetailUseCaseProtocol.self),
                    updatePostUseCase: DIContainer.shared.resolve(UpdatePostUseCaseProtocol.self)
                )
            )

        case .reelComments(let reelId):
            // Reel comments reuse the post comments UI/contract, keyed by the reel id.
            // Presented as a sheet at ~2/3 screen height, matching Instagram.
            NavigationStack {
                CommentsView(
                    viewModel: CommentsViewModel(
                        postId: reelId,
                        fetchCommentsUseCase: DIContainer.shared.resolve(FetchCommentsUseCaseProtocol.self),
                        addCommentUseCase: DIContainer.shared.resolve(AddCommentUseCaseProtocol.self)
                    )
                )
            }
            .presentationDetents([.fraction(Constants.reelCommentsSheetFraction)])
            .presentationDragIndicator(.visible)

        case .newMessage:
            NewMessageSheet()
        }
    }

    // MARK: - Full Screen Content

    @ViewBuilder
    private func fullScreenContent(_ fullScreen: AppFullScreen) -> some View {
        switch fullScreen {
        case .camera:
            StoryCameraView(
                viewModel: StoryCameraViewModel(
                    storyRepository: DIContainer.shared.resolve(StoryRepositoryProtocol.self)
                )
            )

        case .mediaViewer(let url):
            MediaViewerView(url: url)

        case .storyCamera:
            StoryCameraView(
                viewModel: StoryCameraViewModel(
                    storyRepository: DIContainer.shared.resolve(StoryRepositoryProtocol.self)
                )
            )

        case .storyViewer(let userId):
            StoryViewerView(
                viewModel: StoryViewerViewModel(
                    targetUserId: userId,
                    fetchStoriesUseCase: DIContainer.shared.resolve(FetchStoriesUseCaseProtocol.self)
                )
            )
            .presentationBackground(.clear)

        case .myStory:
            MyStoryView(
                viewModel: StoryViewerViewModel(
                    targetUserId: SessionStore.shared.currentUserId,
                    fetchStoriesUseCase: DIContainer.shared.resolve(FetchStoriesUseCaseProtocol.self)
                )
            )
            .presentationBackground(.clear)

        case .createPost:
            UnifiedCreationHubView(initialMode: .post)

        case .createStory:
            UnifiedCreationHubView(initialMode: .story)

        case .createReel:
            UnifiedCreationHubView(initialMode: .reel)

        case .creationHub(let mode):
            UnifiedCreationHubView(initialMode: mode)

        case .call(let userId, let userName, let hasVideo):
            CallView(
                viewModel: CallViewModel(
                    remoteUserId: userId,
                    remoteName: userName,
                    hasVideo: hasVideo
                )
            )
        }
    }

    // MARK: - Constants

    private enum Constants {
        /// Reel comments sheet height ≈ 2/3 of the screen (Instagram-style).
        static let reelCommentsSheetFraction: CGFloat = 2.0 / 3.0
    }
}

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

    var body: some View {
        TabView(selection: $router.selectedTab) {
            // MARK: Feed Tab
            NavigationStack(path: $router.feedPath) {
                FeedView()
                    .navigationDestination(for: AppRoute.self) { route in
                        routeDestination(route)
                    }
            }
            .tag(AppTab.feed)
            .tabItem { tabLabel(for: .feed) }

            // MARK: Explore Tab
            NavigationStack(path: $router.explorePath) {
                ExploreView()
                    .navigationDestination(for: AppRoute.self) { route in
                        routeDestination(route)
                    }
            }
            .tag(AppTab.explore)
            .tabItem { tabLabel(for: .explore) }

            // MARK: Reels Tab
            NavigationStack(path: $router.reelsPath) {
                ReelsView(
                    viewModel: ReelsViewModel(
                        fetchReelsUseCase: DIContainer.shared.resolve(FetchReelsUseCaseProtocol.self),
                        toggleLikeReelUseCase: DIContainer.shared.resolve(ToggleLikeReelUseCaseProtocol.self)
                    )
                )
                .navigationDestination(for: AppRoute.self) { route in
                    routeDestination(route)
                }
            }
            .tag(AppTab.reels)
            .tabItem { tabLabel(for: .reels) }

            // MARK: Notifications Tab
            NavigationStack(path: $router.notificationsPath) {
                NotificationsView()
                    .navigationDestination(for: AppRoute.self) { route in
                        routeDestination(route)
                    }
            }
            .tag(AppTab.notifications)
            .tabItem { tabLabel(for: .notifications) }

            // MARK: Profile Tab
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
        Label(tab.title, systemImage: isSelected ? tab.selectedIcon : tab.icon)
    }

    // MARK: - Route Destination

    @ViewBuilder
    private func routeDestination(_ route: AppRoute) -> some View {
        switch route {
        case .userProfile(let userId):
            ProfileView(userId: userId)

        case .editProfile:
            EditProfileView(
                viewModel: EditProfileViewModel(
                    updateProfileUseCase: DIContainer.shared.resolve(UpdateProfileUseCaseProtocol.self),
                    userRepository: DIContainer.shared.resolve(UserRepositoryProtocol.self)
                )
            )

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
                viewModel: SettingsViewModel(
                    authRepository: DIContainer.shared.resolve(AuthRepositoryProtocol.self),
                    userRepository: DIContainer.shared.resolve(UserRepositoryProtocol.self)
                )
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

        case .directMessages:
            DirectMessagesView()

        case .conversation(let conversationId):
            ChatView(
                viewModel: ChatViewModel(
                    conversationId: conversationId,
                    fetchMessagesUseCase: DIContainer.shared.resolve(FetchMessagesUseCaseProtocol.self),
                    sendMessageUseCase: DIContainer.shared.resolve(SendMessageUseCaseProtocol.self),
                    messageRepository: DIContainer.shared.resolve(MessageRepositoryProtocol.self)
                )
            )

        case .storyViewer:
            // Story viewer is typically presented via fullScreenCover
            // When pushed, show a placeholder that redirects
            Text("Use fullScreenCover for story viewer")

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
        }
    }

    // MARK: - Sheet Content

    @ViewBuilder
    private func sheetContent(_ sheet: AppSheet) -> some View {
        switch sheet {
        case .createPost:
            CreatePostView(
                viewModel: CreatePostViewModel(
                    createPostUseCase: DIContainer.shared.resolve(CreatePostUseCaseProtocol.self)
                )
            )

        case .createStory:
            StoryCameraView(
                viewModel: StoryCameraViewModel(
                    storyRepository: DIContainer.shared.resolve(StoryRepositoryProtocol.self)
                )
            )

        case .createReel:
            CreateReelView(
                viewModel: CreateReelViewModel(
                    reelRepository: DIContainer.shared.resolve(ReelRepositoryProtocol.self)
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

        case .editPost:
            Text("Edit Post") // TODO: EditPostView
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
        }
    }
}

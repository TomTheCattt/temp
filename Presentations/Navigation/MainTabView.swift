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
                ReelsPlaceholderView()
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
            Text("Edit Profile") // Placeholder
        case .followers(let userId):
            Text("Followers for \(userId)") // Placeholder
        case .following(let userId):
            Text("Following for \(userId)") // Placeholder
        case .settings:
            Text("Settings") // Placeholder
        case .postDetail(let postId):
            Text("Post \(postId)") // Placeholder
        case .comments(let postId):
            Text("Comments for \(postId)") // Placeholder
        case .likes(let postId):
            Text("Likes for \(postId)") // Placeholder
        case .directMessages:
            DirectMessagesView()
        case .conversation(let conversationId):
            Text("Chat \(conversationId)") // Placeholder
        case .storyViewer(let userId):
            Text("Story \(userId)") // Placeholder
        case .searchResults(let query):
            Text("Search: \(query)") // Placeholder
        case .hashtag(let name):
            Text("#\(name)") // Placeholder
        case .location(let name):
            Text("📍 \(name)") // Placeholder
        }
    }

    // MARK: - Sheet Content

    @ViewBuilder
    private func sheetContent(_ sheet: AppSheet) -> some View {
        switch sheet {
        case .createPost:
            Text("Create Post") // Placeholder
        case .createStory:
            Text("Create Story") // Placeholder
        case .createReel:
            Text("Create Reel") // Placeholder
        case .sharePost:
            Text("Share Post") // Placeholder
        case .reportPost:
            Text("Report Post") // Placeholder
        case .editPost:
            Text("Edit Post") // Placeholder
        }
    }

    // MARK: - Full Screen Content

    @ViewBuilder
    private func fullScreenContent(_ fullScreen: AppFullScreen) -> some View {
        switch fullScreen {
        case .camera:
            Text("Camera") // Placeholder
        case .mediaViewer(let url):
            Text("Media: \(url.lastPathComponent)") // Placeholder
        case .storyCamera:
            Text("Story Camera") // Placeholder
        }
    }
}

// MARK: - Reels Placeholder

private struct ReelsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "play.square.stack")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Reels")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Coming soon")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Reels")
    }
}

//
//  FeedView.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI

// MARK: - FeedView

struct FeedView: View {

    @State private var viewModel = FeedViewModel(
        fetchFeedUseCase: DIContainer.shared.resolve(FetchFeedUseCaseProtocol.self),
        toggleLikeUseCase: DIContainer.shared.resolve(ToggleLikePostUseCaseProtocol.self),
        toggleSaveUseCase: DIContainer.shared.resolve(ToggleSavePostUseCaseProtocol.self)
    )

    @State private var visiblePostIds: Set<String> = []
    @State private var isNavBarVisible: Bool = true
    @State private var isScrolled: Bool = false
    @State private var lastScrollOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Top padding for custom nav bar + status bar
                    Spacer()
                        .frame(height: DS.Size.buttonDefaultHeight + DS.Size.navBarStatusBarHeight)

                    // Stories bar
                    StoriesBarView()
                        .padding(.bottom, DS.Spacing.xs)

                    Divider()

                    if viewModel.isLoading && viewModel.posts.isEmpty {
                        // Skeleton loading state
                        FeedSkeletonView()
                    } else if let errorMessage = viewModel.errorMessage, viewModel.posts.isEmpty {
                        // Error state (only when there is nothing to show)
                        ErrorStateView(
                            message: errorMessage,
                            systemImage: "wifi.exclamationmark",
                            retryAction: { Task { await viewModel.loadFeed() } }
                        )
                    } else if viewModel.posts.isEmpty {
                        // Empty state
                        EmptyStateView(
                            message: L10n.Feed.emptyState,
                            systemImage: "photo.on.rectangle.angled"
                        )
                    } else {
                        // Posts
                        ForEach(viewModel.posts) { post in
                            PostCardView(
                                post: post,
                                isVisible: visiblePostIds.contains(post.id),
                                onLikeTapped: {
                                    Task { await viewModel.toggleLike(for: post) }
                                },
                                onSaveTapped: {
                                    Task { await viewModel.toggleSave(for: post) }
                                }
                            )
                            .onAppear {
                                visiblePostIds.insert(post.id)
                                if post.id == viewModel.posts.last?.id {
                                    Task { await viewModel.loadMore() }
                                }
                            }
                            .onDisappear {
                                visiblePostIds.remove(post.id)
                            }

                            Divider()
                        }

                        if viewModel.isLoadingMore {
                            ProgressView()
                                .padding()
                        }
                    }
                }
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y
            } action: { oldOffset, newOffset in
                handleScrollOffset(oldOffset: oldOffset, newOffset: newOffset)
            }
            .refreshable {
                await viewModel.refresh()
            }

            // Custom Navigation Bar (3 evenly spaced buttons)
            feedNavigationBar
                .offset(y: isNavBarVisible ? 0 : Constants.navBarHideOffsetY)
                .opacity(isNavBarVisible ? DS.Opacity.full : 0.0)
                .animation(Constants.navBarSpring, value: isNavBarVisible)
        }
        .ignoresSafeArea(.all, edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if viewModel.posts.isEmpty {
                await viewModel.loadFeed()
            }
        }
    }

    // MARK: - Custom Feed Navigation Bar (3 evenly spaced buttons)

    private var feedNavigationBar: some View {
        VStack(spacing: 0) {
            // Status bar safe area top extension
            Color.clear
                .frame(height: DS.Size.navBarStatusBarHeight)

            // Buttons row (44pt)
            HStack {
                // Button 1: Activity / Notifications
                Button {
                    AppRouter.shared.push(.notifications)
                } label: {
                    Image(systemName: "heart")
                        .font(.title3)
                }

                Spacer()

                // Button 2: Logo / Dropdown
                Button {
                    // Feed filter menu
                } label: {
                    HStack(spacing: DS.Spacing.xxs) {
                        Text(L10n.Feed.title)
                            .font(.system(size: 24, weight: .bold, design: .serif))
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                }

                Spacer()

                // Button 3: Direct Messages / Chat
                Button {
                    AppRouter.shared.push(.directMessages)
                } label: {
                    Image(systemName: "paperplane")
                        .font(.title3)
                }
            }
            .tint(.primary)
            .padding(.horizontal, DS.Padding.horizontal)
            .frame(height: DS.Size.buttonDefaultHeight)

            if isScrolled {
                Divider()
                    .opacity(DS.Opacity.divider)
            }
        }
        .background {
            if isScrolled {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .mask(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(Constants.gradientStopFull),
                                Color.white.opacity(Constants.gradientStopHigh),
                                Color.white.opacity(Constants.gradientStopMid),
                                Color.white.opacity(Constants.gradientStopClear)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            } else {
                Color.clear
            }
        }
        .animation(DS.Animation.standard, value: isScrolled)
    }

    // MARK: - Scroll Offset Handling

    private func handleScrollOffset(oldOffset: CGFloat, newOffset: CGFloat) {
        let delta = newOffset - oldOffset
        let atTop = newOffset <= Constants.scrollThresholdTop

        if atTop != !isScrolled {
            withAnimation(DS.Animation.standard) {
                isScrolled = !atTop
            }
        }

        if atTop {
            if !isNavBarVisible {
                withAnimation(Constants.navBarSpring) {
                    isNavBarVisible = true
                }
            }
        } else {
            // User scrolled down (contentOffset increased) -> hide navbar
            if delta > Constants.scrollThresholdDelta {
                if isNavBarVisible {
                    withAnimation(Constants.navBarSpring) {
                        isNavBarVisible = false
                    }
                }
            }
            // User scrolled up (contentOffset decreased) -> show navbar
            else if delta < -Constants.scrollThresholdDelta {
                if !isNavBarVisible {
                    withAnimation(Constants.navBarSpring) {
                        isNavBarVisible = true
                    }
                }
            }
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let navBarHideOffsetY: CGFloat = -140
    static let scrollThresholdTop: CGFloat = 15
    static let scrollThresholdDelta: CGFloat = 5
    static let navBarSpring: SwiftUI.Animation = .spring(response: 0.35, dampingFraction: 0.8)
    static let gradientStopFull: Double = 0.95
    static let gradientStopHigh: Double = 0.70
    static let gradientStopMid: Double = 0.30
    static let gradientStopClear: Double = 0.00
}

//
//  ProfileView.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI
import NukeUI

// MARK: - ProfileView

struct ProfileView: View {

    let userId: String?

    @State private var viewModel: ProfileViewModel
    @State private var selectedGrid: ProfileGrid = .posts

    init(userId: String?) {
        self.userId = userId
        _viewModel = State(initialValue: ProfileViewModel(
            userId: userId,
            fetchProfileUseCase: DIContainer.shared.resolve(FetchProfileUseCaseProtocol.self),
            toggleFollowUseCase: DIContainer.shared.resolve(ToggleFollowUseCaseProtocol.self),
            postRepository: DIContainer.shared.resolve(PostRepositoryProtocol.self),
            reelRepository: DIContainer.shared.resolve(ReelRepositoryProtocol.self)
        ))
    }

    @State private var isScrolled: Bool = false
    private var isMyProfile: Bool {
        viewModel.isCurrentUser
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar for Profile (4 buttons)
            profileNavigationBar

            ScrollView {
                LazyVStack(spacing: 0) {
                    if let user = viewModel.user {
                        // MARK: Header
                        profileHeader(user)

                        // MARK: Bio
                        bioSection(user)

                        // MARK: Action Buttons
                        actionButtons(user)

                        // MARK: Grid Picker
                        gridPicker

                        // MARK: Content Grid (switches by selected tab)
                        gridContent
                    } else if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, DS.Spacing.xxxl)
                    } else if let errorMessage = viewModel.errorMessage {
                        ErrorStateView(
                            message: errorMessage,
                            retryAction: { Task { await viewModel.loadProfile() } }
                        )
                    }
                }
            }
            .refreshable {
                await viewModel.loadProfile()
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y
            } action: { _, newOffset in
                let atTop = newOffset <= Constants.scrollThresholdTop
                if atTop != !isScrolled {
                    withAnimation(DS.Animation.standard) {
                        isScrolled = !atTop
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if viewModel.user == nil || viewModel.posts.isEmpty {
                await viewModel.loadProfile()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didUpdateProfile)) { notification in
            if let updatedUser = notification.object as? User {
                viewModel.applyUpdatedUser(updatedUser)
            }
        }
    }

    // MARK: - Profile Navigation Bar (4 buttons: 1 leading, 2 center-to-trailing, 1 trailing)

    private var profileNavigationBar: some View {
        VStack(spacing: 0) {
            if isMyProfile {
                MyProfileNavigationBar(viewModel: $viewModel, isRootTab: userId == nil)
            } else {
                UserProfileNavigationBar(viewModel: $viewModel)
            }

            if isScrolled {
                Divider()
                    .opacity(DS.Opacity.divider)
            }
        }
        .background {
            if isScrolled {
                Color(.systemBackground)
            } else {
                Color.clear
            }
        }
        .animation(DS.Animation.standard, value: isScrolled)
    }

    // MARK: - Header

    private func profileHeader(_ user: User) -> some View {
        HStack(spacing: DS.Spacing.xl) {
            // Avatar
            LazyImage(url: user.avatarURL) { state in
                if let image = state.image {
                    image.resizable()
                } else {
                    Circle()
                        .fill(ColorTokens.buttonSecondary)
                        .overlay {
                            InstagramIcon(.system(name: "person.fill"), size: DS.Size.iconLarge, color: ColorTokens.textSecondary)
                        }
                }
            }
            .frame(width: DS.Size.avatarXLarge, height: DS.Size.avatarXLarge)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color(.systemGray4), lineWidth: DS.Stroke.hairline))

            // Stats
            HStack(spacing: 0) {
                statItem(count: user.postsCount, label: L10n.Profile.posts)
                Spacer()
                statItem(count: user.followersCount, label: L10n.Profile.followers)
                    .onTapGesture {
                        AppRouter.shared.push(.followers(userId: user.id))
                    }
                Spacer()
                statItem(count: user.followingCount, label: L10n.Profile.following)
                    .onTapGesture {
                        AppRouter.shared.push(.following(userId: user.id))
                    }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, DS.Padding.horizontal)
        .padding(.top, DS.Spacing.sm)
    }

    private func statItem(count: Int, label: String) -> some View {
        VStack(spacing: DS.Spacing.xxxs) {
            Text(formatCount(count))
                .font(DS.Font.subheadlineBold)
            Text(label)
                .font(DS.Font.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Bio

    private func bioSection(_ user: User) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
            HStack(spacing: DS.Spacing.xxs) {
                Text(user.fullName)
                    .font(DS.Font.subheadlineBold)
                if user.isVerified {
                    InstagramIcon(.verifiedBadge, size: DS.Size.iconSmall, color: ColorTokens.accentPrimary)
                }
            }

            if let bio = user.bio, !bio.isEmpty {
                Text(bio)
                    .font(DS.Font.subheadline)
            }

            if let website = user.website, !website.isEmpty {
                let displayURL = website
                    .replacingOccurrences(of: "https://", with: "")
                    .replacingOccurrences(of: "http://", with: "")
                let destinationURL = URL(string: website.contains("://") ? website : "https://\(website)")
                if let destinationURL {
                    Link(displayURL, destination: destinationURL)
                        .font(DS.Font.subheadlineBold)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DS.Padding.horizontal)
        .padding(.top, DS.Spacing.xs)
    }

    // MARK: - Action Buttons

    private func actionButtons(_ user: User) -> some View {
        HStack(spacing: DS.Spacing.xs) {
            if viewModel.isCurrentUser {
                profileButton(title: L10n.Profile.editProfile) {
                    AppRouter.shared.present(sheet: .editProfile)
                }
                shareProfileButton(user)
            } else {
                Button {
                    Task { await viewModel.toggleFollow() }
                } label: {
                    Text(user.isFollowing ? L10n.Common.following : L10n.Common.follow)
                        .font(DS.Font.subheadlineBold)
                        .frame(maxWidth: .infinity)
                        .frame(height: DS.Size.avatarCompact)
                        .foregroundStyle(user.isFollowing ? Color.primary : .white)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                                .fill(user.isFollowing ? ColorTokens.buttonSecondary : ColorTokens.accentPrimary)
                        )
                }

                profileButton(title: L10n.Common.message) {
                    AppRouter.shared.push(.directMessages)
                }
            }
        }
        .padding(.horizontal, DS.Padding.horizontal)
        .padding(.top, DS.Spacing.sm)
    }

    private func shareProfileButton(_ user: User) -> some View {
        let profileURL = URL(string: "\(AppConstants.App.universalLinkHost)/\(user.username)")
        return ShareLink(
            item: profileURL ?? URL(string: AppConstants.App.universalLinkHost)!,
            subject: Text(user.username),
            message: Text(user.fullName)
        ) {
            Text(L10n.Profile.shareProfile)
                .font(DS.Font.subheadlineBold)
                .frame(maxWidth: .infinity)
                .frame(height: DS.Size.avatarCompact)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                        .fill(ColorTokens.backgroundSubtler)
                )
        }
        .tint(.primary)
    }

    private func profileButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(DS.Font.subheadlineBold)
                .frame(maxWidth: .infinity)
                .frame(height: DS.Size.avatarCompact)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                        .fill(ColorTokens.backgroundSubtler)
                )
        }
        .tint(.primary)
    }

    // MARK: - Grid Picker

    private var gridPicker: some View {
        HStack(spacing: 0) {
            ForEach(ProfileGrid.allCases, id: \.self) { grid in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedGrid = grid
                    }
                    if grid == .reels {
                        Task { await viewModel.loadReelsIfNeeded() }
                    }
                } label: {
                    InstagramIcon(
                        grid.appIcon(isSelected: selectedGrid == grid),
                        size: DS.Size.iconDefault,
                        color: selectedGrid == grid ? ColorTokens.textPrimary : ColorTokens.textSecondary
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Padding.inputBar)
                }
            }
        }
        .overlay(alignment: .bottom) {
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.primary)
                    .frame(width: geo.size.width / CGFloat(ProfileGrid.allCases.count), height: DS.Spacing.hairline)
                    .offset(x: CGFloat(selectedGrid.rawValue) * (geo.size.width / CGFloat(ProfileGrid.allCases.count)))
            }
            .frame(height: DS.Spacing.hairline)
        }
        .padding(.top, DS.Spacing.md)
    }

    // MARK: - Grid Content (per selected tab)

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: DS.Spacing.hairline), count: DS.Layout.gridColumns)
    }

    @ViewBuilder
    private var gridContent: some View {
        switch selectedGrid {
        case .posts:
            postsGrid
        case .reels:
            reelsGrid
        case .tagged:
            taggedGrid
        }
    }

    // MARK: - Posts Grid

    private var postsGrid: some View {
        Group {
            if viewModel.posts.isEmpty {
                EmptyStateView(
                    message: L10n.Profile.noPostsDescription,
                    systemImage: "camera",
                    title: L10n.Profile.noPostsTitle
                )
            } else {
                LazyVGrid(columns: gridColumns, spacing: DS.Spacing.hairline) {
                    ForEach(viewModel.posts) { post in
                        Button {
                            AppRouter.shared.push(.postDetail(postId: post.id))
                        } label: {
                            if let media = post.mediaItems.first {
                                LazyImage(url: media.thumbnailURL ?? media.url) { state in
                                    if let image = state.image {
                                        image
                                            .resizable()
                                            .aspectRatio(1, contentMode: .fill)
                                    } else {
                                        ColorTokens.backgroundSecondary
                                    }
                                }
                                .aspectRatio(1, contentMode: .fill)
                                .clipped()
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Reels Grid

    private var reelsGrid: some View {
        Group {
            if viewModel.isLoadingReels && viewModel.reels.isEmpty {
                ProgressView()
                    .padding(.top, DS.Spacing.xxxl)
            } else if viewModel.reels.isEmpty {
                EmptyStateView(
                    message: L10n.Profile.noReelsDescription,
                    systemImage: "play.square",
                    title: L10n.Profile.noReelsTitle
                )
            } else {
                LazyVGrid(columns: gridColumns, spacing: DS.Spacing.hairline) {
                    ForEach(viewModel.reels) { reel in
                        LazyImage(url: reel.thumbnailURL) { state in
                            if let image = state.image {
                                image
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fill)
                            } else {
                                ColorTokens.backgroundSecondary
                            }
                        }
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                        .overlay(alignment: .bottomLeading) {
                            InstagramIcon(.system(name: "play.fill"), size: DS.Size.iconXSmall, color: .white)
                                .padding(DS.Spacing.xxs)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Tagged Grid

    private var taggedGrid: some View {
        EmptyStateView(
            message: L10n.Profile.noTaggedDescription,
            systemImage: "person.crop.square",
            title: L10n.Profile.noTaggedTitle
        )
    }

    // MARK: - Helpers

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 10_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }
}

// MARK: - My Profile Navigation Bar
struct MyProfileNavigationBar: View {
    
    @Binding var viewModel: ProfileViewModel
    var isRootTab: Bool = true
    
    var body: some View {
        ZStack {
            // Center: Username + Lock (only if private)
            VStack(alignment: .center) {
                Button {
                    // Privacy settings or profile info
                } label: {
                    HStack(spacing: DS.Spacing.xxs) {
                        let isPrivate = viewModel.user?.isPrivate ?? SessionStore.shared.currentUser?.isPrivate ?? false
                        if isPrivate {
                            InstagramIcon(.lock, size: DS.Size.iconSmall, color: ColorTokens.textPrimary)
                        }
                        let username = viewModel.user?.username ?? SessionStore.shared.currentUser?.username ?? ""
                        Text(username)
                            .font(DS.Font.headline)
                    }
                }
            }
            
            HStack(spacing: DS.Spacing.md) {
                // Leading Button: '+' if root tab, '<' back button if pushed onto stack
                if isRootTab {
                    Button {
                        HapticFeedbackSafe.impact(.light)
                        AppRouter.shared.present(fullScreen: .creationHub(initialMode: .post))
                    } label: {
                        InstagramIcon(.plus, size: DS.Size.iconDefault, color: ColorTokens.textPrimary)
                            .frame(width: 44, height: 44, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                } else {
                    Button {
                        HapticFeedbackSafe.impact(.light)
                        AppRouter.shared.pop()
                    } label: {
                        InstagramIcon(.chevronLeft, size: DS.Size.iconDefault, color: ColorTokens.textPrimary)
                            .frame(width: 44, height: 44, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                }
                
                Spacer()
                
                // Trailing Button Group: Threads & Hamburger Menu
                HStack(spacing: DS.Spacing.xs) {
                    Button {
                        HapticFeedbackSafe.impact(.light)
                        // Open Threads
                    } label: {
                        InstagramIcon(.threads, size: DS.Size.iconDefault, color: ColorTokens.textPrimary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    
                    Button {
                        HapticFeedbackSafe.impact(.light)
                        AppRouter.shared.push(.settings)
                    } label: {
                        InstagramIcon(.menu, size: DS.Size.iconDefault, color: ColorTokens.textPrimary)
                            .frame(width: 44, height: 44, alignment: .trailing)
                            .contentShape(Rectangle())
                    }
                }
            }
        }
        .tint(.primary)
        .padding(.horizontal, DS.Padding.horizontal)
        .frame(height: DS.Size.buttonDefaultHeight)
    }
}

// MARK: - User Profile Navigation Bar
struct UserProfileNavigationBar: View {
    
    @Binding var viewModel: ProfileViewModel
    
    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            // Leading Button Group: Back + Username
            HStack(spacing: DS.Spacing.sm) {
                Button {
                    HapticFeedbackSafe.impact(.light)
                    AppRouter.shared.pop()
                } label: {
                    InstagramIcon(.chevronLeft, size: DS.Size.iconDefault, color: ColorTokens.textPrimary)
                        .frame(width: 44, height: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                
                Text(viewModel.user?.username ?? L10n.Profile.unknownUser)
                    .font(DS.Font.headline)
            }
            
            Spacer()
            
            HStack(spacing: DS.Spacing.xs) {
                // Notification Button
                Button {
                    HapticFeedbackSafe.impact(.light)
                    // Notification options
                } label: {
                    InstagramIcon(.system(name: "bell"), size: DS.Size.iconDefault, color: ColorTokens.textPrimary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                
                // More (...) Button
                Button {
                    HapticFeedbackSafe.impact(.light)
                    // Profile options
                } label: {
                    InstagramIcon(.options, size: DS.Size.iconDefault, color: ColorTokens.textPrimary)
                        .frame(width: 44, height: 44, alignment: .trailing)
                        .contentShape(Rectangle())
                }
            }
        }
        .tint(.primary)
        .padding(.horizontal, DS.Padding.horizontal)
        .frame(height: DS.Size.buttonDefaultHeight)
    }
}

// MARK: - ProfileGrid

enum ProfileGrid: Int, CaseIterable {
    case posts
    case reels
    case tagged

    func appIcon(isSelected: Bool) -> AppIcon {
        switch self {
        case .posts:  return .grid(selected: isSelected)
        case .reels:  return .reels(selected: isSelected)
        case .tagged: return .tag(selected: isSelected)
        }
    }
}

// MARK: - ProfileScrollOffsetPreferenceKey

private struct ProfileScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Constants

private enum Constants {
    static let scrollThresholdTop: CGFloat = 10
}

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
            postRepository: DIContainer.shared.resolve(PostRepositoryProtocol.self)
        ))
    }

    var body: some View {
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

                    // MARK: Posts Grid
                    postsGrid
                } else if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 100)
                }
            }
        }
        .navigationTitle(viewModel.user?.username ?? "")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if viewModel.isCurrentUser {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: DS.Spacing.md) {
                        Button {
                            AppRouter.shared.present(sheet: .createPost)
                        } label: {
                            Image(systemName: "plus.app")
                        }
                        Button {
                            AppRouter.shared.push(.settings)
                        } label: {
                            Image(systemName: "line.3.horizontal")
                        }
                    }
                    .tint(.primary)
                }
            }
        }
        .task {
            if viewModel.user == nil {
                await viewModel.loadProfile()
            }
        }
    }

    // MARK: - Header

    private func profileHeader(_ user: User) -> some View {
        HStack(spacing: DS.Spacing.xl) {
            // Avatar
            LazyImage(url: user.avatarURL) { state in
                if let image = state.image {
                    image.resizable()
                } else {
                    Circle().fill(ColorTokens.buttonSecondary)
                }
            }
            .frame(width: DS.Size.avatarXLarge, height: DS.Size.avatarXLarge)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color(.systemGray4), lineWidth: 0.5))

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
                .font(DS.Font.subheadline)
                .fontWeight(.bold)
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
                    .font(DS.Font.subheadline)
                    .fontWeight(.semibold)
                if user.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(DS.Font.caption)
                        .foregroundStyle(ColorTokens.accentPrimary)
                }
            }

            if let bio = user.bio, !bio.isEmpty {
                Text(bio)
                    .font(DS.Font.subheadline)
            }

            if let website = user.website, !website.isEmpty {
                Link(website.replacingOccurrences(of: "https://", with: ""),
                     destination: URL(string: website) ?? URL(string: "https://example.com")!)
                    .font(DS.Font.subheadline)
                    .fontWeight(.medium)
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
                    AppRouter.shared.push(.editProfile)
                }
                profileButton(title: L10n.Profile.shareProfile) {
                    // Share
                }
            } else {
                Button {
                    Task { await viewModel.toggleFollow() }
                } label: {
                    Text(user.isFollowing ? L10n.Common.following : L10n.Common.follow)
                        .font(DS.Font.subheadline)
                        .fontWeight(.semibold)
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

    private func profileButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(DS.Font.subheadline)
                .fontWeight(.semibold)
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
                } label: {
                    Image(systemName: grid.icon)
                        .font(DS.Font.title3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Padding.inputBar)
                        .foregroundStyle(selectedGrid == grid ? .primary : .secondary)
                }
            }
        }
        .overlay(alignment: .bottom) {
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.primary)
                    .frame(width: geo.size.width / CGFloat(ProfileGrid.allCases.count), height: 1)
                    .offset(x: CGFloat(selectedGrid.rawValue) * (geo.size.width / CGFloat(ProfileGrid.allCases.count)))
            }
            .frame(height: 1)
        }
        .padding(.top, DS.Spacing.md)
    }

    // MARK: - Posts Grid

    private var postsGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 3)

        return LazyVGrid(columns: columns, spacing: 1) {
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

// MARK: - ProfileGrid

enum ProfileGrid: Int, CaseIterable {
    case posts
    case reels
    case tagged

    var icon: String {
        switch self {
        case .posts:  return "squareshape.split.3x3"
        case .reels:  return "play.square"
        case .tagged: return "person.crop.square"
        }
    }
}

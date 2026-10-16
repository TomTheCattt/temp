//
//  ReelsView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI
import NukeUI

// MARK: - ReelsView

struct ReelsView: View {

    @State private var viewModel: ReelsViewModel

    init(viewModel: ReelsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { geometry in
                if viewModel.isLoading && viewModel.reels.isEmpty {
                    // Skeleton loading for reels
                    ReelSkeletonView()
                } else if let errorMessage = viewModel.errorMessage, viewModel.reels.isEmpty {
                    ZStack {
                        Color.black
                        ErrorStateView(
                            message: errorMessage,
                            retryAction: { Task { await viewModel.loadReels() } }
                        )
                        .foregroundStyle(.white)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                } else if viewModel.reels.isEmpty {
                    ZStack {
                        Color.black
                        EmptyStateView(
                            message: L10n.Reels.empty,
                            systemImage: "play.slash"
                        )
                        .foregroundStyle(.white)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.reels) { reel in
                                ReelItemView(
                                    reel: reel,
                                    isActive: reel.id == viewModel.currentReelId,
                                    onLike: { Task { await viewModel.toggleLike(for: reel) } },
                                    onComment: { navigateToComments(reel) },
                                    onSave: { Task { await viewModel.toggleSave(for: reel) } },
                                    onFollow: { Task { await viewModel.followAuthor(of: reel) } }
                                )
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .id(reel.id)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollPosition(id: $viewModel.currentReelId)
                    .onChange(of: viewModel.currentReelId) { _, newId in
                        viewModel.onCurrentReelChanged(to: newId)
                    }
                }
            }

            // Custom Navigation Bar for Reels (4 buttons)
            reelsNavigationBar
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadReels()
        }
    }

    // MARK: - Reels Navigation Bar (4 buttons: 1 leading, 2 center, 1 trailing)

    private var reelsNavigationBar: some View {
        VStack(spacing: 0) {
            // Status bar top safe area extension
            Color.clear
                .frame(height: DS.Size.navBarStatusBarHeight)

            HStack {
                // Button 1: Leading (Camera)
                Button {
                    HapticFeedbackSafe.impact(.light)
                    AppRouter.shared.present(fullScreen: .camera)
                } label: {
                    InstagramIcon(.camera, size: DS.Size.iconDefault, color: .white)
                        .frame(width: 44, height: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }

                Spacer()

                // Buttons 2 & 3: Center (Reels / Following)
                HStack(spacing: DS.Spacing.md) {
                    Button {
                        viewModel.setFeedMode(.forYou)
                    } label: {
                        Text(L10n.Tab.reels)
                            .font(DS.Font.title3)
                            .fontWeight(viewModel.feedMode == .forYou ? .bold : .medium)
                            .foregroundStyle(viewModel.feedMode == .forYou ? .white : .white.opacity(DS.Opacity.medium))
                    }

                    Button {
                        viewModel.setFeedMode(.following)
                    } label: {
                        Text(L10n.Common.following)
                            .font(DS.Font.title3)
                            .fontWeight(viewModel.feedMode == .following ? .bold : .medium)
                            .foregroundStyle(viewModel.feedMode == .following ? .white : .white.opacity(DS.Opacity.medium))
                    }
                }

                Spacer()

                // Button 4: Trailing (Search)
                Button {
                    HapticFeedbackSafe.impact(.light)
                    AppRouter.shared.switchTab(.explore)
                } label: {
                    InstagramIcon(.search(selected: false), size: DS.Size.iconDefault, color: .white)
                        .frame(width: 44, height: 44, alignment: .trailing)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, DS.Padding.horizontal)
            .frame(height: DS.Size.buttonDefaultHeight)
            .padding(.bottom, DS.Spacing.xs)
        }
        .background {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.black.opacity(Constants.blackGradientTop),
                        Color.black.opacity(Constants.blackGradientMid),
                        Color.black.opacity(Constants.gradientStopClear)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Rectangle()
                    .fill(.ultraThinMaterial)
            }
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
        }
    }

    private func navigateToComments(_ reel: Reel) {
        AppRouter.shared.present(sheet: .reelComments(reelId: reel.id))
    }
}

// MARK: - ReelItemView

struct ReelItemView: View {

    let reel: Reel
    let isActive: Bool
    let onLike: () -> Void
    let onComment: () -> Void
    let onSave: () -> Void
    let onFollow: () -> Void

    /// Profile share URL for this reel's author.
    private var authorShareURL: URL {
        URL(string: "\(AppConstants.App.universalLinkHost)/\(reel.author.username)")
            ?? URL(string: AppConstants.App.universalLinkHost)!
    }

    /// Tab bar height (49) + home indicator (~34) = ~83pt on notch devices.
    /// Using a safe constant that looks good on all devices.
    private let tabBarBottomPadding: CGFloat = DS.Padding.bottomSafe + 49

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark skeleton background: visible while video is loading/buffering
                ReelVideoSkeletonView(isActive: isActive)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                // Video player always in hierarchy — controls playback via isActive
                ReelVideoPlayer(url: reel.videoURL, fallbackURL: reel.fallbackVideoURL, id: reel.id, isActive: isActive)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                // Dim overlay + play icon when not active
                if !isActive {
                    Color.black.opacity(DS.Opacity.low)
                    InstagramIcon(.system(name: "play.fill"), size: DS.Size.iconHero, color: .white.opacity(DS.Opacity.medium))
                }

                // Content overlay
                VStack {
                    Spacer()
                    HStack(alignment: .bottom, spacing: DS.Spacing.sm) {
                        reelInfo
                        actionButtons
                    }
                    .padding(.horizontal, DS.Padding.content)
                    .padding(.bottom, tabBarBottomPadding)
                }
            }
        }
        .clipped()
    }

    // MARK: - Reel Info (bottom-left)

    private var reelInfo: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            // Author
            HStack(spacing: DS.Spacing.xs) {
                LazyImage(url: reel.author.avatarURL) { state in
                    if let image = state.image {
                        image.resizable().scaledToFill()
                    } else {
                        Circle().fill(Color.gray.opacity(DS.Opacity.overlay))
                    }
                }
                .frame(width: DS.Size.avatarCompact, height: DS.Size.avatarCompact)
                .clipShape(Circle())
                .onTapGesture {
                    AppRouter.shared.push(.userProfile(userId: reel.author.id))
                }

                Text(reel.author.username)
                    .font(DS.Font.username)
                    .foregroundStyle(.white)

                // Follow button hides once the author is followed.
                if !reel.author.isFollowing {
                    Button(action: onFollow) {
                        Text(L10n.Common.follow)
                            .font(DS.Font.captionBold)
                            .padding(.horizontal, DS.Spacing.sm)
                            .padding(.vertical, DS.Spacing.xxs)
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.Radius.small)
                                    .stroke(Color.white, lineWidth: DS.Stroke.thin)
                            )
                            .foregroundStyle(.white)
                    }
                }
            }

            // Caption (truncated)
            if let caption = reel.caption, !caption.isEmpty {
                Text(caption)
                    .font(DS.Font.caption)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .frame(maxWidth: 250, alignment: .leading)
            }

            // Audio
            if let audio = reel.audioTrack {
                HStack(spacing: DS.Spacing.iconGap) {
                    InstagramIcon(.system(name: "music.note"), size: DS.Size.iconSmall, color: .white)
                    Text("\(audio.artistName) • \(audio.name)")
                        .font(DS.Font.caption2)
                        .lineLimit(1)
                }
                .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Action Buttons (right side)

    private var actionButtons: some View {
        VStack(spacing: DS.Spacing.lg) {
            // Like
            VStack(spacing: DS.Spacing.xxs) {
                Button(action: onLike) {
                    InstagramIcon(.like(selected: reel.isLiked), size: DS.Size.iconLarge, color: reel.isLiked ? ColorTokens.likeRed : .white)
                }
                Text(formatCount(reel.likesCount))
                    .font(DS.Font.caption2)
                    .foregroundStyle(.white)
            }

            // Comment
            VStack(spacing: DS.Spacing.xxs) {
                Button(action: onComment) {
                    InstagramIcon(.comment, size: DS.Size.iconLarge, color: .white)
                }
                Text(formatCount(reel.commentsCount))
                    .font(DS.Font.caption2)
                    .foregroundStyle(.white)
            }

            // Share
            VStack(spacing: DS.Spacing.xxs) {
                ShareLink(item: authorShareURL, subject: Text(reel.author.username)) {
                    InstagramIcon(.share, size: DS.Size.iconLarge, color: .white)
                }
                Text(formatCount(reel.sharesCount))
                    .font(DS.Font.caption2)
                    .foregroundStyle(.white)
            }

            // Save
            Button(action: onSave) {
                InstagramIcon(.save(selected: reel.isSaved), size: DS.Size.iconLarge, color: .white)
            }

            // Audio disc
            if let audio = reel.audioTrack {
                LazyImage(url: audio.coverURL) { state in
                    if let image = state.image {
                        image.resizable().scaledToFill()
                    } else {
                        Circle().fill(Color.gray)
                    }
                }
                .frame(width: DS.Size.audioDisc, height: DS.Size.audioDisc)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(DS.Opacity.low), lineWidth: DS.Stroke.thin))
            }
        }
    }

    // MARK: - Helpers

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }
}

// MARK: - Constants

private enum Constants {
    static let gradientStopFull: Double = 0.95
    static let gradientStopHigh: Double = 0.70
    static let gradientStopMid: Double = 0.30
    static let gradientStopClear: Double = 0.00
    static let blackGradientTop: Double = 0.40
    static let blackGradientMid: Double = 0.20
}

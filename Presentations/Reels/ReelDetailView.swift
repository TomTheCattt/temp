//
//  ReelDetailView.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI
import NukeUI
import AVKit

// MARK: - ReelDetailView

/// Reel detail view showing full-screen video with info overlay.
/// Uses ReelVideoPlayer for optimized looping playback.

struct ReelDetailView: View {

    let reelId: String

    @State private var viewModel: ReelDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(reelId: String) {
        self.reelId = reelId
        _viewModel = State(initialValue: ReelDetailViewModel(
            reelId: reelId,
            fetchReelDetailUseCase: DIContainer.shared.resolve(FetchReelDetailUseCaseProtocol.self),
            toggleSaveReelUseCase: DIContainer.shared.resolve(ToggleSaveReelUseCaseProtocol.self),
            deleteReelUseCase: DIContainer.shared.resolve(DeleteReelUseCaseProtocol.self),
            toggleLikeUseCase: DIContainer.shared.resolve(ToggleLikePostUseCaseProtocol.self),
            addCommentUseCase: DIContainer.shared.resolve(AddCommentUseCaseProtocol.self)
        ))
    }

    private func setupViewModel() {
        viewModel.onDelete = { dismiss() }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if viewModel.isLoading && viewModel.reel == nil {
                    loadingView
                } else if let reel = viewModel.reel {
                    reelDetailContent(reel)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        HapticFeedbackSafe.impact(.light)
                        dismiss()
                    } label: {
                        InstagramIcon(.chevronLeft, size: 20, color: .white)
                            .frame(width: 44, height: 44)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: DS.Spacing.sm) {
                        // Share button
                        Button {
                            HapticFeedbackSafe.impact(.light)
                            viewModel.shareReel()
                        } label: {
                            InstagramIcon(.share, size: 22, color: .white)
                                .frame(width: 44, height: 44)
                        }

                        // More button
                        if viewModel.isCurrentUserReel {
                            Menu {
                                Button {
                                    Task {
                                        await viewModel.deleteReel()
                                    }
                                } label: {
                                    Label(L10n.ReelDetail.delete, systemImage: "trash")
                                }
                            } label: {
                                InstagramIcon(.system(name: "ellipsis"), size: 22, color: .white)
                                    .frame(width: 44, height: 44)
                            }
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .tabBar)
            .statusBarHidden()
            .onAppear {
                setupViewModel()
            }
            .task {
                await viewModel.loadReel()
            }
            .sheet(item: $viewModel.shareSheetItem) { item in
                ShareSheet(activityItems: [item])
            }
            .fullScreenCover(isPresented: $viewModel.showComments) {
                NavigationStack {
                    CommentsView(
                        viewModel: CommentsViewModel(
                            postId: reelId,
                            fetchCommentsUseCase: DIContainer.shared.resolve(FetchCommentsUseCaseProtocol.self),
                            addCommentUseCase: DIContainer.shared.resolve(AddCommentUseCaseProtocol.self)
                        )
                    )
                }
                .presentationDetents([.fraction(2.0 / 3.0)])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: DS.Spacing.md) {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.5)
            Text(L10n.Common.loading)
                .font(DS.Font.body)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func reelDetailContent(_ reel: Reel) -> some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Video Player - Full width, with safe area
                ReelVideoPlayer(
                    url: reel.videoURL,
                    fallbackURL: reel.fallbackVideoURL,
                    id: reel.id,
                    isActive: true
                )
                .frame(width: geometry.size.width, height: geometry.size.height * 0.75)
                .clipped()

                // Bottom Info Section
                VStack(spacing: 0) {
                    // Author Row
                    authorRow(reel)

                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.horizontal, DS.Padding.horizontal)

                    // Caption & Actions
                    ScrollView {
                        VStack(alignment: .leading, spacing: DS.Spacing.md) {
                            // Caption
                            if let caption = reel.caption, !caption.isEmpty {
                                captionView(caption, author: reel.author)
                            }

                            // Music/Audio Info
                            if let audio = reel.audioTrack {
                                audioInfoView(audio)
                            }

                            // Hashtags & Mentions
                            // Note: Reel model doesn't have hashtags/mentions fields yet
                            // if !reel.hashtags.isEmpty || !reel.mentions.isEmpty {
                            //     tagsView(hashtags: reel.hashtags, mentions: reel.mentions)
                            // }
                        }
                        .padding(.horizontal, DS.Padding.horizontal)
                        .padding(.vertical, DS.Spacing.md)
                    }
                    .frame(maxHeight: geometry.size.height * 0.25)
                }
                .background(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.95)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }

        // Action Buttons Overlay (Right side)
        VStack {
            Spacer()
            HStack {
                Spacer()
                actionButtonsOverlay
                    .padding(.trailing, DS.Padding.horizontal)
                    .padding(.bottom, DS.Spacing.xl + 50) // Safe area + tab bar space
            }
        }
    }

    private func authorRow(_ reel: Reel) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            // Avatar
            LazyImage(url: reel.author.avatarURL) { state in
                if let image = state.image {
                    image.resizable().scaledToFill()
                } else {
                    Circle().fill(ColorTokens.buttonSecondary)
                }
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())
            .onTapGesture {
                HapticFeedbackSafe.impact(.light)
                AppRouter.shared.push(.userProfile(userId: reel.author.id))
            }

            // Username
            VStack(alignment: .leading, spacing: 2) {
                Text(reel.author.username)
                    .font(DS.Font.subheadlineBold)
                    .foregroundStyle(.white)
                // Note: isSponsored not in Reel model
            }

            Spacer()

            // Follow Button (if not current user)
            // Note: isCurrentUser and isFollowedByCurrentUser not in User model yet
            // if !reel.author.isCurrentUser { ... }
        }
        .padding(.horizontal, DS.Padding.horizontal)
        .padding(.vertical, DS.Spacing.sm)
    }

    private func captionView(_ caption: String, author: User) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text("@\(author.username) ")
                .font(DS.Font.subheadlineBold)
                .foregroundStyle(.white) +
            Text(caption)
                .font(DS.Font.subheadline)
                .foregroundStyle(.white)

            // Show more/less would go here
        }
    }

    private func audioInfoView(_ audio: AudioTrack) -> some View {
        Button {
            HapticFeedbackSafe.impact(.light)
            viewModel.showAudioDetail()
        } label: {
            HStack(spacing: DS.Spacing.sm) {
                InstagramIcon(.system(name: "music.note"), size: 16, color: .white)

                VStack(alignment: .leading, spacing: 2) {
                    Text(audio.name)
                        .font(DS.Font.caption)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(audio.artistName)
                        .font(DS.Font.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }

                Spacer()

                InstagramIcon(.system(name: "arrow.up.right"), size: 12, color: .white.opacity(0.7))
            }
            .padding(.horizontal, DS.Spacing.sm)
            .padding(.vertical, DS.Spacing.xs)
            .background(Color.white.opacity(0.1), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func tagsView(hashtags: [String], mentions: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.xs) {
                ForEach(hashtags, id: \.self) { tag in
                    Button {
                        HapticFeedbackSafe.impact(.light)
                        AppRouter.shared.push(.hashtag(name: tag))
                    } label: {
                        Text("#\(tag)")
                            .font(DS.Font.caption)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, DS.Spacing.sm)
                            .padding(.vertical, DS.Spacing.xxs)
                            .background(Color.white.opacity(0.1), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }

                ForEach(mentions, id: \.self) { mention in
                    Button {
                        HapticFeedbackSafe.impact(.light)
                        // Would navigate to user profile
                    } label: {
                        Text("@\(mention)")
                            .font(DS.Font.caption)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, DS.Spacing.sm)
                            .padding(.vertical, DS.Spacing.xxs)
                            .background(Color.white.opacity(0.1), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DS.Padding.horizontal)
        }
    }

    private var actionButtonsOverlay: some View {
        VStack(spacing: DS.Spacing.md) {
            // Like Button
            ActionButtonView(
                icon: viewModel.isLiked ? "heart.fill" : "heart",
                count: viewModel.likeCount,
                isActive: viewModel.isLiked,
                activeColor: .red
            ) {
                Task {
                    await viewModel.toggleLike()
                }
            }

            // Comment Button
            ActionButtonView(
                icon: "message",
                count: viewModel.commentCount,
                isActive: false
            ) {
                viewModel.showComments = true
            }

            // Share Button
            ActionButtonView(
                icon: "paperplane",
                count: viewModel.shareCount,
                isActive: false
            ) {
                viewModel.shareReel()
            }

            // Save Button
            ActionButtonView(
                icon: viewModel.isSaved ? "bookmark.fill" : "bookmark",
                count: nil,
                isActive: viewModel.isSaved,
                activeColor: .yellow
            ) {
                Task {
                    await viewModel.toggleSave()
                }
            }

            // Music/Audio Button
            if viewModel.reel?.audioTrack != nil {
                Button {
                    HapticFeedbackSafe.impact(.light)
                    viewModel.showAudioDetail()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 48, height: 48)

                        InstagramIcon(.system(name: "music.note"), size: 22, color: .white)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Action Button View

private struct ActionButtonView: View {
    let icon: String
    let count: Int?
    let isActive: Bool
    var activeColor: Color = .white
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DS.Spacing.xxs) {
                InstagramIcon(.system(name: icon), size: 28, color: isActive ? activeColor : .white)
                    .scaleEffect(isActive ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)

                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 48, height: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ViewModel

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

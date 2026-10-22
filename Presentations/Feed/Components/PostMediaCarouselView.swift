//
//  PostMediaCarouselView.swift
//  Instagram
//
//  Created by Kiro on 17/10/26.
//

import SwiftUI
import NukeUI

// MARK: - PostMediaCarouselView

/// Reusable multi-media carousel container for feed posts and post details.
/// Features:
/// - Single media: Renders directly with 0 overhead.
/// - Multi-media (Carousel): Smooth horizontal paging via TabView (page style).
/// - Resource Capping (Rule 1): Video only plays when isVisible == true AND currentMediaIndex matches slide index.
/// - Top-Right Badge: Shows "1/3", auto-fades out after 2.5s, re-appears on swipe.
/// - Double-tap to like gesture support.
struct PostMediaCarouselView: View {

    // MARK: - Properties

    let post: Post
    let isVisible: Bool
    var aspectRatio: CGFloat = DS.Layout.postSquareAspectRatio
    @Binding var currentMediaIndex: Int
    let onDoubleTap: () -> Void

    @State private var isBadgeVisible: Bool = true
    @State private var badgeHideTask: Task<Void, Never>?

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {
            mediaContent
                .aspectRatio(aspectRatio, contentMode: .fit)
                .clipped()

            // Page count badge (e.g., 1/4) in top right
            if post.mediaItems.count > 1 && isBadgeVisible {
                Text("\(currentMediaIndex + 1)/\(post.mediaItems.count)")
                    .font(DS.Font.caption2Bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, DS.Spacing.xs)
                    .padding(.vertical, DS.Spacing.xxs)
                    .background(Capsule().fill(Color.black.opacity(0.68)))
                    .padding(DS.Spacing.sm)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onDoubleTap()
        }
        .onAppear {
            if post.mediaItems.count > 1 {
                showBadgeWithAutoFade()
            }
        }
        .onDisappear {
            badgeHideTask?.cancel()
            badgeHideTask = nil
        }
        .onChange(of: currentMediaIndex) { _, _ in
            if post.mediaItems.count > 1 {
                showBadgeWithAutoFade()
            }
        }
    }

    // MARK: - Media Content

    @ViewBuilder
    private var mediaContent: some View {
        if post.mediaItems.count > 1 {
            TabView(selection: $currentMediaIndex) {
                ForEach(Array(post.mediaItems.enumerated()), id: \.element.id) { index, item in
                    slideItemView(for: item, index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        } else if let firstMedia = post.mediaItems.first {
            slideItemView(for: firstMedia, index: 0)
        } else {
            skeletonMediaPlaceholder
        }
    }

    // MARK: - Slide Item View

    @ViewBuilder
    private func slideItemView(for item: MediaItem, index: Int) -> some View {
        switch item.type {
        case .video:
            ZStack {
                // Video thumbnail background while loading
                VideoThumbnailView(videoURL: item.url, thumbnailURL: item.thumbnailURL)
                    .aspectRatio(aspectRatio, contentMode: .fill)

                // Dedicated feed video player
                FeedVideoPlayer(
                    url: item.url,
                    id: "post_video_\(post.id)_\(index)",
                    isVisible: isVisible && (currentMediaIndex == index)
                )
                .aspectRatio(aspectRatio, contentMode: .fill)
            }
            .clipped()

        case .image:
            LazyImage(url: item.url) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(aspectRatio, contentMode: .fill)
                } else if state.error != nil {
                    ColorTokens.buttonSecondary
                        .aspectRatio(aspectRatio, contentMode: .fill)
                        .overlay {
                            InstagramIcon(.picture, size: DS.Size.avatarCompact, color: .secondary)
                        }
                } else {
                    skeletonMediaPlaceholder
                }
            }
            .clipped()
        }
    }

    // MARK: - Badge Auto Fade

    private func showBadgeWithAutoFade() {
        withAnimation(DS.Animation.fast) {
            isBadgeVisible = true
        }
        badgeHideTask?.cancel()
        badgeHideTask = Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
            guard !Task.isCancelled else { return }
            withAnimation(DS.Animation.smooth) {
                isBadgeVisible = false
            }
        }
    }

    // MARK: - Skeleton Placeholder

    private var skeletonMediaPlaceholder: some View {
        ColorTokens.backgroundSubtler
            .aspectRatio(aspectRatio, contentMode: .fill)
            .overlay {
                ShimmerView()
            }
    }
}

//
//  VideoThumbnailView.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI
import NukeUI

// MARK: - VideoThumbnailView

/// Displays a video thumbnail with priority:
/// 1. Remote `thumbnailURL` if provided (via LazyImage for caching)
/// 2. Generated thumbnail from video URL (via AVAssetImageGenerator)
/// 3. Skeleton placeholder while loading
struct VideoThumbnailView: View {

    let videoURL: URL
    let thumbnailURL: URL?

    @State private var generatedImage: UIImage?
    @State private var isGenerating = false

    var body: some View {
        Group {
            if let thumbnailURL {
                // Priority 1: Remote thumbnail URL
                LazyImage(url: thumbnailURL) { state in
                    if let image = state.image {
                        image.resizable().scaledToFill()
                    } else if state.error != nil {
                        // Remote thumbnail failed — try generating
                        generatedThumbnailContent
                    } else {
                        // Loading
                        skeletonPlaceholder
                    }
                }
            } else {
                // No remote URL — generate from video
                generatedThumbnailContent
            }
        }
        .task(id: videoURL) {
            // Pre-generate thumbnail if no remote URL or as fallback
            if thumbnailURL == nil && generatedImage == nil && !isGenerating {
                await generateThumbnail()
            }
        }
    }

    @ViewBuilder
    private var generatedThumbnailContent: some View {
        if let image = generatedImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            skeletonPlaceholder
                .task {
                    if !isGenerating {
                        await generateThumbnail()
                    }
                }
        }
    }

    private var skeletonPlaceholder: some View {
        Rectangle()
            .fill(ColorTokens.backgroundSubtler)
            .overlay {
                ProgressView()
                    .tint(.secondary)
            }
    }

    private func generateThumbnail() async {
        isGenerating = true
        generatedImage = await VideoThumbnailGenerator.shared.thumbnail(for: videoURL)
        isGenerating = false
    }
}

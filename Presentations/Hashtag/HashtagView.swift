//
//  HashtagView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI

// MARK: - HashtagView

struct HashtagView: View {

    @State private var viewModel: HashtagViewModel

    init(viewModel: HashtagViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Header
                hashtagHeader

                Divider()

                // Posts grid
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    ProgressView()
                        .padding(.top, DS.Spacing.xxxl)
                } else {
                    postGrid
                }
            }
        }
        .navigationTitle("#\(viewModel.hashtagName)")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadPosts()
        }
    }

    // MARK: - Header

    private var hashtagHeader: some View {
        HStack(spacing: DS.Spacing.md) {
            // Hashtag icon
            Circle()
                .fill(ColorTokens.buttonSecondary)
                .frame(width: DS.Size.avatarLarge, height: DS.Size.avatarLarge)
                .overlay {
                    Text("#")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }

            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                Text(formatCount(viewModel.postCount) + " posts")
                    .font(DS.Font.username)

                Button(action: {}) {
                    Text(L10n.Common.follow)
                        .font(DS.Font.subheadlineBold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, DS.Spacing.xl)
                        .padding(.vertical, DS.Spacing.xs)
                        .background(ColorTokens.accentPrimary, in: RoundedRectangle(cornerRadius: DS.Radius.medium))
                }
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Post Grid

    private var postGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: DS.Size.gridSpacing),
            GridItem(.flexible(), spacing: DS.Size.gridSpacing),
            GridItem(.flexible(), spacing: DS.Size.gridSpacing)
        ], spacing: DS.Size.gridSpacing) {
            ForEach(viewModel.posts) { post in
                if let media = post.mediaItems.first {
                    AsyncImage(url: media.thumbnailURL ?? media.url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(Color.gray.opacity(0.2))
                    }
                    .frame(minHeight: DS.Size.gridCellMinHeight)
                    .clipped()
                    .onTapGesture {
                        AppRouter.shared.push(.postDetail(postId: post.id))
                    }
                }
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

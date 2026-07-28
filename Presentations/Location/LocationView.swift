//
//  LocationView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI

// MARK: - LocationView

struct LocationView: View {

    @State private var viewModel: LocationViewModel

    init(viewModel: LocationViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Header
                locationHeader

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
        .navigationTitle(viewModel.locationName)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadPosts()
        }
    }

    // MARK: - Header

    private var locationHeader: some View {
        VStack(spacing: DS.Spacing.sm) {
            // Map placeholder
            RoundedRectangle(cornerRadius: DS.Radius.large)
                .fill(ColorTokens.backgroundSecondary)
                .frame(height: 150)
                .overlay {
                    VStack(spacing: DS.Spacing.xxs) {
                        Image(systemName: "map.fill")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text(viewModel.locationName)
                            .font(DS.Font.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

            // Action buttons
            HStack(spacing: DS.Spacing.sm) {
                Button(action: {}) {
                    Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                        .font(DS.Font.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, DS.Spacing.md)
                        .padding(.vertical, DS.Spacing.xs)
                        .background(ColorTokens.buttonSecondary, in: RoundedRectangle(cornerRadius: DS.Radius.medium))
                }

                Button(action: {}) {
                    Label("Save", systemImage: "bookmark")
                        .font(DS.Font.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, DS.Spacing.md)
                        .padding(.vertical, DS.Spacing.xs)
                        .background(ColorTokens.buttonSecondary, in: RoundedRectangle(cornerRadius: DS.Radius.medium))
                }

                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
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
}

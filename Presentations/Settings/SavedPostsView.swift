//
//  SavedPostsView.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI
import NukeUI

// MARK: - SavedPostsViewModel

@MainActor
@Observable
final class SavedPostsViewModel {

    private(set) var posts: [Post] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let postRepository: PostRepositoryProtocol
    private var didLoad = false

    init(postRepository: PostRepositoryProtocol) {
        self.postRepository = postRepository
    }

    func loadSavedPosts(reset: Bool = false) async {
        guard !isLoading else { return }
        if didLoad && !reset { return }

        isLoading = true
        errorMessage = nil

        do {
            posts = try await postRepository.fetchSavedPosts(page: 1, perPage: 30)
            didLoad = true
        } catch {
            errorMessage = error.userMessage
        }

        isLoading = false
    }
}

// MARK: - SavedPostsView

struct SavedPostsView: View {

    @State private var viewModel: SavedPostsViewModel

    init(viewModel: SavedPostsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private let columns = [
        GridItem(.flexible(), spacing: DS.Spacing.xxxs),
        GridItem(.flexible(), spacing: DS.Spacing.xxxs),
        GridItem(.flexible(), spacing: DS.Spacing.xxxs)
    ]

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.posts.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage, viewModel.posts.isEmpty {
                ErrorStateView(
                    message: errorMessage,
                    retryAction: { Task { await viewModel.loadSavedPosts(reset: true) } }
                )
            } else if viewModel.posts.isEmpty {
                ContentUnavailableView(
                    L10n.Settings.savedEmptyTitle,
                    systemImage: "bookmark",
                    description: Text(L10n.Settings.savedEmptyDescription)
                )
            } else {
                grid
            }
        }
        .navigationTitle(L10n.Settings.saved)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadSavedPosts()
        }
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: DS.Spacing.xxxs) {
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
                        } else {
                            ColorTokens.backgroundSubtler
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
        }
    }
}

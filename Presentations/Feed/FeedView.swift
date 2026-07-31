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
        toggleLikeUseCase: DIContainer.shared.resolve(ToggleLikePostUseCaseProtocol.self)
    )

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Stories bar placeholder
                StoriesBarView()
                    .padding(.bottom, 8)

                Divider()

                // Posts
                ForEach(viewModel.posts) { post in
                    PostCardView(post: post) {
                        Task { await viewModel.toggleLike(for: post) }
                    }
                    .onAppear {
                        if post.id == viewModel.posts.last?.id {
                            Task { await viewModel.loadMore() }
                        }
                    }

                    Divider()
                }

                if viewModel.isLoading && !viewModel.posts.isEmpty {
                    ProgressView()
                        .padding()
                }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text(L10n.Feed.title)
                    .font(.system(size: 24, weight: .bold, design: .serif))
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        AppRouter.shared.present(sheet: .createPost)
                    } label: {
                        Image(systemName: "plus.app")
                            .font(.title3)
                    }

                    Button {
                        AppRouter.shared.push(.directMessages)
                    } label: {
                        Image(systemName: "paperplane")
                            .font(.title3)
                    }
                }
                .tint(.primary)
            }
        }
        .task {
            if viewModel.posts.isEmpty {
                await viewModel.loadFeed()
            }
        }
    }
}

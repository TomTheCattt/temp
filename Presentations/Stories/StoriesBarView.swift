//
//  StoriesBarView.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI
import NukeUI

// MARK: - StoriesBarView

/// Horizontal scrolling bar of story circles displayed at the top of the feed.
struct StoriesBarView: View {

    @State private var stories: [Story] = []

    private let fetchStoriesUseCase: FetchStoriesUseCaseProtocol

    init(fetchStoriesUseCase: FetchStoriesUseCaseProtocol? = nil) {
        self.fetchStoriesUseCase = fetchStoriesUseCase
            ?? DIContainer.shared.resolve(FetchStoriesUseCaseProtocol.self)
    }

    /// Whether current user has an active story.
    private var hasMyStory: Bool {
        let userId = SessionStore.shared.currentUserId
        return stories.contains { $0.author.id == userId }
    }
    
    private var myStories: [Story] {
        let userId = SessionStore.shared.currentUserId
        return stories.filter { $0.author.id == userId }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: DS.Spacing.formGap) {
                // "Your Story" button
                MyStoryCircleView(stories: myStories)
                    .onTapGesture {
                        if hasMyStory {
                            AppRouter.shared.present(fullScreen: .myStory)
                        } else {
                            AppRouter.shared.present(fullScreen: .storyCamera)
                        }
                    }
                    .contextMenu {
                        if hasMyStory {
                            Button {
                                AppRouter.shared.present(fullScreen: .storyCamera)
                            } label: {
                                Label {
                                    Text("Add to Story")
                                } icon: {
                                    InstagramIcon(.plus, size: 16)
                                }
                            }
                            Button {
                                AppRouter.shared.present(fullScreen: .myStory)
                            } label: {
                                Label {
                                    Text("View Story")
                                } icon: {
                                    InstagramIcon(.system(name: "eye"), size: 16)
                                }
                            }
                        }
                    }

                // Other users' stories (exclude current user — shown as "Your Story")
                ForEach(stories.filter { $0.author.id != SessionStore.shared.currentUserId }) { story in
                    StoryCircleView(story: story)
                        .onTapGesture {
                            AppRouter.shared.present(fullScreen: .storyViewer(userId: story.author.id))
                        }
                }
            }
            .padding(.horizontal, DS.Padding.content)
            .padding(.vertical, DS.Spacing.xs)
        }
        .task {
            await loadStories()
        }
        .onReceive(NotificationCenter.default.publisher(for: .didCreateStory)) { _ in
            Task {
                await loadStories()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didUpdateStoryViewed)) { notification in
            guard let storyId = notification.object as? String else { return }
            if let index = stories.firstIndex(where: { $0.id == storyId }) {
                stories[index].isViewed = true
            }
        }
    }

    private func loadStories() async {
        do {
            let fetched = try await fetchStoriesUseCase.execute()
            let currentUserId = SessionStore.shared.currentUserId
            let myStories = fetched.filter { $0.author.id == currentUserId }
            let otherStories = fetched.filter { $0.author.id != currentUserId }
            stories = myStories + otherStories
        } catch {
            stories = []
        }
    }

}

// MARK: - MyStoryCircleView
struct MyStoryCircleView: View {
    
    let stories: [Story]
    
    private var hasMyStory: Bool {
        !stories.isEmpty
    }
    
    private var hasViewedAllStories: Bool {
        !stories.contains { $0.isViewed == false }
    }
    
    var body: some View {
        VStack(spacing: DS.Spacing.xs) {
            if hasMyStory {
                LazyImage(url: SessionStore.shared.currentUser?.avatarURL) { state in
                    if let image = state.image {
                        image.resizable()
                    } else {
                        Circle().fill(ColorTokens.buttonSecondary)
                    }
                }
                .frame(width: DS.Size.avatarLarge, height: DS.Size.avatarLarge)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            hasViewedAllStories
                            ? AnyShapeStyle(Color(.systemGray4))
                            : AnyShapeStyle(LinearGradient(
                                colors: [.red, .orange, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )),
                            lineWidth: hasViewedAllStories ? DS.Stroke.standard : 2.5
                        )
                        .frame(width: 70, height: 70)
                )
            } else {
                ZStack(alignment: .bottomTrailing) {
                    LazyImage(url: SessionStore.shared.currentUser?.avatarURL) { state in
                        if let image = state.image {
                            image.resizable()
                        } else {
                            Circle().fill(ColorTokens.buttonSecondary)
                        }
                    }
                    .frame(width: DS.Size.avatarLarge, height: DS.Size.avatarLarge)
                    .clipShape(Circle())
                    
                    // Plus badge
                    InstagramIcon(.system(name: "plus.circle.fill"), size: DS.Size.iconSmall, color: ColorTokens.accentPrimary)
                        .background(Circle().fill(Color(.systemBackground)).frame(width: DS.Spacing.lg, height: DS.Spacing.lg))
                }
            }
            
            Text(L10n.Story.yourStory)
                .font(DS.Font.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: DS.Size.captureButton)
    }
}

// MARK: - StoryCircleView

struct StoryCircleView: View {
    let story: Story

    var body: some View {
        VStack(spacing: DS.Spacing.xs) {
            LazyImage(url: story.author.avatarURL) { state in
                if let image = state.image {
                    image.resizable()
                } else {
                    Circle().fill(ColorTokens.buttonSecondary)
                }
            }
            .frame(width: DS.Size.avatarLarge, height: DS.Size.avatarLarge)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        story.isViewed
                            ? AnyShapeStyle(Color(.systemGray4))
                            : AnyShapeStyle(LinearGradient(
                                colors: [.red, .orange, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )),
                        lineWidth: story.isViewed ? DS.Stroke.standard : 2.5
                    )
                    .frame(width: 70, height: 70)
            )

            Text(story.author.username)
                .font(DS.Font.caption2)
                .foregroundStyle(story.isViewed ? .secondary : .primary)
                .lineLimit(1)
        }
        .frame(width: DS.Size.captureButton)
    }
}

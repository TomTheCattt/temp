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

    @State private var stories: [Story] = MockData.stories
    @State private var showYourStory = true

    /// Whether current user has an active story.
    private var hasMyStory: Bool {
        let userId = SessionStore.shared.currentUserId
        return stories.contains { $0.author.id == userId }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: DS.Spacing.formGap) {
                // "Your Story" button
                if showYourStory {
                    yourStoryItem
                        .onTapGesture {
                            if hasMyStory {
                                AppRouter.shared.present(fullScreen: .myStory)
                            } else {
                                AppRouter.shared.present(fullScreen: .storyCamera)
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
    }

    private var yourStoryItem: some View {
        VStack(spacing: DS.Spacing.xxs) {
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
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(ColorTokens.accentPrimary)
                    .background(Circle().fill(Color(.systemBackground)).frame(width: DS.Spacing.lg, height: DS.Spacing.lg))
            }

            Text("Your Story")
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
        VStack(spacing: DS.Spacing.xxs) {
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

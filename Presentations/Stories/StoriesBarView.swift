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

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 14) {
                // "Your Story" button
                if showYourStory {
                    yourStoryItem
                }

                // Other users' stories
                ForEach(stories) { story in
                    StoryCircleView(story: story)
                        .onTapGesture {
                            AppRouter.shared.push(.storyViewer(userId: story.author.id))
                        }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private var yourStoryItem: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottomTrailing) {
                LazyImage(url: MockData.currentUser.avatarURL) { state in
                    if let image = state.image {
                        image.resizable()
                    } else {
                        Circle().fill(Color(.systemGray5))
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(Circle())

                // Plus badge
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.blue)
                    .background(Circle().fill(Color(.systemBackground)).frame(width: 20, height: 20))
            }

            Text("Your Story")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: 72)
    }
}

// MARK: - StoryCircleView

struct StoryCircleView: View {
    let story: Story

    var body: some View {
        VStack(spacing: 4) {
            LazyImage(url: story.author.avatarURL) { state in
                if let image = state.image {
                    image.resizable()
                } else {
                    Circle().fill(Color(.systemGray5))
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        story.isViewed
                            ? Color(.systemGray4)
                            : LinearGradient(
                                colors: [.red, .orange, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                        lineWidth: story.isViewed ? 1.5 : 2.5
                    )
                    .frame(width: 70, height: 70)
            )

            Text(story.author.username)
                .font(.caption2)
                .foregroundStyle(story.isViewed ? .secondary : .primary)
                .lineLimit(1)
        }
        .frame(width: 72)
    }
}

//
//  NotificationsView.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI
import NukeUI

// MARK: - NotificationsView

struct NotificationsView: View {

    @State private var viewModel = NotificationsViewModel(
        fetchNotificationsUseCase: FetchNotificationsUseCase(
            notificationRepository: NotificationRepository()
        ),
        notificationRepository: NotificationRepository()
    )

    var body: some View {
        List {
            if viewModel.isLoading && viewModel.notifications.isEmpty {
                ForEach(0..<5, id: \.self) { _ in
                    notificationPlaceholder
                }
            } else {
                ForEach(viewModel.notifications) { notification in
                    NotificationRow(notification: notification)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Activity")
        .task {
            if viewModel.notifications.isEmpty {
                await viewModel.loadNotifications()
            }
        }
    }

    private var notificationPlaceholder: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 200, height: 12)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(width: 100, height: 10)
            }
            Spacer()
        }
        .listRowSeparator(.hidden)
    }
}

// MARK: - NotificationRow

private struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            LazyImage(url: notification.actor.avatarURL) { state in
                if let image = state.image {
                    image.resizable()
                } else {
                    Circle().fill(Color(.systemGray5))
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            .onTapGesture {
                AppRouter.shared.push(.userProfile(userId: notification.actor.id))
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                notificationText
                    .font(.subheadline)
                    .lineLimit(2)

                Text(notification.createdAt.timeAgoDisplay())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Thumbnail (if post-related)
            if let thumbnailURL = notification.postThumbnailURL {
                LazyImage(url: thumbnailURL) { state in
                    if let image = state.image {
                        image.resizable()
                    } else {
                        Color(.systemGray6)
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .onTapGesture {
                    if let postId = notification.postId {
                        AppRouter.shared.push(.postDetail(postId: postId))
                    }
                }
            }

            // Follow button for follow notifications
            if notification.type == .follow || notification.type == .followRequest {
                followButton
            }
        }
        .padding(.vertical, 4)
        .background(notification.isRead ? Color.clear : Color.blue.opacity(0.04))
        .contentShape(Rectangle())
    }

    // MARK: - Notification Text

    private var notificationText: Text {
        let username = Text(notification.actor.username).fontWeight(.semibold)

        switch notification.type {
        case .like:
            return username + Text(" liked your post.")
        case .comment:
            let comment = notification.commentText ?? ""
            return username + Text(" commented: \(comment)")
        case .follow:
            return username + Text(" started following you.")
        case .followRequest:
            return username + Text(" requested to follow you.")
        case .mention:
            return username + Text(" mentioned you in a post.")
        case .taggedInPost:
            return username + Text(" tagged you in a post.")
        case .storyMention:
            return username + Text(" mentioned you in their story.")
        case .liveVideo:
            return username + Text(" started a live video.")
        }
    }

    private var followButton: some View {
        Button {
            // Follow back
        } label: {
            Text("Follow")
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .foregroundStyle(.white)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(.blue)
                )
        }
    }
}

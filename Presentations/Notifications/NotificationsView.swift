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
        fetchNotificationsUseCase: DIContainer.shared.resolve(FetchNotificationsUseCaseProtocol.self),
        notificationRepository: DIContainer.shared.resolve(NotificationRepositoryProtocol.self)
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
                        .listRowInsets(EdgeInsets(top: DS.Spacing.iconGap, leading: DS.Spacing.md, bottom: DS.Spacing.iconGap, trailing: DS.Spacing.md))
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
        HStack(spacing: DS.Spacing.sm) {
            Circle()
                .fill(ColorTokens.buttonSecondary)
                .frame(width: DS.Size.avatarList, height: DS.Size.avatarList)
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                RoundedRectangle(cornerRadius: DS.Radius.small)
                    .fill(ColorTokens.buttonSecondary)
                    .frame(width: 200, height: DS.Spacing.sm)
                RoundedRectangle(cornerRadius: DS.Radius.small)
                    .fill(ColorTokens.backgroundSecondary)
                    .frame(width: 100, height: DS.Padding.inputBar)
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
        HStack(spacing: DS.Spacing.sm) {
            // Avatar
            LazyImage(url: notification.actor.avatarURL) { state in
                if let image = state.image {
                    image.resizable()
                } else {
                    Circle().fill(ColorTokens.buttonSecondary)
                }
            }
            .frame(width: DS.Size.avatarList, height: DS.Size.avatarList)
            .clipShape(Circle())
            .onTapGesture {
                AppRouter.shared.push(.userProfile(userId: notification.actor.id))
            }

            // Content
            VStack(alignment: .leading, spacing: DS.Spacing.xxxs) {
                notificationText
                    .font(DS.Font.subheadline)
                    .lineLimit(2)

                Text(notification.createdAt.timeAgoDisplay())
                    .font(DS.Font.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Thumbnail (if post-related)
            if let thumbnailURL = notification.postThumbnailURL {
                LazyImage(url: thumbnailURL) { state in
                    if let image = state.image {
                        image.resizable()
                    } else {
                        ColorTokens.backgroundSecondary
                    }
                }
                .frame(width: DS.Size.avatarList, height: DS.Size.avatarList)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
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
        .padding(.vertical, DS.Spacing.xxs)
        .background(notification.isRead ? Color.clear : ColorTokens.accentPrimary.opacity(DS.Opacity.subtle))
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
                .font(DS.Font.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, DS.Padding.horizontal)
                .padding(.vertical, DS.Spacing.iconGap)
                .foregroundStyle(.white)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.thumbnailCard, style: .continuous)
                        .fill(ColorTokens.accentPrimary)
                )
        }
    }
}

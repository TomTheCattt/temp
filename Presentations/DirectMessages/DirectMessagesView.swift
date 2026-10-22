//
//  DirectMessagesView.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI
import NukeUI

// MARK: - DirectMessagesView

struct DirectMessagesView: View {

    @State private var viewModel = DirectMessagesViewModel(
        messageRepository: DIContainer.shared.resolve(MessageRepositoryProtocol.self)
    )

    @State private var isScrolled: Bool = false
    @State private var showNotePrompt: Bool = false
    @State private var newNoteText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar for Chat (2 buttons: 1 center, 1 trailing)
            chatNavigationBar

            ScrollView {
                VStack(spacing: DS.Spacing.xs) {
                    // Instagram Notes Section (Ghi chú trạng thái 24h)
                    instagramNotesSection
                        .padding(.top, DS.Spacing.xs)

                    // Search Bar
                    searchBarSection
                        .padding(.horizontal, DS.Padding.horizontal)
                        .padding(.vertical, DS.Spacing.xxs)

                    // Section Title: "Tin nhắn"
                    HStack {
                        Text("Tin nhắn")
                            .font(DS.Font.headline)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.horizontal, DS.Padding.horizontal)
                    .padding(.top, DS.Spacing.xxs)

                    if viewModel.isLoading && viewModel.conversations.isEmpty {
                        ForEach(0..<6, id: \.self) { _ in
                            conversationPlaceholder
                                .padding(.horizontal, DS.Padding.horizontal)
                        }
                    } else if viewModel.filteredConversations.isEmpty {
                        EmptyStateView(
                            message: viewModel.searchQuery.isEmpty ? L10n.DirectMessages.noMessages : "Không tìm thấy cuộc trò chuyện",
                            systemImage: "bubble.left.and.bubble.right"
                        )
                        .padding(.top, DS.Spacing.xxl)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.filteredConversations) { conversation in
                                let otherUser = conversation.participants.first { $0.id != SessionStore.shared.currentUserId }
                                    ?? conversation.participants.first

                                ConversationRow(conversation: conversation)
                                    .onTapGesture {
                                        HapticFeedbackSafe.impact(.light)
                                        AppRouter.shared.push(.conversation(conversationId: conversation.id, recipient: otherUser))
                                    }
                                    .contextMenu {
                                        Button {
                                            HapticFeedbackSafe.impact(.light)
                                            viewModel.toggleMute(id: conversation.id)
                                        } label: {
                                            Label(
                                                conversation.isMuted ? "Bật thông báo" : "Tắt thông báo",
                                                systemImage: conversation.isMuted ? "bell.fill" : "bell.slash.fill"
                                            )
                                        }

                                        Button {
                                            HapticFeedbackSafe.impact(.light)
                                            viewModel.toggleUnread(id: conversation.id)
                                        } label: {
                                            Label(
                                                conversation.unreadCount > 0 ? "Đánh dấu là đã đọc" : "Đánh dấu là chưa đọc",
                                                systemImage: conversation.unreadCount > 0 ? "envelope.open" : "envelope.badge"
                                            )
                                        }

                                        Button(role: .destructive) {
                                            HapticFeedbackSafe.impact(.medium)
                                            viewModel.deleteConversation(id: conversation.id)
                                        } label: {
                                            Label("Xóa cuộc trò chuyện", systemImage: "trash")
                                        }
                                    }
                                    .padding(.horizontal, DS.Padding.horizontal)
                            }
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.loadConversations()
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y
            } action: { _, newOffset in
                let atTop = newOffset <= Constants.scrollThresholdTop
                if atTop != !isScrolled {
                    withAnimation(DS.Animation.standard) {
                        isScrolled = !atTop
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("Ghi chú mới", isPresented: $showNotePrompt) {
            TextField("Chia sẻ suy nghĩ của bạn...", text: $newNoteText)
            Button("Lưu") {
                viewModel.addOrUpdateNote(text: newNoteText)
                newNoteText = ""
            }
            Button("Hủy", role: .cancel) {
                newNoteText = ""
            }
        } message: {
            Text("Ghi chú sẽ biến mất sau 24 giờ.")
        }
        .task {
            if viewModel.conversations.isEmpty {
                await viewModel.loadConversations()
            }
        }
    }

    // MARK: - Chat Navigation Bar (2 buttons: 1 center, 1 trailing)

    private var chatNavigationBar: some View {
        CustomNavBarView(
            showDivider: true,
            isScrolled: isScrolled,
            leading: {
                Spacer().frame(width: DS.Size.buttonDefaultHeight)
            },
            center: {
                // Button 1: Center (Username dropdown)
                Button {
                    // Account switcher
                } label: {
                    HStack(spacing: DS.Spacing.xxs) {
                        Text(SessionStore.shared.currentUser?.username ?? L10n.Tab.chat)
                            .font(DS.Font.title3)
                            .fontWeight(.bold)
                        InstagramIcon(.chevronDown, size: 12, color: .primary)
                    }
                    .foregroundStyle(Color.primary)
                }
            },
            trailing: {
                // Button 2: Trailing (New message / Edit)
                Button {
                    HapticFeedbackSafe.impact(.light)
                    AppRouter.shared.present(sheet: .newMessage)
                } label: {
                    InstagramIcon(.system(name: "square.and.pencil"), size: 24, color: .primary)
                        .frame(width: 44, height: 44, alignment: .trailing)
                        .contentShape(Rectangle())
                }
            }
        )
    }

    // MARK: - Instagram Notes Section

    private var instagramNotesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: DS.Spacing.sm) {
                ForEach(viewModel.notes) { note in
                    noteItem(note)
                }
            }
            .padding(.horizontal, DS.Padding.horizontal)
        }
    }

    private func noteItem(_ note: InstagramNote) -> some View {
        Button {
            HapticFeedbackSafe.impact(.light)
            if note.isCurrentUser {
                newNoteText = note.text
                showNotePrompt = true
            } else {
                ToastManager.shared.info("\(note.user.username): \"\(note.text)\"")
            }
        } label: {
            VStack(spacing: 4) {
                // Thought Bubble on top of avatar
                ZStack {
                    Text(note.text)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ColorTokens.backgroundSecondary, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(UIColor.separator).opacity(0.3), lineWidth: 0.5))
                }
                .frame(width: 76, height: 38)

                // Avatar
                ZStack(alignment: .bottomTrailing) {
                    LazyImage(url: note.user.avatarURL) { state in
                        if let image = state.image {
                            image.resizable().scaledToFill()
                        } else {
                            Circle().fill(ColorTokens.buttonSecondary)
                        }
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())

                    if note.isCurrentUser {
                        InstagramIcon(.system(name: "plus.circle.fill"), size: 16, color: ColorTokens.accentPrimary)
                            .background(Circle().fill(Color(UIColor.systemBackground)))
                            .offset(x: 2, y: 2)
                    }
                }

                // Name
                Text(note.isCurrentUser ? "Ghi chú của bạn" : note.user.username)
                    .font(DS.Font.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: 76)
            }
        }
        .tint(.primary)
    }

    // MARK: - Search Bar Section

    private var searchBarSection: some View {
        HStack(spacing: DS.Spacing.xs) {
            InstagramIcon(.search(), size: 14, color: .secondary)

            TextField("Tìm kiếm", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .font(DS.Font.subheadline)

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    InstagramIcon(.system(name: "xmark.circle.fill"), size: 14, color: .secondary)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.sm)
        .padding(.vertical, 8)
        .background(ColorTokens.backgroundSecondary, in: RoundedRectangle(cornerRadius: DS.Radius.medium))
    }

    private var conversationPlaceholder: some View {
        HStack(spacing: DS.Spacing.sm) {
            Circle()
                .fill(ColorTokens.buttonSecondary)
                .frame(width: DS.Size.avatarStoryCircle, height: DS.Size.avatarStoryCircle)
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                RoundedRectangle(cornerRadius: DS.Radius.small)
                    .fill(ColorTokens.buttonSecondary)
                    .frame(width: 120, height: DS.Spacing.formGap)
                RoundedRectangle(cornerRadius: DS.Radius.small)
                    .fill(ColorTokens.backgroundSecondary)
                    .frame(width: 180, height: DS.Spacing.sm)
            }
            Spacer()
        }
        .listRowSeparator(.hidden)
    }
}

// MARK: - ConversationRow

private struct ConversationRow: View {
    let conversation: Conversation

    private var otherUser: User? {
        let currentId = SessionStore.shared.currentUserId
        return conversation.participants.first { $0.id != currentId }
            ?? conversation.participants.first
    }

    private var avatarURL: URL? {
        if conversation.isGroup {
            return conversation.groupAvatarURL ?? otherUser?.avatarURL
        }
        return otherUser?.avatarURL
    }

    private var displayName: String {
        if conversation.isGroup {
            return conversation.groupName ?? "Nhóm"
        }
        return otherUser?.username ?? "Unknown"
    }

    private var isMessageFromCurrentUser: Bool {
        guard let message = conversation.lastMessage else { return false }
        let currentId = SessionStore.shared.currentUserId
        return message.sender.id == currentId
    }

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            // Avatar
            LazyImage(url: avatarURL) { state in
                if let image = state.image {
                    image.resizable().scaledToFill()
                } else {
                    Circle().fill(ColorTokens.buttonSecondary)
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())

            // Content
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: DS.Spacing.xxs) {
                    Text(displayName)
                        .font(DS.Font.subheadline)
                        .fontWeight(conversation.unreadCount > 0 ? .bold : .regular)

                    if !conversation.isGroup && otherUser?.isVerified == true {
                        InstagramIcon(
                            .verifiedBadge,
                            size: DS.Size.iconSmall,
                            color: ColorTokens.accentPrimary
                        )
                    }
                }

                HStack(spacing: DS.Spacing.xxs) {
                    lastMessageText
                        .font(DS.Font.subheadline)
                        .foregroundStyle(conversation.unreadCount > 0 ? .primary : .secondary)
                        .lineLimit(1)

                    Text("· \(conversation.updatedAt.timeAgoDisplay())")
                        .font(DS.Font.subheadline)
                        .foregroundStyle(.secondary)

                    // Show delivery/read status for own last message
                    if let statusText = lastMessageStatusText {
                        Text("· \(statusText)")
                            .font(DS.Font.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Trailing Quick Camera shortcut or Unread badge
            HStack(spacing: DS.Spacing.xs) {
                // Unread badge
                if conversation.unreadCount > 0 {
                    Circle()
                        .fill(ColorTokens.accentPrimary)
                        .frame(width: 8, height: 8)
                }

                // Muted indicator
                if conversation.isMuted {
                    InstagramIcon(.system(name: "bell.slash.fill"), size: 12, color: .secondary)
                }

                // Quick Camera Icon (Standard Instagram Inbox Right Action)
                Button {
                    HapticFeedbackSafe.impact(.light)
                    AppRouter.shared.present(fullScreen: .creationHub(initialMode: .story))
                } label: {
                    InstagramIcon(.camera, size: 20, color: .secondary)
                        .frame(width: 32, height: 32)
                }
            }
        }
        .padding(.vertical, DS.Spacing.xxs)
        .contentShape(Rectangle())
    }

    private var lastMessageText: Text {
        guard let message = conversation.lastMessage else {
            return Text(L10n.DirectMessages.noMessages)
        }

        let isMine = isMessageFromCurrentUser
        let prefix: String = {
            if isMine {
                return L10n.DirectMessages.you
            } else if conversation.isGroup {
                let senderName = message.sender.username.isEmpty ? "Thành viên" : message.sender.username
                return "\(senderName): "
            } else {
                return ""
            }
        }()

        switch message.content {
        case .text(let text):
            return Text(prefix + text)
        case .image:
            return Text(prefix + L10n.DirectMessages.sentPhoto)
        case .video:
            return Text(prefix + L10n.DirectMessages.sentVideo)
        case .audio:
            return Text(prefix + L10n.DirectMessages.sentVoice)
        case .post:
            return Text(prefix + L10n.DirectMessages.sharedPost)
        case .story:
            return Text(prefix + L10n.DirectMessages.sharedStory)
        case .reel:
            return Text(prefix + L10n.DirectMessages.sharedReel)
        case .like:
            return Text(prefix + "❤️")
        }
    }

    /// Returns status text for the last message only if it was sent by the current user.
    private var lastMessageStatusText: String? {
        guard let message = conversation.lastMessage, isMessageFromCurrentUser else { return nil }

        switch message.status {
        case .sent, .delivered:
            return L10n.Chat.statusSent
        case .read:
            return L10n.Chat.statusRead
        case .sending, .failed:
            return nil
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let scrollThresholdTop: CGFloat = 10
}

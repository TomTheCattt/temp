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
        .onAppear {
            viewModel.refreshFromLocal()
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
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .fontWeight(.bold)
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
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(Color.primary)
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
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(ColorTokens.accentPrimary)
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
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            TextField("Tìm kiếm", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .font(DS.Font.subheadline)

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
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

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            // Avatar
            let otherUser = conversation.participants.first { $0.id != SessionStore.shared.currentUserId }

            LazyImage(url: otherUser?.avatarURL) { state in
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
                    Text(conversation.groupName ?? otherUser?.username ?? "Unknown")
                        .font(DS.Font.subheadline)
                        .fontWeight(conversation.unreadCount > 0 ? .bold : .regular)

                    if otherUser?.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .font(DS.Font.caption2)
                            .foregroundStyle(ColorTokens.accentPrimary)
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
                    Image(systemName: "bell.slash.fill")
                        .font(DS.Font.caption)
                        .foregroundStyle(.secondary)
                }

                // Quick Camera Icon (Standard Instagram Inbox Right Action)
                Button {
                    HapticFeedbackSafe.impact(.light)
                    AppRouter.shared.present(fullScreen: .creationHub(initialMode: .story))
                } label: {
                    Image(systemName: "camera")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
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

        let isMine = message.sender.id == SessionStore.shared.currentUserId
        let prefix = isMine ? L10n.DirectMessages.you : ""

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
        guard let message = conversation.lastMessage else { return nil }
        let isMine = message.sender.id == SessionStore.shared.currentUserId
        guard isMine else { return nil }

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

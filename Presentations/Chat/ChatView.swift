//
//  ChatView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI

// MARK: - ChatView

struct ChatView: View {

    @State private var viewModel: ChatViewModel
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool

    /// Horizontal drag offset for iMessage-style timestamp reveal.
    /// Negative value means the user dragged left (revealing timestamps on the right).
    @State private var dragOffset: CGFloat = 0

    private let maxDragOffset: CGFloat = -80

    init(viewModel: ChatViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollView {
                LazyVStack(spacing: DS.Spacing.xxs) {
                    if viewModel.isLoading && viewModel.messages.isEmpty {
                        ProgressView()
                            .padding(.top, DS.Spacing.xxxl)
                    } else {
                        // Load more trigger at top
                        if viewModel.messages.count >= DS.Layout.messagesPageSize {
                            ProgressView()
                                .padding(.vertical, DS.Spacing.xs)
                                .task { await viewModel.loadMoreMessages() }
                        }

                        // Messages (newest at bottom, reversed)
                        let reversed = viewModel.messages.reversed() as [Message]
                        ForEach(Array(reversed.enumerated()), id: \.element.id) { index, message in
                            let isLastOwnMessage = isLastMessageFromCurrentUser(message, in: reversed)
                            messageBubble(message, showReadReceipt: isLastOwnMessage)
                        }
                    }
                }
                .padding(.vertical, DS.Spacing.xs)
            }
            .defaultScrollAnchor(.bottom)
            .gesture(timestampDragGesture)

            // Input bar
            messageInputBar
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadMessages()
        }
    }

    // MARK: - Timestamp Drag Gesture (iMessage-style)

    private var timestampDragGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onChanged { value in
                let translation = value.translation.width
                // Only allow dragging left (negative)
                if translation < 0 {
                    // Apply rubber-band effect beyond maxDragOffset
                    let clamped = max(translation, maxDragOffset * 1.5)
                    withAnimation(.interactiveSpring()) {
                        dragOffset = clamped
                    }
                }
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    dragOffset = 0
                }
            }
    }

    // MARK: - Message Bubble

    @ViewBuilder
    private func messageBubble(_ message: Message, showReadReceipt: Bool) -> some View {
        let isMe = message.sender.id == viewModel.currentUserId

        HStack(spacing: 0) {
            // Message content area (shifts left with drag)
            HStack(alignment: .bottom, spacing: DS.Spacing.xs) {
                if isMe { Spacer(minLength: 60) }

                if !isMe {
                    AsyncImage(url: message.sender.avatarURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(DS.Opacity.low))
                    }
                    .frame(width: DS.Size.avatarSmall, height: DS.Size.avatarSmall)
                    .clipShape(Circle())
                }

                VStack(alignment: isMe ? .trailing : .leading, spacing: DS.Spacing.xxxs) {
                    bubbleContent(message.content, isMe: isMe)

                    // "Đã xem" only for the last own message when status is .read
                    if showReadReceipt && isMe && message.status == .read {
                        Text(L10n.Chat.statusRead)
                            .font(DS.Font.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if !isMe { Spacer(minLength: 60) }
            }
            .offset(x: dragOffset)

            // Timestamp revealed on the right when dragging left
            if dragOffset < -5 {
                Text(message.createdAt, style: .time)
                    .font(DS.Font.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .center)
                    .offset(x: dragOffset + 80)
                    .opacity(timestampOpacity)
            }
        }
        .padding(.horizontal, DS.Padding.content)
        .padding(.vertical, DS.Spacing.xxxs)
        .clipped()
    }

    /// Opacity for the timestamp based on drag progress
    private var timestampOpacity: Double {
        let progress = min(abs(dragOffset) / abs(maxDragOffset), 1.0)
        return Double(progress)
    }

    // MARK: - Helpers (last own message check)

    /// Determines if the given message is the last one sent by the current user
    /// in the displayed (reversed) list. The reversed list shows newest at the bottom,
    /// so the "last" own message is the last occurrence when iterating from top to bottom.
    private func isLastMessageFromCurrentUser(_ message: Message, in displayedMessages: [Message]) -> Bool {
        guard message.sender.id == viewModel.currentUserId else { return false }
        // Find the last message from current user (newest = last in displayed array)
        let lastOwn = displayedMessages.last { $0.sender.id == viewModel.currentUserId }
        return lastOwn?.id == message.id
    }

    // MARK: - Bubble Content

    @ViewBuilder
    private func bubbleContent(_ content: MessageContent, isMe: Bool) -> some View {
        switch content {
        case .text(let text):
            Text(text)
                .font(DS.Font.messageText)
                .foregroundStyle(isMe ? .white : .primary)
                .padding(.horizontal, DS.Spacing.formGap)
                .padding(.vertical, DS.Spacing.xs)
                .background(
                    isMe ? ColorTokens.brandBlue : ColorTokens.buttonSecondary,
                    in: RoundedRectangle(cornerRadius: DS.Radius.bubble)
                )

        case .image(let url):
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                RoundedRectangle(cornerRadius: DS.Radius.large)
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large))

        case .like:
            Text("❤️")
                .font(.system(size: DS.Spacing.xxxl))

        case .audio(_, let duration):
            HStack(spacing: DS.Spacing.xs) {
                Image(systemName: "play.fill")
                    .font(DS.Font.caption)
                RoundedRectangle(cornerRadius: DS.Spacing.xxxs)
                    .fill(isMe ? Color.white.opacity(DS.Opacity.overlay) : Color.gray.opacity(DS.Opacity.low))
                    .frame(height: DS.Stroke.thick)
                Text(formatDuration(duration))
                    .font(DS.Font.caption2)
            }
            .foregroundStyle(isMe ? .white : .primary)
            .padding(.horizontal, DS.Spacing.formGap)
            .padding(.vertical, DS.Padding.inputBar)
            .background(
                isMe ? ColorTokens.brandBlue : ColorTokens.buttonSecondary,
                in: RoundedRectangle(cornerRadius: DS.Radius.bubble)
            )
            .frame(width: 180)

        case .video(_, thumbnailURL: let thumb):
            ZStack {
                if let thumbURL = thumb {
                    AsyncImage(url: thumbURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                } else {
                    Color.gray.opacity(DS.Opacity.low)
                }
                Image(systemName: "play.circle.fill")
                    .font(DS.Font.title)
                    .foregroundStyle(.white.opacity(DS.Opacity.high))
            }
            .frame(width: 200, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large))

        case .post, .story, .reel:
            HStack(spacing: DS.Spacing.xs) {
                Image(systemName: "square.and.arrow.up")
                    .font(DS.Font.caption)
                Text(L10n.Common.sharedContent)
                    .font(DS.Font.messageText)
            }
            .foregroundStyle(isMe ? .white : .primary)
            .padding(.horizontal, DS.Spacing.formGap)
            .padding(.vertical, DS.Spacing.xs)
            .background(
                isMe ? ColorTokens.brandBlue : ColorTokens.buttonSecondary,
                in: RoundedRectangle(cornerRadius: DS.Radius.bubble)
            )
        }
    }

    // MARK: - Input Bar

    private var messageInputBar: some View {
        HStack(spacing: DS.Spacing.sm) {
            // Camera
            Button(action: {}) {
                Image(systemName: "camera.fill")
                    .font(DS.Font.title3)
                    .foregroundStyle(ColorTokens.accentPrimary)
            }

            // Text field
            HStack(spacing: DS.Spacing.xs) {
                TextField(L10n.Chat.messagePlaceholder, text: $messageText)
                    .textFieldStyle(.plain)
                    .font(DS.Font.subheadline)
                    .focused($isInputFocused)

                if messageText.isEmpty {
                    Button(action: {}) {
                        Image(systemName: "mic.fill")
                            .font(DS.Font.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Button(action: {}) {
                        Image(systemName: "photo")
                            .font(DS.Font.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.formGap)
            .padding(.vertical, DS.Spacing.xs)
            .background(ColorTokens.backgroundSecondary, in: Capsule())

            // Send or Like
            if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button(action: {
                    Task { await viewModel.sendLikeReaction() }
                }) {
                    Image(systemName: "heart")
                        .font(DS.Font.title3)
                        .foregroundStyle(.primary)
                }
            } else {
                Button(action: {
                    let text = messageText
                    messageText = ""
                    Task { await viewModel.sendTextMessage(text) }
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(DS.Font.title3)
                        .foregroundStyle(ColorTokens.accentPrimary)
                }
                .disabled(viewModel.isSending)
            }
        }
        .padding(.horizontal, DS.Padding.content)
        .padding(.vertical, DS.Spacing.xs)
        .overlay(alignment: .top) { Divider() }
    }

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

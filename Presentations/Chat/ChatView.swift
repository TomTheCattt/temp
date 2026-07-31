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
                        ForEach(viewModel.messages.reversed()) { message in
                            messageBubble(message)
                        }
                    }
                }
                .padding(.vertical, DS.Spacing.xs)
            }
            .defaultScrollAnchor(.bottom)

            // Input bar
            messageInputBar
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadMessages()
        }
    }

    // MARK: - Message Bubble

    @ViewBuilder
    private func messageBubble(_ message: Message) -> some View {
        let isMe = message.sender.id == "current_user"
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

                // Status + time
                HStack(spacing: DS.Spacing.xxs) {
                    Text(message.createdAt, style: .time)
                        .font(DS.Font.caption2)
                        .foregroundStyle(.secondary)
                    if isMe {
                        statusIcon(message.status)
                    }
                }
            }

            if !isMe { Spacer(minLength: 60) }
        }
        .padding(.horizontal, DS.Padding.content)
        .padding(.vertical, DS.Spacing.xxxs)
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

    // MARK: - Status Icon

    @ViewBuilder
    private func statusIcon(_ status: MessageStatus) -> some View {
        switch status {
        case .sending:
            Image(systemName: "clock")
                .font(DS.Font.caption2)
                .foregroundStyle(.secondary)
        case .sent:
            Image(systemName: "checkmark")
                .font(DS.Font.caption2)
                .foregroundStyle(.secondary)
        case .delivered:
            Image(systemName: "checkmark")
                .font(DS.Font.caption2)
                .foregroundStyle(ColorTokens.accentPrimary)
        case .read:
            Image(systemName: "eye.fill")
                .font(DS.Font.caption2)
                .foregroundStyle(ColorTokens.accentPrimary)
        case .failed:
            Image(systemName: "exclamationmark.circle")
                .font(DS.Font.caption2)
                .foregroundStyle(ColorTokens.destructive)
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

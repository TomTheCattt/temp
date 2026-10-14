//
//  ChatView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI
import PhotosUI

// MARK: - ChatView

struct ChatView: View {

    @State private var viewModel: ChatViewModel
    @State private var messageText = ""
    @State private var photoPickerItem: PhotosPickerItem?
    @FocusState private var isInputFocused: Bool

    /// Horizontal drag offset for iMessage-style timestamp reveal.
    /// Negative value means the user dragged left (revealing timestamps on the right).
    @State private var dragOffset: CGFloat = 0

    /// Max leftward reveal distance (negative). Reveal + opacity share this constant.
    private let maxReveal = DS.Layout.chatTimestampRevealDistance

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
                    } else if let errorMessage = viewModel.errorMessage, viewModel.messages.isEmpty {
                        ErrorStateView(
                            message: errorMessage,
                            retryAction: { Task { await viewModel.loadMessages() } }
                        )
                        .padding(.top, DS.Spacing.xxxl)
                    } else if viewModel.messages.isEmpty {
                        EmptyStateView(
                            message: L10n.Chat.empty,
                            systemImage: "bubble.left.and.bubble.right"
                        )
                        .padding(.top, DS.Spacing.xxxl)
                    } else {
                        // Load more trigger at top — gated on hasMorePages so it
                        // stops once history is exhausted (no infinite loop).
                        if viewModel.hasMorePages {
                            ProgressView()
                                .padding(.vertical, DS.Spacing.xs)
                                .task { await viewModel.loadMoreMessages() }
                        }

                        messageList
                    }
                }
                .padding(.vertical, DS.Spacing.xs)
            }
            .defaultScrollAnchor(.bottom)
            .simultaneousGesture(timestampDragGesture)

            // Input bar
            messageInputBar
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadMessages()
        }
        .onAppear {
            // Restore unsent text into the field when a send fails.
            viewModel.restoreDraft = { text in
                if messageText.isEmpty { messageText = text }
            }
        }
        .onChange(of: photoPickerItem) { _, newItem in
            guard let newItem else { return }
            Task { await handlePickedPhoto(newItem) }
        }
    }

    // MARK: - Message List

    @ViewBuilder
    private var messageList: some View {
        // Newest at bottom (reverse of the newest-first store).
        let reversed = Array(viewModel.messages.reversed())
        // Precompute the last own message id once (avoids O(n^2) scans per row).
        let lastOwnId = reversed.last { $0.sender.id == viewModel.currentUserId }?.id

        ForEach(Array(reversed.enumerated()), id: \.element.id) { index, message in
            let isMe = message.sender.id == viewModel.currentUserId
            // Show avatar only on the last message of a consecutive incoming run.
            let nextSameSender: Bool = {
                let nextIndex = index + 1
                guard nextIndex < reversed.count else { return false }
                return reversed[nextIndex].sender.id == message.sender.id
            }()
            messageBubble(
                message,
                isMe: isMe,
                showReadReceipt: message.id == lastOwnId,
                showAvatar: !isMe && !nextSameSender
            )
        }
    }

    // MARK: - Timestamp Drag Gesture (iMessage-style)

    private var timestampDragGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onChanged { value in
                let width = value.translation.width
                let height = value.translation.height
                // Only react to predominantly-horizontal, leftward drags so we
                // don't fight vertical scrolling.
                guard abs(width) > abs(height), width < 0 else { return }
                // Track raw offset during the drag (no per-frame animation).
                dragOffset = max(width, -maxReveal * 1.5)
            }
            .onEnded { _ in
                // Only animate the reset on release.
                withAnimation(DS.Animation.spring) {
                    dragOffset = 0
                }
            }
    }

    // MARK: - Message Bubble

    @ViewBuilder
    private func messageBubble(
        _ message: Message,
        isMe: Bool,
        showReadReceipt: Bool,
        showAvatar: Bool
    ) -> some View {
        HStack(spacing: 0) {
            // Message content area (shifts left with drag)
            HStack(alignment: .bottom, spacing: DS.Spacing.xs) {
                if isMe { Spacer(minLength: DS.Size.chatBubbleSpacer) }

                if !isMe {
                    // Reserve avatar width for consecutive-run alignment; only the
                    // last message of the run actually renders the image.
                    Group {
                        if showAvatar {
                            AsyncImage(url: message.sender.avatarURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Circle().fill(Color.gray.opacity(DS.Opacity.low))
                            }
                            .clipShape(Circle())
                        } else {
                            Color.clear
                        }
                    }
                    .frame(width: DS.Size.avatarSmall, height: DS.Size.avatarSmall)
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

                if !isMe { Spacer(minLength: DS.Size.chatBubbleSpacer) }
            }
            .offset(x: dragOffset)

            // Timestamp revealed on the right when dragging left
            if dragOffset < -DS.Layout.chatTimestampRevealThreshold {
                Text(message.createdAt, style: .time)
                    .font(DS.Font.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: DS.Size.chatTimestampWidth, alignment: .center)
                    .offset(x: dragOffset + maxReveal)
                    .opacity(timestampOpacity)
            }
        }
        .padding(.horizontal, DS.Padding.content)
        .padding(.vertical, DS.Spacing.xxxs)
        .clipped()
    }

    /// Opacity for the timestamp based on drag progress.
    /// Uses the same `maxReveal` constant as the reveal offset for a consistent feel.
    private var timestampOpacity: Double {
        let progress = min(abs(dragOffset) / maxReveal, 1.0)
        return Double(progress)
    }

    // MARK: - Bubble Content

    @ViewBuilder
    private func bubbleContent(_ content: MessageContent, isMe: Bool) -> some View {
        switch content {
        case .text(let text):
            Text(text)
                .font(DS.Font.messageText)
                .foregroundStyle(isMe ? .white : .black)
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
                    .fill(ColorTokens.backgroundSubtler)
            }
            .frame(width: DS.Size.chatImageBubble, height: DS.Size.chatImageBubble)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large))

        case .like:
            Text("❤️")
                .font(.system(size: DS.Size.chatLikeEmoji))

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
            .frame(width: DS.Size.chatAudioBubbleWidth)

        case .video(_, thumbnailURL: let thumb):
            ZStack {
                if let thumbURL = thumb {
                    AsyncImage(url: thumbURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        ColorTokens.backgroundSubtler
                    }
                } else {
                    Color.gray.opacity(DS.Opacity.low)
                }
                Image(systemName: "play.circle.fill")
                    .font(DS.Font.title)
                    .foregroundStyle(.white.opacity(DS.Opacity.high))
            }
            .frame(width: DS.Size.chatVideoBubbleWidth, height: DS.Size.chatVideoBubbleHeight)
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
            // TODO: No capture flow is available on the Chat screen yet, and
            // sendMessage has no camera entry point. Left as a no-op until a
            // capture flow exists — prefer the photo picker (wired below).
            Button(action: {}) {
                Image(systemName: "camera.fill")
                    .font(DS.Font.title3)
                    .foregroundStyle(ColorTokens.accentPrimary)
            }
            .disabled(viewModel.isSending)

            // Text field
            HStack(spacing: DS.Spacing.xs) {
                TextField(L10n.Chat.messagePlaceholder, text: $messageText)
                    .textFieldStyle(.plain)
                    .font(DS.Font.subheadline)
                    .focused($isInputFocused)

                if messageText.isEmpty {
                    // Mic
                    // TODO: No audio-capture flow exists yet; leaving as a no-op
                    // rather than fabricating a recording pipeline.
                    Button(action: {}) {
                        Image(systemName: "mic.fill")
                            .font(DS.Font.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .disabled(viewModel.isSending)

                    // Photo picker — sends the picked image via the view model.
                    PhotosPicker(selection: $photoPickerItem, matching: .images) {
                        Image(systemName: "photo")
                            .font(DS.Font.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .disabled(viewModel.isSending)
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
                .disabled(viewModel.isSending)
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

    // MARK: - Photo Picker Handling

    /// Load the picked photo to a temporary file URL and send it as an image message.
    private func handlePickedPhoto(_ item: PhotosPickerItem) async {
        defer { photoPickerItem = nil }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")
        guard (try? data.write(to: tempURL)) != nil else { return }
        await viewModel.sendImageMessage(url: tempURL)
    }

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

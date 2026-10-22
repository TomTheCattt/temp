//
//  ChatView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI
import PhotosUI
import NukeUI
import AVFoundation
import UniformTypeIdentifiers

// MARK: - ChatView

struct ChatView: View {

    @State private var viewModel: ChatViewModel
    @ObservedObject private var audioPlayer = ChatAudioPlayer.shared

    @State private var messageText = ""
    @State private var photoPickerItem: PhotosPickerItem?
    @FocusState private var isInputFocused: Bool

    // Voice Recording State
    @State private var isRecordingVoice: Bool = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var recordingTimer: Timer?
    @State private var isRecordingBlinking: Bool = false

    /// Horizontal drag offset for iMessage-style timestamp reveal.
    /// Negative value means the user dragged left (revealing timestamps on the right).
    @State private var dragOffset: CGFloat = 0

    /// Double-tapped message ID for bursting heart animation
    @State private var doubleTappedMessageId: String?

    /// Max leftward reveal distance (negative). Reveal + opacity share this constant.
    private let maxReveal = DS.Layout.chatTimestampRevealDistance

    init(viewModel: ChatViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Instagram-accurate Custom Navigation Bar
            chatCustomHeader

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
                        // Load more trigger at top — gated on hasMorePages
                        if viewModel.hasMorePages {
                            ProgressView()
                                .padding(.vertical, DS.Spacing.xs)
                                .task { await viewModel.loadMoreMessages() }
                        }

                        // Conversation Starter Header (Avatar lớn, bio, nút xem profile)
                        conversationStarterBanner

                        // Main message bubbles list
                        messageList

                        // Typing indicator when partner is typing
                        if viewModel.isPartnerTyping {
                            typingIndicatorBubble
                        }
                    }
                }
                .padding(.vertical, DS.Spacing.xs)
            }
            .defaultScrollAnchor(.bottom)
            .simultaneousGesture(timestampDragGesture)
            .scrollDismissesKeyboard(.interactively)

            if viewModel.isPartnerBlocked {
                blockedPartnerBanner
            } else {
                // Reply Preview Bar (when replying to a message)
                if let replyMessage = viewModel.replyingToMessage {
                    replyPreviewBar(replyMessage)
                }

                if isRecordingVoice {
                    voiceRecordingBar
                } else {
                    // Input bar
                    messageInputBar
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadMessages()
        }
        .onAppear {
            viewModel.onAppear()
            // Restore unsent text into the field when a send fails.
            viewModel.restoreDraft = { text in
                if messageText.isEmpty { messageText = text }
            }
        }
        .onDisappear {
            viewModel.onDisappear()
            cancelVoiceRecording()
            ChatAudioPlayer.shared.stop()
        }
        .onChange(of: photoPickerItem) { _, newItem in
            guard let newItem else { return }
            Task { await handlePickedMedia(newItem) }
        }
    }

    // MARK: - Custom Header (1:1 Instagram)

    private var chatCustomHeader: some View {
        HStack(spacing: DS.Spacing.xs) {
            // Back Button (24pt, 44x44pt hitbox)
            Button {
                HapticFeedbackSafe.impact(.light)
                AppRouter.shared.pop()
            } label: {
                InstagramIcon(.chevronLeft, size: 24, color: ColorTokens.textPrimary)
                    .frame(width: 44, height: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }

            // Recipient Info (Tappable -> opens Conversation Details)
            Button {
                HapticFeedbackSafe.impact(.light)
                AppRouter.shared.push(.conversationDetails(conversationId: viewModel.conversationId, recipient: viewModel.recipient))
            } label: {
                HStack(spacing: DS.Spacing.xs) {
                    // Avatar (36x36) with Active Online Indicator
                    ZStack(alignment: .bottomTrailing) {
                        LazyImage(url: viewModel.recipient?.avatarURL) { state in
                            if let image = state.image {
                                image.resizable().scaledToFill()
                            } else {
                                Circle().fill(ColorTokens.buttonSecondary)
                            }
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())

                        // Active Online Dot
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                            .overlay(Circle().stroke(Color(UIColor.systemBackground), lineWidth: 2))
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 4) {
                            Text(viewModel.recipient?.username ?? "User")
                                .font(DS.Font.headline)
                                .lineLimit(1)

                            if viewModel.recipient?.isVerified == true {
                                InstagramIcon(.verifiedBadge, size: 12, color: ColorTokens.accentPrimary)
                            }
                        }

                        Text("Đang hoạt động")
                            .font(DS.Font.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .tint(.primary)

            Spacer()

            // Trailing Actions: Voice & Video Call
            HStack(spacing: DS.Spacing.xxs) {
                // Audio Call (24pt, 44x44pt)
                Button {
                    handleCallAction(hasVideo: false)
                } label: {
                    InstagramIcon(.system(name: "phone"), size: 24, color: ColorTokens.textPrimary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }

                // Video Call (24pt, 44x44pt)
                Button {
                    handleCallAction(hasVideo: true)
                } label: {
                    InstagramIcon(.system(name: "video"), size: 24, color: ColorTokens.textPrimary)
                        .frame(width: 44, height: 44, alignment: .trailing)
                        .contentShape(Rectangle())
                }
            }
            .tint(.primary)
        }
        .padding(.horizontal, DS.Padding.horizontal)
        .frame(height: DS.Size.buttonDefaultHeight)
        .background(Color(UIColor.systemBackground))
        .overlay(alignment: .bottom) { Divider() }
    }

    private func handleCallAction(hasVideo: Bool) {
        HapticFeedbackSafe.impact(.medium)
        let targetId = viewModel.recipient?.id ?? viewModel.conversationId
        let targetName = viewModel.recipient?.username ?? "User"
        let avatarURL = viewModel.recipient?.avatarURL

        if CallService.shared.currentCallState.isActive {
            if let currentCall = CallService.shared.currentCall, currentCall.remoteUserId == targetId {
                // Same participant: reopen call screen
                AppRouter.shared.present(fullScreen: .call(userId: targetId, userName: targetName, avatarURL: avatarURL, hasVideo: currentCall.hasVideo))
            } else {
                // Different call in progress: warn user
                ToastManager.shared.warning(L10n.Call.alreadyInCall)
            }
            return
        }

        AppRouter.shared.present(fullScreen: .call(userId: targetId, userName: targetName, avatarURL: avatarURL, hasVideo: hasVideo))
    }

    // MARK: - Conversation Starter Banner

    private var conversationStarterBanner: some View {
        VStack(spacing: DS.Spacing.xs) {
            LazyImage(url: viewModel.recipient?.avatarURL) { state in
                if let image = state.image {
                    image.resizable().scaledToFill()
                } else {
                    Circle().fill(ColorTokens.buttonSecondary)
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(Circle())
            .padding(.top, DS.Spacing.md)

            Text(viewModel.recipient?.fullName.isEmpty == false ? (viewModel.recipient?.fullName ?? "") : (viewModel.recipient?.username ?? ""))
                .font(DS.Font.headline)

            Text("@\(viewModel.recipient?.username ?? "user") · Instagram")
                .font(DS.Font.subheadline)
                .foregroundStyle(.secondary)

            if let bio = viewModel.recipient?.bio, !bio.isEmpty {
                Text(bio)
                    .font(DS.Font.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Padding.content)
            }

            Button {
                HapticFeedbackSafe.impact(.light)
                if let user = viewModel.recipient {
                    AppRouter.shared.push(.userProfile(userId: user.id))
                }
            } label: {
                Text("Xem trang cá nhân")
                    .font(DS.Font.captionBold)
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(ColorTokens.buttonSecondary, in: Capsule())
            }
            .tint(.primary)
            .padding(.top, DS.Spacing.xxs)
            .padding(.bottom, DS.Spacing.md)
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
                if isMe {
                    if message.status == .failed {
                        Button {
                            HapticFeedbackSafe.impact(.medium)
                            Task { await viewModel.retryMessage(id: message.id) }
                        } label: {
                            InstagramIcon(.system(name: "exclamationmark.circle.fill"), size: 20, color: .red)
                        }
                    } else if message.status == .sending {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 16, height: 16)
                    }
                    Spacer(minLength: DS.Size.chatBubbleSpacer)
                }

                if !isMe {
                    // Reserve avatar width for consecutive-run alignment
                    Group {
                        if showAvatar {
                            LazyImage(url: message.sender.avatarURL) { state in
                                if let image = state.image {
                                    image.resizable().scaledToFill()
                                } else {
                                    Circle().fill(Color.gray.opacity(DS.Opacity.low))
                                }
                            }
                            .clipShape(Circle())
                        } else {
                            Color.clear
                        }
                    }
                    .frame(width: DS.Size.avatarSmall, height: DS.Size.avatarSmall)
                }

                VStack(alignment: isMe ? .trailing : .leading, spacing: DS.Spacing.xxxs) {
                    // Quoted reply snippet if this message is a reply
                    if let snippet = message.replyToSnippet {
                        HStack(spacing: DS.Spacing.xxs) {
                            Rectangle()
                                .fill(isMe ? Color.white.opacity(0.8) : ColorTokens.accentPrimary)
                                .frame(width: 2)
                            Text(snippet)
                                .font(DS.Font.caption2)
                                .foregroundStyle(isMe ? .white.opacity(0.8) : .secondary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, DS.Spacing.xs)
                        .padding(.vertical, 2)
                    }

                    ZStack(alignment: .center) {
                        bubbleContent(message.content, isMe: isMe)

                        // Popping Heart on Double Tap
                        if doubleTappedMessageId == message.id {
                            InstagramIcon(.system(name: "heart.fill"), size: 48, color: .red)
                                .shadow(radius: 4)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    // Tap gestures: Double-tap to Like, Single-tap to open media/audio, Long-press context menu
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        HapticFeedbackSafe.impact(.medium)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            doubleTappedMessageId = message.id
                        }
                        viewModel.addReaction(to: message.id, emoji: "❤️")
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 800_000_000)
                            withAnimation(.easeOut(duration: 0.2)) {
                                if doubleTappedMessageId == message.id {
                                    doubleTappedMessageId = nil
                                }
                            }
                        }
                    }
                    .onTapGesture(count: 1) {
                        handleBubbleSingleTap(for: message)
                    }
                    .contextMenu {
                        // Quick Emoji Reactions
                        ControlGroup {
                            Button("❤️") { viewModel.addReaction(to: message.id, emoji: "❤️") }
                            Button("😂") { viewModel.addReaction(to: message.id, emoji: "😂") }
                            Button("😮") { viewModel.addReaction(to: message.id, emoji: "😮") }
                            Button("😢") { viewModel.addReaction(to: message.id, emoji: "😢") }
                            Button("👏") { viewModel.addReaction(to: message.id, emoji: "👏") }
                            Button("🔥") { viewModel.addReaction(to: message.id, emoji: "🔥") }
                        }

                        Button {
                            HapticFeedbackSafe.impact(.light)
                            viewModel.replyingToMessage = message
                        } label: {
                            Label("Trả lời", systemImage: "arrowshape.turn.up.left")
                        }

                        if case .text(let t) = message.content {
                            Button {
                                HapticFeedbackSafe.impact(.light)
                                UIPasteboard.general.string = t
                                ToastManager.shared.info("Đã sao chép vào bộ nhớ tạm")
                            } label: {
                                Label("Sao chép", systemImage: "doc.on.doc")
                            }
                        }

                        if isMe {
                            Button(role: .destructive) {
                                HapticFeedbackSafe.impact(.medium)
                                viewModel.deleteMessage(id: message.id)
                            } label: {
                                Label("Thu hồi tin nhắn", systemImage: "trash")
                            }
                        }
                    }

                    // Reactions Pill Badge (nếu có biểu cảm)
                    if !message.reactions.isEmpty {
                        HStack(spacing: 2) {
                            ForEach(Array(Set(message.reactions.values)), id: \.self) { emoji in
                                Text(emoji)
                                    .font(.system(size: 11))
                            }
                            if message.reactions.count > 1 {
                                Text("\(message.reactions.count)")
                                    .font(DS.Font.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(UIColor.secondarySystemBackground), in: Capsule())
                        .overlay(Capsule().stroke(Color(UIColor.separator), lineWidth: 0.5))
                        .offset(y: -4)
                    }

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
                .foregroundStyle(isMe ? .white : .primary)
                .padding(.horizontal, DS.Spacing.formGap)
                .padding(.vertical, DS.Spacing.xs)
                .background(
                    isMe ? ColorTokens.brandBlue : ColorTokens.buttonSecondary,
                    in: RoundedRectangle(cornerRadius: DS.Radius.bubble)
                )

        case .image(let url):
            LazyImage(url: url) { state in
                if let image = state.image {
                    image.resizable().scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: DS.Radius.large)
                        .fill(ColorTokens.backgroundSubtler)
                }
            }
            .frame(width: DS.Size.chatImageBubble, height: DS.Size.chatImageBubble)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large))

        case .like:
            Text("❤️")
                .font(.system(size: DS.Size.chatLikeEmoji))

        case .audio(let url, let duration):
            let isThisAudioPlaying = audioPlayer.currentPlayingURL == url && audioPlayer.isPlaying
            let progress = audioPlayer.currentPlayingURL == url ? audioPlayer.playbackProgress : 0.0
            let displayDuration = (audioPlayer.currentPlayingURL == url && audioPlayer.duration > 0)
                ? (audioPlayer.isPlaying ? audioPlayer.currentTime : audioPlayer.duration)
                : duration

            HStack(spacing: DS.Spacing.xs) {
                Button {
                    HapticFeedbackSafe.impact(.light)
                    audioPlayer.togglePlayPause(url: url, expectedDuration: duration)
                } label: {
                    InstagramIcon(
                        .system(name: isThisAudioPlaying ? "pause.fill" : "play.fill"),
                        size: 14,
                        color: isMe ? .white : .primary
                    )
                    .frame(width: 24, height: 24)
                }

                // Audio Waveform Scrubber Track
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: DS.Spacing.xxxs)
                            .fill(isMe ? Color.white.opacity(DS.Opacity.overlay) : Color.gray.opacity(DS.Opacity.low))
                            .frame(height: DS.Stroke.thick)

                        RoundedRectangle(cornerRadius: DS.Spacing.xxxs)
                            .fill(isMe ? Color.white : ColorTokens.accentPrimary)
                            .frame(width: max(0, min(geo.size.width * CGFloat(progress), geo.size.width)), height: DS.Stroke.thick)
                    }
                    .frame(height: geo.size.height)
                }
                .frame(height: 14)

                Text(formatDuration(displayDuration))
                    .font(DS.Font.caption2)
                    .monospacedDigit()
            }
            .foregroundStyle(isMe ? .white : .primary)
            .padding(.horizontal, DS.Spacing.formGap)
            .padding(.vertical, DS.Padding.inputBar)
            .background(
                isMe ? ColorTokens.brandBlue : ColorTokens.buttonSecondary,
                in: RoundedRectangle(cornerRadius: DS.Radius.bubble)
            )
            .frame(width: DS.Size.chatAudioBubbleWidth)

        case .video(let url, thumbnailURL: let thumb):
            ZStack {
                if let thumbURL = thumb {
                    LazyImage(url: thumbURL) { state in
                        if let image = state.image {
                            image.resizable().scaledToFill()
                        } else {
                            ColorTokens.backgroundSubtler
                        }
                    }
                } else {
                    LazyImage(url: url) { state in
                        if let image = state.image {
                            image.resizable().scaledToFill()
                        } else {
                            ColorTokens.backgroundSubtler
                        }
                    }
                }
                InstagramIcon(.system(name: "play.circle.fill"), size: 36, color: .white.opacity(DS.Opacity.high))
            }
            .frame(width: DS.Size.chatVideoBubbleWidth, height: DS.Size.chatVideoBubbleHeight)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large))

        case .post(let postId):
            sharedContentCard(title: "Bài viết của Instagram", icon: "square.and.arrow.up", detailId: postId, isMe: isMe)

        case .story(let storyId):
            sharedContentCard(title: "Tin của bạn bè", icon: "circle.dashed", detailId: storyId, isMe: isMe)

        case .reel(let reelId):
            sharedContentCard(title: "Instagram Reel", icon: "play.square", detailId: reelId, isMe: isMe)
        }
    }

    // MARK: - Rich Shared Content Card

    private func sharedContentCard(title: String, icon: String, detailId: String, isMe: Bool) -> some View {
        Button {
            HapticFeedbackSafe.impact(.light)
            AppRouter.shared.push(.postDetail(postId: detailId))
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: DS.Spacing.xs) {
                    InstagramIcon(.system(name: icon), size: 14, color: isMe ? .white : .primary)
                    Text(title)
                        .font(DS.Font.captionBold)
                }
                .foregroundStyle(isMe ? .white : .primary)
                .padding(DS.Spacing.xs)

                ZStack {
                    ColorTokens.backgroundSecondary
                    InstagramIcon(.picture, size: 40, color: .secondary)
                }
                .frame(width: 200, height: 140)
                .clipped()

                Text("Nhấn để xem nội dung chia sẻ")
                    .font(DS.Font.caption2)
                    .foregroundStyle(isMe ? .white.opacity(0.8) : .secondary)
                    .padding(DS.Spacing.xs)
            }
            .background(
                isMe ? ColorTokens.brandBlue : ColorTokens.buttonSecondary,
                in: RoundedRectangle(cornerRadius: DS.Radius.large)
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large))
        }
        .tint(.primary)
    }

    // MARK: - Typing Indicator Bubble

    private var typingIndicatorBubble: some View {
        HStack(alignment: .bottom, spacing: DS.Spacing.xs) {
            LazyImage(url: viewModel.recipient?.avatarURL) { state in
                if let image = state.image {
                    image.resizable().scaledToFill()
                } else {
                    Circle().fill(Color.gray.opacity(DS.Opacity.low))
                }
            }
            .frame(width: DS.Size.avatarSmall, height: DS.Size.avatarSmall)
            .clipShape(Circle())

            HStack(spacing: 4) {
                TypingDot(delay: 0)
                TypingDot(delay: 0.2)
                TypingDot(delay: 0.4)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)
            .background(ColorTokens.buttonSecondary, in: RoundedRectangle(cornerRadius: DS.Radius.bubble))

            Spacer()
        }
        .padding(.horizontal, DS.Padding.content)
        .padding(.vertical, DS.Spacing.xxxs)
    }

    // MARK: - Reply Preview Bar

    private func replyPreviewBar(_ replyMessage: Message) -> some View {
        HStack(spacing: DS.Spacing.xs) {
            InstagramIcon(.system(name: "arrowshape.turn.up.left.fill"), size: 14, color: ColorTokens.accentPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Đang trả lời @\(replyMessage.sender.username)")
                    .font(DS.Font.caption2Bold)
                    .foregroundStyle(ColorTokens.accentPrimary)

                Text(snippetForMessage(replyMessage))
                    .font(DS.Font.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                HapticFeedbackSafe.impact(.light)
                viewModel.replyingToMessage = nil
            } label: {
                InstagramIcon(.system(name: "xmark.circle.fill"), size: 16, color: .secondary)
            }
        }
        .padding(.horizontal, DS.Padding.content)
        .padding(.vertical, DS.Spacing.xs)
        .background(ColorTokens.backgroundSecondary)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func snippetForMessage(_ msg: Message) -> String {
        switch msg.content {
        case .text(let t): return t
        case .image: return "Hình ảnh"
        case .video: return "Video"
        case .audio: return "Tin nhắn thoại"
        case .post: return "Bài viết chia sẻ"
        case .story: return "Tin chia sẻ"
        case .reel: return "Reel chia sẻ"
        case .like: return "❤️"
        }
    }

    // MARK: - Input Bar

    private var messageInputBar: some View {
        HStack(spacing: DS.Spacing.sm) {
            // Camera Button (Mở nhanh CreationHub)
            Button {
                HapticFeedbackSafe.impact(.light)
                AppRouter.shared.present(fullScreen: .creationHub(initialMode: .story))
            } label: {
                InstagramIcon(.camera, size: 20, color: ColorTokens.accentPrimary)
                    .frame(width: 36, height: 36)
                    .background(ColorTokens.backgroundSecondary, in: Circle())
            }
            .disabled(viewModel.isSending)

            // Text field in Capsule
            HStack(spacing: DS.Spacing.xs) {
                TextField(L10n.Chat.messagePlaceholder, text: $messageText)
                    .textFieldStyle(.plain)
                    .font(DS.Font.subheadline)
                    .focused($isInputFocused)

                if messageText.isEmpty {
                    // Mic button (Toggles 1-tap voice recording)
                    Button {
                        handleStartVoiceRecording()
                    } label: {
                        InstagramIcon(.system(name: "mic.fill"), size: 18, color: .secondary)
                    }
                    .disabled(viewModel.isSending)

                    // Photo/Video picker (matching both images and videos)
                    PhotosPicker(selection: $photoPickerItem, matching: .any(of: [.images, .videos])) {
                        InstagramIcon(.picture, size: 20, color: .secondary)
                    }
                    .disabled(viewModel.isSending)
                }
            }
            .padding(.horizontal, DS.Spacing.formGap)
            .padding(.vertical, DS.Spacing.xs)
            .background(ColorTokens.backgroundSecondary, in: Capsule())

            // Send or Like
            if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button {
                    HapticFeedbackSafe.impact(.light)
                    Task { await viewModel.sendLikeReaction() }
                } label: {
                    InstagramIcon(.like(), size: 22, color: ColorTokens.textPrimary)
                }
                .disabled(viewModel.isSending)
            } else {
                Button {
                    HapticFeedbackSafe.impact(.medium)
                    let text = messageText
                    messageText = ""
                    Task { await viewModel.sendTextMessage(text) }
                } label: {
                    InstagramIcon(.share2026(), size: 22, color: ColorTokens.accentPrimary)
                }
                .disabled(viewModel.isSending)
            }
        }
        .padding(.horizontal, DS.Padding.content)
        .padding(.vertical, DS.Spacing.xs)
        .overlay(alignment: .top) { Divider() }
    }

    // MARK: - Blocked Partner Banner

    private var blockedPartnerBanner: some View {
        VStack(spacing: DS.Spacing.xs) {
            Text("Bạn đã chặn tài khoản này")
                .font(DS.Font.subheadlineBold)
                .foregroundStyle(.secondary)

            Text("Bạn không thể gửi hoặc nhận tin nhắn từ @\(viewModel.recipient?.username ?? "người này") trừ khi bạn bỏ chặn họ.")
                .font(DS.Font.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Padding.content)

            Button {
                HapticFeedbackSafe.impact(.medium)
                viewModel.unblockPartner()
            } label: {
                Text("Bỏ chặn")
                    .font(DS.Font.captionBold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, DS.Spacing.lg)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(ColorTokens.brandBlue, in: Capsule())
            }
            .padding(.top, DS.Spacing.xxs)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.md)
        .background(Color(UIColor.secondarySystemBackground))
        .overlay(alignment: .top) { Divider() }
    }

    // MARK: - Voice Recording Bar (1-Tap Record & Trash Cancel)

    private var voiceRecordingBar: some View {
        HStack(spacing: DS.Spacing.sm) {
            // Cancel Recording (Trash Button)
            Button {
                HapticFeedbackSafe.impact(.medium)
                cancelVoiceRecording()
            } label: {
                InstagramIcon(.system(name: "trash.fill"), size: 22, color: .red)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }

            // Recording Status Container (Capsule)
            HStack(spacing: DS.Spacing.xs) {
                // Pulsing Red Recording Indicator
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .opacity(isRecordingBlinking ? 1.0 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                        value: isRecordingBlinking
                    )

                // Live Duration Counter
                Text(formatDuration(recordingDuration))
                    .font(DS.Font.subheadlineBold)
                    .monospacedDigit()
                    .foregroundStyle(.primary)

                Spacer()

                // Animated Sound Wave Visualizer
                VoiceWaveVisualizer(isAnimating: isRecordingVoice)
            }
            .padding(.horizontal, DS.Spacing.formGap)
            .padding(.vertical, DS.Spacing.xs)
            .background(ColorTokens.backgroundSecondary, in: Capsule())

            // Finish & Send Audio Message Button
            Button {
                HapticFeedbackSafe.impact(.medium)
                finishAndSendVoiceRecording()
            } label: {
                InstagramIcon(.system(name: "arrow.up.circle.fill"), size: 30, color: ColorTokens.accentPrimary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, DS.Padding.content)
        .padding(.vertical, DS.Spacing.xs)
        .overlay(alignment: .top) { Divider() }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Bubble Interaction

    private func handleBubbleSingleTap(for message: Message) {
        switch message.content {
        case .image(let url):
            HapticFeedbackSafe.impact(.light)
            AppRouter.shared.present(fullScreen: .chatMediaDetail(message: message, mediaURL: url, isVideo: false))
        case .video(let url, _):
            HapticFeedbackSafe.impact(.light)
            AppRouter.shared.present(fullScreen: .chatMediaDetail(message: message, mediaURL: url, isVideo: true))
        case .audio(let url, let duration):
            HapticFeedbackSafe.impact(.light)
            audioPlayer.togglePlayPause(url: url, expectedDuration: duration)
        default:
            break
        }
    }

    // MARK: - Voice Recording Methods

    private func handleStartVoiceRecording() {
        Task {
            do {
                _ = try await AudioRecordingService.shared.startRecording()
                await MainActor.run {
                    HapticFeedbackSafe.impact(.medium)
                    isRecordingVoice = true
                    recordingDuration = 0
                    isRecordingBlinking = true
                    startRecordingTimer()
                }
            } catch {
                await MainActor.run {
                    ToastManager.shared.error(error.localizedDescription)
                }
            }
        }
    }

    private func cancelVoiceRecording() {
        stopRecordingTimer()
        isRecordingVoice = false
        isRecordingBlinking = false
        recordingDuration = 0
        Task {
            await AudioRecordingService.shared.cancelRecording()
        }
    }

    private func finishAndSendVoiceRecording() {
        stopRecordingTimer()
        isRecordingVoice = false
        isRecordingBlinking = false
        Task {
            if let result = try? await AudioRecordingService.shared.stopRecording() {
                await viewModel.sendAudioMessage(url: result.url, duration: result.duration)
            }
        }
    }

    private func startRecordingTimer() {
        stopRecordingTimer()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                recordingDuration += 1
            }
        }
    }

    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    // MARK: - Media Picker Handling (Images & Videos)

    private func handlePickedMedia(_ item: PhotosPickerItem) async {
        defer { photoPickerItem = nil }
        let isVideo = item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) || $0.conforms(to: .video) })

        if isVideo {
            guard let data = try? await item.loadTransferable(type: Data.self) else { return }
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("vid_\(UUID().uuidString).mp4")
            guard (try? data.write(to: tempURL)) != nil else { return }

            // Extract half-res cached thumbnail in background
            let thumb = await VideoThumbnailGenerator.shared.thumbnail(for: tempURL)
            var thumbURL: URL? = nil
            if let thumb, let thumbData = thumb.jpegData(compressionQuality: 0.8) {
                let tURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("thumb_\(UUID().uuidString).jpg")
                try? thumbData.write(to: tURL)
                thumbURL = tURL
            }

            await viewModel.sendVideoMessage(url: tempURL, thumbnailURL: thumbURL)
        } else {
            guard let data = try? await item.loadTransferable(type: Data.self) else { return }
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("img_\(UUID().uuidString).jpg")
            guard (try? data.write(to: tempURL)) != nil else { return }
            await viewModel.sendImageMessage(url: tempURL)
        }
    }

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - VoiceWaveVisualizer

private struct VoiceWaveVisualizer: View {
    let isAnimating: Bool
    @State private var waveScales: [CGFloat] = [0.4, 0.7, 1.0, 0.6, 0.3, 0.8]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<waveScales.count, id: \.self) { idx in
                RoundedRectangle(cornerRadius: 1)
                    .fill(ColorTokens.accentPrimary)
                    .frame(width: 2.5, height: 16 * waveScales[idx])
                    .animation(
                        isAnimating
                            ? Animation.easeInOut(duration: 0.4)
                                .repeatForever(autoreverses: true)
                                .delay(Double(idx) * 0.08)
                            : .default,
                        value: waveScales[idx]
                    )
            }
        }
        .frame(height: 18)
        .onAppear {
            if isAnimating {
                waveScales = [0.9, 0.3, 0.6, 1.0, 0.7, 0.4]
            }
        }
    }
}

// MARK: - TypingDot Component

private struct TypingDot: View {
    let delay: Double
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(Color.secondary.opacity(0.8))
            .frame(width: 7, height: 7)
            .scaleEffect(isAnimating ? 1.0 : 0.5)
            .opacity(isAnimating ? 1.0 : 0.3)
            .animation(
                Animation.easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

//
//  ConversationDetailsView.swift
//  Instagram
//
//  Created by Antigravity on 15/10/26.
//

import SwiftUI
import NukeUI

// MARK: - ConversationDetailsView

struct ConversationDetailsView: View {

    let conversationId: String
    let recipient: User?

    @State private var isMutedMessages: Bool = false
    @State private var isMutedCalls: Bool = false
    @State private var showDeleteConfirmation: Bool = false

    private let messageRepository: MessageRepositoryProtocol = DIContainer.shared.resolve(MessageRepositoryProtocol.self)

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.md) {
                // Profile Card Header
                profileHeaderSection

                Divider().padding(.horizontal, DS.Padding.horizontal)

                // Notification Toggles
                notificationsSection

                Divider().padding(.horizontal, DS.Padding.horizontal)

                // Shared Media Preview
                sharedMediaSection

                Divider().padding(.horizontal, DS.Padding.horizontal)

                // Privacy & Actions
                actionsSection
            }
            .padding(.vertical, DS.Spacing.md)
        }
        .navigationTitle("Chi tiết")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    HapticFeedbackSafe.impact(.light)
                    AppRouter.shared.pop()
                } label: {
                    InstagramIcon(.chevronLeft, size: 20, color: Color.primary)
                }
            }
        }
        .confirmationDialog(
            "Xóa cuộc trò chuyện này?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Xóa cuộc trò chuyện", role: .destructive) {
                HapticFeedbackSafe.impact(.medium)
                Task {
                    try? await messageRepository.deleteConversation(id: conversationId)
                    AppRouter.shared.pop(count: 2)
                    ToastManager.shared.info("Đã xóa cuộc trò chuyện")
                }
            }
            Button("Hủy", role: .cancel) {}
        } message: {
            Text("Các tin nhắn trong cuộc trò chuyện này sẽ bị xóa khỏi hộp thư của bạn.")
        }
    }

    // MARK: - Profile Header

    private var profileHeaderSection: some View {
        VStack(spacing: DS.Spacing.xs) {
            LazyImage(url: recipient?.avatarURL) { state in
                if let image = state.image {
                    image.resizable().scaledToFill()
                } else {
                    Circle().fill(ColorTokens.buttonSecondary)
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())

            Text(recipient?.fullName.isEmpty == false ? (recipient?.fullName ?? "") : (recipient?.username ?? "User"))
                .font(DS.Font.title3)

            Text("@\(recipient?.username ?? "user")")
                .font(DS.Font.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: DS.Spacing.xs) {
                Button {
                    HapticFeedbackSafe.impact(.light)
                    if let user = recipient {
                        AppRouter.shared.push(.userProfile(userId: user.id))
                    }
                } label: {
                    VStack(spacing: 4) {
                        InstagramIcon(.profile(), size: 20, color: Color.primary)
                        Text("Trang cá nhân")
                            .font(DS.Font.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(ColorTokens.backgroundSecondary, in: RoundedRectangle(cornerRadius: DS.Radius.medium))
                }

                Button {
                    HapticFeedbackSafe.impact(.light)
                    ToastManager.shared.info("Tìm kiếm trong đoạn chat")
                } label: {
                    VStack(spacing: 4) {
                        InstagramIcon(.search(), size: 20, color: Color.primary)
                        Text("Tìm kiếm")
                            .font(DS.Font.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(ColorTokens.backgroundSecondary, in: RoundedRectangle(cornerRadius: DS.Radius.medium))
                }

                Button {
                    handleCallAction(hasVideo: false)
                } label: {
                    VStack(spacing: 4) {
                        InstagramIcon(.system(name: "phone"), size: 20, color: Color.primary)
                        Text("Âm thanh")
                            .font(DS.Font.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(ColorTokens.backgroundSecondary, in: RoundedRectangle(cornerRadius: DS.Radius.medium))
                }

                Button {
                    handleCallAction(hasVideo: true)
                } label: {
                    VStack(spacing: 4) {
                        InstagramIcon(.system(name: "video"), size: 20, color: Color.primary)
                        Text("Video")
                            .font(DS.Font.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(ColorTokens.backgroundSecondary, in: RoundedRectangle(cornerRadius: DS.Radius.medium))
                }
            }
            .tint(.primary)
            .padding(.top, DS.Spacing.xs)
        }
    }

    private func handleCallAction(hasVideo: Bool) {
        guard let user = recipient else { return }
        HapticFeedbackSafe.impact(.medium)

        if CallService.shared.currentCallState.isActive {
            if let currentCall = CallService.shared.currentCall, currentCall.remoteUserId == user.id {
                // Same participant: reopen call screen
                AppRouter.shared.present(fullScreen: .call(userId: user.id, userName: user.username, avatarURL: user.avatarURL, hasVideo: currentCall.hasVideo))
            } else {
                // Different call in progress: warn user
                ToastManager.shared.warning(L10n.Call.alreadyInCall)
            }
            return
        }

        AppRouter.shared.present(fullScreen: .call(userId: user.id, userName: user.username, avatarURL: user.avatarURL, hasVideo: hasVideo))
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(spacing: DS.Spacing.xs) {
            Toggle(isOn: $isMutedMessages) {
                Text("Tắt thông báo tin nhắn")
                    .font(DS.Font.body)
            }
            .tint(ColorTokens.brandBlue)
            .onChange(of: isMutedMessages) { _, newValue in
                Task { try? await messageRepository.muteConversation(id: conversationId, mute: newValue) }
            }

            Toggle(isOn: $isMutedCalls) {
                Text("Tắt thông báo cuộc gọi")
                    .font(DS.Font.body)
            }
            .tint(ColorTokens.brandBlue)
        }
        .padding(.horizontal, DS.Padding.horizontal)
    }

    // MARK: - Shared Media Section

    private var sharedMediaSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            HStack {
                Text("File phương tiện & liên kết")
                    .font(DS.Font.headline)
                Spacer()
                Text("Xem tất cả")
                    .font(DS.Font.caption)
                    .foregroundStyle(ColorTokens.accentPrimary)
            }

            // 3 preview thumbnails
            HStack(spacing: DS.Spacing.xxs) {
                ForEach(0..<3, id: \.self) { index in
                    ZStack {
                        ColorTokens.buttonSecondary
                        InstagramIcon(.picture, size: 24, color: .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
                }
            }
        }
        .padding(.horizontal, DS.Padding.horizontal)
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Button {
                HapticFeedbackSafe.impact(.light)
                ToastManager.shared.info("Đã hạn chế tài khoản")
            } label: {
                HStack {
                    Text("Hạn chế")
                    Spacer()
                }
                .foregroundStyle(Color.primary)
            }
            .padding(.vertical, DS.Spacing.xxs)

            Button {
                HapticFeedbackSafe.impact(.medium)
                if let user = recipient {
                    NotificationCenter.default.post(
                        name: .didUpdateBlockStatus,
                        object: nil,
                        userInfo: ["userId": user.id, "isBlocked": true]
                    )
                    ToastManager.shared.info("Đã chặn @\(user.username)")
                    AppRouter.shared.pop()
                }
            } label: {
                HStack {
                    Text("Chặn")
                    Spacer()
                }
                .foregroundStyle(.red)
            }
            .padding(.vertical, DS.Spacing.xxs)

            Button {
                HapticFeedbackSafe.impact(.light)
                ToastManager.shared.info("Đã mở mẫu báo cáo")
            } label: {
                HStack {
                    Text("Báo cáo cuộc trò chuyện")
                    Spacer()
                }
                .foregroundStyle(.red)
            }
            .padding(.vertical, DS.Spacing.xxs)

            Button {
                HapticFeedbackSafe.impact(.medium)
                showDeleteConfirmation = true
            } label: {
                HStack {
                    Text("Xóa cuộc trò chuyện")
                    Spacer()
                }
                .foregroundStyle(.red)
            }
            .padding(.vertical, DS.Spacing.xxs)

            Divider()
                .padding(.vertical, DS.Spacing.xs)

            // Test simulation triggers
            Button {
                HapticFeedbackSafe.selection()
                if let user = recipient {
                    Task {
                        await CallService.shared.simulateIncomingCall(
                            fromUserId: user.id,
                            name: user.username,
                            hasVideo: false
                        )
                    }
                }
            } label: {
                HStack {
                    InstagramIcon(.system(name: "phone.arrow.down.left"), size: 16, color: ColorTokens.accentPrimary)
                    Text("Mô phỏng cuộc gọi thoại đến")
                    Spacer()
                }
                .font(DS.Font.subheadline)
                .foregroundStyle(ColorTokens.accentPrimary)
            }
            .padding(.vertical, DS.Spacing.xxs)

            Button {
                HapticFeedbackSafe.selection()
                if let user = recipient {
                    Task {
                        await CallService.shared.simulateIncomingCall(
                            fromUserId: user.id,
                            name: user.username,
                            hasVideo: true
                        )
                    }
                }
            } label: {
                HStack {
                    InstagramIcon(.system(name: "video.badge.plus"), size: 16, color: ColorTokens.accentPrimary)
                    Text("Mô phỏng cuộc gọi video đến")
                    Spacer()
                }
                .font(DS.Font.subheadline)
                .foregroundStyle(ColorTokens.accentPrimary)
            }
            .padding(.vertical, DS.Spacing.xxs)
        }
        .padding(.horizontal, DS.Padding.horizontal)
    }
}

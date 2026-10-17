//
//  InAppIncomingCallBanner.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI
import Combine
import NukeUI

// MARK: - InAppIncomingCallBanner

/// Floating Glassmorphic heads-up notification appearing at the top of the screen
/// when an incoming audio/video call is ringing (`callState == .incomingRinging`).
struct InAppIncomingCallBanner: View {

    // MARK: - Props

    let call: ActiveCall?

    init(call: ActiveCall? = nil) {
        self.call = call
    }

    // MARK: - State

    @State private var fallbackCall: ActiveCall? = CallService.shared.currentCall
    @State private var isPulsing: Bool = false

    private var currentCall: ActiveCall? {
        call ?? fallbackCall
    }

    // MARK: - Body

    var body: some View {
        if let call = currentCall {
            bannerContent(call: call)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }
                .onReceive(CallService.shared.currentCallPublisher) { newCall in
                    self.fallbackCall = newCall
                }
        }
    }

    // MARK: - Banner Content

    private func bannerContent(call: ActiveCall) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            // Tappable Area: Expand FullScreen Call Screen
            Button {
                openFullScreenCall(call: call)
            } label: {
                HStack(spacing: DS.Spacing.sm) {
                    // Caller Avatar with pulsing halo ring
                    avatarWithHalo(call: call)

                    // Caller Information
                    VStack(alignment: .leading, spacing: 2) {
                        Text(call.remoteName)
                            .font(DS.Font.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(ColorTokens.textPrimary)
                            .lineLimit(1)

                        HStack(spacing: DS.Spacing.xxs) {
                            Circle()
                                .fill(ColorTokens.success)
                                .frame(width: 6, height: 6)

                            Text(call.hasVideo ? L10n.Call.incomingVideoCall : L10n.Call.incomingAudioCall)
                                .font(DS.Font.caption)
                                .foregroundStyle(ColorTokens.textSecondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: DS.Spacing.xs)
                }
            }
            .buttonStyle(.plain)

            // Action Buttons: Reject & Answer
            HStack(spacing: DS.Spacing.xs) {
                // Reject Button (Red)
                Button {
                    HapticFeedbackSafe.notification(.warning)
                    Task {
                        try? await CallService.shared.rejectIncomingCall()
                    }
                } label: {
                    InstagramIcon(.system(name: "phone.down.fill"), size: 16, color: .white)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(ColorTokens.destructive))
                        .shadow(color: ColorTokens.destructive.opacity(0.35), radius: 4)
                }
                .buttonStyle(.plain)
                .frame(minWidth: 44, minHeight: 44) // touch ergonomics

                // Answer Button (Green)
                Button {
                    HapticFeedbackSafe.notification(.success)
                    Task {
                        try? await CallService.shared.acceptIncomingCall()
                        openFullScreenCall(call: call)
                    }
                } label: {
                    InstagramIcon(
                        .system(name: call.hasVideo ? "video.fill" : "phone.fill"),
                        size: 16,
                        color: .white
                    )
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(ColorTokens.success))
                    .shadow(color: ColorTokens.success.opacity(0.35), radius: 4)
                }
                .buttonStyle(.plain)
                .frame(minWidth: 44, minHeight: 44) // touch ergonomics
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.large)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.large)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.18), radius: DS.Shadow.radius, y: 4)
        )
    }

    // MARK: - Avatar with Pulsing Halo

    private func avatarWithHalo(call: ActiveCall) -> some View {
        ZStack(alignment: .bottomTrailing) {
            // Pulsing aura ring
            Circle()
                .stroke(ColorTokens.success.opacity(isPulsing ? 0.6 : 0.15), lineWidth: 2)
                .scaleEffect(isPulsing ? 1.16 : 1.0)
                .frame(width: 40, height: 40)

            // Remote Avatar
            LazyImage(url: call.remoteAvatarURL ?? URL(string: "https://i.pravatar.cc/300?u=\(call.remoteUserId)")) { state in
                if let image = state.image {
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Circle().fill(ColorTokens.backgroundSecondary)
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1))

            // Media mode badge
            Circle()
                .fill(ColorTokens.success)
                .frame(width: 12, height: 12)
                .overlay {
                    InstagramIcon(
                        .system(name: call.hasVideo ? "video.fill" : "phone.fill"),
                        size: 7,
                        color: .white
                    )
                }
                .offset(x: 2, y: 2)
        }
    }

    // MARK: - Navigation

    private func openFullScreenCall(call: ActiveCall) {
        HapticFeedbackSafe.selection()
        AppRouter.shared.present(
            fullScreen: .call(
                userId: call.remoteUserId,
                userName: call.remoteName,
                avatarURL: call.remoteAvatarURL,
                hasVideo: call.hasVideo
            )
        )
    }
}

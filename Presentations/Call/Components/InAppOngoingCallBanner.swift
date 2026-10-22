//
//  InAppOngoingCallBanner.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI
import Combine
import NukeUI

// MARK: - InAppOngoingCallBanner

/// Floating Glassmorphic banner appearing at the top of the screen when an active call
/// is running in the background while the user navigates other parts of the app.
struct InAppOngoingCallBanner: View {

    // MARK: - Props

    let call: ActiveCall?
    let callState: CallState?

    init(call: ActiveCall? = nil, callState: CallState? = nil) {
        self.call = call
        self.callState = callState
    }

    // MARK: - State

    @State private var fallbackCall: ActiveCall? = CallService.shared.currentCall
    @State private var fallbackCallState: CallState = CallService.shared.currentCallState
    @State private var formattedDuration: String = "00:00"
    @State private var durationTask: Task<Void, Never>?

    private var currentActiveCall: ActiveCall? {
        call ?? fallbackCall
    }

    private var currentActiveCallState: CallState {
        callState ?? fallbackCallState
    }

    // MARK: - Body

    var body: some View {
        if let call = currentActiveCall, currentActiveCallState.isActive, currentActiveCallState != .incomingRinging {
            bannerContent(call: call)
                .onAppear {
                    if currentActiveCallState == .connected {
                        startDurationTimer(for: call)
                    }
                }
                .onDisappear {
                    durationTask?.cancel()
                    durationTask = nil
                }
                .onReceive(CallService.shared.currentCallPublisher) { newCall in
                    self.fallbackCall = newCall
                    if let newCall, currentActiveCallState == .connected {
                        startDurationTimer(for: newCall)
                    }
                }
                .onReceive(CallService.shared.callStatePublisher) { state in
                    self.fallbackCallState = state
                    if state == .connected, let call = currentActiveCall {
                        startDurationTimer(for: call)
                    } else if !state.isActive || state != .connected {
                        durationTask?.cancel()
                        durationTask = nil
                    }
                }
        }
    }

    // MARK: - Banner Content

    private func bannerContent(call: ActiveCall) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            // Tappable Area: Return to FullScreen Call
            Button {
                HapticFeedbackSafe.selection()
                AppRouter.shared.present(
                    fullScreen: .call(
                        userId: call.remoteUserId,
                        userName: call.remoteName,
                        avatarURL: call.remoteAvatarURL,
                        hasVideo: call.hasVideo
                    )
                )
            } label: {
                HStack(spacing: DS.Spacing.sm) {
                    // Caller Avatar with active pulse indicator
                    ZStack(alignment: .bottomTrailing) {
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

                        // Small media mode badge
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

                    // Info Column
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: DS.Spacing.xs) {
                            Text(call.remoteName)
                                .font(DS.Font.subheadlineBold)
                                .foregroundStyle(ColorTokens.textPrimary)
                                .lineLimit(1)

                            if currentActiveCallState == .connected {
                                // Real-time audio waveform equalizer mini bars
                                LiveAudioWaveformView(
                                    style: .bars,
                                    barColor: ColorTokens.success,
                                    levelPublisher: DefaultCallMediaPipeline.shared.audioLevelPublisher
                                )
                                .frame(width: 24, height: 14)
                            }
                        }

                        HStack(spacing: DS.Spacing.xs) {
                            Circle()
                                .fill(currentActiveCallState == .connected ? ColorTokens.success : ColorTokens.warning)
                                .frame(width: 6, height: 6)

                            Text(subtitleText(for: call))
                                .font(DS.Font.caption)
                                .foregroundStyle(ColorTokens.textSecondary)
                                .monospacedDigit()
                        }
                    }

                    Spacer(minLength: DS.Spacing.xs)
                }
            }
            .buttonStyle(.plain)

            // Fast Hangup Button
            Button {
                HapticFeedbackSafe.notification(.warning)
                Task {
                    try? await CallService.shared.hangup()
                }
            } label: {
                InstagramIcon(.system(name: "phone.down.fill"), size: 16, color: .white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(ColorTokens.destructive))
                    .shadow(color: ColorTokens.destructive.opacity(0.35), radius: 4)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44) // touch ergonomics
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

    // MARK: - Helpers

    private func subtitleText(for call: ActiveCall) -> String {
        switch currentActiveCallState {
        case .initiating, .ringing:
            return L10n.Call.calling
        case .connecting:
            return L10n.Call.connecting
        case .connected:
            return "\(formattedDuration) • \(L10n.Call.returnToCall)"
        case .reconnecting:
            return L10n.Call.reconnecting
        default:
            return L10n.Call.ongoingCall
        }
    }

    private func startDurationTimer(for call: ActiveCall) {
        durationTask?.cancel()
        let startDate = call.connectedAt ?? call.startedAt

        durationTask = Task {
            while !Task.isCancelled {
                let elapsed = Int(Date().timeIntervalSince(startDate))
                let seconds = max(0, elapsed % 60)
                let minutes = max(0, (elapsed % 3600) / 60)
                let hours = max(0, elapsed / 3600)

                await MainActor.run {
                    if hours > 0 {
                        self.formattedDuration = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
                    } else {
                        self.formattedDuration = String(format: "%02d:%02d", minutes, seconds)
                    }
                }

                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
}

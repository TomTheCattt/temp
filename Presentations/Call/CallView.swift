//
//  CallView.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI
import NukeUI

// MARK: - CallView

struct CallView: View {

    @State private var viewModel: CallViewModel

    init(viewModel: CallViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            // Background
            backgroundLayer

            // Content based on state
            VStack(spacing: 0) {
                Spacer()

                // User info
                callerInfo

                Spacer()

                // Status text
                statusText

                Spacer()

                // Controls
                controlButtons

                Spacer().frame(height: DS.Size.buttonLargeHeight)
            }
        }
        .ignoresSafeArea()
        .statusBarHidden()
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundLayer: some View {
        if viewModel.hasVideo && viewModel.callState == .connected {
            // Video call: remote video fills background
            remoteVideoPlaceholder
        } else {
            // Audio call: gradient background
            LinearGradient(
                colors: [ColorTokens.backgroundSecondary, Color(.systemGray4)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var remoteVideoPlaceholder: some View {
        ZStack {
            Color.black

            // In production: WebRTC remote video view here
            Text(L10n.Call.remoteVideo)
                .foregroundStyle(.white.opacity(DS.Opacity.hudBackground))
                .font(DS.Font.title3)

            // Local video (picture-in-picture)
            VStack {
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: DS.Radius.large)
                        .fill(Color(.systemGray3))
                        .frame(width: DS.Size.pipWidth, height: DS.Size.pipHeight)
                        .overlay {
                            Text(L10n.Call.you)
                                .font(DS.Font.caption)
                                .foregroundStyle(.white.opacity(DS.Opacity.overlay))
                        }
                        .padding(.trailing, DS.Spacing.md)
                        .padding(.top, DS.Spacing.pipTop)
                }
                Spacer()
            }
        }
    }

    // MARK: - Caller Info

    private var callerInfo: some View {
        VStack(spacing: DS.Spacing.sm) {
            // Avatar
            LazyImage(url: URL(string: "https://i.pravatar.cc/300?u=\(viewModel.remoteUserId)")) { state in
                if let image = state.image {
                    image.resizable()
                } else {
                    Circle().fill(Color(.systemGray4))
                }
            }
            .frame(width: DS.Size.avatarCall, height: DS.Size.avatarCall)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(DS.Opacity.hudBackground), lineWidth: DS.Stroke.medium)
            )
            .shadow(radius: DS.Shadow.radiusLarge)
            .opacity(viewModel.hasVideo && viewModel.callState == .connected ? 0 : 1)

            // Name
            Text(viewModel.remoteName)
                .font(DS.Font.title)
                .fontWeight(.semibold)
                .foregroundStyle(viewModel.hasVideo ? .white : .primary)

            // Call type
            if viewModel.callState != .connected {
                HStack(spacing: DS.Spacing.xxs) {
                    Image(systemName: viewModel.hasVideo ? "video.fill" : "phone.fill")
                        .font(DS.Font.caption)
                    Text(viewModel.hasVideo ? L10n.Call.videoCall : L10n.Call.audioCall)
                        .font(DS.Font.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Status

    private var statusText: some View {
        Group {
            switch viewModel.callState {
            case .idle:
                EmptyView()
            case .initiating:
                pulsingText(L10n.Call.calling)
            case .ringing:
                pulsingText(L10n.Call.ringing)
            case .incomingRinging:
                Text(L10n.Call.incoming)
                    .font(DS.Font.headline)
                    .foregroundStyle(.secondary)
            case .connecting:
                pulsingText(L10n.Call.connecting)
            case .connected:
                Text(viewModel.callDuration)
                    .font(DS.Font.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(viewModel.hasVideo ? .white : .primary)
                    .monospacedDigit()
            case .reconnecting:
                pulsingText(L10n.Call.reconnecting)
            case .ending:
                Text(L10n.Call.ending)
                    .foregroundStyle(.secondary)
            case .ended(let reason):
                Text(endReasonText(reason))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func pulsingText(_ text: String) -> some View {
        Text(text)
            .font(DS.Font.headline)
            .foregroundStyle(.secondary)
    }

    // MARK: - Controls

    @ViewBuilder
    private var controlButtons: some View {
        switch viewModel.callState {
        case .incomingRinging:
            incomingCallControls
        case .connected, .connecting, .ringing, .initiating, .reconnecting:
            activeCallControls
        default:
            EmptyView()
        }
    }

    private var incomingCallControls: some View {
        HStack(spacing: DS.Spacing.pipTop) {
            // Reject
            CallButton(
                icon: "phone.down.fill",
                color: ColorTokens.destructive,
                size: DS.Size.callButtonLarge
            ) {
                Task { await viewModel.reject() }
            }

            // Accept
            CallButton(
                icon: "phone.fill",
                color: ColorTokens.success,
                size: DS.Size.callButtonLarge
            ) {
                Task { await viewModel.accept() }
            }
        }
    }

    private var activeCallControls: some View {
        VStack(spacing: DS.Spacing.xl) {
            // Top row: mute, speaker, video toggle
            HStack(spacing: DS.Spacing.xxxl) {
                CallToggleButton(
                    icon: viewModel.isMuted ? "mic.slash.fill" : "mic.fill",
                    isActive: viewModel.isMuted,
                    label: L10n.Call.mute
                ) {
                    Task { await viewModel.toggleMute() }
                }

                CallToggleButton(
                    icon: viewModel.isSpeakerOn ? "speaker.wave.3.fill" : "speaker.fill",
                    isActive: viewModel.isSpeakerOn,
                    label: L10n.Call.speaker
                ) {
                    Task { await viewModel.toggleSpeaker() }
                }

                if viewModel.hasVideo {
                    CallToggleButton(
                        icon: "arrow.triangle.2.circlepath.camera",
                        isActive: false,
                        label: L10n.Call.flip
                    ) {
                        viewModel.flipCamera()
                    }
                }
            }

            // Hangup
            CallButton(
                icon: "phone.down.fill",
                color: ColorTokens.destructive,
                size: DS.Size.callButtonMedium
            ) {
                Task { await viewModel.hangup() }
            }
        }
    }

    // MARK: - Helpers

    private func endReasonText(_ reason: CallEndReason) -> String {
        switch reason {
        case .localHangup, .remoteHangup: return L10n.Call.ended
        case .rejected:   return L10n.Call.declined
        case .busy:       return L10n.Call.busy
        case .timeout:    return L10n.Call.noAnswer
        case .failed:     return L10n.Call.failed
        case .cancelled:  return L10n.Call.cancelled
        }
    }
}

// MARK: - CallButton

struct CallButton: View {
    let icon: String
    let color: Color
    var size: CGFloat = 60
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.38))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(Circle().fill(color))
                .shadow(color: color.opacity(DS.Opacity.muted), radius: DS.Shadow.radius, y: DS.Shadow.offsetY)
        }
    }
}

// MARK: - CallToggleButton

struct CallToggleButton: View {
    let icon: String
    let isActive: Bool
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DS.Spacing.iconGap) {
                Image(systemName: icon)
                    .font(.system(size: DS.FontSize.overlayCallGlyph))
                    .frame(width: DS.Size.buttonLargeHeight, height: DS.Size.buttonLargeHeight)
                    .foregroundStyle(isActive ? .white : .primary)
                    .background(
                        Circle().fill(isActive ? Color.white.opacity(DS.Opacity.hudBackground) : ColorTokens.buttonSecondary)
                    )

                Text(label)
                    .font(DS.Font.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

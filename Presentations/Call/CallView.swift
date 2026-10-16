//
//  CallView.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI
import NukeUI
import AVFoundation

// MARK: - CallView

struct CallView: View {

    @State private var viewModel: CallViewModel

    // Picture-in-Picture drag gesture state
    @State private var pipOffset: CGSize = CGSize(width: 20, height: 110)
    @State private var pipDragTranslation: CGSize = .zero
    @State private var isPipPositionInitialized = false

    init(viewModel: CallViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Layer (Audio ambient or Remote video)
                backgroundLayer(geometry: geometry)

                // Main Content Overlay
                VStack(spacing: 0) {
                    // Top Navigation & Minimize Bar
                    topBar

                    Spacer()

                    // Center: Caller Info & Status (Audio mode only)
                    if !viewModel.hasVideo || viewModel.callState != .connected {
                        callerInfoSection
                    }

                    Spacer()

                    // Bottom: In-Call Action Controls
                    controlButtonsSection
                        .padding(.bottom, DS.Spacing.xxl)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)

                // Video Call: Draggable Picture-in-Picture Local Camera Feed
                if viewModel.hasVideo && viewModel.callState == .connected {
                    pipLocalVideoView(geometry: geometry)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
            .clipped()
            .onAppear {
                initializePipPosition(in: geometry)
            }
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .task {
            await viewModel.onAppear()
        }
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss {
                AppRouter.shared.dismiss()
            }
        }
    }

    // MARK: - Top Navigation Bar

    private var topBar: some View {
        HStack {
            // Minimize / Back button
            Button {
                HapticFeedbackSafe.selection()
                viewModel.dismissCall()
            } label: {
                InstagramIcon(.chevronDown, size: DS.FontSize.overlayMedium, color: .white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.black.opacity(0.35)))
            }
            .frame(minWidth: 44, minHeight: 44) // touch ergonomics

            Spacer()

            // Video Mode: Top duration pill
            if viewModel.hasVideo && viewModel.callState == .connected {
                HStack(spacing: DS.Spacing.xs) {
                    Circle()
                        .fill(ColorTokens.success)
                        .frame(width: 8, height: 8)
                    Text(viewModel.callDuration)
                        .font(DS.Font.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.xs)
                .background(Capsule().fill(Color.black.opacity(0.45)))
            }

            Spacer()

            // Video Mode: Quick Flip Camera Button in Top Right
            if viewModel.hasVideo && viewModel.callState == .connected {
                Button {
                    viewModel.flipCamera()
                } label: {
                    InstagramIcon(.system(name: "arrow.triangle.2.circlepath.camera"), size: DS.FontSize.overlayMedium, color: .white)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Color.black.opacity(0.35)))
                }
                .frame(minWidth: 44, minHeight: 44)
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.top, DS.Spacing.pipTop)
    }

    // MARK: - Background Layer

    @ViewBuilder
    private func backgroundLayer(geometry: GeometryProxy) -> some View {
        Group {
            if viewModel.hasVideo && viewModel.callState == .connected {
                remoteVideoView(geometry: geometry)
            } else if viewModel.hasVideo && (viewModel.callState == .initiating || viewModel.callState == .ringing || viewModel.callState == .connecting) {
                // Show local camera stream as background preview during outgoing ringing
                SampleBufferVideoView(sampleBufferPublisher: viewModel.localSampleBufferPublisher)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            } else {
                ambientAudioBackground(geometry: geometry)
            }
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
        .clipped()
    }

    private func ambientAudioBackground(geometry: GeometryProxy) -> some View {
        ZStack {
            Color.black

            // Ambient blurred caller avatar
            LazyImage(url: viewModel.remoteAvatarURL ?? URL(string: "https://i.pravatar.cc/300?u=\(viewModel.remoteUserId)")) { state in
                if let image = state.image {
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    LinearGradient(
                        colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            .blur(radius: 50)
            .scaleEffect(1.25)
            .overlay(Color.black.opacity(0.62))
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
        .clipped()
    }

    private func remoteVideoView(geometry: GeometryProxy) -> some View {
        ZStack {
            Color.black

            // Hardware GPU accelerated zero-copy remote video stream
            SampleBufferVideoView(sampleBufferPublisher: viewModel.remoteSampleBufferPublisher)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
    }

    // MARK: - Center Caller Info & Pulse Waveform (Audio Mode)

    private var callerInfoSection: some View {
        VStack(spacing: DS.Spacing.md) {
            ZStack {
                // Expanding audio waveform aura rings reactive to microphone audio level
                LiveAudioWaveformView(
                    style: .rings(baseRadius: DS.Size.avatarCall),
                    barColor: Color.white.opacity(0.8),
                    levelPublisher: viewModel.audioLevelPublisher
                )

                // Caller Avatar
                LazyImage(url: viewModel.remoteAvatarURL ?? URL(string: "https://i.pravatar.cc/300?u=\(viewModel.remoteUserId)")) { state in
                    if let image = state.image {
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Circle().fill(Color(.systemGray4))
                    }
                }
                .frame(width: DS.Size.avatarCall, height: DS.Size.avatarCall)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.8), lineWidth: DS.Stroke.medium)
                )
                .shadow(color: Color.black.opacity(0.4), radius: DS.Shadow.radiusLarge, y: DS.Shadow.offsetY)
            }
            .frame(width: 140, height: 140)

            // Remote Name
            Text(viewModel.remoteName)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)

            // Status Subtitle
            statusSubtitle
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var statusSubtitle: some View {
        switch viewModel.callState {
        case .idle:
            Text(L10n.Call.calling)
                .font(DS.Font.headline)
                .foregroundStyle(.white.opacity(0.7))

        case .initiating:
            Text(L10n.Call.calling)
                .font(DS.Font.headline)
                .foregroundStyle(.white.opacity(0.75))

        case .ringing:
            Text(L10n.Call.ringing)
                .font(DS.Font.headline)
                .foregroundStyle(.white.opacity(0.75))

        case .incomingRinging:
            Text(viewModel.hasVideo ? L10n.Call.videoCall : L10n.Call.audioCall)
                .font(DS.Font.headline)
                .foregroundStyle(.white.opacity(0.8))

        case .connecting:
            Text(L10n.Call.connecting)
                .font(DS.Font.headline)
                .foregroundStyle(.white.opacity(0.75))

        case .connected:
            Text(viewModel.callDuration)
                .font(DS.Font.title3)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .monospacedDigit()

        case .reconnecting:
            Text(L10n.Call.reconnecting)
                .font(DS.Font.headline)
                .foregroundStyle(ColorTokens.warning)

        case .ending:
            Text(L10n.Call.ending)
                .font(DS.Font.headline)
                .foregroundStyle(.white.opacity(0.7))

        case .ended(let reason):
            Text(endReasonText(reason))
                .font(DS.Font.headline)
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    // MARK: - Picture-in-Picture Local Camera View

    private func pipLocalVideoView(geometry: GeometryProxy) -> some View {
        let pipWidth: CGFloat = DS.Size.pipWidth
        let pipHeight: CGFloat = DS.Size.pipHeight

        return ZStack {
            if viewModel.isCameraOff {
                // Camera Off Card
                RoundedRectangle(cornerRadius: DS.Radius.large)
                    .fill(Color(white: 0.2))
                    .overlay {
                        VStack(spacing: DS.Spacing.xxs) {
                            InstagramIcon(.system(name: "video.slash.fill"), size: 24, color: .white.opacity(0.8))
                            Text(L10n.Call.cameraOff)
                                .font(DS.Font.caption2)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
            } else {
                // Hardware / Mock AVCaptureSession Preview via SampleBufferVideoView
                SampleBufferVideoView(sampleBufferPublisher: viewModel.localSampleBufferPublisher)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large))
            }
        }
        .frame(width: pipWidth, height: pipHeight)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.large)
                .stroke(Color.white.opacity(0.9), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)
        .position(
            x: pipOffset.width + pipDragTranslation.width + pipWidth / 2,
            y: pipOffset.height + pipDragTranslation.height + pipHeight / 2
        )
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    pipDragTranslation = value.translation
                }
                .onEnded { value in
                    snapPipToCorner(translation: value.translation, in: geometry)
                }
        )
        .highPriorityGesture(
            TapGesture().onEnded {
                viewModel.flipCamera()
            }
        )
    }

    private func initializePipPosition(in geometry: GeometryProxy) {
        guard !isPipPositionInitialized, geometry.size.width > 0 else { return }
        isPipPositionInitialized = true
        // Default: Top right corner, placed below TopBar (targetY: 110) to never overlap the Flip Camera button
        let targetX = max(16, geometry.size.width - DS.Size.pipWidth - 16)
        let targetY: CGFloat = 110
        pipOffset = CGSize(width: targetX, height: targetY)
    }

    private func snapPipToCorner(translation: CGSize, in geometry: GeometryProxy) {
        let pipWidth: CGFloat = DS.Size.pipWidth
        let pipHeight: CGFloat = DS.Size.pipHeight
        let margin: CGFloat = 16
        let topSafe: CGFloat = 110
        let bottomSafe: CGFloat = geometry.size.height - pipHeight - 160

        let currentX = pipOffset.width + translation.width
        let currentY = pipOffset.height + translation.height

        let targetX: CGFloat = (currentX + pipWidth / 2 < geometry.size.width / 2) ? margin : (geometry.size.width - pipWidth - margin)
        let targetY: CGFloat = min(max(currentY, topSafe), bottomSafe)

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            pipOffset = CGSize(width: targetX, height: targetY)
            pipDragTranslation = .zero
        }
    }

    // MARK: - Control Buttons Section

    @ViewBuilder
    private var controlButtonsSection: some View {
        switch viewModel.callState {
        case .incomingRinging:
            incomingControls
                .frame(maxWidth: .infinity)

        case .ended:
            // Call already finished; hide all action controls to prevent accidental taps
            EmptyView()

        default:
            activeCallControls
                .frame(maxWidth: .infinity)
        }
    }

    private var incomingControls: some View {
        HStack(spacing: DS.Spacing.xxxl) {
            // Reject Button (Red)
            CallButton(
                icon: "phone.down.fill",
                color: ColorTokens.destructive,
                size: DS.Size.callButtonLarge
            ) {
                Task { await viewModel.reject() }
            }

            // Accept Button (Green)
            CallButton(
                icon: "phone.fill",
                color: ColorTokens.success,
                size: DS.Size.callButtonLarge
            ) {
                Task { await viewModel.accept() }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var activeCallControls: some View {
        VStack(spacing: DS.Spacing.xl) {
            // Action options row
            HStack(spacing: DS.Spacing.xl) {
                // Mute Toggle
                CallGlassButton(
                    icon: viewModel.isMuted ? "mic.slash.fill" : "mic.fill",
                    label: L10n.Call.mute,
                    isActive: viewModel.isMuted
                ) {
                    viewModel.toggleMute()
                }

                // Speaker Toggle
                CallGlassButton(
                    icon: viewModel.isSpeakerOn ? "speaker.wave.3.fill" : "speaker.fill",
                    label: L10n.Call.speaker,
                    isActive: viewModel.isSpeakerOn
                ) {
                    viewModel.toggleSpeaker()
                }

                if viewModel.hasVideo {
                    // Camera Toggle (On/Off)
                    CallGlassButton(
                        icon: viewModel.isCameraOff ? "video.slash.fill" : "video.fill",
                        label: L10n.Call.camera,
                        isActive: viewModel.isCameraOff
                    ) {
                        viewModel.toggleCamera()
                    }

                    // Flip Camera
                    CallGlassButton(
                        icon: "arrow.triangle.2.circlepath.camera",
                        label: L10n.Call.flip,
                        isActive: false
                    ) {
                        viewModel.flipCamera()
                    }
                } else {
                    // Upgrade Audio to Video Call
                    CallGlassButton(
                        icon: "video.fill",
                        label: L10n.Call.video,
                        isActive: false
                    ) {
                        viewModel.upgradeToVideo()
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // End Call Hangup Button (Red)
            CallButton(
                icon: "phone.down.fill",
                color: ColorTokens.destructive,
                size: DS.Size.callButtonMedium
            ) {
                Task { await viewModel.hangup() }
            }
        }
        .frame(maxWidth: .infinity)
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

// MARK: - CallGlassButton

private struct CallGlassButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DS.Spacing.xs) {
                InstagramIcon(.system(name: icon), size: DS.FontSize.overlayCallGlyph, color: isActive ? .black : .white)
                    .frame(width: 52, height: 52)
                    .background(
                        Circle().fill(isActive ? Color.white : Color.white.opacity(0.2))
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 4)

                Text(label)
                    .font(DS.Font.caption2)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(minWidth: 44, minHeight: 44) // touch ergonomics
    }
}

// MARK: - CallButton

struct CallButton: View {
    let icon: String
    let color: Color
    var size: CGFloat = 65
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            InstagramIcon(.system(name: icon), size: size * 0.38, color: .white)
                .frame(width: size, height: size)
                .background(Circle().fill(color))
                .shadow(color: color.opacity(0.4), radius: DS.Shadow.radiusLarge, y: 3)
        }
        .frame(minWidth: 44, minHeight: 44) // touch ergonomics
    }
}

// MARK: - CallToggleButton (Backwards Compatibility)

struct CallToggleButton: View {
    let icon: String
    let isActive: Bool
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DS.Spacing.iconGap) {
                InstagramIcon(.system(name: icon), size: DS.FontSize.overlayCallGlyph, color: isActive ? .black : .white)
                    .frame(width: DS.Size.buttonLargeHeight, height: DS.Size.buttonLargeHeight)
                    .background(
                        Circle().fill(isActive ? Color.white : Color.white.opacity(0.2))
                    )

                Text(label)
                    .font(DS.Font.caption2)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(minWidth: 44, minHeight: 44)
    }
}

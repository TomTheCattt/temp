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
    @State private var pipOffset: CGSize = CGSize(width: 20, height: 70)
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

                // Video Call: Draggable Picture-in-Picture Local Camera Feed
                if viewModel.hasVideo && viewModel.callState == .connected {
                    pipLocalVideoView(geometry: geometry)
                }
            }
            .onAppear {
                initializePipPosition(in: geometry)
            }
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .task {
            await viewModel.onAppear()
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
                Image(systemName: "chevron.down")
                    .font(.system(size: DS.FontSize.overlayMedium, weight: .bold))
                    .foregroundStyle(.white)
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
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.system(size: DS.FontSize.overlayMedium, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Color.black.opacity(0.35)))
                }
                .frame(minWidth: 44, minHeight: 44)
            } else {
                Spacer().frame(width: 44)
            }
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.top, DS.Spacing.pipTop)
    }

    // MARK: - Background Layer

    @ViewBuilder
    private func backgroundLayer(geometry: GeometryProxy) -> some View {
        if viewModel.hasVideo && viewModel.callState == .connected {
            remoteVideoView(geometry: geometry)
        } else {
            ambientAudioBackground
        }
    }

    private var ambientAudioBackground: some View {
        ZStack {
            Color.black

            // Ambient blurred caller avatar
            LazyImage(url: URL(string: "https://i.pravatar.cc/300?u=\(viewModel.remoteUserId)")) { state in
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
            .blur(radius: 50)
            .scaleEffect(1.25)
            .overlay(Color.black.opacity(0.62))
        }
    }

    private func remoteVideoView(geometry: GeometryProxy) -> some View {
        ZStack {
            Color.black

            // High-fidelity dynamic video stream simulation
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.12, blue: 0.18), Color(red: 0.05, green: 0.06, blue: 0.09)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Remote partner avatar / stream canvas
            VStack(spacing: DS.Spacing.md) {
                LazyImage(url: URL(string: "https://i.pravatar.cc/300?u=\(viewModel.remoteUserId)")) { state in
                    if let image = state.image {
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Circle().fill(Color(.systemGray4))
                    }
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 2))
                .shadow(radius: 12)

                Text(viewModel.remoteName)
                    .font(DS.Font.headline)
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Center Caller Info & Pulse Rings (Audio Mode)

    private var callerInfoSection: some View {
        VStack(spacing: DS.Spacing.md) {
            ZStack {
                // Expanding concentric pulse rings when calling or ringing
                if viewModel.callState == .initiating || viewModel.callState == .ringing {
                    PulseRingsView()
                }

                // Caller Avatar
                LazyImage(url: URL(string: "https://i.pravatar.cc/300?u=\(viewModel.remoteUserId)")) { state in
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
                            Image(systemName: "video.slash.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.white.opacity(0.8))
                            Text("Tắt camera")
                                .font(DS.Font.caption2)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
            } else {
                // Hardware / Mock AVCaptureSession Preview
                CameraPreviewView(
                    session: CameraService.shared.session,
                    isHardwareAvailable: CameraService.shared.isHardwareAvailable,
                    isFrontFacing: viewModel.isFrontCamera
                )
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
            DragGesture()
                .onChanged { value in
                    pipDragTranslation = value.translation
                }
                .onEnded { value in
                    snapPipToCorner(translation: value.translation, in: geometry)
                }
        )
        .onTapGesture {
            viewModel.flipCamera()
        }
    }

    private func initializePipPosition(in geometry: GeometryProxy) {
        guard !isPipPositionInitialized else { return }
        isPipPositionInitialized = true
        // Default: Top right corner
        let targetX = geometry.size.width - DS.Size.pipWidth - 16
        let targetY: CGFloat = 80
        pipOffset = CGSize(width: targetX, height: targetY)
    }

    private func snapPipToCorner(translation: CGSize, in geometry: GeometryProxy) {
        let pipWidth: CGFloat = DS.Size.pipWidth
        let pipHeight: CGFloat = DS.Size.pipHeight
        let margin: CGFloat = 16
        let topSafe: CGFloat = 80
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

        default:
            activeCallControls
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
                    Task { await viewModel.toggleMute() }
                }

                // Speaker Toggle
                CallGlassButton(
                    icon: viewModel.isSpeakerOn ? "speaker.wave.3.fill" : "speaker.fill",
                    label: L10n.Call.speaker,
                    isActive: viewModel.isSpeakerOn
                ) {
                    Task { await viewModel.toggleSpeaker() }
                }

                if viewModel.hasVideo {
                    // Camera Toggle (On/Off)
                    CallGlassButton(
                        icon: viewModel.isCameraOff ? "video.slash.fill" : "video.fill",
                        label: "Camera",
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
                        label: "Video",
                        isActive: false
                    ) {
                        viewModel.upgradeToVideo()
                    }
                }
            }

            // End Call Hangup Button (Red)
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

// MARK: - Pulse Rings View

private struct PulseRingsView: View {
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
                    .frame(width: DS.Size.avatarCall + CGFloat(index * 36), height: DS.Size.avatarCall + CGFloat(index * 36))
                    .scaleEffect(isPulsing ? 1.35 : 0.95)
                    .opacity(isPulsing ? 0.0 : 0.65)
                    .animation(
                        .easeInOut(duration: 1.8)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.45),
                        value: isPulsing
                    )
            }
        }
        .onAppear {
            isPulsing = true
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
                Image(systemName: icon)
                    .font(.system(size: DS.FontSize.overlayCallGlyph))
                    .foregroundStyle(isActive ? .black : .white)
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
            Image(systemName: icon)
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(.white)
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
                Image(systemName: icon)
                    .font(.system(size: DS.FontSize.overlayCallGlyph))
                    .frame(width: DS.Size.buttonLargeHeight, height: DS.Size.buttonLargeHeight)
                    .foregroundStyle(isActive ? .black : .white)
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

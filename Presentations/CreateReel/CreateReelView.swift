//
//  CreateReelView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI
import PhotosUI
import AVKit

// MARK: - CreateReelView

struct CreateReelView: View {

    @State private var viewModel: CreateReelViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: CreateReelViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            if viewModel.isShowingEditor {
                editorScreen
            } else {
                captureScreen
            }
        }
        .task {
            await viewModel.setupCamera()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
        .onChange(of: viewModel.isPublished) { _, published in
            if published { dismiss() }
        }
        .onChange(of: viewModel.videoPickerItem) { _, _ in
            Task { await viewModel.loadVideoFromPicker() }
        }
    }

    // MARK: - Capture Screen

    private var captureScreen: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Live Camera Viewfinder or Simulator Fallback
            if viewModel.cameraService.isHardwareAvailable {
                CameraPreviewView(
                    session: viewModel.cameraService.session,
                    isHardwareAvailable: true
                )
                .ignoresSafeArea()
            } else {
                simulatorMockPreview
            }

            // Controls
            VStack {
                // Top bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.35), in: Circle())
                    }

                    Spacer()

                    // Audio picker
                    Button(action: {
                        HUDManager.shared.showInfo(L10n.CreateReel.addAudio)
                    }) {
                        HStack(spacing: DS.Spacing.xxs) {
                            Image(systemName: "music.note")
                            Text(L10n.CreateReel.addAudio)
                        }
                        .font(DS.Font.captionBold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, DS.Spacing.sm)
                        .padding(.vertical, DS.Spacing.iconGap)
                        .background(Color.black.opacity(0.4), in: Capsule())
                    }

                    Spacer()

                    // Settings / Flash
                    Button(action: {
                        viewModel.toggleFlash()
                    }) {
                        Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash")
                            .font(DS.Font.title3)
                            .foregroundStyle(viewModel.isFlashOn ? .yellow : .white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.35), in: Circle())
                    }
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.top, DS.Spacing.md)

                Spacer()

                // Right side tools
                HStack {
                    Spacer()
                    VStack(spacing: DS.Spacing.lg) {
                        toolButton(icon: "camera.rotate", label: "Flip") {
                            viewModel.toggleCamera()
                        }
                        toolButton(icon: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash", label: "Flash") {
                            viewModel.toggleFlash()
                        }
                        toolButton(icon: "timer", label: "Timer") {
                            HUDManager.shared.showInfo("Hẹn giờ đếm ngược: 3s")
                        }
                        toolButton(icon: "sparkles", label: "Effects") {
                            HUDManager.shared.showInfo("Hiệu ứng AR đang tải...")
                        }
                        toolButton(icon: "square.grid.2x2", label: "Layout") {
                            HUDManager.shared.showInfo("Bố cục chia màn hình")
                        }
                    }
                    .padding(.trailing, DS.Spacing.md)
                }

                Spacer()

                // Bottom: duration + capture + gallery
                VStack(spacing: DS.Spacing.md) {
                    // Duration selector
                    HStack(spacing: DS.Spacing.md) {
                        durationChip("15s", isSelected: viewModel.selectedDuration == "15s") {
                            viewModel.selectedDuration = "15s"
                        }
                        durationChip("30s", isSelected: viewModel.selectedDuration == "30s") {
                            viewModel.selectedDuration = "30s"
                        }
                        durationChip("60s", isSelected: viewModel.selectedDuration == "60s") {
                            viewModel.selectedDuration = "60s"
                        }
                        durationChip("90s", isSelected: viewModel.selectedDuration == "90s") {
                            viewModel.selectedDuration = "90s"
                        }
                    }

                    // Capture + gallery
                    HStack(spacing: DS.Spacing.xxxl) {
                        // Gallery
                        PhotosPicker(
                            selection: $viewModel.videoPickerItem,
                            matching: .videos
                        ) {
                            RoundedRectangle(cornerRadius: DS.Radius.thumbnailCard)
                                .fill(Color.white.opacity(0.2))
                                .frame(width: DS.Size.buttonCompactHeight, height: DS.Size.buttonCompactHeight)
                                .overlay {
                                    Image(systemName: "photo")
                                        .font(DS.Font.caption)
                                        .foregroundStyle(.white)
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: DS.Radius.thumbnailCard)
                                        .stroke(Color.white, lineWidth: 1.5)
                                )
                        }

                        // Record button
                        Button(action: {
                            if viewModel.isRecording {
                                viewModel.stopRecording()
                            } else {
                                viewModel.startRecording()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .stroke(Color.white, lineWidth: DS.Stroke.extraThick)
                                    .frame(width: DS.Size.captureButton, height: DS.Size.captureButton)
                                Circle()
                                    .fill(viewModel.isRecording ? ColorTokens.destructive : ColorTokens.destructive.opacity(DS.Opacity.nearOpaque))
                                    .frame(width: viewModel.isRecording ? DS.Size.avatarCompact : DS.Size.captureButtonInner, height: viewModel.isRecording ? DS.Size.avatarCompact : DS.Size.captureButtonInner)
                                    .clipShape(viewModel.isRecording ? AnyShape(RoundedRectangle(cornerRadius: DS.Radius.medium)) : AnyShape(Circle()))
                            }
                        }

                        // Placeholder for balance
                        Color.clear.frame(width: DS.Size.buttonCompactHeight, height: DS.Size.buttonCompactHeight)
                    }
                }
                .padding(.bottom, DS.Spacing.mediaControlsBottom)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Simulator Mock Preview

    private var simulatorMockPreview: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemGray6), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: DS.Spacing.xs) {
                Image(systemName: "video.fill")
                    .font(.system(size: DS.Spacing.xxxl))
                    .foregroundStyle(.white.opacity(DS.Opacity.overlay))
                Text("Reel Camera Viewfinder")
                    .font(DS.Font.headline)
                    .foregroundStyle(.white)
                Text("Simulator Mock Mode: Nhấn nút tròn đỏ để quay")
                    .font(DS.Font.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    // MARK: - Editor Screen

    private var editorScreen: some View {
        VStack(spacing: 0) {
            // Video preview
            ZStack {
                Color.black
                    .frame(height: DS.Size.mediaEditorPreviewHeight)

                if let url = viewModel.capturedVideoURL {
                    VideoPlayer(player: AVPlayer(url: url))
                        .frame(height: DS.Size.mediaEditorPreviewHeight)
                } else {
                    VStack(spacing: DS.Spacing.xs) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: DS.Size.iconHero))
                            .foregroundStyle(.white.opacity(DS.Opacity.medium))
                        Text(L10n.CreateReel.videoPreview)
                            .font(DS.Font.caption)
                            .foregroundStyle(.white.opacity(DS.Opacity.overlay))
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large))
            .padding()

            // Caption
            TextField(L10n.CreatePost.captionPlaceholder, text: $viewModel.caption, axis: .vertical)
                .font(DS.Font.subheadline)
                .lineLimit(3...5)
                .padding(.horizontal)

            Spacer()
        }
        .dismissKeyboardOnTap()
        .navigationTitle(L10n.CreateReel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    viewModel.isShowingEditor = false
                    viewModel.selectedVideoData = nil
                    viewModel.capturedVideoURL = nil
                }) {
                    Image(systemName: "chevron.left")
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.Common.share) {
                    Task { await viewModel.publish() }
                }
                .fontWeight(.semibold)
                .foregroundStyle(ColorTokens.accentPrimary)
                .disabled(viewModel.isPublishing)
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func toolButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: DS.Spacing.xxs) {
                Image(systemName: icon)
                    .font(DS.Font.title3)
                Text(label)
                    .font(DS.Font.caption2)
            }
            .foregroundStyle(.white)
        }
    }

    @ViewBuilder
    private func durationChip(_ text: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(DS.Font.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundStyle(isSelected ? .white : .white.opacity(DS.Opacity.medium))
                .padding(.horizontal, DS.Spacing.sm)
                .padding(.vertical, DS.Spacing.xxs)
                .background(
                    isSelected ? Color.white.opacity(DS.Opacity.placeholder) : Color.black.opacity(0.3),
                    in: Capsule()
                )
        }
    }
}

// MARK: - AnyShape

/// Type-erased Shape for conditional clipShape.
struct AnyShape: Shape {
    private let _path: @Sendable (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        _path = { rect in shape.path(in: rect) }
    }

    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

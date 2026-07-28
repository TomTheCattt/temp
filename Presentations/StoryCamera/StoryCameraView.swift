//
//  StoryCameraView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI

// MARK: - StoryCameraView

struct StoryCameraView: View {

    @State private var viewModel: StoryCameraViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: StoryCameraViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.isShowingPreview {
                previewScreen
            } else {
                cameraScreen
            }
        }
        .statusBarHidden()
        .task {
            await viewModel.checkPermissions()
        }
        .onChange(of: viewModel.isPublished) { _, published in
            if published { dismiss() }
        }
    }

    // MARK: - Camera Screen

    private var cameraScreen: some View {
        ZStack {
            if viewModel.cameraPermissionGranted {
                cameraPreview
            } else {
                permissionDeniedView
            }

            VStack {
                topBar
                Spacer()
                bottomControls
            }
        }
    }

    // MARK: - Camera Preview (Placeholder)

    private var cameraPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DS.Radius.large)
                .fill(Color.gray.opacity(DS.Opacity.low))
                .padding(.horizontal, DS.Spacing.xxxs)
                .padding(.vertical, DS.Spacing.modalTop + DS.Spacing.sm)
                .overlay {
                    VStack(spacing: DS.Spacing.xs) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: DS.Spacing.xxxl))
                        Text("Camera Preview")
                            .font(DS.Font.caption)
                    }
                    .foregroundStyle(.white.opacity(DS.Opacity.overlay))
                }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundStyle(.white)
            }

            Spacer()

            Button(action: { viewModel.toggleFlash() }) {
                Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash")
                    .font(DS.Font.title3)
                    .foregroundStyle(.white)
            }

            Button(action: {}) {
                Image(systemName: "gearshape")
                    .font(DS.Font.title3)
                    .foregroundStyle(.white)
            }
            .padding(.leading, DS.Spacing.md)
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.top, DS.Spacing.md)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: DS.Spacing.lg) {
            // Mode selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Spacing.md) {
                    ForEach(StoryCameraMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue)
                            .font(DS.Font.caption)
                            .fontWeight(viewModel.mode == mode ? .bold : .regular)
                            .foregroundStyle(viewModel.mode == mode ? .white : .white.opacity(DS.Opacity.medium))
                            .onTapGesture { viewModel.mode = mode }
                    }
                }
                .padding(.horizontal)
            }

            // Capture button + controls
            HStack(spacing: DS.Spacing.xxxl) {
                // Gallery button
                Button(action: {}) {
                    RoundedRectangle(cornerRadius: DS.Radius.thumbnailCard)
                        .fill(Color.gray.opacity(DS.Opacity.overlay))
                        .frame(width: DS.Size.buttonCompactHeight, height: DS.Size.buttonCompactHeight)
                        .overlay {
                            Image(systemName: "photo")
                                .font(DS.Font.caption)
                                .foregroundStyle(.white)
                        }
                }

                // Capture button
                Button(action: {
                    if viewModel.mode == .hands_free || viewModel.isRecording {
                        viewModel.stopRecording()
                    } else if viewModel.mode == .normal {
                        viewModel.capturePhoto()
                    } else {
                        viewModel.startRecording()
                    }
                }) {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: DS.Stroke.extraThick)
                            .frame(width: DS.Size.captureButton, height: DS.Size.captureButton)

                        Circle()
                            .fill(viewModel.isRecording ? ColorTokens.destructive : Color.white)
                            .frame(width: DS.Size.captureButtonInner, height: DS.Size.captureButtonInner)
                    }
                }

                // Flip camera
                Button(action: { viewModel.toggleCamera() }) {
                    Image(systemName: "camera.rotate")
                        .font(DS.Font.title3)
                        .foregroundStyle(.white)
                        .frame(width: DS.Size.buttonCompactHeight, height: DS.Size.buttonCompactHeight)
                }
            }
            .padding(.bottom, 30)
        }
    }

    // MARK: - Preview Screen

    private var previewScreen: some View {
        ZStack {
            // Preview of captured media
            if viewModel.capturedImageData != nil {
                RoundedRectangle(cornerRadius: DS.Radius.large)
                    .fill(Color.gray.opacity(0.4))
                    .padding(DS.Spacing.xxxs)
                    .overlay {
                        Text("Captured Photo")
                            .foregroundStyle(.white.opacity(DS.Opacity.medium))
                    }
            } else if viewModel.capturedVideoURL != nil {
                RoundedRectangle(cornerRadius: DS.Radius.large)
                    .fill(Color.gray.opacity(0.4))
                    .padding(DS.Spacing.xxxs)
                    .overlay {
                        VStack {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: DS.Size.iconHero))
                            Text("Captured Video")
                        }
                        .foregroundStyle(.white.opacity(DS.Opacity.medium))
                    }
            }

            // Top: editing tools
            VStack {
                HStack {
                    Button(action: { viewModel.retake() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    // Edit tools
                    HStack(spacing: DS.Spacing.md) {
                        editToolButton(icon: "textformat", label: "Text")
                        editToolButton(icon: "face.smiling", label: "Sticker")
                        editToolButton(icon: "pencil.tip", label: "Draw")
                        editToolButton(icon: "music.note", label: "Music")
                    }
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.top, DS.Spacing.md)

                Spacer()

                // Bottom: share button
                HStack {
                    // Story button
                    Button(action: {
                        Task { await viewModel.publishStory() }
                    }) {
                        HStack(spacing: DS.Spacing.xs) {
                            Image(systemName: "person.circle")
                            Text("Your Story")
                                .fontWeight(.semibold)
                        }
                        .font(DS.Font.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, DS.Spacing.lg)
                        .padding(.vertical, DS.Spacing.sm)
                        .background(ColorTokens.accentPrimary, in: Capsule())
                    }

                    Spacer()

                    // Close friends button
                    Button(action: {}) {
                        HStack(spacing: DS.Spacing.xs) {
                            Image(systemName: "star.circle.fill")
                                .foregroundStyle(ColorTokens.success)
                            Text("Close Friends")
                                .fontWeight(.semibold)
                        }
                        .font(DS.Font.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, DS.Spacing.lg)
                        .padding(.vertical, DS.Spacing.sm)
                        .background(ColorTokens.buttonSecondary, in: Capsule())
                    }
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.bottom, 30)
            }

            // Loading overlay
            if viewModel.isPublishing {
                Color.black.opacity(DS.Opacity.overlay)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
    }

    // MARK: - Edit Tool Button

    @ViewBuilder
    private func editToolButton(icon: String, label: String) -> some View {
        Button(action: {}) {
            VStack(spacing: DS.Spacing.xxs) {
                Image(systemName: icon)
                    .font(DS.Font.title3)
                Text(label)
                    .font(DS.Font.caption2)
            }
            .foregroundStyle(.white)
        }
    }

    // MARK: - Permission Denied

    private var permissionDeniedView: some View {
        VStack(spacing: DS.Spacing.md) {
            Image(systemName: "camera.fill")
                .font(.system(size: DS.Size.iconHero))
                .foregroundStyle(.white.opacity(DS.Opacity.overlay))
            Text("Camera Access Required")
                .font(DS.Font.headline)
                .foregroundStyle(.white)
            Text("Go to Settings to enable camera access")
                .font(DS.Font.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(DS.Font.subheadlineBold)
            .foregroundStyle(ColorTokens.accentPrimary)
        }
    }
}

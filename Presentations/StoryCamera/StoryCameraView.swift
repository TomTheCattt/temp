//
//  StoryCameraView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI
import PhotosUI
import AVKit

// MARK: - StoryCameraView

struct StoryCameraView: View {

    @State private var viewModel: StoryCameraViewModel
    @State private var selectedGalleryItem: PhotosPickerItem?
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
        .onDisappear {
            viewModel.cameraService.stop()
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

    // MARK: - Camera Preview
 
    private var cameraPreview: some View {
        ZStack {
            if viewModel.isHardwareAvailable {
                CameraPreviewView(
                    session: viewModel.cameraService.session,
                    isHardwareAvailable: true
                )
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large))
                .padding(.horizontal, DS.Spacing.xxxs)
                .padding(.vertical, DS.Spacing.modalTop + DS.Spacing.sm)
            } else {
                RoundedRectangle(cornerRadius: DS.Radius.large)
                    .fill(
                        LinearGradient(
                            colors: [Color.black, Color(.systemGray6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .padding(.horizontal, DS.Spacing.xxxs)
                    .padding(.vertical, DS.Spacing.modalTop + DS.Spacing.sm)
                    .overlay {
                        VStack(spacing: DS.Spacing.xs) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: DS.Spacing.xxxl))
                            Text(L10n.StoryCamera.cameraPreview)
                                .font(DS.Font.headline)
                            Text("Simulator Camera Mode")
                                .font(DS.Font.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.white.opacity(DS.Opacity.overlay))
                    }
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
                // Gallery button with PhotosPicker
                PhotosPicker(
                    selection: $selectedGalleryItem,
                    matching: .any(of: [.images, .videos])
                ) {
                    RoundedRectangle(cornerRadius: DS.Radius.thumbnailCard)
                        .fill(Color.gray.opacity(DS.Opacity.overlay))
                        .frame(width: DS.Size.buttonCompactHeight, height: DS.Size.buttonCompactHeight)
                        .overlay {
                            Image(systemName: "photo")
                                .font(DS.Font.caption)
                                .foregroundStyle(.white)
                        }
                }
                .onChange(of: selectedGalleryItem) { _, newItem in
                    guard let newItem else { return }
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                            let isVideo = isVideoData(data)
                            viewModel.loadFromGallery(data: data, isVideo: isVideo)
                        }
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
            .padding(.bottom, DS.Spacing.mediaControlsBottom)
        }
    }

    // MARK: - Preview Screen

    private var previewScreen: some View {
        ZStack {
            // Preview of captured media
            if let data = viewModel.capturedImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large))
                    .padding(DS.Spacing.xxxs)
            } else if let videoURL = viewModel.capturedVideoURL {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large))
                    .padding(DS.Spacing.xxxs)
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
                            Text(L10n.StoryCamera.yourStory)
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
                            Text(L10n.StoryCamera.closeFriends)
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
                .padding(.bottom, DS.Spacing.mediaControlsBottom)
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
            Text(L10n.StoryCamera.permissionTitle)
                .font(DS.Font.headline)
                .foregroundStyle(.white)
            Text(L10n.StoryCamera.permissionMessage)
                .font(DS.Font.subheadline)
                .foregroundStyle(.white.opacity(DS.Opacity.strong))
            Button(L10n.StoryCamera.openSettings) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(DS.Font.subheadlineBold)
            .foregroundStyle(ColorTokens.accentPrimary)
        }
    }

    // MARK: - Private Helpers

    private func isVideoData(_ data: Data) -> Bool {
        guard data.count >= 12 else { return false }
        let boxTypeBytes = [UInt8](data[4..<8])
        if let boxType = String(bytes: boxTypeBytes, encoding: .ascii) {
            return boxType == "ftyp" || boxType == "moov" || boxType == "wide"
        }
        return false
    }
}

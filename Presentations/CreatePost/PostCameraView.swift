//
//  PostCameraView.swift
//  Instagram
//
//  Created by Kiro on 14/10/26.
//

import SwiftUI
import PhotosUI
import AVKit
import UniformTypeIdentifiers

// MARK: - PostCameraViewModel

@MainActor
@Observable
final class PostCameraViewModel {
    var isFrontCamera = false
    var isFlashOn = false
    var isRecording = false
    var capturedPreviewData: Data?
    var capturedVideoURL: URL?
    var isVideo = false

    let cameraService: CameraService = .shared

    var isHardwareAvailable: Bool {
        cameraService.isHardwareAvailable
    }

    func setupSession() async {
        _ = await cameraService.configureSession(isFront: isFrontCamera)
        cameraService.start()
    }

    func stopSession() {
        cameraService.stop()
    }

    func toggleFlash() {
        isFlashOn.toggle()
        cameraService.setTorch(on: isFlashOn)
    }

    func toggleCamera() {
        isFrontCamera.toggle()
        cameraService.switchCamera(isFront: isFrontCamera)
    }

    func capturePhoto() {
        Task {
            do {
                let photoData = try await cameraService.capturePhoto(isFlashOn: isFlashOn)
                self.capturedPreviewData = photoData
                self.capturedVideoURL = nil
                self.isVideo = false
            } catch {
                HUDManager.shared.showError(error.localizedDescription)
            }
        }
    }

    func startRecording() {
        guard !isRecording else {
            stopRecording()
            return
        }
        isRecording = true
        cameraService.startRecording()
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        Task {
            do {
                let videoURL = try await cameraService.stopRecording()
                self.capturedVideoURL = videoURL
                if let videoData = try? Data(contentsOf: videoURL) {
                    self.capturedPreviewData = videoData
                    self.isVideo = true
                }
            } catch {
                HUDManager.shared.showError(error.localizedDescription)
            }
        }
    }

    func retake() {
        capturedPreviewData = nil
        capturedVideoURL = nil
        isVideo = false
    }
}

// MARK: - PostCameraView

/// Live Camera Viewfinder for Post creation (Camera-First philosophy).
/// Supports instant photo capture, video recording, front/back flip, flash,
/// and smooth fallback on iOS Simulator.
struct PostCameraView: View {

    @Binding var isPresented: Bool
    let onMediaCaptured: (Data, Bool) -> Void

    @State private var viewModel = PostCameraViewModel()
    @State private var selectedGalleryItem: PhotosPickerItem?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let previewData = viewModel.capturedPreviewData {
                if viewModel.isVideo, let videoURL = viewModel.capturedVideoURL {
                    videoReviewScreen(url: videoURL)
                } else if let uiImage = UIImage(data: previewData) {
                    reviewScreen(image: uiImage)
                } else {
                    viewfinderScreen
                }
            } else {
                // Live Viewfinder Screen
                viewfinderScreen
            }
        }
        .statusBarHidden()
        .task {
            await viewModel.setupSession()
        }
        .onDisappear {
            viewModel.stopSession()
        }
    }

    // MARK: - Viewfinder Screen

    private var viewfinderScreen: some View {
        ZStack {
            // Camera Stream
            if viewModel.isHardwareAvailable {
                CameraPreviewView(
                    session: viewModel.cameraService.session,
                    isHardwareAvailable: true
                )
                .ignoresSafeArea()
            } else {
                // Simulator Mock Camera Preview
                simulatorMockPreview
            }

            // Overlay Controls
            VStack {
                topBar
                Spacer()
                bottomBar
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.4), in: Circle())
            }

            Spacer()

            // Flash Toggle
            Button {
                viewModel.toggleFlash()
            } label: {
                Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash")
                    .font(.title3)
                    .foregroundStyle(viewModel.isFlashOn ? .yellow : .white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.4), in: Circle())
            }
        }
        .padding(.horizontal, DS.Padding.horizontal)
        .padding(.top, DS.Spacing.md)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(alignment: .center, spacing: DS.Spacing.xxl) {
            // Left: PhotosPicker Shortcut
            PhotosPicker(
                selection: $selectedGalleryItem,
                matching: .any(of: [.images, .videos])
            ) {
                RoundedRectangle(cornerRadius: DS.Radius.small)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.small)
                            .stroke(Color.white, lineWidth: 1.5)
                    )
            }
            .onChange(of: selectedGalleryItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    let isVideo = newItem.supportedContentTypes.contains(where: {
                        $0.conforms(to: .movie) || $0.conforms(to: .video)
                    })
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        onMediaCaptured(data, isVideo)
                        isPresented = false
                    }
                }
            }

            Spacer()

            // Center: Shutter Button (Tap for Photo, Long Press for Video)
            shutterButton

            Spacer()

            // Right: Camera Flip
            Button {
                viewModel.toggleCamera()
            } label: {
                Image(systemName: "camera.rotate")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.black.opacity(0.4), in: Circle())
            }
        }
        .padding(.horizontal, DS.Padding.horizontal)
        .padding(.bottom, DS.Spacing.xl)
    }

    // MARK: - Shutter Button

    private var shutterButton: some View {
        Button {
            if viewModel.isRecording {
                viewModel.stopRecording()
            } else {
                viewModel.capturePhoto()
            }
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 5)
                    .frame(width: 76, height: 76)

                Circle()
                    .fill(viewModel.isRecording ? ColorTokens.destructive : Color.white)
                    .frame(width: viewModel.isRecording ? 36 : 64, height: viewModel.isRecording ? 36 : 64)
                    .animation(.easeInOut(duration: 0.15), value: viewModel.isRecording)
            }
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    viewModel.startRecording()
                }
        )
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

            VStack(spacing: DS.Spacing.sm) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white.opacity(0.6))

                Text("Simulator Camera Viewfinder")
                    .font(DS.Font.headline)
                    .foregroundStyle(.white)

                Text("Chạm vào nút chụp để tạo ảnh mô phỏng chất lượng cao")
                    .font(DS.Font.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xl)
            }
        }
    }

    // MARK: - Post-capture Photo Review Screen

    private func reviewScreen(image: UIImage) -> some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button(L10n.CreatePost.retake) {
                        viewModel.retake()
                    }
                    .font(DS.Font.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(Color.black.opacity(0.5), in: Capsule())

                    Spacer()

                    Button(L10n.CreatePost.useMedia) {
                        if let data = viewModel.capturedPreviewData {
                            onMediaCaptured(data, false)
                            isPresented = false
                        }
                    }
                    .font(DS.Font.headline)
                    .foregroundStyle(ColorTokens.accentPrimary)
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(Color.white, in: Capsule())
                }
                .padding(.horizontal, DS.Padding.horizontal)
                .padding(.top, DS.Spacing.md)

                Spacer()
            }
        }
    }

    // MARK: - Post-capture Video Review Screen

    private func videoReviewScreen(url: URL) -> some View {
        ZStack {
            VideoPlayer(player: AVPlayer(url: url))
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button(L10n.CreatePost.retake) {
                        viewModel.retake()
                    }
                    .font(DS.Font.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(Color.black.opacity(0.5), in: Capsule())

                    Spacer()

                    Button(L10n.CreatePost.useMedia) {
                        if let data = viewModel.capturedPreviewData {
                            onMediaCaptured(data, true)
                            isPresented = false
                        }
                    }
                    .font(DS.Font.headline)
                    .foregroundStyle(ColorTokens.accentPrimary)
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(Color.white, in: Capsule())
                }
                .padding(.horizontal, DS.Padding.horizontal)
                .padding(.top, DS.Spacing.md)

                Spacer()
            }
        }
    }
}

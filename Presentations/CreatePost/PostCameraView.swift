//
//  PostCameraView.swift
//  Instagram
//
//  Created by Kiro on 14/10/26.
//

import SwiftUI
import PhotosUI

// MARK: - PostCameraView

/// Live Camera Viewfinder for Post creation (Camera-First philosophy).
/// Supports instant photo capture, video recording, front/back flip, flash,
/// and smooth fallback on iOS Simulator.
struct PostCameraView: View {

    @Binding var isPresented: Bool
    let onMediaCaptured: (Data, Bool) -> Void

    @State private var cameraService = CameraService.shared
    @State private var isFrontCamera = false
    @State private var isFlashOn = false
    @State private var isRecording = false
    @State private var capturedPreviewData: Data?
    @State private var isVideo = false
    @State private var selectedGalleryItem: PhotosPickerItem?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let previewData = capturedPreviewData, let uiImage = UIImage(data: previewData) {
                // Post-capture Review Screen
                reviewScreen(image: uiImage)
            } else {
                // Live Viewfinder Screen
                viewfinderScreen
            }
        }
        .statusBarHidden()
        .task {
            _ = await cameraService.configureSession(isFront: isFrontCamera)
            cameraService.start()
        }
        .onDisappear {
            cameraService.stop()
        }
    }

    // MARK: - Viewfinder Screen

    private var viewfinderScreen: some View {
        ZStack {
            // Camera Stream
            if cameraService.isHardwareAvailable {
                CameraPreviewView(
                    session: cameraService.session,
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
                isFlashOn.toggle()
                cameraService.toggleTorch(on: isFlashOn)
            } label: {
                Image(systemName: isFlashOn ? "bolt.fill" : "bolt.slash")
                    .font(.title3)
                    .foregroundStyle(isFlashOn ? .yellow : .white)
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
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        onMediaCaptured(data, false)
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
                isFrontCamera.toggle()
                cameraService.switchCamera(isFront: isFrontCamera)
            } label: {
                Image(systemName: "camera.rotate.fill")
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
            capturePhoto()
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 5)
                    .frame(width: 76, height: 76)

                Circle()
                    .fill(isRecording ? ColorTokens.destructive : Color.white)
                    .frame(width: isRecording ? 36 : 64, height: isRecording ? 36 : 64)
                    .animation(.easeInOut(duration: 0.15), value: isRecording)
            }
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    startRecording()
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

    // MARK: - Post-capture Review Screen

    private func reviewScreen(image: UIImage) -> some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button(L10n.CreatePost.retake) {
                        capturedPreviewData = nil
                    }
                    .font(DS.Font.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(Color.black.opacity(0.5), in: Capsule())

                    Spacer()

                    Button(L10n.CreatePost.useMedia) {
                        if let data = capturedPreviewData {
                            onMediaCaptured(data, isVideo)
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

    // MARK: - Actions

    private func capturePhoto() {
        Task {
            if cameraService.isHardwareAvailable {
                do {
                    let photoData = try await cameraService.capturePhoto()
                    await MainActor.run {
                        self.capturedPreviewData = photoData
                        self.isVideo = false
                    }
                } catch {
                    HUDManager.shared.showError(error.localizedDescription)
                }
            } else {
                // Simulator Mock Capture
                let mockData = cameraService.generateMockImageData()
                self.capturedPreviewData = mockData
                self.isVideo = false
            }
        }
    }

    private func startRecording() {
        guard !isRecording else {
            stopRecording()
            return
        }
        isRecording = true
        Task {
            do {
                try await cameraService.startRecording()
            } catch {
                isRecording = false
                HUDManager.shared.showError(error.localizedDescription)
            }
        }
    }

    private func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        Task {
            do {
                let videoURL = try await cameraService.stopRecording()
                if let videoData = try? Data(contentsOf: videoURL) {
                    await MainActor.run {
                        self.capturedPreviewData = videoData
                        self.isVideo = true
                    }
                }
            } catch {
                HUDManager.shared.showError(error.localizedDescription)
            }
        }
    }
}

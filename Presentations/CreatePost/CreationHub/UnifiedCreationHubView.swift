//
//  UnifiedCreationHubView.swift
//  Instagram
//
//  Created by Kiro on 15/10/26.
//

import SwiftUI

// MARK: - UnifiedCreationHubView

/// Instagram Unified Creation Hub:
/// Houses Post, Story, and Reel creation behind a seamless bottom mode switcher.
/// Matches official Instagram iOS creation flow with horizontal swipe & tab selection.
struct UnifiedCreationHubView: View {

    @State var selectedMode: CreationHubMode
    @Environment(\.dismiss) private var dismiss

    @State private var postViewModel: CreatePostViewModel
    @State private var storyViewModel: StoryCameraViewModel
    @State private var reelViewModel: CreateReelViewModel

    init(initialMode: CreationHubMode = .post) {
        _selectedMode = State(initialValue: initialMode)
        _postViewModel = State(initialValue: CreatePostViewModel(
            createPostUseCase: DIContainer.shared.resolve(CreatePostUseCaseProtocol.self)
        ))
        _storyViewModel = State(initialValue: StoryCameraViewModel(
            storyRepository: DIContainer.shared.resolve(StoryRepositoryProtocol.self)
        ))
        _reelViewModel = State(initialValue: CreateReelViewModel(
            reelRepository: DIContainer.shared.resolve(ReelRepositoryProtocol.self)
        ))
    }

    private var shouldShowModeSwitcher: Bool {
        switch selectedMode {
        case .post:
            return postViewModel.currentStep == .selectMedia
        case .story:
            return !storyViewModel.isShowingPreview && !storyViewModel.hasCapturedMedia
        case .reel:
            return !reelViewModel.isRecording && !reelViewModel.isShowingEditor && !reelViewModel.isShowingShareDetails
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            // Active Creation Screen
            ZStack {
                if selectedMode != .post, CameraService.shared.isHardwareAvailable {
                    // A capture session has exactly one live preview layer. Story and Reel
                    // supply their own controls above this shared stage.
                    CameraPreviewView(
                        session: CameraService.shared.session,
                        isHardwareAvailable: true,
                        isFrontFacing: selectedMode == .story
                            ? storyViewModel.isFrontCamera
                            : reelViewModel.isFrontCamera
                    )
                    .ignoresSafeArea()
                }

                if selectedMode == .post {
                    CreatePostView(viewModel: postViewModel)
                        .zIndex(2)
                        .transition(.opacity)
                }

                // Persistent Story & Reel viewports to achieve 60/120 FPS zero-lag switching
                ZStack {
                    StoryCameraView(
                        viewModel: storyViewModel,
                        stopCameraOnDisappear: false,
                        usesSharedCameraPreview: true,
                        isCameraModeActive: selectedMode == .story
                    )
                        .opacity(selectedMode == .story ? 1 : 0)
                        .allowsHitTesting(selectedMode == .story)
                        .accessibilityHidden(selectedMode != .story)

                    CreateReelView(
                        viewModel: reelViewModel,
                        stopCameraOnDisappear: false,
                        usesSharedCameraPreview: true,
                        isCameraModeActive: selectedMode == .reel
                    )
                        .opacity(selectedMode == .reel ? 1 : 0)
                        .allowsHitTesting(selectedMode == .reel)
                        .accessibilityHidden(selectedMode != .reel)
                }
                .zIndex(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Instagram Bottom Sliding Mode Bar (visible during initial capture / picker only)
            if shouldShowModeSwitcher {
                bottomModeSwitcher
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .statusBarHidden()
        .animation(.easeInOut(duration: 0.25), value: shouldShowModeSwitcher)
        .onDisappear {
            CameraService.shared.stop()
        }
        .onChange(of: selectedMode) { _, newMode in
            if newMode == .post {
                CameraService.shared.stop()
            }

            // Sync camera facing and gallery thumbnails between Story and Reel ViewModels
            if newMode == .reel {
                reelViewModel.isFrontCamera = CameraService.shared.isFrontFacing
                if reelViewModel.latestGalleryThumbnail == nil {
                    reelViewModel.latestGalleryThumbnail = storyViewModel.latestGalleryThumbnail
                }
            } else if newMode == .story {
                storyViewModel.isFrontCamera = CameraService.shared.isFrontFacing
                if storyViewModel.latestGalleryThumbnail == nil {
                    storyViewModel.latestGalleryThumbnail = reelViewModel.latestGalleryThumbnail
                }
            }
        }
    }

    // MARK: - Bottom Mode Switcher

    private var bottomModeSwitcher: some View {
        HStack(spacing: DS.Spacing.xs) {
            ForEach(CreationHubMode.allCases) { mode in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedMode = mode
                    }
                    HapticFeedbackSafe.impact(.light)
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: 13, weight: selectedMode == mode ? .bold : .medium))
                        .foregroundStyle(selectedMode == mode ? .white : .white.opacity(0.55))
                        .frame(width: 82, height: 32)
                        .background(
                            selectedMode == mode ? Color.black.opacity(0.4) : Color.clear,
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DS.Spacing.xs)
        .padding(.vertical, 4)
        .background(
            Color.black.opacity(0.55),
            in: Capsule()
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .gesture(
            DragGesture(minimumDistance: 15)
                .onEnded { value in
                    if value.translation.width < -25 {
                        switchMode(forward: true)
                    } else if value.translation.width > 25 {
                        switchMode(forward: false)
                    }
                }
        )
        .padding(.bottom, DS.Spacing.md)
    }

    private func switchMode(forward: Bool) {
        let modes = CreationHubMode.allCases
        guard let currentIndex = modes.firstIndex(of: selectedMode) else { return }
        if forward && currentIndex < modes.count - 1 {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedMode = modes[currentIndex + 1]
            }
            HapticFeedbackSafe.impact(.medium)
        } else if !forward && currentIndex > 0 {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedMode = modes[currentIndex - 1]
            }
            HapticFeedbackSafe.impact(.medium)
        }
    }
}

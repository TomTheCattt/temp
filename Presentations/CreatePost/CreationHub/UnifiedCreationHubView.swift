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
            Group {
                switch selectedMode {
                case .post:
                    CreatePostView(viewModel: postViewModel)
                case .story:
                    StoryCameraView(viewModel: storyViewModel)
                case .reel:
                    CreateReelView(viewModel: reelViewModel)
                }
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
    }

    // MARK: - Bottom Mode Switcher

    private var bottomModeSwitcher: some View {
        HStack(spacing: DS.Spacing.xl) {
            ForEach(CreationHubMode.allCases) { mode in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedMode = mode
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: 13, weight: selectedMode == mode ? .bold : .medium))
                        .foregroundStyle(selectedMode == mode ? .white : .white.opacity(0.55))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(
                            selectedMode == mode ? Color.black.opacity(0.4) : Color.clear,
                            in: Capsule()
                        )
                }
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, 6)
        .background(
            Color.black.opacity(0.55),
            in: Capsule()
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .padding(.bottom, DS.Spacing.md)
    }
}

//
//  CreateReelView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI
import PhotosUI

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

            // Camera preview placeholder
            RoundedRectangle(cornerRadius: DS.Radius.large)
                .fill(Color.gray.opacity(0.2))
                .padding(.horizontal, DS.Spacing.xxs)
                .padding(.vertical, DS.Spacing.modalTop + DS.Spacing.xxl)
                .overlay {
                    VStack(spacing: DS.Spacing.xs) {
                        Image(systemName: "video.fill")
                            .font(.system(size: DS.Spacing.xxxl))
                        Text("Camera Preview")
                            .font(DS.Font.caption)
                    }
                    .foregroundStyle(.white.opacity(DS.Opacity.overlay))
                }

            // Controls
            VStack {
                // Top bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    // Audio picker
                    Button(action: {}) {
                        HStack(spacing: DS.Spacing.xxs) {
                            Image(systemName: "music.note")
                            Text("Add audio")
                        }
                        .font(DS.Font.captionBold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, DS.Spacing.sm)
                        .padding(.vertical, DS.Spacing.iconGap)
                        .background(Color.white.opacity(0.2), in: Capsule())
                    }

                    Spacer()

                    // Settings
                    Button(action: {}) {
                        Image(systemName: "gearshape")
                            .font(DS.Font.title3)
                            .foregroundStyle(.white)
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
                        toolButton(icon: "bolt.slash", label: "Flash") {}
                        toolButton(icon: "timer", label: "Timer") {}
                        toolButton(icon: "sparkles", label: "Effects") {}
                        toolButton(icon: "square.grid.2x2", label: "Layout") {}
                    }
                    .padding(.trailing, DS.Spacing.md)
                }

                Spacer()

                // Bottom: capture + gallery
                VStack(spacing: DS.Spacing.md) {
                    // Duration selector
                    HStack(spacing: DS.Spacing.md) {
                        durationChip("15s", isSelected: true)
                        durationChip("30s", isSelected: false)
                        durationChip("60s", isSelected: false)
                        durationChip("90s", isSelected: false)
                    }

                    // Capture + gallery
                    HStack(spacing: DS.Spacing.xxxl) {
                        // Gallery
                        PhotosPicker(
                            selection: $viewModel.videoPickerItem,
                            matching: .videos
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
                                    .fill(viewModel.isRecording ? ColorTokens.destructive : ColorTokens.destructive.opacity(0.8))
                                    .frame(width: viewModel.isRecording ? DS.Size.avatarCompact : DS.Size.captureButtonInner, height: viewModel.isRecording ? DS.Size.avatarCompact : DS.Size.captureButtonInner)
                                    .clipShape(viewModel.isRecording ? AnyShape(RoundedRectangle(cornerRadius: DS.Radius.medium)) : AnyShape(Circle()))
                            }
                        }

                        // Placeholder for balance
                        Color.clear.frame(width: DS.Size.buttonCompactHeight, height: DS.Size.buttonCompactHeight)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Editor Screen

    private var editorScreen: some View {
        VStack(spacing: 0) {
            // Video preview
            ZStack {
                Color.black
                    .frame(height: 400)
                VStack(spacing: DS.Spacing.xs) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: DS.Size.iconHero))
                        .foregroundStyle(.white.opacity(DS.Opacity.medium))
                    Text("Video Preview")
                        .font(DS.Font.caption)
                        .foregroundStyle(.white.opacity(DS.Opacity.overlay))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large))
            .padding()

            // Caption
            TextField("Write a caption...", text: $viewModel.caption, axis: .vertical)
                .font(DS.Font.subheadline)
                .lineLimit(3...5)
                .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("New Reel")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    viewModel.isShowingEditor = false
                    viewModel.selectedVideoData = nil
                }) {
                    Image(systemName: "chevron.left")
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Share") {
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
    private func durationChip(_ text: String, isSelected: Bool) -> some View {
        Text(text)
            .font(DS.Font.caption)
            .fontWeight(isSelected ? .bold : .regular)
            .foregroundStyle(isSelected ? .white : .white.opacity(DS.Opacity.medium))
            .padding(.horizontal, DS.Spacing.sm)
            .padding(.vertical, DS.Spacing.xxs)
            .background(
                isSelected ? Color.white.opacity(0.2) : Color.clear,
                in: Capsule()
            )
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

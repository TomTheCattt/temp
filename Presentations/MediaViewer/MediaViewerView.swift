//
//  MediaViewerView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI

// MARK: - MediaViewerView

struct MediaViewerView: View {

    let url: URL
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Media content
            mediaContent
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnifyGesture()
                        .onChanged { value in
                            scale = lastScale * value.magnification
                        }
                        .onEnded { _ in
                            lastScale = scale
                            if scale < 1.0 {
                                withAnimation(.spring()) {
                                    scale = 1.0
                                    lastScale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            }
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { value in
                            lastOffset = offset
                            if scale <= 1.0 && value.translation.height > 100 {
                                dismiss()
                            }
                        }
                )

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .statusBarHidden()
    }

    // MARK: - Media Content

    @ViewBuilder
    private var mediaContent: some View {
        let ext = url.pathExtension.lowercased()
        if ["mp4", "mov", "m4v"].contains(ext) {
            // Video placeholder
            ZStack {
                Color.black
                VStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: DS.Size.iconJumbo))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("Video Player")
                        .font(DS.Font.caption)
                        .foregroundStyle(.white.opacity(DS.Opacity.overlay))
                }
            }
        } else {
            // Image
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    VStack(spacing: DS.Spacing.xs) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                        Text("Failed to load")
                            .font(DS.Font.caption)
                    }
                    .foregroundStyle(.white.opacity(DS.Opacity.medium))
                default:
                    ProgressView()
                        .tint(.white)
                }
            }
        }
    }
}

//
//  StoryStickerDrawer.swift
//  Instagram
//
//  Created by Kiro on 15/10/26.
//

import SwiftUI
import PhotosUI
import ImageIO

// MARK: - StoryStickerDrawer

/// Dedicated Instagram Story Sticker Drawer Sheet:
/// - "Tự tạo nhãn dán": Custom Photo Sticker creation via PhotosPicker with low-memory downsampling.
/// - Interactive Instagram stickers: Vị trí, Nhắc đến, Thăm dò, Câu hỏi, Âm nhạc, Liên kết.
/// - Quick Emoji Stickers.
struct StoryStickerDrawer: View {

    @Binding var isPresented: Bool
    let onAddPhotoSticker: (Data) -> Void
    let onAddTextSticker: (TextOverlayItem) -> Void

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isProcessingPhoto = false
    @State private var isShowingLocationSearch = false
    @State private var isShowingLinkDialog = false

    private let quickEmojis: [String] = [
        "❤️", "🔥", "😍", "😂", "👏", "🎉", "✨", "💯", "🍕", "☕️", "🌈", "🐶"
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: DS.Spacing.lg) {
                    // Section 1: "Tự tạo nhãn dán" (Custom Sticker from Photo)
                    customPhotoStickerCard

                    // Section 2: Interactive Story Stickers Grid
                    interactiveStickersGrid

                    // Section 3: Quick Emojis Row
                    quickEmojisSection
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.md)
            }
            .navigationTitle("Nhãn dán")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") {
                        isPresented = false
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $isShowingLocationSearch) {
            LocationSearchSheet(isPresented: $isShowingLocationSearch) { locationName in
                onAddTextSticker(TextOverlayItem(text: "📍 \(locationName)", hasBackground: true))
                isPresented = false
            }
        }
        .sheet(isPresented: $isShowingLinkDialog) {
            LinkInputDialog(isPresented: $isShowingLinkDialog) { url in
                let cleanURL = url.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "")
                onAddTextSticker(TextOverlayItem(text: "🔗 \(cleanURL)", hasBackground: true))
                isPresented = false
            }
        }
    }

    // MARK: - Custom Photo Sticker Card

    private var customPhotoStickerCard: some View {
        PhotosPicker(
            selection: $selectedPhotoItem,
            matching: .images
        ) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                        .foregroundStyle(ColorTokens.accentPrimary)
                        .frame(width: 48, height: 48)

                    InstagramIcon(.system(name: "plus.square.dashed"), size: 24, color: ColorTokens.accentPrimary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Tự tạo nhãn dán")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.primary)

                        Text("TỪ ẢNH")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(ColorTokens.accentPrimary, in: Capsule())
                    }

                    Text("Chọn ảnh từ thư viện để tạo sticker tuỳ chỉnh")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isProcessingPhoto {
                    ProgressView()
                } else {
                    InstagramIcon(.chevronRight, size: 13, color: .secondary)
                }
            }
            .padding(DS.Spacing.md)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            isProcessingPhoto = true
            Task {
                if let rawData = try? await newItem.loadTransferable(type: Data.self),
                   let rawImage = UIImage(data: rawData) {
                    // Auto-extract foreground subject using Vision Framework
                    let finalData: Data
                    if let liftedSubject = await StickerSubjectLifter.liftSubject(from: rawImage),
                       let png = liftedSubject.pngData() {
                        finalData = png
                    } else {
                        finalData = await downsampleImageData(rawData, maxDimension: 1080)
                    }

                    await MainActor.run {
                        onAddPhotoSticker(finalData)
                        isProcessingPhoto = false
                        selectedPhotoItem = nil
                        isPresented = false
                    }
                } else {
                    await MainActor.run { isProcessingPhoto = false }
                }
            }
        }
    }

    // MARK: - Interactive Stickers Grid (18 Instagram Graphical Stickers)

    private var interactiveStickersGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            stickerButton(sticker: .location) {
                isShowingLocationSearch = true
            }

            stickerButton(sticker: .mention) {
                onAddTextSticker(TextOverlayItem(text: "@banbe", hasBackground: true))
                isPresented = false
            }

            stickerButton(sticker: .addYours) {
                onAddTextSticker(TextOverlayItem(text: "📸 Lượt bạn", hasBackground: true))
                isPresented = false
            }

            stickerButton(sticker: .questions) {
                onAddTextSticker(TextOverlayItem(text: "💬 Hãy hỏi tôi một câu", hasBackground: true))
                isPresented = false
            }

            stickerButton(sticker: .music) {
                onAddTextSticker(TextOverlayItem(text: "🎵 Bài hát yêu thích", hasBackground: true))
                isPresented = false
            }

            stickerButton(sticker: .poll) {
                onAddTextSticker(TextOverlayItem(text: "📊 Thăm dò ý kiến", hasBackground: true))
                isPresented = false
            }

            stickerButton(sticker: .quiz) {
                onAddTextSticker(TextOverlayItem(text: "💡 Câu đố", hasBackground: true))
                isPresented = false
            }

            stickerButton(sticker: .link) {
                isShowingLinkDialog = true
            }

            stickerButton(sticker: .addYoursTemplates) {
                onAddTextSticker(TextOverlayItem(text: "✨ Mẫu của bạn", hasBackground: true))
                isPresented = false
            }

            stickerButton(sticker: .donation) {
                onAddTextSticker(TextOverlayItem(text: "💝 Quyên góp", hasBackground: true))
                isPresented = false
            }

            stickerButton(sticker: .notify) {
                onAddTextSticker(TextOverlayItem(text: "🔔 Nhận thông báo", hasBackground: true))
                isPresented = false
            }

            stickerButton(sticker: .questionReaction) {
                onAddTextSticker(TextOverlayItem(text: "🔥 Thả cảm xúc", hasBackground: true))
                isPresented = false
            }

            stickerButton(sticker: .avatar) {
                onAddTextSticker(TextOverlayItem(text: "😎 Avatar", hasBackground: false))
                isPresented = false
            }

            stickerButton(sticker: .gif) {
                onAddTextSticker(TextOverlayItem(text: "🎞️ GIF", hasBackground: false))
                isPresented = false
            }

            stickerButton(sticker: .hashtag) {
                onAddTextSticker(TextOverlayItem(text: "#hashtag", hasBackground: true))
                isPresented = false
            }

            stickerButton(sticker: .heartBlue) {
                onAddTextSticker(TextOverlayItem(text: "💙", hasBackground: false, scale: 1.5))
                isPresented = false
            }

            stickerButton(sticker: .heartPink) {
                onAddTextSticker(TextOverlayItem(text: "💖", hasBackground: false, scale: 1.5))
                isPresented = false
            }

            stickerButton(sticker: .emoji) {
                onAddTextSticker(TextOverlayItem(text: "😍", hasBackground: false, scale: 1.5))
                isPresented = false
            }
        }
    }

    @ViewBuilder
    private func stickerButton(
        sticker: AppSticker,
        height: CGFloat = 38,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            HapticFeedbackSafe.impact(.light)
            action()
        } label: {
            InstagramStickerView(sticker, height: height)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Emojis Section

    private var quickEmojisSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Emoji nổi bật")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(quickEmojis, id: \.self) { emoji in
                        Button {
                            onAddTextSticker(
                                TextOverlayItem(
                                    text: emoji,
                                    hasBackground: false,
                                    scale: 1.5
                                )
                            )
                            isPresented = false
                        } label: {
                            Text(emoji)
                                .font(.system(size: 36))
                                .frame(width: 52, height: 52)
                                .background(Color(.secondarySystemBackground), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Low-Memory Image Downsampler

    private func downsampleImageData(_ data: Data, maxDimension: CGFloat) async -> Data {
        await Task.detached(priority: .userInitiated) {
            guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return data }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxDimension
            ]
            guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return data }
            let uiImage = UIImage(cgImage: thumbnail)
            return uiImage.jpegData(compressionQuality: 0.85) ?? data
        }.value
    }
}

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

                    Image(systemName: "plus.square.dashed")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(ColorTokens.accentPrimary)
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
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.tertiary)
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

    // MARK: - Interactive Stickers Grid

    private var interactiveStickersGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            stickerButton(
                title: "VỊ TRÍ",
                icon: "mappin.and.ellipse",
                color: Color.red
            ) {
                isShowingLocationSearch = true
            }

            stickerButton(
                title: "NHẮC ĐẾN",
                icon: "at",
                color: Color.orange
            ) {
                onAddTextSticker(TextOverlayItem(text: "@banbe", hasBackground: true))
                isPresented = false
            }

            stickerButton(
                title: "THĂM DÒ",
                icon: "chart.bar.xaxis",
                color: Color.purple
            ) {
                onAddTextSticker(TextOverlayItem(text: "📊 Có / Không?", hasBackground: true))
                isPresented = false
            }

            stickerButton(
                title: "CÂU HỎI",
                icon: "questionmark.circle",
                color: Color.blue
            ) {
                onAddTextSticker(TextOverlayItem(text: "💬 Hãy hỏi tôi một câu", hasBackground: true))
                isPresented = false
            }

            stickerButton(
                title: "ÂM NHẠC",
                icon: "music.note",
                color: Color.pink
            ) {
                onAddTextSticker(TextOverlayItem(text: "🎵 Bài hát yêu thích", hasBackground: true))
                isPresented = false
            }

            stickerButton(
                title: "LIÊN KẾT",
                icon: "link",
                color: Color.indigo
            ) {
                isShowingLinkDialog = true
            }
        }
    }

    @ViewBuilder
    private func stickerButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(color)

                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
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

//
//  TypographyOverlayView.swift
//  Instagram
//
//  Created by Kiro on 14/10/26.
//

import SwiftUI

// MARK: - TextFontStyle

public enum TextFontStyle: String, CaseIterable, Identifiable {
    case modern = "Modern"
    case neon = "Neon"
    case typewriter = "Typewriter"
    case strong = "Strong"

    public var id: String { rawValue }

    var font: Font {
        switch self {
        case .modern: return .system(size: 28, weight: .bold, design: .default)
        case .neon: return .system(size: 28, weight: .semibold, design: .rounded)
        case .typewriter: return .system(size: 26, weight: .medium, design: .monospaced)
        case .strong: return .system(size: 32, weight: .heavy, design: .serif)
        }
    }
}

// MARK: - TextOverlayItem

public struct TextOverlayItem: Identifiable {
    public let id: UUID
    public var text: String
    public var color: Color
    public var hasBackground: Bool
    public var fontStyle: TextFontStyle
    public var offset: CGSize
    public var scale: CGFloat

    public init(
        id: UUID = UUID(),
        text: String,
        color: Color = .white,
        hasBackground: Bool = false,
        fontStyle: TextFontStyle = .modern,
        offset: CGSize = .zero,
        scale: CGFloat = 1.0
    ) {
        self.id = id
        self.text = text
        self.color = color
        self.hasBackground = hasBackground
        self.fontStyle = fontStyle
        self.offset = offset
        self.scale = scale
    }
}

// MARK: - TypographyOverlayView

struct TypographyOverlayView: View {

    @Binding var item: TextOverlayItem
    let onDelete: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var isSelected: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Text(item.text)
                .font(item.fontStyle.font)
                .foregroundStyle(item.color)
                .padding(.horizontal, item.hasBackground ? 12 : 4)
                .padding(.vertical, item.hasBackground ? 6 : 2)
                .background(
                    item.hasBackground ? Color.black.opacity(0.65) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                .onTapGesture {
                    isSelected.toggle()
                }

            if isSelected {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(.white, ColorTokens.destructive)
                        .background(Circle().fill(Color.white).padding(2))
                }
                .offset(x: 12, y: -12)
            }
        }
        .scaleEffect(item.scale * currentScale)
        .offset(x: item.offset.width + dragOffset.width, y: item.offset.height + dragOffset.height)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    item.offset.width += value.translation.width
                    item.offset.height += value.translation.height
                    dragOffset = .zero
                }
        )
        .simultaneousGesture(
            MagnificationGesture()
                .onChanged { scale in
                    currentScale = scale
                }
                .onEnded { scale in
                    item.scale = max(0.5, min(3.0, item.scale * scale))
                    currentScale = 1.0
                }
        )
    }
}

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
    public var alignment: TextAlignment
    public var offset: CGSize
    public var scale: CGFloat

    public init(
        id: UUID = UUID(),
        text: String,
        color: Color = .white,
        hasBackground: Bool = false,
        fontStyle: TextFontStyle = .modern,
        alignment: TextAlignment = .center,
        offset: CGSize = .zero,
        scale: CGFloat = 1.0
    ) {
        self.id = id
        self.text = text
        self.color = color
        self.hasBackground = hasBackground
        self.fontStyle = fontStyle
        self.alignment = alignment
        self.offset = offset
        self.scale = scale
    }
}

// MARK: - Color Contrast Extension

extension Color {
    var isLightColor: Bool {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        let uiColor = UIColor(self)
        if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
            return luminance > 0.6
        }
        var white: CGFloat = 0
        if uiColor.getWhite(&white, alpha: &alpha) {
            return white > 0.6
        }
        return false
    }

    var smartBadgeBackgroundColor: Color {
        isLightColor ? Color.black.opacity(0.65) : Color.white.opacity(0.85)
    }
}

// MARK: - TypographyOverlayView

struct TypographyOverlayView: View {

    @Binding var item: TextOverlayItem
    let onDelete: () -> Void
    var onEdit: (() -> Void)? = nil

    @State private var dragOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var isSelected: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Text(item.text)
                .font(item.fontStyle.font)
                .multilineTextAlignment(item.alignment)
                .foregroundStyle(item.color)
                .padding(.horizontal, item.hasBackground ? 12 : 6)
                .padding(.vertical, item.hasBackground ? 6 : 4)
                .background(
                    item.hasBackground ? item.color.smartBadgeBackgroundColor : Color.clear,
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isSelected ? ColorTokens.accentPrimary : Color.clear, lineWidth: 1.5)
                        .padding(-4)
                )
                .shadow(color: .black.opacity(item.hasBackground ? 0.35 : 0.7), radius: 4, x: 0, y: 2)
                .contentShape(Rectangle())
                .onTapGesture {
                    if isSelected {
                        onEdit?()
                    } else {
                        isSelected = true
                    }
                }

            if isSelected {
                // Delete button (top-trailing)
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(.white, ColorTokens.destructive)
                        .background(Circle().fill(Color.white).padding(2))
                }
                .offset(x: 12, y: -12)

                // Edit button (top-leading)
                if let onEdit {
                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.body)
                            .foregroundStyle(.white, ColorTokens.accentPrimary)
                            .background(Circle().fill(Color.white).padding(2))
                    }
                    .offset(x: -12, y: -12)
                }
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


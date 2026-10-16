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
    case classic = "Classic"
    case signature = "Signature"
    case neon = "Neon"
    case typewriter = "Typewriter"
    case strong = "Strong"

    public var id: String { rawValue }

    var font: Font {
        switch self {
        case .modern: return .system(size: 28, weight: .bold, design: .default)
        case .classic: return .system(size: 28, weight: .regular, design: .serif)
        case .signature: return .system(size: 30, weight: .medium, design: .rounded).italic()
        case .neon: return .system(size: 28, weight: .semibold, design: .rounded)
        case .typewriter: return .system(size: 26, weight: .medium, design: .monospaced)
        case .strong: return .system(size: 32, weight: .heavy, design: .serif)
        }
    }
}

// MARK: - TextAnimationType

public enum TextAnimationType: String, CaseIterable, Identifiable {
    case none = "Không"
    case typewriter = "Chữ đánh máy"
    case reveal = "Hiện ra"
    case bounce = "Nhảy"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .none: return "slash.circle"
        case .typewriter: return "character.cursor.ibeam"
        case .reveal: return "sparkle"
        case .bounce: return "arrow.up.and.down"
        }
    }
}

// MARK: - TextEffectType

public enum TextEffectType: String, CaseIterable, Identifiable {
    case none = "Không"
    case sparkle = "Lấp lánh"
    case neon = "Neon"
    case wavy = "Lung linh"
    case pixel = "Pixel"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .none: return "slash.circle"
        case .sparkle: return "sparkles"
        case .neon: return "bolt.fill"
        case .wavy: return "water.waves"
        case .pixel: return "circle.grid.2x2"
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
    public var isItalic: Bool
    public var animation: TextAnimationType
    public var effect: TextEffectType
    /// Point size on the logical 9:16 canvas. This must travel with the item
    /// so editing, preview, image export and video export agree.
    public var fontSize: CGFloat
    public var offset: CGSize
    public var scale: CGFloat

    public init(
        id: UUID = UUID(),
        text: String,
        color: Color = .white,
        hasBackground: Bool = false,
        fontStyle: TextFontStyle = .modern,
        alignment: TextAlignment = .center,
        isItalic: Bool = false,
        animation: TextAnimationType = .none,
        effect: TextEffectType = .none,
        fontSize: CGFloat = 32,
        offset: CGSize = .zero,
        scale: CGFloat = 1.0
    ) {
        self.id = id
        self.text = text
        self.color = color
        self.hasBackground = hasBackground
        self.fontStyle = fontStyle
        self.alignment = alignment
        self.isItalic = isItalic
        self.animation = animation
        self.effect = effect
        self.fontSize = fontSize
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

// MARK: - TypographyOverlayView

struct TypographyOverlayView: View {

    @Binding var item: TextOverlayItem
    var onStartEditing: () -> Void
    var onDragChanged: ((CGPoint) -> Void)? = nil
    var onDragEnded: ((CGPoint, CGSize) -> Void)? = nil

    @State private var dragOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0

    init(
        item: Binding<TextOverlayItem>,
        onStartEditing: @escaping () -> Void,
        onDragChanged: ((CGPoint) -> Void)? = nil,
        onDragEnded: ((CGPoint, CGSize) -> Void)? = nil
    ) {
        self._item = item
        self.onStartEditing = onStartEditing
        self.onDragChanged = onDragChanged
        self.onDragEnded = onDragEnded
    }

    // Backward-compatible initializer for UniversalCreativeStudioView & StoryCameraView
    init(
        item: Binding<TextOverlayItem>,
        onDelete: (() -> Void)? = nil,
        onEdit: (() -> Void)? = nil,
        onDragChanged: ((CGPoint) -> Void)? = nil,
        onDragEnded: ((CGPoint, CGSize) -> Void)? = nil
    ) {
        self._item = item
        self.onStartEditing = onEdit ?? {}
        self.onDragChanged = onDragChanged
        self.onDragEnded = { location, translation in
            if let onDragEnded {
                onDragEnded(location, translation)
            } else {
                item.wrappedValue.offset.width += translation.width
                item.wrappedValue.offset.height += translation.height
            }
        }
    }

    var body: some View {
        AnimatedStoryTextView(item: item)
            .contentShape(Rectangle())
            .onTapGesture {
                HapticFeedbackSafe.impact(.light)
                onStartEditing()
            }
            .scaleEffect(item.scale * currentScale)
            .offset(x: item.offset.width + dragOffset.width, y: item.offset.height + dragOffset.height)
            .gesture(
                DragGesture(minimumDistance: 3, coordinateSpace: .global)
                    .onChanged { value in
                        dragOffset = value.translation
                        onDragChanged?(value.location)
                    }
                    .onEnded { value in
                        let location = value.location
                        let translation = value.translation
                        dragOffset = .zero
                        onDragEnded?(location, translation)
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


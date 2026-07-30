//
//  PrimitiveColors.swift
//  Instagram
//
//  Extracted from Figma – Instagram UI Kit 4.0 (Community)
//  Node: 475-11107 (Colors)
//

import SwiftUI

// MARK: - Primitive Color Palette

/// Raw color values from the Figma design system.
/// Use `ColorTokens` for semantic usage in views. Use these primitives
/// only when building new semantic tokens or custom components.
enum PrimitiveColors {

    // MARK: - Neutral

    enum Neutral {
        static let black100 = Color(hex: 0x000000)
        static let black80  = Color(hex: 0x000000).opacity(0.80)
        static let black60  = Color(hex: 0x000000).opacity(0.60)
        static let black40  = Color(hex: 0x000000).opacity(0.40)

        static let white100 = Color(hex: 0xFFFFFF)
        static let white70  = Color(hex: 0xFFFFFF).opacity(0.70)
        static let white35  = Color(hex: 0xFFFFFF).opacity(0.35)
        static let white20  = Color(hex: 0xFFFFFF).opacity(0.20)
    }

    // MARK: - Gray

    enum Gray {
        static let gray100 = Color(hex: 0x0C1014)
        static let gray90  = Color(hex: 0x212328)
        static let gray80  = Color(hex: 0x25292E)
        static let gray70  = Color(hex: 0x5E646D)
        static let gray60  = Color(hex: 0x6F7680)
        static let gray40  = Color(hex: 0xA2AAB4)
        static let gray30  = Color(hex: 0xDBDFE4)
        static let gray20  = Color(hex: 0xF3F4F6)
        static let gray10  = Color(hex: 0xF7F9F9)
    }

    // MARK: - Yellow

    enum Yellow {
        static let yellow100 = Color(hex: 0xFFD600)
        static let yellow80  = Color(hex: 0xFFDD2E)
        static let yellow60  = Color(hex: 0xFFE55C)
        static let yellow40  = Color(hex: 0xFFEC8A)
        static let yellow20  = Color(hex: 0xFFF4B8)
        static let yellow10  = Color(hex: 0xFFFDF1)
    }

    // MARK: - Orange

    enum Orange {
        static let orange100 = Color(hex: 0xFF7A00)
        static let orange80  = Color(hex: 0xFF922E)
        static let orange60  = Color(hex: 0xFFAA5C)
        static let orange40  = Color(hex: 0xFFC28A)
        static let orange20  = Color(hex: 0xFFDAB8)
        static let orange10  = Color(hex: 0xFFF8F1)
    }

    // MARK: - Pink

    enum Pink {
        static let pink100 = Color(hex: 0xFF0069)
        static let pink80  = Color(hex: 0xFF2E84)
        static let pink60  = Color(hex: 0xFF5C9F)
        static let pink40  = Color(hex: 0xFF8ABA)
        static let pink20  = Color(hex: 0xFFB8D5)
        static let pink10  = Color(hex: 0xFFF1F7)
    }

    // MARK: - Magenta

    enum Magenta {
        static let magenta100 = Color(hex: 0xD300C5)
        static let magenta80  = Color(hex: 0xFF02EE)
        static let magenta60  = Color(hex: 0xFF30F1)
        static let magenta40  = Color(hex: 0xFF5EF4)
        static let magenta20  = Color(hex: 0xFFA8F9)
        static let magenta10  = Color(hex: 0xFFF0FE)
    }

    // MARK: - Purple

    enum Purple {
        static let purple100 = Color(hex: 0x5C12F9)
        static let purple80  = Color(hex: 0x7638FA)
        static let purple60  = Color(hex: 0x9565FB)
        static let purple40  = Color(hex: 0xB492FC)
        static let purple20  = Color(hex: 0xD3BFFD)
        static let purple10  = Color(hex: 0xF2EBFF)
    }

    // MARK: - Blue

    enum Blue {
        static let blue100 = Color(hex: 0x00386E)
        static let blue80  = Color(hex: 0x006BB3)
        static let blue60  = Color(hex: 0x0098FD)
        static let blue40  = Color(hex: 0x4FB9FF)
        static let blue20  = Color(hex: 0x9AD6FF)
        static let blue10  = Color(hex: 0xEFF9FF)
    }

    // MARK: - Red

    enum Red {
        static let red100 = Color(hex: 0xFF0034)
        static let red80  = Color(hex: 0xFF2E59)
        static let red60  = Color(hex: 0xFF5C7D)
        static let red40  = Color(hex: 0xFF8AA2)
        static let red20  = Color(hex: 0xFFB8C6)
        static let red10  = Color(hex: 0xFFF1F4)
    }

    // MARK: - Green

    enum Green {
        static let green100 = Color(hex: 0x00DA00)
        static let green80  = Color(hex: 0x09FF09)
        static let green60  = Color(hex: 0x37FF37)
        static let green40  = Color(hex: 0x65FF65)
        static let green20  = Color(hex: 0x93FF93)
        static let green10  = Color(hex: 0xCCFFCC)
    }

    // MARK: - Instagram Gradient

    /// The signature Instagram brand gradient colors (top-right to bottom-left).
    static let instagramGradientColors: [Color] = [
        Purple.purple80,   // #7638FA
        Magenta.magenta100, // #D300C5
        Pink.pink100,       // #FF0069
        Orange.orange100    // #FF7A00
    ]
}

// MARK: - Color Hex Initializer

extension Color {
    /// Initialize a Color from a hex integer, e.g. `Color(hex: 0xFF0069)`.
    init(hex: UInt, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, opacity: opacity)
    }
}

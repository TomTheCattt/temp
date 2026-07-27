//
//  Extensions.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 20/7/26.
//

import Combine
import Foundation
import SwiftUI

// MARK: - String Extensions

extension String {
    var isValidEmail: Bool {
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return range(of: pattern, options: .regularExpression) != nil
    }

    var digitsOnly: String {
        filter { $0.isNumber }
    }

    var isValidPhone: Bool {
        normalizedPhone() != nil
    }

    func normalizedPhone(languageCode: String? = nil) -> String? {
        let digits = digitsOnly
        let preferred = Locale.preferredLanguages.first.map { String($0.prefix(2)) }
        let lang = (languageCode ?? preferred) ?? "en"

        if lang == "vi" {
            // VN: accept 9-10 local digits, normalize to +84.
            if digits.hasPrefix("84") {
                let local = String(digits.dropFirst(2))
                guard local.count == 9 || local.count == 10 else { return nil }
                return "+84" + local
            }
            if digits.hasPrefix("0") {
                let local = String(digits.dropFirst(1))
                guard local.count == 9 || local.count == 10 else { return nil }
                return "+84" + local
            }
            guard digits.count == 9 || digits.count == 10 else { return nil }
            return "+84" + digits
        }

        // Fallback: accept E.164-ish length and normalize to +<digits>.
        guard digits.count >= 9 && digits.count <= 15 else { return nil }
        return "+" + digits
    }

    var isValidVerificationCode: Bool {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = trimmed.digitsOnly
        return digits.count == 6 && digits.count == trimmed.count
    }

    var isNotEmpty: Bool { !isEmpty }
}

// MARK: - Publisher Extensions

extension Publisher {
    /// Receive on main thread.
    func receiveOnMain() -> Publishers.ReceiveOn<Self, DispatchQueue> {
        receive(on: DispatchQueue.main)
    }
}

// MARK: - View Extensions

extension View {
    /// Dismiss the keyboard from any SwiftUI view.
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

// MARK: - Date Extensions

extension Date {
    /// ISO-8601 string representation.
    var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }
}

// MARK: - JSONDecoder Date Strategy

extension JSONDecoder.DateDecodingStrategy {
    /// Supports both `"2026-04-07T06:26:43Z"` and `"2026-04-07T06:26:43.263Z"` (fractional seconds).
    static var iso8601WithFractionalSeconds: JSONDecoder.DateDecodingStrategy {
        let formatterWithMS = ISO8601DateFormatter()
        formatterWithMS.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let formatterPlain = ISO8601DateFormatter()
        formatterPlain.formatOptions = [.withInternetDateTime]

        return .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = formatterWithMS.date(from: string) { return date }
            if let date = formatterPlain.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date from: \(string)"
            )
        }
    }
}

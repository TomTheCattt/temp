//
//  DateMapper.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - DateMapper

/// Centralized date parsing for DTO → Entity conversion.
enum DateMapper {

    // MARK: - Formatters (cached, thread-safe)

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601FallbackFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    // MARK: - Public

    /// Parse an ISO 8601 date string into a Date.
    /// Tries fractional seconds first, then fallback without.
    /// Returns `.now` if parsing fails (fail-safe for UI display).
    static func toDate(_ string: String) -> Date {
        if let date = iso8601Formatter.date(from: string) {
            return date
        }
        if let date = iso8601FallbackFormatter.date(from: string) {
            return date
        }
        // Last resort: try Unix timestamp
        if let timestamp = Double(string) {
            return Date(timeIntervalSince1970: timestamp)
        }
        return .now
    }

    /// Convert Date to ISO 8601 string (for request payloads).
    static func toString(_ date: Date) -> String {
        iso8601Formatter.string(from: date)
    }
}

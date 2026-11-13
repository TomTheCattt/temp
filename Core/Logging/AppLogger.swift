//
//  AppLogger.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 26/7/26.
//

import Foundation
import OSLog

// MARK: - Log Level

enum LogLevel: String, Sendable, Comparable {
    case debug = "DEBUG"
    case info = "INFO"
    case notice = "NOTICE"
    case warning = "WARNING"
    case error = "ERROR"
    case fault = "FAULT"

    nonisolated var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .notice: return .default
        case .warning: return .default
        case .error: return .error
        case .fault: return .fault
        }
    }

    nonisolated var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .notice: return "📝"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .fault: return "💥"
        }
    }

    nonisolated static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        let order: [LogLevel] = [.debug, .info, .notice, .warning, .error, .fault]
        return (order.firstIndex(of: lhs) ?? 0) < (order.firstIndex(of: rhs) ?? 0)
    }
}

// MARK: - Log Context

struct LogContext: Sendable {
    let file: String
    let function: String
    let line: Int
    let timestamp: Date
    let thread: String

    nonisolated static func current(
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) -> LogContext {
        LogContext(
            file: file,
            function: function,
            line: line,
            timestamp: Date(),
            thread: Thread.isMainThread ? "main" : "bg"
        )
    }

    nonisolated var shortFile: String {
        file.split(separator: "/").last.map(String.init) ?? file
    }

    nonisolated var location: String {
        "\(shortFile):\(line)"
    }
}

// MARK: - AppLogger

struct AppLogger: Sendable {

    // MARK: - Configuration

    nonisolated private static let subsystem = "com.tomthecat.InstagramClone"
    nonisolated private static let minLevel: LogLevel = .debug

    // MARK: - Categories

    nonisolated static let general = AppLogger(category: "General")
    nonisolated static let network = AppLogger(category: "Network")
    nonisolated static let storage = AppLogger(category: "Storage")
    nonisolated static let auth = AppLogger(category: "Auth")
    nonisolated static let ui = AppLogger(category: "UI")
    nonisolated static let websocket = AppLogger(category: "WebSocket")
    nonisolated static let video = AppLogger(category: "Video")
    nonisolated static let cache = AppLogger(category: "Cache")
    nonisolated static let offline = AppLogger(category: "Offline")

    // MARK: - Private

    private let logger: Logger
    private let category: String

    nonisolated private init(category: String) {
        self.category = category
        self.logger = Logger(subsystem: Self.subsystem, category: category)
    }

    // MARK: - Public APIs

    nonisolated func debug(
        _ message: @autoclosure () -> String,
        context: LogContext = .current()
    ) {
        log(message(), level: .debug, context: context)
    }

    nonisolated func info(
        _ message: @autoclosure () -> String,
        context: LogContext = .current()
    ) {
        log(message(), level: .info, context: context)
    }

    nonisolated func notice(
        _ message: @autoclosure () -> String,
        context: LogContext = .current()
    ) {
        log(message(), level: .notice, context: context)
    }

    nonisolated func warning(
        _ message: @autoclosure () -> String,
        context: LogContext = .current()
    ) {
        log(message(), level: .warning, context: context)
    }

    nonisolated func error(
        _ message: @autoclosure () -> String,
        error: Error? = nil,
        context: LogContext = .current()
    ) {
        var msg = message()
        if let error {
            msg += " | error=\(error.localizedDescription)"
        }
        log(msg, level: .error, context: context)
    }

    nonisolated func fault(
        _ message: @autoclosure () -> String,
        error: Error? = nil,
        context: LogContext = .current()
    ) {
        var msg = message()
        if let error {
            msg += " | error=\(error.localizedDescription)"
        }
        log(msg, level: .fault, context: context)
    }

    // MARK: - Structured Logging

    /// Log a structured event with key-value pairs
    nonisolated func event(
        _ name: String,
        level: LogLevel = .info,
        context: LogContext = .current(),
        metadata: [String: Any] = [:]
    ) {
        var message = "event=\(name)"
        if !metadata.isEmpty {
            let metaString = metadata.map { "\($0.key)=\(formatValue($0.value))" }.joined(separator: " ")
            message += " \(metaString)"
        }
        log(message, level: level, context: context)
    }

    /// Log with structured key-value pairs
    nonisolated func log(
        level: LogLevel = .info,
        context: LogContext = .current(),
        _ message: String,
        _ metadata: [String: Any] = [:]
    ) {
        var fullMessage = message
        if !metadata.isEmpty {
            let metaString = metadata.map { "\($0.key)=\(formatValue($0.value))" }.joined(separator: " ")
            fullMessage += " | \(metaString)"
        }
        log(fullMessage, level: level, context: context)
    }

    // MARK: - Network Specific

    /// Log HTTP request with full details
    nonisolated func logRequest(
        _ request: URLRequest,
        context: LogContext = .current(),
        redactHeaders: Set<String> = ["Authorization", "Cookie", "X-API-Key"]
    ) {
        let method = request.httpMethod ?? "UNKNOWN"
        let url = request.url?.absoluteString ?? "unknown"
        let path = request.url?.path ?? "/"

        var metadata: [String: Any] = [
            "method": method,
            "url": url,
            "path": path,
        ]

        // Headers (redacted)
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            let redactedHeaders = redactHeadersRedacting(headers, redact: redactHeaders)
            metadata["headers"] = redactedHeaders
        }

        // Query parameters
        if let query = request.url?.query, !query.isEmpty {
            metadata["query"] = parseQueryString(query)
        }

        // Body
        if let body = request.httpBody, !body.isEmpty {
            if let bodyString = String(data: body, encoding: .utf8) {
                metadata["body"] = parseJSONOrString(bodyString)
            }
        }

        event("http_request", level: .info, context: context, metadata: metadata)
    }

    /// Log HTTP response with full details
    nonisolated func logResponse(
        request: URLRequest?,
        response: HTTPURLResponse?,
        data: Data?,
        error: Error?,
        latency: TimeInterval?,
        context: LogContext = .current()
    ) {
        let method = request?.httpMethod ?? "UNKNOWN"
        let url = request?.url?.absoluteString ?? "unknown"
        let statusCode = response?.statusCode ?? 0
        let isError = error != nil || (statusCode >= 400)

        let level: LogLevel = isError ? .error : .info

        var metadata: [String: Any] = [
            "method": method,
            "url": url,
            "status": statusCode,
        ]

        if let latency {
            metadata["latency_ms"] = Int(latency * 1000)
        }

        if let error {
            metadata["error"] = error.localizedDescription
        }

        // Response headers (limited)
        if let headers = response?.allHeaderFields as? [String: Any], !headers.isEmpty {
            let importantHeaders = headers.filter { key, _ in
                ["Content-Type", "Content-Length", "ETag", "Cache-Control", "Set-Cookie"].contains(key)
            }
            if !importantHeaders.isEmpty {
                metadata["response_headers"] = importantHeaders
            }
        }

        // Response body
        if let data, !data.isEmpty {
            if let bodyString = String(data: data, encoding: .utf8) {
                metadata["response_body"] = parseJSONOrString(bodyString)
            }
        }

        event("http_response", level: level, context: context, metadata: metadata)
    }

    // MARK: - Private

    nonisolated private func log(
        _ message: String,
        level: LogLevel,
        context: LogContext
    ) {
        guard level >= Self.minLevel else { return }

        let prefix = "\(level.emoji) [\(category)]"
        let location = context.location
        let thread = context.thread
        let formattedMessage = "\(prefix) \(location) [\(thread)] → \(message)"

        logger.log(level: level.osLogType, "\(formattedMessage)")
    }

    nonisolated private func formatValue(_ value: Any) -> String {
        if let dict = value as? [String: Any] {
            return dict.map { "\($0.key): \(formatValue($0.value))" }.joined(separator: ", ")
        } else if let array = value as? [Any] {
            return "[\(array.map(formatValue).joined(separator: ", "))]"
        } else if let data = value as? Data {
            if let str = String(data: data, encoding: .utf8) {
                return parseJSONOrString(str)
            }
            return "<binary \(data.count) bytes>"
        } else {
            return String(describing: value)
        }
    }

    nonisolated private func redactHeadersRedacting(_ headers: [String: String], redact: Set<String>) -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in headers {
            if redact.contains(key) {
                if value.count > 8 {
                    result[key] = "\(value.prefix(4))****\(value.suffix(4))"
                } else {
                    result[key] = "****"
                }
            } else {
                result[key] = value
            }
        }
        return result
    }

    nonisolated private func parseQueryString(_ query: String) -> [String: String] {
        var result: [String: String] = [:]
        for pair in query.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                let key = String(parts[0]).removingPercentEncoding ?? String(parts[0])
                let value = String(parts[1]).removingPercentEncoding ?? String(parts[1])
                result[key] = value
            }
        }
        return result
    }

    nonisolated private func parseJSONOrString(_ string: String) -> String {
        if string.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{"),
           let data = string.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return formatValue(json)
        }
        if string.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("["),
           let data = string.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [Any] {
            return formatValue(json)
        }
        return string
    }
}

// MARK: - Pretty JSON Helper

extension AppLogger {
    /// Pretty print JSON data for debugging
    nonisolated func prettyJSON(_ data: Data, context: LogContext = .current()) -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return String(data: data, encoding: .utf8) ?? "<invalid UTF-8>"
        }
        return prettyString
    }

    /// Log pretty JSON
    nonisolated func logJSON(
        _ data: Data,
        label: String = "JSON",
        level: LogLevel = .debug,
        context: LogContext = .current()
    ) {
        let pretty = prettyJSON(data, context: context)
        log("\(label):\n\(pretty)", level: level, context: context)
    }
}

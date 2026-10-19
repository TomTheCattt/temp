//
//  AppLogger.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 26/7/26.
//

import Foundation
import OSLog

struct AppLogger: Sendable {

    nonisolated private static let subsystem = "com.tomthecat.InstagramClone"

    let logger: Logger

    // MARK: - Categories

    nonisolated static let general = AppLogger(category: "General")
    nonisolated static let network = AppLogger(category: "Network")
    nonisolated static let storage = AppLogger(category: "Storage")
    nonisolated static let auth = AppLogger(category: "Auth")
    nonisolated static let ui = AppLogger(category: "UI")

    nonisolated private init(category: String) {
        self.logger = Logger(
            subsystem: Self.subsystem,
            category: category
        )
    }

    // MARK: - Public APIs

    nonisolated func debug(
        _ message: @autoclosure () -> String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(
            message(),
            level: .debug,
            file: file,
            function: function,
            line: line
        )
    }

    nonisolated func info(
        _ message: @autoclosure () -> String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(
            message(),
            level: .info,
            file: file,
            function: function,
            line: line
        )
    }

    nonisolated func notice(
        _ message: @autoclosure () -> String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(
            message(),
            level: .default,
            file: file,
            function: function,
            line: line
        )
    }

    nonisolated func error(
        _ message: @autoclosure () -> String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(
            message(),
            level: .error,
            file: file,
            function: function,
            line: line
        )
    }

    nonisolated func fault(
        _ message: @autoclosure () -> String,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(
            message(),
            level: .fault,
            file: file,
            function: function,
            line: line
        )
    }

    // MARK: - Private

    nonisolated private func log(
        _ message: String,
        level: OSLogType,
        file: String,
        function: String,
        line: Int
    ) {
        logger.log(
            level: level,
            "[\(file):\(line)] \(function) → \(message)"
        )
    }
}

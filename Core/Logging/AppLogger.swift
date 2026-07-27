//
//  AppLogger.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 26/7/26.
//

import Foundation
import OSLog

struct AppLogger {

    private static let subsystem = Bundle.main.bundleIdentifier ?? AppConstants.App.bundleID

    let logger: Logger

    // MARK: - Categories

    static let general = AppLogger(category: "General")
    static let network = AppLogger(category: "Network")
    static let storage = AppLogger(category: "Storage")
    static let auth = AppLogger(category: "Auth")
    static let ui = AppLogger(category: "UI")

    private init(category: String) {
        self.logger = Logger(
            subsystem: Self.subsystem,
            category: category
        )
    }

    // MARK: - Public APIs

    func debug(
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

    func info(
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

    func notice(
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

    func error(
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

    func fault(
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

    private func log(
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

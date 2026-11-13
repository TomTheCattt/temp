//
//  CallDirectoryHandler.swift
//  InstagramCallDirectory
//
//  Created by Kiro on 26/7/26.
//

import Foundation
internal import CallKit
import os.log

// MARK: - CallDirectoryHandler

/// CallKit Call Directory Extension handler.
/// Provides call identification and blocking for incoming calls.
/// This extension runs in a separate process and must be fast (< 3s for identify, < 5s for block).
class CallDirectoryHandler: CXCallDirectoryProvider {

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        // Check if this is an incremental data request
        if context.isIncremental {
            addOrRemoveIncrementalIdentificationPhoneNumbers(to: context)
            addOrRemoveIncrementalBlockingPhoneNumbers(to: context)
        } else {
            // Full reload - add all identification and blocking numbers
            addAllIdentificationPhoneNumbers(to: context)
            addAllBlockingPhoneNumbers(to: context)
        }

        context.completeRequest()
    }

    // MARK: - Identification (Caller ID)

    /// Add all identification phone numbers for full reload.
    /// Identifies incoming calls with custom names (e.g., "Instagram User").
    private func addAllIdentificationPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        // Fetch user's contacts/followers from local storage or shared container
        let identificationEntries = fetchIdentificationEntries()

        for entry in identificationEntries {
            context.addIdentificationEntry(
                withNextSequentialPhoneNumber: entry.phoneNumber,
                label: entry.label
            )
        }

        CallDirectoryLogger.info("CallDirectory: Added \(identificationEntries.count) identification entries")
    }

    /// Add or remove identification entries incrementally.
    private func addOrRemoveIncrementalIdentificationPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        let entriesToAdd = fetchNewIdentificationEntries(since: context)
        let entriesToRemove = fetchRemovedIdentificationEntries(since: context)

        for entry in entriesToAdd {
            context.addIdentificationEntry(
                withNextSequentialPhoneNumber: entry.phoneNumber,
                label: entry.label
            )
        }

        for phoneNumber in entriesToRemove {
            context.removeIdentificationEntry(withPhoneNumber: phoneNumber)
        }

        CallDirectoryLogger.info("CallDirectory: Incremental - Added \(entriesToAdd.count), Removed \(entriesToRemove.count) identification entries")
    }

    // MARK: - Blocking

    /// Add all blocking phone numbers for full reload.
    /// Blocks unwanted calls (spam, blocked users).
    private func addAllBlockingPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        let blockingEntries = fetchBlockingEntries()

        for phoneNumber in blockingEntries {
            context.addBlockingEntry(withNextSequentialPhoneNumber: phoneNumber)
        }

        CallDirectoryLogger.info("CallDirectory: Added \(blockingEntries.count) blocking entries")
    }

    /// Add or remove blocking entries incrementally.
    private func addOrRemoveIncrementalBlockingPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        let numbersToAdd = fetchNewBlockingNumbers(since: context)
        let numbersToRemove = fetchRemovedBlockingNumbers(since: context)

        for phoneNumber in numbersToAdd {
            context.addBlockingEntry(withNextSequentialPhoneNumber: phoneNumber)
        }

        for phoneNumber in numbersToRemove {
            context.removeBlockingEntry(withPhoneNumber: phoneNumber)
        }

        CallDirectoryLogger.info("CallDirectory: Incremental - Added \(numbersToAdd.count), Removed \(numbersToRemove.count) blocking entries")
    }

    // MARK: - Data Fetching (Replace with actual data source)

    /// Fetches identification entries from shared storage.
    /// In production, this reads from App Group shared container with user's contacts/followers.
    private func fetchIdentificationEntries() -> [CallDirectoryEntry] {
        // TODO: Read from App Group shared UserDefaults or database
        // Example structure:
        // let sharedDefaults = UserDefaults(suiteName: "group.com.instagram.app")
        // let data = sharedDefaults?.data(forKey: "callDirectoryIdentification")
        // return decode(data) ?? []

        // Placeholder: Return empty for now
        return []
    }

    /// Fetches blocking entries from shared storage.
    private func fetchBlockingEntries() -> [CXCallDirectoryPhoneNumber] {
        // TODO: Read from App Group shared storage
        // Include: blocked users, reported spam numbers, etc.
        return []
    }

    /// Fetches new identification entries since last incremental update.
    private func fetchNewIdentificationEntries(since context: CXCallDirectoryExtensionContext) -> [CallDirectoryEntry] {
        // TODO: Track last update timestamp and fetch delta
        return []
    }

    /// Fetches removed identification entries since last incremental update.
    private func fetchRemovedIdentificationEntries(since context: CXCallDirectoryExtensionContext) -> [CXCallDirectoryPhoneNumber] {
        return []
    }

    /// Fetches new blocking numbers since last incremental update.
    private func fetchNewBlockingNumbers(since context: CXCallDirectoryExtensionContext) -> [CXCallDirectoryPhoneNumber] {
        return []
    }

    /// Fetches removed blocking numbers since last incremental update.
    private func fetchRemovedBlockingNumbers(since context: CXCallDirectoryExtensionContext) -> [CXCallDirectoryPhoneNumber] {
        return []
    }
}

// MARK: - CXCallDirectoryExtensionContextDelegate

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {

    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        CallDirectoryLogger.error("CallDirectory request failed: \(error.localizedDescription)")

        // If the error is due to memory limit exceeded, we may need to reduce entries
        if let errorCode = (error as NSError).userInfo["ErrorCode"] as? Int,
           errorCode == 1 { // CXErrorCodeCallDirectoryManagerErrorEntriesQuotaExceeded
            CallDirectoryLogger.error("CallDirectory: Entries quota exceeded. Consider reducing entry count.")
        }
    }
}

// MARK: - CallDirectoryEntry

/// Helper struct for identification entries.
private struct CallDirectoryEntry {
    let phoneNumber: CXCallDirectoryPhoneNumber
    let label: String
}

// MARK: - CallDirectoryLogger

/// Minimal logger for CallDirectory extension (runs in separate process).
/// Uses os_log for proper logging.
private enum CallDirectoryLogger {
    static let subsystem = "com.instagram.CallDirectory"
    static let general = OSLog(subsystem: subsystem, category: "general")

    static func info(_ message: String) {
        os_log("%{public}@", log: general, type: .info, message)
    }

    static func error(_ message: String) {
        os_log("%{public}@", log: general, type: .error, message)
    }
}

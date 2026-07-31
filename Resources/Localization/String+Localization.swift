//
//  String+Localization.swift
//  Instagram
//
//  Convenience extensions for localization with String Catalogs (.xcstrings).
//

import SwiftUI

// MARK: - String Extension

extension String {

    /// Returns the localized version of the string using the String Catalog.
    var localized: String {
        String(localized: String.LocalizationValue(self))
    }

    /// Returns a localized string with format arguments.
    ///
    /// Usage:
    ///   "comments.likesCount".localized(with: 42)
    func localized(with arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }
}

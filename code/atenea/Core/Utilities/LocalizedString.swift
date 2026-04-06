//
//  LocalizedString.swift
//  atenea
//
//  Centralized localization helper for the app
//

import Foundation
import SwiftUI

/// Helper function for localized strings with dynamic language support
/// Usage: LocalizedString("key") or L("key")
func LocalizedString(_ key: String, comment: String = "") -> String {
    return LanguageManager.shared.localizedString(key, comment: comment)
}

/// Short alias for LocalizedString
func L(_ key: String, comment: String = "") -> String {
    return LocalizedString(key, comment: comment)
}

/// SwiftUI View that observes language changes and updates automatically
struct LocalizedText: View {
    let key: String
    let comment: String
    @EnvironmentObject var languageManager: LanguageManager

    init(_ key: String, comment: String = "") {
        self.key = key
        self.comment = comment
    }

    var body: some View {
        Text(languageManager.localizedString(key, comment: comment))
    }
}

//
//  LanguageManager.swift
//  atenea
//
//  Manages app language and localization
//

import Foundation
import SwiftUI
internal import Combine

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published var currentLanguage: String = "es"

    private init() {
        // currentLanguage ya es "es" por el valor default de la propiedad
        UserDefaults.standard.set(["es"], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }

    // MARK: - Device Language Detection

    /// Detects the device's preferred language and maps it to available languages
    private func detectDeviceLanguage() -> String {
        // Try to get the saved language preference first
        if let savedLanguages = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String],
           let savedLanguage = savedLanguages.first,
           LanguageManager.availableLanguages.keys.contains(savedLanguage) {
            return savedLanguage
        }

        // Get device's preferred language
        let deviceLanguageCode = Locale.current.language.languageCode?.identifier ?? "en"
        let deviceRegionCode = Locale.current.region?.identifier ?? ""

        print("📱 Device language: \(deviceLanguageCode), Region: \(deviceRegionCode)")

        // Map device language to available languages
        let languageMapping: [String: String] = [
            "en": "en",
            "es": "es",
            "zh": "zh-Hans",
            "hi": "hi",
            "fr": "fr",
            "ar": "ar",
            "bn": "bn",
            "ur": "ur",
            "pt": "pt",
            "id": "id",
            "ru": "ru",
            "de": "de",
            "sw": "sw",
            "mr": "mr",
            "te": "te",
            "ja": "ja",
            "it": "it",
            "ko": "ko",
            "nl": "nl",
            "tr": "tr",
            "pl": "pl",
            "vi": "vi",
            "ta": "ta",
            "fa": "fa",
            "th": "th",
            "el": "el"
        ]

        // Return mapped language or default to English
        return languageMapping[deviceLanguageCode] ?? "en"
    }

    // MARK: - Language Methods

    func setLanguage(_ languageCode: String) {
        currentLanguage = languageCode
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        print("🌐 Language changed to: \(languageCode)")
    }

    func localizedString(_ key: String, comment: String = "") -> String {
        guard let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: comment)
        }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    // MARK: - RTL Language Detection

    func isRTLLanguage() -> Bool {
        let rtlLanguages = ["ar", "he", "fa", "ur"]
        return rtlLanguages.contains(currentLanguage)
    }

    var layoutDirection: LayoutDirection {
        return isRTLLanguage() ? .rightToLeft : .leftToRight
    }

    // MARK: - Country to Language Mapping

    static func languageForCountry(_ country: String) -> String {
        let mapping: [String: String] = [
            // Spanish-speaking countries
            "Mexico": "es",
            "Argentina": "es",
            "Spain": "es",
            "Colombia": "es",
            "Chile": "es",
            "Peru": "es",
            "Ecuador": "es",
            "Uruguay": "es",
            "Venezuela": "es",
            "Paraguay": "es",
            "Bolivia": "es",

            // English-speaking countries
            "United States": "en",
            "Canada": "en",
            "England": "en",
            "United Kingdom": "en",
            "Australia": "en",
            "Nigeria": "en",
            "Ghana": "en",
            "South Africa": "en",
            "Ireland": "en",
            "New Zealand": "en",

            // Portuguese-speaking countries
            "Brazil": "pt",
            "Portugal": "pt",

            // French-speaking countries
            "France": "fr",
            "Belgium": "fr",
            "Morocco": "fr",
            "Senegal": "fr",
            "Ivory Coast": "fr",
            "Cameroon": "fr",

            // German-speaking countries
            "Germany": "de",
            "Austria": "de",
            "Switzerland": "de",

            // Italian-speaking countries
            "Italy": "it",

            // Dutch-speaking countries
            "Netherlands": "nl",

            // Turkish-speaking countries
            "Turkey": "tr",

            // Polish-speaking countries
            "Poland": "pl",

            // Vietnamese-speaking countries
            "Vietnam": "vi",

            // Persian-speaking countries
            "Iran": "fa",

            // Thai-speaking countries
            "Thailand": "th",

            // Greek-speaking countries
            "Greece": "el",

            // Asian countries
            "Japan": "ja",
            "South Korea": "ko",
            "China": "zh-Hans",
            "India": "hi",
            "Indonesia": "id",
            "Russia": "ru",
            "Bangladesh": "bn",
            "Pakistan": "ur"
        ]

        return mapping[country] ?? "en"
    }

    // MARK: - Available Languages

    static let availableLanguages: [String: String] = [
        "en": "English",
        "es": "Español",
        "zh-Hans": "中文",
        "hi": "हिन्दी",
        "fr": "Français",
        "ar": "العربية",
        "bn": "বাংলা",
        "ur": "اردو",
        "pt": "Português",
        "id": "Bahasa Indonesia",
        "ru": "Русский",
        "de": "Deutsch",
        "sw": "Kiswahili",
        "mr": "मराठी",
        "te": "తెలుగు",
        "ja": "日本語",
        "it": "Italiano",
        "ko": "한국어",
        "nl": "Nederlands",
        "tr": "Türkçe",
        "pl": "Polski",
        "vi": "Tiếng Việt",
        "ta": "தமிழ்",
        "fa": "فارسی",
        "th": "ไทย",
        "el": "Ελληνικά"
    ]
}

// MARK: - Environment Key

private struct LanguageManagerKey: EnvironmentKey {
    static let defaultValue = LanguageManager.shared
}

extension EnvironmentValues {
    var languageManager: LanguageManager {
        get { self[LanguageManagerKey.self] }
        set { self[LanguageManagerKey.self] = newValue }
    }
}

// MARK: - View Extension for Easy Access

extension View {
    func languageManager(_ manager: LanguageManager) -> some View {
        environment(\.languageManager, manager)
    }
}

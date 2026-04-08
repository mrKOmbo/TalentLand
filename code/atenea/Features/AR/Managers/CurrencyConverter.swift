//
//  CurrencyConverter.swift
//  atenea
//
//  Conversor de moneda para turistas internacionales
//  Tasas fijas para demo (en producción se usaría una API de tasas en tiempo real)
//

import Foundation

struct CurrencyConverter {
    // Tasas de cambio MXN → moneda destino (fijas para demo, junio 2026 estimadas)
    static let rates: [String: (rate: Double, symbol: String, code: String)] = [
        "en": (0.058, "$", "USD"),        // Estados Unidos
        "ja": (8.7, "¥", "JPY"),          // Japón
        "ko": (77.0, "₩", "KRW"),        // Corea del Sur
        "de": (0.053, "€", "EUR"),        // Alemania
        "fr": (0.053, "€", "EUR"),        // Francia
        "it": (0.053, "€", "EUR"),        // Italia
        "nl": (0.053, "€", "EUR"),        // Países Bajos
        "pt": (0.30, "R$", "BRL"),        // Brasil/Portugal
        "ar": (0.22, "﷼", "SAR"),        // Árabe/Arabia Saudita
        "zh-Hans": (0.42, "¥", "CNY"),   // China
        "hi": (4.85, "₹", "INR"),         // India
        "ru": (5.15, "₽", "RUB"),         // Rusia
        "tr": (1.87, "₺", "TRY"),         // Turquía
        "pl": (0.23, "zł", "PLN"),        // Polonia
        "es": (1.0, "$", "MXN"),          // Español (MXN)
    ]

    /// Convierte precio en MXN a la moneda del idioma actual
    static func convert(_ priceMXN: Double, to languageCode: String) -> String {
        guard languageCode != "es" else {
            return "$\(formatNumber(priceMXN)) MXN"
        }

        guard let info = rates[languageCode] else {
            // Fallback: mostrar en USD
            let usd = priceMXN * 0.058
            return "$\(formatNumber(usd)) USD"
        }

        let converted = priceMXN * info.rate
        return "\(info.symbol)\(formatNumber(converted)) \(info.code)"
    }

    /// Formato de precio dual: moneda local + MXN original
    static func dualPrice(_ priceMXN: Double, languageCode: String) -> (local: String, mxn: String) {
        let mxn = "$\(formatNumber(priceMXN)) MXN"
        if languageCode == "es" {
            return (mxn, "")
        }
        let local = convert(priceMXN, to: languageCode)
        return (local, mxn)
    }

    private static func formatNumber(_ value: Double) -> String {
        if value >= 100 {
            return String(format: "%.0f", value)
        } else if value >= 1 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
}

//
//  BusinessQRService.swift
//  atenea
//
//  Genera URLs y QR codes para páginas web de negocios en komiia.com
//

import UIKit
import CoreImage.CIFilterBuiltins

enum BusinessQRService {

    private static let baseURL = "https://komiia.com/biz"

    // MARK: - URL Generation

    /// Genera la URL web del negocio con datos codificados en base64
    static func businessURL(for merchant: Merchant) -> String {
        let data = businessPayload(for: merchant)

        guard let jsonData = try? JSONSerialization.data(withJSONObject: data),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return baseURL
        }

        let base64 = Data(jsonString.utf8).base64EncodedString()
        return "\(baseURL)?d=\(base64)"
    }

    /// Genera la imagen QR para el negocio
    static func generateQR(for merchant: Merchant, size: CGSize = CGSize(width: 280, height: 280)) -> UIImage? {
        let url = businessURL(for: merchant)
        return QRGeneratorService.generateQRCode(from: url, size: size)
    }

    // MARK: - Payload

    private static func businessPayload(for merchant: Merchant) -> [String: Any] {
        var data: [String: Any] = [
            "id": merchant.id.uuidString,
            "name": merchant.businessName,
            "emoji": merchant.emoji,
            "category": merchant.category.rawValue,
            "isOpen": merchant.isCurrentlyOpen,
            "isStatic": merchant.isStatic
        ]

        if !merchant.description.isEmpty {
            data["description"] = merchant.description
        }

        if let schedule = merchant.schedule {
            data["schedule"] = "\(schedule.openTime) - \(schedule.closeTime)"
        }

        if let location = merchant.currentLocation {
            data["lat"] = location.latitude
            data["lng"] = location.longitude
        }

        // Products (solo disponibles, max 8 para no inflar el QR)
        let availableProducts = merchant.products.filter { $0.isAvailable }.prefix(8)
        if !availableProducts.isEmpty {
            data["products"] = availableProducts.map { product -> [String: Any] in
                var p: [String: Any] = [
                    "name": product.name,
                    "emoji": product.emoji,
                    "price": product.price,
                    "available": product.isAvailable
                ]
                if let desc = product.description {
                    p["desc"] = desc
                }
                return p
            }
        }

        return data
    }
}

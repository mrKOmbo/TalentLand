//
//  BusinessQRService.swift
//  atenea
//
//  Genera URLs y QR codes para páginas web de negocios en komiia.com
//  Los datos se cargan desde Supabase por ID
//

import UIKit
import CoreImage.CIFilterBuiltins

enum BusinessQRService {

    private static let baseURL = "https://komiia.com/biz"

    // MARK: - URL Generation

    /// URL con ID de Supabase — la web consulta los datos desde la DB
    static func businessURL(for merchant: Merchant) -> String {
        let url = "\(baseURL)?id=\(merchant.id.uuidString)"
        print("🔗 [QR] businessURL (ID-only): \(url)")
        return url
    }

    /// Fallback: URL con datos embebidos en base64 (funciona sin internet para la web)
    static func businessURLWithData(for merchant: Merchant) -> String {
        let data = businessPayload(for: merchant)
        print("🔗 [QR] businessURLWithData payload keys: \(data.keys.sorted())")
        print("🔗 [QR] tiene lat/lng: \(data["lat"] != nil && data["lng"] != nil)")
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("🔗 [QR] ERROR: no se pudo serializar payload a JSON")
            return baseURL
        }
        let base64 = Data(jsonString.utf8).base64EncodedString()
        let url = "\(baseURL)?d=\(base64)"
        print("🔗 [QR] businessURLWithData URL length: \(url.count) chars")
        return url
    }

    /// Genera la imagen QR para el negocio (URL corta con ID de Supabase)
    static func generateQR(for merchant: Merchant, size: CGSize = CGSize(width: 280, height: 280)) -> UIImage? {
        print("🔗 [QR] generateQR para: \(merchant.businessName) (id=\(merchant.id.uuidString.prefix(8)))")
        print("🔗 [QR] currentLocation: \(merchant.currentLocation != nil ? "lat=\(merchant.currentLocation!.latitude), lng=\(merchant.currentLocation!.longitude)" : "nil")")
        print("🔗 [QR] productos: \(merchant.products.count), disponibles: \(merchant.products.filter { $0.isAvailable }.count)")
        print("🔗 [QR] schedule: \(merchant.schedule != nil ? "\(merchant.schedule!.openTime)-\(merchant.schedule!.closeTime)" : "nil")")
        let url = businessURL(for: merchant)
        let qrImage = QRGeneratorService.generateQRCode(from: url, size: size)
        print("🔗 [QR] imagen generada: \(qrImage != nil ? "✅ \(Int(qrImage!.size.width))x\(Int(qrImage!.size.height))" : "❌ nil")")
        return qrImage
    }

    // MARK: - Payload (for base64 fallback)

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

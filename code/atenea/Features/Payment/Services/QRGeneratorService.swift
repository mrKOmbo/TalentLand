import UIKit
import CoreImage.CIFilterBuiltins

enum QRGeneratorService {

    static func generateQRCode(from string: String, size: CGSize = CGSize(width: 250, height: 250)) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        filter.message = Data(string.utf8)
        filter.correctionLevel = "H" // Alta tolerancia a errores (30%)

        guard let ciImage = filter.outputImage else { return nil }

        // Escalar para alta resolución
        let scaleX = size.width / ciImage.extent.size.width
        let scaleY = size.height / ciImage.extent.size.height
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }
}

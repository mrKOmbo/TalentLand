import Foundation
import UIKit
import MapboxMaps
import CoreLocation

enum DemandHeatmapBuilder {

    static let sourceId = "demand-heatmap-source"
    static let glowLayerId = "demand-glow-layer"
    static let circleLayerId = "demand-circle-layer"
    static let symbolLayerId = "demand-symbol-layer"

    // MARK: - Generar puntos simulados de multitudes

    static func generateCrowdFeatures(around center: CLLocationCoordinate2D) -> FeatureCollection {
        var features: [Feature] = []

        let categories: [(cat: String, emoji: String)] = [
            ("tacos", "🌮"), ("bebidas", "🥤"), ("tamales", "🫔"),
            ("elotes", "🌽"), ("helados", "🍦"), ("jugos", "🧃"),
            ("frutas", "🍎"), ("antojitos", "🍽️"), ("postres", "🧁")
        ]

        // Muchos hotspots con alta densidad para cobertura total
        let hotspots: [(dLat: Double, dLon: Double, density: Int, spread: Double)] = [
            // Centro Expo — densidad máxima
            (0.0000,  0.0000,  60, 0.0012),
            (0.0004, -0.0003,  40, 0.0010),
            (-0.0003, 0.0004,  40, 0.0010),
            (0.0003,  0.0005,  35, 0.0010),
            (-0.0005,-0.0003,  35, 0.0010),
            // Entradas — alta densidad
            (0.0012,  0.0000,  30, 0.0010),
            (-0.0010, 0.0000,  28, 0.0010),
            (0.0000,  0.0012,  28, 0.0010),
            (0.0000, -0.0012,  25, 0.0010),
            // Estacionamientos
            (0.0018,  0.0005,  20, 0.0012),
            (-0.0015,-0.0008,  18, 0.0012),
            (0.0015, -0.0010,  16, 0.0010),
            // Av. Santa Fe
            (0.0005,  0.0025,  25, 0.0014),
            (0.0008,  0.0040,  18, 0.0012),
            (-0.0003, 0.0030,  15, 0.0012),
            (0.0000,  0.0050,  10, 0.0010),
            // Vasco de Quiroga
            (0.0005, -0.0025,  22, 0.0014),
            (0.0010, -0.0040,  15, 0.0012),
            (-0.0005,-0.0035,  12, 0.0010),
            // Centro comercial Santa Fe
            (0.0028,  0.0015,  30, 0.0016),
            (0.0035,  0.0010,  20, 0.0014),
            (0.0022,  0.0025,  15, 0.0012),
            // Tec de Monterrey
            (-0.0022,-0.0012,  22, 0.0014),
            (-0.0028,-0.0005,  14, 0.0012),
            // Corporativos
            (0.0012,  0.0045,  12, 0.0012),
            (-0.0018, 0.0025,  10, 0.0010),
            (0.0020, -0.0020,  10, 0.0010),
            // Periferia — baja densidad
            (0.0045,  0.0000,  8,  0.0014),
            (-0.0040, 0.0020,  7,  0.0014),
            (0.0000,  0.0060,  6,  0.0012),
            (0.0000, -0.0055,  6,  0.0012),
            (0.0050,  0.0030,  5,  0.0012),
            (-0.0045,-0.0025,  5,  0.0012),
        ]

        for hotspot in hotspots {
            let baseLat = center.latitude + hotspot.dLat
            let baseLon = center.longitude + hotspot.dLon

            for _ in 0..<hotspot.density {
                let lat = baseLat + Double.random(in: -hotspot.spread...hotspot.spread)
                let lon = baseLon + Double.random(in: -hotspot.spread...hotspot.spread)
                let cat = categories.randomElement()!
                let distFromCenter = abs(hotspot.dLat) + abs(hotspot.dLon)
                let baseIntensity = max(0.2, 1.0 - distFromCenter * 120)
                let intensity = baseIntensity * Double.random(in: 0.5...1.0)

                var feature = Feature(geometry: .point(Point(
                    LocationCoordinate2D(latitude: lat, longitude: lon)
                )))
                feature.properties = [
                    "intensity": .number(intensity),
                    "category": .string(cat.cat),
                    "emoji": .string(cat.emoji)
                ]
                features.append(feature)
            }
        }

        return FeatureCollection(features: features)
    }

    // MARK: - Capa de calor — círculos muy grandes con blur total (efecto continuo)

    static func makeGlowLayer() -> CircleLayer {
        var layer = CircleLayer(id: glowLayerId, source: sourceId)

        // Círculos enormes que se funden entre sí
        layer.circleRadius = .expression(
            Exp(.interpolate) {
                Exp(.linear)
                Exp(.zoom)
                10; 15.0
                13; 40.0
                15; 70.0
                17; 100.0
                19; 140.0
            }
        )

        // Gradiente de color: amarillo → naranja → rojo según intensidad
        layer.circleColor = .expression(
            Exp(.interpolate) {
                Exp(.linear)
                Exp(.get) { "intensity" }
                0.0; "rgba(80, 200, 180, 0.25)"
                0.25; "rgba(200, 220, 50, 0.35)"
                0.45; "rgba(255, 180, 30, 0.45)"
                0.65; "rgba(255, 120, 20, 0.55)"
                0.85; "rgba(230, 60, 15, 0.65)"
                1.0; "rgba(180, 20, 10, 0.75)"
            }
        )

        // Blur máximo — sin bordes visibles, todo difuso
        layer.circleBlur = .constant(1.0)

        layer.circleOpacity = .expression(
            Exp(.interpolate) {
                Exp(.linear)
                Exp(.zoom)
                10; 0.5
                14; 0.6
                16; 0.55
                18; 0.4
            }
        )

        layer.circleEmissiveStrength = .constant(1.0)

        return layer
    }

    // MARK: - Puntos pequeños (solo zoom muy alto)

    static func makeCircleLayer() -> CircleLayer {
        var layer = CircleLayer(id: circleLayerId, source: sourceId)
        layer.minZoom = 16.0

        layer.circleRadius = .constant(3.0)

        layer.circleColor = .expression(
            Exp(.interpolate) {
                Exp(.linear)
                Exp(.get) { "intensity" }
                0.0; "rgba(255, 200, 80, 0.7)"
                0.5; "rgba(255, 120, 30, 0.8)"
                1.0; "rgba(200, 30, 10, 0.9)"
            }
        )

        layer.circleStrokeColor = .constant(StyleColor(UIColor.white.withAlphaComponent(0.5)))
        layer.circleStrokeWidth = .constant(0.5)

        layer.circleOpacity = .expression(
            Exp(.interpolate) {
                Exp(.linear)
                Exp(.zoom)
                16; 0.0
                17; 0.5
                18; 0.7
            }
        )

        layer.circleEmissiveStrength = .constant(1.0)

        return layer
    }

    // MARK: - Emojis (solo zoom muy alto)

    static func makeSymbolLayer() -> SymbolLayer {
        var layer = SymbolLayer(id: symbolLayerId, source: sourceId)
        layer.minZoom = 17.0

        layer.textField = .expression(Exp(.get) { "emoji" })
        layer.textSize = .constant(14)
        layer.textAllowOverlap = .constant(false)
        layer.textOpacity = .expression(
            Exp(.interpolate) {
                Exp(.linear)
                Exp(.zoom)
                17; 0.0
                18; 0.8
            }
        )

        layer.textEmissiveStrength = .constant(1.0)

        return layer
    }

    // MARK: - Source

    static func makeSource(with featureCollection: FeatureCollection) -> GeoJSONSource {
        var source = GeoJSONSource(id: sourceId)
        source.data = .featureCollection(featureCollection)
        return source
    }
}

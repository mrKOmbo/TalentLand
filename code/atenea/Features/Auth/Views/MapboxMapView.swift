//
//  MapboxMapView.swift
//  Atenea
//
//  Mapbox map for route selection with real-time preview
//

import SwiftUI
import MapboxMaps
import CoreLocation

struct MapboxMapView: UIViewRepresentable {
    @Binding var waypoints: [RouteWaypoint]
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var routeCoordinates: [CLLocationCoordinate2D]
    let isMobileBusinesse: Bool
    let onMapTap: (CLLocationCoordinate2D) -> Void
    @Binding var centerOnUserLocation: Bool
    @Binding var approachRouteCoordinates: [CLLocationCoordinate2D]

    func makeUIView(context: Context) -> MapView {
        let mapView = MapView(frame: .zero)
        mapView.mapboxMap.styleURI = .streets

        // Habilitar puck de ubicación del usuario
        mapView.location.options.puckType = .puck2D()
        mapView.location.options.puckBearingEnabled = true

        // Set initial camera to Mexico City
        let mexicoCity = CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332)
        let cameraOptions = CameraOptions(center: mexicoCity, zoom: 12)
        mapView.mapboxMap.setCamera(to: cameraOptions)

        // Enable all map gestures for navigation
        mapView.gestures.options.panEnabled = true
        mapView.gestures.options.pinchEnabled = true
        mapView.gestures.options.rotateEnabled = true
        mapView.gestures.options.pitchEnabled = true
        mapView.gestures.options.doubleTapToZoomInEnabled = true
        mapView.gestures.options.doubleTouchToZoomOutEnabled = true
        mapView.gestures.options.quickZoomEnabled = true

        // Add long press gesture (more intentional than tap)
        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressGesture)

        // Add custom double tap gesture that won't interfere with zoom
        let doubleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        // This will run AFTER the built-in zoom gesture
        doubleTapGesture.delaysTouchesBegan = false
        doubleTapGesture.delaysTouchesEnded = false
        // Don't add double tap - it conflicts with zoom
        // mapView.addGestureRecognizer(doubleTapGesture)

        context.coordinator.mapView = mapView

        return mapView
    }

    func updateUIView(_ mapView: MapView, context: Context) {
        context.coordinator.updateAnnotations(waypoints: waypoints, selectedCoordinate: selectedCoordinate, isMobileBusinesse: isMobileBusinesse)
        context.coordinator.updateRoute(coordinates: routeCoordinates)
        context.coordinator.updateApproachRoute(coordinates: approachRouteCoordinates)

        if centerOnUserLocation {
            DispatchQueue.main.async {
                centerOnUserLocation = false
            }
            if let userLoc = mapView.location.latestLocation?.coordinate {
                let camera = CameraOptions(center: userLoc, zoom: 15.5)
                mapView.camera.ease(to: camera, duration: 0.8)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onMapTap: onMapTap)
    }

    class Coordinator: NSObject {
        var mapView: MapView?
        let onMapTap: (CLLocationCoordinate2D) -> Void
        private var pointAnnotationManager: PointAnnotationManager?
        private var routeLayerId = "route-layer"
        private var routeSourceId = "route-source"
        private var approachLayerId = "approach-layer"
        private var approachSourceId = "approach-source"

        init(onMapTap: @escaping (CLLocationCoordinate2D) -> Void) {
            self.onMapTap = onMapTap
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began else { return }
            guard let mapView = mapView else { return }

            let point = gesture.location(in: mapView)
            let coordinate = mapView.mapboxMap.coordinate(for: point)

            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            onMapTap(coordinate)
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = mapView else { return }

            let point = gesture.location(in: mapView)
            let coordinate = mapView.mapboxMap.coordinate(for: point)

            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

            onMapTap(coordinate)
        }

        func updateAnnotations(waypoints: [RouteWaypoint], selectedCoordinate: CLLocationCoordinate2D?, isMobileBusinesse: Bool) {
            guard let mapView = mapView else { return }

            // Create or reuse annotation manager
            if pointAnnotationManager == nil {
                pointAnnotationManager = mapView.annotations.makePointAnnotationManager()
            }

            guard let manager = pointAnnotationManager else { return }

            // Clear existing annotations
            manager.annotations = []

            if isMobileBusinesse {
                // Add waypoint markers with custom circle images
                for (index, waypoint) in waypoints.enumerated() {
                    // Create numbered marker image
                    let markerImage = createNumberedMarker(number: index + 1)
                    let imageName = "marker-\(index + 1)"

                    // Add image to map style if not already added
                    if let image = markerImage {
                        try? mapView.mapboxMap.addImage(image, id: imageName)
                    }

                    var annotation = PointAnnotation(coordinate: waypoint.coordinate)
                    annotation.image = .init(image: markerImage ?? UIImage(), name: imageName)
                    annotation.iconAnchor = .center
                    annotation.iconSize = 1.0

                    manager.annotations.append(annotation)
                }
            } else {
                // Add single location marker
                if let coordinate = selectedCoordinate {
                    let pinImage = createPinMarker()
                    let imageName = "location-pin"

                    if let image = pinImage {
                        try? mapView.mapboxMap.addImage(image, id: imageName)
                    }

                    var annotation = PointAnnotation(coordinate: coordinate)
                    annotation.image = .init(image: pinImage ?? UIImage(), name: imageName)
                    annotation.iconAnchor = .bottom
                    annotation.iconSize = 1.0

                    manager.annotations.append(annotation)
                }
            }
        }

        private func createNumberedMarker(number: Int) -> UIImage? {
            let size = CGSize(width: 50, height: 50)
            let renderer = UIGraphicsImageRenderer(size: size)

            return renderer.image { context in
                // Draw purple circle
                let circle = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size.width, height: size.height))
                UIColor.systemPurple.setFill()
                circle.fill()

                // Draw white border
                UIColor.white.setStroke()
                circle.lineWidth = 3
                circle.stroke()

                // Draw number
                let numberString = "\(number)" as NSString
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                    .foregroundColor: UIColor.white
                ]

                let textSize = numberString.size(withAttributes: attributes)
                let textRect = CGRect(
                    x: (size.width - textSize.width) / 2,
                    y: (size.height - textSize.height) / 2,
                    width: textSize.width,
                    height: textSize.height
                )

                numberString.draw(in: textRect, withAttributes: attributes)
            }
        }

        private func createPinMarker() -> UIImage? {
            let size = CGSize(width: 20, height: 40)
            let renderer = UIGraphicsImageRenderer(size: size)

            return renderer.image { context in
                // Draw pin shape
                let pinPath = UIBezierPath()
                pinPath.move(to: CGPoint(x: size.width / 2, y: size.height))
                pinPath.addLine(to: CGPoint(x: size.width / 2 - 5, y: size.height - 15))
                pinPath.addArc(
                    withCenter: CGPoint(x: size.width / 2, y: 20),
                    radius: 20,
                    startAngle: .pi + 0.3,
                    endAngle: -0.3,
                    clockwise: true
                )
                pinPath.close()

                UIColor.systemPurple.setFill()
                pinPath.fill()

                UIColor.white.setStroke()
                pinPath.lineWidth = 2
                pinPath.stroke()
            }
        }

        func updateRoute(coordinates: [CLLocationCoordinate2D]) {
            guard let mapView = mapView else { return }

            // Remove existing route layer and source
            if mapView.mapboxMap.layerExists(withId: routeLayerId) {
                try? mapView.mapboxMap.removeLayer(withId: routeLayerId)
            }
            if mapView.mapboxMap.sourceExists(withId: routeSourceId) {
                try? mapView.mapboxMap.removeSource(withId: routeSourceId)
            }

            // Only add route if we have coordinates
            guard !coordinates.isEmpty else { return }

            // Create LineString from coordinates
            let lineString = LineString(coordinates.map { LocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) })
            let feature = Feature(geometry: .lineString(lineString))

            // Create GeoJSON source
            var source = GeoJSONSource(id: routeSourceId)
            source.data = .feature(feature)

            // Create line layer
            var lineLayer = LineLayer(id: routeLayerId, source: routeSourceId)
            lineLayer.lineColor = .constant(StyleColor(UIColor.systemPurple))
            lineLayer.lineWidth = .constant(5)
            lineLayer.lineCap = .constant(.round)
            lineLayer.lineJoin = .constant(.round)
            lineLayer.lineOpacity = .constant(0.8)

            // Add source and layer
            try? mapView.mapboxMap.addSource(source)
            try? mapView.mapboxMap.addLayer(lineLayer)

            // Fit camera to show entire route
            fitCameraToRoute(coordinates: coordinates)
        }

        private func fitCameraToRoute(coordinates: [CLLocationCoordinate2D]) {
            guard let mapView = mapView, !coordinates.isEmpty else { return }

            // Calculate center and zoom
            var minLat = coordinates[0].latitude
            var maxLat = coordinates[0].latitude
            var minLon = coordinates[0].longitude
            var maxLon = coordinates[0].longitude

            for coord in coordinates {
                minLat = min(minLat, coord.latitude)
                maxLat = max(maxLat, coord.latitude)
                minLon = min(minLon, coord.longitude)
                maxLon = max(maxLon, coord.longitude)
            }

            // Calculate center point
            let centerLat = (minLat + maxLat) / 2
            let centerLon = (minLon + maxLon) / 2
            let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)

            // Calculate appropriate zoom level
            let latDelta = maxLat - minLat
            let lonDelta = maxLon - minLon
            let delta = max(latDelta, lonDelta)

            // Simple zoom calculation
            var zoom: Double = 15
            if delta > 0.1 {
                zoom = 10
            } else if delta > 0.05 {
                zoom = 12
            } else if delta > 0.01 {
                zoom = 14
            }

            let cameraOptions = CameraOptions(
                center: center,
                zoom: zoom,
                bearing: 0,
                pitch: 0
            )

            mapView.camera.ease(to: cameraOptions, duration: 0.5)
        }

        func updateApproachRoute(coordinates: [CLLocationCoordinate2D]) {
            guard let mapView = mapView else { return }

            // Limpiar approach route previo
            if mapView.mapboxMap.layerExists(withId: approachLayerId) {
                try? mapView.mapboxMap.removeLayer(withId: approachLayerId)
            }
            if mapView.mapboxMap.sourceExists(withId: approachSourceId) {
                try? mapView.mapboxMap.removeSource(withId: approachSourceId)
            }

            guard !coordinates.isEmpty else { return }

            let lineString = LineString(coordinates.map { LocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) })
            let feature = Feature(geometry: .lineString(lineString))

            var source = GeoJSONSource(id: approachSourceId)
            source.data = .feature(feature)

            var lineLayer = LineLayer(id: approachLayerId, source: approachSourceId)
            lineLayer.lineColor = .constant(StyleColor(UIColor.systemOrange))
            lineLayer.lineWidth = .constant(4)
            lineLayer.lineCap = .constant(.round)
            lineLayer.lineJoin = .constant(.round)
            lineLayer.lineOpacity = .constant(0.85)
            lineLayer.lineDasharray = .constant([2, 1.5])

            try? mapView.mapboxMap.addSource(source)
            try? mapView.mapboxMap.addLayer(lineLayer)
        }
    }
}

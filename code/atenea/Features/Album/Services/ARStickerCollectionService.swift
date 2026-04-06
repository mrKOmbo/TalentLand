//
//  ARStickerCollectionService.swift
//  Atenea
//
//  Created by Claude on 10/15/25.
//

import Foundation
import ARKit
import CoreLocation
import SwiftUI
internal import Combine

// MARK: - AR Collection Manager
class ARStickerCollectionService: NSObject, ObservableObject {

    @Published var isARAvailable: Bool = false
    @Published var nearbyVenues: [WorldCupVenue] = []
    @Published var currentVenue: WorldCupVenue?
    @Published var canCollectSticker: Bool = false
    @Published var collectionRadius: CLLocationDistance = 500 // metros
    @Published var showARScanner: Bool = false
    @Published var lastCollectedSticker: Int?
    @Published var showCollectionAnimation: Bool = false

    // MARK: - AR Image Detection Properties
    @Published var stickerCOPADetected: Bool = false
    @Published var reversoStickerCOPADetected: Bool = false
    @Published var showAddToAlbumButton: Bool = false
    @Published var showFlipAnimation: Bool = false
    @Published var canNavigateToAlbum: Bool = false
    @Published var stickerAddedToAlbum: Bool = false
    @Published var detectedImageName: String?

    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?

    // Singletons
    static let shared = ARStickerCollectionService()

    override init() {
        super.init()
        checkARAvailability()
        setupLocationManager()
    }

    // MARK: - AR Availability Check
    private func checkARAvailability() {
        isARAvailable = ARWorldTrackingConfiguration.isSupported
    }

    // MARK: - Location Manager Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update cada 10 metros

        // Request permission
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }

        locationManager.startUpdatingLocation()
    }

    // MARK: - Check Nearby Venues
    func checkNearbyVenues(userLocation: CLLocation) {
        let allVenues = WorldCupVenue.allVenues

        nearbyVenues = allVenues.filter { venue in
            let venueLocation = CLLocation(
                latitude: venue.coordinate.latitude,
                longitude: venue.coordinate.longitude
            )
            let distance = userLocation.distance(from: venueLocation)
            return distance <= collectionRadius
        }

        // Encontrar la sede más cercana
        if let closest = nearbyVenues.min(by: { venue1, venue2 in
            let loc1 = CLLocation(latitude: venue1.coordinate.latitude, longitude: venue1.coordinate.longitude)
            let loc2 = CLLocation(latitude: venue2.coordinate.latitude, longitude: venue2.coordinate.longitude)
            return userLocation.distance(from: loc1) < userLocation.distance(from: loc2)
        }) {
            currentVenue = closest

            let venueLocation = CLLocation(
                latitude: closest.coordinate.latitude,
                longitude: closest.coordinate.longitude
            )
            let distance = userLocation.distance(from: venueLocation)

            // Permitir coleccionar si está a menos de 100 metros
            canCollectSticker = distance <= 100
        } else {
            currentVenue = nil
            canCollectSticker = false
        }
    }

    // MARK: - Collect Sticker via AR
    func collectStickerForVenue(_ venue: WorldCupVenue, collectionManager: StickerCollectionManager) {
        // Calcular qué sticker corresponde a esta sede
        let venueIndex = WorldCupVenue.allVenues.firstIndex(where: { $0.id == venue.id }) ?? 0

        // Cada sede tiene 1 sticker (el de la sede)
        // Empiezan en sticker #14 (después de intro)
        let stickerId = 14 + venueIndex

        // Coleccionar solo el sticker de la sede
        collectionManager.collectSticker(stickerId)

        // Guardar el último coleccionado para animación
        lastCollectedSticker = stickerId

        // Mostrar animación
        withAnimation {
            showCollectionAnimation = true
        }

        // Ocultar animación después de 3 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                self.showCollectionAnimation = false
            }
        }

        // Enviar notificación
        sendCollectionNotification(venue: venue)
    }

    // MARK: - Send Notification
    private func sendCollectionNotification(venue: WorldCupVenue) {
        // Trigger haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Aquí podrías agregar notificaciones push locales
        print("✅ Stickers coleccionados para: \(venue.name)")
    }

    // MARK: - Distance String
    func distanceString(to venue: WorldCupVenue) -> String {
        guard let userLocation = currentLocation else {
            return "Ubicación desconocida"
        }

        let venueLocation = CLLocation(
            latitude: venue.coordinate.latitude,
            longitude: venue.coordinate.longitude
        )

        let distance = userLocation.distance(from: venueLocation)

        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension ARStickerCollectionService: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location

        // Check nearby venues
        checkNearbyVenues(userLocation: location)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("❌ Permiso de ubicación denegado")
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Error de ubicación: \(error.localizedDescription)")
    }
}

// MARK: - AR Session Configuration
extension ARStickerCollectionService {

    func createARConfiguration() -> ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()

        // Habilitar tracking de planos (opcional)
        configuration.planeDetection = [.horizontal, .vertical]

        // Habilitar scene reconstruction si está disponible
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }

        // Configurar detección de imágenes
        if let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) {
            configuration.detectionImages = referenceImages
            configuration.maximumNumberOfTrackedImages = 2
            print("✅ AR Reference Images configuradas: \(referenceImages.count)")
        } else {
            print("⚠️ No se encontraron AR Reference Images")
        }

        return configuration
    }
}

// MARK: - Image Detection Handling
extension ARStickerCollectionService {

    func handleImageDetection(_ imageName: String, transform: simd_float4x4) {
        print("🖼️ Imagen detectada: \(imageName)")
        detectedImageName = imageName

        if imageName == "stickerCOPA" {
            DispatchQueue.main.async {
                self.stickerCOPADetected = true
                // Solo mostrar botón si aún no se ha agregado al álbum
                if !self.stickerAddedToAlbum {
                    self.showAddToAlbumButton = true
                    print("✅ stickerCOPA detectado - Mostrando botón 'Agregar al Album'")
                }
            }
        } else if imageName == "reversoStickerCOPA" {
            DispatchQueue.main.async {
                self.reversoStickerCOPADetected = true
                print("✅ reversoStickerCOPA detectado")

                // Solo permitir navegación si ya se agregó al álbum
                if self.stickerAddedToAlbum {
                    self.showFlipAnimation = false
                    self.canNavigateToAlbum = true
                    print("✅ Ambas imágenes detectadas - Permitiendo navegación al álbum")
                }
            }
        }
    }

    func addStickerToAlbum() {
        guard stickerCOPADetected else {
            print("⚠️ No se puede agregar - stickerCOPA no detectado")
            return
        }

        print("📝 Agregando sticker al álbum")
        stickerAddedToAlbum = true
        showAddToAlbumButton = false
        showFlipAnimation = true

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Verificar si el reverso ya fue detectado
        if reversoStickerCOPADetected {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showFlipAnimation = false
                self.canNavigateToAlbum = true
                print("✅ Reverso ya detectado - Permitiendo navegación inmediata")
            }
        }
    }

    func resetDetection() {
        stickerCOPADetected = false
        reversoStickerCOPADetected = false
        showAddToAlbumButton = false
        showFlipAnimation = false
        canNavigateToAlbum = false
        stickerAddedToAlbum = false
        detectedImageName = nil
        print("🔄 Detección resetada")
    }
}

// MARK: - Mock Data para Testing sin AR
extension ARStickerCollectionService {

    // Simular colección para testing sin estar físicamente en la sede
    func simulateCollection(for venue: WorldCupVenue, collectionManager: StickerCollectionManager) {
        #if DEBUG
        print("🧪 [DEBUG] Simulando colección para: \(venue.name)")
        collectStickerForVenue(venue, collectionManager: collectionManager)
        #endif
    }

    // Simular estar cerca de una sede
    func simulateNearVenue(_ venue: WorldCupVenue) {
        #if DEBUG
        currentVenue = venue
        nearbyVenues = [venue]
        canCollectSticker = true
        print("🧪 [DEBUG] Simulando estar cerca de: \(venue.name)")
        #endif
    }
}

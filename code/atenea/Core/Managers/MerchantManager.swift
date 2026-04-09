//
//  MerchantManager.swift
//  atenea
//
//  Gestor de comerciantes y sus productos
//

import Foundation
internal import Combine
import CoreLocation

class MerchantManager: ObservableObject {
    static let shared = MerchantManager()

    @Published var merchants: [Merchant] = []
    @Published var currentMerchantProfile: Merchant?

    private init() {
        loadMockMerchants()
        syncMocksToSupabaseIfNeeded()
    }

    /// Sync mock merchants to Supabase once on first launch
    private func syncMocksToSupabaseIfNeeded() {
        let key = "hasSyncedMocksToSupabase"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        Task {
            await SupabaseService.shared.syncAllMerchants(merchants)
            UserDefaults.standard.set(true, forKey: key)
        }
    }

    /// Vincular perfil de merchant para el usuario actual (llamar después de login/restore)
    func linkCurrentUserProfile() {
        guard let user = UserManager.shared.currentUser, user.isMerchant else { return }
        currentMerchantProfile = merchantForUser(user.id)
        print("🏪 Perfil vinculado: \(currentMerchantProfile?.businessName ?? "nil")")
    }

    // MARK: - Queries

    func merchantForUser(_ userId: UUID) -> Merchant? {
        merchants.first { $0.userId == userId }
    }

    func activeMerchants() -> [Merchant] {
        merchants.filter { $0.isActive }
    }

    func merchant(byId id: UUID) -> Merchant? {
        merchants.first { $0.id == id }
    }

    func merchantsNear(latitude: Double, longitude: Double, radiusMeters: Double = 1000) -> [Merchant] {
        activeMerchants().filter { merchant in
            guard let loc = merchant.currentLocation else { return false }
            let distance = Self.haversineDistance(
                lat1: latitude, lon1: longitude,
                lat2: loc.latitude, lon2: loc.longitude
            )
            return distance <= radiusMeters
        }
        .sorted { a, b in
            guard let locA = a.currentLocation, let locB = b.currentLocation else { return false }
            let distA = Self.haversineDistance(lat1: latitude, lon1: longitude, lat2: locA.latitude, lon2: locA.longitude)
            let distB = Self.haversineDistance(lat1: latitude, lon1: longitude, lat2: locB.latitude, lon2: locB.longitude)
            return distA < distB
        }
    }

    // MARK: - Mutations

    func toggleActive(merchantId: UUID) {
        print("🏪 [toggleActive] merchantId=\(merchantId)")
        guard let index = merchants.firstIndex(where: { $0.id == merchantId }) else {
            print("🏪 [toggleActive] ERROR: merchant no encontrado en array")
            return
        }
        let antes = merchants[index].isActive
        merchants[index].isActive.toggle()
        let despues = merchants[index].isActive
        print("🏪 [toggleActive] isActive: \(antes) → \(despues)")
        if merchants[index].id == currentMerchantProfile?.id {
            currentMerchantProfile = merchants[index]
            print("🏪 [toggleActive] currentMerchantProfile actualizado, isActive=\(currentMerchantProfile?.isActive ?? false)")
        } else {
            print("🏪 [toggleActive] No coincide con currentMerchantProfile")
        }

        // Sync status to Supabase
        Task {
            try? await SupabaseService.shared.updateMerchantStatus(merchantId: merchantId, isActive: despues)
        }
    }

    func updateLocation(merchantId: UUID, latitude: Double, longitude: Double) {
        guard let index = merchants.firstIndex(where: { $0.id == merchantId }) else { return }
        merchants[index].currentLocation = MerchantLocation(latitude: latitude, longitude: longitude)
        if merchants[index].id == currentMerchantProfile?.id {
            currentMerchantProfile = merchants[index]
        }

        // Sync location to Supabase
        Task {
            try? await SupabaseService.shared.updateMerchantLocation(merchantId: merchantId, latitude: latitude, longitude: longitude)
        }
    }

    // MARK: - Convenience

    func distanceFrom(latitude: Double, longitude: Double, to merchant: Merchant) -> Double? {
        guard let loc = merchant.currentLocation else { return nil }
        return Self.haversineDistance(lat1: latitude, lon1: longitude, lat2: loc.latitude, lon2: loc.longitude)
    }

    func formattedDistance(meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            return String(format: "%.1fkm", meters / 1000)
        }
    }

    /// Convierte merchants a NearbyMerchant para display en HomeView
    func nearbyMerchantsList(fromLatitude lat: Double, longitude lon: Double, radius: Double = 5000) -> [NearbyMerchant] {
        merchantsNear(latitude: lat, longitude: lon, radiusMeters: radius).map { merchant in
            let dist = distanceFrom(latitude: lat, longitude: lon, to: merchant) ?? 0
            return NearbyMerchant(
                emoji: merchant.emoji,
                name: merchant.businessName,
                distance: formattedDistance(meters: dist),
                isActive: merchant.isActive,
                isStatic: merchant.isStatic,
                category: merchant.category.displayName,
                coordinate: merchant.currentLocation?.coordinate ?? CLLocationCoordinate2D()
            )
        }
    }

    // MARK: - Haversine

    static func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371000.0 // Radio de la Tierra en metros
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }

    // MARK: - Register New Merchant

    func registerMerchant(
        userId: UUID,
        businessName: String,
        businessType: BusinessType,
        isStatic: Bool,
        location: BusinessLocation?,
        route: MerchantRoute?,
        waypoints: [RouteWaypoint]?
    ) {
        let category = Self.merchantCategory(from: businessType)

        let merchantLocation: MerchantLocation?
        if let loc = location {
            merchantLocation = MerchantLocation(latitude: loc.latitude, longitude: loc.longitude)
        } else if let firstWaypoint = waypoints?.first {
            merchantLocation = MerchantLocation(latitude: firstWaypoint.latitude, longitude: firstWaypoint.longitude)
        } else {
            merchantLocation = nil
        }

        let merchantRoute: MerchantRoute?
        if !isStatic, let waypoints = waypoints, waypoints.count >= 2 {
            merchantRoute = route ?? MerchantRoute(
                merchantId: userId,
                waypoints: waypoints,
                isActive: true
            )
        } else {
            merchantRoute = nil
        }

        let merchant = Merchant(
            userId: userId,
            businessName: businessName,
            category: category,
            isActive: true,
            isStatic: isStatic,
            currentLocation: merchantLocation,
            route: merchantRoute
        )

        merchants.append(merchant)
        currentMerchantProfile = merchant
        print("✅ Merchant registrado en MerchantManager: \(businessName)")

        // Subir a Supabase automáticamente
        Task {
            do {
                let supabaseId = try await SupabaseService.shared.saveMerchant(merchant)
                print("☁️ Merchant sincronizado con Supabase: \(supabaseId)")
            } catch {
                print("⚠️ Error subiendo merchant a Supabase: \(error.localizedDescription)")
            }
        }
    }

    private static func merchantCategory(from businessType: BusinessType) -> MerchantCategory {
        switch businessType {
        case .food: return .tacos
        case .beverages: return .bebidas
        case .clothing, .crafts, .electronics, .services, .other: return .otro
        }
    }

    // MARK: - Mock Data

    private func loadMockMerchants() {
        // userId del usuario "Don Taco" en UserManager
        let donTacoUserId = UserManager.shared.getAllUsers()
            .first(where: { $0.email == "don.taco@atenea.com" })?.id ?? UUID()
        let mariaUserId = UserManager.shared.getAllUsers()
            .first(where: { $0.email == "maria.elotes@atenea.com" })?.id ?? UUID()
        let pepeUserId = UserManager.shared.getAllUsers()
            .first(where: { $0.email == "pepe.carnitas@atenea.com" })?.id ?? UUID()

        // Expo Santa Fe coordinates: 19.3576, -99.2617
        let expoSantaFe = (lat: 19.3576, lon: -99.2617)

        merchants = [
            // COMERCIANTES CERCA DE EXPO SANTA FE (con rutas)
            Merchant(
                userId: UUID(),
                businessName: "Tacos El Güero - Ruta Santa Fe",
                category: .tacos,
                description: "Tacos al pastor y de suadero. Recorro la zona de Santa Fe todos los días.",
                products: [
                    Product(name: "Taco al Pastor", price: 20, emoji: "🌮"),
                    Product(name: "Taco de Suadero", price: 22, emoji: "🌮"),
                    Product(name: "Gringa", price: 40, emoji: "🫓"),
                    Product(name: "Refresco", price: 15, emoji: "🥤"),
                ],
                schedule: MerchantSchedule(openTime: "12:00", closeTime: "21:00", daysOfWeek: [1, 2, 3, 4, 5]),
                isStatic: false,
                currentLocation: MerchantLocation(latitude: 19.3576, longitude: -99.2617),
                route: MerchantRoute(
                    merchantId: UUID(),
                    waypoints: [
                        RouteWaypoint(coordinate: CLLocationCoordinate2D(latitude: 19.3576, longitude: -99.2617), order: 0, name: "Expo Santa Fe"),
                        RouteWaypoint(coordinate: CLLocationCoordinate2D(latitude: 19.3600, longitude: -99.2640), order: 1, name: "Centro Comercial"),
                        RouteWaypoint(coordinate: CLLocationCoordinate2D(latitude: 19.3620, longitude: -99.2670), order: 2, name: "Torre Corporativa"),
                        RouteWaypoint(coordinate: CLLocationCoordinate2D(latitude: 19.3590, longitude: -99.2700), order: 3, name: "Parque"),
                    ],
                    estimatedDuration: 1800, // 30 min
                    estimatedDistance: 2500, // 2.5 km
                    isActive: true
                )
            ),
            Merchant(
                userId: UUID(),
                businessName: "Café Móvil Andrea",
                category: .bebidas,
                emoji: "☕",
                description: "Café de especialidad, cappuccinos y bebidas frías. Recorro oficinas de Santa Fe.",
                products: [
                    Product(name: "Cappuccino", price: 45, emoji: "☕"),
                    Product(name: "Latte", price: 50, emoji: "☕"),
                    Product(name: "Cold Brew", price: 55, emoji: "🧊"),
                    Product(name: "Croissant", price: 35, emoji: "🥐"),
                ],
                schedule: MerchantSchedule(openTime: "07:00", closeTime: "11:00", daysOfWeek: [1, 2, 3, 4, 5]),
                isStatic: false,
                currentLocation: MerchantLocation(latitude: 19.3590, longitude: -99.2630),
                route: MerchantRoute(
                    merchantId: UUID(),
                    waypoints: [
                        RouteWaypoint(coordinate: CLLocationCoordinate2D(latitude: 19.3560, longitude: -99.2600), order: 0, name: "Metro Observatorio"),
                        RouteWaypoint(coordinate: CLLocationCoordinate2D(latitude: 19.3576, longitude: -99.2617), order: 1, name: "Expo Santa Fe"),
                        RouteWaypoint(coordinate: CLLocationCoordinate2D(latitude: 19.3595, longitude: -99.2650), order: 2, name: "Samara"),
                        RouteWaypoint(coordinate: CLLocationCoordinate2D(latitude: 19.3610, longitude: -99.2680), order: 3, name: "Punta Santa Fe"),
                    ],
                    estimatedDuration: 1200, // 20 min
                    estimatedDistance: 1800,
                    isActive: true
                )
            ),
            Merchant(
                userId: UUID(),
                businessName: "Frutas y Verduras Doña Lucha",
                category: .frutas,
                emoji: "🍉",
                description: "Fruta picada, agua de frutas y ensaladas. Frescura garantizada.",
                products: [
                    Product(name: "Fruta Picada Chica", price: 30, emoji: "🍉"),
                    Product(name: "Fruta Picada Grande", price: 50, emoji: "🍇"),
                    Product(name: "Agua de Jamaica", price: 20, emoji: "🥤"),
                    Product(name: "Ensalada de Fruta", price: 45, emoji: "🥗"),
                ],
                schedule: MerchantSchedule(openTime: "09:00", closeTime: "18:00", daysOfWeek: [1, 2, 3, 4, 5, 6]),
                isStatic: false,
                currentLocation: MerchantLocation(latitude: 19.3580, longitude: -99.2620),
                route: MerchantRoute(
                    merchantId: UUID(),
                    waypoints: [
                        RouteWaypoint(coordinate: CLLocationCoordinate2D(latitude: 19.3576, longitude: -99.2617), order: 0, name: "Expo Santa Fe"),
                        RouteWaypoint(coordinate: CLLocationCoordinate2D(latitude: 19.3585, longitude: -99.2625), order: 1, name: "Plaza 1"),
                        RouteWaypoint(coordinate: CLLocationCoordinate2D(latitude: 19.3595, longitude: -99.2635), order: 2, name: "Plaza 2"),
                        RouteWaypoint(coordinate: CLLocationCoordinate2D(latitude: 19.3605, longitude: -99.2650), order: 3, name: "Samara"),
                        RouteWaypoint(coordinate: CLLocationCoordinate2D(latitude: 19.3590, longitude: -99.2660), order: 4, name: "Regreso"),
                    ],
                    estimatedDuration: 2400, // 40 min
                    estimatedDistance: 3200,
                    isActive: true
                )
            ),
            Merchant(
                userId: UUID(),
                businessName: "Gorditas Doña Meche",
                category: .antojitos,
                emoji: "🫓",
                description: "Gorditas hechas a mano: chicharrón, picadillo, rajas. Zona Santa Fe.",
                products: [
                    Product(name: "Gordita de Chicharrón", price: 25, emoji: "🫓"),
                    Product(name: "Gordita de Picadillo", price: 25, emoji: "🥩"),
                    Product(name: "Gordita de Rajas", price: 22, emoji: "🌶️"),
                    Product(name: "Atole", price: 15, emoji: "☕"),
                ],
                schedule: MerchantSchedule(openTime: "08:00", closeTime: "14:00", daysOfWeek: [1, 2, 3, 4, 5, 6, 7]),
                isStatic: false,
                currentLocation: MerchantLocation(latitude: 19.3570, longitude: -99.2610),
                route: MerchantRoute(
                    merchantId: UUID(),
                    waypoints: [
                        RouteWaypoint(coordinate: CLLocationCoordinate2D(latitude: 19.3565, longitude: -99.2605), order: 0, name: "Inicio"),
                        RouteWaypoint(coordinate: CLLocationCoordinate2D(latitude: 19.3576, longitude: -99.2617), order: 1, name: "Expo Santa Fe"),
                        RouteWaypoint(coordinate: CLLocationCoordinate2D(latitude: 19.3590, longitude: -99.2635), order: 2, name: "Centro"),
                    ],
                    estimatedDuration: 900, // 15 min
                    estimatedDistance: 1200,
                    isActive: true
                )
            ),

            // COMERCIANTES ORIGINALES
            Merchant(
                userId: donTacoUserId,
                businessName: "Don Taco",
                category: .tacos,
                description: "Los mejores tacos al pastor de la zona del Azteca. Receta familiar desde 1985.",
                products: [
                    Product(name: "Taco al Pastor", price: 18, emoji: "🌮"),
                    Product(name: "Taco de Suadero", price: 20, emoji: "🌮"),
                    Product(name: "Quesadilla", price: 25, emoji: "🧀"),
                    Product(name: "Agua Fresca", price: 15, emoji: "🥤"),
                ],
                schedule: MerchantSchedule(openTime: "10:00", closeTime: "22:00", daysOfWeek: [1, 2, 3, 4, 5, 6, 7]),
                isStatic: true,
                currentLocation: MerchantLocation(latitude: 19.3029, longitude: -99.1506)
            ),
            Merchant(
                userId: UUID(),
                businessName: "Paletas Doña Mary",
                category: .helados,
                emoji: "🍦",
                description: "Paletas artesanales de Michoacán. Frutas naturales, sin conservadores.",
                products: [
                    Product(name: "Paleta de Fresa", price: 20, emoji: "🍓"),
                    Product(name: "Paleta de Mango", price: 20, emoji: "🥭"),
                    Product(name: "Paleta de Limón", price: 18, emoji: "🍋"),
                    Product(name: "Bolis de Coco", price: 12, emoji: "🥥"),
                ],
                schedule: MerchantSchedule(openTime: "09:00", closeTime: "20:00", daysOfWeek: [1, 2, 3, 4, 5, 6, 7]),
                isStatic: false,
                currentLocation: MerchantLocation(latitude: 19.3492, longitude: -99.1617)
            ),
            Merchant(
                userId: UUID(),
                businessName: "Jugos Mary",
                category: .jugos,
                emoji: "🥤",
                description: "Jugos y licuados naturales. Mixtos, verdes y detox.",
                products: [
                    Product(name: "Jugo de Naranja", price: 25, emoji: "🍊"),
                    Product(name: "Licuado de Plátano", price: 30, emoji: "🍌"),
                    Product(name: "Jugo Verde", price: 35, emoji: "🥬"),
                ],
                schedule: MerchantSchedule(openTime: "07:00", closeTime: "15:00", daysOfWeek: [1, 2, 3, 4, 5, 6]),
                isStatic: true,
                currentLocation: MerchantLocation(latitude: 19.4185, longitude: -99.1654)
            ),
            Merchant(
                userId: UUID(),
                businessName: "Tamales Oaxaqueños",
                category: .tamales,
                emoji: "🫔",
                description: "Tamales de mole negro, rajas y dulce. Hechos cada madrugada.",
                products: [
                    Product(name: "Tamal de Mole", price: 20, emoji: "🫔"),
                    Product(name: "Tamal de Rajas", price: 18, emoji: "🌶️"),
                    Product(name: "Tamal Dulce", price: 15, emoji: "🍬"),
                    Product(name: "Atole", price: 15, emoji: "☕"),
                ],
                schedule: MerchantSchedule(openTime: "06:00", closeTime: "12:00", daysOfWeek: [1, 2, 3, 4, 5, 6, 7]),
                isStatic: false,
                currentLocation: MerchantLocation(latitude: 19.4326, longitude: -99.1332)
            ),
            Merchant(
                userId: UUID(),
                businessName: "Elotes Don Chuy",
                category: .elotes,
                emoji: "🌽",
                description: "Elotes y esquites preparados. Con todo: mayonesa, queso, chile y limón.",
                products: [
                    Product(name: "Elote preparado", price: 25, emoji: "🌽"),
                    Product(name: "Esquites", price: 20, emoji: "🥤"),
                    Product(name: "Esquites con Flamin' Hot", price: 30, emoji: "🔥"),
                ],
                schedule: MerchantSchedule(openTime: "14:00", closeTime: "22:00", daysOfWeek: [1, 2, 3, 4, 5, 6, 7]),
                isStatic: false,
                currentLocation: MerchantLocation(latitude: 19.4204, longitude: -99.1895)
            ),
            // Comerciantes vinculados a nuevos usuarios
            Merchant(
                userId: mariaUserId,
                businessName: "Elotes de María",
                category: .elotes,
                emoji: "🌽",
                description: "Elotes y esquites con sazón de abuela. Especialidad: elote con crema de epazote.",
                products: [
                    Product(name: "Elote con crema", price: 28, emoji: "🌽"),
                    Product(name: "Esquites verdes", price: 25, emoji: "🥗"),
                    Product(name: "Elote con Tajín", price: 28, emoji: "🔴"),
                    Product(name: "Agua de Horchata", price: 18, emoji: "🥛"),
                ],
                schedule: MerchantSchedule(openTime: "15:00", closeTime: "22:00", daysOfWeek: [1, 2, 3, 4, 5, 6, 7]),
                isStatic: false,
                currentLocation: MerchantLocation(latitude: 19.3588, longitude: -99.2625),
                route: MerchantRoute(
                    merchantId: UUID(),
                    waypoints: [
                        RouteWaypoint(coordinate: CLLocationCoordinate2D(latitude: 19.3576, longitude: -99.2617), order: 0, name: "Expo Santa Fe"),
                        RouteWaypoint(coordinate: CLLocationCoordinate2D(latitude: 19.3588, longitude: -99.2630), order: 1, name: "Parque Central"),
                        RouteWaypoint(coordinate: CLLocationCoordinate2D(latitude: 19.3600, longitude: -99.2645), order: 2, name: "Zona Corporativa"),
                    ],
                    estimatedDuration: 1200,
                    estimatedDistance: 1500,
                    isActive: true
                )
            ),
            Merchant(
                userId: pepeUserId,
                businessName: "Carnitas Pepe",
                category: .antojitos,
                emoji: "🥩",
                description: "Carnitas estilo Michoacán. Maciza, buche, trompa y surtida. Tortillas hechas a mano.",
                products: [
                    Product(name: "Taco de Maciza", price: 24, emoji: "🌮"),
                    Product(name: "Taco de Buche", price: 26, emoji: "🌮"),
                    Product(name: "Quesadilla de Carnitas", price: 40, emoji: "🧀"),
                    Product(name: "Medio kilo para llevar", price: 150, emoji: "📦"),
                    Product(name: "Agua de Limón", price: 15, emoji: "🍋"),
                ],
                schedule: MerchantSchedule(openTime: "09:00", closeTime: "16:00", daysOfWeek: [6, 7]),
                isStatic: true,
                currentLocation: MerchantLocation(latitude: 19.3572, longitude: -99.2608)
            ),
        ]
    }
}

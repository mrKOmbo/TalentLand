//
//  MapboxRoutingService.swift
//  Atenea
//
//  Service for Mapbox Directions API integration
//

import Foundation
import CoreLocation

// MARK: - Mapbox Routing Service
class MapboxRoutingService {
    static let shared = MapboxRoutingService()

    private let accessToken: String
    private let baseURL = "https://api.mapbox.com/directions/v5/mapbox"

    private init() {
        // Get token from Info.plist
        if let token = Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String {
            self.accessToken = token
        } else {
            self.accessToken = ""
            print("⚠️ Mapbox access token not found in Info.plist")
        }
    }

    // MARK: - Calculate Route

    func calculateRoute(
        waypoints: [RouteWaypoint],
        profile: RouteProfile = .walking,
        completion: @escaping (Result<MapboxRouteResponse, Error>) -> Void
    ) {
        guard waypoints.count >= 2 else {
            completion(.failure(MapboxError.insufficientWaypoints))
            return
        }

        let coordinates = waypoints
            .sorted { $0.order < $1.order }
            .map { "\($0.longitude),\($0.latitude)" }
            .joined(separator: ";")

        var components = URLComponents(string: "\(baseURL)/\(profile.rawValue)/\(coordinates)")
        components?.queryItems = [
            URLQueryItem(name: "access_token", value: accessToken),
            URLQueryItem(name: "geometries", value: "geojson"),
            URLQueryItem(name: "overview", value: "full"),
            URLQueryItem(name: "steps", value: "true")
        ]

        guard let url = components?.url else {
            completion(.failure(MapboxError.invalidURL))
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(MapboxError.noData))
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let routeResponse = try decoder.decode(MapboxRouteResponse.self, from: data)
                completion(.success(routeResponse))
            } catch {
                print("❌ Mapbox decoding error: \(error)")
                completion(.failure(error))
            }
        }

        task.resume()
    }

    // MARK: - Optimization API (for reordering waypoints)

    func optimizeRoute(
        waypoints: [RouteWaypoint],
        profile: RouteProfile = .walking,
        completion: @escaping (Result<MapboxRouteResponse, Error>) -> Void
    ) {
        guard waypoints.count >= 2 else {
            completion(.failure(MapboxError.insufficientWaypoints))
            return
        }

        let coordinates = waypoints
            .map { "\($0.longitude),\($0.latitude)" }
            .joined(separator: ";")

        // Use Optimization API endpoint
        let optimizationURL = "https://api.mapbox.com/optimized-trips/v1/mapbox/\(profile.rawValue)/\(coordinates)"

        var components = URLComponents(string: optimizationURL)
        components?.queryItems = [
            URLQueryItem(name: "access_token", value: accessToken),
            URLQueryItem(name: "geometries", value: "geojson"),
            URLQueryItem(name: "overview", value: "full"),
            URLQueryItem(name: "source", value: "first"), // Start from first point
            URLQueryItem(name: "destination", value: "last") // End at last point
        ]

        guard let url = components?.url else {
            completion(.failure(MapboxError.invalidURL))
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(MapboxError.noData))
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let routeResponse = try decoder.decode(MapboxRouteResponse.self, from: data)
                completion(.success(routeResponse))
            } catch {
                print("❌ Mapbox optimization decoding error: \(error)")
                completion(.failure(error))
            }
        }

        task.resume()
    }
}

// MARK: - Route Profile

enum RouteProfile: String {
    case driving = "driving"
    case walking = "walking"
    case cycling = "cycling"
    case drivingTraffic = "driving-traffic"
}

// MARK: - Mapbox Response Models

struct MapboxRouteResponse: Codable {
    let routes: [MapboxRoute]
    let waypoints: [MapboxWaypoint]?
    let code: String
}

struct MapboxRoute: Codable {
    let geometry: MapboxGeometry
    let distance: Double // meters
    let duration: Double // seconds
    let legs: [MapboxLeg]?
}

struct MapboxGeometry: Codable {
    let coordinates: [[Double]]
    let type: String
}

struct MapboxLeg: Codable {
    let distance: Double
    let duration: Double
    let steps: [MapboxStep]?
}

struct MapboxStep: Codable {
    let distance: Double
    let duration: Double
    let geometry: MapboxGeometry
    let name: String?
    let maneuver: MapboxManeuver?
}

struct MapboxManeuver: Codable {
    let location: [Double]
    let type: String
    let instruction: String?
}

struct MapboxWaypoint: Codable {
    let location: [Double]
    let name: String
}

// MARK: - Errors

enum MapboxError: Error, LocalizedError {
    case insufficientWaypoints
    case invalidURL
    case noData
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .insufficientWaypoints:
            return "Se necesitan al menos 2 puntos para calcular una ruta"
        case .invalidURL:
            return "URL de Mapbox inválida"
        case .noData:
            return "No se recibieron datos de Mapbox"
        case .invalidResponse:
            return "Respuesta de Mapbox inválida"
        }
    }
}

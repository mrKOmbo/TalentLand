//
//  BusinessLocation.swift
//  Atenea
//
//  Model for business location selection
//

import Foundation
import CoreLocation

struct BusinessLocation: Codable {
    let latitude: Double
    let longitude: Double
    let address: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(coordinate: CLLocationCoordinate2D, address: String) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.address = address
    }
}

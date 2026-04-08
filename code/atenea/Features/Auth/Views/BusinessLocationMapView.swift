//
//  BusinessLocationMapView.swift
//  Atenea
//
//  Map view for selecting business location
//

import SwiftUI
import MapKit

struct BusinessLocationMapView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedLocation: BusinessLocation?

    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var searchText = ""
    @State private var isSearching = false

    var body: some View {
        ZStack {
            // Map
            Map(position: $cameraPosition) {
                if let coordinate = selectedCoordinate {
                    Marker("Tu negocio", coordinate: coordinate)
                        .tint(.purple)
                }
            }
            .mapStyle(.standard)
            .ignoresSafeArea()

            // Overlay UI
            VStack {
                // Search bar
                searchBar

                Spacer()

                // Instructions and confirm button
                bottomControls
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Atrás")
                            .font(.system(size: 17, weight: .regular))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.black.opacity(0.6))
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)
                    )
                }
            }
        }
        .onTapGesture { location in
            // Allow user to tap on map to set location
            // Note: This is a simplified version, actual implementation would need MapReader
        }
    }

    private var searchBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)

                TextField("Buscar dirección o lugar", text: $searchText)
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
            )
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }

    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Instructions card
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.purple)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Ubica tu negocio")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("Toca el mapa o busca una dirección para marcar tu ubicación")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
            )

            // Confirm button
            Button(action: confirmLocation) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))

                    Text("Confirmar ubicación")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: selectedCoordinate != nil ? [.purple, .pink] : [.gray, .gray],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(
                    color: selectedCoordinate != nil ? Color.purple.opacity(0.4) : .clear,
                    radius: 12,
                    x: 0,
                    y: 6
                )
            }
            .disabled(selectedCoordinate == nil)
        }
        .padding(16)
    }

    private func confirmLocation() {
        guard let coordinate = selectedCoordinate else { return }

        // Create location object
        selectedLocation = BusinessLocation(
            coordinate: coordinate,
            address: "Ubicación seleccionada" // TODO: Reverse geocoding
        )

        dismiss()
    }
}

// MARK: - Business Location Model

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

// MARK: - Preview

#Preview {
    NavigationStack {
        BusinessLocationMapView(selectedLocation: .constant(nil))
    }
}

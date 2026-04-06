//
//  TangaraMapView.swift
//  atenea
//
//  Vista que muestra el modelo 3D Tangara integrado en el mapa de Mapbox
//

import SwiftUI
@_spi(Experimental) import MapboxMaps
import CoreLocation

struct TangaraMapView: View {
    @State private var tangaraLocation = CLLocationCoordinate2D(
        latitude: 19.42700,  // Ángel de la Independencia, CDMX
        longitude: -99.16766
    )
    var onDismiss: () -> Void = {}

    var body: some View {
        ZStack {
            MapboxTangaraMapView(tangaraLocation: $tangaraLocation)
                .ignoresSafeArea()

            VStack {
                // Panel superior
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.3))
                                    .frame(width: 40, height: 40)
                            )
                    }
                    .padding(.leading, 20)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Tren Tangara 3D")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Modelo en Mapa")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                    .padding(.trailing, 20)
                }
                .padding(.top, 60)

                Spacer()

                // Botones de ubicaciones
                VStack(spacing: 12) {
                    Text("Mover modelo a:")
                        .font(.caption)
                        .foregroundColor(.white)

                    VStack(spacing: 10) {
                        Text("Ciudad de México")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.9))
                            .bold()

                        HStack(spacing: 12) {
                            Button("Ángel") {
                                withAnimation {
                                    tangaraLocation = CLLocationCoordinate2D(
                                        latitude: 19.42700,
                                        longitude: -99.16766
                                    )
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.yellow)

                            Button("Zócalo") {
                                withAnimation {
                                    tangaraLocation = CLLocationCoordinate2D(
                                        latitude: 19.43264,
                                        longitude: -99.13325
                                    )
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }

                        HStack(spacing: 12) {
                            Button("Casa Azul") {
                                withAnimation {
                                    tangaraLocation = CLLocationCoordinate2D(
                                        latitude: 19.35500,
                                        longitude: -99.16240
                                    )
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)

                            Button("Chapultepec") {
                                withAnimation {
                                    tangaraLocation = CLLocationCoordinate2D(
                                        latitude: 19.42049,
                                        longitude: -99.18219
                                    )
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                    }

                    Text("💡 El modelo 3D está integrado en el mapa")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding()
            }
        }
    }
}

struct MapboxTangaraMapView: UIViewRepresentable {
    @Binding var tangaraLocation: CLLocationCoordinate2D

    func makeUIView(context: Context) -> MapView {
        let cameraOptions = CameraOptions(
            center: tangaraLocation,
            zoom: 16,
            bearing: 0,
            pitch: 60
        )
        let mapInitOptions = MapInitOptions(cameraOptions: cameraOptions)
        let mapView = MapView(frame: .zero, mapInitOptions: mapInitOptions)

        // Configurar el estilo del mapa con el modelo 3D
        context.coordinator.setupMapStyle(mapView: mapView)

        return mapView
    }

    func updateUIView(_ mapView: MapView, context: Context) {
        // Actualizar ubicación del modelo
        context.coordinator.updateTangaraLocation(tangaraLocation, in: mapView)

        // Mover cámara a nueva ubicación con animación
        mapView.camera.ease(
            to: CameraOptions(
                center: tangaraLocation,
                zoom: 16,
                bearing: 0,
                pitch: 60
            ),
            duration: 1.5
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(initialLocation: tangaraLocation)
    }

    class Coordinator {
        private let modelId = "tangara-model-id"
        private let sourceId = "tangara-source-id"
        private let modelLayerId = "tangara-layer-id"
        private let modelIdKey = "model-id-key"
        private var currentLocation: CLLocationCoordinate2D

        init(initialLocation: CLLocationCoordinate2D) {
            self.currentLocation = initialLocation
        }

        func setupMapStyle(mapView: MapView) {
            // Obtener la URL del modelo desde el bundle
            guard let modelURL = Bundle.main.url(forResource: "Tangara_NoTracks", withExtension: "glb") else {
                print("❌ Error: No se encontró el archivo Tangara_NoTracks.glb en el bundle")
                print("🔍 Verifica que el archivo esté en Resources/Models/ y agregado al target")
                return
            }

            print("✅ Modelo encontrado en: \(modelURL.path)")

            // Crear feature con la ubicación del modelo
            var tangaraFeature = Feature(geometry: .point(Point(currentLocation)))
            tangaraFeature.properties = [modelIdKey: .string(modelId)]

            // Configurar el estilo del mapa con el modelo
            mapView.mapboxMap.setMapStyleContent {
                // Registrar el modelo 3D
                Model(id: modelId, uri: modelURL)

                // Crear el source con el feature
                GeoJSONSource(id: sourceId)
                    .data(.featureCollection(FeatureCollection(features: [tangaraFeature])))

                // Crear el layer del modelo
                ModelLayer(id: modelLayerId, source: sourceId)
                    .modelId(Exp(.get) { modelIdKey })
                    .modelType(.common3d)
                    .modelScale(x: 50, y: 50, z: 50)  // Escala grande para visualización
                    .modelRotation(x: 0, y: 0, z: 0)  // Sin rotación, paralelo al mapa
                    .modelOpacity(1.0)
            }

            print("✅ Estilo configurado con modelo Tangara en escala 50x50x50")
        }

        func updateTangaraLocation(_ newLocation: CLLocationCoordinate2D, in mapView: MapView) {
            guard newLocation.latitude != currentLocation.latitude ||
                  newLocation.longitude != currentLocation.longitude else {
                return
            }

            currentLocation = newLocation

            // Crear nuevo feature con la nueva ubicación
            var tangaraFeature = Feature(geometry: .point(Point(newLocation)))
            tangaraFeature.properties = [modelIdKey: .string(modelId)]

            // Actualizar el source con la nueva ubicación
            let geoJSONObject: GeoJSONObject = .featureCollection(
                FeatureCollection(features: [tangaraFeature])
            )

            do {
                try mapView.mapboxMap.updateGeoJSONSource(
                    withId: sourceId,
                    geoJSON: geoJSONObject
                )
                print("✅ Ubicación del modelo actualizada: \(newLocation.latitude), \(newLocation.longitude)")
            } catch {
                print("❌ Error actualizando ubicación: \(error)")
            }
        }
    }
}

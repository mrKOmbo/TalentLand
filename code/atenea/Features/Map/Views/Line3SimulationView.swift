//
//  Line3SimulationView.swift
//  atenea
//
//  Simulación del recorrido de un tren en cualquier línea del Metro CDMX
//

import SwiftUI
@_spi(Experimental) import MapboxMaps
import CoreLocation

struct Line3SimulationView: View {
    let metroLine: MetroLine
    @State private var isSimulationRunning = false
    @State private var currentProgress: Double = 0.0
    @State private var currentStation: String
    @State private var estimatedTimeToEnd: Int = 0  // En minutos
    @State private var nextStationTime: Int = 0  // En segundos
    @State private var averageSpeed: Double = 35.0  // En km/h
    var onDismiss: () -> Void = {}

    init(metroLine: MetroLine, onDismiss: @escaping () -> Void = {}) {
        self.metroLine = metroLine
        self.onDismiss = onDismiss
        _currentStation = State(initialValue: metroLine.startStation)
    }

    // Calcular tiempo estimado basado en el progreso
    private func calculateEstimatedTime() -> (toEnd: Int, toNext: Int, speed: Double) {
        let totalStations = metroLine.stationNames.count
        let stationProgress = 1.0 / Double(totalStations - 1)
        let currentStationIndex = Int(round(currentProgress / stationProgress))
        let stationsRemaining = totalStations - currentStationIndex - 1

        // Tiempo promedio entre estaciones: 2 minutos
        let avgTimePerStation = 2.0
        let totalTimeMinutes = Int(Double(stationsRemaining) * avgTimePerStation)

        // Tiempo a la siguiente estación (en segundos)
        let progressToNextStation = (currentProgress.truncatingRemainder(dividingBy: stationProgress)) / stationProgress
        let secondsToNext = Int((1.0 - progressToNextStation) * avgTimePerStation * 60)

        // Velocidad promedio del metro: 30-40 km/h
        let speed = 35.0 + Double.random(in: -3...3)

        return (totalTimeMinutes, secondsToNext, speed)
    }

    var body: some View {
        ZStack {
            // Mapa con la simulación
            MapboxLine3SimulationMapView(
                metroLine: metroLine,
                isRunning: $isSimulationRunning,
                progress: $currentProgress,
                currentStation: $currentStation
            )
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
                        Text(String(format: LocalizedString("simulation.title"), metroLine.name))
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("\(metroLine.startStation) → \(metroLine.endStation)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))

                        HStack(spacing: 4) {
                            Image(systemName: "tram.fill")
                                .font(.caption2)
                                .foregroundColor(Color(uiColor: metroLine.color))
                            Text(currentStation)
                                .font(.caption2)
                                .foregroundColor(.white)
                                .bold()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(uiColor: metroLine.color).opacity(0.3))
                        )
                    }
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                    .padding(.trailing, 20)
                }
                .padding(.top, 60)

                Spacer()

                // Panel de pronósticos
                VStack(spacing: 16) {
                    // Título con botón de control
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(Color(uiColor: metroLine.color))
                            .font(.subheadline)
                        Text(LocalizedString("simulation.arrivalForecast"))
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: {
                            isSimulationRunning.toggle()
                        }) {
                            Image(systemName: isSimulationRunning ? "pause.circle.fill" : "play.circle.fill")
                                .font(.title3)
                                .foregroundColor(Color(uiColor: metroLine.color))
                        }
                    }

                    // Tarjetas de información compactas
                    HStack(spacing: 10) {
                        // Tiempo al destino
                        VStack(spacing: 4) {
                            Text(LocalizedString("simulation.destination"))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                            Text("\(estimatedTimeToEnd) min")
                                .font(.title3)
                                .bold()
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(uiColor: metroLine.color).opacity(0.3))
                        .cornerRadius(8)

                        // Próxima estación
                        VStack(spacing: 4) {
                            Text(LocalizedString("simulation.next"))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                            Text("\(nextStationTime) seg")
                                .font(.title3)
                                .bold()
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.orange.opacity(0.3))
                        .cornerRadius(8)

                        // Velocidad
                        VStack(spacing: 4) {
                            Text(LocalizedString("simulation.speed"))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                            Text("\(Int(averageSpeed)) km/h")
                                .font(.title3)
                                .bold()
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(8)
                    }

                    // Estado e información adicional
                    HStack {
                        Circle()
                            .fill(isSimulationRunning ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(isSimulationRunning ? LocalizedString("simulation.onRoute") : LocalizedString("simulation.stopped"))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text(String(format: LocalizedString("simulation.completed"), Int(currentProgress * 100)))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding()
            }
        }
        .onAppear {
            // Iniciar automáticamente la simulación
            isSimulationRunning = true
            // Calcular tiempos iniciales
            let times = calculateEstimatedTime()
            estimatedTimeToEnd = times.toEnd
            nextStationTime = times.toNext
            averageSpeed = times.speed
        }
        .onChange(of: currentProgress) { _ in
            // Actualizar tiempos cuando cambia el progreso
            let times = calculateEstimatedTime()
            estimatedTimeToEnd = times.toEnd
            nextStationTime = times.toNext
            averageSpeed = times.speed
        }
    }
}

struct MapboxLine3SimulationMapView: UIViewRepresentable {
    let metroLine: MetroLine
    @Binding var isRunning: Bool
    @Binding var progress: Double
    @Binding var currentStation: String

    func makeUIView(context: Context) -> MapView {
        // Configurar cámara inicial en el inicio de la línea
        // donde el tren comienza su recorrido
        let startPoint = metroLine.coordinates.first!
        print("📷 Cámara inicial en: (\(startPoint.latitude), \(startPoint.longitude))")

        let cameraOptions = CameraOptions(
            center: startPoint,
            zoom: 16.5,  // Zoom más cercano para ver el modelo realista
            bearing: 0,
            pitch: 45
        )

        let mapInitOptions = MapInitOptions(cameraOptions: cameraOptions)
        let mapView = MapView(frame: .zero, mapInitOptions: mapInitOptions)

        // Configurar el mapa
        context.coordinator.setupMap(mapView: mapView, line: metroLine)

        return mapView
    }

    func updateUIView(_ mapView: MapView, context: Context) {
        // Actualizar la simulación cuando cambia el estado
        context.coordinator.updateSimulation(
            isRunning: isRunning,
            progress: progress,
            in: mapView,
            updateProgress: { newProgress in
                DispatchQueue.main.async {
                    self.progress = newProgress
                }
            },
            updateStation: { stationName in
                DispatchQueue.main.async {
                    self.currentStation = stationName
                }
            }
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        private let lineSourceId = "line3-simulation-source"
        private let lineLayerId = "line3-simulation-layer"
        private let returnLineSourceId = "line3-return-source"
        private let returnLineLayerId = "line3-return-layer"
        private let startConnectorSourceId = "start-connector-source"
        private let startConnectorLayerId = "start-connector-layer"
        private let endConnectorSourceId = "end-connector-source"
        private let endConnectorLayerId = "end-connector-layer"
        private let trainSourceId = "train-model-source"
        private let trainLayerId = "train-model-layer"
        private let train2SourceId = "train2-model-source"  // Segundo tren
        private let train2LayerId = "train2-model-layer"     // Segundo tren
        private let stationsSourceId = "stations-source"
        private let stationsLayerId = "stations-layer"
        private let stationsIconLayerId = "stations-icon-layer"
        private let stationsSymbolLayerId = "stations-symbol-layer"
        private let peopleLeftSourceId = "people-left-source"  // Personas lado izquierdo
        private let peopleLeftLayerId = "people-left-layer"
        private let peopleRightSourceId = "people-right-source"  // Personas lado derecho
        private let peopleRightLayerId = "people-right-layer"
        private let modelId = "box-model-id"
        private let model2Id = "box-model-id-2"  // ID para el segundo modelo
        private let modelIdKey = "model-id-key"

        private var timer: Timer?
        private var line3Coordinates: [CLLocationCoordinate2D] = []
        private var forwardLineCoordinates: [CLLocationCoordinate2D] = []  // Coordenadas de ida
        private var returnLineCoordinates: [CLLocationCoordinate2D] = []   // Coordenadas de vuelta
        private var currentBearing: Double = 0.0
        private var currentBearing2: Double = 0.0  // Bearing del segundo tren
        private var useSimpleModel = true  // Flag para controlar si usar modelo 3D
        private var hasLoggedFirstUpdate = false  // Para logging de debug
        private var isGoingForward = true  // Dirección del tren (true = ida, false = vuelta)

        // Station stop management
        private var stoppedAtStation = false
        private var stopStartTime: Date?
        private let stationStopDuration: TimeInterval = 2.5  // Segundos de parada en cada estación
        private var lastStationIndex: Int = -1

        // Nombres de las estaciones (se cargan desde la línea del metro)
        private var stationNames: [String] = []

        // Índice de inicio del Tren 2 (segunda estación)
        private let train2StartStationIndex: Int = 1

        // Longitud del tren en términos de progreso (0.0 a 1.0)
        private let trainLengthProgress: Double = 0.008

        // Separación entre líneas de ida y vuelta (en metros aproximados)
        private let lineOffset: Double = 50.0

        // Ajuste de orientación del modelo (en grados)
        private let modelRotationOffset: Double = 0.0

        // Calcula una línea paralela con offset perpendicular
        private func calculateParallelLine(from coordinates: [CLLocationCoordinate2D], offset: Double) -> [CLLocationCoordinate2D] {
            guard coordinates.count > 1 else { return coordinates }

            var parallelCoords: [CLLocationCoordinate2D] = []

            // Constante para convertir metros a grados (aproximado para latitudes medias)
            let metersToDegreesLat = offset / 111111.0
            let metersToDegreesLon = offset / (111111.0 * cos(coordinates[0].latitude * .pi / 180))

            for i in 0..<coordinates.count {
                let current = coordinates[i]

                // Calcular vector perpendicular
                var perpVector: (dx: Double, dy: Double)

                if i == 0 {
                    // Primer punto: usar vector del segmento siguiente
                    let next = coordinates[i + 1]
                    let dx = next.longitude - current.longitude
                    let dy = next.latitude - current.latitude
                    perpVector = (-dy, dx) // Perpendicular (rotar 90°)
                } else if i == coordinates.count - 1 {
                    // Último punto: usar vector del segmento anterior
                    let prev = coordinates[i - 1]
                    let dx = current.longitude - prev.longitude
                    let dy = current.latitude - prev.latitude
                    perpVector = (-dy, dx)
                } else {
                    // Punto medio: promediar vectores de ambos segmentos
                    let prev = coordinates[i - 1]
                    let next = coordinates[i + 1]
                    let dx1 = current.longitude - prev.longitude
                    let dy1 = current.latitude - prev.latitude
                    let dx2 = next.longitude - current.longitude
                    let dy2 = next.latitude - current.latitude
                    perpVector = (-(dy1 + dy2) / 2, (dx1 + dx2) / 2)
                }

                // Normalizar el vector perpendicular
                let length = sqrt(perpVector.dx * perpVector.dx + perpVector.dy * perpVector.dy)
                if length > 0 {
                    perpVector.dx /= length
                    perpVector.dy /= length
                }

                // Aplicar offset
                let offsetLat = perpVector.dy * metersToDegreesLat
                let offsetLon = perpVector.dx * metersToDegreesLon

                let parallelCoord = CLLocationCoordinate2D(
                    latitude: current.latitude + offsetLat,
                    longitude: current.longitude + offsetLon
                )
                parallelCoords.append(parallelCoord)
            }

            return parallelCoords
        }

        func setupMap(mapView: MapView, line: MetroLine) {
            line3Coordinates = line.coordinates
            stationNames = line.stationNames
            print("🗺️ Configurando mapa con \(line3Coordinates.count) coordenadas")
            print("📍 Cargadas \(stationNames.count) estaciones para \(line.name)")
            print("🔄 Creando líneas de ida y vuelta con offset de \(lineOffset)m")

            // Intentar cargar modelos 3D en orden de preferencia
            // Nota: Mapbox solo soporta modelos con menos de 65,535 índices
            let modelNames = ["model2", "model", "low_poly_train", "Train", "Box", "Duck", "Sphere", "Cube"]
            var modelURL: URL?
            var foundModelName: String?

            print("🔍 Buscando modelos 3D...")
            for modelName in modelNames {
                if let url = Bundle.main.url(forResource: modelName, withExtension: "glb") {
                    modelURL = url
                    foundModelName = modelName
                    print("✅ Modelo 3D encontrado: \(modelName).glb")
                    print("   Ruta: \(url.path)")
                    break
                } else {
                    print("   ❌ \(modelName).glb no encontrado")
                }
            }

            // Si encontramos un modelo 3D, úsalo; si no, usa círculo
            if let modelURL = modelURL, let modelName = foundModelName {
                print("🚂 Usando modelo 3D: \(modelName)")
                setupWith3DModel(mapView: mapView, line: line, modelURL: modelURL)
            } else {
                print("⚠️ No se encontró modelo 3D, usando punto animado")
                print("💡 Descarga Box.glb de: https://github.com/KhronosGroup/glTF-Sample-Models")
                setupWithCircle(mapView: mapView, line: line)
            }
        }

        private func setupWith3DModel(mapView: MapView, line: MetroLine, modelURL: URL) {
            print("🔧 Configurando simulación con modelo 3D...")
            print("💡 Si el modelo no apunta en la dirección correcta,")
            print("   ajusta 'modelRotationOffset' en la clase Coordinator")
            
            // Crear feature inicial del tren
            let initialCoord = line.coordinates.first!
            print("   Posición inicial: (\(initialCoord.latitude), \(initialCoord.longitude))")
            
            var trainFeature = Feature(geometry: .point(Point(initialCoord)))
            trainFeature.properties = [
                modelIdKey: .string(modelId),
                "bearing": .number(modelRotationOffset)  // Aplicar offset inicial
            ]
            
            // Crear LineString de la línea de ida (con offset positivo)
            forwardLineCoordinates = calculateParallelLine(from: line.coordinates, offset: lineOffset / 2)
            let forwardLineCoordinatesMapbox = forwardLineCoordinates.map { coord in
                LocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
            }
            let forwardLineString = LineString(forwardLineCoordinatesMapbox)
            
            // Crear LineString de la línea de vuelta (con offset negativo)
            returnLineCoordinates = calculateParallelLine(from: line.coordinates, offset: -lineOffset / 2)
            let returnLineCoordinatesMapbox = returnLineCoordinates.map { coord in
                LocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
            }
            let returnLineString = LineString(returnLineCoordinatesMapbox)
            
            print("   LineString de ida creado con \(forwardLineCoordinatesMapbox.count) puntos")
            print("   LineString de vuelta creado con \(returnLineCoordinatesMapbox.count) puntos")
            
            // Capturar valores
            // Crear líneas conectoras en los extremos
            let startConnector = LineString([
                LocationCoordinate2D(latitude: returnLineCoordinatesMapbox.first!.latitude,
                                     longitude: returnLineCoordinatesMapbox.first!.longitude),
                LocationCoordinate2D(latitude: forwardLineCoordinatesMapbox.first!.latitude,
                                     longitude: forwardLineCoordinatesMapbox.first!.longitude)
            ])
            
            let endConnector = LineString([
                LocationCoordinate2D(latitude: forwardLineCoordinatesMapbox.last!.latitude,
                                     longitude: forwardLineCoordinatesMapbox.last!.longitude),
                LocationCoordinate2D(latitude: returnLineCoordinatesMapbox.last!.latitude,
                                     longitude: returnLineCoordinatesMapbox.last!.longitude)
            ])
            
            print("   Conectores creados en los extremos")
            
            let lineSourceId = self.lineSourceId
            let lineLayerId = self.lineLayerId
            let returnLineSourceId = self.returnLineSourceId
            let returnLineLayerId = self.returnLineLayerId
            let startConnectorSourceId = self.startConnectorSourceId
            let startConnectorLayerId = self.startConnectorLayerId
            let endConnectorSourceId = self.endConnectorSourceId
            let endConnectorLayerId = self.endConnectorLayerId
            let trainSourceId = self.trainSourceId
            let trainLayerId = self.trainLayerId
            let train2SourceId = self.train2SourceId
            let train2LayerId = self.train2LayerId
            let modelId = self.modelId
            let model2Id = self.model2Id
            let modelIdKey = self.modelIdKey
            let lineColor = line.color
            let rotationOffset = self.modelRotationOffset
            
            // Crear feature inicial del segundo tren (en la segunda estación de la línea de vuelta)
            let initialCoord2 = returnLineCoordinates[self.train2StartStationIndex]
            print("🚂 Tren 2 inicia en la segunda estación: \(self.stationNames[self.train2StartStationIndex])")
            print("   Coordenadas: (\(initialCoord2.latitude), \(initialCoord2.longitude))")

            var train2Feature = Feature(geometry: .point(Point(LocationCoordinate2D(latitude: initialCoord2.latitude, longitude: initialCoord2.longitude))))
            train2Feature.properties = [
                modelIdKey: .string(model2Id),
                "bearing": .number(modelRotationOffset + 180)  // Dirección opuesta
            ]

            // Crear features para las estaciones con sus nombres
            let stationFeatures = line.coordinates.enumerated().map { index, coord -> Feature in
                var feature = Feature(geometry: .point(Point(LocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude))))
                feature.properties = [
                    "name": .string(self.stationNames[index]),
                    "index": .number(Double(index))
                ]
                return feature
            }
            let stationsCollection = FeatureCollection(features: stationFeatures)

            // Crear features para las personas (puntos rojos) distribuidas alrededor de cada estación
            let peoplePerStation = 8  // Número de personas por estación
            let peopleSpreadRadius: Double = 12.0  // Radio de distribución en metros

            var peopleLeftFeatures: [Feature] = []
            var peopleRightFeatures: [Feature] = []

            // Para cada estación, crear múltiples personas distribuidas
            for (stationIndex, stationCoord) in line.coordinates.enumerated() {
                // Constantes para convertir metros a grados
                let metersToDegreesLat = 1.0 / 111111.0
                let metersToDegreesLon = 1.0 / (111111.0 * cos(stationCoord.latitude * .pi / 180))

                // Crear personas en el lado izquierdo (línea de ida)
                let leftBaseOffset = (self.lineOffset / 2) + 8.0
                for i in 0..<peoplePerStation {
                    // Distribución aleatoria pero determinística (usando el índice)
                    let angle = Double(i) * (2.0 * .pi / Double(peoplePerStation))
                    let randomRadius = peopleSpreadRadius * (0.5 + 0.5 * sin(Double(stationIndex + i)))

                    let offsetX = randomRadius * cos(angle)
                    let offsetY = randomRadius * sin(angle)

                    let personLat = stationCoord.latitude + (leftBaseOffset + offsetY) * metersToDegreesLat
                    let personLon = stationCoord.longitude + offsetX * metersToDegreesLon

                    var feature = Feature(geometry: .point(Point(LocationCoordinate2D(latitude: personLat, longitude: personLon))))
                    feature.properties = ["type": .string("person"), "station": .number(Double(stationIndex))]
                    peopleLeftFeatures.append(feature)
                }

                // Crear personas en el lado derecho (línea de vuelta)
                let rightBaseOffset = -(self.lineOffset / 2) - 8.0
                for i in 0..<peoplePerStation {
                    let angle = Double(i) * (2.0 * .pi / Double(peoplePerStation))
                    let randomRadius = peopleSpreadRadius * (0.5 + 0.5 * cos(Double(stationIndex + i)))

                    let offsetX = randomRadius * cos(angle)
                    let offsetY = randomRadius * sin(angle)

                    let personLat = stationCoord.latitude + (rightBaseOffset + offsetY) * metersToDegreesLat
                    let personLon = stationCoord.longitude + offsetX * metersToDegreesLon

                    var feature = Feature(geometry: .point(Point(LocationCoordinate2D(latitude: personLat, longitude: personLon))))
                    feature.properties = ["type": .string("person"), "station": .number(Double(stationIndex))]
                    peopleRightFeatures.append(feature)
                }
            }

            let peopleLeftCollection = FeatureCollection(features: peopleLeftFeatures)
            let peopleRightCollection = FeatureCollection(features: peopleRightFeatures)

            print("   Aplicando estilo del mapa...")
            print("   Offset de rotación: \(rotationOffset)°")
            print("   Creando \(stationFeatures.count) marcadores de estaciones")
            print("   Creando \(peopleLeftFeatures.count) personas en lado izquierdo")
            print("   Creando \(peopleRightFeatures.count) personas en lado derecho")

            // Configurar con modelo 3D
            mapView.mapboxMap.setMapStyleContent {
                // Registrar los modelos 3D (uno para cada tren)
                Model(id: modelId, uri: modelURL)
                Model(id: model2Id, uri: modelURL)

                // Línea del metro - Ida (Indios Verdes → Universidad)
                GeoJSONSource(id: lineSourceId)
                    .data(.geometry(.lineString(forwardLineString)))

                LineLayer(id: lineLayerId, source: lineSourceId)
                    .lineColor(StyleColor(lineColor))
                    .lineWidth(6.0)
                    .lineCap(.round)
                    .lineJoin(.round)
                    .lineOpacity(0.8)

                // Línea del metro - Vuelta (Universidad → Indios Verdes)
                GeoJSONSource(id: returnLineSourceId)
                    .data(.geometry(.lineString(returnLineString)))

                LineLayer(id: returnLineLayerId, source: returnLineSourceId)
                    .lineColor(StyleColor(lineColor))
                    .lineWidth(6.0)
                    .lineCap(.round)
                    .lineJoin(.round)
                    .lineOpacity(0.6)  // Más transparente para diferenciar

                // Conector en el inicio (Indios Verdes)
                GeoJSONSource(id: startConnectorSourceId)
                    .data(.geometry(.lineString(startConnector)))

                LineLayer(id: startConnectorLayerId, source: startConnectorSourceId)
                    .lineColor(StyleColor(lineColor))
                    .lineWidth(6.0)
                    .lineCap(.round)
                    .lineJoin(.round)
                    .lineOpacity(0.7)

                // Conector en el final (Universidad)
                GeoJSONSource(id: endConnectorSourceId)
                    .data(.geometry(.lineString(endConnector)))

                LineLayer(id: endConnectorLayerId, source: endConnectorSourceId)
                    .lineColor(StyleColor(lineColor))
                    .lineWidth(6.0)
                    .lineCap(.round)
                    .lineJoin(.round)
                    .lineOpacity(0.7)

                // Marcadores de estaciones
                GeoJSONSource(id: self.stationsSourceId)
                    .data(.featureCollection(stationsCollection))

                // Círculos para las estaciones
                CircleLayer(id: self.stationsLayerId, source: self.stationsSourceId)
                    .circleRadius(10.0)
                    .circleColor(StyleColor(lineColor))
                    .circleStrokeWidth(2.5)
                    .circleStrokeColor(StyleColor(.white))
                    .circleOpacity(0.9)

                // Ícono de metro en cada estación
                SymbolLayer(id: self.stationsIconLayerId, source: self.stationsSourceId)
                    .textField(Exp(.literal) { "Ⓜ" })
                    .textSize(16)
                    .textColor(StyleColor(.white))

                // Nombres de las estaciones
                SymbolLayer(id: self.stationsSymbolLayerId, source: self.stationsSourceId)
                    .textField(Exp(.get) { "name" })
                    .textSize(12)
                    .textColor(StyleColor(.white))
                    .textHaloColor(StyleColor(.black))
                    .textHaloWidth(1.5)
                    .textAnchor(TextAnchor.top)

                // Personas lado izquierdo (puntos rojos)
                GeoJSONSource(id: self.peopleLeftSourceId)
                    .data(.featureCollection(peopleLeftCollection))

                CircleLayer(id: self.peopleLeftLayerId, source: self.peopleLeftSourceId)
                    .circleRadius(2.0)  // Más pequeño para que parezca más realista
                    .circleColor(StyleColor(.red))
                    .circleStrokeWidth(0.3)
                    .circleStrokeColor(StyleColor(.white))
                    .circleOpacity(0.9)

                // Personas lado derecho (puntos rojos)
                GeoJSONSource(id: self.peopleRightSourceId)
                    .data(.featureCollection(peopleRightCollection))

                CircleLayer(id: self.peopleRightLayerId, source: self.peopleRightSourceId)
                    .circleRadius(2.0)  // Más pequeño para que parezca más realista
                    .circleColor(StyleColor(.red))
                    .circleStrokeWidth(0.3)
                    .circleStrokeColor(StyleColor(.white))
                    .circleOpacity(0.9)

                // Modelo 3D del primer tren (ida)
                GeoJSONSource(id: trainSourceId)
                    .data(.featureCollection(FeatureCollection(features: [trainFeature])))

                ModelLayer(id: trainLayerId, source: trainSourceId)
                    .modelId(Exp(.get) { modelIdKey })
                    .modelType(.common3d)
                    .modelScale(x: 4, y: 4, z: 4)
                    .modelRotation(x: 0, y: 0, z: 0)
                    .modelOpacity(1.0)
                    .modelCastShadows(false)
                    .modelReceiveShadows(false)

                // Modelo 3D del segundo tren (vuelta)
                GeoJSONSource(id: train2SourceId)
                    .data(.featureCollection(FeatureCollection(features: [train2Feature])))

                ModelLayer(id: train2LayerId, source: train2SourceId)
                    .modelId(Exp(.get) { modelIdKey })
                    .modelType(.common3d)
                    .modelScale(x: 4, y: 4, z: 4)
                    .modelRotation(x: 0, y: 0, z: 0)
                    .modelOpacity(1.0)
                    .modelCastShadows(false)
                    .modelReceiveShadows(false)
            }

            useSimpleModel = true
            print("✅ Simulación configurada con modelo 3D")
            print("   Tren 1 - Model ID: \(modelId) (Primera estación → Última estación)")
            print("   Tren 2 - Model ID: \(model2Id) (Segunda estación → Primera estación)")
            print("   Escala: 4x4x4")
            print("   Trenes en direcciones opuestas")
        }

        private func setupWithCircle(mapView: MapView, line: MetroLine) {
            print("🔧 Configurando simulación con círculos (sin modelo 3D)...")

            // Crear LineString de la línea de ida (con offset positivo)
            forwardLineCoordinates = calculateParallelLine(from: line.coordinates, offset: lineOffset / 2)
            let forwardLineCoordinatesMapbox = forwardLineCoordinates.map { coord in
                LocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
            }
            let forwardLineString = LineString(forwardLineCoordinatesMapbox)

            // Crear LineString de la línea de vuelta (con offset negativo)
            returnLineCoordinates = calculateParallelLine(from: line.coordinates, offset: -lineOffset / 2)
            let returnLineCoordinatesMapbox = returnLineCoordinates.map { coord in
                LocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
            }
            let returnLineString = LineString(returnLineCoordinatesMapbox)

            // Crear líneas conectoras en los extremos
            let startConnector = LineString([
                LocationCoordinate2D(latitude: returnLineCoordinatesMapbox.first!.latitude,
                                   longitude: returnLineCoordinatesMapbox.first!.longitude),
                LocationCoordinate2D(latitude: forwardLineCoordinatesMapbox.first!.latitude,
                                   longitude: forwardLineCoordinatesMapbox.first!.longitude)
            ])

            let endConnector = LineString([
                LocationCoordinate2D(latitude: forwardLineCoordinatesMapbox.last!.latitude,
                                   longitude: forwardLineCoordinatesMapbox.last!.longitude),
                LocationCoordinate2D(latitude: returnLineCoordinatesMapbox.last!.latitude,
                                   longitude: returnLineCoordinatesMapbox.last!.longitude)
            ])

            let lineSourceId = self.lineSourceId
            let lineLayerId = self.lineLayerId
            let returnLineSourceId = self.returnLineSourceId
            let returnLineLayerId = self.returnLineLayerId
            let startConnectorSourceId = self.startConnectorSourceId
            let startConnectorLayerId = self.startConnectorLayerId
            let endConnectorSourceId = self.endConnectorSourceId
            let endConnectorLayerId = self.endConnectorLayerId
            let trainSourceId = self.trainSourceId
            let trainLayerId = self.trainLayerId
            let train2SourceId = self.train2SourceId
            let train2LayerId = self.train2LayerId
            let lineColor = line.color

            // Crear features para las estaciones con sus nombres
            let stationFeatures = line.coordinates.enumerated().map { index, coord -> Feature in
                var feature = Feature(geometry: .point(Point(LocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude))))
                feature.properties = [
                    "name": .string(self.stationNames[index]),
                    "index": .number(Double(index))
                ]
                return feature
            }
            let stationsCollection = FeatureCollection(features: stationFeatures)

            // Crear features para las personas (puntos rojos) distribuidas alrededor de cada estación
            let peoplePerStation = 8  // Número de personas por estación
            let peopleSpreadRadius: Double = 12.0  // Radio de distribución en metros

            var peopleLeftFeatures: [Feature] = []
            var peopleRightFeatures: [Feature] = []

            // Para cada estación, crear múltiples personas distribuidas
            for (stationIndex, stationCoord) in line.coordinates.enumerated() {
                // Constantes para convertir metros a grados
                let metersToDegreesLat = 1.0 / 111111.0
                let metersToDegreesLon = 1.0 / (111111.0 * cos(stationCoord.latitude * .pi / 180))

                // Crear personas en el lado izquierdo (línea de ida)
                let leftBaseOffset = (self.lineOffset / 2) + 8.0
                for i in 0..<peoplePerStation {
                    // Distribución aleatoria pero determinística (usando el índice)
                    let angle = Double(i) * (2.0 * .pi / Double(peoplePerStation))
                    let randomRadius = peopleSpreadRadius * (0.5 + 0.5 * sin(Double(stationIndex + i)))

                    let offsetX = randomRadius * cos(angle)
                    let offsetY = randomRadius * sin(angle)

                    let personLat = stationCoord.latitude + (leftBaseOffset + offsetY) * metersToDegreesLat
                    let personLon = stationCoord.longitude + offsetX * metersToDegreesLon

                    var feature = Feature(geometry: .point(Point(LocationCoordinate2D(latitude: personLat, longitude: personLon))))
                    feature.properties = ["type": .string("person"), "station": .number(Double(stationIndex))]
                    peopleLeftFeatures.append(feature)
                }

                // Crear personas en el lado derecho (línea de vuelta)
                let rightBaseOffset = -(self.lineOffset / 2) - 8.0
                for i in 0..<peoplePerStation {
                    let angle = Double(i) * (2.0 * .pi / Double(peoplePerStation))
                    let randomRadius = peopleSpreadRadius * (0.5 + 0.5 * cos(Double(stationIndex + i)))

                    let offsetX = randomRadius * cos(angle)
                    let offsetY = randomRadius * sin(angle)

                    let personLat = stationCoord.latitude + (rightBaseOffset + offsetY) * metersToDegreesLat
                    let personLon = stationCoord.longitude + offsetX * metersToDegreesLon

                    var feature = Feature(geometry: .point(Point(LocationCoordinate2D(latitude: personLat, longitude: personLon))))
                    feature.properties = ["type": .string("person"), "station": .number(Double(stationIndex))]
                    peopleRightFeatures.append(feature)
                }
            }

            let peopleLeftCollection = FeatureCollection(features: peopleLeftFeatures)
            let peopleRightCollection = FeatureCollection(features: peopleRightFeatures)

            mapView.mapboxMap.setMapStyleContent {
                // Línea del metro - Ida
                GeoJSONSource(id: lineSourceId)
                    .data(.geometry(.lineString(forwardLineString)))

                LineLayer(id: lineLayerId, source: lineSourceId)
                    .lineColor(StyleColor(lineColor))
                    .lineWidth(6.0)
                    .lineCap(.round)
                    .lineJoin(.round)
                    .lineOpacity(0.8)

                // Línea del metro - Vuelta
                GeoJSONSource(id: returnLineSourceId)
                    .data(.geometry(.lineString(returnLineString)))

                LineLayer(id: returnLineLayerId, source: returnLineSourceId)
                    .lineColor(StyleColor(lineColor))
                    .lineWidth(6.0)
                    .lineCap(.round)
                    .lineJoin(.round)
                    .lineOpacity(0.6)

                // Conector en el inicio
                GeoJSONSource(id: startConnectorSourceId)
                    .data(.geometry(.lineString(startConnector)))

                LineLayer(id: startConnectorLayerId, source: startConnectorSourceId)
                    .lineColor(StyleColor(lineColor))
                    .lineWidth(6.0)
                    .lineCap(.round)
                    .lineJoin(.round)
                    .lineOpacity(0.7)

                // Conector en el final
                GeoJSONSource(id: endConnectorSourceId)
                    .data(.geometry(.lineString(endConnector)))

                LineLayer(id: endConnectorLayerId, source: endConnectorSourceId)
                    .lineColor(StyleColor(lineColor))
                    .lineWidth(6.0)
                    .lineCap(.round)
                    .lineJoin(.round)
                    .lineOpacity(0.7)

                // Marcadores de estaciones
                GeoJSONSource(id: self.stationsSourceId)
                    .data(.featureCollection(stationsCollection))

                CircleLayer(id: self.stationsLayerId, source: self.stationsSourceId)
                    .circleRadius(10.0)
                    .circleColor(StyleColor(lineColor))
                    .circleStrokeWidth(2.5)
                    .circleStrokeColor(StyleColor(.white))
                    .circleOpacity(0.9)

                SymbolLayer(id: self.stationsIconLayerId, source: self.stationsSourceId)
                    .textField(Exp(.literal) { "Ⓜ" })
                    .textSize(16)
                    .textColor(StyleColor(.white))

                SymbolLayer(id: self.stationsSymbolLayerId, source: self.stationsSourceId)
                    .textField(Exp(.get) { "name" })
                    .textSize(12)
                    .textColor(StyleColor(.white))
                    .textHaloColor(StyleColor(.black))
                    .textHaloWidth(1.5)
                    .textAnchor(TextAnchor.top)

                // Personas lado izquierdo (puntos rojos)
                GeoJSONSource(id: self.peopleLeftSourceId)
                    .data(.featureCollection(peopleLeftCollection))

                CircleLayer(id: self.peopleLeftLayerId, source: self.peopleLeftSourceId)
                    .circleRadius(2.0)  // Más pequeño para que parezca más realista
                    .circleColor(StyleColor(.red))
                    .circleStrokeWidth(0.3)
                    .circleStrokeColor(StyleColor(.white))
                    .circleOpacity(0.9)

                // Personas lado derecho (puntos rojos)
                GeoJSONSource(id: self.peopleRightSourceId)
                    .data(.featureCollection(peopleRightCollection))

                CircleLayer(id: self.peopleRightLayerId, source: self.peopleRightSourceId)
                    .circleRadius(2.0)  // Más pequeño para que parezca más realista
                    .circleColor(StyleColor(.red))
                    .circleStrokeWidth(0.3)
                    .circleStrokeColor(StyleColor(.white))
                    .circleOpacity(0.9)

                // Círculo del primer tren (ida)
                let trainFeature = Feature(geometry: .point(Point(forwardLineCoordinatesMapbox.first!)))
                GeoJSONSource(id: trainSourceId)
                    .data(.feature(trainFeature))

                CircleLayer(id: trainLayerId, source: trainSourceId)
                    .circleRadius(2.5)
                    .circleColor(StyleColor(UIColor(red: 0.67, green: 0.71, blue: 0.18, alpha: 1.0)))
                    .circleStrokeWidth(1.5)
                    .circleStrokeColor(StyleColor(.white))
                    .circleStrokeOpacity(1.0)

                // Círculo del segundo tren (vuelta - empieza en la segunda estación)
                let train2StartIndex = 1  // Segunda estación
                let train2Feature = Feature(geometry: .point(Point(returnLineCoordinatesMapbox[train2StartIndex])))
                GeoJSONSource(id: train2SourceId)
                    .data(.feature(train2Feature))

                CircleLayer(id: train2LayerId, source: train2SourceId)
                    .circleRadius(2.5)
                    .circleColor(StyleColor(UIColor(red: 0.67, green: 0.71, blue: 0.18, alpha: 1.0)))
                    .circleStrokeWidth(1.5)
                    .circleStrokeColor(StyleColor(.white))
                    .circleStrokeOpacity(1.0)
            }

            useSimpleModel = false
            print("✅ Simulación configurada con círculo animado y líneas paralelas conectadas")
            print("   Tren 1: Primera estación → Última estación")
            print("   Tren 2: Segunda estación → Primera estación")
            print("   👥 Personas (puntos rojos) agregadas en ambos lados de cada estación")
        }


        func updateSimulation(
            isRunning: Bool,
            progress: Double,
            in mapView: MapView,
            updateProgress: @escaping (Double) -> Void,
            updateStation: @escaping (String) -> Void
        ) {
            if isRunning {
                startSimulation(in: mapView, currentProgress: progress, updateProgress: updateProgress, updateStation: updateStation)
            } else {
                stopSimulation()
            }
        }

        private func startSimulation(
            in mapView: MapView,
            currentProgress: Double,
            updateProgress: @escaping (Double) -> Void,
            updateStation: @escaping (String) -> Void
        ) {
            // Detener timer anterior si existe
            timer?.invalidate()

            var progress = currentProgress

            print("🚀 Iniciando simulación desde progreso: \(progress)")
            print("🚂 Dos trenes en líneas paralelas con direcciones opuestas")
            print("   → Tren 1: \(self.stationNames.first ?? "Primera estación") → \(self.stationNames.last ?? "Última estación")")
            print("   ← Tren 2: \(self.stationNames[self.train2StartStationIndex]) → \(self.stationNames.first ?? "Primera estación")")
            print("⏱️  Simulación ultra-acelerada: ~5-6 minutos de recorrido total")
            print("🚉 Paradas en estaciones: 2.5 segundos cada una")

            // Crear timer que actualiza la posición cada 50ms para animación más fluida
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }

                // Si está detenido en una estación, verificar si ya pasó el tiempo de parada
                if self.stoppedAtStation {
                    if let stopStartTime = self.stopStartTime {
                        let elapsedTime = Date().timeIntervalSince(stopStartTime)
                        if elapsedTime >= self.stationStopDuration {
                            // Ha pasado el tiempo, reanudar movimiento
                            self.stoppedAtStation = false
                            self.stopStartTime = nil
                            print("🚦 Saliendo de la estación")
                        } else {
                            // Todavía esperando, no mover el tren
                            return
                        }
                    }
                }

                // Detectar si está llegando a una estación (solo para el tren 1)
                let totalStations = self.stationNames.count
                let stationProgress = 1.0 / Double(totalStations - 1)
                let tolerance = 0.01

                for i in 0..<totalStations {
                    let stationProgressValue = Double(i) * stationProgress
                    if abs(progress - stationProgressValue) < tolerance && self.lastStationIndex != i {
                        // Llegó a una nueva estación
                        self.stoppedAtStation = true
                        self.stopStartTime = Date()
                        self.lastStationIndex = i
                        let stationName = self.stationNames[i]
                        print("🚉 Tren 1 detenido en estación: \(stationName)")
                        return
                    }
                }

                // Incrementar progreso (ambos trenes avanzan simultáneamente)
                progress += 0.00018  // Velocidad ultra-acelerada 8x

                // Reiniciar cuando llegue al final
                if progress >= 1.0 {
                    progress = 0.0
                    self.lastStationIndex = -1
                    print("🔄 Reinicio: Tren 1 → \(self.stationNames.first ?? "Primera estación") | Tren 2 → \(self.stationNames[self.train2StartStationIndex])")
                }

                // Actualizar el progreso en la UI
                updateProgress(progress)

                // Actualizar la estación más cercana en la UI (tren 1)
                let currentStationIndex = Int(round(progress / stationProgress))
                let clampedIndex = max(0, min(currentStationIndex, totalStations - 1))
                updateStation(self.stationNames[clampedIndex])

                // ========== TREN 1 (IDA) ==========
                // Calcular posiciones del frente y atrás del tren 1
                let frontProgress = progress
                let rearProgress = max(0.0, progress - self.trainLengthProgress)

                let frontPosition = self.interpolatePosition(progress: frontProgress, isForward: true)
                let rearPosition = self.interpolatePosition(progress: rearProgress, isForward: true)

                // Calcular bearing basado en la dirección frente-atrás
                let bearing = self.calculateBearing(from: rearPosition, to: frontPosition)
                self.currentBearing = bearing

                // Usar el punto medio del tren como posición
                let trainPosition = self.midPoint(from: rearPosition, to: frontPosition)

                // Actualizar la posición y rotación del tren 1 en el mapa
                self.updateTrainPosition(to: trainPosition, bearing: bearing, in: mapView, trainNumber: 1)

                // ========== TREN 2 (VUELTA - DIRECCIÓN INVERSA) ==========
                // El tren 2 va en dirección opuesta: desde la segunda estación hacia la primera
                // Calcular el progreso inicial basado en la segunda estación
                let train2InitialProgress = Double(self.train2StartStationIndex) / Double(totalStations - 1)

                // Progreso del Tren 2: empieza en train2InitialProgress y va hacia 0.0
                let progress2 = train2InitialProgress - progress

                // Si el progreso es negativo, el tren completó su recorrido
                let clampedProgress2 = max(0.0, progress2)

                let frontProgress2 = clampedProgress2
                let rearProgress2 = min(1.0, clampedProgress2 + self.trainLengthProgress)

                let frontPosition2 = self.interpolatePosition(progress: frontProgress2, isForward: false)
                let rearPosition2 = self.interpolatePosition(progress: rearProgress2, isForward: false)

                // Calcular bearing del tren 2 (dirección opuesta)
                // Como va en reversa, invertimos from/to para que apunte correctamente
                let bearing2 = self.calculateBearing(from: frontPosition2, to: rearPosition2)
                self.currentBearing2 = bearing2

                // Usar el punto medio del tren 2 como posición
                let train2Position = self.midPoint(from: rearPosition2, to: frontPosition2)

                // Actualizar la posición y rotación del tren 2 en el mapa
                self.updateTrainPosition(to: train2Position, bearing: bearing2, in: mapView, trainNumber: 2)

                // Mover la cámara para seguir al tren 1 (puedes cambiar esto después)
                self.followTrain(at: trainPosition, bearing: bearing, in: mapView)
            }
        }

        private func updateTrainPosition(to coordinate: CLLocationCoordinate2D, bearing: Double, in mapView: MapView, trainNumber: Int) {
            // Seleccionar IDs según el número de tren
            let sourceId = trainNumber == 1 ? trainSourceId : train2SourceId
            let layerId = trainNumber == 1 ? trainLayerId : train2LayerId
            let modelIdValue = trainNumber == 1 ? modelId : model2Id

            // Crear feature - si es modelo 3D, incluir bearing
            var trainFeature = Feature(geometry: .point(Point(coordinate)))

            if useSimpleModel {
                trainFeature.properties = [
                    modelIdKey: .string(modelIdValue)
                ]
            }

            let geoJSON: GeoJSONObject = useSimpleModel ?
                .featureCollection(FeatureCollection(features: [trainFeature])) :
                .feature(trainFeature)

            do {
                try mapView.mapboxMap.updateGeoJSONSource(
                    withId: sourceId,
                    geoJSON: geoJSON
                )

                // Actualizar la rotación del modelo si es 3D
                if useSimpleModel {
                    let adjustedBearing = bearing + modelRotationOffset
                    try mapView.mapboxMap.setLayerProperty(
                        for: layerId,
                        property: "model-rotation",
                        value: [0, 0, adjustedBearing]
                    )
                }

                // Log solo la primera actualización exitosa
                if !hasLoggedFirstUpdate && trainNumber == 1 {
                    print("✅ Primera actualización de posición exitosa")
                    print("   Modelo: \(useSimpleModel ? "3D" : "Círculo")")
                    print("   Coordenadas válidas: \(coordinate.latitude), \(coordinate.longitude)")
                    print("   Dos trenes simultáneos activados")
                    hasLoggedFirstUpdate = true
                }
            } catch {
                print("❌ Error actualizando posición tren \(trainNumber): \(error)")
            }
        }

        private func stopSimulation() {
            timer?.invalidate()
            timer = nil
        }

        private func interpolatePosition(progress: Double, isForward: Bool) -> CLLocationCoordinate2D {
            // Seleccionar las coordenadas correctas según la dirección
            let coordinates = isForward ? forwardLineCoordinates : returnLineCoordinates

            guard !coordinates.isEmpty else {
                return CLLocationCoordinate2D(latitude: 0, longitude: 0)
            }

            // Calcular el índice basado en el progreso
            let totalSegments = Double(coordinates.count - 1)
            let exactIndex = progress * totalSegments
            let lowerIndex = Int(floor(exactIndex))
            let upperIndex = min(lowerIndex + 1, coordinates.count - 1)
            let fraction = exactIndex - Double(lowerIndex)

            let start = coordinates[lowerIndex]
            let end = coordinates[upperIndex]

            // Interpolar entre dos puntos
            let lat = start.latitude + (end.latitude - start.latitude) * fraction
            let lon = start.longitude + (end.longitude - start.longitude) * fraction

            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }

        private func midPoint(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
            let lat = (start.latitude + end.latitude) / 2.0
            let lon = (start.longitude + end.longitude) / 2.0
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }

        private func calculateBearing(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
            let lat1 = start.latitude * .pi / 180
            let lat2 = end.latitude * .pi / 180
            let lon1 = start.longitude * .pi / 180
            let lon2 = end.longitude * .pi / 180

            let dLon = lon2 - lon1

            let y = sin(dLon) * cos(lat2)
            let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
            let bearingRadians = atan2(y, x)
            let bearingDegrees = bearingRadians * 180 / .pi

            return bearingDegrees
        }

        private func followTrain(at coordinate: CLLocationCoordinate2D, bearing: Double, in mapView: MapView) {
            // Mover la cámara suavemente para seguir al tren
            // La cámara ahora también rota con el bearing del tren para una vista más inmersiva
            mapView.camera.ease(
                to: CameraOptions(
                    center: coordinate,
                    zoom: 16.5,  // Zoom más cercano para ver mejor el metro
                    bearing: bearing,  // Rotar la cámara con el tren
                    pitch: 50  // Un poco más inclinado para mejor perspectiva
                ),
                duration: 1.0  // Duración más larga para movimiento más suave
            )
        }

        deinit {
            // Limpiar el timer cuando se destruya el coordinator
            timer?.invalidate()
            timer = nil
            print("🧹 Coordinator limpiado")
        }
    }
}


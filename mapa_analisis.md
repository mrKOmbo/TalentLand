# Analisis Completo del Sistema de Mapas — Atenea

## Resumen General

El mapa es el **componente central** de Atenea. Usa **Mapbox SDK** como motor principal y **MapKit** como complemento para calculos de rutas. El archivo mas grande del proyecto es `MainMapView.swift` con **4,569 lineas**. El sistema cubre: mapa interactivo, busqueda de lugares, navegacion turn-by-turn, heatmaps de demanda, simulacion del Metro CDMX, modelo 3D Tangara, marcadores de sedes FIFA, AR navigation, y modo emergencia.

---

## Arquitectura de Archivos

```
Features/Map/
├── Managers/
│   └── NavigationLoader.swift              — Singleton de MapboxNavigationProvider
├── Models/
│   ├── MapStyle.swift                      — 7 estilos de mapa (enum)
│   └── MetroLine.swift                     — Datos de 4 lineas del Metro CDMX
├── ViewModels/
│   ├── DirectionsViewModel.swift           — Calculo de rutas multi-modo
│   └── SearchViewModel.swift               — Busqueda local de 30+ lugares
├── Views/
│   ├── MainMapView.swift                   — Vista principal (4,569 lineas)
│   ├── TangaraMapView.swift                — Modelo 3D en mapa
│   ├── NavigationViewWrapper.swift         — Navegacion Mapbox turn-by-turn (1,307 lineas)
│   ├── NavigationDynamicIsland.swift       — Dynamic Island de navegacion
│   ├── DirectionsView.swift                — Panel de direcciones multi-modo
│   ├── Line3SimulationView.swift           — Simulacion de tren en Metro CDMX
│   ├── VenueBottomSheet.swift              — Bottom sheet de reservaciones
│   ├── LocationBannerView.swift            — Banner de ubicacion actual
│   ├── EmergencyModal.swift                — Modal SOS con ubicacion
│   ├── FavoritesView.swift                 — Vendedores favoritos
│   ├── RoutesView.swift                    — Rutas guardadas (placeholder)
│   ├── SidebarMenuView.swift               — Menu lateral del mapa
│   ├── MerchantLocationEditView.swift      — Edicion ubicacion del comerciante
│   ├── TripStartedView.swift               — Animacion de viaje iniciado
│   ├── DestinationListView.swift           — Lista de destinos
│   └── Components/
│       ├── CollapsibleSearchBar.swift      — Barra de busqueda colapsable
│       └── CategoryFilterScrollView.swift  — Filtro de categorias por iconos

Otros archivos relacionados:
├── Core/Services/MapboxRoutingService.swift        — API Directions de Mapbox
├── Managers/NavigationStateManager.swift           — Estado global de navegacion
├── Features/Auth/Views/MapboxMapView.swift         — Mapa para seleccion de ubicacion de negocio
├── Features/Auth/Views/BusinessLocationMapView.swift — Vista completa de ubicacion de negocio
├── Features/DemandZones/Services/DemandHeatmapBuilder.swift — Constructor de heatmap
├── Features/Menu/ProfileMapContainerView.swift     — Contenedor menu + mapa
```

---

## SDK y Dependencias

| Dependencia | Uso |
|---|---|
| `MapboxMaps` | Motor del mapa, estilos, capas, anotaciones, gestos |
| `MapboxNavigationCore` | Calculo de rutas, navegacion turn-by-turn |
| `MapboxNavigationUIKit` | UI nativa de navegacion Mapbox |
| `MapboxDirections` | Tipos de maniobras y rutas (import `internal`) |
| `MapKit` / `MKDirections` | Calculo alternativo de rutas (driving, walking, transit) |
| `CoreLocation` | GPS, coordenadas, distancias |
| `RealityKit` + `ARKit` | Navegacion AR con flechas 3D |
| `ActivityKit` | Live Activities / Dynamic Island |
| `ConfettiSwiftUI` | Celebracion visual en dias de partido |

---

## Autenticacion Mapbox

- **Token publico**: Se lee desde `Info.plist` bajo la clave `MBXAccessToken`
- El token empieza con `pk.eyJ1IjoibXJrb21ibyIs...`
- `MapboxRoutingService` lo usa para llamadas directas a la API REST
- El SDK de Mapbox lo lee automaticamente del plist

---

## Estilos de Mapa (MapStyle.swift)

7 estilos disponibles, cada uno con `StyleURI`, nombre localizado e icono SF Symbol:

| Estilo | StyleURI | Icono |
|---|---|---|
| Standard | `.standard` | `map.fill` |
| Streets | `.streets` | `building.2.fill` |
| Outdoors | `.outdoors` | `leaf.fill` |
| Light | `.light` | `sun.max.fill` |
| Dark | `.dark` | `moon.fill` |
| Satellite | `.satellite` | `globe.americas.fill` |
| Satellite Streets | `.satelliteStreets` | `map.circle.fill` |

Se puede cambiar desde el **menu lateral** (SidebarMenuView).

---

## MainMapView — Vista Principal (4,569 lineas)

### State Properties (~60 variables)

La vista principal maneja un estado complejo con ~60 `@State`, `@StateObject`, `@ObservedObject` y `@Binding`:

- **Ubicacion**: `locationManager`, `centerOnLocation`, `shouldFollowUser`, `isFirstLocationLoad`
- **Camara**: `cameraCenter`, `cameraZoom`, `cameraPitch` (inicio: zoom 1.0, centrado en lat 20, lon -100 para ver el globo completo)
- **Busqueda**: `searchViewModel`, `selectedSearchPlace`, `searchMarkers`, `isSearchBarExpanded`
- **Navegacion**: `preparedNavigation`, `showDirections`, `routePolylines`, `selectedDirectionsRouteIndex`, `selectedTransportMode`
- **Sedes FIFA**: `showVenueMarkers` (true por defecto), `selectedVenue`, `showVenueDetailModal`
- **Marcadores**: `selectedMarker`, `temporaryMarker`, `tappedCoordinate`
- **Metro**: `showLine1Simulation`, `showLine2Simulation`, `showLine3Simulation`, `showLine9Simulation`
- **Tangara 3D**: `showTangaraView`
- **Emergencia**: `showEmergencyModal`, `emergencyManager`
- **AR**: `showARPosterScanner`, `isARNavigationMode`
- **Heatmap**: `demandManager.showHeatMap`
- **Categorias**: `selectedCategory`, `isCategoryFilterExpanded`, `selectedChipId`
- **UI**: `modalState`, `sheetHeight`, `selectedMapStyle`, `confettiCounter`, `isWorldCupToday`

### Componente MapboxMainMapView

El mapa Mapbox se renderiza via `MapboxMainMapView` (un `UIViewRepresentable` definido mas abajo en MainMapView.swift) que recibe:

```swift
MapboxMainMapView(
    userLocation: locationManager.currentLocation,
    mapStyle: selectedMapStyle,
    centerOnLocation: $centerOnLocation,
    searchMarkers: allMapMarkers,
    venueMarkers: showVenueMarkers ? WorldCupVenue.allVenues : [],
    merchantMarkers: merchantManager.merchants.filter { $0.isActive && $0.currentLocation != nil },
    routePolylines: routePolylines,
    selectedRouteIndex: selectedDirectionsRouteIndex,
    selectedTransportMode: selectedTransportMode,
    cameraCenter: cameraCenter,
    cameraZoom: cameraZoom,
    cameraPitch: cameraPitch,
    shouldFollowUser: shouldFollowUser,
    isEmergencyActive: emergencyManager.isEmergencyActive,
    demandZones: demandManager.demandZones,
    showHeatMap: demandManager.showHeatMap,
    onMarkerTapped: { ... },
    onVenueTapped: { ... },
    onMerchantTapped: { ... },
    onMapTapped: { ... }
)
```

### Capas en el Mapa

1. **Marcadores de busqueda** — lugares seleccionados o filtrados por categoria
2. **Marcadores de sedes FIFA** — 16 estadios del Mundial 2026 (WorldCupVenue.allVenues)
3. **Marcadores de comerciantes** — merchants activos con ubicacion actual
4. **Polylines de ruta** — MKPolyline de rutas calculadas
5. **Heatmap de demanda** — 3 capas: glow (circulos difusos), circle (puntos), symbol (emojis)
6. **Marcadores temporales** — al tocar el mapa
7. **Flechas direccionales** — sobre la ruta de navegacion (SymbolLayer)
8. **Modelo 3D Tangara** — ModelLayer con archivo .glb

### Interacciones del Mapa

| Gesto | Accion |
|---|---|
| Tap en mapa | Crea marcador temporal + abre panel de direcciones |
| Tap en marcador | Abre panel de direcciones con info del lugar |
| Tap en sede FIFA | Abre modal de detalle de la sede |
| Tap en comerciante | Log en consola (pendiente implementar) |
| Long press | (En MapboxMapView para negocios) Agrega waypoint |
| Shake del dispositivo | Abre modal de emergencia |
| Boton ubicacion | Centra mapa en GPS del usuario + activa seguimiento |
| Boton heatmap (llama) | Toggle del mapa de demanda |
| Boton emergencia | Abre modal SOS |

---

## Sistema de Busqueda

### SearchViewModel

- **Base de datos local** de 30+ lugares hardcodeados de CDMX
- Categorias: Historico, Monumento, Parque, Museo, Cultural, Religioso, Turismo, Mirador, Barrio, Deporte, Mercado, Arqueologico, Educacion, Entretenimiento, Bar
- **Debounce** de 300ms para busqueda
- Busqueda por nombre, subtitle, categoria o direccion (case-insensitive)
- Lugares recomendados: Zocalo, Angel de la Independencia, Chapultepec, Museo de Antropologia, Bellas Artes, Basilica de Guadalupe, Xochimilco, Torre Latinoamericana, Coyoacan, Estadio Azteca

### CollapsibleSearchBar

- Barra que se **expande/colapsa** con animacion spring (0.35s, damping 0.85)
- Estado colapsado: solo icono de lupa (50x50px)
- Estado expandido: campo de texto completo + botones de accion
- Efecto "liquid glass" con ultraThickMaterial
- Modo especial si `isWorldCupToday`: icono de trofeo, colores festivos

### CategoryFilterScrollView

- Grid horizontal de iconos circulares
- Se oculta cuando el buscador esta expandido
- Toggle de expansion con chevron
- Al seleccionar categoria: obtiene lugares, agrega marcadores, centra mapa en primer lugar

---

## Sistema de Navegacion

### NavigationLoader (Singleton)

```swift
class NavigationLoader {
    static let shared = NavigationLoader()
    private let navigationProvider: MapboxNavigationProvider
    
    func loadNavigation(from:to:) async throws -> PreparedNavigation
}
```

- **CRITICO**: Solo crea UNA instancia de `MapboxNavigationProvider` (singleton)
- Usa `LocationSource.live` por defecto
- Retorna `PreparedNavigation` con rutas calculadas

### NavigationViewWrapper (1,307 lineas)

- Navegacion turn-by-turn completa de Mapbox
- Incluye **AR Navigation** con flechas 3D (RealityKit + ARKit)
- **Dynamic Island** con instrucciones de maniobra en tiempo real
- **Flechas direccionales** sobre la ruta (SymbolLayer con iconos cada 75px)
- **Deteccion de texto** en AR (TextDetectionManager)
- **EmergencyModeManager**: modo SOS con NearbyInteraction

### DirectionsView + DirectionsViewModel

- Panel inferior con **5 modos de transporte**: driving, walking, transit, cycling, rideshare
- Calcula rutas en **paralelo** usando `TaskGroup`:
  - Driving: MKDirections con `.automobile`
  - Walking: MKDirections con `.walking`
  - Transit: MKDirections con `.transit` (fallback: 1.5x tiempo de auto)
  - Cycling: estimado como 40% del tiempo de caminar
  - Rideshare: link externo (Uber/Didi)
- Soporta **rutas alternativas** (`requestsAlternateRoutes = true`)
- Modal con 3 alturas: quarter (25%), half (50%), full (92%)

### NavigationStateManager

Singleton que mantiene el estado global:
- `isNavigationActive` — si hay navegacion en curso
- `shouldOpenNavigation` — solicitud de abrir navegacion (deep links)
- `showDirections` — controla visibilidad del Tab Bar
- `pendingDemandZoneCoord` — coordenada pendiente de zona de demanda
- `merchantLocationEditMode` — modo edicion de ubicacion del merchant

### NavigationDynamicIsland

- Vista tipo Dynamic Island que muestra instruccion actual, tipo de maniobra, distancia y ETA
- Dos modos: compacto y expandido
- Se actualiza en tiempo real durante la navegacion

---

## Calculo de Rutas

### MapboxRoutingService (API REST directa)

```swift
class MapboxRoutingService {
    static let shared = MapboxRoutingService()
    
    func calculateRoute(waypoints:profile:completion:)
    func optimizeRoute(waypoints:profile:completion:)
}
```

- **Directions API**: `https://api.mapbox.com/directions/v5/mapbox/{profile}/{coordinates}`
- **Optimization API**: `https://api.mapbox.com/optimized-trips/v1/mapbox/{profile}/{coordinates}`
- Perfiles: `driving`, `walking`, `cycling`, `driving-traffic`
- Respuesta: geometria GeoJSON, distancia, duracion, pasos, maniobras
- Decodificacion con `convertFromSnakeCase`

### Modelos de Respuesta

```swift
MapboxRouteResponse → [MapboxRoute] → MapboxGeometry (coordinates [[Double]])
                                     → [MapboxLeg] → [MapboxStep] → MapboxManeuver
```

### Estimacion Simple de Tiempo (en MainMapView)

Calculo basico por distancia en linea recta:
- < 500m: velocidad caminando (5 km/h)
- 500m - 2km: caminando rapido (7.2 km/h)
- > 2km: transporte/auto (30 km/h)

---

## Heatmap de Demanda (DemandHeatmapBuilder)

### 3 Capas del Heatmap

1. **Glow Layer** (`CircleLayer`):
   - Circulos enormes con blur total (blur = 1.0)
   - Gradiente: verde-azul → amarillo → naranja → rojo segun intensidad
   - Radio variable por zoom: 15px (zoom 10) → 140px (zoom 19)
   - Emissive strength = 1.0 para efecto de brillo

2. **Circle Layer** (`CircleLayer`):
   - Puntos pequenos (radio 3px) solo visibles a zoom >= 16
   - Gradiente amarillo → naranja → rojo
   - Borde blanco semi-transparente

3. **Symbol Layer** (`SymbolLayer`):
   - Emojis de comida solo visibles a zoom >= 17
   - Categorias con emojis: 🌮 tacos, 🥤 bebidas, 🫔 tamales, 🌽 elotes, 🍦 helados, 🧃 jugos, 🍎 frutas, 🍽 antojitos, 🧁 postres

### Generacion de Datos

- Puntos simulados alrededor de un centro (Expo Santa Fe)
- 32 hotspots con densidades de 5 a 60 puntos cada uno
- Zonas: Centro Expo, Entradas, Estacionamientos, Av. Santa Fe, Vasco de Quiroga, Centro Comercial, Tec de Monterrey, Corporativos, Periferia
- Intensidad basada en distancia al centro (mas cerca = mas intenso)

---

## Simulacion del Metro CDMX

### MetroLine (Modelo)

```swift
struct MetroLine {
    let id: String
    let name: String
    let number: Int
    let color: UIColor
    let coordinates: [CLLocationCoordinate2D]
    let stationNames: [String]
    let startStation: String
    let endStation: String
}
```

### Lineas Implementadas

| Linea | Color | Terminal A | Terminal B | Estaciones |
|---|---|---|---|---|
| Linea 1 | Rosa | Observatorio | Pantitlan | 19 |
| Linea 2 | Azul | Cuatro Caminos | Tasquena | 23 |
| Linea 3 | Verde Olivo | Indios Verdes | Universidad | 21 |
| Linea 9 | Cafe | Tacubaya | Pantitlan | 12 |

### Line3SimulationView

- Simulacion visual del recorrido de un tren
- Usa `MapboxLine3SimulationMapView` (UIViewRepresentable)
- Progreso animado con estacion actual
- Tiempo promedio entre estaciones: 2 minutos
- Velocidad promedio: 35 km/h ± 3
- Muestra: estacion actual, tiempo restante, velocidad

---

## Modelo 3D Tangara (TangaraMapView)

- Archivo: `Tangara_NoTracks.glb` (modelo 3D)
- Renderizado con **ModelLayer** de Mapbox
- Escala: 50x50x50
- Pitch de camara: 60 grados (vista 3D)
- Zoom: 16
- 4 ubicaciones predefinidas: Angel de la Independencia, Zocalo, Casa Azul (Frida Kahlo), Chapultepec
- Animacion de camara con `ease(duration: 1.5)`

---

## Mapas para Registro de Negocios

### MapboxMapView (Auth)

- Mapa interactivo para seleccionar ubicacion del negocio
- Centrado inicial en CDMX (19.4326, -99.1332, zoom 12)
- Todos los gestos habilitados: pan, pinch, rotate, pitch, zoom
- **Long press** (0.5s) para colocar waypoint
- Soporta multiples waypoints para negocios moviles
- Visualizacion de ruta con polyline

### BusinessLocationMapView

- Vista completa con barra de busqueda + mapa + controles
- Calculo de ruta y distancia estimada
- Sheet para configurar la ruta
- Soporte para negocios fijos y moviles

---

## Integraciones con Otras Features

### Emergencia (SOS)
- Shake gesture → EmergencyModal con ubicacion GPS
- EmergencyModeManager cambia la visual del mapa completo
- Oculta: panel de direcciones, bottom sheet, banner, botones flotantes
- Muestra: boton verde para desactivar emergencia
- NearbyInteraction para buscar staff cercano

### AR Navigation
- Flechas 3D con RealityKit sobre la camara
- Deteccion de texto en el entorno (TextDetectionManager)
- Al detectar sede FIFA por AR: centra mapa + muestra modal

### Deep Links (schema `atenea://`)
- `NavigationStateManager.shouldOpenNavigation` para reabrir navegacion
- handleAppIntentRequests() para Siri/Shortcuts

### Live Activities / Dynamic Island
- NavigationDynamicIsland muestra instrucciones en tiempo real
- Import de ActivityKit en NavigationViewWrapper

### Sedes FIFA
- 16 estadios como WorldCupVenue con coordenadas
- Marcadores visibles por defecto en el mapa
- Modal de detalle con opcion "Como llegar"
- Bottom sheet con reservaciones

### Comerciantes
- Marcadores de merchants activos en el mapa
- MerchantLocationEditView para editar ubicacion
- Filtro por merchants activos con ubicacion != nil

### Celebracion Mundial
- Deteccion de `isWorldCupToday`
- Confetti con emojis de futbol (⚽🏆)
- Search bar con colores festivos y trofeo

### Localizacion
- Todos los strings del mapa estan localizados (25+ idiomas)
- `LocalizedString()` para textos
- Vista se recarga al cambiar idioma (`.id(languageManager.currentLanguage)`)

---

## Datos Tecnicos

| Metrica | Valor |
|---|---|
| Archivo mas grande | MainMapView.swift (4,569 lineas) |
| Segundo mas grande | NavigationViewWrapper.swift (1,307 lineas) |
| Total archivos mapa | 22 archivos Swift |
| Variables de estado en MainMapView | ~60 |
| Lugares en base de datos local | 30+ |
| Lineas del Metro | 4 (75 estaciones total) |
| Sedes FIFA en mapa | 16 |
| Estilos de mapa | 7 |
| Modos de transporte | 5 (driving, walking, transit, cycling, rideshare) |
| Hotspots del heatmap | 32 |

---

## Dependencias Externas (APIs)

1. **Mapbox Directions API** — Calculo de rutas con geometria GeoJSON
2. **Mapbox Optimization API** — Reordenamiento optimo de waypoints
3. **MapboxNavigationProvider** — Navegacion turn-by-turn nativa
4. **MKDirections (Apple)** — Rutas alternativas y transit

---

## Limitaciones Actuales

- **SearchViewModel** usa base de datos hardcodeada (sin geocoding real)
- **RoutesView** es un placeholder (no guarda rutas aun)
- **Merchant tap** solo hace log en consola
- **Transit** usa estimacion (1.5x driving) como fallback
- **Cycling** usa estimacion (0.4x walking)
- **Heatmap** genera datos simulados (no hay datos reales de demanda)
- **Metro** solo tiene 4 de las 12 lineas
- No hay persistencia de favoritos ni historial de busqueda

# 🔍 Búsqueda de Lugares - Documentación

## Descripción General

Sistema completo de búsqueda y recomendación de lugares implementado con **Mapbox Search API**, siguiendo arquitectura MVVM y mejores prácticas de SwiftUI.

---

## 📁 Archivos Creados

### 1. **SearchViewModel.swift**
`/Features/Map/ViewModels/SearchViewModel.swift`

**Responsabilidad**: Gestión de toda la lógica de búsqueda y recomendaciones

**Características**:
- ✅ Búsqueda en tiempo real con debouncing (300ms)
- ✅ Integración con Mapbox PlaceAutocomplete API
- ✅ Gestión de sugerencias y resultados
- ✅ 10 lugares recomendados precargados de CDMX
- ✅ Cálculo de distancias desde ubicación del usuario
- ✅ Manejo de estados (loading, error, success)

**Propiedades clave**:
```swift
@Published var searchText: String
@Published var suggestions: [SearchPlace]
@Published var recommendedPlaces: [SearchPlace]
@Published var isSearching: Bool
@Published var errorMessage: String?
@Published var selectedPlace: SearchPlace?
```

**Métodos principales**:
- `performSearch(query:)` - Ejecuta búsqueda con Mapbox
- `selectPlace(_:)` - Obtiene información completa de un lugar
- `distanceToPlace(_:)` - Calcula distancia al lugar
- `clearSearch()` - Limpia búsqueda actual

---

### 2. **SearchPlace Model**
`/Features/Map/ViewModels/SearchViewModel.swift` (dentro del mismo archivo)

**Modelo unificado para lugares de búsqueda y recomendaciones**

```swift
struct SearchPlace: Identifiable, Equatable {
    let id: String
    let name: String
    let subtitle: String
    var fullAddress: String?
    let category: String
    let icon: String
    var coordinate: CLLocationCoordinate2D?
    let isRecommended: Bool
    var originalSuggestion: PlaceAutocomplete.Suggestion?
}
```

**Inicializadores**:
- `init(from: PlaceAutocomplete.Suggestion)` - Desde resultado de Mapbox
- `init(id:name:subtitle:...)` - Inicializador completo manual

**Método estático**:
- `iconForCategory(_:)` - Determina ícono SF Symbol según categoría

---

### 3. **SearchScreen.swift**
`/Features/Map/Views/SearchScreen.swift`

**Vista completa de búsqueda con UI moderna**

**Componentes**:

#### Barra de búsqueda superior
- TextField con búsqueda en tiempo real
- Botón de regreso
- Indicador de carga
- Botón para limpiar búsqueda

#### Resultados de búsqueda
- Lista vertical de sugerencias
- Cada item muestra: ícono, nombre, dirección, distancia
- Tap para seleccionar

#### Lugares recomendados
- Grid 2 columnas
- Cards con diseño colorido
- 10 lugares icónicos de CDMX precargados
- Categorías con colores distintos

**Estados**:
- Estado vacío con mensaje
- Estado de búsqueda activa
- Vista de recomendaciones (por defecto)

**Subcomponentes**:
- `PlaceRow` - Fila de resultado de búsqueda
- `RecommendedPlaceCard` - Tarjeta de lugar recomendado

---

### 4. **MainMapView.swift** (Modificado)
`/Features/Map/Views/MainMapView.swift`

**Cambios realizados**:

#### Imports nuevos
```swift
import MapboxSearch
```

#### Estados agregados
```swift
@State private var showSearchScreen = false
@State private var selectedSearchPlace: SearchPlace?
@State private var searchMarkers: [SearchPlace] = []
@State private var cameraCenter: CLLocationCoordinate2D?
@State private var cameraZoom: CGFloat = 16
```

#### UI modificada
- ✅ Barra de búsqueda flotante (reemplaza botón hamburguesa)
- ✅ Botón de menú compacto al lado de la búsqueda
- ✅ SearchScreen como fullScreenCover

#### Método nuevo
```swift
private func handlePlaceSelection(_ place: SearchPlace)
```
- Agrega marcador al mapa
- Anima vuelo a la ubicación (1.2s)
- Guarda lugar seleccionado

#### MapboxMainMapView actualizado
**Nuevos parámetros**:
- `searchMarkers: [SearchPlace]`
- `cameraCenter: CLLocationCoordinate2D?`
- `cameraZoom: CGFloat`

**Coordinator mejorado**:
- `currentSearchMarkers` - Track de marcadores actuales
- `searchAnnotationManager` - Gestor de anotaciones
- `updateSearchMarkers(_:on:)` - Renderiza marcadores
- `createMarkerImage(icon:color:)` - Genera pins personalizados

**Marcadores visuales**:
- Pin con forma de gota personalizada
- Color amarillo para recomendados
- Color rojo para búsquedas
- Ícono SF Symbol dinámico según categoría
- Texto con el nombre del lugar
- Sombra y borde blanco

---

## 🎯 Lugares Recomendados

10 lugares icónicos de Ciudad de México precargados:

| # | Lugar | Categoría | Coordenadas |
|---|-------|-----------|-------------|
| 1 | Zócalo | Histórico | 19.4326, -99.1332 |
| 2 | Ángel de la Independencia | Monumento | 19.4270, -99.1676 |
| 3 | Bosque de Chapultepec | Parque | 19.4204, -99.1895 |
| 4 | Museo Nacional de Antropología | Museo | 19.4259, -99.1862 |
| 5 | Palacio de Bellas Artes | Cultural | 19.4352, -99.1412 |
| 6 | Basílica de Guadalupe | Religioso | 19.4847, -99.1177 |
| 7 | Xochimilco | Turismo | 19.2577, -99.1036 |
| 8 | Torre Latinoamericana | Mirador | 19.4337, -99.1407 |
| 9 | Coyoacán | Barrio | 19.3492, -99.1617 |
| 10 | Estadio Azteca | Deporte | 19.3029, -99.1506 |

---

## 🚀 Flujo de Usuario

### Búsqueda de Lugares

1. Usuario toca barra de búsqueda flotante
2. Se abre `SearchScreen` a pantalla completa
3. Usuario escribe en el campo de búsqueda
4. Debouncing de 300ms antes de hacer request
5. `SearchViewModel` llama a Mapbox PlaceAutocomplete API
6. Resultados se muestran en lista vertical
7. Usuario toca un resultado
8. `SearchViewModel` obtiene información completa (coordenadas)
9. `SearchScreen` se cierra
10. `MainMapView` agrega marcador al mapa
11. Cámara vuela a la ubicación con animación suave (1.2s)
12. Marcador se renderiza con ícono personalizado

### Lugares Recomendados

1. Usuario abre `SearchScreen`
2. Ve grid 2x5 con lugares recomendados
3. Cada card muestra: ícono, nombre, categoría, distancia
4. Usuario toca un lugar recomendado
5. Flujo continúa igual que búsqueda (pasos 9-12)

---

## 🎨 Diseño Visual

### Barra de Búsqueda Flotante
- Material translúcido (.ultraThinMaterial)
- Esquinas redondeadas (12px)
- Sombra sutil
- Ícono de lupa + texto placeholder
- Botón de menú compacto al lado

### SearchScreen
- Fondo sistema (.systemBackground)
- Header con botón back + campo de búsqueda
- Indicador de carga cuando isSearching
- Botón X para limpiar búsqueda

### PlaceRow (Resultados)
- Ícono circular con fondo azul claro
- Nombre en negrita
- Subtítulo en gris
- Distancia con ícono de ubicación
- Chevron derecho

### RecommendedPlaceCard
- Card con fondo gris claro
- Borde con color de categoría
- Ícono grande circular
- Badge de categoría con color
- Distancia en esquina superior
- Altura fija para grid uniforme

### Marcadores en Mapa
- Pin forma gota
- Color amarillo (recomendados) o rojo (búsqueda)
- Borde blanco grueso
- Círculo interior blanco
- Ícono SF Symbol según categoría
- Texto con nombre del lugar
- Sombra sutil

---

## 🔧 Configuración Técnica

### Dependencias
- ✅ MapboxMaps (ya instalado)
- ✅ MapboxSearch (ya instalado)
- ✅ Combine (para debouncing)

### Permisos Necesarios
- Ubicación (ya configurado en el proyecto)
- Token de Mapbox (ya configurado en Info.plist)

### Performance
- Debouncing: 300ms para evitar requests excesivos
- Límites API: Usa proximity para resultados relevantes
- Caché: Lugares recomendados precargados (no requieren API)

---

## 📊 API de Mapbox Search

### PlaceAutocomplete.suggestions()
**Input**:
```swift
let query: String  // Término de búsqueda
var options = SearchOptions()
options.proximity = userLocation  // Priorizar cerca
options.types = [.place, .address, .poi]  // Tipos permitidos
```

**Output**:
```swift
Result<[PlaceAutocomplete.Suggestion], SearchError>
```

**Campos de Suggestion**:
- `mapboxId: String?`
- `name: String`
- `description: String?`
- `categories: [String]?`

### PlaceAutocomplete.select()
**Input**:
```swift
let suggestion: PlaceAutocomplete.Suggestion
```

**Output**:
```swift
Result<PlaceAutocomplete.Result, SearchError>
```

**Campos de Result**:
- Todos los campos de Suggestion +
- `coordinate: Coordinate?` (lat/lng completos)
- Información completa del lugar

---

## 🎯 Características Implementadas

### ✅ Funcionalidades Core
- [x] Búsqueda en tiempo real con Mapbox
- [x] Autocompletado con debouncing
- [x] 10 lugares recomendados CDMX
- [x] Marcadores en mapa
- [x] Animación de vuelo a ubicación
- [x] Cálculo de distancias
- [x] Manejo de errores
- [x] Estados de carga

### ✅ UI/UX
- [x] Barra de búsqueda flotante
- [x] SearchScreen full screen
- [x] Grid de recomendaciones
- [x] Íconos dinámicos por categoría
- [x] Colores por tipo de lugar
- [x] Animaciones suaves
- [x] Estados vacíos
- [x] Indicadores de carga

### ✅ Arquitectura
- [x] Patrón MVVM
- [x] Separación de responsabilidades
- [x] Modelo unificado (SearchPlace)
- [x] Coordinador en UIViewRepresentable
- [x] Binding reactivo con Combine

---

## 🔮 Mejoras Futuras Sugeridas

### Funcionalidad
- [ ] Historial de búsquedas recientes
- [ ] Lugares favoritos guardados
- [ ] Compartir ubicación
- [ ] Filtros por categoría
- [ ] Búsqueda por voz
- [ ] Información detallada del lugar (horarios, teléfono, etc.)
- [ ] Reseñas y calificaciones
- [ ] Rutas desde ubicación actual

### UI
- [ ] Bottom sheet con detalles del lugar
- [ ] Imágenes de los lugares
- [ ] Mapa miniatura en resultados
- [ ] Modo oscuro optimizado
- [ ] Animaciones más elaboradas
- [ ] Gestos (swipe para eliminar marcadores)

### Performance
- [ ] Caché de búsquedas
- [ ] Paginación de resultados
- [ ] Optimización de renderizado de marcadores
- [ ] Clustering de marcadores cercanos

### Backend
- [ ] Lugares recomendados dinámicos según ubicación
- [ ] Lugares trending
- [ ] Personalización con ML
- [ ] Analytics de búsquedas

---

## 🐛 Debugging

### Logs Importantes
```swift
print("✅ Búsqueda exitosa: \(suggestionResults.count) resultados")
print("✅ Lugar seleccionado: \(place.name)")
print("📍 Volando a: \(place.name)")
print("✅ \(annotations.count) marcadores agregados al mapa")
```

### Errores Comunes

**"Error en búsqueda"**
- Verificar token de Mapbox en Info.plist
- Verificar conexión a internet
- Revisar límites de API

**"No se encontraron resultados"**
- Query muy específico
- Sin resultados en esa área
- Problema de encoding de caracteres

**Marcadores no aparecen**
- Verificar que `coordinate` no sea nil
- Revisar que el estilo del mapa esté cargado
- Verificar zoom del mapa

---

## 📖 Uso del Código

### Agregar más lugares recomendados
Editar `SearchViewModel.swift` en `loadRecommendedPlaces()`:

```swift
SearchPlace(
    id: "rec-11",
    name: "Nombre del Lugar",
    subtitle: "Ubicación, CDMX",
    category: "Categoría",
    icon: "sf.symbol.name",
    coordinate: CLLocationCoordinate2D(latitude: XX.XXXX, longitude: -XX.XXXX),
    isRecommended: true
)
```

### Personalizar colores de marcadores
Editar `MainMapView.swift` en `updateSearchMarkers()`:

```swift
let markerImage = createMarkerImage(
    icon: marker.icon,
    color: .systemBlue  // Cambiar color aquí
)
```

### Modificar debouncing
Editar `SearchViewModel.swift` en `setupSearchDebouncing()`:

```swift
.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)  // 500ms
```

---

## 🎉 Conclusión

Sistema completo de búsqueda y recomendación de lugares implementado con:
- ✅ **Mapbox Search API** integrado
- ✅ **10 lugares recomendados** de CDMX
- ✅ **UI moderna y pulida**
- ✅ **Arquitectura MVVM limpia**
- ✅ **Marcadores personalizados**
- ✅ **Animaciones suaves**
- ✅ **Manejo robusto de errores**

**Total de líneas de código**: ~900 líneas
**Archivos modificados/creados**: 3 archivos
**Tiempo estimado de desarrollo**: Implementación profesional completa

---

**Desarrollado con ❤️ usando Swift, SwiftUI y Mapbox**

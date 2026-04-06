# Live Activities - Atenea

Integración completa de Live Activities con Dynamic Island y Lock Screen para mostrar navegación en tiempo real.

## 🎯 Características Implementadas

### 1. **Dynamic Island** (iPhone 14 Pro+)

Muestra navegación activa en el Dynamic Island:

**Estados:**
- **Compacto**: Icono + distancia + tiempo
- **Mínimo**: Cuando hay múltiples actividades
- **Expandido**: Vista completa con instrucciones

### 2. **Lock Screen**

Widget en pantalla de bloqueo con:
- Destino y ciudad
- Distancia restante
- Tiempo estimado
- Instrucción actual de navegación
- Velocidad y calle actual

### 3. **Updates en Tiempo Real**

Se actualiza automáticamente mientras navegas:
- Distancia restante
- Tiempo estimado
- Instrucciones de giro
- Velocidad actual
- Estado de navegación

---

## 📁 Archivos Creados

```
Features/LiveActivities/
├── NavigationActivityAttributes.swift    # Modelo de datos
├── NavigationLiveActivityView.swift      # Vistas UI
├── NavigationLiveActivity.swift          # Widget config
├── LiveActivityHelper.swift              # Helper de integración
└── README_LIVE_ACTIVITIES.md             # Este archivo
```

---

## 🔧 Cómo Integrar en MainMapView

### Paso 1: Importar el Helper

```swift
// En MainMapView.swift o NavigationViewWrapper.swift
import ActivityKit  // Solo para iOS 16.1+
```

### Paso 2: Iniciar Live Activity al Comenzar Navegación

Agrega esto donde inicias la navegación (después de calcular la ruta):

```swift
// Cuando comienza la navegación
func startNavigation(to venue: WorldCupVenue, route: Route) {
    // Tu código existente de navegación...

    // Calcular distancia total
    let totalDistance = route.distance / 1000 // Convertir a km

    // Iniciar Live Activity
    LiveActivityHelper.shared.startNavigationLiveActivity(
        to: venue,
        totalDistance: totalDistance
    )

    print("🟢 Navegación y Live Activity iniciados")
}
```

### Paso 3: Actualizar Live Activity Durante Navegación

En tu observer de progreso de navegación:

```swift
// En MapboxNavigationService delegate o similar
func didUpdateProgress(_ progress: RouteProgress) {
    // Extraer información
    let distanceRemaining = progress.distanceRemaining  // En metros
    let durationRemaining = progress.durationRemaining  // En segundos
    let currentInstruction = progress.currentLegProgress.currentStepProgress.currentSpokenInstruction?.text ?? ""
    let currentSpeed = locationManager.location?.speed ?? 0  // m/s a km/h

    // Actualizar Live Activity
    LiveActivityHelper.shared.updateNavigationLiveActivity(
        distanceRemaining: distanceRemaining,
        estimatedMinutes: Int(durationRemaining / 60),
        instruction: currentInstruction,
        currentStreet: progress.currentLegProgress.currentStep.name ?? "",
        currentSpeed: currentSpeed * 3.6  // Convertir m/s a km/h
    )
}
```

### Paso 4: Finalizar Live Activity al Llegar

Cuando llegas al destino:

```swift
// Cuando se detecta que llegaste
func didArriveAtDestination() {
    // Tu código existente...

    // Finalizar Live Activity con mensaje de llegada
    LiveActivityHelper.shared.endNavigationLiveActivity()

    print("✅ Llegaste! Live Activity finalizado")
}
```

### Paso 5: Cancelar si el Usuario Cancela

Si el usuario cancela la navegación:

```swift
// Botón de cancelar navegación
Button("Cancelar") {
    // Detener navegación existente...

    // Cancelar Live Activity inmediatamente
    LiveActivityHelper.shared.cancelNavigationLiveActivity()

    print("🚫 Navegación cancelada")
}
```

---

## 📱 Ejemplo Completo de Integración

Aquí está un ejemplo completo de cómo integrar en tu MainMapView:

```swift
// En MainMapView.swift
struct MainMapView: View {
    @StateObject private var liveActivityHelper = LiveActivityHelper.shared

    // ... tu código existente ...

    // Cuando se inicia la navegación
    func handleNavigationStart(to venue: WorldCupVenue, route: Route) {
        // 1. Iniciar navegación Mapbox (tu código existente)
        startMapboxNavigation(route)

        // 2. Iniciar Live Activity
        let totalDistanceKm = route.distance / 1000
        LiveActivityHelper.shared.startNavigationLiveActivity(
            to: venue,
            totalDistance: totalDistanceKm
        )

        // 3. Configurar observer de progreso
        navigationService?.addObserver(self)
    }

    // Observer de progreso (Mapbox delegate)
    func navigationService(_ service: NavigationService,
                          didUpdate progress: RouteProgress,
                          with location: CLLocation,
                          rawLocation: CLLocation) {

        // Actualizar Live Activity cada 5 segundos aprox
        let distanceRemaining = progress.distanceRemaining
        let timeRemaining = Int(progress.durationRemaining / 60)
        let instruction = progress.currentLegProgress
            .currentStepProgress
            .currentSpokenInstruction?
            .text ?? "Continúa por esta vía"

        LiveActivityHelper.shared.updateNavigationLiveActivity(
            distanceRemaining: distanceRemaining,
            estimatedMinutes: timeRemaining,
            instruction: instruction,
            currentStreet: progress.currentLegProgress.currentStep.name ?? "",
            currentSpeed: location.speed * 3.6  // m/s a km/h
        )
    }

    // Cuando llegas
    func navigationService(_ service: NavigationService,
                          didArriveAt waypoint: Waypoint) {

        // Finalizar Live Activity
        LiveActivityHelper.shared.endNavigationLiveActivity()

        // Mostrar confetti, etc.
        showArrivalCelebration()
    }

    // Si cancela
    func cancelNavigation() {
        navigationService?.stop()

        // Cancelar Live Activity
        LiveActivityHelper.shared.cancelNavigationLiveActivity()

        // Cerrar vista
        dismiss()
    }
}
```

---

## 🎨 Personalización

### Cambiar Colores

Los colores se toman automáticamente del venue:

```swift
// El color del venue se usa en:
- Icono de ubicación
- Distancia (texto destacado)
- Background gradient del Dynamic Island
```

### Modificar Instrucciones

Puedes personalizar las instrucciones pasadas:

```swift
LiveActivityHelper.shared.updateNavigationLiveActivity(
    distanceRemaining: 500,
    estimatedMinutes: 5,
    instruction: "🏟️ Gira a la derecha hacia el Estadio Azteca",  // Personalizado
    currentStreet: "Av. Insurgentes Sur",
    currentSpeed: 45
)
```

---

## ⚙️ Configuración Requerida

### 1. Info.plist

Ya está configurado:
```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

### 2. Capabilities en Xcode

Asegúrate de tener habilitado:
- **Background Modes** → Location updates
- **Push Notifications** (opcional, para updates remotos)

### 3. Versión de iOS

Live Activities requiere:
- **iOS 16.1+** para funcionalidad básica
- **iOS 16.2+** para Dynamic Island completo
- **iPhone 14 Pro** o superior para ver Dynamic Island

---

## 🧪 Cómo Probar

### En Dispositivo Real (Recomendado)

1. **Build** en un iPhone físico (iOS 16.1+)
2. Inicia navegación a un estadio
3. Observa el Dynamic Island (iPhone 14 Pro+) o Lock Screen
4. Bloquea el teléfono → Verás el widget en Lock Screen
5. Durante navegación, el widget se actualiza automáticamente

### En Simulador

Live Activities funcionan en simulador, pero:
- ⚠️ No hay Dynamic Island (solo en hardware real)
- ✅ Puedes ver la vista de Lock Screen
- Usa **Simulator → Features → Live Activities** para debugging

### Debugging

```swift
// Verificar si están disponibles
if LiveActivityHelper.shared.isLiveActivityAvailable {
    print("✅ Live Activities disponibles")
} else {
    print("❌ Live Activities NO disponibles (iOS < 16.1 o deshabilitadas)")
}
```

---

## 🐛 Troubleshooting

### Live Activity no aparece

**Solución:**
- Verifica que `NSSupportsLiveActivities` esté en Info.plist
- Ve a Ajustes → Notificaciones → Atenea → Asegúrate que "Live Activities" esté ON
- Reinicia la app

### No se actualiza

**Solución:**
- Verifica que estés llamando `updateNavigationLiveActivity` regularmente
- Live Activities tienen un límite de updates por minuto (~4-5)
- Considera actualizar cada 3-5 segundos, no más frecuente

### No funciona en Simulador

**Solución:**
- Live Activities SÍ funcionan en simulador iOS 16.1+
- Pero el Dynamic Island NO (solo en hardware real)
- Usa un iPhone 14 Pro real para probar Dynamic Island

### "Activity authorization denied"

**Solución:**
```swift
// Pedir permisos explícitamente
if #available(iOS 16.1, *) {
    let authInfo = ActivityAuthorizationInfo()
    print("Live Activities enabled: \(authInfo.areActivitiesEnabled)")

    if !authInfo.areActivitiesEnabled {
        // Mostrar alerta al usuario
        showLiveActivityPermissionAlert()
    }
}
```

---

## 📊 Estados del Live Activity

| Estado | Descripción | Cuándo ocurre |
|--------|-------------|---------------|
| `active` | Navegación activa | Durante la ruta |
| `paused` | Navegación pausada | Usuario pausó |
| `recalculating` | Recalculando ruta | Desvío detectado |
| `arrived` | Has llegado | Llegaste al destino |

---

## 🚀 Próximas Mejoras

Ideas para expandir Live Activities:

1. **Múltiples Live Activities:**
   - Navegación + Partido en vivo simultáneos
   - Sticker desbloqueado notification

2. **Interactividad:**
   - Botón "Cancelar navegación" en Dynamic Island
   - Botón "Ver Mapa" para abrir app

3. **Push Updates:**
   - Updates remotos desde servidor
   - Notificar cambios en partidos sin abrir app

4. **Widgets Relacionados:**
   - Home Screen widget que muestra última navegación
   - Widget de "estadios visitados"

---

## 📚 Recursos

- [Apple Live Activities Documentation](https://developer.apple.com/documentation/activitykit)
- [Dynamic Island HIG](https://developer.apple.com/design/human-interface-guidelines/live-activities)
- [ActivityKit Sample Code](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)

---

**Desarrollado para Atenea - Mundial 2026** ⚽🏆


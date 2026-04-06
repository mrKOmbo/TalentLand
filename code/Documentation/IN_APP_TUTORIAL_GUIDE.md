# Tutorial In-App con Spotlight - Guía de Integración

## 📋 Descripción

Se ha implementado un sistema de tutorial **dentro de la app activa** que muestra tooltips con spotlight effect (círculo resaltado sobre fondo oscuro) para enseñar las funcionalidades de la app al usuario mientras la usa.

### Características

- ✨ **Overlay oscuro** con transparencia que oscurece toda la pantalla
- ⭕ **Círculo spotlight** que resalta la funcionalidad específica
- 💬 **Tarjeta de tooltip** con título, descripción y botones
- 🔄 **Animaciones fluidas** de entrada y pulsación
- 📍 **Posicionamiento flexible** del texto (arriba, abajo, izquierda, derecha)
- 💾 **Persistencia automática** de pasos completados

## 🏗️ Arquitectura

### Archivos Creados

```
atenea/
├── Core/
│   ├── Models/
│   │   └── TutorialHint.swift              # Modelo para tooltips
│   ├── Views/
│   │   ├── TutorialSpotlightView.swift     # Vista del spotlight y overlay
│   │   └── TutorialOverlayModifier.swift   # ViewModifier para integración
│   └── Managers/
│       └── OnboardingManager.swift         # Manager actualizado para tutorial
└── Localizations/
    ├── en.lproj/Localizable.strings        # Traducciones inglés
    └── es.lproj/Localizable.strings        # Traducciones español
```

### Componentes

1. **TutorialHint**: Modelo que define cada tooltip
2. **TutorialSpotlightView**: Vista del overlay oscuro + spotlight + tarjeta
3. **OnboardingManager**: Controla el flujo del tutorial
4. **TutorialOverlayModifier**: Facilita agregar el tutorial a cualquier vista

## 🎨 Cómo Usar

### Paso 1: Agregar el overlay a tu vista principal

En `MainMapView.swift` (o cualquier vista), agrega el modifier `.tutorialOverlay()`:

```swift
struct MainMapView: View {
    @StateObject private var tutorialManager = OnboardingManager.shared

    var body: some View {
        ZStack {
            // Tu contenido normal...
            MapView()

            // Botones y controles...
        }
        .tutorialOverlay()  // ⭐ Agregar esta línea
        .onAppear {
            // Iniciar tutorial si es primera vez
            if tutorialManager.shouldShowInAppTutorial() {
                startTutorial()
            }
        }
    }
}
```

### Paso 2: Obtener las posiciones de los elementos

Usa `GeometryReader` o almacena las posiciones de los elementos que quieres resaltar:

```swift
struct MainMapView: View {
    @State private var menuButtonFrame: CGRect = .zero
    @State private var searchButtonFrame: CGRect = .zero

    var body: some View {
        ZStack {
            // Botón de menú
            Button(action: { ... }) {
                Image(systemName: "line.3.horizontal")
            }
            .background(
                GeometryReader { geometry in
                    Color.clear.onAppear {
                        // Capturar posición del botón
                        menuButtonFrame = geometry.frame(in: .global)
                    }
                }
            )

            // Similar para otros elementos...
        }
        .tutorialOverlay()
    }
}
```

### Paso 3: Crear y mostrar hints

```swift
private func startTutorial() {
    // Crear hint para el botón de menú
    let menuHint = TutorialHint(
        id: TutorialStep.menuButton.rawValue,
        title: TutorialStep.menuButton.localizedTitle,
        description: TutorialStep.menuButton.localizedDescription,
        position: menuButtonFrame,
        arrowDirection: .down,
        textPosition: .bottom
    )

    // Mostrar hint
    tutorialManager.showHint(menuHint)
}
```

### Paso 4: Secuencia de hints

Para mostrar múltiples hints en secuencia, observa `currentStepIndex`:

```swift
struct MainMapView: View {
    @StateObject private var tutorialManager = OnboardingManager.shared
    @State private var tutorialSteps: [TutorialHint] = []

    var body: some View {
        ZStack {
            // Tu contenido...
        }
        .tutorialOverlay()
        .onChange(of: tutorialManager.currentStepIndex) { newIndex in
            // Mostrar siguiente hint
            if newIndex < tutorialSteps.count {
                tutorialManager.showHint(tutorialSteps[newIndex])
            } else {
                // Tutorial completado
                tutorialManager.dismissTutorial()
            }
        }
        .onAppear {
            if tutorialManager.shouldShowInAppTutorial() {
                prepareTutorialSteps()
                tutorialManager.startTutorial()
            }
        }
    }

    private func prepareTutorialSteps() {
        tutorialSteps = [
            TutorialHint(
                id: "menu",
                title: "Open Menu",
                description: "Access features here",
                position: menuButtonFrame,
                arrowDirection: .down,
                textPosition: .bottom
            ),
            TutorialHint(
                id: "search",
                title: "Search Places",
                description: "Find nearby locations",
                position: searchButtonFrame,
                arrowDirection: .down,
                textPosition: .bottom
            ),
            // ... más hints
        ]

        // Mostrar primer hint
        if !tutorialSteps.isEmpty {
            tutorialManager.showHint(tutorialSteps[0])
        }
    }
}
```

## 🎯 Ejemplo Completo de Integración

Aquí hay un ejemplo completo listo para usar en `MainMapView`:

```swift
import SwiftUI

struct MainMapView: View {
    @Binding var selectedTab: Int
    @Binding var isLoggedIn: Bool
    @StateObject private var tutorialManager = OnboardingManager.shared

    // Posiciones de elementos
    @State private var menuButtonFrame: CGRect = .zero
    @State private var searchButtonFrame: CGRect = .zero
    @State private var emergencyButtonFrame: CGRect = .zero
    @State private var markerFrame: CGRect = .zero

    // Tutorial
    @State private var tutorialSteps: [TutorialHint] = []

    var body: some View {
        ZStack {
            // Tu vista de mapa normal...

            // Botón de menú (top-left)
            VStack {
                HStack {
                    Button(action: { /* ... */ }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding()
                    }
                    .background(
                        GeometryReader { geo in
                            Color.clear.onAppear {
                                DispatchQueue.main.async {
                                    menuButtonFrame = geo.frame(in: .global)
                                }
                            }
                        }
                    )

                    Spacer()
                }

                Spacer()
            }
        }
        .tutorialOverlay()
        .onChange(of: tutorialManager.currentStepIndex) { newIndex in
            showNextHint(at: newIndex)
        }
        .onAppear {
            // Delay para asegurar que los frames estén listos
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if tutorialManager.shouldShowInAppTutorial() {
                    prepareTutorialSteps()
                    tutorialManager.startTutorial()
                }
            }
        }
    }

    private func prepareTutorialSteps() {
        tutorialSteps = [
            TutorialHint(
                id: TutorialStep.menuButton.rawValue,
                title: TutorialStep.menuButton.localizedTitle,
                description: TutorialStep.menuButton.localizedDescription,
                position: menuButtonFrame,
                arrowDirection: .down,
                textPosition: .bottom
            ),
            TutorialHint(
                id: TutorialStep.searchButton.rawValue,
                title: TutorialStep.searchButton.localizedTitle,
                description: TutorialStep.searchButton.localizedDescription,
                position: searchButtonFrame,
                arrowDirection: .down,
                textPosition: .bottom
            ),
            // ... más pasos
        ]
    }

    private func showNextHint(at index: Int) {
        guard index < tutorialSteps.count else {
            tutorialManager.dismissTutorial()
            return
        }

        tutorialManager.showHint(tutorialSteps[index])
    }
}
```

## 🧪 Testing

### Ver el tutorial nuevamente:

```swift
// En cualquier lugar de tu código:
OnboardingManager.shared.resetTutorial()
```

O agrega un botón de debug:

```swift
#if DEBUG
Button("Reset Tutorial") {
    OnboardingManager.shared.resetTutorial()
}
#endif
```

### Verificar estado:

```swift
// Check if tutorial should show
if OnboardingManager.shared.shouldShowInAppTutorial() {
    print("Tutorial will show")
}

// Check specific step
if OnboardingManager.shared.isStepCompleted("menu.button") {
    print("Menu step completed")
}
```

## 🎨 Personalización

### Cambiar colores del spotlight:

En `TutorialSpotlightView.swift`, modifica:

```swift
// Cambiar color del círculo
Circle()
    .stroke(Color.blue.opacity(0.8), lineWidth: 3)  // ← Cambiar aquí

// Cambiar oscuridad del overlay
.fill(Color.black.opacity(0.90))  // ← Más oscuro
```

### Cambiar animación del pulso:

```swift
withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
    pulseScale = 1.2  // ← Pulso más grande
}
```

### Posición del texto:

```swift
let hint = TutorialHint(
    // ...
    textPosition: .top  // .top, .bottom, .left, .right
)
```

## 📱 Flujo de Usuario

1. Usuario abre la app por primera vez
2. Después del login, el tutorial se activa automáticamente
3. Se muestra el overlay oscuro con el primer elemento resaltado
4. Usuario puede:
   - Presionar "Next" para avanzar
   - Presionar "Skip" para saltar todo el tutorial
   - Tocar fuera del tooltip para avanzar
5. Al completar o saltar, el tutorial no se vuelve a mostrar

## 🔧 Troubleshooting

### El spotlight no aparece en la posición correcta:

**Problema**: Los frames se capturan antes de que la vista se renderice.

**Solución**: Agrega un delay:

```swift
.onAppear {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        startTutorial()
    }
}
```

### El overlay no se muestra:

**Verificar**:
1. ¿Agregaste `.tutorialOverlay()` a la vista?
2. ¿Llamaste a `tutorialManager.showHint(hint)`?
3. ¿Los frames tienen valores válidos (no .zero)?

### El tutorial se muestra cada vez:

**Solución**: El tutorial se guardó correctamente? Verifica:

```swift
print(OnboardingManager.shared.hasCompletedInAppTutorial)
```

Si es `false` pero debería ser `true`, resetea y completa:

```swift
OnboardingManager.shared.dismissTutorial()
```

## 🚀 Próximos Pasos

1. **Agregar más elementos**: Agrega hints para todos los botones importantes
2. **Tutorial por sección**: Crea tutorials separados para Map, Community, Album
3. **Animaciones**: Mejora las animaciones de entrada/salida
4. **Gestos**: Agrega swipe para avanzar entre hints
5. **Analytics**: Rastrea qué usuarios completan el tutorial
6. **Settings**: Agrega opción para revisar el tutorial desde configuración

## 💡 Tips

- ⏰ Usa delays para asegurar que los frames estén listos
- 🎯 No uses demasiados hints (máximo 5-7)
- 📏 Verifica que los elementos resaltados sean lo suficientemente grandes (min 44x44)
- 🎨 Mantén consistencia en el diseño de los tooltips
- 📱 Prueba en diferentes tamaños de pantalla
- 🌍 Verifica que las traducciones se vean bien

## 📝 Notas

- El sistema usa `GeometryReader` para obtener posiciones
- Las posiciones son en coordenadas globales (`.frame(in: .global)`)
- El overlay tiene `zIndex: 9999` para estar siempre encima
- Los hints se guardan automáticamente en `UserDefaults`
- Puedes mostrar hints individuales sin seguir la secuencia

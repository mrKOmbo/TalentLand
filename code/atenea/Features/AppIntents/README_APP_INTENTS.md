# App Intents - Atenea

Integración completa de Apple Intelligence con Siri, Shortcuts y Spotlight para la app Atenea del Mundial 2026.

## 🎯 Características Implementadas

### 1. **Navegación por Voz**

Permite a los usuarios navegar a estadios usando Siri:

```
"Hey Siri, navega al Estadio Azteca en Atenea"
"Hey Siri, ir al MetLife Stadium con Atenea"
"Hey Siri, llévame al estadio más cercano en Atenea"
```

**Intents relacionados:**
- `NavigateToStadiumIntent` - Navega a un estadio específico
- `NavigateToNearestStadiumIntent` - Navega al estadio más cercano

### 2. **Modo Emergencia**

Activación rápida del modo emergencia:

```
"Hey Siri, activa emergencia en Atenea"
"Hey Siri, desactiva emergencia en Atenea"
"Hey Siri, alternar emergencia en Atenea"
```

**Intents relacionados:**
- `ActivateEmergencyIntent` - Activa modo emergencia
- `DeactivateEmergencyIntent` - Desactiva modo emergencia
- `ToggleEmergencyIntent` - Alterna entre activado/desactivado

### 3. **Álbum de Stickers**

Consulta tu progreso de colección:

```
"Hey Siri, ver mi álbum en Atenea"
"Hey Siri, ¿cuántos stickers tengo en Atenea?"
"Hey Siri, ¿qué stickers me faltan en Atenea?"
```

**Intents relacionados:**
- `ShowAlbumIntent` - Abre el álbum
- `GetCollectionProgressIntent` - Muestra progreso con snippet visual
- `MissingStickersIntent` - Indica cuántos faltan

### 4. **Búsqueda de Estadios**

Encuentra estadios cercanos:

```
"Hey Siri, ¿qué estadio está cerca de mí en Atenea?"
"Hey Siri, encontrar estadio cercano en Atenea"
"Hey Siri, listar estadios a 50km en Atenea"
```

**Intents relacionados:**
- `FindNearbyVenueIntent` - Encuentra el más cercano
- `ListNearbyVenuesIntent` - Lista todos en un radio

### 5. **Asistente AI Claude**

Pregunta al asistente AI:

```
"Hey Siri, pregunta a Atenea dónde comer cerca del Azteca"
"Hey Siri, recomiéndame restaurantes en Atenea"
"Hey Siri, qué visitar en Atenea"
```

**Intents relacionados:**
- `AskClaudeIntent` - Pregunta general
- `GetRecommendationsIntent` - Recomendaciones por tipo (restaurantes, cafés, atracciones, etc.)

---

## 📱 Cómo Usar

### Siri

1. Activa Siri: "Hey Siri"
2. Di uno de los comandos listados arriba
3. Siri responderá y ejecutará la acción

### Shortcuts App

1. Abre la app **Shortcuts**
2. Ve a la pestaña **Galería**
3. Busca "Atenea" - verás todos los shortcuts sugeridos
4. Toca uno para agregarlo a tu biblioteca
5. Ejecuta el shortcut o agrégalo a tu pantalla de inicio

### Spotlight Search

1. Desliza hacia abajo en la pantalla de inicio
2. Escribe el nombre de un estadio (ej: "Azteca")
3. Verás resultados de Atenea
4. Toca uno para abrir directamente en la app

---

## 🛠️ Configuración Requerida

### Para que funcionen TODOS los intents:

1. **Permisos de Ubicación**
   - Ve a **Ajustes** → **Privacidad** → **Ubicación** → **Atenea**
   - Selecciona "Siempre" o "Mientras se usa la app"

2. **Claude API Key** (para intents AI)
   - Obtén una API key de [Anthropic](https://console.anthropic.com/)
   - Configúrala en la app o agrégala a `Info.plist` con la clave `ClaudeAPIKey`
   - O guárdala en UserDefaults con la clave `claudeAPIKey`

3. **Siri**
   - Ve a **Ajustes** → **Siri y Buscar**
   - Asegúrate de que "Oye Siri" esté activado

---

## 🧩 Archivos Creados

### Core Files
```
Features/AppIntents/
├── VenueEntity.swift                  # Entity para estadios
├── NavigateToStadiumIntent.swift      # Navegación a estadios
├── EmergencyModeIntent.swift          # Modo emergencia
├── ShowAlbumIntent.swift              # Álbum y progreso
├── FindNearbyVenueIntent.swift        # Búsqueda de estadios
├── AskClaudeIntent.swift              # Asistente AI
├── AteneaAppShortcuts.swift           # Shortcuts sugeridos
└── README_APP_INTENTS.md              # Este archivo
```

### Modified Files
```
App/ios_navigationApp.swift            # Manejo de intents
Features/Album/Models/StickerAlbumModel.swift  # Sync con UserDefaults
```

---

## 🎨 Shortcuts Sugeridos (Pre-configurados)

Los siguientes shortcuts aparecerán automáticamente en la app de Shortcuts:

1. **Ir al Azteca** 🏟️ - Navega al Estadio Azteca
2. **Estadio Cercano** 📍 - Va al estadio más cerca de ti
3. **Emergencia** 🚨 - Activa modo emergencia
4. **Mi Álbum** 📖 - Abre tu álbum de stickers
5. **Mi Progreso** 📊 - Muestra cuántos stickers tienes
6. **Preguntar** 💬 - Haz una pregunta al asistente AI
7. **Restaurantes** 🍽️ - Recomienda restaurantes
8. **Atracciones** ⭐ - Sugiere lugares para visitar
9. **Cafés** ☕ - Encuentra cafeterías

---

## 🔧 Troubleshooting

### "No pude obtener tu ubicación"
- Verifica que Atenea tenga permisos de ubicación
- Abre la app una vez para que guarde tu ubicación actual

### "No pude conectarme al asistente"
- Verifica que la API key de Claude esté configurada
- Checa tu conexión a internet

### Los shortcuts no aparecen
- Asegúrate de que la app esté instalada
- Abre la app al menos una vez
- Reinicia la app de Shortcuts

### Siri no reconoce los comandos
- Usa el nombre exacto: "Atenea"
- Di el comando completo
- Prueba diciendo "en Atenea" al final

---

## 🚀 Próximos Pasos

Para la próxima fase de implementación:

1. **Live Activities** - Navegación en Dynamic Island
2. **Widgets Interactivos** - Control rápido desde home screen
3. **Spotlight Deep Linking** - Búsqueda avanzada
4. **Visual Intelligence** - Escaneo de tickets con cámara

---

## 📝 Notas Técnicas

### Comunicación entre Intent y App

Los App Intents se comunican con la app principal a través de:

1. **UserDefaults** - Para pasar datos (ej: destino de navegación)
2. **Managers compartidos** - `EmergencyModeManager`, `NavigationStateManager`, `StickerCollectionManager`
3. **Deep Links** - URL scheme `atenea://`

### Flujo de Ejecución

```
Usuario dice comando
    ↓
Siri reconoce el intent
    ↓
Intent se ejecuta (@MainActor)
    ↓
Intent escribe en UserDefaults
    ↓
App se abre (si openAppWhenRun = true)
    ↓
handleAppIntentRequests() lee UserDefaults
    ↓
Acción se ejecuta en la app
```

### Permisos Necesarios

- **Location**: Para FindNearbyVenueIntent
- **Siri & Search**: Para todos los intents
- **Background Modes**: Para navegación activa

---

## 📚 Recursos

- [Apple App Intents Documentation](https://developer.apple.com/documentation/appintents)
- [Anthropic Claude API Docs](https://docs.anthropic.com/)
- [App Shortcuts Best Practices](https://developer.apple.com/design/human-interface-guidelines/app-shortcuts)

---

**Desarrollado para Atenea - Mundial 2026** ⚽🏆

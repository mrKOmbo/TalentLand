# Spotlight Integration - Atenea

Integración completa con iOS Spotlight para permitir búsqueda y acceso directo al contenido de Atenea desde la búsqueda del sistema.

## 🎯 Qué es Spotlight

Spotlight es el sistema de búsqueda nativo de iOS. Permite a los usuarios buscar contenido **dentro de la app** directamente desde:
- 🔍 La búsqueda de iOS (deslizar hacia abajo en home screen)
- 🤖 Siri ("Busca Estadio Azteca")
- 📱 Widget de búsqueda
- 💻 iPad Search

## ✨ Qué se Indexa en Atenea

### 1. **Todos los Estadios del Mundial 2026** (16 venues)

Cada estadio es buscable con:
- Nombre del estadio ("Azteca", "MetLife", "SoFi")
- Ciudad ("Ciudad de México", "Los Angeles")
- País ("México", "USA", "Canadá")
- Keywords: "mundial", "world cup", "estadio", "2026"

**Ejemplo de búsqueda:**
```
Usuario escribe: "azteca"

Resultados de Spotlight:
🏟️ Estadio Azteca
   atenea · Ciudad de México, México
   Inauguración: 1966 • 83,264 espectadores
   Mundial 2026: 5 partidos
   [Tap para abrir navegación]
```

### 2. **Colección de Stickers** (progreso del álbum)

Buscable con:
- "mi album"
- "stickers"
- "colección"
- "panini"
- "progreso"

**Ejemplo de búsqueda:**
```
Usuario escribe: "mi album"

Resultado:
📖 Mi Álbum de Stickers
   atenea · Progreso: 5/16 stickers (31%)
   11 stickers restantes
   Mundial 2026 - Colección de Estadios
   [Tap para abrir álbum]
```

---

## 🔗 Deep Linking

Cuando el usuario toca un resultado de Spotlight:

### Venue Result → Navegación Directa

```
1. Usuario busca "Estadio Azteca"
2. Toca el resultado en Spotlight
3. Atenea abre automáticamente
4. Navegación al Azteca se inicia inmediatamente
```

### Album Result → Abre Álbum

```
1. Usuario busca "mi album"
2. Toca el resultado
3. Atenea abre directamente en el álbum de stickers
```

---

## 📁 Archivos de Implementación

```
Features/Spotlight/
├── SpotlightManager.swift         # Manager de indexación
├── README_SPOTLIGHT.md            # Este archivo
└── INTEGRATION_EXAMPLES.swift     # Ejemplos (próximo)

App/
└── ios_navigationApp.swift        # Deep link handling integrado
```

---

## 🛠️ Cómo Funciona

### Indexación Automática

Al iniciar la app, Spotlight indexa todo automáticamente:

```swift
// En ios_navigationApp.swift - Ya implementado ✅
.onAppear {
    initializeSpotlightIndex()  // Indexa en background
}
```

### Actualización Dinámica

Cada vez que se colecta un sticker, Spotlight se actualiza:

```swift
// En StickerCollectionManager - Ya implementado ✅
func collectSticker(_ stickerId: Int) {
    collectedStickers.insert(stickerId)

    // Actualiza automáticamente Spotlight
    SpotlightManager.shared.indexStickerCollection(...)
}
```

### Manejo de Resultados

Cuando el usuario toca un resultado:

```swift
// En ios_navigationApp.swift - Ya implementado ✅
.onContinueUserActivity(CSSearchableItemActionType) { userActivity in
    handleSpotlightActivity(userActivity)
    // → Abre navegación o álbum según el tipo
}
```

---

## 🎨 Personalización Avanzada

### Agregar Más Contenido al Índice

Para indexar más tipos de contenido (ej: posts, partidos):

```swift
// Ejemplo: Indexar un post de la comunidad
func indexCommunityPost(_ post: CommunityPost) {
    let attributeSet = CSSearchableItemAttributeSet(contentType: UTType.content)

    attributeSet.title = "Post de \(post.author)"
    attributeSet.contentDescription = post.content
    attributeSet.keywords = ["comunidad", "post", "mundial"]

    let item = CSSearchableItem(
        uniqueIdentifier: "post-\(post.id)",
        domainIdentifier: "com.atenea.posts",
        attributeSet: attributeSet
    )

    CSSearchableIndex.default().indexSearchableItems([item]) { error in
        // Handle error
    }
}
```

### Actualizar Índice Manualmente

```swift
// Actualizar todo el índice
SpotlightManager.shared.updateSpotlightIndex()

// Remover un venue específico
SpotlightManager.shared.removeVenue(id: venueId)

// Limpiar todo el índice
SpotlightManager.shared.clearAllIndexedContent()
```

---

## 🧪 Cómo Probar

### En Simulador (iOS 9+)

1. **Build** Atenea en simulador
2. Abre la app (esto indexa el contenido)
3. **Cierra la app** (importante - el índice se procesa)
4. **Desliza hacia abajo** en home screen para abrir Spotlight
5. **Escribe** "azteca" o "estadio"
6. Deberías ver resultados de Atenea

**Tip:** Espera 10-30 segundos después de cerrar la app para que iOS procese el índice.

### En Dispositivo Real (Recomendado)

1. Install Atenea en iPhone/iPad
2. Abre la app brevemente
3. Cierra la app
4. Espera ~30 segundos
5. Abre Spotlight (desliza hacia abajo)
6. Busca:
   - "azteca"
   - "mi album"
   - "estadio"
   - "mundial 2026"

### Verificar Indexación

```swift
// En consola de Xcode, busca estos logs:
🔍 [SPOTLIGHT] Iniciando indexación de contenido
✅ [SPOTLIGHT] 16 venues indexados
✅ [SPOTLIGHT] Colección de stickers indexada
✅ [SPOTLIGHT] Índice actualizado
```

---

## 📊 Datos de Búsqueda

### Qué se Indexa por Venue

| Campo | Ejemplo | Buscable |
|-------|---------|----------|
| **Título** | "Estadio Azteca" | ✅ Sí |
| **Ciudad** | "Ciudad de México" | ✅ Sí |
| **País** | "México" | ✅ Sí |
| **Capacidad** | "83,264 espectadores" | ❌ No (solo en descripción) |
| **Coordenadas** | Lat/Lon | ✅ Sí (mejora resultados locales) |
| **Keywords** | "mundial", "estadio", "2026" | ✅ Sí |

### Relevancia de Búsqueda

Spotlight prioriza resultados por:
1. **Coincidencia exacta** del título
2. **Ubicación** (venues cercanos aparecen primero)
3. **Frecuencia de uso** (venues que abres más aparecen primero)
4. **Recencia** (contenido recién indexado)

---

## 🐛 Troubleshooting

### Los resultados no aparecen

**Problema:** Busco "azteca" pero no veo resultados de Atenea

**Soluciones:**
1. ✅ Abre la app al menos una vez (para indexar)
2. ✅ Cierra la app y espera 30-60 segundos
3. ✅ Verifica que Spotlight esté habilitado para Atenea:
   - Ajustes → Siri y Buscar → Atenea
   - Activa "Mostrar app en Buscar"
4. ✅ Reinicia el dispositivo (limpia caché de Spotlight)

### Resultados desactualizados

**Problema:** Colecté stickers pero el progreso no se actualiza

**Soluciones:**
- La actualización es automática, pero puede tomar 1-2 minutos
- Fuerza actualización:
  ```swift
  SpotlightManager.shared.updateSpotlightIndex()
  ```

### Deep link no funciona

**Problema:** Toco un resultado pero la app no abre correctamente

**Soluciones:**
- Verifica que el handler está implementado en `ios_navigationApp.swift`
- Revisa los logs de consola para ver si el deep link se recibe
- Verifica el `uniqueIdentifier` del item indexado

### "Spotlight not available"

**Problema:** `isSpotlightAvailable` retorna `false`

**Soluciones:**
- Spotlight está disponible desde iOS 9+
- Puede estar deshabilitado en Settings → Siri & Search
- En simulador, asegúrate de usar iOS 9+

---

## ⚙️ Configuración

### Info.plist

✅ **No requiere configuración especial**

Spotlight funciona automáticamente sin agregar claves especiales a Info.plist.

### Capabilities

✅ **No requiere capabilities especiales**

### Versión de iOS

- ✅ **iOS 9+** - Core Spotlight disponible
- ✅ **iOS 10+** - Soporte para imágenes thumbnail
- ✅ **iOS 11+** - Mejor integración con Siri
- ✅ **iOS 15+** - Spotlight redesign

---

## 🚀 Mejoras Futuras

Ideas para expandir Spotlight:

### 1. Indexar Partidos

```swift
// Indexar partidos del Mundial 2026
func indexMatch(_ match: WorldCupMatch, at venue: WorldCupVenue) {
    attributeSet.title = "\(match.teams)"
    attributeSet.contentDescription = """
    \(match.stage) - \(match.date)
    \(venue.name), \(venue.city)
    """
    // Deep link → Abre detalles del partido
}
```

### 2. Historial de Navegación

```swift
// Indexar venues visitados recientemente
func indexVisitedVenue(_ venue: WorldCupVenue, visitDate: Date) {
    attributeSet.title = "Visitaste \(venue.name)"
    attributeSet.lastUsedDate = visitDate
    // Aparece en "Recientes" de Spotlight
}
```

### 3. Posts de Comunidad

```swift
// Indexar posts populares
func indexPopularPost(_ post: CommunityPost) {
    attributeSet.title = post.title
    attributeSet.contentDescription = post.content
    attributeSet.keywords = ["comunidad", "post"]
    // Deep link → Abre el post
}
```

### 4. Thumbnails

```swift
// Agregar imágenes a los resultados
if let imageData = venue.imageData {
    attributeSet.thumbnailData = imageData
    // Resultado muestra imagen del estadio
}
```

### 5. Actions en Resultados

```swift
// Agregar botones de acción en el resultado
attributeSet.supportsPhoneCall = false
attributeSet.supportsNavigation = true  // Muestra botón "Directions"
```

---

## 📚 Ejemplos de Uso

### Caso 1: Usuario busca estadio

```
1. Usuario: *Desliza hacia abajo en home screen*
2. Usuario: *Escribe "azteca"*
3. Spotlight muestra:
   🏟️ Estadio Azteca
      Ciudad de México, México
4. Usuario: *Toca el resultado*
5. Atenea abre y empieza navegación al Azteca
```

### Caso 2: Usuario busca su progreso

```
1. Usuario: *Abre Spotlight*
2. Usuario: *Escribe "mi album"*
3. Spotlight muestra:
   📖 Mi Álbum de Stickers
      5/16 stickers (31%)
4. Usuario: *Toca el resultado*
5. Atenea abre directamente en el álbum
```

### Caso 3: Siri

```
1. Usuario: "Hey Siri, busca Estadio Azteca"
2. Siri: "Encontré esto en Atenea..."
3. Usuario: *Toca el resultado*
4. Atenea abre con navegación
```

---

## 📊 Métricas y Analytics

### Rastrear Uso de Spotlight

```swift
// En handleSpotlightActivity
func handleSpotlightActivity(_ userActivity: NSUserActivity) {
    // Log para analytics
    Analytics.logEvent("spotlight_search", parameters: [
        "identifier": identifier,
        "type": type
    ])
}
```

### Contenido Más Buscado

Spotlight no proporciona analytics directamente, pero puedes rastrear:
- Qué venues se abren desde Spotlight
- Qué búsquedas llevan a conversiones
- Tasa de apertura desde Spotlight vs app icon

---

## ✅ Resumen de Implementación

| Feature | Estado | Automático |
|---------|--------|------------|
| Indexación de venues | ✅ Completo | ✅ Sí (al iniciar app) |
| Indexación de stickers | ✅ Completo | ✅ Sí (al colectar) |
| Deep linking | ✅ Completo | ✅ Sí |
| Actualización dinámica | ✅ Completo | ✅ Sí |

---

## 🎯 Checklist de Testing

- [ ] Abrir app y verificar logs de indexación
- [ ] Cerrar app y esperar 30 segundos
- [ ] Buscar "azteca" en Spotlight
- [ ] Tocar resultado y verificar navegación
- [ ] Buscar "mi album" en Spotlight
- [ ] Tocar resultado y verificar apertura de álbum
- [ ] Colectar un sticker
- [ ] Buscar "mi album" nuevamente
- [ ] Verificar que progreso se actualizó

---

**Desarrollado para Atenea - Mundial 2026** ⚽🏆

Spotlight Integration = Búsqueda instantánea de estadios desde iOS

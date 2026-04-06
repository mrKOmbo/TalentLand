# Complete Testing Guide - Apple Intelligence Features

Guía completa para probar todas las features de Apple Intelligence implementadas en Atenea.

## 📋 Features Implementadas

✅ **App Intents** - Siri & Shortcuts
✅ **Live Activities** - Dynamic Island & Lock Screen
✅ **Writing Tools** - Herramientas de escritura IA
✅ **Spotlight** - Búsqueda de contenido

---

## 🧪 Testing Checklist General

### Pre-requisitos

- [ ] Xcode instalado y actualizado
- [ ] Dispositivo iOS 18+ (recomendado) o simulador
- [ ] API Key de Claude configurada (para intents de AI)
- [ ] Permisos de ubicación habilitados

---

## 1️⃣ App Intents Testing

### Configuración Inicial

```bash
1. Build app en dispositivo o simulador
2. Run una vez para registrar los intents
3. Esperar 10-20 segundos
4. Los intents estarán disponibles
```

### Test 1.1: Siri - Navegación a Estadio

**Comando:**
```
"Hey Siri, navega al Estadio Azteca en Atenea"
```

**Resultado Esperado:**
- ✅ Siri responde: "Iniciando navegación al Estadio Azteca..."
- ✅ Atenea abre automáticamente
- ✅ Navegación se inicia al Azteca

**Debug:**
```swift
// Busca en logs:
🧭 [APP INTENT] Navegación programada a Estadio Azteca
🧭 [APP INTENT] Procesando navegación pendiente a Estadio Azteca
```

### Test 1.2: Siri - Modo Emergencia

**Comando:**
```
"Hey Siri, activa emergencia en Atenea"
```

**Resultado Esperado:**
- ✅ Siri: "Modo emergencia activado. Mantente seguro."
- ✅ App abre con modo emergencia activo (pantalla roja)

### Test 1.3: Siri - Progreso de Álbum

**Comando:**
```
"Hey Siri, ¿cuántos stickers tengo en Atenea?"
```

**Resultado Esperado:**
- ✅ Siri responde con número de stickers
- ✅ Muestra snippet visual con barra de progreso
- ✅ No necesita abrir la app

### Test 1.4: Shortcuts App

**Pasos:**
1. Abre app **Shortcuts**
2. Busca "Atenea"
3. Deberías ver 10 shortcuts sugeridos

**Shortcuts esperados:**
- Ir al Azteca
- Estadio Cercano
- Emergencia
- Mi Álbum
- Mi Progreso
- Buscar Estadio
- Preguntar
- Restaurantes
- Atracciones
- Cafés

**Test un shortcut:**
1. Tap en "Mi Progreso"
2. Siri responde con tu progreso
3. Ve snippet visual

---

## 2️⃣ Live Activities Testing

⚠️ **Nota:** Live Activities requiere Widget Extension configurado. Ver README_LIVE_ACTIVITIES.md para setup completo.

### Test 2.1: Iniciar Live Activity

**Pasos:**
1. Inicia navegación a cualquier estadio
2. Live Activity debería iniciarse automáticamente

**Resultado Esperado (iPhone 14 Pro+):**
- ✅ Dynamic Island muestra: 📍 500m · 5min
- ✅ Long press Dynamic Island → Vista expandida
- ✅ Muestra destino, distancia, tiempo, instrucción

**Resultado Esperado (Cualquier iPhone con iOS 16.1+):**
- ✅ Lock Screen widget visible
- ✅ Muestra navegación en tiempo real
- ✅ Se actualiza cada 3-5 segundos

### Test 2.2: Actualización en Tiempo Real

**Durante navegación:**
- ✅ Distancia disminuye
- ✅ Tiempo estimado se actualiza
- ✅ Instrucciones cambian
- ✅ Velocidad se muestra

### Test 2.3: Finalizar Live Activity

**Al llegar:**
- ✅ Mensaje: "¡Has llegado a tu destino!"
- ✅ Live Activity se cierra después de 2 segundos
- ✅ Dynamic Island se limpia

### Test 2.4: Cancelar Navegación

**Al cancelar:**
- ✅ Live Activity se cierra inmediatamente
- ✅ Dynamic Island desaparece
- ✅ Lock Screen widget se elimina

**Debug:**
```swift
// Logs esperados:
✅ [LIVE ACTIVITY] Navegación iniciada: Estadio Azteca
🔄 [LIVE ACTIVITY] Actualizado: 500m, 5min
✅ [LIVE ACTIVITY] Navegación finalizada
```

---

## 3️⃣ Writing Tools Testing

### Test 3.1: Verificar Disponibilidad

**Requisito:** iOS 18.0+

**Pasos:**
1. Ve a CommunityView
2. Tap en campo de texto para crear post
3. Escribe: "hoy fui al azteca fue increible"
4. Selecciona el texto (long press)

**Resultado Esperado:**
- ✅ Menú contextual muestra "Writing Tools"
- ✅ Opciones: Proofread, Rewrite, etc.

### Test 3.2: Proofread (Corregir)

**Input:**
```
"hoy fui al azteca fue increible"
```

**Pasos:**
1. Selecciona texto
2. Tap "Writing Tools"
3. Tap "Proofread"

**Output Esperado:**
```
"Hoy fui al Azteca. Fue increíble."
```

### Test 3.3: Rewrite (Reescribir)

**Input:**
```
"estuvo bien el partido"
```

**Pasos:**
1. Selecciona texto
2. "Writing Tools" → "Rewrite"

**Output Esperado (variable):**
```
"El partido fue excelente"
o
"La experiencia del partido fue muy buena"
```

### Test 3.4: Make Professional

**Input:**
```
"me gusto mucho super cool"
```

**Output Esperado:**
```
"La experiencia fue excepcional"
```

### Test 3.5: Translate

**Input:**
```
"Hello, how are you?"
```

**Pasos:**
1. Selecciona
2. "Writing Tools" → "Translate" → "Spanish"

**Output:**
```
"Hola, ¿cómo estás?"
```

### Test 3.6: AISearchView

**Pasos:**
1. Ve a chat con Claude
2. Escribe pregunta mal formulada
3. Usa Writing Tools para mejorarla
4. Envía a Claude

**Ejemplo:**
```
Antes: "donde comer cerca azteca"
Después: "¿Dónde puedo encontrar buenos restaurantes cerca del Estadio Azteca?"
```

---

## 4️⃣ Spotlight Testing

### Test 4.1: Indexación Inicial

**Pasos:**
1. Build y run Atenea
2. Abre la app por 5 segundos
3. Cierra la app (swipe up)
4. **Espera 30-60 segundos** (importante)

**Debug:**
```swift
// Busca en logs de Xcode:
🔍 [SPOTLIGHT] Iniciando indexación de contenido
✅ [SPOTLIGHT] 16 venues indexados
✅ [SPOTLIGHT] Colección de stickers indexada
✅ [SPOTLIGHT] Índice actualizado
```

### Test 4.2: Búsqueda de Estadio

**Pasos:**
1. Desliza hacia abajo en home screen (abre Spotlight)
2. Escribe: "azteca"

**Resultado Esperado:**
```
🏟️ Estadio Azteca
   atenea · Ciudad de México, México
   Inauguración: 1966 • 83,264 espectadores
   Mundial 2026: 5 partidos
```

**Variaciones de búsqueda:**
- "azteca" ✅
- "mexico city" ✅
- "estadio" ✅
- "mundial 2026" ✅
- "sofi stadium" ✅

### Test 4.3: Búsqueda de Álbum

**Pasos:**
1. Abre Spotlight
2. Escribe: "mi album"

**Resultado Esperado:**
```
📖 Mi Álbum de Stickers
   atenea · Progreso: 5/16 stickers (31%)
   11 stickers restantes
   Mundial 2026 - Colección de Estadios
```

### Test 4.4: Deep Link desde Spotlight

**Test A: Abrir Estadio**
1. Busca "Estadio Azteca" en Spotlight
2. Tap en el resultado
3. **Esperado:** Atenea abre y empieza navegación al Azteca

**Test B: Abrir Álbum**
1. Busca "mi album" en Spotlight
2. Tap en el resultado
3. **Esperado:** Atenea abre directamente en el álbum

**Debug:**
```swift
// Logs esperados al tocar resultado:
🔍 [SPOTLIGHT] Usuario tocó resultado: venue-UUID
🔍 [SPOTLIGHT] Abriendo desde búsqueda: venue-UUID
🔍 [SPOTLIGHT] Iniciando navegación a Estadio Azteca desde búsqueda
```

### Test 4.5: Actualización Dinámica

**Pasos:**
1. Abre Atenea
2. Colecta un sticker (simula visitando estadio)
3. Cierra app
4. Espera 30 segundos
5. Busca "mi album" en Spotlight

**Resultado Esperado:**
- ✅ Progreso actualizado (ej: 6/16 en vez de 5/16)

---

## 5️⃣ Integration Testing

Pruebas que involucran múltiples features juntas.

### Test 5.1: Siri → Spotlight

**Pasos:**
1. "Hey Siri, busca Estadio Azteca"
2. Siri muestra resultado
3. Tap en resultado

**Esperado:**
- ✅ Atenea abre
- ✅ Navegación empieza
- ✅ Si disponible, Live Activity se inicia

### Test 5.2: Spotlight → Live Activity

**Pasos:**
1. Busca "MetLife Stadium" en Spotlight
2. Tap resultado
3. Navegación empieza
4. Bloquea el teléfono

**Esperado:**
- ✅ Live Activity visible en Lock Screen
- ✅ Se actualiza en tiempo real

### Test 5.3: Writing Tools → App Intent

**Pasos:**
1. Escribe pregunta mal formulada en AISearchView
2. Usa Writing Tools para mejorarla
3. Envía pregunta a Claude via App Intent

**Esperado:**
- ✅ Texto mejorado
- ✅ Claude responde apropiadamente

---

## 🐛 Troubleshooting

### App Intents no aparecen

**Problema:** Siri dice "No encontré eso"

**Soluciones:**
1. Reinstala la app
2. Espera 1-2 minutos después de build
3. Ve a Ajustes → Siri y Buscar → Atenea → Verifica permisos
4. Reinicia el dispositivo
5. Intenta: "Hey Siri, shortcuts de Atenea"

### Live Activities no funciona

**Problema:** No aparece Dynamic Island

**Soluciones:**
1. Verifica iOS 16.1+ (16.2+ para Dynamic Island)
2. Verifica que `NSSupportsLiveActivities` esté en Info.plist
3. Ve a Ajustes → Notificaciones → Atenea → "Live Activities" ON
4. Requiere Widget Extension (ver README_LIVE_ACTIVITIES.md)
5. Dynamic Island solo en iPhone 14 Pro+

### Writing Tools no disponible

**Problema:** No veo opción "Writing Tools"

**Soluciones:**
1. Requiere iOS 18.0+
2. Verifica que estás usando `TextField` o `TextEditor` nativo
3. Selecciona texto primero (long press)
4. Busca botón ✨ en teclado
5. Puede no estar disponible en todos los dispositivos/regiones

### Spotlight no muestra resultados

**Problema:** Busco pero no aparece Atenea

**Soluciones:**
1. Abre app al menos una vez
2. Cierra app y espera 30-60 segundos
3. Ajustes → Siri y Buscar → Atenea → "Mostrar app en Buscar" ON
4. Reinicia dispositivo (limpia caché Spotlight)
5. Reinstala app

---

## 📊 Testing Matrix

| Feature | iOS Mínimo | Simulador | Dispositivo | Setup Requerido |
|---------|-----------|-----------|-------------|-----------------|
| **App Intents** | 16.0+ | ✅ Funciona | ✅ Funciona | Permisos Siri |
| **Live Activities** | 16.1+ | ⚠️ Sin Dynamic Island | ✅ Completo | Widget Extension* |
| **Writing Tools** | 18.0+ | ✅ Funciona | ✅ Funciona | Ninguno |
| **Spotlight** | 9.0+ | ✅ Funciona | ✅ Funciona | Permisos Buscar |

*Widget Extension no está configurado aún (código listo, requiere target)

---

## 🎯 Quick Test Script

Script rápido para verificar que todo funciona:

### 5-Minute Test

```bash
1. Build & Run app
   ✅ Logs de indexación Spotlight

2. "Hey Siri, mi progreso en Atenea"
   ✅ Respuesta con snippet

3. Busca "azteca" en Spotlight
   ✅ Resultado visible
   ✅ Tap → Navegación

4. Escribe en CommunityView
   ✅ Selecciona texto
   ✅ "Writing Tools" disponible

5. Inicia navegación
   ✅ [Si Widget Extension] Live Activity visible
```

### Full Test (30 minutos)

Sigue todos los tests 1.1 - 5.3 de esta guía.

---

## 📝 Test Report Template

```markdown
## Test Session Report

**Fecha:** 2025-XX-XX
**Dispositivo:** iPhone XX (iOS XX.X)
**Build:** Atenea vX.X

### App Intents
- [ ] Siri Navegación: ✅/❌
- [ ] Siri Emergencia: ✅/❌
- [ ] Siri Progreso: ✅/❌
- [ ] Shortcuts App: ✅/❌

### Live Activities
- [ ] Inicio Live Activity: ✅/❌
- [ ] Dynamic Island: ✅/❌/N/A
- [ ] Lock Screen: ✅/❌
- [ ] Actualización en vivo: ✅/❌

### Writing Tools
- [ ] Proofread: ✅/❌/N/A (iOS < 18)
- [ ] Rewrite: ✅/❌/N/A
- [ ] Translate: ✅/❌/N/A

### Spotlight
- [ ] Indexación: ✅/❌
- [ ] Búsqueda venues: ✅/❌
- [ ] Búsqueda álbum: ✅/❌
- [ ] Deep linking: ✅/❌

### Issues encontrados:
1. ...
2. ...

### Notas:
...
```

---

## 🚀 Automated Testing (Futuro)

Ideas para tests automatizados:

```swift
// XCTest para App Intents
func testNavigateToVenueIntent() {
    let intent = NavigateToStadiumIntent()
    intent.venue = aztecaEntity

    let result = try await intent.perform()
    XCTAssertTrue(result.dialog.contains("Azteca"))
}

// XCTest para Spotlight
func testSpotlightIndexing() {
    SpotlightManager.shared.indexAllVenues()

    wait(for: [indexingExpectation], timeout: 5.0)

    XCTAssertEqual(indexedItemsCount, 16)
}
```

---

**¡Happy Testing!** 🧪

Recuerda: Cada feature funciona independientemente. Si una falla, las demás seguirán funcionando.


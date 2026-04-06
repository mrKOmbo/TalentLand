# 🎨 Diseño de Búsqueda - Inspirado en Google Maps 2024-2025

## 📐 Filosofía de Diseño

El diseño está inspirado en **Google Maps moderno (2024-2025)** pero con un toque único y personalizado:

### Principios Clave
- ✅ **Floating Cards** - Tarjetas flotantes sobre el mapa
- ✅ **Contexto Visible** - El mapa siempre visible de fondo
- ✅ **Bottom Sheet** - Resultados en hoja inferior deslizable
- ✅ **Material You** - Esquinas muy redondeadas (28px)
- ✅ **Glassmorphism** - Efecto de vidrio translúcido
- ✅ **Minimalismo** - Diseño limpio y espacioso

---

## 🔍 Barra de Búsqueda

### Características Visuales

```
┌─────────────────────────────────────────────────────┐
│  🔍  Buscar en el mapa...                    👤     │
└─────────────────────────────────────────────────────┘
```

**Especificaciones**:
- **Border Radius**: 28px (super redondeado)
- **Padding Horizontal**: 18px
- **Padding Vertical**: 14px
- **Material**: `.ultraThinMaterial` (glassmorphism)
- **Sombra**: `12px blur`, `4px offset`, `0.12 opacity`
- **Altura**: ~56px total

**Elementos**:
1. **Ícono de búsqueda** (izquierda)
   - SF Symbol: `magnifyingglass`
   - Tamaño: 18pt
   - Peso: Medium
   - Color: Gris

2. **TextField** (centro)
   - Placeholder: "Buscar en el mapa"
   - Fuente: System 16pt
   - Sin borde
   - Auto-corrección deshabilitada

3. **Indicador de estado** (derecha-centro)
   - **Loading**: ProgressView escalado 0.8x
   - **Con texto**: Botón X para limpiar

4. **Avatar de perfil** (derecha)
   - Círculo con gradiente azul
   - Ícono de persona
   - Tamaño: 32x32
   - Acceso al menú

### Posicionamiento
- **Top**: 56pt desde el top
- **Horizontal**: 16pt de margin

---

## 📊 Bottom Sheet de Resultados

### Diseño Visual

```
┌───────────────────────────────────────┐
│          ─────                        │  ← Handle bar
│                                       │
│  Resultados                           │  ← Header
│                                       │
│  ⚪ Zócalo                  → 1.2 km  │  ← Item
│     Histórico                         │
│  ─────────────────────────            │
│  ⚪ Palacio de Bellas Artes → 0.8 km  │
│     Cultural                          │
│  ─────────────────────────            │
│  ...                                  │
└───────────────────────────────────────┘
```

### Especificaciones

**Container**:
- **Border Radius**: 24px (continuous)
- **Material**: `.ultraThinMaterial`
- **Sombra**: `20px blur`, `-5px offset Y`, `0.15 opacity`
- **Max Height**: 400px
- **Transición**: `.move(edge: .bottom)`

**Handle Bar**:
- Ancho: 36px
- Alto: 5px
- Radius: 2.5px
- Color: Gris 0.3 opacity
- Margin Top: 12px
- Margin Bottom: 8px

**Header "Resultados"**:
- Fuente: System 14pt, Semibold
- Color: Secondary
- Padding: 20px horizontal, 8px bottom

**Lista de Resultados**:
- ScrollView vertical
- Hasta 8 resultados visibles
- Espaciado entre items: 0 (dividers)

---

## 🎯 Items de Resultado

### Anatomía de un Item

```
┌────────────────────────────────────────────────┐
│  ⚪  Nombre del Lugar              ›      │
│      Categoría • 1.2 km                   │
└────────────────────────────────────────────────┘
```

**Estructura**:

1. **Ícono Circular** (izquierda)
   - Círculo gris claro
   - Tamaño: 40x40
   - Ícono SF Symbol 18pt en azul
   - Spacing: 16px del texto

2. **Información** (centro)
   - **Nombre**: System 16pt, Medium, Primary color
   - **Categoría + Distancia**: System 13pt, Secondary
   - Separador: Bullet point "•"
   - Spacing vertical: 4px

3. **Chevron** (derecha)
   - SF Symbol: `chevron.right`
   - Tamaño: 13pt, Semibold
   - Color: Gris 0.4 opacity

**Padding**:
- Horizontal: 20px
- Vertical: 12px

**Dividers**:
- Inset izquierdo: 76px (después del ícono)
- Solo entre items, no al final

---

## 🌊 Animaciones y Transiciones

### Bottom Sheet
```swift
.transition(.move(edge: .bottom))
```
- Entra desde abajo
- Sale hacia abajo
- Duración: Sistema (0.3s aprox)

### Tap en Resultado
```swift
withAnimation(.easeInOut(duration: 1.2)) {
    // Animación de vuelo
}
```
- Cierra bottom sheet
- Limpia búsqueda
- Vuela a ubicación (1.2s)

---

## 🎨 Colores y Materiales

### Paleta

| Elemento | Color/Material |
|----------|----------------|
| Barra de búsqueda | `.ultraThinMaterial` |
| Bottom sheet | `.ultraThinMaterial` |
| Avatar | `Color.blue.gradient` |
| Ícono búsqueda | Gris |
| Texto primario | `.primary` (adaptativo) |
| Texto secundario | `.secondary` |
| Íconos de lugares | Azul |
| Fondo íconos | `.systemGray6` |
| Handle bar | Gris 0.3 opacity |
| Chevron | Gris 0.4 opacity |

### Sombras

**Barra de búsqueda**:
```swift
.shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
```

**Bottom Sheet**:
```swift
.shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: -5)
```

---

## 📏 Espaciado

### Sistema de Spacing

| Tipo | Valor |
|------|-------|
| Extra Small | 4px |
| Small | 8px |
| Medium | 12px |
| Large | 16px |
| Extra Large | 20px |
| XXL | 24px |

### Aplicación

- **Entre elementos UI**: 12-16px
- **Padding interno cards**: 18-20px
- **Margin de pantalla**: 16px
- **Entre texto**: 4-6px
- **Vertical spacing items**: 12px

---

## 🔄 Estados Interactivos

### Barra de Búsqueda

**Estados**:
1. **Vacía**
   - Placeholder visible
   - Solo ícono de búsqueda + avatar

2. **Escribiendo**
   - TextField activo (focus)
   - Teclado visible
   - Bottom sheet aparece con resultados

3. **Con texto + Buscando**
   - ProgressView visible
   - TextField con texto

4. **Con texto + Resultados**
   - Botón X visible
   - Bottom sheet con resultados

### Items de Resultado

**Normal**:
- Fondo: `.systemBackground`

**Presionado**:
- Sin feedback visual (`.plain` button style)
- Acción inmediata

**Después de tap**:
- Bottom sheet se cierra
- Búsqueda se limpia
- Mapa vuela a ubicación

---

## 📱 Responsive Design

### Adaptabilidad

**Bottom Sheet**:
- Máximo 400px de alto
- Se adapta al contenido
- Scroll si hay más de ~5 resultados
- Se extiende a los bordes (horizontal: 0)

**Barra de Búsqueda**:
- Se adapta al ancho de pantalla
- Padding horizontal constante (16px)
- Elementos internos flexible

**Safe Areas**:
- Bottom sheet: `.ignoresSafeArea(edges: .bottom)`
- Permite extenderse bajo el área del home indicator

---

## 🎭 Diferencias con Google Maps Original

### Mejoras Únicas

1. **Avatar Personalizado**
   - Google Maps: Foto de perfil
   - Nuestra app: Gradiente azul con ícono

2. **Material Translúcido**
   - Más glassmorphism
   - Mejor integración con el mapa

3. **Esquinas Más Redondeadas**
   - 28px vs 16px de Google
   - Estilo más moderno

4. **Iconografía**
   - SF Symbols en lugar de Material Icons
   - Más consistente con iOS

5. **Bottom Sheet**
   - Bordes más redondeados (24px)
   - Handle bar más visible
   - Mejor contraste

---

## 🚀 Performance

### Optimizaciones

1. **Lazy Loading**
   - Solo 8 resultados máximo
   - `.prefix(8)` para limitar

2. **Debouncing**
   - 300ms delay en búsqueda
   - Evita requests excesivos

3. **Material Rendering**
   - `.ultraThinMaterial` es eficiente
   - Renderizado por GPU

4. **Transiciones**
   - Nativas de SwiftUI
   - Optimizadas por el sistema

---

## 📐 Comparación Diseños

### Google Maps 2024
```
┌──────────────────┐
│ 🔍 Search...  👤 │  ← Menos redondeado (16px)
└──────────────────┘

┌──────────────────┐
│ ──               │  ← Handle bar sutil
│ Place Name    ›  │  ← Menos espaciado
│ Category         │
└──────────────────┘
```

### Nuestra App (Estilo Único)
```
┌───────────────────┐
│ 🔍 Buscar...   👤 │  ← Más redondeado (28px)
└───────────────────┘

┌───────────────────┐
│      ─────        │  ← Handle bar visible
│                   │
│ Resultados        │  ← Header explícito
│                   │
│ ⚪ Place Name  ›  │  ← Más espaciado
│    Category • 1km │  ← Info adicional
└───────────────────┘
```

---

## 🎯 Accesibilidad

### Consideraciones

1. **Tamaños Táctiles**
   - Barra búsqueda: ~56px alto ✅
   - Items: 64px+ alto ✅
   - Avatar: 44x44 ✅

2. **Contraste**
   - Material translúcido garantiza legibilidad
   - Texto secondary cumple WCAG AA

3. **Navegación**
   - Teclado soportado (FocusState)
   - Botones accesibles
   - Swipe para cerrar bottom sheet

4. **VoiceOver**
   - Labels implícitos en TextField
   - Botones con acciones claras

---

## 💡 Tips de Uso

### Para Desarrolladores

1. **Modificar Colores**
```swift
// Avatar
Circle()
    .fill(Color.purple.gradient) // Cambiar aquí

// Íconos
.foregroundColor(.orange) // Cambiar aquí
```

2. **Ajustar Radios**
```swift
// Barra búsqueda
.cornerRadius(20) // Menos redondeado

// Bottom sheet
RoundedRectangle(cornerRadius: 16) // Menos redondeado
```

3. **Cambiar Altura Bottom Sheet**
```swift
.frame(maxHeight: 300) // Más bajo
```

---

## 🎉 Resumen

Un diseño **moderno**, **limpio** y **funcional** inspirado en Google Maps 2024-2025 pero con personalidad propia:

✅ Floating search bar super redondeada
✅ Bottom sheet elegante con handle bar
✅ Glassmorphism sutil
✅ Animaciones suaves
✅ Totalmente integrado en el mapa
✅ Sin pantallas adicionales
✅ Accesible y responsive

**El resultado**: Una experiencia de búsqueda familiar pero única. 🚀

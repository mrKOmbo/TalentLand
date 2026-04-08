# Atenea - Design System MASTER
> Source of Truth para todos los componentes SwiftUI

---

## Brand Context
Proyecto del hackathon Genius Arena / Talent Land 2026.
Patrocinado por Fundación Coppel y Coppel Emprende.
**Los colores y tipografía DEBEN seguir el Coppel Brand Toolkit 2024.**

---

## Pattern
Marketplace / Directory — Map-Centric
- Hero: Search bar + mapa interactivo
- Categories: tipos de vendedor con color coding
- Featured Listings: tarjetas de vendedores cercanos
- Trust/Safety: SOS, verificación de negocios
- CTA Vendor: "Registra tu negocio"

---

## Colors (Coppel Brand Toolkit 2024)

### Primary Palette
| Token | Hex | Uso |
|---|---|---|
| coppelBlue | #1C42E8 | Primario, navbar, CTAs principales |
| coppelYellow | #F0D224 | Accents, highlights, vendor pins activos |
| darkBlue | #081754 | Texto principal, headlines en fondo claro |
| white | #FFFFFF | Backgrounds, texto en fondo oscuro |

### Secondary Palette (para Atenea)
| Token | Hex | Uso |
|---|---|---|
| lightBlue | #1CA8F7 | Mapa, servicios, info states |
| green | #0ABF4F | Confirmaciones, negocios abiertos, éxito |
| orange | #FFAE43 | Comida/tacos, warm states, food category |
| red | #FF594D | SOS, alertas, errores |
| beige | #EEE8E3 | Background de cards, superficies suaves |
| darkGrey | #4A4A4A | Texto secundario, subtítulos |

### Vendor Category Colors (del Suggested Category Colors Coppel)
| Categoría | Hex | Color Name |
|---|---|---|
| Comida (tacos, tamales) | #FFAE43 | Orange |
| Bebidas | #0ABF4F | Green |
| Artesanías | #7D42FF | Purple |
| Servicios turísticos | #1CA8F7 | Light Blue |
| Transporte | #4A4A4A | Dark Grey |
| Souvenirs | #FF594D | Red |

### Reglas de Color (Coppel Brand Toolkit)
- ❌ NO usar negro #000000
- ❌ NO usar tints/transparencias del amarillo
- ❌ NO gradientes diagonales ni radiales
- ❌ NO colores fuera del sistema
- ✅ Texto en fondo claro: darkBlue #081754
- ✅ Texto en fondo oscuro: white #FFFFFF
- ✅ Headlines en fondo darkBlue: coppelYellow #F0D224

---

## Typography (SwiftUI — Coppel Intent)

Coppel usa: Reckless (serif) + Sharp Sans No.2 (geometric sans) + Monosten (mono)
En SwiftUI nativo mapeamos con SF Pro equivalentes:

| Rol Coppel | Font SwiftUI | Weight | Design |
|---|---|---|---|
| HEADLINE (Reckless) | .largeTitle / .title | .medium | .serif |
| HEADER 2 (Sharp Sans Bold) | .title2 / .title3 | .bold | .rounded |
| SUBHEADER (Sharp Sans Bold) | .headline | .bold | .rounded |
| BODY (Sharp Sans Medium) | .body | .medium | .rounded |
| CTA (Sharp Sans Bold) | .callout | .bold | .rounded |
| EYEBROW (Monosten) | .caption2 | .regular | .monospaced |
| METADATA (Monosten) | .caption | .regular | .monospaced |

### Reglas de Tipografía (Coppel Brand Toolkit)
- ❌ NO all caps
- ❌ NO stretch/distorsión
- ❌ NO gradientes en texto
- ❌ NO justified text
- ✅ Sentence case siempre
- ✅ Leading 120% mínimo en body

---

## Motion (SwiftUI)
- Transiciones de página: .easeInOut(duration: 0.3)
- Hover/tap states: .spring(response: 0.3, dampingFraction: 0.7)
- Map annotation entrance: .spring()
- ⚠️ Respetar accessibilityReduceMotion

---

## Spacing Scale
4pt base grid: 4, 8, 12, 16, 24, 32, 48, 64

---

## Outdoor / Accessibility Overrides
(Atenea se usa en exteriores, luz solar directa)
- Contraste mínimo: 7:1 (AAA) — más estricto que WCAG AA
- Tamaño mínimo de texto en mapa: caption (.caption2 = 11pt mínimo)
- Tap targets: mínimo 44×44pt
- Modo daltonismo: 4 modos implementados (ya existente en app)

---

## Anti-patterns para Atenea
- ❌ Fotos genéricas de stock (usar fotos reales de negocios)
- ❌ Booking flows complejos (reducir fricción al máximo)
- ❌ AI purple/pink gradients
- ❌ Dark mode (no contemplado en Brand Toolkit Coppel)
- ❌ Neon colors fuera del sistema Coppel

---

## Pre-delivery Checklist
- [ ] Contraste AAA en todos los textos sobre mapa
- [ ] Tap targets ≥ 44×44pt
- [ ] Soporte RTL activo (ya implementado)
- [ ] 25+ idiomas (ya implementado)
- [ ] prefers-reduced-motion respetado
- [ ] Dynamic Type funcional
- [ ] Daltonismo ×4 activo
- [ ] Todos los iconos SF Symbols (no emojis)

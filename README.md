# Atenea

**Plataforma de comercio movil urbano** — Ciudad de Mexico · FIFA World Cup 2026

Atenea digitaliza el comercio ambulante de CDMX conectando vendedores informales con clientes locales y turistas internacionales mediante ubicacion en tiempo real, rutas inteligentes, comunicacion por Bluetooth y recomendaciones con IA.

## Problema

En una metropoli como CDMX, el comercio ambulante es parte fundamental de la identidad urbana. Sin embargo, no existe ninguna herramienta que permita a los clientes saber donde estan sus vendedores favoritos en tiempo real. El cliente se queda con las ganas y el comerciante pierde ventas por falta de visibilidad.

## Solucion

Atenea es un ecosistema bidireccional con tres roles: **cliente**, **comerciante** y **administrador**.

---

## Features implementadas

### Mapa interactivo (Mapbox)
- Mapa con marcadores de comerciantes activos (naranja = ambulante, morado = fijo)
- 16 sedes FIFA World Cup 2026 con informacion completa de partidos
- Busqueda por categorias: bares, restaurantes, cafes, museos, parques, mercados
- Navegacion turn-by-turn con Mapbox Navigation SDK
- Animacion de globo terraqueo al primer uso con transicion 3D
- Seguimiento de ubicacion con giroscopio y brujula
- Detalle completo del comerciante al tocar su marcador (productos, precios, timbre, QR)
- Movimiento libre del mapa — el seguimiento se desactiva al arrastrar

### Registro de comerciantes
- Registro con nombre, categoria (tacos, tamales, helados, elotes, frutas, jugos, antojitos, bebidas, postres), productos con precios y emoji
- Tipo de movilidad: fijo o ambulante
- Seleccion de ubicacion o trazado de ruta con waypoints en mapa interactivo
- Subida de fotos de productos a Supabase Storage
- Verificacion Coppel Emprende

### Rutas inteligentes (comerciante ambulante)
- Trazado de rutas con multiples waypoints durante el registro
- Deteccion automatica de proximidad a la ruta (150m)
- Banner de inicio de ruta cuando el comerciante esta cerca
- Polyline de ruta dibujada en el mapa con barra de progreso animada
- Indicador flotante con emoji del negocio, progreso %, waypoint actual y boton de terminar
- Ubicacion del comerciante actualizada en tiempo real en Supabase

### Radar BLE (Bluetooth Low Energy)
- Comerciantes activos transmiten presencia como BLE peripheral
- Servicio GATT personalizado: nombre, categoria, emoji, estado de ruta
- Clientes escanean como BLE central y descubren comerciantes cercanos (~30-50m)
- Funciona completamente sin internet
- Vista de Radar con intensidad de senal (fuerte/media/debil)

### Timbre (sistema de aviso)
- Cliente envia timbre al comerciante: Quiero comprar, Tengo una pregunta, Ven rapido
- Comerciante responde: Ya voy, Esperame ahi, Estoy ocupado, Ya cerre
- Chat bidireccional con burbujas y timestamps
- Transmision peer-to-peer via BLE cuando ambos estan en rango
- Notificaciones con haptic feedback

### Asistente IA (Claude)
- Chatbot con Claude (claude-sonnet-4-5-20250929)
- Analiza ubicacion, hora, preferencias para recomendar comercios
- Modo UltraThink: analisis contextual profundo con respuesta JSON estructurada
- Motor de prediccion de demanda (PredictionEngine) para zonas de alta demanda

### Realidad aumentada
- Escaner AR con RealityKit + ARKit
- Detecta sedes del Mundial y jugadores a traves de la camara
- Al detectar una sede, el mapa se centra automaticamente con animacion de vuelo
- Album digital Panini con stickers coleccionables desbloqueables por AR

### Autenticacion biometrica
- Login con Face ID / Touch ID (LocalAuthentication)
- Credenciales almacenadas en Keychain del dispositivo
- Sesion persistente con restauracion automatica

### Red mesh de emergencia
- Apple NearbyInteraction + MultipeerConnectivity
- Alertas SOS sin conexion a internet
- Activacion por shake gesture
- Panel de gestion para administradores

### Dynamic Island y Live Activities
- Navegacion visible en Dynamic Island con distancia, tiempo e instrucciones
- Compatible con pantalla de bloqueo (iOS 16.1+)

### Pagos peer-to-peer (Tap to Pay)
- Sistema de cobro entre comerciante y cliente
- Flujo completo: monto, QR, confirmacion

### Sistema de reputacion (Street Cred)
- Puntuacion algoritmica basada en actividad, respuesta a timbres, tiempo activo
- Badge de confianza (Trust Level) visible en perfil del comerciante

### QR del negocio
- Generacion automatica de codigo QR con info del negocio
- Pagina web publica del comerciante con productos y ubicacion (Supabase sync)

### Localizacion
- 25+ idiomas con deteccion automatica del dispositivo
- Soporte RTL (arabe, hebreo, urdu)
- Strings localizadas para es, en, fr, de, pt, zh, ja, ko, hi, ar y mas

### Accesibilidad
- Alto contraste, 4 modos de daltonismo, TTS, tamano de texto ajustable
- Apple Watch con guia haptica por vibracion
- Siri Shortcuts: AskClaude, FindNearby, NavigateToStadium, Emergency, ShowAlbum

### Celebracion del Mundial
- Modo especial con confeti animado y colores festivos
- Bordes arcoiris en buscador y chips de categorias

### Otros
- Deep links con schema `atenea://`
- Feed comunitario via Mastodon
- Landing page web (Tailwind CSS) desplegada en Netlify

---

## Stack tecnico

| Tecnologia | Uso |
|---|---|
| SwiftUI | Interfaz nativa iOS, arquitectura MVVM |
| Mapbox Maps + Navigation SDK | Mapas, rutas, navegacion turn-by-turn |
| Core Bluetooth (BLE) | Radar de proximidad comerciante-cliente |
| RealityKit + ARKit | Escaner AR, stickers coleccionables |
| NearbyInteraction + MultipeerConnectivity | Red mesh de emergencia |
| Claude API (Anthropic) | Chatbot IA contextual |
| Supabase (PostgreSQL) | Backend: DB, realtime, storage |
| LocalAuthentication + Keychain | Autenticacion biometrica |
| WidgetKit + ActivityKit | Dynamic Island, Live Activities |
| App Intents | Siri Shortcuts (5 intents) |
| Mastodon API | Feed comunitario |
| Tailwind CSS | Landing page web |

## Backend

**Actual:** Supabase (PostgreSQL) con sincronizacion en tiempo real, REST API y Storage para fotos de productos.

**Escalabilidad planeada:** AWS Amplify con Cognito, AppSync (GraphQL + Subscriptions), DynamoDB (geohash GSI), S3 y Amazon Location Service.

## Estructura del proyecto

```
code/atenea/
  Core/
    Config/          — APIConfiguration
    Managers/        — UserManager, MerchantManager, RouteTrackingManager
    Models/          — User, Merchant, Product, MerchantRoute
    Services/        — Supabase, BiometricAuth, Keychain, Mapbox, Mastodon, QR
    Theme/           — CoppelColors, CoppelTheme, CoppelTypography
    Utilities/       — LanguageManager, LocalizedString
  Features/
    AR/              — Escaner AR, stickers, menu AR callejero
    Album/           — Album Panini digital
    Auth/            — Login, registro, onboarding, seleccion de rol
    Chat/            — Claude AI, traductor de voz
    Community/       — Feed Mastodon
    DemandZones/     — Heatmap de demanda, predicciones
    Home/            — Dashboard cliente y comerciante
    Map/             — Mapa principal, rutas, marcadores, paneles
    Menu/            — Sidebar, perfil
    Merchant/        — QR del negocio, agregar productos
    Payment/         — Tap to Pay, cobros, historial
    Presence/        — Detalle de comerciante, lista de cercanos
    Radar/           — BLE scan/advertise
    Reputation/      — Vista de reputacion
    StreetCred/      — Manager, modelos, vistas de puntuacion
    Timbre/          — Manager, modelos, chat, notificaciones
    WorldCup/        — Sedes, detalle, lista de venues
web/                 — Landing page (Netlify)
```

## Perfiles de usuario

| Rol | Descripcion |
|---|---|
| **Cliente** | Rastrea comerciantes, envia timbres, navega con AR, recibe recomendaciones IA |
| **Comerciante** | Registra negocio, traza rutas, recibe timbres, cobra con Tap to Pay |
| **Administrador** | Panel de emergencias, gestion de usuarios, estadisticas |

## Usuarios de prueba

| Email | Rol |
|---|---|
| `emi@atenea.com` | Admin |
| `sebas@atenea.com` | Cliente |
| `don.taco@atenea.com` | Comerciante |
| `maria.elotes@atenea.com` | Comerciante |
| `pepe.carnitas@atenea.com` | Comerciante |

## Configuracion

1. Clonar el repositorio
2. Crear `code/Secrets.xcconfig` con las API keys (archivo en `.gitignore`):
   ```
   CLAUDE_API_KEY = sk-ant-...
   STRIPE_SECRET_KEY = sk_test_...
   ```
3. Abrir `code/atenea.xcodeproj` en Xcode
4. Build & Run en dispositivo fisico (BLE y AR requieren hardware real)

## Contexto

Atenea digitaliza el comercio ambulante de CDMX aprovechando el Mundial 2026. Conecta vendedores informales (tacos, tamales, helados, etc.) con clientes locales y turistas internacionales. Llena un vacio que Google Maps no cubre: la visibilidad del comercio informal en tiempo real.

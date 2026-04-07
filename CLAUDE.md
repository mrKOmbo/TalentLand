# Atenea — Plataforma de comercio móvil urbano (FIFA World Cup 2026, CDMX)

## Reglas de trabajo — SIEMPRE
- Ejecuta la tarea mínima pedida. No hagas nada extra que no se haya solicitado explícitamente.
- NUNCA crees archivos .md, README, guías, documentación ni resúmenes de lo que hiciste.
- NUNCA crees archivos de configuración, scripts auxiliares ni carpetas adicionales salvo que se te pidan.
- Al terminar una tarea, responde solo con lo que se pidió. Sin explicaciones largas ni listas de "próximos pasos".
- Si algo es ambiguo, pregunta UNA sola pregunta puntual antes de proceder.
- Prefiere soluciones simples y directas. Evita sobre-ingeniería.
- No refactorices código existente que no sea parte del alcance de la tarea.

## Stack técnico (implementado)
- **Frontend iOS**: SwiftUI — iOS primario
- **Mapas**: Mapbox SDK (token en Info.plist: `pk.eyJ1IjoibXJrb21ibyIs...`)
- **IA / Chat**: Claude API — modelo `claude-sonnet-4-5-20250929` (ClaudeAPIService.swift)
- **Auth**: UserManager con 3 usuarios hardcodeados (emi@, sebas@, don.taco@) — sin backend real aún
- **Emergencias**: Apple NearbyInteraction + MultipeerConnectivity (red mesh SOS sin internet)
- **AR**: RealityKit + ARKit (escáner de posters y jugadores)
- **Localización**: 25+ idiomas, RTL, detección automática (LanguageManager.swift)
- **Live Activities**: NavigationActivityAttributes (implementado, pendiente activar)
- **Siri / Shortcuts**: App Intents (AskClaude, FindNearby, NavigateToStadium, Emergency, ShowAlbum)
- **Deep links**: schema `atenea://`

## Stack planeado (aún no implementado)
- AWS Amplify / Cognito / AppSync / DynamoDB / S3
- Amazon Location Service
- Backend real con persistencia

## Perfiles de usuario
1. **Comerciante** — registra negocio/productos, traza rutas, ve mapa de demanda, recibe alertas de clientes cercanos, lanza promociones, panel de gestión
2. **Cliente** — rastrea comerciantes en tiempo real, navegación AR, chatbot IA para recomendaciones, mensajería directa, accesibilidad (voz, Apple Watch háptico), álbum Panini digital
3. **Administrador** — gestión de plataforma

## Criterios de calidad del proyecto (ten en cuenta al implementar)
- **Impacto social**: favorece al comercio informal/local; el código debe reflejar inclusión y accesibilidad real
- **Innovación**: prioriza features que no existen en Google Maps u otras apps (rutas de comerciantes, zonas de demanda, timbre de aviso, red mesh de emergencia)
- **Mérito técnico**: código limpio, arquitectura sólida, seguridad, buenas prácticas Swift/AWS
- **Escalabilidad**: diseña pensando en picos de demanda (evento masivo tipo Mundial); serverless debe escalar automáticamente
- **Viabilidad**: mantén la solución práctica e implementable; evita dependencias innecesarias

## Arquitectura del código
- Organización: `Core/` (global) + `Features/` (por módulo)
- Managers singleton: UserManager, NavigationStateManager, MenuStateManager, AccessibilitySettingsManager, LanguageManager, NearbyInteractionManager
- Navegación: ContentView como controlador central → Splash → Onboarding → Login → TabBar (4 tabs)
- Roles: `admin` (staff panel), `user` (cliente), `merchant` (comerciante) — enum en User.swift
- API key Claude: se lee desde UserDefaults o Info.plist (`CLAUDE_API_KEY`)

## Features implementadas
- Mapa Mapbox con búsqueda, marcadores, rutas, menú lateral
- Chat Claude (simple) + UltraThink (análisis contextual con JSON)
- Escáner AR: sedes del Mundial y jugadores (colección de stickers)
- Álbum Panini digital (modelo completo, vista funcional)
- Feed comunidad vía Mastodon
- Sistema SOS con NearbyInteraction (sin internet)
- Accesibilidad: alto contraste, daltonismo ×4, TTS, tamaño de texto
- 16 estadios del Mundial 2026 con datos completos
- Panel Staff/Admin con gestión de emergencias
- Dynamic Island para navegación activa

## Estado actual del branch `sebas`
- `Features/Home/` — carpeta nueva, en construcción
- `PostService.swift` — eliminado
- `ContentView`, `UserManager`, `User`, `CommunityView`, `SimpleTabBar`, `Info.plist` — modificados

## Contexto de negocio
Atenea digitaliza el comercio ambulante de CDMX aprovechando el Mundial 2026. Conecta vendedores informales (tacos, tamales, helados, etc.) con clientes locales y turistas internacionales mediante ubicación en tiempo real, rutas inteligentes y recomendaciones con IA. Llena un vacío que Google Maps no cubre.

# Atenea — Plataforma de comercio móvil urbano (FIFA World Cup 2026, CDMX)

## Reglas de trabajo — SIEMPRE
- Ejecuta la tarea mínima pedida. No hagas nada extra que no se haya solicitado explícitamente.
- NUNCA crees archivos .md, README, guías, documentación ni resúmenes de lo que hiciste.
- NUNCA crees archivos de configuración, scripts auxiliares ni carpetas adicionales salvo que se te pidan.
- Al terminar una tarea, responde solo con lo que se pidió. Sin explicaciones largas ni listas de "próximos pasos".
- Si algo es ambiguo, pregunta UNA sola pregunta puntual antes de proceder.
- Prefiere soluciones simples y directas. Evita sobre-ingeniería.
- No refactorices código existente que no sea parte del alcance de la tarea.

## Stack técnico
- **Frontend iOS**: SwiftUI + AWS Amplify SDK
- **Mapas**: MapLibre GL (SDK nativo)
- **Backend (serverless)**: AWS Amplify como orquestador único
- **Auth**: Amazon Cognito (User Pools + Identity Pools) — biometría Face ID
- **API**: AWS AppSync — GraphQL + Subscriptions (WebSocket para tiempo real)
- **DB**: Amazon DynamoDB — Single-Table Design con Geohash GSI
- **Storage**: Amazon S3 (fotos de productos, multimedia)
- **Mapas/Geocoding**: Amazon Location Service (Map Tiles + Geocoding)
- **Multiplataforma**: iOS primario; Android secundario

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

## Contexto de negocio
Atenea digitaliza el comercio ambulante de CDMX aprovechando el Mundial 2026. Conecta vendedores informales (tacos, tamales, helados, etc.) con clientes locales y turistas internacionales mediante ubicación en tiempo real, rutas inteligentes y recomendaciones con IA. Llena un vacío que Google Maps no cubre.

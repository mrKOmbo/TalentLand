# 🤖 Chat con Claude - Guía de Configuración

Esta guía te ayudará a configurar y usar el chat con Claude AI en la app Atenea.

## 📋 Tabla de Contenidos

- [Características](#características)
- [Configuración Inicial](#configuración-inicial)
- [Cómo Usar](#cómo-usar)
- [Funcionalidades](#funcionalidades)
- [Troubleshooting](#troubleshooting)

---

## ✨ Características

### 1. **Chat Claude** 💬
- Chat conversacional con Claude AI (modelo Sonnet 4.5)
- Recomendaciones de lugares con coordenadas GPS
- Lugares clickeables que abren en el mapa
- Direcciones integradas con MapBox
- Historial de búsquedas

### 2. **UltraThink** 🧠
- Análisis contextual avanzado basado en:
  - Tu ubicación actual
  - Hora del día (mañana/tarde/noche)
  - Clima (opcional)
  - Tus preferencias guardadas
- Recomendaciones personalizadas con prioridad
- Navegación directa al mapa

### 3. **Memory Settings** 💾
- Guarda tus preferencias:
  - Comidas favoritas (11 opciones)
  - Preferencias de cafeterías
  - Restricciones dietéticas
  - Consideraciones especiales
  - Unidad de medida (millas/kilómetros)
- Perfil de usuario personalizado

---

## 🚀 Configuración Inicial

### Paso 1: Obtener tu Claude API Key

1. **Visita la Consola de Anthropic**
   - URL: [https://console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys)

2. **Crea una cuenta o inicia sesión**
   - Si no tienes cuenta, regístrate en [https://console.anthropic.com](https://console.anthropic.com)
   - Completa el proceso de verificación

3. **Genera una nueva API Key**
   - En el dashboard, ve a "API Keys"
   - Haz clic en "Create Key"
   - Dale un nombre descriptivo (ej: "Atenea App")
   - **¡IMPORTANTE!** Copia la key inmediatamente, no podrás verla de nuevo

4. **Verifica tu crédito**
   - Anthropic ofrece $5 USD de crédito gratis para nuevas cuentas
   - Puedes agregar más crédito en "Billing" si es necesario

### Paso 2: Configurar la API Key en Atenea

#### Opción A: Desde la App (Recomendado)

1. Abre la app Atenea
2. Toca el botón **"Chat Claude"** (morado) debajo de la barra de búsqueda
3. Toca el ícono de **llave (🔑)** en la parte superior
4. Toca **"Obtener API Key"** para abrir la consola de Anthropic
5. Pega tu API key en el campo de texto
6. Toca **"Guardar API Key"**

#### Opción B: Configuración Manual (Info.plist)

1. Abre el proyecto en Xcode
2. Navega a `atenea/Info.plist`
3. Agrega una nueva entrada:
   - **Key**: `CLAUDE_API_KEY`
   - **Type**: String
   - **Value**: Tu API key (sk-ant-api...)
4. Compila y ejecuta la app

---

## 📱 Cómo Usar

### Chat Claude

1. **Abrir el Chat**
   - Toca el botón **"Chat Claude"** (morado) debajo de la barra de búsqueda

2. **Hacer Preguntas**
   - Escribe tu pregunta en el campo de texto
   - Ejemplos:
     - "¿Dónde puedo comer tacos cerca de mí?"
     - "Recomiéndame cafés en la Roma Norte"
     - "Lugares turísticos en el centro histórico"

3. **Interactuar con Lugares**
   - Claude responderá con lugares que incluyen un botón clickeable
   - Toca cualquier lugar para:
     - Ver su ubicación en el mapa
     - Obtener direcciones paso a paso

4. **Ver Historial**
   - Toca **"History"** para ver tus búsquedas anteriores
   - Puedes buscar en el historial o eliminarlo

### UltraThink

1. **Abrir UltraThink**
   - Toca el botón **"UltraThink"** (cyan) debajo de la barra de búsqueda

2. **Generar Recomendaciones**
   - Toca **"Generar Recomendaciones"**
   - UltraThink analizará automáticamente:
     - Tu ubicación actual
     - La hora del día
     - Tus preferencias guardadas

3. **Explorar Recomendaciones**
   - Cada recomendación incluye:
     - **Prioridad** (⭐ 1-5 estrellas)
     - **Razón contextual** (por qué es relevante ahora)
     - **Horario sugerido**
     - **Duración estimada**
     - **Tags** y categorías
   - Toca **"Ver en Mapa"** o **"Direcciones"** para navegar

4. **Actualizar Análisis**
   - Toca **"Actualizar Análisis"** para generar nuevas recomendaciones

### Memory Settings

1. **Abrir Memory**
   - En el Chat Claude, toca el ícono de **cerebro (🧠)**

2. **Configurar Preferencias**
   - **Favorite Foods**: Selecciona tus comidas favoritas
   - **Coffee Shop Preferences**: Cadenas grandes o cafés locales
   - **Dietary Considerations**: Restricciones alimentarias
   - **Special Considerations**: Accesibilidad o sensibilidad sensorial
   - **Measurement Preferences**: Millas o kilómetros

3. **Guardar**
   - Toca **"Update Memory"** para guardar tus preferencias
   - Claude usará esta información para personalizar recomendaciones

4. **Ver Perfil**
   - Toca el ícono de **persona** en la esquina superior derecha
   - Verás un resumen de todas tus preferencias guardadas

---

## 🎯 Funcionalidades

### Chat Claude
- ✅ Chat conversacional con IA
- ✅ Respuestas con lugares clickeables
- ✅ Coordenadas GPS precisas
- ✅ Integración con MapBox para direcciones
- ✅ Historial de búsquedas
- ✅ Configuración de API key desde la app

### UltraThink
- ✅ Análisis contextual de ubicación
- ✅ Recomendaciones basadas en la hora del día
- ✅ Sistema de prioridades (1-5 estrellas)
- ✅ Razones contextuales para cada recomendación
- ✅ Navegación directa al mapa
- ✅ Actualización de recomendaciones

### Memory
- ✅ 11 tipos de comida favorita
- ✅ Preferencias de cafetería
- ✅ Restricciones dietéticas
- ✅ Consideraciones especiales (accesibilidad)
- ✅ Unidad de medida personalizable
- ✅ Perfil de usuario visual

---

## 🔧 Troubleshooting

### El chat no responde

1. **Verifica tu API Key**
   - Ve a configuración (ícono 🔑)
   - Asegúrate de que el estado sea "Configurado" (círculo verde)
   - Si es naranja, la key no está configurada correctamente

2. **Verifica tu crédito en Anthropic**
   - Ve a [https://console.anthropic.com/settings/billing](https://console.anthropic.com/settings/billing)
   - Asegúrate de tener crédito disponible

3. **Verifica tu conexión a internet**
   - El chat requiere conexión a internet para funcionar

### Error "Invalid API Key"

- Tu API key puede haber expirado
- Genera una nueva en [https://console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys)
- Guárdala nuevamente en la app

### Los lugares no aparecen en el mapa

1. **Permisos de ubicación**
   - Ve a Configuración > Privacidad > Servicios de ubicación
   - Asegúrate de que Atenea tenga permisos

2. **Claude no está enviando coordenadas**
   - Claude debería incluir el formato `[LUGAR: Nombre | LAT: ## | LON: ##]`
   - Si no lo hace, intenta reformular tu pregunta
   - Ejemplo: "Dame 3 restaurantes cerca con sus ubicaciones exactas"

### UltraThink no genera recomendaciones

1. **Verifica permisos de ubicación**
   - UltraThink necesita tu ubicación para funcionar

2. **Configura tus preferencias**
   - Ve a Memory Settings y guarda al menos algunas preferencias
   - Esto mejorará la calidad de las recomendaciones

---

## 💡 Tips y Mejores Prácticas

### Para mejores resultados con Chat Claude:

1. **Sé específico**
   - ❌ "restaurantes"
   - ✅ "restaurantes italianos cerca del centro histórico"

2. **Pide coordenadas si no aparecen**
   - "Dame 3 opciones con sus ubicaciones exactas"

3. **Usa el contexto**
   - "Quiero cenar cerca de donde estoy, algo económico"

### Para UltraThink:

1. **Configura tus preferencias primero**
   - Cuantas más preferencias configures, mejores serán las recomendaciones

2. **Úsalo en diferentes momentos del día**
   - Las recomendaciones cambian según la hora

3. **Actualiza el análisis**
   - Si te mueves a otro lugar, genera nuevas recomendaciones

---

## 📊 Costos

- **Modelo usado**: Claude Sonnet 4.5
- **Costo aproximado**: ~$0.003 por mensaje de chat
- **Costo aproximado**: ~$0.01 por análisis UltraThink
- **Crédito gratis**: $5 USD para nuevas cuentas
- **Esto equivale a**: ~1,600 mensajes de chat o ~500 análisis UltraThink

---

## 🔒 Privacidad y Seguridad

- ✅ Tu API key se guarda de forma segura en tu dispositivo
- ✅ No se comparte con terceros
- ✅ Las preferencias se guardan localmente
- ✅ Las conversaciones no se almacenan en servidores externos
- ✅ Anthropic procesa las solicitudes de forma segura

---

## 📞 Soporte

Si tienes problemas:

1. **Verifica esta guía completa**
2. **Revisa la documentación de Anthropic**: [https://docs.anthropic.com](https://docs.anthropic.com)
3. **Contacta soporte de Anthropic**: [support@anthropic.com](mailto:support@anthropic.com)

---

## 🎉 ¡Disfruta tu chat con Claude!

Ahora estás listo para usar todas las funcionalidades del chat con Claude en Atenea. ¡Explora, pregunta y descubre nuevos lugares! 🗺️✨

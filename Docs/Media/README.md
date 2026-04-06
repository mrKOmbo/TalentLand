# Atenea - Hackathon CSC Changemakers 2025

## Resumen del Proyecto

**Objetivo:** "Garantizar que el Mundial sea accesible para todos"

### Pitch
El Mundial es el evento que une al mundo, pero ¿realmente todos pueden disfrutarlo por igual? Atenea utiliza la inteligencia artificial directamente en tu iPhone para eliminar barreras. Desde un aficionado en silla de ruedas buscando la mejor rampa en el estadio, hasta una persona con ansiedad social necesitando una ruta menos concurrida, nuestra app convierte cada trayecto en una experiencia segura, independiente e inclusiva. No usamos la nube, protegemos tu privacidad y funcionamos incluso sin conexión a internet en estadios llenos. Atenea no es solo un mapa, es un pasaporte a la inclusión.

## Características Principales

### Features Indispensables
- Día especial: la app luce diferente el día del partido
- Sistema de navegación accesible para personas con discapacidad motriz, visual, auditiva o cognitiva

### Implementaciones Clave

#### 1. Ubicación y Prevención de Aglomeraciones
- **feat-001**: Ayuda a evitar aglomeraciones, muestra el estado actual del transporte (caminando, métodos de transporte) y ayuda a prevenirse
- **feat-002**: Crea una red mesh para emergencias si no se tiene red

#### 2. Navegación con AR
- **feat-001**: La navegación se hace con ayuda de Create ML entrenado con un dataset que cruza las necesidades de accesibilidad del usuario con las características de cada punto de interés en los estadios. Se integra usando Core ML. Los datos de accesibilidad no abandonan el teléfono
- **feat-002**: iPhone y Apple Watch ofrecen navegación usando giroscopio y vibraciones, de zonas de peligro y para continuar, pueden hacer dictado con pasos necesarios e indicaciones (resaltar visualmente), descripción de objetos
- **feat-003**: Creación de álbum especial con todas las sedes para no tener que escribir, solo detectar y empezar viaje
- **feat-004**: Detección de Pegatinas Panini, enfocado en dar premios por completar colecciones haciendo las cartas únicas y completar colecciones raras

#### 3. Ayuda Inmediata
- Traducción instantánea para solicitar ayuda
- **feat-001**: Aplicación para recibir notificaciones de emergencias para iPad

#### 4. Comunidad FIFA
- Haciendo uso de web scraping se obtiene información referente al mundial con cierto delay
- Los usuarios pueden notificar lugares accesibles para alimentar IA on-device y para ayudar visualmente para las zonas o que se haga automático

### Features Adicionales
- Apple Intelligence
- Shortcuts para emergencias
- Recomendaciones sobre lugares accesibles
- Estadísticas y alineaciones (conexión en tiempo real con la narración del partido)
- Seguimiento de la pelota con giroscopio
- Poder ver el partido con el teléfono con traducción instantánea

## Características de Configuración

### Menú de Configuración
- Unit of measure
- Announcements format (Clock position (12 o'clock), Relative directions (front, back), Cardinal directions)
- Change language (con un screen scroll para escoger y confirmar el cambio)

### Start Trip
1. Cuando empiece, primero buscará que te localices con una flecha para empezar el viaje
2. Después irá marcando el camino que tiene que seguir (el voiceover se actualiza cada minuto o cada que se cambie la dirección)
3. Aparece la indicación de qué hacer
4. Botón para localizarte
5. Solo darle las acciones con la voz

## Videos Demo

El proyecto incluye 19 videos demostrativos (977 MB total):

### 1. Introducción a las Plataformas
- `1. Introducción iPhone.mov` (157 MB) - Introducción en iPhone
- `1 .introducción iPad.mov` (96 MB) - Introducción en iPad
- `1. introducción aplpe watch.mov` (1.7 MB) - Introducción en Apple Watch
- `1. introduccion navegación.mov` (22 MB) - Introducción a la navegación

### 2. Reservaciones y Configuración
- `2. reservations and config.mp4` (67 MB) - Sistema de reservaciones y configuración
- `2. reservations.mp4` (83 MB) - Sistema de reservaciones

### 3. Características de Comunidad y Búsqueda
- `3. comunidad.mov` (6.1 MB) - Funcionalidad de comunidad
- `3. comunidad iphone.mp4` (1.8 MB) - Comunidad en iPhone
- `3. ipad search.mp4` (72 MB) - Búsqueda en iPad
- `3. metro tracker.mov` (86 MB) - Seguimiento de metro

### 4. Inteligencia Artificial y Álbumes
- `4. IA.mp4` (102 MB) - Características de IA
- `4. actidad.mov` (2.9 MB) - Actividad
- `4. album.mp4` (38 MB) - Funcionalidad de álbum

### 5. Detección y Overview
- `5. album detect.mov` (29 MB) - Detección de álbumes
- `5. overview.mov` (55 MB) - Visión general del sistema
- `5. posters detect.mov` (66 MB) - Detección de pósters

### 6. Detección IA Avanzada
- `6. IA Detection.mp4` (1.6 MB) - Detección con IA
- `6. IA detection2.mp4` (12 MB) - Detección con IA (versión 2)

### 8. Modo de Emergencia
- `8. emergency mode.mov` (80 MB) - Modo de emergencia

## Documentación Adicional

- `Convocatoria CSC-2025.pdf` (511 KB) - Convocatoria oficial del hackathon
- `Lineamientos CSC 2025 final.pdf` (673 KB) - Lineamientos del concurso

## Estructura del Proyecto

```
atenea/
├── README.md                          # Este archivo
├── Changemakers 2025.md               # Documentación detallada del proyecto
├── Me Changemaker app.md              # Especificaciones de la app
├── Convocatoria CSC-2025.pdf         # Convocatoria oficial
├── Lineamientos CSC 2025 final.pdf   # Lineamientos del concurso
└── videos/                            # Videos demostrativos (19 archivos, 977 MB)
    ├── 1. Introducción iPhone.mov
    ├── 1 .introducción iPad.mov
    ├── 1. introducción aplpe watch.mov
    ├── 1. introduccion navegación.mov
    ├── 2. reservations and config.mp4
    ├── 2. reservations.mp4
    ├── 3. comunidad.mov
    ├── 3. comunidad iphone.mp4
    ├── 3. ipad search.mp4
    ├── 3. metro tracker.mov
    ├── 4. IA.mp4
    ├── 4. actidad.mov
    ├── 4. album.mp4
    ├── 5. album detect.mov
    ├── 5. overview.mov
    ├── 5. posters detect.mov
    ├── 6. IA Detection.mp4
    ├── 6. IA detection2.mp4
    └── 8. emergency mode.mov
```

## Tecnologías Utilizadas

- **iOS Nativo** - iPhone, iPad, Apple Watch
- **Create ML** - Entrenamiento de modelos de IA
- **Core ML** - Integración de modelos de IA on-device
- **ARKit** - Realidad aumentada para navegación
- **Giroscopio** - Seguimiento y navegación
- **VoiceOver** - Accesibilidad para usuarios con discapacidad visual
- **Red Mesh** - Comunicación sin internet para emergencias

## Accesibilidad

Atenea está diseñada específicamente para personas con:
- Discapacidad motriz
- Discapacidad visual
- Discapacidad auditiva
- Discapacidad cognitiva
- Ansiedad social

## Privacidad y Seguridad

- Toda la IA funciona on-device (sin enviar datos a la nube)
- Protección de privacidad del usuario
- Funciona sin conexión a internet
- Red mesh para emergencias cuando no hay conectividad

---

**Hackathon CSC Changemakers 2025**
**Proyecto: Atenea**
**Autor: Milo**

# 🚨 Guía de Integración de Emergencias con NearbyInteraction

## 📋 Resumen

Se ha integrado la funcionalidad real de emergencias utilizando **NearbyInteraction** y **MultipeerConnectivity** para conectar usuarios en peligro con el staff de seguridad de forma local, sin necesidad de internet.

---

## 🏗️ Arquitectura

### Componentes Principales

1. **NearbyInteractionManager** (`Core/Managers/NearbyInteractionManager.swift`)
   - Gestor central que maneja NI + MPC
   - Roles: `.client` (usuario) y `.staff` (seguridad)
   - Publica distancia y dirección en tiempo real

2. **EmergencyModeManager** (`Features/Map/Views/NavigationViewWrapper.swift`)
   - Gestor singleton del modo emergencia
   - Inicializa NearbyInteractionManager cuando se activa emergencia

3. **EmergencyModal** (`Features/Map/Views/EmergencyModal.swift`)
   - Modal que se abre al agitar el dispositivo
   - Opciones: Llamar 911, Policía, Compartir ubicación

4. **StaffView** (`Features/Staff/Views/StaffView.swift`)
   - Vista principal del staff
   - Inicializa NI Manager en modo `.staff` (advertising)

5. **StaffEmergenciesView** (`Features/Staff/Views/StaffEmergenciesView.swift`)
   - Lista de emergencias activas con distancia real
   - Muestra clientes conectados vía NI

6. **StaffARNavigationView** (`Features/Staff/Views/StaffARNavigationView.swift`)
   - Vista AR con flecha 3D apuntando al cliente
   - Navegación inmersiva para el staff

---

## 🔄 Flujo de Emergencia

### Lado Cliente (Usuario)

```
1. Usuario agita dispositivo
   ↓
2. Se abre EmergencyModal
   ↓
3. Usuario presiona "Llamar Policía"
   ↓
4. EmergencyModeManager.activateEmergency()
   ↓
5. NearbyInteractionManager(.client) se inicializa
   ↓
6. Comienza browsing para staff vía MPC
   ↓
7. Al encontrar staff → Intercambia tokens NI
   ↓
8. Sesión NI establecida con distancia/dirección
```

### Lado Staff (Seguridad)

```
1. Staff abre StaffView
   ↓
2. NearbyInteractionManager(.staff) se inicializa
   ↓
3. Comienza advertising vía MPC
   ↓
4. Al recibir cliente → Auto-acepta conexión
   ↓
5. Intercambia tokens NI
   ↓
6. Staff ve en "Emergencys" → Cliente con distancia
   ↓
7. Staff selecciona opciones:
   - Navegación AR (flecha 3D)
   - Mostrar ubicación (mapa)
   - Empezar navegación (turn-by-turn)
```

---

## ⚙️ Configuración de Xcode

### 1. Agregar Capability "Near Interaction"

```
1. Abrir proyecto en Xcode
2. Seleccionar target "atenea"
3. Ir a "Signing & Capabilities"
4. Click en "+ Capability"
5. Buscar "Near Interaction"
6. Agregar
```

### 2. Verificar Frameworks

Asegúrate de que estos frameworks estén incluidos:

- ✅ `NearbyInteraction.framework`
- ✅ `MultipeerConnectivity.framework`
- ✅ `ARKit.framework`
- ✅ `RealityKit.framework`
- ✅ `CoreLocation.framework`
- ✅ `Combine.framework`

### 3. Info.plist (Ya configurado)

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Atenea uses local network to connect staff with users in emergency situations...</string>

<key>NSBonjourServices</key>
<array>
    <string>_atenea-sos._tcp</string>
    <string>_atenea-sos._udp</string>
</array>

<key>NSCameraUsageDescription</key>
<string>We need access to your camera for AR navigation...</string>
```

---

## 📱 Requisitos de Dispositivos

### NearbyInteraction (NI)
- **iPhone 11 o superior** (chip U1 requerido)
- **iOS 14.0+**
- **No funciona en simulador** (solo dispositivos físicos)

### MultipeerConnectivity (MPC)
- **iOS 13.0+**
- Bluetooth activado
- WiFi activado (no necesita internet)

### AR Navigation
- **iPhone con chip A12 o superior**
- **iOS 13.0+**

---

## 🧪 Guía de Pruebas

### Configuración

1. **2 iPhones físicos** (iPhone 11+)
2. **Ambos en la misma red WiFi** (o con WiFi Direct)
3. **Bluetooth activado** en ambos
4. **Permisos concedidos**: Cámara, Ubicación, Red Local

### Flujo de Prueba Completo

#### Paso 1: Preparar Dispositivo Staff

```
1. Abrir Atenea en iPhone 1
2. Ir al menú lateral
3. Presionar "Staff"
4. Presionar "Emergencys"
5. Ver mensaje "Sin Emergencias Activas"
6. (El dispositivo ahora está "advertising" esperando clientes)
```

#### Paso 2: Activar Emergencia en Cliente

```
1. Abrir Atenea en iPhone 2
2. Agitar el dispositivo
3. Se abre EmergencyModal
4. Presionar "Llamar Policía" (botón rojo)
5. Ver mensaje "Buscando staff cercano..."
```

#### Paso 3: Verificar Conexión

```
En iPhone 1 (Staff):
- Ver aparecer emergencia en la lista
- Ver nombre del dispositivo cliente
- Ver distancia en metros (ej: "A 5.2m de distancia")

En iPhone 2 (Cliente):
- Ver que el modal se cierra
- (El cliente está conectado)
```

#### Paso 4: Navegación AR (Staff)

```
1. En iPhone 1, presionar la emergencia
2. En el menú, seleccionar "Navegación AR (Realidad Aumentada)"
3. Ver vista AR con flecha roja apuntando al cliente
4. Moverse físicamente y ver cómo la flecha rota
5. Ver distancia actualizándose en tiempo real
```

---

## 🐛 Solución de Problemas

### Problema: "No se encuentran dispositivos"

**Posibles causas:**
- Bluetooth/WiFi desactivado
- Dispositivos muy lejos (>20m)
- Permisos no concedidos

**Solución:**
1. Verificar que ambos dispositivos tengan Bluetooth y WiFi activados
2. Acercar los dispositivos a <10m
3. Verificar permisos en Configuración → Atenea

---

### Problema: "Distancia siempre en 0.0m"

**Causa:**
- NearbyInteraction aún no ha calculado la distancia

**Solución:**
- Esperar 2-3 segundos
- Mover ligeramente el dispositivo
- La distancia se actualiza automáticamente

---

### Problema: "Flecha AR no aparece"

**Posibles causas:**
- Permisos de cámara no concedidos
- Dispositivo no tiene chip A12+
- Falta capability ARKit

**Solución:**
1. Verificar permisos de cámara
2. Verificar que el dispositivo sea iPhone XS o superior
3. En Xcode, agregar framework ARKit si falta

---

### Problema: "Conexión se pierde constantemente"

**Causa:**
- Interferencia WiFi/Bluetooth
- Dispositivos muy lejos
- Batería baja

**Solución:**
- Acercar dispositivos
- Evitar áreas con muchas redes WiFi
- Cargar dispositivos

---

## 📊 Datos Técnicos

### NearbyInteraction

| Característica | Valor |
|----------------|-------|
| Precisión de distancia | ±10cm |
| Rango máximo | 15-20m |
| Actualización | 60 Hz |
| Ángulo de detección | 360° horizontal |
| Consumo de batería | Bajo (~5% por hora) |

### MultipeerConnectivity

| Característica | Valor |
|----------------|-------|
| Rango típico | 10-30m |
| Velocidad de transferencia | 1-10 MB/s |
| Latencia | 50-200ms |
| Dispositivos simultáneos | Hasta 8 |
| Encriptación | TLS 1.2+ |

---

## 🔒 Seguridad y Privacidad

### Datos Transmitidos

- **NI Discovery Token**: ID único temporal (no contiene info personal)
- **Nombre del dispositivo**: Nombre del iPhone (configurable)
- **Distancia y dirección**: Solo mientras hay sesión activa

### Privacidad

- ✅ No se transmite ubicación GPS
- ✅ No se envía información a servidores externos
- ✅ Conexión P2P encriptada (TLS)
- ✅ Sesión se cierra al cerrar la app (no persiste)
- ✅ No se guarda historial de emergencias

---

## 🚀 Próximas Mejoras Sugeridas

### Funcionalidad

- [ ] Múltiples staff simultáneos
- [ ] Historial de emergencias (con consentimiento)
- [ ] Tipos de emergencia personalizables
- [ ] Chat en tiempo real entre cliente-staff
- [ ] Grabación de audio/video opcional
- [ ] Notificaciones push al staff cuando hay emergencia

### UX/UI

- [ ] Animaciones de conexión
- [ ] Sonidos de alerta
- [ ] Vibración háptica al conectar
- [ ] Indicador de calidad de señal
- [ ] Mapa AR con overlay de ubicación

### Técnico

- [ ] Persistencia de sesión NI en background
- [ ] Reconexión automática si se pierde conexión
- [ ] Fallback a GPS si NI no disponible
- [ ] Analytics de uso de emergencias
- [ ] Logs para debugging

---

## 📞 Soporte

Si encuentras algún problema durante la integración:

1. Verificar que todos los archivos fueron agregados al target
2. Limpiar build folder (Cmd+Shift+K)
3. Reconstruir proyecto (Cmd+B)
4. Verificar que los permisos en Info.plist estén correctos
5. Verificar que los dispositivos sean compatibles (iPhone 11+)

---

## ✅ Checklist Final

Antes de compilar, verifica:

- [ ] Capability "Near Interaction" agregada
- [ ] Info.plist con `NSLocalNetworkUsageDescription`
- [ ] Info.plist con `NSBonjourServices`
- [ ] Info.plist con `NSCameraUsageDescription`
- [ ] Todos los archivos agregados al target "atenea"
- [ ] Frameworks importados: NI, MPC, ARKit, RealityKit
- [ ] Dispositivos físicos iPhone 11+ para testing
- [ ] Bluetooth y WiFi habilitados en ambos dispositivos

---

**Última actualización:** 2025-11-09
**Versión:** 1.0.0

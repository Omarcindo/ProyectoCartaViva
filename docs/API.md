# Contrato de API REST y WebSockets — CartaViva

> **Responsable:** Omar Monroy (Backend & Datos)  
> Este documento define los endpoints oficiales entre el Frontend (Aitor / Aarón) y el Backend (Omar).

---

## 1. Endpoints Públicos (Cliente QR en Mesa — Sin Login)

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/api/health` | Comprueba estado del servidor y BD (usado por Docker y Uptime Kuma) |
| `GET` | `/api/qr/:token` | Resuelve el QR: devuelve datos del restaurante, carta ES/EN y sesión activa de la mesa |
| `POST` | `/api/qr/:token/ronda` | Envía nueva ronda (el servidor calcula los precios reales desde PostgreSQL) |
| `POST` | `/api/sesiones/:id/pedir-cuenta` | Notifica a caja si el cliente paga en efectivo o con tarjeta |

---

## 2. Autenticación y Multi-Tenant (Requiere JWT)

| Método | Ruta | Descripción |
|---|---|---|
| `POST` | `/api/auth/login` | Devuelve token JWT con `usuario_id`, `rol` y `restaurante_id` |
| `GET` | `/api/auth/me` | Devuelve perfil del usuario conectado |

---

## 3. Panel del Dueño & Editor 2D (Rol: `dueno`)

| Método | Ruta | Descripción |
|---|---|---|
| `GET/POST/PUT/DELETE` | `/api/categorias` | Gestión de categorías (cocina/barra, incluye_tapa) |
| `GET/POST/PUT/DELETE` | `/api/productos` | Gestión de platos (ES/EN, alérgenos, imagen) |
| `PATCH` | `/api/productos/:id/disponible` | Interruptor rápido de "Plato Agotado" |
| `GET/POST/PUT/DELETE` | `/api/zonas` | Gestión de salones, terrazas y decoración 2D (`JSONB`) |
| `GET/POST/PUT/DELETE` | `/api/mesas` | Gestión de mesas, coordenadas `x/y` de Konva.js y modo feria |

---

## 4. Cocina KDS y Caja TPV (Roles: `cocina`, `camarero`, `dueno`)

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/api/pedidos?estado=pendiente` | Rondas activas para Cocina y Barra |
| `PATCH` | `/api/pedidos/:id/estado` | Cambia estado: `pendiente` → `preparando` → `listo` → `servido` |
| `POST` | `/api/sesiones/:id/trasladar` | Mueve la cuenta acumulada a otra mesa libre |
| `POST` | `/api/sesiones/:id/cerrar-y-cobrar` | Genera ticket fiscal correlativo y resetea la mesa a `0,00 €` |

---

## 5. Consola SuperAdmin CartaViva S.L. (Rol: `plataforma`)

| Método | Ruta | Descripción |
|---|---|---|
| `GET/POST` | `/api/superadmin/restaurantes` | Lista y alta de clientes (bares/ferias) |
| `PATCH` | `/api/superadmin/restaurantes/:id/estado` | Activar o suspender por impago con 1 clic |
| `GET/POST` | `/api/superadmin/soporte` | Tickets de ayuda de los establecimientos |

---

## 6. Eventos WebSocket (Socket.io — Sala `restaurante_<id>`)

* `nueva_ronda_cocina` → Emitido al instante cuando un cliente pide platos.
* `nueva_ronda_barra` → Emitido al instante cuando un cliente pide bebidas.
* `cambio_estado_ronda` → Actualiza en vivo el móvil del cliente y el mapa de mesas.
* `plato_agotado` → Bloquea el plato en tiempo real en todos los móviles.
* `cliente_pide_cuenta` → Alerta en la caja con el método de pago elegido.
* `mesa_liberada` → Limpia el móvil y pone la mesa verde en el mapa TPV.

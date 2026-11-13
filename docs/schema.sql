-- =========================================================================
--  CartaViva — Modelo de Base de Datos Definitivo v2.0 (PostgreSQL 16)
--  Arquitectura SaaS Multi-Restaurante + Ferias + Sesiones Acumulativas
--
--  Regla de oro del multi-tenant:
--  TODA tabla "de negocio" lleva `restaurante_id`, y cada consulta filtra
--  SIEMPRE por el restaurante autenticado. Un local jamás ve datos de otro.
-- =========================================================================

-- 1) RESTAURANTES — Los clientes de CartaViva S.L. (Bares, Restaurantes, Puestos de Feria)
CREATE TABLE restaurantes (
    id                   BIGSERIAL PRIMARY KEY,
    slug                 TEXT UNIQUE NOT NULL,          -- ej. 'bar-pepe' o 'feria-almeria-caseta-4'
    nombre               TEXT NOT NULL,
    nif_cif              TEXT,                          -- Para imprimir en el ticket térmico
    direccion            TEXT,
    telefono             TEXT,
    logo_url             TEXT,
    tipo_negocio         TEXT NOT NULL DEFAULT 'restaurante'
                         CHECK (tipo_negocio IN ('restaurante','bar','cafeteria','feria_evento')),
    moneda               TEXT NOT NULL DEFAULT 'EUR',
    iva                  NUMERIC(5,2) NOT NULL DEFAULT 10.00, -- 10% IVA hostelería en España
    color_principal      TEXT NOT NULL DEFAULT '#0F4C3A',
    color_secundario     TEXT NOT NULL DEFAULT '#10B981',
    cocina_abierta       BOOLEAN NOT NULL DEFAULT TRUE, -- Anti-trolls: si es FALSE, el QR solo deja ver la carta
    pin_seguridad_mesas  BOOLEAN NOT NULL DEFAULT FALSE,-- Opcional: requiere PIN de 2 dígitos en mesa
    -- Control de Suscripción (Consola SuperAdmin de CartaViva S.L.)
    plan_suscripcion     TEXT NOT NULL DEFAULT 'mensual_bar'
                         CHECK (plan_suscripcion IN ('mensual_bar','pro_restaurante','evento_feria','prueba')),
    estado_servicio      TEXT NOT NULL DEFAULT 'activo'
                         CHECK (estado_servicio IN ('activo','suspendido_impago','finalizado','mantenimiento')),
    motivo_suspension    TEXT,
    fecha_vencimiento    TIMESTAMPTZ,
    activo               BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en            TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2) USUARIOS — SuperAdmins de CartaViva, Dueños de bares, Camareros y Cocineros
--    rol 'plataforma' => restaurante_id es NULL (sois vosotros: Aarón, Omar y Aitor)
CREATE TABLE usuarios (
    id             BIGSERIAL PRIMARY KEY,
    restaurante_id BIGINT REFERENCES restaurantes(id) ON DELETE CASCADE,
    nombre         TEXT NOT NULL,
    email          TEXT NOT NULL UNIQUE,
    password_hash  TEXT NOT NULL,
    rol            TEXT NOT NULL CHECK (rol IN ('plataforma','dueno','camarero','cocina')),
    activo         BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3) ZONAS — Salones, Terrazas o Carpas de Feria (Incluye JSONB para muros/decoración 2D)
CREATE TABLE zonas (
    id                 BIGSERIAL PRIMARY KEY,
    restaurante_id     BIGINT NOT NULL REFERENCES restaurantes(id) ON DELETE CASCADE,
    nombre             TEXT NOT NULL,                   -- ej. 'Salón Interior', 'Terraza Calle', 'Carpa Feria'
    nombre_en          TEXT,                            -- ej. 'Main Hall', 'Street Terrace'
    color              TEXT NOT NULL DEFAULT '#94a3b8',
    ancho_lienzo       INTEGER NOT NULL DEFAULT 1200,
    alto_lienzo        INTEGER NOT NULL DEFAULT 800,
    decoracion_2d_json JSONB NOT NULL DEFAULT '[]'::jsonb -- Guarda barras, muros, puertas o carpas de Konva.js
);

-- 4) MESAS — Su posición exacta en el plano 2D de Konva.js + Token del QR
CREATE TABLE mesas (
    id             BIGSERIAL PRIMARY KEY,
    restaurante_id BIGINT NOT NULL REFERENCES restaurantes(id) ON DELETE CASCADE,
    zona_id        BIGINT REFERENCES zonas(id) ON DELETE SET NULL,
    numero         INTEGER NOT NULL,
    etiqueta       TEXT,                                -- ej. 'Mesa 4' o 'Feria Calle 12'
    posicion_x     NUMERIC(8,2) NOT NULL DEFAULT 100,
    posicion_y     NUMERIC(8,2) NOT NULL DEFAULT 100,
    ancho          NUMERIC(8,2) NOT NULL DEFAULT 80,
    alto           NUMERIC(8,2) NOT NULL DEFAULT 80,
    rotacion       NUMERIC(6,2) NOT NULL DEFAULT 0,     -- Ángulo de giro en el plano 2D
    forma          TEXT NOT NULL DEFAULT 'cuadrada'
                   CHECK (forma IN ('cuadrada','redonda','rectangular')),
    sillas         INTEGER NOT NULL DEFAULT 4,
    pin_actual      TEXT,                                -- PIN opcional de 2 dígitos para evitar pedidos falsos
    activa         BOOLEAN NOT NULL DEFAULT TRUE,
    token          TEXT NOT NULL UNIQUE,                -- Token único del QR físico de la mesa
    creado_en      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 5) SESIONES DE MESA (CUENTA ABIERTA) — Permite acumular múltiples pedidos/rondas
--    Cuando la mesa paga y se va, la sesión pasa a 'cerrada' y el QR queda limpio a 0,00 €
CREATE TABLE sesiones_mesa (
    id              BIGSERIAL PRIMARY KEY,
    restaurante_id  BIGINT NOT NULL REFERENCES restaurantes(id) ON DELETE CASCADE,
    mesa_id         BIGINT NOT NULL REFERENCES mesas(id) ON DELETE CASCADE,
    estado          TEXT NOT NULL DEFAULT 'abierta'
                    CHECK (estado IN (
                        'abierta',
                        'llamando_camarero',
                        'pidiendo_cuenta_efectivo',
                        'pidiendo_cuenta_tarjeta',
                        'cerrada',
                        'cancelada'
                    )),
    comensales      INTEGER DEFAULT 2,
    total_acumulado NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    abierta_en      TIMESTAMPTZ NOT NULL DEFAULT now(),
    cerrada_en      TIMESTAMPTZ
);

-- 6) CATEGORÍAS — Entrantes, Bebidas, Raciones, Postres (Bilingüe ES / EN)
CREATE TABLE categorias (
    id                  BIGSERIAL PRIMARY KEY,
    restaurante_id      BIGINT NOT NULL REFERENCES restaurantes(id) ON DELETE CASCADE,
    nombre              TEXT NOT NULL,                       -- Español: 'Para Picar'
    nombre_en           TEXT,                                -- Inglés:  'Starters & Tapas'
    icono               TEXT,                                -- ej. '🍻', '🍔'
    destino_preparacion TEXT NOT NULL DEFAULT 'cocina'       -- Separa qué va a Barra y qué va a Cocina
                        CHECK (destino_preparacion IN ('cocina','barra')),
    incluye_tapa        BOOLEAN NOT NULL DEFAULT FALSE,      -- Especial Almería: si es bebida con tapa a elegir
    orden               INTEGER NOT NULL DEFAULT 0,
    activa              BOOLEAN NOT NULL DEFAULT TRUE
);

-- 7) PRODUCTOS — La Carta / Menú (Bilingüe ES / EN + Alérgenos + Botón Agotado en 1 clic)
CREATE TABLE productos (
    id             BIGSERIAL PRIMARY KEY,
    restaurante_id BIGINT NOT NULL REFERENCES restaurantes(id) ON DELETE CASCADE,
    categoria_id   BIGINT NOT NULL REFERENCES categorias(id) ON DELETE CASCADE,
    nombre         TEXT NOT NULL,                       -- Español: 'Secreto Ibérico a la brasa'
    nombre_en      TEXT,                                -- Inglés:  'Grilled Iberian Pork'
    descripcion    TEXT,
    descripcion_en TEXT,
    precio         NUMERIC(8,2) NOT NULL,
    es_tapa_elegir BOOLEAN NOT NULL DEFAULT FALSE,      -- Si puede elegirse como tapa gratuita con la bebida
    imagen_url     TEXT,
    alergenos      TEXT[] NOT NULL DEFAULT '{}',        -- ej. {'gluten','lacteos','huevos'}
    disponible     BOOLEAN NOT NULL DEFAULT TRUE,       -- Interruptor rápido en cocina si se agota
    orden          INTEGER NOT NULL DEFAULT 0,
    creado_en      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 8) PEDIDOS (RONDAS) — Cada ronda que envía una mesa dentro de su Sesión Activa
CREATE TABLE pedidos (
    id             BIGSERIAL PRIMARY KEY,
    restaurante_id BIGINT NOT NULL REFERENCES restaurantes(id) ON DELETE CASCADE,
    mesa_id        BIGINT NOT NULL REFERENCES mesas(id) ON DELETE RESTRICT,
    sesion_id      BIGINT NOT NULL REFERENCES sesiones_mesa(id) ON DELETE CASCADE,
    numero_ronda   INTEGER NOT NULL DEFAULT 1,          -- Ronda 1, Ronda 2, Ronda 3...
    origen         TEXT NOT NULL DEFAULT 'qr_cliente'
                   CHECK (origen IN ('qr_cliente','camarero_tpv')),
    estado         TEXT NOT NULL DEFAULT 'pendiente'
                   CHECK (estado IN ('pendiente','preparando','listo','servido','cancelado')),
    subtotal_ronda NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    notas          TEXT,
    creado_en      TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 9) LÍNEAS DE PEDIDO — Cada plato o bebida dentro de una ronda
CREATE TABLE lineas_pedido (
    id              BIGSERIAL PRIMARY KEY,
    pedido_id       BIGINT NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
    producto_id     BIGINT REFERENCES productos(id) ON DELETE SET NULL,
    restaurante_id  BIGINT NOT NULL REFERENCES restaurantes(id) ON DELETE CASCADE,
    nombre_producto TEXT NOT NULL,                      -- Snapshot del nombre por seguridad histórica
    cantidad        INTEGER NOT NULL DEFAULT 1,
    precio_unitario NUMERIC(8,2) NOT NULL,              -- Snapshot del precio en ese momento
    tapa_elegida    TEXT,                               -- Ej: 'Tapa: Carne con tomate'
    nombre_comensal TEXT,                               -- Opcional: 'Juan', 'María' (para grupos de amigos)
    notas           TEXT                                -- ej. 'Sin cebolla', 'Con hielo'
);

-- 10) TICKETS / FACTURAS SIMPLIFICADAS — Se genera al cobrar todas las rondas de la sesión
CREATE TABLE tickets (
    id             BIGSERIAL PRIMARY KEY,
    restaurante_id BIGINT NOT NULL REFERENCES restaurantes(id) ON DELETE CASCADE,
    mesa_id        BIGINT REFERENCES mesas(id) ON DELETE SET NULL,
    sesion_id      BIGINT UNIQUE REFERENCES sesiones_mesa(id) ON DELETE SET NULL,
    numero_factura INTEGER NOT NULL,                    -- Correlativo por restaurante (1, 2, 3...)
    subtotal_base  NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    iva_porcentaje NUMERIC(5,2) NOT NULL DEFAULT 10.00,
    iva_importe    NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    total          NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    metodo_pago    TEXT NOT NULL DEFAULT 'efectivo'
                   CHECK (metodo_pago IN ('efectivo','tarjeta','mixto')),
    impreso        BOOLEAN NOT NULL DEFAULT FALSE,
    creado_en      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 11) TICKETS DE SOPORTE TÉCNICO — Para que los bares pidan ayuda a CartaViva S.L.
CREATE TABLE tickets_soporte (
    id                 BIGSERIAL PRIMARY KEY,
    restaurante_id     BIGINT NOT NULL REFERENCES restaurantes(id) ON DELETE CASCADE,
    usuario_id         BIGINT REFERENCES usuarios(id) ON DELETE SET NULL,
    asunto             TEXT NOT NULL,
    mensaje            TEXT NOT NULL,
    prioridad          TEXT NOT NULL DEFAULT 'normal'
                       CHECK (prioridad IN ('baja','normal','urgente_servicio_parado')),
    estado             TEXT NOT NULL DEFAULT 'abierto'
                       CHECK (estado IN ('abierto','en_proceso','resuelto')),
    respuesta_soporte  TEXT,
    creado_en          TIMESTAMPTZ NOT NULL DEFAULT now(),
    resuelto_en        TIMESTAMPTZ
);

-- =========================================================================
--  ÍNDICES DE RENDIMIENTO (Respuestas en < 10 milisegundos)
-- =========================================================================
CREATE INDEX idx_productos_restaurante   ON productos       (restaurante_id, disponible);
CREATE INDEX idx_mesas_restaurante       ON mesas           (restaurante_id);
CREATE INDEX idx_sesiones_mesa_activa    ON sesiones_mesa   (mesa_id, estado);
CREATE INDEX idx_pedidos_restaurante     ON pedidos         (restaurante_id, estado);
CREATE INDEX idx_pedidos_sesion          ON pedidos         (sesion_id);
CREATE INDEX idx_tickets_restaurante     ON tickets         (restaurante_id, creado_en);
CREATE INDEX idx_soporte_estado          ON tickets_soporte (estado, prioridad);

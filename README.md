<p align="center">
  <img src="./docs/branding/logo-cartaviva.svg" alt="CartaViva Logo" width="420" />
</p>

Plataforma SaaS multi-restaurante para bares, cafeterías, terrazas y puestos de ferias donde el dueño dibuja el plano de sus mesas en 2D, genera los códigos QR automáticamente y sincroniza los pedidos en tiempo real con cocina y caja sin tocar código.

---

## 👥 Equipo (2º ASIR)

| Integrante | Rol | Responsabilidades |
|---|---|---|
| **Aarón Cruz** | Líder · DevOps & Vistas Operativas | VPS, Docker, Nginx HTTPS, Monitorización (Uptime Kuma/Dozzle), Cliente QR, Cocina KDS y Caja TPV |
| **Omar Monroy** | Backend & Base de Datos | PostgreSQL + Prisma, Redis, API REST (Node/Express), Seguridad JWT/Multi-Tenant y WebSockets (Socket.io) |
| **Aitor González** | Frontend Admin & Editor 2D | React + Vite + Tailwind, Editor de planos 2D (Konva.js), Consola SuperAdmin, Panel del Dueño y Web Comercial |

---

## 📁 Estructura del Repositorio

```text
ProyectoCartaViva/
├── docker-compose.yml       # Orquestación de los 7 servicios (Nginx, Web, API, Postgres, Redis, Kuma, Dozzle)
├── .env.example             # Plantilla de variables de entorno (copiar a .env, nunca subir .env)
├── docs/
│   ├── schema.sql           # Modelo relacional PostgreSQL v2.0 (11 tablas multi-tenant)
│   ├── API.md               # Contrato de endpoints REST y eventos Socket.io
│   └── branding/            # Logotipos oficiales SVG y 4K
├── infra/
│   ├── nginx/nginx.conf     # Reverse proxy, rate-limiting y soporte WebSockets
│   └── scripts/backup-db.sh # Copia de seguridad nocturna automática
├── backend/                 # Código Node.js + Express + Prisma + Socket.io (Omar)
└── frontend/                # Código React + Vite + Tailwind + Konva (Aitor + Aarón)
```

## 🚀 Arranque Rápido (Entorno VPS o Local con Docker)

1. Copia la plantilla de variables de entorno:
   ```bash
   cp .env.example .env
   ```
2. Edita `.env` con tus contraseñas seguras.
3. Levanta toda la infraestructura:
   ```bash
   docker compose up -d --build
   ```

## 🌿 Flujo de Trabajo en Git (Ramas y Pull Requests)

Para evitar conflictos, cada miembro del equipo debe trabajar en su propia rama y subir los cambios mediante **Pull Requests**. **No se debe hacer push directamente a la rama `main`.**

1. **Actualizar el repositorio local antes de empezar:**
   ```bash
   git checkout main
   git pull origin main
   ```
2. **Crear o cambiar a tu rama de trabajo:**
   * Aarón: `git checkout -b feat/aaron-infra`
   * Omar: `git checkout -b feat/omar-backend`
   * Aitor: `git checkout -b feat/aitor-frontend`
3. **Subir cambios y abrir Pull Request en GitHub:**
   ```bash
   git add .
   git commit -m "Descripción clara de lo realizado"
   git push -u origin <tu-rama>
   ```

## Convenciones de Commits (Git)

Para mantener el historial ordenado y saber exactamente qué hizo cada uno sin tener que leer todo el código, utilizamos el estándar de Conventional Commits.

El formato obligatorio para cada commit es:
`tipo(scope): descripción breve en minúsculas`

### 1. Tipos de Commit (`tipo`)
* **`feat`** (Feature): Añade una nueva funcionalidad. *(Ej: crear la ruta de login, añadir el editor de Konva)*.
* **`fix`** (Fix): Soluciona un error o bug. *(Ej: corregir un fallo al guardar la posición de la mesa)*.
* **`chore`** (Chore): Tareas de mantenimiento, actualización de dependencias, o configuraciones que no tocan código de producción. *(Ej: modificar docker-compose, instalar una librería)*.
* **`docs`** (Documentation): Cambios exclusivos en la documentación. *(Ej: actualizar este README, añadir el API.md)*.
* **`style`** (Style): Cambios de formato (espacios, comas, punto y coma) que no afectan la lógica del código.
* **`refactor`** (Refactor): Cambios en el código que mejoran su estructura pero no añaden funcionalidades nuevas ni arreglan errores.

### 2. Ámbitos (`scope`)
Dado que tenemos el proyecto dividido en tres áreas (Backend, Admin, Cliente), usaremos el "scope" entre paréntesis para indicar qué parte del proyecto se ha tocado:
* `(backend)`: Cambios en Node.js, Express, Socket.io (Omar).
* `(db)`: Cambios en `schema.prisma` o migraciones (Omar).
* `(admin)`: Cambios en el panel de React y el editor de mesas (Aitor).
* `(cliente)`: Cambios en la vista móvil QR, cocina o caja (Aarón).
* `(infra)`: Cambios en Docker, Nginx o configuración del VPS (Aarón).

### 3. Ejemplos de uso real para nuestro proyecto
* `feat(backend): crear endpoint POST para nuevos pedidos`
* `fix(admin): corregir bug que impedía arrastrar las mesas cuadradas`
* `chore(infra): añadir configuración de Nginx para HTTPS`
* `docs(db): actualizar el contrato de API con los endpoints de usuarios`
* `feat(cliente): añadir botón de enviar a cocina en la vista móvil`

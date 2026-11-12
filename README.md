## Flujo de Trabajo (Ramas y Pull Requests)

Para evitar conflictos, cada miembro del equipo debe trabajar en su propia rama y subir los cambios mediante Pull Requests. No se debe hacer push directamente a la rama `main`.

**1. Actualizar el repositorio local:**
Antes de empezar a trabajar, asegúrate de tener la última versión de `main`.
```bash
git checkout main
git pull origin main

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
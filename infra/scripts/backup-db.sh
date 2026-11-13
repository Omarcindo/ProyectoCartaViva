#!/bin/bash
# =========================================================================
#  CartaViva — Script de Copia de Seguridad Nocturna (PostgreSQL)
#  Uso en crontab (04:00 AM): 0 4 * * * /ruta/infra/scripts/backup-db.sh
# =========================================================================

BACKUP_DIR="/var/backups/cartaviva"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
FILENAME="cartaviva_backup_$DATE.sql.gz"

mkdir -p "$BACKUP_DIR"

# Exportar base de datos desde el contenedor PostgreSQL y comprimir
docker exec cartaviva-postgres pg_dump -U cartaviva cartaviva_db | gzip > "$BACKUP_DIR/$FILENAME"

# Borrar copias de más de 7 días para no llenar el disco del VPS
find "$BACKUP_DIR" -type f -name "*.sql.gz" -mtime +7 -delete

echo "[OK] Copia de seguridad generada: $FILENAME"

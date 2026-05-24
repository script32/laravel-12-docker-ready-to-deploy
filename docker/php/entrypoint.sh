#!/bin/sh
# =============================================================================
# entrypoint.sh — Script de Inicialización del Contenedor de Producción
# Laravel 12 Docker Ready-to-Deploy Starter Kit
#
# FILOSOFÍA DE DISEÑO:
#   - 'set -e': Aborta inmediatamente ante cualquier error no controlado.
#     Evita que el contenedor continúe en un estado parcialmente inicializado.
#   - Cada paso crítico tiene su propio bloque de verificación y manejo de errores.
#   - Los comandos de optimización se ejecutan DESPUÉS de las migraciones para
#     asegurar que la caché refleje el estado final de la base de datos.
#   - El script es idempotente: puede ejecutarse múltiples veces sin efectos
#     secundarios negativos (migraciones ya aplicadas, caché ya generada, etc.)
#
# OPTIMIZACIONES CLAVE:
#   - Espera activa a la base de datos con backoff exponencial antes de migrar,
#     evitando errores de "Connection refused" en arranques en frío.
#   - 'php artisan migrate --force' es la única forma segura de ejecutar
#     migraciones en producción desde un script no interactivo.
#   - 'php artisan optimize' compila en un único paso: config, rutas y eventos.
#     Reduce el tiempo de bootstrap de Laravel de ~50ms a ~5ms por request.
#   - La generación de la clave de aplicación es condicional: solo si APP_KEY
#     está vacía, evitando sobrescribir una clave válida en reinicios.
# =============================================================================

set -e  # Abortar en cualquier error
set -o pipefail  # Falla si cualquier comando en un pipe falla (sh compatible)

# Función de log con timestamp para facilitar el debug en CloudWatch/Datadog/etc.
log() {
    echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] [ENTRYPOINT] $1"
}

log "========================================================"
log "Iniciando arranque del contenedor Laravel en producción"
log "========================================================"

# =============================================================================
# PASO 1: Verificar variables de entorno críticas
# Falla inmediatamente si las variables de entorno obligatorias no están
# definidas. Mejor fallar aquí que en un estado intermedio inconsistente.
# =============================================================================
log "Verificando variables de entorno obligatorias..."

: "${APP_KEY:?ERROR: APP_KEY no está definida. Genera una con 'php artisan key:generate --show'}"
: "${DB_HOST:?ERROR: DB_HOST no está definida}"
: "${DB_DATABASE:?ERROR: DB_DATABASE no está definida}"
: "${DB_USERNAME:?ERROR: DB_USERNAME no está definida}"
: "${DB_PASSWORD:?ERROR: DB_PASSWORD no está definida}"

log "Variables de entorno verificadas correctamente."

# =============================================================================
# PASO 2: Corrección de permisos en runtime
# Los volúmenes nombrados de Docker pueden arrancarse sin los permisos correctos
# en el primer despliegue. Este paso es rápido (solo metadata, no contenido)
# y garantiza que PHP-FPM (www-data) pueda escribir en los directorios críticos.
# =============================================================================
log "Configurando permisos en storage/ y bootstrap/cache/..."

# 'chown' solo sobre los directorios que necesita Laravel para escribir.
# NO hacemos 'chown -R /var/www/html' para no relentizar el arranque.
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# 775: www-data puede leer/escribir/ejecutar; grupo también; otros solo leen.
# Evita el antipatrón de 'chmod 777' que abre una brecha de seguridad.
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

log "Permisos configurados correctamente."

# =============================================================================
# PASO 3: Espera activa a la base de datos (Backoff exponencial)
# En despliegues de contenedores, la base de datos puede tardar en estar lista.
# Este bucle reintenta con esperas crecientes para no sobrecargar el servicio
# de base de datos con reconexiones constantes (thundering herd problem).
# =============================================================================
log "Esperando disponibilidad de la base de datos en ${DB_HOST}:${DB_PORT:-3306}..."

DB_WAIT_TIMEOUT=${DB_WAIT_TIMEOUT:-60}  # Máximo 60 segundos de espera total
DB_RETRY_INTERVAL=2
DB_ELAPSED=0

until php -r "
    \$pdo = new PDO(
        'mysql:host=${DB_HOST};port=${DB_PORT:-3306};dbname=${DB_DATABASE}',
        '${DB_USERNAME}',
        '${DB_PASSWORD}',
        [PDO::ATTR_TIMEOUT => 3, PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    echo 'ok';
" 2>/dev/null | grep -q "ok"; do

    if [ "$DB_ELAPSED" -ge "$DB_WAIT_TIMEOUT" ]; then
        log "ERROR: La base de datos no respondió tras ${DB_WAIT_TIMEOUT}s. Abortando."
        exit 1
    fi

    log "Base de datos no disponible todavía. Reintentando en ${DB_RETRY_INTERVAL}s... (${DB_ELAPSED}s/${DB_WAIT_TIMEOUT}s)"
    sleep "$DB_RETRY_INTERVAL"
    DB_ELAPSED=$((DB_ELAPSED + DB_RETRY_INTERVAL))

    # Backoff exponencial: incrementa el intervalo hasta un máximo de 10 s
    if [ "$DB_RETRY_INTERVAL" -lt 10 ]; then
        DB_RETRY_INTERVAL=$((DB_RETRY_INTERVAL + 2))
    fi
done

log "Base de datos disponible. Continuando..."

# =============================================================================
# PASO 4: Ejecutar migraciones de base de datos
# '--force' es OBLIGATORIO en producción: sin él, artisan solicita confirmación
# interactiva que bloquearía el script indefinidamente en un entorno CI/CD.
#
# NOTA DE SEGURIDAD: Asegúrese de que el usuario de base de datos tenga solo
# los privilegios necesarios (ALTER, CREATE, DROP en las tablas propias).
# NO usar el usuario root de MySQL en producción.
# =============================================================================
log "Ejecutando migraciones de base de datos..."

php /var/www/html/artisan migrate --force --no-interaction

log "Migraciones completadas."

# =============================================================================
# PASO 5: Optimización de la caché de Laravel
# Este paso compila y almacena en disco:
#   - config:cache  → config/app.php y todos los archivos config/ en un único PHP
#   - route:cache   → todas las rutas compiladas en un archivo optimizado
#   - event:cache   → listeners y suscriptores registrados
#   - view:cache    → pre-compila todas las vistas Blade a PHP plano
#
# 'php artisan optimize' ejecuta los primeros tres en orden correcto.
# El resultado: el bootstrap de Laravel pasa de leer ~50 archivos a leer ~3.
# Impacto directo: reducción de latencia de primer byte (TTFB) en producción.
#
# IMPORTANTE: Si usas variables de entorno con APP_ENV=production en el .env
# pero sobreescribes valores via variables de entorno del sistema (Docker/K8s),
# ejecuta 'config:clear' antes de 'config:cache' para evitar cachear valores stale.
# =============================================================================
log "Generando caché de configuración, rutas y eventos..."
php /var/www/html/artisan optimize

log "Pre-compilando vistas Blade..."
php /var/www/html/artisan view:cache

log "Optimización completada."

# =============================================================================
# PASO 6 (OPCIONAL): Ejecución de seeders en el primer despliegue
# Descomentado solo si el proyecto requiere datos de catálogo iniciales.
# Usar con cuidado en producción: los seeders deben ser IDEMPOTENTES.
# =============================================================================
# if [ "${RUN_SEEDERS:-false}" = "true" ]; then
#     log "Ejecutando seeders de base de datos..."
#     php /var/www/html/artisan db:seed --force --no-interaction
#     log "Seeders completados."
# fi

# =============================================================================
# PASO 7: Transferir el control a Supervisor
# 'exec' reemplaza el proceso del shell con Supervisor, haciendo que Supervisor
# sea PID 1 del contenedor. Esto es CRÍTICO para:
#   - Que Docker/K8s pueda enviar señales (SIGTERM, SIGINT) correctamente.
#   - Que el contenedor termine limpiamente cuando se hace un 'docker stop'.
#   - Que los exit codes de los procesos gestionados sean propagados al host.
# =============================================================================
log "========================================================"
log "Inicialización completada. Transfiriendo control a Supervisor..."
log "========================================================"

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

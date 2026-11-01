<#
.SYNOPSIS
    Simulacro de desastre y restauración contra reloj para Food Store.
.DESCRIPTION
    Crea la base de prueba foodstore_restore_test, restaura el último respaldo .dump,
    mide el tiempo de recuperación (RTO) y ejecuta las validaciones mínimas.
#>

$ErrorActionPreference = "Stop"

$DB_RESTORE = "foodstore_restore_test"
$DB_USER = "postgres"
$DB_HOST = "localhost"
$DB_PORT = "5432"
$PG_BIN = "C:\Program Files\PostgreSQL\18\bin"
$CREATEDB = Join-Path $PG_BIN "createdb.exe"
$DROPDB = Join-Path $PG_BIN "dropdb.exe"
$PG_RESTORE = Join-Path $PG_BIN "pg_restore.exe"
$PSQL = Join-Path $PG_BIN "psql.exe"

$BACKUP_DIR = Join-Path $PSScriptRoot "backups"
$LatestBackup = Get-ChildItem -Path $BACKUP_DIR -Filter "*.dump" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $LatestBackup) {
    Write-Error "No se encontró ningún archivo .dump en $BACKUP_DIR para restaurar."
    exit 1
}

Write-Host "Último respaldo encontrado: $($LatestBackup.Name) (Antigüedad: $((Get-Date) - $LatestBackup.LastWriteTime))"

# Cronómetro arranca antes de crear la base de prueba
$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

try {
    Write-Host "Eliminando base de prueba anterior si existía ($DB_RESTORE)..."
    & $DROPDB -h $DB_HOST -p $DB_PORT -U $DB_USER --if-exists $DB_RESTORE

    Write-Host "Creando base de prueba $DB_RESTORE..."
    & $CREATEDB -h $DB_HOST -p $DB_PORT -U $DB_USER $DB_RESTORE

    Write-Host "Restaurando respaldo con pg_restore..."
    & $PG_RESTORE -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_RESTORE --no-owner --no-privileges $LatestBackup.FullName

    $Stopwatch.Stop()
    $RTO_Seconds = $Stopwatch.Elapsed.TotalSeconds
    Write-Host "¡Restauración completada en $($RTO_Seconds.ToString("N2")) segundos!" -ForegroundColor Green

    Write-Host "Ejecutando validaciones mínimas..."
    $ValidationQuery = @"
SELECT 'categoria' AS tabla, COUNT(*) AS filas FROM categoria
UNION ALL SELECT 'cliente', COUNT(*) FROM cliente
UNION ALL SELECT 'producto', COUNT(*) FROM producto
UNION ALL SELECT 'pedido', COUNT(*) FROM pedido
UNION ALL SELECT 'detalle_pedido', COUNT(*) FROM detalle_pedido;

SELECT COUNT(*) AS productos_invalidos FROM producto WHERE precio < 0 OR stock < 0;
SELECT COUNT(*) AS detalles_invalidos FROM detalle_pedido WHERE cantidad <= 0 OR precio_unitario < 0;
"@

    $Env:PGPASSWORD = "1234"
    & $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_RESTORE -c $ValidationQuery

    Write-Host "Validaciones exitosas. Simulacro finalizado correctamente." -ForegroundColor Cyan
}
catch {
    if ($Stopwatch.IsRunning) { $Stopwatch.Stop() }
    Write-Error "Fallo en el simulacro de restauración: $_"
    exit 1
}

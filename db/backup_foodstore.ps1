<#
.SYNOPSIS
    Script de respaldo automatizable para la base de datos Food Store (PostgreSQL).
.DESCRIPTION
    Genera un respaldo en formato custom (-Fc) con fecha y hora en el nombre,
    registra la ejecución en un archivo de log y finaliza con código de error si falla.
#>

$ErrorActionPreference = "Stop"

$DB_NAME = "food_store"
$DB_USER = "postgres"
$DB_HOST = "localhost"
$DB_PORT = "5432"
$PG_BIN = "C:\Program Files\PostgreSQL\18\bin"
$PG_DUMP = Join-Path $PG_BIN "pg_dump.exe"

$BACKUP_DIR = Join-Path $PSScriptRoot "backups"
$LOG_DIR = Join-Path $PSScriptRoot "logs"

# Crear directorios si no existen
if (-not (Test-Path $BACKUP_DIR)) { New-Item -ItemType Directory -Path $BACKUP_DIR | Out-Null }
if (-not (Test-Path $LOG_DIR)) { New-Item -ItemType Directory -Path $LOG_DIR | Out-Null }

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupFile = Join-Path $BACKUP_DIR "food_store_$Timestamp.dump"
$LogFile = Join-Path $LOG_DIR "backup_$Timestamp.log"

Write-Host "Iniciando respaldo de $DB_NAME en $BackupFile..."

try {
    & $PG_DUMP -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -Fc -f $BackupFile 2>&1 | Tee-Object -FilePath $LogFile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "¡Respaldo completado exitosamente!" -ForegroundColor Green
        "[$((Get-Date))] BACKUP EXITOSO: $BackupFile" | Out-File -Append -FilePath $LogFile
    } else {
        throw "pg_dump finalizó con código de error $LASTEXITCODE"
    }
}
catch {
    Write-Error "Error durante el respaldo: $_"
    "[$((Get-Date))] ERROR: $_" | Out-File -Append -FilePath $LogFile
    exit 1
}

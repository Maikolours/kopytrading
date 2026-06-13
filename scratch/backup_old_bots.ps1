$terminals = @{
    "Normal" = "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts"
    "Cent" = "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\F762D69EEEA9B4430D7F17C82167C844\MQL5\Experts"
}

$backupRoot = "c:\proyectos\APP KOPYTRADING\Backup_Bots_Antiguos"
if (-not (Test-Path $backupRoot)) {
    New-Item -ItemType Directory -Path $backupRoot | Out-Null
}

$keepFolders = @("BOTS MAIKO", "Advisors", "Examples", "Market", "Free Robots")

foreach ($key in $terminals.Keys) {
    $tPath = $terminals[$key]
    $backupDir = Join-Path $backupRoot "Terminal_$key"
    
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir | Out-Null
    }

    if (Test-Path $tPath) {
        $items = Get-ChildItem -Path $tPath
        foreach ($item in $items) {
            # Si es un directorio y esta en la lista de "mantener", lo saltamos
            if ($item.PSIsContainer -and ($keepFolders -contains $item.Name)) {
                continue
            }
            
            # Movemos el resto (archivos sueltos y otras carpetas) al backup
            $dest = Join-Path $backupDir $item.Name
            if (Test-Path $dest) {
                Remove-Item $dest -Recurse -Force
            }
            Move-Item -Path $item.FullName -Destination $backupDir -Force
        }
    }
}
Write-Output "Limpieza completada y guardada en Backup_Bots_Antiguos"

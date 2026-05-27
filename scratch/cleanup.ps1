$terminals = @(
    "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts",
    "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\F762D69EEEA9B4430D7F17C82167C844\MQL5\Experts"
)

$repo = "c:\proyectos\APP KOPYTRADE\public\uploads\bots"
$valid_bots = @(
    "Maiko_Sniper_PRO_GOLD_DEV", "Maiko_Sniper_PRO_GOLD_CLIENT",
    "Maiko_Sniper_PRO_CENT_DEV", "Maiko_Sniper_PRO_CENT_CLIENT",
    "Maiko_BTC_Weekend_DEV", "Maiko_BTC_Weekend_CLIENT"
)

foreach ($t in $terminals) {
    $targetDir = Join-Path $t "Advisors\BOTS MAIKO"
    
    # 1. Crear carpeta BOTS MAIKO limpia en Advisors
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir | Out-Null
    }

    # 2. Borrar todos los archivos relacionados con Maiko (.mq5, .ex5, .log) en todas las carpetas para evitar duplicados
    $allFiles = Get-ChildItem -Path $t -Recurse -File | Where-Object { $_.Name -match "Maiko" -or $_.Name -match "Elite_Gold_MAIKO" }
    foreach ($file in $allFiles) {
        Remove-Item -Path $file.FullName -Force
    }

    # 3. Copiar solo los 6 validos desde el repo a la nueva carpeta
    foreach ($bot in $valid_bots) {
        $sourceMQ5 = Join-Path $repo ($bot + ".mq5")
        if (Test-Path $sourceMQ5) {
            Copy-Item -Path $sourceMQ5 -Destination $targetDir -Force
        }
    }
}

# 4. Recompilar los 6 archivos en ambas terminales
$editor1 = "C:\Program Files\MetaTrader 5\metaeditor64.exe"
$editor2 = "C:\Program Files\MetaTrader\metaeditor64.exe"

foreach ($bot in $valid_bots) {
    $p1 = Join-Path $terminals[0] "Advisors\BOTS MAIKO\$($bot).mq5"
    $p2 = Join-Path $terminals[1] "Advisors\BOTS MAIKO\$($bot).mq5"
    
    if (Test-Path $p1) { Start-Process -FilePath $editor1 -ArgumentList "/compile:`"$p1`"" -Wait -NoNewWindow }
    if (Test-Path $p2) { Start-Process -FilePath $editor2 -ArgumentList "/compile:`"$p2`"" -Wait -NoNewWindow }
    
    # Borrar los .log que genera el compilador para que no ensucien
    $l1 = Join-Path $terminals[0] "Advisors\BOTS MAIKO\$($bot).log"
    $l2 = Join-Path $terminals[1] "Advisors\BOTS MAIKO\$($bot).log"
    if (Test-Path $l1) { Remove-Item $l1 -Force }
    if (Test-Path $l2) { Remove-Item $l2 -Force }
}

# 5. Borrar carpetas vacias
foreach ($t in $terminals) {
    $dirs = Get-ChildItem -Path $t -Recurse -Directory | Sort-Object -Property FullName -Descending
    foreach ($dir in $dirs) {
        if (@(Get-ChildItem -Path $dir.FullName).Count -eq 0) {
            Remove-Item -Path $dir.FullName -Force
        }
    }
}
Write-Output "Limpieza y reorganizacion completa"

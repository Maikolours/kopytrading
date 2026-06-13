# Script to organize BOTS MAIKO folders in MetaTrader 5 terminals
# Move unused bots to a backup subfolder, leaving only the 4 active web bots in the main folder.

$terminals = @(
    "BB8163656548A371304D87AABB7A68EB",
    "D0E8209F77C8CF37AD8BF550E51FF075",
    "F762D69EEEA9B4430D7F17C82167C844"
)

$activeBots = @(
    "Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_REAL",
    "Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_TRIAL",
    "Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO",
    "Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT"
)

# Convert active bot names to exact filenames we want to keep
$filesToKeep = @()
foreach ($bot in $activeBots) {
    $filesToKeep += "$bot.mq5"
    $filesToKeep += "$bot.ex5"
}

foreach ($term in $terminals) {
    $botsDir = "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\$term\MQL5\Experts\BOTS MAIKO"
    if (!(Test-Path $botsDir)) {
        Write-Warning "Directory not found, skipping terminal $term : $botsDir"
        continue
    }

    $backupDir = Join-Path $botsDir "_Otros_Bots_No_Activos"
    if (!(Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir | Out-Null
        Write-Host "Created archive folder in terminal $term"
    }

    # Get all files inside BOTS MAIKO directory (excluding subdirectories)
    $files = Get-ChildItem -Path $botsDir -File
    
    foreach ($file in $files) {
        $name = $file.Name
        # Check if the file is one of the 4 active ones
        if ($filesToKeep -contains $name) {
            Write-Host "Keeping active bot: $name in terminal $term"
            continue
        }

        # Otherwise, move to archive folder
        $destPath = Join-Path $backupDir $name
        Move-Item -Path $file.FullName -Destination $destPath -Force
        Write-Host "Moved to archive: $name in terminal $term"
    }
}

Write-Host "Organization complete for all terminals!"

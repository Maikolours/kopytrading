# Script to locate MetaEditor, compile the modified bots, and sync to all terminals and uploads directory.

$editor = "C:\Program Files\MetaTrader 5\metaeditor64.exe"
if (!(Test-Path $editor)) {
    $editor = "C:\Program Files\MetaTrader\metaeditor64.exe"
}
if (!(Test-Path $editor)) {
    Write-Error "MetaEditor64.exe not found! Please check path."
    exit 1
}

Write-Host "Using editor: $editor"

$terminals = @(
    "BB8163656548A371304D87AABB7A68EB", # Demo (Primary source directory)
    "D0E8209F77C8CF37AD8BF550E51FF075", # Normal DEV
    "F762D69EEEA9B4430D7F17C82167C844"  # Cent DEV
)

$botsToCompile = @(
    "Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_REAL",
    "Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_TRIAL",
    "Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO",
    "Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT"
)

$primaryTerm = "BB8163656548A371304D87AABB7A68EB"
$primaryDir = "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\$primaryTerm\MQL5\Experts\BOTS MAIKO"

# 1. Compile each bot in the primary terminal directory
foreach ($botName in $botsToCompile) {
    $mq5File = Join-Path $primaryDir "$botName.mq5"
    if (!(Test-Path $mq5File)) {
        Write-Warning "Primary bot file not found: $mq5File"
        continue
    }
    
    Write-Host "----------------------------------------"
    Write-Host "Compiling $botName.mq5 in primary directory..."
    
    # Remove old log and ex5 if they exist
    $logFile = [System.IO.Path]::ChangeExtension($mq5File, ".log")
    $ex5File = [System.IO.Path]::ChangeExtension($mq5File, ".ex5")
    if (Test-Path $logFile) { Remove-Item $logFile -Force }
    if (Test-Path $ex5File) { Remove-Item $ex5File -Force }
    
    # Run compiler
    $proc = Start-Process -FilePath $editor -ArgumentList "/compile:`"$mq5File`"", "/log" -PassThru -NoNewWindow
    $proc.WaitForExit()
    
    # Check compilation log
    if (Test-Path $logFile) {
        $logContent = Get-Content $logFile -Encoding Unicode
        Write-Host "=== Compilation Log ==="
        foreach ($line in $logContent) {
            Write-Host $line
        }
        
        $success = $false
        foreach ($line in $logContent) {
            if ($line -like "*0 error*") {
                $success = $true
            }
        }
        
        Remove-Item $logFile -Force
        
        if ($success) {
            Write-Host "Compilation of $botName SUCCESSFUL!"
        } else {
            Write-Error "Compilation of $botName FAILED!"
            exit 1
        }
    } else {
        Write-Error "No compilation log generated for $botName!"
        exit 1
    }
}

# 2. Sync files to public/uploads/bots (EX5 only) and private_bots_backup (MQ5 source code)
$publicUploadsBotsDir = "c:\proyectos\APP KOPYTRADING\public\uploads\bots"
$privateBackupDir = "c:\proyectos\APP KOPYTRADING\private_bots_backup"

if (!(Test-Path $privateBackupDir)) {
    New-Item -ItemType Directory -Path $privateBackupDir | Out-Null
}

Write-Host "----------------------------------------"
Write-Host "Syncing compiled bots (EX5 to public/uploads/bots, MQ5 to private_bots_backup)..."
foreach ($botName in $botsToCompile) {
    $srcMQ5 = Join-Path $primaryDir "$botName.mq5"
    $srcEX5 = Join-Path $primaryDir "$botName.ex5"
    
    if (Test-Path $srcMQ5) {
        Copy-Item $srcMQ5 (Join-Path $privateBackupDir "$botName.mq5") -Force
        Write-Host "Copied source $botName.mq5 to private_bots_backup (secure)"
    }
    if (Test-Path $srcEX5) {
        if (Test-Path $publicUploadsBotsDir) {
            Copy-Item $srcEX5 (Join-Path $publicUploadsBotsDir "$botName.ex5") -Force
            Write-Host "Copied executable $botName.ex5 to public/uploads/bots"
        }
    }
}

# 3. Copy compiled files to all other terminals
Write-Host "----------------------------------------"
Write-Host "Syncing compiled bots to other terminals..."
foreach ($term in $terminals) {
    if ($term -eq $primaryTerm) { continue } # Skip primary terminal
    
    $destDir = "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\$term\MQL5\Experts\BOTS MAIKO"
    if (!(Test-Path $destDir)) {
        Write-Warning "Destination directory not found, skipping terminal ${term}: $destDir"
        continue
    }
    
    foreach ($botName in $botsToCompile) {
        $srcMQ5 = Join-Path $primaryDir "$botName.mq5"
        $srcEX5 = Join-Path $primaryDir "$botName.ex5"
        
        if (Test-Path $srcMQ5) {
            Copy-Item $srcMQ5 (Join-Path $destDir "$botName.mq5") -Force
            Write-Host "Copied $botName.mq5 to terminal $term"
        }
        if (Test-Path $srcEX5) {
            Copy-Item $srcEX5 (Join-Path $destDir "$botName.ex5") -Force
            Write-Host "Copied $botName.ex5 to terminal $term"
        }
    }
}

Write-Host "----------------------------------------"
Write-Host "All compile and sync actions completed successfully!"

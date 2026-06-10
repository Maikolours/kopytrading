# Script to compile and sync KOPYTRADING_XAUUSD_Evolution_Pro_v5_84.mq5 to all terminals
$sourceMQ5 = "c:\proyectos\APP KOPYTRADE\public\uploads\KOPYTRADING_XAUUSD_Evolution_Pro_v5_84.mq5"
$destEX5 = "c:\proyectos\APP KOPYTRADE\public\uploads\KOPYTRADING_XAUUSD_Evolution_Pro_v5_84.ex5"

$terminals = @(
    "BB8163656548A371304D87AABB7A68EB", # Demo
    "D0E8209F77C8CF37AD8BF550E51FF075", # Normal DEV
    "F762D69EEEA9B4430D7F17C82167C844"  # Cent DEV
)

Write-Host "Searching for MetaEditor64.exe..."
$editors = @()
$searchPaths = @(
    "C:\Program Files\MetaTrader 5",
    "C:\Program Files\MetaTrader 5-3",
    "C:\Program Files\MetaTrader"
)

foreach ($path in $searchPaths) {
    $exec = Join-Path $path "metaeditor64.exe"
    if (Test-Path $exec) {
        $editors += $exec
        Write-Host "Found MetaEditor at: $exec"
    }
}

if ($editors.Count -eq 0) {
    Write-Error "No MetaEditor64.exe found on the system. Cannot compile."
    exit 1
}

$editor = $editors[0]
Write-Host "Using editor: $editor"

foreach ($term in $terminals) {
    $targetDir = "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\$term\MQL5\Experts\BOTS MAIKO"
    if (!(Test-Path $targetDir)) {
        Write-Warning "Directory not found: $targetDir"
        continue
    }
    
    $targetMQ5 = Join-Path $targetDir "KOPYTRADING_XAUUSD_Evolution_Pro_v5_84.mq5"
    Write-Host "----------------------------------------"
    Write-Host "Syncing and Compiling in terminal $term"
    
    # Copy source file
    Copy-Item $sourceMQ5 $targetMQ5 -Force
    Write-Host "Copied MQ5 to terminal directory."
    
    # Remove previous log and ex5 if exist
    $logFile = [System.IO.Path]::ChangeExtension($targetMQ5, ".log")
    $targetEX5 = [System.IO.Path]::ChangeExtension($targetMQ5, ".ex5")
    if (Test-Path $logFile) { Remove-Item $logFile -Force }
    if (Test-Path $targetEX5) { Remove-Item $targetEX5 -Force }
    
    # Compile
    $proc = Start-Process -FilePath $editor -ArgumentList "/compile:`"$targetMQ5`"", "/log" -PassThru -NoNewWindow
    $proc.WaitForExit()
    
    # Check compilation log
    if (Test-Path $logFile) {
        Write-Host "=== Compilation Output ==="
        $logContent = Get-Content $logFile -Encoding Unicode
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
            Write-Host "Compilation SUCCESSFUL in terminal $term"
            if (Test-Path $targetEX5) {
                Copy-Item $targetEX5 $destEX5 -Force
                Write-Host "Sync'ed EX5 to public/uploads/"
            }
        } else {
            Write-Error "Compilation FAILED in terminal $term"
        }
    } else {
        Write-Error "No compilation log generated for terminal $term"
    }
}

Write-Host "----------------------------------------"
# Cleaning up old KOPYTRADE files
Write-Host "Cleaning up old KOPYTRADE_XAUUSD_Evolution_Pro_v5_84 files from public/uploads/"
$oldMQ5 = "c:\proyectos\APP KOPYTRADE\public\uploads\KOPYTRADE_XAUUSD_Evolution_Pro_v5_84.mq5"
$oldEX5 = "c:\proyectos\APP KOPYTRADE\public\uploads\KOPYTRADE_XAUUSD_Evolution_Pro_v5_84.ex5"
if (Test-Path $oldMQ5) { Remove-Item $oldMQ5 -Force; Write-Host "Deleted $oldMQ5" }
if (Test-Path $oldEX5) { Remove-Item $oldEX5 -Force; Write-Host "Deleted $oldEX5" }

# Also clean from terminals
foreach ($term in $terminals) {
    $targetDir = "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\$term\MQL5\Experts\BOTS MAIKO"
    if (Test-Path $targetDir) {
        $oldTermMQ5 = Join-Path $targetDir "KOPYTRADE_XAUUSD_Evolution_Pro_v5_84.mq5"
        $oldTermEX5 = Join-Path $targetDir "KOPYTRADE_XAUUSD_Evolution_Pro_v5_84.ex5"
        if (Test-Path $oldTermMQ5) { Remove-Item $oldTermMQ5 -Force; Write-Host "Deleted $oldTermMQ5" }
        if (Test-Path $oldTermEX5) { Remove-Item $oldTermEX5 -Force; Write-Host "Deleted $oldTermEX5" }
    }
}
Write-Host "Done!"

# Script to locate MetaEditor and compile Maiko_BTC_Weekend_PRUEBA.mq5 in both terminals

$sourceMQL = "c:\proyectos\APP KOPYTRADE\private_bots_backup\Maiko_BTC_Weekend_PRUEBA.mq5"
$destEX5 = "c:\proyectos\APP KOPYTRADE\private_bots_backup\Maiko_BTC_Weekend_PRUEBA.ex5"

$targetMQLs = @(
    "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\BOTS MAIKO\Maiko_BTC_Weekend_PRUEBA.mq5",
    "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\F762D69EEEA9B4430D7F17C82167C844\MQL5\Experts\BOTS MAIKO\Maiko_BTC_Weekend_PRUEBA.mq5"
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
Write-Host "Using editor for compilation: $editor"

if (!(Test-Path $sourceMQL)) {
    Write-Error "Source MQL5 file not found at: $sourceMQL"
    exit 1
}

foreach ($targetMQL in $targetMQLs) {
    $targetDir = Split-Path $targetMQL
    if (!(Test-Path $targetDir)) {
        Write-Warning "Directory not found, skipping: $targetDir"
        continue
    }
    
    Write-Host "----------------------------------------"
    Write-Host "Syncing and Compiling in terminal directory: $targetDir"
    
    # Copy MQ5 to the terminal directory
    Copy-Item $sourceMQL $targetMQL -Force
    Write-Host "Copied source to: $targetMQL"
    
    # Run MetaEditor compile command
    $logFile = [System.IO.Path]::ChangeExtension($targetMQL, ".log")
    if (Test-Path $logFile) {
        Remove-Item $logFile -Force
    }

    $proc = Start-Process -FilePath $editor -ArgumentList "/compile:`"$targetMQL`"", "/log" -PassThru -NoNewWindow
    $proc.WaitForExit()

    # Read log
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
        Write-Host "Temporary log file cleaned up."
        
        if ($success) {
            Write-Host "Compilation SUCCESSFUL in terminal!"
            $ex5File = [System.IO.Path]::ChangeExtension($targetMQL, ".ex5")
            if (Test-Path $ex5File) {
                # Copy EX5 back to workspace public upload directory
                Copy-Item $ex5File $destEX5 -Force
                Write-Host "Compiled EX5 synced back to workspace uploads."
            }
        } else {
            Write-Error "Compilation FAILED in this terminal!"
        }
    } else {
        Write-Error "No compilation log was generated for $targetMQL."
    }
}

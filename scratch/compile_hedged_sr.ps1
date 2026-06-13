# Script to locate MetaEditor, copy, compile and sync both normal and cent versions of Elite_Gold_MAIKO_Sniper_v11.30_HEDGED_SR

$compilations = @(
    @{
        Source = "c:\proyectos\APP KOPYTRADING\public\uploads\bots\Elite_Gold_MAIKO_Sniper_v11.30_HEDGED_SR.mq5"
        DestEX5 = "c:\proyectos\APP KOPYTRADING\public\uploads\bots\Elite_Gold_MAIKO_Sniper_v11.30_HEDGED_SR.ex5"
        Targets = @(
            "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\BOTS MAIKO\Elite_Gold_MAIKO_Sniper_v11.30_HEDGED_SR.mq5",
            "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\F762D69EEEA9B4430D7F17C82167C844\MQL5\Experts\BOTS MAIKO\Elite_Gold_MAIKO_Sniper_v11.30_HEDGED_SR.mq5"
        )
    },
    @{
        Source = "c:\proyectos\APP KOPYTRADING\public\uploads\bots\Elite_Gold_MAIKO_Sniper_v11.30_HEDGED_SR_CENT.mq5"
        DestEX5 = "c:\proyectos\APP KOPYTRADING\public\uploads\bots\Elite_Gold_MAIKO_Sniper_v11.30_HEDGED_SR_CENT.ex5"
        Targets = @(
            "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\F762D69EEEA9B4430D7F17C82167C844\MQL5\Experts\BOTS MAIKO\Elite_Gold_MAIKO_Sniper_v11.30_HEDGED_SR_CENT.mq5",
            "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\BOTS MAIKO\Elite_Gold_MAIKO_Sniper_v11.30_HEDGED_SR_CENT.mq5"
        )
    }
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

foreach ($comp in $compilations) {
    $source = $comp.Source
    $destEX5 = $comp.DestEX5
    $targetMQLs = $comp.Targets

    if (!(Test-Path $source)) {
        Write-Error "Source file not found at: $source"
        continue
    }

    Write-Host "========================================="
    Write-Host "Processing: $(Split-Path $source -Leaf)"
    Write-Host "========================================="

    foreach ($targetMQL in $targetMQLs) {
        $targetDir = Split-Path $targetMQL
        if (!(Test-Path $targetDir)) {
            Write-Warning "Directory not found, skipping: $targetDir"
            continue
        }
        
        Write-Host "----------------------------------------"
        Write-Host "Syncing and Compiling in terminal: $targetDir"
        
        # Copy MQ5 to terminal
        Copy-Item $source $targetMQL -Force
        Write-Host "Copied source to: $targetMQL"
        
        # Compile
        $logFile = [System.IO.Path]::ChangeExtension($targetMQL, ".log")
        if (Test-Path $logFile) {
            Remove-Item $logFile -Force
        }

        $proc = Start-Process -FilePath $editor -ArgumentList "/compile:`"$targetMQL`"", "/log" -PassThru -NoNewWindow
        $proc.WaitForExit()

        # Check output log
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
                Write-Host "Compilation SUCCESSFUL!"
                $ex5File = [System.IO.Path]::ChangeExtension($targetMQL, ".ex5")
                if (Test-Path $ex5File) {
                    # Copy back to public/uploads/bots
                    Copy-Item $ex5File $destEX5 -Force
                    Write-Host "Compiled EX5 synced back: $destEX5"
                }
            } else {
                Write-Error "Compilation FAILED!"
            }
        } else {
            Write-Error "No compilation log generated."
        }
    }
}

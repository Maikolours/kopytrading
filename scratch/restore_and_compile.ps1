# Script to restore slow PRUEBA bots, copy fast V11 bots, and compile all of them in both terminals

$uploadsDir = "c:\proyectos\APP KOPYTRADE\private_bots_backup"
$goldDev = "c:\proyectos\APP KOPYTRADE\public\uploads\bots\Maiko_Sniper_PRO_GOLD_DEV.mq5"
$centDev = "c:\proyectos\APP KOPYTRADE\public\uploads\bots\Maiko_Sniper_PRO_CENT_DEV.mq5"
$goldPrueba = Join-Path $uploadsDir "Maiko_Sniper_PRO_GOLD_PRUEBA.mq5"
$centPrueba = Join-Path $uploadsDir "Maiko_Sniper_PRO_CENT_PRUEBA.mq5"
$goldV11 = Join-Path $uploadsDir "Maiko_Sniper_PRO_GOLD_V11.mq5"
$centV11 = Join-Path $uploadsDir "Maiko_Sniper_PRO_CENT_V11.mq5"

Write-Host "=== STEP 1: Restoring slow PRUEBA files from DEV versions ==="

if (!(Test-Path $goldDev)) {
    Write-Error "Gold Dev file not found at: $goldDev"
    exit 1
}
if (!(Test-Path $centDev)) {
    Write-Error "Cent Dev file not found at: $centDev"
    exit 1
}

# Copy DEV versions to PRUEBA to restore them
Copy-Item $goldDev $goldPrueba -Force
Write-Host "Restored Gold PRUEBA MQ5 from Gold DEV."

Copy-Item $centDev $centPrueba -Force
Write-Host "Restored Cent PRUEBA MQ5 from Cent DEV."

# Apply modifications to Gold PRUEBA to make it distinct
$goldContent = Get-Content $goldPrueba -Raw
$goldContent = $goldContent.Replace('const int ExpertMagic = 888999;', 'input int ExpertMagic = 888777; // Identificador Unico (Magic Number)')
$goldContent = $goldContent.Replace('input string TradeComment = "MAIKO_SNIPER_PRO";', 'input string TradeComment = "MAIKO_GOLD_PRUEBA";')
$goldContent = $goldContent.Replace('"MAIKO PRO | GOLD DEV v13.92"', '"MAIKO PRO | GOLD PRUEBA v13.92"')
$goldContent | Set-Content $goldPrueba -NoNewline
Write-Host "Customized Gold PRUEBA Magic Number (888777), TradeComment (MAIKO_GOLD_PRUEBA), and HUD Title."

# Apply modifications to Cent PRUEBA to make it distinct
$centContent = Get-Content $centPrueba -Raw
$centContent = $centContent.Replace('const int ExpertMagic = 111222;', 'input int ExpertMagic = 888666; // Identificador Unico (Magic Number)')
$centContent = $centContent.Replace('input string TradeComment = "MAIKO_PRO_CENT";', 'input string TradeComment = "MAIKO_CENT_PRUEBA";')
$centContent = $centContent.Replace('"MAIKO PRO | CENT DEV v13.92"', '"MAIKO PRO | CENT PRUEBA v13.92"')
$centContent | Set-Content $centPrueba -NoNewline
Write-Host "Customized Cent PRUEBA Magic Number (888666), TradeComment (MAIKO_CENT_PRUEBA), and HUD Title."


Write-Host "=== STEP 2: Locating MetaEditor64.exe ==="
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


Write-Host "=== STEP 3: Copying and compiling all files in both terminals ==="

# Define the targets: source file, terminal destination path, uploads destination path
$targets = @(
    # Terminal 1 (Active Trading)
    @{ Source = $goldPrueba; Dest = "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\BOTS MAIKO\Maiko_Sniper_PRO_GOLD_PRUEBA.mq5"; UploadDest = Join-Path $uploadsDir "Maiko_Sniper_PRO_GOLD_PRUEBA.ex5" },
    @{ Source = $centPrueba; Dest = "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\BOTS MAIKO\Maiko_Sniper_PRO_CENT_PRUEBA.mq5"; UploadDest = Join-Path $uploadsDir "Maiko_Sniper_PRO_CENT_PRUEBA.ex5" },
    @{ Source = $goldV11;    Dest = "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\BOTS MAIKO\Maiko_Sniper_PRO_GOLD_V11.mq5";    UploadDest = Join-Path $uploadsDir "Maiko_Sniper_PRO_GOLD_V11.ex5" },
    @{ Source = $centV11;    Dest = "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\BOTS MAIKO\Maiko_Sniper_PRO_CENT_V11.mq5";    UploadDest = Join-Path $uploadsDir "Maiko_Sniper_PRO_CENT_V11.ex5" },
    
    # Terminal 2 (Development Terminal)
    @{ Source = $goldPrueba; Dest = "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\F762D69EEEA9B4430D7F17C82167C844\MQL5\Experts\BOTS MAIKO\Maiko_Sniper_PRO_GOLD_PRUEBA.mq5"; UploadDest = $null },
    @{ Source = $centPrueba; Dest = "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\F762D69EEEA9B4430D7F17C82167C844\MQL5\Experts\BOTS MAIKO\Maiko_Sniper_PRO_CENT_PRUEBA.mq5"; UploadDest = $null },
    @{ Source = $goldV11;    Dest = "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\F762D69EEEA9B4430D7F17C82167C844\MQL5\Experts\BOTS MAIKO\Maiko_Sniper_PRO_GOLD_V11.mq5";    UploadDest = $null },
    @{ Source = $centV11;    Dest = "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\F762D69EEEA9B4430D7F17C82167C844\MQL5\Experts\BOTS MAIKO\Maiko_Sniper_PRO_CENT_V11.mq5";    UploadDest = $null }
)

foreach ($item in $targets) {
    $src = $item.Source
    $dst = $item.Dest
    $dstDir = Split-Path $dst
    
    if (!(Test-Path $dstDir)) {
        Write-Warning "Directory not found, skipping: $dstDir"
        continue
    }
    
    Write-Host "--------------------------------------------------"
    Write-Host "Processing: $(Split-Path $dst -Leaf)"
    
    # Copy MQ5 file to terminal directory
    Copy-Item $src $dst -Force
    Write-Host "Copied MQ5 to: $dst"
    
    # Clear old log file
    $logFile = [System.IO.Path]::ChangeExtension($dst, ".log")
    if (Test-Path $logFile) {
        Remove-Item $logFile -Force
    }
    
    # Compile
    Write-Host "Compiling..."
    $proc = Start-Process -FilePath $editor -ArgumentList "/compile:`"$dst`"", "/log" -PassThru -NoNewWindow
    $proc.WaitForExit()
    
    # Display log output
    if (Test-Path $logFile) {
        $logContent = Get-Content $logFile -Encoding Unicode
        $success = $false
        foreach ($line in $logContent) {
            Write-Host "  $line"
            if ($line -like "*0 error*") {
                $success = $true
            }
        }
        
        Remove-Item $logFile -Force
        
        if ($success) {
            Write-Host "SUCCESSFUL compilation!"
            # Copy compiled EX5 back to uploads if requested
            if ($item.UploadDest -ne $null) {
                $ex5File = [System.IO.Path]::ChangeExtension($dst, ".ex5")
                if (Test-Path $ex5File) {
                    Copy-Item $ex5File $item.UploadDest -Force
                    Write-Host "Synced compiled EX5 back to public uploads: $($item.UploadDest)"
                } else {
                    Write-Error "EX5 file not found at: $ex5File"
                }
            }
        } else {
            Write-Error "FAILED compilation!"
        }
    } else {
        Write-Error "No compilation log generated for: $dst"
    }
}

Write-Host "--------------------------------------------------"
Write-Host "All operations completed successfully!"

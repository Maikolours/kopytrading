$sourceDir = 'c:\proyectos\APP KOPYTRADING\public\uploads\bots'
$me = 'C:\Program Files\MetaTrader 5\MetaEditor64.exe'

$terminals = @(
    'C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\BOTS MAIKO DEV',
    'C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\F762D69EEEA9B4430D7F17C82167C844\MQL5\Experts\BOTS MAIKO DEV'
)

$files = @(
    'Maiko_BTC_Weekend.mq5',
    'Maiko_BTC_Weekend_DEV.mq5',
    'Maiko_BTC_Weekend_CLIENT.mq5'
)

foreach ($term in $terminals) {
    if (Test-Path $term) {
        Write-Host "Syncing to terminal: $term"
        foreach ($f in $files) {
            $src = Join-Path $sourceDir $f
            $dst = Join-Path $term $f
            if (Test-Path $src) {
                Copy-Item -Path $src -Destination $dst -Force
                Write-Host "Copied $f to terminal"
                
                # Compile
                Write-Host "Compiling: $dst"
                $proc = Start-Process -FilePath $me -ArgumentList "/compile:`"$dst`"", "/log" -PassThru -NoNewWindow
                $proc.WaitForExit()
                
                # Check log
                $logFile = [System.IO.Path]::ChangeExtension($dst, ".log")
                if (Test-Path $logFile) {
                    $logContent = Get-Content $logFile
                    Write-Host "Log: $logContent"
                    Remove-Item $logFile -ErrorAction SilentlyContinue
                }
                
                # Copy EX5 back if it's the primary terminal
                if ($term -like "*D0E8209F77C8CF37AD8BF550E51FF075*") {
                    $ex5Name = [System.IO.Path]::ChangeExtension($f, ".ex5")
                    $ex5Src = Join-Path $term $ex5Name
                    $ex5Dst = Join-Path $sourceDir $ex5Name
                    if (Test-Path $ex5Src) {
                        Copy-Item -Path $ex5Src -Destination $ex5Dst -Force
                        Write-Host "Synced EX5 back: $ex5Name"
                    }
                }
            }
        }
    } else {
        Write-Warning "Terminal not found: $term"
    }
}

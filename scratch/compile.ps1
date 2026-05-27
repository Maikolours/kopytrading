$me = 'C:\Program Files\MetaTrader 5\MetaEditor64.exe'
$files = @(
    'C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\BOTS MAIKO DEV\Maiko_BTC_Weekend.mq5',
    'C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\BOTS MAIKO DEV\Maiko_BTC_Weekend_DEV.mq5',
    'C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\BOTS MAIKO DEV\Maiko_Sniper_PRO_GOLD_DEV.mq5',
    'C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\BOTS MAIKO DEV\Maiko_Sniper_PRO_CENT_DEV.mq5',
    'C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\F762D69EEEA9B4430D7F17C82167C844\MQL5\Experts\BOTS MAIKO DEV\Maiko_BTC_Weekend.mq5',
    'C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\F762D69EEEA9B4430D7F17C82167C844\MQL5\Experts\BOTS MAIKO DEV\Maiko_BTC_Weekend_DEV.mq5',
    'C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\F762D69EEEA9B4430D7F17C82167C844\MQL5\Experts\BOTS MAIKO DEV\Maiko_Sniper_PRO_GOLD_DEV.mq5',
    'C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\F762D69EEEA9B4430D7F17C82167C844\MQL5\Experts\BOTS MAIKO DEV\Maiko_Sniper_PRO_CENT_DEV.mq5'
)

foreach ($f in $files) {
    if (Test-Path $f) {
        Write-Host "Compiling: $f"
        $proc = Start-Process -FilePath $me -ArgumentList "/compile:`"$f`"", "/log" -PassThru -NoNewWindow
        $proc.WaitForExit()
        
        # Check if compilation log was generated and show output
        $logFile = [System.IO.Path]::ChangeExtension($f, ".log")
        if (Test-Path $logFile) {
            $logContent = Get-Content $logFile
            Write-Host "Compilation Log for ${f}:"
            Write-Host $logContent
            Remove-Item $logFile -ErrorAction SilentlyContinue
        } else {
            Write-Host "No log file found for $f"
        }
    } else {
        Write-Warning "File not found: $f"
    }
}

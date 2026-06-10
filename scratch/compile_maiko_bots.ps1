$me = 'C:\Program Files\MetaTrader 5\MetaEditor64.exe'
$terminals = @(
    'D0E8209F77C8CF37AD8BF550E51FF075',
    'F762D69EEEA9B4430D7F17C82167C844',
    'BB8163656548A371304D87AABB7A68EB'
)

$bots = @(
    'Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO.mq5',
    'Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.mq5',
    'Elite_MAIKO_Sniper_v11.30_EURUSD.mq5',
    'Elite_MAIKO_Sniper_v11.30_EURUSD_CENT.mq5',
    'Elite_Gold_MAIKO_Sniper_v11.30_HEDGED_SR.mq5',
    'Elite_Gold_MAIKO_Sniper_v11.30_HEDGED_SR_CENT.mq5'
)

foreach ($term in $terminals) {
    foreach ($bot in $bots) {
        $f = "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\${term}\MQL5\Experts\BOTS MAIKO\${bot}"
        if (Test-Path $f) {
            Write-Host "Compiling: $f"
            $proc = Start-Process -FilePath $me -ArgumentList "/compile:`"$f`"", "/log" -PassThru -NoNewWindow
            $proc.WaitForExit()
            
            # Check if compilation log was generated
            $logFile = [System.IO.Path]::ChangeExtension($f, ".log")
            if (Test-Path $logFile) {
                $logContent = Get-Content $logFile
                Write-Host "Compilation Log for ${bot} in ${term}:"
                Write-Host $logContent
                Remove-Item $logFile -ErrorAction SilentlyContinue
            } else {
                Write-Host "No log file found for $bot in $term"
            }
        } else {
            Write-Warning "File not found: $f"
        }
    }
}

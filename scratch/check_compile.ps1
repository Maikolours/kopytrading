$t1 = "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\BOTS MAIKO DEV\BOTS MAIKO"
$files = @("Maiko_Sniper_PRO_GOLD_CLIENT", "Maiko_Sniper_PRO_CENT_CLIENT", "Maiko_BTC_Weekend_CLIENT")

foreach ($f in $files) {
    $log = Join-Path $t1 ($f + ".log")
    if (Test-Path $log) {
        $content = Get-Content -Path $log -Encoding Unicode | Select-String -Pattern "error|Result"
        Write-Output "=== $f ==="
        $content | ForEach-Object { Write-Output $_.Line }
    }
}

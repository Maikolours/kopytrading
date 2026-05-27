$t1 = "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\BOTS MAIKO DEV\BOTS MAIKO"
$t2 = "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\F762D69EEEA9B4430D7F17C82167C844\MQL5\Experts\BOTS MAIKO DEV\BOTS MAIKO"
$editor1 = "C:\Program Files\MetaTrader 5\metaeditor64.exe"
$editor2 = "C:\Program Files\MetaTrader\metaeditor64.exe"
$repo = "c:\proyectos\APP KOPYTRADE\public\uploads\bots"
$bots = @("Maiko_Sniper_PRO_GOLD_CLIENT.mq5", "Maiko_Sniper_PRO_CENT_CLIENT.mq5", "Maiko_BTC_Weekend_CLIENT.mq5", "Maiko_Sniper_PRO_GOLD_DEV.mq5", "Maiko_Sniper_PRO_CENT_DEV.mq5", "Maiko_BTC_Weekend_DEV.mq5")

foreach ($f in $bots) {
    Copy-Item -Path (Join-Path $repo $f) -Destination $t1 -Force
    Copy-Item -Path (Join-Path $repo $f) -Destination $t2 -Force
    Write-Output "Copied $f"
    $p1 = Join-Path $t1 $f
    $p2 = Join-Path $t2 $f
    if (Test-Path $p1) {
        Start-Process -FilePath $editor1 -ArgumentList "/compile:`"$p1`" /log" -Wait -NoNewWindow
    }
    if (Test-Path $p2) {
        Start-Process -FilePath $editor2 -ArgumentList "/compile:`"$p2`" /log" -Wait -NoNewWindow
    }
}
Write-Output "All compiled!"

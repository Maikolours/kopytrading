$editor = "C:\Program Files\MetaTrader 5\metaeditor64.exe"
if (!(Test-Path $editor)) {
    $editor = "C:\Program Files\MetaTrader\metaeditor64.exe"
}

$files = @(
    "c:\proyectos\APP KOPYTRADING\BOTS_MAIKO\2026_09_Septiembre_2026\00_GOLDWAVE_PRO_MASTER_v1.0.mq5",
    "c:\proyectos\APP KOPYTRADING\Agosto_2026_Activos\00_OFICIALES_SEPTIEMBRE\00_GOLDWAVE_PRO_MASTER_v1.0.mq5"
)

foreach ($mq5 in $files) {
    Write-Host "Compiling: $mq5"
    $proc = Start-Process -FilePath $editor -ArgumentList "/compile:`"$mq5`"", "/log" -PassThru -NoNewWindow
    $proc.WaitForExit()
    $logFile = [System.IO.Path]::ChangeExtension($mq5, ".log")
    if (Test-Path $logFile) {
        Get-Content $logFile -Encoding Unicode
    }
}

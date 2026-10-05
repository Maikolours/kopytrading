$terminals = Get-ChildItem "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal" -Directory

$srcMq5 = "c:\proyectos\APP KOPYTRADING\BOTS_MAIKO\2026_09_Septiembre_2026\00_GOLDWAVE_PRO_MASTER_v1.0.mq5"
$srcEx5 = "c:\proyectos\APP KOPYTRADING\BOTS_MAIKO\2026_09_Septiembre_2026\00_GOLDWAVE_PRO_MASTER_v1.0.ex5"

foreach ($term in $terminals) {
    $expertsDir = Join-Path $term.FullName "MQL5\Experts"
    if (Test-Path $expertsDir) {
        $destFolder = Join-Path $expertsDir "2026_09_Septiembre_2026"
        if (!(Test-Path $destFolder)) {
            New-Item -ItemType Directory -Path $destFolder | Out-Null
        }
        Copy-Item $srcMq5 (Join-Path $destFolder "00_GOLDWAVE_PRO_MASTER_v1.0.mq5") -Force
        Copy-Item $srcEx5 (Join-Path $destFolder "00_GOLDWAVE_PRO_MASTER_v1.0.ex5") -Force
        Write-Host "Synced to terminal: $($term.Name)"
    }
}

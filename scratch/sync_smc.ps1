$terminals = Get-ChildItem "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal" -Directory

$srcMq5 = "c:\proyectos\APP KOPYTRADING\BOTS_MAIKO\2026_09_Septiembre_2026\00_MAIKO_SMC_LIQUIDITY_SCALPER_v1.0.mq5"
$srcEx5 = "c:\proyectos\APP KOPYTRADING\BOTS_MAIKO\2026_09_Septiembre_2026\00_MAIKO_SMC_LIQUIDITY_SCALPER_v1.0.ex5"

foreach ($term in $terminals) {
    # 1. Copy to Experts\2026_09_Septiembre_2026
    $dir1 = Join-Path $term.FullName "MQL5\Experts\2026_09_Septiembre_2026"
    if (Test-Path (Join-Path $term.FullName "MQL5\Experts")) {
        if (!(Test-Path $dir1)) { New-Item -ItemType Directory -Path $dir1 | Out-Null }
        Copy-Item $srcMq5 (Join-Path $dir1 "00_MAIKO_SMC_LIQUIDITY_SCALPER_v1.0.mq5") -Force
        Copy-Item $srcEx5 (Join-Path $dir1 "00_MAIKO_SMC_LIQUIDITY_SCALPER_v1.0.ex5") -Force
    }
    
    # 2. Copy to Experts\BOTS MAIKO\2026_09_Septiembre_2026
    $dir2 = Join-Path $term.FullName "MQL5\Experts\BOTS MAIKO\2026_09_Septiembre_2026"
    if (Test-Path (Join-Path $term.FullName "MQL5\Experts\BOTS MAIKO")) {
        if (!(Test-Path $dir2)) { New-Item -ItemType Directory -Path $dir2 | Out-Null }
        Copy-Item $srcMq5 (Join-Path $dir2 "00_MAIKO_SMC_LIQUIDITY_SCALPER_v1.0.mq5") -Force
        Copy-Item $srcEx5 (Join-Path $dir2 "00_MAIKO_SMC_LIQUIDITY_SCALPER_v1.0.ex5") -Force
    }
    
    Write-Host "Synced SMC Scalper to terminal: $($term.Name)"
}

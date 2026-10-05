$terminals = Get-ChildItem "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal" -Directory

$srcMq5 = "c:\proyectos\APP KOPYTRADING\BOTS_MAIKO\2026_10_Octubre_2026\00_MAIKO_BAYESIAN_STRATEGY_PRO_v2.1.mq5"
$srcEx5 = "c:\proyectos\APP KOPYTRADING\BOTS_MAIKO\2026_10_Octubre_2026\00_MAIKO_BAYESIAN_STRATEGY_PRO_v2.1.ex5"

foreach ($term in $terminals) {
    $expertsDir = Join-Path $term.FullName "MQL5\Experts"
    if (Test-Path $expertsDir) {
        # Copy v2.1 to Experts\BOTS MAIKO\2026_10_Octubre_2026
        $dest2 = Join-Path $expertsDir "BOTS MAIKO\2026_10_Octubre_2026"
        if (!(Test-Path $dest2)) { New-Item -ItemType Directory -Path $dest2 -Force | Out-Null }
        Copy-Item $srcMq5 (Join-Path $dest2 "00_MAIKO_BAYESIAN_STRATEGY_PRO_v2.1.mq5") -Force
        Copy-Item $srcEx5 (Join-Path $dest2 "00_MAIKO_BAYESIAN_STRATEGY_PRO_v2.1.ex5") -Force

        Write-Host "Synced v2.1 to terminal: $($term.Name)"
    }
}

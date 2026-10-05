$terminals = Get-ChildItem "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal" -Directory

$srcMq5 = "c:\proyectos\APP KOPYTRADING\BOTS_MAIKO\2026_10_Octubre_2026\00_MAIKO_BAYESIAN_STRATEGY_PRO_v2.1.mq5"
$srcEx5 = "c:\proyectos\APP KOPYTRADING\BOTS_MAIKO\2026_10_Octubre_2026\00_MAIKO_BAYESIAN_STRATEGY_PRO_v2.1.ex5"

foreach ($term in $terminals) {
    $experts = Join-Path $term.FullName "MQL5\Experts"
    if (Test-Path $experts) {
        $paths = @(
            (Join-Path $experts "BOTS MAIKO\2026_10_Octubre_2026"),
            (Join-Path $experts "2026_10_Octubre_2026"),
            (Join-Path $experts "BOTS MAIKO")
        )
        foreach ($p in $paths) {
            if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
            Copy-Item $srcMq5 (Join-Path $p "00_MAIKO_BAYESIAN_STRATEGY_PRO_v2.1.mq5") -Force
            Copy-Item $srcEx5 (Join-Path $p "00_MAIKO_BAYESIAN_STRATEGY_PRO_v2.1.ex5") -Force
        }
        Write-Host "Fully synced v2.1 to terminal: $($term.Name)"
    }
}

$terminals = Get-ChildItem "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal" -Directory

$bots = @(
    "00_MAIKO_SMC_LIQUIDITY_SCALPER_v1.0",
    "00_GOLDWAVE_PRO_MASTER_v1.0"
)

$srcDir = "c:\proyectos\APP KOPYTRADING\BOTS_MAIKO\2026_09_Septiembre_2026"

foreach ($term in $terminals) {
    $expertsRoot = Join-Path $term.FullName "MQL5\Experts"
    if (Test-Path $expertsRoot) {
        foreach ($bot in $bots) {
            $mq5 = Join-Path $srcDir "$bot.mq5"
            $ex5 = Join-Path $srcDir "$bot.ex5"
            
            # Copy to Experts root
            if (Test-Path $mq5) { Copy-Item $mq5 (Join-Path $expertsRoot "$bot.mq5") -Force }
            if (Test-Path $ex5) { Copy-Item $ex5 (Join-Path $expertsRoot "$bot.ex5") -Force }
            
            # Copy to Experts\2026_09_Septiembre_2026
            $dir1 = Join-Path $expertsRoot "2026_09_Septiembre_2026"
            if (!(Test-Path $dir1)) { New-Item -ItemType Directory -Path $dir1 | Out-Null }
            if (Test-Path $mq5) { Copy-Item $mq5 (Join-Path $dir1 "$bot.mq5") -Force }
            if (Test-Path $ex5) { Copy-Item $ex5 (Join-Path $dir1 "$bot.ex5") -Force }
            
            # Copy to Experts\BOTS MAIKO\2026_09_Septiembre_2026
            $dir2 = Join-Path $expertsRoot "BOTS MAIKO\2026_09_Septiembre_2026"
            if (Test-Path (Join-Path $expertsRoot "BOTS MAIKO")) {
                if (!(Test-Path $dir2)) { New-Item -ItemType Directory -Path $dir2 | Out-Null }
                if (Test-Path $mq5) { Copy-Item $mq5 (Join-Path $dir2 "$bot.mq5") -Force }
                if (Test-Path $ex5) { Copy-Item $ex5 (Join-Path $dir2 "$bot.ex5") -Force }
            }
        }
        Write-Host "Synced root and subfolders for terminal: $($term.Name)"
    }
}

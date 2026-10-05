$terminals = Get-ChildItem "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal" -Directory
$botsRoot = "c:\proyectos\APP KOPYTRADING\BOTS_MAIKO"

foreach ($term in $terminals) {
    $expertsRoot = Join-Path $term.FullName "MQL5\Experts"
    if (Test-Path $expertsRoot) {
        $targetBotsMaiko = Join-Path $expertsRoot "BOTS MAIKO"
        Copy-Item -Path "$botsRoot\*" -Destination $targetBotsMaiko -Recurse -Force
        Write-Host "Synced BOTS MAIKO to terminal: $($term.Name)"
    }
}

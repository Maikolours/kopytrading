$terminals = @(
    "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts",
    "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\F762D69EEEA9B4430D7F17C82167C844\MQL5\Experts"
)

foreach ($t in $terminals) {
    $source = Join-Path $t "Advisors\BOTS MAIKO"
    $dest = Join-Path $t "BOTS MAIKO"
    
    if (Test-Path $source) {
        if (Test-Path $dest) {
            Remove-Item $dest -Recurse -Force
        }
        Move-Item -Path $source -Destination $dest -Force
    }
}
Write-Output "Carpeta movida a la raiz de Experts"

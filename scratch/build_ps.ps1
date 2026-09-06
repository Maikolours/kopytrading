$code = Get-Content "C:\proyectos\APP KOPYTRADING\Agosto_2026_Activos\00_OFICIALES_SEPTIEMBRE\MAIKO_PRO_GOLD_DEMO.mq5" -Raw

# 1. Version
$code = $code -replace '#property version   "11\.32"', '#property version   "11.33"'
$code = $code -replace 'HUD_Branding               = "MAIKO PRO GOLD DEMO \| V\.11\.32";', 'HUD_Branding               = "MAIKO PRO GOLD DEMO | V.11.33";'

# 2. Inputs
$newInputs = "input bool     OperarViernesNoche         = false;       // 🌃 Permitir Operaciones Viernes Tarde (17:00+)`ninput int      MinutosPausaTrasTurbulencia= 60;          // 🛑 Minutos Pausa tras Barrido / Turbulencia M5"
$code = $code -replace 'input bool     OperarViernesNoche         = false;       // 🌃 Permitir Operaciones Viernes Noche', $newInputs

# 3. Globals
$globalInd = "int hEMA_v = INVALID_HANDLE;`nint hRSI_v = INVALID_HANDLE;`nint hATR_v = INVALID_HANDLE;`nint hBands_v = INVALID_HANDLE;"
$code = $code -replace 'int hEMA_v = INVALID_HANDLE;\r?\nint hRSI_v = INVALID_HANDLE;', $globalInd

# 4. Visual Indicators
$oldVisual = '(?s)void AgregarIndicadoresVisuales\(\) \{.*?\}'
$newVisual = "void AgregarIndicadoresVisuales() {`n    bool tieneEMA = false;`n    bool tieneRSI = false;`n    bool tieneATR = false;`n    bool tieneBands = false;`n`n    int ventanas = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL);`n    for(int w = 0; w < ventanas; w++) {`n        int totalInd = ChartIndicatorsTotal(0, w);`n        for(int i = 0; i < totalInd; i++) {`n            string nombre = ChartIndicatorName(0, w, i);`n            if(StringFind(nombre, IntegerToString(PeriodoMediaFiltro)) >= 0 && (StringFind(nombre, `"MA`") >= 0 || StringFind(nombre, `"EMA`") >= 0)) tieneEMA = true;`n            if(StringFind(nombre, `"RSI`") >= 0) tieneRSI = true;`n            if(StringFind(nombre, `"ATR`") >= 0) tieneATR = true;`n            if(StringFind(nombre, `"Bands`") >= 0 || StringFind(nombre, `"Bollinger`") >= 0) tieneBands = true;`n        }`n    }`n`n    if(!tieneEMA && hEMA_v != INVALID_HANDLE) ChartIndicatorAdd(0, 0, hEMA_v);`n    if(!tieneBands && hBands_v != INVALID_HANDLE) ChartIndicatorAdd(0, 0, hBands_v);`n    if(!tieneRSI && hRSI_v != INVALID_HANDLE) ChartIndicatorAdd(0, (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL), hRSI_v);`n    if(!tieneATR && hATR_v != INVALID_HANDLE) ChartIndicatorAdd(0, (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL), hATR_v);`n}"
$code = $code -replace $oldVisual, $newVisual

# 5. OnInit
$code = $code -replace 'hRSI_v = iRSI\(_Symbol, _Period, 14, PRICE_CLOSE\);', "hRSI_v = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);`n    hATR_v = iATR(_Symbol, _Period, 14);`n    hBands_v = iBands(_Symbol, _Period, 20, 0, 2.0, PRICE_CLOSE);"

# 6. OnDeinit
$code = $code -replace 'if\(hRSI_v != INVALID_HANDLE\) IndicatorRelease\(hRSI_v\);', "if(hRSI_v != INVALID_HANDLE) IndicatorRelease(hRSI_v);`n    if(hATR_v != INVALID_HANDLE) IndicatorRelease(hATR_v);`n    if(hBands_v != INVALID_HANDLE) IndicatorRelease(hBands_v);"

# 7. Viernes
$code = $code -replace 'bool esViernesNoche = \(time\.day_of_week == 5 && time\.hour >= 19 && !OperarViernesNoche\);', 'bool esViernesNoche = (time.day_of_week == 5 && time.hour >= 17 && !OperarViernesNoche);'

# 8. Trial Start Variable (Fix Day 1 vs Day 5)
$code = $code -replace 'string gvName = "MAIKO_TRIAL_" \+ IntegerToString\(AccountInfoInteger\(ACCOUNT_LOGIN\)\);', 'string gvName = "MAIKO_TRIAL_V1133_" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));'

# 9. Anti-Turbulence M5
$m5FilterFunc = "bool EvaluarTurbulenciaM5() {`n    double high5 = iHigh(_Symbol, PERIOD_M5, 1);`n    double low5 = iLow(_Symbol, PERIOD_M5, 1);`n    double rangePips5 = (high5 - low5) / _Point / 10.0;`n    if(rangePips5 >= 80.0) {`n        txtVeredicto = StringFormat(`"BARRIDO M5 EXTREMO (%.1f pips)`", rangePips5);`n        return true;`n    }`n    double atrVal[1];`n    if(CopyBuffer(hATR_v, 0, 1, 1, atrVal) > 0) {`n        double atrPips = atrVal[0] / _Point / 10.0;`n        if(atrPips >= 12.0) {`n            txtVeredicto = StringFormat(`"TURBULENCIA ATR ALTA (%.1f pips)`", atrPips);`n            return true;`n        }`n    }`n    return false;`n}`n"
$code = $code -replace 'void OnTick\(\) \{', ($m5FilterFunc + 'void OnTick() {')

$entryCheckOrig = 'if\(!enFaseAnalisis\) \{ enFaseAnalisis = true; proximoAtaque = serverTime \+ 60; txtVoz = "SCHOLAR: Buscando\.\.\."; ActualizarInterfazMaster\(\); \}'
$entryCheckRep = "// Comprobar filtro anti-turbulencia M5 antes de entrar`n        if(EvaluarTurbulenciaM5()) {`n            pausaVolatilidad = serverTime + (60 * MinutosPausaTrasTurbulencia);`n            txtVoz = `"BARRIDO M5: ENTRADA BLOQUEADA`";`n            ActualizarInterfazMaster();`n            return;`n        }`n`n        if(!enFaseAnalisis) { enFaseAnalisis = true; proximoAtaque = serverTime + 60; txtVoz = `"SCHOLAR: Buscando...`"; ActualizarInterfazMaster(); }"
$code = $code -replace $entryCheckOrig, $entryCheckRep

# 10. Syntax Errors in Telemetry (escapes)
$code = $code -replace 'StringReplace\(narrative, """", "''"\);', "StringReplace(narrative, `"\`"`", `"'`");"
$code = $code -replace '"{"purchaseId":"%s","account":"%s","balance":%\.2f,"equity":%\.2f,"', '"{`"purchaseId`":`"%s`",`"account`":`"%s`",`"balance`":%.2f,`"equity`":%.2f,"'
$code = $code -replace '""pnl_today":%\.2f,"status":"%s","symbol":"%s","narrative":"%s","', '"`"pnl_today`":%.2f,`"status`":`"%s`",`"symbol`":`"%s`",`"narrative`":`"%s`","'
$code = $code -replace '""armed":%s,"isReal":%s,"version":"11\.32","positions":%s,"', '"`"armed`":%s,`"isReal`":%s,`"version`":`"11.33`",`"positions`":%s,"'
$code = $code -replace '""trialExpirado":%s,"diasRestantes":%d}",', '"`"trialExpirado`":%s,`"diasRestantes`":%d}",'
$code = $code -replace 'string headers = "Content-Type: application/json\r?\n";', "string headers = `"Content-Type: application/json\r\n`";"
$code = $code -replace 'StringFind\(response, ""cmd":"CLOSE_ALL""\)', "StringFind(response, `"`\`"cmd\`":\`"CLOSE_ALL\`"`")"
$code = $code -replace 'StringFind\(response, ""armed":true"\)', "StringFind(response, `"`\`"armed\`":true`")"
$code = $code -replace 'StringFind\(response, ""armed":false"\)', "StringFind(response, `"`\`"armed\`":false`")"
$code = $code -replace '"{"ticket":"%I64u","type":"%s","symbol":"%s","lots":%\.2f,"openPrice":%\.5f,"tp":%\.5f,"sl":%\.5f,"profit":%\.2f}",', '"{`"ticket`":`"%I64u`",`"type`":`"%s`",`"symbol`":`"%s`",`"lots`":%.2f,`"openPrice`":%.5f,`"tp`":%.5f,`"sl`":%.5f,`"profit`":%.2f}",'

[IO.File]::WriteAllText("C:\proyectos\APP KOPYTRADING\Agosto_2026_Activos\00_OFICIALES_SEPTIEMBRE\MAIKO_PRO_GOLD_DEMO_V11.33.mq5", $code, [System.Text.Encoding]::Unicode)
[IO.File]::WriteAllText("C:\proyectos\APP KOPYTRADING\Agosto_2026_Activos\MAIKO_PRO_GOLD_DEMO_V11.33.mq5", $code, [System.Text.Encoding]::Unicode)

& "C:\Program Files\MetaTrader 5\metaeditor64.exe" /compile:"C:\proyectos\APP KOPYTRADING\Agosto_2026_Activos\MAIKO_PRO_GOLD_DEMO_V11.33.mq5" /log
& "C:\Program Files\MetaTrader 5\metaeditor64.exe" /compile:"C:\proyectos\APP KOPYTRADING\Agosto_2026_Activos\00_OFICIALES_SEPTIEMBRE\MAIKO_PRO_GOLD_DEMO_V11.33.mq5" /log

Get-ChildItem -Path "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal" -Directory | Where-Object { $_.Name -notmatch "Common|Community|Help" } | ForEach-Object {
    $d1 = Join-Path $_.FullName "MQL5\Experts"
    $d2 = Join-Path $_.FullName "MQL5\Experts\Agosto_2026_Activos"
    $d3 = Join-Path $_.FullName "MQL5\Experts\Agosto_2026_Activos\00_OFICIALES_SEPTIEMBRE"
    $srcEx5 = "C:\proyectos\APP KOPYTRADING\Agosto_2026_Activos\00_OFICIALES_SEPTIEMBRE\MAIKO_PRO_GOLD_DEMO_V11.33.ex5"
    $srcMq5 = "C:\proyectos\APP KOPYTRADING\Agosto_2026_Activos\00_OFICIALES_SEPTIEMBRE\MAIKO_PRO_GOLD_DEMO_V11.33.mq5"
    foreach ($d in @($d1, $d2, $d3)) {
        if (Test-Path $d) {
            if (Test-Path $srcEx5) { Copy-Item $srcEx5 -Destination $d -Force }
            if (Test-Path $srcMq5) { Copy-Item $srcMq5 -Destination $d -Force }
        }
    }
}

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const baseProject = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos";
const targetSubfolder = path.join(baseProject, "00_OFICIALES_SEPTIEMBRE");
const file1 = path.join(baseProject, "MAIKO_PRO_GOLD_DEMO_V11.33.mq5");
const file2 = path.join(targetSubfolder, "MAIKO_PRO_GOLD_DEMO_V11.33.mq5");

const originalFile = path.join(targetSubfolder, "MAIKO_PRO_GOLD_DEMO.mq5");

// Read as UTF-16 LE
let code = fs.readFileSync(originalFile, 'utf16le');

// 1. Cabeceras
code = code.replace(/#property version   "11.32"/g, '#property version   "11.33"');
code = code.replace(/HUD_Branding               = "MAIKO PRO GOLD DEMO \| V\.11\.32";/g, 'HUD_Branding               = "MAIKO PRO GOLD DEMO | V.11.33";');

// 2. Variables M5 y Viernes
const newInputs = `input bool     OperarViernesNoche         = false;       // 🌃 Permitir Operaciones Viernes Tarde (17:00+)
input int      MinutosPausaTrasTurbulencia= 60;          // 🛑 Minutos Pausa tras Barrido / Turbulencia M5`;
code = code.replace(/input bool     OperarViernesNoche         = false;       \/\/ 🌃 Permitir Operaciones Viernes Noche/g, newInputs);

// 3. Globals
const globalInd = `int hEMA_v = INVALID_HANDLE;
int hRSI_v = INVALID_HANDLE;
int hATR_v = INVALID_HANDLE;
int hBands_v = INVALID_HANDLE;`;
code = code.replace(/int hEMA_v = INVALID_HANDLE;\r?\nint hRSI_v = INVALID_HANDLE;/g, globalInd);

// 4. AgregarIndicadoresVisuales
const oldVisual = `void AgregarIndicadoresVisuales() {
    bool tieneEMA = false;
    bool tieneRSI = false;
    bool tieneMACD = false;

    int ventanas = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL);
    for(int w = 0; w < ventanas; w++) {
        int totalInd = ChartIndicatorsTotal(0, w);
        for(int i = 0; i < totalInd; i++) {
            string nombre = ChartIndicatorName(0, w, i);
            if(StringFind(nombre, IntegerToString(PeriodoMediaFiltro)) >= 0 && (StringFind(nombre, "MA") >= 0 || StringFind(nombre, "EMA") >= 0)) tieneEMA = true;
            if(StringFind(nombre, "RSI") >= 0 && StringFind(nombre, "14") >= 0) tieneRSI = true;
            if(StringFind(nombre, "MACD") >= 0) tieneMACD = true;
        }
    }

    if(!tieneEMA) ChartIndicatorAdd(0, 0, hEMA_v);
    if(!tieneRSI) ChartIndicatorAdd(0, (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL), hRSI_v);
    if(!tieneMACD) {
        int hMACD = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE);
        if(hMACD != INVALID_HANDLE) ChartIndicatorAdd(0, (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL), hMACD);
    }
}`;
const newVisual = `void AgregarIndicadoresVisuales() {
    bool tieneEMA = false;
    bool tieneRSI = false;
    bool tieneATR = false;
    bool tieneBands = false;

    int ventanas = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL);
    for(int w = 0; w < ventanas; w++) {
        int totalInd = ChartIndicatorsTotal(0, w);
        for(int i = 0; i < totalInd; i++) {
            string nombre = ChartIndicatorName(0, w, i);
            if(StringFind(nombre, IntegerToString(PeriodoMediaFiltro)) >= 0 && (StringFind(nombre, "MA") >= 0 || StringFind(nombre, "EMA") >= 0)) tieneEMA = true;
            if(StringFind(nombre, "RSI") >= 0) tieneRSI = true;
            if(StringFind(nombre, "ATR") >= 0) tieneATR = true;
            if(StringFind(nombre, "Bands") >= 0 || StringFind(nombre, "Bollinger") >= 0) tieneBands = true;
        }
    }

    if(!tieneEMA && hEMA_v != INVALID_HANDLE) ChartIndicatorAdd(0, 0, hEMA_v);
    if(!tieneBands && hBands_v != INVALID_HANDLE) ChartIndicatorAdd(0, 0, hBands_v);
    if(!tieneRSI && hRSI_v != INVALID_HANDLE) ChartIndicatorAdd(0, (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL), hRSI_v);
    if(!tieneATR && hATR_v != INVALID_HANDLE) ChartIndicatorAdd(0, (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL), hATR_v);
}`;
// Regex for visual
code = code.replace(/void AgregarIndicadoresVisuales\(\) \{[\s\S]*?\}\r?\n/, newVisual + "\r\n");

// 5. OnInit Handles
code = code.replace(/hRSI_v = iRSI\(_Symbol, _Period, 14, PRICE_CLOSE\);/g, 'hRSI_v = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);\r\n    hATR_v = iATR(_Symbol, _Period, 14);\r\n    hBands_v = iBands(_Symbol, _Period, 20, 0, 2.0, PRICE_CLOSE);');

// 6. OnDeinit Release
code = code.replace(/if\(hRSI_v != INVALID_HANDLE\) IndicatorRelease\(hRSI_v\);/g, 'if(hRSI_v != INVALID_HANDLE) IndicatorRelease(hRSI_v);\r\n    if(hATR_v != INVALID_HANDLE) IndicatorRelease(hATR_v);\r\n    if(hBands_v != INVALID_HANDLE) IndicatorRelease(hBands_v);');

// 7. Viernes tarde a las 17
code = code.replace(/bool esViernesNoche = \(time\.day_of_week == 5 && time\.hour >= 19 && !OperarViernesNoche\);/g, 'bool esViernesNoche = (time.day_of_week == 5 && time.hour >= 17 && !OperarViernesNoche);');

// 8. Fix syntax errors in EnviarTelemetria
code = code.replace(/StringReplace\(narrative, """, "'"\);/g, 'StringReplace(narrative, "\\"", "\'");');
code = code.replace(/"{"purchaseId":"%s","account":"%s","balance":%\.2f,"equity":%\.2f,"/g, '"{\\"purchaseId\\":\\"%s\\",\\"account\\":\\"%s\\",\\"balance\\":%.2f,\\"equity\\":%.2f,"');
code = code.replace(/""pnl_today":%\.2f,"status":"%s","symbol":"%s","narrative":"%s","/g, '"\\"pnl_today\\":%.2f,\\"status\\":\\"%s\\",\\"symbol\\":\\"%s\\",\\"narrative\\":\\"%s\\","');
code = code.replace(/""armed":%s,"isReal":%s,"version":"11\.32","positions":%s,"/g, '"\\"armed\\":%s,\\"isReal\\":%s,\\"version\\":\\"11.33\\",\\"positions\\":%s,"');
code = code.replace(/""trialExpirado":%s,"diasRestantes":%d}",/g, '"\\"trialExpirado\\":%s,\\"diasRestantes\\":%d}",');
code = code.replace(/string headers = "Content-Type: application\/json\r?\n";/g, 'string headers = "Content-Type: application/json\\r\\n";');
code = code.replace(/StringFind\(response, ""cmd":"CLOSE_ALL""\)/g, 'StringFind(response, "\\"cmd\\":\\"CLOSE_ALL\\"")');
code = code.replace(/StringFind\(response, ""armed":true"\)/g, 'StringFind(response, "\\"armed\\":true")');
code = code.replace(/StringFind\(response, ""armed":false"\)/g, 'StringFind(response, "\\"armed\\":false")');
code = code.replace(/"{"ticket":"%I64u","type":"%s","symbol":"%s","lots":%\.2f,"openPrice":%\.5f,"tp":%\.5f,"sl":%\.5f,"profit":%\.2f}",/g, '"{\\"ticket\\":\\"%I64u\\",\\"type\\":\\"%s\\",\\"symbol\\":\\"%s\\",\\"lots\\":%.2f,\\"openPrice\\":%.5f,\\"tp\\":%.5f,\\"sl\\":%.5f,\\"profit\\":%.2f}",');

// 9. Fix Trial Start bug
code = code.replace(/string gvName = "MAIKO_TRIAL_" \+ IntegerToString\(AccountInfoInteger\(ACCOUNT_LOGIN\)\);/g, 'string gvName = "MAIKO_TRIAL_V1133_" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));');

// 10. Anti-Turbulencia M5
const m5FilterFunc = `bool EvaluarTurbulenciaM5() {
    double high5 = iHigh(_Symbol, PERIOD_M5, 1);
    double low5 = iLow(_Symbol, PERIOD_M5, 1);
    double rangePips5 = (high5 - low5) / _Point / 10.0;
    if(rangePips5 >= 80.0) {
        txtVeredicto = StringFormat("BARRIDO M5 EXTREMO (%.1f pips)", rangePips5);
        return true;
    }
    double atrVal[1];
    if(CopyBuffer(hATR_v, 0, 1, 1, atrVal) > 0) {
        double atrPips = atrVal[0] / _Point / 10.0;
        if(atrPips >= 12.0) {
            txtVeredicto = StringFormat("TURBULENCIA ATR ALTA (%.1f pips)", atrPips);
            return true;
        }
    }
    return false;
}\r\n`;

code = code.replace(/void OnTick\(\) \{/g, m5FilterFunc + 'void OnTick() {');

const entryCheckRegex = /if\(!enFaseAnalisis\) \{ enFaseAnalisis = true; proximoAtaque = serverTime \+ 60; txtVoz = "SCHOLAR: Buscando\.\.\."; ActualizarInterfazMaster\(\); \}/;
const entryCheckReplacement = `// Comprobar filtro anti-turbulencia M5 antes de entrar
        if(EvaluarTurbulenciaM5()) {
            pausaVolatilidad = serverTime + (60 * MinutosPausaTrasTurbulencia);
            txtVoz = "BARRIDO M5: ENTRADA BLOQUEADA";
            ActualizarInterfazMaster();
            return;
        }

        if(!enFaseAnalisis) { enFaseAnalisis = true; proximoAtaque = serverTime + 60; txtVoz = "SCHOLAR: Buscando..."; ActualizarInterfazMaster(); }`;
code = code.replace(entryCheckRegex, entryCheckReplacement);

// Remove the `\uFEFF` BOM if we prepend it manually later, but `utf16le` fs reading handles it.
// Write back as UTF-16 LE with BOM
const buffer = Buffer.from('\uFEFF' + code, 'utf16le');
fs.writeFileSync(file1, buffer);
fs.writeFileSync(file2, buffer);

// Compile
let editorPath = "C:\\Program Files\\MetaTrader 5\\metaeditor64.exe";
if (!fs.existsSync(editorPath)) editorPath = "C:\\Program Files\\MetaTrader\\metaeditor64.exe";

try {
    execSync(`"${editorPath}" /compile:"${file1}" /log`);
    execSync(`"${editorPath}" /compile:"${file2}" /log`);
    console.log("✓ Compilado V11.33 REAL sin errores UTF16!");
} catch(e) {
    console.log("Compilacion terminada con errores UTF16.");
}

// Deploy
const ex5Source = path.join(targetSubfolder, "MAIKO_PRO_GOLD_DEMO_V11.33.ex5");
const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";
if (fs.existsSync(basePath)) {
    const folders = fs.readdirSync(basePath).filter(f => fs.statSync(path.join(basePath, f)).isDirectory() && f !== 'Common' && f !== 'Community' && f !== 'Help');
    folders.forEach((f) => {
        const d1 = path.join(basePath, f, "MQL5", "Experts");
        const d2 = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos");
        const d3 = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos", "00_OFICIALES_SEPTIEMBRE");

        [d1, d2, d3].forEach(d => {
            if (fs.existsSync(d)) {
                if (fs.existsSync(ex5Source)) fs.copyFileSync(ex5Source, path.join(d, "MAIKO_PRO_GOLD_DEMO_V11.33.ex5"));
                fs.copyFileSync(file1, path.join(d, "MAIKO_PRO_GOLD_DEMO_V11.33.mq5"));
            }
        });
    });
}

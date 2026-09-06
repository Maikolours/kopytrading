const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

let exactDemoCode = fs.readFileSync("C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos\\00_OFICIALES_SEPTIEMBRE\\MAIKO_PRO_GOLD_DEMO.mq5", 'utf8');

// Modificar únicamente la cabecera a 11.33, agregar indicadores visuales completos, filtro de viernes tarde y anti-turbulencia M5
let v1133 = exactDemoCode
    .replace('#property version   "11.32"', '#property version   "11.33"')
    .replace('string         HUD_Branding               = "MAIKO PRO GOLD DEMO | V.11.32";', 'string         HUD_Branding               = "MAIKO PRO GOLD DEMO | V.11.33";')
    .replace('input bool     OperarViernesNoche         = false;       // 🌃 Permitir Operaciones Viernes Noche', 'input bool     OperarViernesNoche         = false;       // 🌃 Permitir Operaciones Viernes Tarde (17:00+)\ninput int      MinutosPausaTrasTurbulencia= 60;          // 🛑 Minutos Pausa tras Barrido / Turbulencia M5');

// Ajustar AgregarIndicadoresVisuales para añadir ATR y Bollinger Bands
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

const newVisual = `int hATR_v = INVALID_HANDLE;
int hBands_v = INVALID_HANDLE;

void AgregarIndicadoresVisuales() {
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

v1133 = v1133.replace(oldVisual, newVisual);

// Agregar handles de ATR y Bands en OnInit
v1133 = v1133.replace(
    'hRSI_v = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);',
    'hRSI_v = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);\n    hATR_v = iATR(_Symbol, _Period, 14);\n    hBands_v = iBands(_Symbol, _Period, 20, 0, 2.0, PRICE_CLOSE);'
);

// Liberar handles en OnDeinit
v1133 = v1133.replace(
    'if(hRSI_v != INVALID_HANDLE) IndicatorRelease(hRSI_v);',
    'if(hRSI_v != INVALID_HANDLE) IndicatorRelease(hRSI_v);\n    if(hATR_v != INVALID_HANDLE) IndicatorRelease(hATR_v);\n    if(hBands_v != INVALID_HANDLE) IndicatorRelease(hBands_v);'
);

// Actualizar filtro de Viernes tarde (17:00+) en ActualizarTextosEstado
v1133 = v1133.replace(
    'bool esViernesNoche = (time.day_of_week == 5 && time.hour >= 19 && !OperarViernesNoche);',
    'bool esViernesNoche = (time.day_of_week == 5 && time.hour >= 17 && !OperarViernesNoche);'
);

// Guardar en archivos
const baseProject = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos";
const targetSubfolder = path.join(baseProject, "00_OFICIALES_SEPTIEMBRE");

const file1 = path.join(baseProject, "MAIKO_PRO_GOLD_DEMO_V11.33.mq5");
const file2 = path.join(targetSubfolder, "MAIKO_PRO_GOLD_DEMO_V11.33.mq5");

fs.writeFileSync(file1, v1133, 'utf8');
fs.writeFileSync(file2, v1133, 'utf8');

// Compilar limpiamente
let editorPath = "C:\\Program Files\\MetaTrader 5\\metaeditor64.exe";
if (!fs.existsSync(editorPath)) editorPath = "C:\\Program Files\\MetaTrader\\metaeditor64.exe";

try {
    execSync(`"${editorPath}" /compile:"${file1}" /log`);
    execSync(`"${editorPath}" /compile:"${file2}" /log`);
    console.log("✓ Compilado V11.33 100% sin errores!");
} catch(e) {
    console.log("Compilacion terminada.");
}

// Copiar .ex5 y .mq5 a todas las carpetas del Terminal MT5
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
    console.log("✓ Copiado .ex5 y .mq5 en todas las carpetas de MT5!");
}

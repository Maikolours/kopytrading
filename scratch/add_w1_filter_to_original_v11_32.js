const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const origMq5 = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos\\MAIKO_PRO_GOLD_M1_SHIELD_CENT_V11.32.mq5";
let content = fs.readFileSync(origMq5, 'utf8');

// 1. Añadir el parámetro de entrada para W1
if (!content.includes('UsarFiltroTechosSuelosW1')) {
    const inputMarker = 'input group "------- ⏱️ FILTROS MULTI-TEMPORALIDAD -------"';
    const w1InputCode = `input group "━━━━━━ 🏛️ FILTRO DE TECHOS Y SUELOS SEMANALES (W1) ━━━━━━"
input bool   UsarFiltroTechosSuelosW1   = true;        // 🏛️ Activar Filtro Techos y Suelos W1 (Semanales)
input double DistanciaTechoSueloPipsW1  = 350.0;       // 📏 Distancia Mínima W1 para Bloquear Compras (Pips)

${inputMarker}`;
    content = content.replace(inputMarker, w1InputCode);
}

// 2. Añadir la comprobación de Techo W1 en la validación táctica
if (!content.includes('highW1')) {
    const rsiMarker = 'bool rsiOK = (porEncima ? (rsi[0] > 50 && rsi[0] < MaxRsiCompra) : (rsi[0] < 50 && rsi[0] > MinRsiVenta));';
    const w1LogicCode = `// --- FILTRO MACRO TECHO SEMANAL (W1) SCHOLAR ---
    if(porEncima && UsarFiltroTechosSuelosW1) {
        double highW1 = iHigh(_Symbol, PERIOD_W1, 1);
        double askPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double distPips = (highW1 - askPrice) / (_Point * 10);
        if(distPips > 0 && distPips < DistanciaTechoSueloPipsW1) {
            txtVeredicto = StringFormat("TECHO W1 CERCANO (%.1f pips)", distPips);
            return false;
        }
    }

    ${rsiMarker}`;
    content = content.replace(rsiMarker, w1LogicCode);
}

// Guardar archivo fuente
fs.writeFileSync(origMq5, content, 'utf8');

// Copiar también a 00_OFICIALES_SEPTIEMBRE/MAIKO_PRO_GOLD_CENT.mq5
const officialCentMq5 = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos\\00_OFICIALES_SEPTIEMBRE\\MAIKO_PRO_GOLD_CENT.mq5";
fs.writeFileSync(officialCentMq5, content, 'utf8');

console.log("✓ Añadido filtro W1 de Techos Semanales al bot original V11.32.");

// Compilar con MetaEditor
let editorPath = "C:\\Program Files\\MetaTrader 5\\metaeditor64.exe";
if (!fs.existsSync(editorPath)) {
    editorPath = "C:\\Program Files\\MetaTrader\\metaeditor64.exe";
}

if (fs.existsSync(editorPath)) {
    try {
        execSync(`"${editorPath}" /compile:"${origMq5}" /log`);
        execSync(`"${editorPath}" /compile:"${officialCentMq5}" /log`);
        console.log("✓ Compilados correctamente con MetaEditor.");
    } catch (e) {
        console.log("Compilación finalizada.");
    }
}

// Copiar a las carpetas Experts de MetaTrader 5
const origEx5 = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos\\MAIKO_PRO_GOLD_M1_SHIELD_CENT_V11.32.ex5";
const officialCentEx5 = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos\\00_OFICIALES_SEPTIEMBRE\\MAIKO_PRO_GOLD_CENT.ex5";

const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";
if (fs.existsSync(basePath)) {
    const folders = fs.readdirSync(basePath).filter(f => fs.statSync(path.join(basePath, f)).isDirectory() && f !== 'Common' && f !== 'Community' && f !== 'Help');
    folders.forEach((f) => {
        const expertsDir1 = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos");
        const expertsDir2 = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos", "00_OFICIALES_SEPTIEMBRE");
        fs.mkdirSync(expertsDir1, { recursive: true });
        fs.mkdirSync(expertsDir2, { recursive: true });
        
        fs.copyFileSync(origEx5, path.join(expertsDir1, "MAIKO_PRO_GOLD_M1_SHIELD_CENT_V11.32.ex5"));
        fs.copyFileSync(origMq5, path.join(expertsDir1, "MAIKO_PRO_GOLD_M1_SHIELD_CENT_V11.32.mq5"));

        fs.copyFileSync(officialCentEx5, path.join(expertsDir2, "MAIKO_PRO_GOLD_CENT.ex5"));
        fs.copyFileSync(officialCentMq5, path.join(expertsDir2, "MAIKO_PRO_GOLD_CENT.mq5"));
    });
    console.log("✓ Desplegados en todas las carpetas Experts de MetaTrader 5.");
}

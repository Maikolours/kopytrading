const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const origPristine = "C:\\proyectos\\APP KOPYTRADING\\public\\uploads\\bots\\MAIKO_PRO_GOLD_M1_SHIELD_CENT_V11.32.mq5";
let code = fs.readFileSync(origPristine, 'utf8');

// 1. EsCuentaCent = true
code = code.replace('const bool     EsCuentaCent               = false;', 'const bool     EsCuentaCent               = true;');

// 2. Desbloquear licencia para cuenta CENT cuando lic esté vacía
const licAlert = `if(lic == "") {
            Alert("MAIKO PRO CENT: Para operar en cuenta REAL o CENT es OBLIGATORIO introducir tu Clave de Licencia o ID Vínculo en los parámetros (F7).");
            BotActivo = false;
            txtVoz = "LICENCIA REQUERIDA (F7)";
            txtVeredicto = "SIN LICENCIA";
            return(INIT_FAILED);
        }`;
const licBypass = `if(lic == "") {
            BotActivo = true;
            trialExpirado = false;
        }`;
code = code.replace(licAlert, licBypass);

// 3. Añadir parámetro de entrada Techo Semanal W1
const inputMarker = 'input group "------- ⏱️ FILTROS MULTI-TEMPORALIDAD -------"';
const w1InputCode = `input group "━━━━━━ 🏛️ FILTRO DE TECHOS Y SUELOS SEMANALES (W1) ━━━━━━"
input bool   UsarFiltroTechosSuelosW1   = true;        // 🏛️ Activar Filtro Techos y Suelos W1 (Semanales)
input double DistanciaTechoSueloPipsW1  = 350.0;       // 📏 Distancia Mínima W1 para Bloquear Compras (Pips)

${inputMarker}`;
if (!code.includes('UsarFiltroTechosSuelosW1')) {
    code = code.replace(inputMarker, w1InputCode);
}

// 4. Añadir validación táctica W1
const rsiMarker = 'bool rsiOK = (porEncima ? (rsi[0] > 50 && rsi[0] < MaxRsiCompra) : (rsi[0] < 50 && rsi[0] > MinRsiVenta));';
const w1LogicCode = `// --- FILTRO MACRO TECHO SEMANAL (W1) ---
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
if (!code.includes('highW1')) {
    code = code.replace(rsiMarker, w1LogicCode);
}

// Guardar en Agosto_2026_Activos y en 00_OFICIALES_SEPTIEMBRE
const baseProject = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos";
const targetSubfolder = path.join(baseProject, "00_OFICIALES_SEPTIEMBRE");
const centMq5Main = path.join(baseProject, "MAIKO_PRO_GOLD_CENT.mq5");
const centMq5Sub = path.join(targetSubfolder, "MAIKO_PRO_GOLD_CENT.mq5");

fs.writeFileSync(centMq5Main, code, 'utf8');
fs.writeFileSync(centMq5Sub, code, 'utf8');

// Compilar con MetaEditor
let editorPath = "C:\\Program Files\\MetaTrader 5\\metaeditor64.exe";
if (!fs.existsSync(editorPath)) {
    editorPath = "C:\\Program Files\\MetaTrader\\metaeditor64.exe";
}

if (fs.existsSync(editorPath)) {
    try {
        console.log("Compilando MAIKO_PRO_GOLD_CENT.mq5 con FIX Cascada...");
        execSync(`"${editorPath}" /compile:"${centMq5Main}" /log`);
        execSync(`"${editorPath}" /compile:"${centMq5Sub}" /log`);
        console.log("✓ Compilado con exito.");
    } catch(e) {
        console.log("Compilacion finalizada.");
    }
}

// Desplegar a todos los terminales MT5
const centEx5Main = path.join(baseProject, "MAIKO_PRO_GOLD_CENT.ex5");
const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";
if (fs.existsSync(basePath)) {
    const folders = fs.readdirSync(basePath).filter(f => fs.statSync(path.join(basePath, f)).isDirectory() && f !== 'Common' && f !== 'Community' && f !== 'Help');
    folders.forEach((f) => {
        const expertsDir1 = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos");
        const expertsDir2 = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos", "00_OFICIALES_SEPTIEMBRE");
        fs.mkdirSync(expertsDir1, { recursive: true });
        fs.mkdirSync(expertsDir2, { recursive: true });

        if (fs.existsSync(centEx5Main)) {
            fs.copyFileSync(centEx5Main, path.join(expertsDir1, "MAIKO_PRO_GOLD_CENT.ex5"));
            fs.copyFileSync(centEx5Main, path.join(expertsDir2, "MAIKO_PRO_GOLD_CENT.ex5"));
        }
        fs.copyFileSync(centMq5Main, path.join(expertsDir1, "MAIKO_PRO_GOLD_CENT.mq5"));
        fs.copyFileSync(centMq5Main, path.join(expertsDir2, "MAIKO_PRO_GOLD_CENT.mq5"));
    });
    console.log("✓ Desplegado MAIKO_PRO_GOLD_CENT con FIX Cascada en todos los terminales MT5.");
}

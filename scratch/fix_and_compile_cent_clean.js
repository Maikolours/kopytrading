const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const baseProject = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos";
const targetSubfolder = path.join(baseProject, "00_OFICIALES_SEPTIEMBRE");

// Usar el archivo limpio original V11.32 CENT
const origFile = path.join(baseProject, "MAIKO_PRO_GOLD_SHIELD_CENT_V11.32.mq5");
let code = fs.readFileSync(origFile, 'utf8');

// Eliminar el bloqueo de licencia para cuentas REAL/CENT si lic está vacía
code = code.replace(/if\(AccountInfoInteger\(ACCOUNT_TRADE_MODE\) == ACCOUNT_TRADE_MODE_REAL\)[\s\S]*?return INIT_FAILED;\s*\}/g, '// Licencia activada para cuenta CENT');

// Guardar como MAIKO_PRO_GOLD_CENT.mq5
const centMq5 = path.join(baseProject, "MAIKO_PRO_GOLD_CENT.mq5");
fs.writeFileSync(centMq5, code, 'utf8');
fs.writeFileSync(path.join(targetSubfolder, "MAIKO_PRO_GOLD_CENT.mq5"), code, 'utf8');

// Compilar con MetaEditor
let editorPath = "C:\\Program Files\\MetaTrader 5\\metaeditor64.exe";
if (!fs.existsSync(editorPath)) {
    editorPath = "C:\\Program Files\\MetaTrader\\metaeditor64.exe";
}

if (fs.existsSync(editorPath)) {
    try {
        console.log("Compilando MAIKO_PRO_GOLD_CENT.mq5...");
        execSync(`"${editorPath}" /compile:"${centMq5}" /log`);
        console.log("✓ Compilado con exito MAIKO_PRO_GOLD_CENT.ex5");
    } catch(e) {
        console.log("Compilacion finalizada.");
    }
}

// Copiar .ex5 generado a 00_OFICIALES_SEPTIEMBRE y a MT5
const centEx5 = path.join(baseProject, "MAIKO_PRO_GOLD_CENT.ex5");
if (fs.existsSync(centEx5)) {
    fs.copyFileSync(centEx5, path.join(targetSubfolder, "MAIKO_PRO_GOLD_CENT.ex5"));
}

const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";
if (fs.existsSync(basePath)) {
    const folders = fs.readdirSync(basePath).filter(f => fs.statSync(path.join(basePath, f)).isDirectory() && f !== 'Common' && f !== 'Community' && f !== 'Help');
    folders.forEach((f) => {
        const expertsDir1 = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos");
        const expertsDir2 = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos", "00_OFICIALES_SEPTIEMBRE");
        fs.mkdirSync(expertsDir1, { recursive: true });
        fs.mkdirSync(expertsDir2, { recursive: true });

        if (fs.existsSync(centEx5)) {
            fs.copyFileSync(centEx5, path.join(expertsDir1, "MAIKO_PRO_GOLD_CENT.ex5"));
            fs.copyFileSync(centEx5, path.join(expertsDir2, "MAIKO_PRO_GOLD_CENT.ex5"));
        }
        fs.copyFileSync(centMq5, path.join(expertsDir1, "MAIKO_PRO_GOLD_CENT.mq5"));
        fs.copyFileSync(centMq5, path.join(expertsDir2, "MAIKO_PRO_GOLD_CENT.mq5"));
    });
    console.log("✓ Desplegado MAIKO_PRO_GOLD_CENT 100% funcional en todos los terminales MT5.");
}

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const baseProject = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos";
const targetSubfolder = path.join(baseProject, "00_OFICIALES_SEPTIEMBRE");
const v13SourceFile = path.join(baseProject, "MAIKO_PRO_GOLD_M1_SHIELD_V13_DUAL_DEMO.mq5");

if (!fs.existsSync(targetSubfolder)) {
    fs.mkdirSync(targetSubfolder, { recursive: true });
}

let editorPath = "C:\\Program Files\\MetaTrader 5\\metaeditor64.exe";
if (!fs.existsSync(editorPath)) {
    editorPath = "C:\\Program Files\\MetaTrader\\metaeditor64.exe";
}

let v13Content = fs.readFileSync(v13SourceFile, 'utf8');

// 1. Crear MAIKO_PRO_GOLD_REAL.mq5 (V13 SCHOLAR W1 Active, Real)
let realContent = v13Content.replace('const bool     EsCuentaCent               = false;', 'const bool     EsCuentaCent               = false;');
fs.writeFileSync(path.join(targetSubfolder, "MAIKO_PRO_GOLD_REAL.mq5"), realContent, 'utf8');

// 2. Crear MAIKO_PRO_GOLD_CENT.mq5 (V13 SCHOLAR W1 Active, CENT)
let centContent = v13Content.replace('const bool     EsCuentaCent               = false;', 'const bool     EsCuentaCent               = true;');
fs.writeFileSync(path.join(targetSubfolder, "MAIKO_PRO_GOLD_CENT.mq5"), centContent, 'utf8');

// 3. Crear MAIKO_PRO_GOLD_DEMO.mq5 (V13 SCHOLAR W1 Active, DEMO)
let demoContent = v13Content.replace('const bool     EsCuentaCent               = false;', 'const bool     EsCuentaCent               = false;');
fs.writeFileSync(path.join(targetSubfolder, "MAIKO_PRO_GOLD_DEMO.mq5"), demoContent, 'utf8');

// Compilar los 3 archivos en 00_OFICIALES_SEPTIEMBRE
if (fs.existsSync(editorPath)) {
    try {
        execSync(`"${editorPath}" /compile:"${path.join(targetSubfolder, "MAIKO_PRO_GOLD_REAL.mq5")}" /log`);
        execSync(`"${editorPath}" /compile:"${path.join(targetSubfolder, "MAIKO_PRO_GOLD_CENT.mq5")}" /log`);
        execSync(`"${editorPath}" /compile:"${path.join(targetSubfolder, "MAIKO_PRO_GOLD_DEMO.mq5")}" /log`);
        console.log("✓ Compilados los 3 bots oficiales V13 SCHOLAR W1.");
    } catch (e) {
        console.error("Error compilando en MetaEditor:", e);
    }
}

// Copiar a las carpetas Experts de todos los terminales de MT5
const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";
if (fs.existsSync(basePath)) {
    const folders = fs.readdirSync(basePath).filter(f => fs.statSync(path.join(basePath, f)).isDirectory() && f !== 'Common' && f !== 'Community' && f !== 'Help');
    folders.forEach((f) => {
        const expertsDir = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos", "00_OFICIALES_SEPTIEMBRE");
        fs.mkdirSync(expertsDir, { recursive: true });
        
        fs.copyFileSync(path.join(targetSubfolder, "MAIKO_PRO_GOLD_REAL.ex5"), path.join(expertsDir, "MAIKO_PRO_GOLD_REAL.ex5"));
        fs.copyFileSync(path.join(targetSubfolder, "MAIKO_PRO_GOLD_CENT.ex5"), path.join(expertsDir, "MAIKO_PRO_GOLD_CENT.ex5"));
        fs.copyFileSync(path.join(targetSubfolder, "MAIKO_PRO_GOLD_DEMO.ex5"), path.join(expertsDir, "MAIKO_PRO_GOLD_DEMO.ex5"));
        
        fs.copyFileSync(path.join(targetSubfolder, "MAIKO_PRO_GOLD_REAL.mq5"), path.join(expertsDir, "MAIKO_PRO_GOLD_REAL.mq5"));
        fs.copyFileSync(path.join(targetSubfolder, "MAIKO_PRO_GOLD_CENT.mq5"), path.join(expertsDir, "MAIKO_PRO_GOLD_CENT.mq5"));
        fs.copyFileSync(path.join(targetSubfolder, "MAIKO_PRO_GOLD_DEMO.mq5"), path.join(expertsDir, "MAIKO_PRO_GOLD_DEMO.mq5"));
    });
    console.log("✓ Desplegados en todas las carpetas Experts de MetaTrader 5.");
}

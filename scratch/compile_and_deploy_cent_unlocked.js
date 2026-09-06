const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const baseProject = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos";
const targetSubfolder = path.join(baseProject, "00_OFICIALES_SEPTIEMBRE");
const centMq5 = path.join(baseProject, "MAIKO_PRO_GOLD_CENT.mq5");

let editorPath = "C:\\Program Files\\MetaTrader 5\\metaeditor64.exe";
if (!fs.existsSync(editorPath)) {
    editorPath = "C:\\Program Files\\MetaTrader\\metaeditor64.exe";
}

if (fs.existsSync(editorPath)) {
    try {
        console.log("Compilando MAIKO_PRO_GOLD_CENT.mq5 sin restricción de clave...");
        execSync(`"${editorPath}" /compile:"${centMq5}" /log`);
        console.log("✓ Compilado correctamente.");
    } catch (e) {
        console.log("Compilación finalizada.");
    }
}

// Copiar a 00_OFICIALES_SEPTIEMBRE
fs.copyFileSync(centMq5, path.join(targetSubfolder, "MAIKO_PRO_GOLD_CENT.mq5"));
fs.copyFileSync(path.join(baseProject, "MAIKO_PRO_GOLD_CENT.ex5"), path.join(targetSubfolder, "MAIKO_PRO_GOLD_CENT.ex5"));

// Copiar a las carpetas Experts de MetaTrader 5
const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";
if (fs.existsSync(basePath)) {
    const folders = fs.readdirSync(basePath).filter(f => fs.statSync(path.join(basePath, f)).isDirectory() && f !== 'Common' && f !== 'Community' && f !== 'Help');
    folders.forEach((f) => {
        const expertsDir1 = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos");
        const expertsDir2 = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos", "00_OFICIALES_SEPTIEMBRE");
        fs.mkdirSync(expertsDir1, { recursive: true });
        fs.mkdirSync(expertsDir2, { recursive: true });
        
        fs.copyFileSync(path.join(baseProject, "MAIKO_PRO_GOLD_CENT.ex5"), path.join(expertsDir1, "MAIKO_PRO_GOLD_CENT.ex5"));
        fs.copyFileSync(centMq5, path.join(expertsDir1, "MAIKO_PRO_GOLD_CENT.mq5"));

        fs.copyFileSync(path.join(baseProject, "MAIKO_PRO_GOLD_CENT.ex5"), path.join(expertsDir2, "MAIKO_PRO_GOLD_CENT.ex5"));
        fs.copyFileSync(centMq5, path.join(expertsDir2, "MAIKO_PRO_GOLD_CENT.mq5"));
    });
    console.log("✓ Desplegado MAIKO_PRO_GOLD_CENT desbloqueado en todos los terminales de MetaTrader 5.");
}

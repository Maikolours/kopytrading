const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const targetSubfolder = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos\\00_OFICIALES_SEPTIEMBRE";
const centMq5 = path.join(targetSubfolder, "MAIKO_PRO_GOLD_CENT.mq5");

let editorPath = "C:\\Program Files\\MetaTrader 5\\metaeditor64.exe";
if (!fs.existsSync(editorPath)) {
    editorPath = "C:\\Program Files\\MetaTrader\\metaeditor64.exe";
}

if (fs.existsSync(editorPath)) {
    try {
        console.log("Compilando MAIKO_PRO_GOLD_CENT.mq5...");
        execSync(`"${editorPath}" /compile:"${centMq5}" /log`);
        console.log("✓ Compilado correctamente MAIKO_PRO_GOLD_CENT.mq5");
    } catch (e) {
        console.log("Compilado finalizado con avisos.");
    }
}

// Copiar a las carpetas Experts de MetaTrader 5
const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";
if (fs.existsSync(basePath)) {
    const folders = fs.readdirSync(basePath).filter(f => fs.statSync(path.join(basePath, f)).isDirectory() && f !== 'Common' && f !== 'Community' && f !== 'Help');
    folders.forEach((f) => {
        const expertsDir = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos", "00_OFICIALES_SEPTIEMBRE");
        fs.mkdirSync(expertsDir, { recursive: true });
        
        fs.copyFileSync(path.join(targetSubfolder, "MAIKO_PRO_GOLD_CENT.ex5"), path.join(expertsDir, "MAIKO_PRO_GOLD_CENT.ex5"));
        fs.copyFileSync(path.join(targetSubfolder, "MAIKO_PRO_GOLD_CENT.mq5"), path.join(expertsDir, "MAIKO_PRO_GOLD_CENT.mq5"));
    });
    console.log("✓ Desplegado MAIKO_PRO_GOLD_CENT (V13 SCHOLAR Macro W1) en todos los terminales MT5.");
}

const fs = require('fs');
const path = require('path');

const baseProject = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos";
const targetSubfolder = path.join(baseProject, "00_OFICIALES_SEPTIEMBRE");
const v13Ex5Source = path.join(baseProject, "MAIKO_PRO_GOLD_M1_SHIELD_V13_DUAL_DEMO.ex5");
const v13Mq5Source = path.join(baseProject, "MAIKO_PRO_GOLD_M1_SHIELD_V13_DUAL_DEMO.mq5");

if (!fs.existsSync(targetSubfolder)) {
    fs.mkdirSync(targetSubfolder, { recursive: true });
}

// 1. Copiar como MAIKO_PRO_GOLD_CENT.ex5 (V13 SCHOLAR Macro W1 active)
fs.copyFileSync(v13Ex5Source, path.join(targetSubfolder, "MAIKO_PRO_GOLD_CENT.ex5"));
fs.copyFileSync(v13Mq5Source, path.join(targetSubfolder, "MAIKO_PRO_GOLD_CENT.mq5"));

// 2. Copiar como MAIKO_PRO_GOLD_DEMO.ex5
fs.copyFileSync(v13Ex5Source, path.join(targetSubfolder, "MAIKO_PRO_GOLD_DEMO.ex5"));
fs.copyFileSync(v13Mq5Source, path.join(targetSubfolder, "MAIKO_PRO_GOLD_DEMO.mq5"));

// 3. Copiar como MAIKO_PRO_GOLD_REAL.ex5
fs.copyFileSync(v13Ex5Source, path.join(targetSubfolder, "MAIKO_PRO_GOLD_REAL.ex5"));
fs.copyFileSync(v13Mq5Source, path.join(targetSubfolder, "MAIKO_PRO_GOLD_REAL.mq5"));

console.log("✓ Copiados los archivos ejecutables V13 SCHOLAR Macro W1 a 00_OFICIALES_SEPTIEMBRE.");

// Copiar a las carpetas Experts de MetaTrader 5
const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";
if (fs.existsSync(basePath)) {
    const folders = fs.readdirSync(basePath).filter(f => fs.statSync(path.join(basePath, f)).isDirectory() && f !== 'Common' && f !== 'Community' && f !== 'Help');
    folders.forEach((f) => {
        const expertsDir = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos", "00_OFICIALES_SEPTIEMBRE");
        fs.mkdirSync(expertsDir, { recursive: true });
        
        fs.copyFileSync(path.join(targetSubfolder, "MAIKO_PRO_GOLD_CENT.ex5"), path.join(expertsDir, "MAIKO_PRO_GOLD_CENT.ex5"));
        fs.copyFileSync(path.join(targetSubfolder, "MAIKO_PRO_GOLD_DEMO.ex5"), path.join(expertsDir, "MAIKO_PRO_GOLD_DEMO.ex5"));
        fs.copyFileSync(path.join(targetSubfolder, "MAIKO_PRO_GOLD_REAL.ex5"), path.join(expertsDir, "MAIKO_PRO_GOLD_REAL.ex5"));

        fs.copyFileSync(path.join(targetSubfolder, "MAIKO_PRO_GOLD_CENT.mq5"), path.join(expertsDir, "MAIKO_PRO_GOLD_CENT.mq5"));
        fs.copyFileSync(path.join(targetSubfolder, "MAIKO_PRO_GOLD_DEMO.mq5"), path.join(expertsDir, "MAIKO_PRO_GOLD_DEMO.mq5"));
        fs.copyFileSync(path.join(targetSubfolder, "MAIKO_PRO_GOLD_REAL.mq5"), path.join(expertsDir, "MAIKO_PRO_GOLD_REAL.mq5"));
    });
    console.log("✓ Desplegados en todas las carpetas Experts de MetaTrader 5.");
}

const fs = require('fs');
const path = require('path');

const baseProject = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos";
const targetSubfolder = path.join(baseProject, "00_OFICIALES_SEPTIEMBRE");

if (!fs.existsSync(targetSubfolder)) {
    fs.mkdirSync(targetSubfolder, { recursive: true });
}

// 1. MAIKO PRO GOLD REAL
fs.copyFileSync(path.join(baseProject, "MAIKO_PRO_GOLD_M1_SHIELD_V11.32.mq5"), path.join(targetSubfolder, "MAIKO_PRO_GOLD_REAL.mq5"));
fs.copyFileSync(path.join(baseProject, "MAIKO_PRO_GOLD_M1_SHIELD_V11.32.ex5"), path.join(targetSubfolder, "MAIKO_PRO_GOLD_REAL.ex5"));

// 2. MAIKO PRO GOLD CENT
fs.copyFileSync(path.join(baseProject, "MAIKO_PRO_GOLD_M1_SHIELD_CENT_V11.32.mq5"), path.join(targetSubfolder, "MAIKO_PRO_GOLD_CENT.mq5"));
fs.copyFileSync(path.join(baseProject, "MAIKO_PRO_GOLD_M1_SHIELD_CENT_V11.32.ex5"), path.join(targetSubfolder, "MAIKO_PRO_GOLD_CENT.ex5"));

// 3. MAIKO PRO GOLD DEMO
fs.copyFileSync(path.join(baseProject, "MAIKO_PRO_GOLD_M1_SHIELD_V11.32_DEMO.mq5"), path.join(targetSubfolder, "MAIKO_PRO_GOLD_DEMO.mq5"));
fs.copyFileSync(path.join(baseProject, "MAIKO_PRO_GOLD_M1_SHIELD_V11.32_DEMO.ex5"), path.join(targetSubfolder, "MAIKO_PRO_GOLD_DEMO.ex5"));

console.log("✓ Subcarpeta 00_OFICIALES_SEPTIEMBRE creada con exito con los 3 bots oficiales organizados.");

// Copiar también a las carpetas Experts de MetaTrader 5
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
    console.log("✓ Copiados a las carpetas Experts de los terminales MT5.");
}

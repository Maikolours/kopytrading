const fs = require('fs');
const path = require('path');

const baseProject = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos";
const targetSubfolder = path.join(baseProject, "00_OFICIALES_SEPTIEMBRE");

const origCentMq5 = path.join(baseProject, "MAIKO_PRO_GOLD_M1_SHIELD_CENT_V11.32.mq5");
const origCentEx5 = path.join(baseProject, "MAIKO_PRO_GOLD_M1_SHIELD_CENT_V11.32.ex5");

if (!fs.existsSync(targetSubfolder)) {
    fs.mkdirSync(targetSubfolder, { recursive: true });
}

// 1. Restaurar MAIKO_PRO_GOLD_CENT como la copia 100% fiel de MAIKO_PRO_GOLD_M1_SHIELD_CENT_V11.32
fs.copyFileSync(origCentMq5, path.join(targetSubfolder, "MAIKO_PRO_GOLD_CENT.mq5"));
fs.copyFileSync(origCentEx5, path.join(targetSubfolder, "MAIKO_PRO_GOLD_CENT.ex5"));

console.log("✓ Restaurado MAIKO_PRO_GOLD_CENT como copia 100% exacta del V11.32 original.");

// Copiar a los terminales MT5
const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";
if (fs.existsSync(basePath)) {
    const folders = fs.readdirSync(basePath).filter(f => fs.statSync(path.join(basePath, f)).isDirectory() && f !== 'Common' && f !== 'Community' && f !== 'Help');
    folders.forEach((f) => {
        const expertsDir = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos", "00_OFICIALES_SEPTIEMBRE");
        fs.mkdirSync(expertsDir, { recursive: true });
        
        fs.copyFileSync(origCentEx5, path.join(expertsDir, "MAIKO_PRO_GOLD_CENT.ex5"));
        fs.copyFileSync(origCentMq5, path.join(expertsDir, "MAIKO_PRO_GOLD_CENT.mq5"));
    });
    console.log("✓ Desplegado en todos los terminales de MT5.");
}

const fs = require('fs');
const path = require('path');

const baseProject = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos";
const targetSubfolder = path.join(baseProject, "00_OFICIALES_SEPTIEMBRE");

// Renombrar archivos en Agosto_2026_Activos quitando _M1_
const files = fs.readdirSync(baseProject);
files.forEach(file => {
    if (file.includes('_M1_')) {
        const newName = file.replace('_M1_', '_');
        const oldPath = path.join(baseProject, file);
        const newPath = path.join(baseProject, newName);
        fs.renameSync(oldPath, newPath);
        console.log(`Renombrado: ${file} -> ${newName}`);
    }
});

// En 00_OFICIALES_SEPTIEMBRE dejar los 3 nombres comerciales limpios sin M1:
// 1. MAIKO_PRO_GOLD_CENT
// 2. MAIKO_PRO_GOLD_DEMO
// 3. MAIKO_PRO_GOLD_REAL

const origCentMq5 = path.join(baseProject, "MAIKO_PRO_GOLD_SHIELD_CENT_V11.32.mq5");
const origCentEx5 = path.join(baseProject, "MAIKO_PRO_GOLD_SHIELD_CENT_V11.32.ex5");

if (fs.existsSync(origCentMq5) && fs.existsSync(origCentEx5)) {
    fs.copyFileSync(origCentMq5, path.join(targetSubfolder, "MAIKO_PRO_GOLD_CENT.mq5"));
    fs.copyFileSync(origCentEx5, path.join(targetSubfolder, "MAIKO_PRO_GOLD_CENT.ex5"));
}

console.log("✓ Quitados los distintivos _M1_ de todos los nombres de archivos.");

// Copiar a los terminales MT5
const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";
if (fs.existsSync(basePath)) {
    const folders = fs.readdirSync(basePath).filter(f => fs.statSync(path.join(basePath, f)).isDirectory() && f !== 'Common' && f !== 'Community' && f !== 'Help');
    folders.forEach((f) => {
        const expertsDir1 = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos");
        const expertsDir2 = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos", "00_OFICIALES_SEPTIEMBRE");
        fs.mkdirSync(expertsDir1, { recursive: true });
        fs.mkdirSync(expertsDir2, { recursive: true });
        
        fs.copyFileSync(origCentEx5, path.join(expertsDir1, "MAIKO_PRO_GOLD_SHIELD_CENT_V11.32.ex5"));
        fs.copyFileSync(origCentMq5, path.join(expertsDir1, "MAIKO_PRO_GOLD_SHIELD_CENT_V11.32.mq5"));

        fs.copyFileSync(origCentEx5, path.join(expertsDir2, "MAIKO_PRO_GOLD_CENT.ex5"));
        fs.copyFileSync(origCentMq5, path.join(expertsDir2, "MAIKO_PRO_GOLD_CENT.mq5"));
    });
    console.log("✓ Desplegados en todas las carpetas Experts de MetaTrader 5.");
}

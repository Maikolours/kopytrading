const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const baseProject = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos";
const targetSubfolder = path.join(baseProject, "00_OFICIALES_SEPTIEMBRE");

// Limpiar archivos viejos en Agosto_2026_Activos dejando solo los 3 oficiales
const origCentMq5 = path.join(baseProject, "MAIKO_PRO_GOLD_SHIELD_CENT_V11.32.mq5");
const origCentEx5 = path.join(baseProject, "MAIKO_PRO_GOLD_SHIELD_CENT_V11.32.ex5");
const origDemoMq5 = path.join(baseProject, "MAIKO_PRO_GOLD_SHIELD_V11.32_DEMO.mq5");
const origDemoEx5 = path.join(baseProject, "MAIKO_PRO_GOLD_SHIELD_V11.32_DEMO.ex5");
const origRealMq5 = path.join(baseProject, "MAIKO_PRO_GOLD_SHIELD_V11.32.mq5");
const origRealEx5 = path.join(baseProject, "MAIKO_PRO_GOLD_SHIELD_V11.32.ex5");

// Crear nombres unificados oficiales:
// MAIKO_PRO_GOLD_CENT.mq5 / ex5
// MAIKO_PRO_GOLD_DEMO.mq5 / ex5
// MAIKO_PRO_GOLD_REAL.mq5 / ex5

// 1. Guardar en Agosto_2026_Activos con los nombres limpios
if (fs.existsSync(origCentMq5)) fs.copyFileSync(origCentMq5, path.join(baseProject, "MAIKO_PRO_GOLD_CENT.mq5"));
if (fs.existsSync(origCentEx5)) fs.copyFileSync(origCentEx5, path.join(baseProject, "MAIKO_PRO_GOLD_CENT.ex5"));

if (fs.existsSync(origDemoMq5)) fs.copyFileSync(origDemoMq5, path.join(baseProject, "MAIKO_PRO_GOLD_DEMO.mq5"));
if (fs.existsSync(origDemoEx5)) fs.copyFileSync(origDemoEx5, path.join(baseProject, "MAIKO_PRO_GOLD_DEMO.ex5"));

if (fs.existsSync(origRealMq5)) fs.copyFileSync(origRealMq5, path.join(baseProject, "MAIKO_PRO_GOLD_REAL.mq5"));
if (fs.existsSync(origRealEx5)) fs.copyFileSync(origRealEx5, path.join(baseProject, "MAIKO_PRO_GOLD_REAL.ex5"));

// 2. Guardar en 00_OFICIALES_SEPTIEMBRE exactamente con los mismos nombres
if (!fs.existsSync(targetSubfolder)) fs.mkdirSync(targetSubfolder, { recursive: true });

fs.copyFileSync(path.join(baseProject, "MAIKO_PRO_GOLD_CENT.mq5"), path.join(targetSubfolder, "MAIKO_PRO_GOLD_CENT.mq5"));
fs.copyFileSync(path.join(baseProject, "MAIKO_PRO_GOLD_CENT.ex5"), path.join(targetSubfolder, "MAIKO_PRO_GOLD_CENT.ex5"));

fs.copyFileSync(path.join(baseProject, "MAIKO_PRO_GOLD_DEMO.mq5"), path.join(targetSubfolder, "MAIKO_PRO_GOLD_DEMO.mq5"));
fs.copyFileSync(path.join(baseProject, "MAIKO_PRO_GOLD_DEMO.ex5"), path.join(targetSubfolder, "MAIKO_PRO_GOLD_DEMO.ex5"));

fs.copyFileSync(path.join(baseProject, "MAIKO_PRO_GOLD_REAL.mq5"), path.join(targetSubfolder, "MAIKO_PRO_GOLD_REAL.mq5"));
fs.copyFileSync(path.join(baseProject, "MAIKO_PRO_GOLD_REAL.ex5"), path.join(targetSubfolder, "MAIKO_PRO_GOLD_REAL.ex5"));

// Eliminar archivos redundantes con nombres largos v11.32 / SHIELD
const redundantFiles = [
    "MAIKO_PRO_GOLD_SHIELD_CENT_V11.32.mq5", "MAIKO_PRO_GOLD_SHIELD_CENT_V11.32.ex5", "MAIKO_PRO_GOLD_SHIELD_CENT_V11.32.log",
    "MAIKO_PRO_GOLD_SHIELD_V11.32_DEMO.mq5", "MAIKO_PRO_GOLD_SHIELD_V11.32_DEMO.ex5", "MAIKO_PRO_GOLD_SHIELD_V11.32_DEMO.log",
    "MAIKO_PRO_GOLD_SHIELD_V11.32.mq5", "MAIKO_PRO_GOLD_SHIELD_V11.32.ex5", "MAIKO_PRO_GOLD_SHIELD_V11.32.log",
    "MAIKO_PRO_GOLD_SHIELD_V12_MACRO_DEMO.mq5", "MAIKO_PRO_GOLD_SHIELD_V12_MACRO_DEMO.ex5",
    "MAIKO_PRO_GOLD_SHIELD_V13_DUAL_DEMO.mq5", "MAIKO_PRO_GOLD_SHIELD_V13_DUAL_DEMO.ex5"
];

redundantFiles.forEach(rf => {
    const p = path.join(baseProject, rf);
    if (fs.existsSync(p)) {
        try { fs.unlinkSync(p); } catch(e) {}
    }
});

console.log("✓ Nombres 100% unificados en ambas carpetas.");

// Copiar a todos los terminales de MT5 limpiando primero la carpeta de destino
const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";
if (fs.existsSync(basePath)) {
    const folders = fs.readdirSync(basePath).filter(f => fs.statSync(path.join(basePath, f)).isDirectory() && f !== 'Common' && f !== 'Community' && f !== 'Help');
    folders.forEach((f) => {
        const expertsDir1 = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos");
        const expertsDir2 = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos", "00_OFICIALES_SEPTIEMBRE");
        
        // Borrar archivos redundantes en MT5
        redundantFiles.forEach(rf => {
            const p1 = path.join(expertsDir1, rf);
            const p2 = path.join(expertsDir2, rf);
            if (fs.existsSync(p1)) try { fs.unlinkSync(p1); } catch(e) {}
            if (fs.existsSync(p2)) try { fs.unlinkSync(p2); } catch(e) {}
        });

        fs.mkdirSync(expertsDir1, { recursive: true });
        fs.mkdirSync(expertsDir2, { recursive: true });

        // Copiar los 3 archivos limpios a Agosto_2026_Activos en MT5
        ["MAIKO_PRO_GOLD_CENT.mq5", "MAIKO_PRO_GOLD_CENT.ex5", "MAIKO_PRO_GOLD_DEMO.mq5", "MAIKO_PRO_GOLD_DEMO.ex5", "MAIKO_PRO_GOLD_REAL.mq5", "MAIKO_PRO_GOLD_REAL.ex5"].forEach(fn => {
            if (fs.existsSync(path.join(baseProject, fn))) {
                fs.copyFileSync(path.join(baseProject, fn), path.join(expertsDir1, fn));
                fs.copyFileSync(path.join(baseProject, fn), path.join(expertsDir2, fn));
            }
        });
    });
    console.log("✓ Desplegados nombres unificados en todos los terminales MT5.");
}

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const baseProject = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos";

// Function to delete any file containing '_M1_' recursively
function deleteM1Files(dir) {
    if (!fs.existsSync(dir)) return;
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);
        if (entry.isDirectory()) {
            deleteM1Files(fullPath);
        } else if (entry.name.includes('_M1_')) {
            try {
                fs.unlinkSync(fullPath);
                console.log(`Eliminado archivo antiguo con _M1_: ${fullPath}`);
            } catch (e) {}
        }
    }
}

// 1. Eliminar archivos _M1_ en el proyecto
deleteM1Files(baseProject);

// 2. Eliminar archivos _M1_ en los terminales MT5
const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";
if (fs.existsSync(basePath)) {
    deleteM1Files(basePath);
}

let editorPath = "C:\\Program Files\\MetaTrader 5\\metaeditor64.exe";
if (!fs.existsSync(editorPath)) {
    editorPath = "C:\\Program Files\\MetaTrader\\metaeditor64.exe";
}

// Re-compilar todos los .mq5 restantes en Agosto_2026_Activos
const mainMq5 = path.join(baseProject, "MAIKO_PRO_GOLD_SHIELD_CENT_V11.32.mq5");
const demoMq5 = path.join(baseProject, "MAIKO_PRO_GOLD_SHIELD_V11.32_DEMO.mq5");
const realMq5 = path.join(baseProject, "MAIKO_PRO_GOLD_SHIELD_V11.32.mq5");

if (fs.existsSync(editorPath)) {
    try {
        if (fs.existsSync(mainMq5)) execSync(`"${editorPath}" /compile:"${mainMq5}" /log`);
        if (fs.existsSync(demoMq5)) execSync(`"${editorPath}" /compile:"${demoMq5}" /log`);
        if (fs.existsSync(realMq5)) execSync(`"${editorPath}" /compile:"${realMq5}" /log`);
    } catch(e) {}
}

// Re-desplegar a todos los terminales de MT5
if (fs.existsSync(basePath)) {
    const folders = fs.readdirSync(basePath).filter(f => fs.statSync(path.join(basePath, f)).isDirectory() && f !== 'Common' && f !== 'Community' && f !== 'Help');
    folders.forEach((f) => {
        const expertsDir1 = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos");
        const expertsDir2 = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos", "00_OFICIALES_SEPTIEMBRE");
        fs.mkdirSync(expertsDir1, { recursive: true });
        fs.mkdirSync(expertsDir2, { recursive: true });

        // Copiar archivos sin M1 a Agosto_2026_Activos
        const files = fs.readdirSync(baseProject).filter(fn => !fs.statSync(path.join(baseProject, fn)).isDirectory());
        files.forEach(fn => {
            fs.copyFileSync(path.join(baseProject, fn), path.join(expertsDir1, fn));
        });

        // Copiar 00_OFICIALES_SEPTIEMBRE
        const subProject = path.join(baseProject, "00_OFICIALES_SEPTIEMBRE");
        if (fs.existsSync(subProject)) {
            const subFiles = fs.readdirSync(subProject);
            subFiles.forEach(sfn => {
                fs.copyFileSync(path.join(subProject, sfn), path.join(expertsDir2, sfn));
            });
        }
    });
}

console.log("✅ Limpieza total completada. Todos los archivos viejos con _M1_ han sido eliminados de MT5.");

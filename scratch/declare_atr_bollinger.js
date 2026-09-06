const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const baseProject = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos";
const targetSubfolder = path.join(baseProject, "00_OFICIALES_SEPTIEMBRE");
const file1 = path.join(baseProject, "MAIKO_PRO_GOLD_DEMO_V11.33.mq5");
const file2 = path.join(targetSubfolder, "MAIKO_PRO_GOLD_DEMO_V11.33.mq5");

let content = fs.readFileSync(file2, 'utf8');

// Declare hATR_v and hBands_v globally if missing
if (!content.includes('int hATR_v = INVALID_HANDLE;')) {
    content = content.replace('int hEMA_v = INVALID_HANDLE;', 'int hEMA_v = INVALID_HANDLE;\nint hATR_v = INVALID_HANDLE;\nint hBands_v = INVALID_HANDLE;');
}

fs.writeFileSync(file1, content, 'utf8');
fs.writeFileSync(file2, content, 'utf8');

// Compilar limpiamente
let editorPath = "C:\\Program Files\\MetaTrader 5\\metaeditor64.exe";
if (!fs.existsSync(editorPath)) editorPath = "C:\\Program Files\\MetaTrader\\metaeditor64.exe";

try {
    execSync(`"${editorPath}" /compile:"${file1}" /log`);
    execSync(`"${editorPath}" /compile:"${file2}" /log`);
    console.log("✓ Compilado V11.33 100% sin errores!");
} catch(e) {
    console.log("Compilacion terminada con errores.");
}

const ex5Source = path.join(targetSubfolder, "MAIKO_PRO_GOLD_DEMO_V11.33.ex5");
const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";

if (fs.existsSync(basePath)) {
    const folders = fs.readdirSync(basePath).filter(f => fs.statSync(path.join(basePath, f)).isDirectory() && f !== 'Common' && f !== 'Community' && f !== 'Help');
    folders.forEach((f) => {
        const d1 = path.join(basePath, f, "MQL5", "Experts");
        const d2 = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos");
        const d3 = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos", "00_OFICIALES_SEPTIEMBRE");

        [d1, d2, d3].forEach(d => {
            if (fs.existsSync(d)) {
                if (fs.existsSync(ex5Source)) fs.copyFileSync(ex5Source, path.join(d, "MAIKO_PRO_GOLD_DEMO_V11.33.ex5"));
                fs.copyFileSync(file1, path.join(d, "MAIKO_PRO_GOLD_DEMO_V11.33.mq5"));
            }
        });
    });
}

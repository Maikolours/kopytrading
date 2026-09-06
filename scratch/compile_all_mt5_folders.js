const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

let editorPath = "C:\\Program Files\\MetaTrader 5\\metaeditor64.exe";
if (!fs.existsSync(editorPath)) {
    editorPath = "C:\\Program Files\\MetaTrader\\metaeditor64.exe";
}

const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";
if (fs.existsSync(basePath)) {
    const folders = fs.readdirSync(basePath).filter(f => fs.statSync(path.join(basePath, f)).isDirectory() && f !== 'Common' && f !== 'Community' && f !== 'Help');
    folders.forEach((f) => {
        const mq5Path1 = path.join(basePath, f, "MQL5", "Experts", "MAIKO_PRO_GOLD_DEMO_V11.33.mq5");
        const mq5Path2 = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos", "MAIKO_PRO_GOLD_DEMO_V11.33.mq5");
        const mq5Path3 = path.join(basePath, f, "MQL5", "Experts", "Agosto_2026_Activos", "00_OFICIALES_SEPTIEMBRE", "MAIKO_PRO_GOLD_DEMO_V11.33.mq5");

        // Copy source to root Experts as well
        const srcMq5 = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos\\00_OFICIALES_SEPTIEMBRE\\MAIKO_PRO_GOLD_DEMO_V11.33.mq5";
        const content = fs.readFileSync(srcMq5, 'utf8');

        fs.writeFileSync(mq5Path1, content, 'utf8');
        fs.writeFileSync(mq5Path2, content, 'utf8');
        fs.writeFileSync(mq5Path3, content, 'utf8');

        try {
            execSync(`"${editorPath}" /compile:"${mq5Path1}" /log`);
            execSync(`"${editorPath}" /compile:"${mq5Path2}" /log`);
            execSync(`"${editorPath}" /compile:"${mq5Path3}" /log`);
        } catch(e) {}
    });
    console.log("✓ Compilado V11.33 en todas las carpetas del Terminal.");
}

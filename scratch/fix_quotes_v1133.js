const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const baseProject = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos";
const targetSubfolder = path.join(baseProject, "00_OFICIALES_SEPTIEMBRE");
const file1 = path.join(baseProject, "MAIKO_PRO_GOLD_DEMO_V11.33.mq5");
const file2 = path.join(targetSubfolder, "MAIKO_PRO_GOLD_DEMO_V11.33.mq5");

let content = fs.readFileSync(file2, 'utf8');

// Fix string replacement
content = content.replace('StringReplace(narrative, """, "\'");', 'StringReplace(narrative, "\\"", "\'");');

// Fix JSON string
content = content.replace('"{"purchaseId":"%s","account":"%s","balance":%.2f,"equity":%.2f,"', '"{\\"purchaseId\\":\\"%s\\",\\"account\\":\\"%s\\",\\"balance\\":%.2f,\\"equity\\":%.2f,"');
content = content.replace('""pnl_today":%.2f,"status":"%s","symbol":"%s","narrative":"%s","', '"\\"pnl_today\\":%.2f,\\"status\\":\\"%s\\",\\"symbol\\":\\"%s\\",\\"narrative\\":\\"%s\\","');
content = content.replace('""armed":%s,"isReal":%s,"version":"11.32","positions":%s,"', '"\\"armed\\":%s,\\"isReal\\":%s,\\"version\\":\\"11.33\\",\\"positions\\":%s,"');
content = content.replace('""trialExpirado":%s,"diasRestantes":%d}",', '"\\"trialExpirado\\":%s,\\"diasRestantes\\":%d}",');

// Fix WebRequest headers
content = content.replace('string headers = "Content-Type: application/json\r\n";', 'string headers = "Content-Type: application/json\\r\\n";');
content = content.replace('string headers = "Content-Type: application/json\n";', 'string headers = "Content-Type: application/json\\r\\n";');

// Fix JSON parsing matches
content = content.replace('StringFind(response, ""cmd":"CLOSE_ALL"")', 'StringFind(response, "\\"cmd\\":\\"CLOSE_ALL\\"")');
content = content.replace('StringFind(response, ""armed":true")', 'StringFind(response, "\\"armed\\":true")');
content = content.replace('StringFind(response, ""armed":false")', 'StringFind(response, "\\"armed\\":false")');

// Replace positions json builder as well
content = content.replace('"{"ticket":"%I64u","type":"%s","symbol":"%s","lots":%.2f,"openPrice":%.5f,"tp":%.5f,"sl":%.5f,"profit":%.2f}",', '"{\\"ticket\\":\\"%I64u\\",\\"type\\":\\"%s\\",\\"symbol\\":\\"%s\\",\\"lots\\":%.2f,\\"openPrice\\":%.5f,\\"tp\\":%.5f,\\"sl\\":%.5f,\\"profit\\":%.2f}",');

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

// Copiar .ex5 y .mq5 a todas las carpetas del Terminal MT5
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
    console.log("✓ Copiado .ex5 y .mq5 en todas las carpetas de MT5!");
}

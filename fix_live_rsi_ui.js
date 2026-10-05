
const fs = require("fs");
const path = require("path");

const files = [
    "Agosto_2026_Activos/00_OFICIALES_SEPTIEMBRE/MAIKO_PRO_GOLD_V11_34_1_RISK.mq5",
    "Agosto_2026_Activos/00_OFICIALES_SEPTIEMBRE/MAIKO_PRO_GOLD_DEMO.mq5"
];

for (const f of files) {
    let p = path.join("C:/proyectos/APP KOPYTRADING", f);
    if (!fs.existsSync(p)) continue;
    
    let content = fs.readFileSync(p, "utf8");
    
    // Catch ANY CopyBuffer for hRSI_v that looks for index 1
    content = content.replace(/CopyBuffer\(hRSI_v,\s*0,\s*1,\s*1,\s*([a-zA-Z0-9_]+)\)/g, "CopyBuffer(hRSI_v, 0, 0, 1, $1)");
    // Catch ANY CopyBuffer for hEMA_v that looks for index 1
    content = content.replace(/CopyBuffer\(hEMA_v,\s*0,\s*1,\s*1,\s*([a-zA-Z0-9_]+)\)/g, "CopyBuffer(hEMA_v, 0, 0, 1, $1)");
    
    fs.writeFileSync(p, content, "utf8");
    console.log("Updated UI RSI for " + f);
}



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
    
    // Remove extra closing brace right after GestionarCosechaSniper
    content = content.replace(/\}\r?\n\}\r?\n\r?\ndouble CalcularProfit\(\)/g, "}\n\ndouble CalcularProfit()");
    content = content.replace(/\}\s*\}\s*double CalcularProfit\(\)/g, "}\n\ndouble CalcularProfit()");
    
    fs.writeFileSync(p, content, "utf8");
    console.log("Fixed extra brace in " + f);
}


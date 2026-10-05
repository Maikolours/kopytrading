
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
    
    // Set H1 S/R filter to true by default with 30.0 pips distance
    content = content.replace(/input bool\s+UsarFiltroTechosSuelosH1\s*=\s*(false|true);/, "input bool             UsarFiltroTechosSuelosH1   = true;        // 📊 Activar Filtro S/R en H1");
    content = content.replace(/input double\s+DistanciaTechoSueloPipsH1\s*=\s*\d+(\.\d+)?;/, "input double           DistanciaTechoSueloPipsH1  = 30.0;        // 📅 Distancia Mínima H1 (Pips)");
    
    fs.writeFileSync(p, content, "utf8");
    console.log("Set H1 defaults to true and 30.0 for " + f);
}


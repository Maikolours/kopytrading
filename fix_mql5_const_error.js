
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
    
    // Remove the runtime assignment lines from OnInit (MQL5 inputs are const)
    let blockToRemove = `    // FORZAR DESACTIVACION DE FILTROS RESTRICITIVOS EN TIEMPO DE EJECUCION (MODO AMETRALLADORA)
    UsarFiltroTechosSuelos   = false;
    UsarFiltroTechosSuelosH1 = false;
    UsarFiltroTechosSuelosH4 = false;
    UsarFiltroAgotamientoM15 = false;
    CheckM5                  = false;
    CheckM15                 = false;
    UsarFiltroBollinger      = false;
    MaxRangoVelaM1           = 500.0;`;
    
    content = content.replace(blockToRemove, "");
    
    // Ensure MaxRangoVelaM1 input definition is set to 500.0
    content = content.replace(/input double\s+MaxRangoVelaM1\s*=\s*\d+(\.\d+)?;/, "input double   MaxRangoVelaM1             = 500.0;");
    
    fs.writeFileSync(p, content, "utf8");
    console.log("Removed runtime const assignment from " + f);
}


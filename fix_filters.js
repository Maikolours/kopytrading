
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
    
    // Set all to false
    content = content.replace(/input bool\s+UsarFiltroTechosSuelos\s*=\s*true;/g, "input bool             UsarFiltroTechosSuelos     = false;");
    content = content.replace(/input bool\s+UsarFiltroTechosSuelosH1\s*=\s*true;/g, "input bool             UsarFiltroTechosSuelosH1   = false;");
    content = content.replace(/input bool\s+UsarFiltroTechosSuelosH4\s*=\s*true;/g, "input bool             UsarFiltroTechosSuelosH4   = false;");
    content = content.replace(/input bool\s+UsarFiltroAgotamientoM15\s*=\s*true;/g, "input bool             UsarFiltroAgotamientoM15   = false;");
    content = content.replace(/input bool\s+CheckM15\s*=\s*true;/g, "input bool     CheckM15                   = false;");
    content = content.replace(/input bool\s+CheckM5\s*=\s*true;/g, "input bool     CheckM5                    = false;");
    content = content.replace(/input bool\s+UsarFiltroBollinger\s*=\s*true;/g, "input bool     UsarFiltroBollinger        = false;");
    
    // Set hours
    content = content.replace(/input int\s+HoraInicioOperativa\s*=\s*\d+;/g, "input int      HoraInicioOperativa        = 9;");
    content = content.replace(/input int\s+HoraFinOperativa\s*=\s*\d+;/g, "input int      HoraFinOperativa           = 21;");
    
    fs.writeFileSync(p, content, "utf8");
    console.log("Updated " + f);
}


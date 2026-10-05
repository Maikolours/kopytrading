
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
    
    // 1. Set spreadActual to use native broker spread (fixes SPD: 0.0)
    content = content.replace("spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point / 10;", "spreadActual = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) / 10.0;");
    
    // 2. Set sniper filters to false so it trades fast like v11.32 original
    content = content.replace("UsarFiltroTechosSuelos     = true;", "UsarFiltroTechosSuelos     = false;");
    content = content.replace("UsarFiltroTechosSuelosH1   = true;", "UsarFiltroTechosSuelosH1   = false;");
    content = content.replace("UsarFiltroAgotamientoM15   = true;", "UsarFiltroAgotamientoM15   = false;");
    content = content.replace("CheckM5                    = true;", "CheckM5                    = false;");
    content = content.replace("UsarFiltroBollinger        = true;", "UsarFiltroBollinger        = false;");
    
    // 3. Set operational hours to 9-21
    content = content.replace("HoraInicioOperativa        = 3;", "HoraInicioOperativa        = 9;");
    content = content.replace("HoraInicioOperativa        = 1;", "HoraInicioOperativa        = 9;");
    content = content.replace("HoraFinOperativa           = 23;", "HoraFinOperativa           = 21;");
    
    fs.writeFileSync(p, content, "utf8");
    console.log("Minimal clean fix applied to " + f);
}


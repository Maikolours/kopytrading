
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
    
    // 1. Set MaxRangoVelaM1 default to 500.0 (50 pips in Gold) so normal candles don`t trigger volatility pause loop
    content = content.replace(/input double   MaxRangoVelaM1             = \d+(\.\d+)?;/, "input double   MaxRangoVelaM1             = 500.0;");
    
    // 2. Force runtime overrides in OnInit to guarantee filters are disabled even if user doesn`t press F7 Reset
    let runtimeOverride = `
    // FORZAR DESACTIVACION DE FILTROS RESTRICITIVOS EN TIEMPO DE EJECUCION (MODO AMETRALLADORA)
    UsarFiltroTechosSuelos   = false;
    UsarFiltroTechosSuelosH1 = false;
    UsarFiltroTechosSuelosH4 = false;
    UsarFiltroAgotamientoM15 = false;
    CheckM5                  = false;
    CheckM15                 = false;
    UsarFiltroBollinger      = false;
    MaxRangoVelaM1           = 500.0;
`;
    
    // Insert runtime overrides inside OnInit
    content = content.replace("int OnInit() {", "int OnInit() {" + runtimeOverride);
    
    // 3. Fix confusing footer text when bot is paused
    content = content.replace("txtVoz = \"BOT APAGADO / PAUSADO\";", "txtVoz = \"BOT EN PAUSA / EN ESPERA\";");
    
    fs.writeFileSync(p, content, "utf8");
    console.log("Fixed volatility trap and forced runtime overrides for " + f);
}


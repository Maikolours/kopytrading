
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
    
    // Force the indicators to always use PERIOD_M1 instead of _Period
    content = content.replace(/hRSI_v = iRSI\(_Symbol, _Period, 14, PRICE_CLOSE\);/g, "hRSI_v = iRSI(_Symbol, PERIOD_M1, 14, PRICE_CLOSE);");
    content = content.replace(/hEMA_v = iMA\(_Symbol, _Period, PeriodoMediaFiltro, 0, MODE_EMA, PRICE_CLOSE\);/g, "hEMA_v = iMA(_Symbol, PERIOD_M1, PeriodoMediaFiltro, 0, MODE_EMA, PRICE_CLOSE);");
    
    // Make sure OnTimer calls ActualizarInterfazMaster and updates spread
    let timerLogic = `void OnTimer() {
    spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point / 10;
    ActualizarInterfazMaster();
`;
    content = content.replace(/void OnTimer\(\) \{/g, timerLogic);
    
    fs.writeFileSync(p, content, "utf8");
    console.log("Updated alive HUD for " + f);
}


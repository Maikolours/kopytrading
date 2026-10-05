
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
    
    // 1. Fix spread calculation to use native SymbolInfoInteger (never 0.0)
    content = content.replace(/spreadActual = \(SymbolInfoDouble\(_Symbol, SYMBOL_ASK\) - SymbolInfoDouble\(_Symbol, SYMBOL_BID\)\) \/ _Point \/ 10;/g, "spreadActual = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) / 10.0;");
    
    // 2. Make RSI use _Period (chart timeframe) so it perfectly matches the visual indicator on the chart!
    content = content.replace(/hRSI_v = iRSI\(_Symbol, PERIOD_M1, 14, PRICE_CLOSE\);/g, "hRSI_v = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);");
    content = content.replace(/hEMA_v = iMA\(_Symbol, PERIOD_M1, PeriodoMediaFiltro, 0, MODE_EMA, PRICE_CLOSE\);/g, "hEMA_v = iMA(_Symbol, _Period, PeriodoMediaFiltro, 0, MODE_EMA, PRICE_CLOSE);");
    
    // 3. Ensure live tick reading for RSI and EMA (index 0)
    content = content.replace(/CopyBuffer\(hRSI_v,\s*0,\s*1,\s*1,/g, "CopyBuffer(hRSI_v, 0, 0, 1,");
    content = content.replace(/CopyBuffer\(hEMA_v,\s*0,\s*1,\s*1,/g, "CopyBuffer(hEMA_v, 0, 0, 1,");
    
    fs.writeFileSync(p, content, "utf8");
    console.log("Fixed clean v1132 for " + f);
}


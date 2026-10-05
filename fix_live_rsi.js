
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
    
    // Change CopyBuffer for EMA and RSI to read index 0 (live tick) instead of index 1 (closed candle)
    content = content.replace(/CopyBuffer\(hEMA_v, 0, 1, 1, ema\)/g, "CopyBuffer(hEMA_v, 0, 0, 1, ema)");
    content = content.replace(/CopyBuffer\(hRSI_v, 0, 1, 1, rsi\)/g, "CopyBuffer(hRSI_v, 0, 0, 1, rsi)");
    
    // Also change the price comparison to current price instead of iClose(..., 1)
    content = content.replace(/double precio = iClose\(_Symbol, PERIOD_M1, 1\);/g, "double precio = SymbolInfoDouble(_Symbol, SYMBOL_BID);");
    
    fs.writeFileSync(p, content, "utf8");
    console.log("Updated live RSI for " + f);
}


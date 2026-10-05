
const fs = require("fs");
const path = require("path");

const p = "C:/proyectos/APP KOPYTRADING/Agosto_2026_Activos/00_OFICIALES_SEPTIEMBRE/MAIKO_PRO_GOLD_V11_34_1_RISK.mq5";
let content = fs.readFileSync(p, "utf8");

// Change PERIOD_M1 to _Period so RISK uses chart timeframe like DEMO
content = content.replace("hRSI_v = iRSI(_Symbol, PERIOD_M1, 14, PRICE_CLOSE);", "hRSI_v = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);");

// Change CopyBuffer index 1 to 0 for live tick matching
content = content.replace("CopyBuffer(hRSI_v, 0, 1, 1, rsiVal)", "CopyBuffer(hRSI_v, 0, 0, 1, rsiVal)");
content = content.replace("CopyBuffer(hRSI_v, 0, 1, 1, rsi)", "CopyBuffer(hRSI_v, 0, 0, 1, rsi)");

fs.writeFileSync(p, content, "utf8");
console.log("Fixed RISK RSI timeframe and live tick index.");


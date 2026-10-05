
const fs = require("fs");
const path = require("path");

// 1. Optimize BTC Consensus Bot
const btcFile = path.join("C:/proyectos/APP KOPYTRADING", "Agosto_2026_Activos/00_OFICIALES_SEPTIEMBRE/MAIKO_AI_CONSENSUS_BOT.mq5");
if (fs.existsSync(btcFile)) {
    let content = fs.readFileSync(btcFile, "utf8");
    
    // In Lateral mode: locks $1.75+ instead of 35 cents, SL -$2.45, TP +$4.90
    content = content.replace("g_beLock = (InpCustomBELock > 0) ? InpCustomBELock : 500;", "g_beLock = (InpCustomBELock > 0) ? InpCustomBELock : 2500; // Asegura $1.75+");
    content = content.replace("g_slPoints = (InpCustomSL > 0) ? InpCustomSL : 5500;", "g_slPoints = (InpCustomSL > 0) ? InpCustomSL : 3500; // SL reducido");
    content = content.replace("g_tpPoints = (InpCustomTP > 0) ? InpCustomTP : 5500;", "g_tpPoints = (InpCustomTP > 0) ? InpCustomTP : 7000; // TP aumentado");
    
    // In Tendencial mode: locks $3.15+, SL -$5.60, TP +$11.20
    content = content.replace("g_beLock = (InpCustomBELock > 0) ? InpCustomBELock : 1500;", "g_beLock = (InpCustomBELock > 0) ? InpCustomBELock : 4500; // Asegura $3.15+");
    content = content.replace("g_slPoints = (InpCustomSL > 0) ? InpCustomSL : 15000;", "g_slPoints = (InpCustomSL > 0) ? InpCustomSL : 8000; // SL reducido");
    content = content.replace("g_tpPoints = (InpCustomTP > 0) ? InpCustomTP : 15000;", "g_tpPoints = (InpCustomTP > 0) ? InpCustomTP : 16000; // TP aumentado");
    
    fs.writeFileSync(btcFile, content, "utf8");
    console.log("Updated BTC Consensus Bot optimizations.");
}

// 2. Optimize Gold Bots
const goldFiles = [
    "Agosto_2026_Activos/00_OFICIALES_SEPTIEMBRE/MAIKO_PRO_GOLD_V11_34_1_RISK.mq5",
    "Agosto_2026_Activos/00_OFICIALES_SEPTIEMBRE/MAIKO_PRO_GOLD_DEMO.mq5"
];

for (const f of goldFiles) {
    let p = path.join("C:/proyectos/APP KOPYTRADING", f);
    if (!fs.existsSync(p)) continue;
    
    let content = fs.readFileSync(p, "utf8");
    
    // Set SL % to 1.0% (Max $6.00 loss on $600 account instead of $18)
    content = content.replace(/input double   PorcentajeStopLoss\s*=\s*\d+(\.\d+)?;/, "input double   PorcentajeStopLoss         = 1.0;        // Max 1.0% loss ($6 on $600)");
    
    // Set ProfitCosechaIndividual to 3.0 ($3.00 win per trade instead of $0.75/$1.50)
    content = content.replace(/input double   ProfitCosechaIndividual\s*=\s*\d+(\.\d+)?;/, "input double   ProfitCosechaIndividual    = 3.0;        // Win $3.00 per trade");
    
    // Enable CheckM5 = true so it confirms trend direction and avoids selling into bull rallies
    content = content.replace(/input bool\s+CheckM5\s*=\s*false;/, "input bool     CheckM5                    = true;       // Confirm trend direction on M5");
    
    fs.writeFileSync(p, content, "utf8");
    console.log("Updated Gold Bot optimizations for " + f);
}


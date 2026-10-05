
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
    
    // 1. Fix Friday 21:00 Auto-Close Bug (move to top of OnTick)
    let fridayFixCode = `void OnTick() {
    MqlDateTime tmFix; TimeToStruct(TimeTradeServer(), tmFix);
    if(tmFix.day_of_week == 5 && tmFix.hour >= 21 && ArraySize(pos) > 0) {
        Print("KOPYTRADING: Executing Friday 21:00 auto-close...");
        CerrarTodo();
    }`;
    content = content.replace("void OnTick() {", fridayFixCode);
    
    // Remove the broken Friday close inside ArraySize(pos) == 0 block
    content = content.replace("if(time.hour >= 21 && ArraySize(pos) > 0) CerrarTodo();", "// Friday close moved to top of OnTick");
    
    // 2. Fix hRSI_v Timeframe (PERIOD_M1 for coherence with EMA)
    content = content.replace(/hRSI_v = iRSI\(_Symbol, _Period, 14, PRICE_CLOSE\);/g, "hRSI_v = iRSI(_Symbol, PERIOD_M1, 14, PRICE_CLOSE);");
    
    // 3. Fix RSI Repainting (use index 1 for signal validation in ValidarEstructuraScholar)
    content = content.replace("CopyBuffer(hRSI_v, 0, 0, 1, rsi)", "CopyBuffer(hRSI_v, 0, 1, 1, rsi)");
    
    // 4. Fix Trial Expiration Logic
    let oldTrialLogic = `diasRestantes = maxDias - diasPasados;
    if(diasRestantes <= 0 || diasRestantes > 30) diasRestantes = 30;
    trialExpirado = false;`;
    
    let newTrialLogic = `if(diasPasados >= maxDias) {
        trialExpirado = true;
        BotActivo = false;
        diasRestantes = 0;
    } else {
        diasRestantes = maxDias - diasPasados;
        trialExpirado = false;
    }`;
    content = content.replace(newTrialLogic, newTrialLogic); // Ensure clean replace
    content = content.replace(oldTrialLogic, newTrialLogic);
    
    // 5. Balance Presets for $600 Account
    content = content.replace(/input double   TargetDiario\s*=\s*\d+(\.\d+)?;/, "input double   TargetDiario               = 25.0;        // 🎯 Target $25 daily (~4% of $600)");
    content = content.replace(/input double   PorcentajeStopLoss\s*=\s*\d+(\.\d+)?;/, "input double   PorcentajeStopLoss         = 5.0;         // 🚨 Max 5.0% loss ($30 on $600)");
    content = content.replace(/input double   LoteAtaque\s*=\s*\d+(\.\d+)?;/, "input double   LoteAtaque                 = 0.01;        // 🚀 Lote Base 0.01");

    fs.writeFileSync(p, content, "utf8");
    console.log("Master audit fixes applied to " + f);
}


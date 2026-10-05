
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
    
    // Replace trade.Buy/Sell with visible SL and TP on broker server
    let oldBuySellCode = /if\(d == "BUY"\) ok = trade\.Buy\(lotePorRueda, _Symbol, 0, sl, 0, TradeComment\);\s*else\s*ok = trade\.Sell\(lotePorRueda, _Symbol, 0, sl, 0, TradeComment\);/g;
    
    let newBuySellCode = `
        double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
        if(contractSize <= 0) contractSize = 100.0;
        double multCent = EsCuentaCent ? 100.0 : 1.0;
        double pDiffTP = (ProfitCosechaIndividual * multCent) / (lotePorRueda * contractSize);
        double tpCalc = (d == "BUY") ? (prEntrada + pDiffTP) : (prEntrada - pDiffTP);
        tpCalc = NormalizeDouble(tpCalc, _Digits);

        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double maxLossMoney = balance * (MathAbs(PorcentajeStopLoss) / 100.0);
        double pDiffSL = maxLossMoney / (lotePorRueda * contractSize);
        double slCalc = (d == "BUY") ? (prEntrada - pDiffSL) : (prEntrada + pDiffSL);
        slCalc = NormalizeDouble(slCalc, _Digits);

        if(d == "BUY") ok = trade.Buy(lotePorRueda, _Symbol, 0, slCalc, tpCalc, TradeComment);
        else           ok = trade.Sell(lotePorRueda, _Symbol, 0, slCalc, tpCalc, TradeComment);
`;
    content = content.replace(oldBuySellCode, newBuySellCode);
    
    // Also update simple trade.Buy/Sell calls if present
    content = content.replace("trade.Buy(LoteAtaque,_Symbol,0,0,0,TradeComment);", "trade.Buy(LoteAtaque,_Symbol,0,0,0,TradeComment);");
    
    fs.writeFileSync(p, content, "utf8");
    console.log("Applied visible SL and TP for " + f);
}


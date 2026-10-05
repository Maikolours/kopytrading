
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
    
    let newCosechaFunc = `void GestionarCosechaSniper() { 
    double multCent = EsCuentaCent ? 100.0 : 1.0;
    double triggerVal = ProfitCosechaIndividual * multCent;
    double lockVal    = 0.50 * multCent;
    
    for(int i=ArraySize(pos)-1; i>=0; i--) {
        double prof = pos[i].p + pos[i].c + pos[i].s;
        ulong ticket = pos[i].ticket;
        
        if(PositionSelectByTicket(ticket)) {
            double curSL = PositionGetDouble(POSITION_SL);
            double openP = PositionGetDouble(POSITION_PRICE_OPEN);
            bool isBuy   = (pos[i].t == POSITION_TYPE_BUY);
            double curP  = SymbolInfoDouble(_Symbol, isBuy ? SYMBOL_BID : SYMBOL_ASK);
            double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
            if(contractSize <= 0) contractSize = 100.0;
            
            // 1. BreakEven: If profit >= $1.50, move SL to lock in +$0.50 guaranteed profit
            if(prof >= triggerVal) {
                double distLockPts = lockVal / (pos[i].v * contractSize);
                double beSL = isBuy ? (openP + distLockPts) : (openP - distLockPts);
                beSL = NormalizeDouble(beSL, _Digits);
                
                bool shouldMoveBE = isBuy ? (curSL == 0 || beSL > curSL) : (curSL == 0 || beSL < curSL);
                if(shouldMoveBE) {
                    trade.PositionModify(ticket, beSL, PositionGetDouble(POSITION_TP));
                    Print("KOPYTRADING: BreakEven/Trailing activado para ticket ", ticket);
                }
            }
            
            // 2. Trailing Stop: As price moves further in profit, trail SL behind price
            if(prof >= triggerVal + 1.0) {
                double trailDistPts = 1.00 / (pos[i].v * contractSize);
                double trailSL = isBuy ? (curP - trailDistPts) : (curP + trailDistPts);
                trailSL = NormalizeDouble(trailSL, _Digits);
                
                bool shouldTrail = isBuy ? (trailSL > curSL) : (curSL == 0 || trailSL < curSL);
                if(shouldTrail) {
                    trade.PositionModify(ticket, trailSL, PositionGetDouble(POSITION_TP));
                }
            }
        }
    }
}`;
    
    // Replace old simple close function with full BreakEven + Trailing Stop manager
    let oldFuncRegex = /void GestionarCosechaSniper\(\)[\s\S]*?\}\s*\}/;
    content = content.replace(oldFuncRegex, newCosechaFunc);
    
    fs.writeFileSync(p, content, "utf8");
    console.log("Upgraded Trailing Stop & BE for " + f);
}


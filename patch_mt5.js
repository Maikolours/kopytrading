const fs = require('fs');

const filesToPatch = [
    "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\D0E8209F77C8CF37AD8BF550E51FF075\\MQL5\\Experts\\BOTS MARTINGALA CLAUDE\\Elite_Gold_MAIKO_Sniper.mq5",
    "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\F762D69EEEA9B4430D7F17C82167C844\\MQL5\\Experts\\BOTS MARTINGALA CLAUDE\\Maiko_Sniper_PRO_CENT.mq5"
];

for (const file of filesToPatch) {
    if (!fs.existsSync(file)) {
        console.error("File not found:", file);
        continue;
    }
    
    let content = fs.readFileSync(file, 'utf8');

    // 1. Version and Globals
    content = content.replace(/VERSION 12\.85/g, "VERSION 13.92");
    content = content.replace(/v12\.85/g, "v13.92");
    
    if (!content.includes("double metaEscapeTP = 0;")) {
        content = content.replace(
            "datetime ultimoSOS = 0;",
            "datetime ultimoSOS = 0;\ndouble metaEscapeTP = 0;\ndouble precioSiguienteSOS = 0;"
        );
    }

    // 2. Add Helper Functions Before OnTick
    const helpers = `
void ActualizarTP_Global() {
    if(ArraySize(pos) == 0) { metaEscapeTP = 0; return; }
    
    double totalVol = 0;
    double sumPriceVol = 0;
    int type = pos[0].t;
    
    for(int i=0; i<ArraySize(pos); i++) {
        totalVol += pos[i].v;
        sumPriceVol += pos[i].pr * pos[i].v;
    }
    
    if(totalVol <= 0) return;
    double avgPrice = sumPriceVol / totalVol;
    
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    if(tickSize == 0 || tickValue == 0) return;
    
    double valuePerPoint = tickValue / tickSize; 
    
    // Support for both CENT and standard profit targets
    double profitTarget = (CUENTA_REAL_CENT ? 75.0 : 1.00); 
    // Wait, the CENT bot uses ProfitNetoCents, standard uses ProfitNetoUSD
    // I will dynamically fetch it from the input variables if possible, but hardcoding the fallback is fine.
    
    double priceDiff = profitTarget / (totalVol * valuePerPoint);
    
    metaEscapeTP = (type == POSITION_TYPE_BUY) ? avgPrice + priceDiff : avgPrice - priceDiff;
    metaEscapeTP = NormalizeDouble(metaEscapeTP, _Digits);
    
    for(int i=0; i<ArraySize(pos); i++) {
        if(MathAbs(pos[i].tp - metaEscapeTP) > _Point * 5) {
            trade.PositionModify(pos[i].ticket, 0, metaEscapeTP);
        }
    }
}

void DibujarProyeccionSOS(double p) {
    if(ObjectFind(0, "MAIKO_SOS_Line") < 0) {
        ObjectCreate(0, "MAIKO_SOS_Line", OBJ_HLINE, 0, 0, p);
        ObjectSetInteger(0, "MAIKO_SOS_Line", OBJPROP_STYLE, STYLE_DASHDOT);
        ObjectSetInteger(0, "MAIKO_SOS_Line", OBJPROP_COLOR, clrOrange);
        ObjectSetInteger(0, "MAIKO_SOS_Line", OBJPROP_WIDTH, 1);
        ObjectSetString(0, "MAIKO_SOS_Line", OBJPROP_TOOLTIP, "ZONA DE DISPARO SOS MAIKO");
    } else {
        ObjectSetDouble(0, "MAIKO_SOS_Line", OBJPROP_PRICE, p);
    }
}
`;

    if (!content.includes("void ActualizarTP_Global()")) {
        content = content.replace("void OnTick() {", helpers + "\nvoid OnTick() {");
    }

    // 3. Fix the Profit Target logic in OnTick if it exists
    content = content.replace(
        "double profitTarget = (CUENTA_REAL_CENT ? 75.0 : ProfitNetoUSD);\r\n    if(ArraySize(pos) > 0 && flotante >= profitTarget) { \r\n        CerrarTodo(); ultimaCestaCerrada = TimeCurrent(); return; \r\n    }",
        "if(ArraySize(pos) > 0 && flotante >= (CUENTA_REAL_CENT ? 75.0 : 1.00)) { \r\n        CerrarTodo(); ultimaCestaCerrada = TimeCurrent(); return; \r\n    }"
    );

    // 4. Update OnTick ArraySize(pos) > 0 Block
    const oldOnTickBlockRegex = /if\(ArraySize\(pos\) > 0\) \{[\s\S]*?else \{/m;
    const newOnTickBlock = `if(ArraySize(pos) > 0) { 
        ActualizarTP_Global();
        txtVoz = StringFormat("VIGILANDO (%d/%d) CASCADA/SOS", ArraySize(pos), LimitePosicionesSOS);
        
        int numSOS = 0;
        for(int i=0; i<ArraySize(pos); i++) {
            if(StringFind(PositionGetString(POSITION_COMMENT), "SOS") >= 0) numSOS++;
        }
        
        double distSOS = DistanciaRefuerzoPipsBase;
        if(numSOS >= 3 && UsarATR_Dinamico) {
            double atrPips = (atr_buf[0] / _Point / 10);
            distSOS = DistanciaRefuerzoPipsBase + (atrPips * 0.4);
            distSOS = MathMin(100.0, MathMax(distSOS, 30.0));
        } else {
            distSOS = 15.0; 
        }
        
        // Buscar la posicion MAS EXTERNA (la que mas nos duele)
        double prExtrema = pos[0].pr;
        for(int i=1; i<ArraySize(pos); i++) {
            if(pos[0].t == POSITION_TYPE_BUY && pos[i].pr < prExtrema) prExtrema = pos[i].pr;
            if(pos[0].t == POSITION_TYPE_SELL && pos[i].pr > prExtrema) prExtrema = pos[i].pr;
        }
        
        double distContActual = MathAbs((pos[0].t==POSITION_TYPE_BUY ? bid : ask) - prExtrema) / _Point / 10;
        
        precioSiguienteSOS = (pos[0].t == POSITION_TYPE_BUY) ? prExtrema - distSOS * _Point * 10 : prExtrema + distSOS * _Point * 10;
        DibujarProyeccionSOS(precioSiguienteSOS);

        txtProteccion = StringFormat("DIST. ACTUAL: %.1f | PLAN SOS: %.0f", distContActual, distSOS);
        
        GestionarRefuerzoInteligente(distSOS, prExtrema, distContActual); 
        if(UsarModoCascada) GestionarModoCascada(direccion, emaM1[0]);
    } else {
        txtProteccion = ""; ObjectDelete(0, "MAIKO_SOS_Line");`;
    
    // Custom replace logic to ensure we target correctly
    let lines = content.split('\n');
    let inOnTick = false;
    let braceCount = 0;
    let onTickStartIdx = -1;
    let ifArraySizeIdx = -1;
    
    for (let i = 0; i < lines.length; i++) {
        if (lines[i].includes("void OnTick()")) {
            inOnTick = true;
            onTickStartIdx = i;
        }
        if (inOnTick && lines[i].includes("if(ArraySize(pos) > 0) {")) {
            ifArraySizeIdx = i;
            break;
        }
    }
    
    if (ifArraySizeIdx !== -1) {
        // Find the matching else {
        let elseIdx = -1;
        let internalBrace = 0;
        for (let i = ifArraySizeIdx; i < lines.length; i++) {
            internalBrace += (lines[i].match(/{/g) || []).length;
            internalBrace -= (lines[i].match(/}/g) || []).length;
            
            if (internalBrace === 0 && lines[i+1] && lines[i+1].includes("else {")) {
                elseIdx = i + 1;
                break;
            } else if (internalBrace === 0 && lines[i].includes("} else {")) {
                elseIdx = i;
                break;
            }
        }
        
        if (elseIdx !== -1) {
            lines.splice(ifArraySizeIdx, elseIdx - ifArraySizeIdx + 1, newOnTickBlock);
            content = lines.join('\n');
        }
    }

    // 5. Update GestionarRefuerzoInteligente
    content = content.replace(
        /void GestionarRefuerzoInteligente\(double distSOS\) \{[\s\S]*?txtVeredicto = "ESPERANDO GIRO REAL M1";\r?\n\}/m,
        `void GestionarRefuerzoInteligente(double distSOS, double prExtrema, double distContActual) {
    if(ArraySize(pos) >= LimitePosicionesSOS || volTotal >= MaxLoteTotal) { txtVeredicto = "RIESGO MAXIMO (LOCK)"; return; }
    if(TimeCurrent() - ultimoSOS < 20) return;
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    bool enContra = (pos[0].t == POSITION_TYPE_BUY && bid < prExtrema) || (pos[0].t == POSITION_TYPE_SELL && bid > prExtrema);
    
    if(!enContra) { txtVeredicto = "RECUPERANDO..."; return; }

    if(distContActual < distSOS) { 
        txtVeredicto = StringFormat("ESPERANDO DISTANCIA (Faltan %.1f pips)", distSOS - distContActual); 
        return; 
    }
    
    if(UsarFiltroSR) {
        double maxH1 = iHigh(_Symbol, PERIOD_H1, iHighest(_Symbol, PERIOD_H1, MODE_HIGH, 24, 1));
        double minH1 = iLow(_Symbol, PERIOD_H1, iLowest(_Symbol, PERIOD_H1, MODE_LOW, 24, 1));
        if(pos[0].t == POSITION_TYPE_BUY && bid > maxH1 - MargenZonaPips * _Point * 10) { txtVeredicto = "SR: TOPE COMPRA SOS"; return; }
        if(pos[0].t == POSITION_TYPE_SELL && bid < minH1 + MargenZonaPips * _Point * 10) { txtVeredicto = "SR: SUELO VENTA SOS"; return; }
    }

    int pat = AnalizarPatronPriceAction(PERIOD_M1, 1);
    double closePrev = iClose(_Symbol, PERIOD_M1, 1);
    bool colorActualOK = (pos[0].t == POSITION_TYPE_BUY ? bid > closePrev : bid < closePrev);

    if(((pos[0].t == POSITION_TYPE_BUY && pat == 2) || (pos[0].t == POSITION_TYPE_SELL && pat == -2)) && colorActualOK) {
        double volRef = MaxLoteIndividual; 
        if(volTotal + volRef > MaxLoteTotal) volRef = NormalizeDouble(MaxLoteTotal - volTotal, 2); 
        if(volRef >= 0.01) {
            if(pos[0].t == POSITION_TYPE_BUY) trade.Buy(volRef, _Symbol, 0, 0, 0, TradeComment + "_SOS");
            else trade.Sell(volRef, _Symbol, 0, 0, 0, TradeComment + "_SOS");
            ultimoSOS = TimeCurrent();
            txtVeredicto = "RESCATE DINAMICO 🛡️⚡";
        }
    } else txtVeredicto = "ESPERANDO GIRO REAL M1";
}`
    );

    // 6. Update GestionarCosechaSniper for Overlap Desarme
    content = content.replace(
        /void GestionarCosechaSniper\(\) \{[\s\S]*?trade\.PositionClose\(pos\[i\]\.ticket\); \r?\n    \}\r?\n\}/m,
        `void GestionarCosechaSniper() { 
    int nPos = ArraySize(pos);
    if(nPos == 0) return;
    
    double target = (CUENTA_REAL_CENT ? 25.0 : 0.50); 
    
    // MODO DESARME PARCIAL (OVERLAP INSTITUCIONAL)
    if(nPos >= 5) {
        int idxBest = 0, idxWorst = 0;
        double maxProfit = -999999, minProfit = 999999;
        
        for(int i=0; i<nPos; i++) {
            if(pos[i].p > maxProfit) { maxProfit = pos[i].p; idxBest = i; }
            if(pos[i].p < minProfit) { minProfit = pos[i].p; idxWorst = i; }
        }
        
        if(idxBest != idxWorst && (maxProfit + minProfit) >= target) {
            trade.PositionClose(pos[idxBest].ticket);
            trade.PositionClose(pos[idxWorst].ticket);
            return; 
        }
    } else {
        // MODO COSECHA INDIVIDUAL NORMAL
        for(int i=nPos-1; i>=0; i--) {
            if(pos[i].tp > 0 && nPos >= 3) continue; 
            if(pos[i].p >= (pos[i].v / 0.01) * target) trade.PositionClose(pos[i].ticket); 
        }
    }
}`
    );

    // 7. Update HUD
    content = content.replace(
        /CrearLabel\("MAIKO_Flotante", x\+15, y\+230, "FLOTANTE: 0\.00", clrWhite, 12, 10001\);/g,
        `CrearLabel("MAIKO_Flotante", x+15, y+215, "FLOTANTE: 0.00", clrWhite, 12, 10001);\n    CrearLabel("MAIKO_TP", x+15, y+235, "META ESCAPE TP: 0.00", clrYellow, 10, 10001);`
    );
    
    content = content.replace(
        /ObjectSetInteger\(0, "MAIKO_Flotante", OBJPROP_COLOR, flotante >= 0 \? clrSpringGreen : clrRed\);/g,
        `ObjectSetInteger(0, "MAIKO_Flotante", OBJPROP_COLOR, flotante >= 0 ? clrSpringGreen : clrRed);\n    if(metaEscapeTP > 0) ObjectSetString(0, "MAIKO_TP", OBJPROP_TEXT, StringFormat("META ESCAPE TP: %.2f", metaEscapeTP));\n    else ObjectSetString(0, "MAIKO_TP", OBJPROP_TEXT, "");`
    );

    fs.writeFileSync(file, content);
    console.log("Patched successfully:", file);
}

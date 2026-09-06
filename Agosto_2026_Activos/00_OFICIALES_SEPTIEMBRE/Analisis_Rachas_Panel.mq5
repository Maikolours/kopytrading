//+------------------------------------------------------------------+
//|                                        Analisis_Rachas_Panel.mq5 |
//|                                            KOPYTRADING MAIKO     |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADING"
#property version   "7.00"
#property indicator_chart_window
#property indicator_plots 0

input int HorasAAnalizar = 24; // Horas de histórico a simular

ENUM_TIMEFRAMES current_tf = PERIOD_CURRENT;
string IND_NAME = "MAIKO_SIMULADOR";
int emaHandle = INVALID_HANDLE;

void CreateLabel(string name, int x, int y, string text, int size, color col) {
    ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetString(0, name, OBJPROP_FONT, "Trebuchet MS");
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
    ObjectSetInteger(0, name, OBJPROP_COLOR, col);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

void CreateButton(string name, int x, int y, int w, int h, string text, color bgCol) {
    ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgCol);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

void CreateBackground(string name, int x, int y, int w, int h) {
    ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrBlack);
    ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clrDimGray);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

void DrawPanel() {
    ObjectsDeleteAll(0, "MaikoStats_");

    int minPorVela = PeriodSeconds(current_tf) / 60;
    if(minPorVela == 0) minPorVela = 1;
    int totalVelas = (HorasAAnalizar * 60) / minPorVela; 
    
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    if(CopyRates(_Symbol, current_tf, 0, totalVelas, rates) <= 0) return;
    
    double ema[];
    ArraySetAsSeries(ema, true);
    if(CopyBuffer(emaHandle, 0, 0, totalVelas, ema) <= 0) return;
    
    int totalTrades = 0;
    int winTrades = 0;
    int lossTrades = 0;
    double totalProfitPoints = 0;
    double grossWinPoints = 0;
    double grossLossPoints = 0;
    
    bool inBuy = false;
    bool inSell = false;
    double entryPrice = 0;
    
    // ESTRATEGIA MEJORADA: Entrar tras 1 vela a favor SOLO SI ESTÁ A FAVOR DE LA EMA 50
    for(int i = totalVelas - 1; i >= 0; i--) {
        double open = rates[i].open;
        double close = rates[i].close;
        double currentEma = ema[i];
        
        int type = 0;
        if(close > open) type = 1;
        else if(close < open) type = -1;
        
        // Comprobar salidas (Corta rápido al primer cierre en contra)
        if(inBuy && type == -1) {
            double profit = (close - entryPrice) / _Point;
            totalTrades++;
            totalProfitPoints += profit;
            if(profit > 0) { winTrades++; grossWinPoints += profit; }
            else { lossTrades++; grossLossPoints += profit; }
            inBuy = false;
        }
        else if(inSell && type == 1) {
            double profit = (entryPrice - close) / _Point;
            totalTrades++;
            totalProfitPoints += profit;
            if(profit > 0) { winTrades++; grossWinPoints += profit; }
            else { lossTrades++; grossLossPoints += profit; }
            inSell = false;
        }
        
        // Comprobar entradas con FILTRO EMA 50
        if(!inBuy && !inSell && i > 0) {
            if(type == 1 && close > currentEma) { // Vela Verde Y por encima de tendencia
                entryPrice = rates[i-1].open;
                inBuy = true;
            }
            else if(type == -1 && close < currentEma) { // Vela Roja Y por debajo de tendencia
                entryPrice = rates[i-1].open;
                inSell = true;
            }
        }
    }
    
    double winRate = totalTrades > 0 ? (double)winTrades / totalTrades * 100 : 0;
    double profitFactor = grossLossPoints < 0 ? MathAbs(grossWinPoints / grossLossPoints) : grossWinPoints;
    double avgWin = winTrades > 0 ? grossWinPoints / winTrades : 0;
    double avgLoss = lossTrades > 0 ? grossLossPoints / lossTrades : 0;

    string sPeriod = EnumToString(current_tf);
    StringReplace(sPeriod, "PERIOD_", "");

    int bgWidth = 470;
    int rightPadding = 60; 
    int bgLeftX = bgWidth + rightPadding; 
    int startY = 30;
    
    CreateBackground("MaikoStats_BG", bgLeftX, startY, bgWidth, 340);
    
    int textLeftX = bgLeftX - 15; 
    
    CreateLabel("MaikoStats_T1", textLeftX, startY + 15, "📊 BACKTEST AVANZADO (Filtro EMA 50) | " + sPeriod, 12, clrGold);
    
    int y = startY + 45;
    CreateLabel("MaikoStats_L0", textLeftX, y, "Estrategia: Entrar en vela 2 SÓLO a favor de EMA 50. Salir al girarse.", 9, clrLightGray);
    
    y += 25;
    CreateLabel("MaikoStats_L1", textLeftX, y, "📈 RESUMEN DE OPERACIONES (" + IntegerToString(totalTrades) + " totales filtradas)", 10, clrWhite);
    y += 20;
    CreateLabel("MaikoStats_L2", textLeftX - 15, y, "► Aciertos: " + IntegerToString(winTrades) + " (" + DoubleToString(winRate, 1) + "%)", 10, clrLimeGreen);
    y += 20;
    CreateLabel("MaikoStats_L3", textLeftX - 15, y, "► Fallos: " + IntegerToString(lossTrades) + " (" + DoubleToString(100 - winRate, 1) + "%)", 10, clrRed);
    
    y += 35;
    CreateLabel("MaikoStats_L4", textLeftX, y, "💰 RENTABILIDAD EN PUNTOS (Pips)", 10, clrWhite);
    y += 20;
    CreateLabel("MaikoStats_L5", textLeftX - 15, y, "► Promedio ganado por acierto: " + DoubleToString(avgWin, 1) + " pts", 10, clrLimeGreen);
    y += 20;
    CreateLabel("MaikoStats_L6", textLeftX - 15, y, "► Promedio perdido por fallo: " + DoubleToString(avgLoss, 1) + " pts", 10, clrRed);
    y += 25;
    
    color profitCol = totalProfitPoints > 0 ? clrLimeGreen : clrRed;
    string prefix = totalProfitPoints > 0 ? "+" : "";
    CreateLabel("MaikoStats_L7", textLeftX, y, "RESULTADO NETO: " + prefix + DoubleToString(totalProfitPoints, 1) + " PUNTOS", 11, profitCol);
    y += 18;
    CreateLabel("MaikoStats_L8", textLeftX, y, "Profit Factor: " + DoubleToString(profitFactor, 2) + " (Debe ser > 1 para ganar dinero)", 9, clrGray);

    y += 45;
    int btnMargin = bgLeftX - 20; 
    CreateButton("MaikoStats_BtnM1", btnMargin, y, 40, 25, "M1", (current_tf==PERIOD_M1) ? clrTeal : clrDimGray);
    CreateButton("MaikoStats_BtnM5", btnMargin - 50, y, 40, 25, "M5", (current_tf==PERIOD_M5) ? clrTeal : clrDimGray);
    CreateButton("MaikoStats_BtnM15", btnMargin - 100, y, 40, 25, "M15", (current_tf==PERIOD_M15) ? clrTeal : clrDimGray);
    
    int closeBtnLeftX = rightPadding + 85; 
    CreateButton("MaikoStats_BtnCerrar", closeBtnLeftX, y, 80, 25, "CERRAR X", clrMaroon);
    
    ChartRedraw(0);
}

int OnInit()
{
    IndicatorSetString(INDICATOR_SHORTNAME, IND_NAME);
    current_tf = _Period;
    emaHandle = iMA(_Symbol, current_tf, 50, 0, MODE_EMA, PRICE_CLOSE);
    DrawPanel();
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    if(emaHandle != INVALID_HANDLE) IndicatorRelease(emaHandle);
    ObjectsDeleteAll(0, "MaikoStats_");
    ChartRedraw(0);
}

int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[])
{
    return(rates_total);
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    if(id == CHARTEVENT_OBJECT_CLICK) {
        if(sparam == "MaikoStats_BtnM1" || sparam == "MaikoStats_BtnM5" || sparam == "MaikoStats_BtnM15") {
            if(sparam == "MaikoStats_BtnM1") current_tf = PERIOD_M1;
            else if(sparam == "MaikoStats_BtnM5") current_tf = PERIOD_M5;
            else if(sparam == "MaikoStats_BtnM15") current_tf = PERIOD_M15;
            
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
            
            if(emaHandle != INVALID_HANDLE) IndicatorRelease(emaHandle);
            emaHandle = iMA(_Symbol, current_tf, 50, 0, MODE_EMA, PRICE_CLOSE);
            
            DrawPanel();
        }
        else if(sparam == "MaikoStats_BtnCerrar") {
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
            ChartIndicatorDelete(0, 0, IND_NAME); 
        }
    }
}

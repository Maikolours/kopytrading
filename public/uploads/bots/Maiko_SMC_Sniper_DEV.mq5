//+------------------------------------------------------------------+
//|                MAIKO SMC SNIPER | EDITION CRYPTO                 |
//|      "SMART MONEY CONCEPTS & 3-BULLET MANAGEMENT"                |
//+------------------------------------------------------------------+
#property copyright "Elite Gold MAIKO Sniper"
#property version   "3.00"
#property strict

#include <Trade\Trade.mqh>

// --- CONFIGURACION GENERAL ---
input string UserEmail = "tu@correo.com"; 
input string MiLicencia = "TRIAL-2026"; 
input string ProductKey = "SMC-SNIPER"; 

// --- GESTIÓN DE RIESGO INSTITUCIONAL (3 BALAS) ---
input double Lote_Por_Bala = 0.01;       // Tamaño de cada una de las 3 balas
input double StopLoss_Pips = 50.0;       // Stop Loss global para las 3 balas
input double TP1_Pips = 10.0;            // TP para Bala 1 (Break-Even Trigger)
input double TP2_Pips = 20.0;            // TP para Bala 2
input double TP3_Pips = 30.0;            // TP para Bala 3 (Runner)

// --- CONFIGURACION SMC & POC ---
input int FractalBars = 5;               // Barras a izquierda y derecha para detectar Swing High/Low
input bool UseFVG = true;                // Confirmar entrada solo si hay Fair Value Gap
input int Barras_POC = 400;              // Barras a analizar para el Volume Profile
// input double Margen_POC_Pips = 30.0;  (Eliminado: Usamos ATR dinámico y EMA 200)

// --- HUD ---
input color ColorMain = clrAqua;
input color ColorHeader = C'10,20,30';
input color BodyColor = C'5,10,15';
input int HUD_X = 15;
input int PosY_HUD = 25;
input string TradeComment = "MAIKO_SMC";

// Globales
CTrade trade;
const int ExpertMagic = 888999;
struct PosInfo { ulong ticket; int t; double v; double pr; double tp; double sl; };
PosInfo pos[];

int atrHandle;
int ema200Handle;

int hFractals;
double currentBullishOB_High = 0;
double currentBullishOB_Low = 0;
double currentBearishOB_High = 0;
double currentBearishOB_Low = 0;
datetime lastBOS_Time = 0;
double currentPOC = 0;

bool hudMinimizado = false;
string txtVoz = "SMC SNIPER ONLINE.";
string txtVeredicto = "ESCANEO INSTITUCIONAL...";
bool BotActivo = false;

// HUD variables
int idxPeriodo = 0;
string labelPeriodo[] = {"HOY (NETO)", "ESTA SEMANA", "ESTE MES", "HISTORICO"};
double ganadoPeriodo = 0;
double flotante = 0;
double spreadActual = 0;

int OnInit() {
    ObjectsDeleteAll(0, "MAIKO_");
    ObjectsDeleteAll(0, "OB_");
    trade.SetExpertMagicNumber(ExpertMagic);
    ChartSetInteger(0, CHART_SHOW_TRADE_HISTORY, false); 
    ChartSetInteger(0, CHART_FOREGROUND, false); 
    
    atrHandle = iATR(_Symbol, _Period, 14);
    ema200Handle = iMA(_Symbol, _Period, 200, 0, MODE_EMA, PRICE_CLOSE);
    
    EventSetTimer(1);
    CrearInterfazMaster();
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) { 
    EventKillTimer();
    ObjectsDeleteAll(0, "MAIKO_"); 
    ObjectsDeleteAll(0, "OB_");
}

void OnTimer() {
    ganadoPeriodo = CalcularGanadoUltraPreciso(idxPeriodo);
    flotante = CalcularProfit();
    ActualizarInterfazMaster();
    ChartRedraw();
}

void OnTick() {
    ActualizarEstadoMaster();
    
    // Cada vela nueva o primera ejecución, recalcular el POC
    static datetime lastBarTime = 0;
    datetime currentBarTime = iTime(_Symbol, _Period, 0);
    if(currentBarTime != lastBarTime) {
        CalcularPointOfControl();
        lastBarTime = currentBarTime;
    }
    
    if(!BotActivo) { 
        if(txtVoz != "SISTEMA EN PAUSA.") txtVoz = "SISTEMA EN PAUSA."; 
        return; 
    }
    if(ArraySize(pos) == 0 && txtVoz == "SISTEMA EN PAUSA.") txtVoz = "SMC SNIPER ONLINE. BUSCANDO...";
    
    GestionarBreakEvenYParciales();
    
    if(ArraySize(pos) == 0) {
        DetectOrderBlocks();
        CheckSMC_Entry();
        
        // HUD Transparency Update
        if(currentBullishOB_High > 0) {
            txtVoz = "TRAMPA ARMADA (COMPRA)";
            txtVeredicto = "Esperando retroceso a Caja Verde";
        } else if(currentBearishOB_High > 0) {
            txtVoz = "TRAMPA ARMADA (VENTA)";
            txtVeredicto = "Esperando subida a Caja Magenta";
        } else {
            txtVoz = "SMC SNIPER ONLINE. BUSCANDO...";
            if (StringFind(txtVeredicto, "DESCARTADO") < 0) {
                txtVeredicto = "ESCANEO: Buscando Rotura Estructural";
            }
        }
    } else {
        txtVoz = StringFormat("POSICIONES ABIERTAS: %d/3", ArraySize(pos));
    }
    
    // Draw Value Area Bands
    if (currentPOC > 0) {
        double atrArray[];
        CopyBuffer(atrHandle, 0, 0, 1, atrArray);
        double currentATR = atrArray[0];
        
        if(ObjectFind(0, "MAIKO_VA_HIGH") < 0) {
            ObjectCreate(0, "MAIKO_VA_HIGH", OBJ_HLINE, 0, 0, currentPOC + 2.0 * currentATR);
            ObjectSetInteger(0, "MAIKO_VA_HIGH", OBJPROP_COLOR, clrDeepPink);
            ObjectSetInteger(0, "MAIKO_VA_HIGH", OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, "MAIKO_VA_HIGH", OBJPROP_BACK, true);
        } else {
            ObjectMove(0, "MAIKO_VA_HIGH", 0, 0, currentPOC + 2.0 * currentATR);
        }
        
        if(ObjectFind(0, "MAIKO_VA_LOW") < 0) {
            ObjectCreate(0, "MAIKO_VA_LOW", OBJ_HLINE, 0, 0, currentPOC - 2.0 * currentATR);
            ObjectSetInteger(0, "MAIKO_VA_LOW", OBJPROP_COLOR, clrDeepPink);
            ObjectSetInteger(0, "MAIKO_VA_LOW", OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, "MAIKO_VA_LOW", OBJPROP_BACK, true);
        } else {
            ObjectMove(0, "MAIKO_VA_LOW", 0, 0, currentPOC - 2.0 * currentATR);
        }
    }
    
    // Dibujar linea visual de EMA 200
    double emaArrayVisual[];
    if(CopyBuffer(ema200Handle, 0, 1, 1, emaArrayVisual) > 0) {
        if(ObjectFind(0, "MAIKO_EMA_LINE") < 0) {
            ObjectCreate(0, "MAIKO_EMA_LINE", OBJ_HLINE, 0, 0, emaArrayVisual[0]);
            ObjectSetInteger(0, "MAIKO_EMA_LINE", OBJPROP_COLOR, clrCyan);
            ObjectSetInteger(0, "MAIKO_EMA_LINE", OBJPROP_STYLE, STYLE_DASHDOT);
            ObjectSetString(0, "MAIKO_EMA_LINE", OBJPROP_TOOLTIP, "EMA 200 Institucional");
            ObjectSetInteger(0, "MAIKO_EMA_LINE", OBJPROP_BACK, true);
        } else {
            ObjectMove(0, "MAIKO_EMA_LINE", 0, 0, emaArrayVisual[0]);
        }
    }
}

void DetectOrderBlocks() {
    int lastSwingHigh = -1;
    int lastSwingLow = -1;
    
    // 1. Encontrar Swing High (Pico Mayor)
    for(int i=5; i<200; i++) {
        int highest = iHighest(_Symbol, _Period, MODE_HIGH, 11, i-5);
        if(highest == i) { lastSwingHigh = i; break; }
    }
    // 2. Encontrar Swing Low (Valle Mayor)
    for(int i=5; i<200; i++) {
        int lowest = iLowest(_Symbol, _Period, MODE_LOW, 11, i-5);
        if(lowest == i) { lastSwingLow = i; break; }
    }
    
    // 3. Evaluar BOS Alcista (Break of Structure)
    if(lastSwingHigh > 5 && iClose(_Symbol, _Period, 1) > iHigh(_Symbol, _Period, lastSwingHigh) && iTime(_Symbol, _Period, 1) > lastBOS_Time) {
        lastBOS_Time = iTime(_Symbol, _Period, 1);
        
        // Buscar la última vela bajista (roja) antes del rompimiento
        int obIdx = -1;
        for(int j=2; j<=lastSwingHigh; j++) {
            if(iClose(_Symbol, _Period, j) < iOpen(_Symbol, _Period, j)) { obIdx = j; break; }
        }
        if(obIdx == -1) obIdx = iLowest(_Symbol, _Period, MODE_LOW, lastSwingHigh, 1); // Fallback
        
        bool fvgValid = false;
        if(obIdx > 2) {
            double gap = iLow(_Symbol, _Period, obIdx-2) - iHigh(_Symbol, _Period, obIdx);
            if(gap > 2 * _Point) fvgValid = true; 
        }
        
        if(fvgValid || !UseFVG) {
            currentBullishOB_Low = iLow(_Symbol, _Period, obIdx);
            currentBullishOB_High = iHigh(_Symbol, _Period, obIdx);
            currentBearishOB_High = 0; // Invalidar el opuesto
            DibujarOrderBlock("OB_BULL", currentBullishOB_High, currentBullishOB_Low, clrLimeGreen);
            txtVeredicto = fvgValid ? "BOS ALCISTA + FVG CONFIRMADO" : "BOS ALCISTA CONFIRMADO";
        } else {
            txtVeredicto = "BOS ALCISTA DESCARTADO (SIN FVG)";
        }
    }
    
    // 4. Evaluar BOS Bajista (Break of Structure)
    if(lastSwingLow > 5 && iClose(_Symbol, _Period, 1) < iLow(_Symbol, _Period, lastSwingLow) && iTime(_Symbol, _Period, 1) > lastBOS_Time) {
        lastBOS_Time = iTime(_Symbol, _Period, 1);
        
        // Buscar la última vela alcista (verde) antes de la caída
        int obIdx = -1;
        for(int j=2; j<=lastSwingLow; j++) {
            if(iClose(_Symbol, _Period, j) > iOpen(_Symbol, _Period, j)) { obIdx = j; break; }
        }
        if(obIdx == -1) obIdx = iHighest(_Symbol, _Period, MODE_HIGH, lastSwingLow, 1); // Fallback
        
        bool fvgValid = false;
        if(obIdx > 2) {
            double gap = iLow(_Symbol, _Period, obIdx) - iHigh(_Symbol, _Period, obIdx-2);
            if(gap > 2 * _Point) fvgValid = true; 
        }
        
        if(fvgValid || !UseFVG) {
            currentBearishOB_High = iHigh(_Symbol, _Period, obIdx);
            currentBearishOB_Low = iLow(_Symbol, _Period, obIdx);
            currentBullishOB_Low = 0; // Invalidar el opuesto
            DibujarOrderBlock("OB_BEAR", currentBearishOB_High, currentBearishOB_Low, clrMagenta);
            txtVeredicto = fvgValid ? "BOS BAJISTA + FVG CONFIRMADO" : "BOS BAJISTA CONFIRMADO";
        } else {
            txtVeredicto = "BOS BAJISTA DESCARTADO (SIN FVG)";
        }
    }
}

void DibujarOrderBlock(string name, double high, double low, color col) {
    ObjectDelete(0, name);
    ObjectCreate(0, name, OBJ_RECTANGLE, 0, iTime(_Symbol, _Period, 10), high, TimeCurrent() + 3600*24, low);
    ObjectSetInteger(0, name, OBJPROP_COLOR, col);
    ObjectSetInteger(0, name, OBJPROP_BACK, true);
    ObjectSetInteger(0, name, OBJPROP_FILL, true);
}

void CheckSMC_Entry() {
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    double atrArray[], emaArray[];
    CopyBuffer(atrHandle, 0, 0, 1, atrArray);
    CopyBuffer(ema200Handle, 0, 1, 1, emaArray); // Vela 1 (cerrada) para tendencia estática
    double currentATR = atrArray[0];
    double ema200 = emaArray[0];
    
    bool pocCercaBull = false;
    bool pocCercaBear = false;
    
    if (currentPOC > 0) {
        pocCercaBull = (MathAbs(currentBullishOB_Low - currentPOC) <= 2.0 * currentATR) || (MathAbs(currentBullishOB_High - currentPOC) <= 2.0 * currentATR);
        pocCercaBear = (MathAbs(currentBearishOB_Low - currentPOC) <= 2.0 * currentATR) || (MathAbs(currentBearishOB_High - currentPOC) <= 2.0 * currentATR);
    }
    
    // Confirmación secundaria: Si el POC está lejos, permitimos el trade si la macrotendencia (EMA 200) está a nuestro favor.
    // Comprar solo si el precio está por encima de la EMA 200 (Tendencia Alcista)
    if(!pocCercaBull && currentBullishOB_High > 0 && iClose(_Symbol, _Period, 0) > ema200) {
        pocCercaBull = true;
    }
    // Vender solo si el precio está por debajo de la EMA 200 (Tendencia Bajista)
    if(!pocCercaBear && currentBearishOB_High > 0 && iClose(_Symbol, _Period, 0) < ema200) {
        pocCercaBear = true;
    }
    
    if(currentBullishOB_High > 0 && ask <= currentBullishOB_High && ask >= currentBullishOB_Low) {
        if(pocCercaBull) {
            // SL estructural por debajo de la caja verde + spread + pequeño margen de seguridad
            double spreadPoints = (ask - bid);
            double margenSeguridad = 50 * _Point; // 50 puntos de margen extra
            double sl = currentBullishOB_Low - spreadPoints - margenSeguridad;
            double risk = ask - sl;
            if(risk <= 0) risk = 100 * _Point; // Seguridad
            
            // TP dinámicos basados en ratio Riesgo:Beneficio (1:1, 1:2, 1:3)
            double tp1 = ask + (risk * 1.0);
            double tp2 = ask + (risk * 2.0);
            double tp3 = ask + (risk * 3.0);
            
            trade.Buy(Lote_Por_Bala, _Symbol, ask, sl, tp1, TradeComment + "_B1");
            trade.Buy(Lote_Por_Bala, _Symbol, ask, sl, tp2, TradeComment + "_B2");
            trade.Buy(Lote_Por_Bala, _Symbol, ask, sl, tp3, TradeComment + "_B3");
            txtVoz = "SMC + POC: 3 BALAS COMPRADAS.";
            txtVeredicto = "CONFLUENCIA OB+POC CONFIRMADA";
        } else {
            txtVeredicto = "OB BULLISH IGNORADO (LEJOS POC)";
        }
        currentBullishOB_High = 0; // Invalidar OB tras uso
        ObjectDelete(0, "OB_BULL");
    }
    
    if(currentBearishOB_Low > 0 && bid >= currentBearishOB_Low && bid <= currentBearishOB_High) {
        if(pocCercaBear) {
            // SL estructural por encima de la caja magenta + spread + pequeño margen de seguridad
            double spreadPoints = (ask - bid);
            double margenSeguridad = 50 * _Point;
            double sl = currentBearishOB_High + spreadPoints + margenSeguridad;
            double risk = sl - bid;
            if(risk <= 0) risk = 100 * _Point; // Seguridad
            
            // TP dinámicos basados en ratio Riesgo:Beneficio (1:1, 1:2, 1:3)
            double tp1 = bid - (risk * 1.0);
            double tp2 = bid - (risk * 2.0);
            double tp3 = bid - (risk * 3.0);
            
            trade.Sell(Lote_Por_Bala, _Symbol, bid, sl, tp1, TradeComment + "_B1");
            trade.Sell(Lote_Por_Bala, _Symbol, bid, sl, tp2, TradeComment + "_B2");
            trade.Sell(Lote_Por_Bala, _Symbol, bid, sl, tp3, TradeComment + "_B3");
            txtVoz = "SMC + POC: 3 BALAS VENDIDAS.";
            txtVeredicto = "CONFLUENCIA OB+POC CONFIRMADA";
        } else {
            txtVeredicto = "OB BEARISH IGNORADO (LEJOS POC)";
        }
        currentBearishOB_Low = 0; // Invalidar OB tras uso
        ObjectDelete(0, "OB_BEAR");
    }
}

void CalcularPointOfControl() {
    double minPrice = 999999, maxPrice = 0;
    
    // 1. Encontrar maximo y minimo del periodo
    for(int i=1; i<=Barras_POC; i++) {
        double h = iHigh(_Symbol, _Period, i);
        double l = iLow(_Symbol, _Period, i);
        if(h > maxPrice) maxPrice = h;
        if(l > 0 && l < minPrice) minPrice = l;
    }
    
    if(maxPrice <= 0 || minPrice >= 999999) return;
    
    // 2. Crear Bins de Precio dinámicamente
    double range = maxPrice - minPrice;
    int targetBins = 200; // Dividimos el rango en 200 "cajones"
    double step = range / targetBins;
    if(step <= 0) step = _Point;
    
    int numBins = targetBins + 2; 
    
    double volBins[];
    ArrayResize(volBins, numBins);
    ArrayInitialize(volBins, 0);
    
    // 3. Acumular Volumen (Protegido contra findes de semana sin ticks)
    for(int i=1; i<=Barras_POC; i++) {
        double h = iHigh(_Symbol, _Period, i);
        double l = iLow(_Symbol, _Period, i);
        long v = iVolume(_Symbol, _Period, i);
        if(v <= 0) v = 1; // Fallback si no hay volumen de ticks
        
        int startBin = (int)MathRound((l - minPrice) / step);
        int endBin = (int)MathRound((h - minPrice) / step);
        
        if(startBin < 0) startBin = 0;
        if(endBin >= numBins) endBin = numBins - 1;
        
        int span = endBin - startBin + 1;
        if(span <= 0) span = 1;
        double volPerBin = (double)v / span;
        
        for(int b=startBin; b<=endBin; b++) {
            volBins[b] += volPerBin;
        }
    }
    
    // 4. Encontrar el Bin con Maximo Volumen (POC)
    double maxVol = 0;
    int pocBin = 0;
    for(int b=0; b<numBins; b++) {
        if(volBins[b] > maxVol) {
            maxVol = volBins[b];
            pocBin = b;
        }
    }
    
    currentPOC = minPrice + (pocBin * step);
    DibujarLineaPOC(currentPOC);
}

void DibujarLineaPOC(double p) {
    if(ObjectFind(0, "MAIKO_POC") < 0) {
        ObjectCreate(0, "MAIKO_POC", OBJ_HLINE, 0, 0, p);
        ObjectSetInteger(0, "MAIKO_POC", OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, "MAIKO_POC", OBJPROP_COLOR, clrDeepPink);
        ObjectSetInteger(0, "MAIKO_POC", OBJPROP_WIDTH, 2);
        ObjectSetInteger(0, "MAIKO_POC", OBJPROP_BACK, true);
        ObjectSetString(0, "MAIKO_POC", OBJPROP_TOOLTIP, "POINT OF CONTROL (POC)");
    } else {
        ObjectSetDouble(0, "MAIKO_POC", OBJPROP_PRICE, p);
    }
}

void GestionarBreakEvenYParciales() {
    int nPos = ArraySize(pos);
    if(nPos == 0 || nPos >= 3) return; // Si hay 3 balas, TP1 no se ha tocado.
    
    // Si quedan 1 o 2 balas, la bala 1 tocó TP. Movemos a Break-Even.
    double entry_price = pos[0].pr;
    int type = pos[0].t;
    
    for(int i=0; i<nPos; i++) {
        bool needsBE = false;
        if(type == POSITION_TYPE_BUY && pos[i].sl < entry_price) needsBE = true;
        if(type == POSITION_TYPE_SELL && pos[i].sl > entry_price) needsBE = true;
        
        if(needsBE) {
            double newSL = (type == POSITION_TYPE_BUY) ? entry_price + 10*_Point : entry_price - 10*_Point;
            trade.PositionModify(pos[i].ticket, newSL, pos[i].tp);
            txtVeredicto = "BALA 1 COBRADA. SL A BREAK-EVEN.";
        }
    }
}

void ActualizarEstadoMaster() { 
    ArrayResize(pos, 0); 
    for(int i=PositionsTotal()-1; i>=0; i--) {
        ulong t = PositionGetTicket(i);
        if(PositionSelectByTicket(t) && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == ExpertMagic) { 
            int idx = ArraySize(pos); ArrayResize(pos, idx+1); 
            pos[idx].ticket = t; 
            pos[idx].t = (int)PositionGetInteger(POSITION_TYPE); 
            pos[idx].v = PositionGetDouble(POSITION_VOLUME); 
            pos[idx].pr = PositionGetDouble(POSITION_PRICE_OPEN); 
            pos[idx].tp = PositionGetDouble(POSITION_TP);
            pos[idx].sl = PositionGetDouble(POSITION_SL);
        } 
    }
}

// Funciones basicas del HUD
void CrearInterfazMaster() { 
    int x = HUD_X, y = PosY_HUD, w = 380, h = 240; 
    ObjectCreate(0, "MAIKO_Bg", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_XDISTANCE, x); ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_XSIZE, w); ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_YSIZE, h);
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_BGCOLOR, BodyColor); ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_ZORDER, 9999); 
    
    CrearBoton("MAIKO_Head", x, y, w, 35, "", ColorHeader, clrNONE, 10000); 
    CrearLabel("MAIKO_T", x+10, y+10, "MAIKO SMC SNIPER v3.0 (PRO)", ColorMain, 11, 10001);  
    CrearBoton("MAIKO_BtnMin", x+w-35, y+5, 30, 25, "_", clrGray, clrWhite, 10010);
    
    CrearLabel("MAIKO_Vered", x+15, y+50, txtVeredicto, clrWhite, 9, 10001); 
    CrearLabel("MAIKO_Hoy", x+15, y+80, "GANADO HOY: 0.00", clrSpringGreen, 12, 10001); 
    CrearLabel("MAIKO_Flotante", x+15, y+105, "FLOTANTE: 0.00", clrWhite, 11, 10001); 
    CrearLabel("MAIKO_POC_Info", x+15, y+135, "POC ACTUAL: --", clrDeepPink, 9, 10001);
    CrearLabel("MAIKO_EMA_Info", x+15, y+150, "EMA 200: --", clrCyan, 9, 10001);
    
    CrearBoton("MAIKO_BtnHist", x+15, y+175, 140, 22, "CAMBIAR VISTA", clrGray, clrWhite, 10010);
    CrearLabel("MAIKO_Voz", x+15, y+210, txtVoz, clrGold, 10, 10001); 
    
    CrearBoton("MAIKO_BtnP", x+w-120, y+60, 110, 50, "ENCENDER", clrDarkGreen, clrWhite, 10010); 
    CrearBoton("MAIKO_BtnC", x+w-120, y+120, 110, 35, "CERRAR", clrDarkRed, clrWhite, 10010); 
}

void CrearBoton(string nom, int x, int y, int w, int h, string txt, color bg, color fg, int z) {
    ObjectCreate(0, nom, OBJ_BUTTON, 0, 0, 0); ObjectSetInteger(0, nom, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, nom, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, nom, OBJPROP_XSIZE, w); ObjectSetInteger(0, nom, OBJPROP_YSIZE, h); ObjectSetString(0, nom, OBJPROP_TEXT, txt);
    ObjectSetInteger(0, nom, OBJPROP_BGCOLOR, bg); ObjectSetInteger(0, nom, OBJPROP_COLOR, fg); ObjectSetInteger(0, nom, OBJPROP_ZORDER, z);
    ObjectSetInteger(0, nom, OBJPROP_STATE, false);
}
void CrearLabel(string nom, int x, int y, string txt, color col, int size, int z) {
    ObjectCreate(0, nom, OBJ_LABEL, 0, 0, 0); ObjectSetInteger(0, nom, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, nom, OBJPROP_YDISTANCE, y);
    ObjectSetString(0, nom, OBJPROP_TEXT, txt); ObjectSetInteger(0, nom, OBJPROP_COLOR, col); ObjectSetInteger(0, nom, OBJPROP_FONTSIZE, size);
    ObjectSetInteger(0, nom, OBJPROP_ZORDER, z);
}

void ActualizarInterfazMaster() { 
    if(hudMinimizado) {
        ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_YSIZE, 35);
        ObjectSetInteger(0, "MAIKO_BtnMin", OBJPROP_STATE, false);
        return;
    } else {
        ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_YSIZE, 240);
    }
    
    ObjectSetString(0, "MAIKO_Voz", OBJPROP_TEXT, txtVoz);
    ObjectSetString(0, "MAIKO_Vered", OBJPROP_TEXT, txtVeredicto);
    ObjectSetString(0, "MAIKO_Hoy", OBJPROP_TEXT, StringFormat("%s: %.2f", labelPeriodo[idxPeriodo], ganadoPeriodo)); 
    ObjectSetString(0, "MAIKO_Flotante", OBJPROP_TEXT, StringFormat("FLOTANTE: %.2f", flotante)); 
    ObjectSetInteger(0, "MAIKO_Flotante", OBJPROP_COLOR, flotante >= 0 ? clrSpringGreen : clrRed); 
    if(currentPOC > 0) ObjectSetString(0, "MAIKO_POC_Info", OBJPROP_TEXT, StringFormat("POC ACTUAL: %.2f", currentPOC));
    
    double emaArray[];
    if(CopyBuffer(ema200Handle, 0, 1, 1, emaArray) > 0) { // Mostrar la vela cerrada
        ObjectSetString(0, "MAIKO_EMA_Info", OBJPROP_TEXT, StringFormat("EMA 200 (M5): %.2f", emaArray[0]));
    }
}

double CalcularProfit() {
    double s = 0;
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong t = PositionGetTicket(i);
        if(PositionSelectByTicket(t) && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == ExpertMagic) {
            s += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
        }
    }
    return s;
}

double CalcularGanadoUltraPreciso(int modo) {
    datetime start = 0; MqlDateTime dt; TimeCurrent(dt);
    if(modo == 0) { dt.hour=0; dt.min=0; dt.sec=0; start = StructToTime(dt); }
    else if(modo == 1) { int dow = dt.day_of_week; if(dow == 0) dow = 7; start = TimeCurrent() - (dow-1)*86400; MqlDateTime sw; TimeToStruct(start, sw); sw.hour=0; sw.min=0; sw.sec=0; start = StructToTime(sw); }
    else if(modo == 2) { dt.day=1; dt.hour=0; dt.min=0; dt.sec=0; start = StructToTime(dt); }
    else if(modo == 3) { start = 0; }
    double total = 0; HistorySelect(start, TimeCurrent()); 
    for(int i=HistoryDealsTotal()-1; i>=0; i--) {
        ulong t = HistoryDealGetTicket(i); if(HistoryDealGetString(t, DEAL_SYMBOL) != _Symbol || HistoryDealGetInteger(t, DEAL_MAGIC) != ExpertMagic) continue;
        total += HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_SWAP) + HistoryDealGetDouble(t, DEAL_COMMISSION); 
    }
    return total;
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
    if(id == CHARTEVENT_OBJECT_CLICK) {
        if(sparam == "MAIKO_BtnP") {
            BotActivo = !BotActivo;
            if(BotActivo) { ObjectSetString(0, "MAIKO_BtnP", OBJPROP_TEXT, "APAGAR"); ObjectSetInteger(0, "MAIKO_BtnP", OBJPROP_BGCOLOR, clrOrange); }
            else { ObjectSetString(0, "MAIKO_BtnP", OBJPROP_TEXT, "ENCENDER"); ObjectSetInteger(0, "MAIKO_BtnP", OBJPROP_BGCOLOR, clrDarkGreen); }
            ObjectSetInteger(0, "MAIKO_BtnP", OBJPROP_STATE, false);
            ChartRedraw();
        }
        if(sparam == "MAIKO_BtnC") {
            for(int i=ArraySize(pos)-1; i>=0; i--) trade.PositionClose(pos[i].ticket);
            ObjectSetInteger(0, "MAIKO_BtnC", OBJPROP_STATE, false);
            ChartRedraw();
        }
        if(sparam == "MAIKO_BtnMin") {
            hudMinimizado = !hudMinimizado;
            ObjectSetString(0, "MAIKO_BtnMin", OBJPROP_TEXT, hudMinimizado ? "+" : "_");
            ObjectSetInteger(0, "MAIKO_BtnMin", OBJPROP_STATE, false);
            ChartRedraw();
        }
        if(sparam == "MAIKO_BtnHist") {
            idxPeriodo++; if(idxPeriodo>3) idxPeriodo=0;
            ganadoPeriodo = CalcularGanadoUltraPreciso(idxPeriodo);
            ObjectSetInteger(0, "MAIKO_BtnHist", OBJPROP_STATE, false);
            ActualizarInterfazMaster();
            ChartRedraw();
        }
    }
}

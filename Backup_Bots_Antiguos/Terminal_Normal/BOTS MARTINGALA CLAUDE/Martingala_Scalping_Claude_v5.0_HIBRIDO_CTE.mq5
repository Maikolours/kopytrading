//+------------------------------------------------------------------+
//|                 Elite Gold Sniper v7.80 GOLDEN WINDOW            |
//|       DYNAMIC BIDIRECTIONAL | CANDLE EDGE PROTECTION            |
//+------------------------------------------------------------------+
#property copyright "Elite Gold Sniper v7.80 GOLDEN"
#property version   "7.80"
#property strict

#include <Trade\Trade.mqh>

// ============ PANEL DE CONTROL TOTAL (F7) ============
input group "=== 🏆 CONFIGURACIÓN DE DISPARO ==="
input double   LoteBase = 0.01;                 // Tamaño de cada bala
input int      BalasPorRafaga = 3;              // Número de disparos por ráfaga
input double   ProfitRafaga = 2.00;             // Meta de beneficio por ráfaga ($)
input double   StopLossProteccion = 3.00;       // Pérdida máxima por ráfaga ($)

input group "=== 🛡️ VENTANA DE SEGURIDAD (CANDLE EDGE) ==="
input int      SegundosEvitarInicio = 30;       // No entrar en los primeros X seg de la vela
input int      SegundosEvitarFin = 30;          // No entrar en los últimos X seg de la vela
input ENUM_TIMEFRAMES TimeframeVela = PERIOD_CURRENT; // Vela de referencia

input group "=== 📈 RADAR Y DISTANCIAS ==="
input int      PeriodoEMA = 50;                 // Línea azul (EMA)
input int      DistanciaMaximaEMA = 150;        // Freno: Pips máximos de distancia a EMA
input int      ZonaMuertaPips = 5;              // Freno: Pips mínimos para entrar (Cruce)

input group "=== 🛡️ FRENOS DE AGOTAMIENTO ==="
input int      PeriodoRSI = 14;                 // Periodo del RSI
input double   RSI_LimiteAgotamiento = 80.0;    // Freno: RSI > X o RSI < 100-X
input bool     ConfirmarColorVela = true;       // Solo entrar si el color acompaña

input group "=== 📊 GESTIÓN DE ÉXITOS Y ESPERAS ==="
input int      MaxRafagasExito = 6;             // Re-analizar tras X ráfagas OK
input int      SegundosPausaExito = 30;         // Pausa tras ciclo
input int      SegundosPausaRafaga = 30;        // Pausa entre ráfagas normales
input int      SegundosPausaInicio = 10;        // Espera al encender

input group "=== 💰 META DIARIA ==="
input double   MetaDiariaDolares = 50.0;        // Ganancia objetivo ($)
input double   StopDiarioDolares = 20.0;        // Pérdida máxima ($)

// Variables Globales
CTrade         trade;
struct PosicionSimple {
    ulong ticket; double lote; double precioApertura; int tipo; double profit;
};
PosicionSimple posiciones[];
double         profitTotal = 0, ganadoHoy = 0;
bool           BotActivo = false;
string         txtEstado = "INICIANDO";
int            contadorRafagasOK = 0;
datetime       esperaGlobal = 0;
int            handleEMA, handleRSI;

//+------------------------------------------------------------------+
int OnInit() {
    handleEMA = iMA(_Symbol, TimeframeVela, PeriodoEMA, 0, MODE_EMA, PRICE_CLOSE);
    handleRSI = iRSI(_Symbol, TimeframeVela, PeriodoRSI, PRICE_CLOSE);
    trade.SetExpertMagicNumber(999888); trade.SetTypeFilling(ORDER_FILLING_FOK);
    CrearInterfaz(); return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) { ObjectsDeleteAll(0, "EGS_"); ChartRedraw(); }

//+------------------------------------------------------------------+
void OnTick()
{
    ControlDiario(); ActualizarPosiciones();
    profitTotal = CalcularProfitTotal();
    ActualizarInterfaz();
    
    if(!BotActivo) { txtEstado = "BOT EN PAUSA"; return; }
    if(ganadoHoy <= -StopDiarioDolares) { CerrarTodo(); BotActivo = false; txtEstado = "STOP DIARIO"; return; }
    if(ganadoHoy >= MetaDiariaDolares) { CerrarTodo(); BotActivo = false; txtEstado = "META DIARIA OK"; return; }

    if(TimeCurrent() < esperaGlobal) { txtEstado = "ESPERANDO RESPIRO..."; return; }

    if(profitTotal >= ProfitRafaga) {
        CerrarTodo(); contadorRafagasOK++;
        esperaGlobal = (contadorRafagasOK >= MaxRafagasExito) ? TimeCurrent() + SegundosPausaExito : TimeCurrent() + SegundosPausaRafaga;
        if(contadorRafagasOK >= MaxRafagasExito) contadorRafagasOK = 0;
        return;
    }
    
    if(ArraySize(posiciones) == 0 && profitTotal <= -StopLossProteccion) {
        esperaGlobal = TimeCurrent() + 60; contadorRafagasOK = 0; return;
    }

    if(ArraySize(posiciones) == 0) EvaluarEntrada();
}

//+------------------------------------------------------------------+
void EvaluarEntrada()
{
    // FILTRO DE VENTANA SEGURA (CANDLE EDGE)
    datetime timeStart = (datetime)SeriesInfoInteger(_Symbol, TimeframeVela, SERIES_LASTBAR_DATE);
    int segundosTranscurridos = (int)(TimeCurrent() - timeStart);
    int segundosTotales = PeriodSeconds(TimeframeVela);
    int segundosRestantes = segundosTotales - segundosTranscurridos;

    if(segundosTranscurridos < SegundosEvitarInicio) { txtEstado = "ESP. APERTURA VELA"; return; }
    if(segundosRestantes < SegundosEvitarFin) { txtEstado = "ESP. CIERRE VELA"; return; }

    double rsi[], ema[];
    ArraySetAsSeries(rsi, true); ArraySetAsSeries(ema, true);
    if(CopyBuffer(handleRSI, 0, 0, 1, rsi) <= 0 || CopyBuffer(handleEMA, 0, 0, 1, ema) <= 0) return;
    
    double close = iClose(_Symbol, TimeframeVela, 0);
    double open = iOpen(_Symbol, TimeframeVela, 0);
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

    double distEMA = (close - ema[0]) / (point * 10);
    bool esVelaVerde = (close > open), esVelaRoja = (close < open);

    if(distEMA > ZonaMuertaPips) {
        if(ConfirmarColorVela && !esVelaVerde) { txtEstado = "ESP. VELA VERDE"; return; }
        if(rsi[0] > RSI_LimiteAgotamiento) { txtEstado = "AGOTADA (RSI)"; return; }
        if(distEMA > DistanciaMaximaEMA) { txtEstado = "MUY LEJOS EMA"; return; }
        txtEstado = "GATILLO COMPRA";
        double sl = NormalizeDouble(ask - (StopLossProteccion / (SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) * LoteBase)) * point, digits);
        for(int i=0; i<BalasPorRafaga; i++) trade.Buy(LoteBase, _Symbol, ask, sl, 0, "EGS_v7.8");
    }
    else if(distEMA < -ZonaMuertaPips) {
        if(ConfirmarColorVela && !esVelaRoja) { txtEstado = "ESP. VELA ROJA"; return; }
        if(rsi[0] < (100 - RSI_LimiteAgotamiento)) { txtEstado = "AGOTADA (RSI)"; return; }
        if(MathAbs(distEMA) > DistanciaMaximaEMA) { txtEstado = "MUY LEJOS EMA"; return; }
        txtEstado = "GATILLO VENTA";
        double sl = NormalizeDouble(bid + (StopLossProteccion / (SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) * LoteBase)) * point, digits);
        for(int i=0; i<BalasPorRafaga; i++) trade.Sell(LoteBase, _Symbol, bid, sl, 0, "EGS_v7.8");
    }
    else { txtEstado = "ZONA DUDOSA EMA"; }
}

void ActualizarPosiciones() {
    ArrayResize(posiciones, 0);
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == 999888) {
            int idx = ArraySize(posiciones); ArrayResize(posiciones, idx + 1);
            posiciones[idx].ticket = ticket; posiciones[idx].profit = PositionGetDouble(POSITION_PROFIT);
            posiciones[idx].tipo = (int)PositionGetInteger(POSITION_TYPE);
            posiciones[idx].precioApertura = PositionGetDouble(POSITION_PRICE_OPEN);
        }
    }
}
double CalcularProfitTotal() { double total = 0; for(int i=0; i<ArraySize(posiciones); i++) total += posiciones[i].profit; return total; }
void CerrarTodo() {
    for(int i=ArraySize(posiciones)-1; i>=0; i--) {
        double p = posiciones[i].profit; if(trade.PositionClose(posiciones[i].ticket)) ganadoHoy += p;
    }
}
void ControlDiario() {
    static int ultimoDia = -1; MqlDateTime dt; TimeCurrent(dt);
    if(dt.day != ultimoDia) { ganadoHoy = 0; ultimoDia = dt.day; }
}
void CrearInterfaz() {
    int base_x = 10, base_y = 10; ENUM_BASE_CORNER corner = CORNER_LEFT_LOWER;
    CrearBoton("EGS_Bg", base_x, base_y, 330, 110, "", clrBlack, clrBlack, corner);
    CrearLabel("EGS_Title", base_x+10, base_y+90, "v7.80 GOLDEN WINDOW PRO", clrGold, 10, corner);
    CrearLabel("EGS_L1", base_x+10, base_y+65, "ESTADO:", clrWhite, 9, corner);
    CrearLabel("EGS_Status", base_x+70, base_y+65, txtEstado, clrGold, 9, corner);
    CrearLabel("EGS_L2", base_x+10, base_y+45, "HOY:", clrWhite, 9, corner);
    CrearLabel("EGS_Ganado", base_x+70, base_y+45, "$0.00", clrLime, 9, corner);
    CrearLabel("EGS_L3", base_x+10, base_y+25, "RAFGAS:", clrWhite, 9, corner);
    CrearLabel("EGS_Cont", base_x+70, base_y+25, "0/6", clrWhite, 9, corner);
    string btnTxt = BotActivo ? "APAGAR BOT" : "ENCENDER BOT";
    color btnCol = BotActivo ? clrMaroon : clrDarkGreen;
    CrearBoton("EGS_BtnPower", base_x+215, base_y+60, 100, 30, btnTxt, btnCol, clrWhite, corner);
    CrearBoton("EGS_BtnPanic", base_x+215, base_y+25, 100, 30, "CERRAR TODO", clrDarkRed, clrWhite, corner);
}
void ActualizarInterfaz() {
    ObjectSetString(0, "EGS_Status", OBJPROP_TEXT, txtEstado);
    ObjectSetString(0, "EGS_Ganado", OBJPROP_TEXT, StringFormat("$%.2f", ganadoHoy));
    ObjectSetString(0, "EGS_Cont", OBJPROP_TEXT, StringFormat("%d/%d OK", contadorRafagasOK, MaxRafagasExito));
    ObjectSetString(0, "EGS_BtnPower", OBJPROP_TEXT, BotActivo ? "APAGAR BOT" : "ENCENDER BOT");
    ObjectSetInteger(0, "EGS_BtnPower", OBJPROP_BGCOLOR, BotActivo ? clrMaroon : clrDarkGreen);
    ChartRedraw();
}
void CrearBoton(string name, int x, int y, int w, int h, string txt, color bg, color fg, ENUM_BASE_CORNER corner) {
    ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0); ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, w); ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg); ObjectSetInteger(0, name, OBJPROP_COLOR, fg);
    ObjectSetString(0, name, OBJPROP_TEXT, txt); ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
}
void CrearLabel(string name, int x, int y, string txt, color col, int size, ENUM_BASE_CORNER corner) {
    ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0); ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetString(0, name, OBJPROP_TEXT, txt); ObjectSetInteger(0, name, OBJPROP_COLOR, col);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
}
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
    if(id == CHARTEVENT_OBJECT_CLICK) {
        if(sparam == "EGS_BtnPower") { BotActivo = !BotActivo; if(BotActivo) esperaGlobal = TimeCurrent() + SegundosPausaInicio; ActualizarInterfaz(); }
        if(sparam == "EGS_BtnPanic") { CerrarTodo(); Print("⚠️ PANIC CLOSE ACTIVADO"); }
        ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
    }
}
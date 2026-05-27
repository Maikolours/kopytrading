//+------------------------------------------------------------------+
//|                 ELITE GOLD HUGO SNIPER v1.0                      |
//|       INSPIRED BY HUGO AI | M1 CLUSTER SCALPING | MACD + RSI    |
//+------------------------------------------------------------------+
#property copyright "Elite Gold HUGO Sniper"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

// ============ PANEL DE CONTROL "HUGO STYLE" ============
input group "=== 👽 CONFIGURACIÓN DE RACIMO (CLUSTERS) ==="
input double   LoteBala = 0.01;                 // Tamaño de cada bala
input int      BalasPorRacimo = 6;              // Cuántas balas en cada ataque (Cluster)
input double   ProfitObjetivo = 2.00;           // Meta de beneficio por racimo ($)
input double   StopLossSeguridad = 4.00;        // SL máximo por racimo ($)

input group "=== 📈 MOTOR DE INTELIGENCIA (M1) ==="
input ENUM_TIMEFRAMES TimeframeM1 = PERIOD_M1;   // Gráfico de ejecución (Sincronizado)
input int      MACD_Fast = 12;                  // MACD Rápido
input int      MACD_Slow = 26;                  // MACD Lento
input int      MACD_Signal = 9;                 // MACD Señal
input int      RSIPeriodo = 14;                 // RSI de agotamiento

input group "=== 🛡️ FILTROS DE PRECISIÓN ==="
input int      EMATendencia = 50;               // Filtro de tendencia (Línea Azul)
input double   RSILimite = 80.0;                // No comprar si RSI > 80 (o vender < 20)
input int      SegundosPausa = 15;              // Pausa entre ataques (Racimos)

input group "=== 💰 GESTIÓN DIARIA ==="
input double   MetaDiaria = 50.0;               // Ganancia objetivo del día ($)
input double   StopDiario = 30.0;               // Pérdida máxima del día ($)

// Variables Globales
CTrade         trade;
struct PosicionSimple { ulong ticket; double lote; double profit; int tipo; };
PosicionSimple posiciones[];
double         profitTotal = 0, ganadoHoy = 0;
bool           BotActivo = false;
string         txtEstado = "INICIANDO HUGO";
datetime       esperaProximoRacimo = 0;

// Handles
int            handleMACD, handleRSI, handleEMA;

//+------------------------------------------------------------------+
int OnInit()
{
    handleMACD = iMACD(_Symbol, TimeframeM1, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE);
    handleRSI = iRSI(_Symbol, TimeframeM1, RSIPeriodo, PRICE_CLOSE);
    handleEMA = iMA(_Symbol, TimeframeM1, EMATendencia, 0, MODE_EMA, PRICE_CLOSE);
    
    trade.SetExpertMagicNumber(777666); // ID Único de Hugo Sniper
    trade.SetTypeFilling(ORDER_FILLING_FOK);
    
    CrearInterfazHugo();
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) { ObjectsDeleteAll(0, "HUGO_"); ChartRedraw(); }

//+------------------------------------------------------------------+
void OnTick()
{
    ControlDiario();
    ActualizarPosiciones();
    profitTotal = CalcularProfitTotal();
    ActualizarInterfazHugo();
    
    if(!BotActivo) { txtEstado = "HUGO EN PAUSA"; return; }
    
    // Escudo Diario
    if(ganadoHoy <= -StopDiario) { CerrarTodo(); BotActivo = false; txtEstado = "STOP DIARIO"; return; }
    if(ganadoHoy >= MetaDiaria) { CerrarTodo(); BotActivo = false; txtEstado = "META DIARIA OK"; return; }

    // Pausa entre ráfagas
    if(TimeCurrent() < esperaProximoRacimo) { txtEstado = "HUGO ANALIZANDO..."; return; }

    // Cierre por Meta de Racimo
    if(profitTotal >= ProfitObjetivo)
    {
        CerrarTodo();
        esperaProximoRacimo = TimeCurrent() + SegundosPausa;
        Print("🚀 RACIMO COMPLETADO CON ÉXITO.");
        return;
    }
    
    // Si perdemos por SL
    if(ArraySize(posiciones) == 0 && profitTotal <= -StopLossSeguridad)
    {
        esperaProximoRacimo = TimeCurrent() + 60; // 1 min de calma tras perder
        return;
    }

    if(ArraySize(posiciones) == 0) EvaluarEntradaHugo();
}

//+------------------------------------------------------------------+
void EvaluarEntradaHugo()
{
    double macdMain[], macdSignal[], rsi[], ema[];
    ArraySetAsSeries(macdMain, true); ArraySetAsSeries(macdSignal, true);
    ArraySetAsSeries(rsi, true); ArraySetAsSeries(ema, true);
    
    if(CopyBuffer(handleMACD, 0, 0, 2, macdMain) <= 0) return;
    if(CopyBuffer(handleMACD, 1, 0, 2, macdSignal) <= 0) return;
    if(CopyBuffer(handleRSI, 0, 0, 1, rsi) <= 0) return;
    if(CopyBuffer(handleEMA, 0, 0, 1, ema) <= 0) return;
    
    double close = iClose(_Symbol, TimeframeM1, 0);
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

    // LÓGICA DE GATILLO (HUGO STYLE)
    // 1. MACD Cruce o Dirección
    bool impulsoAlcista = (macdMain[0] > macdSignal[0] && macdMain[0] > 0);
    bool impulsoBajista = (macdMain[0] < macdSignal[0] && macdMain[0] < 0);
    
    // 2. EMA Filtro
    bool tendenciaArriba = (close > ema[0]);
    bool tendenciaAbajo = (close < ema[0]);

    // DISPARO EN RACIMO (CLUSTERS)
    
    // RACIMO DE COMPRA
    if(impulsoAlcista && tendenciaArriba)
    {
        if(rsi[0] > RSILimite) { txtEstado = "AGOTADO (RSI)"; return; }
        
        txtEstado = "ATAQUE RACIMO COMPRA";
        double sl = NormalizeDouble(ask - (StopLossSeguridad / (SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) * LoteBala)) * point, digits);
        for(int i=0; i<BalasPorRacimo; i++) 
        {
            trade.Buy(LoteBala, _Symbol, ask, sl, 0, "HUGO_SNIPER");
        }
    }
    // RACIMO DE VENTA
    else if(impulsoBajista && tendenciaAbajo)
    {
        if(rsi[0] < (100 - RSILimite)) { txtEstado = "AGOTADO (RSI)"; return; }
        
        txtEstado = "ATAQUE RACIMO VENTA";
        double sl = NormalizeDouble(bid + (StopLossSeguridad / (SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) * LoteBala)) * point, digits);
        for(int i=0; i<BalasPorRacimo; i++) 
        {
            trade.Sell(LoteBala, _Symbol, bid, sl, 0, "HUGO_SNIPER");
        }
    }
    else { txtEstado = "HUGO BUSCANDO SEÑAL"; }
}

void ActualizarPosiciones()
{
    ArrayResize(posiciones, 0);
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == 777666) {
            int idx = ArraySize(posiciones); ArrayResize(posiciones, idx + 1);
            posiciones[idx].ticket = ticket; posiciones[idx].profit = PositionGetDouble(POSITION_PROFIT);
            posiciones[idx].tipo = (int)PositionGetInteger(POSITION_TYPE);
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

void CrearInterfazHugo()
{
    int base_x = 10, base_y = 10;
    ENUM_BASE_CORNER corner = CORNER_LEFT_LOWER;
    CrearBoton("HUGO_Bg", base_x, base_y, 330, 110, "", clrBlack, clrBlack, corner);
    CrearLabel("HUGO_Title", base_x+10, base_y+90, "🛸 ELITE GOLD HUGO SNIPER v1.0", clrLime, 10, corner);
    CrearLabel("HUGO_L1", base_x+10, base_y+65, "ESTADO:", clrWhite, 9, corner);
    CrearLabel("HUGO_Status", base_x+70, base_y+65, txtEstado, clrLime, 9, corner);
    CrearLabel("HUGO_L2", base_x+10, base_y+45, "HOY:", clrWhite, 9, corner);
    CrearLabel("HUGO_Ganado", base_x+70, base_y+45, "$0.00", clrLime, 9, corner);
    CrearLabel("HUGO_L3", base_x+10, base_y+25, "PROFIT:", clrWhite, 9, corner);
    CrearLabel("HUGO_Flot", base_x+70, base_y+25, "$0.00", clrWhite, 9, corner);
    string btnTxt = BotActivo ? "APAGAR HUGO" : "ENCENDER HUGO";
    CrearBoton("HUGO_BtnPower", base_x+215, base_y+60, 100, 30, btnTxt, BotActivo ? clrMaroon : clrDarkGreen, clrWhite, corner);
    CrearBoton("HUGO_BtnPanic", base_x+215, base_y+25, 100, 30, "PANIC CLOSE", clrDarkRed, clrWhite, corner);
}

void ActualizarInterfazHugo()
{
    ObjectSetString(0, "HUGO_Status", OBJPROP_TEXT, txtEstado);
    ObjectSetString(0, "HUGO_Ganado", OBJPROP_TEXT, StringFormat("$%.2f", ganadoHoy));
    ObjectSetString(0, "HUGO_Flot", OBJPROP_TEXT, StringFormat("$%.2f", profitTotal));
    ObjectSetInteger(0, "HUGO_Flot", OBJPROP_COLOR, profitTotal >= 0 ? clrLime : clrRed);
    ObjectSetString(0, "HUGO_BtnPower", OBJPROP_TEXT, BotActivo ? "APAGAR HUGO" : "ENCENDER HUGO");
    ObjectSetInteger(0, "HUGO_BtnPower", OBJPROP_BGCOLOR, BotActivo ? clrMaroon : clrDarkGreen);
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
        if(sparam == "HUGO_BtnPower") { BotActivo = !BotActivo; ActualizarInterfazHugo(); }
        if(sparam == "HUGO_BtnPanic") { CerrarTodo(); Print("⚠️ HUGO PANIC CLOSE"); }
        ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
    }
}

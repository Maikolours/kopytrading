//+------------------------------------------------------------------+
//|                MAIKO SNIPER PRO | EDITION REAL CENT             |
//|      "BUTTON FIX & SOFT RECOVERY" | VERSION 11.99 FINAL         |
//+------------------------------------------------------------------+
#property copyright "Elite Gold MAIKO Sniper"
#property version   "11.99"
#property strict

#include <Trade\Trade.mqh>

// --- CONFIGURACION ---
input string MiLicencia = "23449251"; 
input bool CUENTA_REAL_CENT = true; 
input datetime FechaInicioMaiko = D'2026.05.07 00:00'; 

// --- FILTROS DE TENDENCIA ---
input int PeriodoEMA = 50;
input bool CheckH1 = true;
input bool CheckM15 = true;
input bool CheckM5 = true;
input bool UsarMACD = true;

// --- FILTROS SNIPER ---
input double MinCuerpoVelaPips = 1.0; 
input double MaxSpreadPips = 4.0; 
input int RSI_Periodo = 14;

// --- GESTION DE LOTAJE ---
input double LotajeInicial = 0.02; // Lote inicial en Cent
input double MultiplicadorRefuerzo = 1.0; 
input double MaxLoteIndividual = 0.03; // Lote fijo lineal por SOS en Cent
input double MaxLoteTotal = 0.45; 
input int LimitePosicionesSOS = 15; 

// --- HORARIO DE SESION ---
input bool UsarFiltroHorario = false; // Activar Filtro Horario de Sesion
input int HoraInicioSesion = 9;       // Hora de inicio de sesion (09:00)
input int HoraFinSesion = 22;         // Hora de fin de sesion (22:00)
input bool BloquearViernesNoche = true; // Evitar Nuevas Entradas Viernes Noche (Recomendado)
input bool CerrarViernesNoche = false; // Cierre forzado Viernes Noche (Fin de semana)
input int HoraCierreViernes = 21;     // Hora limite los viernes (21:00)

// --- OBJETIVOS DE PROFIT ---
input double ProfitCosechaCents = 10.0; // Ajustado a 10.0 céntimos (como tu configuración)
input double ProfitNetoCents = 10.0; // Ajustado a 10.0 céntimos (como tu configuración)
input double DistanciaRefuerzoPips = 30.0; 

// --- HUD ---
input color ColorMain = clrGold;
input color ColorHeader = C'30,30,30';
input color ColorBody = C'15,15,15';
input int HUD_X = 15;
input int PosY_HUD = 25;
input string TradeComment = "MAIKO_CENT_V11";

// Globales
CTrade trade;
const int ExpertMagic = 111222;
struct PosInfo { ulong ticket; double p; int t; double v; double pr; double tp; };
PosInfo pos[];
double ganadoPeriodo = 0, flotante = 0, volTotal = 0, spreadActual = 0, rsiActual = 0, macdActual = 0;
bool BotActivo = false;
bool hudMinimizado = false;
string txtVoz = "SISTEMA ONLINE.";
string txtVeredicto = "ESPERANDO...";
string txtAnalisisVela = "ANALIZANDO...";
datetime ultimoSOS = 0;
int hEMA_H1, hEMA_M15, hEMA_M5, hRSI, hMACD;
int hRadar[7];
ENUM_TIMEFRAMES etfs[]={PERIOD_W1,PERIOD_D1,PERIOD_H4,PERIOD_H1,PERIOD_M15,PERIOD_M5,PERIOD_M1};

int idxPeriodo = 0;
string labelPeriodo[] = {"HOY (NETO)", "ESTA SEMANA", "ESTE MES", "MAIKO PROFIT"};

int OnInit() {
    ObjectsDeleteAll(0, "MAIKO_");
    trade.SetExpertMagicNumber(ExpertMagic);
    hEMA_H1 = iMA(_Symbol, PERIOD_H1, PeriodoEMA, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_M15 = iMA(_Symbol, PERIOD_M15, PeriodoEMA, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_M5 = iMA(_Symbol, PERIOD_M5, PeriodoEMA, 0, MODE_EMA, PRICE_CLOSE);
    hRSI = iRSI(_Symbol, PERIOD_M5, 14, PRICE_CLOSE); // RSI en M5
    hMACD = iMACD(_Symbol, PERIOD_M15, 12, 26, 9, PRICE_CLOSE); // MACD en M15
    for(int i=0; i<7; i++) hRadar[i] = iMA(_Symbol, etfs[i], PeriodoEMA, 0, MODE_EMA, PRICE_CLOSE);
    ChartSetInteger(0, CHART_SHOW_TRADE_HISTORY, false);
    CrearInterfazMaster();
    EventSetTimer(1); // Actualizar interfaz cada segundo (útil en mercados cerrados)
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) { 
    ObjectsDeleteAll(0, "MAIKO_"); 
    EventKillTimer(); 
}

int AnalizarPatronPriceAction(ENUM_TIMEFRAMES tf, int shift) {
    double open = iOpen(_Symbol, tf, shift);
    double close = iClose(_Symbol, tf, shift);
    double body = MathAbs(close - open);
    if(body < MinCuerpoVelaPips * _Point * 10) return 0; 
    return (close > open ? 2 : -2);
}

void OnTick() {
    ActualizarEstadoMaster();
    ganadoPeriodo = CalcularGanadoUltraPreciso(idxPeriodo);
    flotante = CalcularProfit();
    spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point / 10;
    
    // CHEQUEO CIERRE FORZADO DE VIERNES (Si está activo)
    MqlDateTime dt; TimeCurrent(dt);
    if(CerrarViernesNoche && dt.day_of_week == 5 && dt.hour >= HoraCierreViernes) {
        if(ArraySize(pos) > 0) {
            txtVoz = "CIERRE FIN DE SEMANA ⚠️";
            CerrarTodo();
            return;
        }
    }
    double rsi_buf[1], macd_buf[1], emaH1[1], emaM15[1], emaM5[1];
    CopyBuffer(hRSI, 0, 0, 1, rsi_buf); rsiActual = rsi_buf[0];
    CopyBuffer(hMACD, 0, 0, 1, macd_buf); macdActual = macd_buf[0];
    CopyBuffer(hEMA_H1, 0, 0, 1, emaH1);
    CopyBuffer(hEMA_M15, 0, 0, 1, emaM15);
    CopyBuffer(hEMA_M5, 0, 0, 1, emaM5);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    int direccion = 0; 
    bool condBuy = (rsiActual > 50);
    bool condSell = (rsiActual < 50);
    
    if(CheckH1) { condBuy = condBuy && (bid > emaH1[0]); condSell = condSell && (bid < emaH1[0]); }
    if(CheckM15) { condBuy = condBuy && (bid > emaM15[0]); condSell = condSell && (bid < emaM15[0]); }
    if(CheckM5) { condBuy = condBuy && (bid > emaM5[0]); condSell = condSell && (bid < emaM5[0]); }
    if(UsarMACD) { condBuy = condBuy && (macdActual > 0); condSell = condSell && (macdActual < 0); }

    if(condBuy) direccion = 1; else if(condSell) direccion = -1;

    int p0 = AnalizarPatronPriceAction(PERIOD_M1, 0);
    if(p0 == 0) txtAnalisisVela = "M1: ACUMULACION / DOJI";
    else txtAnalisisVela = (p0 == 2 ? "M1: FUERZA ALCISTA" : "M1: FUERZA BAJISTA");

    // SOFT RECOVERY LÓGICA
    double metaCesta = (ArraySize(pos) >= LimitePosicionesSOS) ? 25.0 : ProfitNetoCents;
    if(ArraySize(pos) > 0 && flotante >= metaCesta) { 
        txtVoz = "CIERRE DE CESTA."; CerrarTodo(); return; 
    }
    GestionarCosechaSniper(); 
    ActualizarRadarMaster();
    ActualizarInterfazMaster();
    
    // CONGELACIÓN DE NUEVAS ENTRADAS EL VIERNES NOCHE (PERMITIENDO CIERRES ANTES)
    if(BloquearViernesNoche && dt.day_of_week == 5 && dt.hour >= HoraCierreViernes) {
        txtVeredicto = "VIERNES NOCHE: BLOQUEADO";
        if(ArraySize(pos) > 0) {
            txtVoz = StringFormat("CONGELADO FIN DE SEMANA (%d pos abiertas)", ArraySize(pos));
        } else {
            txtVoz = "MERCADO CERRADO / ESPERANDO";
        }
        ActualizarInterfazMaster();
        return;
    }

    if(!BotActivo) { txtVoz = "SISTEMA EN PAUSA."; return; }
    
    if(ArraySize(pos) > 0) { 
        txtVoz = StringFormat("VIGILANDO (%d/%d) SOS", ArraySize(pos), LimitePosicionesSOS);
        GestionarRefuerzoInteligente(); 
    } else {
        if(spreadActual > MaxSpreadPips) { txtVeredicto = "SPREAD ALTO"; return; }
        if(direccion == 0) { txtVeredicto = "FILTRANDO TENDENCIA..."; return; }
        
        int pM5 = AnalizarPatronPriceAction(PERIOD_M5, 1);
        int pM1 = AnalizarPatronPriceAction(PERIOD_M1, 1);
        
        txtVoz = (direccion == 1) ? "BUSCANDO MOMENTO COMPRA..." : "BUSCANDO MOMENTO VENTA...";

        if(direccion == 1 && pM5 == 2 && pM1 == 2) {
            trade.Buy(LotajeInicial, _Symbol, 0, 0, 0, TradeComment);
            txtVoz = "COMPRA SNIPER!";
        }
        else if(direccion == -1 && pM5 == -2 && pM1 == -2) {
            trade.Sell(LotajeInicial, _Symbol, 0, 0, 0, TradeComment);
            txtVoz = "VENTA SNIPER!";
        } else txtVeredicto = "ESPERANDO CONFIRMACION M5/M1";
    }
}

void GestionarRefuerzoInteligente() {
    if(ArraySize(pos) >= LimitePosicionesSOS || volTotal >= MaxLoteTotal) { txtVeredicto = "RIESGO MAXIMO (LOCK)"; return; }
    if(TimeCurrent() - ultimoSOS < 60) return;
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double distPips = MathAbs((pos[0].t==POSITION_TYPE_BUY ? bid : ask) - pos[0].pr) / _Point / 10;
    if(distPips < DistanciaRefuerzoPips) { txtVeredicto = StringFormat("DIST. SOS: %.1f/%.0f", distPips, DistanciaRefuerzoPips); return; }
    int pat = AnalizarPatronPriceAction(PERIOD_M1, 1);
    bool confirmado = (pos[0].t == POSITION_TYPE_BUY) ? (pat == 2) : (pat == -2);
    if(!confirmado) { txtVeredicto = "ESPERANDO GIRO M1"; return; }
    double volRef = MaxLoteIndividual; 
    if(volTotal + volRef > MaxLoteTotal) volRef = NormalizeDouble(MaxLoteTotal - volTotal, 2); 
    if(volRef >= 0.01) {
        if(pos[0].t == POSITION_TYPE_BUY) trade.Buy(volRef, _Symbol, 0, 0, 0, TradeComment + "_SOS");
        else trade.Sell(volRef, _Symbol, 0, 0, 0, TradeComment + "_SOS");
        ultimoSOS = TimeCurrent();
    }
}

void GestionarCosechaSniper() { 
    for(int i=ArraySize(pos)-1; i>=0; i--) {
        if(pos[i].tp > 0) continue; 
        double profitObjetivo = (pos[i].v / 0.01) * ProfitCosechaCents;
        if(pos[i].p >= profitObjetivo) trade.PositionClose(pos[i].ticket); 
    }
}

double CalcularProfit() { double s=0; for(int i=0; i<ArraySize(pos); i++) s += pos[i].p; return s; }

double CalcularGanadoUltraPreciso(int modo) {
    datetime start = 0;
    MqlDateTime dt; TimeCurrent(dt);
    if(modo == 0) { dt.hour=0; dt.min=0; dt.sec=0; start = StructToTime(dt); }
    else if(modo == 1) { 
        int dow = dt.day_of_week; if(dow == 0) dow = 7;
        start = TimeCurrent() - (dow-1)*86400;
        MqlDateTime sw; TimeToStruct(start, sw); sw.hour=0; sw.min=0; sw.sec=0; start = StructToTime(sw);
    }
    else if(modo == 2) { dt.day=1; dt.hour=0; dt.min=0; dt.sec=0; start = StructToTime(dt); }
    else if(modo == 3) { start = FechaInicioMaiko; }
    double total = 0; HistorySelect(start, TimeCurrent()); 
    for(int i=HistoryDealsTotal()-1; i>=0; i--) {
        ulong t = HistoryDealGetTicket(i);
        // PARCHE DE SEGURIDAD HISTORICA: Filtro por Magic Number y Símbolo
        if(HistoryDealGetString(t, DEAL_SYMBOL) != _Symbol || HistoryDealGetInteger(t, DEAL_MAGIC) != ExpertMagic) continue;
        total += HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_SWAP) + HistoryDealGetDouble(t, DEAL_COMMISSION); 
    }
    return total;
}

void CerrarTodo() { for(int i=ArraySize(pos)-1; i>=0; i--) trade.PositionClose(pos[i].ticket); }

void ActualizarRadarMaster() { 
    string tfs[]={"W1","D1","H4","H1","M15","M5","M1"}; 
    double pr = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    for(int i=0; i<7; i++) { 
        double buf[1]; color col = clrGray; 
        if(CopyBuffer(hRadar[i], 0, 0, 1, buf) > 0) col = (pr > buf[0]) ? clrSpringGreen : clrRed;
        ObjectSetInteger(0, "MAIKO_Radar_"+tfs[i], OBJPROP_COLOR, col); 
    } 
}

void ActualizarEstadoMaster() { 
    ArrayResize(pos, 0); volTotal = 0; 
    for(int i=PositionsTotal()-1; i>=0; i--) {
        ulong t = PositionGetTicket(i);
        // PARCHE DE SEGURIDAD ACTIVA: Filtro por Símbolo y Magic Number
        if(PositionSelectByTicket(t) && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == ExpertMagic) { 
            int idx = ArraySize(pos); ArrayResize(pos, idx+1); 
            pos[idx].ticket = t; 
            pos[idx].p = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP) + PositionGetDouble(POSITION_COMMISSION); 
            pos[idx].t = (int)PositionGetInteger(POSITION_TYPE); pos[idx].v = PositionGetDouble(POSITION_VOLUME); 
            pos[idx].pr = PositionGetDouble(POSITION_PRICE_OPEN); 
            pos[idx].tp = PositionGetDouble(POSITION_TP);
            volTotal += pos[idx].v; 
        } 
    }
}

void CrearInterfazMaster() { 
    int x = HUD_X, y = PosY_HUD, w = 400, h = 330; 
    ObjectCreate(0, "MAIKO_Bg", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_XDISTANCE, x); ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_XSIZE, w); ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_YSIZE, h);
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_BGCOLOR, ColorBody); ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_ZORDER, 9999); 
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_BACK, false);
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_BORDER_TYPE, BORDER_FLAT);
    CrearBoton("MAIKO_Head", x, y, w, 35, "", ColorHeader, clrNONE, 10000); 
    CrearLabel("MAIKO_T", x+10, y+10, "MAIKO PRO | CENT v11.99", ColorMain, 11, 10001); 
    CrearBoton("MAIKO_BtnMin", x+w-35, y+5, 30, 25, "_", clrGray, clrWhite, 10010);
    string rads[]={"W1","D1","H4","H1","M15","M5","M1"};
    for(int i=0; i<7; i++) {
        CrearLabel("MAIKO_L_"+rads[i], x+15+(i/4)*100, y+45+(i%4)*20, rads[i]+":", clrWhite, 8, 10001);
        CrearLabel("MAIKO_Radar_"+rads[i], x+45+(i/4)*100, y+45+(i%4)*20, "o", clrGray, 10, 10001);
    }
    CrearLabel("MAIKO_M1", x+15, y+135, txtAnalisisVela, clrWhite, 8, 10001); 
    CrearLabel("MAIKO_Vered", x+15, y+150, txtVeredicto, clrCyan, 9, 10001); 
    CrearLabel("MAIKO_SPD", x+w-120, y+135, "SPD: 0.0", clrWhite, 8, 10001);
    CrearLabel("MAIKO_RSI", x+w-120, y+45, "RSI: 0.0", clrOrange, 9, 10001);
    CrearLabel("MAIKO_LVol", x+w-120, y+65, "VOL TOTAL:", clrWhite, 8, 10001);
    CrearLabel("MAIKO_Hoy", x+15, y+175, "GANADO HOY: $0.00", clrSpringGreen, 14, 10001); 
    CrearLabel("MAIKO_Rend", x+15, y+200, "RENDIMIENTO: 0.00%", clrWhite, 8, 10001); 
    CrearLabel("MAIKO_Flotante", x+15, y+220, "FLOTANTE: $0.00", clrWhite, 12, 10001); 
    CrearLabel("MAIKO_Voz", x+15, y+295, txtVoz, clrGold, 10, 10001); 
    CrearBoton("MAIKO_BtnHist", x+15, y+255, 140, 25, "CAMBIAR VISTA", clrGray, clrWhite, 10010);
    CrearBoton("MAIKO_BtnP", x+w-120, y+165, 110, 50, "ENCENDER", clrDarkGreen, clrWhite, 10010); 
    CrearBoton("MAIKO_BtnC", x+w-120, y+225, 110, 35, "CERRAR", clrDarkRed, clrWhite, 10010); 
}

void ActualizarInterfazMaster() { 
    double divisor = CUENTA_REAL_CENT ? 100.0 : 1.0;
    string unit = CUENTA_REAL_CENT ? "$" : "";
    ObjectSetString(0, "MAIKO_Hoy", OBJPROP_TEXT, StringFormat("%s: %s%.2f", labelPeriodo[idxPeriodo], unit, ganadoPeriodo / divisor)); 
    ObjectSetString(0, "MAIKO_Flotante", OBJPROP_TEXT, StringFormat("FLOTANTE: %s%.2f", unit, flotante / divisor)); 
    ObjectSetInteger(0, "MAIKO_Flotante", OBJPROP_COLOR, flotante >= 0 ? clrSpringGreen : clrRed); 
    ObjectSetString(0, "MAIKO_M1", OBJPROP_TEXT, txtAnalisisVela);
    ObjectSetString(0, "MAIKO_Vered", OBJPROP_TEXT, txtVeredicto);
    ObjectSetString(0, "MAIKO_SPD", OBJPROP_TEXT, StringFormat("SPD: %.1f", spreadActual));
    ObjectSetString(0, "MAIKO_RSI", OBJPROP_TEXT, StringFormat("RSI: %.1f", rsiActual));
    ObjectSetString(0, "MAIKO_LVol", OBJPROP_TEXT, StringFormat("VOL: %.2f/%.2f", volTotal, MaxLoteTotal));
    ObjectSetString(0, "MAIKO_Voz", OBJPROP_TEXT, txtVoz);
    ObjectSetString(0, "MAIKO_BtnP", OBJPROP_TEXT, BotActivo ? "ENCENDIDO" : "ENCENDER");
    ObjectSetInteger(0, "MAIKO_BtnP", OBJPROP_BGCOLOR, BotActivo ? clrRoyalBlue : clrDarkGreen);
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_YSIZE, hudMinimizado ? 35 : 330);
}

void CrearBoton(string n, int x, int y, int w, int h, string t, color bg, color fg, int z) { 
    ObjectCreate(0, n, OBJ_BUTTON, 0, 0, 0); 
    ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, n, OBJPROP_XSIZE, w); ObjectSetInteger(0, n, OBJPROP_YSIZE, h);
    ObjectSetInteger(0, n, OBJPROP_BGCOLOR, bg); ObjectSetInteger(0, n, OBJPROP_COLOR, fg);
    ObjectSetString(0, n, OBJPROP_TEXT, t); ObjectSetInteger(0, n, OBJPROP_ZORDER, z); 
    ObjectSetInteger(0, n, OBJPROP_BACK, false); ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
}

void CrearLabel(string n, int x, int y, string t, color col, int s, int z) { 
    ObjectCreate(0, n, OBJ_LABEL, 0, 0, 0); 
    ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
    ObjectSetString(0, n, OBJPROP_TEXT, t); ObjectSetInteger(0, n, OBJPROP_COLOR, col); 
    ObjectSetInteger(0, n, OBJPROP_FONTSIZE, s); ObjectSetInteger(0, n, OBJPROP_ZORDER, z); 
    ObjectSetInteger(0, n, OBJPROP_BACK, false); ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) { 
    if(id == CHARTEVENT_OBJECT_CLICK) { 
        if(sparam == "MAIKO_BtnP") { BotActivo = !BotActivo; ActualizarInterfazMaster(); }
        if(sparam == "MAIKO_BtnC") CerrarTodo(); 
        if(sparam == "MAIKO_BtnHist") { 
            idxPeriodo++; 
            if(idxPeriodo > 3) idxPeriodo = 0; 
            ganadoPeriodo = CalcularGanadoUltraPreciso(idxPeriodo); // BUG FIX: Recalcular instantáneamente al cambiar la vista
            ActualizarInterfazMaster(); 
        }
        if(sparam == "MAIKO_BtnMin") { hudMinimizado = !hudMinimizado; ActualizarInterfazMaster(); }
        ChartRedraw(); 
    } 
}

// Handler de temporizador para actualizar el HUD en mercados lentos o cerrados
void OnTimer() {
    ActualizarEstadoMaster();
    ganadoPeriodo = CalcularGanadoUltraPreciso(idxPeriodo);
    flotante = CalcularProfit();
    spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point / 10;
    
    double rsi_buf[1], macd_buf[1];
    if(CopyBuffer(hRSI, 0, 0, 1, rsi_buf) > 0) rsiActual = rsi_buf[0];
    if(CopyBuffer(hMACD, 0, 0, 1, macd_buf) > 0) macdActual = macd_buf[0];
    
    ActualizarRadarMaster();
    ActualizarInterfazMaster();
}

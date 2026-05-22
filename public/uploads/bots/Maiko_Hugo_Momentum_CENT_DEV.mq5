//+------------------------------------------------------------------+
//|                MAIKO HUGO MOMENTUM | EDITION REAL CENT            |
//|      "HEDGING BI-DIRECCIONAL M1" | VERSION 15.0                   |
//+------------------------------------------------------------------+
#property copyright "Elite Gold MAIKO Momentum"
#property version   "15.00"
#property strict

#include <Trade\Trade.mqh>

// --- CONFIGURACION ---
input string MiLicencia = "23449251"; 
input bool CUENTA_REAL_CENT = true; 
input datetime FechaInicioMaiko = D'2026.05.07 00:00'; 

// --- GESTIÓN HUGO MOMENTUM (HEDGING & TRAILING) ---
input bool UsarTrailingStop = true;
input double TrailingStartPips = 1.5;    // Pips a favor para activar Trailing (MUY RÁPIDO)
input double TrailingPips = 0.5;         // Distancia del Trailing (PEGADO AL PRECIO)

// --- FILTRO DE NOTICIAS ---
input bool UsarFiltroNoticias = false;   // Por defecto desactivado para no perder entradas
input string HoraProximaNoticia = "14:30"; 
input int MinsAntesNoticia = 15;         
input int MinsDespuesNoticia = 15;       

// --- FILTROS DE ESPERA ---
input double SegundosReAnalisis = 5; // Re-análisis hiper rápido (5 seg)

// --- SINCRONIZACIÓN CON KOPYTRADING.COM ---
input string PurchaseID = "";          // ID de licencia (del dashboard de kopytrading.com)
input string SyncURL = "https://www.kopytrading.com/api/sync-positions";
input int SyncIntervalSec = 5;         // Cada cuántos segundos enviar datos 

// --- NUEVOS FILTROS HORARIOS ---
input bool UsarFiltroHorario = true;
input int HoraInicioSesion = 0;  // 00:00 por defecto para que opere siempre
input int HoraFinSesion = 24;    // 24:00 por defecto

// --- FILTROS SNIPER ---
input double MaxSpreadPips = 4.5; 
input double MinCuerpoVelaPips = 2.0; // Reducido para entrar rápido

// --- GESTION DE LOTAJE ---
input double LotajeInicial = 0.05;   

// --- OBJETIVOS DE PROFIT ---
input double LimiteDiario = 150.0;       // Límite de beneficio diario ($/€)

// --- HUD ---
input color ColorMain = clrAqua; // Color distinto para Hugo
input color ColorHeader = C'30,30,30';
input color BodyColor = C'15,15,15';
input int HUD_X = 15;
input int PosY_HUD = 25;
input string TradeComment = "MAIKO_HUGO_HEDGE";

// Globales
CTrade trade;
const int ExpertMagic = 777888; // Magic Number Distinto
struct PosInfo { ulong ticket; double p; int t; double v; double pr; double tp; double sl; };
PosInfo pos[];
double ganadoPeriodo = 0, flotante = 0, volTotal = 0, spreadActual = 0, rsiActual = 0;
bool BotActivo = false;
bool hudMinimizado = false;
bool bloqueadoPorNoticia = false;
datetime ultimaCestaCerrada = 0;
string txtVoz = "SISTEMA ONLINE.";
string txtVeredicto = "ESPERANDO...";
string txtConsolidado = "HEDGING BIDIRECCIONAL M1";
string txtProteccion = "TRAILING INDIVIDUAL ACTIVADO ⚡"; 

int hEMA_H1, hEMA_M15, hEMA_M5, hEMA_M1, hEMA_M1_9, hRSI, hATR;
int hRadar[7];
ENUM_TIMEFRAMES etfs[]={PERIOD_W1,PERIOD_D1,PERIOD_H4,PERIOD_H1,PERIOD_M15,PERIOD_M5,PERIOD_M1};
double equityPeak = 0;

int idxPeriodo = 0;
string labelPeriodo[] = {"HOY (NETO)", "ESTA SEMANA", "ESTE MES", "MAIKO PROFIT"};
datetime ultimoSync = 0;

int OnInit() {
    ObjectsDeleteAll(0, "MAIKO_");
    trade.SetExpertMagicNumber(ExpertMagic);
    equityPeak = AccountInfoDouble(ACCOUNT_EQUITY);
    hEMA_H1 = iMA(_Symbol, PERIOD_H1, 50, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_M15 = iMA(_Symbol, PERIOD_M15, 50, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_M5 = iMA(_Symbol, PERIOD_M5, 50, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_M1 = iMA(_Symbol, PERIOD_M1, 50, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_M1_9 = iMA(_Symbol, PERIOD_M1, 9, 0, MODE_EMA, PRICE_CLOSE);
    hRSI = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);     
    hATR = iATR(_Symbol, _Period, 14);
    for(int i=0; i<7; i++) hRadar[i] = iMA(_Symbol, etfs[i], 50, 0, MODE_EMA, PRICE_CLOSE);
    
    ChartIndicatorAdd(0, 0, hEMA_M1);
    ChartIndicatorAdd(0, 0, hEMA_M1_9);
    
    ChartSetInteger(0, CHART_SHOW_TRADE_HISTORY, false); 
    ChartSetInteger(0, CHART_FOREGROUND, false); 
    EventSetTimer(1);
    CrearInterfazMaster();
    ActualizarEstadoMaster();
    ganadoPeriodo = CalcularGanadoUltraPreciso(idxPeriodo);
    flotante = CalcularProfit();
    ActualizarInterfazMaster();
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) { EventKillTimer(); ObjectsDeleteAll(0, "MAIKO_"); }

void OnTimer() {
    ActualizarEstadoMaster();
    ganadoPeriodo = CalcularGanadoUltraPreciso(idxPeriodo);
    flotante = CalcularProfit();
    ActualizarInterfazMaster();
    ChartRedraw();
    if(StringLen(PurchaseID) > 5 && TimeCurrent() - ultimoSync >= SyncIntervalSec) {
        EnviarTelemetria();
        ultimoSync = TimeCurrent();
    }
}

void EnviarTelemetria() {
    string account = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
    double ganadoHoy = CalcularGanadoUltraPreciso(0);
    string status = BotActivo ? "ONLINE" : "PAUSED";
    int nPos = ArraySize(pos);
    
    string posJson = "[";
    for(int i = 0; i < nPos; i++) {
        if(i > 0) posJson += ",";
        posJson += StringFormat(
            "{\"ticket\":\"%I64u\",\"type\":\"%s\",\"symbol\":\"%s\",\"lots\":%.2f,\"openPrice\":%.5f,\"tp\":%.5f,\"sl\":%.5f,\"profit\":%.2f}",
            pos[i].ticket,
            pos[i].t == POSITION_TYPE_BUY ? "BUY" : "SELL",
            _Symbol, pos[i].v, pos[i].pr, pos[i].tp, pos[i].sl, pos[i].p
        );
    }
    posJson += "]";
    
    string json = StringFormat(
        "{\"purchaseId\":\"%s\",\"account\":\"%s\",\"balance\":%.2f,\"equity\":%.2f,"
        "\"pnl_today\":%.2f,\"status\":\"%s\",\"symbol\":\"%s\",\"narrative\":\"%s\","
        "\"isReal\":true,\"version\":\"15.00\",\"positions\":%s}",
        PurchaseID, account, balance, equity,
        ganadoHoy, status, _Symbol, txtVeredicto, posJson
    );
    
    char postData[];
    StringToCharArray(json, postData, 0, StringLen(json), CP_UTF8);
    char result[];
    string headers = "Content-Type: application/json\r\n";
    string resHeaders;
    WebRequest("POST", SyncURL, headers, 3000, postData, result, resHeaders);
}

bool IsNewsBlocked() {
    if(!UsarFiltroNoticias) return false;
    MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
    datetime newsTime = StringToTime(StringFormat("%04d.%02d.%02d %s", dt.year, dt.mon, dt.day, HoraProximaNoticia));
    long diff = MathAbs(TimeCurrent() - newsTime);
    if(TimeCurrent() < newsTime && (int)diff <= MinsAntesNoticia * 60) return true;
    if(TimeCurrent() > newsTime && (int)diff <= MinsDespuesNoticia * 60) return true;
    return false;
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
    
    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    if(currentEquity > equityPeak) equityPeak = currentEquity;
    
    double ganadoHoyReal = CalcularGanadoUltraPreciso(0);
    double targetLimit = CUENTA_REAL_CENT ? (LimiteDiario * 100.0) : LimiteDiario;
    if((ganadoHoyReal + flotante) >= targetLimit) {
        if(ArraySize(pos) > 0) {
            CerrarTodo();
            ultimaCestaCerrada = TimeCurrent();
        }
        BotActivo = false;
        txtVeredicto = "LÍMITE DIARIO ALCANZADO 🛑";
        txtVoz = "PAUSADO POR LÍMITE DIARIO.";
    }

    spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point / 10;
    bloqueadoPorNoticia = IsNewsBlocked();

    double rsi_buf[1], emaH1[1], emaM15[1], emaM5[1], emaM1[1], emaM1_9[1];
    CopyBuffer(hRSI, 0, 0, 1, rsi_buf); rsiActual = rsi_buf[0];
    CopyBuffer(hEMA_H1, 0, 0, 1, emaH1);
    CopyBuffer(hEMA_M15, 0, 0, 1, emaM15);
    CopyBuffer(hEMA_M5, 0, 0, 1, emaM5);
    CopyBuffer(hEMA_M1, 0, 0, 1, emaM1);
    CopyBuffer(hEMA_M1_9, 0, 0, 1, emaM1_9);
    
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    ActualizarRadarMaster();
    ActualizarInterfazMaster();

    if(!BotActivo) { txtVoz = "SISTEMA EN PAUSA."; return; }
    if(bloqueadoPorNoticia) { txtVoz = "PAUSA POR NOTICIAS."; return; }
    
    // GESTIÓN DE TRAILING INDIVIDUAL
    if(ArraySize(pos) > 0) {
        txtVoz = "VIGILANDO CON TRAILING (HEDGE)...";
        if(UsarTrailingStop) GestionarTrailingStop();
    }
    
    // FILTROS PARA ENTRAR
    long diffEspera = TimeCurrent() - ultimaCestaCerrada;
    if(diffEspera < (long)SegundosReAnalisis) { 
        txtVoz = StringFormat("MEDITANDO (%d seg restantes)...", (int)(SegundosReAnalisis - diffEspera)); 
        return; 
    }

    if(spreadActual > MaxSpreadPips) { txtVeredicto = "SPREAD ALTO"; return; }
    if(UsarFiltroHorario) {
        MqlDateTime dt; TimeCurrent(dt);
        if(dt.hour < HoraInicioSesion || dt.hour >= HoraFinSesion) {
            txtVeredicto = "FUERA DE SESION (DORMIDO)";
            return;
        }
    }

    // CONTAR OPERACIONES ACTUALES PARA MODO HEDGE (MÁXIMO 1 POR SENTIDO)
    int countBuy = 0, countSell = 0;
    for(int i=0; i<ArraySize(pos); i++) {
        if(pos[i].t == POSITION_TYPE_BUY) countBuy++;
        if(pos[i].t == POSITION_TYPE_SELL) countSell++;
    }

    // LOGICA DE ENTRADA HUGO MOMENTUM M1
    int pM1 = AnalizarPatronPriceAction(PERIOD_M1, 1);
    bool buyMomentum = (pM1 == 2 && bid > emaM1_9[0]);
    bool sellMomentum = (pM1 == -2 && bid < emaM1_9[0]);

    if(buyMomentum && countBuy < 1) {
        txtVeredicto = "🚀 MOMENTUM ALCISTA: COMPRANDO";
        trade.Buy(LotajeInicial, _Symbol, 0, 0, 0, TradeComment);
        ultimaCestaCerrada = TimeCurrent();
    } 
    else if(sellMomentum && countSell < 1) {
        txtVeredicto = "💥 MOMENTUM BAJISTA: VENDIENDO";
        trade.Sell(LotajeInicial, _Symbol, 0, 0, 0, TradeComment);
        ultimaCestaCerrada = TimeCurrent();
    } 
    else if (buyMomentum || sellMomentum) {
        txtVeredicto = "MOMENTUM DETECTADO (POSICIONES LLENAS)";
    }
    else {
        txtVeredicto = "ESPERANDO VELAS DE FUERZA (M1)...";
    }
}

void GestionarTrailingStop() {
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    for(int i=0; i<ArraySize(pos); i++) {
        if(pos[i].t == POSITION_TYPE_BUY) {
            double distProfit = (bid - pos[i].pr) / _Point / 10;
            if(distProfit >= TrailingStartPips) {
                double newSL = bid - (TrailingPips * _Point * 10);
                if(pos[i].sl < newSL || pos[i].sl == 0) {
                    trade.PositionModify(pos[i].ticket, newSL, pos[i].tp);
                    txtVeredicto = "TRAILING STOP COMPRA AJUSTADO 📈";
                }
            }
        } 
        else if(pos[i].t == POSITION_TYPE_SELL) {
            double distProfit = (pos[i].pr - ask) / _Point / 10;
            if(distProfit >= TrailingStartPips) {
                double newSL = ask + (TrailingPips * _Point * 10);
                if(pos[i].sl > newSL || pos[i].sl == 0) {
                    trade.PositionModify(pos[i].ticket, newSL, pos[i].tp);
                    txtVeredicto = "TRAILING STOP VENTA AJUSTADO 📉";
                }
            }
        }
    }
}

double CalcularProfit() { double s=0; for(int i=0; i<ArraySize(pos); i++) s += pos[i].p; return s; }

double CalcularGanadoUltraPreciso(int modo) {
    datetime start = 0; MqlDateTime dt; TimeCurrent(dt);
    if(modo == 0) { dt.hour=0; dt.min=0; dt.sec=0; start = StructToTime(dt); }
    else if(modo == 1) { int dow = dt.day_of_week; if(dow == 0) dow = 7; start = TimeCurrent() - (dow-1)*86400; MqlDateTime sw; TimeToStruct(start, sw); sw.hour=0; sw.min=0; sw.sec=0; start = StructToTime(sw); }
    else if(modo == 2) { dt.day=1; dt.hour=0; dt.min=0; dt.sec=0; start = StructToTime(dt); }
    else if(modo == 3) { start = FechaInicioMaiko; }
    double total = 0; HistorySelect(start, TimeCurrent()); 
    for(int i=HistoryDealsTotal()-1; i>=0; i--) {
        ulong t = HistoryDealGetTicket(i); if(HistoryDealGetString(t, DEAL_SYMBOL) != _Symbol) continue;
        total += HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_SWAP) + HistoryDealGetDouble(t, DEAL_COMMISSION); 
    }
    return total;
}

void CerrarTodo() { for(int i=ArraySize(pos)-1; i>=0; i--) trade.PositionClose(pos[i].ticket); }

void ActualizarRadarMaster() { 
    string tfs[]={"W1","D1","H4","H1","M15","M5","M1"}; double pr = SymbolInfoDouble(_Symbol, SYMBOL_BID);
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
        if(PositionSelectByTicket(t) && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == ExpertMagic) { 
            int idx = ArraySize(pos); ArrayResize(pos, idx+1); pos[idx].ticket = t; 
            pos[idx].p = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP) + PositionGetDouble(POSITION_COMMISSION); 
            pos[idx].t = (int)PositionGetInteger(POSITION_TYPE); pos[idx].v = PositionGetDouble(POSITION_VOLUME); 
            pos[idx].pr = PositionGetDouble(POSITION_PRICE_OPEN); pos[idx].tp = PositionGetDouble(POSITION_TP);
            pos[idx].sl = PositionGetDouble(POSITION_SL);
            volTotal += pos[idx].v; 
        } 
    }
}

void CrearInterfazMaster() { 
    int x = HUD_X, y = PosY_HUD, w = 400, h = 360; 
    ObjectCreate(0, "MAIKO_Bg", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_XDISTANCE, x); ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_XSIZE, w); ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_YSIZE, h);
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_BGCOLOR, BodyColor); ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_ZORDER, 9999); ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_BACK, false);
    CrearBoton("MAIKO_Head", x, y, w, 35, "", ColorHeader, clrNONE, 10000); 
    CrearLabel("MAIKO_T", x+10, y+10, "MAIKO HUGO MOMENTUM v15.0", ColorMain, 11, 10001); 
    CrearBoton("MAIKO_BtnMin", x+w-35, y+5, 30, 25, "_", clrGray, clrWhite, 10010);
    string rads[]={"W1","D1","H4","H1","M15","M5","M1"};
    for(int i=0; i<7; i++) {
        CrearLabel("MAIKO_L_"+rads[i], x+15+(i/4)*100, y+45+(i%4)*20, rads[i]+":", clrWhite, 8, 10001);
        CrearLabel("MAIKO_Radar_"+rads[i], x+45+(i/4)*100, y+45+(i%4)*20, "o", clrGray, 10, 10001);
    }
    CrearLabel("MAIKO_Consol", x+15, y+135, txtConsolidado, clrCyan, 9, 10001); 
    CrearLabel("MAIKO_Protec", x+15, y+152, txtProteccion, clrOrange, 8, 10001); 
    CrearLabel("MAIKO_Vered", x+15, y+168, txtVeredicto, clrWhite, 8, 10001); 
    
    CrearLabel("MAIKO_Hoy", x+15, y+185, "GANADO HOY: 0.00", clrSpringGreen, 12, 10001); 
    CrearLabel("MAIKO_Flotante", x+15, y+205, "FLOTANTE: 0.00", clrWhite, 11, 10001); 
    
    CrearLabel("MAIKO_DD", x+15, y+239, "PICO DD: --", clrOrange, 8, 10001);
    
    CrearLabel("MAIKO_Voz", x+15, y+320, txtVoz, clrGold, 10, 10001); 
    CrearLabel("MAIKO_SPD", x+w-120, y+135, "SPD: 0.0", clrWhite, 8, 10001);
    CrearLabel("MAIKO_RSI", x+w-120, y+45, "RSI: 0.0", clrOrange, 9, 10001);
    CrearLabel("MAIKO_LVol", x+w-120, y+65, "VOL TOTAL:", clrWhite, 8, 10001);
    CrearBoton("MAIKO_BtnHist", x+15, y+296, 140, 22, "CAMBIAR VISTA", clrGray, clrWhite, 10010);
    CrearBoton("MAIKO_BtnP", x+w-120, y+165, 110, 50, "ENCENDER", clrDarkGreen, clrWhite, 10010); 
    CrearBoton("MAIKO_BtnC", x+w-120, y+225, 110, 35, "CERRAR TODO", clrDarkRed, clrWhite, 10010); 
}

void ActualizarInterfazMaster() { 
    ObjectSetString(0, "MAIKO_Hoy", OBJPROP_TEXT, StringFormat("%s: %.2f", labelPeriodo[idxPeriodo], ganadoPeriodo)); 
    ObjectSetString(0, "MAIKO_Flotante", OBJPROP_TEXT, StringFormat("FLOTANTE: %.2f", flotante)); 
    ObjectSetInteger(0, "MAIKO_Flotante", OBJPROP_COLOR, flotante >= 0 ? clrSpringGreen : clrRed);
    
    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    double ddPercent = (equityPeak > 0) ? (((equityPeak - currentEquity) / equityPeak) * 100.0) : 0.0;
    ObjectSetString(0, "MAIKO_DD", OBJPROP_TEXT, StringFormat("PICO DD: %.2f%%", ddPercent));
    
    ObjectSetString(0, "MAIKO_Consol", OBJPROP_TEXT, txtConsolidado);
    ObjectSetString(0, "MAIKO_Protec", OBJPROP_TEXT, txtProteccion);
    ObjectSetString(0, "MAIKO_Vered", OBJPROP_TEXT, txtVeredicto);
    ObjectSetString(0, "MAIKO_SPD", OBJPROP_TEXT, StringFormat("SPD: %.1f", spreadActual));
    ObjectSetString(0, "MAIKO_RSI", OBJPROP_TEXT, StringFormat("RSI: %.1f", rsiActual));
    ObjectSetString(0, "MAIKO_LVol", OBJPROP_TEXT, StringFormat("VOL: %.2f", volTotal));
    string displayVoz = txtVoz; color colVoz = clrGold;
    if(bloqueadoPorNoticia) { displayVoz = "PAUSA POR NOTICIAS"; colVoz = clrOrange; }
    else if(!BotActivo) { displayVoz = "SISTEMA EN PAUSA"; colVoz = clrRed; }
    ObjectSetString(0, "MAIKO_Voz", OBJPROP_TEXT, displayVoz); ObjectSetInteger(0, "MAIKO_Voz", OBJPROP_COLOR, colVoz);
    ObjectSetString(0, "MAIKO_BtnP", OBJPROP_TEXT, BotActivo ? "ENCENDIDO" : "ENCENDER");
    ObjectSetInteger(0, "MAIKO_BtnP", OBJPROP_BGCOLOR, BotActivo ? clrRoyalBlue : clrDarkGreen);
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_YSIZE, hudMinimizado ? 35 : 360);
    ChartSetInteger(0, CHART_FOREGROUND, false); 
}

void CrearBoton(string n, int x, int y, int w, int h, string t, color bg, color fg, int z) { 
    ObjectCreate(0, n, OBJ_BUTTON, 0, 0, 0); ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, n, OBJPROP_XSIZE, w); ObjectSetInteger(0, n, OBJPROP_YSIZE, h); ObjectSetInteger(0, n, OBJPROP_BGCOLOR, bg); ObjectSetInteger(0, n, OBJPROP_COLOR, fg);
    ObjectSetString(0, n, OBJPROP_TEXT, t); ObjectSetInteger(0, n, OBJPROP_ZORDER, z); ObjectSetInteger(0, n, OBJPROP_BACK, false);
}

void CrearLabel(string n, int x, int y, string t, color col, int s, int z) { 
    ObjectCreate(0, n, OBJ_LABEL, 0, 0, 0); ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
    ObjectSetString(0, n, OBJPROP_TEXT, t); ObjectSetInteger(0, n, OBJPROP_COLOR, col); ObjectSetInteger(0, n, OBJPROP_FONTSIZE, s); ObjectSetInteger(0, n, OBJPROP_ZORDER, z); ObjectSetInteger(0, n, OBJPROP_BACK, false);
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) { 
    if(id == CHARTEVENT_OBJECT_CLICK) { 
        ObjectSetInteger(0, sparam, OBJPROP_STATE, false); 
        if(sparam == "MAIKO_BtnP") { BotActivo = !BotActivo; ActualizarInterfazMaster(); }
        if(sparam == "MAIKO_BtnC") CerrarTodo(); 
        if(sparam == "MAIKO_BtnHist") { idxPeriodo++; if(idxPeriodo > 3) idxPeriodo = 0; ActualizarInterfazMaster(); }
        if(sparam == "MAIKO_BtnMin") { hudMinimizado = !hudMinimizado; ActualizarInterfazMaster(); }
        ChartRedraw(); 
    } 
}

//+------------------------------------------------------------------+
//|         KOPYTRADING_XAUUSD_Evolution_Pro_v5_84.mq5               |
//|   EDICIÓN CLIENTE - LÓGICA v11.30 CON CONTROL REMOTO e INTEGRACIÓN  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "5.84"
#property strict
#property description "Maiko Pro Gold / Cent | Edición Cliente Simplificada"

#include <Trade\Trade.mqh>

// --- CONFIGURACIÓN ---
input string PurchaseID = "";            // ID de Licencia / Vínculo (Ver en kopytrading.com)
input double LoteAtaque = 0.0;           // Lote Inicial (0.0 = Configuración Automática)
input int RuedasAmetralladora = 0;       // Ruedas / Operaciones en paralelo (0 = Auto)
input double TargetDiario = 0.0;         // Meta Diaria en Dólares/Centavos (0.0 = Auto)
input double MaxLoteTotal = 0.0;         // Lote Máximo Total Cesta (0.0 = Auto)
input int LimitePosicionesSOS = 0;       // Límite Posiciones SOS / Cesta (0 = Auto)
input bool ModoCentManual = false;       // Forzar Cuenta Cent (para pruebas/overrides)
input string HUD_Branding = "";          // Nombre Personalizado del Bot (Vacío = Auto)

// --- DISEÑO HUD ---
input color ColorMain = clrGold;
input color ColorHeader = C'30,30,30';
input color ColorBody = C'20,20,20';
input int HUD_X = 15;
input int PosY_HUD = 25;

// --- PARÁMETROS INTERNOS (OCULTOS AL CLIENTE) ---
const double MaxRangoVelaM1 = 20.0;
const double MaxSpreadPips = 4.0;
const double SensibilidadMechaReal = 3.0;
const int MinutosPausaTrasSusto = 1;
const int PeriodoMediaFiltro = 50;
const bool CheckM15 = true;
const bool CheckM5 = true;

// Horario
const int HoraInicio = 9;            // Hora de inicio diaria (Lunes a Viernes)
const int HoraFin = 22;             // Hora de fin (Lunes a Jueves, 22:00 = 10:00 PM)
const int HoraFinViernes = 19;      // Hora de fin los Viernes (19:00 = 7:00 PM)

// Seguridad
const double MaxPipsHueco = 50.0;
const int MaxVelasHueco = 5;

// Variables dinámicas efectivas
double eff_LoteAtaque;
int eff_RuedasAmetralladora;
double eff_TargetDiario;
double eff_MaxLoteTotal;
int eff_LimitePosicionesSOS;
double eff_MultiplicadorRefuerzo;
double eff_ProfitNetoFlush;
double eff_ProfitCosechaIndividual;
double eff_DistanciaRefuerzoPips;
double eff_MaxLoteIndividual;
double eff_ProfitBreakEven;
string eff_TradeComment;
string eff_HUD_Branding;
bool EsCuentaCent = false;

// Globales de Telemetría y Control
string SyncURL = "https://www.kopytrading.com/api/sync-positions";
int SyncIntervalSec = 3;         // Enviar datos cada 3 segundos
datetime ultimoSync = 0;

// Globales del Bot original v11.30
CTrade trade;
int ExpertMagic = 111222;
struct PosInfo { ulong ticket; double p; double c; double s; int t; double v; datetime time; double pr; };
PosInfo pos[];
double ganadoHoy = 0, flotante = 0, volTotal = 0, spreadActual = 0;
bool BotActivo = false;
bool hudMinimizado = false;
datetime ultimoAtaque = 0;
string txtVoz = "SCHOLAR: Escaneando...";
string txtVeredicto = "ESPERANDO...";
datetime proximoAtaque = 0, pausaVolatilidad = 0;
bool enFaseAnalisis = false;
int FaseRefuerzo = 0;
ulong ticketExplorador = 0;
int hEMA_v = INVALID_HANDLE;
int hRSI_v = INVALID_HANDLE;
int hRadar[7];
ENUM_TIMEFRAMES etfs[]={PERIOD_W1,PERIOD_D1,PERIOD_H4,PERIOD_H1,PERIOD_M15,PERIOD_M5,PERIOD_M1};

void AgregarIndicadoresVisuales() {
    bool tieneEMA = false;
    bool tieneRSI = false;
    bool tieneMACD = false;
    int ventanas = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL);
    for(int w = 0; w < ventanas; w++) {
        int totalInd = ChartIndicatorsTotal(0, w);
        for(int i = 0; i < totalInd; i++) {
            string nombre = ChartIndicatorName(0, w, i);
            if(StringFind(nombre, IntegerToString(PeriodoMediaFiltro)) >= 0 && (StringFind(nombre, "MA") >= 0 || StringFind(nombre, "EMA") >= 0)) tieneEMA = true;
            if(StringFind(nombre, "RSI") >= 0 && StringFind(nombre, "14") >= 0) tieneRSI = true;
            if(StringFind(nombre, "MACD") >= 0) tieneMACD = true;
        }
    }
    if(!tieneEMA) ChartIndicatorAdd(0, 0, hEMA_v);
    if(!tieneRSI) ChartIndicatorAdd(0, (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL), hRSI_v);
    if(!tieneMACD) {
        int hMACD = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE);
        if(hMACD != INVALID_HANDLE) ChartIndicatorAdd(0, (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL), hMACD);
    }
}

int OnInit() {
    // 1. Detectar tipo de cuenta (Cent vs Normal)
    string currency = AccountInfoString(ACCOUNT_CURRENCY);
    bool autoCent = (StringFind(currency, "USC") != -1 || StringFind(currency, "CENT") != -1 || SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) < 0.001);
    EsCuentaCent = ModoCentManual ? true : autoCent;
    
    // 2. Asignar valores dinámicos
    if(EsCuentaCent) {
        eff_LoteAtaque = (LoteAtaque == 0.0) ? 0.02 : LoteAtaque;
        eff_RuedasAmetralladora = (RuedasAmetralladora == 0) ? 1 : RuedasAmetralladora;
        eff_TargetDiario = (TargetDiario == 0.0) ? 500.0 : TargetDiario;
        eff_MaxLoteTotal = (MaxLoteTotal == 0.0) ? 0.08 : MaxLoteTotal;
        eff_LimitePosicionesSOS = (LimitePosicionesSOS == 0) ? 4 : LimitePosicionesSOS;
        
        eff_MultiplicadorRefuerzo = 3.0;
        eff_ProfitNetoFlush = 15.0;
        eff_ProfitCosechaIndividual = 8.0;
        eff_DistanciaRefuerzoPips = 20.0;
        eff_MaxLoteIndividual = 0.04;
        eff_ProfitBreakEven = 5.0;
        eff_TradeComment = "MAIKO_CENT";
        eff_HUD_Branding = (HUD_Branding == "") ? "KOPYTRADING | MAIKO PRO CENT" : HUD_Branding;
        ExpertMagic = 111225;
    } else {
        eff_LoteAtaque = (LoteAtaque == 0.0) ? 0.01 : LoteAtaque;
        eff_RuedasAmetralladora = (RuedasAmetralladora == 0) ? 1 : RuedasAmetralladora;
        eff_TargetDiario = (TargetDiario == 0.0) ? 150.0 : TargetDiario;
        eff_MaxLoteTotal = (MaxLoteTotal == 0.0) ? 0.50 : MaxLoteTotal;
        eff_LimitePosicionesSOS = (LimitePosicionesSOS == 0) ? 3 : LimitePosicionesSOS;
        
        eff_MultiplicadorRefuerzo = 3.0;
        eff_ProfitNetoFlush = 5.0;
        eff_ProfitCosechaIndividual = 1.0;
        eff_DistanciaRefuerzoPips = 30.0;
        eff_MaxLoteIndividual = 0.02;
        eff_ProfitBreakEven = 0.5;
        eff_TradeComment = "MAIKO_GOLD";
        
        bool isDemo = (AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_DEMO);
        eff_HUD_Branding = (HUD_Branding == "") ? (isDemo ? "KOPYTRADING | MAIKO PRO GOLD DEMO" : "KOPYTRADING | MAIKO PRO GOLD") : HUD_Branding;
        ExpertMagic = 111222;
    }
        
    trade.SetExpertMagicNumber(ExpertMagic);
    trade.SetAsyncMode(true);
    hEMA_v = iMA(_Symbol, _Period, PeriodoMediaFiltro, 0, MODE_EMA, PRICE_CLOSE);
    hRSI_v = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
    
    // Inicializar handles de radar de forma estática para optimizar CPU
    for(int i=0; i<7; i++) {
        hRadar[i] = iMA(_Symbol, etfs[i], PeriodoMediaFiltro, 0, MODE_EMA, PRICE_CLOSE);
    }
    
    AgregarIndicadoresVisuales();
    CrearInterfazMaster();
    if(MQLInfoInteger(MQL_TESTER)) BotActivo = true;
    
    EventSetTimer(1);
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) { 
    EventKillTimer();
    ObjectsDeleteAll(0, "MAIKO_"); 
    for(int i=0; i<7; i++) {
        if(hRadar[i] != INVALID_HANDLE) IndicatorRelease(hRadar[i]);
    }
    if(hEMA_v != INVALID_HANDLE) IndicatorRelease(hEMA_v);
    if(hRSI_v != INVALID_HANDLE) IndicatorRelease(hRSI_v);
    ChartRedraw(); 
}

bool EsHorarioPermitido() {
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    if(dt.day_of_week == 6 || dt.day_of_week == 0) return false;
    if(dt.day_of_week == 5) {
        if(dt.hour < HoraInicio || dt.hour >= HoraFinViernes) return false;
        return true;
    }
    if(dt.hour < HoraInicio || dt.hour >= HoraFin) return false;
    return true;
}

void OnTick() {
    if(MQLInfoInteger(MQL_TESTER)) {
        ActualizarEstadoMaster();
        ganadoHoy = CalcularGanadoHoy();
        flotante = CalcularProfit();
        spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point / 10;
    } else {
        spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point / 10;
    }
    
    double targetActual = (ArraySize(pos) >= eff_LimitePosicionesSOS) ? eff_ProfitBreakEven : eff_ProfitNetoFlush;
    
    if(ArraySize(pos) > 0 && flotante >= targetActual) {
        txtVoz = "CIERRE NETO ALCANZADO."; CerrarTodo(); enFaseAnalisis = false; return;
    }
    if(ganadoHoy >= eff_TargetDiario) {
        txtVoz = "OBJETIVO DIARIO CUMPLIDO."; if(ArraySize(pos) > 0) CerrarTodo(); BotActivo = false; 
        if(MQLInfoInteger(MQL_TESTER)) ActualizarInterfazMaster();
        return;
    }

    GestionarCosechaSniper(); 
    if(MQLInfoInteger(MQL_TESTER)) {
        ActualizarRadarMaster();
        ActualizarInterfazMaster();
    }

    if(!BotActivo) return;
    if(ArraySize(pos) > 0) { GestionarRefuerzoInteligente(); return; }
    if(ArraySize(pos) == 0) {
        if(!EsHorarioPermitido()) {
            txtVeredicto = "FUERA DE HORARIO OPERATIVO";
            txtVoz = "MAIKO: Fuera de horario.";
            if(MQLInfoInteger(MQL_TESTER)) ActualizarInterfazMaster();
            return;
        }
        if(!enFaseAnalisis) { enFaseAnalisis = true; proximoAtaque = TimeCurrent() + 60; txtVoz = "SCHOLAR: Buscando..."; }
        if(TimeCurrent() >= proximoAtaque && TimeCurrent() >= pausaVolatilidad) {
            string d = ""; if(ValidarEstructuraScholar(d)) EjecutarAtaqueScholar(d);
        }
    }
}

void OnTimer() {
    if(!MQLInfoInteger(MQL_TESTER)) {
        ActualizarEstadoMaster();
        ganadoHoy = CalcularGanadoHoy();
        flotante = CalcularProfit();
        spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point / 10;
        
        ActualizarRadarMaster();
        ActualizarInterfazMaster();
        
        if(StringLen(PurchaseID) > 5 && TimeCurrent() - ultimoSync >= SyncIntervalSec) {
            EnviarTelemetria();
            ultimoSync = TimeCurrent();
        }
    }
}

void EnviarTelemetria() {
    string account = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
    
    // Normalizar a Dólares en la BD si es cuenta Cent
    double divFactor = EsCuentaCent ? 100.0 : 1.0;
    double normBalance = balance / divFactor;
    double normEquity = equity / divFactor;
    double normGanadoHoy = ganadoHoy / divFactor;
    
    string status = BotActivo ? "ONLINE" : "PAUSED";
    int nPos = ArraySize(pos);
    
    string posJson = "[";
    for(int i = 0; i < nPos; i++) {
        if(i > 0) posJson += ",";
        posJson += StringFormat(
            "{\"ticket\":\"%I64u\",\"type\":\"%s\",\"symbol\":\"%s\",\"lots\":%.2f,\"openPrice\":%.5f,\"tp\":%.5f,\"sl\":%.5f,\"profit\":%.2f}",
            pos[i].ticket,
            pos[i].t == POSITION_TYPE_BUY ? "BUY" : "SELL",
            _Symbol, pos[i].v, pos[i].pr, 0.0, 0.0, (pos[i].p + pos[i].c + pos[i].s) / divFactor
        );
    }
    posJson += "]";
    
    string narrative = txtVeredicto;
    StringReplace(narrative, "\"", "'");
    
    string json = StringFormat(
        "{\"purchaseId\":\"%s\",\"account\":\"%s\",\"balance\":%.2f,\"equity\":%.2f,"
        "\"pnl_today\":%.2f,\"status\":\"%s\",\"symbol\":\"%s\",\"narrative\":\"%s\","
        "\"armed\":%s,\"isReal\":%s,\"version\":\"11.30\",\"positions\":%s}",
        PurchaseID, account, normBalance, normEquity,
        normGanadoHoy, status, _Symbol, narrative,
        BotActivo ? "true" : "false", 
        (AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL) ? "true" : "false",
        posJson
    );
    
    char postData[];
    StringToCharArray(json, postData, 0, StringLen(json), CP_UTF8);
    char result[];
    string headers = "Content-Type: application/json\r\n";
    string resHeaders;
    int res = WebRequest("POST", SyncURL, headers, 3000, postData, result, resHeaders);
    
    if(res == 200 && ArraySize(result) > 0) {
        string response = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
        
        // Control Remoto: Cierre
        if(StringFind(response, "\"cmd\":\"CLOSE_ALL\"") >= 0) {
            CerrarTodo();
            Print("KOPYTRADING REMOTE: Cierre total ejecutado.");
        }
        
        // Control Remoto: Encendido/Apagado
        if(StringFind(response, "\"armed\":true") >= 0) {
            if(!BotActivo) { BotActivo = true; Print("KOPYTRADING REMOTE: Bot ENCENDIDO."); }
        } else if(StringFind(response, "\"armed\":false") >= 0) {
            if(BotActivo) {
                BotActivo = false;
                Print("KOPYTRADING REMOTE: Bot DESACTIVADO (PAUSADO).");
            }
        }
    }
}

bool ValidarEstructuraScholar(string &decision) {
    if(spreadActual > MaxSpreadPips) { txtVeredicto = "SPD ALTO: " + DoubleToString(spreadActual,1); return false; }
    double rangoBarra = (iHigh(_Symbol, _Period, 1) - iLow(_Symbol, _Period, 1)) / _Point / 10;
    if(rangoBarra > MaxRangoVelaM1) {
        txtVeredicto = "VOLATILIDAD ALTA (ESPERANDO)"; pausaVolatilidad = TimeCurrent() + (60 * MinutosPausaTrasSusto); return false;
    }
    double body = MathAbs(iOpen(_Symbol, _Period, 1) - iClose(_Symbol, _Period, 1)) / _Point / 10;
    if(body < 0.5) { txtVeredicto = "MERCADO ESTANCADO (POCA LUZ)"; return false; }

    double upperWick = (iHigh(_Symbol, _Period, 1) - MathMax(iOpen(_Symbol, _Period, 1), iClose(_Symbol, _Period, 1))) / _Point / 10;
    double lowerWick = (MathMin(iOpen(_Symbol, _Period, 1), iClose(_Symbol, _Period, 1)) - iLow(_Symbol, _Period, 1)) / _Point / 10;
    
    double ema[1];
    if(CopyBuffer(hEMA_v, 0, 1, 1, ema) <= 0) {
        txtVeredicto = "ESPERANDO HISTORIAL EMA...";
        return false;
    }
    
    double precio = iClose(_Symbol, _Period, 1); bool porEncima = (precio > ema[0]);
    
    if(porEncima && upperWick > (body * SensibilidadMechaReal) && upperWick > 3.0) { txtVeredicto = "RECHAZO ALCISTA (MECHA ALTA)"; return false; }
    if(!porEncima && lowerWick > (body * SensibilidadMechaReal) && lowerWick > 3.0) { txtVeredicto = "RECHAZO BAJISTA (MECHA BAJA)"; return false; }
    
    double rsi[1];
    if(CopyBuffer(hRSI_v, 0, 1, 1, rsi) <= 0) {
        txtVeredicto = "ESPERANDO HISTORIAL RSI...";
        return false;
    }
    
    bool rsiOK = (porEncima ? (rsi[0] > 50) : (rsi[0] < 50));
    if(!rsiOK) {
        txtVeredicto = StringFormat("P:%.2f EMA:%.2f RSI:%.1f | %s", precio, ema[0], rsi[0], (porEncima ? "RSI > 50 REQ" : "RSI < 50 REQ"));
        return false;
    }

    double c15 = iClose(_Symbol, PERIOD_M15, 1), o15 = iOpen(_Symbol, PERIOD_M15, 1);
    double c5 = iClose(_Symbol, PERIOD_M5, 1), o5 = iOpen(_Symbol, PERIOD_M5, 1);
    bool m15_ok = !CheckM15 || (porEncima ? c15 > o15 : c15 < o15);
    bool m5_ok = !CheckM5 || (porEncima ? c5 > o5 : c5 < o5);
    
    if(!m15_ok) { txtVeredicto = StringFormat("M15 EN CONTRA (C:%.2f O:%.2f)", c15, o15); return false; }
    if(!m5_ok) { txtVeredicto = StringFormat("M5 EN CONTRA (C:%.2f O:%.2f)", c5, o5); return false; }

    decision = (porEncima ? "BUY" : "SELL"); 
    txtVeredicto = "ESTRUCTURA CONFIRMADA";
    return true;
}

void EjecutarAtaqueScholar(string d) {
    if(TimeCurrent() - ultimoAtaque < 3) return;
    if(volTotal + (eff_LoteAtaque * eff_RuedasAmetralladora) > eff_MaxLoteTotal) return;
    for(int i=0; i<eff_RuedasAmetralladora; i++) { 
        if(d == "BUY") trade.Buy(eff_LoteAtaque,_Symbol,0,0,0,eff_TradeComment); 
        else trade.Sell(eff_LoteAtaque,_Symbol,0,0,0,eff_TradeComment); 
        Sleep(100); 
    }
    ultimoAtaque = TimeCurrent();
    enFaseAnalisis = false;
}

void GestionarRefuerzoInteligente() {
    if(ArraySize(pos) >= eff_LimitePosicionesSOS) {
        txtVeredicto = "LIMITE POSICIONES ALCANZADO";
        return;
    }
    int last = ArraySize(pos)-1;
    double distPips = MathAbs(SymbolInfoDouble(_Symbol, SYMBOL_BID) - pos[0].pr) / _Point / 10;
    
    string dirStr = (pos[0].t == POSITION_TYPE_BUY) ? "COMPRA" : "VENTA";
    txtVoz = StringFormat("MAIKO: Vigilando %s activo...", dirStr);
    
    if(distPips < eff_DistanciaRefuerzoPips) {
        txtVeredicto = StringFormat("VIGILANDO %s | CONTRA: %.1f pips | SOS a: %.1f", dirStr, distPips, eff_DistanciaRefuerzoPips);
        return;
    }
    
    bool forzar = (distPips >= MaxPipsHueco) || (iBarShift(_Symbol, _Period, pos[0].time) >= MaxVelasHueco);
    bool velaGiro = (pos[0].t == POSITION_TYPE_BUY) ? 
                    (iClose(_Symbol, _Period, 1) > iOpen(_Symbol, _Period, 1) && iClose(_Symbol, _Period, 2) > iOpen(_Symbol, _Period, 2)) : 
                    (iClose(_Symbol, _Period, 1) < iOpen(_Symbol, _Period, 1) && iClose(_Symbol, _Period, 2) < iOpen(_Symbol, _Period, 2));
    
    if(!velaGiro && !forzar) {
        string tfName = StringSubstr(EnumToString(_Period), 7);
        txtVeredicto = StringFormat("ZONA SOS ALCANZADA | ESPERANDO 2 VELAS GIRO %s (Pips: %.1f)", tfName, distPips);
        return;
    }
    
    double volLado = 0; int type = pos[0].t; for(int i=0; i<ArraySize(pos); i++) if(pos[i].t == type) volLado += pos[i].v;
    double volRefuerzo = NormalizeDouble(volLado * (eff_MultiplicadorRefuerzo - 1.0), 2);
    if(volRefuerzo < 0.01) volRefuerzo = 0.01;
    if(volRefuerzo > eff_MaxLoteIndividual) volRefuerzo = eff_MaxLoteIndividual;
    if(volTotal + volRefuerzo > eff_MaxLoteTotal) { txtVoz = "LIMITE LOTE ALCANZADO"; return; }
    
    if(TimeCurrent() - ultimoAtaque < 3) return;
    if(type == POSITION_TYPE_BUY) trade.Buy(volRefuerzo, _Symbol, 0, 0, 0, eff_TradeComment + "_SOS"); 
    else trade.Sell(volRefuerzo, _Symbol, 0, 0, 0, eff_TradeComment + "_SOS");
    ultimoAtaque = TimeCurrent();
    txtVeredicto = "DISPARO SOS RESCATE EJECUTADO 🛡️⚡";
}

void GestionarCosechaSniper() { 
    for(int i=ArraySize(pos)-1; i>=0; i--) {
        if((pos[i].p + pos[i].c + pos[i].s) >= eff_ProfitCosechaIndividual) {
            trade.PositionClose(pos[i].ticket);
        }
    }
}

double CalcularProfit() { double s=0; for(int i=0; i<ArraySize(pos); i++) s += (pos[i].p + pos[i].c + pos[i].s); return s; }

double CalcularGanadoHoy() { 
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    dt.hour = 0;
    dt.min = 0;
    dt.sec = 0;
    datetime startOfDay = StructToTime(dt);
    
    double total = 0; HistorySelect(startOfDay, TimeCurrent()); 
    for(int i=HistoryDealsTotal()-1; i>=0; i--) {
        ulong t = HistoryDealGetTicket(i);
        if(HistoryDealGetString(t, DEAL_SYMBOL) == _Symbol) {
            total += (HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_COMMISSION) + HistoryDealGetDouble(t, DEAL_SWAP));
        }
    }
    return total; 
}

void CerrarTodo() { for(int i=ArraySize(pos)-1; i>=0; i--) trade.PositionClose(pos[i].ticket); }

void ActualizarRadarMaster() { 
    string tfs[]={"W1","D1","H4","H1","M15","M5","M1"}; 
    double pr = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    for(int i=0; i<7; i++) { 
        double buf[1]; color col = clrGray; 
        if(CopyBuffer(hRadar[i], 0, 0, 1, buf) > 0) {
            col = (pr > buf[0]) ? clrSpringGreen : clrRed;
        }
        ObjectSetInteger(0, "MAIKO_Radar_"+tfs[i], OBJPROP_COLOR, col); 
    } 
}

void ActualizarEstadoMaster() { 
    ArrayResize(pos, 0); volTotal = 0; 
    for(int i=PositionsTotal()-1; i>=0; i--) {
        if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == ExpertMagic) { 
            int idx = ArraySize(pos); ArrayResize(pos, idx+1); 
            pos[idx].ticket = PositionGetTicket(i); 
            pos[idx].p = PositionGetDouble(POSITION_PROFIT); 
            pos[idx].c = PositionGetDouble(POSITION_COMMISSION); 
            pos[idx].s = PositionGetDouble(POSITION_SWAP); 
            pos[idx].t = (int)PositionGetInteger(POSITION_TYPE); 
            pos[idx].v = PositionGetDouble(POSITION_VOLUME); 
            pos[idx].time = (datetime)PositionGetInteger(POSITION_TIME); 
            pos[idx].pr = PositionGetDouble(POSITION_PRICE_OPEN); 
            volTotal += pos[idx].v; 
        } 
    } 
}

double CalcularMetaEscapeTP() {
    int totalPos = ArraySize(pos);
    if(totalPos == 0) return 0;
    
    double sumVol = 0;
    double sumPriceVol = 0;
    double sumCommSwap = 0;
    int type = pos[0].t;
    
    for(int i = 0; i < totalPos; i++) {
        sumVol += pos[i].v;
        sumPriceVol += pos[i].pr * pos[i].v;
        sumCommSwap += pos[i].c + pos[i].s;
    }
    
    if(sumVol <= 0) return 0;
    
    double avgPrice = sumPriceVol / sumVol;
    double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    if(contractSize <= 0) contractSize = 100.0;
    
    double targetActual = (totalPos >= eff_LimitePosicionesSOS) ? eff_ProfitBreakEven : eff_ProfitNetoFlush;
    double targetVal = targetActual - sumCommSwap;
    if(EsCuentaCent) targetVal = targetVal / 100.0;
    
    double priceDiff = targetVal / (sumVol * contractSize);
    
    double tp = (type == POSITION_TYPE_BUY) ? (avgPrice + priceDiff) : (avgPrice - priceDiff);
    return NormalizeDouble(tp, _Digits);
}

void CrearInterfazMaster() { 
    int x = HUD_X, y = PosY_HUD, w = 400, h = 280; 
    CrearBoton("MAIKO_Bg", x, y, w, h, "", ColorBody, clrNONE, CORNER_LEFT_UPPER); 
    CrearBoton("MAIKO_Head", x, y, w, 35, "", ColorHeader, clrNONE, CORNER_LEFT_UPPER); 
    CrearLabel("MAIKO_T", x+10, y+10, eff_HUD_Branding, ColorMain, 11, CORNER_LEFT_UPPER); 
    CrearBoton("MAIKO_BtnMin", x+w-30, y+7, 22, 22, "_", ColorBody, clrWhite, CORNER_LEFT_UPPER); 
    
    string tfs[]={"W1","D1","H4","H1","M15","M5","M1"}; 
    for(int i=0; i<7; i++) { 
        int px = x + 10 + (i * 55); 
        CrearLabel("MAIKO_L_"+tfs[i], px, y+45, tfs[i]+":", clrWhite, 8, CORNER_LEFT_UPPER); 
        CrearLabel("MAIKO_Radar_"+tfs[i], px+25, y+45, "o", clrGray, 10, CORNER_LEFT_UPPER); 
    } 
    
    CrearLabel("MAIKO_Vered", x+10, y+85, txtVeredicto, clrCyan, 9, CORNER_LEFT_UPPER); 
    CrearLabel("MAIKO_Hoy", x+10, y+125, "GANADO HOY: $0.00", clrSpringGreen, 14, CORNER_LEFT_UPPER); 
    CrearLabel("MAIKO_Flot", x+10, y+160, "FLOTANTE: $0.00", clrWhite, 12, CORNER_LEFT_UPPER); 
    CrearLabel("MAIKO_MetaTP", x+10, y+190, " ", clrYellow, 10, CORNER_LEFT_UPPER); 
    CrearLabel("MAIKO_Spd", x+w-120, y+65, "SPD: 0.0", clrWhite, 8, CORNER_LEFT_UPPER);  
    
    CrearBoton("MAIKO_Foot", x, y+h-40, w, 40, "", ColorHeader, clrNONE, CORNER_LEFT_UPPER); 
    CrearLabel("MAIKO_Voz", x+10, y+h-25, txtVoz, ColorMain, 10, CORNER_LEFT_UPPER); 
    CrearBoton("MAIKO_BtnP", x+w-120, y+110, 110, 50, "ENCENDER", clrDarkGreen, clrWhite, CORNER_LEFT_UPPER); 
    CrearBoton("MAIKO_BtnC", x+w-120, y+175, 110, 35, "CERRAR", clrDarkRed, clrWhite, CORNER_LEFT_UPPER); 
}

void ActualizarInterfazMaster() { 
    double divFactor = EsCuentaCent ? 100.0 : 1.0; 
    ObjectSetString(0, "MAIKO_Hoy", OBJPROP_TEXT, StringFormat("GANADO HOY: $%.2f", ganadoHoy / divFactor)); 
    ObjectSetString(0, "MAIKO_Flot", OBJPROP_TEXT, StringFormat("FLOTANTE: $%.2f", flotante / divFactor)); 
    ObjectSetString(0, "MAIKO_Spd", OBJPROP_TEXT, StringFormat("SPD: %.1f", spreadActual)); 
    ObjectSetInteger(0, "MAIKO_Flot", OBJPROP_COLOR, flotante >= 0 ? clrSpringGreen : clrRed); 
    ObjectSetString(0, "MAIKO_Vered", OBJPROP_TEXT, txtVeredicto); 
    ObjectSetString(0, "MAIKO_Voz", OBJPROP_TEXT, txtVoz); 
    ObjectSetString(0, "MAIKO_BtnP", OBJPROP_TEXT, BotActivo ? "APAGAR" : "ENCENDER"); 
    ObjectSetInteger(0, "MAIKO_BtnP", OBJPROP_BGCOLOR, BotActivo ? clrMaroon : clrDarkGreen); 
    
    double metaTP = CalcularMetaEscapeTP();
    if(metaTP > 0) {
        ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, StringFormat("ESCAPE TP: %.2f", metaTP));
    } else {
        if(!BotActivo) {
            ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, "ESTADO: BOT APAGADO (INACTIVO)");
        } else if(!EsHorarioPermitido()) {
            ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, "ESTADO: FUERA DE HORARIO");
        } else if(TimeCurrent() < pausaVolatilidad) {
            int seg = (int)(pausaVolatilidad - TimeCurrent());
            ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, StringFormat("PAUSA VOLATILIDAD: %ds", seg));
        } else if(TimeCurrent() < proximoAtaque) {
            int seg = (int)(proximoAtaque - TimeCurrent());
            ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, StringFormat("PAUSA SEGURIDAD: %ds", seg));
        } else {
            ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, "ESTADO: BUSCANDO ENTRADA EN M5...");
        }
    }
    
    // Forzar el HUD al frente cambiando el timeframe periódicamente
    static datetime lastFrontTime = 0;
    datetime now = TimeLocal();
    if(now - lastFrontTime >= 2) {
        lastFrontTime = now;
        string objs[] = {"MAIKO_Bg", "MAIKO_Head", "MAIKO_T", "MAIKO_BtnMin", 
                         "MAIKO_Vered", "MAIKO_Hoy", "MAIKO_Flot", "MAIKO_Spd", 
                         "MAIKO_Foot", "MAIKO_Voz", "MAIKO_BtnP", "MAIKO_BtnC", "MAIKO_MetaTP"};
        int total = ArraySize(objs);
        for(int i = 0; i < total; i++) {
            long current_tf = ObjectGetInteger(0, objs[i], OBJPROP_TIMEFRAMES);
            if(current_tf != OBJ_NO_PERIODS) {
                ObjectSetInteger(0, objs[i], OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
                ObjectSetInteger(0, objs[i], OBJPROP_TIMEFRAMES, current_tf);
            }
        }
        
        string tfs[]={"W1","D1","H4","H1","M15","M5","M1"}; 
        for(int i=0; i<7; i++) { 
            string o1 = "MAIKO_L_"+tfs[i];
            string o2 = "MAIKO_Radar_"+tfs[i];
            long tf1 = ObjectGetInteger(0, o1, OBJPROP_TIMEFRAMES);
            long tf2 = ObjectGetInteger(0, o2, OBJPROP_TIMEFRAMES);
            if(tf1 != OBJ_NO_PERIODS) {
                ObjectSetInteger(0, o1, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
                ObjectSetInteger(0, o1, OBJPROP_TIMEFRAMES, tf1);
            }
            if(tf2 != OBJ_NO_PERIODS) {
                ObjectSetInteger(0, o2, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
                ObjectSetInteger(0, o2, OBJPROP_TIMEFRAMES, tf2);
            }
        }
    }
    ChartRedraw(); 
}

void CrearBoton(string n, int x, int y, int w, int h, string t, color bg, color fg, ENUM_BASE_CORNER c) { 
    ObjectCreate(0, n, OBJ_BUTTON, 0, 0, 0); 
    ObjectSetInteger(0, n, OBJPROP_CORNER, c); 
    ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y); 
    ObjectSetInteger(0, n, OBJPROP_XSIZE, w); ObjectSetInteger(0, n, OBJPROP_YSIZE, h); 
    ObjectSetInteger(0, n, OBJPROP_BGCOLOR, bg); ObjectSetInteger(0, n, OBJPROP_COLOR, fg); 
    ObjectSetString(0, n, OBJPROP_TEXT, t); ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false); 
    ObjectSetInteger(0, n, OBJPROP_BACK, false); 
    int z = 80;
    if(StringFind(n, "Btn") >= 0) z = 110;
    ObjectSetInteger(0, n, OBJPROP_ZORDER, z); 
}

void CrearLabel(string n, int x, int y, string t, color col, int s, ENUM_BASE_CORNER c) { 
    ObjectCreate(0, n, OBJ_LABEL, 0, 0, 0); 
    ObjectSetInteger(0, n, OBJPROP_CORNER, c); 
    ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y); 
    ObjectSetString(0, n, OBJPROP_TEXT, t); ObjectSetInteger(0, n, OBJPROP_COLOR, col); 
    ObjectSetInteger(0, n, OBJPROP_FONTSIZE, s); ObjectSetInteger(0, n, OBJPROP_BACK, false); 
    ObjectSetInteger(0, n, OBJPROP_ZORDER, 100); 
}

void ToggleHUD() { 
    hudMinimizado = !hudMinimizado; 
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_YSIZE, hudMinimizado ? 35 : 280); 
    ObjectSetString(0, "MAIKO_BtnMin", OBJPROP_TEXT, hudMinimizado ? "+" : "_"); 
    long tf = hudMinimizado ? OBJ_NO_PERIODS : OBJ_ALL_PERIODS; 
    string objs[] = {"MAIKO_Vered", "MAIKO_Hoy", "MAIKO_Flot", "MAIKO_Spd", "MAIKO_Foot", "MAIKO_Voz", "MAIKO_BtnP", "MAIKO_BtnC", "MAIKO_MetaTP"}; 
    for(int i=0; i<9; i++) ObjectSetInteger(0, objs[i], OBJPROP_TIMEFRAMES, tf); 
    string tfs[]={"W1","D1","H4","H1","M15","M5","M1"}; 
    for(int i=0; i<7; i++) { 
        ObjectSetInteger(0, "MAIKO_L_"+tfs[i], OBJPROP_TIMEFRAMES, tf); 
        ObjectSetInteger(0, "MAIKO_Radar_"+tfs[i], OBJPROP_TIMEFRAMES, tf); 
    } 
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) { 
    if(id == CHARTEVENT_OBJECT_CLICK) { 
        if(sparam == "MAIKO_BtnP") {
            BotActivo = !BotActivo; 
            if(BotActivo) {
                enFaseAnalisis = true;
                proximoAtaque = TimeCurrent();
                pausaVolatilidad = 0;
            }
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
            ActualizarInterfazMaster();
        }
        if(sparam == "MAIKO_BtnC") { 
            CerrarTodo(); 
            enFaseAnalisis = false; 
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
            ActualizarInterfazMaster();
        } 
        if(sparam == "MAIKO_BtnMin") { 
            ToggleHUD(); 
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false); 
        } 
        ChartRedraw(); 
    } 
}

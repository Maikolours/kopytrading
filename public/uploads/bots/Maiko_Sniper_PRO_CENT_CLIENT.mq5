//+------------------------------------------------------------------+
//|                MAIKO SNIPER PRO | EDITION REAL CENT             |
//|      "DYNAMIC SOS PROGRESSION" | VERSION 13.92                |
//+------------------------------------------------------------------+
#property copyright "Elite Gold MAIKO Sniper"
#property version   "13.92"
#property strict

#include <Trade\Trade.mqh>

// --- CONFIGURACION ---
// --- PROTECCION DE EQUIDAD (STOP LOSS) ---
input bool InpUsarProteccionEquidad = false; // Activar Stop Loss por Equidad (Drawdown)
input double InpMaxDrawdownPorcentaje = 20.0; // % Maximo de Drawdown permitido
input string MiLicencia = "23449251"; 
bool CUENTA_REAL_CENT = true; 
datetime FechaInicioMaiko = D'2026.05.07 00:00'; 

// --- MODO CASCADA AGRESIVO ---
bool UsarModoCascada = true;  
double DistanciaCascadaPips = 5.0; 
int MaxPosicionesCascada = 3; 

// --- FILTRO DE NOTICIAS ---
bool UsarFiltroNoticias = true;    
string HoraProximaNoticia = "14:30"; 
int MinsAntesNoticia = 15;         
int MinsDespuesNoticia = 15;       

// --- FILTROS DE TENDENCIA ---
bool CheckH4 = true;       
bool CheckH1 = true;
bool CheckM15 = true;
bool CheckM5 = true;
double SegundosReAnalisis = 60;       // Segundos base de espera tras cerrar cesta
double MultiplicadorMechazo = 2.5;    // Multiplica la espera si hay vela de mechazo (mecha > 2x ATR)
double UmbralMechazo_ATR = 2.0;       // Cuántas veces el ATR tiene que medir la mecha para considerarlo mechazo

// --- MEJORAS INSTITUCIONALES HUGO ---
bool UsarFiltroADX = true; // Activar Filtro ADX (H1 > 25)
int ADX_MinLevel = 25; // Nivel MÃ­nimo ADX para entrar (Tendencia)
bool UsarFiltroSpreadDelta = true; // Activar ProtecciÃ³n Spread Delta
double MaxSpreadDeltaPips = 10.0; // DesviaciÃ³n MÃ¡xima del Spread en pips 

bool UsarProteccionEquidad = false;
double MaxDrawdownPorcentaje = 20.0;

// --- SINCRONIZACIÃ“N CON KOPYTRADING.COM ---
input string PurchaseID = "";          // ID de licencia (del dashboard de kopytrading.com)
string SyncURL = "https://www.kopytrading.com/api/sync-positions";
int SyncIntervalSec = 3;         // Cada cuÃ¡ntos segundos enviar datos 

// --- HORARIO DE SESION (editable) ---
bool UsarFiltroHorario = true;
input int HoraInicioSesion = 9;   // Hora de inicio de sesion (9 = 09:00)
input int HoraFinSesion = 22;     // Hora de fin de sesion (22 = 22:00)
bool UsarFiltroATR = true;
double MinATR_Pips = 5.0;

// --- FILTROS SNIPER ---
bool UsarATR_Dinamico = true;  
bool UsarFiltroSR = true;      
double MargenZonaPips = 2.0;    
double MinDistanciaEMAPips = 1.0; 
bool EsperarGiroM1_SOS = true;    // Espera vela cerrada M1 para abrir SOS (false = al toque)
double MaxRSI_Compra = 70.0;   
double MinRSI_Venta = 30.0;    
double MaxSpreadPips = 4.5; 
double MinCuerpoVelaPips = 3.0; 

// --- GESTION DE LOTAJE ---
input double LotajeMinimo = 0.01;     // Lote para entradas 1 y 2 (minimo, protege la cesta)
input double LotajeInicial = 0.05;    // Lote de referencia inicial
double MultiplicadorRefuerzo = 1.0; 
double MaxLoteIndividual = 0.05;
input double MaxLoteTotal = 0.45;     // Lote maximo total en mercado
input int LimitePosicionesSOS = 3;    // Numero maximo de operaciones simultaneas (1-5)

// --- OBJETIVOS DE PROFIT ---
bool UsarModoScalp = true;
double ProfitScalpIndividual = 20.0;
double ProfitScalpMinLote = 10.0;
bool UsarEmergenciaAuto = true;
double ProfitEmergenciaCents = 75.0;
input double ProfitNetoCents = 75.0;  // Profit objetivo por cesta (cents)
input double LimiteDiario = 10.0;     // Limite de beneficio diario (cents)
double DistanciaRefuerzoPipsBase = 15.0; 

// --- HUD ---
input color ColorMain = clrGold;
input color ColorHeader = C'30,30,30';
input color BodyColor = C'15,15,15';
input int HUD_X = 15;
input int PosY_HUD = 25;
input string TradeComment = "MAIKO_PRO_CENT";

// Globales
CTrade trade;
const int ExpertMagic = 111222;
struct PosInfo { ulong ticket; double p; int t; double v; double pr; double tp; };
PosInfo pos[];
double ganadoPeriodo = 0, flotante = 0, volTotal = 0, spreadActual = 0, rsiActual = 0, macdActual = 0;
bool BotActivo = false;
bool hudMinimizado = false;
bool bloqueadoPorNoticia = false;
datetime ultimaCestaCerrada = 0;
bool mechazoDetectado = false; // Flag: hubo mechazo en la última vela cerrada
string txtVoz = "SISTEMA ONLINE.";
string txtVeredicto = "ESPERANDO...";
string txtConsolidado = "ANALIZANDO...";
string txtProteccion = " "; 
datetime ultimoCascada = 0;
datetime ultimoSOS = 0;
double metaEscapeTP = 0;
double precioSiguienteSOS = 0;
int hEMA_H4, hEMA_H1, hEMA_M15, hEMA_M5, hEMA_M1, hEMA_M1_9, hRSI, hMACD, hATR, hADX, hADX_Chart;
int hRadar[7];
ENUM_TIMEFRAMES etfs[]={PERIOD_W1,PERIOD_D1,PERIOD_H4,PERIOD_H1,PERIOD_M15,PERIOD_M5,PERIOD_M1};
double spreadDelta = 0, lastSpread = 0, adxActual = 0, equityPeak = 0;

int idxPeriodo = 0;
string labelPeriodo[] = {"HOY (NETO)", "ESTA SEMANA", "ESTE MES", "MAIKO PROFIT"};
datetime ultimoSync = 0;

int OnInit() {
      UsarProteccionEquidad = InpUsarProteccionEquidad;
      MaxDrawdownPorcentaje = InpMaxDrawdownPorcentaje;
    ObjectsDeleteAll(0, "MAIKO_");
    trade.SetExpertMagicNumber(ExpertMagic);
    equityPeak = AccountInfoDouble(ACCOUNT_EQUITY);
    hEMA_H4 = iMA(_Symbol, PERIOD_H4, 50, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_H1 = iMA(_Symbol, PERIOD_H1, 50, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_M15 = iMA(_Symbol, PERIOD_M15, 50, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_M5 = iMA(_Symbol, PERIOD_M5, 50, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_M1 = iMA(_Symbol, PERIOD_M1, 50, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_M1_9 = iMA(_Symbol, PERIOD_M1, 9, 0, MODE_EMA, PRICE_CLOSE);
    hRSI = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);     // Usa el TF actual del grÃ¡fico
    hMACD = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE); // Usa el TF actual del grÃ¡fico
    hATR = iATR(_Symbol, _Period, 14);
    hADX = iADX(_Symbol, PERIOD_H1, 14);
    hADX_Chart = iADX(_Symbol, _Period, 14);
    for(int i=0; i<7; i++) hRadar[i] = iMA(_Symbol, etfs[i], 50, 0, MODE_EMA, PRICE_CLOSE);
    
    // GestiÃ³n Inteligente de Indicadores Visuales (igual que BTC)
    int totalWindows = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL);
    int winRSI = -1, winMACD = -1, winADX = -1;
    for(int i=1; i<totalWindows; i++) {
        string name = ChartIndicatorName(0, i, 0);
        if(StringFind(name, "RSI") >= 0) winRSI = i;
        if(StringFind(name, "MACD") >= 0) winMACD = i;
        if(StringFind(name, "Average Directional") >= 0 || StringFind(name, "ADX") >= 0) winADX = i;
    }
    if(winRSI == -1) ChartIndicatorAdd(0, (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL), hRSI);
    if(winMACD == -1) ChartIndicatorAdd(0, (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL), hMACD);
    if(winADX == -1) ChartIndicatorAdd(0, (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL), hADX_Chart);
    ChartIndicatorAdd(0, 0, hEMA_M1); // EMA visible en el grÃ¡fico principal
    
    ChartSetInteger(0, CHART_SHOW_TRADE_HISTORY, false); // Desactivado para evitar manchas en el HUD
    ChartSetInteger(0, CHART_FOREGROUND, false); // Forzar grÃ¡fico al fondo para HUD limpio
    EventSetTimer(1);
    CrearInterfazMaster();
    // Calcular estado inicial (funciona incluso con mercado cerrado)
    ActualizarEstadoMaster();
    ganadoPeriodo = CalcularGanadoUltraPreciso(idxPeriodo);
    flotante = CalcularProfit();
    ActualizarInterfazMaster();
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) { EventKillTimer(); ObjectsDeleteAll(0, "MAIKO_"); }

void OnTimer() {
    // Comprobacion de horario en el timer (funciona aunque no haya ticks)
    if(UsarFiltroHorario && ArraySize(pos) == 0) {
        MqlDateTime dt; TimeCurrent(dt);
        if(dt.hour < HoraInicioSesion || dt.hour >= HoraFinSesion) {
            txtVeredicto = "FUERA DE SESION (DORMIDO)";
            txtVoz = StringFormat("SESION CERRADA - Reabre a las %02d:00", HoraInicioSesion);
        }
    }
    ActualizarEstadoMaster();
    ganadoPeriodo = CalcularGanadoUltraPreciso(idxPeriodo);
    flotante = CalcularProfit();
    ActualizarInterfazMaster();
    ChartRedraw();
    // Sync con kopytrading.com
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
            _Symbol, pos[i].v, pos[i].pr, pos[i].tp, 0.0, pos[i].p
        );
    }
    posJson += "]";
    
    string json = StringFormat(
        "{\"purchaseId\":\"%s\",\"account\":\"%s\",\"balance\":%.2f,\"equity\":%.2f,"
        "\"pnl_today\":%.2f,\"status\":\"%s\",\"symbol\":\"%s\",\"narrative\":\"%s\","
        "\"armed\":%s,\"isReal\":true,\"version\":\"13.92\",\"positions\":%s}",
        PurchaseID, account, balance, equity,
        ganadoHoy, status, _Symbol, txtVeredicto,
        BotActivo ? "true" : "false", posJson
    );
    
    char postData[];
    StringToCharArray(json, postData, 0, StringLen(json), CP_UTF8);
    char result[];
    string headers = "Content-Type: application/json\r\n";
    string resHeaders;
    int res = WebRequest("POST", SyncURL, headers, 3000, postData, result, resHeaders);
    
    // --- CONTROL REMOTO: Procesar respuesta del servidor ---
    if(res == 200 && ArraySize(result) > 0) {
        string response = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
        if(StringFind(response, "\"cmd\":\"CLOSE_ALL\"") >= 0) {
            CerrarTodo();
            Print("MAIKO REMOTE: Cierre total ejecutado desde el panel web.");
        }
        if(StringFind(response, "\"armed\":true") >= 0) {
            if(!BotActivo) { BotActivo = true; Print("MAIKO REMOTE: Bot ENCENDIDO desde el panel web."); }
        } else if(StringFind(response, "\"armed\":false") >= 0) {
              if(BotActivo) {
                  BotActivo = false;
                  Print("MAIKO REMOTE CONTROL: Bot desactivado (PAUSADO) desde el panel web.");
              }
          }
          
          // 3. Control Remoto: Stop Loss Equidad
          if(StringFind(response, "\"usar_sl_equidad\":true") >= 0) {
              UsarProteccionEquidad = true;
          } else if(StringFind(response, "\"usar_sl_equidad\":false") >= 0) {
              UsarProteccionEquidad = false;
          }
          
          int ddPos = StringFind(response, "\"dd_max\":");
          if(ddPos >= 0) {
              int start = ddPos + 9;
              int end = StringFind(response, ",", start);
              if(end == -1) end = StringFind(response, "}", start);
              if(end > start) {
                  double ddVal = StringToDouble(StringSubstr(response, start, end - start));
                  if(ddVal > 0) MaxDrawdownPorcentaje = ddVal;
              }
          }
    }
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
    double profitTarget = (CUENTA_REAL_CENT ? 75.0 : 1.00); 
    double priceDiff = profitTarget / (totalVol * valuePerPoint);
    
    metaEscapeTP = (type == POSITION_TYPE_BUY) ? avgPrice + priceDiff : avgPrice - priceDiff;
    metaEscapeTP = NormalizeDouble(metaEscapeTP, _Digits);
    
    // NOTA: NO se pone TP en el broker. El cierre lo controla EXCLUSIVAMENTE
    // el chequeo de flotante >= ProfitGlobalEscape en OnTick.
    // Esto GARANTIZA que NUNCA se cierre una cesta en negativo.
}

void DibujarProyeccionSOS(double p) {
    if(ObjectFind(0, "MAIKO_SOS_Line") < 0) {
        ObjectCreate(0, "MAIKO_SOS_Line", OBJ_HLINE, 0, 0, p);
        ObjectSetInteger(0, "MAIKO_SOS_Line", OBJPROP_STYLE, STYLE_DASHDOT);
        ObjectSetInteger(0, "MAIKO_SOS_Line", OBJPROP_COLOR, clrOrange);
        ObjectSetInteger(0, "MAIKO_SOS_Line", OBJPROP_WIDTH, 2);
        ObjectSetInteger(0, "MAIKO_SOS_Line", OBJPROP_BACK, true);
        ObjectSetString(0, "MAIKO_SOS_Line", OBJPROP_TOOLTIP, "ZONA DE DISPARO SOS MAIKO");
    } else {
        ObjectSetDouble(0, "MAIKO_SOS_Line", OBJPROP_PRICE, p);
    }
}

void DibujarLineaMetaEscape(double precio) {
    if(precio <= 0) { ObjectDelete(0, "MAIKO_TP_Line"); return; }
    if(ObjectFind(0, "MAIKO_TP_Line") < 0) {
        ObjectCreate(0, "MAIKO_TP_Line", OBJ_HLINE, 0, 0, precio);
        ObjectSetInteger(0, "MAIKO_TP_Line", OBJPROP_STYLE, STYLE_DASH);
        ObjectSetInteger(0, "MAIKO_TP_Line", OBJPROP_COLOR, clrSpringGreen);
        ObjectSetInteger(0, "MAIKO_TP_Line", OBJPROP_WIDTH, 2);
        ObjectSetInteger(0, "MAIKO_TP_Line", OBJPROP_BACK, true);
        ObjectSetString(0, "MAIKO_TP_Line", OBJPROP_TOOLTIP, "META ESCAPE TP - MAIKO");
    } else {
        ObjectSetDouble(0, "MAIKO_TP_Line", OBJPROP_PRICE, precio);
    }
}

void OnTick() {
    ActualizarEstadoMaster();
    ganadoPeriodo = CalcularGanadoUltraPreciso(idxPeriodo);
    flotante = CalcularProfit();
    
    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    if(currentEquity > equityPeak) equityPeak = currentEquity;
    
    if(UsarProteccionEquidad && equityPeak > 0) {
        double ddPercent = ((equityPeak - currentEquity) / equityPeak) * 100.0;
        if(ddPercent >= MaxDrawdownPorcentaje) {
            CerrarTodo();
            BotActivo = false;
            txtVeredicto = "STOP LOSS EQUIDAD ALCANZADO 🛑";
            txtVoz = "SISTEMA PAUSADO POR STOP LOSS DE EQUIDAD.";
            ActualizarInterfazMaster();
            return;
        }
    }
    
    // CHEQUEO LÃ MITE DIARIO (Cerrado + Flotante) - Usamos HOY (0) siempre para evitar falsos cierres al cambiar de vista
    double ganadoHoyReal = CalcularGanadoUltraPreciso(0);
    double targetLimit = CUENTA_REAL_CENT ? (LimiteDiario * 100.0) : LimiteDiario;
    if((ganadoHoyReal + flotante) >= targetLimit) {
        if(ArraySize(pos) > 0) {
            CerrarTodo();
            ultimaCestaCerrada = TimeCurrent();
        }
        BotActivo = false;
        txtVeredicto = "LÃMITE DIARIO ALCANZADO ðŸ›‘";
        txtVoz = "PAUSADO POR LÃMITE DIARIO.";
    }

    spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point / 10;
    spreadDelta = (lastSpread > 0) ? (spreadActual - lastSpread) : 0;
    lastSpread = spreadActual;
    
    double adx_buf[1];
    if(CopyBuffer(hADX, 0, 0, 1, adx_buf) > 0) adxActual = adx_buf[0];
    
    bloqueadoPorNoticia = IsNewsBlocked();

    double rsi_buf[1], macd_buf[1], emaH4[1], emaH1[1], emaM15[1], emaM5[1], emaM1[1], atr_buf[1];
    CopyBuffer(hRSI, 0, 0, 1, rsi_buf); rsiActual = rsi_buf[0];
    CopyBuffer(hMACD, 0, 0, 1, macd_buf); macdActual = macd_buf[0];
    CopyBuffer(hEMA_H4, 0, 0, 1, emaH4);
    CopyBuffer(hEMA_H1, 0, 0, 1, emaH1);
    CopyBuffer(hEMA_M15, 0, 0, 1, emaM15);
    double emaM1_9[1];
    CopyBuffer(hEMA_M5, 0, 0, 1, emaM5);
    CopyBuffer(hEMA_M1, 0, 0, 1, emaM1);
    CopyBuffer(hEMA_M1_9, 0, 0, 1, emaM1_9);
    CopyBuffer(hATR, 0, 0, 1, atr_buf);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    int ok = 0;
    if(bid > emaH4[0]) ok++; if(bid > emaH1[0]) ok++; 
    if(bid > emaM15[0]) ok++; if(bid > emaM5[0]) ok++;
    string sentiment;
    if(ok >= 3) sentiment = StringFormat("ALCISTA (%d/4 â†‘)", ok);
    else if(ok <= 1) sentiment = StringFormat("BAJISTA (%d/4 â†‘ alcistas)", ok);
    else sentiment = StringFormat("MIXTO (%d/4)", ok);
    txtConsolidado = StringFormat("SENTIMIENTO: %s", sentiment);
    
    int direccion = 0; 
    bool condBuy = (rsiActual > 50 && rsiActual < MaxRSI_Compra);
    bool condSell = (rsiActual < 50 && rsiActual > MinRSI_Venta);
    
    if(CheckH4) { condBuy = condBuy && (bid > emaH4[0]); condSell = condSell && (bid < emaH4[0]); }
    if(CheckH1) { condBuy = condBuy && (bid > emaH1[0]); condSell = condSell && (bid < emaH1[0]); }
    if(CheckM15) { condBuy = condBuy && (bid > emaM15[0]); condSell = condSell && (bid < emaM15[0]); }
    if(CheckM5) { condBuy = condBuy && (bid > emaM5[0]); condSell = condSell && (bid < emaM5[0]); }

    if(UsarFiltroSR) {
        double maxH1 = iHigh(_Symbol, PERIOD_H1, iHighest(_Symbol, PERIOD_H1, MODE_HIGH, 24, 1));
        double minH1 = iLow(_Symbol, PERIOD_H1, iLowest(_Symbol, PERIOD_H1, MODE_LOW, 24, 1));
        if(condBuy && bid > maxH1 - MargenZonaPips * _Point * 10) { condBuy = false; txtVeredicto = "TECHO DETECTADO (NO COMPRAR)"; }
        if(condSell && bid < minH1 + MargenZonaPips * _Point * 10) { condSell = false; txtVeredicto = "SUELO DETECTADO (NO VENDER)"; }
    }

    if(condBuy) direccion = 1; else if(condSell) direccion = -1;

    // LÃ“GICA DE EMERGENCIA INTELIGENTE
    bool emergenciaActiva = false;
    if(UsarEmergenciaAuto && ArraySize(pos) >= 3) {
        bool giroEMAs = false;
        bool rsiConfirma = false;
        if(pos[0].t == POSITION_TYPE_SELL) {
            giroEMAs = (ok >= 3); // EMAs se ponen alcistas
            rsiConfirma = (rsiActual > 55.0);
        } else if(pos[0].t == POSITION_TYPE_BUY) {
            giroEMAs = (ok <= 1); // EMAs se ponen bajistas
            rsiConfirma = (rsiActual < 45.0);
        }
        
        // Si hay peligro de giro, ya ganamos hoy y el balance del dÃ­a sumando el flotante sigue siendo positivo
        if(giroEMAs && rsiConfirma && ganadoPeriodo > 0 && (ganadoPeriodo + flotante) >= ProfitEmergenciaCents) {
            emergenciaActiva = true;
        }
    }

    if(ArraySize(pos) > 0) { 
        double targetActual = (emergenciaActiva) ? (ProfitEmergenciaCents - ganadoPeriodo) : ProfitNetoCents;
        // Si estamos en emergencia, el flotante objetivo es el que asegura terminar el dÃ­a con ProfitEmergenciaCents
        if(flotante >= targetActual) {
            CerrarTodo(); 
            ultimaCestaCerrada = TimeCurrent(); 
            if(emergenciaActiva) txtVeredicto = "SALIDA EMERGENCIA OK ðŸ‘";
            return; 
        }
    }
    
    GestionarCosechaSniper(); 
    ActualizarRadarMaster();
    ActualizarInterfazMaster();

    if(!BotActivo) { txtVoz = "SISTEMA EN PAUSA."; return; }
    if(bloqueadoPorNoticia) { txtVoz = "PAUSA POR NOTICIAS."; return; }
    
    // Detectar mechazo en la última vela cerrada (mecha total > UmbralMechazo_ATR * ATR)
    if(atr_buf[0] > 0) {
        double mechaUp   = iHigh(_Symbol, _Period, 1) - MathMax(iOpen(_Symbol, _Period, 1), iClose(_Symbol, _Period, 1));
        double mechaDown = MathMin(iOpen(_Symbol, _Period, 1), iClose(_Symbol, _Period, 1)) - iLow(_Symbol, _Period, 1);
        double mechaMax  = MathMax(mechaUp, mechaDown);
        mechazoDetectado = (mechaMax > atr_buf[0] * UmbralMechazo_ATR);
    }
    
    long esperaEfectiva = (long)(mechazoDetectado ? SegundosReAnalisis * MultiplicadorMechazo : SegundosReAnalisis);
    long diffEspera = TimeCurrent() - ultimaCestaCerrada;
    if(diffEspera < esperaEfectiva) { 
        if(mechazoDetectado)
            txtVoz = StringFormat("⚡ MECHAZO DETECTADO — ENFRIANDO (%d seg restantes)...", (int)(esperaEfectiva - diffEspera));
        else
            txtVoz = StringFormat("MEDITANDO (%d seg restantes)...", (int)(esperaEfectiva - diffEspera)); 
        return; 
    }
    
    if(ArraySize(pos) > 0) { 
        ActualizarTP_Global();
        DibujarLineaMetaEscape(metaEscapeTP);
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
        txtProteccion = " "; ObjectDelete(0, "MAIKO_SOS_Line"); ObjectDelete(0, "MAIKO_TP_Line");
        if(spreadActual > MaxSpreadPips) { txtVeredicto = "SPREAD ALTO"; return; }
        
        if(UsarFiltroHorario) {
            MqlDateTime dt; TimeCurrent(dt);
            if(dt.hour < HoraInicioSesion || dt.hour >= HoraFinSesion) {
                txtVeredicto = "FUERA DE SESION (DORMIDO)";
                return;
            }
        }
        
        if(UsarFiltroATR) {
            double atrPips = (atr_buf[0] / _Point / 10);
            if(atrPips < MinATR_Pips) {
                txtVeredicto = "ATR MUY BAJO (RANGO)";
                return;
            }
        }
        
        // FILTROS INSTITUCIONALES HUGO
        if(UsarFiltroSpreadDelta && MathAbs(spreadDelta) >= MaxSpreadDeltaPips) { txtVeredicto = "SPREAD SPIKE DETECTED ðŸ›‘"; return; }
        if(UsarFiltroADX && adxActual < ADX_MinLevel) { txtVeredicto = "MERCADO LATERAL ADX âŒ"; return; }
        
        int pM5 = AnalizarPatronPriceAction(PERIOD_M5, 1);
        int pM1 = AnalizarPatronPriceAction(PERIOD_M1, 1);
        
        txtVoz = (direccion == 1) ? "BUSCANDO COMPRA..." : "BUSCANDO VENTA...";
        
        bool emaOK = (direccion == 1 && bid > emaM5[0] && bid > emaM1[0] && bid > emaM1_9[0]) || (direccion == -1 && bid < emaM5[0] && bid < emaM1[0] && bid < emaM1_9[0]);
        
        if(!emaOK) txtVeredicto = "ESPERANDO CRUCE EMA (M5/M1/M1(9))...";
        else if(pM5 == 0 || pM1 == 0) txtVeredicto = "ESPERANDO FUERZA VELA (3 Pips min)";
        else {
            if(direccion == 1 && pM5 == 2 && pM1 == 2) trade.Buy(LotajeMinimo, _Symbol, 0, 0, 0, TradeComment);
            else if(direccion == -1 && pM5 == -2 && pM1 == -2) trade.Sell(LotajeMinimo, _Symbol, 0, 0, 0, TradeComment);
            else txtVeredicto = "ESPERANDO GIRO VELA...";
        }
    }
}

void GestionarModoCascada(int direccion, double emaM1) {
    if(ArraySize(pos) >= MaxPosicionesCascada || volTotal >= MaxLoteTotal) return;
    if(TimeCurrent() - ultimoCascada < 5) return; 
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    bool emaOK = (pos[0].t == POSITION_TYPE_BUY && bid > emaM1) || (pos[0].t == POSITION_TYPE_SELL && bid < emaM1);
    if(!emaOK) return;

    double distProfit = (pos[ArraySize(pos)-1].t == POSITION_TYPE_BUY ? bid - pos[ArraySize(pos)-1].pr : pos[ArraySize(pos)-1].pr - ask) / _Point / 10;
    if(distProfit < DistanciaCascadaPips) return;
    
    if(direccion != 0 && ((pos[0].t == POSITION_TYPE_BUY && direccion == 1) || (pos[0].t == POSITION_TYPE_SELL && direccion == -1))) {
        double lotCascada = LotajeMinimo;
        if(pos[0].t == POSITION_TYPE_BUY) trade.Buy(lotCascada, _Symbol, 0, 0, 0, TradeComment + "_CASCADA");
        else trade.Sell(lotCascada, _Symbol, 0, 0, 0, TradeComment + "_CASCADA");
        ultimoCascada = TimeCurrent();
        txtVeredicto = "CASCADA AGRESIVA ðŸ”¥";
    }
}

void GestionarRefuerzoInteligente(double distSOS, double prExtrema, double distContActual) {
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

    if(!EsperarGiroM1_SOS) {
        double volRef = MaxLoteIndividual; 
        if(volTotal + volRef > MaxLoteTotal) volRef = NormalizeDouble(MaxLoteTotal - volTotal, 2); 
        if(volRef >= 0.01) {
            if(pos[0].t == POSITION_TYPE_BUY) trade.Buy(volRef, _Symbol, 0, 0, 0, TradeComment + "_SOS");
            else trade.Sell(volRef, _Symbol, 0, 0, 0, TradeComment + "_SOS");
            ultimoSOS = TimeCurrent();
            txtVeredicto = "RESCATE AL TOQUE ðŸ›¡ï¸âš¡";
        }
        return;
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
            txtVeredicto = "RESCATE DINAMICO ðŸ›¡ï¸âš¡";
        }
    } else txtVeredicto = "ESPERANDO GIRO REAL M1";
}

void GestionarCosechaSniper() { 
    int nPos = ArraySize(pos);
    if(nPos == 0) return;
    
    if(UsarModoScalp) {
        int idxBest = -1;
        double maxProfit = -999999;
        
        for(int i=0; i<nPos; i++) {
            if(pos[i].p > maxProfit) {
                maxProfit = pos[i].p;
                idxBest = i;
            }
        }
        
        if(idxBest != -1) {
            double targetScalp = (pos[idxBest].v <= LotajeMinimo + 0.001) ? ProfitScalpMinLote : ProfitScalpIndividual;
            if(maxProfit >= targetScalp) {
                trade.PositionClose(pos[idxBest].ticket);
                txtVeredicto = "SCALP INDIVIDUAL OK ðŸŽ¯";
                return;
            }
        }
    } else {
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
        ulong t = HistoryDealGetTicket(i); if(HistoryDealGetString(t, DEAL_SYMBOL) != _Symbol || HistoryDealGetInteger(t, DEAL_MAGIC) != ExpertMagic) continue;
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
            pos[idx].p = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP) ; 
            pos[idx].t = (int)PositionGetInteger(POSITION_TYPE); pos[idx].v = PositionGetDouble(POSITION_VOLUME); 
            pos[idx].pr = PositionGetDouble(POSITION_PRICE_OPEN); pos[idx].tp = PositionGetDouble(POSITION_TP);
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
    CrearLabel("MAIKO_T", x+10, y+10, "MAIKO PRO | CENT v13.92", ColorMain, 11, 10001); 
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
    CrearLabel("MAIKO_TP", x+15, y+223, "META ESCAPE TP: 0.00", clrYellow, 9, 10001); 
    
    CrearLabel("MAIKO_ADX", x+15, y+239, "ADX TREND: --", clrCyan, 8, 10001);
    CrearLabel("MAIKO_DD", x+15, y+253, "SL EQUIDAD: --", clrOrange, 8, 10001);
    CrearLabel("MAIKO_Delta", x+15, y+267, "SPREAD DELTA: --", clrLightGray, 8, 10001);
    
    CrearLabel("MAIKO_Voz", x+15, y+320, txtVoz, clrGold, 10, 10001); 
    CrearLabel("MAIKO_SPD", x+w-120, y+135, "SPD: 0.0", clrWhite, 8, 10001);
    CrearLabel("MAIKO_RSI", x+w-120, y+45, "RSI: 0.0", clrOrange, 9, 10001);
    CrearLabel("MAIKO_LVol", x+w-120, y+65, "VOL TOTAL:", clrWhite, 8, 10001);
    CrearBoton("MAIKO_BtnHist", x+15, y+285, 140, 24, "CAMBIAR VISTA", clrGray, clrWhite, 10010);
    CrearBoton("MAIKO_BtnP", x+w-120, y+165, 110, 50, "ENCENDER", clrDarkGreen, clrWhite, 10010); 
    CrearBoton("MAIKO_BtnC", x+w-120, y+225, 110, 35, "CERRAR", clrDarkRed, clrWhite, 10010); 
}

void ActualizarInterfazMaster() { 
    ObjectSetString(0, "MAIKO_Hoy", OBJPROP_TEXT, StringFormat("%s: %.2f", labelPeriodo[idxPeriodo], ganadoPeriodo)); 
    ObjectSetString(0, "MAIKO_Flotante", OBJPROP_TEXT, StringFormat("FLOTANTE: %.2f", flotante)); 
    ObjectSetInteger(0, "MAIKO_Flotante", OBJPROP_COLOR, flotante >= 0 ? clrSpringGreen : clrRed);
    if(metaEscapeTP > 0) ObjectSetString(0, "MAIKO_TP", OBJPROP_TEXT, StringFormat("META ESCAPE TP: %.2f", metaEscapeTP));
    else ObjectSetString(0, "MAIKO_TP", OBJPROP_TEXT, " ");  
    
    // TelemetrÃ­a Visual de Filtros Hugo
    string adxState = (adxActual >= ADX_MinLevel) ? "FUERTE âœ…" : "LATERAL âŒ";
    ObjectSetString(0, "MAIKO_ADX", OBJPROP_TEXT, StringFormat("ADX TREND (H1): %.1f (%s)", adxActual, adxState));
    
    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    double ddPercent = (equityPeak > 0) ? (((equityPeak - currentEquity) / equityPeak) * 100.0) : 0.0;
    string estadoSL = UsarProteccionEquidad ? "ON" : "OFF";
    ObjectSetString(0, "MAIKO_DD", OBJPROP_TEXT, StringFormat("PICO DD: %.2f%% | SL EQUIDAD: %.1f%% (%s)", ddPercent, MaxDrawdownPorcentaje, estadoSL));
    ObjectSetInteger(0, "MAIKO_DD", OBJPROP_COLOR, (UsarProteccionEquidad && ddPercent >= MaxDrawdownPorcentaje * 0.7) ? clrRed : clrOrange);
    
    ObjectSetString(0, "MAIKO_Delta", OBJPROP_TEXT, StringFormat("SPREAD DELTA: %+.1f pips", spreadDelta));
    ObjectSetInteger(0, "MAIKO_Delta", OBJPROP_COLOR, (MathAbs(spreadDelta) >= MaxSpreadDeltaPips) ? clrRed : clrLightGray);
    
    ObjectSetString(0, "MAIKO_Consol", OBJPROP_TEXT, txtConsolidado);
    ObjectSetString(0, "MAIKO_Protec", OBJPROP_TEXT, txtProteccion);
    ObjectSetString(0, "MAIKO_Vered", OBJPROP_TEXT, txtVeredicto);
    ObjectSetString(0, "MAIKO_SPD", OBJPROP_TEXT, StringFormat("SPD: %.1f", spreadActual));
    ObjectSetString(0, "MAIKO_RSI", OBJPROP_TEXT, StringFormat("RSI: %.1f", rsiActual));
    ObjectSetString(0, "MAIKO_LVol", OBJPROP_TEXT, StringFormat("VOL: %.2f/%.2f", volTotal, MaxLoteTotal));
    string displayVoz = txtVoz; color colVoz = clrGold;
    if(bloqueadoPorNoticia) { displayVoz = "PAUSA POR NOTICIAS"; colVoz = clrOrange; }
    else if(!BotActivo) { displayVoz = "SISTEMA EN PAUSA"; colVoz = clrRed; }
    ObjectSetString(0, "MAIKO_Voz", OBJPROP_TEXT, displayVoz); ObjectSetInteger(0, "MAIKO_Voz", OBJPROP_COLOR, colVoz);
    ObjectSetString(0, "MAIKO_BtnP", OBJPROP_TEXT, BotActivo ? "ENCENDIDO" : "ENCENDER");
    ObjectSetInteger(0, "MAIKO_BtnP", OBJPROP_BGCOLOR, BotActivo ? clrRoyalBlue : clrDarkGreen);
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_YSIZE, hudMinimizado ? 35 : 360);
    ChartSetInteger(0, CHART_FOREGROUND, false); // Re-forzar en cada refresco de interfaz
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
        ObjectSetInteger(0, sparam, OBJPROP_STATE, false); // Reset botÃ³n pulsado
        if(sparam == "MAIKO_BtnP") { BotActivo = !BotActivo; ActualizarInterfazMaster(); }
        if(sparam == "MAIKO_BtnC") CerrarTodo(); 
        if(sparam == "MAIKO_BtnHist") { idxPeriodo++; if(idxPeriodo > 3) idxPeriodo = 0; ActualizarInterfazMaster(); }
        if(sparam == "MAIKO_BtnMin") { hudMinimizado = !hudMinimizado; ActualizarInterfazMaster(); }
        ChartRedraw(); 
    } 
}

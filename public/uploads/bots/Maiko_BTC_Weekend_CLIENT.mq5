//+------------------------------------------------------------------+
//|                MAIKO SNIPER PRO | EDITION CRYPTO                |
//|      "SMART OVERLAP (DESARME)" | VERSION 13.92                |
//+------------------------------------------------------------------+
#property copyright "Elite Gold MAIKO Sniper"
#property version   "13.92"
#property strict

#include <Trade\Trade.mqh>

// --- CONFIGURACION DE LICENCIA (DRM) ---
input string UserEmail = "tu@correo.com"; // Email de Compra
input string MiLicencia = "TRIAL-2026"; // Clave de Licencia Unica
input string ProductKey = "BTC-WEEKEND"; // Producto (NO TOCAR)

// --- CONFIGURACION GENERAL ---
bool CUENTA_REAL_CENT = false; 
datetime FechaInicioMaiko = D'2026.05.01 00:00'; 

// --- MODO CASCADA CRYPTO ---
bool UsarModoCascada = true;  
double DistanciaCascadaPips = 60.0; 
int MaxPosicionesCascada = 2; 

// --- FILTROS DE TENDENCIA ---
bool CheckH4 = true;       
bool CheckH1 = true;
bool CheckM15 = true;
bool CheckM5 = true;
double SegundosReAnalisis = 60; 

// --- SINCRONIZACIÃ“N CON KOPYTRADING.COM ---
input string PurchaseID = "";          // ID de licencia (del dashboard de kopytrading.com)
string SyncURL = "https://www.kopytrading.com/api/sync-positions"; // URL de sincronizaciÃ³n
int SyncIntervalSec = 5;         // Cada cuÃ¡ntos segundos enviar datos al dashboard 

// --- NUEVOS FILTROS ---
bool UsarFiltroHorario = true;
int HoraInicioSesion = 9;  // 09:00
int HoraFinSesion = 21;    // 21:00
bool UsarFiltroATR = true;
double MinATR_Pips = 5.0; // MÃ­nimo movimiento (Pips) de ATR para entrar

// --- FILTROS SNIPER ---
bool UsarATR_Dinamico = true;  
bool UsarFiltroSR = true;      
double MargenZonaPips = 20.0;    
double MinDistanciaEMAPips = 5.0; 
bool EsperarGiroM1_SOS = false;    // Espera vela cerrada M1 para abrir SOS (false = al toque)
double MaxRSI_Compra = 70.0;   
double MinRSI_Venta = 30.0;    
double MaxSpreadPips = 500.0; 
double MinCuerpoVelaPips = 25.0; 

// --- GESTION DE LOTAJE ($500 Account - ULTRA SAFETY) ---
input double LotajeMinimo = 0.01;     // Lote para entradas 1 y 2 (mÃ­nimo, protege la cesta)
input double LotajeInicial = 0.01;   // Lote referencia
double MultiplicadorRefuerzo = 1.0; 
double MaxLoteIndividual = 0.01; // Lote SOS (rescates desde posiciÃ³n 3)
input double MaxLoteTotal = 0.12;      
int LimitePosicionesSOS = 12; 

// --- GESTION DE DISTANCIAS SOS (Configurables) ---
double DistanciaSOS_Nivel1 = 150.0; 
double DistanciaSOS_Nivel2 = 300.0; 
double DistanciaSOS_Nivel3 = 500.0; 

// --- OBJETIVOS DE PROFIT ---
bool UsarModoScalp = true;        // Cierra posiciones individuales en ganancia
double ProfitScalpIndividual = 2.00; // Profit individual para posiciones SOS ($)
double ProfitScalpMinLote = 0.50;    // Profit individual para posiciones de 0.01 ($)
bool UsarEmergenciaAuto = true;    // Activa la salida de emergencia inteligente
double ProfitEmergenciaUSD = 3.00;  // TP de emergencia global ($)
double ProfitGlobalEscape = 0.50; 
input double LimiteDiario = 50.0;       // LÃ­mite de beneficio diario ($)

// --- MEJORAS INSTITUCIONALES HUGO ---
bool UsarFiltroADX = true;              // Usar Filtro ADX de fuerza de tendencia
int ADX_MinLevel = 25;                  // Nivel mÃ­nimo de ADX para confirmar tendencia
bool UsarTrailingDrawdown = false;      // Activa Cierre por Drawdown desde el Pico de Equidad
double MaxDrawdownPercent = 15.0;       // % MÃ¡ximo de caÃ­da de equidad desde el pico
bool UsarFiltroSpreadDelta = true;       // Evitar disparos si el spread se ensancha rÃ¡pido
double MaxSpreadDeltaPips = 10.0;       // Delta mÃ¡ximo de ensanchamiento del spread


// --- HUD ---
input color ColorMain = clrOrange;
input color ColorHeader = C'30,20,10';
input color BodyColor = C'15,10,5';
input int HUD_X = 15;
input int PosY_HUD = 25;
input string TradeComment = "MAIKO_CRYPTO";

// Globales
CTrade trade;
const int ExpertMagic = 555777;
struct PosInfo { ulong ticket; double p; int t; double v; double pr; double tp; double sl; };
PosInfo pos[];
double ganadoPeriodo = 0, flotante = 0, volTotal = 0, spreadActual = 0, rsiActual = 0, macdActual = 0;
bool BotActivo = false;
bool hudMinimizado = false;
datetime ultimaCestaCerrada = 0;
string txtVoz = "SISTEMA CRYPTO ONLINE.";
string txtVeredicto = "MONITOREANDO SOS...";
string txtConsolidado = "ANALIZANDO BTC...";
string txtProteccion = " "; 
double precioSiguienteSOS = 0;
double metaEscapeTP = 0;
datetime ultimoCascada = 0;
datetime ultimoSOS = 0;
int hRSI, hMACD, hATR, hADX, hADX_Chart;
double equityPeak = 0;
double spreadDelta = 0;
double lastSpread = 0;
double adxActual = 0;

int hEMA_H4, hEMA_H1, hEMA_M15, hEMA_M5, hEMA_M1, hEMA_M1_9;
int hRadar[7];
double emaH4[1], emaH1[1], emaM15[1], emaM5[1], emaM1[1];
double rsiM5[1], macdM15[1], atrM15[1];
ENUM_TIMEFRAMES etfs[7] = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_H1, PERIOD_H4, PERIOD_D1, PERIOD_W1};

// GLOBALES DE SYNC
datetime ultimoSync = 0;

// --- GLOBALES DE LICENCIA (DRM) ---
datetime ultimaValidacionLicencia = 0;
bool licenciaValida = false;
string licenciaMensaje = "Validando licencia...";

int idxPeriodo = 0;
string labelPeriodo[] = {"HOY (NETO)", "ESTA SEMANA", "ESTE MES", "MAIKO CRYPTO"};

bool ValidarLicenciaServer() {
    // EMERGENCY BYPASS PARA QUE NO PIERDA SUS OPERACIONES
    if(MiLicencia == "TRIAL-2026") {
        licenciaValida = true;
        licenciaMensaje = "Licencia VÃ¡lida (Bypass de Emergencia)";
        return true;
    }

    string url = "https://www.kopytrading.com/api/license/validate";
    string headers = "Content-Type: application/json\r\n";
    
    string acc = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
    string payload = StringFormat("{\"purchaseId\":\"%s\", \"licenseKey\":\"%s\", \"account\":\"%s\", \"email\":\"%s\"}", MiLicencia, ProductKey, acc, UserEmail);
    
    char data[];
    StringToCharArray(payload, data, 0, WHOLE_ARRAY, CP_UTF8);
    char result[];
    string resultHeaders;
    
    int res = WebRequest("POST", url, headers, 5000, data, result, resultHeaders);
    
    if(res == -1) {
        licenciaMensaje = "Error conectando con kopytrading.com. Permite WebRequest.";
        licenciaValida = false;
        return false;
    }
    
    string response = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
    
    if(StringFind(response, "\"valid\":true") >= 0) {
        licenciaValida = true;
        licenciaMensaje = "Licencia VÃ¡lida";
        return true;
    } else {
        int msgIdx = StringFind(response, "\"message\":\"");
        if(msgIdx >= 0) {
            msgIdx += 11;
            int endIdx = StringFind(response, "\"", msgIdx);
            if(endIdx > msgIdx) {
                licenciaMensaje = StringSubstr(response, msgIdx, endIdx - msgIdx);
            } else {
                licenciaMensaje = "Licencia invÃ¡lida o en uso.";
            }
        } else {
            licenciaMensaje = "Licencia invÃ¡lida o en uso.";
        }
        licenciaValida = false;
        return false;
    }
}

int OnInit() {
    ObjectsDeleteAll(0, "MAIKO_");
    
    if(!ValidarLicenciaServer()) {
        Alert("MAIKO SECURITY: ", licenciaMensaje);
        return INIT_FAILED;
    }
    ultimaValidacionLicencia = TimeCurrent();
    EventSetTimer(3); // Para telemetria y validaciones

    trade.SetExpertMagicNumber(ExpertMagic);
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
    equityPeak = AccountInfoDouble(ACCOUNT_EQUITY);
    for(int i=0; i<7; i++) hRadar[i] = iMA(_Symbol, etfs[i], 50, 0, MODE_EMA, PRICE_CLOSE);
    
    // Gestion Inteligente de Indicadores
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
    ChartIndicatorAdd(0, 0, hEMA_M1);
    
    ChartSetInteger(0, CHART_SHOW_TRADE_HISTORY, false); // Desactivado para evitar manchas en el HUD
    ChartSetInteger(0, CHART_FOREGROUND, false); // Forzar grÃ¡fico al fondo para HUD limpio
    EventSetTimer(1);
    CrearInterfazMaster();
    // Calcular estado inicial (funciona incluso sin ticks)
    ActualizarEstadoMaster();
    ganadoPeriodo = CalcularGanadoUltraPreciso(idxPeriodo);
    flotante = CalcularProfit();
    ActualizarInterfazMaster();
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) { 
    EventKillTimer();
    ObjectsDeleteAll(0, "MAIKO_"); 
}

void OnTimer() {
    if(TimeCurrent() - ultimaValidacionLicencia > 1800) { // Cada 30 mins
        if(!ValidarLicenciaServer()) {
            Alert("MAIKO SECURITY: ", licenciaMensaje);
            ExpertRemove();
        }
        ultimaValidacionLicencia = TimeCurrent();
    }
    // Refresco periodico de datos (funciona sin ticks)
    ActualizarEstadoMaster();
    ganadoPeriodo = CalcularGanadoUltraPreciso(idxPeriodo);
    flotante = CalcularProfit();
    ActualizarInterfazMaster();
    ChartRedraw();
    
    // Sync telemetrÃ­a con kopytrading.com
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
    string direction = "NEUTRAL";
    if(nPos > 0) direction = (pos[0].t == POSITION_TYPE_BUY) ? "COMPRA" : "VENTA";
    
    // Construir JSON de posiciones abiertas
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
        "\"isReal\":true,\"version\":\"13.92\",\"positions\":%s}",
        PurchaseID, account, balance, equity,
        ganadoHoy, status, _Symbol,
        txtVeredicto, posJson
    );
    
    char postData[];
    StringToCharArray(json, postData, 0, StringLen(json), CP_UTF8);
    char result[];
    string headers = "Content-Type: application/json\r\n";
    string resHeaders;
    int res = WebRequest("POST", SyncURL, headers, 3000, postData, result, resHeaders);
    if (res == -1) {
        Print("MAIKO SYNC ERROR: WebRequest failed. Error code: ", GetLastError(), ". Verifica 'Allow WebRequest' para: ", SyncURL);
    } else if (res != 200) {
        Print("MAIKO SYNC SERVER ERROR: Code ", res, ". Response: ", CharArrayToString(result));
    } else {
        // Print("MAIKO SYNC SUCCESS: Data sent to dashboard. Length: ", StringLen(json));
    }
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
    double priceDiff = ProfitGlobalEscape / (totalVol * valuePerPoint);
    
    metaEscapeTP = (type == POSITION_TYPE_BUY) ? avgPrice + priceDiff : avgPrice - priceDiff;
    metaEscapeTP = NormalizeDouble(metaEscapeTP, _Digits);
    
    // NOTA: NO se pone TP en el broker. El cierre lo controla EXCLUSIVAMENTE
    // el chequeo de flotante >= ProfitGlobalEscape en OnTick (linea 285).
    // Esto GARANTIZA que NUNCA se cierre una cesta en negativo.
}

void OnTick() {
    ActualizarEstadoMaster();
    ganadoPeriodo = CalcularGanadoUltraPreciso(idxPeriodo);
    flotante = CalcularProfit();
    
    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    if(currentEquity > equityPeak) equityPeak = currentEquity;
    
    if(UsarTrailingDrawdown && equityPeak > 0) {
        double ddPercent = ((equityPeak - currentEquity) / equityPeak) * 100.0;
        if(ddPercent >= MaxDrawdownPercent) {
            CerrarTodo();
            BotActivo = false;
            txtVeredicto = "STOP DRAWDOWN Pico ðŸ›‘";
            txtVoz = "CARTERA CERRADA POR PICO DD.";
            ActualizarInterfazMaster();
            return;
        }
    }
    
    // CHEQUEO LÃMITE DIARIO (Cerrado + Flotante) - Usamos HOY (0) siempre para evitar falsos cierres al cambiar de vista
    double ganadoHoyReal = CalcularGanadoUltraPreciso(0);
    if((ganadoHoyReal + flotante) >= LimiteDiario) {
        if(ArraySize(pos) > 0) {
            CerrarTodo();
        }
        BotActivo = false;
        txtVeredicto = "LÃMITE DIARIO ALCANZADO ðŸ›‘";
        txtVoz = "PAUSADO POR LÃMITE DIARIO.";
    }

    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    spreadActual = (ask - bid) / _Point / 10;
    spreadDelta = (lastSpread > 0) ? (spreadActual - lastSpread) : 0;
    lastSpread = spreadActual;
    
    double adx_buf[1];
    if(CopyBuffer(hADX, 0, 0, 1, adx_buf) > 0) adxActual = adx_buf[0];

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
    
    int ok = 0;
    if(bid > emaH4[0]) ok++; if(bid > emaH1[0]) ok++; 
    if(bid > emaM15[0]) ok++; if(bid > emaM5[0]) ok++;
    string sentiment;
    if(ok >= 3) sentiment = StringFormat("ALCISTA (%d/4 â†‘)", ok);
    else if(ok <= 1) sentiment = StringFormat("BAJISTA (%d/4 â†‘ alcistas)", ok);
    else sentiment = StringFormat("MIXTO (%d/4)", ok);
    txtConsolidado = StringFormat("SENTIMIENTO BTC: %s", sentiment);
    
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
        if(condBuy && bid > maxH1 - MargenZonaPips * _Point * 10) { condBuy = false; txtVeredicto = "TECHOS BTC (ESPERAR)"; }
        if(condSell && bid < minH1 + MargenZonaPips * _Point * 10) { condSell = false; txtVeredicto = "SUELOS BTC (ESPERAR)"; }
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
        if(giroEMAs && rsiConfirma && ganadoPeriodo > 0 && (ganadoPeriodo + flotante) >= ProfitEmergenciaUSD) {
            emergenciaActiva = true;
        }
    }

    if(ArraySize(pos) > 0) { 
        double targetActual = (emergenciaActiva) ? (ProfitEmergenciaUSD - ganadoPeriodo) : ProfitGlobalEscape;
        // Si estamos en emergencia, el flotante objetivo es el que asegura terminar el dÃ­a con ProfitEmergenciaUSD
        if(flotante >= targetActual) {
            CerrarTodo(); 
            ActualizarEstadoMaster();
            if(ArraySize(pos) == 0) {
                ultimaCestaCerrada = TimeCurrent();
                if(emergenciaActiva) txtVeredicto = "SALIDA EMERGENCIA OK ðŸ‘";
            }
            return; 
        }
    }
    
    GestionarCosechaSniper(); 
    ActualizarRadarMaster();
    ActualizarInterfazMaster();

    if(!BotActivo) { txtVoz = "BTC PAUSADO."; return; }
    
    long diffEspera = TimeCurrent() - ultimaCestaCerrada;
    if(diffEspera < (long)SegundosReAnalisis) { 
        txtVoz = StringFormat("RELAX CRYPTO (%d seg)...", (int)(SegundosReAnalisis - diffEspera)); 
        return; 
    }
    
    if(ArraySize(pos) > 0) { 
        ActualizarTP_Global();
        DibujarLineaMetaEscape(metaEscapeTP);
        txtVoz = StringFormat("VIGILANDO BTC (%d/%d)", ArraySize(pos), LimitePosicionesSOS);
        
        int nPos = ArraySize(pos);
        double distSOS = DistanciaSOS_Nivel1;
        if(nPos >= 8) distSOS = DistanciaSOS_Nivel3;
        else if(nPos >= 4) distSOS = DistanciaSOS_Nivel2;
        
        // Buscar la posicion MAS EXTERNA (la que mas nos duele)
        double prExtrema = pos[0].pr;
        for(int i=1; i<nPos; i++) {
            if(pos[0].t == POSITION_TYPE_BUY && pos[i].pr < prExtrema) prExtrema = pos[i].pr;
            if(pos[0].t == POSITION_TYPE_SELL && pos[i].pr > prExtrema) prExtrema = pos[i].pr;
        }
        
        double distContActual = MathAbs((pos[0].t==POSITION_TYPE_BUY ? bid : ask) - prExtrema) / _Point / 10;
        txtProteccion = StringFormat("DIST. ACTUAL: %.1f | PLAN SOS: %.0f", distContActual, distSOS);
        
        // Calcular Proyeccion Visual (Lineas desde la EXTREMA)
        precioSiguienteSOS = (pos[0].t == POSITION_TYPE_BUY) ? prExtrema - distSOS * _Point * 10 : prExtrema + distSOS * _Point * 10;
        DibujarProyeccionSOS(precioSiguienteSOS);

        GestionarRefuerzoInteligente(distSOS, prExtrema, distContActual); 
        if(UsarModoCascada) GestionarModoCascada(direccion, emaM1[0]);
    } else {
        txtProteccion = ""; ObjectDelete(0, "MAIKO_SOS_Line"); ObjectDelete(0, "MAIKO_TP_Line");
        if(spreadActual > MaxSpreadPips) { txtVeredicto = "SPREAD CRYPTO ALTO"; return; }
        
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
        
        if(UsarFiltroSpreadDelta && spreadDelta > MaxSpreadDeltaPips) { txtVeredicto = "SPREAD SPIKE DETECTED ðŸ›‘"; return; }
        if(UsarFiltroADX && adxActual < ADX_MinLevel) { txtVeredicto = StringFormat("MERCADO LATERAL ADX (%.1f < %d)", adxActual, ADX_MinLevel); return; }
        
        int pM5 = AnalizarPatronPriceAction(PERIOD_M5, 1);
        int pM1 = AnalizarPatronPriceAction(PERIOD_M1, 1);
        
        txtVoz = (direccion == 1) ? "BTC: BUSCANDO COMPRA" : "BTC: BUSCANDO VENTA";
        
        bool emaOK = (direccion == 1 && bid > emaM5[0] && bid > emaM1[0] && bid > emaM1_9[0]) || (direccion == -1 && bid < emaM5[0] && bid < emaM1[0] && bid < emaM1_9[0]);
        
        if(!emaOK) txtVeredicto = "ESPERANDO CRUCE EMA (BTC)";
        else if(pM5 == 0 || pM1 == 0) txtVeredicto = "VELA BTC SIN FUERZA";
        else {
            if(direccion == 1 && pM5 == 2 && pM1 == 2) trade.Buy(LotajeMinimo, _Symbol, 0, 0, 0, TradeComment);
            else if(direccion == -1 && pM5 == -2 && pM1 == -2) trade.Sell(LotajeMinimo, _Symbol, 0, 0, 0, TradeComment);
            else txtVeredicto = "ESPERANDO GIRO BTC...";
        }
    }
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
        ObjectSetString(0, "MAIKO_TP_Line", OBJPROP_TOOLTIP, "META ESCAPE TP - MAIKO BTC");
    } else {
        ObjectSetDouble(0, "MAIKO_TP_Line", OBJPROP_PRICE, precio);
    }
}

void GestionarModoCascada(int direccion, double emaM1) {
    if(ArraySize(pos) >= MaxPosicionesCascada || volTotal >= MaxLoteTotal) return;
    if(TimeCurrent() - ultimoCascada < 10) return; 
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
        txtVeredicto = "BTC CASCADA ðŸ”¥";
    }
}

void GestionarRefuerzoInteligente(double distSOS, double prExtrema, double distContActual) {
    if(ArraySize(pos) >= LimitePosicionesSOS || volTotal >= MaxLoteTotal) { 
        txtVeredicto = StringFormat("RIESGO MAX BTC (%d/%d)", ArraySize(pos), LimitePosicionesSOS); 
        return; 
    }
    if(TimeCurrent() - ultimoSOS < 30) return;
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    bool enContra = (pos[0].t == POSITION_TYPE_BUY && bid < prExtrema) || (pos[0].t == POSITION_TYPE_SELL && bid > prExtrema);
    
    if(!enContra) { txtVeredicto = "RECUPERANDO BTC..."; return; }

    if(distContActual < distSOS) { 
        txtVeredicto = StringFormat("ESPERANDO DISTANCIA (Faltan %.1f pips)", distSOS - distContActual); 
        return; 
    }
    
    if(!EsperarGiroM1_SOS) {
        double volRef = LotajeInicial; 
        if(volTotal + volRef > MaxLoteTotal) volRef = NormalizeDouble(MaxLoteTotal - volTotal, 2); 
        if(volRef >= 0.01) {
            if(pos[0].t == POSITION_TYPE_BUY) trade.Buy(volRef, _Symbol, 0, 0, 0, TradeComment + "_SOS");
            else trade.Sell(volRef, _Symbol, 0, 0, 0, TradeComment + "_SOS");
            ultimoSOS = TimeCurrent();
            txtVeredicto = "DISPARO SOS EJECUTADO! ðŸ›¡ï¸âš¡";
        }
        return;
    }

    int pat = AnalizarPatronPriceAction(PERIOD_M1, 1);
    double closePrev = iClose(_Symbol, PERIOD_M1, 1);
    bool colorActualOK = (pos[0].t == POSITION_TYPE_BUY ? bid > closePrev : bid < closePrev);

    if(((pos[0].t == POSITION_TYPE_BUY && pat == 2) || (pos[0].t == POSITION_TYPE_SELL && pat == -2)) && colorActualOK) {
        double volRef = LotajeInicial; 
        if(volTotal + volRef > MaxLoteTotal) volRef = NormalizeDouble(MaxLoteTotal - volTotal, 2); 
        if(volRef >= 0.01) {
            if(pos[0].t == POSITION_TYPE_BUY) trade.Buy(volRef, _Symbol, 0, 0, 0, TradeComment + "_SOS");
            else trade.Sell(volRef, _Symbol, 0, 0, 0, TradeComment + "_SOS");
            ultimoSOS = TimeCurrent();
            txtVeredicto = "DISPARO SOS EJECUTADO! ðŸ›¡ï¸âš¡";
        }
    } else {
        txtVeredicto = "ZONA SOS ALCANZADA: ESPERANDO GIRO M1... ðŸŽ¯";
    }
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
        // MODO DESARME PARCIAL (OVERLAP INSTITUCIONAL)
        if(nPos >= 5) {
            int idxBest = 0, idxWorst = 0;
            double maxProfit = -999999, minProfit = 999999;
            
            for(int i=0; i<nPos; i++) {
                if(pos[i].p > maxProfit) { maxProfit = pos[i].p; idxBest = i; }
                if(pos[i].p < minProfit) { minProfit = pos[i].p; idxWorst = i; }
            }
            
            if(idxBest != idxWorst && (maxProfit + minProfit) >= ProfitGlobalEscape) {
                trade.PositionClose(pos[idxBest].ticket);
                trade.PositionClose(pos[idxWorst].ticket);
                return; 
            }
        } else {
            // MODO COSECHA INDIVIDUAL NORMAL
            for(int i=nPos-1; i>=0; i--) {
                if(pos[i].tp > 0 && nPos >= 3) continue; 
                if(pos[i].p >= (pos[i].v / 0.01) * ProfitGlobalEscape) trade.PositionClose(pos[i].ticket); 
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
            pos[idx].pr = PositionGetDouble(POSITION_PRICE_OPEN); 
            pos[idx].tp = PositionGetDouble(POSITION_TP);
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
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_BGCOLOR, BodyColor); ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_ZORDER, 9999); 
    CrearBoton("MAIKO_Head", x, y, w, 35, "", ColorHeader, clrNONE, 10000); 
    CrearLabel("MAIKO_T", x+10, y+10, "MAIKO PRO | CRYPTO v13.92", ColorMain, 11, 10001);  
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
    CrearLabel("MAIKO_ADX", x+15, y+239, "ADX METRIC: --", clrCyan, 8, 10001);
    CrearLabel("MAIKO_DD", x+15, y+253, "TRAILING DD: --", clrOrange, 8, 10001);
    CrearLabel("MAIKO_Delta", x+15, y+267, "SPREAD DELTA: --", clrLightGray, 8, 10001);
    
    CrearBoton("MAIKO_BtnHist", x+15, y+285, 140, 24, "CAMBIAR VISTA", clrGray, clrWhite, 10010);
    CrearLabel("MAIKO_Voz", x+15, y+320, txtVoz, clrGold, 10, 10001); 
    CrearLabel("MAIKO_SPD", x+w-120, y+135, "SPD: 0.0", clrWhite, 8, 10001);
    CrearLabel("MAIKO_RSI", x+w-120, y+45, "RSI: 0.0", clrOrange, 9, 10001);
    CrearLabel("MAIKO_LVol", x+w-120, y+65, "VOL TOTAL:", clrWhite, 8, 10001);
    CrearBoton("MAIKO_BtnP", x+w-120, y+165, 110, 50, "ENCENDER", clrDarkGreen, clrWhite, 10010); 
    CrearBoton("MAIKO_BtnC", x+w-120, y+225, 110, 35, "CERRAR", clrDarkRed, clrWhite, 10010); 
}

void ActualizarInterfazMaster() { 
    ObjectSetString(0, "MAIKO_Hoy", OBJPROP_TEXT, StringFormat("%s: %.2f", labelPeriodo[idxPeriodo], ganadoPeriodo)); 
    ObjectSetString(0, "MAIKO_Flotante", OBJPROP_TEXT, StringFormat("FLOTANTE: %.2f", flotante)); 
    ObjectSetInteger(0, "MAIKO_Flotante", OBJPROP_COLOR, flotante >= 0 ? clrSpringGreen : clrRed); 
    
    if(metaEscapeTP > 0) ObjectSetString(0, "MAIKO_TP", OBJPROP_TEXT, StringFormat("META ESCAPE TP: %.2f", metaEscapeTP));
    else ObjectSetString(0, "MAIKO_TP", OBJPROP_TEXT, "");
    
    // TelemetrÃ­a Visual de Filtros Hugo
    string adxState = (adxActual >= ADX_MinLevel) ? "FUERTE âœ…" : "LATERAL âŒ";
    ObjectSetString(0, "MAIKO_ADX", OBJPROP_TEXT, StringFormat("ADX TREND: %.1f (%s)", adxActual, adxState));
    
    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    double ddPercent = (equityPeak > 0) ? (((equityPeak - currentEquity) / equityPeak) * 100.0) : 0.0;
    ObjectSetString(0, "MAIKO_DD", OBJPROP_TEXT, StringFormat("PICO DD: %.2f%% / %.1f%%", ddPercent, MaxDrawdownPercent));
    ObjectSetInteger(0, "MAIKO_DD", OBJPROP_COLOR, (ddPercent >= MaxDrawdownPercent * 0.7) ? clrRed : clrOrange);
    
    ObjectSetString(0, "MAIKO_Delta", OBJPROP_TEXT, StringFormat("SPREAD DELTA: %+.1f pips", spreadDelta));
    ObjectSetInteger(0, "MAIKO_Delta", OBJPROP_COLOR, (MathAbs(spreadDelta) >= MaxSpreadDeltaPips) ? clrRed : clrLightGray);
    
    ObjectSetString(0, "MAIKO_Consol", OBJPROP_TEXT, txtConsolidado);
    ObjectSetString(0, "MAIKO_Protec", OBJPROP_TEXT, txtProteccion);
    ObjectSetString(0, "MAIKO_Vered", OBJPROP_TEXT, txtVeredicto);
    ObjectSetString(0, "MAIKO_SPD", OBJPROP_TEXT, StringFormat("SPD: %.1f", spreadActual));
    ObjectSetString(0, "MAIKO_RSI", OBJPROP_TEXT, StringFormat("RSI: %.1f", rsiActual));
    ObjectSetString(0, "MAIKO_LVol", OBJPROP_TEXT, StringFormat("VOL: %.2f/%.2f", volTotal, MaxLoteTotal));
    string displayVoz = txtVoz; color colVoz = clrGold;
    if(!BotActivo) { displayVoz = "BTC PAUSADO."; colVoz = clrRed; }
    ObjectSetString(0, "MAIKO_Voz", OBJPROP_TEXT, displayVoz); ObjectSetInteger(0, "MAIKO_Voz", OBJPROP_COLOR, colVoz);
    ObjectSetString(0, "MAIKO_BtnP", OBJPROP_TEXT, BotActivo ? "ENCENDIDO" : "ENCENDER");
    ObjectSetInteger(0, "MAIKO_BtnP", OBJPROP_BGCOLOR, BotActivo ? clrRoyalBlue : clrDarkGreen);
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_YSIZE, hudMinimizado ? 35 : 360);
    ChartSetInteger(0, CHART_FOREGROUND, false); // Re-forzar en cada refresco de interfaz
}

void CrearBoton(string n, int x, int y, int w, int h, string t, color bg, color fg, int z) { 
    ObjectCreate(0, n, OBJ_BUTTON, 0, 0, 0); ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, n, OBJPROP_XSIZE, w); ObjectSetInteger(0, n, OBJPROP_YSIZE, h); ObjectSetInteger(0, n, OBJPROP_BGCOLOR, bg); ObjectSetInteger(0, n, OBJPROP_COLOR, fg);
    ObjectSetString(0, n, OBJPROP_TEXT, t); ObjectSetInteger(0, n, OBJPROP_ZORDER, z); 
}

void CrearLabel(string n, int x, int y, string t, color col, int s, int z) { 
    ObjectCreate(0, n, OBJ_LABEL, 0, 0, 0); ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
    ObjectSetString(0, n, OBJPROP_TEXT, t); ObjectSetInteger(0, n, OBJPROP_COLOR, col); ObjectSetInteger(0, n, OBJPROP_FONTSIZE, s); ObjectSetInteger(0, n, OBJPROP_ZORDER, z); 
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

//+------------------------------------------------------------------+
//|   MAIKO AI CONSENSUS BOT - kopytrading.com                       |
//|   Fix spread BTC/XAU + Log silencioso + Telegram Configurado     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, kopytrading.com"
#property link      "https://kopytrading.com"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>

CTrade        trade;
CSymbolInfo   symbolInfo;
CPositionInfo positionInfo;

enum ENUM_EXEC_MODE { MODE_FULL_AUTO = 0, MODE_SEMI_AUTO = 1 };
enum ENUM_PRESET { PRESET_AUTO = 0, PRESET_BTCUSD = 1, PRESET_XAUUSD = 2 };

//=================================================================
// PARAMETROS
//=================================================================
input group "━━━━━━ 🎯 PRESET ━━━━━━"
input ENUM_PRESET InpPreset = PRESET_AUTO; // 🎯 Preset (AUTO detecta Bitcoin u Oro por gráfico)

input group "━━━━━━ 🧠 CONSENSO ━━━━━━"
input int     InpMinConsensus     = 60; // 🎯 Consenso mínimo requerido (60% equilibrado y seguro)
input int     InpSegRefrescoOB    = 30;

input group "━━━━━━ 🔑 LICENCIA ━━━━━━"
input string  InpLicenseKey       = "KOPY-ADMIN-MASTER";
input string  InpMasterKey        = "KOPY-ADMIN-MASTER";

input group "━━━━━━ 📱 TELEGRAM ━━━━━━"
input bool    InpUseTelegram      = true;
input string  InpTelegramToken    = "8724647915:AAHDxN2u5F7k9hOGhzP9WmZnSYJyPPUP69w";
input string  InpTelegramChatID   = "906620572";

input group "━━━━━━ ⚙️ EJECUCIÓN ━━━━━━"
input ENUM_EXEC_MODE InpExecMode  = MODE_FULL_AUTO;
input int     InpEsperaInicialSeg = 60;

input group "━━━━━━ 🎯 FILTROS TENDENCIA ━━━━━━"
input bool    InpUseFiltroM15     = true;  // 🎯 REGLA DE ORO M15: Solo Compras si M15 es Alcista, Solo Ventas si es Bajista
input bool    InpUseFiltroH1      = false; // 🎯 Filtro Tendencia H1 (Suma puntos al consenso sin paralizar)
input bool    InpReentradaRapida  = true;
input int     InpSegReentrada     = 30;
input int     InpCooldownSLMin    = 10;
input int     InpCooldownNormalMin= 10;

input group "━━━━━━ 🚧 FILTRO SUELO/TECHO ━━━━━━"
input bool    InpUseFiltroSueloTecho = true;
input int     InpPeriodosSueloTecho  = 20;
input int     InpDistanciaSueloPts   = 0;   // 📏 Distancia Suelo/Techo en pts (0 = Auto: 400 Oro / 5000 BTC)
input int     InpRSI_Suelo           = 0;   // 📉 Bloqueo RSI Venta (0 = Auto: 35 Oro / 30 BTC)
input int     InpRSI_Techo           = 0;   // 📈 Bloqueo RSI Compra (0 = Auto: 65 Oro / 70 BTC)

input group "━━━━━━ 💰 RIESGO ━━━━━━"
input bool    InpUseFixedLot      = false;
input double  InpFixedLot         = 0.01;
input double  InpRiskPercent      = 0.5;
input bool    InpUseATR           = true;
input int     InpATRPeriod        = 14;
input double  InpATRMultiplier    = 2.0;

input group "━━━━━━ 🧠 FUENTES ━━━━━━"
input bool    InpUseBinanceOB      = true;
input bool    InpUseFearGreed      = true;
input bool    InpUseLSRatio        = true;
input int     InpFG_MinBuy         = 25;
input int     InpFG_MaxSell        = 75;

input group "━━━━━━ 🛡️ POSICIÓN ━━━━━━"
input bool    InpUseBreakEven      = true;
input bool    InpUseTrailing       = true;

input group "━━━━━━ ⏰ HORARIOS Y FILTROS ━━━━━━"
input int     InpHoraInicio             = 3;     // 🕒 Hora inicio operativa (servidor)
input int     InpHoraFin                = 23;    // 🕒 Hora fin operativa (23:00 servidor)
input bool    InpNoViernes              = true;  // 🚫 Bloquear Oro viernes noche (>20h)
input bool    InpPausaNoticiasUS        = true;  // 🛑 Pausa noticias EE.UU. (15:15 a 15:45 broker = 14:15 a 14:45 España)
input bool    InpFiltroVelaConfirmacion = true;  // 🕯️ Filtro Velas: Evita Dojis, Martillos contrarios y espera confirmación

input group "━━━━━━ 🚨 KILL SWITCH ━━━━━━"
input bool    InpKillSwitch        = false;

input group "━━━━━━ 🎨 HUD ━━━━━━"
input bool    InpShowHUD           = true;
input bool    InpShowArrows        = true;
input bool    InpCargarIndicadoresVisuales = true; // 📊 Dibujar Indicadores en Gráfico (EMA 20, EMA 50, RSI 14)

//=================================================================
// AUTO-CONFIG (spread corregido)
//=================================================================
string g_binanceSymbol;
int    g_magicNumber, g_slPoints, g_tpPoints, g_beTrigger, g_beLock;
int    g_trailingStart, g_trailingStep, g_slippage;
double g_maxSpread;
bool   g_isBTC = false;
int    g_distanciaSueloPts = 400;
int    g_rsiSuelo = 35;
int    g_rsiTecho = 65;

void AplicarPreset() {
    string s = _Symbol;
    StringToUpper(s);
    if(InpPreset == PRESET_BTCUSD) {
        g_isBTC = true;
    } else if(InpPreset == PRESET_XAUUSD) {
        g_isBTC = false;
    } else { // PRESET_AUTO: auto-detección según el gráfico actual
        if(StringFind(s, "BTC") >= 0 || StringFind(s, "BITCOIN") >= 0) {
            g_isBTC = true;
        } else {
            g_isBTC = false;
        }
    }

    if(g_isBTC) {
        // --- PRESET PROFESIONAL BITCOIN (BTCUSD) ---
        g_binanceSymbol = "BTCUSDT"; g_magicNumber = 202626;
        g_slPoints = 12000; g_tpPoints = 12000;              // $120 SL / $120 TP (Ratio 1:1)
        g_beTrigger = 7000; g_beLock = 2000;                 // BE al ganar $70 asegurando $20 limpios
        g_trailingStart = 9000; g_trailingStep = 3000;       // Trailing a los $90 manteniendo $30 de distancia
        g_maxSpread = 3000.0;                                // Spread máx 3000 pts ($30)
        g_distanciaSueloPts = (InpDistanciaSueloPts > 0) ? InpDistanciaSueloPts : 5000; // $50 en BTC
        g_rsiSuelo = (InpRSI_Suelo > 0) ? InpRSI_Suelo : 30; // 30 en BTC (sobreventa real)
        g_rsiTecho = (InpRSI_Techo > 0) ? InpRSI_Techo : 70; // 70 en BTC (sobrecompra real)
        g_slippage = 50;
    } else {
        // --- PRESET PROFESIONAL ORO (XAUUSD) ---
        g_binanceSymbol = "PAXGUSDT"; g_magicNumber = 202627;
        g_slPoints = 400; g_tpPoints = 400;                 // $4.00 SL / $4.00 TP (Ratio 1:1)
        g_beTrigger = 250; g_beLock = 100;                  // BE al ganar $2.50 asegurando $1.00 limpio
        g_trailingStart = 300; g_trailingStep = 150;        // Trailing a los $3.00 manteniendo $1.50 de distancia
        g_maxSpread = 100.0;                                // Spread máx 100 pts ($1.00)
        g_distanciaSueloPts = (InpDistanciaSueloPts > 0) ? InpDistanciaSueloPts : 400; // $4.00 en Oro
        g_rsiSuelo = (InpRSI_Suelo > 0) ? InpRSI_Suelo : 35; // 35 en Oro
        g_rsiTecho = (InpRSI_Techo > 0) ? InpRSI_Techo : 65; // 65 en Oro
        g_slippage = 30;
    }
}

//=================================================================
// GLOBALES
//=================================================================
string   g_symbol;
double   g_point;
bool     g_botActivo = true;
datetime g_botInicioTime = 0;
int      g_lastFearGreed = 50;
double   g_lastLSRatio = 1.0, g_lastOB_Buy = 1.0, g_lastOB_Sell = 1.0, g_lastATR = 0;
bool     g_m15Bullish = true, g_h1Bullish = true;
double   g_rsiActual = 50;
int      g_realBuyScore = 0;
int      g_realSellScore = 0;
int      g_lastSignal = 0;
datetime g_lastFGUpdate = 0, g_lastLSUpdate = 0, g_lastOBUpdate = 0;
datetime g_lastSignalTime = 0, g_lastSLTime = 0;
int      g_ultimaDireccion = 0;
double   g_peakBalance = 0, g_maxDrawdown = 0;
int      g_totalTrades = 0;
long     g_lastUpdateId = 0;
datetime g_lastTGCheck = 0;
ulong    g_lastDealTicket = 0;
bool     g_bloqueadoSuelo = false;
bool     g_bloqueadoTecho = false;
datetime g_lastLogSueloTecho = 0;  // ✅ FIX: evita spam en el log
datetime g_lastLogSpread = 0;
int      g_hEMA20_v = INVALID_HANDLE;
int      g_hEMA50_v = INVALID_HANDLE;
int      g_hRSI_v   = INVALID_HANDLE;

#define HUD_BG "MAIKO_HUD_BG"
#define BTN_POWER "MAIKO_BTN_POWER"
#define BTN_CLOSE "MAIKO_BTN_CLOSE"

// Declaraciones de funciones previas a OnInit
void AgregarIndicadoresVisuales();
int GetFearAndGreedIndex();
void GetBinanceLongShortRatio(double &ratio);
void GetBinanceOrderBookImbalance(double &buyVol, double &sellVol);
double SumOBVolume(const string &json, const string &side);
void GetATRValue();
void ActualizarTendencias();
void CreateHUD();
void UpdateHUD(int score);
void EscribirEstado();
bool CheckLicense(const string key);
void CloseAllPositions();
void SendTelegramMsg(const string message);
void ManagePositions();
void UpdateDrawdown();
int  ObtenerDireccionActual();
void CalculateConsensus(int &outScore, int &outSignal);
bool EstaPegadoASuelo();
bool EstaPegadoATecho();
int  DetectarPatronVelaPrevia(int direccion, string &nombrePatron);
bool IsOperatingHour();
int  CountOpenPositions();
bool PuedeReentrar();
bool TendenciaSigueViva();
void ExecuteTrade(int direction, int score);
double CalculateLotSize(int slPts);
double NormLot(double lot);
void RefrescarAPIs();
void DetectarCierres();
void CheckTelegramCommands();
void ProcessCommand(string cmd);
void SendStatusReport();
void EnviarEstadoGeneral();
double CalcularFlotante();
bool EsMaster();

//=================================================================
// INIT
//=================================================================
int OnInit() {
    AplicarPreset();
    if(InpKillSwitch) { CloseAllPositions(); return INIT_FAILED; }
    if(!CheckLicense(InpLicenseKey)) { Alert("Licencia invalida."); return INIT_FAILED; }

    g_symbol = _Symbol;
    symbolInfo.Name(g_symbol);
    symbolInfo.RefreshRates();
    g_point = symbolInfo.Point();
    g_peakBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    g_botInicioTime = TimeCurrent();

    trade.SetExpertMagicNumber(g_magicNumber);
    trade.SetDeviationInPoints(g_slippage);
    EventSetTimer(10);

    // Verificar si el símbolo es operable
    long tradeMode = SymbolInfoInteger(g_symbol, SYMBOL_TRADE_MODE);
    string modeTxt = "DESCONOCIDO";
    if(tradeMode == SYMBOL_TRADE_MODE_DISABLED) modeTxt = "❌ DESHABILITADO";
    else if(tradeMode == SYMBOL_TRADE_MODE_LONGONLY) modeTxt = "⚠️ Solo LONG";
    else if(tradeMode == SYMBOL_TRADE_MODE_SHORTONLY) modeTxt = "⚠️ Solo SHORT";
    else if(tradeMode == SYMBOL_TRADE_MODE_CLOSEONLY) modeTxt = "❌ SOLO CIERRE";
    else if(tradeMode == SYMBOL_TRADE_MODE_FULL) modeTxt = "✅ COMPLETO";

    if(!MQLInfoInteger(MQL_TESTER)) {
        Sleep(MathRand() % 3000);
        g_lastFearGreed = GetFearAndGreedIndex();
        Sleep(500);
        GetBinanceLongShortRatio(g_lastLSRatio);
        Sleep(500);
        double b, s;
        GetBinanceOrderBookImbalance(b, s);
        if(b > 0 && s > 0 && !(b == 1.0 && s == 1.0)) { g_lastOB_Buy = b; g_lastOB_Sell = s; }
        GetATRValue();
        ActualizarTendencias();
    }
    if(InpCargarIndicadoresVisuales) AgregarIndicadoresVisuales();
    if(InpShowHUD) { CreateHUD(); UpdateHUD(0); }
    EscribirEstado();

    HistorySelect(TimeCurrent() - 3600, TimeCurrent());
    int total = HistoryDealsTotal();
    if(total > 0) g_lastDealTicket = HistoryDealGetTicket(total - 1);

    string presetName = g_isBTC ? "BTCUSD" : "XAUUSD";
    SendTelegramMsg("🤖 *MAIKO AI Iniciado* | " + presetName + " | " + g_symbol + "\n• Modo símbolo: " + modeTxt + "\n• Consenso min: " + IntegerToString(InpMinConsensus) + "/100\n• Spread max: " + DoubleToString(g_maxSpread,0) + " pts");
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
    EventKillTimer();
    ObjectsDeleteAll(0, "MAIKO_");
    FileDelete("MAIKO_STATE_" + IntegerToString(g_magicNumber) + ".csv");
    if(g_hEMA20_v != INVALID_HANDLE) { IndicatorRelease(g_hEMA20_v); g_hEMA20_v = INVALID_HANDLE; }
    if(g_hEMA50_v != INVALID_HANDLE) { IndicatorRelease(g_hEMA50_v); g_hEMA50_v = INVALID_HANDLE; }
    if(g_hRSI_v   != INVALID_HANDLE) { IndicatorRelease(g_hRSI_v);   g_hRSI_v   = INVALID_HANDLE; }
}

//=================================================================
// INDICADORES VISUALES
//=================================================================
void AgregarIndicadoresVisuales() {
    if(!InpCargarIndicadoresVisuales) return;
    if(MQLInfoInteger(MQL_TESTER)) return;

    if(g_hEMA20_v == INVALID_HANDLE)
        g_hEMA20_v = iMA(g_symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
    if(g_hEMA50_v == INVALID_HANDLE)
        g_hEMA50_v = iMA(g_symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
    if(g_hRSI_v == INVALID_HANDLE)
        g_hRSI_v = iRSI(g_symbol, _Period, 14, PRICE_CLOSE);

    bool tieneEMA20 = false;
    bool tieneEMA50 = false;
    bool tieneRSI = false;

    int ventanas = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL);
    for(int w = 0; w < ventanas; w++) {
        int totalInd = ChartIndicatorsTotal(0, w);
        for(int i = 0; i < totalInd; i++) {
            string nombre = ChartIndicatorName(0, w, i);
            if(StringFind(nombre, "20") >= 0 && (StringFind(nombre, "MA") >= 0 || StringFind(nombre, "EMA") >= 0)) tieneEMA20 = true;
            if(StringFind(nombre, "50") >= 0 && (StringFind(nombre, "MA") >= 0 || StringFind(nombre, "EMA") >= 0)) tieneEMA50 = true;
            if(StringFind(nombre, "RSI") >= 0) tieneRSI = true;
        }
    }

    if(!tieneEMA20 && g_hEMA20_v != INVALID_HANDLE) {
        if(!ChartIndicatorAdd(0, 0, g_hEMA20_v))
            Print("Aviso: No se pudo agregar EMA 20 al gráfico. Error: ", GetLastError());
    }
    if(!tieneEMA50 && g_hEMA50_v != INVALID_HANDLE) {
        if(!ChartIndicatorAdd(0, 0, g_hEMA50_v))
            Print("Aviso: No se pudo agregar EMA 50 al gráfico. Error: ", GetLastError());
    }
    if(!tieneRSI && g_hRSI_v != INVALID_HANDLE) {
        int subWin = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL);
        if(!ChartIndicatorAdd(0, subWin, g_hRSI_v))
            Print("Aviso: No se pudo agregar RSI 14 al gráfico. Error: ", GetLastError());
    }
}

//=================================================================
// ATR Y TENDENCIAS
//=================================================================
void GetATRValue() {
    int h = iATR(g_symbol, PERIOD_M5, InpATRPeriod);
    if(h == INVALID_HANDLE) return;
    double atr[1];
    if(CopyBuffer(h, 0, 0, 1, atr) > 0) g_lastATR = atr[0];
    IndicatorRelease(h);
}

void ActualizarTendencias() {
    double price = symbolInfo.Bid();
    
    // M15: Tendencia Dinámica con EMA 20 y EMA 50
    int h20m = iMA(g_symbol, PERIOD_M15, 20, 0, MODE_EMA, PRICE_CLOSE);
    int h50m = iMA(g_symbol, PERIOD_M15, 50, 0, MODE_EMA, PRICE_CLOSE);
    if(h20m != INVALID_HANDLE && h50m != INVALID_HANDLE) {
        double a[1], b[1];
        if(CopyBuffer(h20m, 0, 0, 1, a) > 0 && CopyBuffer(h50m, 0, 0, 1, b) > 0) {
            // Alcista si el precio está sobre ambas EMAs; Bajista si está bajo ambas EMAs
            if(price > a[0] && price > b[0]) g_m15Bullish = true;
            else if(price < a[0] && price < b[0]) g_m15Bullish = false;
            else g_m15Bullish = (price > a[0]); // En transición manda la EMA 20 rápida
        }
        IndicatorRelease(h20m); IndicatorRelease(h50m);
    }
    
    // H1: Tendencia Dinámica con EMA 20 y EMA 50
    int h20 = iMA(g_symbol, PERIOD_H1, 20, 0, MODE_EMA, PRICE_CLOSE);
    int h50 = iMA(g_symbol, PERIOD_H1, 50, 0, MODE_EMA, PRICE_CLOSE);
    if(h20 != INVALID_HANDLE && h50 != INVALID_HANDLE) {
        double a[1], b[1];
        if(CopyBuffer(h20, 0, 0, 1, a) > 0 && CopyBuffer(h50, 0, 0, 1, b) > 0) {
            if(price > a[0] && price > b[0]) g_h1Bullish = true;
            else if(price < a[0] && price < b[0]) g_h1Bullish = false;
            else g_h1Bullish = (price > a[0]);
        }
        IndicatorRelease(h20); IndicatorRelease(h50);
    }
}

//=================================================================
// FILTRO SUELO/TECHO
//=================================================================
bool EstaPegadoASuelo() {
    if(!InpUseFiltroSueloTecho) return false;
    double low[];
    ArraySetAsSeries(low, true);
    int copied = CopyLow(g_symbol, PERIOD_M15, 0, InpPeriodosSueloTecho, low);
    if(copied <= 0) return false;
    int idxMin = ArrayMinimum(low, 0, copied);
    double minLow = low[idxMin];
    double distPts = (symbolInfo.Bid() - minLow) / g_point;
    return (distPts <= g_distanciaSueloPts);
}

bool EstaPegadoATecho() {
    if(!InpUseFiltroSueloTecho) return false;
    double high[];
    ArraySetAsSeries(high, true);
    int copied = CopyHigh(g_symbol, PERIOD_M15, 0, InpPeriodosSueloTecho, high);
    if(copied <= 0) return false;
    int idxMax = ArrayMaximum(high, 0, copied);
    double maxHigh = high[idxMax];
    double distPts = (maxHigh - symbolInfo.Bid()) / g_point;
    return (distPts <= g_distanciaSueloPts);
}

//=================================================================
// FILTRO ACCIÓN DEL PRECIO / VELAS DE RECHAZO
//=================================================================
int DetectarPatronVelaPrevia(int direccion, string &nombrePatron) {
    if(!InpFiltroVelaConfirmacion) return 0;
    ENUM_TIMEFRAMES tf = (_Period == PERIOD_M1) ? PERIOD_M5 : _Period;
    
    double o1 = iOpen(g_symbol, tf, 1);
    double c1 = iClose(g_symbol, tf, 1);
    double h1 = iHigh(g_symbol, tf, 1);
    double l1 = iLow(g_symbol, tf, 1);
    double range = h1 - l1;
    if(range <= 0) return 0;
    
    double body = MathAbs(c1 - o1);
    double upperWick = h1 - MathMax(c1, o1);
    double lowerWick = MathMin(c1, o1) - l1;
    double bodyRatio = body / range;
    double lowerRatio = lowerWick / range;
    double upperRatio = upperWick / range;
    
    // 1. Vela de Indecisión (Doji o Peonza con cuerpo minúsculo < 20% del rango)
    if(bodyRatio < 0.20) {
        nombrePatron = "DOJI INDECISIÓN";
        return 1;
    }
    
    // 2. Para SEÑAL DE VENTA (-1):
    if(direccion == -1) {
        // Martillo Alcista: Mecha inferior larga (> 40% del rango) -> Rechazo de mínimos
        if(lowerRatio > 0.40) {
            nombrePatron = "MARTILLO ALCISTA";
            return 2;
        }
        // Vela contraria: Si la vela previa cerró verde (alcista)
        if(c1 > o1) {
            nombrePatron = "ESPERANDO VELA ROJA";
            return 3;
        }
    }
    
    // 3. Para SEÑAL DE COMPRA (+1):
    if(direccion == 1) {
        // Estrella Fugaz: Mecha superior larga (> 40% del rango) -> Rechazo de máximos
        if(upperRatio > 0.40) {
            nombrePatron = "ESTRELLA FUGAZ";
            return 2;
        }
        // Vela contraria: Si la vela previa cerró roja (bajista)
        if(c1 < o1) {
            nombrePatron = "ESPERANDO VELA VERDE";
            return 3;
        }
    }
    
    return 0; // Confirmación limpia
}

//=================================================================
// REFRESCO APIs
//=================================================================
void RefrescarAPIs() {
    if(MQLInfoInteger(MQL_TESTER)) return;
    if((TimeCurrent() - g_lastFGUpdate) > 900) {
        g_lastFearGreed = GetFearAndGreedIndex();
        g_lastFGUpdate = TimeCurrent();
    }
    if(InpUseBinanceOB && (TimeCurrent() - g_lastOBUpdate) > InpSegRefrescoOB) {
        double b = 1, s = 1;
        GetBinanceOrderBookImbalance(b, s);
        if(!(b == 1.0 && s == 1.0)) {
            g_lastOB_Buy = b;
            g_lastOB_Sell = s;
        }
        g_lastOBUpdate = TimeCurrent();
    }
    if((TimeCurrent() - g_lastLSUpdate) > 300) {
        GetBinanceLongShortRatio(g_lastLSRatio);
        g_lastLSUpdate = TimeCurrent();
    }
    GetATRValue();
    ActualizarTendencias();
}

//=================================================================
// TICK
//=================================================================
void OnTick() {
    if(!g_botActivo) return;
    if(InpKillSwitch) { CloseAllPositions(); g_botActivo = false; return; }
    
    symbolInfo.RefreshRates();
    ManagePositions();
    UpdateDrawdown();
    g_ultimaDireccion = ObtenerDireccionActual();
    
    ActualizarTendencias();
    int score = 0, signal = 0;
    CalculateConsensus(score, signal);
    g_lastSignal = signal;
    
    g_bloqueadoSuelo = EstaPegadoASuelo();
    g_bloqueadoTecho = EstaPegadoATecho();
    
    if(InpShowHUD) UpdateHUD(score);
    
    if(!IsOperatingHour()) return;
    if((TimeCurrent() - g_botInicioTime) < InpEsperaInicialSeg) return;
    if(CountOpenPositions() >= 1) return;
    if(!PuedeReentrar()) return;
    
    // Filtro de spread CON DIAGNÓSTICO
    double spreadNow = (symbolInfo.Ask() - symbolInfo.Bid()) / g_point;
    if(spreadNow > g_maxSpread) {
        if((TimeCurrent() - g_lastLogSpread) > 300) {
            Print("⏸️ OPERACIÓN BLOQUEADA POR SPREAD | Spread actual: ", DoubleToString(spreadNow,0), " pts | Máximo permitido: ", DoubleToString(g_maxSpread,0), " pts");
            g_lastLogSpread = TimeCurrent();
        }
        return;
    }
    
    if(signal != 0 && score >= InpMinConsensus) {
        if(InpUseFiltroM15) {
            if(signal == 1 && !g_m15Bullish) return;
            if(signal == -1 && g_m15Bullish) return;
        }
        if(InpUseFiltroH1) {
            if(signal == 1 && !g_h1Bullish) return;
            if(signal == -1 && g_h1Bullish) return;
        }
        if(g_bloqueadoSuelo && signal == -1) {
            // ✅ FIX: solo imprime una vez cada 5 minutos
            if((TimeCurrent() - g_lastLogSueloTecho) > 300) {
                Print("VENTA bloqueada: precio pegado al SUELO M15");
                g_lastLogSueloTecho = TimeCurrent();
            }
            return;
        }
        if(g_bloqueadoTecho && signal == 1) {
            if((TimeCurrent() - g_lastLogSueloTecho) > 300) {
                Print("COMPRA bloqueada: precio pegado al TECHO M15");
                g_lastLogSueloTecho = TimeCurrent();
            }
            return;
        }
        if(g_rsiSuelo > 0 && g_rsiActual <= g_rsiSuelo && signal == -1) {
            if((TimeCurrent() - g_lastLogSueloTecho) > 300) {
                Print("VENTA bloqueada: RSI ", DoubleToString(g_rsiActual,1), " en zona SUELO (<= ", g_rsiSuelo, ")");
                g_lastLogSueloTecho = TimeCurrent();
            }
            return;
        }
        if(g_rsiTecho > 0 && g_rsiActual >= g_rsiTecho && signal == 1) {
            if((TimeCurrent() - g_lastLogSueloTecho) > 300) {
                Print("COMPRA bloqueada: RSI ", DoubleToString(g_rsiActual,1), " en zona TECHO (>= ", g_rsiTecho, ")");
                g_lastLogSueloTecho = TimeCurrent();
            }
            return;
        }
        if(InpFiltroVelaConfirmacion) {
            string motivoBloqueo = "";
            if(DetectarPatronVelaPrevia(signal, motivoBloqueo) > 0) return;
        }
        g_lastSignalTime = TimeCurrent();
        g_ultimaDireccion = signal;
        if(InpExecMode == MODE_FULL_AUTO) ExecuteTrade(signal, score);
        else SendTelegramMsg("SEÑAL SEMI-AUTO | " + g_symbol + " | " + (signal==1?"COMPRA":"VENTA") + " | Score: " + IntegerToString(score));
    }
}

//=================================================================
// REENTRADA
//=================================================================
bool PuedeReentrar() {
    if(g_lastSignalTime == 0) return true;
    int segs = (int)(TimeCurrent() - g_lastSignalTime);
    if(g_lastSLTime > 0 && (TimeCurrent() - g_lastSLTime) < (InpCooldownSLMin * 60)) return false;
    if(segs < InpSegReentrada) return false;
    if(!InpReentradaRapida) return (segs >= InpCooldownNormalMin * 60);
    if(TendenciaSigueViva()) return true;
    return (segs >= InpCooldownNormalMin * 60);
}

bool TendenciaSigueViva() {
    if(InpUseFiltroM15 && InpUseFiltroH1 && g_m15Bullish != g_h1Bullish) return false;
    if(g_ultimaDireccion == 1 && g_rsiActual > 70) return false;
    if(g_ultimaDireccion == -1 && g_rsiActual < 30) return false;
    int h = iMA(g_symbol, PERIOD_M5, 20, 0, MODE_EMA, PRICE_CLOSE);
    if(h != INVALID_HANDLE) {
        double e[1];
        if(CopyBuffer(h, 0, 0, 1, e) > 0) {
            double dist = MathAbs(symbolInfo.Bid() - e[0]) / g_point;
            double atrPts = (g_lastATR > 0) ? g_lastATR / g_point : 100;
            if(dist > atrPts * 2.5) { IndicatorRelease(h); return false; }
        }
        IndicatorRelease(h);
    }
    if(g_ultimaDireccion == 1 && g_lastOB_Buy < g_lastOB_Sell * 0.9) return false;
    if(g_ultimaDireccion == -1 && g_lastOB_Sell < g_lastOB_Buy * 0.9) return false;
    return true;
}

int ObtenerDireccionActual() {
    for(int i = PositionsTotal()-1; i>=0; i--) {
        if(!positionInfo.SelectByIndex(i)) continue;
        if(positionInfo.Symbol() != g_symbol || positionInfo.Magic() != g_magicNumber) continue;
        return (positionInfo.PositionType() == POSITION_TYPE_BUY) ? 1 : -1;
    }
    return g_ultimaDireccion;
}

//=================================================================
// TIMER
//=================================================================
void OnTimer() {
    RefrescarAPIs();
    ManagePositions();
    EscribirEstado();
    DetectarCierres();
    CheckTelegramCommands();
}

//=================================================================
// DETECTAR CIERRES
//=================================================================
void DetectarCierres() {
    HistorySelect(TimeCurrent() - 3600, TimeCurrent());
    int total = HistoryDealsTotal();
    if(total == 0) return;
    for(int i = total - 1; i >= 0; i--) {
        ulong ticket = HistoryDealGetTicket(i);
        if(ticket == 0) continue;
        if(ticket <= g_lastDealTicket) break;
        long magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
        long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
        long reason = HistoryDealGetInteger(ticket, DEAL_REASON);
        if(magic == g_magicNumber && entry == DEAL_ENTRY_OUT) {
            double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            double price = HistoryDealGetDouble(ticket, DEAL_PRICE);
            string symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
            string motivo = "MANUAL"; string emoji = "🔵";
            if(reason == DEAL_REASON_TP) { motivo = "TAKE PROFIT"; emoji = "✅"; }
            else if(reason == DEAL_REASON_SL) { 
                if(profit >= 0) { motivo = "TRAILING/BE PROFIT"; emoji = "🟢"; }
                else { motivo = "STOP LOSS"; emoji = "❌"; }
            }
            else if(reason == DEAL_REASON_SO) { motivo = "STOP OUT"; emoji = "⚠️"; }
            
            // Solo pausar con cooldown si fue un Stop Loss con PÉRDIDA real
            if(reason == DEAL_REASON_SL && profit < 0) {
                g_lastSLTime = TimeCurrent();
                Print("SL con pérdida real detectado ($", DoubleToString(profit,2), "). Cooldown de ", InpCooldownSLMin, " minutos.");
            }
            string msg = emoji + " CIERRE " + motivo + " | " + symbol + "\n";
            msg += "Precio: " + DoubleToString(price, _Digits) + "\n";
            msg += "Resultado: $" + DoubleToString(profit, 2) + "\n";
            msg += "Balance: $" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2);
            SendTelegramMsg(msg);
        }
        if(ticket > g_lastDealTicket) g_lastDealTicket = ticket;
    }
}

//=================================================================
// ESTADO COMPARTIDO
//=================================================================
double CalcularFlotante() {
    double f = 0;
    for(int i = PositionsTotal()-1; i>=0; i--)
        if(positionInfo.SelectByIndex(i) && positionInfo.Symbol() == g_symbol && positionInfo.Magic() == g_magicNumber)
            f += positionInfo.Profit();
    return f;
}

void EscribirEstado() {
    string filename = "MAIKO_STATE_" + IntegerToString(g_magicNumber) + ".csv";
    int handle = FileOpen(filename, FILE_WRITE|FILE_CSV|FILE_ANSI, ';');
    if(handle == INVALID_HANDLE) return;
    int maxScore = MathMax(g_realBuyScore, g_realSellScore);
    FileWrite(handle,
        g_symbol,
        g_isBTC ? "BTC" : "XAU",
        (g_botActivo ? "ACTIVO" : "PAUSADO"),
        DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2),
        DoubleToString(CalcularFlotante(), 2),
        IntegerToString(CountOpenPositions()),
        IntegerToString(maxScore),
        ((g_lastSignal==1)?"COMPRA":(g_lastSignal==-1)?"VENTA":"ESPERANDO"),
        (g_m15Bullish ? "ALC" : "BAJ"),
        (g_h1Bullish ? "ALC" : "BAJ"),
        DoubleToString(g_rsiActual, 0),
        IntegerToString(g_magicNumber),
        TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES)
    );
    FileClose(handle);
}

bool EsMaster() {
    if(!GlobalVariableCheck("MAIKO_MASTER_MAGIC")) return true;
    return (g_magicNumber == (int)GlobalVariableGet("MAIKO_MASTER_MAGIC"));
}

void EnviarEstadoGeneral() {
    if(!EsMaster()) return;
    string msg = "📊 ESTADO GENERAL - MAIKO AI\n";
    msg += "═══════════════════════\n";
    double balTotal = 0, flotTotal = 0;
    int totalPos = 0;
    string filename;
    long h = FileFindFirst("MAIKO_STATE_*.csv", filename, 0);
    if(h == INVALID_HANDLE) { SendTelegramMsg("No hay bots MAIKO reportando."); return; }
    do {
        int fh = FileOpen(filename, FILE_READ|FILE_CSV|FILE_ANSI, ';');
        if(fh == INVALID_HANDLE) continue;
        string sym = FileReadString(fh);
        string preset = FileReadString(fh);
        string estado = FileReadString(fh);
        double bal = StringToDouble(FileReadString(fh));
        double flot = StringToDouble(FileReadString(fh));
        int pos = (int)StringToInteger(FileReadString(fh));
        int cons = (int)StringToInteger(FileReadString(fh));
        string senal = FileReadString(fh);
        string t15 = FileReadString(fh);
        string t1h = FileReadString(fh);
        double rsi = StringToDouble(FileReadString(fh));
        string actualizado = FileReadString(fh);
        FileClose(fh);
        msg += "🤖 " + preset + " (" + sym + ")\n";
        msg += "  • Estado: " + estado + "\n";
        msg += "  • Balance: $" + DoubleToString(bal,2) + "\n";
        msg += "  • Flotante: $" + DoubleToString(flot,2) + "\n";
        msg += "  • Posiciones: " + IntegerToString(pos) + "\n";
        msg += "  • Consenso: " + IntegerToString(cons) + "/100\n";
        msg += "  • Señal: " + senal + "\n";
        msg += "  • M15/H1: " + t15 + "/" + t1h + " | RSI: " + DoubleToString(rsi,0) + "\n";
        msg += "  • Actualizado: " + actualizado + "\n";
        msg += "───────────────────────\n";
        balTotal += bal; flotTotal += flot; totalPos += pos;
    } while(FileFindNext(h, filename));
    FileFindClose(h);
    msg += "💰 TOTAL\n";
    msg += "Balance: $" + DoubleToString(balTotal,2) + "\n";
    msg += "Flotante: $" + DoubleToString(flotTotal,2) + "\n";
    msg += "Posiciones: " + IntegerToString(totalPos);
    SendTelegramMsg(msg);
}

//=================================================================
// TELEGRAM
//=================================================================
void CheckTelegramCommands() {
    if(!InpUseTelegram || InpTelegramToken == "" || InpTelegramChatID == "") return;
    if(MQLInfoInteger(MQL_TESTER)) return;
    if(TimeCurrent() - g_lastTGCheck < 10) return;
    g_lastTGCheck = TimeCurrent();
    string url = "https://api.telegram.org/bot" + InpTelegramToken + "/getUpdates?limit=10&timeout=1";
    if(g_lastUpdateId > 0) url += "&offset=" + IntegerToString(g_lastUpdateId + 1);
    char post[], result[]; string headers = "User-Agent: Mozilla/5.0\r\n"; string rHeaders;
    ResetLastError();
    if(WebRequest("GET", url, headers, 5000, post, result, rHeaders) != 200) return;
    string json = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
    if(g_lastUpdateId == 0) {
        int up = 0;
        while(true) {
            int p = StringFind(json, "\"update_id\":", up);
            if(p < 0) break;
            int s = p + 12, e = s;
            while(e < StringLen(json) && StringGetCharacter(json, e) >= '0' && StringGetCharacter(json, e) <= '9') e++;
            long id = StringToInteger(StringSubstr(json, s, e - s));
            if(id > g_lastUpdateId) g_lastUpdateId = id;
            up = e;
        }
        return;
    }
    int pos = 0;
    while(true) {
        int updPos = StringFind(json, "\"update_id\":", pos);
        if(updPos < 0) break;
        int idStart = updPos + 12, idEnd = idStart;
        while(idEnd < StringLen(json) && StringGetCharacter(json, idEnd) >= '0' && StringGetCharacter(json, idEnd) <= '9') idEnd++;
        long updateId = StringToInteger(StringSubstr(json, idStart, idEnd - idStart));
        if(updateId <= g_lastUpdateId) { pos = idEnd; continue; }
        g_lastUpdateId = updateId;
        int textPos = StringFind(json, "\"text\":\"", idEnd);
        if(textPos > 0 && textPos < idEnd + 300) {
            int tStart = textPos + 8;
            int tEnd = StringFind(json, "\"", tStart);
            if(tEnd > tStart) ProcessCommand(StringSubstr(json, tStart, tEnd - tStart));
        }
        pos = idEnd;
    }
}

void ProcessCommand(string cmd) {
    StringToLower(cmd);
    StringTrimLeft(cmd); StringTrimRight(cmd);
    if(StringFind(cmd, "/general") >= 0) { EnviarEstadoGeneral(); return; }
    if(StringFind(cmd, "/estado") >= 0) { SendStatusReport(); }
    else if(StringFind(cmd, "/cerrar") >= 0) { CloseAllPositions(); SendTelegramMsg("CIERRE MANUAL | " + g_symbol); }
    else if(StringFind(cmd, "/pausa") >= 0) { g_botActivo = false; SendTelegramMsg("BOT PAUSADO | " + g_symbol); }
    else if(StringFind(cmd, "/activar") >= 0) { g_botActivo = true; SendTelegramMsg("BOT ACTIVADO | " + g_symbol); }
    else if(StringFind(cmd, "/ayuda") >= 0 || StringFind(cmd, "/help") >= 0 || StringFind(cmd, "/start") >= 0) {
        SendTelegramMsg("COMANDOS MAIKO (" + g_symbol + "):\n\n/estado - Estado de este bot\n/general - Estado de TODOS\n/cerrar - Cerrar posiciones\n/pausa - Pausar\n/activar - Reanudar");
    }
}

void SendStatusReport() {
    string presetName = g_isBTC ? "BTCUSD" : "XAUUSD";
    int nPos = CountOpenPositions();
    double flotante = CalcularFlotante();
    double spreadNow = (symbolInfo.Ask() - symbolInfo.Bid()) / g_point;
    string msg = "📊 ESTADO " + presetName + " (" + g_symbol + ")\n";
    msg += "──────────────────\n";
    msg += "Estado: " + (g_botActivo ? "ACTIVO" : "PAUSADO") + "\n";
    msg += "Balance: $" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2) + "\n";
    msg += "Flotante: $" + DoubleToString(flotante,2) + "\n";
    msg += "Posiciones: " + IntegerToString(nPos) + "\n";
    msg += "Spread: " + DoubleToString(spreadNow,0) + " / max " + DoubleToString(g_maxSpread,0) + "\n";
    msg += "BUY score: " + IntegerToString(g_realBuyScore) + "/100\n";
    msg += "SELL score: " + IntegerToString(g_realSellScore) + "/100\n";
    msg += "Minimo: " + IntegerToString(InpMinConsensus) + "/100\n";
    msg += "Señal: " + ((g_lastSignal==1)?"COMPRA":(g_lastSignal==-1)?"VENTA":"ESPERANDO") + "\n";
    msg += "Tend M15: " + (g_m15Bullish ? "ALCISTA" : "BAJISTA") + "\n";
    msg += "Tend H1:  " + (g_h1Bullish ? "ALCISTA" : "BAJISTA") + "\n";
    msg += "RSI: " + DoubleToString(g_rsiActual,1) + "\n";
    msg += "Suelo/Techo: " + (g_bloqueadoSuelo ? "SUELO!" : g_bloqueadoTecho ? "TECHO!" : "OK") + "\n";
    msg += "F&G: " + IntegerToString(g_lastFearGreed) + "\n";
    msg += "L/S Ratio: " + DoubleToString(g_lastLSRatio,2) + "\n";
    msg += "OB: " + DoubleToString(g_lastOB_Buy,1) + " / " + DoubleToString(g_lastOB_Sell,1);
    SendTelegramMsg(msg);
}

//=================================================================
// BOTONES HUD
//=================================================================
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
    if(id != CHARTEVENT_OBJECT_CLICK) return;
    if(sparam == BTN_POWER) {
        g_botActivo = !g_botActivo;
        if(g_botActivo) {
            ObjectSetString(0, BTN_POWER, OBJPROP_TEXT, "ENCENDIDO");
            ObjectSetInteger(0, BTN_POWER, OBJPROP_BGCOLOR, clrGreen);
        } else {
            ObjectSetString(0, BTN_POWER, OBJPROP_TEXT, "APAGADO");
            ObjectSetInteger(0, BTN_POWER, OBJPROP_BGCOLOR, clrDarkRed);
        }
        ChartRedraw();
    }
    if(sparam == BTN_CLOSE) { CloseAllPositions(); ChartRedraw(); }
}

//=================================================================
// CONSENSO
//=================================================================
void CalculateConsensus(int &outScore, int &outSignal) {
    outScore = 0; outSignal = 0;
    double buyPres = g_lastOB_Buy;
    double sellPres = g_lastOB_Sell;
    int fg = g_lastFearGreed;
    // 1. Tendencia Dinámica Corto Plazo M5 (EMA 20, 50, 200) -> 20%
    int ema20h = iMA(g_symbol,PERIOD_M5,20,0,MODE_EMA,PRICE_CLOSE);
    int ema50h = iMA(g_symbol,PERIOD_M5,50,0,MODE_EMA,PRICE_CLOSE);
    int ema200h= iMA(g_symbol,PERIOD_M5,200,0,MODE_EMA,PRICE_CLOSE);
    double e20[1],e50[1],e200[1];
    CopyBuffer(ema20h,0,0,1,e20); CopyBuffer(ema50h,0,0,1,e50); CopyBuffer(ema200h,0,0,1,e200);
    IndicatorRelease(ema20h); IndicatorRelease(ema50h); IndicatorRelease(ema200h);
    double price = symbolInfo.Bid();
    bool tBull = (price > e20[0] && (e20[0] >= e50[0] || price > e50[0]));
    bool tBear = (price < e20[0] && (e20[0] <= e50[0] || price < e50[0]));
    
    // 2. RSI 14 Momentum M5 -> 15%
    int rsiH = iRSI(g_symbol,PERIOD_M5,14,PRICE_CLOSE);
    double rsi[1]; CopyBuffer(rsiH,0,0,1,rsi); IndicatorRelease(rsiH);
    g_rsiActual = rsi[0];
    bool rsiBull = (rsi[0] > 35 && rsi[0] < 58);
    bool rsiBear = (rsi[0] > 42 && rsi[0] < 65);
    
    // 3. Sentimiento Long/Short Ratio Binance -> 15%
    bool lsBull = false, lsBear = false;
    if(InpUseLSRatio) {
        if(g_lastLSRatio < 0.9) lsBull = true;
        else if(g_lastLSRatio > 1.2) lsBear = true;
    }
    
    // --- PUNTUACIÓN COMPRA (BUY) ---
    int buyS = 0;
    if(buyPres > sellPres*1.3) buyS += 25; 
    else if(buyPres > sellPres*1.1) buyS += 15; 
    else if(sellPres > buyPres*1.2) buyS -= 10;
    
    if(tBull) buyS += 20; else if(tBear) buyS -= 10;
    if(g_m15Bullish) buyS += 20; else buyS -= 10;
    
    if(rsiBull) buyS += 15; 
    else if(rsi[0] >= 70) buyS -= 15;
    
    if(lsBull) buyS += 15; else if(lsBear) buyS -= 10;
    if(g_h1Bullish) buyS += 10; else buyS -= 5;
    
    if(InpUseFearGreed) { 
        if(fg <= 25) buyS += 10; 
        else if(fg <= InpFG_MinBuy) buyS += 5; 
        else if(fg > InpFG_MaxSell) buyS -= 5; 
    }
    if(g_lastATR > 0) buyS += 5;
    
    // --- PUNTUACIÓN VENTA (SELL) ---
    int selS = 0;
    if(sellPres > buyPres*1.3) selS += 25; 
    else if(sellPres > buyPres*1.1) selS += 15; 
    else if(buyPres > sellPres*1.2) selS -= 10;
    
    if(tBear) selS += 20; else if(tBull) selS -= 10;
    if(!g_m15Bullish) selS += 20; else selS -= 10;
    
    if(rsiBear) selS += 15; 
    else if(rsi[0] <= 30) selS -= 15;
    
    if(lsBear) selS += 15; else if(lsBull) selS -= 10;
    if(!g_h1Bullish) selS += 10; else selS -= 5;
    
    if(InpUseFearGreed) { 
        if(fg >= 75) selS += 10; 
        else if(fg >= InpFG_MaxSell) selS += 5; 
        else if(fg < InpFG_MinBuy) selS -= 5; 
    }
    if(g_lastATR > 0) selS += 5;
    
    buyS = MathMax(0, MathMin(100, buyS));
    selS = MathMax(0, MathMin(100, selS));
    g_realBuyScore = buyS;
    g_realSellScore = selS;
    if(buyS > selS && buyS >= InpMinConsensus) { outSignal=1;  outScore=buyS; }
    else if(selS > buyS && selS >= InpMinConsensus) { outSignal=-1; outScore=selS; }
    else outScore = MathMax(buyS, selS);
}

//=================================================================
// APIS
//=================================================================
void GetBinanceOrderBookImbalance(double &buyVol, double &sellVol) {
    buyVol=1; sellVol=1;
    string url = "https://www.binance.com/api/v3/depth?symbol=" + g_binanceSymbol + "&limit=20";
    char post[], result[]; string headers = "User-Agent: Mozilla/5.0\r\n"; string rHeaders;
    ResetLastError();
    if(WebRequest("GET", url, headers, 5000, post, result, rHeaders) != 200) return;
    string json = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
    buyVol = SumOBVolume(json, "bids"); sellVol = SumOBVolume(json, "asks");
}

double SumOBVolume(const string &json, const string &side) {
    double total = 0; int pos = StringFind(json, "\"" + side + "\":");
    if(pos < 0) return 1; pos = StringFind(json, "[", pos); if(pos < 0) return 1;
    int depth=0, count=0;
    for(int i=pos; i<StringLen(json) && count<20; i++) {
        ushort c = StringGetCharacter(json, i);
        if(c=='[') depth++; if(c==']') { depth--; if(depth==0) break; }
        if(c==',' && depth==2) {
            int q1=StringFind(json,"\"",i); if(q1<0) continue;
            int q2=StringFind(json,"\"",q1+1); if(q2<0) continue;
            total += StringToDouble(StringSubstr(json,q1+1,q2-q1-1)); count++;
        }
    }
    return total > 0 ? total : 1;
}

int GetFearAndGreedIndex() {
    char post[], result[]; string headers = "User-Agent: Mozilla/5.0\r\n"; string rHeaders;
    ResetLastError();
    if(WebRequest("GET","https://api.alternative.me/fng/?limit=1&format=json",headers,5000,post,result,rHeaders) != 200) return 50;
    string json = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
    int pos = StringFind(json, "\"value\":\""); if(pos < 0) return 50; pos += 9;
    int end = StringFind(json,"\"",pos); if(end<=pos) return 50;
    return MathMax(0, MathMin(100, (int)StringToInteger(StringSubstr(json,pos,end-pos))));
}

void GetBinanceLongShortRatio(double &ratio) {
    ratio = 1.0;
    string url = "https://fapi.binance.com/futures/data/globalLongShortAccountRatio?symbol=" + g_binanceSymbol + "&period=5m&limit=1";
    char post[], result[]; string headers = "User-Agent: Mozilla/5.0\r\n"; string rHeaders;
    ResetLastError();
    if(WebRequest("GET", url, headers, 5000, post, result, rHeaders) != 200) return;
    string json = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
    int pos = StringFind(json, "\"longShortRatio\":\""); if(pos < 0) return; pos += 18;
    int end = StringFind(json, "\"", pos);
    if(end > pos) ratio = StringToDouble(StringSubstr(json, pos, end-pos));
}

//=================================================================
// EJECUTAR
//=================================================================
void ExecuteTrade(int direction, int score) {
    symbolInfo.RefreshRates();
    double price = (direction==1) ? symbolInfo.Ask() : symbolInfo.Bid();
    int slPts = g_slPoints, tpPts = g_tpPoints;
    if(InpUseATR && g_lastATR > 0) {
        double atrPts = g_lastATR / g_point;
        int atrSl = (int)(atrPts * InpATRMultiplier);
        if(atrSl > slPts) slPts = atrSl;
        if(!g_isBTC && slPts > 800) slPts = 800;    // Máx $8.00 de SL en Oro
        if(g_isBTC && slPts > 18000) slPts = 18000; // Máx $180 de SL en Bitcoin
        tpPts = (int)(slPts * 1.0);                 // Ratio 1:1 (objetivo más alcanzable y seguro)
    }
    double lot = CalculateLotSize(slPts);
    double stopsLevel = (double)SymbolInfoInteger(g_symbol, SYMBOL_TRADE_STOPS_LEVEL) * g_point;
    double sl, tp;
    if(direction==1) {
        sl = NormalizeDouble(price - slPts*g_point, symbolInfo.Digits());
        tp = NormalizeDouble(price + tpPts*g_point, symbolInfo.Digits());
        if(price - sl < stopsLevel) sl = NormalizeDouble(price - stopsLevel, symbolInfo.Digits());
    } else {
        sl = NormalizeDouble(price + slPts*g_point, symbolInfo.Digits());
        tp = NormalizeDouble(price - tpPts*g_point, symbolInfo.Digits());
        if(sl - price < stopsLevel) sl = NormalizeDouble(price + stopsLevel, symbolInfo.Digits());
    }
    string commentTag = (direction==1 ? "MAIKO_AI_BUY_" : "MAIKO_AI_SELL_") + (g_isBTC ? "BTC" : "GOLD");
    bool ok = (direction==1) ? trade.Buy(lot, g_symbol, price, sl, tp, commentTag) : trade.Sell(lot, g_symbol, price, sl, tp, commentTag);
    if(ok) {
        g_totalTrades++;
        g_ultimaDireccion = direction;
        if(InpShowArrows) {
            string arrowName = "MAIKO_ARROW_" + IntegerToString(TimeCurrent()) + "_" + IntegerToString(g_totalTrades);
            if(direction == 1) {
                ObjectCreate(0, arrowName, OBJ_ARROW_UP, 0, TimeCurrent(), price);
                ObjectSetInteger(0, arrowName, OBJPROP_COLOR, clrLime);
                ObjectSetInteger(0, arrowName, OBJPROP_WIDTH, 3);
                ObjectSetInteger(0, arrowName, OBJPROP_ARROWCODE, 233);
            } else {
                ObjectCreate(0, arrowName, OBJ_ARROW_DOWN, 0, TimeCurrent(), price);
                ObjectSetInteger(0, arrowName, OBJPROP_COLOR, clrRed);
                ObjectSetInteger(0, arrowName, OBJPROP_WIDTH, 3);
                ObjectSetInteger(0, arrowName, OBJPROP_ARROWCODE, 234);
            }
            ObjectSetInteger(0, arrowName, OBJPROP_ANCHOR, ANCHOR_CENTER);
        }
        string msg = "🚀 NUEVA ENTRADA | " + g_symbol + "\n";
        msg += "Tipo: " + (direction==1?"COMPRA":"VENTA") + "\n";
        msg += "Lote: " + DoubleToString(lot,2) + "\n";
        msg += "Precio: " + DoubleToString(price,symbolInfo.Digits()) + "\n";
        msg += "SL: " + DoubleToString(sl,symbolInfo.Digits()) + "\n";
        msg += "TP: " + DoubleToString(tp,symbolInfo.Digits()) + "\n";
        msg += "Consenso: " + IntegerToString(score) + "/100";
        SendTelegramMsg(msg);
    } else {
        Print("Error al abrir operación: ", trade.ResultRetcodeDescription(), " (code ", trade.ResultRetcode(), ")");
    }
}

//=================================================================
// GESTIÓN POSICIONES
//=================================================================
void ManagePositions() {
    for(int i=PositionsTotal()-1; i>=0; i--) {
        if(!positionInfo.SelectByIndex(i)) continue;
        if(positionInfo.Symbol() != g_symbol || positionInfo.Magic() != g_magicNumber) continue;
        double openP = positionInfo.PriceOpen(), curSL = positionInfo.StopLoss(), curTP = positionInfo.TakeProfit();
        ulong ticket = positionInfo.Ticket(); bool isBuy = (positionInfo.PositionType()==POSITION_TYPE_BUY);
        symbolInfo.RefreshRates(); double curP = isBuy ? symbolInfo.Bid() : symbolInfo.Ask();
        double ptsProfit = isBuy ? (curP-openP)/g_point : (openP-curP)/g_point;
        double stopsLevel = (double)SymbolInfoInteger(g_symbol, SYMBOL_TRADE_STOPS_LEVEL) * g_point;
        double minDistance = MathMax(stopsLevel, (symbolInfo.Ask() - symbolInfo.Bid()) + 50*g_point);
        
        if(InpUseBreakEven && ptsProfit >= g_beTrigger) {
            double newSL = NormalizeDouble(isBuy ? openP + g_beLock*g_point : openP - g_beLock*g_point, symbolInfo.Digits());
            bool distOk = isBuy ? ((curP - newSL) >= minDistance) : ((newSL - curP) >= minDistance);
            bool move = distOk && (isBuy ? (newSL>curSL) : (curSL==0 || newSL<curSL));
            if(move && trade.PositionModify(ticket, newSL, curTP)) SendTelegramMsg("BREAK-EVEN | " + g_symbol);
        }
        if(InpUseTrailing && ptsProfit >= g_trailingStart) {
            double newSL = NormalizeDouble(isBuy ? curP - g_trailingStep*g_point : curP + g_trailingStep*g_point, symbolInfo.Digits());
            bool distOk = isBuy ? ((curP - newSL) >= minDistance) : ((newSL - curP) >= minDistance);
            bool move = distOk && (isBuy ? (newSL>curSL) : (curSL==0 || newSL<curSL));
            if(move) trade.PositionModify(ticket, newSL, curTP);
        }
    }
}

//=================================================================
// HUD
//=================================================================
void CreateHUD() {
    ObjectCreate(0, HUD_BG, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, HUD_BG, OBJPROP_XDISTANCE, 10);
    ObjectSetInteger(0, HUD_BG, OBJPROP_YDISTANCE, 20);
    ObjectSetInteger(0, HUD_BG, OBJPROP_XSIZE, 280);
    ObjectSetInteger(0, HUD_BG, OBJPROP_YSIZE, 360);
    ObjectSetInteger(0, HUD_BG, OBJPROP_BGCOLOR, C'15,20,30');
    ObjectSetInteger(0, HUD_BG, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, HUD_BG, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, HUD_BG, OBJPROP_COLOR, clrDodgerBlue);
    ObjectSetInteger(0, HUD_BG, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, HUD_BG, OBJPROP_BACK, false);
    
    int yPositions[15] = {
        28,  // L0: Cabecera
        46,  // L1: Preset
        64,  // L2: Estado
        84,  // L3: Señal (Destacado)
        104, // L4: Potencia BUY/SELL (Destacado)
        124, // L5: Objetivo / Faltan % (Destacado)
        146, // L6: Tend M15 / H1
        164, // L7: RSI
        182, // L8: F&G / L/S
        200, // L9: OB
        218, // L10: ATR / Spread
        236, // L11: Reentrada
        254, // L12: Dist.Extremo
        272, // L13: Balance
        290  // L14: Info
    };
    
    for(int i = 0; i < 15; i++) {
        string name = "MAIKO_HUD_L" + IntegerToString(i);
        ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 20);
        ObjectSetInteger(0, name, OBJPROP_YDISTANCE, yPositions[i]);
        ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
        ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
        ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
        ObjectSetInteger(0, name, OBJPROP_BACK, false);
        ObjectSetString(0, name, OBJPROP_TEXT, "");
    }
    ObjectCreate(0, BTN_POWER, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, BTN_POWER, OBJPROP_XDISTANCE, 18);
    ObjectSetInteger(0, BTN_POWER, OBJPROP_YDISTANCE, 318);
    ObjectSetInteger(0, BTN_POWER, OBJPROP_XSIZE, 120);
    ObjectSetInteger(0, BTN_POWER, OBJPROP_YSIZE, 26);
    ObjectSetInteger(0, BTN_POWER, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetString(0, BTN_POWER, OBJPROP_TEXT, "ENCENDIDO");
    ObjectSetString(0, BTN_POWER, OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, BTN_POWER, OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, BTN_POWER, OBJPROP_BGCOLOR, clrGreen);
    ObjectSetInteger(0, BTN_POWER, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, BTN_POWER, OBJPROP_BORDER_COLOR, clrWhite);
    ObjectCreate(0, BTN_CLOSE, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, BTN_CLOSE, OBJPROP_XDISTANCE, 142);
    ObjectSetInteger(0, BTN_CLOSE, OBJPROP_YDISTANCE, 318);
    ObjectSetInteger(0, BTN_CLOSE, OBJPROP_XSIZE, 120);
    ObjectSetInteger(0, BTN_CLOSE, OBJPROP_YSIZE, 26);
    ObjectSetInteger(0, BTN_CLOSE, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetString(0, BTN_CLOSE, OBJPROP_TEXT, "CERRAR TODO");
    ObjectSetString(0, BTN_CLOSE, OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, BTN_CLOSE, OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, BTN_CLOSE, OBJPROP_BGCOLOR, clrDarkRed);
    ObjectSetInteger(0, BTN_CLOSE, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, BTN_CLOSE, OBJPROP_BORDER_COLOR, clrWhite);
}

void UpdateHUD(int score) {
    string sigTxt = "ESPERANDO";
    color colSig = clrGold;
    if(g_realBuyScore >= InpMinConsensus && g_realBuyScore > g_realSellScore) {
        string patronVela = "";
        if(InpUseFiltroM15 && !g_m15Bullish) { sigTxt = "BLOQ TEND M15"; colSig = clrGold; }
        else if(g_bloqueadoTecho) { sigTxt = "BLOQ TECHO M15"; colSig = clrGold; }
        else if(InpFiltroVelaConfirmacion && DetectarPatronVelaPrevia(1, patronVela) > 0) { sigTxt = "BLOQ: " + patronVela; colSig = clrGold; }
        else { sigTxt = "COMPRA"; colSig = clrLime; }
    }
    else if(g_realSellScore >= InpMinConsensus && g_realSellScore > g_realBuyScore) {
        string patronVela = "";
        if(InpUseFiltroM15 && g_m15Bullish) { sigTxt = "BLOQ TEND M15"; colSig = clrGold; }
        else if(g_bloqueadoSuelo) { sigTxt = "BLOQ SUELO M15"; colSig = clrGold; }
        else if(InpFiltroVelaConfirmacion && DetectarPatronVelaPrevia(-1, patronVela) > 0) { sigTxt = "BLOQ: " + patronVela; colSig = clrGold; }
        else { sigTxt = "VENTA"; colSig = clrTomato; }
    }
    
    string estadoBot = "ACTIVO";
    color colEstado = clrLime;
    if(!g_botActivo) {
        estadoBot = "PAUSADO";
        colEstado = clrGold;
    } else {
        MqlDateTime dt; TimeToStruct(TimeTradeServer(), dt);
        if(InpPausaNoticiasUS && dt.hour == 15 && dt.min >= 15 && dt.min <= 45) {
            estadoBot = "PAUSA NOTICIAS";
            colEstado = clrOrange;
        } else if((dt.day_of_week==0 || dt.day_of_week==6) && !g_isBTC) {
            estadoBot = "FIN DE SEMANA";
            colEstado = clrRed;
        } else if(InpNoViernes && dt.day_of_week==5 && dt.hour>=20 && !g_isBTC) {
            estadoBot = "CIERRE VIERNES";
            colEstado = clrRed;
        } else if(dt.hour < InpHoraInicio || dt.hour >= InpHoraFin) {
            estadoBot = "FUERA HORARIO";
            colEstado = clrRed;
        }
    }
    string presetName = g_isBTC ? "BTCUSD" : "XAUUSD";
    string tendM15 = g_m15Bullish ? "ALCISTA" : "BAJISTA";
    string tendH1 = g_h1Bullish ? "ALCISTA" : "BAJISTA";
    string extTxt = "OK";
    if(g_bloqueadoSuelo) extTxt = "SUELO!";
    else if(g_bloqueadoTecho) extTxt = "TECHO!";
    string cooldownTxt = "-";
    if(g_lastSLTime > 0) {
        int s = (InpCooldownSLMin * 60) - (int)(TimeCurrent() - g_lastSLTime);
        if(s > 0) cooldownTxt = "SL " + IntegerToString(s/60) + "m";
    }
    if(g_lastSignalTime > 0 && cooldownTxt == "-") {
        int s = InpSegReentrada - (int)(TimeCurrent() - g_lastSignalTime);
        if(s > 0) cooldownTxt = IntegerToString(s) + "s";
        else if(TendenciaSigueViva()) cooldownTxt = "VIVA";
        else cooldownTxt = "AGOTADA";
    }
    double spreadNow = (symbolInfo.Ask() - symbolInfo.Bid()) / g_point;
    
    // Potencia y Objetivo
    int bestScore = MathMax(g_realBuyScore, g_realSellScore);
    int faltan = InpMinConsensus - bestScore;
    
    string potenciaTxt = StringFormat("POTENCIA: BUY %d%% | SELL %d%%", g_realBuyScore, g_realSellScore);
    color colPot = clrSilver;
    if(g_realBuyScore >= InpMinConsensus) colPot = clrLime;
    else if(g_realSellScore >= InpMinConsensus) colPot = clrTomato;
    else if(bestScore >= (InpMinConsensus - 15)) colPot = clrGold;
    
    string objetivoTxt;
    color colObj;
    if(faltan <= 0) {
        if(StringFind(sigTxt, "BLOQ") >= 0) {
            objetivoTxt = StringFormat("OBJETIVO: %d%% / %d%% [CONFIRMANDO]", bestScore, InpMinConsensus);
            colObj = clrYellow;
        } else {
            objetivoTxt = StringFormat("OBJETIVO: %d%% / %d%% [LISTO DISPARO]", bestScore, InpMinConsensus);
            colObj = (g_realBuyScore >= g_realSellScore) ? clrLime : clrTomato;
        }
    } else {
        objetivoTxt = StringFormat("OBJETIVO: %d%% / %d%% (Faltan %d%%)", bestScore, InpMinConsensus, faltan);
        colObj = (faltan <= 15) ? clrYellow : clrDeepSkyBlue;
    }
    
    string lines[15];
    lines[0]  = "=== MAIKO AI CONSENSUS ===";
    lines[1]  = "Preset: " + presetName;
    lines[2]  = "Estado: " + estadoBot;
    lines[3]  = "Señal: " + sigTxt;
    lines[4]  = potenciaTxt;
    lines[5]  = objetivoTxt;
    lines[6]  = "Tend M15: " + tendM15 + " | H1: " + tendH1;
    lines[7]  = "RSI: " + DoubleToString(g_rsiActual,1) + " | Ext: " + extTxt;
    lines[8]  = "F&G: " + IntegerToString(g_lastFearGreed) + " | L/S: " + DoubleToString(g_lastLSRatio,2);
    lines[9]  = "OB B:" + DoubleToString(g_lastOB_Buy,1) + " / S:" + DoubleToString(g_lastOB_Sell,1);
    lines[10] = "ATR: " + DoubleToString(g_lastATR,2) + " | Spr: " + DoubleToString(spreadNow,0) + " pts";
    lines[11] = "Reentrada: " + cooldownTxt;
    lines[12] = "Dist.Extremo: " + IntegerToString(g_distanciaSueloPts) + " pts";
    lines[13] = "Balance: $" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2);
    lines[14] = "-----------------------------";
    
    for(int i = 0; i < 15; i++) {
        string name = "MAIKO_HUD_L" + IntegerToString(i);
        ObjectSetString(0, name, OBJPROP_TEXT, lines[i]);
    }
    
    // Aplicar estilos y colores dinámicos
    ObjectSetInteger(0, "MAIKO_HUD_L0", OBJPROP_COLOR, clrDodgerBlue);
    ObjectSetString(0, "MAIKO_HUD_L0", OBJPROP_FONT, "Arial Bold");
    
    ObjectSetInteger(0, "MAIKO_HUD_L2", OBJPROP_COLOR, colEstado);
    
    ObjectSetInteger(0, "MAIKO_HUD_L3", OBJPROP_COLOR, colSig);
    ObjectSetString(0, "MAIKO_HUD_L3", OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, "MAIKO_HUD_L3", OBJPROP_FONTSIZE, 10);
    
    ObjectSetInteger(0, "MAIKO_HUD_L4", OBJPROP_COLOR, colPot);
    ObjectSetString(0, "MAIKO_HUD_L4", OBJPROP_FONT, "Consolas Bold");
    ObjectSetInteger(0, "MAIKO_HUD_L4", OBJPROP_FONTSIZE, 10);
    
    ObjectSetInteger(0, "MAIKO_HUD_L5", OBJPROP_COLOR, colObj);
    ObjectSetString(0, "MAIKO_HUD_L5", OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, "MAIKO_HUD_L5", OBJPROP_FONTSIZE, 10);
    
    ObjectSetInteger(0, "MAIKO_HUD_L6", OBJPROP_COLOR, clrAqua);
    ObjectSetInteger(0, "MAIKO_HUD_L13", OBJPROP_COLOR, clrSpringGreen);
    ObjectSetString(0, "MAIKO_HUD_L13", OBJPROP_FONT, "Arial Bold");
    
    ChartRedraw();
}

//=================================================================
// UTILIDADES
//=================================================================
double CalculateLotSize(int slPts) {
    if(InpUseFixedLot) return NormLot(InpFixedLot);
    double risk = AccountInfoDouble(ACCOUNT_BALANCE) * (InpRiskPercent/100.0);
    double tv = SymbolInfoDouble(g_symbol, SYMBOL_TRADE_TICK_VALUE), ts = SymbolInfoDouble(g_symbol, SYMBOL_TRADE_TICK_SIZE);
    if(tv==0||ts==0) return NormLot(InpFixedLot);
    double lplot = slPts * (tv/(ts/g_point)); if(lplot<=0) return NormLot(InpFixedLot);
    return NormLot(risk/lplot);
}
double NormLot(double lot) {
    double mn=SymbolInfoDouble(g_symbol,SYMBOL_VOLUME_MIN), mx=SymbolInfoDouble(g_symbol,SYMBOL_VOLUME_MAX), st=SymbolInfoDouble(g_symbol,SYMBOL_VOLUME_STEP);
    return MathMax(mn, MathMin(mx, MathFloor(lot/st)*st));
}
void CloseAllPositions() {
    for(int i=PositionsTotal()-1; i>=0; i--) if(positionInfo.SelectByIndex(i) && positionInfo.Magic()==g_magicNumber) trade.PositionClose(positionInfo.Ticket());
}
int CountOpenPositions() {
    int n=0; for(int i=0;i<PositionsTotal();i++) if(positionInfo.SelectByIndex(i) && positionInfo.Symbol()==g_symbol && positionInfo.Magic()==g_magicNumber) n++; return n;
}
bool IsOperatingHour() {
    MqlDateTime dt; TimeToStruct(TimeTradeServer(), dt);
    
    // 1. Fines de semana (Sábado=6, Domingo=0):
    // El Oro NO opera, pero Bitcoin (BTC) SÍ puede operar 24/7
    if(dt.day_of_week==0 || dt.day_of_week==6) {
        if(!g_isBTC) return false;
    }
    
    // 2. Viernes noche: El Oro no abre nuevas posiciones después de las 20:00 broker (19:00 España)
    if(InpNoViernes && dt.day_of_week==5 && dt.hour>=20) {
        if(!g_isBTC) return false;
    }
    
    // 3. Rango horario de 3:00 a 23:00
    if(dt.hour < InpHoraInicio || dt.hour >= InpHoraFin) return false;
    
    // 4. Pausa por Noticias de EE.UU. (15:15 a 15:45 servidor broker = 14:15 a 14:45 España)
    if(InpPausaNoticiasUS) {
        if(dt.hour == 15 && dt.min >= 15 && dt.min <= 45) {
            return false;
        }
    }
    
    return true;
}
void UpdateDrawdown() {
    double eq=AccountInfoDouble(ACCOUNT_EQUITY); if(eq>g_peakBalance) g_peakBalance=eq;
    double dd=((g_peakBalance-eq)/g_peakBalance)*100.0; if(dd>g_maxDrawdown) g_maxDrawdown=dd;
}
bool CheckLicense(const string key) {
    if(key == InpMasterKey) return true;
    if(key==""||StringLen(key)<10) return false;
    if(StringFind(key,"KOPY-")!=0) return false;
    return true;
}
void SendTelegramMsg(const string message) {
    if(!InpUseTelegram || InpTelegramToken=="" || InpTelegramChatID=="") return;
    if(MQLInfoInteger(MQL_TESTER)) return;
    string safeMsg = message; StringReplace(safeMsg,"&","%26");
    string post_str = "chat_id=" + InpTelegramChatID + "&text=" + safeMsg;
    char post[], result[]; StringToCharArray(post_str, post, 0, StringLen(post_str), CP_UTF8);
    string rH; 
    ResetLastError();
    int res = WebRequest("POST","https://api.telegram.org/bot"+InpTelegramToken+"/sendMessage","Content-Type: application/x-www-form-urlencoded\r\n",5000,post,result,rH);
    if(res!=200) Print("Telegram error HTTP: ", res);
}

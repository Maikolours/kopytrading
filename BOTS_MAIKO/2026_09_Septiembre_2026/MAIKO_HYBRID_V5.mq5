//+------------------------------------------------------------------+
//|                                       MAIKO_HYBRID_V5.mq5        |
//|     Sniper + Escape Rápido | Rotura vs Reversión                |
//+------------------------------------------------------------------+
#property copyright "MAIKO HYBRID V5 - Sniper Edition"
#property version   "5.00"
#property strict

#include <Trade\Trade.mqh>

#ifndef MODE_HIGH
#define MODE_HIGH 1
#endif
#ifndef MODE_LOW
#define MODE_LOW 2
#endif

// --- HELPER FUNCTIONS FOR MQL5 ---
int iHighest(string symbol, ENUM_TIMEFRAMES tf, int type, int count, int start=0)
  {
   double high[];
   ArraySetAsSeries(high, true);
   if(CopyHigh(symbol, tf, start, count, high) <= 0) return start;
   return ArrayMaximum(high, 0, count) + start;
  }

int iLowest(string symbol, ENUM_TIMEFRAMES tf, int type, int count, int start=0)
  {
   double low[];
   ArraySetAsSeries(low, true);
   if(CopyLow(symbol, tf, start, count, low) <= 0) return start;
   return ArrayMinimum(low, 0, count) + start;
  }

// --- RIESGO ---
input double MaxPerdidaFlotante = 30.0;
input double LimiteDiarioBeneficio = 15.0;
input double MaxLoteTotal = 0.05;
input double LoteBase = 0.01;
input double LoteSOS = 0.01;

// --- SNIPER: DETECCIÓN DE TECHOS Y SUELOS ---
input int VelasParaTechoSuelo = 20;
input double ProximidadTechoSuelo_Pips = 8.0;
input int MaxVelasEsperaRotura = 3;          // Máx velas M15 esperando rotura antes de abortar
input bool UsarConfirmacionVela = true;
input double RSI_Techo_Min = 55.0;
input double RSI_Suelo_Max = 45.0;

// --- MODO LATERAL: ESCAPE RÁPIDO ---
input double ProfitScalpRapido = 1.50;        // Beneficio USD para cierre rápido en lateral ($1.50 USD)
input int MaxMinutosEnLateral = 60;           // Si una operación lateral no da profit en X min, se evalúa (60 min)
input double PerdidaMaximaLateral = 3.00;     // Pérdida máxima USD tolerada en lateral ($3.00 USD)

// --- MODOS ---
input bool AutoDetectarModo = true;
input int ADX_UmbralTendencia = 28;
input double ATR_AltaVolatilidad_Pips = 15.0;

// --- FILTROS ---
input bool UsarFiltroH4 = false;             // Filtro H4 (Desactivado por defecto para permitir Sniper en techos/suelos)
input bool UsarFiltroNoticias = true;
input int MinsAntesNoticia = 15;
input int MinsDespuesNoticia = 15;
input bool UsarFiltroHorario = true;
input int HoraInicioSesion = 9;
input int HoraFinSesion = 22;
input double MaxSpreadPips = 4.5;

// --- GESTIÓN ---
input int MaxPosiciones = 3;
input double MinCuerpoVelaPips = 3.0;
input int EsperaTrasCierre_Seg = 45;

// --- OBJETIVOS ---
input double ProfitScalpIndividual = 3.00;    // Profit individual USD ($3.00 USD)
input double ProfitCestaGlobal = 15.00;       // Profit cesta global USD ($15.00 USD)

// --- LICENCIA ---
input string MiLicencia = "23449251";
input string PurchaseID = "";
input string SyncURL = "https://www.kopytrading.com/api/sync-positions";

// --- HUD ---
input color ColorMain = clrGold;
input int HUD_X = 15;
input int PosY_HUD = 25;

// --- GLOBALES ---
CTrade trade;
const int ExpertMagic = 111222;
struct PosInfo { ulong ticket; double p; int t; double v; double pr; double tp; datetime openTime; };
PosInfo pos[];
double ganadoHoy = 0, flotante = 0, volTotal = 0, spreadActual = 0, rsiActual = 0;
double adxActual = 0, atrActual = 0, techoM15 = 0, sueloM15 = 0;
bool BotActivo = true;
datetime ultimaCestaCerrada = 0, ultimoSOS = 0, ultimoSync = 0, eaStartTime = 0;
datetime inicioEsperaRotura = 0;             // Cuándo empezó a esperar la rotura
string txtVoz = "SISTEMA ONLINE.";
string txtVeredicto = "ESPERANDO...";
string txtModo = "CALCULANDO...";
string txtSetup = " ";

int hEMA_H4, hEMA_H1, hEMA_M15, hEMA_M5, hEMA_M1, hEMA_M1_9, hRSI, hMACD, hATR, hADX;
double equityPeak = 0;

//+------------------------------------------------------------------+
int OnInit() {
    eaStartTime = TimeCurrent();
    ObjectsDeleteAll(0, "MAIKO_");
    trade.SetExpertMagicNumber(ExpertMagic);
    equityPeak = AccountInfoDouble(ACCOUNT_EQUITY);

    hEMA_H4  = iMA(_Symbol, PERIOD_H4, 50, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_H1  = iMA(_Symbol, PERIOD_H1, 50, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_M15 = iMA(_Symbol, PERIOD_M15, 50, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_M5  = iMA(_Symbol, PERIOD_M5, 50, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_M1  = iMA(_Symbol, PERIOD_M1, 50, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_M1_9= iMA(_Symbol, PERIOD_M1, 9, 0, MODE_EMA, PRICE_CLOSE);
    hRSI     = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
    hMACD    = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE);
    hATR     = iATR(_Symbol, _Period, 14);
    hADX     = iADX(_Symbol, PERIOD_H1, 14);

    ChartSetInteger(0, CHART_SHOW_TRADE_HISTORY, false);
    ChartSetInteger(0, CHART_FOREGROUND, false);
    EventSetTimer(1);
    CrearInterfaz();
    DibujarIndicadores();
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) { EventKillTimer(); ObjectsDeleteAll(0, "MAIKO_"); }

//+------------------------------------------------------------------+
void OnTimer() {
    ActualizarEstado();
    ganadoHoy = CalcularGanadoHoy();
    flotante = CalcularFlotante();
    ActualizarInterfaz();
    ChartRedraw();
    if(StringLen(PurchaseID) > 5 && TimeCurrent() - ultimoSync >= 5) {
        EnviarTelemetria();
        ultimoSync = TimeCurrent();
    }
}

//+------------------------------------------------------------------+
void OnTick() {
    ActualizarEstado();
    ganadoHoy = CalcularGanadoHoy();
    flotante = CalcularFlotante();

    // === CONTROL DE RIESGO ===
    if (flotante <= -MaxPerdidaFlotante && ArraySize(pos) > 0) {
        CerrarTodo(); BotActivo = false;
        txtVeredicto = "STOP LOSS DE CESTA 🛑";
        return;
    }
    if ((ganadoHoy + flotante) >= LimiteDiarioBeneficio && ArraySize(pos) > 0) {
        CerrarTodo(); BotActivo = false;
        txtVeredicto = "LÍMITE DIARIO 🎯";
        return;
    }
    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    if (currentEquity > equityPeak) equityPeak = currentEquity;
    if (equityPeak > 0 && ((equityPeak - currentEquity) / equityPeak) * 100.0 >= 30.0) {
        CerrarTodo(); BotActivo = false;
        txtVeredicto = "DRAWDOWN 30% 🛑";
        return;
    }

    // === INDICADORES ===
    spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point / 10;
    double adxBuf[1]; if(CopyBuffer(hADX, 0, 0, 1, adxBuf) > 0) adxActual = adxBuf[0];
    double atrBuf[1]; if(CopyBuffer(hATR, 0, 0, 1, atrBuf) > 0) atrActual = atrBuf[0];
    double rsiBuf[1]; CopyBuffer(hRSI, 0, 0, 1, rsiBuf); rsiActual = rsiBuf[0];

    double emaH4[1], emaH1[1], emaM15[1], emaM5[1], emaM1[1], emaM1_9[1];
    CopyBuffer(hEMA_H4, 0, 0, 1, emaH4);
    CopyBuffer(hEMA_H1, 0, 0, 1, emaH1);
    CopyBuffer(hEMA_M15, 0, 0, 1, emaM15);
    CopyBuffer(hEMA_M5, 0, 0, 1, emaM5);
    CopyBuffer(hEMA_M1, 0, 0, 1, emaM1);
    CopyBuffer(hEMA_M1_9, 0, 0, 1, emaM1_9);

    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

    // === CALCULAR TECHOS Y SUELOS ===
    techoM15 = iHigh(_Symbol, PERIOD_M15, iHighest(_Symbol, PERIOD_M15, MODE_HIGH, VelasParaTechoSuelo, 1));
    sueloM15 = iLow(_Symbol, PERIOD_M15, iLowest(_Symbol, PERIOD_M15, MODE_LOW, VelasParaTechoSuelo, 1));

    // === DETERMINAR MODO ===
    bool altaVolatilidad = (atrActual / _Point / 10) >= ATR_AltaVolatilidad_Pips;
    bool modoTendencia = AutoDetectarModo ? (adxActual >= ADX_UmbralTendencia) : false;

    if (modoTendencia && altaVolatilidad) txtModo = "TENDENCIA + ALTA VOL 🔥";
    else if (modoTendencia) txtModo = "TENDENCIA 📈";
    else if (altaVolatilidad) txtModo = "LATERAL + ALTA VOL 🔥";
    else txtModo = "LATERAL TRANQUILO 📊";

    // === GESTIÓN DE CESTA ABIERTA ===
    if (ArraySize(pos) > 0) {
        GestionarCestaAbierta(bid, ask, emaM1[0], modoTendencia, emaH1[0]);
        ActualizarInterfaz();
        return;
    }

    // === SIN OPERACIONES: EVALUAR NUEVA ENTRADA ===
    if (!BotActivo) { txtVoz = "SISTEMA EN PAUSA."; return; }
    if (spreadActual > MaxSpreadPips) { txtVeredicto = "SPREAD ALTO"; return; }
    
    if (TimeCurrent() - ultimaCestaCerrada < EsperaTrasCierre_Seg) {
        int restante = EsperaTrasCierre_Seg - (int)(TimeCurrent() - ultimaCestaCerrada);
        txtVoz = StringFormat("EVALUANDO MERCADO (%d seg)...", restante);
        txtSetup = " ";
        return;
    }

    if (UsarFiltroHorario) {
        MqlDateTime dt; TimeCurrent(dt);
        if (dt.hour < HoraInicioSesion || dt.hour >= HoraFinSesion) {
            txtVeredicto = "FUERA DE SESIÓN";
            return;
        }
    }
    if (UsarFiltroNoticias && IsNewsBlocked()) {
        txtVeredicto = "PAUSA POR NOTICIAS";
        return;
    }

    // === FILTRO H4 ===
    bool permitirCompras = true;
    bool permitirVentas = true;
    if (UsarFiltroH4) {
        if (bid < emaH4[0]) permitirCompras = false;
        if (bid > emaH4[0]) permitirVentas = false;
    }

    // === DETECCIÓN DE ZONA PELIGROSA (TECHO/SUELO) ===
    double distTechoM15 = MathAbs(techoM15 - bid) / _Point / 10;
    double distSueloM15 = MathAbs(bid - sueloM15) / _Point / 10;
    bool cercaTecho = (distTechoM15 <= ProximidadTechoSuelo_Pips);
    bool cercaSuelo = (distSueloM15 <= ProximidadTechoSuelo_Pips);

    // === GESTIÓN DE LA ESPERA DE ROTURA ===
    // Si estamos en zona peligrosa, esperamos a que se decida
    if (cercaTecho || cercaSuelo) {
        if (inicioEsperaRotura == 0) {
            inicioEsperaRotura = TimeCurrent();
            txtVeredicto = "ZONA CLAVE - OBSERVANDO";
        }
        
        // Verificar si ya pasaron demasiadas velas M15
        int velasEsperando = (int)((TimeCurrent() - inicioEsperaRotura) / (15 * 60));
        
        if (cercaTecho) {
            txtSetup = StringFormat("TECHO a %.1f pips | Esperando %d/%d velas", distTechoM15, velasEsperando, MaxVelasEsperaRotura);
        } else {
            txtSetup = StringFormat("SUELO a %.1f pips | Esperando %d/%d velas", distSueloM15, velasEsperando, MaxVelasEsperaRotura);
        }
        
        // Detectar ROTURA (cierre M15 por encima del techo o por debajo del suelo)
        double cierreM15_1 = iClose(_Symbol, PERIOD_M15, 1);
        double cierreM15_2 = iClose(_Symbol, PERIOD_M15, 2);
        
        bool roturaAlcista = (cierreM15_1 > techoM15 && cierreM15_2 > techoM15);
        bool roturaBajista = (cierreM15_1 < sueloM15 && cierreM15_2 < sueloM15);
        
        if (roturaAlcista) {
            // El precio rompió el techo: CANCELAR idea de venta
            txtVeredicto = "ROTURA ALCISTA - Cambiando sesgo";
            inicioEsperaRotura = 0;
            txtSetup = " ";
            // Aquí podríamos activar un sesgo comprador, pero por seguridad esperamos
            return;
        }
        if (roturaBajista) {
            txtVeredicto = "ROTURA BAJISTA - Cambiando sesgo";
            inicioEsperaRotura = 0;
            txtSetup = " ";
            return;
        }
        
        // Si pasaron demasiadas velas lateralizando → ABORTAR
        if (velasEsperando >= MaxVelasEsperaRotura) {
            txtVeredicto = "ZONA LATERALIZADA - ABORTADO";
            txtVoz = "El precio no se decidió. Cancelando setup.";
            inicioEsperaRotura = 0;
            txtSetup = " ";
            return;
        }
        
        // === CALCULAR SL Y TP ESTRUCTURALES ===
        double slDist = MathMax(atrActual * 1.5, 300.0 * _Point);
        double tpDist = MathMax(atrActual * 2.0, 450.0 * _Point);

        // === CONFIRMACIÓN DE REVERSIÓN (entrada sniping) ===
        if (cercaTecho && permitirVentas && rsiActual >= RSI_Techo_Min) {
            if (ConfirmarReversionBajista()) {
                double sl = NormalizeDouble(ask + slDist, _Digits);
                double tp = NormalizeDouble(bid - tpDist, _Digits);
                trade.Sell(LoteBase, _Symbol, bid, sl, tp, "MAIKO_SNIPER_SELL");
                ultimaCestaCerrada = 0;
                inicioEsperaRotura = 0;
                txtVeredicto = "¡VENTA SNIPER EN TECHO! 📉";
                txtSetup = " ";
                return;
            }
        }
        if (cercaSuelo && permitirCompras && rsiActual <= RSI_Suelo_Max) {
            if (ConfirmarReversionAlcista()) {
                double sl = NormalizeDouble(bid - slDist, _Digits);
                double tp = NormalizeDouble(ask + tpDist, _Digits);
                trade.Buy(LoteBase, _Symbol, ask, sl, tp, "MAIKO_SNIPER_BUY");
                ultimaCestaCerrada = 0;
                inicioEsperaRotura = 0;
                txtVeredicto = "¡COMPRA SNIPER EN SUELO! 📈";
                txtSetup = " ";
                return;
            }
        }
        
        ActualizarInterfaz();
        return; // No hacemos nada más mientras estamos en zona clave
    } else {
        // Fuera de zona clave: resetear contador
        inicioEsperaRotura = 0;
    }

    int pM5 = AnalizarVela(PERIOD_M5, 1);
    int pM1 = AnalizarVela(PERIOD_M1, 1);

    // === MODO TENDENCIA (ADX ALTO): ENTRADAS A FAVOR DE TENDENCIA ===
    if (modoTendencia) {
        bool trenAlcista = (bid > emaH1[0] && emaM15[0] > emaH1[0]);
        bool trenBajista = (bid < emaH1[0] && emaM15[0] < emaH1[0]);

        double slDistTrend = MathMax(atrActual * 1.5, 300.0 * _Point);
        double tpDistTrend = MathMax(atrActual * 2.0, 450.0 * _Point);

        if (trenAlcista && permitirCompras && rsiActual >= 45.0 && rsiActual <= 68.0 && (pM5 == 2 || pM1 == 2) && bid > emaM5[0]) {
            double sl = NormalizeDouble(bid - slDistTrend, _Digits);
            double tp = NormalizeDouble(ask + tpDistTrend, _Digits);
            trade.Buy(LoteBase, _Symbol, ask, sl, tp, "MAIKO_TREND_BUY");
            ultimaCestaCerrada = 0;
            txtVeredicto = "COMPRA A FAVOR DE TENDENCIA 📈";
            return;
        }

        if (trenBajista && permitirVentas && rsiActual <= 55.0 && rsiActual >= 32.0 && (pM5 == -2 || pM1 == -2) && bid < emaM5[0]) {
            double sl = NormalizeDouble(ask + slDistTrend, _Digits);
            double tp = NormalizeDouble(bid - tpDistTrend, _Digits);
            trade.Sell(LoteBase, _Symbol, bid, sl, tp, "MAIKO_TREND_SELL");
            ultimaCestaCerrada = 0;
            txtVeredicto = "VENTA A FAVOR DE TENDENCIA 📉";
            return;
        }
    } 
    // === MODO LATERAL (ADX BAJO): SCALPING EN EXTREMOS DE RANGO ===
    else {
        double slDistScalp = MathMax(atrActual * 1.2, 250.0 * _Point);
        double tpDistScalp = MathMax(atrActual * 1.5, 350.0 * _Point);

        bool condBuyLateral = (rsiActual <= 48.0) && permitirCompras && (pM1 == 2);
        bool condSellLateral = (rsiActual >= 52.0) && permitirVentas && (pM1 == -2);

        if (condBuyLateral) {
            double sl = NormalizeDouble(bid - slDistScalp, _Digits);
            double tp = NormalizeDouble(ask + tpDistScalp, _Digits);
            trade.Buy(LoteBase, _Symbol, ask, sl, tp, "MAIKO_SCALP_BUY");
            ultimaCestaCerrada = 0;
            txtVeredicto = "SCALP LATERAL - RECHAZO ABAJO 📈";
            return;
        }
        if (condSellLateral) {
            double sl = NormalizeDouble(ask + slDistScalp, _Digits);
            double tp = NormalizeDouble(bid - tpDistScalp, _Digits);
            trade.Sell(LoteBase, _Symbol, bid, sl, tp, "MAIKO_SCALP_SELL");
            ultimaCestaCerrada = 0;
            txtVeredicto = "SCALP LATERAL - RECHAZO ARRIBA 📉";
            return;
        }
    }

    txtVeredicto = modoTendencia ? "TENDENCIA - Buscando pullback" : "LATERAL - Buscando extremo de rango";
    txtSetup = " ";
    ActualizarInterfaz();
}

//+------------------------------------------------------------------+
//| CONFIRMACIÓN BAJISTA (envolvente o mecha de rechazo)             |
//+------------------------------------------------------------------+
bool ConfirmarReversionBajista() {
    if (!UsarConfirmacionVela) return true;
    
    double open1 = iOpen(_Symbol, PERIOD_M15, 1);
    double close1 = iClose(_Symbol, PERIOD_M15, 1);
    double high1 = iHigh(_Symbol, PERIOD_M15, 1);
    double open2 = iOpen(_Symbol, PERIOD_M15, 2);
    double close2 = iClose(_Symbol, PERIOD_M15, 2);
    
    bool esBajista = (close1 < open1);
    bool envuelve = (close1 < open2 && open1 > close2);
    bool cuerpoMinimo = MathAbs(close1 - open1) >= MinCuerpoVelaPips * _Point * 10;
    
    if (esBajista && envuelve && cuerpoMinimo) return true;
    
    double mechaSuperior = high1 - MathMax(open1, close1);
    double cuerpo = MathAbs(close1 - open1);
    if (mechaSuperior > cuerpo * 2 && esBajista) return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| CONFIRMACIÓN ALCISTA                                             |
//+------------------------------------------------------------------+
bool ConfirmarReversionAlcista() {
    if (!UsarConfirmacionVela) return true;
    
    double open1 = iOpen(_Symbol, PERIOD_M15, 1);
    double close1 = iClose(_Symbol, PERIOD_M15, 1);
    double low1 = iLow(_Symbol, PERIOD_M15, 1);
    double open2 = iOpen(_Symbol, PERIOD_M15, 2);
    double close2 = iClose(_Symbol, PERIOD_M15, 2);
    
    bool esAlcista = (close1 > open1);
    bool envuelve = (close1 > open2 && open1 < close2);
    bool cuerpoMinimo = MathAbs(close1 - open1) >= MinCuerpoVelaPips * _Point * 10;
    
    if (esAlcista && envuelve && cuerpoMinimo) return true;
    
    double mechaInferior = MathMin(open1, close1) - low1;
    double cuerpo = MathAbs(close1 - open1);
    if (mechaInferior > cuerpo * 2 && esAlcista) return true;
    
    return false;
}

//+------------------------------------------------------------------+
void GestionarCestaAbierta(double bid, double ask, double emaM1, bool modoTendencia, double emaH1) {
    int nPos = ArraySize(pos);
    if (nPos == 0) return;
    
    // === ESCAPE RÁPIDO EN MODO LATERAL ===
    if (!modoTendencia) {
        int minutosAbierta = (int)((TimeCurrent() - pos[0].openTime) / 60);
        
        // Si el flotante alcanza el límite de pérdida tolerable → cerrar
        if (flotante <= -PerdidaMaximaLateral) {
            CerrarTodo();
            txtVeredicto = "ESCAPE RÁPIDO - PÉRDIDA CONTROLADA 💨";
            return;
        }
        
        // Si lleva 60 min y está en pequeño beneficio positivo → asegurar y cerrar
        if (minutosAbierta >= MaxMinutosEnLateral && flotante >= 0.10) {
            CerrarTodo();
            txtVeredicto = "TIEMPO LÍMITE - CIERRE EN PROFIT 💨";
            return;
        }
        
        // Si ya alcanza el beneficio objetivo rápido → cerrar
        if (flotante >= ProfitScalpRapido) {
            CerrarTodo();
            ultimaCestaCerrada = TimeCurrent();
            txtVeredicto = "SCALP RÁPIDO OK 🎯";
            return;
        }
    } else {
        // === MODO TENDENCIA: gestión normal ===
        double maxProfit = -999999;
        int idxBest = -1;
        for (int i = 0; i < nPos; i++) {
            if (pos[i].p > maxProfit) { maxProfit = pos[i].p; idxBest = i; }
        }
        if (idxBest != -1 && maxProfit >= ProfitScalpIndividual) {
            trade.PositionClose(pos[idxBest].ticket);
            txtVeredicto = "SCALP INDIVIDUAL OK 🎯";
            return;
        }
        
        if (flotante >= ProfitCestaGlobal) {
            CerrarTodo();
            ultimaCestaCerrada = TimeCurrent();
            txtVeredicto = "CESTA CERRADA 🎉";
            return;
        }
        
        // Cascada solo si estamos en positivo
        if (nPos < MaxPosiciones && volTotal + LoteBase <= MaxLoteTotal && flotante > 0.10) {
            bool emaOK = (pos[0].t == POSITION_TYPE_BUY && bid > emaM1) || (pos[0].t == POSITION_TYPE_SELL && bid < emaM1);
            if (emaOK && TimeCurrent() - ultimoSOS >= 20) {
                if (pos[0].t == POSITION_TYPE_BUY) trade.Buy(LoteBase, _Symbol, 0, 0, 0, "MAIKO_CASCADA_BUY");
                else trade.Sell(LoteBase, _Symbol, 0, 0, 0, "MAIKO_CASCADA_SELL");
                ultimoSOS = TimeCurrent();
                txtVeredicto = "CASCADA A FAVOR 🔥";
                return;
            }
        }
    }
    
    txtVeredicto = StringFormat("GESTIONANDO %d POS | FLOT: %.2f", nPos, flotante);
}

//+------------------------------------------------------------------+
int AnalizarVela(ENUM_TIMEFRAMES tf, int shift) {
    double open = iOpen(_Symbol, tf, shift);
    double close = iClose(_Symbol, tf, shift);
    double body = MathAbs(close - open);
    if (body < MinCuerpoVelaPips * _Point * 10) return 0;
    return (close > open ? 2 : -2);
}

bool IsNewsBlocked() {
    if (!UsarFiltroNoticias) return false;
    MqlCalendarValue values[];
    datetime start = TimeCurrent() - (MinsAntesNoticia * 60);
    datetime end = TimeCurrent() + (MinsDespuesNoticia * 60);
    if (CalendarValueHistory(values, start, end, NULL, "USD")) {
        for (int i = 0; i < ArraySize(values); i++) {
            MqlCalendarEvent ev;
            if (CalendarEventById(values[i].event_id, ev)) {
                if (ev.importance == CALENDAR_IMPORTANCE_HIGH) return true;
            }
        }
    }
    return false;
}

void ActualizarEstado() {
    ArrayResize(pos, 0);
    volTotal = 0;
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong t = PositionGetTicket(i);
        if (PositionSelectByTicket(t) && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == ExpertMagic) {
            int idx = ArraySize(pos);
            ArrayResize(pos, idx + 1);
            pos[idx].ticket = t;
            pos[idx].p = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
            pos[idx].t = (int)PositionGetInteger(POSITION_TYPE);
            pos[idx].v = PositionGetDouble(POSITION_VOLUME);
            pos[idx].pr = PositionGetDouble(POSITION_PRICE_OPEN);
            pos[idx].tp = PositionGetDouble(POSITION_TP);
            pos[idx].openTime = (datetime)PositionGetInteger(POSITION_TIME);
            volTotal += pos[idx].v;
        }
    }
}

double CalcularFlotante() { double s = 0; for (int i = 0; i < ArraySize(pos); i++) s += pos[i].p; return s; }

double CalcularGanadoHoy() {
    MqlDateTime dt; TimeCurrent(dt);
    dt.hour = 0; dt.min = 0; dt.sec = 0;
    datetime start = StructToTime(dt);
    if (start < eaStartTime) start = eaStartTime;
    double total = 0;
    HistorySelect(start, TimeCurrent());
    for (int i = HistoryDealsTotal() - 1; i >= 0; i--) {
        ulong t = HistoryDealGetTicket(i);
        if (HistoryDealGetString(t, DEAL_SYMBOL) != _Symbol) continue;
        total += HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_SWAP) + HistoryDealGetDouble(t, DEAL_COMMISSION);
    }
    return total;
}

void CerrarTodo() { for (int i = ArraySize(pos) - 1; i >= 0; i--) trade.PositionClose(pos[i].ticket); ultimaCestaCerrada = TimeCurrent(); }

void EnviarTelemetria() {
    string account = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
    string status = BotActivo ? "ONLINE" : "PAUSED";
    string json = StringFormat("{\"purchaseId\":\"%s\",\"account\":\"%s\",\"balance\":%.2f,\"equity\":%.2f,\"pnl_today\":%.2f,\"status\":\"%s\",\"modo\":\"%s\"}",
        PurchaseID, account, balance, equity, ganadoHoy, status, txtModo);
    char postData[]; StringToCharArray(json, postData, 0, StringLen(json), CP_UTF8);
    char result[]; string headers = "Content-Type: application/json\r\n"; string resHeaders;
    WebRequest("POST", SyncURL, headers, 3000, postData, result, resHeaders);
}

//+------------------------------------------------------------------+
//| INTERFAZ                                                         |
//+------------------------------------------------------------------+
void CrearInterfaz() {
    int x = HUD_X, y = PosY_HUD, w = 400, h = 340;
    ObjectCreate(0, "MAIKO_Bg", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_XSIZE, w);
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_YSIZE, h);
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_BGCOLOR, C'15,15,15');
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_ZORDER, 9999);
    
    CrearLabel("MAIKO_T", x+10, y+10, "MAIKO HYBRID V5 | SNIPER", ColorMain, 11);
    CrearLabel("MAIKO_Modo", x+10, y+35, txtModo, clrCyan, 10);
    CrearLabel("MAIKO_Hoy", x+10, y+60, "HOY: 0.00", clrSpringGreen, 11);
    CrearLabel("MAIKO_Flot", x+10, y+80, "FLOTANTE: 0.00", clrWhite, 10);
    CrearLabel("MAIKO_Riesgo", x+10, y+100, StringFormat("RIESGO MAX: $%.2f", MaxPerdidaFlotante), clrOrange, 9);
    CrearLabel("MAIKO_ADX", x+10, y+120, "ADX: --", clrCyan, 9);
    CrearLabel("MAIKO_RSI", x+10, y+140, "RSI: --", clrOrange, 9);
    CrearLabel("MAIKO_SPD", x+10, y+160, "SPREAD: --", clrLightGray, 9);
    CrearLabel("MAIKO_Techo", x+10, y+180, "TECHO M15: --", clrRed, 9);
    CrearLabel("MAIKO_Suelo", x+10, y+198, "SUELO M15: --", clrSpringGreen, 9);
    CrearLabel("MAIKO_Vered", x+10, y+220, txtVeredicto, clrWhite, 9);
    CrearLabel("MAIKO_Setup", x+10, y+238, txtSetup, clrYellow, 8);
    CrearLabel("MAIKO_Voz", x+10, y+260, txtVoz, clrGold, 10);
    CrearLabel("MAIKO_Vol", x+10, y+285, "VOL: 0.00/0.05", clrWhite, 9);
    CrearBoton("MAIKO_BtnP", x+w-140, y+280, 130, 40, BotActivo ? "ENCENDIDO" : "ENCENDER", BotActivo ? clrRoyalBlue : clrDarkGreen);
    CrearBoton("MAIKO_BtnC", x+w-140, y+230, 130, 40, "CERRAR TODO", clrDarkRed);
}

void ActualizarInterfaz() {
    ObjectSetString(0, "MAIKO_Modo", OBJPROP_TEXT, txtModo);
    ObjectSetString(0, "MAIKO_Hoy", OBJPROP_TEXT, StringFormat("HOY: %.2f", ganadoHoy));
    ObjectSetString(0, "MAIKO_Flot", OBJPROP_TEXT, StringFormat("FLOTANTE: %.2f", flotante));
    ObjectSetInteger(0, "MAIKO_Flot", OBJPROP_COLOR, flotante >= 0 ? clrSpringGreen : clrRed);
    ObjectSetString(0, "MAIKO_ADX", OBJPROP_TEXT, StringFormat("ADX: %.1f", adxActual));
    ObjectSetString(0, "MAIKO_RSI", OBJPROP_TEXT, StringFormat("RSI: %.1f", rsiActual));
    ObjectSetString(0, "MAIKO_SPD", OBJPROP_TEXT, StringFormat("SPREAD: %.1f pips", spreadActual));
    ObjectSetString(0, "MAIKO_Techo", OBJPROP_TEXT, StringFormat("TECHO M15: %.2f", techoM15));
    ObjectSetString(0, "MAIKO_Suelo", OBJPROP_TEXT, StringFormat("SUELO M15: %.2f", sueloM15));
    ObjectSetString(0, "MAIKO_Vered", OBJPROP_TEXT, txtVeredicto);
    ObjectSetString(0, "MAIKO_Setup", OBJPROP_TEXT, txtSetup);
    ObjectSetString(0, "MAIKO_Voz", OBJPROP_TEXT, txtVoz);
    ObjectSetString(0, "MAIKO_Vol", OBJPROP_TEXT, StringFormat("VOL: %.2f / %.2f", volTotal, MaxLoteTotal));
    ObjectSetString(0, "MAIKO_BtnP", OBJPROP_TEXT, BotActivo ? "ENCENDIDO" : "ENCENDER");
    ObjectSetInteger(0, "MAIKO_BtnP", OBJPROP_BGCOLOR, BotActivo ? clrRoyalBlue : clrDarkGreen);
}

void CrearLabel(string n, int x, int y, string t, color col, int s) {
    ObjectCreate(0, n, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
    ObjectSetString(0, n, OBJPROP_TEXT, t);
    ObjectSetInteger(0, n, OBJPROP_COLOR, col);
    ObjectSetInteger(0, n, OBJPROP_FONTSIZE, s);
    ObjectSetInteger(0, n, OBJPROP_ZORDER, 10001);
}

void CrearBoton(string n, int x, int y, int w, int h, string t, color bg) {
    ObjectCreate(0, n, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, n, OBJPROP_XSIZE, w);
    ObjectSetInteger(0, n, OBJPROP_YSIZE, h);
    ObjectSetInteger(0, n, OBJPROP_BGCOLOR, bg);
    ObjectSetInteger(0, n, OBJPROP_COLOR, clrWhite);
    ObjectSetString(0, n, OBJPROP_TEXT, t);
    ObjectSetInteger(0, n, OBJPROP_ZORDER, 10010);
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
    if (id == CHARTEVENT_OBJECT_CLICK) {
        ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
        if (sparam == "MAIKO_BtnP") { BotActivo = !BotActivo; ActualizarInterfaz(); }
        if (sparam == "MAIKO_BtnC") { CerrarTodo(); inicioEsperaRotura = 0; }
        ChartRedraw();
    }
}

//+------------------------------------------------------------------+
void DibujarIndicadores() {
    if(MQLInfoInteger(MQL_TESTER)) return;
    int totalWindows = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL);
    for(int w = 0; w < totalWindows; w++) {
        int totalInd = ChartIndicatorsTotal(0, w);
        for(int i = totalInd - 1; i >= 0; i--) {
            string name = ChartIndicatorName(0, w, i);
            if(StringFind(name, "MA") >= 0 || StringFind(name, "RSI") >= 0 || StringFind(name, "ADX") >= 0 || StringFind(name, "ATR") >= 0) {
                ChartIndicatorDelete(0, w, name);
            }
        }
    }
    ChartIndicatorAdd(0, 0, hEMA_M15);
    ChartIndicatorAdd(0, 0, hEMA_M5);
    ChartIndicatorAdd(0, 0, hEMA_M1);
    ChartIndicatorAdd(0, 0, hEMA_M1_9);
    int subwindow = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL);
    ChartIndicatorAdd(0, subwindow, hRSI);
    subwindow++;
    ChartIndicatorAdd(0, subwindow, hADX);
    subwindow++;
    ChartIndicatorAdd(0, subwindow, hATR);
    ChartRedraw();
}
//+------------------------------------------------------------------+

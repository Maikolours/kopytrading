//+------------------------------------------------------------------+
//|          00_MAIKO_BAYESIAN_STRATEGY_PRO_v1.0.mq5                 |
//|    ALGORITMO BAYESIAN STRATEGY PRO - EDICIÓN OFICIAL SEPTIEMBRE  |
//|   MOTOR BAYESIANO + RSI + CAPAS ADAPTATIVAS + SHIELD + HUD TÁCTIL|
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Maiko Trading Corp."
#property link      "https://www.kopytrading.com"
#property version   "1.00"
#property strict
#property description "Bayesian Strategy Pro | Edicion Oficial Septiembre 2026 | Inferencia Bayesiana + RSI + Shield + HUD Interactivo"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//============================================================
//  ENUMERACIONES & PERFILES
//============================================================
enum ENUM_PERFIL_RIESGO
{
    PERFIL_MANUAL = 0,      // Manual (Configuracion Personalizada)
    PERFIL_CONSERVADOR = 1, // Conservador (Max 6 Capas | Shield 3.0%)
    PERFIL_BALANCEADO = 2,  // Balanceado (Max 10 Capas | Shield 4.0%)
    PERFIL_AGRESIVO = 3     // Agresivo (Max 15 Capas | Shield 6.0%)
};

//============================================================
//  CONFIGURACIÓN DE CUENTA & LICENCIA
//============================================================
input group "=== LICENCIA & SEGURIDAD ==="
input string             InpLicenseKey         = "BAYESIAN-PRO-SEPTIEMBRE-2026";
input string             InpPurchaseID         = "";       // ID de Vinculo (kopytrading.com)
input ENUM_PERFIL_RIESGO InpPerfilRiesgo        = PERFIL_BALANCEADO; // Perfil de Riesgo Preconfigurado

//============================================================
//  ESTRATEGIA BAYESIANA & RSI
//============================================================
input group "=== MOTOR BAYESIANO & ENTRADAS ==="
input int                InpRSIPeriod          = 14;       // Periodo RSI
input double             InpRSIOverbought      = 70.0;     // Nivel Sobrecompra (Venta)
input double             InpRSIOversold        = 30.0;     // Nivel Sobreventa (Compra)
input double             InpMinConfidence      = 65.0;     // Confianza Bayesiana Minima (%)
input ENUM_TIMEFRAMES    InpTimeframeRef       = PERIOD_H1;// Tendencia Macro de Referencia (EMA 200)

//============================================================
//  GESTIÓN DE CAPAS (GRID ADAPTATIVO)
//============================================================
input group "=== GESTIÓN DE CAPAS & VOLUMEN ==="
input double             InpLoteBase           = 0.01;     // Lote Base por Operacion
input int                InpMaxCapasManual     = 10;       // Maximo de Capas (Modo Manual)
input double             InpDistanciaCapasPips = 15.0;     // Distancia entre Capas (Pips)
input double             InpStopLoss_USD       = 25.00;    // Stop Loss Físico en Broker ($ por pos)
input double             InpTakeProfit_USD     = 8.00;     // Take Profit Físico en Broker ($ por pos)

//============================================================
//  EL CAJERO & ESCUDO (SHIELD DIARIO)
//============================================================
input group "=== ESCUDO DE PROTECCIÓN (SHIELD DIARIO) ==="
input bool               InpActivarShield      = true;     // Activar Shield Diario
input double             InpShieldPctManual    = 4.0;      // % Maximo de Perdida Diaria (Modo Manual)
input double             InpMetaDiariaUSD      = 50.00;    // Meta de Beneficio Diario ($)

//============================================================
//  PROTECCIÓN BE & TRAILING
//============================================================
input group "=== PROTECCIÓN DINÁMICA (BE & TRAILING) ==="
input bool               InpActivarBE          = true;     // Activar Break Even Inteligente
input double             InpBEPctTrigger       = 75.0;     // % del TP para activar BE (ej: 75%)
input bool               InpActivarTrailing    = true;     // Activar Trailing Stop (50%)
input double             InpTrailingStepUSD    = 1.50;     // Paso de Trailing ($)

//============================================================
//  INTERFACE & SISTEMA
//============================================================
input group "=== CONFIGURACIÓN DE PANEL & MAGIC ==="
input bool               InpMostrarHUD         = true;
input int                InpHUD_X              = 15;
input int                InpHUD_Y              = 25;
input ulong              InpMagicNumber        = 888123;

//============================================================
//  VARIABLES GLOBALES
//============================================================
CTrade         trade;
CPositionInfo  posInfo;
COrderInfo     orderInfo;

int            hRSI = INVALID_HANDLE;
int            hSlowEMA = INVALID_HANDLE;
int            hEMA_Chart = INVALID_HANDLE;
int            hATR = INVALID_HANDLE;

datetime       lastBarTime = 0;
datetime       lastDayDate = 0;

double         equityInicioDia = 0.0;
double         ganadoHoy = 0.0;
double         flotanteActual = 0.0;
bool           botActivo = true;

int            winsHoy = 0;
int            lossesHoy = 0;

int            maxCapasEfectivo = 10;
double         shieldPctEfectivo = 4.0;
ENUM_PERFIL_RIESGO perfilActual = PERFIL_BALANCEADO;

double         distanciaCapasEfectiva = 15.0;
string         txtActivoDetectado = "ORO (XAUUSD)";
bool           autoCalibracionActiva = true;

enum ENUM_HUD_TAB { TAB_CUENTA = 0, TAB_INTEL = 1, TAB_CFG = 2, TAB_CONTROL = 3 };
ENUM_HUD_TAB   tabActual = TAB_CONTROL;

bool           stateTrailing = true;
bool           stateBE = true;
bool           statePausado = false;

string         txtEstadoCajero = "CAJERO OK";
string         txtVeredicto = "ESPERANDO SEÑAL BAYESIANA...";
double         confianzaBayesianaUltima = 50.0;
double         rsiActualVal = 50.0;

bool           hudMinimizado = false;

// Nombres de botones interactivos
#define BTN_TAB_CTA      "BAYES_TAB_CTA"
#define BTN_TAB_INTEL    "BAYES_TAB_INTEL"
#define BTN_TAB_CFG      "BAYES_TAB_CFG"
#define BTN_TAB_CTRL     "BAYES_TAB_CTRL"
#define BTN_MINIMIZE_NAME "BAYES_BTN_MINIMIZE"

#define BTN_PROFILE_NAME "BAYES_BTN_PROFILE"
#define BTN_AUTOCAL_NAME "BAYES_BTN_AUTOCAL"
#define BTN_TRAIL_NAME   "BAYES_BTN_TRAIL"
#define BTN_BE_NAME      "BAYES_BTN_BE"
#define BTN_ASEG_NAME    "BAYES_BTN_ASEGURAR"
#define BTN_CLOSE_NAME   "BAYES_BTN_CERRAR"
#define BTN_SHIELD_NAME  "BAYES_BTN_SHIELD"
#define BTN_PAUSE_NAME   "BAYES_BTN_PAUSAR"

void AutoCalibrarActivo()
{
    if (!autoCalibracionActiva)
    {
        distanciaCapasEfectiva = InpDistanciaCapasPips;
        txtActivoDetectado = _Symbol + " (MANUAL)";
        return;
    }

    string sym = _Symbol;
    StringToUpper(sym);

    if (StringFind(sym, "XAU") >= 0 || StringFind(sym, "GOLD") >= 0)
    {
        distanciaCapasEfectiva = 15.0;
        txtActivoDetectado = "ORO (" + _Symbol + ")";
    }
    else if (StringFind(sym, "BTC") >= 0)
    {
        distanciaCapasEfectiva = 200.0;
        txtActivoDetectado = "BITCOIN (" + _Symbol + ")";
    }
    else if (StringFind(sym, "100") >= 0 || StringFind(sym, "NAS") >= 0 || StringFind(sym, "US") >= 0 || StringFind(sym, "SPX") >= 0 || StringFind(sym, "500") >= 0 || StringFind(sym, "GER") >= 0)
    {
        distanciaCapasEfectiva = 25.0;
        txtActivoDetectado = "ÍNDICE (" + _Symbol + ")";
    }
    else
    {
        distanciaCapasEfectiva = 12.0;
        txtActivoDetectado = "FOREX (" + _Symbol + ")";
    }
}

void AplicarPerfil(ENUM_PERFIL_RIESGO p)
{
    perfilActual = p;
    switch(p)
    {
        case PERFIL_CONSERVADOR:
            maxCapasEfectivo = 6;
            shieldPctEfectivo = 3.0;
            break;
        case PERFIL_BALANCEADO:
            maxCapasEfectivo = 10;
            shieldPctEfectivo = 4.0;
            break;
        case PERFIL_AGRESIVO:
            maxCapasEfectivo = 15;
            shieldPctEfectivo = 6.0;
            break;
        default: // Manual
            maxCapasEfectivo = InpMaxCapasManual;
            shieldPctEfectivo = InpShieldPctManual;
            break;
    }
}

void ActualizarBotonPerfil()
{
    string txt = "";
    color bg = clrDarkSlateGray;

    switch(perfilActual)
    {
        case PERFIL_CONSERVADOR:
            txt = "⚡ PERFIL: CONSERVADOR (MAX 6 CAPAS)";
            bg = clrDarkCyan;
            break;
        case PERFIL_BALANCEADO:
            txt = "⚡ PERFIL: BALANCEADO (MAX 10 CAPAS)";
            bg = clrDarkGoldenrod;
            break;
        case PERFIL_AGRESIVO:
            txt = "⚡ PERFIL: AGRESIVO (MAX 15 CAPAS)";
            bg = clrDarkRed;
            break;
        default:
            txt = "⚡ PERFIL: MANUAL (" + IntegerToString(InpMaxCapasManual) + " CAPAS)";
            bg = clrDarkSlateGray;
            break;
    }

    ObjectSetString(0, BTN_PROFILE_NAME, OBJPROP_TEXT, txt);
    ObjectSetInteger(0, BTN_PROFILE_NAME, OBJPROP_BGCOLOR, bg);
}

//+------------------------------------------------------------------+
//| Expert Initialization Function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    trade.SetExpertMagicNumber(InpMagicNumber);
    ChartSetInteger(0, CHART_SHOW_TRADE_LEVELS, true);

    // Auto-Calibración de Activo y Ajuste de Perfil
    AutoCalibrarActivo();
    perfilActual = InpPerfilRiesgo;
    AplicarPerfil(perfilActual);

    stateTrailing = InpActivarTrailing;
    stateBE = InpActivarBE;

    // Inicializar Indicadores
    hRSI = iRSI(_Symbol, _Period, InpRSIPeriod, PRICE_CLOSE);
    hSlowEMA = iMA(_Symbol, InpTimeframeRef, 200, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_Chart = iMA(_Symbol, _Period, 200, 0, MODE_EMA, PRICE_CLOSE);
    hATR = iATR(_Symbol, _Period, 14);

    if (hRSI == INVALID_HANDLE || hSlowEMA == INVALID_HANDLE || hATR == INVALID_HANDLE || hEMA_Chart == INVALID_HANDLE)
    {
        Print("❌ Error inicializando indicadores técnicos.");
        return INIT_FAILED;
    }

    // Dibujar indicadores en el gráfico automáticamente para inspección visual
    ChartIndicatorAdd(0, 0, hEMA_Chart); // Media Móvil EMA 200 del gráfico en ventana principal
    ChartIndicatorAdd(0, 1, hRSI);       // Indicador RSI (14) en subventana 1

    equityInicioDia = AccountInfoDouble(ACCOUNT_EQUITY);
    MqlDateTime dt; TimeCurrent(dt);
    lastDayDate = dt.day;

    if (InpMostrarHUD) CrearHUD();

    Print("✅ MAIKO BAYESIAN STRATEGY PRO inicializado correctamente. Perfil: ", EnumToString(InpPerfilRiesgo));
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert Deinitialization Function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    if (hRSI != INVALID_HANDLE) IndicatorRelease(hRSI);
    if (hSlowEMA != INVALID_HANDLE) IndicatorRelease(hSlowEMA);
    if (hEMA_Chart != INVALID_HANDLE) IndicatorRelease(hEMA_Chart);
    if (hATR != INVALID_HANDLE) IndicatorRelease(hATR);

    DestruirHUD();
}

bool           indicadoresDibujados = false;

void AsegurarIndicadoresEnGrafico()
{
    if (indicadoresDibujados) return;

    if (hEMA_Chart != INVALID_HANDLE)
    {
        ChartIndicatorAdd(0, 0, hEMA_Chart);
    }

    if (hRSI != INVALID_HANDLE)
    {
        int totalWins = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL);
        int subwin = (totalWins > 1) ? 1 : totalWins;
        ChartIndicatorAdd(0, subwin, hRSI);
    }

    ChartRedraw(0);
    indicadoresDibujados = true;
}

//+------------------------------------------------------------------+
//| Expert Tick Function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Garantizar que los indicadores se dibujen en el gráfico
    AsegurarIndicadoresEnGrafico();

    // 1. Gestionar cambio de dia y actualizar métricas
    ActualizarMetricasDia();

    // 2. Actualizar lectura de RSI y Confianza Bayesiana en tiempo real tick a tick
    bool esSv = false, esSc = false;
    CalcularConfianzaBayesiana(esSv, esSc);

    // 3. Verificar cortafuegos Shield y Meta Diaria
    if (VerificarCortafuegos()) return;

    if (!botActivo || statePausado) return;

    // 4. Gestionar Trailing Stop y Break Even en posiciones abiertas
    GestionarProtecciones();

    // 5. Evaluar entradas bayesianas en tiempo real en cada tick
    EvaluarEntradasBayesianas();

    if (InpMostrarHUD) ActualizarValoresHUD();
}

//+------------------------------------------------------------------+
//| OnChartEvent Function for Interactive Buttons                     |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    if (id == CHARTEVENT_OBJECT_CLICK)
    {
        if (sparam == BTN_MINIMIZE_NAME)
        {
            hudMinimizado = !hudMinimizado;
            RedibujarHUD();
        }
        else if (sparam == BTN_TAB_CTA)
        {
            tabActual = TAB_CUENTA;
            RedibujarHUD();
        }
        else if (sparam == BTN_TAB_INTEL)
        {
            tabActual = TAB_INTEL;
            RedibujarHUD();
        }
        else if (sparam == BTN_TAB_CFG)
        {
            tabActual = TAB_CFG;
            RedibujarHUD();
        }
        else if (sparam == BTN_TAB_CTRL)
        {
            tabActual = TAB_CONTROL;
            RedibujarHUD();
        }
        else if (sparam == BTN_AUTOCAL_NAME)
        {
            autoCalibracionActiva = !autoCalibracionActiva;
            AutoCalibrarActivo();
            RedibujarHUD();
        }
        else if (sparam == BTN_TRAIL_NAME)
        {
            stateTrailing = !stateTrailing;
            ObjectSetString(0, BTN_TRAIL_NAME, OBJPROP_TEXT, stateTrailing ? "TRAIL ON" : "TRAIL OFF");
            ObjectSetInteger(0, BTN_TRAIL_NAME, OBJPROP_BGCOLOR, stateTrailing ? clrDarkGreen : clrMaroon);
        }
        else if (sparam == BTN_BE_NAME)
        {
            stateBE = !stateBE;
            ObjectSetString(0, BTN_BE_NAME, OBJPROP_TEXT, stateBE ? "BE ON" : "BE OFF");
            ObjectSetInteger(0, BTN_BE_NAME, OBJPROP_BGCOLOR, stateBE ? clrDarkGreen : clrMaroon);
        }
        else if (sparam == BTN_ASEG_NAME)
        {
            AsegurarBeneficios();
        }
        else if (sparam == BTN_CLOSE_NAME)
        {
            CerrarTodasLasPosiciones();
            txtVeredicto = "POSICIONES CERRADAS MANUALMENTE";
        }
        else if (sparam == BTN_PROFILE_NAME)
        {
            if (perfilActual == PERFIL_CONSERVADOR) perfilActual = PERFIL_BALANCEADO;
            else if (perfilActual == PERFIL_BALANCEADO) perfilActual = PERFIL_AGRESIVO;
            else if (perfilActual == PERFIL_AGRESIVO) perfilActual = PERFIL_MANUAL;
            else perfilActual = PERFIL_CONSERVADOR;

            AplicarPerfil(perfilActual);
            ActualizarBotonPerfil();
            txtVeredicto = "PERFIL CAMBIADO A: " + EnumToString(perfilActual);
        }
        else if (sparam == BTN_SHIELD_NAME)
        {
            shieldPctEfectivo = (shieldPctEfectivo > 0) ? 0 : InpShieldPctManual;
            ObjectSetString(0, BTN_SHIELD_NAME, OBJPROP_TEXT, (shieldPctEfectivo > 0) ? "SHIELD" : "SHIELD OFF");
            ObjectSetInteger(0, BTN_SHIELD_NAME, OBJPROP_BGCOLOR, (shieldPctEfectivo > 0) ? clrDarkBlue : clrMaroon);
        }
        else if (sparam == BTN_PAUSE_NAME)
        {
            statePausado = !statePausado;
            ObjectSetString(0, BTN_PAUSE_NAME, OBJPROP_TEXT, statePausado ? "ENCENDER" : "APAGAR");
            ObjectSetInteger(0, BTN_PAUSE_NAME, OBJPROP_BGCOLOR, statePausado ? clrDarkGreen : clrDarkRed);
        }
        ChartRedraw(0);
    }
}

//+------------------------------------------------------------------+
//| Actualizar Métricas Diarias                                       |
//+------------------------------------------------------------------+
void ActualizarMetricasDia()
{
    MqlDateTime dt; TimeCurrent(dt);
    if (dt.day != lastDayDate)
    {
        lastDayDate = dt.day;
        equityInicioDia = AccountInfoDouble(ACCOUNT_EQUITY);
        ganadoHoy = 0.0;
        winsHoy = 0;
        lossesHoy = 0;
        botActivo = true;
        txtEstadoCajero = "CAJERO OK";
        txtVeredicto = "NUEVA SESIÓN INICIADA";
    }

    flotanteActual = 0.0;
    int posCount = PositionsTotal();
    for (int i = posCount - 1; i >= 0; i--)
    {
        if (posInfo.SelectByIndex(i))
        {
            if (posInfo.Symbol() == _Symbol && posInfo.Magic() == InpMagicNumber)
            {
                flotanteActual += posInfo.Profit() + posInfo.Swap() + posInfo.Commission();
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Verificar Cortafuegos (Shield & Meta Diaria)                     |
//+------------------------------------------------------------------+
bool VerificarCortafuegos()
{
    if (equityInicioDia <= 0) equityInicioDia = AccountInfoDouble(ACCOUNT_EQUITY);

    double maxLossUSD = (equityInicioDia * shieldPctEfectivo) / 100.0;

    // Shield activado por pérdida diaria
    if (InpActivarShield && shieldPctEfectivo > 0 && (ganadoHoy + flotanteActual <= -maxLossUSD))
    {
        CerrarTodasLasPosiciones();
        botActivo = false;
        txtEstadoCajero = "🛑 SHIELD ACTIVADO (-" + DoubleToString(shieldPctEfectivo, 1) + "%)";
        txtVeredicto = "SHIELD PROTEGIÓ EL CAPITAL HOY";
        return true;
    }

    // Meta diaria alcanzada
    if (ganadoHoy >= InpMetaDiariaUSD)
    {
        CerrarTodasLasPosiciones();
        botActivo = false;
        txtEstadoCajero = "🎯 META DÍA (+$" + DoubleToString(InpMetaDiariaUSD, 2) + ")";
        txtVeredicto = "OBJETIVO DIARIO ALCANZADO";
        return true;
    }

    return false;
}

//+------------------------------------------------------------------+
//| Calcular Inferencia y Confianza Bayesiana                        |
//+------------------------------------------------------------------+
double CalcularConfianzaBayesiana(bool &esSobreventa, bool &esSobrecompra)
{
    double rsiVal[1];
    if (CopyBuffer(hRSI, 0, 0, 1, rsiVal) <= 0) return 50.0;

    rsiActualVal = rsiVal[0];
    esSobreventa  = (rsiVal[0] <= InpRSIOversold);
    esSobrecompra = (rsiVal[0] >= InpRSIOverbought);

    // 1. Puntuación RSI (hasta 40%)
    double scoreRSI = 0.0;
    if (esSobreventa)
    {
        scoreRSI = 30.0 + 10.0 * (InpRSIOversold - rsiVal[0]) / InpRSIOversold;
    }
    else if (esSobrecompra)
    {
        scoreRSI = 30.0 + 10.0 * (rsiVal[0] - InpRSIOverbought) / (100.0 - InpRSIOverbought);
    }
    if (scoreRSI > 40.0) scoreRSI = 40.0;

    // 2. Puntuación Momentum (hasta 30%)
    int cUp = 0, cDn = 0;
    for (int i = 1; i <= 3; i++)
    {
        double o = iOpen(_Symbol, _Period, i);
        double c = iClose(_Symbol, _Period, i);
        if (c > o) cUp++;
        if (c < o) cDn++;
    }
    double scoreMom = 15.0;
    if (esSobreventa && cUp >= 1) scoreMom = 25.0;
    if (esSobrecompra && cDn >= 1) scoreMom = 25.0;

    // 3. Puntuación Volatilidad ATR (hasta 15%)
    double atrVal[1];
    double scoreATR = 10.0;
    if (CopyBuffer(hATR, 0, 0, 1, atrVal) > 0)
    {
        if (atrVal[0] > 0.0) scoreATR = 15.0;
    }

    // 4. Puntuación Spread (hasta 15%)
    long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    double scoreSpread = (spread <= 100) ? 15.0 : 5.0;

    double totalConfianza = scoreRSI + scoreMom + scoreATR + scoreSpread;
    if (totalConfianza < 5.0) totalConfianza = 5.0;
    if (totalConfianza > 95.0) totalConfianza = 95.0;

    confianzaBayesianaUltima = totalConfianza;
    return totalConfianza;
}

//+------------------------------------------------------------------+
//| Evaluar Entradas Bayesianas & Capas                              |
//+------------------------------------------------------------------+
void EvaluarEntradasBayesianas()
{
    bool esSobreventa = false, esSobrecompra = false;
    double confianza = CalcularConfianzaBayesiana(esSobreventa, esSobrecompra);

    int abiertas = ContarPosicionesMagic();
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    // Entrada Inicial (0 posiciones)
    if (abiertas == 0)
    {
        if (confianza >= InpMinConfidence)
        {
            double slDelta = USDtoPriceDelta(InpStopLoss_USD, InpLoteBase);
            double tpDelta = USDtoPriceDelta(InpTakeProfit_USD, InpLoteBase);

            if (esSobreventa)
            {
                double sl = NormalizeDouble(ask - slDelta, _Digits);
                double tp = NormalizeDouble(ask + tpDelta, _Digits);
                if (trade.Buy(InpLoteBase, _Symbol, ask, sl, tp, "BAYESIAN_BUY_1"))
                {
                    txtVeredicto = "COMPRA BAYESIANA EJECUTADA (" + DoubleToString(confianza, 1) + "%) 📈";
                }
            }
            else if (esSobrecompra)
            {
                double sl = NormalizeDouble(bid + slDelta, _Digits);
                double tp = NormalizeDouble(bid - tpDelta, _Digits);
                if (trade.Sell(InpLoteBase, _Symbol, bid, sl, tp, "BAYESIAN_SELL_1"))
                {
                    txtVeredicto = "VENTA BAYESIANA EJECUTADA (" + DoubleToString(confianza, 1) + "%) 📉";
                }
            }
        }
    }
    // Entradas de Capa Adicional (Grid Adaptativo)
    else if (abiertas < maxCapasEfectivo)
    {
        ulong firstTicket = ObtenerPrimerTicket();
        if (firstTicket > 0 && PositionSelectByTicket(firstTicket))
        {
            ENUM_POSITION_TYPE mainType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double distPoints = InpDistanciaCapasPips * _Point * 10.0;
            double loteNorm = NormalizarVolumen(InpLoteBase);
            double slDelta = USDtoPriceDelta(InpStopLoss_USD, loteNorm);
            double tpDelta = USDtoPriceDelta(InpTakeProfit_USD, loteNorm);

            if (mainType == POSITION_TYPE_BUY && (bid <= openPrice - (abiertas * distPoints)))
            {
                double sl = NormalizeDouble(ask - slDelta, _Digits);
                double tp = NormalizeDouble(ask + tpDelta, _Digits);
                if (trade.Buy(loteNorm, _Symbol, ask, sl, tp, "BAYESIAN_CAPA_BUY"))
                {
                    txtVeredicto = "CAPA " + IntegerToString(abiertas + 1) + " COMPRA AGREGADA 🛡️";
                }
            }
            else if (mainType == POSITION_TYPE_SELL && (ask >= openPrice + (abiertas * distPoints)))
            {
                double sl = NormalizeDouble(bid + slDelta, _Digits);
                double tp = NormalizeDouble(bid - tpDelta, _Digits);
                if (trade.Sell(loteNorm, _Symbol, bid, sl, tp, "BAYESIAN_CAPA_SELL"))
                {
                    txtVeredicto = "CAPA " + IntegerToString(abiertas + 1) + " VENTA AGREGADA 🛡️";
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Gestionar BreakEven y Trailing Stop                              |
//+------------------------------------------------------------------+
void GestionarProtecciones()
{
    int posCount = PositionsTotal();
    for (int i = posCount - 1; i >= 0; i--)
    {
        if (posInfo.SelectByIndex(i))
        {
            if (posInfo.Symbol() == _Symbol && posInfo.Magic() == InpMagicNumber)
            {
                double openPrice = posInfo.PriceOpen();
                double currentSL  = posInfo.StopLoss();
                double currentTP  = posInfo.TakeProfit();
                double profitUSD  = posInfo.Profit();
                ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)posInfo.PositionType();

                // BreakEven Inteligente (al alcanzar X% del TP)
                if (stateBE && currentTP > 0)
                {
                    double tpDistance = MathAbs(currentTP - openPrice);
                    if (tpDistance > 0)
                    {
                        if (type == POSITION_TYPE_BUY)
                        {
                            double currentDist = SymbolInfoDouble(_Symbol, SYMBOL_BID) - openPrice;
                            if (currentDist >= (tpDistance * InpBEPctTrigger / 100.0) && (currentSL < openPrice))
                            {
                                trade.PositionModify(posInfo.Ticket(), NormalizeDouble(openPrice + (2.0 * _Point * 10.0), _Digits), currentTP);
                            }
                        }
                        else if (type == POSITION_TYPE_SELL)
                        {
                            double currentDist = openPrice - SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                            if (currentDist >= (tpDistance * InpBEPctTrigger / 100.0) && (currentSL > openPrice || currentSL == 0))
                            {
                                trade.PositionModify(posInfo.Ticket(), NormalizeDouble(openPrice - (2.0 * _Point * 10.0), _Digits), currentTP);
                            }
                        }
                    }
                }

                // Trailing Stop (Persigue al precio)
                if (stateTrailing && profitUSD >= InpTrailingStepUSD * 2.0)
                {
                    double trailDelta = USDtoPriceDelta(InpTrailingStepUSD, posInfo.Volume());
                    if (type == POSITION_TYPE_BUY)
                    {
                        double newSL = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID) - trailDelta, _Digits);
                        if (newSL > currentSL + (_Point * 10.0))
                        {
                            trade.PositionModify(posInfo.Ticket(), newSL, currentTP);
                        }
                    }
                    else if (type == POSITION_TYPE_SELL)
                    {
                        double newSL = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK) + trailDelta, _Digits);
                        if (currentSL == 0 || newSL < currentSL - (_Point * 10.0))
                        {
                            trade.PositionModify(posInfo.Ticket(), newSL, currentTP);
                        }
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Asegurar Beneficios (Cerrar Capas Rentables)                     |
//+------------------------------------------------------------------+
void AsegurarBeneficios()
{
    int count = 0;
    int posCount = PositionsTotal();
    for (int i = posCount - 1; i >= 0; i--)
    {
        if (posInfo.SelectByIndex(i))
        {
            if (posInfo.Symbol() == _Symbol && posInfo.Magic() == InpMagicNumber)
            {
                if (posInfo.Profit() > 0)
                {
                    trade.PositionClose(posInfo.Ticket());
                    count++;
                }
            }
        }
    }
    txtVeredicto = "ASEGURADAS " + IntegerToString(count) + " POSICIONES RENTABLES";
}

//+------------------------------------------------------------------+
//| Cerrar Todas las Posiciones                                       |
//+------------------------------------------------------------------+
void CerrarTodasLasPosiciones()
{
    int posCount = PositionsTotal();
    for (int i = posCount - 1; i >= 0; i--)
    {
        if (posInfo.SelectByIndex(i))
        {
            if (posInfo.Symbol() == _Symbol && posInfo.Magic() == InpMagicNumber)
            {
                trade.PositionClose(posInfo.Ticket());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Funciones de Utilidad (Lote, Tickets y Conversión)               |
//+------------------------------------------------------------------+
double NormalizarVolumen(double v)
{
    double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    double minVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    if (step <= 0) step = 0.01;
    double norm = MathFloor(v / step) * step;
    if (norm < minVol) norm = minVol;
    if (norm > maxVol) norm = maxVol;
    return NormalizeDouble(norm, 2);
}

double USDtoPriceDelta(double usdTarget, double lotSize)
{
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

    if (tickValue <= 0 || tickSize <= 0 || lotSize <= 0) return 4.0;
    double usdPerPriceUnit = lotSize * (tickValue / tickSize);
    if (usdPerPriceUnit <= 0) return 4.0;

    return (usdTarget / usdPerPriceUnit);
}

int ContarPosicionesMagic()
{
    int count = 0;
    int posCount = PositionsTotal();
    for (int i = 0; i < posCount; i++)
    {
        if (posInfo.SelectByIndex(i))
        {
            if (posInfo.Symbol() == _Symbol && posInfo.Magic() == InpMagicNumber) count++;
        }
    }
    return count;
}

ulong ObtenerPrimerTicket()
{
    int posCount = PositionsTotal();
    for (int i = 0; i < posCount; i++)
    {
        if (posInfo.SelectByIndex(i))
        {
            if (posInfo.Symbol() == _Symbol && posInfo.Magic() == InpMagicNumber) return posInfo.Ticket();
        }
    }
    return 0;
}

//+------------------------------------------------------------------+
//| Creación y Actualización de Panel Visual HUD Interactivo         |
//+------------------------------------------------------------------+
void RedibujarHUD()
{
    DestruirHUD();
    CrearHUD();
    ActualizarValoresHUD();
}

//+------------------------------------------------------------------+
//| Creación y Actualización de Panel Visual HUD Interactivo         |
//+------------------------------------------------------------------+
void CrearHUD()
{
    int x = InpHUD_X;
    int y = InpHUD_Y;

    if (hudMinimizado)
    {
        // Panel Minimizado Compacto
        ObjectCreate(0, "BAYES_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
        ObjectSetInteger(0, "BAYES_BG", OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, "BAYES_BG", OBJPROP_YDISTANCE, y);
        ObjectSetInteger(0, "BAYES_BG", OBJPROP_XSIZE, 220);
        ObjectSetInteger(0, "BAYES_BG", OBJPROP_YSIZE, 32);
        ObjectSetInteger(0, "BAYES_BG", OBJPROP_BGCOLOR, clrBlack);
        ObjectSetInteger(0, "BAYES_BG", OBJPROP_BORDER_COLOR, clrDarkGoldenrod);
        ObjectSetInteger(0, "BAYES_BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);

        CrearLabel("BAYES_LBL_TITLE", "BAYESIAN PRO", x + 10, y + 8, clrGold, 9, true);
        CrearBoton(BTN_MINIMIZE_NAME, "[ + ]", x + 175, y + 5, 36, 22, clrDarkGoldenrod);
        return;
    }

    // Panel Maximizado Normal
    ObjectCreate(0, "BAYES_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_XSIZE, 330);
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_YSIZE, 370);
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_BGCOLOR, clrBlack);
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_BORDER_COLOR, clrDarkGoldenrod);
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);

    // Barra de Pestañas de Navegación (Top Tabs) + Botón Minimizar
    CrearBoton(BTN_TAB_CTA, "CTA", x + 8, y + 8, 55, 22, (tabActual == TAB_CUENTA) ? clrDarkGoldenrod : clrDarkSlateGray);
    CrearBoton(BTN_TAB_INTEL, "INTEL", x + 67, y + 8, 55, 22, (tabActual == TAB_INTEL) ? clrDarkGoldenrod : clrDarkSlateGray);
    CrearBoton(BTN_TAB_CFG, "CFG", x + 126, y + 8, 55, 22, (tabActual == TAB_CFG) ? clrDarkGoldenrod : clrDarkSlateGray);
    CrearBoton(BTN_TAB_CTRL, "CONTROL", x + 185, y + 8, 70, 22, (tabActual == TAB_CONTROL) ? clrDarkGoldenrod : clrDarkSlateGray);
    CrearBoton(BTN_MINIMIZE_NAME, "[ — ]", x + 262, y + 8, 60, 22, clrDarkRed);

    // Titulo de Pestaña Activa
    string titleTab = "BAYESIAN STRATEGY PRO";
    if (tabActual == TAB_CUENTA) titleTab = "PANEL DE CUENTA & CAJERO";
    else if (tabActual == TAB_INTEL) titleTab = "INTELIGENCIA & MERCADO";
    else if (tabActual == TAB_CFG) titleTab = "CONFIGURACIÓN DE BOT";
    else if (tabActual == TAB_CONTROL) titleTab = "CONTROL DE OPERACIONES";

    CrearLabel("BAYES_LBL_TITLE", titleTab, x + 12, y + 38, clrGold, 9, true);

    // ================= PESTAÑA: CONTROL (DEFAULT) =================
    if (tabActual == TAB_CONTROL)
    {
        CrearLabel("BAYES_LBL_EQ", "EQUITY: $0.00", x + 12, y + 55, clrCyan, 9, true);
        CrearLabel("BAYES_LBL_BAL", "BALANCE: $0.00", x + 12, y + 73, clrWhite, 9, false);
        CrearLabel("BAYES_LBL_CAPAS", "CAPAS ABIERTAS: 0 / 10", x + 12, y + 93, clrYellow, 9, true);
        CrearLabel("BAYES_LBL_ACTIVO", "ACTIVO: " + txtActivoDetectado, x + 12, y + 111, clrOrange, 8, true);
        CrearLabel("BAYES_LBL_RSI", "RSI (14): -- (Compra <=30 | Venta >=70)", x + 12, y + 129, clrLightSkyBlue, 8, true);
        CrearLabel("BAYES_LBL_CONF", "CONFIANZA BAYES: 50.0%", x + 12, y + 147, clrLime, 9, true);
        CrearLabel("BAYES_LBL_SHIELD", "SHIELD HOY: 0.0% / 4.0%", x + 12, y + 165, clrOrange, 8, false);
        CrearLabel("BAYES_LBL_VEREDICT", "ESPERANDO SEÑAL...", x + 12, y + 185, clrGold, 8, true);

        // Selector Táctil de Perfil de Riesgo (Fila 1)
        CrearBoton(BTN_PROFILE_NAME, "", x + 12, y + 210, 305, 28, clrDarkGoldenrod);
        ActualizarBotonPerfil();

        // Botones Interactivos de Gestión (Fila 2)
        CrearBoton(BTN_TRAIL_NAME, stateTrailing ? "TRAIL ON" : "TRAIL OFF", x + 12, y + 248, 95, 26, stateTrailing ? clrDarkGreen : clrMaroon);
        CrearBoton(BTN_BE_NAME, stateBE ? "BE ON" : "BE OFF", x + 113, y + 248, 95, 26, stateBE ? clrDarkGreen : clrMaroon);
        CrearBoton(BTN_ASEG_NAME, "ASEGURAR", x + 214, y + 248, 103, 26, clrDarkSlateGray);

        // Botones de Control de Operaciones (Fila 3)
        CrearBoton(BTN_CLOSE_NAME, "CERRAR TODO", x + 12, y + 284, 100, 30, clrDarkRed);
        CrearBoton(BTN_SHIELD_NAME, "SHIELD", x + 118, y + 284, 90, 30, clrDarkBlue);
        CrearBoton(BTN_PAUSE_NAME, statePausado ? "ENCENDER" : "APAGAR", x + 214, y + 284, 103, 30, statePausado ? clrDarkGreen : clrDarkRed);
    }
    // ================= PESTAÑA: CUENTA (CTA) =================
    else if (tabActual == TAB_CUENTA)
    {
        CrearLabel("BAYES_LBL_EQ", "EQUITY ACTUAL: $0.00", x + 12, y + 65, clrCyan, 10, true);
        CrearLabel("BAYES_LBL_BAL", "BALANCE CUENTA: $0.00", x + 12, y + 90, clrWhite, 9, false);
        CrearLabel("BAYES_LBL_RESULT", "FLOTANTE ACTUAL: $0.00", x + 12, y + 115, clrYellow, 9, true);
        CrearLabel("BAYES_LBL_CAPAS", "CAPAS EN MERCADO: 0 / 10", x + 12, y + 140, clrWhite, 9, false);
        CrearLabel("BAYES_LBL_SHIELD", "ESCUDO SHIELD DIARIO: 0.0% / 4.0%", x + 12, y + 165, clrOrange, 9, true);
        CrearLabel("BAYES_LBL_VEREDICT", "ESTADO CAJERO: OK", x + 12, y + 190, clrLime, 9, true);

        CrearBoton(BTN_CLOSE_NAME, "CERRAR TODAS LAS POSICIONES", x + 12, y + 240, 305, 35, clrDarkRed);
    }
    // ================= PESTAÑA: INTELIGENCIA (INTEL) =================
    else if (tabActual == TAB_INTEL)
    {
        CrearLabel("BAYES_LBL_ACTIVO", "ACTIVO DETECTADO: " + txtActivoDetectado, x + 12, y + 65, clrOrange, 9, true);
        CrearLabel("BAYES_LBL_SUB", "CALIBRACIÓN: " + (autoCalibracionActiva ? "AUTO-ADAPTATIVA 🧠" : "MANUAL ⚙️"), x + 12, y + 88, clrWhite, 9, false);
        CrearLabel("BAYES_LBL_CAPAS", "DISTANCIA CAPAS: " + DoubleToString(distanciaCapasEfectiva, 1) + " PTS", x + 12, y + 110, clrYellow, 9, true);
        CrearLabel("BAYES_LBL_RSI", "RSI ACTUAL (14): -- (Compra <=30 | Venta >=70)", x + 12, y + 132, clrLightSkyBlue, 8, true);
        CrearLabel("BAYES_LBL_CONF", "CONFIANZA BAYESIANA: 50.0%", x + 12, y + 154, clrLime, 9, true);
        CrearLabel("BAYES_LBL_VEREDICT", "VEREDICTO: ESPERANDO SEÑAL...", x + 12, y + 180, clrGold, 8, true);

        CrearBoton(BTN_AUTOCAL_NAME, autoCalibracionActiva ? "🎯 AUTO-CALIBRAR SIMBOLO [ON]" : "🎯 AUTO-CALIBRAR SIMBOLO [OFF]", x + 12, y + 240, 305, 35, autoCalibracionActiva ? clrDarkGreen : clrMaroon);
    }
    // ================= PESTAÑA: CONFIGURACIÓN (CFG) =================
    else if (tabActual == TAB_CFG)
    {
        CrearLabel("BAYES_LBL_SUB", "CONFIGURACIÓN TÁCTIL Y PERFIL", x + 12, y + 65, clrWhite, 9, true);
        CrearLabel("BAYES_LBL_CAPAS", "CAPAS MÁXIMAS: " + IntegerToString(maxCapasEfectivo) + " CAPAS", x + 12, y + 90, clrYellow, 9, false);
        CrearLabel("BAYES_LBL_SHIELD", "ESCUDO SHIELD DIARIO: " + DoubleToString(shieldPctEfectivo, 1) + "%", x + 12, y + 115, clrOrange, 9, false);
        CrearLabel("BAYES_LBL_ACTIVO", "DISTANCIA ENTRE CAPAS: " + DoubleToString(distanciaCapasEfectiva, 1) + " PTS", x + 12, y + 140, clrCyan, 9, false);

        CrearBoton(BTN_PROFILE_NAME, "", x + 12, y + 180, 305, 32, clrDarkGoldenrod);
        ActualizarBotonPerfil();

        CrearBoton(BTN_AUTOCAL_NAME, autoCalibracionActiva ? "🎯 MODO AUTO-CALIBRACIÓN [ON]" : "🎯 MODO AUTO-CALIBRACIÓN [OFF]", x + 12, y + 230, 305, 32, autoCalibracionActiva ? clrDarkGreen : clrMaroon);
    }
}

void ActualizarValoresHUD()
{
    double eq = AccountInfoDouble(ACCOUNT_EQUITY);
    double bal = AccountInfoDouble(ACCOUNT_BALANCE);
    int abiertas = ContarPosicionesMagic();

    if (hudMinimizado)
    {
        ObjectSetString(0, "BAYES_LBL_TITLE", OBJPROP_TEXT, "BAYES $" + DoubleToString(eq, 2) + " | " + DoubleToString(confianzaBayesianaUltima, 0) + "%");
        return;
    }

    if (tabActual == TAB_CONTROL)
    {
        ObjectSetString(0, "BAYES_LBL_EQ", OBJPROP_TEXT, "EQUITY: $" + DoubleToString(eq, 2));
        ObjectSetString(0, "BAYES_LBL_BAL", OBJPROP_TEXT, "BALANCE: $" + DoubleToString(bal, 2));
        ObjectSetString(0, "BAYES_LBL_CAPAS", OBJPROP_TEXT, "CAPAS ABIERTAS: " + IntegerToString(abiertas) + " / " + IntegerToString(maxCapasEfectivo));
        ObjectSetString(0, "BAYES_LBL_ACTIVO", OBJPROP_TEXT, "ACTIVO: " + txtActivoDetectado + (autoCalibracionActiva ? " [AUTO OK 🧠]" : " [MANUAL]"));
        ObjectSetString(0, "BAYES_LBL_RSI", OBJPROP_TEXT, "RSI (14): " + DoubleToString(rsiActualVal, 1) + " (S.Venta: <=30 | S.Compra: >=70)");
        ObjectSetString(0, "BAYES_LBL_CONF", OBJPROP_TEXT, "CONFIANZA BAYES: " + DoubleToString(confianzaBayesianaUltima, 1) + "%");
        ObjectSetString(0, "BAYES_LBL_SHIELD", OBJPROP_TEXT, "SHIELD ESTADO: " + txtEstadoCajero);
        ObjectSetString(0, "BAYES_LBL_VEREDICT", OBJPROP_TEXT, txtVeredicto);
    }
    else if (tabActual == TAB_CUENTA)
    {
        ObjectSetString(0, "BAYES_LBL_EQ", OBJPROP_TEXT, "EQUITY ACTUAL: $" + DoubleToString(eq, 2));
        ObjectSetString(0, "BAYES_LBL_BAL", OBJPROP_TEXT, "BALANCE CUENTA: $" + DoubleToString(bal, 2));
        ObjectSetString(0, "BAYES_LBL_RESULT", OBJPROP_TEXT, "FLOTANTE ACTUAL: $" + DoubleToString(flotanteActual, 2));
        ObjectSetString(0, "BAYES_LBL_CAPAS", OBJPROP_TEXT, "CAPAS EN MERCADO: " + IntegerToString(abiertas) + " / " + IntegerToString(maxCapasEfectivo));
        ObjectSetString(0, "BAYES_LBL_SHIELD", OBJPROP_TEXT, "ESCUDO SHIELD DIARIO: " + DoubleToString(shieldPctEfectivo, 1) + "%");
        ObjectSetString(0, "BAYES_LBL_VEREDICT", OBJPROP_TEXT, "ESTADO CAJERO: " + txtEstadoCajero);
    }
    else if (tabActual == TAB_INTEL)
    {
        ObjectSetString(0, "BAYES_LBL_ACTIVO", OBJPROP_TEXT, "SIMBOLO DETECTADO: " + txtActivoDetectado);
        ObjectSetString(0, "BAYES_LBL_SUB", OBJPROP_TEXT, "CALIBRACIÓN: " + (autoCalibracionActiva ? "AUTO-ADAPTATIVA 🧠" : "MANUAL ⚙️"));
        ObjectSetString(0, "BAYES_LBL_CAPAS", OBJPROP_TEXT, "DISTANCIA CAPAS AUTO: " + DoubleToString(distanciaCapasEfectiva, 1) + " PTS");
        ObjectSetString(0, "BAYES_LBL_RSI", OBJPROP_TEXT, "RSI ACTUAL (14): " + DoubleToString(rsiActualVal, 1) + " (S.Venta: <=30 | S.Compra: >=70)");
        ObjectSetString(0, "BAYES_LBL_CONF", OBJPROP_TEXT, "CONFIANZA BAYESIANA: " + DoubleToString(confianzaBayesianaUltima, 1) + "%");
        ObjectSetString(0, "BAYES_LBL_VEREDICT", OBJPROP_TEXT, "VEREDICTO: " + txtVeredicto);
    }
    else if (tabActual == TAB_CFG)
    {
        ObjectSetString(0, "BAYES_LBL_CAPAS", OBJPROP_TEXT, "CAPAS MÁXIMAS: " + IntegerToString(maxCapasEfectivo) + " CAPAS");
        ObjectSetString(0, "BAYES_LBL_SHIELD", OBJPROP_TEXT, "ESCUDO SHIELD DIARIO: " + DoubleToString(shieldPctEfectivo, 1) + "%");
        ObjectSetString(0, "BAYES_LBL_ACTIVO", OBJPROP_TEXT, "DISTANCIA ENTRE CAPAS: " + DoubleToString(distanciaCapasEfectiva, 1) + " PTS");
    }
}

void DestruirHUD()
{
    ObjectDelete(0, "BAYES_BG");
    ObjectDelete(0, "BAYES_LBL_TITLE");
    ObjectDelete(0, "BAYES_LBL_SUB");
    ObjectDelete(0, "BAYES_LBL_EQ");
    ObjectDelete(0, "BAYES_LBL_BAL");
    ObjectDelete(0, "BAYES_LBL_CAPAS");
    ObjectDelete(0, "BAYES_LBL_ACTIVO");
    ObjectDelete(0, "BAYES_LBL_RSI");
    ObjectDelete(0, "BAYES_LBL_CONF");
    ObjectDelete(0, "BAYES_LBL_RESULT");
    ObjectDelete(0, "BAYES_LBL_SHIELD");
    ObjectDelete(0, "BAYES_LBL_VEREDICT");

    ObjectDelete(0, BTN_TAB_CTA);
    ObjectDelete(0, BTN_TAB_INTEL);
    ObjectDelete(0, BTN_TAB_CFG);
    ObjectDelete(0, BTN_TAB_CTRL);
    ObjectDelete(0, BTN_MINIMIZE_NAME);

    ObjectDelete(0, BTN_PROFILE_NAME);
    ObjectDelete(0, BTN_AUTOCAL_NAME);
    ObjectDelete(0, BTN_TRAIL_NAME);
    ObjectDelete(0, BTN_BE_NAME);
    ObjectDelete(0, BTN_ASEG_NAME);
    ObjectDelete(0, BTN_CLOSE_NAME);
    ObjectDelete(0, BTN_SHIELD_NAME);
    ObjectDelete(0, BTN_PAUSE_NAME);
}

void CrearLabel(string name, string text, int x, int y, color col, int font_size, bool bold)
{
    ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_COLOR, col);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size);
    ObjectSetString(0, name, OBJPROP_FONT, bold ? "Arial Bold" : "Arial");
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

void CrearBoton(string name, string text, int x, int y, int w, int h, color bg_col)
{
    ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg_col);
    ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrGray);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
    ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

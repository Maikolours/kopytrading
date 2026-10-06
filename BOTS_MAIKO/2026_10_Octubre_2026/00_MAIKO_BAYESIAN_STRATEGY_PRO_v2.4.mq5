//+------------------------------------------------------------------+
//|          00_MAIKO_BAYESIAN_STRATEGY_PRO_v2.4.mq5                 |
//|    ALGORITMO BAYESIAN STRATEGY PRO v2.4 - EDICIÓN OFICIAL 2026   |
//|   MOTOR BAYESIANO + RÉGIMEN ADAPTATIVO (ADX HISTÉRESIS + MTF)    |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Maiko Trading Corp."
#property link      "https://www.kopytrading.com"
#property version   "2.40"
#property strict
#property description "Bayesian Strategy Pro v2.4 | Motor de Régimen ADX (Histéresis 22-25) + Presión MTF M15/H1 + HUD Compacto + Presets Adaptativos"

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

enum ENUM_MODO_TENDENCIA
{
    TENDENCIA_OFF = 0,               // Desactivado (Operar en Ambas Direcciones)
    TENDENCIA_EMA200_STRICT = 1,     // Estricto EMA200 H1 (Solo BUY sobre EMA / Solo SELL bajo EMA)
    TENDENCIA_REGIMEN_AUTO_ADX = 2   // Auto-Régimen ADX + Presión Compradora/Vendedora MTF (Recomendado v2.4)
};

enum ENUM_MODO_PRESET_ACTIVO
{
    PRESET_AUTO = 0,          // Auto-Deteccion por Simbolo del Grafico (Recomendado)
    PRESET_FORZAR_BTC = 1,    // Forzar Preset BITCOIN (BTCUSD 24/7 | Magic 888126)
    PRESET_FORZAR_ORO = 2,    // Forzar Preset ORO (XAUUSD | Magic 888127)
    PRESET_FORZAR_EURUSD = 3, // Forzar Preset FOREX (EURUSD / GBPUSD | Magic 888128)
    PRESET_FORZAR_SP500 = 4,  // Forzar Preset INDICE S&P 500 (US500 | Magic 888129)
    PRESET_MANUAL = 5         // Manual (Usar Parametros Generales Personalizados)
};

enum ENUM_REGIMEN_MERCADO
{
    REGIMEN_LATERAL = 0,      // Mercado en Rango (Ambas Direcciones)
    REGIMEN_ALCISTA = 1,      // Tendencia Alcista Fuerte (Solo Compras)
    REGIMEN_BAJISTA = 2       // Tendencia Bajista Fuerte (Solo Ventas)
};

enum ENUM_TAB_HUD
{
    TAB_CUENTA = 0,
    TAB_INTEL = 1,
    TAB_CFG = 2,
    TAB_CONTROL = 3
};

//============================================================
//  CONFIGURACIÓN DE CUENTA & LICENCIA
//============================================================
input group "━━━━━━ 🔑 LICENCIA & PRESET DE ACTIVO ━━━━━━"
input string             InpLicenseKey         = "BAYESIAN-PRO-OCTUBRE-2026";
input string             InpPurchaseID         = "";       // ID de Vinculo (kopytrading.com)
input ENUM_PERFIL_RIESGO InpPerfilRiesgo        = PERFIL_MANUAL; // Perfil de Riesgo Preconfigurado
input ENUM_MODO_PRESET_ACTIVO InpPresetActivo  = PRESET_AUTO;   // Seleccionar Modo (Auto / ORO / EURUSD / S&P 500 / BTC / Manual)
input ENUM_MODO_TENDENCIA InpFiltroTendencia   = TENDENCIA_REGIMEN_AUTO_ADX; // Modo Filtro de Tendencia & Régimen ADX

//============================================================
//  MARQUITAS AMARILLAS DE ESTRUCTURA
//============================================================
input group "━━━━━━ 📍 ESTRUCTURA DE MERCADO ━━━━━━"
input bool               InpMostrarLineasEstructura = true;      // Mostrar Marquitas Amarillas en Grafico
input int                InpPeriodoEstructura       = 12;        // Sensibilidad de Estructura (Velas)
input color              InpColorEstructura         = clrGold;   // Color de Marquitas Amarillas

//============================================================
//  ESTRATEGIA BAYESIANA & RSI (MODO MANUAL)
//============================================================
input group "━━━━━━ 🧠 MOTOR BAYESIANO MANUAL / PERSONALIZADO ━━━━━━"
input int                InpRSIPeriod          = 14;       // Periodo RSI (Base Manual)
input double             InpRSIOverbought      = 70.0;     // Nivel Sobrecompra (Base Manual)
input double             InpRSIOversold        = 28.0;     // Nivel Sobreventa (Base Manual)
input double             InpMinConfidence      = 80.0;     // Confianza Bayesiana Minima (%) (Base Manual)
input double             InpDistanciaCapasPips = 25.0;     // Distancia entre Capas (Pips/Pts Manual)
input ENUM_TIMEFRAMES    InpTimeframeRef       = PERIOD_H1;// Tendencia Macro de Referencia (EMA 200)

//============================================================
//  GESTIÓN DE CAPAS (GRID ADAPTATIVO UNIDIRECCIONAL)
//============================================================
input group "━━━━━━ 📊 GESTION DE CAPAS & VOLUMEN ━━━━━━"
input double             InpLoteBase           = 0.01;     // Lote Base por Operacion
input int                InpMaxCapasManual     = 10;       // Maximo de Capas (Modo Manual)
input double             InpStopLoss_USD       = 25.00;    // Stop Loss Fisico en Broker ($ por pos)
input double             InpTakeProfit_USD     = 8.00;     // Take Profit Fisico en Broker ($ por pos)

//============================================================
//  EL CAJERO & ESCUDO (SHIELD DIARIO)
//============================================================
input group "━━━━━━ 🛡️ ESCUDO DE PROTECCION ━━━━━━"
input bool               InpActivarShield      = true;     // Activar Shield Diario
input double             InpShieldPctManual    = 4.0;      // % Maximo de Perdida Diaria (Modo Manual)
input double             InpMetaDiariaUSD      = 50.00;    // Meta de Beneficio Diario ($)

//============================================================
//  PROTECCIÓN BE & TRAILING
//============================================================
input group "━━━━━━ 🎯 PROTECCION DINAMICA (BE & TRAILING) ━━━━━━"
input bool               InpActivarBE          = true;     // Activar Break Even Inteligente
input double             InpBEPctTrigger       = 85.0;     // % del TP para activar BE
input bool               InpActivarTrailing    = true;     // Activar Trailing Stop (50%)
input double             InpTrailingStepUSD    = 1.50;     // Paso de Trailing ($)

//============================================================
//  FILTRO HORARIO OPERATIVO GENERAL (MANUAL)
//============================================================
input group "━━━━━━ ⏰ FILTRO HORARIO GENERAL (MANUAL) ━━━━━━"
input bool               InpActivarFiltroHorario = false;    // Activar Filtro Horario General (false = 24/7)
input int                InpHoraInicio           = 0;        // Hora Inicio Operativa General (Broker 0-23)
input int                InpHoraFin              = 24;       // Hora Fin Operativa General (Broker 0-24)
input bool               InpOperarLunes        = true;     // Operar los Lunes
input bool               InpOperarMartes       = true;     // Operar los Martes
input bool               InpOperarMiercoles    = true;     // Operar los Miercoles
input bool               InpOperarJueves       = true;     // Operar los Jueves
input bool               InpOperarViernes      = true;     // Operar los Viernes
input bool               InpOperarSabado       = true;     // Operar los Sabados
input bool               InpOperarDomingo      = true;     // Operar los Domingos

//============================================================
//  INTERFACE & SISTEMA
//============================================================
input group "━━━━━━ 🖥️ PANEL HUD & MAGIC GLOBAL ━━━━━━"
input bool               InpMostrarHUD         = true;     // Mostrar Panel HUD
input int                InpHUD_X              = 15;       // Posicion X del Panel
input int                InpHUD_Y              = 25;       // Posicion Y del Panel
input ulong              InpMagicNumber        = 0;        // Magic (0 = Auto-Asignar Magic por Activo)

//============================================================
//  VARIABLES GLOBALES
//============================================================
CTrade         trade;
CPositionInfo  posInfo;
COrderInfo     orderInfo;

int            hRSI = INVALID_HANDLE;
int            hADX = INVALID_HANDLE;
int            hEMA_M15 = INVALID_HANDLE;
int            hSlowEMA = INVALID_HANDLE;
int            hEMA_Chart = INVALID_HANDLE;
int            hATR = INVALID_HANDLE;
int            hFractals = INVALID_HANDLE;

datetime       lastBarTime = 0;
int            lastDayDate = -1;

double         equityInicioDia = 0.0;
double         ganadoHoy = 0.0;
double         flotanteActual = 0.0;
bool           botActivo = true;
int            winsHoy = 0;
int            lossesHoy = 0;
double         rsiActualVal = 50.0;
double         adxActualVal = 0.0;
double         confianzaBayesianaUltima = 50.0;

ENUM_REGIMEN_MERCADO regimenActual = REGIMEN_LATERAL;

string         txtActivoDetectado = "";
string         txtEstadoCajero = "CAJERO OK";
string         txtVeredicto = "ESPERANDO INICIALIZACIÓN";

// Variables Efectivas de Calibración por Activo
int            rsiPeriodEfectivo = 14;
double         rsiOverboughtEfectivo = 70.0;
double         rsiOversoldEfectivo = 30.0;
double         minConfidenceEfectivo = 80.0;
double         distanciaCapasEfectiva = 35.0;
double         stopLossUSD_Efectivo = 25.0;
double         takeProfitUSD_Efectivo = 8.0;

bool           activarFiltroHorarioEfectivo = false;
int            horaInicioEfectivo = 0;
int            horaFinEfectivo = 24;

bool           operarLunesEfectivo = true;
bool           operarMartesEfectivo = true;
bool           operarMiercolesEfectivo = true;
bool           operarJuevesEfectivo = true;
bool           operarViernesEfectivo = true;
bool           operarSabadoEfectivo = true;
bool           operarDomingoEfectivo = true;

ulong          magicEfectivo = 888126;
ENUM_MODO_PRESET_ACTIVO presetModoActual = PRESET_AUTO;

// Estructura de Posiciones para Grid Unidireccional
struct StPosicion
{
    ulong    ticket;
    int      t;
    double   v;
    double   pr;
    datetime time;
    double   p;
    double   c;
    double   s;
};
StPosicion pos[];
double volTotal = 0.0;

// Variables de Control HUD Original
ENUM_TAB_HUD   tabActual = TAB_CONTROL;
bool           hudMinimizado = false;
bool           stateTrailing = true;
bool           stateBE = true;
bool           statePausado = false;
ENUM_PERFIL_RIESGO perfilActual = PERFIL_MANUAL;
int            maxCapasEfectivo = 10;
double         shieldPctEfectivo = 4.0;
bool           autoCalibracionActiva = true;

// Nombres de Botones HUD Original
#define BTN_MINIMIZE_NAME  "BAYES_BTN_MIN"
#define BTN_TAB_CTA        "BAYES_TAB_CTA"
#define BTN_TAB_INTEL      "BAYES_TAB_INTEL"
#define BTN_TAB_CFG        "BAYES_TAB_CFG"
#define BTN_TAB_CTRL       "BAYES_TAB_CTRL"
#define BTN_PROFILE_NAME   "BAYES_BTN_PROF"
#define BTN_AUTOCAL_NAME   "BAYES_BTN_AUTOCAL"
#define BTN_TRAIL_NAME     "BAYES_BTN_TRAIL"
#define BTN_BE_NAME        "BAYES_BTN_BE"
#define BTN_ASEG_NAME      "BAYES_BTN_ASEG"
#define BTN_CLOSE_NAME     "BAYES_BTN_CLOSE"
#define BTN_SHIELD_NAME    "BAYES_BTN_SHIELD"
#define BTN_PAUSE_NAME     "BAYES_BTN_PAUSE"

#define LINE_PREFIX        "BAYES_LINE_"

//+------------------------------------------------------------------+
//| Expert Initialization Function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    ObjectsDeleteAll(0, -1, OBJ_HLINE);
    ObjectsDeleteAll(0, LINE_PREFIX);
    for (int i = ObjectsTotal(0) - 1; i >= 0; i--)
    {
        string name = ObjectName(0, i);
        if (StringFind(name, "BAYES_LINE_") >= 0 || StringFind(name, "_GHOST") >= 0 || StringFind(name, "MAIKO_") >= 0 || StringFind(name, "SOS") >= 0)
        {
            ObjectDelete(0, name);
        }
    }
    presetModoActual = InpPresetActivo;

    CalibrarParametrosActivo();

    trade.SetExpertMagicNumber(magicEfectivo);
    trade.SetDeviationInPoints(10);
    trade.SetTypeFilling(ORDER_FILLING_FOK);

    // Handles de Indicadores Técnicos
    hSlowEMA   = iMA(_Symbol, InpTimeframeRef, 200, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_M15   = iMA(_Symbol, PERIOD_M15, 20, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_Chart = iMA(_Symbol, _Period, 200, 0, MODE_EMA, PRICE_CLOSE);
    hADX       = iADX(_Symbol, PERIOD_M5, 14);
    hATR       = iATR(_Symbol, _Period, 14);
    hFractals  = iFractals(_Symbol, _Period);

    if (hRSI == INVALID_HANDLE || hRSI == 0)
    {
        hRSI = iRSI(_Symbol, _Period, rsiPeriodEfectivo, PRICE_CLOSE);
    }

    if (hRSI == INVALID_HANDLE || hRSI == 0 || hSlowEMA == INVALID_HANDLE || hEMA_Chart == INVALID_HANDLE || hADX == INVALID_HANDLE)
    {
        Print("Error inicializando indicadores en v2.4.");
        return (INIT_FAILED);
    }

    SincronizarIndicadoresEnGrafico();
    AplicarPerfilRiesgo();

    // Reevaluación automática de salud de cuenta al actualizar parámetros
    ActualizarPosiciones();
    ActualizarFinanzasDiarias();
    double balInit = AccountInfoDouble(ACCOUNT_BALANCE);
    if (balInit > 0 && shieldPctEfectivo > 0)
    {
        double maxPerdidaUSD = balInit * (shieldPctEfectivo / 100.0);
        double perdidasHoyVal = ganadoHoy + (flotanteActual < 0 ? flotanteActual : 0);
        if (perdidasHoyVal > -maxPerdidaUSD)
        {
            botActivo = true;
            txtEstadoCajero = "🛡️ SHIELD ESTADO: CAJERO OK";
            txtVeredicto = "OPERATIVA NORMAL";
        }
    }

    if (InpMostrarHUD) RedibujarHUD();
    if (InpMostrarLineasEstructura) ActualizarLineasEstructura();

    Print("Bayesian Strategy Pro v2.4 Iniciado Correctamente. Magic: ", magicEfectivo, " Activo: ", txtActivoDetectado, " Shield: ", shieldPctEfectivo, "%");
    return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert Deinitialization Function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    DestruirHUD();
    ObjectsDeleteAll(0, LINE_PREFIX);
    
    if (hRSI != INVALID_HANDLE) IndicatorRelease(hRSI);
    if (hADX != INVALID_HANDLE) IndicatorRelease(hADX);
    if (hEMA_M15 != INVALID_HANDLE) IndicatorRelease(hEMA_M15);
    if (hSlowEMA != INVALID_HANDLE) IndicatorRelease(hSlowEMA);
    if (hEMA_Chart != INVALID_HANDLE) IndicatorRelease(hEMA_Chart);
    if (hATR != INVALID_HANDLE) IndicatorRelease(hATR);
    if (hFractals != INVALID_HANDLE) IndicatorRelease(hFractals);
}

//+------------------------------------------------------------------+
//| Auto-Calibración de Presets & Magic Number por Activo           |
//+------------------------------------------------------------------+
void CalibrarParametrosActivo()
{
    string sym = _Symbol;
    StringToUpper(sym);

    int prevRSIPeriod = rsiPeriodEfectivo;

    // 1. PRESET BITCOIN (BTCUSD) - OPERATIVA 100% 24/7 (00:00 - 24:00 LUNES A DOMINGO)
    if (presetModoActual == PRESET_FORZAR_BTC || (presetModoActual == PRESET_AUTO && StringFind(sym, "BTC") >= 0))
    {
        rsiPeriodEfectivo = 9;
        rsiOverboughtEfectivo = 65.0;
        rsiOversoldEfectivo = 35.0;
        minConfidenceEfectivo = 70.0;
        distanciaCapasEfectiva = 150.0;
        stopLossUSD_Efectivo = 30.0;
        takeProfitUSD_Efectivo = 10.0;
        activarFiltroHorarioEfectivo = false;
        horaInicioEfectivo = 0;
        horaFinEfectivo = 24;
        operarLunesEfectivo = true;
        operarMartesEfectivo = true;
        operarMiercolesEfectivo = true;
        operarJuevesEfectivo = true;
        operarViernesEfectivo = true;
        operarSabadoEfectivo = true;
        operarDomingoEfectivo = true;
        magicEfectivo = (InpMagicNumber > 0) ? InpMagicNumber : 888126;
        txtActivoDetectado = "BITCOIN (BTCUSD) 24/7" + (presetModoActual == PRESET_FORZAR_BTC ? " [FORZADO ⚙️]" : " [AUTO 🧠]");
    }
    // 2. PRESET ORO (XAUUSD)
    else if (presetModoActual == PRESET_FORZAR_ORO || (presetModoActual == PRESET_AUTO && (StringFind(sym, "XAU") >= 0 || StringFind(sym, "GOLD") >= 0)))
    {
        rsiPeriodEfectivo = 14;
        rsiOverboughtEfectivo = 70.0;
        rsiOversoldEfectivo = 28.0;
        minConfidenceEfectivo = 85.0;
        distanciaCapasEfectiva = 35.0;
        stopLossUSD_Efectivo = 25.0;
        takeProfitUSD_Efectivo = 8.0;
        activarFiltroHorarioEfectivo = true;
        horaInicioEfectivo = 9;
        horaFinEfectivo = 21;
        operarLunesEfectivo = true;
        operarMartesEfectivo = true;
        operarMiercolesEfectivo = true;
        operarJuevesEfectivo = true;
        operarViernesEfectivo = true;
        operarSabadoEfectivo = false;
        operarDomingoEfectivo = false;
        magicEfectivo = (InpMagicNumber > 0) ? InpMagicNumber : 888127;
        txtActivoDetectado = "ORO (XAUUSD)" + (presetModoActual == PRESET_FORZAR_ORO ? " [FORZADO ⚙️]" : " [AUTO 🧠]");
    }
    // 3. PRESET FOREX (EURUSD / GBPUSD)
    else if (presetModoActual == PRESET_FORZAR_EURUSD || (presetModoActual == PRESET_AUTO && (StringFind(sym, "EURUSD") >= 0 || StringFind(sym, "GBPUSD") >= 0)))
    {
        rsiPeriodEfectivo = 14;
        rsiOverboughtEfectivo = 70.0;
        rsiOversoldEfectivo = 30.0;
        minConfidenceEfectivo = 80.0;
        distanciaCapasEfectiva = 25.0;
        stopLossUSD_Efectivo = 20.0;
        takeProfitUSD_Efectivo = 4.0; // Take Profit ágil de $4.00 USD en Forex
        activarFiltroHorarioEfectivo = true;
        horaInicioEfectivo = 9;
        horaFinEfectivo = 21;
        operarLunesEfectivo = true;
        operarMartesEfectivo = true;
        operarMiercolesEfectivo = true;
        operarJuevesEfectivo = true;
        operarViernesEfectivo = true;
        operarSabadoEfectivo = false;
        operarDomingoEfectivo = false;
        magicEfectivo = (InpMagicNumber > 0) ? InpMagicNumber : 888128;
        txtActivoDetectado = "FOREX " + sym + (presetModoActual == PRESET_FORZAR_EURUSD ? " [FORZADO ⚙️]" : " [AUTO 🧠]");
    }
    // 4. PRESET INDICE S&P 500 (US500 / SP500 / SPX500)
    else if (presetModoActual == PRESET_FORZAR_SP500 || (presetModoActual == PRESET_AUTO && (StringFind(sym, "US500") >= 0 || StringFind(sym, "SPX") >= 0 || StringFind(sym, "SP500") >= 0)))
    {
        rsiPeriodEfectivo = 14;
        rsiOverboughtEfectivo = 70.0;
        rsiOversoldEfectivo = 35.0;
        minConfidenceEfectivo = 80.0;
        distanciaCapasEfectiva = 150.0;
        stopLossUSD_Efectivo = 25.0;
        takeProfitUSD_Efectivo = 8.0;
        activarFiltroHorarioEfectivo = true;
        horaInicioEfectivo = 15;
        horaFinEfectivo = 22;
        operarLunesEfectivo = true;
        operarMartesEfectivo = true;
        operarMiercolesEfectivo = true;
        operarJuevesEfectivo = true;
        operarViernesEfectivo = true;
        operarSabadoEfectivo = false;
        operarDomingoEfectivo = false;
        magicEfectivo = (InpMagicNumber > 0) ? InpMagicNumber : 888129;
        txtActivoDetectado = "INDICE S&P 500 (" + sym + ")" + (presetModoActual == PRESET_FORZAR_SP500 ? " [FORZADO ⚙️]" : " [AUTO 🧠]");
    }
    // 5. MODO MANUAL
    else
    {
        rsiPeriodEfectivo = InpRSIPeriod;
        rsiOverboughtEfectivo = InpRSIOverbought;
        rsiOversoldEfectivo = InpRSIOversold;
        minConfidenceEfectivo = InpMinConfidence;
        distanciaCapasEfectiva = InpDistanciaCapasPips;
        stopLossUSD_Efectivo = InpStopLoss_USD;
        takeProfitUSD_Efectivo = InpTakeProfit_USD;
        activarFiltroHorarioEfectivo = InpActivarFiltroHorario;
        horaInicioEfectivo = InpHoraInicio;
        horaFinEfectivo = InpHoraFin;
        operarLunesEfectivo = InpOperarLunes;
        operarMartesEfectivo = InpOperarMartes;
        operarMiercolesEfectivo = InpOperarMiercoles;
        operarJuevesEfectivo = InpOperarJueves;
        operarViernesEfectivo = InpOperarViernes;
        operarSabadoEfectivo = InpOperarSabado;
        operarDomingoEfectivo = InpOperarDomingo;
        magicEfectivo = (InpMagicNumber > 0) ? InpMagicNumber : 888125;
        txtActivoDetectado = "MANUAL " + sym + " [PERSONALIZADO 🛠️]";
    }

    if (prevRSIPeriod != rsiPeriodEfectivo || hRSI == INVALID_HANDLE)
    {
        if (hRSI != INVALID_HANDLE) IndicatorRelease(hRSI);
        hRSI = iRSI(_Symbol, _Period, rsiPeriodEfectivo, PRICE_CLOSE);
        if (hEMA_Chart != INVALID_HANDLE) SincronizarIndicadoresEnGrafico();
    }
}

//+------------------------------------------------------------------+
//| Sincronizar e Insertar Indicadores Oficiales (RSI + EMA 200 H1) |
//+------------------------------------------------------------------+
void SincronizarIndicadoresEnGrafico()
{
    int totalVentanas = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL);
    bool tieneRSI = false;
    bool cambioHecho = false;

    for (int w = 0; w < totalVentanas; w++)
    {
        int totalInd = ChartIndicatorsTotal(0, w);
        for (int i = 0; i < totalInd; i++)
        {
            string name = ChartIndicatorName(0, w, i);
            if (StringFind(name, "RSI") >= 0 || StringFind(name, "Relative Strength Index") >= 0)
            {
                tieneRSI = true;
                break;
            }
        }
        if (tieneRSI) break;
    }

    if (!tieneRSI)
    {
        if (hRSI == INVALID_HANDLE || hRSI == 0)
        {
            hRSI = iRSI(_Symbol, _Period, rsiPeriodEfectivo, PRICE_CLOSE);
        }
        if (hRSI != INVALID_HANDLE && hRSI != 0)
        {
            ChartIndicatorAdd(0, 1, hRSI);
            cambioHecho = true;
        }
    }

    bool tieneEMA = false;
    int totalMain = ChartIndicatorsTotal(0, 0);
    for (int i = 0; i < totalMain; i++)
    {
        string name = ChartIndicatorName(0, 0, i);
        if (StringFind(name, "Moving Average") >= 0 || StringFind(name, "MA") >= 0)
        {
            tieneEMA = true;
            break;
        }
    }

    if (InpFiltroTendencia != TENDENCIA_OFF && !tieneEMA)
    {
        int handleParaGrafico = (InpTimeframeRef == _Period) ? hSlowEMA : hEMA_Chart;
        if (handleParaGrafico != INVALID_HANDLE && handleParaGrafico != 0)
        {
            ChartIndicatorAdd(0, 0, handleParaGrafico);
            cambioHecho = true;
        }
    }

    if (cambioHecho)
    {
        ChartRedraw(0);
    }
}

//+------------------------------------------------------------------+
//| Asegurar visualización continua de indicadores                  |
//+------------------------------------------------------------------+
void AsegurarIndicadoresEnGrafico()
{
    static datetime lastSyncTime = 0;
    datetime now = TimeCurrent();

    if (now - lastSyncTime >= 5 || lastSyncTime == 0)
    {
        lastSyncTime = now;
        SincronizarIndicadoresEnGrafico();
    }
}

//+------------------------------------------------------------------+
//| Detección de Régimen de Mercado (ADX + Histéresis 22-25 + MTF)   |
//+------------------------------------------------------------------+
void EvaluacionRegimenMercado()
{
    double adxBuf[];
    ArraySetAsSeries(adxBuf, true);
    if (CopyBuffer(hADX, 0, 0, 1, adxBuf) > 0)
    {
        adxActualVal = adxBuf[0];
    }

    double emaH1[];
    ArraySetAsSeries(emaH1, true);
    CopyBuffer(hSlowEMA, 0, 0, 1, emaH1);

    double emaM15[];
    ArraySetAsSeries(emaM15, true);
    CopyBuffer(hEMA_M15, 0, 0, 1, emaM15);

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    // Histéresis cuantitativa 22.0 - 25.0
    if (regimenActual == REGIMEN_LATERAL)
    {
        if (adxActualVal >= 25.0)
        {
            if (ask > emaH1[0] && ask > emaM15[0])
            {
                regimenActual = REGIMEN_ALCISTA;
            }
            else if (bid < emaH1[0] && bid < emaM15[0])
            {
                regimenActual = REGIMEN_BAJISTA;
            }
        }
    }
    else
    {
        if (adxActualVal < 22.0)
        {
            regimenActual = REGIMEN_LATERAL;
        }
        else if (regimenActual == REGIMEN_ALCISTA && (bid < emaH1[0] || bid < emaM15[0]))
        {
            regimenActual = REGIMEN_LATERAL;
        }
        else if (regimenActual == REGIMEN_BAJISTA && (ask > emaH1[0] || ask > emaM15[0]))
        {
            regimenActual = REGIMEN_LATERAL;
        }
    }
}

//+------------------------------------------------------------------+
//| Aplicar Perfil de Riesgo Preconfigurado                         |
//+------------------------------------------------------------------+
void AplicarPerfilRiesgo()
{
    if (InpPerfilRiesgo == PERFIL_MANUAL)
    {
        maxCapasEfectivo = InpMaxCapasManual;
        shieldPctEfectivo = InpShieldPctManual;
        return;
    }

    if (InpPerfilRiesgo == PERFIL_CONSERVADOR)
    {
        maxCapasEfectivo = 6;
        shieldPctEfectivo = 3.0;
    }
    else if (InpPerfilRiesgo == PERFIL_BALANCEADO)
    {
        maxCapasEfectivo = 10;
        shieldPctEfectivo = 4.0;
    }
    else if (InpPerfilRiesgo == PERFIL_AGRESIVO)
    {
        maxCapasEfectivo = 15;
        shieldPctEfectivo = 6.0;
    }
}

//+------------------------------------------------------------------+
//| OnTick Function                                                  |
//+------------------------------------------------------------------+
void OnTick()
{
    AsegurarIndicadoresEnGrafico();
    ActualizarPosiciones();
    ActualizarFinanzasDiarias();
    EvaluacionRegimenMercado();

    if (InpActivarShield && ValidarShieldDiario())
    {
        if (InpMostrarHUD) ActualizarValoresHUD();
        return;
    }

    if (InpActivarBE) GestionarBreakEven();
    if (InpActivarTrailing) GestionarTrailingStop();

    if (hRSI == INVALID_HANDLE || hRSI == 0)
    {
        hRSI = iRSI(_Symbol, _Period, rsiPeriodEfectivo, PRICE_CLOSE);
    }
    if (hRSI != INVALID_HANDLE && hRSI != 0)
    {
        double rsiLive[];
        ArraySetAsSeries(rsiLive, true);
        if (CopyBuffer(hRSI, 0, 0, 1, rsiLive) > 0)
        {
            if (rsiLive[0] >= 0.0 && rsiLive[0] <= 100.0)
            {
                rsiActualVal = rsiLive[0];
            }
        }
    }

    if (InpMostrarLineasEstructura) ActualizarLineasEstructura();

    datetime currentBarTime = iTime(_Symbol, _Period, 0);
    if (currentBarTime == lastBarTime)
    {
        if (InpMostrarHUD) ActualizarValoresHUD();
        return;
    }
    lastBarTime = currentBarTime;

    if (InpMostrarHUD) RedibujarHUD();

    if (statePausado)
    {
        txtVeredicto = "OPERATIVA PAUSADA DESDE PANEL";
        if (InpMostrarHUD) ActualizarValoresHUD();
        return;
    }

    if (!botActivo) return;

    if (!EsHoraOperativa())
    {
        txtVeredicto = "FUERA DE HORARIO OPERATIVO (" + IntegerToString(horaInicioEfectivo) + ":00 - " + IntegerToString(horaFinEfectivo) + ":00)";
        if (InpMostrarHUD) ActualizarValoresHUD();
        return;
    }

    int dirCesta = ObtenerDireccionCesta();
    int totalPos = ArraySize(pos);

    if (totalPos == 0)
    {
        double confidence = 0.0;
        int bayesDir = CalcularInferenciaBayesiana(confidence);
        confianzaBayesianaUltima = confidence;

        if (bayesDir == 0 || confidence < minConfidenceEfectivo)
        {
            txtVeredicto = "ESPERANDO CONFIRMACIÓN (" + DoubleToString(confidence, 1) + "% / " + DoubleToString(minConfidenceEfectivo, 1) + "%)";
            if (InpMostrarHUD) ActualizarValoresHUD();
            return;
        }

        // Filtro de Tendencia / Régimen ADX (v2.4)
        if (InpFiltroTendencia == TENDENCIA_REGIMEN_AUTO_ADX)
        {
            if (regimenActual == REGIMEN_ALCISTA && bayesDir == -1)
            {
                txtVeredicto = "VENTA BLOQUEADA (TENDENCIA ALCISTA ADX " + DoubleToString(adxActualVal, 1) + ")";
                if (InpMostrarHUD) ActualizarValoresHUD();
                return;
            }
            if (regimenActual == REGIMEN_BAJISTA && bayesDir == 1)
            {
                txtVeredicto = "COMPRA BLOQUEADA (TENDENCIA BAJISTA ADX " + DoubleToString(adxActualVal, 1) + ")";
                if (InpMostrarHUD) ActualizarValoresHUD();
                return;
            }
        }
        else if (InpFiltroTendencia == TENDENCIA_EMA200_STRICT)
        {
            double emaVal[];
            ArraySetAsSeries(emaVal, true);
            if (CopyBuffer(hSlowEMA, 0, 0, 1, emaVal) > 0)
            {
                double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                if (bayesDir == 1 && currentAsk < emaVal[0])
                {
                    txtVeredicto = "COMPRA BLOQUEADA POR FILTRO EMA200 H1";
                    if (InpMostrarHUD) ActualizarValoresHUD();
                    return;
                }
                if (bayesDir == -1 && currentBid > emaVal[0])
                {
                    txtVeredicto = "VENTA BLOQUEADA POR FILTRO EMA200 H1";
                    if (InpMostrarHUD) ActualizarValoresHUD();
                    return;
                }
            }
        }

        if (bayesDir == 1) AbrirCapa(POSITION_TYPE_BUY, InpLoteBase, "Bayes_C1_BUY");
        else if (bayesDir == -1) AbrirCapa(POSITION_TYPE_SELL, InpLoteBase, "Bayes_C1_SELL");
    }
    else if (totalPos > 0 && totalPos < maxCapasEfectivo)
    {
        if (EsMomentoNuevaCapa(dirCesta))
        {
            double loteCapa = InpLoteBase;
            if (dirCesta == POSITION_TYPE_BUY)
            {
                AbrirCapa(POSITION_TYPE_BUY, loteCapa, StringFormat("Bayes_C%d_BUY", totalPos + 1));
            }
            else if (dirCesta == POSITION_TYPE_SELL)
            {
                AbrirCapa(POSITION_TYPE_SELL, loteCapa, StringFormat("Bayes_C%d_SELL", totalPos + 1));
            }
        }
    }
    else if (totalPos >= maxCapasEfectivo)
    {
        txtVeredicto = StringFormat("MÁXIMO DE CAPAS ALCANZADO (%d/%d)", totalPos, maxCapasEfectivo);
    }

    GestionarSalidasCesta();
    if (InpMostrarHUD) ActualizarValoresHUD();
}

//+------------------------------------------------------------------+
//| Obtener Dirección de la Cesta Activa                             |
//+------------------------------------------------------------------+
int ObtenerDireccionCesta()
{
    if (ArraySize(pos) == 0) return -1;
    return pos[0].t;
}

//+------------------------------------------------------------------+
//| Validar Distancia para Nueva Capa (Unidireccional)              |
//+------------------------------------------------------------------+
bool EsMomentoNuevaCapa(int direction)
{
    double ultimaPrecio = 0.0;
    datetime ultimaHora = 0;

    int totalPos = ArraySize(pos);
    for (int i = 0; i < totalPos; i++)
    {
        if (pos[i].time > ultimaHora)
        {
            ultimaHora = pos[i].time;
            ultimaPrecio = pos[i].pr;
        }
    }

    if (ultimaPrecio <= 0) return false;

    double actualPrice = (direction == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double pipsDiff = MathAbs(actualPrice - ultimaPrecio) / (_Point * 10.0);

    return (pipsDiff >= distanciaCapasEfectiva);
}

//+------------------------------------------------------------------+
//| Abrir Capa                                                       |
//+------------------------------------------------------------------+
void AbrirCapa(ENUM_POSITION_TYPE dir, double lotes, string comentario)
{
    double price = (dir == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
    if (dir == POSITION_TYPE_BUY)
    {
        trade.Buy(lotes, _Symbol, price, 0, 0, comentario);
    }
    else
    {
        trade.Sell(lotes, _Symbol, price, 0, 0, comentario);
    }
}

//+------------------------------------------------------------------+
//| Inferencia Bayesiana RSI                                        |
//+------------------------------------------------------------------+
int CalcularInferenciaBayesiana(double &confidence)
{
    double rsiBuffer[];
    ArraySetAsSeries(rsiBuffer, true);
    if (CopyBuffer(hRSI, 0, 1, 3, rsiBuffer) < 3) return 0;

    double rsiCurr = rsiBuffer[0];
    double rsiPrev = rsiBuffer[1];

    double priorBuy = 0.50;
    double priorSell = 0.50;

    double pSignalGivenBuy = 0.50;
    double pSignalGivenSell = 0.50;

    if (rsiCurr < rsiOversoldEfectivo)
    {
        pSignalGivenBuy = 0.88;
        pSignalGivenSell = 0.12;
    }
    else if (rsiCurr > rsiOverboughtEfectivo)
    {
        pSignalGivenBuy = 0.12;
        pSignalGivenSell = 0.88;
    }
    else
    {
        if (rsiCurr > rsiPrev && rsiCurr < 50.0)
        {
            pSignalGivenBuy = 0.72;
            pSignalGivenSell = 0.28;
        }
        else if (rsiCurr < rsiPrev && rsiCurr > 50.0)
        {
            pSignalGivenBuy = 0.28;
            pSignalGivenSell = 0.72;
        }
    }

    double pEvidence = (pSignalGivenBuy * priorBuy) + (pSignalGivenSell * priorSell);
    if (pEvidence <= 0) return 0;

    double posteriorBuy = (pSignalGivenBuy * priorBuy) / pEvidence;
    double posteriorSell = (pSignalGivenSell * priorSell) / pEvidence;

    if (posteriorBuy > posteriorSell)
    {
        confidence = posteriorBuy * 100.0;
        return 1;
    }
    else if (posteriorSell > posteriorBuy)
    {
        confidence = posteriorSell * 100.0;
        return -1;
    }

    confidence = 50.0;
    return 0;
}

//+------------------------------------------------------------------+
//| Gestión de Cierre Global en Cesta (TP Adaptativo / Escape)       |
//+------------------------------------------------------------------+
void GestionarSalidasCesta()
{
    int totalPos = ArraySize(pos);
    if (totalPos == 0) return;

    double targetEfectivoUSD = takeProfitUSD_Efectivo;
    if (totalPos >= 8)
    {
        targetEfectivoUSD = 1.50;
    }
    else if (totalPos >= 5)
    {
        targetEfectivoUSD = takeProfitUSD_Efectivo * 0.5;
    }

    if (flotanteActual >= targetEfectivoUSD)
    {
        CerrarTodasLasPosiciones(StringFormat("TakeProfit Cesta Alcanzado ($%.2f USD | Meta: $%.2f)", flotanteActual, targetEfectivoUSD));
        return;
    }

    if (stopLossUSD_Efectivo > 0 && flotanteActual <= -stopLossUSD_Efectivo)
    {
        CerrarTodasLasPosiciones("StopLoss Cesta Alcanzado (-$" + DoubleToString(MathAbs(flotanteActual), 2) + ")");
        return;
    }
}

//+------------------------------------------------------------------+
//| Gestión BreakEven Inteligente (Adaptativa por Activo)            |
//+------------------------------------------------------------------+
void GestionarBreakEven()
{
    if (!stateBE) return;

    string sym = _Symbol;
    StringToUpper(sym);

    double minProfitUSD = 1.50;
    double offsetPuntos = 50.0;

    if (StringFind(sym, "BTC") >= 0)
    {
        minProfitUSD = 1.50;
        offsetPuntos = 50.0;
    }
    else if (StringFind(sym, "XAU") >= 0 || StringFind(sym, "GOLD") >= 0)
    {
        minProfitUSD = 2.00;
        offsetPuntos = 20.0;
    }
    else
    {
        minProfitUSD = 1.00;
        offsetPuntos = 10.0;
    }

    int total = PositionsTotal();
    for (int i = 0; i < total; i++)
    {
        if (posInfo.SelectByIndex(i))
        {
            if (posInfo.Symbol() == _Symbol && posInfo.Magic() == magicEfectivo)
            {
                double openPrice = posInfo.PriceOpen();
                double sl = posInfo.StopLoss();
                double tp = posInfo.TakeProfit();
                double profit = posInfo.Profit() + posInfo.Commission() + posInfo.Swap();

                if (profit >= minProfitUSD)
                {
                    if (posInfo.PositionType() == POSITION_TYPE_BUY)
                    {
                        double newSL = NormalizeDouble(openPrice + (offsetPuntos * _Point), _Digits);
                        if (sl < openPrice) trade.PositionModify(posInfo.Ticket(), newSL, tp);
                    }
                    else if (posInfo.PositionType() == POSITION_TYPE_SELL)
                    {
                        double newSL = NormalizeDouble(openPrice - (offsetPuntos * _Point), _Digits);
                        if (sl > openPrice || sl == 0) trade.PositionModify(posInfo.Ticket(), newSL, tp);
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Gestión Trailing Stop Dinámico (Adaptativo por Activo)           |
//+------------------------------------------------------------------+
void GestionarTrailingStop()
{
    if (!stateTrailing) return;

    int total = PositionsTotal();
    for (int i = 0; i < total; i++)
    {
        if (posInfo.SelectByIndex(i))
        {
            if (posInfo.Symbol() == _Symbol && posInfo.Magic() == magicEfectivo)
            {
                double profit = posInfo.Profit() + posInfo.Commission() + posInfo.Swap();
                if (profit > (InpTrailingStepUSD * 2.0))
                {
                    double openPrice = posInfo.PriceOpen();
                    double currentPrice = posInfo.PriceCurrent();
                    double sl = posInfo.StopLoss();
                    double tp = posInfo.TakeProfit();

                    if (posInfo.PositionType() == POSITION_TYPE_BUY)
                    {
                        double newSL = NormalizeDouble(currentPrice - ((currentPrice - openPrice) * 0.5), _Digits);
                        if (newSL > sl) trade.PositionModify(posInfo.Ticket(), newSL, tp);
                    }
                    else if (posInfo.PositionType() == POSITION_TYPE_SELL)
                    {
                        double newSL = NormalizeDouble(currentPrice + ((openPrice - currentPrice) * 0.5), _Digits);
                        if (sl == 0 || newSL < sl) trade.PositionModify(posInfo.Ticket(), newSL, tp);
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Ejecutar Asegurar Ganancias (Adaptativo por Activo)               |
//+------------------------------------------------------------------+
void EjecutarAsegurarGanancias()
{
    int total = PositionsTotal();
    if (total == 0) return;

    string sym = _Symbol;
    StringToUpper(sym);

    double pipsProtect = 10.0;
    if (StringFind(sym, "BTC") >= 0) pipsProtect = 50.0;
    else if (StringFind(sym, "XAU") >= 0 || StringFind(sym, "GOLD") >= 0) pipsProtect = 20.0;

    double offsetPuntos = pipsProtect * _Point;

    for (int i = 0; i < total; i++)
    {
        if (posInfo.SelectByIndex(i))
        {
            if (posInfo.Symbol() == _Symbol)
            {
                double openPrice = posInfo.PriceOpen();
                double currentPrice = posInfo.PriceCurrent();
                double tp = posInfo.TakeProfit();
                double sl = posInfo.StopLoss();
                double profit = posInfo.Profit() + posInfo.Commission() + posInfo.Swap();

                if (profit > 0)
                {
                    if (posInfo.PositionType() == POSITION_TYPE_BUY && currentPrice > (openPrice + offsetPuntos))
                    {
                        double newSL = NormalizeDouble(openPrice + offsetPuntos, _Digits);
                        if (newSL > sl) trade.PositionModify(posInfo.Ticket(), newSL, tp);
                    }
                    else if (posInfo.PositionType() == POSITION_TYPE_SELL && currentPrice < (openPrice - offsetPuntos))
                    {
                        double newSL = NormalizeDouble(openPrice - offsetPuntos, _Digits);
                        if (sl == 0 || newSL < sl) trade.PositionModify(posInfo.Ticket(), newSL, tp);
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Validación Filtro Horario y Días                                |
//+------------------------------------------------------------------+
bool EsHoraOperativa()
{
    MqlDateTime dt;
    TimeCurrent(dt);

    if (dt.day_of_week == 1 && !operarLunesEfectivo) return false;
    if (dt.day_of_week == 2 && !operarMartesEfectivo) return false;
    if (dt.day_of_week == 3 && !operarMiercolesEfectivo) return false;
    if (dt.day_of_week == 4 && !operarJuevesEfectivo) return false;
    if (dt.day_of_week == 5 && !operarViernesEfectivo) return false;
    if (dt.day_of_week == 6 && !operarSabadoEfectivo) return false;
    if (dt.day_of_week == 0 && !operarDomingoEfectivo) return false;

    if (activarFiltroHorarioEfectivo)
    {
        if (horaInicioEfectivo < horaFinEfectivo)
        {
            if (dt.hour < horaInicioEfectivo || dt.hour >= horaFinEfectivo) return false;
        }
        else
        {
            if (dt.hour < horaInicioEfectivo && dt.hour >= horaFinEfectivo) return false;
        }
    }

    return true;
}

//+------------------------------------------------------------------+
//| Cierre masivo de posiciones                                     |
//+------------------------------------------------------------------+
void CerrarTodasLasPosiciones(string razon)
{
    Print("Cerrando Cesta: ", razon);
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (posInfo.SelectByIndex(i))
        {
            if (posInfo.Symbol() == _Symbol && posInfo.Magic() == magicEfectivo)
            {
                trade.PositionClose(posInfo.Ticket());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Actualizar Array de Posiciones Activas                           |
//+------------------------------------------------------------------+
void ActualizarPosiciones()
{
    ArrayResize(pos, 0);
    volTotal = 0.0;
    flotanteActual = 0.0;

    for (int i = 0; i < PositionsTotal(); i++)
    {
        if (posInfo.SelectByIndex(i))
        {
            if (posInfo.Symbol() == _Symbol && posInfo.Magic() == magicEfectivo)
            {
                int sz = ArraySize(pos);
                ArrayResize(pos, sz + 1);
                pos[sz].ticket = posInfo.Ticket();
                pos[sz].t = (int)posInfo.PositionType();
                pos[sz].v = posInfo.Volume();
                pos[sz].pr = posInfo.PriceOpen();
                pos[sz].time = posInfo.Time();
                pos[sz].p = posInfo.Profit();
                pos[sz].c = posInfo.Commission();
                pos[sz].s = posInfo.Swap();

                volTotal += pos[sz].v;
                flotanteActual += (pos[sz].p + pos[sz].c + pos[sz].s);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Finanzas Diarias & Shield                                        |
//+------------------------------------------------------------------+
void ActualizarFinanzasDiarias()
{
    MqlDateTime dt;
    TimeCurrent(dt);
    datetime hoy = StringToTime(IntegerToString(dt.year) + "." + IntegerToString(dt.mon) + "." + IntegerToString(dt.day));

    if (lastDayDate != (int)dt.day)
    {
        lastDayDate = dt.day;
        equityInicioDia = AccountInfoDouble(ACCOUNT_BALANCE);
        botActivo = true;
        txtEstadoCajero = "🛡️ SHIELD ESTADO: CAJERO OK";
        txtVeredicto = "OPERATIVA NORMAL";
    }

    ganadoHoy = 0.0;
    winsHoy = 0;
    lossesHoy = 0;
    HistorySelect(hoy, TimeCurrent());
    for (int i = HistoryDealsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = HistoryDealGetTicket(i);
        if (HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol && HistoryDealGetInteger(ticket, DEAL_MAGIC) == magicEfectivo)
        {
            double p = HistoryDealGetDouble(ticket, DEAL_PROFIT) + HistoryDealGetDouble(ticket, DEAL_COMMISSION) + HistoryDealGetDouble(ticket, DEAL_SWAP);
            ganadoHoy += p;
            if (p > 0) winsHoy++;
            else if (p < 0) lossesHoy++;
        }
    }
}

//+------------------------------------------------------------------+
//| Validar Escudo Diario (Shield)                                   |
//+------------------------------------------------------------------+
bool ValidarShieldDiario()
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    if (balance <= 0) return false;

    double maxPerdidaPermitidaUSD = balance * (shieldPctEfectivo / 100.0);
    double perdidasHoy = ganadoHoy + (flotanteActual < 0 ? flotanteActual : 0);

    if (perdidasHoy <= -maxPerdidaPermitidaUSD)
    {
        CerrarTodasLasPosiciones("ESCUDO DIARIO ACTIVADO (-" + DoubleToString(shieldPctEfectivo, 1) + "%)");
        botActivo = false;
        txtEstadoCajero = "🛑 SHIELD ACTIVADO (-" + DoubleToString(shieldPctEfectivo, 1) + "%)";
        txtVeredicto = "CORTAFUEGOS: PÉRDIDA MÁXIMA ALCANZADA HOY";
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Dibuja Marquitas Amarillas de Estructura (Original Fractals v2.2)|
//+------------------------------------------------------------------+
void ActualizarLineasEstructura()
{
    if (!InpMostrarLineasEstructura)
    {
        ObjectsDeleteAll(0, LINE_PREFIX);
        return;
    }

    double upperFractals[], lowerFractals[];
    ArraySetAsSeries(upperFractals, true);
    ArraySetAsSeries(lowerFractals, true);

    int count = MathMax(InpPeriodoEstructura * 4, 60);
    if (CopyBuffer(hFractals, 0, 0, count, upperFractals) <= 0) return;
    if (CopyBuffer(hFractals, 1, 0, count, lowerFractals) <= 0) return;

    datetime timeBuf[];
    ArraySetAsSeries(timeBuf, true);
    CopyTime(_Symbol, _Period, 0, count, timeBuf);

    int lineIdx = 0;

    for (int i = 2; i < count - 2 && lineIdx < 30; i++)
    {
        if (upperFractals[i] != EMPTY_VALUE && upperFractals[i] > 0)
        {
            string name = LINE_PREFIX + "HIGH_" + IntegerToString(i);
            double price = upperFractals[i];
            datetime startTime = timeBuf[i + 1];
            datetime endTime = timeBuf[i - 1];

            ObjectCreate(0, name, OBJ_TREND, 0, startTime, price, endTime, price);
            ObjectSetInteger(0, name, OBJPROP_COLOR, InpColorEstructura);
            ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
            ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
            lineIdx++;
        }

        if (lowerFractals[i] != EMPTY_VALUE && lowerFractals[i] > 0)
        {
            string name = LINE_PREFIX + "LOW_" + IntegerToString(i);
            double price = lowerFractals[i];
            datetime startTime = timeBuf[i + 1];
            datetime endTime = timeBuf[i - 1];

            ObjectCreate(0, name, OBJ_TREND, 0, startTime, price, endTime, price);
            ObjectSetInteger(0, name, OBJPROP_COLOR, InpColorEstructura);
            ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
            ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
            lineIdx++;
        }
    }
}

//+------------------------------------------------------------------+
//| OnChartEvent Function (HUD Interactivo Original)                 |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    if (id == CHARTEVENT_OBJECT_CLICK)
    {
        if (sparam == BTN_TAB_CTA) { tabActual = TAB_CUENTA; RedibujarHUD(); }
        else if (sparam == BTN_TAB_INTEL) { tabActual = TAB_INTEL; RedibujarHUD(); }
        else if (sparam == BTN_TAB_CFG) { tabActual = TAB_CFG; RedibujarHUD(); }
        else if (sparam == BTN_TAB_CTRL) { tabActual = TAB_CONTROL; RedibujarHUD(); }
        else if (sparam == BTN_MINIMIZE_NAME) { hudMinimizado = !hudMinimizado; RedibujarHUD(); }
        else if (sparam == BTN_PROFILE_NAME)
        {
            if (perfilActual == PERFIL_MANUAL) perfilActual = PERFIL_CONSERVADOR;
            else if (perfilActual == PERFIL_CONSERVADOR) perfilActual = PERFIL_BALANCEADO;
            else if (perfilActual == PERFIL_BALANCEADO) perfilActual = PERFIL_AGRESIVO;
            else perfilActual = PERFIL_MANUAL;
            AplicarPerfilRiesgo();
            RedibujarHUD();
        }
        else if (sparam == BTN_AUTOCAL_NAME)
        {
            autoCalibracionActiva = !autoCalibracionActiva;
            CalibrarParametrosActivo();
            RedibujarHUD();
        }
        else if (sparam == BTN_TRAIL_NAME) { stateTrailing = !stateTrailing; RedibujarHUD(); }
        else if (sparam == BTN_BE_NAME) { stateBE = !stateBE; RedibujarHUD(); }
        else if (sparam == BTN_ASEG_NAME)
        {
            EjecutarAsegurarGanancias();
            RedibujarHUD();
        }
        else if (sparam == BTN_PAUSE_NAME) { statePausado = !statePausado; RedibujarHUD(); }
        else if (sparam == BTN_CLOSE_NAME)
        {
            CerrarTodasLasPosiciones("CERRADO MANUAL DESDE HUD");
            txtVeredicto = "CERRADO MANUAL DESDE HUD";
            RedibujarHUD();
        }
    }
}

//+------------------------------------------------------------------+
//| Creación de Panel Visual HUD Compacto v2.4                      |
//+------------------------------------------------------------------+
void RedibujarHUD()
{
    DestruirHUD();
    CrearHUD();
    ActualizarValoresHUD();
}

void CrearHUD()
{
    int x = InpHUD_X;
    int y = InpHUD_Y;

    if (hudMinimizado)
    {
        ObjectCreate(0, "BAYES_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
        ObjectSetInteger(0, "BAYES_BG", OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, "BAYES_BG", OBJPROP_YDISTANCE, y);
        ObjectSetInteger(0, "BAYES_BG", OBJPROP_XSIZE, 220);
        ObjectSetInteger(0, "BAYES_BG", OBJPROP_YSIZE, 30);
        ObjectSetInteger(0, "BAYES_BG", OBJPROP_BGCOLOR, C'14,18,28');
        ObjectSetInteger(0, "BAYES_BG", OBJPROP_BORDER_COLOR, clrGold);
        ObjectSetInteger(0, "BAYES_BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);

        CrearLabel("BAYES_LBL_TITLE", "BAYES v2.4", x + 10, y + 7, clrGold, 10, true);
        CrearBoton(BTN_MINIMIZE_NAME, "[+]", x + 185, y + 5, 25, 20, C'30,40,60');
        return;
    }

    ObjectCreate(0, "BAYES_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_XSIZE, 420);
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_YSIZE, 260);
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_BGCOLOR, C'14,18,28');
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_BORDER_COLOR, C'40,50,70');
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);

    // Botones de Pestañas
    CrearBoton(BTN_TAB_CTA, "CTA", x + 10, y + 10, 40, 22, (tabActual == TAB_CUENTA ? C'60,80,120' : C'25,32,48'));
    CrearBoton(BTN_TAB_INTEL, "INTEL", x + 55, y + 10, 48, 22, (tabActual == TAB_INTEL ? C'60,80,120' : C'25,32,48'));
    CrearBoton(BTN_TAB_CFG, "CFG", x + 108, y + 10, 40, 22, (tabActual == TAB_CFG ? C'60,80,120' : C'25,32,48'));
    CrearBoton(BTN_TAB_CTRL, "CONTROL", x + 153, y + 10, 72, 22, (tabActual == TAB_CONTROL ? C'180,130,20' : C'25,32,48'));
    CrearBoton(BTN_MINIMIZE_NAME, "[  ]", x + 360, y + 10, 50, 22, C'120,40,40');

    // Filas de Texto de Información
    CrearLabel("BAYES_LBL_TITLE", "CONTROL OPERATIVO v2.4", x + 10, y + 40, clrGold, 9, true);
    CrearLabel("BAYES_LBL_EQ", "EQUITY: $0.00", x + 10, y + 58, clrCyan, 9, true);
    CrearLabel("BAYES_LBL_BAL", "BALANCE: $0.00 | HOY: $0.00", x + 10, y + 74, clrWhite, 8, false);
    CrearLabel("BAYES_LBL_CAPAS", "CAPAS ABIERTAS: 0 / 10", x + 10, y + 90, clrYellow, 8, true);
    CrearLabel("BAYES_LBL_ACTIVO", "ACTIVO: DETECTANDO...", x + 10, y + 106, clrWhite, 8, false);
    CrearLabel("BAYES_LBL_RSI", "RSI (14): 50.0", x + 10, y + 122, clrCyan, 8, false);
    CrearLabel("BAYES_LBL_CONF", "CONFIANZA BAYES: 50.0%", x + 10, y + 138, clrLime, 8, true);
    CrearLabel("BAYES_LBL_SHIELD", "REGIMEN: DETECTANDO...", x + 10, y + 154, clrOrange, 8, true);
    CrearLabel("BAYES_LBL_VEREDICT", "OPERATIVA: INICIALIZANDO...", x + 10, y + 170, clrYellow, 8, true);

    // Botones Rápidos Interactivos (Fila Inferior)
    CrearBoton(BTN_TRAIL_NAME, (stateTrailing ? "TRAIL ON" : "TRAIL OFF"), x + 10, y + 195, 120, 26, (stateTrailing ? C'20,100,40' : C'60,60,60'));
    CrearBoton(BTN_BE_NAME, (stateBE ? "BE ON" : "BE OFF"), x + 140, y + 195, 120, 26, (stateBE ? C'20,100,40' : C'60,60,60'));
    CrearBoton(BTN_ASEG_NAME, "ASEGURAR", x + 270, y + 195, 140, 26, C'40,80,100');

    CrearBoton(BTN_CLOSE_NAME, "CERRAR TODO", x + 10, y + 226, 120, 26, C'140,30,30');
    CrearBoton(BTN_SHIELD_NAME, "SHIELD", x + 140, y + 226, 120, 26, C'20,40,120');
    CrearBoton(BTN_PAUSE_NAME, (statePausado ? "REANUDAR" : "APAGAR"), x + 270, y + 226, 140, 26, (statePausado ? C'40,140,40' : C'140,30,30'));
}

void ActualizarValoresHUD()
{
    double eq = AccountInfoDouble(ACCOUNT_EQUITY);
    double bal = AccountInfoDouble(ACCOUNT_BALANCE);
    int abiertas = ArraySize(pos);

    if (hudMinimizado)
    {
        ObjectSetString(0, "BAYES_LBL_TITLE", OBJPROP_TEXT, "BAYES v2.4 $" + DoubleToString(eq, 2) + " | " + DoubleToString(confianzaBayesianaUltima, 0) + "%");
        return;
    }

    string txtRegimenStr = "🟡 LATERAL (ADX " + DoubleToString(adxActualVal, 1) + ")";
    string txtOperativaStr = "AMBAS DIRECCIONES";
    color colRegimen = clrYellow;

    if (regimenActual == REGIMEN_ALCISTA)
    {
        txtRegimenStr = "🟢 TENDENCIA ALCISTA (ADX " + DoubleToString(adxActualVal, 1) + ")";
        txtOperativaStr = "SOLO COMPRAS";
        colRegimen = clrLime;
    }
    else if (regimenActual == REGIMEN_BAJISTA)
    {
        txtRegimenStr = "🔴 TENDENCIA BAJISTA (ADX " + DoubleToString(adxActualVal, 1) + ")";
        txtOperativaStr = "SOLO VENTAS";
        colRegimen = clrRed;
    }

    if (tabActual == TAB_CONTROL)
    {
        ObjectSetString(0, "BAYES_LBL_EQ", OBJPROP_TEXT, "EQUITY: $" + DoubleToString(eq, 2));
        ObjectSetString(0, "BAYES_LBL_BAL", OBJPROP_TEXT, "BALANCE: $" + DoubleToString(bal, 2) + " | HOY: " + (ganadoHoy >= 0 ? "+$" : "-$") + DoubleToString(MathAbs(ganadoHoy), 2));
        ObjectSetString(0, "BAYES_LBL_CAPAS", OBJPROP_TEXT, "CAPAS ABIERTAS: " + IntegerToString(abiertas) + " / " + IntegerToString(maxCapasEfectivo));
        ObjectSetString(0, "BAYES_LBL_ACTIVO", OBJPROP_TEXT, "ACTIVO: " + txtActivoDetectado);
        ObjectSetString(0, "BAYES_LBL_RSI", OBJPROP_TEXT, "RSI (14): " + DoubleToString(rsiActualVal, 1) + " (Compra <=30 | Venta >=70)");
        ObjectSetString(0, "BAYES_LBL_CONF", OBJPROP_TEXT, "CONFIANZA BAYES: " + DoubleToString(confianzaBayesianaUltima, 1) + "%");
        ObjectSetString(0, "BAYES_LBL_SHIELD", OBJPROP_TEXT, "REGIMEN: " + txtRegimenStr);
        ObjectSetInteger(0, "BAYES_LBL_SHIELD", OBJPROP_COLOR, colRegimen);
        ObjectSetString(0, "BAYES_LBL_VEREDICT", OBJPROP_TEXT, "OPERATIVA: " + txtOperativaStr + " | " + txtVeredicto);
    }
    else if (tabActual == TAB_CUENTA)
    {
        ObjectSetString(0, "BAYES_LBL_EQ", OBJPROP_TEXT, "EQUITY ACTUAL: $" + DoubleToString(eq, 2));
        ObjectSetString(0, "BAYES_LBL_BAL", OBJPROP_TEXT, "BALANCE CUENTA: $" + DoubleToString(bal, 2));
        ObjectSetString(0, "BAYES_LBL_RESULT", OBJPROP_TEXT, "RESULTADO HOY: " + (ganadoHoy >= 0 ? "+$" : "-$") + DoubleToString(MathAbs(ganadoHoy), 2) + " (FLOTANTE: $" + DoubleToString(flotanteActual, 2) + ")");
        ObjectSetString(0, "BAYES_LBL_CAPAS", OBJPROP_TEXT, "CAPAS EN MERCADO: " + IntegerToString(abiertas) + " / " + IntegerToString(maxCapasEfectivo));
        ObjectSetString(0, "BAYES_LBL_SHIELD", OBJPROP_TEXT, "ESCUDO SHIELD DIARIO: " + DoubleToString(shieldPctEfectivo, 1) + "%");
        ObjectSetString(0, "BAYES_LBL_VEREDICT", OBJPROP_TEXT, "ESTADO CAJERO: " + txtEstadoCajero);
    }
    else if (tabActual == TAB_INTEL)
    {
        ObjectSetString(0, "BAYES_LBL_ACTIVO", OBJPROP_TEXT, "SIMBOLO DETECTADO: " + txtActivoDetectado);
        ObjectSetString(0, "BAYES_LBL_SUB", OBJPROP_TEXT, "CALIBRACIÓN: " + (autoCalibracionActiva ? "AUTO-ADAPTATIVA 🧠" : "MANUAL ⚙️"));
        ObjectSetString(0, "BAYES_LBL_CAPAS", OBJPROP_TEXT, "DISTANCIA CAPAS AUTO: " + DoubleToString(distanciaCapasEfectiva, 1) + " PTS");
        ObjectSetString(0, "BAYES_LBL_RSI", OBJPROP_TEXT, "RSI (14): " + DoubleToString(rsiActualVal, 1) + " | ADX (14): " + DoubleToString(adxActualVal, 1));
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

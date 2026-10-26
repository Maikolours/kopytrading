//+------------------------------------------------------------------+
//|          00_MAIKO_BAYESIAN_STRATEGY_PRO_v2.6.mq5                 |
//|    ALGORITMO BAYESIAN STRATEGY PRO v2.6 - EDICIÓN OFICIAL 2026   |
//|   MOTOR BAYESIANO + RÉGIMEN ADAPTATIVO (ADX HISTÉRESIS + MTF)    |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Maiko Trading Corp."
#property link      "https://www.kopytrading.com"
#property version   "2.40"
#property strict
#property description "Bayesian Strategy Pro v2.6 | Motor de Régimen ADX (Histéresis 22-25) + Presión MTF M15/H1 + HUD Compacto + Presets Adaptativos"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//============================================================
//  ENUMERACIONES & PERFILES
//============================================================
enum ENUM_PERFIL_RIESGO
{
    PERFIL_MANUAL = 0,      // Manual (Configuracion Personalizada)
    PERFIL_CONSERVADOR = 1, // Conservador (Max 6 Capas | Shield 4.0%)
    PERFIL_BALANCEADO = 2,  // Balanceado (Max 10 Capas | Shield 6.0%)
    PERFIL_AGRESIVO = 3     // Agresivo (Max 15 Capas | Shield 8.0%)
};

enum ENUM_MODO_TENDENCIA
{
    TENDENCIA_OFF = 0,               // Desactivado (Operar en Ambas Direcciones)
    TENDENCIA_EMA200_STRICT = 1,     // Estricto EMA200 H1 (Solo BUY sobre EMA / Solo SELL bajo EMA)
    TENDENCIA_REGIMEN_AUTO_ADX = 2   // Auto-Régimen ADX + Presión Compradora/Vendedora MTF (Recomendado v2.6)
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
    TAB_MAIN = 0,
    TAB_AJUSTES = 1,
    TAB_RIESGO = 2,
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
input double             InpMinConfidence      = 60.0;     // Confianza Bayesiana Minima (%) (Base Manual)
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
//  FILTRO NOTICIAS (MANUAL O PRE-PROGRAMADO)
//============================================================
input group "FILTRO NOTICIAS (MANUAL)"
input int                InpHoraNoticiasInicio = 14;       // Hora inicio de Noticias (Broker)
input int                InpHoraNoticiasFin    = 16;       // Hora fin de Noticias (Broker)

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

double         distanciaCapasEfectiva = 35.0;         // DCA en contra (Pips/Puntos MT5)
double         distanciaPiramidacionEfectiva = 20.0;  // Piramidar a favor (Pips/Puntos MT5)
double         targetPipsEfectivo = 15.0;             // Pips/Puntos a favor para cerrar (Take Profit)
double         stopPipsEfectivo = 100.0;              // Pips/Puntos en contra para cerrar (Stop Loss)

// Dinámicos (se calculan en base a los Pips/Puntos)
double         stopLossUSD_Efectivo = 0.0;        
double         takeProfitUSD_Efectivo = 0.0;       

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
ENUM_TAB_HUD   tabActual = TAB_MAIN;
bool           hudMinimizado = false;
bool           stateTrailing = true;
bool           stateBE = true;
bool           statePausado = false;
bool           stateNoticias = false;
ENUM_PERFIL_RIESGO perfilActual = PERFIL_MANUAL;
int            maxCapasEfectivo = 10;
double         loteBaseEfectivo = 0.01;
double         shieldPctEfectivo = 4.0;
bool           autoCalibracionActiva = true;

// Nombres de Botones HUD Original
#define BTN_MINIMIZE_NAME  "BAYES_BTN_MIN"
#define BTN_TAB_MAIN        "BAYES_TAB_CTA"
#define BTN_TAB_AJUSTES      "BAYES_TAB_AJUSTES"
#define BTN_TAB_RIESGO        "BAYES_TAB_RIESGO"
#define BTN_TAB_CTRL       "BAYES_TAB_CTRL"
#define BTN_PROFILE_NAME   "BAYES_BTN_PROF"
#define BTN_AUTOCAL_NAME   "BAYES_BTN_AUTOCAL"
#define BTN_TRAIL_NAME     "BAYES_BTN_TRAIL"
#define BTN_BE_NAME        "BAYES_BTN_BE"
#define BTN_ASEG_NAME      "BAYES_BTN_ASEG"
#define BTN_CLOSE_NAME     "BAYES_BTN_CLOSE"
#define BTN_SHIELD_NAME    "BAYES_BTN_SHIELD"
#define BTN_PAUSE_NAME     "BAYES_BTN_PAUSE"

#define BTN_OB_MINUS_NAME  "BAYES_BTN_OB_MIN"
#define BTN_OB_PLUS_NAME   "BAYES_BTN_OB_PLU"
#define BTN_OS_MINUS_NAME  "BAYES_BTN_OS_MIN"
#define BTN_OS_PLUS_NAME   "BAYES_BTN_OS_PLU"

#define LINE_PREFIX        "BAYES_LINE_"

//+------------------------------------------------------------------+
//| Diagnóstico de Permisos de Trading del Broker y Cuenta          |
//+------------------------------------------------------------------+
bool ValidarPermisosTradingBroker(string &errorMsg)
{
    errorMsg = "";
    ENUM_SYMBOL_TRADE_MODE symTradeMode = (ENUM_SYMBOL_TRADE_MODE)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE);
    bool accTradeAllowed = (bool)AccountInfoInteger(ACCOUNT_TRADE_ALLOWED);
    bool accExpertAllowed = (bool)AccountInfoInteger(ACCOUNT_TRADE_EXPERT);

    if (symTradeMode == SYMBOL_TRADE_MODE_DISABLED)
    {
        errorMsg = "🔴 SÍMBOLO DESACTIVADO POR BROKER (" + _Symbol + "). Cambia a US500 o SPX500";
        return false;
    }
    if (symTradeMode == SYMBOL_TRADE_MODE_CLOSEONLY)
    {
        errorMsg = "🔴 SÍMBOLO EN SOLO CIERRE (" + _Symbol + ")";
        return false;
    }
    if (!accTradeAllowed)
    {
        errorMsg = "🔴 CUENTA EN SOLO LECTURA (Contraseña Inversor / Cuenta deshabilitada)";
        return false;
    }
    if (!accExpertAllowed)
    {
        errorMsg = "🔴 TRADING ALGORÍTMICO PROHIBIDO POR EL BROKER EN ESTA CUENTA";
        return false;
    }

    return true;
}

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

    loteBaseEfectivo = InpLoteBase;
    CalibrarParametrosActivo();

    trade.SetExpertMagicNumber(magicEfectivo);
    trade.SetDeviationInPoints(10);
    AutoConfigurarTypeFilling();

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
        Print("Error inicializando indicadores en v2.6.");
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

    Print("Bayesian Strategy Pro v2.6 Iniciado Correctamente. Magic: ", magicEfectivo, " Activo: ", txtActivoDetectado, " Shield: ", shieldPctEfectivo, "%");
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
        rsiOversoldEfectivo = 30.0;
        minConfidenceEfectivo = 70.0;
        distanciaCapasEfectiva = 150.0;
        stopLossUSD_Efectivo = 30.0;
        takeProfitUSD_Efectivo = 5.0;
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
        magicEfectivo = (InpMagicNumber > 0) ? InpMagicNumber : 888146;
        distanciaPiramidacionEfectiva = 500.0;
        targetPipsEfectivo = 1500.0;
        stopPipsEfectivo = 3000.0;
        txtActivoDetectado = "BITCOIN (BTCUSD) 24/7" + (presetModoActual == PRESET_FORZAR_BTC ? " [FORZADO ⚙️]" : " [AUTO 🧠]");
    }
    // 2. PRESET ORO (XAUUSD)
    else if (presetModoActual == PRESET_FORZAR_ORO || (presetModoActual == PRESET_AUTO && (StringFind(sym, "XAU") >= 0 || StringFind(sym, "GOLD") >= 0)))
    {
        rsiPeriodEfectivo = 14;
        rsiOverboughtEfectivo = 70.0;
        rsiOversoldEfectivo = 28.0;
        minConfidenceEfectivo = 60.0;
        distanciaCapasEfectiva = 60.0; // 60 pips ($6.00 en Oro) entre capas para resistir volatilidad
        stopLossUSD_Efectivo = 35.0;   // SL de cesta calibrado a $35
        takeProfitUSD_Efectivo = 6.0;  // TP aumentado a $6.00 para equilibrar ratio R:R
        activarFiltroHorarioEfectivo = true; // Activo en sesión europea y americana

        horaInicioEfectivo = 8;        // 08:00 (Apertura Londres)
        horaFinEfectivo = 21;          // 21:00 (Cierre Wall Street)
        operarLunesEfectivo = true;
        operarMartesEfectivo = true;
        operarMiercolesEfectivo = true;
        operarJuevesEfectivo = true;
        operarViernesEfectivo = true;
        operarSabadoEfectivo = false;
        operarDomingoEfectivo = false;
        magicEfectivo = (InpMagicNumber > 0) ? InpMagicNumber : 888147;
        distanciaPiramidacionEfectiva = 30.0;
        targetPipsEfectivo = 60.0;
        stopPipsEfectivo = 250.0;
        txtActivoDetectado = "ORO (XAUUSD)" + (presetModoActual == PRESET_FORZAR_ORO ? " [FORZADO ⚙️]" : " [AUTO 🧠]");
    }
    // 3. PRESET FOREX (EURUSD / GBPUSD)
    else if (presetModoActual == PRESET_FORZAR_EURUSD || (presetModoActual == PRESET_AUTO && (StringFind(sym, "EURUSD") >= 0 || StringFind(sym, "GBPUSD") >= 0)))
    {
        rsiPeriodEfectivo = 14;
        rsiOverboughtEfectivo = 70.0;
        rsiOversoldEfectivo = 30.0;
        minConfidenceEfectivo = 60.0;
        distanciaCapasEfectiva = 25.0;
        stopLossUSD_Efectivo = 20.0;
        takeProfitUSD_Efectivo = 2.0; // Reducido para Forex
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
        magicEfectivo = (InpMagicNumber > 0) ? InpMagicNumber : 888148;
        distanciaPiramidacionEfectiva = 10.0;
        targetPipsEfectivo = 15.0;
        stopPipsEfectivo = 50.0;
        txtActivoDetectado = "FOREX " + sym + (presetModoActual == PRESET_FORZAR_EURUSD ? " [FORZADO ⚙️]" : " [AUTO 🧠]");
    }
    // 4. PRESET INDICE S&P 500 (US500 / SP500 / SPX500)
    else if (presetModoActual == PRESET_FORZAR_SP500 || (presetModoActual == PRESET_AUTO && (StringFind(sym, "US500") >= 0 || StringFind(sym, "SPX") >= 0 || StringFind(sym, "SP500") >= 0)))
    {
        rsiPeriodEfectivo = 14;
        rsiOverboughtEfectivo = 70.0;
        rsiOversoldEfectivo = 30.0;
        minConfidenceEfectivo = 60.0;
        distanciaCapasEfectiva = 100.0;
        distanciaPiramidacionEfectiva = 40.0;
        targetPipsEfectivo = 60.0;
        stopPipsEfectivo = 250.0;
        stopLossUSD_Efectivo = 25.0;
        takeProfitUSD_Efectivo = 5.0;
        activarFiltroHorarioEfectivo = true;
        horaInicioEfectivo = 9;
        horaFinEfectivo = 22;
        operarLunesEfectivo = true;
        operarMartesEfectivo = true;
        operarMiercolesEfectivo = true;
        operarJuevesEfectivo = true;
        operarViernesEfectivo = true;
        operarSabadoEfectivo = false;
        operarDomingoEfectivo = false;
        magicEfectivo = (InpMagicNumber > 0) ? InpMagicNumber : 888149;
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
        magicEfectivo = (InpMagicNumber > 0) ? InpMagicNumber : 888145;
        txtActivoDetectado = "MANUAL " + sym + " [PERSONALIZADO 🛠️]";
    }

    // Permitir sobreescritura inmediata si el usuario modifica los inputs en F7
    if (InpRSIOverbought > 0.0 && InpRSIOverbought != 70.0) rsiOverboughtEfectivo = InpRSIOverbought;
    if (InpRSIOversold > 0.0 && InpRSIOversold != 28.0 && InpRSIOversold != 30.0 && InpRSIOversold != 35.0) rsiOversoldEfectivo = InpRSIOversold;
    if (InpMinConfidence > 0.0 && InpMinConfidence != 60.0 && InpMinConfidence != 70.0) minConfidenceEfectivo = InpMinConfidence;
    if (presetModoActual == PRESET_MANUAL) activarFiltroHorarioEfectivo = InpActivarFiltroHorario;

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
        shieldPctEfectivo = 4.0;
    }
    else if (InpPerfilRiesgo == PERFIL_BALANCEADO)
    {
        maxCapasEfectivo = 10;
        shieldPctEfectivo = 6.0;
    }
    else if (InpPerfilRiesgo == PERFIL_AGRESIVO)
    {
        maxCapasEfectivo = 15;
        shieldPctEfectivo = 8.0;
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
    GestionarSalidasCesta();

    if (hRSI == INVALID_HANDLE || hRSI == 0)
    {
        hRSI = iRSI(_Symbol, _Period, rsiPeriodEfectivo, PRICE_CLOSE);
    }
    if (hRSI != INVALID_HANDLE && hRSI != 0 && BarsCalculated(hRSI) > rsiPeriodEfectivo)
    {
        double rsiLive[];
        ArraySetAsSeries(rsiLive, true);
        if (CopyBuffer(hRSI, 0, 0, 1, rsiLive) > 0)
        {
            if (rsiLive[0] > 3.0 && rsiLive[0] < 97.0)
            {
                rsiActualVal = rsiLive[0];
            }
        }
    }

    if (InpMostrarLineasEstructura) ActualizarLineasEstructura();

    datetime currentBarTime = iTime(_Symbol, _Period, 0);

    // Calcular siempre la Inferencia Bayesiana en vivo en cada tick para el HUD
    double liveConf = 50.0;
    CalcularInferenciaBayesiana(liveConf);
    if (liveConf > 0.0) confianzaBayesianaUltima = liveConf;

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

    string errPermiso = "";
    if (!ValidarPermisosTradingBroker(errPermiso))
    {
        txtVeredicto = errPermiso;
        if (InpMostrarHUD) ActualizarValoresHUD();
        return;
    }

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

        // Filtro de Tendencia / Régimen ADX (v2.6)
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

        if (bayesDir == 1) AbrirCapa(POSITION_TYPE_BUY, InpLoteBase, "Bayes_v2.6_C1_BUY");
        else if (bayesDir == -1) AbrirCapa(POSITION_TYPE_SELL, InpLoteBase, "Bayes_v2.6_C1_SELL");
    }
    else if (totalPos > 0 && totalPos < maxCapasEfectivo)
    {
        if (EsMomentoNuevaCapa(dirCesta))
        {
            double loteCapa = InpLoteBase;
            if (dirCesta == POSITION_TYPE_BUY)
            {
                AbrirCapa(POSITION_TYPE_BUY, loteCapa, StringFormat("Bayes_v2.6_C%d_BUY", totalPos + 1));
            }
            else if (dirCesta == POSITION_TYPE_SELL)
            {
                AbrirCapa(POSITION_TYPE_SELL, loteCapa, StringFormat("Bayes_v2.6_C%d_SELL", totalPos + 1));
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
//| Auto-Detección y Configuración de Modo de Relleno (Filling Mode)|
//+------------------------------------------------------------------+
void AutoConfigurarTypeFilling()
{
    uint filling = (uint)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
    if ((filling & SYMBOL_FILLING_FOK) != 0)
    {
        trade.SetTypeFilling(ORDER_FILLING_FOK);
    }
    else if ((filling & SYMBOL_FILLING_IOC) != 0)
    {
        trade.SetTypeFilling(ORDER_FILLING_IOC);
    }
    else
    {
        trade.SetTypeFilling(ORDER_FILLING_RETURN);
    }
}

//+------------------------------------------------------------------+
//| Normalizar Lotes según Límites del Broker (Min, Max, Step)       |
//+------------------------------------------------------------------+
double NormalizarLote(double lotesDeseados)
{
    double minVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double stepVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

    if (minVol <= 0.0) minVol = 0.01;
    if (stepVol <= 0.0) stepVol = 0.01;

    double loteCalculado = lotesDeseados;
    if (loteCalculado < minVol) loteCalculado = minVol;
    if (maxVol > 0.0 && loteCalculado > maxVol) loteCalculado = maxVol;

    loteCalculado = MathFloor(loteCalculado / stepVol + 0.00001) * stepVol;
    if (loteCalculado < minVol) loteCalculado = minVol;

    int precision = 2;
    if (stepVol >= 1.0) precision = 0;
    else if (stepVol >= 0.1) precision = 1;

    return NormalizeDouble(loteCalculado, precision);
}

//+------------------------------------------------------------------+
//| Abrir Capa con Fallback Adaptativo                               |
//+------------------------------------------------------------------+
void AbrirCapa(ENUM_POSITION_TYPE dir, double lotes, string comentario)
{
    AutoConfigurarTypeFilling();
    double loteValido = NormalizarLote(lotes);
    double price = (dir == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
    bool res = false;
    if (dir == POSITION_TYPE_BUY)
    {
        res = trade.Buy(loteValido, _Symbol, price, 0, 0, comentario);
        if (!res)
        {
            trade.SetTypeFilling(ORDER_FILLING_IOC);
            res = trade.Buy(loteValido, _Symbol, price, 0, 0, comentario);
        }
        if (!res)
        {
            trade.SetTypeFilling(ORDER_FILLING_RETURN);
            res = trade.Buy(loteValido, _Symbol, price, 0, 0, comentario);
        }
    }
    else
    {
        res = trade.Sell(loteValido, _Symbol, price, 0, 0, comentario);
        if (!res)
        {
            trade.SetTypeFilling(ORDER_FILLING_IOC);
            res = trade.Sell(loteValido, _Symbol, price, 0, 0, comentario);
        }
        if (!res)
        {
            trade.SetTypeFilling(ORDER_FILLING_RETURN);
            res = trade.Sell(loteValido, _Symbol, price, 0, 0, comentario);
        }
    }

    if (!res)
    {
        uint code = trade.ResultRetcode();
        string desc = trade.ResultRetcodeDescription();
        txtVeredicto = "🔴 RECHAZADO POR BROKER: " + desc + " (" + IntegerToString(code) + ")";
        Print("ERROR EJECUCIÓN EN ", _Symbol, ": ", desc, " [Retcode: ", code, "] Lote intentado: ", loteValido);
        if (InpMostrarHUD) ActualizarValoresHUD();
    }
}

//+------------------------------------------------------------------+
//| Inferencia Bayesiana RSI                                        |
//+------------------------------------------------------------------+
int CalcularInferenciaBayesiana(double &confidence)
{
    confidence = 50.0; // Línea base por defecto

    if (hRSI == INVALID_HANDLE || hRSI == 0 || BarsCalculated(hRSI) < rsiPeriodEfectivo * 2) return 0;

    double rsiBuffer[];
    ArraySetAsSeries(rsiBuffer, true);
    if (CopyBuffer(hRSI, 0, 1, 3, rsiBuffer) < 3) return 0;

    double rsiCurr = rsiBuffer[0];
    double rsiPrev = rsiBuffer[1];

    if (rsiCurr <= 3.0 || rsiCurr >= 97.0 || rsiPrev <= 3.0 || rsiPrev >= 97.0) return 0;

    double priorBuy = 0.50;
    double priorSell = 0.50;

    if (InpFiltroTendencia == TENDENCIA_REGIMEN_AUTO_ADX)
    {
        if (regimenActual == REGIMEN_ALCISTA)
        {
            priorBuy = 0.65;
            priorSell = 0.35;
        }
        else if (regimenActual == REGIMEN_BAJISTA)
        {
            priorBuy = 0.35;
            priorSell = 0.65;
        }
    }

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
        else
        {
            if (rsiCurr >= 50.0)
            {
                pSignalGivenBuy = 0.60;
                pSignalGivenSell = 0.40;
            }
            else
            {
                pSignalGivenBuy = 0.40;
                pSignalGivenSell = 0.60;
            }
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
    if (totalPos >= 6)
    {
        targetEfectivoUSD = 1.50; // Salida rápida de rescate
    }
    else if (totalPos >= 3)
    {
        targetEfectivoUSD = MathMax(takeProfitUSD_Efectivo * 0.5, 2.0); // Salida asegurada al recuperar
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
    
    int total = ArraySize(pos);
    static double maxFlotanteAlcanzado = 0.0;
    static int ultimoTotal = 0;

    // Reset completo si no hay posiciones abiertas
    if (total == 0)
    {
        maxFlotanteAlcanzado = 0.0;
        ultimoTotal = 0;
        return;
    }
    
    // Reset max flotante si cambió el número de posiciones de la cesta
    if (total != ultimoTotal) {
        maxFlotanteAlcanzado = flotanteActual;
        ultimoTotal = total;
    }

    if (flotanteActual > maxFlotanteAlcanzado) {
        maxFlotanteAlcanzado = flotanteActual;
    }

    // Trailing Stop de Cesta: Si llegamos a ganar más del 70% del Take Profit, aseguramos al menos el 20%
    if (takeProfitUSD_Efectivo > 0 && maxFlotanteAlcanzado > (takeProfitUSD_Efectivo * 0.70))
    {
        double lockMinimo = MathMax(takeProfitUSD_Efectivo * 0.20, 0.50);
        if (flotanteActual <= lockMinimo && flotanteActual > 0.0)
        {
            CerrarTodasLasPosiciones("Trailing Stop de Cesta ($" + DoubleToString(flotanteActual, 2) + ")");
            maxFlotanteAlcanzado = 0.0;
            ultimoTotal = 0;
            return;
        }
    }
    
    // BreakEven de Cesta: Si llegamos a ganar al menos el 40% del TP (mínimo $1.50 de beneficio alcanzado),
    // y luego retrocede, aseguramos salir con beneficio positivo neto (mínimo +$0.50)
    else if (takeProfitUSD_Efectivo > 0 && maxFlotanteAlcanzado >= MathMax(takeProfitUSD_Efectivo * 0.40, 1.50))
    {
        if (flotanteActual <= 0.50 && flotanteActual > 0.0)
        {
            CerrarTodasLasPosiciones("BreakEven de Cesta ($" + DoubleToString(flotanteActual, 2) + ")");
            maxFlotanteAlcanzado = 0.0;
            ultimoTotal = 0;
            return;
        }
    }
}

//+------------------------------------------------------------------+
//| Gestión Trailing Stop Dinámico (Adaptativo por Activo)           |
//+------------------------------------------------------------------+
void GestionarTrailingStop() { /* Integrado en BreakEven de Cesta */ }


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
    int closedCount = 0;
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (posInfo.SelectByIndex(i))
        {
            if (posInfo.Symbol() == _Symbol && posInfo.Magic() == magicEfectivo)
            {
                if (trade.PositionClose(posInfo.Ticket()))
                    closedCount++;
            }
        }
    }
    if (closedCount > 0)
    {
        Print("Cerrando Cesta (", closedCount, " posiciones): ", razon);
    }
}

//+------------------------------------------------------------------+
//| Actualizar Array de Posiciones Activas                           |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Calcular Beneficio Esperado para N Pips                          |
//+------------------------------------------------------------------+
double CalcularBeneficioParaPips(int type, double volume, double pips)
{
    double price = (type == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double targetPrice = price + ((type == POSITION_TYPE_BUY ? 1 : -1) * (pips * _Point * 10.0));
    double profit = 0.0;
    if (OrderCalcProfit((ENUM_ORDER_TYPE)type, _Symbol, volume, price, targetPrice, profit))
    {
        return profit;
    }
    // Fallback aproximado
    double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    if (tickSize > 0)
    {
        return (pips * _Point * 10.0) / tickSize * tickVal * volume;
    }
    return 0.0;
}

//+------------------------------------------------------------------+
//| Actualizar Metas Monetarias Globales Dinámicas                   |
//+------------------------------------------------------------------+
void ActualizarMetasMonetarias()
{
    static int ultimoTotal = -1;
    int total = ArraySize(pos);
    
    if (total == ultimoTotal) return; // Solo recalcular si cambió el número de operaciones (evita lag)
    ultimoTotal = total;

    if (total == 0) return;

    double tpGlobal = 0.0;
    double slGlobal = 0.0;
    
    for (int i = 0; i < total; i++)
    {
        tpGlobal += CalcularBeneficioParaPips(pos[i].t, pos[i].v, targetPipsEfectivo);
        slGlobal += MathAbs(CalcularBeneficioParaPips(pos[i].t, pos[i].v, stopPipsEfectivo));
    }

    if (tpGlobal > 0.0) takeProfitUSD_Efectivo = tpGlobal;
    if (slGlobal > 0.0) stopLossUSD_Efectivo = slGlobal;
}

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

    // ActualizarMetasMonetarias(); // [BUGFIX] Removido para evitar que machaque los TPs calibrados fijos
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
    if (!InpActivarShield) return false;

    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    if (balance <= 0) return false;

    double maxPerdidaPermitidaUSD = balance * (shieldPctEfectivo / 100.0);
    double perdidasHoy = ganadoHoy + (flotanteActual < 0 ? flotanteActual : 0);

    if (perdidasHoy <= -maxPerdidaPermitidaUSD)
    {
        if (ArraySize(pos) > 0)
        {
            CerrarTodasLasPosiciones("ESCUDO DIARIO ACTIVADO (-" + DoubleToString(shieldPctEfectivo, 1) + "%)");
        }
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
        ObjectSetInteger(0, sparam, OBJPROP_STATE, false);

        if (sparam == BTN_TAB_MAIN) { tabActual = TAB_MAIN; RedibujarHUD(); }
        else if (sparam == BTN_TAB_AJUSTES) { tabActual = TAB_AJUSTES; RedibujarHUD(); }
        else if (sparam == BTN_TAB_RIESGO) { tabActual = TAB_RIESGO; RedibujarHUD(); }
        else if (sparam == BTN_TAB_CTRL) { tabActual = TAB_MAIN; RedibujarHUD(); }
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
            loteBaseEfectivo = InpLoteBase;
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
        else if (sparam == BTN_SHIELD_NAME) { stateNoticias = !stateNoticias; RedibujarHUD(); }
        else if (sparam == BTN_PAUSE_NAME) { 
            statePausado = !statePausado; 
            if (!statePausado)
            {
                botActivo = true;
                txtEstadoCajero = "🛡️ SHIELD ESTADO: CAJERO OK";
                txtVeredicto = "OPERATIVA NORMAL";
            }
            RedibujarHUD(); 
        }
        else if (sparam == BTN_CLOSE_NAME)
        {
            CerrarTodasLasPosiciones("CERRADO MANUAL DESDE HUD");
            txtVeredicto = "CERRADO MANUAL DESDE HUD";
            RedibujarHUD();
        }
        else if (sparam == BTN_OB_MINUS_NAME) { rsiOverboughtEfectivo -= 1.0; RedibujarHUD(); }
        else if (sparam == BTN_OB_PLUS_NAME)  { rsiOverboughtEfectivo += 1.0; RedibujarHUD(); }
        else if (sparam == BTN_OS_MINUS_NAME) { rsiOversoldEfectivo -= 1.0; RedibujarHUD(); }
        else if (sparam == BTN_OS_PLUS_NAME)  { rsiOversoldEfectivo += 1.0; RedibujarHUD(); }

        else if (sparam == "BAYES_BTN_LOT_MINUS") {
            double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
            loteBaseEfectivo = MathMax(loteBaseEfectivo - lotStep, lotStep);
            RedibujarHUD();
        }
        else if (sparam == "BAYES_BTN_LOT_PLUS") {
            double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
            double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
            loteBaseEfectivo = MathMin(loteBaseEfectivo + lotStep, maxLot);
            RedibujarHUD();
        }
        else if (sparam == "BAYES_BTN_HORA_TOGGLE") {
            activarFiltroHorarioEfectivo = !activarFiltroHorarioEfectivo;
            RedibujarHUD();
        }
        else if (sparam == "BAYES_BTN_CAPAS_MINUS") {
            distanciaCapasEfectiva = MathMax(distanciaCapasEfectiva - 5.0, 5.0);
            RedibujarHUD();
        }
        else if (sparam == "BAYES_BTN_CAPAS_PLUS") {
            distanciaCapasEfectiva += 5.0;
            RedibujarHUD();
        }
        else if (sparam == "BAYES_BTN_PIRA_MINUS") {
            distanciaPiramidacionEfectiva = MathMax(distanciaPiramidacionEfectiva - 5.0, 5.0);
            RedibujarHUD();
        }

        else if (sparam == "BAYES_BTN_MAX_MINUS") {
            maxCapasEfectivo = (int)MathMax(maxCapasEfectivo - 1, 1);
            RedibujarHUD();
        }

        else if (sparam == "BAYES_BTN_CONF_MINUS") {
            minConfidenceEfectivo = MathMax(minConfidenceEfectivo - 1.0, 50.0);
            RedibujarHUD();
        }
        else if (sparam == "BAYES_BTN_CONF_PLUS") {
            minConfidenceEfectivo = MathMin(minConfidenceEfectivo + 1.0, 100.0);
            RedibujarHUD();
        }
        else if (sparam == "BAYES_BTN_MAX_PLUS") {
            maxCapasEfectivo = (int)MathMin(maxCapasEfectivo + 1, 50);
            RedibujarHUD();
        }


        else if (sparam == "BAYES_BTN_PIRA_PLUS") {
            distanciaPiramidacionEfectiva += 5.0;
            RedibujarHUD();
        }

    }
    ChartRedraw(0);
}


//+------------------------------------------------------------------+
//| Creación de Panel Visual HUD Compacto v2.6                      |
//+------------------------------------------------------------------+
void RedibujarHUD()
{
    DestruirHUD();
    CrearHUD();
    ActualizarValoresHUD();
    ChartRedraw(0);
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

        CrearLabel("BAYES_LBL_TITLE", "BAYES v2.6", x + 10, y + 7, clrGold, 10, true);
        CrearBoton(BTN_MINIMIZE_NAME, "[+]", x + 185, y + 5, 25, 20, C'30,40,60');
        return;
    }

    ObjectCreate(0, "BAYES_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_XSIZE, 480);
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_YSIZE, 335);
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_BGCOLOR, C'14,18,28');
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_BORDER_COLOR, C'40,50,70');
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);

    color cMain = (tabActual == TAB_MAIN || tabActual == TAB_CONTROL) ? clrSteelBlue : clrDarkSlateGray;
    color cAjustes = (tabActual == TAB_AJUSTES) ? clrSteelBlue : clrDarkSlateGray;
    color cRiesgo = (tabActual == TAB_RIESGO) ? clrSteelBlue : clrDarkSlateGray;

    CrearBoton(BTN_TAB_MAIN, "PRINCIPAL", x + 10, y + 10, 80, 22, cMain);
    CrearBoton(BTN_TAB_AJUSTES, "AJUSTES", x + 95, y + 10, 80, 22, cAjustes);
    CrearBoton(BTN_TAB_RIESGO, "RIESGO", x + 180, y + 10, 80, 22, cRiesgo);
    CrearBoton(BTN_MINIMIZE_NAME, "[  ]", x + 360, y + 10, 50, 22, C'120,40,40');

    // ALL LABELS
    CrearLabel("BAYES_LBL_TITLE", "CONTROL OPERATIVO v2.6", x + 10, y + 40, clrGold, 9, true);
    CrearLabel("BAYES_LBL_EQ", " ", x + 10, y + 58, clrCyan, 9, true);
    CrearLabel("BAYES_LBL_BAL", " ", x + 10, y + 74, clrWhite, 8, false);
    CrearLabel("BAYES_LBL_CAPAS", " ", x + 10, y + 90, clrYellow, 8, true);
    CrearLabel("BAYES_LBL_ACTIVO", " ", x + 10, y + 106, clrWhite, 8, false);
    CrearLabel("BAYES_LBL_RSI", " ", x + 10, y + 122, clrCyan, 8, false);
    CrearLabel("BAYES_LBL_CONF", " ", x + 10, y + 138, clrLime, 8, true);
    CrearLabel("BAYES_LBL_SHIELD", " ", x + 10, y + 154, clrOrange, 8, true);
    CrearLabel("BAYES_LBL_VEREDICT", " ", x + 10, y + 170, clrYellow, 8, true);
    CrearLabel("BAYES_LBL_RESULT", " ", x + 10, y + 110, clrWhite, 8, false); // For Ajustes Lotaje

    // ALL BUTTONS (ocultos por defecto, los muestra ActualizarValoresHUD si toca)
    CrearBoton("BAYES_BTN_LOT_MINUS", "L -", x + 230, y + 72, 40, 20, C'150,40,40');
    CrearBoton("BAYES_BTN_LOT_PLUS", "L +", x + 275, y + 72, 40, 20, C'20,110,50');
    CrearBoton(BTN_OB_MINUS_NAME, "RSI V-", x + 230, y + 88, 40, 20, C'150,40,40');
    CrearBoton(BTN_OB_PLUS_NAME, "RSI V+", x + 275, y + 88, 40, 20, C'20,110,50');
    CrearBoton(BTN_OS_MINUS_NAME, "RSI C-", x + 230, y + 104, 40, 20, C'150,40,40');
    CrearBoton(BTN_OS_PLUS_NAME, "RSI C+", x + 275, y + 104, 40, 20, C'20,110,50');
    CrearBoton("BAYES_BTN_HORA_TOGGLE", "ON/OFF HORARIO", x + 230, y + 120, 125, 20, C'40,80,120');
    CrearBoton("BAYES_BTN_CAPAS_MINUS", "D -", x + 230, y + 104, 40, 20, C'150,40,40');
    CrearBoton("BAYES_BTN_CAPAS_PLUS", "D +", x + 275, y + 104, 40, 20, C'20,110,50');
    CrearBoton("BAYES_BTN_PIRA_MINUS", "P -", x + 230, y + 120, 40, 20, C'150,40,40');
    CrearBoton("BAYES_BTN_PIRA_PLUS", "P +", x + 275, y + 120, 40, 20, C'20,110,50');
    CrearBoton("BAYES_BTN_MAX_MINUS", "M -", x + 230, y + 136, 40, 20, C'150,40,40');
    CrearBoton("BAYES_BTN_MAX_PLUS", "M +", x + 275, y + 136, 40, 20, C'20,110,50');
    CrearBoton("BAYES_BTN_CONF_MINUS", "C -", x + 230, y + 136, 40, 20, C'150,40,40');
    CrearBoton("BAYES_BTN_CONF_PLUS", "C +", x + 275, y + 136, 40, 20, C'20,110,50');




    // Botones Rápidos Interactivos (Fila Inferior)
    CrearBoton(BTN_TRAIL_NAME, (stateTrailing ? "TRAIL OFF" : "TRAIL ON"), x + 10, y + 265, 120, 26, (stateTrailing ? C'150,40,40' : C'20,110,50'));
    CrearBoton(BTN_BE_NAME, (stateBE ? "BE OFF" : "BE ON"), x + 140, y + 265, 120, 26, (stateBE ? C'150,40,40' : C'20,110,50'));
    CrearBoton(BTN_ASEG_NAME, "ASEGURAR", x + 270, y + 265, 140, 26, C'40,80,100');
    CrearBoton(BTN_CLOSE_NAME, "CERRAR TODO", x + 10, y + 296, 120, 26, C'140,30,30');
    CrearBoton(BTN_SHIELD_NAME, (stateNoticias ? "NOTICIAS OFF" : "NOTICIAS ON"), x + 140, y + 296, 120, 26, (stateNoticias ? C'150,40,40' : C'20,110,50'));
    CrearBoton(BTN_PAUSE_NAME, (statePausado ? "REANUDAR" : "APAGAR"), x + 270, y + 296, 140, 26, (statePausado ? C'40,140,40' : C'140,30,30'));
}




void ActualizarValoresHUD()
{
    int yBase = InpHUD_Y;
    
    double eq = AccountInfoDouble(ACCOUNT_EQUITY);
    double bal = AccountInfoDouble(ACCOUNT_BALANCE);
    int abiertas = ArraySize(pos);

    string txtRegimenStr = "LATERAL (ADX " + DoubleToString(adxActualVal, 1) + ")";
    string txtOperativaStr = "AMBAS DIRECCIONES";
    if (stateNoticias) {
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        if (dt.hour >= InpHoraNoticiasInicio && dt.hour < InpHoraNoticiasFin) {
            txtVeredicto = "PAUSADO POR NOTICIAS (" + IntegerToString(InpHoraNoticiasInicio, 2, '0') + ":00-" + IntegerToString(InpHoraNoticiasFin, 2, '0') + ":00)";
        }
    }

    color colRegimen = clrYellow;

    if (regimenActual == REGIMEN_ALCISTA)
    {
        txtRegimenStr = "TENDENCIA ALCISTA (ADX " + DoubleToString(adxActualVal, 1) + ")";
        txtOperativaStr = "SOLO COMPRAS";
        colRegimen = clrLime;
    }
    else if (regimenActual == REGIMEN_BAJISTA)
    {
        txtRegimenStr = "TENDENCIA BAJISTA (ADX " + DoubleToString(adxActualVal, 1) + ")";
        txtOperativaStr = "SOLO VENTAS";
        colRegimen = clrRed;
    }

    if (hudMinimizado)
    {
        ObjectSetString(0, "BAYES_LBL_TITLE", OBJPROP_TEXT, "BAYES v2.6 $" + DoubleToString(eq, 2) + " | " + DoubleToString(confianzaBayesianaUltima, 0) + "%");
        return;
    }

    if (tabActual == TAB_MAIN || tabActual == TAB_CONTROL)
    {
        // Spacing compacto para TAB MAIN (16px)
        ObjectSetInteger(0, "BAYES_LBL_EQ", OBJPROP_YDISTANCE, yBase + 60);
        ObjectSetInteger(0, "BAYES_LBL_BAL", OBJPROP_YDISTANCE, yBase + 80);
        ObjectSetInteger(0, "BAYES_LBL_CAPAS", OBJPROP_YDISTANCE, yBase + 100);
        ObjectSetInteger(0, "BAYES_LBL_ACTIVO", OBJPROP_YDISTANCE, yBase + 120);
        ObjectSetInteger(0, "BAYES_LBL_RSI", OBJPROP_YDISTANCE, yBase + 140);
        ObjectSetInteger(0, "BAYES_LBL_CONF", OBJPROP_YDISTANCE, yBase + 160);
        ObjectSetInteger(0, "BAYES_LBL_SHIELD", OBJPROP_YDISTANCE, yBase + 180);
        ObjectSetInteger(0, "BAYES_LBL_VEREDICT", OBJPROP_YDISTANCE, yBase + 200);

        ObjectSetString(0, "BAYES_LBL_EQ", OBJPROP_TEXT, "EQUITY: $" + DoubleToString(eq, 2));
        ObjectSetString(0, "BAYES_LBL_BAL", OBJPROP_TEXT, "BALANCE: $" + DoubleToString(bal, 2) + " | HOY: " + (ganadoHoy >= 0 ? "+$" : "-$") + DoubleToString(MathAbs(ganadoHoy), 2));
        ObjectSetString(0, "BAYES_LBL_CAPAS", OBJPROP_TEXT, "CAPAS ABIERTAS: " + IntegerToString(abiertas) + " / " + IntegerToString(maxCapasEfectivo) + "  |  FLOTANTE: " + (flotanteActual >= 0 ? "+$" : "-$") + DoubleToString(MathAbs(flotanteActual), 2) + "  |  META TP: +$" + DoubleToString(takeProfitUSD_Efectivo, 2));
        ObjectSetString(0, "BAYES_LBL_ACTIVO", OBJPROP_TEXT, "ACTIVO: " + txtActivoDetectado + "  |  " + (activarFiltroHorarioEfectivo ? "HORARIO: " + IntegerToString(horaInicioEfectivo, 2, '0') + ":00 - " + IntegerToString(horaFinEfectivo, 2, '0') + ":00" : "HORARIO: 24/7"));
        ObjectSetString(0, "BAYES_LBL_RSI", OBJPROP_TEXT, "RSI (" + IntegerToString(rsiPeriodEfectivo) + "): " + DoubleToString(rsiActualVal, 1) + " (Compra <=" + DoubleToString(rsiOversoldEfectivo, 0) + " | Venta >=" + DoubleToString(rsiOverboughtEfectivo, 0) + ")");
        ObjectSetString(0, "BAYES_LBL_CONF", OBJPROP_TEXT, "CONFIANZA BAYES: " + DoubleToString(confianzaBayesianaUltima, 1) + "%");
        ObjectSetString(0, "BAYES_LBL_SHIELD", OBJPROP_TEXT, "REGIMEN: " + txtRegimenStr);
        ObjectSetInteger(0, "BAYES_LBL_SHIELD", OBJPROP_COLOR, colRegimen);
        ObjectSetString(0, "BAYES_LBL_VEREDICT", OBJPROP_TEXT, "OPERATIVA: " + txtOperativaStr + " | " + txtVeredicto);
        ObjectSetString(0, "BAYES_LBL_RESULT", OBJPROP_TEXT, " ");



        ObjectSetInteger(0, "BAYES_BTN_CONF_MINUS", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_CONF_PLUS", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_LOT_MINUS", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_LOT_PLUS", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, BTN_OB_MINUS_NAME, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, BTN_OB_PLUS_NAME, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, BTN_OS_MINUS_NAME, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, BTN_OS_PLUS_NAME, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_HORA_TOGGLE", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_CAPAS_MINUS", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_CAPAS_PLUS", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_PIRA_MINUS", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_PIRA_PLUS", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_MAX_MINUS", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_CONF_MINUS", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_CONF_PLUS", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);

        ObjectSetInteger(0, "BAYES_BTN_MAX_PLUS", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
    }
    else if (tabActual == TAB_AJUSTES)
    {
        // Spacing amplio para TAB AJUSTES (25px)
        ObjectSetInteger(0, "BAYES_LBL_EQ", OBJPROP_YDISTANCE, yBase + 60);
        ObjectSetInteger(0, "BAYES_LBL_BAL", OBJPROP_YDISTANCE, yBase + 95);
        ObjectSetInteger(0, "BAYES_LBL_CAPAS", OBJPROP_YDISTANCE, yBase + 130);
        ObjectSetInteger(0, "BAYES_LBL_ACTIVO", OBJPROP_YDISTANCE, yBase + 165);
        ObjectSetInteger(0, "BAYES_LBL_RSI", OBJPROP_YDISTANCE, yBase + 200);
        
        // Mover botones acorde al texto (TextY - 4)
        ObjectSetInteger(0, "BAYES_BTN_LOT_MINUS", OBJPROP_YDISTANCE, yBase + 91);
        ObjectSetInteger(0, "BAYES_BTN_LOT_PLUS", OBJPROP_YDISTANCE, yBase + 91);
        ObjectSetInteger(0, BTN_OB_MINUS_NAME, OBJPROP_YDISTANCE, yBase + 126);
        ObjectSetInteger(0, BTN_OB_PLUS_NAME, OBJPROP_YDISTANCE, yBase + 126);
        ObjectSetInteger(0, BTN_OS_MINUS_NAME, OBJPROP_YDISTANCE, yBase + 161);
        ObjectSetInteger(0, BTN_OS_PLUS_NAME, OBJPROP_YDISTANCE, yBase + 161);
        ObjectSetInteger(0, "BAYES_BTN_HORA_TOGGLE", OBJPROP_YDISTANCE, yBase + 196);

        ObjectSetString(0, "BAYES_LBL_EQ", OBJPROP_TEXT, "MENU DE AJUSTES RAPIDOS");
        ObjectSetString(0, "BAYES_LBL_BAL", OBJPROP_TEXT, "LOTAJE BASE: " + DoubleToString(loteBaseEfectivo, 2) + " Lotes");
        ObjectSetString(0, "BAYES_LBL_CAPAS", OBJPROP_TEXT, "RSI VENTA (OBV): " + DoubleToString(rsiOverboughtEfectivo, 0));
        ObjectSetString(0, "BAYES_LBL_ACTIVO", OBJPROP_TEXT, "RSI COMPRA (OBV): " + DoubleToString(rsiOversoldEfectivo, 0));
        ObjectSetString(0, "BAYES_LBL_RSI", OBJPROP_TEXT, "FILTRO HORARIO: " + (activarFiltroHorarioEfectivo ? IntegerToString(horaInicioEfectivo, 2, '0') + ":00 a " + IntegerToString(horaFinEfectivo, 2, '0') + ":00" : "APAGADO (OPERA 24/7)"));
        ObjectSetString(0, "BAYES_LBL_CONF", OBJPROP_TEXT, " ");
        ObjectSetString(0, "BAYES_LBL_SHIELD", OBJPROP_TEXT, " ");
        ObjectSetString(0, "BAYES_LBL_VEREDICT", OBJPROP_TEXT, " ");
        ObjectSetString(0, "BAYES_LBL_RESULT", OBJPROP_TEXT, "CONFIANZA MINIMA: " + DoubleToString(minConfidenceEfectivo, 1) + "%");
        ObjectSetInteger(0, "BAYES_LBL_RESULT", OBJPROP_YDISTANCE, yBase + 235);

        ObjectSetInteger(0, "BAYES_BTN_LOT_MINUS", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_LOT_PLUS", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        ObjectSetInteger(0, BTN_OB_MINUS_NAME, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        ObjectSetInteger(0, BTN_OB_PLUS_NAME, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        ObjectSetInteger(0, BTN_OS_MINUS_NAME, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        ObjectSetInteger(0, BTN_OS_PLUS_NAME, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_HORA_TOGGLE", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        ObjectSetString(0, "BAYES_BTN_HORA_TOGGLE", OBJPROP_TEXT, activarFiltroHorarioEfectivo ? "PONER 24/7" : "PONER " + IntegerToString(horaInicioEfectivo, 2, '0') + ":00 a " + IntegerToString(horaFinEfectivo, 2, '0') + ":00");
        ObjectSetInteger(0, "BAYES_BTN_HORA_TOGGLE", OBJPROP_BGCOLOR, activarFiltroHorarioEfectivo ? C'150,40,40' : C'20,110,50');
        ObjectSetInteger(0, "BAYES_BTN_CONF_MINUS", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_CONF_PLUS", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_CONF_MINUS", OBJPROP_YDISTANCE, yBase + 231);
        ObjectSetInteger(0, "BAYES_BTN_CONF_PLUS", OBJPROP_YDISTANCE, yBase + 231);
        ObjectSetInteger(0, "BAYES_BTN_CAPAS_MINUS", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_CAPAS_PLUS", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_PIRA_MINUS", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_PIRA_PLUS", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_MAX_MINUS", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_MAX_PLUS", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
    }
    else if (tabActual == TAB_RIESGO)
    {
        // Spacing amplio para TAB RIESGO (25px)
        ObjectSetInteger(0, "BAYES_LBL_EQ", OBJPROP_YDISTANCE, yBase + 60);
        ObjectSetInteger(0, "BAYES_LBL_BAL", OBJPROP_YDISTANCE, yBase + 95);
        ObjectSetInteger(0, "BAYES_LBL_CAPAS", OBJPROP_YDISTANCE, yBase + 130);
        ObjectSetInteger(0, "BAYES_LBL_ACTIVO", OBJPROP_YDISTANCE, yBase + 165);
        ObjectSetInteger(0, "BAYES_LBL_RSI", OBJPROP_YDISTANCE, yBase + 200);

        // Mover botones acorde al texto (TextY - 4)
        ObjectSetInteger(0, "BAYES_BTN_CAPAS_MINUS", OBJPROP_YDISTANCE, yBase + 161);
        ObjectSetInteger(0, "BAYES_BTN_CAPAS_PLUS", OBJPROP_YDISTANCE, yBase + 161);
        ObjectSetInteger(0, "BAYES_BTN_PIRA_MINUS", OBJPROP_YDISTANCE, yBase + 196);
        ObjectSetInteger(0, "BAYES_BTN_PIRA_PLUS", OBJPROP_YDISTANCE, yBase + 196);
        ObjectSetInteger(0, "BAYES_BTN_MAX_MINUS", OBJPROP_YDISTANCE, yBase + 231);
        ObjectSetInteger(0, "BAYES_BTN_MAX_PLUS", OBJPROP_YDISTANCE, yBase + 231);
        ObjectSetInteger(0, "BAYES_LBL_CONF", OBJPROP_YDISTANCE, yBase + 235);

        ObjectSetString(0, "BAYES_LBL_EQ", OBJPROP_TEXT, "ESTADO DE RIESGO");
        ObjectSetString(0, "BAYES_LBL_BAL", OBJPROP_TEXT, "MAX DRAWDOWN PERMITIDO: " + DoubleToString(shieldPctEfectivo, 1) + "%");
        ObjectSetString(0, "BAYES_LBL_CAPAS", OBJPROP_TEXT, "ESTADO SHIELD: " + txtEstadoCajero);
        ObjectSetString(0, "BAYES_LBL_ACTIVO", OBJPROP_TEXT, "DISTANCIA CAPAS (DCA): " + DoubleToString(distanciaCapasEfectiva, 1) + " pips");
        ObjectSetString(0, "BAYES_LBL_RSI", OBJPROP_TEXT, "DISTANCIA PIRAMIDACION: " + DoubleToString(distanciaPiramidacionEfectiva, 1) + " pips");
        ObjectSetString(0, "BAYES_LBL_CONF", OBJPROP_TEXT, "MAX CAPAS PERMITIDAS: " + IntegerToString(maxCapasEfectivo));
        ObjectSetString(0, "BAYES_LBL_SHIELD", OBJPROP_TEXT, " ");
        ObjectSetString(0, "BAYES_LBL_VEREDICT", OBJPROP_TEXT, " ");
        ObjectSetString(0, "BAYES_LBL_RESULT", OBJPROP_TEXT, "CONFIANZA MINIMA: " + DoubleToString(minConfidenceEfectivo, 1) + "%");
        ObjectSetInteger(0, "BAYES_LBL_RESULT", OBJPROP_YDISTANCE, yBase + 235);
        
        ObjectSetInteger(0, "BAYES_BTN_LOT_MINUS", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_LOT_PLUS", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, BTN_OB_MINUS_NAME, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, BTN_OB_PLUS_NAME, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, BTN_OS_MINUS_NAME, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, BTN_OS_PLUS_NAME, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_HORA_TOGGLE", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_CAPAS_MINUS", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_CAPAS_PLUS", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_PIRA_MINUS", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_PIRA_PLUS", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_MAX_MINUS", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        ObjectSetInteger(0, "BAYES_BTN_MAX_PLUS", OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
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

    ObjectDelete(0, BTN_TAB_MAIN);
    ObjectDelete(0, BTN_TAB_AJUSTES);
    ObjectDelete(0, BTN_TAB_RIESGO);
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
    ObjectDelete(0, BTN_OB_MINUS_NAME);
    ObjectDelete(0, BTN_OB_PLUS_NAME);
    ObjectDelete(0, BTN_OS_MINUS_NAME);
    ObjectDelete(0, BTN_OS_PLUS_NAME);

    ObjectDelete(0, "BAYES_BTN_LOT_MINUS");
    ObjectDelete(0, "BAYES_BTN_LOT_PLUS");
    ObjectDelete(0, "BAYES_BTN_HORA_TOGGLE");
    ObjectDelete(0, "BAYES_BTN_CAPAS_MINUS");
    ObjectDelete(0, "BAYES_BTN_CAPAS_PLUS");
    ObjectDelete(0, "BAYES_BTN_PIRA_MINUS");
    ObjectDelete(0, "BAYES_BTN_PIRA_PLUS");
    ObjectDelete(0, "BAYES_BTN_MAX_MINUS");
    ObjectDelete(0, "BAYES_BTN_MAX_PLUS");
    ObjectDelete(0, "BAYES_BTN_CONF_MINUS");
    ObjectDelete(0, "BAYES_BTN_CONF_PLUS");


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
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, name, OBJPROP_ZORDER, 10);
    ObjectSetInteger(0, name, OBJPROP_STATE, false);
}

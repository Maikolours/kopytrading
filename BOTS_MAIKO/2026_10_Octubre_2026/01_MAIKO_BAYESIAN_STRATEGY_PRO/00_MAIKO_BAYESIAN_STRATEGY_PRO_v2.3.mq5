//+------------------------------------------------------------------+
//|          00_MAIKO_BAYESIAN_STRATEGY_PRO_v2.3.mq5                 |
//|    ALGORITMO BAYESIAN STRATEGY PRO v2.3 - EDICIÓN OFICIAL 2026   |
//|  MOTOR BAYESIANO + GRID UNIDIRECCIONAL + HUD ORIGINAL + LINEAS   |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Maiko Trading Corp."
#property link      "https://www.kopytrading.com"
#property version   "2.30"
#property strict
#property description "Bayesian Strategy Pro v2.3 | HUD Original + Marquitas Amarillas Intermitentes + Parámetros por Activo (BTC 24/7 / ORO / EURUSD)"

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
    TENDENCIA_OFF = 0,          // Desactivado (Operar en Ambas Direcciones)
    TENDENCIA_EMA200_STRICT = 1 // Estricto EMA200 H1 (Solo BUY sobre EMA / Solo SELL bajo EMA)
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
input string             InpLicenseKey         = "BAYESIAN-PRO-SEPTIEMBRE-2026";
input string             InpPurchaseID         = "";       // ID de Vinculo (kopytrading.com)
input ENUM_PERFIL_RIESGO InpPerfilRiesgo        = PERFIL_MANUAL; // Perfil de Riesgo Preconfigurado
input ENUM_MODO_PRESET_ACTIVO InpPresetActivo  = PRESET_AUTO;   // Seleccionar Modo (Auto / ORO / EURUSD / S&P 500 / BTC / Manual)
input ENUM_MODO_TENDENCIA InpFiltroTendencia   = TENDENCIA_EMA200_STRICT; // Modo Filtro de Tendencia (EMA 200 H1)

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
double         confianzaBayesianaUltima = 50.0;

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
    // Limpiar cualquier línea previa horizontal o residual en el gráfico
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

    // Calibración inicial de parámetros y Magic Number según activo
    CalibrarParametrosActivo();

    trade.SetExpertMagicNumber(magicEfectivo);
    trade.SetDeviationInPoints(10);
    trade.SetTypeFilling(ORDER_FILLING_FOK);

    // Handles de Indicadores Técnicos
    hSlowEMA = iMA(_Symbol, InpTimeframeRef, 200, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_Chart = iMA(_Symbol, _Period, 200, 0, MODE_EMA, PRICE_CLOSE);
    hATR = iATR(_Symbol, _Period, 14);
    hFractals = iFractals(_Symbol, _Period);
    if (hRSI == INVALID_HANDLE || hRSI == 0)
    {
        hRSI = iRSI(_Symbol, _Period, rsiPeriodEfectivo, PRICE_CLOSE);
    }

    if (hRSI == INVALID_HANDLE || hRSI == 0 || hSlowEMA == INVALID_HANDLE || hEMA_Chart == INVALID_HANDLE || hFractals == INVALID_HANDLE)
    {
        Print("Error inicializando indicadores en v2.3.");
        return (INIT_FAILED);
    }

    // Dibujar indicadores en subventana y gráfico
    SincronizarIndicadoresEnGrafico();

    AplicarPerfilRiesgo();

    // Restablecer operativa si al modificar parámetros la pérdida actual es inferior al nuevo escudo
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

    if (InpMostrarHUD)
    {
        RedibujarHUD();
    }

    if (InpMostrarLineasEstructura)
    {
        ActualizarLineasEstructura();
    }

    Print("Bayesian Strategy Pro v2.3 Iniciado Correctamente. Magic: ", magicEfectivo, " Activo: ", txtActivoDetectado, " Shield: ", shieldPctEfectivo, "%");
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
        takeProfitUSD_Efectivo = 4.0; // Profit ágil y rápido en Forex ($4.00 USD / ~40 pips)
        activarFiltroHorarioEfectivo = true;
        horaInicioEfectivo = 9;
        horaFinEfectivo = 21;
        operarLunesEfectivo = true;
        operarMartesEfectivo = true;
        operarMiercolesEfectivo = true;
        operarJuevesEfectivo = false;
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
        rsiOversoldEfectivo = 30.0;
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

    // Reconstrucción dinámica del RSI handle si cambia el periodo
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

    // 1. Verificar si ya existe RSI en el gráfico
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
    }

    // 2. Insertar RSI oficial en una subventana si no está presente
    if (!tieneRSI)
    {
        if (hRSI == INVALID_HANDLE || hRSI == 0)
        {
            hRSI = iRSI(_Symbol, _Period, rsiPeriodEfectivo, PRICE_CLOSE);
        }
        if (hRSI != INVALID_HANDLE && hRSI != 0)
        {
            ChartIndicatorAdd(0, (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL), hRSI);
        }
    }

    // 3. Eliminar EMAs previas en Ventana Principal (Subventana 0) para forzar la EMA 200 H1 del bot
    int totalMain = ChartIndicatorsTotal(0, 0);
    for (int i = totalMain - 1; i >= 0; i--)
    {
        string name = ChartIndicatorName(0, 0, i);
        if (StringFind(name, "Moving Average") >= 0 || StringFind(name, "MA") >= 0)
        {
            ChartIndicatorDelete(0, 0, name);
        }
    }

    // 4. Insertar EMA 200 oficial en Ventana Principal (Subventana 0) solo si el filtro de tendencia está activado
    if (InpFiltroTendencia == TENDENCIA_EMA200_STRICT)
    {
        int handleParaGrafico = (InpTimeframeRef == _Period) ? hSlowEMA : hEMA_Chart;
        if (handleParaGrafico != INVALID_HANDLE && handleParaGrafico != 0)
        {
            ChartIndicatorAdd(0, 0, handleParaGrafico);
        }
        else if (hEMA_Chart != INVALID_HANDLE && hEMA_Chart != 0)
        {
            ChartIndicatorAdd(0, 0, hEMA_Chart);
        }
    }

    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Asegurar visualización de indicadores                            |
//+------------------------------------------------------------------+
void AsegurarIndicadoresEnGrafico()
{
    static datetime lastSyncTime = 0;
    datetime now = TimeCurrent();

    if (now - lastSyncTime >= 3 || lastSyncTime == 0)
    {
        lastSyncTime = now;
        SincronizarIndicadoresEnGrafico();
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

    // Verificación de Shield Diario
    if (InpActivarShield && ValidarShieldDiario())
    {
        if (InpMostrarHUD) ActualizarValoresHUD();
        return;
    }

    // Trailing Stop & BreakEven
    if (InpActivarBE) GestionarBreakEven();
    if (InpActivarTrailing) GestionarTrailingStop();

    // Actualizar valor en vivo del RSI con validación estricta (0.0 - 100.0)
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

    if (InpMostrarLineasEstructura)
    {
        ActualizarLineasEstructura();
    }

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

    // Comprobar filtro horario operativo y de días
    if (!EsHoraOperativa())
    {
        txtVeredicto = "FUERA DE HORARIO OPERATIVO (" + IntegerToString(horaInicioEfectivo) + ":00 - " + IntegerToString(horaFinEfectivo) + ":00)";
        if (InpMostrarHUD) ActualizarValoresHUD();
        return;
    }

    // Dirección actual de la cesta activa
    int dirCesta = ObtenerDireccionCesta();
    int totalPos = ArraySize(pos);

    // 1. SI NO HAY POSICIONES ABIERTAS -> BUSCAR CAPA 1 POR INFERENCIA BAYESIANA
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

        // Validar filtro de tendencia EMA 200 H1 si está activado
        if (InpFiltroTendencia == TENDENCIA_EMA200_STRICT)
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

        // Ejecutar Capa 1
        if (bayesDir == 1) AbrirCapa(POSITION_TYPE_BUY, InpLoteBase, "Bayes_C1_BUY");
        else if (bayesDir == -1) AbrirCapa(POSITION_TYPE_SELL, InpLoteBase, "Bayes_C1_SELL");
    }
    // 2. SI YA HAY UNA CESTA ACTIVA -> GRID UNIDIRECCIONAL ESTRICTO (SOLO MISMA DIRECCIÓN)
    else if (totalPos > 0 && totalPos < maxCapasEfectivo)
    {
        if (EsMomentoNuevaCapa(dirCesta))
        {
            double loteCapa = InpLoteBase; // Lote constante por rejilla
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

    // Gestión dinámica de TP y BE/Trailing
    GestionarSalidasCesta();

    if (InpMostrarHUD) ActualizarValoresHUD();
}

//+------------------------------------------------------------------+
//| Obtener Dirección de la Cesta Activa                             |
//+------------------------------------------------------------------+
int ObtenerDireccionCesta()
{
    if (ArraySize(pos) == 0) return -1;
    return pos[0].t; // Mantiene la dirección de la Capa 1
}

//+------------------------------------------------------------------+
//| Validar Distancia para Nueva Capa (Unidireccional)              |
//+------------------------------------------------------------------+
bool EsMomentoNuevaCapa(int dirCesta)
{
    int totalPos = ArraySize(pos);
    if (totalPos == 0) return false;

    double lastPrice = pos[totalPos - 1].pr;
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double distPuntos = 0.0;

    if (dirCesta == POSITION_TYPE_BUY)
    {
        distPuntos = (lastPrice - ask) / _Point;
    }
    else if (dirCesta == POSITION_TYPE_SELL)
    {
        distPuntos = (bid - lastPrice) / _Point;
    }

    // Convertir pips a puntos o ajustar escala de resguardo en Bitcoin
    double targetPuntos = distanciaCapasEfectiva;
    string sym = _Symbol;
    StringToUpper(sym);
    if (StringFind(sym, "BTC") >= 0)
    {
        // En BTCUSD la distancia debe ser en USD/Puntos (mínimo 150 pts = $1.50 USD)
        if (targetPuntos < 100.0) targetPuntos = 150.0;
    }
    else
    {
        targetPuntos = distanciaCapasEfectiva * 10.0;
    }

    return (distPuntos >= targetPuntos);
}

//+------------------------------------------------------------------+
//| Abrir Operación de Capa                                         |
//+------------------------------------------------------------------+
void AbrirCapa(ENUM_POSITION_TYPE posType, double lotes, string comentario)
{
    double price = (posType == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    if (posType == POSITION_TYPE_BUY)
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
//| Gestión de Cierre Global en Cesta (TP $8 USD / BE & Trailing)    |
//+------------------------------------------------------------------+
void GestionarSalidasCesta()
{
    int totalPos = ArraySize(pos);
    if (totalPos == 0) return;

    // Target adaptativo en USD según cantidad de capas acumuladas (Escape Dinámico)
    double targetEfectivoUSD = takeProfitUSD_Efectivo;
    if (totalPos >= 8)
    {
        targetEfectivoUSD = 1.50; // Meta de Escape Rápido al acumular 8+ capas ($1.50 USD)
    }
    else if (totalPos >= 5)
    {
        targetEfectivoUSD = takeProfitUSD_Efectivo * 0.5; // Meta Reducida para 5-7 capas ($4.00 - $5.00 USD)
    }

    // Cierre en Meta en USD adaptativa
    if (flotanteActual >= targetEfectivoUSD)
    {
        CerrarTodasLasPosiciones(StringFormat("TakeProfit Cesta Alcanzado ($%.2f USD | Meta: $%.2f)", flotanteActual, targetEfectivoUSD));
        return;
    }

    // Stop Loss Físico Cesta
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

    double minProfitUSD = 1.50; // Beneficio mínimo acumulado para activar BE
    double offsetPuntos = 50.0; // Puntos de protección por encima/debajo de apertura

    if (StringFind(sym, "BTC") >= 0)
    {
        minProfitUSD = 1.50;  // Mínimo $1.50 USD en BTC
        offsetPuntos = 50.0;  // Protege a +$0.50 USD del precio de entrada (50 pts)
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
    if (StringFind(sym, "BTC") >= 0) pipsProtect = 50.0;       // 50 puntos resguardo en BTCUSD ($0.50 USD)
    else if (StringFind(sym, "XAU") >= 0 || StringFind(sym, "GOLD") >= 0) pipsProtect = 20.0; // 20 pips en Oro

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

                // Solo se puede asegurar en BreakEven si la posición individual está en beneficio positivo
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

    // 1. Filtro por Días de la semana
    if (dt.day_of_week == 1 && !operarLunesEfectivo) return false;
    if (dt.day_of_week == 2 && !operarMartesEfectivo) return false;
    if (dt.day_of_week == 3 && !operarMiercolesEfectivo) return false;
    if (dt.day_of_week == 4 && !operarJuevesEfectivo) return false;
    if (dt.day_of_week == 5 && !operarViernesEfectivo) return false;
    if (dt.day_of_week == 6 && !operarSabadoEfectivo) return false;
    if (dt.day_of_week == 0 && !operarDomingoEfectivo) return false;

    // 2. Filtro Horario Operativo (Broker Hours)
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
        equityInicioDia = AccountInfoDouble(ACCOUNT_EQUITY);
        botActivo = true; // Restablecer operativa automáticamente al iniciar nuevo día
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
        // Marquita Amarilla en Máximo (Resistencia) - Tramo corto de 3 velas (i+1 a i-1)
        if (upperFractals[i] > 0.0 && upperFractals[i] < 500000.0 && upperFractals[i] != EMPTY_VALUE)
        {
            string name = LINE_PREFIX + "HIGH_" + IntegerToString(i);
            double price = upperFractals[i];
            datetime startTime = timeBuf[i + 1];
            datetime endTime = timeBuf[i - 1];

            if (ObjectFind(0, name) < 0)
            {
                ObjectCreate(0, name, OBJ_TREND, 0, startTime, price, endTime, price);
            }
            else
            {
                ObjectMove(0, name, 0, startTime, price);
                ObjectMove(0, name, 1, endTime, price);
            }

            ObjectSetInteger(0, name, OBJPROP_COLOR, InpColorEstructura);
            ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
            ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
            lineIdx++;
        }

        // Marquita Amarilla en Mínimo (Soporte) - Tramo corto de 3 velas (i+1 a i-1)
        if (lowerFractals[i] > 0.0 && lowerFractals[i] < 500000.0 && lowerFractals[i] != EMPTY_VALUE)
        {
            string name = LINE_PREFIX + "LOW_" + IntegerToString(i);
            double price = lowerFractals[i];
            datetime startTime = timeBuf[i + 1];
            datetime endTime = timeBuf[i - 1];

            if (ObjectFind(0, name) < 0)
            {
                ObjectCreate(0, name, OBJ_TREND, 0, startTime, price, endTime, price);
            }
            else
            {
                ObjectMove(0, name, 0, startTime, price);
                ObjectMove(0, name, 1, endTime, price);
            }

            ObjectSetInteger(0, name, OBJPROP_COLOR, InpColorEstructura);
            ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
            ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
            lineIdx++;
        }
    }
}

//+------------------------------------------------------------------+
//| Obtener Estado de Sesión de Mercado y Hora de Servidor          |
//+------------------------------------------------------------------+
void ObtenerEstadoSesionYHora(string &txtSesion, string &txtHora, color &clrSesion)
{
    MqlDateTime dt;
    TimeTradeServer(dt);
    txtHora = StringFormat("%02d:%02d", dt.hour, dt.min);

    if (dt.day_of_week == 0 || dt.day_of_week == 6)
    {
        txtSesion = "FIN DE SEMANA";
        clrSesion = clrRed;
        return;
    }

    if (dt.hour >= 8 && dt.hour < 15)
    {
        txtSesion = "LONDRES";
        clrSesion = clrLime;
    }
    else if (dt.hour >= 15 && dt.hour < 22)
    {
        txtSesion = "NUEVA YORK";
        clrSesion = clrDodgerBlue;
    }
    else if (dt.hour >= 0 && dt.hour < 8)
    {
        txtSesion = "ASIA";
        clrSesion = clrGold;
    }
    else
    {
        txtSesion = "FUERA SES";
        clrSesion = clrOrange;
    }
}

//+------------------------------------------------------------------+
//| Creación de Panel Visual HUD Interactivo Original v2.3            |
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
        ObjectSetInteger(0, "BAYES_BG", OBJPROP_XSIZE, 240);
        ObjectSetInteger(0, "BAYES_BG", OBJPROP_YSIZE, 32);
        ObjectSetInteger(0, "BAYES_BG", OBJPROP_BGCOLOR, clrBlack);
        ObjectSetInteger(0, "BAYES_BG", OBJPROP_BORDER_COLOR, clrDarkGoldenrod);
        ObjectSetInteger(0, "BAYES_BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);

        CrearLabel("BAYES_LBL_TITLE", "BAYESIAN PRO v2.3", x + 10, y + 8, clrGold, 9, true);
        CrearBoton(BTN_MINIMIZE_NAME, "[ + ]", x + 195, y + 5, 36, 22, clrDarkGoldenrod);
        return;
    }

    ObjectCreate(0, "BAYES_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_XSIZE, 330);
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_YSIZE, 370);
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_BGCOLOR, clrBlack);
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_BORDER_COLOR, clrDarkGoldenrod);
    ObjectSetInteger(0, "BAYES_BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);

    CrearBoton(BTN_TAB_CTA, "CTA", x + 8, y + 8, 55, 22, (tabActual == TAB_CUENTA) ? clrDarkGoldenrod : clrDarkSlateGray);
    CrearBoton(BTN_TAB_INTEL, "INTEL", x + 67, y + 8, 55, 22, (tabActual == TAB_INTEL) ? clrDarkGoldenrod : clrDarkSlateGray);
    CrearBoton(BTN_TAB_CFG, "CFG", x + 126, y + 8, 55, 22, (tabActual == TAB_CFG) ? clrDarkGoldenrod : clrDarkSlateGray);
    CrearBoton(BTN_TAB_CTRL, "CONTROL", x + 185, y + 8, 70, 22, (tabActual == TAB_CONTROL) ? clrDarkGoldenrod : clrDarkSlateGray);
    CrearBoton(BTN_MINIMIZE_NAME, "[ — ]", x + 262, y + 8, 60, 22, clrDarkRed);

    string titleTab = "MAIKO BAYESIAN PRO v2.3";
    if (tabActual == TAB_CUENTA) titleTab = "PANEL CUENTA & CAJERO";
    else if (tabActual == TAB_INTEL) titleTab = "INTELIGENCIA MERCADO";
    else if (tabActual == TAB_CFG) titleTab = "CONFIGURACIÓN BOT";
    else if (tabActual == TAB_CONTROL) titleTab = "CONTROL OPERATIVO";

    CrearLabel("BAYES_LBL_TITLE", titleTab, x + 12, y + 36, clrGold, 9, true);
    CrearLabel("BAYES_LBL_SESION", "SESIÓN: --", x + 175, y + 36, clrLime, 8, true);
    CrearLabel("BAYES_LBL_HORA", "--:--", x + 280, y + 36, clrCyan, 9, true);

    if (tabActual == TAB_CONTROL)
    {
        CrearLabel("BAYES_LBL_EQ", "EQUITY: $0.00", x + 12, y + 55, clrCyan, 9, true);
        CrearLabel("BAYES_LBL_BAL", "BALANCE: $0.00", x + 12, y + 73, clrWhite, 9, false);
        CrearLabel("BAYES_LBL_CAPAS", "CAPAS ABIERTAS: 0 / 10", x + 12, y + 93, clrYellow, 9, true);
        CrearLabel("BAYES_LBL_ACTIVO", "ACTIVO: " + txtActivoDetectado, x + 12, y + 111, clrOrange, 8, true);
        CrearLabel("BAYES_LBL_RSI", StringFormat("RSI (%d): -- (Compra <=%.0f | Venta >=%.0f)", rsiPeriodEfectivo, rsiOversoldEfectivo, rsiOverboughtEfectivo), x + 12, y + 129, clrLightSkyBlue, 8, true);
        CrearLabel("BAYES_LBL_CONF", "CONFIANZA BAYES: 50.0%", x + 12, y + 147, clrLime, 9, true);
        CrearLabel("BAYES_LBL_SHIELD", "SHIELD HOY: 0.0% / 4.0%", x + 12, y + 165, clrOrange, 8, false);
        CrearLabel("BAYES_LBL_VEREDICT", "ESPERANDO SEÑAL...", x + 12, y + 185, clrGold, 8, true);

        CrearBoton(BTN_PROFILE_NAME, "", x + 12, y + 210, 305, 28, clrDarkGoldenrod);
        ActualizarBotonPerfil();

        CrearBoton(BTN_TRAIL_NAME, stateTrailing ? "TRAIL ON" : "TRAIL OFF", x + 12, y + 248, 95, 26, stateTrailing ? clrDarkGreen : clrMaroon);
        CrearBoton(BTN_BE_NAME, stateBE ? "BE ON" : "BE OFF", x + 113, y + 248, 95, 26, stateBE ? clrDarkGreen : clrMaroon);
        CrearBoton(BTN_ASEG_NAME, "ASEGURAR", x + 214, y + 248, 103, 26, clrDarkSlateGray);

        CrearBoton(BTN_CLOSE_NAME, "CERRAR TODO", x + 12, y + 284, 100, 30, clrDarkRed);
        CrearBoton(BTN_SHIELD_NAME, "SHIELD", x + 118, y + 284, 90, 30, clrDarkBlue);
        CrearBoton(BTN_PAUSE_NAME, statePausado ? "ENCENDER" : "APAGAR", x + 214, y + 284, 103, 30, statePausado ? clrDarkGreen : clrDarkRed);
    }
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
    else if (tabActual == TAB_INTEL)
    {
        CrearLabel("BAYES_LBL_ACTIVO", "ACTIVO DETECTADO: " + txtActivoDetectado, x + 12, y + 65, clrOrange, 9, true);
        CrearLabel("BAYES_LBL_SUB", "CALIBRACIÓN: " + (autoCalibracionActiva ? "AUTO-ADAPTATIVA 🧠" : "MANUAL ⚙️"), x + 12, y + 88, clrWhite, 9, false);
        CrearLabel("BAYES_LBL_CAPAS", "DISTANCIA CAPAS AUTO: " + DoubleToString(distanciaCapasEfectiva, 1) + " PTS", x + 12, y + 110, clrYellow, 9, true);
        CrearLabel("BAYES_LBL_RSI", StringFormat("RSI ACTUAL (%d): -- (S.Venta: <=%.0f | S.Compra: >=%.0f)", rsiPeriodEfectivo, rsiOversoldEfectivo, rsiOverboughtEfectivo), x + 12, y + 132, clrLightSkyBlue, 8, true);
        CrearLabel("BAYES_LBL_CONF", "CONFIANZA BAYESIANA: 50.0%", x + 12, y + 154, clrLime, 9, true);
        CrearLabel("BAYES_LBL_VEREDICT", "VEREDICTO: ESPERANDO SEÑAL...", x + 12, y + 180, clrGold, 8, true);

        CrearBoton(BTN_AUTOCAL_NAME, autoCalibracionActiva ? "🎯 AUTO-CALIBRAR SIMBOLO [ON]" : "🎯 AUTO-CALIBRAR SIMBOLO [OFF]", x + 12, y + 240, 305, 35, autoCalibracionActiva ? clrDarkGreen : clrMaroon);
    }
    else if (tabActual == TAB_CFG)
    {
        CrearLabel("BAYES_LBL_SUB", "CONFIGURACIÓN TÁCTIL Y PERFIL", x + 12, y + 60, clrWhite, 9, true);
        CrearLabel("BAYES_LBL_CAPAS", "CAPAS MÁXIMAS: " + IntegerToString(maxCapasEfectivo) + " CAPAS", x + 12, y + 80, clrYellow, 9, false);
        CrearLabel("BAYES_LBL_SHIELD", "ESCUDO SHIELD DIARIO: " + DoubleToString(shieldPctEfectivo, 1) + "%", x + 12, y + 100, clrOrange, 9, false);
        CrearLabel("BAYES_LBL_ACTIVO", "DISTANCIA ENTRE CAPAS: " + DoubleToString(distanciaCapasEfectiva, 1) + " PTS", x + 12, y + 120, clrCyan, 9, false);
        CrearLabel("BAYES_LBL_MAGIC", "MAGIC NUMBER: " + IntegerToString(magicEfectivo), x + 12, y + 140, clrGold, 9, true);

        CrearBoton(BTN_PROFILE_NAME, "", x + 12, y + 175, 305, 30, clrDarkGoldenrod);
        ActualizarBotonPerfil();

        CrearBoton(BTN_AUTOCAL_NAME, autoCalibracionActiva ? "🎯 MODO AUTO-CALIBRACIÓN [ON]" : "🎯 MODO AUTO-CALIBRACIÓN [OFF]", x + 12, y + 215, 305, 30, autoCalibracionActiva ? clrDarkGreen : clrMaroon);
    }
}

void ActualizarBotonPerfil()
{
    string strTxt = "PERFIL DE RIESGO: MANUAL ⚙️";
    if (perfilActual == PERFIL_CONSERVADOR) strTxt = "PERFIL: CONSERVADOR (MAX 6 CAPAS) 🛡️";
    else if (perfilActual == PERFIL_BALANCEADO) strTxt = "PERFIL: BALANCEADO (MAX 10 CAPAS) ⚖️";
    else if (perfilActual == PERFIL_AGRESIVO) strTxt = "PERFIL: AGRESIVO (MAX 15 CAPAS) 🚀";

    ObjectSetString(0, BTN_PROFILE_NAME, OBJPROP_TEXT, strTxt);
}

void ActualizarValoresHUD()
{
    double eq = AccountInfoDouble(ACCOUNT_EQUITY);
    double bal = AccountInfoDouble(ACCOUNT_BALANCE);
    int abiertas = ArraySize(pos);

    string txtSesion = "";
    string txtHora = "";
    color clrSesion = clrLime;
    ObtenerEstadoSesionYHora(txtSesion, txtHora, clrSesion);

    ObjectSetString(0, "BAYES_LBL_SESION", OBJPROP_TEXT, "SESIÓN: " + txtSesion);
    ObjectSetInteger(0, "BAYES_LBL_SESION", OBJPROP_COLOR, clrSesion);
    ObjectSetString(0, "BAYES_LBL_HORA", OBJPROP_TEXT, txtHora);

    if (hudMinimizado)
    {
        ObjectSetString(0, "BAYES_LBL_TITLE", OBJPROP_TEXT, "BAYES $" + DoubleToString(eq, 2) + " | " + DoubleToString(confianzaBayesianaUltima, 0) + "%");
        return;
    }

    if (tabActual == TAB_CONTROL)
    {
        ObjectSetString(0, "BAYES_LBL_EQ", OBJPROP_TEXT, "EQUITY: $" + DoubleToString(eq, 2));
        ObjectSetString(0, "BAYES_LBL_BAL", OBJPROP_TEXT, "BALANCE: $" + DoubleToString(bal, 2) + " | HOY: " + (ganadoHoy >= 0 ? "+$" : "-$") + DoubleToString(MathAbs(ganadoHoy), 2));
        ObjectSetString(0, "BAYES_LBL_CAPAS", OBJPROP_TEXT, "CAPAS ABIERTAS: " + IntegerToString(abiertas) + " / " + IntegerToString(maxCapasEfectivo));
        ObjectSetString(0, "BAYES_LBL_ACTIVO", OBJPROP_TEXT, "ACTIVO: " + txtActivoDetectado);
        ObjectSetString(0, "BAYES_LBL_RSI", OBJPROP_TEXT, StringFormat("RSI (%d): %.1f (Compra <=%.0f | Venta >=%.0f)", rsiPeriodEfectivo, rsiActualVal, rsiOversoldEfectivo, rsiOverboughtEfectivo));
        ObjectSetString(0, "BAYES_LBL_CONF", OBJPROP_TEXT, "CONFIANZA BAYES: " + DoubleToString(confianzaBayesianaUltima, 1) + "%");
        ObjectSetString(0, "BAYES_LBL_SHIELD", OBJPROP_TEXT, "SHIELD ESTADO: " + txtEstadoCajero);
        ObjectSetString(0, "BAYES_LBL_VEREDICT", OBJPROP_TEXT, txtVeredicto);
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
        ObjectSetString(0, "BAYES_LBL_RSI", OBJPROP_TEXT, StringFormat("RSI ACTUAL (%d): %.1f (S.Venta: <=%.0f | S.Compra: >=%.0f)", rsiPeriodEfectivo, rsiActualVal, rsiOversoldEfectivo, rsiOverboughtEfectivo));
        ObjectSetString(0, "BAYES_LBL_CONF", OBJPROP_TEXT, "CONFIANZA BAYESIANA: " + DoubleToString(confianzaBayesianaUltima, 1) + "%");
        ObjectSetString(0, "BAYES_LBL_VEREDICT", OBJPROP_TEXT, "VEREDICTO: " + txtVeredicto);
    }
    else if (tabActual == TAB_CFG)
    {
        ObjectSetString(0, "BAYES_LBL_CAPAS", OBJPROP_TEXT, "CAPAS MÁXIMAS: " + IntegerToString(maxCapasEfectivo) + " CAPAS");
        ObjectSetString(0, "BAYES_LBL_SHIELD", OBJPROP_TEXT, "ESCUDO SHIELD DIARIO: " + DoubleToString(shieldPctEfectivo, 1) + "%");
        ObjectSetString(0, "BAYES_LBL_ACTIVO", OBJPROP_TEXT, "DISTANCIA ENTRE CAPAS: " + DoubleToString(distanciaCapasEfectiva, 1) + " PTS");
        ObjectSetString(0, "BAYES_LBL_MAGIC", OBJPROP_TEXT, "MAGIC NUMBER: " + IntegerToString(magicEfectivo));
    }
}

void DestruirHUD()
{
    ObjectDelete(0, "BAYES_BG");
    ObjectDelete(0, "BAYES_LBL_TITLE");
    ObjectDelete(0, "BAYES_LBL_SESION");
    ObjectDelete(0, "BAYES_LBL_HORA");
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
    ObjectDelete(0, "BAYES_LBL_MAGIC");

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

//+------------------------------------------------------------------+
//| Eventos de Botón en HUD Original                                 |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    if (id == CHARTEVENT_OBJECT_CLICK)
    {
        if (sparam == BTN_MINIMIZE_NAME)
        {
            hudMinimizado = !hudMinimizado;
            RedibujarHUD();
            ChartRedraw();
        }
        else if (sparam == BTN_TAB_CTA) { tabActual = TAB_CUENTA; RedibujarHUD(); ChartRedraw(); }
        else if (sparam == BTN_TAB_INTEL) { tabActual = TAB_INTEL; RedibujarHUD(); ChartRedraw(); }
        else if (sparam == BTN_TAB_CFG) { tabActual = TAB_CFG; RedibujarHUD(); ChartRedraw(); }
        else if (sparam == BTN_TAB_CTRL) { tabActual = TAB_CONTROL; RedibujarHUD(); ChartRedraw(); }
        else if (sparam == BTN_PROFILE_NAME)
        {
            if (perfilActual == PERFIL_MANUAL) perfilActual = PERFIL_CONSERVADOR;
            else if (perfilActual == PERFIL_CONSERVADOR) perfilActual = PERFIL_BALANCEADO;
            else if (perfilActual == PERFIL_BALANCEADO) perfilActual = PERFIL_AGRESIVO;
            else perfilActual = PERFIL_MANUAL;
            AplicarPerfilRiesgo();
            RedibujarHUD();
            ChartRedraw();
        }
        else if (sparam == BTN_AUTOCAL_NAME)
        {
            autoCalibracionActiva = !autoCalibracionActiva;
            CalibrarParametrosActivo();
            RedibujarHUD();
            ChartRedraw();
        }
        else if (sparam == BTN_TRAIL_NAME) { stateTrailing = !stateTrailing; RedibujarHUD(); ChartRedraw(); }
        else if (sparam == BTN_BE_NAME) { stateBE = !stateBE; RedibujarHUD(); ChartRedraw(); }
        else if (sparam == BTN_ASEG_NAME)
        {
            EjecutarAsegurarGanancias();
            RedibujarHUD();
            ChartRedraw();
        }
        else if (sparam == BTN_PAUSE_NAME) { statePausado = !statePausado; RedibujarHUD(); ChartRedraw(); }
        else if (sparam == BTN_CLOSE_NAME)
        {
            CerrarTodasLasPosiciones("CERRADO MANUAL DESDE HUD");
            txtVeredicto = "CERRADO MANUAL DESDE HUD";
            RedibujarHUD();
            ChartRedraw();
        }
    }
}

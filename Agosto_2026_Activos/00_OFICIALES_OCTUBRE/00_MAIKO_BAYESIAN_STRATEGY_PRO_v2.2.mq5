//+------------------------------------------------------------------+
//|          00_MAIKO_BAYESIAN_STRATEGY_PRO_v2.2.mq5                 |
//|    ALGORITMO BAYESIAN STRATEGY PRO v2.2 - EDICIÓN OFICIAL 2026   |
//|   MOTOR BAYESIANO + MARQUITAS ESTRUCTURALES + HUD TÁCTIL ORIGINAL  |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Maiko Trading Corp."
#property link      "https://www.kopytrading.com"
#property version   "2.20"
#property strict
#property description "Bayesian Strategy Pro v2.2 | HUD Original v2.1 + Marquitas Amarillas de Estructura + Magic 888125 + Filtro EMA200 H1"

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

//============================================================
//  CONFIGURACIÓN DE CUENTA & LICENCIA
//============================================================
input group "=== LICENCIA & SEGURIDAD ==="
input string             InpLicenseKey         = "BAYESIAN-PRO-SEPTIEMBRE-2026";
input string             InpPurchaseID         = "";       // ID de Vinculo (kopytrading.com)
input ENUM_PERFIL_RIESGO InpPerfilRiesgo        = PERFIL_MANUAL; // Perfil de Riesgo Preconfigurado

//============================================================
//  MARQUITAS AMARILLAS DE ESTRUCTURA (NUEVO v2.2)
//============================================================
input group "=== MARQUITAS DE ESTRUCTURA DE MERCADO (NUEVO v2.2) ==="
input bool               InpMostrarLineasEstructura = true;      // Mostrar Marquitas Amarillas en Gráfico
input int                InpPeriodoEstructura       = 12;        // Sensibilidad de Estructura (Velas)
input color              InpColorEstructura         = clrGold;   // Color de Marquitas Amarillas

//============================================================
//  FILTRO HORARIO OPERATIVO
//============================================================
input group "=== FILTRO HORARIO OPERATIVO ==="
input bool               InpActivarFiltroHorario = true;     // Activar Filtro Horario Operativo
input int                InpHoraInicio           = 9;        // Hora Inicio Operativa (Broker 0-23)
input int                InpHoraFin              = 21;       // Hora Fin Operativa (Broker 0-23)

//============================================================
//  FILTRO POR DÍAS DE LA SEMANA
//============================================================
input group "=== FILTRO POR DÍAS DE LA SEMANA ==="
input bool               InpOperarLunes        = true;     // Operar los Lunes
input bool               InpOperarMartes       = false;    // Operar los Martes (Recomendado OFF)
input bool               InpOperarMiercoles    = false;    // Operar los Miércoles (Recomendado OFF)
input bool               InpOperarJueves       = true;     // Operar los Jueves
input bool               InpOperarViernes      = true;     // Operar los Viernes

//============================================================
//  FILTRO DE TENDENCIA DIRECCIONAL
//============================================================
input group "=== FILTRO DE TENDENCIA DIRECCIONAL ==="
input ENUM_MODO_TENDENCIA InpFiltroTendencia   = TENDENCIA_OFF; // Modo Filtro de Tendencia (EMA 200 H1)

//============================================================
//  ESTRATEGIA BAYESIANA & RSI
//============================================================
input group "=== MOTOR BAYESIANO & ENTRADAS ==="
input int                InpRSIPeriod          = 14;       // Periodo RSI
input double             InpRSIOverbought      = 70.0;     // Nivel Sobrecompra (Venta)
input double             InpRSIOversold        = 28.0;     // Nivel Sobreventa (Compra)
input double             InpMinConfidence      = 85.0;     // Confianza Bayesiana Minima (%)
input ENUM_TIMEFRAMES    InpTimeframeRef       = PERIOD_H1;// Tendencia Macro de Referencia (EMA 200)

//============================================================
//  GESTIÓN DE CAPAS (GRID ADAPTATIVO)
//============================================================
input group "=== GESTIÓN DE CAPAS & VOLUMEN ==="
input double             InpLoteBase           = 0.01;     // Lote Base por Operacion
input int                InpMaxCapasManual     = 10;       // Maximo de Capas (Modo Manual)
input double             InpDistanciaCapasPips = 35.0;     // Distancia entre Capas (Pips)
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
input double             InpBEPctTrigger       = 85.0;     // % del TP para activar BE
input bool               InpActivarTrailing    = true;     // Activar Trailing Stop (50%)
input double             InpTrailingStepUSD    = 1.50;     // Paso de Trailing ($)

//============================================================
//  INTERFACE & SISTEMA
//============================================================
input group "=== CONFIGURACIÓN DE PANEL & MAGIC ==="
input bool               InpMostrarHUD         = true;
input int                InpHUD_X              = 15;
input int                InpHUD_Y              = 25;
input ulong              InpMagicNumber        = 888125;   // Magic Number Exclusivo v2.2

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
datetime       lastDayDate = 0;

double         equityInicioDia = 0.0;
double         ganadoHoy = 0.0;
double         flotanteActual = 0.0;
bool           botActivo = true;

int            winsHoy = 0;
int            lossesHoy = 0;

int            maxCapasEfectivo = 10;
double         shieldPctEfectivo = 4.0;
ENUM_PERFIL_RIESGO perfilActual = PERFIL_MANUAL;

double         distanciaCapasEfectiva = 35.0;
string         txtActivoDetectado = "ORO (XAUUSD)";
bool           autoCalibracionActiva = true;

enum ENUM_HUD_TAB { TAB_CUENTA = 0, TAB_INTEL = 1, TAB_CFG = 2, TAB_CONTROL = 3 };
ENUM_HUD_TAB   tabActual = TAB_CONTROL;

bool           stateTrailing = true;
bool           stateBE = true;
bool           statePausado = false;
bool           hudMinimizado = false;

string         txtEstadoCajero = "CAJERO OK";
string         txtVeredicto = "ESPERANDO SEÑAL BAYESIANA...";

double         rsiActualVal = 50.0;
double         confianzaBayesianaUltima = 50.0;

#define BTN_PROFILE_NAME   "BAYES_BTN_PROFILE"
#define BTN_AUTOCAL_NAME   "BAYES_BTN_AUTOCAL"
#define BTN_TRAIL_NAME     "BAYES_BTN_TRAIL"
#define BTN_BE_NAME        "BAYES_BTN_BE"
#define BTN_ASEG_NAME      "BAYES_BTN_ASEG"
#define BTN_CLOSE_NAME     "BAYES_BTN_CLOSE"
#define BTN_SHIELD_NAME    "BAYES_BTN_SHIELD"
#define BTN_PAUSE_NAME     "BAYES_BTN_PAUSE"

#define BTN_TAB_CTA        "BAYES_TAB_CTA"
#define BTN_TAB_INTEL      "BAYES_TAB_INTEL"
#define BTN_TAB_CFG        "BAYES_TAB_CFG"
#define BTN_TAB_CTRL       "BAYES_TAB_CTRL"
#define BTN_MINIMIZE_NAME  "BAYES_BTN_MIN"

#define LINE_PREFIX        "BAYES_LINE_"

//+------------------------------------------------------------------+
//| Expert Initialization Function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetDeviationInPoints(10);
    trade.SetTypeFilling(ORDER_FILLING_FOK);

    // Handles de Indicadores
    hRSI = iRSI(_Symbol, _Period, InpRSIPeriod, PRICE_CLOSE);
    hSlowEMA = iMA(_Symbol, InpTimeframeRef, 200, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_Chart = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
    hATR = iATR(_Symbol, _Period, 14);
    hFractals = iFractals(_Symbol, _Period);

    if (hRSI == INVALID_HANDLE || hSlowEMA == INVALID_HANDLE || hEMA_Chart == INVALID_HANDLE || hFractals == INVALID_HANDLE)
    {
        Print("Error inicializando indicadores en v2.2.");
        return (INIT_FAILED);
    }

    CalibrarParametrosActivo();
    AplicarPerfilRiesgo();

    if (InpMostrarHUD)
    {
        RedibujarHUD();
    }

    if (InpMostrarLineasEstructura)
    {
        ActualizarLineasEstructura();
    }

    Print("Bayesian Strategy Pro v2.2 Iniciado Correctamente. Magic: ", InpMagicNumber);
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
//| Auto-Calibración por Activo                                       |
//+------------------------------------------------------------------+
void CalibrarParametrosActivo()
{
    string sym = _Symbol;
    StringToUpper(sym);

    if (StringFind(sym, "XAU") >= 0 || StringFind(sym, "GOLD") >= 0)
    {
        distanciaCapasEfectiva = 35.0;
        txtActivoDetectado = "ORO (XAUUSD)";
        autoCalibracionActiva = true;
    }
    else if (StringFind(sym, "BTC") >= 0)
    {
        distanciaCapasEfectiva = 150.0;
        txtActivoDetectado = "BITCOIN (BTCUSD)";
        autoCalibracionActiva = true;
    }
    else if (StringFind(sym, "EURUSD") >= 0 || StringFind(sym, "GBPUSD") >= 0)
    {
        distanciaCapasEfectiva = 18.0;
        txtActivoDetectado = "FOREX " + sym;
        autoCalibracionActiva = true;
    }
    else
    {
        distanciaCapasEfectiva = InpDistanciaCapasPips;
        txtActivoDetectado = sym;
        autoCalibracionActiva = false;
    }
}

//+------------------------------------------------------------------+
//| Aplicar Perfil de Riesgo                                         |
//+------------------------------------------------------------------+
void AplicarPerfilRiesgo()
{
    perfilActual = InpPerfilRiesgo;

    switch (perfilActual)
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
        case PERFIL_MANUAL:
        default:
            maxCapasEfectivo = InpMaxCapasManual;
            shieldPctEfectivo = InpShieldPctManual;
            break;
    }
}

//+------------------------------------------------------------------+
//| Verificación de Filtro Horario                                   |
//+------------------------------------------------------------------+
bool EsHoraOperativa()
{
    if (!InpActivarFiltroHorario) return true;
    
    MqlDateTime dt;
    TimeCurrent(dt);
    
    if (InpHoraInicio <= InpHoraFin)
    {
        return (dt.hour >= InpHoraInicio && dt.hour < InpHoraFin);
    }
    else
    {
        return (dt.hour >= InpHoraInicio || dt.hour < InpHoraFin);
    }
}

//+------------------------------------------------------------------+
//| Verificación de Filtro de Días                                   |
//+------------------------------------------------------------------+
bool EsDiaOperativo()
{
    MqlDateTime dt;
    TimeCurrent(dt);

    switch (dt.day_of_week)
    {
        case 1: return InpOperarLunes;
        case 2: return InpOperarMartes;
        case 3: return InpOperarMiercoles;
        case 4: return InpOperarJueves;
        case 5: return InpOperarViernes;
        default: return false;
    }
}

//+------------------------------------------------------------------+
//| Dibujar Marquitas Amarillas de Estructura (NUEVO v2.2)           |
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
        if (upperFractals[i] != EMPTY_VALUE && upperFractals[i] > 0)
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
        if (lowerFractals[i] != EMPTY_VALUE && lowerFractals[i] > 0)
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
//| Expert Tick Function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    ActualizarMetricasDia();

    if (VerificarCortafuegos()) return;

    if (InpActivarBE) GestionarBreakEven();
    if (InpActivarTrailing) GestionarTrailingStop();

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

    if (!EsDiaOperativo())
    {
        txtVeredicto = "DÍA NO OPERATIVO (FILTRO DÍAS)";
        if (InpMostrarHUD) ActualizarValoresHUD();
        return;
    }

    if (!EsHoraOperativa())
    {
        txtVeredicto = "FUERA DE HORARIO OPERATIVO (" + IntegerToString(InpHoraInicio) + ":00 - " + IntegerToString(InpHoraFin) + ":00)";
        if (InpMostrarHUD) ActualizarValoresHUD();
        return;
    }

    double confidence = 0.0;
    int direction = CalcularInferenciaBayesiana(confidence);
    confianzaBayesianaUltima = confidence;

    if (direction == 0 || confidence < InpMinConfidence)
    {
        txtVeredicto = "ESPERANDO CONFIRMACIÓN (" + DoubleToString(confidence, 1) + "% / " + DoubleToString(InpMinConfidence, 1) + "%)";
        if (InpMostrarHUD) ActualizarValoresHUD();
        return;
    }

    // Filtro de Tendencia Direccional EMA200 H1
    if (InpFiltroTendencia == TENDENCIA_EMA200_STRICT)
    {
        double slowEMA[];
        ArraySetAsSeries(slowEMA, true);
        if (CopyBuffer(hSlowEMA, 0, 0, 1, slowEMA) > 0)
        {
            double closePrice = iClose(_Symbol, _Period, 1);
            if (direction == 1 && closePrice < slowEMA[0])
            {
                txtVeredicto = "COMPRA BLOQUEADA POR FILTRO EMA200 H1";
                if (InpMostrarHUD) ActualizarValoresHUD();
                return;
            }
            if (direction == -1 && closePrice > slowEMA[0])
            {
                txtVeredicto = "VENTA BLOQUEADA POR FILTRO EMA200 H1";
                if (InpMostrarHUD) ActualizarValoresHUD();
                return;
            }
        }
    }

    int capasAbiertas = ContarPosicionesMagic();

    if (capasAbiertas >= maxCapasEfectivo)
    {
        txtVeredicto = "LÍMITE DE CAPAS ALCANZADO (" + IntegerToString(capasAbiertas) + "/" + IntegerToString(maxCapasEfectivo) + ")";
        if (InpMostrarHUD) ActualizarValoresHUD();
        return;
    }

    if (capasAbiertas == 0)
    {
        AbrirPosicion(direction, InpLoteBase, "Bayes v2.2 C1");
    }
    else
    {
        if (EsMomentoNuevaCapa(direction))
        {
            double loteCapa = InpLoteBase;
            AbrirPosicion(direction, loteCapa, "Bayes v2.2 C" + IntegerToString(capasAbiertas + 1));
        }
    }

    if (InpMostrarHUD) ActualizarValoresHUD();
}

//+------------------------------------------------------------------+
//| Chart Event Function (HUD Interactivo Original)                  |
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
            CerrarTodasLasPosiciones();
            txtVeredicto = "CERRADO MANUAL DESDE HUD";
            RedibujarHUD();
        }
    }
}

//+------------------------------------------------------------------+
//| Actualizar Métricas Diarias                                       |
//+------------------------------------------------------------------+
void ActualizarMetricasDia()
{
    ganadoHoy = 0.0;
    winsHoy = 0;
    lossesHoy = 0;

    datetime inicioHoy = iTime(_Symbol, PERIOD_D1, 0);
    if (HistorySelect(inicioHoy, TimeCurrent()))
    {
        int deals = HistoryDealsTotal();
        for (int i = 0; i < deals; i++)
        {
            ulong ticket = HistoryDealGetTicket(i);
            if (ticket > 0)
            {
                if (HistoryDealGetInteger(ticket, DEAL_MAGIC) == InpMagicNumber &&
                    HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol &&
                    HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
                {
                    double p = HistoryDealGetDouble(ticket, DEAL_PROFIT) +
                               HistoryDealGetDouble(ticket, DEAL_SWAP) +
                               HistoryDealGetDouble(ticket, DEAL_COMMISSION);
                    ganadoHoy += p;
                    if (p > 0) winsHoy++;
                    else if (p < 0) lossesHoy++;
                }
            }
        }
    }

    MqlDateTime dt; TimeCurrent(dt);
    if (dt.day != lastDayDate)
    {
        lastDayDate = dt.day;
        equityInicioDia = AccountInfoDouble(ACCOUNT_EQUITY) - ganadoHoy;
        botActivo = true;
        txtEstadoCajero = "CAJERO OK";
        txtVeredicto = "NUEVA SESIÓN INICIADA";
    }

    flotanteActual = 0.0;
    int posCount = PositionsTotal();
    for (int i = 0; i < posCount; i++)
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
//| Verificar Shield Diario & Cortafuegos                             |
//+------------------------------------------------------------------+
bool VerificarCortafuegos()
{
    if (!InpActivarShield || shieldPctEfectivo <= 0) return false;

    double maxPerdidaPermitida = equityInicioDia * (shieldPctEfectivo / 100.0);
    double resultadoTotalHoy = ganadoHoy + flotanteActual;

    if (resultadoTotalHoy <= -maxPerdidaPermitida)
    {
        CerrarTodasLasPosiciones();
        botActivo = false;
        txtEstadoCajero = "🛑 SHIELD ACTIVADO (-" + DoubleToString(shieldPctEfectivo, 1) + "%)";
        txtVeredicto = "CORTAFUEGOS: PÉRDIDA MÁXIMA ALCANZADA HOY";
        return true;
    }

    if (InpMetaDiariaUSD > 0 && ganadoHoy >= InpMetaDiariaUSD)
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
int CalcularInferenciaBayesiana(double &confidence)
{
    double rsiBuffer[];
    ArraySetAsSeries(rsiBuffer, true);
    if (CopyBuffer(hRSI, 0, 1, 3, rsiBuffer) < 3) return 0;

    double rsiCurr = rsiBuffer[0];
    double rsiPrev = rsiBuffer[1];
    rsiActualVal = rsiCurr;

    double priorBuy = 0.50;
    double priorSell = 0.50;

    double pSignalGivenBuy = 0.50;
    double pSignalGivenSell = 0.50;

    if (rsiCurr < InpRSIOversold)
    {
        pSignalGivenBuy = 0.88;
        pSignalGivenSell = 0.12;
    }
    else if (rsiCurr > InpRSIOverbought)
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
//| Abrir Posición                                                   |
//+------------------------------------------------------------------+
bool AbrirPosicion(int direction, double lotes, string comentario)
{
    double price = (direction == 1) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double sl = 0.0;
    double tp = 0.0;

    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    if (tickValue <= 0) tickValue = 1.0;

    if (InpStopLoss_USD > 0)
    {
        double slPoints = (InpStopLoss_USD / (lotes * tickValue));
        sl = (direction == 1) ? price - (slPoints * point) : price + (slPoints * point);
        sl = NormalizeDouble(sl, _Digits);
    }

    if (InpTakeProfit_USD > 0)
    {
        double tpPoints = (InpTakeProfit_USD / (lotes * tickValue));
        tp = (direction == 1) ? price + (tpPoints * point) : price - (tpPoints * point);
        tp = NormalizeDouble(tp, _Digits);
    }

    ENUM_ORDER_TYPE orderType = (direction == 1) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
    return trade.PositionOpen(_Symbol, orderType, lotes, price, sl, tp, comentario);
}

//+------------------------------------------------------------------+
//| Verificar Condición de Nueva Capa                                |
//+------------------------------------------------------------------+
bool EsMomentoNuevaCapa(int direction)
{
    double ultimaPrecio = 0.0;
    datetime ultimaHora = 0;

    int total = PositionsTotal();
    for (int i = 0; i < total; i++)
    {
        if (posInfo.SelectByIndex(i))
        {
            if (posInfo.Symbol() == _Symbol && posInfo.Magic() == InpMagicNumber)
            {
                if (posInfo.Time() > ultimaHora)
                {
                    ultimaHora = posInfo.Time();
                    ultimaPrecio = posInfo.PriceOpen();
                }
            }
        }
    }

    if (ultimaPrecio <= 0) return false;

    double actualPrice = (direction == 1) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double pipsDiff = MathAbs(actualPrice - ultimaPrecio) / (_Point * 10.0);

    return (pipsDiff >= distanciaCapasEfectiva);
}

//+------------------------------------------------------------------+
//| Contar Capas Abiertas                                            |
//+------------------------------------------------------------------+
int ContarPosicionesMagic()
{
    int count = 0;
    int total = PositionsTotal();
    for (int i = 0; i < total; i++)
    {
        if (posInfo.SelectByIndex(i))
        {
            if (posInfo.Symbol() == _Symbol && posInfo.Magic() == InpMagicNumber) count++;
        }
    }
    return count;
}

//+------------------------------------------------------------------+
//| Cerrar Todas las Posiciones                                       |
//+------------------------------------------------------------------+
void CerrarTodasLasPosiciones()
{
    int total = PositionsTotal();
    for (int i = total - 1; i >= 0; i--)
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
//| Asegurar Ganancias (BE en todas las capas)                        |
//+------------------------------------------------------------------+
void EjecutarAsegurarGanancias()
{
    int total = PositionsTotal();
    for (int i = 0; i < total; i++)
    {
        if (posInfo.SelectByIndex(i))
        {
            if (posInfo.Symbol() == _Symbol && posInfo.Magic() == InpMagicNumber)
            {
                double openPrice = posInfo.PriceOpen();
                double tp = posInfo.TakeProfit();
                if (posInfo.PositionType() == POSITION_TYPE_BUY)
                {
                    double newSL = NormalizeDouble(openPrice + (10 * _Point), _Digits);
                    trade.PositionModify(posInfo.Ticket(), newSL, tp);
                }
                else if (posInfo.PositionType() == POSITION_TYPE_SELL)
                {
                    double newSL = NormalizeDouble(openPrice - (10 * _Point), _Digits);
                    trade.PositionModify(posInfo.Ticket(), newSL, tp);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Gestión BreakEven Inteligente                                    |
//+------------------------------------------------------------------+
void GestionarBreakEven()
{
    if (!stateBE) return;

    int total = PositionsTotal();
    for (int i = 0; i < total; i++)
    {
        if (posInfo.SelectByIndex(i))
        {
            if (posInfo.Symbol() == _Symbol && posInfo.Magic() == InpMagicNumber)
            {
                double openPrice = posInfo.PriceOpen();
                double tp = posInfo.TakeProfit();
                double sl = posInfo.StopLoss();
                double currentPrice = posInfo.PriceCurrent();

                if (tp <= 0) continue;

                double totalDist = MathAbs(tp - openPrice);
                double currentDist = MathAbs(currentPrice - openPrice);
                double pctTarget = (currentDist / totalDist) * 100.0;

                if (pctTarget >= InpBEPctTrigger)
                {
                    if (posInfo.PositionType() == POSITION_TYPE_BUY)
                    {
                        double newSL = NormalizeDouble(openPrice + (20 * _Point), _Digits);
                        if (sl < openPrice) trade.PositionModify(posInfo.Ticket(), newSL, tp);
                    }
                    else if (posInfo.PositionType() == POSITION_TYPE_SELL)
                    {
                        double newSL = NormalizeDouble(openPrice - (20 * _Point), _Digits);
                        if (sl > openPrice || sl == 0) trade.PositionModify(posInfo.Ticket(), newSL, tp);
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Gestión Trailing Stop Dinámico                                   |
//+------------------------------------------------------------------+
void GestionarTrailingStop()
{
    if (!stateTrailing) return;

    int total = PositionsTotal();
    for (int i = 0; i < total; i++)
    {
        if (posInfo.SelectByIndex(i))
        {
            if (posInfo.Symbol() == _Symbol && posInfo.Magic() == InpMagicNumber)
            {
                double profit = posInfo.Profit();
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
//| Creación de Panel Visual HUD Interactivo Original v2.1            |
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
        ObjectSetInteger(0, "BAYES_BG", OBJPROP_YSIZE, 32);
        ObjectSetInteger(0, "BAYES_BG", OBJPROP_BGCOLOR, clrBlack);
        ObjectSetInteger(0, "BAYES_BG", OBJPROP_BORDER_COLOR, clrDarkGoldenrod);
        ObjectSetInteger(0, "BAYES_BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);

        CrearLabel("BAYES_LBL_TITLE", "BAYESIAN PRO v2.2", x + 10, y + 8, clrGold, 9, true);
        CrearBoton(BTN_MINIMIZE_NAME, "[ + ]", x + 175, y + 5, 36, 22, clrDarkGoldenrod);
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

    string titleTab = "BAYESIAN STRATEGY PRO v2.2";
    if (tabActual == TAB_CUENTA) titleTab = "PANEL DE CUENTA & CAJERO";
    else if (tabActual == TAB_INTEL) titleTab = "INTELIGENCIA & MERCADO";
    else if (tabActual == TAB_CFG) titleTab = "CONFIGURACIÓN DE BOT";
    else if (tabActual == TAB_CONTROL) titleTab = "CONTROL DE OPERACIONES";

    CrearLabel("BAYES_LBL_TITLE", titleTab, x + 12, y + 38, clrGold, 9, true);

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
        CrearLabel("BAYES_LBL_RSI", "RSI ACTUAL (14): -- (Compra <=30 | Venta >=70)", x + 12, y + 132, clrLightSkyBlue, 8, true);
        CrearLabel("BAYES_LBL_CONF", "CONFIANZA BAYESIANA: 50.0%", x + 12, y + 154, clrLime, 9, true);
        CrearLabel("BAYES_LBL_VEREDICT", "VEREDICTO: ESPERANDO SEÑAL...", x + 12, y + 180, clrGold, 8, true);

        CrearBoton(BTN_AUTOCAL_NAME, autoCalibracionActiva ? "🎯 AUTO-CALIBRAR SIMBOLO [ON]" : "🎯 AUTO-CALIBRAR SIMBOLO [OFF]", x + 12, y + 240, 305, 35, autoCalibracionActiva ? clrDarkGreen : clrMaroon);
    }
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
    int abiertas = ContarPosicionesMagic();

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
        ObjectSetString(0, "BAYES_LBL_ACTIVO", OBJPROP_TEXT, "ACTIVO: " + txtActivoDetectado + (autoCalibracionActiva ? " [AUTO OK 🧠]" : " [MANUAL]"));
        ObjectSetString(0, "BAYES_LBL_RSI", OBJPROP_TEXT, "RSI (14): " + DoubleToString(rsiActualVal, 1) + " (Compra <=30 | Venta >=70)");
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
//+------------------------------------------------------------------+

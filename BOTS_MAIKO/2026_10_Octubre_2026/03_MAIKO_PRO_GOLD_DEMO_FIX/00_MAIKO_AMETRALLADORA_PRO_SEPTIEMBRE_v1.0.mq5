//+------------------------------------------------------------------+
//|         00_MAIKO_AMETRALLADORA_PRO_SEPTIEMBRE_v1.0.mq5          |
//|    ALGORITMO AMETRALLADORA PRO - EDICIÓN OFICIAL SEPTIEMBRE      |
//|   SL/TP FÍSICO EN BROKER + CAJERO CALIBRADO + ADAPTATIVO AÑOS    |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Maiko Trading Corp."
#property link      "https://www.kopytrading.com"
#property version   "1.00"
#property strict
#property description "La Ametralladora Pro | Edicion Oficial Septiembre 2026 | SL/TP Fisico Broker | Cajero Calibrado"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//============================================================
//  CONFIGURACIÓN DE CUENTA & LICENCIA
//============================================================
input group "=== LICENCIA & SEGURIDAD ==="
input string   InpLicenseKey         = "AMETRALLADORA-SEPTIEMBRE-2026";
input string   InpPurchaseID         = "";       // ID de Vinculo (Ver Marketplace kopytrading.com)
input bool     InpEsCuentaCent       = false;    // Activar si es cuenta CENT ($100 = 10,000 unidades)

//============================================================
//  ESTRATEGIA & ENTRADAS
//============================================================
input group "=== ESTRATEGIA AMETRALLADORA (MOMENTUM) ==="
input ENUM_TIMEFRAMES InpTimeframeRef = PERIOD_H1;  // Tendencia Macro de referencia
input int      InpEMAFast            = 50;        // Media rapida H1
input int      InpEMASlow            = 200;       // Media lenta H1 (Filtro Tendencia)
input bool     InpSoloAFavorTendencia= true;      // Filtrar entradas estrictamente a favor de EMA200
input int      InpMomentumCandles    = 3;         // Velas M15/M5 para medir fuerza
input int      InpMomentumRequired   = 2;         // Cuantas velas coinciden (ej: 2 de 3)
input int      InpCooldownSeconds    = 60;        // Espera tras cierre de ciclo (seg)

//============================================================
//  GESTIÓN DE RIESGO & PROTECCIÓN FÍSICA BROKER
//============================================================
input group "=== GESTIÓN DE RIESGO & SL/TP FÍSICO EN BROKER ==="
input double   InpLoteBase           = 0.01;      // Lote base por operacion (0.01 recomendado / $1k)
input double   InpStopLoss_USD       = 12.00;     // 🛡️ STOP LOSS FÍSICO EN BROKER ($ por pos)
input double   InpTakeProfit_USD     = 4.00;      // 🎯 TAKE PROFIT FÍSICO EN BROKER ($ por pos)
input int      InpMaxPosiciones      = 4;         // Maximo de posiciones abiertas simultaneas
input double   InpProfitCicloUSD     = 3.50;      // Cerrar todo el ciclo al acumular ($)

//============================================================
//  SISTEMA DE RECUPERACIÓN INTELIGENTE (SIN CONGELAMIENTO)
//============================================================
input group "=== RECUPERACIÓN INTELIGENTE ==="
input bool     InpActivarRecuperacion= true;      // Activar entrada de apoyo si la principal se gira
input double   InpGatilloPerdida_USD = 6.00;      // $ Perdida flotante para activar entrada de apoyo
input double   InpLoteApoyo          = 0.02;      // Lote de la operacion de apoyo (0.02 recomendado)
input double   InpDistanciaApoyo_Pips= 30.0;      // Distancia en pips para gatillo de apoyo (30.0 pips)

//============================================================
//  EL CAJERO (PROTECCIÓN DIARIA DE CAPITAL)
//============================================================
input group "=== EL CAJERO (PROTECCIÓN DIARIA REAL) ==="
input bool     InpActivarCajero      = true;      // Activar cortafuegos diario
input double   InpMaxPerdidaDiariaUSD= 20.00;     // 🛑 Pérdida Máxima Diaria Tolerada ($)
input double   InpMetaDiariaUSD      = 50.00;     // 🎯 Beneficio Meta Diario ($)

//============================================================
//  PROTECCIÓN BE & TRAILING
//============================================================
input group "=== PROTECCIÓN DINÁMICA (BE & TRAILING) ==="
input bool     InpActivarBE          = true;      // Activar Break Even dinamico
input double   InpActivarBETrasUSD   = 2.20;      // Activar BE tras alcanzar ($)
input double   InpProtegerBE_USD     = 0.60;      // Proteger ($) tras activar BE
input bool     InpActivarTrailing    = false;     // Activar Trailing Stop (false recomendado para TP $4)
input double   InpTrailingStartUSD   = 3.00;      // Iniciar Trailing tras ($)
input double   InpTrailingStepUSD    = 0.80;      // Paso de Trailing ($)

//============================================================
//  FILTROS DE SESIÓN Y NOTICIAS
//============================================================
input group "=== FILTROS OPERATIVOS ==="
input bool     InpUsarFiltroHorario  = true;      // Usar filtro de sesion liquida
input int      InpHoraInicioSesion   = 8;         // Hora inicio (08:00 servidor)
input int      InpHoraFinSesion      = 21;        // Hora fin (21:00 servidor)
input bool     InpUsarFiltroNoticias = true;      // Pausar trading en noticias USD
input int      InpMinsAntesNoticia   = 30;        // Minutos antes de noticia de alto impacto
input int      InpMinsDespuesNoticia = 30;        // Minutos despues de noticia de alto impacto

//============================================================
//  INTERFACE & SISTEMA
//============================================================
input group "=== CONFIGURACIÓN DE PANEL & MAGIC ==="
input bool     InpMostrarHUD         = true;
input int      InpHUD_X              = 15;
input int      InpHUD_Y              = 25;
input ulong    InpMagicNumber        = 777115;

//============================================================
//  VARIABLES GLOBALES Y CLASES
//============================================================
CTrade         trade;
CPositionInfo  posInfo;
COrderInfo     orderInfo;

int            hSlowEMA              = INVALID_HANDLE;
int            hFastEMA              = INVALID_HANDLE;
int            hATR                  = INVALID_HANDLE;

bool           botActivo             = true;
datetime       cooldownEndTime       = 0;
datetime       lastApoyoTime         = 0;
datetime       eaStartTime           = 0;
datetime       ultimoDiaCajero       = 0;
double         ganadoHoy             = 0;
double         flotanteActual        = 0;
double         atrActual             = 0;
string         txtModo               = "EN ESPERA";
string         txtVeredicto           = "INICIALIZANDO...";
string         txtEstadoCajero       = "CAJERO OK";

#define HUD_PREFIX "MAIKO_AMT_PRO_"

//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit()
{
    eaStartTime = TimeCurrent();
    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetTypeFillingBySymbol(_Symbol);

    // Forzar la visualización en el gráfico de las líneas verdes/rojas de operaciones (Niveles de Trading)
    ChartSetInteger(0, CHART_SHOW_TRADE_LEVELS, true);

    hSlowEMA = iMA(_Symbol, InpTimeframeRef, InpEMASlow, 0, MODE_EMA, PRICE_CLOSE);
    hFastEMA = iMA(_Symbol, InpTimeframeRef, InpEMAFast, 0, MODE_EMA, PRICE_CLOSE);
    hATR     = iATR(_Symbol, _Period, 14);

    if (hSlowEMA == INVALID_HANDLE || hFastEMA == INVALID_HANDLE || hATR == INVALID_HANDLE) {
        Print("Error inicializando indicadores de Ametralladora Septiembre");
        return(INIT_FAILED);
    }

    botActivo = true;
    txtEstadoCajero = "CAJERO OK";

    if (InpMostrarHUD) {
        CrearHUD();
    }
    
    Print("00_MAIKO_AMETRALLADORA_PRO_SEPTIEMBRE_v1.0 cargado con éxito. Magic: ", InpMagicNumber);
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| OnDeinit                                                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    if (hSlowEMA != INVALID_HANDLE) IndicatorRelease(hSlowEMA);
    if (hFastEMA != INVALID_HANDLE) IndicatorRelease(hFastEMA);
    if (hATR != INVALID_HANDLE)     IndicatorRelease(hATR);
    ObjectsDeleteAll(0, HUD_PREFIX);
}

//+------------------------------------------------------------------+
//| OnTick                                                           |
//+------------------------------------------------------------------+
void OnTick()
{
    // Actualizar datos de mercado
    ActualizarMétricas();

    // Comprobar Cajero Diario
    if (EvaluarCajeroDiario()) {
        if (InpMostrarHUD) ActualizarHUD();
        return;
    }

    // Gestionar posiciones existentes (BE, Trailing, TP global de ciclo)
    GestionarPosicionesAbiertas();

    // Evaluar nuevas entradas si no hay bloqueo
    if (botActivo && ContarPosicionesMagic() < InpMaxPosiciones) {
        EvaluarNuevasEntradas();
    }

    if (InpMostrarHUD) ActualizarHUD();
}

//+------------------------------------------------------------------+
//| Actualizar Métricas de Cuenta y Mercado                          |
//+------------------------------------------------------------------+
void ActualizarMétricas()
{
    double atrBuf[1];
    if (CopyBuffer(hATR, 0, 0, 1, atrBuf) > 0) atrActual = atrBuf[0];

    flotanteActual = 0;
    int total = PositionsTotal();
    for (int i = total - 1; i >= 0; i--) {
        if (posInfo.SelectByIndex(i) && posInfo.Symbol() == _Symbol && posInfo.Magic() == InpMagicNumber) {
            flotanteActual += posInfo.Profit() + posInfo.Swap();
        }
    }

    ganadoHoy = CalcularGanadoHoy();
}

//+------------------------------------------------------------------+
//| Calcular Beneficio Acumulado Hoy                                 |
//+------------------------------------------------------------------+
double CalcularGanadoHoy()
{
    MqlDateTime dt;
    TimeCurrent(dt);
    dt.hour = 0; dt.min = 0; dt.sec = 0;
    datetime inicioHoy = StructToTime(dt);

    double res = 0;
    if (!HistorySelect(inicioHoy, TimeCurrent())) return 0;
    int totalDeals = HistoryDealsTotal();
    for (int i = totalDeals - 1; i >= 0; i--) {
        ulong ticket = HistoryDealGetTicket(i);
        datetime dealTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
        if (dealTime < inicioHoy) continue; // EXCLUIR ESTRICTAMENTE DÍAS ANTERIORES
        if (HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol && HistoryDealGetInteger(ticket, DEAL_MAGIC) == InpMagicNumber) {
            res += HistoryDealGetDouble(ticket, DEAL_PROFIT) + HistoryDealGetDouble(ticket, DEAL_SWAP) + HistoryDealGetDouble(ticket, DEAL_COMMISSION);
        }
    }
    return res;
}

//+------------------------------------------------------------------+
//| Evaluar El Cajero (Cortafuegos Diario de Riesgo)                 |
//+------------------------------------------------------------------+
bool EvaluarCajeroDiario()
{
    if (!InpActivarCajero) return false;

    // Reset diario a las 00:00
    MqlDateTime dt;
    TimeCurrent(dt);
    if (dt.day != ultimoDiaCajero) {
        ultimoDiaCajero = dt.day;
        botActivo = true;
        txtEstadoCajero = "CAJERO OK";
        txtVeredicto = "EN ESPERA DE SEÑAL...";
    }

    // Si la pérdida acumulada hoy NO supera el límite actual de pérdida, desbloquear
    if (ganadoHoy + flotanteActual > -InpMaxPerdidaDiariaUSD && ganadoHoy < InpMetaDiariaUSD) {
        if (!botActivo && StringFind(txtEstadoCajero, "STOP DÍA") >= 0) {
            botActivo = true;
            txtEstadoCajero = "CAJERO OK";
            txtVeredicto = "EN ESPERA DE SEÑAL...";
        }
    }

    if (!botActivo) return true; // Si se apagó por riesgo hoy, permanece apagado hasta las 00:00 de mañana

    // Pérdida máxima diaria alcanzada
    if (ganadoHoy + flotanteActual <= -InpMaxPerdidaDiariaUSD) {
        CerrarTodasLasPosiciones();
        botActivo = false;
        txtEstadoCajero = "🛑 STOP DÍA (-$" + DoubleToString(InpMaxPerdidaDiariaUSD, 2) + ")";
        txtVeredicto = "CAJERO CERRÓ LA SESIÓN POR RIESGO";
        return true;
    }

    // Meta diaria alcanzada
    if (ganadoHoy >= InpMetaDiariaUSD) {
        CerrarTodasLasPosiciones();
        botActivo = false;
        txtEstadoCajero = "🎯 META DÍA (+$" + DoubleToString(InpMetaDiariaUSD, 2) + ")";
        txtVeredicto = "OBJETIVO DIARIO ALCANZADO";
        return true;
    }

    return false;
}

//+------------------------------------------------------------------+
//| Normalizar Volumen según paso permitido por el Broker           |
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

//+------------------------------------------------------------------+
//| Convertir USD Objetivo a Distancia en Precio para el Símbolo    |
//+------------------------------------------------------------------+
double USDtoPriceDelta(double usdTarget, double lotSize)
{
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

    if (tickValue <= 0 || tickSize <= 0 || lotSize <= 0) return 4.0;
    double usdPerPriceUnit = lotSize * (tickValue / tickSize);
    if (usdPerPriceUnit <= 0) return 4.0;

    return (usdTarget / usdPerPriceUnit);
}

//+------------------------------------------------------------------+
//| Evaluar Nuevas Entradas (Ametralladora Momentum)                 |
//+------------------------------------------------------------------+
void EvaluarNuevasEntradas()
{
    if (TimeCurrent() < cooldownEndTime) {
        txtVeredicto = "EN COOLDOWN TRAS CICLO...";
        return;
    }

    if (InpUsarFiltroHorario) {
        MqlDateTime dt; TimeCurrent(dt);
        if (dt.hour < InpHoraInicioSesion || dt.hour >= InpHoraFinSesion) {
            txtVeredicto = "FUERA DE SESIÓN OPERATIVA";
            return;
        }
    }

    if (InpUsarFiltroNoticias && HayNoticiaUSD()) {
        txtVeredicto = "PAUSA POR NOTICIA USD";
        return;
    }

    // Dirección de la EMA 200 en H1
    double emaSlow[1], emaFast[1];
    if (CopyBuffer(hSlowEMA, 0, 0, 1, emaSlow) <= 0 || CopyBuffer(hFastEMA, 0, 0, 1, emaFast) <= 0) return;

    bool tendenciaAlcista = (emaFast[0] > emaSlow[0]);
    bool tendenciaBajista = (emaFast[0] < emaSlow[0]);

    // Medición de Momentum en velas
    int cUp = 0, cDn = 0;
    for (int i = 1; i <= InpMomentumCandles; i++) {
        double o = iOpen(_Symbol, _Period, i);
        double c = iClose(_Symbol, _Period, i);
        if (c > o) cUp++;
        if (c < o) cDn++;
    }

    bool entradaBuy  = (cUp >= InpMomentumRequired) && (!InpSoloAFavorTendencia || tendenciaAlcista);
    bool entradaSell = (cDn >= InpMomentumRequired) && (!InpSoloAFavorTendencia || tendenciaBajista);

    int posAbiertas = ContarPosicionesMagic();
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    // Entrada Inicial cuando no hay posiciones
    if (posAbiertas == 0) {
        double slDelta = USDtoPriceDelta(InpStopLoss_USD, InpLoteBase);
        double tpDelta = USDtoPriceDelta(InpTakeProfit_USD, InpLoteBase);

        if (entradaBuy) {
            double sl = NormalizeDouble(ask - slDelta, _Digits);
            double tp = NormalizeDouble(ask + tpDelta, _Digits);
            if (trade.Buy(InpLoteBase, _Symbol, ask, sl, tp, "AMETRALLADORA_BUY")) {
                txtVeredicto = "COMPRA AMETRALLADORA EJECUTADA 📈";
            }
        }
        else if (entradaSell) {
            double sl = NormalizeDouble(bid + slDelta, _Digits);
            double tp = NormalizeDouble(bid - tpDelta, _Digits);
            if (trade.Sell(InpLoteBase, _Symbol, bid, sl, tp, "AMETRALLADORA_SELL")) {
                txtVeredicto = "VENTA AMETRALLADORA EJECUTADA 📉";
            }
        }
    }
    // Entrada de Apoyo / Escalado Limpio si la principal va en contra
    else if (InpActivarRecuperacion && posAbiertas < InpMaxPosiciones && flotanteActual <= -InpGatilloPerdida_USD) {
        if (TimeCurrent() - lastApoyoTime >= 60) {
            ENUM_POSITION_TYPE lastType;
            double lastPrice = ObtenerUltimaPosicionInfo(lastType);
            if (lastPrice > 0) {
                double loteApoyoNorm = NormalizarVolumen(InpLoteApoyo);
                double slDelta = USDtoPriceDelta(InpStopLoss_USD, loteApoyoNorm);
                double tpDelta = USDtoPriceDelta(InpTakeProfit_USD, loteApoyoNorm);
                double pipsDelta = InpDistanciaApoyo_Pips * _Point * 10.0;

                if (lastType == POSITION_TYPE_BUY && (bid <= lastPrice - pipsDelta)) {
                    double sl = NormalizeDouble(ask - slDelta, _Digits);
                    double tp = NormalizeDouble(ask + tpDelta, _Digits);
                    if (trade.Buy(loteApoyoNorm, _Symbol, ask, sl, tp, "AMETRALLADORA_APOYO_BUY")) {
                        txtVeredicto = "ENTRADA APOYO COMPRA AGREGADA 🛡️";
                        lastApoyoTime = TimeCurrent();
                    }
                }
                else if (lastType == POSITION_TYPE_SELL && (ask >= lastPrice + pipsDelta)) {
                    double sl = NormalizeDouble(bid + slDelta, _Digits);
                    double tp = NormalizeDouble(bid - tpDelta, _Digits);
                    if (trade.Sell(loteApoyoNorm, _Symbol, bid, sl, tp, "AMETRALLADORA_APOYO_SELL")) {
                        txtVeredicto = "ENTRADA APOYO VENTA AGREGADA 🛡️";
                        lastApoyoTime = TimeCurrent();
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Gestionar Posiciones Abiertas (Ciclo, BE, Trailing)              |
//+------------------------------------------------------------------+
void GestionarPosicionesAbiertas()
{
    int nPos = ContarPosicionesMagic();
    if (nPos == 0) return;

    // Cierre de Ciclo Global al acumular el Profit Meta
    if (flotanteActual >= InpProfitCicloUSD) {
        CerrarTodasLasPosiciones();
        cooldownEndTime = TimeCurrent() + InpCooldownSeconds;
        txtVeredicto = "CESTA CERRADA CON ÉXITO (+$" + DoubleToString(flotanteActual, 2) + ") 🎉";
        return;
    }

    // Gestión individual por posición (BE y Trailing)
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket) && EsMismoSimbolo(PositionGetString(POSITION_SYMBOL)) && PositionGetInteger(POSITION_MAGIC) == InpMagicNumber) {
            double p = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double currentSL = PositionGetDouble(POSITION_SL);
            double currentTP = PositionGetDouble(POSITION_TP);
            double volume    = PositionGetDouble(POSITION_VOLUME);
            ENUM_POSITION_TYPE pType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

            // Cierre individual por TP alcanzado en flotante si el TP físico no ha disparado
            if (p >= InpTakeProfit_USD) {
                trade.PositionClose(ticket);
                continue;
            }

            // Break Even
            if (InpActivarBE && p >= InpActivarBETrasUSD) {
                double beDeltaProtect = USDtoPriceDelta(InpProtegerBE_USD, volume);
                if (pType == POSITION_TYPE_BUY) {
                    double newSL = NormalizeDouble(openPrice + beDeltaProtect, _Digits);
                    if (currentSL < newSL) trade.PositionModify(ticket, newSL, currentTP);
                }
                else if (pType == POSITION_TYPE_SELL) {
                    double newSL = NormalizeDouble(openPrice - beDeltaProtect, _Digits);
                    if (currentSL == 0 || currentSL > newSL) trade.PositionModify(ticket, newSL, currentTP);
                }
            }

            // Trailing Stop opcional
            if (InpActivarTrailing && p >= InpTrailingStartUSD) {
                double stepDelta = USDtoPriceDelta(InpTrailingStepUSD, volume);
                double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

                if (pType == POSITION_TYPE_BUY) {
                    double newSL = NormalizeDouble(bid - stepDelta, _Digits);
                    if (newSL > currentSL + (_Point * 10.0)) trade.PositionModify(ticket, newSL, currentTP);
                }
                else if (pType == POSITION_TYPE_SELL) {
                    double newSL = NormalizeDouble(ask + stepDelta, _Digits);
                    if (currentSL == 0 || newSL < currentSL - (_Point * 10.0)) trade.PositionModify(ticket, newSL, currentTP);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Utilidades de Conteo y Cierre                                    |
//+------------------------------------------------------------------+
bool EsMismoSimbolo(string sym)
{
    if (sym == _Symbol) return true;
    string s1 = sym; StringToUpper(s1);
    string s2 = _Symbol; StringToUpper(s2);
    return (s1 == s2 || StringFind(s1, s2) >= 0 || StringFind(s2, s1) >= 0);
}

int ContarPosicionesMagic()
{
    int c = 0;
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong t = PositionGetTicket(i);
        if (PositionSelectByTicket(t) && EsMismoSimbolo(PositionGetString(POSITION_SYMBOL)) && PositionGetInteger(POSITION_MAGIC) == InpMagicNumber) c++;
    }
    return c;
}

ulong ObtenerPrimerTicket()
{
    for (int i = 0; i < PositionsTotal(); i++) {
        ulong t = PositionGetTicket(i);
        if (PositionSelectByTicket(t) && EsMismoSimbolo(PositionGetString(POSITION_SYMBOL)) && PositionGetInteger(POSITION_MAGIC) == InpMagicNumber) return t;
    }
    return 0;
}

double ObtenerUltimaPosicionInfo(ENUM_POSITION_TYPE &outType)
{
    datetime maxTime = 0;
    double lastPrice = 0.0;
    for (int i = 0; i < PositionsTotal(); i++) {
        ulong t = PositionGetTicket(i);
        if (PositionSelectByTicket(t) && EsMismoSimbolo(PositionGetString(POSITION_SYMBOL)) && PositionGetInteger(POSITION_MAGIC) == InpMagicNumber) {
            datetime pTime = (datetime)PositionGetInteger(POSITION_TIME);
            if (pTime >= maxTime) {
                maxTime = pTime;
                lastPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                outType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            }
        }
    }
    return lastPrice;
}

void CerrarTodasLasPosiciones()
{
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket) && EsMismoSimbolo(PositionGetString(POSITION_SYMBOL)) && PositionGetInteger(POSITION_MAGIC) == InpMagicNumber) {
            trade.PositionClose(ticket);
        }
    }
}

bool HayNoticiaUSD()
{
    if (!InpUsarFiltroNoticias) return false;
    MqlCalendarValue vals[];
    datetime start = TimeCurrent() - (InpMinsDespuesNoticia * 60);
    datetime end   = TimeCurrent() + (InpMinsAntesNoticia * 60);
    if (CalendarValueHistory(vals, start, end, NULL, "USD") > 0) {
        for (int i = 0; i < ArraySize(vals); i++) {
            MqlCalendarEvent ev;
            if (CalendarEventById(vals[i].event_id, ev) && ev.importance == CALENDAR_IMPORTANCE_HIGH) return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| INTERFAZ VISUAL INTERACTIVA (HUD)                                |
//+------------------------------------------------------------------+
void CrearHUD()
{
    int x = InpHUD_X, y = InpHUD_Y, w = 390, h = 260;
    ObjectCreate(0, HUD_PREFIX+"Bg", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, HUD_PREFIX+"Bg", OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, HUD_PREFIX+"Bg", OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, HUD_PREFIX+"Bg", OBJPROP_XSIZE, w);
    ObjectSetInteger(0, HUD_PREFIX+"Bg", OBJPROP_YSIZE, h);
    ObjectSetInteger(0, HUD_PREFIX+"Bg", OBJPROP_BGCOLOR, C'12,14,24');
    ObjectSetInteger(0, HUD_PREFIX+"Bg", OBJPROP_BORDER_COLOR, C'80,60,180');
    ObjectSetInteger(0, HUD_PREFIX+"Bg", OBJPROP_ZORDER, 9999);

    CrearLabel("T", x+12, y+10, "MAIKO AMETRALLADORA PRO | SEPTIEMBRE v1.0", clrGold, 10);
    CrearLabel("Sub", x+12, y+30, "SL/TP FÍSICO BROKER + CAJERO CALIBRADO", clrCyan, 8);
    CrearLabel("Hoy", x+12, y+55, "RESULTADO HOY: $0.00", clrSpringGreen, 10);
    CrearLabel("Flot", x+12, y+75, "FLOTANTE ACTUAL: $0.00", clrWhite, 9);
    CrearLabel("Cajero", x+12, y+95, "CAJERO: OK", clrLightGray, 9);
    CrearLabel("ATR", x+12, y+115, "VOLATILIDAD (ATR): --", clrLightBlue, 9);
    CrearLabel("Vered", x+12, y+140, txtVeredicto, clrYellow, 8);

    CrearBoton("BtnP", x+w-135, y+190, 120, 35, botActivo ? "APAGAR BOT" : "ENCENDER BOT", botActivo ? clrDarkRed : clrDarkGreen);
    CrearBoton("BtnC", x+w-135, y+145, 120, 35, "CERRAR TODO", C'150,30,30');
}

void ActualizarHUD()
{
    ObjectSetString(0, HUD_PREFIX+"Hoy", OBJPROP_TEXT, StringFormat("RESULTADO HOY: $%.2f", ganadoHoy));
    ObjectSetString(0, HUD_PREFIX+"Flot", OBJPROP_TEXT, StringFormat("FLOTANTE ACTUAL: $%.2f", flotanteActual));
    ObjectSetInteger(0, HUD_PREFIX+"Flot", OBJPROP_COLOR, flotanteActual >= 0 ? clrSpringGreen : clrRed);
    ObjectSetString(0, HUD_PREFIX+"Cajero", OBJPROP_TEXT, txtEstadoCajero);
    ObjectSetString(0, HUD_PREFIX+"ATR", OBJPROP_TEXT, StringFormat("ATR (14): %.2f", atrActual));
    ObjectSetString(0, HUD_PREFIX+"Vered", OBJPROP_TEXT, botActivo ? txtVeredicto : "🔴 BOT DETENIDO (PAUSADO)");
    ObjectSetInteger(0, HUD_PREFIX+"Vered", OBJPROP_COLOR, botActivo ? clrYellow : clrRed);

    ObjectSetString(0, HUD_PREFIX+"BtnP", OBJPROP_TEXT, botActivo ? "APAGAR BOT" : "ENCENDER BOT");
    ObjectSetInteger(0, HUD_PREFIX+"BtnP", OBJPROP_BGCOLOR, botActivo ? clrDarkRed : clrDarkGreen);
    ChartRedraw(0);
}

void CrearLabel(string n, int x, int y, string t, color col, int s)
{
    string full = HUD_PREFIX + n;
    ObjectCreate(0, full, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, full, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, full, OBJPROP_YDISTANCE, y);
    ObjectSetString(0, full, OBJPROP_TEXT, t);
    ObjectSetInteger(0, full, OBJPROP_COLOR, col);
    ObjectSetInteger(0, full, OBJPROP_FONTSIZE, s);
    ObjectSetInteger(0, full, OBJPROP_ZORDER, 10001);
}

void CrearBoton(string n, int x, int y, int w, int h, string t, color bg)
{
    string full = HUD_PREFIX + n;
    ObjectCreate(0, full, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, full, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, full, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, full, OBJPROP_XSIZE, w);
    ObjectSetInteger(0, full, OBJPROP_YSIZE, h);
    ObjectSetInteger(0, full, OBJPROP_BGCOLOR, bg);
    ObjectSetInteger(0, full, OBJPROP_COLOR, clrWhite);
    ObjectSetString(0, full, OBJPROP_TEXT, t);
    ObjectSetInteger(0, full, OBJPROP_ZORDER, 10010);
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    if (id == CHARTEVENT_OBJECT_CLICK) {
        ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
        if (sparam == HUD_PREFIX+"BtnP") { botActivo = !botActivo; ActualizarHUD(); }
        if (sparam == HUD_PREFIX+"BtnC") { CerrarTodasLasPosiciones(); }
    }
}
//+------------------------------------------------------------------+

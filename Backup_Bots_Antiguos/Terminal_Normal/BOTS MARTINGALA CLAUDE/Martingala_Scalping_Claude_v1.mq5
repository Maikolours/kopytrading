//+------------------------------------------------------------------+
//|                          Martingala_Scalping_Claude_v1.mq5       |
//|                          Bot de Scalping Ultra Rápido            |
//+------------------------------------------------------------------+
#property copyright "Martingala Scalping Claude v1"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

// Parámetros de entrada
input group "=== CONFIGURACIÓN GENERAL ==="
input double   LoteInicial = 0.01;           // Lote inicial
input int      MaxOperaciones = 5;           // Máximo de operaciones abiertas
input double   ProfitMinimo = 1.5;           // Profit mínimo individual (USD)
input double   ProfitIdeal = 8.0;            // Profit total objetivo (USD)
input double   StopLossPips = 50;            // Stop Loss en pips

input group "=== MARTINGALA ==="
input double   MultiplicadorLote = 1.5;      // Multiplicador de lote
input int      DistanciaPips = 15;           // Distancia mínima entre operaciones
input bool     ReforzarGanadoras = true;     // Reforzar operaciones en profit

input group "=== GESTIÓN DE RIESGO ==="
input bool     UsarBreakEven = true;         // Usar Break Even
input double   BEActivacionProfit = 0.50;    // Activación BE en USD
input double   BEPips = 1;                   // Pips de BE
input bool     UsarTrailingStop = true;      // Usar Trailing Stop
input double   TrailingStartProfit = 2.0;    // Inicio Trailing en USD
input double   TrailingStepPips = 3;         // Paso de Trailing

input group "=== SEÑALES DE ENTRADA ==="
input int      Periodo_EMA_Rapida = 3;       // EMA ultra rápida
input int      Periodo_EMA_Media = 8;        // EMA media
input int      Lookback_Momentum = 3;        // Velas para momentum

input group "=== SCALPING ULTRA RÁPIDO ==="
input bool     ModoUltraRapido = true;       // Cierre ultra rápido
input double   TiempoMinimoSegundos = 10;    // Tiempo mínimo en operación

// Variables globales
CTrade trade;
bool BotActivo = false;
datetime ultimaBarra = 0;
double profitTotal = 0;
int totalOperaciones = 0;
bool alertaMaximaEmitida = false;
int contadorOperaciones = 0;

// Handles de indicadores
int handleEMAFast;
int handleEMAMed;

// Estructuras
struct PosicionInfo {
    ulong ticket;
    double lote;
    double precioApertura;
    int tipo;
    double profit;
    datetime tiempoApertura;
};

PosicionInfo posiciones[];

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
    // Indicadores más rápidos para scalping
    handleEMAFast = iMA(_Symbol, PERIOD_M1, Periodo_EMA_Rapida, 0, MODE_EMA, PRICE_CLOSE);
    handleEMAMed = iMA(_Symbol, PERIOD_M1, Periodo_EMA_Media, 0, MODE_EMA, PRICE_CLOSE);
    
    if(handleEMAFast == INVALID_HANDLE || handleEMAMed == INVALID_HANDLE)
    {
        Print("Error al crear indicadores");
        return(INIT_FAILED);
    }
    
    trade.SetExpertMagicNumber(234567);
    trade.SetDeviationInPoints(10);
    trade.SetTypeFilling(ORDER_FILLING_FOK);
    
    CrearBotones();
    
    Print("═══════════════════════════════════════");
    Print("  Martingala Scalping Claude v1");
    Print("  Bot iniciado correctamente");
    Print("═══════════════════════════════════════");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    ObjectDelete(0, "BtnActivar");
    ObjectDelete(0, "BtnDesactivar");
    ObjectDelete(0, "LabelEstado");
    ObjectDelete(0, "LabelInfo");
    
    IndicatorRelease(handleEMAFast);
    IndicatorRelease(handleEMAMed);
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    if(!BotActivo) return;
    
    ActualizarPosiciones();
    
    // Gestión continua (cada tick)
    GestionarBreakEvenRapido();
    GestionarTrailingStop();
    CerrarPosicionesRapidas();
    
    profitTotal = CalcularProfitTotal();
    
    // Actualizar interfaz
    string infoText = StringFormat("Ops: %d | P&L: $%.2f", totalOperaciones, profitTotal);
    ObjectSetString(0, "LabelInfo", OBJPROP_TEXT, infoText);
    ObjectSetInteger(0, "LabelInfo", OBJPROP_COLOR, profitTotal > 0 ? clrLime : (profitTotal < 0 ? clrRed : clrWhite));
    
    // Cerrar todo si alcanza objetivo
    if(profitTotal >= ProfitIdeal)
    {
        CerrarTodasLasPosiciones();
        Print("🎯 OBJETIVO ALCANZADO: $", profitTotal);
        return;
    }
    
    // Verificar nueva barra
    datetime tiempoActual = iTime(_Symbol, PERIOD_M1, 0);
    bool nuevaBarra = (tiempoActual != ultimaBarra);
    if(nuevaBarra) ultimaBarra = tiempoActual;
    
    totalOperaciones = ContarPosicionesAbiertas();
    
    // Alerta máximo
    if(totalOperaciones >= MaxOperaciones && !alertaMaximaEmitida)
    {
        Alert("⚠️ Máximo de operaciones: ", totalOperaciones, "/", MaxOperaciones);
        PlaySound("alert.wav");
        alertaMaximaEmitida = true;
    }
    
    // Evaluar entradas
    if(totalOperaciones < MaxOperaciones)
    {
        alertaMaximaEmitida = false;
        
        if(nuevaBarra || totalOperaciones == 0)
        {
            EvaluarEntradas();
        }
        
        // NUEVO: Reforzar ganadoras cada 2 velas
        if(ReforzarGanadoras && totalOperaciones > 0)
        {
            static int contadorVelas = 0;
            if(nuevaBarra) contadorVelas++;
            
            if(contadorVelas >= 2)
            {
                ReforzarPosicionesGanadoras();
                contadorVelas = 0;
            }
        }
    }
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| NUEVO: Evaluar señales CORRECTAS                                 |
//+------------------------------------------------------------------+
void EvaluarEntradas()
{
    double emaFast[], emaMed[], close[];
    ArraySetAsSeries(emaFast, true);
    ArraySetAsSeries(emaMed, true);
    ArraySetAsSeries(close, true);
    
    if(CopyBuffer(handleEMAFast, 0, 0, 5, emaFast) <= 0) return;
    if(CopyBuffer(handleEMAMed, 0, 0, 5, emaMed) <= 0) return;
    if(CopyClose(_Symbol, PERIOD_M1, 0, 5, close) <= 0) return;
    
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // MOMENTUM - Calcular dirección real del precio
    double momentum = close[0] - close[Lookback_Momentum];
    double momentumPips = momentum / (SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10);
    
    bool señalCompra = false;
    bool señalVenta = false;
    
    // ✅ SEÑAL DE COMPRA (cuando el precio está SUBIENDO)
    if(emaFast[0] > emaMed[0] &&                    // EMA rápida por encima
       emaFast[0] > emaFast[1] &&                   // EMA rápida subiendo
       close[0] > emaFast[0] &&                     // Precio por encima de EMA
       momentum > 0 &&                               // Momentum positivo
       momentumPips >= 2)                            // Al menos 2 pips de movimiento
    {
        señalCompra = true;
    }
    
    // ✅ SEÑAL DE VENTA (cuando el precio está BAJANDO)
    if(emaFast[0] < emaMed[0] &&                    // EMA rápida por debajo
       emaFast[0] < emaFast[1] &&                   // EMA rápida bajando
       close[0] < emaFast[0] &&                     // Precio por debajo de EMA
       momentum < 0 &&                               // Momentum negativo
       momentumPips <= -2)                           // Al menos 2 pips de movimiento
    {
        señalVenta = true;
    }
    
    // Primera operación
    if(totalOperaciones == 0)
    {
        if(señalCompra)
        {
            Print("🔵 COMPRA | Mom:", DoubleToString(momentumPips, 1), " pips | EMA:", DoubleToString(emaFast[0], 2), " > ", DoubleToString(emaMed[0], 2));
            AbrirPosicion(ORDER_TYPE_BUY, LoteInicial, ask);
        }
        else if(señalVenta)
        {
            Print("🔴 VENTA | Mom:", DoubleToString(momentumPips, 1), " pips | EMA:", DoubleToString(emaFast[0], 2), " < ", DoubleToString(emaMed[0], 2));
            AbrirPosicion(ORDER_TYPE_SELL, LoteInicial, bid);
        }
    }
    else
    {
        // Operaciones adicionales
        AbrirPosicionMartingala(señalCompra, señalVenta);
    }
}

//+------------------------------------------------------------------+
//| NUEVO: Reforzar posiciones ganadoras                             |
//+------------------------------------------------------------------+
void ReforzarPosicionesGanadoras()
{
    if(totalOperaciones >= MaxOperaciones) return;
    
    double mejorProfit = 0;
    int mejorTipo = -1;
    
    // Encontrar la mejor posición
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        if(posiciones[i].profit > mejorProfit)
        {
            mejorProfit = posiciones[i].profit;
            mejorTipo = posiciones[i].tipo;
        }
    }
    
    // Si hay una ganadora con >$1, reforzar
    if(mejorProfit >= 1.0)
    {
        double siguienteLote = CalcularSiguienteLote();
        
        if(mejorTipo == ORDER_TYPE_BUY)
        {
            double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            Print("💪 REFORZANDO COMPRA ganadora ($", DoubleToString(mejorProfit, 2), ")");
            AbrirPosicion(ORDER_TYPE_BUY, siguienteLote, ask);
        }
        else if(mejorTipo == ORDER_TYPE_SELL)
        {
            double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            Print("💪 REFORZANDO VENTA ganadora ($", DoubleToString(mejorProfit, 2), ")");
            AbrirPosicion(ORDER_TYPE_SELL, siguienteLote, bid);
        }
    }
}

//+------------------------------------------------------------------+
//| Abrir posición con martingala                                    |
//+------------------------------------------------------------------+
void AbrirPosicionMartingala(bool señalCompra, bool señalVenta)
{
    if(totalOperaciones >= MaxOperaciones) return;
    
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    double siguienteLote = CalcularSiguienteLote();
    
    int compras = 0, ventas = 0;
    double profitCompras = 0, profitVentas = 0;
    double precioPromCompras = 0, precioPromVentas = 0;
    
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        if(posiciones[i].tipo == ORDER_TYPE_BUY)
        {
            compras++;
            profitCompras += posiciones[i].profit;
            precioPromCompras += posiciones[i].precioApertura;
        }
        else
        {
            ventas++;
            profitVentas += posiciones[i].profit;
            precioPromVentas += posiciones[i].precioApertura;
        }
    }
    
    if(compras > 0) precioPromCompras /= compras;
    if(ventas > 0) precioPromVentas /= ventas;
    
    double distanciaPips = DistanciaPips * point * 10;
    
    bool abrirCompra = false;
    bool abrirVenta = false;
    
    // Lógica de martingala
    if(señalCompra)
    {
        if(compras == 0) 
        {
            abrirCompra = true;
        }
        else if(ask < precioPromCompras - distanciaPips || profitCompras < -2.0)
        {
            abrirCompra = true;
        }
    }
    
    if(señalVenta)
    {
        if(ventas == 0)
        {
            abrirVenta = true;
        }
        else if(bid > precioPromVentas + distanciaPips || profitVentas < -2.0)
        {
            abrirVenta = true;
        }
    }
    
    if(abrirCompra && abrirVenta)
    {
        if(profitCompras >= profitVentas)
            abrirVenta = false;
        else
            abrirCompra = false;
    }
    
    if(abrirCompra)
    {
        Print("📈 Martingala COMPRA | Lote:", siguienteLote, " | Total:", compras+1);
        AbrirPosicion(ORDER_TYPE_BUY, siguienteLote, ask);
    }
    else if(abrirVenta)
    {
        Print("📉 Martingala VENTA | Lote:", siguienteLote, " | Total:", ventas+1);
        AbrirPosicion(ORDER_TYPE_SELL, siguienteLote, bid);
    }
}

//+------------------------------------------------------------------+
//| Abrir posición                                                    |
//+------------------------------------------------------------------+
void AbrirPosicion(ENUM_ORDER_TYPE tipo, double lote, double precio)
{
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    
    double sl = 0;
    
    if(tipo == ORDER_TYPE_BUY)
    {
        sl = NormalizeDouble(precio - StopLossPips * point * 10, digits);
        if(trade.Buy(lote, _Symbol, precio, sl, 0, "MSC_v1"))
        {
            contadorOperaciones++;
            Print("✅ BUY #", contadorOperaciones, " | Lote:", lote, " | Precio:", precio);
        }
    }
    else
    {
        sl = NormalizeDouble(precio + StopLossPips * point * 10, digits);
        if(trade.Sell(lote, _Symbol, precio, sl, 0, "MSC_v1"))
        {
            contadorOperaciones++;
            Print("✅ SELL #", contadorOperaciones, " | Lote:", lote, " | Precio:", precio);
        }
    }
}

//+------------------------------------------------------------------+
//| Cerrar posiciones ultra rápido                                   |
//+------------------------------------------------------------------+
void CerrarPosicionesRapidas()
{
    datetime ahora = TimeCurrent();
    
    for(int i = ArraySize(posiciones) - 1; i >= 0; i--)
    {
        int segundos = (int)(ahora - posiciones[i].tiempoApertura);
        
        if(ModoUltraRapido)
        {
            if(segundos >= TiempoMinimoSegundos && posiciones[i].profit >= ProfitMinimo)
            {
                if(trade.PositionClose(posiciones[i].ticket))
                {
                    Print("⚡ CERRADO: $", DoubleToString(posiciones[i].profit, 2), " en ", segundos, "s");
                }
            }
            else if(posiciones[i].profit >= 3.0)
            {
                if(trade.PositionClose(posiciones[i].ticket))
                {
                    Print("⚡ CERRADO RÁPIDO: $", DoubleToString(posiciones[i].profit, 2));
                }
            }
        }
        else
        {
            if(posiciones[i].profit >= ProfitMinimo)
            {
                trade.PositionClose(posiciones[i].ticket);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Calcular siguiente lote                                          |
//+------------------------------------------------------------------+
double CalcularSiguienteLote()
{
    if(ArraySize(posiciones) == 0) return LoteInicial;
    
    double maxLote = LoteInicial;
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        if(posiciones[i].lote > maxLote)
            maxLote = posiciones[i].lote;
    }
    
    return NormalizarLote(maxLote * MultiplicadorLote);
}

//+------------------------------------------------------------------+
//| Normalizar lote                                                   |
//+------------------------------------------------------------------+
double NormalizarLote(double lote)
{
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    lote = MathFloor(lote / stepLot) * stepLot;
    lote = MathMax(minLot, MathMin(maxLot, lote));
    
    return lote;
}

//+------------------------------------------------------------------+
//| Actualizar posiciones                                            |
//+------------------------------------------------------------------+
void ActualizarPosiciones()
{
    ArrayResize(posiciones, 0);
    
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0)
        {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
               PositionGetInteger(POSITION_MAGIC) == 234567)
            {
                int idx = ArraySize(posiciones);
                ArrayResize(posiciones, idx + 1);
                
                posiciones[idx].ticket = ticket;
                posiciones[idx].lote = PositionGetDouble(POSITION_VOLUME);
                posiciones[idx].precioApertura = PositionGetDouble(POSITION_PRICE_OPEN);
                posiciones[idx].tipo = (int)PositionGetInteger(POSITION_TYPE);
                posiciones[idx].profit = PositionGetDouble(POSITION_PROFIT);
                posiciones[idx].tiempoApertura = (datetime)PositionGetInteger(POSITION_TIME);
            }
        }
    }
}

int ContarPosicionesAbiertas() { return ArraySize(posiciones); }

double CalcularProfitTotal()
{
    double total = 0;
    for(int i = 0; i < ArraySize(posiciones); i++)
        total += posiciones[i].profit;
    return total;
}

void CerrarTodasLasPosiciones()
{
    for(int i = ArraySize(posiciones) - 1; i >= 0; i--)
        trade.PositionClose(posiciones[i].ticket);
    ArrayResize(posiciones, 0);
}

//+------------------------------------------------------------------+
//| Break Even rápido                                                |
//+------------------------------------------------------------------+
void GestionarBreakEvenRapido()
{
    if(!UsarBreakEven) return;
    
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        if(posiciones[i].profit >= BEActivacionProfit)
        {
            if(!PositionSelectByTicket(posiciones[i].ticket)) continue;
            
            double sl = PositionGetDouble(POSITION_SL);
            double BE;
            
            if(posiciones[i].tipo == ORDER_TYPE_BUY)
            {
                BE = NormalizeDouble(posiciones[i].precioApertura + BEPips * point * 10, digits);
                if(sl < posiciones[i].precioApertura)
                {
                    trade.PositionModify(posiciones[i].ticket, BE, 0);
                }
            }
            else
            {
                BE = NormalizeDouble(posiciones[i].precioApertura - BEPips * point * 10, digits);
                if(sl > posiciones[i].precioApertura || sl == 0)
                {
                    trade.PositionModify(posiciones[i].ticket, BE, 0);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Trailing Stop                                                    |
//+------------------------------------------------------------------+
void GestionarTrailingStop()
{
    if(!UsarTrailingStop) return;
    
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        if(posiciones[i].profit < TrailingStartProfit) continue;
        
        if(!PositionSelectByTicket(posiciones[i].ticket)) continue;
        
        double sl = PositionGetDouble(POSITION_SL);
        double precioActual;
        
        if(posiciones[i].tipo == ORDER_TYPE_BUY)
        {
            precioActual = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double nuevoSL = NormalizeDouble(precioActual - TrailingStepPips * point * 10, digits);
            if(nuevoSL > sl) trade.PositionModify(posiciones[i].ticket, nuevoSL, 0);
        }
        else
        {
            precioActual = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double nuevoSL = NormalizeDouble(precioActual + TrailingStepPips * point * 10, digits);
            if(nuevoSL < sl || sl == 0) trade.PositionModify(posiciones[i].ticket, nuevoSL, 0);
        }
    }
}

//+------------------------------------------------------------------+
//| Crear botones                                                    |
//+------------------------------------------------------------------+
void CrearBotones()
{
    int x = 150, y = 80, ancho = 100, alto = 30;
    
    ObjectCreate(0, "BtnActivar", OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, "BtnActivar", OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, "BtnActivar", OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, "BtnActivar", OBJPROP_XSIZE, ancho);
    ObjectSetInteger(0, "BtnActivar", OBJPROP_YSIZE, alto);
    ObjectSetInteger(0, "BtnActivar", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "BtnActivar", OBJPROP_BGCOLOR, clrGreen);
    ObjectSetInteger(0, "BtnActivar", OBJPROP_COLOR, clrWhite);
    ObjectSetString(0, "BtnActivar", OBJPROP_TEXT, "ACTIVAR");
    ObjectSetInteger(0, "BtnActivar", OBJPROP_FONTSIZE, 10);
    ObjectSetInteger(0, "BtnActivar", OBJPROP_BACK, false);
    
    ObjectCreate(0, "BtnDesactivar", OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, "BtnDesactivar", OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, "BtnDesactivar", OBJPROP_YDISTANCE, y + alto + 10);
    ObjectSetInteger(0, "BtnDesactivar", OBJPROP_XSIZE, ancho);
    ObjectSetInteger(0, "BtnDesactivar", OBJPROP_YSIZE, alto);
    ObjectSetInteger(0, "BtnDesactivar", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "BtnDesactivar", OBJPROP_BGCOLOR, clrRed);
    ObjectSetInteger(0, "BtnDesactivar", OBJPROP_COLOR, clrWhite);
    ObjectSetString(0, "BtnDesactivar", OBJPROP_TEXT, "DESACTIVAR");
    ObjectSetInteger(0, "BtnDesactivar", OBJPROP_FONTSIZE, 10);
    ObjectSetInteger(0, "BtnDesactivar", OBJPROP_BACK, false);
    
    ObjectCreate(0, "LabelEstado", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "LabelEstado", OBJPROP_XDISTANCE, x - 20);
    ObjectSetInteger(0, "LabelEstado", OBJPROP_YDISTANCE, y + (alto + 10) * 2 + 5);
    ObjectSetInteger(0, "LabelEstado", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "LabelEstado", OBJPROP_COLOR, clrYellow);
    ObjectSetString(0, "LabelEstado", OBJPROP_TEXT, "MSC v1: INACTIVO");
    ObjectSetInteger(0, "LabelEstado", OBJPROP_FONTSIZE, 10);
    ObjectSetString(0, "LabelEstado", OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, "LabelEstado", OBJPROP_BACK, false);
    
    ObjectCreate(0, "LabelInfo", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "LabelInfo", OBJPROP_XDISTANCE, x - 20);
    ObjectSetInteger(0, "LabelInfo", OBJPROP_YDISTANCE, y + (alto + 10) * 2 + 25);
    ObjectSetInteger(0, "LabelInfo", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "LabelInfo", OBJPROP_COLOR, clrWhite);
    ObjectSetString(0, "LabelInfo", OBJPROP_TEXT, "Ops: 0 | P&L: $0.00");
    ObjectSetInteger(0, "LabelInfo", OBJPROP_FONTSIZE, 8);
    ObjectSetInteger(0, "LabelInfo", OBJPROP_BACK, false);
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Eventos de botones                                               |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    if(id == CHARTEVENT_OBJECT_CLICK)
    {
        if(sparam == "BtnActivar")
        {
            BotActivo = true;
            ObjectSetString(0, "LabelEstado", OBJPROP_TEXT, "MSC v1: ACTIVO");
            ObjectSetInteger(0, "LabelEstado", OBJPROP_COLOR, clrLime);
            Print("🚀 Martingala Scalping Claude v1 ACTIVADO");
            ObjectSetInteger(0, "BtnActivar", OBJPROP_STATE, false);
        }
        else if(sparam == "BtnDesactivar")
        {
            BotActivo = false;
            ObjectSetString(0, "LabelEstado", OBJPROP_TEXT, "MSC v1: INACTIVO");
            ObjectSetInteger(0, "LabelEstado", OBJPROP_COLOR, clrRed);
            Print("⏸️ Bot DESACTIVADO");
            ObjectSetInteger(0, "BtnDesactivar", OBJPROP_STATE, false);
        }
        ChartRedraw();
    }
}
//+------------------------------------------------------------------+
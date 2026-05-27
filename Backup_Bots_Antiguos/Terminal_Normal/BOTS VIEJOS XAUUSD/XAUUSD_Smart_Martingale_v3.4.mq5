//+------------------------------------------------------------------+
//|                                    XAUUSD_Scalping_Martingale.mq5 |
//|                                  Scalping Bot con Martingala     |
//+------------------------------------------------------------------+
#property copyright "Scalping Martingale Bot"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

// Parámetros de entrada
input group "=== CONFIGURACIÓN GENERAL ==="
input double   LoteInicial = 0.01;           // Lote inicial
input int      MaxOperaciones = 5;           // Máximo de operaciones abiertas
input double   ProfitMinimo = 5.0;           // Profit mínimo en USD
input double   ProfitIdeal = 15.0;           // Profit ideal en USD
input double   StopLossPips = 50;            // Stop Loss en pips

input group "=== MARTINGALA ==="
input double   MultiplicadorLote = 1.5;      // Multiplicador de lote
input int      DistanciaPips = 20;           // Distancia entre operaciones (pips)

input group "=== GESTIÓN DE RIESGO ==="
input bool     UsarBreakEven = true;         // Usar Break Even
input double   BEActivacionPips = 10;        // Activación BE en pips
input double   BEPips = 2;                   // Pips de BE
input bool     UsarTrailingStop = true;      // Usar Trailing Stop
input double   TrailingStartPips = 15;       // Inicio Trailing en pips
input double   TrailingStepPips = 5;         // Paso de Trailing en pips

input group "=== SEÑALES DE ENTRADA ==="
input int      RSI_Periodo = 14;             // Período RSI
input double   RSI_Sobreventa = 30;          // Nivel sobreventa
input double   RSI_Sobrecompra = 70;         // Nivel sobrecompra
input int      EMA_Rapida = 5;               // EMA rápida
input int      EMA_Lenta = 20;               // EMA lenta

// Variables globales
CTrade trade;
bool BotActivo = false;
datetime ultimaBarra = 0;
double profitTotal = 0;
int totalOperaciones = 0;
bool alertaMaximaEmitida = false;

// Handles de indicadores
int handleRSI;
int handleEMAFast;
int handleEMASlow;

// Estructuras
struct PosicionInfo {
    ulong ticket;
    double lote;
    double precioApertura;
    int tipo;
    double profit;
};

PosicionInfo posiciones[];

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
    // Inicializar indicadores
    handleRSI = iRSI(_Symbol, PERIOD_M1, RSI_Periodo, PRICE_CLOSE);
    handleEMAFast = iMA(_Symbol, PERIOD_M1, EMA_Rapida, 0, MODE_EMA, PRICE_CLOSE);
    handleEMASlow = iMA(_Symbol, PERIOD_M1, EMA_Lenta, 0, MODE_EMA, PRICE_CLOSE);
    
    if(handleRSI == INVALID_HANDLE || handleEMAFast == INVALID_HANDLE || handleEMASlow == INVALID_HANDLE)
    {
        Print("Error al crear indicadores");
        return(INIT_FAILED);
    }
    
    trade.SetExpertMagicNumber(123456);
    trade.SetDeviationInPoints(10);
    trade.SetTypeFilling(ORDER_FILLING_FOK);
    
    // Crear botones
    CrearBotones();
    
    Print("Bot de Scalping Martingale iniciado");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Eliminar botones
    ObjectDelete(0, "BtnActivar");
    ObjectDelete(0, "BtnDesactivar");
    ObjectDelete(0, "LabelEstado");
    ObjectDelete(0, "LabelInfo");
    
    // Liberar indicadores
    IndicatorRelease(handleRSI);
    IndicatorRelease(handleEMAFast);
    IndicatorRelease(handleEMASlow);
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    if(!BotActivo) return;
    
    // Actualizar información de posiciones
    ActualizarPosiciones();
    
    // Gestión de posiciones existentes
    GestionarBreakEven();
    GestionarTrailingStop();
    
    // Verificar profit total
    profitTotal = CalcularProfitTotal();
    
    // Actualizar label de información
    string infoText = StringFormat("Ops: %d | P&L: $%.2f", totalOperaciones, profitTotal);
    ObjectSetString(0, "LabelInfo", OBJPROP_TEXT, infoText);
    if(profitTotal > 0)
        ObjectSetInteger(0, "LabelInfo", OBJPROP_COLOR, clrLime);
    else if(profitTotal < 0)
        ObjectSetInteger(0, "LabelInfo", OBJPROP_COLOR, clrRed);
    else
        ObjectSetInteger(0, "LabelInfo", OBJPROP_COLOR, clrWhite);
    
    // Cerrar todo si alcanza profit ideal o mínimo con condiciones
    if(profitTotal >= ProfitIdeal)
    {
        CerrarTodasLasPosiciones();
        Print("Profit ideal alcanzado: $", profitTotal);
        return;
    }
    
    // Cerrar posiciones individuales en profit
    CerrarPosicionesEnProfit();
    
    // Verificar si hay nueva barra
    datetime tiempoActual = iTime(_Symbol, PERIOD_M1, 0);
    bool nuevaBarra = (tiempoActual != ultimaBarra);
    if(nuevaBarra) ultimaBarra = tiempoActual;
    
    // Contar operaciones abiertas
    totalOperaciones = ContarPosicionesAbiertas();
    
    // Alerta si alcanza máximo de operaciones
    if(totalOperaciones >= MaxOperaciones && !alertaMaximaEmitida)
    {
        Alert("¡Máximo de operaciones alcanzado! (", totalOperaciones, "/", MaxOperaciones, ")");
        PlaySound("alert.wav");
        alertaMaximaEmitida = true;
    }
    
    if(totalOperaciones < MaxOperaciones)
    {
        alertaMaximaEmitida = false;
        
        // Evaluar nuevas entradas (más agresivo para scalping)
        if(nuevaBarra || totalOperaciones == 0)
        {
            EvaluarEntradas();
        }
    }
    else
    {
        // Si hay máximo de operaciones, reemplazar si alguna cierra en profit
        VerificarReemplazo();
    }
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Evaluar señales de entrada                                       |
//+------------------------------------------------------------------+
void EvaluarEntradas()
{
    double rsi[], emaFast[], emaSlow[];
    ArraySetAsSeries(rsi, true);
    ArraySetAsSeries(emaFast, true);
    ArraySetAsSeries(emaSlow, true);
    
    if(CopyBuffer(handleRSI, 0, 0, 3, rsi) <= 0) return;
    if(CopyBuffer(handleEMAFast, 0, 0, 3, emaFast) <= 0) return;
    if(CopyBuffer(handleEMASlow, 0, 0, 3, emaSlow) <= 0) return;
    
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    bool señalCompra = false;
    bool señalVenta = false;
    
    // Señales más agresivas para scalping
    // Señal de COMPRA
    if(emaFast[0] > emaSlow[0] && rsi[0] < 60)  // Tendencia alcista + RSI no sobrecomprado
    {
        señalCompra = true;
    }
    else if(rsi[0] < 35 && emaFast[1] <= emaSlow[1])  // Sobreventa fuerte
    {
        señalCompra = true;
    }
    
    // Señal de VENTA
    if(emaFast[0] < emaSlow[0] && rsi[0] > 40)  // Tendencia bajista + RSI no sobrevendido
    {
        señalVenta = true;
    }
    else if(rsi[0] > 65 && emaFast[1] >= emaSlow[1])  // Sobrecompra fuerte
    {
        señalVenta = true;
    }
    
    // Verificar si necesitamos abrir posición
    if(totalOperaciones == 0)
    {
        // Primera operación - más flexible
        if(señalCompra)
        {
            Print("Señal COMPRA detectada | RSI:", rsi[0], " | EMA Fast:", emaFast[0], " | EMA Slow:", emaSlow[0]);
            AbrirPosicion(ORDER_TYPE_BUY, LoteInicial, ask);
        }
        else if(señalVenta)
        {
            Print("Señal VENTA detectada | RSI:", rsi[0], " | EMA Fast:", emaFast[0], " | EMA Slow:", emaSlow[0]);
            AbrirPosicion(ORDER_TYPE_SELL, LoteInicial, bid);
        }
    }
    else
    {
        // Operaciones adicionales con martingala
        AbrirPosicionMartingala(señalCompra, señalVenta);
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
    
    // Calcular siguiente lote
    double siguienteLote = CalcularSiguienteLote();
    
    // Determinar dirección dominante
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
    
    // Distancia en pips
    double distanciaPips = DistanciaPips * point * 10;
    
    // Lógica de entrada más agresiva
    bool abrirCompra = false;
    bool abrirVenta = false;
    
    // Si hay señal y distancia suficiente o profit negativo
    if(señalCompra)
    {
        if(compras == 0) 
        {
            abrirCompra = true;
        }
        else if(ask < precioPromCompras - distanciaPips || profitCompras < -3.0)
        {
            abrirCompra = true;  // Promediar a la baja
        }
    }
    
    if(señalVenta)
    {
        if(ventas == 0)
        {
            abrirVenta = true;
        }
        else if(bid > precioPromVentas + distanciaPips || profitVentas < -3.0)
        {
            abrirVenta = true;  // Promediar al alza
        }
    }
    
    // Priorizar la dirección que va mejor
    if(abrirCompra && abrirVenta)
    {
        if(profitCompras >= profitVentas)
            abrirVenta = false;
        else
            abrirCompra = false;
    }
    
    // Ejecutar operación
    if(abrirCompra)
    {
        Print("Abriendo COMPRA adicional | Lote:", siguienteLote, " | Compras:", compras+1);
        AbrirPosicion(ORDER_TYPE_BUY, siguienteLote, ask);
    }
    else if(abrirVenta)
    {
        Print("Abriendo VENTA adicional | Lote:", siguienteLote, " | Ventas:", ventas+1);
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
    
    double sl = 0, tp = 0;
    
    // Calcular SL
    if(tipo == ORDER_TYPE_BUY)
    {
        sl = NormalizeDouble(precio - StopLossPips * point * 10, digits);
    }
    else
    {
        sl = NormalizeDouble(precio + StopLossPips * point * 10, digits);
    }
    
    // Normalizar lote
    lote = NormalizarLote(lote);
    
    if(tipo == ORDER_TYPE_BUY)
    {
        if(trade.Buy(lote, _Symbol, precio, sl, tp, "Scalping Martingale"))
        {
            Print("Compra abierta: Lote=", lote, " Precio=", precio);
        }
    }
    else
    {
        if(trade.Sell(lote, _Symbol, precio, sl, tp, "Scalping Martingale"))
        {
            Print("Venta abierta: Lote=", lote, " Precio=", precio);
        }
    }
}

//+------------------------------------------------------------------+
//| Calcular siguiente lote con martingala                           |
//+------------------------------------------------------------------+
double CalcularSiguienteLote()
{
    if(ArraySize(posiciones) == 0) return LoteInicial;
    
    // Encontrar el lote más grande
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
//| Actualizar información de posiciones                             |
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
               PositionGetInteger(POSITION_MAGIC) == 123456)
            {
                int idx = ArraySize(posiciones);
                ArrayResize(posiciones, idx + 1);
                
                posiciones[idx].ticket = ticket;
                posiciones[idx].lote = PositionGetDouble(POSITION_VOLUME);
                posiciones[idx].precioApertura = PositionGetDouble(POSITION_PRICE_OPEN);
                posiciones[idx].tipo = (int)PositionGetInteger(POSITION_TYPE);
                posiciones[idx].profit = PositionGetDouble(POSITION_PROFIT);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Contar posiciones abiertas                                       |
//+------------------------------------------------------------------+
int ContarPosicionesAbiertas()
{
    return ArraySize(posiciones);
}

//+------------------------------------------------------------------+
//| Calcular profit total                                            |
//+------------------------------------------------------------------+
double CalcularProfitTotal()
{
    double total = 0;
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        total += posiciones[i].profit;
    }
    return total;
}

//+------------------------------------------------------------------+
//| Cerrar posiciones en profit individual                           |
//+------------------------------------------------------------------+
void CerrarPosicionesEnProfit()
{
    for(int i = ArraySize(posiciones) - 1; i >= 0; i--)
    {
        if(posiciones[i].profit >= ProfitMinimo)
        {
            if(trade.PositionClose(posiciones[i].ticket))
            {
                Print("Posición cerrada en profit: $", posiciones[i].profit);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Cerrar todas las posiciones                                      |
//+------------------------------------------------------------------+
void CerrarTodasLasPosiciones()
{
    for(int i = ArraySize(posiciones) - 1; i >= 0; i--)
    {
        trade.PositionClose(posiciones[i].ticket);
    }
    ArrayResize(posiciones, 0);
}

//+------------------------------------------------------------------+
//| Verificar reemplazo de posiciones                                |
//+------------------------------------------------------------------+
void VerificarReemplazo()
{
    // Si una posición cierra, se puede abrir otra
    // Esta función se ejecuta automáticamente por OnTick
}

//+------------------------------------------------------------------+
//| Gestionar Break Even                                             |
//+------------------------------------------------------------------+
void GestionarBreakEven()
{
    if(!UsarBreakEven) return;
    
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        double precioActual;
        double sl = 0;
        
        if(!PositionSelectByTicket(posiciones[i].ticket)) continue;
        
        sl = PositionGetDouble(POSITION_SL);
        
        if(posiciones[i].tipo == ORDER_TYPE_BUY)
        {
            precioActual = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double BE = NormalizeDouble(posiciones[i].precioApertura + BEPips * point * 10, digits);
            
            if(precioActual >= posiciones[i].precioApertura + BEActivacionPips * point * 10)
            {
                if(sl < posiciones[i].precioApertura)
                {
                    trade.PositionModify(posiciones[i].ticket, BE, 0);
                }
            }
        }
        else
        {
            precioActual = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double BE = NormalizeDouble(posiciones[i].precioApertura - BEPips * point * 10, digits);
            
            if(precioActual <= posiciones[i].precioApertura - BEActivacionPips * point * 10)
            {
                if(sl > posiciones[i].precioApertura || sl == 0)
                {
                    trade.PositionModify(posiciones[i].ticket, BE, 0);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Gestionar Trailing Stop                                          |
//+------------------------------------------------------------------+
void GestionarTrailingStop()
{
    if(!UsarTrailingStop) return;
    
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        double precioActual;
        double sl = 0;
        
        if(!PositionSelectByTicket(posiciones[i].ticket)) continue;
        
        sl = PositionGetDouble(POSITION_SL);
        
        if(posiciones[i].tipo == ORDER_TYPE_BUY)
        {
            precioActual = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            
            if(precioActual >= posiciones[i].precioApertura + TrailingStartPips * point * 10)
            {
                double nuevoSL = NormalizeDouble(precioActual - TrailingStepPips * point * 10, digits);
                
                if(nuevoSL > sl)
                {
                    trade.PositionModify(posiciones[i].ticket, nuevoSL, 0);
                }
            }
        }
        else
        {
            precioActual = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            
            if(precioActual <= posiciones[i].precioApertura - TrailingStartPips * point * 10)
            {
                double nuevoSL = NormalizeDouble(precioActual + TrailingStepPips * point * 10, digits);
                
                if(nuevoSL < sl || sl == 0)
                {
                    trade.PositionModify(posiciones[i].ticket, nuevoSL, 0);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Crear botones de control                                         |
//+------------------------------------------------------------------+
void CrearBotones()
{
    int x = 150;  // Más adentro del margen derecho
    int y = 80;   // Más arriba desde el borde inferior
    int ancho = 100;
    int alto = 30;
    
    // Botón Activar (Verde)
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
    
    // Botón Desactivar (Rojo)
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
    
    // Label de estado
    ObjectCreate(0, "LabelEstado", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "LabelEstado", OBJPROP_XDISTANCE, x - 20);
    ObjectSetInteger(0, "LabelEstado", OBJPROP_YDISTANCE, y + (alto + 10) * 2 + 5);
    ObjectSetInteger(0, "LabelEstado", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "LabelEstado", OBJPROP_COLOR, clrYellow);
    ObjectSetString(0, "LabelEstado", OBJPROP_TEXT, "BOT: INACTIVO");
    ObjectSetInteger(0, "LabelEstado", OBJPROP_FONTSIZE, 10);
    ObjectSetString(0, "LabelEstado", OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, "LabelEstado", OBJPROP_BACK, false);
    
    // Info de operaciones
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
//| Evento de clic en el gráfico                                     |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    if(id == CHARTEVENT_OBJECT_CLICK)
    {
        if(sparam == "BtnActivar")
        {
            BotActivo = true;
            ObjectSetString(0, "LabelEstado", OBJPROP_TEXT, "BOT: ACTIVO");
            ObjectSetInteger(0, "LabelEstado", OBJPROP_COLOR, clrLime);
            Print("Bot ACTIVADO");
            ObjectSetInteger(0, "BtnActivar", OBJPROP_STATE, false);
        }
        else if(sparam == "BtnDesactivar")
        {
            BotActivo = false;
            ObjectSetString(0, "LabelEstado", OBJPROP_TEXT, "BOT: INACTIVO");
            ObjectSetInteger(0, "LabelEstado", OBJPROP_COLOR, clrRed);
            Print("Bot DESACTIVADO");
            ObjectSetInteger(0, "BtnDesactivar", OBJPROP_STATE, false);
        }
        
        ChartRedraw();
    }
}
//+------------------------------------------------------------------+
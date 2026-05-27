//+------------------------------------------------------------------+
//|                          Martingala_Scalping_Claude_v3.mq5       |
//|                    VERSIÓN CONTROLADA - Con Límites              |
//+------------------------------------------------------------------+
#property copyright "Martingala Scalping Claude v3"
#property version   "3.00"
#property strict

#include <Trade\Trade.mqh>

// Parámetros de entrada
input group "=== CONFIGURACIÓN GENERAL ==="
input double   LoteInicial = 0.01;           // Lote inicial
input int      MaxOperaciones = 3;           // Máximo TOTAL de operaciones
input int      MaxPorDireccion = 2;          // Máximo por dirección (BUY o SELL)
input double   ProfitMinimo = 1.5;           // Profit para cerrar individual (USD)
input double   ProfitTotal = 8.0;            // Profit total para cerrar todo (USD)
input double   StopLossPips = 50;            // Stop Loss en pips
input double   PerdidaMaximaDiaria = 50.0;   // Pérdida máxima diaria antes de detener (USD)

input group "=== MARTINGALA CONTROLADA ==="
input double   MultiplicadorLote = 1.3;      // Multiplicador más conservador
input int      DistanciaMinimaPips = 20;     // Distancia MÍNIMA entre operaciones
input double   PerdidaParaContra = -3.0;     // Pérdida para contraoperación (más estricto)
input double   GananciaParaRefuerzo = 2.0;   // Ganancia para reforzar (más estricto)

input group "=== GESTIÓN DE RIESGO ==="
input bool     UsarBreakEven = true;         // Usar Break Even
input double   BEActivacionProfit = 1.0;     // Activación BE en USD
input double   BEPips = 1;                   // Pips de BE
input bool     UsarTrailingStop = true;      // Usar Trailing Stop
input double   TrailingStartProfit = 2.5;    // Inicio Trailing en USD
input double   TrailingStepPips = 1.5;       // Paso de Trailing (tu ajuste)

input group "=== SCALPING ==="
input double   TiempoMinimoSegundos = 15;    // Tiempo mínimo en operación

// Variables globales
CTrade trade;
bool BotActivo = false;
datetime ultimaBarra = 0;
double profitTotal = 0;
int totalOperaciones = 0;
bool alertaMaximaEmitida = false;
int contadorOperaciones = 0;
datetime ultimoRefuerzo = 0;
double perdidaDiaria = 0;
datetime ultimaResetPerdida = 0;

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
    trade.SetExpertMagicNumber(456789);
    trade.SetDeviationInPoints(10);
    trade.SetTypeFilling(ORDER_FILLING_FOK);
    
    CrearBotones();
    
    Print("═══════════════════════════════════════");
    Print("  Martingala Scalping Claude v3");
    Print("  VERSIÓN CONTROLADA Y SEGURA");
    Print("  Max por dirección: ", MaxPorDireccion);
    Print("  Distancia mínima: ", DistanciaMinimaPips, " pips");
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
    ObjectDelete(0, "LabelPerdida");
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    if(!BotActivo) return;
    
    // Resetear pérdida diaria
    ResetearPerdidaDiaria();
    
    ActualizarPosiciones();
    
    // Gestión continua
    GestionarBreakEvenRapido();
    GestionarTrailingStop();
    CerrarPosicionesRapidas();
    
    profitTotal = CalcularProfitTotal();
    
    // Actualizar interfaz
    string infoText = StringFormat("Ops: %d | P&L: $%.2f", totalOperaciones, profitTotal);
    ObjectSetString(0, "LabelInfo", OBJPROP_TEXT, infoText);
    ObjectSetInteger(0, "LabelInfo", OBJPROP_COLOR, profitTotal > 0 ? clrLime : (profitTotal < 0 ? clrRed : clrWhite));
    
    string perdidaText = StringFormat("Pérdida hoy: $%.2f / $%.0f", perdidaDiaria, PerdidaMaximaDiaria);
    ObjectSetString(0, "LabelPerdida", OBJPROP_TEXT, perdidaText);
    ObjectSetInteger(0, "LabelPerdida", OBJPROP_COLOR, perdidaDiaria < -30 ? clrRed : clrYellow);
    
    // STOP POR PÉRDIDA MÁXIMA DIARIA
    if(perdidaDiaria <= -PerdidaMaximaDiaria)
    {
        CerrarTodasLasPosiciones();
        BotActivo = false;
        ObjectSetString(0, "LabelEstado", OBJPROP_TEXT, "MSC v3: DETENIDO");
        ObjectSetInteger(0, "LabelEstado", OBJPROP_COLOR, clrRed);
        Alert("🛑 BOT DETENIDO - Pérdida máxima diaria alcanzada: $", MathAbs(perdidaDiaria));
        Print("🛑 BOT DETENIDO POR PÉRDIDA DIARIA: $", perdidaDiaria);
        return;
    }
    
    // Cerrar todo si alcanza objetivo
    if(profitTotal >= ProfitTotal)
    {
        CerrarTodasLasPosiciones();
        Print("🎯 OBJETIVO ALCANZADO: $", DoubleToString(profitTotal, 2));
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
        Alert("⚠️ Máximo de operaciones: ", totalOperaciones);
        PlaySound("alert.wav");
        alertaMaximaEmitida = true;
    }
    
    // LÓGICA DE ENTRADA
    if(totalOperaciones < MaxOperaciones)
    {
        alertaMaximaEmitida = false;
        
        if(totalOperaciones == 0 && nuevaBarra)
        {
            EvaluarPrimeraEntrada();
        }
        else if(totalOperaciones > 0)
        {
            GestionarRefuerzosControlados();
        }
    }
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Resetear pérdida diaria a las 00:00                              |
//+------------------------------------------------------------------+
void ResetearPerdidaDiaria()
{
    datetime ahora = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(ahora, dt);
    
    // Si es un nuevo día
    if(dt.hour == 0 && dt.min == 0 && ahora - ultimaResetPerdida > 3600)
    {
        perdidaDiaria = 0;
        ultimaResetPerdida = ahora;
        Print("📅 Nueva jornada - Pérdida diaria reseteada");
    }
}

//+------------------------------------------------------------------+
//| Primera entrada con tendencia clara                              |
//+------------------------------------------------------------------+
void EvaluarPrimeraEntrada()
{
    double close[];
    ArraySetAsSeries(close, true);
    if(CopyClose(_Symbol, PERIOD_M1, 0, 5, close) <= 0) return;
    
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // Calcular momentum más fuerte (3 velas)
    double momentum = close[0] - close[3];
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    double momentumPips = momentum / (point * 10);
    
    // ✅ Solo entra si hay TENDENCIA CLARA (>5 pips en 3 velas)
    if(momentumPips >= 5.0)
    {
        Print("🔵 PRIMERA COMPRA | Momentum: +", DoubleToString(momentumPips, 1), " pips");
        AbrirPosicion(ORDER_TYPE_BUY, LoteInicial, ask);
    }
    else if(momentumPips <= -5.0)
    {
        Print("🔴 PRIMERA VENTA | Momentum: ", DoubleToString(momentumPips, 1), " pips");
        AbrirPosicion(ORDER_TYPE_SELL, LoteInicial, bid);
    }
}

//+------------------------------------------------------------------+
//| NUEVO: Refuerzos CONTROLADOS con límites estrictos               |
//+------------------------------------------------------------------+
void GestionarRefuerzosControlados()
{
    datetime ahora = TimeCurrent();
    
    // Evitar refuerzos muy seguidos
    if(ahora - ultimoRefuerzo < 45) return;
    
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    // Contar operaciones por dirección
    int numCompras = 0, numVentas = 0;
    double profitCompras = 0, profitVentas = 0;
    double mejorProfitCompra = -9999, mejorProfitVenta = -9999;
    double precioMedioCompras = 0, precioMedioVentas = 0;
    
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        if(posiciones[i].tipo == ORDER_TYPE_BUY)
        {
            numCompras++;
            profitCompras += posiciones[i].profit;
            precioMedioCompras += posiciones[i].precioApertura;
            if(posiciones[i].profit > mejorProfitCompra) mejorProfitCompra = posiciones[i].profit;
        }
        else
        {
            numVentas++;
            profitVentas += posiciones[i].profit;
            precioMedioVentas += posiciones[i].precioApertura;
            if(posiciones[i].profit > mejorProfitVenta) mejorProfitVenta = posiciones[i].profit;
        }
    }
    
    if(numCompras > 0) precioMedioCompras /= numCompras;
    if(numVentas > 0) precioMedioVentas /= numVentas;
    
    double siguienteLote = CalcularSiguienteLote();
    
    // ✅ REGLA 1: Reforzar ganadora SI no excede límite
    if(mejorProfitCompra >= GananciaParaRefuerzo && numCompras < MaxPorDireccion)
    {
        // Verificar distancia mínima
        double distancia = (ask - precioMedioCompras) / (point * 10);
        if(MathAbs(distancia) >= DistanciaMinimaPips)
        {
            Print("💪 REFORZANDO COMPRA | Profit: $", DoubleToString(mejorProfitCompra, 2), " | Distancia: ", DoubleToString(distancia, 1), " pips");
            AbrirPosicion(ORDER_TYPE_BUY, siguienteLote, ask);
            ultimoRefuerzo = ahora;
            return;
        }
    }
    
    if(mejorProfitVenta >= GananciaParaRefuerzo && numVentas < MaxPorDireccion)
    {
        double distancia = (precioMedioVentas - bid) / (point * 10);
        if(MathAbs(distancia) >= DistanciaMinimaPips)
        {
            Print("💪 REFORZANDO VENTA | Profit: $", DoubleToString(mejorProfitVenta, 2), " | Distancia: ", DoubleToString(distancia, 1), " pips");
            AbrirPosicion(ORDER_TYPE_SELL, siguienteLote, bid);
            ultimoRefuerzo = ahora;
            return;
        }
    }
    
    // ✅ REGLA 2: Contraoperación SOLO si pérdida fuerte Y no hay del otro lado
    if(profitCompras <= PerdidaParaContra && numCompras > 0 && numVentas == 0 && numVentas < MaxPorDireccion)
    {
        Print("🔄 CONTRAOPERACIÓN VENTA | Pérdida compras: $", DoubleToString(profitCompras, 2));
        AbrirPosicion(ORDER_TYPE_SELL, siguienteLote, bid);
        ultimoRefuerzo = ahora;
        return;
    }
    
    if(profitVentas <= PerdidaParaContra && numVentas > 0 && numCompras == 0 && numCompras < MaxPorDireccion)
    {
        Print("🔄 CONTRAOPERACIÓN COMPRA | Pérdida ventas: $", DoubleToString(profitVentas, 2));
        AbrirPosicion(ORDER_TYPE_BUY, siguienteLote, ask);
        ultimoRefuerzo = ahora;
        return;
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
        if(trade.Buy(lote, _Symbol, precio, sl, 0, "MSC_v3"))
        {
            contadorOperaciones++;
            Print("✅ BUY #", contadorOperaciones, " | Lote:", lote, " | Precio:", precio);
        }
    }
    else
    {
        sl = NormalizeDouble(precio + StopLossPips * point * 10, digits);
        if(trade.Sell(lote, _Symbol, precio, sl, 0, "MSC_v3"))
        {
            contadorOperaciones++;
            Print("✅ SELL #", contadorOperaciones, " | Lote:", lote, " | Precio:", precio);
        }
    }
}

//+------------------------------------------------------------------+
//| Cerrar posiciones rápido                                         |
//+------------------------------------------------------------------+
void CerrarPosicionesRapidas()
{
    datetime ahora = TimeCurrent();
    
    for(int i = ArraySize(posiciones) - 1; i >= 0; i--)
    {
        int segundos = (int)(ahora - posiciones[i].tiempoApertura);
        
        if(segundos >= TiempoMinimoSegundos && posiciones[i].profit >= ProfitMinimo)
        {
            double profitCierre = posiciones[i].profit;
            if(trade.PositionClose(posiciones[i].ticket))
            {
                perdidaDiaria += profitCierre;
                Print("⚡ CERRADO: $", DoubleToString(profitCierre, 2), " en ", segundos, "s");
            }
        }
        else if(posiciones[i].profit >= 4.0)
        {
            double profitCierre = posiciones[i].profit;
            if(trade.PositionClose(posiciones[i].ticket))
            {
                perdidaDiaria += profitCierre;
                Print("⚡ CERRADO INMEDIATO: $", DoubleToString(profitCierre, 2));
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
               PositionGetInteger(POSITION_MAGIC) == 456789)
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
    {
        double profitCierre = posiciones[i].profit;
        if(trade.PositionClose(posiciones[i].ticket))
        {
            perdidaDiaria += profitCierre;
        }
    }
    ArrayResize(posiciones, 0);
}

//+------------------------------------------------------------------+
//| Break Even                                                        |
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
                    trade.PositionModify(posiciones[i].ticket, BE, 0);
            }
            else
            {
                BE = NormalizeDouble(posiciones[i].precioApertura - BEPips * point * 10, digits);
                if(sl > posiciones[i].precioApertura || sl == 0)
                    trade.PositionModify(posiciones[i].ticket, BE, 0);
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
    ObjectSetString(0, "LabelEstado", OBJPROP_TEXT, "MSC v3: INACTIVO");
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
    
    ObjectCreate(0, "LabelPerdida", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "LabelPerdida", OBJPROP_XDISTANCE, x - 20);
    ObjectSetInteger(0, "LabelPerdida", OBJPROP_YDISTANCE, y + (alto + 10) * 2 + 43);
    ObjectSetInteger(0, "LabelPerdida", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "LabelPerdida", OBJPROP_COLOR, clrYellow);
    ObjectSetString(0, "LabelPerdida", OBJPROP_TEXT, "Pérdida hoy: $0.00");
    ObjectSetInteger(0, "LabelPerdida", OBJPROP_FONTSIZE, 7);
    ObjectSetInteger(0, "LabelPerdida", OBJPROP_BACK, false);
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Eventos                                                          |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    if(id == CHARTEVENT_OBJECT_CLICK)
    {
        if(sparam == "BtnActivar")
        {
            BotActivo = true;
            ObjectSetString(0, "LabelEstado", OBJPROP_TEXT, "MSC v3: ACTIVO");
            ObjectSetInteger(0, "LabelEstado", OBJPROP_COLOR, clrLime);
            Print("🚀 Martingala Scalping Claude v3 ACTIVADO");
            ObjectSetInteger(0, "BtnActivar", OBJPROP_STATE, false);
        }
        else if(sparam == "BtnDesactivar")
        {
            BotActivo = false;
            ObjectSetString(0, "LabelEstado", OBJPROP_TEXT, "MSC v3: INACTIVO");
            ObjectSetInteger(0, "LabelEstado", OBJPROP_COLOR, clrRed);
            Print("⏸️ Bot DESACTIVADO");
            ObjectSetInteger(0, "BtnDesactivar", OBJPROP_STATE, false);
        }
        ChartRedraw();
    }
}
//+------------------------------------------------------------------+
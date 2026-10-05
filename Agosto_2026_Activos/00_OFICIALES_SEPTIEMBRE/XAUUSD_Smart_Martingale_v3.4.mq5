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
input double   StopLossPips = 70;            // Stop Loss en pips ($7.00 USD max por operación)

input group "=== MARTINGALA ==="
input double   MultiplicadorLote = 1.5;      // Multiplicador de lote
input int      DistanciaPips = 35;           // Distancia entre operaciones (pips)

input group "=== GESTIÓN DE RIESGO ==="
input bool     UsarBreakEven = true;         // Usar Break Even
input double   BEActivacionPips = 10;        // Activación BE en pips
input double   BEPips = 2;                   // Pips de BE
input bool     UsarTrailingStop = true;      // Usar Trailing Stop
input double   TrailingStartPips = 15;       // Inicio Trailing en pips
input double   TrailingStepPips = 5;         // Paso de Trailing en pips


input group "=== FILTRO HORARIO DE OPERACIÓN ==="
input bool     UsarFiltroHorario = true;                                                // ⏰ Activar Filtro Horario
input int      HoraInicio        = 3;                                                   // 🟢 Hora Inicio Broker (0-23, ej: 3 AM)
input int      HoraFin           = 22;                                                  // 🔴 Hora Fin Broker (0-23, ej: 22 PM)

input group "=== FILTRO DE TENDENCIA H1 ==="
input bool     UsarFiltroTendenciaH1 = true;                                            // 📈 Activar Filtro Tendencia H1 (EMA 200)
input int      EMA_Tendencia_H1      = 200;                                             // 📈 Período EMA Tendencia H1

input group "=== TELEGRAM NOTIFICACIONES ==="
input bool     UsarTelegramNotif = true;                                                // 📱 Activar Alertas Telegram
input string   TelegramBotToken  = "";                                                  // 🔑 Token del Bot Telegram
input string   TelegramChatID    = "906620572";                                         // 💬 Chat ID Telegram

input group "=== SEÑALES DE ENTRADA Y SOBRECOMPRA/SOBREVENTA ==="
input int      RSI_Periodo = 14;             // Período RSI
input double   RSI_Sobreventa = 40;          // Nivel sobreventa (Bloquea ventas si RSI < 40)
input double   RSI_Sobrecompra = 60;         // Nivel sobrecompra (Bloquea compras si RSI > 60)
input double   RSI_Reset_Compra = 35;        // Nivel de recuperación sobreventa (Reanuda compras)
input double   RSI_Reset_Venta = 65;         // Nivel de recuperación sobrecompra (Reanuda ventas)
input double   RatioCuerpoIndecision = 0.25; // Ratio máximo cuerpo/rango para considerar indecisión (25%)
input int      EMA_Rapida = 5;               // EMA rápida
input int      EMA_Lenta = 20;               // EMA lenta

// Variables globales
CTrade trade;
bool BotActivo = true;
datetime ultimaBarra = 0;
double profitTotal = 0;
int totalOperaciones = 0;
bool alertaMaximaEmitida = false;
bool sobrecompraBloqueo = false;
bool sobreventaBloqueo = false;
bool indecisionBloqueo = false;
bool horarioBloqueo = false;

// Handles de indicadores
int handleRSI;
int handleRSI_M30;
int handleRSI_H1;
int handleEMAFast;
int handleEMASlow;
int handleEMA200;
int handleEMA200_H1;

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
    // Inicializar indicadores en el timeframe actual del gráfico (_Period) y temporalidades superiores (M30 y H1)
    handleRSI = iRSI(_Symbol, _Period, RSI_Periodo, PRICE_CLOSE);
    handleRSI_M30 = iRSI(_Symbol, PERIOD_M30, RSI_Periodo, PRICE_CLOSE);
    handleRSI_H1  = iRSI(_Symbol, PERIOD_H1, RSI_Periodo, PRICE_CLOSE);
    handleEMAFast = iMA(_Symbol, _Period, EMA_Rapida, 0, MODE_EMA, PRICE_CLOSE);
    handleEMASlow = iMA(_Symbol, _Period, EMA_Lenta, 0, MODE_EMA, PRICE_CLOSE);
    handleEMA200 = iMA(_Symbol, PERIOD_M15, 200, 0, MODE_EMA, PRICE_CLOSE);
    handleEMA200_H1 = iMA(_Symbol, PERIOD_H1, EMA_Tendencia_H1, 0, MODE_EMA, PRICE_CLOSE);
    
    if(handleRSI == INVALID_HANDLE || handleRSI_M30 == INVALID_HANDLE || handleRSI_H1 == INVALID_HANDLE || handleEMAFast == INVALID_HANDLE || handleEMASlow == INVALID_HANDLE || handleEMA200 == INVALID_HANDLE || handleEMA200_H1 == INVALID_HANDLE)
    {
        Print("Error al crear indicadores");
        return(INIT_FAILED);
    }
    
    // Dibujar EMAs visualmente en el gráfico principal
    ChartIndicatorAdd(0, 0, handleEMAFast);
    ChartIndicatorAdd(0, 0, handleEMASlow);
    
    trade.SetExpertMagicNumber(123456);
    trade.SetDeviationInPoints(10);
    trade.SetTypeFilling(ORDER_FILLING_FOK);
    
    // Crear botones y HUD
    CrearBotones();
    if(MQLInfoInteger(MQL_TESTER)) BotActivo = true;
    
    Print("Bot de Scalping Martingale iniciado en timeframe ", EnumToString(_Period));
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Eliminar todo el HUD y botones
    ObjectsDeleteAll(0, "SMART_HUD_");
    ObjectsDeleteAll(0, "SMART_BTN_");
    ObjectDelete(0, "BtnActivar");
    ObjectDelete(0, "BtnDesactivar");
    ObjectDelete(0, "LabelEstado");
    ObjectDelete(0, "LabelInfo");
    
    // Liberar indicadores
    if(handleRSI != INVALID_HANDLE) IndicatorRelease(handleRSI);
    if(handleRSI_M30 != INVALID_HANDLE) IndicatorRelease(handleRSI_M30);
    if(handleRSI_H1 != INVALID_HANDLE) IndicatorRelease(handleRSI_H1);
    if(handleEMAFast != INVALID_HANDLE) IndicatorRelease(handleEMAFast);
    if(handleEMASlow != INVALID_HANDLE) IndicatorRelease(handleEMASlow);
    if(handleEMA200 != INVALID_HANDLE) IndicatorRelease(handleEMA200);
    if(handleEMA200_H1 != INVALID_HANDLE) IndicatorRelease(handleEMA200_H1);
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Actualizar datos y HUD siempre (incluso si está en pausa)
    ActualizarPosiciones();
    profitTotal = CalcularProfitTotal();
    totalOperaciones = ContarPosicionesAbiertas();
    ActualizarHUD();
    
    if(!BotActivo) return;
    
    // Gestión de posiciones existentes
    GestionarBreakEven();
    GestionarTrailingStop();
    
    // Cerrar todo si alcanza profit ideal
    if(profitTotal >= ProfitIdeal)
    {
        CerrarTodasLasPosiciones();
        Print("Profit ideal alcanzado: $", profitTotal);
        EnviarTelegram(StringFormat("💰 *XAUUSD MARTINGALE*\nCesta cerrada en PROFIT!\nGanancia: $%.2f", profitTotal));
        ActualizarHUD();
        return;
    }
    
    // Cerrar posiciones individuales en profit
    CerrarPosicionesEnProfit();
    
    // Verificar si hay nueva barra en el timeframe actual
    datetime tiempoActual = iTime(_Symbol, _Period, 0);
    bool nuevaBarra = (tiempoActual != ultimaBarra);
    if(nuevaBarra) ultimaBarra = tiempoActual;
    
    // Alerta si alcanza máximo de operaciones
    if(totalOperaciones >= MaxOperaciones && !alertaMaximaEmitida)
    {
        // Silencioso: sin popups emergentes ni campanas
        alertaMaximaEmitida = true;
    }
    
    if(totalOperaciones < MaxOperaciones)
    {
        alertaMaximaEmitida = false;
        
        // Evaluar nuevas entradas
        if(nuevaBarra || totalOperaciones == 0)
        {
            EvaluarEntradas();
        }
    }
    else
    {
        VerificarReemplazo();
    }
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Verificar Filtro Horario                                         |
//+------------------------------------------------------------------+
bool EsHorarioPermitido()
{
    if(!UsarFiltroHorario) return true;
    
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    int h = dt.hour;
    
    if(HoraInicio <= HoraFin)
    {
        return (h >= HoraInicio && h < HoraFin);
    }
    else
    {
        return (h >= HoraInicio || h < HoraFin);
    }
}

//+------------------------------------------------------------------+
//| Evaluar señales de entrada                                       |
//+------------------------------------------------------------------+
void EvaluarEntradas()
{
    horarioBloqueo = !EsHorarioPermitido();
    
    double rsi[], emaFast[], emaSlow[];
    ArraySetAsSeries(rsi, true);
    ArraySetAsSeries(emaFast, true);
    ArraySetAsSeries(emaSlow, true);
    
    if(CopyBuffer(handleRSI, 0, 0, 3, rsi) <= 0) return;
    if(CopyBuffer(handleEMAFast, 0, 0, 3, emaFast) <= 0) return;
    if(CopyBuffer(handleEMASlow, 0, 0, 3, emaSlow) <= 0) return;
    double ema200[1];
    if(CopyBuffer(handleEMA200, 0, 0, 1, ema200) <= 0) return;
    
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // EVALUAR FILTRO DE TENDENCIA H1 (EMA 200 H1)
    double ema200H1buf[1];
    bool tendenciaH1_Alcista = true;
    bool tendenciaH1_Bajista = true;
    
    if(UsarFiltroTendenciaH1 && CopyBuffer(handleEMA200_H1, 0, 0, 1, ema200H1buf) > 0)
    {
        tendenciaH1_Alcista = (ask > ema200H1buf[0]); // Solo Compras si precio > EMA 200 H1
        tendenciaH1_Bajista = (bid < ema200H1buf[0]); // Solo Ventas si precio < EMA 200 H1
    }
    
    // 1. Detectar velas de indecisión (Doji / Peineta / Cuerpo muy pequeño vs mechas)
    double open1  = iOpen(_Symbol, _Period, 1);
    double close1 = iClose(_Symbol, _Period, 1);
    double high1  = iHigh(_Symbol, _Period, 1);
    double low1   = iLow(_Symbol, _Period, 1);
    
    double rangoTotal = high1 - low1;
    double cuerpo = MathAbs(close1 - open1);
    
    indecisionBloqueo = false;
    if(rangoTotal > 0)
    {
        if((cuerpo / rangoTotal) < RatioCuerpoIndecision)
        {
            indecisionBloqueo = true; // Vela de indecisión detectada
        }
    }
    
    // 2. Actualizar estados de bloqueo por sobrecompra / sobreventa extrema (Multi-Timeframe M2 + M30 + H1)
    double rsiM30[1], rsiH1[1];
    double rsiM30Val = 50.0, rsiH1Val = 50.0;
    if(CopyBuffer(handleRSI_M30, 0, 0, 1, rsiM30) > 0) rsiM30Val = rsiM30[0];
    if(CopyBuffer(handleRSI_H1, 0, 0, 1, rsiH1) > 0)   rsiH1Val = rsiH1[0];

    // Si M2, M30 o H1 está en sobrecompra (>= 68), se bloquea cualquier nueva compra
    if(rsi[0] >= RSI_Sobrecompra || rsiM30Val >= 68.0 || rsiH1Val >= 68.0)
    {
        sobrecompraBloqueo = true;
    }
    else if(rsi[0] <= RSI_Reset_Venta && rsiM30Val < 65.0 && rsiH1Val < 65.0)
    {
        sobrecompraBloqueo = false; // Se libera cuando el precio cae a un nivel normal en todas las temporalidades
    }
    
    // Si M2, M30 o H1 está en sobreventa (<= 32), se bloquea cualquier nueva venta
    if(rsi[0] <= RSI_Sobreventa || rsiM30Val <= 32.0 || rsiH1Val <= 32.0)
    {
        sobreventaBloqueo = true;
    }
    else if(rsi[0] >= RSI_Reset_Compra && rsiM30Val > 35.0 && rsiH1Val > 35.0)
    {
        sobreventaBloqueo = false; // Se libera cuando el precio sube a un nivel normal en todas las temporalidades
    }
    
        // FILTRO UNICO Y QUIRÚRGICO: No vender en Suelo M15 / No comprar en Techo M15
    double maxM15 = iHigh(_Symbol, PERIOD_M15, iHighest(_Symbol, PERIOD_M15, MODE_HIGH, 20, 1));
    double minM15 = iLow(_Symbol, PERIOD_M15, iLowest(_Symbol, PERIOD_M15, MODE_LOW, 20, 1));
    double margenSueloTechoPips = 5.0 * _Point * 10;
    
    bool enSueloM15 = (bid <= minM15 + margenSueloTechoPips);
    bool enTechoM15 = (ask >= maxM15 - margenSueloTechoPips);

    bool señalCompra = false;
    bool señalVenta = false;
    
    // === REGLA ESTRICTA PRO-TENDENCIA + FILTROS ===
    // 1. Para COMPRA: EMA rápida > EMA lenta, ASK > EMA lenta, RSI < 70, sin sobrecompra, SIN indecisión, DENTRO DE HORARIO y TENDENCIA ALCISTA H1.
    if(emaFast[0] > emaSlow[0] && ask > emaSlow[0] && !enTechoM15 && rsi[0] < RSI_Sobrecompra && !sobrecompraBloqueo && !indecisionBloqueo && !horarioBloqueo && tendenciaH1_Alcista)
    {
        señalCompra = true;
    }
    
    // 2. Para VENTA: EMA rápida < EMA lenta, BID < EMA lenta, RSI > 30, sin sobreventa, SIN indecisión, DENTRO DE HORARIO y TENDENCIA BAJISTA H1.
    if(emaFast[0] < emaSlow[0] && bid < emaSlow[0] && !enSueloM15 && rsi[0] > RSI_Sobreventa && !sobreventaBloqueo && !indecisionBloqueo && !horarioBloqueo && tendenciaH1_Bajista)
    {
        señalVenta = true;
    }
    
    // Verificar si necesitamos abrir posición
    if(totalOperaciones == 0)
    {
        if(señalCompra)
        {
            Print("Señal PRO-TENDENCIA COMPRA detectada | RSI:", rsi[0], " | EMA Fast:", emaFast[0], " | EMA Slow:", emaSlow[0]);
            AbrirPosicion(ORDER_TYPE_BUY, LoteInicial, ask);
        }
        else if(señalVenta)
        {
            Print("Señal PRO-TENDENCIA VENTA detectada | RSI:", rsi[0], " | EMA Fast:", emaFast[0], " | EMA Slow:", emaSlow[0]);
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
        else if(ask < precioPromCompras - distanciaPips)
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
        else if(bid > precioPromVentas + distanciaPips)
        {
            abrirVenta = true;  // Promediar al alza
        }
    }
    
    if(abrirCompra && abrirVenta)
    {
        if(profitCompras >= profitVentas) abrirVenta = false;
        else abrirCompra = false;
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
    
    int numOpsActuales = ContarPosicionesAbiertas() + 1;
    int cOps = 0, vOps = 0;
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        if(posiciones[i].tipo == ORDER_TYPE_BUY) cOps++;
        else vOps++;
    }
    if(tipo == ORDER_TYPE_BUY) cOps++; else vOps++;
    
    double accBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    string dirStr = (tipo == ORDER_TYPE_BUY) ? "COMPRA" : "VENTA";
    
    if(tipo == ORDER_TYPE_BUY)
    {
        if(trade.Buy(lote, _Symbol, precio, sl, tp, "Scalping Martingale"))
        {
            Print("Compra abierta: Lote=", lote, " Precio=", precio);
            string msg = StringFormat("🚀 *XAUUSD SMART MARTINGALE*\n"
                                      "🔹 *Nueva %s Abierta* (Operación %d de %d)\n"
                                      "📊 Lote: `%.2f` | Precio: `%.2f` \n"
                                      "📈 Estado Cesta: %d Compras / %d Ventas\n"
                                      "💰 Balance Cuenta: `$%.2f USD`",
                                      dirStr, numOpsActuales, MaxOperaciones, lote, precio, cOps, vOps, accBalance);
            EnviarTelegram(msg);
        }
    }
    else
    {
        if(trade.Sell(lote, _Symbol, precio, sl, tp, "Scalping Martingale"))
        {
            Print("Venta abierta: Lote=", lote, " Precio=", precio);
            string msg = StringFormat("🚀 *XAUUSD SMART MARTINGALE*\n"
                                      "🔹 *Nueva %s Abierta* (Operación %d de %d)\n"
                                      "📊 Lote: `%.2f` | Precio: `%.2f` \n"
                                      "📈 Estado Cesta: %d Compras / %d Ventas\n"
                                      "💰 Balance Cuenta: `$%.2f USD`",
                                      dirStr, numOpsActuales, MaxOperaciones, lote, precio, cOps, vOps, accBalance);
            EnviarTelegram(msg);
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
//+------------------------------------------------------------------+
//| NUEVA INTERFAZ HUD (Elegante, Opaco, Esquina Superior Izquierda) |
//+------------------------------------------------------------------+
void CrearBotones()
{
    CrearHUD();
}

void CrearHUD()
{
    int x = 15;   // Esquina Superior Izquierda (Sin tapar velas)
    int y = 25;
    int w = 255;
    int h = 240;
    
    // 1. Panel de Fondo 100% OPACO (Sin transparencia)
    ObjectCreate(0, "SMART_HUD_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "SMART_HUD_BG", OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, "SMART_HUD_BG", OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, "SMART_HUD_BG", OBJPROP_XSIZE, w);
    ObjectSetInteger(0, "SMART_HUD_BG", OBJPROP_YSIZE, h);
    ObjectSetInteger(0, "SMART_HUD_BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, "SMART_HUD_BG", OBJPROP_BGCOLOR, C'20,24,33'); // Gris oscuro antracita opaco
    ObjectSetInteger(0, "SMART_HUD_BG", OBJPROP_BORDER_COLOR, C'60,75,95');
    ObjectSetInteger(0, "SMART_HUD_BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, "SMART_HUD_BG", OBJPROP_BACK, false);
    
    // 2. Encabezado Título
    CrearLabel("SMART_HUD_L0", x+15, y+10, "=== SMART MARTINGALE v3.4 ===", clrGold, 9, true);
    
    // 3. Líneas de Métricas
    CrearLabel("SMART_HUD_L1", x+15, y+30, "ESTADO: PAUSADO ⏸️", clrTomato, 9, true);
    CrearLabel("SMART_HUD_BAL", x+15, y+48, "BALANCE: $0.00 USD 🏦", clrYellow, 9, true);
    CrearLabel("SMART_HUD_L2", x+15, y+66, "GANADO HOY: $0.00", clrWhite, 8, false);
    CrearLabel("SMART_HUD_L3", x+15, y+84, "FLOTANTE: $0.00", clrWhite, 9, true);
    CrearLabel("SMART_HUD_L4", x+15, y+102, "OPS: 0 / 5  (0.00 Lotes)", clrCyan, 8, false);
    CrearLabel("SMART_HUD_L5", x+15, y+120, "RSI: -- | SPREAD: --", clrSilver, 8, false);
    CrearLabel("SMART_HUD_L6", x+15, y+138, "ENTRADAS: NORMAL (OK)", clrSpringGreen, 8, true);
    
    // 4. Botón Único de Toggle
    ObjectCreate(0, "SMART_BTN_TOGGLE", OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, "SMART_BTN_TOGGLE", OBJPROP_XDISTANCE, x+12);
    ObjectSetInteger(0, "SMART_BTN_TOGGLE", OBJPROP_YDISTANCE, y+158);
    ObjectSetInteger(0, "SMART_BTN_TOGGLE", OBJPROP_XSIZE, w-24);
    ObjectSetInteger(0, "SMART_BTN_TOGGLE", OBJPROP_YSIZE, 30);
    ObjectSetInteger(0, "SMART_BTN_TOGGLE", OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, "SMART_BTN_TOGGLE", OBJPROP_BGCOLOR, C'130,35,35'); // Rojo si está pausado
    ObjectSetInteger(0, "SMART_BTN_TOGGLE", OBJPROP_COLOR, clrWhite);
    ObjectSetString(0, "SMART_BTN_TOGGLE", OBJPROP_TEXT, "🔴 BOT PAUSADO (PULSA ACTIVAR)");
    ObjectSetInteger(0, "SMART_BTN_TOGGLE", OBJPROP_FONTSIZE, 8);
    ObjectSetString(0, "SMART_BTN_TOGGLE", OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, "SMART_BTN_TOGGLE", OBJPROP_BACK, false);

    // 5. Botón de Cierre de Emergencia
    ObjectCreate(0, "SMART_BTN_CLOSE", OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, "SMART_BTN_CLOSE", OBJPROP_XDISTANCE, x+12);
    ObjectSetInteger(0, "SMART_BTN_CLOSE", OBJPROP_YDISTANCE, y+194);
    ObjectSetInteger(0, "SMART_BTN_CLOSE", OBJPROP_XSIZE, w-24);
    ObjectSetInteger(0, "SMART_BTN_CLOSE", OBJPROP_YSIZE, 24);
    ObjectSetInteger(0, "SMART_BTN_CLOSE", OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, "SMART_BTN_CLOSE", OBJPROP_BGCOLOR, C'40,48,60');
    ObjectSetInteger(0, "SMART_BTN_CLOSE", OBJPROP_COLOR, clrWhite);
    ObjectSetString(0, "SMART_BTN_CLOSE", OBJPROP_TEXT, "❌ CERRAR TODAS LAS OPERACIONES");
    ObjectSetInteger(0, "SMART_BTN_CLOSE", OBJPROP_FONTSIZE, 8);
    ObjectSetInteger(0, "SMART_BTN_CLOSE", OBJPROP_BACK, false);

    ActualizarHUD();
    ChartRedraw();
}

void CrearLabel(string name, int x, int y, string text, color col, int fontSize, bool isBold)
{
    ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_COLOR, col);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
    if(isBold) ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
    else ObjectSetString(0, name, OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
}

void ActualizarHUD()
{
    // 0. Balance de la cuenta
    double balanceAcc = AccountInfoDouble(ACCOUNT_BALANCE);
    string txtBalance = StringFormat("BALANCE: $%.2f USD 🏦", balanceAcc);
    ObjectSetString(0, "SMART_HUD_BAL", OBJPROP_TEXT, txtBalance);
    ObjectSetInteger(0, "SMART_HUD_BAL", OBJPROP_COLOR, clrYellow);

    // 1. Estado y Botón Toggle
    if(BotActivo)
    {
        ObjectSetString(0, "SMART_HUD_L1", OBJPROP_TEXT, "ESTADO: BOT ONLINE ✅");
        ObjectSetInteger(0, "SMART_HUD_L1", OBJPROP_COLOR, clrSpringGreen);
        
        ObjectSetString(0, "SMART_BTN_TOGGLE", OBJPROP_TEXT, "🟢 BOT ONLINE (PULSA PAUSAR)");
        ObjectSetInteger(0, "SMART_BTN_TOGGLE", OBJPROP_BGCOLOR, C'25,85,45'); // Verde Oscuro
    }
    else
    {
        ObjectSetString(0, "SMART_HUD_L1", OBJPROP_TEXT, "ESTADO: PAUSADO ⏸️");
        ObjectSetInteger(0, "SMART_HUD_L1", OBJPROP_COLOR, clrTomato);
        
        ObjectSetString(0, "SMART_BTN_TOGGLE", OBJPROP_TEXT, "🔴 BOT PAUSADO (PULSA ACTIVAR)");
        ObjectSetInteger(0, "SMART_BTN_TOGGLE", OBJPROP_BGCOLOR, C'130,35,35'); // Rojo Oscuro
    }

    // 2. Ganado Hoy (Cerrado)
    double ganadoHoy = CalcularGanadoHoy();
    string txtHoy = StringFormat("GANADO HOY: %+.2f USD", ganadoHoy);
    ObjectSetString(0, "SMART_HUD_L2", OBJPROP_TEXT, txtHoy);
    ObjectSetInteger(0, "SMART_HUD_L2", OBJPROP_COLOR, (ganadoHoy > 0 ? clrLime : (ganadoHoy < 0 ? clrRed : clrGold)));

    // 3. Flotante Actual P&L
    double flotante = CalcularProfitTotal();
    string txtFloat = StringFormat("FLOTANTE P&L: %+.2f USD", flotante);
    ObjectSetString(0, "SMART_HUD_L3", OBJPROP_TEXT, txtFloat);
    ObjectSetInteger(0, "SMART_HUD_L3", OBJPROP_COLOR, (flotante > 0 ? clrLime : (flotante < 0 ? clrRed : clrWhite)));

    // 4. Posiciones y Lote Total
    int numOps = ContarPosicionesAbiertas();
    double lotes = CalcularLoteTotal();
    string txtOps = StringFormat("OPS: %d / %d  (%.2f Lotes)", numOps, MaxOperaciones, lotes);
    ObjectSetString(0, "SMART_HUD_L4", OBJPROP_TEXT, txtOps);

    // 5. RSI Multi-Timeframe y Spread
    double rsiVal = ObtenerRSIActual();
    double rsiM30buf[1], rsiH1buf[1];
    double rsiM30val = 50.0, rsiH1val = 50.0;
    if(CopyBuffer(handleRSI_M30, 0, 0, 1, rsiM30buf) > 0) rsiM30val = rsiM30buf[0];
    if(CopyBuffer(handleRSI_H1, 0, 0, 1, rsiH1buf) > 0)   rsiH1val = rsiH1buf[0];
    
    double spreadVal = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / SymbolInfoDouble(_Symbol, SYMBOL_POINT) / 10.0;
    string tfName = StringSubstr(EnumToString(_Period), 7);
    string txtRsi = StringFormat("RSI: %s:%.0f | M30:%.0f | H1:%.0f", tfName, rsiVal, rsiM30val, rsiH1val);
    ObjectSetString(0, "SMART_HUD_L5", OBJPROP_TEXT, txtRsi);

    // 6. Indicador de Sobrecompra / Sobreventa / Indecisión / Horario
    if(horarioBloqueo)
    {
        ObjectSetString(0, "SMART_HUD_L6", OBJPROP_TEXT, "ENTRADAS: ⏰ FUERA DE HORARIO");
        ObjectSetInteger(0, "SMART_HUD_L6", OBJPROP_COLOR, clrOrangeRed);
    }
    else if(indecisionBloqueo)
    {
        ObjectSetString(0, "SMART_HUD_L6", OBJPROP_TEXT, "ENTRADAS: ⚠️ INDECISIÓN (DOJI)");
        ObjectSetInteger(0, "SMART_HUD_L6", OBJPROP_COLOR, clrOrange);
    }
    else if(sobrecompraBloqueo || rsiVal >= RSI_Sobrecompra)
    {
        ObjectSetString(0, "SMART_HUD_L6", OBJPROP_TEXT, "ENTRADAS: ⚠️ SOBRECOMPRA (PAUSA)");
        ObjectSetInteger(0, "SMART_HUD_L6", OBJPROP_COLOR, clrOrangeRed);
    }
    else if(sobreventaBloqueo || rsiVal <= RSI_Sobreventa)
    {
        ObjectSetString(0, "SMART_HUD_L6", OBJPROP_TEXT, "ENTRADAS: ⚠️ SOBREVENTA (PAUSA)");
        ObjectSetInteger(0, "SMART_HUD_L6", OBJPROP_COLOR, clrOrangeRed);
    }
    else
    {
        ObjectSetString(0, "SMART_HUD_L6", OBJPROP_TEXT, "ENTRADAS: NORMAL (OK)");
        ObjectSetInteger(0, "SMART_HUD_L6", OBJPROP_COLOR, clrSpringGreen);
    }

    ChartRedraw();
}

double CalcularLoteTotal()
{
    double sum = 0.0;
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        sum += posiciones[i].lote;
    }
    return sum;
}

double CalcularGanadoHoy()
{
    datetime inicioHoy = iTime(_Symbol, PERIOD_D1, 0);
    HistorySelect(inicioHoy, TimeCurrent());
    double ganado = 0.0;
    int totalDeals = HistoryDealsTotal();
    for(int i = 0; i < totalDeals; i++)
    {
        ulong ticket = HistoryDealGetTicket(i);
        if(ticket > 0)
        {
            long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
            if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_INOUT)
            {
                long magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
                if(magic == 123456 || magic == 0)
                {
                    ganado += HistoryDealGetDouble(ticket, DEAL_PROFIT) + HistoryDealGetDouble(ticket, DEAL_SWAP) + HistoryDealGetDouble(ticket, DEAL_COMMISSION);
                }
            }
        }
    }
    return ganado;
}

double ObtenerRSIActual()
{
    double rsiBuf[1];
    if(handleRSI != INVALID_HANDLE && CopyBuffer(handleRSI, 0, 0, 1, rsiBuf) > 0)
        return rsiBuf[0];
    return 50.0;
}

//+------------------------------------------------------------------+
//| Evento de clic en el gráfico                                     |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    if(id == CHARTEVENT_OBJECT_CLICK)
    {
        ObjectSetInteger(0, sparam, OBJPROP_STATE, false);

        if(sparam == "SMART_BTN_TOGGLE" || sparam == "BtnActivar" || sparam == "BtnDesactivar")
        {
            BotActivo = !BotActivo;
            Print("Bot ", BotActivo ? "ACTIVADO" : "DESACTIVADO");
            ActualizarHUD();
        }
        else if(sparam == "SMART_BTN_CLOSE")
        {
            CerrarTodasLasPosiciones();
            Print("Cierre manual de todas las operaciones ejecutado desde el HUD.");
            ActualizarHUD();
        }
        
        ChartRedraw();
    }
}

//+------------------------------------------------------------------+
//| Evento de transacción de trading (para alertas de cierre)       |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                         const MqlTradeRequest &request,
                         const MqlTradeResult &result)
{
    if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
    {
        ulong dealTicket = trans.deal;
        if(dealTicket > 0)
        {
            if(HistoryDealSelect(dealTicket))
            {
                long magic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
                string symbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);
                long entry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
                
                if(symbol == _Symbol && (magic == 123456 || magic == 0))
                {
                    if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_INOUT)
                    {
                        double p = HistoryDealGetDouble(dealTicket, DEAL_PROFIT) + 
                                   HistoryDealGetDouble(dealTicket, DEAL_SWAP) + 
                                   HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
                        double volume = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
                        long dealType = HistoryDealGetInteger(dealTicket, DEAL_TYPE);
                        string tipoStr = (dealType == DEAL_TYPE_BUY) ? "VENTA CERRADA" : "COMPRA CERRADA";
                        
                        double accBalance = AccountInfoDouble(ACCOUNT_BALANCE);
                        double gHoy = CalcularGanadoHoy();
                        
                        if(p >= 0)
                        {
                            string msg = StringFormat("✅ *XAUUSD SMART MARTINGALE*\n"
                                                      "🎉 *%s en GANANCIA!*\n"
                                                      "📊 Volumen: `%.2f` Lotes\n"
                                                      "💵 Resultado: `+$%.2f USD` 💰\n"
                                                      "📈 Ganado Hoy: `%+.2f USD`\n"
                                                      "🏦 Balance Cuenta: `$%.2f USD`",
                                                      tipoStr, volume, p, gHoy, accBalance);
                            EnviarTelegram(msg);
                        }
                        else
                        {
                            string msg = StringFormat("❌ *XAUUSD SMART MARTINGALE*\n"
                                                      "⚠️ *%s en PÉRDIDA*\n"
                                                      "📊 Volumen: `%.2f` Lotes\n"
                                                      "📉 Resultado: `-$%.2f USD` ⚠️\n"
                                                      "📈 Ganado Hoy: `%+.2f USD`\n"
                                                      "🏦 Balance Cuenta: `$%.2f USD`",
                                                      tipoStr, volume, MathAbs(p), gHoy, accBalance);
                            EnviarTelegram(msg);
                        }
                    }
                }
            }
        }
    }
}
void EnviarTelegram(string msg)
{
    if(!UsarTelegramNotif || TelegramBotToken == "" || TelegramChatID == "" || MQLInfoInteger(MQL_TESTER)) return;
    
    string url = "https://api.telegram.org/bot" + TelegramBotToken + "/sendMessage";
    string postData = "chat_id=" + TelegramChatID + "&text=" + msg + "&parse_mode=Markdown";
    
    char post[];
    StringToCharArray(postData, post, 0, StringLen(postData), CP_UTF8);
    char result[];
    string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
    string resHeaders;
    
    WebRequest("POST", url, headers, 3000, post, result, resHeaders);
}

//+------------------------------------------------------------------+
//|                          Martingala_Scalping_Claude_v4.3.mq5     |
//|                    ORO OPTIMIZADO - CONTROL ULTRA ESTRICTO       |
//+------------------------------------------------------------------+
#property copyright "Martingala Scalping Claude v4.3"
#property version   "4.30"
#property strict

#include <Trade\Trade.mqh>

// Enumeración de pares
enum ENUM_PAR_TRADING
{
    PAR_AUTO = 0,
    PAR_EURUSD = 1,
    PAR_GBPUSD = 2,
    PAR_USDJPY = 3,
    PAR_AUDUSD = 4,
    PAR_USDCAD = 5,
    PAR_XAUUSD = 6,
    PAR_CUSTOM = 99
};

// Parámetros de entrada
input group "=== SELECCIÓN DE PAR ==="
input ENUM_PAR_TRADING ParTrading = PAR_AUTO;

input group "=== CONFIGURACIÓN GENERAL ==="
input double   LoteInicial = 0.01;
input int      MaxOperaciones = 3;              // LÍMITE ABSOLUTO
input double   PerdidaMaximaDiaria = 50.0;

input group "=== ESTRATEGIA ==="
input bool     Operacion3SoloEnBE = true;
input bool     AlertaSilenciosa = true;
input int      CooldownSegundos = 30;           // Tiempo mínimo entre operaciones
input int      MaxSLConsecutivos = 3;           // Stop después de X SL seguidos

input group "=== AJUSTES ORO (XAUUSD) ==="
input double   ORO_StopLoss = 80.0;             // SL ampliado para volatilidad
input double   ORO_BEActivacion = 0.50;         // BE más rápido
input double   ORO_TrailingStart = 0.80;        // Trailing más temprano
input double   ORO_MultiplicadorLote = 1.8;     // Martingala más agresiva

// Variables de parámetros dinámicos
double ProfitMinimo;
double ProfitTotal;
double StopLossPips;
double MomentumMinimoPips;
int DistanciaMinimaPips;
double MultiplicadorLote;
double PerdidaParaContra;
double GananciaParaRefuerzo;
double BEActivacionProfit;
double BEPips;
double TrailingStartProfit;
double TrailingStepPips;
double TiempoMinimoSegundos;
string NombrePar;

// Variables globales de control
CTrade trade;
bool BotActivo = false;
datetime ultimaBarra = 0;
double profitTotal = 0;
int totalOperaciones = 0;
bool alertaMaximaEmitida = false;
int contadorOperaciones = 0;
datetime ultimoRefuerzo = 0;
datetime ultimaApertura = 0;          // Control de cooldown
double perdidaDiaria = 0;
datetime ultimaResetPerdida = 0;
bool hayOperacionEnBE = false;
int SLconsecutivos = 0;               // Contador de SL seguidos
datetime tiempoPausa = 0;             // Control de pausa automática

struct PosicionInfo {
    ulong ticket;
    double lote;
    double precioApertura;
    int tipo;
    double profit;
    datetime tiempoApertura;
    bool enBreakEven;
};

PosicionInfo posiciones[];

//+------------------------------------------------------------------+
int OnInit()
{
    ConfigurarParametrosPorPar();
    
    trade.SetExpertMagicNumber(901234);
    trade.SetDeviationInPoints(10);
    trade.SetTypeFilling(ORDER_FILLING_FOK);
    
    CrearBotones();
    
    Print("═══════════════════════════════════════");
    Print("  MSC v4.3 - ORO OPTIMIZADO");
    Print("  Par: ", NombrePar);
    Print("  SL: ", StopLossPips, " pips");
    Print("  BE: $", BEActivacionProfit);
    Print("  Trailing: $", TrailingStartProfit);
    Print("  Cooldown: ", CooldownSegundos, "s");
    Print("  Max Ops: ", MaxOperaciones, " ESTRICTO");
    Print("═══════════════════════════════════════");
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void ConfigurarParametrosPorPar()
{
    string symbol = _Symbol;
    ENUM_PAR_TRADING parDetectado = PAR_CUSTOM;
    
    if(ParTrading == PAR_AUTO)
    {
        if(StringFind(symbol, "EURUSD") >= 0 || StringFind(symbol, "EUR") >= 0)
            parDetectado = PAR_EURUSD;
        else if(StringFind(symbol, "XAUUSD") >= 0 || StringFind(symbol, "XAU") >= 0 || StringFind(symbol, "GOLD") >= 0)
            parDetectado = PAR_XAUUSD;
        else
            parDetectado = PAR_CUSTOM;
    }
    else
    {
        parDetectado = ParTrading;
    }
    
    switch(parDetectado)
    {
        case PAR_EURUSD:
            NombrePar = "EURUSD";
            ProfitMinimo = 1.0;
            ProfitTotal = 6.0;
            StopLossPips = 35;
            MomentumMinimoPips = 2.0;
            DistanciaMinimaPips = 12;
            MultiplicadorLote = 1.4;
            PerdidaParaContra = -1.5;
            GananciaParaRefuerzo = 1.5;
            BEActivacionProfit = 0.60;
            BEPips = 1;
            TrailingStartProfit = 1.5;
            TrailingStepPips = 1.5;
            TiempoMinimoSegundos = 20;
            break;
            
        case PAR_XAUUSD:
            NombrePar = "XAUUSD (ORO)";
            ProfitMinimo = 1.5;
            ProfitTotal = 8.0;
            StopLossPips = ORO_StopLoss;              // 80 pips (antes 50)
            MomentumMinimoPips = 5.0;
            DistanciaMinimaPips = 20;
            MultiplicadorLote = ORO_MultiplicadorLote; // 1.8 (antes 1.4)
            PerdidaParaContra = -1.5;
            GananciaParaRefuerzo = 1.5;
            BEActivacionProfit = ORO_BEActivacion;     // $0.50 (antes $1.00)
            BEPips = 1;
            TrailingStartProfit = ORO_TrailingStart;   // $0.80 (antes $1.50)
            TrailingStepPips = 2.0;
            TiempoMinimoSegundos = 15;
            break;
            
        default:
            NombrePar = "CUSTOM";
            ProfitMinimo = 1.5;
            ProfitTotal = 8.0;
            StopLossPips = 50;
            MomentumMinimoPips = 5.0;
            DistanciaMinimaPips = 20;
            MultiplicadorLote = 1.4;
            PerdidaParaContra = -2.5;
            GananciaParaRefuerzo = 1.5;
            BEActivacionProfit = 1.0;
            BEPips = 1;
            TrailingStartProfit = 2.5;
            TrailingStepPips = 2.0;
            TiempoMinimoSegundos = 15;
            break;
    }
}

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
void OnTick()
{
    if(!BotActivo) return;
    
    // Verificar si está en pausa
    if(tiempoPausa > 0 && TimeCurrent() < tiempoPausa)
    {
        int segundosRestantes = (int)(tiempoPausa - TimeCurrent());
        ObjectSetString(0, "LabelEstado", OBJPROP_TEXT, "PAUSA: " + IntegerToString(segundosRestantes) + "s");
        ObjectSetInteger(0, "LabelEstado", OBJPROP_COLOR, clrOrange);
        return;
    }
    else if(tiempoPausa > 0 && TimeCurrent() >= tiempoPausa)
    {
        tiempoPausa = 0;
        SLconsecutivos = 0;
        Print("✅ Pausa terminada, reiniciando");
    }
    
    ResetearPerdidaDiaria();
    ActualizarPosiciones();
    VerificarBreakEven();
    
    // CONTROL ABSOLUTO DE OPERACIONES
    totalOperaciones = ContarPosicionesAbiertas();
    
    // Si excede máximo, SOLO gestionar
    if(totalOperaciones >= MaxOperaciones)
    {
        if(!alertaMaximaEmitida)
        {
            Print("🔒 LÍMITE ALCANZADO: ", totalOperaciones, "/", MaxOperaciones);
            alertaMaximaEmitida = true;
        }
        
        GestionarBreakEvenRapido();
        GestionarTrailingStop();
        CerrarPosicionesRapidas();
        CerrarPerdedorasConContraGanadora();
        
        profitTotal = CalcularProfitTotal();
        ActualizarInterfaz();
        
        if(profitTotal >= ProfitTotal)
        {
            CerrarTodasLasPosiciones();
            Print("🎯 OBJETIVO: $", DoubleToString(profitTotal, 2));
        }
        
        return;
    }
    
    alertaMaximaEmitida = false;
    
    // Gestión normal
    GestionarBreakEvenRapido();
    GestionarTrailingStop();
    CerrarPosicionesRapidas();
    CerrarPerdedorasConContraGanadora();
    
    profitTotal = CalcularProfitTotal();
    ActualizarInterfaz();
    
    // Stop por pérdida diaria
    if(perdidaDiaria <= -PerdidaMaximaDiaria)
    {
        CerrarTodasLasPosiciones();
        BotActivo = false;
        ObjectSetString(0, "LabelEstado", OBJPROP_TEXT, "STOP: -$" + DoubleToString(MathAbs(perdidaDiaria), 0));
        ObjectSetInteger(0, "LabelEstado", OBJPROP_COLOR, clrRed);
        Print("🛑 STOP DIARIO: -$", MathAbs(perdidaDiaria));
        return;
    }
    
    // Objetivo alcanzado
    if(profitTotal >= ProfitTotal)
    {
        CerrarTodasLasPosiciones();
        Print("🎯 OBJETIVO: $", DoubleToString(profitTotal, 2));
        return;
    }
    
    // Nueva barra
    datetime tiempoActual = iTime(_Symbol, PERIOD_M1, 0);
    bool nuevaBarra = (tiempoActual != ultimaBarra);
    if(nuevaBarra) ultimaBarra = tiempoActual;
    
    // LÓGICA DE ENTRADA CON CONTROL ULTRA ESTRICTO
    if(totalOperaciones < MaxOperaciones)
    {
        if(totalOperaciones == 0 && nuevaBarra)
        {
            EvaluarPrimeraEntrada();
        }
        else if(totalOperaciones == 1)
        {
            GestionarSegundaOperacion();
        }
        else if(totalOperaciones == 2)
        {
            GestionarTerceraOperacion();
        }
    }
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
void ActualizarInterfaz()
{
    string infoText = StringFormat("Ops: %d/%d | P&L: $%.2f%s", 
        totalOperaciones,
        MaxOperaciones,
        profitTotal,
        hayOperacionEnBE ? " | BE✓" : "");
    ObjectSetString(0, "LabelInfo", OBJPROP_TEXT, infoText);
    ObjectSetInteger(0, "LabelInfo", OBJPROP_COLOR, profitTotal > 0 ? clrLime : (profitTotal < 0 ? clrRed : clrWhite));
    
    string perdidaText = StringFormat("Día: $%.2f | SL: %d", perdidaDiaria, SLconsecutivos);
    ObjectSetString(0, "LabelPerdida", OBJPROP_TEXT, perdidaText);
    ObjectSetInteger(0, "LabelPerdida", OBJPROP_COLOR, SLconsecutivos >= 2 ? clrRed : clrYellow);
}

//+------------------------------------------------------------------+
void VerificarBreakEven()
{
    hayOperacionEnBE = false;
    
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        if(!PositionSelectByTicket(posiciones[i].ticket)) continue;
        
        double sl = PositionGetDouble(POSITION_SL);
        double precioApertura = posiciones[i].precioApertura;
        
        if(posiciones[i].tipo == ORDER_TYPE_BUY)
        {
            if(sl >= precioApertura)
            {
                posiciones[i].enBreakEven = true;
                hayOperacionEnBE = true;
            }
        }
        else
        {
            if(sl <= precioApertura && sl > 0)
            {
                posiciones[i].enBreakEven = true;
                hayOperacionEnBE = true;
            }
        }
    }
}

//+------------------------------------------------------------------+
void ResetearPerdidaDiaria()
{
    datetime ahora = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(ahora, dt);
    
    if(dt.hour == 0 && dt.min == 0 && ahora - ultimaResetPerdida > 3600)
    {
        perdidaDiaria = 0;
        SLconsecutivos = 0;
        ultimaResetPerdida = ahora;
        Print("📅 Nuevo día - Reset completo");
    }
}

//+------------------------------------------------------------------+
void EvaluarPrimeraEntrada()
{
    double close[];
    ArraySetAsSeries(close, true);
    if(CopyClose(_Symbol, PERIOD_M1, 0, 5, close) <= 0) return;
    
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    double momentum = close[0] - close[3];
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    double momentumPips = momentum / (point * 10);
    
    if(momentumPips >= MomentumMinimoPips)
    {
        Print("🔵 OP #1 COMPRA | Mom: +", DoubleToString(momentumPips, 1), "p");
        AbrirPosicion(ORDER_TYPE_BUY, LoteInicial, ask);
    }
    else if(momentumPips <= -MomentumMinimoPips)
    {
        Print("🔴 OP #1 VENTA | Mom: ", DoubleToString(momentumPips, 1), "p");
        AbrirPosicion(ORDER_TYPE_SELL, LoteInicial, bid);
    }
}

//+------------------------------------------------------------------+
void GestionarSegundaOperacion()
{
    // Verificar límite
    if(totalOperaciones >= MaxOperaciones)
    {
        Print("⚠️ Op#2 bloqueada: límite");
        return;
    }
    
    datetime ahora = TimeCurrent();
    if(ahora - ultimoRefuerzo < 20) return;
    
    if(ArraySize(posiciones) == 0) return;
    
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    double profit1 = posiciones[0].profit;
    int tipo1 = posiciones[0].tipo;
    double precio1 = posiciones[0].precioApertura;
    
    double siguienteLote = CalcularSiguienteLote();
    
    // REFORZAR
    if(profit1 >= GananciaParaRefuerzo)
    {
        double distancia;
        
        if(tipo1 == ORDER_TYPE_BUY)
        {
            distancia = (ask - precio1) / (point * 10);
            if(distancia >= DistanciaMinimaPips)
            {
                Print("💪 OP #2 REFUERZO COMPRA | $", DoubleToString(profit1, 2));
                AbrirPosicion(ORDER_TYPE_BUY, siguienteLote, ask);
                ultimoRefuerzo = ahora;
                return;
            }
        }
        else
        {
            distancia = (precio1 - bid) / (point * 10);
            if(distancia >= DistanciaMinimaPips)
            {
                Print("💪 OP #2 REFUERZO VENTA | $", DoubleToString(profit1, 2));
                AbrirPosicion(ORDER_TYPE_SELL, siguienteLote, bid);
                ultimoRefuerzo = ahora;
                return;
            }
        }
    }
    
    // CONTRAOPERACIÓN
    if(profit1 <= PerdidaParaContra)
    {
        if(tipo1 == ORDER_TYPE_BUY)
        {
            Print("🔄 OP #2 CONTRA VENTA | $", DoubleToString(profit1, 2));
            AbrirPosicion(ORDER_TYPE_SELL, siguienteLote, bid);
            ultimoRefuerzo = ahora;
        }
        else
        {
            Print("🔄 OP #2 CONTRA COMPRA | $", DoubleToString(profit1, 2));
            AbrirPosicion(ORDER_TYPE_BUY, siguienteLote, ask);
            ultimoRefuerzo = ahora;
        }
    }
}

//+------------------------------------------------------------------+
void GestionarTerceraOperacion()
{
    if(totalOperaciones >= MaxOperaciones)
    {
        Print("⚠️ Op#3 bloqueada: límite");
        return;
    }
    
    datetime ahora = TimeCurrent();
    if(ahora - ultimoRefuerzo < 30) return;
    
    if(Operacion3SoloEnBE && !hayOperacionEnBE)
    {
        Print("⏸️ Op#3 esperando BE");
        return;
    }
    
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    double mejorProfitCompra = -9999, mejorProfitVenta = -9999;
    
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        if(posiciones[i].tipo == ORDER_TYPE_BUY)
        {
            if(posiciones[i].profit > mejorProfitCompra) mejorProfitCompra = posiciones[i].profit;
        }
        else
        {
            if(posiciones[i].profit > mejorProfitVenta) mejorProfitVenta = posiciones[i].profit;
        }
    }
    
    double siguienteLote = CalcularSiguienteLote();
    
    if(mejorProfitCompra > 0.8 && mejorProfitCompra > mejorProfitVenta)
    {
        Print("🎯 OP #3 FINAL COMPRA");
        AbrirPosicion(ORDER_TYPE_BUY, siguienteLote, ask);
        ultimoRefuerzo = ahora;
    }
    else if(mejorProfitVenta > 0.8 && mejorProfitVenta > mejorProfitCompra)
    {
        Print("🎯 OP #3 FINAL VENTA");
        AbrirPosicion(ORDER_TYPE_SELL, siguienteLote, bid);
        ultimoRefuerzo = ahora;
    }
}

//+------------------------------------------------------------------+
void AbrirPosicion(ENUM_ORDER_TYPE tipo, double lote, double precio)
{
    // VERIFICACIÓN TRIPLE antes de abrir
    int opsActuales = ContarPosicionesAbiertas();
    if(opsActuales >= MaxOperaciones)
    {
        Print("❌ BLOQUEADO: ", opsActuales, "/", MaxOperaciones);
        return;
    }
    
    // Verificar cooldown
    datetime ahora = TimeCurrent();
    if(ahora - ultimaApertura < CooldownSegundos)
    {
        int espera = (int)(CooldownSegundos - (ahora - ultimaApertura));
        Print("⏸️ Cooldown: ", espera, "s restantes");
        return;
    }
    
    // Verificar que no haya demasiadas del mismo tipo
    int numBuys = 0, numSells = 0;
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        if(posiciones[i].tipo == ORDER_TYPE_BUY) numBuys++;
        else numSells++;
    }
    
    if(tipo == ORDER_TYPE_BUY && numBuys >= 2)
    {
        Print("❌ Ya hay 2 BUYs, no abrir más");
        return;
    }
    if(tipo == ORDER_TYPE_SELL && numSells >= 2)
    {
        Print("❌ Ya hay 2 SELLs, no abrir más");
        return;
    }
    
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    
    double sl = 0;
    
    if(tipo == ORDER_TYPE_BUY)
    {
        sl = NormalizeDouble(precio - StopLossPips * point * 10, digits);
        if(trade.Buy(lote, _Symbol, precio, sl, 0, "MSC_v4.3"))
        {
            contadorOperaciones++;
            ultimaApertura = TimeCurrent();
            Print("✅ BUY #", contadorOperaciones, " | Lote:", lote, " | SL:", StopLossPips, "p");
        }
        else
        {
            Print("❌ Error BUY: ", trade.ResultRetcodeDescription());
        }
    }
    else
    {
        sl = NormalizeDouble(precio + StopLossPips * point * 10, digits);
        if(trade.Sell(lote, _Symbol, precio, sl, 0, "MSC_v4.3"))
        {
            contadorOperaciones++;
            ultimaApertura = TimeCurrent();
            Print("✅ SELL #", contadorOperaciones, " | Lote:", lote, " | SL:", StopLossPips, "p");
        }
        else
        {
            Print("❌ Error SELL: ", trade.ResultRetcodeDescription());
        }
    }
}

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
                SLconsecutivos = 0;  // Reset al cerrar con profit
                Print("⚡ CERRADO: $", DoubleToString(profitCierre, 2));
            }
        }
        else if(posiciones[i].profit >= 4.0)
        {
            double profitCierre = posiciones[i].profit;
            if(trade.PositionClose(posiciones[i].ticket))
            {
                perdidaDiaria += profitCierre;
                SLconsecutivos = 0;
                Print("⚡ CERRADO RÁPIDO: $", DoubleToString(profitCierre, 2));
            }
        }
    }
}

//+------------------------------------------------------------------+
// NUEVO: Cerrar pares ganadora+perdedora
//+------------------------------------------------------------------+
void CerrarPerdedorasConContraGanadora()
{
    if(ArraySize(posiciones) < 2) return;
    
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        if(posiciones[i].profit >= 2.0)
        {
            for(int j = 0; j < ArraySize(posiciones); j++)
            {
                if(i == j) continue;
                
                if(posiciones[j].tipo != posiciones[i].tipo && posiciones[j].profit < -1.0)
                {
                    double profitNeto = posiciones[i].profit + posiciones[j].profit;
                    
                    if(profitNeto >= 0.50)
                    {
                        Print("💰 Cerrando par: $", DoubleToString(posiciones[i].profit, 2), 
                              " + $", DoubleToString(posiciones[j].profit, 2), 
                              " = $", DoubleToString(profitNeto, 2));
                        
                        double profit1 = posiciones[i].profit;
                        double profit2 = posiciones[j].profit;
                        
                        if(trade.PositionClose(posiciones[i].ticket))
                        {
                            perdidaDiaria += profit1;
                            SLconsecutivos = 0;
                        }
                        
                        if(trade.PositionClose(posiciones[j].ticket))
                        {
                            perdidaDiaria += profit2;
                        }
                        
                        return;
                    }
                }
            }
        }
    }
}

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
void ActualizarPosiciones()
{
    int opsAntes = ArraySize(posiciones);
    ArrayResize(posiciones, 0);
    
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0)
        {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
               PositionGetInteger(POSITION_MAGIC) == 901234)
            {
                int idx = ArraySize(posiciones);
                ArrayResize(posiciones, idx + 1);
                
                posiciones[idx].ticket = ticket;
                posiciones[idx].lote = PositionGetDouble(POSITION_VOLUME);
                posiciones[idx].precioApertura = PositionGetDouble(POSITION_PRICE_OPEN);
                posiciones[idx].tipo = (int)PositionGetInteger(POSITION_TYPE);
                posiciones[idx].profit = PositionGetDouble(POSITION_PROFIT);
                posiciones[idx].tiempoApertura = (datetime)PositionGetInteger(POSITION_TIME);
                posiciones[idx].enBreakEven = false;
            }
        }
    }
    
    // Detectar si tocó SL (operación cerrada)
    int opsDespues = ArraySize(posiciones);
    if(opsDespues < opsAntes)
    {
        // Se cerró una operación
        double ultimoCierre = 0;
        
        // Buscar en el historial la última operación cerrada
        if(HistorySelect(TimeCurrent() - 60, TimeCurrent()))
        {
            int totalDeals = HistoryDealsTotal();
            if(totalDeals > 0)
            {
                ulong dealTicket = HistoryDealGetTicket(totalDeals - 1);
                if(dealTicket > 0)
                {
                    ultimoCierre = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
                    
                    // Si es pérdida significativa, probablemente fue SL
                    if(ultimoCierre < -2.0)
                    {
                        SLconsecutivos++;
                        Print("⚠️ SL detectado #", SLconsecutivos, " | Pérdida: $", DoubleToString(ultimoCierre, 2));
                        
                        if(SLconsecutivos >= MaxSLConsecutivos)
                        {
                            tiempoPausa = TimeCurrent() + 300; // 5 minutos
                            Print("🛑 PAUSA AUTOMÁTICA: ", MaxSLConsecutivos, " SL consecutivos");
                            
                            if(!AlertaSilenciosa)
                            {
                                Alert("🛑 BOT EN PAUSA: ", MaxSLConsecutivos, " SL seguidos");
                            }
                        }
                    }
                }
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
void GestionarBreakEvenRapido()
{
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
                    if(trade.PositionModify(posiciones[i].ticket, BE, 0))
                    {
                        Print("🛡️ BE activado COMPRA | Profit: $", DoubleToString(posiciones[i].profit, 2));
                    }
                }
            }
            else
            {
                BE = NormalizeDouble(posiciones[i].precioApertura - BEPips * point * 10, digits);
                if(sl > posiciones[i].precioApertura || sl == 0)
                {
                    if(trade.PositionModify(posiciones[i].ticket, BE, 0))
                    {
                        Print("🛡️ BE activado VENTA | Profit: $", DoubleToString(posiciones[i].profit, 2));
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
void GestionarTrailingStop()
{
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
            if(nuevoSL > sl)
            {
                if(trade.PositionModify(posiciones[i].ticket, nuevoSL, 0))
                {
                    Print("📊 Trailing BUY actualizado | Profit: $", DoubleToString(posiciones[i].profit, 2));
                }
            }
        }
        else
        {
            precioActual = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double nuevoSL = NormalizeDouble(precioActual + TrailingStepPips * point * 10, digits);
            if(nuevoSL < sl || sl == 0)
            {
                if(trade.PositionModify(posiciones[i].ticket, nuevoSL, 0))
                {
                    Print("📊 Trailing SELL actualizado | Profit: $", DoubleToString(posiciones[i].profit, 2));
                }
            }
        }
    }
}

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
    ObjectSetString(0, "LabelEstado", OBJPROP_TEXT, "v4.3: OFF");
    ObjectSetInteger(0, "LabelEstado", OBJPROP_FONTSIZE, 9);
    ObjectSetString(0, "LabelEstado", OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, "LabelEstado", OBJPROP_BACK, false);
    
    ObjectCreate(0, "LabelInfo", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "LabelInfo", OBJPROP_XDISTANCE, x - 20);
    ObjectSetInteger(0, "LabelInfo", OBJPROP_YDISTANCE, y + (alto + 10) * 2 + 24);
    ObjectSetInteger(0, "LabelInfo", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "LabelInfo", OBJPROP_COLOR, clrWhite);
    ObjectSetString(0, "LabelInfo", OBJPROP_TEXT, "Ops: 0/3 | P&L: $0.00");
    ObjectSetInteger(0, "LabelInfo", OBJPROP_FONTSIZE, 8);
    ObjectSetInteger(0, "LabelInfo", OBJPROP_BACK, false);
    
    ObjectCreate(0, "LabelPerdida", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "LabelPerdida", OBJPROP_XDISTANCE, x - 20);
    ObjectSetInteger(0, "LabelPerdida", OBJPROP_YDISTANCE, y + (alto + 10) * 2 + 41);
    ObjectSetInteger(0, "LabelPerdida", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "LabelPerdida", OBJPROP_COLOR, clrYellow);
    ObjectSetString(0, "LabelPerdida", OBJPROP_TEXT, "Día: $0.00 | SL: 0");
    ObjectSetInteger(0, "LabelPerdida", OBJPROP_FONTSIZE, 7);
    ObjectSetInteger(0, "LabelPerdida", OBJPROP_BACK, false);
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    if(id == CHARTEVENT_OBJECT_CLICK)
    {
        if(sparam == "BtnActivar")
        {
            BotActivo = true;
            tiempoPausa = 0;
            SLconsecutivos = 0;
            ObjectSetString(0, "LabelEstado", OBJPROP_TEXT, NombrePar + ": ON");
            ObjectSetInteger(0, "LabelEstado", OBJPROP_COLOR, clrLime);
            Print("🚀 v4.3 ORO ACTIVADO");
            ObjectSetInteger(0, "BtnActivar", OBJPROP_STATE, false);
        }
        else if(sparam == "BtnDesactivar")
        {
            BotActivo = false;
            ObjectSetString(0, "LabelEstado", OBJPROP_TEXT, "v4.3: OFF");
            ObjectSetInteger(0, "LabelEstado", OBJPROP_COLOR, clrRed);
            Print("⏸️ DESACTIVADO");
            ObjectSetInteger(0, "BtnDesactivar", OBJPROP_STATE, false);
        }
        ChartRedraw();
    }
}
//+------------------------------------------------------------------+
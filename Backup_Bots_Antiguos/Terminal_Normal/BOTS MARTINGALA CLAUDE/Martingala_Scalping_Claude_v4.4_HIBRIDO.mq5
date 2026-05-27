//+------------------------------------------------------------------+
//|                    Martingala_Scalping_Claude_v4.4_HIBRIDO.mq5   |
//|          AGRESIVO EN GANANCIAS - DEFENSIVO EN PÉRDIDAS           |
//+------------------------------------------------------------------+
#property copyright "Martingala Scalping Claude v4.4 HÍBRIDO"
#property version   "4.40"
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

input group "=== CONFIGURACIÓN HÍBRIDA ==="
input double   LoteInicial = 0.01;
input int      MaxOperaciones = 4;              // Aumentado a 4 (antes 3)
input double   PerdidaMaximaDiaria = 60.0;      // Más margen
input double   ProfitTotalObjetivo = 10.0;      // Aumentado a $10 (antes $8)

input group "=== ESTRATEGIA AGRESIVA/DEFENSIVA ==="
input double   ProfitMinimo_Ganadora = 3.0;     // NO cerrar antes de $3 (antes $1.50)
input double   Perdida_ContraRapida = -1.0;     // Contraoperar a -$1 (antes -$1.50)
input double   Ganancia_Reforzar = 2.0;         // Reforzar cada $2 (antes $1.50)
input bool     CerrarPerdedoraSiCompensa = true; // Cerrar perdedora si contraoperación compensa

input group "=== AJUSTES ORO (XAUUSD) ==="
input double   ORO_StopLoss = 80.0;
input double   ORO_BEActivacion = 0.50;
input double   ORO_TrailingStart = 1.50;        // Trailing desde $1.50
input double   ORO_MultiplicadorLote = 2.0;     // Más agresivo (antes 1.8)

input group "=== CONTROL ==="
input bool     AlertaSilenciosa = true;
input int      CooldownSegundos = 25;           // Reducido a 25s (antes 30)
input int      MaxSLConsecutivos = 3;

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
datetime ultimaApertura = 0;
double perdidaDiaria = 0;
datetime ultimaResetPerdida = 0;
bool hayOperacionEnBE = false;
int SLconsecutivos = 0;
datetime tiempoPausa = 0;

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
    
    // Aplicar configuración híbrida
    ProfitMinimo = ProfitMinimo_Ganadora;
    ProfitTotal = ProfitTotalObjetivo;
    PerdidaParaContra = Perdida_ContraRapida;
    GananciaParaRefuerzo = Ganancia_Reforzar;
    
    trade.SetExpertMagicNumber(912345);
    trade.SetDeviationInPoints(10);
    trade.SetTypeFilling(ORDER_FILLING_FOK);
    
    CrearBotones();
    
    Print("═══════════════════════════════════════");
    Print("  MSC v4.4 HÍBRIDO");
    Print("  Agresivo en Ganancias | Defensivo en Pérdidas");
    Print("  Par: ", NombrePar);
    Print("  Cierre ganadora: $", ProfitMinimo);
    Print("  Contraoperación: $", PerdidaParaContra);
    Print("  Refuerzo: $", GananciaParaRefuerzo);
    Print("  Max Ops: ", MaxOperaciones);
    Print("  Objetivo: $", ProfitTotal);
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
            StopLossPips = 40;
            MomentumMinimoPips = 2.0;
            DistanciaMinimaPips = 12;
            MultiplicadorLote = 2.0;
            BEActivacionProfit = 0.60;
            BEPips = 1;
            TrailingStartProfit = 1.5;
            TrailingStepPips = 1.5;
            TiempoMinimoSegundos = 20;
            break;
            
        case PAR_XAUUSD:
            NombrePar = "XAUUSD (ORO)";
            StopLossPips = ORO_StopLoss;
            MomentumMinimoPips = 5.0;
            DistanciaMinimaPips = 20;
            MultiplicadorLote = ORO_MultiplicadorLote;
            BEActivacionProfit = ORO_BEActivacion;
            BEPips = 1;
            TrailingStartProfit = ORO_TrailingStart;
            TrailingStepPips = 2.5;
            TiempoMinimoSegundos = 15;
            break;
            
        default:
            NombrePar = "CUSTOM";
            StopLossPips = 60;
            MomentumMinimoPips = 5.0;
            DistanciaMinimaPips = 20;
            MultiplicadorLote = 2.0;
            BEActivacionProfit = 1.0;
            BEPips = 1;
            TrailingStartProfit = 2.0;
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
    
    // Verificar pausa
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
        Print("✅ Pausa terminada");
    }
    
    ResetearPerdidaDiaria();
    ActualizarPosiciones();
    VerificarBreakEven();
    
    totalOperaciones = ContarPosicionesAbiertas();
    
    // Gestión continua
    GestionarBreakEvenRapido();
    GestionarTrailingStop();
    CerrarGanadorasConProfit();      // NUEVO: Cerrar solo si superan $3
    CerrarPerdedorasSiCompensadas(); // NUEVO: Cerrar perdedoras si contraoperación compensa
    
    profitTotal = CalcularProfitTotal();
    ActualizarInterfaz();
    
    // Control de límite
    if(totalOperaciones >= MaxOperaciones)
    {
        if(!alertaMaximaEmitida)
        {
            Print("🔒 LÍMITE: ", totalOperaciones, "/", MaxOperaciones);
            alertaMaximaEmitida = true;
        }
        
        if(profitTotal >= ProfitTotal)
        {
            CerrarTodasLasPosiciones();
            Print("🎯 OBJETIVO HÍBRIDO: $", DoubleToString(profitTotal, 2));
        }
        
        return;
    }
    
    alertaMaximaEmitida = false;
    
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
        Print("🎯 OBJETIVO HÍBRIDO: $", DoubleToString(profitTotal, 2));
        return;
    }
    
    // Nueva barra
    datetime tiempoActual = iTime(_Symbol, PERIOD_M1, 0);
    bool nuevaBarra = (tiempoActual != ultimaBarra);
    if(nuevaBarra) ultimaBarra = tiempoActual;
    
    // LÓGICA HÍBRIDA DE ENTRADA
    if(totalOperaciones < MaxOperaciones)
    {
        if(totalOperaciones == 0 && nuevaBarra)
        {
            EvaluarPrimeraEntrada();
        }
        else if(totalOperaciones >= 1)
        {
            GestionarOperacionesHibridas(); // NUEVO: Lógica híbrida
        }
    }
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
// NUEVO: Lógica híbrida de gestión
//+------------------------------------------------------------------+
void GestionarOperacionesHibridas()
{
    datetime ahora = TimeCurrent();
    if(ahora - ultimoRefuerzo < 15) return; // Más rápido que antes (era 20-30s)
    
    if(ArraySize(posiciones) == 0) return;
    
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // Analizar situación
    double mejorProfitCompra = -9999, peorProfitCompra = 9999;
    double mejorProfitVenta = -9999, peorProfitVenta = 9999;
    int numCompras = 0, numVentas = 0;
    
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        if(posiciones[i].tipo == ORDER_TYPE_BUY)
        {
            numCompras++;
            if(posiciones[i].profit > mejorProfitCompra) mejorProfitCompra = posiciones[i].profit;
            if(posiciones[i].profit < peorProfitCompra) peorProfitCompra = posiciones[i].profit;
        }
        else
        {
            numVentas++;
            if(posiciones[i].profit > mejorProfitVenta) mejorProfitVenta = posiciones[i].profit;
            if(posiciones[i].profit < peorProfitVenta) peorProfitVenta = posiciones[i].profit;
        }
    }
    
    double siguienteLote = CalcularSiguienteLote();
    
    // PRIORIDAD 1: CONTRAOPERACIÓN RÁPIDA si hay pérdida >= -$1.00
    if(peorProfitCompra <= PerdidaParaContra && numVentas == 0)
    {
        Print("🔄 CONTRA INMEDIATA: VENTA | Pérdida compra: $", DoubleToString(peorProfitCompra, 2));
        AbrirPosicion(ORDER_TYPE_SELL, siguienteLote, bid);
        ultimoRefuerzo = ahora;
        return;
    }
    
    if(peorProfitVenta <= PerdidaParaContra && numCompras == 0)
    {
        Print("🔄 CONTRA INMEDIATA: COMPRA | Pérdida venta: $", DoubleToString(peorProfitVenta, 2));
        AbrirPosicion(ORDER_TYPE_BUY, siguienteLote, ask);
        ultimoRefuerzo = ahora;
        return;
    }
    
    // PRIORIDAD 2: REFORZAR GANADORAS cada $2
    if(mejorProfitCompra >= GananciaParaRefuerzo && numCompras < 2)
    {
        Print("💪 REFUERZO COMPRA | Profit: $", DoubleToString(mejorProfitCompra, 2));
        AbrirPosicion(ORDER_TYPE_BUY, siguienteLote, ask);
        ultimoRefuerzo = ahora;
        return;
    }
    
    if(mejorProfitVenta >= GananciaParaRefuerzo && numVentas < 2)
    {
        Print("💪 REFUERZO VENTA | Profit: $", DoubleToString(mejorProfitVenta, 2));
        AbrirPosicion(ORDER_TYPE_SELL, siguienteLote, bid);
        ultimoRefuerzo = ahora;
        return;
    }
    
    // PRIORIDAD 3: Si hay ambas direcciones, reforzar la mejor
    if(numCompras > 0 && numVentas > 0)
    {
        if(mejorProfitCompra > mejorProfitVenta && mejorProfitCompra > 1.0 && numCompras < 2)
        {
            Print("📈 Reforzando mejor dirección: COMPRA");
            AbrirPosicion(ORDER_TYPE_BUY, siguienteLote, ask);
            ultimoRefuerzo = ahora;
        }
        else if(mejorProfitVenta > mejorProfitCompra && mejorProfitVenta > 1.0 && numVentas < 2)
        {
            Print("📉 Reforzando mejor dirección: VENTA");
            AbrirPosicion(ORDER_TYPE_SELL, siguienteLote, bid);
            ultimoRefuerzo = ahora;
        }
    }
}

//+------------------------------------------------------------------+
// NUEVO: Cerrar solo ganadoras que superen $3
//+------------------------------------------------------------------+
void CerrarGanadorasConProfit()
{
    datetime ahora = TimeCurrent();
    
    for(int i = ArraySize(posiciones) - 1; i >= 0; i--)
    {
        int segundos = (int)(ahora - posiciones[i].tiempoApertura);
        
        // Solo cerrar si supera profit mínimo ($3) Y tiempo mínimo
        if(segundos >= TiempoMinimoSegundos && posiciones[i].profit >= ProfitMinimo)
        {
            double profitCierre = posiciones[i].profit;
            if(trade.PositionClose(posiciones[i].ticket))
            {
                perdidaDiaria += profitCierre;
                SLconsecutivos = 0;
                Print("💰 GANADORA CERRADA: $", DoubleToString(profitCierre, 2), " en ", segundos, "s");
            }
        }
        // Cerrar inmediatamente si supera $6
        else if(posiciones[i].profit >= 6.0)
        {
            double profitCierre = posiciones[i].profit;
            if(trade.PositionClose(posiciones[i].ticket))
            {
                perdidaDiaria += profitCierre;
                SLconsecutivos = 0;
                Print("💰💰 GRAN GANANCIA: $", DoubleToString(profitCierre, 2));
            }
        }
    }
}

//+------------------------------------------------------------------+
// NUEVO: Cerrar perdedoras SI contraoperación compensa
//+------------------------------------------------------------------+
void CerrarPerdedorasSiCompensadas()
{
    if(!CerrarPerdedoraSiCompensa) return;
    if(ArraySize(posiciones) < 2) return;
    
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        // Si esta va bien ($2+)
        if(posiciones[i].profit >= 2.0)
        {
            // Buscar su opuesta perdedora
            for(int j = 0; j < ArraySize(posiciones); j++)
            {
                if(i == j) continue;
                
                // Si es opuesta y pierde
                if(posiciones[j].tipo != posiciones[i].tipo && posiciones[j].profit < 0)
                {
                    double profitNeto = posiciones[i].profit + posiciones[j].profit;
                    
                    // Si el neto es positivo (mínimo $0.80)
                    if(profitNeto >= 0.80)
                    {
                        Print("🔄 PAR COMPENSADO: $", DoubleToString(posiciones[i].profit, 2), 
                              " + $", DoubleToString(posiciones[j].profit, 2), 
                              " = $", DoubleToString(profitNeto, 2));
                        
                        double profit1 = posiciones[i].profit;
                        double profit2 = posiciones[j].profit;
                        
                        // Cerrar ganadora
                        if(trade.PositionClose(posiciones[i].ticket))
                        {
                            perdidaDiaria += profit1;
                            SLconsecutivos = 0;
                        }
                        
                        // Cerrar perdedora
                        if(trade.PositionClose(posiciones[j].ticket))
                        {
                            perdidaDiaria += profit2;
                        }
                        
                        Print("✅ Neto del par: $", DoubleToString(profitNeto, 2));
                        return;
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
void ActualizarInterfaz()
{
    // Contar tipos
    int numBuys = 0, numSells = 0;
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        if(posiciones[i].tipo == ORDER_TYPE_BUY) numBuys++;
        else numSells++;
    }
    
    string infoText = StringFormat("Ops: %d/%d (B:%d S:%d) | $%.2f%s", 
        totalOperaciones,
        MaxOperaciones,
        numBuys,
        numSells,
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
        Print("📅 Nuevo día HÍBRIDO");
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
        Print("🔵 HÍBRIDO OP #1 COMPRA | Mom: +", DoubleToString(momentumPips, 1), "p");
        AbrirPosicion(ORDER_TYPE_BUY, LoteInicial, ask);
    }
    else if(momentumPips <= -MomentumMinimoPips)
    {
        Print("🔴 HÍBRIDO OP #1 VENTA | Mom: ", DoubleToString(momentumPips, 1), "p");
        AbrirPosicion(ORDER_TYPE_SELL, LoteInicial, bid);
    }
}

//+------------------------------------------------------------------+
void AbrirPosicion(ENUM_ORDER_TYPE tipo, double lote, double precio)
{
    // Verificación triple
    int opsActuales = ContarPosicionesAbiertas();
    if(opsActuales >= MaxOperaciones)
    {
        Print("❌ BLOQUEADO: ", opsActuales, "/", MaxOperaciones);
        return;
    }
    
    // Cooldown
    datetime ahora = TimeCurrent();
    if(ahora - ultimaApertura < CooldownSegundos)
    {
        return;
    }
    
    // Máximo 2 por tipo
    int numBuys = 0, numSells = 0;
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        if(posiciones[i].tipo == ORDER_TYPE_BUY) numBuys++;
        else numSells++;
    }
    
    if(tipo == ORDER_TYPE_BUY && numBuys >= 2)
    {
        Print("❌ Ya hay 2 BUYs");
        return;
    }
    if(tipo == ORDER_TYPE_SELL && numSells >= 2)
    {
        Print("❌ Ya hay 2 SELLs");
        return;
    }
    
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    
    double sl = 0;
    
    if(tipo == ORDER_TYPE_BUY)
    {
        sl = NormalizeDouble(precio - StopLossPips * point * 10, digits);
        if(trade.Buy(lote, _Symbol, precio, sl, 0, "MSC_HIB"))
        {
            contadorOperaciones++;
            ultimaApertura = TimeCurrent();
            Print("✅ BUY #", contadorOperaciones, " | Lote:", lote);
        }
    }
    else
    {
        sl = NormalizeDouble(precio + StopLossPips * point * 10, digits);
        if(trade.Sell(lote, _Symbol, precio, sl, 0, "MSC_HIB"))
        {
            contadorOperaciones++;
            ultimaApertura = TimeCurrent();
            Print("✅ SELL #", contadorOperaciones, " | Lote:", lote);
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
               PositionGetInteger(POSITION_MAGIC) == 912345)
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
    
    // Detectar SL
    int opsDespues = ArraySize(posiciones);
    if(opsDespues < opsAntes)
    {
        if(HistorySelect(TimeCurrent() - 60, TimeCurrent()))
        {
            int totalDeals = HistoryDealsTotal();
            if(totalDeals > 0)
            {
                ulong dealTicket = HistoryDealGetTicket(totalDeals - 1);
                if(dealTicket > 0)
                {
                    double ultimoCierre = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
                    
                    if(ultimoCierre < -2.0)
                    {
                        SLconsecutivos++;
                        Print("⚠️ SL #", SLconsecutivos, " | $", DoubleToString(ultimoCierre, 2));
                        
                        if(SLconsecutivos >= MaxSLConsecutivos)
                        {
                            tiempoPausa = TimeCurrent() + 300;
                            Print("🛑 PAUSA: ", MaxSLConsecutivos, " SL");
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
void GestionarTrailingStop()
{
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        // Activar trailing desde $1.50
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
                trade.PositionModify(posiciones[i].ticket, nuevoSL, 0);
            }
        }
        else
        {
            precioActual = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double nuevoSL = NormalizeDouble(precioActual + TrailingStepPips * point * 10, digits);
            if(nuevoSL < sl || sl == 0)
            {
                trade.PositionModify(posiciones[i].ticket, nuevoSL, 0);
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
    ObjectSetString(0, "LabelEstado", OBJPROP_TEXT, "HÍBRIDO: OFF");
    ObjectSetInteger(0, "LabelEstado", OBJPROP_FONTSIZE, 9);
    ObjectSetString(0, "LabelEstado", OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, "LabelEstado", OBJPROP_BACK, false);
    
    ObjectCreate(0, "LabelInfo", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "LabelInfo", OBJPROP_XDISTANCE, x - 20);
    ObjectSetInteger(0, "LabelInfo", OBJPROP_YDISTANCE, y + (alto + 10) * 2 + 24);
    ObjectSetInteger(0, "LabelInfo", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "LabelInfo", OBJPROP_COLOR, clrWhite);
    ObjectSetString(0, "LabelInfo", OBJPROP_TEXT, "Ops: 0/4 | $0.00");
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
            ObjectSetString(0, "LabelEstado", OBJPROP_TEXT, "HÍBRIDO: ON");
            ObjectSetInteger(0, "LabelEstado", OBJPROP_COLOR, clrLime);
            Print("🚀 v4.4 HÍBRIDO ACTIVADO");
            ObjectSetInteger(0, "BtnActivar", OBJPROP_STATE, false);
        }
        else if(sparam == "BtnDesactivar")
        {
            BotActivo = false;
            ObjectSetString(0, "LabelEstado", OBJPROP_TEXT, "HÍBRIDO: OFF");
            ObjectSetInteger(0, "LabelEstado", OBJPROP_COLOR, clrRed);
            Print("⏸️ HÍBRIDO DESACTIVADO");
            ObjectSetInteger(0, "BtnDesactivar", OBJPROP_STATE, false);
        }
        ChartRedraw();
    }
}
//+------------------------------------------------------------------+
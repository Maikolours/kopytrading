//+------------------------------------------------------------------+
//|              Martingala_Deepseek_Aggressive_v2.2.mq5            |
//|           VERSIÓN MEJORADA - CIERRE MANUAL + MÁS AGRESIVIDAD    |
//+------------------------------------------------------------------+
#property copyright "Martingala Deepseek Aggressive v2.2"
#property version   "2.20"
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

// ============ CONFIGURACIÓN COMPLETA DESDE INPUTS ============
input group "=== CONFIGURACIÓN BÁSICA ==="
input ENUM_PAR_TRADING ParTrading = PAR_XAUUSD;
input double   LoteInicial = 0.01;
input int      MaxOperacionesSimultaneas = 4;
input int      MaxOperacionesDiarias = 100;
input bool     BotActivoInicio = true;

input group "=== GESTIÓN DE RIESGO ==="
input double   StopLossPorOperacion = -15.0;      // Cierre perdedoras a -$X
input double   PerdidaMaximaDiaria = -100.0;      // Stop diario negativo
input double   TakeProfitDiario = 50.0;           // Objetivo diario positivo
input double   ProfitMinimoCierre = 6.0;          // Cerrar ganadoras desde $X
input double   GananciaRefuerzo = 2.0;            // Reforzar desde $X
input double   PerdidaContraoperar = -0.5;        // Contraoperar desde -$X (más sensible)

input group "=== CONFIGURACIÓN TÉCNICA ==="
input double   StopLossPips = 200.0;              // SL en pips (10 = 1 pip estándar)
input double   TakeProfitPips = 50.0;             // TP en pips (5 pips reales)
input bool     UsarBreakEven = true;
input double   BEActivacionProfit = 1.5;          // $ para activar BE
input double   BEPips = 20.0;                     // Pips para mover SL a BE (2 pips)
input bool     UsarTrailingStop = true;
input double   TrailingStartProfit = 2.0;         // $ para iniciar trailing
input double   TrailingStepPips = 20.0;           // Pips de paso trailing (2 pips)

input group "=== CONFIGURACIÓN OPERATIVA ==="
input double   MultiplicadorLoteMaximo = 2.0;     // Multiplicador máximo
input int      CooldownSegundos = 2;              // Espera entre operaciones (más rápido)
input bool     CerrarPerdedoraSiCompensa = true;
input double   UmbralRefuerzoAgresivo = 1.0;      // Refuerzo temprano desde $X (más agresivo)
input bool     SustitucionAutomatica = true;      // Abrir nueva operación al cerrar

input group "=== PAUSAS INTELIGENTES ==="
input bool     ActivarPausasInteligentes = true;
input int      PausaBaseSegundos = 300;           // 300s = 5 minutos base
input double   FactorAumentoPausa = 1.5;          // Aumento exponencial
input int      MaxSLConsecutivos = 3;             // SL consecutivos para pausa
input int      PausaPerdidaDiaria = 7200;         // Pausa 2h si pérdida diaria (seg)

input group "=== FILTROS DE MERCADO ==="
input bool     UsarFiltroVolumen = false;
input bool     EvitarHorasNoticias = false;       // Desactivado para testing
input int      HoraInicioTrading = 1;
input int      HoraFinTrading = 22;
input double   MomentumMinimoPips = 0.5;          // Momento mínimo entrada (más sensible)
input int      DistanciaMinimaPips = 10;          // Distancia entre operaciones

input group "=== CONFIGURACIÓN ESPECÍFICA ORO (XAUUSD) ==="
input double   ORO_StopLossPips = 200.0;
input double   ORO_BEActivacion = 1.5;
input double   ORO_TrailingStart = 2.0;
input double   ORO_MultiplicadorLote = 2.0;

input group "=== INTERFAZ ==="
input bool     MostrarBotones = true;
input color    ColorBotones = clrDodgerBlue;
input bool     AlertasActivas = true;
input bool     PermitirCierreManual = true;       // Permitir cerrar posiciones manualmente

// Variables globales
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
int operacionesHoy = 0;
datetime ultimaOperacionHoy = 0;
double gananciaAcumulada = 0;
double drawdownMaximo = 0;
double mejorGananciaDia = 0;

// Variables para seguimiento de cierres
datetime ultimoCierre = 0;
int operacionesCerradasBE = 0;
int operacionesCerradasTrailing = 0;

// Estructura para posiciones
struct PosicionInfo {
    ulong ticket;
    double lote;
    double precioApertura;
    int tipo;
    double profit;
    datetime tiempoApertura;
    bool enBreakEven;
    double maxProfitAlcanzado;
    bool cerradaPorBE;
    bool cerradaPorTrailing;
};

PosicionInfo posiciones[];

// Variables técnicas dinámicas
double MyStopLossPips;
double MyBEActivacion;
double MyTrailingStart;
double MyMultiplicadorLote;
string NombrePar;

//+------------------------------------------------------------------+
int OnInit()
{
    ConfigurarParametrosPorPar();
    
    BotActivo = BotActivoInicio;
    
    trade.SetExpertMagicNumber(999777);
    trade.SetDeviationInPoints(10);
    trade.SetTypeFilling(ORDER_FILLING_FOK);
    
    if(MostrarBotones)
        CrearInterfazCompleta();
    
    Print("═══════════════════════════════════════════════════");
    Print("        DEEPSEEK AGGRESSIVE v2.2");
    Print("         VERSIÓN MEJORADA - CIERRE MANUAL + MÁS AGRESIVO");
    Print("═══════════════════════════════════════════════════");
    Print("Par: ", NombrePar);
    Print("Lote inicial: ", LoteInicial);
    Print("Take Profit: ", TakeProfitPips/10, " pips reales ($", DoubleToString(TakeProfitPips/10,2), ")");
    Print("Stop Loss/Operación: $", StopLossPorOperacion);
    Print("BE activación: $", BEActivacionProfit);
    Print("Trailing start: $", TrailingStartProfit);
    Print("Contraoperar desde: $", PerdidaContraoperar);
    Print("Refuerzo desde: $", UmbralRefuerzoAgresivo);
    Print("═══════════════════════════════════════════════════");
    
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
        case PAR_XAUUSD:
            NombrePar = "XAUUSD (ORO)";
            MyStopLossPips = ORO_StopLossPips;
            MyBEActivacion = ORO_BEActivacion;
            MyTrailingStart = ORO_TrailingStart;
            MyMultiplicadorLote = ORO_MultiplicadorLote;
            break;
            
        default:
            NombrePar = symbol;
            MyStopLossPips = StopLossPips;
            MyBEActivacion = BEActivacionProfit;
            MyTrailingStart = TrailingStartProfit;
            MyMultiplicadorLote = MultiplicadorLoteMaximo;
            break;
    }
    
    // Asegurar que no exceda el máximo
    if(MyMultiplicadorLote > MultiplicadorLoteMaximo)
        MyMultiplicadorLote = MultiplicadorLoteMaximo;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    if(MostrarBotones)
    {
        ObjectDelete(0, "BtnActivarDS");
        ObjectDelete(0, "BtnDesactivarDS");
        ObjectDelete(0, "BtnCerrarTodoDS");
        ObjectDelete(0, "LabelEstadoDS");
        ObjectDelete(0, "LabelInfoDS");
        ObjectDelete(0, "LabelRiesgoDS");
        ObjectDelete(0, "LabelStatsDS");
        ObjectDelete(0, "LabelConfigDS");
        ChartRedraw();
    }
}

//+------------------------------------------------------------------+
void OnTick()
{
    if(!BotActivo) return;
    
    // Verificar hora segura
    if(!EsHoraSegura())
    {
        if(totalOperaciones > 0)
            CerrarTodasLasPosiciones();
        return;
    }
    
    // Verificar pausa
    if(tiempoPausa > 0 && TimeCurrent() < tiempoPausa)
    {
        int segundosRestantes = (int)(tiempoPausa - TimeCurrent());
        if(MostrarBotones)
        {
            ObjectSetString(0, "LabelEstadoDS", OBJPROP_TEXT, "PAUSA: " + IntegerToString(segundosRestantes) + "s");
            ObjectSetInteger(0, "LabelEstadoDS", OBJPROP_COLOR, clrOrange);
        }
        return;
    }
    else if(tiempoPausa > 0 && TimeCurrent() >= tiempoPausa)
    {
        tiempoPausa = 0;
        SLconsecutivos = 0;
        Print("✅ DEEPSEEK: Pausa terminada");
    }
    
    ResetearPerdidaDiaria();
    ActualizarPosiciones();
    VerificarBreakEven();
    
    totalOperaciones = ContarPosicionesAbiertas();
    
    // Gestión de posiciones
    if(UsarBreakEven)
        GestionarBreakEvenRapido();
    
    if(UsarTrailingStop)
        GestionarTrailingStopMejorado();
    
    GestionarStopLossMaximo();
    
    if(CerrarPerdedoraSiCompensa)
        CerrarPerdedorasSiCompensadas();
    
    profitTotal = CalcularProfitTotal();
    
    // Actualizar drawdown máximo
    if(profitTotal < drawdownMaximo)
        drawdownMaximo = profitTotal;
    
    // Actualizar mejor ganancia del día
    if(gananciaAcumulada > mejorGananciaDia)
        mejorGananciaDia = gananciaAcumulada;
    
    if(MostrarBotones)
        ActualizarInterfazCompleta();
    
    // Control de límite de operaciones
    if(totalOperaciones >= MaxOperacionesSimultaneas)
    {
        if(!alertaMaximaEmitida && AlertasActivas)
        {
            Print("🔒 DEEPSEEK LÍMITE: ", totalOperaciones, "/", MaxOperacionesSimultaneas);
            alertaMaximaEmitida = true;
        }
        return;
    }
    
    alertaMaximaEmitida = false;
    
    // Stop por pérdida diaria
    if(perdidaDiaria <= PerdidaMaximaDiaria)
    {
        CerrarTodasLasPosiciones();
        tiempoPausa = TimeCurrent() + PausaPerdidaDiaria;
        if(MostrarBotones)
        {
            ObjectSetString(0, "LabelEstadoDS", OBJPROP_TEXT, "PAUSA: -$" + DoubleToString(MathAbs(perdidaDiaria), 0));
            ObjectSetInteger(0, "LabelEstadoDS", OBJPROP_COLOR, clrOrange);
        }
        Print("⏸️ DEEPSEEK PAUSA POR PÉRDIDA: -$", MathAbs(perdidaDiaria));
        return;
    }
    
    // Take profit diario
    if(gananciaAcumulada >= TakeProfitDiario && TakeProfitDiario > 0)
    {
        CerrarTodasLasPosiciones();
        BotActivo = false;
        Print("🏆 OBJETIVO DIARIO ALCANZADO: $", gananciaAcumulada);
        if(MostrarBotones)
        {
            ObjectSetString(0, "LabelEstadoDS", OBJPROP_TEXT, "OBJETIVO: $" + DoubleToString(gananciaAcumulada, 0));
            ObjectSetInteger(0, "LabelEstadoDS", OBJPROP_COLOR, clrLime);
        }
        return;
    }
    
    // Nueva barra
    datetime tiempoActual = iTime(_Symbol, PERIOD_M1, 0);
    bool nuevaBarra = (tiempoActual != ultimaBarra);
    if(nuevaBarra) ultimaBarra = tiempoActual;
    
    // LÓGICA DE ENTRADA
    if(totalOperaciones < MaxOperacionesSimultaneas)
    {
        if(totalOperaciones == 0 && nuevaBarra)
        {
            if(VerificarVolumen())
                EvaluarPrimeraEntrada();
        }
        else if(totalOperaciones >= 1)
        {
            GestionarOperacionesAvanzadas();
        }
    }
    
    // Cierre de ganancias mejorado
    CerrarGanadorasMejorado();
    
    // Sustitución automática de operaciones cerradas
    if(SustitucionAutomatica && (TimeCurrent() - ultimoCierre) < 2)
    {
        EvaluarSustitucion();
    }
    
    if(MostrarBotones)
        ChartRedraw();
}

//+------------------------------------------------------------------+
void EvaluarSustitucion()
{
    if(totalOperaciones >= MaxOperacionesSimultaneas) return;
    
    datetime ahora = TimeCurrent();
    if(ahora - ultimoRefuerzo < 1) return; // Cooldown muy corto para sustitución
    
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // Analizar tendencia actual
    double close[];
    ArraySetAsSeries(close, true);
    if(CopyClose(_Symbol, PERIOD_M1, 0, 3, close) <= 0) return;
    
    double momentum = close[0] - close[2];
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    double momentumPips = momentum / (point * 10);
    
    // Determinar dirección basada en momentum
    if(momentumPips >= MomentumMinimoPips)
    {
        Print("🔄 SUSTITUCIÓN: COMPRA | Momento: +", DoubleToString(momentumPips, 1), "p");
        AbrirPosicion(ORDER_TYPE_BUY, LoteInicial, ask);
        ultimoRefuerzo = ahora;
    }
    else if(momentumPips <= -MomentumMinimoPips)
    {
        Print("🔄 SUSTITUCIÓN: VENTA | Momento: ", DoubleToString(momentumPips, 1), "p");
        AbrirPosicion(ORDER_TYPE_SELL, LoteInicial, bid);
        ultimoRefuerzo = ahora;
    }
}

//+------------------------------------------------------------------+
void GestionarStopLossMaximo()
{
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        if(posiciones[i].profit <= StopLossPorOperacion)
        {
            Print("🛑 DEEPSEEK CIERRE SL: $", DoubleToString(posiciones[i].profit, 2));
            if(trade.PositionClose(posiciones[i].ticket))
            {
                perdidaDiaria += posiciones[i].profit;
                SLconsecutivos++;
                Print("✅ CERRADA POR STOP LOSS (-$", StopLossPorOperacion, ")");
                
                // Reforzar positiva tras cerrar perdedora (más rápido)
                ReforzarPositivaTrasCierrePerdedora();
            }
        }
    }
}

//+------------------------------------------------------------------+
void ReforzarPositivaTrasCierrePerdedora()
{
    double mejorProfit = -9999;
    int mejorIdx = -1;
    
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        if(posiciones[i].profit > mejorProfit && posiciones[i].profit > 0.5)
        {
            mejorProfit = posiciones[i].profit;
            mejorIdx = i;
        }
    }
    
    if(mejorIdx >= 0 && totalOperaciones < MaxOperacionesSimultaneas)
    {
        datetime ahora = TimeCurrent();
        if(ahora - ultimoRefuerzo < 1) return; // Cooldown muy corto
        
        double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double siguienteLote = CalcularSiguienteLote();
        
        if(posiciones[mejorIdx].tipo == ORDER_TYPE_BUY)
        {
            Print("💪 REFUERZO TRAS SL: COMPRA | Profit: $", DoubleToString(mejorProfit, 2));
            AbrirPosicion(ORDER_TYPE_BUY, siguienteLote, ask);
            ultimoRefuerzo = ahora;
        }
        else
        {
            Print("💪 REFUERZO TRAS SL: VENTA | Profit: $", DoubleToString(mejorProfit, 2));
            AbrirPosicion(ORDER_TYPE_SELL, siguienteLote, bid);
            ultimoRefuerzo = ahora;
        }
    }
}

//+------------------------------------------------------------------+
void GestionarOperacionesAvanzadas()
{
    datetime ahora = TimeCurrent();
    if(ahora - ultimoRefuerzo < CooldownSegundos) return;
    
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
    
    // CONTRAOPERACIÓN MÁS AGRESIVA (con menos pérdida)
    if(peorProfitCompra <= PerdidaContraoperar && numVentas == 0)
    {
        Print("🔄 CONTRAOPERAR AGRESIVO: VENTA | Pérdida: $", DoubleToString(peorProfitCompra, 2));
        AbrirPosicion(ORDER_TYPE_SELL, siguienteLote, bid);
        ultimoRefuerzo = ahora;
        return;
    }
    
    if(peorProfitVenta <= PerdidaContraoperar && numCompras == 0)
    {
        Print("🔄 CONTRAOPERAR AGRESIVO: COMPRA | Pérdida: $", DoubleToString(peorProfitVenta, 2));
        AbrirPosicion(ORDER_TYPE_BUY, siguienteLote, ask);
        ultimoRefuerzo = ahora;
        return;
    }
    
    // REFUERZO MÁS AGRESIVO (con menos ganancia)
    if(mejorProfitCompra >= UmbralRefuerzoAgresivo)
    {
        Print("🚀 REFUERZO AGRESIVO COMPRA | Profit: $", DoubleToString(mejorProfitCompra, 2));
        AbrirPosicion(ORDER_TYPE_BUY, siguienteLote, ask);
        ultimoRefuerzo = ahora;
        return;
    }
    
    if(mejorProfitVenta >= UmbralRefuerzoAgresivo)
    {
        Print("🚀 REFUERZO AGRESIVO VENTA | Profit: $", DoubleToString(mejorProfitVenta, 2));
        AbrirPosicion(ORDER_TYPE_SELL, siguienteLote, bid);
        ultimoRefuerzo = ahora;
        return;
    }
}

//+------------------------------------------------------------------+
void CerrarGanadorasMejorado()
{
    datetime ahora = TimeCurrent();
    
    for(int i = ArraySize(posiciones) - 1; i >= 0; i--)
    {
        int segundos = (int)(ahora - posiciones[i].tiempoApertura);
        
        // REGLA 1: Cerrar si ganancia > ProfitMinimoCierre y tiempo > 30 segundos
        if(segundos >= 30 && posiciones[i].profit >= ProfitMinimoCierre)
        {
            double profitCierre = posiciones[i].profit;
            if(trade.PositionClose(posiciones[i].ticket))
            {
                perdidaDiaria += profitCierre;
                gananciaAcumulada += profitCierre;
                SLconsecutivos = 0;
                ultimoCierre = ahora;
                Print("💰 GANANCIA CERRADA: $", DoubleToString(profitCierre, 2), 
                      " en ", segundos, "s");
                
                // Marcar para sustitución
                if(SustitucionAutomatica)
                    Print("🔁 Operación cerrada - preparando sustitución...");
            }
        }
        // REGLA 2: Cerrar si gran ganancia > 10.0 inmediatamente
        else if(posiciones[i].profit >= 10.0)
        {
            double profitCierre = posiciones[i].profit;
            if(trade.PositionClose(posiciones[i].ticket))
            {
                perdidaDiaria += profitCierre;
                gananciaAcumulada += profitCierre;
                SLconsecutivos = 0;
                ultimoCierre = ahora;
                Print("💰💰 GRAN GANANCIA: $", DoubleToString(profitCierre, 2));
                
                if(SustitucionAutomatica)
                    Print("🔁 Operación cerrada - preparando sustitución...");
            }
        }
    }
}

//+------------------------------------------------------------------+
void GestionarTrailingStopMejorado()
{
    if(!UsarTrailingStop) return;
    
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    datetime ahora = TimeCurrent();
    
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        // Trailing solo si ganancia > MyTrailingStart
        if(posiciones[i].profit < MyTrailingStart) continue;
        
        if(!PositionSelectByTicket(posiciones[i].ticket)) continue;
        
        double sl = PositionGetDouble(POSITION_SL);
        double precioActual;
        double profitPorLote = posiciones[i].profit / posiciones[i].lote;
        
        // Trailing más agresivo según la ganancia
        double trailingPips = TrailingStepPips; // Valor base
        
        // Aumentar trailing según ganancia
        if(profitPorLote > 5.0) trailingPips = 30.0;  // 3 pips
        if(profitPorLote > 10.0) trailingPips = 40.0; // 4 pips
        if(profitPorLote > 15.0) trailingPips = 50.0; // 5 pips
        
        bool modificado = false;
        
        if(posiciones[i].tipo == ORDER_TYPE_BUY)
        {
            precioActual = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double nuevoSL = NormalizeDouble(precioActual - trailingPips * point * 10, digits);
            
            // Solo mover si mejora el SL en al menos 1 pip
            if(nuevoSL > sl + (1.0 * point * 10))
            {
                trade.PositionModify(posiciones[i].ticket, nuevoSL, 0);
                modificado = true;
                posiciones[i].cerradaPorTrailing = true;
            }
        }
        else
        {
            precioActual = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double nuevoSL = NormalizeDouble(precioActual + trailingPips * point * 10, digits);
            
            if(nuevoSL < sl - (1.0 * point * 10) || sl == 0)
            {
                trade.PositionModify(posiciones[i].ticket, nuevoSL, 0);
                modificado = true;
                posiciones[i].cerradaPorTrailing = true;
            }
        }
        
        if(modificado)
        {
            Print("🎯 TRAILING: $", DoubleToString(posiciones[i].profit, 2), 
                  " | SL movido ", DoubleToString(trailingPips, 1), "p");
            
            // Si el trailing cierra la posición, registrar para sustitución
            if(ahora - posiciones[i].tiempoApertura > 5)
            {
                ultimoCierre = ahora;
                if(SustitucionAutomatica)
                    Print("🔁 Trailing activado - posible sustitución...");
            }
        }
    }
}

//+------------------------------------------------------------------+
void GestionarBreakEvenRapido()
{
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    datetime ahora = TimeCurrent();
    
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        if(posiciones[i].profit >= MyBEActivacion && !posiciones[i].enBreakEven)
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
                    posiciones[i].enBreakEven = true;
                    posiciones[i].cerradaPorBE = true;
                    Print("🛡️ BE ACTIVADO COMPRA: $", DoubleToString(posiciones[i].profit, 2));
                    
                    // Registrar para posible sustitución
                    if(ahora - posiciones[i].tiempoApertura > 5)
                    {
                        ultimoCierre = ahora;
                        if(SustitucionAutomatica)
                            Print("🔁 BE activado - posible sustitución...");
                    }
                }
            }
            else
            {
                BE = NormalizeDouble(posiciones[i].precioApertura - BEPips * point * 10, digits);
                if(sl > posiciones[i].precioApertura || sl == 0)
                {
                    trade.PositionModify(posiciones[i].ticket, BE, 0);
                    posiciones[i].enBreakEven = true;
                    posiciones[i].cerradaPorBE = true;
                    Print("🛡️ BE ACTIVADO VENTA: $", DoubleToString(posiciones[i].profit, 2));
                    
                    if(ahora - posiciones[i].tiempoApertura > 5)
                    {
                        ultimoCierre = ahora;
                        if(SustitucionAutomatica)
                            Print("🔁 BE activado - posible sustitución...");
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
void AbrirPosicion(ENUM_ORDER_TYPE tipo, double lote, double precio)
{
    int opsActuales = ContarPosicionesAbiertas();
    if(opsActuales >= MaxOperacionesSimultaneas)
    {
        Print("❌ LÍMITE OPERACIONES: ", opsActuales, "/", MaxOperacionesSimultaneas);
        return;
    }
    
    datetime ahora = TimeCurrent();
    if(ahora - ultimaApertura < CooldownSegundos)
        return;
    
    if(!VerificarVolumen())
    {
        Print("❌ VOLUMEN INSUFICIENTE");
        return;
    }
    
    // Límite de operaciones diarias
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    MqlDateTime dtUltima;
    if(ultimaOperacionHoy > 0)
        TimeToStruct(ultimaOperacionHoy, dtUltima);
    
    if(ultimaOperacionHoy == 0 || dt.day != dtUltima.day || dt.mon != dtUltima.mon || dt.year != dtUltima.year)
        operacionesHoy = 0;
    
    if(operacionesHoy >= MaxOperacionesDiarias)
    {
        Print("❌ LÍMITE DIARIO: ", operacionesHoy, "/", MaxOperacionesDiarias);
        return;
    }
    
    // Calcular SL y TP
    double slPips = MyStopLossPips;
    double tpPips = TakeProfitPips;
    
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    
    double sl = 0, tp = 0;
    
    if(tipo == ORDER_TYPE_BUY)
    {
        sl = NormalizeDouble(precio - slPips * point * 10, digits);
        tp = NormalizeDouble(precio + tpPips * point * 10, digits);
        if(trade.Buy(lote, _Symbol, precio, sl, tp, "DEEPSEEK_AGG_v2.2"))
            RegistrarOperacion(tipo, lote);
    }
    else
    {
        sl = NormalizeDouble(precio + slPips * point * 10, digits);
        tp = NormalizeDouble(precio - tpPips * point * 10, digits);
        if(trade.Sell(lote, _Symbol, precio, sl, tp, "DEEPSEEK_AGG_v2.2"))
            RegistrarOperacion(tipo, lote);
    }
}

//+------------------------------------------------------------------+
void RegistrarOperacion(ENUM_ORDER_TYPE tipo, double lote)
{
    contadorOperaciones++;
    ultimaApertura = TimeCurrent();
    operacionesHoy++;
    ultimaOperacionHoy = TimeCurrent();
    
    Print("✅ ", (tipo==ORDER_TYPE_BUY?"COMPRA":"VENTA"), " #", contadorOperaciones, 
          " | Lote:", lote, 
          " | SL:", DoubleToString(MyStopLossPips, 0), "pips",
          " | TP:", DoubleToString(TakeProfitPips, 0), "pips",
          " | BE:$", DoubleToString(MyBEActivacion, 1),
          " | TRAIL:$", DoubleToString(MyTrailingStart, 1));
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
    
    double nuevoLote = maxLote * MyMultiplicadorLote;
    return NormalizarLote(nuevoLote);
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
               PositionGetInteger(POSITION_MAGIC) == 999777)
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
                posiciones[idx].cerradaPorBE = false;
                posiciones[idx].cerradaPorTrailing = false;
                
                if(posiciones[idx].profit > posiciones[idx].maxProfitAlcanzado)
                    posiciones[idx].maxProfitAlcanzado = posiciones[idx].profit;
            }
        }
    }
    
    // Detectar SL y gestionar pausas
    int opsDespues = ArraySize(posiciones);
    if(opsDespues < opsAntes && ActivarPausasInteligentes)
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
                    
                    if(ultimoCierre < StopLossPorOperacion/2)
                    {
                        SLconsecutivos++;
                        Print("⚠️ SL CONSECUTIVO #", SLconsecutivos, " | $", DoubleToString(ultimoCierre, 2));
                        
                        if(SLconsecutivos >= MaxSLConsecutivos)
                        {
                            int pausa = CalcularPausaInteligente();
                            tiempoPausa = TimeCurrent() + pausa;
                            Print("🛑 PAUSA ACTIVADA: ", pausa/60, " minutos");
                        }
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
int CalcularPausaInteligente()
{
    if(!ActivarPausasInteligentes) return 0;
    
    int pausa = PausaBaseSegundos;
    
    if(SLconsecutivos > 0)
        pausa = PausaBaseSegundos * MathPow(FactorAumentoPausa, SLconsecutivos);
    
    if(perdidaDiaria < -20) pausa *= 2;
    if(perdidaDiaria < -40) pausa *= 3;
    
    if(pausa > 7200) pausa = 7200;
    
    return pausa;
}

//+------------------------------------------------------------------+
int ContarPosicionesAbiertas() { return ArraySize(posiciones); }

//+------------------------------------------------------------------+
double CalcularProfitTotal()
{
    double total = 0;
    for(int i = 0; i < ArraySize(posiciones); i++)
        total += posiciones[i].profit;
    return total;
}

//+------------------------------------------------------------------+
void CerrarTodasLasPosiciones()
{
    for(int i = ArraySize(posiciones) - 1; i >= 0; i--)
    {
        double profitCierre = posiciones[i].profit;
        if(trade.PositionClose(posiciones[i].ticket))
        {
            perdidaDiaria += profitCierre;
            if(profitCierre > 0)
                gananciaAcumulada += profitCierre;
        }
    }
    ArrayResize(posiciones, 0);
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
        gananciaAcumulada = 0;
        mejorGananciaDia = 0;
        drawdownMaximo = 0;
        SLconsecutivos = 0;
        operacionesHoy = 0;
        contadorOperaciones = 0;
        ultimaResetPerdida = ahora;
        Print("📅 NUEVO DÍA INICIADO");
    }
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
        Print("🔵 ENTRADA COMPRA | Momento: +", DoubleToString(momentumPips, 1), "p");
        AbrirPosicion(ORDER_TYPE_BUY, LoteInicial, ask);
    }
    else if(momentumPips <= -MomentumMinimoPips)
    {
        Print("🔴 ENTRADA VENTA | Momento: ", DoubleToString(momentumPips, 1), "p");
        AbrirPosicion(ORDER_TYPE_SELL, LoteInicial, bid);
    }
}

//+------------------------------------------------------------------+
void CerrarPerdedorasSiCompensadas()
{
    if(ArraySize(posiciones) < 2) return;
    
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        if(posiciones[i].profit >= GananciaRefuerzo)
        {
            for(int j = 0; j < ArraySize(posiciones); j++)
            {
                if(i == j) continue;
                
                if(posiciones[j].tipo != posiciones[i].tipo && posiciones[j].profit < 0)
                {
                    double profitNeto = posiciones[i].profit + posiciones[j].profit;
                    
                    if(profitNeto >= 0.80)
                    {
                        Print("🔄 PAR COMPENSADO: $", DoubleToString(posiciones[i].profit, 2), 
                              " + $", DoubleToString(posiciones[j].profit, 2), 
                              " = $", DoubleToString(profitNeto, 2));
                        
                        double profit1 = posiciones[i].profit;
                        double profit2 = posiciones[j].profit;
                        
                        if(trade.PositionClose(posiciones[i].ticket))
                        {
                            perdidaDiaria += profit1;
                            gananciaAcumulada += profit1;
                            SLconsecutivos = 0;
                            ultimoCierre = TimeCurrent();
                        }
                        
                        if(trade.PositionClose(posiciones[j].ticket))
                            perdidaDiaria += profit2;
                        
                        Print("✅ NETO: $", DoubleToString(profitNeto, 2));
                        return;
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
bool VerificarVolumen()
{
    if(!UsarFiltroVolumen) return true;
    
    long volumenActual[1];
    if(CopyTickVolume(_Symbol, PERIOD_M1, 0, 1, volumenActual) > 0)
    {
        long volumenPromedio[20];
        if(CopyTickVolume(_Symbol, PERIOD_M1, 0, 20, volumenPromedio) > 0)
        {
            long suma = 0;
            for(int i = 0; i < 20; i++) suma += volumenPromedio[i];
            double promedio = suma / 20.0;
            
            if(volumenActual[0] < promedio * 0.5)
            {
                Print("⚠️ VOLUMEN MUY BAJO");
                return false;
            }
        }
    }
    return true;
}

//+------------------------------------------------------------------+
bool EsHoraSegura()
{
    if(!EvitarHorasNoticias) return true;
    
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    if(dt.hour < HoraInicioTrading || dt.hour >= HoraFinTrading)
    {
        Print("⏸️ FUERA HORARIO TRADING");
        return false;
    }
    
    if(dt.hour == 13 && dt.min >= 30) return false;
    if(dt.hour == 14 && dt.min <= 30) return false;
    
    if(dt.day_of_week == 5 && dt.day <= 7)
    {
        if(dt.hour == 12 && dt.min >= 30) return false;
        if(dt.hour == 13 && dt.min <= 30) return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
void CrearInterfazCompleta()
{
    int x = 150, y = 80, ancho = 100, alto = 30;
    
    // Botón ACTIVAR
    ObjectCreate(0, "BtnActivarDS", OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, "BtnActivarDS", OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, "BtnActivarDS", OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, "BtnActivarDS", OBJPROP_XSIZE, ancho);
    ObjectSetInteger(0, "BtnActivarDS", OBJPROP_YSIZE, alto);
    ObjectSetInteger(0, "BtnActivarDS", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "BtnActivarDS", OBJPROP_BGCOLOR, ColorBotones);
    ObjectSetInteger(0, "BtnActivarDS", OBJPROP_COLOR, clrWhite);
    ObjectSetString(0, "BtnActivarDS", OBJPROP_TEXT, "ACTIVAR");
    ObjectSetInteger(0, "BtnActivarDS", OBJPROP_FONTSIZE, 10);
    
    // Botón DESACTIVAR
    ObjectCreate(0, "BtnDesactivarDS", OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, "BtnDesactivarDS", OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, "BtnDesactivarDS", OBJPROP_YDISTANCE, y + alto + 10);
    ObjectSetInteger(0, "BtnDesactivarDS", OBJPROP_XSIZE, ancho);
    ObjectSetInteger(0, "BtnDesactivarDS", OBJPROP_YSIZE, alto);
    ObjectSetInteger(0, "BtnDesactivarDS", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "BtnDesactivarDS", OBJPROP_BGCOLOR, clrDarkOrange);
    ObjectSetInteger(0, "BtnDesactivarDS", OBJPROP_COLOR, clrWhite);
    ObjectSetString(0, "BtnDesactivarDS", OBJPROP_TEXT, "DESACTIVAR");
    ObjectSetInteger(0, "BtnDesactivarDS", OBJPROP_FONTSIZE, 10);
    
    // Botón CERRAR TODO (NUEVO)
    ObjectCreate(0, "BtnCerrarTodoDS", OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, "BtnCerrarTodoDS", OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, "BtnCerrarTodoDS", OBJPROP_YDISTANCE, y + (alto + 10) * 2);
    ObjectSetInteger(0, "BtnCerrarTodoDS", OBJPROP_XSIZE, ancho);
    ObjectSetInteger(0, "BtnCerrarTodoDS", OBJPROP_YSIZE, alto);
    ObjectSetInteger(0, "BtnCerrarTodoDS", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "BtnCerrarTodoDS", OBJPROP_BGCOLOR, clrRed);
    ObjectSetInteger(0, "BtnCerrarTodoDS", OBJPROP_COLOR, clrWhite);
    ObjectSetString(0, "BtnCerrarTodoDS", OBJPROP_TEXT, "CERRAR TODO");
    ObjectSetInteger(0, "BtnCerrarTodoDS", OBJPROP_FONTSIZE, 10);
    
    // Etiqueta ESTADO
    ObjectCreate(0, "LabelEstadoDS", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "LabelEstadoDS", OBJPROP_XDISTANCE, x - 20);
    ObjectSetInteger(0, "LabelEstadoDS", OBJPROP_YDISTANCE, y + (alto + 10) * 3 + 10);
    ObjectSetInteger(0, "LabelEstadoDS", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "LabelEstadoDS", OBJPROP_COLOR, clrDodgerBlue);
    ObjectSetString(0, "LabelEstadoDS", OBJPROP_TEXT, BotActivo?"DEEPSEEK: ON":"DEEPSEEK: OFF");
    ObjectSetInteger(0, "LabelEstadoDS", OBJPROP_FONTSIZE, 9);
    ObjectSetString(0, "LabelEstadoDS", OBJPROP_FONT, "Arial Bold");
    
    // Etiqueta INFO
    ObjectCreate(0, "LabelInfoDS", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "LabelInfoDS", OBJPROP_XDISTANCE, x - 20);
    ObjectSetInteger(0, "LabelInfoDS", OBJPROP_YDISTANCE, y + (alto + 10) * 3 + 27);
    ObjectSetInteger(0, "LabelInfoDS", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "LabelInfoDS", OBJPROP_COLOR, clrWhite);
    ObjectSetString(0, "LabelInfoDS", OBJPROP_TEXT, "Ops: 0/0 | $0.00");
    ObjectSetInteger(0, "LabelInfoDS", OBJPROP_FONTSIZE, 8);
    
    // Etiqueta RIESGO
    ObjectCreate(0, "LabelRiesgoDS", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "LabelRiesgoDS", OBJPROP_XDISTANCE, x - 20);
    ObjectSetInteger(0, "LabelRiesgoDS", OBJPROP_YDISTANCE, y + (alto + 10) * 3 + 44);
    ObjectSetInteger(0, "LabelRiesgoDS", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "LabelRiesgoDS", OBJPROP_COLOR, clrYellow);
    ObjectSetString(0, "LabelRiesgoDS", OBJPROP_TEXT, "Día: $0.00 | SL: 0");
    ObjectSetInteger(0, "LabelRiesgoDS", OBJPROP_FONTSIZE, 8);
    
    // Etiqueta STATS
    ObjectCreate(0, "LabelStatsDS", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "LabelStatsDS", OBJPROP_XDISTANCE, x - 20);
    ObjectSetInteger(0, "LabelStatsDS", OBJPROP_YDISTANCE, y + (alto + 10) * 3 + 61);
    ObjectSetInteger(0, "LabelStatsDS", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "LabelStatsDS", OBJPROP_COLOR, clrSilver);
    ObjectSetString(0, "LabelStatsDS", OBJPROP_TEXT, "Ops Hoy: 0/100 | Gan: $0");
    ObjectSetInteger(0, "LabelStatsDS", OBJPROP_FONTSIZE, 7);
    
    // Etiqueta CONFIG
    ObjectCreate(0, "LabelConfigDS", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "LabelConfigDS", OBJPROP_XDISTANCE, x - 20);
    ObjectSetInteger(0, "LabelConfigDS", OBJPROP_YDISTANCE, y + (alto + 10) * 3 + 78);
    ObjectSetInteger(0, "LabelConfigDS", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "LabelConfigDS", OBJPROP_COLOR, clrGray);
    ObjectSetString(0, "LabelConfigDS", OBJPROP_TEXT, "SL: "+DoubleToString(MyStopLossPips,0)+"p | TP: "+DoubleToString(TakeProfitPips,0)+"p");
    ObjectSetInteger(0, "LabelConfigDS", OBJPROP_FONTSIZE, 7);
}

//+------------------------------------------------------------------+
void ActualizarInterfazCompleta()
{
    int numBuys = 0, numSells = 0;
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        if(posiciones[i].tipo == ORDER_TYPE_BUY) numBuys++;
        else numSells++;
    }
    
    string infoText = StringFormat("Ops: %d/%d (B:%d S:%d) | $%.2f", 
        totalOperaciones,
        MaxOperacionesSimultaneas,
        numBuys,
        numSells,
        profitTotal);
    ObjectSetString(0, "LabelInfoDS", OBJPROP_TEXT, infoText);
    ObjectSetInteger(0, "LabelInfoDS", OBJPROP_COLOR, profitTotal > 0 ? clrLime : (profitTotal < 0 ? clrRed : clrWhite));
    
    string riesgoText = StringFormat("Día: $%.2f | SL: %d | DD: $%.2f", perdidaDiaria, SLconsecutivos, drawdownMaximo);
    ObjectSetString(0, "LabelRiesgoDS", OBJPROP_TEXT, riesgoText);
    ObjectSetInteger(0, "LabelRiesgoDS", OBJPROP_COLOR, 
        SLconsecutivos >= 2 ? clrOrange : (SLconsecutivos >= 3 ? clrRed : clrYellow));
    
    string statsText = StringFormat("Ops Hoy: %d/%d | Gan: $%.1f | Mejor: $%.1f", 
        operacionesHoy, MaxOperacionesDiarias, gananciaAcumulada, mejorGananciaDia);
    ObjectSetString(0, "LabelStatsDS", OBJPROP_TEXT, statsText);
    ObjectSetInteger(0, "LabelStatsDS", OBJPROP_COLOR, 
        gananciaAcumulada >= TakeProfitDiario/2 ? clrLime : (gananciaAcumulada > 0 ? clrYellow : clrSilver));
    
    ObjectSetString(0, "LabelEstadoDS", OBJPROP_TEXT, BotActivo?"DEEPSEEK: ON":"DEEPSEEK: OFF");
    ObjectSetInteger(0, "LabelEstadoDS", OBJPROP_COLOR, BotActivo?clrLime:clrRed);
    
    string configText = StringFormat("SL: %.0fp | TP: %.0fp | BE: $%.1f | TRAIL: $%.1f", 
        MyStopLossPips, TakeProfitPips, MyBEActivacion, MyTrailingStart);
    ObjectSetString(0, "LabelConfigDS", OBJPROP_TEXT, configText);
}

//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    if(id == CHARTEVENT_OBJECT_CLICK && MostrarBotones)
    {
        if(sparam == "BtnActivarDS")
        {
            BotActivo = true;
            tiempoPausa = 0;
            SLconsecutivos = 0;
            Print("🚀 DEEPSEEK AGGRESSIVE v2.2 ACTIVADO");
            ObjectSetInteger(0, "BtnActivarDS", OBJPROP_STATE, false);
        }
        else if(sparam == "BtnDesactivarDS")
        {
            BotActivo = false;
            Print("⏸️ DEEPSEEK DESACTIVADO");
            ObjectSetInteger(0, "BtnDesactivarDS", OBJPROP_STATE, false);
        }
        else if(sparam == "BtnCerrarTodoDS")
        {
            Print("🛑 CIERRE MANUAL ACTIVADO");
            CerrarTodasLasPosiciones();
            Print("✅ TODAS LAS POSICIONES CERRADAS");
            ObjectSetInteger(0, "BtnCerrarTodoDS", OBJPROP_STATE, false);
        }
        if(MostrarBotones)
            ChartRedraw();
    }
}
//+------------------------------------------------------------------+
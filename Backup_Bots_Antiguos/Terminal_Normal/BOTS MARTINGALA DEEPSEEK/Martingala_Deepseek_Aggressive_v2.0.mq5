//+------------------------------------------------------------------+
//|              Martingala_Deepseek_Aggressive_v2.0.mq5            |
//|               VERSIÓN AGRESIVA - COMPLETAMENTE CONFIGURABLE     |
//+------------------------------------------------------------------+
#property copyright "Martingala Deepseek Aggressive v2.0"
#property version   "2.00"
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
input ENUM_PAR_TRADING ParTrading = PAR_AUTO;
input double   LoteInicial = 0.01;
input int      MaxOperacionesSimultaneas = 4;
input int      MaxOperacionesDiarias = 100;
input bool     BotActivoInicio = false;

input group "=== GESTIÓN DE RIESGO ==="
input double   StopLossPorOperacion = -3.0;      // Cierre perdedoras a -$X
input double   PerdidaMaximaDiaria = -100.0;     // Stop diario negativo
input double   TakeProfitDiario = 1000.0;        // Objetivo diario positivo
input double   ProfitMinimoCierre = 3.0;         // Cerrar ganadoras desde $X
input double   GananciaRefuerzo = 2.0;           // Reforzar desde $X
input double   PerdidaContraoperar = -1.0;       // Contraoperar desde -$X

input group "=== CONFIGURACIÓN TÉCNICA ==="
input double   StopLossPips = 40.0;              // SL en pips (10 = 1 pip estándar)
input double   TakeProfitPips = 0.0;             // TP en pips (0 = sin TP)
input bool     UsarBreakEven = true;
input double   BEActivacionProfit = 0.60;        // $ para activar BE
input double   BEPips = 1.0;                     // Pips para mover SL a BE
input bool     UsarTrailingStop = true;
input double   TrailingStartProfit = 1.5;        // $ para iniciar trailing
input double   TrailingStepPips = 1.5;           // Pips de paso trailing

input group "=== CONFIGURACIÓN OPERATIVA ==="
input double   MultiplicadorLoteMaximo = 2.0;    // Multiplicador máximo
input int      CooldownSegundos = 10;            // Espera entre operaciones
input bool     CerrarPerdedoraSiCompensa = true;
input double   UmbralRefuerzoAgresivo = 1.5;     // Refuerzo temprano desde $X

input group "=== PAUSAS INTELIGENTES ==="
input bool     ActivarPausasInteligentes = true;
input int      PausaBaseSegundos = 300;          // 300s = 5 minutos base
input double   FactorAumentoPausa = 1.5;         // Aumento exponencial
input int      MaxSLConsecutivos = 3;            // SL consecutivos para pausa
input int      PausaPerdidaDiaria = 7200;        // Pausa 2h si pérdida diaria (seg)

input group "=== FILTROS DE MERCADO ==="
input bool     UsarFiltroVolumen = false;
input bool     EvitarHorasNoticias = true;
input int      HoraInicioTrading = 1;
input int      HoraFinTrading = 22;
input double   MomentumMinimoPips = 2.0;         // Momento mínimo entrada
input int      DistanciaMinimaPips = 12;         // Distancia entre operaciones

input group "=== CONFIGURACIÓN ESPECÍFICA ORO (XAUUSD) ==="
input double   ORO_StopLossPips = 80.0;
input double   ORO_BEActivacion = 0.50;
input double   ORO_TrailingStart = 1.50;
input double   ORO_MultiplicadorLote = 2.0;

input group "=== INTERFAZ ==="
input bool     MostrarBotones = true;
input color    ColorBotones = clrDodgerBlue;
input bool     AlertasActivas = true;

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
    Print("        DEEPSEEK AGGRESSIVE v2.0");
    Print("         VERSIÓN COMPLETAMENTE CONFIGURABLE");
    Print("═══════════════════════════════════════════════════");
    Print("Par: ", NombrePar);
    Print("Lote inicial: ", LoteInicial);
    Print("Stop Loss/Operación: $", StopLossPorOperacion);
    Print("Stop Loss Pips: ", MyStopLossPips);
    Print("Take Profit Pips: ", TakeProfitPips);
    Print("Perdida máxima diaria: $", PerdidaMaximaDiaria);
    Print("Objetivo diario: $", TakeProfitDiario);
    Print("Multiplicador máximo: ", MyMultiplicadorLote);
    Print("Operaciones máximas: ", MaxOperacionesSimultaneas);
    Print("Operaciones diarias: ", MaxOperacionesDiarias);
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
        GestionarTrailingStop();
    
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
    
    if(MostrarBotones)
        ChartRedraw();
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
                
                // Reforzar positiva tras cerrar perdedora
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
        double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double siguienteLote = CalcularSiguienteLote();
        
        if(posiciones[mejorIdx].tipo == ORDER_TYPE_BUY)
        {
            Print("💪 REFUERZO TRAS SL: COMPRA | Profit: $", DoubleToString(mejorProfit, 2));
            AbrirPosicion(ORDER_TYPE_BUY, siguienteLote, ask);
        }
        else
        {
            Print("💪 REFUERZO TRAS SL: VENTA | Profit: $", DoubleToString(mejorProfit, 2));
            AbrirPosicion(ORDER_TYPE_SELL, siguienteLote, bid);
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
    
    // Contraoperación rápida
    if(peorProfitCompra <= PerdidaContraoperar && numVentas == 0)
    {
        Print("🔄 CONTRAOPERAR: VENTA | Pérdida: $", DoubleToString(peorProfitCompra, 2));
        AbrirPosicion(ORDER_TYPE_SELL, siguienteLote, bid);
        ultimoRefuerzo = ahora;
        return;
    }
    
    if(peorProfitVenta <= PerdidaContraoperar && numCompras == 0)
    {
        Print("🔄 CONTRAOPERAR: COMPRA | Pérdida: $", DoubleToString(peorProfitVenta, 2));
        AbrirPosicion(ORDER_TYPE_BUY, siguienteLote, ask);
        ultimoRefuerzo = ahora;
        return;
    }
    
    // Refuerzo agresivo
    if(mejorProfitCompra >= UmbralRefuerzoAgresivo && numCompras < 2)
    {
        Print("🚀 REFUERZO AGRESIVO COMPRA | Profit: $", DoubleToString(mejorProfitCompra, 2));
        AbrirPosicion(ORDER_TYPE_BUY, siguienteLote, ask);
        ultimoRefuerzo = ahora;
        return;
    }
    
    if(mejorProfitVenta >= UmbralRefuerzoAgresivo && numVentas < 2)
    {
        Print("🚀 REFUERZO AGRESIVO VENTA | Profit: $", DoubleToString(mejorProfitVenta, 2));
        AbrirPosicion(ORDER_TYPE_SELL, siguienteLote, bid);
        ultimoRefuerzo = ahora;
        return;
    }
    
    // Cerrar ganadoras
    CerrarGanadoras();
}

//+------------------------------------------------------------------+
void CerrarGanadoras()
{
    datetime ahora = TimeCurrent();
    
    for(int i = ArraySize(posiciones) - 1; i >= 0; i--)
    {
        int segundos = (int)(ahora - posiciones[i].tiempoApertura);
        
        // Cerrar si supera profit mínimo
        if(segundos >= 20 && posiciones[i].profit >= ProfitMinimoCierre)
        {
            double profitCierre = posiciones[i].profit;
            if(trade.PositionClose(posiciones[i].ticket))
            {
                perdidaDiaria += profitCierre;
                gananciaAcumulada += profitCierre;
                SLconsecutivos = 0;
                Print("💰 GANADORA CERRADA: $", DoubleToString(profitCierre, 2), " en ", segundos, "s");
            }
        }
        // Cerrar inmediatamente si gran ganancia
        else if(posiciones[i].profit >= 6.0)
        {
            double profitCierre = posiciones[i].profit;
            if(trade.PositionClose(posiciones[i].ticket))
            {
                perdidaDiaria += profitCierre;
                gananciaAcumulada += profitCierre;
                SLconsecutivos = 0;
                Print("💰💰 GRAN GANANCIA: $", DoubleToString(profitCierre, 2));
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
    
    // Máximo 2 operaciones por tipo
    int numBuys = 0, numSells = 0;
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        if(posiciones[i].tipo == ORDER_TYPE_BUY) numBuys++;
        else numSells++;
    }
    
    if(tipo == ORDER_TYPE_BUY && numBuys >= 2) return;
    if(tipo == ORDER_TYPE_SELL && numSells >= 2) return;
    
    // Calcular SL y TP
    double slPips = MyStopLossPips;
    double tpPips = TakeProfitPips;
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    
    double sl = 0, tp = 0;
    
    if(tipo == ORDER_TYPE_BUY)
    {
        sl = NormalizeDouble(precio - slPips * point * 10, digits);
        if(tpPips > 0)
            tp = NormalizeDouble(precio + tpPips * point * 10, digits);
        if(trade.Buy(lote, _Symbol, precio, sl, tp, "DEEPSEEK_AGG"))
            RegistrarOperacion(tipo, lote);
    }
    else
    {
        sl = NormalizeDouble(precio + slPips * point * 10, digits);
        if(tpPips > 0)
            tp = NormalizeDouble(precio - tpPips * point * 10, digits);
        if(trade.Sell(lote, _Symbol, precio, sl, tp, "DEEPSEEK_AGG"))
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
          " | SL:", DoubleToString(MyStopLossPips, 1), "pips",
          TakeProfitPips>0?" | TP:"+DoubleToString(TakeProfitPips,1)+"pips":"");
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
void GestionarBreakEvenRapido()
{
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        if(posiciones[i].profit >= MyBEActivacion)
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
void GestionarTrailingStop()
{
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    
    for(int i = 0; i < ArraySize(posiciones); i++)
    {
        if(posiciones[i].profit < MyTrailingStart) continue;
        
        if(!PositionSelectByTicket(posiciones[i].ticket)) continue;
        
        double sl = PositionGetDouble(POSITION_SL);
        double precioActual;
        
        if(posiciones[i].tipo == ORDER_TYPE_BUY)
        {
            precioActual = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double nuevoSL = NormalizeDouble(precioActual - TrailingStepPips * point * 10, digits);
            if(nuevoSL > sl)
                trade.PositionModify(posiciones[i].ticket, nuevoSL, 0);
        }
        else
        {
            precioActual = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double nuevoSL = NormalizeDouble(precioActual + TrailingStepPips * point * 10, digits);
            if(nuevoSL < sl || sl == 0)
                trade.PositionModify(posiciones[i].ticket, nuevoSL, 0);
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
    
    // Etiqueta ESTADO
    ObjectCreate(0, "LabelEstadoDS", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "LabelEstadoDS", OBJPROP_XDISTANCE, x - 20);
    ObjectSetInteger(0, "LabelEstadoDS", OBJPROP_YDISTANCE, y + (alto + 10) * 2 + 5);
    ObjectSetInteger(0, "LabelEstadoDS", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "LabelEstadoDS", OBJPROP_COLOR, clrDodgerBlue);
    ObjectSetString(0, "LabelEstadoDS", OBJPROP_TEXT, BotActivo?"DEEPSEEK: ON":"DEEPSEEK: OFF");
    ObjectSetInteger(0, "LabelEstadoDS", OBJPROP_FONTSIZE, 9);
    ObjectSetString(0, "LabelEstadoDS", OBJPROP_FONT, "Arial Bold");
    
    // Etiqueta INFO
    ObjectCreate(0, "LabelInfoDS", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "LabelInfoDS", OBJPROP_XDISTANCE, x - 20);
    ObjectSetInteger(0, "LabelInfoDS", OBJPROP_YDISTANCE, y + (alto + 10) * 2 + 22);
    ObjectSetInteger(0, "LabelInfoDS", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "LabelInfoDS", OBJPROP_COLOR, clrWhite);
    ObjectSetString(0, "LabelInfoDS", OBJPROP_TEXT, "Ops: 0/0 | $0.00");
    ObjectSetInteger(0, "LabelInfoDS", OBJPROP_FONTSIZE, 8);
    
    // Etiqueta RIESGO
    ObjectCreate(0, "LabelRiesgoDS", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "LabelRiesgoDS", OBJPROP_XDISTANCE, x - 20);
    ObjectSetInteger(0, "LabelRiesgoDS", OBJPROP_YDISTANCE, y + (alto + 10) * 2 + 39);
    ObjectSetInteger(0, "LabelRiesgoDS", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "LabelRiesgoDS", OBJPROP_COLOR, clrYellow);
    ObjectSetString(0, "LabelRiesgoDS", OBJPROP_TEXT, "Día: $0.00 | SL: 0");
    ObjectSetInteger(0, "LabelRiesgoDS", OBJPROP_FONTSIZE, 8);
    
    // Etiqueta STATS
    ObjectCreate(0, "LabelStatsDS", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "LabelStatsDS", OBJPROP_XDISTANCE, x - 20);
    ObjectSetInteger(0, "LabelStatsDS", OBJPROP_YDISTANCE, y + (alto + 10) * 2 + 56);
    ObjectSetInteger(0, "LabelStatsDS", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "LabelStatsDS", OBJPROP_COLOR, clrSilver);
    ObjectSetString(0, "LabelStatsDS", OBJPROP_TEXT, "Ops Hoy: 0/100 | Gan: $0");
    ObjectSetInteger(0, "LabelStatsDS", OBJPROP_FONTSIZE, 7);
    
    // Etiqueta CONFIG
    ObjectCreate(0, "LabelConfigDS", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "LabelConfigDS", OBJPROP_XDISTANCE, x - 20);
    ObjectSetInteger(0, "LabelConfigDS", OBJPROP_YDISTANCE, y + (alto + 10) * 2 + 73);
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
    
    string configText = StringFormat("SL: %.0fp | TP: %.0fp | BE: $%.2f | TRAIL: $%.2f", 
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
            Print("🚀 DEEPSEEK AGGRESSIVE ACTIVADO");
            ObjectSetInteger(0, "BtnActivarDS", OBJPROP_STATE, false);
        }
        else if(sparam == "BtnDesactivarDS")
        {
            BotActivo = false;
            Print("⏸️ DEEPSEEK DESACTIVADO");
            ObjectSetInteger(0, "BtnDesactivarDS", OBJPROP_STATE, false);
        }
        if(MostrarBotones)
            ChartRedraw();
    }
}
//+------------------------------------------------------------------+

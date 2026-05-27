//+------------------------------------------------------------------+
//|              Martingala_Deepseek_Segura_v3.0.mq5                |
//|           VERSIÓN SEGURA - SIN MARTINGALA AGRESIVA              |
//+------------------------------------------------------------------+
#property copyright "Martingala Deepseek Segura v3.0"
#property version   "3.00"
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
input int      MaxOperacionesSimultaneas = 2;
input int      MaxOperacionesDiarias = 30;
input bool     BotActivoInicio = true;

input group "=== GESTIÓN DE RIESGO (CRÍTICO) ==="
input double   StopLossPorOperacion = -5.0;
input double   PerdidaMaximaDiaria = -40.0;
input double   TakeProfitDiario = 25.0;
input double   ProfitMinimoCierre = 2.5;
input double   GananciaRefuerzo = 1.5;
input double   PerdidaContraoperar = -3.0;

input group "=== CONFIGURACIÓN TÉCNICA PARA ORO ==="
input double   StopLossPips = 500.0;
input double   TakeProfitPips = 250.0;
input bool     UsarBreakEven = true;
input double   BEActivacionProfit = 1.5;
input double   BEPips = 150.0;
input bool     UsarTrailingStop = true;
input double   TrailingStartProfit = 2.0;
input double   TrailingStepPips = 100.0;

input group "=== CONFIGURACIÓN OPERATIVA SEGURA ==="
input double   MultiplicadorLoteMaximo = 1.3;
input int      CooldownSegundos = 5;
input bool     CerrarPerdedoraSiCompensa = false;
input double   UmbralRefuerzoAgresivo = 2.5;
input bool     SustitucionAutomatica = false;

input group "=== PAUSAS INTELIGENTES ==="
input bool     ActivarPausasInteligentes = true;
input int      PausaBaseSegundos = 600;
input double   FactorAumentoPausa = 1.5;
input int      MaxSLConsecutivos = 2;
input int      PausaPerdidaDiaria = 3600;

input group "=== FILTROS DE MERCADO ==="
input bool     UsarFiltroVolumen = false;
input bool     EvitarHorasNoticias = true;
input int      HoraInicioTrading = 8;
input int      HoraFinTrading = 20;
input double   MomentumMinimoPips = 2.0;
input int      DistanciaMinimaPips = 50;

input group "=== CONFIGURACIÓN ESPECÍFICA ORO (XAUUSD) ==="
input double   ORO_StopLossPips = 500.0;
input double   ORO_BEActivacion = 1.5;
input double   ORO_TrailingStart = 2.0;
input double   ORO_MultiplicadorLote = 1.3;

input group "=== INTERFAZ ==="
input bool     MostrarBotones = true;
input color    ColorBotones = clrDodgerBlue;
input bool     AlertasActivas = true;
input bool     PermitirCierreManual = true;

// ============ VARIABLES GLOBALES ============
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
    Print("        DEEPSEEK SEGURA v3.0");
    Print("         VERSIÓN SEGURA SIN INVALID STOPS");
    Print("═══════════════════════════════════════════════════");
    Print("Par: ", NombrePar);
    Print("Lote inicial: ", LoteInicial);
    Print("Stop Loss: ", MyStopLossPips/10, " pips reales");
    Print("Take Profit: ", TakeProfitPips/10, " pips reales");
    Print("Stop Loss/Operación: $", StopLossPorOperacion);
    Print("BE activación: $", BEActivacionProfit);
    Print("Trailing start: $", TrailingStartProfit);
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
    
    if(!EsHoraSegura())
    {
        if(totalOperaciones > 0)
            CerrarTodasLasPosiciones();
        return;
    }
    
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
    
    if(UsarBreakEven)
        GestionarBreakEvenRapido();
    
    if(UsarTrailingStop)
        GestionarTrailingStopMejorado();
    
    GestionarStopLossMaximo();
    
    profitTotal = CalcularProfitTotal();
    
    if(profitTotal < drawdownMaximo)
        drawdownMaximo = profitTotal;
    
    if(gananciaAcumulada > mejorGananciaDia)
        mejorGananciaDia = gananciaAcumulada;
    
    if(MostrarBotones)
        ActualizarInterfazCompleta();
    
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
    
    datetime tiempoActual = iTime(_Symbol, PERIOD_M1, 0);
    bool nuevaBarra = (tiempoActual != ultimaBarra);
    if(nuevaBarra) ultimaBarra = tiempoActual;
    
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
    
    CerrarGanadorasMejorado();
    
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
            }
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
    
    if(mejorProfitCompra >= UmbralRefuerzoAgresivo)
    {
        Print("🚀 REFUERZO COMPRA | Profit: $", DoubleToString(mejorProfitCompra, 2));
        AbrirPosicion(ORDER_TYPE_BUY, siguienteLote, ask);
        ultimoRefuerzo = ahora;
        return;
    }
    
    if(mejorProfitVenta >= UmbralRefuerzoAgresivo)
    {
        Print("🚀 REFUERZO VENTA | Profit: $", DoubleToString(mejorProfitVenta, 2));
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
        
        if(segundos >= 60 && posiciones[i].profit >= ProfitMinimoCierre)
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
            }
        }
        else if(posiciones[i].profit >= 8.0)
        {
            double profitCierre = posiciones[i].profit;
            if(trade.PositionClose(posiciones[i].ticket))
            {
                perdidaDiaria += profitCierre;
                gananciaAcumulada += profitCierre;
                SLconsecutivos = 0;
                ultimoCierre = ahora;
                Print("💰💰 GRAN GANANCIA: $", DoubleToString(profitCierre, 2));
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
        if(posiciones[i].profit < MyTrailingStart) continue;
        
        if(!PositionSelectByTicket(posiciones[i].ticket)) continue;
        
        double sl = PositionGetDouble(POSITION_SL);
        double precioActual;
        double trailingPips = TrailingStepPips;
        
        bool modificado = false;
        
        if(posiciones[i].tipo == ORDER_TYPE_BUY)
        {
            precioActual = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double nuevoSL = NormalizeDouble(precioActual - trailingPips * point * 10, digits);
            
            double distanciaMinima = 50 * point * 10;
            
            if(nuevoSL > sl + distanciaMinima)
            {
                if(ValidarStopLoss(posiciones[i].precioApertura, nuevoSL, ORDER_TYPE_BUY))
                {
                    if(trade.PositionModify(posiciones[i].ticket, nuevoSL, 0))
                    {
                        modificado = true;
                        posiciones[i].cerradaPorTrailing = true;
                    }
                }
            }
        }
        else
        {
            precioActual = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double nuevoSL = NormalizeDouble(precioActual + trailingPips * point * 10, digits);
            
            double distanciaMinima = 50 * point * 10;
            
            if(nuevoSL < sl - distanciaMinima || sl == 0)
            {
                if(ValidarStopLoss(posiciones[i].precioApertura, nuevoSL, ORDER_TYPE_SELL))
                {
                    if(trade.PositionModify(posiciones[i].ticket, nuevoSL, 0))
                    {
                        modificado = true;
                        posiciones[i].cerradaPorTrailing = true;
                    }
                }
            }
        }
        
        if(modificado)
        {
            Print("🎯 TRAILING: $", DoubleToString(posiciones[i].profit, 2), 
                  " | SL movido ", DoubleToString(trailingPips/10, 1), "p reales");
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
                if(ValidarStopLoss(posiciones[i].precioApertura, BE, ORDER_TYPE_BUY))
                {
                    if(sl < posiciones[i].precioApertura)
                    {
                        if(trade.PositionModify(posiciones[i].ticket, BE, 0))
                        {
                            posiciones[i].enBreakEven = true;
                            posiciones[i].cerradaPorBE = true;
                            Print("🛡️ BE ACTIVADO COMPRA: $", DoubleToString(posiciones[i].profit, 2));
                        }
                    }
                }
            }
            else
            {
                BE = NormalizeDouble(posiciones[i].precioApertura - BEPips * point * 10, digits);
                if(ValidarStopLoss(posiciones[i].precioApertura, BE, ORDER_TYPE_SELL))
                {
                    if(sl > posiciones[i].precioApertura || sl == 0)
                    {
                        if(trade.PositionModify(posiciones[i].ticket, BE, 0))
                        {
                            posiciones[i].enBreakEven = true;
                            posiciones[i].cerradaPorBE = true;
                            Print("🛡️ BE ACTIVADO VENTA: $", DoubleToString(posiciones[i].profit, 2));
                        }
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
bool ValidarStopLoss(double precioEntrada, double sl, ENUM_ORDER_TYPE tipo)
{
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    double minDist = 100 * point * 10;
    
    double stopsLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * point;
    if(stopsLevel > minDist) minDist = stopsLevel;
    
    if(tipo == ORDER_TYPE_BUY)
    {
        double distancia = precioEntrada - sl;
        if(distancia < minDist)
        {
            Print("❌ STOP LOSS INVÁLIDO PARA COMPRA:");
            Print("   Entrada: ", precioEntrada, " | SL propuesto: ", sl);
            Print("   Distancia: ", distancia/point, " puntos (necesarios: ", minDist/point, ")");
            return false;
        }
    }
    else
    {
        double distancia = sl - precioEntrada;
        if(distancia < minDist)
        {
            Print("❌ STOP LOSS INVÁLIDO PARA VENTA:");
            Print("   Entrada: ", precioEntrada, " | SL propuesto: ", sl);
            Print("   Distancia: ", distancia/point, " puntos (necesarios: ", minDist/point, ")");
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
void AbrirPosicion(ENUM_ORDER_TYPE tipo, double lote, double precio)
{
    if(lote > 0.05) 
    {
        Print("⚠️ LOTE LIMITADO: ", lote, " → 0.05");
        lote = 0.05;
    }
    
    int opsActuales = ContarPosicionesAbiertas();
    if(opsActuales >= MaxOperacionesSimultaneas)
    {
        Print("❌ LÍMITE OPERACIONES: ", opsActuales, "/", MaxOperacionesSimultaneas);
        return;
    }
    
    datetime ahora = TimeCurrent();
    if(ahora - ultimaApertura < CooldownSegundos)
        return;
    
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
    
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    
    double sl = 0, tp = 0;
    
    if(tipo == ORDER_TYPE_BUY)
    {
        sl = NormalizeDouble(precio - 500 * point * 10, digits);
        tp = NormalizeDouble(precio + 250 * point * 10, digits);
        
        if(!ValidarStopLoss(precio, sl, tipo))
        {
            sl = NormalizeDouble(precio - 600 * point * 10, digits);
            Print("🛠️  SL AJUSTADO A DISTANCIA SEGURA: ", sl);
        }
        
        if(trade.Buy(lote, _Symbol, precio, sl, tp, "DEEPSEEK_SAFE_v3.0"))
            RegistrarOperacion(tipo, lote);
        else
            Print("❌ Error abriendo compra: ", GetErrorDescription((int)GetLastError()));
    }
    else
    {
        sl = NormalizeDouble(precio + 500 * point * 10, digits);
        tp = NormalizeDouble(precio - 250 * point * 10, digits);
        
        if(!ValidarStopLoss(precio, sl, tipo))
        {
            sl = NormalizeDouble(precio + 600 * point * 10, digits);
            Print("🛠️  SL AJUSTADO A DISTANCIA SEGURA: ", sl);
        }
        
        if(trade.Sell(lote, _Symbol, precio, sl, tp, "DEEPSEEK_SAFE_v3.0"))
            RegistrarOperacion(tipo, lote);
        else
            Print("❌ Error abriendo venta: ", GetErrorDescription((int)GetLastError()));
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
          " | SL: 50p reales",
          " | TP: 25p reales",
          " | BE: $", DoubleToString(MyBEActivacion, 1),
          " | TRAIL: $", DoubleToString(MyTrailingStart, 1));
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
    
    double maxPermitido = 0.05;
    if(nuevoLote > maxPermitido) {
        nuevoLote = maxPermitido;
        Print("⚠️ LOTE LIMITADO A MÁXIMO: ", maxPermitido);
    }
    
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
    
    int opsDespues = ArraySize(posiciones);
    if(opsDespues < opsAntes && ActivarPausasInteligentes)
    {
        SLconsecutivos++;
        Print("⚠️ SL CONSECUTIVO #", SLconsecutivos);
        
        if(SLconsecutivos >= MaxSLConsecutivos)
        {
            int pausa = CalcularPausaInteligente();
            tiempoPausa = TimeCurrent() + pausa;
            Print("🛑 PAUSA ACTIVADA: ", pausa/60, " minutos");
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
        else
        {
            Print("❌ Error cerrando posición ", posiciones[i].ticket, ": ", GetErrorDescription((int)GetLastError()));
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
        Print("🔵 ENTRADA COMPRA | Momento: +", DoubleToString(momentumPips, 1), "p reales");
        AbrirPosicion(ORDER_TYPE_BUY, LoteInicial, ask);
    }
    else if(momentumPips <= -MomentumMinimoPips)
    {
        Print("🔴 ENTRADA VENTA | Momento: ", DoubleToString(momentumPips, 1), "p reales");
        AbrirPosicion(ORDER_TYPE_SELL, LoteInicial, bid);
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
    
    return true;
}

//+------------------------------------------------------------------+
void CrearInterfazCompleta()
{
    int x = 150, y = 80, ancho = 100, alto = 30;
    
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
    
    ObjectCreate(0, "LabelEstadoDS", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "LabelEstadoDS", OBJPROP_XDISTANCE, x - 20);
    ObjectSetInteger(0, "LabelEstadoDS", OBJPROP_YDISTANCE, y + (alto + 10) * 3 + 10);
    ObjectSetInteger(0, "LabelEstadoDS", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "LabelEstadoDS", OBJPROP_COLOR, clrDodgerBlue);
    ObjectSetString(0, "LabelEstadoDS", OBJPROP_TEXT, BotActivo?"DEEPSEEK: ON":"DEEPSEEK: OFF");
    ObjectSetInteger(0, "LabelEstadoDS", OBJPROP_FONTSIZE, 9);
    ObjectSetString(0, "LabelEstadoDS", OBJPROP_FONT, "Arial Bold");
    
    ObjectCreate(0, "LabelInfoDS", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "LabelInfoDS", OBJPROP_XDISTANCE, x - 20);
    ObjectSetInteger(0, "LabelInfoDS", OBJPROP_YDISTANCE, y + (alto + 10) * 3 + 27);
    ObjectSetInteger(0, "LabelInfoDS", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "LabelInfoDS", OBJPROP_COLOR, clrWhite);
    ObjectSetString(0, "LabelInfoDS", OBJPROP_TEXT, "Ops: 0/0 | $0.00");
    ObjectSetInteger(0, "LabelInfoDS", OBJPROP_FONTSIZE, 8);
    
    ObjectCreate(0, "LabelRiesgoDS", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "LabelRiesgoDS", OBJPROP_XDISTANCE, x - 20);
    ObjectSetInteger(0, "LabelRiesgoDS", OBJPROP_YDISTANCE, y + (alto + 10) * 3 + 44);
    ObjectSetInteger(0, "LabelRiesgoDS", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "LabelRiesgoDS", OBJPROP_COLOR, clrYellow);
    ObjectSetString(0, "LabelRiesgoDS", OBJPROP_TEXT, "Día: $0.00 | SL: 0");
    ObjectSetInteger(0, "LabelRiesgoDS", OBJPROP_FONTSIZE, 8);
    
    ObjectCreate(0, "LabelStatsDS", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "LabelStatsDS", OBJPROP_XDISTANCE, x - 20);
    ObjectSetInteger(0, "LabelStatsDS", OBJPROP_YDISTANCE, y + (alto + 10) * 3 + 61);
    ObjectSetInteger(0, "LabelStatsDS", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "LabelStatsDS", OBJPROP_COLOR, clrSilver);
    ObjectSetString(0, "LabelStatsDS", OBJPROP_TEXT, "Ops Hoy: 0/100 | Gan: $0");
    ObjectSetInteger(0, "LabelStatsDS", OBJPROP_FONTSIZE, 7);
    
    ObjectCreate(0, "LabelConfigDS", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "LabelConfigDS", OBJPROP_XDISTANCE, x - 20);
    ObjectSetInteger(0, "LabelConfigDS", OBJPROP_YDISTANCE, y + (alto + 10) * 3 + 78);
    ObjectSetInteger(0, "LabelConfigDS", OBJPROP_CORNER, CORNER_RIGHT_LOWER);
    ObjectSetInteger(0, "LabelConfigDS", OBJPROP_COLOR, clrGray);
    ObjectSetString(0, "LabelConfigDS", OBJPROP_TEXT, "SL: 50p | TP: 25p | Lote: 0.01");
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
    
    string configText = StringFormat("SL: 50p | TP: 25p | BE: $%.1f | Lote: %.2f", 
        MyBEActivacion, LoteInicial);
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
            Print("🚀 DEEPSEEK SEGURA v3.0 ACTIVADA");
            ObjectSetInteger(0, "BtnActivarDS", OBJPROP_STATE, false);
        }
        else if(sparam == "BtnDesactivarDS")
        {
            BotActivo = false;
            Print("⏸️ DEEPSEEK DESACTIVADA");
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
// Función para obtener descripción de errores
string GetErrorDescription(int error)
{
    switch(error)
    {
        case 0:     return "No error";
        case 1:     return "No error, but result unknown";
        case 2:     return "Common error";
        case 3:     return "Invalid trade parameters";
        case 4:     return "Trade server is busy";
        case 5:     return "Old version of the client terminal";
        case 6:     return "No connection with trade server";
        case 7:     return "Not enough rights";
        case 8:     return "Too frequent requests";
        case 9:     return "Malfunctional trade operation";
        case 64:    return "Account disabled";
        case 65:    return "Invalid account";
        case 128:   return "Trade timeout";
        case 129:   return "Invalid price";
        case 130:   return "INVALID STOPS - ¡CRÍTICO!";
        case 131:   return "Invalid trade volume";
        case 132:   return "Market is closed";
        case 133:   return "Trade is disabled";
        case 134:   return "Not enough money";
        case 135:   return "Price changed";
        case 136:   return "No quotes";
        case 137:   return "Broker is busy";
        case 138:   return "Requote";
        case 139:   return "Order is locked";
        case 140:   return "Long positions only allowed";
        case 141:   return "Too many requests";
        case 145:   return "Modification denied because order too close to market";
        case 146:   return "Trade context is busy";
        case 147:   return "Expirations are denied by broker";
        case 148:   return "Too many open and pending orders";
        case 149:   return "Hedging is prohibited";
        case 150:   return "Prohibit closing by opposite order";
        default:    return "Unknown error " + IntegerToString(error);
    }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|         ELITE GOLD MAIKO SNIPER v11.30 | HEDGED S/R CENT         |
//|       "INSTITUTIONAL EDITION" | DUAL BASKET & S/R FILTERS       |
//+------------------------------------------------------------------+
#property copyright "Elite Gold MAIKO Sniper"
#property version   "11.30"
#property strict

#include <Trade\Trade.mqh>

// --- CONFIGURACION ---
input string MiLicencia = "23449251";
input int ExpertMagic = 111224; // Magic Number (Debe ser unico para cada bot en la misma cuenta)
const bool EsCuentaCent = true; // Es Cuenta Cent? (Fijado a true para centavos)

// --- FILTROS ---
input bool UsarFiltroFinDeSemana = true; // Activar Filtro de Fin de Semana (Viernes 18:00 - Domingo 01:00)
input double MaxRangoVelaM1 = 20.0;
input double MaxSpreadPips = 4.0;
input double SensibilidadMechaReal = 3.0;
input int MinutosPausaTrasSusto = 1;

// --- TENDENCIA ---
input int PeriodoMediaFiltro = 50;
input bool CheckM15 = true;
input bool CheckM5 = true;
input double LoteAtaque = 0.02;
input int RuedasAmetralladora = 1;
input double MultiplicadorRefuerzo = 3.0;
input double ProfitNetoFlush = 50.0; // Profit Neto Flush (Centavos, recomendado 50 a 75)
input double ProfitCosechaIndividual = 15.0; // Profit Cosecha Individual (Centavos, recomendado 10 a 15)
input double TargetDiario = 2000.00; // Target Diario (Centavos)
input double DistanciaRefuerzoPips = 30.0;
input double MaxLoteTotal = 0.08;
input double MaxLoteIndividual = 0.04;

// --- FILTRO TECHO Y SUELO ---
input bool UsarFiltroTechoSuelo = true;       // Activar Filtro de Techo y Suelo
input int LookbackH1 = 24;                    // Lookback H1 (Horas para Techo/Suelo)
input int LookbackM15 = 24;                   // Lookback M15 (Velas M15 para Techo/Suelo)
input double MargenFiltroPips = 10.0;         // Margen de seguridad en Pips
input bool DibujarLineasTechoSuelo = true;    // Dibujar líneas en el gráfico

// --- CONFIGURACIÓN COBERTURA ---
input bool PermitirBidireccional = true;      // Permitir operar Compra y Venta simultáneas (Hedging)

// --- COLORES DE LÍNEAS ---
input color ColorTechoDiaAnterior = clrMagenta;
input color ColorSueloDiaAnterior = clrTeal;
input color ColorTechoH1 = clrRed;
input color ColorSueloH1 = clrGreen;
input color ColorTechoM15 = clrOrange;
input color ColorSueloM15 = clrBlue;

// --- SEGURIDAD ---
input double MaxPipsHueco = 50.0;
input int MaxVelasHueco = 5;
input int LimitePosicionesSOS = 4; // Límite de posiciones totales en la cesta (Máx 4)
input double ProfitBreakEven = 5.0; // Profit Break Even (Centavos)
input double ProteccionBeneficioDiario = 0.0; // Proteccion Beneficio Diario (Centavos)

// --- SEGURIDAD SOS RADAR ---
input bool CheckM1RadarEnSOS = true;          // Exigir que M1 esté a favor para SOS
input bool CheckM5RadarEnSOS = false;         // Exigir que M5 esté a favor para SOS

// --- HUD ---
input string HUD_Branding = "MAIKO v11.30 | HEDGED S/R CENT";
input color ColorMain = clrGold;
input color ColorHeader = C'30,30,30';
input color ColorBody = C'20,20,20';
input int HUD_X = 15;
input int PosY_HUD = 25;

input bool ShowW1 = true;
input bool ShowD1 = true;
input bool ShowH4 = true;
input bool ShowH1 = true;
input bool ShowM15 = true;
input bool ShowM5 = true;
input bool ShowM1 = true;

input string TradeComment = "MAIKO_HEDGED_SR_CENT";

// Globales
CTrade trade;
struct PosInfo { ulong ticket; double p; double c; double s; int t; double v; datetime time; double pr; };

PosInfo posBuy[];
PosInfo posSell[];
double flotanteBuy = 0, flotanteSell = 0;
double volBuy = 0, volSell = 0;

double ganadoHoy = 0, flotante = 0, volTotal = 0, spreadActual = 0;
bool BotActivo = false;
bool hudMinimizado = false;
datetime ultimoAtaque = 0;
string txtVoz = "SCHOLAR: Escaneando...";
string txtVeredicto = "ESPERANDO...";
datetime proximoAtaque = 0, pausaVolatilidad = 0;
bool enFaseAnalisis = false;
int hEMA_v = INVALID_HANDLE;
int hRSI_v = INVALID_HANDLE;
int hRadar[7];
ENUM_TIMEFRAMES etfs[]={PERIOD_W1,PERIOD_D1,PERIOD_H4,PERIOD_H1,PERIOD_M15,PERIOD_M5,PERIOD_M1};

double GetHighestHigh(ENUM_TIMEFRAMES tf, int count, int start=1) {
    double high[];
    if(CopyHigh(_Symbol, tf, start, count, high) > 0) {
        int highestIdx = ArrayMaximum(high, 0, count);
        if(highestIdx >= 0) return high[highestIdx];
    }
    return 0;
}

double GetLowestLow(ENUM_TIMEFRAMES tf, int count, int start=1) {
    double low[];
    if(CopyLow(_Symbol, tf, start, count, low) > 0) {
        int lowestIdx = ArrayMinimum(low, 0, count);
        if(lowestIdx >= 0) return low[lowestIdx];
    }
    return 0;
}

void DibujarLineaHorizontal(string nombre, double precio, color col, ENUM_LINE_STYLE estilo, string desc) {
    if(precio <= 0) return;
    if(ObjectFind(0, nombre) < 0) {
        ObjectCreate(0, nombre, OBJ_HLINE, 0, 0, precio);
    } else {
        ObjectMove(0, nombre, 0, 0, precio);
    }
    ObjectSetInteger(0, nombre, OBJPROP_COLOR, col);
    ObjectSetInteger(0, nombre, OBJPROP_STYLE, estilo);
    ObjectSetInteger(0, nombre, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, nombre, OBJPROP_BACK, true);
    ObjectSetString(0, nombre, OBJPROP_TOOLTIP, desc);
}

void ActualizarGraficosTechoSuelo() {
    if(!DibujarLineasTechoSuelo) {
        ObjectsDeleteAll(0, "MAIKO_Line_");
        return;
    }
    double yesterday_high = iHigh(_Symbol, PERIOD_D1, 1);
    double yesterday_low = iLow(_Symbol, PERIOD_D1, 1);
    double h1_techo = GetHighestHigh(PERIOD_H1, LookbackH1, 1);
    double h1_suelo = GetLowestLow(PERIOD_H1, LookbackH1, 1);
    double m15_techo = GetHighestHigh(PERIOD_M15, LookbackM15, 1);
    double m15_suelo = GetLowestLow(PERIOD_M15, LookbackM15, 1);
    
    DibujarLineaHorizontal("MAIKO_Line_TechoDia", yesterday_high, ColorTechoDiaAnterior, STYLE_DASH, "Techo Día Anterior");
    DibujarLineaHorizontal("MAIKO_Line_SueloDia", yesterday_low, ColorSueloDiaAnterior, STYLE_DASH, "Suelo Día Anterior");
    DibujarLineaHorizontal("MAIKO_Line_TechoH1", h1_techo, ColorTechoH1, STYLE_SOLID, "Techo H1 (" + IntegerToString(LookbackH1) + "h)");
    DibujarLineaHorizontal("MAIKO_Line_SueloH1", h1_suelo, ColorSueloH1, STYLE_SOLID, "Suelo H1 (" + IntegerToString(LookbackH1) + "h)");
    DibujarLineaHorizontal("MAIKO_Line_TechoM15", m15_techo, ColorTechoM15, STYLE_DOT, "Techo M15");
    DibujarLineaHorizontal("MAIKO_Line_SueloM15", m15_suelo, ColorSueloM15, STYLE_DOT, "Suelo M15");
}

void AgregarIndicadoresVisuales() {
    bool tieneEMA = false;
    bool tieneRSI = false;
    bool tieneMACD = false;
    int ventanas = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL);
    for(int w = 0; w < ventanas; w++) {
        int totalInd = ChartIndicatorsTotal(0, w);
        for(int i = 0; i < totalInd; i++) {
            string nombre = ChartIndicatorName(0, w, i);
            if(StringFind(nombre, IntegerToString(PeriodoMediaFiltro)) >= 0 && (StringFind(nombre, "MA") >= 0 || StringFind(nombre, "EMA") >= 0)) tieneEMA = true;
            if(StringFind(nombre, "RSI") >= 0 && StringFind(nombre, "14") >= 0) tieneRSI = true;
            if(StringFind(nombre, "MACD") >= 0) tieneMACD = true;
        }
    }
    if(!tieneEMA) ChartIndicatorAdd(0, 0, hEMA_v);
    if(!tieneRSI) ChartIndicatorAdd(0, (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL), hRSI_v);
    if(!tieneMACD) {
        int hMACD = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE);
        if(hMACD != INVALID_HANDLE) ChartIndicatorAdd(0, (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL), hMACD);
    }
}

int OnInit() {
    trade.SetExpertMagicNumber(ExpertMagic);
    trade.SetAsyncMode(true);
    hEMA_v = iMA(_Symbol, _Period, PeriodoMediaFiltro, 0, MODE_EMA, PRICE_CLOSE);
    hRSI_v = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
    
    for(int i=0; i<7; i++) {
        hRadar[i] = iMA(_Symbol, etfs[i], PeriodoMediaFiltro, 0, MODE_EMA, PRICE_CLOSE);
    }
    
    AgregarIndicadoresVisuales();
    CrearInterfazMaster();
    
    // Cargar estado inicial inmediatamente sin esperar al primer tick
    ActualizarEstadoMaster();
    ganadoHoy = CalcularGanadoHoy();
    spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point / 10;
    ActualizarInterfazMaster();
    ActualizarLineasTrade();
    
    if(MQLInfoInteger(MQL_TESTER)) BotActivo = true;
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) { 
    ObjectsDeleteAll(0, "MAIKO_"); 
    for(int i=0; i<7; i++) {
        if(hRadar[i] != INVALID_HANDLE) IndicatorRelease(hRadar[i]);
    }
    if(hEMA_v != INVALID_HANDLE) IndicatorRelease(hEMA_v);
    if(hRSI_v != INVALID_HANDLE) IndicatorRelease(hRSI_v);
    ChartRedraw(); 
}

double CalcularProfit() { return flotanteBuy + flotanteSell; }

double CalcularGanadoHoy() { 
    double total = 0; HistorySelect(iTime(_Symbol, PERIOD_D1, 0), TimeCurrent()); 
    for(int i=HistoryDealsTotal()-1; i>=0; i--) {
        ulong t = HistoryDealGetTicket(i);
        if(HistoryDealGetString(t, DEAL_SYMBOL) == _Symbol) {
            total += (HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_COMMISSION) + HistoryDealGetDouble(t, DEAL_SWAP));
        }
    }
    return total; 
}

void CerrarBasket(int type) {
    int total = (type == POSITION_TYPE_BUY) ? ArraySize(posBuy) : ArraySize(posSell);
    for(int i=total-1; i>=0; i--) {
        ulong ticket = (type == POSITION_TYPE_BUY) ? posBuy[i].ticket : posSell[i].ticket;
        trade.PositionClose(ticket);
    }
}

void CerrarTodo() {
    CerrarBasket(POSITION_TYPE_BUY);
    CerrarBasket(POSITION_TYPE_SELL);
}

void ActualizarEstadoMaster() { 
    ArrayResize(posBuy, 0); ArrayResize(posSell, 0);
    volBuy = 0; volSell = 0;
    flotanteBuy = 0; flotanteSell = 0;
    
    for(int i=PositionsTotal()-1; i>=0; i--) {
        if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == ExpertMagic) { 
            PosInfo p;
            p.ticket = PositionGetTicket(i); 
            p.p = PositionGetDouble(POSITION_PROFIT); 
            p.c = PositionGetDouble(POSITION_COMMISSION); 
            p.s = PositionGetDouble(POSITION_SWAP); 
            p.t = (int)PositionGetInteger(POSITION_TYPE); 
            p.v = PositionGetDouble(POSITION_VOLUME); 
            p.time = (datetime)PositionGetInteger(POSITION_TIME); 
            p.pr = PositionGetDouble(POSITION_PRICE_OPEN); 
            
            if(p.t == POSITION_TYPE_BUY) {
                int idx = ArraySize(posBuy); ArrayResize(posBuy, idx+1);
                posBuy[idx] = p; volBuy += p.v; flotanteBuy += (p.p + p.c + p.s);
            } else {
                int idx = ArraySize(posSell); ArrayResize(posSell, idx+1);
                posSell[idx] = p; volSell += p.v; flotanteSell += (p.p + p.c + p.s);
            }
        } 
    }
    volTotal = volBuy + volSell;
    flotante = flotanteBuy + flotanteSell;
}

double CalcularMetaEscapeTPBasket(int type) {
    int totalPos = (type == POSITION_TYPE_BUY) ? ArraySize(posBuy) : ArraySize(posSell);
    if(totalPos == 0) return 0;
    
    double sumVol = 0;
    double sumPriceVol = 0;
    double sumCommSwap = 0;
    
    for(int i = 0; i < totalPos; i++) {
        PosInfo p = (type == POSITION_TYPE_BUY) ? posBuy[i] : posSell[i];
        sumVol += p.v;
        sumPriceVol += p.pr * p.v;
        sumCommSwap += p.c + p.s;
    }
    
    if(sumVol <= 0) return 0;
    
    double avgPrice = sumPriceVol / sumVol;
    double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    if(contractSize <= 0) contractSize = 100.0;
    
    // En cuenta Cent, inputs ya están en centavos. MT5 también devuelve sumCommSwap en centavos.
    double targetActual = (totalPos >= LimitePosicionesSOS) ? ProfitBreakEven : ProfitNetoFlush;
    
    double targetUSD = (targetActual - sumCommSwap) / 100.0;
    double priceDiff = targetUSD / (sumVol * contractSize);
    
    double tp = (type == POSITION_TYPE_BUY) ? (avgPrice + priceDiff) : (avgPrice - priceDiff);
    return NormalizeDouble(tp, _Digits);
}

void GestionarCosechaSniper() { 
    for(int i=ArraySize(posBuy)-1; i>=0; i--) {
        if((posBuy[i].p + posBuy[i].c + posBuy[i].s) >= ProfitCosechaIndividual) {
            trade.PositionClose(posBuy[i].ticket);
        }
    }
    for(int i=ArraySize(posSell)-1; i>=0; i--) {
        if((posSell[i].p + posSell[i].c + posSell[i].s) >= ProfitCosechaIndividual) {
            trade.PositionClose(posSell[i].ticket);
        }
    }
}

void GestionarRefuerzoCesta(int type) {
    int totalPos = (type == POSITION_TYPE_BUY) ? ArraySize(posBuy) : ArraySize(posSell);
    if(totalPos == 0) return;
    
    PosInfo lastPos = (type == POSITION_TYPE_BUY) ? posBuy[0] : posSell[0];
    double distPips = 0;
    if(type == POSITION_TYPE_BUY) {
        distPips = (lastPos.pr - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point / 10;
    } else {
        distPips = (SymbolInfoDouble(_Symbol, SYMBOL_BID) - lastPos.pr) / _Point / 10;
    }
    string dirStr = (type == POSITION_TYPE_BUY) ? "COMPRA" : "VENTA";
    
    if(distPips < DistanciaRefuerzoPips) {
        return;
    }
    
    // Verificar radar de seguridad en SOS
    if(CheckM1RadarEnSOS || CheckM5RadarEnSOS) {
        double buf[1];
        if(CheckM1RadarEnSOS) {
            if(CopyBuffer(hRadar[6], 0, 0, 1, buf) > 0) { // Radar M1
                double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                bool m1_alcista = (bid > buf[0]);
                if(type == POSITION_TYPE_BUY && !m1_alcista) {
                    txtVeredicto = "SOS COMPRA ESPERA: M1 BAJISTA EN RADAR";
                    return;
                }
                if(type == POSITION_TYPE_SELL && m1_alcista) {
                    txtVeredicto = "SOS VENTA ESPERA: M1 ALCISTA EN RADAR";
                    return;
                }
            }
        }
        if(CheckM5RadarEnSOS) {
            if(CopyBuffer(hRadar[5], 0, 0, 1, buf) > 0) { // Radar M5
                double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                bool m5_alcista = (bid > buf[0]);
                if(type == POSITION_TYPE_BUY && !m5_alcista) {
                    txtVeredicto = "SOS COMPRA ESPERA: M5 BAJISTA EN RADAR";
                    return;
                }
                if(type == POSITION_TYPE_SELL && m5_alcista) {
                    txtVeredicto = "SOS VENTA ESPERA: M5 ALCISTA EN RADAR";
                    return;
                }
            }
        }
    }
    
    bool forzar = (distPips >= MaxPipsHueco) || (iBarShift(_Symbol, PERIOD_M1, lastPos.time) >= MaxVelasHueco);
    bool velaGiro = (type == POSITION_TYPE_BUY) ? 
                    (iClose(_Symbol, PERIOD_M1, 1) > iOpen(_Symbol, PERIOD_M1, 1) && iClose(_Symbol, PERIOD_M1, 2) > iOpen(_Symbol, PERIOD_M1, 2)) : 
                    (iClose(_Symbol, PERIOD_M1, 1) < iOpen(_Symbol, PERIOD_M1, 1) && iClose(_Symbol, PERIOD_M1, 2) < iOpen(_Symbol, PERIOD_M1, 2));
    
    if(!velaGiro && !forzar) {
        txtVeredicto = StringFormat("ZONA SOS %s | ESPERANDO 2 VELAS GIRO M1 (Pips: %.1f)", dirStr, distPips);
        return;
    }
    
    double volLado = 0;
    for(int i=0; i<totalPos; i++) {
        PosInfo p = (type == POSITION_TYPE_BUY) ? posBuy[i] : posSell[i];
        volLado += p.v;
    }
    
    double volRefuerzo = NormalizeDouble(volLado * (MultiplicadorRefuerzo - 1.0), 2);
    if(volRefuerzo < 0.01) volRefuerzo = 0.01;
    if(volRefuerzo > MaxLoteIndividual) volRefuerzo = MaxLoteIndividual;
    if(volTotal + volRefuerzo > MaxLoteTotal) { txtVoz = "LIMITE LOTE ALCANZADO"; return; }
    
    if(TimeCurrent() - ultimoAtaque < 3) return;
    if(type == POSITION_TYPE_BUY) trade.Buy(volRefuerzo, _Symbol, 0, 0, 0, TradeComment + "_SOS"); 
    else trade.Sell(volRefuerzo, _Symbol, 0, 0, 0, TradeComment + "_SOS");
    ultimoAtaque = TimeCurrent();
    txtVeredicto = StringFormat("DISPARO SOS %s RESCATE EJECUTADO 🛡️⚡", dirStr);
}

void OnTick() {
    ActualizarEstadoMaster();
    ganadoHoy = CalcularGanadoHoy();
    spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point / 10;
    
    // Verificar cierres globales/cesta (inputs ya en centavos)
    if(ArraySize(posBuy) > 0) {
        double targetBuy = (ArraySize(posBuy) >= LimitePosicionesSOS) ? ProfitBreakEven : ProfitNetoFlush;
        if(flotanteBuy >= targetBuy) {
            txtVoz = "CIERRE COMPRAS ALCANZADO."; CerrarBasket(POSITION_TYPE_BUY); ActualizarEstadoMaster();
        }
    }
    
    if(ArraySize(posSell) > 0) {
        double targetSell = (ArraySize(posSell) >= LimitePosicionesSOS) ? ProfitBreakEven : ProfitNetoFlush;
        if(flotanteSell >= targetSell) {
            txtVoz = "CIERRE VENTAS ALCANZADO."; CerrarBasket(POSITION_TYPE_SELL); ActualizarEstadoMaster();
        }
    }
    
    if(ganadoHoy >= TargetDiario) {
        txtVoz = "OBJETIVO DIARIO CUMPLIDO."; CerrarTodo(); BotActivo = false; ActualizarInterfazMaster(); return;
    }
    if(ProteccionBeneficioDiario > 0.0 && ganadoHoy > ProteccionBeneficioDiario) {
        if((ganadoHoy + flotante) <= ProteccionBeneficioDiario && (ArraySize(posBuy) > 0 || ArraySize(posSell) > 0)) {
            txtVoz = "PROTECCION BENEFICIO."; CerrarTodo(); BotActivo = false; ActualizarInterfazMaster(); return;
        }
    }

    GestionarCosechaSniper(); 
    ActualizarRadarMaster(); 
    
    static datetime lastSRTime = 0;
    datetime currentM1BarTime = iTime(_Symbol, PERIOD_M1, 0);
    if(currentM1BarTime != lastSRTime) {
        lastSRTime = currentM1BarTime;
        ActualizarGraficosTechoSuelo();
    }
    
    ActualizarInterfazMaster();
    ActualizarLineasTrade();

    if(ArraySize(posBuy) > 0 && ArraySize(posSell) > 0) {
        txtVoz = "MAIKO: Cobertura Dual Activa...";
    } else if(ArraySize(posBuy) > 0) {
        txtVoz = "MAIKO: Vigilando COMPRA activo...";
    } else if(ArraySize(posSell) > 0) {
        txtVoz = "MAIKO: Vigilando VENTA activo...";
    }

    if(!BotActivo) return;
    
    if(ArraySize(posBuy) > 0) GestionarRefuerzoCesta(POSITION_TYPE_BUY);
    if(ArraySize(posSell) > 0) GestionarRefuerzoCesta(POSITION_TYPE_SELL);
    
    bool tieneCompras = (ArraySize(posBuy) > 0);
    bool tieneVentas = (ArraySize(posSell) > 0);
    bool permitirEntrarBuy = !tieneCompras && (PermitirBidireccional || !tieneVentas);
    bool permitirEntrarSell = !tieneVentas && (PermitirBidireccional || !tieneCompras);
    
    if(permitirEntrarBuy || permitirEntrarSell) {
        if(ArraySize(posBuy) == 0 && ArraySize(posSell) == 0) {
            string razonFinDeSemana = "";
            if(!CheckHorarioFinDeSemana(razonFinDeSemana)) {
                txtVeredicto = razonFinDeSemana;
                enFaseAnalisis = false;
                return;
            }
            if(!enFaseAnalisis) { enFaseAnalisis = true; proximoAtaque = TimeCurrent() + 60; txtVoz = "SCHOLAR: Buscando..."; }
        } else {
            enFaseAnalisis = true; proximoAtaque = TimeCurrent(); // Entradas secundarias directas si hay señal
        }
        if(TimeCurrent() >= proximoAtaque && TimeCurrent() >= pausaVolatilidad) {
            string d = "";
            if(ValidarEstructuraScholar(d)) {
                if(d == "BUY" && permitirEntrarBuy) { EjecutarAtaqueScholar("BUY"); enFaseAnalisis = false; }
                else if(d == "SELL" && permitirEntrarSell) { EjecutarAtaqueScholar("SELL"); enFaseAnalisis = false; }
            }
        }
    } else {
        enFaseAnalisis = false;
    }
}

//+------------------------------------------------------------------+
//| Filtro de Fin de Semana                                          |
//+------------------------------------------------------------------+
bool CheckHorarioFinDeSemana(string &razon) {
    if(!UsarFiltroFinDeSemana) return true;
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    // Viernes a partir de las 18:00
    if(dt.day_of_week == 5 && dt.hour >= 18) { 
        razon = "PAUSA FIN DE SEMANA (VIERNES > 18:00)"; 
        return false; 
    }
    // Sábado todo el día
    if(dt.day_of_week == 6) { 
        razon = "PAUSA FIN DE SEMANA (SABADO)"; 
        return false; 
    }
    // Domingo antes de las 01:00 AM
    if(dt.day_of_week == 0 && dt.hour < 1) { 
        razon = "PAUSA FIN DE SEMANA (DOMINGO < 01:00)"; 
        return false; 
    }
    return true;
}

//+------------------------------------------------------------------+
//| Filtro de Techo y Suelo con confirmacion de ruptura de 2 velas   |
//+------------------------------------------------------------------+
bool CheckTechoSueloFiltros(string direction, string &razon) {
    if(!UsarFiltroTechoSuelo) return true;
    
    double yesterday_high = iHigh(_Symbol, PERIOD_D1, 1);
    double yesterday_low = iLow(_Symbol, PERIOD_D1, 1);
    double h1_techo = GetHighestHigh(PERIOD_H1, LookbackH1, 1);
    double h1_suelo = GetLowestLow(PERIOD_H1, LookbackH1, 1);
    double m15_techo = GetHighestHigh(PERIOD_M15, LookbackM15, 1);
    double m15_suelo = GetLowestLow(PERIOD_M15, LookbackM15, 1);
    
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double price = (direction == "BUY") ? ask : bid;
    
    double techos[] = {yesterday_high, h1_techo, m15_techo};
    string nameTechos[] = {"D1", "H1", "M15"};
    double suelos[] = {yesterday_low, h1_suelo, m15_suelo};
    string nameSuelos[] = {"D1", "H1", "M15"};
    
    // 1. Bloqueo por cercania a techos (por debajo del techo en la zona de margen)
    for(int i=0; i<3; i++) {
        if(techos[i] <= 0) continue;
        double distPips = (techos[i] - price) / _Point / 10;
        if(distPips >= 0 && distPips < MargenFiltroPips) {
            razon = StringFormat("ZONA RIESGO TECHO %s (A %.1f Pips)", nameTechos[i], distPips);
            return false;
        }
    }
    
    // 2. Bloqueo por cercania a suelos (por encima del suelo en la zona de margen)
    for(int i=0; i<3; i++) {
        if(suelos[i] <= 0) continue;
        double distPips = (price - suelos[i]) / _Point / 10;
        if(distPips >= 0 && distPips < MargenFiltroPips) {
            razon = StringFormat("ZONA RIESGO SUELO %s (A %.1f Pips)", nameSuelos[i], distPips);
            return false;
        }
    }
    
    // 3. Confirmacion de ruptura de techo para COMPRA
    if(direction == "BUY") {
        for(int i=0; i<3; i++) {
            if(techos[i] <= 0) continue;
            if(price >= techos[i]) {
                double c1 = iClose(_Symbol, PERIOD_M1, 1);
                double c2 = iClose(_Symbol, PERIOD_M1, 2);
                if(c1 < techos[i] || c2 < techos[i]) {
                    razon = StringFormat("ESPERANDO RUPTURA TECHO %s (2 Velas M1)", nameTechos[i]);
                    return false;
                }
            }
        }
    }
    
    // 4. Confirmacion de ruptura de suelo para VENTA
    if(direction == "SELL") {
        for(int i=0; i<3; i++) {
            if(suelos[i] <= 0) continue;
            if(price <= suelos[i]) {
                double c1 = iClose(_Symbol, PERIOD_M1, 1);
                double c2 = iClose(_Symbol, PERIOD_M1, 2);
                if(c1 > suelos[i] || c2 > suelos[i]) {
                    razon = StringFormat("ESPERANDO RUPTURA SUELO %s (2 Velas M1)", nameSuelos[i]);
                    return false;
                }
            }
        }
    }
    
    return true;
}

bool ValidarEstructuraScholar(string &decision) {
    if(spreadActual > MaxSpreadPips) { txtVeredicto = "SPD ALTO: " + DoubleToString(spreadActual,1); return false; }
    double rangoM1 = (iHigh(_Symbol, PERIOD_M1, 1) - iLow(_Symbol, PERIOD_M1, 1)) / _Point / 10;
    if(rangoM1 > MaxRangoVelaM1) {
        txtVeredicto = "VOLATILIDAD ALTA (ESPERANDO)"; pausaVolatilidad = TimeCurrent() + (60 * MinutosPausaTrasSusto); return false;
    }
    double body = MathAbs(iOpen(_Symbol, PERIOD_M1, 1) - iClose(_Symbol, PERIOD_M1, 1)) / _Point / 10;
    if(body < 0.5) { txtVeredicto = "MERCADO ESTANCADO (POCA LUZ)"; return false; }

    double upperWick = (iHigh(_Symbol, PERIOD_M1, 1) - MathMax(iOpen(_Symbol, PERIOD_M1, 1), iClose(_Symbol, PERIOD_M1, 1))) / _Point / 10;
    double lowerWick = (MathMin(iOpen(_Symbol, PERIOD_M1, 1), iClose(_Symbol, PERIOD_M1, 1)) - iLow(_Symbol, PERIOD_M1, 1)) / _Point / 10;
    
    double ema[1];
    if(CopyBuffer(hEMA_v, 0, 1, 1, ema) <= 0) {
        txtVeredicto = "ESPERANDO HISTORIAL EMA...";
        return false;
    }
    
    double precio = iClose(_Symbol, PERIOD_M1, 1); bool porEncima = (precio > ema[0]);
    
    if(porEncima && upperWick > (body * SensibilidadMechaReal) && upperWick > 3.0) { txtVeredicto = "RECHAZO ALCISTA (MECHA ALTA)"; return false; }
    if(!porEncima && lowerWick > (body * SensibilidadMechaReal) && lowerWick > 3.0) { txtVeredicto = "RECHAZO BAJISTA (MECHA BAJA)"; return false; }
    
    double rsi[1];
    if(CopyBuffer(hRSI_v, 0, 1, 1, rsi) <= 0) {
        txtVeredicto = "ESPERANDO HISTORIAL RSI...";
        return false;
    }
    
    bool rsiOK = (porEncima ? (rsi[0] > 50) : (rsi[0] < 50));
    if(!rsiOK) {
        txtVeredicto = StringFormat("P:%.2f EMA:%.2f RSI:%.1f | %s", precio, ema[0], rsi[0], (porEncima ? "RSI > 50 REQ" : "RSI < 50 REQ"));
        return false;
    }

    double c15 = iClose(_Symbol, PERIOD_M15, 1), o15 = iOpen(_Symbol, PERIOD_M15, 1);
    double c5 = iClose(_Symbol, PERIOD_M5, 1), o5 = iOpen(_Symbol, PERIOD_M5, 1);
    bool m15_ok = !CheckM15 || (porEncima ? c15 > o15 : c15 < o15);
    bool m5_ok = !CheckM5 || (porEncima ? c5 > o5 : c5 < o5);
    
    if(!m15_ok) { txtVeredicto = StringFormat("M15 EN CONTRA (C:%.2f O:%.2f)", c15, o15); return false; }
    if(!m5_ok) { txtVeredicto = StringFormat("M5 EN CONTRA (C:%.2f O:%.2f)", c5, o5); return false; }

    if(UsarFiltroTechoSuelo) {
        string d = porEncima ? "BUY" : "SELL";
        string razon = "";
        if(!CheckTechoSueloFiltros(d, razon)) {
            txtVeredicto = razon;
            return false;
        }
    }

    decision = (porEncima ? "BUY" : "SELL"); 
    txtVeredicto = "ESTRUCTURA CONFIRMADA";
    return true;
}

void EjecutarAtaqueScholar(string d) {
    if(TimeCurrent() - ultimoAtaque < 3) return;
    if(volTotal + (LoteAtaque * RuedasAmetralladora) > MaxLoteTotal) return;
    for(int i=0; i<RuedasAmetralladora; i++) { 
        if(d == "BUY") trade.Buy(LoteAtaque,_Symbol,0,0,0,TradeComment); 
        else trade.Sell(LoteAtaque,_Symbol,0,0,0,TradeComment); 
        Sleep(100); 
    }
    ultimoAtaque = TimeCurrent();
    enFaseAnalisis = false;
}

void ActualizarRadarMaster() { 
    string tfs[]={"W1","D1","H4","H1","M15","M5","M1"}; 
    double pr = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    for(int i=0; i<7; i++) { 
        double buf[1]; color col = clrGray; 
        if(CopyBuffer(hRadar[i], 0, 0, 1, buf) > 0) {
            col = (pr > buf[0]) ? clrSpringGreen : clrRed;
        }
        ObjectSetInteger(0, "MAIKO_Radar_"+tfs[i], OBJPROP_COLOR, col); 
    } 
}

void CrearInterfazMaster() { 
    int x = HUD_X, y = PosY_HUD, w = 400, h = 280; 
    CrearBoton("MAIKO_Bg", x, y, w, h, "", ColorBody, clrNONE, CORNER_LEFT_UPPER); 
    CrearBoton("MAIKO_Head", x, y, w, 35, "", ColorHeader, clrNONE, CORNER_LEFT_UPPER); 
    CrearLabel("MAIKO_T", x+10, y+10, HUD_Branding, ColorMain, 11, CORNER_LEFT_UPPER); 
    CrearBoton("MAIKO_BtnMin", x+w-30, y+7, 22, 22, "_", ColorBody, clrWhite, CORNER_LEFT_UPPER); 
    
    string tfs[]={"W1","D1","H4","H1","M15","M5","M1"}; 
    for(int i=0; i<7; i++) { 
        int px = x + 10 + (i * 55); 
        CrearLabel("MAIKO_L_"+tfs[i], px, y+45, tfs[i]+":", clrWhite, 8, CORNER_LEFT_UPPER); 
        CrearLabel("MAIKO_Radar_"+tfs[i], px+25, y+45, "o", clrGray, 10, CORNER_LEFT_UPPER); 
    } 
    
    CrearLabel("MAIKO_Vered", x+10, y+85, txtVeredicto, clrCyan, 9, CORNER_LEFT_UPPER); 
    CrearLabel("MAIKO_Hoy", x+10, y+125, "GANADO HOY: $0.00", clrSpringGreen, 14, CORNER_LEFT_UPPER); 
    CrearLabel("MAIKO_Flot", x+10, y+160, "FLOTANTE: $0.00", clrWhite, 12, CORNER_LEFT_UPPER); 
    CrearLabel("MAIKO_MetaTP", x+10, y+190, " ", clrYellow, 10, CORNER_LEFT_UPPER); 
    CrearLabel("MAIKO_Spd", x+w-120, y+65, "SPD: 0.0", clrWhite, 8, CORNER_LEFT_UPPER);  
    
    CrearBoton("MAIKO_Foot", x, y+h-40, w, 40, "", ColorHeader, clrNONE, CORNER_LEFT_UPPER); 
    CrearLabel("MAIKO_Voz", x+10, y+h-25, txtVoz, ColorMain, 10, CORNER_LEFT_UPPER); 
    CrearBoton("MAIKO_BtnP", x+w-120, y+110, 110, 50, "ENCENDER", clrDarkGreen, clrWhite, CORNER_LEFT_UPPER); 
    CrearBoton("MAIKO_BtnC", x+w-120, y+175, 110, 35, "CERRAR", clrDarkRed, clrWhite, CORNER_LEFT_UPPER); 
}

void ActualizarInterfazMaster() { 
    // En el HUD de la versión Cent dividimos siempre por 100.0 para mostrar el valor equivalente en dólares.
    ObjectSetString(0, "MAIKO_Hoy", OBJPROP_TEXT, StringFormat("GANADO HOY: $%.2f", ganadoHoy / 100.0)); 
    ObjectSetString(0, "MAIKO_Flot", OBJPROP_TEXT, StringFormat("FLOTANTE: $%.2f", flotante / 100.0)); 
    ObjectSetString(0, "MAIKO_Spd", OBJPROP_TEXT, StringFormat("SPD: %.1f", spreadActual)); 
    ObjectSetInteger(0, "MAIKO_Flot", OBJPROP_COLOR, flotante >= 0 ? clrSpringGreen : clrRed); 
    ObjectSetString(0, "MAIKO_Vered", OBJPROP_TEXT, txtVeredicto); 
    ObjectSetString(0, "MAIKO_Voz", OBJPROP_TEXT, txtVoz); 
    ObjectSetString(0, "MAIKO_BtnP", OBJPROP_TEXT, BotActivo ? "APAGAR" : "ENCENDER"); 
    ObjectSetInteger(0, "MAIKO_BtnP", OBJPROP_BGCOLOR, BotActivo ? clrMaroon : clrDarkGreen); 
    
    double tpBuy = CalcularMetaEscapeTPBasket(POSITION_TYPE_BUY);
    double tpSell = CalcularMetaEscapeTPBasket(POSITION_TYPE_SELL);
    
    if(ArraySize(posBuy) > 0 && ArraySize(posSell) > 0) {
        ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, StringFormat("TP BUY: %.2f | TP SELL: %.2f", tpBuy, tpSell));
    } else if(ArraySize(posBuy) > 0) {
        ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, StringFormat("ESCAPE TP BUY: %.2f", tpBuy));
    } else if(ArraySize(posSell) > 0) {
        ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, StringFormat("ESCAPE TP SELL: %.2f", tpSell));
    } else {
        string razonFinDeSemana = "";
        if(!BotActivo) {
            ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, "ESTADO: BOT APAGADO (INACTIVO)");
        } else if(!CheckHorarioFinDeSemana(razonFinDeSemana)) {
            ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, "ESTADO: " + razonFinDeSemana);
        } else if(TimeCurrent() < pausaVolatilidad) {
            int seg = (int)(pausaVolatilidad - TimeCurrent());
            ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, StringFormat("FILTRO: PAUSA VOLATILIDAD ALTA (%ds)", seg));
        } else if(TimeCurrent() < proximoAtaque) {
            int seg = (int)(proximoAtaque - TimeCurrent());
            ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, StringFormat("FILTRO: PAUSA DE SEGURIDAD (%ds)", seg));
        } else {
            ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, "ESTADO: BUSCANDO ENTRADA EN M1...");
        }
    }
    
    static datetime lastFrontTime = 0;
    datetime now = TimeLocal();
    if(now - lastFrontTime >= 10) {
        lastFrontTime = now;
        string objs[] = {"MAIKO_Bg", "MAIKO_Head", "MAIKO_T", "MAIKO_BtnMin", 
                         "MAIKO_Vered", "MAIKO_Hoy", "MAIKO_Flot", "MAIKO_Spd", 
                         "MAIKO_Foot", "MAIKO_Voz", "MAIKO_BtnP", "MAIKO_BtnC", "MAIKO_MetaTP"};
        int total = ArraySize(objs);
        for(int i = 0; i < total; i++) {
            long current_tf = ObjectGetInteger(0, objs[i], OBJPROP_TIMEFRAMES);
            if(current_tf != OBJ_NO_PERIODS) {
                ObjectSetInteger(0, objs[i], OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
                ObjectSetInteger(0, objs[i], OBJPROP_TIMEFRAMES, current_tf);
            }
        }
        
        string tfs[]={"W1","D1","H4","H1","M15","M5","M1"}; 
        for(int i=0; i<7; i++) { 
            string o1 = "MAIKO_L_"+tfs[i];
            string o2 = "MAIKO_Radar_"+tfs[i];
            long tf1 = ObjectGetInteger(0, o1, OBJPROP_TIMEFRAMES);
            long tf2 = ObjectGetInteger(0, o2, OBJPROP_TIMEFRAMES);
            if(tf1 != OBJ_NO_PERIODS) {
                ObjectSetInteger(0, o1, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
                ObjectSetInteger(0, o1, OBJPROP_TIMEFRAMES, tf1);
            }
            if(tf2 != OBJ_NO_PERIODS) {
                ObjectSetInteger(0, o2, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
                ObjectSetInteger(0, o2, OBJPROP_TIMEFRAMES, tf2);
            }
        }
    }
    ChartRedraw(); 
}

//+------------------------------------------------------------------+
//| Dibujar líneas de precios medios y Take Profits en el gráfico   |
//+------------------------------------------------------------------+
void ActualizarLineasTrade() {
    double avgBuy = 0, avgSell = 0;
    double tpBuy = CalcularMetaEscapeTPBasket(POSITION_TYPE_BUY);
    double tpSell = CalcularMetaEscapeTPBasket(POSITION_TYPE_SELL);
    
    // Calcular precio promedio Compra
    if(ArraySize(posBuy) > 0) {
        double sumVol = 0, sumPriceVol = 0;
        for(int i=0; i<ArraySize(posBuy); i++) {
            sumVol += posBuy[i].v;
            sumPriceVol += posBuy[i].pr * posBuy[i].v;
        }
        if(sumVol > 0) avgBuy = sumPriceVol / sumVol;
    }
    
    // Calcular precio promedio Venta
    if(ArraySize(posSell) > 0) {
        double sumVol = 0, sumPriceVol = 0;
        for(int i=0; i<ArraySize(posSell); i++) {
            sumVol += posSell[i].v;
            sumPriceVol += posSell[i].pr * posSell[i].v;
        }
        if(sumVol > 0) avgSell = sumPriceVol / sumVol;
    }
    
    // Dibujar / mover / borrar líneas
    if(avgBuy > 0) {
        DibujarLineaHorizontal("MAIKO_Trade_AvgBuy", avgBuy, clrDodgerBlue, STYLE_DASHDOT, "Precio Medio COMPRA");
    } else {
        ObjectDelete(0, "MAIKO_Trade_AvgBuy");
    }
    
    if(tpBuy > 0) {
        DibujarLineaHorizontal("MAIKO_Trade_TPBuy", tpBuy, clrLime, STYLE_DASH, "Take Profit COMPRAS");
    } else {
        ObjectDelete(0, "MAIKO_Trade_TPBuy");
    }
    
    if(avgSell > 0) {
        DibujarLineaHorizontal("MAIKO_Trade_AvgSell", avgSell, clrOrangeRed, STYLE_DASHDOT, "Precio Medio VENTA");
    } else {
        ObjectDelete(0, "MAIKO_Trade_AvgSell");
    }
    
    if(tpSell > 0) {
        DibujarLineaHorizontal("MAIKO_Trade_TPSell", tpSell, clrCrimson, STYLE_DASH, "Take Profit VENTAS");
    } else {
        ObjectDelete(0, "MAIKO_Trade_TPSell");
    }
}

void CrearBoton(string n, int x, int y, int w, int h, string t, color bg, color fg, ENUM_BASE_CORNER c) { 
    ObjectCreate(0, n, OBJ_BUTTON, 0, 0, 0); 
    ObjectSetInteger(0, n, OBJPROP_CORNER, c); 
    ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y); 
    ObjectSetInteger(0, n, OBJPROP_XSIZE, w); ObjectSetInteger(0, n, OBJPROP_YSIZE, h); 
    ObjectSetInteger(0, n, OBJPROP_BGCOLOR, bg); ObjectSetInteger(0, n, OBJPROP_COLOR, fg); 
    ObjectSetString(0, n, OBJPROP_TEXT, t); ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false); 
    ObjectSetInteger(0, n, OBJPROP_BACK, false); ObjectSetInteger(0, n, OBJPROP_ZORDER, 100); 
}

void CrearLabel(string n, int x, int y, string t, color col, int s, ENUM_BASE_CORNER c) { 
    ObjectCreate(0, n, OBJ_LABEL, 0, 0, 0); 
    ObjectSetInteger(0, n, OBJPROP_CORNER, c); 
    ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y); 
    ObjectSetString(0, n, OBJPROP_TEXT, t); ObjectSetInteger(0, n, OBJPROP_COLOR, col); 
    ObjectSetInteger(0, n, OBJPROP_FONTSIZE, s); ObjectSetInteger(0, n, OBJPROP_BACK, false); 
    ObjectSetInteger(0, n, OBJPROP_ZORDER, 101); 
}

void ToggleHUD() { 
    hudMinimizado = !hudMinimizado; 
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_YSIZE, hudMinimizado ? 35 : 280); 
    ObjectSetString(0, "MAIKO_BtnMin", OBJPROP_TEXT, hudMinimizado ? "+" : "_"); 
    long tf = hudMinimizado ? OBJ_NO_PERIODS : OBJ_ALL_PERIODS; 
    string objs[] = {"MAIKO_Vered", "MAIKO_Hoy", "MAIKO_Flot", "MAIKO_Spd", "MAIKO_Foot", "MAIKO_Voz", "MAIKO_BtnP", "MAIKO_BtnC", "MAIKO_MetaTP"}; 
    for(int i=0; i<9; i++) ObjectSetInteger(0, objs[i], OBJPROP_TIMEFRAMES, tf); 
    string tfs[]={"W1","D1","H4","H1","M15","M5","M1"}; 
    for(int i=0; i<7; i++) { 
        ObjectSetInteger(0, "MAIKO_L_"+tfs[i], OBJPROP_TIMEFRAMES, tf); 
        ObjectSetInteger(0, "MAIKO_Radar_"+tfs[i], OBJPROP_TIMEFRAMES, tf); 
    } 
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) { 
    if(id == CHARTEVENT_OBJECT_CLICK) { 
        if(sparam == "MAIKO_BtnP") {
            BotActivo = !BotActivo; 
            ActualizarInterfazMaster();
        }
        if(sparam == "MAIKO_BtnC") { 
            CerrarTodo(); 
            enFaseAnalisis = false; 
            ActualizarInterfazMaster();
        } 
        if(sparam == "MAIKO_BtnMin") { ToggleHUD(); ObjectSetInteger(0, sparam, OBJPROP_STATE, false); } 
        ChartRedraw(); 
    } 
}

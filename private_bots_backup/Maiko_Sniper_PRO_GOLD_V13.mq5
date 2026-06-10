//+------------------------------------------------------------------+
//|                MAIKO SNIPER PRO | EDITION REAL CENT             |
//|      "BUTTON FIX & SOFT RECOVERY" | VERSION 11.99 FINAL         |
//+------------------------------------------------------------------+
#property copyright "Elite Gold MAIKO Sniper"
#property version   "11.99"
#property strict

#include <Trade\Trade.mqh>

// --- CONFIGURACION ---
input string MiLicencia = "23449251"; 
input bool CUENTA_REAL_CENT = false; 
input datetime FechaInicioMaiko = D'2026.05.07 00:00'; 

// --- FILTROS DE TENDENCIA ---
input int PeriodoEMA = 50;
input bool CheckH1 = true;
input bool CheckM15 = true;
input bool CheckM5 = true;
input bool UsarMACD = true;

// --- FILTROS SNIPER ---
input double MinCuerpoVelaPips = 1.0; 
input double MaxSpreadPips = 4.0; 
input int RSI_Periodo = 14;

// --- GESTION DE LOTAJE ---
input double LotajeInicial = 0.01; // Lote Inicial
input double MultiplicadorRefuerzo = 1.0; 
input double MaxLoteIndividual = 0.0; // Lote fijo por SOS (0 = usar multiplicador)
input double MaxLoteTotal = 0.45; 
input int LimitePosicionesSOS = 4; // Limite de Operaciones SOS

// --- HORARIO DE SESION ---
input bool UsarFiltroHorario = false; // Activar Filtro Horario de Sesion
input int HoraInicioSesion = 9;       // Hora de inicio de sesion (09:00)
input int HoraFinSesion = 22;         // Hora de fin de sesion (22:00)
input bool BloquearViernesNoche = true; // Evitar Nuevas Entradas Viernes Noche (Recomendado)
input bool CerrarViernesNoche = false; // Cierre forzado Viernes Noche (Fin de semana)
input int HoraCierreViernes = 21;     // Hora limite los viernes (21:00)

// --- FILTRO DE NOTICIAS (CALENDARIO NATIVO MT5) ---
input bool UsarFiltroNoticias = true; // Activar Filtro de Noticias (Alta Importancia EEUU)
input int MinutosAntesNoticia = 30;   // Pausar entradas X minutos ANTES
input int MinutosDespuesNoticia = 30; // Pausar entradas X minutos DESPUES

// --- FILTRO DE SOPORTES Y RESISTENCIAS ---
input bool UsarFiltroSR = true; // Activar Filtro Suelos/Techos (M15, H1, H4, D1)
input double DistanciaPeligroPips = 15.0; // Distancia de peligro a un S/R (Pips)

// --- FILTRO DE FIBONACCI INSTITUCIONAL ---
input bool UsarFiltroFibo = true; // Activar Filtro Fibonacci (M15, H1, H4)

// --- OBJETIVOS DE PROFIT ---
input double ProfitCosechaCents = 3.0; // Ganancia en Dolares (Operacion Individual)
input double ProfitNetoCents = 5.0; // Ganancia en Dolares (Operacion Colectiva SOS)
input double DistanciaRefuerzoPips = 70.0; // Distancia de Refuerzo (Puntos)

// --- PROTECCION DE EQUIDAD (STOP LOSS MAXIMO) ---
input bool InpUsarProteccionEquidad = true; // Activar el Stop Loss del % de la cuenta
input double InpMaxDrawdownPorcentaje = 50.0; // % de pérdida máxima permitida (ej: 50.0)

// --- HUD ---
input color ColorMain = clrGold;
input color ColorHeader = C'30,30,30';
input color ColorBody = C'15,15,15';
input int HUD_X = 15;
input int PosY_HUD = 25;
input string TradeComment = "MAIKO_GOLD_V13";

// Globales
CTrade trade;
input int ExpertMagic = 888777; // Magic Number
struct PosInfo { ulong ticket; double p; int t; double v; double pr; double tp; };
PosInfo pos[];
double ganadoPeriodo = 0, flotante = 0, volTotal = 0, spreadActual = 0, rsiActual = 0, macdActual = 0;
double adxActual = 0, emaActual = 0;
string txtVeredicto = "ANALIZANDO...", txtVoz = "INICIANDO...", txtAnalisisVela = "";
int direccion = 0; // 1 = Compra, -1 = Venta, 0 = Neutro
bool condBuy = false, condSell = false;
datetime ultimoSOS = 0;
bool BotActivo = true;
bool hudMinimizado = false;
int idxPeriodo = 0;

// Variables V13
bool bloqueadoPorNoticia = false;
int minutosParaNoticia = 0;
bool bloqueadoPorSR = false;
string srPeligro = "";
string fiboPeligro = "";
string fiboEstado = "FIBO: SIN IMPULSO CLARO";

int hEMA_H1, hEMA_M15, hEMA_M5, hRSI, hMACD, hADX;
int hRadar[7];
ENUM_TIMEFRAMES etfs[]={PERIOD_W1,PERIOD_D1,PERIOD_H4,PERIOD_H1,PERIOD_M15,PERIOD_M5,PERIOD_M1};
string labelPeriodo[] = {"HOY (NETO)", "ESTA SEMANA", "ESTE MES", "MAIKO PROFIT"};

int OnInit() {
    ObjectsDeleteAll(0, "MAIKO_");
    trade.SetExpertMagicNumber(ExpertMagic);
    hEMA_H1 = iMA(_Symbol, PERIOD_H1, PeriodoEMA, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_M15 = iMA(_Symbol, PERIOD_M15, PeriodoEMA, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_M5 = iMA(_Symbol, PERIOD_M5, PeriodoEMA, 0, MODE_EMA, PRICE_CLOSE);
    hRSI = iRSI(_Symbol, PERIOD_M5, 14, PRICE_CLOSE); // RSI en M5
    hMACD = iMACD(_Symbol, PERIOD_M15, 12, 26, 9, PRICE_CLOSE); // MACD en M15
    hADX = iADX(_Symbol, PERIOD_M15, 14); // ADX en M15
    for(int i=0; i<7; i++) hRadar[i] = iMA(_Symbol, etfs[i], PeriodoEMA, 0, MODE_EMA, PRICE_CLOSE);
    ChartSetInteger(0, CHART_SHOW_TRADE_HISTORY, true);
    ChartSetInteger(0, CHART_FOREGROUND, false);
    CrearInterfazMaster();
    EventSetTimer(1); // Actualizar interfaz cada segundo (útil en mercados cerrados)
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) { 
    ObjectsDeleteAll(0, "MAIKO_"); 
    EventKillTimer(); 
}

int AnalizarPatronPriceAction(ENUM_TIMEFRAMES tf, int shift) {
    double open[1], close[1];
    if(CopyOpen(_Symbol, tf, shift, 1, open) <= 0 || CopyClose(_Symbol, tf, shift, 1, close) <= 0) {
        // Fallback al timeframe actual si el probador no ha cargado M1
        if(CopyOpen(_Symbol, _Period, shift, 1, open) <= 0 || CopyClose(_Symbol, _Period, shift, 1, close) <= 0) return 0;
    }
    double body = MathAbs(close[0] - open[0]);
    if(body < MinCuerpoVelaPips * _Point * 10) return 0; 
    return (close[0] > open[0] ? 2 : -2);
}

void ChequearFiltrosV13() {
    bloqueadoPorNoticia = false;
    bloqueadoPorSR = false;
    srPeligro = "";
    fiboPeligro = "";
    
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // --- FILTRO DE NOTICIAS ---
    if(UsarFiltroNoticias) {
        MqlCalendarValue values[];
        datetime now = TimeCurrent();
        datetime from = now - (MinutosDespuesNoticia * 60);
        datetime to = now + (MinutosAntesNoticia * 60);
        
        if(CalendarValueHistory(values, from, to, "US")) {
            for(int i=0; i<ArraySize(values); i++) {
                MqlCalendarEvent ev;
                if(CalendarEventById(values[i].event_id, ev)) {
                    if(ev.importance == CALENDAR_IMPORTANCE_HIGH) {
                        bloqueadoPorNoticia = true;
                        int diff = (int)((values[i].time - now) / 60);
                        if(diff > 0) minutosParaNoticia = diff;
                        break;
                    }
                }
            }
        }
    }
    
    // --- FILTRO S/R ---
    if(UsarFiltroSR) {
        ENUM_TIMEFRAMES tfs[] = {PERIOD_M15, PERIOD_H1, PERIOD_H4, PERIOD_D1};
        string tfs_names[] = {"M15", "H1", "H4", "D1"};
        
        for(int i=0; i<4; i++) {
            int hIdx = iHighest(_Symbol, tfs[i], MODE_HIGH, 40, 1);
            int lIdx = iLowest(_Symbol, tfs[i], MODE_LOW, 40, 1);
            if(hIdx < 0 || lIdx < 0) continue; // Si no hay datos, saltar
            
            double h = iHigh(_Symbol, tfs[i], hIdx);
            double l = iLow(_Symbol, tfs[i], lIdx);
            if(h <= 0 || l <= 0) continue; // Proteccion contra precio 0
            
            double distH = MathAbs(h - ask) / _Point / 10.0;
            double distL = MathAbs(bid - l) / _Point / 10.0;
            
            // Dibujar S/R en el grafico
            string nameH = "MAIKO_SR_H_" + tfs_names[i];
            if(ObjectFind(0, nameH) < 0) {
                ObjectCreate(0, nameH, OBJ_HLINE, 0, 0, h);
                ObjectSetInteger(0, nameH, OBJPROP_COLOR, clrRed);
                ObjectSetInteger(0, nameH, OBJPROP_STYLE, STYLE_DOT);
                ObjectSetInteger(0, nameH, OBJPROP_BACK, true);
            }
            ObjectSetDouble(0, nameH, OBJPROP_PRICE, h);
            
            string nameL = "MAIKO_SR_L_" + tfs_names[i];
            if(ObjectFind(0, nameL) < 0) {
                ObjectCreate(0, nameL, OBJ_HLINE, 0, 0, l);
                ObjectSetInteger(0, nameL, OBJPROP_COLOR, clrLimeGreen);
                ObjectSetInteger(0, nameL, OBJPROP_STYLE, STYLE_DOT);
                ObjectSetInteger(0, nameL, OBJPROP_BACK, true);
            }
            ObjectSetDouble(0, nameL, OBJPROP_PRICE, l);
            
            if(distH <= DistanciaPeligroPips && !bloqueadoPorSR) {
                bloqueadoPorSR = true;
                srPeligro = "TECHO " + tfs_names[i] + " (" + DoubleToString(distH, 1) + "p)";
            }
            if(distL <= DistanciaPeligroPips && !bloqueadoPorSR) {
                bloqueadoPorSR = true;
                srPeligro = "SUELO " + tfs_names[i] + " (" + DoubleToString(distL, 1) + "p)";
            }
        }
    }
    
    // --- FILTRO FIBONACCI ---
    fiboEstado = "FIBO: ANALIZANDO...";
    if(UsarFiltroFibo && srPeligro == "") { // Solo analizar Fibo si no hay S/R inminente
        ENUM_TIMEFRAMES tfs[] = {PERIOD_M15, PERIOD_H1, PERIOD_H4};
        string tfs_names[] = {"M15", "H1", "H4"};
        
        for(int i=0; i<3; i++) {
            int hIdx = iHighest(_Symbol, tfs[i], MODE_HIGH, 100, 1);
            int lIdx = iLowest(_Symbol, tfs[i], MODE_LOW, 100, 1);
            if(hIdx < 0 || lIdx < 0) continue;
            
            double h = iHigh(_Symbol, tfs[i], hIdx);
            double l = iLow(_Symbol, tfs[i], lIdx);
            if(h <= 0 || l <= 0) continue;
            
            double dist = h - l;
            if(dist < 50.0 * _Point * 10) continue; // Ignorar impulsos muy pequeos
            
            double fib38 = h - (dist * 0.382);
            double fib50 = h - (dist * 0.500);
            double fib61 = h - (dist * 0.618);
            
            fiboEstado = "IMPULSO " + tfs_names[i] + ": " + DoubleToString(dist/_Point/10.0, 1) + "p";
            
            // Dibujar niveles Fibonacci clave
            string n61 = "MAIKO_FIBO_61";
            if(ObjectFind(0, n61) < 0) {
                ObjectCreate(0, n61, OBJ_HLINE, 0, 0, fib61);
                ObjectSetInteger(0, n61, OBJPROP_COLOR, clrGoldenrod);
                ObjectSetInteger(0, n61, OBJPROP_STYLE, STYLE_DASH);
                ObjectSetInteger(0, n61, OBJPROP_BACK, true);
            }
            ObjectSetDouble(0, n61, OBJPROP_PRICE, fib61);
            
            string n38 = "MAIKO_FIBO_38";
            if(ObjectFind(0, n38) < 0) {
                ObjectCreate(0, n38, OBJ_HLINE, 0, 0, fib38);
                ObjectSetInteger(0, n38, OBJPROP_COLOR, clrPaleGoldenrod);
                ObjectSetInteger(0, n38, OBJPROP_STYLE, STYLE_DASH);
                ObjectSetInteger(0, n38, OBJPROP_BACK, true);
            }
            ObjectSetDouble(0, n38, OBJPROP_PRICE, fib38);
            
            double distFib61 = MathAbs(ask - fib61) / _Point / 10.0;
            if(distFib61 <= 15.0) {
                fiboPeligro = "ZONA FIBO 61.8% " + tfs_names[i];
                fiboEstado = fiboPeligro;
                break;
            }
            
            double distFib38 = MathAbs(ask - fib38) / _Point / 10.0;
            if(distFib38 <= 15.0) {
                fiboPeligro = "ZONA FIBO 38.2% " + tfs_names[i];
                fiboEstado = fiboPeligro;
                break;
            }
            break; // Si encontr un impulso vlido en este TF, no buscar en TFs mayores
        }
    }
}

void OnTick() {
    ActualizarEstadoMaster();
    ganadoPeriodo = CalcularGanadoUltraPreciso(idxPeriodo);
    flotante = CalcularProfit();
    spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point / 10;
    
    double rsi_buf[1], macd_buf[1], adx_buf[1], ema_buf[1];
    if(CopyBuffer(hRSI, 0, 0, 1, rsi_buf) > 0) rsiActual = rsi_buf[0];
    if(CopyBuffer(hMACD, 0, 0, 1, macd_buf) > 0) macdActual = macd_buf[0];
    if(CopyBuffer(hADX, 0, 0, 1, adx_buf) > 0) adxActual = adx_buf[0];
    if(CopyBuffer(hEMA_M5, 0, 0, 1, ema_buf) > 0) emaActual = ema_buf[0];
    
    ChequearFiltrosV13();
    
    // --- STOP LOSS DE EQUIDAD ---
    if(InpUsarProteccionEquidad && flotante < 0) {
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double maxLossDinero = balance * (InpMaxDrawdownPorcentaje / 100.0);
        
        if(MathAbs(flotante) >= maxLossDinero) {
            txtVoz = "STOP LOSS MAX ACTIVADO!";
            CerrarTodo();
            // No apagamos el bot, dejamos que siga operando para recuperarse
            return;
        }
    }
    
    // CHEQUEO CIERRE FORZADO DE VIERNES (Si está activo)
    MqlDateTime dt; TimeCurrent(dt);
    if(CerrarViernesNoche && dt.day_of_week == 5 && dt.hour >= HoraCierreViernes) {
        if(ArraySize(pos) > 0) {
            txtVoz = "CIERRE FIN DE SEMANA ⚠️";
            CerrarTodo();
            return;
        }
    }
    double emaH1[1], emaM15[1], emaM5[1];
    CopyBuffer(hEMA_H1, 0, 0, 1, emaH1);
    CopyBuffer(hEMA_M15, 0, 0, 1, emaM15);
    CopyBuffer(hEMA_M5, 0, 0, 1, emaM5);
    CopyBuffer(hEMA_M15, 0, 0, 1, emaM15);
    CopyBuffer(hEMA_M5, 0, 0, 1, emaM5);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    direccion = 0; 
    condBuy = (rsiActual > 50);
    condSell = (rsiActual < 50);
    
    if(CheckH1) { condBuy = condBuy && (bid > emaH1[0]); condSell = condSell && (bid < emaH1[0]); }
    if(CheckM15) { condBuy = condBuy && (bid > emaM15[0]); condSell = condSell && (bid < emaM15[0]); }
    if(CheckM5) { condBuy = condBuy && (bid > emaM5[0]); condSell = condSell && (bid < emaM5[0]); }
    if(UsarMACD) { condBuy = condBuy && (macdActual > 0); condSell = condSell && (macdActual < 0); }

    if(condBuy) direccion = 1; else if(condSell) direccion = -1;

    int p0 = AnalizarPatronPriceAction(PERIOD_M1, 0);
    if(p0 == 0) txtAnalisisVela = "M1: ACUMULACION / DOJI";
    else txtAnalisisVela = (p0 == 2 ? "M1: FUERZA ALCISTA" : "M1: FUERZA BAJISTA");

    // SOFT RECOVERY LÓGICA
    double metaCesta = (ArraySize(pos) >= LimitePosicionesSOS) ? 25.0 : ProfitNetoCents;
    if(ArraySize(pos) > 0 && flotante >= metaCesta) { 
        txtVoz = "CIERRE DE CESTA."; CerrarTodo(); return; 
    }
    GestionarCosechaSniper(); 
    ActualizarRadarMaster();
    ActualizarInterfazMaster();
    
    // CONGELACIÓN DE NUEVAS ENTRADAS EL VIERNES NOCHE (PERMITIENDO CIERRES ANTES)
    if(BloquearViernesNoche && dt.day_of_week == 5 && dt.hour >= HoraCierreViernes) {
        txtVeredicto = "VIERNES NOCHE: BLOQUEADO";
        if(ArraySize(pos) > 0) {
            txtVoz = StringFormat("CONGELADO FIN DE SEMANA (%d pos abiertas)", ArraySize(pos));
        } else {
            txtVoz = "MERCADO CERRADO / ESPERANDO";
        }
        ActualizarInterfazMaster();
        return;
    }

    if(!BotActivo) { txtVoz = "SISTEMA EN PAUSA."; return; }
    
    if(ArraySize(pos) > 0) { 
        txtVoz = StringFormat("VIGILANDO (%d/%d) SOS", ArraySize(pos), LimitePosicionesSOS);
        GestionarRefuerzoInteligente(); 
    } else {
        if(spreadActual > MaxSpreadPips) { txtVeredicto = "SPREAD ALTO"; return; }
        if(direccion == 0) { txtVeredicto = "FILTRANDO TENDENCIA..."; return; }
        
        int pM5 = AnalizarPatronPriceAction(PERIOD_M5, 1);
        int pM1 = AnalizarPatronPriceAction(PERIOD_M1, 1);
        
        if(bloqueadoPorNoticia) { txtVeredicto = "ESPERA: NOTICIA ROJA (" + IntegerToString(minutosParaNoticia) + "m)"; return; }
        if(bloqueadoPorSR) { txtVeredicto = "ESPERA: S/R " + srPeligro; return; }
        if(fiboPeligro != "") { txtVeredicto = fiboPeligro; } // Mostrar zona Fibo, pero no bloquea entradas Cascada todavia
        
        txtVoz = (direccion == 1) ? "BUSCANDO MOMENTO COMPRA..." : "BUSCANDO MOMENTO VENTA...";

        if(direccion == 1 && pM5 == 2 && pM1 == 2) {
            trade.Buy(LotajeInicial, _Symbol, 0, 0, 0, TradeComment);
            txtVoz = "COMPRA SNIPER!";
        }
        else if(direccion == -1 && pM5 == -2 && pM1 == -2) {
            trade.Sell(LotajeInicial, _Symbol, 0, 0, 0, TradeComment);
            txtVoz = "VENTA SNIPER!";
        } else txtVeredicto = "ESPERANDO CONFIRMACION M5/M1";
    }
}

void GestionarRefuerzoInteligente() {
    if(ArraySize(pos) >= LimitePosicionesSOS || volTotal >= MaxLoteTotal) { txtVeredicto = "RIESGO MAXIMO (LOCK)"; return; }
    if(TimeCurrent() - ultimoSOS < 60) return;
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double distPips = MathAbs((pos[0].t==POSITION_TYPE_BUY ? bid : ask) - pos[0].pr) / _Point / 10;
    if(distPips < DistanciaRefuerzoPips) { txtVeredicto = StringFormat("DIST. SOS: %.1f/%.0f", distPips, DistanciaRefuerzoPips); return; }
    
    double op[1], cl[1];
    if(CopyOpen(_Symbol, _Period, 1, 1, op) <= 0 || CopyClose(_Symbol, _Period, 1, 1, cl) <= 0) return;
    bool confirmado = (pos[0].t == POSITION_TYPE_BUY) ? (cl[0] > op[0]) : (cl[0] < op[0]);
    if(!confirmado) { txtVeredicto = "ESPERANDO GIRO (" + EnumToString(_Period) + ")"; return; }
    
    double volRef = MaxLoteIndividual; 
    if(volTotal + volRef > MaxLoteTotal) volRef = NormalizeDouble(MaxLoteTotal - volTotal, 2); 
    if(volRef >= 0.01) {
        if(pos[0].t == POSITION_TYPE_BUY) trade.Buy(volRef, _Symbol, 0, 0, 0, TradeComment + "_SOS");
        else trade.Sell(volRef, _Symbol, 0, 0, 0, TradeComment + "_SOS");
        ultimoSOS = TimeCurrent();
    }
}

void GestionarCosechaSniper() { 
    for(int i=ArraySize(pos)-1; i>=0; i--) {
        if(pos[i].tp > 0) continue; 
        double profitObjetivo = (pos[i].v / 0.01) * ProfitCosechaCents;
        if(pos[i].p >= profitObjetivo) trade.PositionClose(pos[i].ticket); 
    }
}

double CalcularProfit() { double s=0; for(int i=0; i<ArraySize(pos); i++) s += pos[i].p; return s; }

double CalcularGanadoUltraPreciso(int modo) {
    datetime start = 0;
    MqlDateTime dt; TimeCurrent(dt);
    if(modo == 0) { dt.hour=0; dt.min=0; dt.sec=0; start = StructToTime(dt); }
    else if(modo == 1) { 
        int dow = dt.day_of_week; if(dow == 0) dow = 7;
        start = TimeCurrent() - (dow-1)*86400;
        MqlDateTime sw; TimeToStruct(start, sw); sw.hour=0; sw.min=0; sw.sec=0; start = StructToTime(sw);
    }
    else if(modo == 2) { dt.day=1; dt.hour=0; dt.min=0; dt.sec=0; start = StructToTime(dt); }
    else if(modo == 3) { start = FechaInicioMaiko; }
    double total = 0; HistorySelect(start, TimeCurrent()); 
    for(int i=HistoryDealsTotal()-1; i>=0; i--) {
        ulong t = HistoryDealGetTicket(i);
        // PARCHE DE SEGURIDAD HISTORICA: Filtro por Magic Number y Símbolo
        if(HistoryDealGetString(t, DEAL_SYMBOL) != _Symbol || HistoryDealGetInteger(t, DEAL_MAGIC) != ExpertMagic) continue;
        total += HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_SWAP) + HistoryDealGetDouble(t, DEAL_COMMISSION); 
    }
    return total;
}

void CerrarTodo() { for(int i=ArraySize(pos)-1; i>=0; i--) trade.PositionClose(pos[i].ticket); }

void ActualizarRadarMaster() { 
    string tfs[]={"W1","D1","H4","H1","M15","M5","M1"}; 
    double pr = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    for(int i=0; i<7; i++) { 
        double buf[1]; color col = clrGray; 
        if(CopyBuffer(hRadar[i], 0, 0, 1, buf) > 0) col = (pr > buf[0]) ? clrSpringGreen : clrRed;
        ObjectSetInteger(0, "MAIKO_Radar_"+tfs[i], OBJPROP_COLOR, col); 
    } 
}

void ActualizarEstadoMaster() { 
    ArrayResize(pos, 0); volTotal = 0; 
    for(int i=PositionsTotal()-1; i>=0; i--) {
        ulong t = PositionGetTicket(i);
        // PARCHE DE SEGURIDAD ACTIVA: Filtro por Símbolo y Magic Number
        if(PositionSelectByTicket(t) && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == ExpertMagic) { 
            int idx = ArraySize(pos); ArrayResize(pos, idx+1); 
            pos[idx].ticket = t; 
            pos[idx].p = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP) + PositionGetDouble(POSITION_COMMISSION); 
            pos[idx].t = (int)PositionGetInteger(POSITION_TYPE); pos[idx].v = PositionGetDouble(POSITION_VOLUME); 
            pos[idx].pr = PositionGetDouble(POSITION_PRICE_OPEN); 
            pos[idx].tp = PositionGetDouble(POSITION_TP);
            volTotal += pos[idx].v; 
        } 
    }
}

void CrearInterfazMaster() { 
    int x = HUD_X, y = PosY_HUD, w = 400, h = 330; 
    ObjectCreate(0, "MAIKO_Bg", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_XDISTANCE, x); ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_XSIZE, w); ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_YSIZE, h);
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_BGCOLOR, ColorBody); ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_ZORDER, 9999); 
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_BACK, false);
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_BORDER_TYPE, BORDER_FLAT);
    CrearBoton("MAIKO_Head", x, y, w, 35, "", ColorHeader, clrNONE, 10000); 
    CrearLabel("MAIKO_T", x+10, y+10, "MAIKO PRO | GOLD V13", ColorMain, 11, 10001); 
    CrearBoton("MAIKO_BtnMin", x+w-35, y+5, 30, 25, "_", clrGray, clrWhite, 10010);
    string rads[]={"W1","D1","H4","H1","M15","M5","M1"};
    for(int i=0; i<7; i++) {
        CrearLabel("MAIKO_L_"+rads[i], x+15+(i/4)*100, y+45+(i%4)*20, rads[i]+":", clrWhite, 8, 10001);
        CrearLabel("MAIKO_Radar_"+rads[i], x+45+(i/4)*100, y+45+(i%4)*20, "o", clrGray, 10, 10001);
    }
    CrearLabel("MAIKO_M1", x+15, y+135, txtAnalisisVela, clrWhite, 8, 10001); 
    CrearLabel("MAIKO_Vered", x+15, y+150, txtVeredicto, clrCyan, 9, 10001); 
    CrearLabel("MAIKO_SPD", x+w-120, y+135, "SPD: 0.0", clrWhite, 8, 10001);
    CrearLabel("MAIKO_RSI", x+w-120, y+45, "RSI: 0.0", clrOrange, 9, 10001);
    CrearLabel("MAIKO_LVol", x+w-120, y+65, "VOL TOTAL:", clrWhite, 8, 10001);
    CrearLabel("MAIKO_MACD", x+w-120, y+85, "MACD: 0.0", clrSkyBlue, 8, 10001);
    CrearLabel("MAIKO_ADX", x+w-120, y+100, "ADX: 0.0", clrYellow, 8, 10001);
    CrearLabel("MAIKO_EMA", x+w-120, y+115, "EMA50: 0.0", clrWhite, 8, 10001);
    CrearLabel("MAIKO_FiboEst", x+15, y+165, "FIBO: ANALIZANDO...", clrGoldenrod, 9, 10001);
    CrearLabel("MAIKO_Hoy", x+15, y+185, "GANADO HOY: $0.00", clrSpringGreen, 14, 10001); 
    CrearLabel("MAIKO_Rend", x+15, y+210, "RENDIMIENTO: 0.00%", clrWhite, 8, 10001); 
    CrearLabel("MAIKO_Flotante", x+15, y+230, "FLOTANTE: $0.00", clrWhite, 12, 10001); 
    CrearLabel("MAIKO_Voz", x+15, y+295, txtVoz, clrGold, 10, 10001); 
    CrearBoton("MAIKO_BtnHist", x+15, y+255, 140, 25, "CAMBIAR VISTA", clrGray, clrWhite, 10010);
    CrearBoton("MAIKO_BtnP", x+w-120, y+165, 110, 50, "ENCENDER", clrDarkGreen, clrWhite, 10010); 
    CrearBoton("MAIKO_BtnC", x+w-120, y+225, 110, 35, "CERRAR", clrDarkRed, clrWhite, 10010); 
}

void ActualizarInterfazMaster() { 
    double divisor = CUENTA_REAL_CENT ? 100.0 : 1.0;
    string unit = CUENTA_REAL_CENT ? "$" : "";
    ObjectSetString(0, "MAIKO_Hoy", OBJPROP_TEXT, StringFormat("%s: %s%.2f", labelPeriodo[idxPeriodo], unit, ganadoPeriodo / divisor)); 
    ObjectSetString(0, "MAIKO_Flotante", OBJPROP_TEXT, StringFormat("FLOTANTE: %s%.2f", unit, flotante / divisor)); 
    ObjectSetInteger(0, "MAIKO_Flotante", OBJPROP_COLOR, flotante >= 0 ? clrSpringGreen : clrRed); 
    ObjectSetString(0, "MAIKO_M1", OBJPROP_TEXT, txtAnalisisVela);
    ObjectSetString(0, "MAIKO_Vered", OBJPROP_TEXT, txtVeredicto);
    ObjectSetString(0, "MAIKO_FiboEst", OBJPROP_TEXT, fiboEstado);
    ObjectSetString(0, "MAIKO_SPD", OBJPROP_TEXT, StringFormat("SPD: %.1f", spreadActual));
    ObjectSetString(0, "MAIKO_RSI", OBJPROP_TEXT, StringFormat("RSI: %.1f", rsiActual));
    ObjectSetString(0, "MAIKO_MACD", OBJPROP_TEXT, StringFormat("MACD: %.3f", macdActual));
    ObjectSetString(0, "MAIKO_ADX", OBJPROP_TEXT, StringFormat("ADX: %.1f", adxActual));
    ObjectSetString(0, "MAIKO_EMA", OBJPROP_TEXT, StringFormat("EMA50(M5): %.2f", emaActual));
    ObjectSetString(0, "MAIKO_LVol", OBJPROP_TEXT, StringFormat("VOL: %.2f/%.2f", volTotal, MaxLoteTotal));
    ObjectSetString(0, "MAIKO_Voz", OBJPROP_TEXT, txtVoz);
    ObjectSetString(0, "MAIKO_BtnP", OBJPROP_TEXT, BotActivo ? "ENCENDIDO" : "ENCENDER");
    ObjectSetInteger(0, "MAIKO_BtnP", OBJPROP_BGCOLOR, BotActivo ? clrRoyalBlue : clrDarkGreen);
    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_YSIZE, hudMinimizado ? 35 : 330);
}

void CrearBoton(string n, int x, int y, int w, int h, string t, color bg, color fg, int z) { 
    ObjectCreate(0, n, OBJ_BUTTON, 0, 0, 0); 
    ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, n, OBJPROP_XSIZE, w); ObjectSetInteger(0, n, OBJPROP_YSIZE, h);
    ObjectSetInteger(0, n, OBJPROP_BGCOLOR, bg); ObjectSetInteger(0, n, OBJPROP_COLOR, fg);
    ObjectSetString(0, n, OBJPROP_TEXT, t); ObjectSetInteger(0, n, OBJPROP_ZORDER, z); 
    ObjectSetInteger(0, n, OBJPROP_BACK, false); ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
}

void CrearLabel(string n, int x, int y, string t, color col, int s, int z) { 
    ObjectCreate(0, n, OBJ_LABEL, 0, 0, 0); 
    ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
    ObjectSetString(0, n, OBJPROP_TEXT, t); ObjectSetInteger(0, n, OBJPROP_COLOR, col); 
    ObjectSetInteger(0, n, OBJPROP_FONTSIZE, s); ObjectSetInteger(0, n, OBJPROP_ZORDER, z); 
    ObjectSetInteger(0, n, OBJPROP_BACK, false); ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) { 
    if(id == CHARTEVENT_OBJECT_CLICK) { 
        if(sparam == "MAIKO_BtnP") { BotActivo = !BotActivo; ActualizarInterfazMaster(); }
        if(sparam == "MAIKO_BtnC") CerrarTodo(); 
        if(sparam == "MAIKO_BtnHist") { 
            idxPeriodo++; 
            if(idxPeriodo > 3) idxPeriodo = 0; 
            ganadoPeriodo = CalcularGanadoUltraPreciso(idxPeriodo); // BUG FIX: Recalcular instantáneamente al cambiar la vista
            ActualizarInterfazMaster(); 
        }
        if(sparam == "MAIKO_BtnMin") { hudMinimizado = !hudMinimizado; ActualizarInterfazMaster(); }
        ChartRedraw(); 
    } 
}

// Handler de temporizador para actualizar el HUD en mercados lentos o cerrados
void OnTimer() {
    ActualizarEstadoMaster();
    ganadoPeriodo = CalcularGanadoUltraPreciso(idxPeriodo);
    flotante = CalcularProfit();
    spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point / 10;
    
    double rsi_buf[1], macd_buf[1], adx_buf[1], ema_buf[1];
    if(CopyBuffer(hRSI, 0, 0, 1, rsi_buf) > 0) rsiActual = rsi_buf[0];
    if(CopyBuffer(hMACD, 0, 0, 1, macd_buf) > 0) macdActual = macd_buf[0];
    if(CopyBuffer(hADX, 0, 0, 1, adx_buf) > 0) adxActual = adx_buf[0];
    if(CopyBuffer(hEMA_M5, 0, 0, 1, ema_buf) > 0) emaActual = ema_buf[0];
    
    ActualizarRadarMaster();
    ActualizarInterfazMaster();
}

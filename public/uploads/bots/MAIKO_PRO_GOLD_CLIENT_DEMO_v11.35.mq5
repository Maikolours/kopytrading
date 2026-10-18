//+------------------------------------------------------------------+
//|           MAIKO PRO GOLD CLIENT DEMO v11.35                     |
//|       "INSTITUTIONAL TIMETABLE EDITION - TRIAL DEMO"             |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADING MAIKO"
#property version   "11.35"
#property strict

#include <Trade\Trade.mqh>

// --- CONFIGURACION GENERAL ---
input group "=== CONFIGURACION GENERAL ==="
input string   MiLicencia                 = "";          // 🔑 Clave de Licencia o Correo Usuario
input double   LoteAtaque                 = 0.01;        // 📊 Volumen Entrada Inicial (Ataque)

// --- GESTION DE RIESGO Y BENEFICIOS ---
input group "=== GESTION DE RIESGO Y BENEFICIOS ==="
input double   ProfitNetoFlush            = 5.0;         // 💰 Beneficio Cierre Total Cesta ($)
input double   TargetDiario               = 100.0;       // 🎯 Meta de Beneficio Diario ($)
input bool     UsarStopLossPorcentaje     = true;        // 🛡️ Activar Stop Loss por % Cuenta (DE SERIE)
input double   PorcentajeStopLoss         = 15.0;        // 📉 Porcentaje de Pérdida Máxima (15.0% DE SERIE)

// --- HORARIOS OPERATIVOS Y DIAS ---
input group "=== HORARIOS OPERATIVOS Y DIAS ==="
input int      HoraInicioOperativa        = 1;           // ⏰ Hora de Inicio Operaciones Diaria (Broker)
input int      HoraFinOperativa           = 23;          // ⏰ Hora de Cierre Operaciones Diaria (Broker)
input bool     OperarLunes                = true;        // 📅 Operar los Lunes
input bool     OperarMartes               = true;        // 📅 Operar los Martes
input bool     OperarMiercoles            = true;        // 📅 Operar los Miércoles
input bool     OperarJueves               = true;        // 📅 Operar los Jueves
input bool     OperarViernes              = true;        // 📅 Operar los Viernes

// --- INTERFAZ GRAFICA (HUD) ---
input group "=== INTERFAZ GRAFICA (HUD) ===" 
input color    ColorMain                  = clrGold;     // 🎨 Color Principal HUD (Acento)
input color    ColorHeader                = C'30,30,30'; // 🎨 Color Encabezado Panel HUD
input color    ColorBody                  = C'20,20,20'; // 🎨 Color Cuerpo Panel HUD
input int      HUD_X                      = 15;          // 📍 Posición X en Pantalla (Pixeles)
input int      PosY_HUD                   = 25;          // 📍 Posición Y en Pantalla (Pixeles)

// --- COMENTARIOS DE OPERACIONES ---
input group "=== COMENTARIOS DE OPERACIONES ==="
input string   TradeComment               = "MAIKO_GOLD_DEMO"; // 🏷️ Comentario para Órdenes (Trade Comment)

// --- TELEMETRIA ---
string SyncURL = "https://www.kopytrading.com/api/sync-positions";
int SyncIntervalSec = 2;
datetime ultimoSync = 0;

// --- ESTRATEGIA CUANTITATIVA INSTITUCIONAL (PARAMETROS INTERNOS PROTEGIDOS) ---
const int      DiasDeTrial                = 30;
const bool     EsCuentaCent               = false;

const double   MaxRangoVelaM1             = 20.0;
const double   MaxSpreadPips              = 4.0;
const double   SensibilidadMechaReal      = 3.0;
const int      MinutosPausaTrasSusto      = 1;
const double   MaxRsiCompra               = 70.0;
const double   MinRsiVenta                = 30.0;

const bool     UsarFiltroTechosSuelos     = true;
const ENUM_TIMEFRAMES TimeframeTechosSuelos = PERIOD_M15;
const int      PeriodoTechosSuelos        = 24;
const double   DistanciaTechoSueloPips    = 15.0;

const bool     UsarFiltroTechosSuelosH1   = true;
const int      PeriodoTechosSuelosH1      = 24;
const double   DistanciaTechoSueloPipsH1  = 30.0;

const bool     UsarFiltroTechosSuelosH4   = true;
const int      PeriodoTechosSuelosH4      = 24;
const double   DistanciaTechoSueloPipsH4  = 50.0;

const bool     UsarFiltroAgotamientoM15   = true;
const double   MinPorcentajeMechaM15      = 40.0;

const bool     UsarConfirmacionRuptura    = true;
const ENUM_TIMEFRAMES TimeframeConfirmacion = PERIOD_M5;

const int      PeriodoMediaFiltro         = 50;
const bool     CheckM15                   = true;
const bool     CheckM5                    = true;

const int      RuedasAmetralladora        = 1;
const double   MultiplicadorRefuerzo      = 1.5;
const double   MaxLoteTotal               = 0.50;
const double   MaxLoteIndividual          = 0.02;

const double   DistanciaRefuerzoPips      = 30.0;
const double   MaxPipsHueco               = 50.0;
const int      MaxVelasHueco              = 5;

const double   ProfitCosechaIndividual    = 0.75;

const bool     UsarBloqueoJuevesMadrugada = true;
const int      HoraInicioJueves           = 1;
const int      HoraFinJueves              = 7;

const bool     UsarBloqueoMiercolesNoticias = true;
const int      HoraInicioMiercoles        = 12;
const int      HoraFinMiercoles           = 14;

const bool     UsarBloqueoViernesNoticias = true;
const int      HoraInicioViernes          = 13;
const int      HoraFinViernes             = 14;

const bool     UsarHorarioBloqueo         = false;
const int      HoraInicioBloqueo          = 14;
const int      HoraFinBloqueo             = 16;

const bool     CerrarTodoViernesCierre    = true;
const int      HoraCierreViernes          = 21;
const bool     OperarViernesNoche         = false;

const int      LimitePosicionesSOS        = 2;
const double   ProfitBreakEven            = 0.50;
const double   ProteccionBeneficioDiario  = 0.0;
const bool     UsarPausaTrasStopLoss      = true;
const int      MinutosPausaTrasStopLoss   = 120;

string         HUD_Branding               = "MAIKO PRO GOLD v11.35 (DEMO)";
const bool     ShowW1                     = true;
const bool     ShowD1                     = true;
const bool     ShowH4                     = true;
const bool     ShowH1                     = true;
const bool     ShowM15                    = true;
const bool     ShowM5                     = true;
const bool     ShowM1                     = true;
 // ?? Comentario para Órdenes (Trade Comment)

// Globales

CTrade trade;

input int ExpertMagic = 111336;

struct PosInfo { ulong ticket; double p; double c; double s; int t; double v; datetime time; double pr; };

PosInfo pos[];

double ganadoHoy = 0, flotante = 0, volTotal = 0, spreadActual = 0;

bool BotActivo = false;

bool hudMinimizado = false;

datetime ultimoAtaque = 0;

string txtVoz = "SCHOLAR: Escaneando...";

string txtVeredicto = "ESPERANDO...";

datetime proximoAtaque = 0, pausaVolatilidad = 0, pausaStopLoss = 0;

bool enFaseAnalisis = false;

int FaseRefuerzo = 0;

datetime trialStart = 0;

int diasRestantes = 30;

bool trialExpirado = false;



ulong ticketExplorador = 0;

int hEMA_v = INVALID_HANDLE;

int hRSI_v = INVALID_HANDLE;

int hRadar[7];

ENUM_TIMEFRAMES etfs[]={PERIOD_W1,PERIOD_D1,PERIOD_H4,PERIOD_H1,PERIOD_M15,PERIOD_M5,PERIOD_M1};



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

    if(AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL) {

        Alert("MAIKO SNIPER: TRIAL SÓLO VÁLIDO PARA CUENTAS DEMO.");

        return INIT_FAILED;

    }

    

    // El límite se aplica en CheckTrial para evitar error de constante

        

    trade.SetExpertMagicNumber(ExpertMagic);

    trade.SetAsyncMode(true);

    hEMA_v = iMA(_Symbol, _Period, PeriodoMediaFiltro, 0, MODE_EMA, PRICE_CLOSE);

    hRSI_v = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);

    

    // Inicializar handles de radar de forma estática para optimizar CPU

    for(int i=0; i<7; i++) {

        hRadar[i] = iMA(_Symbol, etfs[i], PeriodoMediaFiltro, 0, MODE_EMA, PRICE_CLOSE);

    }

    

    AgregarIndicadoresVisuales();

    CrearInterfazMaster();

    ChartSetInteger(0, CHART_FOREGROUND, false); ChartSetInteger(0, CHART_SHOW_TRADE_HISTORY, false);

      

    string gvName = "MAIKO_TRIAL_" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));

    if(GlobalVariableCheck(gvName)) {

        trialStart = (datetime)GlobalVariableGet(gvName);

    } else {

        trialStart = TimeCurrent();

        GlobalVariableSet(gvName, (double)trialStart);

    }

      if(MQLInfoInteger(MQL_TESTER)) {
          trialExpirado = false;
          diasRestantes = 30;
          BotActivo = true;
      } else {
          int maxDias = DiasDeTrial;
          if(maxDias > 30) maxDias = 30;
          diasRestantes = maxDias - (int)((TimeCurrent() - trialStart) / 86400);
          int diasOperando = (int)((TimeCurrent() - trialStart) / 86400) + 1;
          if(diasRestantes <= 0) { trialExpirado = true; BotActivo = false; }
      }
    
    ActualizarTextosEstado();
    ActualizarInterfazMaster();
    EventSetTimer(1);
    return(INIT_SUCCEEDED);

}



void OnDeinit(const int reason) { 

    EventKillTimer();

    ObjectsDeleteAll(0, "MAIKO_"); 

    for(int i=0; i<7; i++) {

        if(hRadar[i] != INVALID_HANDLE) IndicatorRelease(hRadar[i]);

    }

    if(hEMA_v != INVALID_HANDLE) IndicatorRelease(hEMA_v);

    if(hRSI_v != INVALID_HANDLE) IndicatorRelease(hRSI_v);

    ChartRedraw(); 

}




//+------------------------------------------------------------------+
//| Validar Horarios y Días Permitidos                               |
//+------------------------------------------------------------------+
bool EsHorarioPermitido(datetime serverTime, string &motivo) {
    MqlDateTime time;
    TimeToStruct(serverTime, time);

    // 1. Fin de semana
    if(time.day_of_week == 0 || time.day_of_week == 6) {
        motivo = "MERCADO CERRADO (FIN DE SEMANA)";
        return false;
    }

    // 2. Días de la semana
    if(time.day_of_week == 1 && !OperarLunes) {
        motivo = "DIA DESACTIVADO: LUNES";
        return false;
    }
    if(time.day_of_week == 2 && !OperarMartes) {
        motivo = "DIA DESACTIVADO: MARTES";
        return false;
    }
    if(time.day_of_week == 3 && !OperarMiercoles) {
        motivo = "DIA DESACTIVADO: MIERCOLES";
        return false;
    }
    if(time.day_of_week == 4 && !OperarJueves) {
        motivo = "DIA DESACTIVADO: JUEVES";
        return false;
    }
    if(time.day_of_week == 5 && !OperarViernes) {
        motivo = "DIA DESACTIVADO: VIERNES";
        return false;
    }

    // 3. Viernes noche / cierre fin de semana
    if(time.day_of_week == 5 && time.hour >= HoraCierreViernes && !OperarViernesNoche) {
        motivo = "VIERNES CIERRE FIN DE SEMANA";
        return false;
    }

    // 4. Horario general diario
    if(time.hour < HoraInicioOperativa || time.hour >= HoraFinOperativa) {
        motivo = "FUERA DE HORARIO (" + IntegerToString(HoraInicioOperativa) + ":00-" + IntegerToString(HoraFinOperativa) + ":00)";
        return false;
    }

    // 5. Bloqueo quirúrgico Jueves Madrugada
    if(UsarBloqueoJuevesMadrugada && time.day_of_week == 4) {
        if(time.hour >= HoraInicioJueves && time.hour < HoraFinJueves) {
            motivo = "BLOQUEO JUEVES MADRUGADA (" + IntegerToString(HoraInicioJueves) + ":00-" + IntegerToString(HoraFinJueves) + ":00)";
            return false;
        }
    }

    // 6. Bloqueo quirúrgico Miércoles Noticias
    if(UsarBloqueoMiercolesNoticias && time.day_of_week == 3) {
        if(time.hour >= HoraInicioMiercoles && time.hour < HoraFinMiercoles) {
            motivo = "BLOQUEO MIERCOLES NOTICIAS (" + IntegerToString(HoraInicioMiercoles) + ":00-" + IntegerToString(HoraFinMiercoles) + ":00)";
            return false;
        }
    }

    // 7. Bloqueo quirúrgico Viernes Noticias (NFP)
    if(UsarBloqueoViernesNoticias && time.day_of_week == 5) {
        if(time.hour >= HoraInicioViernes && time.hour < HoraFinViernes) {
            motivo = "BLOQUEO VIERNES NOTICIAS (" + IntegerToString(HoraInicioViernes) + ":00-" + IntegerToString(HoraFinViernes) + ":00)";
            return false;
        }
    }

    // 8. Bloqueo Horario Genérico Diario (Noticias)
    if(UsarHorarioBloqueo) {
        if(time.hour >= HoraInicioBloqueo && time.hour < HoraFinBloqueo) {
            motivo = "BLOQUEO HORARIO NOTICIAS (" + IntegerToString(HoraInicioBloqueo) + ":00-" + IntegerToString(HoraFinBloqueo) + ":00)";
            return false;
        }
    }

    motivo = "OPERATIVO";
    return true;
}

void ActualizarTextosEstado() {
    if(MQLInfoInteger(MQL_TESTER)) {
        trialExpirado = false;
        diasRestantes = 30;
    } else {
        int maxDias = DiasDeTrial;
        if(maxDias > 30) maxDias = 30;
        diasRestantes = maxDias - (int)((TimeTradeServer() - trialStart) / 86400);
        if(diasRestantes <= 0) { trialExpirado = true; BotActivo = false; }
    }



    if(trialExpirado) {

        txtVoz = "TRIAL 30 DIAS EXPIRADO.";

        txtVeredicto = "EXPIRADO";

        return;

    }



    if(!BotActivo) {

        txtVoz = "BOT APAGADO / PAUSADO";

        txtVeredicto = "APAGADO";

        return;

    }



    ActualizarEstadoMaster();

    if(ArraySize(pos) > 0) {

        string dirStr = (pos[0].t == POSITION_TYPE_BUY) ? "COMPRA" : "VENTA";

        txtVoz = StringFormat("MAIKO: Vigilando %s activo...", dirStr);

        return;

    }



    datetime serverTime = TimeTradeServer();

    if(serverTime < pausaStopLoss) {

        txtVoz = "STANDBY POST-SL (" + IntegerToString((int)((pausaStopLoss - serverTime) / 60) + 1) + " MIN)";

        txtVeredicto = "STANDBY SL";

        return;

    }



    string motivoHorario = "";
    bool enHorario = EsHorarioPermitido(serverTime, motivoHorario);

    if(!enHorario) {
        txtVoz = motivoHorario;
        txtVeredicto = "STANDBY (" + motivoHorario + ")";
    } else {
        // --- DETECCION CONTINUA DE FILTROS PARA EL HUD ---
        double ema[1];
        if(CopyBuffer(hEMA_v, 0, 1, 1, ema) > 0) {
            double precio = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            string potential_dir = (precio > ema[0]) ? "BUY" : "SELL";
            if(!ValidarTechosSuelos(potential_dir)) {
                txtVoz = "SCHOLAR: " + txtVeredicto;
            } else {
                if(!enFaseAnalisis) {
                    txtVoz = "SCHOLAR: Buscando...";
                    txtVeredicto = "ESPERANDO...";
                }
            }
        } else {
            if(!enFaseAnalisis) {
                txtVoz = "SCHOLAR: Buscando...";
                txtVeredicto = "ESPERANDO...";
            }
        }
    }

}



void OnTick() {

    ActualizarTextosEstado();

    if(trialExpirado) { BotActivo = false; ActualizarInterfazMaster(); return; }

    if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) { txtVoz = "TRADING NO PERMITIDO"; return; }



    ActualizarEstadoMaster();

    ganadoHoy = CalcularGanadoHoy();

    flotante = CalcularProfit();

    spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point / 10;



    double multCent = EsCuentaCent ? 100.0 : 1.0;

    double targetActual = (ArraySize(pos) >= LimitePosicionesSOS) ? (ProfitBreakEven * multCent) : (ProfitNetoFlush * multCent);

    

    if(ArraySize(pos) > 0 && flotante >= targetActual) {

        txtVoz = "CIERRE NETO ALCANZADO."; CerrarTodo(); enFaseAnalisis = false; return;

    }

    static datetime ultimoDiaReset = 0;
    datetime diaActual = iTime(_Symbol, PERIOD_D1, 0);
    if(diaActual != ultimoDiaReset) {
        ultimoDiaReset = diaActual;
        BotActivo = true; // Reiniciar automáticamente en cada nuevo día
    }

    if(ganadoHoy >= (TargetDiario * multCent)) {
        txtVoz = "OBJETIVO DIARIO CUMPLIDO."; 
        if(ArraySize(pos) > 0) CerrarTodo(); 
        enFaseAnalisis = false;
        txtVeredicto = "OBJETIVO DIARIO ALCANZADO (PAUSA HOY)";
        ActualizarInterfazMaster(); 
        return;
    }

    if(ProteccionBeneficioDiario > 0.0 && ganadoHoy > (ProteccionBeneficioDiario * multCent)) {
        if((ganadoHoy + flotante) <= (ProteccionBeneficioDiario * multCent) && ArraySize(pos) > 0) {
            txtVoz = "PROTECCION BENEFICIO."; CerrarTodo(); enFaseAnalisis = false; ActualizarInterfazMaster(); return;
        }
    }

    if(UsarStopLossPorcentaje && ArraySize(pos) > 0) {
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        if(balance > 0) {
            double maxLossAllowed = balance * (MathAbs(PorcentajeStopLoss) / 100.0);
            if(flotante <= -maxLossAllowed) {
                txtVoz = "STOP LOSS ALCANZADO.";
                CerrarTodo();
                enFaseAnalisis = false;
                if(UsarPausaTrasStopLoss && MinutosPausaTrasStopLoss > 0) {
                    pausaStopLoss = TimeTradeServer() + (60 * MinutosPausaTrasStopLoss);
                    txtVeredicto = "STANDBY POR SL HASTA: " + TimeToString(pausaStopLoss, TIME_MINUTES);
                } else {
                    txtVeredicto = "REINICIANDO TRAS SL";
                }
                BotActivo = true; // Sigue funcionando, no se apaga
                ActualizarInterfazMaster();
                return;
            }
        }
    }



    GestionarCosechaSniper(); ActualizarRadarMaster(); ActualizarInterfazMaster();



    if(!BotActivo) return;

    // Protección Viernes Fin de Semana (Cierre Forzoso de Posiciones Abiertas)
    if(CerrarTodoViernesCierre && ArraySize(pos) > 0) {
        datetime serverTimeNow = TimeTradeServer();
        MqlDateTime t_now;
        TimeToStruct(serverTimeNow, t_now);
        if(t_now.day_of_week == 5 && t_now.hour >= HoraCierreViernes) {
            txtVoz = "CIERRE PREVENTIVO VIERNES FIN DE SEMANA";
            CerrarTodo();
            enFaseAnalisis = false;
            ActualizarInterfazMaster();
            return;
        }
    }

    if(ArraySize(pos) > 0) { GestionarRefuerzoInteligente(); return; }

    if(ArraySize(pos) == 0) {
        datetime serverTime = TimeTradeServer();
        if(serverTime < pausaStopLoss) return;

        string motivoHorario = "";
        if(!EsHorarioPermitido(serverTime, motivoHorario)) return;



        if(!enFaseAnalisis) { enFaseAnalisis = true; proximoAtaque = serverTime + 60; txtVoz = "SCHOLAR: Buscando..."; ActualizarInterfazMaster(); }

        if(serverTime >= proximoAtaque && serverTime >= pausaVolatilidad) {

            string d = ""; if(ValidarEstructuraScholar(d)) EjecutarAtaqueScholar(d);

        }

    }

}



bool ValidarEstructuraScholar(string &decision) {

    if(spreadActual > MaxSpreadPips) { txtVeredicto = "SPD ALTO: " + DoubleToString(spreadActual,1); return false; }

    double rangoM1 = (iHigh(_Symbol, PERIOD_M1, 1) - iLow(_Symbol, PERIOD_M1, 1)) / _Point / 10;

    if(rangoM1 > MaxRangoVelaM1) {

        txtVeredicto = "VOLATILIDAD ALTA (ESPERANDO)"; pausaVolatilidad = TimeTradeServer() + (60 * MinutosPausaTrasSusto); return false;

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

    

    bool rsiOK = (porEncima ? (rsi[0] > 50 && rsi[0] < MaxRsiCompra) : (rsi[0] < 50 && rsi[0] > MinRsiVenta));

    if(!rsiOK) {

        string rsiReason = "";

        if(porEncima) {

            if(rsi[0] <= 50) rsiReason = "RSI > 50 REQ";

            else if(rsi[0] >= MaxRsiCompra) rsiReason = StringFormat("RSI ALTO SOBRECOMPRA (>%.0f)", MaxRsiCompra);

        } else {

            if(rsi[0] >= 50) rsiReason = "RSI < 50 REQ";

            else if(rsi[0] <= MinRsiVenta) rsiReason = StringFormat("RSI BAJO SOBREVENTA (<%.0f)", MinRsiVenta);

        }

        txtVeredicto = StringFormat("P:%.2f EMA:%.2f RSI:%.1f | %s", precio, ema[0], rsi[0], rsiReason);

        return false;

    }



    double c15 = iClose(_Symbol, PERIOD_M15, 1), o15 = iOpen(_Symbol, PERIOD_M15, 1);

    double c5 = iClose(_Symbol, PERIOD_M5, 1), o5 = iOpen(_Symbol, PERIOD_M5, 1);

    bool m15_ok = !CheckM15 || (porEncima ? c15 > o15 : c15 < o15);

    bool m5_ok = !CheckM5 || (porEncima ? c5 > o5 : c5 < o5);

    

    if(!m15_ok) { txtVeredicto = StringFormat("M15 EN CONTRA (C:%.2f O:%.2f)", c15, o15); return false; }

    if(!m5_ok) { txtVeredicto = StringFormat("M5 EN CONTRA (C:%.2f O:%.2f)", c5, o5); return false; }



    decision = (porEncima ? "BUY" : "SELL"); 

    
    
    
    
    
    if(!ValidarTechosSuelos(decision)) return false;
    txtVeredicto = "ESTRUCTURA CONFIRMADA";

    return true;

}



void EjecutarAtaqueScholar(string d) {

    if(TimeTradeServer() - ultimoAtaque < 3) return;

    if(volTotal + (LoteAtaque * RuedasAmetralladora) > MaxLoteTotal) return;

    for(int i=0; i<RuedasAmetralladora; i++) { 

        if(d == "BUY") trade.Buy(LoteAtaque,_Symbol,0,0,0,TradeComment); 

        else trade.Sell(LoteAtaque,_Symbol,0,0,0,TradeComment); 

        Sleep(100); 

    }

    ultimoAtaque = TimeTradeServer();

    enFaseAnalisis = false;

}



void GestionarRefuerzoInteligente() {

    if(ArraySize(pos) >= LimitePosicionesSOS) {

        txtVeredicto = "MAXIMO OPERACIONES ALCANZADO";

        return;

    }

    int last = ArraySize(pos)-1;

    double distPips = MathAbs(SymbolInfoDouble(_Symbol, SYMBOL_BID) - pos[0].pr) / _Point / 10;

    

    // Actualizar HUD dinámicamente con detalles de la operación activa

    string dirStr = (pos[0].t == POSITION_TYPE_BUY) ? "COMPRA" : "VENTA";

    txtVoz = StringFormat("MAIKO: Vigilando %s activo...", dirStr);

    

    if(distPips < DistanciaRefuerzoPips) {

        txtVeredicto = StringFormat("VIGILANDO %s | CONTRA: %.1f pips | SOS a: %.1f", dirStr, distPips, DistanciaRefuerzoPips);

        return;

    }

    

    bool forzar = (distPips >= MaxPipsHueco) || (iBarShift(_Symbol, PERIOD_M1, pos[0].time) >= MaxVelasHueco);

    bool velaGiro = (pos[0].t == POSITION_TYPE_BUY) ? 

                    (iClose(_Symbol, PERIOD_M1, 1) > iOpen(_Symbol, PERIOD_M1, 1) && iClose(_Symbol, PERIOD_M1, 2) > iOpen(_Symbol, PERIOD_M1, 2)) : 

                    (iClose(_Symbol, PERIOD_M1, 1) < iOpen(_Symbol, PERIOD_M1, 1) && iClose(_Symbol, PERIOD_M1, 2) < iOpen(_Symbol, PERIOD_M1, 2));

    

    if(!velaGiro && !forzar) {

        txtVeredicto = StringFormat("ZONA SOS ALCANZADA | ESPERANDO 2 VELAS GIRO M1 (Pips: %.1f)", distPips);

        return;

    }

    

    double volLado = 0; int type = pos[0].t; for(int i=0; i<ArraySize(pos); i++) if(pos[i].t == type) volLado += pos[i].v;

    double volRefuerzo = NormalizeDouble(volLado * (MultiplicadorRefuerzo - 1.0), 2);

    if(volRefuerzo < 0.01) volRefuerzo = 0.01;

    if(volRefuerzo > MaxLoteIndividual) volRefuerzo = MaxLoteIndividual;

    if(volTotal + volRefuerzo > MaxLoteTotal) { txtVoz = "LIMITE LOTE ALCANZADO"; return; }

    

    if(TimeTradeServer() - ultimoAtaque < 3) return;

    if(type == POSITION_TYPE_BUY) trade.Buy(volRefuerzo, _Symbol, 0, 0, 0, TradeComment + "_SOS"); 

    else trade.Sell(volRefuerzo, _Symbol, 0, 0, 0, TradeComment + "_SOS");

    ultimoAtaque = TimeTradeServer();

    txtVeredicto = "DISPARO SOS RESCATE EJECUTADO ????";

}



void GestionarCosechaSniper() { 

    double multCent = EsCuentaCent ? 100.0 : 1.0;

    for(int i=ArraySize(pos)-1; i>=0; i--) {

        if((pos[i].p + pos[i].c + pos[i].s) >= (ProfitCosechaIndividual * multCent)) {

            trade.PositionClose(pos[i].ticket);

        }

    }

}



double CalcularProfit() { double s=0; for(int i=0; i<ArraySize(pos); i++) s += (pos[i].p + pos[i].c + pos[i].s); return s; }



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



void CerrarTodo() { 

    int total = ArraySize(pos);

    if(total == 0) return;

    Print("KOPYTRADING: Iniciando cierre de ", total, " posiciones...");

    for(int i=total-1; i>=0; i--) {

        ulong ticket = pos[i].ticket;

        if(PositionSelectByTicket(ticket)) {

            int retries = 0;

            bool closed = false;

            while(retries < 5 && !closed) {

                if(trade.PositionClose(ticket)) {

                    closed = true;

                    Print("KOPYTRADING: Posicion ", ticket, " cerrada correctamente.");

                } else {

                    retries++;

                    int err = GetLastError();

                    Print("KOPYTRADING: Error al cerrar posicion ", ticket, " (Intento ", retries, "/5). Codigo: ", err);

                    Sleep(200); 

                    ActualizarEstadoMaster();

                }

            }

        }

    }

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



void ActualizarEstadoMaster() { 

    ArrayResize(pos, 0); volTotal = 0; 

    for(int i=PositionsTotal()-1; i>=0; i--) {

        if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == ExpertMagic) { 

            int idx = ArraySize(pos); ArrayResize(pos, idx+1); 

            pos[idx].ticket = PositionGetTicket(i); 

            pos[idx].p = PositionGetDouble(POSITION_PROFIT); 

            pos[idx].c = PositionGetDouble(POSITION_COMMISSION); 

            pos[idx].s = PositionGetDouble(POSITION_SWAP); 

            pos[idx].t = (int)PositionGetInteger(POSITION_TYPE); 

            pos[idx].v = PositionGetDouble(POSITION_VOLUME); 

            pos[idx].time = (datetime)PositionGetInteger(POSITION_TIME); 

            pos[idx].pr = PositionGetDouble(POSITION_PRICE_OPEN); 

            volTotal += pos[idx].v; 

        } 

    } 

}



double CalcularMetaEscapeTP() {

    int totalPos = ArraySize(pos);

    if(totalPos == 0) return 0;

    

    double sumVol = 0;

    double sumPriceVol = 0;

    double sumCommSwap = 0;

    int type = pos[0].t;

    

    for(int i = 0; i < totalPos; i++) {

        sumVol += pos[i].v;

        sumPriceVol += pos[i].pr * pos[i].v;

        sumCommSwap += pos[i].c + pos[i].s;

    }

    

    if(sumVol <= 0) return 0;

    

    double avgPrice = sumPriceVol / sumVol;

    double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);

    if(contractSize <= 0) contractSize = 100.0;

    

    double multCent = EsCuentaCent ? 100.0 : 1.0;

    double targetActual = (totalPos >= LimitePosicionesSOS) ? (ProfitBreakEven * multCent) : (ProfitNetoFlush * multCent);

    

    double priceDiff = (targetActual - sumCommSwap) / (sumVol * contractSize);

    

    double tp = (type == POSITION_TYPE_BUY) ? (avgPrice + priceDiff) : (avgPrice - priceDiff);

    return NormalizeDouble(tp, _Digits);

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

    

    CrearLabel("MAIKO_Vered", x+10, y+75, txtVeredicto, clrCyan, 9, CORNER_LEFT_UPPER); 

    CrearLabel("MAIKO_Bal", x+10, y+98, "BALANCE: $0.00", clrWhite, 12, CORNER_LEFT_UPPER); 

    CrearLabel("MAIKO_Hoy", x+10, y+124, "GANADO HOY: $0.00", clrSpringGreen, 13, CORNER_LEFT_UPPER); 

    CrearLabel("MAIKO_Flot", x+10, y+152, "FLOTANTE: $0.00", clrWhite, 12, CORNER_LEFT_UPPER); 

    CrearLabel("MAIKO_MetaTP", x+10, y+180, "ESTADO: BUSCANDO ENTRADA EN M1...", clrYellow, 10, CORNER_LEFT_UPPER); 

    CrearLabel("MAIKO_TrialUI", x+10, y+208, "TRIAL: DIA 1 DE 30", clrYellow, 10, CORNER_LEFT_UPPER);

    CrearLabel("MAIKO_Spd", x+w-120, y+65, "SPD: 0.0", clrWhite, 8, CORNER_LEFT_UPPER);  

    

    CrearBoton("MAIKO_Foot", x, y+h-40, w, 40, "", ColorHeader, clrNONE, CORNER_LEFT_UPPER); 

    CrearLabel("MAIKO_Voz", x+10, y+h-25, txtVoz, ColorMain, 10, CORNER_LEFT_UPPER); 

    string btnText = BotActivo ? "APAGAR" : "ENCENDER";
    color btnBg = BotActivo ? clrRed : clrDarkGreen;
    CrearBoton("MAIKO_BtnP", x+w-120, y+105, 110, 50, btnText, btnBg, clrWhite, CORNER_LEFT_UPPER); 

    CrearBoton("MAIKO_BtnC", x+w-120, y+168, 110, 35, "CERRAR", clrDarkRed, clrWhite, CORNER_LEFT_UPPER); 

}



void ActualizarInterfazMaster() { 

    double multCent = EsCuentaCent ? 100.0 : 1.0; 
    double balanceActual = AccountInfoDouble(ACCOUNT_BALANCE);

    ObjectSetString(0, "MAIKO_Bal", OBJPROP_TEXT, StringFormat("BALANCE: $%.2f", balanceActual / multCent)); 

    ObjectSetString(0, "MAIKO_Hoy", OBJPROP_TEXT, StringFormat("GANADO HOY: $%.2f", ganadoHoy / multCent)); 

    ObjectSetString(0, "MAIKO_Flot", OBJPROP_TEXT, StringFormat("FLOTANTE: $%.2f", flotante / multCent)); 

    ObjectSetString(0, "MAIKO_Spd", OBJPROP_TEXT, StringFormat("SPD: %.1f", spreadActual)); 

      

      int elapsedSeconds = (int)(TimeCurrent() - trialStart);

      int remainingSeconds = 86400 - (elapsedSeconds % 86400);

      int remHours = remainingSeconds / 3600;

      int remMinutes = (remainingSeconds % 3600) / 60;

      int dOp = (int)((TimeCurrent() - trialStart) / 86400) + 1;

      

      if(trialExpirado) {
          ObjectSetString(0, "MAIKO_TrialUI", OBJPROP_TEXT, "CUENTA DEMO | TRIAL EXPIRADO (30 DIAS)");
          ObjectSetInteger(0, "MAIKO_TrialUI", OBJPROP_COLOR, clrRed);
      } else if(diasRestantes <= 7) {
          ObjectSetString(0, "MAIKO_TrialUI", OBJPROP_TEXT, StringFormat("CUENTA DEMO | EXPIRA EN %d DIAS [%dh %dm] | ADQUIERE REAL", diasRestantes, remHours, remMinutes));
          ObjectSetInteger(0, "MAIKO_TrialUI", OBJPROP_COLOR, C'255,69,0');
      } else {
          ObjectSetString(0, "MAIKO_TrialUI", OBJPROP_TEXT, StringFormat("CUENTA DEMO | TRIAL DIA %d DE 30 [%dh %dm]", dOp, remHours, remMinutes));
          ObjectSetInteger(0, "MAIKO_TrialUI", OBJPROP_COLOR, clrYellow);
      }

    ObjectSetInteger(0, "MAIKO_Flot", OBJPROP_COLOR, flotante >= 0 ? clrSpringGreen : clrRed); 

    ObjectSetString(0, "MAIKO_Vered", OBJPROP_TEXT, txtVeredicto); 

    ObjectSetString(0, "MAIKO_Voz", OBJPROP_TEXT, txtVoz); 

    ObjectSetString(0, "MAIKO_BtnP", OBJPROP_TEXT, BotActivo ? "APAGAR" : "ENCENDER"); 

    ObjectSetInteger(0, "MAIKO_BtnP", OBJPROP_BGCOLOR, BotActivo ? clrRed : clrDarkGreen); 

    

    double metaTP = CalcularMetaEscapeTP();

    if(metaTP > 0) {

        ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, StringFormat("ESCAPE TP: %.2f", metaTP));

    } else {

        ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, "ESTADO: BUSCANDO ENTRADA EN M1...");

    }

    

    // Se ha desactivado el bucle de forzado de timeframe para evitar fliqueos en pantalla,

    // ya que ahora se utiliza CHART_FOREGROUND = false en OnInit() para mantener el HUD siempre delante de las velas de forma nativa.

    ChartRedraw(); 

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

    string objs[] = {"MAIKO_Vered", "MAIKO_Bal", "MAIKO_Hoy", "MAIKO_Flot", "MAIKO_Spd", "MAIKO_Foot", "MAIKO_Voz", "MAIKO_BtnP", "MAIKO_BtnC", "MAIKO_MetaTP", "MAIKO_TrialUI"}; 

    for(int i=0; i<ArraySize(objs); i++) ObjectSetInteger(0, objs[i], OBJPROP_TIMEFRAMES, tf); 

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

            ActualizarTextosEstado();

            ActualizarInterfazMaster();

        }

        if(sparam == "MAIKO_BtnC") { CerrarTodo(); enFaseAnalisis = false; } 

        if(sparam == "MAIKO_BtnMin") { ToggleHUD(); ObjectSetInteger(0, sparam, OBJPROP_STATE, false); } 

        ChartRedraw(); 

    } 

}



void OnTimer() {
    ChartSetInteger(0, CHART_FOREGROUND, false);
    ChartSetInteger(0, CHART_SHOW_TRADE_HISTORY, false);
    ActualizarEstadoMaster();
    ActualizarInterfazMaster();

    int interval = (ArraySize(pos) > 0) ? 15 : 3600;

    if(TimeLocal() - ultimoSync >= interval) {

        EnviarTelemetria();

        ultimoSync = TimeLocal();

    }

}



void EnviarTelemetria() {

    string account = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));

    double balance = AccountInfoDouble(ACCOUNT_BALANCE);

    double equity  = AccountInfoDouble(ACCOUNT_EQUITY);

    

    double divFactor = EsCuentaCent ? 100.0 : 1.0;

    double normBalance = balance / divFactor;

    double normEquity = equity / divFactor;

    double normGanadoHoy = ganadoHoy / divFactor;

    

    string status = BotActivo ? "ONLINE" : "PAUSED";

    int nPos = ArraySize(pos);

    

    string posJson = "[";

    for(int i = 0; i < nPos; i++) {

        if(i > 0) posJson += ",";

        posJson += StringFormat(

            "{\"ticket\":\"%I64u\",\"type\":\"%s\",\"symbol\":\"%s\",\"lots\":%.2f,\"openPrice\":%.5f,\"tp\":%.5f,\"sl\":%.5f,\"profit\":%.2f}",

            pos[i].ticket,

            pos[i].t == POSITION_TYPE_BUY ? "BUY" : "SELL",

            _Symbol, pos[i].v, pos[i].pr, 0.0, 0.0, (pos[i].p + pos[i].c + pos[i].s) / divFactor

        );

    }

    posJson += "]";

    

    string narrative = txtVeredicto;

    StringReplace(narrative, "\"", "'");

    

    string json = StringFormat(

        "{\"purchaseId\":\"%s\",\"account\":\"%s\",\"balance\":%.2f,\"equity\":%.2f,"

        "\"pnl_today\":%.2f,\"status\":\"%s\",\"symbol\":\"%s\",\"narrative\":\"%s\","

        "\"armed\":%s,\"isReal\":%s,\"version\":\"11.32\",\"positions\":%s,"

        "\"trialExpirado\":%s,\"diasRestantes\":%d}",

        MiLicencia, account, normBalance, normEquity,

        normGanadoHoy, status, _Symbol, narrative,

        BotActivo ? "true" : "false", 

        (AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL) ? "true" : "false",

        posJson,

        trialExpirado ? "true" : "false", diasRestantes

    );

    

    char postData[];

    StringToCharArray(json, postData, 0, StringLen(json), CP_UTF8);

    char result[];

    string headers = "Content-Type: application/json\r\n";

    string resHeaders;

    int res = WebRequest("POST", SyncURL, headers, 3000, postData, result, resHeaders);

    

    if(res == 200 && ArraySize(result) > 0) {

        string response = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);

        

        if(StringFind(response, "\"cmd\":\"CLOSE_ALL\"") >= 0) {

            CerrarTodo();

            Print("KOPYTRADING REMOTE: Cierre total ejecutado.");

        }

        

        if(StringFind(response, "\"armed\":true") >= 0) {

            if(!BotActivo) { BotActivo = true; Print("KOPYTRADING REMOTE: Bot ENCENDIDO."); }

        } else if(StringFind(response, "\"armed\":false") >= 0) {

            if(BotActivo) {

                BotActivo = false;

                Print("KOPYTRADING REMOTE: Bot DESACTIVADO (PAUSADO).");

            }

        }

    }

}

bool ValidarTechosSuelos(string decision) {
    double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double point_pips = _Point * 10;
    int start_bar = 1;

    // --- 1. Filtro original M15 ---
    if(UsarFiltroTechosSuelos) {
        int highest_idx = iHighest(_Symbol, TimeframeTechosSuelos, MODE_HIGH, PeriodoTechosSuelos, start_bar);
        int lowest_idx = iLowest(_Symbol, TimeframeTechosSuelos, MODE_LOW, PeriodoTechosSuelos, start_bar);
        if(highest_idx >= 0 && lowest_idx >= 0) {
            double highest_high = iHigh(_Symbol, TimeframeTechosSuelos, highest_idx);
            double lowest_low = iLow(_Symbol, TimeframeTechosSuelos, lowest_idx);
            
            if(decision == "BUY") {
                double dist_to_ceiling = (highest_high - current_price) / point_pips;
                if(dist_to_ceiling > 0) {
                    if(dist_to_ceiling <= DistanciaTechoSueloPips) {
                        txtVeredicto = StringFormat("TECHO M15 CERCANO (%.1f pips)", dist_to_ceiling);
                        return false;
                    }
                } else {
                    if(UsarConfirmacionRuptura) {
                        double closeVal = iClose(_Symbol, TimeframeConfirmacion, 1);
                        if(closeVal <= highest_high) {
                            txtVeredicto = "ESPERANDO CONFIRMACION RUPTURA TECHO M15";
                            return false;
                        }
                    }
                }
            }
            else if(decision == "SELL") {
                double dist_to_floor = (current_price - lowest_low) / point_pips;
                if(dist_to_floor > 0) {
                    if(dist_to_floor <= DistanciaTechoSueloPips) {
                        txtVeredicto = StringFormat("SUELO M15 CERCANO (%.1f pips)", dist_to_floor);
                        return false;
                    }
                } else {
                    if(UsarConfirmacionRuptura) {
                        double closeVal = iClose(_Symbol, TimeframeConfirmacion, 1);
                        if(closeVal >= lowest_low) {
                            txtVeredicto = "ESPERANDO CONFIRMACION RUPTURA SUELO M15";
                            return false;
                        }
                    }
                }
            }
        }
    }

    // --- 2. Filtro H1 ---
    if(UsarFiltroTechosSuelosH1) {
        int highest_idx = iHighest(_Symbol, PERIOD_H1, MODE_HIGH, PeriodoTechosSuelosH1, start_bar);
        int lowest_idx = iLowest(_Symbol, PERIOD_H1, MODE_LOW, PeriodoTechosSuelosH1, start_bar);
        if(highest_idx >= 0 && lowest_idx >= 0) {
            double highest_high = iHigh(_Symbol, PERIOD_H1, highest_idx);
            double lowest_low = iLow(_Symbol, PERIOD_H1, lowest_idx);
            
            if(decision == "BUY") {
                double dist_to_ceiling = (highest_high - current_price) / point_pips;
                if(dist_to_ceiling > 0) {
                    if(dist_to_ceiling <= DistanciaTechoSueloPipsH1) {
                        txtVeredicto = StringFormat("TECHO H1 CERCANO (%.1f pips)", dist_to_ceiling);
                        return false;
                    }
                } else {
                    if(UsarConfirmacionRuptura) {
                        double closeVal = iClose(_Symbol, TimeframeConfirmacion, 1);
                        if(closeVal <= highest_high) {
                            txtVeredicto = "ESPERANDO CONFIRMACION RUPTURA TECHO H1";
                            return false;
                        }
                    }
                }
            }
            else if(decision == "SELL") {
                double dist_to_floor = (current_price - lowest_low) / point_pips;
                if(dist_to_floor > 0) {
                    if(dist_to_floor <= DistanciaTechoSueloPipsH1) {
                        txtVeredicto = StringFormat("SUELO H1 CERCANO (%.1f pips)", dist_to_floor);
                        return false;
                    }
                } else {
                    if(UsarConfirmacionRuptura) {
                        double closeVal = iClose(_Symbol, TimeframeConfirmacion, 1);
                        if(closeVal >= lowest_low) {
                            txtVeredicto = "ESPERANDO CONFIRMACION RUPTURA SUELO H1";
                            return false;
                        }
                    }
                }
            }
        }
    }

    // --- 3. Filtro H4 ---
    if(UsarFiltroTechosSuelosH4) {
        int highest_idx = iHighest(_Symbol, PERIOD_H4, MODE_HIGH, PeriodoTechosSuelosH4, start_bar);
        int lowest_idx = iLowest(_Symbol, PERIOD_H4, MODE_LOW, PeriodoTechosSuelosH4, start_bar);
        if(highest_idx >= 0 && lowest_idx >= 0) {
            double highest_high = iHigh(_Symbol, PERIOD_H4, highest_idx);
            double lowest_low = iLow(_Symbol, PERIOD_H4, lowest_idx);
            
            if(decision == "BUY") {
                double dist_to_ceiling = (highest_high - current_price) / point_pips;
                if(dist_to_ceiling > 0) {
                    if(dist_to_ceiling <= DistanciaTechoSueloPipsH4) {
                        txtVeredicto = StringFormat("TECHO H4 CERCANO (%.1f pips)", dist_to_ceiling);
                        return false;
                    }
                } else {
                    if(UsarConfirmacionRuptura) {
                        double closeVal = iClose(_Symbol, TimeframeConfirmacion, 1);
                        if(closeVal <= highest_high) {
                            txtVeredicto = "ESPERANDO CONFIRMACION RUPTURA TECHO H4";
                            return false;
                        }
                    }
                }
            }
            else if(decision == "SELL") {
                double dist_to_floor = (current_price - lowest_low) / point_pips;
                if(dist_to_floor > 0) {
                    if(dist_to_floor <= DistanciaTechoSueloPipsH4) {
                        txtVeredicto = StringFormat("SUELO H4 CERCANO (%.1f pips)", dist_to_floor);
                        return false;
                    }
                } else {
                    if(UsarConfirmacionRuptura) {
                        double closeVal = iClose(_Symbol, TimeframeConfirmacion, 1);
                        if(closeVal >= lowest_low) {
                            txtVeredicto = "ESPERANDO CONFIRMACION RUPTURA SUELO H4";
                            return false;
                        }
                    }
                }
            }
        }
    }

    // --- 4. Filtro de Agotamiento de Velas (Rechazo de Mecha M15) ---
    if(UsarFiltroAgotamientoM15) {
        double open15 = iOpen(_Symbol, PERIOD_M15, 1);
        double close15 = iClose(_Symbol, PERIOD_M15, 1);
        double high15 = iHigh(_Symbol, PERIOD_M15, 1);
        double low15 = iLow(_Symbol, PERIOD_M15, 1);
        
        double totalRange = high15 - low15;
        if(totalRange > 0) {
            if(decision == "BUY") {
                double upperWick = high15 - MathMax(open15, close15);
                double wickRatio = (upperWick / totalRange) * 100.0;
                if(wickRatio >= MinPorcentajeMechaM15) {
                    txtVeredicto = StringFormat("MECHA ALTA M15 RECHAZO (%.1f%%)", wickRatio);
                    return false;
                }
            }
            else if(decision == "SELL") {
                double lowerWick = MathMin(open15, close15) - low15;
                double wickRatio = (lowerWick / totalRange) * 100.0;
                if(wickRatio >= MinPorcentajeMechaM15) {
                    txtVeredicto = StringFormat("MECHA BAJA M15 RECHAZO (%.1f%%)", wickRatio);
                    return false;
                }
            }
        }
    }

    return true;
}



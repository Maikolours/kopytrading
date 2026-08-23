//+------------------------------------------------------------------+

//|            ELITE GOLD MAIKO SNIPER V13.00 | DUAL ENGINE          |

//|       "INSTITUTIONAL EDITION" | FIX FINAL SIN PUNTOS            |

//+------------------------------------------------------------------+

//| Restored for Gold/Normal version - behaving 100% like original  |

//+------------------------------------------------------------------+

#property copyright "Elite Gold MAIKO Sniper"

#property version   "13.00"

#property strict



#include <Trade\Trade.mqh>

// --- CONFIGURACION ---
input group "━━━━━━ 🔑 𝗟 𝗜 𝗖 𝗘 𝗡 𝗖 𝗜 𝗔   𝗗 𝗘   𝗖 𝗢 𝗡 𝗘 𝗫 𝗜 𝗢 𝗡 ━━━━━━"
input string   MiLicencia                 = "";          // 🔑 Clave de Licencia o Correo Usuario
input int      DiasDeTrial                = 30;          // ⏳ Días de Prueba (Solo Trial)
const bool     EsCuentaCent               = false;       // Cuenta en Centavos (Hardcoded para seguridad)

// --- TELEMETRIA ---
string SyncURL = "https://www.kopytrading.com/api/sync-positions";
int SyncIntervalSec = 2;
datetime ultimoSync = 0;

// --- FILTROS DE RUIDO Y MERCADO ---
input group "━━━━━━ 🛡️ 𝗙 𝗜 𝗟 𝗧 𝗥 𝗢 𝗦   𝗗 𝗘   𝗥 𝗨 𝗜 𝗗 𝗢   𝗬   𝗠 𝗘 𝗥 𝗖 𝗔 𝗗 𝗢 ━━━━━━"
input double   MaxRangoVelaM1             = 1000.0;        // ⚡ Rango Máximo Vela M1 (Pips)
input double   MaxSpreadPips              = 4.0;         // 📊 Spread Máximo Permitido (Pips)
input double   SensibilidadMechaReal      = 3.0;         // ⚖️ Sensibilidad Rechazo de Mechas
input int      MinutosPausaTrasSusto      = 1;           // ⏱️ Minutos Pausa tras Vela Extrema
input double   MaxRsiCompra               = 70.0;        // 📉 RSI Máximo para Compras (Filtro Techos)
input double   MinRsiVenta                = 30.0;        // 📈 RSI Mínimo para Ventas (Filtro Suelos)
input double   UmbralADXTendencia         = 50.0;        // 📊 Nivel ADX para Considerar Tendencia Fuerte
input double   AnchoMinimoEmbudo          = 30.0;        // 🎯 Ancho Mínimo Bandas Bollinger Ping-Pong (Pips)

// --- FILTRO DE TECHOS Y SUELOS (SOPORTES Y RESISTENCIAS) ---
input group "━━━━━━ 🏛️ 𝗙 𝗜 𝗟 𝗧 𝗥 𝗢   𝗗 𝗘   𝗧 𝗘 𝗖 𝗛 𝗢 𝗦   𝗬   𝗦 𝗨 𝗘 𝗟 𝗢 𝗦 ━━━━━━"
input bool             UsarFiltroTechosSuelos     = true;        // 🏛️ Activar Filtro Techos y Suelos M15 (S/R)
input ENUM_TIMEFRAMES  TimeframeTechosSuelos      = PERIOD_M15;  // 📅 Temporalidad para Techos/Suelos M15
input int              PeriodoTechosSuelos        = 24;          // 🔢 Período de Velas M15 a Analizar
input double           DistanciaTechoSueloPips    = 15.0;        // 📏 Distancia Mínima M15 para Bloquear (Pips)

// --- FILTROS ADICIONALES MULTI-TEMPORALIDAD (H1 y H4) ---
input bool             UsarFiltroTechosSuelosH1   = true;        // 📊 Activar Filtro S/R en H1
input int              PeriodoTechosSuelosH1      = 24;          // 📅 Período H1 a Analizar (Velas)
input double           DistanciaTechoSueloPipsH1  = 30.0;        // 📅 Distancia Mínima H1 (Pips)

input bool             UsarFiltroTechosSuelosH4   = true;        // 📊 Activar Filtro S/R en H4
input int              PeriodoTechosSuelosH4      = 24;          // 📅 Período H4 a Analizar (Velas)
input double           DistanciaTechoSueloPipsH4  = 50.0;        // 📅 Distancia Mínima H4 (Pips)

// --- FILTRO DE AGOTAMIENTO DE VELAS (RECHAZO DE MECHA M15) ---
input bool             UsarFiltroAgotamientoM15   = true;        // 🕯️ Activar Filtro Agotamiento M15
input double           MinPorcentajeMechaM15      = 40.0;        // 🕯️ % Mínimo Mecha Reversa (40.0 = 40%)

// --- CONFIRMACION DE RUPTURA ---
input bool             UsarConfirmacionRuptura    = true;        // 📈 Confirmar Ruptura de S/R con Vela Cerrada
input ENUM_TIMEFRAMES  TimeframeConfirmacion      = PERIOD_M5;   // 📅 Temporalidad de Confirmación (M5/M15)

// --- TENDENCIA Y DIRECCION ---
input group "━━━━━━ 📉 𝗧 𝗘 𝗡 𝗗 𝗘 𝗡 𝗖 𝗜 𝗔   𝗬   𝗗 𝗜 𝗥 𝗘 𝗖 𝗖 𝗜 𝗢 𝗡 ━━━━━━"
input int      PeriodoMediaFiltro         = 50;          // 🔗 Período EMA Tendencia (Filtro)
input bool     CheckM15                   = true;        // 📅 Confirmación Tendencia M15 (Sincronía)
input bool     CheckM5                    = true;        // 📅 Confirmación Tendencia M5 (Sincronía)

// --- OPERATIVA Y LOTES ---
input group "━━━━━━ 📈 𝗖 𝗢 𝗡 𝗙 𝗜 𝗚 𝗨 𝗥 𝗔 𝗖 𝗜 𝗢 𝗡   𝗬   𝗟 𝗢 𝗧 𝗘 𝗦 ━━━━━━"
input double   LoteAtaque                 = 0.01;        // 🚀 Volumen Entrada Inicial (Ataque)
input int      RuedasAmetralladora        = 1;           // 🔫 Operaciones Iniciales en Cesta (Ruedas)
input double   MultiplicadorRefuerzo      = 1.5;         // ✖️ Multiplicador Lote de Rescate (SOS)
input double   MaxLoteTotal               = 0.50;        // 🚫 Lote Máximo Acumulado Permitido
input double   MaxLoteIndividual          = 0.02;        // 🚫 Volumen Máximo por Operación SOS

// --- DISTANCIAS Y CASCADA ---
input group "━━━━━━ 📏 𝗗 𝗜 𝗦 𝗧 𝗔 𝗡 𝗖 𝗜 𝗔 𝗦   𝗬   𝗖 𝗔 𝗦 𝗖 𝗔 𝗗 𝗔 ━━━━━━"
input double   DistanciaRefuerzoPips      = 30.0;        // 📏 Distancia Mínima para Abrir SOS (Pips)
input double   MaxPipsHueco               = 50.0;        // 🕳️ Pips de Vacío para Forzar SOS
input int      MaxVelasHueco              = 5;           // ⏳ Velas sin Giro para Forzar SOS

// --- COBRAR BENEFICIOS (TAKE PROFIT) ---
input group "━━━━━━ 💰 𝗖 𝗢 𝗕 𝗥 𝗔 𝗥   𝗕 𝗘 𝗡 𝗘 𝗙 𝗜 𝗖 𝗜 𝗢 𝗦   ( 𝗧 𝗣 ) ━━━━━━"
input double   ProfitNetoFlush            = 5.0;         // 💵 Beneficio Cierre Total Cesta ($)
input double   ProfitCosechaIndividual    = 0.75;        // 💵 Beneficio Cierre SOS Individual ($)
input double   TargetDiario               = 25.0;        // 🎯 Meta de Beneficio Diario ($)

// --- HORARIOS OPERATIVOS ---
input group "━━━━━━ ⏰ 𝗛 𝗢 𝗥 𝗔 𝗥 𝗜 𝗢 𝗦   𝗢 𝗣 𝗘 𝗥 𝗔 𝗧 𝗜 𝗩 𝗢 𝗦 ━━━━━━"
input int      HoraInicioOperativa        = 1;           // 🔔 Hora de Inicio Operaciones (Broker)
input int      HoraFinOperativa           = 23;          // 🔕 Hora de Cierre Operaciones (Broker)
input bool     OperarViernesNoche         = false;       // 🌃 Permitir Operaciones Viernes Noche
input bool     UsarHorarioBloqueo         = false;       // 🛑 Evitar Noticias (Bloqueo Horario)
input int      HoraInicioBloqueo          = 14;          // 🛑 Hora Inicio Bloqueo Noticias
input int      HoraFinBloqueo             = 16;          // 🛑 Hora Fin Bloqueo Noticias

// --- PROTECCIONES Y SEGURIDAD ---
input group "━━━━━━ 🛡️ 𝗣 𝗥 𝗢 𝗧 𝗘 𝗖 𝗖 𝗜 𝗢 𝗡 𝗘 𝗦   𝗬   𝗦 𝗘 𝗚 𝗨 𝗥 𝗜 𝗗 𝗔 𝗗 ━━━━━━"
input int      LimitePosicionesSOS        = 2;           // 🛡️ Límite Máximo Posiciones SOS
input double   ProfitBreakEven            = 0.50;        // 🛡️ Beneficio Mínimo Break Even Cesta ($)
input double   ProteccionBeneficioDiario  = 0.0;         // 🛡️ Proteger Beneficio Diario Acumulado ($)
input bool     UsarStopLossPorcentaje     = false;       // 🚨 Activar Stop Loss por % Cuenta
input double   PorcentajeStopLoss         = 10.0;        // 🚨 Porcentaje de Pérdida Máxima (%)
input bool     UsarPausaTrasStopLoss      = false;       // ⏳ Pausar Bot tras un Stop Loss
input int      MinutosPausaTrasStopLoss   = 10;          // ⏳ Minutos de Pausa tras Stop Loss

// --- HORARIO BLOQUEO INTERNO ---
input bool     UsarHorarioBloqueo_Interno = false;
input int      HoraInicioBloqueo_Interno  = 14;
input int      HoraFinBloqueo_Interno     = 16;

// --- INTERFAZ GRAFICA (HUD) ---
input group "━━━━━━ 🎨 𝗜 𝗡 𝗧 𝗘 𝗥 𝗙 𝗔 𝗭   𝗚 𝗥 𝗔 𝗙 𝗜 𝗖 𝗔   ( 𝗛 𝗨 𝗗 ) ━━━━━━"
string         HUD_Branding               = "MAIKO V13 | DUAL ENGINE";
input color    ColorMain                  = clrGold;     // 🎨 Color Principal HUD (Acento)
input color    ColorHeader                = C'30,30,30'; // 🎨 Color Encabezado Panel HUD
input color    ColorBody                  = C'20,20,20'; // 🎨 Color Cuerpo Panel HUD
input int      HUD_X                      = 15;          // 📍 Posición X en Pantalla (Pixeles)
input int      PosY_HUD                   = 25;          // 📍 Posición Y en Pantalla (Pixeles)
input bool     ShowW1                     = true;        // 📅 Mostrar Tendencia W1
input bool     ShowD1                     = true;        // 📅 Mostrar Tendencia D1
input bool     ShowH4                     = true;        // 📅 Mostrar Tendencia H4
input bool     ShowH1                     = true;        // 📅 Mostrar Tendencia H1
input bool     ShowM15                    = true;        // 📅 Mostrar Tendencia M15
input bool     ShowM5                     = true;        // 📅 Mostrar Tendencia M5
input bool     ShowM1                     = true;        // 📅 Mostrar Tendencia M1

// --- COMENTARIOS DE OPERACIONES ---
input group "━━━━━━ 📝 𝗖 𝗢 𝗠 𝗘 𝗡 𝗧 𝗔 𝗥 𝗜 𝗢 𝗦   𝗗 𝗘   𝗧 𝗥 𝗔 𝗗 𝗜 𝗡 𝗚 ━━━━━━"
input string   TradeComment               = "V13_SHIELD_DEMO";        // 🏷️ Comentario para órdenes (Trade Comment)


input group "━━━━━━ ⚙️ MOTOR DUAL & SEGURIDAD ━━━━━━"
input long     MagicTendencia             = 888888;      // 🔑 DNI Motor Tendencia
input long     MagicRango                 = 999990;      // 🔑 DNI Motor Scalping Rango
input double   MaxDrawdownPorcentaje      = 5.0;         // 🛡️ Límite Max Drawdown % (Bloqueo Rango)

input group "━━━━━━ 🎯 MOTOR SCALPING DE RANGO ━━━━━━"
input bool     EnableRango                = true;        // 🔛 Activar Scalping Rango
input double   LoteRango                  = 0.01;        // 🚀 Lote Scalping Rango
input double   StopLossRangoPips          = 0.0;        // 🚨 Stop Loss (Pips) Rango

input group "??   O P C I O N E S   T R A I L I N   S T O P   ??"
input bool     UsarTrailingStop           = true;        // ?? Activar Trailing Stop (Tendencia)
input double   TrailingStopTendenciaPips  = 15.0;        // ?? Trailing Stop Distancia (Pips)
input double   TakeProfitRangoPips        = 0.0;         // 💰 Take Profit (Pips) Rango
input int      VelasDormidasM15           = 3;           // ⏳ Velas M15 "Dormidas" para confirmar

// Globales

CTrade tradeTendencia;
CTrade tradeRango;
double flotanteTendencia = 0, flotanteRango = 0;
double ganadoHoyTendencia = 0, ganadoHoyRango = 0;
bool modoRangoBloqueado = false;

struct PosInfo { ulong ticket; double p; double c; double s; int t; double v; datetime time; double pr; };
PosInfo posTendencia[];
PosInfo posRango[];
double volTotalTendencia = 0;
double volTotalRango = 0;

bool BotActivo = false;

bool hudMinimizado = false;

datetime ultimoAtaque = 0;

string txtVoz = "SCHOLAR: Escaneando...";

string txtVeredicto = "ESPERANDO...";
string txtMacro = "ESPERANDO...";
bool surfeandoTendencia = false;

datetime proximoAtaque = 0, pausaVolatilidad = 0, pausaStopLoss = 0;

bool enFaseAnalisis = false;

int FaseRefuerzo = 0;

datetime trialStart = 0;

int diasRestantes = 30;

bool trialExpirado = false;



ulong ticketExplorador = 0;

int hEMA_v = INVALID_HANDLE;
int hRSI_v = INVALID_HANDLE;
int hRSI_H1 = INVALID_HANDLE;
int hRSI_H4 = INVALID_HANDLE;

int hRadar[7];

ENUM_TIMEFRAMES etfs[]={PERIOD_W1,PERIOD_D1,PERIOD_H4,PERIOD_H1,PERIOD_M15,PERIOD_M5,PERIOD_M1};



void AgregarIndicadoresVisuales() {
    bool tieneEMA = false;
    bool tieneRSI = false;
    bool tieneMACD = false;
    bool tieneBands = false;
    bool tieneATR = false;
    bool tieneADX = false;

    int ventanas = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL);
    for(int w = 0; w < ventanas; w++) {
        int totalInd = ChartIndicatorsTotal(0, w);
        for(int i = 0; i < totalInd; i++) {
            string nombre = ChartIndicatorName(0, w, i);
            if(StringFind(nombre, IntegerToString(PeriodoMediaFiltro)) >= 0 && (StringFind(nombre, "MA") >= 0 || StringFind(nombre, "EMA") >= 0)) tieneEMA = true;
            if(StringFind(nombre, "RSI") >= 0 && StringFind(nombre, "14") >= 0) tieneRSI = true;
            if(StringFind(nombre, "MACD") >= 0) tieneMACD = true;
            if(StringFind(nombre, "Bands") >= 0) tieneBands = true;
            if(StringFind(nombre, "ATR") >= 0) tieneATR = true;
            if(StringFind(nombre, "ADX") >= 0) tieneADX = true;
        }
    }

    if(!tieneEMA) ChartIndicatorAdd(0, 0, hEMA_v);
    if(!tieneBands) {
        int hBands = iBands(_Symbol, PERIOD_M15, 20, 0, 2.0, PRICE_CLOSE);
        if(hBands != INVALID_HANDLE) ChartIndicatorAdd(0, 0, hBands);
    }
    if(!tieneRSI) ChartIndicatorAdd(0, (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL), hRSI_v);
    if(!tieneMACD) {
        int hMACD = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE);
        if(hMACD != INVALID_HANDLE) ChartIndicatorAdd(0, (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL), hMACD);
    }
    if(!tieneADX) {
        int hADX = iADX(_Symbol, PERIOD_M15, 14);
        if(hADX != INVALID_HANDLE) ChartIndicatorAdd(0, (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL), hADX);
    }
    if(!tieneATR) {
        int hATR = iATR(_Symbol, PERIOD_M15, 14);
        if(hATR != INVALID_HANDLE) ChartIndicatorAdd(0, (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL), hATR);
    }
}



int OnInit() {

    if(AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL) {

        Alert("MAIKO SNIPER: TRIAL SÓLO VÁLIDO PARA CUENTAS DEMO.");

        return INIT_FAILED;

    }

    

    // El límite se aplica en CheckTrial para evitar error de constante

        

    tradeTendencia.SetExpertMagicNumber(MagicTendencia);
    tradeTendencia.SetAsyncMode(true);
    tradeRango.SetExpertMagicNumber(MagicRango);
    tradeRango.SetAsyncMode(true);

    hEMA_v = iMA(_Symbol, _Period, PeriodoMediaFiltro, 0, MODE_EMA, PRICE_CLOSE);
    hRSI_v = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
    hRSI_H1 = iRSI(_Symbol, PERIOD_H1, 14, PRICE_CLOSE);
    hRSI_H4 = iRSI(_Symbol, PERIOD_H4, 14, PRICE_CLOSE);

    

    // Inicializar handles de radar de forma estática para optimizar CPU

    for(int i=0; i<7; i++) {

        hRadar[i] = iMA(_Symbol, etfs[i], PeriodoMediaFiltro, 0, MODE_EMA, PRICE_CLOSE);

    }

    

    AgregarIndicadoresVisuales();

    CrearInterfazMaster();

    ChartSetInteger(0, CHART_FOREGROUND, false); ChartSetInteger(0, CHART_SHOW_TRADE_HISTORY, false);

      

    string gvName = "MAIKO_V13_TRIAL_" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));

    if(GlobalVariableCheck(gvName)) {

        trialStart = (datetime)GlobalVariableGet(gvName);

    } else {

        trialStart = TimeCurrent();

        GlobalVariableSet(gvName, (double)trialStart);

    }

      int maxDias = DiasDeTrial;

      if(maxDias > 30) maxDias = 30;

      diasRestantes = maxDias - (int)((TimeCurrent() - trialStart) / 86400);

      int diasOperando = (int)((TimeCurrent() - trialStart) / 86400) + 1;

      if(diasRestantes <= 0) { trialExpirado = true; BotActivo = false; }

    

    if(MQLInfoInteger(MQL_TESTER)) BotActivo = true;

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



void ActualizarTextosEstado() {

    int maxDias = DiasDeTrial;

    if(maxDias > 30) maxDias = 30;

    diasRestantes = maxDias - (int)((TimeTradeServer() - trialStart) / 86400);

    if(diasRestantes <= 0) { trialExpirado = true; BotActivo = false; }



    if(trialExpirado) {

        txtVoz = "TRIAL 30 DIAS EXPIRADO.";

        txtVeredicto = "EXPIRADO";

        return;

    }



    if(!BotActivo) {

        txtVoz = "SCHOLAR: SISTEMA EN PAUSA";

        txtVeredicto = "STANDBY (OFF)";

        return;

    } else if (txtVeredicto == "STANDBY (OFF)") { txtVeredicto = "ANALIZANDO..."; txtVoz = "SCHOLAR: ANALIZANDO..."; }



    ActualizarEstadoMaster();

    if(ArraySize(posTendencia) + ArraySize(posRango) > 0) {

        txtVoz = "MAIKO: Vigilando posiciones activas...";

        return;

    }



    datetime serverTime = TimeTradeServer();

    if(serverTime < pausaStopLoss) {

        txtVoz = "STANDBY POST-SL (" + IntegerToString((int)((pausaStopLoss - serverTime) / 60) + 1) + " MIN)";

        txtVeredicto = "STANDBY SL";

        return;

    }



    MqlDateTime time;

    TimeToStruct(serverTime, time);



    // Validar fin de semana

    bool esFinDeSemana = (time.day_of_week == 0 || time.day_of_week == 6);

    // Validar viernes noche (después de las 19:00, salvo que se permita operar)

    bool esViernesNoche = (time.day_of_week == 5 && time.hour >= 19 && !OperarViernesNoche);

    

    bool enHorario = true;

    if(time.hour < HoraInicioOperativa || time.hour >= HoraFinOperativa) enHorario = false;

    if(esFinDeSemana || esViernesNoche) enHorario = false;



    bool enBloqueoNoticias = (UsarHorarioBloqueo && time.hour >= HoraInicioBloqueo && time.hour < HoraFinBloqueo);

    if(enBloqueoNoticias) enHorario = false;



    if(!enHorario) {

        if(esFinDeSemana || esViernesNoche) {

            txtVoz = "FUERA HORARIO: MERCADO CERRADO";

            txtVeredicto = "ARMADO (FUERA DE HORARIO)";

        } else if(enBloqueoNoticias) {

            txtVoz = "HORARIO BLOQUEADO (NOTICIAS)";

            txtVeredicto = "STANDBY NOTICIAS";

        } else {

            txtVoz = "FUERA HORARIO: ESPERANDO";

            txtVeredicto = "ARMADO (FUERA DE HORARIO)";

        }

        } else {
        // --- DETECCION CONTINUA DE FILTROS PARA EL HUD ---
        txtVoz = "SCHOLAR: Analizando Price Action";
    }

}



void AnalizarMacroContexto() {
    double adx[1];
    int hADX = iADX(_Symbol, PERIOD_M15, 14);
    if(CopyBuffer(hADX, 0, 1, 1, adx) <= 0) return;
    
    double macd[1];
    int hMACD = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE);
    if(CopyBuffer(hMACD, 0, 1, 1, macd) <= 0) return;
    
    if(adx[0] > UmbralADXTendencia) {
        if(macd[0] > 0) {
            txtMacro = "MACRO: TENDENCIA ALCISTA (ADX FUERTE | MACD +)";
            surfeandoTendencia = true;
        } else {
            txtMacro = "MACRO: TENDENCIA BAJISTA (ADX FUERTE | MACD -)";
            surfeandoTendencia = true;
        }
    } else {
        txtMacro = StringFormat("MACRO: LATERAL PING-PONG (ADX DEBIL: %.1f)", adx[0]);
        surfeandoTendencia = false;
    }
}

void OnTick() {
    AnalizarMacroContexto();
    ActualizarTextosEstado();

    if(trialExpirado) { BotActivo = false; ActualizarInterfazMaster(); return; }

    if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) { txtVoz = "TRADING NO PERMITIDO"; return; }



    ActualizarEstadoMaster();

    ganadoHoyTendencia = CalcularGanadoHoy(); // Global variable is updated inside

    flotanteTendencia = CalcularProfit(); // Global variables updated inside



    double multCent = EsCuentaCent ? 100.0 : 1.0;

    double targetActual = (ArraySize(posTendencia) + ArraySize(posRango) >= LimitePosicionesSOS) ? (ProfitBreakEven * multCent) : (ProfitNetoFlush * multCent);

    

    if(ArraySize(posTendencia) + ArraySize(posRango) > 0 && flotanteTendencia + flotanteRango >= targetActual) {
        if(surfeandoTendencia) {
            txtVoz = "SURFEANDO TENDENCIA (ESPERANDO AGOTAMIENTO)";
        } else {
            txtVoz = "CIERRE NETO ALCANZADO."; CerrarTodo(); enFaseAnalisis = false; return;
        }
    }

    if(ganadoHoyTendencia + ganadoHoyRango >= (TargetDiario * multCent)) {

        txtVoz = "OBJETIVO DIARIO CUMPLIDO."; if(ArraySize(posTendencia) + ArraySize(posRango) > 0) CerrarTodo(); BotActivo = false; ActualizarInterfazMaster(); return;

    }

    if(ProteccionBeneficioDiario > 0.0 && (ganadoHoyTendencia + ganadoHoyRango) > (ProteccionBeneficioDiario * multCent)) {

        if((ganadoHoyTendencia + ganadoHoyRango + flotanteTendencia + flotanteRango) <= (ProteccionBeneficioDiario * multCent) && (ArraySize(posTendencia) + ArraySize(posRango) > 0)) {

            txtVoz = "PROTECCION BENEFICIO."; CerrarTodo(); enFaseAnalisis = false; BotActivo = false; ActualizarInterfazMaster(); return;

        }

    }



    if(UsarStopLossPorcentaje && (ArraySize(posTendencia) + ArraySize(posRango) > 0)) {

        double balance = AccountInfoDouble(ACCOUNT_BALANCE);

        if(balance > 0) {

            double maxLossAllowed = balance * (MathAbs(PorcentajeStopLoss) / 100.0);

            if(flotanteTendencia + flotanteRango <= -maxLossAllowed) {

                txtVoz = "STOP LOSS ALCANZADO.";

                CerrarTodo();

                enFaseAnalisis = false;

                if(UsarPausaTrasStopLoss && MinutosPausaTrasStopLoss > 0) {

                    pausaStopLoss = TimeTradeServer() + (60 * MinutosPausaTrasStopLoss);

                    txtVeredicto = "STANDBY POR SL HASTA: " + TimeToString(pausaStopLoss, TIME_MINUTES);

                } else {

                    BotActivo = false;

                }

                ActualizarInterfazMaster();

                return;

            }

        }

    }



    GestionarCosechaSniper();
    if(UsarTrailingStop) GestionarTrailingStopTendencia();
    GestionarSalidasDinamicasRango(); ActualizarRadarMaster(); ActualizarInterfazMaster();



    if(!BotActivo) return;

    if(ArraySize(posTendencia) > 0) { GestionarRefuerzoInteligente(); return; }

    if(ArraySize(posTendencia) + ArraySize(posRango) == 0) {

        datetime serverTime = TimeTradeServer();

        if(serverTime < pausaStopLoss) return;



        MqlDateTime time;

        TimeToStruct(serverTime, time);

        bool enHorario = true;

        if(time.hour < HoraInicioOperativa || time.hour >= HoraFinOperativa) enHorario = false;

        if(time.day_of_week == 5 && time.hour >= 19 && !OperarViernesNoche) enHorario = false;

        if(time.day_of_week == 0 || time.day_of_week == 6) enHorario = false;

        

        if(UsarHorarioBloqueo && time.hour >= HoraInicioBloqueo && time.hour < HoraFinBloqueo) enHorario = false;



        if(!enHorario) return;



        if(!enFaseAnalisis) { enFaseAnalisis = true; proximoAtaque = serverTime + 60; txtVoz = "SCHOLAR: Buscando..."; ActualizarInterfazMaster(); }

        if(serverTime >= proximoAtaque && serverTime >= pausaVolatilidad) {
            bool evalTrend = false;
            bool evalRange = false;
            
            if(ArraySize(posTendencia) == 0) evalTrend = true;
            if(EnableRango && ArraySize(posRango) == 0) {
                double balance = AccountInfoDouble(ACCOUNT_BALANCE);
                double maxLossAllowed = balance * (MathAbs(MaxDrawdownPorcentaje) / 100.0);
                if(flotanteTendencia <= -maxLossAllowed) {
                    evalRange = false;
                    txtVoz = "RANGO BLOQUEADO (MARGEN)";
                } else {
                    evalRange = true;
                }
            }
            
            string dTrend = "";
            string dRange = "";
            if(surfeandoTendencia) {
                if(evalTrend && ValidarEstructuraTendencia(dTrend)) EjecutarAtaqueTendencia(dTrend);
            } else {
                if(evalRange && ValidarEstructuraRango(dRange)) EjecutarAtaqueRango(dRange);
            }
        }

    }

}




bool ValidarEstructuraTendencia(string &decision) {
    if(((double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD)/10.0) > MaxSpreadPips) { txtVeredicto = "SPD ALTO: " + DoubleToString(((double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD)/10.0),1); return false; }
    double rangoM1 = (iHigh(_Symbol, PERIOD_M1, 1) - iLow(_Symbol, PERIOD_M1, 1)) / _Point / 10;
    if(rangoM1 > 1000.0) {
        txtVeredicto = "VOLATILIDAD ALTA (ESPERANDO)"; pausaVolatilidad = TimeTradeServer() + (60 * MinutosPausaTrasSusto); return false;
    }
    double body = MathAbs(iOpen(_Symbol, PERIOD_M1, 1) - iClose(_Symbol, PERIOD_M1, 1)) / _Point / 10;
    if(body < 0.5) { txtVeredicto = "MERCADO ESTANCADO (POCA LUZ)"; return false; }

    double upperWick = (iHigh(_Symbol, PERIOD_M1, 1) - MathMax(iOpen(_Symbol, PERIOD_M1, 1), iClose(_Symbol, PERIOD_M1, 1))) / _Point / 10;
    double lowerWick = (MathMin(iOpen(_Symbol, PERIOD_M1, 1), iClose(_Symbol, PERIOD_M1, 1)) - iLow(_Symbol, PERIOD_M1, 1)) / _Point / 10;
    
    double macd[1];
    int hMACD = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE);
    CopyBuffer(hMACD, 0, 1, 1, macd);
    
    double adx[1];
    int hADX = iADX(_Symbol, PERIOD_M15, 14);
    CopyBuffer(hADX, 0, 1, 1, adx);
    if(adx[0] <= 25.0) return false;
    
    double m15[1], m5[1];
    int hM15 = iMA(_Symbol, PERIOD_M15, PeriodoMediaFiltro, 0, MODE_EMA, PRICE_CLOSE);
    int hM5 = iMA(_Symbol, PERIOD_M5, PeriodoMediaFiltro, 0, MODE_EMA, PRICE_CLOSE);
    CopyBuffer(hM15, 0, 1, 1, m15);
    CopyBuffer(hM5, 0, 1, 1, m5);
    double c15 = iClose(_Symbol, PERIOD_M15, 1);
    double c5 = iClose(_Symbol, PERIOD_M5, 1);
    bool trend15_UP = (c15 > m15[0]);
    bool trend5_UP = (c5 > m5[0]);

    if(trend15_UP && trend5_UP) { 
        if(macd[0] < 0) { txtVeredicto = "MACD NEGATIVO (SIN FUERZA ALCISTA)"; return false; }
        double rsi[1], rsiH1[1], rsiH4[1]; 
        CopyBuffer(hRSI_v, 0, 1, 1, rsi); CopyBuffer(hRSI_H1, 0, 1, 1, rsiH1); CopyBuffer(hRSI_H4, 0, 1, 1, rsiH4);
        if(rsi[0] > MaxRsiCompra) { txtVeredicto = StringFormat("TENDENCIA AGOTADA (RSI M15 > %.0f)", MaxRsiCompra); return false; }
        if(rsiH1[0] > MaxRsiCompra) { txtVeredicto = StringFormat("TENDENCIA AGOTADA (RSI H1 > %.0f)", MaxRsiCompra); return false; }
        if(rsiH4[0] > MaxRsiCompra) { txtVeredicto = StringFormat("TENDENCIA AGOTADA (RSI H4 > %.0f)", MaxRsiCompra); return false; }
        decision = "BUY";
    }
    else if(!trend15_UP && !trend5_UP) { 
        if(macd[0] > 0) { txtVeredicto = "MACD POSITIVO (SIN FUERZA BAJISTA)"; return false; }
        double rsi[1], rsiH1[1], rsiH4[1]; 
        CopyBuffer(hRSI_v, 0, 1, 1, rsi); CopyBuffer(hRSI_H1, 0, 1, 1, rsiH1); CopyBuffer(hRSI_H4, 0, 1, 1, rsiH4);
        if(rsi[0] < MinRsiVenta) { txtVeredicto = StringFormat("TENDENCIA AGOTADA (RSI M15 < %.0f)", MinRsiVenta); return false; }
        if(rsiH1[0] < MinRsiVenta) { txtVeredicto = StringFormat("TENDENCIA AGOTADA (RSI H1 < %.0f)", MinRsiVenta); return false; }
        if(rsiH4[0] < MinRsiVenta) { txtVeredicto = StringFormat("TENDENCIA AGOTADA (RSI H4 < %.0f)", MinRsiVenta); return false; }
        decision = "SELL";
    } else {
        txtVeredicto = "ESPERANDO ALINEACION M15/M5"; return false;
    }
    
    if(decision == "BUY" && upperWick > (body * SensibilidadMechaReal) && upperWick > 3.0) { txtVeredicto = "RECHAZO ALCISTA (MECHA ALTA)"; return false; }
    if(decision == "SELL" && lowerWick > (body * SensibilidadMechaReal) && lowerWick > 3.0) { txtVeredicto = "RECHAZO BAJISTA (MECHA BAJA)"; return false; } 

    if(!ValidarTechosSuelos(decision, true)) return false;
    txtVeredicto = "ESTRUCTURA MACRO CONFIRMADA";
    return true;
}

bool ValidarEstructuraRango(string &decision) {
    if(((double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD)/10.0) > MaxSpreadPips) return false;
    double bUp[1], bDn[1];
    int hBands = iBands(_Symbol, PERIOD_M15, 20, 0, 2.0, PRICE_CLOSE);
    CopyBuffer(hBands, 1, 1, 1, bUp); CopyBuffer(hBands, 2, 1, 1, bDn); 
    
    double anchuraPips = (bUp[0] - bDn[0]) / _Point / 10;
    if(anchuraPips < AnchoMinimoEmbudo) { txtVeredicto = "MERCADO BASURA (EMBUDO MUY ESTRECHO)"; return false; }
    
    // Check Velas Dormidas desactivado para permitir Alta Frecuencia real
    // (Las Bandas de Bollinger ya absorben la volatilidad natural)
    
    double rsi[1];
    if(CopyBuffer(hRSI_v, 0, 1, 1, rsi) <= 0) return false;
    
    double precio = iClose(_Symbol, PERIOD_M1, 1);
    double prevPrecio = iClose(_Symbol, PERIOD_M1, 2);
    double bMid = (bUp[0] + bDn[0]) / 2.0;

    


    // Cargar bandas M1 para la micro-tendencia
    double bUpM1[1] = {0.0}, bDnM1[1] = {0.0};
    int hBandsM1 = iBands(_Symbol, PERIOD_M1, 20, 0, 2.0, PRICE_CLOSE);
    if(hBandsM1 != INVALID_HANDLE) {
        CopyBuffer(hBandsM1, 1, 1, 1, bUpM1);
        CopyBuffer(hBandsM1, 2, 1, 1, bDnM1);
    }
    double bMidM1 = (bUpM1[0] + bDnM1[0]) / 2.0;
    if(bMidM1 == 0.0) return false;
    
    // Cargar RSI M1 para la micro-tendencia
    double rsiM1[1] = {50.0};
    int hRSIM1 = iRSI(_Symbol, PERIOD_M1, 14, PRICE_CLOSE);
    if(hRSIM1 != INVALID_HANDLE) CopyBuffer(hRSIM1, 0, 1, 1, rsiM1);
    // A favor de la Micro-Tendencia (ALTA FRECUENCIA)
    if(precio < bMidM1) {
        // Filtro para no entrar tarde: si el precio está en el 20% más bajo del canal, no vender (riesgo de rebote)
        if(precio < bDnM1[0] + ((bMidM1 - bDnM1[0]) * 0.20)) {
            txtVeredicto = "ESPERANDO: PRECIO MUY BAJO (RIESGO DE REBOTE)"; return false;
        }
        if(prevPrecio > precio && rsiM1[0] < 50) {
            decision = "SELL";
        } else if (prevPrecio <= precio) {
            txtVeredicto = "ESPERANDO: PRECIO NO ESTA CAYENDO"; return false;
        } else {
            txtVeredicto = StringFormat("ESPERANDO: RSI (%.1f) NO ES BAJISTA (<50)", rsiM1[0]); return false;
        }
    }
    else if(precio > bMidM1) {
        // Filtro para no entrar tarde: si el precio está en el 20% más alto del canal, no comprar (riesgo de rebote)
        if(precio > bUpM1[0] - ((bUpM1[0] - bMidM1) * 0.20)) {
            txtVeredicto = "ESPERANDO: PRECIO MUY ALTO (RIESGO DE REBOTE)"; return false;
        }
        if(prevPrecio < precio && rsiM1[0] > 50) {
            decision = "BUY";
        } else if (prevPrecio >= precio) {
            txtVeredicto = "ESPERANDO: PRECIO NO ESTA SUBIENDO"; return false;
        } else {
            txtVeredicto = StringFormat("ESPERANDO: RSI (%.1f) NO ES ALCISTA (>50)", rsiM1[0]); return false;
        }
    } else {
        txtVeredicto = "ESPERANDO: PRECIO EXACTAMENTE EN LA MEDIA"; return false;
    }
    
    
    // --- FILTRO MACRO SOBRECOMPRA/SOBREVENTA ---
    double rsiH1_macro[1] = {50.0}, rsiH4_macro[1] = {50.0}; 
    if(hRSI_H1 != INVALID_HANDLE) CopyBuffer(hRSI_H1, 0, 1, 1, rsiH1_macro);
    if(hRSI_H4 != INVALID_HANDLE) CopyBuffer(hRSI_H4, 0, 1, 1, rsiH4_macro);
    
    if(decision == "BUY") {
        if(rsiH1_macro[0] > MaxRsiCompra || rsiH4_macro[0] > MaxRsiCompra) {
            txtVeredicto = "MACRO SOBRECOMPRADO (PELIGRO COMPRAS)";
            return false;
        }
    } else if(decision == "SELL") {
        if(rsiH1_macro[0] < MinRsiVenta || rsiH4_macro[0] < MinRsiVenta) {
            txtVeredicto = "MACRO SOBREVENDIDO (PELIGRO VENTAS)";
            return false;
        }
    }
    // -------------------------------------------
    
    if(!ValidarTechosSuelos(decision, false)) return false;
    txtVeredicto = "OP. RANGO CONFIRMADA";
    return true;
}

void EjecutarAtaqueTendencia(string d) {
    if(TimeTradeServer() - ultimoAtaque < 3) return;
    if(d == "BUY") tradeTendencia.Buy(LoteAtaque,_Symbol,0,0,0,TradeComment+"_TEND"); 
    else tradeTendencia.Sell(LoteAtaque,_Symbol,0,0,0,TradeComment+"_TEND"); 
    ultimoAtaque = TimeTradeServer();
}

void EjecutarAtaqueRango(string d) {
    if(TimeTradeServer() - ultimoAtaque < 3) return;
    double p = SymbolInfoDouble(_Symbol, d == "BUY" ? SYMBOL_ASK : SYMBOL_BID);
    double sl = 0, tp = 0;
    if(d == "BUY") {
        if(StopLossRangoPips > 0) sl = p - (StopLossRangoPips * 10 * _Point);
        if(TakeProfitRangoPips > 0) tp = p + (TakeProfitRangoPips * 10 * _Point);
        tradeRango.Buy(LoteRango,_Symbol,p,sl,tp,TradeComment+"_RANGO");
    } else {
        if(StopLossRangoPips > 0) sl = p + (StopLossRangoPips * 10 * _Point);
        if(TakeProfitRangoPips > 0) tp = p - (TakeProfitRangoPips * 10 * _Point);
        tradeRango.Sell(LoteRango,_Symbol,p,sl,tp,TradeComment+"_RANGO");
    }
    ultimoAtaque = TimeTradeServer();
}




void GestionarRefuerzoInteligente() {

    if(ArraySize(posTendencia) >= LimitePosicionesSOS) {

        txtVeredicto = "MAXIMO OPERACIONES ALCANZADO";

        return;

    }

    int last = ArraySize(posTendencia)-1;

    double curPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    bool isLosing = (posTendencia[0].t == POSITION_TYPE_BUY) ? (curPrice < posTendencia[0].pr) : (curPrice > posTendencia[0].pr);
    double distPips = MathAbs(curPrice - posTendencia[0].pr) / _Point / 10;
    
    if(!isLosing) distPips = 0; // Evitar SOS en ganancias

    // Actualizar HUD dinámicamente con detalles de la operación activa

    string dirStr = (posTendencia[0].t == POSITION_TYPE_BUY) ? "COMPRA" : "VENTA";

    txtVoz = StringFormat("MAIKO: Vigilando %s activo...", dirStr);

    

    if(distPips < DistanciaRefuerzoPips) {

        txtVeredicto = StringFormat("VIGILANDO %s | CONTRA: %.1f pips | SOS a: %.1f", dirStr, distPips, DistanciaRefuerzoPips);

        return;

    }

    

    bool forzar = (distPips >= MaxPipsHueco) || (iBarShift(_Symbol, PERIOD_M1, posTendencia[0].time) >= MaxVelasHueco);

    bool velaGiro = (posTendencia[0].t == POSITION_TYPE_BUY) ? 

                    (iClose(_Symbol, PERIOD_M1, 1) > iOpen(_Symbol, PERIOD_M1, 1) && iClose(_Symbol, PERIOD_M1, 2) > iOpen(_Symbol, PERIOD_M1, 2)) : 

                    (iClose(_Symbol, PERIOD_M1, 1) < iOpen(_Symbol, PERIOD_M1, 1) && iClose(_Symbol, PERIOD_M1, 2) < iOpen(_Symbol, PERIOD_M1, 2));

    

    if(!velaGiro && !forzar) {

        txtVeredicto = StringFormat("ZONA SOS ALCANZADA | ESPERANDO 2 VELAS GIRO M1 (Pips: %.1f)", distPips);

        return;

    }

    

    double volLado = 0; int type = posTendencia[0].t; for(int i=0; i<ArraySize(posTendencia); i++) if(posTendencia[i].t == type) volLado += posTendencia[i].v;

    double volRefuerzo = NormalizeDouble(volLado * (MultiplicadorRefuerzo - 1.0), 2);

    if(volRefuerzo < 0.01) volRefuerzo = 0.01;

    if(volRefuerzo > MaxLoteIndividual) volRefuerzo = MaxLoteIndividual;

    if(volTotalTendencia + volRefuerzo > MaxLoteTotal) { txtVoz = "LIMITE LOTE ALCANZADO"; return; }

    

    if(TimeTradeServer() - ultimoAtaque < 3) return;

    if(type == POSITION_TYPE_BUY) tradeTendencia.Buy(volRefuerzo, _Symbol, 0, 0, 0, TradeComment + "_SOS"); 

    else tradeTendencia.Sell(volRefuerzo, _Symbol, 0, 0, 0, TradeComment + "_SOS");

    ultimoAtaque = TimeTradeServer();

    txtVeredicto = "DISPARO SOS RESCATE EJECUTADO 🛡️⚡";

}



void GestionarCosechaSniper() { 

    double multCent = EsCuentaCent ? 100.0 : 1.0;

    for(int i=ArraySize(posTendencia)-1; i>=0; i--) {

        if((posTendencia[i].p + posTendencia[i].c + posTendencia[i].s) >= (ProfitCosechaIndividual * multCent)) {

            tradeTendencia.PositionClose(posTendencia[i].ticket);

        }

    }

    for(int i=ArraySize(posRango)-1; i>=0; i--) {

        if((posRango[i].p + posRango[i].c + posRango[i].s) >= (ProfitCosechaIndividual * multCent)) {

            tradeRango.PositionClose(posRango[i].ticket);

        }

    }

}



double CalcularProfit() { 
    double t = 0; double r = 0;
    for(int i=0; i<ArraySize(posTendencia); i++) t += posTendencia[i].p + posTendencia[i].c + posTendencia[i].s; 
    for(int i=0; i<ArraySize(posRango); i++) r += posRango[i].p + posRango[i].c + posRango[i].s; 
    flotanteTendencia = t;
    flotanteRango = r;
    return t + r; 
}



double CalcularGanadoHoy() { 
    double totalTendencia = 0, totalRango = 0; HistorySelect(iTime(_Symbol, PERIOD_D1, 0), TimeCurrent()); 
    int totalDeals = HistoryDealsTotal();
    struct DealData { ulong ticket; long magic; long pos_id; double profit; };
    DealData deals[]; int dCount = 0;
    
    for(int i = 0; i < totalDeals; i++) {
        ulong ticket = HistoryDealGetTicket(i);
        if(ticket > 0) {
            string d_symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
            if(d_symbol != _Symbol) continue;
            long entry_type = HistoryDealGetInteger(ticket, DEAL_ENTRY);
            if(entry_type != DEAL_ENTRY_OUT && entry_type != DEAL_ENTRY_INOUT) continue;
            long d_magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
            
            if(d_magic == MagicTendencia || d_magic == 111333) {
                totalTendencia += HistoryDealGetDouble(ticket, DEAL_PROFIT);
                totalTendencia += HistoryDealGetDouble(ticket, DEAL_COMMISSION);
                totalTendencia += HistoryDealGetDouble(ticket, DEAL_SWAP);
            }
            if(d_magic == MagicRango) {
                totalRango += HistoryDealGetDouble(ticket, DEAL_PROFIT);
                totalRango += HistoryDealGetDouble(ticket, DEAL_COMMISSION);
                totalRango += HistoryDealGetDouble(ticket, DEAL_SWAP);
            }
        }
    }
    
    ganadoHoyTendencia = totalTendencia;
    ganadoHoyRango = totalRango;
    return totalTendencia + totalRango;
}



void CerrarTodo() { 

    int total = ArraySize(posTendencia) + ArraySize(posRango);

    if(total == 0) return;

    Print("KOPYTRADING: Iniciando cierre de ", total, " posiciones...");

    for(int i=ArraySize(posTendencia)-1; i>=0; i--) {

        ulong ticket = posTendencia[i].ticket;

        if(PositionSelectByTicket(ticket)) tradeTendencia.PositionClose(ticket);

    }

    for(int i=ArraySize(posRango)-1; i>=0; i--) {

        ulong ticket = posRango[i].ticket;

        if(PositionSelectByTicket(ticket)) tradeRango.PositionClose(ticket);

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
    ArrayResize(posTendencia, 0); volTotalTendencia = 0; 
    ArrayResize(posRango, 0); volTotalRango = 0; 
    
    for(int i=PositionsTotal()-1; i>=0; i--) {
        if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol) { 
            long magic = PositionGetInteger(POSITION_MAGIC);
            if(magic == MagicTendencia) {
                int idx = ArraySize(posTendencia); ArrayResize(posTendencia, idx+1); 
                posTendencia[idx].ticket = PositionGetTicket(i); 
                posTendencia[idx].p = PositionGetDouble(POSITION_PROFIT); 
                posTendencia[idx].c = PositionGetDouble(POSITION_COMMISSION); 
                posTendencia[idx].s = PositionGetDouble(POSITION_SWAP); 
                posTendencia[idx].t = (int)PositionGetInteger(POSITION_TYPE); 
                posTendencia[idx].v = PositionGetDouble(POSITION_VOLUME); 
                posTendencia[idx].time = (datetime)PositionGetInteger(POSITION_TIME); 
                posTendencia[idx].pr = PositionGetDouble(POSITION_PRICE_OPEN); 
                volTotalTendencia += posTendencia[idx].v; 
            } else if(magic == MagicRango) {
                int idx = ArraySize(posRango); ArrayResize(posRango, idx+1); 
                posRango[idx].ticket = PositionGetTicket(i); 
                posRango[idx].p = PositionGetDouble(POSITION_PROFIT); 
                posRango[idx].c = PositionGetDouble(POSITION_COMMISSION); 
                posRango[idx].s = PositionGetDouble(POSITION_SWAP); 
                posRango[idx].t = (int)PositionGetInteger(POSITION_TYPE); 
                posRango[idx].v = PositionGetDouble(POSITION_VOLUME); 
                posRango[idx].time = (datetime)PositionGetInteger(POSITION_TIME); 
                posRango[idx].pr = PositionGetDouble(POSITION_PRICE_OPEN); 
                volTotalRango += posRango[idx].v; 
            }
        } 
    } 
} 





double CalcularMetaEscapeTP() {
    int totalPos = ArraySize(posTendencia);
    if(totalPos == 0) return 0;
    
    double sumVol = 0;
    double sumPriceVol = 0;
    double sumCommSwap = 0;
    int type = posTendencia[0].t;
    
    for(int i = 0; i < totalPos; i++) {
        sumVol += posTendencia[i].v;
        sumPriceVol += posTendencia[i].pr * posTendencia[i].v;
        sumCommSwap += posTendencia[i].c + posTendencia[i].s;
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

    int x = HUD_X, y = PosY_HUD, w = 460, h = 280; 

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

    

    CrearLabel("MAIKO_Vered", x+10, y+85, txtVeredicto, clrCyan, 8, CORNER_LEFT_UPPER); 
    CrearLabel("MAIKO_Macro", x+10, y+105, txtMacro, clrOrange, 8, CORNER_LEFT_UPPER);

    CrearLabel("MAIKO_Hoy", x+10, y+125, "GANADO [T: $0.00 | R: $0.00]", clrSpringGreen, 12, CORNER_LEFT_UPPER); 

    CrearLabel("MAIKO_Flot", x+10, y+160, "FLOTANTE [T: $0.00 | R: $0.00]", clrWhite, 12, CORNER_LEFT_UPPER); 

    CrearLabel("MAIKO_MetaTP", x+10, y+190, "ESTADO: INICIANDO...", clrYellow, 10, CORNER_LEFT_UPPER); 

    CrearLabel("MAIKO_TrialUI", x+10, y+215, "TRIAL: DIA 1 DE 30", clrYellow, 11, CORNER_LEFT_UPPER);

    CrearLabel("MAIKO_Spd", x+w-120, y+65, "SPD: 0.0", clrWhite, 8, CORNER_LEFT_UPPER);  

    

    CrearBoton("MAIKO_Foot", x, y+h-40, w, 40, "", ColorHeader, clrNONE, CORNER_LEFT_UPPER); 

    CrearLabel("MAIKO_Voz", x+10, y+h-25, txtVoz, ColorMain, 10, CORNER_LEFT_UPPER); 

    CrearBoton("MAIKO_BtnP", x+w-120, y+110, 110, 50, "ENCENDER", clrDarkGreen, clrWhite, CORNER_LEFT_UPPER); 

    CrearBoton("MAIKO_BtnC", x+w-120, y+175, 110, 35, "CERRAR", clrDarkRed, clrWhite, CORNER_LEFT_UPPER); 

}



void ActualizarInterfazMaster() { 

    double multCent = EsCuentaCent ? 100.0 : 1.0; 

    ObjectSetString(0, "MAIKO_Hoy", OBJPROP_TEXT, StringFormat("GANADO [T: $%.2f | R: $%.2f]", ganadoHoyTendencia / multCent, ganadoHoyRango / multCent)); 

    ObjectSetString(0, "MAIKO_Flot", OBJPROP_TEXT, StringFormat("FLOTANTE [T: $%.2f | R: $%.2f]", flotanteTendencia / multCent, flotanteRango / multCent)); 

    ObjectSetString(0, "MAIKO_Spd", OBJPROP_TEXT, StringFormat("SPD: %.1f", ((double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD)/10.0))); 

      

      int elapsedSeconds = (int)(TimeCurrent() - trialStart);

      int remainingSeconds = 86400 - (elapsedSeconds % 86400);

      int remHours = remainingSeconds / 3600;

      int remMinutes = (remainingSeconds % 3600) / 60;

      int dOp = (int)((TimeCurrent() - trialStart) / 86400) + 1;

      

      if(trialExpirado) {

          ObjectSetString(0, "MAIKO_TrialUI", OBJPROP_TEXT, "TRIAL EXPIRADO");

          ObjectSetInteger(0, "MAIKO_TrialUI", OBJPROP_COLOR, clrRed);

      } else if(diasRestantes <= 7) {

          ObjectSetString(0, "MAIKO_TrialUI", OBJPROP_TEXT, StringFormat("EXPIRA EN %d DIAS [%dh %dm] | ADQUIERE REAL", diasRestantes, remHours, remMinutes));

          ObjectSetInteger(0, "MAIKO_TrialUI", OBJPROP_COLOR, C'255,69,0');

      } else {

          ObjectSetString(0, "MAIKO_TrialUI", OBJPROP_TEXT, StringFormat("TRIAL: DIA %d [%dh %dm]", dOp, remHours, remMinutes));

          ObjectSetInteger(0, "MAIKO_TrialUI", OBJPROP_COLOR, clrYellow);

      }

    ObjectSetInteger(0, "MAIKO_Flot", OBJPROP_COLOR, (flotanteTendencia + flotanteRango) >= 0 ? clrSpringGreen : clrRed); 

    ObjectSetString(0, "MAIKO_Vered", OBJPROP_TEXT, txtVeredicto);
    ObjectSetString(0, "MAIKO_Macro", OBJPROP_TEXT, txtMacro); 

    ObjectSetString(0, "MAIKO_Voz", OBJPROP_TEXT, txtVoz); 

    ObjectSetString(0, "MAIKO_BtnP", OBJPROP_TEXT, BotActivo ? "APAGAR" : "ENCENDER"); 

    ObjectSetInteger(0, "MAIKO_BtnP", OBJPROP_BGCOLOR, BotActivo ? clrMaroon : clrDarkGreen); 

    

    double metaTP = CalcularMetaEscapeTP();

    if(metaTP > 0) {

        ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, StringFormat("ESCAPE TP: %.2f", metaTP));

    } else {

        ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, "ESTADO: " + (surfeandoTendencia ? "BUSCANDO PULLBACKS" : "BUSCANDO PING-PONG"));

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
    ObjectSetInteger(0, n, OBJPROP_BACK, false); ObjectSetInteger(0, n, OBJPROP_ZORDER, 500); 
}



void CrearLabel(string n, int x, int y, string t, color col, int s, ENUM_BASE_CORNER c) { 

    ObjectCreate(0, n, OBJ_LABEL, 0, 0, 0); 

    ObjectSetInteger(0, n, OBJPROP_CORNER, c); 

    ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y); 

    ObjectSetString(0, n, OBJPROP_TEXT, t); ObjectSetInteger(0, n, OBJPROP_COLOR, col); 

    ObjectSetInteger(0, n, OBJPROP_FONTSIZE, s); ObjectSetInteger(0, n, OBJPROP_BACK, false); 
    ObjectSetInteger(0, n, OBJPROP_ZORDER, 505); 
}



void ToggleHUD() { 

    hudMinimizado = !hudMinimizado; 

    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_YSIZE, hudMinimizado ? 35 : 280); 

    ObjectSetString(0, "MAIKO_BtnMin", OBJPROP_TEXT, hudMinimizado ? "+" : "_"); 

    long tf = hudMinimizado ? OBJ_NO_PERIODS : OBJ_ALL_PERIODS; 

    string objs[] = {"MAIKO_Vered", "MAIKO_Macro", "MAIKO_Hoy", "MAIKO_Flot", "MAIKO_Spd", "MAIKO_Foot", "MAIKO_Voz", "MAIKO_BtnP", "MAIKO_BtnC", "MAIKO_MetaTP", "MAIKO_TrialUI"}; 

    for(int i=0; i<10; i++) ObjectSetInteger(0, objs[i], OBJPROP_TIMEFRAMES, tf); 

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
    ActualizarEstadoMaster();

    int interval = (ArraySize(posTendencia) + ArraySize(posRango) > 0) ? 15 : 3600;

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

    double normGanadoHoy = (ganadoHoyTendencia + ganadoHoyRango) / divFactor;

    

    string status = BotActivo ? "ONLINE" : "PAUSED";

    
    int nPosT = ArraySize(posTendencia);
    int nPosR = ArraySize(posRango);
    
    string posJson = "[";
    bool first = true;
    for(int i = 0; i < nPosT; i++) {
        if(!first) posJson += ",";
        posJson += StringFormat(
            "{\"ticket\":\"%I64u\",\"type\":\"%s\",\"symbol\":\"%s\",\"lots\":%.2f,\"openPrice\":%.5f,\"tp\":%.5f,\"sl\":%.5f,\"profit\":%.2f}",
            posTendencia[i].ticket,
            posTendencia[i].t == POSITION_TYPE_BUY ? "BUY" : "SELL",
            _Symbol, posTendencia[i].v, posTendencia[i].pr, 0.0, 0.0, (posTendencia[i].p + posTendencia[i].c + posTendencia[i].s) / divFactor
        );
        first = false;
    }
    for(int i = 0; i < nPosR; i++) {
        if(!first) posJson += ",";
        posJson += StringFormat(
            "{\"ticket\":\"%I64u\",\"type\":\"%s\",\"symbol\":\"%s\",\"lots\":%.2f,\"openPrice\":%.5f,\"tp\":%.5f,\"sl\":%.5f,\"profit\":%.2f}",
            posRango[i].ticket,
            posRango[i].t == POSITION_TYPE_BUY ? "BUY" : "SELL",
            _Symbol, posRango[i].v, posRango[i].pr, 0.0, 0.0, (posRango[i].p + posRango[i].c + posRango[i].s) / divFactor
        );
        first = false;
    }
    posJson += "]";

    

    string narrative = txtVeredicto;

    StringReplace(narrative, "\"", "'");

    

    string json = StringFormat(

        "{\"purchaseId\":\"%s\",\"account\":\"%s\",\"balance\":%.2f,\"equity\":%.2f,"

        "\"pnl_today\":%.2f,\"status\":\"%s\",\"symbol\":\"%s\",\"narrative\":\"%s\","

        "\"armed\":%s,\"isReal\":%s,\"version\":\"13.00\",\"positions\":%s,"

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

bool ValidarTechosSuelos(string decision, bool esMotorTendencia) {
    double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double point_pips = _Point * 10;
    int start_bar = 1;

    // --- 1. Filtro original M15 ---
    if(UsarFiltroTechosSuelos && !esMotorTendencia) {
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
    if(UsarFiltroTechosSuelosH1 && !esMotorTendencia) {
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





//+------------------------------------------------------------------+
//| SALIDAS DINAMICAS ALTA FRECUENCIA (RANGO)                        |
//+------------------------------------------------------------------+
void GestionarSalidasDinamicasRango() {
    if(ArraySize(posRango) == 0) return;
    
    double rsi[1] = {50.0};
    ENUM_TIMEFRAMES tf = PERIOD_M1;
    int hRSIM1 = iRSI(_Symbol, PERIOD_M1, 14, PRICE_CLOSE);
    if(hRSIM1 != INVALID_HANDLE) CopyBuffer(hRSIM1, 0, 1, 1, rsi);
    
    double bUp[1] = {0.0}, bDn[1] = {0.0};
    int hBands = iBands(_Symbol, tf, 20, 0, 2.0, PRICE_CLOSE);
    if(hBands == INVALID_HANDLE) return;
    if(CopyBuffer(hBands, 1, 1, 1, bUp) <= 0) return;
    if(CopyBuffer(hBands, 2, 1, 1, bDn) <= 0) return;
    double bMid = (bUp[0] + bDn[0]) / 2.0;
    
    double precio = iClose(_Symbol, tf, 1);
    
    for(int i=ArraySize(posRango)-1; i>=0; i--) {
        if(posRango[i].t == POSITION_TYPE_BUY) {
            // Cerramos si el precio cae por debajo de la media o RSI se da la vuelta, SOLO SI ESTAMOS EN GANANCIAS
            if(precio < bMid || rsi[0] < 50) {
                if(posRango[i].p > 0) tradeRango.PositionClose(posRango[i].ticket);
            }
        }
        else if(posRango[i].t == POSITION_TYPE_SELL) {
            // Cerramos si el precio sube por encima de la media o RSI se da la vuelta, SOLO SI ESTAMOS EN GANANCIAS
            if(precio > bMid || rsi[0] > 50) {
                if(posRango[i].p > 0) tradeRango.PositionClose(posRango[i].ticket);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| TRAILING STOP (TENDENCIA)                                        |
//+------------------------------------------------------------------+
void GestionarTrailingStopTendencia() {
    if(ArraySize(posTendencia) == 0) return;
    
    double pipsLevel = TrailingStopTendenciaPips * 10 * _Point;
    
    for(int i=ArraySize(posTendencia)-1; i>=0; i--) {
        ulong ticket = posTendencia[i].ticket;
        if(PositionSelectByTicket(ticket)) {
            double currentSL = PositionGetDouble(POSITION_SL);
            double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            long type = PositionGetInteger(POSITION_TYPE);
            
            if(type == POSITION_TYPE_BUY) {
                if(currentPrice - openPrice > pipsLevel) {
                    double newSL = currentPrice - pipsLevel;
                    if(newSL > currentSL || currentSL == 0) {
                        tradeTendencia.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
                    }
                }
            }
            else if(type == POSITION_TYPE_SELL) {
                if(openPrice - currentPrice > pipsLevel) {
                    double newSL = currentPrice + pipsLevel;
                    if(newSL < currentSL || currentSL == 0) {
                        tradeTendencia.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
                    }
                }
            }
        }
    }
}

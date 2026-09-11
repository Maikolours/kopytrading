//+------------------------------------------------------------------+

//|           MAIKO PRO GOLD DEMO | v11.34.1 |

//|       "INSTITUTIONAL EDITION" | ANTI-TURBULENCIA V11.34.1          |

//+------------------------------------------------------------------+

//| Restored for Gold/Normal version - behaving 100% like original  |

//+------------------------------------------------------------------+

#property copyright "KOPYTRADING MAIKO"

#property version   "11.34.1"

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
input double   MaxRangoVelaM1             = 20.0;        // ⚡ Rango Máximo Vela M1 (Pips)
input double   MaxSpreadPips              = 4.0;         // 📊 Spread Máximo Permitido (Pips)
input double   SensibilidadMechaReal      = 3.0;         // ⚖️ Sensibilidad Rechazo de Mechas
input int      MinutosPausaTrasSusto      = 1;           // ⏱️ Minutos Pausa tras Vela Extrema
input double   MaxRsiCompra               = 70.0;        // 📈 RSI Máximo para Compras (Filtro Techos)
input double   MinRsiVenta                = 30.0;        // 📉 RSI Mínimo para Ventas (Filtro Suelos)

// --- FILTRO DE TECHOS Y SUELOS (SOPORTES Y RESISTENCIAS) ---
input group "━━━━━━ 🏛️ 𝗙 𝗜 𝗟 𝗧 𝗥 𝗢   𝗗 𝗘   𝗧 𝗘 𝗖 𝗛 𝗢 𝗦   𝗬   𝗦 𝗨 𝗘 𝗟 𝗢 𝗦 ━━━━━━"
input bool             UsarFiltroTechosSuelos     = false;       // 🏛️ Activar Filtro Techos y Suelos M15 (S/R)
input ENUM_TIMEFRAMES  TimeframeTechosSuelos      = PERIOD_M15;  // 📅 Temporalidad para Techos/Suelos M15
input int              PeriodoTechosSuelos        = 24;          // 🔢 Período de Velas M15 a Analizar
input double           DistanciaTechoSueloPips    = 15.0;        // 📏 Distancia Mínima M15 para Bloquear (Pips)

// --- FILTROS ADICIONALES MULTI-TEMPORALIDAD (H1 y H4) ---
input bool             UsarFiltroTechosSuelosH1   = true;        // 📊 Activar Filtro S/R en H1
input int              PeriodoTechosSuelosH1      = 24;          // 📅 Período H1 a Analizar (Velas)
input double           DistanciaTechoSueloPipsH1  = 20.0;        // 📅 Distancia Mínima H1 (Pips)

input bool             UsarFiltroTechosSuelosH4   = true;        // 📊 Activar Filtro S/R en H4
input int              PeriodoTechosSuelosH4      = 24;          // 📅 Período H4 a Analizar (Velas)
input double           DistanciaTechoSueloPipsH4  = 35.0;        // 📏 Distancia Mínima H4 (Pips)

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
input double   LoteAtaque                 = 0.02;        // 💰 Volumen Entrada Inicial (Ataque)
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
input double   ProfitCosechaIndividual    = 1.5;         // 💵 Beneficio Cierre SOS Individual ($)
input double   TargetDiario               = 100.0;       // 🎯 Meta de Beneficio Diario ($)

// --- HORARIOS OPERATIVOS ---
input group "━━━━━━ ⏰ 𝗛 𝗢 𝗥 𝗔 𝗥 𝗜 𝗢 𝗦   𝗢 𝗣 𝗘 𝗥 𝗔 𝗧 𝗜 𝗩 𝗢 𝗦 ━━━━━━"
input int      HoraInicioOperativa        = 3;           // 🔔 Hora de Inicio Operaciones (03:00 Broker)
input int      HoraFinOperativa           = 23;          // 🔕 Hora de Cierre Operaciones (23:00 Broker)
input bool     OperarViernesNoche         = false;       // 🌃 Permitir Operaciones Viernes Noche
input bool     UsarHorarioBloqueo         = false;       // 🛑 Evitar Noticias (Bloqueo Horario)
input int      HoraInicioBloqueo          = 14;          // 🛑 Hora Inicio Bloqueo Noticias
input int      HoraFinBloqueo             = 16;          // 🛑 Hora Fin Bloqueo Noticias

// --- PROTECCIONES Y SEGURIDAD ---
input group "━━━━━━ 🛡️ 𝗣 𝗥 𝗢 𝗧 𝗘 𝗖 𝗖 𝗜 𝗢 𝗡 𝗘 𝗦   𝗬   𝗦 𝗘 𝗚 𝗨 𝗥 𝗜 𝗗 𝗔 𝗗 ━━━━━━"
input int      LimitePosicionesSOS        = 2;           // 🛡️ Máximo de posiciones en la cesta (1 inicial + 1 SOS)
input bool     UsarRiesgoDinamico          = true;        // 💰 Calcular lote por % de equity y distancia ATR
input double   RiesgoPorCestaPct           = 0.50;        // 💰 Riesgo objetivo de la cesta (% equity)
input bool     UsarStopServidorATR         = true;        // 🛑 SL real en broker basado en ATR (protección de emergencia)
input int      ATRPeriod                   = 14;          // 📐 ATR M1
input double   ATRStopMultiplicador        = 1.80;        // 📐 Distancia SL = ATR × multiplicador
input double   ATRVolatilidadMaxRatio      = 1.80;        // 🔥 No operar si ATR actual supera este ratio del ATR medio
input int      ATRPromedioPeriodos         = 20;          // 📊 Ventana para ATR medio
input int      MinutosPausaVolatilidadExtrema = 10;       // ⏸️ Pausa por volatilidad extrema
input bool     UsarLimitePerdidaDiaria     = true;        // 🚨 Límite de pérdida diaria
input double   MaxPerdidaDiariaPct         = 2.00;        // 🚨 Pérdida diaria máxima (% del balance)
input int      MaxPerdidasConsecutivas     = 3;           // 🚨 Circuit breaker tras N pérdidas
input int      MinutosPausaCircuitBreaker  = 30;          // ⏸️ Pausa tras circuito de pérdidas
input double   ProfitBreakEven            = 0.50;        // 🛡️ Beneficio Mínimo Break Even Cesta ($)
input double   ProteccionBeneficioDiario  = 0.0;         // 🛡️ Proteger Beneficio Diario Acumulado ($)
input bool     UsarStopLossPorcentaje     = true;        // 🚨 Activar Stop Loss por % Cuenta
input double   PorcentajeStopLoss         = 3.0;         // 🚨 Porcentaje de Pérdida Máxima (3.0%)
input bool     UsarPausaTrasStopLoss      = true;        // 🛑 Pausar Bot tras un Stop Loss
input int      MinutosPausaTrasStopLoss   = 15;          // ⏳ Minutos de Pausa tras Stop Loss

// --- HORARIO BLOQUEO INTERNO ---
input bool     UsarHorarioBloqueo_Interno = false;
input int      HoraInicioBloqueo_Interno  = 14;
input int      HoraFinBloqueo_Interno     = 16;


// --- FILTRO DE AGOTAMIENTO (BANDS) ---
input group "================= FILTRO BANDS ================="
input bool     UsarFiltroBollinger        = true;        // Activar Bloqueo por Bandas de Bollinger
input int      BollingerPeriod            = 20;          // Periodo Bandas
input double   BollingerDev               = 2.0;         // Desviacion Bandas

// --- INTERFAZ GRAFICA (HUD) ---
input group "━━━━━━ 🎨 𝗜 𝗡 𝗧 𝗘 𝗥 𝗙 𝗔 𝗫   𝗚 𝗥 𝗔 𝗙 𝗜 𝗖 𝗔   ( 𝗛 𝗨 𝗗 ) ━━━━━━"
string         HUD_Branding               = "MAIKO GOLD V11.34.1 | RISK";
input color    ColorMain                  = clrGold;     // 🎨 Color Principal HUD (Acento)
input color    ColorHeader                = C'30,30,30'; // 🎨 Color Encabezado Panel HUD
input color    ColorBody                  = C'20,20,20'; // 🎨 Color Cuerpo Panel HUD
input int      HUD_X                      = 15;          // 📍 Posición X en Pantalla (Pixeles)
input int      PosY_HUD                   = 25;          // 📐 Posición Y en Pantalla (Pixeles)
input bool     ShowW1                     = true;        // 📅 Mostrar Tendencia W1
input bool     ShowD1                     = true;        // 📅 Mostrar Tendencia D1
input bool     ShowH4                     = true;        // 📅 Mostrar Tendencia H4
input bool     ShowH1                     = true;        // 📅 Mostrar Tendencia H1
input bool     ShowM15                    = true;        // 📅 Mostrar Tendencia M15
input bool     ShowM5                     = true;        // 📅 Mostrar Tendencia M5
input bool     ShowM1                     = true;        // 📅 Mostrar Tendencia M1
input bool     CargarIndicadoresVisuales  = true;        // 📊 Dibujar Indicadores en Gráfico (True por defecto)

// --- COMENTARIOS DE OPERACIONES Y AISLAMIENTO ---
input group "━━━━━━ 📝 𝗖 𝗢 𝗠 𝗘 𝗡 𝗧 𝗔 𝗥 𝗜 𝗢 𝗦   𝗬   𝗠 𝗔 𝗚 𝗜 𝗖 ━━━━━━"
input string   TradeComment               = "MAIKO_PRO_GOLD_V11.34.1"; // 📝 Comentario para Órdenes (Trade Comment)
input int      InpMagicNumber             = 113300;      // 🔮 Magic Number Propio (Identificador Único del Bot)
input double   BalanceInicialPropio       = 1000.0;      // 💵 Balance Inicial Propio del Bot ($)
input bool     ResetEstadisticas          = false;       // 🔄 Resetear Ganancia Total e Historial de este Bot

// --- TELEGRAM NOTIFICACIONES Y CONTROL ---
input group "━━━━━━ 📱 𝗧 𝗘 𝗟 𝗘 𝗚 𝗥 𝗔 𝗠   𝗖 𝗢 𝗡 𝗧 𝗥 𝗢 𝗟 ━━━━━━"
input bool     UsarTelegramNotif          = true;        // 📱 Activar Alertas y Control Telegram
input string   TelegramBotToken           = "8724647915:AAHDxN2u5F7k9hOGhzP9WmZnSYJyPPUP69w"; // 🤖 Token del Bot
input string   TelegramChatID             = "906620572";  // 👤 Tu Chat ID Privado

void EnviarTelegramConTeclado(string mensaje);
void EnviarTelegram(string mensaje);

// Globales

CTrade trade;

int ExpertMagic = 113300;

struct PosInfo { ulong ticket; double p; double c; double s; int t; double v; datetime time; double pr; };

PosInfo pos[];

double ganadoHoy = 0, flotante = 0, volTotal = 0, spreadActual = 0, ganadoTotal = 0;
double balanceCuenta = 0, flotanteTotalCuenta = 0, gananciaHoyCuenta = 0;
int    totalBotsActivos = 1;
string listaBotsActivos = "RISK";

bool BotActivo = true;

bool hudMinimizado = false;

datetime ultimoAtaque = 0;

string txtVoz = "Escaneando...";

string txtVeredicto = "ESPERANDO...";

datetime proximoAtaque = 0, pausaVolatilidad = 0, pausaStopLoss = 0, ultimaVelaTurbulencia = 0;

bool enFaseAnalisis = false;

int FaseRefuerzo = 0;

datetime trialStart = 0;

int diasRestantes = 30;

bool trialExpirado = false;

ulong ticketExplorador = 0;

int hEMA_v = INVALID_HANDLE;

int hRSI_v = INVALID_HANDLE;

int hATR_v = INVALID_HANDLE;
datetime pausaCircuitBreaker = 0;
ulong ultimoDealCircuitBreaker = 0;

datetime ultimoDiaRiesgo = 0;

int hRadar[7];

ENUM_TIMEFRAMES etfs[]={PERIOD_W1,PERIOD_D1,PERIOD_H4,PERIOD_H1,PERIOD_M15,PERIOD_M5,PERIOD_M1};

int hEMA_chart = INVALID_HANDLE;
int hRSI_chart = INVALID_HANDLE;
int hBands_chart = INVALID_HANDLE;

void AgregarIndicadoresVisuales() {
    if(!CargarIndicadoresVisuales || MQLInfoInteger(MQL_TESTER)) return;

    bool tieneEMA = false;
    bool tieneRSI = false;
    bool tieneBands = false;
    int ventanas = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL);

    for(int w = 0; w < ventanas; w++) {
        int totalInd = ChartIndicatorsTotal(0, w);
        for(int i = totalInd - 1; i >= 0; i--) {
            string nombre = ChartIndicatorName(0, w, i);
            if(StringFind(nombre, IntegerToString(PeriodoMediaFiltro)) >= 0 && (StringFind(nombre, "MA") >= 0 || StringFind(nombre, "EMA") >= 0)) tieneEMA = true;
            if(StringFind(nombre, "RSI") >= 0 && StringFind(nombre, "14") >= 0) tieneRSI = true;
            if(StringFind(nombre, "Bands") >= 0 || StringFind(nombre, "Bollinger") >= 0) tieneBands = true;
            if(StringFind(nombre, "MACD") >= 0) {
                ChartIndicatorDelete(0, w, nombre);
            }
        }
    }

    if(hEMA_chart == INVALID_HANDLE) hEMA_chart = (_Period == PERIOD_M1) ? hEMA_v : iMA(_Symbol, _Period, PeriodoMediaFiltro, 0, MODE_EMA, PRICE_CLOSE);
    if(hRSI_chart == INVALID_HANDLE) hRSI_chart = (_Period == PERIOD_M1) ? hRSI_v : iRSI(_Symbol, _Period, 14, PRICE_CLOSE);

    if(!tieneEMA && hEMA_chart != INVALID_HANDLE) ChartIndicatorAdd(0, 0, hEMA_chart);
    if(UsarFiltroBollinger && !tieneBands) {
        if(hBands_chart == INVALID_HANDLE) hBands_chart = (_Period == PERIOD_M1) ? hBands_v : iBands(_Symbol, _Period, BollingerPeriod, 0, BollingerDev, PRICE_CLOSE);
        if(hBands_chart != INVALID_HANDLE) ChartIndicatorAdd(0, 0, hBands_chart);
    }
    if(!tieneRSI && hRSI_chart != INVALID_HANDLE) ChartIndicatorAdd(0, (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL), hRSI_chart);
}


int hBands_v = INVALID_HANDLE;

int OnInit() {

    if(AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL) {

        Alert("MAIKO SNIPER: TRIAL SÓLO VÁLIDO PARA CUENTAS DEMO.");

        return INIT_FAILED;

    }

    ExpertMagic = InpMagicNumber;
    trade.SetExpertMagicNumber(ExpertMagic);

    trade.SetAsyncMode(false);

    hEMA_v = iMA(_Symbol, PERIOD_M1, PeriodoMediaFiltro, 0, MODE_EMA, PRICE_CLOSE);
    if(UsarFiltroBollinger) {
        hBands_v = iBands(_Symbol, PERIOD_M1, BollingerPeriod, 0, BollingerDev, PRICE_CLOSE);
    }


    hRSI_v = iRSI(_Symbol, PERIOD_M1, 14, PRICE_CLOSE);
    hATR_v = iATR(_Symbol, PERIOD_M1, ATRPeriod);
    if(hATR_v == INVALID_HANDLE) return(INIT_FAILED);

    for(int i=0; i<7; i++) {

        hRadar[i] = iMA(_Symbol, etfs[i], PeriodoMediaFiltro, 0, MODE_EMA, PRICE_CLOSE);

    }

    AgregarIndicadoresVisuales();

    CrearInterfazMaster();

    ChartSetInteger(0, CHART_FOREGROUND, false); ChartSetInteger(0, CHART_SHOW_TRADE_HISTORY, true);

    RefrescarYDibujarFlechasHistorial();

    string gvName = StringFormat("MAIKO_V1134_TRIAL_%d_%I64d", ExpertMagic, AccountInfoInteger(ACCOUNT_LOGIN));
    string gvReset = StringFormat("MAIKO_V1134_STARTTIME_%d_%I64d", ExpertMagic, AccountInfoInteger(ACCOUNT_LOGIN));

    if(ResetEstadisticas) {
        GlobalVariableDel(gvName);
        GlobalVariableDel(gvReset);
        GlobalVariableSet(gvReset, (double)TimeCurrent());
        trialStart = TimeCurrent();
        GlobalVariableSet(gvName, (double)trialStart);
        Print("MAIKO V11.34: Estadisticas e Historial RESETEADOS para Magic ", ExpertMagic);
    } else {
        if(GlobalVariableCheck(gvName)) {
            trialStart = (datetime)GlobalVariableGet(gvName);
        } else {
            trialStart = TimeCurrent();
            GlobalVariableSet(gvName, (double)trialStart);
        }
        if(!GlobalVariableCheck(gvReset)) {
            GlobalVariableSet(gvReset, (double)trialStart);
        }
    }

    int maxDias = 30;
    int diasPasados = (int)((TimeCurrent() - trialStart) / 86400);
    diasRestantes = maxDias - diasPasados;
    if(diasRestantes <= 0 || diasRestantes > 30) diasRestantes = 30;
    trialExpirado = false;

    if(MQLInfoInteger(MQL_TESTER)) BotActivo = true;
    EventSetTimer(1);
    if(!MQLInfoInteger(MQL_TESTER)) {
        EnviarTelemetria();
        string initMsg = StringFormat("🟢 *MAIKO RISK*: Bot Conectado y Listo\n• Cuenta: %s\n• Saldo: $%.2f\n• Par: %s\n• Estado: %s",
                                      IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)),
                                      AccountInfoDouble(ACCOUNT_BALANCE),
                                      _Symbol,
                                      BotActivo ? "OPERANDO ✅" : "PAUSADO 🛑");
        EnviarTelegramConTeclado(initMsg);
    }
    ultimoSync = TimeLocal();
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) { 
    EventKillTimer();
    ObjectsDeleteAll(0, "MAIKO_"); 
    for(int i=0; i<7; i++) {
        if(hRadar[i] != INVALID_HANDLE) IndicatorRelease(hRadar[i]);
    }
    
    if(hBands_v != INVALID_HANDLE) IndicatorRelease(hBands_v);

    if(hEMA_v != INVALID_HANDLE) IndicatorRelease(hEMA_v);
    if(hRSI_v != INVALID_HANDLE) IndicatorRelease(hRSI_v);
    if(hEMA_chart != INVALID_HANDLE && hEMA_chart != hEMA_v) { IndicatorRelease(hEMA_chart); hEMA_chart = INVALID_HANDLE; }
    if(hRSI_chart != INVALID_HANDLE && hRSI_chart != hRSI_v) { IndicatorRelease(hRSI_chart); hRSI_chart = INVALID_HANDLE; }
    if(hBands_chart != INVALID_HANDLE && hBands_chart != hBands_v) { IndicatorRelease(hBands_chart); hBands_chart = INVALID_HANDLE; }
    string myGv = StringFormat("MAIKO_HEARTBEAT_%d_%I64d", ExpertMagic, AccountInfoInteger(ACCOUNT_LOGIN));
    GlobalVariableDel(myGv);
    ChartRedraw(); 
}

void ActualizarTextosEstado() {
    int maxDias = 30;
    int diasPasados = (int)((TimeTradeServer() - trialStart) / 86400);
    diasRestantes = maxDias - diasPasados;
    if(diasRestantes <= 0 || diasRestantes > 30) diasRestantes = 30;
    trialExpirado = false;

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

    if(UsarPausaTrasStopLoss && MinutosPausaTrasStopLoss > 0) {
        datetime dealPerdedorTime = 0;
        long dealPerdedorType = -1;
        ulong ticketSL = ObtenerUltimoDealPerdedorInfo(dealPerdedorTime, dealPerdedorType);
        if(ticketSL > 0 && dealPerdedorTime > 0) {
            datetime finPausaSL = dealPerdedorTime + (60 * MinutosPausaTrasStopLoss);
            if(serverTime < finPausaSL && pausaStopLoss < finPausaSL) {
                pausaStopLoss = finPausaSL;
            }
        }
    }

    if(serverTime < pausaStopLoss) {

        txtVoz = "STANDBY POST-SL (" + IntegerToString((int)((pausaStopLoss - serverTime) / 60) + 1) + " MIN)";

        txtVeredicto = "STANDBY SL";

        return;

    }

    MqlDateTime time;

    TimeToStruct(serverTime, time);

    bool esFinDeSemana = (time.day_of_week == 0 || time.day_of_week == 6);

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

        double ema[1];

        if(CopyBuffer(hEMA_v, 0, 1, 1, ema) > 0) {

            double precio = SymbolInfoDouble(_Symbol, SYMBOL_BID);

            string potential_dir = (precio > ema[0]) ? "BUY" : "SELL";

            if(!ValidarTechosSuelos(potential_dir)) {
                txtVoz = txtVeredicto;
            } else {
                if(!enFaseAnalisis) {
                    txtVoz = "Buscando entrada...";
                    txtVeredicto = "ESPERANDO...";
                }
            }
        } else {
            if(!enFaseAnalisis) {
                txtVoz = "Buscando entrada...";
                txtVeredicto = "ESPERANDO...";
            }
        }

    }

}

void OnTick() {

    ActualizarTextosEstado();

    if(trialExpirado) { BotActivo = false; ActualizarInterfazMaster(); return; }

    if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) { txtVoz = "TRADING NO PERMITIDO"; return; }

    ProcesarComandosTelegram();

    ActualizarEstadoMaster();

    ganadoHoy = CalcularGanadoHoy();
    ganadoTotal = CalcularGanadoTotal();

    flotante = CalcularProfit();

    spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / GetPipSize();

    balanceCuenta = AccountInfoDouble(ACCOUNT_BALANCE);
    flotanteTotalCuenta = CalcularFlotanteCuentaTotal();
    gananciaHoyCuenta = CalcularGanadoHoyCuentaTotal();
    ActualizarPresenciaMultiBot();

    double multCent = EsCuentaCent ? 100.0 : 1.0;

    // --- PROTECCIONES NUEVAS V11.34 ---
    if(UsarLimitePerdidaDiaria) {
        double balanceRiesgo = AccountInfoDouble(ACCOUNT_BALANCE);
        double perdidaDiariaMax = balanceRiesgo * (MathAbs(MaxPerdidaDiariaPct) / 100.0);
        double pnlDiaConFlotante = ganadoHoy + flotante;
        if(balanceRiesgo > 0 && pnlDiaConFlotante <= -perdidaDiariaMax) {
            txtVoz = "LIMITE PERDIDA DIARIA ALCANZADO.";
            if(ArraySize(pos) > 0) CerrarTodo();
            enFaseAnalisis = false;
            ActualizarInterfazMaster();
            return;
        }
    }

    if(TimeTradeServer() < pausaCircuitBreaker) {
        txtVeredicto = "STANDBY CIRCUIT BREAKER HASTA: " + TimeToString(pausaCircuitBreaker, TIME_MINUTES);
        if(ArraySize(pos) > 0) {
            GestionarCosechaSniper();
        }
        ActualizarInterfazMaster();
        return;
    }

    bool volatilidadBloqueada = false;
    if(VolatilidadExtrema()) {
        pausaCircuitBreaker = TimeTradeServer() + (60 * MinutosPausaVolatilidadExtrema);
        txtVeredicto = "VOLATILIDAD EXTREMA: PAUSA PROTECTORA";
        // No cerramos posiciones existentes por este filtro; el SL servidor y la gestión de cesta mandan.
        volatilidadBloqueada = true;
        if(ArraySize(pos) == 0) enFaseAnalisis = false;
    }

    ulong ultimoDealPerdedor = ObtenerUltimoDealPerdedor();
    if(MaxPerdidasConsecutivas > 0 && ContarPerdidasConsecutivas() >= MaxPerdidasConsecutivas &&
       ultimoDealPerdedor > 0 && ultimoDealPerdedor != ultimoDealCircuitBreaker) {
        ultimoDealCircuitBreaker = ultimoDealPerdedor;
        pausaCircuitBreaker = TimeTradeServer() + (60 * MinutosPausaCircuitBreaker);
        txtVeredicto = "CIRCUIT BREAKER: PERDIDAS CONSECUTIVAS";
        if(ArraySize(pos) > 0) CerrarTodo();
        enFaseAnalisis = false;
        ActualizarInterfazMaster();
        return;
    }

    double targetActual = (ArraySize(pos) >= LimitePosicionesSOS) ? (ProfitBreakEven * multCent) : (ProfitNetoFlush * multCent);

    if(ArraySize(pos) > 0 && flotante >= targetActual) {

        txtVoz = "CIERRE NETO ALCANZADO.";
        double profCierre = flotante;
        CerrarTodo();
        enFaseAnalisis = false;
        EnviarTelegram(StringFormat("💰 *MAIKO RISK*: Cierre Neto Alcanzado!\n• Beneficio Cesta: +$%.2f\n• Ganado Hoy: $%.2f", profCierre, ganadoHoy + profCierre));
        return;

    }

    if(ganadoHoy >= (TargetDiario * multCent)) {
        txtVoz = "OBJETIVO DIARIO CUMPLIDO.";
        if(ArraySize(pos) > 0) CerrarTodo();
        ActualizarInterfazMaster();
        EnviarTelegram(StringFormat("🎯 *MAIKO RISK*: ¡Objetivo Diario Cumplido!\n• Ganado Hoy: $%.2f", ganadoHoy));
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

                    BotActivo = false;

                }

                ActualizarInterfazMaster();

                return;

            }

        }

    }

    GestionarCosechaSniper(); ActualizarRadarMaster(); ActualizarInterfazMaster();

    if(!BotActivo) return;

    if(ArraySize(pos) > 0) {
        if(!volatilidadBloqueada) GestionarRefuerzoInteligente();
        return;
    }

    if(volatilidadBloqueada) return;

    if(ArraySize(pos) == 0) {

        datetime serverTime = TimeTradeServer();

        // Si el broker cerró una posición por Stop Loss (Server SL), asegurar pausa de enfriamiento
        if(UsarPausaTrasStopLoss && MinutosPausaTrasStopLoss > 0) {
            datetime dealPerdedorTime = 0;
            long dealPerdedorType = -1;
            ulong ticketSL = ObtenerUltimoDealPerdedorInfo(dealPerdedorTime, dealPerdedorType);
            if(ticketSL > 0 && dealPerdedorTime > 0) {
                datetime finPausaSL = dealPerdedorTime + (60 * MinutosPausaTrasStopLoss);
                if(serverTime < finPausaSL) {
                    if(pausaStopLoss < finPausaSL) pausaStopLoss = finPausaSL;
                    txtVeredicto = "STANDBY POR SL HASTA: " + TimeToString(pausaStopLoss, TIME_MINUTES);
                    return;
                }
            }
        }

        if(serverTime < pausaStopLoss) return;

        MqlDateTime time;

        TimeToStruct(serverTime, time);

        bool enHorario = true;

        if(time.hour < HoraInicioOperativa || time.hour >= HoraFinOperativa) enHorario = false;

        if(time.day_of_week == 5) {
            if(time.hour >= 15 && !OperarViernesNoche) enHorario = false; // Dejar de operar a las 15:00 los viernes
            if(time.hour >= 21 && ArraySize(pos) > 0) CerrarTodo(); // No dejar operaciones abiertas en fin de semana
        }

        if(time.day_of_week == 0 || time.day_of_week == 6) enHorario = false;

        if(UsarHorarioBloqueo && time.hour >= HoraInicioBloqueo && time.hour < HoraFinBloqueo) enHorario = false;

        if(!enHorario) return;

        if(!enFaseAnalisis) { enFaseAnalisis = true; proximoAtaque = serverTime + 60; txtVoz = "Buscando entrada..."; ActualizarInterfazMaster(); }

        if(serverTime >= proximoAtaque && serverTime >= pausaVolatilidad) {

            string d = ""; if(ValidarEstructuraScholar(d)) EjecutarAtaqueScholar(d);

        }

    }

}


//+------------------------------------------------------------------+
//| V11.34 - Utilidades de riesgo y robustez                         |
//+------------------------------------------------------------------+
double ObtenerATR_M1() {
    if(hATR_v == INVALID_HANDLE) return 0.0;
    double atr[1];
    if(CopyBuffer(hATR_v, 0, 1, 1, atr) <= 0) return 0.0;
    return atr[0];
}

double ObtenerATRMedio() {
    if(hATR_v == INVALID_HANDLE || ATRPromedioPeriodos <= 1) return 0.0;
    double vals[];
    ArrayResize(vals, ATRPromedioPeriodos);
    int copied = CopyBuffer(hATR_v, 0, 1, ATRPromedioPeriodos, vals);
    if(copied <= 0) return 0.0;
    double sum = 0.0;
    int n = 0;
    for(int i=0; i<copied; i++) {
        if(vals[i] > 0) { sum += vals[i]; n++; }
    }
    return (n > 0) ? sum / n : 0.0;
}

double GetPipSize() {
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    if(point <= 0) point = _Point;
    return point * 10.0;
}

bool VolatilidadExtrema() {
    if(ATRVolatilidadMaxRatio <= 0) return false;
    double atr = ObtenerATR_M1();
    double atrMedio = ObtenerATRMedio();
    if(atr <= 0 || atrMedio <= 0) return false;
    return (atr >= atrMedio * ATRVolatilidadMaxRatio);
}

ulong ObtenerUltimoDealPerdedor() {
    datetime dTime = 0;
    long dType = -1;
    return ObtenerUltimoDealPerdedorInfo(dTime, dType);
}

ulong ObtenerUltimoDealPerdedorInfo(datetime &dealTime, long &dealType) {
    dealTime = 0;
    dealType = -1;
    if(!HistorySelect(0, TimeCurrent() + 86400)) return 0;
    string currentSym = _Symbol;
    StringToUpper(currentSym);
    int totalDeals = HistoryDealsTotal();
    for(int i = totalDeals - 1; i >= 0; i--) {
        ulong ticket = HistoryDealGetTicket(i);
        if(ticket <= 0) continue;
        long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
        if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT) continue;
        if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != ExpertMagic) continue;
        string sym = HistoryDealGetString(ticket, DEAL_SYMBOL);
        StringToUpper(sym);
        if(sym != currentSym) continue;
        double pnl = HistoryDealGetDouble(ticket, DEAL_PROFIT)
                   + HistoryDealGetDouble(ticket, DEAL_COMMISSION)
                   + HistoryDealGetDouble(ticket, DEAL_SWAP);
        if(pnl < 0.0) {
            dealTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
            dealType = HistoryDealGetInteger(ticket, DEAL_TYPE);
            return ticket;
        }
    }
    return 0;
}

int ContarPerdidasConsecutivas() {
    if(MaxPerdidasConsecutivas <= 0) return 0;
    if(!HistorySelect(0, TimeCurrent() + 86400)) return 0;

    int totalDeals = HistoryDealsTotal();
    int perdidas = 0;
    string currentSym = _Symbol;
    StringToUpper(currentSym);

    for(int i = totalDeals - 1; i >= 0; i--) {
        ulong ticket = HistoryDealGetTicket(i);
        if(ticket <= 0) continue;

        long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
        if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT) continue;

        long magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
        if(magic != ExpertMagic) continue;

        string sym = HistoryDealGetString(ticket, DEAL_SYMBOL);
        StringToUpper(sym);
        if(sym != currentSym) continue;

        double p = HistoryDealGetDouble(ticket, DEAL_PROFIT)
                 + HistoryDealGetDouble(ticket, DEAL_COMMISSION)
                 + HistoryDealGetDouble(ticket, DEAL_SWAP);

        if(p < 0.0) perdidas++;
        else if(p > 0.0) break;

        if(perdidas >= MaxPerdidasConsecutivas) break;
    }
    HistorySelect(0, TimeCurrent() + 86400);
    return perdidas;
}

double NormalizarLote(double lot) {
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    if(step <= 0) step = 0.01;
    if(maxLot <= 0) maxLot = MaxLoteIndividual;
    lot = MathMax(minLot, MathMin(maxLot, lot));
    lot = MathFloor(lot / step + 1e-9) * step;
    int volDigits = 2;
    if(step < 0.01) volDigits = 3;
    if(step < 0.001) volDigits = 4;
    return NormalizeDouble(lot, volDigits);
}

double CalcularRiesgoMonetarioLote(ENUM_ORDER_TYPE orderType, double volume, double entryPrice, double stopPrice) {
    if(volume <= 0.0 || entryPrice <= 0.0 || stopPrice <= 0.0) return 0.0;
    double pnl = 0.0;
    if(!OrderCalcProfit(orderType, _Symbol, volume, entryPrice, stopPrice, pnl)) return 0.0;
    return MathAbs(pnl);
}

double CalcularRiesgoAbierto() {
    double riesgo = 0.0;
    for(int i=PositionsTotal()-1; i>=0; i--) {
        ulong ticket = PositionGetTicket(i);
        if(ticket <= 0 || !PositionSelectByTicket(ticket)) continue;
        if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
        if(PositionGetInteger(POSITION_MAGIC) != ExpertMagic) continue;
        double sl = PositionGetDouble(POSITION_SL);
        if(sl <= 0.0) continue;
        ENUM_POSITION_TYPE pt = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        ENUM_ORDER_TYPE ot = (pt == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
        double entry = PositionGetDouble(POSITION_PRICE_OPEN);
        double volume = PositionGetDouble(POSITION_VOLUME);
        riesgo += CalcularRiesgoMonetarioLote(ot, volume, entry, sl);
    }
    return riesgo;
}

double CalcularLotePorRiesgo(double entryPrice, double stopPrice) {
    if(!UsarRiesgoDinamico) return NormalizarLote(MathMin(LoteAtaque, MaxLoteIndividual));

    if(stopPrice <= 0.0) return NormalizarLote(MathMin(LoteAtaque, MaxLoteIndividual));

    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double riskMoney = equity * (MathAbs(RiesgoPorCestaPct) / 100.0);
    if(equity <= 0 || riskMoney <= 0) return NormalizarLote(MathMin(LoteAtaque, MaxLoteIndividual));

    ENUM_ORDER_TYPE orderType = (stopPrice < entryPrice) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
    double profitForOneLot = 0.0;
    if(!OrderCalcProfit(orderType, _Symbol, 1.0, entryPrice, stopPrice, profitForOneLot))
        return NormalizarLote(MathMin(LoteAtaque, MaxLoteIndividual));

    double lossOneLot = MathAbs(profitForOneLot);
    if(lossOneLot <= 0) return NormalizarLote(MathMin(LoteAtaque, MaxLoteIndividual));

    double lot = riskMoney / lossOneLot;
    lot = MathMin(lot, MaxLoteIndividual);
    lot = MathMin(lot, LoteAtaque);
    lot = NormalizarLote(lot);

    // Si el volumen mínimo del broker supera el riesgo objetivo, no operamos.
    // Esto evita que la normalización del lote pueda violar el % de riesgo.
    double riesgoReal = CalcularRiesgoMonetarioLote(orderType, lot, entryPrice, stopPrice);
    if(riesgoReal > riskMoney * 1.000001) return 0.0;
    return lot;
}

bool CalcularSLServidor(string direction, double entryPrice, double &sl) {
    if(!UsarStopServidorATR) { sl = 0.0; return true; }
    double atr = ObtenerATR_M1();
    if(atr <= 0 || ATRStopMultiplicador <= 0) return false;

    double distancia = atr * ATRStopMultiplicador;
    if(direction == "BUY") sl = entryPrice - distancia;
    else sl = entryPrice + distancia;

    int stopsLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    double minDist = stopsLevel * _Point;
    if(direction == "BUY") {
        if(entryPrice - sl < minDist) sl = entryPrice - minDist;
    } else {
        if(sl - entryPrice < minDist) sl = entryPrice + minDist;
    }
    sl = NormalizeDouble(sl, _Digits);
    return true;
}

bool ValidarEstructuraScholar(string &decision) {

    if(spreadActual > MaxSpreadPips) { txtVeredicto = "SPD ALTO: " + DoubleToString(spreadActual,1); return false; }

    double rangoM1 = (iHigh(_Symbol, PERIOD_M1, 1) - iLow(_Symbol, PERIOD_M1, 1)) / GetPipSize();

    if(rangoM1 > MaxRangoVelaM1) {

        txtVeredicto = "VOLATILIDAD ALTA (ESPERANDO)"; pausaVolatilidad = TimeTradeServer() + (60 * MinutosPausaTrasSusto); return false;

    }

    double body = MathAbs(iOpen(_Symbol, PERIOD_M1, 1) - iClose(_Symbol, PERIOD_M1, 1)) / GetPipSize();

    if(body < 0.5) { txtVeredicto = "MERCADO ESTANCADO (POCA LUZ)"; return false; }

    double upperWick = (iHigh(_Symbol, PERIOD_M1, 1) - MathMax(iOpen(_Symbol, PERIOD_M1, 1), iClose(_Symbol, PERIOD_M1, 1))) / GetPipSize();

    double lowerWick = (MathMin(iOpen(_Symbol, PERIOD_M1, 1), iClose(_Symbol, PERIOD_M1, 1)) - iLow(_Symbol, PERIOD_M1, 1)) / GetPipSize();

    double ema[1];

    if(CopyBuffer(hEMA_v, 0, 1, 1, ema) <= 0) {

        txtVeredicto = "ESPERANDO HISTORIAL EMA...";

        return false;

    }

    double c1 = iClose(_Symbol, PERIOD_M1, 1);
    double o1 = iOpen(_Symbol, PERIOD_M1, 1);
    double precio = c1; bool porEncima = (precio > ema[0]);

    // --- FILTRO PROFESIONAL: VELA DE CONFIRMACIÓN Y RECHAZO DE DOJI ---
    double candleRange = (iHigh(_Symbol, PERIOD_M1, 1) - iLow(_Symbol, PERIOD_M1, 1)) / GetPipSize();
    if(candleRange > 0 && (body / candleRange) < 0.35) {
        txtVeredicto = "VELA INDECISION / DOJI (NO OPERAR)";
        return false;
    }
    if(porEncima && c1 <= o1) {
        txtVeredicto = "ESPERANDO VELA ALCISTA M1";
        return false;
    }
    if(!porEncima && c1 >= o1) {
        txtVeredicto = "ESPERANDO VELA BAJISTA M1";
        return false;
    }

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

    
    // ADD BOLLINGER BANDS EXHAUSTION FILTER
    if(UsarFiltroBollinger && hBands_v != INVALID_HANDLE) {
        double bb_upper[1], bb_lower[1];
        if(CopyBuffer(hBands_v, 1, 1, 1, bb_upper) > 0 && CopyBuffer(hBands_v, 2, 1, 1, bb_lower) > 0) {
            double current_close = iClose(_Symbol, PERIOD_M1, 1); 
            if(decision == "SELL" && current_close <= bb_lower[0] + (3.0 * GetPipSize())) {
                txtVeredicto = "AGOTAMIENTO BB INFERIOR"; return false;
            }
            if(decision == "BUY" && current_close >= bb_upper[0] - (3.0 * GetPipSize())) {
                txtVeredicto = "AGOTAMIENTO BB SUPERIOR"; return false;
            }
        }
    }

    if(!ValidarTechosSuelos(decision)) return false;

    txtVeredicto = "ESTRUCTURA CONFIRMADA";

    return true;

}

void EjecutarAtaqueScholar(string d) {
    if(TimeTradeServer() - ultimoAtaque < 3) return;

    double entry = (d == "BUY") ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                                 : SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double sl = 0.0;
    if(!CalcularSLServidor(d, entry, sl)) {
        txtVeredicto = "NO SE PUDO CALCULAR SL ATR";
        return;
    }

    double stopParaCalculo = sl;
    if(stopParaCalculo <= 0.0) {
        double atr = ObtenerATR_M1();
        if(atr <= 0 || ATRStopMultiplicador <= 0) return;
        stopParaCalculo = (d == "BUY") ? entry - (atr * ATRStopMultiplicador)
                                       : entry + (atr * ATRStopMultiplicador);
    }

    double loteTotalRiesgo = CalcularLotePorRiesgo(entry, stopParaCalculo);
    if(loteTotalRiesgo <= 0) return;

    int ruedasSolicitadas = MathMax(1, RuedasAmetralladora);
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    if(minLot <= 0) minLot = 0.01;

    // El lote calculado representa el riesgo TOTAL de la entrada.
    // No se multiplica por el número de ruedas. Si el volumen por rueda
    // quedaría por debajo del mínimo del broker, reducimos las ruedas.
    int ruedasEfectivas = ruedasSolicitadas;
    int maxRuedasPorVolumen = (int)MathFloor((loteTotalRiesgo + 1e-12) / minLot);
    if(maxRuedasPorVolumen < 1) maxRuedasPorVolumen = 1;
    ruedasEfectivas = MathMin(ruedasEfectivas, maxRuedasPorVolumen);

    double lotePorRueda = NormalizarLote(loteTotalRiesgo / ruedasEfectivas);
    if(lotePorRueda < minLot) return;

    double loteTotalEntrada = lotePorRueda * ruedasEfectivas;
    if(volTotal + loteTotalEntrada > MaxLoteTotal) return;

    for(int i=0; i<ruedasEfectivas; i++) {
        bool ok = false;
        if(d == "BUY") ok = trade.Buy(lotePorRueda, _Symbol, 0, sl, 0, TradeComment);
        else           ok = trade.Sell(lotePorRueda, _Symbol, 0, sl, 0, TradeComment);

        if(!ok) {
            Print("V11.34: fallo entrada ", d, " retcode=", trade.ResultRetcode(), " desc=", trade.ResultRetcodeDescription());
        }
    }

    ultimoAtaque = TimeTradeServer();
    enFaseAnalisis = false;

    double prEntrada = (d == "BUY") ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
    EnviarTelegramConTeclado(StringFormat("🚀 *MAIKO RISK*: Nueva Entrada Ejecutada!\n• Operación: %s\n• Par: %s\n• Lote: %.2f\n• Precio: %.2f\n• SL Servidor: %.2f",
                                (d == "BUY" ? "🟢 COMPRA" : "🔴 VENTA"), _Symbol, loteTotalEntrada, prEntrada, sl));
    EnviarTelemetria();
}

void GestionarRefuerzoInteligente() {
    if(ArraySize(pos) >= LimitePosicionesSOS) {
        txtVeredicto = "MAXIMO OPERACIONES ALCANZADO";
        return;
    }

    double distPips = MathAbs(SymbolInfoDouble(_Symbol, SYMBOL_BID) - pos[0].pr) / GetPipSize();
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

    double volLado = 0;
    int type = pos[0].t;
    for(int i=0; i<ArraySize(pos); i++) if(pos[i].t == type) volLado += pos[i].v;

    double volRefuerzo = volLado * (MultiplicadorRefuerzo - 1.0);
    if(volRefuerzo < 0.01) volRefuerzo = 0.01;
    if(volRefuerzo > MaxLoteIndividual) volRefuerzo = MaxLoteIndividual;
    volRefuerzo = NormalizarLote(volRefuerzo);

    if(volTotal + volRefuerzo > MaxLoteTotal) { txtVoz = "LIMITE LOTE ALCANZADO"; return; }
    if(TimeTradeServer() - ultimoAtaque < 3) return;

    string d = (type == POSITION_TYPE_BUY) ? "BUY" : "SELL";
    double entry = (d == "BUY") ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double sl = 0.0;
    if(!CalcularSLServidor(d, entry, sl)) return;

    // Mantener el riesgo objetivo de la CESTA también durante un SOS.
    if(UsarRiesgoDinamico) {
        double equity = AccountInfoDouble(ACCOUNT_EQUITY);
        double riesgoObjetivo = equity * (MathAbs(RiesgoPorCestaPct) / 100.0);
        double riesgoActual = CalcularRiesgoAbierto();
        double riesgoDisponible = riesgoObjetivo - riesgoActual;
        ENUM_ORDER_TYPE ot = (type == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
        double riesgoUnaUnidad = CalcularRiesgoMonetarioLote(ot, 1.0, entry, sl);
        if(riesgoDisponible <= 0.0 || riesgoUnaUnidad <= 0.0) return;
        double maxVolPorRiesgo = riesgoDisponible / riesgoUnaUnidad;
        volRefuerzo = MathMin(volRefuerzo, maxVolPorRiesgo);
        volRefuerzo = NormalizarLote(volRefuerzo);
        if(volRefuerzo <= 0.0 || CalcularRiesgoMonetarioLote(ot, volRefuerzo, entry, sl) > riesgoDisponible * 1.000001) return;
    }

    bool ok = false;
    if(type == POSITION_TYPE_BUY) ok = trade.Buy(volRefuerzo, _Symbol, 0, sl, 0, TradeComment + "_SOS");
    else                         ok = trade.Sell(volRefuerzo, _Symbol, 0, sl, 0, TradeComment + "_SOS");

    if(ok) txtVeredicto = "DISPARO SOS RESCATE EJECUTADO 🛡️⚡";
    else   txtVeredicto = "ERROR EJECUTANDO SOS: " + trade.ResultRetcodeDescription();

    ultimoAtaque = TimeTradeServer();
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


double CalcularGanadoTotal() { 
    double total = 0;
    string gvReset = StringFormat("MAIKO_V1134_STARTTIME_%d_%I64d", ExpertMagic, AccountInfoInteger(ACCOUNT_LOGIN));
    datetime fromTime = trialStart;
    if(GlobalVariableCheck(gvReset)) {
        fromTime = (datetime)GlobalVariableGet(gvReset);
    }
    if(fromTime <= 0) fromTime = trialStart;
    if(fromTime <= 0) fromTime = TimeCurrent() - (86400 * 30);

    if(!HistorySelect(fromTime, TimeCurrent() + 86400)) return 0; 
    int totalDeals = HistoryDealsTotal();

    string currentSym = _Symbol;
    StringToUpper(currentSym);

    for(int i = 0; i < totalDeals; i++) {
        ulong t = HistoryDealGetTicket(i);
        if(t <= 0) continue;

        long entryType = HistoryDealGetInteger(t, DEAL_ENTRY);
        if(entryType != DEAL_ENTRY_OUT && entryType != DEAL_ENTRY_INOUT) continue;

        string dealSym = HistoryDealGetString(t, DEAL_SYMBOL);
        StringToUpper(dealSym);

        if(dealSym != currentSym && StringFind(currentSym, dealSym) < 0 && StringFind(dealSym, currentSym) < 0) continue;

        long magic = HistoryDealGetInteger(t, DEAL_MAGIC);
        if(magic != ExpertMagic) continue; // Estrictamente solo operaciones de ESTE bot

        double prof = HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_COMMISSION) + HistoryDealGetDouble(t, DEAL_SWAP);
        total += prof;
    }
    HistorySelect(0, TimeCurrent() + 86400);
    return NormalizeDouble(total, 2); 
}

double CalcularGanadoHoy() { 
    double total = 0;

    MqlDateTime currStruct;
    TimeToStruct(TimeTradeServer(), currStruct);
    currStruct.hour = 0; currStruct.min = 0; currStruct.sec = 0;
    datetime startOfToday = StructToTime(currStruct);

    if(!HistorySelect(startOfToday, TimeCurrent() + 86400)) return 0; 
    int totalDeals = HistoryDealsTotal();

    string currentSym = _Symbol;
    StringToUpper(currentSym);

    for(int i = 0; i < totalDeals; i++) {
        ulong t = HistoryDealGetTicket(i);
        if(t <= 0) continue;

        long entryType = HistoryDealGetInteger(t, DEAL_ENTRY);
        if(entryType != DEAL_ENTRY_OUT && entryType != DEAL_ENTRY_INOUT) continue;

        string dealSym = HistoryDealGetString(t, DEAL_SYMBOL);
        StringToUpper(dealSym);

        if(dealSym != currentSym && StringFind(currentSym, dealSym) < 0 && StringFind(dealSym, currentSym) < 0) continue;

        long magic = HistoryDealGetInteger(t, DEAL_MAGIC);
        if(magic != ExpertMagic) continue; // Estrictamente solo operaciones de ESTE bot

        double prof = HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_COMMISSION) + HistoryDealGetDouble(t, DEAL_SWAP);
        total += prof;
    }
    HistorySelect(0, TimeCurrent() + 86400);
    return NormalizeDouble(total, 2); 
}

double CalcularGanadoHoyCuentaTotal() {
    double total = 0;
    MqlDateTime currStruct;
    TimeToStruct(TimeTradeServer(), currStruct);
    currStruct.hour = 0; currStruct.min = 0; currStruct.sec = 0;
    datetime startOfToday = StructToTime(currStruct);

    if(!HistorySelect(startOfToday, TimeCurrent() + 86400)) return 0;
    int totalDeals = HistoryDealsTotal();
    for(int i = 0; i < totalDeals; i++) {
        ulong t = HistoryDealGetTicket(i);
        if(t <= 0) continue;
        long entryType = HistoryDealGetInteger(t, DEAL_ENTRY);
        if(entryType != DEAL_ENTRY_OUT && entryType != DEAL_ENTRY_INOUT) continue;
        double prof = HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_COMMISSION) + HistoryDealGetDouble(t, DEAL_SWAP);
        total += prof;
    }
    HistorySelect(0, TimeCurrent() + 86400);
    return NormalizeDouble(total, 2);
}

double CalcularFlotanteCuentaTotal() {
    double total = 0;
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong t = PositionGetTicket(i);
        if(t > 0 && PositionSelectByTicket(t)) {
            total += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_COMMISSION) + PositionGetDouble(POSITION_SWAP);
        }
    }
    return NormalizeDouble(total, 2);
}

void ActualizarPresenciaMultiBot() {
    long login = AccountInfoInteger(ACCOUNT_LOGIN);
    string myGv = StringFormat("MAIKO_HEARTBEAT_%d_%I64d", ExpertMagic, login);
    GlobalVariableSet(myGv, (double)TimeCurrent());

    int count = 0;
    bool hasRisk = false;
    bool hasAgosto = false;
    int totalGV = GlobalVariablesTotal();

    for(int i = 0; i < totalGV; i++) {
        string gvName = GlobalVariableName(i);
        if(StringFind(gvName, "MAIKO_HEARTBEAT_") == 0) {
            string loginSuffix = StringFormat("_%I64d", login);
            if(StringFind(gvName, loginSuffix) > 0) {
                datetime lastBeat = (datetime)GlobalVariableGet(gvName);
                if(TimeCurrent() - lastBeat <= 35) {
                    count++;
                    if(StringFind(gvName, "113300") >= 0) hasRisk = true;
                    if(StringFind(gvName, "111222") >= 0) hasAgosto = true;
                }
            }
        }
    }

    // Comprobar también si en las posiciones abiertas hay tickets de otros magics
    for(int p = PositionsTotal() - 1; p >= 0; p--) {
        ulong pt = PositionGetTicket(p);
        if(pt > 0 && PositionSelectByTicket(pt)) {
            long pmagic = PositionGetInteger(POSITION_MAGIC);
            if(pmagic == 111222 && !hasAgosto) {
                hasAgosto = true;
                count++;
            }
        }
    }

    totalBotsActivos = (count > 0) ? count : 1;
    if(hasRisk && hasAgosto) {
        listaBotsActivos = "2 BOTS (RISK + AGOSTO)";
    } else if(totalBotsActivos > 1) {
        listaBotsActivos = StringFormat("%d BOTS ACTIVOS", totalBotsActivos);
    } else {
        listaBotsActivos = "1 BOT (RISK ACTIVO)";
    }
}



void RefrescarYDibujarFlechasHistorial() {
    datetime fromTime = TimeCurrent() - (86400 * 7); // Últimos 7 días
    if(!HistorySelect(fromTime, TimeCurrent())) return;

    int totalDeals = HistoryDealsTotal();
    for(int i = 0; i < totalDeals; i++) {
        ulong ticket = HistoryDealGetTicket(i);
        if(ticket <= 0) continue;

        string dealSymbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
        if(dealSymbol != _Symbol) continue;

        long entryType = HistoryDealGetInteger(ticket, DEAL_ENTRY);
        if(entryType != DEAL_ENTRY_IN) continue; // Solo entradas iniciales

        long magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
        string comment = HistoryDealGetString(ticket, DEAL_COMMENT);

        bool esDeEsteBot = (magic == ExpertMagic ||
                            StringFind(comment, "11.34") >= 0 ||
                            StringFind(comment, "SHIELD") >= 0 || StringFind(comment, "GOLD") >= 0);

        if(esDeEsteBot) {
            long type = HistoryDealGetInteger(ticket, DEAL_TYPE);
            datetime dealTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
            double dealPrice = HistoryDealGetDouble(ticket, DEAL_PRICE);

            string objName = StringFormat("MAIKO_Arr_%d", ticket);

            // SOLO CREAR SI NO EXISTE (Evita parpadeo 100%)
            if(ObjectFind(0, objName) < 0) {
                int barShift = iBarShift(_Symbol, _Period, dealTime);
                double arrowPrice = dealPrice;
                if(barShift >= 0) {
                    if(type == DEAL_TYPE_BUY) {
                        arrowPrice = iLow(_Symbol, _Period, barShift) - (10.0 * GetPipSize());
                    } else if(type == DEAL_TYPE_SELL) {
                        arrowPrice = iHigh(_Symbol, _Period, barShift) + (10.0 * GetPipSize());
                    }
                }

                if(ObjectCreate(0, objName, OBJ_ARROW, 0, dealTime, arrowPrice)) {
                    if(type == DEAL_TYPE_BUY) {
                        ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, 233); // Flecha Azul Arriba
                        ObjectSetInteger(0, objName, OBJPROP_COLOR, clrDodgerBlue);
                    } else if(type == DEAL_TYPE_SELL) {
                        ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, 234); // Flecha Roja Abajo
                        ObjectSetInteger(0, objName, OBJPROP_COLOR, clrRed);
                    }
                    ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
                    ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
                    ObjectSetInteger(0, objName, OBJPROP_BACK, true); // Detrás del HUD y del gráfico
                    ObjectSetInteger(0, objName, OBJPROP_ZORDER, 0);
                    ObjectSetString(0, objName, OBJPROP_TOOLTIP, StringFormat("Entrada %s @ %.2f", type == DEAL_TYPE_BUY ? "COMPRA" : "VENTA", dealPrice));
                }
            }
        }
    }
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

void EnviarTelegramConTeclado(string mensaje) {
    if(!UsarTelegramNotif || TelegramBotToken == "" || TelegramChatID == "") return;
    if(MQLInfoInteger(MQL_TESTER)) return;

    string url = "https://api.telegram.org/bot" + TelegramBotToken + "/sendMessage";
    string teclado = "{\"keyboard\":["
                     "[{\"text\":\"📊 Estado General\"}],"
                     "[{\"text\":\"🛑 Pausar AGOSTO\"},{\"text\":\"🛑 Pausar RISK\"}],"
                     "[{\"text\":\"▶️ Activar AGOSTO\"},{\"text\":\"▶️ Activar RISK\"}],"
                     "[{\"text\":\"🚨 Cerrar AGOSTO\"},{\"text\":\"🚨 Cerrar RISK\"}],"
                     "[{\"text\":\"☠️ CERRAR AMBOS\"}]"
                     "],\"resize_keyboard\":true,\"one_time_keyboard\":false}";

    string payload = StringFormat("{\"chat_id\":\"%s\",\"text\":\"%s\",\"parse_mode\":\"Markdown\",\"reply_markup\":%s}", TelegramChatID, mensaje, teclado);
    
    char postData[];
    StringToCharArray(payload, postData, 0, WHOLE_ARRAY, CP_UTF8);
    int postSize = ArraySize(postData);
    if(postSize > 0 && postData[postSize - 1] == 0) ArrayResize(postData, postSize - 1);

    char result[];
    string resultHeaders;
    string headers = "Content-Type: application/json; charset=utf-8\r\n";

    WebRequest("POST", url, headers, 3000, postData, result, resultHeaders);
}

void EnviarTelegram(string mensaje) {
    EnviarTelegramConTeclado(mensaje);
}

void ProcesarComandosTelegram() {
    if(!UsarTelegramNotif || TelegramBotToken == "" || TelegramChatID == "") return;
    if(MQLInfoInteger(MQL_TESTER)) return;

    static datetime ultimoCheck = 0;
    if(TimeLocal() - ultimoCheck < 3) return; // Chequear cada 3 segundos reloj local
    ultimoCheck = TimeLocal();

    static long ultimoUpdateId = 0;
    string url = StringFormat("https://api.telegram.org/bot%s/getUpdates?offset=%d&limit=5", TelegramBotToken, ultimoUpdateId + 1);
    
    char postData[];
    char result[];
    string resultHeaders;
    string headers = "Content-Type: application/json\r\n";

    ResetLastError();
    int res = WebRequest("GET", url, headers, 2000, postData, result, resultHeaders);
    if(res == -1) {
        return;
    }
    if(res == 200) {
        string json = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
        
        // Buscar update_id
        int posUp = StringFind(json, "\"update_id\":");
        while(posUp >= 0) {
            int finUp = StringFind(json, ",", posUp);
            if(finUp > posUp) {
                string upStr = StringSubstr(json, posUp + 12, finUp - (posUp + 12));
                long upId = StringToInteger(upStr);
                if(upId > ultimoUpdateId) ultimoUpdateId = upId;
            }
            posUp = StringFind(json, "\"update_id\":", posUp + 12);
        }

        // Detectar si recibimos orden de cierre: selectiva o general
        if(StringFind(json, "Cerrar RISK") >= 0 || StringFind(json, "/cerrar_risk") >= 0 || StringFind(json, "CERRAR AMBOS") >= 0 || StringFind(json, "/cerrar_todo") >= 0 || StringFind(json, "/kill") >= 0) {
            Print("TELEGRAM: Comando de emergencia recibido para RISK. Cerrando posiciones...");
            CerrarTodo();
            EnviarTelegramConTeclado("🚨 *MAIKO RISK*: Posiciones cerradas por comando de Telegram.");
            EnviarTelemetria();
        }
        else if(StringFind(json, "Pausar RISK") >= 0 || StringFind(json, "/pausar_risk") >= 0 || StringFind(json, "/apagar_risk") >= 0) {
            BotActivo = false;
            ActualizarInterfazMaster();
            EnviarTelegramConTeclado("🛑 *MAIKO RISK*: Bot PAUSADO desde Telegram.");
            EnviarTelemetria();
        }
        else if(StringFind(json, "Activar RISK") >= 0 || StringFind(json, "/activar_risk") >= 0 || StringFind(json, "/encender_risk") >= 0) {
            BotActivo = true;
            ActualizarInterfazMaster();
            EnviarTelegramConTeclado("▶️ *MAIKO RISK*: Bot ACTIVADO desde Telegram.");
            EnviarTelemetria();
        }
        else if(StringFind(json, "Estado General") >= 0 || StringFind(json, "/estado") >= 0 || StringFind(json, "Estado") >= 0) {
            double bal = AccountInfoDouble(ACCOUNT_BALANCE);
            double eq = AccountInfoDouble(ACCOUNT_EQUITY);
            string detallesPos = "";
            int nP = ArraySize(pos);
            if(nP > 0) {
                detallesPos = "\n• *Posiciones Activas:*";
                for(int p = 0; p < nP; p++) {
                    detallesPos += StringFormat("\n  - #%I64u %s %.2f @ %.2f (P/L: $%.2f)",
                                                pos[p].ticket,
                                                pos[p].t == POSITION_TYPE_BUY ? "BUY" : "SELL",
                                                pos[p].v, pos[p].pr,
                                                pos[p].p + pos[p].c + pos[p].s);
                }
            } else {
                detallesPos = "\n• *Posiciones:* Sin operaciones activas";
            }
            string msg = StringFormat("📊 *MAIKO RISK*\n• Saldo: $%.2f | Equidad: $%.2f\n• Flotante: $%.2f | Ganado Hoy: $%.2f%s\n• Estado: %s",
                                      bal, eq, flotante, ganadoHoy, detallesPos, BotActivo ? "OPERANDO ✅" : "PAUSADO 🛑");
            EnviarTelegramConTeclado(msg);
        }
    }
}

void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result) {
    if(MQLInfoInteger(MQL_TESTER)) return;
    if(trans.type == TRADE_TRANSACTION_DEAL_ADD) {
        ulong dealTicket = trans.deal;
        if(dealTicket > 0) {
            if(HistoryDealSelect(dealTicket)) {
                long entry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
                long magic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
                if(magic == ExpertMagic && (entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_INOUT)) {
                    double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT)
                                  + HistoryDealGetDouble(dealTicket, DEAL_SWAP)
                                  + HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
                    double vol = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
                    double price = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
                    long dealType = HistoryDealGetInteger(dealTicket, DEAL_TYPE);
                    
                    double divFactor = EsCuentaCent ? 100.0 : 1.0;
                    double normProfit = profit / divFactor;
                    ganadoHoy = CalcularGanadoHoy();

                    string icon = normProfit >= 0 ? "💰" : "🔴";
                    string msg = StringFormat("%s *MAIKO RISK*: Operación Cerrada!\n• Ticket: #%I64u\n• Tipo: %s\n• Lote: %.2f\n• Precio Cierre: %.2f\n• Resultado: %s$%.2f\n• Ganado Hoy: $%.2f",
                                              icon, dealTicket,
                                              (dealType == DEAL_TYPE_BUY ? "BUY" : "SELL"),
                                              vol, price,
                                              normProfit >= 0 ? "+" : "", normProfit,
                                              ganadoHoy / divFactor);
                    EnviarTelegramConTeclado(msg);
                    EnviarTelemetria();
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

    RefrescarYDibujarFlechasHistorial();

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
    int x = HUD_X, y = PosY_HUD, w = 470, h = 335; 
    CrearBoton("MAIKO_Bg", x, y, w, h, "", ColorBody, clrNONE, CORNER_LEFT_UPPER); 
    CrearBoton("MAIKO_Head", x, y, w, 35, "", ColorHeader, clrNONE, CORNER_LEFT_UPPER); 
    CrearLabel("MAIKO_T", x+10, y+10, HUD_Branding, ColorMain, 11, CORNER_LEFT_UPPER); 
    CrearBoton("MAIKO_BtnMin", x+w-30, y+7, 22, 22, "_", ColorBody, clrWhite, CORNER_LEFT_UPPER); 
    string tfs[]={"W1","D1","H4","H1","M15","M5","M1"}; 
    for(int i=0; i<7; i++) { 
        int px = x + 10 + (i * 60); 
        CrearLabel("MAIKO_L_"+tfs[i], px, y+45, tfs[i]+":", clrWhite, 8, CORNER_LEFT_UPPER); 
        CrearLabel("MAIKO_Radar_"+tfs[i], px+25, y+45, "o", clrGray, 10, CORNER_LEFT_UPPER); 
    } 
    CrearLabel("MAIKO_Spd", x+w-120, y+65, "SPD: 0.0", clrWhite, 8, CORNER_LEFT_UPPER);  
    CrearLabel("MAIKO_Vered", x+10, y+75, txtVeredicto, clrCyan, 8, CORNER_LEFT_UPPER); 

    // --- METRICAS GLOBALES DE CUENTA ---
    CrearLabel("MAIKO_BalUI", x+10, y+100, "BALANCE CUENTA: $0.00", clrWhite, 9, CORNER_LEFT_UPPER);
    CrearLabel("MAIKO_MultiBotUI", x+10, y+118, "BOTS EN CUENTA: 1", clrDeepSkyBlue, 9, CORNER_LEFT_UPPER);

    // --- METRICAS DE ESTE BOT ---
    CrearLabel("MAIKO_Hoy", x+10, y+140, "HOY (ESTE BOT): $0.00", clrSpringGreen, 11, CORNER_LEFT_UPPER); 
    CrearLabel("MAIKO_Total", x+10, y+162, "TOTAL (ESTE BOT): $0.00", clrGold, 11, CORNER_LEFT_UPPER);
    CrearLabel("MAIKO_Flot", x+10, y+185, "FLOTANTE (BOT/CUENTA): $0.00", clrWhite, 10, CORNER_LEFT_UPPER); 

    // --- ESTADO Y MERCADO ---
    CrearLabel("MAIKO_MetaTP", x+10, y+208, "ESTADO: BUSCANDO ENTRADA EN M1...", clrYellow, 9, CORNER_LEFT_UPPER); 
    CrearLabel("MAIKO_RsiUI", x+10, y+228, "RSI(14): --", clrCyan, 9, CORNER_LEFT_UPPER);
    CrearLabel("MAIKO_TrialUI", x+10, y+248, "TRIAL: DIA 1 DE 30", clrYellow, 9, CORNER_LEFT_UPPER);

    // --- BOTONES LATERALES ---
    CrearBoton("MAIKO_BtnP", x+w-120, y+115, 110, 50, "ENCENDER", clrDarkGreen, clrWhite, CORNER_LEFT_UPPER); 
    CrearBoton("MAIKO_BtnC", x+w-120, y+175, 110, 35, "CERRAR", clrDarkRed, clrWhite, CORNER_LEFT_UPPER); 

    CrearBoton("MAIKO_Foot", x, y+h-40, w, 40, "", ColorHeader, clrNONE, CORNER_LEFT_UPPER); 
    CrearLabel("MAIKO_Voz", x+10, y+h-25, txtVoz, ColorMain, 8, CORNER_LEFT_UPPER); 
}

void ActualizarInterfazMaster() { 
    double multCent = EsCuentaCent ? 100.0 : 1.0; 
    ObjectSetString(0, "MAIKO_BalUI", OBJPROP_TEXT, StringFormat("BALANCE CUENTA: $%.2f | HOY TOTAL: $%.2f", balanceCuenta / multCent, gananciaHoyCuenta / multCent));
    ObjectSetString(0, "MAIKO_MultiBotUI", OBJPROP_TEXT, StringFormat("PANEL MULTI-BOT: %s", listaBotsActivos));

    ObjectSetString(0, "MAIKO_Hoy", OBJPROP_TEXT, StringFormat("HOY (ESTE BOT): $%.2f", ganadoHoy / multCent)); 
    ObjectSetString(0, "MAIKO_Total", OBJPROP_TEXT, StringFormat("TOTAL (ESTE BOT): $%.2f", ganadoTotal / multCent)); 
    
    if(flotanteTotalCuenta != flotante) {
        ObjectSetString(0, "MAIKO_Flot", OBJPROP_TEXT, StringFormat("FLOTANTE BOT: $%.2f | CUENTA: $%.2f", flotante / multCent, flotanteTotalCuenta / multCent));
    } else {
        ObjectSetString(0, "MAIKO_Flot", OBJPROP_TEXT, StringFormat("FLOTANTE BOT: $%.2f", flotante / multCent));
    }

    ObjectSetString(0, "MAIKO_Spd", OBJPROP_TEXT, StringFormat("SPD: %.1f", spreadActual)); 

    double rsiVal[1];
    if(CopyBuffer(hRSI_v, 0, 1, 1, rsiVal) > 0) {
        double rsi = rsiVal[0];
        if(rsi >= MaxRsiCompra) {
            ObjectSetString(0, "MAIKO_RsiUI", OBJPROP_TEXT, StringFormat("RSI(14): %.1f | SOBRECOMPRA (NO COMPRAR)", rsi));
            ObjectSetInteger(0, "MAIKO_RsiUI", OBJPROP_COLOR, clrOrangeRed);
        } else if(rsi <= MinRsiVenta) {
            ObjectSetString(0, "MAIKO_RsiUI", OBJPROP_TEXT, StringFormat("RSI(14): %.1f | SOBREVENTA (NO VENDER)", rsi));
            ObjectSetInteger(0, "MAIKO_RsiUI", OBJPROP_COLOR, clrDeepSkyBlue);
        } else {
            ObjectSetString(0, "MAIKO_RsiUI", OBJPROP_TEXT, StringFormat("RSI(14): %.1f | NEUTRO (OPERATIVA OK)", rsi));
            ObjectSetInteger(0, "MAIKO_RsiUI", OBJPROP_COLOR, clrCyan);
        }
    }

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

    ObjectSetInteger(0, "MAIKO_Flot", OBJPROP_COLOR, flotante >= 0 ? clrSpringGreen : clrRed); 
    ObjectSetString(0, "MAIKO_Vered", OBJPROP_TEXT, txtVeredicto); 
    ObjectSetString(0, "MAIKO_Voz", OBJPROP_TEXT, txtVoz); 
    ObjectSetString(0, "MAIKO_BtnP", OBJPROP_TEXT, BotActivo ? "APAGAR" : "ENCENDER"); 
    ObjectSetInteger(0, "MAIKO_BtnP", OBJPROP_BGCOLOR, BotActivo ? clrMaroon : clrDarkGreen); 

    double metaTP = CalcularMetaEscapeTP();
    if(metaTP > 0) {
        ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, StringFormat("ESCAPE TP: %.2f", metaTP));
    } else {
        ObjectSetString(0, "MAIKO_MetaTP", OBJPROP_TEXT, "ESTADO: BUSCANDO ENTRADA EN M1...");
    }
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

    ObjectSetInteger(0, "MAIKO_Bg", OBJPROP_YSIZE, hudMinimizado ? 35 : 335); 

    ObjectSetString(0, "MAIKO_BtnMin", OBJPROP_TEXT, hudMinimizado ? "+" : "_"); 

    long tf = hudMinimizado ? OBJ_NO_PERIODS : OBJ_ALL_PERIODS; 

    string objs[] = {"MAIKO_Vered", "MAIKO_BalUI", "MAIKO_MultiBotUI", "MAIKO_Hoy", "MAIKO_Total", "MAIKO_Flot", "MAIKO_Spd", "MAIKO_Foot", "MAIKO_Voz", "MAIKO_BtnP", "MAIKO_BtnC", "MAIKO_MetaTP", "MAIKO_TrialUI"}; 

    for(int i=0; i<13; i++) ObjectSetInteger(0, objs[i], OBJPROP_TIMEFRAMES, tf); 

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

    ProcesarComandosTelegram();

    ActualizarEstadoMaster();
    ganadoHoy = CalcularGanadoHoy();
    ganadoTotal = CalcularGanadoTotal();
    flotante = CalcularProfit();
    spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / GetPipSize();

    balanceCuenta = AccountInfoDouble(ACCOUNT_BALANCE);
    flotanteTotalCuenta = CalcularFlotanteCuentaTotal();
    gananciaHoyCuenta = CalcularGanadoHoyCuentaTotal();
    ActualizarPresenciaMultiBot();

    ActualizarTextosEstado();
    ActualizarRadarMaster();
    ActualizarInterfazMaster();

    int interval = 60; // Heartbeat suave cada 60s (el resto sincroniza por eventos al abrir/cerrar ordenes)

    if(TimeLocal() - ultimoSync >= interval) {

        EnviarTelemetria();

        ultimoSync = TimeLocal();

    }

}

string JsonEscape(string value) {
    StringReplace(value, "\\", "\\\\");
    StringReplace(value, "\"", "\\\"");
    StringReplace(value, "\r", "\\r");
    StringReplace(value, "\n", "\\n");
    StringReplace(value, "\t", "\\t");
    return value;
}

void EnviarTelemetria() {
    string account = JsonEscape(IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)));
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
            JsonEscape(_Symbol), pos[i].v, pos[i].pr, 0.0, 0.0, (pos[i].p + pos[i].c + pos[i].s) / divFactor
        );
    }
    posJson += "]";
    string narrative = JsonEscape(txtVeredicto);
    string json = StringFormat(
        "{\"purchaseId\":\"%s\",\"account\":\"%s\",\"balance\":%.2f,\"equity\":%.2f,\"pnl_today\":%.2f,\"status\":\"%s\",\"symbol\":\"%s\",\"narrative\":\"%s\",\"armed\":%s,\"isReal\":%s,\"version\":\"11.34.1\",\"positions\":%s,\"trialExpirado\":%s,\"diasRestantes\":%d}",
        JsonEscape(MiLicencia), account, normBalance, normEquity,
        normGanadoHoy, JsonEscape(status), JsonEscape(_Symbol), narrative,
        BotActivo ? "true" : "false", 
        (AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL) ? "true" : "false",
        posJson,
        trialExpirado ? "true" : "false", diasRestantes
    );
    char postData[];
    StringToCharArray(json, postData, 0, StringLen(json), CP_UTF8);
    char result[];
    string headers = "Content-Type: application/json";
    string resHeaders;
    int res = WebRequest("POST", SyncURL, headers, 8000, postData, result, resHeaders);
    if(res == -1 || res >= 1000) {
        string altURL = (StringFind(SyncURL, "www.") >= 0) ? "https://kopytrading.com/api/sync-positions" : "https://www.kopytrading.com/api/sync-positions";
        res = WebRequest("POST", altURL, headers, 8000, postData, result, resHeaders);
    }
    if(res == 200 && ArraySize(result) > 0) {
        string response = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
        if(StringFind(response, "CLOSE_ALL") >= 0) {
            CerrarTodo();
            Print("KOPYTRADING REMOTE: Cierre total ejecutado.");
        }
        if(StringFind(response, "\"armed\":true") >= 0 || StringFind(response, "armed':true") >= 0 || StringFind(response, "armed:true") >= 0) {
            if(!BotActivo) { BotActivo = true; Print("KOPYTRADING REMOTE: Bot ENCENDIDO."); }
        } else if(StringFind(response, "\"armed\":false") >= 0 || StringFind(response, "armed':false") >= 0 || StringFind(response, "armed:false") >= 0) {
            if(BotActivo) {
                BotActivo = false;
                Print("KOPYTRADING REMOTE: Bot DESACTIVADO (PAUSADO).");
            }
        }
    }
}

bool ValidarTechosSuelos(string decision) {

    double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    double point_pips = GetPipSize();

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

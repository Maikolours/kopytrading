//+------------------------------------------------------------------+
//|            ELITE GOLD MAIKO SNIPER v11.30 | NORMAL HISTORICO     |
//|       "INSTITUTIONAL EDITION" | FIX FINAL SIN PUNTOS            |
//+------------------------------------------------------------------+
//| Restored for Gold/Normal version - behaving 100% like original  |
//+------------------------------------------------------------------+
#property copyright "Elite Gold MAIKO Sniper"
#property version   "11.30"
#property strict

#include <Trade\Trade.mqh>

// --- CONFIGURACION DE LICENCIA ---
input group "━━━━━━ 🔑 𝗟 𝗜 𝗖 𝗘 𝗡 𝗖 𝗜 𝗔   𝗗 𝗘   𝗖 𝗢 𝗡 𝗘 𝗫 𝗜 𝗢 𝗡 ━━━━━━"
input string   MiLicencia                 = "";          // 🔑 Clave de Licencia o Correo Usuario
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
input int      HoraInicioOperativa        = 9;           // 🔔 Hora de Inicio Operaciones (Broker)
input int      HoraFinOperativa           = 19;          // 🔕 Hora de Cierre Operaciones (Broker)
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
string         HUD_Branding               = "MAIKO v11.30 | NORMAL HISTORICO";
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
input string   TradeComment               = "MAIKO_NORMAL_HIST"; // 📝 Comentario para Órdenes (Trade Comment)

// Globales
CTrade trade;
const int ExpertMagic = 111222;
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
    trade.SetExpertMagicNumber(ExpertMagic);
    trade.SetAsyncMode(true);
    hEMA_v = iMA(_Symbol, _Period, PeriodoMediaFiltro, 0, MODE_EMA, PRICE_CLOSE);
    hRSI_v = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
    
    for(int i=0; i<7; i++) {
        hRadar[i] = iMA(_Symbol, etfs[i], PeriodoMediaFiltro, 0, MODE_EMA, PRICE_CLOSE);
    }
    
    AgregarIndicadoresVisuales();
    CrearInterfazMaster();
    ChartSetInteger(0, CHART_FOREGROUND, false); ChartSetInteger(0, CHART_SHOW_TRADE_HISTORY, false);
      
    trialStart = 0;
    diasRestantes = 9999;
    trialExpirado = false;
    
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
    if(ganadoHoy >= (TargetDiario * multCent)) {
        txtVoz = "OBJETIVO DIARIO CUMPLIDO."; if(ArraySize(pos) > 0) CerrarTodo(); BotActivo = false; ActualizarInterfazMaster(); return;
    }
    if(ProteccionBeneficioDiario > 0.0 && ganadoHoy > (ProteccionBeneficioDiario * multCent)) {
        if((ganadoHoy + flotante) <= (ProteccionBeneficioDiario * multCent) && ArraySize(pos) > 0) {
            txtVoz = "PROTECCION BENEFICIO."; CerrarTodo(); enFaseAnalisis = false; BotActivo = false; ActualizarInterfazMaster(); return;
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
    if(ArraySize(pos) > 0) { GestionarRefuerzoInteligente(); return; }
    if(ArraySize(pos) == 0) {
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
    
    double entryPrice = pos[0].pr;
    int type = pos[0].t;
    double currentPrice = (type == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    double distPips = 0.0;
    if(type == POSITION_TYPE_BUY) {
        distPips = (entryPrice - currentPrice) / _Point / 10;
    } else {
        distPips = (currentPrice - entryPrice) / _Point / 10;
    }
    
    string dirStr = (type == POSITION_TYPE_BUY) ? "COMPRA" : "VENTA";
    txtVoz = StringFormat("MAIKO: Vigilando %s activo...", dirStr);
    
    if(distPips < 0) {
        txtVeredicto = StringFormat("VIGILANDO %s | EN BENEFICIO: +%.1f pips", dirStr, -distPips);
        return;
    }
    
    if(distPips < DistanciaRefuerzoPips) {
        txtVeredicto = StringFormat("VIGILANDO %s | CONTRA: %.1f pips | SOS a: %.1f", dirStr, distPips, DistanciaRefuerzoPips);
        return;
    }
    
    bool forzar = (distPips >= MaxPipsHueco) || (iBarShift(_Symbol, PERIOD_M1, pos[0].time) >= MaxVelasHueco);
    bool velaGiro = (type == POSITION_TYPE_BUY) ? 
                    (iClose(_Symbol, PERIOD_M1, 1) > iOpen(_Symbol, PERIOD_M1, 1) && iClose(_Symbol, PERIOD_M1, 2) > iOpen(_Symbol, PERIOD_M1, 2)) : 
                    (iClose(_Symbol, PERIOD_M1, 1) < iOpen(_Symbol, PERIOD_M1, 1) && iClose(_Symbol, PERIOD_M1, 2) < iOpen(_Symbol, PERIOD_M1, 2));
    
    if(!velaGiro && !forzar) {
        txtVeredicto = StringFormat("ZONA SOS ALCANZADA | ESPERANDO 2 VELAS GIRO M1 (Pips: %.1f)", distPips);
        return;
    }
    
    double volLado = 0; for(int i=0; i<ArraySize(pos); i++) if(pos[i].t == type) volLado += pos[i].v;
    double volRefuerzo = NormalizeDouble(volLado * (MultiplicadorRefuerzo - 1.0), 2);
    if(volRefuerzo < 0.01) volRefuerzo = 0.01;
    if(volRefuerzo > MaxLoteIndividual) volRefuerzo = MaxLoteIndividual;
    if(volTotal + volRefuerzo > MaxLoteTotal) { txtVoz = "LIMITE LOTE ALCANZADO"; return; }
    
    if(TimeTradeServer() - ultimoAtaque < 3) return;
    if(type == POSITION_TYPE_BUY) trade.Buy(volRefuerzo, _Symbol, 0, 0, 0, TradeComment + "_SOS"); 
    else trade.Sell(volRefuerzo, _Symbol, 0, 0, 0, TradeComment + "_SOS");
    ultimoAtaque = TimeTradeServer();
    txtVeredicto = "DISPARO SOS RESCATE EJECUTADO 🛡️⚡";
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
    
    CrearLabel("MAIKO_Vered", x+10, y+85, txtVeredicto, clrCyan, 9, CORNER_LEFT_UPPER); 
    CrearLabel("MAIKO_Hoy", x+10, y+125, "GANADO HOY: $0.00", clrSpringGreen, 14, CORNER_LEFT_UPPER); 
    CrearLabel("MAIKO_Flot", x+10, y+160, "FLOTANTE: $0.00", clrWhite, 12, CORNER_LEFT_UPPER); 
    CrearLabel("MAIKO_MetaTP", x+10, y+190, "ESTADO: BUSCANDO ENTRADA EN M1...", clrYellow, 10, CORNER_LEFT_UPPER); 
    CrearLabel("MAIKO_TrialUI", x+10, y+215, "LICENCIA: ACTIVA", clrYellow, 11, CORNER_LEFT_UPPER);
    CrearLabel("MAIKO_Spd", x+w-120, y+65, "SPD: 0.0", clrWhite, 8, CORNER_LEFT_UPPER);  
    
    CrearBoton("MAIKO_Foot", x, y+h-40, w, 40, "", ColorHeader, clrNONE, CORNER_LEFT_UPPER); 
    CrearLabel("MAIKO_Voz", x+10, y+h-25, txtVoz, ColorMain, 10, CORNER_LEFT_UPPER); 
    CrearBoton("MAIKO_BtnP", x+w-120, y+110, 110, 50, "ENCENDER", clrDarkGreen, clrWhite, CORNER_LEFT_UPPER); 
    CrearBoton("MAIKO_BtnC", x+w-120, y+175, 110, 35, "CERRAR", clrDarkRed, clrWhite, CORNER_LEFT_UPPER); 
}

void ActualizarInterfazMaster() { 
    double multCent = EsCuentaCent ? 100.0 : 1.0; 
    ObjectSetString(0, "MAIKO_Hoy", OBJPROP_TEXT, StringFormat("GANADO HOY: $%.2f", ganadoHoy / multCent)); 
    ObjectSetString(0, "MAIKO_Flot", OBJPROP_TEXT, StringFormat("FLOTANTE: $%.2f", flotante / multCent)); 
    ObjectSetString(0, "MAIKO_Spd", OBJPROP_TEXT, StringFormat("SPD: %.1f", spreadActual)); 
    ObjectSetString(0, "MAIKO_TrialUI", OBJPROP_TEXT, "LICENCIA: ACTIVA");
    ObjectSetInteger(0, "MAIKO_TrialUI", OBJPROP_COLOR, clrYellow);
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
    string objs[] = {"MAIKO_Vered", "MAIKO_Hoy", "MAIKO_Flot", "MAIKO_Spd", "MAIKO_Foot", "MAIKO_Voz", "MAIKO_BtnP", "MAIKO_BtnC", "MAIKO_MetaTP", "MAIKO_TrialUI"}; 
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
    ChartSetInteger(0, CHART_SHOW_TRADE_HISTORY, false);
    ActualizarEstadoMaster();
    int interval = (ArraySize(pos) > 0) ? 15 : 60;
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
        "\"armed\":%s,\"isReal\":%s,\"version\":\"11.30\",\"positions\":%s,"
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

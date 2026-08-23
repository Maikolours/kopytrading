//+------------------------------------------------------------------+

//|            MAIKO PRO GOLD M1 SHIELD DEMO v11.32                  |

//|               "INSTITUTIONAL EDITION"                            |

//+------------------------------------------------------------------+

//| Restored for Gold/Normal version - behaving 100% like original  |

//+------------------------------------------------------------------+

#property copyright "MAIKO PRO GOLD SHIELD DEMO"

#property version   "11.32"

#property strict



#include <Trade\Trade.mqh>

// --- CONFIGURACION ---
input group "------- 🔑 LICENCIA DE CONEXION -------"
input string   MiLicencia                 = "";          // 🔑 Clave de Licencia o Correo Usuario
input int      DiasDeTrial                = 30;          // ⏳ Días de Prueba (Solo Trial)
const bool     EsCuentaCent               = false;       // CUENTA NORMAL / GOLD / DEMO EN DOLARES (Hardcoded para evitar uso cruzado)

// --- TELEMETRIA ---
string SyncURL = "https://www.kopytrading.com/api/sync-positions";
int SyncIntervalSec = 2;
datetime ultimoSync = 0;

// --- FILTROS ---
input double   MaxRangoVelaM1             = 40.0;        // 📏 Rango Máximo Vela M1 (Puntos GOLD)
input double   MaxSpreadPips              = 5.0;         // 📏 Spread Máximo Permitido (Puntos GOLD)
input double   SensibilidadMechaReal      = 3.0;         // 📏 Sensibilidad Mecha vs Cuerpo
input int      MinutosPausaTrasSusto      = 1;           // ⏳ Minutos de Pausa tras Volatilidad
input double   MaxRsiCompra               = 60.0;        // 📊 RSI Máximo para Compras (Filtro Techos)
input double   MinRsiVenta                = 35.0;        // 📊 RSI Mínimo para Ventas (Filtro Suelos)

// --- TENDENCIA Y LOTAJE ---
input bool     UsarFiltroM1_RSI           = true;        // 🛡️ Activar Escudo M1 (RSI Extremo)
input double   RsiExigidoCompraM1         = 70.0;        // 🟢 M1 RSI Máximo Permitido (COMPRA)
input double   RsiExigidoVentaM1          = 30.0;        // 🔴 M1 RSI Mínimo Permitido (VENTA)
input double   DistanciaCascadaPips       = 0.0;         // 🌊 Distancia disparo Cascada M1 (0 = Desactivada por seguridad)
input group "------- ⏱️ FILTROS MULTI-TEMPORALIDAD -------"
input bool ConfirmarTendenciaM15 = true;    // 📉 Confirmar Tendencia Secundaria (M15) (OBLIGATORIO)
input bool ConfirmarTendenciaM5  = false;   // 📉 Confirmar Tendencia Micro (M5)

int PeriodoMediaFiltro = 50;

int RuedasAmetralladora = 1;



double MaxPipsHueco = 50.0;
int MaxVelasHueco = 5;

double ProteccionBeneficioDiario = 0.0;

// --- FILTRO DE TECHOS Y SUELOS (SOPORTES Y RESISTENCIAS) ---
input group "------- 🌑 FILTROS DE RUIDO Y MERCADO -------"
input bool             UsarFiltroTechosSuelos     = true;        // 🏛️ Activar Filtro Techos y Suelos M15 (S/R)
input ENUM_TIMEFRAMES  TimeframeTechosSuelos      = PERIOD_M15;  // 📅 Temporalidad para Techos/Suelos M15
input int              PeriodoTechosSuelos        = 192;         // 🗓️ Período de Velas M15 a Analizar
input double           DistanciaTechoSueloPips    = 50.0;        // 🛡️ Distancia Mínima M15 para Bloquear (Pips)

// --- FILTROS ADICIONALES MULTI-TEMPORALIDAD (H1 y H4) ---
input bool             UsarFiltroTechosSuelosH1   = true;        // 🛡️ Activar Filtro S/R en H1
input int              PeriodoTechosSuelosH1      = 48;          // 🔢 Período H1 a Analizar (Velas)
input double           DistanciaTechoSueloPipsH1  = 60.0;        // 🛡️ Distancia Mínima H1 (Pips)

input bool             UsarFiltroTechosSuelosH4   = true;        // 🛡️ Activar Filtro S/R en H4
input int              PeriodoTechosSuelosH4      = 30;          // 🔢 Período H4 a Analizar (Velas)
input double           DistanciaTechoSueloPipsH4  = 120.0;       // 📏 Distancia Mínima H4 (Pips)

input bool             UsarFiltroTechosSuelosD1   = true;        // 🛡️ Activar Filtro S/R en D1
input int              PeriodoTechosSuelosD1      = 20;          // 🔢 Período D1 a Analizar (Velas)
input double           DistanciaTechoSueloPipsD1  = 200.0;       // 📏 Distancia Mínima D1 (Pips)

input bool             UsarFiltroTechosSuelosW1   = true;        // 🛡️ Activar Filtro S/R en W1
input int              PeriodoTechosSuelosW1      = 10;          // 🔢 Período W1 a Analizar (Velas)
input double           DistanciaTechoSueloPipsW1  = 350.0;       // 📏 Distancia Mínima W1 (Pips)

// --- FILTRO DE AGOTAMIENTO DE VELAS (RECHAZO DE MECHA M15) ---
input bool             UsarFiltroAgotamientoM15   = true;        // 🛑 Activar Filtro Agotamiento M15
input double           MinPorcentajeMechaM15      = 40.0;        // 🌡️ % Mínimo Mecha Reversa (40.0 = 40%)

// --- CONFIRMACION DE RUPTURA ---
input bool             UsarConfirmacionRuptura    = true;        // ✅ Confirmar Ruptura de S/R con Vela Cerrada
input ENUM_TIMEFRAMES  TimeframeConfirmacion      = PERIOD_M15;  // 📅 Temporalidad de Confirmación (M5/M15)

// --- OPERATIVA Y LOTES ---
input group "------- 🏛️ FILTRO DE TECHOS Y SUELOS -------"
input double   LoteAtaque                 = 0.03;        // 🚀 Volumen Entrada Inicial (Ataque)
input double   MultiplicadorRefuerzo      = 1.5;         // ✖️ Multiplicador Lote de Rescate (SOS)
input double   DistanciaRefuerzoPips      = 50.0;        // 📏 Distancia Mínima para Abrir SOS (Pips amplios)
input double   MaxLoteTotal               = 0.50;        // 🚫 Lote Máximo Acumulado Permitido
input double   MaxLoteIndividual          = 0.05;        // 🚫 Volumen Máximo por Operación SOS

// --- COBRAR BENEFICIOS (TAKE PROFIT) ---
input group "------- 📉 TENDENCIA Y DIRECCION -------"
input double   ProfitCosechaIndividual    = 2.5;         // 💵 Beneficio Cierre SOS Individual ($)
input double   TargetDiario               = 100.0;       // 🎯 Meta de Beneficio Diario ($)
input double   ProfitNetoFlush            = 5.0;         // 💵 Beneficio Cierre Total Cesta ($)
input double   ProfitBreakEven            = 0.50;        // 🛡️ Beneficio Mínimo Break Even Cesta ($)

// --- HORARIOS OPERATIVOS ---
input group "------- 📈 CONFIGURACION Y LOTES -------"
input int      HoraInicioOperativa        = 9;           // 🕒 Hora de Inicio Operaciones (Broker)
input int      HoraFinOperativa           = 21;          // ⏰ Hora de Cierre Operaciones (Broker)
input bool     OperarViernesNoche         = false;       // 🌃 Permitir Operaciones Viernes Noche
input bool     UsarHorarioBloqueo         = false;       // 📰 Evitar Noticias (Bloqueo Horario)
input int      HoraInicioBloqueo          = 14;          // ⏰ Hora Inicio Bloqueo Noticias
input int      HoraFinBloqueo             = 16;          // ⏰ Hora Fin Bloqueo Noticias

// --- PROTECCIONES Y SEGURIDAD ---
input group "------- 📏 DISTANCIAS Y CASCADA -------"
input int      LimitePosicionesSOS        = 2;           // 📉 Límite Máximo Posiciones SOS
input bool     UsarStopLossDinero         = true;        // 🛡️ Activar Stop Loss por Dinero Fijo en Flotante
input double   MaxPerdidaFlotanteDinero   = 100.0;       // 💵 Pérdida Máxima Flotante Permitida ($ USD)
input bool     UsarStopLossPorcentaje     = false;       // 🛡️ Activar Stop Loss por % Cuenta
input double   PorcentajeStopLoss         = 10.0;        // 📉 Porcentaje de Pérdida Máxima...
input bool     UsarPausaTrasStopLoss      = true;        // ⏸️ Pausar Bot tras un Stop Loss
input int      MinutosPausaTrasStopLoss   = 30;          // ⏳ Minutos de Pausa tras Stop Loss (30 min enfriamiento)

// --- HUD ---
input group "------- 💰 COBRAR BENEFICIOS (TP) -------"
string         HUD_Branding               = "MAIKO PRO SHIELD DEMO";
input color    ColorMain                  = clrGold;     // 🎨 Color Principal HUD (Acento)
input color    ColorHeader                = C'30,30,30'; // 🎨 Color Encabezado Panel HUD
input color    ColorBody                  = C'20,20,20'; // 🎨 Color Cuerpo Panel HUD
input int      HUD_X                      = 15;          // 📐 Posición X en Pantalla (Pixeles)
input int      PosY_HUD                   = 25;          // 📐 Posición Y en Pantalla (Pixeles)
bool           ShowW1                     = true;
bool           ShowD1                     = true;
bool           ShowH4                     = true;
bool           ShowH1                     = true;
bool           ShowM15                    = true;
bool           ShowM5                     = true;
bool           ShowM1                     = true;

// --- COMENTARIOS ---
input group "------- ⏰ HORARIOS OPERATIVOS -------"
input string   TradeComment               = "MAIKO_SHIELD_DEMO";        // 🏷️ Comentario para Órdenes (Trade Comment)


// Globales

CTrade trade;
const int ExpertMagic = 888888;



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
int hEMA_M1 = INVALID_HANDLE;
int hEMA_M1_9 = INVALID_HANDLE;

int hRSI_v = INVALID_HANDLE;
int hRSI_M1 = INVALID_HANDLE;

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

    if(AccountInfoInteger(ACCOUNT_TRADE_MODE) != ACCOUNT_TRADE_MODE_DEMO) {
        Alert("MAIKO SHIELD DEMO: ESTE BOT SOLO FUNCIONA EN CUENTAS DEMO.");
        return INIT_FAILED;
    }
    
    // Inicializar Contador de Trial por cuenta MT5
    string gvName = "MAIKO_TRIAL_START_" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
    if(GlobalVariableCheck(gvName)) {
        trialStart = (datetime)GlobalVariableGet(gvName);
    } else {
        trialStart = TimeCurrent();
        GlobalVariableSet(gvName, (double)trialStart);
    }
    
    int maxDias = DiasDeTrial;
    if(maxDias > 30) maxDias = 30;
    diasRestantes = maxDias - (int)((TimeCurrent() - trialStart) / 86400);
    if(diasRestantes <= 0) { 
        trialExpirado = true; 
        BotActivo = false;
        Alert("MAIKO SHIELD DEMO: Tu período de prueba de 30 días ha expirado en esta cuenta.");
        return(INIT_FAILED);
    }

    trade.SetExpertMagicNumber(ExpertMagic);
    trade.SetAsyncMode(true);

    hEMA_v = iMA(_Symbol, _Period, PeriodoMediaFiltro, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_M1 = iMA(_Symbol, PERIOD_M1, 50, 0, MODE_EMA, PRICE_CLOSE);
    hEMA_M1_9 = iMA(_Symbol, PERIOD_M1, 9, 0, MODE_EMA, PRICE_CLOSE);

    hRSI_v = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
    hRSI_M1 = iRSI(_Symbol, PERIOD_M1, 14, PRICE_CLOSE);

    // Inicializar handles de radar de forma estática para optimizar CPU
    for(int i=0; i<7; i++) {
        hRadar[i] = iMA(_Symbol, etfs[i], PeriodoMediaFiltro, 0, MODE_EMA, PRICE_CLOSE);
    }

    AgregarIndicadoresVisuales();
    CrearInterfazMaster();
    ChartSetInteger(0, CHART_FOREGROUND, false); 
    ChartSetInteger(0, CHART_SHOW_TRADE_HISTORY, false);

    trialExpirado = false;
    BotActivo = true;

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
    if(hEMA_M1 != INVALID_HANDLE) IndicatorRelease(hEMA_M1);
    if(hEMA_M1_9 != INVALID_HANDLE) IndicatorRelease(hEMA_M1_9);

    if(hRSI_v != INVALID_HANDLE) IndicatorRelease(hRSI_v);
    if(hRSI_M1 != INVALID_HANDLE) IndicatorRelease(hRSI_M1);

    ChartRedraw(); 

}



void ActualizarTextosEstado() {

    int maxDias = DiasDeTrial;
    if(maxDias > 30) maxDias = 30;
    diasRestantes = maxDias - (int)((TimeTradeServer() - trialStart) / 86400);
    if(diasRestantes <= 0) { trialExpirado = true; BotActivo = false; }

    if(trialExpirado) {
        txtVoz = "TRIAL EXPIRADO.";

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

    bool esViernesNoche = (time.day_of_week == 5 && time.hour >= HoraFinOperativa && !OperarViernesNoche);

    

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



    if(UsarStopLossDinero && ArraySize(pos) > 0) {
        if(flotante <= -MathAbs(MaxPerdidaFlotanteDinero)) {
            txtVoz = "STOP LOSS DINERO ALCANZADO.";
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
        GestionarRefuerzoInteligente();
        // CASCADA SOS M1 (Solo si está explícitamente activada con pips > 0)
        if(DistanciaCascadaPips > 0.0 && TimeTradeServer() - ultimoAtaque > 5 && volTotal < MaxLoteTotal) {
            double emaM1[1];
            if(CopyBuffer(hEMA_M1, 0, 1, 1, emaM1) > 0) {
                double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                int last = ArraySize(pos)-1;
                if(pos[last].pr <= 0.0) return; // FIX: Prevent race condition if price isn't synced yet
                double distProfit = (pos[last].t == POSITION_TYPE_BUY ? bid - pos[last].pr : pos[last].pr - ask) / _Point / 10;
                if(distProfit >= DistanciaCascadaPips) {
                    bool emaOK = (pos[0].t == POSITION_TYPE_BUY && bid > emaM1[0]) || (pos[0].t == POSITION_TYPE_SELL && bid < emaM1[0]);
                    if(emaOK) {
                        double volRefuerzo = NormalizeDouble(volTotal * (MultiplicadorRefuerzo - 1.0), 2);
                        if(volRefuerzo < 0.01) volRefuerzo = 0.01;
                        if(volRefuerzo > MaxLoteIndividual) volRefuerzo = MaxLoteIndividual;
                        if(pos[0].t == POSITION_TYPE_BUY) trade.Buy(volRefuerzo, _Symbol, 0, 0, 0, TradeComment + "_CASCADA");
                        else trade.Sell(volRefuerzo, _Symbol, 0, 0, 0, TradeComment + "_CASCADA");
                        ultimoAtaque = TimeTradeServer();
                        txtVeredicto = "CASCADA EJECUTADA";
                    }
                }
            }
        }
        return;
    }

    if(ArraySize(pos) == 0) {

        datetime serverTime = TimeTradeServer();

        if(serverTime < pausaStopLoss) return;



        MqlDateTime time;

        TimeToStruct(serverTime, time);

        bool enHorario = true;

        if(time.hour < HoraInicioOperativa || time.hour >= HoraFinOperativa) enHorario = false;

        if(time.day_of_week == 5 && time.hour >= HoraFinOperativa && !OperarViernesNoche) enHorario = false;

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

    bool m15_ok = !ConfirmarTendenciaM15 || (porEncima ? c15 > o15 : c15 < o15);
    bool m5_ok = !ConfirmarTendenciaM5 || (porEncima ? c5 > o5 : c5 < o5);

    

    if(!m15_ok) { txtVeredicto = StringFormat("M15 EN CONTRA (C:%.2f O:%.2f)", c15, o15); return false; }

    if(!m5_ok) { txtVeredicto = StringFormat("M5 EN CONTRA (C:%.2f O:%.2f)", c5, o5); return false; }



    decision = (porEncima ? "BUY" : "SELL"); 

    
    
    
    if(UsarFiltroM1_RSI) {
        double rsiM1[1];
        if(CopyBuffer(hRSI_M1, 0, 1, 1, rsiM1) > 0) {
            if(decision == "BUY" && rsiM1[0] >= RsiExigidoCompraM1) {
                txtVeredicto = StringFormat("ESPERANDO RETROCESO M1 (RSI=%.1f >= %.1f)", rsiM1[0], RsiExigidoCompraM1);
                return false;
            }
            if(decision == "SELL" && rsiM1[0] <= RsiExigidoVentaM1) {
                txtVeredicto = StringFormat("ESPERANDO PICO M1 (RSI=%.1f <= %.1f)", rsiM1[0], RsiExigidoVentaM1);
                return false;
            }
        }
    }

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

    double curPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    bool isLosing = (pos[0].t == POSITION_TYPE_BUY) ? (curPrice < pos[0].pr) : (curPrice > pos[0].pr);
    double distPips = MathAbs(curPrice - pos[0].pr) / _Point / 10;
    
    if(!isLosing) distPips = 0; // 🛡️ ESCUDO: Evitar abrir SOS si el precio va a favor (ganancias)

    // Actualizar HUD dinámicamente con detalles de la operación activa
    string dirStr = (pos[0].t == POSITION_TYPE_BUY) ? "COMPRA" : "VENTA";

    txtVoz = StringFormat("MAIKO: Vigilando %s activo...", dirStr);

    

    if(distPips < DistanciaRefuerzoPips) {

        txtVeredicto = StringFormat("VIGILANDO %s | CONTRA: %.1f pips | SOS a: %.1f", dirStr, distPips, DistanciaRefuerzoPips);

        return;

    }

    

    bool forzar = (distPips >= MaxPipsHueco);

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

    // 🛡️ ESCUDO: Tiempo mínimo entre ráfagas SOS (60 segundos en vez de 3) para evitar agrupaciones por latigazos de volatilidad
    if(TimeTradeServer() - ultimoAtaque < 60) return;

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
    int totalDeals = HistoryDealsTotal();
    struct DealData { ulong ticket; long magic; long pos_id; double profit; };
    DealData deals[]; ArrayResize(deals, totalDeals);
    int valid_deals = 0;
    
    for(int i=0; i<totalDeals; i++) {
        ulong t = HistoryDealGetTicket(i);
        if(HistoryDealGetString(t, DEAL_SYMBOL) == _Symbol) {
            deals[valid_deals].ticket = t;
            deals[valid_deals].magic = HistoryDealGetInteger(t, DEAL_MAGIC);
            deals[valid_deals].pos_id = HistoryDealGetInteger(t, DEAL_POSITION_ID);
            deals[valid_deals].profit = HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_COMMISSION) + HistoryDealGetDouble(t, DEAL_SWAP);
            valid_deals++;
        }
    }
    
    for(int i=0; i<valid_deals; i++) {
        long d_magic = deals[i].magic;
        if(d_magic == 0) {
            if(HistorySelectByPosition(deals[i].pos_id)) {
                for(int j=0; j<HistoryDealsTotal(); j++) {
                    ulong t_in = HistoryDealGetTicket(j);
                    if(HistoryDealGetInteger(t_in, DEAL_ENTRY) == DEAL_ENTRY_IN) {
                        d_magic = HistoryDealGetInteger(t_in, DEAL_MAGIC);
                        break;
                    }
                }
            }
        }
        if(d_magic == ExpertMagic || d_magic == 111333) total += deals[i].profit;
    }
    
    HistorySelect(0, TimeCurrent());
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

      int remHours = 0;
      int remMinutes = 0;
      if(diasRestantes > 0) {
          int secs = (int)(86400 - ((TimeCurrent() - trialStart) % 86400));
          remHours = secs / 3600;
          remMinutes = (secs % 3600) / 60;
      }
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
    // Historial eliminado para no molestar
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

        "\"armed\":%s,\"isReal\":%s,\"version\":\"11.31\",\"positions\":%s,"

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

    // --- 3.5. Filtro D1 ---
    if(UsarFiltroTechosSuelosD1) {
        int highest_idx = iHighest(_Symbol, PERIOD_D1, MODE_HIGH, PeriodoTechosSuelosD1, start_bar);
        int lowest_idx = iLowest(_Symbol, PERIOD_D1, MODE_LOW, PeriodoTechosSuelosD1, start_bar);
        if(highest_idx >= 0 && lowest_idx >= 0) {
            double highest_high = iHigh(_Symbol, PERIOD_D1, highest_idx);
            double lowest_low = iLow(_Symbol, PERIOD_D1, lowest_idx);
            
            if(decision == "BUY") {
                double dist_to_ceiling = (highest_high - current_price) / point_pips;
                if(dist_to_ceiling > 0) {
                    if(dist_to_ceiling <= DistanciaTechoSueloPipsD1) {
                        txtVeredicto = StringFormat("TECHO D1 CERCANO (%.1f pips)", dist_to_ceiling);
                        return false;
                    }
                } else {
                    if(UsarConfirmacionRuptura) {
                        double closeVal = iClose(_Symbol, TimeframeConfirmacion, 1);
                        if(closeVal <= highest_high) {
                            txtVeredicto = "ESPERANDO CONFIRMACION RUPTURA TECHO D1";
                            return false;
                        }
                    }
                }
            }
            else if(decision == "SELL") {
                double dist_to_floor = (current_price - lowest_low) / point_pips;
                if(dist_to_floor > 0) {
                    if(dist_to_floor <= DistanciaTechoSueloPipsD1) {
                        txtVeredicto = StringFormat("SUELO D1 CERCANO (%.1f pips)", dist_to_floor);
                        return false;
                    }
                } else {
                    if(UsarConfirmacionRuptura) {
                        double closeVal = iClose(_Symbol, TimeframeConfirmacion, 1);
                        if(closeVal >= lowest_low) {
                            txtVeredicto = "ESPERANDO CONFIRMACION RUPTURA SUELO D1";
                            return false;
                        }
                    }
                }
            }
        }
    }

    // --- 3.6. Filtro W1 ---
    if(UsarFiltroTechosSuelosW1) {
        int highest_idx = iHighest(_Symbol, PERIOD_W1, MODE_HIGH, PeriodoTechosSuelosW1, start_bar);
        int lowest_idx = iLowest(_Symbol, PERIOD_W1, MODE_LOW, PeriodoTechosSuelosW1, start_bar);
        if(highest_idx >= 0 && lowest_idx >= 0) {
            double highest_high = iHigh(_Symbol, PERIOD_W1, highest_idx);
            double lowest_low = iLow(_Symbol, PERIOD_W1, lowest_idx);
            
            if(decision == "BUY") {
                double dist_to_ceiling = (highest_high - current_price) / point_pips;
                if(dist_to_ceiling > 0) {
                    if(dist_to_ceiling <= DistanciaTechoSueloPipsW1) {
                        txtVeredicto = StringFormat("TECHO W1 CERCANO (%.1f pips)", dist_to_ceiling);
                        return false;
                    }
                } else {
                    if(UsarConfirmacionRuptura) {
                        double closeVal = iClose(_Symbol, TimeframeConfirmacion, 1);
                        if(closeVal <= highest_high) {
                            txtVeredicto = "ESPERANDO CONFIRMACION RUPTURA TECHO W1";
                            return false;
                        }
                    }
                }
            }
            else if(decision == "SELL") {
                double dist_to_floor = (current_price - lowest_low) / point_pips;
                if(dist_to_floor > 0) {
                    if(dist_to_floor <= DistanciaTechoSueloPipsW1) {
                        txtVeredicto = StringFormat("SUELO W1 CERCANO (%.1f pips)", dist_to_floor);
                        return false;
                    }
                } else {
                    if(UsarConfirmacionRuptura) {
                        double closeVal = iClose(_Symbol, TimeframeConfirmacion, 1);
                        if(closeVal >= lowest_low) {
                            txtVeredicto = "ESPERANDO CONFIRMACION RUPTURA SUELO W1";
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


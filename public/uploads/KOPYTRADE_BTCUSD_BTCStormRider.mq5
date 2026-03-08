//+------------------------------------------------------------------+
//|          KOPYTRADE_BTCUSD_BTCStormRider v3.1                    |
//|   TREND ALIGNMENT + MULTI-FILTER · USD RISK MANAGEMENT           |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Bot Oficial"
#property version   "3.10"
#property strict
#property description "BTC Storm Rider v3.1 | Alineación de Tendencia + Protección USD"
#property description "Operación Activa 24h con BE y Trailing en Dólares"

#include <Trade\Trade.mqh>

//=== LICENCIA KOPYTRADE ===
input group "=== 🔑 LICENCIA KOPYTRADE ==="
input long     CuentaDemo         = 0;       // Nº cuenta DEMO de MT5 (Trial y Compra)
input long     CuentaReal         = 0;       // Nº cuenta REAL de MT5 (Solo Compra)

//=== SESIONES DE MERCADO ===
input group "=== ⏰ SESIONES DE MERCADO (HORA BROKER) ==="
input int      SesionEuropa_Inicio  = 0;     // Inicio Sesión Europa
input int      SesionEuropa_Fin     = 16;    // Fin Sesión Europa
input int      SesionUS_Inicio      = 14;    // Inicio Sesión USA
input int      SesionUS_Fin         = 24;    // Fin Sesión USA
input bool     OperarEnAsia         = true;  // ¿Operar en sesión Asia?

//=== GESTIÓN DE RIESGO ===
input group "=== 🛡️ GESTIÓN DE RIESGO ==="
input double   LoteInicial           = 0.01;  // Tamaño de posición
input double   MaxRiesgoPorTrade_USD = 50.0;  // Máxima pérdida en $ por trade
input double   ATR_Multiplicador_SL  = 1.5;   // Multiplicador ATR para Stop Loss
input double   ATR_Multiplicador_TP  = 2.0;   // Multiplicador ATR para Take Profit

//=== PROTECCIÓN DE CUENTA ===
input group "=== 🚨 PROTECCIÓN DE CUENTA (ANTI-RACHA) ==="
input double   MaxPerdidaDiaria_USD  = 100.0; // Pérdida máxima diaria permitida ($)
input int      MaxOperacionesDia     = 8;     // Máx operaciones por día

//=== ESTRATEGIA ===
input group "=== 📊 ESTRATEGIA ALINEACIÓN DE TENDENCIA ==="
input int      EMA_Tendencia      = 200;      // EMA de tendencia de fondo
input int      EMA_Rapida         = 21;       // EMA rápida (momentum)
input int      EMA_Lenta          = 55;       // EMA lenta (confirmación)
input int      RSI_Periodo        = 14;       // Período del RSI
input int      RSI_Compra_Min     = 35;       // RSI mínimo para comprar
input int      RSI_Compra_Max     = 72;       // RSI máximo para comprar
input int      RSI_Venta_Min      = 28;       // RSI mínimo para vender
input int      RSI_Venta_Max      = 65;       // RSI máximo para vender
input int      ATR_Periodo        = 14;       // Período del ATR
input double   ATR_Minimo_USD     = 50.0;     // Volatilidad mínima para operar (puntos)

//=== BREAK EVEN ===
input group "=== 🔒 BREAK EVEN ==="
input bool     ActivarBE              = true;  // ¿Activar Break Even?
input double   BE_Activar_USD         = 3.0;   // Activar BE cuando ganes X dólares
input double   BE_Garantia_USD        = 1.0;   // Ganancia asegurada tras BE ($)

//=== TRAILING STOP ===
input group "=== 📈 TRAILING STOP ==="
input bool     ActivarTrailing             = true;  // ¿Activar Trailing Stop?
input double   Trailing_Activar_USD        = 3.0;   // Activar trailing cuando ganes X dólares
input double   Trailing_Distancia_USD      = 2.0;   // Distancia del trailing en dólares
input int      Trailing_Salto_Puntos       = 100;   // Puntos mínimos para mover trailing

//=== CONFIGURACIÓN AVANZADA ===
input group "=== ⚙️ CONFIGURACIÓN AVANZADA ==="
input int      MaxPosiciones     = 2;         // Máx posiciones simultáneas
input int      CooldownMinutos   = 30;        // Minutos de espera entre operaciones
input bool     MostrarPanel      = true;      // Mostrar panel visual en el gráfico
input long     MagicNumber       = 780044;    // ID único del bot

//--- Variables globales internas ---
CTrade trade;
bool   licenseValid    = false;
int    emaTendHandle   = INVALID_HANDLE;
int    emaRapHandle    = INVALID_HANDLE;
int    emaLentHandle   = INVALID_HANDLE;
int    rsiHandle       = INVALID_HANDLE;
int    atrHandle       = INVALID_HANDLE;
double atrValueCurrent = 0;
ulong  lastBarTime     = 0;
int    operacionesHoy  = 0;
double perdidaHoy      = 0;
int    diaActual       = -1;
datetime ultimaOperacion = 0;

//+------------------------------------------------------------------+
//| SISTEMA DE TRIAL Y LICENCIA                                       |
//+------------------------------------------------------------------+
bool CheckTrialAndLicense() {
   long cuenta = AccountInfoInteger(ACCOUNT_LOGIN);
   if(cuenta == CuentaDemo || cuenta == CuentaReal) return true;
   if(AccountInfoInteger(ACCOUNT_TRADE_MODE) != ACCOUNT_TRADE_MODE_DEMO) {
      Alert("❌ LICENCIA REQUERIDA PARA CUENTA REAL. Compra en kopytrade.com");
      return false;
   }
   string gVarName = "KOPYTRADE_BSR3_TRIAL_START";
   datetime firstRun;
   if(!GlobalVariableCheck(gVarName)) {
      GlobalVariableSet(gVarName, (double)TimeCurrent());
      firstRun = TimeCurrent();
      Print("🆓 KOPYTRADE BTC STORM RIDER v3.1 — TRIAL INICIADO (30 DÍAS)");
      Print("📧 Compra tu licencia completa en kopytrade.com");
   } else {
      firstRun = (datetime)GlobalVariableGet(gVarName);
   }
   int dias = (int)((TimeCurrent() - firstRun) / 86400);
   if(dias <= 30) {
      Comment("⚡ BTC STORM RIDER v3.1 TRIAL | Día " + IntegerToString(dias+1) + "/30 | kopytrade.com");
      return true;
   }
   Alert("⏰ TRIAL EXPIRADO (" + IntegerToString(dias) + " días). Compra en kopytrade.com");
   return false;
}

//+------------------------------------------------------------------+
//| OnInit                                                             |
//+------------------------------------------------------------------+
int OnInit() {
   if(!CheckTrialAndLicense()) return(INIT_FAILED);
   
   emaTendHandle  = iMA(_Symbol, _Period, EMA_Tendencia, 0, MODE_EMA, PRICE_CLOSE);
   emaRapHandle   = iMA(_Symbol, _Period, EMA_Rapida,    0, MODE_EMA, PRICE_CLOSE);
   emaLentHandle  = iMA(_Symbol, _Period, EMA_Lenta,     0, MODE_EMA, PRICE_CLOSE);
   rsiHandle      = iRSI(_Symbol, _Period, RSI_Periodo,  PRICE_CLOSE);
   atrHandle      = iATR(_Symbol, _Period, ATR_Periodo);
   
   if(emaTendHandle == INVALID_HANDLE || emaRapHandle == INVALID_HANDLE || 
      emaLentHandle == INVALID_HANDLE || rsiHandle == INVALID_HANDLE || 
      atrHandle == INVALID_HANDLE) {
      Alert("❌ Error al inicializar indicadores.");
      return(INIT_FAILED);
   }
   
   licenseValid = true;
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetTypeFillingBySymbol(_Symbol);
   
   Print("✅ BTC Storm Rider v3.1 ACTIVADO en ", _Symbol);
   Print("   EMA: ", EMA_Tendencia, "/", EMA_Rapida, "/", EMA_Lenta,
         " | RSI: ", RSI_Periodo, " | ATR: ", ATR_Periodo);
   Print("   SL: ", ATR_Multiplicador_SL, "x ATR | TP: ", ATR_Multiplicador_TP, "x ATR");
   Print("   Operación 24h | Max Ops: ", MaxOperacionesDia, " | Cooldown: ", CooldownMinutos, "min");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| OnDeinit                                                           |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   if(emaTendHandle != INVALID_HANDLE)  IndicatorRelease(emaTendHandle);
   if(emaRapHandle != INVALID_HANDLE)   IndicatorRelease(emaRapHandle);
   if(emaLentHandle != INVALID_HANDLE)  IndicatorRelease(emaLentHandle);
   if(rsiHandle != INVALID_HANDLE)      IndicatorRelease(rsiHandle);
   if(atrHandle != INVALID_HANDLE)      IndicatorRelease(atrHandle);
   Comment("");
}

//+------------------------------------------------------------------+
//| OnTick                                                             |
//+------------------------------------------------------------------+
void OnTick() {
   if(!licenseValid) return;
   
   // Reset contadores diarios
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(dt.day_of_year != diaActual) {
      diaActual = dt.day_of_year;
      operacionesHoy = 0;
      perdidaHoy = 0;
      ContarOperacionesYPerdidasHoy();
   }
   
   // Actualizar ATR
   double atr[1];
   if(CopyBuffer(atrHandle, 0, 0, 1, atr) > 0)
      atrValueCurrent = atr[0];
   
   // Gestionar posiciones abiertas (BE + Trailing)
   GestionarPosiciones();
   
   // Comprobar protección anti-racha
   if(perdidaHoy >= MaxPerdidaDiaria_USD) {
      if(MostrarPanel) DibujarPanel();
      return;
   }
   if(operacionesHoy >= MaxOperacionesDia) {
      if(MostrarPanel) DibujarPanel();
      return;
   }
   
   // Cooldown entre operaciones
   if(TimeCurrent() - ultimaOperacion < CooldownMinutos * 60) {
      if(MostrarPanel) DibujarPanel();
      return;
   }
   
   // Buscar entrada solo al inicio de vela nueva
   if(ContarPosiciones() < MaxPosiciones && EstaEnSesion()) {
      datetime barActual = iTime(_Symbol, _Period, 0);
      if(barActual != (datetime)lastBarTime) {
         lastBarTime = barActual;
         BuscarEntrada();
      }
   }
   
   if(MostrarPanel) DibujarPanel();
}

//+------------------------------------------------------------------+
//| BUSCAR ENTRADA — Alineación de Tendencia                          |
//+------------------------------------------------------------------+
void BuscarEntrada() {
   // Leer indicadores
   double emaTend[2], emaRap[2], emaLent[2], rsi[2], atr[2];
   ArraySetAsSeries(emaTend, true);
   ArraySetAsSeries(emaRap, true);
   ArraySetAsSeries(emaLent, true);
   ArraySetAsSeries(rsi, true);
   ArraySetAsSeries(atr, true);
   
   if(CopyBuffer(emaTendHandle, 0, 0, 2, emaTend) < 2) return;
   if(CopyBuffer(emaRapHandle,  0, 0, 2, emaRap)  < 2) return;
   if(CopyBuffer(emaLentHandle, 0, 0, 2, emaLent) < 2) return;
   if(CopyBuffer(rsiHandle,     0, 0, 2, rsi)     < 2) return;
   if(CopyBuffer(atrHandle,     0, 0, 2, atr)     < 2) return;
   
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double atrVal = atr[0];
   
   // Filtro volatilidad mínima
   if(atrVal < ATR_Minimo_USD * _Point) return;
   
   // SL y TP dinámicos
   double slDistance = atrVal * ATR_Multiplicador_SL;
   double tpDistance = atrVal * ATR_Multiplicador_TP;
   
   // Verificar que SL no supere riesgo máximo
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double slUSD = (slDistance / tickSize) * tickValue * LoteInicial;
   if(slUSD > MaxRiesgoPorTrade_USD) return;
   
   // Alineación de EMAs (no crossover exacto)
   bool emaAlcista = (emaRap[0] > emaLent[0]);
   bool emaBajista = (emaRap[0] < emaLent[0]);
   
   // ===== SEÑAL DE COMPRA =====
   // 1. Precio > EMA200 (tendencia alcista)
   // 2. EMA21 > EMA55 (momentum positivo)
   // 3. RSI en zona de compra
   // 4. ATR > mínimo
   if(bid > emaTend[0] && emaAlcista &&
      rsi[0] >= RSI_Compra_Min && rsi[0] <= RSI_Compra_Max) {
      
      double sl = NormalizeDouble(ask - slDistance, _Digits);
      double tp = NormalizeDouble(ask + tpDistance, _Digits);
      
      if(trade.Buy(LoteInicial, _Symbol, ask, sl, tp, "BSR31_BUY")) {
         operacionesHoy++;
         ultimaOperacion = TimeCurrent();
         Print("🟢 COMPRA | Precio: ", ask, " | SL: ", sl, " | TP: ", tp,
               " | ATR: ", DoubleToString(atrVal, 2));
      }
   }
   
   // ===== SEÑAL DE VENTA =====
   // 1. Precio < EMA200 (tendencia bajista)
   // 2. EMA21 < EMA55 (momentum negativo)
   // 3. RSI en zona de venta
   // 4. ATR > mínimo
   if(bid < emaTend[0] && emaBajista &&
      rsi[0] >= RSI_Venta_Min && rsi[0] <= RSI_Venta_Max) {
      
      double sl = NormalizeDouble(bid + slDistance, _Digits);
      double tp = NormalizeDouble(bid - tpDistance, _Digits);
      
      if(trade.Sell(LoteInicial, _Symbol, bid, sl, tp, "BSR31_SELL")) {
         operacionesHoy++;
         ultimaOperacion = TimeCurrent();
         Print("🔴 VENTA | Precio: ", bid, " | SL: ", sl, " | TP: ", tp,
               " | ATR: ", DoubleToString(atrVal, 2));
      }
   }
}

//+------------------------------------------------------------------+
//| GESTIONAR POSICIONES — BE + Trailing USD                           |
//+------------------------------------------------------------------+
void GestionarPosiciones() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      
      double profit  = PositionGetDouble(POSITION_PROFIT);
      double pOpen   = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl      = PositionGetDouble(POSITION_SL);
      double tp      = PositionGetDouble(POSITION_TP);
      long   tipo    = PositionGetInteger(POSITION_TYPE);
      double bid     = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask     = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      // ===== BREAK EVEN (USD) =====
      if(ActivarBE) {
         double garantia = BE_Garantia_USD * _Point * 10;
         
         if(tipo == POSITION_TYPE_BUY) {
            if(profit >= BE_Activar_USD) {
               double newSL = pOpen + garantia;
               newSL = NormalizeDouble(newSL, _Digits);
               if(sl < newSL) {
                  trade.PositionModify(ticket, newSL, tp);
                  Print("🔒 BE [BUY] Ticket: ", ticket, " | Profit: $", profit, " | SL → ", newSL);
               }
            }
         }
         else if(tipo == POSITION_TYPE_SELL) {
            if(profit >= BE_Activar_USD) {
               double newSL = pOpen - garantia;
               newSL = NormalizeDouble(newSL, _Digits);
               if(sl == 0 || sl > newSL) {
                  trade.PositionModify(ticket, newSL, tp);
                  Print("🔒 BE [SELL] Ticket: ", ticket, " | Profit: $", profit, " | SL → ", newSL);
               }
            }
         }
      }
      
      // ===== TRAILING STOP (USD) =====
      if(ActivarTrailing) {
         double trailDist = Trailing_Distancia_USD * _Point * 10;
         double salto = Trailing_Salto_Puntos * _Point;
         
         if(tipo == POSITION_TYPE_BUY) {
            if(profit >= Trailing_Activar_USD) {
               double newSL = NormalizeDouble(bid - trailDist, _Digits);
               if(newSL > sl + salto && newSL > pOpen) {
                  trade.PositionModify(ticket, newSL, tp);
                  Print("📈 TRAILING [BUY] Ticket: ", ticket, " | SL → ", newSL);
               }
            }
         }
         else if(tipo == POSITION_TYPE_SELL) {
            if(profit >= Trailing_Activar_USD) {
               double newSL = NormalizeDouble(ask + trailDist, _Digits);
               if(sl == 0 || (newSL < sl - salto && newSL < pOpen)) {
                  trade.PositionModify(ticket, newSL, tp);
                  Print("📈 TRAILING [SELL] Ticket: ", ticket, " | SL → ", newSL);
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| CONTAR OPERACIONES Y PÉRDIDAS DEL DÍA                             |
//+------------------------------------------------------------------+
void ContarOperacionesYPerdidasHoy() {
   operacionesHoy = 0;
   perdidaHoy = 0;
   datetime inicioHoy = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   
   HistorySelect(inicioHoy, TimeCurrent());
   for(int i = 0; i < HistoryDealsTotal(); i++) {
      ulong ticket = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) == MagicNumber &&
         HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol) {
         int entry = (int)HistoryDealGetInteger(ticket, DEAL_ENTRY);
         if(entry == DEAL_ENTRY_OUT) {
            operacionesHoy++;
            double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            if(profit < 0) perdidaHoy += MathAbs(profit);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| FILTRO DE SESIÓN — 24h para BTC                                    |
//+------------------------------------------------------------------+
bool EstaEnSesion() {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int hora = dt.hour;
   
   if(hora >= SesionEuropa_Inicio && hora < SesionEuropa_Fin) return true;
   if(hora >= SesionUS_Inicio && hora < SesionUS_Fin) return true;
   if(OperarEnAsia && (hora >= 0 && hora < 8)) return true;
   
   return false;
}

//+------------------------------------------------------------------+
//| CONTAR POSICIONES                                                  |
//+------------------------------------------------------------------+
int ContarPosiciones() {
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) && 
         PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
         PositionGetString(POSITION_SYMBOL) == _Symbol) {
         count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| PANEL VISUAL                                                       |
//+------------------------------------------------------------------+
void DibujarPanel() {
   double emaTend[1], emaRap[1], emaLent[1], rsi[1], atr[1];
   CopyBuffer(emaTendHandle, 0, 0, 1, emaTend);
   CopyBuffer(emaRapHandle,  0, 0, 1, emaRap);
   CopyBuffer(emaLentHandle, 0, 0, 1, emaLent);
   CopyBuffer(rsiHandle,     0, 0, 1, rsi);
   CopyBuffer(atrHandle,     0, 0, 1, atr);
   
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   string tendencia = (bid > emaTend[0]) ? "🟢 ALCISTA" : "🔴 BAJISTA";
   string momentum  = (emaRap[0] > emaLent[0]) ? "🟢 POSITIVO" : "🔴 NEGATIVO";
   string rsiStatus;
   if(rsi[0] > 70) rsiStatus = "⚠️ SOBRECOMPRADO";
   else if(rsi[0] < 30) rsiStatus = "⚠️ SOBREVENDIDO";
   else rsiStatus = "✅ " + DoubleToString(rsi[0], 1);
   
   string sesion = EstaEnSesion() ? "🟢 EN SESIÓN" : "🔴 FUERA";
   bool antiRacha = (perdidaHoy >= MaxPerdidaDiaria_USD || operacionesHoy >= MaxOperacionesDia);
   string proteccion = antiRacha ? "🚨 PROTECCIÓN ACTIVA" : "✅ OPERATIVO";
   
   // Cooldown restante
   int cooldownRestante = (int)((CooldownMinutos * 60 - (TimeCurrent() - ultimaOperacion)) / 60);
   string cooldownStr = (cooldownRestante > 0 && cooldownRestante < CooldownMinutos) ? 
      "⏳ " + IntegerToString(cooldownRestante) + " min" : "✅ LISTO";
   
   string panel = "";
   panel += "╔══════════════════════════════════╗\n";
   panel += "║  ⚡ BTC STORM RIDER v3.1          ║\n";
   panel += "║       KOPYTRADE.COM               ║\n";
   panel += "╠══════════════════════════════════╣\n";
   panel += "║ Tendencia: " + tendencia + "\n";
   panel += "║ Momentum: " + momentum + "\n";
   panel += "║ RSI(" + IntegerToString(RSI_Periodo) + "): " + rsiStatus + "\n";
   panel += "║ ATR: " + DoubleToString(atr[0], 2) + "\n";
   panel += "║ Sesión: " + sesion + "\n";
   panel += "╠══════════════════════════════════╣\n";
   panel += "║ Ops Hoy: " + IntegerToString(operacionesHoy) + "/" + IntegerToString(MaxOperacionesDia) + "\n";
   panel += "║ Pérdida Hoy: $" + DoubleToString(perdidaHoy, 2) + "/$" + DoubleToString(MaxPerdidaDiaria_USD, 2) + "\n";
   panel += "║ Estado: " + proteccion + "\n";
   panel += "║ Cooldown: " + cooldownStr + "\n";
   panel += "║ Posiciones: " + IntegerToString(ContarPosiciones()) + "/" + IntegerToString(MaxPosiciones) + "\n";
   panel += "║ BE: $" + DoubleToString(BE_Activar_USD, 1) + " | Trail: $" + DoubleToString(Trailing_Activar_USD, 1) + "\n";
   panel += "╚══════════════════════════════════╝\n";
   
   Comment(panel);
}
//+------------------------------------------------------------------+

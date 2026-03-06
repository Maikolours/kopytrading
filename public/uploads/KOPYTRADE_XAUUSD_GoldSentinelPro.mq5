//+------------------------------------------------------------------+
//|          KOPYTRADE_XAUUSD_GoldSentinelPro v1.1                  |
//|   TREND ALIGNMENT + MULTI-CONFIRMATION · ATR DYNAMIC RISK        |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Bot Oficial"
#property version   "1.10"
#property strict
#property description "GoldSentinel Pro | Inteligencia Adaptativa para el Oro"
#property description "Estrategia Multi-Confirmación con Gestión ATR Dinámica"

#include <Trade\Trade.mqh>

//=== LICENCIA KOPYTRADE ===
input group "=== 🔑 LICENCIA KOPYTRADE ==="
input long     CuentaDemo         = 0;       // Nº cuenta DEMO de MT5 (Trial y Compra)
input long     CuentaReal         = 0;       // Nº cuenta REAL de MT5 (Solo Compra)

//=== RELOJ DE SESIONES ===
input group "=== ⏰ SESIONES DE MERCADO (HORA BROKER) ==="
input int      SesionLondres_Inicio = 8;     // Inicio Sesión Londres
input int      SesionLondres_Fin    = 11;    // Fin Sesión Londres
input int      SesionNY_Inicio      = 14;    // Inicio Sesión Nueva York
input int      SesionNY_Fin         = 17;    // Fin Sesión Nueva York

//=== GESTIÓN DE RIESGO ===
input group "=== 🛡️ GESTIÓN DE RIESGO ==="
input double   LoteInicial           = 0.01;  // Tamaño de posición
input double   MaxRiesgoPorTrade_USD = 30.0;  // Máxima pérdida en $ por trade
input double   ATR_Multiplicador_SL  = 1.5;   // Multiplicador ATR para Stop Loss
input double   ATR_Multiplicador_TP  = 3.0;   // Multiplicador ATR para Take Profit

//=== ESTRATEGIA (INDICADORES) ===
input group "=== 📊 ESTRATEGIA MULTI-CONFIRMACIÓN ==="
input int      EMA_Tendencia     = 200;       // EMA de tendencia de fondo
input int      EMA_Rapida        = 21;        // EMA rápida (señal de cruce)
input int      EMA_Lenta         = 55;        // EMA lenta (confirmación de cruce)
input int      RSI_Periodo       = 14;        // Período del RSI
input int      RSI_Compra_Min    = 40;        // RSI mínimo para comprar
input int      RSI_Compra_Max    = 65;        // RSI máximo para comprar
input int      RSI_Venta_Min     = 35;        // RSI mínimo para vender
input int      RSI_Venta_Max     = 60;        // RSI máximo para vender
input int      ATR_Periodo       = 14;        // Período del ATR
input double   ATR_Minimo_USD    = 2.0;       // Volatilidad mínima para operar (USD)

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
input int      Trailing_Salto_Puntos       = 20;    // Puntos mínimos para mover trailing

//=== CONFIGURACIÓN AVANZADA ===
input group "=== ⚙️ CONFIGURACIÓN AVANZADA ==="
input int      MaxPosiciones     = 1;         // Máx posiciones simultáneas
input bool     MostrarPanel      = true;      // Mostrar panel visual en el gráfico
input long     MagicNumber       = 779933;    // ID único del bot

//--- Variables globales internas ---
CTrade trade;
bool   licenseValid   = false;
int    emaTendHandle  = INVALID_HANDLE;
int    emaRapHandle   = INVALID_HANDLE;
int    emaLentHandle  = INVALID_HANDLE;
int    rsiHandle      = INVALID_HANDLE;
int    atrHandle      = INVALID_HANDLE;
double atrValueCurrent = 0;
ulong  lastBarTime     = 0;

//+------------------------------------------------------------------+
//| SISTEMA DE TRIAL Y LICENCIA                                       |
//+------------------------------------------------------------------+
bool CheckTrialAndLicense() {
   long cuenta = AccountInfoInteger(ACCOUNT_LOGIN);
   
   // 1. ¿Es una cuenta autorizada? → Funciona siempre
   if(cuenta == CuentaDemo || cuenta == CuentaReal) return true;
   
   // 2. ¿Es cuenta REAL sin licencia? → Bloqueado
   if(AccountInfoInteger(ACCOUNT_TRADE_MODE) != ACCOUNT_TRADE_MODE_DEMO) {
      Alert("❌ LICENCIA REQUERIDA PARA CUENTA REAL. Compra en kopytrade.com");
      return false;
   }
   
   // 3. Es cuenta DEMO sin licencia → Comprobar trial de 30 días
   string gVarName = "KOPYTRADE_GSP_TRIAL_START";
   datetime firstRun;
   
   if(!GlobalVariableCheck(gVarName)) {
      GlobalVariableSet(gVarName, (double)TimeCurrent());
      firstRun = TimeCurrent();
      Print("🆓 KOPYTRADE GOLDSENTINEL PRO — TRIAL INICIADO (30 DÍAS)");
      Print("📧 Compra tu licencia completa en kopytrade.com");
   } else {
      firstRun = (datetime)GlobalVariableGet(gVarName);
   }
   
   int dias = (int)((TimeCurrent() - firstRun) / 86400);
   if(dias <= 30) {
      Comment("🛡️ GOLDSENTINEL PRO TRIAL | Día " + IntegerToString(dias+1) + "/30 | kopytrade.com");
      return true;
   }
   
   Alert("⏰ TRIAL EXPIRADO (" + IntegerToString(dias) + " días). Compra en kopytrade.com");
   return false;
}

//+------------------------------------------------------------------+
//| OnInit — Inicialización                                           |
//+------------------------------------------------------------------+
int OnInit() {
   if(!CheckTrialAndLicense()) return(INIT_FAILED);
   
   // Inicializar indicadores
   emaTendHandle  = iMA(_Symbol, _Period, EMA_Tendencia, 0, MODE_EMA, PRICE_CLOSE);
   emaRapHandle   = iMA(_Symbol, _Period, EMA_Rapida,    0, MODE_EMA, PRICE_CLOSE);
   emaLentHandle  = iMA(_Symbol, _Period, EMA_Lenta,     0, MODE_EMA, PRICE_CLOSE);
   rsiHandle      = iRSI(_Symbol, _Period, RSI_Periodo,  PRICE_CLOSE);
   atrHandle      = iATR(_Symbol, _Period, ATR_Periodo);
   
   if(emaTendHandle == INVALID_HANDLE || emaRapHandle == INVALID_HANDLE || 
      emaLentHandle == INVALID_HANDLE || rsiHandle == INVALID_HANDLE || 
      atrHandle == INVALID_HANDLE) {
      Alert("❌ Error al inicializar indicadores. Revisa la configuración.");
      return(INIT_FAILED);
   }
   
   licenseValid = true;
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetTypeFillingBySymbol(_Symbol);
   
   Print("✅ GoldSentinel Pro v1.1 ACTIVADO en ", _Symbol);
   Print("   EMA Tendencia: ", EMA_Tendencia, " | EMA Rápida: ", EMA_Rapida, " | EMA Lenta: ", EMA_Lenta);
   Print("   RSI: ", RSI_Periodo, " | ATR: ", ATR_Periodo);
   Print("   SL Multiplicador: ", ATR_Multiplicador_SL, "x ATR | TP Multiplicador: ", ATR_Multiplicador_TP, "x ATR");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| OnDeinit — Limpieza                                               |
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
//| OnTick — Ciclo principal                                          |
//+------------------------------------------------------------------+
void OnTick() {
   if(!licenseValid) return;
   
   // Actualizar ATR actual
   double atr[1];
   if(CopyBuffer(atrHandle, 0, 0, 1, atr) > 0)
      atrValueCurrent = atr[0];
   
   // Gestionar posiciones abiertas
   GestionarPosiciones();
   
   // Buscar nueva entrada solo al inicio de cada vela nueva
   if(ContarPosiciones() < MaxPosiciones && EstaEnSesion()) {
      datetime barActual = iTime(_Symbol, _Period, 0);
      if(barActual != (datetime)lastBarTime) {
         lastBarTime = barActual;
         BuscarEntrada();
      }
   }
   
   // Panel visual
   if(MostrarPanel) DibujarPanel();
}

//+------------------------------------------------------------------+
//| BUSCAR ENTRADA — Multi-Confirmación                               |
//+------------------------------------------------------------------+
void BuscarEntrada() {
   // Leer todos los indicadores
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
   
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double atrVal = atr[0];
   
   // Filtro de volatilidad mínima (convertir ATR a USD aprox)
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double atrUSD = (atrVal / tickSize) * tickValue * LoteInicial;
   if(atrUSD < ATR_Minimo_USD) return;
   
   // Calcular SL y TP dinámicos basados en ATR
   double slDistance = atrVal * ATR_Multiplicador_SL;
   double tpDistance = atrVal * ATR_Multiplicador_TP;
   
   // Verificar que el SL no supere el riesgo máximo en USD
   double slUSD = (slDistance / tickSize) * tickValue * LoteInicial;
   if(slUSD > MaxRiesgoPorTrade_USD) return;
   
   // Comprobar alineación de EMAs (no cruce exacto)
   bool emaAlcista = (emaRap[0] > emaLent[0]);
   bool emaBajista = (emaRap[0] < emaLent[0]);
   
   // ===== SEÑAL DE COMPRA =====
   // 1. Precio > EMA200 (tendencia alcista)
   // 2. EMA21 > EMA55 (momentum positivo)
   // 3. RSI entre 35-72 (no sobrecomprado)
   // 4. ATR > mínimo (hay volatilidad)
   if(bid > emaTend[0] && emaAlcista && 
      rsi[0] >= RSI_Compra_Min && rsi[0] <= RSI_Compra_Max) {
      
      double sl = ask - slDistance;
      double tp = ask + tpDistance;
      
      // Normalizar precios
      sl = NormalizeDouble(sl, _Digits);
      tp = NormalizeDouble(tp, _Digits);
      
      if(trade.Buy(LoteInicial, _Symbol, ask, sl, tp, "GSP_BUY")) {
         Print("🟢 COMPRA | Precio: ", ask, " | SL: ", sl, " | TP: ", tp, 
               " | ATR: ", DoubleToString(atrVal, 2));
      }
   }
   
   // ===== SEÑAL DE VENTA =====
   // 1. Precio < EMA200 (tendencia bajista)
   // 2. EMA21 < EMA55 (momentum negativo)
   // 3. RSI entre 28-65 (no sobrevendido)
   // 4. ATR > mínimo (hay volatilidad)
   if(bid < emaTend[0] && emaBajista && 
      rsi[0] >= RSI_Venta_Min && rsi[0] <= RSI_Venta_Max) {
      
      double sl = bid + slDistance;
      double tp = bid - tpDistance;
      
      sl = NormalizeDouble(sl, _Digits);
      tp = NormalizeDouble(tp, _Digits);
      
      if(trade.Sell(LoteInicial, _Symbol, bid, sl, tp, "GSP_SELL")) {
         Print("🔴 VENTA | Precio: ", bid, " | SL: ", sl, " | TP: ", tp, 
               " | ATR: ", DoubleToString(atrVal, 2));
      }
   }
}

//+------------------------------------------------------------------+
//| GESTIONAR POSICIONES — BE + Trailing ATR                          |
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
      
      if(atrValueCurrent <= 0) continue;
      
      // ===== BREAK EVEN =====
      if(ActivarBE) {
         double garantia = BE_Garantia_USD * _Point * 10;
         
         if(tipo == POSITION_TYPE_BUY) {
            if(profit >= BE_Activar_USD) {
               double newSL = pOpen + garantia;
               newSL = NormalizeDouble(newSL, _Digits);
               if(sl < newSL) {
                  trade.PositionModify(ticket, newSL, tp);
                  Print("🔒 BE ACTIVADO [BUY] Ticket: ", ticket, " | Profit: $", profit, " | Nuevo SL: ", newSL);
               }
            }
         }
         else if(tipo == POSITION_TYPE_SELL) {
            if(profit >= BE_Activar_USD) {
               double newSL = pOpen - garantia;
               newSL = NormalizeDouble(newSL, _Digits);
               if(sl == 0 || sl > newSL) {
                  trade.PositionModify(ticket, newSL, tp);
                  Print("🔒 BE ACTIVADO [SELL] Ticket: ", ticket, " | Profit: $", profit, " | Nuevo SL: ", newSL);
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
//| FILTRO DE SESIÓN — Londres + Nueva York                           |
//+------------------------------------------------------------------+
bool EstaEnSesion() {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int hora = dt.hour;
   
   // Sesión Londres
   if(hora >= SesionLondres_Inicio && hora < SesionLondres_Fin) return true;
   // Sesión Nueva York
   if(hora >= SesionNY_Inicio && hora < SesionNY_Fin) return true;
   
   return false;
}

//+------------------------------------------------------------------+
//| CONTAR POSICIONES del bot                                          |
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
//| PANEL VISUAL — Información en el gráfico                          |
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
   else rsiStatus = "✅ NEUTRAL (" + DoubleToString(rsi[0], 1) + ")";
   
   string sesion = EstaEnSesion() ? "🟢 EN SESIÓN" : "🔴 FUERA DE SESIÓN";
   int posAbiertas = ContarPosiciones();
   
   string panel = "";
   panel += "╔══════════════════════════════════╗\n";
   panel += "║   🛡️ GOLDSENTINEL PRO v1.1       ║\n";
   panel += "║        KOPYTRADE.COM              ║\n";
   panel += "╠══════════════════════════════════╣\n";
   panel += "║ Tendencia EMA" + IntegerToString(EMA_Tendencia) + ": " + tendencia + "      \n";
   panel += "║ Momentum EMA" + IntegerToString(EMA_Rapida) + "/" + IntegerToString(EMA_Lenta) + ": " + momentum + "  \n";
   panel += "║ RSI(" + IntegerToString(RSI_Periodo) + "): " + rsiStatus + "         \n";
   panel += "║ ATR(" + IntegerToString(ATR_Periodo) + "): " + DoubleToString(atr[0], 2) + "                \n";
   panel += "║ Sesión: " + sesion + "           \n";
   panel += "╠══════════════════════════════════╣\n";
   panel += "║ Posiciones: " + IntegerToString(posAbiertas) + "/" + IntegerToString(MaxPosiciones) + "                  \n";
   panel += "║ Lote: " + DoubleToString(LoteInicial, 2) + "                       \n";
   panel += "║ SL: " + DoubleToString(ATR_Multiplicador_SL, 1) + "x ATR | TP: " + DoubleToString(ATR_Multiplicador_TP, 1) + "x ATR       \n";
   panel += "╚══════════════════════════════════╝\n";
   
   Comment(panel);
}
//+------------------------------------------------------------------+

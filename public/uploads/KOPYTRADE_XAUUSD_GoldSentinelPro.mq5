//+------------------------------------------------------------------+
//|          KOPYTRADE_XAUUSD_GoldSentinelPro v1.2                  |
//|   TREND ALIGNMENT + MULTI-CONFIRMATION · TODO EN DÓLARES         |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Bot Oficial"
#property version   "1.20"
#property strict
#property description "GoldSentinel Pro v1.2 | Todos los parámetros en DÓLARES"
#property description "Estrategia Multi-Confirmación · BE y Trailing en USD"

#include <Trade\Trade.mqh>

//=== LICENCIA KOPYTRADE ===
input group "=== 🔑 LICENCIA KOPYTRADE ==="
input long     CuentaDemo         = 0;       // Nº cuenta DEMO de MT5 (Trial y Compra)
input long     CuentaReal         = 0;       // Nº cuenta REAL de MT5 (Solo Compra)

//=== SESIONES DE MERCADO ===
input group "=== ⏰ HORARIO DE OPERACIÓN (HORA BROKER) ==="
input int      SesionLondres_Inicio = 8;     // Hora inicio Londres
input int      SesionLondres_Fin    = 13;    // Hora fin Londres
input int      SesionNY_Inicio      = 14;    // Hora inicio Nueva York
input int      SesionNY_Fin         = 17;    // Hora fin Nueva York

//=== GESTIÓN DE RIESGO ===
input group "=== 🛡️ RIESGO POR OPERACIÓN (en dólares) ==="
input double   LoteInicial           = 0.01;  // Tamaño del lote (0.01 = mínimo)
input double   MaxPerdidaPorTrade    = 30.0;  // Máximo que puedes perder por operación ($)
input double   SL_Multiplicador      = 1.5;   // Stop Loss = X veces la volatilidad media
input double   TP_Multiplicador      = 3.0;   // Take Profit = X veces la volatilidad media

//=== ESTRATEGIA ===
input group "=== 📊 ESTRATEGIA (para usuarios avanzados) ==="
input int      EMA_Tendencia     = 200;       // Media larga (tendencia general)
input int      EMA_Rapida        = 21;        // Media rápida (impulso)
input int      EMA_Lenta         = 55;        // Media lenta (confirmación)
input int      RSI_Periodo       = 14;        // Período del indicador RSI
input int      RSI_Compra_Min    = 40;        // RSI mínimo para comprar
input int      RSI_Compra_Max    = 65;        // RSI máximo para comprar
input int      RSI_Venta_Min     = 35;        // RSI mínimo para vender
input int      RSI_Venta_Max     = 60;        // RSI máximo para vender
input int      ATR_Periodo       = 14;        // Período volatilidad (ATR)
input double   VolatilidadMinima = 2.0;       // Volatilidad mínima en $ para operar

//=== BREAK EVEN ===
input group "=== 🔒 BREAK EVEN (protección de ganancias en $) ==="
input bool     ActivarBE              = true;  // ¿Activar protección Break Even?
input double   BE_Activar_USD         = 3.0;   // Cuando ganes X$, proteger la operación
input double   BE_Garantia_USD        = 1.0;   // Ganancia mínima asegurada ($)

//=== TRAILING STOP ===
input group "=== 📈 TRAILING STOP (persigue el beneficio en $) ==="
input bool     ActivarTrailing             = true;  // ¿Activar Trailing Stop?
input double   Trailing_Activar_USD        = 3.0;   // Activar cuando ganes X$
input double   Trailing_Distancia_USD      = 2.0;   // Distancia de seguimiento ($)

//=== CONFIGURACIÓN AVANZADA ===
input group "=== ⚙️ CONFIGURACIÓN AVANZADA ==="
input int      MaxPosiciones     = 1;         // Operaciones abiertas a la vez (máximo)
input bool     MostrarPanel      = true;      // Mostrar panel informativo en gráfico
input long     MagicNumber       = 779933;    // ID único del bot (no cambiar)

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
//| Convertir dólares a distancia de precio                           |
//| Ejemplo: $3 con 0.01 lotes = cuántos puntos mover el SL          |
//+------------------------------------------------------------------+
double USDaPrecio(double dolares) {
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickValue <= 0 || LoteInicial <= 0) return 0;
   return (dolares * tickSize) / (tickValue * LoteInicial);
}

//+------------------------------------------------------------------+
//| Convertir distancia de precio a dólares                           |
//+------------------------------------------------------------------+
double PrecioAUSD(double distancia) {
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize <= 0) return 0;
   return (distancia / tickSize) * tickValue * LoteInicial;
}

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
   string gVarName = "KOPYTRADE_GSP_TRIAL_START";
   datetime firstRun;
   if(!GlobalVariableCheck(gVarName)) {
      GlobalVariableSet(gVarName, (double)TimeCurrent());
      firstRun = TimeCurrent();
      Print("🆓 KOPYTRADE GOLDSENTINEL PRO v1.2 — TRIAL INICIADO (30 DÍAS)");
      Print("📧 Compra tu licencia completa en kopytrade.com");
   } else {
      firstRun = (datetime)GlobalVariableGet(gVarName);
   }
   int dias = (int)((TimeCurrent() - firstRun) / 86400);
   if(dias <= 30) {
      Comment("🛡️ GOLDSENTINEL PRO v1.2 TRIAL | Día " + IntegerToString(dias+1) + "/30 | kopytrade.com");
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
   
   Print("✅ GoldSentinel Pro v1.2 ACTIVADO en ", _Symbol);
   Print("   💰 TODO EN DÓLARES:");
   Print("   BE: activar a $", BE_Activar_USD, " | garantía $", BE_Garantia_USD);
   Print("   Trailing: activar a $", Trailing_Activar_USD, " | distancia $", Trailing_Distancia_USD);
   Print("   Máx pérdida/trade: $", MaxPerdidaPorTrade);
   Print("   $3 = ", DoubleToString(USDaPrecio(3.0), 2), " puntos en ", _Symbol);
   
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
   
   // Actualizar ATR
   double atr[1];
   if(CopyBuffer(atrHandle, 0, 0, 1, atr) > 0)
      atrValueCurrent = atr[0];
   
   // Gestionar posiciones abiertas (BE + Trailing)
   GestionarPosiciones();
   
   // Buscar nueva entrada al inicio de cada vela nueva
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
//| BUSCAR ENTRADA — Multi-Confirmación                               |
//+------------------------------------------------------------------+
void BuscarEntrada() {
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
   
   // Filtro volatilidad (convertido a $)
   double atrUSD = PrecioAUSD(atrVal);
   if(atrUSD < VolatilidadMinima) return;
   
   // SL y TP dinámicos
   double slDistance = atrVal * SL_Multiplicador;
   double tpDistance = atrVal * TP_Multiplicador;
   
   // Verificar riesgo máximo ($)
   double slUSD = PrecioAUSD(slDistance);
   if(slUSD > MaxPerdidaPorTrade) return;
   
   // Alineación de EMAs
   bool emaAlcista = (emaRap[0] > emaLent[0]);
   bool emaBajista = (emaRap[0] < emaLent[0]);
   
   // ===== COMPRA =====
   if(bid > emaTend[0] && emaAlcista && 
      rsi[0] >= RSI_Compra_Min && rsi[0] <= RSI_Compra_Max) {
      
      double sl = NormalizeDouble(ask - slDistance, _Digits);
      double tp = NormalizeDouble(ask + tpDistance, _Digits);
      
      if(trade.Buy(LoteInicial, _Symbol, ask, sl, tp, "GSP12_BUY")) {
         Print("🟢 COMPRA | Precio: ", ask,
               " | SL: ", sl, " ($", DoubleToString(slUSD, 2), ")",
               " | TP: ", tp, " ($", DoubleToString(PrecioAUSD(tpDistance), 2), ")");
      }
   }
   
   // ===== VENTA =====
   if(bid < emaTend[0] && emaBajista && 
      rsi[0] >= RSI_Venta_Min && rsi[0] <= RSI_Venta_Max) {
      
      double sl = NormalizeDouble(bid + slDistance, _Digits);
      double tp = NormalizeDouble(bid - tpDistance, _Digits);
      
      if(trade.Sell(LoteInicial, _Symbol, bid, sl, tp, "GSP12_SELL")) {
         Print("🔴 VENTA | Precio: ", bid,
               " | SL: ", sl, " ($", DoubleToString(slUSD, 2), ")",
               " | TP: ", tp, " ($", DoubleToString(PrecioAUSD(tpDistance), 2), ")");
      }
   }
}

//+------------------------------------------------------------------+
//| GESTIONAR POSICIONES — BE + Trailing TODO EN USD                   |
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
      
      // Convertir $ a distancia de precio CORRECTAMENTE
      double garantiaPrecio = USDaPrecio(BE_Garantia_USD);
      double trailDistPrecio = USDaPrecio(Trailing_Distancia_USD);
      
      // ===== BREAK EVEN (basado en profit real en $) =====
      if(ActivarBE) {
         if(tipo == POSITION_TYPE_BUY) {
            if(profit >= BE_Activar_USD) {
               double newSL = NormalizeDouble(pOpen + garantiaPrecio, _Digits);
               if(sl < newSL) {
                  if(trade.PositionModify(ticket, newSL, tp))
                     Print("🔒 BE [BUY] | Profit: $", DoubleToString(profit, 2),
                           " | SL → ", newSL, " (garantía $", BE_Garantia_USD, ")");
               }
            }
         }
         else if(tipo == POSITION_TYPE_SELL) {
            if(profit >= BE_Activar_USD) {
               double newSL = NormalizeDouble(pOpen - garantiaPrecio, _Digits);
               if(sl == 0 || sl > newSL) {
                  if(trade.PositionModify(ticket, newSL, tp))
                     Print("🔒 BE [SELL] | Profit: $", DoubleToString(profit, 2),
                           " | SL → ", newSL, " (garantía $", BE_Garantia_USD, ")");
               }
            }
         }
      }
      
      // ===== TRAILING STOP (basado en profit real en $) =====
      if(ActivarTrailing) {
         if(tipo == POSITION_TYPE_BUY) {
            if(profit >= Trailing_Activar_USD) {
               double newSL = NormalizeDouble(bid - trailDistPrecio, _Digits);
               if(newSL > sl && newSL > pOpen) {
                  if(trade.PositionModify(ticket, newSL, tp))
                     Print("📈 TRAILING [BUY] | Profit: $", DoubleToString(profit, 2),
                           " | SL → ", newSL);
               }
            }
         }
         else if(tipo == POSITION_TYPE_SELL) {
            if(profit >= Trailing_Activar_USD) {
               double newSL = NormalizeDouble(ask + trailDistPrecio, _Digits);
               if(sl == 0 || (newSL < sl && newSL < pOpen)) {
                  if(trade.PositionModify(ticket, newSL, tp))
                     Print("📈 TRAILING [SELL] | Profit: $", DoubleToString(profit, 2),
                           " | SL → ", newSL);
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
   
   if(hora >= SesionLondres_Inicio && hora < SesionLondres_Fin) return true;
   if(hora >= SesionNY_Inicio && hora < SesionNY_Fin) return true;
   
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
//| PANEL VISUAL — TODO EN DÓLARES                                     |
//+------------------------------------------------------------------+
void DibujarPanel() {
   double emaTend[1], emaRap[1], emaLent[1], rsi[1], atr[1];
   CopyBuffer(emaTendHandle, 0, 0, 1, emaTend);
   CopyBuffer(emaRapHandle,  0, 0, 1, emaRap);
   CopyBuffer(emaLentHandle, 0, 0, 1, emaLent);
   CopyBuffer(rsiHandle,     0, 0, 1, rsi);
   CopyBuffer(atrHandle,     0, 0, 1, atr);
   
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double atrUSD = PrecioAUSD(atr[0]);
   
   string tendencia = (bid > emaTend[0]) ? "🟢 ALCISTA" : "🔴 BAJISTA";
   string momentum  = (emaRap[0] > emaLent[0]) ? "🟢 POSITIVO" : "🔴 NEGATIVO";
   string rsiStatus;
   if(rsi[0] > 70) rsiStatus = "⚠️ SOBRECOMPRADO";
   else if(rsi[0] < 30) rsiStatus = "⚠️ SOBREVENDIDO";
   else rsiStatus = "✅ " + DoubleToString(rsi[0], 1);
   
   string sesion = EstaEnSesion() ? "🟢 EN SESIÓN" : "🔴 FUERA";
   
   double slUSD = PrecioAUSD(atr[0] * SL_Multiplicador);
   double tpUSD = PrecioAUSD(atr[0] * TP_Multiplicador);
   
   string panel = "";
   panel += "╔══════════════════════════════════╗\n";
   panel += "║   🛡️ GOLDSENTINEL PRO v1.2       ║\n";
   panel += "║        KOPYTRADE.COM              ║\n";
   panel += "╠═══════ MERCADO ════════════════╣\n";
   panel += "║ Tendencia: " + tendencia + "\n";
   panel += "║ Momentum: " + momentum + "\n";
   panel += "║ RSI(" + IntegerToString(RSI_Periodo) + "): " + rsiStatus + "\n";
   panel += "║ Volatilidad: $" + DoubleToString(atrUSD, 2) + "\n";
   panel += "║ Sesión: " + sesion + "\n";
   panel += "╠═══════ RIESGO ($) ═══════════════╣\n";
   panel += "║ SL: ~$" + DoubleToString(slUSD, 2) + " | TP: ~$" + DoubleToString(tpUSD, 2) + "\n";
   panel += "║ BE: a $" + DoubleToString(BE_Activar_USD, 1) + " (garantía $" + DoubleToString(BE_Garantia_USD, 1) + ")\n";
   panel += "║ Trailing: a $" + DoubleToString(Trailing_Activar_USD, 1) + " (dist $" + DoubleToString(Trailing_Distancia_USD, 1) + ")\n";
   panel += "╠═══════ ESTADO ════════════════════╣\n";
   panel += "║ Posiciones: " + IntegerToString(ContarPosiciones()) + "/" + IntegerToString(MaxPosiciones) + "\n";
   panel += "║ Lote: " + DoubleToString(LoteInicial, 2) + "\n";
   panel += "╚══════════════════════════════════╝\n";
   
   Comment(panel);
}
//+------------------------------------------------------------------+

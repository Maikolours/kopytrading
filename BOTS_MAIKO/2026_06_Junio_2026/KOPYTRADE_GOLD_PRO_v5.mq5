//+------------------------------------------------------------------+
//|                    KOPYTRADE_GOLD_PRO v5.0                       |
//|         BUY + SELL · MA + RSI + ATR · M15 · Sin esperas          |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading"
#property link      "https://www.kopytrading.com"
#property version   "5.00"
#property strict

#include <Trade\Trade.mqh>
CTrade trade;

//=== PARÁMETROS ===

input group "⏰ 1. HORARIO DE TRABAJO"
input int    InpHoraInicio   = 9;    // [9]  Hora de inicio
input int    InpHoraFin      = 21;   // [21] Hora de fin
input int    InpMinutoFin    = 30;   // [30] Minuto de fin (21:30)

input group "🛡️ 2. SEGURIDAD"
input double InpMaxPerdidaDiaria = 30.0;  // [$30] Límite de pérdida diaria
input int    InpMaxOpsAbiertas   = 2;     // [2]   Máximo de posiciones simultáneas

input group "📈 3. ESTRATEGIA (M15)"
input int    InpMA_Rapida    = 30;   // [30] Media rápida
input int    InpMA_Lenta     = 50;   // [50] Media lenta
input int    InpRSI_Periodo  = 14;   // [14] Período RSI
input int    InpRSI_ComMin   = 45;   // [45] RSI mínimo para COMPRA
input int    InpRSI_ComMax   = 65;   // [65] RSI máximo para COMPRA
input int    InpRSI_VenMin   = 35;   // [35] RSI mínimo para VENTA
input int    InpRSI_VenMax   = 55;   // [55] RSI máximo para VENTA
input int    InpATR_Periodo  = 14;   // [14] Período ATR
input double InpATR_MinUSD   = 2.0;  // [$2] Volatilidad mínima para operar

input group "💰 4. GANANCIAS Y PÉRDIDAS (USD)"
input double InpLotaje          = 0.02;  // [0.02] Tamaño del lote
input double InpStopLossUSD     = 15.0;  // [$15]  Stop Loss máximo
input double InpTakeProfitUSD   = 5.0;   // [$5]   Take Profit objetivo
input double InpBreakEvenUSD    = 2.0;   // [$2]   Activar Break Even al ganar $2
input double InpTrailingStopUSD = 2.5;   // [$2.5] Distancia del Trailing Stop

input long   InpMagic = 889944;  // Magic Number del bot

//=== HANDLES DE INDICADORES ===
int hMA_R  = INVALID_HANDLE;
int hMA_L  = INVALID_HANDLE;
int hRSI   = INVALID_HANDLE;
int hATR   = INVALID_HANDLE;

datetime ultimaVela = 0;
double   gananciaDelDia = 0;
bool     bloqueadoHoy   = false;
datetime fechaBloqueo   = 0;

//+------------------------------------------------------------------+
//| OnInit                                                            |
//+------------------------------------------------------------------+
int OnInit() {
   // Crear handles en M15 (la lógica de entrada se analiza en M15)
   hMA_R = iMA(_Symbol, PERIOD_M15, InpMA_Rapida, 0, MODE_SMA, PRICE_CLOSE);
   hMA_L = iMA(_Symbol, PERIOD_M15, InpMA_Lenta,  0, MODE_SMA, PRICE_CLOSE);
   hRSI  = iRSI(_Symbol, PERIOD_M15, InpRSI_Periodo, PRICE_CLOSE);
   hATR  = iATR(_Symbol, PERIOD_M15, InpATR_Periodo);

   if(hMA_R == INVALID_HANDLE || hMA_L == INVALID_HANDLE ||
      hRSI  == INVALID_HANDLE || hATR  == INVALID_HANDLE) {
      Alert("❌ Error al crear indicadores. Revisa el símbolo y reinicia.");
      return INIT_FAILED;
   }

   trade.SetExpertMagicNumber(InpMagic);
   trade.SetTypeFillingBySymbol(_Symbol);

   Print("✅ KOPYTRADE GOLD PRO v5.0 ACTIVO | ", _Symbol, " | M15");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| OnDeinit                                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   if(hMA_R != INVALID_HANDLE) IndicatorRelease(hMA_R);
   if(hMA_L != INVALID_HANDLE) IndicatorRelease(hMA_L);
   if(hRSI  != INVALID_HANDLE) IndicatorRelease(hRSI);
   if(hATR  != INVALID_HANDLE) IndicatorRelease(hATR);
   Comment("");
}

//+------------------------------------------------------------------+
//| OnTick — ejecutado en cada tick                                   |
//+------------------------------------------------------------------+
void OnTick() {

   // ── 1. HORARIO ────────────────────────────────────────────────
   if(!EstaEnHorario()) {
      Comment("💤 FUERA DE HORARIO · KOPYTRADE GOLD PRO v5.0");
      return;
   }

   // ── 2. LÍMITE DIARIO (bloqueo hasta el día siguiente) ─────────
   CalcularGananciaDiaria();
   
   // Resetear bloqueo si es un día nuevo
   if(bloqueadoHoy) {
      MqlDateTime hoy, bloq;
      TimeToStruct(TimeCurrent(), hoy);
      TimeToStruct(fechaBloqueo, bloq);
      if(hoy.day != bloq.day || hoy.mon != bloq.mon)
         bloqueadoHoy = false;
   }
   
   if(!bloqueadoHoy && gananciaDelDia <= -InpMaxPerdidaDiaria) {
      bloqueadoHoy  = true;
      fechaBloqueo  = TimeCurrent();
      Print("🛑 LÍMITE DIARIO alcanzado: $", DoubleToString(gananciaDelDia, 2),
            ". Bot bloqueado hasta mañana.");
   }
   
   if(bloqueadoHoy) {
      Comment("🛑 LÍMITE DIARIO ALCANZADO: $", DoubleToString(gananciaDelDia, 2),
              "\nBot bloqueado hasta mañana.");
      return;
   }

   // ── 3. GESTIÓN DE POSICIONES ABIERTAS (BE + Trailing) ─────────
   GestionarProteccion();

   // ── 4. BUSCAR ENTRADA — solo al inicio de cada vela M15 ───────
   datetime velaActual = iTime(_Symbol, PERIOD_M15, 0);
   if(velaActual == ultimaVela) {
      MostrarPanel();
      return;
   }
   ultimaVela = velaActual;

   // Leer indicadores de la vela CERRADA (índice 1 = más fiable)
   double bufMAR[2], bufMAL[2], bufRSI[2], bufATR[2];
   ArraySetAsSeries(bufMAR, true);
   ArraySetAsSeries(bufMAL, true);
   ArraySetAsSeries(bufRSI, true);
   ArraySetAsSeries(bufATR, true);

   if(CopyBuffer(hMA_R, 0, 0, 2, bufMAR) < 2) return;
   if(CopyBuffer(hMA_L, 0, 0, 2, bufMAL) < 2) return;
   if(CopyBuffer(hRSI,  0, 0, 2, bufRSI) < 2) return;
   if(CopyBuffer(hATR,  0, 0, 2, bufATR) < 2) return;

   double maR    = bufMAR[1];  // vela cerrada
   double maL    = bufMAL[1];
   double rsi    = bufRSI[1];
   double atrVal = bufATR[1];
   double bid    = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask    = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   // ── Filtro ATR: solo operar si hay volatilidad suficiente ──────
   double atrUSD = ATRaUSD(atrVal);
   if(atrUSD < InpATR_MinUSD) {
      MostrarPanel();
      return;
   }

   // ── Señales ────────────────────────────────────────────────────
   // COMPRA: MA rápida > lenta + precio > MA rápida + RSI en zona
   bool señalBUY  = (maR > maL) && (bid > maR) && (rsi >= InpRSI_ComMin && rsi <= InpRSI_ComMax);
   // VENTA: MA rápida < lenta + precio < MA rápida + RSI en zona
   bool señalSELL = (maR < maL) && (bid < maR) && (rsi >= InpRSI_VenMin && rsi <= InpRSI_VenMax);

   int posiciones = ContarMisPosiciones();

   // ── COMPRA ─────────────────────────────────────────────────────
   if(señalBUY) {
      // Si hay una venta abierta, cerrarla primero (giro de mercado)
      if(ExisteTipo(POSITION_TYPE_SELL)) {
         CerrarTodas(POSITION_TYPE_SELL);
         Print("🔄 GIRO: Cerrando SELL para abrir BUY");
      }
      if(!ExisteTipo(POSITION_TYPE_BUY) && posiciones < InpMaxOpsAbiertas) {
         AbrirOperacion(ORDER_TYPE_BUY, ask);
      }
   }

   // ── VENTA ──────────────────────────────────────────────────────
   if(señalSELL) {
      // Si hay una compra abierta, cerrarla primero (giro de mercado)
      if(ExisteTipo(POSITION_TYPE_BUY)) {
         CerrarTodas(POSITION_TYPE_BUY);
         Print("🔄 GIRO: Cerrando BUY para abrir SELL");
      }
      if(!ExisteTipo(POSITION_TYPE_SELL) && posiciones < InpMaxOpsAbiertas) {
         AbrirOperacion(ORDER_TYPE_SELL, bid);
      }
   }

   MostrarPanel();
}

//+------------------------------------------------------------------+
//| Abrir operación con SL/TP calculados en USD                       |
//+------------------------------------------------------------------+
void AbrirOperacion(ENUM_ORDER_TYPE tipo, double precio) {
   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickVal <= 0 || tickSize <= 0) return;

   double distSL = (InpStopLossUSD   * tickSize) / (tickVal * InpLotaje);
   double distTP = (InpTakeProfitUSD * tickSize) / (tickVal * InpLotaje);

   double sl, tp;
   if(tipo == ORDER_TYPE_BUY) {
      sl = NormalizeDouble(precio - distSL, _Digits);
      tp = NormalizeDouble(precio + distTP, _Digits);
   } else {
      sl = NormalizeDouble(precio + distSL, _Digits);
      tp = NormalizeDouble(precio - distTP, _Digits);
   }

   string dir = (tipo == ORDER_TYPE_BUY) ? "🟢 BUY" : "🔴 SELL";
   if(trade.PositionOpen(_Symbol, tipo, InpLotaje, precio, sl, tp, "KT_v5")) {
      Print(dir, " | Precio: ", precio, " | SL: $", InpStopLossUSD, " | TP: $", InpTakeProfitUSD);
   }
}

//+------------------------------------------------------------------+
//| Break Even + Trailing Stop basados en USD                         |
//+------------------------------------------------------------------+
void GestionarProteccion() {
   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickVal <= 0 || tickSize <= 0) return;

   double distBE   = (InpBreakEvenUSD    * tickSize) / (tickVal * InpLotaje);
   double distTR   = (InpTrailingStopUSD * tickSize) / (tickVal * InpLotaje);

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)  continue;

      double profit  = PositionGetDouble(POSITION_PROFIT);
      double pOpen   = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl      = PositionGetDouble(POSITION_SL);
      double tp      = PositionGetDouble(POSITION_TP);
      long   tipo    = PositionGetInteger(POSITION_TYPE);
      double bid     = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask     = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      // ── BREAK EVEN ──────────────────────────────────────────────
      if(profit >= InpBreakEvenUSD) {
         if(tipo == POSITION_TYPE_BUY) {
            double newSL = NormalizeDouble(pOpen + distBE * 0.1, _Digits);
            if(newSL > sl)
               trade.PositionModify(ticket, newSL, tp);
         }
         else {
            double newSL = NormalizeDouble(pOpen - distBE * 0.1, _Digits);
            if(sl == 0 || newSL < sl)
               trade.PositionModify(ticket, newSL, tp);
         }
      }

      // ── TRAILING STOP ────────────────────────────────────────────
      if(profit >= InpTrailingStopUSD) {
         if(tipo == POSITION_TYPE_BUY) {
            double newSL = NormalizeDouble(bid - distTR, _Digits);
            if(newSL > sl && newSL > pOpen)
               trade.PositionModify(ticket, newSL, tp);
         }
         else {
            double newSL = NormalizeDouble(ask + distTR, _Digits);
            if(sl == 0 || (newSL < sl && newSL < pOpen))
               trade.PositionModify(ticket, newSL, tp);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Cerrar todas las posiciones de un tipo                            |
//+------------------------------------------------------------------+
void CerrarTodas(ENUM_POSITION_TYPE tipo) {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)  continue;
      if(PositionGetInteger(POSITION_TYPE)  != tipo)     continue;
      trade.PositionClose(ticket);
   }
}

//+------------------------------------------------------------------+
//| Verificar si existe posición de un tipo                           |
//+------------------------------------------------------------------+
bool ExisteTipo(ENUM_POSITION_TYPE tipo) {
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)  continue;
      if(PositionGetInteger(POSITION_TYPE)  == tipo)     return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Contar posiciones del bot                                         |
//+------------------------------------------------------------------+
int ContarMisPosiciones() {
   int c = 0;
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) == InpMagic &&
         PositionGetString(POSITION_SYMBOL) == _Symbol) c++;
   }
   return c;
}

//+------------------------------------------------------------------+
//| Calcular ganancia del día                                         |
//+------------------------------------------------------------------+
void CalcularGananciaDiaria() {
   gananciaDelDia = 0;
   HistorySelect(iTime(_Symbol, PERIOD_D1, 0), TimeCurrent());
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--) {
      ulong ticket = HistoryDealGetTicket(i);
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol &&
         HistoryDealGetInteger(ticket, DEAL_MAGIC) == InpMagic) {
         gananciaDelDia += HistoryDealGetDouble(ticket, DEAL_PROFIT);
      }
   }
   // Sumar profit de posiciones abiertas
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong t = PositionGetTicket(i);
      if(PositionSelectByTicket(t) &&
         PositionGetInteger(POSITION_MAGIC) == InpMagic &&
         PositionGetString(POSITION_SYMBOL) == _Symbol)
         gananciaDelDia += PositionGetDouble(POSITION_PROFIT);
   }
}

//+------------------------------------------------------------------+
//| ATR en USD                                                        |
//+------------------------------------------------------------------+
double ATRaUSD(double atrVal) {
   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize <= 0) return 0;
   return (atrVal / tickSize) * tickVal * InpLotaje;
}

//+------------------------------------------------------------------+
//| Filtro de horario                                                 |
//+------------------------------------------------------------------+
bool EstaEnHorario() {
   MqlDateTime dt;
   TimeCurrent(dt);
   int minAhora  = dt.hour * 60 + dt.min;
   int minCierre = InpHoraFin * 60 + InpMinutoFin;
   return (dt.hour >= InpHoraInicio && minAhora <= minCierre);
}

//+------------------------------------------------------------------+
//| Panel visual                                                      |
//+------------------------------------------------------------------+
void MostrarPanel() {
   double bufMAR[1], bufMAL[1], bufRSI[1], bufATR[1];
   ArraySetAsSeries(bufMAR, true); ArraySetAsSeries(bufMAL, true);
   ArraySetAsSeries(bufRSI, true); ArraySetAsSeries(bufATR, true);
   CopyBuffer(hMA_R, 0, 0, 1, bufMAR);
   CopyBuffer(hMA_L, 0, 0, 1, bufMAL);
   CopyBuffer(hRSI,  0, 0, 1, bufRSI);
   CopyBuffer(hATR,  0, 0, 1, bufATR);

   double bid   = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double atrUS = ATRaUSD(bufATR[0]);

   string tend  = (bufMAR[0] > bufMAL[0]) ? "🟢 ALCISTA" : "🔴 BAJISTA";
   string rsiS  = DoubleToString(bufRSI[0], 1);
   string atrS  = "$" + DoubleToString(atrUS, 2) + ((atrUS >= InpATR_MinUSD) ? " ✅" : " ⛔ Baja");
   string blk   = bloqueadoHoy ? "🛑 BLOQUEADO HOY" : "✅ OPERATIVO";
   string pnl   = (gananciaDelDia >= 0) ? "+$" : "$";

   Comment(
      "╔══════════════════════════════════╗\n",
      "║   KOPYTRADE GOLD PRO v5.0        ║\n",
      "╠══════════════════════════════════╣\n",
      "║ Tendencia M15: ", tend, "\n",
      "║ Precio: ", DoubleToString(bid, _Digits), "\n",
      "║ RSI(14): ", rsiS, "\n",
      "║ ATR: ", atrS, "\n",
      "╠══════════════════════════════════╣\n",
      "║ Beneficio hoy: ", pnl, DoubleToString(MathAbs(gananciaDelDia), 2), "\n",
      "║ Posiciones: ", ContarMisPosiciones(), "/", InpMaxOpsAbiertas, "\n",
      "║ Estado: ", blk, "\n",
      "╚══════════════════════════════════╝"
   );
}
//+------------------------------------------------------------------+

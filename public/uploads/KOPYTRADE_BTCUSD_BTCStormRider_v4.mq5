//+------------------------------------------------------------------+
//|          KOPYTRADE_BTCUSD_BTCStormRider v4.0                    |
//|   BUY + SELL · MA + RSI + ATR · USD CORRECTO · SIN EMA200 DURO  |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Bot Oficial"
#property version   "4.00"
#property strict
#property description "BTC Storm Rider v4.0 | BUY y SELL | BE y Trailing en USD reales"

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
input group "=== 🚨 PROTECCIÓN DE CUENTA ==="
input double   MaxPerdidaDiaria_USD  = 100.0; // Pérdida máxima diaria ($)
input int      MaxOperacionesDia     = 8;     // Máx operaciones por día

//=== ESTRATEGIA ===
input group "=== 📊 ESTRATEGIA ==="
input int      EMA_Tendencia      = 200;      // EMA de tendencia (referencia, no bloqueante)
input int      EMA_Rapida         = 21;       // EMA rápida (momentum)
input int      EMA_Lenta          = 55;       // EMA lenta (confirmación)
input int      RSI_Periodo        = 14;       // Período del RSI
input int      RSI_Compra_Min     = 40;       // RSI mínimo para comprar
input int      RSI_Compra_Max     = 65;       // RSI máximo para comprar
input int      RSI_Venta_Min      = 35;       // RSI mínimo para vender
input int      RSI_Venta_Max      = 60;       // RSI máximo para vender
input int      ATR_Periodo        = 14;       // Período del ATR
input double   ATR_Minimo_USD     = 30.0;     // Volatilidad mínima en $ para operar

//=== BREAK EVEN ===
input group "=== 🔒 BREAK EVEN ==="
input bool     ActivarBE          = true;    // ¿Activar Break Even?
input double   BE_Activar_USD     = 3.0;     // Activar BE cuando ganes X$
input double   BE_Garantia_USD    = 1.0;     // Ganancia mínima asegurada ($)

//=== TRAILING STOP ===
input group "=== 📈 TRAILING STOP ==="
input bool     ActivarTrailing         = true;  // ¿Activar Trailing Stop?
input double   Trailing_Activar_USD    = 3.0;   // Activar cuando ganes X$
input double   Trailing_Distancia_USD  = 2.0;   // Distancia del trailing ($)

//=== CONFIGURACIÓN AVANZADA ===
input group "=== ⚙️ CONFIGURACIÓN AVANZADA ==="
input int      MaxPosiciones     = 2;         // Máx posiciones simultáneas
input bool     MostrarPanel      = true;      // Mostrar panel visual
input long     MagicNumber       = 780044;    // ID único del bot

//--- Variables internas ---
CTrade trade;
bool     licenseValid    = false;
int      hEmaTend        = INVALID_HANDLE;
int      hEmaRap         = INVALID_HANDLE;
int      hEmaLent        = INVALID_HANDLE;
int      hRSI            = INVALID_HANDLE;
int      hATR            = INVALID_HANDLE;
datetime ultimaVela      = 0;
int      operacionesHoy  = 0;
double   perdidaHoy      = 0;
int      diaActual       = -1;
bool     bloqueadoHoy    = false;
datetime fechaBloqueo    = 0;

//+------------------------------------------------------------------+
//| LICENCIA                                                          |
//+------------------------------------------------------------------+
bool CheckLicense() {
   long cuenta = AccountInfoInteger(ACCOUNT_LOGIN);
   if(cuenta == CuentaDemo || cuenta == CuentaReal) return true;
   if(AccountInfoInteger(ACCOUNT_TRADE_MODE) != ACCOUNT_TRADE_MODE_DEMO) {
      Alert("❌ LICENCIA REQUERIDA PARA CUENTA REAL. Compra en kopytrade.com");
      return false;
   }
   string gVarName = "KOPYTRADE_BSR4_TRIAL_START";
   datetime firstRun;
   if(!GlobalVariableCheck(gVarName)) {
      GlobalVariableSet(gVarName, (double)TimeCurrent());
      firstRun = TimeCurrent();
      Print("🆓 BTC STORM RIDER v4.0 — TRIAL INICIADO (30 DÍAS)");
   } else {
      firstRun = (datetime)GlobalVariableGet(gVarName);
   }
   int dias = (int)((TimeCurrent() - firstRun) / 86400);
   if(dias <= 30) {
      Comment("⚡ BTC STORM RIDER v4.0 TRIAL | Día " + IntegerToString(dias+1) + "/30 | kopytrade.com");
      return true;
   }
   Alert("⏰ TRIAL EXPIRADO. Compra en kopytrade.com");
   return false;
}

//+------------------------------------------------------------------+
//| OnInit                                                            |
//+------------------------------------------------------------------+
int OnInit() {
   if(!CheckLicense()) return INIT_FAILED;

   // Todos los handles en el timeframe del gráfico
   hEmaTend = iMA(_Symbol, _Period, EMA_Tendencia, 0, MODE_EMA, PRICE_CLOSE);
   hEmaRap  = iMA(_Symbol, _Period, EMA_Rapida,    0, MODE_EMA, PRICE_CLOSE);
   hEmaLent = iMA(_Symbol, _Period, EMA_Lenta,     0, MODE_EMA, PRICE_CLOSE);
   hRSI     = iRSI(_Symbol, _Period, RSI_Periodo,  PRICE_CLOSE);
   hATR     = iATR(_Symbol, _Period, ATR_Periodo);

   if(hEmaTend == INVALID_HANDLE || hEmaRap == INVALID_HANDLE ||
      hEmaLent == INVALID_HANDLE || hRSI    == INVALID_HANDLE ||
      hATR     == INVALID_HANDLE) {
      Alert("❌ Error al crear indicadores. Reinicia el bot.");
      return INIT_FAILED;
   }

   licenseValid = true;
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetTypeFillingBySymbol(_Symbol);

   Print("✅ BTC Storm Rider v4.0 ACTIVADO en ", _Symbol);
   Print("   BE/Trailing calculados en USD reales con tick value");
   Print("   EMA200 como referencia, NO como filtro duro → BUY y SELL activos");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| OnDeinit                                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   if(hEmaTend != INVALID_HANDLE) IndicatorRelease(hEmaTend);
   if(hEmaRap  != INVALID_HANDLE) IndicatorRelease(hEmaRap);
   if(hEmaLent != INVALID_HANDLE) IndicatorRelease(hEmaLent);
   if(hRSI     != INVALID_HANDLE) IndicatorRelease(hRSI);
   if(hATR     != INVALID_HANDLE) IndicatorRelease(hATR);
   Comment("");
}

//+------------------------------------------------------------------+
//| Convertir distancia de precio a USD                               |
//+------------------------------------------------------------------+
double PrecioAUSD(double distancia) {
   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize <= 0) return 0;
   return (distancia / tickSize) * tickVal * LoteInicial;
}

//+------------------------------------------------------------------+
//| Convertir USD a distancia de precio                               |
//+------------------------------------------------------------------+
double USDaPrecio(double dolares) {
   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickVal <= 0 || LoteInicial <= 0) return 0;
   return (dolares * tickSize) / (tickVal * LoteInicial);
}

//+------------------------------------------------------------------+
//| OnTick                                                            |
//+------------------------------------------------------------------+
void OnTick() {
   if(!licenseValid) return;

   // ── Reset diario ──────────────────────────────────────────────
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(dt.day_of_year != diaActual) {
      diaActual = dt.day_of_year;
      operacionesHoy = 0;
      perdidaHoy = 0;
      // Desbloquear si es día nuevo
      if(bloqueadoHoy) {
         MqlDateTime fb;
         TimeToStruct(fechaBloqueo, fb);
         if(dt.day != fb.day || dt.mon != fb.mon)
            bloqueadoHoy = false;
      }
      ContarOperacionesYPerdidasHoy();
   }

   // ── Límite diario — bloqueo permanente hasta mañana ──────────
   if(!bloqueadoHoy && perdidaHoy >= MaxPerdidaDiaria_USD) {
      bloqueadoHoy = true;
      fechaBloqueo = TimeCurrent();
      Print("🛑 LÍMITE DIARIO alcanzado: $", DoubleToString(perdidaHoy, 2),
            ". Bot bloqueado hasta mañana.");
   }
   if(bloqueadoHoy) {
      Comment("🛑 LÍMITE DIARIO $", DoubleToString(MaxPerdidaDiaria_USD, 0),
              " ALCANZADO · Bot bloqueado hasta mañana.");
      return;
   }

   // ── Máx operaciones diarias ───────────────────────────────────
   if(operacionesHoy >= MaxOperacionesDia) {
      if(MostrarPanel) DibujarPanel();
      return;
   }

   // ── Gestión BE + Trailing de posiciones abiertas ──────────────
   GestionarPosiciones();

   // ── Buscar entrada solo al inicio de cada vela ────────────────
   datetime velaActual = iTime(_Symbol, _Period, 0);
   if(velaActual == ultimaVela) {
      if(MostrarPanel) DibujarPanel();
      return;
   }
   ultimaVela = velaActual;

   if(!EstaEnSesion()) {
      if(MostrarPanel) DibujarPanel();
      return;
   }

   // ── Leer indicadores de la vela cerrada (índice 1) ────────────
   double bufTend[2], bufRap[2], bufLent[2], bufRSI[2], bufATR[2];
   ArraySetAsSeries(bufTend, true);
   ArraySetAsSeries(bufRap,  true);
   ArraySetAsSeries(bufLent, true);
   ArraySetAsSeries(bufRSI,  true);
   ArraySetAsSeries(bufATR,  true);

   if(CopyBuffer(hEmaTend, 0, 0, 2, bufTend) < 2) return;
   if(CopyBuffer(hEmaRap,  0, 0, 2, bufRap)  < 2) return;
   if(CopyBuffer(hEmaLent, 0, 0, 2, bufLent) < 2) return;
   if(CopyBuffer(hRSI,     0, 0, 2, bufRSI)  < 2) return;
   if(CopyBuffer(hATR,     0, 0, 2, bufATR)  < 2) return;

   double emaTend = bufTend[1];
   double emaRap  = bufRap[1];
   double emaLent = bufLent[1];
   double rsi     = bufRSI[1];
   double atrVal  = bufATR[1];

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   // ── Filtro ATR — volatilidad mínima en USD REAL ───────────────
   double atrUSD = PrecioAUSD(atrVal);
   if(atrUSD < ATR_Minimo_USD) {
      if(MostrarPanel) DibujarPanel();
      return;
   }

   // ── SL y TP dinámicos ─────────────────────────────────────────
   double slDist = atrVal * ATR_Multiplicador_SL;
   double tpDist = atrVal * ATR_Multiplicador_TP;

   // Verificar riesgo máximo por trade
   double slUSD = PrecioAUSD(slDist);
   if(slUSD > MaxRiesgoPorTrade_USD) return;

   // ── SEÑALES ───────────────────────────────────────────────────
   // BUY:  EMA rápida > EMA lenta + precio > EMA rápida + RSI ok
   // EMA200 como contexto: si precio > EMA200 la señal es más fuerte
   // pero NO bloquea — permite operar en ambas direcciones
   bool señalBUY  = (emaRap > emaLent) && (bid > emaRap) &&
                    (rsi >= RSI_Compra_Min && rsi <= RSI_Compra_Max);

   bool señalSELL = (emaRap < emaLent) && (bid < emaRap) &&
                    (rsi >= RSI_Venta_Min  && rsi <= RSI_Venta_Max);

   int posiciones = ContarPosiciones();

   // ── COMPRA ────────────────────────────────────────────────────
   if(señalBUY) {
      // Giro de mercado: cerrar ventas abiertas primero
      if(ExisteTipo(POSITION_TYPE_SELL)) {
         CerrarTodas(POSITION_TYPE_SELL);
         Print("🔄 GIRO: Cerrando SELL para abrir BUY");
      }
      if(!ExisteTipo(POSITION_TYPE_BUY) && posiciones < MaxPosiciones) {
         double sl = NormalizeDouble(ask - slDist, _Digits);
         double tp = NormalizeDouble(ask + tpDist, _Digits);
         if(trade.Buy(LoteInicial, _Symbol, ask, sl, tp, "BSR4_BUY")) {
            operacionesHoy++;
            Print("🟢 BUY | Precio: ", ask,
                  " | SL: ", sl, " ($", DoubleToString(slUSD, 2), ")",
                  " | TP: ", tp, " ($", DoubleToString(PrecioAUSD(tpDist), 2), ")",
                  " | EMA200: ", (bid > emaTend ? "a favor" : "en contra"));
         }
      }
   }

   // ── VENTA ─────────────────────────────────────────────────────
   if(señalSELL) {
      // Giro de mercado: cerrar compras abiertas primero
      if(ExisteTipo(POSITION_TYPE_BUY)) {
         CerrarTodas(POSITION_TYPE_BUY);
         Print("🔄 GIRO: Cerrando BUY para abrir SELL");
      }
      if(!ExisteTipo(POSITION_TYPE_SELL) && posiciones < MaxPosiciones) {
         double sl = NormalizeDouble(bid + slDist, _Digits);
         double tp = NormalizeDouble(bid - tpDist, _Digits);
         if(trade.Sell(LoteInicial, _Symbol, bid, sl, tp, "BSR4_SELL")) {
            operacionesHoy++;
            Print("🔴 SELL | Precio: ", bid,
                  " | SL: ", sl, " ($", DoubleToString(slUSD, 2), ")",
                  " | TP: ", tp, " ($", DoubleToString(PrecioAUSD(tpDist), 2), ")",
                  " | EMA200: ", (bid < emaTend ? "a favor" : "en contra"));
         }
      }
   }

   if(MostrarPanel) DibujarPanel();
}

//+------------------------------------------------------------------+
//| BE + TRAILING — cálculo correcto para BTC (tick value real)       |
//+------------------------------------------------------------------+
void GestionarPosiciones() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)     continue;

      double profit = PositionGetDouble(POSITION_PROFIT);
      double pOpen  = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl     = PositionGetDouble(POSITION_SL);
      double tp     = PositionGetDouble(POSITION_TP);
      long   tipo   = PositionGetInteger(POSITION_TYPE);
      double bid    = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask    = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      // Conversión USD → precio CORRECTA para BTC
      double distBE   = USDaPrecio(BE_Garantia_USD);
      double distTR   = USDaPrecio(Trailing_Distancia_USD);

      // ── BREAK EVEN ──────────────────────────────────────────────
      if(ActivarBE && profit >= BE_Activar_USD) {
         if(tipo == POSITION_TYPE_BUY) {
            double newSL = NormalizeDouble(pOpen + distBE, _Digits);
            if(newSL > sl) {
               if(trade.PositionModify(ticket, newSL, tp))
                  Print("🔒 BE [BUY] | Profit: $", DoubleToString(profit, 2),
                        " | SL → ", newSL);
            }
         }
         else {
            double newSL = NormalizeDouble(pOpen - distBE, _Digits);
            if(sl == 0 || newSL < sl) {
               if(trade.PositionModify(ticket, newSL, tp))
                  Print("🔒 BE [SELL] | Profit: $", DoubleToString(profit, 2),
                        " | SL → ", newSL);
            }
         }
      }

      // ── TRAILING STOP ────────────────────────────────────────────
      if(ActivarTrailing && profit >= Trailing_Activar_USD) {
         if(tipo == POSITION_TYPE_BUY) {
            double newSL = NormalizeDouble(bid - distTR, _Digits);
            if(newSL > sl && newSL > pOpen) {
               if(trade.PositionModify(ticket, newSL, tp))
                  Print("📈 TRAILING [BUY] | Profit: $", DoubleToString(profit, 2),
                        " | SL → ", newSL);
            }
         }
         else {
            double newSL = NormalizeDouble(ask + distTR, _Digits);
            if(sl == 0 || (newSL < sl && newSL < pOpen)) {
               if(trade.PositionModify(ticket, newSL, tp))
                  Print("📈 TRAILING [SELL] | Profit: $", DoubleToString(profit, 2),
                        " | SL → ", newSL);
            }
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
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)     continue;
      if(PositionGetInteger(POSITION_TYPE)  != tipo)        continue;
      trade.PositionClose(ticket);
   }
}

//+------------------------------------------------------------------+
//| Existe posición de un tipo                                        |
//+------------------------------------------------------------------+
bool ExisteTipo(ENUM_POSITION_TYPE tipo) {
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)     continue;
      if(PositionGetInteger(POSITION_TYPE)  == tipo)        return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Contar posiciones del bot                                         |
//+------------------------------------------------------------------+
int ContarPosiciones() {
   int c = 0;
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) &&
         PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
         PositionGetString(POSITION_SYMBOL) == _Symbol) c++;
   }
   return c;
}

//+------------------------------------------------------------------+
//| Contar operaciones y pérdidas del día                             |
//+------------------------------------------------------------------+
void ContarOperacionesYPerdidasHoy() {
   operacionesHoy = 0;
   perdidaHoy     = 0;
   datetime inicioHoy = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   HistorySelect(inicioHoy, TimeCurrent());
   for(int i = 0; i < HistoryDealsTotal(); i++) {
      ulong ticket = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC)  != MagicNumber) continue;
      if(HistoryDealGetString(ticket,  DEAL_SYMBOL) != _Symbol)     continue;
      if(HistoryDealGetInteger(ticket, DEAL_ENTRY)  == DEAL_ENTRY_OUT) {
         operacionesHoy++;
         double p = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         if(p < 0) perdidaHoy += MathAbs(p);
      }
   }
}

//+------------------------------------------------------------------+
//| Filtro de sesión                                                  |
//+------------------------------------------------------------------+
bool EstaEnSesion() {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int hora = dt.hour;
   if(hora >= SesionEuropa_Inicio && hora < SesionEuropa_Fin) return true;
   if(hora >= SesionUS_Inicio     && hora < SesionUS_Fin)     return true;
   if(OperarEnAsia && hora >= 0   && hora < 8)                return true;
   return false;
}

//+------------------------------------------------------------------+
//| Panel visual                                                      |
//+------------------------------------------------------------------+
void DibujarPanel() {
   double bTend[1], bRap[1], bLent[1], bRSI[1], bATR[1];
   ArraySetAsSeries(bTend, true); ArraySetAsSeries(bRap,  true);
   ArraySetAsSeries(bLent, true); ArraySetAsSeries(bRSI,  true);
   ArraySetAsSeries(bATR,  true);
   CopyBuffer(hEmaTend, 0, 0, 1, bTend);
   CopyBuffer(hEmaRap,  0, 0, 1, bRap);
   CopyBuffer(hEmaLent, 0, 0, 1, bLent);
   CopyBuffer(hRSI,     0, 0, 1, bRSI);
   CopyBuffer(hATR,     0, 0, 1, bATR);

   double bid    = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double atrUSD = PrecioAUSD(bATR[0]);

   string tend  = (bRap[0] > bLent[0]) ? "🟢 ALCISTA" : "🔴 BAJISTA";
   string ema200 = (bid > bTend[0]) ? "🟢 Precio > EMA200" : "🔴 Precio < EMA200";
   string rsiS  = DoubleToString(bRSI[0], 1);
   string atrS  = "$" + DoubleToString(atrUSD, 2) + ((atrUSD >= ATR_Minimo_USD) ? " ✅" : " ⛔ Baja");
   string estado = bloqueadoHoy ? "🛑 BLOQUEADO HOY" :
                   (operacionesHoy >= MaxOperacionesDia ? "⚠️ MÁX OPS" : "✅ OPERATIVO");

   Comment(
      "╔══════════════════════════════════╗\n",
      "║  ⚡ BTC STORM RIDER v4.0         ║\n",
      "║       KOPYTRADE.COM              ║\n",
      "╠══════════════════════════════════╣\n",
      "║ Momentum: ", tend, "\n",
      "║ ", ema200, "\n",
      "║ RSI(", RSI_Periodo, "): ", rsiS, "\n",
      "║ ATR: ", atrS, "\n",
      "║ Sesión: ", EstaEnSesion() ? "🟢 ACTIVA" : "🔴 FUERA", "\n",
      "╠══════════════════════════════════╣\n",
      "║ Ops hoy: ", operacionesHoy, "/", MaxOperacionesDia, "\n",
      "║ Pérdida hoy: $", DoubleToString(perdidaHoy, 2), "/$", MaxPerdidaDiaria_USD, "\n",
      "║ Posiciones: ", ContarPosiciones(), "/", MaxPosiciones, "\n",
      "║ Estado: ", estado, "\n",
      "╚══════════════════════════════════╝"
   );
}
//+------------------------------------------------------------------+

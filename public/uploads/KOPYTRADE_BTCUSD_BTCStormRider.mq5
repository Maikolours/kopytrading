//+------------------------------------------------------------------+
//|          KOPYTRADE_BTCUSD_BTCStormRider v4.2 (EQUILIBRADO)       |
//|   BUY + SELL · MA + RSI + ATR · TENDENCIA ESTRICTA EMA 200      |
//|   MEJORAS: Lote dinámico, riesgo flotante, trailing optimizado  |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Bot Oficial (v4.2 Equilibrado y Alegre)"
#property version   "4.20"
#property strict
#property description "BTC Storm Rider v4.2 | Filtros de tendencia reactivados, parámetros campeones"

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
input double   RiskPercent          = 1.0;    // % de riesgo por operación (del saldo)
input double   MaxRiesgoPorTrade_USD = 50.0;  // Máxima pérdida en $ por trade (límite seguro)
input double   ATR_SL_Mult           = 1.5;   // Multiplicador ATR para Stop Loss
input double   ATR_TP_Mult           = 3.5;   // Multiplicador ATR para Take Profit (Campeón)
input int      MaxSpreadPoints       = 5000;  // Máximo spread permitido (Cripto necesita miles)

//=== PROTECCIÓN DE CUENTA ===
input group "=== 🚨 PROTECCIÓN DE CUENTA ==="
input double   MaxPerdidaDiaria_USD  = 100.0; // Pérdida máxima diaria ($) incluyendo flotantes
input int      MaxOperacionesDia     = 15;    // Máx operaciones por día (Alegre)
input int      MinSecondsBetweenTrades = 180; // Segundos mínimos entre operaciones (3 min)

//=== ESTRATEGIA ===
input group "=== 📊 ESTRATEGIA ==="
input int      EMA_Tendencia      = 100;      // EMA de tendencia (Reducida a 100 para no bloquear)
input int      EMA_Rapida         = 10;       // EMA rápida (momentum ágil)
input int      EMA_Lenta          = 55;       // EMA lenta (confirmación)
input int      RSI_Periodo        = 14;       // Período del RSI
input int      RSI_Compra_Min     = 30;       // RSI mínimo para comprar (Ventana amplia)
input int      RSI_Compra_Max     = 70;       // RSI máximo para comprar
input int      RSI_Venta_Min      = 30;       // RSI mínimo para vender (Ventana amplia)
input int      RSI_Venta_Max      = 70;       // RSI máximo para vender
input int      ATR_Periodo        = 14;       // Período del ATR
input double   ATR_Minimo_USD     = 20.0;     // Volatilidad mínima en $ para operar (Dinámico)

//=== BREAK EVEN ===
input group "=== 🔒 BREAK EVEN ==="
input bool     ActivarBE          = true;    // ¿Activar Break Even?
input double   BE_Activar_USD     = 2.0;     // Activar BE cuando ganes X$
input double   BE_Garantia_USD    = 0.5;     // Ganancia mínima asegurada ($)

//=== TRAILING STOP ===
input group "=== 📈 TRAILING STOP ==="
input bool     ActivarTrailing         = true;  // ¿Activar Trailing Stop?
input double   Trailing_Activar_USD    = 5.0;   // Activar cuando ganes X$
input double   Trailing_Distancia_USD  = 2.0;   // Distancia del trailing ($)

//=== CONFIGURACIÓN AVANZADA ===
input group "=== ⚙️ CONFIGURACIÓN AVANZADA ==="
input int      MaxPosiciones     = 3;         // Máx posiciones simultáneas
input bool     MostrarPanel      = true;      // Mostrar panel visual
input long     MagicNumber       = 780045;    // ID único del bot

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
double   perdidaHoy      = 0;          // Incluye pérdidas cerradas + flotantes negativos
int      diaActual       = -1;
bool     bloqueadoHoy    = false;
datetime fechaBloqueo    = 0;
datetime ultimaOperacion = 0;           // Control de tiempo entre operaciones

//+------------------------------------------------------------------+
//| LICENCIA                                                         |
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
      Print("🆓 BTC STORM RIDER v4.2 — TRIAL INICIADO (30 DÍAS)");
   } else {
      firstRun = (datetime)GlobalVariableGet(gVarName);
   }
   int dias = (int)((TimeCurrent() - firstRun) / 86400);
   if(dias <= 30) {
      Comment("⚡ BTC STORM RIDER v4.2 TRIAL | Día " + IntegerToString(dias+1) + "/30 | kopytrade.com");
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
   trade.SetDeviationInPoints(10); // Desviación permitida

   Print("✅ BTC Storm Rider v4.2 EQUILIBRADO ACTIVADO en ", _Symbol);
   Print("   Tendencia blindada por EMA ", EMA_Tendencia);
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
double PrecioAUSD(double distancia, double lote = 0) {
   if(lote == 0) lote = CalcularLote(); // Usar lote actual si no se especifica
   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize <= 0 || lote <= 0) return 0;
   return (distancia / tickSize) * tickVal * lote;
}

//+------------------------------------------------------------------+
//| Convertir USD a distancia de precio                               |
//+------------------------------------------------------------------+
double USDaPrecio(double dolares, double lote = 0) {
   if(lote == 0) lote = CalcularLote();
   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickVal <= 0 || lote <= 0) return 0;
   return (dolares * tickSize) / (tickVal * lote);
}

//+------------------------------------------------------------------+
//| Calcular lote dinámico según riesgo porcentual                    |
//+------------------------------------------------------------------+
double CalcularLote() {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riesgoUSD = balance * RiskPercent / 100.0;
   if(riesgoUSD > MaxRiesgoPorTrade_USD) riesgoUSD = MaxRiesgoPorTrade_USD;

   // Necesitamos el ATR actual para estimar la distancia del SL
   double atr[1];
   if(CopyBuffer(hATR, 0, 1, 1, atr) != 1) return 0.01; // valor por defecto
   double slDist = atr[0] * ATR_SL_Mult;
   double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickVal <= 0 || tickSize <= 0 || slDist <= 0) return 0.01;

   // Lote = riesgoUSD / (slDist en USD por lote 1.0)
   double usdPorLote = (slDist / tickSize) * tickVal;
   double lote = riesgoUSD / usdPorLote;

   // Ajustar a límites de lote del símbolo
   double minLote = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLote = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepLote = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   lote = MathFloor(lote / stepLote) * stepLote;
   if(lote < minLote) lote = minLote;
   if(lote > maxLote) lote = maxLote;
   return lote;
}

//+------------------------------------------------------------------+
//| Comprobar si el spread es aceptable                              |
//+------------------------------------------------------------------+
bool SpreadOk() {
   double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   return (spread <= MaxSpreadPoints);
}

//+------------------------------------------------------------------+
//| Verificar si hay margen suficiente para abrir posición           |
//+------------------------------------------------------------------+
bool MargenSuficiente(double lote) {
   double margin = 0;
   if(!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, lote, SymbolInfoDouble(_Symbol, SYMBOL_ASK), margin)) {
      return false;
   }
   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   return (margin <= freeMargin * 0.9); // dejar 10% de colchón
}

//+------------------------------------------------------------------+
//| Actualizar pérdida diaria incluyendo flotantes                   |
//+------------------------------------------------------------------+
void ActualizarPerdidaHoy() {
   double perdidaCerrada = 0;
   double perdidaFlotante = 0;

   // Pérdidas cerradas hoy
   datetime inicioHoy = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   HistorySelect(inicioHoy, TimeCurrent());
   for(int i = 0; i < HistoryDealsTotal(); i++) {
      ulong ticket = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != MagicNumber) continue;
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol) continue;
      if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
         double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         if(profit < 0) perdidaCerrada += MathAbs(profit);
      }
   }

   // Pérdidas flotantes de posiciones abiertas (solo las negativas)
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) &&
         PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
         PositionGetString(POSITION_SYMBOL) == _Symbol) {
         double profit = PositionGetDouble(POSITION_PROFIT);
         if(profit < 0) perdidaFlotante += MathAbs(profit);
      }
   }

   perdidaHoy = perdidaCerrada + perdidaFlotante;
}

//+------------------------------------------------------------------+
//| Contar operaciones cerradas hoy                                  |
//+------------------------------------------------------------------+
int ContarOperacionesHoy() {
   int count = 0;
   datetime inicioHoy = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   HistorySelect(inicioHoy, TimeCurrent());
   for(int i = 0; i < HistoryDealsTotal(); i++) {
      ulong ticket = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != MagicNumber) continue;
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol) continue;
      if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
         count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| OnTick                                                            |
//+------------------------------------------------------------------+
void OnTick() {
   if(!licenseValid) return;

   // Actualizar pérdida diaria (incluye flotantes)
   ActualizarPerdidaHoy();

   // ── Reset diario ──────────────────────────────────────────────
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(dt.day_of_year != diaActual) {
      diaActual = dt.day_of_year;
      operacionesHoy = ContarOperacionesHoy();
      perdidaHoy = 0; // se recalculará en la siguiente llamada a ActualizarPerdidaHoy
      // Desbloquear si es día nuevo
      if(bloqueadoHoy) {
         MqlDateTime fb;
         TimeToStruct(fechaBloqueo, fb);
         if(dt.day != fb.day || dt.mon != fb.mon)
            bloqueadoHoy = false;
      }
      ActualizarPerdidaHoy(); // para tener el valor actualizado
   }

   // ── Límite diario — bloqueo permanente hasta mañana ──────────
   if(!bloqueadoHoy && perdidaHoy >= MaxPerdidaDiaria_USD) {
      bloqueadoHoy = true;
      fechaBloqueo = TimeCurrent();
      Print("🛑 LÍMITE DIARIO alcanzado: $", DoubleToString(perdidaHoy, 2),
            " (incluye flotantes). Bot bloqueado hasta mañana.");
   }
   if(bloqueadoHoy) {
      if(MostrarPanel) DibujarPanel();
      return;
   }

   // ── Máx operaciones diarias (cerradas) ────────────────────────
   operacionesHoy = ContarOperacionesHoy();
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

   // Filtro de tiempo entre operaciones
   if(TimeCurrent() - ultimaOperacion < MinSecondsBetweenTrades) {
      if(MostrarPanel) DibujarPanel();
      return;
   }

   if(!EstaEnSesion()) {
      if(MostrarPanel) DibujarPanel();
      return;
   }

   if(!SpreadOk()) {
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
   double atrUSD = PrecioAUSD(atrVal, 1.0); // con lote=1 para comparar
   if(atrUSD < ATR_Minimo_USD) {
      if(MostrarPanel) DibujarPanel();
      return;
   }

   // Calcular lote dinámico basado en el riesgo
   double lote = CalcularLote();
   if(lote <= 0) return;
   if(!MargenSuficiente(lote)) {
      Print("⚠️ Margen insuficiente para lote ", lote);
      return;
   }

   // ── SL y TP dinámicos ─────────────────────────────────────────
   double slDist = atrVal * ATR_SL_Mult;
   double tpDist = atrVal * ATR_TP_Mult;

   // Verificar riesgo máximo por trade
   double slUSD = PrecioAUSD(slDist, lote);
   if(slUSD > MaxRiesgoPorTrade_USD) {
      lote = lote * (MaxRiesgoPorTrade_USD / slUSD);
      double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      lote = MathFloor(lote / step) * step;
      if(lote < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN)) return;
      slUSD = PrecioAUSD(slDist, lote); 
   }

   // ── SEÑALES V4.2 (CON ESCUDO DE TENDENCIA) ────────────────────────
   bool señalBUY  = (bid > emaTend) && // <-- FILTRO DE TENDENCIA ACTIVO
                    (emaRap > emaLent) && (bid > emaRap) &&
                    (rsi >= RSI_Compra_Min && rsi <= RSI_Compra_Max);

   bool señalSELL = (bid < emaTend) && // <-- FILTRO DE TENDENCIA ACTIVO
                    (emaRap < emaLent) && (bid < emaRap) &&
                    (rsi >= RSI_Venta_Min  && rsi <= RSI_Venta_Max);

   int posiciones = ContarPosiciones();

   // ── COMPRA ────────────────────────────────────────────────────
   if(señalBUY) {
      if(ExisteTipo(POSITION_TYPE_SELL)) {
         CerrarTodas(POSITION_TYPE_SELL);
         Print("🔄 GIRO: Cerrando SELL para abrir BUY");
      }
      if(!ExisteTipo(POSITION_TYPE_BUY) && posiciones < MaxPosiciones) {
         double sl = NormalizeDouble(ask - slDist, _Digits);
         double tp = NormalizeDouble(ask + tpDist, _Digits);

         double stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
         if(sl > ask - stopLevel) sl = ask - stopLevel;
         if(tp < ask + stopLevel) tp = ask + stopLevel;

         for(int intento = 0; intento < 3; intento++) {
            if(trade.Buy(lote, _Symbol, ask, sl, tp, "BSR42_BUY_SAFE")) {
               operacionesHoy++;
               ultimaOperacion = TimeCurrent();
               Print("🟢 BUY SEGURO | Lote: ", lote, " Precio: ", ask);
               break;
            } else {
               if(intento < 2) Sleep(500);
            }
         }
      }
   }

   // ── VENTA ─────────────────────────────────────────────────────
   if(señalSELL) {
      if(ExisteTipo(POSITION_TYPE_BUY)) {
         CerrarTodas(POSITION_TYPE_BUY);
         Print("🔄 GIRO: Cerrando BUY para abrir SELL");
      }
      if(!ExisteTipo(POSITION_TYPE_SELL) && posiciones < MaxPosiciones) {
         double sl = NormalizeDouble(bid + slDist, _Digits);
         double tp = NormalizeDouble(bid - tpDist, _Digits);

         double stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
         if(sl < bid + stopLevel) sl = bid + stopLevel;
         if(tp > bid - stopLevel) tp = bid - stopLevel;

         for(int intento = 0; intento < 3; intento++) {
            if(trade.Sell(lote, _Symbol, bid, sl, tp, "BSR42_SELL_SAFE")) {
               operacionesHoy++;
               ultimaOperacion = TimeCurrent();
               Print("🔴 SELL SEGURO | Lote: ", lote, " Precio: ", bid);
               break;
            } else {
               if(intento < 2) Sleep(500);
            }
         }
      }
   }

   if(MostrarPanel) DibujarPanel();
}

//+------------------------------------------------------------------+
//| BE + TRAILING 
//+------------------------------------------------------------------+
void GestionarPosiciones() {
   static datetime ultimaModif = 0;
   datetime ahora = TimeCurrent();
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

      double lotePos = PositionGetDouble(POSITION_VOLUME);
      double distBE   = USDaPrecio(BE_Garantia_USD, lotePos);
      double distTR   = USDaPrecio(Trailing_Distancia_USD, lotePos);
      bool modificado = false;

      // ── BREAK EVEN ──────────────────────────────────────────────
      if(ActivarBE && profit >= BE_Activar_USD) {
         if(tipo == POSITION_TYPE_BUY) {
            double newSL = NormalizeDouble(pOpen + distBE, _Digits);
            if(newSL > sl) {
               if(trade.PositionModify(ticket, newSL, tp)) {
                  modificado = true;
               }
            }
         } else {
            double newSL = NormalizeDouble(pOpen - distBE, _Digits);
            if(sl == 0 || newSL < sl) {
               if(trade.PositionModify(ticket, newSL, tp)) {
                  modificado = true;
               }
            }
         }
      }

      // ── TRAILING STOP (solo si no se ha modificado ya en este ciclo) ──
      if(ActivarTrailing && !modificado && profit >= Trailing_Activar_USD) {
         if(tipo == POSITION_TYPE_BUY) {
            double newSL = NormalizeDouble(bid - distTR, _Digits);
            if(newSL > sl && newSL > pOpen) {
               if(trade.PositionModify(ticket, newSL, tp)) {
                  modificado = true;
               }
            }
         } else {
            double newSL = NormalizeDouble(ask + distTR, _Digits);
            if(sl == 0 || (newSL < sl && newSL < pOpen)) {
               if(trade.PositionModify(ticket, newSL, tp)) {
                  modificado = true;
               }
            }
         }
      }

      if(modificado) ultimaModif = ahora;
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
//| Panel visual mejorado                                            |
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
   double ask    = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
   double atrUSD = PrecioAUSD(bATR[0], 1.0);
   double loteCalc = CalcularLote();
   double profitFlotante = 0;
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) &&
         PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
         PositionGetString(POSITION_SYMBOL) == _Symbol) {
         profitFlotante += PositionGetDouble(POSITION_PROFIT);
      }
   }

   string tend  = (bRap[0] > bLent[0]) ? "🟢 ALCISTA" : "🔴 BAJISTA";
   string ema200 = (bid > bTend[0]) ? "🟢 Precio > EMA250" : "🔴 Precio < EMA250";
   string rsiS  = DoubleToString(bRSI[0], 1);
   string atrS  = "$" + DoubleToString(atrUSD, 2) + ((atrUSD >= ATR_Minimo_USD) ? " ✅" : " ⛔ Baja");
   string spreadS = DoubleToString(spread, _Digits) + " (" + IntegerToString(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD)) + " pts)";
   string estado = bloqueadoHoy ? "🛑 BLOQUEADO HOY" :
                   (operacionesHoy >= MaxOperacionesDia ? "⚠️ MÁX OPS" : "✅ OPERATIVO");
   string riesgoDia = "$" + DoubleToString(perdidaHoy, 2) + "/$" + DoubleToString(MaxPerdidaDiaria_USD, 2);
   string flotante = "$" + DoubleToString(profitFlotante, 2);

   Comment(
      "╔══════════════════════════════════╗\n",
      "║  ⚡ BTC STORM RIDER v4.2         ║\n",
      "║    💎 SEGURO Y EQUILIBRADO       ║\n",
      "╠══════════════════════════════════╣\n",
      "║ Momentum: ", tend, "\n",
      "║ Escudo T.: ", ema200, "\n",
      "║ RSI(", RSI_Periodo, "): ", rsiS, "\n",
      "║ ATR: ", atrS, "\n",
      "║ Spread: ", spreadS, "\n",
      "║ Flotante: ", flotante, "\n",
      "╠══════════════════════════════════╣\n",
      "║ Ops hoy: ", operacionesHoy, "/", MaxOperacionesDia, "\n",
      "║ Posiciones: ", ContarPosiciones(), "/", MaxPosiciones, "\n",
      "║ Estado: ", estado, "\n",
      "╚══════════════════════════════════╝"
   );
}
//+------------------------------------------------------------------+

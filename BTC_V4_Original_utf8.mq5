//+------------------------------------------------------------------+
//|          KOPYTRADE_BTCUSD_BTCStormRider v4.0                    |
//|   BUY + SELL ┬À MA + RSI + ATR ┬À USD CORRECTO ┬À SIN EMA200 DURO  |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Bot Oficial"
#property version   "4.00"
#property strict
#property description "BTC Storm Rider v4.0 | BUY y SELL | BE y Trailing en USD reales"

#include <Trade\Trade.mqh>

//=== LICENCIA KOPYTRADE ===
input group "=== ­ƒöæ LICENCIA KOPYTRADE ==="
input long     CuentaDemo         = 0;       // N┬║ cuenta DEMO de MT5 (Trial y Compra)
input long     CuentaReal         = 0;       // N┬║ cuenta REAL de MT5 (Solo Compra)

//=== SESIONES DE MERCADO ===
input group "=== ÔÅ░ SESIONES DE MERCADO (HORA BROKER) ==="
input int      SesionEuropa_Inicio  = 0;     // Inicio Sesi├│n Europa
input int      SesionEuropa_Fin     = 16;    // Fin Sesi├│n Europa
input int      SesionUS_Inicio      = 14;    // Inicio Sesi├│n USA
input int      SesionUS_Fin         = 24;    // Fin Sesi├│n USA
input bool     OperarEnAsia         = true;  // ┬┐Operar en sesi├│n Asia?

//=== GESTI├ôN DE RIESGO ===
input group "=== ­ƒøí´©Å GESTI├ôN DE RIESGO ==="
input double   LoteInicial           = 0.01;  // Tama├▒o de posici├│n
input double   MaxRiesgoPorTrade_USD = 50.0;  // M├íxima p├®rdida en $ por trade
input double   ATR_Multiplicador_SL  = 1.5;   // Multiplicador ATR para Stop Loss
input double   ATR_Multiplicador_TP  = 2.0;   // Multiplicador ATR para Take Profit

//=== PROTECCI├ôN DE CUENTA ===
input group "=== ­ƒÜ¿ PROTECCI├ôN DE CUENTA ==="
input double   MaxPerdidaDiaria_USD  = 100.0; // P├®rdida m├íxima diaria ($)
input int      MaxOperacionesDia     = 8;     // M├íx operaciones por d├¡a

//=== ESTRATEGIA ===
input group "=== ­ƒôè ESTRATEGIA ==="
input int      EMA_Tendencia      = 200;      // EMA de tendencia (referencia, no bloqueante)
input int      EMA_Rapida         = 21;       // EMA r├ípida (momentum)
input int      EMA_Lenta          = 55;       // EMA lenta (confirmaci├│n)
input int      RSI_Periodo        = 14;       // Per├¡odo del RSI
input int      RSI_Compra_Min     = 40;       // RSI m├¡nimo para comprar
input int      RSI_Compra_Max     = 65;       // RSI m├íximo para comprar
input int      RSI_Venta_Min      = 35;       // RSI m├¡nimo para vender
input int      RSI_Venta_Max      = 60;       // RSI m├íximo para vender
input int      ATR_Periodo        = 14;       // Per├¡odo del ATR
input double   ATR_Minimo_USD     = 30.0;     // Volatilidad m├¡nima en $ para operar

//=== BREAK EVEN ===
input group "=== ­ƒöÆ BREAK EVEN ==="
input bool     ActivarBE          = true;    // ┬┐Activar Break Even?
input double   BE_Activar_USD     = 3.0;     // Activar BE cuando ganes X$
input double   BE_Garantia_USD    = 1.0;     // Ganancia m├¡nima asegurada ($)

//=== TRAILING STOP ===
input group "=== ­ƒôê TRAILING STOP ==="
input bool     ActivarTrailing         = true;  // ┬┐Activar Trailing Stop?
input double   Trailing_Activar_USD    = 3.0;   // Activar cuando ganes X$
input double   Trailing_Distancia_USD  = 2.0;   // Distancia del trailing ($)

//=== CONFIGURACI├ôN AVANZADA ===
input group "=== ÔÜÖ´©Å CONFIGURACI├ôN AVANZADA ==="
input int      MaxPosiciones     = 2;         // M├íx posiciones simult├íneas
input bool     MostrarPanel      = true;      // Mostrar panel visual
input long     MagicNumber       = 780044;    // ID ├║nico del bot

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
      Alert("ÔØî LICENCIA REQUERIDA PARA CUENTA REAL. Compra en kopytrade.com");
      return false;
   }
   string gVarName = "KOPYTRADE_BSR4_TRIAL_START";
   datetime firstRun;
   if(!GlobalVariableCheck(gVarName)) {
      GlobalVariableSet(gVarName, (double)TimeCurrent());
      firstRun = TimeCurrent();
      Print("­ƒåô BTC STORM RIDER v4.0 ÔÇö TRIAL INICIADO (30 D├ìAS)");
   } else {
      firstRun = (datetime)GlobalVariableGet(gVarName);
   }
   int dias = (int)((TimeCurrent() - firstRun) / 86400);
   if(dias <= 30) {
      Comment("ÔÜí BTC STORM RIDER v4.0 TRIAL | D├¡a " + IntegerToString(dias+1) + "/30 | kopytrade.com");
      return true;
   }
   Alert("ÔÅ░ TRIAL EXPIRADO. Compra en kopytrade.com");
   return false;
}

//+------------------------------------------------------------------+
//| OnInit                                                            |
//+------------------------------------------------------------------+
int OnInit() {
   if(!CheckLicense()) return INIT_FAILED;

   // Todos los handles en el timeframe del gr├ífico
   hEmaTend = iMA(_Symbol, _Period, EMA_Tendencia, 0, MODE_EMA, PRICE_CLOSE);
   hEmaRap  = iMA(_Symbol, _Period, EMA_Rapida,    0, MODE_EMA, PRICE_CLOSE);
   hEmaLent = iMA(_Symbol, _Period, EMA_Lenta,     0, MODE_EMA, PRICE_CLOSE);
   hRSI     = iRSI(_Symbol, _Period, RSI_Periodo,  PRICE_CLOSE);
   hATR     = iATR(_Symbol, _Period, ATR_Periodo);

   if(hEmaTend == INVALID_HANDLE || hEmaRap == INVALID_HANDLE ||
      hEmaLent == INVALID_HANDLE || hRSI    == INVALID_HANDLE ||
      hATR     == INVALID_HANDLE) {
      Alert("ÔØî Error al crear indicadores. Reinicia el bot.");
      return INIT_FAILED;
   }

   licenseValid = true;
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetTypeFillingBySymbol(_Symbol);

   Print("Ô£à BTC Storm Rider v4.0 ACTIVADO en ", _Symbol);
   Print("   BE/Trailing calculados en USD reales con tick value");
   Print("   EMA200 como referencia, NO como filtro duro ÔåÆ BUY y SELL activos");
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

   // ÔöÇÔöÇ Reset diario ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(dt.day_of_year != diaActual) {
      diaActual = dt.day_of_year;
      operacionesHoy = 0;
      perdidaHoy = 0;
      // Desbloquear si es d├¡a nuevo
      if(bloqueadoHoy) {
         MqlDateTime fb;
         TimeToStruct(fechaBloqueo, fb);
         if(dt.day != fb.day || dt.mon != fb.mon)
            bloqueadoHoy = false;
      }
      ContarOperacionesYPerdidasHoy();
   }

   // ÔöÇÔöÇ L├¡mite diario ÔÇö bloqueo permanente hasta ma├▒ana ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
   if(!bloqueadoHoy && perdidaHoy >= MaxPerdidaDiaria_USD) {
      bloqueadoHoy = true;
      fechaBloqueo = TimeCurrent();
      Print("­ƒøæ L├ìMITE DIARIO alcanzado: $", DoubleToString(perdidaHoy, 2),
            ". Bot bloqueado hasta ma├▒ana.");
   }
   if(bloqueadoHoy) {
      Comment("­ƒøæ L├ìMITE DIARIO $", DoubleToString(MaxPerdidaDiaria_USD, 0),
              " ALCANZADO ┬À Bot bloqueado hasta ma├▒ana.");
      return;
   }

   // ÔöÇÔöÇ M├íx operaciones diarias ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
   if(operacionesHoy >= MaxOperacionesDia) {
      if(MostrarPanel) DibujarPanel();
      return;
   }

   // ÔöÇÔöÇ Gesti├│n BE + Trailing de posiciones abiertas ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
   GestionarPosiciones();

   // ÔöÇÔöÇ Buscar entrada solo al inicio de cada vela ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
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

   // ÔöÇÔöÇ Leer indicadores de la vela cerrada (├¡ndice 1) ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
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

   // ÔöÇÔöÇ Filtro ATR ÔÇö volatilidad m├¡nima en USD REAL ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
   double atrUSD = PrecioAUSD(atrVal);
   if(atrUSD < ATR_Minimo_USD) {
      if(MostrarPanel) DibujarPanel();
      return;
   }

   // ÔöÇÔöÇ SL y TP din├ímicos ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
   double slDist = atrVal * ATR_Multiplicador_SL;
   double tpDist = atrVal * ATR_Multiplicador_TP;

   // Verificar riesgo m├íximo por trade
   double slUSD = PrecioAUSD(slDist);
   if(slUSD > MaxRiesgoPorTrade_USD) return;

   // ÔöÇÔöÇ SE├æALES ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
   // BUY:  EMA r├ípida > EMA lenta + precio > EMA r├ípida + RSI ok
   // EMA200 como contexto: si precio > EMA200 la se├▒al es m├ís fuerte
   // pero NO bloquea ÔÇö permite operar en ambas direcciones
   bool se├▒alBUY  = (emaRap > emaLent) && (bid > emaRap) &&
                    (rsi >= RSI_Compra_Min && rsi <= RSI_Compra_Max);

   bool se├▒alSELL = (emaRap < emaLent) && (bid < emaRap) &&
                    (rsi >= RSI_Venta_Min  && rsi <= RSI_Venta_Max);

   int posiciones = ContarPosiciones();

   // ÔöÇÔöÇ COMPRA ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
   if(se├▒alBUY) {
      // Giro de mercado: cerrar ventas abiertas primero
      if(ExisteTipo(POSITION_TYPE_SELL)) {
         CerrarTodas(POSITION_TYPE_SELL);
         Print("­ƒöä GIRO: Cerrando SELL para abrir BUY");
      }
      if(!ExisteTipo(POSITION_TYPE_BUY) && posiciones < MaxPosiciones) {
         double sl = NormalizeDouble(ask - slDist, _Digits);
         double tp = NormalizeDouble(ask + tpDist, _Digits);
         if(trade.Buy(LoteInicial, _Symbol, ask, sl, tp, "BSR4_BUY")) {
            operacionesHoy++;
            Print("­ƒƒó BUY | Precio: ", ask,
                  " | SL: ", sl, " ($", DoubleToString(slUSD, 2), ")",
                  " | TP: ", tp, " ($", DoubleToString(PrecioAUSD(tpDist), 2), ")",
                  " | EMA200: ", (bid > emaTend ? "a favor" : "en contra"));
         }
      }
   }

   // ÔöÇÔöÇ VENTA ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
   if(se├▒alSELL) {
      // Giro de mercado: cerrar compras abiertas primero
      if(ExisteTipo(POSITION_TYPE_BUY)) {
         CerrarTodas(POSITION_TYPE_BUY);
         Print("­ƒöä GIRO: Cerrando BUY para abrir SELL");
      }
      if(!ExisteTipo(POSITION_TYPE_SELL) && posiciones < MaxPosiciones) {
         double sl = NormalizeDouble(bid + slDist, _Digits);
         double tp = NormalizeDouble(bid - tpDist, _Digits);
         if(trade.Sell(LoteInicial, _Symbol, bid, sl, tp, "BSR4_SELL")) {
            operacionesHoy++;
            Print("­ƒö┤ SELL | Precio: ", bid,
                  " | SL: ", sl, " ($", DoubleToString(slUSD, 2), ")",
                  " | TP: ", tp, " ($", DoubleToString(PrecioAUSD(tpDist), 2), ")",
                  " | EMA200: ", (bid < emaTend ? "a favor" : "en contra"));
         }
      }
   }

   if(MostrarPanel) DibujarPanel();
}

//+------------------------------------------------------------------+
//| BE + TRAILING ÔÇö c├ílculo correcto para BTC (tick value real)       |
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

      // Conversi├│n USD ÔåÆ precio CORRECTA para BTC
      double distBE   = USDaPrecio(BE_Garantia_USD);
      double distTR   = USDaPrecio(Trailing_Distancia_USD);

      // ÔöÇÔöÇ BREAK EVEN ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
      if(ActivarBE && profit >= BE_Activar_USD) {
         if(tipo == POSITION_TYPE_BUY) {
            double newSL = NormalizeDouble(pOpen + distBE, _Digits);
            if(newSL > sl) {
               if(trade.PositionModify(ticket, newSL, tp))
                  Print("­ƒöÆ BE [BUY] | Profit: $", DoubleToString(profit, 2),
                        " | SL ÔåÆ ", newSL);
            }
         }
         else {
            double newSL = NormalizeDouble(pOpen - distBE, _Digits);
            if(sl == 0 || newSL < sl) {
               if(trade.PositionModify(ticket, newSL, tp))
                  Print("­ƒöÆ BE [SELL] | Profit: $", DoubleToString(profit, 2),
                        " | SL ÔåÆ ", newSL);
            }
         }
      }

      // ÔöÇÔöÇ TRAILING STOP ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ
      if(ActivarTrailing && profit >= Trailing_Activar_USD) {
         if(tipo == POSITION_TYPE_BUY) {
            double newSL = NormalizeDouble(bid - distTR, _Digits);
            if(newSL > sl && newSL > pOpen) {
               if(trade.PositionModify(ticket, newSL, tp))
                  Print("­ƒôê TRAILING [BUY] | Profit: $", DoubleToString(profit, 2),
                        " | SL ÔåÆ ", newSL);
            }
         }
         else {
            double newSL = NormalizeDouble(ask + distTR, _Digits);
            if(sl == 0 || (newSL < sl && newSL < pOpen)) {
               if(trade.PositionModify(ticket, newSL, tp))
                  Print("­ƒôê TRAILING [SELL] | Profit: $", DoubleToString(profit, 2),
                        " | SL ÔåÆ ", newSL);
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
//| Existe posici├│n de un tipo                                        |
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
//| Contar operaciones y p├®rdidas del d├¡a                             |
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
//| Filtro de sesi├│n                                                  |
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

   string tend  = (bRap[0] > bLent[0]) ? "­ƒƒó ALCISTA" : "­ƒö┤ BAJISTA";
   string ema200 = (bid > bTend[0]) ? "­ƒƒó Precio > EMA200" : "­ƒö┤ Precio < EMA200";
   string rsiS  = DoubleToString(bRSI[0], 1);
   string atrS  = "$" + DoubleToString(atrUSD, 2) + ((atrUSD >= ATR_Minimo_USD) ? " Ô£à" : " Ôøö Baja");
   string estado = bloqueadoHoy ? "­ƒøæ BLOQUEADO HOY" :
                   (operacionesHoy >= MaxOperacionesDia ? "ÔÜá´©Å M├üX OPS" : "Ô£à OPERATIVO");

   Comment(
      "ÔòöÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòù\n",
      "Ôòæ  ÔÜí BTC STORM RIDER v4.0         Ôòæ\n",
      "Ôòæ       KOPYTRADE.COM              Ôòæ\n",
      "ÔòáÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòú\n",
      "Ôòæ Momentum: ", tend, "\n",
      "Ôòæ ", ema200, "\n",
      "Ôòæ RSI(", RSI_Periodo, "): ", rsiS, "\n",
      "Ôòæ ATR: ", atrS, "\n",
      "Ôòæ Sesi├│n: ", EstaEnSesion() ? "­ƒƒó ACTIVA" : "­ƒö┤ FUERA", "\n",
      "ÔòáÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòú\n",
      "Ôòæ Ops hoy: ", operacionesHoy, "/", MaxOperacionesDia, "\n",
      "Ôòæ P├®rdida hoy: $", DoubleToString(perdidaHoy, 2), "/$", MaxPerdidaDiaria_USD, "\n",
      "Ôòæ Posiciones: ", ContarPosiciones(), "/", MaxPosiciones, "\n",
      "Ôòæ Estado: ", estado, "\n",
      "ÔòÜÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòÉÔòØ"
   );
}
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|          KOPYTRADE_BTCUSD_BTCStormRider v4.5                    |
//|   BUY + SELL | MA + RSI + ATR | FILTRO DE NOTICIAS USD          |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Bot Oficial"
#property version   "4.50"
#property strict
#property description "BTC Storm Rider v4.5 | Filtro Noticias | BE y Trailing USD reales"

#include <Trade\Trade.mqh>

//=== LICENCIA KOPYTRADE ===
input group "=== LICENCIA KOPYTRADE ==="
input long     CuentaDemo         = 0;       // No cuenta DEMO de MT5 (Trial y Compra)
input long     CuentaReal         = 0;       // No cuenta REAL de MT5 (Solo Compra)

//=== SESIONES DE MERCADO ===
input group "=== SESIONES DE MERCADO (HORA BROKER) ==="
input int      SesionEuropa_Inicio  = 0;     // Inicio Sesion Europa
input int      SesionEuropa_Fin     = 16;    // Fin Sesion Europa
input int      SesionUS_Inicio      = 14;    // Inicio Sesion USA
input int      SesionUS_Fin         = 24;    // Fin Sesion USA
input bool     OperarEnAsia         = false; // Operar en sesion Asia?

//=== GESTION DE RIESGO ===
input group "=== GESTION DE RIESGO ==="
input double   LoteInicial           = 0.01;  // Tamano de posicion
input double   MaxRiesgoPorTrade_USD = 3.0;   // Maxima perdida en $ por trade
input double   ATR_Multiplicador_SL  = 1.0;   // Multiplicador ATR para Stop Loss
input double   ATR_Multiplicador_TP  = 2.0;   // Multiplicador ATR para Take Profit

//=== PROTECCION DE CUENTA ===
input group "=== PROTECCION DE CUENTA ==="
input double   MaxPerdidaDiaria_USD  = 20.0;  // Perdida maxima diaria ($)
input int      MaxOperacionesDia     = 50;    // Max operaciones por dia

//=== ESTRATEGIA ===
input group "=== ESTRATEGIA ==="
input int      EMA_Tendencia      = 200;      // EMA de tendencia (referencia)
input int      EMA_Rapida         = 21;       // EMA rapida (momentum)
input int      EMA_Lenta          = 55;       // EMA lenta (confirmacion)
input int      RSI_Periodo        = 14;       // Periodo del RSI
input int      RSI_Compra_Min     = 35;       // RSI minimo para comprar
input int      RSI_Compra_Max     = 60;       // RSI maximo para comprar
input int      RSI_Venta_Min      = 28;       // RSI minimo para vender
input int      RSI_Venta_Max      = 50;       // RSI maximo para vender
input int      ATR_Periodo        = 14;       // Periodo del ATR
input double   ATR_Minimo_USD     = 30.0;     // Volatilidad minima en $ para operar

//=== FILTRO DE NOTICIAS ===
input group "=== FILTRO DE NOTICIAS DE ALTO IMPACTO ==="
input bool     FiltroNoticias       = true;  // Activar filtro de noticias?
input int      MinutosAntes         = 30;    // Minutos antes de noticia para pausar
input int      MinutosDespues       = 30;    // Minutos despues de noticia para reanudar
input bool     CerrarEnPositivoAntesDeNoticia = true; // Cerrar posiciones en positivo antes de noticia

//=== BREAK EVEN ===
input group "=== BREAK EVEN ==="
input bool     ActivarBE          = true;    // Activar Break Even?
input double   BE_Activar_USD     = 2.0;     // Activar BE cuando ganes X$
input double   BE_Garantia_USD    = 1.5;     // Ganancia minima asegurada ($)

//=== TRAILING STOP ===
input group "=== TRAILING STOP ==="
input bool     ActivarTrailing         = true;  // Activar Trailing Stop?
input double   Trailing_Activar_USD    = 2.0;   // Activar cuando ganes X$
input double   Trailing_Distancia_USD  = 2.0;   // Distancia del trailing ($)
input int      Trailing_PuntosMinimos  = 50;    // Puntos minimos para mover trailing

//=== CONFIGURACION AVANZADA ===
input group "=== CONFIGURACION AVANZADA ==="
input int      MaxPosiciones     = 2;         // Max posiciones simultaneas
input int      MinutosEspera     = 20;        // Minutos de espera entre operaciones
input bool     MostrarPanel      = true;      // Mostrar panel visual
input long     MagicNumber       = 780044;    // ID unico del bot

//--- Variables internas ---
CTrade trade;
bool     licenseValid    = false;
int      hEmaTend        = INVALID_HANDLE;
int      hEmaRap         = INVALID_HANDLE;
int      hEmaLent        = INVALID_HANDLE;
int      hRSI            = INVALID_HANDLE;
int      hATR            = INVALID_HANDLE;
datetime ultimaVela      = 0;
datetime ultimaEntrada   = 0;
int      operacionesHoy  = 0;
double   perdidaHoy      = 0;
int      diaActual       = -1;
bool     bloqueadoHoy    = false;
datetime fechaBloqueo    = 0;
bool     noticiaActivaGlobal = false;

//+------------------------------------------------------------------+
//| LICENCIA                                                          |
//+------------------------------------------------------------------+
bool CheckLicense() {
   long cuenta = AccountInfoInteger(ACCOUNT_LOGIN);
   if(cuenta == CuentaDemo || cuenta == CuentaReal) return true;
   if(AccountInfoInteger(ACCOUNT_TRADE_MODE) != ACCOUNT_TRADE_MODE_DEMO) {
      Alert("LICENCIA REQUERIDA PARA CUENTA REAL. Compra en kopytrade.com");
      return false;
   }
   string gVarName = "KOPYTRADE_BSR45_TRIAL_START";
   datetime firstRun;
   if(!GlobalVariableCheck(gVarName)) {
      GlobalVariableSet(gVarName, (double)TimeCurrent());
      firstRun = TimeCurrent();
      Print("BTC STORM RIDER v4.5 - TRIAL INICIADO (30 DIAS)");
   } else {
      firstRun = (datetime)GlobalVariableGet(gVarName);
   }
   int dias = (int)((TimeCurrent() - firstRun) / 86400);
   if(dias <= 30) {
      Comment("BTC STORM RIDER v4.5 TRIAL | Dia " + IntegerToString(dias+1) + "/30 | kopytrade.com");
      return true;
   }
   Alert("TRIAL EXPIRADO. Compra en kopytrade.com");
   return false;
}

//+------------------------------------------------------------------+
//| OnInit                                                            |
//+------------------------------------------------------------------+
int OnInit() {
   if(!CheckLicense()) return INIT_FAILED;

   hEmaTend = iMA(_Symbol, _Period, EMA_Tendencia, 0, MODE_EMA, PRICE_CLOSE);
   hEmaRap  = iMA(_Symbol, _Period, EMA_Rapida,    0, MODE_EMA, PRICE_CLOSE);
   hEmaLent = iMA(_Symbol, _Period, EMA_Lenta,     0, MODE_EMA, PRICE_CLOSE);
   hRSI     = iRSI(_Symbol, _Period, RSI_Periodo,  PRICE_CLOSE);
   hATR     = iATR(_Symbol, _Period, ATR_Periodo);

   if(hEmaTend == INVALID_HANDLE || hEmaRap == INVALID_HANDLE ||
      hEmaLent == INVALID_HANDLE || hRSI    == INVALID_HANDLE ||
      hATR     == INVALID_HANDLE) {
      Alert("Error al crear indicadores. Reinicia el bot.");
      return INIT_FAILED;
   }

   licenseValid = true;
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetTypeFillingBySymbol(_Symbol);

   Print("BTC Storm Rider v4.5 ACTIVADO en ", _Symbol);
   Print("   Filtro de noticias: ", FiltroNoticias ? "ACTIVADO" : "DESACTIVADO");
   Print("   Pausa ", MinutosAntes, " min antes y ", MinutosDespues, " min despues de noticias USD alto impacto");
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
//| FILTRO DE NOTICIAS - Usa el Calendario Economico de MQL5         |
//| Retorna true si hay una noticia de ALTO impacto USD              |
//| en los proximos MinutosAntes o los ultimos MinutosDespues        |
//+------------------------------------------------------------------+
bool HayNoticiaImportante() {
   if(!FiltroNoticias) return false;

   datetime desde = TimeCurrent() - MinutosDespues * 60;
   datetime hasta = TimeCurrent() + MinutosAntes * 60;

   MqlCalendarValue values[];
   // Buscar eventos economicos de USD en la ventana de tiempo
   if(CalendarValueHistory(values, desde, hasta, "USD") > 0) {
      for(int i = 0; i < ArraySize(values); i++) {
         MqlCalendarEvent ev;
         if(CalendarEventById(values[i].event_id, ev)) {
            // Solo bloquear si es ALTO impacto
            if(ev.importance == CALENDAR_IMPORTANCE_HIGH) {
               if(MostrarPanel) {
                  Print("NOTICIA ALTO IMPACTO detectada: ", ev.name,
                        " | Hora: ", TimeToString(values[i].time, TIME_DATE|TIME_MINUTES));
               }
               return true;
            }
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Cerrar posiciones en positivo (antes de noticia)                 |
//+------------------------------------------------------------------+
void CerrarPositivasAntesDeNoticia() {
   if(!CerrarEnPositivoAntesDeNoticia) return;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)     continue;
      double profit = PositionGetDouble(POSITION_PROFIT);
      if(profit > 0) {
         if(trade.PositionClose(ticket)) {
            Print("NOTICIA: Cerrando posicion en +$", DoubleToString(profit, 2),
                  " para proteger ganancia.");
         }
      }
   }
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

   // Reset diario
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(dt.day_of_year != diaActual) {
      diaActual = dt.day_of_year;
      operacionesHoy = 0;
      perdidaHoy = 0;
      if(bloqueadoHoy) {
         MqlDateTime fb;
         TimeToStruct(fechaBloqueo, fb);
         if(dt.day != fb.day || dt.mon != fb.mon)
            bloqueadoHoy = false;
      }
      ContarOperacionesYPerdidasHoy();
   }

   // Limite diario
   if(!bloqueadoHoy && perdidaHoy >= MaxPerdidaDiaria_USD) {
      bloqueadoHoy = true;
      fechaBloqueo = TimeCurrent();
      Print("LIMITE DIARIO alcanzado: $", DoubleToString(perdidaHoy, 2),
            ". Bot bloqueado hasta manana.");
   }
   if(bloqueadoHoy) {
      Comment("LIMITE DIARIO $", DoubleToString(MaxPerdidaDiaria_USD, 0),
              " ALCANZADO. Bot bloqueado hasta manana.");
      return;
   }

   // Max operaciones diarias
   if(operacionesHoy >= MaxOperacionesDia) {
      if(MostrarPanel) DibujarPanel();
      return;
   }

   // === COMPROBACION DE NOTICIAS ===
   noticiaActivaGlobal = HayNoticiaImportante();
   if(noticiaActivaGlobal) {
      // Cerrar posiciones en positivo para asegurar ganancia
      CerrarPositivasAntesDeNoticia();
      // No abrir nuevas posiciones
      if(MostrarPanel) DibujarPanel();
      return;
   }

   // Gestion BE + Trailing de posiciones abiertas
   GestionarPosiciones();

   // Buscar entrada solo al inicio de cada vela
   datetime velaActual = iTime(_Symbol, _Period, 0);
   if(velaActual == ultimaVela) {
      if(MostrarPanel) DibujarPanel();
      return;
   }
   ultimaVela = velaActual;

   // Espera entre operaciones
   if((TimeCurrent() - ultimaEntrada) < MinutosEspera * 60) {
      if(MostrarPanel) DibujarPanel();
      return;
   }

   if(!EstaEnSesion()) {
      if(MostrarPanel) DibujarPanel();
      return;
   }

   // Leer indicadores de la vela cerrada (indice 1)
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

   // Filtro ATR - volatilidad minima en USD REAL
   double atrUSD = PrecioAUSD(atrVal);
   if(atrUSD < ATR_Minimo_USD) {
      if(MostrarPanel) DibujarPanel();
      return;
   }

   // SL y TP dinamicos
   double slDist = atrVal * ATR_Multiplicador_SL;
   double tpDist = atrVal * ATR_Multiplicador_TP;

   // Verificar riesgo maximo por trade
   double slUSD = PrecioAUSD(slDist);
   if(slUSD > MaxRiesgoPorTrade_USD) return;

   // SENALES
   bool senalBUY  = (emaRap > emaLent) && (bid > emaRap) &&
                    (rsi >= RSI_Compra_Min && rsi <= RSI_Compra_Max);

   bool senalSELL = (emaRap < emaLent) && (bid < emaRap) &&
                    (rsi >= RSI_Venta_Min  && rsi <= RSI_Venta_Max);

   int posiciones = ContarPosiciones();

   // COMPRA
   if(senalBUY) {
      if(ExisteTipo(POSITION_TYPE_SELL)) {
         CerrarTodas(POSITION_TYPE_SELL);
         Print("GIRO: Cerrando SELL para abrir BUY");
      }
      if(!ExisteTipo(POSITION_TYPE_BUY) && posiciones < MaxPosiciones) {
         double sl = NormalizeDouble(ask - slDist, _Digits);
         double tp = NormalizeDouble(ask + tpDist, _Digits);
         if(trade.Buy(LoteInicial, _Symbol, ask, sl, tp, "BSR45_BUY")) {
            operacionesHoy++;
            ultimaEntrada = TimeCurrent();
            Print("BUY | Precio: ", ask,
                  " | SL: ", sl, " ($", DoubleToString(slUSD, 2), ")",
                  " | TP: ", tp, " ($", DoubleToString(PrecioAUSD(tpDist), 2), ")",
                  " | EMA200: ", (bid > emaTend ? "a favor" : "en contra"));
         }
      }
   }

   // VENTA
   if(senalSELL) {
      if(ExisteTipo(POSITION_TYPE_BUY)) {
         CerrarTodas(POSITION_TYPE_BUY);
         Print("GIRO: Cerrando BUY para abrir SELL");
      }
      if(!ExisteTipo(POSITION_TYPE_SELL) && posiciones < MaxPosiciones) {
         double sl = NormalizeDouble(bid + slDist, _Digits);
         double tp = NormalizeDouble(bid - tpDist, _Digits);
         if(trade.Sell(LoteInicial, _Symbol, bid, sl, tp, "BSR45_SELL")) {
            operacionesHoy++;
            ultimaEntrada = TimeCurrent();
            Print("SELL | Precio: ", bid,
                  " | SL: ", sl, " ($", DoubleToString(slUSD, 2), ")",
                  " | TP: ", tp, " ($", DoubleToString(PrecioAUSD(tpDist), 2), ")",
                  " | EMA200: ", (bid < emaTend ? "a favor" : "en contra"));
         }
      }
   }

   if(MostrarPanel) DibujarPanel();
}

//+------------------------------------------------------------------+
//| BE + TRAILING                                                     |
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
      double stopLvl = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);

      double distBE = USDaPrecio(BE_Garantia_USD);
      double distTR = USDaPrecio(Trailing_Distancia_USD);

      // BREAK EVEN
      if(ActivarBE && profit >= BE_Activar_USD) {
         if(tipo == POSITION_TYPE_BUY) {
            double newSL = NormalizeDouble(pOpen + distBE, _Digits);
            if(newSL > sl && newSL <= (bid - stopLvl)) {
               if(trade.PositionModify(ticket, newSL, tp))
                  Print("BE [BUY] | Profit: $", DoubleToString(profit, 2), " | SL -> ", newSL);
            }
         }
         else {
            double newSL = NormalizeDouble(pOpen - distBE, _Digits);
            if((sl == 0 || newSL < sl) && newSL >= (ask + stopLvl)) {
               if(trade.PositionModify(ticket, newSL, tp))
                  Print("BE [SELL] | Profit: $", DoubleToString(profit, 2), " | SL -> ", newSL);
            }
         }
      }

      // TRAILING STOP
      if(ActivarTrailing && profit >= Trailing_Activar_USD) {
         if(tipo == POSITION_TYPE_BUY) {
            double newSL = NormalizeDouble(bid - distTR, _Digits);
            double minMove = Trailing_PuntosMinimos * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
            if(newSL > sl && newSL > pOpen && (bid - newSL) <= (distTR + minMove)) {
               if(newSL <= (bid - stopLvl)) {
                  if(trade.PositionModify(ticket, newSL, tp))
                     Print("TRAILING [BUY] | Profit: $", DoubleToString(profit, 2), " | SL -> ", newSL);
               }
            }
         }
         else {
            double newSL = NormalizeDouble(ask + distTR, _Digits);
            double minMove = Trailing_PuntosMinimos * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
            if((sl == 0 || newSL < sl) && newSL < pOpen && (newSL - ask) <= (distTR + minMove)) {
               if(newSL >= (ask + stopLvl)) {
                  if(trade.PositionModify(ticket, newSL, tp))
                     Print("TRAILING [SELL] | Profit: $", DoubleToString(profit, 2), " | SL -> ", newSL);
               }
            }
         }
      }
   }
}

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
//| Panel visual actualizado con estado de noticias                   |
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

   string tend   = (bRap[0] > bLent[0]) ? "ALCISTA" : "BAJISTA";
   string ema200 = (bid > bTend[0]) ? "Precio > EMA200" : "Precio < EMA200";
   string rsiS   = DoubleToString(bRSI[0], 1);
   string atrS   = "$" + DoubleToString(atrUSD, 2) + ((atrUSD >= ATR_Minimo_USD) ? " OK" : " BAJA");
   string estado;

   if(bloqueadoHoy)
      estado = "BLOQUEADO HOY - LIMITE DIARIO";
   else if(noticiaActivaGlobal)
      estado = "PAUSA - NOTICIA ALTO IMPACTO USD";
   else if(operacionesHoy >= MaxOperacionesDia)
      estado = "MAX OPS DIARIAS";
   else
      estado = "OPERATIVO";

   Comment(
      "=========================================\n",
      "   BTC STORM RIDER v4.5 | KOPYTRADE      \n",
      "=========================================\n",
      " Momentum: ", tend, "\n",
      " ", ema200, "\n",
      " RSI(", RSI_Periodo, "): ", rsiS, "\n",
      " ATR: ", atrS, "\n",
      " Sesion: ", EstaEnSesion() ? "ACTIVA" : "FUERA", "\n",
      " Noticias: ", FiltroNoticias ? (noticiaActivaGlobal ? "ALERTA!" : "Vigilando") : "OFF", "\n",
      "-----------------------------------------\n",
      " Ops hoy: ", operacionesHoy, "/", MaxOperacionesDia, "\n",
      " Perdida hoy: $", DoubleToString(perdidaHoy, 2), "/$", MaxPerdidaDiaria_USD, "\n",
      " Posiciones: ", ContarPosiciones(), "/", MaxPosiciones, "\n",
      " Estado: ", estado, "\n",
      "========================================="
   );
}
//+------------------------------------------------------------------+

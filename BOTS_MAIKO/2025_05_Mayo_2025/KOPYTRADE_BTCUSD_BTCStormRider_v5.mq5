
------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|          KOPYTRADE_BTCUSD_BTCStormRider v5.0                    |
//|   PANEL INTERACTIVO | FILTRO NOTICIAS | MODO BUY/SELL/AMBOS     |
//+#property copyright "KOPYTRADING - Bot Oficial"
#property version   "5.00"
#property strict
#property description "BTC Storm Rider v5.0 | Panel Grafico Interactivo | kopytrade.com"

#include <Trade\Trade.mqh>

//============================================================
//  LICENCIA
//============================================================
input group "=== LICENCIA KOPYTRADE ==="
input long   CuentaDemo  = 0;  // No cuenta DEMO de MT5 (Trial y Compra)
input long   CuentaReal  = 0;  // No cuenta REAL de MT5 (Solo Compra)

//============================================================
//  SESIONES
//============================================================
input group "=== SESIONES DE MERCADO (HORA BROKER) ==="
input int    SesionEuropa_Inicio = 0;    // Inicio Sesion Europa
input int    SesionEuropa_Fin   = 16;   // Fin Sesion Europa
input int    SesionUS_Inicio    = 14;   // Inicio Sesion USA
input int    SesionUS_Fin       = 24;   // Fin Sesion USA
input bool   OperarEnAsia       = false;// Operar en sesion Asia?

//============================================================
//  GESTION DE RIESGO
//============================================================
input group "=== GESTION DE RIESGO ==="
input double LoteInicial            = 0.01; // Tamano de posicion
input double MaxRiesgoPorTrade_USD  = 3.0;  // Maxima perdida en $ por trade
input double ATR_Multiplicador_SL   = 1.0;  // Multiplicador ATR para Stop Loss
input double ATR_Multiplicador_TP   = 2.0;  // Multiplicador ATR para Take Profit

//============================================================
//  PROTECCION DE CUENTA (ANTI-RACHA)
//============================================================
input group "=== PROTECCION DE CUENTA (ANTI-RACHA) ==="
input double MaxPerdidaDiaria_USD = 20.0; // Perdida maxima diaria ($)
input int    MaxOperacionesDia    = 50;   // Max operaciones por dia

//============================================================
//  ESTRATEGIA ALINEACION DE TENDENCIA
//============================================================
input group "=== ESTRATEGIA ALINEACION DE TENDENCIA ==="
input int    EMA_Tendencia  = 200; // EMA de tendencia de fondo
input int    EMA_Rapida     = 21;  // EMA rapida (momentum)
input int    EMA_Lenta      = 55;  // EMA lenta (confirmacion)
input int    RSI_Periodo    = 14;  // Periodo del RSI
input int    RSI_Compra_Min = 35;  // RSI minimo para comprar
input int    RSI_Compra_Max = 60;  // RSI maximo para comprar
input int    RSI_Venta_Min  = 28;  // RSI minimo para vender
input int    RSI_Venta_Max  = 50;  // RSI maximo para vender
input int    ATR_Periodo    = 14;  // Periodo del ATR
input double ATR_Minimo_USD = 30.0;// Volatilidad minima para operar (puntos)

//============================================================
//  FILTRO DE NOTICIAS DE ALTO IMPACTO
//============================================================
input group "=== FILTRO DE NOTICIAS DE ALTO IMPACTO ==="
input bool   FiltroNoticias       = true; // Activar filtro de noticias?
input int    MinutosAntes         = 30;   // Minutos antes de noticia para pausar
input int    MinutosDespues       = 30;   // Minutos despues de noticia para reanudar
input bool   CerrarEnPositivo     = true; // Cerrar posiciones en positivo antes de noticia

//============================================================
//  BREAK EVEN
//============================================================
input group "=== BREAK EVEN ==="
input bool   ActivarBE        = true; // Activar Break Even?
input double BE_Activar_USD   = 2.0;  // Activar BE cuando ganes X dolares
input double BE_Garantia_USD  = 1.5;  // Ganancia asegurada tras BE ($)

//============================================================
//  TRAILING STOP
//============================================================
input group "=== TRAILING STOP ==="
input bool   ActivarTrailing          = true; // Activar Trailing Stop?
input double Trailing_Activar_USD     = 2.0;  // Activar trailing cuando ganes X dolares
input double Trailing_Distancia_USD   = 2.0;  // Distancia del trailing en dolares
input int    Puntos_Minimos_Trailing  = 50;   // Puntos minimos para mover trailing

//============================================================
//  CONFIGURACION AVANZADA
//============================================================
input group "=== CONFIGURACION AVANZADA ==="
input int    MaxPosiciones   = 2;       // Max posiciones simultaneas
input int    MinutosEspera   = 20;      // Minutos de espera entre operaciones
input bool   MostrarPanel    = true;    // Mostrar panel visual en el grafico
input long   MagicNumber     = 780044; // ID unico del bot

//============================================================
//  Variables internas
//============================================================
CTrade   trade;
bool     licenseValid        = false;
string   licenseMsg          = "";
int      hEmaTend, hEmaRap, hEmaLent, hRSI, hATR;
datetime ultimaVela          = 0;
datetime ultimaEntrada       = 0;
int      operacionesHoy      = 0;
double   perdidaHoy          = 0;
int      diaActual           = -1;
bool     bloqueadoHoy        = false;
datetime fechaBloqueo        = 0;
bool     noticiaActiva       = false;

// Modo de operacion (controlado por botones del panel)
// 0 = BUY & SELL (ambos)
// 1 = Solo BUY
// 2 = Solo SELL
int      ModoBot             = 0;

// Nombres de objetos del panel
#define PNL "BSR5_"

//============================================================
//  COLORES DEL PANEL
//============================================================
color CLR_BG         = C'12,12,30';     // Fondo principal (azul muy oscuro)
color CLR_HEADER     = C'35,25,75';     // Fondo cabecera (purpura oscuro)
color CLR_BORDER     = C'80,60,160';    // Borde (purpura)
color CLR_SEP        = C'50,50,90';     // Separadores
color CLR_TEXT       = clrWhite;        // Texto principal
color CLR_MUTED      = C'140,140,180';  // Texto secundario
color CLR_SUCCESS    = C'50,210,100';   // Verde exito
color CLR_DANGER     = C'220,60,60';    // Rojo peligro
color CLR_WARN       = C'220,180,50';   // Amarillo aviso
color CLR_BRAND      = C'140,100,230';  // Morado marca
color CLR_BTN_BUY    = C'30,140,60';    // Boton BUY activo
color CLR_BTN_SELL   = C'180,40,40';    // Boton SELL activo
color CLR_BTN_BOTH   = C'50,80,200';    // Boton AMBOS activo
color CLR_BTN_OFF    = C'35,35,65';     // Boton inactivo

//============================================================
//  LICENCIA
//============================================================
bool CheckLicense() {
   long cuenta = AccountInfoInteger(ACCOUNT_LOGIN);
   if(cuenta == CuentaDemo || cuenta == CuentaReal) {
      licenseMsg = "LICENCIA ACTIVA";
      return true;
   }
   if(AccountInfoInteger(ACCOUNT_TRADE_MODE) != ACCOUNT_TRADE_MODE_DEMO) {
      licenseMsg = "SIN LICENCIA";
      Alert("LICENCIA REQUERIDA. Compra en kopytrade.com");
      return false;
   }
   string gVar = "KOPYTRADE_BSR5_TRIAL";
   datetime firstRun;
   if(!GlobalVariableCheck(gVar)) {
      GlobalVariableSet(gVar, (double)TimeCurrent());
      firstRun = TimeCurrent();
   } else {
      firstRun = (datetime)GlobalVariableGet(gVar);
   }
   int dias = (int)((TimeCurrent() - firstRun) / 86400);
   if(dias <= 30) {
      licenseMsg = "TRIAL DIA " + IntegerToString(dias+1) + "/30";
      return true;
   }
   licenseMsg = "TRIAL EXPIRADO";
   Alert("TRIAL EXPIRADO. Compra en kopytrade.com");
   return false;
}

//============================================================
//  INIT
//============================================================
int OnInit() {
   if(!CheckLicense()) return INIT_FAILED;

   hEmaTend = iMA(_Symbol, _Period, EMA_Tendencia, 0, MODE_EMA, PRICE_CLOSE);
   hEmaRap  = iMA(_Symbol, _Period, EMA_Rapida,    0, MODE_EMA, PRICE_CLOSE);
   hEmaLent = iMA(_Symbol, _Period, EMA_Lenta,     0, MODE_EMA, PRICE_CLOSE);
   hRSI     = iRSI(_Symbol, _Period, RSI_Periodo,  PRICE_CLOSE);
   hATR     = iATR(_Symbol, _Period, ATR_Periodo);

   if(hEmaTend==INVALID_HANDLE || hEmaRap==INVALID_HANDLE ||
      hEmaLent==INVALID_HANDLE || hRSI==INVALID_HANDLE || hATR==INVALID_HANDLE) {
      Alert("Error indicadores. Reinicia el bot.");
      return INIT_FAILED;
   }

   licenseValid = true;
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetTypeFillingBySymbol(_Symbol);

   if(MostrarPanel) CrearPanel();

   Print("BTC Storm Rider v5.0 ACTIVADO | Modo: ", ModoBot==0?"AMBOS":ModoBot==1?"SOLO BUY":"SOLO SELL");
   return INIT_SUCCEEDED;
}

//============================================================
//  DEINIT
//============================================================
void OnDeinit(const int reason) {
   if(hEmaTend!=INVALID_HANDLE) IndicatorRelease(hEmaTend);
   if(hEmaRap !=INVALID_HANDLE) IndicatorRelease(hEmaRap);
   if(hEmaLent!=INVALID_HANDLE) IndicatorRelease(hEmaLent);
   if(hRSI    !=INVALID_HANDLE) IndicatorRelease(hRSI);
   if(hATR    !=INVALID_HANDLE) IndicatorRelease(hATR);
   ObjectsDeleteAll(0, PNL);
   Comment("");
}

//============================================================
//  FILTRO NOTICIAS
//============================================================
bool HayNoticiaImportante() {
   if(!FiltroNoticias) return false;
   MqlCalendarValue vals[];
   datetime desde = TimeCurrent() - MinutosDespues * 60;
   datetime hasta = TimeCurrent() + MinutosAntes  * 60;
   if(CalendarValueHistory(vals, desde, hasta, "USD") > 0) {
      for(int i = 0; i < ArraySize(vals); i++) {
         MqlCalendarEvent ev;
         if(CalendarEventById(vals[i].event_id, ev) &&
            ev.importance == CALENDAR_IMPORTANCE_HIGH)
            return true;
      }
   }
   return false;
}

void CerrarPositivasAntesDeNoticia() {
   if(!CerrarEnPositivo) return;
   for(int i = PositionsTotal()-1; i>=0; i--) {
      ulong tkt = PositionGetTicket(i);
      if(!PositionSelectByTicket(tkt)) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)     continue;
      if(PositionGetDouble(POSITION_PROFIT) > 0)
         trade.PositionClose(tkt);
   }
}

//============================================================
//  UTILIDADES
//============================================================
double PrecioAUSD(double dist) {
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(ts <= 0) return 0;
   return (dist/ts)*tv*LoteInicial;
}
double USDaPrecio(double usd) {
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tv<=0||LoteInicial<=0) return 0;
   return (usd*ts)/(tv*LoteInicial);
}
bool EstaEnSesion() {
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   int h = dt.hour;
   if(h>=SesionEuropa_Inicio && h<SesionEuropa_Fin) return true;
   if(h>=SesionUS_Inicio     && h<SesionUS_Fin)     return true;
   if(OperarEnAsia && h>=0   && h<8)                return true;
   return false;
}
int ContarPosiciones() {
   int c=0;
   for(int i=0;i<PositionsTotal();i++) {
      ulong t=PositionGetTicket(i);
      if(PositionSelectByTicket(t) &&
         PositionGetInteger(POSITION_MAGIC)==MagicNumber &&
         PositionGetString(POSITION_SYMBOL)==_Symbol) c++;
   }
   return c;
}
bool ExisteTipo(ENUM_POSITION_TYPE tipo) {
   for(int i=0;i<PositionsTotal();i++) {
      ulong t=PositionGetTicket(i);
      if(PositionSelectByTicket(t) &&
         PositionGetInteger(POSITION_MAGIC)==MagicNumber &&
         PositionGetString(POSITION_SYMBOL)==_Symbol &&
         PositionGetInteger(POSITION_TYPE)==tipo) return true;
   }
   return false;
}
void CerrarTodas(ENUM_POSITION_TYPE tipo) {
   for(int i=PositionsTotal()-1;i>=0;i--) {
      ulong t=PositionGetTicket(i);
      if(!PositionSelectByTicket(t)) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)     continue;
      if(PositionGetInteger(POSITION_TYPE)!=tipo)         continue;
      trade.PositionClose(t);
   }
}
void ContarOperacionesYPerdidasHoy() {
   operacionesHoy=0; perdidaHoy=0;
   datetime hoy = StringToTime(TimeToString(TimeCurrent(),TIME_DATE));
   HistorySelect(hoy, TimeCurrent());
   for(int i=0;i<HistoryDealsTotal();i++) {
      ulong t=HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(t,DEAL_MAGIC)!=MagicNumber) continue;
      if(HistoryDealGetString(t,DEAL_SYMBOL)!=_Symbol)     continue;
      if(HistoryDealGetInteger(t,DEAL_ENTRY)==DEAL_ENTRY_OUT) {
         operacionesHoy++;
         double p=HistoryDealGetDouble(t,DEAL_PROFIT);
         if(p<0) perdidaHoy+=MathAbs(p);
      }
   }
}

//============================================================
//  ONTICK
//============================================================
void OnTick() {
   if(!licenseValid) return;

   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   if(dt.day_of_year != diaActual) {
      diaActual=dt.day_of_year; operacionesHoy=0; perdidaHoy=0;
      if(bloqueadoHoy) {
         MqlDateTime fb; TimeToStruct(fechaBloqueo,fb);
         if(dt.day!=fb.day||dt.mon!=fb.mon) bloqueadoHoy=false;
      }
      ContarOperacionesYPerdidasHoy();
   }

   if(!bloqueadoHoy && perdidaHoy>=MaxPerdidaDiaria_USD) {
      bloqueadoHoy=true; fechaBloqueo=TimeCurrent();
      Print("LIMITE DIARIO: $",DoubleToString(perdidaHoy,2)," Bot bloqueado.");
   }
   if(bloqueadoHoy) { if(MostrarPanel) ActualizarPanel(); return; }
   if(operacionesHoy>=MaxOperacionesDia) { if(MostrarPanel) ActualizarPanel(); return; }

   // NOTICIAS
   noticiaActiva = HayNoticiaImportante();
   if(noticiaActiva) {
      CerrarPositivasAntesDeNoticia();
      if(MostrarPanel) ActualizarPanel();
      return;
   }

   GestionarPosiciones();

   datetime vela = iTime(_Symbol,_Period,0);
   if(vela==ultimaVela) { if(MostrarPanel) ActualizarPanel(); return; }
   ultimaVela=vela;

   if((TimeCurrent()-ultimaEntrada) < MinutosEspera*60) { if(MostrarPanel) ActualizarPanel(); return; }
   if(!EstaEnSesion()) { if(MostrarPanel) ActualizarPanel(); return; }

   double bufT[2],bufR[2],bufL[2],bufS[2],bufA[2];
   ArraySetAsSeries(bufT,true); ArraySetAsSeries(bufR,true);
   ArraySetAsSeries(bufL,true); ArraySetAsSeries(bufS,true);
   ArraySetAsSeries(bufA,true);
   if(CopyBuffer(hEmaTend,0,0,2,bufT)<2) return;
   if(CopyBuffer(hEmaRap, 0,0,2,bufR)<2) return;
   if(CopyBuffer(hEmaLent,0,0,2,bufL)<2) return;
   if(CopyBuffer(hRSI,    0,0,2,bufS)<2) return;
   if(CopyBuffer(hATR,    0,0,2,bufA)<2) return;

   double emaTend=bufT[1], emaRap=bufR[1], emaLent=bufL[1];
   double rsi=bufS[1], atrVal=bufA[1];
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double atrUSD=PrecioAUSD(atrVal);
   if(atrUSD<ATR_Minimo_USD) { if(MostrarPanel) ActualizarPanel(); return; }

   double slDist=atrVal*ATR_Multiplicador_SL;
   double tpDist=atrVal*ATR_Multiplicador_TP;
   double slUSD=PrecioAUSD(slDist);
   if(slUSD>MaxRiesgoPorTrade_USD) return;

   bool senalBUY  = (emaRap>emaLent)&&(bid>emaRap)&&(rsi>=RSI_Compra_Min&&rsi<=RSI_Compra_Max);
   bool senalSELL = (emaRap<emaLent)&&(bid<emaRap)&&(rsi>=RSI_Venta_Min &&rsi<=RSI_Venta_Max);

   // Filtrar segun modo del panel
   if(ModoBot==1) senalSELL=false;  // Solo BUY
   if(ModoBot==2) senalBUY =false;  // Solo SELL

   int pos=ContarPosiciones();

   if(senalBUY) {
      if(ExisteTipo(POSITION_TYPE_SELL)) { CerrarTodas(POSITION_TYPE_SELL); }
      if(!ExisteTipo(POSITION_TYPE_BUY) && pos<MaxPosiciones) {
         double sl=NormalizeDouble(ask-slDist,_Digits);
         double tp=NormalizeDouble(ask+tpDist,_Digits);
         if(trade.Buy(LoteInicial,_Symbol,ask,sl,tp,"BSR5_BUY")) {
            operacionesHoy++; ultimaEntrada=TimeCurrent();
         }
      }
   }
   if(senalSELL) {
      if(ExisteTipo(POSITION_TYPE_BUY)) { CerrarTodas(POSITION_TYPE_BUY); }
      if(!ExisteTipo(POSITION_TYPE_SELL) && pos<MaxPosiciones) {
         double sl=NormalizeDouble(bid+slDist,_Digits);
         double tp=NormalizeDouble(bid-tpDist,_Digits);
         if(trade.Sell(LoteInicial,_Symbol,bid,sl,tp,"BSR5_SELL")) {
            operacionesHoy++; ultimaEntrada=TimeCurrent();
         }
      }
   }
   if(MostrarPanel) ActualizarPanel();
}

//============================================================
//  BE + TRAILING
//============================================================
void GestionarPosiciones() {
   for(int i=PositionsTotal()-1;i>=0;i--) {
      ulong tkt=PositionGetTicket(i);
      if(!PositionSelectByTicket(tkt)) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)     continue;

      double profit=PositionGetDouble(POSITION_PROFIT);
      double pOpen =PositionGetDouble(POSITION_PRICE_OPEN);
      double sl    =PositionGetDouble(POSITION_SL);
      double tp    =PositionGetDouble(POSITION_TP);
      long   tipo  =PositionGetInteger(POSITION_TYPE);
      double bid   =SymbolInfoDouble(_Symbol,SYMBOL_BID);
      double ask   =SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double sLvl  =SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*SymbolInfoDouble(_Symbol,SYMBOL_POINT);
      double distBE=USDaPrecio(BE_Garantia_USD);
      double distTR=USDaPrecio(Trailing_Distancia_USD);

      if(ActivarBE && profit>=BE_Activar_USD) {
         if(tipo==POSITION_TYPE_BUY) {
            double nSL=NormalizeDouble(pOpen+distBE,_Digits);
            if(nSL>sl && nSL<=(bid-sLvl)) trade.PositionModify(tkt,nSL,tp);
         } else {
            double nSL=NormalizeDouble(pOpen-distBE,_Digits);
            if((sl==0||nSL<sl) && nSL>=(ask+sLvl)) trade.PositionModify(tkt,nSL,tp);
         }
      }
      if(ActivarTrailing && profit>=Trailing_Activar_USD) {
         if(tipo==POSITION_TYPE_BUY) {
            double nSL=NormalizeDouble(bid-distTR,_Digits);
            if(nSL>sl && nSL>pOpen && nSL<=(bid-sLvl)) trade.PositionModify(tkt,nSL,tp);
         } else {
            double nSL=NormalizeDouble(ask+distTR,_Digits);
            if((sl==0||nSL<sl) && nSL<pOpen && nSL>=(ask+sLvl)) trade.PositionModify(tkt,nSL,tp);
         }
      }
   }
}

//============================================================
//  PANEL - CREACION INICIAL
//============================================================
void CrLabel(string nm, int x, int y, string txt, color clr, int fs=9, string fn="Segoe UI") {
   ObjectCreate(0,PNL+nm,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,PNL+nm,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,PNL+nm,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,PNL+nm,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetString( 0,PNL+nm,OBJPROP_TEXT,txt);
   ObjectSetString( 0,PNL+nm,OBJPROP_FONT,fn);
   ObjectSetInteger(0,PNL+nm,OBJPROP_FONTSIZE,fs);
   ObjectSetInteger(0,PNL+nm,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,PNL+nm,OBJPROP_SELECTABLE,false);
}
void CrRect(string nm, int x, int y, int w, int h, color bg, color brd, int bw=1) {
   ObjectCreate(0,PNL+nm,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,PNL+nm,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,PNL+nm,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,PNL+nm,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,PNL+nm,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,PNL+nm,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,PNL+nm,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,PNL+nm,OBJPROP_COLOR,brd);
   ObjectSetInteger(0,PNL+nm,OBJPROP_WIDTH,bw);
   ObjectSetInteger(0,PNL+nm,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,PNL+nm,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,PNL+nm,OBJPROP_BACK,false);
}
void CrBtn(string nm, int x, int y, int w, int h, string txt, color bg, color tc) {
   ObjectCreate(0,PNL+nm,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,PNL+nm,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,PNL+nm,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,PNL+nm,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,PNL+nm,OBJPROP_YSIZE,h);
   ObjectSetString( 0,PNL+nm,OBJPROP_TEXT,txt);
   ObjectSetInteger(0,PNL+nm,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,PNL+nm,OBJPROP_COLOR,tc);
   ObjectSetInteger(0,PNL+nm,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetString( 0,PNL+nm,OBJPROP_FONT,"Segoe UI");
   ObjectSetInteger(0,PNL+nm,OBJPROP_FONTSIZE,8);
   ObjectSetInteger(0,PNL+nm,OBJPROP_SELECTABLE,false);
}

void CrearPanel() {
   // Fondo principal
   CrRect("bg",       10, 10, 278, 340, CLR_BG,     CLR_BORDER, 2);
   // Cabecera
   CrRect("hdr",      12, 12, 274, 36,  CLR_HEADER, CLR_BORDER, 1);
   CrLabel("hdr_ttl", 20, 16, "BTC STORM RIDER v5.0", CLR_BRAND, 11, "Segoe UI Bold");

   // Subtitulo
   CrLabel("hdr_sub", 20, 31, "kopytrade.com", CLR_MUTED, 7);

   // Licencia
   CrRect("lic_bg",   12, 50, 274, 22, C'20,20,45', CLR_SEP, 1);
   CrLabel("lic_ico",  20, 54, "LIC:", CLR_MUTED, 8);
   CrLabel("lic_val",  50, 54, licenseMsg, CLR_SUCCESS, 8);
   CrLabel("acc_lbl", 160, 54, "CTA:", CLR_MUTED, 8);
   CrLabel("acc_val", 185, 54, IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)), CLR_TEXT, 8);

   // Separador 1
   CrRect("sep1", 12, 74, 274, 1, CLR_SEP, CLR_SEP);

   // === METRICAS DE MERCADO ===
   CrLabel("mkt_hdr", 20, 78, "MERCADO", CLR_MUTED, 7);

   CrLabel("rsi_lbl",  20, 93, "RSI:", CLR_MUTED, 8);
   CrLabel("rsi_val",  55, 93, "---",  CLR_TEXT,  9);

   CrLabel("atr_lbl", 130, 93, "ATR $:", CLR_MUTED, 8);
   CrLabel("atr_val", 175, 93, "---",    CLR_TEXT,  9);

   CrLabel("tnd_lbl",  20, 110, "Tendencia:", CLR_MUTED, 8);
   CrLabel("tnd_val", 100, 110, "---",        CLR_TEXT,  9);

   CrLabel("ses_lbl", 20, 126, "Sesion:", CLR_MUTED, 8);
   CrLabel("ses_val", 80, 126, "---",     CLR_TEXT,  9);

   CrLabel("nws_lbl", 150, 126, "Noticias:", CLR_MUTED, 8);
   CrLabel("nws_val", 215, 126, "---",       CLR_TEXT,  9);

   // Separador 2
   CrRect("sep2", 12, 144, 274, 1, CLR_SEP, CLR_SEP);

   // === ESTADISTICAS DEL DIA ===
   CrLabel("day_hdr", 20, 148, "HOY", CLR_MUTED, 7);

   CrLabel("ops_lbl",  20, 163, "Operaciones:", CLR_MUTED, 8);
   CrLabel("ops_val", 115, 163, "---",          CLR_TEXT,  9);

   CrLabel("prd_lbl",  20, 179, "Perdida:", CLR_MUTED, 8);
   CrLabel("prd_val",  90, 179, "---",      CLR_TEXT,  9);

   CrLabel("pos_lbl", 160, 163, "Posiciones:", CLR_MUTED, 8);
   CrLabel("pos_val", 240, 163, "---",         CLR_TEXT,  9);

   CrLabel("bal_lbl",  20, 195, "Balance:", CLR_MUTED, 8);
   CrLabel("bal_val",  90, 195, "---",      CLR_TEXT,  9);

   // Separador 3
   CrRect("sep3", 12, 212, 274, 1, CLR_SEP, CLR_SEP);

   // === BOTONES MODO ===
   CrLabel("mode_hdr", 20, 216, "MODO DE OPERACION", CLR_MUTED, 7);
   // Boton SOLO SELL (izq)
   CrBtn("btn_sell", 15,  231, 82, 26, "SOLO SELL", CLR_BTN_SELL, clrWhite);
   // Boton BUY & SELL (centro, activo por defecto)
   CrBtn("btn_both", 103, 231, 82, 26, "BUY & SELL", CLR_BTN_BOTH, clrWhite);
   // Boton SOLO BUY (der)
   CrBtn("btn_buy",  191, 231, 82, 26, "SOLO BUY",  CLR_BTN_BUY,  clrWhite);

   // Separador 4
   CrRect("sep4", 12, 262, 274, 1, CLR_SEP, CLR_SEP);

   // === ESTADO ===
   CrRect("sta_bg",  12, 264, 274, 30, C'15,15,40', CLR_SEP, 1);
   CrLabel("sta_ico", 20, 268, "ESTADO:", CLR_MUTED, 8);
   CrLabel("sta_val", 75, 268, "CARGANDO...", CLR_WARN, 9, "Segoe UI Bold");

   // Pie de pagina
   CrLabel("ftr", 67, 298, "kopytrade.com  |  Bot v5.0", CLR_MUTED, 7);

   ChartRedraw(0);
}

//============================================================
//  PANEL - ACTUALIZACION
//============================================================
void ActualizarPanel() {
   // Leer indicadores
   double bR[1],bL[1],bS[1],bA[1],bT[1];
   ArraySetAsSeries(bR,true); ArraySetAsSeries(bL,true);
   ArraySetAsSeries(bS,true); ArraySetAsSeries(bA,true);
   ArraySetAsSeries(bT,true);
   CopyBuffer(hEmaRap, 0,0,1,bR);
   CopyBuffer(hEmaLent,0,0,1,bL);
   CopyBuffer(hRSI,    0,0,1,bS);
   CopyBuffer(hATR,    0,0,1,bA);
   CopyBuffer(hEmaTend,0,0,1,bT);

   double bid    = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double rsi    = bS[0];
   double atrUSD = PrecioAUSD(bA[0]);
   bool   trend  = (bR[0]>bL[0]);
   bool   sesion = EstaEnSesion();
   double bal    = AccountInfoDouble(ACCOUNT_BALANCE);

   // RSI con color
   color rsiClr = CLR_TEXT;
   if(rsi<35 || rsi>65) rsiClr = CLR_WARN;
   if(rsi<28 || rsi>72) rsiClr = CLR_DANGER;
   ObjectSetString( 0,PNL+"rsi_val",OBJPROP_TEXT, DoubleToString(rsi,1));
   ObjectSetInteger(0,PNL+"rsi_val",OBJPROP_COLOR, rsiClr);

   // ATR
   color atrClr = (atrUSD>=ATR_Minimo_USD) ? CLR_SUCCESS : CLR_DANGER;
   ObjectSetString( 0,PNL+"atr_val",OBJPROP_TEXT, "$"+DoubleToString(atrUSD,0));
   ObjectSetInteger(0,PNL+"atr_val",OBJPROP_COLOR, atrClr);

   // Tendencia
   ObjectSetString( 0,PNL+"tnd_val",OBJPROP_TEXT, trend ? "ALCISTA" : "BAJISTA");
   ObjectSetInteger(0,PNL+"tnd_val",OBJPROP_COLOR, trend ? CLR_SUCCESS : CLR_DANGER);

   // Sesion
   ObjectSetString( 0,PNL+"ses_val",OBJPROP_TEXT, sesion ? "ACTIVA" : "FUERA");
   ObjectSetInteger(0,PNL+"ses_val",OBJPROP_COLOR, sesion ? CLR_SUCCESS : CLR_MUTED);

   // Noticias
   if(!FiltroNoticias) {
      ObjectSetString(0,PNL+"nws_val",OBJPROP_TEXT,"OFF");
      ObjectSetInteger(0,PNL+"nws_val",OBJPROP_COLOR,CLR_MUTED);
   } else if(noticiaActiva) {
      ObjectSetString(0,PNL+"nws_val",OBJPROP_TEXT,"ALERTA!");
      ObjectSetInteger(0,PNL+"nws_val",OBJPROP_COLOR,CLR_DANGER);
   } else {
      ObjectSetString(0,PNL+"nws_val",OBJPROP_TEXT,"OK");
      ObjectSetInteger(0,PNL+"nws_val",OBJPROP_COLOR,CLR_SUCCESS);
   }

   // Stats
   ObjectSetString(0,PNL+"ops_val",OBJPROP_TEXT, IntegerToString(operacionesHoy)+"/"+IntegerToString(MaxOperacionesDia));
   ObjectSetString(0,PNL+"pos_val",OBJPROP_TEXT, IntegerToString(ContarPosiciones())+"/"+IntegerToString(MaxPosiciones));

   color prdClr = (perdidaHoy < MaxPerdidaDiaria_USD*0.5) ? CLR_SUCCESS :
                  (perdidaHoy < MaxPerdidaDiaria_USD*0.8) ? CLR_WARN : CLR_DANGER;
   ObjectSetString( 0,PNL+"prd_val",OBJPROP_TEXT, "$"+DoubleToString(perdidaHoy,2)+"/$"+DoubleToString(MaxPerdidaDiaria_USD,0));
   ObjectSetInteger(0,PNL+"prd_val",OBJPROP_COLOR, prdClr);

   ObjectSetString(0,PNL+"bal_val",OBJPROP_TEXT, "$"+DoubleToString(bal,2));

   // Botones: resaltar activo
   ObjectSetInteger(0,PNL+"btn_sell",OBJPROP_BGCOLOR, ModoBot==2 ? CLR_BTN_SELL  : CLR_BTN_OFF);
   ObjectSetInteger(0,PNL+"btn_both",OBJPROP_BGCOLOR, ModoBot==0 ? CLR_BTN_BOTH  : CLR_BTN_OFF);
   ObjectSetInteger(0,PNL+"btn_buy", OBJPROP_BGCOLOR, ModoBot==1 ? CLR_BTN_BUY   : CLR_BTN_OFF);

   // Estado principal
   string staTxt; color staClr;
   if(bloqueadoHoy)     { staTxt="BLOQUEADO - LIMITE DIARIO"; staClr=CLR_DANGER; }
   else if(noticiaActiva){ staTxt="PAUSA - NOTICIA USD";       staClr=CLR_WARN;  }
   else if(!sesion)      { staTxt="FUERA DE SESION";           staClr=CLR_MUTED; }
   else if(operacionesHoy>=MaxOperacionesDia){ staTxt="MAX OPERACIONES HOY"; staClr=CLR_WARN; }
   else                  { staTxt="OPERATIVO";                 staClr=CLR_SUCCESS;}

   ObjectSetString( 0,PNL+"sta_val",OBJPROP_TEXT, staTxt);
   ObjectSetInteger(0,PNL+"sta_val",OBJPROP_COLOR, staClr);

   // Licencia
   ObjectSetString(0,PNL+"lic_val",OBJPROP_TEXT, licenseMsg);
   ObjectSetInteger(0,PNL+"lic_val",OBJPROP_COLOR,
      StringFind(licenseMsg,"TRIAL")>=0 ? CLR_WARN :
      StringFind(licenseMsg,"SIN")>=0   ? CLR_DANGER : CLR_SUCCESS);

   ChartRedraw(0);
}

//============================================================
//  EVENTOS DEL PANEL (clicks en botones)
//============================================================
void OnChartEvent(const int id, const long &lp, const double &dp, const string &sp) {
   if(id != CHARTEVENT_OBJECT_CLICK) return;

   if(sp == PNL+"btn_buy") {
      ModoBot = 1;
      Print("Modo cambiado a: SOLO BUY");
   }
   else if(sp == PNL+"btn_sell") {
      ModoBot = 2;
      Print("Modo cambiado a: SOLO SELL");
   }
   else if(sp == PNL+"btn_both") {
      ModoBot = 0;
      Print("Modo cambiado a: BUY & SELL (Ambos)");
   }

   // Desmarcar el boton (que no quede "presionado" en MT5)
   ObjectSetInteger(0, sp, OBJPROP_STATE, false);
   if(MostrarPanel) ActualizarPanel();
}
//+------------------------------------------------------------------+

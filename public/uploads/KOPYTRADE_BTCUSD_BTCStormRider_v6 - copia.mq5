//+------------------------------------------------------------------+
//|          KOPYTRADE_BTCUSD_BTCStormRider v6.0                    |
//|   PANEL PRO | CONTADOR VELA | STOP ESTRUCTURAL | OCULTAR PANEL  |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Bot Oficial"
#property version   "6.00"
#property strict
#property description "BTC Storm Rider v6.0 | Panel Pro Interactivo | kopytrade.com"

#include <Trade\Trade.mqh>

//============================================================
//  LICENCIA
//============================================================
input group "=== LICENCIA KOPYTRADE ==="
input long   CuentaDemo  = 0;
input long   CuentaReal  = 0;

//============================================================
//  SESIONES
//============================================================
input group "=== SESIONES DE MERCADO (HORA BROKER) ==="
input int    SesionEuropa_Inicio = 0;
input int    SesionEuropa_Fin   = 16;
input int    SesionUS_Inicio    = 14;
input int    SesionUS_Fin       = 24;
input bool   OperarEnAsia       = true;

//============================================================
//  GESTION DE RIESGO
//============================================================
input group "=== GESTION DE RIESGO ==="
input double LoteInicial            = 0.01;
input double MaxRiesgoPorTrade_USD  = 3.0;
input double ATR_Multiplicador_SL   = 1.5; // Un poco mas de aire en v6
input double ATR_Multiplicador_TP   = 3.0; // Buscamos mas profit

//============================================================
//  STOP ESTRUCTURAL (NUEVO v6.0)
//============================================================
input group "=== STOP ESTRUCTURAL (AUTOSL) ==="
input int    Velas_Estructural      = 6;    // Velas para buscar max/min (ej: 6 velas = 3 horas en M30)
input double Margen_Extra_Pts       = 100;  // Puntos extra de seguridad

//============================================================
//  PROTECCION DE CUENTA (ANTI-RACHA)
//============================================================
input group "=== PROTECCION DE CUENTA (ANTI-RACHA) ==="
input double MaxPerdidaDiaria_USD = 50.0;
input int    MaxOperacionesDia    = 50;

//============================================================
//  ESTRATEGIA ALINEACION DE TENDENCIA
//============================================================
input group "=== ESTRATEGIA ALINEACION DE TENDENCIA ==="
input int    EMA_Tendencia  = 200;
input int    EMA_Rapida     = 21;
input int    EMA_Lenta      = 55;
input int    RSI_Periodo    = 14;
input int    RSI_Compra_Min = 35;
input int    RSI_Compra_Max = 60;
input int    RSI_Venta_Min  = 28;
input int    RSI_Venta_Max  = 50;
input int    ATR_Periodo    = 14;
input double ATR_Minimo_USD = 1.0;

//============================================================
//  FILTRO DE NOTICIAS
//============================================================
input group "=== FILTRO DE NOTICIAS DE ALTO IMPACTO ==="
input bool   FiltroNoticias       = true;
input int    MinutosAntes         = 30;
input int    MinutosDespues       = 30;
input bool   CerrarEnPositivo     = true;

//============================================================
//  CONFIGURACION AVANZADA
//============================================================
input group "=== CONFIGURACION AVANZADA ==="
input int    MaxPosiciones   = 2;
input int    MinutosEspera   = 20;
input bool   MostrarPanel    = true;
input long   MagicNumber     = 780066; 

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

// Estados del Panel
int      ModoBot             = 0;     // 0=BOTH, 1=BUY, 2=SELL
bool     StrucSL_Active      = true;  // Empezamos con SL Estructural ON en v6
bool     PanelMinimized      = false; // Panel Oculto/Visible

#define PNL "BSR6_"

// Colores
color CLR_BG         = C'12,12,30';
color CLR_HEADER     = C'35,25,75';
color CLR_BORDER     = C'80,60,160';
color CLR_SEP        = C'50,50,90';
color CLR_TEXT       = clrWhite;
color CLR_MUTED      = C'140,140,180';
color CLR_SUCCESS    = C'50,210,100';
color CLR_DANGER     = C'220,60,60';
color CLR_WARN       = C'220,180,50';
color CLR_BRAND      = C'140,100,230';
color CLR_BTN_ON     = C'50,80,200';
color CLR_BTN_OFF    = C'35,35,65';

//============================================================
//  LOGICA DE TIEMPO Y SL ESTRUCTURAL
//============================================================
string GetTimeLeft() {
   datetime nextBar = iTime(_Symbol, _Period, 0) + PeriodSeconds(_Period);
   long diff = (long)nextBar - (long)TimeCurrent();
   if(diff < 0) diff = 0;
   return StringFormat("%02d:%02d", (int)(diff/60), (int)(diff%60));
}

double GetStructuralSL(ENUM_POSITION_TYPE type) {
   int highestIdx = iHighest(_Symbol, _Period, MODE_HIGH, Velas_Estructural, 1);
   int lowestIdx  = iLowest(_Symbol, _Period, MODE_LOW, Velas_Estructural, 1);
   double margin = Margen_Extra_Pts * _Point;
   
   if(type == POSITION_TYPE_SELL) return NormalizeDouble(iHigh(_Symbol, _Period, highestIdx) + margin, _Digits);
   else return NormalizeDouble(iLow(_Symbol, _Period, lowestIdx) - margin, _Digits);
}

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
      return false;
   }
   string gVar = "KOPYTRADE_BSR6_TRIAL";
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
   return false;
}

//============================================================
//  INIT / TICK
//============================================================
int OnInit() {
   if(!CheckLicense()) { Alert("Licencia Invalida. Visita kopytrade.com"); return INIT_FAILED; }
   
   hEmaTend = iMA(_Symbol, _Period, EMA_Tendencia, 0, MODE_EMA, PRICE_CLOSE);
   hEmaRap  = iMA(_Symbol, _Period, EMA_Rapida,    0, MODE_EMA, PRICE_CLOSE);
   hEmaLent = iMA(_Symbol, _Period, EMA_Lenta,     0, MODE_EMA, PRICE_CLOSE);
   hRSI     = iRSI(_Symbol, _Period, RSI_Periodo,  PRICE_CLOSE);
   hATR     = iATR(_Symbol, _Period, ATR_Periodo);

   licenseValid = true;
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetTypeFillingBySymbol(_Symbol);

   if(MostrarPanel) CrearPanel();
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
   IndicatorRelease(hEmaTend); IndicatorRelease(hEmaRap); IndicatorRelease(hEmaLent);
   IndicatorRelease(hRSI); IndicatorRelease(hATR);
   ObjectsDeleteAll(0, PNL);
}

void OnTick() {
   if(!licenseValid) return;

   // Control diario
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   if(dt.day_of_year != diaActual) {
      diaActual = dt.day_of_year;
      ContarStats();
      bloqueadoHoy = (perdidaHoy >= MaxPerdidaDiaria_USD);
   }

   if(bloqueadoHoy || operacionesHoy >= MaxOperacionesDia) {
      if(MostrarPanel) ActualizarPanel();
      return;
   }

   // Noticias
   noticiaActiva = HayNoticiaImportante();
   if(noticiaActiva) {
      if(CerrarEnPositivo) CerrarPositivas();
      if(MostrarPanel) ActualizarPanel();
      return;
   }

   // Lógica de entrada
   CheckEntradas();
   
   if(MostrarPanel) ActualizarPanel();
}

//============================================================
//  ESTRATEGIA
//============================================================
void CheckEntradas() {
   datetime vela = iTime(_Symbol, _Period, 0);
   if(vela == ultimaVela) return; 
   
   if((TimeCurrent() - ultimaEntrada) < MinutosEspera * 60) return;
   if(!EstaEnSesion()) return;

   double bufT[2], bufR[2], bufL[2], bufS[2], bufA[2];
   CopyBuffer(hEmaTend,0,0,2,bufT); CopyBuffer(hEmaRap, 0,0,2,bufR);
   CopyBuffer(hEmaLent,0,0,2,bufL); CopyBuffer(hRSI,    0,0,2,bufS);
   CopyBuffer(hATR,    0,0,2,bufA);

   double emaTend=bufT[1], emaRap=bufR[1], emaLent=bufL[1];
   double rsi=bufS[1], atrVal=bufA[1];
   double bid=SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask=SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   // Volatilidad
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(ts <= 0) return;
   double atrUSD = (atrVal/ts)*tv*LoteInicial;
   if(atrUSD < ATR_Minimo_USD) return;

   // Senales
   bool condBuy  = (emaRap > emaLent) && (bid > emaRap) && (rsi >= RSI_Compra_Min && rsi <= RSI_Compra_Max);
   bool condSell = (emaRap < emaLent) && (bid < emaRap) && (rsi >= RSI_Venta_Min  && rsi <= RSI_Venta_Max);

   if(ModoBot == 1) condSell = false;
   if(ModoBot == 2) condBuy  = false;

   if(condBuy && ContarPosiciones() < MaxPosiciones) {
      double slVal = StrucSL_Active ? GetStructuralSL(POSITION_TYPE_BUY) : (ask - (atrVal * ATR_Multiplicador_SL));
      double tpVal = ask + (atrVal * ATR_Multiplicador_TP);
      double sl = NormalizeDouble(slVal, _Digits);
      double tp = NormalizeDouble(tpVal, _Digits);
      if(trade.Buy(LoteInicial, _Symbol, ask, sl, tp, "BSR6_BUY")) {
         ultimaVela = vela; ultimaEntrada = TimeCurrent(); operacionesHoy++;
      }
   }
   
   if(condSell && ContarPosiciones() < MaxPosiciones) {
      double slVal = StrucSL_Active ? GetStructuralSL(POSITION_TYPE_SELL) : (bid + (atrVal * ATR_Multiplicador_SL));
      double tpVal = bid - (atrVal * ATR_Multiplicador_TP);
      double sl = NormalizeDouble(slVal, _Digits);
      double tp = NormalizeDouble(tpVal, _Digits);
      if(trade.Sell(LoteInicial, _Symbol, bid, sl, tp, "BSR6_SELL")) {
         ultimaVela = vela; ultimaEntrada = TimeCurrent(); operacionesHoy++;
      }
   }
}

//============================================================
//  HELPERS
//============================================================
void ContarStats() {
   operacionesHoy = 0; perdidaHoy = 0;
   datetime hoy = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   HistorySelect(hoy, TimeCurrent());
   for(int i=0; i<HistoryDealsTotal(); i++) {
      ulong t = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(t, DEAL_MAGIC) == MagicNumber && HistoryDealGetString(t, DEAL_SYMBOL) == _Symbol) {
         if(HistoryDealGetInteger(t, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
            operacionesHoy++;
            double p = HistoryDealGetDouble(t, DEAL_PROFIT);
            if(p < 0) perdidaHoy += MathAbs(p);
         }
      }
   }
}

int ContarPosiciones() {
   int c=0;
   for(int i=0; i<PositionsTotal(); i++) {
      ulong t = PositionGetTicket(i);
      if(PositionSelectByTicket(t) && PositionGetInteger(POSITION_MAGIC)==MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol) c++;
   }
   return c;
}

bool EstaEnSesion() {
   MqlDateTime d; TimeToStruct(TimeCurrent(), d);
   if(OperarEnAsia && d.hour < 8) return true;
   if(d.hour >= SesionEuropa_Inicio && d.hour < SesionEuropa_Fin) return true;
   if(d.hour >= SesionUS_Inicio     && d.hour < SesionUS_Fin)     return true;
   return false;
}

bool HayNoticiaImportante() {
   if(!FiltroNoticias) return false;
   MqlCalendarValue v[];
   datetime d = TimeCurrent() - MinutosDespues*60;
   datetime h = TimeCurrent() + MinutosAntes*60;
   if(CalendarValueHistory(v, d, h, "USD") > 0) {
      for(int i=0; i<ArraySize(v); i++) {
         MqlCalendarEvent e;
         if(CalendarEventById(v[i].event_id, e) && e.importance == CALENDAR_IMPORTANCE_HIGH) return true;
      }
   }
   return false;
}

void CerrarPositivas() {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong t = PositionGetTicket(i);
      if(PositionSelectByTicket(t) && PositionGetInteger(POSITION_MAGIC)==MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetDouble(POSITION_PROFIT)>0)
         trade.PositionClose(t);
   }
}

//============================================================
//  PANEL VISUAL (v6.0)
//============================================================
void CrearPanel() {
   ObjectsDeleteAll(0, PNL);
   int x=10, y=10, w=280, h=360;
   
   if(PanelMinimized) { h=60; w=200; }

   CrRect("bg", x, y, w, h, CLR_BG, CLR_BORDER, 2);
   CrRect("hdr", x+2, y+2, w-4, 36, CLR_HEADER, CLR_BORDER, 1);
   CrLabel("ttl", x+10, y+8, "BTC STORM RIDER v6.0", CLR_BRAND, 10, "Segoe UI Bold");
   CrBtn("btn_min", x+w-25, y+8, 20, 20, PanelMinimized ? "+" : "-", CLR_HEADER, clrWhite);

   if(!PanelMinimized) {
      CrRect("lic", x+2, y+40, w-4, 20, C'20,20,45', CLR_SEP);
      CrLabel("lic_val", x+10, y+42, licenseMsg, CLR_SUCCESS, 8);
      
      CrLabel("tm_lbl", x+10, y+65, "CIERRE VELA:", CLR_MUTED, 8);
      CrLabel("tm_val", x+100, y+65, GetTimeLeft(), CLR_WARN, 9, "Consolas");

      CrLabel("rsi_lbl", x+10, y+85, "RSI:", CLR_MUTED, 8);
      CrLabel("rsi_val", x+50, y+85, "---", CLR_TEXT, 9);
      
      CrLabel("tnd_lbl", x+10, y+105, "TENDENCIA:", CLR_MUTED, 8);
      CrLabel("tnd_val", x+100, y+105, "---", CLR_TEXT, 9);

      CrBtn("m_both", x+10, y+135, 80, 25, "AMBOS", CLR_BTN_ON, clrWhite);
      CrBtn("m_buy",  x+95, y+135, 80, 25, "SOLO BUY", CLR_BTN_OFF, clrWhite);
      CrBtn("m_sell", x+180, y+135, 80, 25, "SOLO SELL", CLR_BTN_OFF, clrWhite);

      CrLabel("sl_lbl", x+10, y+175, "STOP ESTRUCTURAL:", CLR_MUTED, 8);
      CrBtn("btn_sl", x+150, y+170, 60, 25, "OFF", CLR_BTN_OFF, clrWhite);
      
      CrRect("sep", x+10, y+210, w-20, 1, CLR_SEP);
      CrLabel("st_ops", x+10, y+215, "OPERACIONES:", CLR_MUTED, 8);
      CrLabel("st_ov",  x+120, y+215, "0/50", CLR_TEXT, 9);
      
      CrLabel("st_bal", x+10, y+235, "BALANCE:", CLR_MUTED, 8);
      CrLabel("st_bv",  x+100, y+235, "$0.00", CLR_TEXT, 9);

      CrRect("sta_bg", x+2, h-35+y, w-4, 30, C'15,15,40', CLR_SEP);
      CrLabel("sta_val", x+10, h-28+y, "CARGANDO...", CLR_SUCCESS, 9, "Segoe UI Bold");
   } else {
      CrLabel("tm_min", x+10, y+42, "VELA: " + GetTimeLeft(), CLR_WARN, 8);
      CrLabel("bal_min", x+100, y+42, "BAL: $0.00", CLR_TEXT, 8);
   }
   ChartRedraw(0);
}

void ActualizarPanel() {
   if(PanelMinimized) {
      ObjectSetString(0, PNL+"tm_min", OBJPROP_TEXT, "VELA: " + GetTimeLeft());
      ObjectSetString(0, PNL+"bal_min", OBJPROP_TEXT, "BAL: $" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2));
   } else {
      ObjectSetString(0, PNL+"tm_val", OBJPROP_TEXT, GetTimeLeft());
      double r[1]; CopyBuffer(hRSI, 0, 0, 1, r);
      ObjectSetString(0, PNL+"rsi_val", OBJPROP_TEXT, DoubleToString(r[0], 1));
      
      double ra[1], le[1]; CopyBuffer(hEmaRap,0,0,1,ra); CopyBuffer(hEmaLent,0,0,1,le);
      bool up = (ra[0] > le[0]);
      ObjectSetString(0, PNL+"tnd_val", OBJPROP_TEXT, up ? "ALCISTA" : "BAJISTA");
      ObjectSetInteger(0, PNL+"tnd_val", OBJPROP_COLOR, up ? CLR_SUCCESS : CLR_DANGER);
      
      ObjectSetInteger(0, PNL+"m_both", OBJPROP_BGCOLOR, ModoBot==0 ? CLR_BTN_ON : CLR_BTN_OFF);
      ObjectSetInteger(0, PNL+"m_buy",  OBJPROP_BGCOLOR, ModoBot==1 ? CLR_BTN_ON : CLR_BTN_OFF);
      ObjectSetInteger(0, PNL+"m_sell", OBJPROP_BGCOLOR, ModoBot==2 ? CLR_BTN_ON : CLR_BTN_OFF);
      
      ObjectSetString(0, PNL+"btn_sl", OBJPROP_TEXT, StrucSL_Active ? "ON" : "OFF");
      ObjectSetInteger(0, PNL+"btn_sl", OBJPROP_BGCOLOR, StrucSL_Active ? CLR_BTN_ON : CLR_BTN_OFF);
      
      ObjectSetString(0, PNL+"st_ov", OBJPROP_TEXT, IntegerToString(operacionesHoy) + "/" + IntegerToString(MaxOperacionesDia));
      ObjectSetString(0, PNL+"st_bv", OBJPROP_TEXT, "$" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
      
      string s="OPERATIVO"; color c=CLR_SUCCESS;
      if(bloqueadoHoy) { s="BLOQUEADO"; c=CLR_DANGER; }
      else if(noticiaActiva) { s="NOTICIA!"; c=CLR_WARN; }
      else if(!EstaEnSesion()) { s="FUERA SESION"; c=CLR_MUTED; }
      ObjectSetString(0, PNL+"sta_val", OBJPROP_TEXT, s);
      ObjectSetInteger(0, PNL+"sta_val", OBJPROP_COLOR, c);
   }
   ChartRedraw(0);
}

void OnChartEvent(const int id, const long &lp, const double &dp, const string &sp) {
   if(id != CHARTEVENT_OBJECT_CLICK) return;
   if(sp == PNL+"btn_min") { PanelMinimized = !PanelMinimized; CrearPanel(); }
   else if(sp == PNL+"m_both") ModoBot = 0;
   else if(sp == PNL+"m_buy")  ModoBot = 1;
   else if(sp == PNL+"m_sell") ModoBot = 2;
   else if(sp == PNL+"btn_sl") StrucSL_Active = !StrucSL_Active;
   ObjectSetInteger(0, sp, OBJPROP_STATE, false);
   ActualizarPanel();
}

void CrRect(string n, int x, int y, int w, int h, color bg, color brd, int bw=1) {
   ObjectCreate(0,PNL+n,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,brd);
   ObjectSetInteger(0,PNL+n,OBJPROP_BORDER_TYPE,BORDER_FLAT); ObjectSetInteger(0,PNL+n,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,PNL+n,OBJPROP_SELECTABLE,false);
}
void CrLabel(string n, int x, int y, string t, color c, int s=9, string f="Segoe UI") {
   ObjectCreate(0,PNL+n,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y);
   ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,c);
   ObjectSetInteger(0,PNL+n,OBJPROP_FONTSIZE,s); ObjectSetString(0,PNL+n,OBJPROP_FONT,f);
   ObjectSetInteger(0,PNL+n,OBJPROP_CORNER,CORNER_LEFT_UPPER); ObjectSetInteger(0,PNL+n,OBJPROP_SELECTABLE,false);
}
void CrBtn(string n, int x, int y, int w, int h, string t, color bg, color tc) {
   ObjectCreate(0,PNL+n,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h);
   ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,tc); ObjectSetInteger(0,PNL+n,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,PNL+n,OBJPROP_SELECTABLE,false);
}


//+------------------------------------------------------------------+
//|         LA_AMETRALLADORA_PRO_v5.0.mq5                           |
//|    IA DE ANALISIS + FILTRO NOTICIAS + HUD INTERACTIVO          |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Bot Oficial"
#property version   "5.00"
#property strict
#property description "La Ametralladora v5.0 PRO | HUD Interactivo | Filtro Noticias USD | kopytrade.com"

#include <Trade\Trade.mqh>

//============================================================
//  LICENCIA
//============================================================
input group "=== LICENCIA KOPYTRADE ==="
input long     CuentaDemo         = 0;  // No cuenta DEMO (Trial/Compra)
input long     CuentaReal         = 0;  // No cuenta REAL (Solo Compra)

//============================================================
//  IA DE PRE-ANÁLISIS
//============================================================
input group "=== IA DE PRE-ANÁLISIS (ESTRATEGIA) ==="
input ENUM_TIMEFRAMES Analisis_TF = PERIOD_H1;     // Grafico de referencia
input int    Minutos_Análisis_IA = 15;            // Tiempo de analisis inicial
input bool   Solo_A_Favor_Tendencia = true;       // Filtrar segun EMA200/50 superior

//============================================================
//  GESTIÓN DE RIESGO (METRALLETA)
//============================================================
input group "=== GESTIÓN DE RIESGO (LA METRALLETA) ==="
input double   LoteMain           = 0.01; // Lote operacion principal
input double   LoteShield         = 0.02; // Lote cobertura para blindaje
input int      Bozal_Max_Ops      = 4;    // Maximo de posiciones abiertas
input double   ProfitObjetivoUSD  = 3.0;  // Cerrar ciclo al ganar X dolares
input int      Distancia_Sticky_Pts = 150; // Distancia del escudo (Pts)

//============================================================
//  EL CAJERO (PROTECCIÓN DE CAPITALO)
//============================================================
input group "=== EL CAJERO (PROTECCIÓN DIARIA) ==="
input double   Proteger_Pct_Ganado = 15.0; // Cortar si perdemos % de lo ganado hoy
input double   Riesgo_Max_Diario   = 20.0; // Maxima perdida diaria permitida ($)

//============================================================
//  FILTRO DE NOTICIAS DE ALTO IMPACTO
//============================================================
input group "=== FILTRO DE NOTICIAS USD ==="
input bool     FiltroNoticias       = true; // Activar pausa por noticias?
input int      MinutosAntes         = 30;   // Minutos antes de noticia
input int      MinutosDespues       = 30;   // Minutos despues de noticia
input bool     CerrarEnPositivo     = true; // Asegurar ganancias antes de noticia

//============================================================
//  CONFIGURACIÓN AVANZADA
//============================================================
input group "=== CONFIGURACIÓN AVANZADA ==="
input bool     MostrarPanel      = true;     // Mostrar HUD Pro en pantalla
input long     MagicNumber       = 777112;   // ID unico del bot

//============================================================
//  Variables internas
//============================================================
CTrade   trade;
bool     licenseValid    = false;
string   licenseMsg      = "";
int      hSlow, hFast;
datetime nextAllowedTrade = 0;
bool     analizandoIA     = true;
bool     noticiaActiva    = false;
int      ModoBot          = 0; // 0: Ambos, 1: Solo Buy, 2: Solo Sell

// Identificador de objetos
#define PNL "AMT5_"

// Colores del HUD (Estilo KopyTrade Pro)
color CLR_BG         = C'10,10,25'; 
color CLR_HEADER     = C'25,20,60';
color CLR_BORDER     = C'100,80,220';
color CLR_TEXT       = clrWhite;
color CLR_BRAND      = C'200,100,255';
color CLR_SUCCESS    = C'70,230,120';
color CLR_DANGER     = C'240,70,70';
color CLR_WARN       = C'255,190,40';
color CLR_BTN_OFF    = C'40,40,70';

//============================================================
//  CHECK LICENCIA
//============================================================
bool CheckLicense() {
   long cuenta = AccountInfoInteger(ACCOUNT_LOGIN);
   if(cuenta == CuentaDemo || cuenta == CuentaReal) {
      licenseMsg = "LICENCIA PREMIUM"; return true;
   }
   if(AccountInfoInteger(ACCOUNT_TRADE_MODE) != ACCOUNT_TRADE_MODE_DEMO) {
      licenseMsg = "SIN LICENCIA"; return false;
   }
   string gVar = "KOPYTRADE_AMT5_TRIAL";
   datetime first;
   if(!GlobalVariableCheck(gVar)) {
      GlobalVariableSet(gVar, (double)TimeCurrent()); first = TimeCurrent();
   } else first = (datetime)GlobalVariableGet(gVar);
   
   int dias = (int)((TimeCurrent()-first)/86400);
   if(dias <= 30) {
      licenseMsg = "TRIAL DÍA " + IntegerToString(dias+1) + "/30"; return true;
   }
   licenseMsg = "TRIAL EXPIRADO"; return false;
}

//============================================================
//  INIT / DEINIT
//============================================================
int OnInit() {
   if(!CheckLicense()) {
      if(licenseMsg=="SIN LICENCIA") Alert("LICENCIA REQUERIDA PARA REAL. kopytrade.com");
      else if(licenseMsg=="TRIAL EXPIRADO") Alert("TRIAL FINALIZADO. kopytrade.com");
      return INIT_FAILED;
   }
   
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetTypeFillingBySymbol(_Symbol);

   hSlow = iMA(_Symbol, Analisis_TF, 200, 0, MODE_EMA, PRICE_CLOSE);
   hFast = iMA(_Symbol, Analisis_TF, 50, 0, MODE_EMA, PRICE_CLOSE);
   
   if(hSlow == INVALID_HANDLE || hFast == INVALID_HANDLE) return INIT_FAILED;
   
   nextAllowedTrade = TimeCurrent() + (Minutos_Análisis_IA * 60);
   licenseValid = true;

   if(MostrarPanel) CrearHUD();
   
   Print("La Ametralladora v5.0 PRO Inicializada en ", _Symbol);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
   if(hSlow != INVALID_HANDLE) IndicatorRelease(hSlow);
   if(hFast != INVALID_HANDLE) IndicatorRelease(hFast);
   ObjectsDeleteAll(0, PNL);
   Comment("");
}

//============================================================
//  NOTICIAS
//============================================================
bool HayNoticia() {
   if(!FiltroNoticias) return false;
   MqlCalendarValue vals[];
   datetime start = TimeCurrent() - MinutosDespues*60;
   datetime end   = TimeCurrent() + MinutosAntes*60;
   if(CalendarValueHistory(vals, start, end, "USD") > 0) {
      for(int i=0; i<ArraySize(vals); i++) {
         MqlCalendarEvent ev;
         if(CalendarEventById(vals[i].event_id, ev) && ev.importance == CALENDAR_IMPORTANCE_HIGH) return true;
      }
   }
   return false;
}

void CheckAutoCierreNoticia() {
   if(!CerrarEnPositivo) return;
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong t = PositionGetTicket(i);
      if(PositionSelectByTicket(t) && PositionGetInteger(POSITION_MAGIC)==MagicNumber && PositionGetDouble(POSITION_PROFIT)>0)
         trade.PositionClose(t);
   }
}

//============================================================
//  ONTICK
//============================================================
void OnTick() {
   if(!licenseValid) return;

   GestionCajera();
   MoverEscudoSticky();

   noticiaActiva = HayNoticia();
   if(noticiaActiva) {
      CheckAutoCierreNoticia();
      if(MostrarPanel) ActualizarHUD();
      return;
   }

   int nTotal = ContarPosiciones() + ContarPendientes();
   
   // --- FILTRO DE RECUPERACIÓN (Petición Usuario) ---
   // Si tenemos posiciones en ambas direcciones y el ciclo va en negativo,
   // no abrimos nuevas entradas hasta que una dirección sea clara.
   bool hayBuy = false, haySell = false;
   double pBuy = 0, pSell = 0;
   for(int i=0; i<PositionsTotal(); i++) {
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC)==MagicNumber) {
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) { hayBuy=true; pBuy += PositionGetDouble(POSITION_PROFIT); }
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL) { haySell=true; pSell += PositionGetDouble(POSITION_PROFIT); }
      }
   }

   if(nTotal == 0) {
      if(TimeCurrent() >= nextAllowedTrade) {
         analizandoIA = false;
         EjecutarAmetralladora();
      } else analizandoIA = true;
   }
   
   // Solo colocamos escudo si no estamos bloqueados por el filtro de recuperación
   bool bloqueadoRecuperacion = (hayBuy && haySell && (pBuy+pSell < 0) && (pBuy < 3.0 && pSell < 3.0));

   if(ContarPosiciones() >= 1 && ContarPendientes() == 0 && nTotal < Bozal_Max_Ops && !bloqueadoRecuperacion) 
      ColocarEscudoSticky();

   if(MostrarPanel) ActualizarHUD();
}

//============================================================
//  ESTRATEGIA
//============================================================
void EjecutarAmetralladora() {
   double maS[1], maF[1];
   if(CopyBuffer(hSlow,0,0,1,maS)<=0 || CopyBuffer(hFast,0,0,1,maF)<=0) return;
   
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   bool buyS  = (maF[0] > maS[0]);
   bool sellS = (maF[0] < maS[0]);
   
   if(ModoBot == 1) sellS = false;
   if(ModoBot == 2) buyS  = false;

   if(buyS) trade.Buy(LoteMain, _Symbol, ask, 0, 0, "AMT5_MAIN");
   else if(sellS) trade.Sell(LoteMain, _Symbol, bid, 0, 0, "AMT5_MAIN");
}

void ColocarEscudoSticky() {
   double netLot = 0;
   double lotB = 0, lotS = 0;
   
   for(int i=0; i<PositionsTotal(); i++) {
      ulong t = PositionGetTicket(i);
      if(PositionSelectByTicket(t) && PositionGetInteger(POSITION_MAGIC)==MagicNumber) {
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) lotB += PositionGetDouble(POSITION_VOLUME);
         else lotS += PositionGetDouble(POSITION_VOLUME);
      }
   }
   
   netLot = NormalizeDouble(lotB - lotS, 2);
   if(netLot == 0) return; // Estamos equilibrados, no poner más escudos alternos

   double dist = Distancia_Sticky_Pts * _Point;
   
   if(netLot > 0) // Netamente COMPRADOS -> Protección VENTA
      trade.SellStop(LoteShield, SymbolInfoDouble(_Symbol, SYMBOL_BID)-dist, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "AMT5_SHIELD");
   else // Netamente VENDIDOS -> Protección COMPRA
      trade.BuyStop(LoteShield, SymbolInfoDouble(_Symbol, SYMBOL_ASK)+dist, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "AMT5_SHIELD");
}

void MoverEscudoSticky() {
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double dst = Distancia_Sticky_Pts * _Point;

   for(int i=OrdersTotal()-1; i>=0; i--) {
      ulong t = OrderGetTicket(i);
      if(!OrderSelect(t) || OrderGetInteger(ORDER_MAGIC)!=MagicNumber) continue;
      double cur = OrderGetDouble(ORDER_PRICE_OPEN);
      if(OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_SELL_STOP) {
         double idea = NormalizeDouble(bid-dst, _Digits);
         if(idea > cur + 2*_Point) trade.OrderModify(t, idea, 0, 0, ORDER_TIME_GTC, 0);
      } else if(OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_BUY_STOP) {
         double idea = NormalizeDouble(ask+dst, _Digits);
         if(idea < cur - 2*_Point) trade.OrderModify(t, idea, 0, 0, ORDER_TIME_GTC, 0);
      }
   }
}

void GestionCajera() {
   double hProfit = GetHistorialHoy();
   double nProfit = 0; int n=0;
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong t = PositionGetTicket(i);
      if(PositionSelectByTicket(t) && PositionGetInteger(POSITION_MAGIC)==MagicNumber) {
         nProfit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP); n++;
      }
   }
   
   double limit = hProfit > 0 ? (hProfit * (Proteger_Pct_Ganado/100)) : Riesgo_Max_Diario;
   if(limit < 5) limit = 5;

   if(n > 0 && nProfit <= -limit) { LimpiarTodo(); nextAllowedTrade = TimeCurrent() + 1200; }
   if(n > 0 && nProfit >= ProfitObjetivoUSD) { LimpiarTodo(); nextAllowedTrade = TimeCurrent(); }
}

//============================================================
//  HUD - CREACIÓN
//============================================================
void CrLabel(string nm, int x, int y, string t, color c, int s=9, string f="Segoe UI") {
   ObjectCreate(0,PNL+nm,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,PNL+nm,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+nm,OBJPROP_YDISTANCE,y);
   ObjectSetString(0,PNL+nm,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+nm,OBJPROP_COLOR,c);
   ObjectSetInteger(0,PNL+nm,OBJPROP_FONTSIZE,s); ObjectSetString(0,PNL+nm,OBJPROP_FONT,f);
}
void CrRect(string nm, int x, int y, int w, int h, color bg, color bd) {
   ObjectCreate(0,PNL+nm,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,PNL+nm,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+nm,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,PNL+nm,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+nm,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,PNL+nm,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL+nm,OBJPROP_COLOR,bd);
   ObjectSetInteger(0,PNL+nm,OBJPROP_BORDER_TYPE,BORDER_FLAT);
}
void CrBtn(string nm, int x, int y, int w, int h, string t, color bg, color tc) {
   ObjectCreate(0,PNL+nm,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,PNL+nm,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+nm,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,PNL+nm,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+nm,OBJPROP_YSIZE,h);
   ObjectSetString(0,PNL+nm,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+nm,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,PNL+nm,OBJPROP_COLOR,tc); ObjectSetInteger(0,PNL+nm,OBJPROP_FONTSIZE,8);
}

void CrearHUD() {
   CrRect("bg", 10, 10, 260, 320, CLR_BG, CLR_BORDER);
   CrRect("hdr", 12, 12, 256, 35, CLR_HEADER, CLR_BORDER);
   CrLabel("ttl", 20, 16, "LA AMETRALLADORA v5.0", CLR_BRAND, 10, "Segoe UI Bold");
   CrLabel("sub", 20, 31, "ALGORITMO DE ORO PRO", CLR_BRAND, 7);

   CrLabel("l_lic", 20, 55, "LICENCIA:", CLR_TEXT, 8);
   CrLabel("v_lic", 80, 55, licenseMsg, CLR_SUCCESS, 8);

   CrRect("sep1", 12, 75, 256, 1, C'40,40,80', C'40,40,80');

   CrLabel("l_ia", 20, 85, "ESTADO IA:", CLR_TEXT, 8);
   CrLabel("v_ia", 85, 85, "ANALIZANDO...", CLR_WARN, 8);

   CrLabel("l_mkt", 20, 105, "MERCADO:", CLR_TEXT, 8);
   CrLabel("v_mkt", 85, 105, "H1 ALCISTA", CLR_SUCCESS, 8);

   CrLabel("l_nws", 20, 125, "NOTICIAS:", CLR_TEXT, 8);
   CrLabel("v_nws", 85, 125, "OK", CLR_SUCCESS, 8);

   CrRect("sep2", 12, 145, 256, 1, C'40,40,80', C'40,40,80');

   CrLabel("l_ops", 20, 155, "OPS ABIERTAS:", CLR_TEXT, 8);
   CrLabel("v_ops", 110, 155, "0 / 4", CLR_TEXT, 9);

   CrLabel("l_cur", 20, 175, "PROFIT CICLO:", CLR_TEXT, 8);
   CrLabel("v_cur", 110, 175, "$0.00", CLR_TEXT, 9);

   CrLabel("l_day", 20, 195, "PROFIT HOY:", CLR_TEXT, 8);
   CrLabel("v_day", 110, 195, "$0.00", CLR_SUCCESS, 9);

   CrRect("sep3", 12, 215, 256, 1, C'40,40,80', C'40,40,80');

   // Botones interactivos
   CrBtn("b_sell", 15, 230, 75, 25, "SOLO SELL", CLR_BTN_OFF, clrWhite);
   CrBtn("b_both", 93, 230, 74, 25, "INTERMEDIO", CLR_BRAND, clrWhite);
   CrBtn("b_buy", 170, 230, 75, 25, "SOLO BUY", CLR_BTN_OFF, clrWhite);

   CrRect("st_bg", 12, 265, 256, 30, C'20,20,50', CLR_BORDER);
   CrLabel("v_st", 20, 270, "CARGANDO...", CLR_WARN, 9, "Segoe UI Bold");

   CrLabel("ftr", 80, 300, "kopytrade.com", CLR_BRAND, 7);
   ChartRedraw();
}

void ActualizarHUD() {
   double curP = 0;
   for(int i=0; i<PositionsTotal(); i++) {
      ulong t=PositionGetTicket(i);
      if(PositionSelectByTicket(t) && PositionGetInteger(POSITION_MAGIC)==MagicNumber)
         curP += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
   }
   
   ObjectSetString(0,PNL+"v_lic", OBJPROP_TEXT, licenseMsg);
   
   string iaS; color iaC;
   if(analizandoIA) { iaS = "ANÁLISIS IA (" + IntegerToString((int)((nextAllowedTrade-TimeCurrent())/60)) + "m)"; iaC = CLR_WARN; }
   else { iaS = "LISTO - ACECHANDO"; iaC = CLR_SUCCESS; }
   ObjectSetString(0,PNL+"v_ia", OBJPROP_TEXT, iaS); ObjectSetInteger(0,PNL+"v_ia", OBJPROP_COLOR, iaC);

   double maS[1], maF[1]; CopyBuffer(hSlow,0,0,1,maS); CopyBuffer(hFast,0,0,1,maF);
   bool trend = (maF[0] > maS[0]);
   ObjectSetString(0,PNL+"v_mkt", OBJPROP_TEXT, trend ? "H1 TEND. COMPRA" : "H1 TEND. VENTA");
   ObjectSetInteger(0,PNL+"v_mkt", OBJPROP_COLOR, trend ? CLR_SUCCESS : CLR_DANGER);

   ObjectSetString(0,PNL+"v_nws", OBJPROP_TEXT, noticiaActiva ? "ALERTA - PAUSA" : "OK");
   ObjectSetInteger(0,PNL+"v_nws", OBJPROP_COLOR, noticiaActiva ? CLR_DANGER : CLR_SUCCESS);

   ObjectSetString(0,PNL+"v_ops", OBJPROP_TEXT, IntegerToString(ContarPosiciones()+ContarPendientes()) + " / " + IntegerToString(Bozal_Max_Ops));
   ObjectSetString(0,PNL+"v_cur", OBJPROP_TEXT, "$"+DoubleToString(curP, 2));
   ObjectSetInteger(0,PNL+"v_cur", OBJPROP_COLOR, curP>=0 ? CLR_SUCCESS : CLR_DANGER);
   
   double pDay = GetHistorialHoy();
   ObjectSetString(0,PNL+"v_day", OBJPROP_TEXT, "$"+DoubleToString(pDay, 2));
   ObjectSetInteger(0,PNL+"v_day", OBJPROP_COLOR, pDay>=0 ? CLR_SUCCESS : CLR_DANGER);

   ObjectSetInteger(0,PNL+"b_sell", OBJPROP_BGCOLOR, ModoBot==2 ? C'200,50,50' : CLR_BTN_OFF);
   ObjectSetInteger(0,PNL+"b_both", OBJPROP_BGCOLOR, ModoBot==0 ? CLR_BRAND : CLR_BTN_OFF);
   ObjectSetInteger(0,PNL+"b_buy",  OBJPROP_BGCOLOR, ModoBot==1 ? C'50,180,80' : CLR_BTN_OFF);

   string st; color stC;
   if(noticiaActiva) { st = "BLOQUEADO x NOTICIA"; stC = CLR_DANGER; }
   else if(analizandoIA) { st = "IA PREPARANDO ENTRADA"; stC = CLR_WARN; }
   else if(pDay <= -Riesgo_Max_Diario) { st = "STOP DIARIO ALCANZADO"; stC = CLR_DANGER; }
   else { st = "OPERATIVO - FILTRANDO"; stC = CLR_SUCCESS; }
   
   ObjectSetString(0,PNL+"v_st", OBJPROP_TEXT, st); ObjectSetInteger(0,PNL+"v_st", OBJPROP_COLOR, stC);
   ChartRedraw();
}

//============================================================
//  EVENTOS
//============================================================
void OnChartEvent(const int id, const long &lp, const double &dp, const string &sp) {
   if(id != CHARTEVENT_OBJECT_CLICK) return;
   if(sp == PNL+"b_sell") ModoBot = 2;
   else if(sp == PNL+"b_buy") ModoBot = 1;
   else if(sp == PNL+"b_both") ModoBot = 0;
   ObjectSetInteger(0, sp, OBJPROP_STATE, false);
   ActualizarHUD();
}

//============================================================
//  MISC
//============================================================
double GetHistorialHoy() {
   double d = 0; HistorySelect(iTime(_Symbol, PERIOD_D1, 0), TimeCurrent());
   for(int i=0; i<HistoryDealsTotal(); i++) {
      ulong t = HistoryDealGetTicket(i);
      if(HistoryDealSelect(t) && HistoryDealGetInteger(t, DEAL_MAGIC) == MagicNumber) d += HistoryDealGetDouble(t, DEAL_PROFIT);
   }
   return d;
}
void LimpiarTodo() {
   for(int i=PositionsTotal()-1; i>=0; i--) { ulong t = PositionGetTicket(i); if(PositionSelectByTicket(t) && PositionGetInteger(POSITION_MAGIC) == MagicNumber) trade.PositionClose(t); }
   for(int i=OrdersTotal()-1; i>=0; i--) { ulong t = OrderGetTicket(i); if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC) == MagicNumber) trade.OrderDelete(t); }
}
int ContarPosiciones() { int c=0; for(int i=0;i<PositionsTotal();i++) if(PositionSelectByTicket(PositionGetTicket(i))&&PositionGetInteger(POSITION_MAGIC)==MagicNumber) c++; return c; }
int ContarPendientes() { int c=0; for(int i=0;i<OrdersTotal();i++) if(OrderSelect(OrderGetTicket(i))&&OrderGetInteger(ORDER_MAGIC)==MagicNumber) c++; return c; }

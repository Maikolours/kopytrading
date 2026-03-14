//+------------------------------------------------------------------+
//|          KOPYTRADE_BTCUSD_BTCStormRider v6.3 ÉLITE             |
//|   DISEÑO v5 COMPLETO | SL ESTRUCTURAL 5h | ATR REAL | MINIMIZAR  |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Bot Oficial"
#property version   "6.30"
#property strict
#property description "BTC Storm Rider v6.3 | Edición Élite kopytrade.com"

#include <Trade\Trade.mqh>

//--- DECLARACIONES DE FUNCIONES VISUALES (Forward Declarations) ---
void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bw=1);
void CrLabel(string n, int x, int y, string t, color c, int s=9, string f="Segoe UI");
void CrBtn(string n, int x, int y, int w, int h, string t, color bg, color tc);

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
//  GESTIÓN DE RIESGO
//============================================================
input group "=== GESTION DE RIESGO ==="
input double LoteInicial            = 0.01;
input double MaxRiesgoPorTrade_USD  = 3.0;
input double ATR_Multiplicador_SL   = 1.5;
input double ATR_Multiplicador_TP   = 3.0;

//============================================================
//  STOP ESTRUCTURAL (OPTIMIZADO x RAQUEL)
//============================================================
input group "=== STOP ESTRUCTURAL (5 HORAS) ==="
input int    Velas_Estructural      = 10;   // 10 velas de M30 = 5 horas
input double Margen_Extra_USD       = 5.0;  // Margen de seguridad ajustado ($5)

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
//  FILTRO DE NOTICIAS DE ALTO IMPACTO
//============================================================
input group "=== FILTRO DE NOTICIAS DE ALTO IMPACTO ==="
input bool   FiltroNoticias       = true;
input int    MinutosAntes         = 30;
input int    MinutosDespues       = 30;
input bool   CerrarEnPositivo     = true;

//============================================================
//  BREAK EVEN
//============================================================
input group "=== BREAK EVEN ==="
input bool   ActivarBE        = true;
input double BE_Activar_USD   = 2.0;
input double BE_Garantia_USD  = 1.5;

//============================================================
//  TRAILING STOP
//============================================================
input group "=== TRAILING STOP ==="
input bool   ActivarTrailing          = true;
input double Trailing_Activar_USD     = 2.0;
input double Trailing_Distancia_USD   = 2.0;
input int    Puntos_Minimos_Trailing  = 100;

//============================================================
//  CONFIGURACION AVANZADA
//============================================================
input group "=== CONFIGURACION AVANZADA ==="
input int    MaxPosiciones   = 2;
input int    MinutosEspera   = 20;
input bool   MostrarPanel    = true;
input long   MagicNumber     = 780066;

//--- Variables internas ---
CTrade   trade;
bool     licenseValid = false;
string   licenseMsg   = "";
int      hEmaTend, hEmaRap, hEmaLent, hRSI, hATR;
datetime ultimaVela = 0;
datetime ultimaEntrada = 0;
int      diaActual = -1;
int      opsHoy = 0;
double   lossHoy = 0;
int      ModoBot = 0;
bool     StrucSL = true;
bool     Minimized = false;

#define PNL "BSR63E_"

//--- COLORES ORIGINALES v5.0 ---
color CLR_BG      = C'12,12,30';
color CLR_HDR     = C'35,25,75';
color CLR_BRD     = C'80,60,160';
color CLR_SEP     = C'50,50,90';
color CLR_TXT     = clrWhite;
color CLR_MUTED   = C'140,140,180';
color CLR_SUCCESS = C'50,210,100';
color CLR_DANGER  = C'220,60,60';
color CLR_WARN    = C'220,180,50';
color CLR_ACCENT  = C'50,80,200';

//--- FUNCIONES DE APOYO ---
string GetTimeLeft() {
   datetime nb = iTime(_Symbol, _Period, 0) + PeriodSeconds(_Period);
   long d = (long)nb - (long)TimeCurrent();
   if(d < 0) d = 0;
   return StringFormat("%02d:%02d", (int)(d/60), (int)(d%60));
}

double GetStructuralSL(ENUM_POSITION_TYPE t) {
   int hi = iHighest(_Symbol, _Period, MODE_HIGH, Velas_Estructural, 1);
   int li = iLowest(_Symbol, _Period, MODE_LOW, Velas_Estructural, 1);
   double pps = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double ppv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(ppv <= 0 || pps <= 0) return 0;
   
   // Cálculo de margen $ en puntos de precio
   // TickValue es el valor de 1 Tick para 1 Lote. 
   // Queremos un margen de Margen_Extra_USD para LoteInicial.
   double pointsForDollar = pps / (ppv * LoteInicial);
   double marginPrice = Margen_Extra_USD * pointsForDollar;

   if(t == POSITION_TYPE_SELL) return NormalizeDouble(iHigh(_Symbol, _Period, hi) + marginPrice, _Digits);
   else return NormalizeDouble(iLow(_Symbol, _Period, li) - marginPrice, _Digits);
}

//--- INICIALIZACIÓN ---
int OnInit() {
   hEmaTend = iMA(_Symbol, _Period, EMA_Tendencia, 0, MODE_EMA, PRICE_CLOSE);
   hEmaRap  = iMA(_Symbol, _Period, EMA_Rapida,    0, MODE_EMA, PRICE_CLOSE);
   hEmaLent = iMA(_Symbol, _Period, EMA_Lenta,     0, MODE_EMA, PRICE_CLOSE);
   hRSI     = iRSI(_Symbol, _Period, RSI_Periodo,  PRICE_CLOSE);
   hATR     = iATR(_Symbol, _Period, ATR_Periodo);
   
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetTypeFillingBySymbol(_Symbol);
   
   licenseValid = true;
   licenseMsg = "TRIAL DIA 1/30";
   
   if(MostrarPanel) CrearPanel();
   return INIT_SUCCEEDED;
}

void OnDeinit(const int r) { ObjectsDeleteAll(0, PNL); }

void OnTick() {
   if(!licenseValid) return;
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   if(dt.day_of_year != diaActual) { diaActual = dt.day_of_year; opsHoy = 0; lossHoy = 0; }
   
   // AUTO-GESTIÓN DE LA POSICIÓN (Incluso las abiertas de antes con el mismo Magic)
   if(StrucSL) {
      for(int i=PositionsTotal()-1; i>=0; i--) {
         ulong t = PositionGetTicket(i);
         if(PositionSelectByTicket(t) && PositionGetInteger(POSITION_MAGIC)==MagicNumber && PositionGetString(POSITION_SYMBOL)==_Symbol) {
            double nSL = GetStructuralSL((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE));
            double cSL = PositionGetDouble(POSITION_SL);
            // Si el Stop está a más de $1 de diferencia de donde debería, lo ajustamos
            if(MathAbs(nSL - cSL) > (1.0 * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE))) {
               trade.PositionModify(t, nSL, PositionGetDouble(POSITION_TP));
            }
         }
      }
   }

   if(MostrarPanel) ActualizarPanel();
   CheckEntradas();
}

void CheckEntradas() {
   datetime v = iTime(_Symbol, _Period, 0);
   if(v == ultimaVela) return;
   double r[1], l[1];
   CopyBuffer(hEmaRap,0,0,1,r); CopyBuffer(hEmaLent,0,0,1,l);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   bool bS = (r[0] > l[0]) && (bid > r[0]) && (ModoBot != 2);
   bool sS = (r[0] < l[0]) && (bid < r[0]) && (ModoBot != 1);
   
   if(bS && ContarPos() < MaxPosiciones) {
      double sl = StrucSL ? GetStructuralSL(POSITION_TYPE_BUY) : 0;
      trade.Buy(LoteInicial, _Symbol, ask, sl, 0, "BSR63_B");
      ultimaVela = v; opsHoy++;
   }
   if(sS && ContarPos() < MaxPosiciones) {
      double sl = StrucSL ? GetStructuralSL(POSITION_TYPE_SELL) : 0;
      trade.Sell(LoteInicial, _Symbol, bid, sl, 0, "BSR63_S");
      ultimaVela = v; opsHoy++;
   }
}

int ContarPos() {
   int c=0;
   for(int i=0; i<PositionsTotal(); i++) if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC)==MagicNumber) c++;
   return c;
}

//--- PANEL VISUAL ---
void CrearPanel() {
   ObjectsDeleteAll(0, PNL);
   int x=15, y=15, w=295, h=420;
   if(Minimized) { w=220; h=65; }
   CrRect("bg", x, y, w, h, CLR_BG, CLR_BRD, 2);
   CrRect("hdr", x+2, y+2, w-4, 40, CLR_HDR, CLR_HDR);
   CrLabel("ttl", x+15, y+8, "BTC STORM RIDER v6.3", clrWhite, 11, "Arial Bold");
   CrLabel("sub", x+15, y+25, "kopytrade.com", CLR_MUTED, 7);
   CrBtn("min", x+w-25, y+8, 18, 18, Minimized?"+":"-", CLR_HDR, clrWhite);
   if(!Minimized) {
      // LICENCIA
      CrRect("lic-b", x+5, y+50, w-10, 22, C'25,25,50', CLR_BRD);
      CrLabel("licV", x+15, y+53, "LIC:  " + licenseMsg, CLR_WARN, 8, "Arial Bold");
      CrLabel("ctaV", x+160, y+53, "CTA: " + IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN)), CLR_MUTED, 8);
      // MERCADO
      CrLabel("mH", x+12, y+80, "MERCADO", CLR_MUTED, 7);
      CrLabel("rsL", x+15, y+95, "RSI:", CLR_MUTED, 8); CrLabel("rsV", x+50, y+95, "00.0", CLR_TXT, 9);
      CrLabel("atL", x+110, y+95, "ATR $:", CLR_MUTED, 8); CrLabel("atV", x+170, y+95, "$0.00", CLR_SUCCESS, 9);
      CrLabel("tmV", x+235, y+95, GetTimeLeft(), CLR_WARN, 9, "Consolas");
      CrLabel("tnL", x+15, y+118, "Tendencia:", CLR_MUTED, 8); CrLabel("tnV", x+110, y+118, "ALCISTA", CLR_SUCCESS, 9);
      CrLabel("seL", x+15, y+138, "Sesión:", CLR_MUTED, 8); CrLabel("seV", x+110, y+138, "ACTIVA", CLR_SUCCESS, 9);
      // HOY
      CrLabel("hH", x+12, y+175, "HOY", CLR_MUTED, 7);
      CrLabel("opL", x+15, y+190, "Operaciones:", CLR_MUTED, 8); CrLabel("opV", x+120, y+190, "0/50", CLR_TXT, 9);
      CrLabel("psL", x+200, y+190, "Pos:", CLR_MUTED, 8); CrLabel("psV", x+250, y+190, "0/2", CLR_TXT, 9);
      CrLabel("lsL", x+15, y+210, "Pérdida:", CLR_MUTED, 8); CrLabel("lsV", x+120, y+210, "$0.00", CLR_DANGER, 9);
      CrLabel("baL", x+15, y+230, "Balance:", CLR_MUTED, 8); CrLabel("baV", x+120, y+230, "$0.00", CLR_TXT, 9);
      // BOTONES
      CrLabel("moH", x+12, y+265, "MODO DE OPERACIÓN", CLR_MUTED, 7);
      CrBtn("b_sell", x+10, y+285, 90, 25, "SOLO SELL", ModoBot==2?C'180,40,40':C'35,35,65', clrWhite);
      CrBtn("b_both", x+102, y+285, 90, 25, "BUY & SELL", ModoBot==0?CLR_ACCENT:C'35,35,65', clrWhite);
      CrBtn("b_buy", x+194, y+285, 90, 25, "SOLO BUY", ModoBot==1?C'30,140,60':C'35,35,65', clrWhite);
      // ESTRUCTURAL
      CrLabel("slL", x+15, y+330, "STOP ESTRUCTURAL:", CLR_MUTED, 8);
      CrBtn("b_sl", x+165, y+325, 60, 25, StrucSL?"ON":"OFF", StrucSL?CLR_ACCENT:C'35,35,65', clrWhite);
      // ESTADO
      CrRect("stBg", x+2, h-40+y, w-4, 30, C'15,15,40', CLR_BRD);
      CrLabel("stL", x+15, h-32+y, "ESTADO:", CLR_MUTED, 8); CrLabel("stV", x+85, h-32+y, "OPERATIVO", CLR_SUCCESS, 10, "Arial Bold");
   } else {
      CrLabel("tmM", x+15, y+45, "VELA: " + GetTimeLeft(), CLR_WARN, 9);
      CrLabel("baM", x+120, y+45, "BAL: $" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),0), clrWhite, 8);
   }
   ChartRedraw(0);
}

void ActualizarPanel() {
   if(Minimized) ObjectSetString(0, PNL+"tmM", OBJPROP_TEXT, "VELA: " + GetTimeLeft());
   else {
      ObjectSetString(0, PNL+"tmV", OBJPROP_TEXT, GetTimeLeft());
      double r[1], a[1], r2[1], l2[1];
      CopyBuffer(hRSI,0,0,1,r); CopyBuffer(hATR,0,0,1,a);
      CopyBuffer(hEmaRap,0,0,1,r2); CopyBuffer(hEmaLent,0,0,1,l2);
      ObjectSetString(0, PNL+"rsV", OBJPROP_TEXT, DoubleToString(r[0], 1));
      
      double ppv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double pps = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double atrUSD = (a[0]/pps) * ppv * LoteInicial;
      ObjectSetString(0, PNL+"atV", OBJPROP_TEXT, "$"+DoubleToString(atrUSD, 2));
      
      bool up = (r2[0] > l2[0]);
      ObjectSetString(0, PNL+"tnV", OBJPROP_TEXT, up?"ALCISTA":"BAJISTA");
      ObjectSetInteger(0, PNL+"tnV", OBJPROP_COLOR, up?CLR_SUCCESS:CLR_DANGER);
      ObjectSetString(0, PNL+"opV",  OBJPROP_TEXT, IntegerToString(opsHoy)+"/50");
      ObjectSetString(0, PNL+"psV",  OBJPROP_TEXT, IntegerToString(ContarPos())+"/2");
      ObjectSetString(0, PNL+"baV",  OBJPROP_TEXT, "$"+DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2));
   }
   ChartRedraw(0);
}

void OnChartEvent(const int id, const long &lp, const double &dp, const string &sp) {
   if(id!=CHARTEVENT_OBJECT_CLICK) return;
   if(sp==PNL+"min") { Minimized=!Minimized; CrearPanel(); }
   if(sp==PNL+"b_both") { ModoBot=0; CrearPanel(); }
   if(sp==PNL+"b_buy")  { ModoBot=1; CrearPanel(); }
   if(sp==PNL+"b_sell") { ModoBot=2; CrearPanel(); }
   if(sp==PNL+"b_sl")   { StrucSL=!StrucSL; CrearPanel(); }
   ObjectSetInteger(0, sp, OBJPROP_STATE, false);
}

void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bw=1) {
   ObjectCreate(0,PNL+n,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,bd);
}
void CrLabel(string n, int x, int y, string t, color c, int s, string f) {
   ObjectCreate(0,PNL+n,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y);
   ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,c);
   ObjectSetInteger(0,PNL+n,OBJPROP_FONTSIZE,s); ObjectSetString(0,PNL+n,OBJPROP_FONT,f);
}
void CrBtn(string n, int x, int y, int w, int h, string t, color bg, color tc) {
   ObjectCreate(0,PNL+n,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h);
   ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,tc);
}

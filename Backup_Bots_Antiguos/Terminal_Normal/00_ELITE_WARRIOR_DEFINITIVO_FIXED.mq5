//|             00_ELITE_WARRIOR_DEFINITIVO_FIXED                  |
//|      STRATEGY: WARRIOR PREDATOR | HUD: MASTER CHRONOS | SYNC: FULL |
//|        VERSION: 18.00 FINAL - FIXED HUD & FORCED REFRESH         |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrade Corp."
#property version   "18.00"
#property strict

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

//--- ENUMERACIONES
enum ENUM_MODE { MODE_ZEN, MODE_COSECHA };
enum ENUM_DIR  { DIR_COMPRAS, DIR_VENTAS, DIR_AMBAS };
enum ENUM_EXEC { EXEC_MARKET, EXEC_LIMIT };
enum ENUM_STATE { STATE_WAIT_BOS, STATE_WAIT_RETRACE, STATE_WAIT_CONFIRM };
enum ENUM_PRESET { PRESET_DIARIO, PRESET_FINDE };

bool isMinimized = false; 

//============================================================
//  PARÁMETROS DE ENTRADA
//============================================================
input group "=== 🔑 CONFIGURACIÓN DASHBOARD ==="
input string   InpMasterID       = "cmn9hfaxg000lvhbcqidlvvfm";
input bool     InpRemoteSync     = true;

input group "=== 🛡️ ESTRATEGIA WARRIOR PREDATOR ==="
input ENUM_EXEC       InpExecMode      = EXEC_MARKET; 
input ENUM_TIMEFRAMES InpTF_Macro      = PERIOD_H1; 
input ENUM_TIMEFRAMES InpTF_Mid        = PERIOD_M15;
input ENUM_TIMEFRAMES InpTF_Exec       = PERIOD_M5; 
input int             InpEMA           = 200;

input group "=== 📅 PRESETS (Horas y Protección) ==="
input int             InpLkb_D         = 12;  
input int             InpBE_D          = 300; 
input int             InpLkb_WE        = 6;   
input int             InpBE_WE         = 200; 

input group "=== 🛡️ GESTIÓN DINÁMICA ==="
input int             InpTrail_Points  = 600; 
input int             InpTrail_Dist    = 250; 

input group "=== 💵 RIESGO Y MAGIC ==="
input double          InpRisk          = 0.5;
input int             InpSL_Pips       = 800;   
input double          InpRR_Ratio      = 2.0;   
input int             InpMagic         = 202800;

#define HUD_PRE "HUD_MASTER_"
#define GRAF_PRE "WAR_V_"
#define FIBO_NAME "WAR_V_FIBO"

//--- OBJETOS MQL5
CTrade         trade;
CPositionInfo  posInfo;
ENUM_STATE     state = STATE_WAIT_BOS;
ENUM_MODE      currentMode = MODE_COSECHA;
ENUM_DIR       currentDir = DIR_AMBAS;
ENUM_EXEC      currentExec = EXEC_MARKET;
ENUM_PRESET    currentPreset = PRESET_DIARIO;

int            hEma1H, hEmaMacro;
int            dirMacro = 0, dir1H = 0; 
double         f100=0, f0=0, f23=0, f38=0, f61=0, f70=0, f78=0;
double         valEmaMacro = 0; 
string         botStatus = "WARRIOR READY";
string         botNarrative = "Sniper activado. Cazando...";
datetime       lastSyncTime = 0, lastTickLocal = 0, lastTickServer = 0;
bool           pX_done = false, p1_pierced = false;

int      curLkb, curBE, curHours;

//+------------------------------------------------------------------+
//| EVENTOS PRINCIPALES                                              |
//+------------------------------------------------------------------+
int OnInit() {
   trade.SetExpertMagicNumber(InpMagic);
   hEmaMacro = iMA(_Symbol, InpTF_Macro, InpEMA, 0, MODE_EMA, PRICE_CLOSE);
   hEma1H = iMA(_Symbol, InpTF_Mid, InpEMA, 0, MODE_EMA, PRICE_CLOSE);
   ApplyPreset();
   if(GlobalVariableCheck("WS_M_"+_Symbol)) {
      state = (ENUM_STATE)GlobalVariableGet("WS_M_"+_Symbol);
      f100 = GlobalVariableGet("WF1_M_"+_Symbol);
      f0 = GlobalVariableGet("WF0_M_"+_Symbol);
   }
   CrearPanel();
   EventSetTimer(1); 
   ChartRedraw();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) { 
   if(r == REASON_CHARTCHANGE || r == REASON_PARAMETERS) SaveState();
   else { 
      ObjectsDeleteAll(0, HUD_PRE); ObjectsDeleteAll(0, GRAF_PRE); ObjectsDeleteAll(0, FIBO_NAME);
      CancelOrders();
   }
   EventKillTimer();
}

void ApplyPreset() {
   if(currentPreset == PRESET_DIARIO) { curHours = InpLkb_D; curBE = InpBE_D; }
   else { curHours = InpLkb_WE; curBE = InpBE_WE; }
   curLkb = (int)(curHours * 3600 / PeriodSeconds(InpTF_Mid));
   if(curLkb < 10) curLkb = 10;
}

void OnTick() {
   lastTickLocal = TimeLocal(); lastTickServer = TimeCurrent();
   ApplyPreset(); UpdateTrends();SyncDown();ManageRisk();DetectBOS();
   if(CountActive() == 0) MonitorRetracement();
}

void OnTimer() {
   // SEGURIDAD: Si no hay fondo del HUD, lo recreamos
   if(ObjectFind(0, HUD_PRE+"bg") < 0) CrearPanel();
   UpdatePanelText();
   ChartRedraw();
}

void UpdateTrends() {
   if(SeriesInfoInteger(_Symbol, InpTF_Macro, SERIES_SYNCHRONIZED) == 0) return;
   double eM[1], e1[1];
   if(CopyBuffer(hEmaMacro, 0, 0, 1, eM) <= 0 || CopyBuffer(hEma1H, 0, 0, 1, e1) <= 0) return;
   valEmaMacro = eM[0];
   double p = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) + SymbolInfoDouble(_Symbol, SYMBOL_BID)) / 2.0;
   dirMacro = (p > eM[0]) ? 1 : -1;
   dir1H = (p > e1[0]) ? 1 : -1;
   if(CountActive() > 0) botStatus = "ESTADO: PROTECCIÓN ACTIVA 🛡️";
   else botNarrative = (dirMacro == 1) ? "🔎 CAZANDO COMPRAS 📈" : "🔎 CAZANDO VENTAS 📉";
}

void DetectBOS() {
   if(CountActive() > 0) return;
   int hh = iHighest(_Symbol, InpTF_Mid, MODE_HIGH, curLkb, 0); 
   int ll = iLowest(_Symbol, InpTF_Mid, MODE_LOW, curLkb, 0); 
   double hi = iHigh(_Symbol, InpTF_Mid, hh), lo = iLow(_Symbol, InpTF_Mid, ll);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK), bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   bool bull = (dirMacro == 1); 
   f100 = bull ? lo : hi; 
   f0 = bull ? MathMax(hi, ask) : MathMin(lo, bid);
   DrawFibo(f100, f0, bull);
   string wav = GRAF_PRE+"WAVE";
   if(ObjectFind(0,wav)<0) { ObjectCreate(0,wav,OBJ_TREND,0,iTime(_Symbol,InpTF_Mid,bull?ll:hh),f100,iTime(_Symbol,InpTF_Mid,bull?hh:ll),f0); ObjectSetInteger(0,wav,OBJPROP_WIDTH,2); ObjectSetInteger(0,wav,OBJPROP_STYLE,STYLE_DOT); }
   else { ObjectMove(0,wav,0,iTime(_Symbol,InpTF_Mid,bull?ll:hh),f100); ObjectMove(0,wav,1,iTime(_Symbol,InpTF_Mid,bull?hh:ll),f0); }
   ObjectSetInteger(0,wav,OBJPROP_COLOR,(bull?clrCyan:clrOrangeRed)); ObjectSetInteger(0,wav,OBJPROP_BACK, true);
   if((bull && ask >= hi) || (!bull && bid <= lo)) { if(state != STATE_WAIT_RETRACE) { state = STATE_WAIT_RETRACE; pX_done=false; SaveState(); } }
}

void DrawFibo(double p100, double p0, bool bull) {
   if(ObjectFind(0, FIBO_NAME)<0) {
      ObjectCreate(0, FIBO_NAME, OBJ_FIBO, 0, 0, 0, 0, 0);
      ObjectSetInteger(0, FIBO_NAME, OBJPROP_RAY_RIGHT, true); ObjectSetInteger(0, FIBO_NAME, OBJPROP_BACK, true); ObjectSetInteger(0, FIBO_NAME, OBJPROP_LEVELS, 8);
      ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 0, 0.0);    ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 0, "0.0 TP ZONE");
      ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 1, 0.236);  ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 1, "23.6 IMP X");
      ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 2, 0.382);  ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 2, "38.2 IMP 0");
      ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 3, 0.5);    ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 3, "50.0");
      ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 4, 0.618);  ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 4, "61.8 OTE 1");
      ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 5, 0.705);  ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 5, "70.5 OTE 2");
      ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 6, 0.786);  ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 6, "78.6 OTE 3");
      ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 7, 1.0);    ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 7, "100.0 SL HARD");
   }
   ObjectMove(0, FIBO_NAME, 0, iTime(_Symbol, InpTF_Mid, 0), p100); 
   ObjectMove(0, FIBO_NAME, 1, TimeCurrent(), p0); 
   f23 = bull ? f0-(f0-f100)*0.236 : f0+(f100-f0)*0.236; 
   f38 = bull ? f0-(f0-f100)*0.382 : f0+(f100-f0)*0.382; 
   f61 = bull ? f0-(f0-f100)*0.618 : f0+(f100-f0)*0.618; 
   f70 = bull ? f0-(f0-f100)*0.705 : f0+(f100-f0)*0.705; 
   f78 = bull ? f0-(f0-f100)*0.786 : f0+(f100-f0)*0.786;
}

void MonitorRetracement() {
   if(state != STATE_WAIT_RETRACE) return;
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK), bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   bool bull = (dirMacro == 1); double currentPrice = bull ? ask : bid;
   if(bull && currentPrice <= f61) p1_pierced = true;
   if(!bull && currentPrice >= f61) p1_pierced = true;
   double c0=iClose(_Symbol,InpTF_Exec,0), o0=iOpen(_Symbol,InpTF_Exec,0); 
   bool confirmed = bull ? (c0>o0) : (c0<o0);
   if(confirmed && p1_pierced) { if(!pX_done) { ExecuteMarket(bull, "WARRIOR_FIXED"); pX_done=true; state=STATE_WAIT_BOS; SaveState(); } }
}

void ExecuteMarket(bool bull, string comment) {
   double ps = (_Digits<=2?1.0:(_Digits==3||_Digits==5?10.0*_Point:_Point));
   double lot = AccountInfoDouble(ACCOUNT_EQUITY)*InpRisk/100.0/800.0; lot = NormalizeLot(lot);
   double ent = bull ? SymbolInfoDouble(_Symbol,SYMBOL_ASK) : SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double sl = bull ? ent - InpSL_Pips*ps : ent + InpSL_Pips*ps;
   double tp = bull ? ent + (InpSL_Pips*InpRR_Ratio)*ps : ent - (InpSL_Pips*InpRR_Ratio)*ps;
   if(bull) trade.Buy(lot, _Symbol, 0, sl, tp, comment); else trade.Sell(lot, _Symbol, 0, sl, tp, comment);
}

void CancelOrders() { for(int i=OrdersTotal()-1; i>=0; i--) { ulong t = OrderGetTicket(i); if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC)==InpMagic) trade.OrderDelete(t); } }
void SaveState() { GlobalVariableSet("WS_M_"+_Symbol, (double)state); GlobalVariableSet("WF1_M_"+_Symbol, f100); GlobalVariableSet("WF0_M_"+_Symbol, f0); }
void ManageRisk() {
   double ps = (_Digits<=2?1.0:(_Digits==3||_Digits==5?10.0*_Point:_Point));
   for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic()==InpMagic) {
      double op=posInfo.PriceOpen(), cur=posInfo.PriceCurrent(), sl=posInfo.StopLoss(); double pnl = (posInfo.PositionType()==POSITION_TYPE_BUY) ? (cur-op)/ps : (op-cur)/ps;
      if(pnl >= curBE) { if(MathAbs(sl-op)>2*ps) trade.PositionModify(posInfo.Ticket(), op, posInfo.TakeProfit()); }
      if(pnl >= InpTrail_Points) {
         double nsl = (posInfo.PositionType()==POSITION_TYPE_BUY) ? cur - InpTrail_Dist*ps : cur + InpTrail_Dist*ps;
         if((posInfo.PositionType()==POSITION_TYPE_BUY && nsl > sl + 20*ps) || (posInfo.PositionType()==POSITION_TYPE_SELL && (nsl < sl - 20*ps || (sl==0)))) trade.PositionModify(posInfo.Ticket(), nsl, posInfo.TakeProfit());
      }
   }
}

double NormalizeLot(double l) { double s=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP); l=MathFloor(l/s)*s; return MathMax(l,SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN)); }
int CountActive() { int c=0; for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic()==InpMagic) c++; return c; }
void SyncDown() {
   if(!InpRemoteSync || TimeCurrent() < lastSyncTime+5) return; lastSyncTime=TimeCurrent();
   string u="https://kopytrading.vercel.app/api/sync-positions", b="{\"purchaseId\":\""+InpMasterID+"\",\"status\":\""+botStatus+"\"}";
   uchar p[], r[]; string rh; StringToCharArray(b, p); if(ArraySize(p)>0) ArrayResize(p, ArraySize(p)-1);
   WebRequest("POST", u, "Content-Type: application/json\r\n", 3000, p, r, rh); 
}

void CrearPanel() {
   ObjectsDeleteAll(0, HUD_PRE); int x=15, y=30, w=350, h=isMinimized ? 40 : 580;
   CrRect("bg", x, y, w, h, C'18,10,10', clrMaroon, 2); CrRect("hdr", x+2, y+2, w-4, 35, clrMaroon, clrRed);
   CrLabel("ttl", x+15, y+6, "ELITE WARRIOR FIXED MASTER", clrWhite, 9);
   CrLabel("clk", x+w-115, y+6, "[00:00]", clrGold, 10);
   CrLabel("dbg", x+w-115, y+20, "EMA: " + DoubleToString(valEmaMacro, _Digits), clrWhite, 6);
   CrBtn("b_min", x+w-30, y+2, 22, 22, isMinimized ? "[+]" : "[-]", clrMaroon, clrWhite);
   if(!isMinimized) {
      CrRect("pl_bg", x+10, y+70, w-20, 95, clrBlack, clrMaroon); 
      CrLabel("pl_t", x+15, y+75, "🎯 ESTRATEGIA MASTER:", clrOrangeRed, 7);
      CrLabel("planA", x+20, y+95, botNarrative, clrWhite, 7); 
      CrLabel("vis", x+20, y+110, "VISIÓN: " + (string)curHours + "h | PROTECCIÓN: " + (string)curBE + "pts", clrGray, 7);
      CrBtn("b_day", x+10, y+175, 160, 25, "MODO DIARIO", currentPreset==PRESET_DIARIO?clrCyan:clrCrimson, currentPreset==PRESET_DIARIO?clrCrimson:clrWhite);
      CrBtn("b_we", x+175, y+175, 160, 25, "MODO FINDE", currentPreset==PRESET_FINDE?clrCyan:clrCrimson, currentPreset==PRESET_FINDE?clrCrimson:clrWhite);
      CrRect("ote_bg", x+10, y+210, w-20, 95, clrBlack, clrGold); 
      CrLabel("ote_t", x+15, y+215, "🏹 RED DE CAZA ACTIVADA:", clrGold, 7);
      CrLabel("oteX", x+20, y+230, "ZONA IMPULSO (23.6%): " + (f23>0?DoubleToString(f23,_Digits):"BUSCANDO..."), clrWhite, 7);
      CrLabel("ote0", x+20, y+242, "ZONA IMPULSO (38.2%): " + (f38>0?DoubleToString(f38,_Digits):"BUSCANDO..."), clrWhite, 7);
      CrLabel("ote1", x+20, y+254, "GATILLO TR 1 (61.8%): " + (f61>0?DoubleToString(f61,_Digits):"BUSCANDO..."), clrWhite, 7);
      CrLabel("ote2", x+20, y+266, "GATILLO TR 2 (70.5%): " + (f70>0?DoubleToString(f70,_Digits):"BUSCANDO..."), clrWhite, 7);
      CrLabel("ote3", x+20, y+278, "GATILLO TR 3 (78.6%): " + (f78>0?DoubleToString(f78,_Digits):"BUSCANDO..."), clrWhite, 7);
      CrLabel("stV", x+15, y+315, botStatus, clrWhite, 8); 
      CrLabel("tr4", x+15, y+335, "BIAS MACRO (1H): " + (dirMacro==1?"ALCISTA ▲":"BAJISTA ▼"), (dirMacro==1?clrCyan:clrOrangeRed), 8);
      CrLabel("tr1", x+15, y+355, "ESTRUCTURA (M15): " + (dir1H==1?"ALCISTA ▲":"BAJISTA ▼"), (dir1H==1?clrCyan:clrOrangeRed), 8);
      CrBtn("b_zen", x+10, y+390, 160, 25, "MODO ZEN", currentMode==MODE_ZEN?clrCyan:clrCrimson, currentMode==MODE_ZEN?clrCrimson:clrWhite);
      CrBtn("b_har", x+175, y+390, 160, 25, "COSECHA", currentMode==MODE_COSECHA?clrCyan:clrCrimson, currentMode==MODE_COSECHA?clrCrimson:clrWhite);
      CrBtn("b_mar", x+10, y+430, 160, 25, "MERCADO (Gatillo)", currentExec==EXEC_MARKET?clrCyan:clrCrimson, currentExec==EXEC_MARKET?clrCrimson:clrWhite);
      CrBtn("b_lim", x+175, y+430, 160, 25, "AUTO (Zonas)", currentExec==EXEC_LIMIT?clrCyan:clrCrimson, currentExec==EXEC_LIMIT?clrCrimson:clrWhite);
      CrBtn("b_c", x+10, y+470, 104, 25, "COMPRA", currentDir==DIR_COMPRAS?clrCyan:clrCrimson, currentDir==DIR_COMPRAS?clrCrimson:clrWhite);
      CrBtn("b_a", x+120, y+470, 104, 25, "AMBAS", currentDir==DIR_AMBAS?clrCyan:clrCrimson, currentDir==DIR_AMBAS?clrCrimson:clrWhite);
      CrBtn("b_v", x+230, y+470, 104, 25, "VENTA", currentDir==DIR_VENTAS?clrCyan:clrCrimson, currentDir==DIR_VENTAS?clrCrimson:clrWhite);
      CrBtn("b_cl", x+10, y+515, 330, 50, "CERRAR TODO (PANIC)", clrRed, clrWhite);
   }
}
void UpdatePanelText() {
   if(isMinimized) return;
   datetime cS = TimeCurrent(); if(lastTickLocal > 0) cS = lastTickServer + (datetime)(TimeLocal() - lastTickLocal);
   long sec = iTime(_Symbol, InpTF_Exec, 0) + PeriodSeconds(InpTF_Exec) - cS; if(sec < 0) sec = 0;
   ObjectSetString(0,HUD_PRE+"clk",OBJPROP_TEXT,StringFormat("[%02d:%02d]", sec/60, sec%60));
   UpdateTrends();
   ObjectSetString(0,HUD_PRE+"planA",OBJPROP_TEXT,botNarrative);
   ObjectSetString(0,HUD_PRE+"dbg",OBJPROP_TEXT,"EMA: " + DoubleToString(valEmaMacro, _Digits));
   ObjectSetString(0,HUD_PRE+"oteX",OBJPROP_TEXT,"ZONA IMPULSO (23.6%): " + (f23>0?DoubleToString(f23,_Digits):"BUSCANDO..."));
   ObjectSetString(0,HUD_PRE+"ote0",OBJPROP_TEXT,"ZONA IMPULSO (38.2%): " + (f38>0?DoubleToString(f38,_Digits):"BUSCANDO..."));
   ObjectSetString(0,HUD_PRE+"ote1",OBJPROP_TEXT,"GATILLO TR 1 (61.8%): " + (f61>0?DoubleToString(f61,_Digits):"BUSCANDO..."));
   ObjectSetString(0,HUD_PRE+"ote2",OBJPROP_TEXT,"GATILLO TR 2 (70.5%): " + (f70>0?DoubleToString(f70,_Digits):"BUSCANDO..."));
   ObjectSetString(0,HUD_PRE+"ote3",OBJPROP_TEXT,"GATILLO TR 3 (78.6%): " + (f78>0?DoubleToString(f78,_Digits):"BUSCANDO...")); 
   ObjectSetString(0,HUD_PRE+"stV",OBJPROP_TEXT,botStatus);
   ObjectSetString(0,HUD_PRE+"tr4",OBJPROP_TEXT,"BIAS MACRO (1H): " + (dirMacro==1?"ALCISTA ▲":"BAJISTA ▼"));
   ObjectSetInteger(0,HUD_PRE+"tr4",OBJPROP_COLOR,(dirMacro==1?clrCyan:clrOrangeRed));
   ObjectSetString(0,HUD_PRE+"tr1",OBJPROP_TEXT,"ESTRUCTURA (M15): " + (dir1H==1?"ALCISTA ▲":"BAJISTA ▼"));
   ObjectSetInteger(0,HUD_PRE+"tr1",OBJPROP_COLOR,(dir1H==1?clrCyan:clrOrangeRed));
}
void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bw=1) { ObjectCreate(0,HUD_PRE+n,OBJ_RECTANGLE_LABEL,0,0,0); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YSIZE,h); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_COLOR,bd); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_ZORDER, 2000); }
void CrLabel(string n, int x, int y, string t, color c, int s) { ObjectCreate(0,HUD_PRE+n,OBJ_LABEL,0,0,0); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YDISTANCE,y); ObjectSetString(0,HUD_PRE+n,OBJPROP_TEXT,t); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_COLOR,c); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_FONTSIZE,s); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_ZORDER, 2001); }
void CrBtn(string n, int x, int y, int w, int h, string t, color bg, color tc=clrWhite) { ObjectCreate(0,HUD_PRE+n,OBJ_BUTTON,0,0,0); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YSIZE,h); ObjectSetString(0,HUD_PRE+n,OBJPROP_TEXT,t); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_COLOR,tc); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_ZORDER, 2002); }
void OnChartEvent(const int id, const long &lp, const double &dp, const string &sp) {
   if(id != CHARTEVENT_OBJECT_CLICK) return;
   if(sp == HUD_PRE+"b_min") { isMinimized = !isMinimized; CrearPanel(); }
   if(sp == HUD_PRE+"b_day") { currentPreset = PRESET_DIARIO; ApplyPreset(); CrearPanel(); }
   if(sp == HUD_PRE+"b_we") { currentPreset = PRESET_FINDE; ApplyPreset(); CrearPanel(); }
   if(sp == HUD_PRE+"b_zen") { currentMode = MODE_ZEN; CrearPanel(); }
   if(sp == HUD_PRE+"b_har") { currentMode = MODE_COSECHA; CrearPanel(); }
   if(sp == HUD_PRE+"b_mar") { currentExec = EXEC_MARKET; CrearPanel(); }
   if(sp == HUD_PRE+"b_lim") { currentExec = EXEC_LIMIT; CrearPanel(); }
   if(sp == HUD_PRE+"b_c") { currentDir = DIR_COMPRAS; CrearPanel(); }
   if(sp == HUD_PRE+"b_v") { currentDir = DIR_VENTAS; CrearPanel(); }
   if(sp == HUD_PRE+"b_a") { currentDir = DIR_AMBAS; CrearPanel(); }
   if(sp == HUD_PRE+"b_cl") { for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic()==InpMagic) trade.PositionClose(posInfo.Ticket()); CancelOrders(); } ObjectSetInteger(0, sp, OBJPROP_STATE, false);
}

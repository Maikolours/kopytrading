//+------------------------------------------------------------------+
//|                  00_ELITE_WARRIOR_STYLIZED_MASTER                |
//|      v40.10 - SYNCED MASTER | PERFECT DIAGONAL | HUD STABILITY   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrade Corp."
#property version   "40.10"
#property strict

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

//--- ENUMERACIONES
enum ENUM_MODE { MODE_ZEN, MODE_COSECHA };
enum ENUM_DIR  { DIR_COMPRAS, DIR_VENTAS, DIR_AMBAS };
enum ENUM_EXEC { EXEC_MARKET, EXEC_LIMIT };
enum ENUM_STATE { STATE_WAIT_BOS, STATE_WAIT_RETRACE, STATE_WAIT_CONFIRM };
enum ENUM_PRESET { PRESET_DIARIO, PRESET_FINDE };

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
input int             InpLkb_D         = 28;  
input int             InpBE_D          = 300; 
input int             InpLkb_WE        = 6;  
input int             InpBE_WE         = 200; 

input group "=== 🛡️ GESTIÓN DINÁMICA ==="
input int             InpTrail_Points  = 600; 
input int             InpTrail_Dist    = 250; 
input int             InpGatillo_Margin_Pts = 50; 
input int             InpCaza_Margin_Pts    = 150; 

input group "=== 🎨 ESTILO VISUAL ==="
input color           InpColor_Fibo    = clrGold;
input color           InpColor_Bull    = clrCyan;
input color           Incolor_Bear     = clrOrangeRed;

input group "=== 💵 RIESGO Y MAGIC ==="
input double          InpRisk          = 0.5;
input int             InpMagic         = 202900;

#define HUD_PRE "H_"
#define GRAF_PRE "V_"
#define FIBO_NAME "V_FIBO"

//--- GLOBALES
CTrade         trade;
CPositionInfo  posInfo;
ENUM_STATE     state = STATE_WAIT_BOS;
ENUM_MODE      currentMode = MODE_COSECHA;
ENUM_DIR       currentDir = DIR_AMBAS;
ENUM_EXEC      currentExec = EXEC_MARKET;
ENUM_PRESET    currentPreset = PRESET_DIARIO;

int            hEmaMacro, hEmaMid;
int            dirMacro=0, dirMid=0;
double         f100=0, f0=0, f23=0, f38=0, f61=0, f70=0, f78=0;
datetime       t100=0, t0=0;
bool           isMinimized=false, isManualMode=false;
bool           p1_pierced=false;
int            curLkb, curBE, curHours;
string         botStatus = "WARRIOR READY";
string         narrative = "Buscando oportunidad...";

//--- EVENTOS PRINCIPALES
int OnInit() {
   trade.SetExpertMagicNumber(InpMagic);
   hEmaMacro = iMA(_Symbol, InpTF_Macro, InpEMA, 0, MODE_EMA, PRICE_CLOSE);
   hEmaMid = iMA(_Symbol, InpTF_Mid, InpEMA, 0, MODE_EMA, PRICE_CLOSE);
   ApplyPreset();
   CrearPanel();
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) {
   ObjectsDeleteAll(0, HUD_PRE); ObjectsDeleteAll(0, GRAF_PRE); 
   if(hEmaMacro != INVALID_HANDLE) IndicatorRelease(hEmaMacro);
   if(hEmaMid != INVALID_HANDLE) IndicatorRelease(hEmaMid);
   EventKillTimer();
}

void ApplyPreset() {
   if(currentPreset == PRESET_DIARIO) { curHours = InpLkb_D; curBE = InpBE_D; }
   else { curHours = InpLkb_WE; curBE = InpBE_WE; }
   curLkb = (int)(curHours * 3600 / PeriodSeconds(InpTF_Mid));
   if(curLkb < 10) curLkb = 10;
}

void OnTick() {
   UpdateTrends();
   if(!isManualMode) DetectBOS(); else ManualBOSUpdate();
   if(CountActive() == 0) MonitorRetracement();
   ManageRisk();
   UpdatePanelText();
}

void OnTimer() {
   if(ObjectFind(0, HUD_PRE+"bg") < 0) CrearPanel();
   UpdatePanelText();
}

double GetMAValue(int handle) {
   double buffer[1];
   if(CopyBuffer(handle, 0, 0, 1, buffer) > 0) return buffer[0];
   return 0;
}

void UpdateTrends() {
   double emaM = GetMAValue(hEmaMacro);
   double emaH = GetMAValue(hEmaMid);
   dirMacro = (iClose(_Symbol, InpTF_Macro, 0) > emaM) ? 1 : -1;
   dirMid = (iClose(_Symbol, InpTF_Mid, 0) > emaH) ? 1 : -1;
}

void DetectBOS() {
   int hh = iHighest(_Symbol, InpTF_Mid, MODE_HIGH, curLkb, 1);
   int ll = iLowest(_Symbol, InpTF_Mid, MODE_LOW, curLkb, 1);
   double hi = iHigh(_Symbol, InpTF_Mid, hh), lo = iLow(_Symbol, InpTF_Mid, ll);
   datetime tHi = iTime(_Symbol, InpTF_Mid, hh);
   datetime tLo = iTime(_Symbol, InpTF_Mid, ll);
   
   bool bull = (dirMacro == 1); 
   bool validSwing = (bull && tLo < tHi) || (!bull && tHi < tLo);
   
   if(!validSwing) {
      f61 = 0; f100 = 0; f0 = 0;
      ObjectDelete(0, FIBO_NAME);
      ObjectDelete(0, GRAF_PRE+"WAVE");
      narrative = "⏳ ESPERANDO IMPULSO " + (bull ? "ALCISTA" : "BAJISTA") + " VÁLIDO";
      return;
   }
   
   f100 = bull ? lo : hi; t100 = bull ? tLo : tHi;
   f0 = bull ? hi : lo; t0 = bull ? tHi : tLo;
   DrawFibo(f100, f0, t100, t0, bull);
}

void ManualBOSUpdate() {
   if(ObjectFind(0, FIBO_NAME) < 0) return;
   f100 = ObjectGetDouble(0, FIBO_NAME, OBJPROP_PRICE, 0); t100 = (datetime)ObjectGetInteger(0, FIBO_NAME, OBJPROP_TIME, 0);
   f0 = ObjectGetDouble(0, FIBO_NAME, OBJPROP_PRICE, 1); t0 = (datetime)ObjectGetInteger(0, FIBO_NAME, OBJPROP_TIME, 1);
   DrawFibo(f100, f0, t100, t0, (f0 > f100));
}

void DrawFibo(double p100, double p0, datetime tm100, datetime tm0, bool bull) {
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
      for(int l=0; l<8; l++) ObjectSetInteger(0, FIBO_NAME, OBJPROP_LEVELCOLOR, l, InpColor_Fibo);
      ObjectSetInteger(0, FIBO_NAME, OBJPROP_COLOR, InpColor_Fibo);
   }
   if(!isManualMode) { ObjectMove(0, FIBO_NAME, 0, tm100, p100); ObjectMove(0, FIBO_NAME, 1, tm0, p0); }
   f23 = bull ? p0-(p0-p100)*0.236 : p0+(p100-p0)*0.236; f38 = bull?p0-(p0-p100)*0.382:p0+(p100-p0)*0.382; f61 = bull?p0-(p0-p100)*0.618:p0+(p100-p0)*0.618; f70 = bull?p0-(p0-p100)*0.705:p0+(p100-p0)*0.705; f78 = bull?p0-(p0-p100)*0.786:p0+(p100-p0)*0.786;
   
   string wav = GRAF_PRE+"WAVE";
   if(ObjectFind(0,wav)<0) { ObjectCreate(0,wav,OBJ_TREND,0,0,0,0,0); ObjectSetInteger(0,wav,OBJPROP_STYLE,STYLE_DOT); ObjectSetInteger(0,wav,OBJPROP_WIDTH,2); }
   ObjectSetInteger(0,wav,OBJPROP_BACK,true);
   ObjectMove(0,wav,0,ObjectGetInteger(0,FIBO_NAME,OBJPROP_TIME,0),p100); ObjectMove(0,wav,1,ObjectGetInteger(0,FIBO_NAME,OBJPROP_TIME,1),p0);
   ObjectSetInteger(0,wav,OBJPROP_COLOR,(bull?InpColor_Bull:Incolor_Bear)); ObjectSetInteger(0,FIBO_NAME,OBJPROP_SELECTABLE,isManualMode);
}

void MonitorRetracement() {
   if(f61==0) return; double cp = iClose(_Symbol, 0, 0); bool bull = (f0 > f100); 
   double ps = (_Digits<=2?1.0:(_Digits==3||_Digits==5?10.0*_Point:_Point));
   if(bull) {
      if(cp <= f38 + InpCaza_Margin_Pts*ps) p1_pierced = true;
      if(p1_pierced) {
         narrative = "🎯 GATILLO LISTO (M5 Alcista en " + DoubleToString(f61,_Digits) + ")";
         if(cp <= f61 + InpGatillo_Margin_Pts*ps && iClose(_Symbol,InpTF_Exec,1)>iOpen(_Symbol,InpTF_Exec,1)) ExecuteMarket(true);
      } else narrative = "🏹 CAZANDO RETROCESO A " + DoubleToString(f38,_Digits);
   } else {
      if(cp >= f38 - InpCaza_Margin_Pts*ps) p1_pierced = true;
      if(p1_pierced) {
         narrative = "🎯 GATILLO LISTO (M5 Bajista en " + DoubleToString(f61,_Digits) + ")";
         if(cp >= f61 - InpGatillo_Margin_Pts*ps && iClose(_Symbol,InpTF_Exec,1)<iOpen(_Symbol,InpTF_Exec,1)) ExecuteMarket(false);
      } else narrative = "🏹 CAZANDO RETROCESO A " + DoubleToString(f38,_Digits);
   }
}

void ExecuteMarket(bool bull) {
   double riskVal = AccountInfoDouble(ACCOUNT_BALANCE) * (InpRisk/100.0);
   double cp = SymbolInfoDouble(_Symbol, bull ? SYMBOL_ASK : SYMBOL_BID);
   double slDistRaw = MathAbs(f100 - cp);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   
   double slDistTicks = slDistRaw / tickSize;
   if(slDistTicks <= 0) slDistTicks = 1;
   
   double lot = riskVal / (slDistTicks * tickValue);
   
   double minL = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN); 
   double maxL = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepL = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   lot = MathFloor(lot/stepL)*stepL;
   lot = MathMax(minL, MathMin(maxL, lot));
   
   if(bull) trade.Buy(lot,_Symbol,0,f100,f0); else trade.Sell(lot,_Symbol,0,f100,f0); p1_pierced=false;
}

void ManageRisk() {
   double ps = (_Digits<=2?1.0:(_Digits==3||_Digits==5?10.0*_Point:_Point));
   for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic()==InpMagic) {
      double op=posInfo.PriceOpen(), cur=posInfo.PriceCurrent(), sl=posInfo.StopLoss(), tp=posInfo.TakeProfit(); bool buy=(posInfo.PositionType()==POSITION_TYPE_BUY);
      double pnl = buy ? (cur-op)/_Point : (op-cur)/_Point;
      if(pnl >= curBE && (sl==0 || (buy && sl<op) || (!buy && sl>op))) trade.PositionModify(posInfo.Ticket(), op + (buy?10:-10)*ps, tp);
      if(pnl >= InpTrail_Points) {
         double nsl = buy ? cur-InpTrail_Dist*ps : cur+InpTrail_Dist*ps;
         if((buy && nsl > sl + 20*ps) || (!buy && (nsl < sl - 20*ps || (sl==0)))) trade.PositionModify(posInfo.Ticket(), nsl, tp);
      }
   }
}

void CrearPanel() {
   ObjectsDeleteAll(0, HUD_PRE); int x=15, y=30, w=355, h=isMinimized ? 45 : 650;
   CrRect("bg", x, y, w, h, C'18,10,10', clrMaroon); CrRect("hdr", x+2, y+2, w-4, 40, clrMaroon, clrRed);
   CrLabel("ttl", x+15, y+8, "ELITE WARRIOR MASTER v40.10", clrWhite, 10);
   CrLabel("clk", x+w-120, y+8, "[00:00]", clrGold, 10);
   CrBtn("b_min", x+w-35, y+2, 25, 25, isMinimized ? "[+]" : "[-]", clrMaroon);
   if(!isMinimized) {
      CrRect("pl_bg", x+10, y+75, w-20, 115, clrBlack, clrMaroon);
      CrLabel("pl_t", x+20, y+80, "🎯 ESTRATEGIA WARRIOR PREDATOR:", clrOrangeRed, 7);
      CrLabel("planA", x+25, y+100, narrative, clrWhite, 7);
      CrLabel("vis", x+25, y+115, "VISIÓN: " + (string)curHours + "h | PROTECCIÓN: " + (string)curBE + "pts", clrGray, 7);
      CrBtn("b_mod_a", x+10, y+195, 165, 30, "AUTO [H]", !isManualMode?clrCyan:clrCrimson);
      CrBtn("b_mod_m", x+180, y+195, 165, 30, "MANUAL [M]", isManualMode?clrCyan:clrCrimson);
      CrBtn("b_day", x+10, y+230, 165, 30, "MODO DIARIO", currentPreset==PRESET_DIARIO?clrCyan:clrCrimson);
      CrBtn("b_we", x+180, y+230, 165, 30, "MODO FINDE", currentPreset==PRESET_FINDE?clrCyan:clrCrimson);
      CrRect("ote_bg", x+10, y+270, w-20, 120, clrBlack, clrGold);
      CrLabel("ote_t", x+20, y+275, "🏹 RED DE CAZA ACTIVADA:", clrGold, 7);
      CrLabel("oteX", x+25, y+295, "IMPULSO (23.6%): " + DoubleToString(f23,_Digits), clrWhite, 7);
      CrLabel("ote0", x+25, y+308, "IMPULSO (38.2%): " + DoubleToString(f38,_Digits), clrWhite, 7);
      CrLabel("ote1", x+25, y+321, "OTE 1 (61.8%): " + DoubleToString(f61,_Digits), clrWhite, 7);
      CrLabel("ote2", x+25, y+334, "OTE 2 (70.5%): " + DoubleToString(f70,_Digits), clrWhite, 7);
      CrLabel("ote3", x+25, y+347, "OTE 3 (78.6%): " + DoubleToString(f78,_Digits), clrWhite, 7);
      CrLabel("stV", x+15, y+400, (CountActive()>0?"ESTADO: PROTEGIENDO 🛡️":"WARRIOR READY"), clrWhite, 9);
      CrLabel("tr4", x+15, y+425, "BIAS MACRO (1H): " + (dirMacro==1?"ALCISTA ▲":"BAJISTA ▼"), (dirMacro==1?clrCyan:clrOrangeRed), 8);
      CrLabel("tr1", x+15, y+445, "ESTRUCTURA (M15): " + (dirMid==1?"ALCISTA ▲":"BAJISTA ▼"), (dirMid==1?clrCyan:clrOrangeRed), 8);
      CrBtn("b_zen", x+10, y+480, 165, 30, "MODO ZEN", currentMode==MODE_ZEN?clrCyan:clrCrimson);
      CrBtn("b_har", x+180, y+480, 165, 30, "COSECHA", currentMode==MODE_COSECHA?clrCyan:clrCrimson);
      CrBtn("b_mar", x+10, y+515, 165, 30, "MERCADO (Gatillo)", currentExec==EXEC_MARKET?clrCyan:clrCrimson);
      CrBtn("b_lim", x+180, y+515, 165, 30, "AUTO (Zonas)", currentExec==EXEC_LIMIT?clrCyan:clrCrimson);
      CrBtn("b_c", x+10, y+550, 108, 30, "COMPRA", currentDir==DIR_COMPRAS?clrCyan:clrCrimson);
      CrBtn("b_a", x+123, y+550, 108, 30, "AMBAS", currentDir==DIR_AMBAS?clrCyan:clrCrimson);
      CrBtn("b_v", x+236, y+550, 108, 30, "VENTA", currentDir==DIR_VENTAS?clrCyan:clrCrimson);
      CrBtn("b_cl", x+10, y+595, 335, 45, "CERRAR TODO (PANIC)", clrRed);
   }
}

void UpdatePanelText() {
   if(isMinimized) return;
   long sec = (long)iTime(_Symbol,InpTF_Exec,0) + (long)PeriodSeconds(InpTF_Exec) - (long)TimeCurrent(); if(sec < 0) sec = 0;
   ObjectSetString(0,HUD_PRE+"clk",OBJPROP_TEXT,StringFormat("[%02d:%02d]", sec/60, sec%60));
   ObjectSetString(0,HUD_PRE+"planA",OBJPROP_TEXT,narrative);
   ObjectSetString(0,HUD_PRE+"oteX",OBJPROP_TEXT,"IMPULSO (23.6%): " + DoubleToString(f23,_Digits));
   ObjectSetString(0,HUD_PRE+"ote0",OBJPROP_TEXT,"IMPULSO (38.2%): " + DoubleToString(f38,_Digits));
   ObjectSetString(0,HUD_PRE+"ote1",OBJPROP_TEXT,"OTE 1 (61.8%): " + DoubleToString(f61,_Digits));
   ObjectSetString(0,HUD_PRE+"ote2",OBJPROP_TEXT,"OTE 2 (70.5%): " + DoubleToString(f70,_Digits));
   ObjectSetString(0,HUD_PRE+"ote3",OBJPROP_TEXT,"OTE 3 (78.6%): " + DoubleToString(f78,_Digits));
}

void CrRect(string n, int x, int y, int w, int h, color bg, color bd=clrGray) { ObjectCreate(0,HUD_PRE+n,OBJ_RECTANGLE_LABEL,0,0,0); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YSIZE,h); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_COLOR,bd); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_BORDER_TYPE,BORDER_FLAT); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_ZORDER,10); }
void CrLabel(string n, int x, int y, string t, color c, int s) { ObjectCreate(0,HUD_PRE+n,OBJ_LABEL,0,0,0); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YDISTANCE,y); ObjectSetString(0,HUD_PRE+n,OBJPROP_TEXT,t); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_COLOR,c); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_FONTSIZE,s); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_ZORDER,15); }
void CrBtn(string n, int x, int y, int w, int h, string t, color bg) { ObjectCreate(0,HUD_PRE+n,OBJ_BUTTON,0,0,0); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YSIZE,h); ObjectSetString(0,HUD_PRE+n,OBJPROP_TEXT,t); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_COLOR,clrWhite); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_ZORDER,12); }

void OnChartEvent(const int id, const long &lp, const double &dp, const string &sp) {
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sp == HUD_PRE+"b_min") { isMinimized = !isMinimized; CrearPanel(); }
      if(sp == HUD_PRE+"b_mod_a") { isManualMode = false; ApplyPreset(); DetectBOS(); CrearPanel(); }
      if(sp == HUD_PRE+"b_mod_m") { isManualMode=true; ObjectSetInteger(0, FIBO_NAME, OBJPROP_SELECTABLE, true); ObjectSetInteger(0, FIBO_NAME, OBJPROP_SELECTED, true); CrearPanel(); ChartRedraw(); }
      if(sp == HUD_PRE+"b_day") { currentPreset = PRESET_DIARIO; ApplyPreset(); DetectBOS(); CrearPanel(); }
      if(sp == HUD_PRE+"b_we") { currentPreset = PRESET_FINDE; ApplyPreset(); DetectBOS(); CrearPanel(); }
      if(sp == HUD_PRE+"b_zen") { currentMode = MODE_ZEN; CrearPanel(); }
      if(sp == HUD_PRE+"b_har") { currentMode = MODE_COSECHA; CrearPanel(); }
      if(sp == HUD_PRE+"b_mar") { currentExec = EXEC_MARKET; CrearPanel(); }
      if(sp == HUD_PRE+"b_lim") { currentExec = EXEC_LIMIT; CrearPanel(); }
      if(sp == HUD_PRE+"b_c") { currentDir = DIR_COMPRAS; CrearPanel(); }
      if(sp == HUD_PRE+"b_a") { currentDir = DIR_AMBAS; CrearPanel(); }
      if(sp == HUD_PRE+"b_v") { currentDir = DIR_VENTAS; CrearPanel(); }
      if(sp == HUD_PRE+"b_cl") { for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic()==InpMagic) trade.PositionClose(posInfo.Ticket()); } ObjectSetInteger(0, sp, OBJPROP_STATE, false);
   }
   if(id == CHARTEVENT_OBJECT_DRAG && (sp == FIBO_NAME) && isManualMode) { ManualBOSUpdate(); }
}
int CountActive() { int c=0; for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic()==InpMagic) c++; return c; }
int CountOrders() { int c=0; for(int i=OrdersTotal()-1; i>=0; i--) { ulong t=OrderGetTicket(i); if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC)==InpMagic) c++; } return c; }

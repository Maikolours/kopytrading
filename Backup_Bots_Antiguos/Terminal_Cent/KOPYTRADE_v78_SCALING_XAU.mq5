//+------------------------------------------------------------------+
//|     KOPYTRADE_v78_SCALING_XAU.mq5                                |
//|   XAU AUTO-FIBO MATRIX | sniper v7.9.3 | PRECISION MASTERPIECE  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "7.93"
#property strict
#property description "⚜️ XAU v7.9.3 PRECISION | ANCHORED FIBO & BLIND HUD"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- DEFINES ---
#define P_TAG "AEV79_"
#define CLR_GOLD C'212,175,55'
#define CLR_PANEL C'10,10,14'
#define CLR_GP_SOFT C'45,25,5'  // Ocre sepia profundo/suave
#define CLR_BLUE C'30,144,255'

//--- PARÁMETROS ---
input group "🛡️ SEGURIDAD Y LICENCIA"
input string   LicenciaKey       = "TRIAL-2023"; 
input long     CuentaAutorizada  = 0;            
input bool     ActivarNewsFilter = true;         
input bool     ForceCentMode     = true;         
input double   CentFactor        = 0.01;         

input group "== CONFIGURACIÓN XAU v7.9.3 =="
input int      FiboHorasRango    = 8;            
input double   LotesBase         = 0.04;         
input double   BreakEvenUSD      = 1.00;         
input double   TrailingStopUSD   = 2.50;         
input double   TrailGarantia     = 0.25;         
input bool     PermitirRefuerzo  = false;        

//--- GLOBALES ---
CTrade         trade;
CPositionInfo  pos;
int            h_ema20, h_ema50, h_rsi;
double         profitFactor = 1.0, dayPnL = 0;
string         strategyLabel = "ESPERANDO";
bool           remotePaused = false, isBullish = true, isMinimized = false;
bool           showEMA=true, showRSI=true, showFibo=true, useConfirmBar=true, useScaling=false;
bool           giroOn=true, refuerzoOn=false;
double         f_p0=0, f_p100=0, f_p38=0, f_p50=0, f_p61=0;
datetime       f_t0, f_t100;
double         currLots, currBE, currTS, currSLPct=70.7, currGarantia=0.25;
int            currFiboHours;

//+------------------------------------------------------------------+
//| Init                                                             |
//+------------------------------------------------------------------+
int OnInit() {
   ChartSetInteger(0, CHART_FOREGROUND, false); 
   trade.SetExpertMagicNumber(780001);
   profitFactor = ForceCentMode ? CentFactor : 1.0;
   currLots = LotesBase; currFiboHours = fmax(1, FiboHorasRango);
   currBE = BreakEvenUSD; currTS = TrailingStopUSD; currGarantia = TrailGarantia;
   useScaling = PermitirRefuerzo; refuerzoOn=useScaling;
   h_ema20 = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   h_ema50 = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
   h_rsi   = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   LoadSettings(); EventSetTimer(1); CrearHUD(); UpdateAutoFibo();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) { SaveSettings(); ObjectsDeleteAll(0, P_TAG); }
void OnTimer() { if(ActivarNewsFilter) CheckRemoteNews(); else remotePaused = false; }

void OnTick() {
   UpdateAutoFibo(); ManageStrategy(); ProtectPositions();
   dayPnL = CalculateFullDayPnL(); ActualizarHUD();
}

void UpdateAutoFibo() {
   if(PositionsTotalBots() > 0 && !useScaling) return;
   int bars = currFiboHours * (3600/PeriodSeconds()); if(bars<20) bars=100;
   int hiIdx = iHighest(_Symbol, _Period, MODE_HIGH, bars, 0);
   int liIdx = iLowest(_Symbol, _Period, MODE_LOW, bars, 0);
   double vHi = iHigh(_Symbol, _Period, hiIdx), vLi = iLow(_Symbol, _Period, liIdx);
   if(hiIdx > liIdx) { f_p100 = vHi; f_t100 = iTime(_Symbol, _Period, hiIdx); f_p0 = vLi; f_t0 = iTime(_Symbol, _Period, liIdx); isBullish = false; }
   else { f_p100 = vLi; f_t100 = iTime(_Symbol, _Period, liIdx); f_p0 = vHi; f_t0 = iTime(_Symbol, _Period, hiIdx); isBullish = true; }
   double diff = f_p0 - f_p100;
   f_p38 = f_p100 + diff * 0.382; f_p50 = f_p100 + diff * 0.500; f_p61 = f_p100 + diff * 0.618;
   if(showFibo) DrawFiboVisuals(); else { ObjectsDeleteAll(0, P_TAG+"fibo"); ObjectsDeleteAll(0, P_TAG+"zone"); }
   DrawInteractiveLines();
}

void DrawFiboVisuals() {
   string n = P_TAG+"fibo";
   if(ObjectFind(0,n)<0) ObjectCreate(0,n,OBJ_FIBO,0,f_t100,f_p100,f_t0,f_p0);
   ObjectSetInteger(0,n,OBJPROP_TIME,0,f_t100); ObjectSetDouble(0,n,OBJPROP_PRICE,0,f_p100);
   ObjectSetInteger(0,n,OBJPROP_TIME,1,f_t0); ObjectSetDouble(0,n,OBJPROP_PRICE,1,f_p0);
   ObjectSetInteger(0,n,OBJPROP_RAY_RIGHT,true); ObjectSetInteger(0,n,OBJPROP_BACK, true); 
   ObjectSetInteger(0,n,OBJPROP_COLOR,clrAqua); 
   ObjectSetInteger(0,n,OBJPROP_LEVELS,7);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,0,0.0); ObjectSetString(0,n,OBJPROP_LEVELTEXT,0,"🎯 TP (0.0)");
   ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,0,clrLime);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,1,0.214); ObjectSetString(0,n,OBJPROP_LEVELTEXT,1,"🔔 REV (21.4)");
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,2,0.382); ObjectSetString(0,n,OBJPROP_LEVELTEXT,2,"ENTRY (38.2)");
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,3,0.500); ObjectSetString(0,n,OBJPROP_LEVELTEXT,3,"CENTER (50.0)");
   ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,3,CLR_BLUE);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,4,0.618); ObjectSetString(0,n,OBJPROP_LEVELTEXT,4,"🏆 GOLD 61.8");
   ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,4,clrOrange);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,5,currSLPct/100.0); ObjectSetString(0,n,OBJPROP_LEVELTEXT,5,"🛑 STOP ("+DoubleToString(currSLPct,1)+")");
   ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,5,clrWhite);
   string z = P_TAG+"zone";
   if(ObjectFind(0,z)<0) { ObjectCreate(0,z,OBJ_RECTANGLE,0,f_t100,f_p38,f_t0,f_p61); ObjectSetInteger(0,z,OBJPROP_FILL,true); ObjectSetInteger(0,z,OBJPROP_BACK,true); }
   ObjectSetInteger(0,z,OBJPROP_TIME,0,f_t100); ObjectSetDouble(0,z,OBJPROP_PRICE,0,f_p38);
   ObjectSetInteger(0,z,OBJPROP_TIME,1,TimeCurrent()+3600*12); ObjectSetDouble(0,z,OBJPROP_PRICE,1,f_p61);
   ObjectSetInteger(0,z,OBJPROP_COLOR,CLR_GP_SOFT);
}

void DrawInteractiveLines() {
   string slN=P_TAG+"SL", tpN=P_TAG+"TP";
   double prSL = f_p100 + (f_p0 - f_p100) * (currSLPct/100.0);
   datetime tStart; double pDummy; int subW;
   ChartXYToTimePrice(0, 400, 0, subW, tStart, pDummy); 
   if(ObjectFind(0,slN)<0) { ObjectCreate(0,slN,OBJ_TREND,0,tStart,prSL,TimeCurrent()+3600*24,prSL); ObjectSetInteger(0,slN,OBJPROP_COLOR,clrRed); ObjectSetInteger(0,slN,OBJPROP_WIDTH,2); ObjectSetInteger(0,slN,OBJPROP_RAY_RIGHT,true); ObjectSetInteger(0,slN,OBJPROP_SELECTABLE,true); }
   if(!ObjectGetInteger(0,slN,OBJPROP_SELECTED)) { ObjectSetInteger(0,slN,OBJPROP_TIME,0,tStart); ObjectSetDouble(0,slN,OBJPROP_PRICE,0,prSL); ObjectSetDouble(0,slN,OBJPROP_PRICE,1,prSL); }
   if(ObjectFind(0,tpN)<0) { ObjectCreate(0,tpN,OBJ_TREND,0,tStart,f_p0,TimeCurrent()+3600*24,f_p0); ObjectSetInteger(0,tpN,OBJPROP_COLOR,clrForestGreen); ObjectSetInteger(0,tpN,OBJPROP_STYLE,STYLE_DOT); ObjectSetInteger(0,tpN,OBJPROP_RAY_RIGHT,true); ObjectSetInteger(0,tpN,OBJPROP_SELECTABLE,true); }
   if(!ObjectGetInteger(0,tpN,OBJPROP_SELECTED)) { ObjectSetInteger(0,tpN,OBJPROP_TIME,0,tStart); ObjectSetDouble(0,tpN,OBJPROP_PRICE,0,f_p0); ObjectSetDouble(0,tpN,OBJPROP_PRICE,1,f_p0); }
}

void ManageStrategy() {
   double rsi[1], ema20[1], ema50[1]; CopyBuffer(h_rsi,0,0,1,rsi); CopyBuffer(h_ema20,0,0,1,ema20); CopyBuffer(h_ema50,0,0,1,ema50);
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double totD = MathAbs(f_p0 - f_p100);
   double pct = (totD>0) ? (MathAbs(price - f_p100)/totD)*100 : 0;
   bool inV = (pct >= 38.2 && pct <= 61.8);
   strategyLabel = (isBullish ? "XAU ALCISTA" : "XAU BAJISTA") + (inV ? " (ZONA)" : "");
   if(AccountInfoInteger(ACCOUNT_TRADE_EXPERT) && !remotePaused && inV && (PositionsTotalBots()==0 || (useScaling && IsFirstTradeSecured()))) {
       double sl = ObjectGetDouble(0, P_TAG+"SL", OBJPROP_PRICE, 0);
       if(isBullish && ema20[0] > ema50[0]) trade.Buy(currLots,_Symbol,SymbolInfoDouble(_Symbol,SYMBOL_ASK),sl,0);
       if(!isBullish && ema20[0] < ema50[0]) trade.Sell(currLots,_Symbol,SymbolInfoDouble(_Symbol,SYMBOL_BID),sl,0);
   }
}

bool IsFirstTradeSecured() {
   int count=0; bool sec=false;
   for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==780001) { count++; if((pos.PositionType()==POSITION_TYPE_BUY && pos.StopLoss() >= pos.PriceOpen()) || (pos.PositionType()==POSITION_TYPE_SELL && pos.StopLoss() <= pos.PriceOpen())) sec=true; }
   return (count == 1 && sec);
}

void ProtectPositions() {
   double slLine = ObjectGetDouble(0, P_TAG+"SL", OBJPROP_PRICE, 0);
   for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==780001) {
      double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID), ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK), pUSD = (pos.Profit()+pos.Swap()+pos.Commission())*profitFactor, newSL = pos.StopLoss(), openP = pos.PriceOpen();
      if(pos.PositionType()==POSITION_TYPE_BUY) { if(pUSD > currBE && (newSL < openP || newSL==0)) newSL = openP + currGarantia; if(pUSD > currTS && (bid-currTS) > newSL) newSL = bid-currTS; if(slLine > newSL) newSL = slLine; }
      else { if(pUSD > currBE && (newSL > openP || newSL==0)) newSL = openP - currGarantia; if(pUSD > currTS && (ask+currTS) < newSL) newSL = ask+currTS; if(slLine < newSL && slLine != 0) newSL = slLine; }
      if(MathAbs(newSL - pos.StopLoss()) > _Point) trade.PositionModify(pos.Ticket(), NormalizeDouble(newSL, _Digits), 0);
   }
}

void CrearHUD() {
   ObjectsDeleteAll(0, P_TAG); ChartSetInteger(0, CHART_FOREGROUND, false);
   int hx=15, hy=15, hw=365, hh=isMinimized ? 40 : 650;
   CrRect("bg",hx,hy,hw,hh,CLR_PANEL,CLR_GOLD, 1500); 
   CrLabel("ttl",hx+15,hy+13,isMinimized?"⚜️ XAU ELITE":"⚜️ MASTERPIECE ELITE v7.9.3",CLR_GOLD,11,"Impact", 1600);
   CrBtn("b_min",hx+hw-35,hy+10,25,20,isMinimized ? "[+]" : "[-]",C'60,60,80',clrWhite, 1700);
   if(isMinimized) return;
   CrLabel("pV",hx+15,hy+65,"PnL HOY (USD): "+DoubleToString(dayPnL,2)+" $",clrWhite,10,"Arial Bold", 1600);
   CrBtn("b_rst",hx+hw-65,hy+62,50,22,"RESET",C'60,60,80',clrWhite, 1700);
   CrLabel("stV",hx+15,hy+95,"MODO: "+strategyLabel,clrCyan,10,"Arial Bold", 1600);
   CrBtn("b_zen",hx+10,hy+145,168,35,"ZEN (24h)",C'50,55,75',clrWhite, 1700); 
   CrBtn("b_har",hx+182,hy+145,168,35,"COSECHA (8h)",C'70,45,25',clrWhite, 1700);
   int ry=205, c1=hx+15, c2=hx+235;
   CrLabel("l_lot",c1,ry+3,"Lotes Oro:",clrSilver,9,"Arial", 1600); CrEdit("e_lot",c2,ry,50,22,DoubleToString(currLots,2), 1700); ry+=35;
   CrLabel("l_fib",c1,ry+3,"Fibo Horas:",clrSilver,9,"Arial", 1600); CrEdit("e_fib",c2,ry,50,22,IntegerToString(currFiboHours), 1700); ry+=35;
   CrLabel("l_be",c1,ry+3,"Break-Even ($):",clrSilver,9,"Arial", 1600); CrEdit("e_be",c2,ry,50,22,DoubleToString(currBE,2), 1700); ry+=35;
   CrLabel("l_gar",c1,ry+3,"GARANTÍA ($):",CLR_GOLD,9,"Arial Bold", 1600); CrEdit("e_gar",c2,ry,50,22,DoubleToString(currGarantia,2), 1700); ry+=35;
   CrLabel("l_ts",c1,ry+3,"Trailing ($):",clrSilver,9,"Arial", 1600); CrEdit("e_ts",c2,ry,50,22,DoubleToString(currTS,2), 1700); ry+=35;
   CrLabel("l_slp",c1,ry+3,"Stop %:",clrRed,9,"Arial", 1600); CrEdit("e_slp",c2,ry,50,22,DoubleToString(currSLPct,1), 1700); ry+=45;
   CrBtn("v_ma",hx+10,ry,113,32,"EMA",showEMA?CLR_BLUE:C'40,40,40',clrWhite,1700);
   CrBtn("v_rsi",hx+126,ry,113,32,"RSI",showRSI?C'150,80,40':C'40,40,40',clrWhite,1700);
   CrBtn("v_fib",hx+242,ry,113,32,"FIBO",showFibo?CLR_GOLD:C'40,40,40',clrWhite,1700); ry+=45;
   CrBtn("b_giro",hx+10,ry,hw/2-15,35,"GIRO: "+(giroOn?"ON":"OFF"),giroOn?clrGreen:clrRed,clrWhite,1700);
   CrBtn("b_ref",hx+hw/2+5,ry,hw/2-15,35,"REFUERZO: "+(refuerzoOn?"ON":"OFF"),refuerzoOn?clrGreen:clrRed,clrWhite,1700); ry+=50;
   CrBtn("b_app",hx+10,ry,hw-20,42,"APLICAR CAMBIOS",C'40,80,150',clrWhite,1700); ry+=52;
   CrBtn("b_cls",hx+10,ry,hw-20,42,"CERRAR TODO",C'150,40,40',clrWhite,1700);
   ActualizarHUD();
}

void ActualizarHUD() { if(ObjectFind(0,P_TAG+"pV")>=0) ObjectSetString(0,P_TAG+"pV",OBJPROP_TEXT,"PnL HOY (USD): "+DoubleToString(dayPnL,2)+" $"); }

void OnChartEvent(const int id,const long &lp,const double &dp,const string &sp) {
   if(id==CHARTEVENT_OBJECT_CLICK) {
      if(sp==P_TAG+"b_app") { SaveSettings(); UpdateAutoFibo(); CrearHUD(); }
      if(sp==P_TAG+"b_min") { isMinimized=!isMinimized; CrearHUD(); }
      if(sp==P_TAG+"b_zen") { currLots=0.08; currFiboHours=24; SaveSettings(); CrearHUD(); UpdateAutoFibo(); }
      if(sp==P_TAG+"b_har") { currLots=0.04; currFiboHours=8; SaveSettings(); CrearHUD(); UpdateAutoFibo(); }
      if(sp==P_TAG+"v_ma")  { showEMA=!showEMA; CrearHUD(); }
      if(sp==P_TAG+"v_rsi") { showRSI=!showRSI; CrearHUD(); }
      if(sp==P_TAG+"v_fib") { showFibo=!showFibo; UpdateAutoFibo(); CrearHUD(); }
      if(sp==P_TAG+"b_giro") { giroOn=!giroOn; CrearHUD(); }
      if(sp==P_TAG+"b_ref")  { refuerzoOn=!refuerzoOn; useScaling=refuerzoOn; CrearHUD(); }
      if(sp==P_TAG+"b_cls")  { for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==780001) trade.PositionClose(pos.Ticket()); }
      ObjectSetInteger(0,sp,OBJPROP_STATE,false);
   }
   if(id==CHARTEVENT_OBJECT_DRAG && (sp==P_TAG+"SL" || sp==P_TAG+"TP")) {
      double p = ObjectGetDouble(0, sp, OBJPROP_PRICE, 0); 
      if(sp==P_TAG+"SL") {
         double totD = MathAbs(f_p100-f_p0);
         if(totD>0) { currSLPct = (MathAbs(p-f_p100)/totD)*100; ObjectSetString(0, P_TAG+"e_slp", OBJPROP_TEXT, DoubleToString(currSLPct, 1)); SaveSettings(); }
         ObjectSetDouble(0, sp, OBJPROP_PRICE, 1, p); 
      }
      if(sp==P_TAG+"TP") ObjectSetDouble(0, sp, OBJPROP_PRICE, 1, p);
   }
   if(id==CHARTEVENT_OBJECT_ENDEDIT) {
      if(sp==P_TAG+"e_lot") currLots = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==P_TAG+"e_fib") currFiboHours = (int)StringToInteger(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==P_TAG+"e_be")  currBE = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==P_TAG+"e_gar") currGarantia = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==P_TAG+"e_ts")  currTS = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==P_TAG+"e_slp") currSLPct = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      SaveSettings();
   }
}

void CrRect(string n,int x,int y,int w,int h,color bg,color bd,int z=200){ ObjectCreate(0,P_TAG+n,OBJ_RECTANGLE_LABEL,0,0,0); ObjectSetInteger(0,P_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,P_TAG+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,P_TAG+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,P_TAG+n,OBJPROP_YSIZE,h); ObjectSetInteger(0,P_TAG+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,P_TAG+n,OBJPROP_COLOR,bd); ObjectSetInteger(0,P_TAG+n,OBJPROP_ZORDER,z); }
void CrLabel(string n,int x,int y,string t,color c,int s,string f="Arial",int z=210){ ObjectCreate(0,P_TAG+n,OBJ_LABEL,0,0,0); ObjectSetInteger(0,P_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,P_TAG+n,OBJPROP_YDISTANCE,y); ObjectSetString(0,P_TAG+n,OBJPROP_TEXT,t); ObjectSetInteger(0,P_TAG+n,OBJPROP_COLOR,c); ObjectSetInteger(0,P_TAG+n,OBJPROP_FONTSIZE,s); ObjectSetString(0,P_TAG+n,OBJPROP_FONT,f); ObjectSetInteger(0,P_TAG+n,OBJPROP_ZORDER,z); }
void CrBtn(string n,int x,int y,int w,int h,string t,color bg,color tc,int z=220){ ObjectCreate(0,P_TAG+n,OBJ_BUTTON,0,0,0); ObjectSetInteger(0,P_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,P_TAG+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,P_TAG+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,P_TAG+n,OBJPROP_YSIZE,h); ObjectSetString(0,P_TAG+n,OBJPROP_TEXT,t); ObjectSetInteger(0,P_TAG+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,P_TAG+n,OBJPROP_COLOR,tc); ObjectSetInteger(0,P_TAG+n,OBJPROP_ZORDER,z); }
void CrEdit(string n,int x,int y,int w,int h,string t,int z=220){ ObjectCreate(0,P_TAG+n,OBJ_EDIT,0,0,0); ObjectSetInteger(0,P_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,P_TAG+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,P_TAG+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,P_TAG+n,OBJPROP_YSIZE,h); ObjectSetString(0,P_TAG+n,OBJPROP_TEXT,t); ObjectSetInteger(0,P_TAG+n,OBJPROP_BGCOLOR,C'25,25,35'); ObjectSetInteger(0,P_TAG+n,OBJPROP_COLOR,clrWhite); ObjectSetInteger(0,P_TAG+n,OBJPROP_ZORDER,z); ObjectSetInteger(0,P_TAG+n,OBJPROP_ALIGN,ALIGN_CENTER); }
double CalculateFullDayPnL() { MqlDateTime dt; TimeToStruct(TimeCurrent(), dt); dt.hour=0; dt.min=0; dt.sec=0; HistorySelect(StructToTime(dt), TimeCurrent()); double p=0; for(int i=HistoryDealsTotal()-1; i>=0; i--) { ulong t=HistoryDealGetTicket(i); if(HistoryDealGetString(t, DEAL_SYMBOL) == _Symbol && HistoryDealGetInteger(t, DEAL_MAGIC) == 780001) p += HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_SWAP) + HistoryDealGetDouble(t, DEAL_COMMISSION); } return p * profitFactor; }
int PositionsTotalBots() { int c=0; for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==780001) c++; return c; }
void CheckRemoteNews() { char data[], res[]; string h; int s = WebRequest("GET","https://kopytrading.com/api/news-filter",NULL,NULL,500,data,0,res,h); if(s==200) remotePaused = (StringFind(CharArrayToString(res),"PAUSE")>=0); }
void LoadSettings() { string m=IntegerToString(780001); if(GlobalVariableCheck(P_TAG+"lots"+m)) currLots=GlobalVariableGet(P_TAG+"lots"+m); if(GlobalVariableCheck(P_TAG+"be"+m)) currBE=GlobalVariableGet(P_TAG+"be"+m); if(GlobalVariableCheck(P_TAG+"slp"+m)) currSLPct=GlobalVariableGet(P_TAG+"slp"+m); if(GlobalVariableCheck(P_TAG+"fh"+m)) currFiboHours=(int)GlobalVariableGet(P_TAG+"fh"+m); }
void SaveSettings() { string m=IntegerToString(780001); GlobalVariableSet(P_TAG+"lots"+m,currLots); GlobalVariableSet(P_TAG+"be"+m,currBE); GlobalVariableSet(P_TAG+"slp"+m,currSLPct); GlobalVariableSet(P_TAG+"fh"+m,currFiboHours); }

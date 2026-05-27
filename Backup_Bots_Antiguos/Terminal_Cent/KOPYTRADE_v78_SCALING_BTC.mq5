//+------------------------------------------------------------------+
//|     KOPYTRADE_v78_SCALING_BTC.mq5                                |
//|   BTC AUTO-FIBO MATRIX | sniper v7.8.0 | SCALING-ELITE            |
//|   Copyright 2026, Kopytrading Corp. - kopytrading.com            |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "7.80"
#property strict
#property description "BTC v7.8.0 MATRIX-ELITE | Scaling | License | Drag SL"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- DEFINES ---
#define P_TAG "AEV78B_"
#define CLR_BTC C'255,153,0'

//--- PARÁMETROS ELITE ---
input group "SISTEMA DE LICENCIA ELITE"
input string   MasterKey         = "TRIAL-2026"; 
input long     InpAccountNumber  = 0;            
input string   LicenseCode       = "";           
input bool     ForceCentMode     = true;         
input double   CentFactor        = 0.01;         

input group "== CONFIG ELITE BTC v7.8.0 =="
input int      InpLookbackH      = 24;           
input double   InpLots           = 0.02;         
input double   InpBE             = 0.80;         
input double   InpTS             = 1.20;         
input double   InpTSDist         = 1.00;         
input bool     UseScalingInput   = false;        
input bool     UseNewsFilter     = true;         

//--- GLOBALES ---
CTrade         trade;
CPositionInfo  pos;
int            h_ema20, h_ema50, h_rsi;
double         profitFactor = 1.0, dayPnL = 0;
string         botStatus = "LISTO", strategyLabel = "ESPERANDO";
bool           licenseValid = false, remotePaused = false, isBullish = true;
bool           showEMA=true, showRSI=true, showFibo=true, useConfirmBar=true, useScaling=false;
double         f_p0, f_p100, f_p38, f_p50, f_p61;
datetime       f_timeStart;
double         currLots, currBE, currTS, currTSDist, currSLPct=70.7, currGarantia=0.50;
int            currFiboHours;

//+------------------------------------------------------------------+
//| Init                                                             |
//+------------------------------------------------------------------+
int OnInit() {
   if(!ValidateLicense()) return INIT_FAILED;
   trade.SetExpertMagicNumber(780002);
   profitFactor = ForceCentMode ? CentFactor : 1.0;
   currLots = InpLots; currFiboHours = InpLookbackH;
   currBE = InpBE; currTS = InpTS; currTSDist = InpTSDist;
   useScaling = UseScalingInput;
   h_ema20 = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   h_ema50 = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
   h_rsi   = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   LoadSettings(); EventSetTimer(1); CrearHUD(); UpdateAutoFibo();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) { ObjectsDeleteAll(0, P_TAG); }
void OnTimer() { CheckRemoteNews(); }

void OnTick() {
   UpdateAutoFibo(); ManageStrategy(); ProtectPositions();
   dayPnL = CalculateFullDayPnL(); ActualizarHUD();
}

bool ValidateLicense() {
   if(MasterKey == "TRIAL-2026") {
      if(InpAccountNumber > 0 && AccountInfoInteger(ACCOUNT_LOGIN) != InpAccountNumber) { Alert("Cuenta no autorizada."); return false; }
      licenseValid = true; return true;
   }
   if(AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_DEMO) { licenseValid = true; return true; }
   Alert("LICENCIA REQUERIDA."); return false;
}

void UpdateAutoFibo() {
   if(PositionsTotalBots() > 0 && !useScaling) return;
   int bars = currFiboHours * 4; if(bars<20) bars=100;
   int hi = iHighest(_Symbol, _Period, MODE_HIGH, bars, 0), li = iLowest(_Symbol, _Period, MODE_LOW, bars, 0);
   f_p100 = (hi < li) ? iLow(_Symbol, _Period, li) : iHigh(_Symbol, _Period, hi);
   f_p0   = (hi < li) ? iHigh(_Symbol, _Period, hi) : iLow(_Symbol, _Period, li);
   isBullish = (hi < li); f_timeStart = iTime(_Symbol, _Period, bars);
   double diff = f_p0 - f_p100;
   f_p38 = f_p100 + diff * 0.382; f_p50 = f_p100 + diff * 0.500; f_p61 = f_p100 + diff * 0.618;
   if(showFibo) DrawFiboVisuals(); else ObjectsDeleteAll(0, P_TAG+"fibo");
   DrawInteractiveSLLine(); DrawDirectionalArrow(isBullish, true);
}

void DrawFiboVisuals() {
   string n = P_TAG+"fibo";
   if(ObjectFind(0,n)<0) ObjectCreate(0,n,OBJ_FIBO,0,f_timeStart,f_p100,TimeCurrent(),f_p0);
   ObjectSetDouble(0,n,OBJPROP_PRICE,0,f_p100); ObjectSetDouble(0,n,OBJPROP_PRICE,1,f_p0);
   ObjectSetInteger(0,n,OBJPROP_LEVELS,7);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,0,0.0); ObjectSetString(0,n,OBJPROP_LEVELTEXT,0,"BTC TP (0.0)");
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,4,0.618); ObjectSetString(0,n,OBJPROP_LEVELTEXT,4,"GOLDEN POCKET");
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,5,currSLPct/100.0); ObjectSetString(0,n,OBJPROP_LEVELTEXT,5,"STOP ("+DoubleToString(currSLPct,1)+")");
   DrawTranslucentZone();
}

void DrawTranslucentZone() {
   string z = P_TAG+"zone";
   if(ObjectFind(0,z)<0) { ObjectCreate(0,z,OBJ_RECTANGLE,0,f_timeStart,f_p38,TimeCurrent()+3600,f_p61); ObjectSetInteger(0,z,OBJPROP_FILL,true); ObjectSetInteger(0,z,OBJPROP_BACK,true); }
   ObjectSetDouble(0,z,OBJPROP_PRICE,0,f_p38); ObjectSetDouble(0,z,OBJPROP_PRICE,1,f_p61);
   ObjectSetInteger(0,z,OBJPROP_COLOR,clrOrange);
}

void DrawInteractiveSLLine() {
   string name = P_TAG + "SL_DRAG";
   double slPrice = f_p100 + (f_p0 - f_p100) * (currSLPct/100.0);
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, slPrice);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrRed); ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, true);
   } else if(!ObjectGetInteger(0, name, OBJPROP_SELECTED)) ObjectSetDouble(0, name, OBJPROP_PRICE, slPrice);
}

void DrawDirectionalArrow(bool bull, bool active) {
   string n = P_TAG + "DIR_ARROW";
   if(ObjectFind(0, n) < 0) ObjectCreate(0, n, OBJ_ARROW, 0, TimeCurrent(), 0);
   ObjectSetInteger(0, n, OBJPROP_ARROWCODE, bull ? 233 : 234);
   ObjectSetInteger(0, n, OBJPROP_TIME, TimeCurrent());
   ObjectSetDouble(0, n, OBJPROP_PRICE, bull ? f_p100 - 500*_Point : f_p100 + 500*_Point);
   ObjectSetInteger(0, n, OBJPROP_COLOR, active ? (bull ? clrLime : clrRed) : clrGray);
   ObjectSetInteger(0, n, OBJPROP_WIDTH, 10);
}

void ManageStrategy() {
   double rsi[1], ema20[1], ema50[1]; CopyBuffer(h_rsi,0,0,1,rsi); CopyBuffer(h_ema20,0,0,1,ema20); CopyBuffer(h_ema50,0,0,1,ema50);
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double dist100 = MathAbs(price - f_p100), totalD = MathAbs(f_p0 - f_p100);
   double pct = (totalD>0) ? (dist100/totalD)*100 : 0;
   bool inValue = (pct > 38.2 && pct < 61.8);
   bool confirm = !useConfirmBar || (isBullish ? (iClose(_Symbol,0,1)>iOpen(_Symbol,0,1)) : (iClose(_Symbol,0,1)<iOpen(_Symbol,0,1)));
   int total = PositionsTotalBots();
   strategyLabel = isBullish ? "BTC BULL SWING" : "BTC BEAR SWING";
   if(inValue) strategyLabel += " (VALUE ZONE)";
   if(!(UseNewsFilter && remotePaused) && inValue && confirm && (total == 0 || (total==1 && useScaling && IsFirstTradeSecured()))) {
       double sl = ObjectGetDouble(0, P_TAG+"SL_DRAG", OBJPROP_PRICE);
       if(isBullish && ema20[0] > ema50[0] && price > ema20[0]) trade.Buy(currLots, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_ASK), sl, 0, "BTC_V78_SCAL");
       if(!isBullish && ema20[0] < ema50[0] && price < ema20[0]) trade.Sell(currLots, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_BID), sl, 0, "BTC_V78_SCAL");
   }
}

bool IsFirstTradeSecured() {
   int count=0; bool secured=false;
   for(int i=PositionsTotal()-1; i>=0; i--) { if(pos.SelectByIndex(i) && pos.Magic()==780002) { count++; if((pos.PositionType()==POSITION_TYPE_BUY && pos.StopLoss() >= pos.PriceOpen()) || (pos.PositionType()==POSITION_TYPE_SELL && pos.StopLoss() <= pos.PriceOpen())) secured=true; } }
   return (count == 1 && secured);
}

void ProtectPositions() {
   double slLine = ObjectGetDouble(0, P_TAG+"SL_DRAG", OBJPROP_PRICE);
   double stpDist = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point + 10*_Point;
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(pos.SelectByIndex(i) && pos.Magic()==780002) {
         double bid=SymbolInfoDouble(_Symbol, SYMBOL_BID), ask=SymbolInfoDouble(_Symbol, SYMBOL_ASK), pUSD = (pos.Profit() + pos.Swap() + pos.Commission()) * profitFactor, newSL = pos.StopLoss(), openP = pos.PriceOpen();
         if(pos.PositionType()==POSITION_TYPE_BUY) { if(pUSD > currBE && newSL < openP) newSL = openP + currGarantia; if(pUSD > currTS && (bid-currTS) > newSL) newSL = bid-currTS; if(slLine > newSL) newSL = slLine; if(bid-newSL < stpDist) newSL = bid-stpDist; }
         else { if(pUSD > currBE && (newSL > openP || newSL==0)) newSL = openP - currGarantia; if(pUSD > currTS && (ask+currTS) < newSL) newSL = ask+currTS; if(slLine < newSL && slLine != 0) newSL = slLine; if(newSL-mask < stpDist) newSL = ask+stpDist; }
         if(MathAbs(newSL - pos.StopLoss()) > _Point) trade.PositionModify(pos.Ticket(), NormalizeDouble(newSL, _Digits), 0);
      }
   }
}

void CrearHUD() {
   ObjectsDeleteAll(0, P_TAG); int hx=15, hy=15, hw=280, hh=560;
   CrRect("bg",hx,hy,hw,hh,C'12,12,18',CLR_BTC); CrLabel("ttl",hx+15,hy+15,"BTC v7.8.0 MATRIX",CLR_BTC,11,"Arial Black");
   CrLabel("lic",hx+15,hy+40,"LICENCIA: "+(licenseValid?"ACTIVA":"INVALIDA"),CLR_BTC,8);
   CrLabel("pV",hx+140,hy+80,DoubleToString(dayPnL,2)+" $",clrWhite,10,"Arial Bold");
   CrLabel("stV",hx+15,hy+100,strategyLabel,clrCyan,9,"Arial Bold"); int ry=130;
   CrEdit("e_lots",hx+150,ry,60,22,DoubleToString(currLots,2)); CrLabel("l_lots",hx+15,ry+3,"Lotes:",clrSilver,8); ry+=30;
   CrEdit("e_be",hx+150,ry,60,22,DoubleToString(currBE,2)); CrLabel("l_be",hx+15,ry+3,"Break-Even:",clrSilver,8); ry+=30;
   CrEdit("e_ts",hx+150,ry,60,22,DoubleToString(currTS,2)); CrLabel("l_ts",hx+15,ry+3,"Trailing:",clrSilver,8); ry+=30;
   CrEdit("e_slp",hx+150,ry,60,22,DoubleToString(currSLPct,1)); CrLabel("l_slp",hx+15,ry+3,"Stop %:",clrRed,8); ry+=40;
   CrBtn("b_app",hx+15,ry,250,32,"APLICAR CAMBIOS",clrDodgerBlue,clrWhite); ry+=50;
   CrBtn("v_cnf",hx+15,ry,120,30,"CONF: "+(useConfirmBar?"ON":"OFF"),useConfirmBar?clrForestGreen:clrGray,clrWhite);
   CrBtn("v_scl",hx+145,ry,120,30,"SCAL: "+(useScaling?"ON":"OFF"),useScaling?clrOrange:clrGray,clrWhite); ry+=60;
   CrBtn("close",hx+15,hy+hh-60,250,45,"CERRAR TODO",clrCrimson,clrWhite); ActualizarHUD();
}

void ActualizarHUD() { ObjectSetString(0,P_TAG+"pV",OBJPROP_TEXT,DoubleToString(dayPnL,2)+" $"); ObjectSetString(0,P_TAG+"stV",OBJPROP_TEXT,strategyLabel); }
void OnChartEvent(const int id, const long& lp, const double& dp, const string& sp) {
   if(id==CHARTEVENT_OBJECT_CLICK) {
      if(sp==P_TAG+"b_app") { currLots=StringToDouble(ObjectGetString(0,P_TAG+"e_lots",OBJPROP_TEXT)); currBE=StringToDouble(ObjectGetString(0,P_TAG+"e_be",OBJPROP_TEXT)); currTS=StringToDouble(ObjectGetString(0,P_TAG+"e_ts",OBJPROP_TEXT)); currSLPct=StringToDouble(ObjectGetString(0,P_TAG+"e_slp",OBJPROP_TEXT)); SaveSettings(); UpdateAutoFibo(); CrearHUD(); }
      if(sp==P_TAG+"v_cnf") { useConfirmBar=!useConfirmBar; CrearHUD(); }
      if(sp==P_TAG+"v_scl") { useScaling=!useScaling; CrearHUD(); }
      if(sp==P_TAG+"close") { for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==780002) trade.PositionClose(pos.Ticket()); }
      ObjectSetInteger(0,sp,OBJPROP_STATE,false);
   }
   if(id==CHARTEVENT_OBJECT_DRAG && sp==P_TAG+"SL_DRAG") { double p = ObjectGetDouble(0, sp, OBJPROP_PRICE); double dist = MathAbs(f_p0-f_p100); if(dist>0) { currSLPct = (MathAbs(p-f_p100)/dist)*100; ObjectSetString(0,P_TAG+"e_slp",OBJPROP_TEXT,DoubleToString(currSLPct,1)); SaveSettings(); } }
}

double CalculateFullDayPnL() { MqlDateTime dt; TimeToStruct(TimeCurrent(), dt); dt.hour=0; dt.min=0; dt.sec=0; HistorySelect(StructToTime(dt), TimeCurrent()); double p=0; for(int i=HistoryDealsTotal()-1; i>=0; i--) { ulong t=HistoryDealGetTicket(i); if(HistoryDealGetString(t, DEAL_SYMBOL) == _Symbol && HistoryDealGetInteger(t, DEAL_MAGIC) == 780002) p += HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_SWAP) + HistoryDealGetDouble(t, DEAL_COMMISSION); } return p * profitFactor; }
void CheckRemoteNews() { char data[], res[]; string h; int s = WebRequest("GET","https://kopytrading.com/api/news-filter",NULL,NULL,500,data,0,res,h); if(s==200) remotePaused = (StringFind(CharArrayToString(res),"PAUSE")>=0); }
int PositionsTotalBots() { int c=0; for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==780002) c++; return c; }
void LoadSettings() { string m=IntegerToString(780002); if(GlobalVariableCheck(P_TAG+"lots"+m)) currLots=GlobalVariableGet(P_TAG+"lots"+m); if(GlobalVariableCheck(P_TAG+"be"+m)) currBE=GlobalVariableGet(P_TAG+"be"+m); if(GlobalVariableCheck(P_TAG+"ts"+m)) currTS=GlobalVariableGet(P_TAG+"ts"+m); if(GlobalVariableCheck(P_TAG+"slp"+m)) currSLPct=GlobalVariableGet(P_TAG+"slp"+m); }
void SaveSettings() { string m=IntegerToString(780002); GlobalVariableSet(P_TAG+"lots"+m,currLots); GlobalVariableSet(P_TAG+"be"+m,currBE); GlobalVariableSet(P_TAG+"ts"+m,currTS); GlobalVariableSet(P_TAG+"slp"+m,currSLPct); }
void CrRect(string n,int x,int y,int w,int h,color bg,color bd){ ObjectCreate(0,P_TAG+n,OBJ_RECTANGLE_LABEL,0,0,0); ObjectSetInteger(0,P_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,P_TAG+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,P_TAG+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,P_TAG+n,OBJPROP_YSIZE,h); ObjectSetInteger(0,P_TAG+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,P_TAG+n,OBJPROP_COLOR,bd); ObjectSetInteger(0,P_TAG+n,OBJPROP_BORDER_TYPE,BORDER_FLAT); }
void CrLabel(string n,int x,int y,string t,color c,int s,string f="Arial"){ ObjectCreate(0,P_TAG+n,OBJ_LABEL,0,0,0); ObjectSetInteger(0,P_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,P_TAG+n,OBJPROP_YDISTANCE,y); ObjectSetString(0,P_TAG+n,OBJPROP_TEXT,t); ObjectSetInteger(0,P_TAG+n,OBJPROP_COLOR,c); ObjectSetInteger(0,P_TAG+n,OBJPROP_FONTSIZE,s); ObjectSetString(0,P_TAG+n,OBJPROP_FONT,f); }
void CrEdit(string n,int x,int y,int w,int h,string t){ ObjectCreate(0,P_TAG+n,OBJ_EDIT,0,0,0); ObjectSetInteger(0,P_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,P_TAG+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,P_TAG+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,P_TAG+n,OBJPROP_YSIZE,h); ObjectSetString(0,P_TAG+n,OBJPROP_TEXT,t); ObjectSetInteger(0,P_TAG+n,OBJPROP_BGCOLOR,C'30,30,45'); ObjectSetInteger(0,P_TAG+n,OBJPROP_COLOR,clrWhite); ObjectSetInteger(0,P_TAG+n,OBJPROP_FONTSIZE,8); ObjectSetInteger(0,P_TAG+n,OBJPROP_ALIGN,ALIGN_CENTER); }
void CrBtn(string n,int x,int y,int w,int h,string t,color bg,color tc){ ObjectCreate(0,P_TAG+n,OBJ_BUTTON,0,0,0); ObjectSetInteger(0,P_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,P_TAG+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,P_TAG+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,P_TAG+n,OBJPROP_YSIZE,h); ObjectSetString(0,P_TAG+n,OBJPROP_TEXT,t); ObjectSetInteger(0,P_TAG+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,P_TAG+n,OBJPROP_COLOR,tc); ObjectSetInteger(0,P_TAG+n,OBJPROP_FONTSIZE,8); }

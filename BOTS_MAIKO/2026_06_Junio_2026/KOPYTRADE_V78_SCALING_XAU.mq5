//+------------------------------------------------------------------+
//|     KOPYTRADE_v78_SCALING_BTC.mq5                                |
//|   BTC AUTO-FIBO MATRIX | sniper v7.1.6 | ELITE OPTIMIZED       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "7.16"
#property strict
#property description "₿ BTC v7.1.6 | ELITE SCALER PRESETS | TREND SCALER"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- DEFINES ---
#define P_TAG "AEV79B_"
#define CLR_BTC C'255,153,0'
#define CLR_PANEL C'10,10,14'
#define CLR_GP_STRONG C'80,50,15'
#define CLR_BLUE C'30,144,255'

//--- PARÁMETROS ---
input group "🛡️ SEGURIDAD Y LICENCIA"
input string   LicenciaKey       = "TRIAL-2023"; 
input bool     ActivarNewsFilter = true;         
input bool     ForceCentMode     = true;         
input double   CentFactor        = 0.01;         

input group "== GESTIÓN DE RIESGO v7.1.6 =="
input bool     UsarAutoLote_Def  = true;         
input double   PorcRiesgo_Def    = 2.0;          
input double   MinLotsManual     = 0.02;        

input group "== OPTIMIZACIÓN SONIC =="
input bool     UsarFiltroRSI     = true;         
input int      RSILimiteBajo     = 35;           
input int      RSILimiteAlto     = 65;           
input double   StopLossPorc      = 105.0;        

input group "== ESCALADO Y TRAILING (ELITE PRESETS) =="
input bool     ActivarEscalado_Def= true;         
input double   BreakEvenUSD      = 0.80;         // Optimizado: Era 1.00
input double   TrailingStopUSD   = 1.20;         // Optimizado: Era 1.50
input double   TrailGarantia_Def = 0.50;         
input int      FiboHoras_Def     = 8;            // Optimizado: Era 12

//--- GLOBALES ---
CTrade         trade;
CPositionInfo  pos;
int            h_ema20, h_ema50, h_rsi;
double         profitFactor = 1.0, dayPnL = 0;
string         strategyLabel = "ESPERANDO";
bool           remotePaused = false, isBullish = true, isMinimized = false, isMismatch = false;
bool           showEMA=true, showRSI=true, showFibo=true, sonidoOn=true, giroOn=true;
double         f_p0=0, f_p100=0, f_p38=0, f_p50=0, f_p61=0;
datetime       f_t0, f_t100;
double         currLots, currBE, currTS, currSLPct, currRisk, currGarantia;
int            currFiboHours;
bool           currScaling, currAutoLot;
datetime       lastSoundTime = 0;

//+------------------------------------------------------------------+
//| Risk Engine: Auto-Lot                                            |
//+------------------------------------------------------------------+
double CalculateAutoLot(double slPrice) {
   if(!currAutoLot) return MinLotsManual;
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = bal * (currRisk / 100.0);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK), bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double price = isBullish ? ask : bid;
   double diff = MathAbs(price - slPrice);
   if(diff <= 0 || tickSize <= 0 || tickVal <= 0) return MinLotsManual;
   double lots = riskMoney / ((diff / tickSize) * tickVal);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   lots = MathFloor(lots / step) * step;
   return fmax(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), fmin(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX), NormalizeDouble(lots, 2)));
}

double ValidSL(double price, bool buy) {
   double stopsLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(buy) { if(price > ask - stopsLevel) price = ask - stopsLevel - 5*_Point; }
   else { if(price < bid + stopsLevel && price > 0) price = bid + stopsLevel + 5*_Point; }
   return NormalizeDouble(price, _Digits);
}

//+------------------------------------------------------------------+
//| Init                                                             |
//+------------------------------------------------------------------+
int OnInit() {
   trade.SetExpertMagicNumber(780002);
   profitFactor = ForceCentMode ? CentFactor : 1.0;
   currRisk = PorcRiesgo_Def; currScaling = ActivarEscalado_Def; currAutoLot = UsarAutoLote_Def;
   currGarantia = TrailGarantia_Def; currBE = BreakEvenUSD; currTS = TrailingStopUSD; currSLPct = StopLossPorc;
   currFiboHours = FiboHoras_Def;
   h_ema20 = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   h_ema50 = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
   h_rsi   = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   isMismatch = (StringFind(_Symbol, "BTC") < 0);
   LoadSettings(); EventSetTimer(1); CrearHUD(); UpdateAutoFibo();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) { SaveSettings(); ObjectsDeleteAll(0, P_TAG); }
void OnTimer() { if(!MQLInfoInteger(MQL_TESTER) && ActivarNewsFilter) CheckRemoteNews(); else remotePaused = false; }
void OnTick() { UpdateAutoFibo(); ManageStrategy(); ProtectPositions(); dayPnL = CalculateFullDayPnL(); ActualizarHUD(); }

void UpdateAutoFibo() {
   if(PositionsTotalBots() > 0 && !currScaling) return;
   int bars = currFiboHours * (3600/PeriodSeconds()); if(bars<20) bars=100;
   int hiIdx = iHighest(_Symbol, _Period, MODE_HIGH, bars, 0), liIdx = iLowest(_Symbol, _Period, MODE_LOW, bars, 0);
   double vHi = iHigh(_Symbol, _Period, hiIdx), vLi = iLow(_Symbol, _Period, liIdx);
   if(hiIdx > liIdx) { f_p100 = vHi; f_t100 = iTime(_Symbol, _Period, hiIdx); f_p0 = vLi; f_t0 = iTime(_Symbol, _Period, liIdx); isBullish = false; }
   else { f_p100 = vLi; f_t100 = iTime(_Symbol, _Period, liIdx); f_p0 = vHi; f_t0 = iTime(_Symbol, _Period, hiIdx); isBullish = true; }
   double diff = f_p0 - f_p100;
   f_p38 = f_p100 + diff * 0.382; f_p50 = f_p100 + diff * 0.500; f_p61 = f_p100 + diff * 0.618;
   
   if(showFibo) { DrawFiboVisuals(); DrawGoldenPocket(); } 
   else { ObjectsDeleteAll(0, P_TAG+"fibo"); ObjectsDeleteAll(0, P_TAG+"zone"); }
   DrawInteractiveLines();
}

void DrawFiboVisuals() {
   string n = P_TAG+"fibo"; if(ObjectFind(0,n)<0) ObjectCreate(0,n,OBJ_FIBO,0,f_t100,f_p100,f_t0,f_p0);
   ObjectSetInteger(0,n,OBJPROP_TIME,0,f_t100); ObjectSetDouble(0,n,OBJPROP_PRICE,0,f_p100);
   ObjectSetInteger(0,n,OBJPROP_TIME,1,f_t0); ObjectSetDouble(0,n,OBJPROP_PRICE,1,f_p0);
   ObjectSetInteger(0,n,OBJPROP_RAY_RIGHT,true); ObjectSetInteger(0,n,OBJPROP_BACK, true); 
   ObjectSetInteger(0,n,OBJPROP_LEVELS,7);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,0,0.0); ObjectSetString(0,n,OBJPROP_LEVELTEXT,0,"🎯 TARGET (0.0)"); ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,0,clrLime);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,1,0.236); ObjectSetString(0,n,OBJPROP_LEVELTEXT,1,"23.6"); ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,1,clrYellow);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,2,0.382); ObjectSetString(0,n,OBJPROP_LEVELTEXT,2,"38.2"); ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,2,clrYellow);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,3,0.500); ObjectSetString(0,n,OBJPROP_LEVELTEXT,3,"50.0"); ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,3,clrDeepSkyBlue);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,4,0.618); ObjectSetString(0,n,OBJPROP_LEVELTEXT,4,"61.8"); ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,4,clrYellow);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,5,1.000); ObjectSetString(0,n,OBJPROP_LEVELTEXT,5,"100.0"); ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,5,clrSilver);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,6,currSLPct/100.0); ObjectSetString(0,n,OBJPROP_LEVELTEXT,6,"🛑 STOP ("+DoubleToString(currSLPct,1)+")"); ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,6,clrRed);
}

void DrawGoldenPocket() {
   string n = P_TAG+"zone";
   datetime tFuture = TimeCurrent() + 86400 * 3;
   if(ObjectFind(0,n)<0) {
      ObjectCreate(0,n,OBJ_RECTANGLE,0,f_t100,f_p38,tFuture,f_p61);
      ObjectSetInteger(0,n,OBJPROP_COLOR,CLR_GP_STRONG);
      ObjectSetInteger(0,n,OBJPROP_FILL,true);
      ObjectSetInteger(0,n,OBJPROP_BACK,true);
   } else {
      ObjectSetInteger(0,n,OBJPROP_TIME,0,f_t100); ObjectSetDouble(0,n,OBJPROP_PRICE,0,f_p38);
      ObjectSetInteger(0,n,OBJPROP_TIME,1,tFuture); ObjectSetDouble(0,n,OBJPROP_PRICE,1,f_p61);
   }
}

void DrawInteractiveLines() {
   string slN=P_TAG+"SL"; double diff = f_p0 - f_p100;
   double prSL = f_p0 - diff * (currSLPct/100.0);
   if(ObjectFind(0,slN)<0) { ObjectCreate(0,slN,OBJ_HLINE,0,0,prSL); ObjectSetInteger(0,slN,OBJPROP_COLOR,clrRed); ObjectSetInteger(0,slN,OBJPROP_WIDTH,2); ObjectSetInteger(0,slN,OBJPROP_SELECTABLE,true); ObjectSetInteger(0,slN,OBJPROP_BACK, true); }
   if(!ObjectGetInteger(0,slN,OBJPROP_SELECTED)) ObjectSetDouble(0,slN,OBJPROP_PRICE,prSL);
}

void ManageStrategy() {
   if(!giroOn) { strategyLabel = "GIRO OFF"; return; }
   double rsi[1], ema20[1], ema50[1]; CopyBuffer(h_rsi,0,0,1,rsi); CopyBuffer(h_ema20,0,0,1,ema20); CopyBuffer(h_ema50,0,0,1,ema50);
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double totD = MathAbs(f_p0 - f_p100);
   double pct = (totD>0) ? (MathAbs(price - f_p100)/totD)*100 : 0;
   bool rsiF = !UsarFiltroRSI || (isBullish ? rsi[0] < RSILimiteAlto : rsi[0] > RSILimiteBajo);
   int posTotal = PositionsTotalBots();
   bool canEntry = (posTotal == 0 && pct >= 38.2 && pct <= 61.8);
   bool canScaling = (currScaling && posTotal == 1 && IsFirstTradeSecured() && pct <= 61.8);

   strategyLabel = StringSubstr(_Symbol,0,3) + (isBullish ? " ALCISTA" : " BAJISTA") + (posTotal>0? " (SCALING)":"");
   if(AccountInfoInteger(ACCOUNT_TRADE_EXPERT) && !remotePaused && rsiF && (canEntry || canScaling)) {
       double slRaw = ObjectGetDouble(0, P_TAG+"SL", OBJPROP_PRICE);
       double sl = ValidSL(slRaw, isBullish);
       double lots = CalculateAutoLot(sl);
       bool success = false;
       if(isBullish && ema20[0] > ema50[0]) success = trade.Buy(lots,_Symbol,SymbolInfoDouble(_Symbol,SYMBOL_ASK),sl,0);
       if(!isBullish && ema20[0] < ema50[0]) success = trade.Sell(lots,_Symbol,SymbolInfoDouble(_Symbol,SYMBOL_BID),sl,0);
       
       if(success && sonidoOn && TimeCurrent() > lastSoundTime + 5) { PlaySound("ok.wav"); lastSoundTime = TimeCurrent(); }
   }
}

bool IsFirstTradeSecured() {
   for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==780002) { 
      if(pos.PositionType()==POSITION_TYPE_BUY && pos.StopLoss() >= pos.PriceOpen()) return true;
      if(pos.PositionType()==POSITION_TYPE_SELL && pos.StopLoss() <= pos.PriceOpen() && pos.StopLoss()>0) return true;
   }
   return false;
}

void ProtectPositions() {
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID), ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double slLine = ObjectGetDouble(0, P_TAG+"SL", OBJPROP_PRICE);
   for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==780002) {
      double pUSD = (pos.Profit()+pos.Swap()+pos.Commission())*profitFactor, newSL = pos.StopLoss(), openP = pos.PriceOpen();
      if(pos.PositionType()==POSITION_TYPE_BUY) { 
         if(pUSD > currBE && (newSL < openP || newSL==0)) newSL = openP + currGarantia; 
         if(pUSD > currTS && (bid-currTS) > newSL) newSL = bid-currTS; 
         if(slLine > 0 && slLine < bid && slLine > newSL) newSL = slLine; 
      } else { 
         if(pUSD > currBE && (newSL > openP || newSL==0)) newSL = openP - currGarantia; 
         if(pUSD > currTS && (ask+currTS) < newSL) newSL = ask+currTS; 
         if(slLine > ask && (slLine < newSL || newSL == 0)) newSL = slLine; 
      }
      if(MathAbs(newSL - pos.StopLoss()) > _Point) trade.PositionModify(pos.Ticket(), ValidSL(newSL, pos.PositionType()==POSITION_TYPE_BUY), 0);
   }
}

void CrearHUD() {
   ObjectsDeleteAll(0, P_TAG); int hx=15, hy=15, hw=365, hh=isMinimized?40:685;
   CrRect("bg",hx,hy,hw,hh,CLR_PANEL,CLR_BTC, 1500); 
   CrLabel("ttl",hx+15,hy+13,isMinimized?"₿ BTC ELITE":"🚀 BTC SONIC ELITE v7.1.6",CLR_BTC,11,"Impact", 1600);
   CrBtn("b_min",hx+hw-35,hy+10,25,20,isMinimized?"+":"-",C'60,60,80',clrWhite, 1700);
   if(isMinimized) return;
   CrLabel("pV",hx+15,hy+65,"PnL HOY: "+DoubleToString(dayPnL,2)+" $ / RIESGO "+DoubleToString(currRisk,1)+"%",clrWhite,10,"Arial Bold", 1600);
   CrLabel("stV",hx+15,hy+95,"MODO: "+strategyLabel,clrCyan,10,"Arial Bold", 1600);
   CrBtn("b_zen",hx+10,hy+145,168,35,"ZEN (2.0%)",C'50,55,75',clrWhite, 1700); 
   CrBtn("b_har",hx+182,hy+145,168,35,"CASCADA AGRE (5.0%)",C'70,45,25',clrWhite, 1700);
   int ry=200, c1=hx+15, c2=hx+235;
   CrLabel("l_lot",c1,ry+3,"Riesgo % Trade:",clrSilver,9,"Arial", 1600); CrEdit("e_lot",c2,ry,50,22,DoubleToString(currRisk,1), 1700); ry+=35;
   CrLabel("l_fib",c1,ry+3,"Fibo Horas:",clrSilver,9,"Arial", 1600); CrEdit("e_fib",c2,ry,50,22,IntegerToString(currFiboHours), 1700); ry+=35;
   CrLabel("l_be",c1,ry+3,"Break-Even ($):",clrSilver,9,"Arial", 1600); CrEdit("e_be",c2,ry,50,22,DoubleToString(currBE,2), 1700); ry+=35;
   CrLabel("l_gar",c1,ry+3,"GARANTÍA ($):",CLR_BTC,9,"Arial Bold", 1600); CrEdit("e_gar",c2,ry,50,22,DoubleToString(currGarantia,2), 1700); ry+=35;
   CrLabel("l_ts",c1,ry+3,"Trailing ($):",clrSilver,9,"Arial", 1600); CrEdit("e_ts",c2,ry,50,22,DoubleToString(currTS,2), 1700); ry+=35;
   CrLabel("l_slp",c1,ry+3,"Stop %:",clrRed,9,"Arial", 1600); CrEdit("e_slp",c2,ry,50,22,DoubleToString(currSLPct,1), 1700); ry+=45;
   
   CrBtn("v_ma",hx+10,ry,113,32,"EMA",showEMA?CLR_BLUE:C'40,40,40',clrWhite,1700);
   CrBtn("v_rsi",hx+126,ry,113,32,"RSI",showRSI?C'150,80,40':C'40,40,40',clrWhite,1700);
   CrBtn("v_fib",hx+242,ry,113,32,"FIBO",showFibo?CLR_BTC:C'40,40,40',clrWhite,1700); ry+=45;
   
   CrBtn("b_giro",hx+10,ry,hw/2-15,35,"GIRO: "+(giroOn?"ON":"OFF"),giroOn?clrGreen:clrRed,clrWhite,1700);
   CrBtn("b_cas",hx+hw/2+5,ry,hw/2-15,35,"CASCADA: "+(currScaling?"ON":"OFF"),currScaling?clrGreen:clrRed,clrWhite,1700); ry+=42;
   CrBtn("b_snd",hx+10,ry,hw-20,30,"SONIDO: "+(sonidoOn?"ON":"OFF"),sonidoOn?CLR_BLUE:C'40,40,40',clrWhite,1700); ry+=42;
   CrBtn("b_app",hx+10,ry,hw-20,42,"APLICAR CAMBIOS ELITE",C'40,80,150',clrWhite,1700); ry+=52;
   CrBtn("b_cls",hx+10,ry,hw-20,42,"CERRAR TODO",C'150,40,40',clrWhite,1700);
}

void ActualizarHUD() { if(ObjectFind(0,P_TAG+"pV")>=0) { ObjectSetString(0,P_TAG+"pV",OBJPROP_TEXT,"PnL HOY: "+DoubleToString(dayPnL,2)+" $ / RIESGO "+DoubleToString(currRisk,1)+"%"); ObjectSetString(0,P_TAG+"stV",OBJPROP_TEXT,"MODO: "+strategyLabel); } }
void OnChartEvent(const int id,const long &lp,const double &dp,const string &sp) {
   if(id==CHARTEVENT_OBJECT_CLICK) {
      if(sp==P_TAG+"b_app") { SaveSettings(); UpdateAutoFibo(); CrearHUD(); }
      if(sp==P_TAG+"b_min") { isMinimized=!isMinimized; CrearHUD(); }
      if(sp==P_TAG+"b_zen") { currRisk=2.0; currScaling=true; SaveSettings(); CrearHUD(); }
      if(sp==P_TAG+"b_har") { currRisk=5.0; currScaling=true; SaveSettings(); CrearHUD(); }
      if(sp==P_TAG+"v_ma")  { showEMA=!showEMA; CrearHUD(); }
      if(sp==P_TAG+"v_rsi") { showRSI=!showRSI; CrearHUD(); }
      if(sp==P_TAG+"v_fib") { showFibo=!showFibo; UpdateAutoFibo(); CrearHUD(); }
      if(sp==P_TAG+"b_giro") { giroOn=!giroOn; CrearHUD(); }
      if(sp==P_TAG+"b_cas")  { currScaling=!currScaling; CrearHUD(); }
      if(sp==P_TAG+"b_snd")  { sonidoOn=!sonidoOn; CrearHUD(); }
      if(sp==P_TAG+"b_cls")  { for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==780002) trade.PositionClose(pos.Ticket()); }
      ObjectSetInteger(0,sp,OBJPROP_STATE,false);
   }
   if(id==CHARTEVENT_OBJECT_DRAG && sp==P_TAG+"SL") {
      double p = ObjectGetDouble(0, sp, OBJPROP_PRICE); double totD = MathAbs(f_p100-f_p0);
      if(totD>0) { currSLPct = (MathAbs(p-f_p0)/totD)*100; ObjectSetString(0, P_TAG+"e_slp", OBJPROP_TEXT, DoubleToString(currSLPct, 1)); SaveSettings(); }
   }
   if(id==CHARTEVENT_OBJECT_ENDEDIT) {
      if(sp==P_TAG+"e_lot") currRisk = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==P_TAG+"e_fib") currFiboHours = (int)StringToInteger(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==P_TAG+"e_be")  currBE = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==P_TAG+"e_ts")  currTS = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==P_TAG+"e_gar") currGarantia = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==P_TAG+"e_slp") currSLPct = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      SaveSettings();
   }
}

void CrRect(string n,int x,int y,int w,int h,color bg,color bd,int z=200){ ObjectCreate(0,P_TAG+n,OBJ_RECTANGLE_LABEL,0,0,0); ObjectSetInteger(0,P_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,P_TAG+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,P_TAG+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,P_TAG+n,OBJPROP_YSIZE,h); ObjectSetInteger(0,P_TAG+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,P_TAG+n,OBJPROP_COLOR,bd); ObjectSetInteger(0,P_TAG+n,OBJPROP_ZORDER,z); }
void CrLabel(string n,int x,int y,string t,color c,int s,string f="Arial",int z=210){ ObjectCreate(0,P_TAG+n,OBJ_LABEL,0,0,0); ObjectSetInteger(0,P_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,P_TAG+n,OBJPROP_YDISTANCE,y); ObjectSetString(0,P_TAG+n,OBJPROP_TEXT,t); ObjectSetInteger(0,P_TAG+n,OBJPROP_COLOR,c); ObjectSetInteger(0,P_TAG+n,OBJPROP_FONTSIZE,s); ObjectSetString(0,P_TAG+n,OBJPROP_FONT,f); ObjectSetInteger(0,P_TAG+n,OBJPROP_ZORDER,z); }
void CrBtn(string n,int x,int y,int w,int h,string t,color bg,color tc,int z=220){ ObjectCreate(0,P_TAG+n,OBJ_BUTTON,0,0,0); ObjectSetInteger(0,P_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,P_TAG+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,P_TAG+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,P_TAG+n,OBJPROP_YSIZE,h); ObjectSetString(0,P_TAG+n,OBJPROP_TEXT,t); ObjectSetInteger(0,P_TAG+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,P_TAG+n,OBJPROP_COLOR,tc); ObjectSetInteger(0,P_TAG+n,OBJPROP_ZORDER,z); }
void CrEdit(string n,int x,int y,int w,int h,string t,int z=220){ ObjectCreate(0,P_TAG+n,OBJ_EDIT,0,0,0); ObjectSetInteger(0,P_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,P_TAG+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,P_TAG+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,P_TAG+n,OBJPROP_YSIZE,h); ObjectSetString(0,P_TAG+n,OBJPROP_TEXT,t); ObjectSetInteger(0,P_TAG+n,OBJPROP_BGCOLOR,C'25,25,35'); ObjectSetInteger(0,P_TAG+n,OBJPROP_COLOR,clrWhite); ObjectSetInteger(0,P_TAG+n,OBJPROP_ZORDER,z); ObjectSetInteger(0,P_TAG+n,OBJPROP_ALIGN,ALIGN_CENTER); }
double CalculateFullDayPnL() { MqlDateTime dt; TimeToStruct(TimeCurrent(), dt); dt.hour=0; dt.min=0; dt.sec=0; HistorySelect(StructToTime(dt), TimeCurrent()); double p=0; for(int i=HistoryDealsTotal()-1; i>=0; i--) { ulong t=HistoryDealGetTicket(i); if(HistoryDealGetString(t, DEAL_SYMBOL) == _Symbol && HistoryDealGetInteger(t, DEAL_MAGIC) == 780002) p += HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_SWAP) + HistoryDealGetDouble(t, DEAL_COMMISSION); } return p * profitFactor; }
int PositionsTotalBots() { int c=0; for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==780002) c++; return c; }
void CheckRemoteNews() { char data[], res[]; string h; int s = WebRequest("GET","https://kopytrading.com/api/news-filter",NULL,NULL,500,data,0,res,h); if(s==200) remotePaused = (StringFind(CharArrayToString(res),"PAUSE")>=0); }
void LoadSettings() { string m=IntegerToString(780002); if(GlobalVariableCheck(P_TAG+"risk"+m)) currRisk=GlobalVariableGet(P_TAG+"risk"+m); if(GlobalVariableCheck(P_TAG+"be"+m)) currBE=GlobalVariableGet(P_TAG+"be"+m); if(GlobalVariableCheck(P_TAG+"gar"+m)) currGarantia=GlobalVariableGet(P_TAG+"gar"+m); }
void SaveSettings() { string m=IntegerToString(780002); GlobalVariableSet(P_TAG+"risk"+m,currRisk); GlobalVariableSet(P_TAG+"be"+m,currBE); GlobalVariableSet(P_TAG+"gar"+m,currGarantia); }

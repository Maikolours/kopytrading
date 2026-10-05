//+------------------------------------------------------------------+
//|     KOPYTRADE_v78_SCALING_BTC.mq5                                |
//|   BTC AUTO-FIBO MATRIX | sniper v7.4.6 | TACTICAL VISUALS        |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "7.46"
#property strict
#property description "₿ BTC v7.4.6 | TACTICAL VISUALS | AUTO-SCALING"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- DEFINES ---
#define P_TAG "EVO_V7_B_" 
#define MAGIC_NUMBER 780002
#define STR_COMMENT "EVO_V7_BTC"
#define CLR_BTC C'255,153,0'
#define CLR_GOLD C'212,175,55'
#define CLR_PANEL C'10,10,14'
#define CLR_GP_STRONG C'80,50,15'
#define CLR_BLUE C'30,144,255'

//--- PARÁMETROS ---
input group "🛡️ SEGURIDAD Y LICENCIA"
input string   LicenciaKey       = "TRIAL-2023"; 
input bool     ActivarNewsFilter = true;         
input bool     ForceCentMode     = true;         
input double   CentFactor        = 0.01;         

input group "== GESTIÓN DE RIESGO v7.2.0 =="
input bool     UsarAutoLote_Def  = true;         
input double   PorcRiesgo_Def    = 1.0;          
input double   MinLotsManual     = 0.02;        

input group "== OPTIMIZACIÓN SONIC =="
input bool     UsarFiltroRSI     = true;         
input int      RSILimiteBajo     = 35;           
input int      RSILimiteAlto     = 65;           
input double   StopLossPorc      = 105.0;        

input group "== ESCALADO Y TRAILING (12H MASTER) =="
input bool     ActivarEscalado_Def= true;         
input double   BreakEvenUSD      = 3.00;         
input double   TrailingStopUSD   = 3.50;         
input double   TrailGarantia_Def = 2.00;         
input int      FiboHours_Def     = 12;           

//--- GLOBALES ---
CTrade         trade;
CPositionInfo  pos;
int            h_ema20, h_ema50, h_rsi;
double         profitFactor = 1.0, dayPnL = 0;
string         strategyLabel = "ESPERANDO", statusLabel = "INIT";
bool           remotePaused = false, isBullish = true, isMinimized = false;
bool           showEMA=true, showRSI=true, showFibo=true, sonidoOn=true, giroOn=true;
double         f_p0=0, f_p100=0, f_p38=0, f_p50=0, f_p61=0, f_p78=0;
datetime       f_t0, f_t100, lastTrendChange = 0;
bool           trendConfirmed = false;
double         currRisk, currBE, currTS, currSLPct, currGarantia, currPainLimit = 20.0;
int            currFiboHours, currBars = 0;
bool           currScaling, currAutoLot;
datetime       lastSoundTime = 0;

//+------------------------------------------------------------------+
//| Init                                                             |
//+------------------------------------------------------------------+
int OnInit() {
   trade.SetExpertMagicNumber(MAGIC_NUMBER);
   profitFactor = ForceCentMode ? CentFactor : 1.0;
   currRisk=PorcRiesgo_Def; currScaling=ActivarEscalado_Def; currAutoLot=UsarAutoLote_Def;
   currGarantia=TrailGarantia_Def; currBE=BreakEvenUSD; currTS=TrailingStopUSD; currSLPct=StopLossPorc;
   currFiboHours=FiboHours_Def;
   h_ema20 = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   h_ema50 = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
   h_rsi   = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   LoadSettings(); 
   EventSetTimer(1); CrearHUD(); UpdateAutoFibo();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) { SaveSettings(); ObjectsDeleteAll(0, P_TAG); }
void OnTick() { UpdateAutoFibo(); ManageStrategy(); ProtectPositions(); dayPnL = CalculateFullDayPnL(); ActualizarHUD(); DrawPainLine(); DrawProtectionRadar(); }
void OnTimer() { if(!MQLInfoInteger(MQL_TESTER) && ActivarNewsFilter) CheckRemoteNews(); else remotePaused = false; }

double CalculateAutoLot(double slPrice) {
   if(!currAutoLot) return MinLotsManual;
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = bal * (currRisk / 100.0);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double price = isBullish ? ask : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double diff = MathAbs(price - slPrice);
   if(diff <= 0 || tickSize <= 0 || tickVal <= 0) return MinLotsManual;
   double lots = riskMoney / ((diff / tickSize) * tickVal);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   lots = MathFloor(lots / step) * step;
   return fmax(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), fmin(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX), NormalizeDouble(lots, 2)));
}

double GetFirstPositionVolume() { for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER) return pos.Volume(); return 0; }
double GetFirstPositionOpenPrice() { for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER) return pos.PriceOpen(); return 0; }

double ValidSL(double price, bool buy) {
   double stopsLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(buy) { if(price > ask - stopsLevel) price = ask - stopsLevel - 5*_Point; }
   else { if(price < bid + stopsLevel && price > 0) price = bid + stopsLevel + 5*_Point; }
   return NormalizeDouble(price, _Digits);
}

void UpdateAutoFibo() {
   if(PositionsTotalBots() > 0 && !currScaling) return;
   datetime tNow = TimeCurrent();
   datetime tStart = tNow - (currFiboHours * 3600);
   currBars = iBarShift(_Symbol, _Period, tStart);
   if(currBars < 2) currBars = 10;
   int hiIdx = iHighest(_Symbol, _Period, MODE_HIGH, currBars, 0);
   int liIdx = iLowest(_Symbol, _Period, MODE_LOW, currBars, 0);
   if(hiIdx < 0 || liIdx < 0) return;
   double vHi = iHigh(_Symbol, _Period, hiIdx), vLi = iLow(_Symbol, _Period, liIdx);
   double ema20[], ema50[]; ArraySetAsSeries(ema20,true); ArraySetAsSeries(ema50,true);
   CopyBuffer(h_ema20,0,0,1,ema20); CopyBuffer(h_ema50,0,0,1,ema50);
   bool nowBullish = (ema20[0] > ema50[0]);
   if(nowBullish != isBullish) {
      if(lastTrendChange == 0) lastTrendChange = TimeCurrent();
      trendConfirmed = (TimeCurrent() - lastTrendChange >= 300); 
      if(trendConfirmed) { isBullish = nowBullish; lastTrendChange = 0; }
   } else { lastTrendChange = 0; trendConfirmed = true; }
   if(isBullish) { f_p100 = vLi; f_t100 = iTime(_Symbol, _Period, liIdx); f_p0 = vHi; f_t0 = iTime(_Symbol, _Period, hiIdx); }
   else { f_p100 = vHi; f_t100 = iTime(_Symbol, _Period, hiIdx); f_p0 = vLi; f_t0 = iTime(_Symbol, _Period, liIdx); }
   double diff = f_p0 - f_p100;
   f_p38 = f_p100 + diff * 0.382; f_p50 = f_p100 + diff * 0.500; f_p61 = f_p100 + diff * 0.618; f_p78 = f_p100 + diff * 0.786;
   if(showFibo) { DrawFullFibo(); DrawRangeMarkers(tStart); DrawSignalArrow(); } 
   else { ObjectsDeleteAll(0, P_TAG+"fibo"); ObjectsDeleteAll(0, P_TAG+"zone"); ObjectsDeleteAll(0, P_TAG+"linea"); ObjectsDeleteAll(0, P_TAG+"arrow_price"); }
   DrawInteractiveLines();
}

void DrawFullFibo() {
   string n = P_TAG+"fibo"; datetime tDrawEnd = TimeCurrent() + 7200;
   if(ObjectFind(0,n)<0) { ObjectCreate(0,n,OBJ_FIBO,0,f_t100,f_p100,f_t0,f_p0); ObjectSetInteger(0,n,OBJPROP_BACK,true); ObjectSetInteger(0,n,OBJPROP_RAY_RIGHT,true); }
   ObjectSetInteger(0,n,OBJPROP_TIME,0,f_t100); ObjectSetDouble(0,n,OBJPROP_PRICE,0,f_p100);
   ObjectSetInteger(0,n,OBJPROP_TIME,1,f_t0); ObjectSetDouble(0,n,OBJPROP_PRICE,1,f_p0);
   ObjectSetInteger(0,n,OBJPROP_LEVELS,8);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,0,0.0); ObjectSetString(0,n,OBJPROP_LEVELTEXT,0,"🎯 TARGET (0.0)"); ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,0,clrLime);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,1,0.236); ObjectSetString(0,n,OBJPROP_LEVELTEXT,1,"REVERSIÓN (23.6)"); ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,1,clrOrangeRed);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,2,0.500); ObjectSetString(0,n,OBJPROP_LEVELTEXT,2,"50.0 (ELITE)"); ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,2,CLR_BLUE);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,3,0.618); ObjectSetString(0,n,OBJPROP_LEVELTEXT,3,"61.8 (ENTRY)"); ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,3,clrCyan);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,4,1.000); ObjectSetString(0,n,OBJPROP_LEVELTEXT,4,"INICIO (100.0)"); ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,4,clrSilver);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,5,currSLPct/100.0); ObjectSetString(0,n,OBJPROP_LEVELTEXT,5,"🛑 STOP ("+DoubleToString(currSLPct,1)+")"); ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,5,clrRed);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,6,0.382); ObjectSetString(0,n,OBJPROP_LEVELTEXT,6,"38.2 (RETR)"); ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,6,clrYellow);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,7,0.786); ObjectSetString(0,n,OBJPROP_LEVELTEXT,7,"REVERSIÓN (78.6)"); ObjectSetInteger(0,n,OBJPROP_LEVELCOLOR,7,clrOrangeRed);
   string zn = P_TAG+"zone";
   if(ObjectFind(0,zn)<0) { ObjectCreate(0,zn,OBJ_RECTANGLE,0,f_t100,f_p50,tDrawEnd,f_p61); ObjectSetInteger(0,zn,OBJPROP_COLOR,CLR_GP_STRONG); ObjectSetInteger(0,zn,OBJPROP_FILL,true); ObjectSetInteger(0,zn,OBJPROP_BACK,true); }
   else { ObjectSetInteger(0,zn,OBJPROP_TIME,0,f_t100); ObjectSetDouble(0,zn,OBJPROP_PRICE,0,f_p50); ObjectSetInteger(0,zn,OBJPROP_TIME,1,tDrawEnd); ObjectSetDouble(0,zn,OBJPROP_PRICE,1,f_p61); }
}

void DrawSignalArrow() {
   string n = P_TAG+"arrow_price"; double hi = iHigh(_Symbol,_Period,0), li = iLow(_Symbol,_Period,0);
   double priceArr = isBullish ? (li - 250*_Point) : (hi + 250*_Point);
   if(ObjectFind(0,n)<0) { ObjectCreate(0,n,OBJ_ARROW,0,TimeCurrent(),priceArr); ObjectSetInteger(0,n,OBJPROP_WIDTH,4); }
   ObjectSetInteger(0,n,OBJPROP_TIME,TimeCurrent()); ObjectSetDouble(0,n,OBJPROP_PRICE,priceArr);
   ObjectSetInteger(0,n,OBJPROP_COLOR,isBullish?CLR_BLUE:clrRed); 
   ObjectSetInteger(0,n,OBJPROP_ARROWCODE,isBullish?241:242);
}

void DrawInteractiveLines() {
   string slN=P_TAG+"SL"; double diff=f_p0-f_p100; double prSL=f_p0-diff*(currSLPct/100.0);
   if(ObjectFind(0,slN)<0) { ObjectCreate(0,slN,OBJ_HLINE,0,0,prSL); ObjectSetInteger(0,slN,OBJPROP_COLOR,clrRed); ObjectSetInteger(0,slN,OBJPROP_WIDTH,2); ObjectSetInteger(0,slN,OBJPROP_SELECTABLE,true); ObjectSetInteger(0,slN,OBJPROP_BACK,true); }
   if(!ObjectGetInteger(0,slN,OBJPROP_SELECTED)) ObjectSetDouble(0,slN,OBJPROP_PRICE,prSL);
}

void DrawPainLine() {
   int totalPos = 0; double netLots = 0; double sumOpenLots = 0;
   double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickVal <= 0 || tickSize <= 0) return;
   for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER) { totalPos++; double vol = pos.Volume(); if(pos.PositionType()==POSITION_TYPE_BUY) { netLots += vol; sumOpenLots += pos.PriceOpen() * vol; } else { netLots -= vol; sumOpenLots -= pos.PriceOpen() * vol; } }
   string name = P_TAG+"PAIN_LINE";
   if(totalPos == 0 || MathAbs(netLots) < 0.001) { ObjectDelete(0, name); return; }
   double painInTicker = (-currPainLimit / profitFactor) / (tickVal / tickSize);
   double exitPrice = netLots < 0 ? (sumOpenLots - painInTicker) / (-netLots) : (painInTicker + sumOpenLots) / netLots;
   datetime t1 = iTime(_Symbol, _Period, 25); datetime t2 = TimeCurrent() + 7200;
   if(ObjectFind(0, name) < 0) { ObjectCreate(0, name, OBJ_TREND, 0, t1, exitPrice, t2, exitPrice); ObjectSetInteger(0, name, OBJPROP_COLOR, clrRed); ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT); ObjectSetInteger(0, name, OBJPROP_WIDTH, 2); ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, true); }
   ObjectSetDouble(0, name, OBJPROP_PRICE, 0, exitPrice); ObjectSetDouble(0, name, OBJPROP_PRICE, 1, exitPrice); 
   ObjectSetInteger(0, name, OBJPROP_TIME, 0, t1); ObjectSetInteger(0, name, OBJPROP_TIME, 1, t2);
   ObjectSetString(0, name, OBJPROP_TEXT, " 🔥 TOPE DOLOR: -"+DoubleToString(currPainLimit,2)+"$");
}

void DrawProtectionRadar() {
   string radarName = P_TAG+"TRAIL_RADAR";
   int totalPos = 0; double totalVol = 0;
   double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickVal <= 0 || tickSize <= 0) return;
   for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER) { totalPos++; totalVol += pos.Volume(); }
   if(totalPos == 0) { ObjectDelete(0, radarName); ObjectsDeleteAll(0, P_TAG+"SL_LBL_"); return; }
   double price = isBullish ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double distT = (currTS * tickSize) / (totalVol * tickVal);
   double radarPrice = isBullish ? (price - distT) : (price + distT);
   datetime t1 = iTime(_Symbol, _Period, 30); datetime t2 = TimeCurrent() + 7200;
   if(ObjectFind(0, radarName) < 0) { ObjectCreate(0, radarName, OBJ_TREND, 0, t1, radarPrice, t2, radarPrice); ObjectSetInteger(0, radarName, OBJPROP_COLOR, clrMediumSpringGreen); ObjectSetInteger(0, radarName, OBJPROP_STYLE, STYLE_DASHDOT); ObjectSetInteger(0, radarName, OBJPROP_WIDTH, 1); ObjectSetInteger(0, radarName, OBJPROP_RAY_RIGHT, true); }
   ObjectSetDouble(0, radarName, OBJPROP_PRICE, 0, radarPrice); ObjectSetDouble(0, radarName, OBJPROP_PRICE, 1, radarPrice);
   ObjectSetInteger(0, radarName, OBJPROP_TIME, 0, t1); ObjectSetInteger(0, radarName, OBJPROP_TIME, 1, t2);
   ObjectSetString(0, radarName, OBJPROP_TEXT, " 📡 RADAR TRAILING");
   for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER) {
      string lbl = P_TAG+"SL_LBL_"+(string)pos.Ticket(); double sl = pos.StopLoss(); double op = pos.PriceOpen(); string txt = " [ RISK ]";
      if(isBullish && sl >= op) txt = " [ BLINDADO BE ]"; if(!isBullish && sl <= op && sl > 0) txt = " [ BLINDADO BE ]";
      if((pos.Profit()+pos.Swap()+pos.Commission())*profitFactor > currTS) txt = " [ TRAILING ACTIVO 🔥 ]";
      if(ObjectFind(0, lbl) < 0) { ObjectCreate(0, lbl, OBJ_TEXT, 0, TimeCurrent()+600, sl); ObjectSetInteger(0, lbl, OBJPROP_COLOR, clrWhite); ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE, 8); }
      ObjectSetDouble(0, lbl, OBJPROP_PRICE, sl); ObjectSetInteger(0, lbl, OBJPROP_TIME, TimeCurrent()+600); ObjectSetString(0, lbl, OBJPROP_TEXT, txt);
   }
}

void ManageStrategy() {
   if(!giroOn) { strategyLabel="BOT PAUSED (GIRO OFF)"; statusLabel="N/A"; return; }
   double rsi[], ema20[], ema50[]; ArraySetAsSeries(rsi,true); ArraySetAsSeries(ema20,true); ArraySetAsSeries(ema50,true);
   CopyBuffer(h_rsi,0,0,1,rsi); CopyBuffer(h_ema20,0,0,1,ema20); CopyBuffer(h_ema50,0,0,1,ema50);
   double price=SymbolInfoDouble(_Symbol,SYMBOL_BID); double totD=MathAbs(f_p0-f_p100);
   double pct=(totD>0)?(MathAbs(price-f_p100)/totD)*100:0;
   bool rsiF=!UsarFiltroRSI || (isBullish?rsi[0]<RSILimiteAlto:rsi[0]>RSILimiteBajo);
   int posTotal=PositionsTotalBots();
   if(lastTrendChange>0) statusLabel="ESPERANDO CONFIRMACIÓN...";
   else {
       if(pct>=50.0 && pct<=61.8) statusLabel=isBullish?"POSIBLE COMPRA (ELITE)":"POSIBLE VENTA (ELITE)";
       else if(pct<50.0) statusLabel="ESPERANDO RETROCESO";
       else statusLabel="ZONA DE RIESGO / STOP";
   }
   bool canEntry=(posTotal==0 && pct>=50.0 && pct<=61.8 && trendConfirmed);
   bool canScaling=(currScaling && posTotal>0 && posTotal<3 && IsAllTradesSecured());
   strategyLabel=StringSubstr(_Symbol,0,3)+(isBullish?" 📈 ALCISTA":" 📉 BAJISTA")+(posTotal>0?" (x"+(string)posTotal+")":"");
   if(AccountInfoInteger(ACCOUNT_TRADE_EXPERT) && !remotePaused && (canEntry?rsiF:true) && (canEntry || canScaling)) {
       double slRaw=ObjectGetDouble(0,P_TAG+"SL",OBJPROP_PRICE); double sl=ValidSL(slRaw,isBullish); double lots=CalculateAutoLot(sl);
       if(canScaling) { lots = GetFirstPositionVolume(); sl = ValidSL(GetFirstPositionOpenPrice(), isBullish); }
       bool success=false;
       if(isBullish && ema20[0]>ema50[0]) success=trade.Buy(lots,_Symbol,SymbolInfoDouble(_Symbol,SYMBOL_ASK),sl,0,STR_COMMENT);
       if(!isBullish && ema20[0]<ema50[0]) success=trade.Sell(lots,_Symbol,SymbolInfoDouble(_Symbol,SYMBOL_BID),sl,0,STR_COMMENT);
       if(success && sonidoOn && TimeCurrent()>lastSoundTime+5) { PlaySound("ok.wav"); lastSoundTime=TimeCurrent(); }
   }
}

bool IsAllTradesSecured() {
   int secured=0; int total=0;
   for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER) { total++; if(pos.PositionType()==POSITION_TYPE_BUY && pos.StopLoss()>=pos.PriceOpen()) secured++; if(pos.PositionType()==POSITION_TYPE_SELL && pos.StopLoss()<=pos.PriceOpen() && pos.StopLoss()>0) secured++; }
   return (total>0 && secured==total);
}

void ProtectPositions() {
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID), ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double tickV=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE), tickS=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double slLine=ObjectGetDouble(0,P_TAG+"SL",OBJPROP_PRICE); if(tickV<=0 || tickS<=0) return;
   double totalPnL=0; int totalPos=0;
   for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER) { totalPos++; totalPnL+=(pos.Profit()+pos.Swap()+pos.Commission())*profitFactor; }
   double price=SymbolInfoDouble(_Symbol,SYMBOL_BID); double pctCurrent=(MathAbs(f_p0-f_p100)>0)?(MathAbs(price-f_p100)/MathAbs(f_p0-f_p100))*100:0;
   if(giroOn && totalPos>0) { if(totalPnL<-currPainLimit || pctCurrent<50.0) { CloseAll(); return; } }
   for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER) {
      double vol=pos.Volume(); ENUM_POSITION_TYPE type=pos.PositionType(); double pUSD=(pos.Profit()+pos.Swap()+pos.Commission())*profitFactor, newSL=pos.StopLoss(), openP=pos.PriceOpen();
      double distG=(currGarantia*tickS)/(vol*tickV), distT=(currTS*tickS)/(vol*tickV);
      if(type==POSITION_TYPE_BUY) { if(pUSD>currBE && (newSL<openP || newSL==0)) newSL=openP+distG; if(pUSD>currTS && (bid-distT)>newSL) newSL=bid-distT; if(slLine>0 && slLine<bid && slLine>newSL) newSL=slLine; }
      else { if(pUSD>currBE && (newSL>openP || newSL==0)) newSL=openP-distG; if(pUSD>currTS && (ask+distT)<newSL && ask+distT>0) newSL=ask+distT; if(slLine>ask && (slLine<newSL || newSL==0)) newSL=slLine; }
      if(MathAbs(newSL-pos.StopLoss())>_Point) trade.PositionModify(pos.Ticket(),NormalizeDouble(newSL,_Digits),0);
   }
}

void CloseAll() { for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER) trade.PositionClose(pos.Ticket()); }

void OnTradeTransaction(const MqlTradeTransaction& trans, const MqlTradeRequest& req, const MqlTradeResult& res) {
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD) {
      if(HistoryDealSelect(trans.deal)) {
         long magic = HistoryDealGetInteger(trans.deal, DEAL_MAGIC);
         if(magic == MAGIC_NUMBER) {
            ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
            double price = HistoryDealGetDouble(trans.deal, DEAL_PRICE);
            datetime time = (datetime)HistoryDealGetInteger(trans.deal, DEAL_TIME);
            string name = P_TAG+"MKR_"+(string)trans.deal;
            if(entry == DEAL_ENTRY_IN) {
               long type = HistoryDealGetInteger(trans.deal, DEAL_TYPE);
               color c = (type == DEAL_TYPE_BUY) ? CLR_BLUE : clrRed;
               ObjectCreate(0, name, OBJ_ARROW, 0, time, price);
               ObjectSetInteger(0, name, OBJPROP_ARROWCODE, (type == DEAL_TYPE_BUY) ? 241 : 242);
               ObjectSetInteger(0, name, OBJPROP_COLOR, c); ObjectSetInteger(0, name, OBJPROP_WIDTH, 3);
            } else if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_INOUT) {
               double profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
               color c = (profit > 0) ? CLR_GOLD : clrGray;
               ObjectCreate(0, name, OBJ_ARROW, 0, time, price);
               ObjectSetInteger(0, name, OBJPROP_ARROWCODE, 251); // Checkmark/Star
               ObjectSetInteger(0, name, OBJPROP_COLOR, c); ObjectSetInteger(0, name, OBJPROP_WIDTH, 4);
            }
         }
      }
   }
}

void ActualizarHUD() { 
   if(ObjectFind(0,P_TAG+"pV")>=0) ObjectSetString(0,P_TAG+"pV",OBJPROP_TEXT,"PnL HOY: "+DoubleToString(dayPnL,2)+" $ / RIESGO "+DoubleToString(currRisk,1)+"%"); 
   if(ObjectFind(0,P_TAG+"stV")>=0) ObjectSetString(0,P_TAG+"stV",OBJPROP_TEXT,"MODO: "+strategyLabel);
   if(ObjectFind(0,P_TAG+"l_nx")>=0) ObjectSetString(0,P_TAG+"l_nx",OBJPROP_TEXT,"ESTADO: "+statusLabel); 
   string tf=(_Period==PERIOD_M15)?"15m":(_Period==PERIOD_M5?"5m":(_Period==PERIOD_H1?"1h":"-"));
   if(ObjectFind(0,P_TAG+"l_fib")>=0) ObjectSetString(0,P_TAG+"l_fib",OBJPROP_TEXT,"SCAN: "+(string)currFiboHours+"h ("+(string)currBars+" velas de "+tf+")");
}

void DrawRangeMarkers(datetime tStart) {
   string n1=P_TAG+"linea_ini", n2=P_TAG+"linea_fin"; datetime tNow=TimeCurrent();
   if(ObjectFind(0,n1)<0) { ObjectCreate(0,n1,OBJ_VLINE,0,tStart,0); ObjectSetInteger(0,n1,OBJPROP_COLOR,C'40,40,40'); ObjectSetInteger(0,n1,OBJPROP_STYLE,STYLE_DOT); } else ObjectSetInteger(0,n1,OBJPROP_TIME,tStart);
   if(ObjectFind(0,n2)<0) { ObjectCreate(0,n2,OBJ_VLINE,0,tNow,0); ObjectSetInteger(0,n2,OBJPROP_COLOR,C'40,40,40'); ObjectSetInteger(0,n2,OBJPROP_STYLE,STYLE_DOT); } else ObjectSetInteger(0,n2,OBJPROP_TIME,tNow);
}

void CrearHUD() {
   ObjectsDeleteAll(0, P_TAG); int hx=15, hy=15, hw=365, hh=isMinimized?40:630;
   CrRect("bg",hx,hy,hw,hh,CLR_PANEL,CLR_BTC, 1500); 
   CrLabel("ttl",hx+15,hy+13,isMinimized?"₿ BTC RECALL":"🚀 BTC SNIPER v7.4.6",CLR_BTC,11,"Impact", 2000);
   color sndBg=sonidoOn?C'40,80,150':C'150,40,40';
   CrBtn("b_snd",hx+hw-100,hy+8,55,30,sonidoOn?"🔊":"🔇",sndBg,clrWhite, 2000);
   CrBtn("b_min",hx+hw-40,hy+8,35,30,isMinimized?"+":"-",C'60,60,80',clrWhite, 2000);
   if(isMinimized) return;
   CrLabel("pV",hx+15,hy+65,"PnL HOY: "+DoubleToString(dayPnL,2)+" $ / RIESGO "+DoubleToString(currRisk,1)+"%",clrWhite,10,"Arial Bold", 2000);
   CrBtn("b_reset",hx+hw-70,hy+62,55,22,"RESET",C'80,40,40',clrWhite, 2000);
   CrLabel("stV",hx+15,hy+95,"MODO: "+strategyLabel,clrCyan,10,"Arial Bold", 2000);
   CrLabel("l_nx",hx+15,hy+120,"ESTADO: "+statusLabel,clrOrange,9,"Arial", 2000);
   CrBtn("b_zen",hx+10,hy+155,172,35,"RE-CONFIG ELITE",CLR_BLUE,clrWhite, 2000); 
   CrBtn("b_har",hx+186,hy+155,168,35,"SCALING AGGRE",C'120,45,25',clrWhite, 2000);
   int ry=210, c1=hx+15, c2=hx+235;
   CrLabel("l_lot",c1,ry+3,"Riesgo % Trade:",clrSilver,9,"Arial", 2000); CrEdit("e_lot",c2,ry,50,22,DoubleToString(currRisk,1), 2000); ry+=35;
   CrLabel("l_fib",c1,ry+3,"Fibo Horas: ...",clrSilver,9,"Arial", 2000); CrEdit("e_fib",c2,ry,50,22,IntegerToString(currFiboHours), 2000); ry+=35;
   CrLabel("l_be",c1,ry+3,"Break-Even ($):",clrSilver,9,"Arial", 2000); CrEdit("e_be",c2,ry,50,22,DoubleToString(currBE,2), 2000); ry+=35;
   CrLabel("l_gar",c1,ry+3,"GARANTÍA ($):",CLR_BTC,9,"Arial Bold", 2000); CrEdit("e_gar",c2,ry,50,22,DoubleToString(currGarantia,2), 2000); ry+=35;
   CrLabel("l_ts",c1,ry+3,"Trailing ($):",clrSilver,9,"Arial", 2000); CrEdit("e_ts",c2,ry,50,22,DoubleToString(currTS,2), 2000); ry+=35;
   CrLabel("l_pain",c1,ry+3,"TOPE DOLOR ($):",clrRed,10,"Arial Black", 2000); CrEdit("e_pain",c2,ry,50,22,DoubleToString(currPainLimit,2), 2000); ry+=35;
   CrLabel("l_slp",c1,ry+3,"Stop %:",clrSilver,9,"Arial", 2000); CrEdit("e_slp",c2,ry,50,22,DoubleToString(currSLPct,1), 2000); ry+=45;
   CrBtn("v_ma",hx+10,ry,113,32,"EMA",showEMA?CLR_BLUE:C'40,40,40',clrWhite,2000);
   CrBtn("v_rsi",hx+126,ry,113,32,"RSI",showRSI?C'150,80,40':C'40,40,40',clrWhite,2000);
   CrBtn("v_fib",hx+242,ry,113,32,"FIBO",showFibo?CLR_BTC:C'40,40,40',clrWhite,2000); ry+=45;
   CrBtn("b_giro",hx+10,ry,(int)(hw/2-15),35,"GIRO: "+(giroOn?"ON":"OFF"),giroOn?clrGreen:clrRed,clrWhite,2000);
   CrBtn("b_cas",hx+(int)(hw/2+5),ry,(int)(hw/2-15),35,"CASCADA: "+(currScaling?"ON":"OFF"),currScaling?clrGreen:clrRed,clrWhite,2000); ry+=42;
   CrBtn("b_app",hx+10,ry,(int)(hw*0.60),42,"APLICAR CAMBIOS",C'40,80,150',clrWhite,2000);
   CrBtn("b_cls",hx+(int)(hw*0.60+15),ry,(int)(hw*0.35),42,"CERRAR",C'150,40,40',clrWhite,2000);
}

void OnChartEvent(const int id,const long &lp,const double &dp,const string &sp) {
   if(id==CHARTEVENT_OBJECT_CLICK) {
      if(sp==P_TAG+"b_zen")   { currRisk=0.5; currBE=5.0; currTS=7.0; currScaling=false; currGarantia=3.0; SaveSettings(); CrearHUD(); UpdateAutoFibo(); }
      if(sp==P_TAG+"b_har")   { currRisk=2.0; currBE=2.0; currTS=3.0; currScaling=true; currGarantia=1.5; SaveSettings(); CrearHUD(); UpdateAutoFibo(); }
      if(sp==P_TAG+"b_reset") { GlobalVariablesDeleteAll(P_TAG); currRisk=PorcRiesgo_Def; currBE=BreakEvenUSD; currTS=TrailingStopUSD; currGarantia=TrailGarantia_Def; currFiboHours=FiboHours_Def; SaveSettings(); UpdateAutoFibo(); CrearHUD(); }
      if(sp==P_TAG+"b_snd")   { sonidoOn=!sonidoOn; SaveSettings(); CrearHUD(); }
      if(sp==P_TAG+"b_app")   { SaveSettings(); UpdateAutoFibo(); CrearHUD(); }
      if(sp==P_TAG+"b_min")   { isMinimized=!isMinimized; CrearHUD(); }
      if(sp==P_TAG+"v_ma")    { showEMA=!showEMA; CrearHUD(); }
      if(sp==P_TAG+"v_rsi")   { showRSI=!showRSI; CrearHUD(); }
      if(sp==P_TAG+"v_fib")   { showFibo=!showFibo; UpdateAutoFibo(); CrearHUD(); }
      if(sp==P_TAG+"b_giro")  { giroOn=!giroOn; SaveSettings(); CrearHUD(); }
      if(sp==P_TAG+"b_cas")   { currScaling=!currScaling; SaveSettings(); CrearHUD(); }
      if(sp==P_TAG+"b_cls")   { CloseAll(); }
      ObjectSetInteger(0,sp,OBJPROP_STATE,false);
   }
   if(id==CHARTEVENT_OBJECT_DRAG && sp==P_TAG+"SL") { double p=ObjectGetDouble(0,sp,OBJPROP_PRICE); double totD=MathAbs(f_p100-f_p0); if(totD>0) { currSLPct=(MathAbs(p-f_p0)/totD)*100; ObjectSetString(0,P_TAG+"e_slp",OBJPROP_TEXT,DoubleToString(currSLPct,1)); } }
   if(id==CHARTEVENT_OBJECT_ENDEDIT) {
      if(sp==P_TAG+"e_lot") currRisk=StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==P_TAG+"e_fib") currFiboHours=(int)StringToInteger(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==P_TAG+"e_be")  currBE=StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==P_TAG+"e_ts")  currTS=StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==P_TAG+"e_gar") currGarantia=StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==P_TAG+"e_pain") currPainLimit=StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==P_TAG+"e_slp") currSLPct=StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      SaveSettings(); UpdateAutoFibo(); ActualizarHUD();
   }
}

//--- FUNCIONES AUXILIARES ---
void CrRect(string n,int x,int y,int w,int h,color bg,color bd,int z=200){ ObjectCreate(0,P_TAG+n,OBJ_RECTANGLE_LABEL,0,0,0); ObjectSetInteger(0,P_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,P_TAG+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,P_TAG+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,P_TAG+n,OBJPROP_YSIZE,h); ObjectSetInteger(0,P_TAG+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,P_TAG+n,OBJPROP_COLOR,bd); ObjectSetInteger(0,P_TAG+n,OBJPROP_ZORDER,z); }
void CrLabel(string n,int x,int y,string t,color c,int s,string f="Arial",int z=210){ ObjectCreate(0,P_TAG+n,OBJ_LABEL,0,0,0); ObjectSetInteger(0,P_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,P_TAG+n,OBJPROP_YDISTANCE,y); ObjectSetString(0,P_TAG+n,OBJPROP_TEXT,t); ObjectSetInteger(0,P_TAG+n,OBJPROP_COLOR,c); ObjectSetInteger(0,P_TAG+n,OBJPROP_FONTSIZE,s); ObjectSetString(0,P_TAG+n,OBJPROP_FONT,f); ObjectSetInteger(0,P_TAG+n,OBJPROP_ZORDER,z); }
void CrBtn(string n,int x,int y,int w,int h,string t,color bg,color tc,int z=220){ ObjectCreate(0,P_TAG+n,OBJ_BUTTON,0,0,0); ObjectSetInteger(0,P_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,P_TAG+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,P_TAG+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,P_TAG+n,OBJPROP_YSIZE,h); ObjectSetString(0,P_TAG+n,OBJPROP_TEXT,t); ObjectSetInteger(0,P_TAG+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,P_TAG+n,OBJPROP_COLOR,tc); ObjectSetInteger(0,P_TAG+n,OBJPROP_ZORDER,z); }
void CrEdit(string n,int x,int y,int w,int h,string t,int z=220){ ObjectCreate(0,P_TAG+n,OBJ_EDIT,0,0,0); ObjectSetInteger(0,P_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,P_TAG+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,P_TAG+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,P_TAG+n,OBJPROP_YSIZE,h); ObjectSetString(0,P_TAG+n,OBJPROP_TEXT,t); ObjectSetInteger(0,P_TAG+n,OBJPROP_BGCOLOR,C'25,25,35'); ObjectSetInteger(0,P_TAG+n,OBJPROP_COLOR,clrWhite); ObjectSetInteger(0,P_TAG+n,OBJPROP_ZORDER,z); ObjectSetInteger(0,P_TAG+n,OBJPROP_ALIGN,ALIGN_CENTER); }
double CalculateFullDayPnL() { MqlDateTime dt; TimeToStruct(TimeCurrent(), dt); dt.hour=0; dt.min=0; dt.sec=0; HistorySelect(StructToTime(dt), TimeCurrent()); double p=0; for(int i=HistoryDealsTotal()-1; i>=0; i--) { ulong t=HistoryDealGetTicket(i); if(HistoryDealGetString(t, DEAL_SYMBOL) == _Symbol && HistoryDealGetInteger(t, DEAL_MAGIC) == MAGIC_NUMBER) p += HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_SWAP) + HistoryDealGetDouble(t, DEAL_COMMISSION); } return p * profitFactor; }
int PositionsTotalBots() { int c=0; for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER) c++; return c; }
void CheckRemoteNews() { char data[], res[]; string h; int s = WebRequest("GET","https://kopytrading.com/api/news-filter",NULL,NULL,500,data,0,res,h); if(s==200) remotePaused = (StringFind(CharArrayToString(res),"PAUSE")>=0); }
void LoadSettings() { string m=IntegerToString(MAGIC_NUMBER); if(GlobalVariableCheck(P_TAG+"risk"+m)) currRisk=GlobalVariableGet(P_TAG+"risk"+m); if(GlobalVariableCheck(P_TAG+"be"+m)) currBE=GlobalVariableGet(P_TAG+"be"+m); if(GlobalVariableCheck(P_TAG+"gar"+m)) currGarantia=GlobalVariableGet(P_TAG+"gar"+m); if(GlobalVariableCheck(P_TAG+"ts"+m)) currTS=GlobalVariableGet(P_TAG+"ts"+m); if(GlobalVariableCheck(P_TAG+"fib"+m)) currFiboHours=(int)GlobalVariableGet(P_TAG+"fib"+m); if(GlobalVariableCheck(P_TAG+"pain"+m)) currPainLimit=GlobalVariableGet(P_TAG+"pain"+m); if(GlobalVariableCheck(P_TAG+"slp"+m)) currSLPct=GlobalVariableGet(P_TAG+"slp"+m); if(GlobalVariableCheck(P_TAG+"snd"+m)) sonidoOn=(GlobalVariableGet(P_TAG+"snd"+m)>0.5); }
void SaveSettings() { string m=IntegerToString(MAGIC_NUMBER); GlobalVariableSet(P_TAG+"risk"+m,currRisk); GlobalVariableSet(P_TAG+"be"+m,currBE); GlobalVariableSet(P_TAG+"gar"+m,currGarantia); GlobalVariableSet(P_TAG+"ts"+m,currTS); GlobalVariableSet(P_TAG+"fib"+m,currFiboHours); GlobalVariableSet(P_TAG+"pain"+m,currPainLimit); GlobalVariableSet(P_TAG+"slp"+m,currSLPct); GlobalVariableSet(P_TAG+"snd"+m,sonidoOn?1.0:0.0); GlobalVariablesFlush(); }

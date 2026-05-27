//+------------------------------------------------------------------+
//|     KOPYTRADE_v78_SCALING_XAU.mq5                                |
//|   XAU IRONCLAD v7.4.7 | SNIPER | RESCUE | SCALING PRO             |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "7.47"
#property strict
#property description "⚜️ XAU v7.4.7 IRONCLAD | B1-B2 Scaling | Edge Rescue"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- DEFINES ---
#define P_TAG "EVO_V7_X_" 
#define MAGIC_NUMBER 780001
#define STR_COMMENT "EVO_V7_XAU"
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

input group "== GESTIÓN DE RIESGO v7.4.7 =="
input bool     UsarAutoLote_Def  = true;         
input double   PorcRiesgo_Def    = 0.5;          
input double   MinLotsManual     = 0.04;        

input group "== CONFIGURACIÓN TÁCTICA =="
input int      FiboHours_Def     = 12;           
input double   StopLossPorc      = 105.0;        
input bool     GiroOn            = true;         // Permite entrar en contra (Edge)
input bool     CascadaOn         = true;         // Permite entrar a favor (Bala 2)

//--- GLOBALES ---
CTrade         trade;
CPositionInfo  pos;
int            h_ema20, h_ema50, h_rsi;
double         profitFactor = 1.0, dayPnL = 0;
string         statusLabel = "INIT", strategyLabel = "ESPERANDO";
bool           remotePaused = false, isBullish = true, isMinimized = false;
bool           showEMA=true, showRSI=true, showFibo=true, sonidoOn=true;
double         f_p0=0, f_p100=0, f_p38=0, f_p50=0, f_p61=0;
datetime       f_t0, f_t100, lastTrendChange = 0;
bool           trendConfirmed = false;
double         currRisk, currSLPct;
int            currFiboHours;

//--- BALA_1 SETTINGS ---
double b1_BE_USD = 3.00, b1_G_USD = 2.00, b1_T_USD = 5.00;
//--- BALA_2 SETTINGS ---
double b2_BE_USD = 2.00, b2_G_USD = 1.00, b2_T_USD = 4.00;
//--- EDGE SETTINGS ---
double edge_BE_USD = 3.00, edge_G_USD = 2.00, edge_T_USD = 5.00;

//+------------------------------------------------------------------+
int OnInit() {
   trade.SetExpertMagicNumber(MAGIC_NUMBER);
   profitFactor = ForceCentMode ? CentFactor : 1.0;
   currRisk=PorcRiesgo_Def; currSLPct=StopLossPorc; currFiboHours=FiboHours_Def;
   h_ema20 = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   h_ema50 = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
   h_rsi   = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   LoadSettings(); 
   EventSetTimer(1); CrearHUD(); UpdateAutoFibo();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) { SaveSettings(); ObjectsDeleteAll(0, P_TAG); }
void OnTick() { UpdateAutoFibo(); ManageStrategy(); ProtectPositions(); dayPnL = CalculateFullDayPnL(); ActualizarHUD(); }
void OnTimer() { if(!MQLInfoInteger(MQL_TESTER) && ActivarNewsFilter) CheckRemoteNews(); else remotePaused = false; }

double CalculateAutoLot() {
   if(!UsarAutoLote_Def) return MinLotsManual;
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = bal * (currRisk / 100.0);
   double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double range = MathAbs(f_p0 - f_p100) * (currSLPct/100.0); 
   if(range <= 0 || tickVal <= 0) return MinLotsManual;
   double lots = riskMoney / ((range / tickSize) * tickVal);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   lots = MathFloor(lots / step) * step;
   return fmax(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), fmin(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX), NormalizeDouble(lots, 2)));
}

void UpdateAutoFibo() {
   if(PositionsTotalBots() > 0 && !CascadaOn) return;
   datetime tNow = TimeCurrent();
   datetime tStart = tNow - (currFiboHours * 3600);
   int bars = iBarShift(_Symbol, _Period, tStart);
   if(bars < 2) bars = 10;
   int hiIdx = iHighest(_Symbol, _Period, MODE_HIGH, bars, 0);
   int liIdx = iLowest(_Symbol, _Period, MODE_LOW, bars, 0);
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
   f_p38 = f_p100 + diff * 0.382; f_p50 = f_p100 + diff * 0.500; f_p61 = f_p100 + diff * 0.618;
   if(showFibo) DrawFullFibo(); 
}

void DrawFullFibo() {
   string n = P_TAG+"fibo";
   if(ObjectFind(0,n)<0) { ObjectCreate(0,n,OBJ_FIBO,0,f_t100,f_p100,f_t0,f_p0); ObjectSetInteger(0,n,OBJPROP_BACK,true); ObjectSetInteger(0,n,OBJPROP_RAY_RIGHT,true); }
   ObjectSetInteger(0,n,OBJPROP_TIME,0,f_t100); ObjectSetDouble(0,n,OBJPROP_PRICE,0,f_p100);
   ObjectSetInteger(0,n,OBJPROP_TIME,1,f_t0); ObjectSetDouble(0,n,OBJPROP_PRICE,1,f_p0);
   ObjectSetInteger(0,n,OBJPROP_LEVELS,5);
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,0,0.0); ObjectSetString(0,n,OBJPROP_LEVELTEXT,0,"🎯 TARGET (0.0)");
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,1,0.382); ObjectSetString(0,n,OBJPROP_LEVELTEXT,1,"ZONA ENTRADA (38.2)");
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,2,0.500); ObjectSetString(0,n,OBJPROP_LEVELTEXT,2,"MITAD (50.0)");
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,3,0.618); ObjectSetString(0,n,OBJPROP_LEVELTEXT,3,"GIRO / EDGE (61.8)");
   ObjectSetDouble(0,n,OBJPROP_LEVELVALUE,4,currSLPct/100.0); ObjectSetString(0,n,OBJPROP_LEVELTEXT,4,"🛑 STOP LOSS");
}

void ManageStrategy() {
   double rsi[1], ema20[1], ema50[1], high[1], low[1];
   if(CopyBuffer(h_rsi,0,0,1,rsi)<=0 || CopyBuffer(h_ema20,0,0,1,ema20)<=0 || CopyBuffer(h_ema50,0,0,1,ema50)<=0) return;
   CopyHigh(_Symbol,_Period,0,1,high); CopyLow(_Symbol,_Period,0,1,low);
   
   // --- FILTRO INDECISIÓN ---
   if((ema20[0] < high[0] && ema20[0] > low[0]) || (ema50[0] < high[0] && ema50[0] > low[0])) {
      statusLabel = "LATERAL / INDECISIÓN ⏸️"; return;
   }

   double price = SymbolInfoDouble(_Symbol, isBullish ? SYMBOL_ASK : SYMBOL_BID);
   double totalRange = MathAbs(f_p0 - f_p100);
   double pct = (totalRange > 0) ? (MathAbs(price - f_p100) / totalRange) * 100 : 0;
   
   // --- BALA 1: ENTRADA (Zona Smart 38.2 - 50) ---
   bool inZone = (pct >= 38.2 && pct <= 50.0);
   if(PositionsTotalBots() == 0 && inZone && trendConfirmed) {
      double lots = CalculateAutoLot();
      double sl = f_p100 - (f_p0 - f_p100) * (currSLPct/100.0);
      if(isBullish && price > ema20[0]) trade.Buy(lots, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_ASK), sl, 0, "EVO_V7_B1");
      if(!isBullish && price < ema20[0]) trade.Sell(lots, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_BID), sl, 0, "EVO_V7_B1");
   }

   // --- BALA 2: CASCADA (Si B1 esta en BE de +$2) ---
   if(CascadaOn && GetPositionProfit("EVO_V7_B1") >= b1_BE_USD && CountPositions("EVO_V7_B2") == 0) {
      double lots = CalculateAutoLot() * 0.8; 
      double sl = ValidSL(GetPositionOpenPrice("EVO_V7_B1"), isBullish);
      if(isBullish) trade.Buy(lots, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_ASK), sl, 0, "EVO_V7_B2");
      else trade.Sell(lots, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_BID), sl, 0, "EVO_V7_B2");
   }

   // --- MODO EDGE: GIRO (Cruza 61.8% en contra) ---
   if(GiroOn && pct > 61.8 && CountPositions("EVO_V7_RESCUE") == 0) {
      double lots = CalculateAutoLot() * 1.5; 
      if(isBullish) {
         if(trade.Sell(lots, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_BID), 0, 0, "EVO_V7_RESCUE")) PlaySound("alert.wav");
      } else {
         if(trade.Buy(lots, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_ASK), 0, 0, "EVO_V7_RESCUE")) PlaySound("alert.wav");
      }
   }

   statusLabel = isBullish ? "📈 ALCISTA (TRABAJANDO)" : "📉 BAJISTA (TRABAJANDO)";
   strategyLabel = StringSubstr(_Symbol, 0, 3) + " x" + (string)PositionsTotalBots();
}

void ProtectPositions() {
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE), ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tv <= 0 || ts <= 0) return;

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(pos.SelectByIndex(i) && pos.Magic() == MAGIC_NUMBER) {
         string comm = pos.Comment();
         double pUSD = (pos.Profit() + pos.Swap() + pos.Commission()) * profitFactor;
         double vol = pos.Volume(), openP = pos.PriceOpen(), curSL = pos.StopLoss(), newSL = curSL;
         
         // --- BALA 1 PROTECTION ---
         if(comm == "EVO_V7_B1") {
            double distG = (b1_G_USD * ts) / (vol * tv), distT = (b1_T_USD * ts) / (vol * tv);
            if(pos.PositionType()==POSITION_TYPE_BUY) {
               if(pUSD >= b1_BE_USD && (newSL < openP + distG)) newSL = openP + distG;
               if(pUSD >= b1_T_USD && (bid - distT) > newSL) newSL = bid - distT;
               // Panic Exit: 50% SL distance
               double slDist = MathAbs(openP - curSL);
               if(pUSD < 0 && MathAbs(bid - openP) > slDist * 0.5 && CountPositions("EVO_V7_RESCUE") > 0) {
                  trade.PositionClose(pos.Ticket()); continue;
               }
            } else {
               if(pUSD >= b1_BE_USD && (newSL > openP - distG || newSL == 0)) newSL = openP - distG;
               if(pUSD >= b1_T_USD && (ask + distT) < newSL && ask + distT > 0) newSL = ask + distT;
               double slDist = MathAbs(openP - curSL);
               if(pUSD < 0 && MathAbs(ask - openP) > slDist * 0.5 && CountPositions("EVO_V7_RESCUE") > 0) {
                  trade.PositionClose(pos.Ticket()); continue;
               }
            }
         }
         // --- BALA 2 PROTECTION ---
         else if(comm == "EVO_V7_B2") {
            double distG = (b2_G_USD * ts) / (vol * tv), distT = (b2_T_USD * ts) / (vol * tv);
            if(pos.PositionType()==POSITION_TYPE_BUY) {
               if(pUSD >= b2_BE_USD && (newSL < openP + distG)) newSL = openP + distG;
               if(pUSD >= b2_T_USD && (bid - distT) > newSL) newSL = bid - distT;
            } else {
               if(pUSD >= b2_BE_USD && (newSL > openP - distG || newSL == 0)) newSL = openP - distG;
               if(pUSD >= b2_T_USD && (ask + distT) < newSL && ask + distT > 0) newSL = ask + distT;
            }
         }
         // --- RESCUE PROTECTION ---
         else if(comm == "EVO_V7_RESCUE") {
            double distG = (edge_G_USD * ts) / (vol * tv), distT = (edge_T_USD * ts) / (vol * tv);
            if(pos.PositionType()==POSITION_TYPE_BUY) {
               if(pUSD >= edge_BE_USD && (newSL < openP + distG)) newSL = openP + distG;
               if(pUSD >= edge_T_USD && (bid - distT) > newSL) newSL = bid - distT;
            } else {
               if(pUSD >= edge_BE_USD && (newSL > openP - distG || newSL == 0)) newSL = openP - distG;
               if(pUSD >= edge_T_USD && (ask + distT) < newSL && ask + distT > 0) newSL = ask + distT;
            }
         }

         if(MathAbs(newSL - curSL) > _Point) trade.PositionModify(pos.Ticket(), NormalizeDouble(newSL, _Digits), 0);
      }
   }
}

//--- HELPERS ---
double GetPositionProfit(string comment) { for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER && pos.Comment()==comment) return (pos.Profit()+pos.Swap()+pos.Commission())*profitFactor; return -999; }
double GetPositionOpenPrice(string comment) { for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER && pos.Comment()==comment) return pos.PriceOpen(); return 0; }
int CountPositions(string comment) { int c=0; for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER && pos.Comment()==comment) c++; return c; }
int PositionsTotalBots() { int c=0; for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER) c++; return c; }
void CloseAll() { for(int i=PositionsTotal()-1; i>=0; i--) if(pos.SelectByIndex(i) && pos.Magic()==MAGIC_NUMBER) trade.PositionClose(pos.Ticket()); }
double ValidSL(double price, bool buy) { double stp = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point; double b = SymbolInfoDouble(_Symbol, SYMBOL_BID), a = SymbolInfoDouble(_Symbol, SYMBOL_ASK); if(buy) { if(price > a - stp) price = a - stp - 5*_Point; } else { if(price < b + stp && price > 0) price = b + stp + 5*_Point; } return NormalizeDouble(price, _Digits); }

void ActualizarHUD() { 
   if(ObjectFind(0,P_TAG+"pV")>=0) ObjectSetString(0,P_TAG+"pV",OBJPROP_TEXT,"PnL HOY: "+DoubleToString(dayPnL,2)+" $ / RIESGO "+DoubleToString(currRisk,1)+"%"); 
   if(ObjectFind(0,P_TAG+"stV")>=0) ObjectSetString(0,P_TAG+"stV",OBJPROP_TEXT,statusLabel);
   if(ObjectFind(0,P_TAG+"l_nx")>=0) ObjectSetString(0,P_TAG+"l_nx",OBJPROP_TEXT,"MODO: "+strategyLabel); 
}

void CrearHUD() {
   ObjectsDeleteAll(0, P_TAG); int hx=15, hy=15, hw=365, hh=isMinimized?40:630;
   CrRect("bg",hx,hy,hw,hh,CLR_PANEL,CLR_GOLD, 1500); 
   CrLabel("ttl",hx+15,hy+13,isMinimized?"⚜️ XAU RECALL":"🛡️ XAU IRONCLAD v7.4.7",CLR_GOLD,11,"Impact", 2000);
   CrBtn("b_min",hx+hw-40,hy+8,35,30,isMinimized?"+":"-",C'60,60,80',clrWhite, 2000);
   if(isMinimized) return;
   CrLabel("pV",hx+15,hy+65,"PnL HOY: "+DoubleToString(dayPnL,2)+" $ / RIESGO "+DoubleToString(currRisk,1)+"%",clrWhite,10,"Arial Bold", 2000);
   CrLabel("stV",hx+15,hy+95,statusLabel,clrCyan,10,"Arial Bold", 2000);
   CrLabel("l_nx",hx+15,hy+120,"MODO: "+strategyLabel,clrOrange,9,"Arial", 2000);
   CrBtn("b_giro",hx+10,hy+155,172,35,"GIRO: "+(GiroOn?"ON":"OFF"),GiroOn?clrGreen:clrRed,clrWhite,2000);
   CrBtn("b_cas",hx+186,hy+155,168,35,"CASCADA: "+(CascadaOn?"ON":"OFF"),CascadaOn?clrGreen:clrRed,clrWhite,2000); 
   CrBtn("b_cls",hx+10,hy+hh-60,hw-20,45,"CERRAR TODO",C'150,40,40',clrWhite,2000);
}

void OnChartEvent(const int id,const long &lp,const double &dp,const string &sp) {
   if(id==CHARTEVENT_OBJECT_CLICK) {
      if(sp==P_TAG+"b_min")   { isMinimized=!isMinimized; CrearHUD(); }
      if(sp==P_TAG+"b_giro")  { GiroOn=!GiroOn; SaveSettings(); CrearHUD(); }
      if(sp==P_TAG+"b_cas")   { CascadaOn=!CascadaOn; SaveSettings(); CrearHUD(); }
      if(sp==P_TAG+"b_cls")   { CloseAll(); }
      ObjectSetInteger(0,sp,OBJPROP_STATE,false);
   }
}

void CheckRemoteNews() { char data[], res[]; string h; int s = WebRequest("GET","https://kopytrading.com/api/news-filter",NULL,NULL,500,data,0,res,h); if(s==200) remotePaused = (StringFind(CharArrayToString(res),"PAUSE")>=0); }
void LoadSettings() { string m=IntegerToString(MAGIC_NUMBER); if(GlobalVariableCheck(P_TAG+"risk"+m)) currRisk=GlobalVariableGet(P_TAG+"risk"+m); if(GlobalVariableCheck(P_TAG+"fib"+m)) currFiboHours=(int)GlobalVariableGet(P_TAG+"fib"+m); }
void SaveSettings() { string m=IntegerToString(MAGIC_NUMBER); GlobalVariableSet(P_TAG+"risk"+m,currRisk); GlobalVariableSet(P_TAG+"fib"+m,currFiboHours); GlobalVariablesFlush(); }
void CrRect(string n,int x,int y,int w,int h,color bg,color bd,int z=200){ ObjectCreate(0,P_TAG+n,OBJ_RECTANGLE_LABEL,0,0,0); ObjectSetInteger(0,P_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,P_TAG+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,P_TAG+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,P_TAG+n,OBJPROP_YSIZE,h); ObjectSetInteger(0,P_TAG+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,P_TAG+n,OBJPROP_COLOR,bd); ObjectSetInteger(0,P_TAG+n,OBJPROP_ZORDER,z); }
void CrLabel(string n,int x,int y,string t,color c,int s,string f="Arial",int z=210){ ObjectCreate(0,P_TAG+n,OBJ_LABEL,0,0,0); ObjectSetInteger(0,P_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,P_TAG+n,OBJPROP_YDISTANCE,y); ObjectSetString(0,P_TAG+n,OBJPROP_TEXT,t); ObjectSetInteger(0,P_TAG+n,OBJPROP_COLOR,c); ObjectSetInteger(0,P_TAG+n,OBJPROP_FONTSIZE,s); ObjectSetString(0,P_TAG+n,OBJPROP_FONT,f); ObjectSetInteger(0,P_TAG+n,OBJPROP_ZORDER,z); }
void CrBtn(string n,int x,int y,int w,int h,string t,color bg,color tc,int z=220){ ObjectCreate(0,P_TAG+n,OBJ_BUTTON,0,0,0); ObjectSetInteger(0,P_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,P_TAG+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,P_TAG+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,P_TAG+n,OBJPROP_YSIZE,h); ObjectSetString(0,P_TAG+n,OBJPROP_TEXT,t); ObjectSetInteger(0,P_TAG+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,P_TAG+n,OBJPROP_COLOR,tc); ObjectSetInteger(0,P_TAG+n,OBJPROP_ZORDER,z); }
double CalculateFullDayPnL() { MqlDateTime dt; TimeToStruct(TimeCurrent(), dt); dt.hour=0; dt.min=0; dt.sec=0; HistorySelect(StructToTime(dt), TimeCurrent()); double p=0; for(int i=HistoryDealsTotal()-1; i>=0; i--) { ulong t=HistoryDealGetTicket(i); if(HistoryDealGetString(t, DEAL_SYMBOL) == _Symbol && HistoryDealGetInteger(t, DEAL_MAGIC) == MAGIC_NUMBER) p += HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_SWAP) + HistoryDealGetDouble(t, DEAL_COMMISSION); } return p * profitFactor; }

//+------------------------------------------------------------------+
//|    KOPYTRADE_BTCUSD_EVOLUTION_v8_1 - PRICE MASTER PRO            |
//|   STRICT FIBO + TIME FILTERS + DD PROTECTION + SIDEWAYS FILTER   |
//|   Copyright 2026, Kopytrading Corp. - kopytrading.com            |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "8.10"
#property strict
#property description "PRICE MASTER v8.1 PRO | BTC Institutional Settings"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- ENUMS ---
enum ENUM_FIBO_LEVEL { LVL_NONE, LVL_38, LVL_50, LVL_61 };

//--- PARÁMETROS ---
sinput string separator0 = "=========================="; // === SEGURIDAD ===
input string   LicenseKey        = "TRIAL-2026";
input bool     ForceCentMode     = true;

sinput string separator1 = "=========================="; // === GESTIÓN v8.1 PRO ===
input int      MagicNumber       = 800900;
input double   LotSize           = 0.03;      
input int      MaxOpenTrades     = 2;         
input double   MaxDrawdownPct    = 10.0;      
input int      MinImpulsePts     = 20000;     // Filtro para BTC (Volatilidad mayor)

sinput string separator2 = "=========================="; // === PROTECCIÓN v8.2.1 ===
input int      MaxReEntries      = 2;         
input int      MaxLateEntryPts   = 1000;      // BTC late entry (100 pts)
input int      MinM5Vol          = 200;       // BTC min volatility
input int      MaxM5Vol          = 50000;     // BTC news filter
input int      BE_Trigger        = 5000;      
input int      BE_Profit         = 1000;      
input int      TrailingStart     = 8000;      
input int      TrailingDist      = 5000;      
input int      StartHour         = 8;         
input int      EndHour           = 22;        

//--- ESTRUCTURAS ---
struct LevelStats { int entries; int be_streak; bool locked; };
LevelStats stats[4]; // 1:38, 2:50, 3:61

//--- GLOBALES ESTRUCTURALES ---
double f_0=0, f_38=0, f_50=0, f_61=0, f_78=0, f_100=0;
int    f_dir = 0; 
int    SwingLookback = 168;

//--- GLOBALES ---
CTrade         trade;
CPositionInfo  posInfo;
int            activeMagic;
double         profitFactor = 1.0;
string         botStatus = "SCANNING CRYPTO...", PNL = "AEVO_v81PMBTC";

// Fibonacci Data
// double f_0=0, f_38=0, f_50=0, f_61=0, f_100=0; // Duplicated, removed
// int    f_dir = 0; // Duplicated, removed
// int    SwingLookback = 168; // 1 semana H1 // Duplicated, removed

int OnInit() {
   activeMagic = MagicNumber;
   trade.SetExpertMagicNumber(activeMagic);
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if((tv < 0.1 && AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL) || ForceCentMode) profitFactor = 0.01;
   CrearHUD();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) { ObjectsDeleteAll(0, PNL); ObjectsDeleteAll(0, "FIBO_MAP_BTC_MASTER"); }

void OnTick() {
   CheckDDProtection();
   UpdateMarketStructure();
   DrawFiboMap();
   
   if(IsTradingTime()) {
      CheckLevelLocks();
      double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      bool broken = (f_dir == 1 && price <= f_78) || (f_dir == -1 && price >= f_78);
      
      if(!broken) {
         if(PositionsTotalBots() < MaxOpenTrades) {
            if(MathAbs(f_0 - f_100) > MinImpulsePts * _Point) {
               ScanForEntries();
               if(PositionsTotalBots()==0) botStatus = "🎯 ARCHITECT BTC HUNTING...";
            } else botStatus = "WEAK STRUCTURE (RANGE)";
         } else botStatus = "MAX EXPOSURE";
      } else botStatus = "STRUCTURE BROKEN (78.6)";
      
   } else botStatus = "Zzz (OFF SESSION)";
   
   if(PositionsTotalBots() > 0) {
      ManageCascadeExit();
      ManageShield();
   }
   ActualizarHUD();
}

bool IsTradingTime() {
   MqlDateTime dt; TimeCurrent(dt); return (dt.hour >= StartHour && dt.hour < EndHour);
}

void CheckDDProtection() {
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   double eq  = AccountInfoDouble(ACCOUNT_EQUITY);
   if(bal > 0 && ((bal - eq) / bal) * 100.0 >= MaxDrawdownPct) {
      CloseAllBotPositions();
      botStatus = "PROTECCIÓN DD ACTIVADA";
   }
}

void CloseAllBotPositions() {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) trade.PositionClose(posInfo.Ticket());
   }
}

void UpdateMarketStructure() {
   int hh_idx = iHighest(_Symbol, PERIOD_H1, MODE_HIGH, SwingLookback, 1);
   int ll_idx = iLowest(_Symbol, PERIOD_H1, MODE_LOW, SwingLookback, 1);
   if(hh_idx == -1 || ll_idx == -1) return;
   double hh = iHigh(_Symbol, PERIOD_H1, hh_idx);
   double ll = iLow(_Symbol, PERIOD_H1, ll_idx);
   if(hh_idx < ll_idx) { f_dir = 1; f_100 = ll; f_0 = hh; }
   else { f_dir = -1; f_100 = hh; f_0 = ll; }
   double range = MathAbs(f_0 - f_100);
   if(f_dir == 1) {
      f_38  = f_0 - range * 0.382; f_50 = f_0 - range * 0.500; f_61 = f_0 - range * 0.618; f_78 = f_0 - range * 0.786;
   } else {
      f_38  = f_0 + range * 0.382; f_50 = f_0 + range * 0.500; f_61 = f_0 + range * 0.618; f_78 = f_0 + range * 0.786;
   }
}

void ScanForEntries() {
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(f_dir == 1) {
      if(price <= f_38 && price > f_50 && !HasLevelPos("v81_L38") && !stats[LVL_38].locked) TryConfirm(LVL_38, POSITION_TYPE_BUY);
      if(price <= f_50 && price > f_61 && !HasLevelPos("v81_L50") && !stats[LVL_50].locked) TryConfirm(LVL_50, POSITION_TYPE_BUY);
      if(price <= f_61 && price > f_100 && !HasLevelPos("v81_L61") && !stats[LVL_61].locked) TryConfirm(LVL_61, POSITION_TYPE_BUY);
   } else {
      if(price >= f_38 && price < f_50 && !HasLevelPos("v81_L38") && !stats[LVL_38].locked) TryConfirm(LVL_38, POSITION_TYPE_SELL);
      if(price >= f_50 && price < f_61 && !HasLevelPos("v81_L50") && !stats[LVL_50].locked) TryConfirm(LVL_50, POSITION_TYPE_SELL);
      if(price >= f_61 && price < f_100 && !HasLevelPos("v81_L61") && !stats[LVL_61].locked) TryConfirm(LVL_61, POSITION_TYPE_SELL);
   }
}

void TryConfirm(ENUM_FIBO_LEVEL lvl, ENUM_POSITION_TYPE type) {
   MqlRates rates[];
   if(CopyRates(_Symbol, PERIOD_M5, 0, 1, rates) < 1) return;
   double range = rates[0].high - rates[0].low;
   
   if(range < MinM5Vol * _Point || range > MaxM5Vol * _Point) {
      botStatus = "BTC VOL. EXTREMA - SKIP"; return;
   }
   
   double targetPrice = (lvl == LVL_38) ? f_38 : (lvl == LVL_50 ? f_50 : f_61);
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(MathAbs(price - targetPrice) / _Point > MaxLateEntryPts) {
      botStatus = "BTC LATE ENTRY SKIP"; return;
   }
   
   double hw = rates[0].high - MathMax(rates[0].close, rates[0].open);
   double lw = MathMin(rates[0].close, rates[0].open) - rates[0].low;
   
   bool wickOk  = (type == POSITION_TYPE_BUY) ? (lw > range * 0.6) : (hw > range * 0.6);
   bool colorOk = (type == POSITION_TYPE_BUY) ? (rates[0].close > rates[0].open) : (rates[0].close < rates[0].open);
   
   if(wickOk && colorOk) {
      string c = "v82_L"+IntegerToString(lvl);
      if(type == POSITION_TYPE_BUY) trade.Buy(LotSize, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_ASK), 0, 0, c);
      else trade.Sell(LotSize, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_BID), 0, 0, c);
      stats[lvl].entries++;
      botStatus = "BTC L"+IntegerToString(lvl)+" MASTER";
   }
}

void ManageCascadeExit() {
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) {
         if((f_dir == 1 && price < f_100) || (f_dir == -1 && price > f_100)) { trade.PositionClose(posInfo.Ticket()); continue; }
         if((f_dir == 1 && price >= f_0) || (f_dir == -1 && price <= f_0)) { trade.PositionClose(posInfo.Ticket()); continue; }
         string cmd = posInfo.Comment();
         if(cmd == "v81_L38" && HasLevelPos("v81_L50")) {
            double mid = (f_50 + f_61) / 2.0;
            if((f_dir == 1 && price >= mid) || (f_dir == -1 && price <= mid)) trade.PositionClose(posInfo.Ticket());
         }
      }
   }
}

void ManageShield() {
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) {
         double open = posInfo.PriceOpen();
         double pnlPoints = (posInfo.PositionType()==POSITION_TYPE_BUY) ? (price - open) : (open - price);
         pnlPoints /= _Point;
         
         double newSL = 0;
         if(pnlPoints >= BE_Trigger && posInfo.StopLoss() == 0) {
            newSL = (posInfo.PositionType()==POSITION_TYPE_BUY) ? (open + BE_Profit*_Point) : (open - BE_Profit*_Point);
            trade.PositionModify(posInfo.Ticket(), newSL, 0);
            
            int lvlIdx = (int)StringToInteger(StringSubstr(posInfo.Comment(), 5));
            if(lvlIdx > 0) stats[lvlIdx].be_streak++;
         }
         
         if(pnlPoints >= TrailingStart) {
            double trailSL = (posInfo.PositionType()==POSITION_TYPE_BUY) ? (price - TrailingDist*_Point) : (price + TrailingDist*_Point);
            if(posInfo.PositionType()==POSITION_TYPE_BUY) {
               if(posInfo.StopLoss() < trailSL) trade.PositionModify(posInfo.Ticket(), trailSL, 0);
            } else {
               if(posInfo.StopLoss() > trailSL || posInfo.StopLoss() == 0) trade.PositionModify(posInfo.Ticket(), trailSL, 0);
            }
         }
      }
   }
}

bool HasLevelPos(string c) { for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic && posInfo.Comment()==c) return true; return false; }

void DrawFiboMap() {
   ObjectsDeleteAll(0, "FIBO_LVL_BTC_");
   
   string dirTxt = (f_dir == 1) ? " (BTC BUY)" : " (BTC SELL)";
   color  cM      = C'120,120,160';
   
   // Pintar niveles con etiquetas de texto explícitas para BTC
   CrFLine("L38", f_38, cM, dirTxt + " 38.2% - T1");
   CrFLine("L50", f_50, cM, dirTxt + " 50.0% - T2");
   CrFLine("L61", f_61, C'200,100,100', dirTxt + " 61.8% - GOLD");
   CrFLine("L78", f_78, C'80,80,90', " !!! 78.6% - BROKEN !!!");
   CrFLine("TP", f_0,  C'0,255,100', dirTxt + " 0.0% - TARGET");
   CrFLine("SL", f_100, clrRed, " 100.0% - STOP");
}

void CrFLine(string n, double p, color c, string t) {
   string name = "F_LVL_BTC_"+n;
   if(!ObjectCreate(0, name, OBJ_HLINE, 0, 0, p)) return;
   ObjectSetInteger(0, name, OBJPROP_COLOR, c);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetString(0, name, OBJPROP_TEXT, t);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
}

void CrearHUD() {
   ObjectsDeleteAll(0, PNL);
   int x=15, y=15, w=300, h=250;
   CrRect("bg",x,y,w,h,C'10,10,25',C'80,80,150',2);
   CrLabel("ttl",x+15,y+10,"🏗️ EVO v8.2 BTC ARCHITECT",clrWhite,10,"Arial Bold");
   int cy = y+45;
   CrLabel("stL",x+20,cy,"STATUS:",C'150,150,200',8);
   CrLabel("stV",x+130,cy,botStatus,C'0,255,127',9);
   cy += 25;
   CrLabel("trL",x+20,cy,"TREND H1:",C'150,150,200',8);
   CrLabel("trV",x+130,cy,"...",clrYellow,9);
   cy += 35;
   CrRect("sep",x+15,cy,270,1,C'50,50,80',C'50,50,80');
   cy += 15;
   CrLabel("hiL",x+20,cy,"BTC HIGH:",C'1 host,150,200',7);
   CrLabel("hiV",x+130,cy,"0.00",clrWhite,8);
   cy += 20;
   CrLabel("loL",x+20,cy,"BTC LOW:",C'150,150,200',7);
   CrLabel("loV",x+130,cy,"0.00",clrWhite,8);
   cy += 35;
   CrLabel("ddL",x+20,cy,"DD SAFETY:",C'150,150,200',8);
   CrLabel("ddV",x+130,cy,DoubleToString(MaxDrawdownPct,1)+" %",clrRed,9);
}

void CheckLevelLocks() {
   for(int i=1; i<=3; i++) {
      if(stats[i].entries >= MaxReEntries) stats[i].locked = true;
      if(stats[i].be_streak >= 2) stats[i].locked = true;
   }
}

void ActualizarHUD() {
   ObjectSetString(0,PNL+"stV",OBJPROP_TEXT,botStatus);
   string trendTxt = (f_dir == 1 ? "🚀 BULLISH" : (f_dir == -1 ? "📉 BEARISH" : "WAITING..."));
   color trendCol = (f_dir == 1 ? C'0,255,150' : (f_dir == -1 ? C'255,100,100' : clrYellow));
   ObjectSetString(0,PNL+"trV",OBJPROP_TEXT,trendTxt);
   ObjectSetInteger(0,PNL+"trV",OBJPROP_COLOR,trendCol);

   for(int i=1; i<=3; i++) {
     if(stats[i].locked) botStatus = "L"+IntegerToString(i)+" BLOQUEADO (SAFE)";
   }
   
   ObjectSetString(0,PNL+"hiV",OBJPROP_TEXT,DoubleToString(f_dir==1 ? f_0 : f_100, _Digits));
   ObjectSetString(0,PNL+"loV",OBJPROP_TEXT,DoubleToString(f_dir==1 ? f_100 : f_0, _Digits));
}

void CrRect(string n,int x,int y,int w,int h,color bg,color bd,int bw=1) { ObjectCreate(0,PNL+n,OBJ_RECTANGLE_LABEL,0,0,0); ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h); ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,bd); }
void CrLabel(string n,int x,int y,string t,color c,int s,string f="Segoe UI") { ObjectCreate(0,PNL+n,OBJ_LABEL,0,0,0); ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y); ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,c); ObjectSetInteger(0,PNL+n,OBJPROP_FONTSIZE,s); }
int PositionsTotalBots() { int c=0; for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) c++; return c; }

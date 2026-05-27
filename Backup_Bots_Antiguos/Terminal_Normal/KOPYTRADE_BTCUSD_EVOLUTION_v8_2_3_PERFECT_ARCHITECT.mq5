//+------------------------------------------------------------------+
//|    KOPYTRADE_BTCUSD_EVOLUTION_v8_2_3 - PERFECT ARCHITECT           |
//|   STRICT FIBO + IRON FILTERS + DD PROTECTION + M5 CONFIRMATION  |
//|   Copyright 2026, Kopytrading Corp. - kopytrading.com            |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "8.23"
#property strict
#property description "BTC ELITE ARCHITECT v8.2.3 | Perfect Institutional Suite"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- ENUMS ---
enum ENUM_FIBO_LEVEL { LVL_NONE, LVL_38, LVL_50, LVL_61 };

//--- PARÁMETROS ---
sinput string separator0 = "=========================="; // === SEGURIDAD ===
input string   LicenseKey        = "TRIAL-2026";
input bool     ForceCentMode     = true;

sinput string separator1 = "=========================="; // === GESTIÓN v8.2 IRON ===
input int      MagicNumber       = 800901;
input double   LotSize           = 0.03;      
input int      MaxOpenTrades     = 2;         
input double   MaxDrawdownPct    = 10.0;      
input int      MinImpulsePts     = 20000;      

sinput string separator2 = "=========================="; // === PROTECCIÓN v8.2.1 ===
input int      MaxReEntries      = 2;         
input int      MaxLateEntryPts   = 1000;       
input int      MinM5Vol          = 200;        
input int      MaxM5Vol          = 50000;      
input int      BE_Trigger        = 5000;       
input int      BE_Profit         = 1000;        
input int      TrailingStart     = 8000;       
input int      TrailingDist      = 5000;      
input int      StartHour         = 8;         
input int      EndHour           = 22;        

//--- ESTRUCTURAS ---
struct LevelStats { int entries; int be_streak; bool locked; };
LevelStats stats[4];

//--- GLOBALES ---
CTrade         trade;
CPositionInfo  posInfo;
int            activeMagic;
double         profitFactor = 1.0;
string         botStatus = "STARTING BTC...", PNL = "AEVO_v821_BTC";

double f_0=0, f_38=0, f_50=0, f_61=0, f_78=0, f_100=0;
int    f_dir = 0; 
int    SwingLookback = 168;

int OnInit() {
   activeMagic = MagicNumber;
   trade.SetExpertMagicNumber(activeMagic);
   if(ForceCentMode) profitFactor = 0.01;
   CrearHUD();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) { ObjectsDeleteAll(0, PNL); ObjectsDeleteAll(0, "F_LVL_BTC_"); }

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
               if(PositionsTotalBots()==0) botStatus = "🎯 BTC ARCHITECT HUNTING...";
            } else botStatus = "CRYPTO RANGE - WAIT";
         } else botStatus = "MAX EXPOSURE BTC";
      } else botStatus = "BTC STRUCTURE BROKEN (78.6)";
   } else botStatus = "Zzz (OFF SESSION)";
   
   if(PositionsTotalBots() > 0) { ManageCascadeExit(); ManageShield(); }
   ActualizarHUD();
}

bool IsTradingTime() {
   MqlDateTime dt;
   TimeCurrent(dt);
   return (dt.hour >= StartHour && dt.hour < EndHour);
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
   f_38 = (f_dir==1)?f_0-range*0.382:f_0+range*0.382;
   f_50 = (f_dir==1)?f_0-range*0.500:f_0+range*0.500;
   f_61 = (f_dir==1)?f_0-range*0.618:f_0+range*0.618;
   f_78 = (f_dir==1)?f_0-range*0.786:f_0+range*0.786;
}

void ScanForEntries() {
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(f_dir == 1) {
      if(price <= f_38 && price > f_50 && !HasLevelPos("v821_L3") && !stats[1].locked) TryConfirm(LVL_38, POSITION_TYPE_BUY);
      if(price <= f_50 && price > f_61 && !HasLevelPos("v821_L5") && !stats[2].locked) TryConfirm(LVL_50, POSITION_TYPE_BUY);
      if(price <= f_61 && price > f_78 && !HasLevelPos("v821_L6") && !stats[3].locked) TryConfirm(LVL_61, POSITION_TYPE_BUY);
   } else {
      if(price >= f_38 && price < f_50 && !HasLevelPos("v821_L3") && !stats[1].locked) TryConfirm(LVL_38, POSITION_TYPE_SELL);
      if(price >= f_50 && price < f_61 && !HasLevelPos("v821_L5") && !stats[2].locked) TryConfirm(LVL_50, POSITION_TYPE_SELL);
      if(price >= f_61 && price < f_78 && !HasLevelPos("v821_L6") && !stats[3].locked) TryConfirm(LVL_61, POSITION_TYPE_SELL);
   }
}

void TryConfirm(ENUM_FIBO_LEVEL lvl, ENUM_POSITION_TYPE type) {
   MqlRates rates[];
   if(CopyRates(_Symbol, PERIOD_M5, 0, 1, rates) < 1) return;
   double range = rates[0].high - rates[0].low;
   if(range < MinM5Vol*_Point || range > MaxM5Vol*_Point) { botStatus = "BTC VOL. FILTER SKIP"; return; }
   
   double target = (lvl==LVL_38)?f_38:(lvl==LVL_50?f_50:f_61);
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(MathAbs(price - target)/_Point > MaxLateEntryPts) { botStatus = "BTC LATE ENTRY SKIP"; return; }
   
   double hw = rates[0].high - MathMax(rates[0].close, rates[0].open);
   double lw = MathMin(rates[0].close, rates[0].open) - rates[0].low;
   bool wickOk  = (type == POSITION_TYPE_BUY) ? (lw > range * 0.6) : (hw > range * 0.6);
   bool colorOk = (type == POSITION_TYPE_BUY) ? (rates[0].close > rates[0].open) : (rates[0].close < rates[0].open);
   
   if(wickOk && colorOk) {
      string c = "v822_L"+IntegerToString(lvl);
      if(type == POSITION_TYPE_BUY) trade.Buy(LotSize, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_ASK), 0, 0, c);
      else trade.Sell(LotSize, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_BID), 0, 0, c);
      int idx = (lvl==LVL_38?1:(lvl==LVL_50?2:3));
      stats[idx].entries++;
      botStatus = "BTC "+IntegerToString(lvl)+" ELITE";
   }
}

void ManageCascadeExit() {
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) {
         if((f_dir == 1 && price < f_100) || (f_dir == -1 && price > f_100)) { trade.PositionClose(posInfo.Ticket()); continue; }
         if((f_dir == 1 && price >= f_0) || (f_dir == -1 && price <= f_0)) { trade.PositionClose(posInfo.Ticket()); continue; }
         
         string cmd = posInfo.Comment();
         if(StringSubstr(cmd,0,7) == "v821_L3" && HasLevelPos("v821_L5")) {
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
         
         if(pnlPoints >= BE_Trigger && posInfo.StopLoss() == 0) {
            double newSL = (posInfo.PositionType()==POSITION_TYPE_BUY) ? (open + BE_Profit*_Point) : (open - BE_Profit*_Point);
            trade.PositionModify(posInfo.Ticket(), newSL, 0);
            int idx = (int)StringToInteger(StringSubstr(posInfo.Comment(), 7));
            if(idx > 0 && idx <= 3) stats[idx].be_streak++;
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

void DrawFiboMap() {
   ObjectsDeleteAll(0, "F_LVL_BTC_");
   ObjectsDeleteAll(0, "F_LBL_BTC_");
   string dir = (f_dir == 1) ? "BUY" : "SELL";
   
   // 1. ZONA DE ORO BTC
   CrZone("GZone", f_50, f_61, C'20,30,40');
   
   // 2. LÍNEAS BTC
   CrFLine("38", f_38, C'160,160,180', "38.2% - T1", 1);
   CrFLine("50", f_50, C'180,200,255', "50.0% - T2", 2);
   CrFLine("61", f_61, C'255,150,0',   "61.8% - GOLD", 3);
   CrFLine("78", f_78, C'255,50,50',   "!!! 78.6% - BREAK !!!", 2);
   CrFLine("00", f_0,  C'0,255,150',   "TARGET 0.0%", 1);
   CrFLine("100", f_100, C'255,100,100', "STOP 100.0%", 1);
}

void CrFLine(string n, double p, color c, string t, int w=1) {
   string name = "F_LVL_BTC_"+n;
   ObjectCreate(0, name, OBJ_HLINE, 0, 0, p);
   ObjectSetInteger(0, name, OBJPROP_COLOR, c);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, w);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   
   string lname = "F_LBL_BTC_"+n;
   ObjectCreate(0, lname, OBJ_TEXT, 0, TimeCurrent()+3600*4, p);
   ObjectSetString(0, lname, OBJPROP_TEXT, "  ◀ BTC " + t);
   ObjectSetInteger(0, lname, OBJPROP_COLOR, c);
   ObjectSetInteger(0, lname, OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, lname, OBJPROP_FONT, "Arial Black");
   ObjectSetInteger(0, lname, OBJPROP_SELECTABLE, false);
}

void CrZone(string n, double p1, double p2, color c) {
   string name = "F_LVL_BTC_"+n;
   ObjectCreate(0, name, OBJ_RECTANGLE, 0, TimeCurrent()-3600*24, p1, TimeCurrent()+3600*24, p2);
   ObjectSetInteger(0, name, OBJPROP_COLOR, c);
   ObjectSetInteger(0, name, OBJPROP_FILL, true);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

void CrearHUD() {
   ObjectsDeleteAll(0, PNL);
   int x=15, y=40, w=280, h=220;
   CrRect("bg",x,y,w,h,C'10,15,30',C'100,150,250',2);
   CrLabel("ttl",x+15,y+10,"🏗️ EVO v8.2.3 BTC ELITE ARCHITECT",C'100,200,255',10,"Impact");
   CrLabel("stL",x+15,y+45,"MODE:",C'150,150,200',8,"Arial");
   CrLabel("stV",x+80,y+45,botStatus,clrWhite,9,"Arial Black");
}

void CheckLevelLocks() {
   for(int i=1; i<=3; i++) {
      if(stats[i].entries >= MaxReEntries || stats[i].be_streak >= 2) stats[i].locked = true;
   }
}

void ActualizarHUD() {
   ObjectSetString(0,PNL+"stV",OBJPROP_TEXT,botStatus);
   ObjectSetString(0,PNL+"hi",OBJPROP_TEXT,"HI: "+DoubleToString(f_dir==1?f_0:f_100,_Digits));
   ObjectSetString(0,PNL+"lo",OBJPROP_TEXT,"LO: "+DoubleToString(f_dir==1?f_100:f_0,_Digits));
}

void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bdw) {
   string name = PNL+n;
   ObjectCreate(0, name, OBJ_RECT_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR, bd);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, bdw);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

void CrLabel(string n, int x, int y, string t, color c, int s, string f) {
   string name = PNL+n;
   ObjectCreate(0, name, OBJ_LABEL, 0,0,0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, t);
   ObjectSetInteger(0, name, OBJPROP_COLOR, c);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, s);
   ObjectSetString(0, name, OBJPROP_FONT, f);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

int PositionsTotalBots() { int c=0; for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) c++; return c; }
bool HasLevelPos(string c) { for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic && posInfo.Comment()==c) return true; return false; }

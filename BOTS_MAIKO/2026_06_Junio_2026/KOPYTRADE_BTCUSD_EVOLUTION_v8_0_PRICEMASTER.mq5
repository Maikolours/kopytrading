//+------------------------------------------------------------------+
//|   KOPYTRADE_BTCUSD_EVOLUTION_v8_0 - PRICE MASTER                 |
//|   STRICT FIBONACCI ENTRIES + M1 CONFIRMATION + CASCADE MGMT      |
//|   Copyright 2026, Kopytrading Corp. - kopytrading.com            |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "8.00"
#property strict
#property description "PRICE MASTER v8.0 | BTC Fibonacci Strategy"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- ENUMS ---
enum ENUM_FIBO_LEVEL { LVL_NONE, LVL_38, LVL_50, LVL_61 };

//--- PARÁMETROS ---
sinput string separator0 = "=========================="; // === SEGURIDAD ===
input string   LicenseKey        = "TRIAL-2026";
input bool     ForceCentMode     = true;

sinput string separator1 = "=========================="; // === GESTIÓN v8.0 ===
input int      MagicNumber       = 800900;
input double   LotSize           = 0.01;      
input int      SwingLookback     = 168;       // Velas H1 (1 semana aprox)
input bool     UseExtensions     = true;      

//--- GLOBALES ---
CTrade         trade;
CPositionInfo  posInfo;
int            activeMagic;
double         profitFactor = 1.0;
string         botStatus = "SCANNING CRYPTO", PNL = "AEVO_v80PMBTC";

// Fibonacci Data
double f_0=0, f_38=0, f_50=0, f_61=0, f_100=0, f_127=0, f_161=0;
int    f_dir = 0; 

int OnInit() {
   activeMagic = MagicNumber;
   trade.SetExpertMagicNumber(activeMagic);
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if((tv < 0.1 && AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL) || ForceCentMode) profitFactor = 0.01;
   CrearHUD();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) { ObjectsDeleteAll(0, PNL); ObjectsDeleteAll(0, "FIBO_MAP_BTC"); }

void OnTick() {
   UpdateMarketStructure();
   DrawFiboMap();
   if(PositionsTotalBots() == 0) ScanForEntries();
   else ManageCascadeExit();
   ActualizarHUD();
   ChartRedraw();
}

void UpdateMarketStructure() {
   int hh_idx = iHighest(_Symbol, PERIOD_H1, MODE_HIGH, SwingLookback, 1);
   int ll_idx = iLowest(_Symbol, PERIOD_H1, MODE_LOW, SwingLookback, 1);
   double hh = iHigh(_Symbol, PERIOD_H1, hh_idx);
   double ll = iLow(_Symbol, PERIOD_H1, ll_idx);
   if(hh_idx < ll_idx) { f_dir = 1; f_100 = ll; f_0 = hh; }
   else { f_dir = -1; f_100 = hh; f_0 = ll; }
   double range = MathAbs(f_0 - f_100);
   if(f_dir == 1) {
      f_38  = f_0 - range * 0.382; f_50  = f_0 - range * 0.500; f_61  = f_0 - range * 0.618;
      f_127 = f_0 + range * 0.272; f_161 = f_0 + range * 0.618;
   } else {
      f_38  = f_0 + range * 0.382; f_50  = f_0 + range * 0.500; f_61  = f_0 + range * 0.618;
      f_127 = f_0 - range * 0.272; f_161 = f_0 - range * 0.618;
   }
}

void ScanForEntries() {
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(f_dir == 1) {
      if(price <= f_38 && price > f_50) TryConfirm(LVL_38, POSITION_TYPE_BUY);
      if(price <= f_50 && price > f_61) TryConfirm(LVL_50, POSITION_TYPE_BUY);
      if(price <= f_61 && price > f_100) TryConfirm(LVL_61, POSITION_TYPE_BUY);
   } else {
      if(price >= f_38 && price < f_50) TryConfirm(LVL_38, POSITION_TYPE_SELL);
      if(price >= f_50 && price < f_61) TryConfirm(LVL_50, POSITION_TYPE_SELL);
      if(price >= f_61 && price < f_100) TryConfirm(LVL_61, POSITION_TYPE_SELL);
   }
}

void TryConfirm(ENUM_FIBO_LEVEL lvl, ENUM_POSITION_TYPE type) {
   MqlRates rates[];
   if(CopyRates(_Symbol, PERIOD_M1, 0, 2, rates) < 2) return;
   double body = MathAbs(rates[0].close - rates[0].open);
   double hw = rates[0].high - MathMax(rates[0].close, rates[0].open);
   double lw = MathMin(rates[0].close, rates[0].open) - rates[0].low;
   double range = rates[0].high - rates[0].low;
   if(range == 0) return;
   
   bool confirmed = false;
   if(type == POSITION_TYPE_BUY && lw > (range * 0.6)) confirmed = true;
   if(type == POSITION_TYPE_SELL && hw > (range * 0.6)) confirmed = true;
   
   if(confirmed) {
      string comment = "v80_L"+IntegerToString(lvl);
      if(type == POSITION_TYPE_BUY) trade.Buy(LotSize, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_ASK), 0, 0, comment);
      else trade.Sell(LotSize, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_BID), 0, 0, comment);
      botStatus = "BTC LEVEL "+IntegerToString(lvl);
   }
}

void ManageCascadeExit() {
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) {
         if((f_dir == 1 && price < f_100) || (f_dir == -1 && price > f_100)) { trade.PositionClose(posInfo.Ticket()); continue; }
         double target = UseExtensions ? f_161 : f_0;
         if((f_dir == 1 && price >= target) || (f_dir == -1 && price <= target)) { trade.PositionClose(posInfo.Ticket()); continue; }
         string cmd = posInfo.Comment();
         if(cmd == "v80_L38" && HasLevelPos("v80_L50")) {
            double mid = (f_50 + f_61) / 2.0;
            if((f_dir == 1 && price >= mid) || (f_dir == -1 && price <= mid)) trade.PositionClose(posInfo.Ticket());
         }
         if(cmd == "v80_L50" && HasLevelPos("v80_L61")) {
            double midToTP = (f_50 + f_0) / 2.0; 
            if((f_dir == 1 && price >= midToTP) || (f_dir == -1 && price <= midToTP)) trade.PositionClose(posInfo.Ticket());
         }
      }
   }
}

bool HasLevelPos(string c) { for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic && posInfo.Comment()==c) return true; return false; }

void DrawFiboMap() {
   string name = "FIBO_MAP_BTC_MASTER";
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_FIBO, 0, iTime(_Symbol, PERIOD_H1, SwingLookback), f_100, TimeCurrent(), f_0);
      ObjectSetInteger(0, name, OBJPROP_COLOR, C'70,70,90');
      ObjectSetInteger(0, name, OBJPROP_LEVELCOLOR, C'140,140,160');
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, true);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
   } else {
      ObjectMove(0, name, 0, iTime(_Symbol, PERIOD_H1, SwingLookback), f_100);
      ObjectMove(0, name, 1, TimeCurrent(), f_0);
   }
}

void CrFLine(string n, double p, color c, int w, string t="") {
   string name = "FIBO_MAP_BTC_"+n;
   ObjectCreate(0, name, OBJ_HLINE, 0, 0, p);
   ObjectSetInteger(0, name, OBJPROP_COLOR, c);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, w);
   ObjectSetString(0, name, OBJPROP_TEXT, t);
}

void CrFZone(string n, double p1, double p2, color c) {
   string name = "FIBO_MAP_BTC_"+n;
   datetime t1 = iTime(_Symbol, _Period, 48);
   datetime t2 = iTime(_Symbol, _Period, 0);
   ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, p1, t2, p2);
   ObjectSetInteger(0, name, OBJPROP_COLOR, c);
   ObjectSetInteger(0, name, OBJPROP_FILL, true);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
}

void CrearHUD() {
   ObjectsDeleteAll(0, PNL);
   int x=15, y=15, w=300, h=250;
   CrRect("bg",x,y,w,h,C'10,10,25',C'80,80,150',2);
   CrLabel("ttl",x+15,y+10,"💎 EVO v8.0 BTC MASTER",clrWhite,10,"Arial Bold");
   
   int cy = y+45;
   CrLabel("stL",x+20,cy,"STATUS:",C'150,150,200',8);
   CrLabel("stV",x+130,cy,botStatus,C'0,255,127',9);
   
   cy += 25;
   CrLabel("trL",x+20,cy,"TREND H1:",C'150,150,200',8);
   CrLabel("trV",x+130,cy,"...",clrYellow,9);
   
   cy += 35;
   CrRect("sep",x+15,cy,270,1,C'50,50,80',C'50,50,80');
   
   cy += 15;
   CrLabel("hiL",x+20,cy,"SWING HIGH:",C'150,150,200',7);
   CrLabel("hiV",x+130,cy,"0.00",clrWhite,8);
   
   cy += 20;
   CrLabel("loL",x+20,cy,"SWING LOW:",C'150,150,200',7);
   CrLabel("loV",x+130,cy,"0.00",clrWhite,8);
   
   cy += 20;
   CrLabel("raL",x+20,cy,"CRYPTO RANGE:",C'150,150,200',7);
   CrLabel("raV",x+130,cy,"0.00 pts",clrSilver,8);

   cy += 35;
   CrLabel("balL",x+20,cy,"ACCOUNT BALANCE:",C'150,150,200',8);
   CrLabel("balV",x+130,cy,DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2)+" USC",C'0,200,255',9);
}

void ActualizarHUD() { 
   ObjectSetString(0,PNL+"stV",OBJPROP_TEXT,botStatus); 
   string trendTxt = (f_dir == 1 ? "🚀 BULLISH" : (f_dir == -1 ? "📉 BEARISH" : "WAITING..."));
   color trendCol = (f_dir == 1 ? C'0,255,150' : (f_dir == -1 ? C'255,100,100' : clrYellow));
   ObjectSetString(0,PNL+"trV",OBJPROP_TEXT,trendTxt);
   ObjectSetInteger(0,PNL+"trV",OBJPROP_COLOR,trendCol);
   
   ObjectSetString(0,PNL+"hiV",OBJPROP_TEXT,DoubleToString(f_dir==1 ? f_0 : f_100, _Digits));
   ObjectSetString(0,PNL+"loV",OBJPROP_TEXT,DoubleToString(f_dir==1 ? f_100 : f_0, _Digits));
   ObjectSetString(0,PNL+"raV",OBJPROP_TEXT,DoubleToString(MathAbs(f_0-f_100)/_Point,0)+" pts");
}
void CrRect(string n,int x,int y,int w,int h,color bg,color bd,int bw=1) { ObjectCreate(0,PNL+n,OBJ_RECTANGLE_LABEL,0,0,0); ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h); ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,bd); }
void CrLabel(string n,int x,int y,string t,color c,int s,string f="Segoe UI") { ObjectCreate(0,PNL+n,OBJ_LABEL,0,0,0); ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y); ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,c); ObjectSetInteger(0,PNL+n,OBJPROP_FONTSIZE,s); }
int PositionsTotalBots() { int c=0; for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) c++; return c; }
void SyncWeb() {}

//+------------------------------------------------------------------+
//|    KOPYTRADE_XAUUSD_EVOLUTION_v8_1 - PRICE MASTER PRO            |
//|   STRICT FIBO + TIME FILTERS + DD PROTECTION + SIDEWAYS FILTER   |
//|   Copyright 2026, Kopytrading Corp. - kopytrading.com            |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "8.10"
#property strict
#property description "PRICE MASTER v8.1 PRO | Institutional Grade Settings"

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
input int      MagicNumber       = 800800;
input double   LotSize           = 0.03;      // Lote optimizado para 25k USC
input int      MaxOpenTrades     = 2;         // Límite de exposición
input double   MaxDrawdownPct    = 10.0;      // Cerrar todo al 10% DD
input int      MinImpulsePts     = 5000;      // Evitar mercados laterales (500 pips ORO)

sinput string separator2 = "=========================="; // === PROTECCIÓN v8.2.1 ===
input int      MaxReEntries      = 2;         // Máximo 2 intentos por nivel
input int      MaxLateEntryPts   = 100;       // Evitar entrar tarde (>10 pips)
input int      MinM5Vol          = 50;        // Mínimo tamaño vela M5 (pts)
input int      MaxM5Vol          = 1500;      // Máximo tamaño vela M5 (News)
input int      BE_Trigger        = 120;       
input int      BE_Profit         = 10;        
input int      TrailingStart     = 180;       
input int      TrailingDist      = 120;       
input int      StartHour         = 8;         
input int      EndHour           = 22;        // Nueva jornada ampliada

//--- ESTRUCTURAS ---
struct LevelStats { int entries; int be_streak; bool locked; };
LevelStats stats[4]; // 1:38, 2:50, 3:61

//--- GLOBALES ESTRUCTURALES ---
CTrade         trade;
CPositionInfo  posInfo;
int            activeMagic;
double         profitFactor = 1.0;
string         botStatus = "INICIANDO PRO...", PNL = "AEVO_v81PM";

double f_0=0, f_38=0, f_50=0, f_61=0, f_78=0, f_100=0;
int    f_dir = 0; 
int    SwingLookback = 100;

int OnInit() {
   activeMagic = MagicNumber;
   trade.SetExpertMagicNumber(activeMagic);
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if((tv < 0.1 && AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL) || ForceCentMode) profitFactor = 0.01;
   CrearHUD();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) { ObjectsDeleteAll(0, PNL); ObjectsDeleteAll(0, "FIBO_MAP_MASTER"); }

void OnTick() {
   CheckDDProtection();
   UpdateMarketStructure();
   DrawFiboMap();
   
   if(IsTradingTime()) {
      CheckLevelLocks();
      
      // Filtro Maestro 78.6%
      double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      bool broken = (f_dir == 1 && price <= f_78) || (f_dir == -1 && price >= f_78);
      
      if(!broken) {
         if(PositionsTotalBots() < MaxOpenTrades) {
            if(MathAbs(f_0 - f_100) > MinImpulsePts * _Point) {
               ScanForEntries();
               if(PositionsTotalBots()==0) botStatus = "🎯 ARQUITECTO ACECHANDO...";
            } else botStatus = "ESTRUCTURA DÉBIL (RANGO)";
         } else botStatus = "MAX EXPOSICIÓN";
      } else botStatus = "ESTRUCTURA ROTA (78.6%)";
      
   } else botStatus = "Zzz (FUERA DE HORARIO)";
   
   if(PositionsTotalBots() > 0) {
      ManageCascadeExit();
      ManageShield();
   }
   
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
      CloseAllBotPositions("MAX_DRAWDOWN_HIT");
      botStatus = "PROTECCIÓN DD ACTIVADA";
   }
}

void CloseAllBotPositions(string reason) {
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
   
   // 1. Filtro Volatilidad Extremas
   if(range < MinM5Vol * _Point || range > MaxM5Vol * _Point) {
      botStatus = "VOL. EXTREMA - SKIP"; return;
   }
   
   // 2. Filtro Llegada Tarde
   double targetPrice = 0;
   if(lvl == LVL_38) targetPrice = f_38;
   else if(lvl == LVL_50) targetPrice = f_50;
   else if(lvl == LVL_61) targetPrice = f_61;
   
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double dist = MathAbs(price - targetPrice) / _Point;
   if(dist > MaxLateEntryPts) {
      botStatus = "LLEGADA TARDE (>100pts)"; return;
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
      botStatus = "L"+IntegerToString(lvl)+" MASTER ENTRADA";
   }
}

void ManageCascadeExit() {
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) {
         if((f_dir == 1 && price < f_100) || (f_dir == -1 && price > f_100)) { trade.PositionClose(posInfo.Ticket()); continue; }
         if((f_dir == 1 && price >= f_0) || (f_dir == -1 && price <= f_0)) { trade.PositionClose(posInfo.Ticket()); continue; }
         
         string cmd = posInfo.Comment();
         if(StringSubstr(cmd,0,6) == "v82_L3" && HasLevelPos("v82_L5")) {
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
         
         // 1. Break Even
         if(pnlPoints >= BE_Trigger && posInfo.StopLoss() == 0) {
            newSL = (posInfo.PositionType()==POSITION_TYPE_BUY) ? (open + BE_Profit*_Point) : (open - BE_Profit*_Point);
            trade.PositionModify(posInfo.Ticket(), newSL, 0);
            
            // Lógica de Streak 2-BE
            int lvlIdx = (int)StringToInteger(StringSubstr(posInfo.Comment(), 5));
            if(lvlIdx > 0) stats[lvlIdx].be_streak++;
         }
         
         // 2. Trailing Stop
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
   ObjectsDeleteAll(0, "FIBO_LVL_");
   string dirTxt = (f_dir == 1) ? " (COMPRA)" : " (VENTA)";
   color  cM      = C'100,100,140';
   CrFLine("L38", f_38, cM, dirTxt + " 38.2% - T1");
   CrFLine("L50", f_50, cM, dirTxt + " 50.0% - T2");
   CrFLine("L61", f_61, C'200,100,100', dirTxt + " 61.8% - GOLD");
   CrFLine("L78", f_78, C'80,80,90', " !!! 78.6% - ESTRUCTURA ROTA !!!");
   CrFLine("L00", f_0,  C'0,255,100', dirTxt + " 0.0% - TARGET");
   CrFLine("L100", f_100, clrRed, " 100.0% - STOP");
}

void CrFLine(string n, double p, color c, string t) {
   string name = "FIBO_LVL_"+n;
   if(!ObjectCreate(0, name, OBJ_HLINE, 0, 0, p)) return;
   ObjectSetInteger(0, name, OBJPROP_COLOR, c);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetString(0, name, OBJPROP_TEXT, t);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

void CrearHUD() {
   ObjectsDeleteAll(0, PNL);
   int x=15, y=15, w=300, h=250;
   CrRect("bg",x,y,w,h,C'10,10,25',C'80,80,150',2);
   CrLabel("ttl",x+15,y+10,"🏗️ EVO v8.2 MASTER ARCHITECT",clrWhite,10,"Arial Bold");
   int cy = y+45;
   CrLabel("stL",x+20,cy,"STATUS:",C'150,150,200',8);
   CrLabel("stV",x+120,cy,botStatus,C'0,255,127',9);
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
   cy += 35;
   CrLabel("ddL",x+20,cy,"MAX DD LIMIT:",C'150,150,200',8);
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
   
   // Si un nivel está bloqueado, informar en HUD
   for(int i=1; i<=3; i++) {
     if(stats[i].locked) botStatus = "L"+IntegerToString(i)+" BLOQUEADO (SAFE MODE)";
   }

   ObjectSetString(0,PNL+"hiV",OBJPROP_TEXT,DoubleToString(f_dir==1 ? f_0 : f_100, _Digits));
   ObjectSetString(0,PNL+"loV",OBJPROP_TEXT,DoubleToString(f_dir==1 ? f_100 : f_0, _Digits));
}

void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bdw=1) {
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

void CrLabel(string n, int x, int y, string text, color c, int s=8, string font="Arial") {
   string name = PNL+n;
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, c);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, s);
   ObjectSetString(0, name, OBJPROP_FONT, font);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

int PositionsTotalBots() { int c=0; for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) c++; return c; }
bool HasLevelPos(string c) { for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic && posInfo.Comment()==c) return true; return false; }

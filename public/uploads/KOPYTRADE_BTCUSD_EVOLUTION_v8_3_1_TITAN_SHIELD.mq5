//+------------------------------------------------------------------+
//|    KOPYTRADE_BTCUSD_EVOLUTION_v8_3_0 - TITAN SHIELD              |
//|   SMOOTH REDRAW + Z-ORDER FIX + TRADUCIDO + TITAN HUD            |
//|   Copyright 2026, Kopytrading Corp. - kopytrading.com            |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "8.31"
#property strict
#property description "BTC TITAN SHIELD v8.3.1 | Web Sync & Remote Management"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- ENUMS ---
enum ENUM_FIBO_LEVEL { LVL_NONE, LVL_38, LVL_50, LVL_61 };

//--- PARÁMETROS ---
sinput string separator0 = "=========================="; // === SEGURIDAD ===
input string   LicenseKey        = "TRIAL-2026";
input string   PurchaseID        = "";         // ID de la Web (Dashboard)
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
input int      StartHour         = 0;         
input int      EndHour           = 24;        

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
double last_f0=0, last_f100=0;
int    f_dir = 0; 
int    SwingLookback = 100;
bool   isMin = false, remotePaused = false;
datetime lastSync = 0, lastRemoteCheck = 0;

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == PNL+"btn_close") {
         if(MessageBox("¿CERRAR TODAS LAS POSICIONES BTC?","TITAN EMERGENCY",MB_YESNO|MB_ICONWARNING) == IDYES) {
            CloseAllBotPositions();
            botStatus = "!!! BTC EMERGENCY CLOSED !!!";
            ActualizarHUD();
         }
      }
      if(sparam == PNL+"btn_min") {
         isMin = !isMin;
         CrearHUD();
         ActualizarHUD();
      }
   }
}

int OnInit() {
   activeMagic = MagicNumber;
   trade.SetExpertMagicNumber(activeMagic);
   if(ForceCentMode) profitFactor = 0.01;
   
   // FORCE H1 HISTORY LOAD
   datetime temp[];
   CopyTime(_Symbol, PERIOD_H1, 0, SwingLookback+1, temp);

   CrearHUD();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) { ObjectsDeleteAll(0, PNL); ObjectsDeleteAll(0, "F_LVL_"); ObjectsDeleteAll(0, "F_LBL_"); }

void OnTick() {
   CheckDDProtection();
   HandleWebSync();

   if(remotePaused) { botStatus = "🔴 PAUSA REMOTA ACTIVADA"; ActualizarHUD(); return; }
   
   UpdateMarketStructure();
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
   } else botStatus = "Zzz (FUERA DE HORA)";
   
   if(f_dir == 0) botStatus = "⚠️ CARGANDO DATOS BTC H1...";

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
   if(iBars(_Symbol, PERIOD_H1) < SwingLookback) { f_dir = 0; return; }
   int hh_idx = iHighest(_Symbol, PERIOD_H1, MODE_HIGH, SwingLookback, 1);
   int ll_idx = iLowest(_Symbol, PERIOD_H1, MODE_LOW, SwingLookback, 1);
   if(hh_idx == -1 || ll_idx == -1) { f_dir = 0; return; }
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
      if(price <= f_38 && price > f_50 && !HasLevelPos("v830_L3") && !stats[1].locked) TryConfirm(LVL_38, POSITION_TYPE_BUY);
      if(price <= f_50 && price > f_61 && !HasLevelPos("v830_L5") && !stats[2].locked) TryConfirm(LVL_50, POSITION_TYPE_BUY);
      if(price <= f_61 && price > f_78 && !HasLevelPos("v830_L6") && !stats[3].locked) TryConfirm(LVL_61, POSITION_TYPE_BUY);
   } else {
      if(price >= f_38 && price < f_50 && !HasLevelPos("v830_L3") && !stats[1].locked) TryConfirm(LVL_38, POSITION_TYPE_SELL);
      if(price >= f_50 && price < f_61 && !HasLevelPos("v830_L5") && !stats[2].locked) TryConfirm(LVL_50, POSITION_TYPE_SELL);
      if(price >= f_61 && price < f_78 && !HasLevelPos("v830_L6") && !stats[3].locked) TryConfirm(LVL_61, POSITION_TYPE_SELL);
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
      string c = "v830_L"+IntegerToString(lvl);
      if(type == POSITION_TYPE_BUY) trade.Buy(LotSize, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_ASK), 0, 0, c);
      else trade.Sell(LotSize, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_BID), 0, 0, c);
      int idx = (lvl==LVL_38?1:(lvl==LVL_50?2:3));
      stats[idx].entries++;
      botStatus = "BTC "+IntegerToString(lvl)+" ESCUDO ACTIVO";
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

// --- WEB SYNC & REMOTE CONTROL ---
void HandleWebSync() {
   if(PurchaseID == "") return;
   if(TimeCurrent() > lastSync + 30) SyncWeb();
   if(TimeCurrent() > lastRemoteCheck + 15) CheckRemoteCommands();
}

void SyncWeb() {
   lastSync = TimeCurrent();
   string posJSON = GeneratePositionsJSON();
   string postD = "{\"purchaseId\":\""+PurchaseID+"\",\"account\":\""+IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN))+"\",\"version\":\"8.3.1\",\"status\":\""+botStatus+"\",\"symbol\":\""+_Symbol+"\",\"positions\":"+posJSON+"}";
   
   char post[], res[]; string rH, head="Content-Type: application/json\r\n";
   StringToCharArray(postD,post,0,StringLen(postD),CP_UTF8);
   int resCode = WebRequest("POST","https://www.kopytrading.com/api/sync-positions",head,3000,post,res,rH);
}

void CheckRemoteCommands() {
   lastRemoteCheck = TimeCurrent();
   string url = "https://www.kopytrading.com/api/remote-control?purchaseId="+PurchaseID+"&account="+IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
   char post[], res[]; string rH;
   int resCode = WebRequest("GET",url,NULL,3000,post,res,rH);
   
   if(resCode == 200) {
      string json = CharArrayToString(res, 0, WHOLE_ARRAY, CP_UTF8);
      if(StringFind(json, "\"command\":\"CLOSE_ALL\"") >= 0) {
         CloseAllBotPositions();
         botStatus = "!!! WEB EMERGENCY STOP !!!";
      }
      if(StringFind(json, "\"command\":\"PAUSE\"") >= 0) remotePaused = true;
      if(StringFind(json, "\"command\":\"RESUME\"") >= 0) remotePaused = false;
   }
}

string GeneratePositionsJSON() {
   string json = "[";
   bool first = true;
   for(int i=0; i<PositionsTotal(); i++) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) {
         if(!first) json += ",";
         json += "{\"ticket\":"+IntegerToString(posInfo.Ticket())+",";
         json += "\"symbol\":\""+posInfo.Symbol()+"\",";
         json += "\"type\":\""+EnumToString(posInfo.PositionType())+"\",";
         json += "\"lots\":"+DoubleToString(posInfo.Volume(),2)+",";
         json += "\"openPrice\":"+DoubleToString(posInfo.PriceOpen(),_Digits)+",";
         json += "\"profit\":"+DoubleToString(posInfo.Profit()+posInfo.Swap()+posInfo.Commission(),2)+"}";
         first = false;
      }
   }
   json += "]";
   return json;
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
   if(f_0 == 0 || f_100 == 0) return; 
   
   // Smooth Redraw BTC: Actualizamos posiciones sin borrar
   string dir = (f_dir == 1) ? "BUY" : "SELL";
   
   CrZone("GZone", f_50, f_61, C'20,30,40');
   CrFLine("38", f_38, C'160,160,180', "38.2% - T1", 1);
   CrFLine("50", f_50, C'180,200,255', "50.0% - T2", 2);
   CrFLine("61", f_61, C'255,150,0',   "61.8% - ORO", 3);
   CrFLine("78", f_78, C'255,50,50',   "!!! 78.6% - ROTURA !!!", 2);
   CrFLine("00", f_0,  C'0,255,150',   "OBJETIVO 0.0%", 1);
   CrFLine("100", f_100, C'255,100,100', "STOP 100.0%", 1);
}

void CrFLine(string n, double p, color c, string t, int w=1) {
   string name = "F_LVL_BTC_"+n, lname = "F_LBL_BTC_"+n;

   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, p);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
   } else ObjectMove(0, name, 0, 0, p);

   ObjectSetInteger(0, name, OBJPROP_COLOR, c);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, w);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   
   if(ObjectFind(0, lname) < 0) {
      ObjectCreate(0, lname, OBJ_TEXT, 0, TimeCurrent()+3600*4, p);
      ObjectSetInteger(0, lname, OBJPROP_ZORDER, 0);
      ObjectSetInteger(0, lname, OBJPROP_BACK, true);
   } else ObjectMove(0, lname, 0, TimeCurrent()+3600*4, p);

   ObjectSetString(0, lname, OBJPROP_TEXT, "  ◀ BTC " + t);
   ObjectSetInteger(0, lname, OBJPROP_COLOR, c);
   ObjectSetInteger(0, lname, OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, lname, OBJPROP_FONT, "Arial Black");
   ObjectSetInteger(0, lname, OBJPROP_SELECTABLE, false);
}

void CrZone(string n, double p1, double p2, color c) {
   string name = "F_LVL_BTC_"+n;
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_RECTANGLE, 0, TimeCurrent()-3600*24, p1, TimeCurrent()+3600*24, p2);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
   } else {
      ObjectMove(0, name, 0, TimeCurrent()-3600*24, p1);
      ObjectMove(0, name, 1, TimeCurrent()+3600*24, p2);
   }
   ObjectSetInteger(0, name, OBJPROP_COLOR, c);
   ObjectSetInteger(0, name, OBJPROP_FILL, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

void CrearHUD() {
   ObjectsDeleteAll(0, PNL);
   int x=15, y=30, w=(isMin?220:300), h=(isMin?40:280);
   
   // Fondo y Título
   CrRect("bg",x,y,w,h,C'10,15,30',C'100,150,255',2);
   CrLabel("ttl",x+15,y+10,"🏗️ EVO v8.3.0 BTC TITAN SHIELD",C'100,200,255',isMin?8:10,isMin?"Arial":"Impact");
   CrButton("btn_min",x+w-30,y+10,20,20,isMin?"+":"-",C'50,80,120',clrWhite);

   if(isMin) return;

   // Status Line
   CrRect("st_bg",x+10,y+40,w-20,25,C'20,30,50',C'50,100,150',1);
   CrLabel("stV",x+20,y+45,botStatus,clrWhite,9,"Arial Black");
   
   // Datos Mercado
   int gy = y+75;
   CrLabel("l_trnd",x+15,gy,   "TENDENCIA:",C'0,200,255',8);     CrLabel("trend",x+110,gy,"BUSCANDO...",clrWhite,8,"Arial Black");

   // Parámetros BTC en Vista
   int py = gy+25;
   CrLabel("l_lots",x+15,py,   "LOTS:",C'180,180,100',8);    CrLabel("v_lots",x+90,py,DoubleToString(LotSize,2),clrWhite,8,"Arial Bold");
   CrLabel("l_be",x+15,py+18, "BE AT:",C'100,200,100',8);    CrLabel("v_be",x+90,py+18,IntegerToString(BE_Trigger)+" pts",clrWhite,8,"Arial Bold");
   CrLabel("l_tr",x+15,py+36, "TRAIL:",C'100,180,255',8);    CrLabel("v_tr",x+90,py+36,IntegerToString(TrailingStart)+" pts",clrWhite,8,"Arial Bold");

   // BOTONES
   int by = y+h-50;
   CrButton("btn_close",x+15,by,w-30,35,"🛑 CERRAR TODAS LAS POSICIONES BTC",C'120,30,30',clrWhite);
}

void CrButton(string n, int x, int y, int w, int h, string t, color bg, color tc) {
   string name = PNL+n;
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetString(0, name, OBJPROP_TEXT, t);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR, tc);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 100);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial Black");
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

void CheckLevelLocks() {
   for(int i=1; i<=3; i++) {
      if(stats[i].entries >= MaxReEntries || stats[i].be_streak >= 2) stats[i].locked = true;
   }
}

void ActualizarHUD() {
   if(isMin) return;
   ObjectSetString(0,PNL+"stV",OBJPROP_TEXT,botStatus);
   ObjectSetString(0,PNL+"trend",OBJPROP_TEXT,(f_dir==1?"🟩 ALCISTA (Bull)":"🟥 BAJISTA (Bear)"));
   ObjectSetString(0,PNL+"hi",OBJPROP_TEXT,"MÁXIMO: "+DoubleToString(f_dir==1?f_0:f_100,_Digits));
   ObjectSetString(0,PNL+"lo",OBJPROP_TEXT,"MÍNIMO: "+DoubleToString(f_dir==1?f_100:f_0,_Digits));
}

void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bdw=1) {
   string name = PNL+n;
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR, bd);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, bdw);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 50);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

void CrLabel(string n, int x, int y, string t, color c, int s, string f="Arial") {
   string name = PNL+n;
   ObjectCreate(0, name, OBJ_LABEL, 0,0,0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, t);
   ObjectSetInteger(0, name, OBJPROP_COLOR, c);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, s);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 60);
   ObjectSetString(0, name, OBJPROP_FONT, f);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

int PositionsTotalBots() { int c=0; for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) c++; return c; }
bool HasLevelPos(string c) { for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic && posInfo.Comment()==c) return true; return false; }

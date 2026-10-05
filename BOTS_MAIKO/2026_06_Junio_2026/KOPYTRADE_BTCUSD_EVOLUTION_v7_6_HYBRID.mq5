//+------------------------------------------------------------------+
//|     KOPYTRADE_BTCUSD_EVOLUTION_v7_6 - HYBRID RECOVERY            |
//|   DIRECT ENTRY + MOMENTUM (STOP) + MEAN REVERSION (LIMIT)        |
//|   Copyright 2026, Kopytrading Corp. - kopytrading.com            |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "7.60"
#property strict
#property description "BTC HYBRID EVOLUTION | Momentum + Mean Reversion Recovery"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- HELPER ---
double ParseDouble(string json, string key) {
   int pos = StringFind(json, key);
   if(pos < 0) return 0;
   int start = pos + StringLen(key);
   int end = StringFind(json, ",", start);
   if(end < 0) end = StringFind(json, "}", start);
   return StringToDouble(StringSubstr(json, start, end - start));
}

string GetJsonValue(string json, string key) {
   int pos = StringFind(json, key);
   if(pos < 0) return "";
   int start = StringFind(json, ":", pos) + 1;
   while(StringSubstr(json, start, 1) == " " || StringSubstr(json, start, 1) == "\"") start++;
   int end = StringFind(json, "\"", start);
   if(end < 0) end = StringFind(json, ",", start);
   if(end < 0) end = StringFind(json, "}", start);
   return StringSubstr(json, start, end - start);
}

//--- PARÁMETROS ---
sinput string separator0 = "=========================="; // === SEGURIDAD ===
input string   LicenseKey        = "TRIAL-2026";
input string   PurchaseID        = "";         
input bool     ForceCentMode     = true;

sinput string separator1 = "=========================="; // === GESTIÓN ===
enum ENUM_MODE { MODE_ZEN, MODE_COSECHA };
enum ENUM_DIR  { DIR_AMBAS, DIR_SOLO_COMPRAS, DIR_SOLO_VENTAS };
input ENUM_MODE ModePreset        = MODE_COSECHA; 
input int      MagicNumber        = 700761;       
input int      MaxPosiciones      = 5;            
input double   LoteManual         = 0.01;         
input double   LoteRescate        = 0.02;         
input double   MaxDrawdownAccount = 50.0;         

sinput string separator2 = "=========================="; // === RITMO v7.6 ===
input double   GatilloHedge_USD    = 0.50;         // Cent safe
input double   Target_Rescate      = 0.20;          
input double   Net_Cycle_USD       = 2.0;          

sinput string separator3 = "=========================="; // === PROTECCIÓN ===
input bool     ActivarBE           = true;        
input double   BE_Trigger_USD      = 1.5;          
input double   TraillingStop_USD   = 0.0;          
input double   TraillingStep_USD   = 0.5;          

sinput string separator4 = "=========================="; // === HYBRID LIMITS ===
input bool     EnableLimitRecovery = true;         
input int      LimitDistPoints     = 5000;         // Wider for BTC

//--- GLOBALES ---
CTrade         trade;
CPositionInfo  posInfo;
int            activeMagic, h_ema20, h_ema50, h_rsi, rescueCount = 0;
bool           remotePaused = false, isMinimized = false, syncPending = false;
ENUM_MODE      currentMode;
ENUM_DIR       currentDir = DIR_AMBAS;
string         botStatus = "LISTO", commentTag = "EVO_HYB_BTC_76";
double         profitFactor = 1.0, dayPnL = 0;
datetime       lastSync = 0, coolingEndTime = 0;

double         dynNet_Cycle, dynGatilloHedge, dynLoteManual, dynLoteRescate, dynTrailing, dynMaxDD, dynLimitDist;
string         dynTF = "M5";

#define PNL "AEVO_v76HYBBTC"

int OnInit() {
   currentMode = ModePreset;
   activeMagic = MagicNumber;
   trade.SetExpertMagicNumber(activeMagic);
   
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if((tv < 0.1 && AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL) || ForceCentMode) profitFactor = 0.01;
   
   dynNet_Cycle = Net_Cycle_USD;
   dynGatilloHedge = GatilloHedge_USD;
   dynLoteManual   = LoteManual;
   dynLoteRescate  = LoteRescate;
   dynTrailing     = TraillingStop_USD;
   dynMaxDD        = MaxDrawdownAccount;
   dynLimitDist    = (double)LimitDistPoints;

   h_ema20 = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   h_ema50 = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
   h_rsi   = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   ChartIndicatorAdd(0, 0, h_ema20); ChartIndicatorAdd(0, 0, h_ema50); ChartIndicatorAdd(0, 1, h_rsi);
   
   CrearHUD();
   EventSetTimer(3);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) { ObjectsDeleteAll(0, PNL); }

void OnTick() {
   SyncWeb();
   if(remotePaused) { botStatus = "🔴 PAUSA REMOTA"; DeletePendings(); ActualizarHUD(); return; }
   
   double netUSD = GetNetProfitUSD();
   if(dynMaxDD > 0 && netUSD <= -dynMaxDD) { CloseAll(); DeletePendings(); botStatus = "🛑 STOP EMERGENCIA"; remotePaused = true; return; }
   
   ProtectAll();
   ManageStrike();
   DrawGhostLines();
   botStatus = "🟢 TRABAJANDO";
   dayPnL = CalculateDayProfit();
   ActualizarHUD();
   ChartRedraw();
}

void SyncWeb() {
   if(PurchaseID=="" || TimeCurrent()<lastSync+30) return; lastSync=TimeCurrent();
   string accountS = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
   
   string settingsJson = "";
   if(syncPending) {
      settingsJson = ",\"proposedSettings\":{" +
                  "\"net_cycle\":" + DoubleToString(dynNet_Cycle,2) + "," +
                  "\"hedge_trigger\":" + DoubleToString(dynGatilloHedge,2) + "," +
                  "\"lote_manual\":" + DoubleToString(dynLoteManual,2) + "," +
                  "\"lote_rescate\":" + DoubleToString(dynLoteRescate,2) + "," +
                  "\"max_dd\":" + DoubleToString(dynMaxDD,2) + "," +
                  "\"trailling_stop\":" + DoubleToString(dynTrailing,2) + "," +
                  "\"limit_dist\":" + DoubleToString(dynLimitDist,0) + "," +
                  "\"timeframe\":\"" + dynTF + "\"" +
                  "}";
       syncPending = false;
   }

   string postD="{\"purchaseId\":\""+PurchaseID+"\",\"account\":\""+accountS+"\",\"status\":\""+botStatus+"\"" + settingsJson + "}";
   char post[], res[]; string rH, head="Content-Type: application/json\r\n";
   StringToCharArray(postD,post,0,StringLen(postD),CP_UTF8);
   
   if(WebRequest("POST","https://www.kopytrading.com/api/sync-positions",head,3000,post,res,rH) == 200) {
      string r = CharArrayToString(res,0,WHOLE_ARRAY,CP_UTF8);
      if(StringFind(r,"\"paused\":true")>=0) remotePaused=true;
      if(StringFind(r,"\"paused\":false")>=0) remotePaused=false;
      
      int sPos = StringFind(r, "\"settings\":");
      if(sPos >= 0) {
         string json = StringSubstr(r, sPos);
         dynNet_Cycle = ParseDouble(json, "\"net_cycle\":");
         dynGatilloHedge = ParseDouble(json, "\"hedge_trigger\":");
         dynLoteManual = ParseDouble(json, "\"lote_manual\":");
         dynLoteRescate = ParseDouble(json, "\"lote_rescate\":");
         dynMaxDD = ParseDouble(json, "\"max_dd\":");
         dynTrailing = ParseDouble(json, "\"trailling_stop\":");
         if(StringFind(r,"\"limit_dist\":")>=0) dynLimitDist = ParseDouble(json, "\"limit_dist\":");
      }
      ActualizarHUD();
   }
}

void ProtectAll() {
   double net = GetNetProfitUSD();
   int total = 0;
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) {
         total++;
         double pUSD = GetProfitUSD(posInfo.Profit()+posInfo.Swap()+posInfo.Commission());
         if(ActivarBE && pUSD >= BE_Trigger_USD) {
            double sl = posInfo.StopLoss();
            if(posInfo.PositionType()==POSITION_TYPE_BUY) {
               double be=posInfo.PriceOpen()+100*_Point; 
               if(sl<be || sl==0) trade.PositionModify(posInfo.Ticket(),NormalizeDouble(be,_Digits),0);
            } else {
               double be=posInfo.PriceOpen()-100*_Point; 
               if(sl>be || sl==0) trade.PositionModify(posInfo.Ticket(),NormalizeDouble(be,_Digits),0);
            }
         }
         
         if(dynTrailing > 0 && pUSD >= dynTrailing) {
            double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID), ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
            double stepPoints = (TraillingStep_USD / profitFactor) / SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) * _Point;
            if(posInfo.PositionType()==POSITION_TYPE_BUY) {
               double newSL = NormalizeDouble(bid - stepPoints, _Digits);
               if(newSL > posInfo.StopLoss() + 100*_Point || posInfo.StopLoss()==0) trade.PositionModify(posInfo.Ticket(), newSL, 0);
            } else {
               double newSL = NormalizeDouble(ask + stepPoints, _Digits);
               if(newSL < posInfo.StopLoss() - 100*_Point || posInfo.StopLoss()==0) trade.PositionModify(posInfo.Ticket(), newSL, 0);
            }
         }
      }
   }
   if(total >= 1 && net >= dynNet_Cycle) { CloseAll(); coolingEndTime=TimeCurrent()+60; }
}

void ManageStrike() {
   if(PositionsTotalBots() >= MaxPosiciones) { DeletePendings(); return; }
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID), ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   
   int posTotal = PositionsTotalBots();
   if(posTotal == 0) {
      double rsi[1]; CopyBuffer(h_rsi,0,0,1,rsi);
      if(rsi[0] < 30) trade.Buy(dynLoteManual,_Symbol,ask,0,0,commentTag);
      else if(rsi[0] > 70) trade.Sell(dynLoteManual,_Symbol,bid,0,0,commentTag);
      return;
   }
   
   double net = GetNetProfitUSD();
   if(net <= -dynGatilloHedge) {
      bool hasPending = false;
      for(int j=0; j<OrdersTotal(); j++) if(OrderSelect(OrderGetTicket(j)) && OrderGetInteger(ORDER_MAGIC)==activeMagic) { hasPending=true; break; }
      
      if(!hasPending) {
         long type = -1;
         for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) { type = posInfo.PositionType(); break; }
         
         if(type == POSITION_TYPE_BUY) {
            if(EnableLimitRecovery) trade.BuyLimit(dynLoteRescate, bid - (int)dynLimitDist*_Point, _Symbol, 0,0,0,0, commentTag+"_LIM");
            trade.SellStop(dynLoteRescate, bid - 5000*_Point, _Symbol, 0,0,0,0, commentTag+"_STP");
         } else {
            if(EnableLimitRecovery) trade.SellLimit(dynLoteRescate, ask + (int)dynLimitDist*_Point, _Symbol, 0,0,0,0, commentTag+"_LIM");
            trade.BuyStop(dynLoteRescate, ask + 5000*_Point, _Symbol, 0,0,0,0, commentTag+"_STP");
         }
      }
   }
}

void DrawGhostLines() {
   ObjectsDeleteAll(0, PNL+"_GHOST");
   if(PositionsTotalBots()==0) return;
   
   double entryP=0; int type=-1; double totalLot=0;
   for(int i=0; i<PositionsTotal(); i++) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) { 
         entryP=posInfo.PriceOpen(); 
         type=(int)posInfo.PositionType(); 
         totalLot += posInfo.Volume();
         break;
      }
   }
   
   double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickVal==0 || tickSize==0 || totalLot==0) return;
   
   double pointsToTrigger = MathAbs(dynGatilloHedge / (_Point * (tickVal/tickSize) * totalLot * profitFactor));
   double triggerP = (type==POSITION_TYPE_BUY) ? entryP - pointsToTrigger*_Point : entryP + pointsToTrigger*_Point;
   
   triggerP = NormalizeDouble(triggerP, _Digits);
   
   CrHLine("_GHOST_TRG", triggerP, C'255,100,0', STYLE_DOT, 1, "Gatillo de Rescate ("+DoubleToString(dynGatilloHedge,2)+")");
   double limP = (type==POSITION_TYPE_BUY) ? triggerP - dynLimitDist*_Point : triggerP + dynLimitDist*_Point;
   double stpP = (type==POSITION_TYPE_BUY) ? triggerP - 5000*_Point : triggerP + 5000*_Point;
   
   CrHLine("_GHOST_LIM", NormalizeDouble(limP, _Digits), C'255,255,0', STYLE_DASH, 1, "Proyección LIMIT a "+DoubleToString(dynLimitDist,0)+" pts");
   CrHLine("_GHOST_STP", NormalizeDouble(stpP, _Digits), C'255,50,50', STYLE_DASH, 1, "Proyección STOP a 5000 pts");
}

void CrHLine(string n, double p, color c, ENUM_LINE_STYLE s, int w, string txt) {
   string name = PNL+n;
   ObjectCreate(0, name, OBJ_HLINE, 0, 0, p);
   ObjectSetInteger(0, name, OBJPROP_COLOR, c);
   ObjectSetInteger(0, name, OBJPROP_STYLE, s);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, w);
   ObjectSetString(0, name, OBJPROP_TEXT, txt);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

double CalculateDayProfit() {
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt); dt.hour=0; dt.min=0; dt.sec=0;
   HistorySelect(StructToTime(dt), TimeCurrent());
   double p=0;
   for(int i=HistoryDealsTotal()-1; i>=0; i--) {
      ulong t=HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(t, DEAL_MAGIC) == activeMagic) p += HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_SWAP) + HistoryDealGetDouble(t, DEAL_COMMISSION);
   }
   return GetProfitUSD(p);
}

void CloseAll() { for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) trade.PositionClose(posInfo.Ticket()); }
void DeletePendings() { for(int i=OrdersTotal()-1; i>=0; i--) if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC)==activeMagic) trade.OrderDelete(OrderGetTicket(i)); }
int PositionsTotalBots() { int c=0; for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) c++; return c; }
double GetNetProfitUSD() { double p=0; for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) p+=posInfo.Profit()+posInfo.Swap()+posInfo.Commission(); return GetProfitUSD(p); }
double GetProfitUSD(double p) { return p * profitFactor; }

void CrearHUD() {
   ObjectsDeleteAll(0, PNL);
   int x=15, y=15, w=280, h=400; if(isMinimized) { w=200; h=50; }
   CrRect("bg",x,y,w,h,C'15,15,35',C'60,60,120',2);
   CrLabel("ttl",x+15,y+10,"BTC v7.6 HYBRID",clrWhite,10,"Arial Bold");
   if(isMinimized) { CrBtn("min",x+w-25,y+10,20,20,"+",C'40,40,80',clrWhite); return; }
   CrBtn("min",x+w-25,y+10,20,20,"-",C'40,40,80',clrWhite);
   
   int cy = y+50;
   CrLabel("pL",x+15,cy,"PNL HOY (USD):",C'150,150,200',8);
   CrLabel("pV",x+120,cy,"0.00 $",clrWhite,10,"Arial Bold");
   cy += 25;
   CrLabel("stL",x+15,cy,"ESTADO:",C'150,150,200',8);
   CrLabel("stV",x+120,cy,botStatus,C'0,255,127',9);
   cy += 35;
   CrLabel("metaL",x+15,cy,"META CICLO ($):",C'100,200,255',7);
   CrEdit("edit_target",x+120,cy-5,60,20,DoubleToString(dynNet_Cycle,2),clrWhite,C'40,40,60');
   cy += 25;
   CrLabel("hedgeL",x+15,cy,"GATILLO HEDGE:",C'100,200,255',7);
   CrEdit("edit_hedge",x+120,cy-5,60,20,DoubleToString(dynGatilloHedge,2),clrWhite,C'40,40,60');
   cy += 25;
   CrLabel("loteL",x+15,cy,"LOTE (Seg/Res):",C'100,200,255',7);
   CrEdit("edit_lote_m",x+120,cy-5,45,20,DoubleToString(dynLoteManual,2),clrWhite,C'30,30,50');
   CrEdit("edit_lote_r",x+170,cy-5,45,20,DoubleToString(dynLoteRescate,2),clrWhite,C'30,30,50');
   cy += 25;
   CrLabel("tsL",x+15,cy,"T-STOP ($):",C'100,200,255',7);
   CrEdit("edit_tstop",x+120,cy-5,60,20,DoubleToString(dynTrailing,2),clrWhite,C'40,40,60');
   
   cy += 25;
   CrLabel("limL",x+15,cy,"DIST. LIMIT (pts):",C'100,200,255',7);
   CrEdit("edit_limdist",x+120,cy-5,60,20,DoubleToString(dynLimitDist,0),clrWhite,C'40,40,60');

   cy += 40;
   CrBtn("b_zen",x+10,cy,125,30,"ZEN",currentMode==MODE_ZEN?C'0,100,255':C'40,40,70',clrWhite);
   CrBtn("b_har",x+145,cy,125,30,"COSECHA",currentMode==MODE_COSECHA?C'255,100,0':C'40,40,70',clrWhite);
   cy += 35;
   CrBtn("d_amb",x+10,cy,80,25,"AMBAS",currentDir==DIR_AMBAS?C'60,150,255':C'40,40,70',clrWhite);
   CrBtn("d_buy",x+95,cy,80,25,"SOLO BUY",currentDir==DIR_SOLO_COMPRAS?C'0,200,100':C'40,40,70',clrWhite);
   CrBtn("d_sel",x+180,cy,80,25,"SOLO SELL",currentDir==DIR_SOLO_VENTAS?C'220,50,50':C'40,40,70',clrWhite);
   cy += 35;
   CrBtn("save",x+10,cy,260,30,"APLICAR CAMBIOS Y SINCRONIZAR",C'0,150,100',clrWhite);
   cy += 35;
   CrBtn("close",x+10,cy,260,40,"CERRAR TODO",C'200,40,40',clrWhite);
}

void ActualizarHUD() {
   if(isMinimized) return;
   ObjectSetString(0,PNL+"pV",OBJPROP_TEXT,DoubleToString(dayPnL,2)+" $");
   ObjectSetString(0,PNL+"stV",OBJPROP_TEXT,botStatus);
   ObjectSetInteger(0,PNL+"stV",OBJPROP_COLOR,remotePaused?C'220,50,50':C'0,255,127');
   if(ObjectGetInteger(0,PNL+"edit_target",OBJPROP_STATE)==0) ObjectSetString(0,PNL+"edit_target",OBJPROP_TEXT,DoubleToString(dynNet_Cycle,2));
   if(ObjectGetInteger(0,PNL+"edit_hedge",OBJPROP_STATE)==0) ObjectSetString(0,PNL+"edit_hedge",OBJPROP_TEXT,DoubleToString(dynGatilloHedge,2));
   if(ObjectGetInteger(0,PNL+"edit_lote_m",OBJPROP_STATE)==0) ObjectSetString(0,PNL+"edit_lote_m",OBJPROP_TEXT,DoubleToString(dynLoteManual,2));
   if(ObjectGetInteger(0,PNL+"edit_lote_r",OBJPROP_STATE)==0) ObjectSetString(0,PNL+"edit_lote_r",OBJPROP_TEXT,DoubleToString(dynLoteRescate,2));
   if(ObjectGetInteger(0,PNL+"edit_tstop",OBJPROP_STATE)==0) ObjectSetString(0,PNL+"edit_tstop",OBJPROP_TEXT,DoubleToString(dynTrailing,2));
   if(ObjectGetInteger(0,PNL+"edit_limdist",OBJPROP_STATE)==0) ObjectSetString(0,PNL+"edit_limdist",OBJPROP_TEXT,DoubleToString(dynLimitDist,0));
}

void OnChartEvent(const int id,const long &lp,const double &dp,const string &sp) {
   if(id==CHARTEVENT_OBJECT_CLICK) {
      if(sp==PNL+"min") { isMinimized=!isMinimized; CrearHUD(); }
      if(sp==PNL+"b_zen") { currentMode=MODE_ZEN; CrearHUD(); }
      if(sp==PNL+"b_har") { currentMode=MODE_COSECHA; CrearHUD(); }
      if(sp==PNL+"d_amb") { currentDir=DIR_AMBAS; CrearHUD(); }
      if(sp==PNL+"d_buy") { currentDir=DIR_SOLO_COMPRAS; CrearHUD(); }
      if(sp==PNL+"d_sel") { currentDir=DIR_SOLO_VENTAS; CrearHUD(); }
      if(sp==PNL+"save") { syncPending=true; ObjectSetInteger(0,sp,OBJPROP_BGCOLOR,C'0,250,150'); }
      if(sp==PNL+"close") CloseAll();
      ObjectSetInteger(0,sp,OBJPROP_STATE,false);
   }
   if(id==CHARTEVENT_OBJECT_ENDEDIT) {
      if(sp==PNL+"edit_target") { dynNet_Cycle = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT)); syncPending=true; }
      if(sp==PNL+"edit_hedge")  { dynGatilloHedge = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT)); syncPending=true; }
      if(sp==PNL+"edit_lote_m") { dynLoteManual = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT)); syncPending=true; }
      if(sp==PNL+"edit_lote_r") { dynLoteRescate = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT)); syncPending=true; }
      if(sp==PNL+"edit_tstop")  { dynTrailing = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT)); syncPending=true; }
      if(sp==PNL+"edit_limdist") { dynLimitDist = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT)); syncPending=true; }
   }
}

void CrRect(string n,int x,int y,int w,int h,color bg,color bd,int bw=1) { ObjectCreate(0,PNL+n,OBJ_RECTANGLE_LABEL,0,0,0); ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h); ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,bd); ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,100); }
void CrLabel(string n,int x,int y,string t,color c,int s,string f="Segoe UI") { ObjectCreate(0,PNL+n,OBJ_LABEL,0,0,0); ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y); ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,c); ObjectSetInteger(0,PNL+n,OBJPROP_FONTSIZE,s); ObjectSetString(0,PNL+n,OBJPROP_FONT,f); ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,101); }
void CrEdit(string n,int x,int y,int w,int h,string t,color tc,color bg) { ObjectCreate(0,PNL+n,OBJ_EDIT,0,0,0); ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h); ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,tc); ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,102); }
void CrBtn(string n,int x,int y,int w,int h,string t,color bg,color tc) { ObjectCreate(0,PNL+n,OBJ_BUTTON,0,0,0); ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h); ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,tc); ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,102); }

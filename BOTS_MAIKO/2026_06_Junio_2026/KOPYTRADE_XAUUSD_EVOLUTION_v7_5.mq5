//+------------------------------------------------------------------+
//|     KOPYTRADE_XAUUSD_EVOLUTION_v7_5 - AMETRALLADORA RÍTMICA      |
//|   RHYTHM 1-1-2-2 RESCUE + $5.00 CYCLE TARGET + 0.01/0.02 SPLIT   |
//|   Copyright 2026, Kopytrading Corp. - kopytrading.com            |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "7.50"
#property strict
#property description "RHYTHM 1-1-2-2 | $5.00 Cycle Target | Agile Recovery"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- PARÁMETROS ---
sinput string separator0 = "=========================="; // === SEGURIDAD ===
input string   LicenseKey        = "TRIAL-2026";
input string   PurchaseID        = "";         
input bool     ForceCentMode     = false;

sinput string separator1 = "=========================="; // === GESTIÓN ===
enum ENUM_MODE { MODE_ZEN, MODE_COSECHA };
enum ENUM_DIR  { DIR_AMBAS, DIR_SOLO_COMPRAS, DIR_SOLO_VENTAS };
input ENUM_MODE ModePreset        = MODE_COSECHA; 
input int      MagicNumber        = 700750;       
input int      MaxPosiciones      = 5;            
input double   LoteManual         = 0.01;         
input double   LoteRescate        = 0.02;         
input double   MaxDrawdownAccount = 50.0;         

sinput string separator2 = "=========================="; // === RITMO v7.5 ===
input double   GatilloHedge_USD    = 3.0;          
input double   Target_Rescate      = 2.0;          
input double   Net_Cycle_USD       = 5.0;          

sinput string separator3 = "=========================="; // === PROTECCIÓN ===
input bool     ActivarBE           = true;        
input double   BE_Trigger_USD      = 1.5;          
input double   TraillingStop_USD   = 0.0;          // 0 = Desactivado
input double   TraillingStep_USD   = 0.5;          // Distancia de seguimiento

//--- GLOBALES ---
CTrade         trade;
CPositionInfo  posInfo;
int            activeMagic, h_ema20, h_ema50, h_rsi, rescueCount = 0;
bool           remotePaused = false, isMinimized = false, syncPending = false;
ENUM_MODE      currentMode;
ENUM_DIR       currentDir = DIR_AMBAS;
string         botStatus = "LISTO", commentTag = "EVO_GOLD_75";
double         profitFactor = 1.0, dayPnL = 0;
datetime       lastSync = 0, coolingEndTime = 0;

// Variables dinámicas (pueden ser sobreescritas por la web o HUD)
double         dynNet_Cycle, dynGatilloHedge, dynLoteManual, dynLoteRescate, dynTrailing, dynMaxDD;
string         dynTF = "M5";

#define PNL "AEVO_v75"

int OnInit() {
   currentMode = ModePreset;
   activeMagic = MagicNumber;
   trade.SetExpertMagicNumber(activeMagic);
   
   // Inicializar variables dinámicas con los inputs de usuario
   dynNet_Cycle = Net_Cycle_USD;
   dynGatilloHedge = GatilloHedge_USD;
   dynLoteManual   = LoteManual;
   dynLoteRescate  = LoteRescate;
   dynTrailing     = TraillingStop_USD;
   dynMaxDD = MaxDrawdownAccount;
   dynTF = EnumToString(_Period);
   
   if(_Symbol == "BTCUSD" || _Symbol == "BTCUSD.bit") commentTag = "EVO_BTC_75";
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if((tv < 0.1 && AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL) || ForceCentMode) profitFactor = 0.01;
   h_ema20 = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   h_ema50 = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
   h_rsi   = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   CrearHUD();
   EventSetTimer(3);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) { ObjectsDeleteAll(0, PNL); }

void OnTick() {
   SyncWeb();
   if(remotePaused) { botStatus = "🔴 PAUSA REMOTA"; DeletePendings(); ActualizarHUD(); return; }
   double netUSD = GetNetProfitUSD();
   
   if(dynMaxDD > 0 && netUSD <= -dynMaxDD) { 
      CloseAll(); rescueCount = 0; botStatus = "🛑 RESET SEGURIDAD"; remotePaused = true; return; 
   }
   if(netUSD >= dynNet_Cycle && PositionsTotalBots() >= 2) { 
      CloseAll(); rescueCount = 0; coolingEndTime = TimeCurrent()+120; botStatus = "💰 CICLO COMPLETADO"; return; 
   }
   ProtectAndTarget();
   ManageStrike();
   botStatus = "🟢 TRABAJANDO";
   dayPnL = CalculateDayProfit();
   ActualizarHUD();
}

void ProtectAndTarget() {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) {
         double pUSD = GetProfitUSD(posInfo.Profit()+posInfo.Swap()+posInfo.Commission());
         bool isRescue = (StringFind(posInfo.Comment(), "_R") >= 0);
         
         if(isRescue && pUSD >= Target_Rescate) { 
            trade.PositionClose(posInfo.Ticket()); 
            rescueCount++; 
            syncPending = true; // Avisar a la web del cambio de ritmo
            continue; 
         }
         
         if(ActivarBE && pUSD >= BE_Trigger_USD) {
            double sl = posInfo.StopLoss();
            double be = (posInfo.PositionType()==POSITION_TYPE_BUY) ? posInfo.PriceOpen()+10*_Point : posInfo.PriceOpen()-10*_Point;
            if(posInfo.PositionType()==POSITION_TYPE_BUY) { if(sl<be || sl==0) trade.PositionModify(posInfo.Ticket(),NormalizeDouble(be,_Digits),0); }
            else { if(sl>be || sl==0) trade.PositionModify(posInfo.Ticket(),NormalizeDouble(be,_Digits),0); }
         }
         
         // --- TRAILING STOP (USD) ---
         if(dynTrailing > 0 && pUSD >= dynTrailing) {
            double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID), ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
            double stepPoints = (TraillingStep_USD / profitFactor) / SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) * _Point;
            if(posInfo.PositionType()==POSITION_TYPE_BUY) {
               double newSL = NormalizeDouble(bid - stepPoints, _Digits);
               if(newSL > posInfo.StopLoss() + 10*_Point || posInfo.StopLoss()==0) trade.PositionModify(posInfo.Ticket(), newSL, 0);
            } else { // SELL
               double newSL = NormalizeDouble(ask + stepPoints, _Digits);
               if(newSL < posInfo.StopLoss() - 10*_Point || posInfo.StopLoss()==0) trade.PositionModify(posInfo.Ticket(), newSL, 0);
            }
         }
      }
   }
}

void ManageStrike() {
   int posTotal = PositionsTotalBots();
   if(posTotal >= MaxPosiciones) return;
   
   double emaF[1], emaS[1], rsi[1], bid=SymbolInfoDouble(_Symbol,SYMBOL_BID), ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   CopyBuffer(h_ema20,0,0,1,emaF); CopyBuffer(h_ema50,0,0,1,emaS); CopyBuffer(h_rsi,0,0,1,rsi);
   
   bool biasUp = (emaF[0] > emaS[0] && rsi[0] > 50);
   bool biasDn = (emaF[0] < emaS[0] && rsi[0] < 50);
   
   if(posTotal == 0) {
      if(biasUp && (currentDir==DIR_AMBAS || currentDir==DIR_SOLO_COMPRAS)) trade.Buy(dynLoteManual,_Symbol,ask,0,0,commentTag);
      else if(biasDn && (currentDir==DIR_AMBAS || currentDir==DIR_SOLO_VENTAS)) trade.Sell(dynLoteManual,_Symbol,bid,0,0,commentTag);
      return;
   }
   
   double net = GetNetProfitUSD();
   if(net <= -dynGatilloHedge) {
      int activeRescues = 0;
      for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic && StringFind(posInfo.Comment(),"_R")>=0) activeRescues++;
      
      if(activeRescues == 0) {
         int rhythm = rescueCount % 4;
         int numToOpen = (rhythm < 2) ? 1 : 2;
         for(int k=0; k<numToOpen; k++) {
            if(biasUp) trade.Buy(dynLoteRescate,_Symbol,ask,0,0,commentTag+"_R");
            else if(biasDn) trade.Sell(dynLoteRescate,_Symbol,bid,0,0,commentTag+"_R");
         }
      }
   }
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

void SyncWeb() {
   if(PurchaseID=="" || (TimeCurrent()<lastSync+30 && !syncPending)) return; 
   lastSync=TimeCurrent();
   
   string proposed = "";
   if(syncPending) {
       proposed = ",\"proposedSettings\":{" + 
                  "\"net_cycle\":" + DoubleToString(dynNet_Cycle,2) + "," +
                  "\"hedge_trigger\":" + DoubleToString(dynGatilloHedge,2) + "," +
                  "\"lote_manual\":" + DoubleToString(dynLoteManual,2) + "," +
                  "\"lote_rescate\":" + DoubleToString(dynLoteRescate,2) + "," +
                  "\"max_dd\":" + DoubleToString(dynMaxDD,2) + "," +
                  "\"trailling_stop\":" + DoubleToString(dynTrailing,2) + "," +
                  "\"timeframe\":\"" + dynTF + "\"" +
                  "}";
       syncPending = false;
   }

   string postD="{\"purchaseId\":\""+PurchaseID+"\",\"account\":\""+IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN))+"\",\"version\":\"7.50\",\"status\":\""+botStatus+"\"" + proposed + "}";
   char post[], res[]; string rH, head="Content-Type: application/json\r\n";
   StringToCharArray(postD,post,0,StringLen(postD),CP_UTF8);
   int resCode = WebRequest("POST","https://www.kopytrading.com/api/sync-positions",head,3000,post,res,rH);
   
   if(resCode == 200) {
      string jsonResponse = CharArrayToString(res, 0, WHOLE_ARRAY, CP_UTF8);
      ApplyRemoteSettings(jsonResponse);
   }
}

void ApplyRemoteSettings(string json) {
    double n = StringToDouble(GetJsonValue(json, "net_cycle")); 
    if(n > 0) dynNet_Cycle = n;
    
    double h = StringToDouble(GetJsonValue(json, "hedge_trigger"));
    if(h > 0) dynGatilloHedge = h;
    
    double lm = StringToDouble(GetJsonValue(json, "lote_manual"));
    if(lm > 0) dynLoteManual = lm;
    
    double lr = StringToDouble(GetJsonValue(json, "lote_rescate"));
    if(lr > 0) dynLoteRescate = lr;
    
    double md = StringToDouble(GetJsonValue(json, "max_dd"));
    if(md > 0) dynMaxDD = md;

    double tr = StringToDouble(GetJsonValue(json, "trailling_stop"));
    if(tr >= 0) dynTrailing = tr;
    
    string tf = GetJsonValue(json, "timeframe");
    if(tf != "" && tf != dynTF) {
        dynTF = tf;
        ENUM_TIMEFRAMES newTF = StringToTimeframe(tf);
        if(newTF != _Period) ChartSetSymbolPeriod(0, _Symbol, newTF);
    }
}

string GetJsonValue(string json, string key) {
   string search = "\"" + key + "\":";
   int pos = StringFind(json, search);
   if(pos < 0) return "";
   int start = pos + StringLen(search);
   int end = -1;
   
   // Si empieza por ", es un string
   if(StringSubstr(json, start, 1) == "\"") {
      start++;
      end = StringFind(json, "\"", start);
   } else {
      // Es un numero o booleano, termina en , o }
      int end1 = StringFind(json, ",", start);
      int end2 = StringFind(json, "}", start);
      if(end1 > 0 && (end1 < end2 || end2 < 0)) end = end1;
      else end = end2;
   }
   
   if(end < 0) return "";
   return StringSubstr(json, start, end - start);
}

ENUM_TIMEFRAMES StringToTimeframe(string tf) {
   if(tf == "M1") return PERIOD_M1;
   if(tf == "M5") return PERIOD_M5;
   if(tf == "M15") return PERIOD_M15;
   if(tf == "M30") return PERIOD_M30;
   if(tf == "H1") return PERIOD_H1;
   return _Period;
}

void CloseAll() { for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) trade.PositionClose(posInfo.Ticket()); }
void DeletePendings() { for(int i=OrdersTotal()-1; i>=0; i--) if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC)==activeMagic) trade.OrderDelete(OrderGetTicket(i)); }
int PositionsTotalBots() { int c=0; for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) c++; return c; }
double GetNetProfitUSD() { double p=0; for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) p+=posInfo.Profit()+posInfo.Swap()+posInfo.Commission(); return GetProfitUSD(p); }
double GetProfitUSD(double p) { return p * profitFactor; }

void CrearHUD() {
   ObjectsDeleteAll(0, PNL);
   int x=15, y=15, w=280, h=450; if(isMinimized) { w=200; h=50; }
   CrRect("bg",x,y,w,h,C'20,20,40',C'80,80,150',2);
   CrLabel("ttl",x+15,y+10,"EVO v7.5 RÍTMICA",clrWhite,10,"Arial Bold");
   if(isMinimized) { CrBtn("min",x+w-25,y+10,20,20,"+",C'40,40,80',clrWhite); return; }
   CrBtn("min",x+w-25,y+10,20,20,"-",C'40,40,80',clrWhite);
   
   int cy = y+50;
   CrLabel("pL",x+15,cy,"PnL HOY (USD):",C'150,150,200',8);
   CrLabel("pV",x+120,cy,DoubleToString(dayPnL,2)+" $",clrWhite,10,"Arial Bold");
   
   cy += 25;
   CrLabel("stL",x+15,cy,"ESTADO:",C'150,150,200',8);
   CrLabel("stV",x+120,cy,botStatus,C'0,255,127',9);
   
   cy += 25;
   CrLabel("rcL",x+15,cy,"RITMO RESCATE:",C'150,150,200',8);
   CrLabel("rcV",x+120,cy,IntegerToString(rescueCount % 4)+"/4",clrYellow,10);
   
   // --- INPUTS EDITABLES (Sincronizados con el terminal) ---
   cy += 35;
   CrLabel("metaL",x+15,cy,"META CICLO ($5):",C'100,200,255',7);
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
   
   cy += 35;
   CrBtn("b_zen",x+10,cy,125,30,"ZEN",currentMode==MODE_ZEN?C'0,100,255':C'40,40,70',clrWhite);
   CrBtn("b_har",x+145,cy,125,30,"COSECHA",currentMode==MODE_COSECHA?C'255,100,0':C'40,40,70',clrWhite);
   
   cy += 40;
   CrBtn("d_amb",x+10,cy,80,25,"AMBAS",currentDir==DIR_AMBAS?C'60,150,255':C'40,40,70',clrWhite);
   CrBtn("d_buy",x+95,cy,80,25,"SOLO BUY",currentDir==DIR_SOLO_COMPRAS?C'0,200,100':C'40,40,70',clrWhite);
   CrBtn("d_sel",x+180,cy,80,25,"SOLO SELL",currentDir==DIR_SOLO_VENTAS?C'220,50,50':C'40,40,70',clrWhite);
   
   cy += 40;
   CrBtn("close",x+10,cy,260,40,"CERRAR TODO",C'200,40,40',clrWhite);
}

void ActualizarHUD() {
   if(isMinimized) return;
   ObjectSetString(0,PNL+"pV",OBJPROP_TEXT,DoubleToString(dayPnL,2)+" $");
   ObjectSetString(0,PNL+"stV",OBJPROP_TEXT,botStatus);
   ObjectSetString(0,PNL+"rcV",OBJPROP_TEXT,IntegerToString(rescueCount % 4)+"/4");
   
   // Actualizar valores de los edits si no están siendo editados por el usuario
   if(ObjectGetInteger(0,PNL+"edit_target",OBJPROP_STATE)==0) ObjectSetString(0,PNL+"edit_target",OBJPROP_TEXT,DoubleToString(dynNet_Cycle,2));
   if(ObjectGetInteger(0,PNL+"edit_hedge",OBJPROP_STATE)==0) ObjectSetString(0,PNL+"edit_hedge",OBJPROP_TEXT,DoubleToString(dynGatilloHedge,2));
   if(ObjectGetInteger(0,PNL+"edit_lote_m",OBJPROP_STATE)==0) ObjectSetString(0,PNL+"edit_lote_m",OBJPROP_TEXT,DoubleToString(dynLoteManual,2));
   if(ObjectGetInteger(0,PNL+"edit_lote_r",OBJPROP_STATE)==0) ObjectSetString(0,PNL+"edit_lote_r",OBJPROP_TEXT,DoubleToString(dynLoteRescate,2));
   if(ObjectGetInteger(0,PNL+"edit_tstop",OBJPROP_STATE)==0) ObjectSetString(0,PNL+"edit_tstop",OBJPROP_TEXT,DoubleToString(dynTrailing,2));
}

void OnChartEvent(const int id,const long &lp,const double &dp,const string &sp) {
   if(id==CHARTEVENT_OBJECT_CLICK) {
      if(sp==PNL+"min") { isMinimized=!isMinimized; CrearHUD(); }
      if(sp==PNL+"b_zen") { currentMode=MODE_ZEN; CrearHUD(); }
      if(sp==PNL+"b_har") { currentMode=MODE_COSECHA; CrearHUD(); }
      if(sp==PNL+"d_amb") { currentDir=DIR_AMBAS; CrearHUD(); }
      if(sp==PNL+"d_buy") { currentDir=DIR_SOLO_COMPRAS; CrearHUD(); }
      if(sp==PNL+"d_sel") { currentDir=DIR_SOLO_VENTAS; CrearHUD(); }
      if(sp==PNL+"close") CloseAll();
      ObjectSetInteger(0,sp,OBJPROP_STATE,false);
   }
   
   if(id==CHARTEVENT_OBJECT_ENDEDIT) {
      if(sp==PNL+"edit_target") { dynNet_Cycle = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT)); syncPending=true; }
      if(sp==PNL+"edit_hedge")  { dynGatilloHedge = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT)); syncPending=true; }
      if(sp==PNL+"edit_lote_m") { dynLoteManual = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT)); syncPending=true; }
      if(sp==PNL+"edit_lote_r") { dynLoteRescate = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT)); syncPending=true; }
      if(sp==PNL+"edit_tstop")  { dynTrailing = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT)); syncPending=true; }
   }
}

void CrRect(string n,int x,int y,int w,int h,color bg,color bd,int bw=1) { ObjectCreate(0,PNL+n,OBJ_RECTANGLE_LABEL,0,0,0); ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h); ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,bd); ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,100); }
void CrLabel(string n,int x,int y,string t,color c,int s,string f="Segoe UI") { ObjectCreate(0,PNL+n,OBJ_LABEL,0,0,0); ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y); ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,c); ObjectSetInteger(0,PNL+n,OBJPROP_FONTSIZE,s); ObjectSetString(0,PNL+n,OBJPROP_FONT,f); ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,101); }
void CrBtn(string n,int x,int y,int w,int h,string t,color bg,color tc) { ObjectCreate(0,PNL+n,OBJ_BUTTON,0,0,0); ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h); ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,tc); ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,102); }
void CrEdit(string n,int x,int y,int w,int h,string t,color c,color bg) { ObjectCreate(0,PNL+n,OBJ_EDIT,0,0,0); ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h); ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,c); ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL+n,OBJPROP_ALIGN,ALIGN_CENTER); ObjectSetInteger(0,PNL+n,OBJPROP_FONTSIZE,8); ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,103); }

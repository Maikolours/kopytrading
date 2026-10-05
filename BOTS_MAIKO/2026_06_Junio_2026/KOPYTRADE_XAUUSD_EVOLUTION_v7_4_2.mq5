//+------------------------------------------------------------------+
//|     KOPYTRADE_XAUUSD_EVOLUTION_v7_4_2 - MASTER BLINDADO          |
//|   DIRECT ENTRY + 1.0X FULL LOCK HEDGE + HISTORY PNL HUD          |
//|   Copyright 2026, Kopytrading Corp. - kopytrading.com            |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "7.42"
#property strict
#property description "MASTER BLINDADO | Full Lock Hedge | History PnL HUD"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- HELPER ---
uint GetHash(string text) {
   uint hash = 5381;
   for(int i = 0; i < StringLen(text); i++) hash = ((hash << 5) + hash) + text[i];
   return hash & 0x7FFFFFFF;
}

//--- PARÁMETROS ---
sinput string separator0 = "=========================="; // === SEGURIDAD ===
input string   LicenseKey        = "TRIAL-2026";
input string   PurchaseID        = "";         
input bool     ForceCentMode     = false;

sinput string separator1 = "=========================="; // === GESTIÓN ===
enum ENUM_MODE { MODE_ZEN, MODE_COSECHA };
enum ENUM_DIR  { DIR_AMBAS, DIR_SOLO_COMPRAS, DIR_SOLO_VENTAS };
input ENUM_MODE ModePreset        = MODE_COSECHA; 
input int      MagicNumber        = 700742;       
input int      MaxPosiciones      = 2;            
input double   LoteManual         = 0.02;         
input double   MaxDrawdownAccount = 50.0;         

sinput string separator2 = "=========================="; // === ESTRATEGIA DIRECTA ===
input double   GatilloHedge_USD    = 3.0;          // Valla estática a -$3.00
input double   HedgeMultiplier     = 1.0;          // 1.0 = Bloqueo total (0.02 vs 0.02)
input double   Target_Individual   = 0.50;         // Meta por operación
input double   Net_Cycle_USD       = 2.0;          // Cierre total bloque
input int      SegundosEspera      = 60;           // Espera tras cerrar (Segundos)
input double   MaxDistEMA_USD      = 1.5;          // No entrar si precio > $1.5 lejos de EMA
input int      RSI_Overbought      = 70;           // No comprar si RSI > 70
input int      RSI_Oversold        = 30;           // No vender si RSI < 30


sinput string separator3 = "=========================="; // === PROTECCIÓN ===
input bool     ActivarBE           = true;         // Activar Break-Even (BE)
input double   BE_Trigger_USD      = 0.15;         // Proteger a los $ (USD Reales)
input bool     ActivarTS           = true;         // Activar Trailing Stop (TS)
input double   TS_Activation_USD   = 0.35;         // Activar TS a los $ (Profit)
input double   TS_Distance_USD     = 0.20;         // Distancia TS (en $)
input double   TS_Step_Points      = 5;            // Salto mínimo (Points)

sinput string separator4 = "=========================="; // === VISUALES ===
input bool     AutoDrawIndicators  = true;         
input bool     EnableTimeFilter    = true;
input int      StartHour1 = 1;   input int EndHour1 = 24;

//--- GLOBALES ---
CTrade         trade;
CPositionInfo  posInfo;
int            activeMagic, h_ema20, h_ema50, h_rsi;
bool           remotePaused = false, isMinimized = false;
ENUM_MODE      currentMode;
ENUM_DIR       currentDir = DIR_AMBAS;
string         botStatus = "LISTO", commentTag = "EVO_GOLD_74";
double         profitFactor = 1.0, dayPnL = 0;
datetime       lastSync = 0, coolingEndTime = 0, lastTradeClose = 0;


#define PNL "AEVO_v742"

int OnInit() {
   currentMode = ModePreset;
   activeMagic = MagicNumber;
   trade.SetExpertMagicNumber(activeMagic);
   if(_Symbol == "BTCUSD" || _Symbol == "BTCUSD.bit") commentTag = "EVO_BTC_74";
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if((tv < 0.1 && AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL) || ForceCentMode) profitFactor = 0.01;
   h_ema20 = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   h_ema50 = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
   h_rsi   = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   if(AutoDrawIndicators) { ChartIndicatorAdd(0, 0, h_ema20); ChartIndicatorAdd(0, 0, h_ema50); ChartIndicatorAdd(0, 1, h_rsi); }
   CrearHUD();
   remotePaused = false; 
   EventSetTimer(3);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) { ObjectsDeleteAll(0, PNL); }

void OnTick() {
   SyncWeb();
   if(remotePaused) { botStatus = "🔴 PAUSA REMOTA"; DeletePendings(); ActualizarHUD(); return; }
   double netUSD = GetNetProfitUSD();
   if(MaxDrawdownAccount > 0 && netUSD <= -MaxDrawdownAccount) { CloseAll(); DeletePendings(); botStatus = "🛑 STOP EMERGENCIA"; remotePaused = true; return; }
   if(!IsTradingTime() || TimeCurrent() < coolingEndTime) { botStatus = (TimeCurrent() < coolingEndTime) ? "ENFRIANDO" : "FUERA HORA"; ProtectAll(); DeletePendings(); ActualizarHUD(); return; }
   ProtectAll();
   ManageStrike();
   botStatus = "🟢 TRABAJANDO";
   dayPnL = CalculateDayProfit();
   ActualizarHUD();
}

void SyncWeb() {
   if(PurchaseID=="" || TimeCurrent()<lastSync+30) return; lastSync=TimeCurrent();
   string postD="{\"purchaseId\":\""+PurchaseID+"\",\"account\":\""+IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN))+"\",\"version\":\"7.42\",\"status\":\""+botStatus+"\"}";
   char post[], res[]; string rH, head="Content-Type: application/json\r\n";
   StringToCharArray(postD,post,0,StringLen(postD),CP_UTF8);
   if(WebRequest("POST","https://www.kopytrading.com/api/sync-positions",head,3000,post,res,rH) == 200) {
      string r = CharArrayToString(res,0,WHOLE_ARRAY,CP_UTF8);
      if(StringFind(r,"\"paused\":true")>=0) remotePaused=true;
      if(StringFind(r,"\"paused\":false")>=0) remotePaused=false;
   }
}

void ProtectAll() {
   double net = GetNetProfitUSD();
   int total = 0;
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) {
         total++;
         double pUSD = GetProfitUSD(posInfo.Profit()+posInfo.Swap()+posInfo.Commission());
         if(pUSD >= Target_Individual) { 
            if(trade.PositionClose(posInfo.Ticket())) lastTradeClose = TimeCurrent();
            continue; 
         }
         if(ActivarBE && pUSD >= BE_Trigger_USD) {
            double sl = posInfo.StopLoss(), bid=SymbolInfoDouble(_Symbol,SYMBOL_BID), ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
            if(posInfo.PositionType()==POSITION_TYPE_BUY) {
               double be=posInfo.PriceOpen()+10*_Point; 
               if(sl<be || sl==0) trade.PositionModify(posInfo.Ticket(),NormalizeDouble(be,_Digits),0);
            } else {
               double be=posInfo.PriceOpen()-10*_Point; 
               if(sl>be || sl==0) trade.PositionModify(posInfo.Ticket(),NormalizeDouble(be,_Digits),0);
            }
         }
         
         // --- TRAILING STOP LOGIC ---
         if(ActivarTS && pUSD >= TS_Activation_USD) {
            double sl = posInfo.StopLoss(), bid=SymbolInfoDouble(_Symbol,SYMBOL_BID), ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
            double pointsDist = (TS_Distance_USD / (LoteManual * profitFactor)) * 100; // Convierte USD a Points aprox
            if(posInfo.PositionType()==POSITION_TYPE_BUY) {
               double nSL = NormalizeDouble(bid - pointsDist*_Point, _Digits);
               if(nSL > sl + TS_Step_Points*_Point) trade.PositionModify(posInfo.Ticket(), nSL, 0);
            } else {
               double nSL = NormalizeDouble(ask + pointsDist*_Point, _Digits);
               if(nSL < sl - TS_Step_Points*_Point || sl==0) trade.PositionModify(posInfo.Ticket(), nSL, 0);
            }
         }
      }
   }
   if(total >= 2 && net >= Net_Cycle_USD) { CloseAll(); coolingEndTime=TimeCurrent()+120; }
}

void ManageStrike() {
   if(PositionsTotalBots() >= MaxPosiciones) { DeletePendings(); return; }
   if(TimeCurrent() < lastTradeClose + SegundosEspera) { botStatus = "ESPERANDO CONFIRMACIÓN"; return; }
   
   double emaF[1], emaS[1], rsi[1], bid=SymbolInfoDouble(_Symbol,SYMBOL_BID), ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   if(CopyBuffer(h_ema20,0,0,1,emaF)<=0 || CopyBuffer(h_ema50,0,0,1,emaS)<=0 || CopyBuffer(h_rsi,0,0,1,rsi)<=0) return;
   
   bool biasUp = (emaF[0] > emaS[0] && rsi[0] > 50 && rsi[0] < RSI_Overbought);
   bool biasDn = (emaF[0] < emaS[0] && rsi[0] < 50 && rsi[0] > RSI_Oversold);
   
   // Filtro de sobre-extensión (distancia a la EMA 20)
   double distPoints = MathAbs(bid - emaF[0]) / _Point;
   double distUSD = (distPoints / 100) * (LoteManual * 100) * profitFactor; // Conversión rápida a USD
   if(distUSD > MaxDistEMA_USD) { botStatus = "PRECIO MUY LEJOS (ESPERANDO)"; return; }
   
   int posTotal = PositionsTotalBots();
   
   if(posTotal == 0) {
      DeletePendings();
      if(biasUp && (currentDir==DIR_AMBAS || currentDir==DIR_SOLO_COMPRAS)) { if(trade.Buy(LoteManual,_Symbol,ask,0,0,commentTag)) lastTradeClose = 0; }
      else if(biasDn && (currentDir==DIR_AMBAS || currentDir==DIR_SOLO_VENTAS)) { if(trade.Sell(LoteManual,_Symbol,bid,0,0,commentTag)) lastTradeClose = 0; }
      return;
   }
   
   ulong mainTicket = 0; double entryP = 0, pUSD = 0; long mainType = -1; bool hasOpposite = false;
   for(int i=0; i<PositionsTotal(); i++) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) {
         if(mainTicket==0) { mainType=posInfo.PositionType(); mainTicket=posInfo.Ticket(); entryP=posInfo.PriceOpen(); pUSD=GetProfitUSD(posInfo.Profit()+posInfo.Swap()+posInfo.Commission()); }
         else if(posInfo.PositionType() != mainType) hasOpposite=true;
      }
   }
   
   if(!hasOpposite && pUSD <= -GatilloHedge_USD) {
      bool hasPending = false;
      for(int j=0; j<OrdersTotal(); j++) if(OrderSelect(OrderGetTicket(j)) && OrderGetInteger(ORDER_MAGIC)==activeMagic) { hasPending=true; break; }
      if(!hasPending) {
         double hedgeLot = NormalizeDouble(LoteManual * HedgeMultiplier, 2);
         double targetHedgeP = (mainType==POSITION_TYPE_BUY) ? entryP - 300*_Point : entryP + 300*_Point;
         bool pastHedge = (mainType==POSITION_TYPE_BUY) ? (bid < targetHedgeP) : (ask > targetHedgeP);
         if(pastHedge) {
            if(mainType==POSITION_TYPE_BUY) trade.Sell(hedgeLot,_Symbol,bid,0,0,commentTag+"_H");
            else trade.Buy(hedgeLot,_Symbol,ask,0,0,commentTag+"_H");
         } else {
            if(mainType==POSITION_TYPE_BUY) trade.SellStop(hedgeLot,targetHedgeP,_Symbol,0,0,0,0,commentTag+"_G");
            else trade.BuyStop(hedgeLot,targetHedgeP,_Symbol,0,0,0,0,commentTag+"_G");
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

void CloseAll() { for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) trade.PositionClose(posInfo.Ticket()); }
void DeletePendings() { for(int i=OrdersTotal()-1; i>=0; i--) if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC)==activeMagic) trade.OrderDelete(OrderGetTicket(i)); }
int PositionsTotalBots() { int c=0; for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) c++; return c; }
double GetNetProfitUSD() { double p=0; for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) p+=posInfo.Profit()+posInfo.Swap()+posInfo.Commission(); return GetProfitUSD(p); }
double GetProfitUSD(double p) { return p * profitFactor; }
bool IsTradingTime() { MqlDateTime dt; TimeToStruct(TimeCurrent(), dt); return (!EnableTimeFilter || (dt.hour >= StartHour1 && dt.hour < EndHour1)); }

void CrearHUD() {
   ObjectsDeleteAll(0, PNL);
   int x=15, y=15, w=280, h=360; if(isMinimized) { w=200; h=50; }
   CrRect("bg",x,y,w,h,C'15,15,35',C'60,60,120',2);
   string vName = (_Symbol=="BTCUSD") ? "BTC EVO v7.4.2" : "EVO v7.4.2 BLINDADO";
   CrLabel("ttl",x+15,y+10,vName,clrWhite,10,"Arial Bold");
   if(isMinimized) { CrBtn("min",x+w-25,y+10,20,20,"+",C'40,40,80',clrWhite); return; }
   CrBtn("min",x+w-25,y+10,20,20,"-",C'40,40,80',clrWhite);
   CrLabel("pL",x+15,y+50,"PnL HOY (USD):",C'150,150,200',8);
   CrLabel("pV",x+120,y+50,"0.00 $",clrWhite,10,"Arial Bold");
   CrLabel("stL",x+15,y+75,"ESTADO:",C'150,150,200',8);
   CrLabel("stV",x+120,y+75,botStatus,C'0,255,127',9);
   CrBtn("b_zen",x+10,y+110,125,30,"ZEN",currentMode==MODE_ZEN?C'0,100,255':C'40,40,70',clrWhite);
   CrBtn("b_har",x+145,y+110,125,30,"COSECHA",currentMode==MODE_COSECHA?C'255,100,0':C'40,40,70',clrWhite);
   CrBtn("d_amb",x+10,y+150,80,25,"AMBAS",currentDir==DIR_AMBAS?C'60,150,255':C'40,40,70',clrWhite);
   CrBtn("d_buy",x+95,y+150,80,25,"SOLO BUY",currentDir==DIR_SOLO_COMPRAS?C'0,200,100':C'40,40,70',clrWhite);
   CrBtn("d_sel",x+180,y+150,80,25,"SOLO SELL",currentDir==DIR_SOLO_VENTAS?C'220,50,50':C'40,40,70',clrWhite);
   CrBtn("close",x+10,y+190,260,40,"CERRAR TODO",C'200,40,40',clrWhite);
   string aT=(profitFactor<1.0)?"REAL CENT":"REAL USD";
   if(AccountInfoInteger(ACCOUNT_TRADE_MODE)==ACCOUNT_TRADE_MODE_DEMO) aT="DEMO Account";
   CrLabel("acc",x+15,y+250,"CUENTA: "+aT,C'120,120,150',8);
   CrLabel("rem",x+15,y+270,"REMOTO: ONLINE",C'0,200,100',8);
}

void ActualizarHUD() {
   if(isMinimized) return;
   ObjectSetString(0,PNL+"pV",OBJPROP_TEXT,DoubleToString(dayPnL,2)+" $");
   ObjectSetString(0,PNL+"stV",OBJPROP_TEXT,botStatus);
   ObjectSetInteger(0,PNL+"stV",OBJPROP_COLOR,remotePaused?C'220,50,50':C'0,255,127');
}

void OnChartEvent(const int id,const long &lp,const double &dp,const string &sp) {
   if(id!=CHARTEVENT_OBJECT_CLICK) return;
   if(sp==PNL+"min") { isMinimized=!isMinimized; CrearHUD(); }
   if(sp==PNL+"b_zen") { currentMode=MODE_ZEN; CrearHUD(); }
   if(sp==PNL+"b_har") { currentMode=MODE_COSECHA; CrearHUD(); }
   if(sp==PNL+"d_amb") { currentDir=DIR_AMBAS; CrearHUD(); }
   if(sp==PNL+"d_buy") { currentDir=DIR_SOLO_COMPRAS; CrearHUD(); }
   if(sp==PNL+"d_sel") { currentDir=DIR_SOLO_VENTAS; CrearHUD(); }
   if(sp==PNL+"close") CloseAll();
   ObjectSetInteger(0,sp,OBJPROP_STATE,false);
}

void CrRect(string n,int x,int y,int w,int h,color bg,color bd,int bw=1) { ObjectCreate(0,PNL+n,OBJ_RECTANGLE_LABEL,0,0,0); ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h); ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,bd); ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,100); }
void CrLabel(string n,int x,int y,string t,color c,int s,string f="Segoe UI") { ObjectCreate(0,PNL+n,OBJ_LABEL,0,0,0); ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y); ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,c); ObjectSetInteger(0,PNL+n,OBJPROP_FONTSIZE,s); ObjectSetString(0,PNL+n,OBJPROP_FONT,f); ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,101); }
void CrBtn(string n,int x,int y,int w,int h,string t,color bg,color tc) { ObjectCreate(0,PNL+n,OBJ_BUTTON,0,0,0); ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h); ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,tc); ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,102); }

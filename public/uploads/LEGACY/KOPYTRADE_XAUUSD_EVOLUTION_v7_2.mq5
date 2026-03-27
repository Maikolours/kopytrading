//+------------------------------------------------------------------+
//|     KOPYTRADE_XAUUSD_EVOLUTION_v7_2 - MASTER STRATEGY            |
//|   PULLBACK HUNTING + STATIC HEDGE + UNIVERSAL BE ($1.00)         |
//|   Copyright 2026, Kopytrading Corp. - kopytrading.com            |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "7.20"
#property strict
#property description "MASTER VERSION | Pullback Entry | Static Hedge | Universal BE"

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
sinput string separator0 = "=========================="; // === SEGURIDAD & CUENTA ===
input string   LicenseKey        = "TRIAL-2026";
input string   PurchaseID        = "";         
input bool     ForceCentMode     = false;

sinput string separator1 = "=========================="; // === GESTIÓN INTERNA ===
enum ENUM_MODE { MODE_ZEN, MODE_COSECHA };
enum ENUM_DIR  { DIR_AMBAS, DIR_SOLO_COMPRAS, DIR_SOLO_VENTAS };
input ENUM_MODE ModePreset        = MODE_COSECHA; 
input int      MagicNumber        = 700720;       
input int      MaxPosiciones      = 3;            
input double   LoteManual         = 0.02;         
input double   MaxDrawdownAccount = 50.0;         

sinput string separator2 = "=========================="; // === ESTRATEGIA MAESTRA ===
input int      DistanciaGates      = 150;         // Espacio entre precio y trampa
input int      MaxPersecucion      = 500;         // Máximo retroceso (Anclaje)
input double   GatilloHedge_USD    = 3.0;          // Pérdida para poner valla estática
input double   Net_Cycle_USD       = 2.0;          // Meta para cerrar todo el bloque
input double   Target_Individual   = 0.50;         // Meta por operación (v5.55 feel)

sinput string separator3 = "=========================="; // === PROTECCIÓN AVANZADA ===
input bool     ActivarBE           = true;        
input double   BE_Trigger_USD      = 1.0;          // Proteger a los $1.00 de ganancia
input bool     ActivarTrailing     = true;        
input int      TrailingPoints      = 1500;        

sinput string separator4 = "=========================="; // === VISUALES & HORARIO ===
input bool     AutoDrawIndicators  = true;         
input bool     EnableTimeFilter    = true;
input int      StartHour1 = 9;   input int EndHour1 = 22;

//--- GLOBALES ---
CTrade         trade;
CPositionInfo  posInfo;
int            activeMagic, h_ema20, h_ema50, h_rsi;
bool           remotePaused = false, isMinimized = false;
ENUM_MODE      currentMode;
ENUM_DIR       currentDir = DIR_AMBAS;
string         botStatus = "LISTO";
double         profitFactor = 1.0;
datetime       lastSync = 0, coolingEndTime = 0;

#define PNL "AEVO_v72"

int OnInit() {
   currentMode = ModePreset;
   activeMagic = MagicNumber;
   trade.SetExpertMagicNumber(activeMagic);
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
   ManageGates();
   botStatus = "🟢 TRABAJANDO";
   ActualizarHUD();
}

void SyncWeb() {
   if(PurchaseID=="" || TimeCurrent()<lastSync+30) return; lastSync=TimeCurrent();
   string postD="{\"purchaseId\":\""+PurchaseID+"\",\"account\":\""+IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN))+"\",\"version\":\"7.20\",\"status\":\""+botStatus+"\"}";
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
         
         // TP Individual
         if(pUSD >= Target_Individual) { trade.PositionClose(posInfo.Ticket()); continue; }
         
         // Universal BE $1.00
         if(ActivarBE && pUSD >= BE_Trigger_USD) {
            double sl = posInfo.StopLoss(), bid=SymbolInfoDouble(_Symbol,SYMBOL_BID), ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
            if(posInfo.PositionType()==POSITION_TYPE_BUY) {
               double be=posInfo.PriceOpen()+2*_Point; 
               if(sl<be || sl==0) trade.PositionModify(posInfo.Ticket(),NormalizeDouble(be,_Digits),0);
            } else {
               double be=posInfo.PriceOpen()-2*_Point; 
               if(sl>be || sl==0) trade.PositionModify(posInfo.Ticket(),NormalizeDouble(be,_Digits),0);
            }
         }
      }
   }
   if(total >= 2 && net >= Net_Cycle_USD) { CloseAll(); coolingEndTime=TimeCurrent()+120; }
}

void ManageGates() {
   if(PositionsTotalBots() >= MaxPosiciones) { DeletePendings(); return; }
   
   double emaF[1], emaS[1], rsi[1];
   if(CopyBuffer(h_ema20,0,0,1,emaF)<=0 || CopyBuffer(h_ema50,0,0,1,emaS)<=0 || CopyBuffer(h_rsi,0,0,1,rsi)<=0) return;
   bool biasUp = (emaF[0] > emaS[0] && rsi[0] > 50);
   bool biasDn = (emaF[0] < emaS[0] && rsi[0] < 50);
   
   bool hasBuyStop=false, hasSellStop=false, hasBuyPos=false, hasSellPos=false;
   double maxBuyLoss=0, maxSellLoss=0;
   
   for(int i=0; i<PositionsTotal(); i++) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) {
         double pUSD = GetProfitUSD(posInfo.Profit()+posInfo.Swap()+posInfo.Commission());
         if(posInfo.PositionType()==POSITION_TYPE_BUY) { hasBuyPos=true; if(pUSD < maxBuyLoss) maxBuyLoss=pUSD; }
         else { hasSellPos=true; if(pUSD < maxSellLoss) maxSellLoss=pUSD; }
      }
   }
   
   for(int i=OrdersTotal()-1; i>=0; i--) {
      ulong t=OrderGetTicket(i); 
      if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC)==activeMagic) {
         long type = OrderGetInteger(ORDER_TYPE);
         double currentP = OrderGetDouble(ORDER_PRICE_OPEN);
         double d = DistanciaGates*_Point;
         
         if(type==ORDER_TYPE_BUY_STOP) {
            hasBuyStop=true;
            double targetP = SymbolInfoDouble(_Symbol,SYMBOL_ASK)+d;
            // TRAILING ENTRY: Solo baja si el mercado cae
            if(targetP < currentP && currentP - targetP < MaxPersecucion*_Point) trade.OrderModify(t,NormalizeDouble(targetP,_Digits),0,0,ORDER_TIME_GTC,0,0);
         } else if(type==ORDER_TYPE_SELL_STOP) {
            hasSellStop=true;
            double targetP = SymbolInfoDouble(_Symbol,SYMBOL_BID)-d;
            // TRAILING ENTRY: Solo sube si el mercado sube
            if(targetP > currentP && targetP - currentP < MaxPersecucion*_Point) trade.OrderModify(t,NormalizeDouble(targetP,_Digits),0,0,ORDER_TIME_GTC,0,0);
         }
      }
   }
   
   // SEGURIDAD: Si perdemos > $3.0, ponemos valla estática contraria (si no existe)
   if(hasBuyPos && maxBuyLoss <= -GatilloHedge_USD && !hasSellStop && !hasSellPos) {
      trade.SellStop(LoteManual,SymbolInfoDouble(_Symbol,SYMBOL_BID)-DistanciaGates*_Point,_Symbol,0,0,0,0,"HEDGE");
      return;
   }
   if(hasSellPos && maxSellLoss <= -GatilloHedge_USD && !hasBuyStop && !hasBuyPos) {
      trade.BuyStop(LoteManual,SymbolInfoDouble(_Symbol,SYMBOL_ASK)+DistanciaGates*_Point,_Symbol,0,0,0,0,"HEDGE");
      return;
   }

   // ENTRADA NORMAL PULLBACK
   double dPoints = DistanciaGates*_Point;
   if(!hasBuyStop && !hasBuyPos && biasUp && (currentDir==DIR_AMBAS || currentDir==DIR_SOLO_COMPRAS)) 
      trade.BuyStop(LoteManual,SymbolInfoDouble(_Symbol,SYMBOL_ASK)+dPoints,_Symbol,0,0,0,0,"G_BUY");
   if(!hasSellStop && !hasSellPos && biasDn && (currentDir==DIR_AMBAS || currentDir==DIR_SOLO_VENTAS)) 
      trade.SellStop(LoteManual,SymbolInfoDouble(_Symbol,SYMBOL_BID)-dPoints,_Symbol,0,0,0,0,"G_SELL");
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
   CrLabel("ttl",x+15,y+10,"EVO v7.2 MASTER STRATEGY",clrWhite,10,"Arial Bold");
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

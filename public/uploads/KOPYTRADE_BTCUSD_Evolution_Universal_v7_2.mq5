//+------------------------------------------------------------------+
//|          KOPYTRADE_BTCUSD_Evolution_Universal_v7_50         |
//|   EDICIÓN UNIVERSAL: PHASE 3 - SMART CLUSTER RESCUE             |
//|   kopytrading.com - v7.50 "Tranquilo pero Decidido"             |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrade Corp."
#property link      "https://www.kopytrade.com"
#property version   "7.50"
#property strict
#property description "Universal BTC Evolution | Phase 3 | Smart Rescue Offsetting"

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/SymbolInfo.mqh>

//--- DECLARACIONES VISUALES ---
void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bw=1);
void CrLabel(string n, int x, int y, string t, color c, int s=9, string f="Segoe UI");
void CrBtn(string n, int x, int y, int w, int h, string t, color bg, color tc);

//============================================================
//  CONFIGURACIÓN & LICENCIA
//============================================================
input group "=== SEGURIDAD & VÍNCULO ==="
input string   LicenseKey        = "BTC-ULTRA-2026";
input string   PurchaseID        = "";         
input bool     EscalarACent      = true;       // 💰 Escalado Automático (Recomendado)

input group "=== GESTIÓN DE RIESGO BTC ==="
input double   LoteManual         = 0.01;      
input int      MagicNumber        = 707070;    
input double   MaxDrawdown_Uni    = 500.0;     // Stop Emergencia Cuenta (unid. o $)
input double   Max_DD_Individual  = 100.0;     // Stop por Operación (unid. o $)
input int      MaxPosiciones      = 4;         
input int      Max_Velas_Vida     = 0;         

input group "=== RESCATE MATEMÁTICO BTC ==="
input bool     ActivarRescate     = true;      
input double   DistanciaRescate   = 50.0;      // Perdida para gatillo (unid. o $)
input double   MultiplicadorLote  = 2.0;       

input group "=== METAS & OBJETIVOS ==="
input double   MetaDiaria_Uni     = 500.0;     // Ganancia Diaria (unid. o $)
input double   Meta_Ciclo_Uni     = 100.0;     // Neto para cerrar ciclo (unid. o $)
input double   Harvest_TP_Uni     = 20.0;      // Meta por operación individual (unid. o $)

input group "=== PROTECCIÓN (BE & TRAILING) ==="
input bool     ActivarBE           = true;     
input double   BE_Trigger_Uni      = 15.0;     
input bool     ActivarTrailing     = true;     
input int      TrailingPoints      = 1500;     
input int      TrailingStep        = 200;      

input group "=== ESTRATEGIA TREND & CALMA ==="
input int      CooldownSeconds     = 60;       
input int      MA_Fast             = 20;
input int      MA_Medium           = 50;
input int      MA_Trend            = 200;
input double   DistanciaEntrada_Uni = 10.0;    

//--- Variables internas ---
CTrade         trade;
CPositionInfo  posInfo;
int            h_ma20, h_ma50, h_ma200, h_rsi;
datetime       coolingEndTime = 0;
datetime       lastRemoteSync = 0;
datetime       lastPositionsSync = 0;
double         scale = 1.0;

enum ENUM_DIR  { DIR_COMPRAS, DIR_VENTAS, DIR_AMBAS };
enum ENUM_MODE { MODE_ZEN, MODE_COSECHA };

ENUM_DIR       currentDir  = DIR_AMBAS;
ENUM_MODE      currentMode = MODE_COSECHA;
string         botStatus   = "LISTO";
bool           isMinimized = false;
bool           remotePaused = false; 

// Params efectivos escalados
double eff_HarvestTP, eff_CycleMeta, eff_BETrigger, eff_DailyGoal, eff_StopEmerg, eff_StopIndiv, eff_DistResTrigger, eff_Entrada;
int    eff_MaxPos;

#define PNL "BSR_U_v7_"

//--- COLORES PREMIUM ---
color CLR_BG      = C'10,10,25';
color CLR_HDR     = C'20,40,80';
color CLR_BRD     = C'60,100,200';
color CLR_TXT     = clrWhite;
color CLR_SUCCESS = C'40,200,90';
color CLR_DANGER  = C'210,50,50';
color CLR_WARN    = C'210,170,40';
color CLR_ACCENT  = C'40,120,220';
color CLR_MUTED   = C'130,130,170';

int OnInit() {
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetTypeFillingBySymbol(_Symbol);
   
   // Detección automática de escala
   if(EscalarACent && SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) < 0.01) scale = 100.0;
   else scale = 1.0;

   h_ma20  = iMA(_Symbol,_Period,MA_Fast,0,MODE_SMA,PRICE_CLOSE);
   h_ma50  = iMA(_Symbol,_Period,MA_Medium,0,MODE_SMA,PRICE_CLOSE);
   h_ma200 = iMA(_Symbol,_Period,MA_Trend,0,MODE_SMA,PRICE_CLOSE);
   h_rsi   = iRSI(_Symbol,_Period,14,PRICE_CLOSE);
   
   ChartIndicatorAdd(0, 0, h_ma20);
   ChartIndicatorAdd(0, 0, h_ma50);
   ChartIndicatorAdd(0, 0, h_ma200);
   ChartIndicatorAdd(0, 1, h_rsi);
   
   UpdateEffectiveParams();
   CrearPanel(); 
   SyncPositions();
   EventSetTimer(3); 
   return(INIT_SUCCEEDED);
}

void UpdateEffectiveParams() {
    if(currentMode == MODE_ZEN) {
       eff_HarvestTP = 10.0 * scale;
       eff_CycleMeta = 30.0 * scale;
       eff_BETrigger = 10.0 * scale;
       eff_MaxPos    = 1;
       eff_Entrada   = 50.0 * scale;
    } else {
       eff_HarvestTP = Harvest_TP_Uni * scale;
       eff_CycleMeta = Meta_Ciclo_Uni * scale;
       eff_BETrigger = BE_Trigger_Uni * scale;
       eff_MaxPos    = MaxPosiciones;
       eff_Entrada   = DistanciaEntrada_Uni * scale;
    }
    
    // SEGURIDAD: Evitar que el BE asfixie la operación (Mínimo $1.50 de beneficio para mover stop)
    if(eff_BETrigger < 1.50) eff_BETrigger = 1.50;
    eff_DailyGoal  = MetaDiaria_Uni * scale;
    eff_StopEmerg  = MaxDrawdown_Uni * scale;
    eff_StopIndiv  = Max_DD_Individual * scale;
    eff_DistResTrigger = DistanciaRescate * scale;
}

void OnTick() {
   double p_day = GetDailyProfit();
   double p_net = GetCurrentNetProfit();
   
   if(remotePaused) { botStatus = "🔴 PAUSA REMOTA"; DeleteBotPendings(); ActualizarPanel(); return; }
   
   if(eff_DailyGoal > 0 && p_day >= eff_DailyGoal) {
      if(PositionsTotalBots() == 0) { botStatus = "META ALCANZADA"; DeleteBotPendings(); ActualizarPanel(); return; }
      if(p_net >= 0) { CloseAllBotPositions(); DeleteBotPendings(); botStatus = "META ALCANZADA"; ActualizarPanel(); return; }
      else botStatus = "META (LIMPIANDO)";
   }

   ManageOpenPositions();
   MaintainGates();
   ActualizarPanel();
   SyncPositions();
}

void ManageOpenPositions() {
    double net = GetCurrentNetProfit();
    int count = PositionsTotalBots();

    if(eff_StopEmerg > 0 && net <= -eff_StopEmerg) {
       CloseAllBotPositions(); botStatus = "🛑 STOP EMERGENCIA"; remotePaused = true; return;
    }

    if(count >= 2 && net >= eff_CycleMeta) {
       CloseAllBotPositions(); coolingEndTime = TimeCurrent() + CooldownSeconds; return;
    }
    
    for(int i=PositionsTotal()-1; i>=0; i--) {
       if(posInfo.SelectByIndex(i) && posInfo.Magic() == MagicNumber) {
          double p = posInfo.Profit() + posInfo.Swap();
          if(p <= -eff_StopIndiv) { trade.PositionClose(posInfo.Ticket()); continue; }
          if(p >= eff_HarvestTP && posInfo.Comment() != "RES_U" && posInfo.Comment() != "RESCATE_P") { trade.PositionClose(posInfo.Ticket()); continue; }

          // BE & Trailing
          if(ActivarBE && p >= eff_BETrigger) {
             double open = posInfo.PriceOpen(), bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK), sl = posInfo.StopLoss();
             if(posInfo.PositionType()==POSITION_TYPE_BUY) {
                double nBE = open + (SymbolInfoDouble(_Symbol, SYMBOL_ASK)-open)*0.1;
                if(MathAbs(sl - nBE) > _Point) if(sl < nBE || sl == 0) trade.PositionModify(posInfo.Ticket(), NormalizeDouble(nBE, _Digits), posInfo.TakeProfit());
                if(ActivarTrailing && bid-nBE > TrailingPoints*_Point) {
                   double ts = bid - TrailingPoints*_Point;
                   if((ts > sl + TrailingStep*_Point || sl == 0) && MathAbs(sl - ts) > _Point) trade.PositionModify(posInfo.Ticket(), NormalizeDouble(ts, _Digits), posInfo.TakeProfit());
                }
             } else {
                double nBE = open - (open-SymbolInfoDouble(_Symbol, SYMBOL_BID))*0.1;
                if(MathAbs(sl - nBE) > _Point) if(sl > nBE || sl == 0) trade.PositionModify(posInfo.Ticket(), NormalizeDouble(nBE, _Digits), posInfo.TakeProfit());
                if(ActivarTrailing && nBE-ask > TrailingPoints*_Point) {
                   double ts = ask + TrailingPoints*_Point;
                   if((ts < sl - TrailingStep*_Point || sl == 0) && MathAbs(sl - ts) > _Point) trade.PositionModify(posInfo.Ticket(), NormalizeDouble(ts, _Digits), posInfo.TakeProfit());
                }
             }
          }
          
          // --- PHASE 3: SMART CLUSTER RESCUE (Offsetting) ---
          if(p < 0 && MathAbs(p) >= (eff_StopIndiv * 0.4) && posInfo.Comment() != "RESCATE_P") {
             int activeRescues = 0;
             for(int j=0; j<PositionsTotal(); j++) {
                if(posInfo.SelectByIndex(j) && posInfo.Magic() == MagicNumber && posInfo.Comment() == "RESCATE_P") { activeRescues++; }
             }
             
             if(activeRescues == 0) {
                double resLot = NormalizeDouble(posInfo.Volume() * 0.5, 2);
                if(resLot < 0.01) resLot = 0.01;
                
                double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
                double tpPoints = (1.50 / resLot) / tickVal;
                
                trade.SetExpertMagicNumber(MagicNumber);
                if(posInfo.PositionType() == POSITION_TYPE_BUY) {
                   double resTP = SymbolInfoDouble(_Symbol, SYMBOL_BID) - (tpPoints * _Point);
                   if(trade.Sell(resLot, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_BID), 0, NormalizeDouble(resTP, _Digits), "RESCATE_P"))
                      Print("PHASE 3: Rescate SELL lanzado...");
                } else {
                   double resTP = SymbolInfoDouble(_Symbol, SYMBOL_ASK) + (tpPoints * _Point);
                   if(trade.Buy(resLot, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_ASK), 0, NormalizeDouble(resTP, _Digits), "RESCATE_P"))
                      Print("PHASE 3: Rescate BUY lanzado...");
                }
             }
          }
       }
    }
}

void MaintainGates() {
   if(remotePaused) { DeleteBotPendings(); return; }
   int count = PositionsTotalBots();
   
   // Entrada agresiva (romper enfriamiento si tendencia fuerte)
   if(count == 0 && TimeCurrent() < coolingEndTime && currentMode == MODE_COSECHA) {
      double r[]; CopyBuffer(h_rsi, 0, 0, 1, r);
      if((currentDir != DIR_VENTAS && r[0] > 65) || (currentDir != DIR_COMPRAS && r[0] < 35)) coolingEndTime = 0;
   }

   if(count > 0) {
      if(count >= eff_MaxPos) { DeleteBotPendings(); return; }
      ENUM_POSITION_TYPE type = GetMainPositionType();
      double net = GetCurrentNetProfit(), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK), bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      
      ulong t_ref = GetPendingTicketByComment("REF_U");
      double dRef = USDtoPrice(eff_HarvestTP * 0.5, LoteManual); 
      if(net > (eff_HarvestTP * 0.4)) {
         if(t_ref == 0) (type==POSITION_TYPE_BUY) ? trade.BuyStop(LoteManual, ask+dRef, _Symbol, 0, 0, 0, 0, "REF_U") : trade.SellStop(LoteManual, bid-dRef, _Symbol, 0, 0, 0, 0, "REF_U");
         else { // Chase
            if(OrderSelect(t_ref)) {
               double p_ref = OrderGetDouble(ORDER_PRICE_OPEN);
               if(type==POSITION_TYPE_BUY && ask+dRef < p_ref - USDtoPrice(1.0, LoteManual)) trade.OrderModify(t_ref, ask+dRef, 0, 0, ORDER_TIME_GTC, 0, 0);
               if(type==POSITION_TYPE_SELL && bid-dRef > p_ref + USDtoPrice(1.0, LoteManual)) trade.OrderModify(t_ref, bid-dRef, 0, 0, ORDER_TIME_GTC, 0, 0);
            }
         }
      } else if(t_ref != 0) trade.OrderDelete(t_ref);

      ulong t_res = GetPendingTicketByComment("RES_U");
      if(net < -eff_DistResTrigger && ActivarRescate) {
         double dRes = USDtoPrice(5.0 * scale, LoteManual);
         if(t_res == 0) (type==POSITION_TYPE_BUY) ? trade.SellStop(NormalizeLot(LoteManual*MultiplicadorLote), bid-dRes, _Symbol, 0, 0, 0, 0, "RES_U") : trade.BuyStop(NormalizeLot(LoteManual*MultiplicadorLote), ask+dRes, _Symbol, 0, 0, 0, 0, "RES_U");
      }
   } else {
      if(CountPendings(ORDER_TYPE_BUY_STOP) + CountPendings(ORDER_TYPE_SELL_STOP) == 0 && TimeCurrent() >= coolingEndTime) {
         double d = USDtoPrice(eff_Entrada / scale, LoteManual);
         if(currentDir != DIR_VENTAS) trade.BuyStop(LoteManual, SymbolInfoDouble(_Symbol, SYMBOL_ASK)+d, _Symbol, 0, 0, 0, 0, "G_BUY");
         if(currentDir != DIR_COMPRAS) trade.SellStop(LoteManual, SymbolInfoDouble(_Symbol, SYMBOL_BID)-d, _Symbol, 0, 0, 0, 0, "G_SELL");
      }
   }
}

//--- HELPERS ---
double USDtoPrice(double usd, double lot) {
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE), ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tv <= 0 || lot <= 0) return 100*_Point;
   return (usd * ts) / (tv * lot);
}
double GetDailyProfit() {
   HistorySelect(iTime(_Symbol, PERIOD_D1, 0), TimeCurrent());
   double p=0; for(int i=HistoryDealsTotal()-1; i>=0; i--) {
      ulong t = HistoryDealGetTicket(i); if(HistoryDealGetInteger(t, DEAL_MAGIC)==MagicNumber) p += HistoryDealGetDouble(t, DEAL_PROFIT);
   }
   return p;
}
double GetCurrentNetProfit() {
   double p=0; for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic()==MagicNumber) p += posInfo.Profit() + posInfo.Swap();
   return p;
}
int PositionsTotalBots() {
   int c=0; for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==MagicNumber) c++;
   return c;
}
void CloseAllBotPositions() { for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic()==MagicNumber) trade.PositionClose(posInfo.Ticket()); }
void DeleteBotPendings() { for(int i=OrdersTotal()-1; i>=0; i--) if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC)==MagicNumber) trade.OrderDelete(OrderGetTicket(i)); }
ENUM_POSITION_TYPE GetMainPositionType() {
   for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==MagicNumber) return (ENUM_POSITION_TYPE)posInfo.PositionType();
   return POSITION_TYPE_BUY;
}
int CountPendings(ENUM_ORDER_TYPE t) {
   int c=0; for(int i=0; i<OrdersTotal(); i++) if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC)==MagicNumber && OrderGetInteger(ORDER_TYPE)==t) c++;
   return c;
}
ulong GetPendingTicketByComment(string c) {
   for(int i=0; i<OrdersTotal(); i++) { ulong t=OrderGetTicket(i); if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC)==MagicNumber && OrderGetString(ORDER_COMMENT)==c) return t; }
   return 0;
}
double NormalizeLot(double l) {
   double min=SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), step=SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double res=MathFloor(l/step)*step; return (res<min)?min:res;
}

//--- PANEL & SYNC ---
void OnTimer() { if(PurchaseID!="" && TimeCurrent()-lastRemoteSync>=30) { CheckRemoteCommands(); SyncPositions(); lastRemoteSync=TimeCurrent(); } }
void CheckRemoteCommands() {
    string url = "https://www.kopytrading.com/api/remote-control?purchaseId="+PurchaseID+"&account="+IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN));
    char post[], res[]; string head;
    if(WebRequest("GET",url,head,2000,post,res,head)==200) {
        string r = CharArrayToString(res);
        if(StringFind(r,"\"command\":\"PAUSE\"")!=-1) remotePaused=true;
        if(StringFind(r,"\"command\":\"RESUME\"")!=-1) remotePaused=false;
        if(StringFind(r,"\"command\":\"CLOSE_ALL\"")!=-1) CloseAllBotPositions();
        if(StringFind(r,"\"command\":\"CHANGE_MODE\"")!=-1) { currentMode=(StringFind(r,"\"value\":\"ZEN\"")!=-1)?MODE_ZEN:MODE_COSECHA; UpdateEffectiveParams(); }
        if(StringFind(r,"\"command\":\"DIRECTION\"")!=-1) {
            if(StringFind(r,"\"value\":\"BUY\"")!=-1) currentDir=DIR_COMPRAS; else if(StringFind(r,"\"value\":\"SELL\"")!=-1) currentDir=DIR_VENTAS; else currentDir=DIR_AMBAS;
        }
        CrearPanel();
    }
}

void SyncPositions() {
    if(PurchaseID=="") return; if(TimeCurrent()<lastPositionsSync+30) return; lastPositionsSync=TimeCurrent();
    string posJ="", histJ=""; int c=0;
    for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==MagicNumber) {
        if(c>0) posJ+=",";
        posJ+="{\"ticket\":\""+IntegerToString((long)posInfo.Ticket())+"\",\"type\":\""+(posInfo.PositionType()==POSITION_TYPE_BUY?"BUY":"SELL")+"\",\"symbol\":\""+posInfo.Symbol()+"\",\"lots\":"+DoubleToString(posInfo.Volume(),2)+",\"profit\":"+DoubleToString(posInfo.Profit()+posInfo.Swap(),2)+"}";
        c++;
    }
    HistorySelect(iTime(_Symbol,PERIOD_D1,0),TimeCurrent()); int hc=0;
    for(int i=HistoryDealsTotal()-1; i>=0; i--) {
        ulong t=HistoryDealGetTicket(i); if(HistoryDealGetInteger(t,DEAL_MAGIC)==MagicNumber && HistoryDealGetDouble(t,DEAL_PROFIT)!=0) {
            if(hc>0) histJ+=",";
            histJ+="{\"ticket\":\""+IntegerToString((long)t)+"\",\"type\":\""+(HistoryDealGetInteger(t,DEAL_TYPE)==DEAL_TYPE_BUY?"BUY":"SELL")+"\",\"symbol\":\""+HistoryDealGetString(t,DEAL_SYMBOL)+"\",\"profit\":"+DoubleToString(HistoryDealGetDouble(t,DEAL_PROFIT),2)+"}";
            hc++; if(hc>=10) break;
        }
    }
    bool isR=(AccountInfoInteger(ACCOUNT_TRADE_MODE)==ACCOUNT_TRADE_MODE_REAL);
    string postD="{\"purchaseId\":\""+PurchaseID+"\",\"account\":\""+IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN))+"\",\"isReal\":"+(isR?"true":"false")+",\"version\":\"7.20\",\"positions\":["+posJ+"],\"history\":["+histJ+"]}";
    char post[], result[]; string h="Content-Type: application/json\r\n";
    StringToCharArray(postD,post,0,StringLen(postD),CP_UTF8);
    WebRequest("POST","https://www.kopytrading.com/api/sync-positions",h,3000,post,result,h);
}

void CrearPanel() {
   ObjectsDeleteAll(0, PNL);
   int x=15, y=15, w=290, h=350;
   if(isMinimized) { w=200; h=60; }
   CrRect("bg",x,y,w,h,CLR_BG,CLR_BRD,2);
   CrRect("hdr",x+2,y+2,w-4,40,CLR_HDR,CLR_HDR);
   CrLabel("ttl",x+15,y+8,"BTC EVOLUTION UNIVERSAL",clrWhite,10,"Arial Bold");
   CrLabel("sub",x+15,y+25,"v7.2 - kopytrading.com",CLR_MUTED,7);
   CrBtn("min",x+w-25,y+10,18,18,isMinimized?"+":"-",CLR_HDR,clrWhite);
   if(!isMinimized) {
      CrLabel("li",x+15,y+55,"LIC: "+LicenseKey,CLR_WARN,8,"Arial Bold");
      CrLabel("pL",x+15,y+80,"PnL HOY:",CLR_MUTED,8);
      double p=GetDailyProfit();
      CrLabel("pV",x+100,y+80,DoubleToString(p/scale,2)+(scale>1?" USC":" $"),p>=0?CLR_SUCCESS:CLR_DANGER,10,"Arial Bold");
      CrLabel("stL",x+15,y+105,"ESTADO:",CLR_MUTED,8); CrLabel("stV",x+100,y+105,botStatus,CLR_SUCCESS,9);
      CrLabel("moL",x+15,y+130,"MODO:",CLR_MUTED,8); CrLabel("moV",x+100,y+130,currentMode==MODE_ZEN?"ZEN":"COSECHA",CLR_ACCENT,8,"Arial Bold");
      
      CrBtn("b_zen",x+10,y+180,85,25,"ZEN",currentMode==MODE_ZEN?CLR_ACCENT:C'35,35,65',clrWhite);
      CrBtn("b_har",x+100,y+180,85,25,"COSECHA",currentMode==MODE_COSECHA?C'200,80,40':C'35,35,65',clrWhite);
      CrBtn("b_both",x+190,y+180,85,25,"AMBAS",currentDir==DIR_AMBAS?CLR_ACCENT:C'35,35,65',clrWhite);
      CrBtn("b_close",x+10,y+215,265,30,"CLOSE ALL BTC POSITIONS",CLR_DANGER,clrWhite);
      
      string aT=(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE)<0.01)?"REAL (CENT)":"REAL (USD)";
      if(AccountInfoInteger(ACCOUNT_TRADE_MODE)==ACCOUNT_TRADE_MODE_DEMO) aT="DEMO Account";
      CrLabel("acc",x+15,y+265,"TIPO: "+aT,CLR_MUTED,8);
      CrLabel("sca",x+15,y+285,"ESCALADO AUTO: "+(scale>1?"SÍ":"NO"),CLR_TXT,8);
      CrLabel("rem",x+15,y+310,"REMOTO: "+(remotePaused?"🔴 PAUSA":"🟢 ONLINE"),remotePaused?CLR_DANGER:CLR_SUCCESS,8);
   }
   ChartRedraw(0);
}
void ActualizarPanel() { if(!isMinimized) { double p=GetDailyProfit(); ObjectSetString(0,PNL+"pV",OBJPROP_TEXT,DoubleToString(p/scale,2)+(scale>1?" USC":" $")); ObjectSetInteger(0,PNL+"pV",OBJPROP_COLOR,p>=0?CLR_SUCCESS:CLR_DANGER); ObjectSetString(0,PNL+"stV",OBJPROP_TEXT,botStatus); } ChartRedraw(0); }
void OnChartEvent(const int id,const long &lp,const double &dp,const string &sp) {
   if(id!=CHARTEVENT_OBJECT_CLICK) return;
   if(sp==PNL+"min") { isMinimized=!isMinimized; CrearPanel(); }
   if(sp==PNL+"b_zen") { currentMode=MODE_ZEN; UpdateEffectiveParams(); CrearPanel(); }
   if(sp==PNL+"b_har") { currentMode=MODE_COSECHA; UpdateEffectiveParams(); CrearPanel(); }
   if(sp==PNL+"b_both") { currentDir=DIR_AMBAS; CrearPanel(); }
   if(sp==PNL+"b_close") CloseAllBotPositions();
   ObjectSetInteger(0,sp,OBJPROP_STATE,false);
}
void CrRect(string n,int x,int y,int w,int h,color bg,color bd,int bw=1) { ObjectCreate(0,PNL+n,OBJ_RECTANGLE_LABEL,0,0,0); ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h); ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,bd); ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,100); }
void CrLabel(string n,int x,int y,string t,color c,int s,string f="Segoe UI") { ObjectCreate(0,PNL+n,OBJ_LABEL,0,0,0); ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y); ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,c); ObjectSetInteger(0,PNL+n,OBJPROP_FONTSIZE,s); ObjectSetString(0,PNL+n,OBJPROP_FONT,f); ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,101); }
void CrBtn(string n,int x,int y,int w,int h,string t,color bg,color tc) { ObjectCreate(0,PNL+n,OBJ_BUTTON,0,0,0); ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h); ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,tc); ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,102); }

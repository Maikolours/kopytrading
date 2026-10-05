//+------------------------------------------------------------------+
//|     KOPYTRADE_XAUUSD_Evolution_Universal_v6_10 - AMETRALLADORA   |
//|   PRO - AUTOMATIC SCALING, SMART RESCUE, EMA/RSI FILTERS         |
//|   kopytrading.com - Phase 3 Stable                              |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "6.10"
#property strict
#property description "AMETRALLADORA PRO | Auto-Cent | EMA+RSI | Smart Rescue"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- HELPER: CustomBarShift for MQL5 ---
int CustomBarShift(string symbol, ENUM_TIMEFRAMES timeframe, datetime time, bool exact=false) {
   datetime times[1];
   if(CopyTime(symbol, timeframe, 0, 1, times) <= 0) return -1;
   datetime last_bar = times[0];
   if(time > last_bar) return 0;
   
   datetime history_times[];
   int count = CopyTime(symbol, timeframe, 0, 1000, history_times);
   if(count <= 0) return -1;
   
   for(int i = 0; i < count; i++) {
      if(history_times[count-1-i] <= time) return i;
   }
   return -1;
}

//--- GENERADOR DE HASH PARA MAGIC NUMBER AUTOMATICO ---
uint GetHash(string text) {
   uint hash = 5381;
   for(int i = 0; i < StringLen(text); i++) hash = ((hash << 5) + hash) + text[i];
   return hash & 0x7FFFFFFF;
}

//--- DECLARACIONES DE FUNCIONES VISUALES ---
void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bw=1);
void CrLabel(string n, int x, int y, string t, color c, int s=9, string f="Segoe UI");
void CrBtn(string n, int x, int y, int w, int h, string t, color bg, color tc);

enum ENUM_DIR  { DIR_COMPRAS, DIR_VENTAS, DIR_AMBAS };
enum ENUM_MODE { MODE_ZEN, MODE_COSECHA };

//============================================================
//  LICENCIA & SEGURIDAD
//============================================================
sinput string separator0 = "=========================="; // === LICENCIA & SEGURIDAD ===
input string   LicenseKey        = "TRIAL-2026";
input string   PurchaseID        = "";         // ID de Vínculo (kopytrading.com/dashboard)
input bool     ForceCentMode     = false;      // manual override for Cent mode

//============================================================
//  GESTIÓN DE RIESGO
//============================================================
sinput string separator1 = "=========================="; // === FILTRO DE NOTICIAS USD ===
input bool     FiltroNoticias       = true; // Activar pausa por noticias?
input int      MinutosAntes         = 30;   // Minutos antes de noticia
input int      MinutosDespues       = 30;   // Minutos despues de noticia

sinput string separator2 = "=========================="; // === CONFIGURACIÓN INTERNA ===
input ENUM_MODE ModePreset        = MODE_COSECHA; // 🎨 Modo del Bot (Zen/Cosecha)
input int      MagicNumber        = 610610;       // Magic Number
input int      MaxPosiciones      = 3;            // 📈 Máximo de posiciones abiertas (Bot)
input double   LoteManual         = 0.02;         // Lote Principal
input double   MaxDrawdown_USD    = 5.0;          // 🛑 Stop de Emergencia Cuenta (en USD reales)
input double   Max_DD_Individual_USD = 1.0;       // 🛑 Stop por Operación (en USD reales)
input int      Max_Velas_Vida     = 0;            // ⏳ Vida máxima en velas (0 = Desact.)

//============================================================
//  RESCATE MATEMÁTICO (AMETRALLADORA)
//============================================================
sinput string separator3 = "=========================="; // === RESCATE PRO (PROTECCIÓN) ===
input bool     ActivarRescate     = true;         // 🚑 Activar Operación de Rescate
input double   GatilloRescate_USD = 5.0;          // $ Pérdida para activar gatillo (en USD!)
input double   MultiplicadorRes   = 1.5;          // Multiplicador lote rescate
input double   Rescue_TP_USD      = 2.0;          // Target para salir de rescate (en USD!)
input double   MaxLoteRescate     = 0.15;         // 🛡️ Lote máximo permitido en rescate

//============================================================
//  METAS & CORTAFUEGOS (USD REALES)
//============================================================
sinput string separator4 = "=========================="; // === METAS (USD REALES) ===
input double   MetaDiaria_USD      = 10.0;        // 🎯 Ganancia Diaria
input double   Meta_Ciclo_USD      = 5.0;         // Neto para cerrar ciclo (Basket TP)
input double   Harvest_TP_USD      = 1.0;         // TP individual (Operación única)

//============================================================
//  BREAK EVEN & TRAILING
//============================================================
sinput string separator5 = "=========================="; // === BREAK EVEN & TRAILING ===
input bool     ActivarBE           = true;        // 🛡️ Activar Break Even
input double   BE_Trigger_USD      = 2.0;         // Activar BE tras ganar X USD
input bool     ActivarTrailing     = true;        // 🚀 Activar Trailing Stop
input int      TrailingPoints      = 1500;        // Puntos de Trailing (15 pips gold)
input int      TrailingStep        = 500;         // Paso de Trailing (5 pips gold)

//============================================================
//  ESTRATEGIA & FILTROS
//============================================================
sinput string separator6 = "=========================="; // === ESTRATEGIA (EMA + RSI) ===
input int      EMA_Fast            = 20;
input int      EMA_Slow            = 50;
input int      RSI_Period          = 14;
input int      DistanciaGates      = 150;         // Distancia entrada (en puntos)
input int      CooldownSeconds     = 60;       
input bool     EnableTimeFilter    = true;        // ⏰ Activar filtro de horario
input int      StartHour1          = 9;        
input int      EndHour1            = 17;       
input int      StartHour2          = 17;       
input int      EndHour2            = 22;       

//--- Variables internas ---
CTrade         trade;
CPositionInfo  posInfo;
int            activeMagic;
int            h_ema20, h_ema50, h_rsi;
datetime       lastRemoteSync = 0, coolingEndTime = 0, lastPositionsSync = 0;
ENUM_DIR       currentDir = DIR_AMBAS;
ENUM_MODE      currentMode = MODE_COSECHA;
string         botStatus = "LISTO";
bool           isMinimized = false, remotePaused = false, noticiaActiva = false;
double         profitFactor = 1.0; // 1.0 = USD, 0.01 = CENT

#define PNL "AEVO_U_61"

//-- COLORES --
color CLR_BG      = C'10,10,25'; color CLR_HDR = C'40,30,80'; color CLR_BRD = C'80,60,180';
color CLR_TXT  = clrWhite; color CLR_MUTED = C'130,130,170'; color CLR_SUCCESS = C'40,200,90';
color CLR_DANGER = C'210,50,50'; color CLR_WARN = C'210,170,40'; color CLR_ACCENT = C'60,100,220';

int OnInit() {
   activeMagic = MagicNumber;
   if(activeMagic == 0) activeMagic = (int)GetHash(_Symbol + IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN)));
   trade.SetExpertMagicNumber(activeMagic);
   
   // --- AUTO-CENT DETECTION ---
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if((tv < 0.1 && AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL) || ForceCentMode) {
      profitFactor = 0.01; Print("MODO CENT DETECTADO (Factor 0.01)");
   } else {
      profitFactor = 1.0; Print("MODO USD DETECTADO (Factor 1.0)");
   }

   h_ema20 = iMA(_Symbol, _Period, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
   h_ema50 = iMA(_Symbol, _Period, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
   h_rsi   = iRSI(_Symbol, _Period, RSI_Period, PRICE_CLOSE);
   
   if(h_ema20 == INVALID_HANDLE || h_ema50 == INVALID_HANDLE || h_rsi == INVALID_HANDLE) return(INIT_FAILED);
   
   ChartIndicatorAdd(0, 0, h_ema20);
   ChartIndicatorAdd(0, 0, h_ema50);
   ChartIndicatorAdd(0, 1, h_rsi);
   
   CrearPanel(); 
   SyncPositions();
   remotePaused = false; // Reset security pause on start
   EventSetTimer(3); 
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) { 
   ObjectsDeleteAll(0, PNL); 
   IndicatorRelease(h_ema20); IndicatorRelease(h_ema50); IndicatorRelease(h_rsi);
}

void OnTick() {
   SyncPositions(); // Always listen, even if paused
   double dailyProfit = GetDailyProfitUSD();
   double netUSD = GetCurrentNetProfitUSD();
   
   if(remotePaused) { botStatus = "🔴 PAUSA REMOTA"; DeleteBotPendings(); ActualizarPanel(); return; }
   
   if(MetaDiaria_USD > 0 && dailyProfit >= MetaDiaria_USD) {
      if(PositionsTotalBots() == 0) { botStatus = "META ALCANZADA"; DeleteBotPendings(); ActualizarPanel(); return; }
      if(netUSD >= 0) { CloseAllBotPositions(); DeleteBotPendings(); botStatus = "META ALCANZADA"; ActualizarPanel(); return; }
      else botStatus = "META (LIMPIANDO)";
   }

   noticiaActiva = HayNoticia();
   if(noticiaActiva || !IsTradingTime() || TimeCurrent() < coolingEndTime) {
      botStatus = noticiaActiva ? "ALERTA NOTICIA" : (TimeCurrent() < coolingEndTime ? "ENFRIANDO" : "FUERA DE HORARIO");
      ManageOpenPositions(); DeleteBotPendings(); ActualizarPanel(); SyncPositions(); return;
   }

   ManageOpenPositions();
   MaintainGates();
   ActualizarPanel();
}

void ManageOpenPositions() {
    double netUSD = GetCurrentNetProfitUSD();
    int count = PositionsTotalBots();

    if(MaxDrawdown_USD > 0 && netUSD <= -MaxDrawdown_USD) {
       CloseAllBotPositions(); botStatus = "🛑 STOP EMERGENCIA"; remotePaused = true; return;
    }

    if(count >= 2 && netUSD >= Meta_Ciclo_USD) {
       CloseAllBotPositions(); coolingEndTime = TimeCurrent() + CooldownSeconds; return;
    }
    
    static datetime lastRescueCloseTime = 0;
    bool rescueOrderSent = false;
    for(int i=PositionsTotal()-1; i>=0; i--) {
       if(posInfo.SelectByIndex(i) && posInfo.Magic() == activeMagic) {
          double pUSD = GetProfitUSD(posInfo.Profit() + posInfo.Commission() + posInfo.Swap());
          int shift = CustomBarShift(_Symbol, _Period, (datetime)posInfo.Time());
          
          if(pUSD <= -Max_DD_Individual_USD) { trade.PositionClose(posInfo.Ticket()); continue; }
          if(Max_Velas_Vida > 0 && shift >= Max_Velas_Vida) { trade.PositionClose(posInfo.Ticket()); continue; }
          
          double target = (posInfo.Comment() == "RESCATE_P") ? Rescue_TP_USD : Harvest_TP_USD;
          if(pUSD >= target) { 
             if(posInfo.Comment() == "RESCATE_P") lastRescueCloseTime = TimeCurrent();
             trade.PositionClose(posInfo.Ticket()); continue; 
          }

          if(ActivarBE && pUSD >= BE_Trigger_USD) {
             double open = posInfo.PriceOpen(), bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK), sl = posInfo.StopLoss();
             if(posInfo.PositionType()==POSITION_TYPE_BUY) {
                double nBE = open + (2*_Point);
                if(bid-nBE > 100*_Point && (sl < nBE || sl == 0)) trade.PositionModify(posInfo.Ticket(), NormalizeDouble(nBE, _Digits), posInfo.TakeProfit());
                if(ActivarTrailing && bid-nBE > TrailingPoints*_Point) {
                   double ts = bid - TrailingPoints*_Point;
                   if(ts > sl + TrailingStep*_Point || sl == 0) trade.PositionModify(posInfo.Ticket(), NormalizeDouble(ts, _Digits), posInfo.TakeProfit());
                }
             } else {
                double nBE = open - (2*_Point);
                if(nBE-ask > 100*_Point && (sl > nBE || sl == 0)) trade.PositionModify(posInfo.Ticket(), NormalizeDouble(nBE, _Digits), posInfo.TakeProfit());
                if(ActivarTrailing && nBE-ask > TrailingPoints*_Point) {
                   double ts = ask + TrailingPoints*_Point;
                   if(ts < sl - TrailingStep*_Point || sl == 0) trade.PositionModify(posInfo.Ticket(), NormalizeDouble(ts, _Digits), posInfo.TakeProfit());
                }
             }
          }
          
           // --- PHASE 3: SMART CLUSTER RESCUE (Fixing Over-activation & Flicker) ---
           if(ActivarRescate && !rescueOrderSent && TimeCurrent() > lastRescueCloseTime + 30 && pUSD < 0 && MathAbs(pUSD) >= GatilloRescate_USD && posInfo.Comment() != "RESCATE_P") {
              bool rescueExists = false;
              for(int j=0; j<PositionsTotal(); j++) {
                 if(posInfo.SelectByIndex(j) && posInfo.Magic()==activeMagic && posInfo.Comment()=="RESCATE_P") {
                    rescueExists=true; break;
                 }
              }
              
              if(!rescueExists && PositionsTotalBots() < (MaxPosiciones + 1)) {
                 double resLot = NormalizeDouble(posInfo.Volume() * MultiplicadorRes, 2);
                 if(resLot > MaxLoteRescate) resLot = MaxLoteRescate;
                 
                 double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                 if(posInfo.PositionType() == POSITION_TYPE_BUY) {
                    if(trade.Sell(resLot, _Symbol, bid, 0, 0, "RESCATE_P")) rescueOrderSent = true;
                 } else {
                    if(trade.Buy(resLot, _Symbol, ask, 0, 0, "RESCATE_P")) rescueOrderSent = true;
                 }
              }
           }
       }
    }
}

void MaintainGates() {
   int count = PositionsTotalBots();
   bool buyAllowed = (currentDir != DIR_VENTAS), sellAllowed = (currentDir != DIR_COMPRAS);
   
   // TREND FILTER (EMA + RSI)
   double e20[], e50[], rsi[];
   if(CopyBuffer(h_ema20,0,0,1,e20)>0 && CopyBuffer(h_ema50,0,0,1,e50)>0 && CopyBuffer(h_rsi,0,0,1,rsi)>0) {
      if(e20[0] < e50[0] || rsi[0] < 50) buyAllowed = false;
      if(e20[0] > e50[0] || rsi[0] > 50) sellAllowed = false;
   }

   if(count == 0) {
      if(CountPendings(ORDER_TYPE_BUY_STOP) + CountPendings(ORDER_TYPE_SELL_STOP) == 0) {
         double d = DistanciaGates * _Point;
         if(buyAllowed) trade.BuyStop(LoteManual, SymbolInfoDouble(_Symbol, SYMBOL_ASK)+d, _Symbol, 0, 0, 0, 0, "G_BUY");
         if(sellAllowed) trade.SellStop(LoteManual, SymbolInfoDouble(_Symbol, SYMBOL_BID)-d, _Symbol, 0, 0, 0, 0, "G_SELL");
      }
   } else if(count < MaxPosiciones) {
      // CHASE LOGIC for Gates
      ulong t_buy = GetPendingTicketByComment("G_BUY");
      ulong t_sell = GetPendingTicketByComment("G_SELL");
      double d = DistanciaGates * _Point;
      if(t_buy != 0) {
         double p = SymbolInfoDouble(_Symbol, SYMBOL_ASK)+d;
         if(MathAbs(OrderGetDouble(ORDER_PRICE_OPEN)-p) > 100*_Point) trade.OrderModify(t_buy, NormalizeDouble(p, _Digits), 0, 0, ORDER_TIME_GTC, 0, 0);
      }
      if(t_sell != 0) {
         double p = SymbolInfoDouble(_Symbol, SYMBOL_BID)-d;
         if(MathAbs(OrderGetDouble(ORDER_PRICE_OPEN)-p) > 100*_Point) trade.OrderModify(t_sell, NormalizeDouble(p, _Digits), 0, 0, ORDER_TIME_GTC, 0, 0);
      }
   }
}

//--- DATA HELPERS ---
double GetProfitUSD(double accProfit) { return accProfit * profitFactor; }
double GetDailyProfitUSD() {
   HistorySelect(iTime(_Symbol, PERIOD_D1, 0), TimeCurrent());
   double p=0; for(int i=HistoryDealsTotal()-1; i>=0; i--) {
      ulong t = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(t, DEAL_MAGIC) == activeMagic) p += HistoryDealGetDouble(t, DEAL_PROFIT);
   }
   return GetProfitUSD(p);
}
double GetCurrentNetProfitUSD() {
   double p=0; for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) p += posInfo.Profit() + posInfo.Swap();
   return GetProfitUSD(p);
}
int PositionsTotalBots() { int c=0; for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) c++; return c; }
void CloseAllBotPositions() { for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) trade.PositionClose(posInfo.Ticket()); }
void DeleteBotPendings() { for(int i=OrdersTotal()-1; i>=0; i--) if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC)==activeMagic) trade.OrderDelete(OrderGetTicket(i)); }
int CountPendings(ENUM_ORDER_TYPE type) { int c=0; for(int i=0; i<OrdersTotal(); i++) if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC)==activeMagic && OrderGetInteger(ORDER_TYPE)==type) c++; return c; }
ulong GetPendingTicketByComment(string cmnt) { for(int i=0; i<OrdersTotal(); i++) { ulong t=OrderGetTicket(i); if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC)==activeMagic && OrderGetString(ORDER_COMMENT)==cmnt) return t; } return 0; }
bool IsTradingTime() { MqlDateTime dt; TimeToStruct(TimeCurrent(), dt); return (!EnableTimeFilter || (dt.hour >= StartHour1 && dt.hour < EndHour2)); }
bool HayNoticia() { 
   if(!FiltroNoticias) return false;
   MqlCalendarValue vals[];
   if(CalendarValueHistory(vals, TimeCurrent()-MinutosDespues*60, TimeCurrent()+MinutosAntes*60, "USD") > 0) {
      for(int i=0; i<ArraySize(vals); i++) {
         MqlCalendarEvent ev; if(CalendarEventById(vals[i].event_id, ev) && ev.importance == CALENDAR_IMPORTANCE_HIGH) return true;
      }
   }
   return false;
}

//--- UI ---
void CrearPanel() {
   ObjectsDeleteAll(0, PNL);
   int x=15, y=15, w=290, h=340;
   if(isMinimized) { w=200; h=60; }
   CrRect("bg",x,y,w,h,CLR_BG,CLR_BRD,2);
   CrRect("hdr",x+2,y+2,w-4,40,CLR_HDR,CLR_HDR);
   CrLabel("ttl",x+15,y+8,"AMETRALLADORA PRO v6.1",clrWhite,10,"Arial Bold");
   CrLabel("sub",x+15,y+25,"kopytrading.com",CLR_MUTED,7);
   CrBtn("min",x+w-25,y+10,18,18,isMinimized?"+":"-",CLR_HDR,clrWhite);
   if(!isMinimized) {
      CrLabel("li",x+15,y+55,"LIC: "+LicenseKey,CLR_WARN,8,"Arial Bold");
      CrLabel("pL",x+15,y+80,"PnL HOY (USD):",CLR_MUTED,8);
      double p=GetDailyProfitUSD(); CrLabel("pV",x+120,y+80,DoubleToString(p,2)+" $",p>=0?CLR_SUCCESS:CLR_DANGER,10,"Arial Bold");
      CrLabel("stL",x+15,y+105,"ESTADO:",CLR_MUTED,8); CrLabel("stV",x+120,y+105,botStatus,CLR_SUCCESS,9);
      CrLabel("moL",x+15,y+130,"MODO:",CLR_MUTED,8); CrLabel("moV",x+120,y+130,currentMode==MODE_ZEN?"ZEN":"COSECHA",CLR_ACCENT,8,"Arial Bold");
      CrLabel("fL",x+15,y+155,"FLOTANTE (USD):",CLR_MUTED,8);
      double f=GetCurrentNetProfitUSD(); CrLabel("fV",x+120,y+155,DoubleToString(f,2)+" $",f>=0?CLR_SUCCESS:CLR_DANGER,9);
      
      CrBtn("b_zen",x+10,y+190,85,25,"ZEN",currentMode==MODE_ZEN?CLR_ACCENT:C'35,35,65',clrWhite);
      CrBtn("b_har",x+100,y+190,85,25,"COSECHA",currentMode==MODE_COSECHA?C'200,80,40':C'35,35,65',clrWhite);
      CrBtn("b_both",x+190,y+190,85,25,"AMBAS",currentDir==DIR_AMBAS?CLR_ACCENT:C'35,35,65',clrWhite);
      CrBtn("b_close",x+10,y+225,265,30,"FECHAR TUDO",CLR_DANGER,clrWhite);
      
      string aT=(profitFactor<1.0)?"REAL CENT":"REAL USD";
      if(AccountInfoInteger(ACCOUNT_TRADE_MODE)==ACCOUNT_TRADE_MODE_DEMO) aT="DEMO Account";
      CrLabel("acc",x+15,y+270,"CONTA: "+aT,CLR_MUTED,8);
      CrLabel("sca",x+15,y+290,"AUTO-SCALING: ACTIVADO",CLR_TXT,8);
      CrLabel("rem",x+15,y+310,"REMOTO: "+(remotePaused?"🔴 PAUSA":"🟢 ONLINE"),remotePaused?CLR_DANGER:CLR_SUCCESS,8);
   }
   ChartRedraw(0);
}
void ActualizarPanel() {
   if(!isMinimized) {
      double p=GetDailyProfitUSD(); ObjectSetString(0,PNL+"pV",OBJPROP_TEXT,DoubleToString(p,2)+" $");
      ObjectSetInteger(0,PNL+"pV",OBJPROP_COLOR,p>=0?CLR_SUCCESS:CLR_DANGER);
      ObjectSetString(0,PNL+"stV",OBJPROP_TEXT,botStatus);
      double f=GetCurrentNetProfitUSD(); ObjectSetString(0,PNL+"fV",OBJPROP_TEXT,DoubleToString(f,2)+" $");
      ObjectSetInteger(0,PNL+"fV",OBJPROP_COLOR,f>=0?CLR_SUCCESS:CLR_DANGER);
   }
   ChartRedraw(0);
}
void OnChartEvent(const int id,const long &lp,const double &dp,const string &sp) {
   if(id!=CHARTEVENT_OBJECT_CLICK) return;
   if(sp==PNL+"min") { isMinimized=!isMinimized; CrearPanel(); }
   if(sp==PNL+"b_zen") { currentMode=MODE_ZEN; CrearPanel(); }
   if(sp==PNL+"b_har") { currentMode=MODE_COSECHA; CrearPanel(); }
   if(sp==PNL+"b_both") { currentDir=DIR_AMBAS; CrearPanel(); }
   if(sp==PNL+"b_close") CloseAllBotPositions();
   ObjectSetInteger(0,sp,OBJPROP_STATE,false);
}
void CrRect(string n,int x,int y,int w,int h,color bg,color bd,int bw=1) { ObjectCreate(0,PNL+n,OBJ_RECTANGLE_LABEL,0,0,0); ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h); ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,bd); ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,100); }
void CrLabel(string n,int x,int y,string t,color c,int s,string f="Segoe UI") { ObjectCreate(0,PNL+n,OBJ_LABEL,0,0,0); ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y); ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,c); ObjectSetInteger(0,PNL+n,OBJPROP_FONTSIZE,s); ObjectSetString(0,PNL+n,OBJPROP_FONT,f); ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,101); }
void CrBtn(string n,int x,int y,int w,int h,string t,color bg,color tc) { ObjectCreate(0,PNL+n,OBJ_BUTTON,0,0,0); ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h); ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,tc); ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,102); }

void SyncPositions() {
    if(PurchaseID=="") return; if(TimeCurrent()<lastPositionsSync+30) return; lastPositionsSync=TimeCurrent();
    bool isR=(AccountInfoInteger(ACCOUNT_TRADE_MODE)==ACCOUNT_TRADE_MODE_REAL);
    string postD="{\"purchaseId\":\""+PurchaseID+"\",\"account\":\""+IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN))+"\",\"isReal\":"+(isR?"true":"false")+",\"version\":\"6.10\",\"status\":\""+botStatus+"\"}";
    char post[], res[]; string rHead;
    StringToCharArray(postD,post,0,StringLen(postD),CP_UTF8);
    string head="Content-Type: application/json\r\n";
    if(WebRequest("POST","https://www.kopytrading.com/api/sync-positions",head,3000,post,res,rHead) == 200) {
       string response = CharArrayToString(res, 0, WHOLE_ARRAY, CP_UTF8);
       if(StringFind(response, "\"paused\":true") >= 0) remotePaused = true;
       if(StringFind(response, "\"paused\":false") >= 0) remotePaused = false;
    }
}

//+------------------------------------------------------------------+
//| XAU-MG_v1.1.mq5 - AMETRALLADORA                                  |
//| Bot de alta frecuencia para XAUUSD (Oro)                         |
//| Product Key: XAU-MG                                              |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "1.10"
#property description "AMETRALLADORA - Bot de alta frecuencia para XAUUSD"
#property description "Optimizado para Oro | M15 | Rescate y Trailing"

//--- INCLUIR MÓDULO DE INTEGRACIÓN
#include <Kopytrading_Integration.mqh>

//--- PARÁMETROS DE LICENCIA
sinput string separator_license = "========= LICENCIA =========";
input string PurchaseID = "";        
input string LicenseKey = "XAU-MG";  

//--- PARÁMETROS DEL BOT
sinput string separator_strategy = "======= ESTRATEGIA =========";
input int      MagicNumber        = 700842;
input ENUM_TIMEFRAMES TimeframePrincipal = PERIOD_M15;
input int      MaxPosiciones      = 2;

sinput string separator_risk = "======= RIESGO =========";
input double   LoteManual         = 0.01;
input double   RiskPct            = 0.8;
input double   MaxDrawdownPercent = 20.0;

sinput string separator_hedge = "======= RESCATE (HEDGE) =========";
input double   GatilloHedge_USD   = 12.0;
input double   HedgeMultiplier    = 1.5;
input double   MetaCiclo_USD      = 30.0;
input double   Objetivo_USD       = 15.0;

sinput string separator_trailing = "======= PROTECCIÓN =========";
input bool     ActivarBE          = true;
input double   BE_Trigger_USD     = 4.0;
input bool     ActivarTS          = true;
input double   TS_Activation_USD  = 8.0;
input double   TS_Distance_USD    = 6.0;

sinput string separator_filters = "======= FILTROS =========";
input int      DistanciaEMA_Points = 1200;
input int      RSI_Overbought     = 75;
input int      RSI_Oversold       = 25;
input int      SegundosEspera     = 30;

//--- VARIABLES
string         botName = "AMETRALLADORA";
string         botVersion = "v1.1";
string         botStatusStr = "INICIALIZANDO...";
double         dayPnL = 0;
datetime       lastTradeClose = 0;
int            h_ema20, h_ema50, h_rsi;

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
CTrade         trade;
CPositionInfo  posInfo;

//+------------------------------------------------------------------+
//| Funciones básicas                                                |
//+------------------------------------------------------------------+
double GetPositionProfitUSD(ulong ticket) {
   if(posInfo.SelectByTicket(ticket))
      return posInfo.Profit() + posInfo.Swap() + posInfo.Commission();
   return 0;
}

int GetPositionsCount() {
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic() == MagicNumber)
         count++;
   }
   return count;
}

double GetNetProfitUSD() {
   double net = 0;
   for(int i = 0; i < PositionsTotal(); i++) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic() == MagicNumber)
         net += posInfo.Profit() + posInfo.Swap() + posInfo.Commission();
   }
   return net;
}

double CalculateDayProfitUSD() {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   datetime dayStart = StructToTime(dt);
   HistorySelect(dayStart, TimeCurrent());
   double p = 0;
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--) {
      ulong ticket = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) == MagicNumber)
         p += HistoryDealGetDouble(ticket, DEAL_PROFIT);
   }
   return p;
}

void CloseAll() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic() == MagicNumber)
         trade.PositionClose(posInfo.Ticket());
   }
}

void DeletePendings() {
   for(int i = 0; i < OrdersTotal(); i++) {
      ulong orderTicket = OrderGetTicket(i);
      if(orderTicket > 0) trade.OrderDelete(orderTicket);
   }
}

//+------------------------------------------------------------------+
//| Gestión                                                          |
//+------------------------------------------------------------------+
void ManageTrading() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Magic() != MagicNumber) continue;
      
      ulong ticket = posInfo.Ticket();
      double profitUSD = GetPositionProfitUSD(ticket);
      ENUM_POSITION_TYPE type = posInfo.PositionType();
      double sl = posInfo.StopLoss();
      double openPrice = posInfo.PriceOpen();
      double currentPrice = (type == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      if(profitUSD >= Objetivo_USD) {
         trade.PositionClose(ticket);
         lastTradeClose = TimeCurrent();
         continue;
      }
      
      if(ActivarBE && profitUSD >= BE_Trigger_USD) {
         double bePrice = openPrice + (type == POSITION_TYPE_BUY ? 10 * _Point : -10 * _Point);
         if((type == POSITION_TYPE_BUY && (sl < bePrice || sl == 0)) ||
            (type == POSITION_TYPE_SELL && (sl > bePrice || sl == 0))) {
            trade.PositionModify(ticket, bePrice, 0);
         }
      }
      
      if(ActivarTS && profitUSD >= TS_Activation_USD) {
         double newSL;
         if(type == POSITION_TYPE_BUY) {
            newSL = currentPrice - TS_Distance_USD * 100 * _Point;
            if(newSL > sl) trade.PositionModify(ticket, newSL, 0);
         } else {
            newSL = currentPrice + TS_Distance_USD * 100 * _Point;
            if(newSL < sl || l == 0) trade.PositionModify(ticket, newSL, 0);
         }
      }
   }
}

void CheckEntry() {
   if(GetPositionsCount() >= MaxPosiciones) return;
   if(TimeCurrent() < lastTradeClose + SegundosEspera) return;
   
   double emaF[1], emaS[1], rsi[1];
   if(CopyBuffer(h_ema20, 0, 0, 1, emaF) <= 0 ||
      CopyBuffer(h_ema50, 0, 0, 1, emaS) <= 0 ||
      CopyBuffer(h_rsi, 0, 0, 1, rsi) <= 0) return;
   
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   bool biasUp   = (emaF[0] > emaS[0] && rsi[0] > 50 && rsi[0] < RSI_Overbought);
   bool biasDown = (emaF[0] < emaS[0] && rsi[0] < 50 && rsi[0] > RSI_Oversold);
   
   if(biasUp) {
      trade.Buy(LoteManual, _Symbol, ask, 0, 0, botName);
      lastTradeClose = 0;
   } else if(biasDown) {
      trade.Sell(LoteManual, _Symbol, bid, 0, 0, botName);
      lastTradeClose = 0;
   }
}

void CheckHedge() {
   if(GetPositionsCount() >= MaxPosiciones) return;
   
   ulong mainTicket = 0;
   double mainProfitUSD = 0;
   ENUM_POSITION_TYPE mainType = -1;
   bool hasHedge = false;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Magic() != MagicNumber) continue;
      if(mainTicket == 0) {
         mainTicket = posInfo.Ticket();
         mainType = posInfo.PositionType();
         mainProfitUSD = GetPositionProfitUSD(mainTicket);
      } else {
         if(posInfo.PositionType() != mainType) hasHedge = true;
      }
   }
   
   if(!hasHedge && mainProfitUSD <= -GatilloHedge_USD) {
      double hedgeLot = NormalizeDouble(LoteManual * HedgeMultiplier, 2);
      if(mainType == POSITION_TYPE_BUY) trade.Sell(hedgeLot, _Symbol);
      else trade.Buy(hedgeLot, _Symbol);
   }
}

void MostrarHUD() {
   Comment("\nLicense: " + GetLicenseStatus() + "\nStatus: " + botStatusStr + "\nPNL: " + DoubleToString(dayPnL, 2));
}

int OnInit() {
   if(!ValidateLicense(PurchaseID, LicenseKey, (int)AccountInfoInteger(ACCOUNT_LOGIN))) return INIT_FAILED;
   trade.SetExpertMagicNumber(MagicNumber);
   h_ema20 = iMA(_Symbol, TimeframePrincipal, 20, 0, MODE_EMA, PRICE_CLOSE);
   h_ema50 = iMA(_Symbol, TimeframePrincipal, 50, 0, MODE_EMA, PRICE_CLOSE);
   h_rsi   = iRSI(_Symbol, TimeframePrincipal, 14, PRICE_CLOSE);
   return INIT_SUCCEEDED;
}

void OnTick() {
   GetRemoteStatus();
   if(IsRemotePaused()) {
      botStatusStr = "PAUSED";
      SyncPositions(botStatusStr, dayPnL, GetPositionsCount());
      MostrarHUD();
      return;
   }
   
   ManageTrading();
   if(GetPositionsCount() == 0) { CheckEntry(); CheckHedge(); }
   
   dayPnL = CalculateDayProfitUSD();
   botStatusStr = "ACTIVE";
   SyncPositions(botStatusStr, dayPnL, GetPositionsCount());
   MostrarHUD();
}

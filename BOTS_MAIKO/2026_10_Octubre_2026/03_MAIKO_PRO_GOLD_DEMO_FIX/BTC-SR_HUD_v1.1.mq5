//+------------------------------------------------------------------+
//| BTC-SR_HUD_v1.1.mq5 - STORM RIDER                                |
//| Bot conservador para BTCUSD (Bitcoin)                            |
//| Versión con HUD completo - Botones interactivos - Kopytrade Sync |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "1.10"
#property description "STORM RIDER - Bot conservador para BTCUSD"
#property description "HUD completo | Botones interactivos | Trailing | Hedge | Kopytrade"

//--- INCLUIR MÓDULO DE INTEGRACIÓN (v1.4)
#include <Kopytrading_Integration.mqh>

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- ENUMS
enum ENUM_MODE { MODE_ZEN, MODE_COSECHA };
enum ENUM_DIR  { DIR_AMBAS, DIR_SOLO_COMPRAS, DIR_SOLO_VENTAS };

//--- PARÁMETROS INPUT
sinput string   separator_license = "========= LICENCIA =========";
input string    PurchaseID        = "";
input string    LicenseKey        = "BTC-SR"; // Product Key fijo para validación

sinput string   separator_risk_p  = "======= PROTECCIÓN =======";
input double    user_MaxDrawdownPercent = 15.0;
input bool      user_EnableTimeFilter = true;
input int       user_StartHour1 = 1;
input int       user_EndHour1 = 23;

sinput string   separator_hud     = "======= APARIENCIA =======";
input bool      user_ShowIndicators = true;
input int       user_HUD_DefaultWidth = 380;
input int       user_HUD_DefaultHeight = 720;

//--- PARÁMETROS DE ESTRATEGIA
double   user_MagicNumber        = 700843;
double   user_MaxPosiciones      = 2;
double   user_LoteManual         = 0.01;
double   user_HedgeMultiplier    = 1.5;
double   user_GatilloHedge_USD   = 15.0;
double   user_Target_Individual_USD = 20.0;
double   user_Net_Cycle_USD      = 35.0;
double   user_TS_Distance_USD    = 8.0;
double   user_MaxDistEMA_Points  = 1500;
double   user_BE_Trigger_USD     = 5.0;
double   user_TS_Activation_USD  = 10.0;
int      user_RSI_Overbought     = 75;
int      user_RSI_Oversold       = 25;
int      user_SegundosEspera     = 45;
int      user_TS_Step_Points     = 100;

//--- GLOBALES
CTrade         trade;
CPositionInfo  posInfo;
CSymbolInfo    symInfo;
int            activeMagic, h_ema20, h_ema50, h_rsi;
bool           isMinimized = false;
ENUM_MODE      currentMode;
ENUM_DIR       currentDir;
string         botStatusStr = "TRABAJANDO", commentTag = "BTC_HUD";
double         dayPnL_USD = 0;
datetime       lastSync = 0, coolingEndTime = 0, lastTradeClose = 0;
double         tickSize, tickValue;
double         accountBalanceUSD;
datetime       pnlResetTime = 0;

//--- HUD MÓVIL
int      hud_X = 10, hud_Y = 10, hud_W = 380, hud_H = 720;
bool     dragging = false, resizing = false;
int      dragStartX, dragStartY, resizeStartW, resizeStartH;

//--- RUNTIME
double runtime_LoteManual;
double runtime_HedgeMultiplier;
double runtime_GatilloHedge_USD;
double runtime_Target_Individual_USD;
double runtime_Net_Cycle_USD;
double runtime_TS_Distance_USD;
double runtime_MaxDistEMA_Points;
double runtime_BE_Trigger_USD;
double runtime_TS_Activation_USD;
int    runtime_MaxPosiciones;
int    runtime_RSI_Overbought;
int    runtime_RSI_Oversold;
int    runtime_SegundosEspera;

#define PNL_TAG "BTC_HUD"

//+------------------------------------------------------------------+
//| Funciones de utilidad                                            |
//+------------------------------------------------------------------+
double GetPointValueUSD(double lot) {
   return lot * symInfo.TickValue() / symInfo.TickSize();
}

double ConvertUSDToPoints(double usd, double lot) {
   double pv = GetPointValueUSD(lot);
   if(pv == 0) return 0;
   return usd / pv;
}

double GetPositionProfitUSD(ulong ticket) {
   if(posInfo.SelectByTicket(ticket))
      return posInfo.Profit() + posInfo.Swap() + posInfo.Commission();
   return 0;
}

double CalculateDayProfitUSD() {
   datetime startTime = pnlResetTime;
   if(startTime == 0) {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      dt.hour = 0; dt.min = 0; dt.sec = 0;
      startTime = StructToTime(dt);
   }
   HistorySelect(startTime, TimeCurrent());
   double p = 0;
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--) {
      ulong ticket = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) == activeMagic)
         p += HistoryDealGetDouble(ticket, DEAL_PROFIT) +
              HistoryDealGetDouble(ticket, DEAL_SWAP) +
              HistoryDealGetDouble(ticket, DEAL_COMMISSION);
   }
   return p;
}

void ResetDayPnL() {
   pnlResetTime = TimeCurrent();
   dayPnL_USD = 0;
   botStatusStr = "PNL RESETEADO";
   ActualizarHUD();
   dayPnL_USD = CalculateDayProfitUSD();
   ActualizarHUD();
}

int GetPositionsCount() {
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic() == activeMagic)
         count++;
   }
   return count;
}

double GetNetProfitTotal() {
   double net = 0;
   for(int i = 0; i < PositionsTotal(); i++) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic() == activeMagic)
         net += posInfo.Profit() + posInfo.Swap() + posInfo.Commission();
   }
   return net;
}

void CloseAllPositions() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic() == activeMagic)
         trade.PositionClose(posInfo.Ticket());
   }
}

void DeletePendings() {
   for(int i = 0; i < OrdersTotal(); i++) {
      ulong orderTicket = OrderGetTicket(i);
      if(orderTicket > 0) trade.OrderDelete(orderTicket);
   }
}

bool IsTradingTime() {
   if(!user_EnableTimeFilter) return true;
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   return (dt.hour >= user_StartHour1 && dt.hour < user_EndHour1);
}

//+------------------------------------------------------------------+
//| Protección de posiciones                                          |
//+------------------------------------------------------------------+
void ProtectAll() {
   double netUSD = GetNetProfitTotal();
   int total = GetPositionsCount();
   
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Magic() != activeMagic) continue;
      
      ulong ticket = posInfo.Ticket();
      double profitUSD = GetPositionProfitUSD(ticket);
      ENUM_POSITION_TYPE type = posInfo.PositionType();
      double sl = posInfo.StopLoss();
      double openPrice = posInfo.PriceOpen();
      double currentPrice = (type == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      // Cierre individual por objetivo
      if(profitUSD >= runtime_Target_Individual_USD) {
         trade.PositionClose(ticket);
         lastTradeClose = TimeCurrent();
         continue;
      }
      
      // Break Even
      if(runtime_BE_Trigger_USD > 0 && profitUSD >= runtime_BE_Trigger_USD) {
         double bePrice = openPrice + (type == POSITION_TYPE_BUY ? 10 * _Point : -10 * _Point);
         if((type == POSITION_TYPE_BUY && (sl < bePrice || sl == 0)) ||
            (type == POSITION_TYPE_SELL && (sl > bePrice || sl == 0))) {
            trade.PositionModify(ticket, bePrice, 0);
         }
      }
      
      // Trailing Stop
      if(runtime_TS_Activation_USD > 0 && profitUSD >= runtime_TS_Activation_USD) {
         double pointsDist = ConvertUSDToPoints(runtime_TS_Distance_USD, posInfo.Volume());
         if(pointsDist <= 0) continue;
         
         double newSL;
         if(type == POSITION_TYPE_BUY) {
            newSL = currentPrice - pointsDist * _Point;
            if(newSL > sl) trade.PositionModify(ticket, newSL, 0);
         } else {
            newSL = currentPrice + pointsDist * _Point;
            if(newSL < sl || sl == 0) trade.PositionModify(ticket, newSL, 0);
         }
      }
   }
   
   // Cierre de bloque (Meta de Ciclo)
   if(total >= 2 && netUSD >= runtime_Net_Cycle_USD) {
      CloseAllPositions();
      coolingEndTime = TimeCurrent() + 120; // 2 min de pausa tras éxito
   }
}

//+------------------------------------------------------------------+
//| Gestión de entradas y hedge                                       |
//+------------------------------------------------------------------+
void ManageStrategy() {
   if(GetPositionsCount() >= runtime_MaxPosiciones) {
      DeletePendings();
      return;
   }
   if(TimeCurrent() < lastTradeClose + runtime_SegundosEspera) {
      botStatusStr = "ESPERANDO";
      return;
   }
   
   double emaF[1], emaS[1], rsi[1];
   if(CopyBuffer(h_ema20, 0, 0, 1, emaF) <= 0 ||
      CopyBuffer(h_ema50, 0, 0, 1, emaS) <= 0 ||
      CopyBuffer(h_rsi, 0, 0, 1, rsi) <= 0) return;
   
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double priceNow = (currentDir == DIR_SOLO_COMPRAS) ? ask : bid;
   
   bool biasUp   = (emaF[0] > emaS[0] && rsi[0] > 50 && rsi[0] < runtime_RSI_Overbought);
   bool biasDown = (emaF[0] < emaS[0] && rsi[0] < 50 && rsi[0] > runtime_RSI_Oversold);
   
   double distPoints = MathAbs(priceNow - emaF[0]) / _Point;
   if(distPoints > runtime_MaxDistEMA_Points) {
      botStatusStr = "P. LEJOS";
      return;
   }
   
   int totalPos = GetPositionsCount();
   
   if(totalPos == 0) {
      DeletePendings();
      if(biasUp && (currentDir == DIR_AMBAS || currentDir == DIR_SOLO_COMPRAS)) {
         if(trade.Buy(runtime_LoteManual, _Symbol, ask, 0, 0, commentTag))
            lastTradeClose = 0;
      }
      else if(biasDown && (currentDir == DIR_AMBAS || currentDir == DIR_SOLO_VENTAS)) {
         if(trade.Sell(runtime_LoteManual, _Symbol, bid, 0, 0, commentTag))
            lastTradeClose = 0;
      }
      return;
   }
   
   // Lógica de hedge
   ulong mainTicket = 0;
   double mainProfitUSD = 0;
   ENUM_POSITION_TYPE mainType = -1;
   bool hasHedge = false;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Magic() != activeMagic) continue;
      if(mainTicket == 0) {
         mainTicket = posInfo.Ticket();
         mainType = posInfo.PositionType();
         mainProfitUSD = GetPositionProfitUSD(mainTicket);
      } else {
         if(posInfo.PositionType() != mainType) hasHedge = true;
      }
   }
   
   if(!hasHedge && (totalPos < runtime_MaxPosiciones) && mainProfitUSD <= -runtime_GatilloHedge_USD) {
      double hedgeLot = NormalizeDouble(runtime_LoteManual * runtime_HedgeMultiplier, 3);
      double hedgePrice = (mainType == POSITION_TYPE_BUY) ? bid : ask;
      if(mainType == POSITION_TYPE_BUY)
         trade.Sell(hedgeLot, _Symbol, hedgePrice, 0, 0, commentTag + "_H");
      else
         trade.Buy(hedgeLot, _Symbol, hedgePrice, 0, 0, commentTag + "_H");
   }
}

//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit() {
   //--- 1. VALIDAR LICENCIA (Kopytrade Core)
   if(!ValidateLicense(PurchaseID, LicenseKey, (int)AccountInfoInteger(ACCOUNT_LOGIN))) {
      MessageBox("Licencia inválida: " + GetLicenseStatus(), "Kopytrade Error", MB_OK | MB_ICONERROR);
      return INIT_FAILED;
   }

   currentMode = MODE_COSECHA;
   currentDir = DIR_AMBAS;
   activeMagic = (int)user_MagicNumber;
   trade.SetExpertMagicNumber(activeMagic);
   symInfo.Name(_Symbol);
   symInfo.Refresh();
   tickSize = symInfo.TickSize();
   tickValue = symInfo.TickValue();
   
   runtime_LoteManual = user_LoteManual;
   runtime_HedgeMultiplier = user_HedgeMultiplier;
   runtime_GatilloHedge_USD = user_GatilloHedge_USD;
   runtime_Target_Individual_USD = user_Target_Individual_USD;
   runtime_Net_Cycle_USD = user_Net_Cycle_USD;
   runtime_TS_Distance_USD = user_TS_Distance_USD;
   runtime_MaxDistEMA_Points = user_MaxDistEMA_Points;
   runtime_BE_Trigger_USD = user_BE_Trigger_USD;
   runtime_TS_Activation_USD = user_TS_Activation_USD;
   runtime_MaxPosiciones = (int)user_MaxPosiciones;
   runtime_RSI_Overbought = user_RSI_Overbought;
   runtime_RSI_Oversold = user_RSI_Oversold;
   runtime_SegundosEspera = user_SegundosEspera;
   
   hud_W = user_HUD_DefaultWidth;
   hud_H = user_HUD_DefaultHeight;
   hud_X = 10;
   hud_Y = 10;
   
   accountBalanceUSD = AccountInfoDouble(ACCOUNT_BALANCE);
   
   h_ema20 = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   h_ema50 = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
   h_rsi   = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   
   if(user_ShowIndicators) {
      ChartIndicatorAdd(0, 0, h_ema20);
      ChartIndicatorAdd(0, 0, h_ema50);
      ChartIndicatorAdd(0, 1, h_rsi);
   }
   
   dayPnL_USD = CalculateDayProfitUSD();
   CrearHUD();
   EventSetTimer(3);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int r) {
   ObjectsDeleteAll(0, PNL_TAG);
   Comment("");
}

//+------------------------------------------------------------------+
//| OnTick                                                           |
//+------------------------------------------------------------------+
void OnTick() {
   accountBalanceUSD = AccountInfoDouble(ACCOUNT_BALANCE);
   
   //--- 2. CONTROL REMOTO (Kopytrade Core)
   GetRemoteStatus();
   if(IsRemotePaused()) {
      botStatusStr = "PAUSA REMOTA";
      DeletePendings();
      ActualizarHUD();
      SyncPositions(botStatusStr, dayPnL_USD, GetPositionsCount());
      return;
   }
   
   double netUSD = GetNetProfitTotal();
   double drawdownPercent = (netUSD / accountBalanceUSD) * 100.0;
   
   if(user_MaxDrawdownPercent > 0 && drawdownPercent <= -user_MaxDrawdownPercent) {
      CloseAllPositions();
      DeletePendings();
      botStatusStr = "STOP DD";
      ActualizarHUD();
      SyncPositions(botStatusStr, dayPnL_USD, GetPositionsCount());
      return;
   }
   
   if(!IsTradingTime() || TimeCurrent() < coolingEndTime) {
      botStatusStr = (TimeCurrent() < coolingEndTime) ? "ENFRIANDO" : "FUERA HORA";
      ProtectAll();
      DeletePendings();
      ActualizarHUD();
      SyncPositions(botStatusStr, dayPnL_USD, GetPositionsCount());
      return;
   }
   
   ProtectAll();
   ManageStrategy();
   
   dayPnL_USD = CalculateDayProfitUSD();
   botStatusStr = "TRABAJANDO";
   
   //--- 3. SINCRONIZACIÓN (Kopytrade Core)
   SyncPositions(botStatusStr, dayPnL_USD, GetPositionsCount());
   ActualizarHUD();
}

//+------------------------------------------------------------------+
//| HUD VISUAL COMPLETO                                              |
//+------------------------------------------------------------------+
void CrearHUD() {
   ObjectsDeleteAll(0, PNL_TAG);
   int x = hud_X, y = hud_Y, w = hud_W, h = hud_H;
   if(isMinimized) { w = 220; h = 55; }
   
   CrRect("bg", x, y, w, h, C'15,15,35', C'60,60,120', 2);
   string title = "⚡ STORM RIDER v1.1 | Balance: $" + DoubleToString(accountBalanceUSD, 2);
   CrRect("titlebar", x, y, w, 32, C'40,40,80', C'80,80,140', 1);
   CrLabel("ttl", x+10, y+8, title, clrWhite, 9, "Arial Bold");
   CrBtn("min", x+w-32, y+5, 26, 22, isMinimized ? "+" : "−", C'60,60,100', clrWhite);
   
   if(isMinimized) return;
   
   CrRect("resize", x+w-14, y+h-14, 14, 14, C'80,80,120', C'100,100,160', 1);
   
   int innerX = x + 12, innerY = y + 38, innerW = w - 24;
   int row = innerY, colLabel = 0, colValue = 135, colBtn1 = innerW - 75, colBtn2 = innerW - 40, btnW = 30;
   
   // Licencia y Estado
   CrLabel("licL", innerX+colLabel, row, "LICENCIA:", C'150,150,200', 9);
   CrLabel("licV", innerX+colValue, row, GetLicenseStatus(), C'255,200,50', 9);
   row += 26;
   
   CrLabel("pL", innerX+colLabel, row, "PNL HOY (USD):", C'150,150,200', 9);
   CrLabel("pV", innerX+colValue, row, DoubleToString(dayPnL_USD, 2) + " $", clrWhite, 10);
   CrBtn("reset", innerX+colBtn2-20, row-3, 55, 24, "RESET", C'80,80,120', clrWhite);
   row += 28;
   
   CrLabel("stL", innerX+colLabel, row, "ESTADO WEB:", C'150,150,200', 9);
   CrLabel("stV", innerX+colValue, row, botStatusStr, C'0,255,127', 9);
   row += 28;
   
   // --- CONTROLES DINÁMICOS ---
   string labels[] = {"LOTE BASE:","MULTIPLIC:","GATILLO-H:","META CICLO:","OBJETIVO $:","BE TRIG $:","TS ACT $:","TS DIST $:","EMA DIST:","MAX POS:","RSI OB:","RSI OS:"};
   string vals[] = {DoubleToString(runtime_LoteManual,3), DoubleToString(runtime_HedgeMultiplier,1), DoubleToString(runtime_GatilloHedge_USD,1), 
                   DoubleToString(runtime_Net_Cycle_USD,1), DoubleToString(runtime_Target_Individual_USD,1), DoubleToString(runtime_BE_Trigger_USD,1),
                   DoubleToString(runtime_TS_Activation_USD,1), DoubleToString(runtime_TS_Distance_USD,1), DoubleToString(runtime_MaxDistEMA_Points,0),
                   IntegerToString(runtime_MaxPosiciones), IntegerToString(runtime_RSI_Overbought), IntegerToString(runtime_RSI_Oversold)};
   string keys[] = {"lot","mult","gat","meta","target","be","tsact","tsdist","dist","maxpos","rsiob","rsios"};

   for(int i=0; i<ArraySize(labels); i++) {
      CrLabel(keys[i]+"L", innerX+colLabel, row, labels[i], C'150,150,200', 9);
      CrLabel(keys[i]+"V", innerX+colValue, row, vals[i], clrWhite, 10);
      CrBtn(keys[i]+"m", innerX+colBtn1, row-3, btnW, 24, "-", C'40,40,70', clrWhite);
      CrBtn(keys[i]+"p", innerX+colBtn2, row-3, btnW, 24, "+", C'40,40,70', clrWhite);
      row += 28;
   }
   
   row += 10;
   // Dirección
   CrBtn("d_amb", innerX+5, row, 85, 32, "AMBAS", currentDir == DIR_AMBAS ? C'60,150,255' : C'40,40,70', clrWhite);
   CrBtn("d_buy", innerX+95, row, 90, 32, "SOLO BUY", currentDir == DIR_SOLO_COMPRAS ? C'0,200,100' : C'40,40,70', clrWhite);
   CrBtn("d_sel", innerX+190, row, 90, 32, "SOLO SELL", currentDir == DIR_SOLO_VENTAS ? C'220,50,50' : C'40,40,70', clrWhite);
   row += 45;
   
   CrBtn("apply", innerX+5, row, innerW-10, 38, "APLICAR CAMBIOS", C'0,100,150', clrWhite);
   row += 46;
   CrBtn("close", innerX+5, row, innerW-10, 38, "CERRAR TODAS", C'200,40,40', clrWhite);
}

void ActualizarHUD() {
   if(ObjectFind(0, PNL_TAG + "bg") == -1) { CrearHUD(); return; }
   ObjectSetString(0, PNL_TAG + "ttl", OBJPROP_TEXT, "⚡ STORM RIDER v1.1 | Balance: $" + DoubleToString(accountBalanceUSD, 2));
   ObjectSetString(0, PNL_TAG + "bal_v", OBJPROP_TEXT, "$" + DoubleToString(accountBalanceUSD, 2));
   ObjectSetString(0, PNL_TAG + "pV", OBJPROP_TEXT, DoubleToString(dayPnL_USD, 2) + " $");
   ObjectSetString(0, PNL_TAG + "stV", OBJPROP_TEXT, botStatusStr);
   ObjectSetString(0, PNL_TAG + "licV", OBJPROP_TEXT, GetLicenseStatus());
   
   if(isMinimized) return;
   
   ObjectSetString(0, PNL_TAG + "lotV", OBJPROP_TEXT, DoubleToString(runtime_LoteManual, 3));
   ObjectSetString(0, PNL_TAG + "multV", OBJPROP_TEXT, DoubleToString(runtime_HedgeMultiplier, 1));
   ObjectSetString(0, PNL_TAG + "gatV", OBJPROP_TEXT, DoubleToString(runtime_GatilloHedge_USD, 1));
   ObjectSetString(0, PNL_TAG + "metaV", OBJPROP_TEXT, DoubleToString(runtime_Net_Cycle_USD, 1));
   ObjectSetString(0, PNL_TAG + "targetV", OBJPROP_TEXT, DoubleToString(runtime_Target_Individual_USD, 1));
   ObjectSetString(0, PNL_TAG + "beV", OBJPROP_TEXT, DoubleToString(runtime_BE_Trigger_USD, 1));
   ObjectSetString(0, PNL_TAG + "tsactV", OBJPROP_TEXT, DoubleToString(runtime_TS_Activation_USD, 1));
   ObjectSetString(0, PNL_TAG + "tsdistV", OBJPROP_TEXT, DoubleToString(runtime_TS_Distance_USD, 1));
   ObjectSetString(0, PNL_TAG + "distV", OBJPROP_TEXT, DoubleToString(runtime_MaxDistEMA_Points, 0));
   ObjectSetString(0, PNL_TAG + "maxposV", OBJPROP_TEXT, IntegerToString(runtime_MaxPosiciones));
   ObjectSetString(0, PNL_TAG + "rsiobV", OBJPROP_TEXT, IntegerToString(runtime_RSI_Overbought));
   ObjectSetString(0, PNL_TAG + "rsiosV", OBJPROP_TEXT, IntegerToString(runtime_RSI_Oversold));
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == PNL_TAG + "min") { isMinimized = !isMinimized; CrearHUD(); return; }
      if(sparam == PNL_TAG + "reset") { ResetDayPnL(); return; }
      if(sparam == PNL_TAG + "d_amb") { currentDir = DIR_AMBAS; CrearHUD(); }
      if(sparam == PNL_TAG + "d_buy") { currentDir = DIR_SOLO_COMPRAS; CrearHUD(); }
      if(sparam == PNL_TAG + "d_sel") { currentDir = DIR_SOLO_VENTAS; CrearHUD(); }
      if(sparam == PNL_TAG + "close") { CloseAllPositions(); return; }
      if(sparam == PNL_TAG + "apply") {
         user_LoteManual = runtime_LoteManual; user_HedgeMultiplier = runtime_HedgeMultiplier;
         user_GatilloHedge_USD = runtime_GatilloHedge_USD; user_Net_Cycle_USD = runtime_Net_Cycle_USD;
         user_Target_Individual_USD = runtime_Target_Individual_USD; user_TS_Distance_USD = runtime_TS_Distance_USD;
         user_MaxDistEMA_Points = (int)runtime_MaxDistEMA_Points; user_BE_Trigger_USD = runtime_BE_Trigger_USD;
         user_TS_Activation_USD = runtime_TS_Activation_USD; user_MaxPosiciones = runtime_MaxPosiciones;
         user_RSI_Overbought = runtime_RSI_Overbought; user_RSI_Oversold = runtime_RSI_Oversold;
         botStatusStr = "CONFIG OK"; ActualizarHUD(); return;
      }
      
      double sl = 0.001, sm = 0.1, su = 1.0, sp = 100;
      if(sparam == PNL_TAG + "lotm") runtime_LoteManual = MathMax(0.01, runtime_LoteManual - sl);
      if(sparam == PNL_TAG + "lotp") runtime_LoteManual = MathMin(0.5, runtime_LoteManual + sl);
      if(sparam == PNL_TAG + "multm") runtime_HedgeMultiplier = MathMax(1.0, runtime_HedgeMultiplier - sm);
      if(sparam == PNL_TAG + "multp") runtime_HedgeMultiplier = MathMin(3.0, runtime_HedgeMultiplier + sm);
      if(sparam == PNL_TAG + "gatm") runtime_GatilloHedge_USD = MathMax(5, runtime_GatilloHedge_USD - su);
      if(sparam == PNL_TAG + "gatp") runtime_GatilloHedge_USD = MathMin(100, runtime_GatilloHedge_USD + su);
      if(sparam == PNL_TAG + "metam") runtime_Net_Cycle_USD = MathMax(10, runtime_Net_Cycle_USD - su);
      if(sparam == PNL_TAG + "metap") runtime_Net_Cycle_USD = MathMin(500, runtime_Net_Cycle_USD + su);
      if(sparam == PNL_TAG + "targetm") runtime_Target_Individual_USD = MathMax(5, runtime_Target_Individual_USD - su);
      if(sparam == PNL_TAG + "targetp") runtime_Target_Individual_USD = MathMin(200, runtime_Target_Individual_USD + su);
      if(sparam == PNL_TAG + "bem") runtime_BE_Trigger_USD = MathMax(2, runtime_BE_Trigger_USD - 1);
      if(sparam == PNL_TAG + "bep") runtime_BE_Trigger_USD = MathMin(50, runtime_BE_Trigger_USD + 1);
      if(sparam == PNL_TAG + "tsactm") runtime_TS_Activation_USD = MathMax(5, runtime_TS_Activation_USD - su);
      if(sparam == PNL_TAG + "tsactp") runtime_TS_Activation_USD = MathMin(100, runtime_TS_Activation_USD + su);
      if(sparam == PNL_TAG + "tsdistm") runtime_TS_Distance_USD = MathMax(2, runtime_TS_Distance_USD - 1);
      if(sparam == PNL_TAG + "tsdistp") runtime_TS_Distance_USD = MathMin(50, runtime_TS_Distance_USD + 1);
      if(sparam == PNL_TAG + "distm") runtime_MaxDistEMA_Points = MathMax(100, runtime_MaxDistEMA_Points - sp);
      if(sparam == PNL_TAG + "distp") runtime_MaxDistEMA_Points = MathMin(5000, runtime_MaxDistEMA_Points + sp);
      if(sparam == PNL_TAG + "maxposm") runtime_MaxPosiciones = MathMax(1, runtime_MaxPosiciones - 1);
      if(sparam == PNL_TAG + "maxposp") runtime_MaxPosiciones = MathMin(10, runtime_MaxPosiciones + 1);
      if(sparam == PNL_TAG + "rsiobm") runtime_RSI_Overbought = MathMax(60, runtime_RSI_Overbought - 1);
      if(sparam == PNL_TAG + "rsiobp") runtime_RSI_Overbought = MathMin(95, runtime_RSI_Overbought + 1);
      if(sparam == PNL_TAG + "rsiosm") runtime_RSI_Oversold = MathMax(5, runtime_RSI_Oversold - 1);
      if(sparam == PNL_TAG + "rsiosp") runtime_RSI_Oversold = MathMin(40, runtime_RSI_Oversold + 1);
      
      ActualizarHUD();
      ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
   }
   
   if(id == CHARTEVENT_MOUSE_MOVE) {
      if(sparam == PNL_TAG + "titlebar") {
         if(!dragging) { dragging = true; dragStartX = (int)lparam - hud_X; dragStartY = (int)dparam - hud_Y; }
         if(dragging) {
            hud_X = (int)lparam - dragStartX; hud_Y = (int)dparam - dragStartY;
            CrearHUD();
         }
      } else if(sparam == PNL_TAG + "resize") {
          if(!resizing) { resizing = true; resizeStartW = hud_W; resizeStartH = hud_H; dragStartX = (int)lparam; dragStartY = (int)dparam; }
          if(resizing) {
             int deltaX = (int)lparam - dragStartX, deltaY = (int)dparam - dragStartY;
             hud_W = MathMax(320, resizeStartW + deltaX); hud_H = MathMax(500, resizeStartH + deltaY);
             CrearHUD();
          }
      } else { dragging = false; resizing = false; }
   }
}

// Dibujo
void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bw=1) {
   string nm = PNL_TAG + n; ObjectCreate(0, nm, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, nm, OBJPROP_XSIZE, w); ObjectSetInteger(0, nm, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, nm, OBJPROP_BGCOLOR, bg); ObjectSetInteger(0, nm, OBJPROP_COLOR, bd);
   ObjectSetInteger(0, nm, OBJPROP_ZORDER, 100);
}

void CrLabel(string n, int x, int y, string t, color c, int s, string f="Segoe UI") {
   string nm = PNL_TAG + n; ObjectCreate(0, nm, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, nm, OBJPROP_TEXT, t); ObjectSetInteger(0, nm, OBJPROP_COLOR, c);
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, s); ObjectSetString(0, nm, OBJPROP_FONT, f);
   ObjectSetInteger(0, nm, OBJPROP_ZORDER, 101);
}

void CrBtn(string n, int x, int y, int w, int h, string t, color bg, color tc) {
   string nm = PNL_TAG + n; ObjectCreate(0, nm, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, nm, OBJPROP_XSIZE, w); ObjectSetInteger(0, nm, OBJPROP_YSIZE, h);
   ObjectSetString(0, nm, OBJPROP_TEXT, t); ObjectSetInteger(0, nm, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, tc); ObjectSetInteger(0, nm, OBJPROP_ZORDER, 102);
}

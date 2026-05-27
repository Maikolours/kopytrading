//+------------------------------------------------------------------+
//|                                    XAUUSD_CENT_HUD_TotalControl  |
//|                           Versión 8.3 - HUD MOVIBLE Y REDIMENS.  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "8.30"
#property description "HUD completo | ARRASTRABLE | REDIMENSIONABLE"
#property description "Arrastra desde la barra superior | Redimensiona desde la esquina"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- ENUMS
enum ENUM_MODE { MODE_ZEN, MODE_COSECHA };
enum ENUM_DIR  { DIR_AMBAS, DIR_SOLO_COMPRAS, DIR_SOLO_VENTAS };

//--- Parámetros input
sinput string   LicenseKey        = "CENT-2026";
input string    PurchaseID        = "";
input double    user_MaxDrawdownPercent = 30.0;
input bool      user_EnableTimeFilter = true;
input int       user_StartHour1 = 1;
input int       user_EndHour1 = 24;
input bool      user_ShowIndicators = true;
input int       user_HUD_DefaultWidth = 340;     // Ancho por defecto del HUD
input int       user_HUD_DefaultHeight = 650;    // Alto por defecto del HUD

//--- Variables que se manejan desde HUD
double   user_MagicNumber        = 700742;
double   user_MaxPosiciones      = 2;
double   user_LoteManual         = 0.015;
double   user_HedgeMultiplier    = 1.5;
double   user_GatilloHedge_Cents = 100;
double   user_Target_Individual_Cents = 60;
double   user_Net_Cycle_Cents    = 200;
double   user_TS_Distance_Cents  = 15;
double   user_MaxDistEMA_Points  = 250;
double   user_BE_Trigger_Cents   = 12;
double   user_TS_Activation_Cents = 25;
int      user_RSI_Overbought     = 70;
int      user_RSI_Oversold       = 30;
int      user_SegundosEspera     = 30;
int      user_TS_Step_Points     = 5;

//--- Globales
CTrade         trade;
CPositionInfo  posInfo;
CSymbolInfo    symInfo;
int            activeMagic, h_ema20, h_ema50, h_rsi;
bool           remotePaused = false;
bool           isMinimized = false;  // <--- DECLARADA AQUÍ
ENUM_MODE      currentMode;
ENUM_DIR       currentDir;
string         botStatus = "TRABAJANDO", commentTag = "CENT_GOLD_83";
double         dayPnL_Cents = 0;
datetime       lastSync = 0, coolingEndTime = 0, lastTradeClose = 0;
double         tickSize, tickValue;
double         accountBalanceCents;
datetime       pnlResetTime = 0;

//--- Variables para HUD móvil
int      hud_X = 10;           // Posición X del HUD
int      hud_Y = 10;           // Posición Y del HUD
int      hud_W = 340;          // Ancho del HUD
int      hud_H = 650;          // Alto del HUD
bool     dragging = false;     // Modo arrastre
int      dragStartX, dragStartY;
bool     resizing = false;     // Modo redimensionamiento
int      resizeStartW, resizeStartH;

//--- Runtime
double runtime_LoteManual;
double runtime_HedgeMultiplier;
double runtime_GatilloHedge_Cents;
double runtime_Target_Individual_Cents;
double runtime_Net_Cycle_Cents;
double runtime_TS_Distance_Cents;
double runtime_MaxDistEMA_Points;
double runtime_BE_Trigger_Cents;
double runtime_TS_Activation_Cents;
int    runtime_MaxPosiciones;
int    runtime_RSI_Overbought;
int    runtime_RSI_Oversold;
int    runtime_SegundosEspera;

#define PNL "CENT_HUD"

//+------------------------------------------------------------------+
//| Utilidades                                                       |
//+------------------------------------------------------------------+
double GetPointValueUSD(double lot) {
   return lot * symInfo.TickValue() / symInfo.TickSize();
}

double ConvertCentsToPoints(double cents, double lot) {
   double usd = cents / 100.0;
   double pv = GetPointValueUSD(lot);
   if(pv == 0) return 0;
   return usd / pv;
}

double GetProfitInCents(double profitUSD) {
   return profitUSD * 100.0;
}

double GetPositionProfitCents(ulong ticket) {
   if(posInfo.SelectByTicket(ticket))
      return GetProfitInCents(posInfo.Profit() + posInfo.Swap() + posInfo.Commission());
   return 0;
}

double CalculateDayProfitCents() {
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
   return GetProfitInCents(p);
}

void ResetDayPnL() {
   pnlResetTime = TimeCurrent();
   dayPnL_Cents = 0;
   botStatus = "PNL RESETEADO";
   ActualizarHUD();
   dayPnL_Cents = CalculateDayProfitCents();
   ActualizarHUD();
}

//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit() {
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
   runtime_GatilloHedge_Cents = user_GatilloHedge_Cents;
   runtime_Target_Individual_Cents = user_Target_Individual_Cents;
   runtime_Net_Cycle_Cents = user_Net_Cycle_Cents;
   runtime_TS_Distance_Cents = user_TS_Distance_Cents;
   runtime_MaxDistEMA_Points = user_MaxDistEMA_Points;
   runtime_BE_Trigger_Cents = user_BE_Trigger_Cents;
   runtime_TS_Activation_Cents = user_TS_Activation_Cents;
   runtime_MaxPosiciones = (int)user_MaxPosiciones;
   runtime_RSI_Overbought = user_RSI_Overbought;
   runtime_RSI_Oversold = user_RSI_Oversold;
   runtime_SegundosEspera = user_SegundosEspera;
   
   hud_W = user_HUD_DefaultWidth;
   hud_H = user_HUD_DefaultHeight;
   hud_X = 10;
   hud_Y = 10;
   
   accountBalanceCents = AccountInfoDouble(ACCOUNT_BALANCE) * 100.0;
   
   if(_Symbol == "BTCUSD" || _Symbol == "BTCUSD.bit") commentTag = "CENT_BTC_83";
   
   h_ema20 = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   h_ema50 = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
   h_rsi   = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   
   if(user_ShowIndicators) {
      ChartIndicatorDelete(0, 0, "EMA(20)");
      ChartIndicatorDelete(0, 0, "EMA(50)");
      ChartIndicatorDelete(0, 1, "RSI(14)");
      ChartIndicatorAdd(0, 0, h_ema20);
      ChartIndicatorAdd(0, 0, h_ema50);
      ChartIndicatorAdd(0, 1, h_rsi);
   }
   
   dayPnL_Cents = CalculateDayProfitCents();
   CrearHUD();
   EventSetTimer(3);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) {
   ObjectsDeleteAll(0, PNL);
}

//+------------------------------------------------------------------+
//| OnTick                                                           |
//+------------------------------------------------------------------+
void OnTick() {
   accountBalanceCents = AccountInfoDouble(ACCOUNT_BALANCE) * 100.0;
   
   if(remotePaused) {
      botStatus = "PAUSA REMOTA";
      DeletePendings();
      ActualizarHUD();
      return;
   }
   
   double netCents = GetNetProfitCents();
   double drawdownPercent = (netCents / accountBalanceCents) * 100.0;
   
   if(user_MaxDrawdownPercent > 0 && drawdownPercent <= -user_MaxDrawdownPercent) {
      CloseAll();
      DeletePendings();
      botStatus = "STOP DRAWDOWN";
      remotePaused = true;
      ActualizarHUD();
      return;
   }
   
   if(!IsTradingTime() || TimeCurrent() < coolingEndTime) {
      botStatus = (TimeCurrent() < coolingEndTime) ? "ENFRIANDO" : "FUERA HORA";
      ProtectAll();
      DeletePendings();
      ActualizarHUD();
      return;
   }
   
   ProtectAll();
   ManageStrike();
   botStatus = "TRABAJANDO";
   dayPnL_Cents = CalculateDayProfitCents();
   ActualizarHUD();
}

//+------------------------------------------------------------------+
//| Protección y gestión                                              |
//+------------------------------------------------------------------+
void ProtectAll() {
   double netCents = GetNetProfitCents();
   int total = PositionsTotalBots();
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Magic() != activeMagic) continue;
      ulong ticket = posInfo.Ticket();
      double profitCents = GetPositionProfitCents(ticket);
      ENUM_POSITION_TYPE type = posInfo.PositionType();
      double sl = posInfo.StopLoss();
      double openPrice = posInfo.PriceOpen();
      double currentPrice = (type == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      if(profitCents >= runtime_Target_Individual_Cents) { trade.PositionClose(ticket); lastTradeClose = TimeCurrent(); continue; }
      if(runtime_BE_Trigger_Cents > 0 && profitCents >= runtime_BE_Trigger_Cents) {
         double bePrice = openPrice + (type == POSITION_TYPE_BUY ? 10 * _Point : -10 * _Point);
         if((type == POSITION_TYPE_BUY && (sl < bePrice || sl == 0)) || (type == POSITION_TYPE_SELL && (sl > bePrice || sl == 0)))
            trade.PositionModify(ticket, bePrice, 0);
      }
      if(runtime_TS_Activation_Cents > 0 && profitCents >= runtime_TS_Activation_Cents) {
         double pointsDist = ConvertCentsToPoints(runtime_TS_Distance_Cents, posInfo.Volume());
         if(pointsDist <= 0) continue;
         double newSL;
         if(type == POSITION_TYPE_BUY) { newSL = currentPrice - pointsDist * _Point; if(newSL > sl + user_TS_Step_Points * _Point) trade.PositionModify(ticket, newSL, 0); }
         else { newSL = currentPrice + pointsDist * _Point; if(newSL < sl - user_TS_Step_Points * _Point || sl == 0) trade.PositionModify(ticket, newSL, 0); }
      }
   }
   if(total >= 2 && netCents >= runtime_Net_Cycle_Cents) { CloseAll(); coolingEndTime = TimeCurrent() + 120; }
}

void ManageStrike() {
   if(PositionsTotalBots() >= runtime_MaxPosiciones) { DeletePendings(); return; }
   if(TimeCurrent() < lastTradeClose + runtime_SegundosEspera) { botStatus = "ESPERANDO"; return; }
   double emaF[1], emaS[1], rsi[1];
   if(CopyBuffer(h_ema20, 0, 0, 1, emaF) <= 0 || CopyBuffer(h_ema50, 0, 0, 1, emaS) <= 0 || CopyBuffer(h_rsi, 0, 0, 1, rsi) <= 0) return;
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double priceNow = (currentDir == DIR_SOLO_COMPRAS) ? ask : bid;
   bool biasUp = (emaF[0] > emaS[0] && rsi[0] > 50 && rsi[0] < runtime_RSI_Overbought);
   bool biasDown = (emaF[0] < emaS[0] && rsi[0] < 50 && rsi[0] > runtime_RSI_Oversold);
   double distPoints = MathAbs(priceNow - emaF[0]) / _Point;
   if(distPoints > runtime_MaxDistEMA_Points) { botStatus = "PRECIO LEJOS"; return; }
   int totalPos = PositionsTotalBots();
   if(totalPos == 0) {
      DeletePendings();
      if(biasUp && (currentDir == DIR_AMBAS || currentDir == DIR_SOLO_COMPRAS)) { if(trade.Buy(runtime_LoteManual, _Symbol, ask, 0, 0, commentTag)) lastTradeClose = 0; }
      else if(biasDown && (currentDir == DIR_AMBAS || currentDir == DIR_SOLO_VENTAS)) { if(trade.Sell(runtime_LoteManual, _Symbol, bid, 0, 0, commentTag)) lastTradeClose = 0; }
      return;
   }
   ulong mainTicket = 0; double mainProfitCents = 0; ENUM_POSITION_TYPE mainType = -1; bool hasHedge = false;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Magic() != activeMagic) continue;
      if(mainTicket == 0) { mainTicket = posInfo.Ticket(); mainType = posInfo.PositionType(); mainProfitCents = GetPositionProfitCents(mainTicket); }
      else { if(posInfo.PositionType() != mainType) hasHedge = true; }
   }
   if(!hasHedge && mainProfitCents <= -runtime_GatilloHedge_Cents) {
      double hedgeLot = NormalizeDouble(runtime_LoteManual * runtime_HedgeMultiplier, 3);
      double hedgePrice = (mainType == POSITION_TYPE_BUY) ? bid : ask;
      if(mainType == POSITION_TYPE_BUY) trade.Sell(hedgeLot, _Symbol, hedgePrice, 0, 0, commentTag + "_H");
      else trade.Buy(hedgeLot, _Symbol, hedgePrice, 0, 0, commentTag + "_H");
   }
}

void CloseAll() { for(int i = PositionsTotal() - 1; i >= 0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic() == activeMagic) trade.PositionClose(posInfo.Ticket()); }
void DeletePendings() { for(int i = 0; i < OrdersTotal(); i++) { ulong orderTicket = OrderGetTicket(i); if(orderTicket > 0) trade.OrderDelete(orderTicket); } }
int PositionsTotalBots() { int count = 0; for(int i = 0; i < PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic() == activeMagic) count++; return count; }
double GetNetProfitCents() { double net = 0; for(int i = 0; i < PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic() == activeMagic) net += posInfo.Profit() + posInfo.Swap() + posInfo.Commission(); return GetProfitInCents(net); }
bool IsTradingTime() { if(!user_EnableTimeFilter) return true; MqlDateTime dt; TimeToStruct(TimeCurrent(), dt); return (dt.hour >= user_StartHour1 && dt.hour < user_EndHour1); }
void SyncWeb() {}

//+------------------------------------------------------------------+
//| HUD MOVIBLE Y REDIMENSIONABLE                                     |
//+------------------------------------------------------------------+
void CrearHUD() {
   ObjectsDeleteAll(0, PNL);
   
   int x = hud_X, y = hud_Y, w = hud_W, h = hud_H;
   
   // Fondo principal
   CrRect("bg", x, y, w, h, C'15,15,35', C'60,60,120', 2);
   
   // Barra de título (arrastrable)
   CrRect("titlebar", x, y, w, 28, C'40,40,80', C'80,80,140', 1);
   string vName = "≡ CENT v8.3 | Cuenta: " + DoubleToString(accountBalanceCents, 0) + "¢";
   CrLabel("ttl", x+8, y+6, vName, clrWhite, 9, "Arial Bold");
   
   // Botón minimizar
   CrBtn("min", x+w-28, y+4, 22, 20, "−", C'60,60,100', clrWhite);
   
   // Esquina de redimensionamiento
   CrRect("resize", x+w-12, y+h-12, 12, 12, C'80,80,120', C'100,100,160', 1);
   CrLabel("resize_mark", x+w-10, y+h-9, "◢", C'150,150,200', 10, "Segoe UI");
   
   int innerX = x + 8;
   int innerY = y + 32;
   int innerW = w - 16;
   
   int row = innerY;
   int colLabel = 0;
   int colValue = 90;
   int colBtn1 = innerW - 60;
   int colBtn2 = innerW - 30;
   
   // PNL con botón reset
   CrLabel("pL", innerX+colLabel, row, "PNL HOY (¢):", C'150,150,200', 8);
   CrLabel("pV", innerX+colValue, row, "0.00 ¢", clrWhite, 10, "Arial Bold");
   CrBtn("reset", innerX+colBtn2-10, row-3, 50, 22, "RESET", C'80,80,120', clrWhite);
   row += 28;
   
   // Estado
   CrLabel("stL", innerX+colLabel, row, "ESTADO:", C'150,150,200', 8);
   CrLabel("stV", innerX+colValue, row, botStatus, C'0,255,127', 9);
   row += 30;
   
   // LOTE BASE
   CrLabel("lot_l", innerX+colLabel, row, "LOTE BASE:", C'150,150,200', 8);
   CrLabel("lot_v", innerX+colValue, row, DoubleToString(runtime_LoteManual, 3), clrWhite, 9, "Consolas");
   CrBtn("lot_m", innerX+colBtn1, row-3, 22, 20, "-", C'40,40,70', clrWhite);
   CrBtn("lot_p", innerX+colBtn2, row-3, 22, 20, "+", C'40,40,70', clrWhite);
   row += 24;
   
   // MULTIPLICADOR
   CrLabel("mult_l", innerX+colLabel, row, "MULTIPLICADOR:", C'150,150,200', 8);
   CrLabel("mult_v", innerX+colValue, row, DoubleToString(runtime_HedgeMultiplier, 1), clrWhite, 9, "Consolas");
   CrLabel("rec_v", innerX+colValue+55, row, "→ " + DoubleToString(runtime_LoteManual * runtime_HedgeMultiplier, 3), C'100,200,100', 8);
   CrBtn("mult_m", innerX+colBtn1, row-3, 22, 20, "-", C'40,40,70', clrWhite);
   CrBtn("mult_p", innerX+colBtn2, row-3, 22, 20, "+", C'40,40,70', clrWhite);
   row += 24;
   
   // GATILLO HEDGE
   CrLabel("gat_l", innerX+colLabel, row, "GATILLO HEDGE (¢):", C'150,150,200', 8);
   CrLabel("gat_v", innerX+colValue, row, DoubleToString(runtime_GatilloHedge_Cents, 0), clrWhite, 9, "Consolas");
   CrBtn("gat_m", innerX+colBtn1, row-3, 22, 20, "-", C'40,40,70', clrWhite);
   CrBtn("gat_p", innerX+colBtn2, row-3, 22, 20, "+", C'40,40,70', clrWhite);
   row += 24;
   
   // META CCLO
   CrLabel("meta_l", innerX+colLabel, row, "META CCLO (¢):", C'150,150,200', 8);
   CrLabel("meta_v", innerX+colValue, row, DoubleToString(runtime_Net_Cycle_Cents, 0), clrWhite, 9, "Consolas");
   CrBtn("meta_m", innerX+colBtn1, row-3, 22, 20, "-", C'40,40,70', clrWhite);
   CrBtn("meta_p", innerX+colBtn2, row-3, 22, 20, "+", C'40,40,70', clrWhite);
   row += 24;
   
   // OBJETIVO
   CrLabel("target_l", innerX+colLabel, row, "OBJETIVO (¢):", C'150,150,200', 8);
   CrLabel("target_v", innerX+colValue, row, DoubleToString(runtime_Target_Individual_Cents, 0), clrWhite, 9, "Consolas");
   CrBtn("target_m", innerX+colBtn1, row-3, 22, 20, "-", C'40,40,70', clrWhite);
   CrBtn("target_p", innerX+colBtn2, row-3, 22, 20, "+", C'40,40,70', clrWhite);
   row += 24;
   
   // BE TRIGGER
   CrLabel("be_l", innerX+colLabel, row, "BE TRIGGER (¢):", C'150,150,200', 8);
   CrLabel("be_v", innerX+colValue, row, DoubleToString(runtime_BE_Trigger_Cents, 0), clrWhite, 9, "Consolas");
   CrBtn("be_m", innerX+colBtn1, row-3, 22, 20, "-", C'40,40,70', clrWhite);
   CrBtn("be_p", innerX+colBtn2, row-3, 22, 20, "+", C'40,40,70', clrWhite);
   row += 24;
   
   // TS ACTIVACIÓN
   CrLabel("tsact_l", innerX+colLabel, row, "TS ACTIVACIÓN (¢):", C'150,150,200', 8);
   CrLabel("tsact_v", innerX+colValue, row, DoubleToString(runtime_TS_Activation_Cents, 0), clrWhite, 9, "Consolas");
   CrBtn("tsact_m", innerX+colBtn1, row-3, 22, 20, "-", C'40,40,70', clrWhite);
   CrBtn("tsact_p", innerX+colBtn2, row-3, 22, 20, "+", C'40,40,70', clrWhite);
   row += 24;
   
   // T-STOP DIST
   CrLabel("tsdist_l", innerX+colLabel, row, "T-STOP DIST (¢):", C'150,150,200', 8);
   CrLabel("tsdist_v", innerX+colValue, row, DoubleToString(runtime_TS_Distance_Cents, 0), clrWhite, 9, "Consolas");
   CrBtn("tsdist_m", innerX+colBtn1, row-3, 22, 20, "-", C'40,40,70', clrWhite);
   CrBtn("tsdist_p", innerX+colBtn2, row-3, 22, 20, "+", C'40,40,70', clrWhite);
   row += 24;
   
   // DIST LIMIT
   CrLabel("dist_l", innerX+colLabel, row, "DIST LIMIT (pts):", C'150,150,200', 8);
   CrLabel("dist_v", innerX+colValue, row, DoubleToString(runtime_MaxDistEMA_Points, 0), clrWhite, 9, "Consolas");
   CrBtn("dist_m", innerX+colBtn1, row-3, 22, 20, "-", C'40,40,70', clrWhite);
   CrBtn("dist_p", innerX+colBtn2, row-3, 22, 20, "+", C'40,40,70', clrWhite);
   row += 24;
   
   // MAX POSICIONES
   CrLabel("maxpos_l", innerX+colLabel, row, "MAX POSICIONES:", C'150,150,200', 8);
   CrLabel("maxpos_v", innerX+colValue, row, IntegerToString(runtime_MaxPosiciones), clrWhite, 9, "Consolas");
   CrBtn("maxpos_m", innerX+colBtn1, row-3, 22, 20, "-", C'40,40,70', clrWhite);
   CrBtn("maxpos_p", innerX+colBtn2, row-3, 22, 20, "+", C'40,40,70', clrWhite);
   row += 24;
   
   // RSI SOBRECOMPRA
   CrLabel("rsiob_l", innerX+colLabel, row, "RSI SOBRECOMPRA:", C'150,150,200', 8);
   CrLabel("rsiob_v", innerX+colValue, row, IntegerToString(runtime_RSI_Overbought), clrWhite, 9, "Consolas");
   CrBtn("rsiob_m", innerX+colBtn1, row-3, 22, 20, "-", C'40,40,70', clrWhite);
   CrBtn("rsiob_p", innerX+colBtn2, row-3, 22, 20, "+", C'40,40,70', clrWhite);
   row += 24;
   
   // RSI SOBREVENTA
   CrLabel("rsios_l", innerX+colLabel, row, "RSI SOBREVENTA:", C'150,150,200', 8);
   CrLabel("rsios_v", innerX+colValue, row, IntegerToString(runtime_RSI_Oversold), clrWhite, 9, "Consolas");
   CrBtn("rsios_m", innerX+colBtn1, row-3, 22, 20, "-", C'40,40,70', clrWhite);
   CrBtn("rsios_p", innerX+colBtn2, row-3, 22, 20, "+", C'40,40,70', clrWhite);
   row += 24;
   
   // ESPERA
   CrLabel("wait_l", innerX+colLabel, row, "ESPERA (seg):", C'150,150,200', 8);
   CrLabel("wait_v", innerX+colValue, row, IntegerToString(runtime_SegundosEspera), clrWhite, 9, "Consolas");
   CrBtn("wait_m", innerX+colBtn1, row-3, 22, 20, "-", C'40,40,70', clrWhite);
   CrBtn("wait_p", innerX+colBtn2, row-3, 22, 20, "+", C'40,40,70', clrWhite);
   row += 30;
   
   // Modos y dirección
   CrBtn("b_zen", innerX+5, row, 85, 28, "ZEN", currentMode == MODE_ZEN ? C'0,100,255' : C'40,40,70', clrWhite);
   CrBtn("b_har", innerX+95, row, 85, 28, "COSECHA", currentMode == MODE_COSECHA ? C'255,100,0' : C'40,40,70', clrWhite);
   row += 35;
   
   CrBtn("d_amb", innerX+5, row, 65, 28, "AMBAS", currentDir == DIR_AMBAS ? C'60,150,255' : C'40,40,70', clrWhite);
   CrBtn("d_buy", innerX+78, row, 75, 28, "SOLO BUY", currentDir == DIR_SOLO_COMPRAS ? C'0,200,100' : C'40,40,70', clrWhite);
   CrBtn("d_sel", innerX+161, row, 75, 28, "SOLO SELL", currentDir == DIR_SOLO_VENTAS ? C'220,50,50' : C'40,40,70', clrWhite);
   row += 40;
   
   // Botones principales
   CrBtn("apply", innerX+5, row, innerW-10, 35, "APLICAR CAMBIOS", C'0,100,150', clrWhite);
   row += 42;
   CrBtn("close", innerX+5, row, innerW-10, 35, "CERRAR TODO", C'200,40,40', clrWhite);
}

void ActualizarHUD() {
   if(ObjectFind(0, PNL + "bg") == -1) { CrearHUD(); return; }
   
   accountBalanceCents = AccountInfoDouble(ACCOUNT_BALANCE) * 100.0;
   string title = "≡ CENT v8.3 | Cuenta: " + DoubleToString(accountBalanceCents, 0) + "¢";
   ObjectSetString(0, PNL + "ttl", OBJPROP_TEXT, title);
   ObjectSetString(0, PNL + "pV", OBJPROP_TEXT, DoubleToString(dayPnL_Cents, 2) + " ¢");
   ObjectSetString(0, PNL + "stV", OBJPROP_TEXT, botStatus);
   ObjectSetInteger(0, PNL + "stV", OBJPROP_COLOR, remotePaused ? C'220,50,50' : C'0,255,127');
   
   ObjectSetString(0, PNL + "lot_v", OBJPROP_TEXT, DoubleToString(runtime_LoteManual, 3));
   ObjectSetString(0, PNL + "rec_v", OBJPROP_TEXT, "→ " + DoubleToString(runtime_LoteManual * runtime_HedgeMultiplier, 3));
   ObjectSetString(0, PNL + "mult_v", OBJPROP_TEXT, DoubleToString(runtime_HedgeMultiplier, 1));
   ObjectSetString(0, PNL + "gat_v", OBJPROP_TEXT, DoubleToString(runtime_GatilloHedge_Cents, 0));
   ObjectSetString(0, PNL + "meta_v", OBJPROP_TEXT, DoubleToString(runtime_Net_Cycle_Cents, 0));
   ObjectSetString(0, PNL + "target_v", OBJPROP_TEXT, DoubleToString(runtime_Target_Individual_Cents, 0));
   ObjectSetString(0, PNL + "be_v", OBJPROP_TEXT, DoubleToString(runtime_BE_Trigger_Cents, 0));
   ObjectSetString(0, PNL + "tsact_v", OBJPROP_TEXT, DoubleToString(runtime_TS_Activation_Cents, 0));
   ObjectSetString(0, PNL + "tsdist_v", OBJPROP_TEXT, DoubleToString(runtime_TS_Distance_Cents, 0));
   ObjectSetString(0, PNL + "dist_v", OBJPROP_TEXT, DoubleToString(runtime_MaxDistEMA_Points, 0));
   ObjectSetString(0, PNL + "maxpos_v", OBJPROP_TEXT, IntegerToString(runtime_MaxPosiciones));
   ObjectSetString(0, PNL + "rsiob_v", OBJPROP_TEXT, IntegerToString(runtime_RSI_Overbought));
   ObjectSetString(0, PNL + "rsios_v", OBJPROP_TEXT, IntegerToString(runtime_RSI_Oversold));
   ObjectSetString(0, PNL + "wait_v", OBJPROP_TEXT, IntegerToString(runtime_SegundosEspera));
}

//+------------------------------------------------------------------+
//| Eventos de ratón para arrastrar y redimensionar                   |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == PNL + "min") { 
         isMinimized = !isMinimized; 
         if(isMinimized) {
            // Modo minimizado - ocultar todo excepto barra
            int x = hud_X, y = hud_Y, w = hud_W;
            ObjectsDeleteAll(0, PNL);
            CrRect("bg", x, y, w, 32, C'15,15,35', C'60,60,120', 2);
            CrRect("titlebar", x, y, w, 28, C'40,40,80', C'80,80,140', 1);
            string vName = "≡ CENT v8.3 | Cuenta: " + DoubleToString(accountBalanceCents, 0) + "¢";
            CrLabel("ttl", x+8, y+6, vName, clrWhite, 9, "Arial Bold");
            CrBtn("min", x+w-28, y+4, 22, 20, "+", C'60,60,100', clrWhite);
            CrRect("resize", x+w-12, y+20, 12, 12, C'80,80,120', C'100,100,160', 1);
         } else {
            CrearHUD();
         }
         return; 
      }
      if(sparam == PNL + "reset") { ResetDayPnL(); return; }
      if(sparam == PNL + "b_zen") { currentMode = MODE_ZEN; CrearHUD(); }
      if(sparam == PNL + "b_har") { currentMode = MODE_COSECHA; CrearHUD(); }
      if(sparam == PNL + "d_amb") { currentDir = DIR_AMBAS; CrearHUD(); }
      if(sparam == PNL + "d_buy") { currentDir = DIR_SOLO_COMPRAS; CrearHUD(); }
      if(sparam == PNL + "d_sel") { currentDir = DIR_SOLO_VENTAS; CrearHUD(); }
      if(sparam == PNL + "close") { CloseAll(); return; }
      if(sparam == PNL + "apply") {
         user_LoteManual = runtime_LoteManual; user_HedgeMultiplier = runtime_HedgeMultiplier;
         user_GatilloHedge_Cents = runtime_GatilloHedge_Cents; user_Target_Individual_Cents = runtime_Target_Individual_Cents;
         user_Net_Cycle_Cents = runtime_Net_Cycle_Cents; user_TS_Distance_Cents = runtime_TS_Distance_Cents;
         user_MaxDistEMA_Points = runtime_MaxDistEMA_Points; user_BE_Trigger_Cents = runtime_BE_Trigger_Cents;
         user_TS_Activation_Cents = runtime_TS_Activation_Cents; user_MaxPosiciones = runtime_MaxPosiciones;
         user_RSI_Overbought = runtime_RSI_Overbought; user_RSI_Oversold = runtime_RSI_Oversold;
         user_SegundosEspera = runtime_SegundosEspera; botStatus = "CONFIG OK"; ActualizarHUD(); return;
      }
      
      // Botones de ajuste de parámetros
      double step_lot = 0.001, step_mult = 0.1, step_cent = 10, step_point = 10;
      if(sparam == PNL + "lot_m") { runtime_LoteManual = MathMax(0.001, runtime_LoteManual - step_lot); ActualizarHUD(); }
      if(sparam == PNL + "lot_p") { runtime_LoteManual += step_lot; ActualizarHUD(); }
      if(sparam == PNL + "mult_m") { runtime_HedgeMultiplier = MathMax(1.0, runtime_HedgeMultiplier - step_mult); ActualizarHUD(); }
      if(sparam == PNL + "mult_p") { runtime_HedgeMultiplier += step_mult; ActualizarHUD(); }
      if(sparam == PNL + "gat_m") { runtime_GatilloHedge_Cents = MathMax(10, runtime_GatilloHedge_Cents - step_cent); ActualizarHUD(); }
      if(sparam == PNL + "gat_p") { runtime_GatilloHedge_Cents += step_cent; ActualizarHUD(); }
      if(sparam == PNL + "meta_m") { runtime_Net_Cycle_Cents = MathMax(30, runtime_Net_Cycle_Cents - step_cent); ActualizarHUD(); }
      if(sparam == PNL + "meta_p") { runtime_Net_Cycle_Cents += step_cent; ActualizarHUD(); }
      if(sparam == PNL + "target_m") { runtime_Target_Individual_Cents = MathMax(10, runtime_Target_Individual_Cents - step_cent); ActualizarHUD(); }
      if(sparam == PNL + "target_p") { runtime_Target_Individual_Cents += step_cent; ActualizarHUD(); }
      if(sparam == PNL + "be_m") { runtime_BE_Trigger_Cents = MathMax(5, runtime_BE_Trigger_Cents - 5); ActualizarHUD(); }
      if(sparam == PNL + "be_p") { runtime_BE_Trigger_Cents += 5; ActualizarHUD(); }
      if(sparam == PNL + "tsact_m") { runtime_TS_Activation_Cents = MathMax(10, runtime_TS_Activation_Cents - step_cent); ActualizarHUD(); }
      if(sparam == PNL + "tsact_p") { runtime_TS_Activation_Cents += step_cent; ActualizarHUD(); }
      if(sparam == PNL + "tsdist_m") { runtime_TS_Distance_Cents = MathMax(5, runtime_TS_Distance_Cents - 5); ActualizarHUD(); }
      if(sparam == PNL + "tsdist_p") { runtime_TS_Distance_Cents += 5; ActualizarHUD(); }
      if(sparam == PNL + "dist_m") { runtime_MaxDistEMA_Points = MathMax(50, runtime_MaxDistEMA_Points - step_point); ActualizarHUD(); }
      if(sparam == PNL + "dist_p") { runtime_MaxDistEMA_Points += step_point; ActualizarHUD(); }
      if(sparam == PNL + "maxpos_m") { runtime_MaxPosiciones = MathMax(1, runtime_MaxPosiciones - 1); ActualizarHUD(); }
      if(sparam == PNL + "maxpos_p") { runtime_MaxPosiciones += 1; ActualizarHUD(); }
      if(sparam == PNL + "rsiob_m") { runtime_RSI_Overbought = MathMax(50, runtime_RSI_Overbought - 1); ActualizarHUD(); }
      if(sparam == PNL + "rsiob_p") { runtime_RSI_Overbought = MathMin(90, runtime_RSI_Overbought + 1); ActualizarHUD(); }
      if(sparam == PNL + "rsios_m") { runtime_RSI_Oversold = MathMax(10, runtime_RSI_Oversold - 1); ActualizarHUD(); }
      if(sparam == PNL + "rsios_p") { runtime_RSI_Oversold = MathMin(50, runtime_RSI_Oversold + 1); ActualizarHUD(); }
      if(sparam == PNL + "wait_m") { runtime_SegundosEspera = MathMax(5, runtime_SegundosEspera - 5); ActualizarHUD(); }
      if(sparam == PNL + "wait_p") { runtime_SegundosEspera += 5; ActualizarHUD(); }
      
      ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
   }
   
   // Arrastre desde la barra de título
   if(id == CHARTEVENT_MOUSE_MOVE) {
      int x = (int)lparam;
      int y = (int)dparam;
      
      if(sparam == PNL + "titlebar") {
         if(!dragging) {
            dragging = true;
            dragStartX = x - hud_X;
            dragStartY = y - hud_Y;
         }
         if(dragging) {
            hud_X = x - dragStartX;
            hud_Y = y - dragStartY;
            hud_X = MathMax(0, MathMin(hud_X, (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS) - hud_W));
            hud_Y = MathMax(0, MathMin(hud_Y, (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS) - hud_H));
            CrearHUD();
         }
      } else if(sparam == PNL + "resize") {
         if(!resizing) {
            resizing = true;
            resizeStartW = hud_W;
            resizeStartH = hud_H;
            dragStartX = x;
            dragStartY = y;
         }
         if(resizing) {
            int deltaX = x - dragStartX;
            int deltaY = y - dragStartY;
            hud_W = MathMax(250, resizeStartW + deltaX);
            hud_H = MathMax(400, resizeStartH + deltaY);
            CrearHUD();
         }
      } else {
         dragging = false;
         resizing = false;
      }
   }
}

void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bw=1) {
   ObjectCreate(0, PNL + n, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, PNL + n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, PNL + n, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, PNL + n, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, PNL + n, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, PNL + n, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, PNL + n, OBJPROP_COLOR, bd);
   ObjectSetInteger(0, PNL + n, OBJPROP_ZORDER, 100);
}

void CrLabel(string n, int x, int y, string t, color c, int s, string f="Segoe UI") {
   ObjectCreate(0, PNL + n, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, PNL + n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, PNL + n, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, PNL + n, OBJPROP_TEXT, t);
   ObjectSetInteger(0, PNL + n, OBJPROP_COLOR, c);
   ObjectSetInteger(0, PNL + n, OBJPROP_FONTSIZE, s);
   ObjectSetString(0, PNL + n, OBJPROP_FONT, f);
   ObjectSetInteger(0, PNL + n, OBJPROP_ZORDER, 101);
}

void CrBtn(string n, int x, int y, int w, int h, string t, color bg, color tc) {
   ObjectCreate(0, PNL + n, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, PNL + n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, PNL + n, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, PNL + n, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, PNL + n, OBJPROP_YSIZE, h);
   ObjectSetString(0, PNL + n, OBJPROP_TEXT, t);
   ObjectSetInteger(0, PNL + n, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, PNL + n, OBJPROP_COLOR, tc);
   ObjectSetInteger(0, PNL + n, OBJPROP_ZORDER, 102);
}
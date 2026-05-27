//+------------------------------------------------------------------+
//|                                    XAUUSD_CENT_HUD_TotalControl  |
//|                           Versión 8.1 - HUD optimizado           |
//|                                   Con reset PNL y mejor visual   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "8.10"
#property description "HUD completo | Optimizado para cuentas CENT"
#property description "Lote ajustable 0.001 | Reset PNL | Indicadores visibles"

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
input bool      user_ShowIndicators = true;   // Mostrar EMA y RSI en gráfico

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
bool           remotePaused = false, isMinimized = false;
ENUM_MODE      currentMode;
ENUM_DIR       currentDir;
string         botStatus = "TRABAJANDO", commentTag = "CENT_GOLD_81";
double         dayPnL_Cents = 0;
datetime       lastSync = 0, coolingEndTime = 0, lastTradeClose = 0;
double         tickSize, tickValue;
double         accountBalanceCents;
datetime       dayStartTime;  // Para reset de PNL

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
   
   accountBalanceCents = AccountInfoDouble(ACCOUNT_BALANCE) * 100.0;
   
   // Inicializar PNL del día
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   dayStartTime = StructToTime(dt);
   dayPnL_Cents = CalculateDayProfitCents();
   
   if(_Symbol == "BTCUSD" || _Symbol == "BTCUSD.bit") commentTag = "CENT_BTC_81";
   
   // Indicadores
   h_ema20 = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   h_ema50 = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
   h_rsi   = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   
   if(user_ShowIndicators) {
      ChartIndicatorAdd(0, 0, h_ema20);
      ChartIndicatorAdd(0, 0, h_ema50);
      ChartIndicatorAdd(0, 1, h_rsi);
   }
   
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
//| Protección (igual que antes, simplificado por espacio)          |
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
      
      if(profitCents >= runtime_Target_Individual_Cents) {
         trade.PositionClose(ticket);
         lastTradeClose = TimeCurrent();
         continue;
      }
      
      if(runtime_BE_Trigger_Cents > 0 && profitCents >= runtime_BE_Trigger_Cents) {
         double bePrice = openPrice + (type == POSITION_TYPE_BUY ? 10 * _Point : -10 * _Point);
         if((type == POSITION_TYPE_BUY && (sl < bePrice || sl == 0)) ||
            (type == POSITION_TYPE_SELL && (sl > bePrice || sl == 0))) {
            trade.PositionModify(ticket, bePrice, 0);
         }
      }
      
      if(runtime_TS_Activation_Cents > 0 && profitCents >= runtime_TS_Activation_Cents) {
         double pointsDist = ConvertCentsToPoints(runtime_TS_Distance_Cents, posInfo.Volume());
         if(pointsDist <= 0) continue;
         
         double newSL;
         if(type == POSITION_TYPE_BUY) {
            newSL = currentPrice - pointsDist * _Point;
            if(newSL > sl + user_TS_Step_Points * _Point)
               trade.PositionModify(ticket, newSL, 0);
         } else {
            newSL = currentPrice + pointsDist * _Point;
            if(newSL < sl - user_TS_Step_Points * _Point || sl == 0)
               trade.PositionModify(ticket, newSL, 0);
         }
      }
   }
   
   if(total >= 2 && netCents >= runtime_Net_Cycle_Cents) {
      CloseAll();
      coolingEndTime = TimeCurrent() + 120;
   }
}

void ManageStrike() {
   if(PositionsTotalBots() >= runtime_MaxPosiciones) {
      DeletePendings();
      return;
   }
   if(TimeCurrent() < lastTradeClose + runtime_SegundosEspera) {
      botStatus = "ESPERANDO";
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
      botStatus = "PRECIO LEJOS";
      return;
   }
   
   int totalPos = PositionsTotalBots();
   
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
   double mainProfitCents = 0;
   ENUM_POSITION_TYPE mainType = -1;
   bool hasHedge = false;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Magic() != activeMagic) continue;
      if(mainTicket == 0) {
         mainTicket = posInfo.Ticket();
         mainType = posInfo.PositionType();
         mainProfitCents = GetPositionProfitCents(mainTicket);
      } else {
         if(posInfo.PositionType() != mainType) hasHedge = true;
      }
   }
   
   if(!hasHedge && mainProfitCents <= -runtime_GatilloHedge_Cents) {
      double hedgeLot = NormalizeDouble(runtime_LoteManual * runtime_HedgeMultiplier, 3);
      double hedgePrice = (mainType == POSITION_TYPE_BUY) ? bid : ask;
      if(mainType == POSITION_TYPE_BUY)
         trade.Sell(hedgeLot, _Symbol, hedgePrice, 0, 0, commentTag + "_H");
      else
         trade.Buy(hedgeLot, _Symbol, hedgePrice, 0, 0, commentTag + "_H");
   }
}

double CalculateDayProfitCents() {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   datetime todayStart = StructToTime(dt);
   HistorySelect(todayStart, TimeCurrent());
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
   dayPnL_Cents = 0;
   botStatus = "PNL RESETEADO";
   ActualizarHUD();
}

void CloseAll() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic() == activeMagic)
         trade.PositionClose(posInfo.Ticket());
   }
}

void DeletePendings() {
   for(int i = 0; i < OrdersTotal(); i++) {
      ulong orderTicket = OrderGetTicket(i);
      if(orderTicket > 0) {
         trade.OrderDelete(orderTicket);
      }
   }
}

int PositionsTotalBots() {
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic() == activeMagic)
         count++;
   }
   return count;
}

double GetNetProfitCents() {
   double net = 0;
   for(int i = 0; i < PositionsTotal(); i++) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic() == activeMagic)
         net += posInfo.Profit() + posInfo.Swap() + posInfo.Commission();
   }
   return GetProfitInCents(net);
}

bool IsTradingTime() {
   if(!user_EnableTimeFilter) return true;
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   return (dt.hour >= user_StartHour1 && dt.hour < user_EndHour1);
}

void SyncWeb() {}

//+------------------------------------------------------------------+
//| HUD mejorado con reset PNL y botones bien alineados              |
//+------------------------------------------------------------------+
void CrearHUD() {
   ObjectsDeleteAll(0, PNL);
   int x = 15, y = 15, w = 320, h = 680;
   if(isMinimized) { w = 200; h = 50; }
   CrRect("bg", x, y, w, h, C'15,15,35', C'60,60,120', 2);
   string vName = "CENT v8.1 | Cuenta: " + DoubleToString(accountBalanceCents, 0) + "¢";
   CrLabel("ttl", x+15, y+10, vName, clrWhite, 9, "Arial Bold");
   if(isMinimized) {
      CrBtn("min", x+w-25, y+10, 20, 20, "+", C'40,40,80', clrWhite);
      return;
   }
   CrBtn("min", x+w-25, y+10, 20, 20, "-", C'40,40,80', clrWhite);
   
   // PnL y Estado con botón reset
   CrLabel("pL", x+15, y+45, "PNL HOY (¢):", C'150,150,200', 8);
   CrLabel("pV", x+120, y+45, "0.00 ¢", clrWhite, 10, "Arial Bold");
   CrBtn("reset", x+220, y+40, 60, 20, "RESET", C'80,80,120', clrWhite);
   
   CrLabel("stL", x+15, y+70, "ESTADO:", C'150,150,200', 8);
   CrLabel("stV", x+120, y+70, botStatus, C'0,255,127', 9);
   
   int py = y + 100;
   int col1x = 15, col2x = 140, btnX = 230, btnW = 25;
   
   // LOTE BASE
   CrLabel("lot_l", col1x, py, "LOTE BASE:", C'150,150,200', 8);
   CrLabel("lot_v", col2x, py, DoubleToString(runtime_LoteManual, 3), clrWhite, 9, "Consolas");
   CrBtn("lot_m", btnX, py-3, btnW, 18, "-", C'40,40,70', clrWhite);
   CrBtn("lot_p", btnX+30, py-3, btnW, 18, "+", C'40,40,70', clrWhite);
   
   // MULTIPLICADOR
   CrLabel("mult_l", col1x, py+25, "MULTIPLICADOR:", C'150,150,200', 8);
   CrLabel("mult_v", col2x, py+25, DoubleToString(runtime_HedgeMultiplier, 1), clrWhite, 9, "Consolas");
   CrBtn("mult_m", btnX, py+22, btnW, 18, "-", C'40,40,70', clrWhite);
   CrBtn("mult_p", btnX+30, py+22, btnW, 18, "+", C'40,40,70', clrWhite);
   CrLabel("rec_v", col2x+65, py+25, "→ " + DoubleToString(runtime_LoteManual * runtime_HedgeMultiplier, 3), C'100,200,100', 8);
   
   // GATILLO HEDGE
   CrLabel("gat_l", col1x, py+50, "GATILLO HEDGE (¢):", C'150,150,200', 8);
   CrLabel("gat_v", col2x, py+50, DoubleToString(runtime_GatilloHedge_Cents, 0), clrWhite, 9, "Consolas");
   CrBtn("gat_m", btnX, py+47, btnW, 18, "-", C'40,40,70', clrWhite);
   CrBtn("gat_p", btnX+30, py+47, btnW, 18, "+", C'40,40,70', clrWhite);
   
   // META CCLO
   CrLabel("meta_l", col1x, py+75, "META CCLO (¢):", C'150,150,200', 8);
   CrLabel("meta_v", col2x, py+75, DoubleToString(runtime_Net_Cycle_Cents, 0), clrWhite, 9, "Consolas");
   CrBtn("meta_m", btnX, py+72, btnW, 18, "-", C'40,40,70', clrWhite);
   CrBtn("meta_p", btnX+30, py+72, btnW, 18, "+", C'40,40,70', clrWhite);
   
   // OBJETIVO
   CrLabel("target_l", col1x, py+100, "OBJETIVO (¢):", C'150,150,200', 8);
   CrLabel("target_v", col2x, py+100, DoubleToString(runtime_Target_Individual_Cents, 0), clrWhite, 9, "Consolas");
   CrBtn("target_m", btnX, py+97, btnW, 18, "-", C'40,40,70', clrWhite);
   CrBtn("target_p", btnX+30, py+97, btnW, 18, "+", C'40,40,70', clrWhite);
   
   // BE TRIGGER
   CrLabel("be_l", col1x, py+125, "BE TRIGGER (¢):", C'150,150,200', 8);
   CrLabel("be_v", col2x, py+125, DoubleToString(runtime_BE_Trigger_Cents, 0), clrWhite, 9, "Consolas");
   CrBtn("be_m", btnX, py+122, btnW, 18, "-", C'40,40,70', clrWhite);
   CrBtn("be_p", btnX+30, py+122, btnW, 18, "+", C'40,40,70', clrWhite);
   
   // TS ACTIVACIÓN
   CrLabel("tsact_l", col1x, py+150, "TS ACTIVACIÓN (¢):", C'150,150,200', 8);
   CrLabel("tsact_v", col2x, py+150, DoubleToString(runtime_TS_Activation_Cents, 0), clrWhite, 9, "Consolas");
   CrBtn("tsact_m", btnX, py+147, btnW, 18, "-", C'40,40,70', clrWhite);
   CrBtn("tsact_p", btnX+30, py+147, btnW, 18, "+", C'40,40,70', clrWhite);
   
   // T-STOP DIST
   CrLabel("tsdist_l", col1x, py+175, "T-STOP DIST (¢):", C'150,150,200', 8);
   CrLabel("tsdist_v", col2x, py+175, DoubleToString(runtime_TS_Distance_Cents, 0), clrWhite, 9, "Consolas");
   CrBtn("tsdist_m", btnX, py+172, btnW, 18, "-", C'40,40,70', clrWhite);
   CrBtn("tsdist_p", btnX+30, py+172, btnW, 18, "+", C'40,40,70', clrWhite);
   
   // DIST LIMIT
   CrLabel("dist_l", col1x, py+200, "DIST LIMIT (pts):", C'150,150,200', 8);
   CrLabel("dist_v", col2x, py+200, DoubleToString(runtime_MaxDistEMA_Points, 0), clrWhite, 9, "Consolas");
   CrBtn("dist_m", btnX, py+197, btnW, 18, "-", C'40,40,70', clrWhite);
   CrBtn("dist_p", btnX+30, py+197, btnW, 18, "+", C'40,40,70', clrWhite);
   
   // MAX POSICIONES
   CrLabel("maxpos_l", col1x, py+225, "MAX POSICIONES:", C'150,150,200', 8);
   CrLabel("maxpos_v", col2x, py+225, IntegerToString(runtime_MaxPosiciones), clrWhite, 9, "Consolas");
   CrBtn("maxpos_m", btnX, py+222, btnW, 18, "-", C'40,40,70', clrWhite);
   CrBtn("maxpos_p", btnX+30, py+222, btnW, 18, "+", C'40,40,70', clrWhite);
   
   // RSI LÍMITES
   CrLabel("rsiob_l", col1x, py+250, "RSI SOBRECOMPRA:", C'150,150,200', 8);
   CrLabel("rsiob_v", col2x, py+250, IntegerToString(runtime_RSI_Overbought), clrWhite, 9, "Consolas");
   CrBtn("rsiob_m", btnX, py+247, btnW, 18, "-", C'40,40,70', clrWhite);
   CrBtn("rsiob_p", btnX+30, py+247, btnW, 18, "+", C'40,40,70', clrWhite);
   
   CrLabel("rsios_l", col1x, py+275, "RSI SOBREVENTA:", C'150,150,200', 8);
   CrLabel("rsios_v", col2x, py+275, IntegerToString(runtime_RSI_Oversold), clrWhite, 9, "Consolas");
   CrBtn("rsios_m", btnX, py+272, btnW, 18, "-", C'40,40,70', clrWhite);
   CrBtn("rsios_p", btnX+30, py+272, btnW, 18, "+", C'40,40,70', clrWhite);
   
   // TIEMPO DE ESPERA
   CrLabel("wait_l", col1x, py+300, "ESPERA (seg):", C'150,150,200', 8);
   CrLabel("wait_v", col2x, py+300, IntegerToString(runtime_SegundosEspera), clrWhite, 9, "Consolas");
   CrBtn("wait_m", btnX, py+297, btnW, 18, "-", C'40,40,70', clrWhite);
   CrBtn("wait_p", btnX+30, py+297, btnW, 18, "+", C'40,40,70', clrWhite);
   
   // Modos y dirección (botones más anchos para que no se corten)
   int my = py + 335;
   CrBtn("b_zen", x+10, my, 95, 30, "ZEN", currentMode == MODE_ZEN ? C'0,100,255' : C'40,40,70', clrWhite);
   CrBtn("b_har", x+115, my, 95, 30, "COSECHA", currentMode == MODE_COSECHA ? C'255,100,0' : C'40,40,70', clrWhite);
   
   // Botones dirección más anchos
   CrBtn("d_amb", x+10, my+40, 70, 28, "AMBAS", currentDir == DIR_AMBAS ? C'60,150,255' : C'40,40,70', clrWhite);
   CrBtn("d_buy", x+90, my+40, 80, 28, "SOLO BUY", currentDir == DIR_SOLO_COMPRAS ? C'0,200,100' : C'40,40,70', clrWhite);
   CrBtn("d_sel", x+180, my+40, 80, 28, "SOLO SELL", currentDir == DIR_SOLO_VENTAS ? C'220,50,50' : C'40,40,70', clrWhite);
   
   // Botones principales
   CrBtn("apply", x+10, my+85, 295, 35, "APLICAR CAMBIOS", C'0,100,150', clrWhite);
   CrBtn("close", x+10, my+125, 295, 35, "CERRAR TODO", C'200,40,40', clrWhite);
}

void ActualizarHUD() {
   if(isMinimized) return;
   
   accountBalanceCents = AccountInfoDouble(ACCOUNT_BALANCE) * 100.0;
   ObjectSetString(0, PNL + "ttl", OBJPROP_TEXT, "CENT v8.1 | Cuenta: " + DoubleToString(accountBalanceCents, 0) + "¢");
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

void OnChartEvent(const int id, const long &lp, const double &dp, const string &sp) {
   if(id != CHARTEVENT_OBJECT_CLICK) return;
   
   if(sp == PNL + "min") { isMinimized = !isMinimized; CrearHUD(); return; }
   if(sp == PNL + "reset") { ResetDayPnL(); return; }
   if(sp == PNL + "b_zen") { currentMode = MODE_ZEN; CrearHUD(); }
   if(sp == PNL + "b_har") { currentMode = MODE_COSECHA; CrearHUD(); }
   if(sp == PNL + "d_amb") { currentDir = DIR_AMBAS; CrearHUD(); }
   if(sp == PNL + "d_buy") { currentDir = DIR_SOLO_COMPRAS; CrearHUD(); }
   if(sp == PNL + "d_sel") { currentDir = DIR_SOLO_VENTAS; CrearHUD(); }
   if(sp == PNL + "close") { CloseAll(); return; }
   
   if(sp == PNL + "apply") {
      user_LoteManual = runtime_LoteManual;
      user_HedgeMultiplier = runtime_HedgeMultiplier;
      user_GatilloHedge_Cents = runtime_GatilloHedge_Cents;
      user_Target_Individual_Cents = runtime_Target_Individual_Cents;
      user_Net_Cycle_Cents = runtime_Net_Cycle_Cents;
      user_TS_Distance_Cents = runtime_TS_Distance_Cents;
      user_MaxDistEMA_Points = runtime_MaxDistEMA_Points;
      user_BE_Trigger_Cents = runtime_BE_Trigger_Cents;
      user_TS_Activation_Cents = runtime_TS_Activation_Cents;
      user_MaxPosiciones = runtime_MaxPosiciones;
      user_RSI_Overbought = runtime_RSI_Overbought;
      user_RSI_Oversold = runtime_RSI_Oversold;
      user_SegundosEspera = runtime_SegundosEspera;
      botStatus = "CONFIG OK";
      ActualizarHUD();
      return;
   }
   
   // Ajustes de parámetros
   double step_lot = 0.001;
   double step_mult = 0.1;
   double step_cent = 10;
   double step_point = 10;
   
   if(sp == PNL + "lot_m") { runtime_LoteManual = MathMax(0.001, runtime_LoteManual - step_lot); ActualizarHUD(); }
   if(sp == PNL + "lot_p") { runtime_LoteManual += step_lot; ActualizarHUD(); }
   if(sp == PNL + "mult_m") { runtime_HedgeMultiplier = MathMax(1.0, runtime_HedgeMultiplier - step_mult); ActualizarHUD(); }
   if(sp == PNL + "mult_p") { runtime_HedgeMultiplier += step_mult; ActualizarHUD(); }
   if(sp == PNL + "gat_m") { runtime_GatilloHedge_Cents = MathMax(10, runtime_GatilloHedge_Cents - step_cent); ActualizarHUD(); }
   if(sp == PNL + "gat_p") { runtime_GatilloHedge_Cents += step_cent; ActualizarHUD(); }
   if(sp == PNL + "meta_m") { runtime_Net_Cycle_Cents = MathMax(30, runtime_Net_Cycle_Cents - step_cent); ActualizarHUD(); }
   if(sp == PNL + "meta_p") { runtime_Net_Cycle_Cents += step_cent; ActualizarHUD(); }
   if(sp == PNL + "target_m") { runtime_Target_Individual_Cents = MathMax(10, runtime_Target_Individual_Cents - step_cent); ActualizarHUD(); }
   if(sp == PNL + "target_p") { runtime_Target_Individual_Cents += step_cent; ActualizarHUD(); }
   if(sp == PNL + "be_m") { runtime_BE_Trigger_Cents = MathMax(5, runtime_BE_Trigger_Cents - 5); ActualizarHUD(); }
   if(sp == PNL + "be_p") { runtime_BE_Trigger_Cents += 5; ActualizarHUD(); }
   if(sp == PNL + "tsact_m") { runtime_TS_Activation_Cents = MathMax(10, runtime_TS_Activation_Cents - step_cent); ActualizarHUD(); }
   if(sp == PNL + "tsact_p") { runtime_TS_Activation_Cents += step_cent; ActualizarHUD(); }
   if(sp == PNL + "tsdist_m") { runtime_TS_Distance_Cents = MathMax(5, runtime_TS_Distance_Cents - 5); ActualizarHUD(); }
   if(sp == PNL + "tsdist_p") { runtime_TS_Distance_Cents += 5; ActualizarHUD(); }
   if(sp == PNL + "dist_m") { runtime_MaxDistEMA_Points = MathMax(50, runtime_MaxDistEMA_Points - step_point); ActualizarHUD(); }
   if(sp == PNL + "dist_p") { runtime_MaxDistEMA_Points += step_point; ActualizarHUD(); }
   if(sp == PNL + "maxpos_m") { runtime_MaxPosiciones = MathMax(1, runtime_MaxPosiciones - 1); ActualizarHUD(); }
   if(sp == PNL + "maxpos_p") { runtime_MaxPosiciones += 1; ActualizarHUD(); }
   if(sp == PNL + "rsiob_m") { runtime_RSI_Overbought = MathMax(50, runtime_RSI_Overbought - 1); ActualizarHUD(); }
   if(sp == PNL + "rsiob_p") { runtime_RSI_Overbought = MathMin(90, runtime_RSI_Overbought + 1); ActualizarHUD(); }
   if(sp == PNL + "rsios_m") { runtime_RSI_Oversold = MathMax(10, runtime_RSI_Oversold - 1); ActualizarHUD(); }
   if(sp == PNL + "rsios_p") { runtime_RSI_Oversold = MathMin(50, runtime_RSI_Oversold + 1); ActualizarHUD(); }
   if(sp == PNL + "wait_m") { runtime_SegundosEspera = MathMax(5, runtime_SegundosEspera - 5); ActualizarHUD(); }
   if(sp == PNL + "wait_p") { runtime_SegundosEspera += 5; ActualizarHUD(); }
   
   ObjectSetInteger(0, sp, OBJPROP_STATE, false);
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
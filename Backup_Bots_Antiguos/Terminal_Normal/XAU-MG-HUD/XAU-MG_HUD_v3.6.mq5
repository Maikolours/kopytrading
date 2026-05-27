//+------------------------------------------------------------------+
//| XAU-MG_HUD_v3.6.mq5 - AMETRALLADORA                              |
//| Versión Definitiva - Prioridad a la Tendencia                    |
//| Fibonacci solo opera en dirección de la tendencia principal      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "3.60"
#property description "AMETRALLADORA v3.6 - Prioridad a la Tendencia"
#property description "Fibonacci solo opera en dirección de la tendencia principal"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- ENUMS
enum ENUM_MODE { MODE_ZEN, MODE_COSECHA };
enum ENUM_DIR  { DIR_AMBAS, DIR_SOLO_COMPRAS, DIR_SOLO_VENTAS };
enum ENUM_ACCOUNT_TYPE { ACCOUNT_AUTO, ACCOUNT_REAL, ACCOUNT_CENT };

//--- PARÁMETROS INPUT
sinput string   LicenseKey        = "XAU-MG";
input string    PurchaseID        = "";
input ENUM_ACCOUNT_TYPE AccountType = ACCOUNT_AUTO;
input double    user_MaxDrawdownPercent = 15.0;
input bool      user_ShowIndicators = true;
input bool      user_RequireConfluence = false;

//--- PARÁMETROS DE ESTRATEGIA
double   user_MagicNumber        = 700842;
double   user_MaxPosiciones      = 2;
double   user_LoteManual         = 0.015;
double   user_HedgeMultiplier    = 1.5;
double   user_GatilloHedge       = 40;
double   user_Target_Individual  = 150;
double   user_Net_Cycle          = 250;
double   user_MaxDistEMA_Points  = 500;
double   user_BE_Trigger         = 30;
double   user_TS_Activation      = 50;
int      user_RSI_Overbought     = 75;
int      user_RSI_Oversold       = 25;
int      user_SegundosEspera     = 15;

//--- Fibonacci
double   user_Fibo_618 = 0.618;
double   user_Fibo_786 = 0.786;
double   user_Fibo_272 = 0.272;
double   user_Fibo_618_ext = 0.618;

//--- ATR
int      user_ATR_Period = 14;
double   user_ATR_Multiplier = 2.0;

//--- Smart Recovery
double   user_SmartRecovery_RiskMax = 3.0;

//--- Emergency Exit
double   user_Emergency_Drawdown = 5.0;

//--- GLOBALES
CTrade         trade;
CPositionInfo  posInfo;
CSymbolInfo    symInfo;
int            activeMagic, h_ema20, h_ema50, h_rsi, h_atr, h_ema_h1;
bool           isMinimized = false;
bool           remotePaused = false;
ENUM_MODE      currentMode;
ENUM_DIR       currentDir;
string         botStatus = "INICIALIZANDO...";
double         dayPnL_Units = 0;
datetime       coolingEndTime = 0, lastTradeClose = 0;
datetime       emergencyEndTime = 0;
bool           emergencyActive = false;
bool           webConnected = false;
datetime       lastWebSync = 0;

//--- Cuenta
double         accountBalance;
datetime       pnlResetTime = 0;
bool           isCentAccount = false;
double         unitMultiplier = 1.0;

//--- Fibonacci
datetime       fibo_fixed_time = 0;
double         fibo_0 = 0, fibo_100 = 0;
double         fibo_618 = 0, fibo_786 = 0;
double         tp1 = 0, tp2 = 0;
int            fibo_direction = 0;
bool           fibo_valid = false;
string         expectedSignal = "DETECTANDO...";
string         currentTrend = "DETECTANDO...";
color          trendColor = clrYellow;

//--- Análisis de velas
string         lastCandlePattern = "";
int            lastCandleSignal = 0;
double         lastPatternPrice = 0;
datetime       lastPatternTime = 0;

//--- Confluencia
int            confluenceCount = 0;
string         confluenceSources = "";

//--- HUD posición y tamaño
int      hud_X = 10;
int      hud_Y = 10;
int      hud_W = 580;
int      hud_H = 820;
bool     dragging = false;
int      dragStartX, dragStartY;
bool     resizing = false;
int      resizeStartW, resizeStartH;

//--- Runtime
double runtime_LoteManual;
double runtime_HedgeMultiplier;
double runtime_GatilloHedge;
double runtime_Target_Individual;
double runtime_Net_Cycle;
double runtime_MaxDistEMA_Points;
double runtime_BE_Trigger;
double runtime_TS_Activation;
int    runtime_MaxPosiciones;
int    runtime_RSI_Overbought;
int    runtime_RSI_Oversold;
int    runtime_SegundosEspera;

//--- Variables para campos de texto
string edit_lot = "", edit_gat = "", edit_tar = "", edit_meta = "";
string edit_be = "", edit_ts = "", edit_dist = "", edit_wait = "";

#define PNL_TAG "XAU_HUD_V3"

//+------------------------------------------------------------------+
//| DETECTAR TIPO DE CUENTA                                          |
//+------------------------------------------------------------------+
void DetectAccountType() {
   if(AccountType == ACCOUNT_REAL) {
      isCentAccount = false;
      unitMultiplier = 1.0;
   } else if(AccountType == ACCOUNT_CENT) {
      isCentAccount = true;
      unitMultiplier = 100.0;
   } else {
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      if(balance > 5000 && minLot <= 0.01) {
         isCentAccount = true;
         unitMultiplier = 100.0;
      } else {
         isCentAccount = false;
         unitMultiplier = 1.0;
      }
   }
}

//+------------------------------------------------------------------+
//| FORMATEAR VALOR                                                  |
//+------------------------------------------------------------------+
string FormatValue(double value) {
   if(isCentAccount) {
      return DoubleToString(value, 0) + "¢ (" + DoubleToString(value / 100.0, 2) + " $)";
   }
   return DoubleToString(value, 2) + " $";
}

//+------------------------------------------------------------------+
//| 1. TENDENCIA (EMA 20/50)                                        |
//+------------------------------------------------------------------+
void UpdateTrend() {
   double emaF[1], emaS[1];
   if(CopyBuffer(h_ema20, 0, 0, 1, emaF) <= 0 || CopyBuffer(h_ema50, 0, 0, 1, emaS) <= 0) return;
   
   if(emaF[0] > emaS[0]) {
      currentTrend = "ALCISTA ▲";
      trendColor = C'0,255,0';
   } else if(emaF[0] < emaS[0]) {
      currentTrend = "BAJISTA ▼";
      trendColor = C'255,0,0';
   } else {
      currentTrend = "LATERAL -";
      trendColor = clrYellow;
   }
}

//+------------------------------------------------------------------+
//| 2. DETECTAR IMPULSO EN M15                                       |
//+------------------------------------------------------------------+
bool DetectImpulse(int &direction, double &startPrice, double &endPrice) {
   MqlRates rates[];
   if(CopyRates(_Symbol, PERIOD_M15, 0, 15, rates) < 15) return false;
   
   int up_count = 0, down_count = 0;
   double max_high = 0, min_low = DBL_MAX;
   
   for(int i = 0; i < 10; i++) {
      if(rates[i].close > rates[i].open) up_count++;
      if(rates[i].close < rates[i].open) down_count++;
      
      if(rates[i].high > max_high) max_high = rates[i].high;
      if(rates[i].low < min_low) min_low = rates[i].low;
   }
   
   if(up_count >= 6) {
      direction = 1;
      startPrice = min_low;
      endPrice = max_high;
      return true;
   } else if(down_count >= 6) {
      direction = -1;
      startPrice = max_high;
      endPrice = min_low;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| 3. CALCULAR FIBONACCI                                            |
//+------------------------------------------------------------------+
void CalculateFibonacci() {
   int impulse_dir;
   double start, end;
   
   if(DetectImpulse(impulse_dir, start, end)) {
      fibo_0 = start;
      fibo_100 = end;
      fibo_direction = impulse_dir;
      double range = MathAbs(end - start);
      
      if(impulse_dir == 1) {
         fibo_618 = end - range * user_Fibo_618;
         fibo_786 = end - range * user_Fibo_786;
         tp1 = end + range * user_Fibo_272;
         tp2 = end + range * user_Fibo_618_ext;
      } else {
         fibo_618 = end + range * user_Fibo_618;
         fibo_786 = end + range * user_Fibo_786;
         tp1 = end - range * user_Fibo_272;
         tp2 = end - range * user_Fibo_618_ext;
      }
      
      fibo_fixed_time = TimeCurrent();
      fibo_valid = true;
      
      UpdateExpectedSignal();
      DrawFibonacciLevels();
   }
}

//+------------------------------------------------------------------+
//| 4. ACTUALIZAR SEÑAL ESPERADA (según tendencia + Fibonacci)       |
//+------------------------------------------------------------------+
void UpdateExpectedSignal() {
   double emaF[1], emaS[1];
   CopyBuffer(h_ema20, 0, 0, 1, emaF);
   CopyBuffer(h_ema50, 0, 0, 1, emaS);
   
   bool trend_up = (emaF[0] > emaS[0]);
   bool trend_down = (emaF[0] < emaS[0]);
   
   if(!fibo_valid) {
      expectedSignal = "DETECTANDO IMPULSO...";
      return;
   }
   
   if(trend_up && fibo_direction == 1) {
      expectedSignal = "COMPRA en zona " + DoubleToString(fibo_786, _Digits) + " - " + DoubleToString(fibo_618, _Digits);
   }
   else if(trend_down && fibo_direction == -1) {
      expectedSignal = "VENTA en zona " + DoubleToString(fibo_618, _Digits) + " - " + DoubleToString(fibo_786, _Digits);
   }
   else if(trend_up && fibo_direction == -1) {
      expectedSignal = "BUSCANDO NUEVO IMPULSO ALCISTA";
   }
   else if(trend_down && fibo_direction == 1) {
      expectedSignal = "BUSCANDO NUEVO IMPULSO BAJISTA";
   }
   else {
      expectedSignal = "TENDENCIA LATERAL - ESPERANDO";
   }
}

//+------------------------------------------------------------------+
//| 5. DIBUJAR FIBONACCI EN EL GRÁFICO                               |
//+------------------------------------------------------------------+
void DrawFibonacciLevels() {
   ObjectsDeleteAll(0, "FIBO_");
   if(!fibo_valid || fibo_0 == 0 || fibo_100 == 0) return;
   
   ObjectCreate(0, "FIBO_0", OBJ_HLINE, 0, 0, 0);
   ObjectSetDouble(0, "FIBO_0", OBJPROP_PRICE, fibo_0);
   ObjectSetInteger(0, "FIBO_0", OBJPROP_COLOR, clrDodgerBlue);
   ObjectSetInteger(0, "FIBO_0", OBJPROP_STYLE, STYLE_DASH);
   
   ObjectCreate(0, "FIBO_618", OBJ_HLINE, 0, 0, 0);
   ObjectSetDouble(0, "FIBO_618", OBJPROP_PRICE, fibo_618);
   ObjectSetInteger(0, "FIBO_618", OBJPROP_COLOR, clrGold);
   ObjectSetInteger(0, "FIBO_618", OBJPROP_WIDTH, 2);
   
   ObjectCreate(0, "FIBO_786", OBJ_HLINE, 0, 0, 0);
   ObjectSetDouble(0, "FIBO_786", OBJPROP_PRICE, fibo_786);
   ObjectSetInteger(0, "FIBO_786", OBJPROP_COLOR, clrOrange);
   ObjectSetInteger(0, "FIBO_786", OBJPROP_WIDTH, 2);
   
   ObjectCreate(0, "FIBO_100", OBJ_HLINE, 0, 0, 0);
   ObjectSetDouble(0, "FIBO_100", OBJPROP_PRICE, fibo_100);
   ObjectSetInteger(0, "FIBO_100", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, "FIBO_100", OBJPROP_STYLE, STYLE_DASH);
   
   datetime now = TimeCurrent();
   datetime future = now + 100 * 60;
   ObjectCreate(0, "FIBO_ZONE", OBJ_RECTANGLE, 0, now, fibo_786, future, fibo_618);
   ObjectSetInteger(0, "FIBO_ZONE", OBJPROP_COLOR, C'255,200,0');
   ObjectSetInteger(0, "FIBO_ZONE", OBJPROP_FILL, true);
   ObjectSetInteger(0, "FIBO_ZONE", OBJPROP_BACK, true);
}

//+------------------------------------------------------------------+
//| 6. ANÁLISIS PROFESIONAL DE VELAS (M5)                            |
//+------------------------------------------------------------------+
void AnalyzeCandlestick() {
   MqlRates rates[3];
   if(CopyRates(_Symbol, PERIOD_M5, 0, 3, rates) < 3) return;
   
   double body = MathAbs(rates[0].close - rates[0].open);
   double lower_wick = MathMin(rates[0].close, rates[0].open) - rates[0].low;
   double upper_wick = rates[0].high - MathMax(rates[0].close, rates[0].open);
   double total_range = rates[0].high - rates[0].low;
   
   if(lower_wick > body * 2 && upper_wick < body && rates[0].close > rates[0].open) {
      lastCandlePattern = "MARTILLO 🔨 (COMPRA)";
      lastCandleSignal = 1;
      return;
   }
   
   if(upper_wick > body * 2 && lower_wick < body && rates[0].close < rates[0].open) {
      lastCandlePattern = "ESTRELLA FUGAZ ⭐ (VENTA)";
      lastCandleSignal = -1;
      return;
   }
   
   if(body <= total_range * 0.1) {
      lastCandlePattern = "DOJI ✚ (INDECISIÓN)";
      lastCandleSignal = 0;
      return;
   }
   
   bool prev_bearish = rates[1].close < rates[1].open;
   bool curr_bullish = rates[0].close > rates[0].open;
   bool engulfs_up = rates[0].high > rates[1].high && rates[0].low < rates[1].low;
   if(prev_bearish && curr_bullish && engulfs_up) {
      lastCandlePattern = "ENVOLVENTE ALCISTA 📈 (COMPRA)";
      lastCandleSignal = 1;
      return;
   }
   
   bool prev_bullish = rates[1].close > rates[1].open;
   bool curr_bearish = rates[0].close < rates[0].open;
   bool engulfs_down = rates[0].high > rates[1].high && rates[0].low < rates[1].low;
   if(prev_bullish && curr_bearish && engulfs_down) {
      lastCandlePattern = "ENVOLVENTE BAJISTA 📉 (VENTA)";
      lastCandleSignal = -1;
      return;
   }
   
   lastCandlePattern = "VELA NEUTRA";
   lastCandleSignal = 0;
}

//+------------------------------------------------------------------+
//| 7. VERIFICAR CONFLUENCIA                                         |
//+------------------------------------------------------------------+
void CheckConfluence(double price) {
   confluenceCount = 0;
   confluenceSources = "";
   
   double ema20[1], ema50[1];
   CopyBuffer(h_ema20, 0, 0, 1, ema20);
   CopyBuffer(h_ema50, 0, 0, 1, ema50);
   
   if(MathAbs(price - ema20[0]) < 15 * _Point) {
      confluenceCount++;
      confluenceSources += "EMA20 ";
   }
   
   if(MathAbs(price - ema50[0]) < 15 * _Point) {
      confluenceCount++;
      confluenceSources += "EMA50 ";
   }
   
   double round_level = MathRound(price / 50) * 50;
   if(MathAbs(price - round_level) < 10 * _Point) {
      confluenceCount++;
      confluenceSources += "REDONDO ";
   }
}

//+------------------------------------------------------------------+
//| 8. VERIFICAR SI PRECIO ESTÁ EN ZONA FIBO                         |
//+------------------------------------------------------------------+
bool IsInFiboZone(double price) {
   if(!fibo_valid) return false;
   if(fibo_direction == 1) {
      return (price >= fibo_786 && price <= fibo_618);
   } else {
      return (price <= fibo_786 && price >= fibo_618);
   }
}

//+------------------------------------------------------------------+
//| 9. VERIFICAR SI PRECIO ESTÁ CERCA DE ZONA                        |
//+------------------------------------------------------------------+
bool IsNearFiboZone(double price, int tolerance = 15) {
   if(!fibo_valid) return false;
   double tolerance_price = tolerance * _Point;
   
   if(fibo_direction == 1) {
      return (price >= fibo_786 - tolerance_price && price <= fibo_618 + tolerance_price);
   } else {
      return (price <= fibo_786 + tolerance_price && price >= fibo_618 - tolerance_price);
   }
}

//+------------------------------------------------------------------+
//| FUNCIONES BÁSICAS                                                |
//+------------------------------------------------------------------+
double GetPositionProfitUnits(ulong ticket) {
   if(posInfo.SelectByTicket(ticket))
      return (posInfo.Profit() + posInfo.Swap() + posInfo.Commission()) * unitMultiplier;
   return 0;
}

double CalculateDayProfitUnits() {
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
         p += (HistoryDealGetDouble(ticket, DEAL_PROFIT) +
               HistoryDealGetDouble(ticket, DEAL_SWAP) +
               HistoryDealGetDouble(ticket, DEAL_COMMISSION)) * unitMultiplier;
   }
   return p;
}

void ResetDayPnL() {
   pnlResetTime = TimeCurrent();
   dayPnL_Units = 0;
   botStatus = "PNL RESETEADO";
   ActualizarHUD();
   dayPnL_Units = CalculateDayProfitUnits();
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

double GetNetProfitUnits() {
   double net = 0;
   for(int i = 0; i < PositionsTotal(); i++) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic() == activeMagic)
         net += (posInfo.Profit() + posInfo.Swap() + posInfo.Commission()) * unitMultiplier;
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

double GetTotalRiskPercent() {
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(balance <= 0) return 0;
   return (balance - equity) / balance * 100;
}

double GetATR() {
   double atr[1];
   if(CopyBuffer(h_atr, 0, 0, 1, atr) > 0) return atr[0];
   return 0;
}

//+------------------------------------------------------------------+
//| SINCRONIZACIÓN WEB                                               |
//+------------------------------------------------------------------+
void SyncWithWeb() {
   if(PurchaseID == "") return;
   if(TimeCurrent() < lastWebSync + 30) return;
   lastWebSync = TimeCurrent();
   
   string url = "https://www.kopytrading.com/api/sync-positions";
   string headers = "Content-Type: application/json\r\n";
   string postData = "{";
   postData += "\"purchaseId\":\"" + PurchaseID + "\",";
   postData += "\"productKey\":\"XAU-MG\",";
   postData += "\"account\":" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)) + ",";
   postData += "\"balance\":" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + ",";
   postData += "\"dayPnL\":" + DoubleToString(dayPnL_Units / unitMultiplier, 2) + ",";
   postData += "\"positions\":" + IntegerToString(GetPositionsCount()) + ",";
   postData += "\"status\":\"" + botStatus + "\"";
   postData += "}";
   
   char post[], result[];
   string resultHeaders;
   StringToCharArray(postData, post);
   
   int res = WebRequest("POST", url, headers, 5000, post, result, resultHeaders);
   webConnected = (res == 200);
}

//+------------------------------------------------------------------+
//| TRAILING STOP                                                    |
//+------------------------------------------------------------------+
void ManageTrailingATR() {
   double atr = GetATR();
   if(atr <= 0) return;
   double trailDistance = atr * user_ATR_Multiplier;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Magic() != activeMagic) continue;
      
      ulong ticket = posInfo.Ticket();
      double profitUnits = GetPositionProfitUnits(ticket);
      ENUM_POSITION_TYPE type = posInfo.PositionType();
      double sl = posInfo.StopLoss();
      double currentPrice = (type == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      if(profitUnits >= runtime_TS_Activation) {
         double newSL;
         if(type == POSITION_TYPE_BUY) {
            newSL = currentPrice - trailDistance;
            if(newSL > sl) trade.PositionModify(ticket, newSL, 0);
         } else {
            newSL = currentPrice + trailDistance;
            if(newSL < sl || sl == 0) trade.PositionModify(ticket, newSL, 0);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| SMART RECOVERY                                                   |
//+------------------------------------------------------------------+
void SmartRecovery() {
   if(GetPositionsCount() >= runtime_MaxPosiciones) return;
   
   ulong mainTicket = 0;
   double mainProfitUnits = 0;
   ENUM_POSITION_TYPE mainType = -1;
   bool hasHedge = false;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Magic() != activeMagic) continue;
      if(mainTicket == 0) {
         mainTicket = posInfo.Ticket();
         mainType = posInfo.PositionType();
         mainProfitUnits = GetPositionProfitUnits(mainTicket);
      } else {
         if(posInfo.PositionType() != mainType) hasHedge = true;
      }
   }
   
   if(hasHedge || mainProfitUnits >= 0) return;
   
   double currentPrice = (mainType == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   bool priceInZone = IsInFiboZone(currentPrice);
   
   double totalRisk = GetTotalRiskPercent();
   if(totalRisk > user_SmartRecovery_RiskMax) return;
   
   if(priceInZone && mainProfitUnits <= -runtime_GatilloHedge) {
      double recoveryLot = runtime_LoteManual;
      if(mainType == POSITION_TYPE_BUY) {
         trade.Sell(recoveryLot, _Symbol, currentPrice, 0, 0, "RECOVERY");
      } else {
         trade.Buy(recoveryLot, _Symbol, currentPrice, 0, 0, "RECOVERY");
      }
   }
}

//+------------------------------------------------------------------+
//| EMERGENCY EXIT                                                   |
//+------------------------------------------------------------------+
void CheckEmergencyExit() {
   double drawdownPercent = GetTotalRiskPercent();
   
   if(drawdownPercent >= user_Emergency_Drawdown && !emergencyActive) {
      emergencyActive = true;
      emergencyEndTime = TimeCurrent() + 24 * 3600;
      CloseAllPositions();
      remotePaused = true;
      botStatus = "⚠️ EMERGENCIA - DRAWDOWN " + DoubleToString(drawdownPercent, 1) + "%";
   }
   
   if(emergencyActive && TimeCurrent() >= emergencyEndTime) {
      emergencyActive = false;
      remotePaused = false;
      botStatus = "REACTIVADO";
   }
}

//+------------------------------------------------------------------+
//| PROTECCIÓN DE POSICIONES                                         |
//+------------------------------------------------------------------+
void ProtectAll() {
   double netUnits = GetNetProfitUnits();
   int total = GetPositionsCount();
   
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Magic() != activeMagic) continue;
      
      ulong ticket = posInfo.Ticket();
      double profitUnits = GetPositionProfitUnits(ticket);
      ENUM_POSITION_TYPE type = posInfo.PositionType();
      double sl = posInfo.StopLoss();
      double openPrice = posInfo.PriceOpen();
      
      if(profitUnits >= runtime_Target_Individual) {
         trade.PositionClose(ticket);
         lastTradeClose = TimeCurrent();
         continue;
      }
      
      if(runtime_BE_Trigger > 0 && profitUnits >= runtime_BE_Trigger) {
         double bePrice = openPrice + (type == POSITION_TYPE_BUY ? 10 * _Point : -10 * _Point);
         if((type == POSITION_TYPE_BUY && (sl < bePrice || sl == 0)) ||
            (type == POSITION_TYPE_SELL && (sl > bePrice || sl == 0))) {
            trade.PositionModify(ticket, bePrice, 0);
         }
      }
   }
   
   ManageTrailingATR();
   
   if(total >= 2 && netUnits >= runtime_Net_Cycle) {
      CloseAllPositions();
      coolingEndTime = TimeCurrent() + 120;
   }
}

//+------------------------------------------------------------------+
//| 10. ENTRADA CON PRIORIDAD A LA TENDENCIA (CORAZÓN DEL BOT)       |
//+------------------------------------------------------------------+
void CheckEntry() {
   if(GetPositionsCount() >= runtime_MaxPosiciones) return;
   if(TimeCurrent() < lastTradeClose + runtime_SegundosEspera) return;
   if(!fibo_valid) return;
   
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double priceNow = (fibo_direction == 1) ? ask : bid;
   
   double emaF[1], emaS[1];
   if(CopyBuffer(h_ema20, 0, 0, 1, emaF) <= 0 || CopyBuffer(h_ema50, 0, 0, 1, emaS) <= 0) return;
   
   bool trend_up = (emaF[0] > emaS[0]);
   bool trend_down = (emaF[0] < emaS[0]);
   
   // REGLA DE ORO: No operar en contra de la tendencia
   if(trend_up && fibo_direction == -1) {
      botStatus = "TENDENCIA ALCISTA - IGNORANDO SEÑAL DE VENTA";
      expectedSignal = "BUSCANDO NUEVO IMPULSO ALCISTA";
      return;
   }
   
   if(trend_down && fibo_direction == 1) {
      botStatus = "TENDENCIA BAJISTA - IGNORANDO SEÑAL DE COMPRA";
      expectedSignal = "BUSCANDO NUEVO IMPULSO BAJISTA";
      return;
   }
   
   // Si llegamos aquí, tendencia y Fibonacci están ALINEADOS
   bool inZone = IsInFiboZone(priceNow);
   bool nearZone = IsNearFiboZone(priceNow, 15);
   bool hasConfluence = (confluenceCount >= 1);
   bool hasGoodCandle = (lastCandleSignal == fibo_direction);
   
   if(!inZone && !nearZone) {
      if(fibo_direction == 1) {
         botStatus = "ESPERANDO PRECIO en zona COMPRA " + DoubleToString(fibo_786, _Digits) + " - " + DoubleToString(fibo_618, _Digits);
      } else {
         botStatus = "ESPERANDO PRECIO en zona VENTA " + DoubleToString(fibo_618, _Digits) + " - " + DoubleToString(fibo_786, _Digits);
      }
      return;
   }
   
   if((inZone || nearZone) && user_RequireConfluence && !hasConfluence) {
      botStatus = "EN ZONA FIBO, SIN CONFLUENCIA (esperando)";
      return;
   }
   
   if((inZone || nearZone) && !hasGoodCandle) {
      botStatus = "EN ZONA FIBO, VELA: " + lastCandlePattern + " (esperando confirmación)";
      return;
   }
   
   // Verificar RSI
   double rsi[1];
   if(CopyBuffer(h_rsi, 0, 0, 1, rsi) <= 0) return;
   
   if(fibo_direction == 1) {
      if(rsi[0] < 50 || rsi[0] > runtime_RSI_Overbought) {
         botStatus = "RSI FUERA DE RANGO (" + DoubleToString(rsi[0], 1) + ")";
         return;
      }
   } else {
      if(rsi[0] > 50 || rsi[0] < runtime_RSI_Oversold) {
         botStatus = "RSI FUERA DE RANGO (" + DoubleToString(rsi[0], 1) + ")";
         return;
      }
   }
   
   // Verificar EMAs (confirmación adicional)
   if(fibo_direction == 1 && emaF[0] <= emaS[0]) {
      botStatus = "EMA20 NO SOBRE EMA50";
      return;
   }
   if(fibo_direction == -1 && emaF[0] >= emaS[0]) {
      botStatus = "EMA20 NO BAJO EMA50";
      return;
   }
   
   // Verificar distancia a EMA
   double distPoints = MathAbs(priceNow - emaF[0]) / _Point;
   if(distPoints > runtime_MaxDistEMA_Points) {
      botStatus = "PRECIO LEJOS DE EMA (" + DoubleToString(distPoints, 0) + " pts)";
      return;
   }
   
   // --- TODAS LAS CONDICIONES CUMPLIDAS: EJECUTAR ---
   if(fibo_direction == 1) {
      if(trade.Buy(runtime_LoteManual, _Symbol, ask, fibo_786, tp1, "FIBO_ENTRY")) {
         lastTradeClose = 0;
         botStatus = "✅ COMPRA EJECUTADA | Vela: " + lastCandlePattern;
         Print("🔔 COMPRA | Precio: ", ask, " | Vela: ", lastCandlePattern);
      }
   } else {
      if(trade.Sell(runtime_LoteManual, _Symbol, bid, fibo_618, tp1, "FIBO_ENTRY")) {
         lastTradeClose = 0;
         botStatus = "✅ VENTA EJECUTADA | Vela: " + lastCandlePattern;
         Print("🔔 VENTA | Precio: ", bid, " | Vela: ", lastCandlePattern);
      }
   }
}

//+------------------------------------------------------------------+
//| HUD COMPLETO CON MINIMIZAR CORREGIDO                              |
//+------------------------------------------------------------------+
void CrearHUD() {
   ObjectsDeleteAll(0, PNL_TAG);
   int x = hud_X, y = hud_Y, w = hud_W, h = hud_H;
   
   if(isMinimized) {
      w = 280;
      h = 38;
   }
   
   CrRect("bg", x, y, w, h, C'15,15,35', C'60,60,120', 2);
   
   string title = "⚡ AMETRALLADORA v3.6 | " + (isCentAccount ? "CENT" : "REAL");
   CrRect("titlebar", x, y, w, 32, C'40,40,80', C'80,80,140', 1);
   CrLabel("ttl", x+10, y+8, title, clrWhite, 9, "Arial Bold");
   
   string minBtn = isMinimized ? "□" : "−";
   CrBtn("min", x+w-28, y+5, 22, 22, minBtn, C'60,60,100', clrWhite);
   
   if(isMinimized) return;
   
   CrRect("resize", x+w-14, y+h-14, 14, 14, C'80,80,120', C'100,100,160', 1);
   CrLabel("resize_mark", x+w-12, y+h-11, "◢", C'150,150,200', 10);
   
   int innerX = x + 12, innerY = y + 38, innerW = w - 24;
   int row = innerY, colLabel = 0, colValue = 180, colEdit = innerW - 100;
   
   string webIcon = webConnected ? "🟢 CONECTADO" : "🔴 DESCONECTADO";
   color webColor = webConnected ? C'0,255,0' : C'255,0,0';
   CrLabel("webL", innerX+colLabel, row, "🌐 WEB:", C'150,150,200', 10);
   CrLabel("webV", innerX+colValue, row, webIcon, webColor, 10, "Arial Bold");
   row += 26;
   
   CrLabel("balL", innerX+colLabel, row, "💰 BALANCE:", C'200,200,100', 10);
   CrLabel("balV", innerX+colValue, row, "$" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2), C'100,255,100', 11);
   row += 26;
   
   CrLabel("pL", innerX+colLabel, row, "📈 PNL HOY:", C'150,150,200', 10);
   CrLabel("pV", innerX+colValue, row, FormatValue(dayPnL_Units), clrWhite, 11);
   CrBtn("reset", innerX+colEdit+50, row-3, 60, 28, "RESET", C'80,80,120', clrWhite);
   row += 30;
   
   CrLabel("stL", innerX+colLabel, row, "🔵 ESTADO:", C'150,150,200', 10);
   CrLabel("stV", innerX+colValue, row, botStatus, C'0,255,127', 9);
   row += 28;
   
   CrLabel("trL", innerX+colLabel, row, "🧭 TENDENCIA:", C'150,150,200', 10);
   CrLabel("trV", innerX+colValue, row, currentTrend, trendColor, 10, "Arial Bold");
   row += 24;
   
   string fiboDir = (fibo_direction == 1) ? "COMPRA" : ((fibo_direction == -1) ? "VENTA" : "DETECTANDO");
   string fiboZone = (fibo_valid) ? DoubleToString(fibo_786, _Digits) + " - " + DoubleToString(fibo_618, _Digits) : "---";
   CrLabel("fibL", innerX+colLabel, row, "📊 FIBONACCI:", C'150,150,200', 10);
   CrLabel("fibV", innerX+colValue, row, fiboDir + " | Zona: " + fiboZone, C'255,200,0', 9);
   row += 24;
   
   CrLabel("sigL", innerX+colLabel, row, "🎯 SEÑAL ESPERADA:", C'150,150,200', 10);
   CrLabel("sigV", innerX+colValue, row, expectedSignal, C'255,200,0', 9);
   row += 24;
   
   CrLabel("cndL", innerX+colLabel, row, "🕯️ VELA M5:", C'150,150,200', 10);
   color candleColor = (lastCandleSignal == 1) ? C'100,255,100' : ((lastCandleSignal == -1) ? C'255,100,100' : C'255,200,100');
   CrLabel("cndV", innerX+colValue, row, lastCandlePattern, candleColor, 10, "Arial Bold");
   row += 28;
   
   string confText = (confluenceCount > 0) ? IntegerToString(confluenceCount) + " fuente(s): " + confluenceSources : "NINGUNA";
   color confColor = (confluenceCount > 0) ? C'100,255,100' : C'255,100,100';
   CrLabel("confL", innerX+colLabel, row, "✅ CONFLUENCIA:", C'150,150,200', 10);
   CrLabel("confV", innerX+colValue, row, confText, confColor, 9);
   row += 28;
   
   CrRect("sep1", innerX, row, innerW, 1, C'60,70,90', C'60,70,90', 1);
   row += 12;
   
   CrLabel("lotL", innerX+colLabel, row, "⚙️ LOTE BASE:", C'150,150,200', 10);
   CrEdit("lotE", innerX+colEdit, row-3, 80, 28, DoubleToString(runtime_LoteManual, 3), C'30,30,60', clrWhite);
   row += 30;
   
   CrLabel("gatL", innerX+colLabel, row, "🛡️ RESCATE (Gatillo):", C'150,150,200', 10);
   CrEdit("gatE", innerX+colEdit, row-3, 80, 28, DoubleToString(runtime_GatilloHedge, 0), C'30,30,60', clrWhite);
   row += 30;
   
   CrLabel("tarL", innerX+colLabel, row, "🎯 OBJETIVO (TP):", C'150,150,200', 10);
   CrEdit("tarE", innerX+colEdit, row-3, 80, 28, DoubleToString(runtime_Target_Individual, 0), C'30,30,60', clrWhite);
   row += 30;
   
   CrLabel("beL", innerX+colLabel, row, "⚖️ BREAK EVEN (BE):", C'150,150,200', 10);
   CrEdit("beE", innerX+colEdit, row-3, 80, 28, DoubleToString(runtime_BE_Trigger, 0), C'30,30,60', clrWhite);
   row += 30;
   
   CrLabel("tsL", innerX+colLabel, row, "⏱️ TRAILING STOP (TS):", C'150,150,200', 10);
   CrEdit("tsE", innerX+colEdit, row-3, 80, 28, DoubleToString(runtime_TS_Activation, 0), C'30,30,60', clrWhite);
   row += 30;
   
   CrLabel("distL", innerX+colLabel, row, "📏 DISTANCIA EMA:", C'150,150,200', 10);
   CrEdit("distE", innerX+colEdit, row-3, 80, 28, DoubleToString(runtime_MaxDistEMA_Points, 0), C'30,30,60', clrWhite);
   row += 30;
   
   CrLabel("waitL", innerX+colLabel, row, "⏳ ESPERA (seg):", C'150,150,200', 10);
   CrEdit("waitE", innerX+colEdit, row-3, 80, 28, IntegerToString(runtime_SegundosEspera), C'30,30,60', clrWhite);
   row += 35;
   
   CrBtn("b_zen", innerX+5, row, 120, 35, "ZEN", currentMode == MODE_ZEN ? C'0,100,255' : C'40,40,70', clrWhite);
   CrBtn("b_har", innerX+135, row, 120, 35, "COSECHA", currentMode == MODE_COSECHA ? C'255,100,0' : C'40,40,70', clrWhite);
   row += 42;
   
   CrBtn("d_amb", innerX+5, row, 90, 35, "AMBAS", currentDir == DIR_AMBAS ? C'60,150,255' : C'40,40,70', clrWhite);
   CrBtn("d_buy", innerX+105, row, 100, 35, "SOLO BUY", currentDir == DIR_SOLO_COMPRAS ? C'0,200,100' : C'40,40,70', clrWhite);
   CrBtn("d_sel", innerX+215, row, 100, 35, "SOLO SELL", currentDir == DIR_SOLO_VENTAS ? C'220,50,50' : C'40,40,70', clrWhite);
   row += 45;
   
   CrBtn("apply", innerX+5, row, innerW-10, 42, "💾 APLICAR CAMBIOS", C'0,100,150', clrWhite);
   row += 50;
   CrBtn("close", innerX+5, row, innerW-10, 42, "🔒 CERRAR TODO", C'200,40,40', clrWhite);
}

void ActualizarHUD() {
   if(ObjectFind(0, PNL_TAG + "bg") == -1) { CrearHUD(); return; }
   
   string webIcon = webConnected ? "🟢 CONECTADO" : "🔴 DESCONECTADO";
   color webColor = webConnected ? C'0,255,0' : C'255,0,0';
   
   ObjectSetString(0, PNL_TAG + "webV", OBJPROP_TEXT, webIcon);
   ObjectSetInteger(0, PNL_TAG + "webV", OBJPROP_COLOR, webColor);
   ObjectSetString(0, PNL_TAG + "balV", OBJPROP_TEXT, "$" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
   ObjectSetString(0, PNL_TAG + "pV", OBJPROP_TEXT, FormatValue(dayPnL_Units));
   ObjectSetString(0, PNL_TAG + "stV", OBJPROP_TEXT, botStatus);
   ObjectSetString(0, PNL_TAG + "trV", OBJPROP_TEXT, currentTrend);
   ObjectSetInteger(0, PNL_TAG + "trV", OBJPROP_COLOR, trendColor);
   
   string fiboDir = (fibo_direction == 1) ? "COMPRA" : ((fibo_direction == -1) ? "VENTA" : "DETECTANDO");
   string fiboZone = (fibo_valid) ? DoubleToString(fibo_786, _Digits) + " - " + DoubleToString(fibo_618, _Digits) : "---";
   ObjectSetString(0, PNL_TAG + "fibV", OBJPROP_TEXT, fiboDir + " | Zona: " + fiboZone);
   
   ObjectSetString(0, PNL_TAG + "sigV", OBJPROP_TEXT, expectedSignal);
   ObjectSetString(0, PNL_TAG + "cndV", OBJPROP_TEXT, lastCandlePattern);
   
   string confText = (confluenceCount > 0) ? IntegerToString(confluenceCount) + " fuente(s): " + confluenceSources : "NINGUNA";
   color confColor = (confluenceCount > 0) ? C'100,255,100' : C'255,100,100';
   ObjectSetString(0, PNL_TAG + "confV", OBJPROP_TEXT, confText);
   ObjectSetInteger(0, PNL_TAG + "confV", OBJPROP_COLOR, confColor);
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == PNL_TAG + "min") { 
         isMinimized = !isMinimized; 
         CrearHUD(); 
         return; 
      }
      if(sparam == PNL_TAG + "reset") { ResetDayPnL(); return; }
      if(sparam == PNL_TAG + "b_zen") { currentMode = MODE_ZEN; CrearHUD(); }
      if(sparam == PNL_TAG + "b_har") { currentMode = MODE_COSECHA; CrearHUD(); }
      if(sparam == PNL_TAG + "d_amb") { currentDir = DIR_AMBAS; CrearHUD(); }
      if(sparam == PNL_TAG + "d_buy") { currentDir = DIR_SOLO_COMPRAS; CrearHUD(); }
      if(sparam == PNL_TAG + "d_sel") { currentDir = DIR_SOLO_VENTAS; CrearHUD(); }
      if(sparam == PNL_TAG + "close") { CloseAllPositions(); return; }
      
      if(sparam == PNL_TAG + "apply") {
         runtime_LoteManual = StringToDouble(edit_lot);
         runtime_GatilloHedge = StringToDouble(edit_gat);
         runtime_Target_Individual = StringToDouble(edit_tar);
         runtime_Net_Cycle = StringToDouble(edit_meta);
         runtime_BE_Trigger = StringToDouble(edit_be);
         runtime_TS_Activation = StringToDouble(edit_ts);
         runtime_MaxDistEMA_Points = StringToDouble(edit_dist);
         runtime_SegundosEspera = (int)StringToInteger(edit_wait);
         botStatus = "CONFIG ACTUALIZADA";
         ActualizarHUD();
         return;
      }
   }
   
   if(id == CHARTEVENT_OBJECT_ENDEDIT) {
      string objName = sparam;
      string value = ObjectGetString(0, objName, OBJPROP_TEXT);
      
      if(objName == PNL_TAG + "lotE") edit_lot = value;
      if(objName == PNL_TAG + "gatE") edit_gat = value;
      if(objName == PNL_TAG + "tarE") edit_tar = value;
      if(objName == PNL_TAG + "metaE") edit_meta = value;
      if(objName == PNL_TAG + "beE") edit_be = value;
      if(objName == PNL_TAG + "tsE") edit_ts = value;
      if(objName == PNL_TAG + "distE") edit_dist = value;
      if(objName == PNL_TAG + "waitE") edit_wait = value;
   }
   
   // Arrastrar ventana
   if(id == CHARTEVENT_MOUSE_MOVE) {
      int x = (int)lparam, y = (int)dparam;
      if(sparam == PNL_TAG + "titlebar") {
         if(!dragging) { dragging = true; dragStartX = x - hud_X; dragStartY = y - hud_Y; }
         if(dragging) {
            hud_X = x - dragStartX;
            hud_Y = y - dragStartY;
            int maxX = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS) - hud_W;
            int maxY = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS) - hud_H;
            hud_X = MathMax(0, MathMin(hud_X, maxX));
            hud_Y = MathMax(0, MathMin(hud_Y, maxY));
            CrearHUD();
         }
      } else if(sparam == PNL_TAG + "resize") {
         if(!resizing) { resizing = true; resizeStartW = hud_W; resizeStartH = hud_H; dragStartX = x; dragStartY = y; }
         if(resizing) {
            int deltaX = x - dragStartX, deltaY = y - dragStartY;
            hud_W = MathMax(320, resizeStartW + deltaX);
            hud_H = MathMax(500, resizeStartH + deltaY);
            CrearHUD();
         }
      } else {
         dragging = false;
         resizing = false;
      }
   }
}

//+------------------------------------------------------------------+
//| INIT                                                             |
//+------------------------------------------------------------------+
int OnInit() {
   DetectAccountType();
   
   activeMagic = (int)user_MagicNumber;
   trade.SetExpertMagicNumber(activeMagic);
   symInfo.Name(_Symbol);
   symInfo.Refresh();
   
   runtime_LoteManual = user_LoteManual;
   runtime_HedgeMultiplier = user_HedgeMultiplier;
   runtime_GatilloHedge = user_GatilloHedge;
   runtime_Target_Individual = user_Target_Individual;
   runtime_Net_Cycle = user_Net_Cycle;
   runtime_MaxDistEMA_Points = user_MaxDistEMA_Points;
   runtime_BE_Trigger = user_BE_Trigger;
   runtime_TS_Activation = user_TS_Activation;
   runtime_MaxPosiciones = (int)user_MaxPosiciones;
   runtime_RSI_Overbought = user_RSI_Overbought;
   runtime_RSI_Oversold = user_RSI_Oversold;
   runtime_SegundosEspera = user_SegundosEspera;
   
   h_ema20 = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   h_ema50 = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
   h_rsi = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   h_atr = iATR(_Symbol, _Period, user_ATR_Period);
   h_ema_h1 = iMA(_Symbol, PERIOD_H1, 50, 0, MODE_EMA, PRICE_CLOSE);
   
   if(user_ShowIndicators) {
      ChartIndicatorAdd(0, 0, h_ema20);
      ChartIndicatorAdd(0, 0, h_ema50);
      ChartIndicatorAdd(0, 1, h_rsi);
   }
   
   CalculateFibonacci();
   UpdateTrend();
   UpdateExpectedSignal();
   dayPnL_Units = CalculateDayProfitUnits();
   CrearHUD();
   EventSetTimer(3);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int r) {
   ObjectsDeleteAll(0, PNL_TAG);
   IndicatorRelease(h_ema_h1);
}

//+------------------------------------------------------------------+
//| TICK                                                             |
//+------------------------------------------------------------------+
void OnTick() {
   CheckEmergencyExit();
   SyncWithWeb();
   
   if(TimeCurrent() % 300 == 0) {
      CalculateFibonacci();
   }
   
   UpdateTrend();
   UpdateExpectedSignal();
   CheckConfluence(SymbolInfoDouble(_Symbol, SYMBOL_BID));
   AnalyzeCandlestick();
   
   if(remotePaused) {
      botStatus = emergencyActive ? "⚠️ EMERGENCIA" : "⏸️ PAUSA";
      ActualizarHUD();
      return;
   }
   
   double drawdownPercent = GetTotalRiskPercent();
   if(drawdownPercent > user_MaxDrawdownPercent) {
      CloseAllPositions();
      botStatus = "🛑 DRAWDOWN MÁXIMO";
      ActualizarHUD();
      return;
   }
   
   if(GetPositionsCount() > 0) {
      ProtectAll();
   } else {
      CheckEntry();
   }
   
   dayPnL_Units = CalculateDayProfitUnits();
   ActualizarHUD();
}

//+------------------------------------------------------------------+
//| FUNCIONES DE DIBUJO                                              |
//+------------------------------------------------------------------+
void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bw=1) {
   string nm = PNL_TAG + n;
   ObjectCreate(0, nm, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, nm, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, nm, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, nm, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, bd);
   ObjectSetInteger(0, nm, OBJPROP_ZORDER, 100);
}

void CrLabel(string n, int x, int y, string t, color c, int s, string f="Segoe UI") {
   string nm = PNL_TAG + n;
   ObjectCreate(0, nm, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, nm, OBJPROP_TEXT, t);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, c);
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, s);
   ObjectSetString(0, nm, OBJPROP_FONT, f);
   ObjectSetInteger(0, nm, OBJPROP_ZORDER, 101);
}

void CrBtn(string n, int x, int y, int w, int h, string t, color bg, color tc) {
   string nm = PNL_TAG + n;
   ObjectCreate(0, nm, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, nm, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, nm, OBJPROP_YSIZE, h);
   ObjectSetString(0, nm, OBJPROP_TEXT, t);
   ObjectSetInteger(0, nm, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, tc);
   ObjectSetInteger(0, nm, OBJPROP_ZORDER, 102);
}

void CrEdit(string n, int x, int y, int w, int h, string t, color bg, color tc) {
   string nm = PNL_TAG + n;
   ObjectCreate(0, nm, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, nm, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, nm, OBJPROP_YSIZE, h);
   ObjectSetString(0, nm, OBJPROP_TEXT, t);
   ObjectSetInteger(0, nm, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, tc);
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, nm, OBJPROP_ZORDER, 102);
}
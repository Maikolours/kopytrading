//+------------------------------------------------------------------+
//| XAU-MG_HUD_v3.1.mq5 - AMETRALLADORA                              |
//| Bot profesional para XAUUSD (Oro)                                |
//| Versión: Casillas de texto + Fibonacci dibujado + CENT/REAL      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "3.10"
#property description "AMETRALLADORA v3.1 - Bot profesional para XAUUSD"
#property description "Fibonacci | ATR Trailing | Smart Recovery | Emergency Exit"
#property description "Casillas de texto | Fibonacci dibujado | HUD adaptado móvil"

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
input ENUM_ACCOUNT_TYPE AccountType = ACCOUNT_AUTO;  // AUTO, REAL, CENT
input double    user_MaxDrawdownPercent = 15.0;
input bool      user_ShowIndicators = true;

//--- PARÁMETROS DE ESTRATEGIA (valores en UNIDADES DE CUENTA)
double   user_MagicNumber        = 700842;
double   user_MaxPosiciones      = 2;
double   user_LoteManual         = 0.015;
double   user_HedgeMultiplier    = 1.5;
double   user_GatilloHedge       = 40;      // 0.40 USD real o 40 céntimos
double   user_Target_Individual  = 150;     // 1.50 USD real o 150 céntimos
double   user_Net_Cycle          = 250;     // 2.50 USD real o 250 céntimos
double   user_MaxDistEMA_Points  = 500;
double   user_BE_Trigger         = 30;      // 0.30 USD real o 30 céntimos
double   user_TS_Activation      = 50;      // 0.50 USD real o 50 céntimos
int      user_RSI_Overbought     = 75;
int      user_RSI_Oversold       = 25;
int      user_SegundosEspera     = 15;

//--- Fibonacci
double   user_Fibo_618 = 0.618;
double   user_Fibo_786 = 0.786;
double   user_Fibo_127 = 1.272;
double   user_Fibo_161 = 1.618;

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
int            activeMagic, h_ema20, h_ema50, h_rsi, h_atr;
bool           isMinimized = false;
bool           remotePaused = false;
ENUM_MODE      currentMode;
ENUM_DIR       currentDir;
string         botStatus = "TRABAJANDO";
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
double         unitMultiplier = 1.0;  // 1 para REAL, 100 para CENT

//--- Fibonacci niveles dinámicos
double         fibo_high = 0, fibo_low = 0;
double         fibo_618 = 0, fibo_786 = 0;
datetime       fibo_last_update = 0;

//--- Runtime (valores editables)
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

//--- Variables para campos de texto editables
string edit_lot = "";
string edit_gat = "";
string edit_tar = "";
string edit_meta = "";
string edit_be = "";
string edit_ts = "";
string edit_dist = "";
string edit_wait = "";

#define PNL_TAG "XAU_HUD_V3"

//+------------------------------------------------------------------+
//| Detectar tipo de cuenta                                           |
//+------------------------------------------------------------------+
void DetectAccountType() {
   if(AccountType == ACCOUNT_REAL) {
      isCentAccount = false;
      unitMultiplier = 1.0;
   } else if(AccountType == ACCOUNT_CENT) {
      isCentAccount = true;
      unitMultiplier = 100.0;
   } else { // AUTO
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
//| Convertir valor a unidades de cuenta (para mostrar)              |
//+------------------------------------------------------------------+
string FormatValue(double value) {
   if(isCentAccount) {
      return DoubleToString(value, 0) + "¢ (" + DoubleToString(value / 100.0, 2) + " $)";
   }
   return DoubleToString(value, 2) + " $";
}

//+------------------------------------------------------------------+
//| Obtener ATR actual                                                |
//+------------------------------------------------------------------+
double GetATR() {
   double atr[1];
   if(CopyBuffer(h_atr, 0, 0, 1, atr) > 0) return atr[0];
   return 0;
}

//+------------------------------------------------------------------+
//| Actualizar niveles Fibonacci                                      |
//+------------------------------------------------------------------+
void UpdateFibonacciLevels() {
   int bars = 50;
   double highs[], lows[];
   CopyHigh(_Symbol, _Period, 0, bars, highs);
   CopyLow(_Symbol, _Period, 0, bars, lows);
   
   fibo_high = highs[ArrayMaximum(highs)];
   fibo_low = lows[ArrayMinimum(lows)];
   double range = fibo_high - fibo_low;
   
   fibo_618 = fibo_high - range * user_Fibo_618;
   fibo_786 = fibo_high - range * user_Fibo_786;
   
   fibo_last_update = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Verificar si el precio está en zona Fibonacci                     |
//+------------------------------------------------------------------+
bool IsInFiboZone(double price, int direction) {
   UpdateFibonacciLevels();
   if(fibo_high <= 0 || fibo_low <= 0) return false;
   
   if(direction == 1) { // BUY
      return (price >= fibo_786 && price <= fibo_618);
   } else { // SELL
      return (price <= fibo_786 && price >= fibo_618);
   }
}

//+------------------------------------------------------------------+
//| Obtener nivel clave para Smart Recovery                           |
//+------------------------------------------------------------------+
double GetKeyLevel(int type) {
   UpdateFibonacciLevels();
   if(type == POSITION_TYPE_BUY) return fibo_786;
   return fibo_618;
}

//+------------------------------------------------------------------+
//| Dibujar Fibonacci en el gráfico                                   |
//+------------------------------------------------------------------+
void DrawFibonacciLevels() {
   ObjectsDeleteAll(0, "FIBO_");
   
   UpdateFibonacciLevels();
   if(fibo_high <= 0 || fibo_low <= 0) return;
   
   double range = fibo_high - fibo_low;
   double level_0 = fibo_low;
   double level_618 = fibo_high - range * 0.618;
   double level_786 = fibo_high - range * 0.786;
   double level_100 = fibo_high;
   
   // Línea 0%
   ObjectCreate(0, "FIBO_0", OBJ_HLINE, 0, 0, 0);
   ObjectSetDouble(0, "FIBO_0", OBJPROP_PRICE, level_0);
   ObjectSetInteger(0, "FIBO_0", OBJPROP_COLOR, clrDodgerBlue);
   ObjectSetInteger(0, "FIBO_0", OBJPROP_STYLE, STYLE_DASH);
   
   // Línea 61.8%
   ObjectCreate(0, "FIBO_618", OBJ_HLINE, 0, 0, 0);
   ObjectSetDouble(0, "FIBO_618", OBJPROP_PRICE, level_618);
   ObjectSetInteger(0, "FIBO_618", OBJPROP_COLOR, clrGold);
   ObjectSetInteger(0, "FIBO_618", OBJPROP_WIDTH, 2);
   
   // Línea 78.6%
   ObjectCreate(0, "FIBO_786", OBJ_HLINE, 0, 0, 0);
   ObjectSetDouble(0, "FIBO_786", OBJPROP_PRICE, level_786);
   ObjectSetInteger(0, "FIBO_786", OBJPROP_COLOR, clrOrange);
   ObjectSetInteger(0, "FIBO_786", OBJPROP_WIDTH, 2);
   
   // Línea 100%
   ObjectCreate(0, "FIBO_100", OBJ_HLINE, 0, 0, 0);
   ObjectSetDouble(0, "FIBO_100", OBJPROP_PRICE, level_100);
   ObjectSetInteger(0, "FIBO_100", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, "FIBO_100", OBJPROP_STYLE, STYLE_DASH);
   
   // Zona de entrada (rectángulo)
   datetime now = TimeCurrent();
   datetime future = now + 100 * 60;
   ObjectCreate(0, "FIBO_ZONE", OBJ_RECTANGLE, 0, now, level_786, future, level_618);
   ObjectSetInteger(0, "FIBO_ZONE", OBJPROP_COLOR, C'255,200,0');
   ObjectSetInteger(0, "FIBO_ZONE", OBJPROP_FILL, true);
   ObjectSetInteger(0, "FIBO_ZONE", OBJPROP_BACK, true);
   
   // Texto informativo
   string info = "FIBONACCI | Alto: " + DoubleToString(fibo_high, _Digits) + 
                 " | Bajo: " + DoubleToString(fibo_low, _Digits) +
                 " | Zona entrada: 61.8%-78.6%";
   ObjectCreate(0, "FIBO_INFO", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "FIBO_INFO", OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, "FIBO_INFO", OBJPROP_YDISTANCE, 30);
   ObjectSetString(0, "FIBO_INFO", OBJPROP_TEXT, info);
   ObjectSetInteger(0, "FIBO_INFO", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "FIBO_INFO", OBJPROP_FONTSIZE, 9);
}

//+------------------------------------------------------------------+
//| Funciones básicas                                                |
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

//+------------------------------------------------------------------+
//| Sincronización con web                                            |
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
//| Trailing Stop por ATR                                            |
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
//| Smart Recovery                                                   |
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
   
   double keyLevel = GetKeyLevel(mainType);
   double currentPrice = (mainType == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   bool priceAtKeyLevel = false;
   
   if(mainType == POSITION_TYPE_BUY) {
      if(currentPrice <= keyLevel + 10 * _Point && currentPrice >= keyLevel - 10 * _Point)
         priceAtKeyLevel = true;
   } else {
      if(currentPrice >= keyLevel - 10 * _Point && currentPrice <= keyLevel + 10 * _Point)
         priceAtKeyLevel = true;
   }
   
   double totalRisk = GetTotalRiskPercent();
   if(totalRisk > user_SmartRecovery_RiskMax) return;
   
   if(priceAtKeyLevel && mainProfitUnits <= -runtime_GatilloHedge) {
      double recoveryLot = runtime_LoteManual;
      double recoveryPrice = (mainType == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      if(mainType == POSITION_TYPE_BUY) {
         trade.Sell(recoveryLot, _Symbol, recoveryPrice, 0, 0, "RECOVERY");
      } else {
         trade.Buy(recoveryLot, _Symbol, recoveryPrice, 0, 0, "RECOVERY");
      }
   }
}

//+------------------------------------------------------------------+
//| Emergency Exit                                                   |
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
//| Protección de posiciones                                         |
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
//| Entrada con Fibonacci                                            |
//+------------------------------------------------------------------+
void CheckEntry() {
   if(GetPositionsCount() >= runtime_MaxPosiciones) return;
   if(TimeCurrent() < lastTradeClose + runtime_SegundosEspera) return;
   
   double emaF[1], emaS[1], rsi[1];
   if(CopyBuffer(h_ema20, 0, 0, 1, emaF) <= 0 ||
      CopyBuffer(h_ema50, 0, 0, 1, emaS) <= 0 ||
      CopyBuffer(h_rsi, 0, 0, 1, rsi) <= 0) return;
   
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   bool biasUp   = (emaF[0] > emaS[0] && rsi[0] > 50 && rsi[0] < runtime_RSI_Overbought);
   bool biasDown = (emaF[0] < emaS[0] && rsi[0] < 50 && rsi[0] > runtime_RSI_Oversold);
   
   double distPoints = MathAbs(bid - emaF[0]) / _Point;
   if(distPoints > runtime_MaxDistEMA_Points) return;
   
   int totalPos = GetPositionsCount();
   
   if(totalPos == 0) {
      DeletePendings();
      if(biasUp && (currentDir == DIR_AMBAS || currentDir == DIR_SOLO_COMPRAS)) {
         if(IsInFiboZone(ask, 1)) {
            if(trade.Buy(runtime_LoteManual, _Symbol, ask, 0, 0, "FIBO_ENTRY"))
               lastTradeClose = 0;
         }
      }
      else if(biasDown && (currentDir == DIR_AMBAS || currentDir == DIR_SOLO_VENTAS)) {
         if(IsInFiboZone(bid, -1)) {
            if(trade.Sell(runtime_LoteManual, _Symbol, bid, 0, 0, "FIBO_ENTRY"))
               lastTradeClose = 0;
         }
      }
   } else {
      SmartRecovery();
   }
}

//+------------------------------------------------------------------+
//| HUD con casillas de texto                                        |
//+------------------------------------------------------------------+
void CrearHUD() {
   ObjectsDeleteAll(0, PNL_TAG);
   int x = 10, y = 10, w = 450, h = 780;
   
   CrRect("bg", x, y, w, h, C'15,15,35', C'60,60,120', 2);
   
   string title = "⚡ AMETRALLADORA v3.1 | " + (isCentAccount ? "CENT" : "REAL");
   CrRect("titlebar", x, y, w, 35, C'40,40,80', C'80,80,140', 1);
   CrLabel("ttl", x+10, y+10, title, clrWhite, 10, "Arial Bold");
   
   int innerX = x + 12, innerY = y + 40, innerW = w - 24;
   int row = innerY, colLabel = 0, colValue = 140, colEdit = innerW - 100;
   
   // Conexión web
   string webIcon = webConnected ? "🟢 CONECTADO" : "🔴 DESCONECTADO";
   color webColor = webConnected ? C'0,255,0' : C'255,0,0';
   CrLabel("webL", innerX+colLabel, row, "WEB:", C'150,150,200', 10);
   CrLabel("webV", innerX+colValue, row, webIcon, webColor, 10, "Arial Bold");
   row += 30;
   
   // Balance y PnL
   CrLabel("balL", innerX+colLabel, row, "BALANCE:", C'200,200,100', 10);
   CrLabel("balV", innerX+colValue, row, "$" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2), C'100,255,100', 11);
   row += 28;
   
   CrLabel("pL", innerX+colLabel, row, "PNL HOY:", C'150,150,200', 10);
   CrLabel("pV", innerX+colValue, row, FormatValue(dayPnL_Units), clrWhite, 11);
   CrBtn("reset", innerX+colEdit+50, row-3, 60, 28, "RESET", C'80,80,120', clrWhite);
   row += 32;
   
   CrLabel("stL", innerX+colLabel, row, "ESTADO:", C'150,150,200', 10);
   CrLabel("stV", innerX+colValue, row, botStatus, C'0,255,127', 10);
   row += 35;
   
   // LOTE BASE (casilla de texto)
   CrLabel("lotL", innerX+colLabel, row, "LOTE BASE:", C'150,150,200', 10);
   CrEdit("lotE", innerX+colEdit, row-3, 80, 28, DoubleToString(runtime_LoteManual, 3), C'30,30,60', clrWhite);
   row += 30;
   
   // GATILLO HEDGE
   CrLabel("gatL", innerX+colLabel, row, "RESCATE (Gatillo):", C'150,150,200', 10);
   CrEdit("gatE", innerX+colEdit, row-3, 80, 28, DoubleToString(runtime_GatilloHedge, 0), C'30,30,60', clrWhite);
   row += 30;
   
   // OBJETIVO
   CrLabel("tarL", innerX+colLabel, row, "OBJETIVO (Take Profit):", C'150,150,200', 10);
   CrEdit("tarE", innerX+colEdit, row-3, 80, 28, DoubleToString(runtime_Target_Individual, 0), C'30,30,60', clrWhite);
   row += 30;
   
   // META CICLO
   CrLabel("metaL", innerX+colLabel, row, "META CICLO (Bloque):", C'150,150,200', 10);
   CrEdit("metaE", innerX+colEdit, row-3, 80, 28, DoubleToString(runtime_Net_Cycle, 0), C'30,30,60', clrWhite);
   row += 30;
   
   // BREAK EVEN
   CrLabel("beL", innerX+colLabel, row, "BREAK EVEN (BE):", C'150,150,200', 10);
   CrEdit("beE", innerX+colEdit, row-3, 80, 28, DoubleToString(runtime_BE_Trigger, 0), C'30,30,60', clrWhite);
   row += 30;
   
   // TRAILING STOP
   CrLabel("tsL", innerX+colLabel, row, "TRAILING STOP (TS):", C'150,150,200', 10);
   CrEdit("tsE", innerX+colEdit, row-3, 80, 28, DoubleToString(runtime_TS_Activation, 0), C'30,30,60', clrWhite);
   row += 30;
   
   // DISTANCIA EMA
   CrLabel("distL", innerX+colLabel, row, "DISTANCIA EMA (pts):", C'150,150,200', 10);
   CrEdit("distE", innerX+colEdit, row-3, 80, 28, DoubleToString(runtime_MaxDistEMA_Points, 0), C'30,30,60', clrWhite);
   row += 30;
   
   // ESPERA
   CrLabel("waitL", innerX+colLabel, row, "ESPERA (segundos):", C'150,150,200', 10);
   CrEdit("waitE", innerX+colEdit, row-3, 80, 28, IntegerToString(runtime_SegundosEspera), C'30,30,60', clrWhite);
   row += 35;
   
   // Modos
   CrBtn("b_zen", innerX+5, row, 120, 35, "ZEN", currentMode == MODE_ZEN ? C'0,100,255' : C'40,40,70', clrWhite);
   CrBtn("b_har", innerX+135, row, 120, 35, "COSECHA", currentMode == MODE_COSECHA ? C'255,100,0' : C'40,40,70', clrWhite);
   row += 42;
   
   // Dirección
   CrBtn("d_amb", innerX+5, row, 90, 35, "AMBAS", currentDir == DIR_AMBAS ? C'60,150,255' : C'40,40,70', clrWhite);
   CrBtn("d_buy", innerX+105, row, 100, 35, "SOLO BUY", currentDir == DIR_SOLO_COMPRAS ? C'0,200,100' : C'40,40,70', clrWhite);
   CrBtn("d_sel", innerX+215, row, 100, 35, "SOLO SELL", currentDir == DIR_SOLO_VENTAS ? C'220,50,50' : C'40,40,70', clrWhite);
   row += 45;
   
   CrBtn("apply", innerX+5, row, innerW-10, 42, "APLICAR CAMBIOS", C'0,100,150', clrWhite);
   row += 50;
   CrBtn("close", innerX+5, row, innerW-10, 42, "CERRAR TODO", C'200,40,40', clrWhite);
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
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
   if(id == CHARTEVENT_OBJECT_CLICK) {
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
         botStatus = "CONFIG OK";
         ActualizarHUD();
         return;
      }
   }
   
   // Capturar cambios en campos de texto
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
}

//+------------------------------------------------------------------+
//| OnInit                                                           |
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
   h_rsi   = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   h_atr   = iATR(_Symbol, _Period, user_ATR_Period);
   
   if(user_ShowIndicators) {
      ChartIndicatorAdd(0, 0, h_ema20);
      ChartIndicatorAdd(0, 0, h_ema50);
      ChartIndicatorAdd(0, 1, h_rsi);
   }
   
   UpdateFibonacciLevels();
   DrawFibonacciLevels();
   dayPnL_Units = CalculateDayProfitUnits();
   CrearHUD();
   EventSetTimer(3);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int r) {
   ObjectsDeleteAll(0, PNL_TAG);
}

//+------------------------------------------------------------------+
//| OnTick                                                           |
//+------------------------------------------------------------------+
void OnTick() {
   CheckEmergencyExit();
   SyncWithWeb();
   
   // Actualizar Fibonacci cada minuto
   if(TimeCurrent() % 60 == 0) {
      UpdateFibonacciLevels();
      DrawFibonacciLevels();
   }
   
   if(remotePaused) {
      botStatus = emergencyActive ? "⚠️ EMERGENCIA" : "PAUSA";
      ActualizarHUD();
      return;
   }
   
   double drawdownPercent = GetTotalRiskPercent();
   if(drawdownPercent > user_MaxDrawdownPercent) {
      CloseAllPositions();
      botStatus = "DRAWDOWN MAX";
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

// Funciones de dibujo
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
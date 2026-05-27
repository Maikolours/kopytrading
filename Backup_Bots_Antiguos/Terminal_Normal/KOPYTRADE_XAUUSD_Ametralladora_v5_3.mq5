//+------------------------------------------------------------------+
//|                                  KOPYTRADE_XAUUSD_Ametralladora_v5_3.mq5 |
//|                                  Copyright 2026, Kopytrade Corp. |
//|                                  https://www.kopytrade.com       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrade Corp."
#property link      "https://www.kopytrade.com"
#property version   "5.30"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

// --- INPUTS ---
input string   LicenseKey = "DEMO-1234";
input double   LoteMain = 0.01;
input double   LoteHarvest = 0.02;
input int      MagicNumber = 5353;
input int      Distancia_Gatillo_Pts = 200;
input double   Meta_Cosecha_USD = 3.0;
input double   Meta_Ciclo_USD = 2.0;
input bool     MostrarHUD = true;

// --- ESTRUCTURAS Y ENUMS ---
enum ENUM_BOT_MODE { MODE_ZEN, MODE_COSECHA };
enum ENUM_TRADE_DIR { DIR_BUYS, DIR_SELLS, DIR_BOTH };

// --- VARIABLES GLOBALES ---
CTrade         trade;
CPositionInfo  posInfo;
bool           licenseValid = true;
ENUM_BOT_MODE  currentMode = MODE_ZEN;
ENUM_TRADE_DIR currentDir = DIR_BOTH;
double         customLot = 0.01;
datetime       nextTradeTime = 0;
string         botStatus = "LISTO";

// --- INICIALIZACIÓN ---
int OnInit() {
   trade.SetExpertMagicNumber(MagicNumber);
   customLot = LoteMain;
   if(MostrarHUD) CreateHUD();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
   ObjectsDeleteAll(0, "HUD_");
}

// --- LÓGICA PRINCIPAL ---
void OnTick() {
   if(!licenseValid) return;

   // 1. Verificar Enfriamiento
   if(TimeCurrent() < nextTradeTime) {
      botStatus = "ENFRIANDO (" + IntegerToString((int)(nextTradeTime - TimeCurrent())) + "s)";
      if(MostrarHUD) UpdateHUD();
      return;
   }

   // 2. Gestión de Cierre Global (Fees Incluidos)
   CheckGlobalClosure();

   // 3. Gestión de Cosecha y BE
   ManageHarvesting();

   // 4. Análisis y Apertura
   if(ContarPosiciones() == 0 && ContarPendientes() == 0) {
      if(CheckTripleConfirmation()) {
         botStatus = "ACECHANDO";
         PlaceDualGatillos();
      } else {
         botStatus = "ANALIZANDO TF";
      }
   }

   if(MostrarHUD) UpdateHUD();
}

// --- FUNCIONES DE SEGURIDAD Y FILTRO ---

bool CheckTripleConfirmation() {
   // 1. TENDENCIA MACRO (H1 y M30)
   double ema200_H1 = iMA(_Symbol, PERIOD_H1, 200, 0, MODE_EMA, PRICE_CLOSE, 0);
   double ema50_H1 = iMA(_Symbol, PERIOD_H1, 50, 0, MODE_EMA, PRICE_CLOSE, 0);
   double priceH1 = iClose(_Symbol, PERIOD_H1, 0);
   
   double ema50_M30 = iMA(_Symbol, PERIOD_M30, 50, 0, MODE_EMA, PRICE_CLOSE, 0);
   double priceM30 = iClose(_Symbol, PERIOD_M30, 0);
   
   bool trendUpMacro = (priceH1 > ema200_H1 && priceM30 > ema50_M30);
   bool trendDnMacro = (priceH1 < ema200_H1 && priceM30 < ema50_M30);

   // 2. MOMENTUM MICRO (M5 - 2 de 3 velas)
   int bullM5 = 0, bearM5 = 0;
   for(int i=1; i<=3; i++) {
      if(iClose(_Symbol, PERIOD_M5, i) > iOpen(_Symbol, PERIOD_M5, i)) bullM5++;
      else bearM5++;
   }
   
   // 3. BLOQUEO DOBLE NEGATIVO (Safety Rule)
   double pBuy = 0, pSell = 0;
   bool hasBuy = false, hasSell = false;
   for(int i=0; i<PositionsTotal(); i++) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic() == MagicNumber) {
         if(posInfo.PositionType() == POSITION_TYPE_BUY) { pBuy += posInfo.Profit(); hasBuy = true; }
         else { pSell += posInfo.Profit(); hasSell = true; }
      }
   }
   
   // BLOQUEO TOTAL si ambos pierden
   if(hasBuy && hasSell && pBuy < 0 && pSell < 0) {
      botStatus = "LOCK: DOBLE NEGATIVO";
      return false;
   }

   // 4. VALIDACIÓN SEGÚN DIRECCIÓN ELEGIDA EN HUD
   if(currentDir == DIR_BUYS) {
      if(trendUpMacro && bullM5 >= 2 && (pBuy >= 0 || !hasBuy)) return true;
   }
   if(currentDir == DIR_SELLS) {
      if(trendDnMacro && bearM5 >= 2 && (pSell >= 0 || !hasSell)) return true;
   }
   if(currentDir == DIR_BOTH) {
      if(trendUpMacro && bullM5 >= 2 && (pBuy >= 0 || !hasBuy)) return true;
      if(trendDnMacro && bearM5 >= 2 && (pSell >= 0 || !hasSell)) return true;
   }
   
   return false;
}

void CheckGlobalClosure() {
   double netTotal = 0;
   int count = 0;
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic() == MagicNumber) {
         netTotal += posInfo.Profit() + posInfo.Commission() + posInfo.Swap();
         count++;
      }
   }
   
   if(count > 0 && netTotal >= Meta_Ciclo_USD) {
      CloseAll();
      nextTradeTime = TimeCurrent() + 300; // 5 min de enfriamiento
      botStatus = "CICLO CERRADO (+$" + DoubleToString(netTotal, 2) + ")";
   }
}

void ManageHarvesting() {
   double harvestTarget = (currentMode == MODE_ZEN ? 5.0 : 3.0);
   
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic() == MagicNumber) {
         double profit = posInfo.Profit();
         
         // Regla de Cosecha
         if(profit >= harvestTarget) {
            trade.PositionClose(posInfo.Ticket());
            // Re-armar gatillo se hará en OnTradeTransaction para mayor precisión
            continue;
         }
         
         // BE Inmediato (+$2)
         if(profit >= 2.0) {
            double sl = posInfo.PriceOpen();
            // Mantener un colchón de $0.5
            if(posInfo.PositionType() == POSITION_TYPE_BUY) sl += 50 * _Point;
            else sl -= 50 * _Point;
            
            if(posInfo.StopLoss() == 0 || (posInfo.PositionType() == POSITION_TYPE_BUY && posInfo.StopLoss() < sl) || (posInfo.PositionType() == POSITION_TYPE_SELL && (posInfo.StopLoss() > sl || posInfo.StopLoss() == 0)))
               trade.PositionModify(posInfo.Ticket(), sl, posInfo.TakeProfit());
         }
      }
   }
}

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &req, const MqlTradeResult &res) {
   // Detectar cierre de posición para re-armado inmediato
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD) {
      if(HistoryDealSelect(trans.deal)) {
         long magic = HistoryDealGetInteger(trans.deal, DEAL_MAGIC);
         if(magic == MagicNumber) {
            long entry = HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
            if(entry == DEAL_ENTRY_OUT) {
               // Posición cerrada por SL (BE) o TP (Cosecha)
               ENUM_DEAL_TYPE type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(trans.deal, DEAL_TYPE);
               PlaceSingleGatillo(type == DEAL_TYPE_BUY ? POSITION_TYPE_SELL : POSITION_TYPE_BUY);
            }
         }
      }
   }
}

// --- UTILIDADES ---

void PlaceDualGatillos() {
   double dist = Distancia_Gatillo_Pts * _Point;
   double lot = (currentMode == MODE_ZEN) ? LoteMain : LoteHarvest;
   
   if(currentDir == DIR_BUYS || currentDir == DIR_BOTH)
      trade.BuyStop(lot, SymbolInfoDouble(_Symbol, SYMBOL_ASK) + dist, _Symbol, 0, 0, ORDER_TIME_GTC);
   if(currentDir == DIR_SELLS || currentDir == DIR_BOTH)
      trade.SellStop(lot, SymbolInfoDouble(_Symbol, SYMBOL_BID) - dist, _Symbol, 0, 0, ORDER_TIME_GTC);
}

void PlaceSingleGatillo(ENUM_POSITION_TYPE type) {
   double dist = 100 * _Point; // Distancia corta para cosecha
   if(type == POSITION_TYPE_BUY)
      trade.BuyStop(customLot, SymbolInfoDouble(_Symbol, SYMBOL_ASK) + dist, _Symbol, 0, 0, ORDER_TIME_GTC);
   else
      trade.SellStop(customLot, SymbolInfoDouble(_Symbol, SYMBOL_BID) - dist, _Symbol, 0, 0, ORDER_TIME_GTC);
}

void CloseAll() {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic() == MagicNumber) trade.PositionClose(posInfo.Ticket());
   }
   // Borrar pendientes
   for(int i=OrdersTotal()-1; i>=0; i--) {
      ulong ticket = OrderGetTicket(i);
      if(OrderSelect(ticket) && OrderGetInteger(ORDER_MAGIC) == MagicNumber) trade.OrderDelete(ticket);
   }
}

int ContarPosiciones() {
   int c = 0;
   for(int i=0; i<PositionsTotal(); i++) if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == MagicNumber) c++;
   return c;
}

int ContarPendientes() {
   int c = 0;
   for(int i=0; i<OrdersTotal(); i++) {
      ulong t = OrderGetTicket(i);
      if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC) == MagicNumber) c++;
   }
   return c;
}

// --- INTERFAZ (HUD) ---
void CreateHUD() {
   // Titulo
   ObjectCreate(0, "HUD_Title", OBJ_LABEL, 0, 0, 0);
   ObjectSetString(0, "HUD_Title", OBJPROP_TEXT, "AMETRALLADORA v5.3 GOLD");
   ObjectSetInteger(0, "HUD_Title", OBJPROP_XDISTANCE, 20);
   ObjectSetInteger(0, "HUD_Title", OBJPROP_YDISTANCE, 20);
   ObjectSetInteger(0, "HUD_Title", OBJPROP_COLOR, clrGold);
   
   // Boton Modo
   CreateButton("HUD_Btn_Mode", "MODO: ZEN", 20, 50, 100, 25);
   CreateButton("HUD_Btn_Dir", "DIR: BOTH", 130, 50, 100, 25);
   CreateButton("HUD_Btn_LotUp", "LOT +", 20, 85, 45, 25);
   CreateButton("HUD_Btn_LotDown", "LOT -", 75, 85, 45, 25);
}

void CreateButton(string name, string text, int x, int y, int w, int h) {
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
}

void UpdateHUD() {
   ObjectSetString(0, "HUD_Btn_Mode", OBJPROP_TEXT, "MODO: " + (currentMode == MODE_ZEN ? "ZEN" : "COSECHA"));
   ObjectSetString(0, "HUD_Btn_Dir", OBJPROP_TEXT, "DIR: " + (currentDir == DIR_BOTH ? "BOTH" : (currentDir == DIR_BUYS ? "ONLY BUYS" : "ONLY SELLS")));
   
   // Status Line
   string statusText = "STATUS: " + botStatus + " | LOTE: " + DoubleToString(customLot, 2);
   if(ObjectFind(0, "HUD_Status") < 0) ObjectCreate(0, "HUD_Status", OBJ_LABEL, 0, 0, 0);
   ObjectSetString(0, "HUD_Status", OBJPROP_TEXT, statusText);
   ObjectSetInteger(0, "HUD_Status", OBJPROP_XDISTANCE, 20);
   ObjectSetInteger(0, "HUD_Status", OBJPROP_YDISTANCE, 120);
   ObjectSetInteger(0, "HUD_Status", OBJPROP_COLOR, clrWhite);
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == "HUD_Btn_Mode") currentMode = (currentMode == MODE_ZEN ? MODE_COSECHA : MODE_ZEN);
      if(sparam == "HUD_Btn_Dir") {
         if(currentDir == DIR_BOTH) currentDir = DIR_BUYS;
         else if(currentDir == DIR_BUYS) currentDir = DIR_SELLS;
         else currentDir = DIR_BOTH;
      }
      if(sparam == "HUD_Btn_LotUp") customLot = NormalizeDouble(customLot + 0.01, 2);
      if(sparam == "HUD_Btn_LotDown") customLot = NormalizeDouble(MathMax(0.01, customLot - 0.01), 2);
      UpdateHUD();
   }
}

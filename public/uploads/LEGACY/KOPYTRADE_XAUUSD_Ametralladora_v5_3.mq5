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

// =====================================================================
// =================== RESTORATION OF ORIGINAL INPUTS ==================
// =====================================================================

// --- LICENCIA ---
input string   LicenseKey        = "DEMO-1234";

// --- GESTIÓN DE RIESGO ---
input double   RiskPercent       = 0.5;       // % de Riesgo por operación
input int      MagicNumber       = 5353;      // Magic Number del bot
input double   LoteManual        = 0.01;      // Lote si Risk es 0

// --- RESCATE MATEMÁTICO (AMETRALLADORA) ---
input bool     ActivarRescate    = true;      // 🚑 Activar Operación de Rescate
input double   MultiplicadorLote = 2.0;       // Multiplicador base
input double   DisparadorRescate = 4.0;       // $ Perdida para activar gatillo

// --- META DIARIA ---
input double   MetaDiaria_USD    = 25.0;      // 🎯 Ganancia Diaria para apagar el bot ($)

// --- FILTRO DE HORARIO (Doble Sesión) ---
input bool     EnableTimeFilter  = true;      // ⏰ Activar filtro de horario
input int      StartHour1        = 9;         // Inicio Mañana
input int      EndHour1          = 14;        // Fin Mañana
input int      StartHour2        = 17;        // Inicio Tarde
input int      EndHour2          = 21;        // Fin Tarde

// --- STOP LOSS Y TAKE PROFIT (ATR) ---
input int      ATR_Period        = 14;        // Periodo del ATR
input double   SL_Mult_Gold      = 1.3;       // SL ORO (Multiplicador ATR)
input double   TP_Mult_Gold      = 1.0;       // TP ORO (Multiplicador ATR)

// --- ESTRATEGIA (MOMENTUM) ---
input int      MomentumCandles   = 3;         // Nº Velas atrás
input int      MomentumRequired  = 2;         // Nº Velas mismo sentido
input int      CooldownSeconds   = 60;        // Espera entre operaciones

// --- CORTAFUEGOS Y GESTIÓN ---
input bool     ActivarCortafuego = true;      // 🛡️ Cerrar si gana/pierde X
input double   Meta_Ciclo_USD    = 5.0;       // Neto para cerrar todo ciclo (+$5)
input double   Harvest_TP_USD    = 3.0;       // TP para "Cosechar" individualmente (+$3)

// --- BREAK EVEN Y TRAILING ---
input bool     EnableBE          = true;      
input double   BE_Trigger_USD    = 2.5;      
input double   BE_Cushion_USD    = 1.0;      

// --- PANEL VISUAL ---
input bool     ShowHUD           = true;      // Mostrar panel Premium
input color    ColorPanel        = C'10,15,30'; // Azul Medianoche

// =====================================================================
// ======================== VARIABLES GLOBALES =========================
// =====================================================================
CTrade         trade;
CPositionInfo  posInfo;
int            handleEMA200, handleEMA50, handleATR;
datetime       lastTradeTime = 0;
datetime       coolingEndTime = 0;
enum ENUM_DIR  { DIR_COMPRAS, DIR_VENTAS, DIR_AMBAS };
enum ENUM_MODE { MODE_ZEN, MODE_COSECHA };
ENUM_DIR       currentDir = DIR_AMBAS;
ENUM_MODE      currentMode = MODE_COSECHA;
string         botStatus = "LISTO";
bool           isMinimized = false;
datetime       licenseStart = 0;
double         mode_HarvestTP = 3.0;
double         mode_CycleMeta = 5.0;
double         mode_BETrigger = 2.5;

// =====================================================================
// ========================== INICIALIZACIÓN ===========================
// =====================================================================
int OnInit() {
   trade.SetExpertMagicNumber(MagicNumber);
   handleEMA200 = iMA(_Symbol, PERIOD_H1, 200, 0, MODE_EMA, PRICE_CLOSE);
   handleEMA50  = iMA(_Symbol, PERIOD_H1, 50, 0, MODE_EMA, PRICE_CLOSE);
   handleATR    = iATR(_Symbol, PERIOD_H1, ATR_Period);
   
   // Simulación de inicio de licencia de 30 días
   licenseStart = iTime(_Symbol, PERIOD_D1, 0) - (86400 * 5); // Supongamos que pasaron 5 días
   
   if(ShowHUD) CreatePremiumHUD();
   UpdateModeParams();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
   ObjectsDeleteAll(0, "HUD_");
   Comment("");
}

// =====================================================================
// ========================= LÓGICA PRINCIPAL ==========================
// =====================================================================
void OnTick() {
   if(MetaDiaria_USD > 0 && GetDailyProfit() >= MetaDiaria_USD) {
      botStatus = "META ALCANZADA";
      if(ShowHUD) UpdateHUD();
      return;
   }

   if(!IsTradingTime() || TimeCurrent() < coolingEndTime) {
      botStatus = (TimeCurrent() < coolingEndTime) ? "ENFRIANDO ("+IntegerToString((int)(coolingEndTime-TimeCurrent()))+"s)" : "FUERA DE HORARIO";
      if(ShowHUD) UpdateHUD();
      return;
   }

   // 1. Gestión de Cosecha Veloz
   ManageFastScalping();

   // 2. Mantenimiento de Pendientes (Operaciones en Reserva)
   MaintainReserveOrders();

   if(ShowHUD) UpdateHUD();
}

// =====================================================================
// ======================= COSECHA Y RESCATE ===========================
// =====================================================================

void ManageFastScalping() {
   double netProfit = 0;
   int buys=0, sells=0;
   double buyP=0, sellP=0;

   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic() == MagicNumber) {
         double p = posInfo.Profit() + posInfo.Commission() + posInfo.Swap();
         if(posInfo.PositionType() == POSITION_TYPE_BUY) { buys++; buyP += p; }
         else { sells++; sellP += p; }
         netProfit += p;

         // Cosecha Individual según Modo
         if(p >= mode_HarvestTP) {
            trade.PositionClose(posInfo.Ticket());
            botStatus = "COSECHA +$" + DoubleToString(mode_HarvestTP, 1);
            continue; 
         }
         
         // REFUERZO: Si va ganando > $2 y solo hay una operación, meter segunda
         if(p >= 2.0 && CountBySide((ENUM_POSITION_TYPE)posInfo.PositionType()) == 1) {
            double rLot = posInfo.Volume();
            if(posInfo.PositionType() == POSITION_TYPE_BUY) trade.Buy(rLot, _Symbol, 0, 0, 0, "REFUERZO");
            else trade.Sell(rLot, _Symbol, 0, 0, 0, "REFUERZO");
            botStatus = "INYECTANDO REFUERZO";
         }
         
         // Break Even Dinámico
         if(EnableBE && p >= mode_BETrigger) ApplyInstantBE(posInfo.Ticket());
      }
   }

   // Cosecha Doble / Ciclo según Modo
   if((buys+sells) >= 2 && netProfit >= mode_CycleMeta) {
      CloseEverything();
      coolingEndTime = TimeCurrent() + 60;
      botStatus = "CICLO CERRADO +$" + DoubleToString(mode_CycleMeta, 1);
   }
}

void UpdateModeParams() {
   if(currentMode == MODE_ZEN) {
      mode_HarvestTP = 1.0;
      mode_CycleMeta = 2.0;
      mode_BETrigger = 1.0;
   } else {
      mode_HarvestTP = Harvest_TP_USD;
      mode_CycleMeta = Meta_Ciclo_USD;
      mode_BETrigger = BE_Trigger_USD;
   }
}

void MaintainReserveOrders() {
   if(coolingEndTime > TimeCurrent()) return;

   int buys = CountBySide(POSITION_TYPE_BUY);
   int sells = CountBySide(POSITION_TYPE_SELL);
   int p_buys = CountPendings(ORDER_TYPE_BUY_STOP);
   int p_sells = CountPendings(ORDER_TYPE_SELL_STOP);

   // CASO 0: Sin operaciones -> Poner gatillos según dirección HUD
   if(buys == 0 && sells == 0) {
      bool needBuy = (currentDir == DIR_COMPRAS || currentDir == DIR_AMBAS);
      bool needSell = (currentDir == DIR_VENTAS || currentDir == DIR_AMBAS);
      
      if(needBuy && p_buys == 0) SyncPending(ORDER_TYPE_BUY_STOP, CalculateLot());
      if(needSell && p_sells == 0) SyncPending(ORDER_TYPE_SELL_STOP, CalculateLot());
      return;
   }

   // CASO 1: Solo COMPRA abierta -> Necesitamos SellStop de Rescate (Hedge inteligente)
   if(buys > 0 && sells == 0) {
      double p = GetTotalProfitSide(POSITION_TYPE_BUY);
      // El lote de la "Reserva" (SellStop) se vuelve dinámico si la compra pierde mas de $2
      double recLot = (p <= -2.0) ? CalculateRecoveryLot(MathAbs(p)) : LoteManual;
      
      SyncPending(ORDER_TYPE_SELL_STOP, recLot);
      DeletePendings(ORDER_TYPE_BUY_STOP); 
      botStatus = (p <= -DisparadorRescate) ? "RECUPERANDO COMPRA" : "COSECHANDO COMPRA";
   }

   // CASO 2: Solo VENTA abierta -> Necesitamos BuyStop de Rescate
   if(sells > 0 && buys == 0) {
      double p = GetTotalProfitSide(POSITION_TYPE_SELL);
      double recLot = (p <= -2.0) ? CalculateRecoveryLot(MathAbs(p)) : LoteManual;
      
      SyncPending(ORDER_TYPE_BUY_STOP, recLot);
      DeletePendings(ORDER_TYPE_SELL_STOP);
      botStatus = (p <= -DisparadorRescate) ? "RECUPERANDO VENTA" : "COSECHANDO VENTA";
   }

   // CASO 3: Ambas abiertas (Hedge) -> Bloqueo de seguridad para evitar sobre-exposición
   if(buys > 0 && sells > 0) {
      DeletePendings(ORDER_TYPE_BUY_STOP);
      DeletePendings(ORDER_TYPE_SELL_STOP);
      botStatus = "LOCK (ESPERANDO)";
   }
}

void SyncPending(ENUM_ORDER_TYPE type, double lot) {
   // Buscar si ya existe la orden
   ulong ticket = 0;
   for(int i=OrdersTotal()-1; i>=0; i--) {
      ulong t = OrderGetTicket(i);
      if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC) == MagicNumber && OrderGetInteger(ORDER_TYPE) == type) {
         ticket = t; break;
      }
   }

   double dist = 200 * _Point;
   double price = (type == ORDER_TYPE_BUY_STOP) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) + dist : SymbolInfoDouble(_Symbol, SYMBOL_BID) - dist;
   price = NormalizeDouble(price, _Digits);

   if(ticket == 0) {
      if(type == ORDER_TYPE_BUY_STOP) trade.BuyStop(lot, price, _Symbol);
      else trade.SellStop(lot, price, _Symbol);
   } else {
      // Si el lote ha cambiado significativamente, rehacer orden
      if(MathAbs(OrderGetDouble(ORDER_VOLUME_INITIAL) - lot) > 0.001) {
         trade.OrderDelete(ticket);
         if(type == ORDER_TYPE_BUY_STOP) trade.BuyStop(lot, price, _Symbol);
         else trade.SellStop(lot, price, _Symbol);
      }
   }
}

void DeletePendings(ENUM_ORDER_TYPE type) {
   for(int i=OrdersTotal()-1; i>=0; i--) {
      ulong t = OrderGetTicket(i);
      if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC) == MagicNumber && OrderGetInteger(ORDER_TYPE) == type) trade.OrderDelete(t);
   }
}

// Re-armado Instantáneo al cerrar operaciones
void OnTradeTransaction(const MqlTradeTransaction& trans, const MqlTradeRequest& req, const MqlTradeResult& res) {
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD) {
      HistoryDealSelect(trans.deal);
      if(HistoryDealGetInteger(trans.deal, DEAL_MAGIC) == MagicNumber) {
         ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
         if(entry == DEAL_ENTRY_OUT) {
            // Se cerró una posición, re-armar gatillos si no hay nada abierto
            if(CountBySide(POSITION_TYPE_BUY) == 0 && CountBySide(POSITION_TYPE_SELL) == 0 && 
               CountPendings(ORDER_TYPE_BUY_STOP) == 0 && CountPendings(ORDER_TYPE_SELL_STOP) == 0) {
               PlaceInitialOrders();
            }
         }
      }
   }
}

double CalculateRecoveryLot(double currentLoss) {
   double atr = GetATRVal();
   if(atr <= 0) return LoteManual * MultiplicadorLote;
   
   double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickVal <= 0) return LoteManual * MultiplicadorLote;

   // Objetivo: Ganar la pérdida + la meta en el recorrido de 1 ATR
   double target = currentLoss + 2.0; 
   double neededLot = target / (atr * (tickVal / tickSize));
   
   return NormalizeLot(neededLot);
}

// =====================================================================
// ========================== INTERFAZ PREMIUM =========================
// =====================================================================
void CreatePremiumHUD() {
   CreateRect("HUD_Bg", 10, 30, 240, 280, ColorPanel);
   CreateText("HUD_T1", "AMETRALLADORA v5.3 ULTRA", 20, 35, 9, clrGold);
   
   // Boton Minimizar
   CreateButton("HUD_Btn_Min", "-", 220, 35, 20, 15);
   
   // Licencia y Cuenta
   CreateText("HUD_L_Lic", "LICENCIA:", 20, 55, 7, clrWhite);
   CreateText("HUD_V_Lic", LicenseKey, 80, 55, 7, clrAqua);
   CreateText("HUD_L_Acc", "TIPO:", 20, 70, 7, clrWhite);
   CreateText("HUD_V_Acc", "ANALIZANDO", 80, 70, 7, clrAqua);
   
   // Market Data
   CreateText("HUD_L_Trend", "MERCADO:", 20, 90, 8, clrWhite);
   CreateText("HUD_V_Trend", "ANALIZANDO", 100, 90, 8, clrAqua);
   CreateText("HUD_L_ATR", "ATR H1:", 20, 105, 8, clrWhite);
   CreateText("HUD_V_ATR", "$0.00", 100, 105, 8, clrAqua);
   
   // Modos de Operación
   CreateButton("HUD_Btn_Zen", "MODO ZEN", 20, 125, 95, 20);
   CreateButton("HUD_Btn_Harvest", "COSECHA", 120, 125, 95, 20);
   
   // Cuenta
   CreateText("HUD_L_Profit", "HOY (PnL):", 20, 155, 8, clrWhite);
   CreateText("HUD_V_Profit", "$0.00", 100, 155, 8, clrGold);
   
   // Botones Dirección
   CreateButton("HUD_Btn_Buy", "SOLO BUY", 20, 185, 95, 25);
   CreateButton("HUD_Btn_Both", "AMBAS", 120, 185, 95, 25);
   CreateButton("HUD_Btn_Sell", "SOLO SELL", 20, 215, 95, 25);
   CreateButton("HUD_Btn_Close", "CLOSE ALL", 120, 215, 95, 25);
   
   // Status
   CreateText("HUD_Status", "STATUS: LISTO", 20, 255, 8, clrWhite);
}

void UpdateHUD() {
   if(isMinimized) {
      ObjectSetInteger(0, "HUD_Bg", OBJPROP_YSIZE, 25);
      ObjectSetString(0, "HUD_Btn_Min", OBJPROP_TEXT, "+");
      for(int i=0; i<ObjectsTotal(0); i++) {
         string name = ObjectName(0, i);
         if(StringFind(name, "HUD_")==0 && name!="HUD_Bg" && name!="HUD_T1" && name!="HUD_Btn_Min")
            ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
      }
      return; 
   } else {
      ObjectSetInteger(0, "HUD_Bg", OBJPROP_YSIZE, 280);
      ObjectSetString(0, "HUD_Btn_Min", OBJPROP_TEXT, "-");
      for(int i=0; i<ObjectsTotal(0); i++) {
         string name = ObjectName(0, i);
         if(StringFind(name, "HUD_")==0)
            ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
      }
   }

   // Tipo de Cuenta y Licencia
   long mode = AccountInfoInteger(ACCOUNT_TRADE_MODE);
   string accStr = "CONTEST";
   if(mode == ACCOUNT_TRADE_MODE_DEMO) {
      int daysLeft = 30 - (int)((TimeCurrent() - licenseStart)/86400);
      if(daysLeft < 0) {
         accStr = "LICENCIA EXPIRADA";
         botStatus = "BLOQUEADO";
      } else accStr = "DEMO (" + IntegerToString(daysLeft) + " DÍAS)";
   } else if(mode == ACCOUNT_TRADE_MODE_REAL) {
      accStr = "REAL";
   }
   ObjectSetString(0, "HUD_V_Acc", OBJPROP_TEXT, accStr);

   // Colores Botones Modos
   ObjectSetInteger(0, "HUD_Btn_Zen", OBJPROP_BGCOLOR, (currentMode == MODE_ZEN ? clrLimeGreen : clrGray));
   ObjectSetInteger(0, "HUD_Btn_Harvest", OBJPROP_BGCOLOR, (currentMode == MODE_COSECHA ? clrOrangeRed : clrGray));

   // Colores Botones Dirección
   ObjectSetInteger(0, "HUD_Btn_Buy", OBJPROP_BGCOLOR, (currentDir == DIR_COMPRAS ? clrDodgerBlue : clrGray));
   ObjectSetInteger(0, "HUD_Btn_Sell", OBJPROP_BGCOLOR, (currentDir == DIR_VENTAS ? clrDodgerBlue : clrGray));
   ObjectSetInteger(0, "HUD_Btn_Both", OBJPROP_BGCOLOR, (currentDir == DIR_AMBAS ? clrDodgerBlue : clrGray));
   
   // Datos Live
   double profit = GetDailyProfit();
   ObjectSetString(0, "HUD_V_Profit", OBJPROP_TEXT, "$" + DoubleToString(profit, 2));
   ObjectSetInteger(0, "HUD_V_Profit", OBJPROP_COLOR, (profit >= 0 ? clrLime : clrRed));
   
   double atr = GetATRVal();
   ObjectSetString(0, "HUD_V_ATR", OBJPROP_TEXT, "$" + DoubleToString(atr, 2));
   
   // Tendencia
   double price = iClose(_Symbol, PERIOD_H1, 0);
   double ema200 = 0, ema50 = 0;
   double b200[], b50[];
   if(CopyBuffer(handleEMA200,0,0,1,b200)>0) ema200 = b200[0];
   if(CopyBuffer(handleEMA50,0,0,1,b50)>0) ema50 = b50[0];
   
   string trendStr = "LATERAL";
   color trendCol = clrWhite;
   if(price > ema50 && price > ema200) { trendStr = "ALCISTA ↑"; trendCol = clrLime; }
   else if(price < ema50 && price < ema200) { trendStr = "BAJISTA ↓"; trendCol = clrRed; }
   ObjectSetString(0, "HUD_V_Trend", OBJPROP_TEXT, trendStr);
   ObjectSetInteger(0, "HUD_V_Trend", OBJPROP_COLOR, trendCol);

   ObjectSetString(0, "HUD_Status", OBJPROP_TEXT, "STATUS: " + botStatus);
}

// =====================================================================
// =========================== UTILIDADES ==============================
// =====================================================================

void CreateRect(string name, int x, int y, int w, int h, color bg) {
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

void CreateText(string name, string txt, int x, int y, int size, color c) {
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetString(0, name, OBJPROP_TEXT, txt);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_COLOR, c);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
}

void CreateButton(string name, string text, int x, int y, int w, int h) {
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrGray);
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == "HUD_Btn_Buy") currentDir = DIR_COMPRAS;
      if(sparam == "HUD_Btn_Sell") currentDir = DIR_VENTAS;
      if(sparam == "HUD_Btn_Both") currentDir = DIR_AMBAS;
      if(sparam == "HUD_Btn_Zen") { currentMode = MODE_ZEN; UpdateModeParams(); }
      if(sparam == "HUD_Btn_Harvest") { currentMode = MODE_COSECHA; UpdateModeParams(); }
      if(sparam == "HUD_Btn_Close") CloseEverything();
      if(sparam == "HUD_Btn_Min") isMinimized = !isMinimized;
      UpdateHUD();
   }
}

bool IsTradingTime() {
   if(!EnableTimeFilter) return true;
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   int h = dt.hour;
   if((h >= StartHour1 && h < EndHour1) || (h >= StartHour2 && h < EndHour2)) return true;
   return false;
}

double GetATRVal() {
   double b[]; if(CopyBuffer(handleATR, 0, 0, 1, b) > 0) return b[0];
   return 0;
}

double GetDailyProfit() {
   HistorySelect(iTime(_Symbol, PERIOD_D1, 0), TimeCurrent());
   double profit = 0;
   for(int i=HistoryDealsTotal()-1; i>=0; i--) {
      ulong t = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(t, DEAL_MAGIC) == MagicNumber)
         profit += HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_COMMISSION) + HistoryDealGetDouble(t, DEAL_SWAP);
   }
   return profit;
}

void CloseEverything() {
   for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic() == MagicNumber) trade.PositionClose(posInfo.Ticket());
   for(int i=OrdersTotal()-1; i>=0; i--) {
      ulong t = OrderGetTicket(i);
      if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC) == MagicNumber) trade.OrderDelete(t);
   }
}

void PlaceInitialOrders() {
   DeletePendings(ORDER_TYPE_BUY_STOP);
   DeletePendings(ORDER_TYPE_SELL_STOP);
   double dist = 200 * _Point; 
   double lot = CalculateLot();
   if(currentDir == DIR_COMPRAS || currentDir == DIR_AMBAS) trade.BuyStop(lot, SymbolInfoDouble(_Symbol, SYMBOL_ASK) + dist, _Symbol);
   if(currentDir == DIR_VENTAS || currentDir == DIR_AMBAS) trade.SellStop(lot, SymbolInfoDouble(_Symbol, SYMBOL_BID) - dist, _Symbol);
   botStatus = "ACECHANDO";
}

void PlaceRecoveryOrder(ENUM_POSITION_TYPE type, double lot) {
   double dist = 100 * _Point;
   if(type == POSITION_TYPE_BUY) trade.BuyStop(lot, SymbolInfoDouble(_Symbol, SYMBOL_ASK) + dist, _Symbol);
   else trade.SellStop(lot, SymbolInfoDouble(_Symbol, SYMBOL_BID) - dist, _Symbol);
   botStatus = "RESCATE ARMADO (" + DoubleToString(lot, 2) + ")";
}

double CalculateLot() {
   if(RiskPercent <= 0) return LoteManual;
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = balance * RiskPercent / 100.0;
   double atr = GetATRVal();
   if(atr <= 0) return LoteManual;
   double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double lot = riskMoney / (atr * SL_Mult_Gold * (tickVal / tickSize));
   return NormalizeLot(lot);
}

double NormalizeLot(double l) {
   double min = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double res = MathFloor(l/step)*step;
   if(res < min) res = min;
   return res;
}

void ApplyInstantBE(ulong ticket) {
   if(posInfo.SelectByTicket(ticket)) {
      double open = posInfo.PriceOpen();
      double currentSL = posInfo.StopLoss();
      double sl = (posInfo.PositionType() == POSITION_TYPE_BUY) ? open + 50*_Point : open - 50*_Point;
      if(currentSL == 0 || (posInfo.PositionType() == POSITION_TYPE_BUY && sl > currentSL) || (posInfo.PositionType() == POSITION_TYPE_SELL && sl < currentSL))
         trade.PositionModify(ticket, sl, posInfo.TakeProfit());
   }
}

bool CheckEntryConfirm() {
   double price = iClose(_Symbol, PERIOD_H1, 0);
   double b200[], b50[];
   if(CopyBuffer(handleEMA200, 0, 0, 1, b200) <= 0) return false;
   if(CopyBuffer(handleEMA50, 0, 0, 1, b50) <= 0) return false;
   
   if(currentDir == DIR_COMPRAS && price > b50[0] && price > b200[0]) return true;
   if(currentDir == DIR_VENTAS && price < b50[0] && price < b200[0]) return true;
   if(currentDir == DIR_AMBAS) return true;
   return false;
}

int CountBySide(ENUM_POSITION_TYPE type) {
   int c=0; for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic() == MagicNumber && posInfo.PositionType() == type) c++;
   return c;
}

int CountPendings(ENUM_ORDER_TYPE type) {
   int c=0; for(int i=0; i<OrdersTotal(); i++) {
      ulong t = OrderGetTicket(i);
      if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC) == MagicNumber && OrderGetInteger(ORDER_TYPE) == type) c++;
   }
   return c;
}

double GetTotalProfitSide(ENUM_POSITION_TYPE type) {
   double p=0; for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic() == MagicNumber && posInfo.PositionType() == type) p += posInfo.Profit();
   return p;
}

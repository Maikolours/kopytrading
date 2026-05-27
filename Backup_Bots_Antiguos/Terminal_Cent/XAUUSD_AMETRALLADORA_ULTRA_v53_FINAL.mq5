//+------------------------------------------------------------------+
//| LA AMETRALLADORA ULTRA v5.3 – MT5                                |
//| Pro-Level Gold Bot with Momentum, HUD, & Telegram Mobile Bridge   |
//+------------------------------------------------------------------+
#property strict
#property version "5.32"
#property copyright "Copyright 2026, Kopytrade Corp."
#property link      "https://www.kopytrade.com"

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/SymbolInfo.mqh>

// =====================================================================
// ========================== INPUT PARAMETERS =========================
// =====================================================================

// --- LICENCIA ---
input string   LicenseKey        = "DEMO-2026";

// --- MOBILE BRIDGE (TELEGRAM) ---
input string   TelegramToken     = "";         // Token del Bot (ej: 123456:ABC...)
input long     TelegramChatID    = 0;          // Tu Chat ID (ej: 987654321)
input bool     NotificarTelegram = true;       // Enviar alertas al móvil

// --- GESTIÓN DE RIESGO (v5.2) ---
input double   RiskPercent        = 0.5;       // % de Riesgo por operación
input int      MagicNumber        = 202509;    // Magic Number
input double   LoteManual         = 0.01;      // Lote si Risk es 0

// --- RESCATE MATEMÁTICO (ULTRA) ---
input bool     ActivarRescate     = true;      // 🚑 Activar Operación de Rescate
input double   MultiplicadorLote  = 2.0;       // Multiplicador base Martingala
input double   DistanciaRescate   = 3.0;       // $ Perdida para activar gatillo
input int      DelayRescateSegs   = 120;       // Segundos de espera para rescatar (2 min)

// --- META DIARIA ---
input double   MetaDiaria_USD      = 25.0;     // 🎯 Ganancia Diaria ($). 0 = Desactivado.

// --- FILTRO DE HORARIO (Double v5.2) ---
input bool     EnableTimeFilter    = true;     // ⏰ Activar filtro de horario
input int      StartHour1          = 9;        
input int      StartMinute1        = 0;        
input int      EndHour1            = 14;       
input int      EndMinute1          = 0;        
input int      StartHour2          = 17;       
input int      StartMinute2        = 0;        
input int      EndHour2            = 21;       
input int      EndMinute2          = 30;       

// --- STOP LOSS Y TAKE PROFIT (ATR v5.2) ---
input int      ATR_Period         = 14;        
input double   SL_Mult_Gold       = 1.3;       
input double   TP_Mult_Gold       = 1.0;       

// --- ESTRATEGIA (MOMENTUM v5.2) ---
input int      MomentumCandles     = 3;        
input int      MomentumRequired    = 2;        
input int      CooldownSeconds     = 60;       

// --- CORTAFUEGOS (ULTRA) ---
input bool     ActivarCortafuegos  = true;     
input double   Meta_Ciclo_USD      = 5.0;       // Neto para cerrar ciclo (+$5)
input double   Harvest_TP_USD      = 3.0;       // TP individual (+$3)

// --- BREAK EVEN Y TRAILING (v5.2) ---
input bool     EnableBE            = true;     
input double   BE_Trigger_USD      = 2.5;      
input double   BE_Cushion_USD      = 1.0;      
input bool     EnableTrailing      = true;     
input double   Trail_Trigger_USD   = 2.5;      
input double   Trail_Distance_USD  = 1.5;      

// --- PANEL VISUAL ---
input bool     ShowHUD             = true;     
input color    ColorPanel          = C'10,15,30';

// =====================================================================
// ======================== VARIABLES GLOBALES =========================
// =====================================================================
CTrade         trade;
CPositionInfo  posInfo;
int            atrHandle;
int            handleEMA50, handleEMA200;
datetime       lastTradeTime = 0;
datetime       coolingEndTime = 0;
datetime       licenseStart = 0;
long           lastUpdateID = 0;

enum ENUM_DIR  { DIR_COMPRAS, DIR_VENTAS, DIR_AMBAS };
enum ENUM_MODE { MODE_ZEN, MODE_COSECHA };

ENUM_DIR       currentDir = DIR_AMBAS;
ENUM_MODE      currentMode = MODE_COSECHA;
string         botStatus = "LISTO";
bool           isMinimized = false;
bool           remotePaused = false; 

double         mode_HarvestTP = 3.0;
double         mode_CycleMeta = 5.0;
double         mode_BETrigger = 2.5;

// =====================================================================
// ========================== INICIALIZACIÓN ===========================
// =====================================================================
int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);
   atrHandle = iATR(_Symbol, _Period, ATR_Period);
   handleEMA50 = iMA(_Symbol, PERIOD_H1, 50, 0, MODE_EMA, PRICE_CLOSE);
   handleEMA200 = iMA(_Symbol, PERIOD_H1, 200, 0, MODE_EMA, PRICE_CLOSE);
   
   if(atrHandle == INVALID_HANDLE) return(INIT_FAILED);
   
   licenseStart = TimeCurrent() - (86400 * 5); 
   
   if(ShowHUD) CreatePremiumHUD();
   UpdateModeParams();
   
   if(NotificarTelegram && TelegramToken != "") 
      SendTelegramMessage("🚀 LA AMETRALLADORA ULTRA v5.3 Iniciada.\n\nComandos:\n/status - Ver PnL\n/pause - Apagar Bot\n/resume - Encender Bot\n/closeall - Cerrar TODO y Pausar");

   EventSetTimer(3); 
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, "HUD_");
   Comment("");
}

// =====================================================================
// ========================= LÓGICA PRINCIPAL ==========================
// =====================================================================
void OnTick()
{
   double dailyProfit = GetDailyProfit();
   
   if(remotePaused) {
      botStatus = "🔴 PAUSA REMOTA (MÓVIL)";
      DeleteBotPendings();
      if(ShowHUD) UpdateHUD(dailyProfit);
      return;
   }

   if(MetaDiaria_USD > 0 && dailyProfit >= MetaDiaria_USD) {
      botStatus = "META ALCANZADA";
      if(ShowHUD) UpdateHUD(dailyProfit);
      return;
   }

   if(!IsTradingTime() || TimeCurrent() < coolingEndTime) {
      botStatus = (TimeCurrent() < coolingEndTime) ? "ENFRIANDO" : "FUERA DE HORARIO";
      if(ShowHUD) UpdateHUD(dailyProfit);
      return;
   }

   ManageOpenPositions();
   MaintainGates();

   if(ShowHUD) UpdateHUD(dailyProfit);
}

void OnTimer()
{
   if(TelegramToken != "") ProcessTelegramCommands();
}

// =====================================================================
// ======================= TELEGRAM BRIDGE =============================
// =====================================================================

void ProcessTelegramCommands()
{
   string url = "https://api.telegram.org/bot" + TelegramToken + "/getUpdates?offset=" + IntegerToString(lastUpdateID + 1);
   char post[], result[];
   string headers;
   int res = WebRequest("GET", url, headers, 1000, post, result, headers);
   
   if(res == 200)
   {
      string response = CharArrayToString(result);
      if(StringFind(response, "\"/status\"") != -1) { 
         if(remotePaused) SendTelegramStatus("🔴"); 
         else SendTelegramStatus("🟢"); 
         lastUpdateID = ParseUpdateID(response); 
      }
      if(StringFind(response, "\"/pause\"") != -1) { remotePaused = true; SendTelegramMessage("🔴 LA AMETRALLADORA PAUSADA."); lastUpdateID = ParseUpdateID(response); }
      if(StringFind(response, "\"/resume\"") != -1) { remotePaused = false; SendTelegramMessage("🟢 LA AMETRALLADORA REANUDADA."); lastUpdateID = ParseUpdateID(response); }
      if(StringFind(response, "\"/closeall\"") != -1) { CloseAllBotPositions(); remotePaused = true; SendTelegramMessage("🛑 TODO CERRADO y Bot PAUSADO."); lastUpdateID = ParseUpdateID(response); }
      if(StringFind(response, "\"/zen\"") != -1) { currentMode = MODE_ZEN; UpdateModeParams(); SendTelegramMessage("🧘 MODO ZEN ACTIVADO."); lastUpdateID = ParseUpdateID(response); }
      if(StringFind(response, "\"/cosecha\"") != -1) { currentMode = MODE_COSECHA; UpdateModeParams(); SendTelegramMessage("🚜 MODO COSECHA ACTIVADO."); lastUpdateID = ParseUpdateID(response); }
   }
}

long ParseUpdateID(string json)
{
   int pos = StringFind(json, "\"update_id\":");
   if(pos == -1) return lastUpdateID;
   string sub = StringSubstr(json, pos + 12);
   int end = StringFind(sub, ",");
   return (long)StringToInteger(StringSubstr(sub, 0, end));
}

void SendTelegramMessage(string msg)
{
   if(TelegramToken == "" || TelegramChatID == 0) return;
   string url = "https://api.telegram.org/bot" + TelegramToken + "/sendMessage?chat_id=" + IntegerToString(TelegramChatID) + "&text=" + UrlEncode(msg);
   char post[], result[];
   string headers;
   WebRequest("GET", url, headers, 1000, post, result, headers);
}

void SendTelegramStatus(string emoji)
{
   string msg = emoji + " LA AMETRALLADORA ULTRA\n\n";
   msg += "PnL Hoy: $" + DoubleToString(GetDailyProfit(), 2) + "\n";
   msg += "Posiciones: " + IntegerToString(PositionsTotalBots()) + "\n";
   msg += "Modo: " + (currentMode == MODE_ZEN ? "ZEN 🧘" : "COSECHA 🚜") + "\n";
   msg += "Status: " + botStatus;
   SendTelegramMessage(msg);
}

string UrlEncode(string text)
{
   string encoded = "";
   for(int i=0; i<StringLen(text); i++)
   {
      ushort c = StringGetCharacter(text, i);
      if(c == ' ') encoded += "%20";
      else if(c == '\n') encoded += "%0A";
      else encoded += ShortToString(c);
   }
   return encoded;
}

// =====================================================================
// ======================= GESTIÓN POSICIONES ==========================
// =====================================================================

void ManageOpenPositions()
{
   double netProfit = 0;
   int botPosCount = 0;

   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(posInfo.SelectByIndex(i) && posInfo.Magic() == MagicNumber)
      {
         botPosCount++;
         double p = posInfo.Profit() + posInfo.Commission() + posInfo.Swap();
         netProfit += p;
         
         if(p >= mode_HarvestTP) {
            trade.PositionClose(posInfo.Ticket());
            if(NotificarTelegram) SendTelegramMessage("✅ Cosecha Individual: +$" + DoubleToString(p, 2));
            continue;
         }

         if(p >= 2.0 && CountBySideAndComment((ENUM_POSITION_TYPE)posInfo.PositionType(), "REFUERZO") == 0 && botPosCount == 1)
         {
            double rLot = NormalizeLot(posInfo.Volume() * 1.5);
            if(posInfo.PositionType() == POSITION_TYPE_BUY) trade.Buy(rLot, _Symbol, 0, 0, 0, "REFUERZO");
            else trade.Sell(rLot, _Symbol, 0, 0, 0, "REFUERZO");
            if(NotificarTelegram) SendTelegramMessage("🚀 Refuerzo Inyectado (Lot: " + DoubleToString(rLot, 2) + ")");
         }

         if(p <= -DistanciaRescate && ActivarRescate)
         {
            datetime openTime = (datetime)posInfo.IntegerProperty(POSITION_TIME);
            if(TimeCurrent() - openTime >= DelayRescateSegs && CountBySideAndComment(OppositeType((ENUM_POSITION_TYPE)posInfo.PositionType()), "RESCATE") == 0)
            {
               double resLot = CalculateRecoveryLot(MathAbs(p));
               if(posInfo.PositionType() == POSITION_TYPE_BUY) trade.Sell(resLot, _Symbol, 0, 0, 0, "RESCATE");
               else trade.Buy(resLot, _Symbol, 0, 0, 0, "RESCATE");
               if(NotificarTelegram) SendTelegramMessage("🚑 Rescate Activado! Cubriendo pérdida de $" + DoubleToString(p, 2));
            }
         }

         ManageBEandTrail(posInfo.Ticket(), p);
      }
   }

   if(botPosCount >= 2 && netProfit >= mode_CycleMeta)
   {
      CloseAllBotPositions();
      coolingEndTime = TimeCurrent() + CooldownSeconds;
      if(NotificarTelegram) SendTelegramMessage("💰 CICLO COMPLETADO: +$" + DoubleToString(netProfit, 2));
   }
}

void ManageBEandTrail(ulong ticket, double profit)
{
   if(posInfo.SelectByTicket(ticket))
   {
      double open = posInfo.PriceOpen();
      double currentSL = posInfo.StopLoss();
      double lot = posInfo.Volume();
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double newSL = 0;
      
      if(EnableBE && profit >= mode_BETrigger)
      {
         if(posInfo.PositionType() == POSITION_TYPE_BUY) newSL = open + USDtoPrice(BE_Cushion_USD, lot);
         else newSL = open - USDtoPrice(BE_Cushion_USD, lot);
         newSL = NormalizeDouble(newSL, _Digits);
         if((posInfo.PositionType() == POSITION_TYPE_BUY && (currentSL == 0 || newSL > currentSL)) ||
            (posInfo.PositionType() == POSITION_TYPE_SELL && (currentSL == 0 || newSL < currentSL)))
            trade.PositionModify(ticket, newSL, posInfo.TakeProfit());
      }
      
      if(EnableTrailing && profit >= Trail_Trigger_USD)
      {
         if(posInfo.PositionType() == POSITION_TYPE_BUY) newSL = bid - USDtoPrice(Trail_Distance_USD, lot);
         else newSL = ask + USDtoPrice(Trail_Distance_USD, lot);
         newSL = NormalizeDouble(newSL, _Digits);
         if((posInfo.PositionType() == POSITION_TYPE_BUY && newSL > currentSL) ||
            (posInfo.PositionType() == POSITION_TYPE_SELL && (currentSL == 0 || newSL < currentSL)))
            trade.PositionModify(ticket, newSL, posInfo.TakeProfit());
      }
   }
}

// =====================================================================
// ======================== GESTIÓN DE GATILLOS ========================
// =====================================================================

void MaintainGates()
{
   if(remotePaused) { DeleteBotPendings(); return; }
   if(PositionsTotalBots() > 0) { DeleteBotPendings(); return; }

   if(!CheckMomentumGates()) { DeleteBotPendings(); return; }

   int p_buys = CountPendings(ORDER_TYPE_BUY_STOP);
   int p_sells = CountPendings(ORDER_TYPE_SELL_STOP);
   double dist = 200 * _Point;
   double lot = CalculateInitialLot();

   if((currentDir == DIR_COMPRAS || currentDir == DIR_AMBAS) && p_buys == 0)
      trade.BuyStop(lot, SymbolInfoDouble(_Symbol, SYMBOL_ASK) + dist, _Symbol);
      
   if((currentDir == DIR_VENTAS || currentDir == DIR_AMBAS) && p_sells == 0)
      trade.SellStop(lot, SymbolInfoDouble(_Symbol, SYMBOL_BID) - dist, _Symbol);
}

bool CheckMomentumGates()
{
   int c_up = 0, c_dn = 0;
   for(int i=1; i<=MomentumCandles; i++) {
      double o = iOpen(_Symbol, _Period, i);
      double c = iClose(_Symbol, _Period, i);
      if(c > o) c_up++;
      if(c < o) c_dn++;
   }
   return (c_up >= MomentumRequired || c_dn >= MomentumRequired);
}

// =====================================================================
// =========================== UTILIDADES ==============================
// =====================================================================

double CalculateInitialLot()
{
   if(RiskPercent <= 0) return LoteManual;
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = balance * RiskPercent / 100.0;
   double atr = GetATR();
   if(atr <= 0) return LoteManual;
   double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double lot = riskMoney / (atr * SL_Mult_Gold * (tickVal / tickSize));
   return NormalizeLot(lot);
}

double CalculateRecoveryLot(double loss)
{
   double atr = GetATR();
   if(atr <= 0) return NormalizeLot(LoteManual * MultiplicadorLote);
   double target = loss + 2.0; 
   double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double lot = target / (atr * (tickVal / tickSize));
   return NormalizeLot(lot);
}

double NormalizeLot(double l)
{
   double min = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double res = MathFloor(l/step)*step;
   if(res < min) res = min;
   return res;
}

double GetATR()
{
   double b[];
   if(CopyBuffer(atrHandle, 0, 0, 1, b) > 0) return b[0];
   return 0;
}

double GetDailyProfit()
{
   HistorySelect(iTime(_Symbol, PERIOD_D1, 0), TimeCurrent());
   double p = 0;
   for(int i=HistoryDealsTotal()-1; i>=0; i--) {
      ulong t = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(t, DEAL_MAGIC) == MagicNumber)
         p += HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_COMMISSION) + HistoryDealGetDouble(t, DEAL_SWAP);
   }
   return p;
}

int CountBySideAndComment(ENUM_POSITION_TYPE type, string cmnt)
{
   int c = 0;
   for(int i=0; i<PositionsTotal(); i++) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic() == MagicNumber && posInfo.PositionType() == type && posInfo.Comment() == cmnt) c++;
   }
   return c;
}

int PositionsTotalBots()
{
   int c = 0;
   for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic() == MagicNumber) c++;
   return c;
}

void CloseAllBotPositions()
{
   for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic() == MagicNumber) trade.PositionClose(posInfo.Ticket());
}

void CloseLastPosition()
{
   ulong lastTicket = 0;
   datetime lastTime = 0;
   for(int i=0; i<PositionsTotal(); i++) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic() == MagicNumber) {
         if(posInfo.Time() > lastTime) {
            lastTime = posInfo.Time();
            lastTicket = posInfo.Ticket();
         }
      }
   }
   if(lastTicket > 0) trade.PositionClose(lastTicket);
}

void DeleteBotPendings()
{
   for(int i=OrdersTotal()-1; i>=0; i--) {
      ulong t = OrderGetTicket(i);
      if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC) == MagicNumber) trade.OrderDelete(t);
   }
}

int CountPendings(ENUM_ORDER_TYPE type)
{
   int c=0; for(int i=0; i<OrdersTotal(); i++) {
      ulong t = OrderGetTicket(i);
      if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC) == MagicNumber && OrderGetInteger(ORDER_TYPE) == type) c++;
   }
   return c;
}

ENUM_POSITION_TYPE OppositeType(ENUM_POSITION_TYPE type) { return (type == POSITION_TYPE_BUY) ? POSITION_TYPE_SELL : POSITION_TYPE_BUY; }

double USDtoPrice(double usd, double lot)
{
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tv <= 0 || lot <= 0) return 0;
   return (usd * ts) / (tv * lot);
}

bool IsTradingTime()
{
   if(!EnableTimeFilter) return true;
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   int m = dt.hour * 60 + dt.min;
   int s1 = StartHour1 * 60 + StartMinute1;
   int e1 = EndHour1 * 60 + EndMinute1;
   int s2 = StartHour2 * 60 + StartMinute1;
   int e2 = EndHour2 * 60 + EndMinute2;
   return ((m >= s1 && m < e1) || (m >= s2 && m < e2));
}

// =====================================================================
// ========================== INTERFAZ PREMIUM =========================
// =====================================================================
void CreatePremiumHUD()
{
   CreateRect("HUD_Bg", 10, 30, 240, 310, ColorPanel);
   CreateText("HUD_T1", "LA AMETRALLADORA ULTRA v5.3", 20, 35, 9, clrGold);
   CreateButton("HUD_Btn_Min", "-", 220, 35, 20, 15);
   
   CreateText("HUD_L_Lic", "LICENCIA:", 20, 55, 7, clrWhite);
   CreateText("HUD_V_Lic", LicenseKey, 80, 55, 7, clrAqua);
   
   CreateButton("HUD_Btn_Zen", "MODO ZEN", 20, 80, 95, 20);
   CreateButton("HUD_Btn_Cosecha", "COSECHA", 120, 80, 95, 20);
   
   CreateText("HUD_L_Profit", "HOY (PnL):", 20, 110, 8, clrWhite);
   CreateText("HUD_V_Profit", "$0.00", 100, 110, 8, clrGold);
   
   CreateButton("HUD_Btn_Buy", "SOLO BUY", 20, 140, 95, 22);
   CreateButton("HUD_Btn_Both", "AMBAS", 120, 140, 95, 22);
   CreateButton("HUD_Btn_Sell", "SOLO SELL", 20, 170, 95, 22);
   CreateButton("HUD_Btn_Close", "CLOSE ALL", 120, 170, 95, 22);
   
   CreateButton("HUD_Btn_CloseLast", "CERRAR ULTIMA", 20, 200, 195, 22);
   
   CreateText("HUD_L_ATR", "ATR:", 20, 230, 8, clrWhite);
   CreateText("HUD_V_ATR", "0.00", 100, 230, 8, clrAqua);
   CreateText("HUD_L_Trend", "TENDENCIA:", 20, 245, 8, clrWhite);
   CreateText("HUD_V_Trend", "...", 100, 245, 8, clrAqua);
   
   CreateText("HUD_Status", "STATUS: LISTO", 20, 265, 8, clrWhite);
   CreateText("HUD_Remote", "REMOTO:🟢 ONLINE", 20, 285, 7, clrLime);
}

void UpdateHUD(double dailyProfit)
{
   if(isMinimized) {
      ObjectSetInteger(0, "HUD_Bg", OBJPROP_YSIZE, 25);
      ObjectSetString(0, "HUD_Btn_Min", OBJPROP_TEXT, "+");
      HideHUDObjects(true);
      return; 
   } else {
      ObjectSetInteger(0, "HUD_Bg", OBJPROP_YSIZE, 310);
      ObjectSetString(0, "HUD_Btn_Min", OBJPROP_TEXT, "-");
      HideHUDObjects(false);
   }

   ObjectSetString(0, "HUD_V_Profit", OBJPROP_TEXT, "$" + DoubleToString(dailyProfit, 2));
   ObjectSetInteger(0, "HUD_V_Profit", OBJPROP_COLOR, (dailyProfit >= 0 ? clrLime : clrRed));
   ObjectSetString(0, "HUD_V_ATR", OBJPROP_TEXT, DoubleToString(GetATR(), 2));
   
   ObjectSetString(0, "HUD_Status", OBJPROP_TEXT, "STATUS: " + botStatus);
   ObjectSetString(0, "HUD_Remote", OBJPROP_TEXT, "REMOTO: " + (remotePaused ? "🔴 PAUSADO":"🟢 ONLINE"));
   ObjectSetInteger(0, "HUD_Remote", OBJPROP_COLOR, (remotePaused ? clrRed : clrLime));

   ObjectSetInteger(0, "HUD_Btn_Zen", OBJPROP_BGCOLOR, (currentMode == MODE_ZEN ? clrLimeGreen : clrGray));
   ObjectSetInteger(0, "HUD_Btn_Cosecha", OBJPROP_BGCOLOR, (currentMode == MODE_COSECHA ? clrOrangeRed : clrGray));
   ObjectSetInteger(0, "HUD_Btn_Buy", OBJPROP_BGCOLOR, (currentDir == DIR_COMPRAS ? clrDodgerBlue : clrGray));
   ObjectSetInteger(0, "HUD_Btn_Sell", OBJPROP_BGCOLOR, (currentDir == DIR_VENTAS ? clrDodgerBlue : clrGray));
   ObjectSetInteger(0, "HUD_Btn_Both", OBJPROP_BGCOLOR, (currentDir == DIR_AMBAS ? clrDodgerBlue : clrGray));
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == "HUD_Btn_Zen") { currentMode = MODE_ZEN; UpdateModeParams(); }
      if(sparam == "HUD_Btn_Cosecha") { currentMode = MODE_COSECHA; UpdateModeParams(); }
      if(sparam == "HUD_Btn_Buy") currentDir = DIR_COMPRAS;
      if(sparam == "HUD_Btn_Sell") currentDir = DIR_VENTAS;
      if(sparam == "HUD_Btn_Both") currentDir = DIR_AMBAS;
      if(sparam == "HUD_Btn_Close") CloseAllBotPositions();
      if(sparam == "HUD_Btn_CloseLast") CloseLastPosition();
      if(sparam == "HUD_Btn_Min") isMinimized = !isMinimized;
      UpdateHUD(GetDailyProfit());
   }
}

void UpdateModeParams()
{
   if(currentMode == MODE_ZEN) { mode_HarvestTP = 1.0; mode_CycleMeta = 2.0; mode_BETrigger = 1.0; }
   else { mode_HarvestTP = Harvest_TP_USD; mode_CycleMeta = Meta_Ciclo_USD; mode_BETrigger = BE_Trigger_USD; }
}

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

void HideHUDObjects(bool hide) {
   for(int i=0; i<ObjectsTotal(0); i++) {
      string n = ObjectName(0, i);
      if(StringFind(n, "HUD_") == 0 && n != "HUD_Bg" && n != "HUD_T1" && n != "HUD_Btn_Min")
         ObjectSetInteger(0, n, OBJPROP_TIMEFRAMES, hide ? OBJ_NO_PERIODS : OBJ_ALL_PERIODS);
   }
}

void OnTradeTransaction(const MqlTradeTransaction& trans, const MqlTradeRequest& req, const MqlTradeResult& res)
{
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD) {
      if(PositionsTotalBots() == 0) MaintainGates();
   }
}

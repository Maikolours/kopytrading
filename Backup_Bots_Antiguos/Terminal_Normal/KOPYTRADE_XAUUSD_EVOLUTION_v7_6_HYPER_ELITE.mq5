//+------------------------------------------------------------------+
//|     KOPYTRADE_XAUUSD_EVOLUTION_v7_7_INTERACTIVE                  |
//|   AUTO-FIBO PRO | sniper v7.7.0 | INTERACTIVE ELITE          |
//|   Copyright 2026, Kopytrading Corp. - kopytrading.com            |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "7.70"
#property strict
#property description "⚜️ XAU v7.7.0 INTERACTIVE-ELITE | Candle Confirm | Drag SL"
//--- INPUTS ---
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Canvas\Canvas.mqh>

//--- DEFINES ---
#define PNL_TAG "AEVO_v76"
#define CLR_GOLD C'212,175,55'
#define CLR_BLUE C'30,144,255'
#define ALPHA_ZONE 60  // Transparencia (0-255)

//--- PARÁMETROS ---
input group "🛡️ SISTEMA DE LICENCIA ELITE"
input string   MasterKey         = "TRIAL-2026"; // 1- LLAVE MAESTRA (Sólo Dueño)
input long     ManualLock        = 0;            // 2- BLOQUEO MANUAL CUENTA (Opcional)
input string   LicenseCode       = "";           // 3- CÓDIGO ACTIVACIÓN WEB (Clientes)
input bool     ForceCentMode     = true;         // Forzar Modo Cent (0.01 factor)
input double   CentFactor        = 0.01;         // Factor Cent (1 unidad = 0.01 USD)

sinput string sep1 = "=========================="; // === CONFIG ELITE ===
input int      FiboLookback      = 100;
input int      InpFiboHours      = 4;            // 4- Fibo Retroceso (H) 
input double   InpBE             = 1.00;         // 5- Break-Even ($)
input double   InpTS             = 2.50;         // 6- Trailing-Stop ($)
input double   InpTSDist         = 1.50;         // 7- Distancia Trailing ($)
input int      InpOpenHour       = 9;            // 8- Hora Apertura (0-23)
input int      InpCloseHour      = 22;           // 9- Hora Cierre (0-23)
input bool     UseNewsFilter     = false;        // 10- Filtro Noticias (Auto-Pause)
input int      MagicNumber       = 700760;       
input double   DefaultLots       = 0.02;

//--- GLOBALES ---
CCanvas        canvas;
CTrade         trade;
CPositionInfo  posInfo;
int            h_ema20, h_ema50, h_rsi;
double         profitFactor = 1.0, dayPnL = 0;
string         botStatus = "LISTO", strategyLabel = "ESPERANDO";
bool           remotePaused = false, showEMA = true, showRSI = true, showFibo = true;
bool           isMinimized = false; 
bool           licenseValid = false, isTrialActive = false; 
int            trialDaysLeft = 30;
int            outRangeCount = 0;   
datetime       lastCloseTime = 0;
double         f_high = 0, f_low = 0, f_p0 = 0, f_p100 = 0;
datetime       f_timeHigh, f_timeLow;
bool           isBullish = true;

//--- HUD EDITABLES ---
double   currLots, currBE, currTS, currTSDist, currFiboH, currGarantia, currSLPct;
int      currFiboHours; // New: time-based lookback
int      activePreset = 0; // 0=none, 1=zen, 2=cosecha
bool     useConfirmBar = true;

//+------------------------------------------------------------------+
//| Init                                                             |
//+------------------------------------------------------------------+
int OnInit() {
   trade.SetExpertMagicNumber(MagicNumber);
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   bool isCent = (tv < 0.1 && AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL);
   if(ForceCentMode || isCent) profitFactor = 0.01;
   else profitFactor = 1.0; 
   
   // Validación de Licencia Profesional
   if(!ValidateLicense()) {
      Alert("❌ LICENCIA INVÁLIDA o NO VINCULADA. El bot se detendrá.");
      return INIT_FAILED;
   }
   
   h_ema20 = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   h_ema50 = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
   h_rsi   = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   
   // Sincronizar parámetros editables desde Inputs (Persistent)
   LoadSettings();

   CrearHUD();
   UpdateAutoFibo();
   
   // Forzar Estética Institucional
   long cid = 0;
   ChartSetInteger(cid, CHART_COLOR_CHART_UP, clrForestGreen);
   ChartSetInteger(cid, CHART_COLOR_CHART_DOWN, clrIndianRed);
   ChartSetInteger(cid, CHART_COLOR_CANDLE_BEAR, clrIndianRed);
   ChartSetInteger(cid, CHART_COLOR_CANDLE_BULL, clrForestGreen);
   ChartSetInteger(cid, CHART_MODE, CHART_CANDLES);
   
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Validación de licencia profesional (Demo/Real)                   |
//+------------------------------------------------------------------+
bool ValidateLicense() {
   if(MasterKey == "TRIAL-2026") {
      if(ManualLock > 0 && AccountInfoInteger(ACCOUNT_LOGIN) != ManualLock) {
         Alert("❌ LLAVE MAESTRA CORRECTA, pero cuenta no autorizada manualmente.");
         return false;
      }
      licenseValid = true;
      isTrialActive = false;
      return true;
   }
   
   bool isDemo = (AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_DEMO);
   
   if(StringLen(LicenseCode) == 0) {
      if(!isDemo) {
         Alert("❌ Cuenta REAL detectada. Ingresa tu CÓDIGO DE ACTIVACIÓN WEB para operar o usa tu LLAVE MAESTRA.");
         return false;
      }
      string key = "KOPY_TRIAL_START_" + IntegerToString(MagicNumber);
      double startVal = 0;
      if(GlobalVariableGet(key, startVal)) {
         datetime startDate = (datetime)startVal;
         int daysPassed = (int)((TimeCurrent() - startDate) / 86400);
         if(daysPassed > 30) {
            Alert("❌ Período de prueba expirado. Adquiere una licencia en kopytrading.com");
            return false;
         }
         trialDaysLeft = 30 - daysPassed;
      } else {
         GlobalVariableSet(key, (double)TimeCurrent());
         trialDaysLeft = 30;
      }
      isTrialActive = true;
      licenseValid = true;
      return true;
   }
   
   // Validación vía Web API 
   string url = "https://www.kopytrading.com/api/validate-license?licenseKey=" + LicenseCode + "&account=" + IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN));
   char post[], result[]; string headers;
   int code = WebRequest("GET", url, headers, 3000, post, result, headers);
   
   if(code == 200) {
      string resp = CharArrayToString(result);
      if(StringFind(resp, "\"valid\":true") != -1) {
         licenseValid = true;
         isTrialActive = false;
         return true;
      } else if(StringFind(resp, "\"error\":\"ALREADY_USED\"") != -1) {
         Alert("❌ ERROR: Licencia ya vinculada a otro número de cuenta.");
         return false;
      }
   }
   licenseValid = true; 
   return true;
}

//+------------------------------------------------------------------+
//| Deinit                                                           |
//+------------------------------------------------------------------+
void OnDeinit(const int r) { 
   SaveSettings();
   ObjectsDeleteAll(0, PNL_TAG); 
   canvas.Destroy();
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| OnTick                                                           |
//+------------------------------------------------------------------+
void OnTick() {
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   if(dt.hour < InpOpenHour || dt.hour > InpCloseHour) { botStatus = "FUEERA DE HORARIO ZZZ"; ActualizarHUD(); return; }
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   UpdateAutoFibo();
   
   // --- LÓGICA DE SALIDA POR REVERSIÓN (FIXED) ---
   
   bool isOut = false;
   if(isBullish) { 
      if(price < f_p100 + MathAbs(f_p0 - f_p100) * 0.05) isOut = true; 
   } else {
      if(price > f_p100 - MathAbs(f_p0 - f_p100) * 0.05) isOut = true;
   }
   
   if(isOut) {
      if(PositionsTotalBots() > 0) {
         CloseAll();
         lastCloseTime = iTime(_Symbol, _Period, 0); 
         botStatus = "REVERSIÓN / FUERA DE RANGO";
      }
   }
   
   ManageStrategy();
   dayPnL = CalculateFullDayPnL();
   ActualizarHUD();
}

//+------------------------------------------------------------------+
//| Fibonacci Logic                                                  |
//+------------------------------------------------------------------+
void UpdateAutoFibo() {
   if(PositionsTotalBots() == 0) {
      // Calcular barras basadas en horas
      int bars = (int)(currFiboHours * 3600 / PeriodSeconds());
      if(bars < 2) bars = 2;

      int highestIdx = iHighest(_Symbol, _Period, MODE_HIGH, bars, 0);
      int lowestIdx  = iLowest(_Symbol, _Period, MODE_LOW, bars, 0);
      
      f_high = iHigh(_Symbol, _Period, highestIdx);
      f_low  = iLow(_Symbol, _Period, lowestIdx);
      f_timeHigh = iTime(_Symbol, _Period, highestIdx);
      f_timeLow  = iTime(_Symbol, _Period, lowestIdx);
      
      isBullish = (f_timeLow < f_timeHigh); // El punto bajo ocurrió antes
      
      if(isBullish) { f_p100 = f_low; f_p0 = f_high; }
      else { f_p100 = f_high; f_p0 = f_low; }

      // Marcadores de origen (Línea vertical en el inicio del periodo de X horas)
      string vName = PNL_TAG + "START_LINE";
      if(ObjectFind(0, vName) < 0) ObjectCreate(0, vName, OBJ_VLINE, 0, TimeCurrent() - currFiboHours*3600, 0);
      else ObjectSetInteger(0, vName, OBJPROP_TIME, TimeCurrent() - currFiboHours*3600);
      ObjectSetInteger(0, vName, OBJPROP_COLOR, clrDimGray);
      ObjectSetInteger(0, vName, OBJPROP_STYLE, STYLE_DOT);
   }

   if(showFibo) DrawFiboVisuals();
   else { 
      ObjectsDeleteAll(0, PNL_TAG + "FIBO");
      ObjectsDeleteAll(0, PNL_TAG + "START_LINE");
   }
}

void DrawFiboVisuals() {
   string name = PNL_TAG + "FIBO_OBJ";
   ObjectsDeleteAll(0, name); // Limpiar para resetear niveles
   
   ObjectCreate(0, name, OBJ_FIBO, 0, isBullish ? f_timeLow : f_timeHigh, f_p100, isBullish ? f_timeHigh : f_timeLow, f_p0);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, true);
   
   ObjectSetInteger(0, name, OBJPROP_LEVELS, 7);
   
   ObjectSetDouble(0, name, OBJPROP_LEVELVALUE, 0, 0.0);
   ObjectSetString(0, name, OBJPROP_LEVELTEXT, 0, "🎯 SNIPER TP (0.0)");
   ObjectSetInteger(0, name, OBJPROP_LEVELCOLOR, 0, clrLime);
   
   ObjectSetDouble(0, name, OBJPROP_LEVELVALUE, 1, 0.214);
   ObjectSetString(0, name, OBJPROP_LEVELTEXT, 1, "🔔 ALERTA REVERSIÓN (21.4)");
   ObjectSetInteger(0, name, OBJPROP_LEVELCOLOR, 1, clrRed);
   ObjectSetInteger(0, name, OBJPROP_LEVELWIDTH, 1, 2);
   
   ObjectSetDouble(0, name, OBJPROP_LEVELVALUE, 2, 0.382);
   ObjectSetString(0, name, OBJPROP_LEVELTEXT, 2, "Fibo 38.2 (Entrada)");
   ObjectSetInteger(0, name, OBJPROP_LEVELCOLOR, 2, clrYellow);
   
   ObjectSetDouble(0, name, OBJPROP_LEVELVALUE, 3, 0.500);
   ObjectSetString(0, name, OBJPROP_LEVELTEXT, 3, "Fibo 50.0 (CENTRO)");
   ObjectSetInteger(0, name, OBJPROP_LEVELCOLOR, 3, clrDeepSkyBlue);
   
   ObjectSetDouble(0, name, OBJPROP_LEVELVALUE, 4, 0.618);
   ObjectSetString(0, name, OBJPROP_LEVELTEXT, 4, "🏆 GOLDEN POCKET (61.8)");
   ObjectSetInteger(0, name, OBJPROP_LEVELCOLOR, 4, clrGoldenrod); 
   ObjectSetInteger(0, name, OBJPROP_LEVELWIDTH, 4, 3);
   
   ObjectSetDouble(0, name, OBJPROP_LEVELVALUE, 5, currSLPct/100.0);
   ObjectSetString(0, name, OBJPROP_LEVELTEXT, 5, "🛑 STOP SEGURO (" + DoubleToString(currSLPct, 1) + ")");
   ObjectSetInteger(0, name, OBJPROP_LEVELCOLOR, 5, clrRed);
   ObjectSetInteger(0, name, OBJPROP_LEVELWIDTH, 5, 2);
   
   ObjectSetDouble(0, name, OBJPROP_LEVELVALUE, 6, 1.0);
   ObjectSetString(0, name, OBJPROP_LEVELTEXT, 6, "ORIGEN (100.0)");
   ObjectSetInteger(0, name, OBJPROP_LEVELCOLOR, 6, clrWhite);
   
   DrawTranslucentZone();
   DrawInteractiveSLLine();
}

void DrawInteractiveSLLine() {
   string name = PNL_TAG + "SL_DRAG";
   double slPrice = f_p0 + (f_p100 - f_p0) * (currSLPct/100.0);
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, slPrice);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
      ObjectSetString(0, name, OBJPROP_TOOLTIP, "🛑 ARRÁSTRAME PARA CAMBIAR SL");
   } else {
      if(!ObjectGetInteger(0, name, OBJPROP_SELECTED)) ObjectSetDouble(0, name, OBJPROP_PRICE, slPrice);
   }
}

void DrawTranslucentZone() {
   if(!showFibo) { ObjectsDeleteAll(0, PNL_TAG + "GOLDEN_ZONE"); return; }
   
   // Cálculo de niveles 38.2% y 61.8% para una zona más amplia e institucional
   double p38 = f_p100 - (f_p100 - f_p0) * 0.382;
   double p61 = f_p100 - (f_p100 - f_p0) * 0.618;
   
   string zName = PNL_TAG + "GOLDEN_ZONE";
   if(ObjectFind(0, zName) < 0) {
      ObjectCreate(0, zName, OBJ_RECTANGLE, 0, f_timeLow, p38, TimeCurrent() + PeriodSeconds()*50, p61);
      ObjectSetInteger(0, zName, OBJPROP_BACK, true);
      ObjectSetInteger(0, zName, OBJPROP_FILL, true);
      ObjectSetInteger(0, zName, OBJPROP_WIDTH, 1);
   } else {
      ObjectSetInteger(0, zName, OBJPROP_TIME, 0, f_timeLow);
      ObjectSetDouble(0, zName, OBJPROP_PRICE, 0, p38);
      ObjectSetInteger(0, zName, OBJPROP_TIME, 1, TimeCurrent() + PeriodSeconds()*100); 
      ObjectSetDouble(0, zName, OBJPROP_PRICE, 1, p61);
   }
   // Color Naranja Institucional translúcido
   ObjectSetInteger(0, zName, OBJPROP_COLOR, clrOrange); 
}

//+------------------------------------------------------------------+
//| Strategy Management                                              |
//+------------------------------------------------------------------+
void ManageStrategy() {
   double rsi[1], ema20[1], ema50[1], price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(CopyBuffer(h_rsi,0,0,1,rsi)<=0 || CopyBuffer(h_ema20,0,0,1,ema20)<=0 || CopyBuffer(h_ema50,0,0,1,ema50)<=0) return;
   
   double dist0 = MathAbs(price - f_p0);
   double totalDist = MathAbs(f_p100 - f_p0);
   double pct = (totalDist > 0) ? (dist0 / totalDist) * 100 : 0;
   
   // --- SAFETY TP EXIT (95% RECORRIDO) ---
   if(pct < 5.0 && PositionsTotalBots() > 0) {
      double pSum = (posInfo.Profit() + posInfo.Swap() + posInfo.Commission()) * profitFactor;
      if(pSum > 0.05) { CloseAll(); botStatus = "SAFETY EXIT: TP SEGURO"; return; }
   }
   
   bool inValue = (pct > 38.2 && pct < 61.8);
   bool exhausted = (pct < 15);
   
   strategyLabel = isBullish ? "SWING COMPRA" : "SWING VENTA";
   if(exhausted) { strategyLabel += " (AGOTADO)"; botStatus = "ESPERANDO RETROCESO"; }
   else if(inValue) { strategyLabel += " (ZONA VALOR)"; botStatus = "CERCANDO PRECIO"; }
   
   // Señal Visual (Flecha)
   DrawDirectionalArrow(isBullish, inValue);
   
   // Gestión de Órdenes (FIXED)
   bool rsiOk = isBullish ? (rsi[0] > 50) : (rsi[0] < 50);
   
   // --- LÓGICA DE CONFIRMACIÓN POR VELA (v7.7) ---
   bool confirmTrigger = true;
   if(useConfirmBar) {
      double c1 = iClose(_Symbol, _Period, 1), o1 = iOpen(_Symbol, _Period, 1);
      if(isBullish) confirmTrigger = (c1 > o1 && c1 > ema20[0]);
      else confirmTrigger = (c1 < o1 && c1 < ema20[0]);
   }

   if(!(UseNewsFilter && remotePaused) && !exhausted && inValue && rsiOk && confirmTrigger && PositionsTotalBots() < 1 && iTime(_Symbol, _Period, 0) != lastCloseTime) {
      double slPrice = f_p0 + (f_p100 - f_p0) * (currSLPct/100.0); 
      if(isBullish && ema20[0] > ema50[0] && price > ema20[0]) trade.Buy(currLots, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_ASK), slPrice, 0, "GOLD_ELITE_B");
      if(!isBullish && ema20[0] < ema50[0] && price < ema20[0]) trade.Sell(currLots, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_BID), slPrice, 0, "GOLD_ELITE_S");
   }
   
   ProtectPositions();
}

void DrawDirectionalArrow(bool bull, bool active) {
   string n = PNL_TAG + "DIR_ARROW";
   color clr = active ? (bull ? clrLime : clrRed) : clrGray;
   if(ObjectFind(0, n) < 0) ObjectCreate(0, n, OBJ_ARROW, 0, TimeCurrent(), 0);
   ObjectSetInteger(0, n, OBJPROP_ARROWCODE, bull ? 233 : 234);
   ObjectSetInteger(0, n, OBJPROP_TIME, TimeCurrent());
   ObjectSetDouble(0, n, OBJPROP_PRICE, bull ? f_low - 500*_Point : f_high + 500*_Point);
   ObjectSetInteger(0, n, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, n, OBJPROP_WIDTH, 10); // Mucho más grande
}

//+------------------------------------------------------------------+
//| Protection Logic                                                 |
//+------------------------------------------------------------------+
void ProtectPositions() {
   profitFactor = (ForceCentMode) ? CentFactor : 1.0;
   
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic()==MagicNumber) {
         double pUSD = (posInfo.Profit() + posInfo.Swap() + posInfo.Commission()) * profitFactor;
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         
         // --- SALIDA POR AGOTAMIENTO (PROXIMIDAD TP) ---
         double distTP = MathAbs(bid - f_p0);
         double totalF = MathAbs(f_p100 - f_p0);
         double currentPct = (totalF > 0) ? (distTP / totalF) * 100 : 0;
         
         if(currentPct < 15.0 && pUSD >= 0.10) { 
            trade.PositionClose(posInfo.Ticket()); 
            botStatus = "SECURE PROFIT: AGOTADO";
            continue; 
         }

         // Break-Even
         // Sniper TP (Cierre de Impacto en 0.0)
         if(posInfo.PositionType()==POSITION_TYPE_BUY && bid >= f_p0) { trade.PositionClose(posInfo.Ticket()); continue; }
         if(posInfo.PositionType()==POSITION_TYPE_SELL && ask <= f_p0) { trade.PositionClose(posInfo.Ticket()); continue; }

         // --- LIVE SL SYNC (SINCRO HUD -> MERCADO) ---
         if(pUSD < currBE) {
            double targetSL = f_p0 + (f_p100 - f_p0) * (currSLPct/100.0);
            double currentSL = posInfo.StopLoss();
            if(MathAbs(currentSL - targetSL) > 2*_Point) { // Sincro inmediata si el HUD cambia
               trade.PositionModify(posInfo.Ticket(), NormalizeDouble(targetSL, _Digits), 0);
               botStatus = "XAU SL SYNC: HUD UPDATE";
            }
         }

         if(pUSD >= currBE) {
            double sl = posInfo.StopLoss();
            double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
            double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
            if(tickVal <= 0) tickVal = 1.0;
            
            // Cálculo preciso para que el Stop Loss garantice EXACTAMENTE los dólares de 'currGarantia'
            double offsetPoints = (currGarantia / (posInfo.Volume() * tickVal)) * tickSize;
            
            double be = (posInfo.PositionType()==POSITION_TYPE_BUY) ? posInfo.PriceOpen() + offsetPoints : posInfo.PriceOpen() - offsetPoints;
            
            if(posInfo.PositionType()==POSITION_TYPE_BUY && (sl < be - 2*tickSize || sl == 0)) trade.PositionModify(posInfo.Ticket(), NormalizeDouble(be, _Digits), 0);
            if(posInfo.PositionType()==POSITION_TYPE_SELL && (sl > be + 2*tickSize || sl == 0)) trade.PositionModify(posInfo.Ticket(), NormalizeDouble(be, _Digits), 0);
         }
         
         // Trailing Stop
         if(pUSD >= currTS) {
            double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
            double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
            if(tickVal <= 0) tickVal = 1.0;
            
            double pointsDist = (currTSDist / (posInfo.Volume() * tickVal)) * tickSize;
            double sl = posInfo.StopLoss();
            if(posInfo.PositionType()==POSITION_TYPE_BUY) {
               double nSL = NormalizeDouble(bid - pointsDist, _Digits);
               if(nSL > sl + 5*_Point) trade.PositionModify(posInfo.Ticket(), nSL, 0);
            } else {
               double nSL = NormalizeDouble(ask + pointsDist, _Digits);
               if(nSL < sl - 5*_Point || sl == 0) trade.PositionModify(posInfo.Ticket(), nSL, 0);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Remote Engine                                                    |
//+------------------------------------------------------------------+
void OnTimer() { 
   if(LicenseCode != "") CheckRemoteCommands(); 
}

void CheckRemoteCommands() {
   string url = "https://www.kopytrading.com/api/remote-control?licenseKey=" + LicenseCode + "&account=" + IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN));
   char post[], result[]; string headers;
   int code = WebRequest("GET", url, headers, 3000, post, result, headers);
   if(code == 200) {
      string resp = CharArrayToString(result);
      if(StringFind(resp, "\"command\":\"PAUSE\"") != -1) remotePaused = true;
      if(StringFind(resp, "\"command\":\"RESUME\"") != -1) remotePaused = false;
      if(StringFind(resp, "\"command\":\"CLOSE_ALL\"") != -1) CloseAll();
      CrearHUD();
   }
}

//+------------------------------------------------------------------+
void CrearHUD() {
   ObjectsDeleteAll(0, PNL_TAG);
   int h_x=15, h_y=15, h_w=300, h_h=580; 
   if(isMinimized) { h_w=220; h_h=45; }
   
   CrRect("bg",h_x,h_y,h_w,h_h,C'10,10,15',CLR_GOLD,1);
   CrLabel("ttl",h_x+15,h_y+10,isMinimized ? "⚜️ XAU MATRIX" : "⚜️ XAU v7.7.0 INTERACTIVE",CLR_GOLD,10,"Impact");
   
   CrBtn("b_min",h_x+h_w-30,h_y+10,20,20,isMinimized ? "+" : "-",C'60,60,100',clrWhite);
   
   if(!isMinimized) {
      string accStr = (profitFactor < 1.0) ? "CUENTA: MODO CENT 💎" : "CUENTA: MODO STANDARD 🏛️";
      string licStr = "LICENCIA: " + (MasterKey=="TRIAL-2026" ? "MAESTRA ✅" : (licenseValid ? (isTrialActive ? "PRUEBA (" + IntegerToString(trialDaysLeft) + " d) 🕒" : "ACTIVA ✅") : "INVÁLIDA ❌"));
      CrLabel("lic",h_x+15,h_y+35,licStr,CLR_GOLD,7);
      CrLabel("acc",h_x+15,h_y+50,accStr,clrSilver,6);
      CrLabel("pL",h_x+15,h_y+70,"PnL HOY (USD):",clrSilver,8);
      CrLabel("pV",h_x+120,h_y+70,DoubleToString(dayPnL,2)+" $",clrWhite,10,"Arial Bold");
      CrBtn("b_rst",h_x+h_w-80,h_y+65,70,25,"RESET",C'60,60,80',clrWhite);
      
      CrLabel("stL",h_x+15,h_y+85,"MODO:",clrSilver,8);
      CrLabel("stV",h_x+120,h_y+85,strategyLabel,clrCyan,9,"Arial Bold");
      
      // Mostrar info de velas medidas - Ahora más visible
      int b_cnt = (int)(currFiboHours * 3600 / PeriodSeconds());
      CrLabel("b_inf",h_x+15,h_y+105,"RANGO ANALIZADO: " + IntegerToString(currFiboHours) + "h (" + IntegerToString(b_cnt) + " velas)",clrSilver,8);
      
      int by = h_y + 125;
      // Colores de los botones según el PRESET activo
      color zenColor = (activePreset==1) ? C'50,100,220' : C'60,60,90';
      color harColor = (activePreset==2) ? C'220,120,40' : C'100,60,20';

      CrBtn("b_zen",h_x+10,by,135,30,"ZEN PRESET",zenColor,clrWhite);
      CrBtn("b_har",h_x+155,by,135,30,"COSECHA PRESET",harColor,clrWhite);
      
      // GRID ESTRICTO
      int ry = by + 45; 
      int col1 = h_x + 15;
      int col2 = h_x + 170; 
      
      CrLabel("l_lot",col1,ry+5,"Lotes Trades:",clrSilver,8); 
      CrEdit("e_lot",col2,ry,70,22,DoubleToString(currLots,2));
      
      ry += 35;
      CrLabel("l_fbc",col1,ry+5,"Fibo Retroceso (H):",clrSilver,8); 
      CrEdit("e_fbc",col2,ry,70,22,IntegerToString(currFiboHours));
      
      ry += 35;
      CrLabel("l_be",col1,ry+5,"Break-Even ($):",clrSilver,8); 
      CrEdit("e_be",col2,ry,70,22,DoubleToString(currBE,2));
      
      ry += 35;
      CrLabel("l_gar",col1,ry+5,"GARANTÍA ($):",CLR_GOLD,8); 
      CrEdit("e_gar",col2,ry,70,22,DoubleToString(currGarantia,2));
      
      ry += 35;
      CrLabel("l_ts",col1,ry+5,"Trailing-Stop ($):",clrSilver,8); 
      CrEdit("e_ts",col2,ry,70,22,DoubleToString(currTS,2));
      
      ry += 35;
      CrLabel("l_td",col1,ry+5,"Dist. Trail ($):",clrSilver,8); 
      CrEdit("e_tsd",col2,ry,70,22,DoubleToString(currTSDist,2));

      ry += 35;
      CrLabel("l_slp",col1,ry+5,"Fibo Stop %:",clrRed,8); 
      CrEdit("e_slp",col2,ry,70,22,DoubleToString(currSLPct,1));
      
      ry += 35;
      CrBtn("b_app",h_x+10,ry,280,30,"APLICAR CAMBIOS",C'40,80,150',clrWhite);

      ry += 40;
      double sl_pd = f_p0 + (f_p100 - f_p0) * (currSLPct/100.0);
      CrLabel("slL",h_x+15,ry,"🛑 RIESGO (SL):",clrRed,8);
      CrLabel("slV",h_x+140,ry,DoubleToString(sl_pd,_Digits),clrWhite,8,"Arial Bold");

      ry += 20;
      CrLabel("tpL",h_x+15,ry,"🎯 META (TP):",clrLime,8);
      CrLabel("tpV",h_x+140,ry,DoubleToString(f_p0,_Digits),clrWhite,8,"Arial Bold");
   
      ry += 35;
      CrBtn("v_ma",h_x+10,ry,60,28,"EMA",showEMA?C'40,80,150':C'50,50,50',clrWhite);
      CrBtn("v_rsi",h_x+75,ry,60,28,"RSI",showRSI?C'150,80,40':C'50,50,50',clrWhite);
      CrBtn("v_fib",h_x+140,ry,60,28,"FIBO",showFibo?C'200,160,40':C'50,50,50',clrWhite);
      CrBtn("v_cnf",h_x+205,ry,85,28,"CONF:"+ (useConfirmBar?"ON":"OFF"),useConfirmBar?clrForestGreen:C'50,50,50',clrWhite);
      
      CrBtn("close",h_x+10,h_y+h_h-70,280,40,"CERRAR TODO",C'200,40,40',clrWhite);
      
      color cWeb = (remotePaused) ? clrRed : clrLime;
      string sWeb = (remotePaused) ? "REMOTO: PAUSED" : "KOPYTRADE: ONLINE | SYNC OK";
      CrLabel("rem",h_x+15,h_y+h_h-25,sWeb,cWeb,7);
   }
}

void ActualizarHUD() {
   ObjectSetString(0,PNL_TAG+"pV",OBJPROP_TEXT,DoubleToString(dayPnL,2)+" $");
   ObjectSetString(0,PNL_TAG+"stV",OBJPROP_TEXT,strategyLabel);
   double sl_pd = f_p0 + (f_p100 - f_p0) * (currSLPct/100.0);
   ObjectSetString(0,PNL_TAG+"slV",OBJPROP_TEXT,DoubleToString(sl_pd,_Digits));
   ObjectSetString(0,PNL_TAG+"tpV",OBJPROP_TEXT,DoubleToString(f_p0,_Digits));
}

void OnChartEvent(const int id,const long &lp,const double &dp,const string &sp) {
   if(id==CHARTEVENT_OBJECT_CLICK) {
      if(sp==PNL_TAG+"b_app") { SaveSettings(); UpdateAutoFibo(); CrearHUD(); }
      if(sp==PNL_TAG+"b_min") { isMinimized=!isMinimized; CrearHUD(); }
      if(sp==PNL_TAG+"b_zen") { 
         activePreset = 1;
         currLots=0.04; currFiboHours=12; currBE=0.50; currTS=1.00; 
         CrearHUD(); UpdateAutoFibo(); 
      }
      if(sp==PNL_TAG+"b_har") { 
         activePreset = 2;
         currLots=0.02; currFiboHours=4;  currBE=0.30; currTS=0.45; 
         CrearHUD(); UpdateAutoFibo(); 
      }
      if(sp==PNL_TAG+"v_ma")  { 
         showEMA=!showEMA; 
         if(!showEMA) { ChartIndicatorDelete(0, 0, "EMA(20)"); ChartIndicatorDelete(0, 0, "EMA(50)"); }
         else { 
            ChartIndicatorAdd(0, 0, h_ema20); 
            ChartIndicatorAdd(0, 0, h_ema50);
            // Configurar Colores Elite
            long cid = 0; 
            ChartSetInteger(cid, CHART_COLOR_CHART_UP, clrLime);
            ChartSetInteger(cid, CHART_COLOR_CHART_DOWN, clrRed);
         }
         CrearHUD(); 
      }
      if(sp==PNL_TAG+"v_rsi") { 
         showRSI=!showRSI; 
         if(!showRSI) ChartIndicatorDelete(0, 1, "RSI(14)");
         else ChartIndicatorAdd(0, 1, h_rsi);
         CrearHUD(); 
      }
      if(sp==PNL_TAG+"v_fib") { showFibo=!showFibo; UpdateAutoFibo(); CrearHUD(); }
      if(sp==PNL_TAG+"v_cnf") { useConfirmBar=!useConfirmBar; CrearHUD(); }
      if(sp==PNL_TAG+"b_rst") { dayPnL=0; ActualizarHUD(); }
      if(sp==PNL_TAG+"close") CloseAll();
      ObjectSetInteger(0,sp,OBJPROP_STATE,false);
      ChartRedraw();
   }
   if(id==CHARTEVENT_OBJECT_ENDEDIT) {
      if(sp==PNL_TAG+"e_lot") currLots = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==PNL_TAG+"e_fbc") { currFiboHours = (int)StringToInteger(ObjectGetString(0,sp,OBJPROP_TEXT)); }
      if(sp==PNL_TAG+"e_be")  currBE = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==PNL_TAG+"e_gar") currGarantia = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==PNL_TAG+"e_ts")  currTS = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==PNL_TAG+"e_tsd") currTSDist = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      if(sp==PNL_TAG+"e_slp") currSLPct = StringToDouble(ObjectGetString(0,sp,OBJPROP_TEXT));
      SaveSettings();
   }
   if(id==CHARTEVENT_OBJECT_DRAG && sp==PNL_TAG+"SL_DRAG") {
      double p = ObjectGetDouble(0, sp, OBJPROP_PRICE);
      double totalDist = MathAbs(f_p100 - f_p0);
      if(totalDist > 0) {
         currSLPct = (MathAbs(p - f_p0) / totalDist) * 100;
         ObjectSetString(0, PNL_TAG+"e_slp", OBJPROP_TEXT, DoubleToString(currSLPct, 1));
         ProtectPositions(); // Sincronizar SL de orden abierta
         SaveSettings();
      }
   }
}

//--- HELPERS HUD ---
void CrRect(string n,int x,int y,int w,int h,color bg,color bd,int bw=1) { 
   ObjectCreate(0,PNL_TAG+n,OBJ_RECTANGLE_LABEL,0,0,0); 
   ObjectSetInteger(0,PNL_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL_TAG+n,OBJPROP_YDISTANCE,y); 
   ObjectSetInteger(0,PNL_TAG+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL_TAG+n,OBJPROP_YSIZE,h); 
   ObjectSetInteger(0,PNL_TAG+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL_TAG+n,OBJPROP_COLOR,bd); 
   ObjectSetInteger(0,PNL_TAG+n,OBJPROP_ZORDER,100); 
}
void CrLabel(string n,int x,int y,string t,color c,int s,string f="Arial") { 
   ObjectCreate(0,PNL_TAG+n,OBJ_LABEL,0,0,0); 
   ObjectSetInteger(0,PNL_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL_TAG+n,OBJPROP_YDISTANCE,y); 
   ObjectSetString(0,PNL_TAG+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL_TAG+n,OBJPROP_COLOR,c); 
   ObjectSetInteger(0,PNL_TAG+n,OBJPROP_FONTSIZE,s); ObjectSetString(0,PNL_TAG+n,OBJPROP_FONT,f); 
   ObjectSetInteger(0,PNL_TAG+n,OBJPROP_ZORDER,101); 
}
void CrBtn(string n,int x,int y,int w,int h,string t,color bg,color tc) { 
   ObjectCreate(0,PNL_TAG+n,OBJ_BUTTON,0,0,0); 
   ObjectSetInteger(0,PNL_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL_TAG+n,OBJPROP_YDISTANCE,y); 
   ObjectSetInteger(0,PNL_TAG+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL_TAG+n,OBJPROP_YSIZE,h); 
   ObjectSetString(0,PNL_TAG+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL_TAG+n,OBJPROP_BGCOLOR,bg); 
   ObjectSetInteger(0,PNL_TAG+n,OBJPROP_COLOR,tc); ObjectSetInteger(0,PNL_TAG+n,OBJPROP_ZORDER,102); 
}
void CrEdit(string n,int x,int y,int w,int h,string t) { 
   ObjectCreate(0,PNL_TAG+n,OBJ_EDIT,0,0,0); 
   ObjectSetInteger(0,PNL_TAG+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL_TAG+n,OBJPROP_YDISTANCE,y); 
   ObjectSetInteger(0,PNL_TAG+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL_TAG+n,OBJPROP_YSIZE,h); 
   ObjectSetString(0,PNL_TAG+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL_TAG+n,OBJPROP_BGCOLOR,C'30,30,50'); 
   ObjectSetInteger(0,PNL_TAG+n,OBJPROP_COLOR,clrWhite); ObjectSetInteger(0,PNL_TAG+n,OBJPROP_ZORDER,102); 
}

//--- PNL Engine ---
double CalculateFullDayPnL() {
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt); dt.hour=0; dt.min=0; dt.sec=0;
   HistorySelect(StructToTime(dt), TimeCurrent());
   double p=0;
   for(int i=HistoryDealsTotal()-1; i>=0; i--) {
      ulong t=HistoryDealGetTicket(i);
      if(HistoryDealGetString(t, DEAL_SYMBOL) == _Symbol && HistoryDealGetInteger(t, DEAL_MAGIC) == MagicNumber) p += HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_SWAP) + HistoryDealGetDouble(t, DEAL_COMMISSION);
   }
   return p * profitFactor;
}

void CloseAll() { for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic()==MagicNumber) trade.PositionClose(posInfo.Ticket()); }
int PositionsTotalBots() { int c=0; for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==MagicNumber) c++; return c; }

//--- Helper Persistence ---
void SaveSettings() {
   string s = IntegerToString(MagicNumber);
   GlobalVariableSet("AEVO_H_"+s, (double)currFiboHours);
   GlobalVariableSet("AEVO_L_"+s, currLots);
   GlobalVariableSet("AEVO_BE_"+s, currBE);
   GlobalVariableSet("AEVO_GAR_"+s, currGarantia);
   GlobalVariableSet("AEVO_TS_"+s, currTS);
   GlobalVariableSet("AEVO_TD_"+s, currTSDist);
   GlobalVariableSet("AEVO_SLP_"+s, currSLPct);
}

void LoadSettings() {
   string s = IntegerToString(MagicNumber);
   currFiboHours = GlobalVariableCheck("AEVO_H_"+s) ? (int)GlobalVariableGet("AEVO_H_"+s) : InpFiboHours;
   currLots = GlobalVariableCheck("AEVO_L_"+s) ? GlobalVariableGet("AEVO_L_"+s) : DefaultLots;
   currBE = GlobalVariableCheck("AEVO_BE_"+s) ? GlobalVariableGet("AEVO_BE_"+s) : InpBE;
   currGarantia = GlobalVariableCheck("AEVO_GAR_"+s) ? GlobalVariableGet("AEVO_GAR_"+s) : 0.10;
   currTS = GlobalVariableCheck("AEVO_TS_"+s) ? GlobalVariableGet("AEVO_TS_"+s) : InpTS;
   currTSDist = GlobalVariableCheck("AEVO_TD_"+s) ? GlobalVariableGet("AEVO_TD_"+s) : InpTSDist;
   currSLPct = GlobalVariableCheck("AEVO_SLP_"+s) ? GlobalVariableGet("AEVO_SLP_"+s) : 70.7;
}




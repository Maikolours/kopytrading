//+------------------------------------------------------------------+
//|                  00_ELITE_WARRIOR_PRO_v41.3                      |
//|   v41.3 - FILTRO LATERAL AUTO | ATR SL | TIME STOP | HUD PRO     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrade Corp."
#property version   "41.30"
#property strict

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

//--- ENUMERACIONES
enum ENUM_MODE { MODE_ZEN, MODE_COSECHA };
enum ENUM_DIR  { DIR_COMPRAS, DIR_VENTAS, DIR_AMBAS };
enum ENUM_EXEC { EXEC_MARKET, EXEC_LIMIT };
enum ENUM_STATE { STATE_WAIT_BOS, STATE_WAIT_RETRACE, STATE_WAIT_CONFIRM };
enum ENUM_PRESET { PRESET_DIARIO, PRESET_FINDE };

//============================================================
//  PARÁMETROS DE ENTRADA
//============================================================
input group "=== 🔑 CONFIGURACIÓN DASHBOARD ==="
input string   InpMasterID       = "cmn9hfaxg000lvhbcqidlvvfm";
input bool     InpRemoteSync     = true;

input group "=== ⏰ FILTRO HORARIO ==="
input bool     InpUseTimeFilter  = true;
input int      InpStartHour      = 8;
input int      InpEndHour        = 21;

input group "=== 🚀 FILTROS DE PROTECCIÓN AVANZADA ==="
input bool     InpUseTrendFilter = true;
input ENUM_TIMEFRAMES InpTF_Trend = PERIOD_H4;
input int      InpTrendEMA       = 200;
input int      InpTrendSlope_Pts = 15;
input bool     InpUseATR_SL      = true;
input int      InpATR_Period     = 14;
input double   InpATR_Mult       = 1.0;
input bool     InpUseTimeStop    = true;
input int      InpTimeStop_Hours = 8;

input group "=== 🛡️ ESTRATEGIA Y TEMPORALIDADES ==="
input ENUM_EXEC       InpExecMode      = EXEC_MARKET; 
input ENUM_TIMEFRAMES InpTF_Macro      = PERIOD_H1; 
input ENUM_TIMEFRAMES InpTF_Mid        = PERIOD_M15;
input ENUM_TIMEFRAMES InpTF_Exec       = PERIOD_M5; 
input int             InpEMA           = 200;

input group "=== 🎯 ZONAS FIBONACCI INSTITUCIONALES ==="
input double          InpMinFiboEntry  = 0.618;
input double          InpMaxFiboEntry  = 0.786;
input int             InpGatillo_Margin_Pts = 25;
input int             InpCaza_Margin_Pts    = 80;
input int             InpSL_Buffer_Pts      = 10;

input group "=== 💰 CIERRE PARCIAL Y TAKE PROFIT ==="
input bool            InpUsePartial    = true;
input double          InpPartialLevel  = 0.382;
input double          InpPartialPerc   = 70.0;
input int             InpBE_Offset_Pts = 20;

input group "=== 📅 PRESETS DE ESTRUCTURA ==="
input int             InpLkb_D         = 28;  
input int             InpBE_D          = 300; 
input int             InpLkb_WE        = 12;  
input int             InpBE_WE         = 200; 

input group "=== 🛡️ GESTIÓN DE TRAILING STOP ==="
input int             InpTrail_Points  = 150; 
input int             InpTrail_Dist    = 70; 

input group "=== 🎨 ESTILO VISUAL ==="
input color           InpColor_Fibo    = clrGold;
input color           InpColor_Bull    = clrCyan;
input color           Incolor_Bear     = clrOrangeRed;

input group "=== 💵 RIESGO Y MAGIC ==="
input double          InpRisk          = 0.5;
input int             InpMagic         = 202900;

#define HUD_PRE "H_"
#define GRAF_PRE "V_"
#define FIBO_NAME "V_FIBO"

//--- GLOBALES
CTrade         trade;
CPositionInfo  posInfo;
ENUM_STATE     state = STATE_WAIT_BOS;
ENUM_MODE      currentMode = MODE_COSECHA;
ENUM_DIR       currentDir = DIR_AMBAS;
ENUM_EXEC      currentExec = EXEC_MARKET;
ENUM_PRESET    currentPreset = PRESET_DIARIO;

int            hEmaMacro, hEmaMid, hEmaTrend, hATR;
int            dirMacro=0, dirMid=0, dirH4=0;
double         f100=0, f0=0, f23=0, f38=0, f61=0, f70=0, f78=0;
datetime       t100=0, t0=0;
bool           isMinimized=false, isManualMode=false;
bool           p1_pierced=false;
bool           partial_closed=false;
int            curLkb, curBE, curHours;
string         narrative = "Buscando oportunidad...";

//--- EVENTOS PRINCIPALES
int OnInit() {
   trade.SetExpertMagicNumber(InpMagic);
   hEmaMacro = iMA(_Symbol, InpTF_Macro, InpEMA, 0, MODE_EMA, PRICE_CLOSE);
   hEmaMid = iMA(_Symbol, InpTF_Mid, InpEMA, 0, MODE_EMA, PRICE_CLOSE);
   hEmaTrend = iMA(_Symbol, InpTF_Trend, InpTrendEMA, 0, MODE_EMA, PRICE_CLOSE);
   hATR = iATR(_Symbol, PERIOD_H1, InpATR_Period);
   ApplyPreset();
   CrearPanel();
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) {
   ObjectsDeleteAll(0, HUD_PRE); ObjectsDeleteAll(0, GRAF_PRE); 
   if(hEmaMacro != INVALID_HANDLE) IndicatorRelease(hEmaMacro);
   if(hEmaMid != INVALID_HANDLE) IndicatorRelease(hEmaMid);
   if(hEmaTrend != INVALID_HANDLE) IndicatorRelease(hEmaTrend);
   if(hATR != INVALID_HANDLE) IndicatorRelease(hATR);
   EventKillTimer();
}

void ApplyPreset() {
   if(currentPreset == PRESET_DIARIO) { curHours = InpLkb_D; curBE = InpBE_D; }
   else { curHours = InpLkb_WE; curBE = InpBE_WE; }
   curLkb = (int)(curHours * 3600 / PeriodSeconds(InpTF_Mid));
   if(curLkb < 10) curLkb = 10;
}

bool IsTimeAllowed() {
   if(!InpUseTimeFilter) return true;
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(InpStartHour <= InpEndHour)
      return (dt.hour >= InpStartHour && dt.hour < InpEndHour);
   else
      return (dt.hour >= InpStartHour || dt.hour < InpEndHour);
}

void OnTick() {
   UpdateTrends();
   if(!isManualMode) DetectBOS(); else ManualBOSUpdate();
   
   if(CountActive() == 0) {
      MonitorRetracement();
      partial_closed = false;
   }
   
   ManageRisk();
   UpdatePanelText();
}

void OnTimer() {
   if(ObjectFind(0, HUD_PRE+"bg") < 0) CrearPanel();
   UpdatePanelText();
}

double GetMAValue(int handle) {
   double buffer[1];
   if(CopyBuffer(handle, 0, 0, 1, buffer) > 0) return buffer[0];
   return 0;
}

double GetATRValue() {
   double buffer[1];
   if(CopyBuffer(hATR, 0, 0, 1, buffer) > 0) return buffer[0];
   return 0;
}

//+------------------------------------------------------------------+
//| DETECCIÓN DE TENDENCIA CON PENDIENTE (Evita mercado lateral)    |
//+------------------------------------------------------------------+
void UpdateTrends() {
   double emaM = GetMAValue(hEmaMacro);
   double emaH = GetMAValue(hEmaMid);
   double emaT = GetMAValue(hEmaTrend);
   
   // Obtenemos el valor de la EMA 200 de H4 hace 5 velas para medir la pendiente
   double emaT_prev[1];
   int copied = CopyBuffer(hEmaTrend, 0, 5, 1, emaT_prev);
   double emaTPast = (copied > 0) ? emaT_prev[0] : emaT;
   
   dirMacro = (iClose(_Symbol, InpTF_Macro, 0) > emaM) ? 1 : -1;
   dirMid = (iClose(_Symbol, InpTF_Mid, 0) > emaH) ? 1 : -1;
   
   // Lógica del filtro H4: 1 = Alcista, -1 = Bajista, 0 = LATERAL (Pausa auto)
   double ps = (_Digits==3||_Digits==5 ? 10.0*_Point : _Point);
   double slopeThreshold = InpTrendSlope_Pts * ps;
   
   if(emaT > emaTPast + slopeThreshold) {
      dirH4 = 1;  // Tendencia Alcista clara
   } else if(emaT < emaTPast - slopeThreshold) {
      dirH4 = -1; // Tendencia Bajista clara
   } else {
      dirH4 = 0;  // MERCADO LATERAL (EMA plana) - Se pausa automáticamente
   }
}

void DetectBOS() {
   int hh = iHighest(_Symbol, InpTF_Mid, MODE_HIGH, curLkb, 1);
   int ll = iLowest(_Symbol, InpTF_Mid, MODE_LOW, curLkb, 1);
   double hi = iHigh(_Symbol, InpTF_Mid, hh), lo = iLow(_Symbol, InpTF_Mid, ll);
   datetime tHi = iTime(_Symbol, InpTF_Mid, hh);
   datetime tLo = iTime(_Symbol, InpTF_Mid, ll);
   
   bool bull = (dirMacro == 1); 
   bool validSwing = (bull && tLo < tHi) || (!bull && tHi < tLo);
   
   if(!validSwing) {
      f61 = 0; f100 = 0; f0 = 0;
      ObjectDelete(0, FIBO_NAME);
      ObjectDelete(0, GRAF_PRE+"WAVE");
      narrative = "⏳ ESPERANDO IMPULSO " + (bull ? "ALCISTA" : "BAJISTA") + " VÁLIDO";
      return;
   }
   
   f100 = bull ? lo : hi; t100 = bull ? tLo : tHi;
   f0 = bull ? hi : lo; t0 = bull ? tHi : tLo;
   DrawFibo(f100, f0, t100, t0, bull);
}

void ManualBOSUpdate() {
   if(ObjectFind(0, FIBO_NAME) < 0) return;
   f100 = ObjectGetDouble(0, FIBO_NAME, OBJPROP_PRICE, 0); t100 = (datetime)ObjectGetInteger(0, FIBO_NAME, OBJPROP_TIME, 0);
   f0 = ObjectGetDouble(0, FIBO_NAME, OBJPROP_PRICE, 1); t0 = (datetime)ObjectGetInteger(0, FIBO_NAME, OBJPROP_TIME, 1);
   DrawFibo(f100, f0, t100, t0, (f0 > f100));
}

void DrawFibo(double p100, double p0, datetime tm100, datetime tm0, bool bull) {
   if(ObjectFind(0, FIBO_NAME)<0) {
      ObjectCreate(0, FIBO_NAME, OBJ_FIBO, 0, 0, 0, 0, 0);
      ObjectSetInteger(0, FIBO_NAME, OBJPROP_RAY_RIGHT, true); ObjectSetInteger(0, FIBO_NAME, OBJPROP_BACK, true); ObjectSetInteger(0, FIBO_NAME, OBJPROP_LEVELS, 8);
      ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 0, 0.0);    ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 0, "0.0 TP ZONE");
      ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 1, 0.236);  ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 1, "23.6 IMP X");
      ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 2, 0.382);  ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 2, "38.2 IMP 0");
      ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 3, 0.5);    ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 3, "50.0");
      ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 4, 0.618);  ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 4, "61.8 OTE 1");
      ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 5, 0.705);  ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 5, "70.5 OTE 2");
      ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 6, 0.786);  ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 6, "78.6 OTE 3");
      ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 7, 1.0);    ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 7, "100.0 SL HARD");
      for(int l=0; l<8; l++) ObjectSetInteger(0, FIBO_NAME, OBJPROP_LEVELCOLOR, l, InpColor_Fibo);
      ObjectSetInteger(0, FIBO_NAME, OBJPROP_COLOR, InpColor_Fibo);
   }
   if(!isManualMode) { ObjectMove(0, FIBO_NAME, 0, tm100, p100); ObjectMove(0, FIBO_NAME, 1, tm0, p0); }
   f23 = bull ? p0-(p0-p100)*0.236 : p0+(p100-p0)*0.236; f38 = bull?p0-(p0-p100)*0.382:p0+(p100-p0)*0.382; f61 = bull?p0-(p0-p100)*0.618:p0+(p100-p0)*0.618; f70 = bull?p0-(p0-p100)*0.705:p0+(p100-p0)*0.705; f78 = bull?p0-(p0-p100)*0.786:p0+(p100-p0)*0.786;
   
   string wav = GRAF_PRE+"WAVE";
   if(ObjectFind(0,wav)<0) { ObjectCreate(0,wav,OBJ_TREND,0,0,0,0,0); ObjectSetInteger(0,wav,OBJPROP_STYLE,STYLE_DOT); ObjectSetInteger(0,wav,OBJPROP_WIDTH,2); }
   ObjectSetInteger(0,wav,OBJPROP_BACK,true);
   ObjectMove(0,wav,0,ObjectGetInteger(0,FIBO_NAME,OBJPROP_TIME,0),p100); ObjectMove(0,wav,1,ObjectGetInteger(0,FIBO_NAME,OBJPROP_TIME,1),p0);
   ObjectSetInteger(0,wav,OBJPROP_COLOR,(bull?InpColor_Bull:Incolor_Bear)); ObjectSetInteger(0,FIBO_NAME,OBJPROP_SELECTABLE,isManualMode);
}

void MonitorRetracement() {
   if(f61==0) return;
   if(!IsTimeAllowed()) { narrative = "⏰ FUERA DE HORARIO DE OPERACIÓN"; return; }
   
   double cp = iClose(_Symbol, 0, 0); 
   bool bull = (f0 > f100); 
   double ps = (_Digits==3||_Digits==5 ? 10.0*_Point : _Point);
   
   if(bull && currentDir == DIR_VENTAS) return;
   if(!bull && currentDir == DIR_COMPRAS) return;
   
   // FILTRO DE TENDENCIA H4 CON DETECCIÓN DE LATERAL
   if(InpUseTrendFilter) {
      if(dirH4 == 0) { narrative = "⏸️ MERCADO LATERAL. ESPERANDO..."; return; }
      if(bull && dirH4 == -1) { narrative = "⛔ BLOQUEADO: TENDENCIA H4 BAJISTA"; return; }
      if(!bull && dirH4 == 1) { narrative = "⛔ BLOQUEADO: TENDENCIA H4 ALCISTA"; return; }
   }
   
   double minLevelPrice = bull ? f0 - (f0 - f100)*InpMinFiboEntry : f0 + (f100 - f0)*InpMinFiboEntry;
   double maxLevelPrice = bull ? f0 - (f0 - f100)*InpMaxFiboEntry : f0 + (f100 - f0)*InpMaxFiboEntry;
   
   if(bull) {
      if(cp <= minLevelPrice + InpCaza_Margin_Pts*ps) p1_pierced = true;
      if(p1_pierced) {
         narrative = "🎯 GATILLO OTE (M5 Alcista)";
         bool confirm = iClose(_Symbol,InpTF_Exec,1) > iOpen(_Symbol,InpTF_Exec,1);
         if(cp <= minLevelPrice + InpGatillo_Margin_Pts*ps && cp >= maxLevelPrice - InpSL_Buffer_Pts*ps && confirm) {
            ExecuteMarket(true);
         }
      } else narrative = "🏹 CAZANDO OTE ALCISTA";
   } else {
      if(cp >= minLevelPrice - InpCaza_Margin_Pts*ps) p1_pierced = true;
      if(p1_pierced) {
         narrative = "🎯 GATILLO OTE (M5 Bajista)";
         bool confirm = iClose(_Symbol,InpTF_Exec,1) < iOpen(_Symbol,InpTF_Exec,1);
         if(cp >= minLevelPrice - InpGatillo_Margin_Pts*ps && cp <= maxLevelPrice + InpSL_Buffer_Pts*ps && confirm) {
            ExecuteMarket(false);
         }
      } else narrative = "🏹 CAZANDO OTE BAJISTA";
   }
}

void ExecuteMarket(bool bull) {
   double ps = (_Digits==3||_Digits==5 ? 10.0*_Point : _Point);
   double slPriceFibo = bull ? f100 - (InpSL_Buffer_Pts*ps) : f100 + (InpSL_Buffer_Pts*ps);
   double entryPrice = bull ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   double slPrice = slPriceFibo;
   if(InpUseATR_SL) {
      double atrVal = GetATRValue();
      if(atrVal > 0) {
         double atrSLDist = atrVal * InpATR_Mult;
         double fiboSLDist = MathAbs(entryPrice - slPriceFibo);
         if(atrSLDist < fiboSLDist) {
            slPrice = bull ? entryPrice - atrSLDist : entryPrice + atrSLDist;
         }
      }
   }
   
   double riskVal = AccountInfoDouble(ACCOUNT_BALANCE) * (InpRisk/100.0);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(tickValue == 0) tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE_LOSS);
   
   double slDistRaw = MathAbs(entryPrice - slPrice);
   double slDistTicks = slDistRaw / (tickSize > 0 ? tickSize : _Point);
   if(slDistTicks <= 0) slDistTicks = 1;
   
   double lot = riskVal / (slDistTicks * tickValue);
   double minL = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxL = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepL = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   lot = MathFloor(lot/stepL)*stepL;
   lot = MathMax(minL, MathMin(maxL, lot));
   
   if(bull) trade.Buy(lot, _Symbol, 0, slPrice, f0, "WARRIOR_v41.3"); else trade.Sell(lot, _Symbol, 0, slPrice, f0, "WARRIOR_v41.3");
   p1_pierced = false;
   partial_closed = false;
}

void ManageRisk() {
   double ps = (_Digits==3||_Digits==5 ? 10.0*_Point : _Point);
   double partialTargetPrice = f38;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic() == InpMagic) {
         double op = posInfo.PriceOpen(), cur = posInfo.PriceCurrent(), sl = posInfo.StopLoss(), tp = posInfo.TakeProfit();
         bool buy = (posInfo.PositionType() == POSITION_TYPE_BUY);
         double pnl = buy ? (cur - op)/_Point : (op - cur)/_Point;
         
         // TIME STOP (Cierre por inactividad)
         if(InpUseTimeStop && !partial_closed) {
            datetime posTime = (datetime)posInfo.Time();
            if(TimeCurrent() - posTime > InpTimeStop_Hours * 3600) {
               trade.PositionClose(posInfo.Ticket());
               narrative = "⏰ TIME STOP: Posición cerrada";
               continue;
            }
         }
         
         // 1. CIERRE PARCIAL Y BREAKEVEN ESTÁNDAR
         if(InpUsePartial && !partial_closed) {
            bool reachedPartial = buy ? (cur >= partialTargetPrice) : (cur <= partialTargetPrice);
            if(reachedPartial && posInfo.Volume() > SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN)) {
               double closeVol = NormalizeDouble(posInfo.Volume() * (InpPartialPerc / 100.0), 2);
               double stepL = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
               closeVol = MathMax(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), MathFloor(closeVol / stepL) * stepL);
               
               if(trade.PositionClosePartial(posInfo.Ticket(), closeVol)) {
                  double newSL = op + (buy ? InpBE_Offset_Pts : -InpBE_Offset_Pts) * ps;
                  trade.PositionModify(posInfo.Ticket(), newSL, tp);
                  partial_closed = true;
                  narrative = "💰 PARCIAL CERRADO. SL A BE+";
               }
            }
         }
         
         // 2. BREAKEVEN STANDARD
         if(!partial_closed && pnl >= curBE && (sl == 0 || (buy && sl < op) || (!buy && sl > op))) {
            double newSL = op + (buy ? InpBE_Offset_Pts : -InpBE_Offset_Pts) * ps;
            trade.PositionModify(posInfo.Ticket(), newSL, tp);
         }
         
         // 3. TRAILING STOP
         if(pnl >= InpTrail_Points) {
            double nsl = buy ? cur - InpTrail_Dist * ps : cur + InpTrail_Dist * ps;
            if((buy && nsl > sl + 20 * ps) || (!buy && (nsl < sl - 20 * ps || (sl == 0)))) {
               trade.PositionModify(posInfo.Ticket(), nsl, tp);
            }
         }
      }
   }
}

//--- ESTADÍSTICAS
double CalcularGanadoHoy() {
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   datetime startOfDay = StructToTime(dt);
   HistorySelect(startOfDay, TimeCurrent());
   double total = 0;
   int deals = HistoryDealsTotal();
   for(int i = 0; i < deals; i++) {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0) {
         long magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
         long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
         if(magic == InpMagic && (entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_INOUT)) {
            total += HistoryDealGetDouble(ticket, DEAL_PROFIT) + HistoryDealGetDouble(ticket, DEAL_SWAP) + HistoryDealGetDouble(ticket, DEAL_COMMISSION);
         }
      }
   }
   return total;
}

void CalcularEstadisticasHoy(int &wins, int &losses) {
   wins = 0; losses = 0;
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   datetime startOfDay = StructToTime(dt);
   HistorySelect(startOfDay, TimeCurrent());
   int deals = HistoryDealsTotal();
   for(int i = 0; i < deals; i++) {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0) {
         long magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
         long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
         if(magic == InpMagic && (entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_INOUT)) {
            double p = HistoryDealGetDouble(ticket, DEAL_PROFIT) + HistoryDealGetDouble(ticket, DEAL_SWAP) + HistoryDealGetDouble(ticket, DEAL_COMMISSION);
            if(p > 0) wins++; else if(p < 0) losses++;
         }
      }
   }
}

double CalcularFlotante() {
   double total = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic() == InpMagic) {
         total += posInfo.Profit() + posInfo.Swap();
      }
   }
   return total;
}

int CountActive() { int c=0; for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic()==InpMagic) c++; return c; }
int CountOrders() { int c=0; for(int i=OrdersTotal()-1; i>=0; i--) { ulong t=OrderGetTicket(i); if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC)==InpMagic) c++; } return c; }

//+------------------------------------------------------------------+
//| PANEL VISUAL PROFESIONAL v41.3                                   |
//+------------------------------------------------------------------+
void CrearPanel() {
   ObjectsDeleteAll(0, HUD_PRE);
   int x = 15, y = 25, w = 320;
   int h = isMinimized ? 42 : 615;
   
   // Fondo opaco negro puro
   CrRect("bg", x, y, w, h, C'8,8,8', clrGold);
   CrRect("hdr", x+2, y+2, w-4, 38, C'60,0,0', clrRed);
   CrLabel("ttl", x+12, y+10, "⚔️ ELITE WARRIOR PRO", clrWhite, 10);
   CrLabel("ver", x+12, y+25, "v41.3 INSTITUTIONAL", clrGold, 7);
   CrBtnOld("b_min", x+w-32, y+8, 24, 24, isMinimized ? "[+]" : "[-]", C'80,0,0');
   
   if(isMinimized) return;
   
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   double gHoy = CalcularGanadoHoy();
   double flot = CalcularFlotante();
   double total = bal + flot;
   int wins = 0, losses = 0;
   CalcularEstadisticasHoy(wins, losses);
   int totalTrades = wins + losses;
   double winRate = (totalTrades > 0) ? (wins * 100.0 / totalTrades) : 0;
   
   int cy = y + 45;
   
   // === BLOQUE FINANZAS ===
   CrRect("fin_bg", x+6, cy, w-12, 105, C'0,0,0', clrGold);
   CrLabel("fin_t", x+14, cy+5, "💼  FINANZAS GLOBALES", clrGold, 8);
   CrLabel("l_bal",  x+14, cy+22, StringFormat("Balance:      $%.2f", bal), clrWhite, 8);
   CrLabel("l_ghoy", x+14, cy+39, StringFormat("Ganado Hoy:   %s$%.2f", (gHoy>=0?"+":""), gHoy), (gHoy>=0 ? clrLime : clrRed), 8);
   CrLabel("l_flot", x+14, cy+56, StringFormat("Flotante:     %s$%.2f", (flot>=0?"+":""), flot), (flot>=0 ? clrLime : clrRed), 8);
   CrLabel("l_tot",  x+14, cy+73, StringFormat("Total:        $%.2f", total), clrAqua, 8);
   CrLabel("l_stats",x+14, cy+89, StringFormat("Stats Hoy: %d W / %d L  (%.1f%%)", wins, losses, winRate), clrSilver, 7);
   cy += 110;
   
   // === BLOQUE POSICIÓN ACTIVA ===
   CrRect("pos_bg", x+6, cy, w-12, 82, C'0,0,0', clrMaroon);
   CrLabel("pos_t", x+14, cy+5, "📊  POSICIÓN ACTIVA", clrOrangeRed, 8);
   
   if(CountActive() > 0) {
      for(int i = 0; i < PositionsTotal(); i++) {
         if(posInfo.SelectByIndex(i) && posInfo.Magic() == InpMagic) {
            bool isBuy = (posInfo.PositionType() == POSITION_TYPE_BUY);
            double pProfit = posInfo.Profit() + posInfo.Swap();
            CrLabel("pos_dir", x+14, cy+22, StringFormat("%s  %.2f lot", (isBuy?"🟢 BUY":"🔴 SELL"), posInfo.Volume()), (isBuy?clrCyan:clrOrangeRed), 8);
            CrLabel("pos_ent", x+14, cy+38, StringFormat("Entrada: %s | Actual: %s", DoubleToString(posInfo.PriceOpen(),_Digits), DoubleToString(posInfo.PriceCurrent(),_Digits)), clrWhite, 7);
            CrLabel("pos_sl",  x+14, cy+53, StringFormat("SL: %s | TP: %s", DoubleToString(posInfo.StopLoss(),_Digits), DoubleToString(posInfo.TakeProfit(),_Digits)), clrSilver, 7);
            CrLabel("pos_pnl", x+14, cy+68, StringFormat("P/L: %s$%.2f", (pProfit>=0?"+":""), pProfit), (pProfit>=0?clrLime:clrRed), 8);
            break;
         }
      }
   } else {
      CrLabel("pos_none", x+14, cy+35, "— Sin posición activa —", clrGray, 8);
      CrLabel("pos_wait", x+14, cy+55, "Esperando señal OTE...", C'120,120,120', 7);
   }
   cy += 88;
   
   // === BLOQUE ESTRATEGIA ===
   CrRect("str_bg", x+6, cy, w-12, 72, C'0,0,0', clrMaroon);
   CrLabel("str_t", x+14, cy+5, "🎯  ESTRATEGIA", clrOrangeRed, 8);
   CrLabel("str_nar", x+14, cy+22, narrative, clrWhite, 8);
   string trendTxt = "H4: " + (dirH4==1?"▲ ALC":(dirH4==-1?"▼ BAJ":"— LAT")) + "  |  H1: " + (dirMacro==1?"▲ ALC":"▼ BAJ") + "  |  M15: " + (dirMid==1?"▲ ALC":"▼ BAJ");
   color trendColor = (dirH4==1 ? clrCyan : (dirH4==-1 ? clrOrangeRed : clrSilver));
   CrLabel("str_tr", x+14, cy+40, trendTxt, trendColor, 7);
   CrLabel("str_st", x+14, cy+56, "Modo: " + (isManualMode?"MANUAL ✋":"AUTO 🤖") + "  |  Riesgo: " + DoubleToString(InpRisk,2) + "%", clrSilver, 7);
   cy += 78;
   
   // === BLOQUE FIBONACCI ===
   CrRect("fib_bg", x+6, cy, w-12, 90, C'0,0,0', clrGold);
   CrLabel("fib_t", x+14, cy+5, "🏹  RED DE CAZA FIBONACCI", clrGold, 8);
   CrLabel("fib_1", x+14, cy+22, "IMP 23.6%: " + DoubleToString(f23,_Digits) + "  |  38.2%: " + DoubleToString(f38,_Digits), clrWhite, 7);
   CrLabel("fib_2", x+14, cy+38, "OTE 1 (61.8%): " + DoubleToString(f61,_Digits) + "  |  70.5%: " + DoubleToString(f70,_Digits), clrWhite, 7);
   CrLabel("fib_3", x+14, cy+54, "OTE 3 (78.6%): " + DoubleToString(f78,_Digits), clrWhite, 7);
   double spreadPts = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;
   MqlDateTime dtNow; TimeToStruct(TimeCurrent(), dtNow);
   CrLabel("fib_sp", x+14, cy+72, StringFormat("Spread Actual: %.0f pts  |  Hora: %02d:%02d", spreadPts, dtNow.hour, dtNow.min), clrAqua, 7);
   cy += 96;
   
   // === BOTONES ===
   CrBtn("b_day", x+6,   cy, 151, 26, "MODO DIARIO", currentPreset==PRESET_DIARIO);
   CrBtn("b_we",  x+163, cy, 151, 26, "MODO FINDE", currentPreset==PRESET_FINDE);
   cy += 30;
   
   CrBtn("b_zen", x+6,   cy, 151, 26, "MODO ZEN", currentMode==MODE_ZEN);
   CrBtn("b_har", x+163, cy, 151, 26, "COSECHA", currentMode==MODE_COSECHA);
   cy += 30;
   
   CrBtn("b_mar", x+6,   cy, 151, 26, "GATILLO M5", currentExec==EXEC_MARKET);
   CrBtn("b_lim", x+163, cy, 151, 26, "LIMIT ZONAS", currentExec==EXEC_LIMIT);
   cy += 30;
   
   CrBtn("b_auto", x+6, cy, 151, 26, "AUTO 🤖", !isManualMode);
   CrBtn("b_man",  x+163, cy, 151, 26, "MANUAL ✋", isManualMode);
   cy += 30;
   
   CrBtn("b_c", x+6,   cy, 99, 26, "COMPRA", currentDir==DIR_COMPRAS);
   CrBtn("b_a", x+110, cy, 100, 26, "AMBAS", currentDir==DIR_AMBAS);
   CrBtn("b_v", x+215, cy, 99, 26, "VENTA", currentDir==DIR_VENTAS);
   cy += 30;
   
   CrBtnOld("b_cl", x+6, cy, w-12, 32, "🚨 CERRAR TODO (PANIC)", C'150,0,0');
   if(!isMinimized) ObjectSetInteger(0, HUD_PRE+"bg", OBJPROP_YSIZE, (cy + 38) - y);
}

void UpdatePanelText() {
   if(isMinimized) return;
   
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   double gHoy = CalcularGanadoHoy();
   double flot = CalcularFlotante();
   double total = bal + flot;
   int wins = 0, losses = 0;
   CalcularEstadisticasHoy(wins, losses);
   int totalTrades = wins + losses;
   double winRate = (totalTrades > 0) ? (wins * 100.0 / totalTrades) : 0;
   
   ObjectSetString(0, HUD_PRE+"l_bal",  OBJPROP_TEXT, StringFormat("Balance:      $%.2f", bal));
   ObjectSetString(0, HUD_PRE+"l_ghoy", OBJPROP_TEXT, StringFormat("Ganado Hoy:   %s$%.2f", (gHoy>=0?"+":""), gHoy));
   ObjectSetInteger(0, HUD_PRE+"l_ghoy", OBJPROP_COLOR, (gHoy>=0 ? clrLime : clrRed));
   ObjectSetString(0, HUD_PRE+"l_flot", OBJPROP_TEXT, StringFormat("Flotante:     %s$%.2f", (flot>=0?"+":""), flot));
   ObjectSetInteger(0, HUD_PRE+"l_flot", OBJPROP_COLOR, (flot>=0 ? clrLime : clrRed));
   ObjectSetString(0, HUD_PRE+"l_tot",  OBJPROP_TEXT, StringFormat("Total:        $%.2f", total));
   ObjectSetString(0, HUD_PRE+"l_stats",OBJPROP_TEXT, StringFormat("Stats Hoy: %d W / %d L  (%.1f%%)", wins, losses, winRate));
   
   // Actualizar posición
   if(CountActive() > 0) {
      for(int i = 0; i < PositionsTotal(); i++) {
         if(posInfo.SelectByIndex(i) && posInfo.Magic() == InpMagic) {
            bool isBuy = (posInfo.PositionType() == POSITION_TYPE_BUY);
            double pProfit = posInfo.Profit() + posInfo.Swap();
            ObjectSetString(0, HUD_PRE+"pos_dir", OBJPROP_TEXT, StringFormat("%s  %.2f lot", (isBuy?"🟢 BUY":"🔴 SELL"), posInfo.Volume()));
            ObjectSetInteger(0, HUD_PRE+"pos_dir", OBJPROP_COLOR, (isBuy?clrCyan:clrOrangeRed));
            ObjectSetString(0, HUD_PRE+"pos_ent", OBJPROP_TEXT, StringFormat("Entrada: %s | Actual: %s", DoubleToString(posInfo.PriceOpen(),_Digits), DoubleToString(posInfo.PriceCurrent(),_Digits)));
            ObjectSetString(0, HUD_PRE+"pos_sl",  OBJPROP_TEXT, StringFormat("SL: %s | TP: %s", DoubleToString(posInfo.StopLoss(),_Digits), DoubleToString(posInfo.TakeProfit(),_Digits)));
            ObjectSetString(0, HUD_PRE+"pos_pnl", OBJPROP_TEXT, StringFormat("P/L: %s$%.2f", (pProfit>=0?"+":""), pProfit));
            ObjectSetInteger(0, HUD_PRE+"pos_pnl", OBJPROP_COLOR, (pProfit>=0?clrLime:clrRed));
            break;
         }
      }
   }
   
   ObjectSetString(0, HUD_PRE+"str_nar", OBJPROP_TEXT, narrative);
   string trendTxt = "H4: " + (dirH4==1?"▲ ALC":(dirH4==-1?"▼ BAJ":"— LAT")) + "  |  H1: " + (dirMacro==1?"▲ ALC":"▼ BAJ") + "  |  M15: " + (dirMid==1?"▲ ALC":"▼ BAJ");
   color trendColor = (dirH4==1 ? clrCyan : (dirH4==-1 ? clrOrangeRed : clrSilver));
   ObjectSetString(0, HUD_PRE+"str_tr", OBJPROP_TEXT, trendTxt);
   ObjectSetInteger(0, HUD_PRE+"str_tr", OBJPROP_COLOR, trendColor);
   
   ObjectSetString(0, HUD_PRE+"fib_1", OBJPROP_TEXT, "IMP 23.6%: " + DoubleToString(f23,_Digits) + "  |  38.2%: " + DoubleToString(f38,_Digits));
   ObjectSetString(0, HUD_PRE+"fib_2", OBJPROP_TEXT, "OTE 1 (61.8%): " + DoubleToString(f61,_Digits) + "  |  70.5%: " + DoubleToString(f70,_Digits));
   ObjectSetString(0, HUD_PRE+"fib_3", OBJPROP_TEXT, "OTE 3 (78.6%): " + DoubleToString(f78,_Digits));
   double spreadPts = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;
   MqlDateTime dtNow2; TimeToStruct(TimeCurrent(), dtNow2);
   ObjectSetString(0, HUD_PRE+"fib_sp", OBJPROP_TEXT, StringFormat("Spread Actual: %.0f pts  |  Hora: %02d:%02d", spreadPts, dtNow2.hour, dtNow2.min));
}

//--- HELPERS VISUALES
void CrRect(string n, int x, int y, int w, int h, color bg, color bd=clrGray) { 
   ObjectCreate(0,HUD_PRE+n,OBJ_RECTANGLE_LABEL,0,0,0); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XDISTANCE,x); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YDISTANCE,y); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XSIZE,w); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YSIZE,h); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_BGCOLOR,bg); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_COLOR,bd); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_BORDER_TYPE,BORDER_FLAT); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_ZORDER,10); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_BACK,false);
}
void CrLabel(string n, int x, int y, string t, color c, int s) { 
   ObjectCreate(0,HUD_PRE+n,OBJ_LABEL,0,0,0); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XDISTANCE,x); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YDISTANCE,y); 
   ObjectSetString(0,HUD_PRE+n,OBJPROP_TEXT,t); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_COLOR,c); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_FONTSIZE,s); 
   ObjectSetString(0,HUD_PRE+n,OBJPROP_FONT,"Segoe UI");
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_ZORDER,15); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_BACK,false);
}
void CrBtnOld(string n, int x, int y, int w, int h, string t, color bg) { 
   ObjectCreate(0,HUD_PRE+n,OBJ_BUTTON,0,0,0); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XDISTANCE,x); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YDISTANCE,y); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XSIZE,w); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YSIZE,h); 
   ObjectSetString(0,HUD_PRE+n,OBJPROP_TEXT,t); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_BGCOLOR,bg); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_COLOR,clrWhite); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_ZORDER,20); 
   ObjectSetString(0,HUD_PRE+n,OBJPROP_FONT,"Segoe UI");
}
void CrBtn(string n, int x, int y, int w, int h, string t, bool active) { 
   color bg = active ? C'0,200,255' : C'30,30,30';
   color tc = active ? clrBlack : C'180,180,180';
   color br = active ? clrAqua : C'80,80,80';
   ObjectCreate(0,HUD_PRE+n,OBJ_BUTTON,0,0,0); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XDISTANCE,x); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YDISTANCE,y); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XSIZE,w); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YSIZE,h); 
   ObjectSetString(0,HUD_PRE+n,OBJPROP_TEXT,(active ? "● " : "○ ") + t); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_BGCOLOR,bg); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_COLOR,tc); 
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_BORDER_COLOR,br);
   ObjectSetInteger(0,HUD_PRE+n,OBJPROP_ZORDER,20); 
   ObjectSetString(0,HUD_PRE+n,OBJPROP_FONT,"Segoe UI");
}

void OnChartEvent(const int id, const long &lp, const double &dp, const string &sp) {
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sp == HUD_PRE+"b_min") { isMinimized = !isMinimized; CrearPanel(); }
      if(sp == HUD_PRE+"b_day") { currentPreset = PRESET_DIARIO; ApplyPreset(); DetectBOS(); CrearPanel(); }
      if(sp == HUD_PRE+"b_we")  { currentPreset = PRESET_FINDE;  ApplyPreset(); DetectBOS(); CrearPanel(); }
      if(sp == HUD_PRE+"b_zen") { currentMode = MODE_ZEN; CrearPanel(); }
      if(sp == HUD_PRE+"b_har") { currentMode = MODE_COSECHA; CrearPanel(); }
      if(sp == HUD_PRE+"b_mar") { currentExec = EXEC_MARKET; CrearPanel(); }
      if(sp == HUD_PRE+"b_lim") { currentExec = EXEC_LIMIT;  CrearPanel(); }
      if(sp == HUD_PRE+"b_auto"){ isManualMode = false; CrearPanel(); }
      if(sp == HUD_PRE+"b_man") { isManualMode = true;  CrearPanel(); }
      if(sp == HUD_PRE+"b_c")   { currentDir = DIR_COMPRAS; CrearPanel(); }
      if(sp == HUD_PRE+"b_a")   { currentDir = DIR_AMBAS;   CrearPanel(); }
      if(sp == HUD_PRE+"b_v")   { currentDir = DIR_VENTAS;  CrearPanel(); }
      if(sp == HUD_PRE+"b_cl")  { 
         for(int i=PositionsTotal()-1; i>=0; i--) 
            if(posInfo.SelectByIndex(i) && posInfo.Magic()==InpMagic) 
               trade.PositionClose(posInfo.Ticket()); 
         ObjectSetInteger(0, sp, OBJPROP_STATE, false);
      }
   }
   if(id == CHARTEVENT_OBJECT_DRAG && (sp == FIBO_NAME) && isManualMode) { ManualBOSUpdate(); }
}
//+------------------------------------------------------------------+

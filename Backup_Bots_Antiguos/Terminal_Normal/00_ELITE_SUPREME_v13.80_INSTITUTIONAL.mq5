//|                  00_ELITE_SUPREME_v13.80_INSTITUTIONAL               |
//|      STRATEGY: FIBONACCI OTE | HUD: PREMIUM | SYNC: FORCED v1.80 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrade Corp."
#property version   "13.80"
#property strict

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

//--- ENUMERACIONES
enum ENUM_MODE { MODE_ZEN, MODE_COSECHA };
enum ENUM_DIR  { DIR_COMPRAS, DIR_VENTAS, DIR_AMBAS };
enum ENUM_EXEC { EXEC_MARKET, EXEC_LIMIT };
enum ENUM_STATE { STATE_WAIT_BOS, STATE_WAIT_RETRACE, STATE_WAIT_CONFIRM };

bool isMinimized = false; // Estado del HUD

//============================================================
//  PARÁMETROS DE ENTRADA
//============================================================
input group "=== 🔑 CONFIGURACIÓN DASHBOARD ==="
input string   InpLicKey         = "TRIAL-2023";
input string   InpMasterID       = "cmn9hfaxg000lvhbcqidlvvfm";

input group "=== 🛡️ ESTRATEGIA INSTITUCIONAL ==="
input ENUM_EXEC       InpExecMode      = EXEC_LIMIT; // Modo de Ejecución
input ENUM_TIMEFRAMES InpTF_Macro      = PERIOD_H4;  // Bias 48h
input ENUM_TIMEFRAMES InpTF_Mid        = PERIOD_H1;  // Estructura 24h
input ENUM_TIMEFRAMES InpTF_Exec       = PERIOD_M15; // Estrategia/Estructura (M15)
input int             InpLookback      = 100;        // Lookback para BOS (Default: 100 candles)
input int             InpEMA           = 200;        // Filtro EMA Macro

input group "=== 💵 GESTIÓN DE RIESGO AVANZADA ==="
input double          InpRisk          = 0.5;        // Riesgo % por Operación
input int             InpSL_Pips       = 250;        // Stop Loss (Pips)
input int             InpTP_Pips       = 500;        // Take Profit (Pips)
input int             InpBE_Trigger    = 150;        // BreakEven Trigger
input int             InpTrailingStop  = 100;        // Trailing Stop
input int             InpMagic         = 202600;     // Magic Number

//--- VARIABLES GLOBALES
CTrade         trade;
CPositionInfo  posInfo;
ENUM_STATE     state = STATE_WAIT_BOS;
ENUM_MODE      currentMode = MODE_COSECHA;
ENUM_DIR       currentDir = DIR_AMBAS;
ENUM_EXEC      currentExec = EXEC_LIMIT;
int            hEma4H, hEma1H;
int            dir4H = 0, dir1H = 0; 
double         f100=0, f0=0, f61=0, f70=0, f78=0;
string         botStatus = "INSTITUTIONAL SYNCING...";
datetime       lastSyncTime = 0;
#define PNL "SUPREME_"
#define FIBO_NAME "SUPREME_OTE_LEVELS"

//--- VARIABLES DE CONTROL REMOTO (Override de Inputs)
int      curSL, curTP, curBE, curTra, curLkb;
ENUM_TIMEFRAMES curTF_Macro, curTF_Trend, curTF_Fibo, curTF_Entry;

//+------------------------------------------------------------------+
//| MOTOR DE SINCRONIZACIÓN SUPREME (v1.70)                          |
//+------------------------------------------------------------------+
void AbsoluteSync() {
   if(TimeCurrent() < lastSyncTime + 5) return; 
   lastSyncTime = TimeCurrent();
   
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   double equ = AccountInfoDouble(ACCOUNT_EQUITY);
   double pnlToday = 0;
   
   if(HistorySelect(iTime(_Symbol, PERIOD_D1, 0), TimeCurrent())) {
      for(int i=HistoryDealsTotal()-1; i>=0; i--) {
         ulong t = HistoryDealGetTicket(i);
         if(HistoryDealGetInteger(t, DEAL_MAGIC) == InpMagic) pnlToday += HistoryDealGetDouble(t, DEAL_PROFIT);
      }
   }

   string url = "https://kopytrading.vercel.app/api/sync-positions";
   string body = "{";
   body += "\"purchaseId\":\"" + InpMasterID + "\",";
   body += "\"account\":\"" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)) + "\",";
   body += "\"symbol\":\"" + _Symbol + "\",";
   body += "\"tf\":\"" + EnumToString(Period()) + "\",";
   body += "\"balance\":" + DoubleToString(bal, 2) + ",";
   body += "\"equity\":" + DoubleToString(equ, 2) + ",";
   body += "\"pnl_today\":" + DoubleToString(pnlToday, 2) + ",";
   body += "\"status\":\"" + botStatus + "\",";
   body += "\"trend\":\"" + (dir4H == 1 ? "BULL" : "BEAR") + "\",";
   body += "\"mode\":" + IntegerToString(currentMode) + ",";
   body += "\"dir\":" + IntegerToString(currentDir) + ",";
   body += "\"exec\":" + IntegerToString(currentExec) + ",";
   body += "\"sl\":" + IntegerToString(curSL) + ",";
   body += "\"tp\":" + IntegerToString(curTP) + ",";
   body += "\"be\":" + IntegerToString(curBE) + ",";
   body += "\"tra\":" + IntegerToString(curTra) + ",";
   body += "\"lkb\":" + IntegerToString(curLkb) + ",";
   body += "\"tf_trend\":\"" + EnumToString(curTF_Trend) + "\",";
   body += "\"tf_fibo\":\"" + EnumToString(curTF_Fibo) + "\",";
   body += "\"tf_entry\":\"" + EnumToString(curTF_Entry) + "\",";
   body += "\"armed\":true,";
   body += "\"version\":\"13.80\"";
   body += "}";
   
   uchar p[], r[]; string rh;
   StringToCharArray(body, p);
   if(ArraySize(p) > 0) ArrayResize(p, ArraySize(p)-1);
   
   int res = WebRequest("POST", url, "Content-Type: application/json\r\n", 3000, p, r, rh);
   
   if(res == 200) {
      string response = CharArrayToString(r);
      if(StringFind(response, "\"cmd\":\"CLOSE_ALL\"") != -1) {
         for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic()==InpMagic) trade.PositionClose(posInfo.Ticket());
      }
      
      // PARSER v13.80
      if(StringFind(response, "\"mode\":0") != -1) currentMode = MODE_ZEN;
      if(StringFind(response, "\"mode\":1") != -1) currentMode = MODE_COSECHA;
      if(StringFind(response, "\"dir\":0") != -1) currentDir = DIR_COMPRAS;
      if(StringFind(response, "\"dir\":1") != -1) currentDir = DIR_VENTAS;
      if(StringFind(response, "\"dir\":2") != -1) currentDir = DIR_AMBAS;
      if(StringFind(response, "\"exec\":0") != -1) currentExec = EXEC_MARKET;
      if(StringFind(response, "\"exec\":1") != -1) currentExec = EXEC_LIMIT;

      ParseRemoteRisk(response);
   }
}

void ParseRemoteRisk(string json) {
    int start = StringFind(json, "\"settings\":{");
    if(start == -1) return;
    
    curSL = ExtractInt(json, "\"sl\":", curSL);
    curTP = ExtractInt(json, "\"tp\":", curTP);
    curBE = ExtractInt(json, "\"be\":", curBE);
    curTra = ExtractInt(json, "\"tra\":", curTra);
    curLkb = ExtractInt(json, "\"lkb\":", curLkb);
    
    ENUM_TIMEFRAMES oldMacro = curTF_Macro;
    curTF_Macro = StringToTF(ExtractStr(json, "\"tf_macro\":"));
    if(curTF_Macro != oldMacro) { IndicatorRelease(hEma4H); hEma4H = iMA(_Symbol, curTF_Macro, InpEMA, 0, MODE_EMA, PRICE_CLOSE); }

    ENUM_TIMEFRAMES oldMid = curTF_Trend; 
    curTF_Trend = StringToTF(ExtractStr(json, "\"tf_trend\":"));
    if(curTF_Trend != oldMid) { IndicatorRelease(hEma1H); hEma1H = iMA(_Symbol, curTF_Trend, InpEMA, 0, MODE_EMA, PRICE_CLOSE); }
    
    curTF_Entry = StringToTF(ExtractStr(json, "\"tf_entry\":"));
}

int ExtractInt(string json, string key, int def) {
    int pos = StringFind(json, key);
    if(pos == -1) return def;
    int start = pos + StringLen(key);
    int end = StringFind(json, ",", start);
    if(end == -1) end = StringFind(json, "}", start);
    string val = StringSubstr(json, start, end - start);
    return (int)StringToInteger(val);
}

string ExtractStr(string json, string key) {
    int pos = StringFind(json, key);
    if(pos == -1) return "";
    int start = pos + StringLen(key) + 1; // Saltar comilla
    int end = StringFind(json, "\"", start);
    return StringSubstr(json, start, end - start);
}

ENUM_TIMEFRAMES StringToTF(string tf) {
    if(tf == "PERIOD_H1" || tf == "H1") return PERIOD_H1;
    if(tf == "PERIOD_M15" || tf == "M15") return PERIOD_M15;
    if(tf == "PERIOD_M5" || tf == "M5") return PERIOD_M5;
    if(tf == "PERIOD_M1" || tf == "M1") return PERIOD_M1;
    if(tf == "PERIOD_M30" || tf == "M30") return PERIOD_M30;
    if(tf == "PERIOD_H4" || tf == "H4") return PERIOD_H4;
    return curTF_Fibo; // Fallback
}

int OnInit() {
   trade.SetExpertMagicNumber(InpMagic);
   
   curSL = InpSL_Pips; curTP = InpTP_Pips; curBE = InpBE_Trigger; 
   curTra = InpTrailingStop; curLkb = InpLookback;
   curTF_Macro = InpTF_Macro; curTF_Trend = InpTF_Mid; curTF_Fibo = PERIOD_M15; curTF_Entry = InpTF_Exec;

   hEma4H = iMA(_Symbol, curTF_Macro, InpEMA, 0, MODE_EMA, PRICE_CLOSE);
   hEma1H = iMA(_Symbol, curTF_Trend, InpEMA, 0, MODE_EMA, PRICE_CLOSE);
   
   CrearPanel();
   EventSetTimer(1); 
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) { ObjectsDeleteAll(0, PNL); ObjectsDeleteAll(0, "SUPREME_"); IndicatorRelease(hEma4H); IndicatorRelease(hEma1H); }

void OnTick() {
   UpdateStructuralTrends(); // 4H & 1H Alignment
   AbsoluteSync();
   ManageExits();
   
   if(CountPositions() > 0) {
      botStatus = "🚀 POSICIÓN ABIERTA";
   } else {
      if(state == STATE_WAIT_BOS) DetectMarketStructureBreak();
      else if(state == STATE_WAIT_RETRACE) MonitorRetracement();
      else if(state == STATE_WAIT_CONFIRM) ScanConfirmTrigger();
   }
   
   ActualizarPanel();
}

void UpdateStructuralTrends() {
   double ema4[1], ema1[1];
   if(CopyBuffer(hEma4H, 0, 1, 1, ema4) <= 0 || CopyBuffer(hEma1H, 0, 1, 1, ema1) <= 0) return;
   
   dir4H = (iClose(_Symbol, curTF_Macro, 1) > ema4[0]) ? 1 : -1;
   dir1H = (iClose(_Symbol, curTF_Trend, 1) > ema1[0]) ? 1 : -1;
   
   // Seguridad: Limpieza si se desalinean
   if(state != STATE_WAIT_BOS && dir4H != dir1H) {
      botStatus = "TENDENCIAS DESALINEADAS";
      CancelPendingOrders();
      state = STATE_WAIT_BOS;
      ObjectsDeleteAll(0, FIBO_NAME);
   }
}

void DrawFiboVisuals(double p100, double p0, datetime t100, datetime t0, bool bull) {
   ObjectsDeleteAll(0, FIBO_NAME);
   if(!ObjectCreate(0, FIBO_NAME, OBJ_FIBO, 0, t100, p100, t0, p0)) return;
   
   ObjectSetInteger(0, FIBO_NAME, OBJPROP_COLOR, bull ? C'40,110,210' : C'210,60,100');
   ObjectSetInteger(0, FIBO_NAME, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, FIBO_NAME, OBJPROP_BACK, true);
   
   ObjectSetInteger(0, FIBO_NAME, OBJPROP_LEVELS, 8);
   ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 0, 0.0);
   ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 1, 0.236);
   ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 2, 0.382);
   ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 3, 0.50);  ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 3, "EQUILIBRIUM");
   ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 4, 0.618); ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 4, "OTE START (61.8%)");
   ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 5, 0.705); ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 5, "SWEET SPOT (70.5%)");
   ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 6, 0.786); ObjectSetString(0, FIBO_NAME, OBJPROP_LEVELTEXT, 6, "OTE END (78.6%)");
   ObjectSetDouble(0, FIBO_NAME, OBJPROP_LEVELVALUE, 7, 1.0);
   
   ObjectSetInteger(0, FIBO_NAME, OBJPROP_LEVELCOLOR, 4, clrGold);
   ObjectSetInteger(0, FIBO_NAME, OBJPROP_LEVELCOLOR, 5, clrGold);
   ObjectSetInteger(0, FIBO_NAME, OBJPROP_LEVELCOLOR, 6, clrGold);
   
   ChartRedraw(0);
}

void DetectMarketStructureBreak() {
   if(dir4H == 0 || dir1H == 0 || dir4H != dir1H) {
      botStatus = "ESPERANDO ALINEACIÓN 4H/1H";
      return;
   }
   
   int hh = iHighest(_Symbol, InpTF_Exec, MODE_HIGH, curLkb, 1);
   int ll = iLowest(_Symbol, InpTF_Exec, MODE_LOW, curLkb, 1);
   double highLevel = iHigh(_Symbol, InpTF_Exec, hh);
   double lowLevel = iLow(_Symbol, InpTF_Exec, ll);
   double currentClose = iClose(_Symbol, InpTF_Exec, 0);
   
   bool isBullBOS = (dir4H == 1 && currentClose > highLevel);
   bool isBearBOS = (dir4H == -1 && currentClose < lowLevel);
   
   if(isBullBOS || isBearBOS) {
      f100 = isBullBOS ? lowLevel : highLevel;
      f0 = currentClose; 
      
      datetime t100 = isBullBOS ? iTime(_Symbol, InpTF_Exec, ll) : iTime(_Symbol, InpTF_Exec, hh);
      datetime t0 = iTime(_Symbol, InpTF_Exec, 0);

      f61 = isBullBOS ? f0 - (f0-f100)*0.618 : f0 + (f100-f0)*0.618;
      f70 = isBullBOS ? f0 - (f0-f100)*0.705 : f0 + (f100-f0)*0.705;
      f78 = isBullBOS ? f0 - (f0-f100)*0.786 : f0 + (f100-f0)*0.786;
      
      botStatus = "BOS DETECTADO | ESPERANDO OTE";
      DrawFiboVisuals(f100, f0, t100, t0, isBullBOS);
      
      if(currentExec == EXEC_LIMIT) PlaceLimitOrders(isBullBOS);
      
      state = STATE_WAIT_RETRACE;
      Print("🎯 [OTE] BOS Detectado. Modo SUPREME OTE activado.");
   } else {
      botStatus = (dir4H == 1) ? "4H BULL | BUSCANDO BOS ↑" : "4H BEAR | BUSCANDO BOS ↓";
      ChartRedraw(0);
   }
}

void PlaceLimitOrders(bool bull) {
   double lot = CalculateLot(curSL); 
   if(lot <= 0) lot = 0.01;
   double sl = bull ? f100 - curSL*_Point : f100 + curSL*_Point;
   double tp = bull ? f0 + curTP*_Point : f0 - curTP*_Point;
   if(bull) trade.BuyLimit(lot, f70, _Symbol, sl, tp, ORDER_TIME_GTC, 0, "SUPREME_OTE_LIMIT");
   else trade.SellLimit(lot, f70, _Symbol, sl, tp, ORDER_TIME_GTC, 0, "SUPREME_OTE_LIMIT");
   botStatus = "ÓRDENES LÍMIT PUESTAS";
}

void MonitorRetracement() {
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   bool bull = (dir1H == 1);
   bool inZone = bull ? (price <= f61 && price >= f78) : (price >= f61 && price <= f78);
   if(inZone) {
      if(currentExec == EXEC_MARKET) {
         state = STATE_WAIT_CONFIRM;
         botStatus = "OTE ALCANZADO | ESPERANDO GATILLO";
      } else {
         botStatus = "PRECIO EN ZONA LIMIT";
      }
   }
   if((bull && price < f100) || (!bull && price > f100)) {
       state = STATE_WAIT_BOS;
       botStatus = "ESTRUCTURA INVALIDADA";
       ObjectsDeleteAll(0, FIBO_NAME);
       CancelPendingOrders();
   }
}

void ScanConfirmTrigger() {
   double o = iOpen(_Symbol, InpTF_Exec, 1); double c = iClose(_Symbol, InpTF_Exec, 1);
   bool ok = (dir1H == 1 && c > o) || (dir1H == -1 && c < o);
   if(ok) { ExecuteTrade(); state = STATE_WAIT_BOS; }
}

void CancelPendingOrders() {
   for(int i=OrdersTotal()-1; i>=0; i--) {
      ulong t = OrderGetTicket(i);
      if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC)==InpMagic) trade.OrderDelete(t);
   }
}

void ExecuteTrade() {
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl = (dir1H==1) ? ask - curSL*_Point : bid + curSL*_Point;
   double tp = (dir1H==1) ? ask + curTP*_Point : bid - curTP*_Point;
   double lot = CalculateLot(curSL);
   if(dir1H == 1) trade.Buy(lot, _Symbol, ask, sl, tp, "SUPREME OTE");
   else trade.Sell(lot, _Symbol, bid, sl, tp, "SUPREME OTE");
   ObjectsDeleteAll(0, FIBO_NAME);
}

double CalculateLot(double sl_pips) {
   double risk_amount = AccountInfoDouble(ACCOUNT_EQUITY) * (InpRisk / 100.0);
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(sl_pips <= 0 || tick_value <= 0) return 0.01;
   double lot = risk_amount / (sl_pips * _Point * (tick_value / tick_size));
   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   lot = MathFloor(lot / step_lot) * step_lot;
   if(lot < min_lot) lot = min_lot;
   if(lot > max_lot) lot = max_lot;
   return lot;
}

void CrearPanel() {
   ObjectsDeleteAll(0, PNL);
   int x=15, y=30, w=290, h=isMinimized ? 45 : 410;
   CrRect("bg", x, y, w, h, C'10,10,25', C'255,180,40', 2); 
   CrRect("hdr", x+2, y+2, w-4, 40, C'30,20,60', C'30,20,60');
   CrLabel("ttl", x+15, y+8, "ELITE SUPREME v13.80", clrWhite, 10, "Arial Bold");
   CrBtn("b_min", x+w-35, y+8, 25, 25, isMinimized ? "▢" : "_", C'50,40,90', clrWhite);
   if(!isMinimized) {
      CrLabel("stL", x+15, y+60, "SISTEMA: " + InpMasterID, C'40,200,90', 8, "Arial Bold");
      CrLabel("stV", x+15, y+85, "ESTADO: " + botStatus, C'200,200,200', 9);
      string s4 = (dir4H==1?"ALCISTA ▲":"BAJISTA ▼"); color c4 = (dir4H==1?C'40,200,90':C'210,50,50');
      CrLabel("tr4", x+15, y+110, "BIAS MACRO 4H: " + s4, c4, 9);
      string s1 = (dir1H==1?"ALCISTA ▲":"BAJISTA ▼"); color c1 = (dir1H==1?C'40,200,90':C'210,50,50');
      CrLabel("tr1", x+15, y+135, "ESTRUCTURA 1H: " + s1, c1, 9);
      CrBtn("b_zen", x+10, y+205, 130, 25, "MODO ZEN", currentMode==MODE_ZEN?C'40,70,190':C'35,35,65', clrWhite);
      CrBtn("b_har", x+145, y+205, 130, 25, "COSECHA", currentMode==MODE_COSECHA?C'200,80,40':C'35,35,65', clrWhite);
      CrBtn("b_market", x+10, y+240, 130, 25, "MERCADO (Gatillo)", currentExec==EXEC_MARKET?C'40,70,190':C'35,35,65', clrWhite);
      CrBtn("b_limit", x+145, y+240, 130, 25, "LÍMITE OTE (Auto)", currentExec==EXEC_LIMIT?C'40,70,190':C'35,35,65', clrWhite);
      CrBtn("b_buy", x+10, y+275, 85, 25, "COMPRA", currentDir==DIR_COMPRAS?C'40,70,190':C'35,35,65', clrWhite);
      CrBtn("b_both", x+100, y+275, 85, 25, "AMBAS", currentDir==DIR_AMBAS?C'40,70,190':C'35,35,65', clrWhite);
      CrBtn("b_sell", x+190, y+275, 85, 25, "VENTA", currentDir==DIR_VENTAS?C'180,40,40':C'35,35,65', clrWhite);
      CrBtn("b_close", x+10, y+320, 270, 45, "CERRAR TODO (EMERGENCIA)", C'210,50,50', clrWhite);
      CrLabel("rem", x+15, y+385, "SYNC: INSTITUTIONAL SUPREME v1.8", clrWhite, 8);
   }
   ChartRedraw(0);
}

void ActualizarPanel() {
   if(isMinimized) return;
   ObjectSetString(0, PNL+"stV", OBJPROP_TEXT, "ESTADO: " + botStatus);
   ObjectSetString(0, PNL+"tr4", OBJPROP_TEXT, "BIAS MACRO 4H: " + (dir4H==1?"ALCISTA ▲":"BAJISTA ▼"));
   ObjectSetInteger(0, PNL+"tr4", OBJPROP_COLOR, (dir4H==1?C'40,200,90':C'210,50,50'));
   ObjectSetString(0, PNL+"tr1", OBJPROP_TEXT, "ESTRUCTURA 1H: " + (dir1H==1?"ALCISTA ▲":"BAJISTA ▼"));
   ObjectSetInteger(0, PNL+"tr1", OBJPROP_COLOR, (dir1H==1?C'40,200,90':C'210,50,50'));
}

void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bw=1) {
   ObjectCreate(0,PNL+n,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,bd);
}
void CrLabel(string n, int x, int y, string t, color c, int s, string f="Segoe UI") {
   ObjectCreate(0,PNL+n,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y);
   ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,c);
   ObjectSetInteger(0,PNL+n,OBJPROP_FONTSIZE,s);
}
void CrBtn(string n, int x, int y, int w, int h, string t, color bg, color tc) {
   ObjectCreate(0,PNL+n,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h);
   ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,tc);
}

void OnChartEvent(const int id, const long &lp, const double &dp, const string &sp) {
   if(id != CHARTEVENT_OBJECT_CLICK) return;
   if(sp == PNL+"b_min") { isMinimized = !isMinimized; CrearPanel(); }
   if(sp == PNL+"b_zen") { currentMode = MODE_ZEN; CrearPanel(); }
   if(sp == PNL+"b_har") { currentMode = MODE_COSECHA; CrearPanel(); }
   if(sp == PNL+"b_market") { currentExec = EXEC_MARKET; CrearPanel(); }
   if(sp == PNL+"b_limit") { currentExec = EXEC_LIMIT; CrearPanel(); }
   if(sp == PNL+"b_buy") { currentDir = DIR_COMPRAS; CrearPanel(); }
   if(sp == PNL+"b_sell") { currentDir = DIR_VENTAS; CrearPanel(); }
   if(sp == PNL+"b_both") { currentDir = DIR_AMBAS; CrearPanel(); }
   if(sp == PNL+"b_close") {
      for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic()==InpMagic) trade.PositionClose(posInfo.Ticket());
      CancelPendingOrders();
   }
   ObjectSetInteger(0, sp, OBJPROP_STATE, false);
}

int CountPositions() {
   int c=0; for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic()==InpMagic) c++;
   return c;
}

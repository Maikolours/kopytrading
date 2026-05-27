//|                00_ELITE_SUPREME_v13.70_ABSOLUTE                  |
//|      STRATEGY: FIBONACCI OTE | HUD: PREMIUM | SYNC: FORCED v1.70 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrade Corp."
#property version   "13.70"
#property strict

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

//--- ENUMERACIONES
enum ENUM_MODE { MODE_ZEN, MODE_COSECHA };
enum ENUM_DIR  { DIR_COMPRAS, DIR_VENTAS, DIR_AMBAS };
enum ENUM_STATE { STATE_WAIT_IMPULSE, STATE_WAIT_RETRACE, STATE_WAIT_CONFIRM };

//============================================================
//  PARÁMETROS DE ENTRADA
//============================================================
input group "=== 🔑 CONFIGURACIÓN DASHBOARD ==="
input string   InpLicKey         = "TRIAL-2023";
input string   InpMasterID       = "cmn9hfaxg000lvhbcqidlvvfm";

input group "=== 🛡️ ESTRATEGIA & TEMPORALIDADES ==="
input ENUM_TIMEFRAMES InpTF_Trend      = PERIOD_H1;  // Tendencia Principal
input ENUM_TIMEFRAMES InpTF_Fibo       = PERIOD_M15; // Impulso y Fibonacci
input ENUM_TIMEFRAMES InpTF_Entry      = PERIOD_M5;  // Confirmación de Gatillo
input int             InpLookback      = 25;         // Velas para buscar impulso
input int             InpEMA           = 50;         // Periodos EMA Tendencia

input group "=== 💵 GESTIÓN DE RIESGO AVANZADA ==="
input double          InpRisk          = 0.5;        // Riesgo % por Operación
input int             InpSL_Pips       = 250;        // Stop Loss (Puntos)
input int             InpTP_Pips       = 500;        // Take Profit (Puntos)
input int             InpBE_Trigger    = 150;        // Activar BreakEven a los (Puntos)
input int             InpTrailingStop  = 100;        // Distancia Trailing (Puntos)
input int             InpMagic         = 202600;     // Magic Number

//--- VARIABLES GLOBALES
CTrade         trade;
CPositionInfo  posInfo;
ENUM_STATE     state = STATE_WAIT_IMPULSE;
ENUM_MODE      currentMode = MODE_COSECHA;
ENUM_DIR       currentDir = DIR_AMBAS;
int            hEmaH1;
int            h1Dir = 0; 
double         f100=0, f78=0, f62=0, f50=0, f0=0;
string         botStatus = "INICIALIZANDO...";
bool           isMinimized = false;
datetime       lastLogTime = 0;
datetime       lastSyncTime = 0;
#define PNL "SUPREME_"

//+------------------------------------------------------------------+
//| MOTOR DE SINCRONIZACIÓN ABSOLUTA (v1.6B)                         |
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
   body += "\"trend\":\"" + (h1Dir == 1 ? "BULL" : "BEAR") + "\",";
   body += "\"mode\":" + IntegerToString(currentMode) + ",";
   body += "\"dir\":" + IntegerToString(currentDir) + ",";
   body += "\"armed\":true,";
   body += "\"p100\":" + DoubleToString(f100, _Digits) + ",";
   body += "\"p78\":" + DoubleToString(f78, _Digits) + ",";
   body += "\"p62\":" + DoubleToString(f62, _Digits) + ",";
   body += "\"p50\":" + DoubleToString(f50, _Digits) + ",";
   body += "\"p00\":" + DoubleToString(f0, _Digits) + ",";
   body += "\"b1_be\":0.8, \"b1_gar\":0.5, \"b1_tra\":1.2";
   body += "}";
   
   uchar p[], r[]; string rh;
   StringToCharArray(body, p);
   if(ArraySize(p) > 0) ArrayResize(p, ArraySize(p)-1);
   
   int res = WebRequest("POST", url, "Content-Type: application/json\r\n", 3000, p, r, rh);
   
   if(res == 200) {
      string response = CharArrayToString(r);
      // PARSER LIGHTWEIGHT DE COMANDOS v1.67
      if(StringFind(response, "\"cmd\":\"CLOSE_ALL\"") != -1) {
         Print("🚨 [REMOTE] COMANDO RECIBIDO: CLOSE_ALL");
         for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic()==InpMagic) trade.PositionClose(posInfo.Ticket());
      }
      if(StringFind(response, "\"mode\":0") != -1 && currentMode != MODE_ZEN) {
         currentMode = MODE_ZEN; CrearPanel(); Print("📡 [REMOTE] CAMBIO A MODO ZEN");
      }
      if(StringFind(response, "\"mode\":1") != -1 && currentMode != MODE_COSECHA) {
         currentMode = MODE_COSECHA; CrearPanel(); Print("📡 [REMOTE] CAMBIO A MODO COSECHA");
      }
      if(StringFind(response, "\"dir\":0") != -1 && currentDir != DIR_COMPRAS) {
         currentDir = DIR_COMPRAS; CrearPanel(); Print("📡 [REMOTE] CAMBIO A DIRECCIÓN BUY");
      }
      if(StringFind(response, "\"dir\":1") != -1 && currentDir != DIR_VENTAS) {
         currentDir = DIR_VENTAS; CrearPanel(); Print("📡 [REMOTE] CAMBIO A DIRECCIÓN SELL");
      }
      if(StringFind(response, "\"dir\":2") != -1 && currentDir != DIR_AMBAS) {
         currentDir = DIR_AMBAS; CrearPanel(); Print("📡 [REMOTE] CAMBIO A DIRECCIÓN AMBAS");
      }
   }

   if(TimeCurrent() > lastLogTime + 10) {
      if(res == 200) {} // Silent OK
      else if(res == -1) Print("❌ [SUPREME-SYNC] ERROR: Verifique URLs permitidas en MT5.");
      else Print("❌ [SUPREME-SYNC] ERROR HTTP: " + IntegerToString(res));
      lastLogTime = TimeCurrent();
   }
}

//+------------------------------------------------------------------+
//| OnInit & OnTick                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   trade.SetExpertMagicNumber(InpMagic);
   hEmaH1 = iMA(_Symbol, PERIOD_H1, InpEMA, 0, MODE_EMA, PRICE_CLOSE);
   CrearPanel();
   EventSetTimer(1); 
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) { ObjectsDeleteAll(0, PNL); IndicatorRelease(hEmaH1); }

void OnTick() {
   UpdateH1Trend();
   AbsoluteSync();
   ManageExits(); // Gestión de BE y Trailing
   
   if(CountPositions() > 0) {
      botStatus = "🚀 POSICIÓN ABIERTA";
   } else {
      if(state == STATE_WAIT_IMPULSE) ScanM15Impulse();
      else if(state == STATE_WAIT_RETRACE) MonitorRetracement();
      else if(state == STATE_WAIT_CONFIRM) ScanM5Confirmation();
   }

   ActualizarPanel();
}

//+------------------------------------------------------------------+
//| LÓGICA INSTITUCIONAL FIBONACCI                                   |
//+------------------------------------------------------------------+
void ScanM15Impulse() {
   int hh = iHighest(_Symbol, InpTF_Fibo, MODE_HIGH, InpLookback, 1);
   int ll = iLowest(_Symbol, InpTF_Fibo, MODE_LOW, InpLookback, 1);
   double range = iHigh(_Symbol, InpTF_Fibo, hh) - iLow(_Symbol, InpTF_Fibo, ll);
   
   if(range > 400 * _Point) {
      if(h1Dir == 1 && iClose(_Symbol, InpTF_Fibo, 1) > iHigh(_Symbol, InpTF_Fibo, hh)) {
         f100 = iLow(_Symbol, InpTF_Fibo, ll); f0 = iHigh(_Symbol, InpTF_Fibo, hh);
         f62 = f0 - (f0-f100)*0.618; f78 = f0 - (f0-f100)*0.786; f50 = f0 - (f0-f100)*0.5;
         state = STATE_WAIT_RETRACE; botStatus = "FIBO ACTIVADO";
         DrawFiboLevels(f100, f0, true);
      }
      else if(h1Dir == -1 && iClose(_Symbol, InpTF_Fibo, 1) < iLow(_Symbol, InpTF_Fibo, ll)) {
         f100 = iHigh(_Symbol, InpTF_Fibo, hh); f0 = iLow(_Symbol, InpTF_Fibo, ll);
         f62 = f0 + (f100-f0)*0.618; f78 = f0 + (f100-f0)*0.786; f50 = f0 + (f100-f0)*0.5;
         state = STATE_WAIT_RETRACE; botStatus = "FIBO ACTIVADO";
         DrawFiboLevels(f100, f0, false);
      } else {
         botStatus = (h1Dir == 1) ? "BUSCANDO IMPULSO BULL" : "BUSCANDO IMPULSO BEAR";
      }
   } else {
      botStatus = "ANALIZANDO RANGO...";
   }
}

void MonitorRetracement() {
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   bool inZone = (h1Dir == 1) ? (price <= f62 && price >= f78) : (price >= f62 && price <= f78);
   if(inZone) { state = STATE_WAIT_CONFIRM; botStatus = "¡ZONA OTE!"; }
   if((h1Dir == 1 && price < f100) || (h1Dir == -1 && price > f100)) state = STATE_WAIT_IMPULSE;
}

void ScanM5Confirmation() {
   double o = iOpen(_Symbol, InpTF_Entry, 1); double c = iClose(_Symbol, InpTF_Entry, 1);
   bool ok = (h1Dir == 1 && c > o && (currentDir==DIR_COMPRAS || currentDir==DIR_AMBAS)) ||
             (h1Dir == -1 && c < o && (currentDir==DIR_VENTAS || currentDir==DIR_AMBAS));
   if(ok) { ExecuteTrade(); state = STATE_WAIT_IMPULSE; }
}

void ExecuteTrade() {
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl = (h1Dir==1) ? ask - InpSL_Pips*_Point : bid + InpSL_Pips*_Point;
   double tp = (h1Dir==1) ? ask + InpTP_Pips*_Point : bid - InpTP_Pips*_Point;
   
   if(h1Dir == 1) trade.Buy(0.01, _Symbol, ask, sl, tp, "SUPREME OTE");
   else trade.Sell(0.01, _Symbol, bid, sl, tp, "SUPREME OTE");
   
   ObjectsDeleteAll(0, "SUP_FIBO");
}

//+------------------------------------------------------------------+
//| INTERFAZ PREMIUM HUD                                             |
//+------------------------------------------------------------------+
void CrearPanel() {
   ObjectsDeleteAll(0, PNL);
   int x=15, y=30, w=290, h=365;
   if(isMinimized) { w=220; h=65; }
   
   CrRect("bg", x, y, w, h, C'10,10,25', C'70,50,140', 2);
   CrRect("hdr", x+2, y+2, w-4, 40, C'30,20,60', C'30,20,60');
   CrLabel("ttl", x+15, y+8, "ELITE SUPREME v13.70", clrWhite, 11, "Arial Bold");
   CrBtn("min", x+w-25, y+8, 18, 18, isMinimized?"+":"-", C'30,20,60', clrWhite);
   
   if(!isMinimized) {
      CrLabel("stL", x+15, y+60, "ID: " + InpMasterID, C'40,200,90', 8, "Arial Bold");
      CrLabel("stV", x+15, y+90, "ESTADO: " + botStatus, C'200,200,200', 9);
      CrLabel("trV", x+15, y+115, "TENDENCIA: " + (h1Dir==1?"ALCISTA ▲":"BAJISTA ▼"), (h1Dir==1?C'40,200,90':C'210,50,50'), 9);
      
      CrBtn("b_zen", x+10, y+165, 130, 25, "MODO ZEN", currentMode==MODE_ZEN?C'40,70,190':C'35,35,65', clrWhite);
      CrBtn("b_har", x+145, y+165, 130, 25, "COSECHA", currentMode==MODE_COSECHA?C'200,80,40':C'35,35,65', clrWhite);
      
      CrBtn("b_buy", x+10, y+200, 85, 25, "BUY", currentDir==DIR_COMPRAS?C'40,70,190':C'35,35,65', clrWhite);
      CrBtn("b_both", x+100, y+200, 85, 25, "AMBAS", currentDir==DIR_AMBAS?C'40,70,190':C'35,35,65', clrWhite);
      CrBtn("b_sell", x+190, y+200, 85, 25, "SELL", currentDir==DIR_VENTAS?C'180,40,40':C'35,35,65', clrWhite);
      
      CrBtn("b_close", x+10, y+245, 270, 45, "CLOSE ALL POSITIONS", C'210,50,50', clrWhite);
      CrLabel("rem", x+15, y+315, "SYNC: ABSOLUTE v1.67", clrWhite, 8);
   }
   ChartRedraw(0);
}

void ActualizarPanel() {
   if(!isMinimized) {
      ObjectSetString(0, PNL+"stV", OBJPROP_TEXT, "ESTADO: " + botStatus);
      ObjectSetString(0, PNL+"trV", OBJPROP_TEXT, "TENDENCIA: " + (h1Dir==1?"ALCISTA ▲":"BAJISTA ▼"));
      ObjectSetInteger(0, PNL+"trV", OBJPROP_COLOR, (h1Dir==1?C'40,200,90':C'210,50,50'));
   }
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
   if(sp == PNL+"min") { isMinimized = !isMinimized; CrearPanel(); }
   if(sp == PNL+"b_zen") { currentMode = MODE_ZEN; CrearPanel(); }
   if(sp == PNL+"b_har") { currentMode = MODE_COSECHA; CrearPanel(); }
   if(sp == PNL+"b_buy") { currentDir = DIR_COMPRAS; CrearPanel(); }
   if(sp == PNL+"b_sell") { currentDir = DIR_VENTAS; CrearPanel(); }
   if(sp == PNL+"b_both") { currentDir = DIR_AMBAS; CrearPanel(); }
   if(sp == PNL+"b_close") for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic()==InpMagic) trade.PositionClose(posInfo.Ticket());
   ObjectSetInteger(0, sp, OBJPROP_STATE, false);
}

void DrawFiboLevels(double p100, double p0, bool isBull) {
   string name = "SUP_FiboOTE";
   ObjectsDeleteAll(0, "SUP_FIBO");
   
   ObjectCreate(0, name, OBJ_FIBO, 0, iTime(_Symbol, InpTF_Fibo, 1), p100, iTime(_Symbol, InpTF_Fibo, 0), p0);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrDarkOrchid);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   
   // Personalizar niveles OTE
   ObjectSetInteger(0, name, OBJPROP_LEVELS, 4);
   ObjectSetDouble(0, name, OBJPROP_LEVELVALUE, 0, 0.5); ObjectSetString(0, name, OBJPROP_LEVELTEXT, 0, "EQ (50%)");
   ObjectSetDouble(0, name, OBJPROP_LEVELVALUE, 1, 0.618); ObjectSetString(0, name, OBJPROP_LEVELTEXT, 1, "OTE (61.8%)");
   ObjectSetDouble(0, name, OBJPROP_LEVELVALUE, 2, 0.705); ObjectSetString(0, name, OBJPROP_LEVELTEXT, 2, "SWEET SPOT (70.5%)");
   ObjectSetDouble(0, name, OBJPROP_LEVELVALUE, 3, 0.786); ObjectSetString(0, name, OBJPROP_LEVELTEXT, 3, "OTE (78.6%)");
}

void ManageExits() {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic()==InpMagic) {
         double open = posInfo.PriceOpen();
         double sl = posInfo.StopLoss();
         double cur = posInfo.PriceCurrent();
         double pnl_points = (posInfo.PositionType()==POSITION_TYPE_BUY) ? (cur-open)/_Point : (open-cur)/_Point;
         
         // 1. BREAK EVEN
         if(InpBE_Trigger > 0 && pnl_points >= InpBE_Trigger && MathAbs(sl-open) > _Point) {
            trade.PositionModify(posInfo.Ticket(), open, posInfo.TakeProfit());
            Print("🛡️ [OTE] BREAK EVEN ACTIVADO");
         }
         
         // 2. TRAILING STOP
         if(InpTrailingStop > 0 && pnl_points > InpTrailingStop + 50) {
            double newSL = (posInfo.PositionType()==POSITION_TYPE_BUY) ? cur - InpTrailingStop*_Point : cur + InpTrailingStop*_Point;
            if((posInfo.PositionType()==POSITION_TYPE_BUY && newSL > sl + 10*_Point) || (posInfo.PositionType()==POSITION_TYPE_SELL && (newSL < sl - 10*_Point || sl==0))) {
               trade.PositionModify(posInfo.Ticket(), newSL, posInfo.TakeProfit());
            }
         }
      }
   }
}

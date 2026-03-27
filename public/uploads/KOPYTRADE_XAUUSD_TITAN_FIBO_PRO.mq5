//+------------------------------------------------------------------+
//|    KOPYTRADE_XAUUSD_TITAN_FIBO_PRO - PROFESSIONAL GRADE          |
//|   H1 TREND + M15 BOS + M5 CONFIRMATION (WICK & CLOSE)            |
//|   Copyright 2026, Kopytrading Corp. - kopytrading.com            |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "1.00"
#property strict
#property description "Titan Fibonacci Pro | Institutional Strategy | Multi-TF Confirmation"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//--- PROTOTYPES ---
void UpdateH1Trend();
bool IsConsolidating();
void ScanM15Impulse();
void CalculateFibo(datetime start, datetime end);
void MonitorRetracement();
void ScanM5Confirmation();
void ExecuteTrade();
void ManageExits();
void DrawFiboLines();
void CrearHUD();
void ActualizarHUD();
double CalculateDynamicLot(double sl_points);
int PositionsTotalBots();
void SyncWeb();
void DrawBOSLevels();


//--- ENUMS ---
enum ENUM_RETRACEMENT_STATE { STATE_WAIT_IMPULSE, STATE_WAIT_RETRACE, STATE_WAIT_CONFIRM };

//--- INPUT PARAMETERS ---
sinput string separator0 = "======= LICENCIA =======";
input string   LicenseKey        = "TRIAL-2026";
input string   PurchaseID        = "";         

sinput string separator1 = "======= RIESGO =======";
input double   RiskPct           = 0.5;        // Riesgo por Operación (%)
input double   MaxDailyRiskPct   = 3.0;        // Máx. Riesgo Diario (%)
input int      MaxDailyTrades    = 5;          // Máx. Operaciones Diarias
input double   FixedProfitTarget = 0.0;        // Meta USD diaria (0 = Desact.)

sinput string separator2 = "======= ESTRATEGIA =======";
input int      EMA_H1_Period     = 50;         // EMA Tendencia H1
input int      ImpulseSensitivity = 3;         // Velas consecutivas M15
input double   ImpulseATRMult    = 1.5;        // Multiplicador ATR para vela "fuerte"
input int      MinWickRatio      = 2;          // Ratio Mecha/Cuerpo (Conf. M5)
input int      MinRetraceCandles = 3;          // Anti-V: Min velas de retroceso

//--- GLOBALES ---
CTrade         trade;
CPositionInfo  posInfo;
int            activeMagic = 880880;
double         f_0=0, f_100=0, f_60=0, f_78=0;
int            h1_dir = 0; // 1=Alcista, -1=Bajista
int            h_ema_h1;
ENUM_RETRACEMENT_STATE state = STATE_WAIT_IMPULSE;
datetime       lastTradedImpulse = 0;
datetime       pointA_time, pointB_time;
int            retraceCandleCount = 0;
string         botStatus = "INICIALIZANDO...";
bool           remotePaused = false;
datetime       lastSync = 0;
const string   PNL_HUD = "FIBO_HUD_";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   trade.SetExpertMagicNumber(activeMagic);
   h_ema_h1 = iMA(_Symbol, PERIOD_H1, EMA_H1_Period, 0, MODE_EMA, PRICE_CLOSE);
   if(h_ema_h1 == INVALID_HANDLE) return(INIT_FAILED);
   
   CrearHUD();
   botStatus = "BUSCANDO TENDENCIA H1...";
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
   ObjectsDeleteAll(0, PNL_HUD, -1, -1);
   IndicatorRelease(h_ema_h1);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   SyncWeb();
   if(remotePaused) { botStatus = "🔴 PAUSA REMOTA"; ActualizarHUD(); return; }

   if(PositionsTotalBots() > 0) {
      ManageExits();
      botStatus = "GESTIONANDO POSICIÓN";
      return;
   }

   if(state == STATE_WAIT_IMPULSE) {
      if(IsConsolidating()) botStatus = "LATERALIZADO (ZONA NO OPERABLE)";
      else botStatus = "BUSCANDO IMPULSO " + (h1_dir == 1 ? "ALCISTA (BUY)" : "BAJISTA (SELL)");
      ScanM15Impulse();
   }
   
   if(state == STATE_WAIT_RETRACE) {
      MonitorRetracement();
      DrawFiboLines(); // Redibujar por seguridad
   }
   
   if(state == STATE_WAIT_CONFIRM) {
      ScanM5Confirmation();
      DrawFiboLines(); // Redibujar por seguridad
   }
   
   ActualizarHUD();
}

//+------------------------------------------------------------------+
//| Update H1 Trend based on EMA 50 + Highs/Lows                     |
//+------------------------------------------------------------------+
void UpdateH1Trend() {
   double ema[];
   if(CopyBuffer(h_ema_h1, 0, 0, 2, ema) < 2) return;
   ArraySetAsSeries(ema, true); // ema[0] es la actual, ema[1] la anterior
   
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   bool above = (price > ema[0]);
   bool sloping_up = (ema[0] > ema[1]);
   
   // Detección basada en posición vs EMA y pendiente (Slope)
   if(above && sloping_up) h1_dir = 1;
   else if(!above && !sloping_up) h1_dir = -1;
   else h1_dir = 0; // Transición o lateralización
}

//+------------------------------------------------------------------+
//| Detect consolidation ranges in M15 (Anti-noise)                  |
//+------------------------------------------------------------------+
bool IsConsolidating() {
   int hi_idx = iHighest(_Symbol, PERIOD_M15, MODE_HIGH, 10, 1);
   int lo_idx = iLowest(_Symbol, PERIOD_M15, MODE_LOW, 10, 1);
   if(hi_idx == -1 || lo_idx == -1) return true;

   double range = iHigh(_Symbol, PERIOD_M15, hi_idx) - iLow(_Symbol, PERIOD_M15, lo_idx);
   
   if(range < 200 * _Point) return true; // Rango muy estrecho (20 pips gold)
   
   // Contar mechas largas en ambas direcciones
   int double_wicks = 0;
   MqlRates r[];
   if(CopyRates(_Symbol, PERIOD_M15, 1, 10, r) >= 10) {
      for(int i=0; i<10; i++) {
         double b = MathAbs(r[i].close - r[i].open);
         double uw = r[i].high - MathMax(r[i].close, r[i].open);
         double lw = MathMin(r[i].close, r[i].open) - r[i].low;
         if(uw > b && lw > b) double_wicks++;
      }
   }
   return (double_wicks > 4); // Más de 4 velas de indecisión en las últimas 10
}

//+------------------------------------------------------------------+
//| Scan for valid impulses in M15 (3 strong candles + BOS)          |
//+------------------------------------------------------------------+
void ScanM15Impulse() {
   if(state != STATE_WAIT_IMPULSE) return;

   MqlRates rates[];
   if(CopyRates(_Symbol, PERIOD_M15, 1, 15, rates) < 15) return;
   
   int count = 0;
   int start_idx = -1;
   
   for(int i=0; i<13; i++) {
      bool bullish = (rates[i].close > rates[i].open);
      bool bearish = (rates[i].close < rates[i].open);
      
      if((h1_dir == 1 && bullish) || (h1_dir == -1 && bearish)) {
         count++;
         if(count >= ImpulseSensitivity) {
            start_idx = i - (ImpulseSensitivity-1);
            break;
         }
      } else count = 0;
   }
   
   if(start_idx != -1) {
      if(rates[start_idx].time <= lastTradedImpulse) return; // Regla de UN Impulso por operación

      if(h1_dir == 1) {
         int prev_hi = iHighest(_Symbol, PERIOD_M15, MODE_HIGH, 60, 1); // Mirar últimas 15 horas (aprox)
         double trigger = iHigh(_Symbol, PERIOD_M15, prev_hi);
         if(SymbolInfoDouble(_Symbol, SYMBOL_BID) > trigger) {
            CalculateFibo(rates[start_idx].time, TimeCurrent());
         } else {
            // Dibuja el Fibo "Previo" mientras busca la ruptura
            CalculateFibo(rates[start_idx].time, rates[0].time);
         }
      } else {
         int prev_lo = iLowest(_Symbol, PERIOD_M15, MODE_LOW, 60, 1);
         double trigger = iLow(_Symbol, PERIOD_M15, prev_lo);
         if(SymbolInfoDouble(_Symbol, SYMBOL_BID) < trigger) {
            CalculateFibo(rates[start_idx].time, TimeCurrent());
         } else {
            // Dibuja el Fibo "Previo" mientras busca la ruptura
            CalculateFibo(rates[start_idx].time, rates[0].time);
         }
      }
   }
   
   DrawBOSLevels();
}

void CalculateFibo(datetime start, datetime end) {
   pointA_time = start;
   pointB_time = end;
   
   int bars = iBarShift(_Symbol, PERIOD_M15, pointA_time);
   double hh = iHigh(_Symbol, PERIOD_M15, iHighest(_Symbol, PERIOD_M15, MODE_HIGH, bars+1, 0));
   double ll = iLow(_Symbol, PERIOD_M15, iLowest(_Symbol, PERIOD_M15, MODE_LOW, bars+1, 0));
   
   if(h1_dir == 1) { f_100 = ll; f_0 = hh; }
   else { f_100 = hh; f_0 = ll; }
   
   double range = MathAbs(f_0 - f_100);
   f_60 = (h1_dir == 1) ? f_0 - range * 0.618 : f_0 + range * 0.618;
   f_78 = (h1_dir == 1) ? f_0 - range * 0.786 : f_0 + range * 0.786;
   
   state = STATE_WAIT_RETRACE;
   retraceCandleCount = 0;
   botStatus = "DIAMANTE DETECTADO (FIBO ACTIVADO)";
   DrawFiboLines();
}

void ExecuteTrade() {
   double sl = f_78;
   double tp1 = f_0;
   double tp2 = (h1_dir == 1) ? f_0 + MathAbs(f_0 - f_100) * 0.272 : f_0 - MathAbs(f_0 - f_100) * 0.272;
   
   double dist_pts = MathAbs(SymbolInfoDouble(_Symbol, SYMBOL_ASK) - sl) / _Point;
   double lots = CalculateDynamicLot(dist_pts);
   
   if(h1_dir == 1) {
      if(trade.Buy(lots, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_ASK), sl, tp2, "FIBO_P")) {
         state = STATE_WAIT_IMPULSE;
         botStatus = "ORDEN L0NG EJECUTADA";
      }
   } else {
      if(trade.Sell(lots, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_BID), sl, tp2, "FIBO_P")) {
         state = STATE_WAIT_IMPULSE;
         botStatus = "ORDEN SH0RT EJECUTADA";
      }
   }
}

void ManageExits() {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic() == activeMagic) {
         double price = (posInfo.PositionType() == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         
         // 1. Cierre parcial al llegar al 0% (TP1)
         if(posInfo.Comment() == "FIBO_P") {
            bool hit_tp1 = (posInfo.PositionType() == POSITION_TYPE_BUY) ? (price >= f_0) : (price <= f_0);
            if(hit_tp1) {
               double close_lots = NormalizeDouble(posInfo.Volume() / 2.0, 2);
               if(trade.PositionClosePartial(posInfo.Ticket(), close_lots)) {
                  // Mover a Break Even
                  double be_level = (posInfo.PositionType() == POSITION_TYPE_BUY) ? posInfo.PriceOpen() + (10 * _Point) : posInfo.PriceOpen() - (10 * _Point);
                  trade.PositionModify(posInfo.Ticket(), NormalizeDouble(be_level, _Digits), posInfo.TakeProfit());
               }
            }
         }
      }
   }
}

void MonitorRetracement() {
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   // Ver si invalidamos el impulso (rompe el inicio del impulso 100%)
   if(h1_dir == 1 && price < f_100) { state = STATE_WAIT_IMPULSE; ObjectsDeleteAll(0, "FIBO_"); return; }
   if(h1_dir == -1 && price > f_100) { state = STATE_WAIT_IMPULSE; ObjectsDeleteAll(0, "FIBO_"); return; }

   // Ver si invalidamos por ir más allá del 78.6%
   if(h1_dir == 1 && price < f_78) { state = STATE_WAIT_IMPULSE; ObjectsDeleteAll(0, "FIBO_"); return; }
   if(h1_dir == -1 && price > f_78) { state = STATE_WAIT_IMPULSE; ObjectsDeleteAll(0, "FIBO_"); return; }

   // Detectar llegada a la zona OTE (Optimal Trade Entry) entre 61.8 y 78.6
   bool in_zone = false;
   if(h1_dir == 1 && price <= f_60 && price >= f_78) in_zone = true;
   if(h1_dir == -1 && price >= f_60 && price <= f_78) in_zone = true;

   if(in_zone) {
      // Contar velas de retroceso (Anti-V)
      int bars = iBarShift(_Symbol, PERIOD_M15, pointB_time);
      if(bars >= MinRetraceCandles) {
         state = STATE_WAIT_CONFIRM;
         botStatus = "ZONA FIBO ALCANZADA (ESPERANDO M5)";
      } else {
         botStatus = "RETROCESO DEMASIADO RÁPIDO (ANTI-V)";
      }
   }
}

void ScanM5Confirmation() {
   MqlRates r[];
   if(CopyRates(_Symbol, PERIOD_M5, 0, 1, r) < 1) return;
   
   double body = MathAbs(r[0].close - r[0].open);
   double upper_wick = r[0].high - MathMax(r[0].close, r[0].open);
   double lower_wick = MathMin(r[0].close, r[0].open) - r[0].low;
   
   bool confirmed = false;
   if(h1_dir == 1) {
      // Reclamamos martillo o vela con mucha mecha abajo + cierre alcista
      if(lower_wick > body * MinWickRatio && r[0].close >= r[0].open) confirmed = true;
   } else {
      // Reclamamos estrella fugaz o vela con mucha mecha arriba + cierre bajista
      if(upper_wick > body * MinWickRatio && r[0].close <= r[0].open) confirmed = true;
   }
   
   if(confirmed) {
      ExecuteTrade();
      lastTradedImpulse = pointB_time;
   }
}

void DrawFiboLines() {
   ObjectsDeleteAll(0, "FIBO_");
   string n0="FIBO_0", n38="FIBO_38", n50="FIBO_50", n60="FIBO_60", n78="FIBO_78";
   ObjectCreate(0, n0, OBJ_HLINE, 0, 0, f_0);
   ObjectCreate(0, n38, OBJ_HLINE, 0, 0, (h1_dir==1?f_0-MathAbs(f_0-f_100)*0.382:f_0+MathAbs(f_0-f_100)*0.382));
   ObjectCreate(0, n50, OBJ_HLINE, 0, 0, (h1_dir==1?f_0-MathAbs(f_0-f_100)*0.500:f_0+MathAbs(f_0-f_100)*0.500));
   ObjectCreate(0, n60, OBJ_HLINE, 0, 0, f_60);
   ObjectCreate(0, n78, OBJ_HLINE, 0, 0, f_78);
   
   ObjectSetInteger(0, n0, OBJPROP_COLOR, clrAqua);
   ObjectSetInteger(0, n38, OBJPROP_COLOR, C'200,200,200');
   ObjectSetInteger(0, n50, OBJPROP_COLOR, C'150,150,150');
   ObjectSetInteger(0, n60, OBJPROP_COLOR, clrGold);
   ObjectSetInteger(0, n78, OBJPROP_COLOR, clrOrangeRed);
   ObjectSetInteger(0, n60, OBJPROP_WIDTH, 2);
   
   // Etiquetas de precios
   string p60 = "FIBO_P_60", p78 = "FIBO_P_78";
   ObjectCreate(0, p60, OBJ_TEXT, 0, pointB_time, f_60);
   ObjectSetString(0, p60, OBJPROP_TEXT, "  OTE ZONE - ENTRADA PROBABLE");
   ObjectSetInteger(0, p60, OBJPROP_COLOR, clrGold);
   
   ObjectCreate(0, p78, OBJ_TEXT, 0, pointB_time, f_78);
   ObjectSetString(0, p78, OBJPROP_TEXT, "  STOP LOSS - INVALIDACIÓN");
   ObjectSetInteger(0, p78, OBJPROP_COLOR, clrOrangeRed);
}

#define PNL_HUD_OLD "FIBO_HUD_" // Unused but kept for legacy
void CrearHUD() {
    ObjectsDeleteAll(0, PNL_HUD, -1, -1);
    int x=15, y=30, w=280, h=250;
    CrRect("bg",x,y,w,h,C'15,20,35',C'100,150,255',2);
    CrLabel("ttl",x+15,y+12,"💎 TITAN FIBONACCI PRO",C'100,200,255',10,"Impact");
    
    int gy = y+45;
    CrLabel("stL",x+15,gy,   "SITUACIÓN:",C'130,130,150',8); 
    CrLabel("stV",x+95,gy,   botStatus,clrWhite,8,"Arial Bold");
    
    CrLabel("trL",x+15,gy+20,"TENDENCIA H1:",C'130,130,150',8);
    CrLabel("trV",x+95,gy+20,(h1_dir==1?"ALCISTA ▲":"BAJISTA ▼"), (h1_dir==1?clrSpringGreen:clrOrangeRed),8,"Arial Black");
    
    int py = gy+55;
    CrRect("sep",x+15,py-5,w-30,1,C'60,70,90',C'60,70,90',1);
    CrLabel("lkL",x+15,py,   "LOOKBACK:",C'130,130,150',8);   CrLabel("lkV",x+100,py,"H1 / M15 / M5",clrWhite,8);
    CrLabel("riL",x+15,py+20,"RIESGO:",C'130,130,150',8);     CrLabel("riV",x+100,py+20,DoubleToString(RiskPct,1)+"% PER TRADE",clrGold,8,"Arial Bold");
    
    int by = y+h-50;
    CrButton("close",x+15,by,w-30,35,"ARRANCAR / RESET MANUAL",C'50,70,120',clrWhite);
}

void ActualizarHUD() {
    ObjectSetString(0,PNL_HUD+"stV",OBJPROP_TEXT,botStatus);
    ObjectSetInteger(0,PNL_HUD+"trV",OBJPROP_COLOR,(h1_dir==1?clrSpringGreen:clrOrangeRed));
    ObjectSetString(0,PNL_HUD+"trV",OBJPROP_TEXT,(h1_dir==1?"ALCISTA ▲":"BAJISTA ▼"));
}

void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bdw=1) {
   string name = PNL_HUD+n;
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR, bd);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, bdw);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 100);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

void CrLabel(string n, int x, int y, string t, color c, int s, string f="Arial") {
   string name = PNL_HUD+n;
   ObjectCreate(0, name, OBJ_LABEL, 0,0,0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, t);
   ObjectSetInteger(0, name, OBJPROP_COLOR, c);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, s);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 101);
   ObjectSetString(0, name, OBJPROP_FONT, f);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

void CrButton(string n, int x, int y, int w, int h, string t, color bg, color tc) {
   string name = PNL_HUD+n;
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetString(0, name, OBJPROP_TEXT, t);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR, tc);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 105);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial Black");
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

double CalculateDynamicLot(double sl_points) {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double risk_usd = balance * (RiskPct / 100.0);
   double tick_val = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   
   if(sl_points <= 0) return 0.01;
   
   double lots = risk_usd / (sl_points * tick_val);
   
   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   lots = MathFloor(lots / lot_step) * lot_step;
   if(lots < min_lot) lots = min_lot;
   if(lots > max_lot) lots = max_lot;
   
   return lots;
}

int PositionsTotalBots() {
   int c=0;
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic() == activeMagic) c++;
   }
   return c;
}

void DrawBOSLevels() {
   if(state != STATE_WAIT_IMPULSE) {
      ObjectsDeleteAll(0, "BOS_");
      return;
   }
   
   double trigger = 0;
   color col = clrNONE;
   string msg = "";
   
   if(h1_dir == 1) {
      int idx = iHighest(_Symbol, PERIOD_M15, MODE_HIGH, 60, 5);
      trigger = iHigh(_Symbol, PERIOD_M15, idx);
      col = clrDodgerBlue;
      msg = "BOS TRIGGER - BREAKOUT PARA COMPRA (BUY)";
   } else {
      int idx = iLowest(_Symbol, PERIOD_M15, MODE_LOW, 60, 5);
      trigger = iLow(_Symbol, PERIOD_M15, idx);
      col = clrTomato;
      msg = "BOS TRIGGER - BREAKOUT PARA VENTA (SELL)";
   }
   
   if(trigger > 0) {
      string n = "BOS_LINE";
      ObjectCreate(0, n, OBJ_HLINE, 0, 0, trigger);
      ObjectSetInteger(0, n, OBJPROP_COLOR, col);
      ObjectSetInteger(0, n, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, n, OBJPROP_WIDTH, 1);
      
      string t = "BOS_TEXT";
      ObjectCreate(0, t, OBJ_TEXT, 0, TimeCurrent(), trigger);
      ObjectSetString(0, t, OBJPROP_TEXT, "   " + msg);
      ObjectSetInteger(0, t, OBJPROP_COLOR, col);
      ObjectSetInteger(0, t, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
   }
}

void SyncWeb() {
   if(PurchaseID=="" || TimeCurrent()<lastSync+30) return; lastSync=TimeCurrent();
   string postD="{\"purchaseId\":\""+PurchaseID+"\",\"account\":\""+IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN))+"\",\"version\":\"T-FIBO-1.0\",\"status\":\""+botStatus+"\"}";
   char post[], res[]; string rH, head="Content-Type: application/json\r\n";
   StringToCharArray(postD,post,0,StringLen(postD),CP_UTF8);
   if(WebRequest("POST","https://www.kopytrading.com/api/sync-positions",head,3000,post,res,rH) == 200) {
      string r = CharArrayToString(res,0,WHOLE_ARRAY,CP_UTF8);
      if(StringFind(r,"\"paused\":true")>=0) remotePaused=true;
      if(StringFind(r,"\"paused\":false")>=0) remotePaused=false;
   }
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
   if(id == CHARTEVENT_OBJECT_CLICK && sparam == PNL_HUD+"close") {
      state = STATE_WAIT_IMPULSE;
      botStatus = "RESET SOLICITADO";
      ObjectsDeleteAll(0, "FIBO_");
      ActualizarHUD();
   }
}

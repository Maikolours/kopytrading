//|          KOPYTRADING_BTCUSD_BTCStormRider_Cent ÉLITE             |
//|   EDICIÓN ESPECIAL CUENTA CENT | RIESGO $1 | STOP $5             |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Bot Oficial"
//--- GENERADOR DE HASH PARA MAGIC NUMBER AUTOMATICO ---
uint GetHash(string text) {
   uint hash = 5381;
   for(int i = 0; i < StringLen(text); i++) hash = ((hash << 5) + hash) + text[i];
   return hash & 0x7FFFFFFF;
}
#property version   "6.65"
#property strict
#property description "BTC Storm Rider Cent | Edición Cent kopytrading.com"

#include <Trade\Trade.mqh>

//--- DECLARACIONES DE FUNCIONES VISUALES ---
void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bw=1);
void CrLabel(string n, int x, int y, string t, color c, int s=9, string f="Segoe UI");
void CrBtn(string n, int x, int y, int w, int h, string t, color bg, color tc);

//============================================================
//  LICENCIA & TELEGRAM
//============================================================
input group "=== LICENCIA & MOBILE BRIDGE ==="
input long   CuentaDemo        = 0;
input long   CuentaReal        = 0;
input string TelegramToken     = ""; 
input long   TelegramChatID    = 0; 
input bool   NotificarTelegram = true;

//============================================================
//  SESIONES
//============================================================
input group "=== SESIONES DE MERCADO (HORA BROKER) ==="
input int    SesionEuropa_Inicio = 0;
input int    SesionEuropa_Fin   = 16;
input int    SesionUS_Inicio    = 14;
input int    SesionUS_Fin       = 24;
input bool   OperarEnAsia       = true;

//============================================================
//  GESTIÓN DE RIESGO (MODO CENT)
//============================================================
input group "=== GESTION DE RIESGO (MODO CENT) ==="
input double LoteInicial            = 0.01;
input double MaxRiesgoPorTrade_USD  = 100.0;     // 🛑 Stop por Operación (100 = $1).
input double ATR_Multiplicador_SL   = 1.5;
input double ATR_Multiplicador_TP   = 3.0;

input group "=== LICENCIA & WEB BRIDGE ==="
input string Token_Web              = "";   
input string purchaseID_Synced      = "";   
input bool   SilentTelegram         = true; 

input group "=== STOP ESTRUCTURAL ==="
input int    Velas_Estructural      = 10;   
input double Margen_Extra_USD       = 200.0;  // 200 = $2 safety margin

//============================================================
//  PROTECCION DE CUENTA (ANTI-RACHA)
//============================================================
input group "=== PROTECCION DE CUENTA (ANTI-RACHA) ==="
input double MaxPerdidaDiaria_USD = 500.0;    // 500 = $5 real
input double MaxDrawdown_USD      = 500.0;    // 🛑 Stop de Emergencia ($5).
input int    MaxOperacionesDia    = 50;

//============================================================
//  BREAK EVEN (CENT)
//============================================================
input group "=== BREAK EVEN (UNITS) ==="
input bool   ActivarBE        = true;
input double BE_Activar_USD   = 30.0;        // 30 unidades
input double BE_Garantia_USD  = 10.0;        // 10 unidades

//============================================================
//  TRAILING STOP (CENT)
//============================================================
input group "=== TRAILING STOP (CENT) ==="
input int    Puntos_Minimos_Trailing  = 100;
input bool   ActivarTrailing          = true;
input double Trailing_Activar_USD     = 50.0;
input double Trailing_Distancia_USD   = 50.0;

//============================================================
//  SMART HEDGE (RESCATE CENT)
//============================================================
input group "=== SMART HEDGE (RESCATE CENT) ==="
input bool   ActivarHedge           = true;     
input double DistanciaRescate       = 50.0;     // 50 = $0.50 centavos para gatillo
input double Meta_Ciclo_USD         = 30.0;     // 30 USC para cerrar ciclo
input double HedgeLoteMult          = 1.5;      

//============================================================
//  CONFIGURACION AVANZADA
//============================================================
input group "=== CONFIGURACION AVANZADA ==="
input int    MaxPosiciones   = 2;
input int    MinutosEspera   = 20;
input bool   MostrarPanel    = true;
input long   InpMagicNumber  = 202510;

//--- Variables internas ---
CTrade   trade;
long     MagicNumber;
bool     licenseValid = false;
string   licenseMsg   = "CENT EDITION";
int      hEmaTend, hEmaRap, hEmaLent, hRSI, hATR;
datetime ultimaVela = 0;
datetime ultimaEntrada = 0;
int      diaActual = -1;
int      opsHoy = 0;
int      lastUpdateID = 0;
datetime lastRemoteSync = 0;
datetime lastPositionsSync = 0;
int      lastPosCount = 0;
datetime cooldownUntil = 0;
bool     hedgeActive = false;
ulong    hedgeTicket = 0;
bool     remotePaused = false;
int      ModoBot = 0;
bool     StrucSL = true;
bool     Minimized = false;

#define PNL "BSR64_C_"

//--- COLORES ORIGINALES v5.0 ---
color CLR_BG      = C'12,12,30';
color CLR_HDR     = C'35,25,75';
color CLR_BRD     = C'80,60,160';
color CLR_SEP     = C'50,50,90';
color CLR_TXT     = clrWhite;
color CLR_MUTED   = C'140,140,180';
color CLR_SUCCESS = C'50,210,100';
color CLR_DANGER  = C'220,60,60';
color CLR_WARN    = C'220,180,50';
color CLR_ACCENT  = C'50,80,200';

//--- FUNCIONES DE APOYO ---
string GetTimeLeft() {
   datetime nb = iTime(_Symbol, _Period, 0) + PeriodSeconds(_Period);
   long d = (long)nb - (long)TimeCurrent();
   if(d < 0) d = 0;
   return StringFormat("%02d:%02d", (int)(d/60), (int)(d%60));
}

double GetStructuralSL(ENUM_POSITION_TYPE t) {
   int hi = iHighest(_Symbol, _Period, MODE_HIGH, Velas_Estructural, 1);
   int li = iLowest(_Symbol, _Period, MODE_LOW, Velas_Estructural, 1);
   double pps = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double ppv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(ppv <= 0 || pps <= 0) return 0;
   double pointsForDollar = pps / (ppv * LoteInicial);
   double marginPrice = Margen_Extra_USD * pointsForDollar;
   double res = (t == POSITION_TYPE_SELL) ? (iHigh(_Symbol, _Period, hi) + marginPrice) : (iLow(_Symbol, _Period, li) - marginPrice);
   double stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   double price = (t == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(t == POSITION_TYPE_BUY) { if(price - res < stopLevel + (5 * _Point)) res = price - stopLevel - (10 * _Point); } 
   else { if(res - price < stopLevel + (5 * _Point)) res = price + stopLevel + (10 * _Point); }
   return NormalizeDouble(res, _Digits);
}

int OnInit() {
   hEmaTend = iMA(_Symbol, _Period, 200, 0, MODE_EMA, PRICE_CLOSE);
   hEmaRap  = iMA(_Symbol, _Period, 21,  0, MODE_EMA, PRICE_CLOSE);
   hEmaLent = iMA(_Symbol, _Period, 55,  0, MODE_EMA, PRICE_CLOSE);
   hRSI     = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   hATR     = iATR(_Symbol, _Period, 14);
   
   if(InpMagicNumber == 0) MagicNumber = (int)GetHash(_Symbol + IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN)));
   else MagicNumber = InpMagicNumber;
   
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetTypeFillingBySymbol(_Symbol);
   licenseValid = true;
   if(MostrarPanel) CrearPanel();
   return INIT_SUCCEEDED;
}

void OnDeinit(const int r) { ObjectsDeleteAll(0, PNL); }

void OnTick() {
   if(!licenseValid) return;
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   if(dt.day_of_year != diaActual) { diaActual = dt.day_of_year; opsHoy = 0; }
   
   int currentPos = ContarPos();
   if(currentPos < lastPosCount) {
      cooldownUntil = TimeCurrent() + (MinutosEspera * 60);
      SendTelegramMessage("ℹ️ BTC CENT: Cierre detectado.");
   }
   lastPosCount = currentPos;

   if(MaxDrawdown_USD > 0 && GetCurrentNetProfit() <= -MaxDrawdown_USD) {
      CloseAllBotPositions(); remotePaused = true;
      SendTelegramMessage("🛑 BTC EMERGENCY CENT: Drawdown superó $" + DoubleToString(MaxDrawdown_USD/100.0, 2) + " reales.");
   }

   if(remotePaused) {
      ObjectSetString(0, PNL+"stV", OBJPROP_TEXT, "PAUSADO REMOTO");
      ObjectSetInteger(0, PNL+"stV", OBJPROP_COLOR, CLR_WARN);
      ProcessTelegramCommands(); return;
   }

   if(ActivarHedge) ManageHedge();
   CheckEntradas();
   if(MostrarPanel) ActualizarPanel();
   ManageBETrailing();
   ProcessTelegramCommands();
   SyncWithWeb();
   SyncPositions();
}

void SyncWithWeb() {
   if(purchaseID_Synced == "" || TimeCurrent() < lastRemoteSync + 30) return;
   lastRemoteSync = TimeCurrent();
   string account = IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN));
   string url = "https://kopytrading.com/api/remote-control?purchaseId=" + purchaseID_Synced + "&account=" + account;
   char post[], result[]; string headers;
   int res = WebRequest("GET", url, headers, 2000, post, result, headers);
   if(res == 200) {
      string response = CharArrayToString(result);
      if(StringFind(response, "\"command\":\"PAUSE\"") != -1) remotePaused = true;
      if(StringFind(response, "\"command\":\"RESUME\"") != -1) remotePaused = false;
      if(StringFind(response, "\"command\":\"CLOSE_ALL\"") != -1) CloseAllBotPositions();
      if(MostrarPanel) CrearPanel();
   }
}

double USDtoPrice(double usd, double lot) {
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickValue <= 0 || lot <= 0) return 0;
   return (usd * tickSize) / (tickValue * lot);
}

void ManageBETrailing() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket) || PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      double profit = PositionGetDouble(POSITION_PROFIT);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL = PositionGetDouble(POSITION_SL);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double lot = PositionGetDouble(POSITION_VOLUME);
      double stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;

      if(ActivarBE && profit >= BE_Activar_USD) {
         double nSL = (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) ? openPrice + USDtoPrice(BE_Garantia_USD, lot) : openPrice - USDtoPrice(BE_Garantia_USD, lot);
         nSL = NormalizeDouble(nSL, _Digits);
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) { if(nSL > currentSL && nSL <= bid - stopLevel) trade.PositionModify(ticket, nSL, 0); }
         else { if((currentSL == 0 || nSL < currentSL) && nSL >= ask + stopLevel) trade.PositionModify(ticket, nSL, 0); }
      }
   }
}

void ManageHedge() {
   double netProfit = GetCurrentNetProfit();
   int mainPos = ContarPos();
   if(hedgeTicket > 0) {
      if(!PositionSelectByTicket(hedgeTicket)) { hedgeTicket = 0; hedgeActive = false; } 
      else {
         double pPos = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         if(pPos >= Meta_Ciclo_USD || mainPos == 0 || netProfit >= -2.0) {
            Print("ℹ️ BTC: Cerrando rescate. PnL Pos: ", pPos, " | PnL Ciclo: ", netProfit);
            trade.PositionClose(hedgeTicket);
         }
         return;
      }
   }
   if(!hedgeActive && mainPos > 0 && netProfit <= -DistanciaRescate) {
      ENUM_POSITION_TYPE hedgeType = (GetDominantSide() == POSITION_TYPE_BUY) ? POSITION_TYPE_SELL : POSITION_TYPE_BUY;
      double lot = LoteInicial * HedgeLoteMult;
      double price = (hedgeType == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(hedgeType == POSITION_TYPE_BUY) trade.Buy(NormalizeLot(lot), _Symbol, price, 0, 0, "BSR66_HEDGE");
      else trade.Sell(NormalizeLot(lot), _Symbol, price, 0, 0, "BSR66_HEDGE");
      hedgeTicket = trade.ResultOrder(); hedgeActive = (hedgeTicket>0);
      if(hedgeActive) {
         Print("🚑 BTC CENT: HEDGE ACTIVADO a ", netProfit, " USC");
         SendTelegramMessage("🚑 BTC CENT: HEDGE ACTIVADO (" + DoubleToString(netProfit, 0) + " USC)");
      }
   }
}

ENUM_POSITION_TYPE GetDominantSide() {
   int b=0, s=0; for(int i=0; i<PositionsTotal(); i++) if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC)==MagicNumber) { if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) b++; else s++; }
   return (b >= s) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
}

double NormalizeLot(double l) {
   double min = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double res = MathFloor(l/step)*step; return (res < min) ? min : res;
}

void CheckEntradas() {
   if(TimeCurrent() < cooldownUntil) return;
   datetime v = iTime(_Symbol, _Period, 0); 
   if(v == ultimaVela) return;
   
   double r[1], l[1]; CopyBuffer(hEmaRap,0,0,1,r); CopyBuffer(hEmaLent,0,0,1,l);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   if(r[0] > l[0] && bid > r[0] && ModoBot != 2 && ContarPos() < MaxPosiciones) { 
      ultimaVela = v; // Marcar vela antes para evitar loops
      if(trade.Buy(LoteInicial, _Symbol, ask, GetStructuralSL(POSITION_TYPE_BUY), 0, "BSR63_B")) {
         opsHoy++;
         Print("✅ BTC: Compra abierta. Lote: ", LoteInicial);
      }
   }
   if(r[0] < l[0] && bid < r[0] && ModoBot != 1 && ContarPos() < MaxPosiciones) { 
      ultimaVela = v; // Marcar vela antes
      if(trade.Sell(LoteInicial, _Symbol, bid, GetStructuralSL(POSITION_TYPE_SELL), 0, "BSR63_S")) {
         opsHoy++;
         Print("✅ BTC: Venta abierta. Lote: ", LoteInicial);
      }
   }
}

int ContarPos() {
   int c=0; for(int i=0; i<PositionsTotal(); i++) if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL)==_Symbol && (PositionGetInteger(POSITION_MAGIC)==MagicNumber || StringFind(PositionGetString(POSITION_COMMENT),"BSR63")!=-1)) c++;
   return c;
}

void ProcessTelegramCommands() {
   if(TelegramToken == "" || TelegramChatID == 0) return;
   string url = "https://api.telegram.org/bot" + TelegramToken + "/getUpdates?offset=" + IntegerToString(lastUpdateID + 1);
   char post[], result[]; string headers;
   int res = WebRequest("GET", url, headers, 1000, post, result, headers);
   if(res == 200) {
      string resp = CharArrayToString(result);
      if(StringFind(resp, "\"/status\"") != -1) { SendTelegramStatus(); lastUpdateID = ParseUpdateID(resp); }
      if(StringFind(resp, "\"/closeall\"") != -1) { CloseAllBotPositions(); lastUpdateID = ParseUpdateID(resp); }
   }
}

void SendTelegramStatus() {
   SendTelegramMessage("📊 BTC CENT\nBeneficio: " + DoubleToString(GetCurrentNetProfit(), 0) + " USC\nPos: " + IntegerToString(ContarPos()));
}

bool SendTelegramMessage(string msg) {
   if(TelegramToken == "" || TelegramChatID <= 0) return false;
   string url = "https://api.telegram.org/bot" + TelegramToken + "/sendMessage";
   string payload = "chat_id=" + IntegerToString(TelegramChatID) + "&text=" + msg;
   char post[], result[]; string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
   StringToCharArray(payload, post, 0, WHOLE_ARRAY, CP_UTF8);
   WebRequest("POST", url, headers, 2000, post, result, headers); return true;
}

long ParseUpdateID(string json) { int pos = StringFind(json, "\"update_id\":"); return (pos == -1) ? lastUpdateID : (long)StringToInteger(StringSubstr(json, pos + 12, 10)); }

void CloseAllBotPositions() { for(int i=PositionsTotal()-1; i>=0; i--) { ulong t = PositionGetTicket(i); if(PositionSelectByTicket(t) && PositionGetInteger(POSITION_MAGIC) == MagicNumber) trade.PositionClose(t); } }

double GetCurrentNetProfit() {
   double p = 0; for(int i=PositionsTotal()-1; i>=0; i--) if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC)==MagicNumber) p += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
   return p;
}

double GetDailyProfit() {
   HistorySelect(iTime(_Symbol, PERIOD_D1, 0), TimeCurrent());
   double p = 0; for(int i=HistoryDealsTotal()-1; i>=0; i--) { ulong t = HistoryDealGetTicket(i); if(HistoryDealGetInteger(t, DEAL_MAGIC) == MagicNumber) p += HistoryDealGetDouble(t, DEAL_PROFIT); }
   return p;
}

void CrearPanel() {
   ObjectsDeleteAll(0, PNL); 
   int x=15, y=15, w=295, h=400; if(Minimized) { w=220; h=65; }
   CrRect("bg", x, y, w, h, CLR_BG, CLR_BRD, 2);
   CrRect("hdr", x+2, y+2, w-4, 40, CLR_HDR, CLR_HDR);
   CrLabel("ttl", x+15, y+8, "BTC RIDER v6.65", clrWhite, 11, "Arial Bold");
   CrLabel("sub", x+15, y+25, "kopytrading.com", CLR_MUTED, 7);
   CrBtn("min", x+w-25, y+8, 18, 18, Minimized?"+":"-", CLR_HDR, clrWhite);
   
   if(!Minimized) {
      CrLabel("licV", x+15, y+60, "LICENCIA: " + licenseMsg, CLR_WARN, 8, "Arial Bold");
      CrLabel("pL", x+15, y+90, "PnL HOY:", CLR_MUTED, 8); CrLabel("pV", x+110, y+90, "0", CLR_TXT, 10, "Arial Bold");
      CrLabel("lsL", x+15, y+115, "FLOTANTE:", CLR_MUTED, 8); CrLabel("lsV", x+110, y+115, "0", CLR_DANGER, 9);
      
      CrLabel("moH", x+12, y+150, "MODOS DE DIRECCIÓN", CLR_MUTED, 7);
      CrBtn("b_buy", x+10, y+170, 90, 25, "SOLO BUY", ModoBot==1?CLR_ACCENT:C'35,35,65', clrWhite);
      CrBtn("b_both", x+105, y+170, 90, 25, "AMBAS", ModoBot==0?CLR_ACCENT:C'35,35,65', clrWhite);
      CrBtn("b_sell", x+200, y+205-35, 85, 25, "SOLO SELL", ModoBot==2?C'180,40,40':C'35,35,65', clrWhite);
      
      CrBtn("b_close", x+10, y+215, 185, 30, "CLOSE ALL POSITIONS", CLR_DANGER, clrWhite);
      CrBtn("b_test", x+205, y+215, 80, 30, "TEST BOT", C'50,50,80', clrWhite);
      
      CrLabel("rem", x+15, y+265, "REMOTO: " + (remotePaused?"🔴 PAUSA":"🟢 ONLINE"), (remotePaused?CLR_DANGER:CLR_SUCCESS), 8);
      CrLabel("stV", x+85, h-32+y, remotePaused?"PAUSADO REMOTO":"OPERATIVO", CLR_SUCCESS, 10, "Arial Bold");
   }
   ChartRedraw(0);
}

void ActualizarPanel() {
   if(!Minimized) {
      double d = GetDailyProfit(), f = GetCurrentNetProfit();
      ObjectSetString(0, PNL+"pV", OBJPROP_TEXT, DoubleToString(d, 2));
      ObjectSetString(0, PNL+"lsV", OBJPROP_TEXT, DoubleToString(f, 2));
      ObjectSetInteger(0, PNL+"pV", OBJPROP_COLOR, d>=0?CLR_SUCCESS:CLR_DANGER);
      ObjectSetInteger(0, PNL+"lsV", OBJPROP_COLOR, f>=0?CLR_SUCCESS:CLR_DANGER);
      ObjectSetString(0, PNL+"stV", OBJPROP_TEXT, remotePaused?"PAUSADO REMOTO":"OPERATIVO");
      ObjectSetInteger(0, PNL+"stV", OBJPROP_COLOR, remotePaused?CLR_WARN:CLR_SUCCESS);
   }
   ChartRedraw(0);
}

void OnChartEvent(const int id, const long &lp, const double &dp, const string &sp) {
   if(id!=CHARTEVENT_OBJECT_CLICK) return;
   if(sp==PNL+"min") { Minimized=!Minimized; CrearPanel(); }
   if(sp==PNL+"b_buy") { ModoBot=1; CrearPanel(); }
   if(sp==PNL+"b_sell") { ModoBot=2; CrearPanel(); }
   if(sp==PNL+"b_both") { ModoBot=0; CrearPanel(); }
   if(sp==PNL+"b_close") { CloseAllBotPositions(); }
   if(sp==PNL+"b_test") { if(SendTelegramMessage("🔔 Prueba conexión BTC HUD OK.")) Alert("¡Mensaje enviado!"); }
   ObjectSetInteger(0, sp, OBJPROP_STATE, false);
}

void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bw=1) {
   ObjectCreate(0,PNL+n,OBJ_RECTANGLE_LABEL,0,0,0); ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h); ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,bd); ObjectSetInteger(0,PNL+n,OBJPROP_BORDER_TYPE,BORDER_FLAT); 
}
void CrLabel(string n, int x, int y, string t, color c, int s, string f) {
   ObjectCreate(0,PNL+n,OBJ_LABEL,0,0,0); ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y); ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,c); ObjectSetInteger(0,PNL+n,OBJPROP_FONTSIZE,s); ObjectSetString(0,PNL+n,OBJPROP_FONT,f);
}
void CrBtn(string n, int x, int y, int w, int h, string t, color bg, color tc) {
   ObjectCreate(0,PNL+n,OBJ_BUTTON,0,0,0); ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h); ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,tc);
}
void SyncPositions() {
    if(purchaseID_Synced == "" || TimeCurrent() < lastPositionsSync + 30) return;
    lastPositionsSync = TimeCurrent();
    string account = IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN)), positionsJson = "";
    int count = 0;
    for(int i=0; i<PositionsTotal(); i++) {
        if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
            if(count > 0) positionsJson += ",";
            positionsJson += "{\"ticket\":\"" + IntegerToString(PositionGetInteger(POSITION_TICKET)) + "\",\"profit\":" + DoubleToString(PositionGetDouble(POSITION_PROFIT), 2) + "}";
            count++;
        }
    }
    string post = "{\"purchaseId\":\"" + purchaseID_Synced + "\",\"account\":\"" + account + "\",\"positions\":[" + positionsJson + "]}";
    char p[], r[]; string h = "Content-Type: application/json\r\n";
    StringToCharArray(post, p, 0, WHOLE_ARRAY, CP_UTF8);
    WebRequest("POST", "https://kopytrading.com/api/sync-positions", h, 2000, p, r, h);
}

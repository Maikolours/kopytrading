//|          KOPYTRADING_BTCUSD_BTCStormRider v6.6 ÉLITE             |
//|   DISEÑO v6 COMPLETO | SL ESTRUCTURAL 5h | ATR REAL | MINIMIZAR  |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Bot Oficial"
//--- GENERADOR DE HASH PARA MAGIC NUMBER AUTOMATICO ---
uint GetHash(string text) {
   uint hash = 5381;
   for(int i = 0; i < StringLen(text); i++) hash = ((hash << 5) + hash) + text[i];
   return hash & 0x7FFFFFFF;
}
#property version   "6.60"
#property strict
#property description "BTC Storm Rider v6.6 | Edición Élite kopytrading.com"

#include <Trade\Trade.mqh>

//--- DECLARACIONES DE FUNCIONES VISUALES (Forward Declarations) ---
void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bw=1);
void CrLabel(string n, int x, int y, string t, color c, int s=9, string f="Segoe UI");
void CrBtn(string n, int x, int y, int w, int h, string t, color bg, color tc);

//============================================================
//  LICENCIA & TELEGRAM
//============================================================
input group "=== LICENCIA & MOBILE BRIDGE ==="
input long   CuentaDemo        = 0;
input long   CuentaReal        = 0;
input string TelegramToken     = "8788116899:AAFNkT-qvCW1yUGWz4fwYZkFfl8MJXoavaI"; // Token del Bot
input long   TelegramChatID    = 1021469094; // Tu Chat ID
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
//  GESTIÓN DE RIESGO
//============================================================
input group "=== GESTION DE RIESGO ==="
input double LoteInicial            = 0.01;
input double MaxRiesgoPorTrade_USD  = 3.0;
input double ATR_Multiplicador_SL   = 1.5;
input double ATR_Multiplicador_TP   = 3.0;

input group "=== LICENCIA & WEB BRIDGE ==="
input string Token_Web              = "";   // Token de sincronización web
input string purchaseID_Synced      = "";   // ID de compra para sync
input bool   SilentTelegram         = true; // Silenciar errores de Telegram

input group "=== STOP ESTRUCTURAL ==="
input int    Velas_Estructural      = 10;   // 10 velas de M15 (Como pidió el usuario)
input double Margen_Extra_USD       = 5.0;  // Margen de seguridad ajustado ($5)

//============================================================
//  PROTECCION DE CUENTA (ANTI-RACHA)
//============================================================
input group "=== PROTECCION DE CUENTA (ANTI-RACHA) ==="
input double MaxPerdidaDiaria_USD = 50.0;
input double MaxDrawdown_USD      = 10.0;     // 🛑 Stop de Emergencia ($). 0 = Off.
input int    MaxOperacionesDia    = 50;

//============================================================
//  ESTRATEGIA ALINEACION DE TENDENCIA
//============================================================
input group "=== ESTRATEGIA ALINEACION DE TENDENCIA ==="
input int    EMA_Tendencia  = 200;
input int    EMA_Rapida     = 21;
input int    EMA_Lenta      = 55;
input int    RSI_Periodo    = 14;
input int    RSI_Compra_Min = 35;
input int    RSI_Compra_Max = 60;
input int    RSI_Venta_Min  = 28;
input int    RSI_Venta_Max  = 50;
input int    ATR_Periodo    = 14;
input double ATR_Minimo_USD = 1.0;

//============================================================
//  FILTRO DE NOTICIAS DE ALTO IMPACTO
//============================================================
input group "=== FILTRO DE NOTICIAS DE ALTO IMPACTO ==="
input bool   FiltroNoticias       = true;
input int    MinutosAntes         = 30;
input int    MinutosDespues       = 30;
input bool   CerrarEnPositivo     = true;

//============================================================
//  BREAK EVEN
//============================================================
input group "=== BREAK EVEN ==="
input bool   ActivarBE        = true;
input double BE_Activar_USD   = 2.0;
input double BE_Garantia_USD  = 1.5;

//============================================================
//  TRAILING STOP
//============================================================
input group "=== TRAILING STOP ==="
input int    Puntos_Minimos_Trailing  = 100;
input bool   ActivarTrailing          = true;
input double Trailing_Activar_USD     = 2.0;
input double Trailing_Distancia_USD   = 2.0;

//============================================================
//  SMART HEDGE (RESCATE)
//============================================================
input group "=== SMART HEDGE (RESCATE) ==="
input bool   ActivarHedge           = true;     // 🚑 Activar protección Hedge
input double HedgeTrigger_USD       = 3.0;      // $ Perdida para activar Hedge
input double HedgeTP_USD            = 2.0;      // $ TP para la operación Hedge
input double HedgeLoteMult          = 1.5;      // Multiplicador de lote para el Hedge

//============================================================
//  CONFIGURACION AVANZADA
//============================================================
input group "=== CONFIGURACION AVANZADA ==="
input int    MaxPosiciones   = 2;
input int    MinutosEspera   = 20;
input bool   MostrarPanel    = true;
input long   InpMagicNumber  = 0;  // 0 = Auto Smart Magic

//--- Variables internas ---
CTrade   trade;
long     MagicNumber;
bool     licenseValid = false;
string   licenseMsg   = "";
int      hEmaTend, hEmaRap, hEmaLent, hRSI, hATR;
datetime ultimaVela = 0;
datetime ultimaEntrada = 0;
int      diaActual = -1;
int      opsHoy = 0;
double   lossHoy = 0;
int      ModoBot = 0;
bool     StrucSL = true;
bool     Minimized = false;
bool     remotePaused = false;
long     lastUpdateID = 0;
datetime lastWebSync = 0;
int      lastPosCount = 0;
datetime cooldownUntil = 0;
bool     hedgeActive = false;
ulong    hedgeTicket = 0;

#define PNL "BSR64_E_"

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
   
   // SEGURIDAD: Evitar error [invalid stops] respetando el StopLevel del broker
   double stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   double price = (t == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   if(t == POSITION_TYPE_BUY) {
      if(price - res < stopLevel + (5 * _Point)) res = price - stopLevel - (10 * _Point);
   } else {
      if(res - price < stopLevel + (5 * _Point)) res = price + stopLevel + (10 * _Point);
   }
   
   return NormalizeDouble(res, _Digits);
}

//--- INICIALIZACIÓN ---
int OnInit() {
   hEmaTend = iMA(_Symbol, _Period, EMA_Tendencia, 0, MODE_EMA, PRICE_CLOSE);
   hEmaRap  = iMA(_Symbol, _Period, EMA_Rapida,    0, MODE_EMA, PRICE_CLOSE);
   hEmaLent = iMA(_Symbol, _Period, EMA_Lenta,     0, MODE_EMA, PRICE_CLOSE);
   hRSI     = iRSI(_Symbol, _Period, RSI_Periodo,  PRICE_CLOSE);
   hATR     = iATR(_Symbol, _Period, ATR_Periodo);
   
   if(InpMagicNumber == 0) MagicNumber = (int)GetHash(_Symbol + IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN)));
   else MagicNumber = InpMagicNumber;
   
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetTypeFillingBySymbol(_Symbol);
   
   licenseValid = true;
   licenseMsg = "TRIAL DIA 1/30";
   
   if(MostrarPanel) CrearPanel();
   return INIT_SUCCEEDED;
}

void OnDeinit(const int r) { ObjectsDeleteAll(0, PNL); }

void OnTick() {
   if(!licenseValid) return;
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   if(dt.day_of_year != diaActual) { diaActual = dt.day_of_year; opsHoy = 0; lossHoy = 0; }
   
   // DETECTAR CIERRE Y ACTIVAR COOLDOWN
   int currentPos = ContarPos();
   if(currentPos < lastPosCount) {
      cooldownUntil = TimeCurrent() + (MinutosEspera * 60);
      SendTelegramMessage("ℹ️ BTC: Cierre detectado. Cooldown activado.");
   }
   lastPosCount = currentPos;

   // EMERGENCIA
   if(MaxDrawdown_USD > 0 && GetCurrentNetProfit() <= -MaxDrawdown_USD) {
      CloseAllBotPositions();
      remotePaused = true;
      SendTelegramMessage("🛑 BTC EMERGENCY: Drawdown superó $" + DoubleToString(MaxDrawdown_USD, 2));
   }

   if(remotePaused) {
      ObjectSetString(0, PNL+"stV", OBJPROP_TEXT, "PAUSADO REMOTO");
      ObjectSetInteger(0, PNL+"stV", OBJPROP_COLOR, CLR_WARN);
      ProcessTelegramCommands();
      return;
   }

   // AUTO-GESTIÓN DE LA POSICIÓN
   if(StrucSL) {
      for(int i=PositionsTotal()-1; i>=0; i--) {
         ulong t = PositionGetTicket(i);
         if(PositionSelectByTicket(t) && PositionGetInteger(POSITION_MAGIC)==MagicNumber && PositionGetString(POSITION_SYMBOL)==_Symbol) {
            double nSL = GetStructuralSL((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE));
            double cSL = PositionGetDouble(POSITION_SL);
            ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            bool mejor = (type == POSITION_TYPE_BUY) ? (cSL == 0 || nSL > cSL) : (cSL == 0 || nSL < cSL);
            if(mejor && MathAbs(nSL - cSL) > (1.0 * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE))) {
               trade.PositionModify(t, nSL, PositionGetDouble(POSITION_TP));
            }
         }
      }
   }

   if(MostrarPanel) ActualizarPanel();
   ManageBETrailing();
   if(ActivarHedge) ManageHedge();
   CheckEntradas();
   ProcessTelegramCommands();
   SyncWithWeb();
}

void SyncWithWeb() {
   if(purchaseID_Synced == "" || TimeCurrent() < lastWebSync + 30) return;
   lastWebSync = TimeCurrent();
   
   string account = IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN));
   string url = "https://www.kopytrading.com/api/remote-control?purchaseId=" + purchaseID_Synced + "&account=" + account;
   char post[], result[]; string headers;
   int res = WebRequest("GET", url, headers, 2000, post, result, headers);
   
   if(res == 200) {
      string response = CharArrayToString(result);
      if(StringFind(response, "\"command\":\"PAUSE\"") != -1) {
         remotePaused = true;
         SendTelegramMessage("🛑 BTC: Pausado remotamente desde el Panel Web.");
      }
      if(StringFind(response, "\"command\":\"RESUME\"") != -1) {
         remotePaused = false;
         SendTelegramMessage("✅ BTC: Reanudado remotamente desde el Panel Web.");
      }
      if(StringFind(response, "\"command\":\"CLOSE_ALL\"") != -1) {
         CloseAllBotPositions();
         SendTelegramMessage("🔥 BTC: Cierre de Emergencia activado desde la Web.");
      }
      if(StringFind(response, "\"command\":\"DIRECTION\"") != -1) {
         if(StringFind(response, "\"value\":\"BUY\"") != -1) ModoBot = 1;
         else if(StringFind(response, "\"value\":\"SELL\"") != -1) ModoBot = 2;
         else ModoBot = 0;
         SendTelegramMessage("↕️ BTC: Dirección de trading cambiada remotamente.");
      }
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
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)     continue;

      double profit      = PositionGetDouble(POSITION_PROFIT);
      double openPrice   = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL   = PositionGetDouble(POSITION_SL);
      double currentTP   = PositionGetDouble(POSITION_TP);
      long   type        = PositionGetInteger(POSITION_TYPE);
      double lot         = PositionGetDouble(POSITION_VOLUME);
      double bid         = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask         = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double stopLevel   = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);

      double newSL = 0;
      bool modificado = false;

      if(ActivarBE && profit >= BE_Activar_USD) {
         if(type == POSITION_TYPE_BUY) {
            newSL = NormalizeDouble(openPrice + USDtoPrice(BE_Garantia_USD, lot), _Digits);
            if(newSL > currentSL && newSL <= (bid - stopLevel)) { if(trade.PositionModify(ticket, newSL, currentTP)) modificado = true; }
         } else if(type == POSITION_TYPE_SELL) {
            newSL = NormalizeDouble(openPrice - USDtoPrice(BE_Garantia_USD, lot), _Digits);
            if((currentSL == 0 || newSL < currentSL) && newSL >= (ask + stopLevel)) { if(trade.PositionModify(ticket, newSL, currentTP)) modificado = true; }
         }
      }

      if(ActivarTrailing && !modificado && profit >= Trailing_Activar_USD) {
         if(type == POSITION_TYPE_BUY) {
            newSL = NormalizeDouble(bid - USDtoPrice(Trailing_Distancia_USD, lot), _Digits);
            if(newSL > currentSL && newSL > openPrice && newSL <= (bid - stopLevel)) trade.PositionModify(ticket, newSL, currentTP);
         } else if(type == POSITION_TYPE_SELL) {
            newSL = NormalizeDouble(ask + USDtoPrice(Trailing_Distancia_USD, lot), _Digits);
            if((currentSL == 0 || newSL < currentSL) && newSL < openPrice && newSL >= (ask + stopLevel)) trade.PositionModify(ticket, newSL, currentTP);
         }
      }
   }
}

void ManageHedge() {
   double netProfit = GetCurrentNetProfit();
   int mainPos = ContarPos();
   
   // Verificar si el hedge sigue vivo
   if(hedgeTicket > 0) {
      if(!PositionSelectByTicket(hedgeTicket)) {
         hedgeTicket = 0;
         hedgeActive = false;
         SendTelegramMessage("🏁 BTC: Operación Hedge cerrada.");
      } else {
         // Gestionar TP del Hedge
         double pPos = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         if(pPos >= HedgeTP_USD) trade.PositionClose(hedgeTicket);
         
         // Si las posiciones principales se cerraron/recuperaron, cerrar hedge
         if(mainPos == 0 || netProfit >= -1.0) trade.PositionClose(hedgeTicket);
         return;
      }
   }

   // Activar Hedge si hay perdida suficiente
   if(!hedgeActive && mainPos > 0 && netProfit <= -HedgeTrigger_USD) {
      ENUM_POSITION_TYPE mainType = GetDominantSide();
      ENUM_POSITION_TYPE hedgeType = (mainType == POSITION_TYPE_BUY) ? POSITION_TYPE_SELL : POSITION_TYPE_BUY;
      
      double lot = LoteInicial * HedgeLoteMult;
      double price = (hedgeType == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
      
      bool res = false;
      if(hedgeType == POSITION_TYPE_BUY) res = trade.Buy(NormalizeLot(lot), _Symbol, price, 0, 0, "BSR66_HEDGE");
      else res = trade.Sell(NormalizeLot(lot), _Symbol, price, 0, 0, "BSR66_HEDGE");

      if(res) {
         hedgeTicket = trade.ResultOrder();
         hedgeActive = true;
         SendTelegramMessage("🚑 BTC: SMART HEDGE ACTIVADO ($" + DoubleToString(netProfit, 2) + ")");
      }
   }
}

ENUM_POSITION_TYPE GetDominantSide() {
   int buys=0, sells=0;
   for(int i=0; i<PositionsTotal(); i++) {
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC)==MagicNumber) {
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) buys++;
         else sells++;
      }
   }
   return (buys >= sells) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
}

double NormalizeLot(double l) {
   double min = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double res = MathFloor(l/step)*step;
   return (res < min) ? min : res;
}

void CheckEntradas() {
   if(TimeCurrent() < cooldownUntil) return;
   datetime v = iTime(_Symbol, _Period, 0); if(v == ultimaVela) return;
   double r[1], l[1]; CopyBuffer(hEmaRap,0,0,1,r); CopyBuffer(hEmaLent,0,0,1,l);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID); double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   bool bS = (r[0] > l[0]) && (bid > r[0]) && (ModoBot != 2);
   bool sS = (r[0] < l[0]) && (bid < r[0]) && (ModoBot != 1);
   if(bS && ContarPos() < MaxPosiciones) {
      double sl = StrucSL ? GetStructuralSL(POSITION_TYPE_BUY) : 0;
      trade.Buy(LoteInicial, _Symbol, ask, sl, 0, "BSR63_B"); ultimaVela = v; opsHoy++;
   }
   if(sS && ContarPos() < MaxPosiciones) {
      double sl = StrucSL ? GetStructuralSL(POSITION_TYPE_SELL) : 0;
      trade.Sell(LoteInicial, _Symbol, bid, sl, 0, "BSR63_S"); ultimaVela = v; opsHoy++;
   }
}

int ContarPos() {
   int c=0;
   for(int i=0; i<PositionsTotal(); i++) {
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL)==_Symbol) {
         if(PositionGetInteger(POSITION_MAGIC)==MagicNumber || StringFind(PositionGetString(POSITION_COMMENT),"BSR63")!=-1) c++;
      }
   }
   return c;
}

//--- TELEGRAM BRIDGE ---
void ProcessTelegramCommands() {
   if(TelegramToken == "" || TelegramChatID == 0) return;
   string url = "https://api.telegram.org/bot" + TelegramToken + "/getUpdates?offset=" + IntegerToString(lastUpdateID + 1);
   char post[], result[]; string headers;
   int res = WebRequest("GET", url, headers, 1000, post, result, headers);
   if(res == 200) {
      string response = CharArrayToString(result);
      if(StringFind(response, "\"/start\"") != -1) { SendTelegramMessage("👋 Kopytrading BTC Rider listo."); lastUpdateID = ParseUpdateID(response); }
      if(StringFind(response, "\"/status\"") != -1) { SendTelegramStatus(); lastUpdateID = ParseUpdateID(response); }
      if(StringFind(response, "\"/closeall\"") != -1) { CloseAllBotPositions(); SendTelegramMessage("🏁 BTC: TODAS LAS POSICIONES CERRADAS"); lastUpdateID = ParseUpdateID(response); }
      if(StringFind(response, "\"/pause\"") != -1) { remotePaused = true; SendTelegramMessage("🔴 BTC: PAUSA REMOTA ACTIVADA"); lastUpdateID = ParseUpdateID(response); }
      if(StringFind(response, "\"/resume\"") != -1) { remotePaused = false; SendTelegramMessage("🟢 BTC: BOT REANUDADO"); lastUpdateID = ParseUpdateID(response); }
   }
}

void SendTelegramStatus() {
   double pVal = GetCurrentNetProfit();
   string msg = "📊 ESTADO BTC STORM RIDER\n" +
                "--------------------------\n" +
                "💰 Beneficio Actual: $" + DoubleToString(pVal, 2) + "\n" +
                "💼 Posiciones: " + IntegerToString(ContarPos()) + "\n" +
                "🤖 Estado: " + (remotePaused ? "PAUSADO" : "OPERATIVO");
   SendTelegramMessage(msg);
}

bool SendTelegramMessage(string msg) {
   if(TelegramToken == "" || TelegramChatID <= 0) return false;
   string url = "https://api.telegram.org/bot" + TelegramToken + "/sendMessage";
   string payload = "chat_id=" + IntegerToString(TelegramChatID) + "&text=" + msg + "\n\n🌐 kopytrading.com";
   char post[], result[]; string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
   StringToCharArray(payload, post, 0, WHOLE_ARRAY, CP_UTF8);
   int res = WebRequest("POST", url, headers, 2000, post, result, headers);
   if(res != 200) {
      if(!SilentTelegram) {
         string response = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
         Print("TELEGRAM ERROR: ", res, " | Respuesta: ", response);
      }
      return false;
   }
   return true;
}

long ParseUpdateID(string json) {
   int pos = StringFind(json, "\"update_id\":"); if(pos == -1) return lastUpdateID;
   string sub = StringSubstr(json, pos + 12); int end = StringFind(sub, ",");
   return (long)StringToInteger(StringSubstr(sub, 0, end));
}

void CloseAllBotPositions() {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong t = PositionGetTicket(i);
      if(PositionSelectByTicket(t) && PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol)
         trade.PositionClose(t);
   }
}

double GetCurrentNetProfit() {
   double p = 0;
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber || StringFind(PositionGetString(POSITION_COMMENT),"BSR63")!=-1)
            p += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      }
   }
   return p;
}

double GetDailyProfit() {
   HistorySelect(iTime(_Symbol, PERIOD_D1, 0), TimeCurrent());
   double p = 0;
   for(int i=HistoryDealsTotal()-1; i>=0; i--) {
      ulong t = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(t, DEAL_MAGIC) == MagicNumber && HistoryDealGetString(t, DEAL_SYMBOL) == _Symbol) 
         p += HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_COMMISSION) + HistoryDealGetDouble(t, DEAL_SWAP);
   }
   return p;
}

//--- PANEL VISUAL ---
void CrearPanel() {
   ObjectsDeleteAll(0, PNL); 
   int x=15, y=15, w=295, h=450; 
   if(Minimized) { w=220; h=65; }
   
   CrRect("bg", x, y, w, h, CLR_BG, CLR_BRD, 2);
   CrRect("hdr", x+2, y+2, w-4, 40, CLR_HDR, CLR_HDR);
   CrLabel("ttl", x+15, y+8, "KOPYTRADING BTC RIDER v6.6", clrWhite, 11, "Arial Bold");
   CrLabel("sub", x+15, y+25, "kopytrading.com", CLR_MUTED, 7);
   CrBtn("min", x+w-25, y+8, 18, 18, Minimized?"+":"-", CLR_HDR, clrWhite);
   
   if(!Minimized) {
      CrRect("lic-b", x+5, y+50, w-10, 22, C'25,25,50', CLR_BRD);
      CrLabel("licV", x+15, y+53, "LIC:  " + licenseMsg, CLR_WARN, 8, "Arial Bold");
      CrLabel("ctaV", x+160, y+53, "CTA: " + IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN)), CLR_MUTED, 8);
      
      CrLabel("mH", x+12, y+80, "MERCADO", CLR_MUTED, 7);
      CrLabel("rsL", x+15, y+95, "RSI:", CLR_MUTED, 8); CrLabel("rsV", x+50, y+95, "00.0", CLR_TXT, 9);
      CrLabel("atL", x+110, y+95, "ATR $:", CLR_MUTED, 8); CrLabel("atV", x+170, y+95, "$0.00", CLR_SUCCESS, 9);
      CrLabel("tmV", x+235, y+95, GetTimeLeft(), CLR_WARN, 9, "Consolas");
      CrLabel("tnL", x+15, y+118, "Tendencia:", CLR_MUTED, 8); CrLabel("tnV", x+110, y+118, "ALCISTA", CLR_SUCCESS, 9);
      CrLabel("seL", x+15, y+138, "Sesión:", CLR_MUTED, 8); CrLabel("seV", x+110, y+138, "ACTIVA", CLR_SUCCESS, 9);
      
      CrLabel("hH", x+12, y+175, "HOY", CLR_MUTED, 7);
      CrLabel("pL", x+15, y+190, "PnL HOY:", CLR_MUTED, 8); CrLabel("pV", x+120, y+190, "$0.00", CLR_TXT, 10, "Arial Bold");
      CrLabel("opL", x+15, y+215, "Operaciones:", CLR_MUTED, 8); CrLabel("opV", x+120, y+215, "0/50", CLR_TXT, 9);
      CrLabel("psL", x+200, y+215, "Pos:", CLR_MUTED, 8); CrLabel("psV", x+250, y+215, "0/2", CLR_TXT, 9);
      CrLabel("lsL", x+15, y+235, "FLOTANTE:", CLR_MUTED, 8); CrLabel("lsV", x+120, y+235, "$0.00", CLR_DANGER, 9);
      CrLabel("baL", x+15, y+255, "Balance:", CLR_MUTED, 8); CrLabel("baV", x+120, y+255, "$0.00", CLR_TXT, 9);
      
      CrLabel("moH", x+12, y+265, "MODO DE OPERACIÓN", CLR_MUTED, 7);
      CrBtn("b_sell", x+10, y+285, 90, 25, "SOLO SELL", ModoBot==2?C'180,40,40':C'35,35,65', clrWhite);
      CrBtn("b_both", x+102, y+285, 90, 25, "BUY & SELL", ModoBot==0?CLR_ACCENT:C'35,35,65', clrWhite);
      CrBtn("b_buy", x+194, y+285, 90, 25, "SOLO BUY", ModoBot==1?C'30,140,60':C'35,35,65', clrWhite);
      
      CrLabel("slL", x+15, y+330, "STOP ESTRUCTURAL:", CLR_MUTED, 8);
      CrBtn("b_sl", x+165, y+325, 60, 25, StrucSL?"ON":"OFF", StrucSL?CLR_ACCENT:C'35,35,65', clrWhite);
      
      CrLabel("rem", x+100, y+370, "REMOTO: " + (remotePaused?"🔴 PAUSA":"🟢 ONLINE"), (remotePaused?CLR_DANGER:CLR_SUCCESS), 8);
      CrLabel("hdg", x+15, y+395, "SMART HEDGE: " + (hedgeActive?"🚑 ACTIVO":"💤 ESPERA"), (hedgeActive?CLR_SUCCESS:CLR_MUTED), 8);

      CrRect("stBg", x+2, h-40+y, w-4, 30, C'15,15,40', CLR_BRD);
      CrLabel("stL", x+15, h-32+y, "ESTADO:", CLR_MUTED, 8); CrLabel("stV", x+85, h-32+y, "OPERATIVO", CLR_SUCCESS, 10, "Arial Bold");
   } else {
      CrLabel("tmM", x+15, y+45, "VELA: " + GetTimeLeft(), CLR_WARN, 9);
      CrLabel("baM", x+120, y+45, "BAL: $" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),0), clrWhite, 8);
   }
   ChartRedraw(0);
}

void ActualizarPanel() {
   if(Minimized) ObjectSetString(0, PNL+"tmM", OBJPROP_TEXT, "VELA: " + GetTimeLeft());
   else {
      ObjectSetString(0, PNL+"tmV", OBJPROP_TEXT, GetTimeLeft());
      double r[1], a[1], r2[1], l2[1]; CopyBuffer(hRSI,0,0,1,r); CopyBuffer(hATR,0,0,1,a);
      CopyBuffer(hEmaRap,0,0,1,r2); CopyBuffer(hEmaLent,0,0,1,l2);
      ObjectSetString(0, PNL+"rsV", OBJPROP_TEXT, DoubleToString(r[0], 1));
      double ppv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double pps = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double atrUSD = (a[0]/pps) * ppv * LoteInicial;
      ObjectSetString(0, PNL+"atV", OBJPROP_TEXT, "$"+DoubleToString(atrUSD, 2));
      bool up = (r2[0] > l2[0]);
      ObjectSetString(0, PNL+"tnV", OBJPROP_TEXT, up?"ALCISTA":"BAJISTA");
      ObjectSetInteger(0, PNL+"tnV", OBJPROP_COLOR, up?CLR_SUCCESS:CLR_DANGER);
      
      double pdaily = GetDailyProfit();
      ObjectSetString(0, PNL+"pV", OBJPROP_TEXT, "$"+DoubleToString(pdaily, 2));
      ObjectSetInteger(0, PNL+"pV", OBJPROP_COLOR, pdaily>=0?CLR_SUCCESS:CLR_DANGER);
      
      ObjectSetString(0, PNL+"opV",  OBJPROP_TEXT, IntegerToString(opsHoy)+"/50");
      ObjectSetString(0, PNL+"psV",  OBJPROP_TEXT, IntegerToString(ContarPos())+"/2");
      ObjectSetString(0, PNL+"baV",  OBJPROP_TEXT, "$"+DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2));
      ObjectSetString(0, PNL+"lsV",  OBJPROP_TEXT, "$"+DoubleToString(GetCurrentNetProfit(), 2));
      ObjectSetInteger(0, PNL+"lsV", OBJPROP_COLOR, GetCurrentNetProfit()>=0?CLR_SUCCESS:CLR_DANGER);
      ObjectSetString(0, PNL+"rem",  OBJPROP_TEXT, "REMOTO: " + (remotePaused?"🔴 PAUSA":"🟢 ONLINE"));
      ObjectSetInteger(0, PNL+"rem", OBJPROP_COLOR, (remotePaused?CLR_DANGER:CLR_SUCCESS));
      
      // Asegurar que el estado vuelva a OPERATIVO si no hay pausa
      ObjectSetString(0, PNL+"stV", OBJPROP_TEXT, "OPERATIVO");
      ObjectSetInteger(0, PNL+"stV", OBJPROP_COLOR, CLR_SUCCESS);
   }
   ChartRedraw(0);
}

void OnChartEvent(const int id, const long &lp, const double &dp, const string &sp) {
   if(id!=CHARTEVENT_OBJECT_CLICK) return;
   if(sp==PNL+"min") { Minimized=!Minimized; CrearPanel(); }
   if(sp==PNL+"b_both") { ModoBot=0; CrearPanel(); }
   if(sp==PNL+"b_buy")  { ModoBot=1; CrearPanel(); }
   if(sp==PNL+"b_sell") { ModoBot=2; CrearPanel(); }
   if(sp==PNL+"b_sl")   { StrucSL=!StrucSL; CrearPanel(); }
   if(sp==PNL+"b_test") { 
      if(SendTelegramMessage("🔔 Prueba de conexión BTC Rider OK."))
         Alert("¡Mensaje enviado correctamente! Mira tu móvil.");
   }
   ObjectSetInteger(0, sp, OBJPROP_STATE, false);
}

void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bw=1) {
   ObjectCreate(0,PNL+n,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,bd);
   ObjectSetInteger(0,PNL+n,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,PNL+n,OBJPROP_BACK,false); 
}
void CrLabel(string n, int x, int y, string t, color c, int s, string f) {
   ObjectCreate(0,PNL+n,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y);
   ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,c);
   ObjectSetInteger(0,PNL+n,OBJPROP_FONTSIZE,s); ObjectSetString(0,PNL+n,OBJPROP_FONT,f);
}
void CrBtn(string n, int x, int y, int w, int h, string t, color bg, color tc) {
   ObjectCreate(0,PNL+n,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h);
   ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,tc);
}

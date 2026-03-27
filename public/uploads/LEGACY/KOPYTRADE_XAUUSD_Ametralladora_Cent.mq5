//+------------------------------------------------------------------+
//|          KOPYTRADE_XAUUSD_Ametralladora_Cent                     |
//|   EDICIÓN ESPECIAL CUENTA CENT | RIESGO $1 | STOP $5             |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrade Corp."
#property link      "https://www.kopytrade.com"
//--- GENERADOR DE HASH PARA MAGIC NUMBER AUTOMATICO ---
uint GetHash(string text) {
   uint hash = 5381;
   for(int i = 0; i < StringLen(text); i++) hash = ((hash << 5) + hash) + text[i];
   return hash & 0x7FFFFFFF; // Asegurar que sea positivo
}
#property version   "5.55"
#property strict
#property description "Ametralladora Cent | Pre-configurado para Cuentas Cent kopytrade.com"

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/SymbolInfo.mqh>

//--- DECLARACIONES DE FUNCIONES VISUALES ---
void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bw=1);
void CrLabel(string n, int x, int y, string t, color c, int s=9, string f="Segoe UI");
void CrBtn(string n, int x, int y, int w, int h, string t, color bg, color tc);

//============================================================
//  LICENCIA & TELEGRAM
//============================================================
input group "=== LICENCIA & MOBILE BRIDGE ==="
input string   LicenseKey        = "TRIAL-2026";
input string   PurchaseID        = "";         // ID de Vínculo (Ver en kopytrading.com/dashboard)
input string   TelegramToken     = "";         // Token del Bot (ej: 123456:ABC...)
input long     TelegramChatID    = 0;          // Tu Chat ID (ej: 987654321)
input bool     NotificarTelegram = true;       // Enviar alertas al móvil

//============================================================
//  GESTIÓN DE RIESGO
//============================================================
input group "=== GESTION DE RIESGO ==="
input double   RiskPercent        = 0.0;       // % de Riesgo (0 = Lote Manual)
input int      MagicNumber        = 202509;    // Magic Number
input double   LoteManual         = 0.01;      // Lote Inicial
input double   MaxDrawdown_USD    = 500.0;     // 🛑 Stop de Emergencia Cuenta (500 unid.).
input double   Max_DD_Individual  = 100.0;     // 🛑 Stop por Operación (100 unid.).
input int      Max_Velas_Vida     = 3;         // ⏳ Vida máxima en velas por operación.

//--- VARIABLES GLOBALES ---
int activeMagic;
datetime lastRemoteSync = 0;

//============================================================
//  RESCATE MATEMÁTICO (ULTRA)
//============================================================
input group "=== RESCATE MATEMÁTICO (ULTRA) ==="
input bool     ActivarRescate     = true;      // 🚑 Activar Operación de Rescate
input double   MultiplicadorLote  = 2.0;       // Multiplicador base Martingala
input double   DistanciaRescate   = 50.0;      // $ Perdida para activar gatillo (50 unid.)
input int      DelayRescateSegs   = 120;       // Segundos de espera para rescatar (2 min)

//============================================================
//  METAS & CORTAFUEGOS
//============================================================
input group "=== METAS & CORTAFUEGOS ==="
input double   MetaDiaria_USD      = 500.0;     // 🎯 Ganancia Diaria (500 unid.).
input double   Meta_Ciclo_USD      = 100.0;     // Neto para cerrar ciclo (100 unid.)
input double   Harvest_TP_USD      = 50.0;      // TP individual (50 unid.)

//============================================================
//  BREAK EVEN & TRAILING
//============================================================
input group "=== BREAK EVEN & TRAILING ==="
input bool     ActivarBE           = true;      // 🛡️ Activar Break Even
input double   BE_Trigger_USD      = 30.0;      // Activar BE tras (30 unidades)
input bool     ActivarTrailing     = true;      // 🚀 Activar Trailing Stop
input int      TrailingPoints      = 150;       // Puntos de Trailing (15 pips)
input int      TrailingStep        = 50;        // Paso de Trailing (5 pips)

//============================================================
//  ESTRATEGIA & FILTROS
//============================================================
input group "=== ESTRATEGIA (MOMENTUM) ==="
input int      MomentumCandles     = 3;        
input int      MomentumRequired    = 2;        
input int      CooldownSeconds     = 60;       
input bool     EnableTimeFilter    = true;     // ⏰ Activar filtro de horario
input int      StartHour1          = 9;        
input int      EndHour1            = 14;       
input int      StartHour2          = 17;       
input int      EndHour2            = 21;       

//--- Variables internas ---
CTrade         trade;
CPositionInfo  posInfo;
int            atrHandle;
datetime       lastTradeTime = 0;
datetime       coolingEndTime = 0;
long           lastUpdateID = 0;

enum ENUM_DIR  { DIR_COMPRAS, DIR_VENTAS, DIR_AMBAS };
enum ENUM_MODE { MODE_ZEN, MODE_COSECHA };

ENUM_DIR       currentDir = DIR_AMBAS;
ENUM_MODE      currentMode = MODE_COSECHA;
string         botStatus = "LISTO";
bool           isMinimized = false;
bool           remotePaused = false; 
bool           startNotified = false;
int            startRetries = 0;
datetime       lastPositionsSync = 0;
double         mode_HarvestTP = 50.0;
double         mode_CycleMeta = 100.0;
double         mode_BETrigger = 50.0;

#define PNL "AEVO_C_"

//--- COLORES PREMIUM ---
color CLR_BG      = C'10,10,25';
color CLR_HDR     = C'30,20,60';
color CLR_BRD     = C'70,50,140';
color CLR_TXT     = clrWhite;
color CLR_MUTED   = C'130,130,170';
color CLR_SUCCESS = C'40,200,90';
color CLR_DANGER  = C'210,50,50';
color CLR_WARN    = C'210,170,40';
color CLR_ACCENT  = C'40,70,190';

//--- INICIALIZACIÓN ---
int OnInit() {
   activeMagic = MagicNumber;
   if(activeMagic == 0) activeMagic = (int)GetHash(_Symbol + IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN)));
   trade.SetExpertMagicNumber(activeMagic);
   
   atrHandle = iATR(_Symbol, _Period, 14);
   if(atrHandle == INVALID_HANDLE) return(INIT_FAILED);
   
   startNotified = false;
   startRetries = 0;
   if(NotificarTelegram && TelegramToken != "") Print("TELEGRAM: Iniciando bot Cent...");
   CrearPanel(); 
   UpdateModeParams();
   EventSetTimer(3); 
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) { ObjectsDeleteAll(0, PNL); }

void OnTick() {
   if(NotificarTelegram && TelegramToken != "" && !startNotified && startRetries < 3) {
      if(SendTelegramMessage("🚀 KOPYTRADING EVOLUTION CENT Iniciada.\n\n/status - Ver PnL\n/pause - Apagar\n/resume - Reanudar"))
         startNotified = true;
      else
         startRetries++;
   }
   double dailyProfit = GetDailyProfit();
   double currentNet = GetCurrentNetProfit();
   
   if(remotePaused) { botStatus = "🔴 PAUSA REMOTA"; DeleteBotPendings(); ActualizarPanel(); return; }
   
   // --- LÓGICA DE META DIARIA INTELIGENTE ---
   bool goalReached = (MetaDiaria_USD > 0 && dailyProfit >= MetaDiaria_USD);
   
   if(goalReached) {
      if(PositionsTotalBots() == 0) {
         botStatus = "META ALCANZADA";
         DeleteBotPendings();
         ActualizarPanel();
         return;
      }
      
      if(currentNet >= 0) {
         CloseAllBotPositions();
         DeleteBotPendings();
         SendTelegramMessage("🎯 META CENT FINALIZADA ($" + DoubleToString((dailyProfit + currentNet)/100.0, 2) + " reales). Todo cerrado.");
         botStatus = "META ALCANZADA";
         ActualizarPanel();
         return;
      } else {
         botStatus = "META (LIMPIANDO)"; 
      }
   }

   ManageOpenPositions();
   if(!goalReached) MaintainGates(); 
   else DeleteBotPendings(); 

   if(!IsTradingTime() || TimeCurrent() < coolingEndTime) {
      botStatus = (TimeCurrent() < coolingEndTime) ? "ENFRIANDO" : "FUERA DE HORARIO";
      ActualizarPanel(); return;
   }
   ActualizarPanel();
   SyncPositions();
   NotifyDeals();
}

void NotifyDeals() {
   HistorySelect(TimeCurrent()-60, TimeCurrent());
   for(int i=HistoryDealsTotal()-1; i>=0; i--) {
      ulong t = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(t, DEAL_MAGIC) == activeMagic && HistoryDealGetInteger(t, DEAL_TIME) > TimeCurrent()-10) {
         double p = HistoryDealGetDouble(t, DEAL_PROFIT);
         if(p != 0) SendTelegramMessage("💰 Operación Cent Cerrada: " + (p>0?"✅ ":"❌ ") + DoubleToString(p, 0) + " USC");
         else SendTelegramMessage("🏁 Operación Cent Abierta (" + HistoryDealGetString(t, DEAL_SYMBOL) + ")");
      }
   }
}

void OnTimer() { 
   if(TelegramToken != "") ProcessTelegramCommands(); 
   
   if(PurchaseID != "" && TimeCurrent() - lastRemoteSync >= 30) {
      CheckRemoteCommands();
      lastRemoteSync = TimeCurrent();
   }
}

void CheckRemoteCommands() {
   string account = IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN));
   string url = "https://kopytrading.com/api/remote-control?purchaseId=" + PurchaseID + "&account=" + account;
   char post[], result[]; string headers;
   int res = WebRequest("GET", url, headers, 2000, post, result, headers);
   if(res == 200) {
      string response = CharArrayToString(result);
      if(StringFind(response, "\"command\":\"PAUSE\"") != -1) { remotePaused = true; SendTelegramMessage("🛑 Comando Remoto: PAUSAR BOT"); CrearPanel(); }
      if(StringFind(response, "\"command\":\"RESUME\"") != -1) { remotePaused = false; SendTelegramMessage("🟢 Comando Remoto: REANUDAR BOT"); CrearPanel(); }
      if(StringFind(response, "\"command\":\"CLOSE_ALL\"") != -1) { CloseAllBotPositions(); SendTelegramMessage("🔥 Comando Remoto: CIERRE EMERGENCIA"); }
      if(StringFind(response, "\"command\":\"CHANGE_MODE\"") != -1) {
          if(StringFind(response, "\"value\":\"ZEN\"") != -1) { currentMode = MODE_ZEN; UpdateModeParams(); }
          else if(StringFind(response, "\"value\":\"COSECHA\"") != -1) { currentMode = MODE_COSECHA; UpdateModeParams(); }
          CrearPanel();
      }
      if(StringFind(response, "\"command\":\"DIRECTION\"") != -1) {
          if(StringFind(response, "\"value\":\"BUY\"") != -1) currentDir = DIR_COMPRAS;
          else if(StringFind(response, "\"value\":\"SELL\"") != -1) currentDir = DIR_VENTAS;
          else currentDir = DIR_AMBAS;
          CrearPanel();
      }
   }
}

void MaintainGates() {
   if(remotePaused) { DeleteBotPendings(); return; }
   int botPosCount = PositionsTotalBots();
   ENUM_POSITION_TYPE mainType = GetMainPositionType();
   double netProfit = GetCurrentNetProfit();

   if(botPosCount > 0) {
      if(botPosCount >= 2) { DeleteBotPendings(); return; }
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(ask <= 0 || bid <= 0) return; 

      ulong t_ref = GetPendingTicketByComment("REFUERZO");
      double distRef = 250 * _Point;
      double targetRef = (mainType == POSITION_TYPE_BUY) ? ask + distRef : bid - distRef;
      
      if(GetCurrentNetProfit() > 50.0) { // Profit > 50 cents
         if(t_ref == 0) {
            double lot = CalculateInitialLot();
            if(mainType == POSITION_TYPE_BUY) trade.BuyStop(lot, targetRef, _Symbol, 0, 0, 0, 0, "REFUERZO");
            else trade.SellStop(lot, targetRef, _Symbol, 0, 0, 0, 0, "REFUERZO");
         } else {
            if(OrderSelect(t_ref)) {
               double op = OrderGetDouble(ORDER_PRICE_OPEN);
               if(MathAbs(targetRef - op) > 100 * _Point) trade.OrderModify(t_ref, targetRef, 0, 0, ORDER_TIME_GTC, 0, 0);
            }
         }
      } else { if(t_ref != 0) trade.OrderDelete(t_ref); }

      ulong t_res = GetPendingTicketByComment("RESCATE_P");
      double distRes = 200 * _Point;
      double targetRes = (mainType == POSITION_TYPE_BUY) ? bid - distRes : ask + distRes;

      if(t_res == 0) {
         double resLot = CalculateRecoveryLot(MathAbs(netProfit > 0 ? 0 : netProfit));
         if(mainType == POSITION_TYPE_BUY) trade.SellStop(resLot, targetRes, _Symbol, 0, 0, 0, 0, "RESCATE_P");
         else trade.BuyStop(resLot, targetRes, _Symbol, 0, 0, 0, 0, "RESCATE_P");
      } else {
         if(OrderSelect(t_res)) {
            double op = OrderGetDouble(ORDER_PRICE_OPEN);
            double netP = GetCurrentNetProfit();
            
            // --- DIFERENCIA CLAVE: Solo "corremos" si estamos en zona segura ---
            // Si la pérdida es mayor que DistanciaRescate, anclamos la orden.
            if(netP > -DistanciaRescate) {
               if(MathAbs(targetRes - op) > 50 * _Point) trade.OrderModify(t_res, targetRes, 0, 0, ORDER_TIME_GTC, 0, 0);
            } else {
               // Ya estamos en zona de riesgo, dejamos la orden quieta para que sea ejecutada
               Print("RESCATE: Precio en zona activa. Manteniendo orden anclada.");
            }
         }
      }
   }

   if(botPosCount == 0) {
      int c_up=0, c_dn=0;
      for(int i=1; i<=MomentumCandles; i++) {
         double o = iOpen(_Symbol, _Period, i);
         double c = iClose(_Symbol, _Period, i);
         if(c > o) c_up++; if(c < o) c_dn++;
      }
      if(c_up < MomentumRequired && c_dn < MomentumRequired) { DeleteBotPendings(); return; }
      int p_buys = CountPendings(ORDER_TYPE_BUY_STOP);
      int p_sells = CountPendings(ORDER_TYPE_SELL_STOP);
      double dist = 250 * _Point;
      double lot = CalculateInitialLot();
      if((currentDir == DIR_COMPRAS || currentDir == DIR_AMBAS) && p_buys == 0)
         trade.BuyStop(lot, SymbolInfoDouble(_Symbol, SYMBOL_ASK) + dist, _Symbol, 0, 0, 0, 0, "G_BUY");
      if((currentDir == DIR_VENTAS || currentDir == DIR_AMBAS) && p_sells == 0)
         trade.SellStop(lot, SymbolInfoDouble(_Symbol, SYMBOL_BID) - dist, _Symbol, 0, 0, 0, 0, "G_SELL");
   }
}

ulong GetPendingTicketByComment(string cmnt) {
   for(int i=0; i<OrdersTotal(); i++) {
      ulong t = OrderGetTicket(i);
      if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC)==activeMagic && OrderGetString(ORDER_COMMENT)==cmnt) return t;
   }
   return 0;
}

void ManageOpenPositions() {
    double netProfit = GetCurrentNetProfit();
    int botPosCount = 0;
    for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) botPosCount++;

    if(MaxDrawdown_USD > 0 && netProfit <= -MaxDrawdown_USD) {
       CloseAllBotPositions();
       botStatus = "🛑 STOP EMERGENCIA";
       SendTelegramMessage("⚠️ STOP EMERGENCIA CENT ACTIVADO. Perdida: $" + DoubleToString(netProfit/100.0, 2) + " reales.\nEl bot se ha detenido.");
       remotePaused = true; return;
    }

    if(botPosCount >= 2 && netProfit >= mode_CycleMeta) {
       CloseAllBotPositions();
       coolingEndTime = TimeCurrent() + CooldownSeconds;
       SendTelegramMessage("✅ Ciclo Cent Cerrado: " + DoubleToString(netProfit, 0) + " USC");
       return;
    }
    
    for(int i=PositionsTotal()-1; i>=0; i--) {
       if(posInfo.SelectByIndex(i) && posInfo.Magic() == activeMagic) {
          double p = posInfo.Profit() + posInfo.Commission() + posInfo.Swap();
          datetime openTime = (datetime)posInfo.Time();
          int candlesPassed = iBarShift(_Symbol, _Period, openTime);

          if(p <= -Max_DD_Individual) {
             trade.PositionClose(posInfo.Ticket());
             SendTelegramMessage("⚠️ Cierre Seguridad: Operación alcanzó -" + DoubleToString(Max_DD_Individual, 0) + " USC");
             coolingEndTime = TimeCurrent() + 300; continue;
          }
          if(Max_Velas_Vida > 0 && candlesPassed >= Max_Velas_Vida) {
             trade.PositionClose(posInfo.Ticket());
             SendTelegramMessage("⏳ Cierre Tiempo: " + IntegerToString(candlesPassed) + " velas.");
             continue;
          }
          // --- LOGICA DE HARVEST (TP INDIVIDUAL) ---
          if(p >= mode_HarvestTP) { trade.PositionClose(posInfo.Ticket()); continue; }

          // --- LOGICA DE BREAK EVEN (PROTEGER) ---
          if(ActivarBE && p >= BE_Trigger_USD) {
             double open = posInfo.PriceOpen();
             double stop = posInfo.StopLoss();
             double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
             double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
             
             // --- DISTANCIA MINIMA DEL BROKER ---
             double stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
             double safePoints = 5 * _Point; // 0.5 pips extra safety
             
             if(posInfo.PositionType() == POSITION_TYPE_BUY) {
                double newBE = open + (2 * _Point);
                // Si el precio actual está muy cerca del open, esperamos o ajustamos al mínimo del broker
                if(bid - newBE < stopLevel + safePoints) newBE = bid - (stopLevel + safePoints);
                
                if(stop < newBE || stop == 0) {
                   if(bid - newBE > stopLevel) trade.PositionModify(posInfo.Ticket(), NormalizeDouble(newBE, _Digits), posInfo.TakeProfit());
                }
                
                // --- TRAILING STOP ---
                if(ActivarTrailing && bid - newBE > TrailingPoints * _Point) {
                   double tsSL = bid - TrailingPoints * _Point;
                   if(tsSL > stop + TrailingStep * _Point || stop == 0) trade.PositionModify(posInfo.Ticket(), NormalizeDouble(tsSL, _Digits), posInfo.TakeProfit());
                }
             }
             else if(posInfo.PositionType() == POSITION_TYPE_SELL) {
                double newBE = open - (2 * _Point);
                if(newBE - ask < stopLevel + safePoints) newBE = ask + (stopLevel + safePoints);
                
                if(stop > newBE || stop == 0) {
                   if(newBE - ask > stopLevel) trade.PositionModify(posInfo.Ticket(), NormalizeDouble(newBE, _Digits), posInfo.TakeProfit());
                }
                
                // --- TRAILING STOP ---
                if(ActivarTrailing && newBE - ask > TrailingPoints * _Point) {
                   double tsSL = ask + TrailingPoints * _Point;
                   if(tsSL < stop - TrailingStep * _Point || stop == 0) trade.PositionModify(posInfo.Ticket(), NormalizeDouble(tsSL, _Digits), posInfo.TakeProfit());
                }
             }
          }
       }
    }
}

double GetCurrentNetProfit() {
   double p = 0;
   for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic() == activeMagic) p += posInfo.Profit() + posInfo.Commission() + posInfo.Swap();
   return p;
}

ENUM_POSITION_TYPE GetMainPositionType() {
   for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic() == activeMagic) return (ENUM_POSITION_TYPE)posInfo.PositionType();
   return POSITION_TYPE_BUY;
}

void ProcessTelegramCommands() {
   string url = "https://api.telegram.org/bot" + TelegramToken + "/getUpdates?offset=" + IntegerToString(lastUpdateID + 1);
   char post[], result[]; string headers;
   int res = WebRequest("GET", url, headers, 1000, post, result, headers);
   if(res == 200) {
      string response = CharArrayToString(result);
      if(StringFind(response, "\"/start\"") != -1) { SendTelegramMessage("👋 ¡Hola! Soy tu bot de Kopytrading Cent."); lastUpdateID = ParseUpdateID(response); }
      if(StringFind(response, "\"/status\"") != -1) { SendTelegramStatus(); lastUpdateID = ParseUpdateID(response); }
      if(StringFind(response, "\"/closeall\"") != -1) { CloseAllBotPositions(); SendTelegramMessage("🏁 POSICIONES CENT CERRADAS"); lastUpdateID = ParseUpdateID(response); }
      if(StringFind(response, "\"/pause\"") != -1) { remotePaused = true; SendTelegramMessage("🔴 PAUSA REMOTA ACTIVADA"); lastUpdateID = ParseUpdateID(response); }
      if(StringFind(response, "\"/resume\"") != -1) { remotePaused = false; SendTelegramMessage("🟢 BOT REANUDADO"); lastUpdateID = ParseUpdateID(response); }
   }
}

long ParseUpdateID(string json) {
   int pos = StringFind(json, "\"update_id\":"); if(pos == -1) return lastUpdateID;
   string sub = StringSubstr(json, pos + 12); int end = StringFind(sub, ",");
   return (long)StringToInteger(StringSubstr(sub, 0, end));
}

bool SendTelegramMessage(string msg) {
   string token = TelegramToken;
   StringTrimLeft(token); StringTrimRight(token);
   if(token == "" || TelegramChatID <= 0) return false;
   string url = "https://api.telegram.org/bot" + token + "/sendMessage";
   string payload = "chat_id=" + IntegerToString(TelegramChatID) + "&text=" + msg + "\n\n🌐 kopytrading.com";
   char post[], result[]; string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
   StringToCharArray(payload, post, 0, WHOLE_ARRAY, CP_UTF8);
   int res = WebRequest("POST", url, headers, 2000, post, result, headers);
   if(res != 200) return false;
   return true;
}

void SendTelegramStatus() {
   string msg = "🔫 EVOLUTION CENT\n";
   msg += "PnL Hoy: " + DoubleToString(GetDailyProfit(), 0) + " USC\n";
   msg += "Status: " + botStatus;
   SendTelegramMessage(msg);
}

double CalculateInitialLot() { return LoteManual; }
double CalculateRecoveryLot(double loss) { 
   double factorATR = GetATR();
   if(factorATR <= 0) factorATR = 2.0; // Fallback seguro para Oro
   
   // --- REFINAMIENTO MATEMÁTICO ---
   // Calculamos el lote para recuperar la pérdida + meta de ciclo mínima (15 unidades)
   // Pero limitamos el lote máximo para que el Stop Loss de $2 no sea demasiado sensible.
   double targetRecovery = loss + 15.0; 
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   
   double rawLot = targetRecovery / (factorATR * (tickValue / tickSize));
   double finalLot = NormalizeLot(rawLot);
   
   // --- CAP DE SEGURIDAD (MÁXIMO 0.05) ---
   if(finalLot > 0.05) {
      Print("RESCATE: Lote calculado (" + DoubleToString(finalLot, 2) + ") excedía el CAP. Limitando a 0.05");
      finalLot = 0.05;
   }
   
   if(finalLot < 0.02) finalLot = 0.02; // Mínimo de rescate para que tenga impacto
   
   Print("RESCATE CALC: Loss=" + DoubleToString(loss, 1) + " | ATR=" + DoubleToString(factorATR, 2) + " | Lote Final=" + DoubleToString(finalLot, 2));
   return finalLot;
}
double NormalizeLot(double l) {
   double min = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double res = MathFloor(l/step)*step;
   return (res < min) ? min : res;
}
double GetATR() { double b[]; return (CopyBuffer(atrHandle, 0, 0, 1, b) > 0) ? b[0] : 0; }

double GetDailyProfit() {
   HistorySelect(iTime(_Symbol, PERIOD_D1, 0), TimeCurrent());
   double p = 0;
   for(int i=HistoryDealsTotal()-1; i>=0; i--) {
      ulong t = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(t, DEAL_MAGIC) == activeMagic) p += HistoryDealGetDouble(t, DEAL_PROFIT);
   }
   return p;
}

int CountPendings(ENUM_ORDER_TYPE type) {
   int c=0; for(int i=0; i<OrdersTotal(); i++) if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC)==activeMagic && OrderGetInteger(ORDER_TYPE)==type) c++;
   return c;
}

int PositionsTotalBots() {
   int c=0; for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) c++;
   return c;
}

void CloseAllBotPositions() { for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) trade.PositionClose(posInfo.Ticket()); }
void DeleteBotPendings() { for(int i=OrdersTotal()-1; i>=0; i--) if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC)==activeMagic) trade.OrderDelete(OrderGetTicket(i)); }

bool IsTradingTime() {
   if(!EnableTimeFilter) return true;
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   int m = dt.hour * 60 + dt.min;
   return ((m >= StartHour1*60 && m < EndHour1*60) || (m >= StartHour2*60 && m < EndHour2*60));
}

void UpdateModeParams() {
   if(currentMode == MODE_ZEN) { mode_HarvestTP = 20.0; mode_CycleMeta = 50.0; mode_BETrigger = 20.0; }
   else { mode_HarvestTP = Harvest_TP_USD; mode_CycleMeta = Meta_Ciclo_USD; mode_BETrigger = BE_Trigger_USD; }
}

void CrearPanel() {
   ObjectsDeleteAll(0, PNL);
   int x=15, y=15, w=295, h=380;
   if(isMinimized) { w=220; h=65; }
   CrRect("bg", x, y, w, h, CLR_BG, CLR_BRD, 2);
   CrRect("hdr", x+2, y+2, w-4, 40, CLR_HDR, CLR_HDR);
   CrLabel("ttl", x+15, y+8, "EVOLUTION v5.55", clrWhite, 11, "Arial Bold");
   CrLabel("sub", x+15, y+25, "kopytrading.com", CLR_MUTED, 7);
   CrBtn("min", x+w-25, y+8, 18, 18, isMinimized?"+":"-", CLR_HDR, clrWhite);
   
   if(!isMinimized) {
      CrLabel("licV", x+15, y+60, "LICENCIA: " + LicenseKey, CLR_WARN, 8, "Arial Bold");
      CrLabel("pL", x+15, y+90, "PnL USC:", CLR_MUTED, 8); CrLabel("pV", x+110, y+90, "0", CLR_TXT, 10, "Arial Bold");
      CrLabel("stL", x+15, y+115, "ESTADO:", CLR_MUTED, 8); CrLabel("stV", x+110, y+115, botStatus, CLR_SUCCESS, 9);
      CrLabel("moH", x+12, y+150, "MODOS & DIRECCIÓN", CLR_MUTED, 7);
      CrBtn("b_zen", x+10, y+170, 90, 25, "MODO ZEN", currentMode==MODE_ZEN?CLR_ACCENT:C'35,35,65', clrWhite);
      CrBtn("b_har", x+105, y+170, 90, 25, "COSECHA", currentMode==MODE_COSECHA?C'200,80,40':C'35,35,65', clrWhite);
      CrBtn("b_buy", x+10, y+205, 90, 25, "SOLO BUY", currentDir==DIR_COMPRAS?CLR_ACCENT:C'35,35,65', clrWhite);
      CrBtn("b_both", x+105, y+205, 90, 25, "AMBAS", currentDir==DIR_AMBAS?CLR_ACCENT:C'35,35,65', clrWhite);
      CrBtn("b_sell", x+200, y+205, 85, 25, "SOLO SELL", currentDir==DIR_VENTAS?C'180,40,40':C'35,35,65', clrWhite);
      CrBtn("b_close", x+10, y+245, 185, 30, "CLOSE ALL POSITIONS", CLR_DANGER, clrWhite);
      CrBtn("b_test", x+205, y+245, 80, 30, "TEST BOT", C'50,50,80', clrWhite);
      CrLabel("rem", x+15, y+300, "REMOTO: " + (remotePaused?"🔴 PAUSA":"🟢 ONLINE"), (remotePaused?CLR_DANGER:CLR_SUCCESS), 8);
   }
   ChartRedraw(0);
}

void ActualizarPanel() {
   if(!isMinimized) {
      double p = GetDailyProfit();
      ObjectSetString(0, PNL+"pV", OBJPROP_TEXT, DoubleToString(p, 0) + " USC");
      ObjectSetInteger(0, PNL+"pV", OBJPROP_COLOR, p>=0?CLR_SUCCESS:CLR_DANGER);
      ObjectSetString(0, PNL+"stV", OBJPROP_TEXT, botStatus);
      ObjectSetInteger(0, PNL+"stV", OBJPROP_COLOR, botStatus=="LISTO"?CLR_SUCCESS:CLR_WARN);
   }
   ChartRedraw(0);
}

void OnChartEvent(const int id, const long &lp, const double &dp, const string &sp) {
   if(id!=CHARTEVENT_OBJECT_CLICK) return;
   if(sp==PNL+"min") { isMinimized=!isMinimized; CrearPanel(); }
   if(sp==PNL+"b_zen") { currentMode=MODE_ZEN; UpdateModeParams(); CrearPanel(); }
   if(sp==PNL+"b_har") { currentMode=MODE_COSECHA; UpdateModeParams(); CrearPanel(); }
   if(sp==PNL+"b_buy") { currentDir=DIR_COMPRAS; CrearPanel(); }
   if(sp==PNL+"b_sell") { currentDir=DIR_VENTAS; CrearPanel(); }
   if(sp==PNL+"b_both") { currentDir=DIR_AMBAS; CrearPanel(); }
   if(sp==PNL+"b_close") { CloseAllBotPositions(); }
   if(sp==PNL+"b_test") { if(SendTelegramMessage("🔔 Prueba conexión HUD Cent OK.")) Alert("¡Mensaje enviado!"); }
   ObjectSetInteger(0, sp, OBJPROP_STATE, false);
}

void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bw=1) {
   ObjectCreate(0,PNL+n,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,bd);
   ObjectSetInteger(0,PNL+n,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,PNL+n,OBJPROP_BACK,false); 
   ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,100);
}
void CrLabel(string n, int x, int y, string t, color c, int s, string f="Segoe UI") {
   ObjectCreate(0,PNL+n,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y);
   ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,c);
   ObjectSetInteger(0,PNL+n,OBJPROP_FONTSIZE,s); ObjectSetString(0,PNL+n,OBJPROP_FONT,f);
   ObjectSetInteger(0,PNL+n,OBJPROP_BACK,false);
   ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,101);
}
void CrBtn(string n, int x, int y, int w, int h, string t, color bg, color tc) {
   ObjectCreate(0,PNL+n,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h);
   ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,tc);
   ObjectSetInteger(0,PNL+n,OBJPROP_BACK,false);
   ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,102);
}
void SyncPositions() {
    if(PurchaseID == "" || TimeCurrent() < lastPositionsSync + 30) return;
    lastPositionsSync = TimeCurrent();
    string account = IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN));
    string positionsJson = "";
    int count = 0;
    for(int i=0; i<PositionsTotal(); i++) {
        if(posInfo.SelectByIndex(i) && posInfo.Magic() == activeMagic) {
            if(count > 0) positionsJson += ",";
            positionsJson += "{\"ticket\":\"" + IntegerToString((long)posInfo.Ticket()) + "\"," +
                             "\"type\":\"" + (posInfo.PositionType()==POSITION_TYPE_BUY?"BUY":"SELL") + "\"," +
                             "\"symbol\":\"" + posInfo.Symbol() + "\"," +
                             "\"lots\":" + DoubleToString(posInfo.Volume(), 2) + "," +
                             "\"openPrice\":" + DoubleToString(posInfo.PriceOpen(), _Digits) + "," +
                             "\"sl\":" + DoubleToString(posInfo.StopLoss(), _Digits) + "," +
                             "\"tp\":" + DoubleToString(posInfo.TakeProfit(), _Digits) + "," +
                             "\"profit\":" + DoubleToString(posInfo.Profit() + posInfo.Commission() + posInfo.Swap(), 2) + "}";
            count++;
        }
    }
    string postData = "{\"purchaseId\":\"" + PurchaseID + "\",\"account\":\"" + account + "\",\"positions\":[" + positionsJson + "]}";
    char post[], result[]; string headers = "Content-Type: application/json\r\n";
    StringToCharArray(postData, post, 0, WHOLE_ARRAY, CP_UTF8);
    WebRequest("POST", "https://kopytrading.com/api/sync-positions", headers, 2000, post, result, headers);
}

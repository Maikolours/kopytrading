//+------------------------------------------------------------------+
//|          KOPYTRADE_XAUUSD_Ametralladora_Ultra_Cent                   |
//|   EDICIÓN ESPECIAL "ULTRA" - ENCADENAMIENTO Y LÍMITES AJUSTABLES        |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrade Corp."
#property link      "https://www.kopytrade.com"
//--- GENERADOR DE HASH PARA MAGIC NUMBER AUTOMATICO ---
uint GetHash(string text) {
   uint hash = 5381;
   for(int i = 0; i < StringLen(text); i++) hash = ((hash << 5) + hash) + text[i];
   return hash & 0x7FFFFFFF; // Asegurar que sea positivo
}
#property version   "5.84"
#property strict
#property description "Evolution Pro | Pre-configurado para Cuentas USD/Cent kopytrading.com"

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/SymbolInfo.mqh>

//--- DECLARACIONES DE FUNCIONES VISUALES ---
void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bw=1);
void CrLabel(string n, int x, int y, string t, color c, int s=9, string f="Segoe UI");
void CrBtn(string n, int x, int y, int w, int h, string t, color bg, color tc);

enum ENUM_DIR  { DIR_COMPRAS, DIR_VENTAS, DIR_AMBAS };
enum ENUM_MODE { MODE_ZEN, MODE_COSECHA };

ENUM_DIR       currentDir = DIR_AMBAS;
ENUM_MODE      currentMode = MODE_COSECHA;
bool           isCentAccount = true; 

//============================================================
//  LICENCIA & SEGURIDAD
//============================================================
input group "=== LICENCIA & SEGURIDAD ==="
input string   LicenseKey        = "TRIAL-2026";
input string   PurchaseID        = "";         // ID de Vínculo (Ver en kopytrading.com/dashboard)

//============================================================
//  GESTIÓN DE RIESGO
//============================================================
input group "=== FILTRO DE NOTICIAS USD ==="
input bool     FiltroNoticias       = true; // Activar pausa por noticias?
input int      MinutosAntes         = 30;   // Minutos antes de noticia
input int      MinutosDespues       = 30;   // Minutos despues de noticia

input group "=== CONFIGURACIÓN INTERNA ==="
input ENUM_MODE ModePreset        = MODE_COSECHA; // 🎨 Modo del Bot (Zen/Cosecha)
input bool     UseManualSettings  = false;        // 🛠️ Ignorar Preset y usar ajustes manuales
input double   RiskPercent        = 0.0;          // % de Riesgo (0 = Lote Manual)
input int      MagicNumber        = 202509;       // Magic Number
input double   LoteManual         = 0.01;         // Lote Inicial Manual
input double   MaxDrawdown_USD    = 500.0;        // 🛑 Stop de Emergencia Cuenta (500 unid.).
input double   Max_DD_Individual  = 100.0;        // 🛑 Stop por Operación (100 unid.).
input int      Max_Velas_Vida     = 3;            // ⏳ Vida máxima en velas por operación.
input int      MaxPosiciones      = 2;            // 📈 Máximo de posiciones abiertas (Bot)

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
input double   MaxLoteRescate     = 0.05;      // 🛡️ Lote máximo permitido en rescate
input double   MinLoteRescate     = 0.02;      // 🚑 Lote mínimo para rescatar

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
input int      EntradaPoints       = 500;      // 📥 Distancia de entrada (GATES) en puntos (500 = $5).
input int      DistanciaRefuerzo   = 350;      // 📥 Distancia para orden de REFUERZO (3.5 pips).
input int      DistanciaRescatePoints = 250;   // 📥 Distancia para orden de RESCATE (2.5 pips).
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

// --- VARIABLES EFECTIVAS (SHADOW) ---
double         eff_Lots = 0.01;
double         eff_HarvestTP = 50.0;
double         eff_CycleMeta = 100.0;
double         eff_BETrigger = 30.0;
double         eff_DailyTarget = 500.0;
string         eff_ModeType = "AUTO (COSECHA)";

// --- OVERRIDES REMOTOS ---
double         rem_Lots = 0;
double         rem_HarvestTP = 0;
double         rem_CycleMeta = 0;
double         rem_BETrigger = 0;
double         rem_DailyTarget = 0;

string         botStatus = "LISTO";
bool           isMinimized = false;
bool           remotePaused = false;
bool           noticiaActiva = false;
bool           startNotified = false;
int            startRetries = 0;
bool           loginPrinted = false;
datetime       lastPositionsSync = 0;
double         mode_HarvestTP = 50.0;
double         mode_CycleMeta = 100.0;
double         mode_BETrigger = 50.0;
int            mode_MaxPos    = 2;
int            mode_Entrada   = 500;

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
   if(activeMagic == 0) activeMagic = (int)GetHash(_Symbol + IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN)));
   trade.SetExpertMagicNumber(activeMagic);
   
   string currency = AccountInfoString(ACCOUNT_CURRENCY);
   isCentAccount = (StringFind(currency, "USC") != -1 || SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) < 0.001);

   atrHandle = iATR(_Symbol, _Period, 14);
   if(atrHandle == INVALID_HANDLE) return(INIT_FAILED);
   
   // --- AUTO-INDICATOR VISUALIZATION ---
   ChartIndicatorAdd(0, 1, atrHandle); 
   
   startNotified = true; // No Telegram, avoid checking
   startRetries = 0;
   CrearPanel(); 
   UpdateModeParams();
   SyncPositions();
   EventSetTimer(3); 
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) { ObjectsDeleteAll(0, PNL); }

bool HayNoticia() {
   if(!FiltroNoticias) return false;
   MqlCalendarValue vals[];
   datetime start = TimeCurrent() - MinutosDespues*60;
   datetime end   = TimeCurrent() + MinutosAntes*60;
   if(CalendarValueHistory(vals, start, end, "USD") > 0) {
      for(int i=0; i<ArraySize(vals); i++) {
         MqlCalendarEvent ev;
         if(CalendarEventById(vals[i].event_id, ev) && ev.importance == CALENDAR_IMPORTANCE_HIGH) return true;
      }
   }
   return false;
}

void OnTick() {
    double dailyProfit = GetDailyProfit();
    double currentNet = GetCurrentNetProfit();
    
    if(remotePaused) { botStatus = "🔴 PAUSA REMOTA"; DeleteBotPendings(); ActualizarPanel(); return; }
    
    // --- LÓGICA DE META DIARIA INTELIGENTE ---
    bool goalReached = (eff_DailyTarget > 0 && dailyProfit >= eff_DailyTarget);
   
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
         botStatus = "META ALCANZADA";
         ActualizarPanel();
         return;
      } else {
         botStatus = "META (LIMPIANDO)"; 
      }
   }

   noticiaActiva = HayNoticia();
   if(noticiaActiva || !IsTradingTime() || TimeCurrent() < coolingEndTime) {
      if(noticiaActiva) botStatus = "ALERTA NOTICIA";
      else botStatus = (TimeCurrent() < coolingEndTime) ? "ENFRIANDO" : "FUERA DE HORARIO";
      
      ManageOpenPositions(); // Keep managing existing ones
      DeleteBotPendings();  // No new pending orders
      ActualizarPanel(); 
      SyncPositions();
      return;
   }

   ManageOpenPositions();
   if(!goalReached) MaintainGates(); 
   else DeleteBotPendings(); 

   ActualizarPanel();
   SyncPositions();
}

void OnTimer() { 
   if(PurchaseID != "" && TimeCurrent() - lastRemoteSync >= 30) {
      CheckRemoteCommands();
      SyncPositions();
      lastRemoteSync = TimeCurrent();
   }
}

void CheckRemoteCommands() {
   string account = IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN));
   string url = "https://www.kopytrading.com/api/remote-control?purchaseId=" + PurchaseID + "&account=" + account;
   char post[], result[]; string headers;
   int res = WebRequest("GET", url, headers, 2000, post, result, headers);
   if(res == 200) {
      string response = CharArrayToString(result);
      if(!loginPrinted) { Print("LICENSE: Validacion exitosa Oro Pro."); loginPrinted = true; }
      
      if(StringFind(response, "\"command\":\"PAUSE\"") != -1) { remotePaused = true; CrearPanel(); }
      if(StringFind(response, "\"command\":\"RESUME\"") != -1) { remotePaused = false; CrearPanel(); }
      if(StringFind(response, "\"command\":\"CLOSE_ALL\"") != -1) { CloseAllBotPositions(); }
      
      // --- COMANDOS PRO ---
      if(StringFind(response, "\"command\":\"SET_LOTS\"") != -1) { rem_Lots = ExtractValue(response); UpdateModeParams(); }
      if(StringFind(response, "\"command\":\"SET_META\"") != -1) { rem_DailyTarget = ExtractValue(response); UpdateModeParams(); }
      if(StringFind(response, "\"command\":\"SET_TIMEFRAME\"") != -1) { SetRemoteTimeframe(ExtractString(response)); }
      
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

double ExtractValue(string json) {
   int pos = StringFind(json, "\"value\":\"");
   if(pos == -1) return 0;
   string sub = StringSubstr(json, pos + 9);
   int end = StringFind(sub, "\"");
   return StringToDouble(StringSubstr(sub, 0, end));
}

string ExtractString(string json) {
   int pos = StringFind(json, "\"value\":\"");
   if(pos == -1) return "";
   string sub = StringSubstr(json, pos + 9);
   int end = StringFind(sub, "\"");
   return StringSubstr(sub, 0, end);
}

void SetRemoteTimeframe(string tf) {
   ENUM_TIMEFRAMES period = _Period;
   if(tf == "M1")  period = PERIOD_M1;
   if(tf == "M5")  period = PERIOD_M5;
   if(tf == "M15") period = PERIOD_M15;
   if(tf == "M30") period = PERIOD_M30;
   if(tf == "H1")  period = PERIOD_H1;
   
   if(period != _Period) {
      ChartSetSymbolPeriod(0, _Symbol, period);
   }
}

void MaintainGates() {
   if(remotePaused) { DeleteBotPendings(); return; }
   int botPosCount = PositionsTotalBots();
   ENUM_POSITION_TYPE mainType = GetMainPositionType();
   double netProfit = GetCurrentNetProfit();

   if(botPosCount > 0) {
      if(botPosCount >= mode_MaxPos) { DeleteBotPendings(); return; }
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(ask <= 0 || bid <= 0) return; 

      ulong t_ref = GetPendingTicketByComment("REFUERZO");
      double distRef = DistanciaRefuerzo * _Point;
      double targetRef = (mainType == POSITION_TYPE_BUY) ? ask + distRef : bid - distRef;
      
      if(GetCurrentNetProfit() > 50.0) { // Profit > 50 cents
         if(t_ref == 0) {
            double lot = CalculateInitialLot();
            if(mainType == POSITION_TYPE_BUY) trade.BuyStop(lot, targetRef, _Symbol, 0, 0, 0, 0, "REFUERZO");
            else trade.SellStop(lot, targetRef, _Symbol, 0, 0, 0, 0, "REFUERZO");
         } else {
             if(OrderSelect(t_ref)) {
                double op = OrderGetDouble(ORDER_PRICE_OPEN);
                
                double stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
                double freezeLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) * _Point;
                double distLimit = MathMax(stopLevel, freezeLevel) + (20 * _Point);
                
                bool canMod = (mainType == POSITION_TYPE_BUY) ? (targetRef - ask > distLimit) : (bid - targetRef > distLimit);

                if(canMod && MathAbs(targetRef - op) > 100 * _Point) {
                   trade.OrderModify(t_ref, NormalizeDouble(targetRef, _Digits), 0, 0, ORDER_TIME_GTC, 0, 0);
                }
             }
         }
      } else { if(t_ref != 0) trade.OrderDelete(t_ref); }

      ulong t_res = GetPendingTicketByComment("RESCATE_P");
      double distRes = DistanciaRescatePoints * _Point;
      double targetRes = (mainType == POSITION_TYPE_BUY) ? bid - distRes : ask + distRes;

      if(netProfit < -10.0) { // Solo rescatar si estamos en pérdida significativa
         if(t_res == 0) {
            double resLot = CalculateRecoveryLot(MathAbs(netProfit > 0 ? 0 : netProfit));
            if(mainType == POSITION_TYPE_BUY) trade.SellStop(resLot, targetRes, _Symbol, 0, 0, 0, 0, "RESCATE_P");
            else trade.BuyStop(resLot, targetRes, _Symbol, 0, 0, 0, 0, "RESCATE_P");
         } else {
            if(OrderSelect(t_res)) {
               double op = OrderGetDouble(ORDER_PRICE_OPEN);
               double netP = GetCurrentNetProfit();
               
               if(netP > -DistanciaRescate) {
                  double freezeLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) * _Point;
                  double stopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
                  double distLimit = MathMax(freezeLevel, stopLevel) + (20 * _Point);
                  
                  bool canModify = (mainType == POSITION_TYPE_BUY) ? (bid - targetRes > distLimit) : (targetRes - ask > distLimit);

                  if(canModify && MathAbs(targetRes - op) > 100 * _Point) {
                     trade.OrderModify(t_res, NormalizeDouble(targetRes, _Digits), 0, 0, ORDER_TIME_GTC, 0, 0);
                  }
               }
            }
         }
      } else {
         if(t_res != 0) trade.OrderDelete(t_res); // El mercado se dio la vuelta, dejamos de meter rescate
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
      double dist = mode_Entrada * _Point;
      double lot = eff_Lots;
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
        remotePaused = true; return;
     }

    if(botPosCount >= 2 && netProfit >= eff_CycleMeta) {
       CloseAllBotPositions();
       coolingEndTime = TimeCurrent() + CooldownSeconds;
       return;
    }
    
    for(int i=PositionsTotal()-1; i>=0; i--) {
       if(posInfo.SelectByIndex(i) && posInfo.Magic() == activeMagic) {
          double p = posInfo.Profit() + posInfo.Commission() + posInfo.Swap();
          datetime openTime = (datetime)posInfo.Time();
          int candlesPassed = iBarShift(_Symbol, _Period, openTime);

          if(p <= -Max_DD_Individual) {
             trade.PositionClose(posInfo.Ticket());
             coolingEndTime = TimeCurrent() + 300; continue;
          }
          if(Max_Velas_Vida > 0 && candlesPassed >= Max_Velas_Vida) {
             trade.PositionClose(posInfo.Ticket());
             continue;
          }
          // --- LOGICA DE HARVEST (TP INDIVIDUAL) ---
          if(p >= eff_HarvestTP) { 
             trade.PositionClose(posInfo.Ticket()); 
             if(posInfo.Comment() == "RESCATE_P") coolingEndTime = 0; // CHAINING: Bypas cooldown if rescue TP
             continue; 
          }

          // --- LOGICA DE BREAK EVEN (PROTEGER) ---
          if(ActivarBE && p >= eff_BETrigger) {
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
   
   // --- CAP DE SEGURIDAD AJUSTABLE ---
   if(finalLot > MaxLoteRescate) {
      Print("RESCATE ULTRA: Lote calculado (" + DoubleToString(finalLot, 2) + ") excedía el CAP ("+DoubleToString(MaxLoteRescate,2)+"). Limitando.");
      finalLot = MaxLoteRescate;
   }
   
   if(finalLot < MinLoteRescate) finalLot = MinLoteRescate; 
   
   Print("RESCATE ULTRA CALC: Loss=" + DoubleToString(loss, 1) + " | ATR=" + DoubleToString(factorATR, 2) + " | Lote Final=" + DoubleToString(finalLot, 2));
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
   // 1. Base del Modo (Preset) - DIFERENCIACIÓN REAL ZEN vs COSECHA
   if(currentMode == MODE_ZEN) { 
      eff_HarvestTP = 20.0; eff_CycleMeta = 50.0; eff_BETrigger = 20.0; 
      mode_MaxPos = 1; 
      mode_Entrada = 1000; // ZEN: Entrada a $10 de distancia
      eff_ModeType = "AUTO (ZEN - CALM)";
   }
   else { 
      eff_HarvestTP = Harvest_TP_USD; eff_CycleMeta = Meta_Ciclo_USD; eff_BETrigger = BE_Trigger_USD; 
      mode_MaxPos = MaxPosiciones;
      mode_Entrada = EntradaPoints; // COSECHA: Entrada según input (500 por defecto)
      eff_ModeType = "AUTO (COSECHA - ACT)";
   }
   
   // 2. Overrides Manuales (Inputs)
   if(UseManualSettings) {
      eff_Lots = LoteManual;
      eff_ModeType = "MANUAL (INPUTS)";
   } else {
      eff_Lots = 0.01; // Lote base Cent
   }

   // 3. Overrides Remotos (Web) - Prioridad Máxima
   if(rem_Lots > 0) { eff_Lots = rem_Lots; eff_ModeType = "REMOTO (WEB)"; }
   if(rem_HarvestTP > 0) eff_HarvestTP = rem_HarvestTP;
   if(rem_CycleMeta > 0) eff_CycleMeta = rem_CycleMeta;
   if(rem_BETrigger > 0) eff_BETrigger = rem_BETrigger;
   if(rem_DailyTarget > 0) eff_DailyTarget = rem_DailyTarget;
   else eff_DailyTarget = MetaDiaria_USD;
}

void CrearPanel() {
   ObjectsDeleteAll(0, PNL);
   int x=15, y=15, w=295, h=380;
   if(isMinimized) { w=220; h=65; }
   CrRect("bg", x, y, w, h, CLR_BG, CLR_BRD, 2);
   CrRect("hdr", x+2, y+2, w-4, 40, CLR_HDR, CLR_HDR);
   CrLabel("ttl", x+15, y+8, "EVOLUTION ULTRA", clrWhite, 11, "Arial Bold");
   CrLabel("sub", x+15, y+25, "kopytrading.com", CLR_MUTED, 7);
   CrBtn("min", x+w-25, y+8, 18, 18, isMinimized?"+":"-", CLR_HDR, clrWhite);
   
   if(!isMinimized) {
      CrLabel("licV", x+15, y+55, "LICENCIA: " + LicenseKey, CLR_WARN, 8, "Arial Bold");
      CrLabel("pL", x+15, y+80, "PnL HOY:", CLR_MUTED, 8); CrLabel("pV", x+110, y+80, "0", CLR_TXT, 10, "Arial Bold");
      CrLabel("stL", x+15, y+105, "ESTADO:", CLR_MUTED, 8); CrLabel("stV", x+110, y+105, botStatus, CLR_SUCCESS, 9);
      
      CrLabel("trL", x+15, y+130, "MODO EFECT.:", CLR_MUTED, 8); CrLabel("trV", x+110, y+130, eff_ModeType, CLR_WARN, 8, "Arial Bold");
      CrLabel("nwL", x+15, y+150, "LOTE BASE:", CLR_MUTED, 8);  CrLabel("nwV", x+110, y+150, DoubleToString(eff_Lots, 2), CLR_SUCCESS, 8);
      CrLabel("tfL", x+15, y+170, "TEMP. (TF):", CLR_MUTED, 8); CrLabel("tfV", x+110, y+170, EnumToString(_Period), CLR_SUCCESS, 8);
      
      string mUnit = isCentAccount ? " unid." : " $";
      CrLabel("opL", x+15, y+190, "META DIARIA:", CLR_MUTED, 8); CrLabel("opV", x+110, y+190, DoubleToString(eff_DailyTarget, isCentAccount?0:2) + mUnit, CLR_TXT, 8, "Arial Bold");

      CrLabel("moH", x+12, y+215, "MODOS & DIRECCIÓN", CLR_MUTED, 7);
      CrBtn("b_zen", x+10, y+230, 90, 25, "MODO ZEN", currentMode==MODE_ZEN?CLR_ACCENT:C'35,35,65', clrWhite);
      CrBtn("b_har", x+105, y+230, 90, 25, "COSECHA", currentMode==MODE_COSECHA?C'200,80,40':C'35,35,65', clrWhite);
      CrBtn("b_set", x+200, y+230, 85, 25, "⚙️ SET", CLR_HDR, clrWhite); // BOTON SET PARA SYNC FORZADO
      
      CrBtn("b_buy", x+10, y+265, 90, 25, "SOLO BUY", currentDir==DIR_COMPRAS?CLR_ACCENT:C'35,35,65', clrWhite);
      CrBtn("b_both", x+105, y+265, 90, 25, "AMBAS", currentDir==DIR_AMBAS?CLR_ACCENT:C'35,35,65', clrWhite);
      CrBtn("b_sell", x+200, y+265, 85, 25, "SOLO SELL", currentDir==DIR_VENTAS?C'180,40,40':C'35,35,65', clrWhite);
      CrBtn("b_close", x+10, y+305, 275, 30, "CLOSE ALL POSITIONS", CLR_DANGER, clrWhite);
      
      string accType = isCentAccount ? " REAL (CENT)" : " REAL (USD)";
      if(AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_DEMO) accType = " DEMO Account";
      
      CrLabel("rem", x+15, y+350, "CUENTA: " + accType, CLR_MUTED, 8, "Arial Bold");
      CrLabel("con", x+15, y+365, "CONTROL: " + (remotePaused?"🔴 PAUSA":"🟢 ONLINE"), (remotePaused?CLR_DANGER:CLR_SUCCESS), 8);
   }
   ChartRedraw(0);
}

void ActualizarPanel() {
   if(!isMinimized) {
      double p = GetDailyProfit();
      string unit = isCentAccount ? " unid." : " $";
      int digs = isCentAccount ? 0 : 2;
      ObjectSetString(0, PNL+"pV", OBJPROP_TEXT, DoubleToString(p, digs) + unit);
      ObjectSetInteger(0, PNL+"pV", OBJPROP_COLOR, p>=0?CLR_SUCCESS:CLR_DANGER);
      ObjectSetString(0, PNL+"stV", OBJPROP_TEXT, botStatus);
      ObjectSetInteger(0, PNL+"stV", OBJPROP_COLOR, (botStatus=="LISTO"||botStatus=="SENTINEL")?CLR_SUCCESS:CLR_WARN);
      
      ObjectSetString(0, PNL+"nwV", OBJPROP_TEXT, noticiaActiva ? "ALERTA - PAUSA" : "OK");
      ObjectSetInteger(0, PNL+"nwV", OBJPROP_COLOR, noticiaActiva ? CLR_DANGER : CLR_SUCCESS);
      
      int ops = PositionsTotalBots();
      ObjectSetString(0, PNL+"opV", OBJPROP_TEXT, IntegerToString(ops) + " / " + IntegerToString(mode_MaxPos));
      
      // Tendencia simplificada para el HUD
      double ma[];
      if(CopyBuffer(atrHandle, 0, 0, 1, ma) > 0) { // Usamos el ATR handle solo para sync, pero mejor buscar tendencia real
         ObjectSetString(0, PNL+"trV", OBJPROP_TEXT, "ACTIVA");
      }
   }
   ChartRedraw(0);
}

void OnChartEvent(const int id, const long &lp, const double &dp, const string &sp) {
   if(id!=CHARTEVENT_OBJECT_CLICK) return;
   if(sp==PNL+"min") { isMinimized=!isMinimized; CrearPanel(); }
   if(sp==PNL+"b_zen") { currentMode=MODE_ZEN; rem_Lots=0; UpdateModeParams(); CrearPanel(); }
   if(sp==PNL+"b_har") { currentMode=MODE_COSECHA; rem_Lots=0; UpdateModeParams(); CrearPanel(); }
   if(sp==PNL+"b_set") { CheckRemoteCommands(); UpdateModeParams(); SyncPositions(); CrearPanel(); }
   if(sp==PNL+"b_buy") { currentDir=DIR_COMPRAS; CrearPanel(); }
   if(sp==PNL+"b_sell") { currentDir=DIR_VENTAS; CrearPanel(); }
   if(sp==PNL+"b_both") { currentDir=DIR_AMBAS; CrearPanel(); }
   if(sp==PNL+"b_close") { CloseAllBotPositions(); }
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
    if(PurchaseID == "") return;
    if(TimeCurrent() < lastPositionsSync + 30) return;
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
    // --- Sincronizar Historial de Hoy ---
    string historyJson = "";
    int hCount = 0;
    HistorySelect(iTime(_Symbol, PERIOD_D1, 0), TimeCurrent());
    for(int i=HistoryDealsTotal()-1; i>=0; i--) {
        ulong t = HistoryDealGetTicket(i);
        if(HistoryDealGetInteger(t, DEAL_MAGIC) == activeMagic && HistoryDealGetDouble(t, DEAL_PROFIT) != 0) {
            if(hCount > 0) historyJson += ",";
            historyJson += "{\"ticket\":\"" + IntegerToString((long)t) + "\"," +
                           "\"type\":\"" + (HistoryDealGetInteger(t, DEAL_TYPE)==DEAL_TYPE_BUY?"BUY":"SELL") + "\"," +
                           "\"symbol\":\"" + HistoryDealGetString(t, DEAL_SYMBOL) + "\"," +
                           "\"lots\":" + DoubleToString(HistoryDealGetDouble(t, DEAL_VOLUME), 2) + "," +
                           "\"profit\":" + DoubleToString(HistoryDealGetDouble(t, DEAL_PROFIT), 2) + "}";
            hCount++;
            if(hCount >= 10) break; // Limitar para no saturar el JSON
        }
    }

    bool isReal = (AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL);
    string postData = "{\"purchaseId\":\"" + PurchaseID + "\",\"account\":\"" + account + "\",\"isReal\":" + (isReal?"true":"false") + ",\"positions\":[" + positionsJson + "],\"history\":[" + historyJson + "]}";
    char post[], result[]; string headers = "Content-Type: application/json\r\n";
    StringToCharArray(postData, post, 0, StringLen(postData), CP_UTF8);
    int syncRes = WebRequest("POST", "https://www.kopytrading.com/api/sync-positions", headers, 3000, post, result, headers);
    if(syncRes != 200) {
        Print("SYNC: Error detectado. Resultado: " + IntegerToString(syncRes) + " Cuerpo: " + CharArrayToString(result));
    }
}

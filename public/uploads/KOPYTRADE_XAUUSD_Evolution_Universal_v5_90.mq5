//+------------------------------------------------------------------+
//|          KOPYTRADE_XAUUSD_Evolution_Universal_v5_92               |
//|   EDICIÓN UNIVERSAL - STABILITY FIX (BE & LOGS)                   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrade Corp."
#property link      "https://www.kopytrade.com"
#property version   "5.92"
#property strict
#property description "Universal Bot | Stability Fix | Anti-Suffocation"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- GENERADOR DE HASH PARA MAGIC NUMBER AUTOMATICO ---
uint GetHash(string text) {
   uint hash = 5381;
   for(int i = 0; i < StringLen(text); i++) hash = ((hash << 5) + hash) + text[i];
   return hash & 0x7FFFFFFF;
}

//--- DECLARACIONES DE FUNCIONES VISUALES ---
void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bw=1);
void CrLabel(string n, int x, int y, string t, color c, int s=9, string f="Segoe UI");
void CrBtn(string n, int x, int y, int w, int h, string t, color bg, color tc);

enum ENUM_DIR  { DIR_COMPRAS, DIR_VENTAS, DIR_AMBAS };
enum ENUM_MODE { MODE_ZEN, MODE_COSECHA };

//============================================================
//  LICENCIA & SEGURIDAD
//============================================================
sinput string separator0 = "=========================="; // === LICENCIA & SEGURIDAD ===
input string   LicenseKey        = "TRIAL-2026";
input string   PurchaseID        = "";         // ID de Vínculo (Ver en kopytrading.com/dashboard)
input bool     EscalarACent      = true;       // 💰 Escalar (100 = $1.00) en todos los casos?

//============================================================
//  GESTIÓN DE RIESGO
//============================================================
sinput string separator1 = "=========================="; // === FILTRO DE NOTICIAS USD ===
input bool     FiltroNoticias       = true; // Activar pausa por noticias?
input int      MinutosAntes         = 30;   // Minutos antes de noticia
input int      MinutosDespues       = 30;   // Minutos despues de noticia

sinput string separator2 = "=========================="; // === CONFIGURACIÓN INTERNA ===
input ENUM_MODE ModePreset        = MODE_COSECHA; // 🎨 Modo del Bot (Zen/Cosecha)
input bool     UseManualSettings  = false;        // 🛠️ Ignorar Preset y usar ajustes manuales
input double   RiskPercent        = 0.0;          // % de Riesgo (0 = Lote Manual)
input int      MagicNumber        = 202509;       // Magic Number
input double   LoteManual         = 0.02;         // Lote Inicial Manual
input double   MaxDrawdown_Uni    = 500.0;        // 🛑 Stop de Emergencia Cuenta (500 unid.).
input double   Max_DD_Individual  = 100.0;        // 🛑 Stop por Operación (100 unid.).
input int      Max_Velas_Vida     = 0;            // ⏳ Vida máxima en velas por operación (0 = Desact.).
input int      MaxPosiciones      = 2;            // 📈 Máximo de posiciones abiertas (Bot)

//============================================================
//  RESCATE MATEMÁTICO (ULTRA)
//============================================================
sinput string separator3 = "=========================="; // === RESCATE MATEMÁTICO (ULTRA) ===
input bool     ActivarRescate     = true;      // 🚑 Activar Operación de Rescate
input double   MultiplicadorLote  = 2.0;       // Multiplicador base Martingala
input double   DistanciaRescate   = 50.0;      // $ Perdida para activar gatillo (50 unid.)
input int      DelayRescateSegs   = 120;       // Segundos de espera para rescatar (2 min)
input double   MaxLoteRescate     = 0.10;      // 🛡️ Lote máximo permitido en rescate
input double   MinLoteRescate     = 0.03;      // 🚑 Lote mínimo para rescatar

//============================================================
//  METAS & CORTAFUEGOS
//============================================================
sinput string separator4 = "=========================="; // === METAS & CORTAFUEGOS ===
input double   MetaDiaria_Uni      = 500.0;     // 🎯 Ganancia Diaria (500 unid.).
input double   Meta_Ciclo_Uni      = 100.0;     // Neto para cerrar ciclo (100 unid.)
input double   Harvest_TP_Uni      = 15.0;      // TP individual (15 unid. = 15 céntimos)

//============================================================
//  BREAK EVEN & TRAILING
//============================================================
sinput string separator5 = "=========================="; // === BREAK EVEN & TRAILING ===
input bool     ActivarBE           = true;      // 🛡️ Activar Break Even
input double   BE_Trigger_Uni      = 30.0;      // Activar BE tras (30 unidades)
input bool     ActivarTrailing     = true;      // 🚀 Activar Trailing Stop
input int      TrailingPoints      = 150;       // Puntos de Trailing (15 pips)
input int      TrailingStep        = 50;        // Paso de Trailing (5 pips)

//============================================================
//  ESTRATEGIA & FILTROS
//============================================================
sinput string separator6 = "=========================="; // === ESTRATEGIA (MOMENTUM) ===
input int      MomentumCandles     = 3;        
input int      MomentumRequired    = 2;        
input int      CooldownSeconds     = 60;       
input int      DistanciaGates      = 500;      // Distancia de entrada en puntos ($5 aprox)
input int      DistanciaRefuerzo   = 350;      // Distancia orden REFUERZO (3.5 pips)
input int      DistanciaRescateP   = 250;      // Distancia orden RESCATE (2.5 pips)
input bool     EnableTimeFilter    = true;     // ⏰ Activar filtro de horario
input int      StartHour1          = 9;        
input int      EndHour1            = 17;       
input int      StartHour2          = 17;       
input int      EndHour2            = 22;       

//--- Variables internas ---
CTrade         trade;
CPositionInfo  posInfo;
int            activeMagic;
int            atrHandle, maSmallHandle, maBigHandle, rsiHandle;
datetime       lastRemoteSync = 0;
datetime       coolingEndTime = 0;
long           lastUpdateID = 0;
ENUM_DIR       currentDir = DIR_AMBAS;
ENUM_MODE      currentMode = MODE_COSECHA;
string         botStatus = "LISTO";
bool           isMinimized = false;
bool           remotePaused = false;
bool           noticiaActiva = false;
bool           startNotified = false;
int            startRetries = 0;
bool           loginPrinted = false;
datetime       lastPositionsSync = 0;

//--- VALORES EFECTIVOS (YA ESCALADOS) ---
double         eff_Lots;
double         eff_HarvestTP;
double         eff_CycleMeta;
double         eff_BETrigger;
double         eff_DailyGoal;
double         eff_StopEmerg;
double         eff_StopIndiv;
double         eff_DistRescateTrigger;
int            eff_MaxPos;
int            eff_Entrada;

#define PNL "AEVO_U_"

//-- COLORES --
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
   maSmallHandle = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   maBigHandle   = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
   rsiHandle     = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   
   if(atrHandle == INVALID_HANDLE || maSmallHandle == INVALID_HANDLE || maBigHandle == INVALID_HANDLE || rsiHandle == INVALID_HANDLE) return(INIT_FAILED);
   
   // Auto-agregado visual al gráfico
   ChartIndicatorAdd(0, 0, maSmallHandle);
   ChartIndicatorAdd(0, 0, maBigHandle);
   ChartIndicatorAdd(0, 1, rsiHandle);
   
   UpdateEffectiveParams();
   CrearPanel(); 
   SyncPositions();
   EventSetTimer(3); 
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) { ObjectsDeleteAll(0, PNL); }

void UpdateEffectiveParams() {
   double scale = (EscalarACent) ? 0.01 : 1.0;
   
   if(currentMode == MODE_ZEN) {
      eff_HarvestTP = 20.0 * scale;
      eff_CycleMeta = 50.0 * scale;
      eff_BETrigger = 20.0 * scale;
      eff_MaxPos    = 1;
      eff_Entrada   = 1000;
   } else {
      eff_HarvestTP = Harvest_TP_Uni * scale;
      eff_CycleMeta = Meta_Ciclo_Uni * scale;
      eff_BETrigger = BE_Trigger_Uni * scale;
      eff_MaxPos    = MaxPosiciones;
      eff_Entrada   = DistanciaGates;
   }
   
   // SEGURIDAD: Evitar que el BE asfixie la operación (Mínimo $1.50 de beneficio para mover stop)
   if(eff_BETrigger < 1.50) eff_BETrigger = 1.50;
   
   eff_Lots       = LoteManual;
   eff_DailyGoal  = MetaDiaria_Uni * scale;
   eff_StopEmerg  = MaxDrawdown_Uni * scale;
   eff_StopIndiv  = Max_DD_Individual * scale;
   eff_DistRescateTrigger = DistanciaRescate * scale;
}

void OnTick() {
   double dailyProfit = GetDailyProfit();
   double currentNet = GetCurrentNetProfit();
   
   if(remotePaused) { botStatus = "🔴 PAUSA REMOTA"; DeleteBotPendings(); ActualizarPanel(); return; }
   
   if(eff_DailyGoal > 0 && dailyProfit >= eff_DailyGoal) {
      if(PositionsTotalBots() == 0) { botStatus = "META ALCANZADA"; DeleteBotPendings(); ActualizarPanel(); return; }
      if(currentNet >= 0) { CloseAllBotPositions(); DeleteBotPendings(); botStatus = "META ALCANZADA"; ActualizarPanel(); return; }
      else botStatus = "META (LIMPIANDO)";
   }

   noticiaActiva = HayNoticia();
   if(noticiaActiva || !IsTradingTime() || TimeCurrent() < coolingEndTime) {
      botStatus = noticiaActiva ? "ALERTA NOTICIA" : (TimeCurrent() < coolingEndTime ? "ENFRIANDO" : "FUERA DE HORARIO");
      ManageOpenPositions(); DeleteBotPendings(); ActualizarPanel(); SyncPositions(); return;
   }

   ManageOpenPositions();
   MaintainGates();
   ActualizarPanel();
   SyncPositions();
}

void ManageOpenPositions() {
    double netProfit = GetCurrentNetProfit();
    int botPosCount = PositionsTotalBots();

    if(eff_StopEmerg > 0 && netProfit <= -eff_StopEmerg) {
       CloseAllBotPositions(); botStatus = "🛑 STOP EMERGENCIA"; remotePaused = true; return;
    }

    if(botPosCount >= 2 && netProfit >= eff_CycleMeta) {
       CloseAllBotPositions(); coolingEndTime = TimeCurrent() + CooldownSeconds; return;
    }
    
    for(int i=PositionsTotal()-1; i>=0; i--) {
       if(posInfo.SelectByIndex(i) && posInfo.Magic() == activeMagic) {
          double p = posInfo.Profit() + posInfo.Commission() + posInfo.Swap();
          int candlesPassed = iBarShift(_Symbol, _Period, (datetime)posInfo.Time());
          
          if(p <= -eff_StopIndiv) { trade.PositionClose(posInfo.Ticket()); continue; }
          if(Max_Velas_Vida > 0 && candlesPassed >= Max_Velas_Vida) { trade.PositionClose(posInfo.Ticket()); continue; }
          
          // FIX RESCATE: Los rescates no se cierran solos si están por debajo de eff_HarvestTP
          if(p >= eff_HarvestTP && posInfo.Comment() != "RESCATE_P") { trade.PositionClose(posInfo.Ticket()); continue; }

          if(ActivarBE && p >= eff_BETrigger) {
             double open = posInfo.PriceOpen(), bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK), sl = posInfo.StopLoss();
             double slLvl = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
             if(posInfo.PositionType()==POSITION_TYPE_BUY) {
                double nBE = open + (2*_Point);
                if(MathAbs(sl - nBE) > _Point) if(bid-nBE > slLvl) trade.PositionModify(posInfo.Ticket(), NormalizeDouble(nBE, _Digits), posInfo.TakeProfit());
                if(ActivarTrailing && bid-nBE > TrailingPoints*_Point) {
                   double ts = bid - TrailingPoints*_Point;
                   if((ts > sl + TrailingStep*_Point || sl == 0) && MathAbs(sl - ts) > _Point) trade.PositionModify(posInfo.Ticket(), NormalizeDouble(ts, _Digits), posInfo.TakeProfit());
                }
             } else {
                double nBE = open - (2*_Point);
                if(MathAbs(sl - nBE) > _Point) if(nBE-ask > slLvl) trade.PositionModify(posInfo.Ticket(), NormalizeDouble(nBE, _Digits), posInfo.TakeProfit());
                if(ActivarTrailing && nBE-ask > TrailingPoints*_Point) {
                   double ts = ask + TrailingPoints*_Point;
                   if((ts < sl - TrailingStep*_Point || sl == 0) && MathAbs(sl - ts) > _Point) trade.PositionModify(posInfo.Ticket(), NormalizeDouble(ts, _Digits), posInfo.TakeProfit());
                }
             }
          }
       }
    }
}

void MaintainGates() {
   if(remotePaused) { DeleteBotPendings(); return; }
   int botPosCount = PositionsTotalBots();
   
   // FIX: Lógica de entrada continua si acabamos de cerrar en positivo y la tendencia sigue (RSI simple)
   if(botPosCount == 0 && TimeCurrent() < coolingEndTime && currentMode == MODE_COSECHA) {
       double rsi = GetRSI();
       if((currentDir != DIR_VENTAS && rsi > 60) || (currentDir != DIR_COMPRAS && rsi < 40)) {
           coolingEndTime = 0; // Rompemos el enfriamiento si la tendencia es brutal
       }
   }

   if(botPosCount > 0) {
      if(botPosCount >= eff_MaxPos) { DeleteBotPendings(); return; }
      ENUM_POSITION_TYPE mainType = GetMainPositionType();
      double netProfit = GetCurrentNetProfit(), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK), bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      
      ulong t_ref = GetPendingTicketByComment("REFUERZO");
      // REDUCIMOS LA DISTANCIA DEL REFUERZO PARA QUE NO "HUYA": 200 puntos en lugar de los 350 originales
      double dRef = (DistanciaRefuerzo * 0.6) * _Point; 
      
      if(netProfit > (eff_HarvestTP * 0.4)) { // Bajamos el umbral para que entre antes
         if(t_ref == 0) (mainType==POSITION_TYPE_BUY) ? trade.BuyStop(eff_Lots, ask+dRef, _Symbol, 0, 0, 0, 0, "REFUERZO") : trade.SellStop(eff_Lots, bid-dRef, _Symbol, 0, 0, 0, 0, "REFUERZO");
         // Ajustar orden si el precio se aleja demasiado (Chase)
         else {
            if(mainType==POSITION_TYPE_BUY && ask+dRef < OrderGetDouble(OBJPROP_PRICE) - 50*_Point) trade.OrderModify(t_ref, ask+dRef, 0, 0, 0);
            if(mainType==POSITION_TYPE_SELL && bid-dRef > OrderGetDouble(OBJPROP_PRICE) + 50*_Point) trade.OrderModify(t_ref, bid-dRef, 0, 0, 0);
         }
      } else if(t_ref != 0) trade.OrderDelete(t_ref);

      ulong t_res = GetPendingTicketByComment("RESCATE_P");
      double dRes = DistanciaRescateP * _Point;
      if(netProfit < -eff_DistRescateTrigger && ActivarRescate) {
         if(t_res == 0) (mainType==POSITION_TYPE_BUY) ? trade.SellStop(CalculateRecoveryLot(MathAbs(netProfit)), bid-dRes, _Symbol, 0, 0, 0, 0, "RESCATE_P") : trade.BuyStop(CalculateRecoveryLot(MathAbs(netProfit)), ask+dRes, _Symbol, 0, 0, 0, 0, "RESCATE_P");
      }
   } else {
      if(CountPendings(ORDER_TYPE_BUY_STOP) + CountPendings(ORDER_TYPE_SELL_STOP) == 0) {
         double d = eff_Entrada * _Point;
         if(currentDir != DIR_VENTAS) trade.BuyStop(eff_Lots, SymbolInfoDouble(_Symbol, SYMBOL_ASK)+d, _Symbol, 0, 0, 0, 0, "G_BUY");
         if(currentDir != DIR_COMPRAS) trade.SellStop(eff_Lots, SymbolInfoDouble(_Symbol, SYMBOL_BID)-d, _Symbol, 0, 0, 0, 0, "G_SELL");
      }
   }
}

double GetRSI() {
   int handle = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   double val[1];
   if(CopyBuffer(handle, 0, 0, 1, val) > 0) return val[0];
   return 50;
}

void OnTimer() { 
   if(PurchaseID != "" && TimeCurrent() - lastRemoteSync >= 30) { CheckRemoteCommands(); SyncPositions(); lastRemoteSync = TimeCurrent(); }
}

void CheckRemoteCommands() {
   string url = "https://www.kopytrading.com/api/remote-control?purchaseId=" + PurchaseID + "&account=" + IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN));
   char post[], result[]; string headers;
   if(WebRequest("GET", url, headers, 2000, post, result, headers) == 200) {
      string resp = CharArrayToString(result);
      if(StringFind(resp, "\"command\":\"PAUSE\"") != -1) remotePaused = true;
      if(StringFind(resp, "\"command\":\"RESUME\"") != -1) remotePaused = false;
      if(StringFind(resp, "\"command\":\"CLOSE_ALL\"") != -1) CloseAllBotPositions();
      if(StringFind(resp, "\"command\":\"CHANGE_MODE\"") != -1) {
         currentMode = (StringFind(resp, "\"value\":\"ZEN\"") != -1) ? MODE_ZEN : MODE_COSECHA; UpdateEffectiveParams();
      }
      if(StringFind(resp, "\"command\":\"DIRECTION\"") != -1) {
         if(StringFind(resp, "\"value\":\"BUY\"")!=-1) currentDir=DIR_COMPRAS; else if(StringFind(resp, "\"value\":\"SELL\"")!=-1) currentDir=DIR_VENTAS; else currentDir=DIR_AMBAS;
      }
      CrearPanel();
   }
}

double GetDailyProfit() {
   HistorySelect(iTime(_Symbol, PERIOD_D1, 0), TimeCurrent());
   double p = 0;
   for(int i=HistoryDealsTotal()-1; i>=0; i--) {
      ulong t = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(t, DEAL_MAGIC) == activeMagic) p += HistoryDealGetDouble(t, DEAL_PROFIT);
   }
   return p;
}
double GetCurrentNetProfit() {
   double p = 0;
   for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic() == activeMagic) p += posInfo.Profit() + posInfo.Commission() + posInfo.Swap();
   return p;
}
int PositionsTotalBots() {
   int c=0; for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) c++;
   return c;
}
void CloseAllBotPositions() { for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) trade.PositionClose(posInfo.Ticket()); }
void DeleteBotPendings() { for(int i=OrdersTotal()-1; i>=0; i--) if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC)==activeMagic) trade.OrderDelete(OrderGetTicket(i)); }
ENUM_POSITION_TYPE GetMainPositionType() {
   for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic() == activeMagic) return (ENUM_POSITION_TYPE)posInfo.PositionType();
   return POSITION_TYPE_BUY;
}
int CountPendings(ENUM_ORDER_TYPE type) {
   int c=0; for(int i=0; i<OrdersTotal(); i++) if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC)==activeMagic && OrderGetInteger(ORDER_TYPE)==type) c++;
   return c;
}
ulong GetPendingTicketByComment(string cmnt) {
   for(int i=0; i<OrdersTotal(); i++) {
      ulong t = OrderGetTicket(i);
      if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC)==activeMagic && OrderGetString(ORDER_COMMENT)==cmnt) return t;
   }
   return 0;
}
double CalculateRecoveryLot(double loss) { return NormalizeLot(eff_Lots * MultiplicadorLote); }
double NormalizeLot(double l) {
   double min = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double res = MathFloor(l/step)*step; return (res < min) ? min : res;
}
bool IsTradingTime() {
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   bool session1 = (dt.hour >= StartHour1 && dt.hour < EndHour1);
   bool session2 = (dt.hour >= StartHour2 && dt.hour < EndHour2);
   return (!EnableTimeFilter || session1 || session2);
}
bool HayNoticia() { 
   if(!FiltroNoticias) return false;
   MqlCalendarValue vals[];
   if(CalendarValueHistory(vals, TimeCurrent()-MinutosDespues*60, TimeCurrent()+MinutosAntes*60, "USD") > 0) {
      for(int i=0; i<ArraySize(vals); i++) {
         MqlCalendarEvent ev;
         if(CalendarEventById(vals[i].event_id, ev) && ev.importance == CALENDAR_IMPORTANCE_HIGH) return true;
      }
   }
   return false;
}

void CrearPanel() {
   ObjectsDeleteAll(0, PNL);
   int x=15, y=15, w=290, h=330;
   if(isMinimized) { w=200; h=60; }
   CrRect("bg", x, y, w, h, CLR_BG, CLR_BRD, 2);
   CrRect("hdr", x+2, y+2, w-4, 40, CLR_HDR, CLR_HDR);
   CrLabel("ttl", x+15, y+8, "EVOLUTION UNIVERSAL", clrWhite, 10, "Arial Bold");
   CrLabel("sub", x+15, y+25, "v5.91 - kopytrading.com", CLR_MUTED, 7);
   CrBtn("min", x+w-25, y+10, 18, 18, isMinimized?"+":"-", CLR_HDR, clrWhite);
   if(!isMinimized) {
      CrLabel("li", x+15, y+55, "LIC: " + LicenseKey, CLR_WARN, 8, "Arial Bold");
      CrLabel("pL", x+15, y+80, "PnL HOY:", CLR_MUTED, 8); 
      double p = GetDailyProfit();
      CrLabel("pV", x+100, y+80, DoubleToString(p, 2) + " $", p>=0?CLR_SUCCESS:CLR_DANGER, 10, "Arial Bold");
      CrLabel("stL", x+15, y+105, "ESTADO:", CLR_MUTED, 8); CrLabel("stV", x+100, y+105, botStatus, CLR_SUCCESS, 9);
      CrLabel("moL", x+15, y+130, "MODO:", CLR_MUTED, 8); CrLabel("moV", x+100, y+130, currentMode==MODE_ZEN?"ZEN":"COSECHA", CLR_ACCENT, 8, "Arial Bold");
      
      CrLabel("hd", x+12, y+165, "CONTROL RÁPIDO", CLR_MUTED, 7);
      CrBtn("b_zen", x+10, y+180, 85, 25, "ZEN", currentMode==MODE_ZEN?CLR_ACCENT:C'35,35,65', clrWhite);
      CrBtn("b_har", x+100, y+180, 85, 25, "COSECHA", currentMode==MODE_COSECHA?C'200,80,40':C'35,35,65', clrWhite);
      CrBtn("b_both", x+190, y+180, 85, 25, "AMBAS", currentDir==DIR_AMBAS?CLR_ACCENT:C'35,35,65', clrWhite);
      CrBtn("b_close", x+10, y+215, 265, 30, "CLOSE ALL POSITIONS", CLR_DANGER, clrWhite);
      
      string aT = (SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) < 0.001) ? "REAL (CENT)" : "REAL (USD)";
      if(AccountInfoInteger(ACCOUNT_TRADE_MODE)==ACCOUNT_TRADE_MODE_DEMO) aT = "DEMO Account";
      CrLabel("acc", x+15, y+260, "TIPO: " + aT, CLR_MUTED, 8);
      CrLabel("sca", x+15, y+275, "ESCALADO: " + (EscalarACent?"ACTIVO (50=0.50)":"OFF"), CLR_TXT, 8);
      CrLabel("ctr", x+15, y+295, "REMOTO: " + (remotePaused?"🔴 PAUSA":"🟢 ONLINE"), remotePaused?CLR_DANGER:CLR_SUCCESS, 8);
   }
   ChartRedraw(0);
}

void ActualizarPanel() {
   if(!isMinimized) {
      double p = GetDailyProfit();
      ObjectSetString(0, PNL+"pV", OBJPROP_TEXT, DoubleToString(p, 2) + " $");
      ObjectSetInteger(0, PNL+"pV", OBJPROP_COLOR, p>=0?CLR_SUCCESS:CLR_DANGER);
      ObjectSetString(0, PNL+"stV", OBJPROP_TEXT, botStatus);
   }
   ChartRedraw(0);
}

void OnChartEvent(const int id, const long &lp, const double &dp, const string &sp) {
   if(id!=CHARTEVENT_OBJECT_CLICK) return;
   if(sp==PNL+"min") { isMinimized=!isMinimized; CrearPanel(); }
   if(sp==PNL+"b_zen") { currentMode=MODE_ZEN; UpdateEffectiveParams(); CrearPanel(); }
   if(sp==PNL+"b_har") { currentMode=MODE_COSECHA; UpdateEffectiveParams(); CrearPanel(); }
   if(sp==PNL+"b_both") { currentDir=DIR_AMBAS; CrearPanel(); }
   if(sp==PNL+"b_close") CloseAllBotPositions();
   ObjectSetInteger(0, sp, OBJPROP_STATE, false);
}

void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bw=1) {
   ObjectCreate(0,PNL+n,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,bd);
   ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,100);
}
void CrLabel(string n, int x, int y, string t, color c, int s, string f="Segoe UI") {
   ObjectCreate(0,PNL+n,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y);
   ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,c);
   ObjectSetInteger(0,PNL+n,OBJPROP_FONTSIZE,s); ObjectSetString(0,PNL+n,OBJPROP_FONT,f);
   ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,101);
}
void CrBtn(string n, int x, int y, int w, int h, string t, color bg, color tc) {
   ObjectCreate(0,PNL+n,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h);
   ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,tc);
   ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,102);
}
void SyncPositions() {
    if(PurchaseID == "") return; if(TimeCurrent() < lastPositionsSync + 30) return; lastPositionsSync = TimeCurrent();
    string account = IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN)), posJ = "", histJ = "";
    int c = 0;
    for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==activeMagic) {
       if(c>0) posJ += ",";
       posJ += "{\"ticket\":\""+IntegerToString((long)posInfo.Ticket())+"\",\"type\":\""+(posInfo.PositionType()==POSITION_TYPE_BUY?"BUY":"SELL")+"\",\"symbol\":\""+posInfo.Symbol()+"\",\"lots\":"+DoubleToString(posInfo.Volume(),2)+",\"openPrice\":"+DoubleToString(posInfo.PriceOpen(),_Digits)+",\"sl\":"+DoubleToString(posInfo.StopLoss(),_Digits)+",\"tp\":"+DoubleToString(posInfo.TakeProfit(),_Digits)+",\"profit\":"+DoubleToString(posInfo.Profit()+posInfo.Commission()+posInfo.Swap(),2)+"}";
       c++;
    }
    HistorySelect(iTime(_Symbol, PERIOD_D1, 0), TimeCurrent());
    int hc = 0;
    for(int i=HistoryDealsTotal()-1; i>=0; i--) {
       ulong t = HistoryDealGetTicket(i);
       if(HistoryDealGetInteger(t, DEAL_MAGIC) == activeMagic && HistoryDealGetDouble(t, DEAL_PROFIT) != 0) {
          if(hc>0) histJ += ",";
          histJ += "{\"ticket\":\""+IntegerToString((long)t)+"\",\"type\":\""+(HistoryDealGetInteger(t, DEAL_TYPE)==DEAL_TYPE_BUY?"BUY":"SELL")+"\",\"symbol\":\""+HistoryDealGetString(t, DEAL_SYMBOL)+"\",\"lots\":"+DoubleToString(HistoryDealGetDouble(t, DEAL_VOLUME),2)+",\"profit\":"+DoubleToString(HistoryDealGetDouble(t, DEAL_PROFIT), 2)+"}";
          hc++; if(hc>=10) break;
       }
    }
    bool isR = (AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL);
    string postD = "{\"purchaseId\":\""+PurchaseID+"\",\"account\":\""+account+"\",\"isReal\":"+(isR?"true":"false")+",\"version\":\"5.91\",\"positions\":["+posJ+"],\"history\":["+histJ+"]}";
    char post[], res[]; string head = "Content-Type: application/json\r\n";
    StringToCharArray(postD, post, 0, StringLen(postD), CP_UTF8);
    WebRequest("POST", "https://www.kopytrading.com/api/sync-positions", head, 3000, post, res, head);
}

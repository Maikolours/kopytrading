//|          BTCSTORM_RIDER_ULTRA_v7.0 - EDICIÓN "TENDENCIA"         |
//|   FILTRO DE MEDIA MÓVIL 200 + MOMENTUM RÁPIDO + LÍMITES BTC      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrade Corp."
#property link      "https://www.kopytrade.com"
#property version   "7.00"
#property strict
#property description "BTC Storm Rider v7.0 | Filtro Trend SMA200 | Alta Velocidad"

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/SymbolInfo.mqh>

//--- DECLARACIONES DE FUNCIONES VISUALES ---
void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bw=1);
void CrLabel(string n, int x, int y, string t, color c, int s=9, string f="Segoe UI");
void CrBtn(string n, int x, int y, int w, int h, string t, color bg, color tc);

//============================================================
//  CONFIGURACIÓN DE CUENTA & LICENCIA
//============================================================
input group "=== SEGURIDAD & DASHBOARD BTC ==="
input string   LicenseKey        = "BTC-ULTRA-2026";
input string   PurchaseID        = "";         // ID de Vínculo (Ver Marketplace en kopytrading.com)
input string   CuentasPermitidas = "";         // Ejemplo: 123456,789012 (Vacio = Todas)
input bool     EsCuentaCent      = true;       // 💰 Activar si es cuenta CENT ($100 = 10,000 unidades)

//============================================================
//  GESTIÓN DE RIESGO BTC
//============================================================
input group "=== GESTION DE RIESGO BTC ==="
input double   LoteManual         = 0.01;      // Lote Inicial (0.01 recomendado para $1k)
input int      MagicNumber        = 707070;    // Numero Identificador BTC
input double   MaxDrawdown_USD    = 50.0;      // 🛑 Stop Emergencia Cuenta ($)
input double   Max_DD_Individual  = 10.0;      // 🛑 Stop por Operación ($)
input int      MaxPosiciones      = 4;         // 📈 Máximo de posiciones BTC
input int      Max_Velas_Vida     = 10;        // ⏳ Vida máxima en velas (M15/M30)

//============================================================
//  RESCATE MATEMÁTICO (ULTRA BTC)
//============================================================
input group "=== RESCATE MATEMÁTICO (ULTRA BTC) ==="
input bool     ActivarRescate     = true;      // 🚑 Activar Operación de Rescate
input double   DistanciaRescate   = 5.0;       // $ Perdida para activar gatillo ($)
input double   MaxLoteRescate     = 0.05;      // 🛡️ Lote máximo permitido en rescate
input double   MinLoteRescate     = 0.02;      // 🚑 Lote mínimo para rescatar

//============================================================
//  METAS & CORTAFUEGOS
//============================================================
input group "=== METAS & OBJETIVOS ==="
input double   MetaDiaria_USD      = 20.0;      // 🎯 Ganancia Diaria ($)
input double   Meta_Ciclo_USD      = 5.0;       // Neto para cerrar ciclo ($)
input double   Harvest_TP_USD      = 2.0;       // Meta por operación individual ($)

//============================================================
//  FILTRO DE TENDENCIA (PRO BTC)
//============================================================
input group "=== FILTRO DE TENDENCIA ==="
input bool     ActivarFiltroTendencia = true;   // 🚀 Solo operar a favor de la Media
input int      MediaTendencia         = 200;    // Periodos de la Media Móvil (SMA)

//============================================================
//  BREAK EVEN & TRAILING
//============================================================
input group "=== PROTECCIÓN (BE & TRAILING) ==="
input bool     ActivarBE           = true;      // 🛡️ Activar Break Even
input double   BE_Trigger_USD      = 2.0;       // Activar BE tras ($)
input bool     ActivarTrailing     = true;      // 🚀 Activar Trailing Stop
input int      TrailingPoints      = 1000;      // Puntos (1000 = $10 en BTC)
input int      TrailingStep        = 200;       // Paso ($2 en BTC)

//============================================================
//  ESTRATEGIA (MOMENTUM)
//============================================================
input group "=== ESTRATEGIA (MOMENTUM) ==="
input int      MomentumCandles     = 3;         // Velas para medir fuerza (M15/M30)
input int      MomentumRequired    = 2;         // Cuantas velas coinciden (ej: 2 de 3)
input int      CooldownSeconds     = 60;        // Espera tras cierre de ciclo (seg)
input bool     EnableTimeFilter    = false;     // ⏰ BTC opera 24/7 (false = desactivado)

//--- Variables internas ---
CTrade         trade;
CPositionInfo  posInfo;
int            maHandle;
datetime       coolingEndTime = 0;
datetime       lastRemoteSync = 0;
datetime       lastPositionsSync = 0;

enum ENUM_DIR  { DIR_COMPRAS, DIR_VENTAS, DIR_AMBAS };
enum ENUM_MODE { MODE_ZEN, MODE_COSECHA };

ENUM_DIR       currentDir  = DIR_AMBAS;
ENUM_MODE      currentMode = MODE_COSECHA;
string         botStatus   = "LISTO";
string         trendStatus = "MIDIENDO...";
bool           isMinimized = false;
bool           remotePaused = false; 
double         mode_HarvestTP = 2.0;
double         mode_CycleMeta = 5.0;
double         mode_BETrigger = 2.0;

#define PNL "BSR_v7_"

//--- COLORES PREMIUM ---
color CLR_BG      = C'10,10,25';
color CLR_HDR     = C'20,40,80';
color CLR_BRD     = C'60,100,200';
color CLR_TXT     = clrWhite;
color CLR_MUTED   = C'130,130,170';
color CLR_SUCCESS = C'40,200,90';
color CLR_DANGER  = C'210,50,50';
color CLR_WARN    = C'210,170,40';
color CLR_ACCENT  = C'40,120,220';

//--- INICIALIZACIÓN ---
int OnInit() {
   //--- Verificación de Cuentas ---
   if(CuentasPermitidas != "") {
      string login = IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN));
      if(StringFind(CuentasPermitidas, login) == -1) {
         Alert("ERROR BTC: Esta cuenta ("+login+") no está autorizada.");
         return(INIT_FAILED);
      }
   }

   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetTypeFillingBySymbol(_Symbol);
   
   if(!CheckLicenseServer()) return(INIT_FAILED);
   
   maHandle = iMA(_Symbol, _Period, MediaTendencia, 0, MODE_SMA, PRICE_CLOSE);
   if(maHandle == INVALID_HANDLE) return(INIT_FAILED);
   
   CrearPanel(); 
   UpdateModeParams();
   SyncPositions();
   EventSetTimer(3); 
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) { ObjectsDeleteAll(0, PNL); }

void OnTick() {
   ActualizarTendencia();
   
   double dailyProfit = GetDailyProfit();
   double currentNet = GetCurrentNetProfit();
   
   if(remotePaused) { botStatus = "🔴 PAUSA REMOTA"; DeleteBotPendings(); ActualizarPanel(); return; }
   
   // --- LÓGICA DE META DIARIA ---
   bool goalReached = (MetaDiaria_USD > 0 && dailyProfit >= MetaDiaria_USD);
   
   if(goalReached) {
      if(PositionsTotalBots() == 0) {
         botStatus = "META ALCANZADA"; DeleteBotPendings(); ActualizarPanel(); return;
      }
      if(currentNet >= 0) {
         CloseAllBotPositions(); DeleteBotPendings();
         botStatus = "META ALCANZADA"; ActualizarPanel(); return;
      } else { botStatus = "META (LIMPIANDO)"; }
   }

   ManageOpenPositions();
   if(!goalReached) MaintainGates(); 
   else DeleteBotPendings(); 

   if(TimeCurrent() < coolingEndTime) {
      botStatus = "ENFRIANDO"; ActualizarPanel(); return;
   }
   ActualizarPanel();
   SyncPositions();
}

void ActualizarTendencia() {
   double ma[];
   if(CopyBuffer(maHandle, 0, 0, 1, ma) > 0) {
      double close = iClose(_Symbol, _Period, 0);
      if(close > ma[0]) { trendStatus = "ALCISTA"; }
      else if(close < ma[0]) { trendStatus = "BAJISTA"; }
      else { trendStatus = "NEUTRAL"; }
   }
}

void OnTimer() { 
   if(PurchaseID != "" && TimeCurrent() - lastRemoteSync >= 30) {
      CheckRemoteCommands();
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
      if(StringFind(response, "\"command\":\"PAUSE\"") != -1) { remotePaused = true; CrearPanel(); }
      if(StringFind(response, "\"command\":\"RESUME\"") != -1) { remotePaused = false; CrearPanel(); }
      if(StringFind(response, "\"command\":\"CLOSE_ALL\"") != -1) { CloseAllBotPositions(); }
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

double USDtoPrice(double usd, double lot) {
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickValue <= 0 || lot <= 0) return 0;
   return (usd * tickSize) / (tickValue * lot);
}

void MaintainGates() {
   if(remotePaused) { DeleteBotPendings(); return; }
   int botPosCount = PositionsTotalBots();
   ENUM_POSITION_TYPE mainType = GetMainPositionType();
   double netProfit = GetCurrentNetProfit();

   if(botPosCount > 0) {
      if(botPosCount >= MaxPosiciones) { DeleteBotPendings(); return; }
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      
      // --- LOGICA DE REFUERZO BTC ---
      ulong t_ref = GetPendingTicketByComment("REF_BTC");
      double distRef = USDtoPrice(1.0, LoteManual); // $1 de distancia para BTC
      double targetRef = (mainType == POSITION_TYPE_BUY) ? ask + distRef : bid - distRef;
      
      if(netProfit >= 2.0) { // Profit > $2
         if(t_ref == 0) {
            if(mainType == POSITION_TYPE_BUY) trade.BuyStop(LoteManual, targetRef, _Symbol, 0, 0, 0, 0, "REF_BTC");
            else trade.SellStop(LoteManual, targetRef, _Symbol, 0, 0, 0, 0, "REF_BTC");
         }
      } else { if(t_ref != 0) trade.OrderDelete(t_ref); }

      // --- LOGICA DE RESCATE BTC ---
      ulong t_res = GetPendingTicketByComment("RES_BTC");
      double distRes = USDtoPrice(DistanciaRescate, LoteManual); 
      double targetRes = (mainType == POSITION_TYPE_BUY) ? bid - distRes : ask + distRes;

      if(t_res == 0) {
         double resLot = CalculateRecoveryLot(MathAbs(netProfit > 0 ? 0 : netProfit));
         if(mainType == POSITION_TYPE_BUY) trade.SellStop(resLot, targetRes, _Symbol, 0, 0, 0, 0, "RES_BTC");
         else trade.BuyStop(resLot, targetRes, _Symbol, 0, 0, 0, 0, "RES_BTC");
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
      
      bool allowBuy = true; bool allowSell = true;
      if(ActivarFiltroTendencia) {
         if(trendStatus == "ALCISTA") allowSell = false;
         if(trendStatus == "BAJISTA") allowBuy = false;
      }

      int p_buys = CountPendings(ORDER_TYPE_BUY_STOP);
      int p_sells = CountPendings(ORDER_TYPE_SELL_STOP);
      double dist = USDtoPrice(1.0, LoteManual); 
      
      if((currentDir == DIR_COMPRAS || currentDir == DIR_AMBAS) && p_buys == 0 && allowBuy)
         trade.BuyStop(LoteManual, SymbolInfoDouble(_Symbol, SYMBOL_ASK) + dist, _Symbol, 0, 0, 0, 0, "G_BUY_BTC");
      if((currentDir == DIR_VENTAS || currentDir == DIR_AMBAS) && p_sells == 0 && allowSell)
         trade.SellStop(LoteManual, SymbolInfoDouble(_Symbol, SYMBOL_BID) - dist, _Symbol, 0, 0, 0, 0, "G_SELL_BTC");
   }
}

ulong GetPendingTicketByComment(string cmnt) {
   for(int i=0; i<OrdersTotal(); i++) {
      ulong t = OrderGetTicket(i);
      if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC)==MagicNumber && OrderGetString(ORDER_COMMENT)==cmnt) return t;
   }
   return 0;
}

void ManageOpenPositions() {
    double netProfit = GetCurrentNetProfit();
    int botPosCount = PositionsTotalBots();

    if(MaxDrawdown_USD > 0 && netProfit <= -MaxDrawdown_USD) {
       CloseAllBotPositions(); botStatus = "🛑 STOP EMERGENCIA"; remotePaused = true; return;
    }

    if(botPosCount >= 2 && netProfit >= mode_CycleMeta) {
       CloseAllBotPositions(); coolingEndTime = TimeCurrent() + CooldownSeconds; return;
    }
    
    for(int i=PositionsTotal()-1; i>=0; i--) {
       if(posInfo.SelectByIndex(i) && posInfo.Magic() == MagicNumber) {
          double p = posInfo.Profit() + posInfo.Swap();
          int candles = iBarShift(_Symbol, _Period, (datetime)posInfo.Time());

          if(p <= -Max_DD_Individual) { trade.PositionClose(posInfo.Ticket()); coolingEndTime = TimeCurrent() + 300; continue; }
          if(Max_Velas_Vida > 0 && candles >= Max_Velas_Vida) { trade.PositionClose(posInfo.Ticket()); continue; }
          
          if(p >= mode_HarvestTP) { 
             trade.PositionClose(posInfo.Ticket()); 
             if(StringFind(posInfo.Comment(), "RES") != -1) coolingEndTime = 0; // CHAINING
             continue; 
          }

          if(ActivarBE && p >= mode_BETrigger) {
             double open = posInfo.PriceOpen();
             double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
             double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
             double dist = USDtoPrice(0.5, posInfo.Volume()); // Proteger $0.5
             if(posInfo.PositionType() == POSITION_TYPE_BUY) {
                double newBE = open + dist;
                if(posInfo.StopLoss() < newBE) trade.PositionModify(posInfo.Ticket(), NormalizeDouble(newBE, _Digits), posInfo.TakeProfit());
             }
             else {
                double newBE = open - dist;
                if(posInfo.StopLoss() > newBE || posInfo.StopLoss() == 0) trade.PositionModify(posInfo.Ticket(), NormalizeDouble(newBE, _Digits), posInfo.TakeProfit());
             }
          }
       }
    }
}

double GetCurrentNetProfit() {
   double p = 0;
   for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic() == MagicNumber) p += posInfo.Profit() + posInfo.Swap();
   if(EsCuentaCent) p /= 100.0; 
   return p;
}

ENUM_POSITION_TYPE GetMainPositionType() {
   for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic() == MagicNumber) return (ENUM_POSITION_TYPE)posInfo.PositionType();
   return POSITION_TYPE_BUY;
}

double CalculateRecoveryLot(double loss) { 
   double targetRecovery = loss + 1.0; // Ganar $1 extra en rescate BTC
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double distPoints = 5000; // Distancia proyectada grande para BTC
   double rawLot = targetRecovery / (distPoints * (tickValue / tickSize));
   double finalLot = NormalizeLot(rawLot * 1.5); 
   if(finalLot > MaxLoteRescate) finalLot = MaxLoteRescate;
   if(finalLot < MinLoteRescate) finalLot = MinLoteRescate; 
   return finalLot;
}

double NormalizeLot(double l) {
   double min = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double res = MathFloor(l/step)*step;
   return (res < min) ? min : res;
}

double GetDailyProfit() {
   HistorySelect(iTime(_Symbol, PERIOD_D1, 0), TimeCurrent());
   double p = 0;
   for(int i=HistoryDealsTotal()-1; i>=0; i--) {
      ulong t = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(t, DEAL_MAGIC) == MagicNumber) p += HistoryDealGetDouble(t, DEAL_PROFIT);
   }
   if(EsCuentaCent) p /= 100.0; 
   return p;
}

int CountPendings(ENUM_ORDER_TYPE type) {
   int c=0; for(int i=0; i<OrdersTotal(); i++) if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC)==MagicNumber && OrderGetInteger(ORDER_TYPE)==type) c++;
   return c;
}

int PositionsTotalBots() {
   int c=0; for(int i=0; i<PositionsTotal(); i++) if(posInfo.SelectByIndex(i) && posInfo.Magic()==MagicNumber) c++;
   return c;
}

void CloseAllBotPositions() { for(int i=PositionsTotal()-1; i>=0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic()==MagicNumber) trade.PositionClose(posInfo.Ticket()); }
void DeleteBotPendings() { for(int i=OrdersTotal()-1; i>=0; i--) if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC)==MagicNumber) trade.OrderDelete(OrderGetTicket(i)); }

void UpdateModeParams() {
   if(currentMode == MODE_ZEN) { mode_HarvestTP = 1.0; mode_CycleMeta = 3.0; mode_BETrigger = 1.0; }
   else { mode_HarvestTP = Harvest_TP_USD; mode_CycleMeta = Meta_Ciclo_USD; mode_BETrigger = BE_Trigger_USD; }
}

void CrearPanel() {
   ObjectsDeleteAll(0, PNL);
   int x=15, y=15, w=295, h=395;
   if(isMinimized) { w=220; h=65; }
   CrRect("bg", x, y, w, h, CLR_BG, CLR_BRD, 2);
   CrRect("hdr", x+2, y+2, w-4, 40, CLR_HDR, CLR_HDR);
   CrLabel("ttl", x+15, y+8, "BTC STORM RIDER v7.0", clrWhite, 11, "Arial Bold");
   CrLabel("sub", x+15, y+25, "Bilateral + Trend SMA200", CLR_MUTED, 7);
   CrBtn("min", x+w-25, y+8, 18, 18, isMinimized?"+":"-", CLR_HDR, clrWhite);
   
   if(!isMinimized) {
      CrLabel("licV", x+15, y+60, "LICENCIA: " + LicenseKey, CLR_WARN, 8, "Arial Bold");
      CrLabel("trL", x+15, y+90, "TENDENCIA BTC:", CLR_MUTED, 8); 
      CrLabel("trV", x+115, y+90, trendStatus, (trendStatus=="ALCISTA"?CLR_SUCCESS:(trendStatus=="BAJISTA"?CLR_DANGER:CLR_WARN)), 9, "Arial Bold");
      
      string pPrefix = EsCuentaCent ? "PnL HOY (USD):" : "PnL HOY USD:";
      CrLabel("pL", x+15, y+115, pPrefix, CLR_MUTED, 8); CrLabel("pV", x+115, y+115, "0", CLR_TXT, 10, "Arial Bold");
      CrLabel("stL", x+15, y+140, "ESTADO:", CLR_MUTED, 8); CrLabel("stV", x+115, y+140, botStatus, CLR_SUCCESS, 9);
      
      CrLabel("moH", x+12, y+175, "MODOS & DIRECCIÓN BTC", CLR_MUTED, 7);
      CrBtn("b_zen", x+10, y+195, 90, 25, "MODO ZEN", currentMode==MODE_ZEN?CLR_ACCENT:C'35,35,65', clrWhite);
      CrBtn("b_har", x+105, y+195, 90, 25, "COSECHA", currentMode==MODE_COSECHA?C'200,80,40':C'35,35,65', clrWhite);
      CrBtn("b_buy", x+10, y+230, 90, 25, "SOLO BUY", currentDir==DIR_COMPRAS?CLR_ACCENT:C'35,35,65', clrWhite);
      CrBtn("b_both", x+105, y+230, 90, 25, "AMBAS", currentDir==DIR_AMBAS?CLR_ACCENT:C'35,35,65', clrWhite);
      CrBtn("b_sell", x+200, y+230, 85, 25, "SOLO SELL", currentDir==DIR_VENTAS?C'180,40,40':C'35,35,65', clrWhite);
      CrBtn("b_close", x+10, y+270, 275, 30, "CERRAR TODAS LAS POSICIONES", CLR_DANGER, clrWhite);
      
      CrLabel("inf", x+15, y+315, "MODO: PROTECCIÓN ACTIVA", CLR_SUCCESS, 7);
      CrLabel("inf2", x+15, y+330, "RESCATE & BE CONFIGURADOS", CLR_MUTED, 7);
      
      string rem = "REMOTO: " + (remotePaused?"🔴 PAUSA":"🟢 ONLINE");
      CrLabel("rem", x+15, y+360, rem, (remotePaused?CLR_DANGER:CLR_SUCCESS), 8);
   }
   ChartRedraw(0);
}

void ActualizarPanel() {
   if(!isMinimized) {
      double p = GetDailyProfit();
      ObjectSetString(0, PNL+"pV", OBJPROP_TEXT, "$"+DoubleToString(p, 2));
      ObjectSetInteger(0, PNL+"pV", OBJPROP_COLOR, p>=0?CLR_SUCCESS:CLR_DANGER);
      ObjectSetString(0, PNL+"stV", OBJPROP_TEXT, botStatus);
      ObjectSetInteger(0, PNL+"stV", OBJPROP_COLOR, (botStatus=="LISTO"?CLR_SUCCESS:CLR_WARN));
      ObjectSetString(0, PNL+"trV", OBJPROP_TEXT, trendStatus);
      ObjectSetInteger(0, PNL+"trV", OBJPROP_COLOR, (trendStatus=="ALCISTA"?CLR_SUCCESS:(trendStatus=="BAJISTA"?CLR_DANGER:CLR_WARN)));
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
   ObjectSetInteger(0, sp, OBJPROP_STATE, false);
}

void CrRect(string n, int x, int y, int w, int h, color bg, color bd, int bw=1) {
   ObjectCreate(0,PNL+n,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,bd);
   ObjectSetInteger(0,PNL+n,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,PNL+n,OBJPROP_BACK,false); ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,100);
}
void CrLabel(string n, int x, int y, string t, color c, int s, string f="Segoe UI") {
   ObjectCreate(0,PNL+n,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y);
   ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,c);
   ObjectSetInteger(0,PNL+n,OBJPROP_FONTSIZE,s); ObjectSetString(0,PNL+n,OBJPROP_FONT,f);
   ObjectSetInteger(0,PNL+n,OBJPROP_BACK,false); ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,101);
}
void CrBtn(string n, int x, int y, int w, int h, string t, color bg, color tc) {
   ObjectCreate(0,PNL+n,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,PNL+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,PNL+n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,PNL+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,PNL+n,OBJPROP_YSIZE,h);
   ObjectSetString(0,PNL+n,OBJPROP_TEXT,t); ObjectSetInteger(0,PNL+n,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,PNL+n,OBJPROP_COLOR,tc);
   ObjectSetInteger(0,PNL+n,OBJPROP_BACK,false); ObjectSetInteger(0,PNL+n,OBJPROP_ZORDER,102);
}
void SyncPositions() {
    if(PurchaseID == "") return;
    Print("SYNC: Intentando sincronizar ID: " + PurchaseID);
    if(TimeCurrent() < lastPositionsSync + 30) return;
    lastPositionsSync = TimeCurrent();
    string account = IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN));
    string positionsJson = "";
    int count = 0;
    for(int i=0; i<PositionsTotal(); i++) {
        if(posInfo.SelectByIndex(i) && posInfo.Magic() == MagicNumber) {
            if(count > 0) positionsJson += ",";
            positionsJson += "{\"ticket\":\"" + IntegerToString((long)posInfo.Ticket()) + "\"," +
                             "\"type\":\"" + (posInfo.PositionType()==POSITION_TYPE_BUY?"BUY":"SELL") + "\"," +
                             "\"symbol\":\"" + posInfo.Symbol() + "\"," +
                             "\"lots\":" + DoubleToString(posInfo.Volume(), 2) + "," +
                             "\"openPrice\":" + DoubleToString(posInfo.PriceOpen(), _Digits) + "," +
                             "\"sl\":" + DoubleToString(posInfo.StopLoss(), _Digits) + "," +
                             "\"tp\":" + DoubleToString(posInfo.TakeProfit(), _Digits) + "," +
                             "\"profit\":" + DoubleToString(posInfo.Profit() + posInfo.Swap(), 2) + "}";
            count++;
        }
    }
    string postData = "{\"purchaseId\":\"" + PurchaseID + "\",\"account\":\"" + account + "\",\"positions\":[" + positionsJson + "]}";
    char post[], result[]; string headers = "Content-Type: application/json\r\n";
    StringToCharArray(postData, post, 0, WHOLE_ARRAY, CP_UTF8);
    int syncRes = WebRequest("POST", "https://www.kopytrading.com/api/sync-positions", headers, 3000, post, result, headers);
    Print("SYNC: Resultado servidor: " + IntegerToString(syncRes));
    if(syncRes != 200) {
        Print("SYNC: Error detectado. Cuerpo: " + CharArrayToString(result));
    }
}

bool CheckLicenseServer() {
   if(PurchaseID == "") {
      Print("LICENSE: PurchaseID Vacio. Iniciando en modo offline limitado.");
      if(AccountInfoInteger(ACCOUNT_TRADE_MODE) != ACCOUNT_TRADE_MODE_DEMO) {
         Alert("ERROR BTC: El modo offline solo es para cuentas DEMO. Introduce tu PurchaseID.");
         return false;
      }
      return true;
   }

   string account = IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN));
   int mode = (AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_DEMO) ? 0 : 1;
   string url = "https://www.kopytrading.com/api/license/check?purchaseId=" + PurchaseID + "&account=" + account + "&mode=" + IntegerToString(mode);
   
   char post[], result[]; string headers;
   int res = WebRequest("GET", url, headers, 3000, post, result, headers);
   
   if(res == 200) {
      string response = CharArrayToString(result);
      if(StringFind(response, "\"allowed\":true") != -1) {
         Print("LICENSE: Validacion exitosa BTC.");
         return true;
      } else {
         int msgPos = StringFind(response, "\"message\":\"");
         string msg = "Licencia No Valida (Server)";
         if(msgPos != -1) {
            string sub = StringSubstr(response, msgPos + 11);
            int end = StringFind(sub, "\"");
            msg = StringSubstr(sub, 0, end);
         }
         Alert("ERROR LICENCIA BTC: " + msg);
         return false;
      }
   }
   
   Print("LICENSE: Error de conexion BTC (" + IntegerToString(res) + "). Reintentando en Demo...");
   if(AccountInfoInteger(ACCOUNT_TRADE_MODE) != ACCOUNT_TRADE_MODE_DEMO) {
      Alert("ERROR: No se pudo verificar la licencia BTC en cuenta REAL. Revisa tu internet.");
      return false;
   }
   return true;
}

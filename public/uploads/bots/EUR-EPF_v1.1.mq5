//+------------------------------------------------------------------+
//|             KOPYTRADE_EURUSD_EuroPrecision Flow v2.1            |
//|        EMA CROSS TURBO + FILTRO RSI - ACTIVIDAD EXTREMA         |
//|                    Integración Kopytrade v1.4                   |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Bot Oficial"
#property version   "2.10"
#property strict
#property description "Euro Precision Flow | ACTIVIDAD TURBO (8+ ops/día)"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//--- INCLUIR MÓDULO DE INTEGRACIÓN
#include <Kopytrading_Integration.mqh>

//--- LICENCIA ---
input group "=== LICENCIA KOPYTRADE ==="
input string   PurchaseID         = "";     // ID de Vínculo (Copiar del Dashboard)
input string   LicenseKey         = "EUR-EPF"; // Product Key

//--- RELOJ ---
input group "=== RELOJ DE OPERACIÓN (HORARIO BROKER) ==="
input int      HoraInicio         = 8;      // Inicio sesión europea
input int      HoraFin            = 20;     // Cierre sesión americana

//--- GESTIÓN DE RIESGO ---
input group "=== GESTIÓN DE RIESGO ==="
input double   LoteInicial        = 0.01;   // Tamaño de la posición
input double   StopLossUSD        = 15.0;   // Protección máxima en $ por lote 0.01
input double   ProfitObjetivo     = 5.0;    // Cerrar automáticamente al ganar X dólares

//--- ESTRATEGIA TURBO ---
input group "=== ESTRATEGIA TURBO (CONFIDENCIAL) ==="
input int      EMA_Rapida         = 5;      // EMA muy rápida para actividad extrema
input int      EMA_Lenta          = 13;     // EMA de confirmación
input int      RSI_Sobrevendido   = 40;     // Nivel para comprar (rebote)
input int      RSI_Sobrecomprado  = 60;     // Nivel para vender (rebote)

//--- GESTIÓN DE BENEFICIO ---
input group "=== GESTIÓN DE BENEFICIO (BE & TRAILING) ==="
input double   BE_Activacion      = 2.0;    // Activar Break Even al ganar X dólares
input double   GarantiaBE         = 0.5;    // Ganancia asegurada tras el BE
input bool     ActivarTrailing    = true;   // ¿Deseas que el Stop siga al precio?
input int      DistanciaTrailing  = 100;    // Puntos de distancia (10 pips)
input int      SaltoDelTrailing   = 30;     // Puntos para mover (3 pips)

//--- AVANZADO ---
input group "=== CONFIGURACIÓN AVANZADA ==="
input int      MaxPosiciones      = 3;      // Máximas posiciones simultáneas
input long     MagicPrincipal     = 778822;

//--- GLOBALES ---
CPositionInfo posInfo;
CTrade trade;
int    emaRapHandle  = INVALID_HANDLE;
int    emaLentHandle = INVALID_HANDLE;
int    rsiHandle     = INVALID_HANDLE;
string botStatus     = "READY";
double dayPnL        = 0;

//+------------------------------------------------------------------+
int OnInit() {
   //--- 1. VALIDAR LICENCIA
   if(!ValidateLicense(PurchaseID, LicenseKey, (int)AccountInfoInteger(ACCOUNT_LOGIN))) {
      MessageBox("Licencia inválida: " + GetLicenseStatus(), "Kopytrade Error", MB_OK | MB_ICONERROR);
      return INIT_FAILED;
   }

   emaRapHandle  = iMA(_Symbol, _Period, EMA_Rapida,  0, MODE_EMA, PRICE_CLOSE);
   emaLentHandle = iMA(_Symbol, _Period, EMA_Lenta,   0, MODE_EMA, PRICE_CLOSE);
   rsiHandle     = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   
   trade.SetExpertMagicNumber(MagicPrincipal);
   trade.SetTypeFillingBySymbol(_Symbol);
   
   Print("🚀 Euro Precision Flow v2.1 Initialized");
   
   // Sync inicial
   SyncPositions(botStatus, 0, 0);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
   Comment("");
}

//+------------------------------------------------------------------+
void OnTick() {
   //--- 2. CONTROL REMOTO
   GetRemoteStatus();
   if(IsRemotePaused()) {
      botStatus = "PAUSED";
      MostrarHUD();
      SyncPositions(botStatus, dayPnL, ContarPosiciones());
      return;
   }
   
   botStatus = "ACTIVE";
   GestionarIndividual();
   if(ContarPosiciones() < MaxPosiciones && EstaEnHorario()) BuscarEntrada();
   
   //--- 3. SINCRONIZACIÓN
   dayPnL = CalculatePnL();
   SyncPositions(botStatus, dayPnL, ContarPosiciones());
   
   MostrarHUD();
}

double CalculatePnL() {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   datetime dayStart = StructToTime(dt);
   HistorySelect(dayStart, TimeCurrent());
   double p = 0;
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--) {
      ulong ticket = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) == MagicPrincipal)
         p += HistoryDealGetDouble(ticket, DEAL_PROFIT);
   }
   return p;
}

void BuscarEntrada() {
   double emaR[2], emaL[2], rsi[2];
   ArraySetAsSeries(emaR, true); ArraySetAsSeries(emaL, true); ArraySetAsSeries(rsi, true);
   if(CopyBuffer(emaRapHandle, 0, 0, 2, emaR) < 2) return;
   if(CopyBuffer(emaLentHandle, 0, 0, 2, emaL) < 2) return;
   if(CopyBuffer(rsiHandle, 0, 0, 2, rsi) < 2) return;

   bool cruzaArriba = (emaR[1] < emaL[1]) && (emaR[0] > emaL[0]);
   bool cruzaAbajo  = (emaR[1] > emaL[1]) && (emaR[0] < emaL[0]);

   double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(tickVal <= 0) return;
   double sl_puntos = StopLossUSD / (LoteInicial * tickVal / _Point);

   if(cruzaArriba && rsi[0] < RSI_Sobrecomprado) {
      double sl = SymbolInfoDouble(_Symbol, SYMBOL_BID) - sl_puntos * _Point;
      trade.Buy(LoteInicial, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_ASK), sl, 0, "EPF_TURBO_BUY");
   }
   if(cruzaAbajo && rsi[0] > RSI_Sobrevendido) {
      double sl = SymbolInfoDouble(_Symbol, SYMBOL_ASK) + sl_puntos * _Point;
      trade.Sell(LoteInicial, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_BID), sl, 0, "EPF_TURBO_SELL");
   }
}

void GestionarIndividual() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong t = PositionGetTicket(i);
      if(!PositionSelectByTicket(t) || PositionGetInteger(POSITION_MAGIC) != MagicPrincipal) continue;
      double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP) + PositionGetDouble(POSITION_COMMISSION);
      double pOpen  = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl     = PositionGetDouble(POSITION_SL);
      long   tipo   = PositionGetInteger(POSITION_TYPE);
      
      if(profit >= ProfitObjetivo) { trade.PositionClose(t); continue; }
      
      if(profit >= BE_Activacion) {
         double g = GarantiaBE * 10 * _Point;
         double nBE = (tipo == POSITION_TYPE_BUY) ? pOpen + g : pOpen - g;
         if(tipo == POSITION_TYPE_BUY  && (sl < nBE || sl == 0)) trade.PositionModify(t, nBE, 0);
         if(tipo == POSITION_TYPE_SELL && (sl > nBE || sl == 0)) trade.PositionModify(t, nBE, 0);
      }
      if(ActivarTrailing && profit >= BE_Activacion) {
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         if(tipo == POSITION_TYPE_BUY) { double ns = bid - DistanciaTrailing*_Point; if(ns > sl + SaltoDelTrailing*_Point) trade.PositionModify(t, ns, 0); }
         else { double ns = ask + DistanciaTrailing*_Point; if(sl==0||ns < sl - SaltoDelTrailing*_Point) trade.PositionModify(t, ns, 0); }
      }
   }
}

bool EstaEnHorario() { MqlDateTime dt; TimeToStruct(TimeCurrent(),dt); return(dt.hour >= HoraInicio && dt.hour < HoraFin); }
int ContarPosiciones() { int c=0; for(int i=0;i<PositionsTotal();i++) if(PositionSelectByTicket(PositionGetTicket(i))&&PositionGetInteger(POSITION_MAGIC)==MagicPrincipal) c++; return c; }

void MostrarHUD() {
   string comment = "";
   comment += "╔══════════════════════════════════════╗\n";
   comment += "║   Euro Precision Flow v2.1\n";
   comment += "╠══════════════════════════════════════╣\n";
   comment += "║ Licencia: " + GetLicenseStatus() + "\n";
   comment += "║ Estado:   " + botStatus + "\n";
   comment += "║ PNL Hoy:  " + DoubleToString(dayPnL, 2) + " USD\n";
   comment += "║ Posiciones: " + IntegerToString(ContarPosiciones()) + "\n";
   comment += "╚══════════════════════════════════════╝";
   Comment(comment);
}

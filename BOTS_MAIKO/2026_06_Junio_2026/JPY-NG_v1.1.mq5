//+------------------------------------------------------------------+
//|             KOPYTRADE_USDJPY_YenNinjaGhost v3.1 TITAN           |
//|        REBOTE + RSI + FILTRO TENDENCIAL EMA 50 H1               |
//|                    Integración Kopytrade v1.4                   |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Bot Oficial"
#property version   "3.10"
#property strict
#property description "Yen Ninja Ghost v3.1 | TITAN YEN (USDJPY)"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//--- INCLUIR MÓDULO DE INTEGRACIÓN
#include <Kopytrading_Integration.mqh>

//--- LICENCIA ---
input group "=== LICENCIA KOPYTRADE ==="
input string   PurchaseID         = "";     // ID de Vínculo (Copiar del Dashboard)
input string   LicenseKey         = "JPY-NG"; // Product Key

//--- RELOJ ---
input group "=== RELOJ DE OPERACIÓN (SESIÓN ASIÁTICA) ==="
input int      HoraInicio         = 0;      // Apertura de Tokio (hora broker)
input int      HoraFin            = 8;      // Cierre sesión asiática

//--- GESTIÓN DE RIESGO TITAN ---
input group "=== GESTIÓN DE RIESGO TITAN ==="
input double   RiskPercent        = 1.0;    // Riesgo por operación (%)
input double   LoteFijo           = 0.00;   // Ingrese valor > 0 para desactivar Risk%
input double   StopLossUSD        = 30.0;   // Protección máxima en $ (Yen es volátil)
input double   ProfitObjetivo     = 6.0;    

//--- ESTRATEGIA (NINJA MODE) ---
input group "=== ESTRATEGIA TITAN (BOLLINGER + RSI + EMA H1) ==="
input int      EMA_Filtro_Periodo = 50;     // Filtro Tendencial H1
input int      BB_Periodo         = 20;     
input double   BB_Desviacion      = 1.5;    
input int      RSI_Sobrevendido   = 40;     
input int      RSI_Sobrecomprado  = 60;     

//--- GESTIÓN DE BENEFICIO ---
input group "=== GESTIÓN DE BENEFICIO (BE & TRAILING) ==="
input double   BE_Activacion      = 1.5;    
input double   GarantiaBE         = 0.3;    
input bool     ActivarTrailing    = true;   
input int      DistanciaTrailing  = 100;    
input int      SaltoDelTrailing   = 30;     

//--- AVANZADO ---
input group "=== CONFIGURACIÓN AVANZADA ==="
input int      MaxPosiciones      = 2;      
input long     MagicPrincipal     = 779933;

//--- GLOBALES ---
CPositionInfo posInfo;
CTrade trade;
int    bbHandle     = INVALID_HANDLE;
int    rsiHandle    = INVALID_HANDLE;
int    emaHandle    = INVALID_HANDLE;
string botStatus    = "READY";
double dayPnL       = 0;

//+------------------------------------------------------------------+
int OnInit() {
   //--- 1. VALIDAR LICENCIA
   if(!ValidateLicense(PurchaseID, LicenseKey, (int)AccountInfoInteger(ACCOUNT_LOGIN))) {
      MessageBox("Licencia inválida: " + GetLicenseStatus(), "Kopytrade Error", MB_OK | MB_ICONERROR);
      return INIT_FAILED;
   }

   bbHandle  = iBands(_Symbol, _Period, BB_Periodo, 0, BB_Desviacion, PRICE_CLOSE);
   rsiHandle = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   emaHandle = iMA(_Symbol, PERIOD_H1, EMA_Filtro_Periodo, 0, MODE_EMA, PRICE_CLOSE);
   
   trade.SetExpertMagicNumber(MagicPrincipal);
   trade.SetTypeFillingBySymbol(_Symbol);
   
   Print("🚀 Yen Ninja Ghost v3.1 TITAN Initialized");
   
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

double GetDynamicLot() {
    if(LoteFijo > 0) return LoteFijo;
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double lot = NormalizeDouble((balance * RiskPercent / 100.0) / (StopLossUSD * 10), 2);
    if(lot < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN)) lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    if(lot > SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX)) lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    return lot;
}

void BuscarEntrada() {
   double bbUpper[2], bbLower[2], rsi[2], ema[2];
   ArraySetAsSeries(bbUpper,true); ArraySetAsSeries(bbLower,true); ArraySetAsSeries(rsi,true); ArraySetAsSeries(ema,true);
   
   if(CopyBuffer(bbHandle, 1, 0, 2, bbUpper) < 2) return;
   if(CopyBuffer(bbHandle, 2, 0, 2, bbLower) < 2) return;
   if(CopyBuffer(rsiHandle, 0, 0, 2, rsi) < 2) return;
   if(CopyBuffer(emaHandle, 0, 0, 2, ema) < 2) return;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double pNow = iClose(_Symbol, PERIOD_H1, 0);
   
   bool tendenciaAlcista = pNow > ema[0];
   bool tendenciaBajista = pNow < ema[0];

   double lote = GetDynamicLot();
   double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(tickVal <= 0) return;
   double sl_puntos = StopLossUSD / (lote * tickVal / _Point);

   if(bid <= bbLower[0] && rsi[0] < RSI_Sobrevendido && tendenciaAlcista) {
      double sl = ask - sl_puntos * _Point;
      trade.Buy(lote, _Symbol, ask, sl, 0, "YNG_TITAN_BUY");
   }
   if(ask >= bbUpper[0] && rsi[0] > RSI_Sobrecomprado && tendenciaBajista) {
      double sl = bid + sl_puntos * _Point;
      trade.Sell(lote, _Symbol, bid, sl, 0, "YNG_TITAN_SELL");
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
   comment += "║   Yen Ninja Ghost v3.1 TITAN\n";
   comment += "╠══════════════════════════════════════╣\n";
   comment += "║ Licencia: " + GetLicenseStatus() + "\n";
   comment += "║ Estado:   " + botStatus + "\n";
   comment += "║ PNL Hoy:  " + DoubleToString(dayPnL, 2) + " USD\n";
   comment += "║ Posiciones: " + IntegerToString(ContarPosiciones()) + "\n";
   comment += "╚══════════════════════════════════════╝";
   Comment(comment);
}

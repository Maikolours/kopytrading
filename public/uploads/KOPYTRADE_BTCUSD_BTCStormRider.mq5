//+------------------------------------------------------------------+
//|             KOPYTRADE_BTCUSD_BTCStormRider v2.0                 |
//|        BREAKOUT DE RANGO + MOMENTUM - OPERATIVA 24/7            |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Bot Oficial"
#property version   "2.00"
#property strict
#property description "BTC Storm Rider | BREAKOUT BITCOIN"

#include <Trade\Trade.mqh>

//--- LICENCIA ---
input group "=== LICENCIA KOPYTRADE ==="
input long     CuentaDemo         = 0;      // Número de cuenta DEMO de MT5
input long     CuentaReal         = 0;      // Número de cuenta REAL de MT5

//--- GESTIÓN DE RIESGO ---
input group "=== GESTIÓN DE RIESGO (BITCOIN REQUIERE MARGEN) ==="
input double   LoteInicial        = 0.01;   
input double   StopLossUSD        = 80.0;   // Protección en $ (BTC es altamente volátil)
input double   ProfitObjetivo     = 50.0;   

//--- ESTRATEGIA (STORM MODE) ---
input group "=== ESTRATEGIA BREAKOUT (M30/H1) ==="
input int      VelasRango         = 24;     // Rango de las últimas X velas (M30=12h)
input double   FiltroMinRango     = 500.0;  // Distancia mínima para considerar rango

//--- GESTIÓN DE BENEFICIO ---
input group "=== GESTIÓN DE BENEFICIO (BE & TRAILING) ==="
input double   BE_Activacion      = 20.0;   
input double   GarantiaBE         = 5.0;    
input bool     ActivarTrailing    = true;   
input int      DistanciaTrailing  = 2000;   // 200 pips (BTC mueve mucho)
input int      SaltoDelTrailing   = 500;    // 50 pips de salto

//--- AVANZADO ---
input group "=== CONFIGURACIÓN AVANZADA ==="
input int      MaxPosiciones      = 1;      
input long     MagicPrincipal     = 780044;

CTrade trade;
bool  licenseValid = false;
ulong lastBarTime  = 0;

//+------------------------------------------------------------------+
bool CheckTrialAndLicense() {
   long cuenta = AccountInfoInteger(ACCOUNT_LOGIN);
   if(cuenta == CuentaDemo || cuenta == CuentaReal) return true;
   if(AccountInfoInteger(ACCOUNT_TRADE_MODE) != ACCOUNT_TRADE_MODE_DEMO) {
      Alert("❌ LICENCIA REQUERIDA PARA REAL. kopytrade.com");
      return false;
   }
   string gVarName = "KOPYTRADE_BSR_TRIAL_START";
   datetime firstRun;
   if(!GlobalVariableCheck(gVarName)) {
      GlobalVariableSet(gVarName, (double)TimeCurrent());
      firstRun = TimeCurrent();
   } else firstRun = (datetime)GlobalVariableGet(gVarName);
   
   int dias = (int)((TimeCurrent() - firstRun) / 86400);
   if(dias <= 30) return true;
   Alert("⏰ TRIAL EXPIRADO. kopytrade.com");
   return false;
}

int OnInit() {
   if(!CheckTrialAndLicense()) return(INIT_FAILED);
   licenseValid = true;
   trade.SetExpertMagicNumber(MagicPrincipal);
   trade.SetTypeFillingBySymbol(_Symbol);
   return(INIT_SUCCEEDED);
}

void OnTick() {
   if(!licenseValid) return;
   GestionarIndividual();
   if(ContarPosiciones() > 0) return;
   datetime barActual = iTime(_Symbol, _Period, 0);
   if(barActual == (datetime)lastBarTime) return;
   lastBarTime = barActual;
   BuscarBreakout();
}

void BuscarBreakout() {
   double highest = -1, lowest = 999999999;
   for(int i = 1; i <= VelasRango; i++) {
      double h = iHigh(_Symbol, _Period, i);
      double l = iLow(_Symbol, _Period, i);
      if(h > highest) highest = h;
      if(l < lowest)  lowest  = l;
   }
   double rango = highest - lowest;
   if(rango < FiltroMinRango * _Point) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl_puntos = StopLossUSD / (LoteInicial * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) / _Point);

   if(ask > highest) {
      double sl = ask - sl_puntos * _Point;
      trade.Buy(LoteInicial, _Symbol, 0, sl, 0, "BSR_BREAKOUT_BUY");
   }
   else if(bid < lowest) {
      double sl = bid + sl_puntos * _Point;
      trade.Sell(LoteInicial, _Symbol, 0, sl, 0, "BSR_BREAKOUT_SELL");
   }
}

void GestionarIndividual() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong t = PositionGetTicket(i);
      if(!PositionSelectByTicket(t) || PositionGetInteger(POSITION_MAGIC) != MagicPrincipal) continue;
      double profit = PositionGetDouble(POSITION_PROFIT);
      double pOpen  = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl     = PositionGetDouble(POSITION_SL);
      long   tipo   = PositionGetInteger(POSITION_TYPE);
      if(profit >= ProfitObjetivo) { trade.PositionClose(t); continue; }
      if(profit >= BE_Activacion) {
         double g = GarantiaBE * 10 * _Point;
         double nBE = (tipo == POSITION_TYPE_BUY) ? pOpen + g : pOpen - g;
         if(tipo == POSITION_TYPE_BUY  && sl < nBE) trade.PositionModify(t, nBE, 0);
         if(tipo == POSITION_TYPE_SELL && (sl == 0 || sl > nBE)) trade.PositionModify(t, nBE, 0);
      }
      if(ActivarTrailing && profit >= BE_Activacion) {
         double b = SymbolInfoDouble(_Symbol, SYMBOL_BID), a = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         if(tipo == POSITION_TYPE_BUY) { double ns = b - DistanciaTrailing*_Point; if(ns > sl + SaltoDelTrailing*_Point) trade.PositionModify(t, ns, 0); }
         else { double ns = a + DistanciaTrailing*_Point; if(sl==0||ns < sl - SaltoDelTrailing*_Point) trade.PositionModify(t, ns, 0); }
      }
   }
}

int ContarPosiciones() { int c=0; for(int i=0;i<PositionsTotal();i++) if(PositionSelectByTicket(PositionGetTicket(i))&&PositionGetInteger(POSITION_MAGIC)==MagicPrincipal) c++; return c; }

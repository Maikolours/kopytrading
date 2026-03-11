//+------------------------------------------------------------------+
//|             KOPYTRADE_XAUUSD_Ametralladora v2.1                  |
//|        MOTOR DE HEDGING INTELIGENTE - CYCLE CLEANER              |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Bot Oficial"
#property version   "2.10"
#property strict
#property description "La Ametralladora | EL REY DEL ORO"

#include <Trade\Trade.mqh>

//--- LICENCIA ---
input group "=== LICENCIA KOPYTRADE ==="
input long     CuentaDemo         = 0;      // N├║mero de cuenta DEMO de MT5
input long     CuentaReal         = 0;      // N├║mero de cuenta REAL de MT5

//--- RELOJ ---
input group "=== RELOJ PER├ìODO OPERATIVO (HORA BROKER) ==="
input int      HoraInicio         = 9;
input int      HoraFin            = 21;

//--- GESTI├ôN DE RIESGO ---
input group "=== GESTI├ôN DE RIESGO (ESTRATEGIA SCALPING) ==="
input double   LoteInicial        = 0.01;
input double   StopLossUSD        = 50.0;   // Protecci├│n m├íxima en $ por lote 0.01
input double   ProfitObjetivo     = 5.0;    // Objetivo del primer disparo

//--- ESTRATEGIA (ORACLE MODE) ---
input group "=== ESTRATEGIA AMETRALLADORA (HEDGING) ==="
input int      EMA_Referencia     = 14;     // EMA para detectar tendencia
input int      DistanciaPipsHedge = 80;     // Distancia del escudo (8 pips)
input double   LoteHedge          = 0.02;   // Tama├▒o de la posici├│n de cobertura
input double   ProfitHedge        = 3.0;    // Objetivo para cerrar relevo

//--- GESTI├ôN DE BENEFICIO ---
input group "=== GESTI├ôN DE BENEFICIO (BE & TRAILING) ==="
input double   BE_Activacion      = 2.0;    
input double   GarantiaBE         = 0.5;    
input bool     ActivarTrailing    = true;   
input int      DistanciaTrailing  = 60;     // 6 pips (Oro es r├ípido)
input int      SaltoDelTrailing   = 20;     // 2 pips

//--- AVANZADO ---
input group "=== CONFIGURACI├ôN AVANZADA ==="
input int      MaxPosiciones      = 4;      // Incluyendo el hedge
input int      StopLevelManual    = 50;
input long     MagicPrincipal     = 777112;

CTrade trade;
bool   licenseValid  = false;
int    emaHandle     = INVALID_HANDLE;

//+------------------------------------------------------------------+
bool CheckTrialAndLicense() {
   long cuenta = AccountInfoInteger(ACCOUNT_LOGIN);
   if(cuenta == CuentaDemo || cuenta == CuentaReal) return true;
   if(AccountInfoInteger(ACCOUNT_TRADE_MODE) != ACCOUNT_TRADE_MODE_DEMO) {
      Alert("ÔØî LICENCIA REQUERIDA PARA REAL. kopytrade.com");
      return false;
   }
   string gVarName = "KOPYTRADE_AMTR_TRIAL_START";
   datetime firstRun;
   if(!GlobalVariableCheck(gVarName)) {
      GlobalVariableSet(gVarName, (double)TimeCurrent());
      firstRun = TimeCurrent();
   } else firstRun = (datetime)GlobalVariableGet(gVarName);
   
   int dias = (int)((TimeCurrent() - firstRun) / 86400);
   if(dias <= 30) return true;
   Alert("ÔÅ░ TRIAL EXPIRADO. kopytrade.com");
   return false;
}

int OnInit() {
   if(!CheckTrialAndLicense()) return(INIT_FAILED);
   emaHandle = iMA(_Symbol, _Period, EMA_Referencia, 0, MODE_EMA, PRICE_CLOSE);
   licenseValid = true;
   trade.SetExpertMagicNumber(MagicPrincipal);
   trade.SetTypeFillingBySymbol(_Symbol);
   return(INIT_SUCCEEDED);
}

void OnTick() {
   if(!licenseValid) return;
   GestionarIndividual();
   LimpiarPendientesHuerfanos();
   
   int nTotal = ContarPosiciones();
   int nPendientes = ContarPendientes();
   
   if(nTotal >= 1 && nTotal < MaxPosiciones && nPendientes == 0) ColocarEscudoInteligente();
   if(nTotal == 0 && nPendientes == 0 && EstaEnHorario()) AbrirEntradaInicial();
}

void AbrirEntradaInicial() {
   double ma[2]; ArraySetAsSeries(ma, true);
   if(CopyBuffer(emaHandle, 0, 0, 2, ma) > 1) {
      if(SymbolInfoDouble(_Symbol, SYMBOL_BID) > ma[0])
         trade.Buy(LoteInicial, _Symbol, 0, 0, 0, "AMTR_PRINCIPAL");
      else
         trade.Sell(LoteInicial, _Symbol, 0, 0, 0, "AMTR_PRINCIPAL");
   }
}

void ColocarEscudoInteligente() {
   int nBuys=0, nSells=0; double priceBuy=0, priceSell=0;
   for(int i=0; i<PositionsTotal(); i++) {
      if(!PositionSelectByTicket(PositionGetTicket(i)) || PositionGetInteger(POSITION_MAGIC)!=MagicPrincipal) continue;
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) { nBuys++; priceBuy=PositionGetDouble(POSITION_PRICE_OPEN); }
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL) { nSells++; priceSell=PositionGetDouble(POSITION_PRICE_OPEN); }
   }
   double ask=SymbolInfoDouble(_Symbol, SYMBOL_ASK), bid=SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double dist=DistanciaPipsHedge*_Point, minDist=StopLevelManual*_Point;
   if(nBuys > nSells) {
      double p=priceBuy-dist; if(p>bid-minDist) p=bid-minDist;
      trade.SellStop(LoteHedge, p, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "AMTR_RELEVO");
   }
   else if(nSells > nBuys) {
      double p=priceSell+dist; if(p<ask+minDist) p=ask+minDist;
      trade.BuyStop(LoteHedge, p, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "AMTR_RELEVO");
   }
}

void GestionarIndividual() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong t = PositionGetTicket(i);
      if(!PositionSelectByTicket(t) || PositionGetInteger(POSITION_MAGIC) != MagicPrincipal) continue;
      double profit = PositionGetDouble(POSITION_PROFIT);
      double pOpen  = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl     = PositionGetDouble(POSITION_SL);
      string comment = PositionGetString(POSITION_COMMENT);
      long tipo = PositionGetInteger(POSITION_TYPE);
      double obj = (StringFind(comment, "PRINCIPAL") >= 0) ? ProfitObjetivo : ProfitHedge;
      if(profit >= obj) { trade.PositionClose(t); continue; }
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

void LimpiarPendientesHuerfanos() {
   if(ContarPosiciones() > 0) return;
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC) == MagicPrincipal) trade.OrderDelete(OrderGetTicket(i));
   }
}
bool EstaEnHorario() { MqlDateTime dt; TimeToStruct(TimeCurrent(),dt); return(dt.hour >= HoraInicio && dt.hour < HoraFin); }
int ContarPosiciones() { int c=0; for(int i=0;i<PositionsTotal();i++) if(PositionSelectByTicket(PositionGetTicket(i))&&PositionGetInteger(POSITION_MAGIC)==MagicPrincipal) c++; return c; }
int ContarPendientes() { int c=0; for(int i=0;i<OrdersTotal();i++) if(OrderSelect(OrderGetTicket(i))&&OrderGetInteger(ORDER_MAGIC)==MagicPrincipal) c++; return c; }

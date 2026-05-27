//+------------------------------------------------------------------+
//|                                     MSC_NEO_SHIELD_V6_ANTIBLOCK  |
//|   VERSIÓN FINAL: ANTI-CONGELACIÓN + GESTIÓN AGRESIVA             |
//+------------------------------------------------------------------+
#property copyright "Master Scalping Hybrid"
#property version   "6.20"
#property strict

#include <Trade\Trade.mqh>

input group "=== RELOJ Y HORARIO ==="
input int      HoraInicio         = 0;      
input int      HoraFin            = 23;     

input group "=== GESTIÓN DE BENEFICIOS ==="
input double   LoteInicial            = 0.01;   
input double   ProfitCierreIndividual = 1.5;    // Cobrar rápido $1.5
input double   ProfitObjetivoCesta    = 5.0;    // Limpiar todo al llegar a $5
input double   StopLossGlobal         = 20.0;   

input group "=== PROTECCIÓN (BE Y TRAILING) ==="
input double   BE_Activacion          = 1.0;    // A los $1.0 pone el SL
input double   GarantiaBE             = 0.1;    // Asegura solo un poco para que el broker acepte
input int      TrailingPips           = 20;     
input int      TrailingStep           = 5;      
input int      StopLevelManual        = 300;    // Clave para evitar el bloqueo del PC

input group "=== ESCUDO (HEDGE) ==="
input int      DistanciaPipsHedge     = 25;     
input long     MagicNeo               = 555666; // Magic nuevo para empezar limpio

CTrade trade;
datetime ultimaVela = 0;
datetime tiempoEspera = 0; // Para el limitador de errores

void OnTick() {
   // 1. LIMITADOR ANTI-BLOQUEO (Si hubo error, espera para no congelar el PC)
   if(TimeCurrent() < tiempoEspera) return;

   // 2. GESTIÓN DE BENEFICIOS (INDIVIDUAL Y CESTA)
   double pTotal = CalcularProfitTotal();
   if(ContarPosiciones() > 0) {
      GestionarCierreIndividual();
      if(pTotal >= ProfitObjetivoCesta) { CerrarTodoYLimpiar("CESTA OK"); return; }
      if(pTotal <= -StopLossGlobal) { CerrarTodoYLimpiar("STOP GLOBAL"); return; }
   }

   // 3. PROTECCIÓN DE COLUMNA S/L (BE Y TRAILING)
   if(!GestionarProteccionSegura()) {
      tiempoEspera = TimeCurrent() + 5; // Si falla, no hace nada durante 5 segundos
      return;
   }

   // 4. VIGILANCIA DEL ESCUDO
   VerificarEscudoSincronizado();

   // 5. ENTRADA INICIAL
   if(ContarPosiciones() == 0 && ContarPendientes() == 0) {
      if(ultimaVela != iTime(_Symbol, _Period, 0)) {
         if(AbrirConEscudoInmediato()) ultimaVela = iTime(_Symbol, _Period, 0);
      }
   }
}

void GestionarCierreIndividual() {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == MagicNeo) {
         if(PositionGetDouble(POSITION_PROFIT) >= ProfitCierreIndividual) {
            trade.PositionClose(PositionGetTicket(i));
         }
      }
   }
}

bool GestionarProteccionSegura() {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == MagicNeo) {
         ulong t = PositionGetTicket(i);
         double sl = PositionGetDouble(POSITION_SL);
         double po = PositionGetDouble(POSITION_PRICE_OPEN);
         double pr = PositionGetDouble(POSITION_PROFIT);
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         long tipo = PositionGetInteger(POSITION_TYPE);

         // BREAK EVEN
         if(pr >= BE_Activacion && sl == 0) {
            double nBE = (tipo == POSITION_TYPE_BUY) ? po + (GarantiaBE*_Point*10) : po - (GarantiaBE*_Point*10);
            if(!trade.PositionModify(t, nBE, 0)) return false; 
         }
         // TRAILING
         if(sl > 0) {
            if(tipo == POSITION_TYPE_BUY) {
               double nSL = bid - (TrailingPips*_Point*10);
               if(nSL > sl + (TrailingStep*_Point*10)) if(!trade.PositionModify(t, nSL, 0)) return false;
            } else {
               double nSL = ask + (TrailingPips*_Point*10);
               if(nSL < sl - (TrailingStep*_Point*10)) if(!trade.PositionModify(t, nSL, 0)) return false;
            }
         }
      }
   }
   return true;
}

bool AbrirConEscudoInmediato() {
   double ma[]; ArraySetAsSeries(ma, true);
   int h = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   bool res = false;
   if(CopyBuffer(h, 0, 0, 1, ma) > 0) {
      double dist = DistanciaPipsHedge * _Point * 10;
      if(SymbolInfoDouble(_Symbol, SYMBOL_BID) > ma[0]) {
         if(trade.Buy(LoteInicial, _Symbol, 0, 0, 0, "PRI")) trade.SellStop(LoteInicial, SymbolInfoDouble(_Symbol, SYMBOL_BID)-dist, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "SHIELD");
         res = true;
      } else {
         if(trade.Sell(LoteInicial, _Symbol, 0, 0, 0, "PRI")) trade.BuyStop(LoteInicial, SymbolInfoDouble(_Symbol, SYMBOL_ASK)+dist, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "SHIELD");
         res = true;
      }
   }
   IndicatorRelease(h);
   return res;
}

void VerificarEscudoSincronizado() {
   int c=0, v=0, ps=0, pb=0; double pRef=0;
   for(int i=0; i<PositionsTotal(); i++) {
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == MagicNeo) {
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) { c++; pRef=PositionGetDouble(POSITION_PRICE_OPEN); }
         else { v++; pRef=PositionGetDouble(POSITION_PRICE_OPEN); }
      }
   }
   for(int i=0; i<OrdersTotal(); i++) {
      if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC) == MagicNeo) {
         if(OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_BUY_STOP) pb++;
         if(OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_SELL_STOP) ps++;
      }
   }
   double d = DistanciaPipsHedge*_Point*10;
   if(c>0 && v==0 && ps==0) trade.SellStop(LoteInicial, pRef-d, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "SHIELD");
   if(v>0 && c==0 && pb==0) trade.BuyStop(LoteInicial, pRef+d, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "SHIELD");
}

double CalcularProfitTotal() { double p=0; for(int i=0; i<PositionsTotal(); i++) if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC)==MagicNeo) p+=PositionGetDouble(POSITION_PROFIT); return p; }
int ContarPosiciones() { int c=0; for(int i=0; i<PositionsTotal(); i++) if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC)==MagicNeo) c++; return c; }
int ContarPendientes() { int c=0; for(int i=0; i<OrdersTotal(); i++) if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC)==MagicNeo) c++; return c; }
void CerrarTodoYLimpiar(string m) {
   for(int i=PositionsTotal()-1; i>=0; i--) if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC)==MagicNeo) trade.PositionClose(PositionGetTicket(i));
   for(int i=OrdersTotal()-1; i>=0; i--) if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC)==MagicNeo) trade.OrderDelete(OrderGetTicket(i));
   Print(m);
}
//+------------------------------------------------------------------+
//|                                     MSC_NEO_SHIELD_V6_OMNI_CLEAN |
//|   VERSIÓN 6.42: CADA OVEJA CON SU PAREJA (SINCRONIZACIÓN TOTAL)  |
//+------------------------------------------------------------------+
#property copyright "Master Scalping Hybrid"
#property version   "6.42"
#property strict

#include <Trade\Trade.mqh>

input group "=== GESTIÓN DE BENEFICIOS ==="
input double   ProfitCierreIndividual = 1.0;    
input double   ProfitObjetivoCesta    = 5.0;    

input group "=== SEGUROS Y DISTANCIAS ==="
input double   BE_Activacion          = 1.5;    
input int      DistanciaPipsHedge     = 25;     
input double   LoteOperativo          = 0.01;

CTrade trade;
datetime ultimaVela = 0;

void OnTick() {
   int totalBuy = 0, totalSell = 0;
   double pTotal = 0;

   // --- 1. GESTIÓN DE POSICIONES ACTIVAS ---
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
         double pr = PositionGetDouble(POSITION_PROFIT);
         double po = PositionGetDouble(POSITION_PRICE_OPEN);
         ENUM_POSITION_TYPE tipo = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         
         pTotal += pr;
         if(tipo == POSITION_TYPE_BUY) totalBuy++; else totalSell++;

         // Cierre individual y BE
         if(pr >= ProfitCierreIndividual) { trade.PositionClose(ticket); continue; }
         if(pr >= BE_Activacion && PositionGetDouble(POSITION_SL) == 0) trade.PositionModify(ticket, po, 0);
      }
   }

   // --- 2. LÓGICA DE PAREJAS (Limpieza y Sincronización) ---
   // Si no hay compras, no puede haber Sell Stops huérfanos
   if(totalBuy == 0) BorrarPendientesTipo(ORDER_TYPE_SELL_STOP);
   // Si no hay ventas, no puede haber Buy Stops huérfanos
   if(totalSell == 0) BorrarPendientesTipo(ORDER_TYPE_BUY_STOP);

   // --- 3. RE-SINCRONIZAR ESCUDOS CORRECTOS ---
   SincronizarEscudosPareja(totalBuy, totalSell);

   // --- 4. ENTRADA NUEVA (Cada 15 min) ---
   if(totalBuy == 0 && totalSell == 0 && ContarPendientes() == 0) {
      if(ultimaVela != iTime(_Symbol, _Period, 0)) {
         if(AbrirConEscudoInmediato()) ultimaVela = iTime(_Symbol, _Period, 0);
      }
   }
}

void BorrarPendientesTipo(ENUM_ORDER_TYPE tipo) {
   for(int i=OrdersTotal()-1; i>=0; i--) {
      ulong t = OrderGetTicket(i);
      if(OrderSelect(t) && OrderGetString(ORDER_SYMBOL) == _Symbol) {
         if(OrderGetInteger(ORDER_TYPE) == tipo) trade.OrderDelete(t);
      }
   }
}

void SincronizarEscudosPareja(int buys, int sells) {
   double dist = DistanciaPipsHedge * _Point * 10;
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   if(buys > 0 && ContarPendientesTipo(ORDER_TYPE_SELL_STOP) == 0) {
      trade.SellStop(LoteOperativo, bid - dist, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "OMNI_SHIELD");
   }
   if(sells > 0 && ContarPendientesTipo(ORDER_TYPE_BUY_STOP) == 0) {
      trade.BuyStop(LoteOperativo, ask + dist, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "OMNI_SHIELD");
   }
}

int ContarPendientesTipo(ENUM_ORDER_TYPE tipo) {
   int c=0;
   for(int i=OrdersTotal()-1; i>=0; i--) {
      if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_TYPE) == tipo && OrderGetString(ORDER_SYMBOL) == _Symbol) c++;
   }
   return c;
}

bool AbrirConEscudoInmediato() {
   double ma[]; ArraySetAsSeries(ma, true);
   int h = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   if(CopyBuffer(h, 0, 0, 1, ma) <= 0) { IndicatorRelease(h); return false; }
   
   if(SymbolInfoDouble(_Symbol, SYMBOL_BID) > ma[0]) trade.Buy(LoteOperativo, _Symbol, 0, 0, 0, "OMNI_PRI");
   else trade.Sell(LoteOperativo, _Symbol, 0, 0, 0, "OMNI_PRI");
   
   IndicatorRelease(h); return true;
}

int ContarPendientes() {
   int c=0;
   for(int i=0; i<OrdersTotal(); i++) {
      if(OrderSelect(OrderGetTicket(i)) && OrderGetString(ORDER_SYMBOL) == _Symbol) c++;
   }
   return c;
}
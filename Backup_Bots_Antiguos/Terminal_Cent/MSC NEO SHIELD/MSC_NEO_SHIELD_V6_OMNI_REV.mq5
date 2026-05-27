//+------------------------------------------------------------------+
//|                                     MSC_NEO_SHIELD_V6_OMNI_REV   |
//|   VERSIÓN 6.40: GESTIÓN TOTAL + COBERTURA POR TENDENCIA          |
//+------------------------------------------------------------------+
#property copyright "Master Scalping Hybrid"
#property version   "6.40"
#property strict

#include <Trade\Trade.mqh>

input group "=== GESTIÓN DE BENEFICIOS ==="
input double   ProfitCierreIndividual = 1.0;    // Cierre rápido de cada operación
input double   ProfitObjetivoCesta    = 5.0;    // Cierre de todo el conjunto
input double   StopLossGlobal         = 50.0;   // Máxima pérdida permitida
input int      StopLevelManual        = 500;    

input group "=== PROTECCIÓN (BE Y TRAILING) ==="
input double   BE_Activacion          = 1.5;    // A los $1.5 pone el S/L en entrada
input int      TrailingPips           = 20;     
input int      TrailingStep           = 5;      

input group "=== ESCUDO Y REVERSIÓN ==="
input int      DistanciaPipsHedge     = 25;     // Escudo SellStop/BuyStop
input int      DistanciaReversion     = 100;    // Si el precio se aleja 100 pips (10$)
input double   LoteOperativo          = 0.01;

CTrade trade;
datetime ultimaVela = 0;

void OnTick() {
   double pTotal = 0;
   int totalPos = 0;
   double precioVentaMasAlto = 0;
   double precioCompraMasBajo = 999999;

   // --- PARTE 1: GESTIÓN DE CUALQUIER OPERACIÓN EN EL GRÁFICO ---
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
         
         double pr = PositionGetDouble(POSITION_PROFIT);
         double sl = PositionGetDouble(POSITION_SL);
         double po = PositionGetDouble(POSITION_PRICE_OPEN);
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         ENUM_POSITION_TYPE tipo = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         
         pTotal += pr;
         totalPos++;

         // Rastrear extremos para la lógica de reversión
         if(tipo == POSITION_TYPE_SELL && po > precioVentaMasAlto) precioVentaMasAlto = po;
         if(tipo == POSITION_TYPE_BUY && po < precioCompraMasBajo) precioCompraMasBajo = po;

         // 1. Cierre Individual
         if(pr >= ProfitCierreIndividual) {
            trade.PositionClose(ticket);
            continue;
         }

         // 2. Break Even
         if(pr >= BE_Activacion && sl == 0) {
            trade.PositionModify(ticket, po, 0);
         }
         
         // 3. Trailing Stop
         if(sl > 0) {
            if(tipo == POSITION_TYPE_BUY) {
               double nSL = bid - (TrailingPips*_Point*10);
               if(nSL > sl + (TrailingStep*_Point*10)) trade.PositionModify(ticket, nSL, 0);
            } else {
               double nSL = ask + (TrailingPips*_Point*10);
               if(nSL < sl - (TrailingStep*_Point*10)) trade.PositionModify(ticket, nSL, 0);
            }
         }
      }
   }

   // --- PARTE 2: GESTIÓN DE CESTA ---
   if(totalPos > 0) {
      if(pTotal >= ProfitObjetivoCesta) { CerrarTodoYLimpiar("CESTA OK"); return; }
      if(pTotal <= -StopLossGlobal) { CerrarTodoYLimpiar("STOP GLOBAL"); return; }
   }

   // --- PARTE 3: LÓGICA DE REVERSIÓN (ENTRADAS A FAVOR DE TENDENCIA) ---
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(totalPos > 0) {
      // Si el precio sube 10$ por encima de la mejor Venta -> Abrimos Compra
      if(precioVentaMasAlto > 0 && ask > (precioVentaMasAlto + DistanciaReversion * _Point * 10)) {
         if(ContarTipo(POSITION_TYPE_BUY) == 0) trade.Buy(LoteOperativo, _Symbol, 0, 0, 0, "OMNI_REV_BUY");
      }
      // Si el precio baja 10$ por debajo de la mejor Compra -> Abrimos Venta
      if(precioCompraMasBajo < 999999 && bid < (precioCompraMasBajo - DistanciaReversion * _Point * 10)) {
         if(ContarTipo(POSITION_TYPE_SELL) == 0) trade.Sell(LoteOperativo, _Symbol, 0, 0, 0, "OMNI_REV_SELL");
      }
   }

   // --- PARTE 4: ESCUDO Y ENTRADA INICIAL ---
   VerificarEscudoSincronizado();

   if(totalPos == 0 && ContarPendientes() == 0) {
      if(ultimaVela != iTime(_Symbol, _Period, 0)) {
         if(AbrirConEscudoInmediato()) ultimaVela = iTime(_Symbol, _Period, 0);
      }
   }
}

// --- FUNCIONES AUXILIARES ---

bool AbrirConEscudoInmediato() {
   double ma[]; ArraySetAsSeries(ma, true);
   int h = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   if(CopyBuffer(h, 0, 0, 1, ma) <= 0) { IndicatorRelease(h); return false; }
   
   double dist = DistanciaPipsHedge * _Point * 10;
   bool res = false;
   if(SymbolInfoDouble(_Symbol, SYMBOL_BID) > ma[0]) {
      if(trade.Buy(LoteOperativo, _Symbol, 0, 0, 0, "OMNI_PRI")) {
         trade.SellStop(LoteOperativo, SymbolInfoDouble(_Symbol, SYMBOL_BID)-dist, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "OMNI_SHIELD");
         res = true;
      }
   } else {
      if(trade.Sell(LoteOperativo, _Symbol, 0, 0, 0, "OMNI_PRI")) {
         trade.BuyStop(LoteOperativo, SymbolInfoDouble(_Symbol, SYMBOL_ASK)+dist, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "OMNI_SHIELD");
         res = true;
      }
   }
   IndicatorRelease(h); return res;
}

void VerificarEscudoSincronizado() {
   int pos=0, pend=0; double pRef=0;
   for(int i=0; i<PositionsTotal(); i++) {
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL)==_Symbol) {
         pos++; pRef=PositionGetDouble(POSITION_PRICE_OPEN);
      }
   }
   for(int i=0; i<OrdersTotal(); i++) {
      ulong t = OrderGetTicket(i);
      if(OrderSelect(t) && OrderGetString(ORDER_SYMBOL) == _Symbol) pend++;
   }
   if(pos > 0 && pend == 0) {
      double d = DistanciaPipsHedge*_Point*10;
      trade.BuyStop(LoteOperativo, pRef+d, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "OMNI_SHIELD");
      trade.SellStop(LoteOperativo, pRef-d, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "OMNI_SHIELD");
   }
}

int ContarTipo(ENUM_POSITION_TYPE tipo) {
   int c=0;
   for(int i=0; i<PositionsTotal(); i++) {
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL)==_Symbol) {
         if(PositionGetInteger(POSITION_TYPE) == tipo) c++;
      }
   }
   return c;
}

int ContarPendientes() {
   int c=0;
   for(int i=0; i<OrdersTotal(); i++) {
      ulong t = OrderGetTicket(i);
      if(OrderSelect(t) && OrderGetString(ORDER_SYMBOL) == _Symbol) c++;
   }
   return c;
}

void CerrarTodoYLimpiar(string m) {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong t = PositionGetTicket(i);
      if(PositionSelectByTicket(t) && PositionGetString(POSITION_SYMBOL)==_Symbol) trade.PositionClose(t);
   }
   for(int i=OrdersTotal()-1; i>=0; i--) {
      ulong t = OrderGetTicket(i);
      if(OrderSelect(t) && OrderGetString(ORDER_SYMBOL)==_Symbol) trade.OrderDelete(t);
   }
   Print(m);
}
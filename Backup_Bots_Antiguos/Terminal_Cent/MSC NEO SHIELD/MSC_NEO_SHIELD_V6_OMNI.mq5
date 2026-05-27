//+------------------------------------------------------------------+
//|                                     MSC_NEO_SHIELD_V6_OMNI_FIXED |
//|   GESTIÓN TOTAL MT5: CORREGIDA Y SIN ERRORES DE COMPILACIÓN      |
//+------------------------------------------------------------------+
#property copyright "Master Scalping Hybrid"
#property version   "6.31"
#property strict

#include <Trade\Trade.mqh>

input group "=== GESTIÓN DE BENEFICIOS ==="
input double   ProfitCierreIndividual = 1.0;    
input double   ProfitObjetivoCesta    = 5.0;    
input int      StopLevelManual        = 500;    

input group "=== PROTECCIÓN (BE Y TRAILING) ==="
input double   BE_Activacion          = 0.7;    
input int      TrailingPips           = 20;     
input int      TrailingStep           = 5;      

input group "=== ESCUDO (HEDGE) ==="
input double   LoteHedge              = 0.01;
input int      DistanciaPipsHedge     = 25;     

CTrade trade;
datetime ultimaVela = 0;

void OnTick() {
   // --- PARTE 1: GESTIÓN DE CUALQUIER OPERACIÓN EN ESTE SÍMBOLO ---
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol) {
            
            double pr = PositionGetDouble(POSITION_PROFIT);
            double sl = PositionGetDouble(POSITION_SL);
            double po = PositionGetDouble(POSITION_PRICE_OPEN);
            double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            ENUM_POSITION_TYPE tipo = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

            // 1. Cierre Individual ($1.00)
            if(pr >= ProfitCierreIndividual) {
               trade.PositionClose(ticket);
               continue;
            }

            // 2. Break Even ($0.70)
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
   }

   // --- PARTE 2: GESTIÓN DE CESTA (Suma de todo el símbolo) ---
   double pTotal = 0;
   int totalPos = 0;
   for(int i=0; i<PositionsTotal(); i++) {
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
         pTotal += PositionGetDouble(POSITION_PROFIT);
         totalPos++;
      }
   }

   if(totalPos > 0) {
      if(pTotal >= ProfitObjetivoCesta) { CerrarTodoYLimpiar("CESTA OK"); return; }
   }

   // --- PARTE 3: ESCUDO Y ENTRADA ---
   VerificarEscudoSincronizado();

   if(totalPos == 0 && ContarPendientes() == 0) {
      if(ultimaVela != iTime(_Symbol, _Period, 0)) {
         if(AbrirConEscudoInmediato()) ultimaVela = iTime(_Symbol, _Period, 0);
      }
   }
}

bool AbrirConEscudoInmediato() {
   double ma[]; ArraySetAsSeries(ma, true);
   int h = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   if(CopyBuffer(h, 0, 0, 1, ma) <= 0) { IndicatorRelease(h); return false; }
   
   double dist = DistanciaPipsHedge * _Point * 10;
   bool res = false;
   if(SymbolInfoDouble(_Symbol, SYMBOL_BID) > ma[0]) {
      if(trade.Buy(0.01, _Symbol, 0, 0, 0, "OMNI_PRI")) {
         trade.SellStop(LoteHedge, SymbolInfoDouble(_Symbol, SYMBOL_BID)-dist, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "OMNI_SHIELD");
         res = true;
      }
   } else {
      if(trade.Sell(0.01, _Symbol, 0, 0, 0, "OMNI_PRI")) {
         trade.BuyStop(LoteHedge, SymbolInfoDouble(_Symbol, SYMBOL_ASK)+dist, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "OMNI_SHIELD");
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
      trade.BuyStop(LoteHedge, pRef+d, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "OMNI_SHIELD");
      trade.SellStop(LoteHedge, pRef-d, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "OMNI_SHIELD");
   }
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
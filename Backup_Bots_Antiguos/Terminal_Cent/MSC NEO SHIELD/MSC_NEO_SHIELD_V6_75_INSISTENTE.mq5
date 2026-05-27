//+------------------------------------------------------------------+
//|                                 MSC_NEO_SHIELD_V6_75_INSISTENTE  |
//|   SINCRONIZACIÓN CONTINUA + CADA OVEJA CON SU PAREJA             |
//+------------------------------------------------------------------+
#property copyright "Master Scalping Hybrid"
#property version   "6.75"
#property strict

#include <Trade\Trade.mqh>

input group "=== 1. GESTIÓN DE RÁFAGA (DINERO) ==="
input double   BeneficioCierre        = 1.0;    
input double   ProfitCesta            = 5.0;    

input group "=== 2. CONFIGURACIÓN DEL BREAK EVEN ==="
input double   BE_Activacion          = 1.2;    
input double   BE_PipsGarantia        = 0.5;    

input group "=== 3. CONFIGURACIÓN DEL TRAILING STOP ==="
input bool     ActivarTrailing        = true;   
input int      TrailingPips           = 20;     
input int      TrailingStep           = 5;      

input group "=== 4. EL ESCUDO (PAREJAS) ==="
input double   Lote                   = 0.01;   
input int      DistanciaEscudo        = 20;     // Lo bajamos a 20 por defecto
input bool     LimpiarHuerfanas       = true;   

CTrade trade;

void OnTick() {
   int posBuy = 0, posSell = 0;
   double profitTotal = 0;
   double precioVenta = 0, precioCompra = 0;
   
   // --- PARTE A: GESTIÓN Y RECUENTO ---
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong t = PositionGetTicket(i);
      if(PositionSelectByTicket(t) && PositionGetString(POSITION_SYMBOL) == _Symbol) {
         double pr = PositionGetDouble(POSITION_PROFIT);
         double sl = PositionGetDouble(POSITION_SL);
         double po = PositionGetDouble(POSITION_PRICE_OPEN);
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         ENUM_POSITION_TYPE tipo = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         
         profitTotal += pr;
         if(tipo == POSITION_TYPE_BUY) { posBuy++; precioCompra = po; } 
         else { posSell++; precioVenta = po; }

         if(pr >= BeneficioCierre) { trade.PositionClose(t); continue; }
         
         if(pr >= BE_Activacion && sl == 0) {
            double nuevoSL = (tipo == POSITION_TYPE_BUY) ? po + BE_PipsGarantia : po - BE_PipsGarantia;
            trade.PositionModify(t, nuevoSL, 0);
         }
         
         if(ActivarTrailing && sl > 0) {
            double dist = TrailingPips * _Point * 10;
            double paso = TrailingStep * _Point * 10;
            if(tipo == POSITION_TYPE_BUY && (bid - dist > sl + paso)) trade.PositionModify(t, bid - dist, 0);
            if(tipo == POSITION_TYPE_SELL && (ask + dist < sl - paso)) trade.PositionModify(t, ask + dist, 0);
         }
      }
   }

   // --- PARTE B: LA MEJORA - SINCRONIZACIÓN FORZADA DE ESCUDOS ---
   // Si hay una venta pero no hay un BuyStop, lo ponemos YA.
   if(posSell > 0 && ContarPendientesTipo(ORDER_TYPE_BUY_STOP) == 0) {
       double precioEscudo = SymbolInfoDouble(_Symbol, SYMBOL_ASK) + (DistanciaEscudo * _Point * 10);
       trade.BuyStop(Lote, precioEscudo, _Symbol);
       Print("OMNI: Escudo BuyStop repuesto para la venta abierta.");
   }
   // Si hay una compra pero no hay un SellStop, lo ponemos YA.
   if(posBuy > 0 && ContarPendientesTipo(ORDER_TYPE_SELL_STOP) == 0) {
       double precioEscudo = SymbolInfoDouble(_Symbol, SYMBOL_BID) - (DistanciaEscudo * _Point * 10);
       trade.SellStop(Lote, precioEscudo, _Symbol);
       Print("OMNI: Escudo SellStop repuesto para la compra abierta.");
   }

   // --- PARTE C: LIMPIEZA DE HUÉRFANAS ---
   if(LimpiarHuerfanas) {
      if(posBuy == 0) BorrarPendientesPorTipo(ORDER_TYPE_SELL_STOP);
      if(posSell == 0) BorrarPendientesPorTipo(ORDER_TYPE_BUY_STOP);
   }

   // --- PARTE D: ENTRADA NUEVA ---
   if(posBuy == 0 && posSell == 0 && ContarPendientes() == 0) {
      // (Lógica de entrada igual que la 6.7)
      double close1 = iClose(_Symbol, _Period, 1);
      if(SymbolInfoDouble(_Symbol, SYMBOL_BID) > close1) trade.Buy(Lote, _Symbol);
      else trade.Sell(Lote, _Symbol);
   }
}

// Funciones auxiliares necesarias para el conteo...
int ContarPendientesTipo(ENUM_ORDER_TYPE tipo) {
   int c=0;
   for(int i=OrdersTotal()-1; i>=0; i--) {
      if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_TYPE) == tipo && OrderGetString(ORDER_SYMBOL) == _Symbol) c++;
   }
   return c;
}

void BorrarPendientesPorTipo(ENUM_ORDER_TYPE tipo) {
   for(int i=OrdersTotal()-1; i>=0; i--) {
      ulong t = OrderGetTicket(i);
      if(OrderSelect(t) && OrderGetString(ORDER_SYMBOL) == _Symbol && OrderGetInteger(ORDER_TYPE) == tipo) trade.OrderDelete(t);
   }
}

int ContarPendientes() {
   int c=0;
   for(int i=OrdersTotal()-1; i>=0; i--) {
      if(OrderSelect(OrderGetTicket(i)) && OrderGetString(ORDER_SYMBOL) == _Symbol) c++;
   }
   return c;
}
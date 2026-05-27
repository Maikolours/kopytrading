//+------------------------------------------------------------------+
//|                                  MSC_NEO_SHIELD_V6_7_COMMANDER   |
//|   CONTROL TOTAL + RÁFAGA RÁPIDA + LIMPIEZA + SIN ERRORES MT5     |
//+------------------------------------------------------------------+
#property copyright "Master Scalping Hybrid"
#property version   "6.70"
#property strict

#include <Trade\Trade.mqh>

input group "=== 1. GESTIÓN DE RÁFAGA (DINERO) ==="
input double   BeneficioCierre        = 1.0;    // Cerrar operación al ganar este dinero ($)
input double   ProfitCesta            = 5.0;    // Cerrar todo si el conjunto gana esto ($)

input group "=== 2. CONFIGURACIÓN DEL BREAK EVEN ==="
input double   BE_Activacion          = 1.2;    // A partir de cuánto beneficio ($) poner el seguro
input double   BE_PipsGarantia        = 0.5;    // Cuántos $ asegurar por encima del precio de entrada

input group "=== 3. CONFIGURACIÓN DEL TRAILING STOP ==="
input bool     ActivarTrailing        = true;   // ¿Quieres que el Stop Loss persiga al precio?
input int      TrailingPips           = 20;     // Distancia de seguridad (Pips)
input int      TrailingStep           = 5;      // Salto mínimo para mover el Stop (Pips)

input group "=== 4. EL ESCUDO (PAREJAS) ==="
input double   Lote                   = 0.01;   // Tamaño de la operación inicial
input int      DistanciaEscudo        = 25;     // Distancia del SellStop/BuyStop (Pips)
input bool     LimpiarHuerfanas       = true;   // Borrar "cada oveja sin su pareja" al instante

CTrade trade;

void OnTick() {
   int posBuy = 0, posSell = 0;
   double profitTotal = 0;
   
   // --- PARTE A: GESTIÓN DE LAS OPERACIONES ACTIVAS ---
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
         if(tipo == POSITION_TYPE_BUY) posBuy++; else posSell++;

         // 1. Cierre por beneficio individual ($1.00)
         if(pr >= BeneficioCierre) { trade.PositionClose(t); continue; }
         
         // 2. BREAK EVEN (El seguro)
         if(pr >= BE_Activacion && sl == 0) {
            double nuevoSL = (tipo == POSITION_TYPE_BUY) ? po + BE_PipsGarantia : po - BE_PipsGarantia;
            trade.PositionModify(t, nuevoSL, 0);
         }
         
         // 3. TRAILING STOP (Persiguiendo el precio)
         if(ActivarTrailing && sl > 0) {
            double dist = TrailingPips * _Point * 10;
            double paso = TrailingStep * _Point * 10;
            if(tipo == POSITION_TYPE_BUY) {
               if(bid - dist > sl + paso) trade.PositionModify(t, bid - dist, 0);
            } else {
               if(ask + dist < sl - paso) trade.PositionModify(t, ask + dist, 0);
            }
         }
      }
   }

   // --- PARTE B: LIMPIEZA DE "OVEJAS SIN PAREJA" ---
   if(LimpiarHuerfanas) {
      if(posBuy == 0) BorrarPendientesPorTipo(ORDER_TYPE_SELL_STOP);
      if(posSell == 0) BorrarPendientesPorTipo(ORDER_TYPE_BUY_STOP);
      if(posBuy == 0 && posSell == 0 && ContarPendientes() > 0) BorrarTodasLasPendientes();
   }

   // --- PARTE C: CIERRE POR CESTA ---
   if((posBuy + posSell) > 0 && profitTotal >= ProfitCesta) {
      CerrarTodoYLimpiar("CESTA COMPLETADA");
      return;
   }

   // --- PARTE D: ENTRADA Y ESCUDO (MODO AMETRALLADORA) ---
   if(posBuy == 0 && posSell == 0 && ContarPendientes() == 0) {
      // Entrada directa (sin filtros de tendencia para no perder velocidad)
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      // Decisión simple: Si la última vela cerró arriba, compramos; si no, vendemos.
      double close1 = iClose(_Symbol, _Period, 1);
      if(bid > close1) {
         if(trade.Buy(Lote, _Symbol)) 
            trade.SellStop(Lote, bid - (DistanciaEscudo * _Point * 10), _Symbol);
      } else {
         if(trade.Sell(Lote, _Symbol))
            trade.BuyStop(Lote, ask + (DistanciaEscudo * _Point * 10), _Symbol);
      }
   }
}

// --- FUNCIONES DE CONTROL ---

void BorrarPendientesPorTipo(ENUM_ORDER_TYPE tipo) {
   for(int i=OrdersTotal()-1; i>=0; i--) {
      ulong t = OrderGetTicket(i);
      if(OrderSelect(t) && OrderGetString(ORDER_SYMBOL) == _Symbol && OrderGetInteger(ORDER_TYPE) == tipo)
         trade.OrderDelete(t);
   }
}

void BorrarTodasLasPendientes() {
   for(int i=OrdersTotal()-1; i>=0; i--) {
      ulong t = OrderGetTicket(i);
      if(OrderSelect(t) && OrderGetString(ORDER_SYMBOL) == _Symbol) trade.OrderDelete(t);
   }
}

int ContarPendientes() {
   int c=0;
   for(int i=OrdersTotal()-1; i>=0; i--) {
      if(OrderSelect(OrderGetTicket(i)) && OrderGetString(ORDER_SYMBOL) == _Symbol) c++;
   }
   return c;
}

void CerrarTodoYLimpiar(string m) {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong t = PositionGetTicket(i);
      if(PositionSelectByTicket(t) && PositionGetString(POSITION_SYMBOL) == _Symbol) trade.PositionClose(t);
   }
   BorrarTodasLasPendientes();
   Print(m);
}
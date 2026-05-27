//+------------------------------------------------------------------+
//|                                     MSC_NEO_SHIELD_V4_ULTIMATE   |
//|   ESCUDO SINCRONIZADO (MODO SOMBRA) + GESTIÓN BE/TRAILING        |
//+------------------------------------------------------------------+
#property copyright "Master Scalping Hybrid"
#property version   "4.03"
#property strict

#include <Trade\Trade.mqh>

input group "=== GESTIÓN DE BENEFICIOS ==="
input double   LoteInicial        = 0.01;   
input double   ProfitObjetivoNeto = 3.0;    
input double   StopLossGlobal     = 15.0;   

input group "=== PROTECCIÓN ACTIVA (BE/TRAILING) ==="
input double   BE_Activacion      = 1.5;    
input double   GarantiaBE         = 0.5;    
input int      TrailingPips       = 15;     

input group "=== ESCUDO INMEDIATO (PEGADO) ==="
input int      DistanciaPipsHedge = 20;     
input int      StopLevelManual    = 150;    

input group "=== SEGURIDAD ==="
input long     MagicNeo           = 999900; // Magic nuevo para resetear

CTrade trade;
datetime ultimaVela = 0;

void OnTick() {
   double profitTotal = CalcularProfitTotal();
   int nTotal = ContarPosiciones();

   // 1. CIERRES DE EMERGENCIA
   if(nTotal > 0) {
      if(profitTotal >= ProfitObjetivoNeto) { CerrarTodoYLimpiar("PROFIT"); return; }
      if(profitTotal <= -StopLossGlobal) { CerrarTodoYLimpiar("STOP"); return; }
   }

   // 2. VIGILANCIA DE ESCUDOS (Por si uno se borra por error)
   GestionarEscudosDinamicos();

   // 3. GESTIÓN DE BE/TRAILING
   GestionarTrailingYBE();

   // 4. ENTRADA PRINCIPAL + ESCUDO SIMULTÁNEO
   if(nTotal == 0 && ContarPendientes() == 0) {
      if(ultimaVela != iTime(_Symbol, _Period, 0)) {
         if(AbrirEntradaConEscudo()) { // LA CLAVE ESTÁ AQUÍ
            ultimaVela = iTime(_Symbol, _Period, 0);
         }
      }
   }
}

// NUEVA FUNCIÓN: Abre la orden y pone el escudo EN EL ACTO
bool AbrirEntradaConEscudo() {
   double ma[]; ArraySetAsSeries(ma, true);
   int h = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   bool exito = false;
   
   if(CopyBuffer(h, 0, 0, 1, ma) > 0) {
      double dist = DistanciaPipsHedge * _Point * 10;
      
      // CASO COMPRA
      if(SymbolInfoDouble(_Symbol, SYMBOL_BID) > ma[0]) {
         if(trade.Buy(LoteInicial, _Symbol, 0, 0, 0, "PRI")) {
            double pStop = SymbolInfoDouble(_Symbol, SYMBOL_ASK) - dist;
            // Verificación de distancia mínima del broker
            double minStop = SymbolInfoDouble(_Symbol, SYMBOL_BID) - (StopLevelManual * _Point);
            if(pStop > minStop) pStop = minStop;
            trade.SellStop(LoteInicial, pStop, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "SHIELD");
            exito = true;
         }
      } 
      // CASO VENTA
      else {
         if(trade.Sell(LoteInicial, _Symbol, 0, 0, 0, "PRI")) {
            double pStop = SymbolInfoDouble(_Symbol, SYMBOL_BID) + dist;
            double minStop = SymbolInfoDouble(_Symbol, SYMBOL_ASK) + (StopLevelManual * _Point);
            if(pStop < minStop) pStop = minStop;
            trade.BuyStop(LoteInicial, pStop, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "SHIELD");
            exito = true;
         }
      }
   }
   IndicatorRelease(h);
   return exito;
}

// --- FUNCIONES DE APOYO Y MANTENIMIENTO ---
void GestionarEscudosDinamicos() {
   int compras = 0, ventas = 0, pBuyStop = 0, pSellStop = 0;
   double pRef = 0;

   for(int i=0; i<PositionsTotal(); i++) {
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == MagicNeo) {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) { compras++; pRef = PositionGetDouble(POSITION_PRICE_OPEN); }
         else { ventas++; pRef = PositionGetDouble(POSITION_PRICE_OPEN); }
      }
   }
   for(int i=0; i<OrdersTotal(); i++) {
      if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC) == MagicNeo) {
         if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_STOP) pBuyStop++;
         if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_STOP) pSellStop++;
      }
   }

   double dist = DistanciaPipsHedge * _Point * 10;
   if(compras > 0 && ventas == 0 && pSellStop == 0) {
      trade.SellStop(LoteInicial, pRef - dist, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "SHIELD");
   }
   if(ventas > 0 && compras == 0 && pBuyStop == 0) {
      trade.BuyStop(LoteInicial, pRef + dist, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "SHIELD");
   }
}

void GestionarTrailingYBE() {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == MagicNeo) {
         ulong t = PositionGetTicket(i);
         double sl = PositionGetDouble(POSITION_SL), profit = PositionGetDouble(POSITION_PROFIT);
         double pOpen = PositionGetDouble(POSITION_PRICE_OPEN), bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         long tipo = PositionGetInteger(POSITION_TYPE);

         if(profit >= BE_Activacion && sl == 0) {
            double nBE = (tipo == POSITION_TYPE_BUY) ? pOpen + (GarantiaBE*_Point*10) : pOpen - (GarantiaBE*_Point*10);
            trade.PositionModify(t, nBE, 0);
         }
         if(sl > 0) {
            if(tipo == POSITION_TYPE_BUY) {
               double nSL = bid - (TrailingPips*_Point*10);
               if(nSL > sl + (3*_Point*10)) trade.PositionModify(t, nSL, 0);
            } else {
               double nSL = ask + (TrailingPips*_Point*10);
               if(nSL < sl - (3*_Point*10)) trade.PositionModify(t, nSL, 0);
            }
         }
      }
   }
}

double CalcularProfitTotal() {
   double p = 0;
   for(int i=0; i<PositionsTotal(); i++) if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == MagicNeo) p += PositionGetDouble(POSITION_PROFIT);
   return p;
}

int ContarPosiciones() {
   int c=0; for(int i=0; i<PositionsTotal(); i++) if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == MagicNeo) c++;
   return c;
}

int ContarPendientes() {
   int c=0; for(int i=0; i<OrdersTotal(); i++) if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC) == MagicNeo) c++;
   return c;
}

void CerrarTodoYLimpiar(string m) {
   for(int i=PositionsTotal()-1; i>=0; i--) if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == MagicNeo) trade.PositionClose(PositionGetTicket(i));
   for(int i=OrdersTotal()-1; i>=0; i--) if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC) == MagicNeo) trade.OrderDelete(OrderGetTicket(i));
   Print(m);
}
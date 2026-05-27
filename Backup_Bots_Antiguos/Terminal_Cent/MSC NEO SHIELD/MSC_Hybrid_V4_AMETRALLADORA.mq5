//+------------------------------------------------------------------+
//|                                     MSC_Ametralladora_V9_7_FIXED |
//|          CORRECCIÓN INVALID PRICE + PANEL DE CONTROL TOTAL       |
//+------------------------------------------------------------------+
#property copyright "Master Scalping Hybrid"
#property version   "9.70"
#property strict

#include <Trade\Trade.mqh>

//--- PARÁMETROS VISIBLES ---

input group "=== RELOJ DE OPERACIÓN ==="
input int      HoraInicio         = 9;      
input int      MinutoInicio       = 0;      
input int      HoraFin            = 21;     
input int      MinutoFin          = 0;      

input group "=== CONFIGURACIÓN PRINCIPAL ==="
input double   LoteInicial        = 0.01;   
input double   ProfitObjetivo     = 1.0;    // Profit para cerrar ($)
input double   BE_Activacion      = 2.0;    // $ para activar BE
input double   GarantiaBE         = 1.0;    // $ a asegurar

input group "=== CONFIGURACIÓN RELEVOS (CADENA) ==="
input int      DistanciaPipsHedge = 20;     // Distancia del seguro
input double   LoteHedge          = 0.01;   
input double   ProfitHedge        = 1.0;    // Profit para relevos ($)

input group "=== GESTIÓN DE TRAILING STOP ==="
input bool     ActivarTrailing    = true;   
input int      DistanciaTrailing  = 15;     
input int      SaltoDelTrailing   = 5;      

input group "=== SEGURIDAD Y FILTROS ==="
input int      MaxPosiciones      = 3;      
input int      StopLevelManual    = 100;    // Puntos extra de seguridad para evitar Invalid Price
input long     MagicPrincipal     = 777111; 

CTrade trade;

int OnInit() {
   trade.SetExpertMagicNumber(MagicPrincipal);
   trade.SetTypeFillingBySymbol(_Symbol);
   return(INIT_SUCCEEDED);
}

void OnTick() {
   GestionarIndividual();

   int nTotal = ContarPosiciones();
   int nPendientes = ContarPendientes();

   // LÓGICA DE ESCUDO CON FILTRO DE PRECIO VÁLIDO
   if(nTotal >= 1 && nTotal < MaxPosiciones && nPendientes == 0) {
      ColocarEscudoSeguro();
   }

   if(nTotal == 0 && nPendientes == 0 && EstaEnHorario()) {
      AbrirEntradaInicial();
   }
}

void ColocarEscudoSeguro() {
   double pOpen = 0; long tipo = -1;
   for(int i=0; i<PositionsTotal(); i++) {
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == MagicPrincipal) {
         pOpen = PositionGetDouble(POSITION_PRICE_OPEN);
         tipo = PositionGetInteger(POSITION_TYPE);
      }
   }

   double dist = DistanciaPipsHedge * _Point * 10;
   double minDiff = (StopLevelManual * _Point); // Margen de seguridad
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(tipo == POSITION_TYPE_BUY) {
      double pStop = pOpen - dist;
      // Si el precio actual está muy cerca del pStop, lo bajamos un poco para evitar "Invalid Price"
      if(pStop > bid - minDiff) pStop = bid - minDiff;
      trade.SellStop(LoteHedge, pStop, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "RELEVO");
   } 
   else if(tipo == POSITION_TYPE_SELL) {
      double pStop = pOpen + dist;
      // Si el precio actual está muy cerca del pStop, lo subimos un poco
      if(pStop < ask + minDiff) pStop = ask + minDiff;
      trade.BuyStop(LoteHedge, pStop, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "RELEVO");
   }
}

void GestionarIndividual() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong t = PositionGetTicket(i);
      if(PositionSelectByTicket(t) && PositionGetInteger(POSITION_MAGIC) == MagicPrincipal) {
         double profit = PositionGetDouble(POSITION_PROFIT);
         double pOpen  = PositionGetDouble(POSITION_PRICE_OPEN);
         double sl     = PositionGetDouble(POSITION_SL);
         long tipo     = PositionGetInteger(POSITION_TYPE);
         string comment = PositionGetString(POSITION_COMMENT);
         
         double obj = (comment == "PRINCIPAL") ? ProfitObjetivo : ProfitHedge;

         // CIERRE POR PROFIT
         if(profit >= obj) { trade.PositionClose(t); continue; }

         // BREAK EVEN
         if(profit >= BE_Activacion) {
            double nBE = (tipo == POSITION_TYPE_BUY) ? pOpen + (GarantiaBE*_Point*10) : pOpen - (GarantiaBE*_Point*10);
            if(tipo == POSITION_TYPE_BUY && sl < nBE) trade.PositionModify(t, nBE, 0);
            if(tipo == POSITION_TYPE_SELL && (sl == 0 || sl > nBE)) trade.PositionModify(t, nBE, 0);
         }

         // TRAILING
         if(ActivarTrailing && profit >= BE_Activacion) {
            double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            if(tipo == POSITION_TYPE_BUY) {
               double nSL = bid - (DistanciaTrailing*_Point*10);
               if(nSL > sl + (SaltoDelTrailing*_Point*10)) trade.PositionModify(t, nSL, 0);
            } else {
               double nSL = ask + (DistanciaTrailing*_Point*10);
               if(sl == 0 || nSL < sl - (SaltoDelTrailing*_Point*10)) trade.PositionModify(t, nSL, 0);
            }
         }
      }
   }
}

void AbrirEntradaInicial() {
   double ma[]; ArraySetAsSeries(ma, true);
   int h = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
   if(CopyBuffer(h, 0, 0, 2, ma) > 1) {
      if(SymbolInfoDouble(_Symbol, SYMBOL_BID) > ma[0]) trade.Buy(LoteInicial, _Symbol, 0, 0, 0, "PRINCIPAL");
      else trade.Sell(LoteInicial, _Symbol, 0, 0, 0, "PRINCIPAL");
   }
   IndicatorRelease(h);
}

bool EstaEnHorario() {
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   int mAct = dt.hour * 60 + dt.min;
   return (mAct >= (HoraInicio*60+MinutoInicio) && mAct < (HoraFin*60+MinutoFin));
}

int ContarPosiciones() {
   int c = 0;
   for(int i=0; i<PositionsTotal(); i++)
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == MagicPrincipal) c++;
   return c;
}

int ContarPendientes() {
   int c = 0;
   for(int i=0; i<OrdersTotal(); i++)
      if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC) == MagicPrincipal) c++;
   return c;
}
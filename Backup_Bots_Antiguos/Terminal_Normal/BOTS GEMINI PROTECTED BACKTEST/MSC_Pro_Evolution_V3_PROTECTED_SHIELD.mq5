//+------------------------------------------------------------------+
//|                               MSC_Pro_Evolution_V3_PROTECTED.mq5 |
//|        Estrategia Profesional - Cobertura + Horario Preciso      |
//+------------------------------------------------------------------+
#property copyright "Master Scalping Hybrid"
#property version   "3.10"
#property strict

#include <Trade\Trade.mqh>

//--- INPUTS PROFESIONALES
input group "=== GESTIÓN DE RIESGO PRO ==="
input double   LoteInicial       = 0.01;
input double   ProfitObjetivo    = 8.0;    
input double   StopLossDiario    = 150.0;
input int      MaxOpsSimultaneas = 2;

input group "=== FILTROS Y TIEMPO ==="
input bool     UsarFiltroTendencia = true;
input int      PeriodoMedia        = 200;
input bool     UsarCierrePorTiempo = true;
input int      HorasMaximasOrden   = 6;     

input group "=== CONFIGURACIÓN HORARIA PRECISA ==="
input int      HoraInicio   = 0;     // Ejemplo: 0
input int      MinutoInicio = 30;    // Ejemplo: 30 (Empezará a las 00:30)
input int      HoraFin      = 22;    
input int      MinutoFin    = 0;

input group "=== COBERTURA PROTECTED (SHIELD) ==="
input bool     UsarCobertura       = true;
input int      DistanciaPipsHedge  = 1000;  
input double   LoteHedge           = 0.02;  
input double   BE_Venta_Activacion = 2.0;   
input int      TrailingStopVenta   = 50;    

input group "=== PROTECCIÓN Y MAGIC ==="
input int      Cooldown          = 900;
input int      BreakEvenPips     = 5;      
input double   BE_Activacion     = 2.0;
input long     MagicNumber       = 123456;
input long     MagicHedge        = 654321; 

//--- VARIABLES GLOBALES
CTrade trade;
datetime ultimaOperacion = 0;

int OnInit() {
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetTypeFillingBySymbol(_Symbol);
   return(INIT_SUCCEEDED);
}

void OnTick() {
   MqlDateTime strTime;
   TimeToStruct(TimeCurrent(), strTime);

   // --- FILTRO HORARIO POR MINUTOS ---
   int momentoActual = (strTime.hour * 60) + strTime.min;
   int momentoInicio = (HoraInicio * 60) + MinutoInicio;
   int momentoFin    = (HoraFin * 60) + MinutoFin;

   if(momentoActual < momentoInicio || momentoActual > momentoFin) {
      Comment("🌙 MODO SUEÑO: Activo de ", HoraInicio, ":", MinutoInicio, " a ", HoraFin, ":", MinutoFin);
      return;
   }

   // 1. Gestión de posiciones y Cobertura
   GestionarPosicionesYTiempo();
   GestionarHedgeVentas(); 

   // 2. Lógica de Entrada (Solo si no hay compras)
   if(ContarPosiciones(MagicNumber) == 0) {
      BorrarOrdenesPendientesHedge(); 
      if(TimeCurrent() - ultimaOperacion > Cooldown) {
         EvaluarEntradaConFiltro();
      }
   }
}

void GestionarPosicionesYTiempo() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
            
            if(UsarCierrePorTiempo) {
               datetime tiempoApertura = (datetime)PositionGetInteger(POSITION_TIME);
               if(TimeCurrent() - tiempoApertura > HorasMaximasOrden * 3600) {
                  trade.PositionClose(ticket);
                  continue;
               }
            }

            double profit = PositionGetDouble(POSITION_PROFIT);
            if(profit >= ProfitObjetivo) trade.PositionClose(ticket);
            if(profit >= BE_Activacion) MoverABreakEven(ticket, BreakEvenPips);
         }
      }
   }
}

void GestionarHedgeVentas() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(PositionGetInteger(POSITION_MAGIC) == MagicHedge) {
            double profit = PositionGetDouble(POSITION_PROFIT);
            if(profit >= BE_Venta_Activacion) MoverABreakEven(ticket, 10); 
            AplicarTrailingVenta(ticket);
            if(profit >= 8.0) trade.PositionClose(ticket);
         }
      }
   }
}

void EvaluarEntradaConFiltro() {
   double ma = 0;
   double precioActual = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   if(UsarFiltroTendencia) {
      double maArray[];
      int handle = iMA(_Symbol, _Period, PeriodoMedia, 0, MODE_EMA, PRICE_CLOSE);
      CopyBuffer(handle, 0, 0, 1, maArray);
      ma = maArray[0];
   }

   if(precioActual > ma) {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      trade.SetExpertMagicNumber(MagicNumber);
      if(trade.Buy(LoteInicial, _Symbol, ask, 0, 0, "PROTECTED V3.1")) {
         ultimaOperacion = TimeCurrent();
         if(UsarCobertura) {
            double precioHedge = ask - (DistanciaPipsHedge * _Point * 10);
            trade.SetExpertMagicNumber(MagicHedge);
            trade.SellStop(LoteHedge, precioHedge, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "Hedge_Shield");
            trade.SetExpertMagicNumber(MagicNumber);
         }
      }
   }
}

void AplicarTrailingVenta(ulong ticket) {
   double precioActual = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double stopLossActual = PositionGetDouble(POSITION_SL);
   double slPips = TrailingStopVenta * _Point * 10;
   double nuevoSL = precioActual + slPips;
   if(stopLossActual == 0 || nuevoSL < stopLossActual) trade.PositionModify(ticket, nuevoSL, 0);
}

int ContarPosiciones(long magic) {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(PositionSelectByTicket(PositionGetTicket(i)))
         if(PositionGetInteger(POSITION_MAGIC) == magic) count++;
   }
   return count;
}

void BorrarOrdenesPendientesHedge() {
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      ulong ticket = OrderGetTicket(i);
      if(OrderSelect(ticket)) {
         if(OrderGetInteger(ORDER_MAGIC) == MagicHedge) trade.OrderDelete(ticket);
      }
   }
}

void MoverABreakEven(ulong ticket, int pips) {
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double sl = PositionGetDouble(POSITION_SL);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
      double nuevoSL = openPrice + (pips * point * 10);
      if(sl < openPrice) trade.PositionModify(ticket, nuevoSL, 0);
   } else {
      double nuevoSL = openPrice - (pips * point * 10);
      if(sl == 0 || sl > openPrice) trade.PositionModify(ticket, nuevoSL, 0);
   }
}
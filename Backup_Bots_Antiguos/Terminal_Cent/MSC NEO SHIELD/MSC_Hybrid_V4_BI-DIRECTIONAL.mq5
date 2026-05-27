
//+------------------------------------------------------------------+
//|                                  MSC_Hybrid_V4_BI-DIRECTIONAL.mq5|
//|                    Versión 4.0 - Híbrido Compras/Ventas + Shield |
//+------------------------------------------------------------------+
#property copyright "Master Scalping Hybrid"
#property version   "4.00"
#property strict

#include <Trade\Trade.mqh>

//--- INPUTS PROFESIONALES
input group "=== GESTIÓN DE RIESGO PRO ==="
input double   LoteInicial   = 0.01;
input double   ProfitObjetivo = 8.0;    
input double   StopLossDiario  = 200.0;  
input int      MaxOpsSimultaneas = 1; // Recomendado 1 para modo Híbrido

input group "=== FILTROS Y TIEMPO ==="
input bool     UsarFiltroTendencia = true;
input int      PeriodoMedia        = 50;    // Lo bajamos a 50 como hablamos para más agilidad
input bool     UsarCierrePorTiempo = true;
input int      HorasMaximasOrden   = 10;    

input group "=== CONFIGURACIÓN HORARIA PRECISA ==="
input int      HoraInicio   = 0;     
input int      MinutoInicio = 30;    
input int      HoraFin      = 22;    
input int      MinutoFin    = 0;

input group "=== COBERTURA (SHIELD) BI-DIRECCIONAL ==="
input bool     UsarCobertura       = true;
input int      DistanciaPipsHedge  = 1000;  
input double   LoteHedge           = 0.02;  
input double   BE_Hedge_Activacion = 2.0;   
input int      TrailingStopHedge   = 50;    

input group "=== SEGURIDAD FIN DE SEMANA ==="
input bool     UsarCierreViernes   = true;  
input int      HoraCierreViernes   = 21;    

input group "=== PROTECCIÓN Y MAGIC ==="
input int      Cooldown          = 900;
input int      BreakEvenPips     = 5;      
input double   BE_Activacion     = 2.0;
input long     MagicPrincipal    = 888999; 
input long     MagicHedge        = 111222; 

//--- VARIABLES GLOBALES
CTrade trade;
datetime ultimaOperacion = 0;

int OnInit() {
   trade.SetExpertMagicNumber(MagicPrincipal);
   trade.SetTypeFillingBySymbol(_Symbol);
   return(INIT_SUCCEEDED);
}

void OnTick() {
   MqlDateTime strTime;
   TimeToStruct(TimeCurrent(), strTime);

   // 1. Cierre de Seguridad Viernes
   if(UsarCierreViernes && strTime.day_of_week == 5 && strTime.hour >= HoraCierreViernes) {
      CerrarTodoEmergencia("Cierre Fin de Semana");
      Comment("🍹 FIN DE SEMANA: Bot en pausa.");
      return;
   }

   // 2. Filtro Horario
   int momentoActual = (strTime.hour * 60) + strTime.min;
   int momentoInicio = (HoraInicio * 60) + MinutoInicio;
   int momentoFin    = (HoraFin * 60) + MinutoFin;

   if(momentoActual < momentoInicio || momentoActual > momentoFin) {
      Comment("🌙 MODO SUEÑO: Esperando a las 00:30");
      return;
   }

   // 3. Gestión de Posiciones Activas
   GestionarPosicionesYTiempo();
   GestionarHedgeActivo(); 

   // 4. Lógica de Entrada Híbrida
   if(ContarPosiciones(MagicPrincipal) == 0 && ContarPosiciones(MagicHedge) == 0) {
      BorrarOrdenesPendientesHedge();
      if(TimeCurrent() - ultimaOperacion > Cooldown) {
          EvaluarEntradaHibrida();
      }
   }
}

void GestionarPosicionesYTiempo() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(PositionGetInteger(POSITION_MAGIC) == MagicPrincipal) {
            // Cierre por tiempo
            if(UsarCierrePorTiempo) {
               datetime tiempoApertura = (datetime)PositionGetInteger(POSITION_TIME);
               if(TimeCurrent() - tiempoApertura > HorasMaximasOrden * 3600) {
                  trade.PositionClose(ticket);
                  continue;
               }
            }
            // Take Profit y BreakEven
            double profit = PositionGetDouble(POSITION_PROFIT);
            if(profit >= ProfitObjetivo) trade.PositionClose(ticket);
            if(profit >= BE_Activacion) MoverABreakEven(ticket, BreakEvenPips);
         }
      }
   }
}

void GestionarHedgeActivo() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(PositionGetInteger(POSITION_MAGIC) == MagicHedge) {
            double profit = PositionGetDouble(POSITION_PROFIT);
            // Si el Hedge gana, protegemos
            if(profit >= BE_Hedge_Activacion) MoverABreakEven(ticket, 10); 
            AplicarTrailingHedge(ticket);
            if(profit >= ProfitObjetivo) trade.PositionClose(ticket);
         }
      }
   }
}

void EvaluarEntradaHibrida() {
   double maArray[];
   int handle = iMA(_Symbol, _Period, PeriodoMedia, 0, MODE_EMA, PRICE_CLOSE);
   CopyBuffer(handle, 0, 0, 1, maArray);
   double ma = maArray[0];
   
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   // CASO A: PRECIO POR ENCIMA DE LA MEDIA -> COMPRAMOS
   if(bid > ma) {
      trade.SetExpertMagicNumber(MagicPrincipal);
      if(trade.Buy(LoteInicial, _Symbol, ask, 0, 0, "BUY_HYBRID")) {
         ultimaOperacion = TimeCurrent();
         if(UsarCobertura) {
            double precioHedge = bid - (DistanciaPipsHedge * _Point * 10);
            trade.SetExpertMagicNumber(MagicHedge);
            trade.SellStop(LoteHedge, precioHedge, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "Shield_Sell");
         }
      }
   } 
   // CASO B: PRECIO POR DEBAJO DE LA MEDIA -> VENDEMOS
   else if(bid < ma) {
      trade.SetExpertMagicNumber(MagicPrincipal);
      if(trade.Sell(LoteInicial, _Symbol, bid, 0, 0, "SELL_HYBRID")) {
         ultimaOperacion = TimeCurrent();
         if(UsarCobertura) {
            double precioHedge = ask + (DistanciaPipsHedge * _Point * 10);
            trade.SetExpertMagicNumber(MagicHedge);
            trade.BuyStop(LoteHedge, precioHedge, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "Shield_Buy");
         }
      }
   }
}

void AplicarTrailingHedge(ulong ticket) {
   ENUM_POSITION_TYPE tipo = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   double slPips = TrailingStopHedge * _Point * 10;
   double stopLossActual = PositionGetDouble(POSITION_SL);
   
   if(tipo == POSITION_TYPE_SELL) {
      double precioAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double nuevoSL = precioAsk + slPips;
      if(stopLossActual == 0 || nuevoSL < stopLossActual) trade.PositionModify(ticket, nuevoSL, 0);
   } else {
      double precioBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double nuevoSL = precioBid - slPips;
      if(stopLossActual == 0 || nuevoSL > stopLossActual) trade.PositionModify(ticket, nuevoSL, 0);
   }
}

void CerrarTodoEmergencia(string motivo) {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         long mg = PositionGetInteger(POSITION_MAGIC);
         if(mg == MagicPrincipal || mg == MagicHedge) trade.PositionClose(ticket);
      }
   }
   BorrarOrdenesPendientesHedge();
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
         long mg = OrderGetInteger(ORDER_MAGIC);
         if(mg == MagicHedge) trade.OrderDelete(ticket);
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
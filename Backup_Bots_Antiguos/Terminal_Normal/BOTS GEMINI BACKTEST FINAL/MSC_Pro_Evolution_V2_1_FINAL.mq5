//+------------------------------------------------------------------+
//|                                 MSC_Pro_Evolution_V2_1_FINAL.mq5 |
//|                    VERSIÓN CON CIERRE AUTOMÁTICO DE VIERNES      |
//+------------------------------------------------------------------+
#property copyright "Master Scalping Hybrid"
#property version   "2.10"
#property strict

#include <Trade\Trade.mqh>

//--- INPUTS PROFESIONALES
input group "=== GESTIÓN DE RIESGO PRO ==="
input double   LoteInicial       = 0.01;
input double   ProfitObjetivo    = 5.0;    
input double   StopLossDiario    = 150.0;  
input int      MaxOpsSimultaneas = 2;      

input group "=== FILTROS INTELIGENTES ==="
input bool     UsarFiltroTendencia = true;  
input int      PeriodoMedia        = 200;   
input bool     UsarCierrePorTiempo = true;  
input int      HorasMaximasOrden   = 8;     // Configuración del backtest ganador

input group "=== SEGURIDAD FIN DE SEMANA ==="
input bool     UsarCierreViernes   = true;  // Activar cierre automático
input int      HoraCierreViernes   = 21;    // Hora de cierre (21:00h)

input group "=== CONFIGURACIÓN HORARIA ==="
input int      HoraInicio = 1;             
input int      HoraFin    = 22;            

input group "=== PROTECCIÓN ==="
input int      Cooldown          = 900;    
input int      BreakEvenPips     = 5;      
input double   BE_Activacion     = 2.0;
input long     MagicNumber       = 1234567; // Nuevo Magic para esta versión

//--- VARIABLES GLOBALES
CTrade trade;
double perdidaAcumuladaDia = 0;
datetime ultimaOperacion = 0;

int OnInit() {
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetTypeFillingBySymbol(_Symbol);
   return(INIT_SUCCEEDED);
}

void OnTick() {
   MqlDateTime strTime;
   TimeToStruct(TimeCurrent(), strTime);

   // 1. Verificar Stop Diario
   if(MathAbs(perdidaAcumuladaDia) >= StopLossDiario) {
      Comment("🛑 STOP DIARIO ALCANZADO");
      return;
   }

   // 2. Lógica de Cierre por Fin de Semana
   if(UsarCierreViernes && strTime.day_of_week == 5 && strTime.hour >= HoraCierreViernes) {
      CerrarTodoEmergencia("Cierre de Seguridad Viernes (Fin de Semana)");
      Comment("🍹 FIN DE SEMANA: Operaciones cerradas por seguridad.");
      return;
   }

   // 3. Filtro Horario Normal
   if(strTime.hour < HoraInicio || strTime.hour > HoraFin) {
      Comment("🌙 FUERA DE HORARIO OPERATIVO");
      return;
   }

   // 4. Gestión de posiciones activas
   GestionarPosicionesYTiempo();

   // 5. Lógica de Entrada (Solo si no hay operaciones abiertas)
   int total = ContarPosicionesPropias();
   if(total == 0) {
      if(TimeCurrent() - ultimaOperacion > Cooldown) {
          EvaluarEntradaConFiltro();
      }
   }
}

void CerrarTodoEmergencia(string motivo) {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
            trade.PositionClose(ticket);
            Print("⚠️ ", motivo);
         }
      }
   }
}

void GestionarPosicionesYTiempo() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            
            // A. Cierre por Time-Out (8 horas)
            if(UsarCierrePorTiempo) {
               datetime tiempoApertura = (datetime)PositionGetInteger(POSITION_TIME);
               if(TimeCurrent() - tiempoApertura > HorasMaximasOrden * 3600) {
                  trade.PositionClose(ticket);
                  Print("⏰ Orden cerrada por límite de 8 horas");
                  continue;
               }
            }

            // B. Gestión de BreakEven
            double profit = PositionGetDouble(POSITION_PROFIT);
            if(profit >= BE_Activacion) MoverABreakEven(ticket);
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
      ArraySetAsSeries(maArray, true);
      if(CopyBuffer(handle, 0, 0, 1, maArray) > 0) {
         ma = maArray[0];
      }
   }

   // Entrada basada en la Media de 200
   if(precioActual > ma) {
      EjecutarOrden(ORDER_TYPE_BUY, LoteInicial, "V2.1_Compra_Tendencia");
   } else if(precioActual < ma) {
      EjecutarOrden(ORDER_TYPE_SELL, LoteInicial, "V2.1_Venta_Tendencia");
   }
}

void EjecutarOrden(int tipo, double lote, string comentario) {
   double precio = (tipo == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(tipo == ORDER_TYPE_BUY) trade.Buy(lote, _Symbol, precio, 0, 0, comentario);
   else trade.Sell(lote, _Symbol, precio, 0, 0, comentario);
   ultimaOperacion = TimeCurrent();
}

int ContarPosicionesPropias() {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(PositionSelectByTicket(PositionGetTicket(i)))
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber) count++;
   }
   return count;
}

void MoverABreakEven(ulong ticket) {
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double currentSL = PositionGetDouble(POSITION_SL);
   
   if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
      double newSL = openPrice + (BreakEvenPips*point*10);
      if(currentSL < newSL) trade.PositionModify(ticket, newSL, 0);
   } else {
      double newSL = openPrice - (BreakEvenPips*point*10);
      if(currentSL > newSL || currentSL == 0) trade.PositionModify(ticket, newSL, 0);
   }
}

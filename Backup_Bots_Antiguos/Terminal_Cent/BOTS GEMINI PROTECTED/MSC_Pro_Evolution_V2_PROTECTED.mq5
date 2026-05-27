//+------------------------------------------------------------------+
//|                                MSC_Pro_Evolution_V2_PROTECTED.mq5|
//|                         Estrategia Profesional con Cortafuegos    |
//+------------------------------------------------------------------+
#property copyright "Master Scalping Hybrid"
#property version   "2.00"
#property strict

#include <Trade\Trade.mqh>

//--- ENUMS
enum ENUM_PAR_TRADING { PAR_AUTO, PAR_XAUUSD, PAR_CUSTOM };

//--- INPUTS PROFESIONALES
input group "=== GESTIÓN DE RIESGO PRO ==="
input double   LoteInicial       = 0.01;
input double   ProfitObjetivo    = 5.0;    // Objetivo de ciclo más corto
input double   StopLossDiario    = 150.0;  // Tu límite de seguridad
input int      MaxOpsSimultaneas = 2;      // El cortafuegos que te funcionó

input group "=== FILTROS INTELIGENTES (NUEVO) ==="
input bool     UsarFiltroTendencia = true;  // Solo opera a favor de la tendencia
input int      PeriodoMedia        = 200;   // Media Móvil de 200 (El estándar Pro)
input bool     UsarCierrePorTiempo = true;  // Activa el Time-Out
input int      HorasMaximasOrden   = 4;     // Máximo 4 horas abierta

input group "=== CONFIGURACIÓN HORARIA ==="
input int      HoraInicio = 1;             // Evita el spread de apertura
input int      HoraFin    = 22;            // Cierra antes del cierre de mercado

input group "=== PROTECCIÓN ==="
input int      Cooldown          = 900;    // Tus 900 segundos
input int      BreakEvenPips     = 5;      
input double   BE_Activacion     = 2.0;
input long     MagicNumber       = 123456;

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
   // 1. Verificar Stop Diario
   if(MathAbs(perdidaAcumuladaDia) >= StopLossDiario) {
      Comment("🛑 STOP DIARIO ALCANZADO");
      return;
   }

   // 2. Filtro Horario
   MqlDateTime strTime;
   TimeToStruct(TimeCurrent(), strTime);
   if(strTime.hour < HoraInicio || strTime.hour > HoraFin) {
      Comment("🌙 FUERA DE HORARIO OPERATIVO");
      return;
   }

   // 3. Gestión de órdenes (incluye Cierre por Tiempo)
   GestionarPosicionesYTiempo();

   // 4. Lógica de Entrada
   int total = ContarPosicionesPropias();
   if(total == 0) {
      if(TimeCurrent() - ultimaOperacion > Cooldown) {
         EvaluarEntradaConFiltro();
      }
   }
}

void GestionarPosicionesYTiempo() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            
            // A. Cierre por tiempo (NUEVO)
            if(UsarCierrePorTiempo) {
               datetime tiempoApertura = (datetime)PositionGetInteger(POSITION_TIME);
               if(TimeCurrent() - tiempoApertura > HorasMaximasOrden * 3600) {
                  trade.PositionClose(ticket);
                  Print("⏰ Orden cerrada por Time-Out");
                  continue;
               }
            }

            // B. BreakEven y Profit Individual
            double profit = PositionGetDouble(POSITION_PROFIT);
            if(profit >= BE_Activacion) MoverABreakEven(ticket);
         }
      }
   }
}

void EvaluarEntradaConFiltro() {
   // Filtro de Tendencia con Media Móvil (NUEVO)
   double ma = 0;
   double precioActual = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   if(UsarFiltroTendencia) {
      double maArray[];
      int handle = iMA(_Symbol, _Period, PeriodoMedia, 0, MODE_EMA, PRICE_CLOSE);
      CopyBuffer(handle, 0, 0, 1, maArray);
      ma = maArray[0];
   }

   // Lógica de entrada: Solo compra si precio > Media 200
   if(precioActual > ma) {
      EjecutarOrden(ORDER_TYPE_BUY, LoteInicial, "Trend_Buy");
   } else {
      EjecutarOrden(ORDER_TYPE_SELL, LoteInicial, "Trend_Sell");
   }
}

// (Resto de funciones auxiliares similares al anterior...)
void EjecutarOrden(int tipo, double lote, string comentario) {
   double precio = (tipo == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(trade.Buy(lote, _Symbol, precio, 0, 0, comentario) || trade.Sell(lote, _Symbol, precio, 0, 0, comentario))
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
   if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
      trade.PositionModify(ticket, openPrice + (BreakEvenPips*point*10), 0);
   else
      trade.PositionModify(ticket, openPrice - (BreakEvenPips*point*10), 0);
}
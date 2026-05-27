//+------------------------------------------------------------------+
//|                                     MSC_Pro_Evolution_V1_FIX.mq5 |
//|                                  Agresivo/Defensivo Profesional  |
//+------------------------------------------------------------------+
#property copyright "Master Scalping Hybrid"
#property version   "1.01"
#property strict

#include <Trade\Trade.mqh>

//--- ENUMS
enum ENUM_PAR_TRADING { PAR_AUTO, PAR_EURUSD, PAR_XAUUSD, PAR_CUSTOM };

//--- INPUTS PROFESIONALES (Todo ajustable)
input group "=== CONFIGURACIÓN DE CUENTA ==="
input double   LoteInicial     = 0.01;
input double   ProfitObjetivo  = 10.0;   // Objetivo de la serie
input double   StopLossDiario  = 500.0;  // Límite de pérdida diaria
input int      MaxOpsSimultaneas = 6;    // Máximo de posiciones abiertas

input group "=== ESTRATEGIA HÍBRIDA ==="
input double   TriggerContra   = -1.5;   // Perder esto activa contraoperación
input double   TriggerRefuerzo = 2.0;    // Ganar esto activa refuerzo
input double   ProfitCierreMin = 3.0;    // Cierre individual de ganadoras
input double   Multiplicador   = 2.0;    // Multiplicador Martingala

input group "=== PROTECCIÓN Y TIEMPOS ==="
input int      Cooldown        = 15;     // Segundos de espera entre órdenes
input int      BreakEvenPips   = 2;      // Pips por encima del precio de entrada
input double   BE_Activacion   = 1.0;    // Profit ($) para activar BreakEven

input group "=== SELECCIÓN DE ACTIVO ==="
input ENUM_PAR_TRADING Activo = PAR_AUTO;
input long     MagicNumber     = 123456; // Para no tocar trades manuales

//--- VARIABLES GLOBALES
CTrade trade;
double perdidaAcumuladaDia = 0;
datetime ultimaOperacion = 0;

//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit() {
   trade.SetExpertMagicNumber(MagicNumber);
   // Detección automática de tipo de ejecución para evitar errores de broker
   trade.SetTypeFillingBySymbol(_Symbol);
   
   Print("🚀 MSC Pro Evolution Corregido. Magic: ", MagicNumber);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| OnTick                                                           |
//+------------------------------------------------------------------+
void OnTick() {
   if(MathAbs(perdidaAcumuladaDia) >= StopLossDiario) {
      Comment("🛑 STOP DIARIO ALCANZADO: $", perdidaAcumuladaDia);
      return;
   }

   GestionarPosiciones();

   int total = ContarPosicionesPropias();
   
   if(total == 0) {
      if(TimeCurrent() - ultimaOperacion > Cooldown) {
         EvaluarEntradaInicial();
      }
   } else {
      LogicaHibrida();
   }

   ActualizarComentario();
}

//+------------------------------------------------------------------+
//| Lógica de Contraoperación y Refuerzo                             |
//+------------------------------------------------------------------+
void LogicaHibrida() {
   int total = ContarPosicionesPropias();
   if(total >= MaxOpsSimultaneas) return;
   if(TimeCurrent() - ultimaOperacion < Cooldown) return;
   
   double profitActualTotal = 0;
   double peorProfit = 999;
   double mejorProfit = -999;
   int tipoUltima = -1;
   double ultimoLote = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            double p = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_COMMISSION) + PositionGetDouble(POSITION_SWAP);
            profitActualTotal += p;
            
            if(p < peorProfit) peorProfit = p;
            if(p > mejorProfit) mejorProfit = p;
            
            tipoUltima = (int)PositionGetInteger(POSITION_TYPE);
            ultimoLote = PositionGetDouble(POSITION_VOLUME);
         }
      }
   }

   // 1. Contraoperar si la peor va muy mal
   if(peorProfit <= TriggerContra) {
      int tipoContra = (tipoUltima == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
      double nuevoLote = NormalizarLote(ultimoLote * Multiplicador);
      EjecutarOrden(tipoContra, nuevoLote, "Contra");
      return;
   }
   
   // 2. Reforzar si la mejor va muy bien
   if(mejorProfit >= TriggerRefuerzo && total < 3) {
      EjecutarOrden(tipoUltima, LoteInicial, "Refuerzo");
      return;
   }
   
   // 3. Cierre por ciclo completo
   if(profitActualTotal >= ProfitObjetivo) {
      CerrarTodo("Ciclo Completado");
   }
}

//+------------------------------------------------------------------+
//| Gestión de Posiciones Individuales                               |
//+------------------------------------------------------------------+
void GestionarPosiciones() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            
            double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_COMMISSION);
            
            // Cierre individual si supera el profit mínimo
            if(profit >= ProfitCierreMin) {
               trade.PositionClose(ticket);
               Print("💰 Ganadora cerrada: $", profit);
               continue;
            }
            
            // BreakEven
            if(profit >= BE_Activacion) {
               MoverABreakEven(ticket);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Funciones de Apoyo                                               |
//+------------------------------------------------------------------+
void EjecutarOrden(int tipo, double lote, string comentario) {
   double precio = (tipo == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   bool res;
   if(tipo == ORDER_TYPE_BUY) res = trade.Buy(lote, _Symbol, precio, 0, 0, comentario);
   else res = trade.Sell(lote, _Symbol, precio, 0, 0, comentario);
   
   if(res) ultimaOperacion = TimeCurrent();
}

int ContarPosicionesPropias() {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol) 
            count++;
      }
   }
   return count;
}

double NormalizarLote(double lote) {
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double min = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double n = MathRound(lote/step)*step;
   if(n < min) n = min;
   if(n > max) n = max;
   return n;
}

void CerrarTodo(string razon) {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol) {
            perdidaAcumuladaDia += PositionGetDouble(POSITION_PROFIT);
            trade.PositionClose(ticket);
         }
      }
   }
   Print("🧹 Todo cerrado: ", razon);
}

void MoverABreakEven(ulong ticket) {
   if(PositionSelectByTicket(ticket)) {
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl = PositionGetDouble(POSITION_SL);
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
         double nuevoSL = NormalizeDouble(openPrice + (BreakEvenPips * point * 10), digits);
         if(sl < openPrice) trade.PositionModify(ticket, nuevoSL, 0);
      } else {
         double nuevoSL = NormalizeDouble(openPrice - (BreakEvenPips * point * 10), digits);
         if(sl > openPrice || sl == 0) trade.PositionModify(ticket, nuevoSL, 0);
      }
   }
}

void EvaluarEntradaInicial() {
   // Momentum simple usando el precio respecto a la vela anterior
   double close1 = iClose(_Symbol, _Period, 1);
   double close2 = iClose(_Symbol, _Period, 2);
   
   if(close1 > close2) EjecutarOrden(ORDER_TYPE_BUY, LoteInicial, "Inicio_Buy");
   else EjecutarOrden(ORDER_TYPE_SELL, LoteInicial, "Inicio_Sell");
}

void ActualizarComentario() {
   string msg = "=== MSC PRO EVOLUTION ===\n";
   msg += "Profit Hoy: $" + DoubleToString(perdidaAcumuladaDia, 2) + "\n";
   msg += "Ops Propias: " + IntegerToString(ContarPosicionesPropias()) + "\n";
   msg += "Estado: " + (ContarPosicionesPropias() > 0 ? "Gestionando..." : "Buscando entrada");
   Comment(msg);
}
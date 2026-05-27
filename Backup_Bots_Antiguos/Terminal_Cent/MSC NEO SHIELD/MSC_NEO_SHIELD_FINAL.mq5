//+------------------------------------------------------------------+
//|                                     MSC_NEO_SHIELD_FINAL_V2      |
//|   CIERRE INDIVIDUAL + CESTA + ESCUDO + BE/TRAILING               |
//+------------------------------------------------------------------+
#property copyright "Master Scalping Hybrid"
#property version   "5.02"
#property strict

#include <Trade\Trade.mqh>

input group "=== GESTIÓN DE BENEFICIOS ==="
input double   ProfitCierreIndividual = 2.0;    // SI UNA OPERACIÓN GANA ESTO, SE CIERRA SOLA
input double   ProfitObjetivoCesta    = 5.0;    // SI TODAS SUMAN ESTO, SE CIERRA TODO
input double   StopLossGlobal         = 15.0;   

input group "=== BREAK EVEN Y TRAILING ==="
input double   BE_Activacion          = 1.5;    
input double   GarantiaBE             = 1.0;    
input int      TrailingPips           = 15;     

input group "=== ESCUDO Y SEGURIDAD ==="
input double   LoteInicial            = 0.01;   
input int      DistanciaPipsHedge     = 20;     
input long     MagicNeo               = 888111; // Cambiado para empezar fresco

CTrade trade;

void OnTick() {
   // 1. VERIFICAR CIERRE INDIVIDUAL (Para no quedar atrapados)
   GestionarCierreIndividual();

   // 2. VERIFICAR CIERRE POR CESTA (Suma total)
   double pTotal = CalcularProfitTotal();
   if(pTotal >= ProfitObjetivoCesta) { CerrarTodoYLimpiar("CESTA COMPLETADA"); return; }
   if(pTotal <= -StopLossGlobal) { CerrarTodoYLimpiar("STOP EMERGENCIA"); return; }

   // 3. PROTECCIÓN ACTIVA (BE / TRAILING)
   GestionarProteccion();

   // 4. ENTRADA Y ESCUDO (Solo si hay hueco para operar)
   if(ContarPosiciones() == 0) {
      AbrirOperacionConEscudo();
   }
}

void GestionarCierreIndividual() {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == MagicNeo) {
         if(PositionGetDouble(POSITION_PROFIT) >= ProfitCierreIndividual) {
            trade.PositionClose(PositionGetTicket(i));
            Print("Operación cerrada individualmente por profit");
         }
      }
   }
}

// ... (Resto de funciones de apertura y escudo que ya tienes en la V5)
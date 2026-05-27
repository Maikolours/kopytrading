//+------------------------------------------------------------------+
//|                                     MSC_NEO_SHIELD_V6_MASTER     |
//|   CIERRE INDIVIDUAL + CESTA + ESCUDO + BE/TRAILING + HORARIOS    |
//+------------------------------------------------------------------+
#property copyright "Master Scalping Hybrid"
#property version   "6.0"
#property strict

#include <Trade\Trade.mqh>

input group "=== RELOJ DE OPERACIÓN ==="
input int      HoraInicio         = 9;      
input int      MinutoInicio       = 0;
input int      HoraFin            = 21;     
input int      MinutoFin          = 0;

input group "=== GESTIÓN DE BENEFICIOS (INDIVIDUAL Y CESTA) ==="
input double   LoteInicial            = 0.01;   
input double   ProfitCierreIndividual = 2.0;    // Si una operación gana esto, se cierra sola
input double   ProfitObjetivoCesta    = 5.0;    // Si todas suman esto, se limpia todo
input double   StopLossGlobal         = 15.0;   // Máxima pérdida permitida en la suma de todas
input int      MaxOperaciones         = 2;      

input group "=== PROTECCIÓN ACTIVA (BE Y TRAILING) ==="
input double   BE_Activacion          = 1.5;    // $ para poner el Stop en positivo
input double   GarantiaBE             = 1.0;    // $ que aseguras al saltar el BE
input bool     UsarTrailing           = true;   
input int      TrailingPips           = 15;     
input int      TrailingStep           = 3;      

input group "=== ESCUDO DE PROXIMIDAD (HEDGE) ==="
input int      DistanciaPipsHedge     = 20;     
input int      StopLevelManual        = 150;    

input group "=== SEGURIDAD ==="
input long     MagicNeo               = 777888; // Magic nuevo para ignorar errores pasados

CTrade trade;
datetime ultimaVela = 0;

void OnTick() {
   // 1. GESTIÓN DE BENEFICIOS INDIVIDUAL (Cierra las que ya ganan)
   GestionarCierreIndividual();

   // 2. GESTIÓN DE CESTA (Suma total de la cuenta)
   double profitTotal = CalcularProfitTotal();
   int nTotal = ContarPosiciones();

   if(nTotal > 0) {
      if(profitTotal >= ProfitObjetivoCesta) { CerrarTodoYLimpiar("CESTA: PROFIT COMPLETADO"); return; }
      if(profitTotal <= -StopLossGlobal) { CerrarTodoYLimpiar("CESTA: STOP EMERGENCIA"); return; }
   }

   // 3. PROTECCIÓN DE COLUMNA S/L (BE Y TRAILING)
   GestionarProteccionActiva();

   // 4. VIGILANCIA DEL ESCUDO (Asegura que siempre haya protección contraria)
   VerificarEscudoSincronizado();

   // 5. ENTRADA INICIAL CON FILTRO DE VELA (1 por cada 15 min)
   if(EstaEnHorario() && nTotal == 0 && ContarPendientes() == 0) {
      if(ultimaVela != iTime(_Symbol, _Period, 0)) {
         if(AbrirConEscudoInmediato()) ultimaVela = iTime(_Symbol, _Period, 0);
      }
   }

   // 6. OPERACIÓN DE APOYO (Solo si la primera ya está protegida con S/L en positivo)
   if(EstaEnHorario() && nTotal == 1 && ContarEnBE() == 1 && nTotal < MaxOperaciones) {
      if(trade.Buy(LoteInicial, _Symbol, 0, 0, 0, "APO")) Print("Abierta operación de apoyo");
   }
}

// --- FUNCIÓN DE CIERRE INDIVIDUAL (TU PETICIÓN) ---
void GestionarCierreIndividual() {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == MagicNeo) {
         if(PositionGetDouble(POSITION_PROFIT) >= ProfitCierreIndividual) {
            trade.PositionClose(PositionGetTicket(i));
            Print("Cerrada operación individual ganadora: ", PositionGetTicket(i));
         }
      }
   }
}

// --- GESTIÓN DE BE Y TRAILING ---
void GestionarProteccionActiva() {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == MagicNeo) {
         ulong t = PositionGetTicket(i);
         double pOpen = PositionGetDouble(POSITION_PRICE_OPEN);
         double sl = PositionGetDouble(POSITION_SL);
         double profit = PositionGetDouble(POSITION_PROFIT);
         long tipo = PositionGetInteger(POSITION_TYPE);
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

         if(profit >= BE_Activacion && sl == 0) {
            double nBE = (tipo == POSITION_TYPE_BUY) ? pOpen + (GarantiaBE*_Point*10) : pOpen - (GarantiaBE*_Point*10);
            trade.PositionModify(t, nBE, 0);
         }
         if(UsarTrailing && sl > 0) {
            if(tipo == POSITION_TYPE_BUY) {
               double nSL = bid - (TrailingPips*_Point*10);
               if(nSL > sl + (TrailingStep*_Point*10)) trade.PositionModify(t, nSL, 0);
            } else {
               double nSL = ask + (TrailingPips*_Point*10);
               if(nSL < sl - (TrailingStep*_Point*10)) trade.PositionModify(t, nSL, 0);
            }
         }
      }
   }
}

// --- APERTURA CON ESCUDO INCORPORADO ---
bool AbrirConEscudoInmediato() {
   double ma[]; ArraySetAsSeries(ma, true);
   int h = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   bool res = false;
   if(CopyBuffer(h, 0, 0, 1, ma) > 0) {
      double dist = DistanciaPipsHedge * _Point * 10;
      if(SymbolInfoDouble(_Symbol, SYMBOL_BID) > ma[0]) {
         if(trade.Buy(LoteInicial, _Symbol, 0, 0, 0, "PRI")) {
            trade.SellStop(LoteInicial, SymbolInfoDouble(_Symbol, SYMBOL_BID)-dist, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "SHIELD");
            res = true;
         }
      } else {
         if(trade.Sell(LoteInicial, _Symbol, 0, 0, 0, "PRI")) {
            trade.BuyStop(LoteInicial, SymbolInfoDouble(_Symbol, SYMBOL_ASK)+dist, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "SHIELD");
            res = true;
         }
      }
   }
   IndicatorRelease(h);
   return res;
}

// --- VERIFICACIÓN DE ESCUDO FALTANTE ---
void VerificarEscudoSincronizado() {
   int c=0, v=0, ps=0, pb=0; double pRef=0;
   for(int i=0; i<PositionsTotal(); i++) {
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == MagicNeo) {
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) { c++; pRef=PositionGetDouble(POSITION_PRICE_OPEN); }
         else { v++; pRef=PositionGetDouble(POSITION_PRICE_OPEN); }
      }
   }
   for(int i=0; i<OrdersTotal(); i++) {
      if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC) == MagicNeo) {
         if(OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_BUY_STOP) pb++;
         if(OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_SELL_STOP) ps++;
      }
   }
   double d = DistanciaPipsHedge*_Point*10;
   if(c>0 && v==0 && ps==0) trade.SellStop(LoteInicial, pRef-d, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "SHIELD");
   if(v>0 && c==0 && pb==0) trade.BuyStop(LoteInicial, pRef+d, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "SHIELD");
}

// --- AUXILIARES ---
double CalcularProfitTotal() { double p=0; for(int i=0; i<PositionsTotal(); i++) if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC)==MagicNeo) p+=PositionGetDouble(POSITION_PROFIT); return p; }
int ContarPosiciones() { int c=0; for(int i=0; i<PositionsTotal(); i++) if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC)==MagicNeo) c++; return c; }
int ContarPendientes() { int c=0; for(int i=0; i<OrdersTotal(); i++) if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC)==MagicNeo) c++; return c; }
int ContarEnBE() {
   int count=0;
   for(int i=0; i<PositionsTotal(); i++) {
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC)==MagicNeo) {
         double sl=PositionGetDouble(POSITION_SL), po=PositionGetDouble(POSITION_PRICE_OPEN);
         if(sl>0 && ((PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY && sl>=po) || (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL && sl<=po))) count++;
      }
   }
   return count;
}
void CerrarTodoYLimpiar(string m) {
   for(int i=PositionsTotal()-1; i>=0; i--) if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC)==MagicNeo) trade.PositionClose(PositionGetTicket(i));
   for(int i=OrdersTotal()-1; i>=0; i--) if(OrderSelect(OrderGetTicket(i)) && OrderGetInteger(ORDER_MAGIC)==MagicNeo) trade.OrderDelete(OrderGetTicket(i));
   Print(m);
}
bool EstaEnHorario() { MqlDateTime dt; TimeToStruct(TimeCurrent(), dt); int mNow=(dt.hour*60)+dt.min, mIni=(HoraInicio*60)+MinutoInicio, mFin=(HoraFin*60)+MinutoFin; return (mNow>=mIni && mNow<mFin); }
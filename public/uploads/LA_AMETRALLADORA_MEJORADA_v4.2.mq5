
//+------------------------------------------------------------------+
//|         LA_AMETRALLADORA_MEJORADA_v4.2.mq5                       |
//|    IA DE PRE-ANÁLISIS + CIERRE X % BENEFICIO DIARIO + STICKY    |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Bot Oficial"
#property version   "4.20"
#property strict
#property description "La Ametralladora v4.2 | Inteligencia de entrada y blindaje de beneficios"

#include <Trade\Trade.mqh>

//--- LICENCIA ---
input group "=== LICENCIA KOPYTRADE ==="
input long     CuentaDemo         = 0;
input long     CuentaReal         = 0;

//--- IA DE PRE-ANÁLISIS ---
input group "=== IA DE PRE-ANÁLISIS ==="
input ENUM_TIMEFRAMES Analisis_TF = PERIOD_H1;     // Gráfico para confirmar tendencia
input int    Minutos_Espera_Analisis = 10;         // Esperar X minutos analizando antes de entrar
input bool   Solo_Contra_Tendencia = false;        // Permitir entrar contra tendencia (No recomendado)

//--- PARÁMETROS PRINCIPAL (MAIN) ---
input group "=== PARÁMETROS PRINCIPAL (MAIN) ==="
input double   LoteMain           = 0.01;
input double   TP_Main_USD        = 3.0;
input double   Trigger_O_Seguro   = 2.0;    
input double   Ganancia_Asegurada = 1.5;    
input bool     Activar_Trail_Main = false;

//--- PARÁMETROS ESCUDO (SHIELD) ---
input group "=== PARÁMETROS ESCUDO (SHIELD) ==="
input double   LoteShield         = 0.02;
input int      Max_Hedges         = 3;             // 🛡️ Máximo de órdenes de escudo
input double   DistanciaAcechoUSD = 10.0;
input bool     EscudoSticky       = true;          // La línea verde persigue al precio

//--- RIESGO Y CIERRES GLOBALES ---
input group "=== RIESGO Y CIERRES GLOBALES ==="
input double   ProfitCicloTotal   = 5.0;
input double   Corte_Loss_Pct_Diario = 15.0;       // 🛑 Cerrar todo si pierdes el 15% de lo ganado hoy
input double   RiesgoMaxAbsoluto  = 50.0;          // Por si no hay ganancias hoy

CTrade trade;
long magic = 777112;
datetime timeToStart = 0;
bool cicloEnPerdida = false;

int OnInit() {
   trade.SetExpertMagicNumber(magic);
   trade.SetTypeFillingBySymbol(_Symbol);
   timeToStart = TimeCurrent() + (Minutos_Espera_Analisis * 60);
   return(INIT_SUCCEEDED);
}

void OnTick() {
   if(AccountInfoInteger(ACCOUNT_TRADE_MODE) != ACCOUNT_TRADE_MODE_DEMO && AccountInfoInteger(ACCOUNT_LOGIN) != CuentaReal) return;

   GestionCestaSegura();
   if(EscudoSticky) MoverEscudoSticky();
   
   int nPos = ContarPosiciones();
   int nOrd = ContarPendientes();
   
   // 🛡️ Gestión de Escudos
   if(nPos >= 1 && nPos < (Max_Hedges+1) && nOrd == 0) ColocarEscudo();
   
   // 🔫 Ametralladora Inteligente
   if(nPos == 0 && nOrd == 0) {
      if(TimeCurrent() >= timeToStart) AbrirPrincipal();
      else Comment("Analizando mercado... Esperando confirmación de tendencia.");
   }
}

void AbrirPrincipal() {
   // ANÁLISIS DE TENDENCIA (Mirando Analisis_TF)
   double close1 = iClose(_Symbol, Analisis_TF, 1);
   double close2 = iClose(_Symbol, Analisis_TF, 2);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(close1 > close2) { // Tendencia Alcista
      if(trade.Buy(LoteMain, _Symbol, ask, 0, 0, "MAIN_V4.2_BUY")) {
         timeToStart = 0; // Reset
      }
   }
   else if(close1 < close2) { // Tendencia Bajista
      if(trade.Sell(LoteMain, _Symbol, bid, 0, 0, "MAIN_V4.2_SELL")) {
         timeToStart = 0; 
      }
   }
}

void GestionCestaSegura() {
   double curProfit = 0; 
   int n = 0;
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong t = PositionGetTicket(i);
      if(PositionSelectByTicket(t) && PositionGetInteger(POSITION_MAGIC) == magic) {
         curProfit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         n++;
      }
   }
   
   // Cálculo de Profit Diario para el Stop Loss
   double dailyGain = GetDailyProfit();
   double limitLoss = dailyGain > 0 ? (dailyGain * (Corte_Loss_Pct_Diario/100)) : RiesgoMaxAbsoluto;
   if(limitLoss < 10) limitLoss = 10; // Mínimo de seguridad

   // 🛑 CIERRE POR % DE GANANCIAS DIARIAS
   if(n > 0 && curProfit <= -limitLoss) {
      CerrarTodo();
      timeToStart = TimeCurrent() + (Minutos_Espera_Analisis * 60); // Pausa tras pérdida
      Print("🛑 FRENO DE SEGURIDAD: Pérdida del 15% diario alcanzada. Limpiando.");
      return;
   }

   // ✅ CIERRE POR OBJETIVO
   if(n > 0 && curProfit >= ProfitCicloTotal) {
      CerrarTodo();
      timeToStart = TimeCurrent(); // Re-disparo inmediato en ganancias
      Print("✅ Ciclo Ametralladora en Profit: $", curProfit);
   }
}

double GetDailyProfit() {
   double profit = 0;
   HistorySelect(iTime(_Symbol, PERIOD_D1, 0), TimeCurrent());
   for(int i=0; i<HistoryDealsTotal(); i++) {
      ulong t = HistoryDealGetTicket(i);
      if(HistoryDealSelect(t)) {
         if(HistoryDealGetInteger(t, DEAL_MAGIC) == magic)
            profit += HistoryDealGetDouble(t, DEAL_PROFIT);
      }
   }
   return profit;
}

void MoverEscudoSticky() {
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double dist = (DistanciaAcechoUSD / 0.01) * _Point;

   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      ulong t = OrderGetTicket(i);
      if(!OrderSelect(t) || OrderGetInteger(ORDER_MAGIC) != magic) continue;
      double price = OrderGetDouble(ORDER_PRICE_OPEN);
      if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_STOP) {
         double ideal = NormalizeDouble(bid - dist, _Digits);
         if(ideal > price + (5 * _Point)) trade.OrderModify(t, ideal, 0, 0, ORDER_TIME_GTC, 0);
      }
      else if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_STOP) {
         double ideal = NormalizeDouble(ask + dist, _Digits);
         if(ideal < price - (5 * _Point)) trade.OrderModify(t, ideal, 0, 0, ORDER_TIME_GTC, 0);
      }
   }
}

void ColocarEscudo() {
   double dist = (DistanciaAcechoUSD / 0.01) * _Point;
   for(int i=0; i<PositionsTotal(); i++) {
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == magic) {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            trade.SellStop(LoteShield, SymbolInfoDouble(_Symbol, SYMBOL_BID) - dist, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "SHIELD_V4.2");
         else
            trade.BuyStop(LoteShield, SymbolInfoDouble(_Symbol, SYMBOL_ASK) + dist, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "SHIELD_V4.2");
         break;
      }
   }
}

void CerrarTodo() {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong t = PositionGetTicket(i);
      if(PositionSelectByTicket(t) && PositionGetInteger(POSITION_MAGIC) == magic) trade.PositionClose(t);
   }
   for(int i=OrdersTotal()-1; i>=0; i--) {
      ulong t = OrderGetTicket(i);
      if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC) == magic) trade.OrderDelete(t);
   }
}

int ContarPosiciones() { int c=0; for(int i=0;i<PositionsTotal();i++) if(PositionSelectByTicket(PositionGetTicket(i))&&PositionGetInteger(POSITION_MAGIC)==magic) c++; return c; }
int ContarPendientes() { int c=0; for(int i=0;i<OrdersTotal();i++) if(OrderSelect(OrderGetTicket(i))&&OrderGetInteger(ORDER_MAGIC)==magic) c++; return c; }

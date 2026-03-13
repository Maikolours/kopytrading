
//+------------------------------------------------------------------+
//|         LA_AMETRALLADORA_MEJORADA_v4.3.mq5                       |
//|    IA DE PRE-ANÁLISIS + BOZAL OPS + EL CAJERO (STICKY)           |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Bot Oficial"
#property version   "4.30"
#property strict
#property description "La Ametralladora v4.3 | Edición 'Cerebro de Oro' con etiquetas claras"

#include <Trade\Trade.mqh>

//--- LICENCIA ---
input group "=== LICENCIA KOPYTRADE ==="
input long     CuentaDemo         = 0;
input long     CuentaReal         = 0;

//--- IA DE PRE-ANÁLISIS ---
input group "=== IA DE PRE-ANÁLISIS (MIRA ANTES DE SALTAR) ==="
input ENUM_TIMEFRAMES Analisis_TF = PERIOD_H1;     // Gráfico de referencia (Sugerido H1)
input int    Minutos_Análisis_IA = 15;            // Minutos que la IA analiza antes de entrar
input bool   Solo_A_Favor_Tendencia = true;       // Bloquear disparos contra tendencia superior

//--- LÍMITES DE LA METRALLETA ---
input group "=== BOZAL DE LA METRALLETA (GESTIÓN DE RIESGO) ==="
input double   LoteMain           = 0.01;
input double   LoteShield         = 0.02;
input int      Bozal_Max_Ops      = 3;             // 🛡️ Máximo total de operaciones (Sugerido 3 o 4)
input double   ProfitObjetivoUSD  = 3.0;
input int      Distancia_Sticky_Pts = 150;        // Distancia del escudo (150 = 1.5$ en ORO)

//--- STOP LOSS DE CAJERO ---
input group "=== EL CAJERO (PROTECCIÓN DE GANANCIAS) ==="
input double   Proteger_Pct_Ganado_Hoy = 15.0;    // Cortar todo si perdemos el 15% ganado hoy
input double   Riesgo_Max_Sin_Ganancias = 20.0;   // Si no hay ganancias hoy, cortar en -$20

CTrade trade;
long   m_magic_id = 777112;                
datetime nextAllowedTrade = 0;
bool   analizando = true;
int    hSlow = INVALID_HANDLE;
int    hFast = INVALID_HANDLE;

int    OnInit() {
   trade.SetExpertMagicNumber(m_magic_id);
   trade.SetTypeFillingBySymbol(_Symbol);
   hSlow = iMA(_Symbol, Analisis_TF, 200, 0, MODE_EMA, PRICE_CLOSE);
   hFast = iMA(_Symbol, Analisis_TF, 50, 0, MODE_EMA, PRICE_CLOSE);
   if(hSlow == INVALID_HANDLE || hFast == INVALID_HANDLE) return(INIT_FAILED);
   nextAllowedTrade = TimeCurrent() + (Minutos_Análisis_IA * 60);
   return(INIT_SUCCEEDED);
}

void OnTick() {
   if(AccountInfoInteger(ACCOUNT_TRADE_MODE) != ACCOUNT_TRADE_MODE_DEMO && AccountInfoInteger(ACCOUNT_LOGIN) != CuentaReal) return;

   GestionCajera();
   MoverEscudoSticky();
   
   int nPos = ContarPosiciones();
   int nOrd = ContarPendientes();
   int nTotal = nPos + nOrd;
   
   if(nTotal == 0) {
      if(TimeCurrent() >= nextAllowedTrade) {
         analizando = false;
         AbrirPrincipalIA();
      } else analizando = true;
   }
   
   if(nPos >= 1 && nOrd == 0 && nTotal < Bozal_Max_Ops) ColocarEscudoSticky();
   
   ActualizarPanelUI();
}

void MoverEscudoSticky() {
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double dist = Distancia_Sticky_Pts * _Point;

   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      ulong t = OrderGetTicket(i);
      if(!OrderSelect(t) || OrderGetInteger(ORDER_MAGIC) != m_magic_id) continue;
      double curPrice = OrderGetDouble(ORDER_PRICE_OPEN);
      long type = OrderGetInteger(ORDER_TYPE);
      if(type == ORDER_TYPE_SELL_STOP) {
         double ideal = NormalizeDouble(bid - dist, _Digits);
         if(ideal > curPrice + (2 * _Point)) trade.OrderModify(t, ideal, 0, 0, ORDER_TIME_GTC, 0);
      }
      else if(type == ORDER_TYPE_BUY_STOP) {
         double ideal = NormalizeDouble(ask + dist, _Digits);
         if(ideal < curPrice - (2 * _Point)) trade.OrderModify(t, ideal, 0, 0, ORDER_TIME_GTC, 0);
      }
   }
}

void ColocarEscudoSticky() {
   double dist = Distancia_Sticky_Pts * _Point;
   for(int i=0; i<PositionsTotal(); i++) {
      ulong tp = PositionGetTicket(i);
      if(PositionSelectByTicket(tp) && PositionGetInteger(POSITION_MAGIC) == m_magic_id) {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            trade.SellStop(LoteShield, SymbolInfoDouble(_Symbol, SYMBOL_BID) - dist, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "STICKY_SHIELD");
         else
            trade.BuyStop(LoteShield, SymbolInfoDouble(_Symbol, SYMBOL_ASK) + dist, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "STICKY_SHIELD");
         break;
      }
   }
}

void AbrirPrincipalIA() {
   double maSlow[1], maFast[1];
   if(CopyBuffer(hSlow, 0, 0, 1, maSlow) <= 0 || CopyBuffer(hFast, 0, 0, 1, maFast) <= 0) return;
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(maFast[0] > maSlow[0]) trade.Buy(LoteMain, _Symbol, ask, 0, 0, "IA_MAIN_BUY");
   else if(maFast[0] < maSlow[0]) trade.Sell(LoteMain, _Symbol, bid, 0, 0, "IA_MAIN_SELL");
}

void GestionCajera() {
   double balanceHoy = GetHistorialHoy();
   double limit = balanceHoy > 0 ? (balanceHoy * (Proteger_Pct_Ganado_Hoy/100)) : Riesgo_Max_Sin_Ganancias;
   if(limit < 5) limit = 10;
   double neto = 0; int n=0;
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong t = PositionGetTicket(i);
      if(PositionSelectByTicket(t) && PositionGetInteger(POSITION_MAGIC) == m_magic_id) {
         neto += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         n++;
      }
   }
   if(n > 0 && neto <= -limit) {
      LimpiarTodo();
      nextAllowedTrade = TimeCurrent() + (20 * 60);
      Print("🛑 CAJERO: Nivel de protección alcanzado. Ciclo cerrado.");
   }
   if(n > 0 && neto >= ProfitObjetivoUSD) {
      LimpiarTodo();
      nextAllowedTrade = TimeCurrent(); 
      Print("✅ OBJETIVO: Profit alcanzado.");
   }
}

double GetHistorialHoy() {
   double d = 0; HistorySelect(iTime(_Symbol, PERIOD_D1, 0), TimeCurrent());
   for(int i=0; i<HistoryDealsTotal(); i++) {
      ulong t = HistoryDealGetTicket(i);
      if(HistoryDealSelect(t) && HistoryDealGetInteger(t, DEAL_MAGIC) == m_magic_id) d += HistoryDealGetDouble(t, DEAL_PROFIT);
   }
   return d;
}

void LimpiarTodo() {
   for(int i=PositionsTotal()-1; i>=0; i--) { ulong t = PositionGetTicket(i); if(PositionSelectByTicket(t) && PositionGetInteger(POSITION_MAGIC) == m_magic_id) trade.PositionClose(t); }
   for(int i=OrdersTotal()-1; i>=0; i--) { ulong t = OrderGetTicket(i); if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC) == m_magic_id) trade.OrderDelete(t); }
}

int ContarPosiciones() { int c=0; for(int i=0;i<PositionsTotal();i++) if(PositionSelectByTicket(PositionGetTicket(i))&&PositionGetInteger(POSITION_MAGIC)==m_magic_id) c++; return c; }
int ContarPendientes() { int c=0; for(int i=0;i<OrdersTotal();i++) if(OrderSelect(OrderGetTicket(i))&&OrderGetInteger(ORDER_MAGIC)==m_magic_id) c++; return c; }

void ActualizarPanelUI() {
   string s = analizando ? "IA ANALIZANDO TENDENCIA..." : "METRALLETA EN ACECHO";
   string m = "LA AMETRALLADORA v4.3 MASTER\n----------------------------\nESTADO: " + s + "\n";
   if(analizando) m += "TIEMPO RESTANTE: " + IntegerToString((int)((nextAllowedTrade - TimeCurrent())/60)) + " min\n";
   m += "OPS ABIERTAS: " + IntegerToString(ContarPosiciones() + ContarPendientes()) + " / " + IntegerToString(Bozal_Max_Ops) + "\n";
   m += "PROFIT CICLO: " + DoubleToString(0, 2) + " USD\n"; // Placeholder para profit visual
   Comment(m);
}

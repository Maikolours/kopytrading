
//+------------------------------------------------------------------+
//|         KOPYTRADE_XAUUSD_Ametralladora v4.1 (PROTECTED)          |
//|    LÓGICA STICKY + FILTRO TENDENCIA + LÍMITE DE COBERTURAS       |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Bot Oficial"
#property version   "4.10"
#property strict
#property description "La Ametralladora v4.1 | Blindaje Anti-Rachas"

#include <Trade\Trade.mqh>

//--- LICENCIA ---
input group "=== LICENCIA KOPYTRADE ==="
input long     CuentaDemo         = 0;      
input long     CuentaReal         = 0;      

//--- AJUSTES DE DISPARO ---
input group "=== AJUSTES DE DISPARO (AMETRALLADORA) ==="
input double   LoteInicial        = 0.01;
input double   ProfitDisparo      = 3.0;    
input bool     ModoAmetralladora  = true;   

//--- LÍMITES DE SEGURIDAD (CINTURÓN) ---
input group "=== LÍMITES DE SEGURIDAD ==="
input int      Max_Coberturas     = 3;      // 🛡️ NO abrir más de 3 ventas/compras de escudo
input double   Riesgo_Max_USD     = 20.0;   // 🛑 Frenar con -20$ de pérdida
input bool     UsaFiltroTendencia = true;   // Prohibido vender si el precio sube mucho

//--- PARÁMETROS STICKY ---
input group "=== PARÁMETROS STICKY (LÍNEA VERDE) ==="
input int      DistanciaVerde     = 150;    
input double   LoteHedge          = 0.02;   

CTrade trade;
long magic = 777112;
int emaH = INVALID_HANDLE;

int OnInit() {
   emaH = iMA(_Symbol, _Period, 200, 0, MODE_EMA, PRICE_CLOSE);
   trade.SetExpertMagicNumber(magic);
   trade.SetTypeFillingBySymbol(_Symbol);
   return(INIT_SUCCEEDED);
}

void OnTick() {
   GestionarCierres();
   PersiguirConLineaVerde();
   
   int nPos = ContarPosiciones();
   int nOrd = ContarPendientes();
   int nHedge = ContarCoberturas();
   
   if(nPos >= 1 && nOrd == 0 && nHedge < Max_Coberturas) ColocarEscudo();
   if(nPos == 0 && nOrd == 0 && ModoAmetralladora) AbrirPrincipal();
   
   Comment("AMETRALLADORA v4.1 PROTECTED\nCoberturas: " + IntegerToString(nHedge) + "/" + IntegerToString(Max_Coberturas) + 
           "\nEstado: " + (nPos > 0 ? "ACECHANDO" : "LISTO"));
}

void PersiguirConLineaVerde() {
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double dist = DistanciaVerde * _Point;

   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      ulong t = OrderGetTicket(i);
      if(!OrderSelect(t) || OrderGetInteger(ORDER_MAGIC) != magic) continue;
      
      double price = OrderGetDouble(ORDER_PRICE_OPEN);
      if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_STOP) {
         double target = NormalizeDouble(bid - dist, _Digits);
         if(target > price + (5 * _Point)) trade.OrderModify(t, target, 0, 0, ORDER_TIME_GTC, 0);
      }
      else if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_STOP) {
         double target = NormalizeDouble(ask + dist, _Digits);
         if(target < price - (5 * _Point)) trade.OrderModify(t, target, 0, 0, ORDER_TIME_GTC, 0);
      }
   }
}

void GestionarCierres() {
   double total = 0; int n=0;
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong t = PositionGetTicket(i);
      if(PositionSelectByTicket(t) && PositionGetInteger(POSITION_MAGIC) == magic) {
         total += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         n++;
      }
   }
   
   // Freno de mano 🛑
   if(n > 0 && total <= -Riesgo_Max_USD) {
      CerrarYLimpiar();
      Print("🛑 FRENO DE MANO: Pérdida de -", Riesgo_Max_USD, " alcanzada. Limpiando.");
      return;
   }

   if(n > 0 && total >= ProfitDisparo) {
      CerrarYLimpiar();
      Print("✅ Profit de disparo completado.");
   }
}

void CerrarYLimpiar() {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong t = PositionGetTicket(i);
      if(PositionSelectByTicket(t) && PositionGetInteger(POSITION_MAGIC) == magic) trade.PositionClose(t);
   }
   for(int i=OrdersTotal()-1; i>=0; i--) {
      ulong t = OrderGetTicket(i);
      if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC) == magic) trade.OrderDelete(t);
   }
}

void ColocarEscudo() {
   double ma[1]; CopyBuffer(emaH, 0, 0, 1, ma);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double dist = DistanciaVerde * _Point;
   
   for(int i=0; i<PositionsTotal(); i++) {
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC) == magic) {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            if(UsaFiltroTendencia && bid < ma[0]) return; // No vender si hay mucha fuerza alcista
            trade.SellStop(LoteHedge, bid - dist, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "HEDGE_V4.1");
         } else {
            if(UsaFiltroTendencia && ask > ma[0]) return; // No comprar si hay mucha fuerza bajista
            trade.BuyStop(LoteHedge, ask + dist, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "HEDGE_V4.1");
         }
         break;
      }
   }
}

void AbrirPrincipal() {
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   trade.Buy(LoteInicial, _Symbol, ask, 0, 0, "MAIN_V4.1");
}

int ContarPosiciones() { int c=0; for(int i=0;i<PositionsTotal();i++) if(PositionSelectByTicket(PositionGetTicket(i))&&PositionGetInteger(POSITION_MAGIC)==magic) c++; return c; }
int ContarPendientes() { int c=0; for(int i=0;i<OrdersTotal();i++) if(OrderSelect(OrderGetTicket(i))&&OrderGetInteger(ORDER_MAGIC)==magic) c++; return c; }
int ContarCoberturas() { int c=0; for(int i=0;i<PositionsTotal();i++) if(PositionSelectByTicket(PositionGetTicket(i))&&PositionGetInteger(POSITION_MAGIC)==magic&&PositionGetString(POSITION_COMMENT)=="HEDGE_V4.1") c++; return c; }
bool EstaEnHorario() { MqlDateTime dt; TimeToStruct(TimeCurrent(), dt); return(dt.hour >= 9 && dt.hour < 21); }

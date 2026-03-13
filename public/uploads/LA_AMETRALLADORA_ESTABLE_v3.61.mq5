
//+------------------------------------------------------------------+
//|             KOPYTRADE_XAUUSD_Ametralladora v3.61                 |
//|        ZERO FRICTION - MEJORADO CONTRA ERRORES [FROZEN]          |
//+------------------------------------------------------------------+
#property copyright "KOPYTRADE - Bot Oficial"
#property version   "3.61"
#property strict

#include <Trade\Trade.mqh>

//--- LICENCIA ---
input group "=== LICENCIA KOPYTRADE ==="
input long     CuentaDemo         = 1028690;
input long     CuentaReal         = 0;      

//--- AJUSTES OPERATIVOS ---
input group "=== RELOJ Y FILTROS ==="
input int      HoraInicio         = 9;      // Cambiado a las 9 por tu preferencia
input int      HoraFin            = 22;     // Para que no opere de madrugada si quieres
input bool     Usar_Filtros_Tecnicos = true;  

//--- POSICIÓN PRINCIPAL (0.01) ---
input group "=== PARÁMETROS PRINCIPAL (MAIN) ==="
input double   LoteMain           = 0.01;
input double   TP_Main_USD        = 5.0;      
input double   BE_Main_Trigger    = 2.0;      
input double   BE_Main_Offset     = 1.5;      
input bool     Activar_Trail_Main = true;   
input int      Trailing_Main_Points = 150;    

//--- POSICIÓN ESCUDO (0.02) ---
input group "=== PARÁMETROS ESCUDO (SHIELD) ==="
input double   LoteShield         = 0.02;   
input double   DistanciaAcechoUSD = 4.0;      
input double   TP_Shield_USD      = 10.0;     
input bool     Hedge_Proteccion_Indep = false; 

//--- RIESGO GLOBAL Y CICLO ---
input group "=== RIESGO GLOBAL Y CICLO ==="
input double   ProfitCicloTotal   = 3.0;      
input double   ProfitMaxDiario    = 200.0;    
input double   PerdidaMaxDiaria   = 500.0;    
input long     MagicNumber        = 777112; 

CTrade trade;
bool   licenseValid  = false;
int    emaH = INVALID_HANDLE, rsiH = INVALID_HANDLE;

//+------------------------------------------------------------------+
int OnInit() {
   long cuenta = AccountInfoInteger(ACCOUNT_LOGIN);
   if(cuenta != CuentaDemo && cuenta != CuentaReal && AccountInfoInteger(ACCOUNT_TRADE_MODE) != ACCOUNT_TRADE_MODE_DEMO) return(INIT_FAILED);
   emaH = iMA(_Symbol, _Period, 14, 0, MODE_EMA, PRICE_CLOSE);
   rsiH = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   licenseValid = true;
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetTypeFillingBySymbol(_Symbol);
   Comment(""); EventSetTimer(1);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) { ObjectsDeleteAll(0, "AMTR_"); EventKillTimer(); }
void OnTimer() { DibujaPanel(CalcularProfitDiario()); }

void OnTick() {
   if(!licenseValid) return;
   
   GestionarCicloBlindado();
   MoverEscudoSticky();
   
   int nTotal = ContarPosiciones();
   int nPendientes = ContarPendientes();
   
   if(nTotal == 0 && EstaEnHorario()) {
      if(nPendientes > 0) BorrarPendientes();
      AbrirPrincipal();
      return;
   }
   if(nTotal == 1 && nPendientes == 0) ColocarEscudo();
}

void GestionarCicloBlindado() {
   double totalP = 0; int nPos = 0;
   ulong tMain = 0, tShield = 0;
   double pMain = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong t = PositionGetTicket(i);
      if(!PositionSelectByTicket(t) || PositionGetInteger(POSITION_MAGIC) != MagicNumber || PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      double p = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      double vol = PositionGetDouble(POSITION_VOLUME);
      totalP += p; nPos++;
      if(vol <= LoteMain + 0.001) { tMain = t; pMain = p; }
      else { tShield = t; }
   }

   if(nPos == 1 && tMain > 0) {
      if(pMain >= TP_Main_USD) { trade.PositionClose(tMain); return; }
      if(pMain >= BE_Main_Trigger) SafeModify(tMain, BE_Main_Offset, false);
      if(Activar_Trail_Main) SafeModify(tMain, Trailing_Main_Points, true);
   }
   else if(nPos >= 2) {
      if(totalP >= ProfitCicloTotal) { SerialCloseAll("Ciclo Titanium"); return; }
      if(pMain >= BE_Main_Trigger) { trade.PositionClose(tShield); return; }
   }
}

void DibujaPanel(double profHoy) {
   string nameBg = "AMTR_BG";
   if(ObjectFind(0, nameBg) < 0) {
      ObjectCreate(0, nameBg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, nameBg, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, nameBg, OBJPROP_YDISTANCE, 20);
      ObjectSetInteger(0, nameBg, OBJPROP_XSIZE, 300);
      ObjectSetInteger(0, nameBg, OBJPROP_YSIZE, 130);
      ObjectSetInteger(0, nameBg, OBJPROP_BGCOLOR, clrBlack);
   }
   CrearLabel("AMTR_L1", "VERSION 3.61 ZERO-FRICTION ⚡", 20, 35, 10, clrLime);
   CrearLabel("AMTR_L2", "Profit Hoy: " + DoubleToString(profHoy, 2) + " USD", 20, 55, 10, clrCyan);
   CrearLabel("AMTR_L3", "Magic: " + (string)MagicNumber + " | Pos: " + (string)ContarPosiciones(), 20, 75, 9, clrWhite);
   CrearLabel("AMTR_L4", "Safe Mode: ACTIVADO ✔️", 20, 95, 9, clrYellow);
}

void CrearLabel(string name, string text, int x, int y, int size, color col) {
   if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_COLOR, col);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
}

void SafeModify(ulong t, double val, bool isTrail) {
   if(!PositionSelectByTicket(t)) return;
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double pt = SymbolInfoDouble(_Symbol, SYMBOL_POINT), open = PositionGetDouble(POSITION_PRICE_OPEN);
   double sl = PositionGetDouble(POSITION_SL); long type = PositionGetInteger(POSITION_TYPE);
   
   double nSL = 0;
   if(isTrail) nSL = (type == POSITION_TYPE_BUY) ? bid - (val * pt) : ask + (val * pt);
   else nSL = (type == POSITION_TYPE_BUY) ? open + (val / (PositionGetDouble(POSITION_VOLUME)*100)) : open - (val / (PositionGetDouble(POSITION_VOLUME)*100));
   
   double freeze = MathMax(SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL), SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL)) * pt;
   nSL = NormalizePrice(nSL);

   // Solo modificamos si estamos fuera de la zona de congelación (freeze)
   if(type == POSITION_TYPE_BUY) {
      if(bid - nSL < freeze + (10 * pt)) return; 
      if(sl < nSL || sl == 0) trade.PositionModify(t, nSL, 0);
   } else {
      if(nSL - ask < freeze + (10 * pt)) return;
      if(sl > nSL || sl == 0) trade.PositionModify(t, nSL, 0);
   }
}

void MoverEscudoSticky() {
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      ulong t = OrderGetTicket(i);
      if(!OrderSelect(t) || OrderGetInteger(ORDER_MAGIC) != MagicNumber || OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID), ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK), pt = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double curP = OrderGetDouble(ORDER_PRICE_OPEN);
      double freeze = MathMax(SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL), SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL)) * pt;
      
      if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_STOP) {
         double ideal = NormalizePrice(bid - DistanciaAcechoUSD);
         if(bid - ideal < freeze + (10*pt)) return;
         if(ideal > curP + 0.1) trade.OrderModify(t, ideal, 0, 0, ORDER_TIME_GTC, 0);
      }
      if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_STOP) {
         double ideal = NormalizePrice(ask + DistanciaAcechoUSD);
         if(ideal - ask < freeze + (10*pt)) return;
         if(ideal < curP - 0.1) trade.OrderModify(t, ideal, 0, 0, ORDER_TIME_GTC, 0);
      }
   }
}

void ColocarEscudo() {
   double ask=SymbolInfoDouble(_Symbol, SYMBOL_ASK), bid=SymbolInfoDouble(_Symbol, SYMBOL_BID), pt = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double freeze = MathMax(SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL), SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL)) * pt;
   int nB=0, nS=0;
   for(int i=0; i<PositionsTotal(); i++) {
      if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetInteger(POSITION_MAGIC)==MagicNumber && PositionGetString(POSITION_SYMBOL)==_Symbol) {
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) nB++; else nS++;
      }
   }
   if(nB>nS) {
      double pr = NormalizePrice(bid - DistanciaAcechoUSD);
      if(bid - pr < freeze + (10*pt)) pr = bid - freeze - (15*pt);
      trade.SellStop(LoteShield, pr, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "SHIELD");
   } else if(nS>nB) {
      double pr = NormalizePrice(ask + DistanciaAcechoUSD);
      if(pr - ask < freeze + (10*pt)) pr = ask + freeze + (15*pt);
      trade.BuyStop(LoteShield, pr, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "SHIELD");
   }
}

void AbrirPrincipal() {
   if(Usar_Filtros_Tecnicos) {
      double ma[1], rsi[1]; CopyBuffer(emaH, 0, 0, 1, ma); CopyBuffer(rsiH, 0, 0, 1, rsi);
      double p = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(p > ma[0] && rsi[0] < 70) trade.Buy(LoteMain, _Symbol, 0, 0, 0, "MAIN_BUY");
      if(p < ma[0] && rsi[0] > 30) trade.Sell(LoteMain, _Symbol, 0, 0, 0, "MAIN_SELL");
   } else trade.Buy(LoteMain, _Symbol, 0, 0, 0, "NON_STOP");
}

double NormalizePrice(double p) {
   double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(p<=0) return 0; return(NormalizeDouble(MathRound(p/ts)*ts, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
}

double CalcularProfitDiario() {
   double pr = 0; HistorySelect(iTime(_Symbol, PERIOD_D1, 0), TimeCurrent());
   for(int i=HistoryDealsTotal()-1; i>=0; i--) {
      ulong t = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(t, DEAL_MAGIC)==MagicNumber && HistoryDealGetString(t, DEAL_SYMBOL)==_Symbol)
         pr += HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_SWAP) + HistoryDealGetDouble(t, DEAL_COMMISSION);
   }
   return pr;
}

void BorrarPendientes() {
   for(int i=OrdersTotal()-1; i>=0; i--) {
      ulong t = OrderGetTicket(i);
      if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC)==MagicNumber && OrderGetString(ORDER_SYMBOL)==_Symbol) trade.OrderDelete(t);
   }
}

void SerialCloseAll(string m) {
   for(int i=PositionsTotal()-1; i >= 0; i--) {
      ulong t = PositionGetTicket(i);
      if(PositionSelectByTicket(t) && PositionGetInteger(POSITION_MAGIC)==MagicNumber && PositionGetString(POSITION_SYMBOL)==_Symbol) trade.PositionClose(t);
   }
}

int ContarPosiciones() { int c=0; for(int i=0;i<PositionsTotal();i++) if(PositionSelectByTicket(PositionGetTicket(i))&&PositionGetInteger(POSITION_MAGIC)==MagicNumber && PositionGetString(POSITION_SYMBOL)==_Symbol) c++; return c; }
int ContarPendientes() { int c=0; for(int i=0;i<OrdersTotal();i++) if(OrderSelect(OrderGetTicket(i))&&OrderGetInteger(ORDER_MAGIC)==MagicNumber && OrderGetString(ORDER_SYMBOL)==_Symbol) c++; return c; }
bool EstaEnHorario() { MqlDateTime dt; TimeToStruct(TimeCurrent(), dt); return (dt.hour >= HoraInicio && dt.hour < HoraFin); }
//+------------------------------------------------------------------+

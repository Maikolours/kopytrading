//+------------------------------------------------------------------+
//|                  00_ELITE_GOLD_V2.20_SNIPER_HUD                  |
//|      ESTRATEGIA TENDENCIA V2.1 | MAGIC 1234567 | CON PANEL       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrade Corp."
#property version   "2.20"
#property strict

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/HistoryOrderInfo.mqh>

//--- INPUTS PROFESIONALES
input group "=== 🛡️ GESTIÓN DE RIESGO PRO ==="
input double   LoteInicial       = 0.01;
input double   ProfitObjetivo    = 5.0;    
input double   StopLossDiario    = 15.0;  // Máxima pérdida diaria permitida
input int      MaxOpsSimultaneas = 1;      

input group "=== 🎯 FILTROS SNIPER (ANTI-LATERAL) ==="
input int      InpConfirmacionVelas = 12;  
input int      PeriodoMedia        = 200;   
input int      HorasMaximasOrden   = 8;     
 
input group "=== 🛡️ PROTECCIÓN Y MAGIC ==="
input int      BreakEvenPips     = 10;     
input double   BE_Activacion     = 2.0;    
input long     MagicNumber       = 1234567; 
input int      Cooldown          = 900;    

#define HUD_PRE "G_"

//--- GLOBALES
CTrade         trade;
CPositionInfo  posInfo;
int            hEma;
string         botStatus = "BUSCANDO TENDENCIA";
string         narrative = "Analizando estructura...";
bool           bloqueoDiario = false;

int OnInit() {
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetTypeFillingBySymbol(_Symbol);
   hEma = iMA(_Symbol, _Period, PeriodoMedia, 0, MODE_EMA, PRICE_CLOSE);
   CrearPanel();
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int r) {
   ObjectsDeleteAll(0, HUD_PRE);
   if(hEma != INVALID_HANDLE) IndicatorRelease(hEma);
   EventKillTimer();
}

void OnTick() {
   double profitH = CalcularProfitHoy();
   double profitA = CalcularProfitAbierto();
   double totalHoy = profitH + profitA;

   if(totalHoy <= -StopLossDiario) {
      if(!bloqueoDiario) {
         CerrarTodo();
         bloqueoDiario = true;
      }
      botStatus = "STOP LOSS DIARIO!";
      narrative = "Límite alcanzado. Operativa cerrada.";
      UpdatePanel();
      return;
   } else {
      bloqueoDiario = false; // Reset si cambiamos de día o recuperamos
   }

   GestionarPosicionesYTiempo();
   
   if(ContarPosiciones() == 0 && !bloqueoDiario) {
      EvaluarEntradaSniper();
   }
   UpdatePanel();
}

void OnTimer() {
   if(ObjectFind(0, HUD_PRE+"bg") < 0) CrearPanel();
   UpdatePanel();
}

double CalcularProfitHoy() {
   double profit = 0;
   if(HistorySelect(iTime(_Symbol, PERIOD_D1, 0), TimeCurrent())) {
      int total = HistoryDealsTotal();
      for(int i=0; i<total; i++) {
         ulong ticket = HistoryDealGetTicket(i);
         if(HistoryDealGetInteger(ticket, DEAL_MAGIC) == MagicNumber) {
            profit += HistoryDealGetDouble(ticket, DEAL_PROFIT);
            profit += HistoryDealGetDouble(ticket, DEAL_COMMISSION);
            profit += HistoryDealGetDouble(ticket, DEAL_SWAP);
         }
      }
   }
   return profit;
}

double CalcularProfitAbierto() {
   double profit = 0;
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic()==MagicNumber) profit += posInfo.Profit();
   }
   return profit;
}

void CerrarTodo() {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic()==MagicNumber) trade.PositionClose(posInfo.Ticket());
   }
}

void EvaluarEntradaSniper() {
   double maArray[];
   ArraySetAsSeries(maArray, true);
   if(CopyBuffer(hEma, 0, 0, 1, maArray) <= 0) return;
   double ma = maArray[0];
   double precioActual = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   int hh = iHighest(_Symbol, _Period, MODE_HIGH, InpConfirmacionVelas, 2);
   int ll = iLowest(_Symbol, _Period, MODE_LOW, InpConfirmacionVelas, 2);
   double techo = iHigh(_Symbol, _Period, hh);
   double suelo = iLow(_Symbol, _Period, ll);
   double closePrev = iClose(_Symbol, _Period, 1);

   if(precioActual > ma) {
      if(closePrev > techo) {
         EjecutarOrden(ORDER_TYPE_BUY, LoteInicial, "V2.1_Compra_Tendencia");
      } else {
         botStatus = "ESPERANDO RUPTURA";
         narrative = "Techo en: " + DoubleToString(techo, _Digits);
      }
   } else if(precioActual < ma) {
      if(closePrev < suelo) {
         EjecutarOrden(ORDER_TYPE_SELL, LoteInicial, "V2.1_Venta_Tendencia");
      } else {
         botStatus = "ESPERANDO RUPTURA";
         narrative = "Suelo en: " + DoubleToString(suelo, _Digits);
      }
   }
}

void EjecutarOrden(int tipo, double lote, string comentario) {
   double precio = (tipo == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   trade.PositionOpen(_Symbol, (ENUM_POSITION_TYPE)tipo, lote, precio, 0, 0, comentario);
}

void GestionarPosicionesYTiempo() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Magic() == MagicNumber) {
         double profit = posInfo.Profit();

         if(profit >= BE_Activacion) {
            double op = posInfo.PriceOpen();
            double sl = posInfo.StopLoss();
            double ps = (_Digits<=2?1.0:(_Digits==3||_Digits==5?10.0*_Point:_Point));
            bool buy = (posInfo.PositionType() == POSITION_TYPE_BUY);
            double nsl = op + (buy ? BreakEvenPips : -BreakEvenPips) * ps;
            if((buy && sl < nsl) || (!buy && (sl > nsl || sl == 0))) trade.PositionModify(posInfo.Ticket(), nsl, posInfo.TakeProfit());
         }

         if(TimeCurrent() - (datetime)posInfo.Time() > HorasMaximasOrden * 3600) trade.PositionClose(posInfo.Ticket());
         if(profit >= ProfitObjetivo) trade.PositionClose(posInfo.Ticket());
      }
   }
}

int ContarPosiciones() {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) if(posInfo.SelectByIndex(i) && posInfo.Magic() == MagicNumber) count++;
   return count;
}

void CrearPanel() {
   int x=10, y=30, w=220, h=160;
   CrRect("bg", x, y, w, h, C'30,30,30', clrGold);
   CrRect("hdr", x, y, w, 25, clrGold, clrGold);
   CrLabel("ttl", x+10, y+5, "ELITE GOLD V2.20 SNIPER", clrBlack, 9);
   CrLabel("st_t", x+10, y+40, "ESTADO:", clrGray, 7);
   CrLabel("st_v", x+10, y+55, botStatus, clrWhite, 8);
   CrLabel("nr_t", x+10, y+80, "NARRATIVA:", clrGray, 7);
   CrLabel("nr_v", x+10, y+95, narrative, clrGold, 7);
   CrBtn("b_cl", x+10, y+120, w-20, 30, "CERRAR TODO (PANIC)", clrRed);
}

void UpdatePanel() {
   if(ObjectFind(0, HUD_PRE+"st_v")>=0) ObjectSetString(0, HUD_PRE+"st_v", OBJPROP_TEXT, botStatus);
   if(ObjectFind(0, HUD_PRE+"nr_v")>=0) ObjectSetString(0, HUD_PRE+"nr_v", OBJPROP_TEXT, narrative);
   color c = bloqueoDiario ? clrRed : ((ContarPosiciones()>0) ? clrCyan : clrWhite);
   ObjectSetInteger(0, HUD_PRE+"st_v", OBJPROP_COLOR, c);
}

void CrRect(string n, int x, int y, int w, int h, color bg, color bd) { ObjectCreate(0,HUD_PRE+n,OBJ_RECTANGLE_LABEL,0,0,0); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YSIZE,h); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_COLOR,bd); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_BORDER_TYPE,BORDER_FLAT); }
void CrLabel(string n, int x, int y, string t, color c, int s) { ObjectCreate(0,HUD_PRE+n,OBJ_LABEL,0,0,0); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YDISTANCE,y); ObjectSetString(0,HUD_PRE+n,OBJPROP_TEXT,t); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_COLOR,c); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_FONTSIZE,s); }
void CrBtn(string n, int x, int y, int w, int h, string t, color bg) { ObjectCreate(0,HUD_PRE+n,OBJ_BUTTON,0,0,0); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XDISTANCE,x); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YDISTANCE,y); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_XSIZE,w); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_YSIZE,h); ObjectSetString(0,HUD_PRE+n,OBJPROP_TEXT,t); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_BGCOLOR,bg); ObjectSetInteger(0,HUD_PRE+n,OBJPROP_COLOR,clrWhite); }

void OnChartEvent(const int id, const long &lp, const double &dp, const string &sp) {
   if(id == CHARTEVENT_OBJECT_CLICK && sp == HUD_PRE+"b_cl") {
      CerrarTodo();
      ObjectSetInteger(0, sp, OBJPROP_STATE, false);
   }
}

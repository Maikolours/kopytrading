//+------------------------------------------------------------------+
//| EA Scalping Inteligente v4.9 – MT5 (RESTAURADO AL ORIGINAL)      |
//| Con todos los parámetros expuestos y Cortafuegos en 6$           |
//+------------------------------------------------------------------+
#property strict
#property version "4.9"
#include <Trade/Trade.mqh>
CTrade trade;

// ================= GESTIÓN DE RIESGO =================
input double RiskPercent        = 0.5;       // % de Riesgo por operación (Calcula lote autom.)
input int    MagicNumber        = 202509;    // Magic Number del bot

// ================= STOP LOSS Y TAKE PROFIT (FÍSICOS POR ATR) =================
// ⚠️ El bot original calcula el SL/TP multiplicando la volatilidad (ATR)
input int    ATR_Period         = 14;        // Periodo del ATR
input double SL_Mult_Forex      = 1.0;       // Stop Loss Forex (Multiplicador ATR)
input double TP_Mult_Forex      = 1.2;       // Take Profit Forex (Multiplicador ATR)
input double SL_Mult_Gold       = 1.3;       // Stop Loss ORO (Multiplicador ATR)
input double TP_Mult_Gold       = 1.0;       // Take Profit ORO (Multiplicador ATR)

// ================= ESTRATEGIA (MOMENTUM PURO) =================
// ⚠️ Este bot NO usa Medias Móviles ni RSI. Solo impulso de velas.
input int    MomentumCandles     = 3;        // Nº Velas a mirar hacia atrás
input int    MomentumRequired    = 2;        // Nº Velas requeridas en la misma dirección
input int    MaxTradesPerSide    = 2;        // Máximo de operaciones a la vez por tipo
input int    CooldownSeconds     = 60;       // Segundos de espera entre operaciones

// ================= CORTAFUEGOS EN DÓLARES (CIERRES VIRTUALES) =================
input bool   ActivarCortafuegos  = true;     // 🛡️ Activar Cortafuegos en Dólares
input double MaxPerdida_USD      = 6.0;      // 🔴 Cerrar OP inmediatamente si pierde X dólares (Tú Stop Loss en $)
input double MaxGanancia_USD     = 6.0;      // 🟢 Cerrar OP inmediatamente si gana X dólares (Tu Take Profit en $)
input int    MaxVelasContra      = 2;        // ⏱️ Cerrar OP estancada si tras X velas sigue en rojo

// ================= CIERRE POR TIEMPO + BENEFICIO =================
input bool   EnableTimeExit      = true;     // Activar cierre rápido por "impaciencia"
input int    ExitBars_1          = 3;        // Velas espera 1º cierre
input double ExitProfit_1_EUR    = 1.0;      // Ganancia para 1º cierre ($)
input int    ExitBars_2          = 4;        // Velas espera 2º cierre
input double ExitProfit_2_EUR    = 2.0;      // Ganancia para 2º cierre ($)

// ================= BREAK EVEN =================
input bool   EnableBE            = true;     // Activar Break Even
input double BE_Trigger_USD      = 2.5;      // Ganancia en dólares para activar BE 
input double BE_Cushion_USD      = 0.5;      // Dólares asegurados en el BE

// ================= TRAILING STOP =================
input bool   EnableTrailing      = true;     // Activar Trailing Stop
input double Trail_Trigger_USD   = 2.5;      // Ganancia en dólares para arrancar Trailing
input double Trail_Distance_USD  = 2.0;      // Distancia de persecución ($)

// ================= PANEL VISUAL =================
input bool   ShowPanel           = true;     // Mostrar panel en el gráfico
input bool   EnableDebug         = false;    // Mostrar mensajes en registro Expertos

//---------------- GLOBALS ----------------
datetime lastTradeTime = 0;
datetime lastBarTime   = 0;
int atrHandle = INVALID_HANDLE;

//+------------------------------------------------------------------+
int OnInit()
{
   atrHandle = iATR(_Symbol,_Period,ATR_Period);
   if(atrHandle==INVALID_HANDLE) return(INIT_FAILED);
   trade.SetExpertMagicNumber(MagicNumber);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   if(atrHandle!=INVALID_HANDLE) IndicatorRelease(atrHandle);
   Comment(""); 
}

double GetATR()
{
   if(atrHandle==INVALID_HANDLE) {
      atrHandle = iATR(_Symbol,_Period,ATR_Period);
      if(atrHandle==INVALID_HANDLE) return 0.0;
   }
   double buf[];
   if(CopyBuffer(atrHandle,0,0,1,buf)<=0) return 0.0;
   return buf[0];
}

bool CheckMomentum(bool bullish)
{
   if(Bars(_Symbol,_Period) < MomentumCandles+1) return false;
   int count = 0;
   for(int i=1; i<=MomentumCandles; i++) {
      double o = iOpen(_Symbol,_Period,i);
      double c = iClose(_Symbol,_Period,i);
      if(bullish && c>o) count++;
      if(!bullish && c<o) count++;
   }
   return (count >= MomentumRequired);
}

int CountTrades(int type)
{
   int total=0;
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(PositionGetInteger(POSITION_MAGIC)==MagicNumber &&
            PositionGetString(POSITION_SYMBOL)==_Symbol &&
            PositionGetInteger(POSITION_TYPE)==type)
            total++;
      }
   }
   return total;
}

double USDtoPrice(double usd, double lot)
{
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickValue<=0 || lot<=0) return 0;
   return (usd * tickSize) / (tickValue * lot);
}

double CalculateLot(double slPrice)
{
   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double risk = accountBalance * RiskPercent / 100.0;
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double tickSize  = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double distPips = MathAbs(price - slPrice) / tickSize;
   if(distPips <= 0) distPips = 1;
   if(tickValue <= 0) tickValue = 1;
   double lot = risk / (distPips * tickValue);
   double volMin  = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double volMax  = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double volStep = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   int digits = (volStep>0) ? (int)MathLog10(1/volStep)+1 : 2;
   lot = NormalizeDouble(lot, digits);
   if(lot < volMin) lot = volMin;
   if(volMax>0 && lot > volMax) lot = volMax;
   return lot;
}

bool IsGoldSymbol(string symbol) { return (StringFind(symbol, "XAU")>=0); }

//+------------------------------------------------------------------+
void ManageCortafuegos()
{
   if(!ActivarCortafuegos) return;
   
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber) continue;

      double profit = PositionGetDouble(POSITION_PROFIT);
      
      // Stop Loss virtual definido por la usuaria en Dólares
      if(MaxPerdida_USD > 0 && profit <= -MaxPerdida_USD) 
      {
         trade.PositionClose(ticket);
         if(EnableDebug) Print("CORTAFUEGOS PÉRDIDA: Cierre a -$6.0");
         continue;
      }

      // Take Profit virtual definido por la usuaria en Dólares
      if(MaxGanancia_USD > 0 && profit >= MaxGanancia_USD) 
      {
         trade.PositionClose(ticket);
         if(EnableDebug) Print("CORTAFUEGOS GANANCIA: Cierre a +$6.0");
         continue;
      }
      
      // Cierre por estancamiento de velas
      datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
      int barsOpen = iBarShift(_Symbol,_Period,openTime,false);
      
      if(barsOpen >= MaxVelasContra && profit < 0)
      {
         trade.PositionClose(ticket);
         continue;
      }
   }
}

void ManageBETrailing()
{
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber) continue;

      double profit      = PositionGetDouble(POSITION_PROFIT);
      double openPrice   = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL   = PositionGetDouble(POSITION_SL);
      double currentTP   = PositionGetDouble(POSITION_TP);
      long   type        = PositionGetInteger(POSITION_TYPE);
      double lot         = PositionGetDouble(POSITION_VOLUME);
      double bid         = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask         = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double stopLevel   = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);

      double newSL = 0;

      if(EnableBE && profit >= BE_Trigger_USD)
      {
         bool modifyObj = false;
         if(type == POSITION_TYPE_BUY)
         {
            newSL = openPrice + USDtoPrice(BE_Cushion_USD, lot);
            newSL = NormalizeDouble(newSL, _Digits);
            if(newSL > currentSL && newSL <= (bid - stopLevel)) modifyObj = true;
         }
         else if(type == POSITION_TYPE_SELL)
         {
            newSL = openPrice - USDtoPrice(BE_Cushion_USD, lot);
            newSL = NormalizeDouble(newSL, _Digits);
            if((currentSL==0 || newSL < currentSL) && newSL >= (ask + stopLevel)) modifyObj = true;
         }
         if(modifyObj && trade.PositionModify(ticket, newSL, currentTP)) {
             if(EnableDebug) Print("=== BREAK EVEN APLICADO === -> ", newSL);
         }
      }

      if(EnableTrailing && profit >= Trail_Trigger_USD)
      {
         bool modifyObj = false;
         if(type == POSITION_TYPE_BUY)
         {
            newSL = bid - USDtoPrice(Trail_Distance_USD, lot);
            newSL = NormalizeDouble(newSL, _Digits);
            if(newSL > currentSL && newSL > openPrice && newSL <= (bid - stopLevel)) modifyObj = true;
         }
         else if(type == POSITION_TYPE_SELL)
         {
            newSL = ask + USDtoPrice(Trail_Distance_USD, lot);
            newSL = NormalizeDouble(newSL, _Digits);
            if((currentSL==0 || newSL < currentSL) && newSL < openPrice && newSL >= (ask + stopLevel)) modifyObj = true;
         }
         if(modifyObj && trade.PositionModify(ticket, newSL, currentTP)) {
             if(EnableDebug) Print("=== TRAILING MOVIDO === -> ", newSL);
         }
      }
   }
}

void ManageTimeExit()
{
   if(!EnableTimeExit) return;
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber) continue;

      datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
      int barsOpen = iBarShift(_Symbol,_Period,openTime,false); 
      double profit = PositionGetDouble(POSITION_PROFIT);

      if(profit <= 0) continue;
      if(barsOpen >= ExitBars_1 && profit >= ExitProfit_1_EUR) { trade.PositionClose(ticket); continue; }
      if(barsOpen >= ExitBars_2 && profit >= ExitProfit_2_EUR) { trade.PositionClose(ticket); continue; }
   }
}

void DrawPanel()
{
   if(!ShowPanel) {
      Comment("");
      return;
   }
   string text = "╔══════════════════════════════════════════════╗\n";
   text += "║  EA Scalping v4.9 [RESTAURADO + EXPLICADO] \n";
   text += "╠══════════════════════════════════════════════╣\n";
   text += "║ Balance: " + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + " USD\n";
   text += "║ Posiciones: " + IntegerToString(PositionsTotal()) + "\n";
   text += "║ Cortafuegos SL/TP en USD Activo \n";
   text += "╚══════════════════════════════════════════════╝\n";
   Comment(text);
}

void OnTick()
{
   ManageBETrailing();
   ManageTimeExit(); 
   ManageCortafuegos();
   
   DrawPanel();

   datetime currentBar = iTime(_Symbol,_Period,0);
   if(currentBar == lastBarTime) return;
   lastBarTime = currentBar;

   if(TimeCurrent() - lastTradeTime < CooldownSeconds) return;

   double atr = GetATR();
   if(atr <= 0.0) return;
   if(atr < SymbolInfoDouble(_Symbol, SYMBOL_POINT)*50.0) return;

   bool isGold = IsGoldSymbol(_Symbol);
   double slMult = isGold ? SL_Mult_Gold : SL_Mult_Forex;
   double tpMult = isGold ? TP_Mult_Gold : TP_Mult_Forex;
   double price, sl, tp, lot;

   if(CheckMomentum(true) && CountTrades(POSITION_TYPE_BUY) < MaxTradesPerSide)
   {
      price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      sl = price - atr * slMult;
      tp = price + atr * tpMult; 
      
      lot = CalculateLot(sl);
      if(lot>0 && trade.Buy(lot, _Symbol, price, sl, tp, "ENTRADA_NORMAL_BUY")) {
         lastTradeTime = TimeCurrent();
      }
   }

   if(CheckMomentum(false) && CountTrades(POSITION_TYPE_SELL) < MaxTradesPerSide)
   {
      price = SymbolInfoDouble(_Symbol,SYMBOL_BID);
      sl = price + atr * slMult;
      tp = price - atr * tpMult; 
      
      lot = CalculateLot(sl);
      if(lot>0 && trade.Sell(lot, _Symbol, price, sl, tp, "ENTRADA_NORMAL_SELL")) {
         lastTradeTime = TimeCurrent();
      }
   }
}

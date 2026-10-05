//+------------------------------------------------------------------+
//| EA Scalping Inteligente v4.6 – MT5 (AJUSTES DE LA JEFA)          |
//+------------------------------------------------------------------+
#property strict
#property version "4.6"
#include <Trade/Trade.mqh>
CTrade trade;

//---------------- INPUTS ----------------
input double RiskPercent        = 0.5;       // Riesgo por operación (% del balance)
input int    MagicNumber        = 202509;    // Magic para distinguir operaciones del EA

input int    ATR_Period         = 14;
input double SL_Mult_Forex      = 1.0;
input double TP_Mult_Forex      = 1.2;

input double SL_Mult_Gold       = 1.3;
input double TP_Mult_Gold       = 1.0;

input int    MomentumCandles     = 3;
input int    MomentumRequired    = 2;

input int    MaxTradesPerSide    = 2;        // Máximo por lado (compra/venta)
input int    CooldownSeconds     = 60;

input bool   EnableDebug         = false;    // Modo debug/log detallado

// ================= CORTAFUEGOS DE PÉRDIDA ========================
input bool   ActivarCortafuegos  = true;     // 🛡️ Activar Cortafuegos (Cierre rápido en negativo)
input double MaxPerdida_USD      = 10.0;     // 💸 Cortar operación inmediatamente si pierde X dólares
input int    MaxVelasContra      = 2;        // 🕯️ Cortar operación si han pasado X velas y sigue en rojo (AJUSTADO A 2)

// ================= CIERRE POR TIEMPO + BENEFICIO =================
input bool   EnableTimeExit      = true;     // Activar cierre por tiempo/beneficio
input int    ExitBars_1          = 3;        // número de velas para primer cierre
input double ExitProfit_1_EUR    = 1.0;      // beneficio mínimo primer cierre
input int    ExitBars_2          = 4;        // número de velas para segundo cierre
input double ExitProfit_2_EUR    = 2.0;      // beneficio mínimo segundo cierre

// ================= BREAK EVEN =================
input bool   EnableBE            = true;     // Activar Break Even
input double BE_Trigger_USD      = 2.5;      // Ganancia en USD para activar BE (AJUSTADO A 2.5)
input double BE_Cushion_USD      = 0.5;      // Ganancia asegurada en USD después de BE

// ================= TRAILING STOP =================
input bool   EnableTrailing      = true;     // Activar Trailing Stop
input double Trail_Trigger_USD   = 2.5;      // Ganancia en USD para activar trailing
input double Trail_Distance_USD  = 2.0;      // Distancia del trailing en USD

// ================= PANEL VISUAL =================
input bool   ShowPanel           = true;     // Mostrar panel en el gráfico

//---------------- GLOBALS ----------------
datetime lastTradeTime = 0;
datetime lastBarTime   = 0;
int atrHandle = INVALID_HANDLE;
string panelName = "EA_Panel_";

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
//| CORTAFUEGOS: Cierre rápido si la cosa se pone fea                |
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
      
      if(profit <= -MaxPerdida_USD) 
      {
         trade.PositionClose(ticket);
         continue;
      }
      
      datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
      int barsOpen = iBarShift(_Symbol,_Period,openTime,false);
      
      // REGla ajustada a lo que pediste: si han pasado 2 velas y está en rojo, fuera.
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
   text += "║  EA Scalping v4.6 [Cortafuegos Agresivo] \n";
   text += "╠══════════════════════════════════════════════╣\n";
   text += "║ Balance: " + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + " USD\n";
   text += "║ Posiciones: " + IntegerToString(PositionsTotal()) + "\n";
   text += "║ Compras: " + IntegerToString(CountTrades(POSITION_TYPE_BUY)) + " / " + IntegerToString(MaxTradesPerSide) + "\n";
   text += "║ Ventas:  " + IntegerToString(CountTrades(POSITION_TYPE_SELL)) + " / " + IntegerToString(MaxTradesPerSide) + "\n";
   text += "║\n";
   text += "║ Cortafuegos de tiempo: " + IntegerToString(MaxVelasContra) + " velas\n";
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

//+------------------------------------------------------------------+
//| EA_XAUUSD_M5_BUY_SAFE_v1                                          |
//| Scalping BUY-only seguro para Oro                                |
//+------------------------------------------------------------------+
#property strict
#property version "1.0"

#include <Trade/Trade.mqh>
CTrade trade;

//================ INPUTS =================
input double RiskPercent        = 0.5;
input int    MagicNumber        = 770501;

input int    ATR_Period         = 14;
input double SL_ATR_Mult        = 1.5;
input double TP_ATR_Mult        = 1.2;

input int    MA_Fast            = 50;
input int    MA_Slow            = 200;

input int    MomentumCandles    = 4;
input int    MomentumRequired   = 3;

input int    CooldownSeconds    = 90;

//--- Spread filter (XAUUSD)
input double MaxSpreadPoints    = 35;

//--- Break Even & Trailing
input double BE_Percent_TP      = 50.0;
input double Trailing_ATR_Mult  = 0.8;

//================ VARIABLES =================
datetime lastTradeTime = 0;
int atrHandle = INVALID_HANDLE;

//+------------------------------------------------------------------+
int OnInit()
{
   atrHandle = iATR(_Symbol,_Period,ATR_Period);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(atrHandle!=INVALID_HANDLE)
      IndicatorRelease(atrHandle);
}

//+------------------------------------------------------------------+
double GetATR()
{
   double buf[];
   if(CopyBuffer(atrHandle,0,0,1,buf)<=0) return 0;
   return buf[0];
}

//+------------------------------------------------------------------+
double GetMA(int period)
{
   double ma[];
   int h=iMA(_Symbol,_Period,period,0,MODE_EMA,PRICE_CLOSE);
   if(h==INVALID_HANDLE) return 0;
   CopyBuffer(h,0,0,1,ma);
   IndicatorRelease(h);
   return ma[0];
}

//+------------------------------------------------------------------+
bool SpreadOK()
{
   double spread=(SymbolInfoDouble(_Symbol,SYMBOL_ASK)-
                  SymbolInfoDouble(_Symbol,SYMBOL_BID))/_Point;
   return spread<=MaxSpreadPoints;
}

//+------------------------------------------------------------------+
bool BullishTrend()
{
   double maFast=GetMA(MA_Fast);
   double maSlow=GetMA(MA_Slow);
   double price=iClose(_Symbol,_Period,0);
   return price>maFast && maFast>maSlow;
}

//+------------------------------------------------------------------+
bool MomentumOK()
{
   int count=0;
   for(int i=1;i<=MomentumCandles;i++)
   {
      if(iClose(_Symbol,_Period,i)>iOpen(_Symbol,_Period,i))
         count++;
   }
   return count>=MomentumRequired;
}

//+------------------------------------------------------------------+
double CalculateLot(double slPrice)
{
   double balance=AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney=balance*RiskPercent/100.0;

   double tickSize=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double tickValue=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);

   double price=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double ticks=MathAbs(price-slPrice)/tickSize;
   if(ticks<=0) ticks=1;

   double lot=riskMoney/(ticks*tickValue);

   double minLot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double maxLot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);

   lot=MathMax(minLot,MathMin(lot,maxLot));
   lot=NormalizeDouble(lot,(int)MathLog10(1.0/step));
   return lot;
}

//+------------------------------------------------------------------+
void ManageBEandTrailing()
{
   double atr=GetATR();
   if(atr<=0) return;

   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      if(!PositionSelectByTicket(PositionGetTicket(i))) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber) continue;

      double entry=PositionGetDouble(POSITION_PRICE_OPEN);
      double sl=PositionGetDouble(POSITION_SL);
      double tp=PositionGetDouble(POSITION_TP);
      double price=SymbolInfoDouble(_Symbol,SYMBOL_BID);

      double beLevel=entry+(tp-entry)*(BE_Percent_TP/100.0);

      // BREAK EVEN
      if(price>=beLevel && sl<entry)
      {
         trade.PositionModify(PositionGetTicket(i),entry,tp);
         continue;
      }

      // TRAILING DESPUÉS DEL BE
      if(sl>=entry)
      {
         double newSL=price-atr*Trailing_ATR_Mult;
         if(newSL>sl)
            trade.PositionModify(PositionGetTicket(i),newSL,tp);
      }
   }
}

//+------------------------------------------------------------------+
void OnTick()
{
   ManageBEandTrailing();

   if(TimeCurrent()-lastTradeTime<CooldownSeconds) return;
   if(!SpreadOK()) return;
   if(!BullishTrend()) return;
   if(!MomentumOK()) return;

   double atr=GetATR();
   if(atr<=0) return;

   double price=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double sl=price-atr*SL_ATR_Mult;
   double tp=price+atr*TP_ATR_Mult;

   double lot=CalculateLot(sl);
   if(lot<=0) return;

   if(trade.Buy(lot,_Symbol,price,sl,tp))
      lastTradeTime=TimeCurrent();
}
//+------------------------------------------------------------------+
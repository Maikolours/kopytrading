//+------------------------------------------------------------------+
//|                          00_MAIKO_SMC_LIQUIDITY_SCALPER_v1.0.mq5 |
//|                                  Copyright 2026, MAIKO KOPYTRADING |
//|                                              https://kopytrading.es|
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, MAIKO KOPYTRADING"
#property link      "https://kopytrading.es"
#property version   "1.00"
#property description "MAIKO SMC Liquidity Scalper PRO - Automated Smart Money Concepts & VWAP Scalper"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//--- Enums
enum ENUM_LOT_MODE
  {
   LOT_CONSERVATIVE = 0, // Conservative (0.2% Risk)
   LOT_MODERATE     = 1, // Moderate (0.5% Risk)
   LOT_AGGRESSIVE   = 2, // Aggressive (1.0% Risk)
   LOT_FIXED        = 3  // Fixed Lot Size
  };

enum ENUM_ACCOUNT_UNIT_MODE
  {
   ACCOUNT_UNIT_AUTO = 0, // Auto Detect (USD vs USC Cent)
   ACCOUNT_UNIT_USD  = 1, // Standard USD / EUR
   ACCOUNT_UNIT_CENT = 2  // Cent Account (USC)
  };

enum ENUM_ENTRY_MODE
  {
   ENTRY_MARKET_FAST = 0, // Fast Market Entry on SMC Signal
   ENTRY_RETEST_LIMIT= 1  // Retest Limit Entry at Order Block
  };

//--- Inputs
input string               InpTradeComment        = "MAIKO_SMC";       // Trade Comment
input ulong                InpMagicNumber          = 20260924;         // Magic Number
input string               InpIndicatorName        = "Market\\SMC Liquidity"; // Indicator Name / Path

input group "=== STRATEGY & ENTRY MODE ==="
input ENUM_ENTRY_MODE      InpEntryMode            = ENTRY_MARKET_FAST;// Execution Mode
input bool                 InpUseVWAPFilter        = true;             // Enable VWAP / Trend Filter
input bool                 InpRequireFVGRetest     = false;            // Require FVG Retest

input group "=== LOT SIZE & RISK MANAGEMENT ==="
input ENUM_LOT_MODE        InpLotMode              = LOT_CONSERVATIVE; // Lot Sizing Mode
input double               InpFixedLot             = 0.01;             // Fixed Lot Size
input double               InpRiskPercent          = 0.2;              // Risk % per trade (Equity)
input double               InpMinLot               = 0.01;             // Minimum Lot
input double               InpMaxLot               = 10.0;             // Maximum Lot
input ENUM_ACCOUNT_UNIT_MODE InpAccountUnitMode    = ACCOUNT_UNIT_AUTO; // Account Unit Mode

input group "=== STOP LOSS & TAKE PROFIT ==="
input bool                 InpUseFixedSL           = true;             // Use Fixed Emergency SL
input double               InpFixedSL_Pips         = 1500.0;           // Hard Emergency SL (Points = 150 pips)
input bool                 InpUseFixedTP           = true;             // Use Fixed TP Target
input double               InpFixedTP_Pips         = 3000.0;           // Hard TP Target (Points = 300 pips)

input group "=== DYNAMIC EXIT MANAGEMENT ==="
input bool                 InpUseBreakEven         = true;             // Enable BreakEven Shield
input double               InpBreakEvenTrigger     = 100.0;            // BreakEven Trigger (100 Points = $1.00 Gold)
input double               InpBreakEvenLock        = 20.0;             // BreakEven Lock Profit (20 Points = $0.20 Gold)
input bool                 InpUseTrailingStop      = true;             // Enable Trailing Stop
input double               InpTrailingStart        = 120.0;            // Trailing Start (120 Points = $1.20 Gold)
input double               InpTrailingStep         = 30.0;             // Trailing Step (30 Points = $0.30 Gold)
input bool                 InpUseTimeStop          = true;             // Enable Time Stop
input int                  InpMaxTradeDurationHours= 22;               // Max Holding Time (Hours)

input group "=== SPREAD & SLIPPAGE FILTER ==="
input bool                 InpEnableSpreadFilter   = true;             // Enable Spread Filter
input double               InpMaxSpreadPoints      = 150.0;            // Max Allowed Spread (Points)
input ulong                InpMaxSlippage          = 30;               // Maximum Slippage (Points / 3 Pips)

//--- Global Variables
CTrade         m_trade;
CPositionInfo  m_position;
int            m_handle_smc        = INVALID_HANDLE;
int            m_handle_vwap_ema   = INVALID_HANDLE;
int            m_handle_atr        = INVALID_HANDLE;
datetime       m_last_bar_time     = 0;
bool           m_is_cent_account   = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   m_trade.SetExpertMagicNumber(InpMagicNumber);
   m_trade.SetDeviationInPoints(InpMaxSlippage); // Set Maximum Slippage Guard
   
   // Autodetect Cent Account
   DetectAccountType();

   // Attempt to load custom SMC Liquidity indicator handle
   ResetLastError();
   m_handle_smc = iCustom(_Symbol, _Period, InpIndicatorName);
   if(m_handle_smc == INVALID_HANDLE)
     {
      Print("[WARNING] Custom SMC Liquidity indicator not found at '", InpIndicatorName, "'. Using Standalone Native SMC Engine.");
     }

   // Initialize Trend/VWAP EMA Filter Handle
   m_handle_vwap_ema = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
   m_handle_atr      = iATR(_Symbol, _Period, 14);

   if(m_handle_vwap_ema == INVALID_HANDLE || m_handle_atr == INVALID_HANDLE)
     {
      Print("[ERROR] Failed to create trend indicator handles.");
      return(INIT_FAILED);
     }

   CreateDashboard();
   Print("[INIT SUCCESS] 00_MAIKO_SMC_LIQUIDITY_SCALPER_v1.0 initialized successfully.");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(m_handle_smc != INVALID_HANDLE) IndicatorRelease(m_handle_smc);
   if(m_handle_vwap_ema != INVALID_HANDLE) IndicatorRelease(m_handle_vwap_ema);
   if(m_handle_atr != INVALID_HANDLE) IndicatorRelease(m_handle_atr);
   ObjectsDeleteAll(0, "SMC_SCALPER_");
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   UpdateDashboard();

   // Manage Active Open Positions
   ManageActivePositions();

   // New Bar Filter for Opening New Entries
   datetime current_bar_time = iTime(_Symbol, _Period, 0);
   if(current_bar_time == m_last_bar_time) return;

   // Check Max Open Positions (Max 1 active trade)
   if(GetOpenPositionsCount() > 0) return;

   // Check Spread Filter
   double current_spread = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(InpEnableSpreadFilter && current_spread > InpMaxSpreadPoints)
     {
      return;
     }

   // Check Signal Conditions
   bool buy_signal = false;
   bool sell_signal = false;

   // 1. Try reading Custom Indicator Buffers if available
   if(m_handle_smc != INVALID_HANDLE)
     {
      double buy_buffer[2], sell_buffer[2];
      if(CopyBuffer(m_handle_smc, 0, 1, 2, buy_buffer) >= 2 && CopyBuffer(m_handle_smc, 1, 1, 2, sell_buffer) >= 2)
        {
         if(buy_buffer[1] != 0 && buy_buffer[1] != EMPTY_VALUE) buy_signal = true;
         if(sell_buffer[1] != 0 && sell_buffer[1] != EMPTY_VALUE) sell_signal = true;
        }
     }

   // 2. Fallback to Native SMC Liquidity & Structure Engine if custom indicator buffer is empty
   if(!buy_signal && !sell_signal)
     {
      double ema[2], atr[2];
      if(CopyBuffer(m_handle_vwap_ema, 0, 1, 2, ema) >= 2 && CopyBuffer(m_handle_atr, 0, 1, 2, atr) >= 2)
        {
         double close_price = iClose(_Symbol, _Period, 1);
         double open_price  = iOpen(_Symbol, _Period, 1);
         double high_price  = iHigh(_Symbol, _Period, 1);
         double low_price   = iLow(_Symbol, _Period, 1);

         // Native SMC Dip Retest Signal: Price dips near EMA/VWAP in structure direction
         bool is_bullish_engulfing = (close_price > open_price) && (close_price > iHigh(_Symbol, _Period, 2));
         bool is_bearish_engulfing = (close_price < open_price) && (close_price < iLow(_Symbol, _Period, 2));

         if(InpUseVWAPFilter)
           {
            if(low_price <= ema[1] && close_price > ema[1] && is_bullish_engulfing) buy_signal = true;
            if(high_price >= ema[1] && close_price < ema[1] && is_bearish_engulfing) sell_signal = true;
           }
         else
           {
            if(is_bullish_engulfing) buy_signal = true;
            if(is_bearish_engulfing) sell_signal = true;
           }
        }
     }

   // Execute Trade Signals
   if(buy_signal)
     {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double sl = InpUseFixedSL ? (ask - InpFixedSL_Pips * _Point) : 0;
      double tp = InpUseFixedTP ? (ask + InpFixedTP_Pips * _Point) : 0;
      double lot = CalculateLotSize(MathAbs(ask - sl));

      if(m_trade.Buy(lot, _Symbol, ask, sl, tp, InpTradeComment))
        {
         m_last_bar_time = current_bar_time;
         Print("[SMC BUY] Opened Fast BUY at ", ask, " Lot: ", lot);
        }
     }
   else if(sell_signal)
     {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double sl = InpUseFixedSL ? (bid + InpFixedSL_Pips * _Point) : 0;
      double tp = InpUseFixedTP ? (bid - InpFixedTP_Pips * _Point) : 0;
      double lot = CalculateLotSize(MathAbs(sl - bid));

      if(m_trade.Sell(lot, _Symbol, bid, sl, tp, InpTradeComment))
        {
         m_last_bar_time = current_bar_time;
         Print("[SMC SELL] Opened Fast SELL at ", bid, " Lot: ", lot);
        }
     }
  }

//+------------------------------------------------------------------+
//| Manage Active Positions (Trailing, BreakEven, TimeStop)          |
//+------------------------------------------------------------------+
void ManageActivePositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i))
        {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == InpMagicNumber)
           {
            ulong ticket = m_position.Ticket();
            double open_price = m_position.PriceOpen();
            double current_sl = m_position.StopLoss();
            double current_tp = m_position.TakeProfit();
            datetime open_time = (datetime)m_position.Time();
            ENUM_POSITION_TYPE type = m_position.PositionType();

            // 1. Time Stop Guard
            if(InpUseTimeStop)
              {
               int elapsed_hours = (int)((TimeCurrent() - open_time) / 3600);
               if(elapsed_hours >= InpMaxTradeDurationHours)
                 {
                  Print("[TIME STOP] Closing position #", ticket, " after ", elapsed_hours, " hours.");
                  m_trade.PositionClose(ticket);
                  continue;
                 }
              }

            // 2. BUY Position Management
            if(type == POSITION_TYPE_BUY)
              {
               double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

               // BreakEven Shield
               if(InpUseBreakEven)
                 {
                  double trigger_price = open_price + (InpBreakEvenTrigger * _Point);
                  double lock_sl = open_price + (InpBreakEvenLock * _Point);
                  if(bid >= trigger_price && (current_sl < lock_sl || current_sl == 0))
                    {
                     m_trade.PositionModify(ticket, lock_sl, current_tp);
                     Print("[BREAKEVEN SHIELD] Locked profit on BUY #", ticket, " SL set to ", lock_sl);
                    }
                 }

               // Trailing Stop
               if(InpUseTrailingStop)
                 {
                  double trail_trigger = open_price + (InpTrailingStart * _Point);
                  if(bid >= trail_trigger)
                    {
                     double new_sl = bid - (InpTrailingStart * _Point);
                     if(new_sl > current_sl + (InpTrailingStep * _Point))
                       {
                        m_trade.PositionModify(ticket, new_sl, current_tp);
                        Print("[TRAILING STOP] Moved BUY #", ticket, " SL to ", new_sl);
                       }
                    }
                 }
              }
            // 3. SELL Position Management
            else if(type == POSITION_TYPE_SELL)
              {
               double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

               // BreakEven Shield
               if(InpUseBreakEven)
                 {
                  double trigger_price = open_price - (InpBreakEvenTrigger * _Point);
                  double lock_sl = open_price - (InpBreakEvenLock * _Point);
                  if(ask <= trigger_price && (current_sl > lock_sl || current_sl == 0))
                    {
                     m_trade.PositionModify(ticket, lock_sl, current_tp);
                     Print("[BREAKEVEN SHIELD] Locked profit on SELL #", ticket, " SL set to ", lock_sl);
                    }
                 }

               // Trailing Stop
               if(InpUseTrailingStop)
                 {
                  double trail_trigger = open_price - (InpTrailingStart * _Point);
                  if(ask <= trail_trigger)
                    {
                     double new_sl = ask + (InpTrailingStart * _Point);
                     if(current_sl == 0 || new_sl < current_sl - (InpTrailingStep * _Point))
                       {
                        m_trade.PositionModify(ticket, new_sl, current_tp);
                        Print("[TRAILING STOP] Moved SELL #", ticket, " SL to ", new_sl);
                       }
                    }
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Detect Account Type (Standard vs Cent)                           |
//+------------------------------------------------------------------+
void DetectAccountType()
  {
   if(InpAccountUnitMode == ACCOUNT_UNIT_CENT)
     {
      m_is_cent_account = true;
     }
   else if(InpAccountUnitMode == ACCOUNT_UNIT_USD)
     {
      m_is_cent_account = false;
     }
   else // AUTO
     {
      string currency = AccountInfoString(ACCOUNT_CURRENCY);
      StringToUpper(currency);
      if(StringFind(currency, "USC") >= 0 || StringFind(currency, "CENT") >= 0 || StringFind(currency, "EUCC") >= 0)
        {
         m_is_cent_account = true;
        }
      else
        {
         m_is_cent_account = false;
        }
     }
  }

//+------------------------------------------------------------------+
//| Calculate Lot Size                                               |
//+------------------------------------------------------------------+
double CalculateLotSize(double sl_distance_price)
  {
   if(InpLotMode == LOT_FIXED)
     {
      return NormalizeLot(InpFixedLot);
     }

   double risk_percent = InpRiskPercent;
   if(InpLotMode == LOT_CONSERVATIVE) risk_percent = 0.2;
   else if(InpLotMode == LOT_MODERATE) risk_percent = 0.5;
   else if(InpLotMode == LOT_AGGRESSIVE) risk_percent = 1.0;

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double risk_amount = equity * (risk_percent / 100.0);

   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   if(tick_value <= 0 || tick_size <= 0 || sl_distance_price <= 0)
     {
      return NormalizeLot(InpFixedLot);
     }

   double sl_points = sl_distance_price / tick_size;
   double lot = risk_amount / (sl_points * tick_value);

   if(m_is_cent_account)
     {
      lot = lot / 100.0;
     }

   return NormalizeLot(lot);
  }

//+------------------------------------------------------------------+
//| Normalize Lot Size                                               |
//+------------------------------------------------------------------+
double NormalizeLot(double lot)
  {
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double min_lot = MathMax(InpMinLot, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN));
   double max_lot = MathMin(InpMaxLot, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX));

   lot = MathFloor(lot / step) * step;
   return MathMin(MathMax(lot, min_lot), max_lot);
  }

//+------------------------------------------------------------------+
//| Get Count of Open Positions for Magic Number                     |
//+------------------------------------------------------------------+
int GetOpenPositionsCount()
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i))
        {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == InpMagicNumber)
           {
            count++;
           }
        }
     }
   return count;
  }

//+------------------------------------------------------------------+
//| Dashboard Display                                                |
//+------------------------------------------------------------------+
void CreateDashboard()
  {
   int x = 20, y = 30;
   CreateLabel("SMC_SCALPER_Title", "MAIKO SMC LIQUIDITY SCALPER v1.0", x, y, clrGold, 12, true);
   CreateLabel("SMC_SCALPER_Acc", "Account Mode: " + (m_is_cent_account ? "CENT (USC)" : "STANDARD (USD)"), x, y + 25, clrWhite, 9, false);
   CreateLabel("SMC_SCALPER_Spread", "Spread: 0 pts | Slippage Guard: " + IntegerToString(InpMaxSlippage) + " pts", x, y + 45, clrCyan, 9, false);
   CreateLabel("SMC_SCALPER_Status", "Status: Active & Monitoring SMC Signals", x, y + 65, clrSpringGreen, 9, false);
  }

void UpdateDashboard()
  {
   double spread = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   ObjectSetString(0, "SMC_SCALPER_Spread", OBJPROP_TEXT, "Spread: " + DoubleToString(spread, 0) + " pts | Slip Guard: " + IntegerToString(InpMaxSlippage) + " pts");
  }

void CreateLabel(string name, string text, int x, int y, color col, int font_size, bool is_bold)
  {
   ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, col);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size);
   ObjectSetString(0, name, OBJPROP_FONT, is_bold ? "Arial Bold" : "Arial");
  }
//+------------------------------------------------------------------+

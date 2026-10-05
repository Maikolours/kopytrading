//+------------------------------------------------------------------+
//|                          00_MAIKO_SMC_LIQUIDITY_SCALPER_v1.0.mq5 |
//|                                  Copyright 2026, MAIKO KOPYTRADING |
//|                                              https://kopytrading.es|
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, MAIKO KOPYTRADING"
#property link      "https://kopytrading.es"
#property version   "1.00"
#property description "SMC Liquidity Scalper PRO - Automated Smart Money Concepts Scalper"

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
input string               InpTradeComment        = "SMC_Scalper";    // Trade Comment
input ulong                InpMagicNumber          = 20260924;         // Magic Number
input string               InpIndicatorName        = "Market\\SMC Liquidity"; // Indicator Name / Path

input group "=== STRATEGY & ENTRY MODE ==="
input ENUM_ENTRY_MODE      InpEntryMode            = ENTRY_MARKET_FAST;// Execution Mode (Fast Market Entry on Signal)
input bool                 InpUseH1TrendFilter     = true;             // Enable H1 Higher Timeframe Trend Filter (Recommended)
input bool                 InpUseVWAPFilter        = true;             // Enable VWAP / EMA 50 Trend Filter
input bool                 InpRequireFVGRetest     = true;             // Require FVG / Pullback Retest
input bool                 InpCloseOnOppositeSignal= true;             // Close Active Position on Opposite Signal
input double               InpMaxOverextensionPoints= 120.0;           // Max Overextension Points ($1.20 Gold)

input group "=== LOT SIZE & RISK MANAGEMENT ==="
input ENUM_LOT_MODE        InpLotMode              = LOT_CONSERVATIVE; // Lot Sizing Mode
input double               InpFixedLot             = 0.01;             // Fixed Lot Size
input double               InpRiskPercent          = 0.2;              // Risk % per trade (Equity)
input double               InpMinLot               = 0.01;             // Minimum Lot
input double               InpMaxLot               = 10.0;             // Maximum Lot
input ENUM_ACCOUNT_UNIT_MODE InpAccountUnitMode    = ACCOUNT_UNIT_AUTO; // Account Unit Mode

input group "=== STOP LOSS & TAKE PROFIT ==="
input bool                 InpUseDynamicATR_SLTP   = true;             // Use Dynamic ATR SL & TP (Adapts to Volatility)
input double               InpATR_SL_Multiplier    = 1.0;              // Scalper ATR SL Multiplier (1.0x ATR)
input double               InpATR_TP_Multiplier    = 1.5;              // Scalper ATR TP Multiplier (1.5x ATR = Quick TP Target)
input bool                 InpUseFixedSL           = true;             // Use Fixed Emergency SL (Fallback)
input double               InpFixedSL_Pips         = 300.0;            // Scalper SL (300 Points = $3.00 Gold)
input bool                 InpUseFixedTP           = true;             // Use Fixed TP Target (Fallback)
input double               InpFixedTP_Pips         = 450.0;            // Scalper TP Target (450 Points = $4.50 Gold)

input group "=== DYNAMIC EXIT MANAGEMENT ==="
input bool                 InpUseBreakEven         = true;             // Enable BreakEven Shield
input double               InpBreakEvenTrigger     = 450.0;            // BreakEven Trigger (450 Points = $4.50 Gold)
input double               InpBreakEvenLock        = 350.0;            // BreakEven Lock Profit (350 Points = $3.50 Gold)
input bool                 InpUseTrailingStop      = true;             // Enable Trailing Stop
input double               InpTrailingStart        = 400.0;            // Trailing Start (400 Points = $4.00 Gold)
input double               InpTrailingStep         = 50.0;             // Trailing Step (50 Points = $0.50 Gold)
input bool                 InpUseTimeStop          = true;             // Enable Time Stop
input int                  InpMaxTradeDurationHours= 22;               // Max Holding Time (Hours)

input group "=== PENDING ORDER CLEANUP ==="
input bool                 InpUsePendingExpiry     = true;             // Enable Pending Order Expiration
input int                  InpPendingOrderExpiryBars = 5;              // Expiration Limit (Bars, default 5)
input bool                 InpUseATRDistanceCancel = true;             // Cancel if Distance > 1.5x ATR

input group "=== SPREAD & SLIPPAGE FILTER ==="
input bool                 InpEnableSpreadFilter   = true;             // Enable Spread Filter
input double               InpMaxSpreadPoints      = 300.0;            // Max Allowed Spread (300 Points = 30 Pips / $3.00 Gold)
input ulong                InpMaxSlippage          = 30;               // Maximum Slippage (Points / 3 Pips)

input group "=== SESSION TIME FILTER ==="
input bool                 InpUseTimeFilter        = true;             // Enable Session Time Filter (Filter Asian Dead Hours)
input int                  InpStartHour            = 8;                // Session Start Hour (Server Time, default 08:00)
input int                  InpEndHour              = 20;               // Session End Hour (Server Time, default 20:00)

input group "=== TREND STRENGTH & MOMENTUM FILTERS ==="
input bool                 InpUseADXFilter         = true;             // Enable ADX Trend Strength Guard (Filter Ranging LV)
input double               InpMinADX               = 20.0;             // Minimum ADX Threshold (Default 20.0)
input bool                 InpUseRSIFilter         = true;             // Enable RSI Momentum Filter
input double               InpRSI_BuyMin           = 48.0;             // RSI Buy Minimum (Default 48.0)
input double               InpRSI_BuyMax           = 70.0;             // RSI Buy Maximum (Default 70.0)
input double               InpRSI_SellMin          = 30.0;             // RSI Sell Minimum (Default 30.0)
input double               InpRSI_SellMax          = 52.0;             // RSI Sell Maximum (Default 52.0)

input group "=== DASHBOARD & HUD DISPLAY ==="
input bool                 InpEnableInfoPanel      = true;             // Enable HUD Panel
input ENUM_BASE_CORNER     InpCornerPosition       = CORNER_LEFT_UPPER;// Panel Corner Position
input int                  InpXPosition            = 15;               // Panel X Offset
input int                  InpYPosition            = 30;               // Panel Y Offset

//--- Global Variables
CTrade         m_trade;
CPositionInfo  m_position;
int            m_handle_smc        = INVALID_HANDLE;
int            m_handle_ema_5      = INVALID_HANDLE;
int            m_handle_ema_20     = INVALID_HANDLE;
int            m_handle_ema_50     = INVALID_HANDLE;
int            m_handle_h1_ema_50  = INVALID_HANDLE;
int            m_handle_vwap_ema   = INVALID_HANDLE;
int            m_handle_atr        = INVALID_HANDLE;
int            m_handle_adx        = INVALID_HANDLE;
int            m_handle_rsi        = INVALID_HANDLE;
datetime       m_last_bar_time     = 0;
bool           m_is_cent_account   = false;
bool           m_hud_minimized     = false;

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
   else
     {
      ChartIndicatorAdd(0, 0, m_handle_smc);
     }

   // Initialize Trend EMAs (5, 20, 50), H1 Trend EMA (50), ATR, ADX and RSI Handles
   m_handle_ema_5    = iMA(_Symbol, _Period, 5, 0, MODE_EMA, PRICE_CLOSE);
   m_handle_ema_20   = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   m_handle_ema_50   = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
   m_handle_h1_ema_50= iMA(_Symbol, PERIOD_H1, 50, 0, MODE_EMA, PRICE_CLOSE);
   m_handle_vwap_ema = m_handle_ema_50;
   m_handle_atr      = iATR(_Symbol, _Period, 14);
   m_handle_adx      = iADX(_Symbol, _Period, 14);
   m_handle_rsi      = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);

   if(m_handle_ema_5 == INVALID_HANDLE || m_handle_ema_20 == INVALID_HANDLE || 
      m_handle_ema_50 == INVALID_HANDLE || m_handle_atr == INVALID_HANDLE)
     {
      Print("[ERROR] Failed to create trend indicator handles.");
      return(INIT_FAILED);
     }

   // Automatically draw EMAs (5, 20, 50) onto the chart window
   ChartIndicatorAdd(0, 0, m_handle_ema_5);
   ChartIndicatorAdd(0, 0, m_handle_ema_20);
   ChartIndicatorAdd(0, 0, m_handle_ema_50);

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
   if(m_handle_h1_ema_50 != INVALID_HANDLE) IndicatorRelease(m_handle_h1_ema_50);
   if(m_handle_atr != INVALID_HANDLE) IndicatorRelease(m_handle_atr);
   if(m_handle_adx != INVALID_HANDLE) IndicatorRelease(m_handle_adx);
   if(m_handle_rsi != INVALID_HANDLE) IndicatorRelease(m_handle_rsi);
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

   // Manage Pending Limit Orders Cleanup (Expiry by Bars or ATR Distance)
   ManagePendingOrders();

   // New Bar Filter for Opening New Entries
   datetime current_bar_time = iTime(_Symbol, _Period, 0);
   if(current_bar_time == m_last_bar_time) return;
   m_last_bar_time = current_bar_time; // Mark bar processed immediately to avoid tick spam

   // Session Time Filter Guard (Filters Asian Dead Hours)
   if(InpUseTimeFilter)
     {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      if(dt.hour < InpStartHour || dt.hour >= InpEndHour)
        {
         Print("[TIME FILTER] Outside session hours (", dt.hour, ":00 vs Allowed ", InpStartHour, ":00-", InpEndHour, ":00). Skipping new entries.");
         return;
        }
     }

   // Check Max Open Positions (Max 1 active trade)
   if(GetOpenPositionsCount() > 0) return;

   // Check Spread Filter
   double current_spread = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(InpEnableSpreadFilter && current_spread > InpMaxSpreadPoints)
     {
      Print("[SMC SCALPER] Spread too high: ", current_spread, " > Max: ", InpMaxSpreadPoints);
      return;
     }

   // Check Signal Conditions
   bool raw_buy_signal  = false;
   bool raw_sell_signal = false;

   // 1. Scan Custom SMC Liquidity Indicator Buffers (buffers 0 to 15)
   if(m_handle_smc != INVALID_HANDLE)
     {
      for(int b = 0; b < 16; b++)
        {
         double temp_buf[];
         ArraySetAsSeries(temp_buf, true);
         if(CopyBuffer(m_handle_smc, b, 1, 2, temp_buf) >= 2)
           {
            double val = temp_buf[0]; // Bar 1 (just closed bar)
            if(val != 0.0 && val != EMPTY_VALUE && val != DBL_MAX && MathIsValidNumber(val))
              {
               Print("[SMC BUFFER DETECTED] Buffer ", b, " at Bar 1 value: ", val);
               if(b == 0 || b == 2 || b == 4 || b == 6) raw_buy_signal = true;
               if(b == 1 || b == 3 || b == 5 || b == 7) raw_sell_signal = true;
              }
           }
        }
     }

   // 2. Scan Chart Arrow Objects created by SMC Liquidity indicator (arrows, text "B", "S")
   datetime bar1_time = iTime(_Symbol, _Period, 1);
   int total_objs = ObjectsTotal(0, 0, -1);
   for(int i = total_objs - 1; i >= 0; i--)
     {
      string obj_name = ObjectName(0, i, 0, -1);
      datetime obj_time = (datetime)ObjectGetInteger(0, obj_name, OBJPROP_TIME);
      if(obj_time == bar1_time || obj_time == current_bar_time)
        {
         string text = ObjectGetString(0, obj_name, OBJPROP_TEXT);
         ENUM_OBJECT type = (ENUM_OBJECT)ObjectGetInteger(0, obj_name, OBJPROP_TYPE);
         
         if(text == "B" || type == OBJ_ARROW_BUY)
           {
            raw_buy_signal = true;
            Print("[SMC OBJ SIGNAL] Found BUY object: ", obj_name, " Text: '", text, "'");
           }
         else if(text == "S" || type == OBJ_ARROW_SELL)
           {
            raw_sell_signal = true;
            Print("[SMC OBJ SIGNAL] Found SELL object: ", obj_name, " Text: '", text, "'");
           }
        }
     }

   // 3. High-Precision Institutional SMC Liquidity Sweep & Structure Engine
   if(!raw_buy_signal && !raw_sell_signal)
     {
      double close1 = iClose(_Symbol, _Period, 1);
      double open1  = iOpen(_Symbol, _Period, 1);
      double high1  = iHigh(_Symbol, _Period, 1);
      double low1   = iLow(_Symbol, _Period, 1);

      double close2 = iClose(_Symbol, _Period, 2);
      double open2  = iOpen(_Symbol, _Period, 2);
      double high2  = iHigh(_Symbol, _Period, 2);
      double low2   = iLow(_Symbol, _Period, 2);

      // Find Swing High and Swing Low of previous 5 bars (bars 3 to 7)
      double prev_lowest_low = iLow(_Symbol, _Period, 3);
      double prev_highest_high = iHigh(_Symbol, _Period, 3);
      for(int k = 4; k <= 8; k++)
        {
         double l = iLow(_Symbol, _Period, k);
         double h = iHigh(_Symbol, _Period, k);
         if(l < prev_lowest_low) prev_lowest_low = l;
         if(h > prev_highest_high) prev_highest_high = h;
        }

      // Bullish SMC Sweep: Low swept liquidity below previous swing low, and bar 1 rejected strongly upwards
      if((low1 < prev_lowest_low || low2 < prev_lowest_low) && close1 > open1 && close1 > prev_lowest_low)
        {
         raw_buy_signal = true;
         Print("[INSTITUTIONAL SMC] Bullish Liquidity Sweep detected below ", prev_lowest_low, " -> Rejection Close at ", close1);
        }

      // Bearish SMC Sweep: High swept liquidity above previous swing high, and bar 1 rejected strongly downwards
      else if((high1 > prev_highest_high || high2 > prev_highest_high) && close1 < open1 && close1 < prev_highest_high)
        {
         raw_sell_signal = true;
         Print("[INSTITUTIONAL SMC] Bearish Liquidity Sweep detected above ", prev_highest_high, " -> Rejection Close at ", close1);
        }
     }

   // 4. Strict Hierarchy Validation against EMA 5/20/50 & VWAP Trend Filter
   double ema5[], ema20[], ema50[];
   ArraySetAsSeries(ema5, true);
   ArraySetAsSeries(ema20, true);
   ArraySetAsSeries(ema50, true);

   bool ema_bullish = true;
   bool ema_bearish = true;

   if(CopyBuffer(m_handle_ema_5, 0, 1, 2, ema5) >= 2 &&
      CopyBuffer(m_handle_ema_20, 0, 1, 2, ema20) >= 2 &&
      CopyBuffer(m_handle_ema_50, 0, 1, 2, ema50) >= 2)
     {
      ema_bullish = (ema5[0] >= ema20[0]);
      ema_bearish = (ema5[0] <= ema20[0]);

      if(InpUseVWAPFilter)
        {
         double close1 = iClose(_Symbol, _Period, 1);
         if(close1 < ema50[0]) ema_bullish = false;
         if(close1 > ema50[0]) ema_bearish = false;
        }
     }

   // H1 Higher Timeframe Trend Filter Alignment (Multi-Timeframe Guard)
   if(InpUseH1TrendFilter && m_handle_h1_ema_50 != INVALID_HANDLE)
     {
      double h1_ema50[];
      ArraySetAsSeries(h1_ema50, true);
      if(CopyBuffer(m_handle_h1_ema_50, 0, 1, 1, h1_ema50) > 0)
        {
         double h1_close1 = iClose(_Symbol, PERIOD_H1, 1);
         if(h1_close1 < h1_ema50[0]) ema_bullish = false; // Block M5 BUY when H1 is Bearish
         if(h1_close1 > h1_ema50[0]) ema_bearish = false; // Block M5 SELL when H1 is Bullish
        }
     }

   // ADX Trend Strength Filter Alignment (Filter out Ranging LV)
   if(InpUseADXFilter && m_handle_adx != INVALID_HANDLE)
     {
      double adx_buf[];
      ArraySetAsSeries(adx_buf, true);
      if(CopyBuffer(m_handle_adx, 0, 1, 1, adx_buf) > 0)
        {
         if(adx_buf[0] < InpMinADX)
           {
            ema_bullish = false;
            ema_bearish = false;
            if(raw_buy_signal || raw_sell_signal)
               Print("[ADX FILTER] Market in Ranging LV (ADX: ", DoubleToString(adx_buf[0], 1), " < Min ", InpMinADX, "). Signal ignored.");
           }
        }
     }

   // RSI Momentum Guard Alignment
   if(InpUseRSIFilter && m_handle_rsi != INVALID_HANDLE)
     {
      double rsi_buf[];
      ArraySetAsSeries(rsi_buf, true);
      if(CopyBuffer(m_handle_rsi, 0, 1, 1, rsi_buf) > 0)
        {
         double rsi_val = rsi_buf[0];
         if(raw_buy_signal && (rsi_val < InpRSI_BuyMin || rsi_val > InpRSI_BuyMax))
           {
            ema_bullish = false;
            Print("[RSI FILTER] Raw BUY signal blocked by RSI: ", DoubleToString(rsi_val, 1), " (Allowed: ", InpRSI_BuyMin, "-", InpRSI_BuyMax, ")");
           }
         if(raw_sell_signal && (rsi_val > InpRSI_SellMax || rsi_val < InpRSI_SellMin))
           {
            ema_bearish = false;
            Print("[RSI FILTER] Raw SELL signal blocked by RSI: ", DoubleToString(rsi_val, 1), " (Allowed: ", InpRSI_SellMin, "-", InpRSI_SellMax, ")");
           }
        }
     }

   bool buy_signal = raw_buy_signal && ema_bullish;
   bool sell_signal = raw_sell_signal && ema_bearish;

   if(raw_buy_signal && !ema_bullish)
     {
      Print("[SMC SIGNAL FILTERED] Raw BUY signal ignored due to Bearish EMA/VWAP Trend Filter.");
     }
   if(raw_sell_signal && !ema_bearish)
     {
      Print("[SMC SIGNAL FILTERED] Raw SELL signal ignored due to Bullish EMA/VWAP Trend Filter.");
     }

   Print("[SMC SCALPER SCAN] New Bar: ", TimeToString(current_bar_time), " | BuySignal: ", buy_signal, " | SellSignal: ", sell_signal, " | Spread: ", current_spread);

   // Close Open Positions on Opposite Signal
   if(InpCloseOnOppositeSignal)
     {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         if(m_position.SelectByIndex(i))
           {
            if(m_position.Symbol() == _Symbol && m_position.Magic() == InpMagicNumber)
              {
               if(m_position.PositionType() == POSITION_TYPE_BUY && sell_signal)
                 {
                  m_trade.PositionClose(m_position.Ticket());
                  Print("[OPPOSITE SIGNAL] Closed BUY #", m_position.Ticket(), " due to new SELL signal.");
                 }
               else if(m_position.PositionType() == POSITION_TYPE_SELL && buy_signal)
                 {
                  m_trade.PositionClose(m_position.Ticket());
                  Print("[OPPOSITE SIGNAL] Closed SELL #", m_position.Ticket(), " due to new BUY signal.");
                 }
              }
           }
        }
     }

   // Execute Trade Signals
   if(buy_signal)
     {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double high1 = iHigh(_Symbol, _Period, 1);
      double low1  = iLow(_Symbol, _Period, 1);
      double close1= iClose(_Symbol, _Period, 1);

      // Dynamic ATR Overextension Threshold (1.5 * ATR)
      double atr_buf[];
      ArraySetAsSeries(atr_buf, true);
      double current_atr_pts = 300.0; // Fallback 30 pips
      if(CopyBuffer(m_handle_atr, 0, 1, 1, atr_buf) > 0) current_atr_pts = (atr_buf[0] / _Point);

      double max_overext_pts = 1.5 * current_atr_pts;

      // Compute Dynamic SL & TP distances in points
      double sl_pips = InpFixedSL_Pips;
      double tp_pips = InpFixedTP_Pips;
      if(InpUseDynamicATR_SLTP && current_atr_pts > 0)
        {
         sl_pips = MathMax(InpATR_SL_Multiplier * current_atr_pts, 300.0);
         tp_pips = MathMax(InpATR_TP_Multiplier * current_atr_pts, 600.0);
        }

      double ema5_val = 0;
      double ema5_buf[];
      ArraySetAsSeries(ema5_buf, true);
      if(CopyBuffer(m_handle_ema_5, 0, 1, 1, ema5_buf) > 0) ema5_val = ema5_buf[0];

      double overext = (ema5_val > 0) ? MathAbs(ask - ema5_val) / _Point : 0;

      // 50% SMC Order Block Retest Level (from Rectangle Object or OB Midpoint)
      datetime bar1_time = iTime(_Symbol, _Period, 1);
      double ob_top, ob_bottom, ob_mid;
      GetSMCOrderBlockRange(true, bar1_time, ob_top, ob_bottom, ob_mid);
      double retest_price = NormalizeDouble(ob_mid, _Digits);
      if(retest_price <= 0 || retest_price >= ask) retest_price = NormalizeDouble(ask - 30 * _Point, _Digits);

      if(InpEntryMode == ENTRY_RETEST_LIMIT || overext > max_overext_pts)
        {
         double sl = InpUseFixedSL ? (retest_price - sl_pips * _Point) : 0;
         double tp = InpUseFixedTP ? (retest_price + tp_pips * _Point) : 0;
         double lot = CalculateLotSize(MathAbs(retest_price - sl));

         DeletePendingOrders();

         if(m_trade.BuyLimit(lot, retest_price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, InpTradeComment))
           {
            Print("[SMC BUY LIMIT] Placed BUY LIMIT at 50% FVG/OB Retest ", retest_price, " (Overext: ", DoubleToString(overext,1), " / Max ATR: ", DoubleToString(max_overext_pts,1), " pts) SL: ", sl, " TP: ", tp, " (SL Pts: ", DoubleToString(sl_pips,0), ")");
           }
        }
      else // ENTRY_MARKET_FAST
        {
         double sl = InpUseFixedSL ? (ask - sl_pips * _Point) : 0;
         double tp = InpUseFixedTP ? (ask + tp_pips * _Point) : 0;
         double lot = CalculateLotSize(MathAbs(ask - sl));
         if(m_trade.Buy(lot, _Symbol, ask, sl, tp, InpTradeComment))
           {
            Print("[SMC BUY] Opened Fast BUY at ", ask, " Lot: ", lot, " (SL Pts: ", DoubleToString(sl_pips,0), ")");
           }
        }
     }
   else if(sell_signal)
     {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double high1 = iHigh(_Symbol, _Period, 1);
      double low1  = iLow(_Symbol, _Period, 1);
      double close1= iClose(_Symbol, _Period, 1);

      // Dynamic ATR Overextension Threshold (1.5 * ATR)
      double atr_buf[];
      ArraySetAsSeries(atr_buf, true);
      double current_atr_pts = 300.0; // Fallback 30 pips
      if(CopyBuffer(m_handle_atr, 0, 1, 1, atr_buf) > 0) current_atr_pts = (atr_buf[0] / _Point);

      double max_overext_pts = 1.5 * current_atr_pts;

      // Compute Dynamic SL & TP distances in points
      double sl_pips = InpFixedSL_Pips;
      double tp_pips = InpFixedTP_Pips;
      if(InpUseDynamicATR_SLTP && current_atr_pts > 0)
        {
         sl_pips = MathMax(InpATR_SL_Multiplier * current_atr_pts, 300.0);
         tp_pips = MathMax(InpATR_TP_Multiplier * current_atr_pts, 600.0);
        }

      double ema5_val = 0;
      double ema5_buf[];
      ArraySetAsSeries(ema5_buf, true);
      if(CopyBuffer(m_handle_ema_5, 0, 1, 1, ema5_buf) > 0) ema5_val = ema5_buf[0];

      double overext = (ema5_val > 0) ? MathAbs(ema5_val - bid) / _Point : 0;

      // 50% SMC Order Block Retest Level (from Rectangle Object or OB Midpoint)
      datetime bar1_time = iTime(_Symbol, _Period, 1);
      double ob_top, ob_bottom, ob_mid;
      GetSMCOrderBlockRange(false, bar1_time, ob_top, ob_bottom, ob_mid);
      double retest_price = NormalizeDouble(ob_mid, _Digits);
      if(retest_price <= 0 || retest_price <= bid) retest_price = NormalizeDouble(bid + 30 * _Point, _Digits);

      if(InpEntryMode == ENTRY_RETEST_LIMIT || overext > max_overext_pts)
        {
         double sl = InpUseFixedSL ? (retest_price + sl_pips * _Point) : 0;
         double tp = InpUseFixedTP ? (retest_price - tp_pips * _Point) : 0;
         double lot = CalculateLotSize(MathAbs(sl - retest_price));

         DeletePendingOrders();

         if(m_trade.SellLimit(lot, retest_price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, InpTradeComment))
           {
            Print("[SMC SELL LIMIT] Placed SELL LIMIT at 50% FVG/OB Retest ", retest_price, " (Overext: ", DoubleToString(overext,1), " / Max ATR: ", DoubleToString(max_overext_pts,1), " pts) SL: ", sl, " TP: ", tp, " (SL Pts: ", DoubleToString(sl_pips,0), ")");
           }
        }
      else // ENTRY_MARKET_FAST
        {
         double sl = InpUseFixedSL ? (bid + sl_pips * _Point) : 0;
         double tp = InpUseFixedTP ? (bid - tp_pips * _Point) : 0;
         double lot = CalculateLotSize(MathAbs(sl - bid));
         if(m_trade.Sell(lot, _Symbol, bid, sl, tp, InpTradeComment))
           {
            Print("[SMC SELL] Opened Fast SELL at ", bid, " Lot: ", lot, " (SL Pts: ", DoubleToString(sl_pips,0), ")");
           }
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
//| Manage Pending Limit Orders Cleanup (Expiry by Bars or ATR Dist) |
//+------------------------------------------------------------------+
void ManagePendingOrders()
  {
   if(!InpUsePendingExpiry && !InpUseATRDistanceCancel) return;

   double atr_buf[];
   ArraySetAsSeries(atr_buf, true);
   double current_atr_pts = 300.0;
   if(CopyBuffer(m_handle_atr, 0, 1, 1, atr_buf) > 0) current_atr_pts = (atr_buf[0] / _Point);

   double max_distance_pts = 1.5 * current_atr_pts;
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0)
        {
         if(OrderGetString(ORDER_SYMBOL) == _Symbol && OrderGetInteger(ORDER_MAGIC) == InpMagicNumber)
           {
            ENUM_ORDER_TYPE order_type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
            if(order_type != ORDER_TYPE_BUY_LIMIT && order_type != ORDER_TYPE_SELL_LIMIT) continue;

            datetime setup_time = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
            double open_price   = OrderGetDouble(ORDER_PRICE_OPEN);

            // 1. Expiration by Bar Count (InpPendingOrderExpiryBars, default 5 bars)
            bool cancel_by_time = false;
            int elapsed_bars = 0;
            if(InpUsePendingExpiry && setup_time > 0)
              {
               int elapsed_seconds = (int)(TimeCurrent() - setup_time);
               int bar_seconds = PeriodSeconds(_Period);
               if(bar_seconds > 0)
                 {
                  elapsed_bars = elapsed_seconds / bar_seconds;
                  if(elapsed_bars >= InpPendingOrderExpiryBars)
                    {
                     cancel_by_time = true;
                    }
                 }
              }

            // 2. Cancellation by Distance (> 1.5x ATR away)
            bool cancel_by_dist = false;
            double dist_pts = 0;
            if(InpUseATRDistanceCancel && max_distance_pts > 0)
              {
               if(order_type == ORDER_TYPE_BUY_LIMIT) dist_pts = MathAbs(ask - open_price) / _Point;
               else if(order_type == ORDER_TYPE_SELL_LIMIT) dist_pts = MathAbs(open_price - bid) / _Point;

               if(dist_pts > max_distance_pts)
                 {
                  cancel_by_dist = true;
                 }
              }

            if(cancel_by_time || cancel_by_dist)
              {
               if(m_trade.OrderDelete(ticket))
                 {
                  Print("[PENDING ORDER CANCELED] #", ticket, " (Reason: ", 
                        (cancel_by_time ? StringFormat("Expired after %d bars", elapsed_bars) : ""),
                        (cancel_by_time && cancel_by_dist ? " & " : ""),
                        (cancel_by_dist ? StringFormat("Distance %.1f pts > 1.5x ATR (%.1f pts)", dist_pts, max_distance_pts) : ""),
                        ")");
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Get SMC Order Block Range (Rectangle Object or Candle High/Low)  |
//+------------------------------------------------------------------+
void GetSMCOrderBlockRange(bool is_buy, datetime bar1_time, double &ob_top, double &ob_bottom, double &ob_mid)
  {
   double high1 = iHigh(_Symbol, _Period, 1);
   double low1  = iLow(_Symbol, _Period, 1);

   ob_top = high1;
   ob_bottom = low1;
   ob_mid = (high1 + low1) * 0.5;

   int total_objs = ObjectsTotal(0, 0, -1);
   for(int i = total_objs - 1; i >= 0; i--)
     {
      string name = ObjectName(0, i, 0, -1);
      ENUM_OBJECT type = (ENUM_OBJECT)ObjectGetInteger(0, name, OBJPROP_TYPE);

      if(type == OBJ_RECTANGLE)
        {
         datetime time1 = (datetime)ObjectGetInteger(0, name, OBJPROP_TIME, 0);
         datetime time2 = (datetime)ObjectGetInteger(0, name, OBJPROP_TIME, 1);

         if(time1 >= bar1_time - 5 * PeriodSeconds(_Period) || time2 >= bar1_time - 5 * PeriodSeconds(_Period))
           {
            double price1 = ObjectGetDouble(0, name, OBJPROP_PRICE, 0);
            double price2 = ObjectGetDouble(0, name, OBJPROP_PRICE, 1);
            color col = (color)ObjectGetInteger(0, name, OBJPROP_COLOR);

            if((!is_buy && (col == clrRed || col == clrCrimson || col == clrMaroon || price1 > price2)) ||
               (is_buy && (col == clrGreen || col == clrLime || col == clrBlue || price1 < price2)))
              {
               ob_top = MathMax(price1, price2);
               ob_bottom = MathMin(price1, price2);
               ob_mid = (ob_top + ob_bottom) * 0.5;
               Print("[SMC RECTANGLE OB FOUND] Object: '", name, "' | Top: ", ob_top, " | Bottom: ", ob_bottom, " | Mid (50%): ", ob_mid);
               return;
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
//| Chart Event Handler (Minimize/Expand HUD Panel Button)           |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(id == CHARTEVENT_OBJECT_CLICK)
     {
      if(sparam == "SMC_SCALPER_MinBtn")
        {
         m_hud_minimized = !m_hud_minimized;
         CreateDashboard();
         UpdateDashboard();
         ChartRedraw();
        }
     }
  }

//+------------------------------------------------------------------+
//| Calculate Today's Closed Stats (PnL, Wins, Losses, WinRate)      |
//+------------------------------------------------------------------+
void CalculateTodayStats(double &today_pnl, int &wins, int &losses, double &win_rate)
  {
   today_pnl = 0.0;
   wins = 0;
   losses = 0;
   win_rate = 0.0;

   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   datetime today_start = StructToTime(dt);

   if(!HistorySelect(today_start, now)) return;

   int total_deals = HistoryDealsTotal();
   for(int i = 0; i < total_deals; i++)
     {
      ulong deal_ticket = HistoryDealGetTicket(i);
      if(deal_ticket > 0)
        {
         if(HistoryDealGetString(deal_ticket, DEAL_SYMBOL) == _Symbol &&
            HistoryDealGetInteger(deal_ticket, DEAL_MAGIC) == InpMagicNumber &&
            HistoryDealGetInteger(deal_ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
           {
            double profit = HistoryDealGetDouble(deal_ticket, DEAL_PROFIT) +
                            HistoryDealGetDouble(deal_ticket, DEAL_SWAP) +
                            HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION);
            today_pnl += profit;
            if(profit > 0) wins++;
            else if(profit < 0) losses++;
           }
        }
     }

   int total_trades = wins + losses;
   if(total_trades > 0) win_rate = ((double)wins / total_trades) * 100.0;
  }

//+------------------------------------------------------------------+
//| Get Active Trade & Pending Order Information                     |
//+------------------------------------------------------------------+
void GetActiveTradeInfo(string &trade_info, string &sl_tp_info)
  {
   trade_info = "Sin Operación Activa";
   sl_tp_info = "";

   // Check Active Position
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i))
        {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == InpMagicNumber)
           {
            string type_str = (m_position.PositionType() == POSITION_TYPE_BUY) ? "BUY" : "SELL";
            double open_price = m_position.PriceOpen();
            double sl = m_position.StopLoss();
            double tp = m_position.TakeProfit();
            double lot = m_position.Volume();
            double pnl = m_position.Profit() + m_position.Swap();

            trade_info = StringFormat("%s %.2f @ %.2f (PnL: %+.2f$)", type_str, lot, open_price, pnl);
            sl_tp_info = StringFormat("SL: %.2f  |  TP: %.2f", sl, tp);
            return;
           }
        }
     }

   // Check Pending Limit Order
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0)
        {
         if(OrderGetString(ORDER_SYMBOL) == _Symbol && OrderGetInteger(ORDER_MAGIC) == InpMagicNumber)
           {
            ENUM_ORDER_TYPE order_type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
            string type_str = (order_type == ORDER_TYPE_BUY_LIMIT) ? "BUY LIMIT" :
                              (order_type == ORDER_TYPE_SELL_LIMIT) ? "SELL LIMIT" : "PENDIENTE";
            double price = OrderGetDouble(ORDER_PRICE_OPEN);
            double sl = OrderGetDouble(ORDER_SL);
            double tp = OrderGetDouble(ORDER_TP);
            trade_info = StringFormat("%s @ %.2f (Pendiente)", type_str, price);
            sl_tp_info = StringFormat("SL: %.2f  |  TP: %.2f", sl, tp);
            return;
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Dashboard Display                                                |
//+------------------------------------------------------------------+
void CreateDashboard()
  {
   if(!InpEnableInfoPanel) return;

   ObjectsDeleteAll(0, "SMC_SCALPER_");

   int x = InpXPosition;
   int y = InpYPosition;

   string bg_name = "SMC_SCALPER_BG";
   ObjectCreate(0, bg_name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, bg_name, OBJPROP_CORNER, InpCornerPosition);
   ObjectSetInteger(0, bg_name, OBJPROP_XDISTANCE, x - 10);
   ObjectSetInteger(0, bg_name, OBJPROP_YDISTANCE, y - 5);
   ObjectSetInteger(0, bg_name, OBJPROP_BGCOLOR, C'12,14,18');
   ObjectSetInteger(0, bg_name, OBJPROP_BORDER_COLOR, C'45,55,70');
   ObjectSetInteger(0, bg_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, bg_name, OBJPROP_BACK, false);
   ObjectSetInteger(0, bg_name, OBJPROP_SELECTABLE, false);

   if(m_hud_minimized)
     {
      ObjectSetInteger(0, bg_name, OBJPROP_XSIZE, 240);
      ObjectSetInteger(0, bg_name, OBJPROP_YSIZE, 28);

      CreateLabel("SMC_SCALPER_Title", "SMC SCALPER v1.0", x, y, clrGold, 10, true);
      CreateButton("SMC_SCALPER_MinBtn", "[ + ]", x + 180, y - 2, clrLightGray, 8);
      return;
     }

   // Expanded Panel
   ObjectSetInteger(0, bg_name, OBJPROP_XSIZE, 305);
   ObjectSetInteger(0, bg_name, OBJPROP_YSIZE, 205);

   // Header
   CreateLabel("SMC_SCALPER_Title", "SMC LIQUIDITY SCALPER v1.0", x, y, clrGold, 11, true);
   CreateButton("SMC_SCALPER_MinBtn", "[ _ ]", x + 245, y - 2, clrLightGray, 8);

   // Section 1: Daily Stats
   CreateLabel("SMC_SCALPER_LblPnl", "Ganado Hoy:", x, y + 24, clrDarkGray, 9, false);
   CreateLabel("SMC_SCALPER_ValPnl", "+0.00 USD", x + 110, y + 24, clrWhite, 9, true);

   CreateLabel("SMC_SCALPER_LblWin", "Operaciones Hoy:", x, y + 44, clrDarkGray, 9, false);
   CreateLabel("SMC_SCALPER_ValWin", "0 / 0 (0%)", x + 110, y + 44, clrWhite, 9, false);

   CreateLabel("SMC_SCALPER_LblFloat", "Flotante Actual:", x, y + 64, clrDarkGray, 9, false);
   CreateLabel("SMC_SCALPER_ValFloat", "0.00 USD", x + 110, y + 64, clrWhite, 9, false);

   CreateLabel("SMC_SCALPER_LblBal", "Balance Cuenta:", x, y + 84, clrDarkGray, 9, false);
   CreateLabel("SMC_SCALPER_ValBal", "0.00 USD", x + 110, y + 84, clrLightGray, 9, false);

   CreateLabel("SMC_SCALPER_LblSpread", "SPREAD:", x, y + 104, clrDarkGray, 9, false);
   CreateLabel("SMC_SCALPER_ValSpread", "0 pts", x + 110, y + 104, clrCyan, 9, true);

   // Divider Line
   CreateLabel("SMC_SCALPER_Sep", "----------------------------------------------------", x, y + 120, clrDarkSlateGray, 8, false);

   // Section 2: Active Trade & Signal Status
   CreateLabel("SMC_SCALPER_LblStatus", "ESTADO:", x, y + 135, clrDarkGray, 9, false);
   CreateLabel("SMC_SCALPER_ValStatus", "Buscando Señal SMC...", x + 65, y + 135, clrSpringGreen, 9, true);

   CreateLabel("SMC_SCALPER_LblTrade", "OPERACIÓN:", x, y + 155, clrDarkGray, 9, false);
   CreateLabel("SMC_SCALPER_ValTrade", "Sin Operación Activa", x + 85, y + 155, clrWhite, 9, false);

   CreateLabel("SMC_SCALPER_ValSLTP", "", x, y + 175, clrGold, 9, false);
   ChartRedraw(0);
  }

void UpdateDashboard()
  {
   if(!InpEnableInfoPanel) return;

   // Calculate Today's Closed Stats
   double today_pnl = 0.0;
   int wins = 0, losses = 0;
   double win_rate = 0.0;
   CalculateTodayStats(today_pnl, wins, losses, win_rate);

   // Floating Profit
   double floating_pnl = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i))
        {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == InpMagicNumber)
           {
            floating_pnl += m_position.Profit() + m_position.Swap();
           }
        }
     }

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double spread  = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);

   if(m_hud_minimized)
     {
      string min_txt = StringFormat("SMC v1.0 | PnL: %+.2f$", today_pnl);
      ObjectSetString(0, "SMC_SCALPER_Title", OBJPROP_TEXT, min_txt);
      ChartRedraw(0);
      return;
     }

   // Update Expanded Fields
   color pnl_col = (today_pnl > 0) ? clrLimeGreen : (today_pnl < 0) ? clrRed : clrWhite;
   ObjectSetString(0, "SMC_SCALPER_ValPnl", OBJPROP_TEXT, StringFormat("%+.2f USD", today_pnl));
   ObjectSetInteger(0, "SMC_SCALPER_ValPnl", OBJPROP_COLOR, pnl_col);

   ObjectSetString(0, "SMC_SCALPER_ValWin", OBJPROP_TEXT, StringFormat("%d Gan / %d Per (%.0f%%)", wins, losses, win_rate));

   color float_col = (floating_pnl > 0) ? clrLimeGreen : (floating_pnl < 0) ? clrRed : clrWhite;
   ObjectSetString(0, "SMC_SCALPER_ValFloat", OBJPROP_TEXT, StringFormat("%+.2f USD", floating_pnl));
   ObjectSetInteger(0, "SMC_SCALPER_ValFloat", OBJPROP_COLOR, float_col);

   ObjectSetString(0, "SMC_SCALPER_ValBal", OBJPROP_TEXT, StringFormat("%.2f USD", balance));

   ObjectSetString(0, "SMC_SCALPER_ValSpread", OBJPROP_TEXT, StringFormat("%.0f pts (%.1f pips)", spread, spread / 10.0));

   // Active Trade Details
   string trade_info = "", sl_tp_info = "";
   GetActiveTradeInfo(trade_info, sl_tp_info);

   ObjectSetString(0, "SMC_SCALPER_ValTrade", OBJPROP_TEXT, trade_info);
   ObjectSetString(0, "SMC_SCALPER_ValSLTP", OBJPROP_TEXT, sl_tp_info);
   ChartRedraw(0);
  }

void CreateLabel(string name, string text, int x, int y, color col, int font_size, bool is_bold)
  {
   ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, InpCornerPosition);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, col);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size);
   ObjectSetString(0, name, OBJPROP_FONT, is_bold ? "Arial Bold" : "Arial");
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
  }

void CreateButton(string name, string text, int x, int y, color col, int font_size)
  {
   ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, InpCornerPosition);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, col);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
  }

//+------------------------------------------------------------------+
//| Delete Pending Orders for Magic Number                           |
//+------------------------------------------------------------------+
void DeletePendingOrders()
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0)
        {
         if(OrderGetString(ORDER_SYMBOL) == _Symbol && OrderGetInteger(ORDER_MAGIC) == InpMagicNumber)
           {
            m_trade.OrderDelete(ticket);
           }
        }
     }
  }
//+------------------------------------------------------------------+

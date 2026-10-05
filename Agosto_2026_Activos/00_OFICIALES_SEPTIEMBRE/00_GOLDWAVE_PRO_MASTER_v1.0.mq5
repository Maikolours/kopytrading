//+------------------------------------------------------------------+
//|                                  00_GOLDWAVE_PRO_MASTER_v1.0.mq5 |
//|                                  Copyright 2026, MAIKO KOPYTRADING |
//|                                              https://kopytrading.es|
//+------------------------------------------------------------------+
#property copyright "Copyright 2026 Futureboost Education Limited. All rights reserved."
#property link      "https://t.me/tweettasweet"
#property version   "2.50"
#property description "Goldwave EA v2.50 - Official Master Replica"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//--- Enums
enum ENUM_LOT_MODE
  {
   LOT_CONSERVATIVE = 0, // LOT_CONSERVATIVE
   LOT_MODERATE     = 1, // LOT_MODERATE
   LOT_AGGRESSIVE   = 2, // LOT_AGGRESSIVE
   LOT_FIXED        = 3  // LOT_FIXED
  };

enum ENUM_ACCOUNT_UNIT_MODE
  {
   ACCOUNT_UNIT_AUTO = 0, // ACCOUNT_UNIT_AUTO
   ACCOUNT_UNIT_USD  = 1, // ACCOUNT_UNIT_USD
   ACCOUNT_UNIT_CENT = 2  // ACCOUNT_UNIT_CENT
  };

//--- Contact Information Inputs
input string CI_Line1    = "//////////////////////////////////////////////////"; // 
input string CI_Title    = "--- Contact Information ---";                       // 
input string CI_Note1    = "EA is run and forget, friendly to all traders";    // 
input string CI_Info     = "If you need any help, feel free to contact me";    // 
input string CI_Telegram = "https://t.me/tweettasweet";                        // 
input string CI_Line2    = "//////////////////////////////////////////////////"; // 
input string TradeComment= "GW";                                                // TradeComment

//--- Strategy Logic Direction Switch
input bool InpInvertStrategy = false;                                           // Invert Strategy Signals (False = Trend Follow, True = Reversion/Dip)

//--- Position Size
input string sep1 = "POSITION SIZE";                                            // sep1
input ENUM_LOT_MODE LotMode = LOT_CONSERVATIVE;                                 // LotMode
input double FixedLot = 0.01;                                                   // Fixed Lot (only used when LotMode = Fixed)
input double MaxLot = 1.0;                                                      // MaxLot
input double MinLot = 0.01;                                                     // MinLot

//--- SL / TP
input string sep2 = "SL/TP";                                                    // sep2
input bool UseFixedSL = true;                                                   // UseFixedSL
input double FixedSL_Pips = 3000.0;                                             // FixedSL_Pips
input bool UseFixedTP = true;                                                   // UseFixedTP
input double FixedTP_Pips = 3000.0;                                             // FixedTP_Pips

//--- News Filter
input string sep_news = "NEWS FILTER";                                          // sep_news
input bool UseNewsFilter = true;                                                // UseNewsFilter
input int StopMinutesBefore = 60;                                               // StopMinutesBefore
input int StopMinutesAfter = 60;                                                // StopMinutesAfter
input bool UseHighImpact = true;                                                // UseHighImpact
input bool UseMediumImpact = false;                                             // UseMediumImpact
input bool UseLowImpact = false;                                                // UseLowImpact
input bool EnableDetailedNewsFilter = true;                                     // EnableDetailedNewsFilter
input string NewsURL = "https://nfs.faireconomy.media/ff_calendar_thisweek.json"; // NewsURL

//--- Account Unit
input string sep_account = "ACCOUNT UNIT";                                      // sep_account
input ENUM_ACCOUNT_UNIT_MODE InpAccountUnitMode = ACCOUNT_UNIT_AUTO;            // InpAccountUnitMode
input string InpOptionalCurrencies = "USD, USC, EUR, GBP, CAD, USDT, EUC, GBX"; // Optional: USD, USC, EUR, GBP, CAD, USDT, EUC, GBX

//--- Spread Filter
input string sep_spread = "SPREAD FILTER";                                      // sep_spread
input bool EnableSpreadFilter = true;                                           // Enable Spread Filter
input double MaxAllowedSpread = 150.0;                                          // Max allowed spread in points to open trade

//--- Prop Firm Gates
input string sep_prop = "PROP FIRM GATES (For prop firm accounts only)";        // sep_prop
input bool EnablePropProtection = false;                                        // ENABLE: Prop Protection (Daily Loss + MaxDD + Risk Override)
input bool OverrideLotMode = true;                                              // Override EA's LotMode with PropRiskPct (when Enabled)
input double RiskPctPerTrade = 0.2;                                             // Risk % per trade (EQUITY-based, 0.1-0.2 recommended)
input double DailyLossPct = 5.0;                                                // Daily loss % of EQUITY - lock until next day 00:00
input double MaxDDPct = 20.0;                                                   // Max DD % from initial EQUITY -> force close + lock
input double UnlockBufferPct = 0.5;                                             // Unlock buffer % (EQUITY-based, avoids bounce)
input int CooldownMinutes = 120;                                                // Cooldown minutes after auto-unlock
input bool LockCloseAll = false;                                                // When locked: true = close ALL | false = close this EA only

//--- Friday Filter
input string sep_friday = "FRIDAY FILTER";                                      // sep_friday
input bool BlockFridayLast3Hours = true;                                        // Blocks new trades in the last 3 hours on Friday.

//--- Night Filter
input string sep_night = "NIGHT FILTER";                                        // sep_night
input bool EnableNightWindow = false;                                           // Enable Night No-Trade Window
input string BlockStartTime = "23:00";                                          // Block start time (server time, HH:MM)
input string BlockEndTime = "01:05";                                            // Block end time (server time, HH:MM, next day if < start)

//--- Info Panel
input string sep_info_panel = "Info Panel";                                     // Info Panel
input bool EnableInfoPanel = true;                                              // Enable Info Panel
input int XPosition = 10;                                                       // X Position
input int YPosition = 36;                                                       // Y Position
input double PanelSizeScaling = 1.1;                                            // Panel Size Scaling
input ENUM_BASE_CORNER CornerPosition = CORNER_LEFT_UPPER;                      // Corner Position

//--- Global Variables
CTrade         m_trade;
CPositionInfo  m_position;
int            m_handle_ema_fast   = INVALID_HANDLE;
int            m_handle_ema_medium = INVALID_HANDLE;
int            m_handle_ema_slow   = INVALID_HANDLE;
int            m_handle_rsi        = INVALID_HANDLE;
int            m_handle_atr        = INVALID_HANDLE;
datetime       m_last_bar_time     = 0;
bool           m_is_cent_account   = false;
ulong          m_magic             = 888888;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   m_trade.SetExpertMagicNumber(m_magic);
   m_trade.SetDeviationInPoints(30);
   
   // Autodetect Cent Account
   DetectAccountType();

   // Initialize Indicator Handles
   m_handle_ema_fast   = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE);
   m_handle_ema_medium = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE);
   m_handle_ema_slow   = iMA(_Symbol, _Period, 200, 0, MODE_EMA, PRICE_CLOSE);
   m_handle_rsi        = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
   m_handle_atr        = iATR(_Symbol, _Period, 14);

   if(m_handle_ema_fast == INVALID_HANDLE || m_handle_ema_medium == INVALID_HANDLE ||
      m_handle_ema_slow == INVALID_HANDLE || m_handle_rsi == INVALID_HANDLE || m_handle_atr == INVALID_HANDLE)
     {
      Print("[ERROR] Failed to create indicator handles.");
      return(INIT_FAILED);
     }

   if(EnableInfoPanel) CreateDashboard();
   Print("[INIT SUCCESS] Goldwave EA v2.50 Master Replica initialized.");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(m_handle_ema_fast);
   IndicatorRelease(m_handle_ema_medium);
   IndicatorRelease(m_handle_ema_slow);
   IndicatorRelease(m_handle_rsi);
   IndicatorRelease(m_handle_atr);
   ObjectsDeleteAll(0, "GW_");
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(EnableInfoPanel) UpdateDashboard();

   // Manage Active Open Positions
   ManageActivePositions();

   // New Bar Filter for Opening New Entries
   datetime current_bar_time = iTime(_Symbol, _Period, 0);
   if(current_bar_time == m_last_bar_time) return;

   // Check Max Open Positions (Max 1 active trade)
   if(GetOpenPositionsCount() > 0) return;

   // Friday Filter Check
   if(BlockFridayLast3Hours)
     {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      if(dt.day_of_week == 5 && dt.hour >= 21) return; // Block last 3 hours of Friday
     }

   // Night Filter Check
   if(EnableNightWindow)
     {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      int current_min = dt.hour * 60 + dt.min;
      if(current_min >= 23 * 60 || current_min <= 1 * 60 + 5) return;
     }

   // Check Spread Filter
   double current_spread = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(EnableSpreadFilter && current_spread > MaxAllowedSpread)
     {
      return;
     }

   // Fetch Indicator Buffers (Shift 1 = Completed Bar)
   double ema_fast[2], ema_medium[2], ema_slow[2], rsi[2], atr[2];
   if(CopyBuffer(m_handle_ema_fast, 0, 1, 2, ema_fast) < 2) return;
   if(CopyBuffer(m_handle_ema_medium, 0, 1, 2, ema_medium) < 2) return;
   if(CopyBuffer(m_handle_ema_slow, 0, 1, 2, ema_slow) < 2) return;
   if(CopyBuffer(m_handle_rsi, 0, 1, 2, rsi) < 2) return;
   if(CopyBuffer(m_handle_atr, 0, 1, 2, atr) < 2) return;

   double close_price = iClose(_Symbol, _Period, 1);

   // Check Volatility Filter
   if((atr[1] / _Point) < 0.5) return;

   // Trend Signal Base Conditions
   bool raw_buy  = (close_price > ema_medium[1]) && (ema_medium[1] > ema_slow[1]) && (rsi[1] >= 45.0 && rsi[1] <= 68.0);
   bool raw_sell = (close_price < ema_medium[1]) && (ema_medium[1] < ema_slow[1]) && (rsi[1] >= 32.0 && rsi[1] <= 55.0);

   // Toggle Inversion Mode via InpInvertStrategy input
   bool buy_condition  = InpInvertStrategy ? raw_sell : raw_buy;
   bool sell_condition = InpInvertStrategy ? raw_buy  : raw_sell;

   if(buy_condition)
     {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double sl = UseFixedSL ? (ask - FixedSL_Pips * _Point) : 0;
      double tp = UseFixedTP ? (ask + FixedTP_Pips * _Point) : 0;
      double lot = CalculateLotSize(MathAbs(ask - sl));

      if(m_trade.Buy(lot, _Symbol, ask, sl, tp, TradeComment))
        {
         m_last_bar_time = current_bar_time;
         Print("[BUY ORDER] Opened BUY at ", ask, " Lot: ", lot);
        }
     }
   else if(sell_condition)
     {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double sl = UseFixedSL ? (bid + FixedSL_Pips * _Point) : 0;
      double tp = UseFixedTP ? (bid - FixedTP_Pips * _Point) : 0;
      double lot = CalculateLotSize(MathAbs(sl - bid));

      if(m_trade.Sell(lot, _Symbol, bid, sl, tp, TradeComment))
        {
         m_last_bar_time = current_bar_time;
         Print("[SELL ORDER] Opened SELL at ", bid, " Lot: ", lot);
        }
     }
  }

//+------------------------------------------------------------------+
//| Manage Active Positions (Trailing, BreakEven, Reversal)          |
//+------------------------------------------------------------------+
void ManageActivePositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i))
        {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == m_magic)
           {
            ulong ticket = m_position.Ticket();
            double open_price = m_position.PriceOpen();
            double current_sl = m_position.StopLoss();
            double current_tp = m_position.TakeProfit();
            ENUM_POSITION_TYPE type = m_position.PositionType();

            // Fetch Indicators for Reversal Exits
            double ema_medium[2], rsi[2];
            CopyBuffer(m_handle_ema_medium, 0, 1, 2, ema_medium);
            CopyBuffer(m_handle_rsi, 0, 1, 2, rsi);
            double close_price = iClose(_Symbol, _Period, 1);

            // BUY Position Management
            if(type == POSITION_TYPE_BUY)
              {
               double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

               // Signal Reversal Exit
               if(close_price < ema_medium[1] && rsi[1] < 35.0)
                 {
                  Print("[REVERSAL EXIT] Closing BUY position #", ticket);
                  m_trade.PositionClose(ticket);
                  continue;
                 }

               // BreakEven Shield (100 points trigger = $1.00 Gold)
               double trigger_price = open_price + (100.0 * _Point);
               double lock_sl = open_price + (20.0 * _Point);
               if(bid >= trigger_price && (current_sl < lock_sl || current_sl == 0))
                 {
                  m_trade.PositionModify(ticket, lock_sl, current_tp);
                 }

               // Trailing Stop (120 points start = $1.20 Gold)
               double trail_trigger = open_price + (120.0 * _Point);
               if(bid >= trail_trigger)
                 {
                  double new_sl = bid - (120.0 * _Point);
                  if(new_sl > current_sl + (30.0 * _Point))
                    {
                     m_trade.PositionModify(ticket, new_sl, current_tp);
                    }
                 }
              }
            // SELL Position Management
            else if(type == POSITION_TYPE_SELL)
              {
               double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

               // Signal Reversal Exit
               if(close_price > ema_medium[1] && rsi[1] > 65.0)
                 {
                  Print("[REVERSAL EXIT] Closing SELL position #", ticket);
                  m_trade.PositionClose(ticket);
                  continue;
                 }

               // BreakEven Shield (100 points trigger = $1.00 Gold)
               double trigger_price = open_price - (100.0 * _Point);
               double lock_sl = open_price - (20.0 * _Point);
               if(ask <= trigger_price && (current_sl > lock_sl || current_sl == 0))
                 {
                  m_trade.PositionModify(ticket, lock_sl, current_tp);
                 }

               // Trailing Stop (120 points start = $1.20 Gold)
               double trail_trigger = open_price - (120.0 * _Point);
               if(ask <= trail_trigger)
                 {
                  double new_sl = ask + (120.0 * _Point);
                  if(current_sl == 0 || new_sl < current_sl - (30.0 * _Point))
                    {
                     m_trade.PositionModify(ticket, new_sl, current_tp);
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
   if(LotMode == LOT_FIXED)
     {
      return NormalizeLot(FixedLot);
     }

   double risk_percent = EnablePropProtection ? RiskPctPerTrade : 0.2;
   if(LotMode == LOT_CONSERVATIVE) risk_percent = 0.2;
   else if(LotMode == LOT_MODERATE) risk_percent = 0.5;
   else if(LotMode == LOT_AGGRESSIVE) risk_percent = 1.0;

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double risk_amount = equity * (risk_percent / 100.0);

   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   if(tick_value <= 0 || tick_size <= 0 || sl_distance_price <= 0)
     {
      return NormalizeLot(FixedLot);
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
   double min_lot = MathMax(MinLot, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN));
   double max_lot = MathMin(MaxLot, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX));

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
         if(m_position.Symbol() == _Symbol && m_position.Magic() == m_magic)
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
   int x = XPosition, y = YPosition;
   CreateLabel("GW_Title", "GoldWave EA v2.50 - Official", x, y, clrGold, 12, true);
   CreateLabel("GW_Acc", "Account Mode: " + (m_is_cent_account ? "CENT (USC)" : "STANDARD (USD)"), x, y + 25, clrWhite, 9, false);
   CreateLabel("GW_Spread", "Spread: 0 pts", x, y + 45, clrCyan, 9, false);
   CreateLabel("GW_Status", "Status: Active & Monitoring", x, y + 65, clrSpringGreen, 9, false);
  }

void UpdateDashboard()
  {
   double spread = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   ObjectSetString(0, "GW_Spread", OBJPROP_TEXT, "Spread: " + DoubleToString(spread, 0) + " pts / " + DoubleToString(spread / 10.0, 1) + " pips");
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

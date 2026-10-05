//+------------------------------------------------------------------+
//|                                           probe_smc_buffers.mq5 |
//|                                  Copyright 2026, MAIKO KOPYTRADING |
//+------------------------------------------------------------------+
#property copyright "MAIKO KOPYTRADING"
#property version   "1.00"
#property script_show_inputs

input string InpIndicatorName = "Market\\SMC Liquidity";

void OnStart()
  {
   Print("=== PROBING SMC LIQUIDITY INDICATOR BUFFERS ===");
   int handle = iCustom(_Symbol, _Period, InpIndicatorName);
   if(handle == INVALID_HANDLE)
     {
      Print("[ERROR] Failed to load indicator handle: ", InpIndicatorName, " Error: ", GetLastError());
      return;
     }

   Print("[SUCCESS] Handle loaded. Scanning buffers 0 to 30 across 100 bars...");

   for(int b = 0; b < 32; b++)
     {
      double buf[];
      ArraySetAsSeries(buf, true);
      int copied = CopyBuffer(handle, b, 0, 100, buf);
      if(copied > 0)
        {
         int non_zero_count = 0;
         string sample_vals = "";
         for(int i = 0; i < copied; i++)
           {
            if(buf[i] != 0.0 && buf[i] != EMPTY_VALUE && buf[i] != DBL_MAX && MathIsValidNumber(buf[i]))
              {
               non_zero_count++;
               if(non_zero_count <= 5)
                 {
                  sample_vals += StringFormat("[Bar %d: %.2f] ", i, buf[i]);
                 }
              }
           }
         if(non_zero_count > 0)
           {
            Print(StringFormat(">>> BUFFER %d: Active! Found %d non-zero entries. Samples: %s", b, non_zero_count, sample_vals));
           }
        }
     }
   IndicatorRelease(handle);
   Print("=== PROBE COMPLETE ===");
  }

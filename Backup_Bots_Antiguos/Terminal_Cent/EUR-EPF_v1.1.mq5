//+------------------------------------------------------------------+
//| EUR-EPF_v1.1.mq5 - EURO PRECISION FLOW                            |
//| Bot conservador para EURUSD                                       |
//| Product Key: EUR-EPF                                              |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "1.10"

#include <Kopytrading_Integration.mqh>
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

input string PurchaseID = "";
input string LicenseKey = "EUR-EPF";
input double LoteManual = 0.01;
input int    MagicNumber = 700846;

CTrade trade;
CPositionInfo posInfo;

int OnInit() {
   if(!ValidateLicense(PurchaseID, LicenseKey, (int)AccountInfoInteger(ACCOUNT_LOGIN))) return INIT_FAILED;
   trade.SetExpertMagicNumber(MagicNumber);
   return INIT_SUCCEEDED;
}

void OnTick() {
   GetRemoteStatus();
   if(IsRemotePaused()) return;
   
   // Lógica de trading EUR-EPF simplificada
   if(PositionsTotal() == 0) {
      trade.Sell(LoteManual, _Symbol);
   }
   
   SyncPositions("RUNNING", 0, 1);
}

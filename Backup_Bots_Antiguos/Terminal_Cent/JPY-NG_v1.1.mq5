//+------------------------------------------------------------------+
//| JPY-NG_v1.1.mq5 - NINJA GHOST                                     |
//| Bot agresivo para USDJPY                                          |
//| Product Key: JPY-NG                                               |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property link      "https://www.kopytrading.com"
#property version   "1.10"

#include <Kopytrading_Integration.mqh>
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

input string PurchaseID = "";
input string LicenseKey = "JPY-NG";
input double LoteManual = 0.01;
input int    MagicNumber = 700845;

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
   
   // Lógica de trading JPY-NG simplificada
   if(PositionsTotal() == 0) {
      trade.Buy(LoteManual, _Symbol);
   }
   
   SyncPositions("RUNNING", 0, 1);
}

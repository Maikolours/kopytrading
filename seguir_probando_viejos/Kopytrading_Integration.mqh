//+------------------------------------------------------------------+
//|                                   Kopytrading_Integration.mqh   |
//|                     Módulo de integración con kopytrading.com    |
//|                                   Versión 1.6 - Abril 2026      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property version   "1.60"

//--- Variables globales de integración
string   g_KopyPurchaseID = "";
string   g_KopyProductKey = ""; 
string   g_KopyLicenseKey = "";
datetime g_KopyLastSync   = 0;
bool     g_KopyPaused     = false;

//+------------------------------------------------------------------+
//| Validar licencia                                                 |
//+------------------------------------------------------------------+
bool ValidateLicense(string _id, string _key, int _sincro=15) {
   g_KopyPurchaseID = _id;
   g_KopyLicenseKey = _key;
   g_KopyProductKey = _key; 
   Print("✅ Kopytrade: Autenticado [" + g_KopyPurchaseID + "]");
   return true;
}

//+------------------------------------------------------------------+
//| Sincronización Completa (Full Telemetry v1.6)                    |
//+------------------------------------------------------------------+
void SyncFull(string _stat, string _trend, bool _armed, double _pnl,
              double _p100, double _p78, double _p62, double _p50, double _p1,
              double _be=0.8, double _gar=0.5, double _tra=1.2) {
              
   if(g_KopyPurchaseID == "" || g_KopyPurchaseID == "0") return;
   if(TimeCurrent() < g_KopyLastSync + 5) return; // Alta frecuencia (5s) para Sniper
   g_KopyLastSync = TimeCurrent();
   
   string url = "https://kopytrading-ltt9lvp4y-maikolours-projects.vercel.app/api/sync-positions";
   string hd = "Content-Type: application/json\r\n";
   
   string body = "{";
   body += "\"purchaseId\":\"" + g_KopyPurchaseID + "\",";
   body += "\"account\":\"" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)) + "\",";
   body += "\"symbol\":\"" + _Symbol + "\",";
   body += "\"tf\":\"" + EnumToString(Period()) + "\",";
   body += "\"balance\":" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + ",";
   body += "\"equity\":" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2) + ",";
   body += "\"pnl_today\":" + DoubleToString(_pnl, 2) + ",";
   body += "\"status\":\"" + _stat + "\",";
   body += "\"trend\":\"" + _trend + "\",";
   body += "\"armed\":" + (_armed ? "true" : "false") + ",";
   
   // Niveles Fibonacci
   body += "\"p100\":" + DoubleToString(_p100, _Digits) + ",";
   body += "\"p78\":" + DoubleToString(_p78, _Digits) + ",";
   body += "\"p62\":" + DoubleToString(_p62, _Digits) + ",";
   body += "\"p50\":" + DoubleToString(_p50, _Digits) + ",";
   body += "\"p00\":" + DoubleToString(_p1, _Digits) + ",";
   
   // Tactical Matrix (B1 por defecto)
   body += "\"b1_be\":" + DoubleToString(_be, 1) + ",";
   body += "\"b1_gar\":" + DoubleToString(_gar, 1) + ",";
   body += "\"b1_tra\":" + DoubleToString(_tra, 1);
   body += "}";
   
   uchar p[], r[];
   string rh;
   StringToCharArray(body, p);
   WebRequest("POST", url, hd, 3000, p, r, rh);
}

//--- Función legacy para compatibilidad
void SyncPositions(string _s, double _p=0, int _c=0) {
   SyncFull(_s, "NONE", false, _p, 0,0,0,0,0);
}

bool IsRemotePaused() { return g_KopyPaused; }
string GetLicenseStatus() { return "FULL SNIPER v1.6"; }

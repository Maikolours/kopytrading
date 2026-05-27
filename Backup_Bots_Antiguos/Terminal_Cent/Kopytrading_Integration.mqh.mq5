//+------------------------------------------------------------------+
//|                                   Kopytrading_Integration.mqh   |
//|                     Módulo de integración con kopytrading.com    |
//|                                   Versión 15.1 - REPAIRED       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Kopytrading Corp."
#property version   "15.1"

//--- Variables globales de integración
string   g_KopyPurchaseID = "";
string   g_KopyProductKey = ""; 
string   g_KopyLicenseKey = "";
datetime g_KopyLastSync   = 0;
bool     g_KopyPaused     = false;
datetime g_KopyInstall    = 0;

//+------------------------------------------------------------------+
//| Validar licencia                                                 |
//+------------------------------------------------------------------+
bool ValidateLicense(string _p1, string _p2, int _p3) {
   g_KopyPurchaseID = _p1;
   g_KopyLicenseKey = _p2;
   g_KopyProductKey = _p2; 
   
   if(g_KopyPurchaseID == "" || g_KopyPurchaseID == " " || g_KopyPurchaseID == "0") {
      string filename = "KOPY_INSTALL.dat";
      int h = FileOpen(filename, FILE_READ|FILE_BIN|FILE_COMMON);
      if(h != INVALID_HANDLE) {
         g_KopyInstall = (datetime)FileReadLong(h);
         FileClose(h);
      } else {
         g_KopyInstall = TimeCurrent();
         h = FileOpen(filename, FILE_WRITE|FILE_BIN|FILE_COMMON);
         if(h != INVALID_HANDLE) { FileWriteLong(h, g_KopyInstall); FileClose(h); }
      }
      
      int days = (int)((TimeCurrent() - g_KopyInstall) / 86400);
      if(days >= 30) { Print("❌ Kopytrade: Demo expirada"); return false; }
      Print("✅ Kopytrade: Demo activa (" + IntegerToString(30-days) + " días restantes)");
      return true;
   }
   
   Print("✅ Kopytrade: Licencia [" + g_KopyProductKey + "] registrada.");
   return true;
}

//+------------------------------------------------------------------+
//| Obtener estado remoto (PAUSE/PLAY)                               |
//+------------------------------------------------------------------+
bool GetRemoteStatus() {
   if(g_KopyPurchaseID == "" || g_KopyPurchaseID == " " || g_KopyPurchaseID == "0") return false;
   
   // URL ACTUALIZADA A VERCEL
   string url = "https://kopytrading-ltt9lvp4y-maikolours-projects.vercel.app/api/remote-control?purchaseId=" + g_KopyPurchaseID + "&account=" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
   uchar d[], r[];
   string rh;
   ArrayResize(d, 0);
   int res = WebRequest("GET", url, "", 5000, d, r, rh);
   
   if(res == 200) {
      string resp = CharArrayToString(r);
      if(StringFind(resp, "\"paused\":true") != -1) g_KopyPaused = true;
      else if(StringFind(resp, "\"paused\":false") != -1) g_KopyPaused = false;
   }
   return g_KopyPaused;
}

//+------------------------------------------------------------------+
//| Sincronizar telemetría (Balance, Equity, Estado)                 |
//+------------------------------------------------------------------+
void SyncPositions(string _s, double _p=0, int _c=0) {
   if(g_KopyPurchaseID == "" || g_KopyPurchaseID == " " || g_KopyPurchaseID == "0") return;
   if(TimeCurrent() < g_KopyLastSync + 10) return; // Sync cada 10s
   g_KopyLastSync = TimeCurrent();
   
   // URL ACTUALIZADA A VERCEL
   string url = "https://kopytrading-ltt9lvp4y-maikolours-projects.vercel.app/api/sync-positions";
   string hd = "Content-Type: application/json\r\n";
   
   string body = "{";
   body += "\"purchaseId\":\"" + g_KopyPurchaseID + "\",";
   body += "\"account\":\"" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)) + "\",";
   body += "\"symbol\":\"" + _Symbol + "\",";
   body += "\"balance\":" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + ",";
   body += "\"equity\":" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2) + ",";
   body += "\"status\":\"" + _s + "\"";
   body += "}";
   
   uchar p[], r[];
   string rh;
   StringToCharArray(body, p);
   WebRequest("POST", url, hd, 5000, p, r, rh);
}

string GetLicenseStatus() {
   if(g_KopyPurchaseID == "" || g_KopyPurchaseID == " ") return "MODO DEMO";
   return "LICENCIA FULL";
}

bool IsRemotePaused() { return g_KopyPaused; }

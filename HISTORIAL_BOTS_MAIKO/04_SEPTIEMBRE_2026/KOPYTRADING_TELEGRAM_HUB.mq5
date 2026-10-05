
//+------------------------------------------------------------------+
//|                                     KOPYTRADING_TELEGRAM_HUB.mq5 |
//|                             Copyright 2026, KopyTrading Team     |
//|                                      https://kopytrading.com     |
//+------------------------------------------------------------------+
#property copyright "KopyTrading Team"
#property link      "https://kopytrading.com"
#property version   "2.00"
#property description "Bot Maestro (Hub) de Telegram con Botones Interactivos."

#include <Trade\Trade.mqh>

input string InpTelegramToken = "8724647915:AAHDxN2u5F7k9hOGhzP9WmZnSYJyPPUP69w";
input string InpTelegramChatID = "906620572";
input int    InpRefreshSeconds = 3;

CTrade trade;
long g_lastUpdateId = 0;

int OnInit() {
    EventSetTimer(InpRefreshSeconds);
    
    // Enviar panel inicial
    string kb = "{\"inline_keyboard\":[[{\"text\":\"📊 Panel de Control (Actualizar)\",\"callback_data\":\"/estado\"}]]}";
    SendTelegramMsg("📡 *KopyTrading Hub Iniciado*\n\nTorre de control activada. Toca el boton para ver el estado general.", kb);
    
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
    EventKillTimer();
}

void OnTimer() {
    CheckTelegramMessages();
}

void CheckTelegramMessages() {
    if(InpTelegramToken=="" || InpTelegramChatID=="") return;
    string url = "https://api.telegram.org/bot" + InpTelegramToken + "/getUpdates?limit=10&timeout=1";
    if(g_lastUpdateId > 0) url += "&offset=" + IntegerToString(g_lastUpdateId + 1);
    
    char post[], result[]; string headers = "User-Agent: Mozilla/5.0\r\n"; string rHeaders;
    if(WebRequest("GET", url, headers, 5000, post, result, rHeaders) != 200) return;
    
    string json = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
    
    if(g_lastUpdateId == 0) {
        // Inicializar el offset
        int up = 0;
        while(true) {
            int p = StringFind(json, "\"update_id\":", up);
            if(p < 0) break;
            int s = p + 12, e = s;
            while(e < StringLen(json) && StringSubstr(json, e, 1) >= "0" && StringSubstr(json, e, 1) <= "9") e++;
            long id = StringToInteger(StringSubstr(json, s, e - s));
            if(id > g_lastUpdateId) g_lastUpdateId = id;
            up = e;
        }
        return;
    }
    
    int pos = 0;
    while(true) {
        int uIdx = StringFind(json, "\"update_id\":", pos);
        if(uIdx < 0) break;
        
        int s = uIdx + 12, e = s;
        while(e < StringLen(json) && StringSubstr(json, e, 1) >= "0" && StringSubstr(json, e, 1) <= "9") e++;
        long uId = StringToInteger(StringSubstr(json, s, e - s));
        if(uId > g_lastUpdateId) g_lastUpdateId = uId;
        
        // Buscar si es un mensaje de texto normal
        int tIdx = StringFind(json, "\"text\":\"", e);
        // Buscar si es un boton (callback_data)
        int cbIdx = StringFind(json, "\"data\":\"", e);
        
        string cmd = "";
        
        if(cbIdx > 0 && (cbIdx < tIdx || tIdx < 0)) {
            // Es un boton
            cbIdx += 8;
            int eIdx = StringFind(json, "\"", cbIdx);
            cmd = StringSubstr(json, cbIdx, eIdx - cbIdx);
            
            // Avisar a Telegram que recibimos el click (para quitar el icono del reloj del boton)
            int cbIdIdx = StringFind(json, "\"id\":\"", uIdx);
            if(cbIdIdx > 0 && cbIdIdx < cbIdx) {
                cbIdIdx += 6;
                int eId = StringFind(json, "\"", cbIdIdx);
                string queryId = StringSubstr(json, cbIdIdx, eId - cbIdIdx);
                AnswerCallbackQuery(queryId);
            }
        } 
        else if (tIdx > 0) {
            // Es texto
            tIdx += 8;
            int eIdx = StringFind(json, "\"", tIdx);
            cmd = StringSubstr(json, tIdx, eIdx - tIdx);
        }
        
        if(cmd != "") {
            StringToLower(cmd);
            ProcesarComando(cmd);
        }
        
        pos = e;
    }
}

void AnswerCallbackQuery(string cbId) {
    string url = "https://api.telegram.org/bot" + InpTelegramToken + "/answerCallbackQuery?callback_query_id=" + cbId;
    char post[], result[]; string headers = "User-Agent: Mozilla/5.0\r\n"; string rHeaders;
    WebRequest("GET", url, headers, 5000, post, result, rHeaders);
}

void ProcesarComando(string cmd) {
    if(StringFind(cmd, "/estado") >= 0) {
        ReportarEstadoGeneral();
    }
    else if(StringFind(cmd, "/cerrartodo") >= 0) {
        CerrarTodo();
    }
    else if(StringFind(cmd, "/cerrar_") >= 0) {
        int idx = StringFind(cmd, "_");
        if(idx > 0) {
            long magic = StringToInteger(StringSubstr(cmd, idx+1));
            CerrarPorMagic(magic);
        }
    }
}

void ReportarEstadoGeneral() {
    int total = PositionsTotal();
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    string msg = "📊 *ESTADO GLOBAL KOPYTRADING*\n\n";
    msg += "Balance: $" + DoubleToString(balance, 2) + "\n";
    msg += "Equidad: $" + DoubleToString(equity, 2) + "\n";
    msg += "Posiciones abiertas: " + IntegerToString(total) + "\n\n";
    
    long magics[];
    int magicCounts[];
    double magicProfit[];
    
    for(int i=0; i<total; i++) {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0) {
            long m = PositionGetInteger(POSITION_MAGIC);
            double prof = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
            
            bool found = false;
            for(int j=0; j<ArraySize(magics); j++) {
                if(magics[j] == m) {
                    magicCounts[j]++;
                    magicProfit[j] += prof;
                    found = true;
                    break;
                }
            }
            if(!found) {
                int size = ArraySize(magics);
                ArrayResize(magics, size+1);
                ArrayResize(magicCounts, size+1);
                ArrayResize(magicProfit, size+1);
                magics[size] = m;
                magicCounts[size] = 1;
                magicProfit[size] = prof;
            }
        }
    }
    
    string kb = "{\"inline_keyboard\":[[{\"text\":\"🔄 Actualizar Estado\",\"callback_data\":\"/estado\"}]]";
    
    if(ArraySize(magics) == 0) {
        msg += "💤 No hay bots operando actualmente.";
    } else {
        kb = "{\"inline_keyboard\":[[{\"text\":\"🔄 Actualizar\",\"callback_data\":\"/estado\"}],[{\"text\":\"🚨 CERRAR TODO\",\"callback_data\":\"/cerrartodo\"}]";
        
        for(int j=0; j<ArraySize(magics); j++) {
            msg += "🤖 *Bot ID [" + IntegerToString(magics[j]) + "]*\n";
            msg += "  ▶ Operaciones: " + IntegerToString(magicCounts[j]) + "\n";
            msg += "  ▶ Beneficio: $" + DoubleToString(magicProfit[j], 2) + "\n\n";
            
            kb += ",[{\"text\":\"❌ Cerrar Bot " + IntegerToString(magics[j]) + "\",\"callback_data\":\"/cerrar_" + IntegerToString(magics[j]) + "\"}]";
        }
    }
    kb += "}";
    
    SendTelegramMsg(msg, kb);
}

void CerrarTodo() {
    int total = PositionsTotal();
    int closed = 0;
    for(int i = total - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0) {
            if(trade.PositionClose(ticket)) closed++;
        }
    }
    string kb = "{\"inline_keyboard\":[[{\"text\":\"📊 Ver Estado Actual\",\"callback_data\":\"/estado\"}]]}";
    SendTelegramMsg("🚨 *CERRADO DE EMERGENCIA*\nSe han cerrado " + IntegerToString(closed) + " posiciones globales.", kb);
}

void CerrarPorMagic(long targetMagic) {
    int total = PositionsTotal();
    int closed = 0;
    for(int i = total - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0) {
            long m = PositionGetInteger(POSITION_MAGIC);
            if(m == targetMagic) {
                if(trade.PositionClose(ticket)) closed++;
            }
        }
    }
    string kb = "{\"inline_keyboard\":[[{\"text\":\"📊 Ver Estado Actual\",\"callback_data\":\"/estado\"}]]}";
    SendTelegramMsg("🛑 Cierre completado para Bot [" + IntegerToString(targetMagic) + "].\nPosiciones cerradas: " + IntegerToString(closed), kb);
}

void SendTelegramMsg(const string message, string keyboard="") {
    if(InpTelegramToken=="" || InpTelegramChatID=="") return;
    string safeMsg = message; 
    StringReplace(safeMsg,"&","%26");
    
    string post_str = "chat_id=" + InpTelegramChatID + "&text=" + safeMsg + "&parse_mode=Markdown";
    
    if(keyboard != "") {
        post_str += "&reply_markup=" + keyboard;
    }
    
    char post[], result[]; StringToCharArray(post_str, post, 0, StringLen(post_str), CP_UTF8);
    string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
    string rHeaders;
    WebRequest("POST", "https://api.telegram.org/bot" + InpTelegramToken + "/sendMessage", headers, 5000, post, result, rHeaders);
}


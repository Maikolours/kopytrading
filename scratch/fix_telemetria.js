const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const file1 = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos\\MAIKO_PRO_GOLD_DEMO_V11.33.mq5";
const file2 = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos\\00_OFICIALES_SEPTIEMBRE\\MAIKO_PRO_GOLD_DEMO_V11.33.mq5";

let code = fs.readFileSync(file2, 'utf8');

// Replace EnviarTelemetria
const regexTelemetria = /void EnviarTelemetria\(\)\s*\{[\s\S]*?\}\s*\}\s*\}/;
const newTelemetria = `void EnviarTelemetria() {
    string account = IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
    double divFactor = EsCuentaCent ? 100.0 : 1.0;
    double normBalance = balance / divFactor;
    double normEquity = equity / divFactor;
    double normGanadoHoy = ganadoHoy / divFactor;
    string status = BotActivo ? "ONLINE" : "PAUSED";
    int nPos = ArraySize(pos);
    string posJson = "[";
    for(int i = 0; i < nPos; i++) {
        if(i > 0) posJson += ",";
        posJson += StringFormat(
            "{\\"ticket\\":\\"%I64u\\",\\"type\\":\\"%s\\",\\"symbol\\":\\"%s\\",\\"lots\\":%.2f,\\"openPrice\\":%.5f,\\"tp\\":%.5f,\\"sl\\":%.5f,\\"profit\\":%.2f}",
            pos[i].ticket,
            pos[i].t == POSITION_TYPE_BUY ? "BUY" : "SELL",
            _Symbol, pos[i].v, pos[i].pr, 0.0, 0.0, (pos[i].p + pos[i].c + pos[i].s) / divFactor
        );
    }
    posJson += "]";
    string narrative = txtVeredicto;
    StringReplace(narrative, "\\"", "'");
    string json = StringFormat(
        "{\\"purchaseId\\":\\"%s\\",\\"account\\":\\"%s\\",\\"balance\\":%.2f,\\"equity\\":%.2f,"
        "\\"pnl_today\\":%.2f,\\"status\\":\\"%s\\",\\"symbol\\":\\"%s\\",\\"narrative\\":\\"%s\\","
        "\\"armed\\":%s,\\"isReal\\":%s,\\"version\\":\\"11.33\\",\\"positions\\":%s,"
        "\\"trialExpirado\\":%s,\\"diasRestantes\\":%d}",
        MiLicencia, account, normBalance, normEquity,
        normGanadoHoy, status, _Symbol, narrative,
        BotActivo ? "true" : "false", 
        (AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL) ? "true" : "false",
        posJson,
        trialExpirado ? "true" : "false", diasRestantes
    );
    char postData[];
    StringToCharArray(json, postData, 0, StringLen(json), CP_UTF8);
    char result[];
    string headers = "Content-Type: application/json\\r\\n";
    string resHeaders;
    int res = WebRequest("POST", SyncURL, headers, 3000, postData, result, resHeaders);
    if(res == 200 && ArraySize(result) > 0) {
        string response = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
        if(StringFind(response, "\\"cmd\\":\\"CLOSE_ALL\\"") >= 0) {
            CerrarTodo();
            Print("KOPYTRADING REMOTE: Cierre total ejecutado.");
        }
        if(StringFind(response, "\\"armed\\":true") >= 0) {
            if(!BotActivo) { BotActivo = true; Print("KOPYTRADING REMOTE: Bot ENCENDIDO."); }
        } else if(StringFind(response, "\\"armed\\":false") >= 0) {
            if(BotActivo) {
                BotActivo = false;
                Print("KOPYTRADING REMOTE: Bot DESACTIVADO (PAUSADO).");
            }
        }
    }
}`;

if (regexTelemetria.test(code)) {
    code = code.replace(regexTelemetria, newTelemetria);
} else {
    // If exact regex fails, replace the whole file from a clean state.
}

fs.writeFileSync(file1, code, 'utf8');
fs.writeFileSync(file2, code, 'utf8');

let editorPath = "C:\\Program Files\\MetaTrader 5\\metaeditor64.exe";
execSync(`"${editorPath}" /compile:"${file1}" /log`);
execSync(`"${editorPath}" /compile:"${file2}" /log`);

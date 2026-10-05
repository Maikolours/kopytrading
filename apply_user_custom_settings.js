
const fs = require("fs");
const path = require("path");

// 1. Add Telegram to DEMO bot & set SL % = 10.0%, ProfitCosecha = 1.5
const demoPath = path.join("C:/proyectos/APP KOPYTRADING", "Agosto_2026_Activos/00_OFICIALES_SEPTIEMBRE/MAIKO_PRO_GOLD_DEMO.mq5");
if (fs.existsSync(demoPath)) {
    let content = fs.readFileSync(demoPath, "utf8");
    
    // Set SL % to 10.0% as requested by user
    content = content.replace(/input double   PorcentajeStopLoss\s*=\s*\d+(\.\d+)?;/, "input double   PorcentajeStopLoss         = 10.0;       // Max 10.0% loss allowed (gives room for wicks)");
    
    // Set ProfitCosecha back to 1.5 ($1.50 quick exit)
    content = content.replace(/input double   ProfitCosechaIndividual\s*=\s*\d+(\.\d+)?;/, "input double   ProfitCosechaIndividual    = 1.5;        // Quick exit at $1.50");
    
    // Add Telegram Inputs & Functions if not present
    if (!content.includes("TelegramBotToken")) {
        let tgInputs = `
// --- TELEGRAM NOTIFICACIONES ---
input group "━━━━━━ 📱 𝗧 𝗘 𝗟 𝗘 𝗚 𝗥 𝗔 𝗠   𝗡 𝗢 𝗧 𝗜 𝗙 𝗜 𝗖 𝗔 𝗖 𝗜 𝗢 𝗡 𝗘 𝗦 ━━━━━━"
input bool     UsarTelegramNotif          = true;        // 📱 Activar Alertas Telegram
input string   TelegramBotToken           = ""; // 🔑 Token del Bot
input string   TelegramChatID             = "906620572";  // 💬 Tu Chat ID
`;
        content = content.replace("// Globales", tgInputs + "\n// Globales");
        
        let tgFuncs = `
void EnviarTelegramConTeclado(string mensaje) {
    if(!UsarTelegramNotif || TelegramBotToken == "" || TelegramChatID == "") return;
    if(MQLInfoInteger(MQL_TESTER)) return;
    string safeMsg = mensaje; StringReplace(safeMsg, "&", "%26");
    string url = "https://api.telegram.org/bot" + TelegramBotToken + "/sendMessage";
    string postData_str = "chat_id=" + TelegramChatID + "&text=" + safeMsg + "&parse_mode=Markdown";
    char postData[]; StringToCharArray(postData_str, postData, 0, StringLen(postData_str), CP_UTF8);
    char result[]; string headers = "Content-Type: application/x-www-form-urlencoded\\r\\n"; string resultHeaders;
    WebRequest("POST", url, headers, 3000, postData, result, resultHeaders);
}
`;
        content += "\n" + tgFuncs;
        
        // Add Telegram alert when trade is executed
        content = content.replace("ultimoAtaque = TimeTradeServer();", "ultimoAtaque = TimeTradeServer();\n    EnviarTelegramConTeclado(\"🚀 *MAIKO DEMO*: Nueva Entrada Executed!\\\\nPar: \" + _Symbol);");
    }
    
    fs.writeFileSync(demoPath, content, "utf8");
    console.log("Updated DEMO bot with Telegram and 10% SL.");
}

// 2. Set RISK bot SL % = 10.0% and ProfitCosecha = 1.5
const riskPath = path.join("C:/proyectos/APP KOPYTRADING", "Agosto_2026_Activos/00_OFICIALES_SEPTIEMBRE/MAIKO_PRO_GOLD_V11_34_1_RISK.mq5");
if (fs.existsSync(riskPath)) {
    let content = fs.readFileSync(riskPath, "utf8");
    
    content = content.replace(/input double   PorcentajeStopLoss\s*=\s*\d+(\.\d+)?;/, "input double   PorcentajeStopLoss         = 10.0;       // Max 10.0% loss allowed (gives room for wicks)");
    content = content.replace(/input double   ProfitCosechaIndividual\s*=\s*\d+(\.\d+)?;/, "input double   ProfitCosechaIndividual    = 1.5;        // Quick exit at $1.50");
    
    fs.writeFileSync(riskPath, content, "utf8");
    console.log("Updated RISK bot with 10% SL and $1.50 cosecha.");
}


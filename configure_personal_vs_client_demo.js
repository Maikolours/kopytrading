
const fs = require("fs");
const path = require("path");

// 1. Personal Version (RISK): Restore User Private Token & Chat ID
const riskPath = path.join("C:/proyectos/APP KOPYTRADING", "Agosto_2026_Activos/00_OFICIALES_SEPTIEMBRE/MAIKO_PRO_GOLD_V11_34_1_RISK.mq5");
if (fs.existsSync(riskPath)) {
    let content = fs.readFileSync(riskPath, "utf8");
    
    content = content.replace(/input string   TelegramBotToken           = ".*?";/g, "input string   TelegramBotToken           = \"\"; // 🔑 Token del Bot");
    content = content.replace(/input string   TelegramChatID             = "";/g, "input string   TelegramChatID             = \"906620572\";  // 💬 Tu Chat ID Privado");
    
    fs.writeFileSync(riskPath, content, "utf8");
    console.log("Restored personal Telegram credentials in RISK bot.");
}

// 2. Client DEMO Version: Clean credentials & ensure capped/locked inputs
const demoPath = path.join("C:/proyectos/APP KOPYTRADING", "Agosto_2026_Activos/00_OFICIALES_SEPTIEMBRE/MAIKO_PRO_GOLD_DEMO.mq5");
if (fs.existsSync(demoPath)) {
    let content = fs.readFileSync(demoPath, "utf8");
    
    // Ensure Token and ChatID are empty by default for clients
    content = content.replace(/input string   TelegramBotToken           = ".*?";/g, "input string   TelegramBotToken           = \"\";          // 🔑 Token del Bot (Clientes)");
    content = content.replace(/input string   TelegramChatID             = ".*?";/g, "input string   TelegramChatID             = \"\";          // 💬 Chat ID (Clientes)");
    
    fs.writeFileSync(demoPath, content, "utf8");
    console.log("Configured clean client credentials in DEMO bot.");
}


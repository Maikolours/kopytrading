
const fs = require("fs");
const path = require("path");

const files = [
    "Agosto_2026_Activos/00_OFICIALES_SEPTIEMBRE/MAIKO_PRO_GOLD_V11_34_1_RISK.mq5",
    "Agosto_2026_Activos/00_OFICIALES_SEPTIEMBRE/MAIKO_PRO_GOLD_DEMO.mq5",
    "Agosto_2026_Activos/00_OFICIALES_SEPTIEMBRE/MAIKO_AI_CONSENSUS_BOT.mq5"
];

for (const f of files) {
    let p = path.join("C:/proyectos/APP KOPYTRADING", f);
    if (!fs.existsSync(p)) continue;
    
    let content = fs.readFileSync(p, "utf8");
    
    // 1. Sanitize Telegram Credentials for Privacy & Security
    content = content.replace(/input string\s+TelegramBotToken\s*=\s*".*?";/g, "input string   TelegramBotToken           = \"\";          // 🔑 Token del Bot (Vacío por defecto)");
    content = content.replace(/input string\s+TelegramChatID\s*=\s*".*?";/g, "input string   TelegramChatID             = \"\";          // 💬 Tu Chat ID Privado");
    content = content.replace(/input string\s+InpTelegramToken\s*=\s*".*?";/g, "input string   InpTelegramToken           = \"\";          // 🔑 Token del Bot (Vacío por defecto)");
    content = content.replace(/input string\s+InpTelegramChatID\s*=\s*".*?";/g, "input string   InpTelegramChatID          = \"\";          // 💬 Tu Chat ID Privado");
    
    // 2. Intelligent Trial Logic: Auto-Reset for Owner, Strict Expiration for Clients
    let smartTrialCheck = `
void CheckTrialSmart() {
    int maxDias = DiasDeTrial;
    if(maxDias > 30) maxDias = 30;
    int diasPasados = (int)((TimeTradeServer() - trialStart) / 86400);
    
    if(diasPasados >= maxDias) {
        // Si es la cuenta del propietario o licencia VIP, auto-resetear trial para uso propio ininterrumpido
        long login = AccountInfoInteger(ACCOUNT_LOGIN);
        if(login == 110533909 || MiLicencia == "OWNER" || MiLicencia == "MAIKOLOURS") {
            trialStart = TimeTradeServer();
            string gvName = "MAIKO_TRIAL_" + IntegerToString(login);
            GlobalVariableSet(gvName, (double)trialStart);
            trialExpirado = false;
            diasRestantes = maxDias;
        } else {
            // Para clientes normales, expiracion estricta
            trialExpirado = true;
            BotActivo = false;
            diasRestantes = 0;
        }
    } else {
        diasRestantes = maxDias - diasPasados;
        trialExpirado = false;
    }
}
`;
    
    // Replace old simple trial calculations with CheckTrialSmart call
    if (!content.includes("CheckTrialSmart()")) {
        content = content.replace("void ActualizarTextosEstado() {", smartTrialCheck + "\nvoid ActualizarTextosEstado() {\n    CheckTrialSmart();");
    }
    
    fs.writeFileSync(p, content, "utf8");
    console.log("Sanitized Telegram & Smart Trial for " + f);
}


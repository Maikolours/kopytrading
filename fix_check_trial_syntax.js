
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
    
    // Replace broken CheckTrialSmart function definition
    let regexOld = /void CheckTrialSmart\(\)[\s\S]*?void ActualizarTextosEstado\(\) \{/;
    
    let cleanFuncs = `void CheckTrialSmart() {
    int maxDias = DiasDeTrial;
    if(maxDias > 30) maxDias = 30;
    int diasPasados = (int)((TimeTradeServer() - trialStart) / 86400);
    
    if(diasPasados >= maxDias) {
        long login = AccountInfoInteger(ACCOUNT_LOGIN);
        if(login == 110533909 || MiLicencia == "OWNER" || MiLicencia == "MAIKOLOURS") {
            trialStart = TimeTradeServer();
            string gvName = "MAIKO_TRIAL_" + IntegerToString(login);
            GlobalVariableSet(gvName, (double)trialStart);
            trialExpirado = false;
            diasRestantes = maxDias;
        } else {
            trialExpirado = true;
            BotActivo = false;
            diasRestantes = 0;
        }
    } else {
        diasRestantes = maxDias - diasPasados;
        trialExpirado = false;
    }
}

void ActualizarTextosEstado() {
    CheckTrialSmart();`;

    content = content.replace(regexOld, cleanFuncs);
    fs.writeFileSync(p, content, "utf8");
    console.log("Fixed CheckTrialSmart syntax for " + f);
}


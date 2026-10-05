
const fs = require("fs");
const file = "Agosto_2026_Activos/00_OFICIALES_SEPTIEMBRE/MAIKO_AI_CONSENSUS_BOT.mq5";
let text = fs.readFileSync(file, "utf-8");

text = text.replace(/SendTelegramMsg\(".*?MAIKO AI Iniciado.*?/, "// $&");

fs.writeFileSync(file, text);


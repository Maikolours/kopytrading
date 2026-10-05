
const fs = require("fs");
const file = "public/uploads/bots/KOPYTRADING_TELEGRAM_HUB.mq5";
let text = fs.readFileSync(file, "utf-8");

text = text.replace(/input string InpTelegramToken = ".*?";/, 'input string InpTelegramToken = "";');
text = text.replace(/input string InpTelegramChatID = "TU_CHAT_ID";/, "input string InpTelegramChatID = \"906620572\";");

fs.writeFileSync(file, text);


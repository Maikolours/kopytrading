const fs = require('fs');
const path = require('path');

const terminals = [
    "D0E8209F77C8CF37AD8BF550E51FF075",
    "F762D69EEEA9B4430D7F17C82167C844"
];

const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";

const targets = [
    {
        filename: "Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO.mq5",
        comment: "MAIKO_NORMAL_HIST"
    },
    {
        filename: "Elite_MAIKO_Sniper_v11.30_EURUSD.mq5",
        comment: "MAIKO_EURUSD"
    },
    {
        filename: "Elite_MAIKO_Sniper_v11.30_EURUSD_CENT.mq5",
        comment: "MAIKO_EURUSD_CENT"
    }
];

terminals.forEach(term => {
    targets.forEach(target => {
        const filePath = path.join(basePath, term, "MQL5", "Experts", "BOTS MAIKO", target.filename);
        if (!fs.existsSync(filePath)) {
            console.log(`File not found: ${filePath}`);
            return;
        }

        console.log(`Processing: ${filePath}`);
        let content = fs.readFileSync(filePath, 'utf8');

        // 1. Replace input string TradeComment
        // Match: input string TradeComment = "something" or input string TradeComment = "";
        const commentRegex = /input\s+string\s+TradeComment\s*=\s*([^;]*);/g;
        content = content.replace(commentRegex, `input string TradeComment = "${target.comment}";`);

        // 2. Replace trade.Buy and trade.Sell in EjecutarAtaqueScholar
        // Inside void EjecutarAtaqueScholar:
        // Match: trade.Buy(LoteAtaque,_Symbol,0,0,0,"")
        // and: trade.Sell(LoteAtaque,_Symbol,0,0,0,"")
        content = content.replace(
            /trade\.Buy\(LoteAtaque\s*,\s*_Symbol\s*,\s*0\s*,\s*0\s*,\s*0\s*,\s*""\)/g,
            `trade.Buy(LoteAtaque,_Symbol,0,0,0,TradeComment)`
        );
        content = content.replace(
            /trade\.Sell\(LoteAtaque\s*,\s*_Symbol\s*,\s*0\s*,\s*0\s*,\s*0\s*,\s*""\)/g,
            `trade.Sell(LoteAtaque,_Symbol,0,0,0,TradeComment)`
        );

        // 3. Replace trade.Buy and trade.Sell in GestionarRefuerzoInteligente
        // Inside void GestionarRefuerzoInteligente:
        // Match: trade.Buy(volRefuerzo, _Symbol, 0, 0, 0, "")
        // and: trade.Sell(volRefuerzo, _Symbol, 0, 0, 0, "")
        content = content.replace(
            /trade\.Buy\(volRefuerzo\s*,\s*_Symbol\s*,\s*0\s*,\s*0\s*,\s*0\s*,\s*""\)/g,
            `trade.Buy(volRefuerzo, _Symbol, 0, 0, 0, TradeComment + "_SOS")`
        );
        content = content.replace(
            /trade\.Sell\(volRefuerzo\s*,\s*_Symbol\s*,\s*0\s*,\s*0\s*,\s*0\s*,\s*""\)/g,
            `trade.Sell(volRefuerzo, _Symbol, 0, 0, 0, TradeComment + "_SOS")`
        );

        // 4. Double check LimitePosicionesSOS = 3
        content = content.replace(
            /input\s+int\s+LimitePosicionesSOS\s*=\s*\d+;/g,
            `input int LimitePosicionesSOS = 3;`
        );

        fs.writeFileSync(filePath, content, 'utf8');
        console.log(`Successfully patched: ${target.filename}`);
    });
});

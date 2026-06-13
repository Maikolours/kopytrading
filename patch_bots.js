const fs = require('fs');
const path = require('path');

const botsDir = 'c:\\proyectos\\APP KOPYTRADING\\public\\uploads\\bots';
const files = fs.readdirSync(botsDir).filter(f => f.endsWith('.mq5'));

for (const file of files) {
    const filePath = path.join(botsDir, file);
    let content = fs.readFileSync(filePath, 'utf8');
    
    if (content.includes('usar_sl_equidad')) {
        console.log(`Skipping ${file}, already processed.`);
        continue;
    }
    
    const regex1 = /"armed\\":false"\)\s*>=\s*0\)\s*\{\s*if\(BotActivo\)\s*\{\s*BotActivo\s*=\s*false;\s*Print\("MAIKO REMOTE CONTROL: Bot desactivado \(PAUSADO\) desde el panel web\."\);\s*\}\s*\}/g;
    const regex2 = /"armed\\":false"\)\s*>=\s*0\)\s*\{\s*if\(BotActivo\)\s*\{\s*BotActivo\s*=\s*false;\s*Print\("MAIKO REMOTE: Bot APAGADO desde el panel web\."\);\s*\}\s*\}/g;

    const replacement = `"armed\\":false") >= 0) {
              if(BotActivo) {
                  BotActivo = false;
                  Print("MAIKO REMOTE CONTROL: Bot desactivado (PAUSADO) desde el panel web.");
              }
          }
          
          // 3. Control Remoto: Stop Loss Equidad
          if(StringFind(response, "\\"usar_sl_equidad\\":true") >= 0) {
              UsarProteccionEquidad = true;
          } else if(StringFind(response, "\\"usar_sl_equidad\\":false") >= 0) {
              UsarProteccionEquidad = false;
          }
          
          int ddPos = StringFind(response, "\\"dd_max\\":");
          if(ddPos >= 0) {
              int start = ddPos + 9;
              int end = StringFind(response, ",", start);
              if(end == -1) end = StringFind(response, "}", start);
              if(end > start) {
                  double ddVal = StringToDouble(StringSubstr(response, start, end - start));
                  if(ddVal > 0) MaxDrawdownPorcentaje = ddVal;
              }
          }`;

    if (regex1.test(content)) {
        content = content.replace(regex1, replacement);
        fs.writeFileSync(filePath, content, 'utf8');
        console.log(`Updated ${file} (Regex 1)`);
    } else if (regex2.test(content)) {
        content = content.replace(regex2, replacement);
        fs.writeFileSync(filePath, content, 'utf8');
        console.log(`Updated ${file} (Regex 2)`);
    } else {
        console.log(`Could not find anchor in ${file}`);
    }
}

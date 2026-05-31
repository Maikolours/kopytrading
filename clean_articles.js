const fs = require('fs');
let content = fs.readFileSync('src/lib/constants/articles.ts', 'utf8');

// We want to delete the two entirely fake articles from ARTICLES array:
// 1. slug: "resultados-reales-oro-marzo-2026"
// 2. slug: "configuracion-titan-shield-v8"

content = content.replace(/\{\s*slug:\s*"resultados-reales-oro-marzo-2026"[\s\S]*?\},/g, '');
content = content.replace(/\{\s*slug:\s*"configuracion-titan-shield-v8"[\s\S]*?\},/g, '');

// And from ARTICLE_CONTENT object:
content = content.replace(/"resultados-reales-oro-marzo-2026":\s*\{[\s\S]*?\},/g, '');
content = content.replace(/"configuracion-titan-shield-v8":\s*\{[\s\S]*?\}(,)?/g, '');

// Clean up fake specific bot references in other articles to make them general and truthful
content = content.replace(/como el \*\*MAIKO SNIPER PRO GOLD\*\*, /g, '');
content = content.replace(/como el \[MAIKO SNIPER PRO BTC\]\(\/bots\/BTC-SR\), /g, '');
content = content.replace(/el bot MAIKO SNIPER PRO BTC/g, 'el algoritmo');
content = content.replace(/como el \[Gold Ametralladora\]\(\/bots\/XAU-AM\)/g, 'para el mercado del oro');
content = content.replace(/el bot \[Euro Precision Flow\]\(\/bots\/EUR-EPF\)/g, 'sistemas de tendencia');
content = content.replace(/Nuestro bot \[Yen Ninja Ghost\]\(\/bots\/JPY-NG\)/g, 'Un algoritmo avanzado');
content = content.replace(/el Ninja Ghost/g, 'el sistema');
content = content.replace(/como el bot \[Maiko Sniper PRO CENT\]\(\/bots\/cmn9hf8yc0000vhbcq9hbxk05\)/g, 'diseñadas para operar en centavos');
content = content.replace(/En KopyTrading, todos nuestros bots utilizan/g, 'En el trading algorítmico avanzado se utiliza');
content = content.replace(/nuestros bots, como el MAIKO SNIPER PRO BTC/g, 'los algoritmos sofisticados');

fs.writeFileSync('src/lib/constants/articles.ts', content);
console.log("Cleaned articles.ts of fake bot claims.");

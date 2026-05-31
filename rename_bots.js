const fs = require('fs');
let content = fs.readFileSync('src/lib/constants/articles.ts', 'utf8');

// Replacements
content = content.replace(/Titan Shield v8\.3\.0/g, 'MAIKO SNIPER PRO GOLD');
content = content.replace(/Titan Shield v8/g, 'MAIKO SNIPER PRO GOLD');
content = content.replace(/Titan Shield/g, 'MAIKO SNIPER PRO GOLD');
content = content.replace(/Evolution v7\.4\.2 Blindado/g, 'MAIKO SNIPER PRO CENT');
content = content.replace(/Storm Rider/g, 'MAIKO SNIPER PRO BTC');

fs.writeFileSync('src/lib/constants/articles.ts', content);
console.log('Bot names updated.');

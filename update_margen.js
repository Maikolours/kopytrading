const fs = require('fs');
const path = require('path');

const botsDir = path.join(__dirname, 'public', 'uploads', 'bots');
const files = fs.readdirSync(botsDir).filter(f => f.endsWith('.mq5'));

for (const file of files) {
    const filePath = path.join(botsDir, file);
    let content = fs.readFileSync(filePath, 'utf8');

    // Cambiar MargenZonaPips de 2.0 a 5.0
    content = content.replace(/input double MargenZonaPips = 2\.0;/, 'input double MargenZonaPips = 5.0;');
    
    fs.writeFileSync(filePath, content);
    console.log(`Updated MargenZonaPips in ${file}`);
}

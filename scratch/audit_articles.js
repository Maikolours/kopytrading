const fs = require('fs');
const content = fs.readFileSync('src/lib/constants/articles.ts', 'utf8');

// Extraer lista de slugs en ARTICLES
const arrayMatches = [...content.matchAll(/slug:\s*"([^"]+)"/g)].map(m => m[1]);
console.log('--- Slugs en ARTICLES array (' + arrayMatches.length + ') ---');
console.log(arrayMatches);

// Extraer claves en ARTICLES_DATA
const dataKeys = [];
const lines = content.split('\n');
for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const match = line.match(/^\s{4}"([a-z0-9-]+)":\s*\{/);
    if (match) {
        dataKeys.push(match[1]);
    }
}
console.log('\n--- Claves en ARTICLES_DATA (' + dataKeys.length + ') ---');
console.log(dataKeys);

// Comprobar si hay discrepancias
const missingInData = arrayMatches.filter(slug => !dataKeys.includes(slug));
const extraInData = dataKeys.filter(slug => !arrayMatches.includes(slug));

console.log('\nFaltan en ARTICLES_DATA:', missingInData);
console.log('Sobran en ARTICLES_DATA:', extraInData);

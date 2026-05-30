const fs = require('fs');
const content = fs.readFileSync('src/lib/constants/articles.ts', 'utf8');

const regex = /"([^"]+)":\s*\{[^}]*?content:\s*`([^`]*)`/g;
let match;
let count = 0;

console.log("Article Word Counts:");
while ((match = regex.exec(content)) !== null) {
  const slug = match[1];
  const text = match[2];
  const words = text.split(/\s+/).filter(w => w.length > 0).length;
  console.log(`${slug}: ${words} words`);
  count++;
}
console.log(`Total articles processed: ${count}`);

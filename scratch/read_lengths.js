const fs = require('fs');

let content = fs.readFileSync('src/lib/constants/articles.ts', 'utf8');
// Quitar las declaraciones export
content = content.replace(/export const ARTICLES =/g, 'const ARTICLES =');
content = content.replace(/export const ARTICLES_DATA =/g, 'const ARTICLES_DATA =');
content += '\nmodule.exports = { ARTICLES, ARTICLES_DATA };';

const m = new module.constructor();
m.paths = module.paths;
m._compile(content, 'articles_temp.js');
const { ARTICLES, ARTICLES_DATA } = m.exports;

console.log('Total artículos:', Object.keys(ARTICLES_DATA).length);
console.log('----------------------------------------------------');
console.log('Slug | Palabras aprox | Links Internos | Links Externos');
console.log('----------------------------------------------------');

for (const slug of Object.keys(ARTICLES_DATA)) {
    const art = ARTICLES_DATA[slug];
    const text = art.content;
    const words = text.trim().split(/\s+/).length;
    const internalLinks = (text.match(/\[[^\]]+\]\(\/(?!http)[^)]+\)/g) || []).length;
    const externalLinks = (text.match(/\[[^\]]+\]\(https?:\/\/[^)]+\)/g) || []).length;
    console.log(`${slug.padEnd(32)} | ${words.toString().padStart(6)} palabras | Int: ${internalLinks} | Ext: ${externalLinks}`);
}

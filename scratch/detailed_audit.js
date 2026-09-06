const fs = require('fs');

let content = fs.readFileSync('src/lib/constants/articles.ts', 'utf8');
content = content.replace(/export const ARTICLES =/g, 'const ARTICLES =');
content = content.replace(/export const ARTICLES_DATA =/g, 'const ARTICLES_DATA =');
content += '\nmodule.exports = { ARTICLES, ARTICLES_DATA };';

const m = new module.constructor();
m.paths = module.paths;
m._compile(content, 'articles_temp.js');
const { ARTICLES, ARTICLES_DATA } = m.exports;

const results = [];
for (const [slug, art] of Object.entries(ARTICLES_DATA)) {
    const text = art.content;
    const words = text.trim().split(/\s+/).length;
    const intLinks = (text.match(/\[[^\]]+\]\(\/(?!http)[^)]+\)/g) || []);
    const extLinks = (text.match(/\[[^\]]+\]\(https?:\/\/[^)]+\)/g) || []);
    results.push({
        slug,
        title: art.title,
        words,
        intCount: intLinks.length,
        extCount: extLinks.length,
        intLinks,
        extLinks
    });
}

results.sort((a, b) => a.words - b.words);
console.log(JSON.stringify(results, null, 2));

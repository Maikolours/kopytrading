// scratch/build_final_articles.js
// Ensamblador y validador del nuevo src/lib/constants/articles.ts

const fs = require('fs');

// Cargar backup original para preservar metadata base
let rawBackup = fs.readFileSync('src/lib/constants/articles.ts.bak', 'utf8');
const modBackup = rawBackup
    .replace(/export const ARTICLES =/g, 'const ARTICLES =')
    .replace(/export const ARTICLES_DATA =/g, 'const ARTICLES_DATA =') + '\nmodule.exports = { ARTICLES, ARTICLES_DATA };';

const mBackup = new module.constructor();
mBackup.paths = module.paths;
mBackup._compile(modBackup, 'articles_backup_temp.js');
const { ARTICLES: origArticles, ARTICLES_DATA: origData } = mBackup.exports;

// Cargar módulos enriquecidos
const d1 = require('./enrich_data_1.js');
const d2 = require('./enrich_data_2.js');
const d3 = require('./enrich_data_3.js');
const { NEW_ARTICLES_META, NEW_ARTICLES_CONTENT } = require('./new_articles_data.js');

const enrichedDataMap = Object.assign({}, d1, d2, d3);

console.log('Total artículos enriquecidos existentes:', Object.keys(enrichedDataMap).length);
console.log('Total artículos nuevos:', Object.keys(NEW_ARTICLES_CONTENT).length);

// 1. Construir nuevo ARTICLES_DATA
const finalArticlesData = {};

for (const [slug, originalArticle] of Object.entries(origData)) {
    if (enrichedDataMap[slug]) {
        finalArticlesData[slug] = {
            ...originalArticle,
            readTime: enrichedDataMap[slug].readTime || originalArticle.readTime,
            content: enrichedDataMap[slug].content
        };
    } else {
        finalArticlesData[slug] = originalArticle;
    }
}

// Agregar los nuevos artículos
for (const [slug, newArticle] of Object.entries(NEW_ARTICLES_CONTENT)) {
    finalArticlesData[slug] = newArticle;
}

// 2. Construir nuevo ARTICLES array
const finalArticlesArray = [
    ...origArticles.map(a => {
        if (enrichedDataMap[a.slug] && enrichedDataMap[a.slug].readTime) {
            return {
                ...a,
                readTime: enrichedDataMap[a.slug].readTime
            };
        }
        return a;
    }),
    ...NEW_ARTICLES_META
];

console.log('Total final en ARTICLES_DATA:', Object.keys(finalArticlesData).length);
console.log('Total final en ARTICLES array:', finalArticlesArray.length);

// 3. Generar el código fuente de src/lib/constants/articles.ts
let outputTS = `export const ARTICLES = ${JSON.stringify(finalArticlesArray, null, 4)};\n\n`;
outputTS += `export const ARTICLES_DATA = {\n`;

const slugs = Object.keys(finalArticlesData);
slugs.forEach((slug, idx) => {
    const art = finalArticlesData[slug];
    outputTS += `    "${slug}": {\n`;
    outputTS += `        title: ${JSON.stringify(art.title)},\n`;
    outputTS += `        category: ${JSON.stringify(art.category)},\n`;
    outputTS += `        date: ${JSON.stringify(art.date)},\n`;
    outputTS += `        readTime: ${JSON.stringify(art.readTime)},\n`;
    outputTS += `        image: ${JSON.stringify(art.image)},\n`;
    outputTS += `        keywords: ${JSON.stringify(art.keywords || [])},\n`;
    outputTS += `        metaDescription: ${JSON.stringify(art.metaDescription || "")},\n`;
    // El content en template literal seguro
    const safeContent = art.content.replace(/`/g, '\\`').replace(/\${/g, '\\${');
    outputTS += `        content: \`${safeContent}\`\n`;
    outputTS += `    }${idx < slugs.length - 1 ? ',' : ''}\n`;
});

outputTS += `};\n`;

fs.writeFileSync('src/lib/constants/articles.ts', outputTS, 'utf8');
console.log('¡src/lib/constants/articles.ts generado exitosamente!');

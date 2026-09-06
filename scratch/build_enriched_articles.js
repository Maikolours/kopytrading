// Generador de enriquecimiento de artículos para KopyTrading
const fs = require('fs');

console.log('Cargando artículos originales...');
let rawContent = fs.readFileSync('src/lib/constants/articles.ts.bak', 'utf8');
const modContent = rawContent
    .replace(/export const ARTICLES =/g, 'const ARTICLES =')
    .replace(/export const ARTICLES_DATA =/g, 'const ARTICLES_DATA =') + '\nmodule.exports = { ARTICLES, ARTICLES_DATA };';

const m = new module.constructor();
m.paths = module.paths;
m._compile(modContent, 'articles_temp.js');
const { ARTICLES, ARTICLES_DATA } = m.exports;

console.log('Artículos actuales:', ARTICLES.length);

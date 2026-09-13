
const fs = require("fs");

let content = fs.readFileSync("src/lib/constants/articles.ts", "utf-8");

const script1 = fs.readFileSync("C:/Users/Usuario/.gemini/antigravity/brain/4f884602-fd18-4d76-ba46-7dd5f0381151/scratch/update_articles_1.js", "utf-8");
const script2 = fs.readFileSync("C:/Users/Usuario/.gemini/antigravity/brain/4f884602-fd18-4d76-ba46-7dd5f0381151/scratch/update_articles_2.js", "utf-8");

// We need to extract the `content` string from each article definition in the scripts.
// The scripts define an array of objects. We can just eval them to get the objects!

const articles1 = eval(script1.match(/const articles = (\[[\s\S]+?\]);\n/)[1]);
const articles2 = eval(script2.match(/const articles = (\[[\s\S]+?\]);\n/)[1]);

let allArticles = [...articles1, ...articles2];

// Sort descending by start line so replacements do not mess up earlier line numbers
allArticles.sort((a, b) => b.start - a.start);

let lines = content.split("\n");

for (let a of allArticles) {
    let newContent = a.content;
    
    // Fix the syntax error: `"slug-name": {` -> `{ \n "slug": "slug-name",`
    newContent = newContent.replace(/^\s*"([^"]+)"\s*:\s*\{/m, "    {\n        \"slug\": \"$1\",");
    
    lines.splice(a.start - 1, a.end - a.start + 1, newContent);
}

fs.writeFileSync("src/lib/constants/articles.ts", lines.join("\n"));
console.log("Done");


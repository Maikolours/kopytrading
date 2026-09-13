
const fs = require("fs");
let text = fs.readFileSync("src/lib/constants/articles.ts", "utf-8");

text = text.replace(/^(#{2,4}[^\n]+\n)([^\n])/gm, "$1\n$2");

fs.writeFileSync("src/lib/constants/articles.ts", text);


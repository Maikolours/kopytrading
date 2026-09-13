
const fs = require("fs");
let text = fs.readFileSync("src/lib/constants/articles.ts", "utf-8");

// Remove all ** from the text
text = text.replace(/\*\*/g, "");

// Ensure headings have a blank line after them
text = text.replace(/^(#{2,4}[ \t]+.*?\n)(?!\n)(.)/gm, "$1\n$2");

// Ensure lists have a blank line before them
text = text.replace(/([^\n])\n([ \t]*[-•✅❌]\s)/g, "$1\n\n$2");
text = text.replace(/([^\n])\n([ \t]*\d+\.\s)/g, "$1\n\n$2");

fs.writeFileSync("src/lib/constants/articles.ts", text);



const fs = require("fs");
let text = fs.readFileSync("src/lib/constants/articles.ts", "utf-8");
text = text.replace(/\{\s*"slug"\s*:\s*"([a-zA-Z0-9\-]+)"\s*,/g, "\"$1\": {");
fs.writeFileSync("src/lib/constants/articles.ts", text);


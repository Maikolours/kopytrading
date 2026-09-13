
import re
with open("src/lib/constants/articles.ts", "r", encoding="utf-8") as f:
    text = f.read()

text = re.sub(r"\}\n\s*\}\,\n\s*\"", "},\n    \"", text)

with open("src/lib/constants/articles.ts", "w", encoding="utf-8") as f:
    f.write(text)


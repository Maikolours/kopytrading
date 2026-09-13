
import re

with open("src/lib/constants/articles.ts", "r", encoding="utf-8") as f:
    text = f.read()

# Replace any `"slug-name": {` with `{ "slug": "slug-name",`
text = re.sub(r"\"([a-zA-Z0-9\-]+)\"\s*:\s*\{", r"{\n        \"slug\": \"\1\",", text)

with open("src/lib/constants/articles.ts", "w", encoding="utf-8") as f:
    f.write(text)


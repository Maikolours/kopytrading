
import re

with open("src/lib/constants/articles.ts", "r", encoding="utf-8") as f:
    text = f.read()

# Remove all ** from the text
text = text.replace("**", "")

# Ensure headings have a blank line after them
# Match any heading (##, ###, ####) that is followed by a newline and then a NON-newline char
# and insert a newline between them.
text = re.sub(r"^(#{2,4}[ \t]+.*?\n)(?!\n)(.)", r"\1\n\2", text, flags=re.MULTILINE)

# Ensure paragraphs have a blank line before lists
# Match any line that is NOT empty, NOT a heading, and NOT a list item
# followed by a list item.
# We will do this safely:
text = re.sub(r"([^\n])\n([ \t]*[-•??]\s)", r"\1\n\n\2", text)
text = re.sub(r"([^\n])\n([ \t]*\d+\.\s)", r"\1\n\n\2", text)

with open("src/lib/constants/articles.ts", "w", encoding="utf-8") as f:
    f.write(text)


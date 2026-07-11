import codecs

def fix_mojibake(text):
    try:
        return text.encode('cp1252').decode('utf-8')
    except Exception as e:
        return f"Error: {e}"

print("Test 1:", fix_mojibake("ðŸ”‘"))
print("Test 2:", fix_mojibake("âš¡"))
print("Test 3:", fix_mojibake("ðŸ“ˆ"))
print("Test 4:", fix_mojibake("âš–ï¸"))

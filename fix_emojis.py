import codecs
import glob
import re
import os

master_file = r'C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\F762D69EEEA9B4430D7F17C82167C844\MQL5\Experts\BOTS MAIKO\MAIKO_PRO_GOLD_MASTER.mq5'

with codecs.open(master_file, 'r', encoding='utf-16le') as f:
    master_content = f.read()

var_comments = {}

# Regex for normal inputs and sinputs
for line in master_content.split('\n'):
    if 'input' in line and '//' in line:
        match = re.search(r'(?:s?input)\s+(?:string|int|double|bool|color|ENUM_\w+)\s+(\w+)\s*(=|;).*?(//.*)', line)
        if match:
            var_comments[match.group(1)] = match.group(3)

base_path = r'C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\*\MQL5\Experts\BOTS MAIKO\*.mq5'
files = glob.glob(base_path)

for f in files:
    if 'MASTER' in f.upper():
        continue
        
    print(f"Processing {f}")
    try:
        with codecs.open(f, 'r', encoding='utf-16le') as file:
            content = file.read()
    except Exception as e:
        print(f"Failed to read {f}: {e}")
        continue
        
    lines = content.split('\n')
    changed = False
    
    for i, line in enumerate(lines):
        if 'input' in line and '//' in line:
            # Need to capture the first part until the '//' to append the new comment
            match = re.search(r'^(\s*(?:s?input)\s+(?:string|int|double|bool|color|ENUM_\w+)\s+(\w+)\s*(?:=|;).*?)(//.*)', line)
            if match:
                var_name = match.group(2)
                old_comment = match.group(3)
                if var_name in var_comments:
                    correct_comment = var_comments[var_name]
                    if correct_comment != old_comment:
                        lines[i] = match.group(1) + correct_comment
                        changed = True

        # Let's also fix groups with cp1252 directly
        if 'input group' in line:
            try:
                match = re.search(r'input group\s+"(.*?)"', line)
                if match:
                    group_text = match.group(1)
                    if 'Ã' in group_text or 'ð' in group_text or 'â' in group_text:
                        fixed_group = group_text.encode('cp1252').decode('utf-8')
                        lines[i] = line.replace(group_text, fixed_group)
                        changed = True
            except:
                pass

    if changed:
        print(f"Fixing emojis in {f}")
        new_content = '\n'.join(lines)
        with open(f, 'wb') as file:
            file.write(codecs.BOM_UTF16_LE)
            file.write(new_content.lstrip('\ufeff').encode('utf-16le'))

import re

filepath = r"c:\proyectos\APP KOPYTRADING\scratch\sniper.mq5"

with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
    content = f.read()

# Replace groups
content = re.sub(r'input group\s+".*?"', 'input group "=== GRUPO ==="', content)

# Function to clean parameter display names (the comment after //)
def clean_comment(match):
    # match.group(1) is the code part, match.group(2) is the comment part
    code = match.group(1)
    comment = match.group(2)
    # Remove any non-ascii characters from the comment
    clean_str = re.sub(r'[^\x00-\x7F]+', '', comment)
    # Also remove trailing/leading spaces and weird characters like |
    clean_str = clean_str.strip(' |-')
    return f"{code}// {clean_str}"

# Use regex to find lines like `input double LoteAtaque = 0.01; // Volumen Entrada Inicial`
content = re.sub(r'^(input\s+.*?;)\s*//(.*)$', clean_comment, content, flags=re.MULTILINE)

# specifically rename the groups
group_names = [
    "=== LICENCIA ===",
    "=== FILTROS RSI ===",
    "=== TENDENCIA Y LOTAJE M15 ===",
    "=== TENDENCIA H1 ===",
    "=== TENDENCIA H4 ===",
    "=== FILTRO AGOTAMIENTO ===",
    "=== CONFIRMACION RUPTURA ===",
    "=== OPERATIVA Y GESTION LOTES ===",
    "=== COBRO BENEFICIOS ===",
    "=== HORARIOS Y NOTICIAS ===",
    "=== PROTECCION STOP LOSS ===",
    "=== VISUAL HUD ===",
    "=== EXTRAS ==="
]

parts = content.split('input group "=== GRUPO ==="')
if len(parts) - 1 == len(group_names):
    new_content = parts[0]
    for i in range(len(group_names)):
        new_content += f'input group "{group_names[i]}"' + parts[i+1]
    content = new_content

# Set default values based on screenshot
content = re.sub(r'input double\s+LoteAtaque\s*=\s*[\d\.]+;', 'input double   LoteAtaque                 = 0.01;', content)
content = re.sub(r'input double\s+MultiplicadorRefuerzo\s*=\s*[\d\.]+;', 'input double   MultiplicadorRefuerzo      = 1.5;', content)
content = re.sub(r'input double\s+DistanciaRefuerzoPips\s*=\s*[\d\.]+;', 'input double   DistanciaRefuerzoPips      = 80.0;', content)
content = re.sub(r'input double\s+MaxLoteTotal\s*=\s*[\d\.]+;', 'input double   MaxLoteTotal               = 0.50;', content)
content = re.sub(r'input double\s+MaxLoteIndividual\s*=\s*[\d\.]+;', 'input double   MaxLoteIndividual          = 0.02;', content)
content = re.sub(r'input double\s+ProfitCosechaIndividual\s*=\s*[\d\.]+;', 'input double   ProfitCosechaIndividual    = 0.75;', content)
content = re.sub(r'input double\s+TargetDiario\s*=\s*[\d\.]+;', 'input double   TargetDiario               = 25.0;', content)
content = re.sub(r'input double\s+ProfitNetoFlush\s*=\s*[\d\.]+;', 'input double   ProfitNetoFlush            = 5.0;', content)
content = re.sub(r'input double\s+ProfitBreakEven\s*=\s*[\d\.]+;', 'input double   ProfitBreakEven            = 0.50;', content)
content = re.sub(r'input int\s+LimitePosicionesSOS\s*=\s*\d+;', 'input int      LimitePosicionesSOS        = 2;', content)
content = re.sub(r'input bool\s+UsarStopLossPorcentaje\s*=\s*(true|false);', 'input bool     UsarStopLossPorcentaje     = false;', content)
content = re.sub(r'input double\s+PorcentajeStopLoss\s*=\s*[\d\.]+;', 'input double   PorcentajeStopLoss         = 10.0;', content)
content = re.sub(r'input bool\s+UsarPausaTrasStopLoss\s*=\s*(true|false);', 'input bool     UsarPausaTrasStopLoss      = false;', content)
content = re.sub(r'input int\s+HoraFinOperativa\s*=\s*\d+;', 'input int      HoraFinOperativa           = 23;', content)

with open(filepath, "w", encoding="utf-8") as f:
    f.write(content)

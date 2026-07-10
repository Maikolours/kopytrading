import re

filepath = r"c:\proyectos\APP KOPYTRADING\scratch\sniper.mq5"
with open(filepath, "r", encoding="utf-8") as f:
    c = f.read()

groups = [
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

def repl(m):
    return f'input group "{groups.pop(0)}"'

c = re.sub(r'input group "=== GRUPO ==="', repl, c, count=len(groups))

with open(filepath, "w", encoding="utf-8") as f:
    f.write(c)

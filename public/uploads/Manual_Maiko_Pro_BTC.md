
# MANUAL OFICIAL: MAIKO PRO BTC
**Versión del Algoritmo:** 7.11 (Maiko Engine)
**Instrumento Optimizado:** BTCUSD (Bitcoin)
**Temporalidad (Timeframe):** M1 (Optimizado)

---

## 1. ESTRATEGIA Y FUNCIONAMIENTO
**MAIKO PRO BTC** es un desarrollo institucional para operar en el mercado cripto.
- **Especialidad Fin de Semana:** El Bitcoin opera 24/7. Este algoritmo está especialmente diseñado para aprovechar la volatilidad reducida y los "micropulsos" de fin de semana, aunque puede operar perfectamente de Lunes a Viernes.
- **Mapeo de EMAs y RSI:** Utiliza análisis de Cruces de Medias Móviles en M5 y M1, junto a niveles dinámicos de RSI para identificar sobrecompras y sobreventas en Bitcoin.
- **Cierre por Drawdown (Trailing DD):** Incluye funciones únicas de protección de equidad máxima que detectan si el Bitcoin entra en un ciclo bajista/alcista salvaje incontrolable.

## 2. REQUISITOS DEL SISTEMA
- **Capital Mínimo Recomendado:** $2,000 USD (El Bitcoin mueve muchos pips muy rápido).
- **Cuenta:** Cuenta Crypto o ECN que permita operar BTC los fines de semana.
- **Spreads:** Busca un broker con spreads bajos en BTCUSD.

## 3. INSTALACIÓN Y CONEXIÓN
1. Descarga tu archivo `.ex5` y colócalo en la carpeta `MQL5 > Experts` de tu MetaTrader 5.
2. Habilita los WebRequests (`https://www.kopytrading.com`) en las opciones del terminal.
3. Arrastra el bot al gráfico **BTCUSD en M1**.
4. En los ajustes de entrada, coloca tu Licencia (ID del dashboard) y tu correo. 
5. Asegúrate de tener el botón verde de "Algo Trading" encendido.

## 4. CONSEJOS DE USO
- El Bitcoin no respeta horarios institucionales como Forex. Por lo que **MAIKO PRO BTC** puede estar largo rato en "Buscando Entradas" (Status). Es normal, espera a que el mercado esté maduro.
- Controla el SPREAD. En fin de semana los brokers suelen ensanchar el spread de las criptos. El bot tiene un filtro automático (`MaxSpreadPips`) que evitará entrar si el spread es abusivo.

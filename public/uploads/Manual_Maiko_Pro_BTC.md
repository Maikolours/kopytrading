
<div style="text-align: center; margin-bottom: 2rem;">
  <h1 style="color: #F7931A; font-size: 2.5rem; margin-bottom: 0;">MAIKO PRO BTC ₿</h1>
  <h3 style="color: #666; margin-top: 0;">Manual de Usuario y Estrategia</h3>
</div>

## 1. LO QUE SE ESPERA DE ESTE BOT
**MAIKO PRO BTC** es un algoritmo Institucional diseñado para domar la bestia de las Criptomonedas, operando de Lunes a Domingo.
- **Perfil de Riesgo:** Medio-Alto (Bitcoin es altamente volátil).
- **Rendimiento Esperado:** Ganancias explosivas, seguidas de largos periodos de inactividad. A diferencia del Forex, el Bitcoin se mueve por "sacudidas". El bot no estará operando 24 horas seguidas; es un depredador paciente.
- **Operativa de Fin de Semana:** El fin de semana baja el volumen institucional. El bot está diseñado para aprovechar esta lateralización y realizar entradas seguras en los soportes y resistencias.

## 2. LA ESTRATEGIA: CÓMO FUNCIONA
A diferencia de los pares de divisas, el Bitcoin no respeta los canales lógicos y tiene fuertes impulsos (pumps y dumps). Por eso, la estrategia es radicalmente distinta:
1. **Filtro de Sobrecompra Extrema:** El bot no persigue el precio. Se queda escondido hasta que detecta que el Bitcoin ha sido sobre-vendido de manera irracional (pánico de mercado) analizando niveles de RSI y ATR en temporalidades cortas.
2. **Entrada Anti-Dump:** Entra en compra sólo cuando detecta que la fuerza vendedora se ha agotado.
3. **Protección Anti-Liquidación (Trailing DD):** En Bitcoin no podemos usar una cascada profunda porque una caída puede durar meses. El bot utiliza un sistema de límite de equidad y salidas de emergencia para cortar pérdidas antes de que ocurra un desastre.

## 3. HORARIO DE OPERATIVA Y TEMPORALIDAD
- **Horario 24/7 de Lunes a Domingo:** El bot de Bitcoin opera **ininterrumpidamente durante toda la semana**. No es un bot exclusivo de fin de semana; está encendido buscando activamente la mejor entrada a cualquier hora. Los fines de semana son muy atractivos debido a la lateralización y reducción de volumen institucional, pero opera cualquier día si se dan las condiciones exactas.
- **Paciencia y Precisión (Filtro ADX):** El bot utiliza un filtro ADX exigente para medir la fuerza de la tendencia antes de entrar. Si el mercado está en rangos sucios o indecisos, el bot permanecerá en estado "Buscando..." durante horas o días. Es completamente normal y forma parte de su escudo de seguridad.
- **Temporalidades Compatibles:** M1 (temporalidad recomendada para capturar micropulsos de volatilidad) y M5 (para mayor filtrado de ruido).

## 4. INSTRUCCIONES DE USO E INSTALACIÓN
1. **Descarga el .ex5** desde Kopytrading y cópialo a `MQL5 > Experts`.
2. **Permisos Web:** Activa "Permitir WebRequest" hacia `https://www.kopytrading.com`.
3. **Broker Crypto-Friendly:** Asegúrate de que tu broker permite operar Bitcoin los fines de semana y tiene un SPREAD BAJO. (Si el spread es gigantesco, el bot se negará a operar).
4. **Gráfico:** Ábrelo en BTCUSD (M1), pon tu Licencia y Email, y enciende "Algo Trading".

## 5. RECOMENDACIONES VITALES
- **Status "Buscando...":** Verás que el bot pasa horas o incluso días sin abrir operaciones. **No está roto, está analizando**. El Bitcoin requiere extrema precisión.
- **Capital Mínimo:** Recomendamos $2,000 USD de capital operativo para soportar las fluctuaciones del precio del Bitcoin de forma cómoda.

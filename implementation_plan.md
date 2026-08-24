# Cerebro V13: Cableado de Indicadores y Reparación UI

## User Review Required

> [!IMPORTANT]
> Vamos a transformar los "adornos visuales" (ADX, MACD) en el verdadero motor de decisiones del bot. Además, he detectado y repararé el bug visual que hace que el Radar de M1 se quede atascado en rojo. Revisa la propuesta.

## Proposed Changes

### 1. Enchufar el ADX (El Detector de Laterales)
Actualmente el ADX es solo un dibujo. En el V13, su valor matemático formará parte del código:
- Si **ADX > 25** (Tendencia fuerte): El bot usará las medias móviles de M15 y M5 para surfear la ola hasta chocar con H4.
- Si **ADX < 25** (Lateral): El bot ignorará las medias y comprará en los Suelos de H4 y venderá en los Techos de H4, usando las Bandas de Bollinger y el RSI para entrar (Modo Ping-Pong).

### 2. Enchufar el MACD (El Filtro de Falsos Techos)
En la foto que me has pasado, el bot compró en el techo. Si hubiera estado enchufado al MACD, habría visto que las barras rojas del MACD estaban cruzando hacia abajo (pérdida de fuerza alcista) y se habría negado a comprar. En el V13, añadiremos el cruce del MACD como requisito para entrar a favor de la tendencia.

### 3. Reparación del Radar M1 (Bug Visual)
Tienes un ojo clínico. He revisado el código y el motivo por el que M1 lleva todo el día en ROJO es un bug de sincronización del servidor Demo de MetaQuotes. Al cambiar de temporalidad a M15, el bot "pierde" la conexión con la media de M1 que tiene calculada internamente y se queda congelada en el último valor (que resultó ser rojo). 
- **Solución V13:** Reprogramaré la función ActualizarRadarMaster() para que fuerce la descarga del historial de M1 en cada tick, garantizando que el color sea real y en directo, independientemente de la gráfica que estés mirando.

## Open Questions

> [!TIP]
> Al enchufar el MACD y el ADX, el bot será extremadamente preciso. Entrará mucho menos, pero cuando entre, será porque el mercado tiene volumen, tendencia y fuerza real. ¿Estás lista para que empiece a programar esta bestia en el V13?

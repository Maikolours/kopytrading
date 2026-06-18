<div class="cover-container" style="--accent-color: #F7931A; --accent-bg: rgba(247, 147, 26, 0.08);">
  <div class="logos-left">
    <img class="logo-head" src="{{logoKopyTrading}}" alt="KopyTrading Logo" />
  </div>
  <div class="header-text">
    <span class="badge-premium" style="--accent-color: #F7931A; --accent-bg: rgba(247, 147, 26, 0.15);">Institutional Crypto Engine</span>
    <h1 class="main-title">MAIKO PRO BTC</h1>
    <h2 class="sub-title">Guía de Inicio y Manual de Operación Oficial v5.84</h2>
  </div>
  <div class="logos-right">
    <img class="logo-maiko" src="{{logoMaikoBtc}}" alt="Maiko BTC" title="Versión BTC" />
  </div>
</div>

¡Felicidades por adquirir **MAIKO PRO BTC**! Este es un algoritmo de nivel institucional diseñado específicamente para domar la alta volatilidad del mercado de las Criptomonedas, con capacidad para operar de lunes a domingo.

---

## 1. ¿CUÁNTO CAPITAL NECESITO Y DÓNDE OPERAR?

Para operar de forma segura y sacarle el máximo provecho a la estrategia de Scalping Dinámico del bot, la gestión de riesgo y la elección del broker son pilares fundamentales:

<div class="grid-2">
  <div class="grid-col">
    <div class="card card-accent" style="--accent-color: #F7931A; --accent-bg: rgba(247, 147, 26, 0.04);">
      <h4>💰 Capital Recomendado</h4>
      <p>Recomendamos un capital mínimo de <strong>$2,000 USD</strong>. El mercado de Bitcoin tiene movimientos porcentuales muy amplios, por lo que es necesario un margen cómodo para absorber las fluctuaciones del precio.</p>
    </div>
  </div>
  <div class="grid-col">
    <div class="card card-accent" style="--accent-color: #F7931A; --accent-bg: rgba(247, 147, 26, 0.04);">
      <h4>⚡ Operativa de Fin de Semana</h4>
      <p>El bot funciona 24/7. El fin de semana, cuando baja el volumen institucional, aprovecha las zonas de lateralización y ejecuta entradas de alta precisión en soportes y resistencias.</p>
    </div>
  </div>
</div>

### 🏢 Elección del Broker
* **Broker Crypto-Friendly:** Asegúrate de que tu broker permite operar Bitcoin los fines de semana y que maneje spreads razonables para BTCUSD. Si el spread es excesivamente alto, el bot se abstendrá de operar por seguridad.
* **⚠️ Advertencia sobre otros brokers:** Asegúrate de revisar que las comisiones por lote y el spread no superen los límites lógicos, especialmente el fin de semana.

---

## 2. DISCIPLINA Y GESTIÓN DE RIESGO: LA REGLA DE ORO

El trading algorítmico es una actividad de precisión matemática. Para obtener beneficios consistentes:

### 🚫 No Intervenir en la Operativa del Bot
Una vez que enciendas el bot, **se recomienda no tocar las operaciones individuales ni modificarlas manualmente**. El sistema calcula distancias y tamaños de lote de forma exacta. Si cierras o modificas operaciones a mano, romperás la matemática de la estrategia y puedes provocar pérdidas flotantes innecesarias. Deja trabajar al sistema.

### 🛡️ Uso del Stop Loss Diario Personalizado
El bot cuenta con un parámetro de protección para limitar pérdidas extremas de forma dinámica:
* **Stop Loss Diario:** Viene configurado por defecto en el **10% del balance de la cuenta**.
* **⚠️ Recomendación muy importante:** No configures este límite a un porcentaje muy bajo (como un 2% o un 5%). Si lo haces, el bot cerrará operaciones en pérdidas ante retrocesos normales que luego se habrían recuperado solos. **En un 80% o 90% de los casos, la estrategia del bot recupera el flotante de manera autónoma** si se le da el margen adecuado.

---

<div class="alert-box" style="--alert-color: #e11d48; --alert-bg: #fff1f2; --alert-text-color: #9f1239;">
  <h4>🚨 ¡ATENCIÓN CRÍTICA: CONTROL DE NOTICIAS MACROECONÓMICAS!</h4>
  <p>El mercado no es matemática pura y está sujeto a manipulaciones extremas o deslizamientos de spread durante noticias de alto impacto (IPC, desempleo NFP, tipos de interés de la Fed, etc.).<br>
  <strong>Si NO tienes operaciones abiertas</strong> y se aproxima una noticia importante: <strong>APAGA EL BOT INMEDIATAMENTE</strong>. Deja que pase el evento, observa cómo se estabiliza el mercado y vuelve a encender el bot una vez que regrese la normalidad.<br>
  Si la noticia extrema te pilla con operaciones abiertas, el precio puede moverse tan rápido que las operaciones queden colgadas. En esos casos, <strong>siempre es preferible pausar el bot e incluso cerrar manualmente operaciones en pequeñas pérdidas</strong> para proteger tu capital de una pérdida mayor por manipulación.</p>
</div>

---

## 3. CONCEPTOS CLAVE DE LA ESTRATEGIA MAIKO PRO BTC

A diferencia de los pares de divisas tradicionales, el Bitcoin no respeta los canales lógicos tradicionales y tiene fuertes impulsos (pumps y dumps). Por eso, su estrategia es radicalmente distinta:

1. **Filtro de Sobrecompra/Sobreventa Extrema:** El bot no persigue el precio. Se queda inactivo hasta que detecta que el Bitcoin ha sido sobre-vendido de manera irracional (pánico de mercado) analizando niveles de RSI y ATR en temporalidades cortas.
2. **Entrada Anti-Dump:** Entra en compra sólo cuando detecta que la fuerza vendedora se ha agotado.
3. **Protección Anti-Liquidación (Trailing DD):** En Bitcoin no podemos usar una cascada profunda porque una caída puede durar meses. El bot utiliza un sistema de límite de equidad y salidas de emergencia para cortar pérdidas antes de que ocurra un desastre.
4. **⏱️ Temporalidad Obligatoria:** **M1 (1 Minuto)** en el gráfico.
5. **⏰ Estado "Buscando...":** Verás que el bot pasa horas o incluso días sin abrir operaciones. No está roto, está analizando. El Bitcoin requiere extrema precisión.

---

## 4. INSTRUCCIONES DE INSTALACIÓN PASO A PASO

1. **Descarga el bot:** Obtén el archivo ejecutable del bot (`*.ex5`) desde tu panel de usuario de KopyTrading.
2. **Abre MetaTrader 5:** En tu PC o servidor VPS, abre MT5. Ve a **Archivo** > **Abrir Carpeta de Datos**.
3. **Ubica la carpeta de Experts:** Navega a `MQL5` > `Experts` y pega el archivo descargable del bot allí.
4. **Actualiza e Instala:** En la barra izquierda de MT5 (Navegador), haz clic derecho sobre "Asesores Expertos" y pulsa **Actualizar**.
5. **Configura el Gráfico:** Abre el gráfico de **BTCUSD** (Bitcoin) y configúralo en la temporalidad de `M1`.
6. **Arrastra el bot:** Arrastra el Asesor Experto al gráfico.
7. **IMPORTANTE - Activa tu Licencia:** En la pestaña de parámetros del bot, asegúrate de rellenar el campo **ID Vínculo** con tu código personal obtenido en tu panel web. **Este paso es una condición obligatoria e indispensable tanto para cuentas Reales como para cuentas DEMO.** Sin tu código de licencia, el bot no operará.
8. **Activa el Autotrading:** Asegúrate de que el botón de **Algo Trading** (Trading Algorítmico) en la barra superior de MT5 esté de color verde (Activado).

---

## 5. ERRORES COMUNES Y RESOLUCIÓN DE PROBLEMAS

### ❌ El bot está en el gráfico pero no abre operaciones y no carga el HUD
* **Solución:** Asegúrate de haber introducido tu **ID Vínculo** de licencia en los parámetros del bot. Sin esto, el bot se mantendrá desactivado por seguridad.

### ❌ El bot da error de conexión al iniciar o no valida la licencia
* **Explicación:** MetaTrader 5 requiere tu autorización expresa para conectarse a nuestro servidor web y validar tu ID de licencia.
* **Solución (Paso Obligatorio de WebRequest):**
  1. En la barra superior de MT5, ve a **Herramientas (Tools)** > **Opciones (Options)**.
  2. Selecciona la pestaña **Asesores Expertos (Expert Advisors)**.
  3. Marca la casilla **"Permitir WebRequest para las URLs listadas" (Allow WebRequest for listed URL)**.
  4. Haz doble clic en el símbolo `+` verde de abajo y añade la URL oficial de la plataforma:
     `https://kopytrading.com`
  5. Haz clic en **Aceptar**. Reinicia tu MetaTrader 5 y el bot se conectará de inmediato.

---

## 6. AVISO DE RIESGO Y LIMITACIÓN DE RESPONSABILIDAD

> [!WARNING]
> **El trading en mercados financieros conlleva un alto riesgo de pérdida de capital.**
> Aunque Evolution PRO ha sido diseñado con tecnología de punta y cuenta con estadísticas de acierto superiores al 80% en pruebas históricas, el mercado del Oro es sumamente volátil y los rendimientos pasados no garantizan beneficios futuros.
>
> **KopyTrading se limita exclusivamente a proveer herramientas de software y soporte tecnológico.** No actuamos como asesores financieros, no gestionamos cuentas de terceros ni somos responsables por las pérdidas directas o indirectas derivadas del uso de este bot. Opera siempre con capital que estés dispuesto a arriesgar y bajo tu propia responsabilidad.

---
*Desarrollado con ❤️ por el equipo de KopyTrading. ¡Que tengas una excelente y disciplinada sesión de trading!*

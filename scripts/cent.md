<div class="cover-page" style="--accent-color: #10B981; --accent-bg: rgba(16, 185, 129, 0.08);">
  <div class="cover-content">
    <img class="cover-logo-head" src="{{logoKopyTrading}}" alt="KopyTrading" />
    <div>
      <span class="cover-badge" style="--accent-color: #10B981; --accent-bg: rgba(16, 185, 129, 0.15);">Micro-Account Engine</span>
    </div>
    <h1 class="cover-title">MAIKO PRO CENT</h1>
    <h2 class="cover-subtitle">Guía de Inicio y Manual de Operación Oficial v5.84</h2>
    <div class="cover-frame">
      <img class="cover-logo-maiko" src="{{logoMaikoCent}}" alt="Maiko Cent" />
    </div>
  </div>
</div>
<div class="page-break"></div>

¡Felicidades por adquirir **MAIKO PRO CENT**! Esta es la versión "Blindada" del motor Maiko. Al estar diseñado exclusivamente para operar en Cuentas CENT (donde la escala del dinero se multiplica por 100), es un bot extremadamente conservador en cuanto a riesgo real, ideal para un crecimiento constante del balance y uso del interés compuesto.

---

## 1. ¿CUÁNTO CAPITAL NECESITO Y DÓNDE OPERAR?

Para operar de forma segura y sacarle el máximo provecho a la estrategia de Scalping Dinámico del bot, la gestión de riesgo y la elección del broker son pilares fundamentales:

<div class="grid-2">
  <div class="grid-col">
    <div class="card card-accent" style="--accent-color: #10B981; --accent-bg: rgba(16, 185, 129, 0.04);">
      <h4>💰 Capital Recomendado (Real)</h4>
      <p>Lo ideal es depositar entre <strong>$300 USD y $500 USD reales</strong>. En una cuenta CENT, esto se visualiza como un balance operativo de entre <strong>30,000 y 50,000 centavos</strong>, haciendo que la cuenta sea extremadamente segura.</p>
    </div>
  </div>
  <div class="grid-col">
    <div class="card card-accent" style="--accent-color: #10B981; --accent-bg: rgba(16, 185, 129, 0.04);">
      <h4>🎁 El "Truco" del Bono del 100%</h4>
      <p>Si depositas por ejemplo <strong>$250 USD reales</strong> (25,000 centavos) y aprovechas el bono del 100%, tu cuenta CENT operará con un balance total de <strong>50,000 centavos</strong>. Tendrás un colchón de margen extraordinario arriesgando la mitad.</p>
    </div>
  </div>
</div>

### 🏢 Brokers Oficiales Recomendados (VT Markets y Vantage)
El bot ha sido intensivamente testeado con excelentes resultados en dos brokers de renombre internacional que ofrecen soporte para cuentas de centavos:
* **VT Markets (Recomendado):** Spreads muy bajos para el Oro y comisiones bajas.
* **Vantage (Cuenta Estándar/Cent):** Broker sumamente seguro, aunque ten en cuenta que el spread suele ser ligeramente superior al de VT Markets.
* **El Spread Ideal (~2.4 - 2.5):** La estrategia está optimizada para funcionar con un spread promedio de **2.4 a 2.5 puntos** (24-25 pips en MT5).
* **⚠️ Advertencia sobre otros brokers:** Si decides instalar el bot en otro broker, lo haces bajo tu propio riesgo. Spreads altos o variables pueden afectar los puntos de salida óptimos calculados por la estrategia.

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

### ⚡ Rendimiento en Movimientos Bruscos de Alta Volatilidad
El bot ha sido puesto a prueba en escenarios de alta volatilidad y movimientos extremadamente bruscos del mercado, demostrando una excelente solidez y capacidad de recuperación. En nuestras cuentas de seguimiento, el algoritmo ha gestionado de manera óptima el flotante ante caídas y subidas repentinas de precio, cerrando las operaciones con beneficios consistentes de forma autónoma. No obstante, es importante recordar que el mercado no es 100% predecible y se debe vigilar la operativa.

<div class="alert-box" style="--alert-color: #e11d48; --alert-bg: #fff1f2; --alert-text-color: #9f1239;">
  <h4>🚨 ¡ATENCIÓN CRÍTICA: CONTROL DE NOTICIAS MACROECONÓMICAS!</h4>
  <p>El mercado no es matemática pura y está sujeto a manipulaciones extremas o deslizamientos de spread durante noticias de alto impacto (IPC, desempleo NFP, tipos de interés de la Fed, etc.).<br>
  <strong>Si NO tienes operaciones abiertas</strong> y se aproxima una noticia importante: <strong>APAGA EL BOT INMEDIATAMENTE</strong>. Deja que pase el evento, observa cómo se estabiliza el mercado y vuelve a encender el bot una vez que regrese la normalidad.<br>
  Si la noticia extrema te pilla con operaciones abiertas, el precio puede moverse tan rápido que las operaciones queden colgadas. En esos casos, <strong>siempre es preferible pausar el bot e incluso cerrar manualmente operaciones en pequeñas pérdidas</strong> para proteger tu capital de una pérdida mayor por manipulación.</p>
</div>

---

## 3. CONCEPTOS CLAVE DE LA ESTRATEGIA MAIKO PRO CENT

El sistema v5.84 incluye mejoras exclusivas de inteligencia artificial y protección del balance:

1. **Meta Inteligente (Smart Take Profit):** El bot no utiliza un TP fijo estático. Ajusta dinámicamente el objetivo de ganancia en función de la volatilidad y la velocidad del precio para exprimir al máximo los movimientos a nuestro favor.
2. **🏛️ Filtro de Techos y Suelos:** Este filtro analiza las últimas horas de mercado para identificar zonas de saturación (soportes y resistencias locales). Evita que el bot compre en máximos (techos) o venda en mínimos (suelos), reduciendo drásticamente el drawdown.
3. **⏱️ Flexibilidad de Temporalidades (Timeframes):** 
   * **M15 (15 Minutos - Recomendado por defecto):** Ofrece el equilibrio ideal entre la frecuencia de las operaciones y la precisión en las entradas.
   * **M5 (5 Minutos):** Aumenta la velocidad y la cantidad de operaciones (perfil más agresivo), pero ten en cuenta que el flotante puede subir más rápido.
   * **H1 (1 Hora):** Recomendado para mercados altamente volátiles o para un estilo de trading muy conservador. Las operaciones son más espaciadas y seguras, reduciendo la exposición al ruido del mercado.
4. **⏰ Horario Operativo por Defecto:** Viene programado para buscar entradas de **09:00 a 19:00 (de lunes a viernes)**, que son las horas de mayor liquidez. Puedes editar libremente este rango horario en los parámetros del bot para adaptarlo a tus preferencias.
5. **📱 Control Total desde el Móvil:** Gracias a la sincronización en la nube de KopyTrading:
   * Puedes monitorear tus operaciones abiertas y ganancias diarias desde el móvil.
   * Cuentas con un **Botón de Pánico / Cierre** desde tu dashboard web para pausar el bot o cerrar todo en un solo clic si alguna vez te sientes incómodo con el mercado, sin necesidad de conectarte a tu VPS.

---

## 4. INSTRUCCIONES DE INSTALACIÓN PASO A PASO

1. **Descarga el bot:** Obtén el archivo ejecutable del bot (`*.ex5`) desde tu panel de usuario de KopyTrading.
   * *Nota: Te recomendamos revisar periódicamente tu panel web. Liberamos actualizaciones regulares para optimizar la operativa y adaptarnos a los cambios del mercado en tu beneficio.*
2. **Abre MetaTrader 5:** En tu PC o servidor VPS, abre MT5. Ve a **Archivo** > **Abrir Carpeta de Datos**.
3. **Ubica la carpeta de Experts:** Navega a `MQL5` > `Experts` y pega el archivo descargable del bot allí.
4. **Actualiza e Instala:** En la barra izquierda de MT5 (Navegador), haz clic derecho sobre "Asesores Expertos" y pulsa **Actualizar**.
5. **Configura el Gráfico:** Abre el gráfico de **XAUUSDc** o **GOLD.c** (el correspondiente a cuentas Cent) y configúralo en la temporalidad deseada (`M15` por defecto).
6. **Arrastra el bot:** Arrastra el Asesor Experto al gráfico del Oro.
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
> Aunque Maiko Pro ha sido diseñado con tecnología de punta y cuenta con estadísticas de acierto superiores al 80% en pruebas históricas, el mercado del Oro es sumamente volátil y los rendimientos pasados no garantizan beneficios futuros.
>
> **KopyTrading se limita exclusivamente a proveer herramientas de software y soporte tecnológico.** No actuamos como asesores financieros, no gestionamos cuentas de terceros ni somos responsables por las pérdidas directas o indirectas derivadas del uso de este bot. Opera siempre con capital que estés dispuesto a arriesgar y bajo tu propia responsabilidad.

---
*Desarrollado con ❤️ por el equipo de KopyTrading. ¡Que tengas una excelente y disciplinada sesión de trading!*

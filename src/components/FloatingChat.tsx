"use client";

import { useState, useRef, useEffect } from "react";

const BOT_RESPONSES: { keywords: string[]; response: string }[] = [
    {
        keywords: ["hola", "hello", "buenas", "hey", "qué tal", "que tal", "saludos"],
        response: "¡Hola! Soy KopyBot 🤖, el asistente experto de KopyTrading. Puedo ayudarte con consultas técnicas, MetaTrader 5, nuestros bots, brokers y gestión de riesgo. ¿En qué te puedo ayudar?"
    },
    {
        keywords: ["recomiendas", "recomienda", "empezar", "primer bot", "cuál compro", "cual compro", "para principiante", "soy nuevo", "nunca he", "novato", "recomendación", "mejor para"],
        response: "🏆 **Para principiantes, te recomiendo El Euro Precision Flow (EURUSD)** por estas razones:\n\n✅ Riesgo BAJO (el más seguro de los 4)\n✅ Capital mínimo 500$ (el más accesible)\n✅ Opera en H1 — señales claras, sin mucho ruido\n✅ El Euro es el par más líquido y estabilizado del mundo\n\n⚡ Si quieres más acción y tienes 1.000$, **La Ametralladora (XAUUSD)** es apasionante, pero tiene más riesgo.\n\n❌ **Evita BTC Storm Rider** si eres principiante — el Bitcoin es altamente volátil."
    },
    {
        keywords: ["cuándo abre", "cuando abre", "no opera", "operacion", "operación", "señal", "esperar", "cuánto tiempo", "cuanto tiempo", "no hace nada", "no abre nada", "lleva dias", "lleva días", "no mete", "cero operaciones", "ninguna operacion", "esperando"],
        response: "⏳ **¿Por qué el bot no abre operaciones?**\n\nEs 100% normal. Nuestros bots usan algoritmos muy estrictos. No operan al azar; analizan múltiples temporalidades y filtros (cruce de medias, RSI, mechas de rechazo, spread y volatilidad) antes de abrir una operación.\n\n• **Euro Precision (H1)**: Puede pasar de 3 a 5 días sin abrir operaciones si no hay tendencia clara.\n• **Yen Ninja (M30)**: Solo opera en horario nocturno (0h a 8h broker).\n• **La Ametralladora (M5)**: Es el más rápido, pero si el spread del Oro es alto o hay noticias, se detendrá.\n\nTen paciencia, el bot está protegiendo tu capital."
    },
    {
        keywords: ["ametralladora", "xauusd", "oro", "gold"],
        response: "🔥 **MAIKO SNIPER PRO GOLD (XAUUSD)** — El más popular\n\n• Temporalidad: **M5**\n• Estrategia: Scalping + Hedge Inteligente\n• Horario: 9h - 21h\n• Capital mínimo: 1.000$\n• Riesgo: Medio\n• Precio: Próximo Lanzamiento\n\n⚠️ El Oro es súper volátil. Usa siempre lotaje 0.01 por cada 1.000$.\n\n🎁 **Prueba nuestra versión Demo por 1$ durante 30 días** y luego podrás adquirir tu licencia válida para un año."
    },
    {
        keywords: ["euro", "precision", "eurusd", "eur"],
        response: "🎯 **Euro Precision Flow (EURUSD)** — El más seguro\n\n• Temporalidad: **H1**\n• Estrategia: Cruce de EMA 21/50 + Filtro RSI\n• Horario: 8h - 20h\n• Capital mínimo: 500$\n• Riesgo: BAJO ✅\n• Precio: Próximo Lanzamiento\n\n💡 Puede tardar días en abrir porque espera la alineación perfecta del cruce institucional (H1)."
    },
    {
        keywords: ["yen", "usdjpy", "ninja", "jpy", "asia", "asiática", "asiatica"],
        response: "🥷 **Yen Ninja Ghost (USDJPY)** — Operativa nocturna\n\n• Temporalidad: **M30**\n• Estrategia: Rebote Bollingers + RSI\n• Horario: 0h - 8h (noche europea)\n• Capital mínimo: 500$\n• Riesgo: Medio\n• Precio: Próximo Lanzamiento\n\n🌙 Perfecto para aprovechar los rangos aburridos de la sesión asiática."
    },
    {
        keywords: ["bitcoin", "btc", "crypto", "cripto", "storm"],
        response: "⚡ **MAIKO SNIPER PRO BTC (BTCUSD)** — Solo para verdaderos expertos\n\n• Temporalidad: **H4 o M30 según set**\n• Estrategia: Breakout/Tendencia Fuerte\n• Horario: 24/7\n• Capital mínimo: 2.000$\n• Riesgo: ALTO ⚠️\n• Precio: Próximo Lanzamiento\n\nDiseñado para capturar la enorme inercia y volatilidad de la criptomoneda madre."
    },
    {
        keywords: ["precio", "cuánto cuesta", "cuanto cuesta", "costo", "coste", "todos", "comparar", "comprar", "pagar", "compras", "licencia anual", "pago"],
        response: "💰 **Precios de las Licencias:**\n\nActualmente todos nuestros bots están en fase de lanzamiento y el precio definitivo está por determinar.\n\n⚡ **Lo único disponible ahora mismo** es la versión demo del bot estrella **MAIKO PRO GOLD**, que puedes activar durante **30 días por solo 1$** en una cuenta DEMO de MetaTrader 5.\n\nTras el período de demo, podrás adquirir tu licencia válida para un año. Visita la sección de [Bots](/bots) para más información."
    },
    {
        keywords: ["vps", "servidor", "cloud", "siempre encendido", "apago el ordenador", "se apaga", "nube", "contabo", "hosting", "computadora", "vps servidor"],
        response: "🖥️ **¿Es obligatorio el VPS (Servidor en la Nube)?**\n\n**SÍ, en el 99% de los casos.** Si tu ordenador de casa se suspende, se apaga, Windows se actualiza o la línea de internet se cae, MetaTrader 5 se cerrará. Si MT5 se cierra, el bot se desconecta de la bolsa y dejará de gestionar tus órdenes abiertas, lo cual es muy peligroso.\n\n👉 **Recomendamos Contabo (plan VPS S)** por unos 5-6€ al mes. Es un servidor encendido 24h/7d sin molestarte, donde instalas Windows Server, metes MT5 y dejas el bot funcionando de forma segura."
    },
    {
        keywords: ["broker", "vantage", "vtmarkets", "pepperstone", "ic markets", "dónde", "donde", "qué broker", "que broker", "mt5 broker", "brokers"],
        response: "🏦 **Brokers 100% Compatibles con KopyTrading:**\n\n• **Vantage Markets**: Gran broker ECN, sin limites en XAU.\n• **Pepperstone**: Extrema liquidez, ideal para bots (Regulado EU/US/AU).\n• **IC Markets**: Favorito mundial por latencia hiperbaja.\n• **VT Markets**: Muy buena ejecución de pares Forex.\n\n(Recomendamos usar tipos de cuenta 'RAW' o 'PRO' para tener spreads desde 0.0 pips y minimizar comisiones)."
    },
    {
        keywords: ["licencia", "clave", "número de cuenta", "cuenta mt5", "cómo activar", "autorizada", "identidad", "autorizar", "vinculo", "vincular", "mi cuenta", "numero de cuenta"],
        response: "🔐 **Sistema de Protección y Licencias:**\n\nEl archivo del bot está encriptado y se vincula a tu número de Cuenta particular de MetaTrader 5. Solo debes escribir este número exacto en las propiedades del bot, sección **'MiLicencia'** o **'Cuenta'**.\n\n👉 De esta manera, tu bot queda blindado. Al arrastrarlo al gráfico de MetaTrader, el sistema validará tu licencia en nuestra Base de Datos en tiempo real y se autorizará automáticamente."
    },
    {
        keywords: ["instalar", "instalación", "instalacion", "instala", "instalo", "mt5", "metatrader", "cómo lo instalo", "archivos", "mq5", "ex5", "instalar el bot", "como se usa"],
        response: "📋 **Puesta a punto (MetaTrader 5):**\n\n1. En MT5: Archivo → Abrir carpeta de datos.\n2. Ve a MQL5 → Experts y pega ahí el archivo `.ex5` descargado.\n3. Asegúrate de activar el botón **'Algo Trading'** en la parte superior de MT5 (debe tener play verde).\n4. Abre el gráfico del par correspondiente (ej: XAUUSD en temporalidad M5 para el bot de Oro).\n5. Arrastra el bot desde el navegador al gráfico, pon tu código de vínculo en el parámetro 'MiLicencia', marca 'Permitir trading algorítmico' en la pestaña Común y pulsa Aceptar.\n\n¡Listo! El HUD del bot aparecerá en tu gráfico."
    },
    {
        keywords: ["gratis", "demo", "trial", "mes gratis", "free", "prueba", "30 dias", "30 días", "trial 30"],
        response: "⚡ **Demo del MAIKO PRO GOLD:**\n\nPuedes activar la demo del bot estrella **MAIKO PRO GOLD** durante **30 días** en una cuenta DEMO de MetaTrader 5 por solo **1$**.\n\nEl algoritmo opera en **M5** con estrategia de scalping institucional. Conectado a tu cuenta DEMO de tu broker, podrás observar cómo opera en tiempo real sin arriesgar dinero real.\n\nTras los 30 días, podrás adquirir tu licencia válida para un año. \n\n🔗 [Activar Demo](/bots/cmn9hf8yc0000vhbcq9hbxk0j)"
    },
    {
        keywords: ["stripe", "paypal", "bizum", "cómo pago", "tarjeta", "pagar", "metodos de pago", "métodos de pago"],
        response: "💳 **Métodos de Pago:**\n\nAceptamos pagos seguros mediante tarjeta de crédito/débito a través de **Stripe** y pagos con **PayPal Express**. Nuestras licencias son de suscripción anual, sin costes ocultos ni comisiones sobre tus ganancias."
    },
    {
        keywords: ["no funciona", "error", "problema", "ayuda", "bug", "fallo", "cuenta no autorizada", "no se abre", "invalido", "invalid license"],
        response: "🔧 **Diagnóstico de Problemas Técnicos:**\n\n1. **'Invalid License / Cuenta no autorizada'**: Verifica que no haya espacios al poner tu Nº de cuenta en los Ajustes del bot.\n2. **'AutoTrading deshabilitado'**: Dale al icono de AutoTrading en MT5 (arriba al centro, debe tener play verde).\n3. **'No abre nada'**: Asegúrate que el mercado esté abierto y estás en la gráfica correcta (Oro, Euro..).\nParecen tonterías, pero suele ser la solución al 90%."
    },
    {
        keywords: ["qué es kopytrading", "quiénes sois", "sobre vosotros", "la empresa", "kopytrading", "quienes somos"],
        response: "🏢 **Sobre nosotros KopyTrading:**\n\nEvitamos los sistemas piramidales, las mensualidades, las Martingalas destructivas y el marketing vende-húmos.\n\nSolo proporcionamos algoritmos matemáticos probados, que nosotros mismos operamos, directamente de las manos del desarrollador a la gráfica del trader. Trading puro, duro y aburrido (consistente)."
    },
    {
        keywords: ["break even", "breakeven", "empate", "proteger"],
        response: "🛡️ **Sistema Break Even (BE):**\n\nNuestra regla de oro. Si la operación va ganando X dólares, el Bot bloquea la posición y mueve el Stop Loss exactamente a tu punto de entrada.\n\n✅ Desde ese instante el saldo de esa operación NUNCA pasará a ser negativo. Estarás matemáticamente blindado ante cualquier retroceso."
    },
    {
        keywords: ["trailing stop", "trailing", "perseguir", "asegurar", "trail"],
        response: "📉 **Trailing Stop Dinámico:**\n\nNo dejamos el Stop Loss fijo abajo mientras el precio sube al infinito.\nEl algoritmo lo arrastra dinámicamente varios pips por detrás del precio actual. Si se gira agresivamente el mercado, la operación se cortará de golpe con toda la caja en verde que haya acumulado durante el trayecto."
    },
    {
        keywords: ["apalancamiento", "leverage", "margen", "apalancado"],
        response: "⚖️ **Guía de Apalancamiento:**\n\nTe recomendamos seleccionar apalancamiento 1:100 o 1:200 en tu Broker.\nOjo: Apalancamiento NO es riesgo extra si usas nuestro Stop Loss y los lotes (0.01) correctamente.\nEl apalancamiento solo sirve para que el broker no retenga el 80% de tus fondos de Free Margin cada vez que el Bot accione."
    },
    {
        keywords: ["lote", "lotaje", "tamaño", "volumen", "0.01", "gestion de riesgo", "gestión de riesgo"],
        response: "📏 **Control del Gran Lotaje Matemático:**\n\nNunca subestimes un mal dimensionamiento.\nInicia siempre operando con volumen **0.01 Lotes** por cada 500$-1000$ que tengas fondeados en la gráfica. Ese es el único colchón que evitará la quema bajo Drawdowns extremos."
    },
    {
        keywords: ["mac", "apple", "macbook", "macos", "ipad"],
        response: "🍎 **MetaTrader en Ecosistema MAC**\n\nMT5 está nativamente programado para Windows. No obstante:\nOpción A: Usa la capa Parallels Desktop/CrossOver.\nOpción B (Nuestra Favorita): Contrátate un VPS Windows y usa Microsoft Remote Desktop. Verás a la perfección tu Windows con el bot desde tu Mac impecablemente fluido."
    },
    {
        keywords: ["fondeo", "prop firm", "ftmo", "evaluación", "funding", "darwinex", "pass", "cuenta fondeada"],
        response: "🏆 **Apto para Firmas de Fondeo (Prop Firms):**\n\nAbsolutamente. Todos los Bots usan Stop Loss estrictos sin promedios Martingala. Cumplirás perfectamente los mandatos del 'Daily Maximum Loss Drawdown' requeridos para superar los Exámenes y Challenges de FTMO o MyForexFunds."
    },
    {
        keywords: ["martingala", "martingale", "grid", "cuadricula", "promediar", "martingalas"],
        response: "⚠️ **Cero exposición infinita (No Martingalas suicidas):**\n\nTodos nuestros bots rechazan la clásica Martingala exponencial.\nAlgunos usan Hedge escalonado minúsculo, pero todos (sin excepción) cortan con un Stop Loss Duro general de Equity. Cuando nos equivocamos, nos equivocamos, perdemos el 1-2% del account y a seguir. Sobrevivimos."
    },
    {
        keywords: ["drawdown", "retroceso", "flotante", "negativo", "baja la cuenta", "flotante negativo"],
        response: "📉 **El inevitable Drawdown (DD):**\n\nTodo algoritmo tendrá DD. Es el flotante negativo aguantado temporalmente. Nuestros perfiles arrojan Drawdowns calculados entre un 5% y 20% histórico anual (teniendo muy buena protección institucional)."
    },
    {
        keywords: ["noticias", "news", "nfp", "ipc", "cpi", "powell", "noticia", "bloqueo noticias"],
        response: "📰 **Impacto de las Noticias Macro:**\n\nNivel rojo (Powell, NFP). En estas franjas el spread del oro o del euro puede triplicarse y saltarse tus defensas.\nRecomendación de oro: Pulsa off al Bot 60 mins antes y préndelo 60 mins después de la intervención fundamental."
    },
    {
        keywords: ["mt4", "metatrader 4", "mq4"],
        response: "⚙️ **¿Por qué no funciona en MT4?**\n\nKopyTrading desarrolla nativamente al 100% en `MQL5` para MetaTrader 5 porque es el futuro estándar de las instituciones y su Tester genético multithread está a años luz de las herramientas arcaicas de MT4."
    },
    {
        keywords: ["movil", "móvil", "android", "iphone", "celular", "app", "aplicacion movil"],
        response: "📱 **Acceso vía Smartphones (Móvil):**\n\nNo puedes inyectar un robot en la App Móvil de MetaTrader (MetaQuotes lo bloquea por arquitectura). Usa tu PC o tu VPS para alojar el `Bot.ex5`.\nEso sí, luego podrás vincular la App móvil de MT5 a tu cuenta de broker y ver a tiempo real, desde tu sofá, todas las operaciones que abra y cierre el bot de forma automática."
    },
    {
        keywords: ["rentabilidad", "ganancia", "cuanto gano", "porcentaje", "mensual", "roi", "cuanto da", "ganancias"],
        response: "💵 **Proyecciones de Rentabilidad:**\n\nCálculos empíricos y moderados nos arrojan entre un **2% a 5%** de beneficio neto mensual empleando perfiles de riesgo conservadores. \nCualquiera que te garantice un +30% mensual sistemático es porque expone la cuenta al +100% de quebrar (un fraude estadístico)."
    },
    {
        keywords: ["interés", "interes compuesto", "compound", "crecimiento"],
        response: "📈 **La Magia del Compound (Interés Compuesto):**\n\nEmpieza con 1.000$ a Lote 0.01. Pasados unos meses, con tu cuenta en $2.000 (entre ingresos y bots), asciende el Lotaje a 0.02 respetando el escalón. Expones lo mismo visualmente, pero la gráfica nominal ascenderá en curva geométrica maravillosa."
    },
    {
        keywords: ["manual", "cerrar", "yo mismo", "intervenir", "manipular"],
        response: "✋ **Tú Eres el Dueño de las Posiciones:**\n\nSi el robot metió una orden, y vas ganando un buen pico que necesitas o que ves incierto a la luz de las velas macro: TÚ le das a la X. No afectará a la API, simplemente el bot cerrará el monitor actual y reanudará escaneo al tick siguiente."
    },
    {
        keywords: ["internet", "corte", "se va la luz", "wifi", "desconexión"],
        response: "🔌 **La Vitalidad de la Conexión Ininterrumpida:**\n\nSi el terminal pierde red, el algoritmo de gestión (Break Evens / Trails) desaparece con él. Dejarás la posición a su suerte desprotegida.\nVuelvo al refrán institucional: \"Un VPS vale 5€ y te ahorra años de salud cardiovascular\"."
    },
    {
        keywords: ["devolucion", "reembolso", "garantia", "devolver", "return"],
        response: "↩️ **Política de Devolución:**\n\nEntregamos código compilado EX5 listo para rodar. Dado su formato de producto digital sin desvinculación comprobable, no realizamos reembolsos de compras. Te sugerimos exprimir al máximo los 30 días de prueba gratuita en Demo para estar seguro antes de comprar."
    },
    {
        keywords: ["actualización", "update", "versión nueva", "version", "upgrade", "descargar version"],
        response: "🔄 **Mantenimiento y Actualizaciones:**\n\nNuestras actualizaciones son 100% gratuitas. En cuanto publiquemos una mejora o nueva versión de un bot que has adquirido, podrás descargarla de forma gratuita directamente desde tu área de cliente (Dashboard) para siempre."
    },
    {
        keywords: ["cuál opera más", "quien opera más", "cual opera mas", "mas veces", "más operaciones", "mayor frecuencia", "opera mucho", "más rápido", "mas rapido", "el bot mas rapido", "el más rápido", "operaciones al dia"],
        response: "⚡ **¿Cuál es el bot más rápido en operar?**\n\nEl bot más rápido y activo es **La Ametralladora (XAUUSD)**. Su nombre no es casualidad; al operar en gráficos de M5 y especializarse en Scalping en un par tan volátil como el Oro, tenderá a buscar muchas micro-entradas al día (entre 2 y 5 operaciones).\n\n*(Recuerda usar siempre lotes mínimos de 0.01 si empiezas con este bot).* "
    },
    {
        keywords: ["menos riesgo", "más seguro", "mas seguro", "menor riesgo", "conservador", "cual arriesga menos", "qué bot es más seguro", "el mas seguro"],
        response: "🛡️ **¿Cuál es el bot con menor riesgo?**\n\nEl más seguro y conservador es el **Euro Precision Flow (EURUSD)**. \n\nOpera en temporalidad de H1 (1 hora) y sobre el par Euro-Dólar, que es el más líquido y estable del mundo. Tarda más tiempo en encontrar oportunidades y abrir operaciones, pero sus entradas están extremadamente filtradas y seguras."
    },
    {
        keywords: ["cuántas operaciones hace", "cuantas operaciones hace", "frecuencia de cada", "qué frecuencia", "cuánto tarda cada", "frecuencia operaciones"],
        response: "⏱️ **Frecuencia de Operaciones de nuestros Bots:**\n\n• **La Ametralladora (XAUUSD):** 2 a 5 operaciones al día (Scalping rápido).\n• **Yen Ninja Ghost (USDJPY):** 3 a 8 operaciones por *semana* (solo nocturno de 0h a 8h).\n• **Euro Precision Flow (EURUSD):** 1 a 3 operaciones por *semana* (alta precisión H1).\n• **BTC Storm Rider (BTCUSD):** Puede pasar semanas sin operar hasta capturar un gran breakout de Bitcoin."
    },
    {
        keywords: ["ganar más dinero", "que más dinero", "que mas dinero", "gana más", "gana mas", "más beneficios", "mas beneficios", "más rentable", "mas rentable", "el que más gana", "mayor beneficio", "mejor rendimiento"],
        response: "💸 **¿Con cuál bot se gana más dinero?**\n\nPor volatilidad e inercia de precios, **La Ametralladora (Oro)** y **BTC Storm Rider (Bitcoin)** son los que mayor potencial de ganancias rápidas ofrecen. \n\n⚠️ SIN EMBARGO: Mayor ganancia siempre implica mayor riesgo y fluctuaciones temporales de la cuenta (Drawdown). No busques solo la ganancia; busca la consistencia combinando varios perfiles."
    },
    {
        keywords: ["capital asegurado", "asegurado el capital", "seguro de perdida", "pierdo mi dinero", "perderlo todo", "garantizado", "riesgo cero", "riesgo 0", "capital protegido", "mi dinero está seguro", "esta asegurado", "garantizar ganancias"],
        response: "🛑 **Aviso de Riesgo Importante:**\n\n**NO, el capital NO está asegurado bajo ningún concepto.**\nEl trading financiero, sea algorítmico o manual, implica un riesgo real de pérdida. Quien te ofrezca rentabilidades garantizadas o riesgo cero en la bolsa, te está intentando estafar.\n\nNuestros bots usan defensas avanzadas como *Stop Loss* general de balance y blindaje *Break Even* para proteger tu cuenta y evitar catástrofes, pero arriesgas dinero real. Invierte solo capital que te puedas permitir perder sin afectar tu vida diaria."
    },
    {
        keywords: ["cara triste", "sombrero gris", "no cambia de color", "no cambia color", "no hace nada al pulsar", "el bot no responde", "boton encender", "botón encender", "no se enciende", "no enciende", "no activa"],
        response: "🤖 **El botón de encender o el HUD no responde (Mercado cerrado / Fin de semana):**\n\nEn MetaTrader 5, los gráficos y botones se actualizan en base a los precios que envía tu broker (ticks). Fines de semana (sábados y domingos) o festivos, el mercado está cerrado y no hay ticks, por lo que antes la interfaz parecía congelada.\n\n✨ **¡Lo hemos solucionado!** Hemos actualizado nuestros bots para que al hacer clic en 'ENCENDER' el HUD responda al instante, el botón cambie a color rojo y muestre **'APAGAR'**, y el estado ponga **'ARMADO (FUERA DE HORARIO)'**. En cuanto abra el mercado, empezará a operar solo sin que tengas que tocar nada."
    },
    {
        keywords: ["cuenta real trial", "demo en real", "trial en real", "versión de prueba en real", "gratis en real", "demo real", "gratis real"],
        response: "🔐 **¿Puedo usar la versión de prueba (Trial) en cuenta Real?**\n\n**NO. Está bloqueado por código.** La licencia de prueba de 1$ por 30 días de **MAIKO PRO GOLD** funciona exclusivamente en cuentas de tipo **DEMO** (dinero virtual). Si arrastras el bot de prueba a una cuenta Real, emitirá una alerta sonora en pantalla y se desinstalará de la gráfica de inmediato por tu seguridad."
    },
    {
        keywords: ["fuera de horario", "esperando hora", "fuera horario", "09:00", "9 de la mañana", "horario de operativa", "no opera de noche", "esperando horario"],
        response: "⏰ **El bot pone 'FUERA HORARIO: ESPERANDO':**\n\nEs el comportamiento correcto. El bot tiene un horario seguro de operativa (por defecto de **09:00 a 19:00 hora del broker**). Fuera de ese rango, el bot detiene la búsqueda de nuevas entradas para proteger tu capital de la baja liquidez nocturna. Al llegar la hora operativa se activará de nuevo de forma 100% automática."
    },
    {
        keywords: ["dormir", "irse a dormir", "por la noche", "dejar encendido", "se enciende solo", "se activa solo", "que pasa cuando abre", "qué pasa cuando abre", "tengo que encenderlo", "tengo que volver a encenderlo", "dejarlo encendido", "dormir bot"],
        response: "🛌 **¿Qué hago al irme a dormir? ¿Tengo que volver a encender el bot?**\n\n**No tienes que hacer nada.** Si el botón está en rojo y dice **'APAGAR'**, el bot está **armado y activo**.\n\n• Si estás fuera de horario o el mercado está cerrado, verás el texto **'ARMADO (FUERA DE HORARIO)'** y **'FUERA HORARIO: MERCADO CERRADO'**.\n• Quédate tranquilo: puedes irte a dormir. El bot se quedará en espera y comenzará a operar solo en cuanto empiece el horario de operativa, sin que tengas que volver a pulsar el botón.\n\n⚠️ **Recordatorio**: Asegúrate de tener el MetaTrader en un VPS encendido. Si apagas tu PC personal, el bot no podrá operar."
    },
    {
        keywords: ["soporte", "contacto", "ayuda", "telegram", "correo", "email", "hablar con alguien", "humano", "escribir", "redes", "chat", "escribir a soporte"],
        response: "📞 **Contacto con Soporte Humano:**\n\nSi necesitas asistencia personalizada para configurar tu VPS o tienes preguntas sobre tu licencia:\n\n💬 **Telegram**: [@KopyTradingSoporte](https://t.me/KopyTradingSoporte)\n📧 **Email**: soporte@kopytrading.com\n\n¡Te responderemos a la mayor brevedad de lunes a viernes en horario de mercado!"
    },
    {
        keywords: ["deslizamiento", "slippage", "recorrer", "spread", "comisión", "comision", "swap", "swaps", "spreads"],
        response: "💹 **Spread, Slippage y Swaps:**\n\n• **Spread**: Es la comisión del broker por entrar. Si es alto, el bot espera a que baje para protegerte.\n• **Slippage**: Es cuando el precio se mueve tan rápido que entras en un punto distinto. Nuestros bots tienen filtros de 'Max Slippage'.\n• **Swap**: Es el interés por dejar la operación abierta de un día para otro. \n\nPara optimizar esto, usa siempre una cuenta **RAW o ECN** en tu broker."
    },
    {
        keywords: ["backtest", "probador", "historia", "pasado", "por que es distinto", "por qué es distinto", "real vs demo", "demo vs real"],
        response: "📈 **Backtest vs Realidad:**\n\nEl backtest es genial para ver si la estrategia funciona en el pasado, pero NO tiene en cuenta la latencia de internet ni los spreads variables del directo. \n\nNo te fíes solo del backtest: prueba el bot **30 días gratis en una cuenta DEMO** de tu broker. Esa es la única prueba real de fuego."
    },
    {
        keywords: ["diferencia", "KopyTrading", "copiar", "ea", "expert advisor", "señales", "señal"],
        response: "🔄 **¿Nuestros EAs (Bots) o CopyTrading?**\n\nEn el CopyTrading dependes de otro y de su plataforma. Con nuestros **EAs (Expert Advisors)**:\n\n1. El software corre en tu propio MetaTrader 5 (en tu PC o VPS).\n2. Tienes control absoluto de tu capital y lotajes.\n3. La ejecución es instantánea sin delays de red.\n4. Puedes apagarlo o cambiar el riesgo cuando quieras."
    },
    {
        keywords: ["descargar", "descarga", "descargan", "cómo descargar", "como descargar", "bajar el bot", "donde esta el archivo", "dónde está el archivo", "descarga mi bot"],
        response: "📥 **¿Cómo descargar tus bots?**\n\nEs instantáneo. Una vez activas una prueba o realizas una compra, ve a **[Mi Panel]** (o 'Dashboard'). \n\nAllí verás el botón de **'Descargar .ex5'** para cada uno de tus bots. Recuerda que también incluimos el manual en PDF para que no te pierdas nada."
    },
    {
        keywords: ["que bots hay", "qué bots hay", "cuales teneis", "cuáles tenéis", "cuales son", "cuáles son", "lista de bots", "catálogo", "catalogo"],
        response: "🤖 **Nuestros 4 Especialistas:**\n\n1. **La Ametralladora (XAUUSD)**: Scalping agresivo en Oro. ($$$)\n2. **Euro Precision Flow (EURUSD)**: El más seguro y estable. (✅)\n3. **Yen Ninja Ghost (USDJPY)**: Estrategia nocturna para Asia. (🥷)\n4. **BTC Storm Rider (BTCUSD)**: Solo para expertos en Bitcoin. (⚡)\n\nPuedes ver los detalles de cada uno en la sección de **Bots** de la web."
    },
    {
        keywords: ["capital minimo", "capital mínimo", "cuanto dinero necesito", "cuánto dinero necesito", "deposito minimo", "depósito mínimo"],
        response: "💰 **Capital Mínimo Recomendado:**\n\n• **Euro Precision**: 500$\n• **Yen Ninja**: 500$\n• **La Ametralladora**: 1.000$\n• **BTC Storm Rider**: 2.000$\n\n*Nota: Operamos con lotajes mínimos de 0.01. Tener este capital te permite aguantar retrocesos del mercado con seguridad.*"
    },
    {
        keywords: ["mql5 vs mql4", "por que mt5", "por qué mt5", "funciona en mt4", "metatrader 4"],
        response: "⚙️ **¿Por qué usamos MetaTrader 5 (MT5)?**\n\nMT5 es el estándar moderno. Es más rápido, permite ejecutar más hilos en el procesador y su probador de estrategias (Backtest) es infinitamente más preciso que el de MT4. \n\nNo desarrollamos para MT4 porque es una plataforma obsoleta para el trading algorítmico institucional."
    },
    {
        keywords: ["varios graficos", "varias cuentas", "mas de un bot", "más de un bot", "combinar", "varios bots a la vez"],
        response: "🔀 **¿Puedo usar varios bots a la vez?**\n\n¡Por supuesto! \n1. Abre un gráfico para cada par (ej. uno de Oro y otro de Euro).\n2. Arrastra a cada uno su respectivo bot.\n3. Asegúrate de tener capital suficiente para ambos.\n\nCada bot operará de forma independiente sin estorbar al otro."
    },
    {
        keywords: ["ajustes", "parametros", "parámetros", "cambiar lotaje", "riesgo", "configuracion", "configuración"],
        response: "🛠️ **Personalización (Inputs):**\n\nAl arrastrar el bot, verás una pestaña de **'Parámetros de Entrada'**. Aquí puedes:\n• Ajustar el **Lotaje** (recomendamos 0.01).\n• Activar/Desactivar el **Auto-Hedge**.\n• Cambiar el **Daily Stop Loss**.\n\nVienen optimizados por defecto, pero tú tienes el control final."
    }
];

const DEFAULT_RESPONSE = "Hmm, no tengo esa respuesta exacta en mi memoria 🤖. He aprendido mucho sobre **instalación, brokers, gestión de riesgo, VPS y el estado del bot (fin de semana/dormir)**.\n\nIntenta preguntarme algo más específico de estos temas, o escribe **'soporte'** para hablar directamente con una persona de nuestro equipo.";

function getBotResponse(input: string): string {
    const lower = input.toLowerCase()
        .normalize("NFD")
        .replace(/[\u0300-\u036f]/g, ""); // Quitar acentos
    
    let bestMatch: { response: string; score: number } | null = null;
    
    for (const item of BOT_RESPONSES) {
        let score = 0;
        for (const kw of item.keywords) {
            const cleanKw = kw.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
            if (cleanKw.length > 3) {
                if (lower.includes(cleanKw)) {
                    score += cleanKw.split(" ").length * 5; // Más palabras = más score
                }
            } else {
                const reg = new RegExp(`\\b${cleanKw}\\b`);
                if (reg.test(lower)) {
                    score += 5;
                }
            }
        }
        
        if (score > 0 && (!bestMatch || score > bestMatch.score)) {
            bestMatch = { response: item.response, score: score };
        }
    }
    
    if (bestMatch && bestMatch.score >= 5) {
        return bestMatch.response;
    }
    
    // Búsqueda de raíces secundaria
    const roots = [
        { root: "descarg", block: "descargar" },
        { root: "instal", block: "instalar" },
        { root: "pag", block: "pago" },
        { root: "vps", block: "vps" },
        { root: "broker", block: "broker" },
        { root: "oro", block: "ametralladora" },
        { root: "xau", block: "ametralladora" },
        { root: "bitcoin", block: "bitcoin" },
        { root: "btc", block: "bitcoin" },
        { root: "eur", block: "euro" },
        { root: "yen", block: "yen" },
        { root: "jpy", block: "yen" },
        { root: "gratis", block: "gratis" },
        { root: "demo", block: "gratis" },
        { root: "bot", block: "que bots hay" },
        { root: "robot", block: "que bots hay" },
        { root: "compr", block: "pago" },
        { root: "dorm", block: "dormir" },
        { root: "noche", block: "dormir" },
        { root: "ayud", block: "no funciona" },
        { root: "error", block: "no funciona" },
        { root: "soport", block: "contacto" }
    ];

    for (const r of roots) {
        if (lower.includes(r.root)) {
            const match = BOT_RESPONSES.find(item => item.keywords.some(kw => kw.toLowerCase().includes(r.block)));
            if (match) return match.response;
        }
    }
    
    return DEFAULT_RESPONSE;
}

interface Message {
    from: "user" | "bot";
    text: string;
    time: string;
}

function speakText(text: string) {
    if (typeof window === "undefined" || !window.speechSynthesis) return;

    window.speechSynthesis.cancel();

    let cleanText = text
        .replace(/[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F1E6}-\u{1F1FF}\u{1F004}\u{1F0CF}\u{1F170}-\u{1F251}]/gu, '')
        .replace(/\*\*/g, '')
        .replace(/\|/g, '')
        .replace(/—/g, '')
        .replace(/→/g, ' y luego en ')
        .replace(/['"`]/g, '')
        .replace(/\.mq5/gi, ' eme cu cinco ')
        .replace(/MQL5/gi, ' eme cu ele cinco ')
        .replace(/MT5/gi, ' Meta Trader 5 ')
        .replace(/MT4/gi, ' Meta Trader 4 ')
        .replace(/\bH1\b/gi, ' Hache 1 ')
        .replace(/\bH4\b/gi, ' Hache 4 ')
        .replace(/\bM5\b/gi, ' Eme 5 ')
        .replace(/\bM30\b/gi, ' Eme 30 ')
        .replace(/\n+/g, '. ');

    // Forzar pronunciación correcta para que no lo deletree "K O P Y T R A D I N G"
    cleanText = cleanText
        .replace(/KOPYTRADING/g, 'Kopy Trading')
        .replace(/KopyTrading/gi, 'Kopy Trading')
        .replace(/KopyBot/gi, 'Kopy Bot');

    const utterance = new SpeechSynthesisUtterance(cleanText);
    utterance.lang = 'es-ES';
    utterance.rate = 1.0;
    utterance.pitch = 0.9;

    // Intentar buscar una voz masculina en español
    const voices = window.speechSynthesis.getVoices();
    const esVoices = voices.filter(v => v.lang.startsWith('es'));
    const maleVoice = esVoices.find(v =>
        v.name.toLowerCase().includes('pablo') ||
        v.name.toLowerCase().includes('alonso') ||
        v.name.toLowerCase().includes('federico') ||
        v.name.toLowerCase().includes('male') ||
        v.name.toLowerCase().includes('hombre') ||
        v.name.toLowerCase().includes('diego') ||
        v.name.toLowerCase().includes('carlos')
    );

    if (maleVoice) {
        utterance.voice = maleVoice;
    } else if (esVoices.length > 0) {
        // Evitar explícitamente voces de femeninas típicas de Microsoft si es posible
        const otherMale = esVoices.find(v => !v.name.toLowerCase().includes('helena') && !v.name.toLowerCase().includes('laura') && !v.name.toLowerCase().includes('zira') && !v.name.toLowerCase().includes('sabella'));
        if (otherMale) utterance.voice = otherMale;
        else utterance.voice = esVoices[0]; // fallback total
    }

    window.speechSynthesis.speak(utterance);
}

export default function FloatingChat() {
    const [open, setOpen] = useState(false);
    const [input, setInput] = useState("");
    const [voiceEnabled, setVoiceEnabled] = useState(true);
    const [isListening, setIsListening] = useState(false);
    const [messages, setMessages] = useState<Message[]>([
        {
            from: "bot",
            text: "¡Hola! Soy KopyBot 🤖, el asistente experto de KopyTrading. ¿En qué puedo ayudarte hoy? Pregúntame sobre bots, trading, instalación o brokers.",
            time: new Date().toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' })
        }
    ]);
    const [typing, setTyping] = useState(false);
    const bottomRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        bottomRef.current?.scrollIntoView({ behavior: "smooth" });
    }, [messages, typing]);

    // Handle initial greeting voice if opened and voice was enabled
    useEffect(() => {
        if (open && voiceEnabled && messages.length === 1) {
            speakText(messages[0].text);
        }
    }, [open]);

    // Speech-to-Text Microphone toggle
    const toggleListen = () => {
        const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
        if (!SpeechRecognition) {
            alert("Tu navegador no soporta dictado por voz. Recomendamos Chrome o Edge.");
            return;
        }

        if (isListening) return; // Ya está escuchando

        const recognition = new SpeechRecognition();
        recognition.lang = 'es-ES';
        recognition.continuous = false;
        recognition.interimResults = false;

        recognition.onstart = () => {
            setIsListening(true);
        };

        recognition.onresult = (event: any) => {
            const transcript = event.results[0][0].transcript;
            setInput(prev => prev ? `${prev} ${transcript}` : transcript);
            setIsListening(false);
        };

        recognition.onerror = (event: any) => {
            console.error("Error en reconocimiento de voz: ", event.error);
            setIsListening(false);
        };

        recognition.onend = () => {
            setIsListening(false);
        };

        recognition.start();
    };

    function sendMessage() {
        if (!input.trim()) return;
        const userMsg: Message = { from: "user", text: input, time: new Date().toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' }) };
        setMessages(prev => [...prev, userMsg]);
        setInput("");
        setTyping(true);
        setTimeout(() => {
            const response = getBotResponse(input);
            setMessages(prev => [...prev, { from: "bot", text: response, time: new Date().toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' }) }]);
            if (voiceEnabled) {
                speakText(response);
            }
            setTyping(false);
        }, 900 + Math.random() * 600);
    }

    return (
        <>
            {/* Botón flotante */}
            <button
                onClick={() => setOpen(!open)}
                className="fixed bottom-6 right-6 z-[999] w-14 h-14 rounded-full bg-gradient-to-br from-brand-light to-brand shadow-[0_0_30px_rgba(139,92,246,0.6)] flex items-center justify-center text-2xl hover:scale-110 transition-transform animate-pulse-glow"
                title="Chat con KopyBot"
            >
                {open ? "✕" : "🤖"}
            </button>

            {/* Panel del chat */}
            {open && (
                <div className="fixed bottom-20 sm:bottom-24 left-4 right-4 sm:left-auto sm:right-6 z-[998] sm:w-[350px] glass-card border border-brand/30 rounded-2xl shadow-[0_0_50px_rgba(139,92,246,0.3)] flex flex-col overflow-hidden" style={{ height: '440px', maxHeight: '70vh' }}>
                    {/* Header */}
                    <div className="bg-gradient-to-r from-brand-dark to-brand p-4 flex items-center justify-between gap-3 flex-shrink-0">
                        <div className="flex items-center gap-3 min-w-0">
                            <div className="w-10 h-10 rounded-full bg-white/20 flex items-center justify-center text-xl flex-shrink-0">🤖</div>
                            <div className="min-w-0">
                                <div className="font-semibold text-white text-sm truncate">KopyBot — Asistente</div>
                                <div className="text-xs text-white/60 flex items-center gap-1">
                                    <span className="w-1.5 h-1.5 rounded-full bg-success inline-block flex-shrink-0"></span>
                                    <span className="truncate">Disponible ahora</span>
                                </div>
                            </div>
                        </div>
                        <button
                            onClick={() => {
                                setVoiceEnabled(!voiceEnabled);
                                if (voiceEnabled && window.speechSynthesis) {
                                    window.speechSynthesis.cancel();
                                }
                            }}
                            className="w-11 h-11 flex-shrink-0 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center text-white transition-colors text-xl ml-2 shadow-lg"
                            title={voiceEnabled ? "Desactivar voz" : "Activar voz"}
                        >
                            {voiceEnabled ? "🔊" : "🔇"}
                        </button>
                    </div>

                    {/* Mensajes */}
                    <div className="flex-1 overflow-y-auto p-4 space-y-3 bg-bg-dark/80">
                        {messages.map((msg, i) => (
                            <div key={i} className={`flex ${msg.from === "user" ? "justify-end" : "justify-start"}`}>
                                {msg.from === "bot" && (
                                    <div className="w-7 h-7 rounded-full bg-brand/40 flex items-center justify-center text-sm mr-2 flex-shrink-0 mt-1">🤖</div>
                                )}
                                <div className={`max-w-[75%] rounded-2xl px-3 py-2 text-xs leading-relaxed whitespace-pre-line ${msg.from === "user"
                                    ? "bg-brand text-white rounded-tr-md"
                                    : "bg-surface-light border border-white/10 text-text-muted rounded-tl-md"
                                    }`}>
                                    {msg.text}
                                    <div className={`text-[10px] mt-1 ${msg.from === "user" ? "text-white/50 text-right" : "text-text-muted/50"}`}>{msg.time}</div>
                                </div>
                            </div>
                        ))}
                        {typing && (
                            <div className="flex justify-start">
                                <div className="w-7 h-7 rounded-full bg-brand/40 flex items-center justify-center text-sm mr-2">🤖</div>
                                <div className="bg-surface-light border border-white/10 rounded-2xl rounded-tl-md px-4 py-3">
                                    <div className="flex gap-1 items-center">
                                        <span className="w-1.5 h-1.5 rounded-full bg-brand animate-bounce" style={{ animationDelay: '0ms' }}></span>
                                        <span className="w-1.5 h-1.5 rounded-full bg-brand animate-bounce" style={{ animationDelay: '150ms' }}></span>
                                        <span className="w-1.5 h-1.5 rounded-full bg-brand animate-bounce" style={{ animationDelay: '300ms' }}></span>
                                    </div>
                                </div>
                            </div>
                        )}
                        <div ref={bottomRef} />
                    </div>

                    {/* Input */}
                    <div className="p-3 border-t border-white/10 flex gap-2 flex-shrink-0 bg-bg-dark/90 items-end">
                        <button
                            onClick={toggleListen}
                            className={`w-9 h-9 rounded-full flex items-center justify-center flex-shrink-0 transition-colors mb-1 ${isListening ? "bg-red-500 text-white animate-pulse" : "bg-surface-light hover:bg-white/10 text-white/70"}`}
                            title={isListening ? "Escuchando..." : "Hablar por micrófono"}
                        >
                            🎤
                        </button>
                        <textarea
                            value={input}
                            onChange={e => setInput(e.target.value)}
                            onKeyDown={e => {
                                if (e.key === "Enter" && !e.shiftKey) {
                                    e.preventDefault();
                                    sendMessage();
                                }
                            }}
                            placeholder={isListening ? "Escuchando..." : "Escribe tu pregunta..."}
                            className="flex-1 bg-surface-light border border-white/10 rounded-xl px-3 py-2 text-xs text-white placeholder-text-muted outline-none focus:border-brand/60 transition-colors resize-none overflow-y-auto min-h-[36px] max-h-[80px]"
                            rows={input.length > 35 ? 3 : (input.length > 15 ? 2 : 1)}
                        />
                        <button
                            onClick={sendMessage}
                            className="w-9 h-9 flex-shrink-0 rounded-xl bg-brand flex items-center justify-center text-white hover:bg-brand-light transition-colors text-sm mb-1"
                        >➤</button>
                    </div>
                </div>
            )}
        </>
    );
}

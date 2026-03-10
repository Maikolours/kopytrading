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
        keywords: ["cuándo abre", "cuando abre", "no abre", "no opera", "operacion", "operación", "señal", "esperar", "cuánto tiempo", "cuanto tiempo", "no hace nada"],
        response: "⏳ **¿Por qué el bot no abre operaciones?**\n\nEste bot usa algoritmos estrictos. Si la vela no cumple los parámetros milimétricos, NO abre. Esto te protege del sobre-apalancamiento y de operaciones falsas.\n\n🔵 Es NORMAL que esté horas o incluso varios días (en el caso de H1/H4) sin abrir nada. La paciencia es la cualidad #1 de un inversor algorítmico disciplinado."
    },
    {
        keywords: ["ametralladora", "xauusd", "oro", "gold"],
        response: "🔥 **La Ametralladora (XAUUSD)** — El más popular\n\n• Temporalidad: **M15**\n• Estrategia: Scalping + Hedge Inteligente\n• Horario: 9h - 21h\n• Objetivo por operación: $5\n• Break Even: a los $2\n• Capital mínimo: 1.000$\n• Riesgo: Medio\n• Precio: 249€ (pago único)\n\n⚠️ El Oro es súper volátil. Usa siempre lotaje 0.01 por cada 1.000$."
    },
    {
        keywords: ["euro", "precision", "eurusd", "eur"],
        response: "🎯 **Euro Precision Flow (EURUSD)** — El más seguro\n\n• Temporalidad: **H1**\n• Estrategia: Cruce de EMA 21/50 + Filtro RSI\n• Horario: 8h - 20h\n• Capital mínimo: 500$\n• Riesgo: BAJO ✅\n• Precio: 179€ (pago único)\n\n💡 Puede tardar días en abrir porque espera la alineación perfecta del cruce institucional (H1)."
    },
    {
        keywords: ["yen", "usdjpy", "ninja", "jpy", "asia", "asiática", "asiatica"],
        response: "🥷 **Yen Ninja Ghost (USDJPY)** — Operativa nocturna\n\n• Temporalidad: **M30**\n• Estrategia: Rebote Bollingers + RSI\n• Horario: 0h - 8h (noche europea)\n• Capital mínimo: 500$\n• Riesgo: Medio\n• Precio: 149€ (pago único)\n\n🌙 Perfecto para aprovechar los rangos aburridos de la sesión asiática."
    },
    {
        keywords: ["bitcoin", "btc", "crypto", "cripto", "storm"],
        response: "⚡ **BTC Storm Rider (BTCUSD)** — Solo para verdaderos expertos\n\n• Temporalidad: **H4 o M30 según set**\n• Estrategia: Breakout/Tendencia Fuerte\n• Horario: 24/7\n• Capital mínimo: 2.000$\n• Riesgo: ALTO ⚠️\n• Precio: 299€ (pago único)\n\nDiseñado para capturar la enorme inercia y volatilidad de la criptomoneda madre."
    },
    {
        keywords: ["precio", "cuánto cuesta", "cuanto cuesta", "costo", "coste", "todos", "comparar"],
        response: "💰 **Precios de las Licencias Universales (Pago Único):**\n\n• La Ametralladora (XAUUSD) — 249€\n• Euro Precision Flow (EURUSD) — 179€\n• Yen Ninja Ghost (USDJPY) — 149€\n• BTC Storm Rider (BTCUSD) — 299€\n\nIncluye licencia ilimitada en el tiempo para la cuenta, actualizaciones futuras gratis y soporte técnico."
    },
    {
        keywords: ["vps", "servidor", "cloud", "siempre encendido", "apago el ordenador", "se apaga", "nube"],
        response: "🖥️ **¿Es obligatorio el VPS?**\n\nSÍ, en el 99% de los casos. Si tu ordenador de casa se apaga, la línea de internet se cae o Windows se actualiza, MT5 se cierra. Si MT5 se cierra, el bot se desconecta de la bolsa.\n\nPara no quedar con operaciones expuestas sin el escudo del 'Break Even', sugerimos un VPS barato como *Contabo* (aprox 5€/mes) encendido 24h sin molestarte."
    },
    {
        keywords: ["broker", "vantage", "vtmarkets", "pepperstone", "ic markets", "dónde", "donde", "qué broker", "que broker", "mt5 broker"],
        response: "🏦 **Brokers 100% Compatibles con KopyTrading:**\n\n• **Vantage Markets**: Gran broker ECN, sin limites en XAU.\n• **Pepperstone**: Extrema liquidez, ideal para bots (Regulado EU/US/AU).\n• **IC Markets**: Favorito mundial por latencia hiperbaja.\n• **VT Markets**: Muy buena ejecución de pares Forex.\n\n(Recomendamos usar tipos de cuenta 'RAW' o 'PRO' para tener spreads desde 0.0 pips)."
    },
    {
        keywords: ["licencia", "clave", "número de cuenta", "cuenta mt5", "cómo activar", "autorizada", "identidad"],
        response: "🔐 **Sistema de Protección Activo:**\n\nEl archivo comercial del bot se vincula a tu código de Cuenta particular de MetaTrader. Solo debes escribir este nº en las propiedades del bot, sección **'CuentaDemo'** o **'CuentaReal'**.\n\n👉 De esta manera, nadie podrá robar tu inversión. Al arrastrarlo al gráfico él se autorizará automáticamente."
    },
    {
        keywords: ["instalar", "instalación", "mt5", "metatrader", "cómo lo instalo", "archivos", "mq5"],
        response: "📋 **Puesta a punto (MetaTrader 5):**\n\n1. En MT5: Archivo → Abrir carpeta de datos.\n2. Ve a MQL5 → Experts y pega ahí el archivo `.mq5`\n3. Presiona F4 para abrir el Compilador MetaEditor.\n4. Presiona F7 para Compilarlo. (Sin errores).\n5. ¡Listo! Vuelve a MT5, activa el AutoTrading (botón de arriba) y arrastra el experto al gráfico."
    },
    {
        keywords: ["gratis", "demo", "trial", "mes gratis", "free", "prueba"],
        response: "🆓 **Licencias Demo (Ilimitadas)**\n\nPor el momento regalamos la evaluación en Tiempo Real (Prueba Gratuita).\nPuedes ir a descargar cualquier robot y conectarlo tranquilamente a tu cuenta Demo de MetaTrader5 y observar su comportamiento sin límite de días y sin pagar nada.\n\n¡Queremos clientes convencidos antes de usar euros reales!"
    },
    {
        keywords: ["pago", "comprar", "stripe", "paypal", "bizum", "cómo pago", "tarjeta", "pagar"],
        response: "💳 **Métodos de Compra:**\n\nPronto implementaremos Stripe directo, PayPal Express y otras pasarelas.\nSi no puedes esperar a llevarte un bot para tu cuenta Real, contáctanos en **soporte@kopytrading.com** y te habilitamos el pago manual mediante tarjeta, transferencia o wallet cripto."
    },
    {
        keywords: ["no funciona", "error", "problema", "ayuda", "bug", "fallo", "cuenta no autorizada"],
        response: "🔧 **Diagnóstico de Problemas Técnicos:**\n\n1. **'Invalid License / Cuenta no autorizada'**: Verifica que no haya espacios al poner tu Nº de cuenta en los Ajustes del bot.\n2. **'AutoTrading deshabilitado'**: Dale al icono de AutoTrading en MT5 (arriba al centro, debe tener play verde).\n3. **'No abre nada'**: Asegúrate que el mercado esté abierto y estás en la gráfica correcta (Oro, Euro..).\nParecen tonterías, pero suele ser la solución al 90%."
    },
    {
        keywords: ["qué es kopytrade", "quiénes sois", "sobre vosotros", "la empresa", "kopytrade"],
        response: "🏢 **Sobre nosotros KopyTrading:**\n\nEvitamos los sistemas piramidales, las mensualidades, las Martingalas destructivas y el marketing vende-húmos.\n\nSolo proporcionamos algoritmos matemáticos probados, que nosotros mismos operamos, directamente de las manos del desarrollador a la gráfica del trader. Trading puro, duro y aburrido (consistente)."
    },
    {
        keywords: ["break even", "breakeven", "empate", "proteger"],
        response: "🛡️ **Sistema Break Even (BE):**\n\nNuestra regla de oro. Si la operación va ganando X dólares, el Bot bloquea la posición y mueve el Stop Loss exactamente a tu punto de entrada.\n\n✅ Desde ese instante el saldo de esa operación NUNCA pasará a ser negativo. Estarás matemáticamente blindado ante cualquier retroceso."
    },
    {
        keywords: ["trailing stop", "trailing", "perseguir", "asegurar"],
        response: "📉 **Trailing Stop Dinámico:**\n\nNo dejamos el Stop Loss fijo abajo mientras el precio sube al infinito.\nEl algoritmo lo arrastra dinámicamente varios pips por detrás del precio actual. Si se gira agresivamente el mercado, la operación se cortará de golpe con toda la caja en verde que haya acumulado durante el trayecto."
    },
    {
        keywords: ["apalancamiento", "leverage", "margen", "aplancado"],
        response: "⚖️ **Guía de Apalancamiento:**\n\nTe recomendamos seleccionar apalancamiento 1:100 o 1:200 en tu Broker.\nOjo: Apalancamiento NO es riesgo extra si usas nuestro Stop Loss y los lotes (0.01) correctamente.\nEl apalancamiento solo sirve para que el broker no retenga el 80% de tus fondos de Free Margin cada vez que el Bot accione."
    },
    {
        keywords: ["lote", "lotaje", "tamaño", "volumen", "0.01"],
        response: "📏 **Control del Gran Lotaje Matemático:**\n\nNunca subestimes un mal dimensionamiento.\nInicia siempre operando con volumén **0.01 Lotes** por cada 500$-1000$ que tengas fondeados en la gráfica. Ese es el único colchón que evitará la quema bajo Drawdowns extremos."
    },
    {
        keywords: ["mac", "apple", "macbook", "macos", "ipad"],
        response: "🍎 **MetaTrader en Ecosistema MAC**\n\nMT5 está nativamente programado para Windows. No obstante:\nOpción A: Usa la capa Parallels Desktop/CrossOver.\nOpción B (Nuestra Favorita): Contrátate un VPS Windows y usa Microsoft Remote Desktop. Verás a la perfección tu Windows con el bot desde tu Mac impecablemente fluido."
    },
    {
        keywords: ["fondeo", "prop firm", "ftmo", "evaluación", "funding", "darwinex", "pass"],
        response: "🏆 **Apto para Firmas de Fondeo (Prop Firms):**\n\nAbsolutamente. Todos los Bots usan Stop Loss estrictos sin promedios Martingala. Cumplirás perfectamente los mandatos del 'Daily Maximum Loss Drawdown' requeridos para superar los Exámenes y Challenges de FTMO o MyForexFunds."
    },
    {
        keywords: ["martingala", "martingale", "grid", "cuadricula", "promediar", "martingalas"],
        response: "⚠️ **Cero exposición infinita (No Martingalas suicidas):**\n\nTodos nuestros bots rechazan la clásica Martingala exponencial.\nAlgunos usan Hedge escalonado minúsculo, pero todos (sin excepción) cortan con un Stop Loss Duro general de Equity. Cuando nos equivocamos, nos equivocamos, perdemos el 1-2% del account y a seguir. Sobrevivimos."
    },
    {
        keywords: ["drawdown", "retroceso", "flotante", "negativo", "baja la cuenta"],
        response: "📉 **El inevitable Drawdown (DD):**\n\nTodo algoritmo tendrá DD. Es el flotante negativo aguantado temporalmente. Nuestros perfiles arrojan Drawdowns calculados entre un 5% y 20% histórico anual (teniendo muy buena protección institucional)."
    },
    {
        keywords: ["noticias", "news", "nfp", "ipc", "cpi", "powell", "noticia"],
        response: "📰 **Impacto de las Noticias Macro:**\n\nNivel rojo (Powell, NFP). En estas franjas el spread del oro o del euro puede triplicarse y saltarse tus defensas.\nRecomendación de oro: Pulsa off al Bot 60 mins antes y préndelo 60 mins después de la intervención fundamental."
    },
    {
        keywords: ["mt4", "metatrader 4", "mq4"],
        response: "⚙️ **Obsolescencia Técnica de MetaTrader 4:**\n\nKopyTrading desarrolla nativamente al 100% en `MQL5` para MetaTrader 5 porque es el futuro estándar de las instituciones y su Tester genético multithread está a años luz de las barrabasadas arcaicas de MT4."
    },
    {
        keywords: ["movil", "móvil", "android", "iphone", "celular", "app"],
        response: "📱 **Acceso vía Smartphones:**\n\nNo puedes inyectar un robot en la App Móvil de MetaTrader (MetaQuotes lo bloquea por arquitectura). Usa tu PC o tu VPS para alojar el `Bot.mq5`.\nEso sí, luego podrás ver desde el móvil a tiempo real en el sofá los rendimientos maravillosos abriendo tú solo a leer la operación."
    },
    {
        keywords: ["rentabilidad", "ganancia", "cuanto gano", "porcentaje", "mensual", "roi"],
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
        response: "↩️ **Política de Código Abierto (Sin DRM Intrusivos):**\n\nEntregamos código MQ5 encriptado y limpio, listo para rodar.\nDado su formato de producto enteramente digital sin desvinculación comprobable... NO ejecutamos reembolsos de compras. Úsalos gratis durante milenios en tu DEMO y paga si se adaptan a tí."
    },
    {
        keywords: ["actualización", "update", "versión nueva", "version", "upgrade"],
        response: "🔄 **Mantenimiento Cero Costes Ocultos:**\n\nNuestro panel de control está alimentado por DB moderna, en cuanto despachemos una variante v3 del Ametralladora para mejorar eficiencia... los compradores anteriores se lo bajan de su Dashboard GRATIS por siempre."
    },
    {
        keywords: ["soporte", "contacto", "email", "ticket", "hablar con"],
        response: "📩 **Contacto y Asistencia Personal de Traders para Traders:**\n\nMándanos tu duda, captura de logs técnicos, capturas del terminal.. no te cortes, estamos para ti 24h a soporte@kopytrading.com y tu caso será mirado bajo lupa (Sin IA intermedio, soporte humano 100%)."
    },
    {
        keywords: ["cuál opera más", "quien opera más", "cual opera mas", "mas veces", "más operaciones", "mayor frecuencia", "opera mucho", "más rápido", "mas rapido", "el bot mas rapido", "el más rápido"],
        response: "⚡ **¿Cuál es el bot más rápido en operar?**\n\nEl bot más rápido y activo es **La Ametralladora (XAUUSD)**. Su nombre no es casualidad; al operar en gráficos de M15 y especializarse en Scalping en un par tan volátil como el Oro, tenderá a buscar muchísimas micro-entradas durante su ventana horaria.\n\n*(Recuerda que mayor rapidez también implica mayor estrés operativo, usa siempre lotes mínimos de 0.01 si empiezas con este).* "
    },
    {
        keywords: ["menos riesgo", "más seguro", "mas seguro", "menor riesgo", "conservador", "cual arriesga menos", "qué bot es más seguro"],
        response: "🛡️ **¿Cuál es el bot con menor riesgo?**\n\nEl más seguro y conservador es el **Euro Precision Flow (EURUSD)**. \n\n¿El motivo? Opera en temporalidad institucional de H1 (1 hora) y sobre el Euro-Dólar, que es el mercado más maduro y estable. Tarda en ver una oportunidad matemática, por lo que hace menos operaciones al mes, pero sus entradas son extremadamente filtradas y seguras."
    },
    {
        keywords: ["cuántas operaciones hace", "cuantas operaciones hace", "frecuencia de cada", "qué frecuencia", "cuánto tarda cada"],
        response: "⏱️ **Frecuencia de Operaciones de nuestros Bots:**\n\n• **La Ametralladora (XAUUSD):** Puede hacer de 2 a 5 operaciones en un mismo día activo.\n• **Yen Ninja Ghost (USDJPY):** Hace entre 3 y 8 operaciones por *semana* (solo actúa de noche).\n• **Euro Precision Flow (EURUSD):** Hace entre 1 y 3 operaciones por *semana* (alta precisión analítica).\n• **BTC Storm Rider (BTCUSD):** Puede estar 2 semanas sin hacer nada, y de repente abrir 4 operaciones seguidas si hay un breakout fuerte de precio Crypto."
    },
    {
        keywords: ["ganar más dinero", "que más dinero", "que mas dinero", "gana más", "gana mas", "más beneficios", "mas beneficios", "más rentable", "mas rentable", "el que más gana", "mayor beneficio", "mejor rendimiento"],
        response: "💸 **¿Con cuál bot se puede llegar a ganar más dinero?**\n\nEn términos de potencial bruto (pura velocidad y agresividad del precio), tanto **La Ametralladora (Oro)** como el **BTC Storm Rider (Bitcoin)** son los que mayores sacudidas de beneficios diarios pueden dar si enganchan bien una racha tendencial. \n\n⚠️ PERO OJO: Los bots que más dinero pueden generar también son siempre los que mayor Drawdown (riesgo de caída temporal) asumen. La recompensa siempre es proporcional al riesgo. Para ganar más, debes estar dispuesto psicológicamente a ver los números rojos bailar más fuerte."
    },
    {
        keywords: ["capital asegurado", "asegurado el capital", "seguro de perdida", "pierdo mi dinero", "perderlo todo", "garantizado", "riesgo cero", "riesgo 0", "capital protegido", "mi dinero está seguro", "esta asegurado"],
        response: "🛑 **Aviso sobre el Capital y el Riesgo:**\n\n**NO. EL CAPITAL NO ESTÁ ASEGURADO BAJO NINGÚN CONCEPTO.** \nEl Trading algorítmico o manual es una actividad de muy alto riesgo financiero. Quien te diga que tu capital está 100% asegurado en los mercados financieros, te está mintiendo o intentando estafar.\n\nNuestros bots usan *Stop Loss* estrictos y escudos de *Break Even* muy avanzados para PROTEGERTE e intentar evitar la quiebra total de tu cuenta ante un día nefasto, pero en cada operación arriesgas un % real de tu cuenta. Solo opera con aquel dinero del que no dependa tu vida ni tus facturas."
    }
];

const DEFAULT_RESPONSE = "Hmm, pues no tengo nada específico para eso en mi base de datos de momento, pero puedes revisar con calma nuestra sección de **FAQ** (Preguntas Frecuentes) donde casi seguro que encuentras la información que necesitas. ¿Puedo ayudarte con otra cosa sobre bots de trading?";

function getBotResponse(input: string): string {
    const lower = input.toLowerCase();
    for (const item of BOT_RESPONSES) {
        if (item.keywords.some(k => lower.includes(k))) {
            return item.response;
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
        .replace(/\bM15\b/gi, ' Eme 15 ')
        .replace(/\bM30\b/gi, ' Eme 30 ')
        .replace(/\n+/g, '. ');

    // Forzar pronunciación correcta para que no lo deletree "K O P Y T R A D I N G"
    cleanText = cleanText
        .replace(/KOPYTRADING/g, 'Copy Trade')
        .replace(/KopyTrading/gi, 'Copy Trade')
        .replace(/KopyTrading/gi, 'Copy Trading')
        .replace(/KopyBot/gi, 'Copy Bot');

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

"use client";

import { useState, useRef, useEffect } from "react";

const BOT_RESPONSES: { keywords: string[]; response: string }[] = [
    {
        keywords: ["hola", "hello", "buenas", "hey", "qué tal", "que tal", "saludos"],
        response: `¡Hola! Soy KopyBot 🤖, el asistente experto de KopyTrading. Puedo ayudarte con consultas técnicas sobre nuestros algoritmos **MAIKO PRO GOLD** (en M15), **MAIKO CENT** (M15), **MAIKO DEMO** (M15), MetaTrader 5, VPS, brokers y gestión de riesgo. ¿En qué te puedo ayudar?`
    },
    {
        keywords: ["recomiendas", "recomienda", "empezar", "primer bot", "cuál compro", "cual compro", "para principiante", "soy nuevo", "nunca he", "novato", "recomendación", "mejor para"],
        response: `🏆 **Nuestra recomendación según tu perfil:**

1. **Si quieres probar gratis sin arriesgar dinero hoy mismo**: Activa **MAIKO SNIPER PRO GOLD DEMO** 💜 por solo 1€ durante 30 días en cuenta DEMO de MT5 en gráfico de M15.

2. **Si quieres empezar con poco capital en cuenta real ($50 - $100)**: **MAIKO SNIPER PRO GOLD CENT** ⚡ (Disponible a partir del 1 de Septiembre). Opera en cuentas CENT de MT5 en gráfico de M15.

3. **Si vas a operar con cuenta Real estándar ($500 - $1.000)**: **MAIKO SNIPER PRO GOLD (REAL)** 🏆 (Disponible a partir del 1 de Septiembre en M15).

🔥 *¡Reserva tu Oferta de Lanzamiento del 1 de Septiembre con 50% de DESCUENTO (100€ en vez de 200€)!*`
    },
    {
        keywords: ["cuándo abre", "cuando abre", "no opera", "operacion", "operación", "señal", "esperar", "cuánto tiempo", "cuanto tiempo", "no hace nada", "no abre nada", "lleva dias", "lleva días", "no mete", "cero operaciones", "ninguna operacion", "esperando"],
        response: `⏳ **¿Por qué el bot no abre operaciones en este momento?**

Es 100% normal y correcto. Nuestros algoritmos MAIKO (en gráfico M15) utilizan filtros muy estrictos (cruce de estructura M15, mechas de rechazo, spread y control de volatilidad) antes de ejecutar:

• **Horario de Operativa**: El bot opera principalmente entre las **09:00 y las 19:00 (hora del broker)**. Fuera de ese horario pone 'FUERA HORARIO: ESPERANDO' para protegerte de la baja liquidez.
• **Confirmación M15**: El bot espera la confirmación del cierre de la vela de M15 antes de entrar. Si hay noticias de alto impacto o spread elevado en el Oro, esperará a que el mercado se calme.

Ten paciencia, el algoritmo está protegiendo tu capital.`
    },
    {
        keywords: ["ametralladora", "xauusd", "oro", "gold", "maiko gold", "pro gold"],
        response: `🏆 **MAIKO SNIPER PRO GOLD (XAUUSD)** — El algoritmo estrella

• Temporalidad: **M15** (Gráfico de 15 Minutos en el Oro)
• Estrategia: Scalping de precisión institucional + Hedge Inteligente
• Horario: 09h - 19h (hora broker)
• Capital mínimo sugerido: $500 - $1.000 (0.01 lotes por cada 1.000$)
• Riesgo: Controlado con Stop Loss de Equidad

🚀 **Lanzamiento Oficial: 1 de Septiembre de 2026**
🔥 **Oferta Especial:** **100€** (50% de descuento sobre el precio regular de 200€) para las primeras 50 licencias.

🎁 **¿Quieres probarlo hoy mismo?** Puedes activar ya la versión DEMO en M15 por 1€ durante 30 días.`
    },
    {
        keywords: ["cent", "micro", "bajo capital", "50$", "100$", "cuenta cent", "cuentas cent"],
        response: `⚡ **MAIKO SNIPER PRO GOLD CENT** — Ideal para bajos capitales

• Diseñado específicamente para cuentas **Micro / CENT** en MetaTrader 5 (Gráfico de **M15**).
• Te permite operar con **$50 a $100 reales**, ya que en la cuenta CENT $100 equivalen a 10.000 centavos.
• Mantiene exactamente la misma lógica matemática del bot estrella MAIKO GOLD adaptada a la precisión de micro-lotes.

🚀 **Disponible a partir del 1 de Septiembre de 2026** por solo **100€** (Antes 200€).`
    },
    {
        keywords: ["bitcoin", "btc", "crypto", "cripto", "storm"],
        response: `₿ **MAIKO SNIPER PRO BTC (BTCUSD)** — Volatilidad Cripto

• Temporalidad: **M30 / H1**
• Estrategia: Breakout & Inercia de volatilidad en Bitcoin
• Capital mínimo: $1.500 - $2.000
• Riesgo: Medio-Alto (debido a la gran volatilidad del Bitcoin)

Ideal para diversificar tu portafolio junto con el bot de Oro.`
    },
    {
        keywords: ["precio", "cuánto cuesta", "cuanto cuesta", "costo", "coste", "oferta", "descuento", "septiembre", "comprar", "pagar", "licencia", "pago"],
        response: `💰 **Precios y Lanzamiento el 1 de Septiembre:**

🚀 **LANZAMIENTO OFICIAL (1 DE SEPTIEMBRE) CON -50% DESCUENTO:**
• **MAIKO SNIPER PRO GOLD (REAL)**: **100€** *(Precio regular 200€ - Disponible 1 Sept)*
• **MAIKO SNIPER PRO GOLD CENT**: **100€** *(Precio regular 200€ - Disponible 1 Sept)*

💜 **DISPONIBLE HOY MISMO EN PRUEBA:**
• **MAIKO PRO GOLD DEMO**: **1€** por **30 días de prueba** en cuenta DEMO de MT5 (en gráfico M15).

Las licencias de venta oficial se abren el 1 de Septiembre e incluirán soporte técnico, guías PDF y **actualizaciones futuras 100% gratuitas** desde tu panel.`
    },
    {
        keywords: ["vps", "servidor", "cloud", "siempre encendido", "apago el ordenador", "se apaga", "nube", "contabo", "hosting", "computadora", "vps servidor"],
        response: `🖥️ **¿Es obligatorio el VPS (Servidor en la Nube)?**

**SÍ, es altamente recomendable.** Si tu PC personal se suspende, se apaga o pierde internet, MetaTrader 5 se cerrará y el bot no podrá gestionar las posiciones abiertas.

👉 **Recomendamos Contabo (plan VPS S)** o cualquier VPS Windows por unos 5-6€ al mes. Deja tu MT5 encendido 24/7 de forma 100% segura.`
    },
    {
        keywords: ["broker", "vantage", "vtmarkets", "pepperstone", "ic markets", "dónde", "donde", "qué broker", "que broker", "mt5 broker", "brokers"],
        response: `🏦 **Brokers 100% Compatibles con KopyTrading:**

• **Vantage Markets**: Excelente ejecución ECN para Oro (M15) y Cuentas CENT.
• **VT Markets**: Muy recomendado para cuentas CENT y estándar.
• **Pepperstone**: Latencia hiperbaja y regulación oficial.
• **IC Markets**: Ideal para cuentas ECN/RAW.

(Recomendamos usar tipos de cuenta 'RAW', 'PRO' o 'CENT' para tener spreads bajos y la mejor ejecución).`
    },
    {
        keywords: ["licencia", "clave", "número de cuenta", "cuenta mt5", "cómo activar", "autorizada", "identidad", "autorizar", "vinculo", "vincular", "mi cuenta", "numero de cuenta"],
        response: `🔐 **Sistema de Activación de Licencias:**

El bot está encriptado y se vincula directamente a tu número de Cuenta MetaTrader 5.

1. Al activar la demo o comprar (a partir del 1 de Septiembre), introduce tu Nº de Cuenta MT5 en tu panel.
2. En MT5, al arrastrar el bot al gráfico M15, pon tu número en el parámetro **'MiLicencia'**.
3. El algoritmo conectará con nuestra API en tiempo real y mostrará **'LICENCIA: ACTIVA'** en el HUD.`
    },
    {
        keywords: ["instalar", "instalación", "instalacion", "instala", "instalo", "mt5", "metatrader", "cómo lo instalo", "archivos", "mq5", "ex5", "instalar el bot", "como se usa"],
        response: `📋 **Pasos de Instalación en MetaTrader 5:**

1. En MT5: Menú **Archivo** → **Abrir carpeta de datos**.
2. Entra en \`MQL5\` → \`Experts\` y pega allí el archivo \`.ex5\` descargado.
3. Activa el botón **'Algo Trading'** en la barra superior de MT5 (icono con Play verde ▶️).
4. Abre el gráfico de **XAUUSD en M15** (15 Minutos).
5. Arrastra el bot al gráfico, introduce tu número de cuenta en 'MiLicencia' y pulsa Aceptar.

¡El panel de control (HUD) de MAIKO aparecerá en tu pantalla!`
    },
    {
        keywords: ["gratis", "demo", "trial", "mes gratis", "free", "prueba", "30 dias", "30 días", "trial 30"],
        response: `💜 **Prueba MAIKO PRO GOLD DEMO en M15 hoy mismo:**

Puedes probar la versión de prueba durante **30 días por solo 1€** en cualquier cuenta DEMO de MetaTrader 5 en gráfico de **M15**.

Es 100% idéntica en precisión al algoritmo real. Podrás comprobar su rendimiento sin arriesgar capital real antes del lanzamiento oficial del 1 de Septiembre.

🔗 [Activar Demo en el Catálogo](/bots)`
    },
    {
        keywords: ["stripe", "paypal", "bizum", "cómo pago", "tarjeta", "pagar", "metodos de pago", "métodos de pago"],
        response: `💳 **Métodos de Pago Seguros:**

Aceptamos pagos mediante **PayPal Express** y tarjeta de crédito/débito a través de **Stripe**. Recibirás el acceso a la descarga del bot y el PDF inmediatamente tras la compra.`
    },
    {
        keywords: ["no funciona", "error", "problema", "ayuda", "bug", "fallo", "cuenta no autorizada", "no se abre", "invalido", "invalid license"],
        response: `🔧 **Solución a Problemas Frecuentes:**

1. **'Cuenta No Autorizada / Licencia Inválida'**: Revisa que tu número de cuenta MT5 coincida exactamente en el Dashboard y en el parámetro 'MiLicencia' (sin espacios).
2. **'AlgoTrading Deshabilitado'**: Haz clic en el botón 'Algo Trading' arriba en MT5 (debe mostrar un cuadrado verde activo).
3. **'No abre operaciones'**: Verifica si estás en la gráfica de **XAUUSD M15**, si estás en horario operativo (09:00 a 19:00 broker) y que el mercado del Oro esté abierto.`
    },
    {
        keywords: ["qué es kopytrading", "quiénes sois", "sobre vosotros", "la empresa", "kopytrading", "quienes somos"],
        response: `🏢 **Sobre KopyTrading:**

Desarrollamos algoritmos institucionales de trading cuantitativo para MetaTrader 5. Sin esquemas piramidales ni marketing engañoso. Software probado, transparente y enfocado en la preservación del capital.`
    },
    {
        keywords: ["break even", "breakeven", "empate", "proteger"],
        response: `🛡️ **Protección Break Even (BE):**

Cuando una operación alcanza el objetivo de ganancia parcial, el bot mueve automáticamente el Stop Loss al punto exacto de entrada.

Desde ese momento, la operación es **100% libre de riesgo** y no podrá cerrar en pérdidas aunque el precio se gire violentamente.`
    },
    {
        keywords: ["ajustes", "parametros", "parámetros", "cambiar lotaje", "riesgo", "configuracion", "configuración", "ocultos"],
        response: `🛠️ **Parámetros y Blindaje de Seguridad:**

Por tu seguridad y para proteger la propiedad intelectual de la estrategia, los parámetros técnicos internos (distancias SOS, martingalas y flushes) vienen **100% optimizados de fábrica y blindados**.

Tú puedes ajustar cómodamente desde la ventana \`F7\`:
• **Meta de Beneficio Diario ($)**
• **Horario de Operativa**
• **Protector de Pérdida ($ / %)**
• **Lotaje Inicial** (recomendamos 0.01 por cada 1.000$ o 100$ cent)`
    },
    {
        keywords: ["control remoto", "movil", "móvil", "apagar desde el movil", "cobrar y apagar", "cerrar todo", "stop all", "tarda", "segundos", "minutos", "cerrar operaciones"],
        response: `📱 **Control Remoto desde Móvil / Tablet:**

¡Puedes controlar tu bot a distancia desde cualquier teléfono o tablet!

1. Entra a **[kopytrading.com/dashboard](https://www.kopytrading.com/dashboard)** en tu móvil.
2. Usa los botones de emergencia: **'Cobrar y Apagar'**, **'Stop All'** o **'Encender Bot'**.

⏱️ **¿Cuánto tarda en ejecutarse la orden de cierre?**
La orden se envía al instante a nuestro servidor. Tu MetaTrader 5 (en tu PC o VPS) consulta el servidor en **ciclos de seguridad de entre 15 y 30 segundos**. Por lo tanto, las operaciones se cerrarán en tu MT5 en unos pocos segundos (máximo 30 segundos según la conexión de tu VPS/broker).`
    },
    {
        keywords: ["actualización", "update", "versión nueva", "version", "upgrade", "descargar version"],
        response: `🔄 **Actualizaciones 100% Gratuitas:**

Todas las actualizaciones y mejoras del algoritmo son gratuitas para siempre. En cuanto liberemos una nueva versión (como la v11.32), te llegará una notificación al correo y podrás descargar el nuevo archivo \`.ex5\` directamente desde **[Mi Panel]**.`
    },
    {
        keywords: ["soporte", "contacto", "ayuda", "telegram", "correo", "email", "hablar con alguien", "humano", "escribir", "redes", "chat", "escribir a soporte"],
        response: `💬 **Atención y Soporte:**

Si necesitas ayuda para instalar el bot o configurar tu VPS, contáctanos:

📱 **Telegram**: [@KopyTradingSoporte](https://t.me/KopyTradingSoporte)
📧 **Email**: info@kopytrading.com

Te atenderemos de lunes a viernes en horario de mercado.`
    }
];

const DEFAULT_RESPONSE = "Hmm, parece que mi respuesta no encaja exactamente con lo que preguntas 🤖. He aprendido mucho sobre:\n\n• **Instalación y Descargas**\n• **Tipos de Licencias (Vitalicias / Anuales / Trial)**\n• **Gestión de Riesgo y Parámetros Técnicos**\n• **Uso de VPS y Horarios de Trading**\n\nIntenta hacer tu pregunta usando palabras clave o, si prefieres hablar con un humano, escribe **'soporte'**.";

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
    const [voiceEnabled, setVoiceEnabled] = useState(false);
    const [isListening, setIsListening] = useState(false);
    const [messages, setMessages] = useState<Message[]>([
        {
            from: "bot",
            text: "¡Hola! Soy el asistente avanzado de KopyTrading. ⚡\n\nPuedes **escribirme** usando la caja de texto de abajo, o usar el **micrófono** 🎤 para hablarme.\n\nSi quieres que te lea las respuestas en voz alta, dale al botón del altavoz 🔇 de arriba.\n\n¿En qué te ayudo hoy?",
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
                className="fixed bottom-6 right-6 z-[999] w-14 h-14 rounded-full bg-gradient-to-br from-brand-light to-brand shadow-[0_0_30px_rgba(139,92,246,0.6)] flex items-center justify-center hover:scale-110 transition-transform animate-pulse-glow"
                title="Chat con KopyBot"
            >
                {open ? (
                    <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
                ) : (
                    <svg className="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M8.625 12a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H8.25m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H12m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0h-.375M21 12c0 4.556-4.03 8.25-9 8.25a9.764 9.764 0 01-2.555-.337A5.972 5.972 0 015.41 20.97a5.969 5.969 0 01-.474-.065 4.48 4.48 0 00.978-2.025c.09-.457-.133-.901-.467-1.226C3.93 16.178 3 14.189 3 12c0-4.556 4.03-8.25 9-8.25s9 3.694 9 8.25z" /></svg>
                )}
            </button>

            {/* Panel del chat */}
            {open && (
                <div className="!fixed bottom-20 sm:bottom-24 left-4 right-4 sm:left-auto sm:right-6 z-[9999] sm:w-[350px] glass-card border border-brand/30 rounded-2xl shadow-[0_0_50px_rgba(139,92,246,0.3)] flex flex-col overflow-hidden" style={{ height: '440px', maxHeight: '80vh' }}>
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
                    <div className="flex-1 min-h-0 overflow-y-auto p-4 space-y-3 bg-bg-dark/80">
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
                    <div className="p-3 sm:p-4 border-t border-white/10 flex gap-2 flex-shrink-0 bg-bg-dark/95 items-end">
                        <button
                            onClick={toggleListen}
                            className={`w-10 h-10 sm:w-11 sm:h-11 rounded-full flex items-center justify-center flex-shrink-0 transition-colors mb-0.5 shadow-inner border border-white/5 ${isListening ? "bg-red-500 text-white animate-pulse" : "bg-white/5 hover:bg-white/10 text-white"}`}
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
                            placeholder={isListening ? "Escuchando tu voz..." : "✍️ Escribe tu mensaje aquí..."}
                            className="flex-1 bg-black/50 border border-white/20 rounded-xl px-4 py-3 text-sm text-white placeholder-text-muted outline-none focus:border-brand-light focus:bg-black transition-all resize-none overflow-y-auto min-h-[44px] max-h-[100px] shadow-inner"
                            rows={input.length > 35 ? 3 : (input.length > 15 ? 2 : 1)}
                        />
                        <button
                            onClick={sendMessage}
                            className={`w-10 h-10 sm:w-11 sm:h-11 flex-shrink-0 rounded-xl flex items-center justify-center transition-all text-lg mb-0.5 shadow-lg ${input.trim() ? 'bg-brand text-white hover:bg-brand-light scale-100' : 'bg-white/5 text-white/30 scale-95 cursor-default'}`}
                        >➤</button>
                    </div>
                </div>
            )}
        </>
    );
}

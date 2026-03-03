"use client";

import { useState, useRef, useEffect } from "react";

const BOT_RESPONSES: { keywords: string[]; response: string }[] = [
    {
        keywords: ["hola", "hello", "buenas", "hey", "qué tal", "que tal"],
        response: "¡Hola! Soy KopyBot 🤖, el asistente experto de KOPYTRADE. Puedo ayudarte con preguntas sobre nuestros 4 bots, instalación en MetaTrader 5, gestión de riesgo, brokers y mucho más. ¿Qué necesitas saber?"
    },
    {
        keywords: ["recomiendas", "recomienda", "empezar", "primer bot", "cuál compro", "cual compro", "para principiante", "soy nuevo", "nunca he", "novato", "recomendación", "mejor para"],
        response: "🏆 **Para principiantes, te recomiendo El Euro Precision Flow (EURUSD)** por estas razones:\n\n✅ Riesgo BAJO (el más seguro de los 4)\n✅ Capital mínimo 500$ (el más accesible)\n✅ Opera en H1 — señales claras, sin mucho ruido\n✅ El Euro es el par más líquido y estabilizado del mundo\n\n⚡ Si quieres más acción y tienes 1.000$, **La Ametralladora (XAUUSD)** es apasionante, pero tiene más riesgo.\n\n❌ **Evita BTC Storm Rider** si eres principiante — el Bitcoin es altamente volátil."
    },
    {
        keywords: ["cuándo abre", "cuando abre", "no abre", "no opera", "operacion", "operación", "señal", "esperar", "cuánto tiempo", "cuanto tiempo", "eurusd"],
        response: "⏳ **¿Por qué el Euro Precision Flow no abre operaciones?**\n\nEste bot usa cruce de medias móviles (EMA 21 y EMA 50). Solo entra cuando:\n1. La EMA rápida (21) cruza a la EMA lenta (50)\n2. El RSI no está en zona extrema\n\n🔵 Estos cruces a veces tardan **1-3 días** en producirse en H1 — eso es NORMAL. El bot está diseñado para ser selectivo, no para abrir a cualquier precio.\n\n💡 **En H1 puedes esperar 1-2 señales por semana en condiciones normales.** Si el mercado EURUSD está lateral (como ahora mismo en varios períodos de 2026), el bot espera con paciencia. ¡Eso es correcto!"
    },
    {
        keywords: ["ametralladora", "xauusd", "oro", "gold"],
        response: "🔥 **La Ametralladora (XAUUSD)** — El más popular de KOPYTRADE\n\n• Temporalidad: **M15** (Recomendado)\n• Estrategia: Scalping + Hedge Inteligente\n• Horario: 9h - 21h (sesiones europeas y americanas)\n• Objetivo por operación: $5\n• Break Even: A los $2 ganados\n• Capital mínimo: 1.000$\n• Riesgo: Medio\n• Precio: 249€ (pago único)\n\n⚠️ El Oro es muy volátil. Empieza siempre con lote **0.01** en cuenta Demo."
    },
    {
        keywords: ["euro", "precision", "eurusd", "eur"],
        response: "🎯 **Euro Precision Flow (EURUSD)** — El más seguro\n\n• Temporalidad: **H1** (Recomendado)\n• Estrategia: Cruce de EMA 21/50 + Filtro RSI\n• Horario: 8h - 20h (sesión europea + americana)\n• Objetivo por operación: $8\n• Capital mínimo: 500$\n• Riesgo: BAJO ✅\n• Precio: 179€ (pago único)\n\n💡 Puede tardar 1-3 días en abrir operaciones. El cruce de medias H1 es selectivo — eso es una ventaja, no un bug."
    },
    {
        keywords: ["yen", "usdjpy", "ninja", "jpy", "asia", "asiática", "asiatica"],
        response: "🥷 **Yen Ninja Ghost (USDJPY)** — El que opera de noche\n\n• Temporalidad: **M30** (Recomendado)\n• Estrategia: Rebote de Bandas de Bollinger + RSI\n• Horario: 0h - 8h (sesión asiática de Tokio)\n• Objetivo por operación: $6\n• Capital mínimo: 500$\n• Riesgo: Medio\n• Precio: 149€ (pago único)\n\n🌙 Perfecta combinación con La Ametralladora: uno opera de noche, el otro de día."
    },
    {
        keywords: ["bitcoin", "btc", "crypto", "cripto", "storm"],
        response: "⚡ **BTC Storm Rider (BTCUSD)** — Solo para expertos\n\n• Temporalidad: **H4** (Recomendado)\n• Estrategia: Breakout de rango de 48 velas H4\n• Horario: 24/7 (Bitcoin no cierra)\n• Objetivo por operación: $50 (BTC mueve mucho)\n• Capital mínimo: 2.000$\n• Riesgo: ALTO ⚠️\n• Precio: 299€ (pago único)\n\n❌ Si eres principiante, espera a tener experiencia con otro bot primero."
    },
    {
        keywords: ["precio", "cuánto cuesta", "cuanto cuesta", "costo", "coste", "todos", "comparar", "diferencia entre", "qué bots", "que bots"],
        response: "💰 **Todos los Bots de KOPYTRADE:**\n\n| Bot | Par | Riesgo | Precio |\n|---|---|---|---|\n| 🔥 La Ametralladora | XAUUSD | Medio | 249€ |\n| 🎯 Euro Precision Flow | EURUSD | Bajo | 179€ |\n| 🥷 Yen Ninja Ghost | USDJPY | Medio | 149€ |\n| ⚡ BTC Storm Rider | BTCUSD | Alto | 299€ |\n\nTodos son de **pago único** — sin suscripciones mensuales. Incluye el archivo .mq5 + PDF manual."
    },
    {
        keywords: ["vps", "servidor", "cloud", "siempre encendido", "apago el ordenador", "se apaga"],
        response: "🖥️ **El VPS es FUNDAMENTAL para trading 24/5.**\n\nSi tu ordenador se apaga con operaciones abiertas, el bot queda ciego y no puede aplicar el Break Even ni el Trailing Stop.\n\n💡 Opciones recomendadas:\n• **Contabo**: desde ~5€/mes (bueno para empezar)\n• **ForexVPS**: ~15$/mes (muy bajo latency)\n• **Pepperstone VPS**: GRATIS para clientes activos\n• **IC Markets VPS**: GRATIS para clientes activos\n\nPara La Ametralladora (opera 9h-21h) puedes gestionar con tu propio PC si estás en casa. Para el Yen Ninja Ghost (opera 0h-8h de noche) el VPS es OBLIGATORIO."
    },
    {
        keywords: ["broker", "vantage", "vtmarkets", "pepperstone", "ic markets", "dónde", "donde", "qué broker", "que broker"],
        response: "🏦 **Brokers compatibles con KOPYTRADE:**\n\n• **Vantage Markets** — Tu broker actual. Buena ejecución en Oro\n• **VT Markets** — Spreads competitivos, compatible MT5\n• **Pepperstone** — Lìder mundial. Spreads raw 0 pips. VPS gratis\n• **IC Markets** — Favorito de algorítmicos. Latencia ultra baja\n\n✅ Todos ofrecen MetaTrader 5 y cuentas Demo gratuitas.\n⚠️ Asegúrate de que el par que necesita tu bot esté disponible en tu broker."
    },
    {
        keywords: ["licencia", "clave", "número de cuenta", "cuenta mt5", "cómo activar", "como activar"],
        response: "🔐 **Activación del Bot (Super Sencilla):**\n\n1. Abre MetaTrader 5\n2. Tu número de cuenta aparece arriba a la izquierda (ej: 87409072)\n3. Descarga el bot desde tu Dashboard en KOPYTRADE\n4. Instálalo en MT5 y ábrelo en el gráfico\n5. En los parámetros, pon ese número en:\n   • **CuentaDemo** si usas cuenta Demo\n   • **CuentaReal** si usas cuenta Real\n\n🎉 El bot se activará automáticamente al reconocer tu cuenta."
    },
    {
        keywords: ["instalar", "instalación", "mt5", "metatrader", "cómo lo instalo", "como lo instalo", "archivo"],
        response: "📋 **Guía de instalación paso a paso:**\n\n1. Compra el bot y ve a tu Dashboard en KOPYTRADE\n2. Descarga el archivo `.mq5`\n3. En MT5: **Archivo → Abrir carpeta de datos**\n4. Navega a la carpeta `MQL5 → Experts`\n5. Pega el archivo .mq5 ahí\n6. Abre **MetaEditor** (tecla F4 en MT5)\n7. Pulsa **Compilar** (F7) — verás ✓ sin errores\n8. Arrastra el bot del Panel de Navegación al gráfico\n9. Activa AutoTrading (botón verde en la barra de MT5)\n10. Pon tu número de cuenta en CuentaDemo o CuentaReal\n\n¿En qué paso tienes problemas?"
    },
    {
        keywords: ["gratis", "prueba", "demo", "trial", "mes gratis", "free"],
        response: "🆓 **¿Prueba gratuita?**\n\nActualmente ofrecemos:\n✅ **Cuenta Demo gratuita ilimitada** — Descarga el bot, úsalo en una cuenta Demo de tu broker con dinero virtual. Sin límite de tiempo para probar.\n\n🔜 **Próximamente:** Trial de 30 días en cuenta real. Estamos implementando este sistema en la plataforma. Apúntate a nuestra newsletter para ser de los primeros en saberlo.\n\n💡 **Mi consejo:** Prueba siempre al menos 2-3 semanas en Demo antes de pasar a cuenta real. Así entiendes exactamente cómo se comporta tu bot sin arriesgar dinero."
    },
    {
        keywords: ["pago", "comprar", "stripe", "paypal", "bizum", "cómo pago", "como pago", "tarjeta"],
        response: "💳 **¿Cómo comprar un bot de KOPYTRADE?**\n\n1. Ve al Marketplace y elige tu bot\n2. Haz clic en **'Comprar y Descargar'**\n3. Actualmente el sistema está en modo de prueba (checkout simulado)\n4. Próximamente activaremos Stripe (tarjeta) y PayPal\n\n📧 Si quieres comprar ahora, escríbenos a **soporte@kopytrade.com** y te enviamos instrucciones de pago manual."
    },
    {
        keywords: ["no funciona", "error", "problema", "ayuda", "bug", "fallo"],
        response: "🔧 **¿Tienes un problema técnico?**\n\nLos más comunes y sus soluciones:\n\n⚠️ **'Cuenta no autorizada'**: Verifica que el número de cuenta en los parámetros sea exactamente el mismo que aparece en MetaTrader.\n\n⚠️ **Bot no abre operaciones**: Comprueba que el AutoTrading esté ACTIVO (botón verde en MT5) y que estés en las horas de operación del bot.\n\n⚠️ **Error de compilación**: Asegúrate de copiar el archivo .mq5 en la carpeta correcta (MQL5/Experts) y recompilar.\n\nSi el problema persiste: **soporte@kopytrade.com**"
    },
    {
        keywords: ["qué es kopytrade", "que es kopytrade", "quiénes sois", "quienes sois", "sobre vosotros", "la empresa"],
        response: "🏢 **¿Qué es KOPYTRADE?**\n\nKOPYTRADE es un marketplace especializado en bots de trading algorítmico para MetaTrader 5. Vendemos algoritmos diseñados y probados para automatizar operaciones en los mercados financieros más populares.\n\n🎯 **Nuestra filosofía:**\n• Pago único, sin suscripciones mensuales\n• Código protegido por licencia personal (número de cuenta MT5)\n• Manuales detallados para principiantes\n• Transparencia total sobre estrategias y riesgos\n\n📌 Visita nuestra sección **FAQ** o el **Blog** para más información."
    },
    {
        keywords: ["break even", "breakeven", "perdida", "pérdida", "stop loss"],
        response: "🛡️ **Break Even (Punto de Equilibrio):**\n\nCuando el bot gana $2 en una operación, mueve automáticamente el Stop Loss al precio de entrada. Así:\n\n✅ Si el mercado se gira, la operación se cierra sin pérdida\n✅ Nunca puede perder más de lo que tenías cuando entró el bot\n\n**Trailing Stop:** Además, el bot persigue el precio a favor con una distancia de 6 pips. Si el precio sigue subiendo, el stop sube con él. Si el precio se gira, el stop protege la ganancia acumulada."
    },
];

const DEFAULT_RESPONSE = "Hmm, no tengo una respuesta específica para eso. Para consultas detalladas puedes contactar con nuestro soporte en **soporte@kopytrade.com** o revisar nuestra sección de **FAQ** con las preguntas más frecuentes. ¿Puedo ayudarte con algo diferente?";

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

export default function FloatingChat() {
    const [open, setOpen] = useState(false);
    const [input, setInput] = useState("");
    const [messages, setMessages] = useState<Message[]>([
        {
            from: "bot",
            text: "¡Hola! Soy KopyBot 🤖, el asistente experto de KOPYTRADE. ¿En qué puedo ayudarte hoy? Pregúntame sobre bots, trading, instalación o brokers.",
            time: new Date().toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' })
        }
    ]);
    const [typing, setTyping] = useState(false);
    const bottomRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        bottomRef.current?.scrollIntoView({ behavior: "smooth" });
    }, [messages, typing]);

    function sendMessage() {
        if (!input.trim()) return;
        const userMsg: Message = { from: "user", text: input, time: new Date().toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' }) };
        setMessages(prev => [...prev, userMsg]);
        setInput("");
        setTyping(true);
        setTimeout(() => {
            const response = getBotResponse(input);
            setMessages(prev => [...prev, { from: "bot", text: response, time: new Date().toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' }) }]);
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
                <div className="fixed bottom-24 right-6 z-[998] w-80 sm:w-96 glass-card border border-brand/30 rounded-2xl shadow-[0_0_50px_rgba(139,92,246,0.3)] flex flex-col overflow-hidden" style={{ height: '520px' }}>
                    {/* Header */}
                    <div className="bg-gradient-to-r from-brand-dark to-brand p-4 flex items-center gap-3 flex-shrink-0">
                        <div className="w-10 h-10 rounded-full bg-white/20 flex items-center justify-center text-xl">🤖</div>
                        <div>
                            <div className="font-semibold text-white text-sm">KopyBot — Asistente KOPYTRADE</div>
                            <div className="text-xs text-white/60 flex items-center gap-1">
                                <span className="w-1.5 h-1.5 rounded-full bg-success inline-block"></span> Disponible ahora
                            </div>
                        </div>
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
                    <div className="p-3 border-t border-white/10 flex gap-2 flex-shrink-0 bg-bg-dark/90">
                        <input
                            value={input}
                            onChange={e => setInput(e.target.value)}
                            onKeyDown={e => e.key === "Enter" && sendMessage()}
                            placeholder="Escribe tu pregunta..."
                            className="flex-1 bg-surface-light border border-white/10 rounded-xl px-3 py-2 text-xs text-white placeholder-text-muted outline-none focus:border-brand/60 transition-colors"
                        />
                        <button
                            onClick={sendMessage}
                            className="w-9 h-9 rounded-xl bg-brand flex items-center justify-center text-white hover:bg-brand-light transition-colors text-sm"
                        >➤</button>
                    </div>
                </div>
            )}
        </>
    );
}

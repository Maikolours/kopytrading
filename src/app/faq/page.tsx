"use client";

import { useState } from "react";
import Link from "next/link";

const FAQS = [
    {
        category: "🤖 Sobre los Bots",
        items: [
            {
                q: "¿Necesito saber programación o trading para usar un bot de KopyTrading?",
                a: "No. Nuestros bots están diseñados para que cualquier persona pueda ponerlos en marcha en minutos. Simplemente descarga el archivo `.ex5` desde tu panel, arrástralo al gráfico de tu MetaTrader 5 y pulsa 'Aceptar'. No necesitas entender el código."
            },
            {
                q: "¿El bot opera por mí 24 horas al día?",
                a: "Cada bot tiene sus horarios de trading configurados de fábrica. La Ametralladora, por ejemplo, trabaja de 9:00 a 21:00 (hora broker) y fuera de ese horario no abre operaciones nuevas. Para operar las 24 horas ininterrumpidamente, necesitas que tu ordenador (o un VPS) esté siempre encendido y conectado a internet."
            },
            {
                q: "¿Qué pasa si apago el ordenador mientras el bot tiene operaciones abiertas?",
                a: "Si apagas el MetaTrader con operaciones vivas en el mercado, el bot se 'queda ciego'. Ya no podrá gestionar esas posiciones (aplicar Break Even, Trailing Stop o cerrarlas en beneficio). Las operaciones seguirán abiertas en el broker hasta que lleguen a su Stop Loss o Take Profit original. Recomendamos encarecidamente el uso de un VPS para evitar esto."
            },
            {
                q: "¿Puedo controlar el bot desde el móvil?",
                a: "Desde la app de MT5 en tu móvil puedes VER y CERRAR posiciones manualmente. Sin embargo, el botón para encender/apagar el AutoTrading del bot NO existe en la aplicación móvil. Para arrancar o detener el bot en seco, necesitas estar delante de un ordenador (PC o Mac)."
            },
        ]
    },
    {
        category: "💰 Riesgo y Dinero",
        items: [
            {
                q: "¿Cuánto dinero necesito para empezar?",
                a: "Depende del bot. La Ametralladora recomienda un mínimo de 1.000$ con un lote de 0.01 para que los márgenes sean sanos. Pero lo MÁS IMPORTANTE es que empieces siempre en una cuenta DEMO (dinero virtual) durante al menos 2-4 semanas para ver cómo se comporta el bot sin arriesgar dinero real."
            },
            {
                q: "¿Garantizáis ganancias?",
                a: "No. En KopyTrading somos transparentes: ningún bot puede garantizar ganancias. El mercado financiero lleva implícito un alto riesgo de pérdida de capital. Los bots son herramientas matemáticas que ejecutan una estrategia con disciplina, pero los mercados siempre pueden comportarse de manera impredecible. Invertir siempre conlleva riesgo."
            },
            {
                q: "¿Qué es el Break Even y por qué es importante?",
                a: "Break Even significa 'punto de equilibrio'. Cuando el bot activa el Break Even en una operación, mueve automáticamente el Stop Loss hasta el precio de entrada. Esto garantiza que, aunque el mercado se gire en contra, la operación se cierre sin pérdida ni ganancia. Es el escudo número uno contra los sustos."
            },
            {
                q: "¿Qué es el Trailing Stop?",
                a: "El Trailing Stop es un Stop Loss que 'sigue' al precio cuando va a tu favor. Si el precio sube y tú tienes una compra abierta, el Trailing Stop sube automáticamente detrás del precio a una distancia fija. Así puedes dejar correr las ganancias sin miedo, porque si el precio se gira, el stop ya estará mucho más arriba que cuando entraste."
            },
        ]
    },
    {
        category: "🖥️ Técnico y VPS",
        items: [
            {
                q: "¿Qué es un VPS y necesito uno?",
                a: "Un VPS (Virtual Private Server) es como alquilar un ordenador en la nube que nunca se apaga ni pierde internet. Para trading automatizado a tiempo completo es ESENCIAL. Por unos 10-15$/mes tienes un servidor 24/7 en el que instalas tu MetaTrader 5 y tus bots de KopyTrading. Los brokers más grandes como OctaFX o Pepperstone ofrecen VPS gratuitos para sus clientes activos."
            },
            {
                q: "¿Qué diferencia hay entre M5, M15, H1...?",
                a: "Son los 'timeframes' o temporalidades del gráfico. M5 significa que cada vela representa 5 minutos de mercado, M15 son 15 minutos, H1 es 1 hora y H4 son 4 horas. Los bots de scalping como La Ametralladora operan en M5 o M15 (operaciones rápidas). Los bots tendenciales suelen operar en H1 o H4 (operaciones más largas pero más sólidas)."
            },
            {
                q: "¿Puedo probar el bot antes de comprar?",
                a: "Sí, todos nuestros bots incluyen una opción de PRUEBA GRATUITA DE 30 DÍAS. Te recomendamos siempre usar esta opción primero, instalarlo en una cuenta DEMO virtual con tu broker y probarlo durante 2-4 semanas. Si el comportamiento te convence, puedes adquirir la licencia vitalicia después. Si no te convence, la prueba simplemente expirará sin coste alguno."
            },
            {
                q: "¿KopyTrading tiene acceso a mi cuenta del broker?",
                a: "No. KopyTrading en ningún momento tiene acceso a tu cuenta de broker, a tus credenciales ni a tus fondos. Tú instalas el bot en tu propio MetaTrader 5, en tu propio ordenador, conectado a tu propia cuenta del broker. Nosotros solo vendemos el software. Tú controlas todo."
            },
        ]
    },
    {
        category: "🎁 Pruebas y Cuentas",
        items: [
            {
                q: "¿Cómo activo mi prueba gratuita de 30 días?",
                a: "Es muy sencillo. En el Marketplace, elige el bot que quieras probar y pulsa en 'Probar Gratis'. Solo tendrás que introducir tu email. El sistema te creará una cuenta automáticamente y te llevará a 'Mi Panel', donde podrás descargar el bot (.ex5) y el manual PDF al instante."
            },
            {
                q: "¿Cuál es mi contraseña y cómo accedo a mi cuenta?",
                a: "Al activar una prueba o realizar una compra, el sistema te registra automáticamente. Tu contraseña temporal por defecto es '123456'. Puedes usarla para entrar en 'Mi Cuenta' o 'Mi Panel' en cualquier momento. Te recomendamos cambiarla por una más segura una vez dentro del panel."
            },
            {
                q: "¿Puedo usar la prueba gratuita en una cuenta real?",
                a: "No. Las licencias de prueba de 30 días están limitadas técnicamente para funcionar SOLO en cuentas de tipo DEMO (dinero ficticio). Esto es para que puedas testear la estrategia sin riesgo. Para operar en una cuenta REAL, necesitarás adquirir la licencia vitalicia (LIFETIME)."
            },
        ]
    },
    {
        category: "⚖️ Conceptos Ávancados",
        items: [
            {
                q: "He arrastrado el bot pero no hace nada, ¿qué es el 'Algo Trading'?",
                a: "En la parte superior de MetaTrader 5 hay un botón llamado 'Algo Trading' (o AutoTrading). Debe estar en VERDE. Además, al arrastrar el bot, en la pestaña 'Común', debes marcar la casilla 'Permitir trading algorítmico'. Si alguna de estas dos cosas falla, el bot tendrá una cara triste en la esquina superior derecha y no operará."
            },
            {
                q: "¿Por qué los resultados del Probador (Backtest) son distintos a la Real?",
                a: "El Backtest usa datos históricos, pero no puede replicar al 100% la velocidad de ejecución, el deslizamiento (slippage) o los cambios de spread que ocurren en el mercado real en milisegundos. El backtest sirve para validar la lógica, pero la verdadera prueba es la cuenta DEMO en tiempo real."
            },
            {
                q: "¿Qué es el Spread y cómo afecta a mi bot?",
                a: "El spread es la diferencia entre el precio de compra y el de venta (la comisión del broker). Si el spread sube mucho (por ejemplo, durante noticias), el bot podría no abrir operaciones o cerrarlas antes de tiempo para protegerte. Por eso recomendamos brokers con spreads bajos (Raw/Razor)."
            },
            {
                q: "¿Qué diferencia hay entre CopyTrading y usar vuestros Bots?",
                a: "En el CopyTrading tradicional, dependes de que un humano abra una operación y tu cuenta la replique (a veces con retraso). Con nuestros Expert Advisors (Bots), tú tienes el software ejecutándose en tu propio ordenador/VPS. Es más rápido, más privado y tú tienes el control total de los parámetros y el riesgo en todo momento."
            }
        ]
    }
];

function AccordionItem({ question, answer }: { question: string; answer: string }) {
    const [open, setOpen] = useState(false);
    return (
        <div className={`border rounded-xl overflow-hidden transition-all duration-300 ${open ? "border-brand/40 bg-brand/5 shadow-[0_0_20px_rgba(139,92,246,0.1)]" : "border-white/10 bg-transparent hover:border-white/20"}`}>
            <button
                onClick={() => setOpen(!open)}
                className="w-full text-left flex items-center justify-between p-5 sm:p-6 transition-colors"
            >
                <span className={`font-semibold transition-colors ${open ? "text-brand-light" : "text-white"}`}>{question}</span>
                <span className={`text-brand-light text-2xl transition-transform duration-300 flex-shrink-0 ${open ? "rotate-45" : ""}`}>+</span>
            </button>
            <div className={`grid transition-all duration-300 ease-in-out ${open ? "grid-rows-[1fr] opacity-100" : "grid-rows-[0fr] opacity-0"}`}>
                <div className="overflow-hidden">
                    <div className="px-5 sm:px-6 pb-6 text-text-muted text-sm sm:text-base leading-relaxed border-t border-white/5 pt-4">
                        {answer}
                    </div>
                </div>
            </div>
        </div>
    );
}

export default function FAQPage() {
    return (
        <div className="min-h-screen pt-28 md:pt-36 pb-24 px-4 sm:px-8 max-w-5xl mx-auto">
            <div className="w-full">
                {/* Header */}
                <div className="mb-6">
                    <Link href="/" className="inline-flex items-center gap-2 text-sm text-text-muted hover:text-white transition-colors group">
                        <span className="group-hover:-translate-x-1 transition-transform">←</span> Volver al inicio
                    </Link>
                </div>
                <div className="text-center mb-16">
                    <h1 className="text-4xl md:text-6xl font-extrabold text-white mb-6 uppercase tracking-tight italic">Preguntas Frecuentes</h1>
                    <p className="text-text-muted max-w-2xl mx-auto text-lg">
                        Todo lo que necesitas saber antes de empezar con el trading algorítmico y los bots de KopyTrading.
                    </p>
                    <div className="mt-8 inline-block px-6 py-2 rounded-full bg-warning/10 border border-warning/20">
                        <p className="text-xs text-warning font-semibold">
                            ⚠️ El trading conlleva un alto riesgo de pérdida de capital. Rendimientos pasados no garantizan resultados futuros.
                        </p>
                    </div>
                </div>

                {/* FAQ Sections */}
                <div className="space-y-16">
                    {FAQS.map((section, si) => (
                        <div key={si} className="animate-slide-up" style={{ animationDelay: `${si * 100}ms` }}>
                            <div className="flex items-center gap-3 mb-6">
                                <div className="h-8 w-1 bg-brand rounded-full"></div>
                                <h2 className="text-2xl font-bold text-white">{section.category}</h2>
                            </div>
                            <div className="space-y-4">
                                {section.items.map((item, ii) => (
                                    <AccordionItem key={ii} question={item.q} answer={item.a} />
                                ))}
                            </div>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
}

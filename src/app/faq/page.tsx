"use client";

import { useState } from "react";

const FAQS = [
    {
        category: "🤖 Sobre los Bots",
        items: [
            {
                q: "¿Necesito saber programación o trading para usar un bot de KOPYTRADE?",
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
                a: "No. En KOPYTRADE somos transparentes: ningún bot puede garantizar ganancias. El mercado financiero lleva implícito un alto riesgo de pérdida de capital. Los bots son herramientas matemáticas que ejecutan una estrategia con disciplina, pero los mercados siempre pueden comportarse de manera impredecible. Invertir siempre conlleva riesgo."
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
                a: "Un VPS (Virtual Private Server) es como alquilar un ordenador en la nube que nunca se apaga ni pierde internet. Para trading automatizado a tiempo completo es ESENCIAL. Por unos 10-15$/mes tienes un servidor 24/7 en el que instalas tu MetaTrader 5 y tus bots de KOPYTRADE. Los brokers más grandes como OctaFX o Pepperstone ofrecen VPS gratuitos para sus clientes activos."
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
                q: "¿KOPYTRADE tiene acceso a mi cuenta del broker?",
                a: "No. KOPYTRADE en ningún momento tiene acceso a tu cuenta de broker, a tus credenciales ni a tus fondos. Tú instalas el bot en tu propio MetaTrader 5, en tu propio ordenador, conectado a tu propia cuenta del broker. Nosotros solo vendemos el software. Tú controlas todo."
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
    }
];

function AccordionItem({ question, answer }: { question: string; answer: string }) {
    const [open, setOpen] = useState(false);
    return (
        <div className="border border-white/10 rounded-xl overflow-hidden">
            <button
                onClick={() => setOpen(!open)}
                className="w-full text-left flex items-center justify-between p-5 hover:bg-white/5 transition-colors"
            >
                <span className="font-medium text-white pr-4">{question}</span>
                <span className={`text-brand-light text-xl transition-transform flex-shrink-0 ${open ? "rotate-45" : ""}`}>+</span>
            </button>
            {open && (
                <div className="px-5 pb-5 text-text-muted text-sm leading-relaxed border-t border-white/5 pt-4">
                    {answer}
                </div>
            )}
        </div>
    );
}

export default function FAQPage() {
    return (
        <div className="min-h-screen pt-36 sm:pt-40 pb-24 px-4 sm:px-6 lg:px-8">
            <div className="max-w-4xl mx-auto">
                {/* Header */}
                <div className="text-center mb-16">
                    <span className="text-sm font-semibold text-brand-light tracking-widest uppercase mb-3 block">Soporte & Educación</span>
                    <h1 className="text-4xl md:text-5xl font-bold text-white mb-4">Preguntas Frecuentes</h1>
                    <p className="text-text-muted max-w-xl mx-auto">
                        Todo lo que necesitas saber antes de empezar con el trading algorítmico y los bots de KOPYTRADE.
                    </p>
                    <p className="mt-4 text-xs text-warning/80 border border-warning/20 inline-block px-4 py-2 rounded-full mb-10">
                        ⚠️ El trading conlleva un alto riesgo de pérdida de capital. Rendimientos pasados no garantizan resultados futuros.
                    </p>

                </div>

                {/* FAQ Sections */}
                <div className="space-y-12">
                    {FAQS.map((section, si) => (
                        <div key={si}>
                            <h2 className="text-xl font-semibold text-white mb-4">{section.category}</h2>
                            <div className="space-y-3">
                                {section.items.map((item, ii) => (
                                    <AccordionItem key={ii} question={item.q} answer={item.a} />
                                ))}
                            </div>
                        </div>
                    ))}
                </div>

                {/* CTA Bottom */}
                <div className="mt-20 text-center glass-card border border-white/10 rounded-2xl p-10">
                    <h3 className="text-2xl font-bold text-white mb-3">¿Tienes más dudas?</h3>
                    <p className="text-text-muted mb-6">Nuestro equipo está disponible para resolver todas tus preguntas antes de que decidas invertir.</p>
                    <a
                        href="mailto:soporte@kopytrade.com"
                        className="inline-block px-8 py-3 rounded-xl bg-brand text-white font-semibold hover:bg-brand-light transition-colors"
                    >
                        Contactar Soporte
                    </a>
                </div>
            </div>
        </div>
    );
}

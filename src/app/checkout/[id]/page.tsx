import { notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import CheckoutClientForm from "./CheckoutClientForm";

const GOLD_DEMO_BOT_ID = "cmn9hf8yc0000vhbcq9hbxk0j";

export default async function CheckoutPage(props: any) {
    const params = await props.params;

    const bot = await prisma.botProduct.findUnique({
        where: { id: params.id },
    });

    if (!bot) notFound();

    // Redirigir a una página amigable si el bot no está activo (nunca mostrar error técnico al cliente)
    if (bot.status !== "ACTIVE") {
        const statusLabel = bot.status === "MAINTENANCE" ? "En Optimización" : "Próximo Lanzamiento";
        const statusIcon = bot.status === "MAINTENANCE" ? "⚙️" : "🚀";
        const statusDesc = bot.status === "MAINTENANCE"
            ? "Este algoritmo está siendo optimizado para maximizar su rendimiento. Vuelve pronto o contacta con nosotros para ser notificado cuando esté disponible."
            : "Este algoritmo se encuentra en fase de optimización final y estará disponible muy pronto. Pónte en contacto para información de preventa.";
        return (
            <main className="min-h-screen pt-24 flex items-center justify-center bg-[#050505] text-white px-4">
                <div className="max-w-md w-full text-center space-y-6 p-12 rounded-[2rem] border border-brand/20 bg-brand/5 backdrop-blur-xl shadow-2xl shadow-brand/10">
                    <div className="text-6xl mb-4">🚀</div>
                    <h1 className="text-3xl font-black text-white uppercase italic tracking-tighter">{statusIcon} {statusLabel}</h1>
                    <p className="text-text-muted text-sm leading-relaxed">
                        <strong className="text-white">{bot.name}</strong><br />
                        {statusDesc}
                    </p>
                    <a href="/bots" className="inline-block mt-4 px-8 py-3 rounded-xl bg-brand text-white font-black text-xs uppercase tracking-widest hover:bg-brand-light transition-all shadow-lg shadow-brand/30">
                        Ver Catálogo →
                    </a>
                </div>
            </main>
        );
    }

    const isDemo = bot.id === GOLD_DEMO_BOT_ID || bot.name.toUpperCase().includes("DEMO");
    const priceDisplay = `${bot.price.toFixed(2)} EUR`;
    const licenseLabel = isDemo ? "Licencia Demo · 30 Días" : "Licencia Profesional";

    return (
        <main className="min-h-screen pt-20 pb-12 flex items-center justify-center bg-[#050505] text-white px-4 relative overflow-hidden">
            {/* Background glows */}
            <div className="absolute top-0 right-0 w-[600px] h-[600px] bg-brand/10 blur-[150px] rounded-full pointer-events-none -mr-32 -mt-32 opacity-50" />
            <div className="absolute bottom-0 left-0 w-[400px] h-[400px] bg-amber-500/5 blur-[120px] rounded-full pointer-events-none -ml-20 -mb-20" />

            <div className="max-w-lg w-full relative z-10">
                {/* Header */}
                <div className="text-center mb-8">
                    <a href="/bots" className="inline-flex items-center gap-2 text-text-muted hover:text-white transition-colors text-xs font-black uppercase tracking-widest mb-6 group">
                        <span className="group-hover:-translate-x-1 transition-transform">←</span> Volver al Marketplace
                    </a>
                    <div className="inline-block px-4 py-1 rounded-full bg-brand/10 border border-brand/20 text-[10px] font-black text-brand-light uppercase tracking-[0.2em] mb-4">
                        {isDemo ? "⚡ Prueba Demo Activa" : "🔐 Checkout Seguro"}
                    </div>
                </div>

                {/* Card principal */}
                <div className="relative glass-card border border-white/10 rounded-[2rem] overflow-hidden shadow-2xl shadow-brand/10">
                    {/* Top accent line */}
                    <div className="absolute top-0 left-0 w-full h-[2px] bg-gradient-to-r from-transparent via-brand to-transparent" />

                    {/* Bot info header */}
                    <div className="p-8 border-b border-white/5 bg-white/[0.02]">
                        <div className="flex items-start justify-between gap-4">
                            <div className="space-y-2">
                                <p className="text-[10px] text-text-muted uppercase tracking-[0.3em] font-black">{licenseLabel}</p>
                                <h1 className="text-xl font-black text-white uppercase italic tracking-tight leading-tight">{bot.name}</h1>
                                <div className="flex items-center gap-2">
                                    <span className="text-[9px] bg-white/5 border border-white/10 px-2 py-0.5 rounded-full font-bold uppercase tracking-wider text-text-muted">
                                        {bot.instrument}
                                    </span>
                                    <span className="text-[9px] bg-white/5 border border-white/10 px-2 py-0.5 rounded-full font-bold uppercase tracking-wider text-text-muted">
                                        MT5
                                    </span>
                                    {isDemo && (
                                        <span className="text-[9px] bg-amber-500/10 border border-amber-500/30 px-2 py-0.5 rounded-full font-bold uppercase tracking-wider text-amber-400">
                                            DEMO
                                        </span>
                                    )}
                                </div>
                            </div>
                            <div className="text-right shrink-0">
                                <div className="text-4xl font-black text-white italic tracking-tighter">
                                    {bot.price.toFixed(0)}
                                    <span className="text-lg text-text-muted ml-1">.00</span>
                                </div>
                                <div className="text-[10px] text-text-muted uppercase tracking-widest font-bold mt-1">EUR</div>
                            </div>
                        </div>

                        {isDemo && (
                            <div className="mt-4 p-3 rounded-xl bg-amber-500/5 border border-amber-500/20 flex items-center gap-3">
                                <span className="text-amber-400 text-sm">⏱</span>
                                <p className="text-[11px] text-amber-300/80 font-medium leading-relaxed">
                                    Licencia de prueba válida por <strong className="text-amber-300">30 días</strong> en cuenta <strong className="text-amber-300">DEMO</strong> de MetaTrader 5. Tras la prueba, podrás adquirir tu <strong className="text-amber-300">licencia anual</strong>.
                                </p>
                            </div>
                        )}
                    </div>

                    {/* Checkout form */}
                    <div className="p-8">
                        <CheckoutClientForm
                            bot={{ id: bot.id, name: bot.name, price: Number(bot.price) }}
                        />
                    </div>

                    {/* Footer security badge */}
                    <div className="px-8 pb-6 flex items-center justify-center gap-4 opacity-30">
                        <div className="text-[9px] font-black text-white uppercase tracking-tighter">🔒 Pago Cifrado SSL · PayPal Secure</div>
                    </div>
                </div>

                {/* Subtext */}
                <p className="text-center text-[10px] text-text-muted mt-6 leading-relaxed opacity-50">
                    Al completar el pago aceptas nuestros <a href="/legal/terminos" className="underline hover:text-white transition-colors">Términos de Uso</a> y el <a href="/legal/riesgo" className="underline hover:text-white transition-colors">Aviso de Riesgo</a>.
                </p>
            </div>
        </main>
    );
}

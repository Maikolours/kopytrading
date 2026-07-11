import { notFound } from "next/navigation";
import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { Button } from "@/components/ui/Button";
import { getServerSession } from "next-auth/next";
import { authOptions } from "@/lib/auth";
import { Metadata } from "next";
import { ReviewSection } from "@/components/reviews/ReviewSection";
import { VisualTestimonials } from "@/components/reviews/VisualTestimonials";

export async function generateMetadata({ params }: { params: Promise<{ id: string }> }): Promise<Metadata> {
    const { id } = await params;
    const bot = await prisma.botProduct.findUnique({
        where: { id: id }
    });
    if (!bot) {
        return {
            title: "Bot No Encontrado | KopyTrading",
            description: "El algoritmo solicitado no existe o no está disponible."
        };
    }
    return {
        title: `${bot.name} | Expert Advisor MT5`,
        description: `${bot.description} Algoritmo optimizado para ${bot.instrument} utilizando estrategia de ${bot.strategyType}.`,
        keywords: [bot.name, bot.instrument, bot.strategyType, "expert advisor mt5", "trading automático"],
    };
}

const GOLD_DEMO_BOT_ID = "cmn9hf8yc0000vhbcq9hbxk0j";
const GOLD_REAL_BOT_ID = "cmn9hf9440001vhbclffx9no6";
const BTC_REAL_BOT_ID  = "cmn9hf9bm0003vhbckaamkqal";

const formatBotName = (name: string, instrument: string, isTitle: boolean = false) => {
    let gradient = 'from-brand-light to-brand';
    
    if (instrument === 'XAUUSD') {
        gradient = 'from-yellow-300 to-amber-500';
    } else if (instrument === 'BTCUSD') {
        gradient = 'from-orange-400 to-orange-600';
    } else if (instrument === 'EURUSD') {
        gradient = 'from-blue-400 to-cyan-500';
    } else if (instrument === 'USDJPY') {
        gradient = 'from-purple-500 to-indigo-500';
    } else if (name.includes('CENT')) {
        gradient = 'from-slate-300 to-slate-400';
    }

    const highlightedName = name.split(' ').map((word, i) => {
        if (['GOLD', 'BTC', 'CENT', 'DEMO', 'EURO', 'YEN', 'GHOST', 'PRECISION', 'NINJA'].includes(word)) {
            const wordGradient = word === 'DEMO' ? 'from-purple-400 to-brand' : gradient;
            return <span key={i} className={`text-transparent bg-clip-text bg-gradient-to-r ${wordGradient}`}>{word} </span>;
        }
        return word + ' ';
    });

    return (
        <span className="block break-words">
            {highlightedName}
        </span>
    );
};

export default async function BotDetailPage({ params }: { params: Promise<{ id: string }> }) {
    const { id } = await params;

    const session = await getServerSession(authOptions);
    const isOwner = session?.user?.email === "viajaconsakura@gmail.com" || session?.user?.email === "viajaconsakura";

    const bot = await prisma.botProduct.findUnique({
        where: { id: id }
    });

    if (!bot || (!bot.isActive && !isOwner)) {
        notFound();
    }

    const demoBot = await prisma.botProduct.findUnique({
        where: { id: GOLD_DEMO_BOT_ID }
    });
    const demoIsUpcoming = demoBot ? (demoBot.status === "UPCOMING" || demoBot.status === "MAINTENANCE") : true;
    const isUpcoming = bot.status === "UPCOMING" || bot.status === "MAINTENANCE";

    const colors = {
        'XAUUSD': { accent: 'text-purple-400', badge: 'bg-purple-500/20 text-purple-400 border-purple-500/30', glow: 'bg-purple-500/5', button: 'bg-purple-600 hover:bg-purple-500 shadow-purple-500/40', shadow: 'shadow-purple-500/20' },
        'BTCUSD': { accent: 'text-amber-400', badge: 'bg-amber-500/20 text-amber-400 border-amber-500/30', glow: 'bg-amber-500/5', button: 'bg-amber-600 hover:bg-amber-500 shadow-amber-500/40', shadow: 'shadow-amber-500/20' },
        'EURUSD': { accent: 'text-emerald-400', badge: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30', glow: 'bg-emerald-500/5', button: 'bg-emerald-600 hover:bg-emerald-500 shadow-emerald-500/40', shadow: 'shadow-emerald-500/20' },
        'USDJPY': { accent: 'text-rose-400', badge: 'bg-rose-500/20 text-rose-400 border-rose-500/30', glow: 'bg-rose-500/5', button: 'bg-rose-600 hover:bg-rose-500 shadow-rose-500/40', shadow: 'shadow-rose-500/20' },
    }[bot.instrument as string] || { accent: 'text-brand-light', badge: 'bg-brand/20 text-brand-light border-brand/30', glow: 'bg-brand/5', button: 'bg-brand hover:bg-brand-light shadow-brand/40', shadow: 'shadow-brand/20' };

    const isDemo = bot.id === GOLD_DEMO_BOT_ID;

    return (
        <div className="min-h-screen pt-24 pb-12 px-4 sm:px-6 lg:px-8 overflow-hidden max-w-full relative">
            {/* Background Aesthetic Blur */}
            <div className={`absolute top-0 right-0 w-[600px] h-[600px] ${colors.glow} blur-[120px] rounded-full pointer-events-none -mr-40 -mt-20 opacity-40`} />
            <div className={`absolute bottom-0 left-0 w-[400px] h-[400px] ${colors.glow} blur-[100px] rounded-full pointer-events-none -ml-20 -mb-20 opacity-20`} />

            <div className="max-w-7xl mx-auto relative z-10">
                <div className="mb-10">
                    <Link href="/bots" className="text-text-muted hover:text-white transition-all text-xs flex items-center gap-2 uppercase tracking-widest font-black">
                        <span className="text-lg">←</span> Volver al Marketplace
                    </Link>
                </div>

                <div className="grid lg:grid-cols-12 gap-12">
                    {/* Main Content */}
                    <div className="lg:col-span-8 space-y-8 w-full max-w-full">
                        <div className="glass-card p-6 sm:p-12 border border-white/10 relative overflow-hidden group">
                            <div className={`absolute top-0 left-0 w-1 h-full bg-gradient-to-b from-transparent via-${bot.instrument === 'XAUUSD' ? 'purple-500' : bot.instrument === 'BTCUSD' ? 'amber-500' : 'brand'}/50 to-transparent`} />
                            
                            <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 mb-10">
                                <div className="max-w-full">
                                    <div className="flex flex-wrap items-center gap-2 sm:gap-3 mb-4">
                                        <span className={`px-4 py-1 rounded-full text-[10px] font-black tracking-[0.2em] border uppercase ${colors.badge}`}>
                                            {bot.instrument}
                                        </span>
                                        <span className="text-[10px] text-text-muted font-bold uppercase tracking-widest bg-white/5 px-3 py-1 rounded-full border border-white/5">
                                            Algorithmic Asset
                                        </span>
                                        <span className="text-[10px] font-bold uppercase tracking-widest bg-success/10 text-success px-3 py-1 rounded-full border border-success/20 animate-pulse">
                                            ✨ NUEVA VERSIÓN v11.31
                                        </span>
                                        {isDemo && (
                                            <span className="text-[10px] font-bold uppercase tracking-widest bg-amber-500/10 text-amber-400 px-3 py-1 rounded-full border border-amber-500/20">
                                                DEMO · 30 Días
                                            </span>
                                        )}
                                    </div>
                                    <h1 className="text-4xl sm:text-6xl font-black text-white tracking-tighter uppercase italic leading-[0.9]">
                                        {formatBotName(bot.name, bot.instrument, true)}
                                    </h1>
                                </div>
                                <div className="flex flex-col items-start md:items-end">
                                    <div className="text-[10px] text-text-muted font-black uppercase tracking-widest mb-1">Estrategia Base</div>
                                    <div className="text-xl font-bold text-white uppercase italic">{bot.strategyType}</div>
                                </div>
                            </div>

                            <div className="prose prose-invert max-w-none relative mt-8">
                                <h3 className="text-sm font-black text-text-muted uppercase tracking-[0.3em] mb-6 flex items-center gap-4">
                                    <span>Tesis de Inversión</span>
                                    <div className="flex-1 h-[1px] bg-white/5"></div>
                                </h3>
                                <p className="text-base sm:text-lg text-text-muted leading-relaxed font-light whitespace-pre-wrap break-words drop-shadow-sm">
                                    {bot.description}
                                </p>
                                
                                {/* STATUS OVERLAYS for Detail Page */}
                                {bot.status === "MAINTENANCE" && (
                                    <div className="mt-12 bg-amber-500/10 backdrop-blur-xl border border-amber-500/30 rounded-2xl p-6 text-center shadow-2xl shadow-amber-500/10 animate-pulse">
                                        <p className="text-amber-400 font-black flex items-center justify-center gap-3 uppercase tracking-widest text-sm italic">
                                            <span className="text-xl">⚙️</span> CALIBRACIÓN TÉCNICA EN CURSO
                                        </p>
                                        <p className="text-[10px] text-amber-500/60 mt-2 uppercase tracking-widest">El acceso a este modelo está restringido temporalmente por mantenimiento.</p>
                                    </div>
                                )}
                                {bot.status === "UPCOMING" && (
                                    <div className="mt-12 bg-brand/10 backdrop-blur-xl border border-brand/30 rounded-2xl p-6 text-center shadow-2xl shadow-brand/10">
                                        <p className="text-brand-light font-black flex items-center justify-center gap-3 uppercase tracking-widest text-sm italic animate-pulse">
                                            <span className="text-xl">🚀</span> PRÓXIMO LANZAMIENTO
                                        </p>
                                        <p className="text-[10px] text-brand-light/75 mt-2 uppercase tracking-widest leading-relaxed">
                                            Este algoritmo de alta frecuencia se encuentra en fase de optimización final.
                                            <br />Vuelve pronto para adquirir tu licencia o ponte en contacto para la preventa.
                                        </p>
                                    </div>
                                )}
                            </div>
                        </div>

                        <div className="grid md:grid-cols-2 gap-8 w-full max-w-full">
                            <div className="glass-card p-6 sm:p-8 border border-white/5 space-y-6">
                                <h3 className="text-xs font-black text-white uppercase tracking-[0.3em] flex items-center gap-3 flex-wrap">
                                    <span className={`w-2 h-2 rounded-full flex-shrink-0 ${bot.riskLevel === 'Low' ? 'bg-success' : 'bg-amber-500'}`}></span>
                                    Especificaciones Técnicas
                                </h3>

                                <div className="grid grid-cols-2 gap-4 sm:gap-8">
                                    <div className="space-y-1">
                                        <p className="text-[10px] text-text-muted uppercase tracking-widest">Timeframes</p>
                                        <p className="text-xl font-black text-white italic">{bot.timeframes || 'M1'}</p>
                                    </div>
                                    <div className="space-y-1">
                                        <p className="text-[10px] text-text-muted uppercase tracking-widest">Capital Mínimo</p>
                                        <p className="text-xl font-black text-white italic">${bot.minCapital ? bot.minCapital.toLocaleString() : '500'}</p>
                                    </div>
                                    <div className="space-y-1">
                                        <p className="text-[10px] text-text-muted uppercase tracking-widest">Plataforma</p>
                                        <p className="text-xl font-black text-white italic">MT5</p>
                                    </div>
                                    <div className="space-y-1">
                                        <p className="text-[10px] text-text-muted uppercase tracking-widest">Riesgo</p>
                                        <p className={`text-xl font-black italic ${bot.riskLevel === 'Low' ? 'text-success' : 'text-amber-400'}`}>{bot.riskLevel}</p>
                                    </div>
                                </div>
                            </div>

                            <div className="glass-card p-6 sm:p-8 border border-white/5 relative overflow-hidden">
                                <div className="flex flex-col sm:flex-row sm:items-center justify-between mb-8 gap-4">
                                    <h4 className="text-[10px] font-black text-white uppercase tracking-[0.3em] break-words">Rendimiento Histórico</h4>
                                    <span className="text-[9px] bg-success/10 text-success px-3 py-1 rounded-full border border-success/20 font-black uppercase tracking-widest self-start sm:self-auto">Auditado</span>
                                </div>

                                <div className="grid grid-cols-2 gap-4 sm:gap-6 relative z-10">
                                    <div className="bg-white/[0.02] p-4 rounded-2xl border border-white/5">
                                        <p className="text-[9px] text-text-muted mb-1 uppercase tracking-widest font-black">Profit Factor</p>
                                        <p className="text-3xl font-black text-success italic">2.14</p>
                                    </div>
                                    <div className="bg-white/[0.02] p-4 rounded-2xl border border-white/5">
                                        <p className="text-[9px] text-text-muted mb-1 uppercase tracking-widest font-black">Drawdown Max</p>
                                        <p className="text-3xl font-black text-danger italic">4.2%</p>
                                    </div>
                                </div>
                                
                                <div className="mt-6 h-12 flex items-end gap-1 w-full opacity-30 group-hover:opacity-100 transition-opacity">
                                    {[30, 45, 40, 60, 55, 85, 75, 100].map((h, i) => (
                                        <div key={i} className="flex-1 bg-gradient-to-t from-success/5 to-success/40 rounded-t-sm" style={{ height: `${h}%` }} />
                                    ))}
                                </div>
                            </div>
                        </div>

                        <div className="glass-card p-6 sm:p-10 border border-white/10 w-full max-w-full">
                            <h5 className="text-2xl font-black text-white mb-8 uppercase italic flex items-center gap-4">
                                <span className="w-10 h-10 rounded-2xl bg-white/5 flex items-center justify-center text-xl shadow-inner border border-white/10 italic">#</span>
                                Recursos del Algoritmo
                            </h5>
                            
                            <div className="grid sm:grid-cols-2 gap-6">
                                <div className="glass-card bg-white/[0.02] p-6 border border-white/5 hover:border-white/20 transition-all group/dl relative overflow-hidden">
                                    <div className="flex items-center justify-between mb-4">
                                        <div className={`text-[10px] font-black uppercase tracking-[0.2em] ${colors.accent}`}>Guía de Usuario</div>
                                        <span className="text-[10px] text-text-muted font-bold uppercase tracking-widest">PDF Premium</span>
                                    </div>
                                    <h6 className="text-lg font-black text-white mb-2 uppercase italic">Manual de Operativa</h6>
                                    <p className="text-xs text-text-muted mb-6 font-light leading-relaxed">Configuración avanzada de lotaje dinámico y gestión de riesgos paso a paso.</p>
                                    <div className="flex items-center gap-3">
                                        <div className="flex-1 h-[2px] bg-white/5 overflow-hidden">
                                            <div className="h-full bg-white/20 w-1/3"></div>
                                        </div>
                                        <span className="text-[9px] font-black text-text-muted uppercase tracking-widest whitespace-nowrap">Restringido</span>
                                    </div>
                                </div>

                                <div className="glass-card bg-white/[0.02] p-6 border border-white/5 hover:border-white/20 transition-all group/dl relative overflow-hidden">
                                    <div className="flex items-center justify-between mb-4">
                                        <div className="text-[10px] font-black uppercase tracking-[0.2em] text-success">Optimización</div>
                                        <span className="text-[10px] text-text-muted font-bold uppercase tracking-widest">SET File</span>
                                    </div>
                                    <h6 className="text-lg font-black text-white mb-2 uppercase italic">Ajustes de Institucional</h6>
                                    <p className="text-xs text-text-muted mb-6 font-light leading-relaxed">Archivo de parámetros optimizado para maximizar el Sharpe Ratio en cuentas reales.</p>
                                    <div className="flex items-center gap-3">
                                        <div className="flex-1 h-[2px] bg-white/5 overflow-hidden">
                                            <div className="h-full bg-white/20 w-2/3"></div>
                                        </div>
                                        <span className="text-[9px] font-black text-text-muted uppercase tracking-widest whitespace-nowrap">Restringido</span>
                                    </div>
                                </div>
                            </div>
                            
                            <p className="text-center text-[10px] text-text-muted uppercase tracking-[0.3em] mt-10 opacity-30">Los archivos se desbloquean automáticamente tras la adquisición de la licencia</p>
                        </div>
                        
                        {/* REVIEWS SECTION */}
                        <ReviewSection botProductId={bot.id} />
                        
                        {/* VISUAL TESTIMONIALS SECTION */}
                        <VisualTestimonials />
                        
                    </div>

                    {/* Sidebar Purchase Card */}
                    <div className="lg:col-span-4 w-full max-w-full">
                        <div className={`sticky top-28 glass-card p-6 sm:p-10 border-white/10 border shadow-2xl ${colors.shadow} relative overflow-hidden group/side`}>
                            {/* Decorative Glow */}
                            <div className={`absolute -top-24 -right-24 w-48 h-48 ${colors.glow} blur-[80px] rounded-full group-hover/side:opacity-100 opacity-50 transition-opacity`} />
                            
                            {/* Precio / Estado */}
                            <div className="text-center mb-10 pb-10 border-b border-white/5 relative z-10">
                                {isDemo ? (
                                    // Gold Demo: mostrar precio de 1€ con badge de 30 días
                                    <>
                                        <p className="text-[10px] text-text-muted mb-4 uppercase tracking-[0.4em] font-black">Licencia Demo (30 Días)</p>
                                        <div className="text-5xl sm:text-7xl font-black text-white tracking-tighter leading-none italic mb-4 break-all">
                                            {bot.price.toFixed(0)}
                                            <span className="text-2xl sm:text-3xl text-amber-400 ml-1">€</span>
                                            <span className="text-base sm:text-lg text-text-muted ml-1 italic">.00</span>
                                        </div>
                                        <div className="inline-flex items-center gap-2 bg-amber-500/10 text-amber-400 text-[10px] font-black px-4 py-1.5 rounded-full border border-amber-500/20 uppercase tracking-widest flex-wrap justify-center">
                                            ⏱ 30 Días Acceso Demo
                                        </div>
                                    </>
                                ) : (
                                    // Bots comerciales: precio oculto elegante
                                    <>
                                        <p className="text-[10px] text-text-muted mb-4 uppercase tracking-[0.4em] font-black">Licencia Anual</p>
                                        <div className="text-6xl font-black text-white/10 tracking-[0.6em] italic mb-3 select-none">— —</div>
                                        <div className="inline-flex items-center gap-2 bg-brand/5 text-brand-light/40 text-[10px] font-black px-4 py-1.5 rounded-full border border-brand/10 uppercase tracking-widest">
                                            ✦ PRÓXIMA REVELACIÓN
                                        </div>
                                    </>
                                )}
                            </div>

                            {/* Features list */}
                            <div className="space-y-4 mb-10 relative z-10">
                                {(isDemo ? [
                                    '✓ Compilación Nativa .ex5',
                                    '✓ Acceso Exclusivo Demo MT5',
                                    '✓ Dashboard Connectivity',
                                    '✓ Soporte Técnico Directo',
                                    '✓ Válido por 30 Días',
                                ] : [
                                    'Compilación Nativa .ex5',
                                    'Soporte Técnico Directo',
                                    'Dashboard Connectivity',
                                    'Licencia Vinculada a Cuenta',
                                    'Actualizaciones Disponibles',
                                ]).map((item, i) => (
                                    <div key={i} className="flex items-center gap-4 text-sm text-text-muted group/item">
                                        <div className={`w-1.5 h-1.5 rounded-full ${isDemo ? 'bg-amber-400/60' : 'bg-white/20'} group-hover/item:bg-brand-light transition-colors`}></div>
                                        <span className="font-medium group-hover/item:text-white transition-colors">{item}</span>
                                    </div>
                                ))}
                            </div>

                            {/* CTAs */}
                            <div className="space-y-4 relative z-10">
                                {isDemo && !isUpcoming ? (
                                    /* Gold Demo → Checkout directo */
                                    <Link href={`/checkout/${bot.id}`} className="block">
                                        <Button size="lg" fullWidth className={`text-base py-8 shadow-2xl uppercase tracking-widest font-black italic transition-all hover:scale-[1.02] active:scale-[0.98] ${colors.button}`}>
                                            Activar Demo · 1.00 EUR
                                        </Button>
                                    </Link>
                                ) : (
                                    /* Bots comerciales o Demo Desconectada */
                                    <div className="space-y-4">
                                        {/* Botón principal: siempre deshabilitado para prelanzamiento o demo desconectada */}
                                        <div className="space-y-2">
                                            <div className="p-4 rounded-xl bg-white/[0.03] border border-white/10 text-center backdrop-blur-sm">
                                                <p className="text-[9px] text-text-muted mb-1 uppercase tracking-widest font-black">
                                                    {isDemo ? 'Licencia Demo' : 'Versión Real'}
                                                </p>
                                                <p className="text-sm font-black text-white uppercase italic tracking-tighter">
                                                    {bot.status === 'MAINTENANCE' ? 'En Mantenimiento' : 'Próximamente'}
                                                </p>
                                            </div>
                                            <Button disabled size="lg" fullWidth className="py-6 opacity-30 grayscale cursor-not-allowed font-black uppercase tracking-widest text-xs italic">
                                                {bot.status === 'MAINTENANCE' ? 'No Disponible' : 'Próximamente'}
                                            </Button>
                                        </div>

                                        {/* Botón de Demo → Solo para Oro Real y BTC */}
                                        {bot.id === GOLD_REAL_BOT_ID && !demoIsUpcoming ? (
                                            /* Oro Real → Ofrece el Gold Demo por 1€ */
                                            <Link href="/checkout/cmn9hf8yc0000vhbcq9hbxk0j" className="block mt-2">
                                                <Button size="lg" variant="outline" fullWidth className="py-7 border-brand-light/30 hover:border-brand-light text-brand-light font-black uppercase tracking-widest text-[10px] hover:bg-brand/10 h-10 shadow-lg shadow-brand/10">
                                                    🎁 Activar Demo · 1€ (30 Días)
                                                </Button>
                                            </Link>
                                        ) : bot.id === BTC_REAL_BOT_ID ? (
                                            /* BTC Real → Demo próximamente */
                                            <div className="mt-2">
                                                <Button disabled size="lg" variant="outline" fullWidth className="py-6 opacity-40 border-white/10 text-white/50 font-black uppercase tracking-widest text-[10px] h-10 cursor-not-allowed">
                                                    🎁 Demo · Próximamente
                                                </Button>
                                            </div>
                                        ) : null /* Cent no tiene botón de prueba */}
                                    </div>
                                )}
                            </div>

                            <div className="mt-8 flex items-center justify-center gap-4 grayscale opacity-30">
                                <div className="text-[10px] font-black text-white uppercase tracking-tighter">Secure Payment via</div>
                                <div className="w-16 h-4 bg-white/20 rounded-sm"></div>
                                <div className="w-16 h-4 bg-white/20 rounded-sm"></div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}

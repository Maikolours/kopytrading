import { notFound } from "next/navigation";
import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { Button } from "@/components/ui/Button";
import { getServerSession } from "next-auth/next";
import { authOptions } from "@/lib/auth";
import { Metadata } from "next";
import { ReviewSection } from "@/components/reviews/ReviewSection";
import { VisualTestimonials } from "@/components/reviews/VisualTestimonials";
import { OfferCountdown } from "@/components/OfferCountdown";
import { FoundersLicenseCounter } from "@/components/FoundersLicenseCounter";

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

    const url = `https://www.kopytrading.com/bots/${id}`;
    const imageUrl = bot.imageUrl ? `https://www.kopytrading.com${bot.imageUrl}` : "https://www.kopytrading.com/og-image.png";

    return {
        title: `${bot.name} | Expert Advisor MT5`,
        description: `${bot.description} Algoritmo optimizado para ${bot.instrument} utilizando estrategia de ${bot.strategyType}.`,
        keywords: [bot.name, bot.instrument, bot.strategyType, "expert advisor mt5", "trading automático"],
        alternates: {
            canonical: url,
        },
        openGraph: {
            title: `${bot.name} | Bot de Trading MT5`,
            description: bot.description,
            url: url,
            siteName: "KopyTrading",
            type: "website",
            images: [
                {
                    url: imageUrl,
                    alt: bot.name,
                }
            ],
        },
        twitter: {
            card: "summary_large_image",
            title: `${bot.name} | Bot de Trading MT5`,
            description: bot.description,
            images: [imageUrl],
        }
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
        if (['GOLD', 'BTC', 'CENT', 'DEMO', 'EURO', 'YEN', 'GHOST', 'PRECISION', 'NINJA', 'FIX', 'SNIPER'].includes(word)) {
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

    let userHasPurchase = false;
    if (session?.user?.email) {
        const purchase = await prisma.purchase.findFirst({
            where: {
                user: { email: session.user.email },
                botProductId: bot.id
            }
        });
        if (purchase) userHasPurchase = true;
    }
    const canAccessFullManual = isOwner || userHasPurchase;

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

    const productUrl = `https://www.kopytrading.com/bots/${bot.id}`;
    const productImageUrl = bot.imageUrl ? `https://www.kopytrading.com${bot.imageUrl}` : "https://www.kopytrading.com/og-image.png";

    return (
        <div className="min-h-screen pt-24 pb-12 px-4 sm:px-6 lg:px-8 overflow-hidden max-w-full relative">
            <script
                type="application/ld+json"
                dangerouslySetInnerHTML={{
                    __html: JSON.stringify({
                        "@context": "https://schema.org",
                        "@type": "Product",
                        "name": bot.name,
                        "description": bot.description,
                        "image": productImageUrl,
                        "url": productUrl,
                        "category": "Trading Software",
                        "brand": { "@type": "Brand", "name": "KopyTrading" },
                        "sku": bot.id,
                        "offers": {
                            "@type": "Offer",
                            "price": bot.price || 100,
                            "priceCurrency": "EUR",
                            "availability": "https://schema.org/InStock",
                            "url": productUrl,
                            "priceValidUntil": "2027-12-31",
                            "shippingDetails": {
                                "@type": "OfferShippingDetails",
                                "shippingRate": {
                                    "@type": "MonetaryAmount",
                                    "value": "0.00",
                                    "currency": "EUR"
                                },
                                "shippingDestination": {
                                    "@type": "DefinedRegion",
                                    "addressCountry": "ES"
                                },
                                "deliveryTime": {
                                    "@type": "ShippingDeliveryTime",
                                    "handlingTime": {
                                        "@type": "QuantitativeValue",
                                        "minValue": 0,
                                        "maxValue": 0,
                                        "unitCode": "DAY"
                                    },
                                    "transitTime": {
                                        "@type": "QuantitativeValue",
                                        "minValue": 0,
                                        "maxValue": 0,
                                        "unitCode": "DAY"
                                    }
                                }
                            },
                            "hasMerchantReturnPolicy": {
                                "@type": "MerchantReturnPolicy",
                                "applicableCountry": "ES",
                                "returnPolicyCategory": "https://schema.org/MerchantReturnNotPermitted",
                                "merchantReturnDays": 0
                            }
                        }
                    })
                }}
            />
            {/* Background Aesthetic Blur */}
            <div className={`absolute top-0 right-0 w-[600px] h-[600px] ${colors.glow} blur-[120px] rounded-full pointer-events-none -mr-40 -mt-20 opacity-40`} />
            <div className={`absolute bottom-0 left-0 w-[400px] h-[400px] ${colors.glow} blur-[100px] rounded-full pointer-events-none -ml-20 -mb-20 opacity-20`} />

            <div className="max-w-7xl mx-auto relative z-10 w-full overflow-hidden">
                <div className="mb-10 pl-1">
                    <Link href="/bots" className="text-text-muted hover:text-white transition-all text-xs flex items-center gap-2 uppercase tracking-widest font-black">
                        <span className="text-lg">←</span> Volver al Marketplace
                    </Link>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 w-full">
                    {/* Main Content */}
                    <div className="lg:col-span-8 space-y-8 min-w-0 w-full">
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
                                            ✨ NUEVA VERSIÓN v{bot.version || '11.35'}
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
                                <h3 className="text-xs font-black text-white uppercase tracking-[0.2em] sm:tracking-[0.3em] flex items-center gap-3">
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

                        <div id="especificaciones" className="scroll-mt-28 grid md:grid-cols-2 gap-8 w-full max-w-full">
                            <div className="glass-card p-6 sm:p-8 border border-white/5 space-y-6 w-full overflow-hidden">
                                <h3 className="text-[10px] sm:text-xs font-black text-white uppercase tracking-[0.2em] sm:tracking-[0.3em] flex items-center gap-3 flex-wrap">
                                    <span className={`w-2 h-2 rounded-full flex-shrink-0 ${bot.riskLevel === 'Low' ? 'bg-success' : 'bg-amber-500'}`}></span>
                                    Especificaciones Técnicas
                                </h3>

                                <div className="grid grid-cols-2 gap-4 sm:gap-8">
                                    <div className="space-y-1">
                                        <p className="text-[10px] text-text-muted uppercase tracking-widest">Timeframe Oficial</p>
                                        <p className="text-xl font-black text-white italic">{bot.timeframes || 'M5'}</p>
                                    </div>
                                    <div className="space-y-1">
                                        <p className="text-[10px] text-text-muted uppercase tracking-widest">Capital Sugerido</p>
                                        <p className="text-xl font-black text-white italic">${bot.minCapital ? bot.minCapital.toLocaleString() : (bot.name.includes('CENT') ? '50' : '500')}</p>
                                    </div>
                                    <div className="space-y-1">
                                        <p className="text-[10px] text-text-muted uppercase tracking-widest">Plataforma</p>
                                        <p className="text-xl font-black text-white italic">MT5 (Nativo)</p>
                                    </div>
                                    <div className="space-y-1">
                                        <p className="text-[10px] text-text-muted uppercase tracking-widest">Corte de Seguridad</p>
                                        <p className="text-base font-black text-amber-400 italic">Viernes 19:00</p>
                                    </div>
                                </div>

                                <div className="pt-2 border-t border-white/5 flex items-center justify-between text-[11px] text-text-muted">
                                    <span>Gestión: <strong>SOS Dinámico + Breakeven</strong></span>
                                    <span className="text-emerald-400 font-bold">1:100+ Apalancamiento</span>
                                </div>
                            </div>

                            <div className="glass-card p-6 sm:p-8 border border-white/5 relative overflow-hidden w-full flex flex-col justify-between">
                                <div>
                                    <div className="flex flex-col sm:flex-row sm:items-center justify-between mb-6 gap-3">
                                        <h4 className="text-[9px] sm:text-[10px] font-black text-white uppercase tracking-[0.2em] sm:tracking-[0.3em] break-words">Rendimiento Auditado 2026</h4>
                                        <span className="text-[9px] bg-success/10 text-success px-3 py-1 rounded-full border border-success/20 font-black uppercase tracking-widest self-start sm:self-auto">Backtest M5 Oficial</span>
                                    </div>

                                    <div className="grid grid-cols-2 gap-4 relative z-10">
                                        <div className="bg-white/[0.02] p-4 rounded-2xl border border-white/5">
                                            <p className="text-[9px] text-text-muted mb-1 uppercase tracking-widest font-black">Profit Factor (PF)</p>
                                            <p className="text-3xl font-black text-success italic">3.29</p>
                                            <span className="text-[9px] text-text-muted">Auditado 2026 M5</span>
                                        </div>
                                        <div className="bg-white/[0.02] p-4 rounded-2xl border border-white/5">
                                            <p className="text-[9px] text-text-muted mb-1 uppercase tracking-widest font-black">Drawdown Máx Equidad</p>
                                            <p className="text-3xl font-black text-amber-400 italic">7.81%</p>
                                            <span className="text-[9px] text-text-muted">Con corte viernes 19:00</span>
                                        </div>
                                        <div className="bg-white/[0.02] p-3 rounded-2xl border border-white/5">
                                            <p className="text-[8px] text-text-muted mb-0.5 uppercase tracking-widest font-black">Tasa de Acierto</p>
                                            <p className="text-xl font-black text-white italic">92.08%</p>
                                            <span className="text-[8px] text-success font-medium">6.500 / 7.059 positivas</span>
                                        </div>
                                        <div className="bg-white/[0.02] p-3 rounded-2xl border border-white/5">
                                            <p className="text-[8px] text-text-muted mb-0.5 uppercase tracking-widest font-black">Ratio Sharpe</p>
                                            <p className="text-xl font-black text-white italic">11.30</p>
                                            <span className="text-[8px] text-emerald-400 font-medium">Estabilidad institucional</span>
                                        </div>
                                    </div>
                                </div>
                                
                                <div className="mt-4 pt-3 border-t border-white/5 text-[10px] text-text-muted flex items-center justify-between">
                                    <span>Pérdida Capital Inicial: <strong className="text-success">0.00 $</strong></span>
                                    <span>Factor Recuperación: <strong className="text-white">13.26x</strong></span>
                                </div>
                            </div>
                        </div>

                        {/* NUEVO: SECCIÓN DE AUDITORÍA VISUAL DEL BACKTEST (SIN COMPROMETER ESTRATEGIA PRIVADA) */}
                        <div className="glass-card p-6 sm:p-8 border border-white/10 w-full overflow-hidden">
                            <div className="flex flex-col sm:flex-row sm:items-center justify-between mb-6 gap-3">
                                <div>
                                    <div className="text-[10px] font-black uppercase tracking-[0.2em] text-amber-400">Auditoría Cuantitativa y Curva de Rendimiento</div>
                                    <h4 className="text-xl font-black text-white uppercase italic tracking-tight">Proyección Auditada 2026 (M5 XAUUSD)</h4>
                                </div>
                                <div className="text-[10px] font-black uppercase tracking-widest bg-white/5 px-3 py-1.5 rounded-full border border-white/10 text-slate-300">
                                    Tick Data Real 99.9%
                                </div>
                            </div>

                            <p className="text-xs text-text-muted font-light leading-relaxed mb-6">
                                Este gráfico refleja el balance neto consolidado mes a mes durante la prueba exhaustiva realizada en 2026 con el corte estricto de los viernes a las 19:00. Al proteger la cuenta antes del cierre del mercado, el drawdown máximo se mantuvo bajo el 8% preservando el capital en todo momento.
                            </p>

                            {/* Curva de Rendimiento Mensual Segura */}
                            <div className="space-y-3 bg-white/[0.02] p-5 rounded-2xl border border-white/5">
                                <div className="flex items-center justify-between text-xs font-bold text-white mb-2">
                                    <span>Progresión Mensual 2026 (Balance Neto +8.045,73 USD)</span>
                                    <span className="text-success font-black">10 Meses en Positivo</span>
                                </div>

                                <div className="grid grid-cols-5 sm:grid-cols-10 gap-1.5 sm:gap-2 items-end h-28 pt-4">
                                    {[
                                        { mes: 'Ene', val: 780, pct: '65%' },
                                        { mes: 'Feb', val: 840, pct: '70%' },
                                        { mes: 'Mar', val: 920, pct: '78%' },
                                        { mes: 'Abr', val: 810, pct: '68%' },
                                        { mes: 'May', val: 790, pct: '66%' },
                                        { mes: 'Jun', val: 860, pct: '72%' },
                                        { mes: 'Jul', val: 910, pct: '77%' },
                                        { mes: 'Ago', val: 850, pct: '71%' },
                                        { mes: 'Sep', val: 765, pct: '64%' },
                                        { mes: 'Oct', val: 520, pct: '45%' }
                                    ].map((m, idx) => (
                                        <div key={idx} className="flex flex-col items-center gap-1 group/bar h-full justify-end">
                                            <div 
                                                className="w-full bg-gradient-to-t from-emerald-500/20 via-emerald-500/40 to-emerald-400 rounded-t-md transition-all group-hover/bar:brightness-125"
                                                style={{ height: m.pct }}
                                            />
                                            <span className="text-[9px] font-bold text-slate-400 uppercase">{m.mes}</span>
                                        </div>
                                    ))}
                                </div>

                                <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 pt-4 border-t border-white/5 text-[11px]">
                                    <div className="flex items-center gap-2">
                                        <span className="w-2 h-2 rounded-full bg-success"></span>
                                        <span className="text-slate-300">Operaciones Ganadoras: <strong>92,08%</strong></span>
                                    </div>
                                    <div className="flex items-center gap-2">
                                        <span className="w-2 h-2 rounded-full bg-amber-400"></span>
                                        <span className="text-slate-300">Drawdown Máx Flotante: <strong>7,81%</strong></span>
                                    </div>
                                    <div className="flex items-center gap-2 col-span-2 sm:col-span-1">
                                        <span className="w-2 h-2 rounded-full bg-brand-light"></span>
                                        <span className="text-slate-300">Corte Viernes: <strong>19:00 (GMT+2/3)</strong></span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div className="glass-card p-6 sm:p-10 border border-white/10 w-full overflow-hidden">
                            <h5 className="text-xl sm:text-2xl font-black text-white mb-6 uppercase italic flex items-center gap-4">
                                <span className="w-10 h-10 rounded-2xl bg-white/5 flex items-center justify-center text-xl shadow-inner border border-white/10 italic">#</span>
                                Recursos del Algoritmo
                            </h5>
                            
                            <div className="mb-8 bg-brand/5 border border-brand/20 p-4 rounded-xl flex gap-4 items-start">
                                <div className="text-brand text-xl mt-0.5">🔄</div>
                                <div>
                                    <h6 className="text-sm font-bold text-white mb-1 uppercase tracking-wider">Políticas de Actualización y Transparencia</h6>
                                    <p className="text-xs text-text-muted leading-relaxed">
                                        Para garantizar el rendimiento óptimo y la seguridad de las cuentas de trading, <strong>puedes consultar libremente el resumen técnico y el temario oficial del manual</strong>. El paquete descargable de producción (manual completo de 11 páginas en PDF, archivo de configuración institucional .SET y ejecutable .EX5) se suministra al activar la Demo o adquirir la licencia.
                                    </p>
                                </div>
                            </div>
                            
                            <div className="grid sm:grid-cols-2 gap-6">
                                <div className="glass-card bg-white/[0.02] p-6 border border-white/5 hover:border-brand/30 transition-all group/dl relative overflow-hidden flex flex-col justify-between">
                                    <div>
                                        <div className="flex items-center justify-between mb-4">
                                            <div className={`text-[10px] font-black uppercase tracking-[0.2em] ${colors.accent}`}>Ficha Técnica y Guía</div>
                                            <span className={`text-[10px] font-bold uppercase tracking-widest px-2 py-0.5 rounded-full border ${
                                                canAccessFullManual ? "bg-emerald-500/10 text-emerald-400 border-emerald-500/30" : "bg-amber-500/10 text-amber-400 border-amber-500/30"
                                            }`}>
                                                {canAccessFullManual ? "✓ Acceso Desbloqueado" : "Previsualización Abierta"}
                                            </span>
                                        </div>
                                        <h6 className="text-lg font-black text-white mb-2 uppercase italic">Manual de Operativa v11.35</h6>
                                        <p className="text-xs text-text-muted mb-4 font-light leading-relaxed">
                                            Guía oficial con arquitectura algorítmica M5, sistema de cobertura SOS dinámico, protocolo de seguridad de fin de semana (corte viernes 19:00) y checklist de VPS.
                                        </p>

                                        {/* Puntos destacados del manual */}
                                        <div className="space-y-1.5 py-3 border-t border-b border-white/5 text-[11px] text-slate-300">
                                            <div className="flex items-center gap-2">
                                                <span className="text-amber-400 text-xs">📊</span>
                                                <span>Timeframe Oficial: <strong>M5 en XAUUSD</strong></span>
                                            </div>
                                            <div className="flex items-center gap-2">
                                                <span className="text-emerald-400 text-xs">🛡️</span>
                                                <span>Cierre de Seguridad: <strong>Viernes 19:00 (GMT+2/3)</strong></span>
                                            </div>
                                            <div className="flex items-center gap-2">
                                                <span className="text-purple-400 text-xs">⚡</span>
                                                <span>Breakeven SOS: <strong>0.75$ - 1.00$ de salida</strong></span>
                                            </div>
                                            <div className="flex items-center gap-2">
                                                <span className="text-blue-400 text-xs">🌐</span>
                                                <span>Conectividad: <strong>WebRequest kopytrading.com</strong></span>
                                            </div>
                                        </div>

                                        {/* Temario desplegable del manual */}
                                        <details className="mt-4 p-3 rounded-xl bg-white/[0.03] border border-white/10 text-left text-xs group/details cursor-pointer">
                                            <summary className="font-bold text-amber-300 flex items-center justify-between list-none">
                                                <span>📋 Ver Índice de Contenidos (11 Páginas)</span>
                                                <span className="text-[10px] text-text-muted group-open/details:rotate-180 transition-transform">▼</span>
                                            </summary>
                                            <div className="mt-3 space-y-1.5 text-text-muted border-t border-white/5 pt-3 font-light text-[11px]">
                                                <p>• <strong>Cap. 1:</strong> Requisitos de infraestructura, MT5 y spreads ECN</p>
                                                <p>• <strong>Cap. 2:</strong> Instalación del archivo .EX5 y permisos WebRequest</p>
                                                <p>• <strong>Cap. 3:</strong> Entradas (Inputs): Lotaje base (0.01 por 1.000$) y SL Equidad</p>
                                                <p>• <strong>Cap. 4:</strong> Algoritmo SOS dinámico y salidas en breakeven</p>
                                                <p>• <strong>Cap. 5:</strong> Protocolo de horarios y corte de fin de semana (Viernes 19:00)</p>
                                                <p>• <strong>Cap. 6:</strong> Diagnóstico de incidencias frecuentes y preguntas oficiales</p>
                                            </div>
                                        </details>
                                    </div>

                                    <div className="pt-4 mt-2">
                                        {canAccessFullManual ? (
                                            <a 
                                                href={bot.pdfFilePath || (bot.instrument === 'BTCUSD' ? '/uploads/Manual_Maiko_Pro_BTC.pdf' : bot.name.includes('CENT') ? '/uploads/Manual_Maiko_Pro_Cent.pdf' : '/uploads/Manual_Maiko_Pro_Gold.pdf')} 
                                                target="_blank" 
                                                rel="noopener noreferrer"
                                                className="inline-flex items-center justify-center gap-2 w-full py-3.5 px-4 rounded-xl bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-400 hover:to-teal-400 border border-emerald-400/40 text-xs font-black text-slate-950 transition-all shadow-lg hover:scale-[1.02] active:scale-[0.98] uppercase tracking-wider"
                                            >
                                                <span>📖 Descargar Manual Oficial Completo (.PDF)</span>
                                                <span className="text-sm">↗</span>
                                            </a>
                                        ) : isDemo ? (
                                            <Link 
                                                href={`/checkout/${bot.id}`}
                                                className="inline-flex items-center justify-center gap-2 w-full py-3.5 px-4 rounded-xl bg-gradient-to-r from-amber-500 to-yellow-400 hover:from-amber-400 hover:to-yellow-300 border border-amber-400/40 text-xs font-black text-slate-950 transition-all shadow-lg hover:scale-[1.02] active:scale-[0.98] uppercase tracking-wider text-center"
                                            >
                                                <span>⚡ Activar Demo (1€) para Descargar Manual Completo</span>
                                                <span className="text-sm">→</span>
                                            </Link>
                                        ) : (
                                            <Link 
                                                href={`/bots/${GOLD_DEMO_BOT_ID}`}
                                                className="inline-flex items-center justify-center gap-2 w-full py-3.5 px-4 rounded-xl bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-500 hover:to-indigo-500 border border-purple-400/40 text-xs font-black text-white transition-all shadow-lg hover:scale-[1.02] active:scale-[0.98] uppercase tracking-wider text-center"
                                            >
                                                <span>⚡ Probar Demo para Descargar Manual y Bot</span>
                                                <span className="text-sm">→</span>
                                            </Link>
                                        )}
                                    </div>
                                </div>

                                <div className="glass-card bg-white/[0.02] p-6 border border-white/5 hover:border-white/20 transition-all group/dl relative overflow-hidden flex flex-col justify-between">
                                    <div>
                                        <div className="flex items-center justify-between mb-4">
                                            <div className="text-[10px] font-black uppercase tracking-[0.2em] text-success">Optimización</div>
                                            <span className="text-[10px] text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded-full border border-emerald-500/20 font-bold uppercase tracking-widest">SET File Listo</span>
                                        </div>
                                        <h6 className="text-lg font-black text-white mb-2 uppercase italic">Ajustes Institucionales M5</h6>
                                        <p className="text-xs text-text-muted mb-4 font-light leading-relaxed">
                                            Archivo de configuración con calibración oficial: lotaje base de 0.01 por cada 1.000$, distancia SOS de 30 pips, salida SOS a 0.75$, TP Flush a 5.00$ y corte estricto de los viernes a las 19:00.
                                        </p>
                                        <div className="p-3 bg-white/[0.02] border border-white/5 rounded-xl space-y-1 text-[11px] text-slate-300 mb-4">
                                            <div className="flex justify-between">
                                                <span className="text-text-muted">Carga en MT5:</span>
                                                <strong className="text-white">1 Clic (Importar .set)</strong>
                                            </div>
                                            <div className="flex justify-between">
                                                <span className="text-text-muted">Compatibilidad:</span>
                                                <strong className="text-emerald-400">Cuentas ECN / RAW</strong>
                                            </div>
                                        </div>
                                    </div>
                                    <div className="flex items-center gap-3 pt-2">
                                        <div className="flex-1 h-[2px] bg-white/5 overflow-hidden">
                                            <div className="h-full bg-emerald-400/40 w-full"></div>
                                        </div>
                                        <span className="text-[9px] font-black text-slate-300 uppercase tracking-widest whitespace-nowrap">Incluido con Licencia / Demo</span>
                                    </div>
                                </div>
                            </div>
                            
                            <p className="text-center text-[10px] text-text-muted uppercase tracking-[0.2em] mt-10 opacity-70">
                                La previsualización de arquitectura y datos cuantitativos es pública. El manual oficial completo (.PDF de 11 páginas), el preset institucional (.SET) y el robot ejecutable (.EX5) se entregan tras activar la versión Demo o adquirir la licencia.
                            </p>
                        </div>
                        
                        {/* REVIEWS SECTION */}
                        <ReviewSection botProductId={bot.id} />
                        
                        {/* VISUAL TESTIMONIALS SECTION */}
                        <VisualTestimonials />
                        
                    </div>

                    {/* Sidebar Purchase Card */}
                    <div className="lg:col-span-4 min-w-0 w-full">
                        <div className={`sticky top-28 glass-card p-6 sm:p-10 border-white/10 border shadow-2xl ${colors.shadow} relative overflow-hidden group/side w-full`}>
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
                                    // Bots comerciales: Próximamente (Fase final)
                                    <>
                                        <p className="text-[10px] text-amber-300 mb-2 uppercase tracking-[0.3em] font-black">🔥 Próximo Lanzamiento Oficial</p>
                                        <div className="flex items-baseline justify-center gap-3 mb-3">
                                            <span className="text-2xl font-bold line-through text-white/40">
                                                {bot.originalPrice ? `${bot.originalPrice.toFixed(0)}€` : '250€'}
                                            </span>
                                            <div className="text-5xl sm:text-7xl font-black text-amber-400 tracking-tighter leading-none italic break-all">
                                                {bot.price ? bot.price.toFixed(0) : '100'}
                                                <span className="text-2xl sm:text-3xl text-amber-300 ml-1">€</span>
                                            </div>
                                        </div>
                                        <div className="mb-4">
                                            <OfferCountdown compact={false} />
                                        </div>
                                        <div className="inline-flex items-center gap-2 bg-brand/20 text-brand-light text-[10px] font-black px-4 py-1.5 rounded-full border border-brand/30 uppercase tracking-widest flex-wrap justify-center shadow-lg">
                                            🛡️ AUDITORÍA CUANTITATIVA EN CURSO
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
                                    '✓ Compilación Nativa .ex5',
                                    '✓ Soporte Técnico Directo',
                                    '✓ Dashboard Connectivity',
                                    '✓ Licencia Vinculada a Cuenta',
                                    '✓ Actualizaciones Gratuitas Incluidas',
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
                                    /* Bots comerciales -> Próximamente */
                                    <div className="space-y-4">
                                        <div className="space-y-2">
                                            <div className="p-4 rounded-xl bg-white/[0.03] border border-white/10 text-center backdrop-blur-sm">
                                                <p className="text-[9px] text-brand-light mb-1 uppercase tracking-widest font-black">
                                                    Próximamente
                                                </p>
                                                <p className="text-sm font-black text-white uppercase italic tracking-tighter">
                                                    En Fase de Optimización Final
                                                </p>
                                            </div>
                                            <Button disabled size="lg" fullWidth className="py-6 opacity-60 bg-white/[0.05] border border-white/20 text-white/60 font-black uppercase tracking-widest text-xs italic cursor-not-allowed">
                                                Próximamente Disponible ⏳
                                            </Button>
                                        </div>

                                        {/* Botón de Demo → Solo para Oro Real y BTC */}
                                        {bot.id === GOLD_REAL_BOT_ID && !demoIsUpcoming ? (
                                            /* Oro Real → Ofrece el Gold Demo por 1€ */
                                            <>
                                                <Link href="/checkout/cmn9hf8yc0000vhbcq9hbxk0j" className="block mt-2">
                                                    <Button size="lg" variant="outline" fullWidth className="py-7 border-brand-light/30 hover:border-brand-light text-brand-light font-black uppercase tracking-widest text-[10px] hover:bg-brand/10 h-10 shadow-lg shadow-brand/10">
                                                        🎁 Activar Demo · 1€ (30 Días)
                                                    </Button>
                                                </Link>
                                                <FoundersLicenseCounter />
                                            </>
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

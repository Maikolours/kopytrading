import { Metadata } from "next";
import Link from "next/link";
import { getServerSession } from "next-auth/next";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { Card, CardContent, CardTitle, CardHeader, CardFooter } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";

export const metadata: Metadata = {
  title: "Maiko Algorithms | KopyTrading",
  description: "Algoritmos de alta precisión para MetaTrader 5. Diseñados por traders para traders.",
};

export const dynamic = "force-dynamic";

const GOLD_DEMO_ID = "cmn9hf8yc0000vhbcq9hbxk0j";
const GOLD_REAL_ID = "cmn9hf9440001vhbclffx9no6";

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
        <span className="inline-flex items-center gap-x-2 flex-wrap">
            <span>{highlightedName}</span>
        </span>
    );
};

export default async function BotsPage({ searchParams }: { searchParams: Promise<{ asset?: string }> }) {
    const session = await getServerSession(authOptions);
    const isOwner = session?.user?.email === "viajaconsakura@gmail.com" || session?.user?.email === "viajaconsakura";
    const { asset } = await searchParams;

    const whereClause: any = { isActive: true };
    if (asset) {
        whereClause.instrument = { contains: asset };
    }

    const bots = await prisma.botProduct.findMany({
        where: whereClause,
        orderBy: { createdAt: 'asc' }
    });

    const categories = [
        { id: "", label: "Todos" },
        { id: "XAUUSD", label: "Maiko Gold" },
        { id: "BTCUSD", label: "Maiko BTC" },
    ];

    const getBotAccent = (bot: any) => {
        let image = "";
        if (bot.instrument === 'BTCUSD') {
            image = "/images/maiko-btc.png";
            return { accent: "text-amber-400", badge: "from-amber-500 to-orange-600", glow: "bg-amber-500/10", image };
        }
        if (bot.id === GOLD_DEMO_ID) {
            image = "/images/maiko-gold-demo.png";
            return { accent: "text-purple-400", badge: "from-purple-500 to-violet-600", glow: "bg-purple-500/10", image };
        }
        if (bot.instrument === 'EURUSD') {
            image = "/images/maiko-euro.png"; 
            return { accent: "text-blue-400", badge: "from-blue-500 to-cyan-500", glow: "bg-blue-500/10", image };
        }
        if (bot.instrument === 'USDJPY') {
            image = "/images/maiko-yen.png"; 
            return { accent: "text-purple-400", badge: "from-purple-500 to-indigo-500", glow: "bg-purple-500/10", image };
        }
        if (bot.name.includes('CENT')) {
            image = "/images/maiko-cent.png";
            return { accent: "text-slate-400", badge: "from-slate-400 to-slate-500", glow: "bg-slate-400/10", image };
        }
        image = "/images/maiko-gold.png";
        return { accent: "text-brand-light", badge: "from-brand to-brand-light", glow: "bg-brand/10", image };
    };

    return (
        <div className="min-h-screen pt-28 md:pt-32 pb-12 px-4 sm:px-6 lg:px-8 relative overflow-hidden bg-[#050505]">

            {/* Background GFX */}
            <div className="absolute top-[-10%] right-[-10%] w-[800px] h-[800px] bg-brand-light/5 blur-[150px] rounded-full pointer-events-none" />
            <div className="absolute bottom-[-10%] left-[-10%] w-[600px] h-[600px] bg-brand/5 blur-[120px] rounded-full pointer-events-none" />

            <div className="max-w-7xl mx-auto relative z-10 mb-4">
                <Link href="/" className="inline-flex items-center gap-2 text-xs font-black uppercase tracking-widest text-text-muted hover:text-white transition-all group">
                    <span className="group-hover:-translate-x-1 transition-transform">←</span> Volver al inicio
                </Link>
            </div>

            {/* Header */}
            <div id="bot-catalog" className="max-w-7xl mx-auto mb-14 pb-10 text-center relative">
                <div className="mb-10">
                    {/* Título con font adaptado para móvil */}
                    <h1 className="text-4xl sm:text-6xl lg:text-7xl font-black text-white tracking-tight mb-4 uppercase italic leading-tight py-2 px-2">
                        Maiko{" "}
                        <span className="text-transparent bg-clip-text bg-gradient-to-r from-brand-light to-brand tracking-normal pb-2">Algorithms</span>
                    </h1>
                    <p className="text-text-muted text-base max-w-2xl mx-auto font-light tracking-tight opacity-60 italic leading-relaxed">
                        Sistemas de alta frecuencia y precisión institucional para el mercado MT5.
                    </p>
                </div>

                {/* Filtros por categoría */}
                <div className="flex flex-wrap gap-2 md:gap-3 justify-center">
                    {categories.map((cat) => (
                        <Link key={cat.id} href={cat.id ? `/bots?asset=${cat.id}` : "/bots"}>
                            <span className={`px-5 py-2.5 rounded-full text-[10px] font-black tracking-[0.2em] uppercase transition-all whitespace-nowrap ${(asset === cat.id || (!asset && cat.id === ""))
                                ? "bg-brand text-white shadow-[0_0_25px_rgba(168,85,247,0.4)] border border-brand-light/50"
                                : "bg-white/[0.03] border border-white/5 text-text-muted hover:text-white hover:border-white/20"
                                }`}>
                                {cat.label}
                            </span>
                        </Link>
                    ))}
                </div>
            </div>

            {/* Grid de bots */}
            {bots.length === 0 ? (
                <div className="text-center py-20 px-4 glass-card border border-dashed border-white/10 rounded-[2rem]">
                    <h3 className="text-2xl font-black text-white mb-4 italic uppercase tracking-tighter opacity-40">No hay terminales disponibles</h3>
                    <p className="text-text-muted mb-8 max-w-md mx-auto">Nuestro equipo está calibrando los servidores para estos activos. Vuelve pronto.</p>
                    <Link href="/bots"><Button variant="outline" className="rounded-xl border-white/10 text-white/40">Ver todos</Button></Link>
                </div>
            ) : (
                <div className="max-w-7xl mx-auto grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 lg:gap-8">
                    {bots.map((bot: any) => {
                        const colors = getBotAccent(bot);
                        const isUpcoming = bot.status === 'UPCOMING' || bot.status === 'MAINTENANCE';
                        const isDemo = bot.id === GOLD_DEMO_ID;

                        return (
                             <Card key={bot.id} interactive className={`flex flex-col h-full transition-all duration-700 overflow-hidden group relative rounded-[2rem] border bg-white/[0.03] border-white/10 hover:border-brand-light/50 hover:shadow-[0_20px_50px_rgba(168,85,247,0.15)] shadow-[0_20px_60px_rgba(0,0,0,0.6)] ${isUpcoming ? 'opacity-60 hover:opacity-100' : 'opacity-100 shadow-[0_0_40px_rgba(168,85,247,0.2)] border-brand/40'}`}>

                                 {/* Upcoming overlay */}
                                 {isUpcoming && (
                                     <div className="absolute top-3 left-1/2 -translate-x-1/2 z-20">
                                         <span className="bg-brand/20 border border-brand/50 text-brand-light text-[8px] font-black px-3 py-1 rounded-full tracking-[0.15em] uppercase shadow-[0_0_20px_rgba(168,85,247,0.3)] whitespace-nowrap">
                                         ⚡ {bot.status === 'MAINTENANCE' ? 'MANTENIMIENTO' : 'PRÓXIMAMENTE'}
                                         </span>
                                     </div>
                                 )}

                                <CardHeader className="relative overflow-hidden pb-4 pt-10">
                                    <div className={`absolute top-0 right-0 w-32 h-32 ${colors.glow} blur-3xl -mr-16 -mt-16 transition-opacity duration-700 group-hover:opacity-100 opacity-20`} />
                                    
                                    {/* Maiko Avatar */}
                                    <div className="absolute top-[-20px] right-[-20px] w-32 h-32 opacity-60 group-hover:opacity-100 transition-opacity duration-700 mix-blend-screen pointer-events-none z-0">
                                        {colors.image && <img src={colors.image} alt="Maiko Warrior" className="w-full h-full object-cover rounded-full" />}
                                    </div>

                                    <div className="flex justify-between items-start mb-3 relative z-10">
                                        {/* Nombre del bot — con min-w-0 para que truncate funcione */}
                                        <CardTitle className="text-xl font-black italic tracking-tighter uppercase transition-all duration-500 text-white group-hover:text-brand-light min-w-0 pr-2 leading-tight">
                                            {formatBotName(bot.name, bot.instrument)}
                                        </CardTitle>
                                        <div className="flex flex-col items-end gap-1.5 shrink-0">
                                            <span className={`bg-gradient-to-br ${colors.badge} text-white px-2.5 py-1 rounded-full text-[9px] font-black tracking-widest shadow-lg uppercase whitespace-nowrap`}>
                                                {bot.instrument}
                                            </span>
                                            {isDemo && (
                                                <span className="bg-amber-500/10 border border-amber-500/30 text-amber-400 text-[7px] font-black px-2 py-0.5 rounded-full tracking-widest uppercase whitespace-nowrap">
                                                    DEMO · 30 días
                                                </span>
                                            )}
                                        </div>
                                    </div>
                                    <p className="text-xs text-text-muted line-clamp-3 font-light leading-relaxed opacity-70 group-hover:opacity-95 transition-opacity">
                                        {bot.description}
                                    </p>
                                </CardHeader>

                                <CardContent className="flex-grow relative z-10 px-5">
                                    <div className="space-y-3 p-4 rounded-2xl border bg-white/[0.02] border-white/5 backdrop-blur-sm">
                                        {/* Arquitectura — con truncate para evitar overflow */}
                                        <div className="flex justify-between items-center text-[10px] pb-2 border-b border-white/5 gap-3">
                                            <span className="text-text-muted uppercase tracking-[0.15em] font-bold shrink-0">Arquitectura</span>
                                            <span className={`font-black uppercase ${colors.accent} text-right leading-tight text-[9px] truncate max-w-[120px]`}>
                                                {bot.strategyType}
                                            </span>
                                        </div>
                                        {/* Factor Riesgo */}
                                        <div className="flex justify-between items-center text-[10px] pb-2 border-b border-white/5 gap-3">
                                            <span className="text-text-muted uppercase tracking-[0.15em] font-bold shrink-0">Factor Riesgo</span>
                                            <span className={`font-black uppercase text-[9px] ${bot.riskLevel === 'Low' ? 'text-success' : bot.riskLevel === 'High' ? 'text-danger' : 'text-amber-400'}`}>
                                                {bot.riskLevel}
                                            </span>
                                        </div>

                                        {/* Mini chart */}
                                        <div className="pt-1">
                                            <div className="flex justify-between items-center mb-2">
                                                <span className="text-[8px] uppercase tracking-[0.3em] font-black text-white/20 italic">Previsión Alpha</span>
                                                <span className="flex items-center gap-1">
                                                    <div className="w-1 h-1 rounded-full bg-success animate-ping" />
                                                    <span className="text-[8px] text-success font-black tracking-widest uppercase">Live</span>
                                                </span>
                                            </div>
                                            <div className="h-10 flex items-end gap-1 w-full">
                                                {[25, 45, 30, 60, 55, 85, 70, 95, 80, 100].map((h, i) => (
                                                    <div
                                                        key={i}
                                                        className="flex-1 rounded-t-sm transition-all duration-[1.5s] bg-gradient-to-t from-transparent via-success/10 to-success/60 opacity-40 group-hover:opacity-100"
                                                        style={{ height: `${h}%`, transitionDelay: `${i * 50}ms` }}
                                                    />
                                                ))}
                                            </div>
                                        </div>
                                    </div>
                                </CardContent>

                                <CardFooter className="flex-col items-center mt-auto border-t border-white/5 pt-5 px-5 pb-5 bg-black/10 gap-3">
                                    {isDemo && !isUpcoming ? (
                                        /* Demo: precio centrado + botón */
                                        <>
                                            <div className="text-center">
                                                <div className="flex items-baseline justify-center gap-1 mb-0.5">
                                                    <span className="text-3xl font-black tracking-tighter italic text-white">1€</span>
                                                    <span className="text-[8px] font-bold uppercase tracking-widest text-white/30">/ 30 días</span>
                                                </div>
                                                <div className="text-[7px] text-amber-400 font-black tracking-[0.25em] uppercase italic">
                                                    Licencia Demo
                                                </div>
                                            </div>
                                            <Link href={`/bots/${bot.id}`} className="w-full">
                                                <Button size="sm" className="w-full font-black uppercase tracking-[0.12em] text-[9px] h-10 shadow-xl transition-all duration-500 rounded-xl bg-white text-black hover:bg-brand-light hover:text-white hover:scale-105 active:scale-95">
                                                    Activar Demo ⚡
                                                </Button>
                                            </Link>
                                        </>
                                    ) : (
                                        /* Comerciales o Demos Desconectadas: solo botón centrado */
                                        <Link href={`/bots/${bot.id}`} className="w-full">
                                            <Button size="sm" className="w-full font-black uppercase tracking-[0.12em] text-[9px] h-10 shadow-xl transition-all duration-500 rounded-xl bg-brand/10 text-brand-light border border-brand/30 hover:bg-brand/20 hover:scale-105 active:scale-95">
                                                {bot.status === 'MAINTENANCE' ? 'En Mantenimiento' : 'Próximamente'}
                                            </Button>
                                        </Link>
                                    )}
                                </CardFooter>
                            </Card>
                        );
                    })}
                </div>
            )}
        </div>
    );
}

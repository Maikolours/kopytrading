import { Metadata } from "next";
import Link from "next/link";
import { getServerSession } from "next-auth/next";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { Card, CardContent, CardTitle, CardHeader, CardFooter } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";

export const metadata: Metadata = {
  title: "Vanguard Marketplace | KopyTrading",
  description: "Acceso institucional a algoritmos de alta frecuencia: Storm Rider, La Ametralladora y más.",
};

export const dynamic = "force-dynamic";

export default async function BotsPage({ searchParams }: { searchParams: Promise<{ asset?: string }> }) {
    const session = await getServerSession(authOptions);
    const isOwner = session?.user?.email === "viajaconsakura@gmail.com" || session?.user?.email === "viajaconsakura";
    const { asset } = await searchParams;

    // Filters for the 4 master products
    const whereClause: any = { isActive: true };
    if (asset) {
        whereClause.instrument = { contains: asset };
    }

    const bots = await prisma.botProduct.findMany({
        where: whereClause,
        orderBy: { createdAt: 'desc' }
    });

    const categories = [
        { id: "", label: "Todos" },
        { id: "BTCUSD", label: "Elite Sniper v13" },
        { id: "XAUUSD", label: "Elite Gold Ametralladora" },
        { id: "EURUSD", label: "Euro Precision" },
        { id: "USDJPY", label: "Ninja Ghost" }
    ];

    // Helper to map DB names to the requested specific branding
    const getBotDisplayData = (bot: any) => {
        const name = bot.name.toLowerCase();
        if (name.includes('storm') || name.includes('sniper')) return { name: "Elite Sniper v13 ⚡", accent: "text-brand-light", badge: "from-brand-light to-brand" };
        if (name.includes('ametralladora')) return { name: "Elite Gold Ametralladora 🔥", accent: "text-amber-400", badge: "from-amber-400 to-orange-600" };
        if (name.includes('ninja')) return { name: "Ninja Ghost 🥷", accent: "text-rose-400", badge: "from-rose-400 to-pink-600" };
        if (name.includes('precision') || name.includes('euro')) return { name: "Euro Precision 🎯", accent: "text-emerald-400", badge: "from-emerald-400 to-teal-600" };
        return { name: bot.name, accent: "text-white", badge: "from-white/20 to-white/5" };
    };

    return (
        <div className="min-h-screen pt-28 md:pt-32 pb-12 px-6 sm:px-6 lg:px-8 relative overflow-hidden bg-[#050505]">

            {/* Vanguard Background GFX */}
            <div className="absolute top-[-10%] right-[-10%] w-[800px] h-[800px] bg-brand-light/5 blur-[150px] rounded-full pointer-events-none" />
            <div className="absolute bottom-[-10%] left-[-10%] w-[600px] h-[600px] bg-brand/5 blur-[120px] rounded-full pointer-events-none" />

            <div className="max-w-7xl mx-auto relative z-10 mb-4">
                <Link href="/" className="inline-flex items-center gap-2 text-xs font-black uppercase tracking-widest text-text-muted hover:text-white transition-all group">
                    <span className="group-hover:-translate-x-1 transition-transform">←</span> Volver al inicio
                </Link>
            </div>

            <div id="bot-catalog" className="max-w-7xl mx-auto mb-16 pb-12 text-center relative">
                <div className="mb-10">
                    <h1 className="text-5xl sm:text-7xl font-black text-white tracking-tighter mb-4 uppercase italic leading-none">
                        Vanguard <span className="text-transparent bg-clip-text bg-gradient-to-r from-brand-light to-brand">Algorithms</span>
                    </h1>
                    <p className="text-text-muted text-lg max-w-2xl mx-auto font-light tracking-tight opacity-60 italic leading-relaxed">
                        Sistemas de alta frecuencia y precisión institucional para el mercado MT5.
                    </p>
                </div>

                <div className="flex flex-wrap gap-2 md:gap-3 justify-center">
                    {categories.map((cat) => (
                        <Link key={cat.id} href={cat.id ? `/bots?asset=${cat.id}` : "/bots"}>
                            <span className={`px-6 py-2.5 rounded-full text-[10px] font-black tracking-[0.2em] uppercase transition-all ${(asset === cat.id || (!asset && cat.id === ""))
                                ? "bg-brand text-white shadow-[0_0_25px_rgba(168,85,247,0.4)] border border-brand-light/50"
                                : "bg-white/[0.03] border border-white/5 text-text-muted hover:text-white hover:border-white/20"
                                }`}>
                                {cat.label}
                            </span>
                        </Link>
                    ))}
                </div>
            </div>

            {bots.length === 0 ? (
                <div className="text-center py-20 px-4 glass-card border border-dashed border-white/10 rounded-[2rem]">
                    <h3 className="text-2xl font-black text-white mb-4 italic uppercase tracking-tighter opacity-40">No hay terminales disponibles</h3>
                    <p className="text-text-muted mb-8 max-w-md mx-auto">Nuestro equipo está calibrando los servidores para estos activos. Vuelve pronto.</p>
                    <Link href="/bots"><Button variant="outline" className="rounded-xl border-white/10 text-white/40">Ver todos</Button></Link>
                </div>
            ) : (
                <div className={`grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8`}>
                    {bots.map((bot: any) => {
                        const display = getBotDisplayData(bot);
                        const isUpcoming = bot.status === 'UPCOMING' || bot.status === 'MAINTENANCE';

                        return (
                            <Card key={bot.id} interactive className={`flex flex-col h-full transition-all duration-700 overflow-hidden group relative rounded-[2rem] border ${
                                isUpcoming 
                                ? 'bg-white/[0.01] border-white/5 backdrop-blur-[2px]' 
                                : `bg-white/[0.03] border-white/10 hover:border-brand-light/50 shadow-[0_20px_60px_rgba(0,0,0,0.6)]`
                            }`}>
                                <CardHeader className="relative overflow-hidden pb-4">
                                     {/* Background Glow Overlay */}
                                    <div className={`absolute top-0 right-0 w-32 h-32 bg-brand/10 blur-3xl -mr-16 -mt-16 transition-opacity duration-700 group-hover:opacity-100 opacity-20`} />

                                    <div className="flex justify-between items-start mb-2 relative z-10">
                                        <CardTitle className={`text-2xl font-black italic tracking-tighter uppercase transition-all duration-500 ${isUpcoming ? 'text-white/20' : 'text-white'}`}>
                                            {display.name}
                                        </CardTitle>
                                        <span className={`bg-gradient-to-br ${display.badge} text-white px-3 py-1 rounded-full text-[9px] font-black tracking-widest shadow-lg uppercase ${isUpcoming && 'opacity-20 grayscale'}`}>
                                            {bot.instrument}
                                        </span>
                                    </div>
                                    <p className={`text-xs text-text-muted line-clamp-2 font-light leading-relaxed ${isUpcoming ? 'opacity-20' : 'opacity-60'}`}>
                                        {bot.description.replace(/⚡|🛠️|🛡️|🎯|🥷/g, '').replace('PRÓXIMO LANZAMIENTO', '').trim()}
                                    </p>
                                </CardHeader>

                                <CardContent className="flex-grow relative z-10 px-6">
                                    <div className={`space-y-4 p-5 rounded-2xl border transition-all duration-700 ${
                                        isUpcoming ? 'bg-white/0 border-white/0 opacity-20' : 'bg-white/[0.02] border-white/5 backdrop-blur-sm'
                                    }`}>
                                        <div className="flex justify-between items-center text-[10px] pb-2 border-b border-white/5">
                                            <span className="text-text-muted uppercase tracking-[0.2em] font-bold">Arquitectura</span>
                                            <span className={`font-black tracking-tighter uppercase ${isUpcoming ? 'text-white/30' : display.accent}`}>
                                                {isUpcoming ? 'Confidential' : bot.strategyType}
                                            </span>
                                        </div>
                                        <div className="flex justify-between items-center text-[10px] pb-2 border-b border-white/5">
                                            <span className="text-text-muted uppercase tracking-[0.2em] font-bold">Factor Riesgo</span>
                                            <span className={`font-black flex items-center gap-2 uppercase ${
                                                isUpcoming ? 'text-white/30' :
                                                bot.riskLevel === 'Low' ? 'text-success' : 
                                                bot.riskLevel === 'High' ? 'text-danger' : 'text-amber-400'
                                            }`}>
                                                {isUpcoming ? '???' : bot.riskLevel}
                                            </span>
                                        </div>

                                        <div className="pt-2">
                                            <div className="flex justify-between items-center mb-4">
                                                <span className="text-[9px] uppercase tracking-[0.3em] font-black text-white/20 italic">Previsión Alpha</span>
                                                {!isUpcoming && (
                                                    <span className="flex items-center gap-1">
                                                        <div className="w-1 h-1 rounded-full bg-success animate-ping" />
                                                        <span className="text-[9px] text-success font-black tracking-widest uppercase">Live</span>
                                                    </span>
                                                )}
                                            </div>
                                            <div className="h-14 flex items-end gap-1.5 w-full">
                                                {[25, 45, 30, 60, 55, 85, 70, 95, 80, 100].map((h, i) => (
                                                    <div
                                                        key={i}
                                                        className={`flex-1 rounded-t-sm transition-all duration-[1.5s] ${
                                                            isUpcoming 
                                                            ? 'bg-white/5 opacity-20' 
                                                            : 'bg-gradient-to-t from-transparent via-success/10 to-success/60 opacity-30 group-hover:opacity-100'
                                                        }`}
                                                        style={{ height: `${h}%`, transitionDelay: `${i * 50}ms` }}
                                                    />
                                                ))}
                                            </div>
                                        </div>
                                    </div>

                                    {/* Glassmorphic "Upcoming" Overlay - Only for Public */}
                                    {isUpcoming && (
                                        <div className="absolute inset-0 z-20 flex flex-col items-center justify-center p-6 text-center transform scale-[1.05]">
                                             <div className="px-5 py-2.5 rounded-full bg-brand/10 border border-brand/40 shadow-[0_0_40px_rgba(168,85,247,0.3)] backdrop-blur-xl mb-4 group-hover:scale-110 transition-transform duration-500">
                                                <span className="text-[10px] font-black text-brand-light uppercase tracking-[0.5em] animate-pulse">
                                                    {bot.status === 'MAINTENANCE' ? 'CALIBRANDO' : 'PRÓXIMO LANZAMIENTO'}
                                                </span>
                                            </div>
                                            <div className="text-white/20 text-[8px] font-bold uppercase tracking-[0.3em] max-w-[160px] leading-relaxed italic">
                                                Algoritmo en fase final de calibración institucional
                                            </div>
                                        </div>
                                    )}
                                </CardContent>

                                <CardFooter className="justify-between items-center mt-auto border-t border-white/5 pt-6 p-8 bg-black/10">
                                    <div className="flex flex-col">
                                        <div className="flex items-center gap-2">
                                            <div className={`text-3xl font-black tracking-tighter italic ${isUpcoming ? 'text-white/10' : 'text-white'}`}>
                                                ${bot.price.toFixed(0)}
                                            </div>
                                            <span className={`text-[9px] font-bold uppercase tracking-widest ${isUpcoming ? 'text-white/5' : 'text-white/30'}`}>USD</span>
                                        </div>
                                        {!isUpcoming && (
                                            <div className="text-[8px] text-success font-black tracking-[0.3em] uppercase flex items-center gap-1 mt-1 italic">
                                                Pre-Venta Activa
                                            </div>
                                        )}
                                    </div>
                                    <Link href={`/bots/${bot.id}`} className={(isUpcoming && !isOwner) ? 'pointer-events-none' : ''}>
                                        <Button 
                                            size="lg" 
                                            className={`font-black uppercase tracking-[0.2em] text-[10px] px-8 h-11 shadow-2xl transition-all duration-500 rounded-xl ${
                                                (!isUpcoming || isOwner) 
                                                ? 'bg-white text-black hover:bg-brand-light hover:text-white hover:scale-105 active:scale-95' 
                                                : 'bg-white/5 text-white/10 border border-white/5 cursor-not-allowed opacity-50'
                                            }`}
                                            disabled={isUpcoming && !isOwner}
                                        >
                                            {(!isUpcoming || isOwner) ? 'Invertir' : 'Próximamente'}
                                        </Button>
                                    </Link>
                                </CardFooter>
                            </Card>
                        );
                    })}
                </div>
            )}
        </div>
    );
}

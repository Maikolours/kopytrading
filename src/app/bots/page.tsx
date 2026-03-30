import { Metadata } from "next";
import Link from "next/link";
import { getServerSession } from "next-auth/next";
import { authOptions } from "@/lib/auth";

export const metadata: Metadata = {
  title: "Marketplace de Bots | MT5 Trading Algorítmico",
  description: "Explora nuestro catálogo de Expert Advisors para MetaTrader 5. Consigue acceso a La Ametralladora Evolution, BTC Storm Rider y más.",
};
import { prisma } from "@/lib/prisma";
import { Card, CardContent, CardTitle, CardHeader, CardFooter } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { Countdown } from "@/components/Countdown";

export const dynamic = "force-dynamic";

export default async function BotsPage({ searchParams }: { searchParams: Promise<{ asset?: string }> }) {
    const session = await getServerSession(authOptions);
    const isOwner = session?.user?.email === "viajaconsakura@gmail.com" || session?.user?.email === "viajaconsakura";
    const { asset } = await searchParams;

    const whereClause: any = isOwner 
        ? { productKey: { not: null } }  // Solo mostrar los bots "llave en mano" con ProductKey
        : { isActive: true };
    if (asset) {
        whereClause.instrument = { contains: asset };
    }

    const bots = await prisma.botProduct.findMany({
        where: whereClause,
        orderBy: { createdAt: 'desc' }
    });

    const categories = [
        { id: "", label: "Todos" },
        { id: "XAUUSD", label: "Oro (XAUUSD)" },
        { id: "EURUSD", label: "EURUSD" },
        { id: "USDJPY", label: "USDJPY" },
        { id: "BTCUSD", label: "Bitcoin" }
    ];

    return (
        <div className="min-h-screen pt-28 md:pt-32 pb-12 px-6 sm:px-6 lg:px-8 relative overflow-hidden">

            <div className="absolute top-1/4 left-1/4 w-[500px] h-[500px] bg-brand-light/5 blur-[120px] rounded-full pointer-events-none" />

            <div className="max-w-7xl mx-auto relative z-10 mb-4">
                <Link href="/" className="inline-flex items-center gap-2 text-sm text-text-muted hover:text-white transition-colors">
                    <span>←</span> Volver al inicio
                </Link>
            </div>


            <div id="bot-catalog" className="max-w-7xl mx-auto mb-10 border-b border-white/10 pb-8 text-center">
                <div className="mb-6">
                    <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tighter mb-4 uppercase italic">Marketplace de Bots</h1>

                    <p className="text-text-muted text-lg max-w-2xl mx-auto font-light">Encuentra los algoritmos más precisos para MetaTrader 5.</p>
                </div>

                <div className="flex flex-wrap gap-2 md:gap-3 justify-center">
                    {categories.map((cat) => (
                        <Link key={cat.id} href={cat.id ? `/bots?asset=${cat.id}` : "/bots"}>
                            <span className={`px-4 py-2 rounded-full text-sm font-medium transition-all ${(asset === cat.id || (!asset && cat.id === ""))
                                ? "bg-brand text-white shadow-[0_0_15px_rgba(139,92,246,0.4)] relative"
                                : "bg-surface-light border border-white/5 text-text-muted hover:text-white hover:border-brand/50 relative"
                                }`}>
                                {cat.label}
                                {(asset === cat.id || (!asset && cat.id === "")) && (
                                    <div className="absolute inset-0 bg-brand blur opacity-50 rounded-full -z-10 animate-pulse"></div>
                                )}
                            </span>
                        </Link>
                    ))}
                </div>
            </div>

            {bots.length === 0 ? (
                <div className="text-center py-20 px-4 glass-card border border-dashed border-white/20">
                    <h3 className="text-xl font-medium text-white mb-2">Aún no hay bots disponibles para esta categoría</h3>
                    <p className="text-text-muted mb-6">Sigue explorando otros activos o vuelve pronto.</p>
                    <Link href="/bots"><Button variant="outline">Ver todos los bots</Button></Link>
                </div>
            ) : (
                <div className={`grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8`}>
                    {bots.map((bot: any) => {
                        const instrument = (bot.instrument || '').trim().toUpperCase();
                        const colorMap: Record<string, any> = {
                            'XAUUSD': { border: 'hover:border-purple-500/50', badge: 'from-purple-500/80 to-indigo-600/80', glow: 'shadow-purple-500/40', accent: 'text-purple-400', bg: 'bg-purple-500/10' },
                            'BTCUSD': { border: 'hover:border-amber-500/50', badge: 'from-amber-400/80 to-orange-600/80', glow: 'shadow-amber-500/40', accent: 'text-amber-400', bg: 'bg-amber-500/10' },
                            'EURUSD': { border: 'hover:border-emerald-500/50', badge: 'from-emerald-400/80 to-teal-600/80', glow: 'shadow-emerald-500/40', accent: 'text-emerald-400', bg: 'bg-emerald-500/10' },
                            'USDJPY': { border: 'hover:border-rose-500/50', badge: 'from-rose-400/80 to-pink-600/80', glow: 'shadow-rose-500/40', accent: 'text-rose-400', bg: 'bg-rose-500/10' },
                        };
                        const colors = colorMap[instrument] || { border: 'hover:border-brand/50', badge: 'from-brand-light/80 to-brand/80', glow: 'shadow-brand/40', accent: 'text-brand-light', bg: 'bg-brand/10' };

                        return (
                            <Card key={bot.id} interactive className={`flex flex-col h-full bg-white/[0.03] border-white/10 ${colors.border} transition-all duration-500 shadow-[0_20px_50px_rgba(0,0,0,0.5)] hover:shadow-2xl overflow-hidden group perspective-1000`}>
                                <CardHeader className="relative overflow-hidden">
                                     {/* Background Glow Overlay */}
                                    <div className={`absolute top-0 right-0 w-32 h-32 ${colors.bg} blur-3xl -mr-16 -mt-16 transition-opacity duration-700 group-hover:opacity-100 opacity-30`} />

                                    <div className="flex justify-between items-start mb-2 relative z-10">
                                        <CardTitle className="text-xl font-black italic tracking-tighter uppercase">{bot.name}</CardTitle>
                                        <span className={`bg-gradient-to-br ${colors.badge} text-white px-3 py-1 rounded-full text-[10px] font-black tracking-widest shadow-lg uppercase`}>
                                            {bot.instrument}
                                        </span>
                                    </div>
                                    <p className="text-sm text-text-muted line-clamp-2 font-light">{bot.description}</p>
                                </CardHeader>

                                <CardContent className="flex-grow relative z-10">
                                    <div className="space-y-4 bg-white/[0.02] p-5 rounded-2xl border border-white/5 backdrop-blur-sm">
                                        <div className="flex justify-between items-center text-xs pb-2 border-b border-white/5">
                                            <span className="text-text-muted uppercase tracking-widest font-bold">Estrategia</span>
                                            <span className={`font-black ${colors.accent}`}>{bot.strategyType}</span>
                                        </div>
                                        <div className="flex justify-between items-center text-xs pb-2 border-b border-white/5">
                                            <span className="text-text-muted uppercase tracking-widest font-bold">Riesgo</span>
                                            <span className={`font-black flex items-center gap-1.5 ${bot.riskLevel === 'Low' ? 'text-success'
                                                : bot.riskLevel === 'High' ? 'text-danger'
                                                    : 'text-amber-400'
                                                }`}>
                                                <div className={`w-2 h-2 rounded-full ${bot.riskLevel === 'Low' ? 'bg-success' : bot.riskLevel === 'High' ? 'bg-danger' : 'bg-amber-400'} shadow-[0_0_8px_currentColor]`} />
                                                {bot.riskLevel}
                                            </span>
                                        </div>

                                        <div className="pt-3">
                                            <div className="flex justify-between items-center mb-3">
                                                <span className="text-[10px] uppercase tracking-[0.2em] font-black text-text-muted">Proyección Algorítmica</span>
                                                <span className="text-[10px] text-success font-black flex items-center gap-1 bg-success/10 px-2 py-0.5 rounded-full">
                                                    <span className="w-1 h-1 rounded-full bg-success animate-pulse"></span>
                                                    ALPHA+
                                                </span>
                                            </div>
                                            <div className="h-12 flex items-end gap-1.5 w-full group/chart">
                                                {[25, 45, 30, 60, 55, 85, 70, 95, 80, 100].map((h, i) => (
                                                    <div
                                                        key={i}
                                                        className={`flex-1 bg-gradient-to-t from-transparent via-success/10 to-success/60 rounded-t-sm transition-all duration-500 group-hover/chart:opacity-100`}
                                                        style={{ height: `${h}%`, opacity: 0.2 + (i * 0.08) }}
                                                    />
                                                ))}
                                            </div>
                                        </div>
                                    </div>

                                    {/* STATUS OVERLAYS (GLASSMORPISM PRO) */}
                                    {bot.status === "MAINTENANCE" && (
                                        <div className="absolute inset-0 z-20 bg-bg-dark/60 backdrop-blur-xl flex flex-col items-center justify-center p-6 text-center border border-white/5 rounded-2xl scale-[1.01]">
                                            <div className="w-20 h-20 rounded-full bg-white/5 flex items-center justify-center mb-4 border border-white/10 shadow-2xl shadow-black">
                                                <span className="text-4xl animate-pulse">⚙️</span>
                                            </div>
                                            <h4 className="text-2xl font-black text-white mb-2 uppercase tracking-tighter italic">Calibrando</h4>
                                            <p className="text-xs text-text-muted font-medium bg-black/40 px-4 py-2 rounded-full border border-white/5">Acceso restringido temporalmente</p>
                                        </div>
                                    )}

                                    {bot.status === "UPCOMING" && (
                                        <div className="absolute inset-0 z-20 bg-brand-dark/40 backdrop-blur-md flex flex-col items-center justify-center p-6 text-center scale-[1.01]">
                                            <div className="w-16 h-16 rounded-full bg-brand/30 flex items-center justify-center mb-4 border border-brand/40 animate-bounce shadow-2xl shadow-brand/20">
                                                <span className="text-3xl">☄️</span>
                                            </div>
                                            <h4 className="text-xl font-black text-white mb-1 uppercase tracking-tighter italic drop-shadow-2xl">Próximo Alpha</h4>
                                            <Countdown targetDate="2026-04-01T00:00:00" />
                                        </div>
                                    )}
                                </CardContent>

                                <CardFooter className="justify-between items-center mt-auto border-t border-white/10 pt-6 bg-black/10">
                                    <div className="flex flex-col">
                                        <div className="flex items-center gap-2">
                                            <div className="text-3xl font-black text-white tracking-tighter">
                                                ${bot.price.toFixed(2)}
                                            </div>
                                            {bot.originalPrice && bot.originalPrice > bot.price && (
                                                <div className="text-sm text-text-muted line-through opacity-30 font-bold">
                                                    ${bot.originalPrice.toFixed(2)}
                                                </div>
                                            )}
                                        </div>
                                        <div className="text-[9px] text-success font-black tracking-[0.2em] uppercase flex items-center gap-1 mt-1">
                                            <span className="bg-success/10 px-2 py-0.5 rounded border border-success/20">Lanzamiento</span>
                                        </div>
                                    </div>
                                    <Link href={`/bots/${bot.id}`} className={(bot.status !== 'ACTIVE' && !isOwner) ? 'pointer-events-none opacity-20' : ''}>
                                        <Button 
                                            size="lg" 
                                            className={`font-black uppercase tracking-widest text-[10px] px-6 h-10 shadow-2xl transition-all duration-300 ${bot.status === 'ACTIVE' || isOwner ? 'hover:scale-105 active:scale-95' : ''}`}
                                            disabled={bot.status !== 'ACTIVE' && !isOwner}
                                        >
                                            {(bot.status === 'ACTIVE' || isOwner) ? 'Invertir' : 'Cerrado'}
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

import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { Card, CardContent, CardTitle, CardHeader, CardFooter } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { Countdown } from "@/components/Countdown";

export const dynamic = "force-dynamic";

export default async function BotsPage({ searchParams }: { searchParams: Promise<{ asset?: string }> }) {
    const { asset } = await searchParams;

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
                <div className={`grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6`}>
                    {bots.map((bot: any) => (
                        <Card key={bot.id} interactive className="flex flex-col h-full bg-surface-light/20">
                            <CardHeader>
                                <div className="flex justify-between items-start mb-2">
                                    <CardTitle className="text-xl">{bot.name}</CardTitle>
                                    <span className="bg-gradient-to-br from-brand-light to-brand text-white px-2 py-1 rounded text-xs font-bold tracking-wider shadow-[0_0_10px_rgba(139,92,246,0.5)]">
                                        {bot.instrument}
                                    </span>
                                </div>
                                <p className="text-sm text-text-muted line-clamp-2">{bot.description}</p>
                            </CardHeader>

                            <CardContent className="flex-grow">
                                <div className="space-y-3 bg-black/20 p-4 rounded-xl border border-white/5">
                                    <div className="flex justify-between items-center text-sm pb-2 border-b border-white/5">
                                        <span className="text-text-muted">Estrategia</span>
                                        <span className="font-medium text-white">{bot.strategyType}</span>
                                    </div>
                                    <div className="flex justify-between items-center text-sm pb-2 border-b border-white/5">
                                        <span className="text-text-muted">Riesgo</span>
                                        <span className={`font-medium flex items-center gap-1 ${bot.riskLevel === 'Low' ? 'text-success'
                                            : bot.riskLevel === 'High' ? 'text-danger'
                                                : 'text-amber-400'
                                            }`}>
                                            <span className={`w-1.5 h-1.5 rounded-full ${bot.riskLevel === 'Low' ? 'bg-success' : bot.riskLevel === 'High' ? 'bg-danger' : 'bg-amber-400'}`}></span>
                                            {bot.riskLevel}
                                        </span>
                                    </div>
                                    <div className="flex justify-between items-center text-sm">
                                        <span className="text-text-muted">Timeframes</span>
                                        <span className="font-medium text-white">{bot.timeframes || '-'}</span>
                                    </div>
                                    <div className="pt-3 mt-3 border-t border-white/5">
                                        <div className="flex justify-between items-center mb-2">
                                            <span className="text-[10px] uppercase tracking-wider text-text-muted">Curva de Equidad</span>
                                            <span className="text-xs text-success font-bold flex items-center gap-1">
                                                <span className="w-1.5 h-1.5 rounded-full bg-success animate-pulse"></span>
                                                Positiva
                                            </span>
                                        </div>
                                        <div className="h-8 flex items-end gap-1 w-full">
                                            {[30, 40, 35, 50, 45, 65, 60, 80, 75, 100].map((h, i) => (
                                                <div
                                                    key={i}
                                                    className="flex-1 bg-gradient-to-t from-success/20 to-success rounded-t-sm transition-all duration-300 hover:opacity-100"
                                                    style={{ height: `${h}%`, opacity: 0.4 + (i * 0.06) }}
                                                />
                                            ))}
                                        </div>
                                    </div>
                                </div>

                                {/* STATUS OVERLAYS */}
                                {bot.status === "MAINTENANCE" && (
                                    <div className="absolute inset-0 z-20 bg-bg-dark/80 backdrop-blur-sm flex flex-col items-center justify-center p-6 text-center">
                                        <div className="w-16 h-16 rounded-full bg-amber-500/20 flex items-center justify-center mb-4 border border-amber-500/30">
                                            <span className="text-3xl">🛠️</span>
                                        </div>
                                        <h4 className="text-xl font-bold text-white mb-2 uppercase tracking-tighter italic">Mantenimiento</h4>
                                        <p className="text-sm text-text-muted">Estamos optimizando este bot. Volverá a estar disponible muy pronto.</p>
                                    </div>
                                )}

                                {bot.status === "UPCOMING" && (
                                    <div className="absolute inset-0 z-20 bg-brand-dark/95 backdrop-blur-md flex flex-col items-center justify-center p-6 text-center">
                                        <div className="w-16 h-16 rounded-full bg-brand/20 flex items-center justify-center mb-4 border border-brand/30 animate-pulse">
                                            <span className="text-3xl">🚀</span>
                                        </div>
                                        <h4 className="text-xl font-black text-white mb-1 uppercase tracking-tighter italic">Próximo Lanzamiento</h4>
                                        <p className="text-[10px] text-brand-light font-bold mb-4 uppercase tracking-[0.2em]">{bot.name.includes("Ametralladora") ? "Ametralladora Evolution" : bot.name.includes("BTC") ? "Storm Rider 6.6" : "Nuevo Bot"}</p>
                                        <Countdown targetDate="2026-03-24T22:00:00" />
                                        <div className="mt-6 text-[10px] font-black uppercase tracking-widest text-white/40 hover:text-white transition-colors border-b border-white/10 pb-1">Permanece atento</div>
                                    </div>
                                )}
                            </CardContent>

                            <CardFooter className="justify-between items-center mt-auto border-t border-white/10 pt-4">
                                <div className="flex flex-col">
                                    <div className="text-2xl font-bold text-white tracking-tight">
                                        ${bot.price.toFixed(2)}
                                    </div>
                                    <div className="text-[10px] text-success font-semibold tracking-wider uppercase">1 Mes Gratis</div>
                                </div>
                                <Link href={`/bots/${bot.id}`} className={bot.status !== 'ACTIVE' ? 'pointer-events-none opacity-20' : ''}>
                                    <Button size="sm" className="shadow-[0_0_15px_rgba(139,92,246,0.3)] hover:shadow-[0_0_20px_rgba(139,92,246,0.6)]" disabled={bot.status !== 'ACTIVE'}>
                                        {bot.status === 'ACTIVE' ? 'Descargar' : 'No disponible'}
                                    </Button>
                                </Link>
                            </CardFooter>
                        </Card>
                    ))}
                </div>
            )}
        </div>
    );
}

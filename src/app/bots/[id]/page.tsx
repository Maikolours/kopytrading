import { notFound } from "next/navigation";
import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { Button } from "@/components/ui/Button";

export default async function BotDetailPage({ params }: { params: Promise<{ id: string }> }) {
    const { id } = await params;

    const bot = await prisma.botProduct.findUnique({
        where: { id: id }
    });

    if (!bot || !bot.isActive) {
        notFound();
    }

    return (
        <div className="min-h-screen pt-24 pb-12 px-4 sm:px-6 lg:px-8">
            <div className="max-w-5xl mx-auto">
                <div className="mb-8">
                    <Link href="/bots" className="text-brand-light hover:text-white transition-colors text-sm flex items-center gap-2">
                        ← Volver al Marketplace
                    </Link>
                </div>

                <div className="grid lg:grid-cols-3 gap-12">
                    {/* Main Content */}
                    <div className="lg:col-span-2 space-y-8">
                        <div className="glass-card p-8 border border-white/10">
                            <h1 className="text-4xl font-bold text-white mb-4">{bot.name}</h1>
                            <div className="flex flex-wrap gap-2 mb-6">
                                <span className="bg-brand/20 text-brand-light px-3 py-1 rounded-full text-sm font-semibold">{bot.instrument}</span>
                                <span className="bg-surface-light/50 text-white px-3 py-1 rounded-full text-sm">{bot.strategyType}</span>
                                <span className={`px-3 py-1 rounded-full text-sm font-semibold ${bot.riskLevel === 'Low' ? 'bg-success/20 text-success'
                                    : bot.riskLevel === 'High' ? 'bg-danger/20 text-danger'
                                        : 'bg-amber-400/20 text-amber-400'
                                    }`}>Riesgo {bot.riskLevel}</span>
                            </div>

                            <div className="prose prose-invert max-w-none">
                                <h3 className="text-xl font-semibold mb-2">Descripción de la Estrategia</h3>
                                <p className="text-text-muted leading-relaxed whitespace-pre-wrap">{bot.description}</p>
                            </div>
                        </div>

                        <div className="glass-card p-8 border border-white/10 space-y-6">
                            <h3 className="text-xl font-semibold text-white">Especificaciones Técnicas</h3>

                            <div className="grid sm:grid-cols-2 gap-6">
                                <div className="space-y-1">
                                    <p className="text-sm text-text-muted">Timeframes Recomendados</p>
                                    <p className="font-medium text-white">{bot.timeframes || 'H1, M15'}</p>
                                </div>
                                <div className="space-y-1">
                                    <p className="text-sm text-text-muted">Capital Mínimo Recomendado</p>
                                    <p className="font-medium text-white">${bot.minCapital ? bot.minCapital.toLocaleString() : '500'}</p>
                                </div>
                            </div>

                            <div className="border-t border-white/10 pt-6">
                                <h4 className="font-medium text-white mb-2">Resultados de Backtest</h4>
                                <div className="w-full h-48 bg-surface-light/30 rounded-lg border border-white/5 flex items-center justify-center text-text-muted text-sm">
                                    {bot.backtestResults ? (
                                        <img src={bot.backtestResults} alt="Backtest" className="w-full h-full object-cover rounded-lg opacity-80" />
                                    ) : (
                                        <span>[Gráfico de Rendimiento Simulado]</span>
                                    )}
                                </div>
                            </div>
                        </div>

                        <div className="bg-danger/10 border border-danger/20 rounded-xl p-6">
                            <h4 className="text-danger font-bold mb-2 flex items-center gap-2">
                                ⚠️ Aviso Importante de Riesgo
                            </h4>
                            <p className="text-sm text-danger/80">
                                El trading conlleva un alto nivel de riesgo y puede no ser adecuado para todos los inversores.
                                Los resultados históricos mostrados en backtests no garantizan rendimientos futuros.
                                Este bot es una herramienta de asistencia y tú eres el único responsable de la configuración,
                                supervisión y ejecución en tu cuenta. No se garantizan beneficios.
                            </p>
                        </div>
                    </div>

                    {/* Sidebar Purchase Card */}
                    <div className="lg:col-span-1">
                        <div className="sticky top-28 glass-card p-6 border-brand/30 border-2 shadow-[0_0_30px_rgba(139,92,246,0.15)]">
                            <div className="text-center mb-6 pb-6 border-b border-white/10">
                                <p className="text-text-muted mb-2">Precio de Licencia Única</p>
                                <div className="text-5xl font-bold text-white">${bot.price.toFixed(2)}</div>
                                <p className="text-sm text-success mt-2">✓ Sin suscripciones mensuales</p>
                            </div>

                            <div className="space-y-3 mb-8 text-sm text-text-muted">
                                <div className="flex items-center gap-2">
                                    <div className="w-1.5 h-1.5 rounded-full bg-brand-light"></div>
                                    Archivo .ex5 listo para usar
                                </div>
                                <div className="flex items-center gap-2">
                                    <div className="w-1.5 h-1.5 rounded-full bg-brand-light"></div>
                                    Manual de configuración PDF
                                </div>
                                <div className="flex items-center gap-2">
                                    <div className="w-1.5 h-1.5 rounded-full bg-brand-light"></div>
                                    Parámetros totalmente editables
                                </div>
                                <div className="flex items-center gap-2">
                                    <div className="w-1.5 h-1.5 rounded-full bg-brand-light"></div>
                                    Actualizaciones incluidas
                                </div>
                            </div>

                            <div className="space-y-3">
                                <Link href={`/checkout/${bot.id}`} className="block">
                                    <Button size="lg" fullWidth className="text-lg py-6 shadow-[0_0_20px_rgba(139,92,246,0.5)]">
                                        Comprar y Descargar
                                    </Button>
                                </Link>

                                <Link href={`/checkout/${bot.id}?trial=true`} className="block">
                                    <Button size="lg" variant="outline" fullWidth className="py-6 border-success/40 text-success hover:bg-success/10 hover:border-success/60">
                                        🎁 Probar Gratis 30 Días
                                    </Button>
                                </Link>
                            </div>

                            <p className="text-center text-xs text-text-muted mt-4">
                                Pago seguro. Descarga inmediata.
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}

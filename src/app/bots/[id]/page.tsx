import { notFound } from "next/navigation";
import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { Button } from "@/components/ui/Button";
import { getServerSession } from "next-auth/next";
import { authOptions } from "@/lib/auth";

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

    const colors = {
        'XAUUSD': { accent: 'text-purple-400', badge: 'bg-purple-500/20 text-purple-400 border-purple-500/30', glow: 'bg-purple-500/5', button: 'bg-purple-600 hover:bg-purple-500 shadow-purple-500/40', shadow: 'shadow-purple-500/20' },
        'BTCUSD': { accent: 'text-amber-400', badge: 'bg-amber-500/20 text-amber-400 border-amber-500/30', glow: 'bg-amber-500/5', button: 'bg-amber-600 hover:bg-amber-500 shadow-amber-500/40', shadow: 'shadow-amber-500/20' },
        'EURUSD': { accent: 'text-emerald-400', badge: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30', glow: 'bg-emerald-500/5', button: 'bg-emerald-600 hover:bg-emerald-500 shadow-emerald-500/40', shadow: 'shadow-emerald-500/20' },
        'USDJPY': { accent: 'text-rose-400', badge: 'bg-rose-500/20 text-rose-400 border-rose-500/30', glow: 'bg-rose-500/5', button: 'bg-rose-600 hover:bg-rose-500 shadow-rose-500/40', shadow: 'shadow-rose-500/20' },
    }[bot.instrument as string] || { accent: 'text-brand-light', badge: 'bg-brand/20 text-brand-light border-brand/30', glow: 'bg-brand/5', button: 'bg-brand hover:bg-brand-light shadow-brand/40', shadow: 'shadow-brand/20' };

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
                    <div className="lg:col-span-8 space-y-8">
                        <div className="glass-card p-8 sm:p-12 border border-white/10 relative overflow-hidden group">
                            <div className={`absolute top-0 left-0 w-1 h-full bg-gradient-to-b from-transparent via-${bot.instrument === 'XAUUSD' ? 'purple-500' : bot.instrument === 'BTCUSD' ? 'amber-500' : 'brand'}/50 to-transparent`} />
                            
                            <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 mb-10">
                                <div>
                                    <div className="flex items-center gap-3 mb-4">
                                        <span className={`px-4 py-1 rounded-full text-[10px] font-black tracking-[0.2em] border uppercase ${colors.badge}`}>
                                            {bot.instrument}
                                        </span>
                                        <span className="text-[10px] text-text-muted font-bold uppercase tracking-widest bg-white/5 px-3 py-1 rounded-full border border-white/5">
                                            Algorithmic Asset
                                        </span>
                                    </div>
                                    <h1 className="text-5xl sm:text-6xl font-black text-white tracking-tighter uppercase italic leading-[0.9]">{bot.name}</h1>
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
                                <p className="text-lg text-text-muted leading-relaxed font-light whitespace-pre-wrap drop-shadow-sm">
                                    {bot.description}
                                </p>
                                
                                {/* STATUS OVERLAYS for Detail Page */}
                                {bot.status === "MAINTENANCE" && (
                                    <div className="mt-12 bg-amber-500/10 backdrop-blur-xl border border-amber-500/30 rounded-2xl p-6 text-center shadow-2xl shadow-amber-500/10">
                                        <p className="text-amber-400 font-black flex items-center justify-center gap-3 uppercase tracking-widest text-sm italic">
                                            <span className="animate-spin text-xl">⚙️</span> CALIBRACIÓN TÉCNICA EN CURSO
                                        </p>
                                        <p className="text-[10px] text-amber-500/60 mt-2 uppercase tracking-widest">El acceso a este modelo está restringido temporalmente por mantenimiento.</p>
                                    </div>
                                )}
                            </div>
                        </div>

                        <div className="grid md:grid-cols-2 gap-8">
                            <div className="glass-card p-8 border border-white/5 space-y-6">
                                <h3 className="text-xs font-black text-white uppercase tracking-[0.3em] flex items-center gap-3">
                                    <span className={`w-2 h-2 rounded-full ${bot.riskLevel === 'Low' ? 'bg-success' : 'bg-amber-500'}`}></span>
                                    Especificaciones Técnicas
                                </h3>

                                <div className="grid grid-cols-2 gap-8">
                                    <div className="space-y-1">
                                        <p className="text-[10px] text-text-muted uppercase tracking-widest">Timeframes</p>
                                        <p className="text-xl font-black text-white italic">{bot.timeframes || 'H1 / M15'}</p>
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

                            <div className="glass-card p-8 border border-white/5 relative overflow-hidden">
                                <div className="flex items-center justify-between mb-8">
                                    <h4 className="text-[10px] font-black text-white uppercase tracking-[0.3em]">Rendimiento Histórico</h4>
                                    <span className="text-[9px] bg-success/10 text-success px-3 py-1 rounded-full border border-success/20 font-black uppercase tracking-widest">Auditado</span>
                                </div>

                                <div className="grid grid-cols-2 gap-6 relative z-10">
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

                        <div className="glass-card p-10 border border-white/10">
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
                    </div>

                    {/* Sidebar Purchase Card */}
                    <div className="lg:col-span-4">
                        <div className={`sticky top-28 glass-card p-10 border-white/10 border shadow-2xl ${colors.shadow} relative overflow-hidden group/side`}>
                            {/* Decorative Glow */}
                            <div className={`absolute -top-24 -right-24 w-48 h-48 ${colors.glow} blur-[80px] rounded-full group-hover/side:opacity-100 opacity-50 transition-opacity`} />
                            
                            <div className="text-center mb-10 pb-10 border-b border-white/5 relative z-10">
                                <p className="text-[10px] text-text-muted mb-4 uppercase tracking-[0.4em] font-black">Licencia Profesional</p>
                                <div className="text-7xl font-black text-white tracking-tighter leading-none italic mb-4">
                                    <span className="text-3xl align-top mr-1">$</span>
                                    {bot.price.toFixed(0)}
                                    <span className="text-lg text-text-muted ml-1 italic">.00</span>
                                </div>
                                <div className="inline-flex items-center gap-2 bg-success/10 text-success text-[10px] font-black px-4 py-1.5 rounded-full border border-success/20 uppercase tracking-widest">
                                    ✓ Lifetime Access
                                </div>
                            </div>

                            <div className="space-y-4 mb-10 relative z-10">
                                {[
                                    'Compilación Nativa .ex5',
                                    'Soporte Técnico 24/7',
                                    'Dashboard Connectivity',
                                    'Multi-cuenta (Binding)',
                                    'Actualizaciones de por vida'
                                ].map((item, i) => (
                                    <div key={i} className="flex items-center gap-4 text-sm text-text-muted group/item">
                                        <div className={`w-1.5 h-1.5 rounded-full bg-white/20 group-hover/item:bg-${bot.instrument === 'XAUUSD' ? 'purple-400' : 'brand-light'} transition-colors`}></div>
                                        <span className="font-medium group-hover/item:text-white transition-colors">{item}</span>
                                    </div>
                                ))}
                            </div>

                            <div className="space-y-4 relative z-10">
                                {bot.status === 'ACTIVE' ? (
                                    <>
                                        <Link href={`/checkout/${bot.id}`} className="block">
                                            <Button size="lg" fullWidth className={`text-base py-8 shadow-2xl uppercase tracking-widest font-black italic transition-all hover:scale-[1.02] active:scale-[0.98] ${colors.button}`}>
                                                Invertir Ahora
                                            </Button>
                                        </Link>

                                        <Link href={`/checkout/${bot.id}?trial=true`} className="block">
                                            <Button size="lg" variant="outline" fullWidth className="py-7 border-white/10 text-white font-black uppercase tracking-widest text-[10px] hover:bg-white/5 h-10">
                                                🎁 Demo Gratuita (30 Días)
                                            </Button>
                                        </Link>
                                    </>
                                ) : (
                                    <div className="space-y-6">
                                        <div className="p-6 rounded-2xl bg-white/[0.03] border border-white/10 text-center backdrop-blur-sm">
                                            <p className="text-[10px] text-text-muted mb-2 uppercase tracking-widest font-black">Disponibilidad</p>
                                            <p className="text-xl font-black text-white uppercase italic tracking-tighter">
                                                {bot.status === 'MAINTENANCE' ? 'En Mantenimiento' : 'Próximamente'}
                                            </p>
                                        </div>
                                        <Button disabled size="lg" fullWidth className="py-8 opacity-30 grayscale cursor-not-allowed font-black uppercase tracking-widest italic">
                                            No Disponible
                                        </Button>
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

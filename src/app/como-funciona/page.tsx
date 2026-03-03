import { Card, CardContent } from "@/components/ui/Card";

export default function ComoFuncionaPage() {
    return (
        <div className="min-h-screen pt-12 pb-24 px-4 sm:px-6 lg:px-8 relative overflow-hidden">
            {/* Background radial sutil */}
            <div className="absolute top-0 right-0 w-[600px] h-[600px] bg-brand/10 blur-[150px] rounded-full mix-blend-screen pointer-events-none" />

            <div className="max-w-4xl mx-auto z-10 relative pt-10">
                <div className="text-center mb-20">
                    <h1 className="text-4xl md:text-6xl font-extrabold tracking-tighter text-white mb-6 leading-tight">
                        Cómo Funciona <span className="text-transparent bg-clip-text bg-gradient-to-r from-accent via-white to-accent">KopyTrading</span>
                    </h1>
                    <p className="text-lg md:text-xl text-text-muted max-w-2xl mx-auto font-light">
                        Descargar e instalar tu primer bot de trading en MetaTrader 5 es un proceso diseñado para ser rápido y seguro. Sigue estos simples pasos y empieza hoy mismo.
                    </p>
                </div>

                <div className="space-y-12">
                    {/* Step 1 */}
                    <div className="relative pl-8 md:pl-0">
                        <div className="hidden md:block absolute left-[50%] top-0 bottom-[-3rem] w-px bg-gradient-to-b from-brand to-transparent -translate-x-1/2"></div>

                        <div className="md:grid md:grid-cols-2 gap-12 items-center relative">
                            <div className="md:text-right md:pr-12 md:pb-0 pb-8">
                                <div className="md:hidden absolute left-0 top-0 bottom-0 w-px bg-gradient-to-b from-brand to-transparent"></div>
                                <div className="absolute left-[-5px] md:left-auto md:right-[-2.5rem] md:translate-x-1/2 top-0 w-3 h-3 rounded-full bg-brand-light shadow-[0_0_10px_rgba(167,139,250,1)] z-10"></div>

                                <h3 className="text-2xl font-bold text-white mb-2">1. Explora el Marketplace</h3>
                                <p className="text-text-muted">Navega por nuestra selección de bots especializados. Filtra por activo (como Oro o Bitcoin), ajusta el riesgo y revisa el historial de la estrategia.</p>
                            </div>
                            <div className="glass-card p-6 border-accent/20 bg-black/40 backdrop-blur-xl shadow-[0_20px_50px_rgba(0,0,0,0.8)]">
                                <div className="h-56 rounded-2xl bg-gradient-to-br from-surface to-black flex flex-col items-center justify-center gap-4 border border-white/5 transform hover:scale-105 transition-all duration-500 group">
                                    <span className="text-7xl group-hover:scale-110 transition-transform">🔍</span>
                                    <div className="flex gap-2">
                                        <span className="w-12 h-1 bg-accent/30 rounded-full animate-pulse"></span>
                                        <span className="w-8 h-1 bg-brand/30 rounded-full animate-pulse delay-75"></span>
                                    </div>
                                    <span className="text-[10px] text-accent/50 uppercase tracking-[0.2em] font-bold">Scanning Markets...</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Step 2 */}
                    <div className="relative pl-8 md:pl-0">
                        <div className="hidden md:block absolute left-[50%] top-0 bottom-[-3rem] w-px bg-gradient-to-b from-brand to-transparent -translate-x-1/2"></div>

                        <div className="md:grid md:grid-cols-2 gap-12 items-center relative">
                            <div className="md:col-start-2 md:pl-12 md:pb-0 pb-8">
                                <div className="md:hidden absolute left-0 top-0 bottom-0 w-px bg-gradient-to-b from-brand to-transparent"></div>
                                <div className="absolute left-[-5px] md:-left-10 top-0 w-3 h-3 rounded-full bg-brand-light shadow-[0_0_10px_rgba(167,139,250,1)] z-10"></div>

                                <h3 className="text-2xl font-bold text-white mb-2">2. Pago Único por PayPal</h3>
                                <p className="text-text-muted">Sin suscripciones. Paga una vez vía **PayPal o Tarjeta** y obtén licencia vitalicia, manuales detallados y soporte premium.</p>
                            </div>
                            <div className="md:col-start-1 md:row-start-1 glass-card p-6 border-accent/20 bg-black/40 backdrop-blur-xl shadow-[0_20px_50px_rgba(0,0,0,0.8)]">
                                <div className="h-56 rounded-2xl bg-gradient-to-br from-surface to-black flex flex-col items-center justify-center gap-4 border border-white/5 transform hover:scale-105 transition-all duration-500 group text-center px-4">
                                    <div className="flex items-center gap-2">
                                        <span className="text-5xl group-hover:-rotate-12 transition-transform">💳</span>
                                        <span className="text-5xl group-hover:rotate-12 transition-transform">🅿️</span>
                                    </div>
                                    <div className="space-y-1">
                                        <div className="text-sm font-bold text-white">Descarga Instantánea</div>
                                        <div className="text-[10px] text-success font-bold uppercase tracking-wider">Seguro • Vitalicio • Sin Cuotas</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Step 3 */}
                    <div className="relative pl-8 md:pl-0">
                        <div className="hidden md:block absolute left-[50%] top-0 bottom-0 w-px bg-gradient-to-b from-brand to-transparent -translate-x-1/2"></div>

                        <div className="md:grid md:grid-cols-2 gap-12 items-center relative">
                            <div className="md:text-right md:pr-12">
                                <div className="md:hidden absolute left-0 top-0 bottom-0 w-px bg-gradient-to-b from-brand to-transparent"></div>
                                <div className="absolute left-[-5px] md:left-auto md:right-[-2.5rem] md:translate-x-1/2 top-0 w-3 h-3 rounded-full bg-brand-light shadow-[0_0_10px_rgba(167,139,250,1)] z-10"></div>

                                <h3 className="text-2xl font-bold text-white mb-2">3. Instalación en MetaTrader 5</h3>
                                <p className="text-text-muted">Baja tu archivo `.ex5` y la guía PDF. Arrástralo a tu MT5, ajusta el lotaje y deja que el algoritmo opere por ti en tu broker preferido.</p>
                            </div>
                            <div className="glass-card p-6 border-accent/20 bg-black/40 backdrop-blur-xl shadow-[0_20px_50px_rgba(0,0,0,0.8)]">
                                <div className="h-56 rounded-2xl bg-gradient-to-br from-surface to-black flex flex-col items-center justify-center gap-4 border border-white/5 transform hover:scale-105 transition-all duration-500 group">
                                    <span className="text-7xl group-hover:translate-y-[-10px] transition-transform">MT5</span>
                                    <div className="flex flex-col items-center">
                                        <span className="text-xs font-bold text-brand-light">Trading Automático</span>
                                        <span className="text-[10px] text-text-muted">100% Configurado</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                </div>
            </div>
        </div>
    );
}

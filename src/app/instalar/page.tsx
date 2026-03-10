import Link from 'next/link';

export default function InstalarAppPage() {
    return (
        <div className="min-h-screen pt-32 pb-20 px-4 sm:px-6 lg:px-8 bg-bg-dark relative overflow-hidden">
            {/* Background elements */}
            <div className="absolute top-0 inset-x-0 h-full w-full pointer-events-none z-0">
                <div className="absolute top-1/4 left-1/2 -translate-x-1/2 w-[600px] h-[600px] bg-brand/10 blur-[120px] rounded-full mix-blend-screen" />
            </div>

            <div className="max-w-4xl mx-auto space-y-12 relative z-10">
                <div className="text-center space-y-6">
                    <div className="w-20 h-20 mx-auto bg-gradient-to-br from-brand to-brand-dark rounded-3xl shadow-[0_0_30px_rgba(168,85,247,0.4)] flex items-center justify-center text-4xl border border-white/20 animate-float">
                        📲
                    </div>
                    <h1 className="text-3xl sm:text-5xl font-extrabold text-white tracking-tight">
                        Cómo tener KopyTrade en tu móvil
                    </h1>
                    <p className="text-text-muted text-base sm:text-lg max-w-2xl mx-auto leading-relaxed">
                        Nuestra plataforma utiliza tecnología web moderna (PWA). <strong className="text-white">No existe una app en la App Store ni en Google Play</strong>. En su lugar, instalas la web directamente desde tu navegador en 10 segundos. No ocupa apenas memoria.
                    </p>
                </div>

                <div className="grid md:grid-cols-2 gap-6 lg:gap-8 pt-4">
                    {/* iOS Instructions */}
                    <div className="glass-card p-6 sm:p-8 rounded-2xl border border-white/10 hover:border-brand/40 transition-colors relative overflow-hidden group">
                        <div className="absolute top-0 right-0 w-32 h-32 bg-white/5 rounded-bl-full -z-10 group-hover:bg-brand/10 transition-colors" />
                        <h2 className="text-2xl font-bold text-white mb-8 flex items-center gap-3">
                            <span className="text-3xl">🍎</span> iPhone (iOS)
                        </h2>
                        <ol className="space-y-6">
                            <li className="flex gap-4">
                                <div className="w-8 h-8 rounded-full bg-brand/20 border border-brand/50 flex items-center justify-center text-brand-light font-bold shrink-0 shadow-lg shadow-brand/20">1</div>
                                <div>
                                    <p className="text-white text-base font-semibold">Abre el navegador Safari</p>
                                    <p className="text-text-muted text-sm mt-1">Asegúrate de estar navegando desde <strong>Safari</strong>, ya que Google Chrome en iPhone no siempre lo permite.</p>
                                </div>
                            </li>
                            <li className="flex gap-4">
                                <div className="w-8 h-8 rounded-full bg-brand/20 border border-brand/50 flex items-center justify-center text-brand-light font-bold shrink-0 shadow-lg shadow-brand/20">2</div>
                                <div>
                                    <p className="text-white text-base font-semibold">Toca el botón "Compartir"</p>
                                    <p className="text-text-muted text-sm mt-1">Busca en la barra de abajo el icono del cuadrado con una flechita hacia arriba <span className="inline-block p-1 bg-white/10 rounded">↑</span>.</p>
                                </div>
                            </li>
                            <li className="flex gap-4">
                                <div className="w-8 h-8 rounded-full bg-brand/20 border border-brand/50 flex items-center justify-center text-brand-light font-bold shrink-0 shadow-lg shadow-brand/20">3</div>
                                <div>
                                    <p className="text-white text-base font-semibold">Añadir a pantalla de inicio</p>
                                    <p className="text-text-muted text-sm mt-1">Desliza el abanico de opciones hacia abajo hasta que veas "Añadir a pantalla de inicio" (tiene un icono de '+') y confírmalo.</p>
                                </div>
                            </li>
                        </ol>
                        <div className="mt-8 pt-4 border-t border-white/10">
                            <p className="text-xs text-brand-light/80 italic text-center">¡Listo! Aparecerá nuestro icono junto a tus otras apps.</p>
                        </div>
                    </div>

                    {/* Android Instructions */}
                    <div className="glass-card p-6 sm:p-8 rounded-2xl border border-white/10 hover:border-success/40 transition-colors relative overflow-hidden group">
                        <div className="absolute top-0 right-0 w-32 h-32 bg-white/5 rounded-bl-full -z-10 group-hover:bg-success/10 transition-colors" />
                        <h2 className="text-2xl font-bold text-white mb-8 flex items-center gap-3">
                            <span className="text-3xl">🤖</span> Android
                        </h2>
                        <ol className="space-y-6">
                            <li className="flex gap-4">
                                <div className="w-8 h-8 rounded-full bg-success/20 border border-success/50 flex items-center justify-center text-success font-bold shrink-0 shadow-lg shadow-success/20">1</div>
                                <div>
                                    <p className="text-white text-base font-semibold">Abre Google Chrome</p>
                                    <p className="text-text-muted text-sm mt-1">Normalmente, al entrar a la web, Chrome te mostrará solo un aviso pidiendo <strong className="text-white">"Añadir a la pantalla de inicio"</strong>. Si es así, acéptalo. Si no sale, ve al paso 2.</p>
                                </div>
                            </li>
                            <li className="flex gap-4">
                                <div className="w-8 h-8 rounded-full bg-success/20 border border-success/50 flex items-center justify-center text-success font-bold shrink-0 shadow-lg shadow-success/20">2</div>
                                <div>
                                    <p className="text-white text-base font-semibold">Toca los 3 puntitos</p>
                                    <p className="text-text-muted text-sm mt-1">Están en la esquina superior derecha de la pantalla del navegador.</p>
                                </div>
                            </li>
                            <li className="flex gap-4">
                                <div className="w-8 h-8 rounded-full bg-success/20 border border-success/50 flex items-center justify-center text-success font-bold shrink-0 shadow-lg shadow-success/20">3</div>
                                <div>
                                    <p className="text-white text-base font-semibold">Instalar Aplicación / Añadir a inicio</p>
                                    <p className="text-text-muted text-sm mt-1">Busca la opción "Instalar aplicación" (o descargar aplicación) y acepta.</p>
                                </div>
                            </li>
                        </ol>
                        <div className="mt-8 pt-4 border-t border-white/10">
                            <p className="text-xs text-success/80 italic text-center">¡Genial! Funciona sin conexión y mucho más rápido.</p>
                        </div>
                    </div>
                </div>

                <div className="text-center pt-8">
                    <Link href="/" className="inline-flex items-center gap-2 px-8 py-4 rounded-xl font-bold bg-white/5 border border-white/10 text-white hover:bg-white/10 hover:border-white/20 transition-all">
                        ← Volver al inicio 🏠
                    </Link>
                </div>
            </div>
        </div>
    );
}

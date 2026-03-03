import Link from "next/link";

export default function CookiesPage() {
    return (
        <div className="min-h-screen pt-28 pb-20 px-4 sm:px-6 lg:px-8">
            <div className="max-w-3xl mx-auto">
                <Link href="/" className="text-brand-light hover:text-white text-sm flex items-center gap-2 mb-8 group">
                    <span className="group-hover:-translate-x-1 transition-transform">←</span> Inicio
                </Link>
                <h1 className="text-3xl font-bold text-white mb-8">Política de Cookies</h1>
                <div className="glass-card border border-white/10 rounded-2xl p-8 space-y-8 text-text-muted text-sm leading-relaxed">

                    <section>
                        <h2 className="text-white font-semibold text-base mb-2">¿Qué son las Cookies?</h2>
                        <p>Las cookies son pequeños archivos de texto que los sitios web almacenan en tu dispositivo cuando los visitas. Sirven para recordar tus preferencias y mejorar tu experiencia de navegación.</p>
                    </section>

                    <section>
                        <h2 className="text-white font-semibold text-base mb-2">Cookies que utilizamos</h2>
                        <div className="overflow-x-auto">
                            <table className="w-full text-xs border border-white/10 rounded-lg overflow-hidden">
                                <thead className="bg-surface-light/50">
                                    <tr>
                                        <th className="text-left p-3 text-white">Nombre</th>
                                        <th className="text-left p-3 text-white">Tipo</th>
                                        <th className="text-left p-3 text-white">Finalidad</th>
                                        <th className="text-left p-3 text-white">Duración</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr className="border-t border-white/5">
                                        <td className="p-3">next-auth.session-token</td>
                                        <td className="p-3 text-brand-light">Esencial</td>
                                        <td className="p-3">Mantener tu sesión iniciada</td>
                                        <td className="p-3">30 días</td>
                                    </tr>
                                    <tr className="border-t border-white/5">
                                        <td className="p-3">next-auth.csrf-token</td>
                                        <td className="p-3 text-brand-light">Esencial</td>
                                        <td className="p-3">Seguridad anti-CSRF</td>
                                        <td className="p-3">Sesión</td>
                                    </tr>
                                    <tr className="border-t border-white/5">
                                        <td className="p-3">_ga (si se activa)</td>
                                        <td className="p-3 text-text-muted">Analítica</td>
                                        <td className="p-3">Estadísticas de visitas anónimas</td>
                                        <td className="p-3">2 años</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </section>

                    <section>
                        <h2 className="text-white font-semibold text-base mb-2">Gestión de Cookies</h2>
                        <p>Puedes configurar tu navegador para rechazar o eliminar cookies. Ten en cuenta que desactivar las cookies esenciales puede afectar al funcionamiento del sitio (p.ej., no podrás mantener la sesión iniciada).</p>
                        <p className="mt-2">Instrucciones para los principales navegadores:</p>
                        <ul className="list-disc list-inside mt-1 space-y-1">
                            <li><a href="https://support.google.com/chrome/answer/95647" target="_blank" rel="noopener" className="text-brand-light hover:underline">Google Chrome</a></li>
                            <li><a href="https://support.mozilla.org/es/kb/habilitar-y-deshabilitar-cookies-sitios-web-rastrear-preferencias" target="_blank" rel="noopener" className="text-brand-light hover:underline">Mozilla Firefox</a></li>
                            <li><a href="https://support.apple.com/es-es/guide/safari/sfri11471/mac" target="_blank" rel="noopener" className="text-brand-light hover:underline">Safari</a></li>
                        </ul>
                    </section>

                    <p className="text-xs text-text-muted/60 border-t border-white/10 pt-4">Última actualización: Febrero 2026</p>
                </div>
            </div>
        </div>
    );
}

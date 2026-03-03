import Link from "next/link";

export default function RiesgoPage() {
    return (
        <div className="min-h-screen pt-28 pb-20 px-4 sm:px-6 lg:px-8">
            <div className="max-w-3xl mx-auto">
                <Link href="/" className="text-brand-light hover:text-white text-sm flex items-center gap-2 mb-8 group">
                    <span className="group-hover:-translate-x-1 transition-transform">←</span> Inicio
                </Link>
                <h1 className="text-3xl font-bold text-white mb-2">⚠️ Aviso de Riesgo</h1>
                <p className="text-brand-light text-sm mb-8">Léelo completo antes de usar cualquier bot de KOPYTRADE</p>

                <div className="bg-danger/10 border border-danger/30 rounded-2xl p-6 mb-8">
                    <p className="text-danger font-bold text-base">ADVERTENCIA IMPORTANTE</p>
                    <p className="text-danger/80 text-sm mt-2">
                        El trading de CFDs, Forex, materias primas y criptomonedas conlleva un <strong>alto riesgo de pérdida de capital</strong>.
                        Existe la posibilidad de que pierdas parte o la totalidad del capital invertido.
                        Por tanto, no debes operar con capital que no puedas permitirte perder.
                    </p>
                </div>

                <div className="glass-card border border-white/10 rounded-2xl p-8 space-y-8 text-text-muted text-sm leading-relaxed">

                    <section>
                        <h2 className="text-white font-semibold text-base mb-3">1. Naturaleza del Riesgo en Trading Algorítmico</h2>
                        <p>Los algoritmos de trading (bots) son herramientas matemáticas que ejecutan estrategias de forma automatizada. Sin embargo:</p>
                        <ul className="list-disc list-inside mt-2 space-y-1">
                            <li>Los mercados financieros son intrínsecamente impredecibles</li>
                            <li>Los resultados históricos de backtests NO garantizan rendimientos futuros</li>
                            <li>Un bot que funciona bien en condiciones normales puede perder dinero en eventos extremos (Black Swan)</li>
                            <li>El apalancamiento financiero amplifica tanto las ganancias como las pérdidas</li>
                        </ul>
                    </section>

                    <section>
                        <h2 className="text-white font-semibold text-base mb-3">2. Responsabilidad del Usuario</h2>
                        <p>Al utilizar los bots de KOPYTRADE, el usuario reconoce y acepta que:</p>
                        <ul className="list-disc list-inside mt-2 space-y-1">
                            <li>Es el único responsable de la configuración, supervisión y uso del software</li>
                            <li>KOPYTRADE no tiene acceso a sus fondos, cuenta de broker ni datos de trading</li>
                            <li>KOPYTRADE no puede ser considerada responsable de pérdidas derivadas del uso del software</li>
                            <li>Ha leído y comprende todas las instrucciones del Manuel de Usuario del bot</li>
                            <li>Conoce el concepto de apalancamiento financiero y sus implicaciones</li>
                        </ul>
                    </section>

                    <section>
                        <h2 className="text-white font-semibold text-base mb-3">3. No Somos una Entidad Financiera</h2>
                        <p>KOPYTRADE es una empresa de software. <strong className="text-white">No somos una empresa de inversión, gestión de activos, ni asesoramiento financiero regulado.</strong> Los bots que vendemos son herramientas de software, no señales de inversión ni recomendaciones financieras.</p>
                    </section>

                    <section>
                        <h2 className="text-white font-semibold text-base mb-3">4. Recomendaciones Mínimas de Seguridad</h2>
                        <ul className="list-disc list-inside space-y-1">
                            <li>Prueba SIEMPRE en cuenta Demo durante mínimo 2-4 semanas antes de operar en real</li>
                            <li>Nunca uses el bot con lotajes superiores al recomendado en el manual</li>
                            <li>Apaga el AutoTrading antes de noticias macroeconómicas de alto impacto</li>
                            <li>Usa siempre el capital mínimo recomendado para cada bot</li>
                            <li>Nunca inviertas dinero que necesites para tus gastos básicos</li>
                        </ul>
                    </section>

                    <section>
                        <h2 className="text-white font-semibold text-base mb-3">5. Condiciones Específicas del Mercado del Oro (XAUUSD)</h2>
                        <p>El Oro es uno de los activos más volátiles del mercado global. Puede moverse cientos de dólares por onza en minutos ante noticias de la FED, conflictos geopolíticos o datos de inflación inesperados. El uso del bot La Ametralladora implica la aceptación de esta volatilidad extrema.</p>
                    </section>

                    <div className="bg-danger/5 border border-danger/20 rounded-xl p-4 mt-4">
                        <p className="text-xs text-danger/80 font-medium">
                            Al descargar y usar cualquier bot de KOPYTRADE, confirmas haber leído, comprendido y aceptado íntegramente este Aviso de Riesgo, la Política de Privacidad y los Términos de Uso.
                        </p>
                    </div>

                    <p className="text-xs text-text-muted/60 border-t border-white/10 pt-4">Última actualización: Febrero 2026</p>
                </div>
            </div>
        </div>
    );
}

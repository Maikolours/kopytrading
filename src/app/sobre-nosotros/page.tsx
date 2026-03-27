import { Card, CardContent } from "@/components/ui/Card";
import Link from "next/link";

export default function SobreNosotrosPage() {
    return (
        <div className="min-h-screen pt-28 md:pt-32 pb-24 px-4 sm:px-6 lg:px-8 relative">
            <div className="absolute top-1/2 left-0 w-[400px] h-[400px] bg-brand/5 blur-[120px] rounded-full mix-blend-screen pointer-events-none" />

            <div className="max-w-4xl mx-auto z-10 relative">
                <Link href="/" className="inline-flex items-center gap-2 text-sm text-text-muted hover:text-white transition-colors mb-8">
                    <span>←</span> Volver al inicio
                </Link>

                <div className="mb-12 border-b border-white/10 pb-8 text-center md:text-left">
                    <h1 className="text-4xl font-bold tracking-tight text-white mb-3">Sobre Nosotros</h1>
                    <p className="text-brand-light font-medium uppercase tracking-[0.2em] text-xs">La tecnología detrás de KopyTrading</p>
                </div>

                <div className="space-y-12 text-text-muted leading-relaxed">
                    <section className="space-y-6">
                        <h2 className="text-2xl font-semibold text-white">Nuestra Historia: Del Trading Manual a la Automatización</h2>
                        <p>
                            KopyTrading nació de una necesidad real. Como trader con años de experiencia operando los mercados de forma manual, entendí rápidamente que el eslabón más débil en cualquier estrategia es el factor emocional humano. El cansancio, el miedo al cierre de una operación y la falta de tiempo para monitorizar los mercados 24/5 son los mayores obstáculos para la rentabilidad constante.
                        </p>
                        <p>
                            Tras un largo proceso de formación autodidacta y especialización en MQL5, decidí trasladar mis estrategias manuales más exitosas al código. Lo que comenzó como un proyecto personal para optimizar mi propia operativa y liberar tiempo, pronto empezó a llamar la atención de otros traders y conocidos tras observar su consistencia y precisión.
                        </p>
                    </section>

                    <Card className="bg-surface-light/10 border-white/5 p-8">
                        <CardContent className="p-0">
                            <h3 className="text-xl font-semibold text-white mb-4 italic">"El trading no debería ser una batalla contra tus emociones, sino una ejecución precisa de tu ventaja estadística."</h3>
                            <p className="text-sm">
                                Nuestra misión es democratizar el acceso a herramientas de trading institucional, permitiendo que cualquier persona pueda ejecutar algoritmos complejos sin necesidad de pasar horas frente a la pantalla.
                            </p>
                        </CardContent>
                    </Card>

                    <section className="grid md:grid-cols-2 gap-8">
                        <div className="space-y-4">
                            <h3 className="text-lg font-semibold text-white">¿Por qué Elegir KopyTrading?</h3>
                            <ul className="space-y-3 text-sm">
                                <li className="flex items-start gap-3">
                                    <span className="text-brand">✓</span>
                                    <span><strong>Transparencia:</strong> No vendemos promesas mágicas, vendemos software matemático riguroso.</span>
                                </li>
                                <li className="flex items-start gap-3">
                                    <span className="text-brand">✓</span>
                                    <span><strong>Eficiencia:</strong> Gana tiempo libre mientras tu bot monitoriza cada vela del gráfico.</span>
                                </li>
                                <li className="flex items-start gap-3">
                                    <span className="text-brand">✓</span>
                                    <span><strong>Soporte Directo:</strong> Trato directo de trader a trader, sin intermediarios.</span>
                                </li>
                            </ul>
                        </div>
                        <div className="space-y-4">
                            <h3 className="text-lg font-semibold text-white">Nuestra Filosofía de Riesgo</h3>
                            <p className="text-sm">
                                Sabemos que el trading algorítmico no es una ciencia exacta y que los mercados siempre conllevan riesgo. Por eso, todos nuestros productos están diseñados con un enfoque estricto en la preservación del capital, utilizando Stop Loss físicos y evitando estrategias peligrosas como las martingalas exponenciales.
                            </p>
                        </div>
                    </section>

                    <div className="pt-12 border-t border-white/10 text-center">
                        <Link href="/bots" className="inline-block px-8 py-4 rounded-2xl bg-brand text-white font-bold hover:bg-brand-light transition-all shadow-[0_0_30px_rgba(245,158,11,0.2)]">
                            Explorar Nuestros Algoritmos →
                        </Link>
                    </div>
                </div>
            </div>
        </div>
    );
}

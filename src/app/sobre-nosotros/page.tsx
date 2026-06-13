import { Card, CardContent } from "@/components/ui/Card";
import Link from "next/link";
import { Metadata } from "next";

export const metadata: Metadata = {
    title: "Sobre Nosotros | KopyTrading",
    description: "Conoce la historia real detrás de KopyTrading. Creamos herramientas tecnológicas de automatización para facilitar el trading en MetaTrader 5.",
    keywords: ["sobre nosotros", "trayectoria kopytrading", "bots de trading", "trading automático", "aprender trading"],
};

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
                        <h2 className="text-2xl font-semibold text-white">Nuestra Historia: Una necesidad de simplificación</h2>
                        <p>
                            KopyTrading nació de una historia muy común y real. A diferencia de otros proyectos, no pretendo venderte que tengo décadas de experiencia operando en Wall Street o gestionando fondos institucionales. Mi trayectoria viene de un sector completamente ajeno a las finanzas y el trading.
                        </p>
                        <p>
                            Cuando decidí adentrarme en el mundo de los mercados financieros, rápidamente me di cuenta de que aprender a hacer trading manual de forma consistente requiere un esfuerzo de estudio enorme, un análisis en profundidad diario de los gráficos y, sobre todo, una disciplina psicológica que pocas personas pueden mantener mientras trabajan en su día a día.
                        </p>
                        <p>
                            Por ello, como persona autodidacta, decidí ponerme a diseñar mis propias herramientas y programar robots (bots) en MetaTrader 5. Mi meta era clara: crear un software bien elaborado y probado que hiciese el trabajo pesado de analizar y abrir operaciones de manera automatizada. Quería facilitar el acceso a la rentabilidad para personas que, como yo, carecen del tiempo diario o de los conocimientos avanzados de análisis de mercado pero buscan un ingreso extra apoyados en la tecnología.
                        </p>
                    </section>

                    <Card className="bg-surface-light/10 border-white/5 p-8">
                        <CardContent className="p-0">
                            <h3 className="text-xl font-semibold text-white mb-4 italic">"El trading no tiene por qué ser una carrera imposible de dominar si dejas que la tecnología automatice la estrategia por ti."</h3>
                            <p className="text-sm font-light">
                                Nuestra misión es proveer herramientas y software que simplifiquen tu operativa diaria. Diseñamos algoritmos listos para que no tengas que pasar horas frente a la pantalla ni batallar contra las emociones.
                            </p>
                        </CardContent>
                    </Card>

                    <section className="grid md:grid-cols-2 gap-8">
                        <div className="space-y-4">
                            <h3 className="text-lg font-semibold text-white">¿Por qué Elegir KopyTrading?</h3>
                            <ul className="space-y-3 text-sm">
                                <li className="flex items-start gap-3">
                                    <span className="text-brand">✓</span>
                                    <span><strong>Acceso Simplificado:</strong> Facilitamos el acceso al trading para personas con conocimientos limitados o poco tiempo disponible.</span>
                                </li>
                                <li className="flex items-start gap-3">
                                    <span className="text-brand">✓</span>
                                    <span><strong>Software Probado:</strong> Nuestros robots están testeados a fondo para ofrecer resultados estables y automatizados.</span>
                                </li>
                                <li className="flex items-start gap-3">
                                    <span className="text-brand">✓</span>
                                    <span><strong>Transparencia Real:</strong> Sin falsas promesas. Compartimos la realidad del trading y de cada software.</span>
                                </li>
                            </ul>
                        </div>
                        <div className="space-y-4">
                            <h3 className="text-lg font-semibold text-white">Aviso de Riesgo y Responsabilidad</h3>
                            <p className="text-sm font-light">
                                Ningún bot de trading es 100% infalible. Aunque nuestras herramientas concretas cuentan con estadísticas verificadas y tasas de acierto que superan el 80% en pruebas históricas, el mercado financiero (especialmente en activos volátiles como el Oro o Cripto) es sumamente cambiante. 
                            </p>
                            <p className="text-sm font-semibold text-white">
                                KopyTrading proporciona una herramienta de apoyo tecnológico. En ningún caso nos responsabilizamos de los resultados financieros finales de cada cliente o de las pérdidas de capital sufridas por operaciones de mercado.
                            </p>
                        </div>
                    </section>

                    <div className="pt-12 border-t border-white/10 text-center">
                        <Link href="/bots" className="inline-block px-8 py-4 rounded-2xl bg-brand text-white font-bold hover:bg-brand-light transition-all shadow-[0_0_30px_rgba(245,158,11,0.2)]">
                            Ver Bots Disponibles →
                        </Link>
                    </div>
                </div>
            </div>
        </div>
    );
}

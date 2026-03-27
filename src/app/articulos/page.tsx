import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/Card";
import Link from "next/link";
import { ARTICLES } from "@/lib/constants/articles";

export default function ArticulosPage() {
    return (
        <div className="min-h-screen pt-28 md:pt-32 pb-24 px-4 sm:px-6 lg:px-8 relative">
            <div className="absolute top-1/2 left-0 w-[400px] h-[400px] bg-brand/5 blur-[120px] rounded-full mix-blend-screen pointer-events-none" />

            <div className="max-w-7xl mx-auto z-10 relative">
                <Link href="/" className="inline-flex items-center gap-2 text-sm text-text-muted hover:text-white transition-colors mb-4">
                    <span>←</span> Volver al inicio
                </Link>

                <div className="mb-12 border-b border-white/10 pb-8 text-center md:text-left">
                    <h1 className="text-4xl font-bold tracking-tight text-white mb-3">Artículos de Trading</h1>
                    <p className="text-text-muted max-w-2xl">Mantente al día con nuestros recursos de aprendizaje. Tips de expertos, guías de configuración de MT5 e introducciones al mundo bot.</p>
                </div>

                <div className="grid md:grid-cols-2 lg:grid-cols-2 gap-8">
                    {ARTICLES.map((article, idx) => (
                        <Link key={idx} href={`/articulos/${article.slug}`} className="block group">
                            <Card interactive className="h-full border border-white/5 bg-surface-light/20">
                                <CardHeader className="border-none pb-2">
                                    <div className="flex justify-between items-center mb-4">
                                        <span className="text-xs font-semibold text-brand-light uppercase tracking-wider">{article.category}</span>
                                        <span className="text-xs text-text-muted flex items-center gap-2">
                                            <span>{article.date}</span>
                                            <span className="w-1 h-1 rounded-full bg-white/20"></span>
                                            <span>⏱ {article.readTime}</span>
                                        </span>
                                    </div>
                                    <CardTitle className="group-hover:text-brand-light transition-colors">{article.title}</CardTitle>
                                </CardHeader>
                                <CardContent>
                                    <p className="text-text-muted text-sm leading-relaxed">{article.excerpt}</p>
                                </CardContent>
                            </Card>
                        </Link>
                    ))}
                </div>

                <div className="mt-16 text-center">
                    <p className="text-text-muted text-sm border border-white/10 inline-block px-6 py-3 rounded-full glass-card">
                        Suscríbete a nuestra newsletter para recibir nuevos artículos (Próximamente)
                    </p>
                </div>
            </div>
        </div>
    );
}

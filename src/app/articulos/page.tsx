import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/Card";
import Link from "next/link";
import { ARTICLES } from "@/lib/constants/articles";

export default function ArticulosPage() {
    return (
        <div className="min-h-screen pt-28 md:pt-32 pb-24 px-4 sm:px-6 lg:px-8 relative">
            <div className="absolute top-1/2 left-0 w-[400px] h-[400px] bg-brand/5 blur-[120px] rounded-full mix-blend-screen pointer-events-none" />

            <div className="max-w-7xl mx-auto z-10 relative">
                <Link href="/" className="inline-flex items-center gap-2 text-[10px] font-black text-text-muted hover:text-white transition-colors mb-6 uppercase tracking-widest border border-white/5 px-4 py-2 rounded-full glass-card hover:border-white/20">
                    <span className="text-base leading-none">←</span> Volver al inicio
                </Link>

                <div className="mb-16 border-b border-white/5 pb-10 text-center md:text-left">
                    <h1 className="text-4xl sm:text-6xl font-black tracking-tighter text-white mb-4 uppercase italic">Artículos de <span className="text-brand-light">Trading</span></h1>
                    <p className="text-text-muted max-w-2xl text-base sm:text-lg font-light leading-relaxed">Explora nuestras guías institucionales, configuraciones avanzadas de MT5 y estrategias de alta frecuencia para dominar el mercado.</p>
                </div>

                <div className="grid md:grid-cols-2 lg:grid-cols-2 gap-8 lg:gap-12">
                    {ARTICLES.map((article, idx) => (
                        <Link key={idx} href={`/articulos/${article.slug}`} className="block group">
                            <Card className="relative h-full overflow-hidden border-2 border-white/5 bg-surface/30 backdrop-blur-2xl group-hover:border-brand/40 transition-all duration-700 rounded-[2.5rem] premium-card-glow shadow-2xl hover:scale-[1.02] hover:-translate-y-2">
                                <div className="absolute inset-0 bg-gradient-to-br from-brand/10 to-transparent opacity-40 group-hover:opacity-100 transition-opacity" />
                                
                                <CardHeader className="relative z-10 border-none pb-4 pt-10 px-8 sm:px-10">
                                    <div className="flex justify-between items-center mb-8">
                                        <div className="flex items-center gap-3">
                                            <span className="w-2 h-2 rounded-full bg-brand animate-pulse shadow-[0_0_10px_rgba(139,92,246,0.8)]" />
                                            <span className="text-[11px] font-black text-brand-light uppercase tracking-[0.3em]">{article.category}</span>
                                        </div>
                                        <div className="flex items-center gap-4 text-[10px] text-text-muted font-bold uppercase tracking-[0.2em] opacity-60">
                                            <span>{article.date}</span>
                                            <span className="w-1 h-1 rounded-full bg-white/20"></span>
                                            <span className="flex items-center gap-1.5 whitespace-nowrap">⏱ {article.readTime}</span>
                                        </div>
                                    </div>
                                    <CardTitle className="text-2xl sm:text-4xl font-black text-white group-hover:text-brand-light transition-all duration-500 leading-[1.1] uppercase italic tracking-tighter mb-4">
                                        {article.title}
                                    </CardTitle>
                                </CardHeader>
                                
                                <CardContent className="relative z-10 px-8 sm:px-10 pb-12">
                                    <p className="text-text-muted text-sm sm:text-base leading-relaxed opacity-70 group-hover:opacity-100 transition-opacity mb-10 line-clamp-3 font-medium">
                                        {article.excerpt}
                                    </p>
                                    
                                    <div className="flex items-center gap-3 text-[11px] font-black text-brand-light uppercase tracking-[0.3em] group-hover:translate-x-4 transition-transform duration-700">
                                        Leer Guía Completa <span className="text-2xl leading-none">→</span>
                                    </div>
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

import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/Card";
import Link from "next/link";
import { ARTICLES } from "@/lib/constants/articles";
import { NewsletterForm } from "@/components/NewsletterForm";
import { Metadata } from "next";

export const metadata: Metadata = {
    title: "Blog de Trading Algorítmico | KopyTrading",
    description: "Explora guías institucionales, configuraciones de MetaTrader 5 y estrategias avanzadas de trading algorítmico y scalping.",
    keywords: ["trading algorítmico", "bots mt5", "expert advisor", "oro xauusd", "copytrading", "estrategias forex"],
};

export default function ArticulosPage() {
    return (
        <div className="min-h-screen pt-28 md:pt-32 pb-24 px-4 sm:px-6 lg:px-8 relative">
            <div className="absolute top-1/2 left-0 w-[400px] h-[400px] bg-brand/5 blur-[120px] rounded-full mix-blend-screen pointer-events-none" />

            <div className="max-w-7xl mx-auto z-10 relative">
                {/* Header: botón Volver al inicio y Título a la misma altura */}
                <div className="flex flex-col md:flex-row items-center justify-between gap-4 mb-3">
                    <Link href="/" className="inline-flex items-center gap-2 text-[10px] font-black text-text-muted hover:text-white transition-colors uppercase tracking-widest border border-white/5 px-4 py-2 rounded-full glass-card hover:border-white/20 shrink-0 self-start md:self-center">
                        <span className="text-base leading-none">←</span> Volver al inicio
                    </Link>

                    <h1 className="text-2xl sm:text-3xl lg:text-4xl font-black tracking-tight text-white uppercase italic text-center md:-ml-28">
                        Artículos de <span className="text-brand-light">Trading</span>
                    </h1>

                    <div className="hidden md:block w-28" />
                </div>

                {/* Subtítulo centrado */}
                <div className="text-center mb-8 pb-5 border-b border-white/5">
                    <p className="text-text-muted max-w-2xl mx-auto text-xs sm:text-sm font-light leading-relaxed">
                        Explora nuestras guías institucionales, configuraciones avanzadas de MT5 y estrategias de alta frecuencia para dominar el mercado.
                    </p>
                </div>

                {/* Grid con tarjetas compactas que entran completas en pantalla al hacer scroll */}
                <div className="grid md:grid-cols-2 lg:grid-cols-2 gap-4 sm:gap-6">
                    {ARTICLES.map((article, idx) => (
                        <Link key={idx} href={`/articulos/${article.slug}`} className="block group">
                            <Card className="relative h-full overflow-hidden border border-white/10 bg-surface/30 backdrop-blur-2xl group-hover:border-brand/50 transition-all duration-300 rounded-2xl premium-card-glow shadow-lg hover:scale-[1.01]">
                                <div className="absolute inset-0 bg-gradient-to-br from-brand/10 to-transparent opacity-25 group-hover:opacity-100 transition-opacity" />
                                
                                <CardHeader className="relative z-10 border-none pb-2 pt-4 px-4 sm:px-5">
                                    <div className="flex justify-between items-center mb-2">
                                        <div className="flex items-center gap-1.5">
                                            <span className="w-1.5 h-1.5 rounded-full bg-brand animate-pulse shadow-[0_0_8px_rgba(139,92,246,0.8)]" />
                                            <span className="text-[9px] font-black text-brand-light uppercase tracking-[0.2em]">{article.category}</span>
                                        </div>
                                        <div className="flex items-center gap-2 text-[9px] text-text-muted font-bold uppercase tracking-widest opacity-60">
                                            <span>✍️ Maikolours</span>
                                            <span className="w-1 h-1 rounded-full bg-white/20"></span>
                                            <span className="flex items-center gap-1 whitespace-nowrap">⏱ {article.readTime}</span>
                                        </div>
                                    </div>
                                    <CardTitle className="text-base sm:text-lg font-black text-white group-hover:text-brand-light transition-colors leading-snug tracking-tight mb-1 line-clamp-1">
                                        {article.title}
                                    </CardTitle>
                                </CardHeader>
                                
                                {article.image && (
                                    <div className="relative w-full h-32 sm:h-36 overflow-hidden bg-black/40">
                                        <img src={article.image} alt={article.title} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500 opacity-90 group-hover:opacity-100" />
                                        <div className="absolute inset-0 bg-gradient-to-t from-bg-dark via-transparent to-transparent opacity-80" />
                                    </div>
                                )}
                                
                                <CardContent className="relative z-10 px-4 sm:px-5 pb-4 pt-2.5">
                                    <p className="text-text-muted text-xs leading-relaxed opacity-75 group-hover:opacity-100 transition-opacity mb-3 line-clamp-2 font-medium">
                                        {article.excerpt}
                                    </p>
                                    
                                    <div className="flex items-center gap-1.5 text-[9px] font-black text-brand-light uppercase tracking-[0.2em] group-hover:translate-x-1.5 transition-transform duration-200">
                                        Leer Guía Completa <span className="text-base leading-none">→</span>
                                    </div>
                                </CardContent>
                            </Card>
                        </Link>
                    ))}
                </div>

                <div className="mt-20">
                    <NewsletterForm />
                </div>
            </div>
        </div>
    );
}

import { notFound } from "next/navigation";
import Link from "next/link";
import type { Metadata } from "next";
import { ARTICLES_DATA } from "@/lib/constants/articles";

// Force dynamic rendering to avoid 404 in dev mode
export const dynamic = "force-dynamic";
export const dynamicParams = true;

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
    const { slug } = await params;
    const article = ARTICLES_DATA[slug];

    if (!article) return { title: "Artículo no encontrado" };

    return {
        title: `${article.title} | KOPYTRADING Blog`,
        description: article.metaDescription,
        keywords: article.keywords.join(", "),
        openGraph: {
            title: article.title,
            description: article.metaDescription,
            type: "article",
            publishedTime: article.date,
        },
    };
}

export default async function ArticuloDetallePage({ params }: { params: Promise<{ slug: string }> }) {
    const { slug } = await params;
    const article = ARTICLES_DATA[slug];
    if (!article) notFound();

    const contentBlocks = article.content.split('\n\n');
    return (
        <div className="min-h-screen pt-28 pb-24 px-4 sm:px-6 lg:px-8 relative overflow-hidden bg-[#050510]">
            {/* Background Accents */}
            <div className="absolute top-0 left-1/4 w-[600px] h-[600px] bg-brand/10 blur-[180px] rounded-full mix-blend-screen pointer-events-none" />
            <div className="absolute bottom-0 right-1/4 w-[500px] h-[500px] bg-accent/5 blur-[150px] rounded-full mix-blend-screen pointer-events-none" />
            
            <div className="max-w-3xl mx-auto relative z-10">
                <Link href="/articulos" className="text-brand-light hover:text-white transition-all text-sm flex items-center gap-2 mb-8 group w-fit">
                    <span className="group-hover:-translate-x-1 transition-transform inline-block">←</span> 
                    <span className="font-bold uppercase tracking-widest text-[10px]">Volver al Blog</span>
                </Link>

                {/* SEO-optimized header */}
                <header className="mb-10 text-center sm:text-left">
                    <div className="inline-block px-3 py-1 rounded-full bg-brand/10 border border-brand/20 mb-4">
                        <span className="text-[10px] font-black text-brand-light uppercase tracking-[0.2em]">{article.category}</span>
                    </div>
                    <h1 className="text-3xl sm:text-5xl font-black text-white mt-1 mb-6 leading-[1.1] tracking-tighter uppercase italic">{article.title}</h1>
                    <div className="flex flex-wrap items-center justify-center sm:justify-start gap-6 text-[11px] text-text-muted font-bold uppercase tracking-widest">
                        <span className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-white/5 border border-white/5">📅 {article.date}</span>
                        <span className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-white/5 border border-white/5">⏱ {article.readTime}</span>
                    </div>
                </header>

                {/* Article content */}
                <article className="glass-card border border-white/10 rounded-[2.5rem] p-8 sm:p-14 space-y-10 shadow-2xl relative overflow-hidden bg-white/[0.01]">
                    <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-brand to-transparent opacity-80" />
                    
                    {contentBlocks.map((block, i) => {
                        const trimmed = block.trim();
                        if (!trimmed) return null;
                        if (trimmed.startsWith('## ')) return <h2 key={i} className="text-3xl sm:text-4xl font-black text-transparent bg-clip-text bg-gradient-to-r from-white to-white/60 mt-16 mb-8 tracking-tighter uppercase italic border-l-8 border-brand pl-8">{trimmed.replace('## ', '')}</h2>;
                        if (trimmed.startsWith('### ')) return <h3 key={i} className="text-xl font-black text-brand-light mt-12 mb-6 tracking-tight uppercase flex items-center gap-3"><span className="w-2 h-2 rounded-full bg-brand" /> {trimmed.replace('### ', '')}</h3>;
                        if (trimmed.startsWith('---')) return <hr key={i} className="border-white/10 my-14" />;
                        if (trimmed.startsWith('⚠️')) return (
                            <div key={i} className="relative group my-12">
                                <div className="absolute -inset-1 bg-gradient-to-r from-danger/30 to-orange-500/20 rounded-3xl blur opacity-30 group-hover:opacity-50 transition-all duration-500" />
                                <div className="relative text-sm text-danger-light border border-danger/30 rounded-3xl px-8 py-7 bg-danger/[0.03] font-medium leading-relaxed shadow-xl">
                                    <div className="flex items-center gap-3 mb-4">
                                        <span className="w-8 h-8 rounded-xl bg-danger/20 flex items-center justify-center text-lg shadow-lg">⚠️</span>
                                        <span className="text-xs font-black uppercase tracking-[0.2em] text-danger">Aviso de Riesgo Crítico</span>
                                    </div>
                                    <div className="pl-11 opacity-90">{trimmed.replace('⚠️', '').trim()}</div>
                                </div>
                            </div>
                        );
                        
                        // Image support from content
                        if (trimmed.includes('<img')) {
                             return <div key={i} dangerouslySetInnerHTML={{ __html: trimmed }} className="my-14 rounded-[2.5rem] overflow-hidden border border-white/10 shadow-2xl transition-all hover:border-brand/40 hover:scale-[1.01] duration-700 bg-black/40" />;
                        }

                        // Lists
                        if (trimmed.match(/^(\d+\.|[-•✅❌])\s/m)) {
                            const items = trimmed.split('\n').filter(l => l.trim());
                            return (
                                <ul key={i} className="space-y-6 my-10 pl-2">
                                    {items.map((item, li) => (
                                        <li key={li} className="text-slate-300 text-lg leading-relaxed flex items-start gap-5 group">
                                            <span className="mt-1 flex-shrink-0 w-8 h-8 rounded-xl bg-white/[0.05] border border-white/10 flex items-center justify-center text-xs font-black text-brand-light group-hover:bg-brand group-hover:text-white transition-all shadow-lg">{li + 1}</span>
                                            <span className="pt-1 opacity-90 group-hover:opacity-100 transition-opacity" dangerouslySetInnerHTML={{ __html: item.replace(/^(\d+\.\s?|[-•✅❌]\s?)/, '').replace(/\*\*(.*?)\*\*/g, '<strong class="text-white font-black hover:text-brand-light transition-colors">$1</strong>') }} />
                                        </li>
                                    ))}
                                </ul>
                            );
                        }
                        // Tables
                        if (trimmed.includes('|')) {
                            const rows = trimmed.split('\n').filter(r => r.includes('|') && !r.match(/^\|[-\s|]+\|$/));
                            return (
                                <div key={i} className="my-12 overflow-hidden rounded-3xl border border-white/10 bg-white/[0.01] shadow-2xl group/table">
                                    <table className="w-full text-sm">
                                        <tbody>
                                            {rows.map((row, ri) => (
                                                <tr key={ri} className={ri === 0 ? 'bg-white/5 border-b border-white/10' : 'border-b border-white/[0.03] hover:bg-brand/[0.02] transition-colors'}>
                                                    {row.split('|').filter(c => c.trim()).map((cell, ci) => (
                                                        <td key={ci} className={`py-5 px-8 ${ri === 0 ? 'font-black text-brand-light text-[10px] uppercase tracking-[0.3em]' : 'text-slate-300'}`}>
                                                            <span dangerouslySetInnerHTML={{ __html: cell.trim().replace(/\*\*(.*?)\*\*/g, '<strong class="text-white font-bold">$1</strong>') }} />
                                                        </td>
                                                    ))}
                                                </tr>
                                            ))}
                                        </tbody>
                                    </table>
                                </div>
                            );
                        }
                        // Paragraphs with bold and link handling
                        // Apply drop cap to the very first paragraph
                        const isFirstParagraph = i === 1 || (i === 0 && !trimmed.startsWith('#'));
                        return <p key={i} className={`text-slate-300 text-lg sm:text-xl leading-relaxed font-normal mb-8 opacity-90 hover:opacity-100 transition-opacity ${isFirstParagraph ? 'first-letter:text-6xl first-letter:font-black first-letter:text-brand first-letter:mr-3 first-letter:float-left first-letter:leading-[0.85]' : ''}`} dangerouslySetInnerHTML={{
                            __html: trimmed
                                .replace(/\*\*(.*?)\*\*/g, '<strong class="text-white font-black tracking-tight">$1</strong>')
                                .replace(/\[(.*?)\]\((.*?)\)/g, '<a href="$2" class="text-brand-light hover:text-white font-bold underline decoration-brand/50 underline-offset-8 transition-all hover:decoration-white">$1</a>')
                        }} />;
                    })}
                </article>

                {/* CTA */}
                <div className="mt-24 relative group">
                    <div className="absolute -inset-2 bg-gradient-to-r from-brand via-accent to-brand rounded-[3rem] blur opacity-10 group-hover:opacity-30 transition duration-1000 animate-pulse"></div>
                    <div className="relative glass-card border border-white/10 rounded-[3rem] p-12 sm:p-20 text-center overflow-hidden bg-black/40">
                        <div className="absolute top-0 right-0 p-12 opacity-[0.03]">
                            <span className="text-[15rem] font-black italic select-none leading-none">VIP</span>
                        </div>
                        <div className="relative z-10">
                            <h3 className="text-3xl sm:text-5xl font-black text-white mb-6 uppercase italic tracking-tighter leading-none">¿Listo para operar como un <span className="text-brand-light">Profesional</span>?</h3>
                            <p className="text-slate-400 text-xl mb-12 max-w-2xl mx-auto font-light leading-relaxed">Únete a la élite del trading algorítmico. Accede a herramientas diseñadas para bancos y fondos de inversión, ahora en tu cuenta personal.</p>
                            <div className="flex flex-col sm:flex-row gap-6 justify-center items-center">
                                <Link href="/bots" className="w-full sm:w-auto inline-flex items-center justify-center px-12 py-6 rounded-2xl bg-brand text-white font-black text-xs uppercase tracking-[0.2em] hover:scale-105 active:scale-95 transition-all shadow-[0_0_40px_rgba(139,92,246,0.3)] hover:shadow-[0_0_60px_rgba(139,92,246,0.5)]">
                                    Ver Catálogo →
                                </Link>
                                <Link href="/bots" className="w-full sm:w-auto inline-flex items-center justify-center px-12 py-6 rounded-2xl bg-white/5 border border-white/10 text-white font-black text-xs uppercase tracking-[0.2em] hover:bg-white/10 transition-all hover:border-white/30">
                                    🎁 Prueba Gratis 30 Días
                                </Link>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}

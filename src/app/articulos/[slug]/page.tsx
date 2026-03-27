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
        <div className="min-h-screen pt-28 pb-24 px-4 sm:px-6 lg:px-8">
            <div className="max-w-3xl mx-auto">
                <Link href="/articulos" className="text-brand-light hover:text-white transition-colors text-sm flex items-center gap-2 mb-8 group">
                    <span className="group-hover:-translate-x-1 transition-transform">←</span> Volver al Blog
                </Link>

                {/* SEO-optimized header */}
                <header className="mb-8">
                    <span className="text-xs font-semibold text-brand-light uppercase tracking-widest">{article.category}</span>
                    <h1 className="text-3xl sm:text-4xl font-bold text-white mt-3 mb-4 leading-tight">{article.title}</h1>
                    <div className="flex items-center gap-4 text-sm text-text-muted">
                        <span>📅 {article.date}</span>
                        <span>⏱ {article.readTime} de lectura</span>
                    </div>
                    {/* Keywords visibles para SEO y usuario */}
                    <div className="flex flex-wrap gap-2 mt-4">
                        {article.keywords.slice(0, 5).map((kw, i) => (
                            <span key={i} className="text-[10px] text-text-muted border border-white/10 px-2 py-0.5 rounded-full">{kw}</span>
                        ))}
                    </div>
                </header>

                {/* Article content */}
                <article className="glass-card border border-white/10 rounded-2xl p-6 sm:p-10 space-y-5">
                    {contentBlocks.map((block, i) => {
                        const trimmed = block.trim();
                        if (!trimmed) return null;
                        if (trimmed.startsWith('## ')) return <h2 key={i} className="text-2xl font-bold text-white mt-6 mb-2">{trimmed.replace('## ', '')}</h2>;
                        if (trimmed.startsWith('### ')) return <h3 key={i} className="text-lg font-semibold text-brand-light mt-4 mb-2">{trimmed.replace('### ', '')}</h3>;
                        if (trimmed.startsWith('---')) return <hr key={i} className="border-white/10 my-6" />;
                        if (trimmed.startsWith('⚠️')) return <p key={i} className="text-xs text-text-muted border border-white/10 rounded-lg px-4 py-3 bg-white/5 mt-4">{trimmed}</p>;
                        
                        // Image support from content
                        if (trimmed.includes('<img')) {
                             return <div key={i} dangerouslySetInnerHTML={{ __html: trimmed }} className="my-8 rounded-2xl overflow-hidden border border-white/10 shadow-2xl" />;
                        }

                        // Lists
                        if (trimmed.match(/^(\d+\.|[-•✅❌])\s/m)) {
                            const items = trimmed.split('\n').filter(l => l.trim());
                            return (
                                <ul key={i} className="space-y-2 pl-1">
                                    {items.map((item, li) => (
                                        <li key={li} className="text-text-muted text-sm leading-relaxed flex items-start gap-2">
                                            <span className="mt-0.5 flex-shrink-0">{item.match(/^(\d+\.)/)?.[1] || '•'}</span>
                                            <span dangerouslySetInnerHTML={{ __html: item.replace(/^(\d+\.\s?|[-•✅❌]\s?)/, '').replace(/\*\*(.*?)\*\*/g, '<strong class="text-white">$1</strong>') }} />
                                        </li>
                                    ))}
                                </ul>
                            );
                        }
                        // Tables
                        if (trimmed.includes('|')) {
                            const rows = trimmed.split('\n').filter(r => r.includes('|') && !r.match(/^\|[-\s|]+\|$/));
                            return (
                                <div key={i} className="overflow-x-auto rounded-xl border border-white/10">
                                    <table className="w-full text-sm">
                                        <tbody>
                                            {rows.map((row, ri) => (
                                                <tr key={ri} className={ri === 0 ? 'bg-brand/10 border-b border-brand/30' : 'border-b border-white/5 hover:bg-white/5 transition-colors'}>
                                                    {row.split('|').filter(c => c.trim()).map((cell, ci) => (
                                                        <td key={ci} className={`py-2.5 px-4 ${ri === 0 ? 'font-semibold text-white text-xs uppercase tracking-wider' : 'text-text-muted'}`}>
                                                            <span dangerouslySetInnerHTML={{ __html: cell.trim().replace(/\*\*(.*?)\*\*/g, '<strong class="text-white">$1</strong>') }} />
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
                        return <p key={i} className="text-text-muted leading-relaxed" dangerouslySetInnerHTML={{
                            __html: trimmed
                                .replace(/\*\*(.*?)\*\*/g, '<strong class="text-white">$1</strong>')
                                .replace(/\[(.*?)\]\((.*?)\)/g, '<a href="$2" class="text-brand-light hover:underline">$1</a>')
                        }} />;
                    })}
                </article>

                {/* CTA */}
                <div className="mt-10 glass-card border border-brand/20 rounded-2xl p-6 text-center">
                    <p className="text-white font-semibold mb-2">¿Te ha sido útil este artículo?</p>
                    <p className="text-text-muted text-sm mb-4">Prueba nuestros bots GRATIS durante 30 días y empieza a automatizar tu trading.</p>
                    <div className="flex flex-col sm:flex-row gap-3 justify-center">
                        <Link href="/bots" className="inline-block px-8 py-3 rounded-xl bg-brand text-white font-semibold hover:bg-brand-light transition-colors text-sm">
                            Ver Todos los Bots →
                        </Link>
                        <Link href="/bots" className="inline-block px-8 py-3 rounded-xl border border-success/40 text-success font-semibold hover:bg-success/10 transition-colors text-sm">
                            🎁 Probar Gratis 30 Días
                        </Link>
                    </div>
                </div>
            </div>
        </div>
    );
}

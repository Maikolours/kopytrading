import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/Card";
import Link from "next/link";

const ARTICLES = [
    {
        slug: "oro-supera-maximos",
        title: "🥇 El Oro Supera Máximos Históricos: ¿Qué Está Impulsando el Rally?",
        category: "XAUUSD | Análisis",
        excerpt: "El precio del Oro (XAUUSD) ha vuelto a marcar máximos históricos en las primeras semanas de 2026, superando los 2.900$ la onza. El principal catalizador sigue siendo la compra masiva de bancos centrales asiáticos (China, India, Turquía) que buscan diversificar sus reservas lejos del dólar.",
        date: "20 Feb, 2026",
        readTime: "6 min"
    },
    {
        slug: "eurusd-analisis",
        title: "💵 EURUSD: ¿El Euro Toca Techo o Hay Más Recorrido?",
        category: "EURUSD | Análisis",
        excerpt: "El par EURUSD ha mostrado una rebaja significativa en los meses recientes, presionado por la divergencia de políticas monetarias entre la Reserva Federal (FED) y el Banco Central Europeo (BCE). Esta divergencia crea oportunidades claras para los bots tendenciales.",
        date: "17 Feb, 2026",
        readTime: "5 min"
    },
    {
        slug: "usdjpy-boj",
        title: "🎌 USDJPY: El BoJ Mueve Ficha - Implicaciones para el Yen Trader",
        category: "USDJPY | Macro",
        excerpt: "El Banco de Japón (BoJ) sorprendió al mercado con una subida de tipos a 0.50%, la más alta en más de 15 años. Esto provocó una apreciación violenta del Yen de casi 300 pips en pocas horas. Un recordatorio crucial de la importancia del calendario económico.",
        date: "14 Feb, 2026",
        readTime: "7 min"
    },
    {
        slug: "bitcoin-consolidacion",
        title: "₿ Bitcoin en Consolidación: ¿Acumulación o Distribución Antes del Próximo Impulso?",
        category: "BTCUSD | Cripto",
        excerpt: "Bitcoin lleva semanas en un rango de consolidación entre los 90.000$ y 105.000$ tras el rally post-halvening de 2024. Los analistas on-chain detectan volumen estable y salidas mínimas de los exchanges, señales clásicas de acumulación institucional.",
        date: "10 Feb, 2026",
        readTime: "8 min"
    },
    {
        slug: "vps-trading",
        title: "📊 VPS Trading: La Herramienta Invisible que Marca la Diferencia",
        category: "Tecnología | Educación",
        excerpt: "Una de las diferencias más grandes entre un trader algorítmico amateur y uno avanzado no está en el bot que usa, sino en la infraestructura con la que lo ejecuta. Un VPS garantiza latencia baja, conexión ininterrumpida 24/5 y ejecución consistente.",
        date: "05 Feb, 2026",
        readTime: "4 min"
    },
    {
        slug: "gestion-riesgo",
        title: "⚠️ Gestión de Riesgo en Tiempos de Volatilidad Extrema",
        category: "Educación | Esencial",
        excerpt: "El mayor error de los traders novatos no es elegir mal la estrategia, sino sobredimensionar el tamaño de sus posiciones (oversizing). Aprende las 5 reglas de oro de KOPYTRADE para sobrevivir en los mercados.",
        date: "01 Feb, 2026",
        readTime: "9 min"
    },
    {
        slug: "indicadores-volatilidad-atr",
        title: "📈 ATR: Cómo Medir la Volatilidad para Colocar tu Stop Loss",
        category: "Educación | Indicadores",
        excerpt: "Uno de los errores más comunes es colocar un Stop Loss fijo. Descubre cómo usar el Average True Range (ATR) para medir la volatilidad real del mercado y colocar tu Stop Loss de forma matemática, como hacen los bots institucionales.",
        date: "28 Feb, 2026",
        readTime: "7 min"
    },
    {
        slug: "trading-algoritmico-vs-manual",
        title: "🤖 Trading Algorítmico vs Manual: ¿Hacia Dónde va el Futuro?",
        category: "Educación | Tendencias",
        excerpt: "El debate sobre si los bots de trading acabarán por reemplazar totalmente a los traders manuales sigue vigente. Comparamos el trading manual tradicional frente a los algoritmos automáticos y por qué la cooperación es la respuesta.",
        date: "25 Feb, 2026",
        readTime: "6 min"
    }
];

export default function ArticulosPage() {
    return (
        <div className="min-h-screen pt-28 sm:pt-32 pb-24 px-4 sm:px-6 lg:px-8 relative">
            <div className="absolute top-1/2 left-0 w-[400px] h-[400px] bg-brand/5 blur-[120px] rounded-full mix-blend-screen pointer-events-none" />

            <div className="max-w-7xl mx-auto z-10 relative">
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

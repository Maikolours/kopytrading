
import { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "KopyTrading | Bots de Trading Algorítmico para MT5",
  description: "Líderes en automatización de trading. Bots especializados en Oro (XAUUSD), Bitcoin y Forex con gestión de riesgo avanzada. Resultados reales y verificados.",
};
import { Button } from "@/components/ui/Button";
import { ProfitCalculator } from "@/components/ProfitCalculator";
import { LiveSalesPopup } from "@/components/LiveSalesPopup";
import { BotComparisonTable } from "@/components/BotComparisonTable";
import { ARTICLES } from "@/lib/constants/articles";

const TICKER_ITEMS = [
  { symbol: "XAU/USD", price: "2,934.50", change: "+0.82%", up: true },
  { symbol: "EUR/USD", price: "1.0842", change: "-0.15%", up: false },
  { symbol: "USD/JPY", price: "149.73", change: "+0.31%", up: true },
  { symbol: "BTC/USD", price: "97,421", change: "+2.14%", up: true },
  { symbol: "XAU/USD", price: "2,934.50", change: "+0.82%", up: true },
  { symbol: "EUR/USD", price: "1.0842", change: "-0.15%", up: false },
  { symbol: "USD/JPY", price: "149.73", change: "+0.31%", up: true },
  { symbol: "BTC/USD", price: "97,421", change: "+2.14%", up: true },
];

export default function Home() {
  return (
    <div className="flex flex-col min-h-screen relative overflow-x-hidden bg-bg-dark overflow-guard">

      {/* === TICKER DE PRECIOS ANIMADO === */}
      <div className="fixed top-0 left-0 right-0 z-[60] bg-bg-dark/95 backdrop-blur border-b border-white/5 py-2">
        <div className="ticker-wrapper">
          <div className="ticker-inner gap-8">
            {TICKER_ITEMS.map((item, i) => (
              <span key={i} className="flex items-center gap-3 px-6">
                <span className="text-xs text-text-muted font-mono">{item.symbol}</span>
                <span className="text-xs font-bold text-white font-mono">{item.price}</span>
                <span className={`text-xs font-semibold ${item.up ? "text-success" : "text-danger"}`}>{item.up ? "▲" : "▼"} {item.change}</span>
              </span>
            ))}
          </div>
        </div>
      </div>

      {/* Fondo */}
      <div className="absolute top-0 inset-x-0 h-full w-full pointer-events-none z-0 overflow-hidden bg-blur-container">
        <div className="absolute top-1/4 left-1/4 -translate-x-1/2 -translate-y-1/2 w-[700px] h-[700px] bg-brand/20 blur-[150px] rounded-full mix-blend-screen" />
        <div className="absolute top-1/3 right-0 translate-x-1/3 w-[500px] h-[500px] bg-accent/10 blur-[120px] rounded-full mix-blend-screen" />
        <div className="absolute bottom-0 left-1/2 -translate-x-1/2 w-full h-[400px] bg-gradient-to-t from-black to-transparent" />
      </div>

      <main className="flex-1 flex flex-col relative pt-28 sm:pt-32 z-10">

        {/* === LANZAMIENTO OFICIAL / OFERTA === */}
        <section className="px-4 mt-8">
          <div className="max-w-5xl mx-auto">
            <div className="relative group">
              <div className="absolute -inset-1 bg-gradient-to-r from-brand to-accent rounded-3xl blur opacity-25 group-hover:opacity-50 transition duration-1000 group-hover:duration-200"></div>
              <div className="relative bg-black/80 border border-brand/30 rounded-2xl p-6 sm:p-8 backdrop-blur-xl flex flex-col md:flex-row items-center gap-6 overflow-hidden">
                <div className="absolute top-0 right-0 p-4 opacity-10">
                  <span className="text-8xl select-none">🔥</span>
                </div>
                
                <div className="flex-shrink-0 w-16 h-16 rounded-2xl bg-brand/20 flex items-center justify-center text-3xl animate-pulse">
                  🚀
                </div>
                
                <div className="flex-1 text-center md:text-left z-10">
                  <h3 className="text-2xl font-black text-white uppercase italic tracking-tighter mb-2">
                    ¡PRÓXIMO LANZAMIENTO: EVOLUTION PRO!
                  </h3>
                  <p className="text-text-muted leading-relaxed max-w-2xl">
                    Estamos preparando el lanzamiento de <span className="text-brand-light font-bold">La Ametralladora Evolution PRO</span>. 
                    <strong className="text-white"> Muy pronto podrás conseguirlo con un 25% de DESCUENTO </strong> 
                    y disfrutar del nuevo sistema de control desde el <span className="text-success font-bold">MÓVIL</span>.
                  </p>
                </div>
                
                <div className="flex-shrink-0">
                  <Link href="/bots">
                    <Button variant="outline" className="border-brand-light text-brand-light hover:bg-brand/10 px-8 py-6 h-auto font-black uppercase tracking-widest text-xs shadow-lg">
                      Ver Catálogo →
                    </Button>
                  </Link>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* === HERO === */}
        <section className="flex items-center px-4 sm:px-6 lg:px-8 py-10 md:py-16 hero-section relative">
          <div className="max-w-7xl mx-auto w-full grid lg:grid-cols-2 gap-12 items-center">

            {/* Texto Hero */}
            <div className="space-y-8 text-center lg:text-left">
              <h1 className="text-3xl sm:text-5xl md:text-6xl font-black tracking-tight text-white leading-tight uppercase italic break-words">
                Trading <br />
                <span className="text-transparent bg-clip-text bg-gradient-to-r from-brand-light to-accent">
                   Inteligente
                </span>
              </h1>

              <p className="text-lg sm:text-xl text-text-muted max-w-xl mx-auto lg:mx-0 font-light leading-relaxed">
                Algoritmos de alta precisión para MetaTrader 5. Diseñados por traders para traders. <strong className="text-white font-bold">Pruébalos gratis 30 días.</strong>
              </p>

              <div className="flex flex-col sm:flex-row items-center gap-4 justify-center lg:justify-start">
                <Link href="/bots">
                  <Button variant="accent" size="lg" className="w-full sm:w-auto px-10 h-12 text-base font-black uppercase tracking-widest shadow-[0_0_30px_rgba(139,92,246,0.3)] hover:scale-105 transition-all">
                    Ver Catálogo
                  </Button>
                </Link>
                <Link href="/articulos" className="text-white/60 hover:text-white transition-colors text-xs font-bold uppercase tracking-widest border-b border-white/10 pb-1">
                  Ver Resultados Reales
                </Link>
              </div>

              {/* Stats */}
              <div className="pt-8 flex flex-wrap justify-center lg:justify-start gap-10 border-t border-white/5">
                {[
                  { val: "4", label: "Bots Activos" },
                  { val: "30 Días", label: "Prueba Gratis" },
                  { val: "$500", label: "Capital Mínimo" },
                ].map((s, i) => (
                  <div key={i}>
                    <p className="text-3xl font-black text-white">{s.val}</p>
                    <p className="text-[10px] text-text-muted uppercase tracking-[0.2em] font-bold mt-1">{s.label}</p>
                  </div>
                ))}
              </div>
            </div>

            {/* Visual Hero */}
            <div className="relative group">
              <div className="absolute -inset-4 bg-brand/20 blur-[60px] rounded-full opacity-50 group-hover:opacity-100 transition-opacity duration-1000" />
              <div className="relative glass-card border border-white/10 rounded-[3rem] p-8 sm:p-10 flex flex-col justify-center overflow-hidden shadow-2xl">
                 <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-brand to-transparent" />
                 
                 <div className="space-y-6">
                    <div className="flex justify-between items-end">
                       <div className="space-y-1">
                          <div className="text-[10px] text-brand-light font-black uppercase tracking-[0.3em]">Live Performance</div>
                          <div className="text-4xl font-black text-white italic tracking-tighter uppercase">XAUUSD</div>
                       </div>
                       <div className="text-right">
                          <div className="text-success font-black text-2xl tracking-tighter">+42.5%</div>
                          <div className="text-[10px] text-text-muted uppercase font-bold tracking-widest">Este Mes</div>
                       </div>
                    </div>
                    
                    <div className="relative h-2 bg-white/5 rounded-full overflow-hidden">
                       <div className="absolute top-0 left-0 h-full bg-brand w-[75%] shadow-[0_0_15px_rgba(139,92,246,0.8)]" />
                    </div>
                    
                    <div className="grid grid-cols-2 gap-4">
                       <div className="bg-white/[0.03] border border-white/5 p-4 rounded-3xl hover:bg-white/10 transition-colors group/item">
                          <div className="text-[10px] text-white/30 uppercase font-black tracking-widest mb-1 group-hover/item:text-brand-light transition-colors">Estrategia</div>
                          <div className="text-sm font-bold text-white uppercase italic">Scalping HFT</div>
                       </div>
                       <div className="bg-white/[0.03] border border-white/5 p-4 rounded-3xl hover:bg-white/10 transition-colors group/item">
                          <div className="text-[10px] text-white/30 uppercase font-black tracking-widest mb-1 group-hover/item:text-success transition-colors">Riesgo</div>
                          <div className="text-sm font-bold text-success uppercase italic">Controlado</div>
                       </div>
                    </div>
                    
                    <Link href="/bots" className="relative group/btn block text-center bg-white/5 hover:bg-brand py-5 rounded-3xl transition-all duration-500 font-black text-[10px] uppercase tracking-[0.2em] border border-white/10 hover:border-brand shadow-xl">
                       <span className="relative z-10 text-white">Ver Análisis Detallado →</span>
                    </Link>
                 </div>
              </div>
            </div>
          </div>
        </section>

        {/* === BANNER PRUEBA GRATIS === */}
        <section className="px-4 sm:px-6 lg:px-8 mb-12">
          <div className="max-w-5xl mx-auto">
            <Link href="/bots" className="block group">
              <div className="relative overflow-hidden rounded-3xl border border-brand/40 bg-gradient-to-r from-brand/20 via-brand-dark/30 to-brand/20 p-6 sm:p-8 flex flex-col lg:flex-row items-center justify-between gap-6 hover:border-brand-light/60 transition-all duration-300 hover:shadow-[0_0_50px_rgba(139,92,246,0.3)]">
                <div className="absolute inset-0 bg-gradient-to-r from-transparent via-brand/5 to-transparent animate-gradient-sweep pointer-events-none" />
                <div className="flex items-center gap-6 z-10">
                  <div className="w-16 h-16 sm:w-20 sm:h-20 rounded-2xl bg-gradient-to-br from-success to-emerald-600 flex items-center justify-center shadow-lg shadow-success/40 flex-shrink-0">
                    <span className="text-3xl sm:text-4xl">🎁</span>
                  </div>
                  <div className="text-left">
                    <h2 className="text-xl sm:text-2xl font-black text-white uppercase italic mb-1 tracking-tight">Prueba cualquier Bot GRATIS</h2>
                    <p className="text-sm sm:text-base text-text-muted font-light">Acceso completo durante 30 días · Sin tarjeta de crédito · Sin compromiso</p>
                  </div>
                </div>
                <div className="flex-shrink-0 z-10 w-full lg:w-auto">
                  <span className="block text-center lg:inline-flex items-center gap-3 px-10 py-5 rounded-2xl bg-success text-white font-black text-sm shadow-xl shadow-success/30 group-hover:bg-emerald-500 transition-all uppercase tracking-[0.15em]">
                    Empezar Ahora →
                  </span>
                </div>
              </div>
            </Link>
          </div>
        </section>

        {/* === SECCIÓN CALCULADORA === */}
        <section className="px-4 py-20 bg-black/40">
           <ProfitCalculator />
        </section>

        {/* === SECCIÓN COMPARATIVA === */}
        <section className="px-4 py-20 border-t border-white/5">
           <BotComparisonTable />
        </section>

        {/* === SECCIÓN ÚLTIMOS ANÁLISIS === */}
        <section className="px-4 py-24 relative overflow-hidden">
           <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full h-full bg-brand/5 blur-[120px] rounded-full pointer-events-none" />
           
           <div className="max-w-7xl mx-auto relative z-10">
              <div className="text-center mb-16 space-y-4">
                 <h2 className="text-3xl sm:text-5xl font-black text-white italic tracking-tighter uppercase leading-none">
                    Últimos <span className="text-brand-light">Análisis</span>
                 </h2>
                 <p className="text-text-muted max-w-2xl mx-auto font-light lg:text-lg">
                    Mantente al día con las últimas estrategias y estados del mercado. Análisis técnico institucional a tu alcance.
                 </p>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
                 {ARTICLES.slice(0, 3).map((article, j) => (
                    <Link href={`/articulos/${article.slug}`} key={j} className="group">
                       <div className="glass-card border border-white/5 rounded-[2.5rem] p-8 h-full flex flex-col space-y-6 hover:border-brand/40 transition-all duration-500 hover:-translate-y-2 hover:shadow-2xl hover:shadow-brand/20 bg-white/[0.02]">
                          <div className="space-y-2">
                             <span className="text-[10px] font-black text-brand-light uppercase tracking-[0.2em]">{article.category}</span>
                             <h3 className="text-xl font-black text-white group-hover:text-brand-light transition-colors leading-tight italic uppercase tracking-tight">{article.title}</h3>
                          </div>
                          <p className="text-text-muted text-sm line-clamp-3 font-light leading-relaxed flex-grow">
                             {article.excerpt}
                          </p>
                          <div className="flex items-center justify-between pt-6 border-t border-white/5">
                             <span className="text-[10px] text-text-muted font-bold uppercase tracking-widest">⏱ {article.readTime}</span>
                             <span className="text-[10px] text-brand-light font-black uppercase tracking-widest group-hover:translate-x-2 transition-transform">Leer Más →</span>
                          </div>
                       </div>
                    </Link>
                 ))}
              </div>

              <div className="mt-16 text-center">
                 <Link href="/articulos">
                    <Button variant="outline" className="border-white/10 text-white/60 hover:text-white px-10 rounded-full text-xs font-black uppercase tracking-widest">
                       Ver Todos los Artículos
                    </Button>
                 </Link>
              </div>
           </div>
        </section>

        <LiveSalesPopup />
      </main>
    </div>
  );
}

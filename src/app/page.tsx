
import Link from "next/link";
import { Button } from "@/components/ui/Button";
import { ProfitCalculator } from "@/components/ProfitCalculator";
import { LiveSalesPopup } from "@/components/LiveSalesPopup";
import { BotComparisonTable } from "@/components/BotComparisonTable";

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
    <div className="flex flex-col min-h-screen relative overflow-hidden bg-bg-dark">

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
      <div className="absolute top-0 inset-x-0 h-full w-full pointer-events-none z-0">
        <div className="absolute top-1/4 left-1/4 -translate-x-1/2 -translate-y-1/2 w-[700px] h-[700px] bg-brand/20 blur-[150px] rounded-full mix-blend-screen" />
        <div className="absolute top-1/3 right-0 translate-x-1/3 w-[500px] h-[500px] bg-accent/10 blur-[120px] rounded-full mix-blend-screen" />
        <div className="absolute bottom-0 left-1/2 -translate-x-1/2 w-full h-[400px] bg-gradient-to-t from-black to-transparent" />
      </div>

      <main className="flex-1 flex flex-col relative pt-28 sm:pt-32 z-10">

        {/* === BANNER PRUEBA GRATIS === */}
        <section className="px-4 sm:px-6 lg:px-8 mt-4 mb-2">
          <div className="max-w-4xl mx-auto">
            <Link href="/bots" className="block group">
              <div className="relative overflow-hidden rounded-2xl border border-brand/30 bg-gradient-to-r from-brand/10 via-brand-dark/20 to-brand/10 p-4 sm:p-5 flex flex-col sm:flex-row items-center justify-between gap-4 hover:border-brand-light/50 transition-all duration-300 hover:shadow-[0_0_30px_rgba(139,92,246,0.2)]">
                <div className="absolute inset-0 bg-gradient-to-r from-transparent via-brand/5 to-transparent animate-gradient-sweep pointer-events-none" />
                <div className="flex items-center gap-4 z-10">
                  <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-success to-emerald-600 flex items-center justify-center shadow-lg shadow-success/30 flex-shrink-0">
                    <span className="text-2xl">🎁</span>
                  </div>
                  <div className="text-left">
                    <h2 className="text-sm sm:text-base font-black text-white uppercase italic">Prueba Gratis 30 Días</h2>
                    <p className="text-[10px] sm:text-xs text-text-muted">Acceso completo a cualquier bot · Sin tarjeta</p>
                  </div>
                </div>
                <div className="flex-shrink-0 z-10">
                  <span className="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-success text-white font-black text-xs shadow-lg shadow-success/30 group-hover:bg-emerald-500 transition-all uppercase tracking-widest">
                    Empezar →
                  </span>
                </div>
              </div>
            </Link>
          </div>
        </section>

        {/* === HERO === */}
        <section className="flex items-center px-4 sm:px-6 lg:px-8 py-10 md:py-20">
          <div className="max-w-7xl mx-auto w-full grid lg:grid-cols-2 gap-12 items-center">

            {/* Texto Hero */}
            <div className="space-y-8 text-center lg:text-left">
              <h1 className="text-4xl sm:text-5xl md:text-6xl font-black tracking-tight text-white leading-[1.1] uppercase italic">
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
                <Link href="/activos#resultados" className="text-white/60 hover:text-white transition-colors text-xs font-bold uppercase tracking-widest border-b border-white/10 pb-1">
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

            {/* Visual Hero Simple */}
            <div className="relative">
              <div className="absolute inset-0 bg-brand/30 blur-[100px] rounded-full" />
              <div className="relative glass-card border border-white/10 rounded-[3rem] p-8 aspect-square flex flex-col justify-center">
                 <div className="space-y-6">
                    <div className="flex justify-between items-end">
                       <div className="text-4xl font-black text-white italic">XAUUSD</div>
                       <div className="text-success font-black text-xl">+42.5%</div>
                    </div>
                    <div className="w-full h-1 bg-white/5 rounded-full overflow-hidden">
                       <div className="h-full bg-brand w-[75%]" />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                       <div className="bg-white/5 p-4 rounded-2xl">
                          <div className="text-[10px] text-white/30 uppercase font-black tracking-widest mb-1">Estrategia</div>
                          <div className="text-sm font-bold text-white">Scalping HFT</div>
                       </div>
                       <div className="bg-white/5 p-4 rounded-2xl">
                          <div className="text-[10px] text-white/30 uppercase font-black tracking-widest mb-1">Riesgo</div>
                          <div className="text-sm font-bold text-success">Controlado</div>
                       </div>
                    </div>
                    <Link href="/bots" className="block text-center bg-white/10 hover:bg-white/20 py-4 rounded-2xl transition-all font-bold text-xs uppercase tracking-widest">
                       Ver Análisis Detallado
                    </Link>
                 </div>
              </div>
            </div>

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

        <LiveSalesPopup />
      </main>
    </div>
  );
}

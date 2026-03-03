import Link from "next/link";
import { Button } from "@/components/ui/Button";

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

const BROKERS = [
  { name: "Vantage Markets", logo: "V", color: "from-red-500 to-red-700", desc: "Tu broker actual. Buena ejecución en Oro. MT5 nativo.", reg: "ASIC / CIMA" },
  { name: "VT Markets", logo: "VT", color: "from-blue-500 to-blue-700", desc: "Tu broker alternativo. Spreads competitivos. MT5.", reg: "ASIC / FSC" },
  { name: "Pepperstone", logo: "P", color: "from-green-500 to-green-700", desc: "Líder mundial. Spreads raw desde 0 pips. VPS gratis.", reg: "FCA / ASIC" },
  { name: "IC Markets", logo: "IC", color: "from-purple-500 to-purple-700", desc: "Favorito de los traders algorítmicos. Latencia ultra baja.", reg: "ASIC / CySEC" },
];

export default function Home() {
  return (
    <div className="flex flex-col min-h-screen relative overflow-hidden">

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
        <div className="absolute top-1/4 left-1/4 -translate-x-1/2 -translate-y-1/2 w-[700px] h-[700px] bg-brand/20 blur-[150px] rounded-full mix-blend-screen animate-float-slow" />
        <div className="absolute top-1/3 right-0 translate-x-1/3 w-[500px] h-[500px] bg-accent/10 blur-[120px] rounded-full mix-blend-screen" />
        <div className="absolute bottom-0 left-1/2 -translate-x-1/2 w-full h-[400px] bg-gradient-to-t from-black to-transparent" />
        <div className="absolute inset-0 bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHBhdGggZD0iTTU5LjUgMGguNXY2MEg1OXYtNjB6TTAgNTkuNXYuNWg2MHYtLjVIMHoiIGZpbGw9InJnYmEoMjU1LDI1NSwyNTUsMC4wMykiLz48L3N2Zz4=')] opacity-20" />
      </div>

      <main className="flex-1 flex flex-col relative pt-28 sm:pt-32 z-10">

        {/* === BANNER PRUEBA GRATIS === */}
        <section className="px-4 sm:px-6 lg:px-8 pt-4 pb-2">
          <div className="max-w-5xl mx-auto">
            <Link href="/bots" className="block group">
              <div className="relative overflow-hidden rounded-2xl border border-brand/40 bg-gradient-to-r from-brand/20 via-brand-dark/30 to-brand/20 p-4 sm:p-5 flex flex-col sm:flex-row items-center justify-between gap-4 hover:border-brand-light/60 transition-all duration-300 hover:shadow-[0_0_40px_rgba(139,92,246,0.3)]">
                <div className="absolute inset-0 bg-gradient-to-r from-transparent via-brand/5 to-transparent animate-gradient-sweep pointer-events-none" />
                <div className="flex items-center gap-4 z-10">
                  <div className="w-12 h-12 sm:w-14 sm:h-14 rounded-2xl bg-gradient-to-br from-success to-emerald-600 flex items-center justify-center shadow-lg shadow-success/30 flex-shrink-0">
                    <span className="text-2xl sm:text-3xl">🎁</span>
                  </div>
                  <div>
                    <h2 className="text-base sm:text-lg font-bold text-white">Prueba cualquier Bot GRATIS durante 30 días</h2>
                    <p className="text-xs sm:text-sm text-text-muted">Sin tarjeta de crédito · Sin compromiso · Acceso completo al bot</p>
                  </div>
                </div>
                <div className="flex-shrink-0 z-10">
                  <span className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-success text-white font-semibold text-sm shadow-lg shadow-success/30 group-hover:bg-emerald-500 transition-colors">
                    Empezar Prueba Gratis →
                  </span>
                </div>
              </div>
            </Link>
          </div>
        </section>

        {/* === HERO === */}
        <section className="flex items-center px-4 sm:px-6 lg:px-8 py-4 sm:py-6">
          <div className="max-w-7xl mx-auto w-full grid lg:grid-cols-2 gap-8 lg:gap-12 items-center">

            {/* Texto Hero */}
            <div className="space-y-6 text-center lg:text-left animate-slide-up">
              <div className="inline-flex items-center gap-3 px-4 py-2 rounded-full border border-brand/40 bg-surface/40 backdrop-blur-md shadow-[0_0_20px_rgba(139,92,246,0.2)] text-sm text-brand-light">
                <span className="relative flex h-2.5 w-2.5">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-brand-light opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-brand-light"></span>
                </span>
                Tu entrada al Trading Algorítmico
              </div>

              <h1 className="text-4xl sm:text-5xl md:text-6xl lg:text-7xl font-extrabold tracking-tight text-white leading-[1.15] text-hero">
                Trading Inteligente{" "}
                <span className="text-transparent bg-clip-text gradient-animate filter drop-shadow-[0_0_15px_rgba(167,139,250,0.5)]">
                  al alcance de Todos
                </span>
              </h1>

              <p className="text-base sm:text-lg md:text-xl text-text-muted max-w-2xl mx-auto lg:mx-0 font-light">
                Bots para MetaTrader 5 diseñados por expertos. <strong className="text-success">Pruébalos gratis 30 días.</strong> Pago único, sin suscripciones. Protegidos por licencia personal.
              </p>

              <div className="flex flex-col sm:flex-row items-center gap-4 justify-center lg:justify-start pt-2">
                <Link href="/bots">
                  <Button variant="accent" size="lg" className="w-full sm:w-auto px-8 text-base sm:text-lg animate-pulse-glow">
                    🚀 Ver Todos los Bots
                  </Button>
                </Link>
                <Link href="/bots">
                  <Button variant="glass" size="lg" className="w-full sm:w-auto px-8 text-base sm:text-lg border-success/40 hover:border-success/70 text-success hover:text-white">
                    🎁 Probar Gratis 30 Días
                  </Button>
                </Link>
              </div>

              {/* Stats */}
              <div className="pt-6 grid grid-cols-3 gap-4 sm:gap-6 border-t border-white/10 text-center lg:text-left">
                {[
                  { val: "4", label: "Bots Activos" },
                  { val: "30 Días", label: "Prueba Gratis" },
                  { val: "M15", label: "Temporalidad Estrella" },
                ].map((s, i) => (
                  <div key={i} className="group p-3 sm:p-4 rounded-xl hover:bg-white/5 transition-all cursor-default">
                    <p className="text-2xl sm:text-3xl font-bold text-white group-hover:text-brand-light transition-colors">{s.val}</p>
                    <p className="text-xs sm:text-sm text-text-muted mt-1">{s.label}</p>
                  </div>
                ))}
              </div>
            </div>

            {/* Visual Hero — Chart Card (responsive, visible en móvil) */}
            <div className="relative mx-auto w-full max-w-[420px] lg:max-w-none animate-slide-right">
              <div className="absolute inset-0 bg-brand/25 blur-[80px] rounded-full pointer-events-none animate-pulse-glow"></div>
              <div className="relative glass-card border border-white/15 rounded-[2rem] p-3 w-full aspect-square sm:aspect-[4/4] flex items-center justify-center overflow-hidden card-3d">
                <div className="absolute inset-0 bg-gradient-to-br from-brand/10 via-transparent to-brand/5"></div>
                <div className="relative w-full h-full flex flex-col p-4 sm:p-5 z-10">
                  {/* Header */}
                  <div className="flex justify-between items-center mb-4">
                    <div className="flex gap-3 items-center">
                      <div className="w-9 h-9 sm:w-10 sm:h-10 rounded-full bg-gradient-to-br from-yellow-400 to-yellow-600 flex items-center justify-center shadow-lg">
                        <span className="text-yellow-900 font-bold text-xs sm:text-sm">XAU</span>
                      </div>
                      <div>
                        <div className="text-xs text-text-muted">Oro / USD</div>
                        <div className="text-xl sm:text-2xl font-extrabold text-white tracking-tight">2,934.50</div>
                      </div>
                    </div>
                    <div className="text-success font-semibold flex items-center bg-success/15 border border-success/30 px-2 sm:px-3 py-1 sm:py-1.5 rounded-lg text-xs sm:text-sm">
                      ↑ +0.82%
                    </div>
                  </div>
                  {/* Velas */}
                  <div className="flex-1 flex items-end gap-1 sm:gap-1.5 justify-between py-3">
                    {[40, 60, 45, 80, 50, 90, 70, 100, 85, 110, 95].map((h, i) => (
                      <div key={i} className="relative w-full flex justify-center h-full items-end">
                        <div className={`relative w-full max-w-[10px] sm:max-w-[12px] rounded-sm ${i % 2 === 0 ? "bg-gradient-to-t from-success/80 to-success" : "bg-gradient-to-t from-danger/80 to-danger"}`} style={{ height: `${h}%` }}>
                          <div className="absolute -top-3 left-1/2 -translate-x-1/2 w-0.5 h-3 bg-white/30"></div>
                          <div className="absolute -bottom-3 left-1/2 -translate-x-1/2 w-0.5 h-3 bg-white/30"></div>
                        </div>
                      </div>
                    ))}
                  </div>
                  {/* Footer señal */}
                  <div className="glass-card !border-white/10 !rounded-xl p-3 sm:p-4 flex justify-between items-center mt-2 bg-white/5">
                    <div>
                      <div className="text-[10px] sm:text-xs text-brand-light font-medium uppercase tracking-wider mb-0.5">Señal KopyTrading</div>
                      <div className="text-base sm:text-xl font-bold flex items-center gap-2">La Ametralladora <span className="text-success text-sm animate-pulse">●</span></div>
                    </div>
                    <div className="w-9 h-9 sm:w-11 sm:h-11 rounded-xl bg-gradient-to-br from-brand to-brand-bright flex items-center justify-center shadow-lg shadow-brand/40">
                      <span className="text-white text-base sm:text-lg">🔥</span>
                    </div>
                  </div>
                </div>
              </div>
              {/* Badge flotante - solo visible en desktop */}
              <div className="absolute top-1/4 -left-8 float-3d p-3 rounded-xl border border-white/20 items-center gap-3 animate-float z-20 hidden lg:flex">
                <div className="w-9 h-9 rounded-full bg-gradient-to-br from-yellow-400 to-yellow-600 flex items-center justify-center text-xs font-bold text-yellow-900">XAU</div>
                <div>
                  <div className="text-xs text-text-muted">Bot Activo</div>
                  <div className="text-xs font-bold text-white">Ametralladora v2</div>
                  <div className="text-xs text-success flex items-center gap-1"><span className="w-1.5 h-1.5 rounded-full bg-success"></span> Operando</div>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* === SECCIÓN BROKERS RECOMENDADOS === */}
        <section className="px-4 sm:px-6 lg:px-8 py-20 border-t border-white/5">
          <div className="max-w-7xl mx-auto">
            <div className="text-center mb-12">
              <span className="text-xs font-semibold text-brand-light tracking-widest uppercase mb-3 block">Compatibilidad Verificada</span>
              <h2 className="text-2xl sm:text-3xl font-bold text-white mb-3">Brokers Recomendados</h2>
              <p className="text-text-muted max-w-xl mx-auto text-sm sm:text-base">
                Nuestros bots se han testado y optimizado en estos brokers regulados con spreads bajos. Compatibles 100% con MetaTrader 5.
              </p>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
              {BROKERS.map((broker, i) => (
                <a
                  key={i}
                  href={broker.name === "Vantage Markets" ? "https://www.vantagemarkets.com/" : broker.name === "VT Markets" ? "https://www.vtmarkets.com/" : broker.name === "Pepperstone" ? "https://pepperstone.com/" : "https://www.icmarkets.com/"}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="glass-card border border-white/10 rounded-2xl p-6 text-center card-3d hover:border-accent/40 group transition-all"
                >
                  <div className={`w-16 h-16 rounded-2xl bg-gradient-to-br ${broker.color} flex items-center justify-center mx-auto mb-4 shadow-xl text-white font-extrabold text-xl group-hover:scale-110 transition-transform`}>
                    {broker.logo}
                  </div>
                  <h3 className="text-lg font-bold text-white mb-1 group-hover:text-accent transition-colors">{broker.name}</h3>
                  <p className="text-xs text-text-muted mb-4 leading-relaxed line-clamp-2">{broker.desc}</p>
                  <span className="text-[10px] text-accent font-bold border border-accent/20 px-3 py-1 rounded-full group-hover:bg-accent group-hover:text-black transition-all">Abrir Cuenta ↗</span>
                </a>
              ))}
            </div>
            <p className="text-center text-xs text-text-muted mt-8 opacity-60">
              KopyTrading no tiene afiliación comercial con estos brokers. La selección se basa únicamente en criterios técnicos de compatibilidad con MT5.
            </p>
          </div>
        </section>

        {/* === AVISO DE RIESGO GLOBAL === */}
        <section className="px-4 sm:px-6 lg:px-8 py-8">
          <div className="max-w-4xl mx-auto text-center">
            <p className="text-xs text-text-muted border border-white/5 rounded-xl px-6 py-4 glass-card">
              ⚠️ <strong className="text-white">Advertencia de riesgo:</strong> El trading de CFDs, Forex y Criptomonedas conlleva un alto riesgo de pérdida de capital. Los rendimientos pasados no garantizan resultados futuros. Opera únicamente con capital que puedas permitirte perder. Prueba siempre en cuenta demo antes de operar en real.
            </p>
          </div>
        </section>

      </main>
    </div>
  );
}

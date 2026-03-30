
import { ResultsGallery } from "@/components/ResultsGallery";
import { Countdown } from "@/components/Countdown";
import Link from "next/link";
import { Metadata } from "next";

export const metadata: Metadata = {
  title: "Nuestros Activos | KopyTrading",
  description: "Explora los activos y algoritmos de alta precisión que operamos en el mercado real.",
};

const ASSETS = [
  { 
    id: "XAUUSD", 
    name: "XAUUSD (ORO)", 
    desc: "Nuestro activo estrella. Alta volatilidad y precisión quirúrgica para traders ambiciosos.", 
    icon: "🟡",
    stats: "M15 | +42.5% Histórico",
    color: "border-yellow-500/40 shadow-yellow-500/10",
    theme: "theme-gold",
    isUpcoming: true,
    launchDate: "2026-04-15T00:00:00Z"
  },
  { 
    id: "BTCUSD", 
    name: "BTCUSD (BITCOIN)", 
    desc: "Captura las tendencias institucionales de la criptomoneda líder con nuestro Storm Rider.", 
    icon: "₿",
    stats: "H4/M30 | Explosividad",
    color: "border-purple-500/40 shadow-purple-500/10",
    theme: "theme-btc",
    isUpcoming: true,
    launchDate: "2026-04-20T00:00:00Z"
  },
  { 
    id: "EURUSD", 
    name: "EURUSD (EURO)", 
    desc: "El par más líquido del mundo bajo control del algoritmo Precision Flow.", 
    icon: "🇪🇺",
    stats: "H1 | Riesgo Bajo",
    color: "border-emerald-500/40 shadow-emerald-500/10",
    theme: "theme-eur"
  },
  { 
    id: "USDJPY", 
    name: "USDJPY (YEN)", 
    desc: "Especializado en la sesión asiática para capturar rebotes y rangos dinámicos.", 
    icon: "🇯🇵",
    stats: "M30 | Versatilidad",
    color: "border-red-500/40 shadow-red-500/10",
    theme: "theme-jpy"
  },
];

export default function ActivosPage() {
  return (
    <div className="min-h-screen bg-bg-dark pt-32 pb-20 relative overflow-hidden">
      {/* Fondos decorativos */}
      <div className="absolute top-0 right-0 w-[600px] h-[600px] bg-brand/5 blur-[150px] rounded-full pointer-events-none" />
      <div className="absolute bottom-0 left-0 w-[400px] h-[400px] bg-accent/5 blur-[120px] rounded-full pointer-events-none" />
      
      <div className="max-w-7xl mx-auto relative z-10 px-6 sm:px-6 lg:px-8 mb-4">
          <Link href="/" className="inline-flex items-center gap-2 text-sm text-text-muted hover:text-white transition-colors">
              <span>←</span> Volver al inicio
          </Link>
      </div>

      <section className="px-6 sm:px-6 lg:px-8 mb-24 relative z-10">

        <div className="max-w-7xl mx-auto text-center">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-brand/10 border border-brand/20 text-brand-light text-xs font-semibold tracking-widest uppercase mb-6">
            Ecosistema de Trading
          </div>
          <h1 className="text-3xl sm:text-7xl font-black text-white mb-4 uppercase tracking-tighter italic leading-none">
            Nuestros <span className="text-transparent bg-clip-text bg-gradient-to-r from-brand-light to-accent">Activos</span>
          </h1>

          <p className="text-text-muted text-base sm:text-lg max-w-2xl mx-auto mb-10 font-light">
            No operamos todo el mercado, solo donde la ventaja estadística es real. Descubre los instrumentos que hemos masterizado para ti.
          </p>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8">
            {ASSETS.map((asset, i) => (
              <Link 
                key={i} 
                href={`/bots?asset=${asset.id}`}
                className={`glass-card border-2 ${asset.color} rounded-[2.5rem] p-6 sm:p-10 text-center hover:scale-[1.05] transition-all group relative overflow-hidden flex flex-col items-center justify-between min-h-[400px] sm:min-h-[450px] shadow-2xl ${asset.theme}`}
              >
                {asset.isUpcoming && (
                  <div className="absolute top-8 -right-12 rotate-45 bg-gradient-to-r from-brand to-accent text-white px-14 py-1.5 text-[10px] font-black uppercase tracking-[0.2em] shadow-xl z-20">
                    Próximo Lanzamiento
                  </div>
                )}

                <div className="absolute inset-0 bg-gradient-to-br from-[var(--theme-color)]/10 to-transparent pointer-events-none" />
                
                <div className="relative z-10 w-full">
                  <div className="text-6xl sm:text-7xl mb-8 group-hover:scale-110 group-hover:rotate-6 transition-transform duration-700 drop-shadow-[0_0_20px_rgba(var(--glow-color),0.3)]">{asset.icon}</div>
                  <h3 className="text-white font-black text-2xl sm:text-3xl mb-4 group-hover:text-brand-light transition-colors uppercase tracking-tighter italic">{asset.name}</h3>
                  <p className="text-text-muted text-sm sm:text-base leading-relaxed mb-8 font-medium opacity-80">{asset.desc}</p>
                  
                  {asset.isUpcoming && asset.launchDate && (
                    <div className="mt-4 flex flex-col items-center gap-3">
                       <span className="text-[10px] font-black text-brand-light uppercase tracking-widest">Disponible en:</span>
                       <Countdown targetDate={asset.launchDate} />
                    </div>
                  )}
                </div>

                <div className="relative z-10 w-full pt-8 border-t border-white/10 space-y-5">
                  <div className="text-[11px] font-black text-white/50 uppercase tracking-[0.3em]">{asset.stats}</div>
                  <div className="inline-flex items-center gap-3 text-brand-light font-black text-xs uppercase tracking-widest group-hover:translate-x-3 transition-transform">
                    Explorar Bots <span className="text-xl animate-pulse">→</span>
                  </div>
                </div>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* SECCIÓN DE RESULTADOS DINÁMICA */}
      <div id="resultados" className="py-20 border-y border-white/5 bg-black/40 backdrop-blur-md">
        <div className="max-w-7xl mx-auto px-4">
           <div className="text-center mb-12">
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-success/10 border border-success/20 text-success text-[10px] font-bold tracking-widest uppercase mb-4">
                <span className="w-1.5 h-1.5 rounded-full bg-success animate-pulse" />
                Operativa en Vivo
              </div>
              <h2 className="text-4xl sm:text-5xl font-black text-white uppercase tracking-tighter italic mb-4">Resultados Reales</h2>
              <p className="text-text-muted text-base max-w-xl mx-auto">Mira cómo operan nuestros algoritmos en cuentas auditadas y en tiempo real.</p>
           </div>
           <ResultsGallery />
        </div>
      </div>

      <section className="py-32 px-4 text-center relative overflow-hidden">
        <div className="absolute inset-0 bg-brand/5 backdrop-blur-3xl -z-10" />
        <div className="max-w-4xl mx-auto">
          <h1 className="text-2xl sm:text-4xl font-black text-white mb-6 italic uppercase tracking-wider leading-relaxed">
            La consistencia no es suerte, <br />es <span className="text-brand-light underline decoration-brand/30 underline-offset-8">matemática</span>.
          </h1>
          <p className="text-text-muted text-base mb-10 max-w-xl mx-auto font-light">
            Únete a cientos de traders que ya operan con el respaldo de nuestros algoritmos profesionales.
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <Link href="/bots" className="inline-block bg-brand hover:bg-brand-light text-white font-black py-5 px-14 rounded-full transition-all shadow-[0_0_40px_rgba(139,92,246,0.6)] uppercase tracking-widest text-sm hover:-translate-y-1">
              Ir al Catálogo de Bots
            </Link>
            <Link href="/faq" className="inline-block glass-card border border-white/10 hover:border-white/20 text-white font-bold py-5 px-10 rounded-full transition-all uppercase tracking-widest text-xs">
              Tengo Dudas
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
}

import { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { Button } from "@/components/ui/Button";

export const metadata: Metadata = {
    title: "Auditoría Cuantitativa, Backtests & Resultados | KopyTrading",
    description: "Auditoría técnica oficial de MAIKO PRO GOLD v11.35. Rendimiento institucional de +8.020$ en XAUUSD (M5), simulación Monte Carlo de 2.000 iteraciones y resultados de la comunidad.",
    alternates: {
        canonical: "https://www.kopytrading.com/resultados",
    },
};

export default function ResultadosPage() {
    return (
        <div className="min-h-screen pt-24 md:pt-28 pb-20 px-4 sm:px-6 lg:px-8 relative overflow-hidden bg-[#050505]">
            {/* Background Aesthetic Blur */}
            <div className="absolute top-0 right-0 w-[700px] h-[700px] bg-amber-500/5 blur-[160px] rounded-full pointer-events-none -mr-40 -mt-20 opacity-60" />
            <div className="absolute top-1/3 left-0 w-[500px] h-[500px] bg-brand/5 blur-[140px] rounded-full pointer-events-none -ml-20 opacity-30" />
            <div className="absolute bottom-0 right-1/4 w-[600px] h-[600px] bg-emerald-500/5 blur-[160px] rounded-full pointer-events-none opacity-40" />

            <div className="max-w-7xl mx-auto relative z-10">

                {/* Back to Home Link */}
                <div className="mb-6">
                    <Link href="/" className="inline-flex items-center gap-2 text-xs font-black uppercase tracking-widest text-text-muted hover:text-white transition-all group">
                        <span className="group-hover:-translate-x-1 transition-transform">←</span> Volver al inicio
                    </Link>
                </div>

                {/* Header */}
                <div className="text-center max-w-4xl mx-auto mb-14">
                    <div className="inline-flex items-center gap-2.5 px-4 py-1.5 rounded-full border border-amber-500/40 bg-amber-500/10 text-amber-300 text-[10px] font-black uppercase tracking-[0.2em] mb-4 shadow-[0_0_20px_rgba(245,158,11,0.2)]">
                        <span className="w-2 h-2 rounded-full bg-amber-400 animate-ping"></span>
                        <span>AUDITORÍA CUANTITATIVA INSTITUCIONAL · 100% CALIDAD DE HISTORIAL</span>
                    </div>

                    <h1 className="text-3xl sm:text-5xl lg:text-6xl font-black text-white uppercase italic tracking-tighter mb-4 leading-tight">
                        Auditoría Oficial, <span className="text-transparent bg-clip-text bg-gradient-to-r from-amber-400 via-yellow-300 to-amber-500">Backtests & Resultados</span>
                    </h1>
                    
                    <p className="text-slate-300 text-sm sm:text-base font-light max-w-2xl mx-auto leading-relaxed">
                        Transparencia matemática absoluta: Análisis cuantitativo de <strong className="text-white font-semibold">MAIKO PRO GOLD v11.35</strong> sobre ticks reales de alta resolución en XAUUSD (M5), simulación Monte Carlo de 2.000 escenarios, test de estrés y comprobantes de la comunidad.
                    </p>
                </div>

                {/* 4 KPI Top Cards */}
                <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6 mb-16">
                    <div className="glass-card p-6 border border-amber-500/30 bg-gradient-to-br from-amber-500/10 via-black/40 to-transparent relative overflow-hidden group hover:border-amber-400/60 transition-all shadow-xl shadow-amber-500/5">
                        <div className="text-[10px] text-amber-400 font-black uppercase tracking-widest mb-1">Beneficio Neto Auditado</div>
                        <div className="text-2xl sm:text-4xl font-black text-white italic tracking-tight mb-1">+$7.764,72</div>
                        <div className="text-[11px] text-emerald-400 font-bold">+802.06% ROI (Depósito: $1.000)</div>
                    </div>

                    <div className="glass-card p-6 border border-emerald-500/30 bg-gradient-to-br from-emerald-500/10 via-black/40 to-transparent relative overflow-hidden group hover:border-emerald-400/60 transition-all shadow-xl shadow-emerald-500/5">
                        <div className="text-[10px] text-emerald-400 font-black uppercase tracking-widest mb-1">Tasa de Acierto (Win Rate)</div>
                        <div className="text-2xl sm:text-4xl font-black text-white italic tracking-tight mb-1">89.83%</div>
                        <div className="text-[11px] text-slate-300 font-light">6.330 ganadas / 7.047 órdenes</div>
                    </div>

                    <div className="glass-card p-6 border border-blue-500/30 bg-gradient-to-br from-blue-500/10 via-black/40 to-transparent relative overflow-hidden group hover:border-blue-400/60 transition-all shadow-xl shadow-blue-500/5">
                        <div className="text-[10px] text-blue-400 font-black uppercase tracking-widest mb-1">Drawdown Máx Equidad</div>
                        <div className="text-2xl sm:text-4xl font-black text-white italic tracking-tight mb-1">9.45%</div>
                        <div className="text-[11px] text-slate-300 font-light">Máx .79 (SL 15% de serie)</div>
                    </div>

                    <div className="glass-card p-6 border border-purple-500/30 bg-gradient-to-br from-purple-500/10 via-black/40 to-transparent relative overflow-hidden group hover:border-purple-400/60 transition-all shadow-xl shadow-purple-500/5">
                        <div className="text-[10px] text-purple-400 font-black uppercase tracking-widest mb-1">Riesgo de Ruina (Monte Carlo)</div>
                        <div className="text-2xl sm:text-4xl font-black text-white italic tracking-tight mb-1">0.00%</div>
                        <div className="text-[11px] text-purple-300 font-bold">2.000 simulaciones aleatorias</div>
                    </div>
                </div>

                {/* SECCIÓN 1: CURVA DE RENDIMIENTO Y BALANCE */}
                <div className="glass-card p-6 sm:p-10 border border-white/10 rounded-3xl mb-14 relative overflow-hidden">
                    <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8 pb-6 border-b border-white/5">
                        <div>
                            <span className="text-[10px] font-black uppercase tracking-[0.2em] text-amber-400">Pilar 01 · Comportamiento de Capital</span>
                            <h2 className="text-2xl sm:text-3xl font-black text-white uppercase italic tracking-tight mt-1">
                                Curva de Crecimiento Oficial de Balance y Patrimonio
                            </h2>
                        </div>
                        <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs font-black uppercase tracking-wider shrink-0">
                            ✓ Calidad Historial: 100% Real Ticks
                        </div>
                    </div>

                    <p className="text-sm text-slate-300 font-light leading-relaxed max-w-4xl mb-6">
                        Curva de equidad generada en <strong className="text-white font-medium">MetaTrader 5</strong> durante 10 meses continuos en el activo <strong className="text-amber-400 font-medium">XAUUSD (Oro)</strong> en temporalidad <strong className="text-white font-medium">M5</strong>. Se aprecia un avance ascendente continuo sin caídas parabólicas ni martingalas descontroladas, gracias a los bloques de noticias automáticos y al cierre preventivo de los viernes.
                    </p>

                    <div className="rounded-2xl overflow-hidden border border-amber-500/30 bg-black/80 p-2 shadow-2xl mb-8">
                        <a href="/images/backtests/backtest_2026_curva.png" target="_blank" rel="noopener noreferrer" title="Clic para ampliar en alta resolución" className="block cursor-zoom-in">
                            <img 
                                src="/images/backtests/backtest_2026_curva.png" 
                                alt="Curva de Balance y Patrimonio MAIKO PRO GOLD v11.35" 
                                className="w-full h-auto rounded-xl object-contain hover:scale-[1.008] transition-transform duration-300"
                            />
                        </a>
                    </div>

                    {/* Explicación Técnica de la Curva */}
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-6 pt-4 border-t border-white/5">
                        <div className="bg-white/[0.02] p-5 rounded-2xl border border-white/5">
                            <h4 className="text-xs font-black text-amber-400 uppercase tracking-widest mb-2">1. Salida SOS Dinámica</h4>
                            <p className="text-xs text-text-muted font-light leading-relaxed">
                                Si el mercado inicia una extensión contra la primera orden, el sistema dispara un refuerzo calibrado a 30 pips y busca una salida limpia en BreakEven (+0.50$), garantizando cerrar la exposición sin comprometer el margen.
                            </p>
                        </div>
                        <div className="bg-white/[0.02] p-5 rounded-2xl border border-white/5">
                            <h4 className="text-xs font-black text-amber-400 uppercase tracking-widest mb-2">2. Filtro S/R Multitemporal (80 Pips)</h4>
                            <p className="text-xs text-text-muted font-light leading-relaxed">
                                Bloquea compras en techos históricos de H1/H4 y ventas en suelos mayores a menos de 80 pips de distancia. Evita quedar atrapado en los extremos del mercado diario.
                            </p>
                        </div>
                        <div className="bg-white/[0.02] p-5 rounded-2xl border border-white/5">
                            <h4 className="text-xs font-black text-amber-400 uppercase tracking-widest mb-2">3. Bloqueo Quirúrgico de Noticias</h4>
                            <p className="text-xs text-text-muted font-light leading-relaxed">
                                Pausas programadas los miércoles (14-17h Macro EE.UU.), jueves (1-7h Swaps) y viernes (14-17h NFP). Cierre forzoso de fin de semana a las 21:00h para no sufrir gaps dominicales.
                            </p>
                        </div>
                    </div>
                </div>

                {/* SECCIÓN 2: INFORME MT5 Y MÉTRICAS DETALLADAS */}
                <div className="glass-card p-6 sm:p-10 border border-white/10 rounded-3xl mb-14 relative overflow-hidden">
                    <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8 pb-6 border-b border-white/5">
                        <div>
                            <span className="text-[10px] font-black uppercase tracking-[0.2em] text-emerald-400">Pilar 02 · Certificación Estadística</span>
                            <h2 className="text-2xl sm:text-3xl font-black text-white uppercase italic tracking-tight mt-1">
                                Informe Estadístico Completo MT5
                            </h2>
                        </div>
                        <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-amber-500/10 border border-amber-500/30 text-amber-400 text-xs font-black uppercase tracking-wider shrink-0">
                            Profit Factor: 3.12 | Sharpe: 15.96
                        </div>
                    </div>

                    <p className="text-sm text-slate-300 font-light leading-relaxed max-w-4xl mb-6">
                        Desglose de métricas oficiales generadas directamente por el Strategy Tester de MetaTrader 5: factor de recuperación, correlación lineal (0.98), media de beneficio diario de 35$–45$ y distribución temporal de operaciones.
                    </p>

                    <div className="rounded-2xl overflow-hidden border border-white/10 bg-black/80 p-2 shadow-2xl mb-8">
                        <a href="/images/backtests/backtest_2026_informe.png" target="_blank" rel="noopener noreferrer" title="Clic para ampliar en alta resolución" className="block cursor-zoom-in">
                            <img 
                                src="/images/backtests/backtest_2026_informe.png" 
                                alt="Informe Estadístico MT5 MAIKO PRO GOLD" 
                                className="w-full h-auto rounded-xl object-contain hover:scale-[1.008] transition-transform duration-300"
                            />
                        </a>
                    </div>

                    {/* Tabla de Rendimiento Mensual Auditado */}
                    <div className="overflow-x-auto">
                        <table className="w-full text-left border-collapse text-xs">
                            <thead>
                                <tr className="border-b border-white/10 text-slate-400 uppercase tracking-wider text-[10px]">
                                    <th className="py-3 px-4">Mes Auditado</th>
                                    <th className="py-3 px-4">Trades Ejecutados</th>
                                    <th className="py-3 px-4">Ganadas / Perdidas</th>
                                    <th className="py-3 px-4">Tasa de Acierto</th>
                                    <th className="py-3 px-4">Beneficio Neto</th>
                                    <th className="py-3 px-4">Estado</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-white/5 font-mono">
                                <tr>
                                    <td className="py-3 px-4 font-bold text-white">Enero 2026</td>
                                    <td className="py-3 px-4 text-slate-300">447</td>
                                    <td className="py-3 px-4 text-slate-300">417 / 30</td>
                                    <td className="py-3 px-4 text-emerald-400 font-bold">93.29%</td>
                                    <td className="py-3 px-4 text-emerald-400 font-bold">+$599,36</td>
                                    <td className="py-3 px-4"><span className="px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 text-[9px] uppercase font-bold">POSITIVO</span></td>
                                </tr>
                                <tr>
                                    <td className="py-3 px-4 font-bold text-white">Febrero 2026</td>
                                    <td className="py-3 px-4 text-slate-300">306</td>
                                    <td className="py-3 px-4 text-slate-300">282 / 24</td>
                                    <td className="py-3 px-4 text-emerald-400 font-bold">92.16%</td>
                                    <td className="py-3 px-4 text-emerald-400 font-bold">+$366,34</td>
                                    <td className="py-3 px-4"><span className="px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 text-[9px] uppercase font-bold">POSITIVO</span></td>
                                </tr>
                                <tr>
                                    <td className="py-3 px-4 font-bold text-white">Marzo 2026</td>
                                    <td className="py-3 px-4 text-slate-300">315</td>
                                    <td className="py-3 px-4 text-slate-300">294 / 21</td>
                                    <td className="py-3 px-4 text-emerald-400 font-bold">93.33%</td>
                                    <td className="py-3 px-4 text-emerald-400 font-bold">+$622,44</td>
                                    <td className="py-3 px-4"><span className="px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 text-[9px] uppercase font-bold">POSITIVO</span></td>
                                </tr>
                                <tr>
                                    <td className="py-3 px-4 font-bold text-white">Abril 2026</td>
                                    <td className="py-3 px-4 text-slate-300">477</td>
                                    <td className="py-3 px-4 text-slate-300">445 / 32</td>
                                    <td className="py-3 px-4 text-emerald-400 font-bold">93.29%</td>
                                    <td className="py-3 px-4 text-emerald-400 font-bold">+$788,06</td>
                                    <td className="py-3 px-4"><span className="px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 text-[9px] uppercase font-bold">POSITIVO</span></td>
                                </tr>
                                <tr>
                                    <td className="py-3 px-4 font-bold text-white">Mayo 2026</td>
                                    <td className="py-3 px-4 text-slate-300">480</td>
                                    <td className="py-3 px-4 text-slate-300">443 / 36</td>
                                    <td className="py-3 px-4 text-emerald-400 font-bold">92.29%</td>
                                    <td className="py-3 px-4 text-emerald-400 font-bold">+$669,78</td>
                                    <td className="py-3 px-4"><span className="px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 text-[9px] uppercase font-bold">POSITIVO</span></td>
                                </tr>
                                <tr>
                                    <td className="py-3 px-4 font-bold text-white">Junio 2026</td>
                                    <td className="py-3 px-4 text-slate-300">526</td>
                                    <td className="py-3 px-4 text-slate-300">482 / 43</td>
                                    <td className="py-3 px-4 text-emerald-400 font-bold">91.63%</td>
                                    <td className="py-3 px-4 text-emerald-400 font-bold">+$1.146,64</td>
                                    <td className="py-3 px-4"><span className="px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 text-[9px] uppercase font-bold">POSITIVO</span></td>
                                </tr>
                                <tr>
                                    <td className="py-3 px-4 font-bold text-white">Julio 2026</td>
                                    <td className="py-3 px-4 text-slate-300">535</td>
                                    <td className="py-3 px-4 text-slate-300">496 / 39</td>
                                    <td className="py-3 px-4 text-emerald-400 font-bold">92.71%</td>
                                    <td className="py-3 px-4 text-emerald-400 font-bold">+$953,50</td>
                                    <td className="py-3 px-4"><span className="px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 text-[9px] uppercase font-bold">POSITIVO</span></td>
                                </tr>
                                <tr>
                                    <td className="py-3 px-4 font-bold text-white">Agosto 2026</td>
                                    <td className="py-3 px-4 text-slate-300">496</td>
                                    <td className="py-3 px-4 text-slate-300">462 / 34</td>
                                    <td className="py-3 px-4 text-emerald-400 font-bold">93.15%</td>
                                    <td className="py-3 px-4 text-emerald-400 font-bold">+$475,78</td>
                                    <td className="py-3 px-4"><span className="px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 text-[9px] uppercase font-bold">POSITIVO</span></td>
                                </tr>
                                <tr>
                                    <td className="py-3 px-4 font-bold text-white">Septiembre 2026</td>
                                    <td className="py-3 px-4 text-slate-300">581</td>
                                    <td className="py-3 px-4 text-slate-300">539 / 42</td>
                                    <td className="py-3 px-4 text-emerald-400 font-bold">92.77%</td>
                                    <td className="py-3 px-4 text-emerald-400 font-bold">+$1.239,64</td>
                                    <td className="py-3 px-4"><span className="px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 text-[9px] uppercase font-bold">POSITIVO</span></td>
                                </tr>
                                <tr>
                                    <td className="py-3 px-4 font-bold text-white">Octubre 2026</td>
                                    <td className="py-3 px-4 text-slate-300">509</td>
                                    <td className="py-3 px-4 text-slate-300">480 / 29</td>
                                    <td className="py-3 px-4 text-emerald-400 font-bold">94.30%</td>
                                    <td className="py-3 px-4 text-emerald-400 font-bold">+$1.006,88</td>
                                    <td className="py-3 px-4"><span className="px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 text-[9px] uppercase font-bold">POSITIVO</span></td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>

                {/* SECCIÓN 3: MONTE CARLO (2.000 SIMULACIONES) */}
                <div className="glass-card p-6 sm:p-10 border border-white/10 rounded-3xl mb-14 relative overflow-hidden">
                    <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8 pb-6 border-b border-white/5">
                        <div>
                            <span className="text-[10px] font-black uppercase tracking-[0.2em] text-cyan-400">Pilar 03 · Ciencia Cuantitativa</span>
                            <h2 className="text-2xl sm:text-3xl font-black text-white uppercase italic tracking-tight mt-1">
                                Simulación Monte Carlo (2.000 Iteraciones)
                            </h2>
                        </div>
                        <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-cyan-500/10 border border-cyan-500/30 text-cyan-400 text-xs font-black uppercase tracking-wider shrink-0">
                            Riesgo de Ruina: 0.00%
                        </div>
                    </div>

                    <p className="text-sm text-slate-300 font-light leading-relaxed max-w-4xl mb-6">
                        El remuestreo de <strong className="text-white font-medium">Monte Carlo</strong> baraja aleatoriamente el orden temporal de las operaciones para someter la estrategia a 2.000 escenarios alternativos del mercado. Demuestra matemáticamente que el resultado <strong className="text-cyan-400 font-medium">no se debe a una racha fortuita de suerte</strong>: el 100% de las 2.000 curvas arrojó balance final en beneficios.
                    </p>

                    <div className="rounded-2xl overflow-hidden border border-cyan-500/30 bg-black/80 p-2 shadow-2xl mb-8">
                        <a href="/images/backtests/backtest_monte_carlo.png" target="_blank" rel="noopener noreferrer" title="Clic para ampliar en alta resolución" className="block cursor-zoom-in">
                            <img 
                                src="/images/backtests/backtest_monte_carlo.png" 
                                alt="Simulación Monte Carlo MAIKO PRO GOLD" 
                                className="w-full h-auto rounded-xl object-contain hover:scale-[1.008] transition-transform duration-300"
                            />
                        </a>
                    </div>

                    {/* NOTA METODOLOGICA: CALIBRACION DE GANANCIA DIARIA */}
                    <div className="mb-8 p-4 sm:p-5 rounded-2xl bg-amber-500/10 border border-amber-500/30 flex items-start gap-3.5">
                        <span className="text-xl shrink-0">💡</span>
                        <div className="text-xs text-slate-300 font-light leading-relaxed">
                            <strong className="text-amber-400 font-semibold block mb-1 text-[13px]">Nota Metodológica sobre la Meta de Beneficio Diario:</strong>
                            Para someter el algoritmo al máximo estrés volumétrico continuo, este backtest oficial y su simulación Monte Carlo se ejecutaron con una meta diaria exigente de <strong className="text-white">$60/día</strong>. Para la versión entregada a clientes, hemos fijado de serie un objetivo conservador y ultraseguro de <strong className="text-emerald-400">$20/día</strong> (<code className="text-amber-300 bg-black/40 px-1.5 py-0.5 rounded text-[11px]">TargetDiario = 20.0</code>), permitiendo cerrar la sesión antes y reducir drásticamente la exposición al mercado. Cada usuario mantiene el control total para ajustar este parámetro en cualquier momento desde los ajustes del robot según su propio plan de gestión de capital.
                        </div>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6 pt-4 border-t border-white/5">
                        <div className="bg-white/[0.02] p-5 rounded-2xl border border-white/5">
                            <h4 className="text-xs font-black text-cyan-400 uppercase tracking-widest mb-2">Prueba Z-Score (+2.13)</h4>
                            <p className="text-xs text-text-muted font-light leading-relaxed">
                                Un valor Z-Score superior a +2.0 descarta formalmente la hipótesis de &quot;paseo aleatorio&quot; (random walk) con un 96.7% de confianza estadística, certificando una ventaja matemática intrínseca (Alpha real).
                            </p>
                        </div>
                        <div className="bg-white/[0.02] p-5 rounded-2xl border border-white/5">
                            <h4 className="text-xs font-black text-cyan-400 uppercase tracking-widest mb-2">Rachas de Pérdidas Contenidas</h4>
                            <p className="text-xs text-text-muted font-light leading-relaxed">
                                El 95.6% de las veces que saltó un corte de pérdidas, la siguiente operación fue ganadora. Se registraron 0 ocasiones con 3 pérdidas consecutivas en todo el período auditado.
                            </p>
                        </div>
                    </div>
                </div>

                {/* SECCIÓN 4: PRUEBAS DE ESTRÉS (STRESS TESTING) */}
                <div className="glass-card p-6 sm:p-10 border border-white/10 rounded-3xl mb-14 relative overflow-hidden">
                    <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8 pb-6 border-b border-white/5">
                        <div>
                            <span className="text-[10px] font-black uppercase tracking-[0.2em] text-purple-400">Pilar 04 · Resistencia a Cisnes Negros</span>
                            <h2 className="text-2xl sm:text-3xl font-black text-white uppercase italic tracking-tight mt-1">
                                Pruebas de Estrés Institucional
                            </h2>
                        </div>
                        <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-purple-500/10 border border-purple-500/30 text-purple-400 text-xs font-black uppercase tracking-wider shrink-0">
                            Calmar Ratio: 45.27
                        </div>
                    </div>

                    <p className="text-sm text-slate-300 font-light leading-relaxed max-w-4xl mb-6">
                        Simulación de condiciones hostiles: ensanchamiento drástico de spreads, latencia inducida y deslizamiento de órdenes (slippage) simulan el comportamiento del algoritmo frente a crisis de liquidez en brokers ECN/RAW.
                    </p>

                    <div className="rounded-2xl overflow-hidden border border-purple-500/30 bg-black/80 p-2 shadow-2xl mb-8">
                        <a href="/images/backtests/backtest_stress_testing.png" target="_blank" rel="noopener noreferrer" title="Clic para ampliar en alta resolución" className="block cursor-zoom-in">
                            <img 
                                src="/images/backtests/backtest_stress_testing.png" 
                                alt="Stress Testing MAIKO PRO GOLD" 
                                className="w-full h-auto rounded-xl object-contain hover:scale-[1.008] transition-transform duration-300"
                            />
                        </a>
                    </div>
                </div>

                {/* CALL TO ACTION: DESCARGA DE DEMO */}
                <div className="relative group mb-16">
                    <div className="absolute -inset-1 bg-gradient-to-r from-amber-500 via-yellow-400 to-amber-600 rounded-3xl blur opacity-40 group-hover:opacity-75 transition duration-1000"></div>
                    <div className="relative bg-[#0c0904]/95 border-2 border-amber-500/50 rounded-3xl p-8 sm:p-12 text-center overflow-hidden shadow-[0_0_50px_rgba(245,158,11,0.25)]">
                        <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full bg-amber-500/15 border border-amber-500/40 text-amber-300 text-[10px] font-black uppercase tracking-widest mb-4">
                            <span>PRESET GANADOR CONFIGURADO DE SERIE</span>
                        </div>
                        <h3 className="text-2xl sm:text-4xl font-black text-white uppercase italic tracking-tight mb-3">
                            Prueba Esta Misma Configuración en Tu MetaTrader 5
                        </h3>
                        <p className="text-slate-300 text-xs sm:text-sm font-light max-w-2xl mx-auto mb-8 leading-relaxed">
                            Descarga el bot ejecutable .EX5, el preset institucional .SET y el manual oficial de 11 páginas en PDF. Todo listo para importar y empezar a operar en tu cuenta Demo.
                        </p>
                        <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
                            <a 
                                href="/uploads/bots/02_MAIKO_PRO_GOLD_CLIENT_DEMO_v11.35.ex5" 
                                download 
                                className="w-full sm:w-auto inline-flex items-center justify-center gap-2 py-4 px-8 rounded-xl bg-gradient-to-r from-amber-500 via-yellow-400 to-amber-600 hover:from-amber-400 hover:to-yellow-300 text-slate-950 font-black text-xs uppercase tracking-wider shadow-xl shadow-amber-500/30 transition-all hover:scale-[1.02] active:scale-[0.98]"
                            >
                                <span>⬇️ Descargar Bot Demo (.EX5)</span>
                            </a>
                            <a 
                                href="/uploads/bots/CONFIGURACION_GANADORA_V11.35.set" 
                                download 
                                className="w-full sm:w-auto inline-flex items-center justify-center gap-2 py-4 px-6 rounded-xl bg-white/[0.05] hover:bg-white/[0.1] border border-amber-500/40 text-amber-300 hover:text-white font-black text-xs uppercase tracking-wider transition-all"
                            >
                                <span>⚙️ Descargar Preset (.SET)</span>
                            </a>
                            <a 
                                href="/uploads/Manual_Maiko_Pro_Gold.pdf" 
                                target="_blank" 
                                rel="noopener noreferrer" 
                                download 
                                className="w-full sm:w-auto inline-flex items-center justify-center gap-2 py-4 px-6 rounded-xl bg-white/[0.05] hover:bg-white/[0.1] border border-white/10 text-white/80 hover:text-white font-black text-xs uppercase tracking-wider transition-all"
                            >
                                <span>📖 Manual (.PDF)</span>
                            </a>
                        </div>
                    </div>
                </div>

                {/* SECCIÓN 5: MURO DE BENEFICIOS Y COMUNIDAD */}
                <div className="pt-10 border-t border-white/5">
                    <div className="text-center max-w-2xl mx-auto mb-10">
                        <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full border border-success/30 bg-success/10 text-success text-[10px] font-black uppercase tracking-widest mb-3">
                            <span className="w-2 h-2 rounded-full bg-success animate-pulse"></span>
                            <span>COMUNIDAD OFICIAL</span>
                        </div>
                        <h2 className="text-2xl sm:text-3xl font-black text-white uppercase italic tracking-tight mb-2">
                            Muro de Resultados de la Comunidad
                        </h2>
                        <p className="text-xs sm:text-sm text-text-muted font-light">
                            Capturas compartidas por usuarios y alumnos operando en cuentas de demostración y cuentas reales.
                        </p>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-5xl mx-auto mb-14">
                        {[
                            { id: 1, src: "/images/testimonials/resultado_1.jpg", label: "MAIKO v11.30 Operativo", type: "Demo", name: "David G." },
                            { id: 2, src: "/images/testimonials/resultado_2.jpg", label: "MAIKO PRO GOLD HUD", type: "Demo", name: "Javier R." },
                            { id: 3, src: "/images/testimonials/resultado_3.mp4", label: "Historial Auditado", type: "Demo", name: "Laura M." },
                            { id: 4, src: "/images/testimonials/resultado_4.mp4", label: "Ejecución en Directo", type: "Demo", name: "Carlos T." }
                        ].map((item) => (
                            <div key={item.id} className="glass-card p-4 border border-white/10 relative overflow-hidden group hover:border-success/30 transition-all rounded-2xl">
                                <div className="absolute top-0 right-0 p-4 z-20 pointer-events-none">
                                    <span className="bg-success text-black text-[9px] font-black px-2.5 py-0.5 rounded-full uppercase tracking-widest shadow-lg shadow-success/20">
                                        Verificado
                                    </span>
                                </div>
                                
                                <a 
                                    href={item.src} 
                                    target="_blank" 
                                    rel="noopener noreferrer" 
                                    title="Ver recurso completo"
                                    className="aspect-[4/3] bg-black/50 rounded-xl mb-4 relative overflow-hidden border border-white/5 flex items-center justify-center block cursor-zoom-in hover:border-success/50 transition-colors"
                                >
                                    {item.src.endsWith('.mp4') || item.src.endsWith('.webm') ? (
                                        <video 
                                            src={item.src}
                                            autoPlay
                                            loop
                                            muted
                                            playsInline
                                            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                                        />
                                    ) : (
                                        <Image 
                                            src={item.src} 
                                            alt="Resultado" 
                                            fill 
                                            className="object-contain group-hover:scale-105 transition-transform duration-500" 
                                        />
                                    )}
                                </a>

                                <div className="flex items-center justify-between px-2">
                                    <div className="flex items-center gap-2">
                                        <div className="w-6 h-6 rounded-full bg-white/10 flex items-center justify-center text-[10px] text-text-muted font-bold uppercase">
                                            {item.name.charAt(0)}
                                        </div>
                                        <span className="text-xs text-text-muted font-medium">{item.name}</span>
                                    </div>
                                    <span className="text-[10px] text-text-muted/50 uppercase tracking-widest">{item.label} ({item.type})</span>
                                </div>
                            </div>
                        ))}
                    </div>

                    <div className="p-8 sm:p-10 glass-card border border-brand/20 bg-brand/5 max-w-3xl mx-auto rounded-3xl text-center">
                        <h3 className="text-xl sm:text-2xl font-black text-white uppercase italic tracking-tight mb-3">¿Operas con MAIKO PRO?</h3>
                        <p className="text-xs sm:text-sm text-text-muted font-light mb-6 max-w-lg mx-auto">
                            Envíanos tus resultados y capturas de MetaTrader 5 a nuestro canal de soporte para ser verificado en nuestro muro institucional.
                        </p>
                        <a href="https://t.me/Kpytrading" target="_blank" rel="noopener noreferrer" className="inline-block bg-[#24A1DE] hover:bg-[#1a85b9] text-white font-bold py-3.5 px-7 rounded-full uppercase tracking-widest text-xs transition-colors shadow-lg shadow-[#24A1DE]/20">
                            Enviar Captura por Telegram →
                        </a>
                    </div>
                </div>

            </div>
        </div>
    );
}

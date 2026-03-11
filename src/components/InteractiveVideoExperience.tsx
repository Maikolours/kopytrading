
"use client";

import React, { useState, useEffect, useRef } from 'react';
import { Button } from "@/components/ui/Button";
import { motion, AnimatePresence } from "framer-motion";

interface DataPoint {
  time: string;
  profit: number;
}

export const InteractiveVideoExperience = () => {
  const [step, setStep] = useState<'intro' | 'choice' | 'result_buy' | 'result_wait'>('intro');
  const [liveProfit, setLiveProfit] = useState(1250.45);
  const [history, setHistory] = useState<DataPoint[]>([]);

  // Simulación de datos dinámicos premium
  useEffect(() => {
    const interval = setInterval(() => {
      const change = (Math.random() * 5 - 1); // Tendencia alcista ligera
      setLiveProfit(prev => prev + change);
      
      const newPoint = {
        time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }),
        profit: liveProfit,
      };
      
      setHistory(prev => [...prev.slice(-15), newPoint]);
    }, 1500);
    return () => clearInterval(interval);
  }, [liveProfit]);

  const handleChoice = (choice: 'buy' | 'wait') => {
    if (choice === 'buy') setStep('result_buy');
    else setStep('result_wait');
    
    setTimeout(() => setStep('choice'), 10000);
  };

  return (
    <section className="relative w-full overflow-hidden bg-[#050505] py-24 sm:py-32 px-4 border-y border-white/5">
      {/* Background Orbs */}
      <div className="absolute top-0 left-0 w-full h-full pointer-events-none">
        <div className="absolute top-1/2 left-[-10%] w-[600px] h-[600px] bg-brand/10 blur-[180px] rounded-full" />
        <div className="absolute bottom-[-10%] right-[-10%] w-[500px] h-[500px] bg-accent/5 blur-[150px] rounded-full" />
      </div>

      <div className="max-w-7xl mx-auto relative z-10">
        <div className="flex flex-col md:flex-row md:items-end justify-between mb-16 gap-6">
          <div className="max-w-2xl">
            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-brand/10 border border-brand/20 text-brand-light text-[10px] font-black tracking-[0.2em] uppercase mb-4"
            >
              <span className="w-1.5 h-1.5 rounded-full bg-brand animate-pulse" />
              Experiencia Inmersiva
            </motion.div>
            <h2 className="text-4xl sm:text-6xl font-black text-white mb-6 tracking-tight leading-none">
              El Corazón de la <br />
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-brand-light via-accent to-brand-bright">Ametralladora</span>
            </h2>
            <p className="text-white/50 text-base sm:text-lg font-light max-w-xl">
              No dejes que el miedo decida por ti. Observa cómo nuestros algoritmos ejecutan con precisión quirúrgica donde otros dudan.
            </p>
          </div>
          
          <div className="flex items-center gap-8 bg-white/5 backdrop-blur-xl border border-white/10 rounded-2xl p-6 shadow-2xl">
            <div className="text-center">
              <div className="text-[10px] text-text-muted uppercase font-bold tracking-widest mb-1">Bots Activos</div>
              <div className="text-2xl font-black text-white">2.4k+</div>
            </div>
            <div className="w-px h-10 bg-white/10" />
            <div className="text-center">
              <div className="text-[10px] text-text-muted uppercase font-bold tracking-widest mb-1">Volumen 24h</div>
              <div className="text-2xl font-black text-brand-bright">$14.8M</div>
            </div>
          </div>
        </div>

        <div className="grid lg:grid-cols-12 gap-8 items-stretch">
          
          {/* Main Simulation Engine */}
          <div className="lg:col-span-8 relative group">
            <div className="relative rounded-[3rem] overflow-hidden border border-white/10 bg-[#0a0a0c] shadow-[0_0_80px_rgba(0,0,0,0.5)] aspect-video lg:aspect-auto lg:min-h-[600px] h-full transition-transform duration-700">
              
              {/* Animated Border Glow */}
              <div className="absolute inset-0 bg-gradient-to-br from-brand/20 via-transparent to-accent/20 opacity-30 group-hover:opacity-60 transition-opacity duration-1000" />
              
              {/* Simulation Content */}
              <div className="absolute inset-0 flex items-center justify-center">
                {/* MT5 Grid Simulation */}
                <div className="absolute inset-0 opacity-10 pointer-events-none">
                    <div className="w-full h-full bg-[linear-gradient(to_right,#ffffff10_1px,transparent_1px),linear-gradient(to_bottom,#ffffff10_1px,transparent_1px)] bg-[size:50px_50px]"></div>
                </div>

                <AnimatePresence mode="wait">
                  {step === 'intro' && (
                    <motion.div 
                      key="intro"
                      initial={{ opacity: 0, scale: 0.9 }}
                      animate={{ opacity: 1, scale: 1 }}
                      exit={{ opacity: 0, scale: 1.1, filter: "blur(10px)" }}
                      className="text-center p-12 z-20 relative"
                    >
                      <div className="absolute -inset-20 bg-brand/10 blur-[100px] rounded-full animate-pulse-glow" />
                      <div className="w-24 h-24 bg-gradient-to-br from-brand to-brand-dark rounded-[2rem] flex items-center justify-center mb-8 mx-auto border border-white/20 shadow-2xl transform rotate-12 hover:rotate-0 transition-transform duration-500">
                        <span className="text-4xl">💎</span>
                      </div>
                      <h3 className="text-3xl sm:text-4xl font-black text-white mb-6">¿Preparado para ver <br />la ejecución perfecta?</h3>
                      <p className="text-white/40 mb-10 max-w-sm mx-auto font-medium">Entraremos en el simulador de alta frecuencia de la Ametralladora.</p>
                      <Button onClick={() => setStep('choice')} variant="accent" size="lg" className="shadow-[0_0_30px_rgba(245,158,11,0.3)]">
                        Desbloquear Simulador
                      </Button>
                    </motion.div>
                  )}

                  {step === 'choice' && (
                    <motion.div 
                      key="choice"
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      className="absolute inset-0 flex flex-col items-center justify-center p-12 z-20"
                    >
                       <div className="absolute top-12 left-1/2 -translate-x-1/2 text-center w-full">
                          <motion.div 
                            animate={{ scale: [1, 1.05, 1] }} 
                            transition={{ repeat: Infinity, duration: 2 }}
                            className="text-danger font-black text-xs tracking-[0.3em] uppercase mb-3 block"
                          >
                            ⚠️ SEÑAL DETECTADA ⚠️
                          </motion.div>
                          <h4 className="text-4xl font-black text-white tracking-tighter">XAUUSD <span className="text-white/30">M15</span></h4>
                          <div className="mt-4 flex justify-center gap-12">
                             <div className="text-center">
                                <div className="text-[10px] text-white/40 uppercase font-bold">Volatilidad</div>
                                <div className="text-lg font-bold text-white">ALTA (2.4 ATR)</div>
                             </div>
                             <div className="text-center">
                                <div className="text-[10px] text-white/40 uppercase font-bold">Trend</div>
                                <div className="text-lg font-bold text-success">ALCISTA Institutional</div>
                             </div>
                          </div>
                       </div>

                       <div className="flex flex-col sm:flex-row gap-8 mt-24 w-full max-w-2xl px-4">
                          <button 
                            onClick={() => handleChoice('buy')}
                            className="flex-1 group relative p-8 rounded-[2rem] bg-success/10 border border-success/30 hover:bg-success/20 transition-all shadow-2xl"
                          >
                            <div className="absolute inset-0 bg-gradient-to-t from-success/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
                            <span className="text-5xl block mb-4 group-hover:scale-125 transition-transform duration-500">🔥</span>
                            <span className="text-2xl font-black text-white block">COMPRAR</span>
                            <p className="text-[10px] text-success-light uppercase font-bold tracking-widest mt-2 opacity-60">Ejecución Algorítmica</p>
                          </button>

                          <button 
                            onClick={() => handleChoice('wait')}
                            className="flex-1 group relative p-8 rounded-[2rem] bg-white/5 border border-white/10 hover:bg-white/10 transition-all shadow-2xl"
                          >
                            <span className="text-5xl block mb-4 group-hover:scale-125 transition-transform duration-500">🛡️</span>
                            <span className="text-2xl font-black text-white block">ESPERAR</span>
                            <p className="text-[10px] text-white/20 uppercase font-bold tracking-widest mt-2 opacity-60">Miedo Humano</p>
                          </button>
                       </div>
                    </motion.div>
                  )}

                  {step === 'result_buy' && (
                    <motion.div 
                      key="res_buy"
                      initial={{ opacity: 0, y: 30 }}
                      animate={{ opacity: 1, y: 0 }}
                      className="text-center p-12 z-20"
                    >
                      <motion.div 
                        animate={{ y: [0, -10, 0] }}
                        transition={{ repeat: Infinity, duration: 3 }}
                        className="text-6xl mb-8"
                      >
                        🤑
                      </motion.div>
                      <h3 className="text-5xl sm:text-6xl font-black text-success mb-6 tracking-tighter">+$450.00 <span className="text-2xl text-white/30 font-light">PROFIT</span></h3>
                      <p className="text-white/60 max-w-md mx-auto mb-10 text-lg leading-relaxed">
                        Mientras tú decidiste confiar, el algoritmo aplicó su **gestión inteligente de cobertura** y cerró el ciclo en el pico exacto.
                      </p>
                      <div className="inline-flex items-center gap-3 px-6 py-3 bg-success/10 rounded-2xl text-success text-sm font-bold border border-success/20">
                        <span className="w-2 h-2 rounded-full bg-success animate-ping" />
                        Resultado obtenido en 14 minutos
                      </div>
                    </motion.div>
                  )}

                   {step === 'result_wait' && (
                    <motion.div 
                      key="res_wait"
                      initial={{ opacity: 0, scale: 1.1 }}
                      animate={{ opacity: 1, scale: 1 }}
                      className="text-center p-12 z-20"
                    >
                      <div className="text-6xl mb-8">📉</div>
                      <h3 className="text-4xl sm:text-5xl font-black text-white mb-6 tracking-tighter opacity-80">COSTO DE OPORTUNIDAD</h3>
                      <p className="text-white/40 max-w-md mx-auto mb-10 text-lg">
                        El bot hubiera ganado un **8.5%** de tu cuenta en este movimiento. El miedo es el impuesto más caro que paga un trader.
                      </p>
                      <div className="inline-block px-6 py-3 bg-white/5 rounded-2xl text-white/40 text-sm font-bold border border-white/10">
                         Tu cuenta se quedó igual, tu competencia avanzó
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>

              {/* Bot Info Glass Bar */}
              <div className="absolute bottom-10 left-1/2 -translate-x-1/2 w-[90%] flex items-center justify-between p-6 bg-white/5 backdrop-blur-2xl rounded-[2rem] border border-white/10 z-30 shadow-2xl">
                <div className="flex items-center gap-5">
                  <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-brand to-brand-bright flex items-center justify-center shadow-[0_0_20px_rgba(168,85,247,0.4)]">
                    <img src="/logo-kopytrading.png" className="w-10 h-10 object-contain brightness-0 invert" alt="K" />
                  </div>
                  <div>
                    <div className="text-[10px] text-brand-light uppercase font-black tracking-widest mb-1">Algoritmo en Ejecución</div>
                    <div className="text-xl font-black text-white tracking-tight">LA AMETRALLADORA v2.1</div>
                  </div>
                </div>
                <div className="hidden sm:flex flex-col items-end">
                  <div className="text-[10px] text-white/40 uppercase font-black tracking-widest mb-1">Eficiencia Real</div>
                  <div className="text-xl font-black text-success flex items-center gap-2">
                    <span className="w-2 h-2 rounded-full bg-success animate-pulse" /> 94.2%
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Side Panels - Data Dynamics */}
          <div className="lg:col-span-4 flex flex-col gap-8">
            
            {/* Real-time Profit Card */}
            <div className="flex-1 glass-card border border-white/10 rounded-[3rem] p-8 relative overflow-hidden group bg-[#0a0a0c]">
               <div className="absolute -top-10 -right-10 w-40 h-40 bg-brand/5 blur-[50px] group-hover:bg-brand/10 transition-colors" />
               <h4 className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] mb-10">Profit Flotante USD</h4>
               <div className="relative">
                 <motion.div 
                   key={liveProfit}
                   initial={{ opacity: 0, y: 10 }}
                   animate={{ opacity: 1, y: 0 }}
                   className="text-6xl font-black text-white tracking-tighter mb-2"
                 >
                   ${liveProfit.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                 </motion.div>
                 <div className="flex items-center gap-2">
                   <span className="text-success font-black text-sm">+0.12% hoy</span>
                   <div className="w-full h-[1px] bg-white/10" />
                 </div>
               </div>

               {/* Waveform Chart (Dynamic) */}
               <div className="mt-12 flex items-end gap-1.5 h-32">
                 {history.map((h, i) => (
                   <motion.div 
                    key={i} 
                    initial={{ scaleY: 0 }}
                    animate={{ scaleY: 1 }}
                    className="flex-1 rounded-full bg-gradient-to-t from-brand/60 to-brand-bright/80 opacity-60 hover:opacity-100 transition-opacity" 
                    style={{ height: `${Math.max(15, (h.profit - 1200) * 0.5)}%` }} 
                   />
                 ))}
               </div>
            </div>

            {/* Risk Management Panel */}
            <div className="glass-card border border-white/10 rounded-[3rem] p-8 bg-[#0a0a0c] relative overflow-hidden">
                <div className="absolute top-0 right-0 p-8">
                  <span className="text-2xl animate-pulse">🛡️</span>
                </div>
                <h4 className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] mb-8">Escudo de Riesgo</h4>
                <div className="space-y-6">
                  <div className="flex justify-between items-end">
                    <span className="text-white/40 text-xs font-bold uppercase tracking-widest">Drawdown Actual</span>
                    <span className="text-2xl font-black text-white">0.42<span className="text-sm font-light text-white/40">%</span></span>
                  </div>
                  <div className="w-full h-2 bg-white/5 rounded-full overflow-hidden">
                    <motion.div 
                      animate={{ width: "42%" }}
                      className="h-full bg-gradient-to-r from-success to-brand shadow-[0_0_15px_rgba(168,85,247,0.5)]" 
                    />
                  </div>
                  <div className="flex items-center gap-3 bg-brand/5 border border-brand/10 p-4 rounded-2xl">
                    <div className="w-3 h-3 rounded-full bg-success animate-ping" />
                    <span className="text-[10px] text-brand-light font-black uppercase tracking-widest">Nivel de Riesgo: ÓPTIMO</span>
                  </div>
                </div>
            </div>

            {/* Live activity feed */}
            <div className="glass-card border border-white/10 rounded-[3rem] p-8">
                <h4 className="text-[10px] font-black text-white/30 uppercase tracking-[0.3em] mb-8">Monitor Interno</h4>
                <div className="space-y-6">
                  {[
                    { log: "Buscando patrón institucional...", time: "Ahora" },
                    { log: "Cierre de ciclo detectado: +450$", time: "hace 2m" },
                    { log: "Hedging de seguridad desactivado.", time: "hace 5m" },
                  ].map((item, i) => (
                    <div key={i} className="flex gap-4 items-start group">
                      <div className="w-1.5 h-1.5 rounded-full bg-brand-bright mt-1.5 group-hover:scale-150 transition-transform" />
                      <div className="flex-1">
                        <p className="text-xs text-white/80 font-medium leading-relaxed">{item.log}</p>
                        <p className="text-[9px] text-text-muted font-bold uppercase tracking-widest mt-1">{item.time}</p>
                      </div>
                    </div>
                  ))}
                </div>
            </div>

          </div>
        </div>
      </div>
    </section>
  );
};

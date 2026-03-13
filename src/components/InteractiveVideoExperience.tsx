
"use client";

import React, { useState, useEffect, memo } from 'react';
import Link from 'next/link';

interface DataPoint {
  time: string;
  profit: number;
}

const MiniProfitWidget = memo(({ profit, history }: { profit: number, history: DataPoint[] }) => {
  return (
    <div className="glass-card border border-white/20 rounded-xl p-2 bg-[#08080a] shadow-lg">
       <div className="flex justify-between items-center mb-0.5">
         <h4 className="text-[6px] font-black text-brand-light uppercase tracking-widest leading-none">Live Gold Profit</h4>
         <div className="text-[8px] font-bold text-success leading-none">+0.12%</div>
       </div>
       <div className="text-lg font-black text-white tracking-tighter mb-0.5">
         ${profit.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
       </div>
       <div className="flex items-end gap-0.5 h-4 opacity-30">
         {history.map((h, i) => (
           <div 
            key={i} 
            className="flex-1 rounded-t-[1px] bg-brand" 
            style={{ height: `${Math.max(10, (h.profit - 1200) * 0.8)}%` }} 
           />
         ))}
       </div>
    </div>
  );
});
MiniProfitWidget.displayName = "MiniProfitWidget";

export const InteractiveVideoExperience = () => {
  const [step, setStep] = useState<'intro' | 'choice' | 'result_buy' | 'result_wait'>('intro');
  const [liveProfit, setLiveProfit] = useState(1284.45);
  const [history, setHistory] = useState<DataPoint[]>([]);

  useEffect(() => {
    const interval = setInterval(() => {
      setLiveProfit(prev => prev + (Math.random() * 4 - 0.5));
    }, 3000);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    const newPoint = { time: new Date().toLocaleTimeString(), profit: liveProfit };
    setHistory(prev => [...prev.slice(-10), newPoint]);
  }, [liveProfit]);

  return (
    <section className="relative w-full bg-[#010101] py-0.5 sm:py-1 px-4 border-y border-white/5 overflow-hidden z-[45]">
      <div className="max-w-5xl mx-auto relative z-10">
        
        {/* TEXTO DE INTRODUCCIÓN - MÁXIMA COMPRESIÓN */}
        <div className="text-center mb-1 max-w-2xl mx-auto">
           <h2 className="text-xs sm:text-base font-black text-white mb-0 uppercase tracking-tighter italic">¿Preparado para ver la ejecución perfecta?</h2>
           <p className="text-white/30 text-[8px] sm:text-[9px] leading-none max-w-sm mx-auto">
             Observa cómo nuestros algoritmos ejecutan con precisión quirúrgica donde otros dudan.
           </p>
        </div>

        <div className="grid lg:grid-cols-12 gap-1 items-start">
          
          {/* SIMULADOR - ALTURA RECORTEADA Y BOTÓN FIJO */}
          <div className="lg:col-span-8">
            <div className="relative rounded-lg overflow-hidden border border-white/20 bg-black h-[130px] sm:h-[150px] shadow-2xl group pointer-events-auto">
              
              {/* VÍDEO REAL DE FONDO */}
              <div className={`absolute inset-0 transition-opacity duration-1000 ${step !== 'intro' ? 'opacity-40 grayscale-0' : 'opacity-10 grayscale'}`}>
                {step !== 'intro' && (
                   <iframe
                   src="https://drive.google.com/file/d/13zwGUwrmkxOYEKrOd3TVYSwd8xqa9-be/preview?autoplay=1&mute=1"
                   className="w-full h-full scale-[1.3] pointer-events-none"
                   allow="autoplay"
                 ></iframe>
                )}
                {step === 'intro' && (
                  <div className="w-full h-full bg-gradient-to-br from-brand/10 to-transparent flex items-center justify-center">
                    <span className="text-2xl filter blur-sm opacity-10">📈</span>
                  </div>
                )}
              </div>

              {/* Botón Central - SUPER SIMPLE CSS */}
              <div className="absolute inset-0 flex flex-col items-center justify-center p-2 z-[150] bg-black/50 pointer-events-auto">
                {step === 'intro' ? (
                  <div 
                    onClick={() => setStep('choice')}
                    className="cursor-pointer bg-brand hover:bg-brand-light text-white font-black text-[9px] sm:text-[11px] px-6 py-2.5 rounded-full border border-white/30 shadow-2xl transition-all active:scale-95 pointer-events-auto select-none"
                    style={{ cursor: 'pointer', zIndex: 999 }}
                  >
                    DESBLOQUEAR SIMULADOR
                  </div>
                ) : (
                  <div className="flex flex-col items-center gap-1.5 z-[120] relative w-full pointer-events-auto">
                    {step === 'choice' && (
                       <div className="flex gap-2 w-full max-w-[180px] pointer-events-auto">
                        <button 
                            onClick={() => setStep('result_buy')} 
                            className="flex-1 bg-success hover:bg-emerald-500 text-white font-black py-1.5 rounded-lg text-[9px] cursor-pointer shadow-lg shadow-success/20 pointer-events-auto"
                            style={{ cursor: 'pointer' }}
                        > COMPRAR </button>
                        <button 
                            onClick={() => setStep('result_wait')} 
                            className="flex-1 bg-white/10 hover:bg-white/20 text-white font-black py-1.5 rounded-lg text-[9px] cursor-pointer pointer-events-auto"
                            style={{ cursor: 'pointer' }}
                        > ESPERAR </button>
                       </div>
                    )}
                    {step.startsWith('result') && (
                      <div className="text-center pointer-events-auto">
                         <div className={`text-lg font-black ${step === 'result_buy' ? 'text-success' : 'text-white/60'}`}>
                           {step === 'result_buy' ? '+$125.40' : 'SIN SEÑAL'}
                         </div>
                         <button 
                            onClick={() => setStep('intro')} 
                            className="text-[7px] text-accent font-black uppercase tracking-widest mt-0.5 border-b border-accent/20 cursor-pointer pointer-events-auto"
                            style={{ cursor: 'pointer' }}
                         > REINICIAR </button>
                      </div>
                    )}
                  </div>
                )}
              </div>

              {/* Status Bar */}
              <div className="absolute bottom-1 inset-x-1 flex items-center justify-between p-1 px-2 bg-black/80 backdrop-blur-md rounded-lg border border-white/5 z-20">
                <span className="text-[6px] font-bold text-success animate-pulse uppercase tracking-widest leading-none">● LIVE EXECUTION</span>
                <span className="text-[6px] font-black text-white/20 tracking-widest uppercase italic leading-none">XAUUSD | HFT Mode</span>
              </div>
            </div>
          </div>

          {/* DERECHA - WIDGETS REDUCIDOS AL MÍNIMO */}
          <div className="lg:col-span-4 flex flex-col gap-1">
            <MiniProfitWidget profit={liveProfit} history={history} />
            <div className="glass-card border border-white/10 rounded-xl p-2 bg-black/40 shadow-xl">
                <div className="flex justify-between items-center mb-0.5">
                  <h4 className="text-[6px] font-black text-white/20 uppercase tracking-widest leading-none">Escudo de Riesgo</h4>
                  <div className="w-1 h-1 rounded-full bg-success" />
                </div>
                <div className="flex justify-between items-baseline">
                   <div className="text-[7px] text-white/40 font-bold uppercase leading-none">Drawdown</div>
                   <div className="text-base font-black text-white italic leading-none">0.42%</div>
                </div>
            </div>
          </div>

        </div>
      </div>
    </section>
  );
};

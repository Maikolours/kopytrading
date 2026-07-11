"use client";

import Image from "next/image";

// Estructura de datos manual para los testimonios visuales (Opción 1)
const TESTIMONIOS_VISUALES = [
    {
        id: "1",
        type: "image", // 'image' | 'video'
        src: "/images/testimonials/resultado_1.jpg",
        alt: "Resultado MAIKO HISTÓRICO 1",
        caption: "Resultados en Cuenta Demo",
    },
    {
        id: "2",
        type: "image",
        src: "/images/testimonials/resultado_2.jpg",
        alt: "Resultado MAIKO HISTÓRICO 2",
        caption: "Resultados en Cuenta Demo",
    },
    {
        id: "3",
        type: "video",
        src: "/images/testimonials/resultado_3.mp4",
        alt: "Vídeo Resultados",
        caption: "Resultados en Cuenta Demo",
    }
];

export function VisualTestimonials() {
    if (TESTIMONIOS_VISUALES.length === 0) return null;

    return (
        <div className="glass-card p-10 border border-white/10 mt-6">
            <h3 className="text-2xl font-black text-white uppercase italic flex items-center gap-4 mb-8">
                <span className="text-brand-light">📸</span>
                Resultados y Casos de Éxito
            </h3>
            
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {TESTIMONIOS_VISUALES.map((t) => (
                    <div key={t.id} className="relative group rounded-xl overflow-hidden border border-white/5 bg-black/40 aspect-square">
                        {t.type === 'image' ? (
                            <Image 
                                src={t.src} 
                                alt={t.alt}
                                fill
                                className="object-contain hover:scale-105 transition-transform duration-500"
                            />
                        ) : (
                            <video 
                                src={t.src}
                                autoPlay
                                loop
                                muted
                                playsInline
                                className="w-full h-full object-cover"
                            />
                        )}
                        {t.caption && (
                            <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/90 to-transparent p-4 pt-10">
                                <p className="text-xs font-bold text-white uppercase tracking-widest text-center">
                                    {t.caption}
                                </p>
                            </div>
                        )}
                    </div>
                ))}
            </div>
            
            <div className="mt-8 pt-6 border-t border-white/5">
                <p className="text-center text-[10px] text-text-muted uppercase tracking-widest opacity-60">
                    * Los resultados visuales mostrados corresponden a operativas en cuentas demo/simulación para fines demostrativos. Rendimientos pasados no garantizan rendimientos futuros.
                </p>
            </div>
        </div>
    );
}

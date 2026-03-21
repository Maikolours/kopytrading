
"use client";

import { useState } from "react";
import { Button } from "@/components/ui/Button";

interface VideoResult {
  id: string;
  title: string;
  description: string;
  videoUrl: string;
  date: string;
  botName: string;
  profit?: string;
}

const RESULTS_VIDEOS: VideoResult[] = [
  {
    id: "1",
    title: "Operativa Real XAUUSD - Rescate Cent",
    description: "Funcionamiento del sistema de rescate (Martingala Controlada) en cuenta real Cent. Verificación de lotajes y anclaje de seguridad.",
    videoUrl: "https://drive.google.com/file/d/1jbQWw8cuLm6gjqoH1TADWPqTNZ2199_u/preview",
    date: "20 Mar 2026",
    botName: "Ametralladora Evolution",
    profit: "+55.80 USC"
  },
  {
    id: "2",
    title: "BTCUSD Storm Rider - Optimización",
    description: "Análisis de entradas en Bitcoin tras la optimización del Momentum y filtros de volatilidad.",
    videoUrl: "https://drive.google.com/file/d/1aIu398AEt4_HBW_ULl0UvGmK70eCV3b8/preview",
    date: "19 Mar 2026",
    botName: "BTC Storm Rider",
    profit: "+12.20 USD"
  },
];

const RESULTS_PHOTOS: any[] = [];

export function ResultsGallery() {
  const [activeVideo, setActiveVideo] = useState<VideoResult | null>(null);

  return (
    <section className="py-12 md:py-24 relative overflow-hidden bg-black">
      {/* Luces de fondo */}
      <div className="absolute top-0 left-1/4 w-[500px] h-[500px] bg-brand/10 blur-[120px] rounded-full pointer-events-none" />
      <div className="absolute bottom-0 right-1/4 w-[400px] h-[400px] bg-accent/5 blur-[100px] rounded-full pointer-events-none" />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 mb-16">
          {RESULTS_VIDEOS.map((video) => (
            <div 
              key={video.id} 
              className="glass-card border border-white/10 rounded-2xl overflow-hidden group hover:border-brand/40 transition-all flex flex-col"
            >
              <div className="aspect-video relative bg-surface overflow-hidden">
                <iframe
                  src={video.videoUrl}
                  className="w-full h-full"
                  allow="autoplay"
                  title={video.title}
                ></iframe>
                <div className="absolute inset-0 bg-black/20 pointer-events-none group-hover:bg-transparent transition-colors" />
              </div>

              <div className="p-6 flex-1 flex flex-col">
                <div className="flex justify-between items-start mb-4">
                  <div>
                    <span className="text-[10px] font-bold text-brand-light uppercase tracking-tighter bg-brand/10 px-2 py-0.5 rounded-md">
                      {video.botName}
                    </span>
                    <h3 className="text-white font-bold text-lg mt-2 group-hover:text-brand-light transition-colors">
                      {video.title}
                    </h3>
                  </div>
                  {video.profit && (
                    <div className="text-success font-bold text-sm bg-success/10 px-3 py-1 rounded-lg border border-success/20">
                      {video.profit}
                    </div>
                  )}
                </div>
                
                <p className="text-text-muted text-sm line-clamp-2 mb-6 font-light">
                  {video.description}
                </p>

                <div className="mt-auto flex items-center justify-between pt-4 border-t border-white/5">
                  <span className="text-xs text-text-muted/60">{video.date}</span>
                  <Button variant="glass" size="sm" className="h-8 text-[11px] px-4">
                    Detalles del Bot
                  </Button>
                </div>
              </div>
            </div>
          ))}

          {/* Card Placeholder para invitar a subir más */}
          <div className="border-2 border-dashed border-white/5 rounded-2xl p-8 flex flex-col items-center justify-center text-center bg-white/[0.02] hover:bg-white/[0.04] transition-colors cursor-pointer group">
            <div className="w-16 h-16 rounded-full bg-white/5 flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
              <span className="text-3xl text-white/20">🎥</span>
            </div>
            <h4 className="text-white/40 font-bold mb-2">Próximos Resultados</h4>
            <p className="text-text-muted/40 text-xs">Añadiremos más grabaciones semanales de nuestras pruebas.</p>
          </div>
        </div>

        {/* Sección de Fotos/Capturas */}
        <div className="mt-20">
          <div className="flex flex-col items-center mb-12">
            <h2 className="text-3xl font-bold text-white mb-4">Capturas de Resultados</h2>
            <div className="h-1 w-20 bg-brand rounded-full" />
          </div>
          
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
            {RESULTS_PHOTOS.map((photo) => (
              <div 
                key={photo.id}
                className="aspect-square relative rounded-xl overflow-hidden border border-white/10 group cursor-zoom-in"
              >
                <img 
                  src={photo.url} 
                  alt={photo.title}
                  className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity flex flex-col justify-end p-4">
                  <p className="text-white text-xs font-bold">{photo.title}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

      </div>
    </section>
  );
}

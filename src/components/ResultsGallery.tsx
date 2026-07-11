
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

const RESULTS_VIDEOS: VideoResult[] = [];

const RESULTS_PHOTOS = [
  {
    id: "photo-1",
    title: "Resultados en Cuenta Demo - MAIKO Histórico",
    url: "/images/testimonials/resultado_1.jpg"
  },
  {
    id: "photo-2",
    title: "Resultados en Cuenta Demo - Consistencia",
    url: "/images/testimonials/resultado_2.jpg"
  }
];

export function ResultsGallery() {
  const [activeVideo, setActiveVideo] = useState<VideoResult | null>(null);

  return (
    <section className="py-12 md:py-20 relative overflow-hidden bg-black">
      {/* Luces de fondo */}
      <div className="absolute top-0 left-1/4 w-[500px] h-[500px] bg-brand/10 blur-[120px] rounded-full pointer-events-none" />
      <div className="absolute bottom-0 right-1/4 w-[400px] h-[400px] bg-accent/5 blur-[100px] rounded-full pointer-events-none" />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        
        {/* Sección de Vídeos - Solo se muestra si hay videos cargados */}
        {RESULTS_VIDEOS.length > 0 && (
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
          </div>
        )}

        {/* Sección de Fotos/Capturas */}
        <div>
          <div className="flex flex-col items-center mb-12">
            <h2 className="text-3xl font-bold text-white mb-4">Capturas de Resultados (Demo)</h2>
            <div className="h-1 w-20 bg-brand rounded-full mb-8" />
            
            <a 
              href="https://t.me/Kpytrading" 
              target="_blank" 
              rel="noopener noreferrer"
              className="bg-[#24A1DE] hover:bg-[#1d82b5] text-white px-6 py-3 rounded-lg font-bold text-sm uppercase tracking-wide transition-colors flex items-center gap-2"
            >
              <span>✈️</span> ¿Quieres aparecer en el muro? Envía tu captura por Telegram
            </a>
          </div>
          
          {RESULTS_PHOTOS.length > 0 ? (
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-3 gap-6">
              {RESULTS_PHOTOS.map((photo) => (
                <div 
                  key={photo.id}
                  className="aspect-video relative rounded-2xl overflow-hidden border border-white/10 bg-surface/30 backdrop-blur-md group cursor-pointer hover:border-brand/40 transition-all shadow-xl"
                >
                  <img 
                    src={photo.url} 
                    alt={photo.title}
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/40 to-transparent opacity-80 group-hover:opacity-90 transition-opacity flex flex-col justify-end p-4">
                    <p className="text-white text-xs font-bold tracking-tight">{photo.title}</p>
                    <span className="text-[10px] text-brand-light font-medium uppercase tracking-wider mt-1">✓ Verificado</span>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="flex justify-center">
              <div className="border-2 border-dashed border-white/5 rounded-2xl p-8 flex flex-col items-center justify-center text-center bg-white/[0.02] hover:bg-white/[0.04] transition-colors cursor-pointer group max-w-md w-full">
                <div className="w-16 h-16 rounded-full bg-white/5 flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
                  <span className="text-3xl text-white/20">📸</span>
                </div>
                <h4 className="text-white/40 font-bold mb-2">Capturas de Operaciones</h4>
                <p className="text-text-muted/40 text-xs">Las capturas se actualizarán automáticamente.</p>
              </div>
            </div>
          )}
        </div>

      </div>
    </section>
  );
}


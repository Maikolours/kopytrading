
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
    title: "Operativa Real XAUUSD - La Ametralladora",
    description: "Sesión de trading en vivo mostrando el funcionamiento del algoritmo en el Oro con el sistema de blindaje activado.",
    videoUrl: "https://drive.google.com/file/d/13zwGUwrmkxOYEKrOd3TVYSwd8xqa9-be/preview",
    date: "12 Mar 2026",
    botName: "Ametralladora v3.60",
    profit: "+125.40 USD"
  },
  // Aquí se pueden añadir más vídeos en el futuro
];

export function ResultsGallery() {
  const [activeVideo, setActiveVideo] = useState<VideoResult | null>(null);

  return (
    <section className="py-12 md:py-24 relative overflow-hidden bg-black">
      {/* Luces de fondo */}
      <div className="absolute top-0 left-1/4 w-[500px] h-[500px] bg-brand/10 blur-[120px] rounded-full pointer-events-none" />
      <div className="absolute bottom-0 right-1/4 w-[400px] h-[400px] bg-accent/5 blur-[100px] rounded-full pointer-events-none" />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {RESULTS_VIDEOS.map((video) => (
            <div 
              key={video.id} 
              className="glass-card border border-white/10 rounded-2xl overflow-hidden group hover:border-brand/40 transition-all flex flex-col"
            >
              <div className="aspect-video relative bg-surface overflow-hidden">
                {/* Iframe de Google Drive */}
                <iframe
                  src={video.videoUrl}
                  className="w-full h-full"
                  allow="autoplay"
                  title={video.title}
                ></iframe>
                
                {/* Overlay sutil para indicar que es un video */}
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

      </div>
    </section>
  );
}

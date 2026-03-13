
import { ResultsGallery } from "@/components/ResultsGallery";
import { Metadata } from "next";

export const metadata: Metadata = {
  title: "Resultados Reales | KopyTrading",
  description: "Vídeos de operativa real con nuestros bots de trading en vivo.",
};

export default function ResultadosPage() {
  return (
    <div className="pt-20">
      <ResultsGallery />
      
      {/* Sección de llamada a la acción inferior */}
      <section className="py-20 px-4 border-t border-white/5 bg-gradient-to-b from-transparent to-brand/10">
        <div className="max-w-4xl mx-auto text-center">
          <h2 className="text-3xl font-bold text-white mb-6">¿Quieres estos mismos resultados?</h2>
          <p className="text-text-muted mb-10 text-lg">
            Empieza hoy mismo con una prueba gratuita de 30 días y comprueba el potencial de nuestros algoritmos en tu propia cuenta.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <a href="/bots" className="bg-brand hover:bg-brand-light text-white font-bold py-4 px-10 rounded-xl transition-all shadow-[0_0_30px_rgba(139,92,246,0.3)]">
              🚀 Ver Catálogo de Bots
            </a>
            <a href="/como-funciona" className="bg-white/5 hover:bg-white/10 text-white font-bold py-4 px-10 rounded-xl transition-all border border-white/10">
              Aprender más
            </a>
          </div>
        </div>
      </section>
    </div>
  );
}

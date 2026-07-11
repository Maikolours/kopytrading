import { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";

export const metadata: Metadata = {
    title: "Resultados de Clientes | KopyTrading",
    description: "Descubre los beneficios reales que están obteniendo nuestros clientes utilizando la tecnología institucional de KopyTrading en MetaTrader 5.",
};

const PROFIT_IMAGES = [
    { src: "/uploads/bots/profit_1.jpg", alt: "Profit $340", name: "Usuario verificado", date: "Hace 2 días" },
    { src: "/uploads/bots/profit_2.jpg", alt: "Profit $890", name: "Usuario verificado", date: "Hace 1 semana" },
    { src: "/uploads/bots/profit_3.jpg", alt: "Profit $1,250", name: "Usuario verificado", date: "Hace 2 semanas" },
];

export default function ResultadosPage() {
    return (
        <div className="min-h-screen pt-24 pb-12 px-4 sm:px-6 lg:px-8 relative overflow-hidden">
            {/* Background Aesthetic Blur */}
            <div className="absolute top-0 right-0 w-[600px] h-[600px] bg-success/5 blur-[120px] rounded-full pointer-events-none -mr-40 -mt-20 opacity-40" />
            <div className="absolute bottom-0 left-0 w-[400px] h-[400px] bg-brand/5 blur-[100px] rounded-full pointer-events-none -ml-20 -mb-20 opacity-20" />

            <div className="max-w-7xl mx-auto relative z-10 text-center">
                <div className="inline-flex items-center gap-3 px-4 py-2 rounded-full border border-success/30 bg-success/10 text-success text-[10px] font-black uppercase tracking-widest mb-8">
                    <span className="w-2 h-2 rounded-full bg-success animate-pulse"></span>
                    Muro de Beneficios
                </div>

                <h1 className="text-5xl md:text-7xl font-black text-white uppercase italic tracking-tighter mb-6">
                    Resultados <span className="text-transparent bg-clip-text bg-gradient-to-r from-success to-emerald-400">Reales</span>
                </h1>
                <p className="text-text-muted text-lg md:text-xl max-w-2xl mx-auto mb-16 font-light">
                    Explora las capturas de pantalla y los beneficios que nuestra comunidad de traders comparte diariamente usando nuestra tecnología en MetaTrader 5.
                </p>

                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
                    {/* Placeholder Grid */}
                    {[1, 2, 3, 4, 5, 6].map((i) => (
                        <div key={i} className="glass-card p-4 border border-white/10 relative overflow-hidden group hover:border-success/30 transition-all">
                            <div className="absolute top-0 right-0 p-4 z-20">
                                <span className="bg-success text-black text-[10px] font-black px-3 py-1 rounded-full uppercase tracking-widest shadow-lg shadow-success/20">
                                    Verificado
                                </span>
                            </div>
                            
                            <div className="aspect-[4/3] bg-black/50 rounded-xl mb-4 relative overflow-hidden border border-white/5 flex flex-col items-center justify-center">
                                {/* Cuando Sakura tenga imágenes reales, usaremos la etiqueta <Image src="..." /> */}
                                <div className="text-success text-5xl mb-2">📈</div>
                                <div className="text-white font-black text-2xl italic tracking-tighter">+ $ 34{i}.50</div>
                                <div className="text-[10px] text-text-muted uppercase tracking-widest mt-2">Beneficio Semanal</div>
                            </div>

                            <div className="flex items-center justify-between px-2">
                                <div className="flex items-center gap-2">
                                    <div className="w-6 h-6 rounded-full bg-white/10 flex items-center justify-center text-[10px] text-text-muted font-bold">
                                        U
                                    </div>
                                    <span className="text-xs text-text-muted font-medium">Trader Anónimo</span>
                                </div>
                                <span className="text-[10px] text-text-muted/50 uppercase tracking-widest">Maiko Gold Demo</span>
                            </div>
                        </div>
                    ))}
                </div>

                <div className="mt-20 p-10 glass-card border border-brand/20 bg-brand/5 max-w-3xl mx-auto rounded-3xl">
                    <h3 className="text-2xl font-black text-white uppercase italic tracking-tighter mb-4">¿Quieres aparecer en el Muro?</h3>
                    <p className="text-text-muted mb-8">
                        Si estás obteniendo beneficios con nuestros algoritmos, envíanos una captura de pantalla de tu MetaTrader 5 a nuestro Telegram oficial.
                    </p>
                    <a href="https://t.me/Kpytrading" target="_blank" rel="noopener noreferrer" className="inline-block bg-[#24A1DE] hover:bg-[#1a85b9] text-white font-bold py-4 px-8 rounded-full uppercase tracking-widest text-xs transition-colors shadow-lg shadow-[#24A1DE]/20">
                        Enviar Captura por Telegram
                    </a>
                </div>
            </div>
        </div>
    );
}

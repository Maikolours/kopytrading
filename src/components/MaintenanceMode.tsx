"use client";

import { useEffect, useState } from "react";

export function MaintenanceMode() {
    const [isMaintenance, setIsMaintenance] = useState(false);

    useEffect(() => {
        // Solo activamos si la variable de entorno es 'true'
        if (process.env.NEXT_PUBLIC_MAINTENANCE_MODE === "true") {
            setIsMaintenance(true);
            document.body.style.overflow = "hidden";
        } else {
            setIsMaintenance(false);
            document.body.style.overflow = "auto";
        }
    }, []);

    if (!isMaintenance) return null;

    return (
        <div className="fixed inset-0 z-[9999] bg-black flex items-center justify-center p-6 text-center">
            <div className="max-w-md w-full animate-in fade-in zoom-in duration-500">
                <div className="relative mb-12 inline-block">
                    <div className="absolute -inset-4 bg-accent/20 blur-3xl rounded-full animate-pulse"></div>
                    <img
                        src="/logo-kopytrading.png"
                        alt="Logo"
                        className="w-32 h-32 object-cover rounded-[2.5rem] relative border border-white/10 shadow-2xl"
                    />
                </div>

                <h1 className="text-4xl font-extrabold tracking-tighter sm:text-5xl mb-6">
                    Ajustes <span className="bg-clip-text text-transparent bg-gradient-to-r from-accent to-white">Finales</span>
                </h1>

                <p className="text-slate-400 text-lg mb-10 leading-relaxed">
                    Estamos cargando los últimos bots y configurando el sistema de pagos.
                    Vuelve en unos minutos para descubrir la mejor experiencia de trading.
                </p>

                <div className="flex flex-col items-center gap-4">
                    <div className="flex items-center gap-2 text-accent bg-accent/10 px-4 py-2 rounded-full border border-accent/20">
                        <span className="w-2 h-2 bg-accent rounded-full animate-ping"></span>
                        <span className="text-xs font-bold uppercase tracking-widest leading-none">Trabajando para ti</span>
                    </div>

                    <div className="text-[10px] text-slate-600 uppercase tracking-widest mt-8 font-medium">
                        © {new Date().getFullYear()} KopyTrading Technical Team
                    </div>
                </div>
            </div>
        </div>
    );
}

"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { AlertTriangle, X } from "lucide-react";

export default function RiskBanner() {
    const [isVisible, setIsVisible] = useState(false);

    useEffect(() => {
        const hasAcceptedRisk = localStorage.getItem("kopytrading_risk_accepted");
        if (!hasAcceptedRisk) {
            setIsVisible(true);
        }
    }, []);

    const handleAccept = () => {
        localStorage.setItem("kopytrading_risk_accepted", "true");
        setIsVisible(false);
    };

    if (!isVisible) return null;

    return (
        <div className="fixed bottom-0 left-0 right-0 z-[100] bg-black/95 backdrop-blur-md border-t border-danger/30 p-4 shadow-[0_-10px_40px_rgba(220,38,38,0.15)]">
            <div className="max-w-7xl mx-auto flex flex-col sm:flex-row items-center gap-4 justify-between">
                <div className="flex items-start gap-3 flex-1">
                    <AlertTriangle className="w-6 h-6 text-danger shrink-0 mt-0.5" />
                    <div className="text-sm text-text-muted">
                        <strong className="text-white uppercase tracking-wider text-xs block mb-1">Aviso de Alto Riesgo</strong>
                        El trading con CFDs, Forex y criptomonedas conlleva un alto riesgo de pérdida rápida de capital debido al apalancamiento. 
                        KopyTrading es exclusivamente un proveedor de software tecnológico. NO ofrecemos asesoramiento financiero ni recomendaciones de inversión.
                        <Link href="/legal/riesgo" className="text-brand-light hover:text-white underline ml-2 whitespace-nowrap transition-colors">
                            Leer aviso legal completo
                        </Link>
                    </div>
                </div>
                
                <div className="flex items-center gap-3 w-full sm:w-auto shrink-0">
                    <button 
                        onClick={handleAccept}
                        className="w-full sm:w-auto px-6 py-2.5 bg-danger hover:bg-danger/80 text-white text-sm font-bold rounded-xl transition-all shadow-lg shadow-danger/20"
                    >
                        Entendido
                    </button>
                    <button 
                        onClick={() => setIsVisible(false)}
                        className="p-2.5 hover:bg-white/10 rounded-xl text-text-muted hover:text-white transition-colors"
                        aria-label="Cerrar temporalmente"
                    >
                        <X className="w-5 h-5" />
                    </button>
                </div>
            </div>
        </div>
    );
}

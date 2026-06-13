"use client";

import React, { useState } from "react";
import { Button } from "@/components/ui/Button";

export function NewsletterForm() {
    const [email, setEmail] = useState("");
    const [status, setStatus] = useState<"idle" | "loading" | "success" | "error">("idle");

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!email) return;

        setStatus("loading");
        
        // Simular llamada de red a la API (2 segundos de feedback de premium loaders)
        setTimeout(() => {
            setStatus("success");
            setEmail("");
        }, 1500);
    };

    if (status === "success") {
        return (
            <div className="glass-card border border-brand-light/20 p-8 rounded-[2rem] max-w-xl mx-auto text-center bg-brand/5 animate-fade-in">
                <span className="text-4xl block mb-3">✉️✨</span>
                <h3 className="text-white font-black text-xl mb-2 uppercase tracking-tighter italic">¡Suscripción Completada!</h3>
                <p className="text-text-muted text-sm max-w-sm mx-auto font-medium">
                    Te has unido a nuestra lista de distribución. Te notificaremos con análisis exclusivos y actualizaciones del mercado.
                </p>
            </div>
        );
    }

    return (
        <div className="glass-card border border-white/10 p-8 sm:p-10 rounded-[2rem] max-w-xl mx-auto bg-surface/30 backdrop-blur-xl shadow-2xl relative overflow-hidden">
            <div className="absolute top-0 left-0 w-full h-[2px] bg-gradient-to-r from-transparent via-brand-light to-transparent opacity-80" />
            
            <h3 className="text-white font-black text-lg sm:text-xl text-center uppercase tracking-tight italic mb-3">
                Boletín de <span className="text-brand-light">Trading Algorítmico</span>
            </h3>
            <p className="text-text-muted text-xs sm:text-sm text-center mb-6 max-w-md mx-auto font-light leading-relaxed">
                Recibe en tu correo las últimas guías institucionales, presets óptimos de MetaTrader 5 y análisis del mercado.
            </p>

            <form onSubmit={handleSubmit} className="flex flex-col sm:flex-row gap-3">
                <input
                    type="email"
                    required
                    placeholder="Tu correo electrónico..."
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    disabled={status === "loading"}
                    className="flex-1 bg-black/40 border border-white/10 rounded-full px-5 py-3 text-sm text-white placeholder-text-muted/60 focus:outline-none focus:border-brand/60 focus:ring-1 focus:ring-brand/60 transition-all disabled:opacity-50"
                />
                <Button 
                    type="submit" 
                    variant="glass" 
                    size="sm"
                    loading={status === "loading"}
                    className="sm:w-auto h-11 text-xs uppercase tracking-widest font-black shrink-0 px-6"
                >
                    Suscribirse
                </Button>
            </form>
        </div>
    );
}

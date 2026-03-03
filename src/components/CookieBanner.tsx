"use client";
import { useState, useEffect } from "react";
import Link from "next/link";

export default function CookieBanner() {
    const [visible, setVisible] = useState(false);

    useEffect(() => {
        const accepted = localStorage.getItem("kopytrade_cookies_accepted");
        if (!accepted) setVisible(true);
    }, []);

    function accept() {
        localStorage.setItem("kopytrade_cookies_accepted", "true");
        setVisible(false);
    }

    function reject() {
        localStorage.setItem("kopytrade_cookies_accepted", "essential_only");
        setVisible(false);
    }

    if (!visible) return null;

    return (
        <div className="fixed bottom-0 left-0 right-0 z-[1000] px-4 pb-4 pt-2 bg-bg-dark/95 backdrop-blur-lg border-t border-white/10 shadow-[0_-10px_40px_rgba(0,0,0,0.6)]">
            <div className="max-w-6xl mx-auto flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                <div className="flex items-start gap-3">
                    <span className="text-2xl flex-shrink-0 mt-0.5">🍪</span>
                    <div>
                        <p className="text-sm font-semibold text-white mb-0.5">Este sitio utiliza cookies</p>
                        <p className="text-xs text-text-muted leading-relaxed max-w-2xl">
                            Usamos cookies esenciales para el funcionamiento del sitio (sesión, seguridad) y opcionales para mejorar la experiencia (análisis anónimo).
                            Consulta nuestra {" "}
                            <Link href="/legal/cookies" className="text-brand-light hover:underline">Política de Cookies</Link>
                            {" "}y{" "}
                            <Link href="/legal/privacidad" className="text-brand-light hover:underline">Política de Privacidad</Link>.{" "}
                            <span className="text-danger/70">⚠️ Recuerda: el trading conlleva alto riesgo de pérdida de capital.</span>
                        </p>
                    </div>
                </div>
                <div className="flex items-center gap-2 flex-shrink-0">
                    <button
                        onClick={reject}
                        className="px-4 py-2 text-xs text-text-muted border border-white/20 rounded-full hover:border-white/40 hover:text-white transition-all"
                    >
                        Solo esenciales
                    </button>
                    <button
                        onClick={accept}
                        className="px-5 py-2 text-xs font-semibold text-white bg-brand rounded-full hover:bg-brand-light hover:shadow-[0_0_20px_rgba(196,181,253,0.5)] transition-all"
                    >
                        ✓ Aceptar todas
                    </button>
                </div>
            </div>
        </div>
    );
}

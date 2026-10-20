"use client";

import React, { useState, useEffect } from "react";
import { Gift, Bot, ShieldCheck, ArrowRight, CheckCircle2 } from "lucide-react";
import Link from "next/link";

interface FreeTrialClaimCardProps {
  userEmail?: string;
  onTrialClaimed?: () => void;
  onNextLesson?: () => void;
}

export default function FreeTrialClaimCard({ userEmail, onTrialClaimed, onNextLesson }: FreeTrialClaimCardProps) {
  const [email, setEmail] = useState(userEmail || "");
  const [isSubmitted, setIsSubmitted] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState("");

  useEffect(() => {
    if (userEmail && !email) {
      setEmail(userEmail);
    }
    try {
      const trialClaimed = localStorage.getItem("kopytrading_trial_claimed");
      if (trialClaimed === "true") {
        setIsSubmitted(true);
      }
    } catch (e) {
      console.error(e);
    }
  }, [userEmail]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) return;

    setIsLoading(true);
    setErrorMsg("");

    try {
      const res = await fetch("/api/trial", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, botId: "cmn9hf8yc0000vhbcq9hbxk0j" })
      });

      const data = await res.json();

      if (res.ok && data.success) {
        setIsSubmitted(true);
        try {
          localStorage.setItem("kopytrading_user_email", email);
          localStorage.setItem("kopytrading_user_role", "VIP");
          localStorage.setItem("kopytrading_trial_claimed", "true");
        } catch (err) {
          console.error(err);
        }
        onTrialClaimed?.();
      } else {
        if (data.error && data.error.includes("ya tienes")) {
          setIsSubmitted(true);
          try {
            localStorage.setItem("kopytrading_user_role", "VIP");
            localStorage.setItem("kopytrading_trial_claimed", "true");
          } catch (err) {
            console.error(err);
          }
          onTrialClaimed?.();
        } else {
          setErrorMsg(data.error || "No se pudo activar la prueba. Inténtalo de nuevo.");
        }
      }
    } catch (err) {
      console.error(err);
      setErrorMsg("Error de conexión. Inténtalo más tarde.");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="w-full rounded-3xl bg-gradient-to-br from-[#0F172A] via-[#1E1B4B] to-[#0F172A] border border-amber-400/40 p-6 md:p-8 shadow-2xl relative overflow-hidden">
      {/* Glow Effects */}
      <div className="absolute top-0 right-0 w-80 h-80 bg-amber-500/10 blur-3xl pointer-events-none rounded-full" />
      <div className="absolute bottom-0 left-0 w-80 h-80 bg-purple-500/10 blur-3xl pointer-events-none rounded-full" />

      <div className="relative z-10 max-w-xl mx-auto text-center space-y-6">
        {/* Gift Icon Badge */}
        <div className="w-16 h-16 rounded-2xl bg-amber-500/20 border border-amber-400/40 flex items-center justify-center mx-auto text-amber-400 shadow-xl shadow-amber-500/10 text-3xl">
          🎁
        </div>

        <div>
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs font-mono font-bold tracking-wider uppercase mb-3">
            <ShieldCheck className="w-3.5 h-3.5" />
            RECOMPENSA DE GRADUACIÓN DESBLOQUEADA
          </div>
          <h2 className="text-2xl md:text-3xl font-extrabold text-white tracking-tight">
            1 Mes Gratis: MAIKO PRO GOLD CLIENT DEMO FIX
          </h2>
          <p className="text-slate-300 text-sm md:text-base mt-2 leading-relaxed">
            ¡Enhorabuena! Has demostrado comprender la gestión de riesgo y la operativa en M5. Tu cupón de regalo del 100% de descuento (<strong>ACADEMIA100</strong>) está listo para activar tu licencia de 30 días en cuenta DEMO de MT5 sin coste alguno.
          </p>
        </div>

        {isSubmitted ? (
          <div className="p-6 rounded-2xl bg-emerald-950/60 border border-emerald-500/60 text-emerald-300 space-y-4 animate-fade-in text-center max-w-lg mx-auto">
            <div className="flex items-center justify-center gap-2 font-bold text-lg text-emerald-300">
              <CheckCircle2 className="w-6 h-6 text-emerald-400" />
              ¡Licencia Demo Activada con Éxito!
            </div>
            <p className="text-xs md:text-sm text-slate-300 leading-relaxed">
              Hemos registrado y activado tu licencia de 30 días para <strong className="text-white">{email}</strong>. Ya puedes ingresar a tu panel para descargar el bot (.EX5) y el manual o continuar con las siguientes lecciones.
            </p>
            <div className="pt-2 flex flex-col sm:flex-row items-center justify-center gap-3">
              <Link
                href="/dashboard"
                className="w-full sm:w-auto px-5 py-3 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 font-extrabold text-xs transition-all shadow-lg shadow-amber-500/20 uppercase tracking-wider flex items-center justify-center gap-2"
              >
                <Bot className="w-4 h-4" />
                Ir a Mi Panel a Descargar el Bot →
              </Link>
              {onNextLesson && (
                <button
                  type="button"
                  onClick={onNextLesson}
                  className="w-full sm:w-auto px-5 py-3 rounded-xl bg-slate-900 hover:bg-slate-800 border border-slate-700 text-white font-bold text-xs transition-all flex items-center justify-center gap-2"
                >
                  <span>Continuar Siguiente Lección</span>
                  <ArrowRight className="w-4 h-4 text-amber-400" />
                </button>
              )}
            </div>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-4 text-left max-w-md mx-auto">
            <div>
              <label className="block text-xs font-semibold text-slate-300 mb-1.5">
                Tu correo para activar tu licencia de 30 días:
              </label>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="ejemplo@correo.com"
                className="w-full px-4 py-3 rounded-xl bg-slate-950/80 border border-slate-700 text-white placeholder-slate-500 focus:outline-none focus:border-amber-400 text-sm"
              />
            </div>

            {errorMsg && (
              <p className="text-xs text-red-400 bg-red-950/40 p-2.5 rounded-lg border border-red-500/40">
                {errorMsg}
              </p>
            )}

            <button
              type="submit"
              disabled={isLoading}
              className="w-full py-4 rounded-xl bg-gradient-to-r from-amber-500 to-yellow-400 hover:from-amber-400 hover:to-yellow-300 text-slate-950 font-black text-sm tracking-wide flex items-center justify-center gap-2 shadow-xl shadow-amber-500/25 transition-all transform hover:-translate-y-0.5 disabled:opacity-50 uppercase"
            >
              <Gift className="w-5 h-5 text-slate-950" />
              {isLoading ? "Activando tu licencia..." : "Clica Aquí para Activar tu Mes Gratis"}
            </button>

            <div className="pt-2 text-center space-y-1">
              <p className="text-[11px] font-mono text-emerald-400 font-semibold">
                ✓ Cupón 100% OFF (ACADEMIA100) aplicado automáticamente · Sin tarjeta
              </p>
              <p className="text-[11px] text-slate-500">
                Operativa completa en cuenta DEMO de MT5 durante 30 días.
              </p>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}

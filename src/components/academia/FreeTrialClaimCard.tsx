"use client";

import React, { useState } from "react";
import { Gift, Bot, ShieldCheck, ArrowRight, CheckCircle2, Copy, Check } from "lucide-react";
import Link from "next/link";

interface FreeTrialClaimCardProps {
  userEmail?: string;
  onTrialClaimed?: () => void;
}

export default function FreeTrialClaimCard({ userEmail, onTrialClaimed }: FreeTrialClaimCardProps) {
  const [email, setEmail] = useState(userEmail || "");
  const [isSubmitted, setIsSubmitted] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState("");
  const [copied, setCopied] = useState(false);

  const handleCopyCoupon = () => {
    navigator.clipboard.writeText("ACADEMIA100");
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

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
        // If already active or error, still grant VIP access if trial was existing
        if (data.error && data.error.includes("ya tienes")) {
          setIsSubmitted(true);
          localStorage.setItem("kopytrading_user_role", "VIP");
          localStorage.setItem("kopytrading_trial_claimed", "true");
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
            ¡Enhorabuena! Has demostrado comprender la gestión de riesgo y la operativa en M5. Tienes a tu disposición un cupón del 100% de descuento para utilizar en cuenta DEMO de MT5 sin coste alguno durante 30 días.
          </p>
        </div>

        {/* Cupón Card */}
        {!isSubmitted ? (
          <div className="p-4 rounded-2xl bg-slate-950/80 border border-amber-400/30 flex flex-col sm:flex-row items-center justify-between gap-3 max-w-md mx-auto text-left">
            <div>
              <span className="text-[10px] font-mono text-slate-400 uppercase tracking-widest block">Código Promocional 100% OFF</span>
              <span className="text-xl font-black font-mono text-amber-400 tracking-wider">ACADEMIA100</span>
              <span className="text-[11px] text-emerald-400 block mt-0.5">✓ Se aplica automáticamente con el botón</span>
            </div>
            <button
              type="button"
              onClick={handleCopyCoupon}
              className="px-3.5 py-1.5 rounded-lg bg-amber-500/20 hover:bg-amber-500/30 border border-amber-400/40 text-amber-300 text-xs font-bold flex items-center gap-1.5 transition-all shrink-0"
            >
              {copied ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
              {copied ? "¡Copiado!" : "Copiar"}
            </button>
          </div>
        ) : (
          <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs font-mono font-bold mx-auto">
            <CheckCircle2 className="w-4 h-4 text-emerald-400" />
            Cupón ACADEMIA100 canjeado y aplicado automáticamente
          </div>
        )}

        {isSubmitted ? (
          <div className="p-5 rounded-2xl bg-emerald-950/60 border border-emerald-500/60 text-emerald-300 space-y-3 animate-fade-in">
            <div className="flex items-center justify-center gap-2 font-bold text-lg">
              <CheckCircle2 className="w-6 h-6 text-emerald-400" />
              ¡Licencia Demo Activada con Éxito!
            </div>
            <p className="text-xs md:text-sm text-slate-300">
              Hemos registrado y activado tu licencia para <strong className="text-white">{email}</strong>. Ya puedes ingresar a tu panel para descargar el bot (.EX5) y el manual institucional en PDF.
            </p>
            <div className="pt-2 flex flex-col sm:flex-row items-center justify-center gap-3">
              <Link
                href="/dashboard"
                className="px-4 py-2.5 rounded-xl bg-amber-500 text-slate-950 font-bold text-xs hover:bg-amber-400 transition-colors shadow-md shadow-amber-500/20 uppercase tracking-wider"
              >
                Ir a Mi Panel a Descargar el Bot →
              </Link>
              <Link
                href="/bots"
                className="text-xs font-bold text-slate-400 hover:text-white underline"
              >
                Ver Catálogo Oficial
              </Link>
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
              className="w-full py-3.5 rounded-xl bg-gradient-to-r from-amber-500 to-yellow-400 hover:from-amber-400 hover:to-yellow-300 text-slate-950 font-extrabold text-sm tracking-wide flex items-center justify-center gap-2 shadow-lg shadow-amber-500/20 transition-all transform hover:-translate-y-0.5 disabled:opacity-50 uppercase"
            >
              <Bot className="w-4 h-4" />
              {isLoading ? "Activando licencia..." : "Activar 1 Mes Gratis Ahora"}
            </button>

            <div className="pt-2 text-center space-y-1">
              <p className="text-[11px] font-mono text-slate-400">
                100% gratuito con cupón · Sin tarjeta requerida · Operativa en cuenta DEMO
              </p>
              <p className="text-[11px] text-slate-500">
                ¿Prefieres no esperar? La demo también está disponible directamente en la web por <Link href="/checkout/cmn9hf8yc0000vhbcq9hbxk0j" className="text-amber-400 underline font-bold">1$</Link>.
              </p>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}

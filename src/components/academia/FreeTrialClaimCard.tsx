"use client";

import React, { useState } from "react";
import { Gift, Bot, ShieldCheck, ArrowRight, CheckCircle2 } from "lucide-react";
import Link from "next/link";

interface FreeTrialClaimCardProps {
  userEmail?: string;
}

export default function FreeTrialClaimCard({ userEmail }: FreeTrialClaimCardProps) {
  const [email, setEmail] = useState(userEmail || "");
  const [isSubmitted, setIsSubmitted] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (email) {
      setIsSubmitted(true);
    }
  };

  return (
    <div className="w-full rounded-3xl bg-gradient-to-br from-[#0F172A] via-[#1E1B4B] to-[#0F172A] border border-amber-400/40 p-6 md:p-8 shadow-2xl relative overflow-hidden">
      {/* Glow Effects */}
      <div className="absolute top-0 right-0 w-80 h-80 bg-amber-500/10 blur-3xl pointer-events-none rounded-full" />
      <div className="absolute bottom-0 left-0 w-80 h-80 bg-purple-500/10 blur-3xl pointer-events-none rounded-full" />

      <div className="relative z-10 max-w-xl mx-auto text-center space-y-6">
        {/* Gift Icon Badge */}
        <div className="w-16 h-16 rounded-2xl bg-amber-500/20 border border-amber-400/40 flex items-center justify-center mx-auto text-amber-400 shadow-xl shadow-amber-500/10">
          <Gift className="w-8 h-8" />
        </div>

        <div>
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs font-mono font-bold tracking-wider uppercase mb-3">
            <ShieldCheck className="w-3.5 h-3.5" />
            RECOMPENSA DE GRADUACIÓN DESBLOQUEADA
          </div>
          <h2 className="text-2xl md:text-3xl font-extrabold text-white tracking-tight">
            Prueba Gratis el Bot Maiko Bayesian
          </h2>
          <p className="text-slate-300 text-sm md:text-base mt-2 leading-relaxed">
            Has demostrado entender los conceptos clave de la operativa algorítmica y la gestión de riesgo. Como recompensa, te regalamos un acceso de prueba sin costo en cuenta demo para ver actuar al bot en tiempo real.
          </p>
        </div>

        {isSubmitted ? (
          <div className="p-5 rounded-2xl bg-emerald-950/60 border border-emerald-500/60 text-emerald-300 space-y-3 animate-fade-in">
            <div className="flex items-center justify-center gap-2 font-bold text-lg">
              <CheckCircle2 className="w-6 h-6 text-emerald-400" />
              ¡Prueba Gratuita Solicitada!
            </div>
            <p className="text-xs md:text-sm text-slate-300">
              Hemos registrado tu correo <strong className="text-white">{email}</strong>. Revisa tu bandeja de entrada donde recibirás las credenciales y el instalador para tu cuenta de prueba.
            </p>
            <div className="pt-2">
              <Link
                href="/bots"
                className="inline-flex items-center gap-2 text-xs font-bold text-amber-400 hover:text-amber-300 underline"
              >
                Ver catálogo de bots disponibles <ArrowRight className="w-3.5 h-3.5" />
              </Link>
            </div>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-4 text-left max-w-md mx-auto">
            <div>
              <label className="block text-xs font-semibold text-slate-300 mb-1.5">
                Tu correo electrónico para enviarte la licencia de prueba:
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

            <button
              type="submit"
              className="w-full py-3.5 rounded-xl bg-gradient-to-r from-amber-500 to-yellow-400 hover:from-amber-400 hover:to-yellow-300 text-slate-950 font-extrabold text-sm tracking-wide flex items-center justify-center gap-2 shadow-lg shadow-amber-500/20 transition-all transform hover:-translate-y-0.5"
            >
              <Bot className="w-4 h-4" />
              Reclamar mi Prueba Gratuita de Bot
            </button>
            <p className="text-[11px] font-mono text-slate-400 text-center">
              100% gratuito · Sin tarjeta de crédito · Entorno de prueba seguro
            </p>
          </form>
        )}
      </div>
    </div>
  );
}

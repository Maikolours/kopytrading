"use client";

import React, { useState, useEffect } from "react";
import { Mail, GraduationCap, ArrowRight, ShieldCheck, Gift } from "lucide-react";

interface EmailGateModalProps {
  isOpen: boolean;
  onSuccess: (email: string) => void;
}

export default function EmailGateModal({ isOpen, onSuccess }: EmailGateModalProps) {
  const [email, setEmail] = useState("");

  useEffect(() => {
    try {
      const saved = localStorage.getItem("kopytrading_user_email");
      if (saved) setEmail(saved);
    } catch (e) {
      console.error(e);
    }
  }, []);

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (email && email.trim()) {
      try {
        localStorage.setItem("kopytrading_user_email", email.trim());
      } catch (err) {
        console.error(err);
      }
      onSuccess(email.trim());
    }
  };

  return (
    <div className="fixed inset-0 z-[120] flex items-center justify-center p-4 bg-black/85 backdrop-blur-md animate-fade-in">
      <div className="w-full max-w-md bg-[#0F1422] border border-amber-400/40 rounded-3xl p-6 md:p-8 text-center shadow-2xl relative overflow-hidden animate-slide-up">
        {/* Glow accent */}
        <div className="absolute top-0 right-0 w-48 h-48 bg-amber-500/10 blur-3xl pointer-events-none rounded-full" />

        {/* Icon Badge */}
        <div className="w-16 h-16 rounded-2xl bg-amber-500/15 border border-amber-400/30 flex items-center justify-center mx-auto text-amber-400 mb-5 shadow-xl shadow-amber-500/10">
          <GraduationCap className="w-8 h-8" />
        </div>

        {/* Header */}
        <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-amber-400/10 border border-amber-400/30 text-amber-400 text-[11px] font-mono font-bold uppercase mb-3">
          <ShieldCheck className="w-3.5 h-3.5" />
          ACCESO Y REGISTRO DE ALUMNO
        </div>

        <h2 className="text-2xl font-extrabold text-white tracking-tight mb-2">
          Ingresa tu correo para comenzar
        </h2>

        <p className="text-xs md:text-sm text-slate-300 mb-4 leading-relaxed">
          Guarda tu progreso de lecciones, desbloquea las evaluaciones y obtén al graduarte un <strong className="text-amber-400">Cupón de 100% de descuento</strong> para 1 mes gratis de <strong>MAIKO PRO GOLD CLIENT DEMO FIX</strong>.
        </p>

        <div className="mb-6 p-3 rounded-xl bg-amber-500/10 border border-amber-400/20 text-left flex items-start gap-2.5">
          <Gift className="w-4 h-4 text-amber-400 shrink-0 mt-0.5" />
          <p className="text-[11px] text-amber-300/90 leading-relaxed">
            ¿No deseas realizar el curso? Puedes adquirir la versión Demo directamente en la tienda por 1$.
          </p>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="space-y-4 text-left">
          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-1.5">
              Tu Email de contacto:
            </label>
            <div className="relative">
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="tu@email.com"
                className="w-full pl-10 pr-4 py-3 rounded-xl bg-slate-950 border border-slate-700 text-white placeholder-slate-500 focus:outline-none focus:border-amber-400 text-sm"
              />
              <Mail className="w-4 h-4 text-slate-400 absolute left-3.5 top-3.5" />
            </div>
          </div>

          <button
            type="submit"
            className="w-full py-3.5 rounded-xl bg-gradient-to-r from-amber-500 to-yellow-400 hover:from-amber-400 hover:to-yellow-300 text-slate-950 font-extrabold text-sm tracking-wide flex items-center justify-center gap-2 shadow-lg shadow-amber-500/20 transition-all transform hover:-translate-y-0.5"
          >
            Entrar a la Academia Ahora
            <ArrowRight className="w-4 h-4" />
          </button>

          <p className="text-[10px] font-mono text-slate-400 text-center">
            100% gratuito · Cero spam · Puedes darte de baja cuando quieras
          </p>
        </form>
      </div>
    </div>
  );
}

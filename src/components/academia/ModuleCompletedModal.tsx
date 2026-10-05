"use client";

import React from "react";
import { Check, Sparkles, Trophy, ArrowRight } from "lucide-react";
import { TOTAL_LESSONS_COUNT } from "@/lib/academiaData";

interface ModuleCompletedModalProps {
  isOpen: boolean;
  moduleTitle: string;
  completedLessonsCount: number;
  onClose: () => void;
}

export default function ModuleCompletedModal({
  isOpen,
  moduleTitle,
  completedLessonsCount,
  onClose
}: ModuleCompletedModalProps) {
  if (!isOpen) return null;

  const progressPercent = Math.min(100, Math.round((completedLessonsCount / TOTAL_LESSONS_COUNT) * 100));

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md animate-fade-in">
      <div className="w-full max-w-md bg-[#0F1420] border border-amber-500/40 rounded-3xl p-6 md:p-8 text-center shadow-2xl relative overflow-hidden animate-slide-up">
        {/* Glow effect */}
        <div className="absolute -top-24 -left-24 w-48 h-48 bg-amber-500/20 blur-3xl pointer-events-none rounded-full" />
        <div className="absolute -bottom-24 -right-24 w-48 h-48 bg-emerald-500/20 blur-3xl pointer-events-none rounded-full" />

        {/* Big Check Circle */}
        <div className="w-20 h-20 rounded-full bg-slate-900 border-2 border-amber-400 flex items-center justify-center mx-auto mb-6 shadow-xl shadow-amber-400/20">
          <div className="w-14 h-14 rounded-full bg-gradient-to-tr from-amber-500 to-yellow-300 flex items-center justify-center text-slate-950">
            <Check className="w-8 h-8 stroke-[3]" />
          </div>
        </div>

        {/* Subheader Badge */}
        <div className="text-[11px] font-mono font-bold tracking-widest text-amber-400 uppercase mb-2 flex items-center justify-center gap-1.5">
          <Sparkles className="w-3.5 h-3.5" />
          MÓDULO COMPLETADO
        </div>

        {/* Main Title */}
        <h2 className="text-2xl md:text-3xl font-extrabold text-white mb-2 tracking-tight">
          ¡Módulo completado!
        </h2>

        <p className="text-slate-300 text-sm mb-6">
          Terminaste <span className="text-amber-400 font-semibold">"{moduleTitle}"</span>. Vas por muy buen camino.
        </p>

        {/* Progress Bar Card */}
        <div className="p-4 rounded-2xl bg-slate-900/90 border border-slate-800 text-left mb-6">
          <div className="flex items-center justify-between text-xs text-slate-300 font-medium mb-2">
            <span>Tu progreso en la Academia</span>
            <span className="font-bold text-amber-400 text-sm">{progressPercent}%</span>
          </div>

          <div className="w-full h-2 rounded-full bg-slate-800 overflow-hidden mb-2">
            <div
              className="h-full bg-gradient-to-r from-amber-500 to-yellow-400 rounded-full transition-all duration-700"
              style={{ width: `${progressPercent}%` }}
            />
          </div>

          <div className="text-[11px] font-mono text-slate-500 text-center">
            {completedLessonsCount} de {TOTAL_LESSONS_COUNT} lecciones
          </div>
        </div>

        {/* Action Button */}
        <button
          onClick={onClose}
          className="w-full py-3.5 rounded-xl bg-gradient-to-r from-amber-500 to-yellow-400 hover:from-amber-400 hover:to-yellow-300 text-slate-950 font-extrabold text-sm tracking-wide flex items-center justify-center gap-2 shadow-lg shadow-amber-500/25 transition-all transform hover:-translate-y-0.5"
        >
          Continuar
          <ArrowRight className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
}

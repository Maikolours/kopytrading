"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { 
  GraduationCap, 
  Play, 
  CheckCircle2, 
  Lock, 
  Crown, 
  Sparkles, 
  ArrowRight,
  ShieldAlert,
  BookOpen,
  Award
} from "lucide-react";
import { ACADEMIA_MODULES, TOTAL_LESSONS_COUNT } from "@/lib/academiaData";
import { Navbar } from "@/components/Navbar";

export default function AcademiaDashboardPage() {
  const [completedLessonIds, setCompletedLessonIds] = useState<string[]>([]);

  useEffect(() => {
    try {
      const saved = localStorage.getItem("kopytrading_academia_completed");
      if (saved) {
        setCompletedLessonIds(JSON.parse(saved));
      }
    } catch (e) {
      console.error(e);
    }
  }, []);

  const totalCompleted = completedLessonIds.length;
  const progressPercent = Math.min(100, Math.round((totalCompleted / TOTAL_LESSONS_COUNT) * 100));

  // Find next uncompleted lesson
  let firstUncompletedLessonId = "m00-l01";
  for (const mod of ACADEMIA_MODULES) {
    for (const l of mod.lessons) {
      if (!completedLessonIds.includes(l.id)) {
        firstUncompletedLessonId = l.id;
        break;
      }
    }
  }

  return (
    <div className="min-h-screen bg-[#070A10] text-white selection:bg-amber-400 selection:text-slate-950">
      <Navbar />

      <main className="max-w-6xl mx-auto px-4 py-8 md:py-12 space-y-10">
        {/* Header Hero Banner */}
        <div className="relative rounded-3xl bg-gradient-to-r from-slate-900 via-[#111625] to-slate-900 border border-slate-800 p-6 md:p-10 overflow-hidden shadow-2xl">
          {/* Subtle ambient glows */}
          <div className="absolute top-0 right-0 w-96 h-96 bg-amber-500/10 blur-3xl pointer-events-none rounded-full" />
          <div className="absolute bottom-0 left-0 w-96 h-96 bg-blue-500/10 blur-3xl pointer-events-none rounded-full" />

          <div className="relative z-10 max-w-3xl space-y-4">
            <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full bg-amber-400/10 border border-amber-400/30 text-amber-400 text-xs font-mono font-bold uppercase tracking-wider">
              <GraduationCap className="w-4 h-4" />
              KOPYTRADING ACADEMY
            </div>

            <h1 className="text-3xl md:text-5xl font-extrabold tracking-tight text-white leading-tight">
              Aprende Trading Algorítmico <br />
              <span className="bg-gradient-to-r from-amber-400 via-yellow-300 to-amber-500 bg-clip-text text-transparent">
                Sin Magia ni Falsas Promesas
              </span>
            </h1>

            <p className="text-slate-300 text-sm md:text-base leading-relaxed">
              La academia diseñada para personas que quieren entender cómo funcionan los bots de trading desde la realidad: gestión de riesgo estricta, paciencia matemática y configuración responsable.
            </p>

            {/* Quick Action Button & Stats */}
            <div className="pt-4 flex flex-wrap items-center gap-4">
              <Link
                href={`/academia/leccion/${firstUncompletedLessonId}`}
                className="px-6 py-3.5 rounded-xl bg-gradient-to-r from-amber-500 to-yellow-400 hover:from-amber-400 hover:to-yellow-300 text-slate-950 font-extrabold text-sm tracking-wide flex items-center gap-2 shadow-lg shadow-amber-500/20 transition-all transform hover:-translate-y-0.5"
              >
                <Play className="w-4 h-4 fill-current" />
                {totalCompleted > 0 ? "Continuar Academia" : "Empezar Módulo 00"}
              </Link>

              <div className="flex items-center gap-3 px-4 py-2.5 rounded-xl bg-slate-950/60 border border-slate-800 text-xs font-mono text-slate-300">
                <BookOpen className="w-4 h-4 text-amber-400" />
                <span>{totalCompleted} / {TOTAL_LESSONS_COUNT} Lecciones completadas ({progressPercent}%)</span>
              </div>
            </div>
          </div>
        </div>

        {/* Global Progress Bar */}
        <div className="p-6 rounded-2xl bg-slate-900/60 border border-slate-800 space-y-3">
          <div className="flex items-center justify-between text-sm">
            <span className="font-bold text-slate-200">Tu Progreso General</span>
            <span className="font-mono font-bold text-amber-400">{progressPercent}% completado</span>
          </div>
          <div className="w-full h-3 rounded-full bg-slate-950 overflow-hidden p-0.5 border border-slate-800">
            <div
              className="h-full bg-gradient-to-r from-amber-500 to-yellow-400 rounded-full transition-all duration-700"
              style={{ width: `${progressPercent}%` }}
            />
          </div>
        </div>

        {/* Modules List */}
        <div className="space-y-6">
          <h2 className="text-xl md:text-2xl font-bold text-white tracking-tight flex items-center gap-2">
            <Award className="w-6 h-6 text-amber-400" />
            Plan de Estudios
          </h2>

          <div className="grid grid-cols-1 gap-6">
            {ACADEMIA_MODULES.map((mod) => {
              const completedInMod = mod.lessons.filter(l => completedLessonIds.includes(l.id)).length;
              const isModComplete = completedInMod === mod.lessons.length;

              return (
                <div
                  key={mod.id}
                  className={`rounded-2xl border transition-all ${
                    mod.isVip
                      ? "bg-[#0E121E]/60 border-amber-500/30"
                      : "bg-[#0E121E] border-slate-800"
                  } p-6 space-y-4`}
                >
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-slate-800/80 pb-4">
                    <div>
                      <div className="text-xs font-mono font-bold text-amber-400 uppercase tracking-widest flex items-center gap-2">
                        <span>MÓDULO {mod.moduleNumberStr}</span>
                        {mod.isVip && (
                          <span className="px-2 py-0.5 rounded bg-amber-400/10 border border-amber-400/30 text-amber-400 text-[10px]">
                            CONTENIDO VIP
                          </span>
                        )}
                      </div>
                      <h3 className="text-lg md:text-xl font-extrabold text-white mt-1">
                        {mod.title}
                      </h3>
                      <p className="text-xs md:text-sm text-slate-400 mt-0.5">
                        {mod.description}
                      </p>
                    </div>

                    <div className="text-xs font-mono text-slate-400 shrink-0 bg-slate-900 px-3 py-1.5 rounded-lg border border-slate-800">
                      {completedInMod} / {mod.lessons.length} Lecciones
                    </div>
                  </div>

                  {/* Lessons inside grid */}
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                    {mod.lessons.map((lesson) => {
                      const isDone = completedLessonIds.includes(lesson.id);

                      return (
                        <Link
                          key={lesson.id}
                          href={`/academia/leccion/${lesson.id}`}
                          className={`p-4 rounded-xl border transition-all flex items-center justify-between group ${
                            isDone
                              ? "bg-slate-900/40 border-emerald-500/40 text-emerald-300 hover:bg-slate-900/80"
                              : "bg-slate-950/60 border-slate-800 text-slate-200 hover:border-amber-400/40 hover:bg-slate-900/60"
                          }`}
                        >
                          <div className="flex items-center gap-3 truncate">
                            {isDone ? (
                              <CheckCircle2 className="w-5 h-5 text-emerald-400 shrink-0" />
                            ) : lesson.isVip ? (
                              <Crown className="w-5 h-5 text-amber-400 shrink-0" />
                            ) : (
                              <div className="w-5 h-5 rounded-full border border-slate-600 flex items-center justify-center text-[10px] font-mono text-slate-400 shrink-0">
                                {lesson.lessonNumber}
                              </div>
                            )}
                            <div className="truncate">
                              <div className="text-sm font-semibold text-white group-hover:text-amber-400 transition-colors truncate">
                                {lesson.title}
                              </div>
                              <div className="text-[11px] font-mono text-slate-400">
                                ⏱️ {lesson.durationMinutes} min
                              </div>
                            </div>
                          </div>

                          <ArrowRight className="w-4 h-4 text-slate-500 group-hover:text-amber-400 transition-colors shrink-0" />
                        </Link>
                      );
                    })}
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Risk Disclaimer */}
        <div className="p-5 rounded-2xl bg-slate-950 border border-slate-800/80 text-xs text-slate-400 space-y-2">
          <div className="flex items-center gap-2 font-bold text-slate-300">
            <ShieldAlert className="w-4 h-4 text-amber-400" />
            Aviso de Riesgo y Responsabilidad Educativa
          </div>
          <p className="leading-relaxed">
            El trading algorítmico y la operativa en mercados financieros implican riesgo de pérdida de capital. Los contenidos presentados en Kopytrading Academy son de carácter puramente informativo y educativo. Ninguna información constituye asesoramiento financiero ni garantiza rendimientos futuros. Medir resultados en meses y mantener una gestión de riesgo estricta es responsabilidad de cada usuario.
          </p>
        </div>
      </main>
    </div>
  );
}

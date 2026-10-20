"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
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
import EmailGateModal from "@/components/academia/EmailGateModal";

export default function AcademiaDashboardPage() {
  const router = useRouter();
  const [completedLessonIds, setCompletedLessonIds] = useState<string[]>([]);
  const [userEmail, setUserEmail] = useState<string | null>(null);
  const [showEmailGate, setShowEmailGate] = useState(false);

  useEffect(() => {
    try {
      let savedCompleted: string[] = [];
      const rawCompleted = localStorage.getItem("kopytrading_academia_completed");
      if (rawCompleted) {
        savedCompleted = JSON.parse(rawCompleted);
      }
      const savedEmail = localStorage.getItem("kopytrading_user_email");
      if (savedEmail) {
        setUserEmail(savedEmail);
      }

      const isAdminOrUser = 
        savedEmail?.toLowerCase() === "viajaconsakura@gmail.com" ||
        savedEmail?.toLowerCase() === "rakerusan@yahoo.es" ||
        localStorage.getItem("kopytrading_is_admin") === "true";

      if (isAdminOrUser && savedCompleted.length < 9) {
        const base9 = [
          "m00-l01", "m00-l02",
          "m01-l01", "m01-l02", "m01-l03", "m01-l04",
          "m02-l01", "m02-l02", "m02-l03"
        ];
        const merged = Array.from(new Set([...savedCompleted, ...base9]));
        savedCompleted = merged;
        localStorage.setItem("kopytrading_academia_completed", JSON.stringify(merged));
        localStorage.setItem("kopytrading_trial_claimed", "true");
        if (savedEmail?.toLowerCase() === "viajaconsakura@gmail.com") {
          localStorage.setItem("kopytrading_user_role", "ADMIN");
          localStorage.setItem("kopytrading_is_admin", "true");
        }
      }

      setCompletedLessonIds(savedCompleted);
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
    if (firstUncompletedLessonId !== "m00-l01") break;
  }

  const handleStartAcademy = (e: React.MouseEvent) => {
    e.preventDefault();
    if (!userEmail) {
      setShowEmailGate(true);
    } else {
      router.push(`/academia/leccion/${firstUncompletedLessonId}`);
    }
  };

  const handleEmailSubmitted = (email: string) => {
    setUserEmail(email);
    setShowEmailGate(false);

    let currentCompleted = completedLessonIds;
    if (
      email.toLowerCase() === "viajaconsakura@gmail.com" ||
      email.toLowerCase() === "rakerusan@yahoo.es"
    ) {
      const base9 = [
        "m00-l01", "m00-l02",
        "m01-l01", "m01-l02", "m01-l03", "m01-l04",
        "m02-l01", "m02-l02", "m02-l03"
      ];
      const merged = Array.from(new Set([...currentCompleted, ...base9]));
      currentCompleted = merged;
      setCompletedLessonIds(merged);
      localStorage.setItem("kopytrading_academia_completed", JSON.stringify(merged));
      localStorage.setItem("kopytrading_trial_claimed", "true");
      if (email.toLowerCase() === "viajaconsakura@gmail.com") {
        localStorage.setItem("kopytrading_user_role", "ADMIN");
        localStorage.setItem("kopytrading_is_admin", "true");
      }
    }

    let nextId = "m00-l01";
    for (const mod of ACADEMIA_MODULES) {
      for (const l of mod.lessons) {
        if (!currentCompleted.includes(l.id)) {
          nextId = l.id;
          break;
        }
      }
      if (nextId !== "m00-l01") break;
    }

    router.push(`/academia/leccion/${nextId}`);
  };

  return (
    <div className="min-h-screen bg-[#070A10] text-white selection:bg-amber-400 selection:text-slate-950">
      <Navbar />

      <main className="max-w-6xl mx-auto px-4 pt-24 pb-12 space-y-10">
        {/* Header Hero Banner */}
        <div className="relative rounded-3xl bg-gradient-to-r from-slate-900 via-[#111625] to-slate-900 border border-slate-800 p-6 md:p-10 overflow-hidden shadow-2xl">
          {/* Ambient glows */}
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

            {/* NOTA DESTACADA: CONSEGUIR DEMO GRATIS SUPERANDO LA FORMACIÓN O PAGANDO 1€ */}
            <div className="p-4 rounded-2xl bg-gradient-to-r from-amber-500/15 via-yellow-500/10 to-amber-500/15 border border-amber-400/40 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 text-left shadow-lg">
              <div className="flex items-start gap-3">
                <span className="text-2xl sm:text-3xl shrink-0 mt-0.5">🎁</span>
                <div className="space-y-1">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="text-[10px] font-mono font-black uppercase tracking-wider text-amber-300 bg-amber-400/20 px-2 py-0.5 rounded border border-amber-400/40">
                      Cupón 100% Gratuito
                    </span>
                    <span className="text-xs font-black text-white">¿Quieres conseguir la Licencia Demo gratis?</span>
                  </div>
                  <p className="text-xs text-slate-200 font-light leading-relaxed">
                    Si quieres conseguir la demo gratis, <strong>completa los módulos formativos de la academia y supera las evaluaciones prácticas</strong> para desbloquear tu cupón exclusivo del 100% de descuento. Si prefieres no hacer el curso y empezar ya, puedes adquirir la Demo directamente por <strong className="text-amber-400 font-bold">solo 1€</strong>.
                  </p>
                </div>
              </div>
              <Link 
                href="/checkout/cmn9hf8yc0000vhbcq9hbxk0j"
                className="shrink-0 px-3.5 py-2 rounded-xl bg-white/10 hover:bg-white/20 border border-white/20 text-white font-bold text-[10px] uppercase tracking-wider whitespace-nowrap transition-all self-stretch sm:self-auto text-center"
              >
                Saltar curso · 1€ →
              </Link>
            </div>

            {/* Quick Action Button & Stats */}
            <div className="pt-4 flex flex-wrap items-center gap-4">
              <button
                onClick={handleStartAcademy}
                className="px-6 py-3.5 rounded-xl bg-gradient-to-r from-amber-500 to-yellow-400 hover:from-amber-400 hover:to-yellow-300 text-slate-950 font-extrabold text-sm tracking-wide flex items-center gap-2 shadow-lg shadow-amber-500/20 transition-all transform hover:-translate-y-0.5 cursor-pointer"
              >
                <Play className="w-4 h-4 fill-current" />
                {totalCompleted > 0 ? "Continuar Academia" : "Empezar Módulo 01"}
              </button>

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

        {/* Banner Recompensa de Graduación: Cupón 100% Demo */}
        <div className="relative rounded-2xl bg-gradient-to-r from-amber-500/10 via-yellow-500/10 to-amber-500/10 border border-amber-400/40 p-6 md:p-8 overflow-hidden shadow-xl">
          <div className="flex flex-col md:flex-row items-center justify-between gap-6 relative z-10">
            <div className="flex items-start gap-4">
              <div className="w-12 h-12 rounded-xl bg-amber-500/20 border border-amber-400/40 flex items-center justify-center text-amber-400 shrink-0 text-2xl">
                🎁
              </div>
              <div className="space-y-1">
                <div className="flex items-center gap-2">
                  <span className="text-[10px] font-mono font-bold uppercase tracking-widest text-amber-400 bg-amber-400/10 px-2.5 py-0.5 rounded-full border border-amber-400/30">
                    Recompensa de Graduación
                  </span>
                  <span className="text-[10px] font-bold uppercase text-emerald-400">Cupón 100% OFF</span>
                </div>
                <h3 className="text-lg md:text-xl font-black text-white">
                  Desbloquea 1 Mes Gratis de MAIKO PRO GOLD CLIENT DEMO FIX
                </h3>
                <p className="text-xs md:text-sm text-slate-300 max-w-2xl leading-relaxed">
                  Completa todas las lecciones y supera los cuestionarios para desbloquear tu código de descuento del 100% para activar el bot en cuenta DEMO de MT5 (en gráfico M5).
                </p>
                <p className="text-[11px] text-amber-300/90 pt-1">
                  ¿Prefieres no realizar la formación? Puedes conseguir la Demo directamente en la web por <strong className="text-white">solo 1$</strong>.
                </p>
              </div>
            </div>

            <div className="shrink-0 w-full md:w-auto flex flex-col sm:flex-row md:flex-col gap-2">
              <Link
                href="/checkout/cmn9hf8yc0000vhbcq9hbxk0j"
                className="px-5 py-3 rounded-xl bg-white/10 hover:bg-white/20 border border-white/20 text-white font-bold text-xs uppercase tracking-wider text-center transition-all hover:scale-105"
              >
                Comprar Demo por 1$ →
              </Link>
            </div>
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
                            RESERVADO VIP
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
                      const isNextUp = lesson.id === firstUncompletedLessonId;

                      return (
                        <Link
                          key={lesson.id}
                          href={`/academia/leccion/${lesson.id}`}
                          className={`relative p-4 rounded-xl border transition-all flex items-center justify-between group ${
                            isDone
                              ? "bg-slate-900/40 border-emerald-500/40 text-emerald-300 hover:bg-slate-900/80"
                              : isNextUp
                              ? "bg-amber-500/10 border-amber-400 ring-2 ring-amber-400/50 text-white hover:bg-amber-500/20 shadow-lg shadow-amber-500/10"
                              : "bg-slate-950/60 border-slate-800 text-slate-200 hover:border-amber-400/40 hover:bg-slate-900/60"
                          }`}
                        >
                          {isNextUp && !isDone && (
                            <span className="absolute -top-2.5 right-4 px-2.5 py-0.5 rounded-full bg-amber-400 text-slate-950 text-[10px] font-black tracking-wider uppercase shadow-md animate-pulse">
                              {totalCompleted > 0 ? "👉 CONTINUAR AQUÍ" : "👉 EMPEZAR AQUÍ"}
                            </span>
                          )}

                          <div className="flex items-center gap-3 truncate">
                            {isDone ? (
                              <CheckCircle2 className="w-5 h-5 text-emerald-400 shrink-0" />
                            ) : lesson.isVip ? (
                              <Crown className="w-5 h-5 text-amber-400 shrink-0" />
                            ) : (
                              <div className={`w-5 h-5 rounded-full border flex items-center justify-center text-[10px] font-mono shrink-0 ${
                                isNextUp ? "border-amber-400 bg-amber-400 text-slate-950 font-bold" : "border-slate-600 text-slate-400"
                              }`}>
                                {lesson.lessonNumber}
                              </div>
                            )}
                            <div className="truncate">
                              <div className={`text-sm font-semibold transition-colors truncate ${
                                isNextUp ? "text-amber-300 group-hover:text-amber-200 font-bold" : "text-white group-hover:text-amber-400"
                              }`}>
                                {lesson.title}
                              </div>
                              <div className="text-[11px] font-mono text-slate-400">
                                ⏱️ {lesson.durationMinutes} min
                              </div>
                            </div>
                          </div>

                          <ArrowRight className={`w-4 h-4 transition-colors shrink-0 ${
                            isNextUp ? "text-amber-400 group-hover:translate-x-1" : "text-slate-500 group-hover:text-amber-400"
                          }`} />
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

      {/* Email Gate Modal */}
      <EmailGateModal
        isOpen={showEmailGate}
        onSuccess={handleEmailSubmitted}
      />
    </div>
  );
}

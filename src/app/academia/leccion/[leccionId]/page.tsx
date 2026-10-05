"use client";

import React, { useState, useEffect } from "react";
import { useParams, useRouter } from "next/navigation";
import Link from "next/link";
import { 
  ArrowLeft, 
  CheckCircle2, 
  Lock, 
  Crown, 
  Clock, 
  BookOpen, 
  ShieldAlert,
  ChevronRight,
  Menu,
  X,
  AlertCircle
} from "lucide-react";
import { getLessonById, ACADEMIA_MODULES } from "@/lib/academiaData";
import ProgressSidebar from "@/components/academia/ProgressSidebar";
import InteractiveQuiz from "@/components/academia/InteractiveQuiz";
import LessonTextPage from "@/components/academia/LessonTextPage";
import ModuleCompletedModal from "@/components/academia/ModuleCompletedModal";
import FreeTrialClaimCard from "@/components/academia/FreeTrialClaimCard";
import EmailGateModal from "@/components/academia/EmailGateModal";

export default function LessonPlayerPage() {
  const params = useParams();
  const router = useRouter();
  const lessonId = params?.leccionId as string;

  const [completedLessonIds, setCompletedLessonIds] = useState<string[]>([]);
  const [showModuleModal, setShowModuleModal] = useState(false);
  const [completedModuleName, setCompletedModuleName] = useState("");
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [userRole, setUserRole] = useState<string>("USER");
  const [userEmail, setUserEmail] = useState<string | null>(null);
  const [showEmailGate, setShowEmailGate] = useState(false);
  const [isQuizPassed, setIsQuizPassed] = useState(false);

  useEffect(() => {
    try {
      const savedCompleted = localStorage.getItem("kopytrading_academia_completed");
      if (savedCompleted) {
        const parsed = JSON.parse(savedCompleted);
        setCompletedLessonIds(parsed);
      }
      const savedEmail = localStorage.getItem("kopytrading_user_email");
      if (savedEmail) {
        setUserEmail(savedEmail);
      } else {
        setShowEmailGate(true);
      }
      const savedRole = localStorage.getItem("kopytrading_user_role");
      const trialClaimed = localStorage.getItem("kopytrading_trial_claimed");
      if (savedRole === "VIP" || trialClaimed === "true") {
        setUserRole("VIP");
      }
    } catch (e) {
      console.error(e);
    }
  }, []);

  const lessonData = getLessonById(lessonId);

  useEffect(() => {
    if (lessonData?.lesson) {
      const isComp = completedLessonIds.includes(lessonData.lesson.id);
      if (!lessonData.lesson.quiz || isComp) {
        setIsQuizPassed(true);
      } else {
        setIsQuizPassed(false);
      }
    }
  }, [lessonData, completedLessonIds]);

  if (!lessonData) {
    return (
      <div className="min-h-screen bg-[#070A10] text-white flex flex-col items-center justify-center p-6 text-center pt-24">
        <h1 className="text-2xl font-bold mb-4">Lección no encontrada</h1>
        <Link
          href="/academia"
          className="px-5 py-2.5 rounded-xl bg-amber-500 text-slate-950 font-bold text-sm"
        >
          Volver a la Academia
        </Link>
      </div>
    );
  }

  const { lesson, module: currentModule } = lessonData;
  const isLessonCompleted = completedLessonIds.includes(lesson.id);
  const canAdvance = !lesson.quiz || isQuizPassed || isLessonCompleted;

  // Check strict sequential lock
  const isUnlocked = (() => {
    if (lesson.globalIndex === 1) return true;
    for (const mod of ACADEMIA_MODULES) {
      for (const l of mod.lessons) {
        if (l.globalIndex === lesson.globalIndex - 1) {
          return completedLessonIds.includes(l.id);
        }
      }
    }
    return false;
  })();

  const isVipLocked = lesson.isVip && userRole !== "VIP";
  const isAccessBlocked = !isUnlocked || isVipLocked;

  const markLessonAsComplete = () => {
    if (!completedLessonIds.includes(lesson.id)) {
      const updated = [...completedLessonIds, lesson.id];
      setCompletedLessonIds(updated);
      try {
        localStorage.setItem("kopytrading_academia_completed", JSON.stringify(updated));
      } catch (e) {
        console.error(e);
      }

      // Check if module completed
      const modLessons = currentModule.lessons.map(l => l.id);
      const isModFinished = modLessons.every(id => updated.includes(id));
      if (isModFinished) {
        setCompletedModuleName(currentModule.title);
        setShowModuleModal(true);
      }
    }
  };

  const handleNextLesson = () => {
    let allLessons: string[] = [];
    ACADEMIA_MODULES.forEach(m => {
      m.lessons.forEach(l => allLessons.push(l.id));
    });

    const currentIndex = allLessons.indexOf(lesson.id);
    if (currentIndex >= 0 && currentIndex < allLessons.length - 1) {
      const nextId = allLessons[currentIndex + 1];
      router.push(`/academia/leccion/${nextId}`);
    } else {
      router.push("/academia");
    }
  };

  return (
    <div className="min-h-screen bg-[#070A10] text-white flex flex-col lg:flex-row font-sans selection:bg-amber-400 selection:text-slate-950 pt-16 md:pt-20">
      {/* Mobile Top Header */}
      <div className="lg:hidden p-4 bg-[#0A0D14] border-b border-slate-800 flex items-center justify-between sticky top-16 z-30">
        <button
          onClick={() => setSidebarOpen(!sidebarOpen)}
          className="p-2 rounded-lg bg-slate-900 border border-slate-800 text-slate-300"
        >
          {sidebarOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
        </button>
        <span className="text-xs font-mono font-bold text-amber-400 truncate max-w-[200px]">
          {lesson.title}
        </span>
        <Link href="/academia" className="text-xs text-slate-400 font-medium hover:text-white">
          Salir
        </Link>
      </div>

      {/* Sidebar Navigation */}
      <div
        className={`fixed inset-y-0 left-0 z-40 lg:relative lg:z-auto transition-transform duration-300 transform ${
          sidebarOpen ? "translate-x-0" : "-translate-x-full lg:translate-x-0"
        }`}
      >
        <ProgressSidebar
          currentLessonId={lesson.id}
          completedLessonIds={completedLessonIds}
          userRole={userRole}
          onSelectLesson={() => setSidebarOpen(false)}
        />
      </div>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-h-[calc(100vh-80px)] overflow-y-auto">
        {/* Top Breadcrumb Bar */}
        <header className="hidden lg:flex items-center justify-between px-8 py-3.5 bg-[#0A0D14] border-b border-slate-800/80">
          <div className="flex items-center gap-3 text-xs font-mono text-slate-400">
            <Link href="/academia" className="hover:text-amber-400 transition-colors">
              ACADEMIA
            </Link>
            <span>/</span>
            <span className="text-slate-500">{currentModule.title}</span>
            <span>/</span>
            <span className="text-amber-400 font-bold">{lesson.title}</span>
          </div>

          <Link
            href="/academia"
            className="px-3.5 py-1.5 rounded-lg bg-slate-900 hover:bg-slate-800 border border-slate-800 text-xs font-semibold text-slate-300 transition-colors"
          >
            ← Volver al Menú
          </Link>
        </header>

        {/* Content Container */}
        <main className="flex-1 max-w-4xl w-full mx-auto p-4 md:p-6 space-y-6">
          {/* Locked Guard Screen (Optimized height and margins) */}
          {isAccessBlocked ? (
            <div className="rounded-2xl bg-[#0F1422] border border-amber-500/30 p-6 md:p-8 text-center space-y-4 shadow-xl max-w-xl mx-auto my-4">
              <div className="w-14 h-14 rounded-2xl bg-amber-500/10 border border-amber-400/30 flex items-center justify-center mx-auto text-amber-400">
                {isVipLocked ? <Crown className="w-7 h-7" /> : <Lock className="w-7 h-7" />}
              </div>

              <div className="space-y-1.5">
                <span className="px-2.5 py-0.5 rounded-full bg-amber-400/10 border border-amber-400/30 text-amber-400 font-mono text-[10px] font-bold uppercase">
                  {isVipLocked ? "CONTENIDO VIP RESTRINGIDO" : "LECCIÓN BLOQUEADA"}
                </span>
                <h2 className="text-xl md:text-2xl font-extrabold text-white">
                  {isVipLocked ? "Módulo Exclusivo para Usuarios del Bot" : "Debes avanzar en orden secuencial"}
                </h2>
                <p className="text-xs md:text-sm text-slate-300 leading-relaxed">
                  {isVipLocked
                    ? "Este módulo técnico de puesta en marcha estará disponible para usuarios que adquieran o descarguen un bot oficialmente."
                    : "Para garantizar un aprendizaje veraz y sólido, no es posible saltar lecciones. Completa la lección anterior para desbloquear esta parte."}
                </p>
              </div>

              <div className="pt-2">
                <Link
                  href="/academia"
                  className="inline-flex items-center gap-2 px-5 py-3 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 font-extrabold text-xs shadow-lg shadow-amber-500/20 transition-all"
                >
                  <ArrowLeft className="w-4 h-4" />
                  Ir al Menú de Lecciones
                </Link>
              </div>
            </div>
          ) : (
            <>
              {/* Lesson Header */}
              <div className="space-y-2 border-b border-slate-800/80 pb-4">
                <div className="flex items-center gap-3">
                  <span className="px-2.5 py-0.5 rounded bg-amber-400/10 border border-amber-400/30 text-amber-400 font-mono text-[10px] font-bold uppercase">
                    MÓDULO {currentModule.moduleNumberStr}
                  </span>
                  <span className="text-xs font-mono text-slate-400 flex items-center gap-1">
                    <Clock className="w-3.5 h-3.5" />
                    {lesson.durationMinutes} min de lectura
                  </span>
                </div>

                <h1 className="text-2xl md:text-3xl font-extrabold text-white tracking-tight">
                  {lesson.title}
                </h1>
                {lesson.subtitle && (
                  <p className="text-slate-400 text-xs md:text-sm">{lesson.subtitle}</p>
                )}
              </div>

              {/* Micro-learning Pages Component */}
              {lesson.pages && lesson.pages.length > 0 && (
                <LessonTextPage
                  pages={lesson.pages}
                  hasQuiz={Boolean(lesson.quiz)}
                  onFinishReading={() => {
                    if (!lesson.quiz) {
                      markLessonAsComplete();
                    }
                  }}
                />
              )}

              {/* Interactive Quiz Component */}
              {lesson.quiz && (
                <InteractiveQuiz
                  quiz={lesson.quiz}
                  isAlreadyPassed={isLessonCompleted || isQuizPassed}
                  onCorrectAnswer={() => {
                    setIsQuizPassed(true);
                    markLessonAsComplete();
                  }}
                />
              )}

              {/* Special Lead Magnet / Free Trial Card */}
              {lesson.isFreeTrialUnlocker && (
                <div className="pt-4">
                  <FreeTrialClaimCard
                    userEmail={userEmail || undefined}
                    onTrialClaimed={() => setUserRole("VIP")}
                  />
                </div>
              )}

              {/* Bottom Lesson Footer Controls */}
              <div className="pt-6 border-t border-slate-800/80 space-y-3">
                <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
                  <Link
                    href="/academia"
                    className="w-full sm:w-auto px-5 py-2.5 rounded-xl bg-slate-900 hover:bg-slate-800 border border-slate-800 text-xs font-bold text-slate-300 flex items-center justify-center gap-2 transition-colors"
                  >
                    <ArrowLeft className="w-4 h-4" />
                    Menú de Lecciones
                  </Link>

                  <button
                    onClick={() => {
                      if (!canAdvance) {
                        const el = document.getElementById("evaluacion-section");
                        if (el) {
                          el.scrollIntoView({ behavior: "smooth" });
                        }
                        return;
                      }
                      markLessonAsComplete();
                      handleNextLesson();
                    }}
                    className={`w-full sm:w-auto px-6 py-3 rounded-xl text-xs font-extrabold flex items-center justify-center gap-2 transition-all shadow-lg ${
                      canAdvance
                        ? "bg-gradient-to-r from-emerald-500 to-teal-400 hover:from-emerald-400 hover:to-teal-300 text-slate-950 shadow-emerald-500/20"
                        : "bg-slate-900 border border-amber-500/40 text-amber-300 hover:bg-slate-800"
                    }`}
                  >
                    {canAdvance ? (
                      <>
                        <CheckCircle2 className="w-4 h-4 text-slate-950" />
                        {isLessonCompleted ? "Lección Completada - Siguiente" : "Avanzar a la Siguiente Lección"}
                        <ChevronRight className="w-4 h-4" />
                      </>
                    ) : (
                      <>
                        <Lock className="w-4 h-4 text-amber-400" />
                        Responde la Evaluación para Avanzar
                      </>
                    )}
                  </button>
                </div>

                <p className="text-[10px] font-mono text-slate-500 text-center">
                  Completa la evaluación correctamente para registrar tu avance y desbloquear las siguientes lecciones.
                </p>
              </div>
            </>
          )}

          {/* Disclaimer Footer */}
          <div className="p-3.5 rounded-xl bg-slate-950/60 border border-slate-900 text-[11px] text-slate-500 space-y-1">
            <div className="flex items-center gap-1.5 font-bold text-slate-400">
              <ShieldAlert className="w-3.5 h-3.5 text-amber-500" />
              Aviso de Riesgo
            </div>
            <p>
              El trading algorítmico implica riesgo. Las lecciones de Kopytrading Academy tienen fines puramente educativos. Los resultados de backtest o rendimiento previo no constituyen garantía de resultados futuros.
            </p>
          </div>
        </main>
      </div>

      {/* Module Completion Modal */}
      <ModuleCompletedModal
        isOpen={showModuleModal}
        moduleTitle={completedModuleName}
        completedLessonsCount={completedLessonIds.length}
        onClose={() => setShowModuleModal(false)}
      />

      {/* Email Gate Modal */}
      <EmailGateModal
        isOpen={showEmailGate}
        onSuccess={(email) => {
          setUserEmail(email);
          setShowEmailGate(false);
        }}
      />
    </div>
  );
}

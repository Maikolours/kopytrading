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
  X
} from "lucide-react";
import { getLessonById, ACADEMIA_MODULES } from "@/lib/academiaData";
import ProgressSidebar from "@/components/academia/ProgressSidebar";
import InteractiveQuiz from "@/components/academia/InteractiveQuiz";
import LessonTextPage from "@/components/academia/LessonTextPage";
import ModuleCompletedModal from "@/components/academia/ModuleCompletedModal";
import FreeTrialClaimCard from "@/components/academia/FreeTrialClaimCard";

export default function LessonPlayerPage() {
  const params = useParams();
  const router = useRouter();
  const lessonId = params?.leccionId as string;

  const [completedLessonIds, setCompletedLessonIds] = useState<string[]>([]);
  const [showModuleModal, setShowModuleModal] = useState(false);
  const [completedModuleName, setCompletedModuleName] = useState("");
  const [sidebarOpen, setSidebarOpen] = useState(false);

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

  const lessonData = getLessonById(lessonId);

  if (!lessonData) {
    return (
      <div className="min-h-screen bg-[#070A10] text-white flex flex-col items-center justify-center p-6 text-center">
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
    // Find next lesson
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
    <div className="min-h-screen bg-[#070A10] text-white flex flex-col lg:flex-row font-sans selection:bg-amber-400 selection:text-slate-950">
      {/* Mobile Top Header */}
      <div className="lg:hidden p-4 bg-[#0A0D14] border-b border-slate-800 flex items-center justify-between sticky top-0 z-30">
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
          userRole="USER"
          onSelectLesson={() => setSidebarOpen(false)}
        />
      </div>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-h-screen overflow-y-auto">
        {/* Top Navbar Header */}
        <header className="hidden lg:flex items-center justify-between px-8 py-4 bg-[#0A0D14] border-b border-slate-800/80">
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
        <main className="flex-1 max-w-4xl w-full mx-auto p-6 md:p-10 space-y-8">
          {/* Lesson Header */}
          <div className="space-y-2 border-b border-slate-800/80 pb-6">
            <div className="flex items-center gap-3">
              <span className="px-2.5 py-0.5 rounded bg-amber-400/10 border border-amber-400/30 text-amber-400 font-mono text-[10px] font-bold uppercase">
                MÓDULO {currentModule.moduleNumberStr}
              </span>
              <span className="text-xs font-mono text-slate-400 flex items-center gap-1">
                <Clock className="w-3.5 h-3.5" />
                {lesson.durationMinutes} min de lectura
              </span>
            </div>

            <h1 className="text-2xl md:text-4xl font-extrabold text-white tracking-tight">
              {lesson.title}
            </h1>
            {lesson.subtitle && (
              <p className="text-slate-400 text-sm md:text-base">{lesson.subtitle}</p>
            )}
          </div>

          {/* Micro-learning Pages Component */}
          {lesson.pages && lesson.pages.length > 0 && (
            <LessonTextPage
              pages={lesson.pages}
              onFinishReading={markLessonAsComplete}
            />
          )}

          {/* Interactive Quiz Component */}
          {lesson.quiz && (
            <div className="pt-4">
              <InteractiveQuiz
                quiz={lesson.quiz}
                onCorrectAnswer={markLessonAsComplete}
              />
            </div>
          )}

          {/* Special Lead Magnet / Free Trial Card */}
          {lesson.isFreeTrialUnlocker && (
            <div className="pt-6">
              <FreeTrialClaimCard />
            </div>
          )}

          {/* Bottom Lesson Footer Controls */}
          <div className="pt-8 border-t border-slate-800/80 space-y-4">
            <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
              <Link
                href="/academia"
                className="w-full sm:w-auto px-5 py-3 rounded-xl bg-slate-900 hover:bg-slate-800 border border-slate-800 text-xs font-bold text-slate-300 flex items-center justify-center gap-2 transition-colors"
              >
                <ArrowLeft className="w-4 h-4" />
                Menú de Lecciones
              </Link>

              <button
                onClick={() => {
                  markLessonAsComplete();
                  handleNextLesson();
                }}
                className={`w-full sm:w-auto px-6 py-3.5 rounded-xl text-xs font-extrabold flex items-center justify-center gap-2 transition-all shadow-lg ${
                  isLessonCompleted
                    ? "bg-emerald-500 hover:bg-emerald-400 text-slate-950 shadow-emerald-500/20"
                    : "bg-gradient-to-r from-amber-500 to-yellow-400 hover:from-amber-400 hover:to-yellow-300 text-slate-950 shadow-amber-500/20"
                }`}
              >
                <CheckCircle2 className="w-4 h-4" />
                {isLessonCompleted ? "Lección Completada - Siguiente" : "Marcar como Completada y Avanzar"}
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>

            <p className="text-[11px] font-mono text-slate-500 text-center">
              Completa las lecciones en orden para desbloquear progresivamente los siguientes módulos.
            </p>
          </div>

          {/* Disclaimer Footer */}
          <div className="p-4 rounded-xl bg-slate-950/60 border border-slate-900 text-[11px] text-slate-500 space-y-1">
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
    </div>
  );
}

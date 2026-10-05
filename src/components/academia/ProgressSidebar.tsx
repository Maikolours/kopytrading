"use client";

import React from "react";
import Link from "next/link";
import { 
  CheckCircle2, 
  Lock, 
  Crown, 
  ChevronDown, 
  ChevronRight,
  BookOpen,
  Award,
  Sparkles
} from "lucide-react";
import { ACADEMIA_MODULES, TOTAL_LESSONS_COUNT, Lesson, Module } from "@/lib/academiaData";

interface ProgressSidebarProps {
  currentLessonId?: string;
  completedLessonIds: string[];
  userRole?: string; // "VIP" | "USER"
  onSelectLesson?: (lessonId: string) => void;
}

export default function ProgressSidebar({
  currentLessonId,
  completedLessonIds,
  userRole = "USER",
  onSelectLesson
}: ProgressSidebarProps) {
  const [openModules, setOpenModules] = React.useState<Record<string, boolean>>({
    "modulo-00": true,
    "modulo-01": true,
  });

  const toggleModule = (moduleId: string) => {
    setOpenModules(prev => ({ ...prev, [moduleId]: !prev[moduleId] }));
  };

  const totalCompleted = completedLessonIds.length;
  const progressPercent = Math.min(100, Math.round((totalCompleted / TOTAL_LESSONS_COUNT) * 100));

  return (
    <div className="w-full lg:w-80 flex flex-col h-full bg-[#0A0D14] border-r border-slate-800/80 text-white select-none">
      {/* Brand Header */}
      <div className="p-5 border-b border-slate-800/60 bg-[#0B0F19]">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-amber-500 to-yellow-300 p-0.5 shadow-lg shadow-amber-500/20">
            <div className="w-full h-full bg-[#0F172A] rounded-[10px] flex items-center justify-center font-extrabold text-amber-400 text-lg">
              K
            </div>
          </div>
          <div>
            <h2 className="font-extrabold text-base tracking-wide text-white leading-tight flex items-center gap-1.5">
              Kopytrading <span className="text-amber-400 text-xs font-semibold px-1.5 py-0.5 bg-amber-400/10 rounded border border-amber-400/20">ACADEMY</span>
            </h2>
            <p className="text-[11px] font-mono tracking-widest text-slate-400 uppercase mt-0.5">
              FOREX · ORO · BOTS
            </p>
          </div>
        </div>

        {/* Global Progress Widget */}
        <div className="mt-5 p-3.5 rounded-xl bg-slate-900/90 border border-slate-800 flex items-center gap-4">
          <div className="relative w-12 h-12 flex items-center justify-center">
            <svg className="w-full h-full -rotate-90" viewBox="0 0 36 36">
              <path
                className="text-slate-800"
                strokeWidth="3.5"
                stroke="currentColor"
                fill="none"
                d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
              />
              <path
                className="text-amber-400 transition-all duration-700 ease-out"
                strokeDasharray={`${progressPercent}, 100`}
                strokeWidth="3.5"
                strokeLinecap="round"
                stroke="currentColor"
                fill="none"
                d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
              />
            </svg>
            <span className="absolute text-xs font-bold text-amber-400">
              {progressPercent}%
            </span>
          </div>

          <div>
            <div className="text-xs text-slate-400 font-medium">Tu progreso</div>
            <div className="text-sm font-bold text-slate-200">
              {totalCompleted} de {TOTAL_LESSONS_COUNT} lecciones
            </div>
            <div className="text-[11px] font-mono text-emerald-400 mt-0.5">
              Módulo 00 disponible
            </div>
          </div>
        </div>
      </div>

      {/* Modules List */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4 custom-scrollbar">
        {ACADEMIA_MODULES.map((mod, modIdx) => {
          const isOpen = !!openModules[mod.id];
          const completedInModule = mod.lessons.filter(l => completedLessonIds.includes(l.id)).length;
          const isModuleDone = completedInModule === mod.lessons.length;

          return (
            <div key={mod.id} className="rounded-xl overflow-hidden border border-slate-800/80 bg-slate-950/40">
              {/* Module Header Toggle */}
              <button
                onClick={() => toggleModule(mod.id)}
                className={`w-full text-left p-3.5 flex items-center justify-between transition-colors ${
                  isOpen ? "bg-slate-900/60" : "hover:bg-slate-900/40"
                }`}
              >
                <div>
                  <div className="text-[10px] font-mono font-bold tracking-wider text-amber-400/90 uppercase flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-amber-400 inline-block"></span>
                    Módulo {mod.moduleNumberStr}: {mod.title}
                  </div>
                  <div className="text-xs text-slate-400 mt-0.5 font-medium">
                    {mod.subtitle}
                  </div>
                </div>

                <div className="flex items-center gap-2">
                  <span className="text-[11px] font-mono text-slate-500">
                    {completedInModule}/{mod.lessons.length}
                  </span>
                  {isOpen ? (
                    <ChevronDown className="w-4 h-4 text-slate-400" />
                  ) : (
                    <ChevronRight className="w-4 h-4 text-slate-400" />
                  )}
                </div>
              </button>

              {/* Lessons List inside Module */}
              {isOpen && (
                <div className="p-2 space-y-1 bg-slate-900/20 border-t border-slate-800/40">
                  {mod.lessons.map((lesson) => {
                    const isCompleted = completedLessonIds.includes(lesson.id);
                    const isActive = lesson.id === currentLessonId;
                    const isVipLocked = lesson.isVip && userRole !== "VIP";

                    return (
                      <div key={lesson.id}>
                        {isVipLocked ? (
                          <div className="flex items-center justify-between px-3 py-2.5 rounded-lg opacity-60 bg-slate-950/40 border border-transparent text-slate-400 cursor-not-allowed">
                            <div className="flex items-center gap-2.5 truncate">
                              <Crown className="w-4 h-4 text-amber-400 shrink-0" />
                              <span className="text-xs font-medium truncate">{lesson.title}</span>
                            </div>
                            <span className="text-[10px] font-mono font-bold bg-amber-400/10 text-amber-400 border border-amber-400/30 px-1.5 py-0.5 rounded">
                              VIP
                            </span>
                          </div>
                        ) : (
                          <Link
                            href={`/academia/leccion/${lesson.id}`}
                            onClick={() => onSelectLesson?.(lesson.id)}
                            className={`flex items-center justify-between px-3 py-2.5 rounded-lg transition-all text-xs font-medium ${
                              isActive
                                ? "bg-slate-800 text-amber-400 border border-amber-400/40 font-semibold shadow-md shadow-amber-400/5"
                                : isCompleted
                                ? "bg-slate-900/40 text-emerald-400 hover:bg-slate-800/60"
                                : "text-slate-300 hover:bg-slate-900/60 hover:text-white"
                            }`}
                          >
                            <div className="flex items-center gap-2.5 truncate">
                              {isCompleted ? (
                                <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
                              ) : isActive ? (
                                <span className="w-2.5 h-2.5 rounded-full bg-amber-400 shrink-0 animate-pulse"></span>
                              ) : (
                                <span className="w-2 h-2 rounded-full bg-slate-600 shrink-0"></span>
                              )}
                              <span className="truncate">{lesson.title}</span>
                            </div>

                            {lesson.quiz && (
                              <span className="text-[9px] font-mono uppercase bg-emerald-500/10 text-emerald-400 px-1.5 py-0.5 rounded border border-emerald-500/20">
                                QUIZ
                              </span>
                            )}
                          </Link>
                        )}
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}

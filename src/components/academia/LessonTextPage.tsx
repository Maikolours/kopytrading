"use client";

import React, { useState } from "react";
import { ChevronLeft, ChevronRight, BookOpen, Clock, Lightbulb } from "lucide-react";
import { LessonPage } from "@/lib/academiaData";

interface LessonTextPageProps {
  pages: LessonPage[];
  hasQuiz?: boolean;
  onPageChange?: (pageIdx: number) => void;
  onFinishReading?: () => void;
}

export default function LessonTextPage({ pages, hasQuiz, onPageChange, onFinishReading }: LessonTextPageProps) {
  const [currentPageIdx, setCurrentPageIdx] = useState(0);

  if (!pages || pages.length === 0) return null;

  const page = pages[currentPageIdx];
  const isFirstPage = currentPageIdx === 0;
  const isLastPage = currentPageIdx === pages.length - 1;

  const handleNext = () => {
    if (!isLastPage) {
      const nextIdx = currentPageIdx + 1;
      setCurrentPageIdx(nextIdx);
      onPageChange?.(nextIdx);
    } else {
      if (hasQuiz) {
        const el = document.getElementById("evaluacion-section");
        if (el) {
          el.scrollIntoView({ behavior: "smooth" });
        }
      }
      onFinishReading?.();
    }
  };

  const handlePrev = () => {
    if (!isFirstPage) {
      const prevIdx = currentPageIdx - 1;
      setCurrentPageIdx(prevIdx);
      onPageChange?.(prevIdx);
    }
  };

  return (
    <div className="w-full space-y-6">
      {/* Pagination Step Header */}
      <div className="flex items-center justify-between border-b border-slate-800 pb-3 text-xs font-mono text-slate-400">
        <div className="flex items-center gap-2">
          {pages.map((_, idx) => (
            <span
              key={idx}
              className={`w-2.5 h-2.5 rounded-full transition-all ${
                idx === currentPageIdx
                  ? "bg-amber-400 scale-125 shadow-sm shadow-amber-400/50"
                  : idx < currentPageIdx
                  ? "bg-emerald-400"
                  : "bg-slate-700"
              }`}
            />
          ))}
          <span className="ml-2 text-slate-300">
            Página {currentPageIdx + 1} de {pages.length}
          </span>
        </div>
      </div>

      {/* Page Title */}
      <h2 className="text-2xl md:text-3xl font-extrabold text-white tracking-tight">
        {page.title}
      </h2>

      {/* Paragraphs */}
      <div className="space-y-4 text-slate-300 text-sm md:text-base leading-relaxed">
        {page.content.map((paragraph, idx) => (
          <p key={idx} className="text-slate-300">
            {paragraph}
          </p>
        ))}
      </div>

      {/* Key Concept Visual Card */}
      {page.keyConceptCard && (
        <div className="my-6 rounded-2xl bg-slate-900/90 border border-slate-800 p-5 space-y-3">
          <div className="text-[10px] font-mono font-bold tracking-widest text-amber-400 uppercase flex items-center gap-1.5">
            <Lightbulb className="w-3.5 h-3.5 text-amber-400" />
            {page.keyConceptCard.tag}
          </div>
          <h4 className="font-bold text-sm text-slate-200 uppercase tracking-wide">
            {page.keyConceptCard.title}
          </h4>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 pt-2">
            {page.keyConceptCard.items.map((item, idx) => (
              <div key={idx} className="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80 text-center">
                <div className="text-xs text-slate-400 mb-1">{item.label}</div>
                <div className={`text-sm font-extrabold ${item.color || "text-white"}`}>
                  {item.value}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Page Navigation Controls */}
      {pages.length > 1 && (
        <div className="flex items-center justify-between pt-4 border-t border-slate-800/60">
          <button
            onClick={handlePrev}
            disabled={isFirstPage}
            className={`px-4 py-2 rounded-xl border text-xs font-semibold flex items-center gap-1.5 transition-all ${
              isFirstPage
                ? "opacity-30 border-slate-800 text-slate-500 cursor-not-allowed"
                : "border-slate-700 text-slate-300 hover:bg-slate-800 hover:text-white"
            }`}
          >
            <ChevronLeft className="w-4 h-4" />
            Anterior
          </button>

          <button
            onClick={handleNext}
            className="px-5 py-2 rounded-xl bg-amber-500 hover:bg-amber-400 text-slate-950 font-bold text-xs flex items-center gap-1.5 shadow-lg shadow-amber-500/20 transition-all"
          >
            {isLastPage ? (hasQuiz ? "Ir a la Evaluación ↓" : "Lectura finalizada") : `Siguiente página (${currentPageIdx + 2}/${pages.length})`}
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>
      )}
    </div>
  );
}

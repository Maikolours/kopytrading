"use client";

import React, { useState } from "react";
import { Check, X, Sparkles, HelpCircle } from "lucide-react";
import { QuizQuestion } from "@/lib/academiaData";

interface InteractiveQuizProps {
  quiz: QuizQuestion;
  onCorrectAnswer?: () => void;
}

export default function InteractiveQuiz({ quiz, onCorrectAnswer }: InteractiveQuizProps) {
  const [selectedOptionId, setSelectedOptionId] = useState<string | null>(null);
  const [isAnswered, setIsAnswered] = useState(false);

  const handleSelectOption = (optionId: string) => {
    if (isAnswered) return; // Lock after answering
    setSelectedOptionId(optionId);
    setIsAnswered(true);

    if (optionId === quiz.correctAnswerId) {
      onCorrectAnswer?.();
    }
  };

  const isCorrect = selectedOptionId === quiz.correctAnswerId;

  return (
    <div className="w-full rounded-2xl bg-[#0E131F] border border-amber-500/30 p-6 shadow-2xl relative overflow-hidden">
      {/* Decorative Glow */}
      <div className="absolute top-0 right-0 w-64 h-64 bg-amber-500/5 blur-3xl pointer-events-none rounded-full" />

      {/* Top Badge */}
      <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-amber-400/10 border border-amber-400/30 text-amber-400 text-xs font-mono font-bold tracking-wider uppercase mb-4">
        <Sparkles className="w-3.5 h-3.5" />
        {quiz.badgeText || "PRACTICA"}
      </div>

      {/* Question Title */}
      <h3 className="text-lg md:text-xl font-bold text-white mb-6 leading-snug">
        {quiz.question}
      </h3>

      {/* Options List */}
      <div className="space-y-3 mb-6">
        {quiz.options.map((option) => {
          const isSelected = selectedOptionId === option.id;
          const isThisCorrect = option.id === quiz.correctAnswerId;

          let cardStyle = "bg-[#141A29] border-slate-800 text-slate-200 hover:border-slate-700 hover:bg-[#182033]";
          let circleStyle = "border-slate-600 text-slate-400 bg-slate-800";

          if (isAnswered) {
            if (isThisCorrect) {
              cardStyle = "bg-emerald-950/40 border-emerald-500 text-emerald-200 shadow-lg shadow-emerald-500/10";
              circleStyle = "bg-emerald-500 border-emerald-400 text-slate-950 font-bold";
            } else if (isSelected && !isThisCorrect) {
              cardStyle = "bg-red-950/40 border-red-500 text-red-200";
              circleStyle = "bg-red-500 border-red-400 text-white";
            } else {
              cardStyle = "bg-[#141A29]/50 border-slate-900 text-slate-500 opacity-50";
            }
          }

          return (
            <button
              key={option.id}
              onClick={() => handleSelectOption(option.id)}
              disabled={isAnswered}
              className={`w-full text-left p-4 rounded-xl border transition-all duration-200 flex items-start gap-4 ${cardStyle}`}
            >
              <div
                className={`w-7 h-7 rounded-full border flex items-center justify-center text-xs font-mono shrink-0 mt-0.5 transition-transform ${circleStyle}`}
              >
                {isAnswered && isThisCorrect ? (
                  <Check className="w-4 h-4 stroke-[3]" />
                ) : isAnswered && isSelected && !isThisCorrect ? (
                  <X className="w-4 h-4 stroke-[3]" />
                ) : (
                  option.id
                )}
              </div>
              <span className="text-sm md:text-base font-medium leading-relaxed">
                {option.text}
              </span>
            </button>
          );
        })}
      </div>

      {/* Answer Feedback Explanation Box */}
      {isAnswered && (
        <div
          className={`p-4 rounded-xl border animate-slide-up ${
            isCorrect
              ? "bg-emerald-950/60 border-emerald-500/60 text-emerald-300"
              : "bg-red-950/60 border-red-500/60 text-red-300"
          }`}
        >
          <div className="flex items-start gap-3">
            {isCorrect ? (
              <Check className="w-5 h-5 text-emerald-400 shrink-0 mt-0.5 stroke-[3]" />
            ) : (
              <X className="w-5 h-5 text-red-400 shrink-0 mt-0.5 stroke-[3]" />
            )}
            <div>
              <div className="font-bold text-sm mb-1">
                {isCorrect ? "¡Correcto!" : "Opción incorrecta"}
              </div>
              <p className="text-xs md:text-sm leading-relaxed opacity-95">
                {quiz.feedbackExplanation}
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

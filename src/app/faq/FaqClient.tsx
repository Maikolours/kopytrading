"use client";

import { useState } from "react";
import Link from "next/link";

import { FAQS } from "./data";

function AccordionItem({ question, answer }: { question: string; answer: string }) {
    const [open, setOpen] = useState(false);
    return (
        <div className={`border rounded-xl overflow-hidden transition-all duration-300 ${open ? "border-brand/40 bg-brand/5 shadow-[0_0_20px_rgba(139,92,246,0.1)]" : "border-white/10 bg-transparent hover:border-white/20"}`}>
            <button
                onClick={() => setOpen(!open)}
                className="w-full text-left flex items-center justify-between p-5 sm:p-6 transition-colors"
            >
                <span className={`font-semibold transition-colors ${open ? "text-brand-light" : "text-white"}`}>{question}</span>
                <span className={`text-brand-light text-2xl transition-transform duration-300 flex-shrink-0 ${open ? "rotate-45" : ""}`}>+</span>
            </button>
            <div className={`grid transition-all duration-300 ease-in-out ${open ? "grid-rows-[1fr] opacity-100" : "grid-rows-[0fr] opacity-0"}`}>
                <div className="overflow-hidden">
                    <div className="px-5 sm:px-6 pb-6 text-text-muted text-sm sm:text-base leading-relaxed border-t border-white/5 pt-4 font-light">
                        {answer}
                    </div>
                </div>
            </div>
        </div>
    );
}

export function FaqClient() {
    return (
        <div className="min-h-screen pt-28 md:pt-36 pb-24 px-4 sm:px-8 max-w-5xl mx-auto">
            <div className="w-full">
                {/* Header */}
                <div className="mb-6">
                    <Link href="/" className="inline-flex items-center gap-2 text-sm text-text-muted hover:text-white transition-colors group">
                        <span className="group-hover:-translate-x-1 transition-transform">←</span> Volver al inicio
                    </Link>
                </div>
                <div className="text-center mb-16">
                    <h1 className="text-4xl md:text-6xl font-extrabold text-white mb-6 uppercase tracking-tight italic">Preguntas Frecuentes</h1>
                    <p className="text-text-muted max-w-2xl mx-auto text-lg font-light leading-relaxed">
                        Todo lo que necesitas saber antes de empezar con el trading algorítmico y los bots de KopyTrading.
                    </p>
                    <div className="mt-8 inline-block px-6 py-2 rounded-full bg-warning/10 border border-warning/20">
                        <p className="text-xs text-warning font-semibold">
                            ⚠️ El trading conlleva un alto riesgo de pérdida de capital. Rendimientos pasados no garantizan resultados futuros.
                        </p>
                    </div>
                </div>

                {/* FAQ Sections */}
                <div className="space-y-16">
                    {FAQS.map((section, si) => (
                        <div key={si} className="animate-slide-up" style={{ animationDelay: `${si * 100}ms` }}>
                            <div className="flex items-center gap-3 mb-6">
                                <div className="h-8 w-1 bg-brand rounded-full"></div>
                                <h2 className="text-2xl font-bold text-white uppercase tracking-tight italic">{section.category}</h2>
                            </div>
                            <div className="space-y-4">
                                {section.items.map((item, ii) => (
                                    <AccordionItem key={ii} question={item.q} answer={item.a} />
                                ))}
                            </div>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
}

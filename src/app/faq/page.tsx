import { FaqClient } from "./FaqClient";
import { Metadata } from "next";

export const metadata: Metadata = {
    title: "Preguntas Frecuentes (FAQ) | KopyTrading",
    description: "Encuentra respuestas sobre cómo configurar tu VPS, instalar Expert Advisors en MT5, la gestión del riesgo y cómo activar tu prueba de 30 días.",
    keywords: ["faq bots", "vps trading", "cuentas cent", "cuenta demo metatrader 5", "break even mt5"],
};

export default function FAQPage() {
    return <FaqClient />;
}

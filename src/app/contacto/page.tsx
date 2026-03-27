import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/Card";
import Link from "next/link";

export default function ContactoPage() {
    return (
        <div className="min-h-screen pt-28 md:pt-32 pb-24 px-4 sm:px-6 lg:px-8 relative">
            <div className="absolute top-1/2 left-0 w-[400px] h-[400px] bg-brand/5 blur-[120px] rounded-full mix-blend-screen pointer-events-none" />

            <div className="max-w-4xl mx-auto z-10 relative">
                <Link href="/" className="inline-flex items-center gap-2 text-sm text-text-muted hover:text-white transition-colors mb-8">
                    <span>←</span> Volver al inicio
                </Link>

                <div className="mb-12 border-b border-white/10 pb-8 text-center md:text-left">
                    <h1 className="text-4xl font-bold tracking-tight text-white mb-3">Contacto</h1>
                    <p className="text-text-muted max-w-2xl">¿Tienes dudas sobre la instalación o el funcionamiento de nuestros bots? Estamos aquí para ayudarte.</p>
                </div>

                <div className="grid md:grid-cols-2 gap-8 items-start">
                    {/* Canal oficial de Soporte */}
                    <Card className="bg-surface-light/10 border-white/5 p-8">
                        <CardHeader className="p-0 mb-6">
                            <CardTitle className="text-xl font-bold text-white flex items-center gap-2">
                                📧 Canal de Soporte
                            </CardTitle>
                        </CardHeader>
                        <CardContent className="p-0 space-y-4">
                            <p className="text-sm text-text-muted">
                                Escríbenos directamente para consultas técnicas, licencias o problemas de instalación:
                            </p>
                            <div className="bg-black/40 border border-brand/20 p-4 rounded-xl text-center">
                                <a href="mailto:kopytrading@gmail.com" className="text-brand-light font-bold text-lg hover:underline transition-all">
                                    kopytrading@gmail.com
                                </a>
                            </div>
                            <p className="text-[10px] text-text-muted/60 bg-white/5 p-3 rounded-lg border border-white/5">
                                Respondemos por orden de llegada, normalmente en menos de 24-48 horas laborables.
                            </p>
                        </CardContent>
                    </Card>

                    {/* FAQ & Alternativa rápida */}
                    <div className="space-y-6">
                        <Card className="bg-surface-light/5 border-white/5 p-6">
                            <h3 className="text-white font-semibold mb-3">🚀 Respuesta Rápida</h3>
                            <p className="text-xs text-text-muted leading-relaxed">
                                Antes de contactarnos, echa un vistazo a nuestra sección de preguntas frecuentes. He respondido a las dudas más comunes sobre MetaTrader 5, VPS y lotajes.
                            </p>
                            <Link href="/faq" className="inline-block mt-4 text-xs font-bold text-brand-light hover:text-white transition-colors">
                                Ir a Preguntas Frecuentes (FAQ) →
                            </Link>
                        </Card>

                        <div className="p-6 border border-white/5 rounded-2xl bg-brand/5">
                            <h3 className="text-white font-semibold mb-2 text-sm">⚠️ Atención al Cliente</h3>
                            <p className="text-xs text-text-muted leading-relaxed">
                                Por favor, no envíes datos personales sensibles. Solo necesitamos tu ID de compra o el error que te muestra el terminal para poder asistirte.
                            </p>
                        </div>
                    </div>
                </div>

                {/* Mapa de ruta a seguir */}
                <div className="mt-16 text-center max-w-2xl mx-auto space-y-4">
                    <h2 className="text-white font-bold text-xl">¿Eres un usuario nuevo?</h2>
                    <p className="text-sm text-text-muted">Si acabas de adquirir un bot, recuerda que el proceso de instalación es semi-automático. Consulta la guía de instalación para ahorrar tiempo.</p>
                    <Link href="/instalar" className="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-surface-light text-white text-xs font-bold hover:bg-white hover:text-black transition-all">
                        📘 Guía de Instalación
                    </Link>
                </div>
            </div>
        </div>
    );
}

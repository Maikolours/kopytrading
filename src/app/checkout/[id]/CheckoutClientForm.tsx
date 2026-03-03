"use client";

import { useState, useTransition, useEffect } from "react";
import { useRouter } from "next/navigation";
import { signIn } from "next-auth/react";
import { PayPalScriptProvider, PayPalButtons } from "@paypal/react-paypal-js";

export function CheckoutClientForm({ bot, isTrial = false }: { bot: any, isTrial?: boolean }) {
    const router = useRouter();
    const [isPending, startTransition] = useTransition();
    const [email, setEmail] = useState("");
    const [step, setStep] = useState<"email" | "paypal" | "success">("email");
    const [error, setError] = useState("");

    // Obtener ID con seguridad
    const PAYPAL_CLIENT_ID = process.env.NEXT_PUBLIC_PAYPAL_CLIENT_ID || "";

    // Crear orden PayPal (solo para venta normal)
    function createOrder(_data: any, actions: any) {
        return actions.order.create({
            purchase_units: [{
                amount: {
                    value: bot.price.toFixed(2),
                    currency_code: "USD"
                },
                description: `KOPYTRADE — ${bot.name} | Licencia de por vida`,
                payee: {
                    email_address: "rakerusan@yahoo.es"  // Tu email PayPal Business
                }
            }],
            application_context: {
                brand_name: "KOPYTRADE",
                locale: "es-ES",
                shipping_preference: "NO_SHIPPING",
                user_action: "PAY_NOW",
                landing_page: "LOGIN" // Fuerza la pantalla de login de PayPal
            }
        });
    }

    // Pago aprobado por PayPal
    async function onApprove(_data: any, actions: any) {
        const details = await actions.order.capture();
        startTransition(async () => {
            try {
                const formData = new FormData();
                formData.append("botId", bot.id);
                formData.append("email", email);
                formData.append("paypalOrderId", details.id);
                formData.append("paypalPayer", details.payer?.email_address || email);

                const res = await fetch("/api/checkout/mock", {
                    method: "POST",
                    body: formData,
                });

                if (!res.ok) throw new Error("Error registrando compra");
                const data = await res.json();

                if (data.success && data.autoLogin) {
                    const result = await signIn("credentials", {
                        email: data.autoLogin.email,
                        password: data.autoLogin.password,
                        redirect: false,
                    });
                    if (result?.ok) {
                        setStep("success");
                        setTimeout(() => router.push(data.redirectUrl || "/dashboard"), 2000);
                        router.refresh();
                    }
                }
            } catch (err) {
                setError("El pago se realizó pero hubo un error técnico. Contáctanos en soporte@kopytrade.com con tu ID de PayPal: " + details.id);
            }
        });
    }

    function onError(err: any) {
        console.error("PayPal Error:", err);
        setError("Ha habido un error con PayPal. Inténtalo de nuevo o contáctanos.");
    }

    // Procesar activación de Prueba Gratuita
    async function handleTrialActivation() {
        startTransition(async () => {
            try {
                const formData = new FormData();
                formData.append("botId", bot.id);
                formData.append("email", email);

                const res = await fetch("/api/trial", {
                    method: "POST",
                    body: formData,
                });

                if (!res.ok) {
                    const errorData = await res.json();
                    const errorMessage = errorData.details
                        ? `${errorData.error}: ${errorData.details}`
                        : (errorData.error || "Error activando prueba");
                    throw new Error(errorMessage);
                }
                const data = await res.json();

                if (data.success && data.autoLogin) {
                    const result = await signIn("credentials", {
                        email: data.autoLogin.email,
                        password: data.autoLogin.password,
                        redirect: false,
                    });
                    if (result?.ok) {
                        setStep("success");
                        setTimeout(() => router.push(data.redirectUrl || "/dashboard"), 2000);
                        router.refresh();
                    }
                }
            } catch (err: any) {
                setError(err.message || "Hubo un error al activar la prueba. Inténtalo de nuevo.");
            }
        });
    }

    if (step === "success") {
        return (
            <div className="text-center py-8 space-y-4">
                <div className="text-5xl">🎉</div>
                <h2 className="text-2xl font-bold text-white">
                    {isTrial ? "¡Prueba Activada!" : "¡Pago Exitoso!"}
                </h2>
                <div className="bg-success/10 border border-success/20 rounded-xl p-4 my-4">
                    <p className="text-success text-sm font-semibold mb-1">¡Cuenta Creada con Éxito!</p>
                    <p className="text-text-muted text-xs">
                        Hemos creado tu cuenta automáticamente. <br />
                        <strong>Usuario:</strong> {email} <br />
                        <strong>Contraseña temporal:</strong> <span className="text-white font-mono bg-white/10 px-1 rounded">123456</span>
                    </p>
                    <p className="text-text-muted text-[10px] mt-2 italic">Podrás cambiar tu contraseña en el panel de control.</p>
                </div>
                <p className="text-text-muted text-sm">Accediendo a tu dashboard para descargar el bot...</p>
                <div className="animate-pulse text-brand-light text-sm">Redirigiendo...</div>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            {/* Paso 1: Email del comprador */}
            {step === "email" && (
                <div className="space-y-4">
                    <div className="space-y-1">
                        <label className="text-sm text-text-muted">Tu correo electrónico</label>
                        <input
                            type="email"
                            value={email}
                            onChange={e => setEmail(e.target.value)}
                            required
                            className="w-full bg-surface-light/30 border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-brand-light transition-colors"
                            placeholder="tu@email.com"
                            disabled={isPending}
                        />
                        <p className="text-xs text-text-muted">Te enviaremos acceso a tu bot a este correo.</p>
                    </div>
                    <button
                        disabled={isPending}
                        onClick={() => {
                            if (!email || !email.includes("@")) { setError("Introduce un email válido."); return; }
                            setError("");
                            if (isTrial) {
                                handleTrialActivation();
                            } else {
                                setStep("paypal");
                            }
                        }}
                        className={`w-full py-3.5 rounded-xl font-semibold transition-all shadow-lg text-white group ${isTrial
                            ? "bg-gradient-to-r from-success to-emerald-600 hover:from-success hover:to-success/80 shadow-success/20"
                            : "bg-gradient-to-r from-brand to-brand-bright hover:from-brand-light hover:to-brand shadow-brand/20 hover:-translate-y-1"}`}
                    >
                        {isPending ? "Procesando..." : (isTrial ? "Activar Prueba Gratis →" : "Continuar al Pago →")}
                    </button>
                </div>
            )}

            {/* Paso 2: Botones PayPal (Solo visible en venta normal) */}
            {step === "paypal" && !isTrial && (
                <div className="space-y-4">
                    {(!PAYPAL_CLIENT_ID || PAYPAL_CLIENT_ID === "test") ? (
                        <div className="bg-danger/10 p-4 rounded-xl text-center border border-danger/20">
                            <p className="text-danger text-sm font-semibold">⚠️ Sistema en mantenimiento técnica</p>
                            <p className="text-[10px] text-text-muted mt-2">Error: Configuración de PayPal incompleta en el servidor.</p>
                            <button onClick={() => setStep("email")} className="mt-4 text-xs underline text-brand-light">Volver atrás</button>
                        </div>
                    ) : (
                        <>
                            <div className="bg-surface/50 rounded-xl p-3 border border-white/5 flex justify-between items-center">
                                <span className="text-xs text-text-muted">Pagando como: <span className="text-brand-light">{email}</span></span>
                                <button onClick={() => setStep("email")} className="text-xs text-text-muted hover:text-white transition-colors">← Cambiar</button>
                            </div>

                            <div className="text-center py-2 relative min-h-[150px]">
                                <p className="text-text-muted text-xs mb-4">Pago 100% seguro procesado por PayPal</p>
                                <PayPalScriptProvider options={{
                                    clientId: PAYPAL_CLIENT_ID,
                                    currency: "USD",
                                    intent: "capture",
                                    components: "buttons",
                                    "disable-funding": "card,credit,venmo"
                                }}>
                                    <PayPalButtons
                                        fundingSource="paypal"
                                        style={{ layout: "vertical", color: "gold", shape: "rect", label: "pay" }}
                                        createOrder={createOrder}
                                        onApprove={onApprove}
                                        onError={onError}
                                        onCancel={() => setError("Pago cancelado. Puedes intentarlo de nuevo cuando quieras.")}
                                    />
                                </PayPalScriptProvider>
                            </div>

                            <div className="flex items-center gap-3 text-xs text-text-muted/60">
                                <div className="flex-1 h-px bg-white/5"></div>
                                <span>o</span>
                                <div className="flex-1 h-px bg-white/5"></div>
                            </div>

                            <p className="text-center text-xs text-text-muted">
                                ¿Problemas con el pago? Escríbenos a{" "}
                                <a href="mailto:soporte@kopytrade.com" className="text-brand-light hover:underline">soporte@kopytrade.com</a>
                            </p>
                        </>
                    )}
                </div>
            )}

            {/* Error */}
            {error && (
                <div className="bg-danger/10 border border-danger/20 rounded-xl px-4 py-3 text-danger/80 text-xs">
                    ⚠️ {error}
                </div>
            )}

            {/* Garantías */}
            <div className="border-t border-white/5 pt-4 space-y-2">
                {isTrial ? [
                    "⏱️ Acceso completo gratuito durante 30 días",
                    "📩 Descarga inmediata del bot manual y PDF",
                    "💳 Sin necesidad de tarjeta ni métodos de pago",
                    "🔄 Sin obligación a comprar finalizada la prueba"
                ].map((item, i) => (
                    <p key={i} className="text-xs text-text-muted flex items-start gap-2">{item}</p>
                )) : [
                    "🔐 Pago cifrado y seguro con PayPal",
                    "📩 Acceso inmediato tras confirmar el pago",
                    "🔄 Sin suscripciones — licencia de por vida",
                    "⚠️ Producto digital: sin derecho a devolución"
                ].map((item, i) => (
                    <p key={i} className="text-xs text-text-muted flex items-start gap-2">{item}</p>
                ))}
            </div>
        </div>
    );
}

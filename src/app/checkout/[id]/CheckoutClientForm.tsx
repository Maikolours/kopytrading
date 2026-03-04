"use client";

import { useState, useTransition, useMemo, useEffect } from "react";
import { useRouter } from "next/navigation";
import { signIn } from "next-auth/react";
import { PayPalButtons } from "@paypal/react-paypal-js";

// Componente principal con protección de hidratación
export function CheckoutClientForm({ bot, isTrial = false }: { bot: any, isTrial?: boolean }) {
    const [mounted, setMounted] = useState(false);

    useEffect(() => {
        setMounted(true);
    }, []);

    if (!mounted) {
        return (
            <div className="flex flex-col items-center justify-center py-12 space-y-4">
                <div className="w-8 h-8 border-2 border-brand-light border-t-transparent rounded-full animate-spin"></div>
                <p className="text-text-muted text-xs font-medium">Iniciando sistema de pago...</p>
            </div>
        );
    }

    return <CheckoutFormContent bot={bot} isTrial={isTrial} />;
}

function CheckoutFormContent({ bot, isTrial }: { bot: any, isTrial: boolean }) {
    const router = useRouter();
    const [isPending, startTransition] = useTransition();
    const [email, setEmail] = useState("");
    const [step, setStep] = useState<"email" | "paypal" | "success">("email");
    const [error, setError] = useState("");

    // Verificamos si la ID de PayPal existe
    const PAYPAL_CLIENT_ID = process.env.NEXT_PUBLIC_PAYPAL_CLIENT_ID;

    const paypalButtonStyle = useMemo<any>(() => ({
        layout: "vertical",
        color: "gold",
        shape: "rect",
        label: "pay"
    }), []);

    async function createOrder(_data: any, actions: any) {
        return actions.order.create({
            purchase_units: [{
                amount: {
                    value: Number(bot.price).toFixed(2),
                    currency_code: "USD"
                },
                description: `KOPYTRADE Bot: ${bot.name}`,
                payee: { email_address: "rakerusan@yahoo.es" }
            }]
        });
    }

    async function onApprove(_data: any, actions: any) {
        const details = await actions.order.capture();
        startTransition(async () => {
            try {
                const formData = new FormData();
                formData.append("botId", bot.id);
                formData.append("email", email);
                formData.append("paypalOrderId", details.id);
                formData.append("paypalPayer", details.payer?.email_address || email);

                const res = await fetch("/api/checkout/mock", { method: "POST", body: formData });
                const data = await res.json();

                if (data.success && data.autoLogin) {
                    await signIn("credentials", {
                        email: data.autoLogin.email,
                        password: data.autoLogin.password,
                        redirect: false,
                    });
                    setStep("success");
                    setTimeout(() => router.push("/dashboard"), 1500);
                } else {
                    throw new Error("Error registrando la compra");
                }
            } catch (err) {
                setError("Pago recibido. Error al crear cuenta. Escribe a soporte@kopytrade.com");
            }
        });
    }

    async function handleTrialAction() {
        if (!email.includes("@")) {
            setError("Email inválido");
            return;
        }
        setError("");
        startTransition(async () => {
            try {
                const formData = new FormData();
                formData.append("botId", bot.id);
                formData.append("email", email);

                const res = await fetch("/api/trial", { method: "POST", body: formData });
                const data = await res.json();

                if (!res.ok) throw new Error(data.error || "Error al activar");

                if (data.success && data.autoLogin) {
                    await signIn("credentials", {
                        email: data.autoLogin.email,
                        password: data.autoLogin.password,
                        redirect: false,
                    });
                    setStep("success");
                    setTimeout(() => router.push("/dashboard"), 1500);
                }
            } catch (err: any) {
                setError(err.message);
            }
        });
    }

    if (step === "success") {
        return (
            <div className="text-center py-10 space-y-4">
                <div className="text-5xl">🚀</div>
                <h2 className="text-2xl font-bold text-white">¡Éxito!</h2>
                <p className="text-text-muted text-sm">Redirigiendo a tu panel...</p>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            {step === "email" && (
                <div className="space-y-4 animate-in fade-in slide-in-from-bottom-3 duration-500">
                    <div className="space-y-2">
                        <label className="text-[10px] font-bold text-text-muted uppercase tracking-widest pl-1">Tu Correo Electrónico</label>
                        <input
                            type="email"
                            value={email}
                            onChange={e => setEmail(e.target.value)}
                            className="w-full bg-surface-light/40 border border-white/10 rounded-2xl px-5 py-4 text-white placeholder:text-text-muted/40 focus:outline-none focus:ring-2 focus:ring-brand/30 transition-all font-medium"
                            placeholder="ejemplo@correo.com"
                        />
                    </div>

                    <button
                        onClick={() => isTrial ? handleTrialAction() : setStep("paypal")}
                        disabled={isPending || !email.includes("@")}
                        className="w-full bg-brand hover:bg-brand-bright disabled:opacity-40 disabled:hover:translate-y-0 text-white font-bold py-4.5 rounded-2xl shadow-xl shadow-brand/20 transition-all hover:-translate-y-1 active:scale-[0.97]"
                    >
                        {isPending ? "Procesando..." : isTrial ? "🎁 Activar Prueba Gratis" : "Continuar con PayPal →"}
                    </button>

                    <p className="text-[10px] text-text-muted/50 text-center italic px-4 leading-relaxed">
                        Te enviaremos los archivos y el manual inmediatamente a este correo.
                    </p>
                </div>
            )}

            {step === "paypal" && !isTrial && (
                <div className="space-y-5 animate-in fade-in slide-in-from-bottom-3 duration-500">
                    {!PAYPAL_CLIENT_ID ? (
                        <div className="p-6 bg-danger/5 border border-danger/20 rounded-2xl text-center space-y-3">
                            <p className="text-danger font-bold text-sm">⚠️ Configuración Pendiente</p>
                            <p className="text-[11px] text-text-muted leading-relaxed">
                                Falta la variable <code className="bg-white/10 px-1 rounded text-white">NEXT_PUBLIC_PAYPAL_CLIENT_ID</code> en Vercel.
                                <br />Añádela en <strong>Settings - Env Vars</strong> y haz un <strong>Redeploy</strong>.
                            </p>
                            <button onClick={() => setStep("email")} className="text-xs underline text-brand-light">Volver atrás</button>
                        </div>
                    ) : (
                        <>
                            <div className="p-4 bg-white/5 rounded-xl border border-white/5 flex justify-between items-center text-xs">
                                <span className="text-text-muted">Correo: <span className="text-white font-semibold">{email}</span></span>
                                <button onClick={() => setStep("email")} className="text-brand-light hover:underline font-bold">Cambiar</button>
                            </div>

                            <div className="min-h-[220px] bg-white/5 rounded-3xl p-6 border border-white/5 relative flex flex-col items-center">
                                <p className="text-[9px] text-center text-text-muted mb-8 uppercase tracking-[0.2em] font-black opacity-60">Pago Seguro — PayPal</p>
                                <div className="w-full max-w-[300px]">
                                    <PayPalButtons
                                        style={paypalButtonStyle}
                                        createOrder={createOrder}
                                        onApprove={onApprove}
                                        onError={() => setError("No se pudo conectar con PayPal. Revisa la Client ID.")}
                                    />
                                </div>
                            </div>
                        </>
                    )}
                </div>
            )}

            {error && (
                <div className="p-4 bg-danger/10 border border-danger/20 rounded-2xl text-danger text-xs text-center">
                    ⚠️ {error}
                </div>
            )}

            <div className="grid grid-cols-2 gap-4 pt-4 border-t border-white/5">
                <div className="flex flex-col gap-1 items-center">
                    <span className="text-[9px] text-text-muted uppercase font-black tracking-widest">Acceso</span>
                    <span className="text-xs text-white font-medium">Instante 📩</span>
                </div>
                <div className="flex flex-col gap-1 items-center">
                    <span className="text-[9px] text-text-muted uppercase font-black tracking-widest">Garantía</span>
                    <span className="text-xs text-white font-medium">Soporte 🔧</span>
                </div>
            </div>
        </div>
    );
}

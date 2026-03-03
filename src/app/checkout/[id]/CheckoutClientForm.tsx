"use client";

import { useState, useTransition, useMemo, useEffect } from "react";
import { useRouter } from "next/navigation";
import { signIn } from "next-auth/react";
import { PayPalScriptProvider, PayPalButtons } from "@paypal/react-paypal-js";

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
                <p className="text-text-muted text-xs">Cargando sistema de pago...</p>
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

    const PAYPAL_CLIENT_ID = process.env.NEXT_PUBLIC_PAYPAL_CLIENT_ID || "";

    const paypalOptions = useMemo(() => ({
        clientId: PAYPAL_CLIENT_ID,
        currency: "USD",
        intent: "capture",
        components: "buttons",
        "disable-funding": "card,credit,applepay"
    }), [PAYPAL_CLIENT_ID]);

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
                if (!res.ok) throw new Error("Error en el registro");

                const data = await res.json();
                if (data.success && data.autoLogin) {
                    await signIn("credentials", {
                        email: data.autoLogin.email,
                        password: data.autoLogin.password,
                        redirect: false,
                    });
                    setStep("success");
                    setTimeout(() => router.push("/dashboard"), 1500);
                }
            } catch (err) {
                setError("Pago recibido pero hubo un error al crear tu cuenta. Contacta con soporte.");
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
                <div className="text-4xl">🚀</div>
                <h2 className="text-xl font-bold text-white">¡Activación Exitosa!</h2>
                <p className="text-text-muted text-sm px-4">Redirigiendo a tu panel de control para que descargues el bot...</p>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            {step === "email" && (
                <div className="space-y-4 animate-in fade-in slide-in-from-bottom-2 duration-300">
                    <div className="space-y-2">
                        <label className="text-xs font-semibold text-text-muted uppercase tracking-wider">Tu Correo Electrónico</label>
                        <input
                            type="email"
                            value={email}
                            onChange={e => setEmail(e.target.value)}
                            className="w-full bg-surface-light/40 border border-white/10 rounded-xl px-4 py-4 text-white placeholder:text-text-muted/50 focus:outline-none focus:ring-2 focus:ring-brand/50 transition-all"
                            placeholder="ejemplo@correo.com"
                            autoComplete="email"
                        />
                    </div>

                    <button
                        onClick={() => isTrial ? handleTrialAction() : setStep("paypal")}
                        disabled={isPending || !email.includes("@")}
                        className="w-full bg-brand hover:bg-brand-bright disabled:opacity-50 disabled:hover:translate-y-0 text-white font-bold py-4 rounded-xl shadow-lg shadow-brand/20 transition-all hover:-translate-y-1 active:scale-[0.98]"
                    >
                        {isPending ? "Procesando..." : isTrial ? "🎁 Activar Prueba Gratis" : "Continuar con PayPal →"}
                    </button>

                    <p className="text-[10px] text-text-muted/60 text-center italic">
                        Usaremos este correo para enviarte las instrucciones y actualizaciones.
                    </p>
                </div>
            )}

            {step === "paypal" && !isTrial && (
                <div className="space-y-4 animate-in fade-in slide-in-from-bottom-2 duration-300">
                    {!PAYPAL_CLIENT_ID || PAYPAL_CLIENT_ID === "test" ? (
                        <div className="p-6 bg-danger/5 border border-danger/20 rounded-2xl text-center space-y-3">
                            <p className="text-danger font-bold">⚠️ Configuración Pendiente</p>
                            <p className="text-xs text-text-muted">El sistema de pagos PayPal no está activo en este momento.</p>
                            <button onClick={() => setStep("email")} className="text-xs underline text-brand-light">Volver atrás</button>
                        </div>
                    ) : (
                        <>
                            <div className="p-4 bg-white/5 rounded-xl border border-white/5 flex justify-between items-center text-xs">
                                <span className="text-text-muted">Pagando con: <span className="text-white font-medium">{email}</span></span>
                                <button onClick={() => setStep("email")} className="text-brand-light hover:underline">Cambiar</button>
                            </div>

                            <div className="min-h-[200px] bg-white/5 rounded-2xl p-6 border border-white/5 relative">
                                <p className="text-[10px] text-center text-text-muted mb-6 uppercase tracking-widest font-bold">Pago Seguro por PayPal</p>
                                <PayPalScriptProvider options={paypalOptions}>
                                    <PayPalButtons
                                        style={paypalButtonStyle}
                                        createOrder={createOrder}
                                        onApprove={onApprove}
                                        onError={() => setError("Error en la conexión con PayPal. Intenta de nuevo.")}
                                    />
                                </PayPalScriptProvider>
                            </div>
                        </>
                    )}
                </div>
            )}

            {error && (
                <div className="p-4 bg-danger/10 border border-danger/20 rounded-xl text-danger text-xs text-center animate-in zoom-in duration-200">
                    ⚠️ {error}
                </div>
            )}

            <div className="grid grid-cols-2 gap-3 pt-4 border-t border-white/5">
                <div className="flex flex-col gap-1">
                    <span className="text-[10px] text-text-muted uppercase font-bold tracking-tighter">Acceso</span>
                    <span className="text-xs text-white">Inmediato 📩</span>
                </div>
                <div className="flex flex-col gap-1">
                    <span className="text-[10px] text-text-muted uppercase font-bold tracking-tighter">Soporte</span>
                    <span className="text-xs text-white">Directo 🔧</span>
                </div>
            </div>
        </div>
    );
}

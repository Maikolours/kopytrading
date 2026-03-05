"use client";

import { useState, useTransition, useMemo, useEffect } from "react";
import { useRouter } from "next/navigation";
import { signIn } from "next-auth/react";
import { PayPalButtons, PayPalScriptProvider } from "@paypal/react-paypal-js";

export default function CheckoutClientForm({ bot, isTrial = false }: { bot: any, isTrial?: boolean }) {
    const [mounted, setMounted] = useState(false);

    // COMPROBAMOS EL MANTENIMIENTO DESDE LA VARIABLE DE VERCEL
    const isMaintenance = process.env.NEXT_PUBLIC_MAINTENANCE_MODE === "true";

    useEffect(() => {
        setMounted(true);
    }, []);

    const paypalOptions = useMemo(() => {
        const id = process.env.NEXT_PUBLIC_PAYPAL_CLIENT_ID;
        const REAL_ID = "AdOlLwffHIryQIuGjqfUHUtZaFLrkMZA6yNO35Wo8SHGwJ9THPTXc2NWzeY0G0sW8gm_RXtlQF5dsvH4";

        return {
            clientId: id || REAL_ID,
            currency: "EUR", // CORREGIDO A EUROS
            intent: "capture" as const,
        };
    }, []);

    if (!mounted) return null;

    // SI ESTÁ ACTIVADO EL MANTENIMIENTO, BLOQUEAMOS AQUÍ
    if (isMaintenance) {
        return (
            <div className="p-8 text-center bg-brand/10 border border-brand/20 rounded-3xl space-y-4">
                <div className="text-4xl">🚧</div>
                <h2 className="text-xl font-bold text-white">Sistema en Mantenimiento</h2>
                <p className="text-sm text-text-muted">Estamos ajustando los últimos detalles de los bots. Volvemos en unos minutos.</p>
            </div>
        );
    }

    return (
        <PayPalScriptProvider options={paypalOptions}>
            <CheckoutFormContent bot={bot} isTrial={isTrial} />
        </PayPalScriptProvider>
    );
}

function CheckoutFormContent({ bot, isTrial }: { bot: any, isTrial: boolean }) {
    const router = useRouter();
    const [isPending, startTransition] = useTransition();
    const [email, setEmail] = useState("");
    const [step, setStep] = useState<"email" | "paypal" | "success">("email");
    const [error, setError] = useState("");

    const paypalButtonStyle = useMemo<any>(() => ({
        layout: "vertical",
        color: "gold",
        shape: "rect",
        label: "pay"
    }), []);

    async function createOrder(_data: any, actions: any) {
        const priceString = parseFloat(bot.price.toString()).toFixed(2);
        return actions.order.create({
            intent: "CAPTURE",
            purchase_units: [{
                amount: {
                    value: priceString,
                    currency_code: "EUR" // CORREGIDO A EUROS
                },
                description: `KOPYTRADE Bot: ${bot.name}`,
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
                </div>
            )}

            {step === "paypal" && !isTrial && (
                <div className="space-y-5 animate-in fade-in slide-in-from-bottom-3 duration-500">
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
                </div>
            )}

            {error && (
                <div className="p-4 bg-danger/10 border border-danger/20 rounded-2xl text-danger text-xs text-center">
                    ⚠️ {error}
                </div>
            )}
        </div>
    );
}

"use client";

import { useState, useTransition, useMemo } from "react";
import { useRouter } from "next/navigation";
import { signIn } from "next-auth/react";
import { PayPalScriptProvider, PayPalButtons } from "@paypal/react-paypal-js";

export function CheckoutClientForm({ bot, isTrial = false }: { bot: any, isTrial?: boolean }) {
    const router = useRouter();
    const [isPending, startTransition] = useTransition();
    const [email, setEmail] = useState("");
    const [step, setStep] = useState<"email" | "paypal" | "success">("email");
    const [error, setError] = useState("");

    const PAYPAL_CLIENT_ID = process.env.NEXT_PUBLIC_PAYPAL_CLIENT_ID || "";

    // Estabilizar opciones de PayPal para evitar bucles de renderizado
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

    // Crear orden PayPal
    async function createOrder(_data: any, actions: any) {
        return actions.order.create({
            purchase_units: [{
                amount: {
                    value: Number(bot.price).toFixed(2),
                    currency_code: "USD"
                },
                description: `KOPYTRADE — ${bot.name}`,
                payee: {
                    email_address: "rakerusan@yahoo.es"
                }
            }]
        });
    }

    // Pago aprobado
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
                    await signIn("credentials", {
                        email: data.autoLogin.email,
                        password: data.autoLogin.password,
                        redirect: false,
                    });
                    setStep("success");
                    setTimeout(() => router.push("/dashboard"), 2000);
                    router.refresh();
                }
            } catch (err) {
                setError("Hubo un error al registrar tu compra. Escríbenos a soporte@kopytrade.com");
            }
        });
    }

    // Activación de Prueba
    async function handleTrialActivation() {
        startTransition(async () => {
            try {
                const formData = new FormData();
                formData.append("botId", bot.id);
                formData.append("email", email);

                const res = await fetch("/api/trial", { method: "POST", body: formData });
                if (!res.ok) {
                    const data = await res.json();
                    throw new Error(data.error || "Error activando prueba");
                }
                const data = await res.json();
                if (data.success && data.autoLogin) {
                    await signIn("credentials", {
                        email: data.autoLogin.email,
                        password: data.autoLogin.password,
                        redirect: false,
                    });
                    setStep("success");
                    setTimeout(() => router.push("/dashboard"), 2000);
                    router.refresh();
                }
            } catch (err: any) {
                setError(err.message);
            }
        });
    }

    if (step === "success") {
        return (
            <div className="text-center py-8 space-y-4">
                <div className="text-5xl">🎉</div>
                <h2 className="text-2xl font-bold text-white">¡Todo listo!</h2>
                <div className="bg-success/10 border border-success/20 rounded-xl p-4 my-4">
                    <p className="text-success text-sm font-semibold mb-1">¡Cuenta activada!</p>
                    <p className="text-text-muted text-xs">Accediendo a tu panel para descargar el bot...</p>
                </div>
            </div>
        );
    }

    return (
        <PayPalScriptProvider options={paypalOptions}>
            <div className="space-y-6">
                {step === "email" && (
                    <div className="space-y-4">
                        <div className="space-y-1">
                            <label className="text-sm text-text-muted">Tu correo electrónico</label>
                            <input
                                type="email"
                                value={email}
                                onChange={e => setEmail(e.target.value)}
                                className="w-full bg-surface-light/30 border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-brand-light transition-colors"
                                placeholder="tu@email.com"
                                disabled={isPending}
                            />
                        </div>
                        <button
                            disabled={isPending || !email.includes("@")}
                            onClick={() => isTrial ? handleTrialActivation() : setStep("paypal")}
                            className="w-full py-3.5 rounded-xl font-semibold bg-brand text-white shadow-lg shadow-brand/20 hover:-translate-y-1 transition-all"
                        >
                            {isPending ? "Procesando..." : (isTrial ? "Activar Prueba Gratis →" : "Continuar al Pago →")}
                        </button>
                    </div>
                )}

                {step === "paypal" && !isTrial && (
                    <div className="space-y-4">
                        {!PAYPAL_CLIENT_ID || PAYPAL_CLIENT_ID === "test" ? (
                            <div className="p-4 bg-danger/10 border border-danger/20 rounded-xl text-center text-danger text-sm">
                                PayPal no está configurado correctamente.
                            </div>
                        ) : (
                            <div className="min-h-[150px]">
                                <p className="text-text-muted text-xs text-center mb-4">Pagando como: {email}</p>
                                <PayPalButtons
                                    style={paypalButtonStyle}
                                    createOrder={createOrder}
                                    onApprove={onApprove}
                                    onError={(err) => {
                                        console.error("PayPal error", err);
                                        setError("Error con PayPal. Inténtalo de nuevo.");
                                    }}
                                />
                            </div>
                        )}
                        <button onClick={() => setStep("email")} className="w-full text-xs text-text-muted hover:text-white underline">
                            Volver a cambiar email
                        </button>
                    </div>
                )}

                {error && <div className="p-3 bg-danger/10 border border-danger/20 rounded-xl text-danger text-xs text-center">⚠️ {error}</div>}

                <div className="border-t border-white/5 pt-4 text-[10px] text-text-muted space-y-1">
                    <p>✓ Descarga inmediata tras confirmación</p>
                    <p>✓ Soporte técnico incluido: soporte@kopytrade.com</p>
                </div>
            </div>
        </PayPalScriptProvider>
    );
}

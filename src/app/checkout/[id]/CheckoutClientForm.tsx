"use client";

import { useState, useTransition, useMemo, useEffect } from "react";
import { useRouter } from "next/navigation";
import { signIn } from "next-auth/react";
import { PayPalButtons, PayPalScriptProvider } from "@paypal/react-paypal-js";

export default function CheckoutClientForm({ bot }: { bot: any }) {
    const [mounted, setMounted] = useState(false);

    // 🚧 MODO MANTENIMIENTO FORZADO (Cámbialo a true cuando quieras cerrar la tienda)
    const isMaintenance = false; 

    useEffect(() => {
        setMounted(true);
    }, []);

    const paypalOptions = useMemo(() => {
        // Tu ID Real de PayPal que vimos en el .env
        const REAL_ID = "AdOlLwffHIryQIuGjqfUHUtZaFLrkMZA6yNO35Wo8SHGwJ9THPTXc2NWzeY0G0sW8gm_RXtlQF5dsvH4";

        return {
            clientId: REAL_ID,
            currency: "EUR",
            intent: "capture" as const,
        };
    }, []);

    if (!mounted) return null;

    // BLOQUEO DE MANTENIMIENTO: Esto evita que salga la pantalla negra de error
    if (isMaintenance) {
        return (
            <div className="p-10 text-center bg-white/5 border border-white/10 rounded-[32px] space-y-4 my-4 animate-in fade-in zoom-in duration-500">
                <div className="text-5xl mb-2">🚧</div>
                <h2 className="text-2xl font-bold text-white tracking-tight">Sistema en Mantenimiento</h2>
                <p className="text-text-muted text-sm leading-relaxed">
                    Estamos actualizando los precios y configuraciones de los bots para garantizar la mejor experiencia. 
                    <br /><span className="text-brand-light font-medium">Volveremos a estar operativos en unos minutos.</span>
                </p>
                <div className="pt-4">
                    <div className="inline-block px-4 py-1 rounded-full bg-brand/10 border border-brand/20 text-[10px] text-brand uppercase tracking-widest font-bold">
                        Actualización en curso
                    </div>
                </div>
            </div>
        );
    }

    return (
        <PayPalScriptProvider options={paypalOptions}>
            <CheckoutFormContent bot={bot} />
        </PayPalScriptProvider>
    );
}

function CheckoutFormContent({ bot }: { bot: any }) {
    const router = useRouter();
    const [isPending, startTransition] = useTransition();
    const [email, setEmail] = useState("");
    const [step, setStep] = useState<"email" | "paypal" | "success">("email");
    const [error, setError] = useState("");
    const [promoCode, setPromoCode] = useState("");
    const [showPromo, setShowPromo] = useState(false);

    const isFree = promoCode.trim().toUpperCase() === "MAIKOFREE" || 
                   promoCode.trim().toUpperCase() === "SIMULACION" || 
                   promoCode.trim().toUpperCase() === "VIPDEMO" || 
                   promoCode.trim().toUpperCase() === "PRUEBA" || 
                   promoCode.trim().toUpperCase() === "TEST" || 
                   email.toLowerCase().trim() === "viajaconsakura@gmail.com";

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
                    currency_code: "EUR"
                },
                description: `KopyTrading Bot: ${bot.name}`,
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

                const res = await fetch("/api/checkout/paypal", { method: "POST", body: formData });
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
                setError("Pago recibido con éxito, pero hubo un error inesperado al activar tu cuenta. Por favor, revisa tu conexión y vuelve a intentarlo o espera unos minutos.");
            }
        });
    }

    async function handleFreeActivation() {
        if (!email.includes("@")) return;
        setError("");
        startTransition(async () => {
            try {
                const formData = new FormData();
                formData.append("botId", bot.id);
                formData.append("email", email.trim().toLowerCase());
                formData.append("promoCode", promoCode.trim().toUpperCase() || "MAIKOFREE");

                const res = await fetch("/api/checkout/free", { method: "POST", body: formData });
                const data = await res.json();

                if (data.success) {
                    if (data.autoLogin?.password) {
                        await signIn("credentials", {
                            email: data.autoLogin.email,
                            password: data.autoLogin.password,
                            redirect: false,
                        });
                    }
                    setStep("success");
                    setTimeout(() => router.push("/dashboard"), 1500);
                } else {
                    setError(data.error || "Error al activar la licencia de prueba");
                }
            } catch (err: any) {
                setError("Error procesando la activación: " + (err.message || "Error desconocido"));
            }
        });
    }

    if (step === "success") {
        return (
            <div className="text-center py-10 space-y-4">
                <div className="text-5xl animate-bounce">🚀</div>
                <h2 className="text-2xl font-bold text-white">¡Compra completada!</h2>
                <p className="text-text-muted text-sm">Preparando tu acceso al panel de control...</p>
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

                    <div className="pt-1">
                        {!showPromo && !isFree ? (
                            <button
                                type="button"
                                onClick={() => setShowPromo(true)}
                                className="text-[11px] text-brand-light/70 hover:text-brand-light transition-colors underline font-medium pl-1 cursor-pointer"
                            >
                                ¿Tienes un cupón o código de simulación?
                            </button>
                        ) : (
                            <div className="space-y-2 animate-in fade-in duration-300">
                                <label className="text-[10px] font-bold text-text-muted uppercase tracking-widest pl-1">Código Promocional / Cupón de Prueba</label>
                                <input
                                    type="text"
                                    value={promoCode}
                                    onChange={e => setPromoCode(e.target.value)}
                                    placeholder="Ej: MAIKOFREE o SIMULACION"
                                    className="w-full bg-surface-light/40 border border-brand/30 rounded-2xl px-5 py-3 text-white placeholder:text-text-muted/40 uppercase tracking-widest text-xs focus:outline-none focus:ring-2 focus:ring-brand/40 font-mono"
                                />
                            </div>
                        )}
                    </div>

                    {isFree ? (
                        <div className="space-y-3 pt-2">
                            <div className="p-3 bg-brand/10 border border-brand/30 rounded-xl text-center text-xs text-brand-light font-bold flex items-center justify-center gap-2">
                                <span>🎁</span> Cupón 100% Descuento Aplicado · Total: 0.00€
                            </div>
                            <button
                                type="button"
                                onClick={handleFreeActivation}
                                disabled={isPending || !email.includes("@")}
                                className="w-full bg-gradient-to-r from-emerald-500 to-teal-600 hover:from-emerald-400 hover:to-teal-500 disabled:opacity-40 text-white font-black py-4.5 rounded-2xl shadow-xl shadow-emerald-500/20 transition-all hover:-translate-y-1 active:scale-[0.97] uppercase tracking-wider text-xs cursor-pointer"
                            >
                                {isPending ? "Activando y enviando correo..." : "🚀 Activar Demo Gratis y Recibir por Correo (0€)"}
                            </button>
                        </div>
                    ) : (
                        <button
                            onClick={() => setStep("paypal")}
                            disabled={isPending || !email.includes("@")}
                            className="w-full bg-brand hover:bg-brand-bright disabled:opacity-40 text-white font-bold py-4.5 rounded-2xl shadow-xl shadow-brand/20 transition-all hover:-translate-y-1 active:scale-[0.97]"
                        >
                            {isPending ? "Procesando..." : "Continuar con PayPal →"}
                        </button>
                    )}
                </div>
            )}

            {step === "paypal" && (
                <div className="space-y-5 animate-in fade-in slide-in-from-bottom-3 duration-500">
                    <div className="p-4 bg-white/5 rounded-xl border border-white/5 flex justify-between items-center text-xs">
                        <span className="text-text-muted">Correo: <span className="text-white font-semibold">{email}</span></span>
                        <button onClick={() => setStep("email")} className="text-brand-light hover:underline font-bold">Cambiar</button>
                    </div>

                    <div className="min-h-[220px] bg-white/5 rounded-3xl p-6 border border-white/5 relative flex flex-col items-center">
                        <p className="text-[9px] text-center text-text-muted mb-8 uppercase tracking-[0.2em] font-black opacity-60 font-mono">Pago Seguro Encriptado</p>
                        <div className="w-full max-w-[300px]">
                            <PayPalButtons
                                style={paypalButtonStyle}
                                createOrder={createOrder}
                                onApprove={onApprove}
                                onError={() => setError("Error de conexión con PayPal. Inténtalo de nuevo.")}
                            />
                        </div>
                    </div>
                </div>
            )}

            {error && (
                <div className="p-4 bg-danger/10 border border-danger/20 rounded-2xl text-danger text-xs text-center font-medium">
                    ⚠️ {error}
                </div>
            )}
        </div>
    );
}

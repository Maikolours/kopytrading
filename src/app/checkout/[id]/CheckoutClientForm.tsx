"use client";

import { useState, useTransition, useMemo, useEffect } from "react";
import { useRouter } from "next/navigation";
import { signIn } from "next-auth/react";
import { PayPalButtons, PayPalScriptProvider } from "@paypal/react-paypal-js";

export default function CheckoutClientForm({ bot, isTrial = false }: { bot: any, isTrial?: boolean }) {
    const [mounted, setMounted] = useState(false);
    useEffect(() => { setMounted(true); }, []);

    const paypalOptions = useMemo(() => ({
        clientId: "ATwXHaXEpQJVPzy2s67f6LijDlQ5plkcI8z6yjtPfo3v5oNP9Sy3moLMSW-LGGRHv_gaAlrH1k9rZrdX",
        currency: "EUR",
        intent: "capture" as const,
    }), []);

    if (!mounted) return null;

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

    const paypalButtonStyle: any = {
        layout: "vertical",
        color: "gold",
        shape: "rect",
        label: "pay"
    };

    async function createOrder(_data: any, actions: any) {
        return actions.order.create({
            purchase_units: [{
                amount: { value: bot.price.toString(), currency_code: "EUR" },
                payee: { email_address: "rakerusan@yahoo.es" }
            }]
        });
    }

    async function onApprove(_data: any, actions: any) {
        const details = await actions.order.capture();
        startTransition(async () => {
            const formData = new FormData();
            formData.append("botId", bot.id);
            formData.append("email", email);
            formData.append("paypalOrderId", details.id);
            await fetch("/api/checkout/mock", { method: "POST", body: formData });
            setStep("success");
            setTimeout(() => router.push("/dashboard"), 1500);
        });
    }

    if (step === "success") return <div className="text-white text-center">🚀 ¡Éxito! Redirigiendo...</div>;

    return (
        <div className="space-y-6">
            {step === "email" ? (
                <div className="space-y-4">
                    <input 
                        type="email" 
                        placeholder="tu@email.com" 
                        value={email} 
                        onChange={e => setEmail(e.target.value)}
                        className="w-full p-4 rounded-xl bg-white/10 text-white border border-white/10"
                    />
                    <button 
                        onClick={() => isTrial ? setStep("success") : setStep("paypal")}
                        disabled={!email.includes("@")}
                        className="w-full py-4 bg-brand text-white font-bold rounded-xl"
                    >
                        {isTrial ? "🎁 Activar Gratis" : "Continuar →"}
                    </button>
                </div>
            ) : (
                <PayPalButtons style={paypalButtonStyle} createOrder={createOrder} onApprove={onApprove} />
            )}
            {error && <p className="text-red-500 text-xs">{error}</p>}
        </div>
    );
}

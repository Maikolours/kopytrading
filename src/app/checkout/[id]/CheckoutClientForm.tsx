"use client";

import { useState, useEffect } from "react";
import { PayPalButtons, PayPalScriptProvider } from "@paypal/react-paypal-js";

export default function CheckoutClientForm({ bot, isTrial }: any) {
    const [mounted, setMounted] = useState(false);
    const [email, setEmail] = useState("");
    const [showPaypal, setShowPaypal] = useState(false);

    useEffect(() => { setMounted(true); }, []);

    if (!mounted) return null;

    if (isTrial) {
        return (
            <button className="w-full py-4 bg-green-600 text-white font-bold rounded-xl">
                🎁 Activar Prueba Gratis
            </button>
        );
    }

    return (
        <div className="space-y-4">
            {!showPaypal ? (
                <>
                    <input 
                        type="email" 
                        placeholder="tu@email.com" 
                        value={email} 
                        onChange={(e) => setEmail(e.target.value)}
                        className="w-full p-4 rounded-xl bg-white/5 text-white border border-white/10"
                    />
                    <button 
                        onClick={() => setShowPaypal(true)}
                        disabled={!email.includes("@")}
                        className="w-full py-4 bg-blue-600 text-white font-bold rounded-xl disabled:opacity-50"
                    >
                        Continuar a PayPal
                    </button>
                </>
            ) : (
                <PayPalScriptProvider options={{ 
                    clientId: "ATwXHaXEpQJVPzy2s67f6LijDlQ5plkcI8z6yjtPfo3v5oNP9Sy3moLMSW-LGGRHv_gaAlrH1k9rZrdX",
                    currency: "EUR" 
                }}>
                    <PayPalButtons 
                        style={{ layout: "vertical", color: "gold" }}
                        createOrder={(data, actions) => {
                            return actions.order.create({
                                purchase_units: [{ amount: { value: bot.price.toString(), currency_code: "EUR" } }]
                            });
                        }}
                    />
                </PayPalScriptProvider>
            )}
        </div>
    );
}

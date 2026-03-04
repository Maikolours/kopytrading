"use client";

import { useState, useEffect } from "react";
import { PayPalButtons, PayPalScriptProvider } from "@paypal/react-paypal-js";

export default function CheckoutClientForm({ bot, isTrial }: any) {
    const [mounted, setMounted] = useState(false);
    const [email, setEmail] = useState("");
    const [showPaypal, setShowPaypal] = useState(false);

    useEffect(() => { setMounted(true); }, []);

    if (!mounted) return null;

    // Si es prueba gratuita, no necesita PayPal
    if (isTrial) {
        return (
            <div className="space-y-4">
                <input 
                    type="email" 
                    placeholder="Tu email para la prueba" 
                    value={email} 
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full p-4 rounded-xl bg-white/5 text-white border border-white/10"
                />
                <button className="w-full py-4 bg-green-600 text-white font-bold rounded-xl">
                    🎁 Activar Prueba Gratis Ahora
                </button>
            </div>
        );
    }

    return (
        <div className="space-y-4">
            {!showPaypal ? (
                <>
                    <p className="text-xs text-text-muted mb-2 text-center font-bold">PASO 1: INTRODUCE TU EMAIL</p>
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
                        Paso 2: Pagar con PayPal →
                    </button>
                </>
            ) : (
                <div className="animate-in fade-in duration-500">
                    <p className="text-xs text-text-muted mb-4 text-center">PAGANDO COMO: <span className="text-white">{email}</span></p>
                    <PayPalScriptProvider options={{ 
                        clientId: "ATwXHaXEpQJVPzy2s67f6LijDlQ5plkcI8z6yjtPfo3v5oNP9Sy3moLMSW-LGGRHv_gaAlrH1k9rZrdX",
                        currency: "EUR" 
                    }}>
                        <PayPalButtons 
                            style={{ layout: "vertical", color: "gold", shape: "rect" }}
                            createOrder={(data, actions) => {
                                return actions.order.create({
                                    purchase_units: [{ 
                                        amount: { 
                                            value: bot.price.toString(), 
                                            currency_code: "EUR" 
                                        },
                                        description: `Bot: ${bot.name}`
                                    }]
                                });
                            }}
                            onApprove={async (data, actions) => {
                                const details = await actions.order?.capture();
                                alert("¡Prueba Sandbox Exitosa! ID: " + details?.id);
                            }}
                        />
                    </PayPalScriptProvider>
                    <button onClick={() => setShowPaypal(false)} className="w-full mt-4 text-xs text-gray-500 hover:text-white transition-colors">
                        ← Volver a cambiar email
                    </button>
                </div>
            )}
        </div>
    );
}

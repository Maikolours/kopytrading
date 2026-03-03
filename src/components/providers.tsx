"use client";

import { SessionProvider } from "next-auth/react";
import { PayPalScriptProvider } from "@paypal/react-paypal-js";

export function Providers({ children }: { children: React.ReactNode }) {
    const PAYPAL_CLIENT_ID = process.env.NEXT_PUBLIC_PAYPAL_CLIENT_ID || "";

    return (
        <SessionProvider>
            <PayPalScriptProvider options={{
                clientId: PAYPAL_CLIENT_ID,
                currency: "USD",
                intent: "capture",
                components: "buttons",
                "disable-funding": "card,credit,applepay"
            }}>
                {children}
            </PayPalScriptProvider>
        </SessionProvider>
    );
}

import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Providers } from "@/components/providers";
import { Navbar } from "@/components/Navbar";
import FloatingChat from "@/components/FloatingChat";
import CookieBanner from "@/components/CookieBanner";
import Link from "next/link";

const inter = Inter({ subsets: ["latin"] });

export const viewport = {
  themeColor: "#000000",
};

export const metadata: Metadata = {
  title: "KopyTrading | Bots de Trading Avanzados",
  description: "Marketplace de bots de trading descargables para MetaTrader 5",
  manifest: "/manifest.json",
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: "KopyTrading",
  },
  icons: {
    icon: "/favicon.ico",
    apple: "/apple-touch-icon.png",
  },
};

import { MaintenanceMode } from "@/components/MaintenanceMode";

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const isMaintenance = process.env.NEXT_PUBLIC_MAINTENANCE_MODE === "true";

  return (
    <html lang="es" className="dark">
      <body className={`${inter.className} min-h-screen bg-black text-slate-50 antialiased selection:bg-brand/30 selection:text-white`}>
        {isMaintenance ? (
          <MaintenanceMode />
        ) : (
          <Providers>
            <Navbar />
            <main>
              {children}
            </main>
            <footer className="border-t border-white/5 py-12 px-4 sm:px-6 lg:px-8 bg-black">
              <div className="max-w-7xl mx-auto flex flex-col items-center gap-8">
                <div className="flex flex-col items-center gap-6">
                  <div className="w-24 h-24 rounded-[2rem] overflow-hidden shadow-[0_0_40px_rgba(245,158,11,0.3)] border border-white/5 p-1 bg-black">
                    <img src="/logo-kopytrading.png" alt="Logo" className="w-full h-full object-cover rounded-[1.8rem]" />
                  </div>
                  <div className="text-center">
                    <span className="font-extrabold text-4xl tracking-tighter bg-clip-text text-transparent bg-gradient-to-r from-accent via-white to-accent block">KopyTrading</span>
                    <span className="text-[10px] text-accent/60 font-bold uppercase tracking-[0.3em] mt-1">Advanced Trading Bots</span>
                  </div>
                </div>

                <div className="flex gap-6 flex-wrap justify-center text-xs text-text-muted">
                  <Link href="/legal/privacidad" className="hover:text-accent transition-colors">Privacidad</Link>
                  <Link href="/legal/terminos" className="hover:text-accent transition-colors">Términos de Uso</Link>
                  <Link href="/legal/cookies" className="hover:text-accent transition-colors">Cookies</Link>
                  <Link href="/legal/riesgo" className="hover:text-accent transition-colors">Aviso de Riesgo</Link>
                  <Link href="/faq" className="hover:text-accent transition-colors">FAQ</Link>
                </div>

                <div className="flex flex-col items-center gap-2 text-[10px] text-text-muted/40 text-center max-w-2xl">
                  <p>© {new Date().getFullYear()} KopyTrading. Todos los derechos reservados.</p>
                  <p className="mt-2">
                    KopyTrading NO constituye asesoramiento financiero. El trading en CFDs, Forex y Criptomonedas implica un alto nivel de riesgo y puede no ser adecuado para todos los inversores.
                    Solo debes operar con capital que puedas permitirte perder completamente.
                  </p>
                  <span className="text-accent/60 mt-2 font-bold uppercase tracking-widest">⚠️ Trading de Alto Riesgo</span>
                </div>
              </div>
            </footer>
            <CookieBanner />
            <FloatingChat />
          </Providers>
        )}
      </body>
    </html>
  );
}

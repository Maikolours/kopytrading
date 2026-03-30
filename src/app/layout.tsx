// Deploy V2-Test-Dashboard-Fix
import { Outfit } from "next/font/google";
import "./globals.css";
import { Providers } from "@/components/providers";
import { Navbar } from "@/components/Navbar";
import CookieBanner from "@/components/CookieBanner";
import FloatingChat from "@/components/FloatingChat";
import { MaintenanceMode } from "@/components/MaintenanceMode";
import { Analytics } from "@vercel/analytics/react";
import { SpeedInsights } from "@vercel/speed-insights/next";
import Script from "next/script";
import Link from "next/link";
import type { Metadata } from "next";

const outfit = Outfit({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: {
    default: "KopyTrading | Bots de Trading Avanzados para MT5",
    template: "%s | KopyTrading"
  },
  description: "Automatiza tu trading en MetaTrader 5 con nuestros bots de alta precisión en Oro (XAUUSD), Bitcoin y Forex. Tecnología institucional accesible para todos.",
  keywords: ["Trading Bots", "MT5", "MetaTrader 5", "Expert Advisors", "Oro", "XAUUSD", "Bitcoin Trading", "Trading Automático", "KopyTrading", "MQL5"],
  authors: [{ name: "KopyTrading Team" }],
  creator: "KopyTrading",
  publisher: "KopyTrading",
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  openGraph: {
    type: "website",
    locale: "es_ES",
    url: "https://kopytrading.com",
    siteName: "KopyTrading",
    title: "KopyTrading | Bots de Trading de Alta Precisión",
    description: "Consigue rentabilidad algorítmica con nuestros bots especializados para MT5. Oro, BTC y más.",
    images: [
      {
        url: "/og-image.png",
        width: 1200,
        height: 630,
        alt: "KopyTrading Platform",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "KopyTrading | Bots de Trading MT5",
    description: "Algoritmos avanzados para traders que quieren resultados reales en MT5.",
    images: ["/og-image.png"],
    creator: "@kopytrading",
  },
  manifest: "/manifest.json",
  icons: {
    icon: "/favicon.ico",
    apple: "/apple-touch-icon.png",
  },
  verification: {
    google: "google6360705432bda5d2",
  }
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const isMaintenance = process.env.NEXT_PUBLIC_MAINTENANCE_MODE === "true";

  return (
    <html lang="es" className="dark">
      <head>
        <meta name="google-adsense-account" content="ca-pub-7217883854605334" />
        <script 
          async 
          src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-7217883854605334"
          crossOrigin="anonymous"
        ></script>
        {/* Google Analytics */}
        <Script
          src="https://www.googletagmanager.com/gtag/js?id=G-QWJ1GK9417"
          strategy="afterInteractive"
        />
        <Script id="google-analytics" strategy="afterInteractive">
          {`
            window.dataLayer = window.dataLayer || [];
            function gtag(){dataLayer.push(arguments);}
            gtag('js', new Date());
            gtag('config', 'G-QWJ1GK9417');
          `}
        </Script>
      </head>
      <body className={`${outfit.className} min-h-screen bg-black text-slate-50 antialiased selection:bg-brand/30 selection:text-white`}>

        {isMaintenance ? (
          <MaintenanceMode />
        ) : (
          <Providers>
            <Navbar />
            <main className="main-wrapper">
              {children}
            </main>
            <footer className="border-t border-white/5 pt-16 pb-12 px-4 sm:px-6 lg:px-8 bg-black main-wrapper">
              <div className="max-w-7xl mx-auto">
                <div className="grid grid-cols-2 md:grid-cols-4 gap-12 mb-16">
                  {/* Columna 1: Marca y Logo */}
                  <div className="col-span-2 md:col-span-1 space-y-6">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl overflow-hidden border border-white/10 p-0.5 bg-black">
                        <img src="/logo-kopytrading.png" alt="Logo" className="w-full h-full object-cover rounded-[0.5rem]" />
                      </div>
                      <span className="font-black text-lg sm:text-2xl tracking-tighter uppercase text-white">KopyTrading</span>
                    </div>
                    <p className="text-xs text-text-muted leading-relaxed max-w-xs">
                      Tecnología algorítmica de alta precisión diseñada para traders que buscan consistencia en MetaTrader 5.
                    </p>
                  </div>

                  {/* Columna 2: Productos */}
                  <div className="space-y-4">
                    <h4 className="text-white font-bold text-sm uppercase tracking-widest">Sistemas</h4>
                    <ul className="space-y-2 text-xs text-text-muted">
                      <li><Link href="/bots/cmmv3xu5f0006vhmcqmuq1b4a" className="hover:text-accent transition-colors">La Ametralladora (Oro)</Link></li>
                      <li><Link href="/bots/cmmv3xugt000cvhmc7nqjwwji-btcusd" className="hover:text-accent transition-colors">BTC Storm Rider</Link></li>
                      <li><Link href="/bots" className="hover:text-accent transition-colors font-semibold text-accent/80">Todos los Bots →</Link></li>
                    </ul>
                  </div>

                  {/* Columna 3: Información */}
                  <div className="space-y-4">
                    <h4 className="text-white font-bold text-sm uppercase tracking-widest">Recursos</h4>
                    <ul className="space-y-2 text-xs text-text-muted">
                      <li><Link href="/articulos" className="hover:text-accent transition-colors">Blog & Análisis</Link></li>
                      <li><Link href="/activos" className="hover:text-accent transition-colors">Activos Disponibles</Link></li>
                      <li><Link href="/faq" className="hover:text-accent transition-colors">Preguntas Frecuentes</Link></li>
                      <li><Link href="/instalar" className="hover:text-accent transition-colors">Guía de Instalación</Link></li>
                    </ul>
                  </div>

                  {/* Columna 4: Soporte y Legal */}
                  <div className="space-y-4">
                    <h4 className="text-white font-bold text-sm uppercase tracking-widest">Compañía</h4>
                    <ul className="space-y-2 text-xs text-text-muted">
                      <li><Link href="/sobre-nosotros" className="hover:text-accent transition-colors">Sobre Nosotros</Link></li>
                      <li><Link href="/contacto" className="hover:text-accent transition-colors">Contacto</Link></li>
                      <li><Link href="/legal/privacidad" className="hover:text-accent transition-colors">Privacidad</Link></li>
                      <li><Link href="/legal/riesgo" className="hover:text-accent transition-colors font-bold text-danger/80">Aviso de Riesgo</Link></li>
                    </ul>
                  </div>
                </div>

                <div className="border-t border-white/5 pt-8 flex flex-col items-center gap-6">
                  <div className="flex flex-col items-center gap-2 text-[10px] text-text-muted/40 text-center max-w-3xl">
                    <p suppressHydrationWarning>© {new Date().getFullYear()} KopyTrading. Todos los derechos reservados.</p>
                    <p className="mt-4 leading-relaxed">
                      KopyTrading es un proveedor de software tecnológico. NO constituye asesoramiento financiero ni recomendaciones de inversión. 
                      El trading en CFDs, Forex y Criptomonedas implica un riesgo significativo. Solo debes operar con capital que puedas permitirte perder completamente. 
                    </p>
                    <div className="flex items-center gap-4 mt-2">
                        <span className="text-accent/40 font-bold uppercase tracking-[0.2em]">E-E-A-T Certified</span>
                        <span className="w-1 h-1 rounded-full bg-white/10"></span>
                        <span className="text-accent/40 font-bold uppercase tracking-[0.2em]">SSL Secure Encryption</span>
                    </div>
                  </div>
                </div>
              </div>
            </footer>
            <CookieBanner />
            <FloatingChat />
            <Analytics />
            <SpeedInsights />
          </Providers>
        )}
      </body>
    </html>
  );
}

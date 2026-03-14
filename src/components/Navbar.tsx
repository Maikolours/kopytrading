
"use client";

import { useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Button } from "@/components/ui/Button";
import { useSession, signOut } from "next-auth/react";

export function Navbar() {
    const { data: session, status } = useSession();
    const pathname = usePathname();
    const isLoggedIn = status === "authenticated";
    const [isMenuOpen, setIsMenuOpen] = useState(false);

    // Navbar siempre fija arriba para simplicidad
    return (
        <header className="fixed top-0 w-full z-[70] transition-all duration-300">
            <div className="absolute inset-0 bg-bg-dark/90 backdrop-blur-xl border-b border-white/5"></div>

            <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between relative z-10">

                <Link href="/" className="flex items-center gap-4 group">
                    <div className="w-10 h-10 sm:w-12 sm:h-12 rounded-xl overflow-hidden shadow-lg group-hover:scale-105 transition-transform">
                        <img src="/logo-kopytrading.png" alt="Logo" className="w-full h-full object-cover" />
                    </div>
                    <span className="font-black text-xl sm:text-2xl tracking-tighter uppercase italic text-white">KopyTrading</span>
                </Link>

                {/* Desktop Nav - SIMPLE Y DIRECTA */}
                <nav className="hidden md:flex items-center gap-8">
                    <Link href="/bots" className={`text-xs font-black uppercase tracking-widest transition-colors ${pathname === "/bots" ? "text-brand-light" : "text-white/60 hover:text-white"}`}>Marketplace</Link>
                    <Link href="/activos" className={`text-xs font-black uppercase tracking-widest transition-colors ${pathname === "/activos" ? "text-brand-light" : "text-white/60 hover:text-white"}`}>Activos</Link>
                    <Link href="/activos#resultados" className="text-xs font-black uppercase tracking-widest text-white/40 hover:text-white transition-colors">Resultados</Link>
                    <Link href="/como-funciona" className="text-xs font-black uppercase tracking-widest text-white/40 hover:text-white transition-colors">Cómo Funciona</Link>
                    {isLoggedIn && (
                        <Link href="/dashboard" className="text-xs font-black uppercase tracking-widest text-brand-light hover:text-white transition-colors">Mi Panel</Link>
                    )}
                </nav>

                <div className="flex items-center gap-4">
                    {!isLoggedIn ? (
                        <Link href="/login" className="text-xs font-black uppercase tracking-widest text-white/60 hover:text-white transition-colors hidden sm:block">Login</Link>
                    ) : (
                        <Button variant="outline" size="sm" onClick={() => signOut()} className="hidden sm:flex text-[10px] h-8 border-white/10 text-white">Salir</Button>
                    )}
                    <Link href="/bots">
                        <Button variant="accent" size="sm" className="text-[10px] font-black uppercase h-9 px-6 rounded-full shadow-lg shadow-brand/20">Ver Bots</Button>
                    </Link>

                    {/* Mobile Menu Toggle */}
                    <button
                        onClick={() => setIsMenuOpen(!isMenuOpen)}
                        className="md:hidden w-12 h-12 flex flex-col items-center justify-center gap-1.5 focus:outline-none z-50 rounded-xl bg-white/5 border border-white/10 active:scale-90 transition-transform -mr-2"
                        aria-label="Menu"
                    >
                        <span className={`w-6 h-0.5 bg-white transition-all duration-300 ${isMenuOpen ? "rotate-45 translate-y-2" : ""}`} />
                        <span className={`w-6 h-0.5 bg-white transition-all duration-300 ${isMenuOpen ? "opacity-0" : ""}`} />
                        <span className={`w-6 h-0.5 bg-white transition-all duration-300 ${isMenuOpen ? "-rotate-45 -translate-y-2" : ""}`} />
                    </button>

                </div>
            </div>

            {/* Mobile Menu Overlay */}
            <div className={`md:hidden fixed inset-0 z-40 transition-all duration-500 flex flex-col ${isMenuOpen ? "visible opacity-100" : "invisible opacity-0"}`}>
                <div className="absolute inset-0 bg-bg-dark/98 backdrop-blur-2xl"></div>
                <div className="relative z-10 flex-1 flex flex-col pt-32 px-8 gap-10">
                    <Link onClick={() => setIsMenuOpen(false)} href="/bots" className="text-3xl font-black text-white uppercase italic">Marketplace</Link>
                    <Link onClick={() => setIsMenuOpen(false)} href="/activos" className="text-3xl font-black text-white uppercase italic">Activos</Link>
                    <Link onClick={() => setIsMenuOpen(false)} href="/activos#resultados" className="text-3xl font-black text-white/40 uppercase italic">Resultados</Link>
                    <Link onClick={() => setIsMenuOpen(false)} href="/como-funciona" className="text-3xl font-black text-white/40 uppercase italic">Cómo Funciona</Link>
                    <div className="mt-auto pb-12 flex flex-col gap-4">
                        {!isLoggedIn ? (
                            <Link href="/login" onClick={() => setIsMenuOpen(false)}><Button fullWidth size="lg">Mi Cuenta</Button></Link>
                        ) : (
                            <Button fullWidth size="lg" variant="outline" onClick={() => { signOut(); setIsMenuOpen(false); }}>Cerrar Sesión</Button>
                        )}
                    </div>
                </div>
            </div>
        </header>
    );
}

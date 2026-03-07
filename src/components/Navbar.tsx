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

    // Si hay ticker, bajamos la navbar. El ticker está en '/' por ahora.
    const hasTicker = pathname === "/";

    return (
        <header className={`fixed ${hasTicker ? 'top-[41px]' : 'top-0'} w-full z-[70] transition-all duration-300`}>
            <div className="absolute inset-0 glass-card !rounded-none !border-x-0 !border-t-0 bg-bg-dark/80 backdrop-blur-xl"></div>

            <div className="max-w-7xl mx-auto px-4 py-3 flex items-center justify-between relative z-10">
                <Link href="/" className="flex items-center gap-4 group">
                    <div className="w-12 h-12 sm:w-14 sm:h-14 rounded-2xl overflow-hidden shadow-[0_0_20px_rgba(245,158,11,0.3)] group-hover:shadow-[0_0_35px_rgba(245,158,11,0.5)] transition-all duration-500">
                        <img src="/logo-kopytrading.png" alt="Logo" className="w-full h-full object-cover scale-110 group-hover:scale-125 transition-transform duration-700" />
                    </div>
                    <span className="font-extrabold text-2xl sm:text-3xl tracking-tighter bg-clip-text text-transparent bg-gradient-to-r from-white via-white to-accent/60">KopyTrading</span>
                </Link>

                {/* Desktop Nav */}
                <nav className="hidden md:flex items-center gap-4 lg:gap-6">
                    <Link
                        href="/bots"
                        className={`text-sm font-medium transition-colors ${pathname === "/bots" ? "text-white border-b border-brand-light/50 pb-0.5" : "text-text-muted hover:text-white"}`}
                    >
                        Marketplace
                    </Link>
                    {isLoggedIn && (
                        <Link
                            href="/dashboard"
                            className={`text-sm font-medium transition-colors ${pathname === "/dashboard" ? "text-white border-b border-brand-light/50 pb-0.5" : "text-text-muted hover:text-white"}`}
                        >
                            Mi Panel
                        </Link>
                    )}
                    <div className="relative group">
                        <span className="text-sm font-medium text-text-muted hover:text-white transition-colors cursor-pointer flex items-center gap-1">
                            Activos <span className="text-[10px]">▼</span>
                        </span>
                        <div className="absolute top-full left-0 mt-2 w-40 glass-card p-2 rounded-xl opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-300 translate-y-2 group-hover:translate-y-0">
                            <Link href="/bots?asset=XAUUSD" className="block px-4 py-2 text-sm text-text-muted hover:text-white hover:bg-white/5 rounded-lg">XAUUSD (Oro)</Link>
                            <Link href="/bots?asset=EURUSD" className="block px-4 py-2 text-sm text-text-muted hover:text-white hover:bg-white/5 rounded-lg">EURUSD</Link>
                            <Link href="/bots?asset=USDJPY" className="block px-4 py-2 text-sm text-text-muted hover:text-white hover:bg-white/5 rounded-lg">USDJPY</Link>
                            <Link href="/bots?asset=BTCUSD" className="block px-4 py-2 text-sm text-text-muted hover:text-white hover:bg-white/5 rounded-lg">BTCUSD</Link>
                        </div>
                    </div>
                    <Link href="/como-funciona" className="text-sm font-medium text-text-muted hover:text-white transition-colors">Cómo Funciona</Link>
                    <Link href="/articulos" className="text-sm font-medium text-text-muted hover:text-white transition-colors">Blog</Link>
                    <Link href="/faq" className="text-sm font-medium text-text-muted hover:text-white transition-colors">FAQ</Link>
                </nav>

                <div className="flex items-center gap-2 sm:gap-4">
                    {isLoggedIn ? (
                        <div className="flex items-center gap-3">
                            <span className="text-[10px] text-text-muted hidden md:block opacity-50">{session.user?.email}</span>
                            <Button variant="outline" size="sm" onClick={() => signOut()} className="hidden sm:flex text-[10px] h-8 border-white/10 text-white hover:bg-danger/10 hover:border-danger/30">Cerrar Sesión</Button>
                        </div>
                    ) : (
                        <Link href="/login" className="text-xs font-medium text-white hover:text-accent transition-colors hidden sm:block">Mi Cuenta</Link>
                    )}
                    <Link href="/bots" className="hidden sm:block">
                        <Button variant="accent" size="sm" className="text-[11px] h-9">Ver Bots</Button>
                    </Link>

                    {/* Mobile Menu Toggle */}
                    <button
                        onClick={() => setIsMenuOpen(!isMenuOpen)}
                        className="md:hidden w-10 h-10 flex flex-col items-center justify-center gap-1.5 focus:outline-none z-50 rounded-xl bg-white/5 border border-white/10"
                    >
                        <span className={`w-5 h-0.5 bg-white transition-all duration-300 ${isMenuOpen ? "rotate-45 translate-y-2" : ""}`} />
                        <span className={`w-5 h-0.5 bg-white transition-all duration-300 ${isMenuOpen ? "opacity-0" : ""}`} />
                        <span className={`w-5 h-0.5 bg-white transition-all duration-300 ${isMenuOpen ? "-rotate-45 -translate-y-2" : ""}`} />
                    </button>
                </div>
            </div>

            {/* Mobile Menu Overlay */}
            <div className={`md:hidden fixed inset-0 z-40 transition-all duration-500 flex flex-col ${isMenuOpen ? "visible opacity-100" : "invisible opacity-0"}`}>
                <div className="absolute inset-0 bg-bg-dark/95 backdrop-blur-2xl"></div>
                <div className="relative z-10 flex-1 flex flex-col pt-32 px-8 gap-8 overflow-y-auto pb-12">
                    <div className="flex flex-col gap-6">
                        <Link onClick={() => setIsMenuOpen(false)} href="/bots" className="text-2xl font-bold text-white border-b border-white/5 pb-2">Marketplace</Link>
                        {isLoggedIn && (
                            <Link onClick={() => setIsMenuOpen(false)} href="/dashboard" className="text-2xl font-bold text-brand-light border-b border-white/5 pb-2">Mi Panel (Mis Bots)</Link>
                        )}
                        <Link onClick={() => setIsMenuOpen(false)} href="/como-funciona" className="text-2xl font-bold text-white border-b border-white/5 pb-2">Cómo Funciona</Link>
                        <Link onClick={() => setIsMenuOpen(false)} href="/articulos" className="text-2xl font-bold text-white border-b border-white/5 pb-2">Blog</Link>
                        <Link onClick={() => setIsMenuOpen(false)} href="/faq" className="text-2xl font-bold text-white border-b border-white/5 pb-2">FAQ</Link>
                    </div>

                    <div className="flex flex-col gap-4 mt-auto">
                        {!isLoggedIn && (
                            <Link onClick={() => setIsMenuOpen(false)} href="/login">
                                <Button fullWidth size="lg" variant="outline" className="border-white/10">Mi Cuenta</Button>
                            </Link>
                        )}
                        <Link onClick={() => setIsMenuOpen(false)} href="/bots">
                            <Button variant="accent" fullWidth size="lg">Ver Todos los Bots</Button>
                        </Link>
                        {isLoggedIn && (
                            <Button fullWidth size="lg" variant="outline" onClick={() => { signOut(); setIsMenuOpen(false); }} className="border-danger/30 text-danger hover:bg-danger/10">Cerrar Sesión</Button>
                        )}
                    </div>
                </div>
            </div>
        </header>
    );
}

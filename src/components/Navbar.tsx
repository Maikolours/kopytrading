
"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Button } from "@/components/ui/Button";
import { useSession, signOut } from "next-auth/react";

export function Navbar() {
    const { data: session, status } = useSession();
    const pathname = usePathname();
    const isLoggedIn = status === "authenticated";
    const [isMenuOpen, setIsMenuOpen] = useState(false);

    // Prevent scroll when menu is open
    useEffect(() => {
        if (isMenuOpen) {
            document.body.style.overflow = 'hidden';
        } else {
            document.body.style.overflow = 'unset';
        }
        return () => {
            document.body.style.overflow = 'unset';
        };
    }, [isMenuOpen]);

    // Close menu on resize if screen becomes large
    useEffect(() => {
        const handleResize = () => {
            if (window.innerWidth >= 1024) { // lg breakpoint
                setIsMenuOpen(false);
            }
        };
        window.addEventListener('resize', handleResize);
        return () => window.removeEventListener('resize', handleResize);
    }, []);
    return (
        <header className="fixed top-0 left-0 right-0 w-full z-[70] transition-all duration-300">
            <div className="absolute inset-0 bg-bg-dark/90 backdrop-blur-xl border-b border-white/5"></div>

            <div className="max-w-7xl mx-auto px-4 py-3 flex items-center justify-between w-full relative z-10">

                {/* LOGO & BUTTON STACK - Ultra-Mobile Fix */}
                <div className="flex flex-col items-start gap-1 flex-shrink-0 z-20">
                    <Link href="/" className="flex items-center gap-3 flex-shrink-0 group pointer-events-auto">
                        <div className="w-12 h-12 sm:w-14 sm:h-14 rounded-xl overflow-hidden shadow-xl bg-black border border-white/10 transition-transform group-hover:scale-110">
                            <img src="/logo-kopytrading.png" alt="Logo" className="w-full h-full object-cover" />
                        </div>
                        <span className="font-black text-lg sm:text-2xl tracking-tighter uppercase text-white">KopyTrading</span>
                    </Link>
                    
                    <Link href="/bots" className="lg:hidden">
                        <Button variant="accent" size="sm" className="text-[10px] font-black uppercase h-7 px-4 rounded-full shadow-lg">
                            VER BOTS
                        </Button>
                    </Link>
                </div>

                {/* Desktop Nav - Only for LG+ (1024px+) */}
                <nav className="hidden lg:flex items-center gap-6 ml-6">
                    <Link href="/bots" className={`text-xs font-black uppercase tracking-widest transition-colors ${pathname === "/bots" ? "text-brand-light" : "text-white/60 hover:text-white"}`}>Marketplace</Link>
                    <Link href="/activos" className={`text-xs font-black uppercase tracking-widest transition-colors ${pathname === "/activos" ? "text-brand-light" : "text-white/60 hover:text-white"}`}>Activos</Link>
                    <Link href="/como-funciona" className={`text-xs font-black uppercase tracking-widest transition-colors ${pathname === "/como-funciona" ? "text-brand-light" : "text-white/60 hover:text-white"}`}>Cómo Funciona</Link>
                    <Link href="/faq" className={`text-xs font-black uppercase tracking-widest transition-colors ${pathname === "/faq" ? "text-brand-light" : "text-white/60 hover:text-white"}`}>FAQ</Link>
                    {isLoggedIn && (
                        <Link href="/dashboard" className={`text-xs font-black uppercase tracking-widest transition-colors ${pathname === "/dashboard" ? "text-brand-light" : "text-white/60 hover:text-white"}`}>Panel</Link>
                    )}
                </nav>

                <div className="flex items-center gap-4">
                    {/* PC View Button stays here for LG+ */}
                    <Link href="/bots" className="hidden lg:block">
                        <Button variant="accent" size="sm" className="text-xs font-black uppercase px-6 rounded-full shadow-lg shadow-brand/20">
                            VER BOTS
                        </Button>
                    </Link>

                    {/* Mobile Menu Toggle - Responsive Below LG */}
                    <button
                        onClick={() => setIsMenuOpen(!isMenuOpen)}
                        className="lg:hidden w-12 h-12 flex flex-col items-center justify-center gap-1.5 focus:outline-none z-[110] rounded-2xl bg-brand text-white shadow-2xl active:scale-90 transition-all border border-white/10"
                        aria-label="Menu"
                    >
                        <div className="relative w-6 h-5">
                            <span className={`absolute left-0 w-6 h-0.5 bg-white transition-all duration-300 ${isMenuOpen ? "top-2.5 rotate-45" : "top-0"}`} />
                            <span className={`absolute left-0 top-2.5 w-6 h-0.5 bg-white transition-all duration-300 ${isMenuOpen ? "opacity-0" : "opacity-100"}`} />
                            <span className={`absolute left-0 w-6 h-0.5 bg-white transition-all duration-300 ${isMenuOpen ? "top-2.5 -rotate-45" : "top-5"}`} />
                        </div>
                    </button>
                </div>
            </div>

            {/* Mobile Menu Overlay - Active below LG */}
            <div className={`lg:hidden fixed inset-0 z-[60] transition-all duration-500 flex flex-col ${isMenuOpen ? "visible opacity-100" : "invisible opacity-0"}`}>
                <div className="absolute inset-0 bg-bg-dark/98 backdrop-blur-2xl"></div>
                
                {/* Explicit Close Button inside menu */}
                <button 
                    onClick={() => setIsMenuOpen(false)}
                    className="absolute top-6 right-6 w-12 h-12 flex items-center justify-center rounded-full bg-white/5 border border-white/10 text-white z-20"
                >
                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>

                <div className="relative z-10 flex-1 flex flex-col pt-24 px-10 gap-5 items-center justify-center text-center">
                    <Link onClick={() => setIsMenuOpen(false)} href="/bots" className={`text-xl font-black uppercase tracking-[0.2em] transition-colors ${pathname === "/bots" ? "text-brand-light" : "text-white/60 hover:text-white"}`}>Marketplace</Link>
                    <Link onClick={() => setIsMenuOpen(false)} href="/activos" className={`text-xl font-black uppercase tracking-[0.2em] transition-colors ${pathname === "/activos" ? "text-brand-light" : "text-white/60 hover:text-white"}`}>Activos</Link>
                    <Link onClick={() => setIsMenuOpen(false)} href="/activos#resultados" className={`text-xl font-black uppercase tracking-[0.2em] transition-colors ${pathname === "/activos#resultados" ? "text-brand-light" : "text-white/60 hover:text-white"}`}>Resultados</Link>
                    <Link onClick={() => setIsMenuOpen(false)} href="/como-funciona" className={`text-xl font-black uppercase tracking-[0.2em] transition-colors ${pathname === "/como-funciona" ? "text-brand-light" : "text-white/60 hover:text-white"}`}>Cómo Funciona</Link>
                    <Link onClick={() => setIsMenuOpen(false)} href="/faq" className={`text-xl font-black uppercase tracking-[0.2em] transition-colors ${pathname === "/faq" ? "text-brand-light" : "text-white/60 hover:text-white"}`}>Preguntas</Link>
                    {isLoggedIn && (
                        <Link onClick={() => setIsMenuOpen(false)} href="/dashboard" className="text-xl font-bold text-brand-light uppercase tracking-widest hover:text-white transition-colors">Mi Panel</Link>
                    )}
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

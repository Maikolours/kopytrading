
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
            document.body.style.overflow = '';
        }
        return () => {
            document.body.style.overflow = '';
        };
    }, [isMenuOpen]);

    // Close menu on resize if screen becomes large (XL breakpoint)
    useEffect(() => {
        const handleResize = () => {
            if (window.innerWidth >= 1280) { // xl breakpoint
                setIsMenuOpen(false);
            }
        };
        window.addEventListener('resize', handleResize);
        return () => window.removeEventListener('resize', handleResize);
    }, []);

    // Close menu when route changes
    useEffect(() => {
        setIsMenuOpen(false);
    }, [pathname]);

    return (
        <header className="fixed top-0 left-0 right-0 w-full z-[80] transition-all duration-300">
            <div className="absolute inset-0 bg-[#060913]/90 backdrop-blur-xl border-b border-white/10"></div>

            <div className="max-w-7xl mx-auto px-4 py-3 flex items-center justify-between w-full relative z-10">

                {/* LOGO & BUTTON STACK */}
                <div className="flex items-center gap-3 flex-shrink-0 z-20">
                    <Link href="/" className="flex items-center gap-3 flex-shrink-0 group pointer-events-auto">
                        <div className="w-11 h-11 sm:w-13 sm:h-13 rounded-xl overflow-hidden shadow-xl bg-black border border-white/10 transition-transform group-hover:scale-105">
                            <img src="/logo-kopytrading.png" alt="Logo" className="w-full h-full object-cover" />
                        </div>
                        <span className="font-black text-lg sm:text-2xl tracking-tighter uppercase text-white">KopyTrading</span>
                    </Link>
                </div>

                {/* Desktop Nav - Visible on XL+ (1280px+) for perfect tablet & desktop layout */}
                <nav className="hidden xl:flex items-center gap-6 ml-6">
                    <Link href="/bots" className={`text-xs font-black uppercase tracking-widest transition-colors ${pathname === "/bots" ? "text-brand-light" : "text-white/70 hover:text-white"}`}>Marketplace</Link>
                    <Link href="/resultados" className={`text-xs font-black uppercase tracking-widest transition-colors ${pathname === "/resultados" ? "text-brand-light" : "text-white/70 hover:text-white"}`}>Resultados</Link>
                    <Link href="/activos" className={`text-xs font-black uppercase tracking-widest transition-colors ${pathname === "/activos" ? "text-brand-light" : "text-white/70 hover:text-white"}`}>Activos</Link>
                    <Link href="/como-funciona" className={`text-xs font-black uppercase tracking-widest transition-colors ${pathname === "/como-funciona" ? "text-brand-light" : "text-white/70 hover:text-white"}`}>Cómo Funciona</Link>
                    <Link href="/articulos" className={`text-xs font-black uppercase tracking-widest transition-colors ${pathname === "/articulos" ? "text-brand-light" : "text-white/70 hover:text-white"}`}>Blog</Link>
                    <Link href="/faq" className={`text-xs font-black uppercase tracking-widest transition-colors ${pathname === "/faq" ? "text-brand-light" : "text-white/70 hover:text-white"}`}>FAQ</Link>
                    <Link href={isLoggedIn ? "/dashboard" : "/login"} className={`text-xs font-black uppercase tracking-widest transition-colors flex items-center gap-2 group ${pathname === "/dashboard" || pathname === "/login" ? "text-brand-light" : "text-white/70 hover:text-white"}`}>
                        <span className="w-1.5 h-1.5 rounded-full bg-brand group-hover:animate-pulse"></span>
                        {isLoggedIn ? "Mi Panel" : "Mi Cuenta"}
                    </Link>
                    {isLoggedIn && (
                        <button 
                            onClick={() => signOut()}
                            className="ml-2 px-3 py-1.5 text-[10px] font-black uppercase tracking-widest text-white border border-danger/40 bg-danger/10 hover:bg-danger hover:border-danger rounded-md transition-all shadow-[0_0_10px_rgba(239,68,68,0.2)] cursor-pointer"
                        >
                            Cerrar Sesión
                        </button>
                    )}
                </nav>

                <div className="flex items-center gap-3">
                    {/* VER BOTS CTA Button */}
                    <Link href="/bots" className="hidden sm:block">
                        <Button variant="accent" size="sm" className="text-xs font-black uppercase px-5 rounded-full shadow-lg shadow-brand/20">
                            VER BOTS
                        </Button>
                    </Link>

                    {/* Hamburger Button - Optimized for Mobile & Tablets (below XL) */}
                    <button
                        type="button"
                        onClick={(e) => {
                            e.stopPropagation();
                            setIsMenuOpen((prev) => !prev);
                        }}
                        className="xl:hidden w-11 h-11 sm:w-12 sm:h-12 flex flex-col items-center justify-center gap-1.5 focus:outline-none z-[120] rounded-xl bg-brand text-white shadow-xl active:scale-95 transition-all border border-white/20 cursor-pointer touch-manipulation"
                        aria-label="Abrir menú de navegación"
                    >
                        <div className="relative w-5 h-4 flex flex-col justify-between items-center pointer-events-none">
                            <span className={`w-5 h-0.5 bg-white rounded-full transition-all duration-300 transform ${isMenuOpen ? "translate-y-1.5 rotate-45" : ""}`} />
                            <span className={`w-5 h-0.5 bg-white rounded-full transition-all duration-300 ${isMenuOpen ? "opacity-0" : "opacity-100"}`} />
                            <span className={`w-5 h-0.5 bg-white rounded-full transition-all duration-300 transform ${isMenuOpen ? "-translate-y-2 -rotate-45" : ""}`} />
                        </div>
                    </button>
                </div>
            </div>

            {/* Mobile & Tablet Fullscreen Menu Overlay */}
            <div 
                className={`xl:hidden fixed inset-0 z-[100] transition-all duration-300 flex flex-col ${
                    isMenuOpen ? "opacity-100 pointer-events-auto" : "opacity-0 pointer-events-none"
                }`}
                style={{ height: '100dvh' }}
            >
                {/* Dark Backdrop */}
                <div 
                    className="absolute inset-0 bg-[#060913]/98 backdrop-blur-3xl"
                    onClick={() => setIsMenuOpen(false)}
                />
                
                {/* Close Button Top Right */}
                <button 
                    type="button"
                    onClick={() => setIsMenuOpen(false)}
                    className="absolute top-5 right-5 w-11 h-11 flex items-center justify-center rounded-xl bg-white/10 border border-white/20 text-white z-20 hover:bg-white/20 active:scale-95 transition-all cursor-pointer"
                    aria-label="Cerrar menú"
                >
                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>

                {/* Navigation Links inside Menu */}
                <div className="relative z-10 flex-1 flex flex-col justify-center items-center py-16 px-6 gap-6 text-center overflow-y-auto">
                    <Link 
                        onClick={() => setIsMenuOpen(false)} 
                        href="/bots" 
                        className={`text-xl sm:text-2xl font-black uppercase tracking-[0.2em] transition-colors py-1 ${pathname === "/bots" ? "text-brand-light" : "text-white/80 hover:text-white"}`}
                    >
                        Marketplace
                    </Link>
                    <Link 
                        onClick={() => setIsMenuOpen(false)} 
                        href="/activos" 
                        className={`text-xl sm:text-2xl font-black uppercase tracking-[0.2em] transition-colors py-1 ${pathname === "/activos" ? "text-brand-light" : "text-white/80 hover:text-white"}`}
                    >
                        Activos
                    </Link>
                    <Link 
                        onClick={() => setIsMenuOpen(false)} 
                        href="/resultados" 
                        className={`text-xl sm:text-2xl font-black uppercase tracking-[0.2em] transition-colors py-1 ${pathname === "/resultados" ? "text-brand-light" : "text-white/80 hover:text-white"}`}
                    >
                        Resultados
                    </Link>
                    <Link 
                        onClick={() => setIsMenuOpen(false)} 
                        href="/como-funciona" 
                        className={`text-xl sm:text-2xl font-black uppercase tracking-[0.2em] transition-colors py-1 ${pathname === "/como-funciona" ? "text-brand-light" : "text-white/80 hover:text-white"}`}
                    >
                        Cómo Funciona
                    </Link>
                    <Link 
                        onClick={() => setIsMenuOpen(false)} 
                        href="/articulos" 
                        className={`text-xl sm:text-2xl font-black uppercase tracking-[0.2em] transition-colors py-1 ${pathname === "/articulos" ? "text-brand-light" : "text-white/80 hover:text-white"}`}
                    >
                        Blog
                    </Link>
                    <Link 
                        onClick={() => setIsMenuOpen(false)} 
                        href="/faq" 
                        className={`text-xl sm:text-2xl font-black uppercase tracking-[0.2em] transition-colors py-1 ${pathname === "/faq" ? "text-brand-light" : "text-white/80 hover:text-white"}`}
                    >
                        Preguntas FAQ
                    </Link>
                    
                    {isLoggedIn && (
                        <Link 
                            onClick={() => setIsMenuOpen(false)} 
                            href="/dashboard" 
                            className="text-xl sm:text-2xl font-black text-brand-light uppercase tracking-widest hover:text-white transition-colors py-1"
                        >
                            Mi Panel de Usuario
                        </Link>
                    )}

                    <div className="w-full max-w-xs mt-4 flex flex-col gap-3">
                        <Link href="/bots" onClick={() => setIsMenuOpen(false)}>
                            <Button fullWidth size="lg" variant="accent" className="font-black uppercase tracking-wider">
                                Explorar Bots
                            </Button>
                        </Link>
                        {!isLoggedIn ? (
                            <Link href="/login" onClick={() => setIsMenuOpen(false)}>
                                <Button fullWidth size="lg" variant="outline" className="font-black uppercase tracking-wider">
                                    Iniciar Sesión / Registro
                                </Button>
                            </Link>
                        ) : (
                            <Button 
                                fullWidth 
                                size="lg" 
                                variant="outline" 
                                className="font-black uppercase tracking-wider text-danger border-danger/40 hover:bg-danger hover:text-white"
                                onClick={() => { signOut(); setIsMenuOpen(false); }}
                            >
                                Cerrar Sesión
                            </Button>
                        )}
                    </div>
                </div>
            </div>
        </header>
    );
}

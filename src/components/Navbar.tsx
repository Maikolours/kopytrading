
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

    const [isDropdownOpen, setIsDropdownOpen] = useState(false);

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

    // Close menu on resize if screen becomes tablet/desktop (MD breakpoint 768px)
    useEffect(() => {
        const handleResize = () => {
            if (window.innerWidth >= 768) { // md breakpoint
                setIsMenuOpen(false);
            }
        };
        window.addEventListener('resize', handleResize);
        return () => window.removeEventListener('resize', handleResize);
    }, []);

    // Close menu when route changes
    useEffect(() => {
        setIsMenuOpen(false);
        setIsDropdownOpen(false);
    }, [pathname]);

    return (
        <header className="fixed top-0 left-0 right-0 w-full z-[80] transition-all duration-300">
            <div className="absolute inset-0 bg-[#060913]/90 backdrop-blur-xl border-b border-white/10"></div>

            <div className="max-w-7xl mx-auto px-4 py-3 flex items-center justify-between w-full relative z-10">

                {/* LOGO & BUTTON STACK */}
                <div className="flex items-center gap-3 flex-shrink-0 z-20">
                    <Link href="/" className="flex items-center gap-3 flex-shrink-0 group pointer-events-auto">
                        <div className="w-11 h-11 sm:w-13 sm:h-13 rounded-xl overflow-hidden shadow-xl bg-black border border-white/10 transition-transform group-hover:scale-105">
                            <img src="/logo-kopytrading.png" alt="Logo" className="w-full h-full object-cover" width={40} height={40} />
                        </div>
                        <span className="font-black text-lg sm:text-2xl tracking-tighter uppercase text-white">KopyTrading</span>
                    </Link>
                </div>

                {/* Desktop Nav */}
                <nav className="hidden md:flex items-center gap-4 lg:gap-6 xl:gap-7 ml-4 lg:ml-6">
                    
                    {/* MARKETPLACE DROPDOWN MENU */}
                    <div 
                        className="relative"
                        onMouseEnter={() => setIsDropdownOpen(true)}
                        onMouseLeave={() => setIsDropdownOpen(false)}
                    >
                        <button 
                            type="button"
                            onClick={() => setIsDropdownOpen(!isDropdownOpen)}
                            className={`text-[11px] lg:text-xs font-black uppercase tracking-wider lg:tracking-widest transition-colors flex items-center gap-1 cursor-pointer py-2 ${
                                pathname === "/bots" || pathname === "/resultados" || pathname === "/activos" || pathname === "/calculadora-riesgo" || pathname === "/como-funciona"
                                    ? "text-brand-light" 
                                    : "text-white/70 hover:text-white"
                            }`}
                        >
                            <span>Marketplace</span>
                            <svg className={`w-3 h-3 transition-transform duration-200 ${isDropdownOpen ? "rotate-180 text-brand-light" : ""}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M19 9l-7 7-7-7" />
                            </svg>
                        </button>

                        {/* Dropdown Panel */}
                        {isDropdownOpen && (
                            <div className="absolute top-full left-0 w-56 pt-2 z-[100] animate-in fade-in slide-in-from-top-2 duration-150">
                                <div className="bg-[#0b0f19]/95 backdrop-blur-2xl border border-white/15 rounded-xl shadow-2xl p-2 flex flex-col gap-1 overflow-hidden">
                                    <Link 
                                        href="/bots" 
                                        className={`flex items-center gap-2.5 px-3 py-2 rounded-lg text-xs font-bold transition-all ${
                                            pathname === "/bots" ? "bg-brand/20 text-brand-light font-black" : "text-white/80 hover:text-white hover:bg-white/10"
                                        }`}
                                    >
                                        <span className="text-base">🤖</span>
                                        <span>Catálogo de Bots</span>
                                    </Link>
                                    <Link 
                                        href="/resultados" 
                                        className={`flex items-center gap-2.5 px-3 py-2 rounded-lg text-xs font-bold transition-all ${
                                            pathname === "/resultados" ? "bg-brand/20 text-brand-light font-black" : "text-white/80 hover:text-white hover:bg-white/10"
                                        }`}
                                    >
                                        <span className="text-base">📈</span>
                                        <span>Resultados Reales</span>
                                    </Link>
                                    <Link 
                                        href="/como-funciona" 
                                        className={`flex items-center gap-2.5 px-3 py-2 rounded-lg text-xs font-bold transition-all ${
                                            pathname === "/como-funciona" ? "bg-brand/20 text-brand-light font-black" : "text-white/80 hover:text-white hover:bg-white/10"
                                        }`}
                                    >
                                        <span className="text-base">⚙️</span>
                                        <span>Cómo Funciona</span>
                                    </Link>
                                    <Link 
                                        href="/calculadora-riesgo" 
                                        className={`flex items-center gap-2.5 px-3 py-2 rounded-lg text-xs font-bold transition-all ${
                                            pathname === "/calculadora-riesgo" ? "bg-brand/20 text-brand-light font-black" : "text-white/80 hover:text-white hover:bg-white/10"
                                        }`}
                                    >
                                        <span className="text-base">🧮</span>
                                        <span>Calculadora MT5</span>
                                    </Link>
                                    <Link 
                                        href="/activos" 
                                        className={`flex items-center gap-2.5 px-3 py-2 rounded-lg text-xs font-bold transition-all ${
                                            pathname === "/activos" ? "bg-brand/20 text-brand-light font-black" : "text-white/80 hover:text-white hover:bg-white/10"
                                        }`}
                                    >
                                        <span className="text-base">🪙</span>
                                        <span>Nuestros Activos</span>
                                    </Link>
                                </div>
                            </div>
                        )}
                    </div>

                    <Link href="/academia" className={`text-[11px] lg:text-xs font-black uppercase tracking-wider lg:tracking-widest transition-colors flex items-center gap-1 ${pathname.startsWith("/academia") ? "text-amber-400" : "text-white/70 hover:text-white"}`}>
                        <span>Academia</span>
                        <span className="text-amber-400 text-[9px] px-1 py-0.5 bg-amber-400/10 rounded border border-amber-400/30">NUEVO</span>
                    </Link>
                    <Link href="/articulos" className={`text-[11px] lg:text-xs font-black uppercase tracking-wider lg:tracking-widest transition-colors ${pathname === "/articulos" ? "text-brand-light" : "text-white/70 hover:text-white"}`}>Blog</Link>
                    <Link href="/sobre-nosotros" className={`text-[11px] lg:text-xs font-black uppercase tracking-wider lg:tracking-widest transition-colors ${pathname === "/sobre-nosotros" ? "text-brand-light" : "text-white/70 hover:text-white"}`}>Nosotros</Link>
                    <Link href="/faq" className={`text-[11px] lg:text-xs font-black uppercase tracking-wider lg:tracking-widest transition-colors ${pathname === "/faq" ? "text-brand-light" : "text-white/70 hover:text-white"}`}>FAQ</Link>
                    <Link href={isLoggedIn ? "/dashboard" : "/login"} className={`text-[11px] lg:text-xs font-black uppercase tracking-wider lg:tracking-widest transition-colors flex items-center gap-1.5 lg:gap-2 group ${pathname === "/dashboard" || pathname === "/login" ? "text-brand-light" : "text-white/70 hover:text-white"}`}>
                        <span className="w-1.5 h-1.5 rounded-full bg-brand group-hover:animate-pulse"></span>
                        {isLoggedIn ? "Mi Panel" : "Mi Cuenta"}
                    </Link>
                    {isLoggedIn && (
                        <button 
                            onClick={() => signOut()}
                            className="ml-1 lg:ml-2 px-2.5 lg:px-3 py-1 lg:py-1.5 text-[10px] font-black uppercase tracking-widest text-white border border-danger/40 bg-danger/10 hover:bg-danger hover:border-danger rounded-md transition-all shadow-[0_0_10px_rgba(239,68,68,0.2)] cursor-pointer"
                        >
                            Cerrar Sesión
                        </button>
                    )}
                </nav>

                <div className="flex items-center gap-3">
                    {/* VER BOTS CTA Button */}
                    <Link href="/bots" className="hidden sm:block">
                        <Button variant="accent" size="sm" className="text-xs font-black uppercase px-4 lg:px-5 rounded-full shadow-lg shadow-brand/20">
                            VER BOTS
                        </Button>
                    </Link>

                    {/* Hamburger Button - Only for Mobile (below MD) */}
                    <button
                        type="button"
                        onClick={(e) => {
                            e.stopPropagation();
                            setIsMenuOpen((prev) => !prev);
                        }}
                        className="md:hidden w-11 h-11 flex flex-col items-center justify-center gap-1.5 focus:outline-none z-[120] rounded-xl bg-brand text-white shadow-xl active:scale-95 transition-all border border-white/20 cursor-pointer touch-manipulation"
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

            {/* Mobile Fullscreen Menu Overlay (under MD) */}
            <div 
                className={`md:hidden fixed inset-0 z-[1100] transition-all duration-300 flex flex-col ${
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
                    className="absolute top-4 right-4 w-11 h-11 flex items-center justify-center rounded-xl bg-white/10 border border-white/20 text-white z-20 hover:bg-white/20 active:scale-95 transition-all cursor-pointer"
                    aria-label="Cerrar menú"
                >
                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>

                {/* Navigation Links inside Menu */}
                <div className="relative z-10 flex-1 flex flex-col justify-start items-center pt-16 pb-12 px-6 gap-3.5 text-center overflow-y-auto">
                    <Link 
                        onClick={() => setIsMenuOpen(false)} 
                        href="/academia" 
                        className={`text-base sm:text-lg font-black uppercase tracking-[0.2em] transition-colors py-1 ${pathname.startsWith("/academia") ? "text-amber-400 font-black" : "text-white/80 hover:text-white"}`}
                    >
                        🎓 Academia
                    </Link>
                    <Link 
                        onClick={() => setIsMenuOpen(false)} 
                        href="/bots" 
                        className={`text-base sm:text-lg font-black uppercase tracking-[0.2em] transition-colors py-1 ${pathname === "/bots" ? "text-brand-light" : "text-white/80 hover:text-white"}`}
                    >
                        Marketplace
                    </Link>
                    <Link 
                        onClick={() => setIsMenuOpen(false)} 
                        href="/activos" 
                        className={`text-base sm:text-lg font-black uppercase tracking-[0.2em] transition-colors py-1 ${pathname === "/activos" ? "text-brand-light" : "text-white/80 hover:text-white"}`}
                    >
                        Activos
                    </Link>
                    <Link 
                        onClick={() => setIsMenuOpen(false)} 
                        href="/calculadora-riesgo" 
                        className={`text-base sm:text-lg font-black uppercase tracking-[0.2em] transition-colors py-1 ${pathname === "/calculadora-riesgo" ? "text-brand-light" : "text-white/80 hover:text-white"}`}
                    >
                        Calculadora MT5
                    </Link>
                    <Link 
                        onClick={() => setIsMenuOpen(false)} 
                        href="/resultados" 
                        className={`text-base sm:text-lg font-black uppercase tracking-[0.2em] transition-colors py-1 ${pathname === "/resultados" ? "text-brand-light" : "text-white/80 hover:text-white"}`}
                    >
                        Resultados
                    </Link>
                    <Link 
                        onClick={() => setIsMenuOpen(false)} 
                        href="/como-funciona" 
                        className={`text-base sm:text-lg font-black uppercase tracking-[0.2em] transition-colors py-1 ${pathname === "/como-funciona" ? "text-brand-light" : "text-white/80 hover:text-white"}`}
                    >
                        Cómo Funciona
                    </Link>
                    <Link 
                        onClick={() => setIsMenuOpen(false)} 
                        href="/articulos" 
                        className={`text-base sm:text-lg font-black uppercase tracking-[0.2em] transition-colors py-1 ${pathname === "/articulos" ? "text-brand-light" : "text-white/80 hover:text-white"}`}
                    >
                        Blog
                    </Link>
                    <Link 
                        onClick={() => setIsMenuOpen(false)} 
                        href="/faq" 
                        className={`text-base sm:text-lg font-black uppercase tracking-[0.2em] transition-colors py-1 ${pathname === "/faq" ? "text-brand-light" : "text-white/80 hover:text-white"}`}
                    >
                        Preguntas FAQ
                    </Link>
                    <Link 
                        onClick={() => setIsMenuOpen(false)} 
                        href="/sobre-nosotros" 
                        className={`text-base sm:text-lg font-black uppercase tracking-[0.2em] transition-colors py-1 ${pathname === "/sobre-nosotros" ? "text-brand-light" : "text-white/80 hover:text-white"}`}
                    >
                        Sobre Nosotros
                    </Link>
                    
                    {isLoggedIn && (
                        <Link 
                            onClick={() => setIsMenuOpen(false)} 
                            href="/dashboard" 
                            className="text-base sm:text-lg font-black text-brand-light uppercase tracking-widest hover:text-white transition-colors py-1"
                        >
                            Mi Panel de Usuario
                        </Link>
                    )}

                    <div className="w-full max-w-xs mt-3 flex flex-col gap-2.5 pb-6">
                        <Link href="/bots" onClick={() => setIsMenuOpen(false)}>
                            <Button fullWidth size="md" variant="accent" className="font-black uppercase tracking-wider text-xs">
                                Explorar Bots
                            </Button>
                        </Link>
                        {!isLoggedIn ? (
                            <Link href="/login" onClick={() => setIsMenuOpen(false)}>
                                <Button fullWidth size="md" variant="outline" className="font-black uppercase tracking-wider text-xs">
                                    Iniciar Sesión / Registro
                                </Button>
                            </Link>
                        ) : (
                            <Button 
                                fullWidth 
                                size="md" 
                                variant="outline" 
                                className="font-black uppercase tracking-wider text-xs text-danger border-danger/40 hover:bg-danger hover:text-white"
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

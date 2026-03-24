"use client";

import { signIn } from "next-auth/react";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/Button";

export default function LoginPage() {
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [error, setError] = useState("");
    const [loading, setLoading] = useState(false);
    const router = useRouter();

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError("");
        setLoading(true);

        try {
            const result = await signIn("credentials", {
                redirect: false,
                email,
                password,
            });

            if (result?.error) {
                setError("Credenciales incorrectas. Por favor, inténtalo de nuevo.");
            } else {
                router.push("/dashboard");
                router.refresh();
            }
        } catch (err) {
            setError("Ocurrió un error inesperado. Por favor, inténtalo más tarde.");
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-[80vh] flex items-center justify-center px-4 py-12">
            <div className="max-w-md w-full space-y-8 glass-card p-8 sm:p-10 border border-white/10 relative overflow-hidden group">
                {/* Background glow effect - Optimized blur and opacity */}
                <div className="absolute -top-24 -right-24 w-48 h-48 bg-brand/10 blur-[60px] rounded-full group-hover:bg-brand/20 transition-colors duration-1000" />
                <div className="absolute -bottom-24 -left-24 w-48 h-48 bg-accent/5 blur-[60px] rounded-full group-hover:bg-accent/10 transition-colors duration-1000" />

                <div className="relative z-10 text-center">
                    <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br from-brand/10 to-brand-bright/5 border border-white/5 mb-6 group-hover:scale-105 transition-transform duration-500">
                        <span className="text-3xl">🔐</span>
                    </div>
                    <h2 className="text-3xl font-extrabold text-white tracking-tight">Bienvenido de nuevo</h2>
                    <p className="mt-2 text-sm text-text-muted">
                        Accede a tus bots y descargas
                    </p>
                </div>

                <form className="mt-8 space-y-6 relative z-10" onSubmit={handleSubmit}>
                    {error && (
                        <div className="bg-danger/10 border border-danger/20 text-danger text-sm p-4 rounded-xl flex items-center gap-3 animate-head-shake">
                            <span className="text-lg">⚠️</span>
                            {error}
                        </div>
                    )}
                    
                    <div className="space-y-4">
                        <div className="group/input">
                            <label className="block text-xs font-bold text-text-muted uppercase tracking-widest mb-2 ml-1 group-focus-within/input:text-brand-light transition-colors">
                                Email corporativo o personal
                            </label>
                            <input
                                type="email"
                                required
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                className="appearance-none block w-full px-4 py-4 border border-white/10 rounded-2xl bg-white/5 text-white placeholder-text-muted/30 focus:outline-none focus:ring-2 focus:ring-brand/40 focus:border-brand transition-[border-color,box-shadow,background-color] duration-200 sm:text-sm"
                                placeholder="ejemplo@email.com"
                            />
                        </div>
                        <div className="group/input">
                            <label className="block text-xs font-bold text-text-muted uppercase tracking-widest mb-2 ml-1 group-focus-within/input:text-brand-light transition-colors">
                                Contraseña
                            </label>
                            <input
                                type="password"
                                required
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                className="appearance-none block w-full px-4 py-4 border border-white/10 rounded-2xl bg-white/5 text-white placeholder-text-muted/30 focus:outline-none focus:ring-2 focus:ring-brand/40 focus:border-brand transition-[border-color,box-shadow,background-color] duration-200 sm:text-sm"
                                placeholder="••••••••"
                            />
                        </div>
                    </div>

                    <div className="flex items-center justify-between">
                        <div className="text-sm">
                            <a href="#" className="font-medium text-brand-light hover:text-brand-bright transition-colors">
                                ¿Olvidaste tu contraseña?
                            </a>
                        </div>
                    </div>

                    <Button 
                        type="submit" 
                        fullWidth 
                        size="lg" 
                        loading={loading}
                        className="mt-8 shadow-[0_4px_15px_rgba(139,92,246,0.2)] hover:shadow-[0_6px_20px_rgba(139,92,246,0.3)]"
                    >
                        Iniciar Sesión →
                    </Button>

                    <div className="text-center mt-6">
                        <p className="text-sm text-text-muted">
                            ¿No tienes cuenta?{" "}
                            <a href="/bots" className="font-bold text-white hover:text-brand-light transition-colors">
                                Elige un bot para empezar
                            </a>
                        </p>
                    </div>
                </form>
            </div>
        </div>
    );
}

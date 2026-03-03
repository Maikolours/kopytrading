"use client";

import { signIn } from "next-auth/react";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/Button";

export default function LoginPage() {
    const router = useRouter();
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [error, setError] = useState("");

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError("");

        const result = await signIn("credentials", {
            redirect: false,
            email,
            password,
        });

        if (result?.error) {
            setError("Credenciales inválidas");
        } else {
            router.push("/dashboard");
        }
    };

    return (
        <div className="min-h-screen flex items-center justify-center p-4">
            {/* Elementos decorativos de fondo */}
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-lg h-96 bg-brand/10 blur-[100px] rounded-full pointer-events-none"></div>

            <div className="relative glass-card p-8 sm:p-12 w-full max-w-md border border-white/10 rounded-2xl shadow-2xl">
                <div className="text-center mb-8 bg-gradient-to-br from-brand-light to-brand-bright bg-clip-text text-transparent">
                    <div className="w-12 h-12 rounded-full bg-brand/20 flex items-center justify-center mx-auto mb-4 border border-brand/30">
                        <span className="font-bold text-white text-xl">T</span>
                    </div>
                    <h2 className="text-2xl font-bold text-white">Bienvenido de nuevo</h2>
                    <p className="text-sm text-text-muted mt-2">Accede a tus bots y descargas</p>
                </div>

                <form onSubmit={handleSubmit} className="space-y-5">
                    {error && (
                        <div className="p-3 rounded-lg bg-danger/10 border border-danger/30 text-danger text-sm text-center">
                            {error}
                        </div>
                    )}
                    <div className="space-y-2">
                        <label className="text-sm font-medium text-text-muted">Correo electrónico</label>
                        <input
                            type="email"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            className="w-full bg-surface-light border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:ring-2 focus:ring-brand/50 transition-all placeholder-white/20"
                            placeholder="tu@email.com"
                            required
                        />
                    </div>
                    <div className="space-y-2">
                        <label className="text-sm font-medium text-text-muted">Contraseña</label>
                        <input
                            type="password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            className="w-full bg-surface-light border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:ring-2 focus:ring-brand/50 transition-all placeholder-white/20"
                            placeholder="••••••••"
                            required
                        />
                    </div>

                    <Button type="submit" fullWidth size="lg" className="mt-8 shadow-[0_4px_15px_rgba(139,92,246,0.3)] hover:shadow-[0_6px_25px_rgba(139,92,246,0.5)]">
                        Ingresar
                    </Button>
                </form>

                <div className="mt-8 text-center text-sm text-text-muted">
                    ¿No tienes cuenta? Las cuentas se crean al comprar tu primer bot.
                </div>
            </div>
        </div>
    );
}

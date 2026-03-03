"use client";

import { useState } from "react";
import { Button } from "./ui/Button";

export function PasswordChangeForm() {
    const [password, setPassword] = useState("");
    const [status, setStatus] = useState<"idle" | "loading" | "success" | "error">("idle");
    const [message, setMessage] = useState("");

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (password.length < 6) {
            setStatus("error");
            setMessage("La contraseña debe tener al menos 6 caracteres");
            return;
        }

        setStatus("loading");
        try {
            const res = await fetch("/api/user/change-password", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ newPassword: password }),
            });

            if (res.ok) {
                setStatus("success");
                setMessage("¡Contraseña actualizada! Usa la nueva la próxima vez.");
                setPassword("");
            } else {
                setStatus("error");
                setMessage("Error al actualizar. Inténtalo de nuevo.");
            }
        } catch (err) {
            setStatus("error");
            setMessage("Error de conexión.");
        }
    };

    return (
        <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
                <input
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="Nueva contraseña"
                    className="w-full bg-white/5 border border-white/10 rounded-lg px-4 py-2 text-sm text-white focus:outline-none focus:border-brand-light/50 transition-colors"
                />
            </div>
            <div className="flex flex-col gap-2">
                <Button
                    type="submit"
                    variant="outline"
                    size="sm"
                    className="w-full text-xs"
                    disabled={status === "loading"}
                >
                    {status === "loading" ? "Actualizando..." : "Actualizar Contraseña"}
                </Button>
                {message && (
                    <p className={`text-[10px] italic ${status === "success" ? "text-success" : "text-danger"}`}>
                        {message}
                    </p>
                )}
            </div>
        </form>
    );
}

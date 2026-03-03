"use client";

import { useState } from "react";
import { Button } from "@/components/ui/Button";
import { useRouter } from "next/navigation";

export default function AdminPage() {
    const router = useRouter();
    const [loading, setLoading] = useState(false);
    const [message, setMessage] = useState("");

    const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
        e.preventDefault();
        setLoading(true);
        setMessage("");

        const formData = new FormData(e.currentTarget);

        try {
            const res = await fetch("/api/admin/bots", {
                method: "POST",
                body: formData,
            });

            if (res.ok) {
                setMessage("✅ Bot creado y archivos subidos correctamente.");
                router.refresh();
                (e.target as HTMLFormElement).reset();
            } else {
                const data = await res.json();
                setMessage(`❌ Error: ${data.error || "Algo salió mal"}`);
            }
        } catch (error) {
            setMessage("❌ Error fatal al subir.");
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen pt-24 pb-12 px-4 sm:px-6 lg:px-8">
            <div className="max-w-4xl mx-auto glass-card p-8 border border-white/10">
                <h1 className="text-3xl font-bold text-white mb-6">Panel de Administración</h1>

                {message && (
                    <div className="p-4 mb-6 rounded-lg bg-surface-light border border-white/10 text-white font-medium">
                        {message}
                    </div>
                )}

                <form onSubmit={handleSubmit} className="space-y-6">
                    <div className="grid sm:grid-cols-2 gap-6">
                        <div className="space-y-2">
                            <label className="text-sm text-text-muted">Nombre del Bot</label>
                            <input name="name" required className="w-full bg-surface/50 border border-white/10 rounded-lg px-4 py-2 text-white" />
                        </div>
                        <div className="space-y-2">
                            <label className="text-sm text-text-muted">Precio (USD)</label>
                            <input type="number" step="0.01" name="price" required className="w-full bg-surface/50 border border-white/10 rounded-lg px-4 py-2 text-white" />
                        </div>
                        <div className="space-y-2">
                            <label className="text-sm text-text-muted">Instrumento (XAUUSD, EURUSD...)</label>
                            <input name="instrument" required className="w-full bg-surface/50 border border-white/10 rounded-lg px-4 py-2 text-white" />
                        </div>
                        <div className="space-y-2">
                            <label className="text-sm text-text-muted">Tipo de Estrategia</label>
                            <input name="strategyType" defaultValue="Scalping Avanzado" required className="w-full bg-surface/50 border border-white/10 rounded-lg px-4 py-2 text-white" />
                        </div>
                    </div>

                    <div className="space-y-2">
                        <label className="text-sm text-text-muted">Descripción</label>
                        <textarea name="description" required rows={4} className="w-full bg-surface/50 border border-white/10 rounded-lg px-4 py-2 text-white"></textarea>
                    </div>

                    <div className="grid sm:grid-cols-3 gap-6">
                        <div className="space-y-2">
                            <label className="text-sm text-text-muted">Nivel de Riesgo</label>
                            <select name="riskLevel" className="w-full bg-surface/50 border border-white/10 rounded-lg px-4 py-2 text-white">
                                <option value="Low">Low</option>
                                <option value="Medium">Medium</option>
                                <option value="High">High</option>
                            </select>
                        </div>
                        <div className="space-y-2">
                            <label className="text-sm text-text-muted">Timeframes (H1, M15)</label>
                            <input name="timeframes" className="w-full bg-surface/50 border border-white/10 rounded-lg px-4 py-2 text-white" />
                        </div>
                        <div className="space-y-2">
                            <label className="text-sm text-text-muted">Cap. Mínimo ($)</label>
                            <input type="number" name="minCapital" defaultValue={500} className="w-full bg-surface/50 border border-white/10 rounded-lg px-4 py-2 text-white" />
                        </div>
                    </div>

                    <div className="grid sm:grid-cols-2 gap-6 p-4 rounded-xl bg-brand/5 border border-brand/20">
                        <div className="space-y-2">
                            <label className="text-sm font-bold text-brand-light">Descargable: Archivo .ex5</label>
                            <input type="file" name="ex5File" accept=".ex5" className="w-full text-sm text-text-muted file:bg-surface-light file:border-none file:text-white file:px-4 file:py-2 file:rounded-lg file:mr-4 hover:file:bg-brand/20 transition-all cursor-pointer" />
                        </div>
                        <div className="space-y-2">
                            <label className="text-sm font-bold text-brand-light">Descargable: Manual .pdf</label>
                            <input type="file" name="pdfFile" accept="application/pdf" className="w-full text-sm text-text-muted file:bg-surface-light file:border-none file:text-white file:px-4 file:py-2 file:rounded-lg file:mr-4 hover:file:bg-brand/20 transition-all cursor-pointer" />
                        </div>
                    </div>

                    <Button type="submit" disabled={loading} size="lg" className="w-full sm:w-auto">
                        {loading ? "Creando y Subiendo..." : "Publicar Bot"}
                    </Button>
                </form>
            </div>
        </div>
    );
}

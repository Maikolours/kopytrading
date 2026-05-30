"use client";

import { useState, useEffect } from "react";
import { useSession } from "next-auth/react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/Button";

export default function AdminPage() {
    const { data: session, status } = useSession();
    const router = useRouter();
    
    const [activeTab, setActiveTab] = useState<"metrics" | "publish">("metrics");
    const [metrics, setMetrics] = useState<any>(null);
    const [loadingMetrics, setLoadingMetrics] = useState(true);
    
    // Estados para el formulario de publicación
    const [loadingForm, setLoadingForm] = useState(false);
    const [message, setMessage] = useState("");

    // Bloqueo y redirección de seguridad
    useEffect(() => {
        if (status === "unauthenticated") {
            router.push("/login");
        } else if (session?.user && (session.user as any).role !== "ADMIN") {
            router.push("/dashboard");
        }
    }, [status, session, router]);

    // Cargar métricas del servidor
    useEffect(() => {
        if (session?.user && (session.user as any).role === "ADMIN") {
            fetchMetrics();
        }
    }, [session]);

    const fetchMetrics = async () => {
        setLoadingMetrics(true);
        try {
            const res = await fetch("/api/admin/metrics");
            if (res.ok) {
                const data = await res.json();
                setMetrics(data);
            }
        } catch (e) {
            console.error("Error fetching metrics:", e);
        } finally {
            setLoadingMetrics(false);
        }
    };

    const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
        e.preventDefault();
        setLoadingForm(true);
        setMessage("");

        const formData = new FormData(e.currentTarget);

        try {
            const res = await fetch("/api/admin/bots", {
                method: "POST",
                body: formData,
            });

            if (res.ok) {
                setMessage("✅ Bot creado correctamente en la base de datos.");
                fetchMetrics(); // Recargar datos
                (e.target as HTMLFormElement).reset();
            } else {
                const data = await res.json();
                setMessage(`❌ Error: ${data.error || "Algo salió mal"}`);
            }
        } catch (error) {
            setMessage("❌ Error fatal al subir.");
        } finally {
            setLoadingForm(false);
        }
    };

    if (status === "loading" || !session || (session.user as any).role !== "ADMIN") {
        return (
            <div className="min-h-screen flex items-center justify-center bg-surface">
                <div className="text-center space-y-4">
                    <div className="w-12 h-12 border-4 border-brand border-t-transparent rounded-full animate-spin mx-auto"></div>
                    <p className="text-text-muted font-medium animate-pulse">Verificando Credenciales de Administrador...</p>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen pt-24 pb-12 px-4 sm:px-6 lg:px-8 bg-surface">
            <div className="max-w-6xl mx-auto space-y-8">
                
                {/* Header */}
                <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 border-b border-white/10 pb-6">
                    <div>
                        <h1 className="text-3xl font-bold text-white flex items-center gap-2">
                            <span>🛡️</span> Panel de Desarrollador / Admin
                        </h1>
                        <p className="text-text-muted text-sm mt-1">Monitoreo en tiempo real de registros, ventas, descargas y terminales MT5 activas.</p>
                    </div>
                    
                    {/* Tabs Selector */}
                    <div className="flex bg-surface-light/50 p-1 rounded-xl border border-white/5 self-start md:self-auto">
                        <button 
                            onClick={() => setActiveTab("metrics")}
                            className={`px-4 py-2 rounded-lg text-sm font-semibold transition-all ${activeTab === "metrics" ? "bg-brand text-white shadow-md shadow-brand/20" : "text-text-muted hover:text-white"}`}
                        >
                            📊 Panel de Control
                        </button>
                        <button 
                            onClick={() => setActiveTab("publish")}
                            className={`px-4 py-2 rounded-lg text-sm font-semibold transition-all ${activeTab === "publish" ? "bg-brand text-white shadow-md shadow-brand/20" : "text-text-muted hover:text-white"}`}
                        >
                            🤖 Publicar Bot
                        </button>
                    </div>
                </div>

                {activeTab === "metrics" ? (
                    <div className="space-y-8">
                        {/* Metrics Grid Cards */}
                        <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
                            
                            {/* Card 1: Revenue */}
                            <div className="glass-card p-6 border border-white/10 rounded-2xl flex flex-col justify-between space-y-4">
                                <div className="flex justify-between items-start">
                                    <span className="text-sm font-semibold text-text-muted uppercase tracking-wider">Ingresos Totales</span>
                                    <span className="text-2xl">💰</span>
                                </div>
                                <div>
                                    <h3 className="text-3xl font-bold text-brand-light">
                                        {loadingMetrics ? "..." : `$${metrics?.metrics?.totalRevenue?.toFixed(2) || "0.00"}`}
                                    </h3>
                                    <p className="text-xs text-text-muted mt-1">Ventas globales de EAs completadas</p>
                                </div>
                            </div>

                            {/* Card 2: Registrations */}
                            <div className="glass-card p-6 border border-white/10 rounded-2xl flex flex-col justify-between space-y-4">
                                <div className="flex justify-between items-start">
                                    <span className="text-sm font-semibold text-text-muted uppercase tracking-wider">Usuarios Registrados</span>
                                    <span className="text-2xl">👤</span>
                                </div>
                                <div>
                                    <h3 className="text-3xl font-bold text-white">
                                        {loadingMetrics ? "..." : metrics?.metrics?.totalUsers || "0"}
                                    </h3>
                                    <p className="text-xs text-text-muted mt-1">Clientes registrados en la plataforma</p>
                                </div>
                            </div>

                            {/* Card 3: Active MT5 Syncs */}
                            <div className="glass-card p-6 border border-white/10 rounded-2xl flex flex-col justify-between space-y-4">
                                <div className="flex justify-between items-start">
                                    <span className="text-sm font-semibold text-text-muted uppercase tracking-wider">Licencias MT5 Activas</span>
                                    <span className="text-2xl">🟢</span>
                                </div>
                                <div>
                                    <h3 className="text-3xl font-bold text-springgreen">
                                        {loadingMetrics ? "..." : metrics?.metrics?.activeSessionsCount || "0"}
                                    </h3>
                                    <p className="text-xs text-text-muted mt-1">Terminales MT5 sincronizadas en vivo hoy</p>
                                </div>
                            </div>
                        </div>

                        {/* Live MT5 Syncs Table */}
                        <div className="glass-card border border-white/10 p-6 rounded-2xl space-y-4">
                            <div className="flex justify-between items-center">
                                <h3 className="text-lg font-bold text-white flex items-center gap-2">
                                    <span className="w-2.5 h-2.5 rounded-full bg-springgreen animate-ping"></span>
                                    Cuentas MT5 Sincronizadas en Vivo
                                </h3>
                                <Button size="sm" variant="outline" onClick={fetchMetrics} disabled={loadingMetrics} className="text-xs px-3 py-1">
                                    🔄 Actualizar
                                </Button>
                            </div>
                            <div className="overflow-x-auto">
                                <table className="w-full text-left border-collapse">
                                    <thead>
                                        <tr className="border-b border-white/10 text-xs text-text-muted uppercase tracking-wider">
                                            <th className="py-3 px-4 font-semibold">Cuenta</th>
                                            <th className="py-3 px-4 font-semibold">Usuario</th>
                                            <th className="py-3 px-4 font-semibold">Bot Asignado</th>
                                            <th className="py-3 px-4 font-semibold">Balance</th>
                                            <th className="py-3 px-4 font-semibold">Equidad</th>
                                            <th className="py-3 px-4 font-semibold">Estado</th>
                                            <th className="py-3 px-4 font-semibold">Última Sincronización</th>
                                        </tr>
                                    </thead>
                                    <tbody className="text-sm text-white divide-y divide-white/5">
                                        {loadingMetrics ? (
                                            <tr>
                                                <td colSpan={7} className="py-8 text-center text-text-muted">Cargando terminales...</td>
                                            </tr>
                                        ) : !metrics?.activeSessions || metrics.activeSessions.length === 0 ? (
                                            <tr>
                                                <td colSpan={7} className="py-8 text-center text-text-muted">No hay terminales MT5 activas actualmente.</td>
                                            </tr>
                                        ) : (
                                            metrics.activeSessions.map((s: any) => (
                                                <tr key={s.id} className="hover:bg-white/5 transition-all">
                                                    <td className="py-3 px-4 font-bold text-brand-light">#{s.account}</td>
                                                    <td className="py-3 px-4 text-xs text-text-muted">{s.userEmail}</td>
                                                    <td className="py-3 px-4 text-xs font-semibold">{s.botName}</td>
                                                    <td className="py-3 px-4 font-semibold text-springgreen">${s.balance?.toFixed(2)}</td>
                                                    <td className="py-3 px-4 font-semibold">${s.equity?.toFixed(2)}</td>
                                                    <td className="py-3 px-4 text-xs">
                                                        <span className={`px-2 py-0.5 rounded-full font-bold ${s.isActive ? "bg-springgreen/10 text-springgreen border border-springgreen/20" : "bg-danger/10 text-danger border border-danger/20"}`}>
                                                            {s.isActive ? "ONLINE" : "PAUSED"}
                                                        </span>
                                                    </td>
                                                    <td className="py-3 px-4 text-xs text-text-muted">
                                                        {new Date(s.lastActivity).toLocaleTimeString()} ({new Date(s.lastActivity).toLocaleDateString()})
                                                    </td>
                                                </tr>
                                            ))
                                        )}
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        {/* Split Grid: Recent Signups and Downloads */}
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                            
                            {/* Column 1: Recent Users */}
                            <div className="glass-card border border-white/10 p-6 rounded-2xl space-y-4">
                                <h3 className="text-lg font-bold text-white">Últimos Registros</h3>
                                <div className="overflow-y-auto max-h-[300px]">
                                    <table className="w-full text-left border-collapse">
                                        <thead>
                                            <tr className="border-b border-white/10 text-xs text-text-muted uppercase tracking-wider">
                                                <th className="py-2 px-3 font-semibold">Email</th>
                                                <th className="py-2 px-3 font-semibold">Nombre</th>
                                                <th className="py-2 px-3 font-semibold">Fecha de Alta</th>
                                            </tr>
                                        </thead>
                                        <tbody className="text-xs text-white divide-y divide-white/5">
                                            {loadingMetrics ? (
                                                <tr>
                                                    <td colSpan={3} className="py-4 text-center text-text-muted">Cargando...</td>
                                                </tr>
                                            ) : !metrics?.recentUsers || metrics.recentUsers.length === 0 ? (
                                                <tr>
                                                    <td colSpan={3} className="py-4 text-center text-text-muted">No hay registros.</td>
                                                </tr>
                                            ) : (
                                                metrics.recentUsers.map((u: any) => (
                                                    <tr key={u.id} className="hover:bg-white/5 transition-all">
                                                        <td className="py-2 px-3 font-semibold">{u.email}</td>
                                                        <td className="py-2 px-3 text-text-muted">{u.name || "Sin nombre"}</td>
                                                        <td className="py-2 px-3 text-text-muted">
                                                            {new Date(u.createdAt).toLocaleDateString()}
                                                        </td>
                                                    </tr>
                                                ))
                                            )}
                                        </tbody>
                                    </table>
                                </div>
                            </div>

                            {/* Column 2: Recent Downloads */}
                            <div className="glass-card border border-white/10 p-6 rounded-2xl space-y-4">
                                <h3 className="text-lg font-bold text-white">Historial de Descargas</h3>
                                <div className="overflow-y-auto max-h-[300px]">
                                    <table className="w-full text-left border-collapse">
                                        <thead>
                                            <tr className="border-b border-white/10 text-xs text-text-muted uppercase tracking-wider">
                                                <th className="py-2 px-3 font-semibold">Usuario</th>
                                                <th className="py-2 px-3 font-semibold">Bot / EA</th>
                                                <th className="py-2 px-3 font-semibold">Versión</th>
                                                <th className="py-2 px-3 font-semibold">Fecha</th>
                                            </tr>
                                        </thead>
                                        <tbody className="text-xs text-white divide-y divide-white/5">
                                            {loadingMetrics ? (
                                                <tr>
                                                    <td colSpan={4} className="py-4 text-center text-text-muted">Cargando...</td>
                                                </tr>
                                            ) : !metrics?.downloads || metrics.downloads.length === 0 ? (
                                                <tr>
                                                    <td colSpan={4} className="py-4 text-center text-text-muted">No hay descargas registradas.</td>
                                                </tr>
                                            ) : (
                                                metrics.downloads.map((d: any) => (
                                                    <tr key={d.id} className="hover:bg-white/5 transition-all">
                                                        <td className="py-2 px-3 font-semibold">{d.userEmail}</td>
                                                        <td className="py-2 px-3 text-brand-light font-semibold">{d.botName}</td>
                                                        <td className="py-2 px-3 text-center">{d.downloadedVersion}</td>
                                                        <td className="py-2 px-3 text-text-muted">
                                                            {new Date(d.downloadedAt).toLocaleDateString()}
                                                        </td>
                                                    </tr>
                                                ))
                                            )}
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>

                    </div>
                ) : (
                    /* Existing Form to Publish Bots */
                    <div className="glass-card p-8 border border-white/10 rounded-2xl">
                        <h2 className="text-xl font-bold text-white mb-6 flex items-center gap-2">
                            <span>🤖</span> Publicar un Nuevo Bot en la Base de Datos
                        </h2>

                        {message && (
                            <div className="p-4 mb-6 rounded-lg bg-surface-light border border-white/10 text-white font-medium">
                                {message}
                            </div>
                        )}

                        <form onSubmit={handleSubmit} className="space-y-6">
                            <div className="grid sm:grid-cols-2 gap-6">
                                <div className="space-y-2">
                                    <label className="text-sm text-text-muted">Nombre del Bot</label>
                                    <input name="name" required className="w-full bg-surface/50 border border-white/10 rounded-lg px-4 py-2 text-white outline-none focus:border-brand transition-all" />
                                </div>
                                <div className="space-y-2">
                                    <label className="text-sm text-text-muted">Precio (USD)</label>
                                    <input type="number" step="0.01" name="price" required className="w-full bg-surface/50 border border-white/10 rounded-lg px-4 py-2 text-white outline-none focus:border-brand transition-all" />
                                </div>
                                <div className="space-y-2">
                                    <label className="text-sm text-text-muted">Instrumento (XAUUSD, EURUSD...)</label>
                                    <input name="instrument" required className="w-full bg-surface/50 border border-white/10 rounded-lg px-4 py-2 text-white outline-none focus:border-brand transition-all" />
                                </div>
                                <div className="space-y-2">
                                    <label className="text-sm text-text-muted">Tipo de Estrategia</label>
                                    <input name="strategyType" defaultValue="Scalping Avanzado" required className="w-full bg-surface/50 border border-white/10 rounded-lg px-4 py-2 text-white outline-none focus:border-brand transition-all" />
                                </div>
                            </div>

                            <div className="space-y-2">
                                <label className="text-sm text-text-muted">Descripción</label>
                                <textarea name="description" required rows={4} className="w-full bg-surface/50 border border-white/10 rounded-lg px-4 py-2 text-white outline-none focus:border-brand transition-all"></textarea>
                            </div>

                            <div className="grid sm:grid-cols-3 gap-6">
                                <div className="space-y-2">
                                    <label className="text-sm text-text-muted">Nivel de Riesgo</label>
                                    <select name="riskLevel" className="w-full bg-surface/50 border border-white/10 rounded-lg px-4 py-2 text-white outline-none focus:border-brand transition-all">
                                        <option value="Low">Low</option>
                                        <option value="Medium">Medium</option>
                                        <option value="High">High</option>
                                    </select>
                                </div>
                                <div className="space-y-2">
                                    <label className="text-sm text-text-muted">Timeframes (H1, M15)</label>
                                    <input name="timeframes" className="w-full bg-surface/50 border border-white/10 rounded-lg px-4 py-2 text-white outline-none focus:border-brand transition-all" />
                                </div>
                                <div className="space-y-2">
                                    <label className="text-sm text-text-muted">Cap. Mínimo ($)</label>
                                    <input type="number" name="minCapital" defaultValue={500} className="w-full bg-surface/50 border border-white/10 rounded-lg px-4 py-2 text-white outline-none focus:border-brand transition-all" />
                                </div>
                            </div>

                            <Button type="submit" disabled={loadingForm} size="lg" className="w-full sm:w-auto">
                                {loadingForm ? "Publicando en la BD..." : "Publicar Bot"}
                            </Button>
                        </form>
                    </div>
                )}
            </div>
        </div>
    );
}

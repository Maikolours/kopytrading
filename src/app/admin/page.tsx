"use client";

import React, { useState, useEffect } from "react";
import { useSession } from "next-auth/react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/Button";

export default function AdminPage() {
    const { data: session, status } = useSession();
    const router = useRouter();
    
    const [activeTab, setActiveTab] = useState<"metrics" | "traffic" | "publish" | "update">("metrics");
    const [analyticsData, setAnalyticsData] = useState<any>(null);
    const [loadingAnalytics, setLoadingAnalytics] = useState(false);
    const [customClientTag, setCustomClientTag] = useState("");
    const [copiedCustomLink, setCopiedCustomLink] = useState(false);
    const [metrics, setMetrics] = useState<any>(null);
    const [loadingMetrics, setLoadingMetrics] = useState(true);
    
    // Estados para el formulario de publicación
    const [loadingForm, setLoadingForm] = useState(false);
    const [message, setMessage] = useState("");

    // Estados para el formulario de actualización de versión
    const [bots, setBots] = useState<any[]>([]);
    const [loadingBots, setLoadingBots] = useState(false);
    const [updatingBotId, setUpdatingBotId] = useState("");
    const [newVersion, setNewVersion] = useState("");
    const [sendEmails, setSendEmails] = useState(true);
    const [changelog, setChangelog] = useState("");
    const [isUrgent, setIsUrgent] = useState(false);
    const [ex5Path, setEx5Path] = useState("");
    const [pdfPath, setPdfPath] = useState("");
    const [updateMessage, setUpdateMessage] = useState("");
    const [updating, setUpdating] = useState(false);
    const [expandedUserEmail, setExpandedUserEmail] = useState<string | null>(null);
    const [copiedEmails, setCopiedEmails] = useState(false);

    const copyUserEmails = () => {
        if (!metrics?.recentUsers) return;
        const emails = metrics.recentUsers.map((u: any) => u.email).filter(Boolean).join(", ");
        navigator.clipboard.writeText(emails);
        setCopiedEmails(true);
        setTimeout(() => setCopiedEmails(false), 2500);
    };

    // Bloqueo y redirección de seguridad
    useEffect(() => {
        if (status === "unauthenticated") {
            router.push("/login");
        } else if (session?.user && (session.user as any).role !== "ADMIN") {
            router.push("/dashboard");
        }
    }, [status, session, router]);

    // Cargar métricas y bots del servidor
    useEffect(() => {
        if (session?.user && (session.user as any).role === "ADMIN") {
            fetchMetrics();
            fetchBots();
            fetchAnalytics();
        }
    }, [session]);

    const fetchAnalytics = async () => {
        setLoadingAnalytics(true);
        try {
            const res = await fetch("/api/admin/analytics");
            if (res.ok) {
                const data = await res.json();
                setAnalyticsData(data);
            }
        } catch (e) {
            console.error("Error fetching analytics:", e);
        } finally {
            setLoadingAnalytics(false);
        }
    };

    const fetchBots = async () => {
        setLoadingBots(true);
        try {
            const res = await fetch("/api/admin/bots");
            if (res.ok) {
                const data = await res.json();
                setBots(data.bots || []);
            }
        } catch (e) {
            console.error("Error fetching bots:", e);
        } finally {
            setLoadingBots(false);
        }
    };

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

    const handleDeleteRecord = async (type: "user" | "purchase", id: string, name: string) => {
        const confirmMsg = type === "user"
            ? `⚠️ ¿Eliminar al usuario "${name}"? Se eliminarán también todas sus descargas y licencias asociadas.`
            : `⚠️ ¿Eliminar este registro de descarga (${name})?`;

        if (!confirm(confirmMsg)) return;

        try {
            const res = await fetch(`/api/admin/metrics?type=${type}&id=${id}`, {
                method: "DELETE"
            });
            if (res.ok) {
                fetchMetrics();
            } else {
                const data = await res.json();
                alert(`Error: ${data.error || "No se pudo eliminar"}`);
            }
        } catch (e) {
            alert("Error al intentar eliminar.");
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

    const handleBotChange = (botId: string) => {
        setUpdatingBotId(botId);
        const selectedBot = bots.find(b => b.id === botId);
        if (selectedBot) {
            setNewVersion(selectedBot.version || "");
            setEx5Path(selectedBot.ex5FilePath || "");
            setPdfPath(selectedBot.pdfFilePath || "");
            setChangelog("");
            setIsUrgent(false);
        } else {
            setNewVersion("");
            setEx5Path("");
            setPdfPath("");
            setChangelog("");
            setIsUrgent(false);
        }
    };

    const handleUpdateVersion = async (e: React.FormEvent) => {
        e.preventDefault();
        setUpdating(true);
        setUpdateMessage("");
        try {
            const res = await fetch("/api/admin/bots", {
                method: "PUT",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify({
                    botProductId: updatingBotId,
                    version: newVersion,
                    sendEmails,
                    changelog,
                    isUrgent,
                    ex5FilePath: ex5Path || undefined,
                    pdfFilePath: pdfPath || undefined
                })
            });

            const data = await res.json();
            if (res.ok && data.success) {
                setUpdateMessage(`✅ Versión actualizada con éxito a v${newVersion}.` + (data.emailsSent > 0 ? ` Se enviaron ${data.emailsSent} correos electrónicos.` : ""));
                fetchBots(); // Recargar bots
                fetchMetrics(); // Recargar métricas
            } else {
                setUpdateMessage(`❌ Error: ${data.error || "No se pudo actualizar."}`);
            }
        } catch (err: any) {
            setUpdateMessage(`❌ Error fatal: ${err.message}`);
        } finally {
            setUpdating(false);
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
                            onClick={() => { setActiveTab("traffic"); fetchAnalytics(); }}
                            className={`px-4 py-2 rounded-lg text-sm font-semibold transition-all ${activeTab === "traffic" ? "bg-brand text-white shadow-md shadow-brand/20" : "text-text-muted hover:text-white"}`}
                        >
                            🌍 Visitantes y Tráfico
                        </button>
                        <button 
                            onClick={() => setActiveTab("publish")}
                            className={`px-4 py-2 rounded-lg text-sm font-semibold transition-all ${activeTab === "publish" ? "bg-brand text-white shadow-md shadow-brand/20" : "text-text-muted hover:text-white"}`}
                        >
                            🤖 Publicar Bot
                        </button>
                        <button 
                            onClick={() => setActiveTab("update")}
                            className={`px-4 py-2 rounded-lg text-sm font-semibold transition-all ${activeTab === "update" ? "bg-brand text-white shadow-md shadow-brand/20" : "text-text-muted hover:text-white"}`}
                        >
                            🔔 Actualizar Versión
                        </button>
                    </div>
                </div>

                {activeTab === "metrics" && (
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
                                <div className="flex items-center justify-between">
                                    <h3 className="text-lg font-bold text-white">Últimos Registros</h3>
                                    <button
                                        type="button"
                                        onClick={copyUserEmails}
                                        className="text-[9px] font-black uppercase tracking-wider px-2.5 py-1 rounded-lg bg-brand/20 hover:bg-brand text-brand-light hover:text-white border border-brand/40 transition-all flex items-center gap-1.5 cursor-pointer shadow-sm"
                                        title="Copiar todos los correos registrados para campañas de Email Marketing"
                                    >
                                        <span>{copiedEmails ? "✓ ¡COPIADOS!" : "📋 COPIAR EMAILS"}</span>
                                    </button>
                                </div>
                                <div className="overflow-y-auto max-h-[300px]">
                                    <table className="w-full text-left border-collapse">
                                        <thead>
                                            <tr className="border-b border-white/10 text-xs text-text-muted uppercase tracking-wider">
                                                <th className="py-2 px-3 font-semibold">Email</th>
                                                <th className="py-2 px-3 font-semibold">Nombre</th>
                                                <th className="py-2 px-3 font-semibold">Fecha</th>
                                                <th className="py-2 px-3 font-semibold text-right">Acción</th>
                                            </tr>
                                        </thead>
                                        <tbody className="text-xs text-white divide-y divide-white/5">
                                            {loadingMetrics ? (
                                                <tr>
                                                    <td colSpan={4} className="py-4 text-center text-text-muted">Cargando...</td>
                                                </tr>
                                            ) : !metrics?.recentUsers || metrics.recentUsers.length === 0 ? (
                                                <tr>
                                                    <td colSpan={4} className="py-4 text-center text-text-muted">No hay registros.</td>
                                                </tr>
                                            ) : (
                                                metrics.recentUsers.map((u: any) => (
                                                    <tr key={u.id} className="hover:bg-white/5 transition-all">
                                                        <td className="py-2 px-3 font-semibold">{u.email}</td>
                                                        <td className="py-2 px-3 text-text-muted">{u.name || "Sin nombre"}</td>
                                                        <td className="py-2 px-3 text-text-muted">
                                                            {new Date(u.createdAt).toLocaleDateString()}
                                                        </td>
                                                        <td className="py-2 px-3 text-right">
                                                            {u.email !== "viajaconsakura@gmail.com" && (
                                                                <button
                                                                    onClick={() => handleDeleteRecord("user", u.id, u.email || u.name)}
                                                                    title="Eliminar usuario y licencias"
                                                                    className="p-1 rounded bg-red-500/10 border border-red-500/20 text-red-400 hover:bg-red-500 hover:text-white transition-all text-xs"
                                                                >
                                                                    🗑️
                                                                </button>
                                                            )}
                                                        </td>
                                                    </tr>
                                                ))
                                            )}
                                        </tbody>
                                    </table>
                                </div>
                            </div>

                            {/* Column 2: Recent Downloads (Grouped by User) */}
                            <div className="glass-card border border-white/10 p-6 rounded-2xl space-y-4">
                                <div className="flex items-center justify-between">
                                    <h3 className="text-lg font-bold text-white">Historial de Descargas</h3>
                                    <span className="text-[10px] text-text-muted font-mono font-bold bg-white/5 px-2 py-0.5 rounded-full border border-white/10">
                                        {metrics?.groupedDownloads?.length || 0} usuarios únicos
                                    </span>
                                </div>
                                <div className="overflow-y-auto max-h-[300px]">
                                    <table className="w-full text-left border-collapse">
                                        <thead>
                                            <tr className="border-b border-white/10 text-xs text-text-muted uppercase tracking-wider">
                                                <th className="py-2 px-3 font-semibold">Usuario</th>
                                                <th className="py-2 px-3 font-semibold">Bots</th>
                                                <th className="py-2 px-3 font-semibold text-center">Total</th>
                                                <th className="py-2 px-3 font-semibold text-right">Live</th>
                                            </tr>
                                        </thead>
                                        <tbody className="text-xs text-white divide-y divide-white/5">
                                            {loadingMetrics ? (
                                                <tr>
                                                    <td colSpan={4} className="py-4 text-center text-text-muted">Cargando...</td>
                                                </tr>
                                            ) : !metrics?.groupedDownloads || metrics.groupedDownloads.length === 0 ? (
                                                <tr>
                                                    <td colSpan={4} className="py-4 text-center text-text-muted">No hay descargas registradas.</td>
                                                </tr>
                                            ) : (
                                                metrics.groupedDownloads.map((group: any) => (
                                                    <React.Fragment key={group.userEmail}>
                                                        <tr 
                                                            onClick={() => setExpandedUserEmail(expandedUserEmail === group.userEmail ? null : group.userEmail)}
                                                            className="hover:bg-white/5 transition-all cursor-pointer group"
                                                        >
                                                            <td className="py-2.5 px-3">
                                                                <p className="font-semibold text-white group-hover:text-brand-light transition-colors">{group.userEmail}</p>
                                                                <p className="text-[10px] text-text-muted">{group.userName}</p>
                                                            </td>
                                                            <td className="py-2.5 px-3">
                                                                <div className="flex flex-wrap gap-1">
                                                                    {group.bots.map((b: string, idx: number) => (
                                                                        <span key={idx} className="text-[8.5px] px-1.5 py-0.5 rounded bg-brand/10 border border-brand/20 text-brand-light font-medium whitespace-nowrap">
                                                                            {b.replace("MAIKO PRO GOLD ", "").replace(" FIX", "")}
                                                                        </span>
                                                                    ))}
                                                                </div>
                                                            </td>
                                                            <td className="py-2.5 px-3 text-center">
                                                                <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-white/10 text-white font-black text-[9px] hover:bg-brand hover:text-white transition-all shadow-sm">
                                                                    📦 {group.totalDownloads}
                                                                    <span className="text-[8px] opacity-60">{expandedUserEmail === group.userEmail ? '▲' : '▼'}</span>
                                                                </span>
                                                            </td>
                                                            <td className="py-2.5 px-3 text-right">
                                                                <span className={`inline-flex items-center gap-1 text-[8px] font-black uppercase px-2 py-0.5 rounded-full ${group.isOnline ? 'bg-success/20 text-success border border-success/30' : 'bg-white/5 text-text-muted border border-white/10'}`}>
                                                                    <span className={`w-1.5 h-1.5 rounded-full ${group.isOnline ? 'bg-success animate-ping' : 'bg-white/30'}`} />
                                                                    {group.isOnline ? 'ONLINE' : 'OFFLINE'}
                                                                </span>
                                                            </td>
                                                        </tr>
                                                        {expandedUserEmail === group.userEmail && (
                                                            <tr className="bg-black/40 border-b border-brand/20">
                                                                <td colSpan={4} className="p-3">
                                                                    <div className="space-y-2 bg-surface/60 p-3 rounded-xl border border-white/10">
                                                                        <p className="text-[9px] font-black text-brand-light uppercase tracking-widest flex items-center justify-between">
                                                                            <span>Desglose de descargas y terminales ({group.userEmail}):</span>
                                                                            <span className="text-white/40 font-mono text-[8px]">Última actividad: {new Date(group.lastDownloadedAt).toLocaleDateString()}</span>
                                                                        </p>
                                                                        <div className="space-y-1.5 max-h-[160px] overflow-y-auto divide-y divide-white/5">
                                                                            {group.items.map((it: any) => (
                                                                                <div key={it.purchaseId} className="pt-1.5 first:pt-0 flex items-center justify-between text-[10px] gap-2">
                                                                                    <div className="space-y-0.5 min-w-0">
                                                                                        <p className="font-bold text-white truncate">{it.botName}</p>
                                                                                        <p className="text-[9px] text-text-muted font-mono">
                                                                                            v{it.version || '1.0'} · Cuenta: <span className="text-brand-light font-bold">#{it.account}</span>
                                                                                        </p>
                                                                                    </div>
                                                                                    <div className="flex items-center gap-2 shrink-0">
                                                                                        <span className="text-text-muted text-[9px]">{new Date(it.date).toLocaleDateString()}</span>
                                                                                        <span className={`font-mono text-[9px] font-bold ${it.isOnline ? 'text-success' : 'text-text-muted'}`}>
                                                                                            ${Number(it.balance || 0).toFixed(2)}
                                                                                        </span>
                                                                                        <button
                                                                                            onClick={(e) => {
                                                                                                e.stopPropagation();
                                                                                                handleDeleteRecord("purchase", it.purchaseId, `${group.userEmail} - ${it.botName}`);
                                                                                            }}
                                                                                            className="p-1 rounded bg-red-500/10 hover:bg-red-500 text-red-400 hover:text-white transition-all text-[9px]"
                                                                                            title="Eliminar este registro"
                                                                                        >
                                                                                            🗑️
                                                                                        </button>
                                                                                    </div>
                                                                                </div>
                                                                            ))}
                                                                        </div>
                                                                    </div>
                                                                </td>
                                                            </tr>
                                                        )}
                                                    </React.Fragment>
                                                ))
                                            )}
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>

                    </div>
                )}
                {/* TAB: TRAFFIC & VISITOR GEOLOCATION ANALYTICS */}
                {activeTab === "traffic" && (
                    <div className="space-y-8">
                        {/* Header con botón de refrescar */}
                        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 glass-card p-6 border border-white/10 rounded-2xl">
                            <div>
                                <h2 className="text-xl font-bold text-white flex items-center gap-2">
                                    <span>🌍</span> Analítica de Visitantes y Geolocalización en Tiempo Real
                                </h2>
                                <p className="text-text-muted text-xs sm:text-sm mt-1">
                                    Conteo independiente y privado de visitas, países, dispositivos y fuentes de tráfico (100% legal y anónimo).
                                </p>
                            </div>
                            <Button 
                                onClick={fetchAnalytics}
                                disabled={loadingAnalytics}
                                size="sm"
                                className="self-start sm:self-auto shrink-0 flex items-center gap-2"
                            >
                                <span>🔄</span> {loadingAnalytics ? "Actualizando..." : "Actualizar en Vivo"}
                            </Button>
                        </div>

                        {/* Summary Cards */}
                        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
                            <div className="glass-card p-6 border border-white/10 rounded-2xl flex flex-col justify-between space-y-2">
                                <span className="text-xs font-semibold text-text-muted uppercase tracking-wider">Visitas Hoy</span>
                                <div className="text-3xl font-bold text-brand-light">
                                    {analyticsData?.summary?.todayHits || 0}
                                </div>
                                <span className="text-[11px] text-white/50">
                                    👤 {analyticsData?.summary?.uniqueToday || 0} visitantes únicos hoy
                                </span>
                            </div>

                            <div className="glass-card p-6 border border-white/10 rounded-2xl flex flex-col justify-between space-y-2">
                                <span className="text-xs font-semibold text-text-muted uppercase tracking-wider">Últimos 7 Días</span>
                                <div className="text-3xl font-bold text-white">
                                    {analyticsData?.summary?.weekHits || 0}
                                </div>
                                <span className="text-[11px] text-white/50">
                                    👤 {analyticsData?.summary?.uniqueWeek || 0} visitantes únicos en 7d
                                </span>
                            </div>

                            <div className="glass-card p-6 border border-white/10 rounded-2xl flex flex-col justify-between space-y-2">
                                <span className="text-xs font-semibold text-text-muted uppercase tracking-wider">Últimos 30 Días</span>
                                <div className="text-3xl font-bold text-success">
                                    {analyticsData?.summary?.monthHits || 0}
                                </div>
                                <span className="text-[11px] text-white/50">
                                    👤 {analyticsData?.summary?.uniqueMonth || 0} visitantes únicos en el mes
                                </span>
                            </div>

                            <div className="glass-card p-6 border border-white/10 rounded-2xl flex flex-col justify-between space-y-2">
                                <span className="text-xs font-semibold text-text-muted uppercase tracking-wider">Total Histórico</span>
                                <div className="text-3xl font-bold text-accent">
                                    {analyticsData?.summary?.totalHits || 0}
                                </div>
                                <span className="text-[11px] text-white/50">
                                    📈 Páginas vistas acumuladas
                                </span>
                            </div>
                        </div>

                        {/* Generador de Enlaces Personalizados para Redes / Clientes */}
                        <div className="glass-card p-6 border border-brand/20 bg-brand/5 rounded-2xl space-y-4">
                            <div className="flex items-center gap-2">
                                <span className="text-xl">🎯</span>
                                <h3 className="text-base font-bold text-white">Generador de Enlaces para Instagram / Facebook / Clientes Privados</h3>
                            </div>
                            <p className="text-xs text-text-muted">
                                Escribe el nombre de un cliente, post o red social (ej: <code className="text-brand-light">instagram_bio</code>, <code className="text-brand-light">carlos_trading</code>, <code className="text-brand-light">facebook_post</code>). Cuando entren por ese enlace, sabrás al instante quién es y qué está viendo.
                            </p>
                            <div className="flex flex-col sm:flex-row items-center gap-3">
                                <input 
                                    type="text" 
                                    placeholder="Nombre del cliente o campaña (ej: carlos_trading)" 
                                    value={customClientTag}
                                    onChange={(e) => setCustomClientTag(e.target.value.toLowerCase().replace(/[^a-z0-9_-]/g, ""))}
                                    className="w-full sm:w-80 px-4 py-2 bg-black/60 border border-white/10 rounded-xl text-sm text-white focus:outline-none focus:border-brand"
                                />
                                <div className="flex-1 w-full bg-black/40 border border-white/10 px-4 py-2 rounded-xl text-xs text-brand-light font-mono truncate">
                                    {`https://www.kopytrading.com/?cliente=${customClientTag || "carlos_trading"}`}
                                </div>
                                <Button 
                                    onClick={() => {
                                        const url = `https://www.kopytrading.com/?cliente=${customClientTag || "carlos_trading"}`;
                                        navigator.clipboard.writeText(url);
                                        setCopiedCustomLink(true);
                                        setTimeout(() => setCopiedCustomLink(false), 2500);
                                    }}
                                    size="sm"
                                    className="shrink-0 w-full sm:w-auto"
                                >
                                    {copiedCustomLink ? "✅ ¡Copiado!" : "📋 Copiar Enlace"}
                                </Button>
                            </div>
                        </div>

                        {/* Grids de Países, Ciudades, Fuentes y Dispositivos */}
                        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                            
                            {/* Países y Ciudades */}
                            <div className="glass-card p-6 border border-white/10 rounded-2xl space-y-6">
                                <div>
                                    <h3 className="text-base font-bold text-white flex items-center gap-2 mb-1">
                                        <span>🗺️</span> Principales Países (Últimos 30 Días)
                                    </h3>
                                    <p className="text-xs text-text-muted">De dónde vienen las visitas a la página.</p>
                                </div>

                                {loadingAnalytics ? (
                                    <div className="py-8 text-center text-xs text-text-muted">Cargando países...</div>
                                ) : !analyticsData?.topCountries || analyticsData.topCountries.length === 0 ? (
                                    <div className="py-8 text-center text-xs text-text-muted bg-white/[0.02] rounded-xl border border-white/5">
                                        Aún no hay visitas registradas hoy. ¡Comparte tu primer enlace para ver los datos aquí!
                                    </div>
                                ) : (
                                    <div className="space-y-3">
                                        {analyticsData.topCountries.map((c: any, idx: number) => {
                                            const totalHitsInPeriod = analyticsData.summary.monthHits || 1;
                                            const percentage = Math.round((c.count / totalHitsInPeriod) * 100);
                                            const flag = (c.code === "ES" ? "🇪🇸" : c.code === "MX" ? "🇲🇽" : c.code === "CO" ? "🇨🇴" : c.code === "AR" ? "🇦🇷" : c.code === "CL" ? "🇨🇱" : c.code === "PE" ? "🇵🇪" : c.code === "US" ? "🇺🇸" : c.code === "VE" ? "🇻🇪" : c.code === "EC" ? "🇪🇨" : "🌐");
                                            return (
                                                <div key={idx} className="space-y-1">
                                                    <div className="flex justify-between items-center text-xs">
                                                        <span className="font-semibold text-white flex items-center gap-2">
                                                            <span>{flag}</span> {c.country} ({c.code})
                                                        </span>
                                                        <span className="text-text-muted font-mono">{c.count} visitas ({percentage}%)</span>
                                                    </div>
                                                    <div className="w-full bg-white/5 h-2 rounded-full overflow-hidden">
                                                        <div className="bg-brand h-full rounded-full transition-all duration-500" style={{ width: `${Math.max(5, percentage)}%` }} />
                                                    </div>
                                                </div>
                                            );
                                        })}
                                    </div>
                                )}

                                {/* Ciudades */}
                                <div className="border-t border-white/10 pt-4">
                                    <h4 className="text-xs font-bold text-white uppercase tracking-wider mb-3">Ciudades Más Activas</h4>
                                    <div className="flex flex-wrap gap-2">
                                        {!analyticsData?.topCities || analyticsData.topCities.length === 0 ? (
                                            <span className="text-xs text-text-muted">Sin datos de ciudad aún</span>
                                        ) : (
                                            analyticsData.topCities.map((ct: any, idx: number) => (
                                                <span key={idx} className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs bg-surface border border-white/10 text-white/90">
                                                    📍 {ct.city} <span className="text-brand-light font-bold">({ct.count})</span>
                                                </span>
                                            ))
                                        )}
                                    </div>
                                </div>
                            </div>

                            {/* Origen del Tráfico y Dispositivos */}
                            <div className="glass-card p-6 border border-white/10 rounded-2xl space-y-6">
                                <div>
                                    <h3 className="text-base font-bold text-white flex items-center gap-2 mb-1">
                                        <span>📡</span> Fuentes de Tráfico (Cómo llegaron)
                                    </h3>
                                    <p className="text-xs text-text-muted">Redes sociales, buscadores o enlaces directos.</p>
                                </div>

                                <div className="space-y-3">
                                    {!analyticsData?.topSources || analyticsData.topSources.length === 0 ? (
                                        <div className="py-6 text-center text-xs text-text-muted bg-white/[0.02] rounded-xl border border-white/5">
                                            Esperando primeras visitas registradas.
                                        </div>
                                    ) : (
                                        analyticsData.topSources.map((s: any, idx: number) => {
                                            const totalHitsInPeriod = analyticsData.summary.monthHits || 1;
                                            const pct = Math.round((s.count / totalHitsInPeriod) * 100);
                                            const icon = s.source.includes("Instagram") ? "📱" : s.source.includes("Facebook") ? "📘" : s.source.includes("Google") ? "🔍" : s.source.includes("WhatsApp") ? "💬" : s.source.includes("Cliente") ? "👤" : "🔗";
                                            return (
                                                <div key={idx} className="flex justify-between items-center p-2.5 rounded-xl bg-surface border border-white/5 text-xs">
                                                    <span className="font-semibold text-white flex items-center gap-2">
                                                        <span>{icon}</span> {s.source}
                                                    </span>
                                                    <span className="text-brand-light font-mono font-bold">{s.count} ({pct}%)</span>
                                                </div>
                                            );
                                        })
                                    )}
                                </div>

                                {/* Dispositivos */}
                                <div className="border-t border-white/10 pt-4">
                                    <h4 className="text-xs font-bold text-white uppercase tracking-wider mb-3">Dispositivos Utilizados</h4>
                                    <div className="grid grid-cols-3 gap-3 text-center">
                                        {(() => {
                                            const total = (analyticsData?.devices || []).reduce((acc: number, d: any) => acc + d.count, 0) || 1;
                                            const mobileCount = analyticsData?.devices?.find((d: any) => d.device === "mobile")?.count || 0;
                                            const desktopCount = analyticsData?.devices?.find((d: any) => d.device === "desktop")?.count || 0;
                                            const tabletCount = analyticsData?.devices?.find((d: any) => d.device === "tablet")?.count || 0;

                                            return (
                                                <>
                                                    <div className="p-3 rounded-xl bg-surface border border-white/5">
                                                        <div className="text-xl mb-1">📱</div>
                                                        <div className="text-xs text-text-muted">Móvil</div>
                                                        <div className="text-sm font-bold text-white mt-1">{Math.round((mobileCount / total) * 100)}%</div>
                                                        <div className="text-[10px] text-white/40">{mobileCount} visitas</div>
                                                    </div>
                                                    <div className="p-3 rounded-xl bg-surface border border-white/5">
                                                        <div className="text-xl mb-1">💻</div>
                                                        <div className="text-xs text-text-muted">Ordenador</div>
                                                        <div className="text-sm font-bold text-white mt-1">{Math.round((desktopCount / total) * 100)}%</div>
                                                        <div className="text-[10px] text-white/40">{desktopCount} visitas</div>
                                                    </div>
                                                    <div className="p-3 rounded-xl bg-surface border border-white/5">
                                                        <div className="text-xl mb-1">📟</div>
                                                        <div className="text-xs text-text-muted">Tablet</div>
                                                        <div className="text-sm font-bold text-white mt-1">{Math.round((tabletCount / total) * 100)}%</div>
                                                        <div className="text-[10px] text-white/40">{tabletCount} visitas</div>
                                                    </div>
                                                </>
                                            );
                                        })()}
                                    </div>
                                </div>
                            </div>
                        </div>

                        {/* Páginas Más Vistas */}
                        <div className="glass-card p-6 border border-white/10 rounded-2xl space-y-4">
                            <h3 className="text-base font-bold text-white flex items-center gap-2">
                                <span>📄</span> Páginas Más Vistas de tu Web
                            </h3>
                            <div className="overflow-x-auto">
                                <table className="w-full text-left text-xs">
                                    <thead className="bg-surface-light border-b border-white/10 text-text-muted uppercase text-[10px]">
                                        <tr>
                                            <th className="p-3">Ruta / Página</th>
                                            <th className="p-3 text-right">Visitas Registradas</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-white/5">
                                        {!analyticsData?.topPages || analyticsData.topPages.length === 0 ? (
                                            <tr>
                                                <td colSpan={2} className="p-4 text-center text-text-muted">Sin datos aún</td>
                                            </tr>
                                        ) : (
                                            analyticsData.topPages.map((p: any, idx: number) => (
                                                <tr key={idx} className="hover:bg-white/[0.02]">
                                                    <td className="p-3 font-mono text-brand-light">{p.path}</td>
                                                    <td className="p-3 text-right font-bold text-white">{p.count}</td>
                                                </tr>
                                            ))
                                        )}
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        {/* Feed en Vivo de Últimas Visitas */}
                        <div className="glass-card p-6 border border-white/10 rounded-2xl space-y-4">
                            <div className="flex justify-between items-center">
                                <div>
                                    <h3 className="text-base font-bold text-white flex items-center gap-2">
                                        <span>⚡</span> Feed en Vivo: Últimas Visitas Registradas
                                    </h3>
                                    <p className="text-xs text-text-muted">Monitoreo segundo a segundo de quién entra a la web.</p>
                                </div>
                                <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[11px] bg-green-500/10 border border-green-500/20 text-green-400 font-semibold animate-pulse">
                                    <span className="w-2 h-2 rounded-full bg-green-400"></span> Sensor Activo
                                </span>
                            </div>

                            <div className="overflow-x-auto">
                                <table className="w-full text-left text-xs">
                                    <thead className="bg-surface-light border-b border-white/10 text-text-muted uppercase text-[10px]">
                                        <tr>
                                            <th className="p-3">Fecha y Hora</th>
                                            <th className="p-3">Ubicación</th>
                                            <th className="p-3">Dispositivo / Navegador</th>
                                            <th className="p-3">Origen</th>
                                            <th className="p-3">Página Visitada</th>
                                            <th className="p-3">Identificación</th>
                                        </tr>
                                    </thead>
                                    <tbody className="divide-y divide-white/5 font-mono text-[11px]">
                                        {!analyticsData?.recentHits || analyticsData.recentHits.length === 0 ? (
                                            <tr>
                                                <td colSpan={6} className="p-8 text-center text-text-muted">
                                                    No se han registrado visitas todavía. En cuanto entre un visitante desde tu enlace de Instagram o Google aparecerá aquí al segundo.
                                                </td>
                                            </tr>
                                        ) : (
                                            analyticsData.recentHits.map((hit: any) => {
                                                const flag = (hit.countryCode === "ES" ? "🇪🇸" : hit.countryCode === "MX" ? "🇲🇽" : hit.countryCode === "CO" ? "🇨🇴" : hit.countryCode === "AR" ? "🇦🇷" : hit.countryCode === "CL" ? "🇨🇱" : hit.countryCode === "PE" ? "🇵🇪" : hit.countryCode === "US" ? "🇺🇸" : hit.countryCode === "VE" ? "🇻🇪" : hit.countryCode === "EC" ? "🇪🇨" : "🌐");
                                                const dateStr = new Date(hit.createdAt).toLocaleString("es-ES", {
                                                    day: "2-digit",
                                                    month: "2-digit",
                                                    hour: "2-digit",
                                                    minute: "2-digit",
                                                    second: "2-digit"
                                                });
                                                return (
                                                    <tr key={hit.id} className="hover:bg-white/[0.02]">
                                                        <td className="p-3 text-text-muted">{dateStr}</td>
                                                        <td className="p-3 text-white">
                                                            <span className="mr-1.5">{flag}</span>
                                                            {hit.city && hit.city !== "Desconocida" ? `${hit.city}, ` : ""}{hit.country}
                                                        </td>
                                                        <td className="p-3 text-text-muted">
                                                            {hit.device === "mobile" ? "📱 Móvil" : hit.device === "tablet" ? "📟 Tablet" : "💻 PC"} ({hit.os} / {hit.browser})
                                                        </td>
                                                        <td className="p-3">
                                                            <span className="px-2 py-0.5 rounded bg-surface border border-white/10 text-white font-sans text-[11px]">
                                                                {hit.source}
                                                            </span>
                                                        </td>
                                                        <td className="p-3 text-brand-light font-bold truncate max-w-xs">{hit.path}</td>
                                                        <td className="p-3">
                                                            {hit.clientTag ? (
                                                                <span className="px-2 py-0.5 rounded bg-brand/20 border border-brand/40 text-brand-light font-bold">
                                                                    🎯 {hit.clientTag}
                                                                </span>
                                                            ) : hit.userEmail ? (
                                                                <span className="px-2 py-0.5 rounded bg-green-500/10 border border-green-500/30 text-green-400 font-bold">
                                                                    👤 {hit.userEmail}
                                                                </span>
                                                            ) : (
                                                                <span className="text-white/30 text-[10px]">Anónimo</span>
                                                            )}
                                                        </td>
                                                    </tr>
                                                );
                                            })
                                        )}
                                    </tbody>
                                </table>
                            </div>
                        </div>

                    </div>
                )}


                {activeTab === "publish" && (
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

                {activeTab === "update" && (
                    <div className="glass-card p-8 border border-white/10 rounded-2xl">
                        <h2 className="text-xl font-bold text-white mb-6 flex items-center gap-2">
                            <span>🔔</span> Actualizar Versión de Bot y Notificar Clientes
                        </h2>

                        {updateMessage && (
                            <div className="p-4 mb-6 rounded-lg bg-surface-light border border-white/10 text-white font-medium">
                                {updateMessage}
                            </div>
                        )}

                        <form onSubmit={handleUpdateVersion} className="space-y-6">
                            <div className="grid sm:grid-cols-2 gap-6">
                                <div className="space-y-2">
                                    <label className="text-sm text-text-muted">Seleccionar Bot a Actualizar</label>
                                    <select 
                                        value={updatingBotId} 
                                        onChange={(e) => handleBotChange(e.target.value)}
                                        required 
                                        className="w-full bg-surface/50 border border-white/10 rounded-lg px-4 py-2 text-white outline-none focus:border-brand transition-all"
                                    >
                                        <option value="">-- Selecciona un Bot --</option>
                                        {bots.map((b) => (
                                            <option key={b.id} value={b.id}>
                                                {b.name} ({b.instrument}) - v{b.version}
                                            </option>
                                        ))}
                                    </select>
                                </div>
                                <div className="space-y-2">
                                    <label className="text-sm text-text-muted">Nueva Versión (ej: 11.30 o 5.84)</label>
                                    <input 
                                        type="text" 
                                        value={newVersion} 
                                        onChange={(e) => setNewVersion(e.target.value)}
                                        required 
                                        placeholder="v1.0"
                                        className="w-full bg-surface/50 border border-white/10 rounded-lg px-4 py-2 text-white outline-none focus:border-brand transition-all" 
                                    />
                                </div>
                            </div>

                            <div className="grid sm:grid-cols-2 gap-6">
                                <div className="space-y-2">
                                    <label className="text-sm text-text-muted">Ruta Archivo .EX5 (opcional)</label>
                                    <input 
                                        type="text" 
                                        value={ex5Path} 
                                        onChange={(e) => setEx5Path(e.target.value)}
                                        placeholder="/uploads/..."
                                        className="w-full bg-surface/50 border border-white/10 rounded-lg px-4 py-2 text-white outline-none focus:border-brand transition-all" 
                                    />
                                </div>
                                <div className="space-y-2">
                                    <label className="text-sm text-text-muted">Ruta Manual .PDF (opcional)</label>
                                    <input 
                                        type="text" 
                                        value={pdfPath} 
                                        onChange={(e) => setPdfPath(e.target.value)}
                                        placeholder="/uploads/..."
                                        className="w-full bg-surface/50 border border-white/10 rounded-lg px-4 py-2 text-white outline-none focus:border-brand transition-all" 
                                    />
                                </div>
                            </div>

                            <div className="space-y-2">
                                <label className="text-sm text-text-muted">Notas de la Actualización (Changelog) - Visible en el correo</label>
                                <textarea 
                                    value={changelog}
                                    onChange={(e) => setChangelog(e.target.value)}
                                    placeholder="Novedades de esta versión..."
                                    rows={3}
                                    className="w-full bg-surface/50 border border-white/10 rounded-lg px-4 py-2 text-white outline-none focus:border-brand transition-all"
                                />
                            </div>

                            <div className="flex items-center gap-3 bg-white/5 p-4 rounded-xl border border-white/5">
                                <input 
                                    type="checkbox" 
                                    id="isUrgentCheckbox"
                                    checked={isUrgent} 
                                    onChange={(e) => setIsUrgent(e.target.checked)}
                                    className="w-4 h-4 rounded text-brand focus:ring-brand accent-amber-500 bg-surface border-white/10" 
                                />
                                <label htmlFor="isUrgentCheckbox" className="text-xs text-white/80 font-semibold cursor-pointer select-none text-amber-400">
                                    ⚠️ Marcar como actualización URGENTE/CRÍTICA.
                                </label>
                            </div>

                            <div className="flex items-center gap-3 bg-white/5 p-4 rounded-xl border border-white/5">
                                <input 
                                    type="checkbox" 
                                    id="sendEmailsCheckbox"
                                    checked={sendEmails} 
                                    onChange={(e) => setSendEmails(e.target.checked)}
                                    className="w-4 h-4 rounded text-brand focus:ring-brand accent-brand bg-surface border-white/10" 
                                />
                                <label htmlFor="sendEmailsCheckbox" className="text-xs text-white/80 font-semibold cursor-pointer select-none">
                                    Enviar correo automático de nueva actualización a todos los licenciatarios activos de este producto.
                                </label>
                            </div>

                            {(() => {
                                const selectedBot = bots.find(b => b.id === updatingBotId);
                                const isSameVersion = selectedBot && selectedBot.version === newVersion && newVersion !== "";
                                
                                return (
                                    <Button 
                                        type="submit" 
                                        disabled={updating || !updatingBotId} 
                                        size="lg" 
                                        className={`w-full sm:w-auto transition-all ${isSameVersion ? "bg-surface-light border-white/20 text-white/50 hover:bg-surface-light hover:text-white" : ""}`}
                                    >
                                        {updating 
                                            ? "Actualizando..." 
                                            : isSameVersion 
                                                ? "✅ Ya Actualizado (Volver a Notificar)" 
                                                : `Actualizar a v${newVersion || "..."} y Notificar 🚀`}
                                    </Button>
                                );
                            })()}
                        </form>
                    </div>
                )}
            </div>
        </div>
    );
}

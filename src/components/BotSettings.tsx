"use client";

import { useState, useEffect } from "react";
import { Button } from "./ui/Button";
import { Card, CardHeader, CardTitle, CardContent } from "./ui/Card";
import { motion, AnimatePresence } from "framer-motion";
import { Settings2, Save, RefreshCw, AlertCircle, CheckCircle2 } from "lucide-react";

interface BotSettingsProps {
    purchaseId: string;
    account: string;
    theme: any;
    onClose?: () => void;
    compact?: boolean;
}

export function BotSettings({ purchaseId, account, theme, onClose, compact }: BotSettingsProps) {
    const [settings, setSettings] = useState<any>({
        net_cycle: 5.0,
        hedge_trigger: 3.0,
        lote_manual: 0.08,
        lote_rescate: 0.02,
        max_dd: 50.0,
        trailling_stop: 3.0,
        limit_dist: 500,
        timeframe: "M5",
        be_trigger: 120,      
        trailing_start: 180,  
        max_reentries: 2,     
        start_hour: 8,        
        end_hour: 22,
        // Sniper Specific 11.2
        lkb: 12,
        b1_be: 7.0, b1_gar: 4.0,
        b2_be: 8.0, b2_gar: 5.0,
        gr_be: 8.0, gr_gar: 5.0,
        casOn: true,
        autoRA: true
    });
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [message, setMessage] = useState<{ type: 'success' | 'error', text: string } | null>(null);

    useEffect(() => {
        fetchSettings();
    }, [purchaseId, account]);

    const fetchSettings = async () => {
        setLoading(true);
        try {
            const res = await fetch(`/api/purchase/${purchaseId}/settings?account=${account}`);
            if (res.ok) {
                const data = await res.json();
                if (data && Object.keys(data).length > 0) {
                    setSettings(data);
                }
            }
        } catch (error) {
            console.error("Error fetching settings:", error);
        } finally {
            setLoading(false);
        }
    };

    const handleSave = async () => {
        setSaving(true);
        setMessage(null);
        try {
            const res = await fetch(`/api/purchase/${purchaseId}/settings`, {
                method: 'PATCH',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ account, settings })
            });

            if (res.ok) {
                setMessage({ type: 'success', text: 'Configuración guardada. Se aplicará en el próximo ciclo.' });
                setTimeout(() => setMessage(null), 5000);
            } else {
                setMessage({ type: 'error', text: 'Error al guardar la configuración.' });
            }
        } catch (error) {
            setMessage({ type: 'error', text: 'Error de conexión.' });
        } finally {
            setSaving(false);
        }
    };

    const handleChange = (key: string, value: any) => {
        setSettings((prev: any) => ({ ...prev, [key]: value }));
    };

    if (loading) {
        return (
            <div className="flex flex-col items-center justify-center p-12 space-y-4">
                <RefreshCw className="animate-spin text-brand-light" size={32} />
                <p className="text-sm text-text-muted animate-pulse font-black uppercase tracking-widest">Cargando parámetros...</p>
            </div>
        );
    }

    return (
        <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className={compact ? "" : "space-y-6"}
        >
            <div className={compact ? `p-4 rounded-xl bg-black/40 border ${theme.border} relative overflow-hidden` : `p-6 rounded-2xl bg-black/60 border-2 ${theme.border} shadow-2xl relative overflow-hidden group`}>
                <div className={`absolute inset-0 bg-gradient-to-br ${theme.gradient} opacity-10 pointer-events-none`} />
                
                <div className={`flex items-center justify-between ${compact ? 'mb-4' : 'mb-6'} border-b border-white/5 pb-4`}>
                    <div className="flex items-center gap-3">
                        <div className={`p-2 rounded-lg bg-white/5 border border-white/10 ${theme.accent}`}>
                            <Settings2 size={20} />
                        </div>
                        <div>
                            <h4 className="text-sm font-black text-white uppercase tracking-tight">Configuración Remota</h4>
                            <p className="text-[9px] text-text-muted/60 font-black uppercase tracking-widest">Cuenta {account}</p>
                        </div>
                    </div>
                    {onClose && (
                         <button onClick={onClose} className="text-white/20 hover:text-white transition-colors">✕</button>
                    )}
                </div>

                <div className="grid sm:grid-cols-2 gap-5">
                    {/* Meta de Ciclo */}
                    <div className="space-y-2">
                        <label className="text-[10px] font-black uppercase tracking-widest text-white/40 block">Meta Ciclo ($5.00)</label>
                        <input 
                            type="number" 
                            step="0.5"
                            value={settings.net_cycle}
                            onChange={(e) => handleChange('net_cycle', parseFloat(e.target.value))}
                            className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white font-mono text-sm focus:border-brand-light/50 outline-none transition-all"
                        />
                    </div>

                    {/* Gatillo Hedge */}
                    <div className="space-y-2">
                        <label className="text-[10px] font-black uppercase tracking-widest text-white/40 block">Gatillo Hedge (USD)</label>
                        <input 
                            type="number" 
                            step="0.5"
                            value={settings.hedge_trigger}
                            onChange={(e) => handleChange('hedge_trigger', parseFloat(e.target.value))}
                            className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white font-mono text-sm focus:border-brand-light/50 outline-none transition-all"
                        />
                    </div>

                    {/* Lote Seguridad */}
                    <div className="space-y-2">
                        <label className="text-[10px] font-black uppercase tracking-widest text-white/40 block">Lote Seguridad (S)</label>
                        <input 
                            type="number" 
                            step="0.01"
                            value={settings.lote_manual}
                            onChange={(e) => handleChange('lote_manual', parseFloat(e.target.value))}
                            className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white font-mono text-sm focus:border-brand-light/50 outline-none transition-all"
                        />
                    </div>

                    {/* Lote Rescate */}
                    <div className="space-y-2">
                        <label className="text-[10px] font-black uppercase tracking-widest text-white/40 block">Lote Rescate</label>
                        <input 
                            type="number" 
                            step="0.01"
                            value={settings.lote_rescate}
                            onChange={(e) => handleChange('lote_rescate', parseFloat(e.target.value))}
                            className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white font-mono text-sm focus:border-brand-light/50 outline-none transition-all"
                        />
                    </div>

                    {/* Max Drawdown */}
                    <div className="space-y-2">
                        <label className="text-[10px] font-black uppercase tracking-widest text-white/40 block">Reset Seg. (Max DD)</label>
                        <input 
                            type="number" 
                            step="1.0"
                            value={settings.max_dd}
                            onChange={(e) => handleChange('max_dd', parseFloat(e.target.value))}
                            className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white font-mono text-sm focus:border-brand-light/50 outline-none transition-all"
                        />
                    </div>

                    {/* Trailling Stop */}
                    <div className="space-y-2">
                        <label className="text-[10px] font-black uppercase tracking-widest text-white/40 block">Trailling Stop (USD)</label>
                        <input 
                            type="number" 
                            step="0.5"
                            value={settings.trailling_stop || 0}
                            onChange={(e) => handleChange('trailling_stop', parseFloat(e.target.value))}
                            className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white font-mono text-sm focus:border-brand-light/50 outline-none transition-all"
                        />
                    </div>

                    {/* Limit Dist */}
                    <div className="space-y-2">
                        <label className="text-[10px] font-black uppercase tracking-widest text-white/40 block">Distancia Limit (Pts)</label>
                        <input 
                            type="number" 
                            step="100"
                            value={settings.limit_dist || 500}
                            onChange={(e) => handleChange('limit_dist', parseInt(e.target.value))}
                            className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white font-mono text-sm focus:border-brand-light/50 outline-none transition-all"
                        />
                    </div>

                    {/* --- SNIPER PRECISION SECTION --- */}
                    <div className="col-span-full pt-6 border-t-2 border-brand-light/30 text-[10px] font-black uppercase tracking-[0.2em] text-brand-light flex items-center gap-3">
                        <div className="w-2 h-2 bg-brand-light rounded-full animate-pulse" />
                        Ajustes Sniper v11.2.6
                    </div>

                    {/* Lookback (LKB) */}
                    <div className="space-y-2">
                        <label className="text-[10px] font-black uppercase tracking-widest text-white/40 block">Lookback (Horas)</label>
                        <select 
                            value={settings.lkb || 12}
                            onChange={(e) => handleChange('lkb', parseInt(e.target.value))}
                            className="w-full bg-brand-light/10 border border-brand-light/20 rounded-xl px-4 py-3 text-white font-black text-xs uppercase focus:border-brand-light/50 outline-none transition-all appearance-none"
                        >
                            <option value="6" className="bg-neutral-900">🚀 6H (Scalping Agresivo)</option>
                            <option value="12" className="bg-neutral-900">🛡️ 12H (Estándar Sniper)</option>
                            <option value="24" className="bg-neutral-900">🐢 24H (Swing Alta Precisión)</option>
                        </select>
                    </div>

                    {/* Lote Base Sniper */}
                    <div className="space-y-2">
                        <label className="text-[10px] font-black uppercase tracking-widest text-white/40 block">Lote Sniper Base (InpLots)</label>
                        <input 
                            type="number" 
                            step="0.01"
                            value={settings.lote_manual}
                            onChange={(e) => handleChange('lote_manual', parseFloat(e.target.value))}
                            className="w-full bg-brand-light/10 border border-brand-light/20 rounded-xl px-4 py-3 text-white font-mono text-sm focus:border-brand-light/50 outline-none transition-all"
                        />
                    </div>

                    {/* Protección B1 */}
                    <div className="space-y-2">
                        <label className="text-[10px] font-black uppercase tracking-widest text-white/40 block">Protección B1 (BE | GAR)</label>
                        <div className="flex gap-2">
                            <input 
                                type="number" 
                                value={settings.b1_be || 7.0}
                                onChange={(e) => handleChange('b1_be', parseFloat(e.target.value))}
                                className="w-1/2 bg-white/10 border border-white/10 rounded-xl px-3 py-3 text-white font-mono text-xs outline-none"
                                placeholder="BE"
                            />
                            <input 
                                type="number" 
                                value={settings.b1_gar || 4.0}
                                onChange={(e) => handleChange('b1_gar', parseFloat(e.target.value))}
                                className="w-1/2 bg-white/10 border border-white/10 rounded-xl px-3 py-3 text-white font-mono text-xs outline-none"
                                placeholder="GAR"
                            />
                        </div>
                    </div>

                    {/* Protección B2/GR */}
                    <div className="space-y-2">
                        <label className="text-[10px] font-black uppercase tracking-widest text-white/40 block">Protección B2/GR (BE | GAR)</label>
                        <div className="flex gap-2">
                            <input 
                                type="number" 
                                value={settings.b2_be || 8.0}
                                onChange={(e) => handleChange('b2_be', parseFloat(e.target.value))}
                                className="w-1/2 bg-white/10 border border-white/10 rounded-xl px-3 py-3 text-white font-mono text-xs outline-none"
                                placeholder="BE"
                            />
                            <input 
                                type="number" 
                                value={settings.b2_gar || 5.0}
                                onChange={(e) => handleChange('b2_gar', parseFloat(e.target.value))}
                                className="w-1/2 bg-white/10 border border-white/10 rounded-xl px-3 py-3 text-white font-mono text-xs outline-none"
                                placeholder="GAR"
                            />
                        </div>
                    </div>

                    {/* Toggles Sniper */}
                    <div className="col-span-full grid grid-cols-2 gap-4">
                        <button 
                            onClick={() => handleChange('casOn', !settings.casOn)}
                            className={`py-3 rounded-xl border-2 font-black text-[10px] uppercase tracking-widest transition-all ${
                                settings.casOn ? 'bg-brand/20 border-brand-light text-brand-light shadow-[0_0_10px_rgba(168,85,247,0.3)]' : 'bg-white/5 border-white/10 text-white/20'
                            }`}
                        >
                            Cascada {settings.casOn ? 'Activada ✅' : 'Apagada ❌'}
                        </button>
                        <button 
                            onClick={() => handleChange('autoRA', !settings.autoRA)}
                            className={`py-3 rounded-xl border-2 font-black text-[10px] uppercase tracking-widest transition-all ${
                                settings.autoRA ? 'bg-success/20 border-success/40 text-success shadow-[0_0_10px_rgba(34,197,94,0.3)]' : 'bg-white/5 border-white/10 text-white/20'
                            }`}
                        >
                            Re-Armar {settings.autoRA ? 'Activado ✅' : 'Apagado ❌'}
                        </button>
                    </div>
                </div>

                <AnimatePresence>
                    {message && (
                        <motion.div 
                            initial={{ opacity: 0, height: 0 }}
                            animate={{ opacity: 1, height: 'auto' }}
                            exit={{ opacity: 0, height: 0 }}
                            className={`mt-4 p-3 rounded-lg flex items-center gap-2 text-[10px] font-bold uppercase transition-all ${
                                message.type === 'success' ? 'bg-success/20 text-success border border-success/30' : 'bg-danger/20 text-danger border border-danger/30'
                            }`}
                        >
                            {message.type === 'success' ? <CheckCircle2 size={14} /> : <AlertCircle size={14} />}
                            {message.text}
                        </motion.div>
                    )}
                </AnimatePresence>

                <div className="mt-8 flex gap-3">
                    <Button 
                        fullWidth 
                        onClick={handleSave} 
                        disabled={saving}
                        className="group relative overflow-hidden py-4 h-auto rounded-xl"
                    >
                        {saving ? (
                            <RefreshCw className="animate-spin" size={18} />
                        ) : (
                            <>
                                <Save size={18} className="mr-2 group-hover:scale-110 transition-transform" />
                                <span className="font-black tracking-tighter uppercase text-sm">Guardar Cambios</span>
                            </>
                        )}
                    </Button>
                </div>
                <p className="text-center text-[8px] text-text-muted/40 uppercase font-black tracking-widest mt-4">
                    💡 Los cambios se sincronizarán en el próximo latido (aprox. 30s)
                </p>
            </div>
        </motion.div>
    );
}

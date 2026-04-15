"use client";

import React, { Component, ErrorInfo, ReactNode } from "react";
import { AlertTriangle, RefreshCcw } from "lucide-react";
import { Button } from "./ui/Button";

interface Props {
  children?: ReactNode;
  fallbackTitle?: string;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  public state: State = {
    hasError: false,
    error: null,
  };

  public static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  public componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error("Uncaught error:", error, errorInfo);
  }

  public render() {
    if (this.state.hasError) {
      return (
        <div className="p-8 my-8 glass-card border-2 border-danger/30 rounded-3xl bg-danger/5 flex flex-col items-center text-center animate-in fade-in zoom-in duration-500">
          <div className="w-16 h-16 bg-danger/20 rounded-full flex items-center justify-center mb-6">
            <AlertTriangle className="text-danger w-8 h-8" />
          </div>
          <h2 className="text-2xl font-black text-white uppercase tracking-tighter mb-4">
            {this.props.fallbackTitle || "Error en el Componente"}
          </h2>
          <p className="text-sm text-gray-400 max-w-md mb-8">
            Se ha producido un error crítico al renderizar esta sección. Esto puede deberse a datos corruptos o un fallo en el motor del gráfico.
          </p>
          
          <div className="w-full bg-black/40 p-4 rounded-xl border border-white/5 mb-8 text-left overflow-hidden">
            <p className="text-[10px] font-black text-danger uppercase tracking-widest mb-2">Detalles Técnicos:</p>
            <code className="text-[11px] font-mono text-gray-500 break-all">
              {this.state.error?.message || "Error desconocido"}
            </code>
          </div>

          <Button 
            onClick={() => this.setState({ hasError: false, error: null })}
            className="flex items-center gap-2"
          >
            <RefreshCcw size={14} />
            Intentar Re-renderizar
          </Button>
        </div>
      );
    }

    return this.props.children;
  }
}

"use client";

import React from "react";

interface CopyIdButtonProps {
    id: string;
}

export function CopyIdButton({ id }: CopyIdButtonProps) {
    const handleCopy = () => {
        navigator.clipboard.writeText(id);
        alert("ID Copiado al portapapeles");
    };

    return (
        <button 
            onClick={handleCopy}
            className="p-2 rounded-lg bg-secondary/10 hover:bg-secondary/20 border border-secondary/20 transition-all text-secondary"
            title="Copiar ID"
        >
            <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7v8a2 2 0 002 2h6M8 7V5a2 2 0 002-2h4.586a1 1 0 01.707.293l4.414 4.414a1 1 0 01.293.707V15a2 2 0 00-2 2h-2M8 7H6a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2v-2" />
            </svg>
        </button>
    );
}

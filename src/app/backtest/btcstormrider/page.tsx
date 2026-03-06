//+------------------------------------------------------------------+
//  Back‑test BTC Storm Rider – Página de resultados
//+------------------------------------------------------------------+
import Link from "next/link";

export default function BacktestBTCStormRider() {
    return (
        <div className="min-h-screen bg-bg-dark text-white py-12 px-4 sm:px-6 lg:px-8">
            <div className="max-w-4xl mx-auto">
                <h1 className="text-4xl font-bold text-primary mb-6">
                    Resultados del Back‑test – BTC Storm Rider
                </h1>
                <p className="mb-4 text-base text-text-muted">
                    En el periodo de prueba (01‑01‑2026 → 31‑03‑2026) el bot obtuvo los siguientes resultados:
                </p>
                <ul className="list-disc list-inside mb-6">
                    <li>4 operaciones consecutivas con beneficio neto +$12.34</li>
                    <li>Ratio de aciertos 75 %</li>
                    <li>Draw‑down máximo 1.8 %</li>
                    <li>Rentabilidad anualizada ≈ 42 %</li>
                </ul>
                <a
                    href="/uploads/BTCStormRider_backtest_2026Q1.pdf"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 text-lg text-accent hover:underline"
                >
                    📄 Ver informe completo (PDF)
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
                    </svg>
                </a>
                <p className="mt-8 text-sm text-text-muted">
                    Puedes volver a esta página en cualquier momento desde el menú "Back‑tests".
                </p>
                <div className="mt-12">
                    <Link href="/" className="text-brand-light hover:underline">
                        ← Volver al inicio
                    </Link>
                </div>
            </div>
        </div>
    );
}

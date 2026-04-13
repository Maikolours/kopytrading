import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export async function GET() {
    console.log('--- Starting Migration via API ---');
    try {
        // 1. Limpiar datos antiguos
        await prisma.botProduct.deleteMany({});

        const bots = [
            {
                name: 'Elite Sniper',
                description: '⚡ **PRÓXIMO LANZAMIENTO**\n\n₿ El algoritmo más avanzado para Bitcoin. Basado en el motor TITAN de ejecución institucional para una precisión absoluta en el mercado cripto.',
                instrument: 'BTCUSD',
                strategyType: 'Sniper v11.2',
                riskLevel: 'Medium',
                price: 299.00,
                version: '11.2.6',
                timeframes: 'H1 (Recomendado), M15',
                minCapital: 2000,
                isActive: true,
                status: 'UPCOMING',
            },
            {
                name: 'Oro',
                description: '🛠️ **PRÓXIMO LANZAMIENTO**\n\n🛡️ **Calibrando la versión de alta precisión para el Oro.** Estamos optimizando la gestión de riesgo y los filtros de liquidez institucional.',
                instrument: 'XAUUSD',
                strategyType: 'Scalping Institucional',
                riskLevel: 'Medium',
                price: 249.00,
                version: '1.0',
                timeframes: 'M15',
                minCapital: 1000,
                isActive: true,
                status: 'UPCOMING',
            },
            {
                name: 'Euro',
                description: '🎯 **PRÓXIMO LANZAMIENTO**\n\n📈 Optimizando el Scalper Europeo para adaptarlo a las nuevas condiciones de volatilidad bancaria. Precisión quirúrgica en el par EURUSD.',
                instrument: 'EURUSD',
                strategyType: 'Precision Flow',
                riskLevel: 'Low',
                price: 179.00,
                version: '1.0',
                timeframes: 'H1, M15',
                minCapital: 500,
                isActive: true,
                status: 'UPCOMING',
            },
            {
                name: 'Yen',
                description: '🥷 **PRÓXIMO LANZAMIENTO**\n\n🌙 Diseñado específicamente para capturar movimientos explosivos en la sesión asiática con filtros de volatilidad mejorados.',
                instrument: 'USDJPY',
                strategyType: 'Ninja Ghost',
                riskLevel: 'Medium',
                price: 149.00,
                version: '1.0',
                timeframes: 'M30, H1',
                minCapital: 500,
                isActive: true,
                status: 'UPCOMING',
            }
        ];

        for (const bot of bots) {
            await prisma.botProduct.create({ data: bot });
        }

        return NextResponse.json({ success: true, message: "Migration complete" });
    } catch (e: any) {
        console.error(e);
        return NextResponse.json({ success: false, error: e.message }, { status: 500 });
    }
}

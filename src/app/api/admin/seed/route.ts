import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export async function GET() {
    try {
        const newBots = [
            {
                productKey: 'XAU-MG',
                name: 'AMETRALLADORA 🔥 (XAUUSD)',
                description: 'Algoritmo de alta frecuencia especializado en Oro. Agresivo y optimizado para máxima rentabilidad.',
                instrument: 'XAUUSD',
                strategyType: 'HFT / Scalping',
                riskLevel: 'HIGH',
                price: 149.00,
                originalPrice: 299.00,
                version: 'v1.0',
                isActive: true,
                timeframes: 'M5, M15',
                minCapital: 250.0,
                status: 'ACTIVE'
            },
            {
                productKey: 'BTC-SR',
                name: 'STORM RIDER ⚡ (BTCUSD)',
                description: 'Bot conservador para Bitcoin. Captura tendencias institucionales con un control de Drawdown estricto.',
                instrument: 'BTCUSD',
                strategyType: 'Trend Following',
                riskLevel: 'LOW',
                price: 99.00,
                originalPrice: 199.00,
                version: 'v1.0',
                isActive: true,
                timeframes: 'H1, H4',
                minCapital: 500.0,
                status: 'ACTIVE'
            },
            {
                productKey: 'JPY-NG',
                name: 'NINJA GHOST 🥷 (USDJPY)',
                description: 'Especialista en el par Yen. Movimientos furtivos y precisión quirúrgica para capitalizar la volatilidad del BoJ.',
                instrument: 'USDJPY',
                strategyType: 'Precision Scalping',
                riskLevel: 'MEDIUM',
                price: 99.00,
                originalPrice: 149.00,
                version: 'v1.0',
                isActive: true,
                timeframes: 'M15, M30',
                minCapital: 200.0,
                status: 'ACTIVE'
            },
            {
                productKey: 'EUR-EPF',
                name: 'EURO PRECISION FLOW 🎯 (EURUSD)',
                description: 'Bot estable para el par Euro/Dólar. Basado en liquidez institucional y flujos de capital constantes.',
                instrument: 'EURUSD',
                strategyType: 'Institutional Flow',
                riskLevel: 'LOW',
                price: 99.00,
                originalPrice: 149.00,
                version: 'v1.0',
                isActive: true,
                timeframes: 'M30, H1',
                minCapital: 100.0,
                status: 'ACTIVE'
            }
        ];

        let results = [];
        for (const bot of newBots) {
            const existing = await prisma.botProduct.findFirst({
                where: { OR: [{ productKey: bot.productKey }, { name: bot.name }] }
            });

            if (!existing) {
                const created = await prisma.botProduct.create({ data: bot });
                results.push(`✅ Created: ${bot.productKey}`);
            } else {
                results.push(`⏭️ Skipped (Exists): ${bot.productKey}`);
            }
        }

        return NextResponse.json({ success: true, results });
    } catch (error: any) {
        console.error("Seed API Error:", error);
        return NextResponse.json({ success: false, error: error.message }, { status: 500 });
    }
}

import { MetadataRoute } from 'next';
import { prisma } from '@/lib/prisma';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const baseUrl = 'https://kopytrading.com';

  // Obtener bots activos de la DB
  let botUrls: any[] = [];
  try {
    const bots = await prisma.botProduct.findMany({
      where: { isActive: true },
      select: { id: true, updatedAt: true },
    });
    
    botUrls = bots.map((bot) => ({
      url: `${baseUrl}/bots/${bot.id}`,
      lastModified: bot.updatedAt,
      priority: 0.8,
    }));
  } catch (e) {
    console.error("Error generating sitemap bots:", e);
  }

  const staticPages = [
    { url: baseUrl, lastModified: new Date(), changeFrequency: 'daily', priority: 1 },
    { url: `${baseUrl}/bots`, lastModified: new Date(), changeFrequency: 'daily', priority: 0.9 },
    { url: `${baseUrl}/activos`, lastModified: new Date(), changeFrequency: 'weekly', priority: 0.7 },
    { url: `${baseUrl}/articulos`, lastModified: new Date(), changeFrequency: 'daily', priority: 0.8 },
    { url: `${baseUrl}/sobre-nosotros`, lastModified: new Date(), changeFrequency: 'monthly', priority: 0.6 },
    { url: `${baseUrl}/contacto`, lastModified: new Date(), changeFrequency: 'monthly', priority: 0.6 },
    { url: `${baseUrl}/faq`, lastModified: new Date(), changeFrequency: 'monthly', priority: 0.5 },
    { url: `${baseUrl}/legal/privacidad`, lastModified: new Date(), changeFrequency: 'yearly', priority: 0.3 },
    { url: `${baseUrl}/legal/terminos`, lastModified: new Date(), changeFrequency: 'yearly', priority: 0.3 },
    { url: `${baseUrl}/legal/cookies`, lastModified: new Date(), changeFrequency: 'yearly', priority: 0.3 },
    { url: `${baseUrl}/legal/riesgo`, lastModified: new Date(), changeFrequency: 'yearly', priority: 0.4 },
  ];

  const articleSlugs = [
    "oro-supera-maximos", "eurusd-analisis", "usdjpy-boj", "bitcoin-consolidacion",
    "vps-trading", "gestion-riesgo", "indicadores-volatilidad-atr",
    "trading-algoritmico-vs-manual", "por-que-fallan-bots-trading",
    "configurar-metatrader-5-mac", "mejores-vps-trading-2026",
    "psicologia-trading-emociones", "guia-backtesting-mt5", "cuentas-hedging-vs-netting",
    "spread-slippage-costes-ocultos", "trading-noticias-nfp", "correlacion-divisas-riesgo",
    "entender-drawdown-trading", "accion-precio-vs-indicadores", "smart-money-concepts-realidad",
    "elegir-broker-algoritmico"
  ];

  const articleUrls = articleSlugs.map(slug => ({
    url: `${baseUrl}/articulos/${slug}`,
    lastModified: new Date(),
    changeFrequency: 'weekly',
    priority: 0.8,
  }));

  return [
    ...staticPages,
    ...articleUrls,
    ...botUrls,
  ];
}

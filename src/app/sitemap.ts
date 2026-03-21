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

  return [
    {
      url: baseUrl,
      lastModified: new Date(),
      changeFrequency: 'daily',
      priority: 1,
    },
    {
      url: `${baseUrl}/bots`,
      lastModified: new Date(),
      changeFrequency: 'daily',
      priority: 0.9,
    },
    {
      url: `${baseUrl}/activos`,
      lastModified: new Date(),
      changeFrequency: 'weekly',
      priority: 0.7,
    },
    {
       url: `${baseUrl}/faq`,
       lastModified: new Date(),
       changeFrequency: 'monthly',
       priority: 0.6,
    },
    ...botUrls,
  ];
}

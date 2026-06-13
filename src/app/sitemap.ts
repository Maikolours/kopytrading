import { MetadataRoute } from "next";
import { ARTICLES } from "@/lib/constants/articles";
import { prisma } from "@/lib/prisma";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
    const baseUrl = "https://www.kopytrading.com";

    // Rutas estáticas principales y válidas
    const staticRoutes = [
        "",
        "/bots",
        "/articulos",
        "/activos",
        "/como-funciona",
        "/instalar",
        "/sobre-nosotros",
        "/contacto",
        "/faq",
        "/legal/cookies",
        "/legal/privacidad",
        "/legal/riesgo",
        "/legal/terminos",
    ].map((route) => ({
        url: `${baseUrl}${route}`,
        lastModified: new Date(),
        changeFrequency: "weekly" as const,
        priority: route === "" ? 1 : 0.8,
    }));

    // Rutas dinámicas de artículos del blog
    const blogRoutes = ARTICLES.map((article) => ({
        url: `${baseUrl}/articulos/${article.slug}`,
        lastModified: new Date(),
        changeFrequency: "monthly" as const,
        priority: 0.6,
    }));

    // Rutas dinámicas de bots (productos activos)
    let botRoutes: MetadataRoute.Sitemap = [];
    try {
        const activeBots = await prisma.botProduct.findMany({
            where: { isActive: true },
            select: { id: true, updatedAt: true }
        });
        
        botRoutes = activeBots.map((bot) => ({
            url: `${baseUrl}/bots/${bot.id}`,
            lastModified: bot.updatedAt || new Date(),
            changeFrequency: "weekly" as const,
            priority: 0.9,
        }));
    } catch (error) {
        console.error("Error generating bot routes for sitemap:", error);
    }

    return [...staticRoutes, ...blogRoutes, ...botRoutes];
}

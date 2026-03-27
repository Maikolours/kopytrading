import { MetadataRoute } from "next";
import { ARTICLES } from "@/lib/constants/articles";

export default function sitemap(): MetadataRoute.Sitemap {
    const baseUrl = "https://www.kopytrading.com";

    // Rutas estáticas principales
    const staticRoutes = [
        "",
        "/bots",
        "/articulos",
        "/dashboard",
        "/legal",
        "/cookies",
        "/politica-privacidad",
    ].map((route) => ({
        url: `${baseUrl}${route}`,
        lastModified: new Date(),
        changeFrequency: "weekly" as const,
        priority: route === "" ? 1 : 0.8,
    }));

    // Rutas dinámicas de artículos
    const blogRoutes = ARTICLES.map((article) => ({
        url: `${baseUrl}/articulos/${article.slug}`,
        lastModified: new Date(),
        changeFrequency: "monthly" as const,
        priority: 0.6,
    }));

    return [...staticRoutes, ...blogRoutes];
}

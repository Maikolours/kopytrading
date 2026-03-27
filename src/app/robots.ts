import { MetadataRoute } from "next";

export default function robots(): MetadataRoute.Sitemap {
    return {
        rules: {
            userAgent: "*",
            allow: "/",
            disallow: ["/api/", "/_next/", "/admin/"],
        },
        sitemap: "https://www.kopytrading.com/sitemap.xml",
    };
}

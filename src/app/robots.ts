import { MetadataRoute } from "next";

export default function robots(): MetadataRoute.Robots {
    return {
        rules: {
            userAgent: "*",
            allow: "/",
            disallow: ["/api/", "/_next/", "/admin/", "/dashboard/", "/login/", "/checkout/", "/uploads/"],
        },
        sitemap: "https://www.kopytrading.com/sitemap.xml",
    };
}

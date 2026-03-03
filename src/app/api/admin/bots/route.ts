import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { writeFile, mkdir } from "fs/promises";
import path from "path";

// Creamos un helper para manejar las subidas a public/uploads/
async function uploadFile(file: File | null): Promise<string | null> {
    if (!file || file.size === 0) return null;

    const bytes = await file.arrayBuffer();
    const buffer = Buffer.from(bytes);

    // Save to public/uploads
    const uploadDir = path.join(process.cwd(), "public", "uploads");

    try {
        await mkdir(uploadDir, { recursive: true });
    } catch (e) {
        // ignorar error si ya existe
    }

    // Generar nombre unico guardando original
    const filename = `${Date.now()}-${file.name}`;
    const filepath = path.join(uploadDir, filename);

    await writeFile(filepath, buffer);

    // Return the public URL path
    return `/uploads/${filename}`;
}

export async function POST(req: Request) {
    try {
        const session = await getServerSession(authOptions);
        /* Descomentar en produccion real:
        if (!session || (session.user as any).role !== "ADMIN") {
          return NextResponse.json({ error: "No autorizado" }, { status: 403 });
        }
        */

        const formData = await req.formData();

        // Extract info
        const name = formData.get("name") as string;
        const description = formData.get("description") as string;
        const instrument = formData.get("instrument") as string;
        const strategyType = formData.get("strategyType") as string;
        const riskLevel = formData.get("riskLevel") as string;
        const price = parseFloat(formData.get("price") as string);
        const timeframes = formData.get("timeframes") as string;
        const minCapital = parseFloat(formData.get("minCapital") as string);

        // Archivos
        const ex5File = formData.get("ex5File") as unknown as File;
        const pdfFile = formData.get("pdfFile") as unknown as File;

        const ex5FilePath = await uploadFile(ex5File);
        const pdfFilePath = await uploadFile(pdfFile);

        const newBot = await prisma.botProduct.create({
            data: {
                name,
                description,
                instrument,
                strategyType,
                riskLevel,
                price,
                timeframes,
                minCapital: isNaN(minCapital) ? null : minCapital,
                ex5FilePath,
                pdfFilePath,
            }
        });

        return NextResponse.json({ success: true, bot: newBot });
    } catch (error: any) {
        return NextResponse.json({ error: error.message }, { status: 500 });
    }
}

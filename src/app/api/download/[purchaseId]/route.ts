import { NextResponse } from "next/server";
import { getServerSession } from "next-auth/next";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { readFile } from "fs/promises";
import path from "path";

export async function GET(req: Request, { params }: { params: Promise<{ purchaseId: string }> }) {
    const { purchaseId } = await params;

    const session = await getServerSession(authOptions);
    if (!session?.user) {
        return new NextResponse("No autorizado", { status: 401 });
    }

    const purchase = await prisma.purchase.findUnique({
        where: { id: purchaseId },
        include: { botProduct: true }
    });

    if (!purchase) {
        return new NextResponse("Compra no encontrada", { status: 404 });
    }

    // Verificar que el usuario sea dueño de la compra o Admin
    if (purchase.userId !== (session.user as any).id && (session.user as any).role !== "ADMIN") {
        return new NextResponse("No tienes acceso a este archivo", { status: 403 });
    }

    // Obtener query param para saber si descarga ex5 o pdf
    const url = new URL(req.url);
    const type = url.searchParams.get("type"); // 'ex5' o 'pdf'

    const relativePath = type === "pdf" ? purchase.botProduct.pdfFilePath : purchase.botProduct.ex5FilePath;

    if (!relativePath) {
        return new NextResponse("Archivo no disponible", { status: 404 });
    }

    // Actualizar última versión descargada si es el bot (.ex5)
    if (type === "ex5") {
        await prisma.purchase.update({
            where: { id: purchaseId },
            data: { lastDownloadedVersion: purchase.botProduct.version }
        });
    }

    try {
        const filename = relativePath.split("/").pop();
        const filePath = path.join(process.cwd(), "public", "uploads", filename as string);
        const fileBuffer = await readFile(filePath);

        const headers = new Headers();
        headers.set("Content-Disposition", `attachment; filename="${filename}"`);
        headers.set("Content-Type", "application/octet-stream");

        return new NextResponse(fileBuffer, {
            status: 200,
            headers,
        });
    } catch (error) {
        return new NextResponse("Error leyendo archivo. Posiblemente no existe en el disco.", { status: 500 });
    }
}

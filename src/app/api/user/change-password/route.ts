import { NextResponse } from "next/server";
import { getServerSession } from "next-auth/next";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import bcrypt from "bcryptjs";

export async function POST(req: Request) {
    try {
        const session = await getServerSession(authOptions);
        if (!session?.user) {
            return new NextResponse("No autorizado", { status: 401 });
        }

        const { newPassword } = await req.json();

        if (!newPassword || newPassword.length < 6) {
            return new NextResponse("La contraseña debe tener al menos 6 caracteres", { status: 400 });
        }

        const hashedPassword = await bcrypt.hash(newPassword, 10);

        await prisma.user.update({
            where: { id: (session.user as any).id },
            data: { password: hashedPassword }
        });

        return NextResponse.json({ message: "Contraseña actualizada correctamente" });
    } catch (error) {
        console.error("Error al cambiar contraseña:", error);
        return new NextResponse("Error interno del servidor", { status: 500 });
    }
}

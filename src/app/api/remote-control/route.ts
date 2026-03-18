import { NextResponse } from "next/server";
import { getServerSession } from "next-auth/next";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";

export async function POST(req: Request) {
    const session = await getServerSession(authOptions);
    if (!session?.user) return new NextResponse("Unauthorized", { status: 401 });

    try {
        const { purchaseId, command, value } = await req.json();

        // Verificar que la compra pertenezca al usuario
        const purchase = await prisma.purchase.findFirst({
            where: { id: purchaseId, userId: (session.user as any).id }
        });

        if (!purchase) return new NextResponse("Forbidden", { status: 403 });

        // Crear el comando
        const remoteCommand = await prisma.remoteCommand.create({
            data: {
                purchaseId,
                command,
                value
            }
        });

        return NextResponse.json(remoteCommand);
    } catch (error) {
        return new NextResponse("Error", { status: 500 });
    }
}

// GET para el bot de MetaTrader 5
export async function GET(req: Request) {
    const { searchParams } = new URL(req.url);
    const purchaseId = searchParams.get("purchaseId");
    const account = searchParams.get("account");

    if (!purchaseId || !account) return new NextResponse("Missing params", { status: 400 });

    try {
        // Obtener comandos no ejecutados por ESTA cuenta específica
        const commands = await prisma.remoteCommand.findMany({
            where: { 
                purchaseId,
                executions: {
                    none: { account: account }
                }
            },
            orderBy: { createdAt: 'asc' }
        });

        // Registrar ejecución para esta cuenta al leerlos
        if (commands.length > 0) {
            await prisma.$transaction(
                commands.map(cmd => 
                    prisma.commandExecution.create({
                        data: {
                            commandId: cmd.id,
                            account: account
                        }
                    })
                )
            );
        }

        return NextResponse.json(commands);
    } catch (error) {
        console.error("Remote Control GET Error:", error);
        return new NextResponse("Error", { status: 500 });
    }
}

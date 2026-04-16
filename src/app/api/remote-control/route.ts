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

        // Crear el comando histórico
        const remoteCommand = await prisma.remoteCommand.create({
            data: { purchaseId, command, value }
        });

        // ACTUALIZACIÓN EN TIEMPO REAL v1.67
        // Buscamos todas las configuraciones activas para esta compra
        const settings = await prisma.botSettings.findMany({
            where: { purchaseId }
        });

        for (const setting of settings) {
            let updatedJson: any = { ...(setting.settings as any) };

            if (command === "SET_SETTING" && value) {
                try {
                    const newVals = JSON.parse(value);
                    updatedJson = { ...updatedJson, ...newVals };
                } catch (e) {}
            }

            if (command === "CLOSE_ALL") {
                updatedJson.pendingCmd = "CLOSE_ALL";
            } else if (command === "ARM_BOT") {
                updatedJson.armed = value === "TRUE" || value === "TOGGLE" ? !updatedJson.armed : value === "TRUE";
            }

            await prisma.botSettings.update({
                where: { id: setting.id },
                data: { settings: updatedJson }
            });
        }

        return NextResponse.json(remoteCommand);
    } catch (error) {
        return new NextResponse("Error", { status: 500 });
    }
}

export async function GET(req: Request) {
    const { searchParams } = new URL(req.url);
    const purchaseId = searchParams.get("purchaseId");
    const account = searchParams.get("account");

    if (!purchaseId || !account) {
        await prisma.requestLog.create({
            data: { path: "/api/remote-control", method: "GET", body: req.url, error: "Missing params" }
        });
        return new NextResponse("Missing params", { status: 400 });
    }

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
            
            // Log de comandos enviados
            await prisma.requestLog.create({
                data: { path: "/api/remote-control", method: "GET", body: `CID: ${purchaseId}, ACC: ${account}`, error: `Enviados ${commands.length} comandos` }
            });
        }

        return NextResponse.json(commands);
    } catch (err: any) {
        console.error("Remote Control GET Error:", err);
        await prisma.requestLog.create({
            data: { path: "/api/remote-control", method: "GET", body: req.url, error: err.message || "Unknown error" }
        });
        return new NextResponse("Error", { status: 500 });
    }
}

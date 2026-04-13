import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

async function check() {
    console.log("--- Diagnóstico de Productos ---");
    const products = await prisma.botProduct.findMany();
    products.forEach(p => {
        console.log(`ID: ${p.id} | Nombre: ${p.name} | Key: ${p.productKey}`);
    });

    console.log("\n--- Diagnóstico de Licencias (viajaconsakura) ---");
    const user = await prisma.user.findFirst({
        where: { OR: [{ id: "viajaconsakura" }, { email: { contains: "viajaconsakura" } }] }
    });

    if (user) {
        const purchases = await prisma.purchase.findMany({
            where: { userId: user.id },
            include: { botProduct: true }
        });
        purchases.forEach(pur => {
            console.log(`Licencia ID: ${pur.id} | Bot: ${pur.botProduct.name} | Key Actual: ${pur.botProduct.productKey}`);
        });
    } else {
        console.log("Usuario viajaconsakura no encontrado");
    }
}

check()
    .catch(e => console.error(e))
    .finally(() => prisma.$disconnect());

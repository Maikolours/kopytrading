const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    const bots = await prisma.botProduct.findMany();
    console.log("All bots:");
    bots.forEach(b => console.log(`${b.name} - ${b.status} - PDF: ${b.pdfFilePath} - EX5: ${b.ex5FilePath}`));
}
main().catch(console.error).finally(() => prisma.$disconnect());

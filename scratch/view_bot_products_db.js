const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const bots = await prisma.botProduct.findMany();
  console.log("=== BOTS EN BASE DE DATOS ===");
  bots.forEach(b => {
    console.log(`ID: ${b.id}`);
    console.log(`Nombre: ${b.name}`);
    console.log(`Instrumento: ${b.instrument}`);
    console.log(`EX5 Path: ${b.ex5FilePath}`);
    console.log(`PDF Path: ${b.pdfFilePath}`);
    console.log(`Version: ${b.version}`);
    console.log("-----------------------------------");
  });
}

main().finally(() => prisma.$disconnect());

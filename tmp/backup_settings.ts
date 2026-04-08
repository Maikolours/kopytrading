import { PrismaClient } from '@prisma/client';
import * as fs from 'fs';
import * as dotenv from 'dotenv';

dotenv.config();

const prisma = new PrismaClient();

async function main() {
  console.log('📦 Iniciando backup de seguridad de BotSettings...');
  try {
    const settings = await prisma.botSettings.findMany();
    const backupPath = './tmp/backup_settings_v11.json';
    
    if (!fs.existsSync('./tmp')) {
      fs.mkdirSync('./tmp');
    }
    
    fs.writeFileSync(backupPath, JSON.stringify(settings, null, 2));
    console.log(`✅ Backup completado satisfactoriamente en: ${backupPath}`);
    console.log(`📊 Total de registros respaldados: ${settings.length}`);
  } catch (error) {
    console.error('❌ Error durante el backup:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();

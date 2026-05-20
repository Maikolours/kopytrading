const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();
async function main() {
    const positions = await p.livePosition.findMany({
        where: { purchaseId: 'cmn9hfaxg000lvhbcqidlvvfm' }, take: 5
    });
    console.log('BTC positions count:', positions.length);
    
    const purchase = await p.purchase.findUnique({
        where: { id: 'cmn9hfaxg000lvhbcqidlvvfm' },
        select: { lastSync: true, balance: true, equity: true, lastStatus: true }
    });
    console.log('BTC purchase sync data:', JSON.stringify(purchase, null, 2));
    
    // Check Gold purchase too
    const goldPurchase = await p.purchase.findUnique({
        where: { id: 'cmn9hfal4000fvhbcr34kst5x' },
        select: { lastSync: true, balance: true, equity: true, lastStatus: true }
    });
    console.log('Gold purchase sync data:', JSON.stringify(goldPurchase, null, 2));
}
main().catch(console.error).finally(() => p.$disconnect());

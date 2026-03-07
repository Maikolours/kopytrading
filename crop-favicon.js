const sharp = require('sharp');
const fs = require('fs');

async function cropFavicon() {
    const image = sharp('public/logo-kopytrading.png');
    const metadata = await image.metadata();
    console.log(`Original Size: ${metadata.width}x${metadata.height}`);

    // Create a square from the left edge (where the logo mark typically is)
    const size = Math.min(metadata.width, metadata.height);
    const cropped = await image.extract({ left: 0, top: 0, width: size, height: size }).toBuffer();

    await sharp(cropped).resize(512, 512).toFile('public/icon-512.png');
    await sharp(cropped).resize(192, 192).toFile('public/icon-192.png');
    await sharp(cropped).resize(180, 180).toFile('public/apple-touch-icon.png');
    await sharp(cropped).resize(48, 48).toFile('public/favicon.ico');

    console.log('Done creating icons');
}
cropFavicon().catch(console.error);

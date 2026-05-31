const fs = require('fs');
let content = fs.readFileSync('src/lib/constants/articles.ts', 'utf8');
const images = [
  '/images/ai-algorithmic-trading.png',
  '/images/candlestick-patterns.png',
  '/images/crypto-liquidity-pool.png',
  '/images/eurusd-divergence-2026.png',
  '/images/fibonacci-golden-ratio.png',
  '/images/forex-trading.png',
  '/images/gold-trading.png',
  '/images/institutional-order-flow.png',
  '/images/maiko-btc.png',
  '/images/maiko-cent.png',
  '/images/maiko-euro.png',
  '/images/maiko-gold-demo.png',
  '/images/maiko-gold.png',
  '/images/maiko-yen.png',
  '/images/mt5-guide.png',
  '/images/mt5-mac-silicon-2026.png',
  '/images/mt5-server-farm.png',
  '/images/results-march-27.png',
  '/images/smart-money-concepts.png',
  '/images/titan-shield-setup.png',
  '/images/volatility-trading.png',
  '/images/vps-setup.png'
];

let i = 0;
// skip "image: string;" which is the type definition inside ARTICLE_CONTENT signature!
// Wait, is there a type definition? Yes, line 219 `image: string;`.
content = content.replace(/image:\s*"([^"]+)"/g, (match, p1) => {
    let img = images[i % 22];
    i++;
    return 'image: "' + img + '"';
});

fs.writeFileSync('src/lib/constants/articles.ts', content);
console.log('Replaced ' + i + ' images.');

const fs = require('fs');
const path = 'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\BB8163656548A371304D87AABB7A68EB\\MQL5\\Experts\\BOTS MAIKO\\Maiko_Sniper_PRO_CENT_TEST_V12.mq5';

let code = fs.readFileSync(path, 'utf8');

// Update input values and names
code = code.replace(/input double TrailingStopUSD = 2\.0;/g, 'input double TrailingStopCents = 200.0;');
code = code.replace(/input double TrailingStepUSD = 1\.0;/g, 'input double TrailingStepCents = 100.0;');
code = code.replace(/input double BreakEvenStartUSD = 2\.0;/g, 'input double BreakEvenStartCents = 150.0;');
code = code.replace(/input double BreakEvenProfitUSD = 1\.0;/g, 'input double BreakEvenProfitCents = 75.0;');
code = code.replace(/input double StopLossUSDIndividual = -10\.0;/g, 'input double StopLossCentsIndividual = -1000.0;');
code = code.replace(/input double ObjetivoDiarioUSD = 250\.0;/g, 'input double ObjetivoDiarioCents = 25000.0;');
code = code.replace(/input double LotajeInicial = 0\.01;/g, 'input double LotajeInicial = 0.02;');
code = code.replace(/input double MaxLoteIndividual = 0\.02;/g, 'input double MaxLoteIndividual = 0.03;');
code = code.replace(/input double MaxLoteTotal = 0\.50;/g, 'input double MaxLoteTotal = 0.08;');
code = code.replace(/input string TradeComment = "MAIKO_TEST_V12";/g, 'input string TradeComment = "MAIKO_CENT_TEST_V12";');

// Update variable references
code = code.replace(/TrailingStopUSD/g, 'TrailingStopCents');
code = code.replace(/TrailingStepUSD/g, 'TrailingStepCents');
code = code.replace(/BreakEvenStartUSD/g, 'BreakEvenStartCents');
code = code.replace(/BreakEvenProfitUSD/g, 'BreakEvenProfitCents');
code = code.replace(/StopLossUSDIndividual/g, 'StopLossCentsIndividual');
code = code.replace(/ObjetivoDiarioUSD/g, 'ObjetivoDiarioCents');

fs.writeFileSync(path, code);
console.log('Cent V12 created successfully!');

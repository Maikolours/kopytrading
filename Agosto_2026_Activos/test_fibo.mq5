void OnStart() {
   double hi = 4420.0;
   double lo = 4300.0;
   bool bull = true;
   double f100 = bull ? lo : hi;
   double f0 = bull ? hi : lo;
   double f23 = bull ? f0-(f0-f100)*0.236 : f0+(f100-f0)*0.236;
   double f61 = bull ? f0-(f0-f100)*0.618 : f0+(f100-f0)*0.618;
   double f78 = bull ? f0-(f0-f100)*0.786 : f0+(f100-f0)*0.786;
   PrintFormat("BULL: f100=%.2f (BOTTOM), f0=%.2f (TOP)", f100, f0);
   PrintFormat("BULL LEVELS: f23=%.2f, f61=%.2f, f78=%.2f", f23, f61, f78);
   
   bull = false;
   f100 = bull ? lo : hi;
   f0 = bull ? hi : lo;
   f23 = bull ? f0-(f0-f100)*0.236 : f0+(f100-f0)*0.236;
   f61 = bull ? f0-(f0-f100)*0.618 : f0+(f100-f0)*0.618;
   f78 = bull ? f0-(f0-f100)*0.786 : f0+(f100-f0)*0.786;
   PrintFormat("BEAR: f100=%.2f (TOP), f0=%.2f (BOTTOM)", f100, f0);
   PrintFormat("BEAR LEVELS: f23=%.2f, f61=%.2f, f78=%.2f", f23, f61, f78);
}

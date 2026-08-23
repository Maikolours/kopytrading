void OnStart() {
   double bufferM[1];
   int hEmaMacro = iMA("XAUUSD", PERIOD_H1, 200, 0, MODE_EMA, PRICE_CLOSE);
   CopyBuffer(hEmaMacro, 0, 0, 1, bufferM);
   Print("EMA200 H1: ", bufferM[0], " Current Price: ", iClose("XAUUSD", PERIOD_H1, 0));
}

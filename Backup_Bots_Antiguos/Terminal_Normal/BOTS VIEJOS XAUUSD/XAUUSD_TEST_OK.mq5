#property strict
#property version "6.1"

//================ INPUTS =================//
input double LoteInicial      = 0.01;
input double ProfitGlobalUSD  = 2.0;
input double MaxLossGlobalUSD = 15.0;
input int    MagicNumber      = 20260204;

//================ GLOBAL =================//
bool EA_ON = true;
string BTN_NAME = "EA_TOGGLE";

//================ BOTÓN =================//
void CreateButton()
{
   if(ObjectFind(0, BTN_NAME) != -1) return;

   ObjectCreate(0, BTN_NAME, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, BTN_NAME, OBJPROP_CORNER, CORNER_LEFT_LOWER);
   ObjectSetInteger(0, BTN_NAME, OBJPROP_XDISTANCE, 20);
   ObjectSetInteger(0, BTN_NAME, OBJPROP_YDISTANCE, 20);
   ObjectSetInteger(0, BTN_NAME, OBJPROP_XSIZE, 120);
   ObjectSetInteger(0, BTN_NAME, OBJPROP_YSIZE, 30);
   ObjectSetString (0, BTN_NAME, OBJPROP_TEXT, "EA ON");
   ObjectSetInteger(0, BTN_NAME, OBJPROP_BGCOLOR, clrGreen);
   ObjectSetInteger(0, BTN_NAME, OBJPROP_COLOR, clrWhite);
}

//================ FILLING =================//
ENUM_ORDER_TYPE_FILLING GetValidFilling()
{
   int mask = (int)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);

   if(mask & SYMBOL_FILLING_FOK)    return ORDER_FILLING_FOK;
   if(mask & SYMBOL_FILLING_IOC)    return ORDER_FILLING_IOC;
   if(mask & SYMBOL_FILLING_RETURN) return ORDER_FILLING_RETURN;

   return ORDER_FILLING_RETURN;
}

//================ POSICIONES ==============//
int CountPositions()
{
   int total = 0;
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionSelectByIndex(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==MagicNumber &&
            PositionGetString(POSITION_SYMBOL)==_Symbol)
            total++;
      }
   }
   return total;
}

double GlobalProfit()
{
   double profit = 0.0;
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionSelectByIndex(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==MagicNumber &&
            PositionGetString(POSITION_SYMBOL)==_Symbol)
            profit += PositionGetDouble(POSITION_PROFIT);
      }
   }
   return profit;
}

//================ CERRAR TODO =============//
void CloseAll()
{
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(!PositionSelectByIndex(i)) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber) continue;

      MqlTradeRequest r;
      MqlTradeResult  res;
      ZeroMemory(r);
      ZeroMemory(res);

      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      r.action   = TRADE_ACTION_DEAL;
      r.position = PositionGetInteger(POSITION_TICKET);
      r.symbol   = _Symbol;
      r.volume   = PositionGetDouble(POSITION_VOLUME);
      r.magic    = MagicNumber;
      r.type     = (type==POSITION_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY);
      r.price    = (type==POSITION_TYPE_BUY ?
                    SymbolInfoDouble(_Symbol,SYMBOL_BID) :
                    SymbolInfoDouble(_Symbol,SYMBOL_ASK));
      r.type_filling = GetValidFilling();

      OrderSend(r,res);
   }
}

//================ ABRIR BUY ===============//
void OpenBuy()
{
   MqlTradeRequest r;
   MqlTradeResult  res;
   ZeroMemory(r);
   ZeroMemory(res);

   r.action = TRADE_ACTION_DEAL;
   r.symbol = _Symbol;
   r.volume = LoteInicial;
   r.magic  = MagicNumber;
   r.type   = ORDER_TYPE_BUY;
   r.price  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   r.type_filling = GetValidFilling();

   OrderSend(r,res);
}

//================ INIT ====================//
int OnInit()
{
   CreateButton();
   Print("EA iniciado correctamente");
   return INIT_SUCCEEDED;
}

//================ BOTÓN ==================//
void OnChartEvent(const int id,const long &l,const double &d,const string &s)
{
   if(id==CHARTEVENT_OBJECT_CLICK && s==BTN_NAME)
   {
      EA_ON = !EA_ON;
      ObjectSetString(0,BTN_NAME,OBJPROP_TEXT,EA_ON?"EA ON":"EA OFF");
      ObjectSetInteger(0,BTN_NAME,OBJPROP_BGCOLOR,EA_ON?clrGreen:clrRed);
   }
}

//================ TICK ===================//
void OnTick()
{
   if(!EA_ON) return;

   double profit = GlobalProfit();

   if(profit >= ProfitGlobalUSD || profit <= -MaxLossGlobalUSD)
   {
      CloseAll();
      return;
   }

   if(CountPositions()==0)
      OpenBuy();
}


//+------------------------------------------------------------------+
//|                                           kiddies_random.mq5    |
//|                  Random BUY trades, 0.9 lot, TP $100           |
//+------------------------------------------------------------------+
#property strict

input double LotSize = 0.9;        // Fixed lot size
input double TargetProfit = 100.0; // Close all trades when profit reaches $100
input string TradePairs = "EURUSD,GBPUSD,USDJPY"; // Symbols to trade
input int MagicNumber = 987654;

string Pairs[];

//+------------------------------------------------------------------+
int OnInit()
{
   StringSplit(TradePairs,',',Pairs);
   Print("Random BUY EA initialized");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnTick()
{
   // Check current profit
   double totalProfit = 0;
   for(int i=0;i<OrdersTotal();i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         if(OrderMagicNumber()==MagicNumber)
            totalProfit += OrderProfit();
      }
   }

   if(totalProfit>=TargetProfit)
   {
      // Close all trades
      for(int i=OrdersTotal()-1;i>=0;i--)
      {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         {
            if(OrderMagicNumber()==MagicNumber)
            {
               int type = OrderType();
               double price = (type==OP_BUY) ? SymbolInfoDouble(OrderSymbol(),SYMBOL_BID) : SymbolInfoDouble(OrderSymbol(),SYMBOL_ASK);
               OrderClose(OrderTicket(),OrderLots(),price,10,clrRed);
            }
         }
      }
      Print("Target profit reached. All trades closed.");
      return;
   }

   // Random chance to place a BUY trade
   if(MathRand()%2==0) // 50% chance
   {
      for(int i=0;i<ArraySize(Pairs);i++)
      {
         string symbol = Pairs[i];
         if(!SymbolInfoInteger(symbol,SYMBOL_SELECT))
            SymbolSelect(symbol,true);

         double price = SymbolInfoDouble(symbol,SYMBOL_ASK);
         MqlTradeRequest request;
         MqlTradeResult result;
         ZeroMemory(request);
         ZeroMemory(result);

         request.action = TRADE_ACTION_DEAL;
         request.symbol = symbol;
         request.volume = LotSize;
         request.type = ORDER_TYPE_BUY;
         request.price = price;
         request.magic = MagicNumber;
         request.deviation = 10;
         request.type_filling = ORDER_FILLING_IOC;
         request.comment = "Random BUY";

         if(!OrderSend(request,result))
            Print("Trade failed: ",result.retcode);
         else
            Print("Random BUY placed: ",symbol," Lot:",LotSize);
      }
   }
}


//+------------------------------------------------------------------+
//|                                                      kiddies.mq5 |
//|                        Auto EA for MT5 with risk 50%            |
//+------------------------------------------------------------------+
#property strict

input double RiskPercent = 50.0;      // Risk per trade in %
input int StopLossPips = 80;          // Stop Loss in pips
input int TakeProfitPips = 300;       // Take Profit in pips
input string TradePairs = "EURUSD,GBPUSD,XAUUSD,XAGUSD,USDJPY,USDCHF,AUDUSD,USDCAD,NZDUSD,EURGBP,EURJPY,GBPJPY,AUDJPY,EURAUD,EURCHF,GBPAUD,CADJPY,WTIUSD";
input int MagicNumber = 123456;

string Pairs[];
//+------------------------------------------------------------------+
int OnInit()
{
   StringSplit(TradePairs,',',Pairs);
   Print("kiddies EA initialized. Trading Pairs: ", TradePairs);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnTick()
{
   for(int i=0;i<ArraySize(Pairs);i++)
   {
      string symbol = Pairs[i];
      if(!SymbolInfoInteger(symbol,SYMBOL_SELECT))
         SymbolSelect(symbol,true);

      int signal = CheckStrategy(symbol); // 1=BUY, -1=SELL, 0=NO SIGNAL
      if(signal!=0)
      {
         double lot = CalculateLot(symbol,RiskPercent,StopLossPips);
         if(signal==1) PlaceTrade(symbol,ORDER_TYPE_BUY,lot);
         if(signal==-1) PlaceTrade(symbol,ORDER_TYPE_SELL,lot);
      }
   }
}

//+------------------------------------------------------------------+
int CheckStrategy(string symbol)
{
   // Placeholder for EMA, CCI, RSI, Price Action checks
   // Must return 1=BUY, -1=SELL, 0=NO SIGNAL
   // For testing purposes, we force a BUY every time
   return(1);
}

//+------------------------------------------------------------------+
double CalculateLot(string symbol,double risk_percent,int sl_pips)
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double lot = (balance*risk_percent/100.0)/(sl_pips*10.0);
   double minLot = SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
   double lotStep = SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);
   if(lot<minLot) lot=minLot;
   lot = MathFloor(lot/lotStep)*lotStep;
   return(lot);
}

//+------------------------------------------------------------------+
void PlaceTrade(string symbol,ENUM_ORDER_TYPE type,double lot)
{
   double price=0,sl=0,tp=0;
   double point = SymbolInfoDouble(symbol,SYMBOL_POINT);
   if(type==ORDER_TYPE_BUY)
   {
      price = SymbolInfoDouble(symbol,SYMBOL_ASK);
      sl = price - StopLossPips*point;
      tp = price + TakeProfitPips*point;
   }
   else if(type==ORDER_TYPE_SELL)
   {
      price = SymbolInfoDouble(symbol,SYMBOL_BID);
      sl = price + StopLossPips*point;
      tp = price - TakeProfitPips*point;
   }

   MqlTradeRequest request;
   MqlTradeResult  result;
   ZeroMemory(request);
   ZeroMemory(result);

   request.action = TRADE_ACTION_DEAL;
   request.symbol = symbol;
   request.volume = lot;
   request.type = type;
   request.price = price;
   request.sl = sl;
   request.tp = tp;
   request.magic = MagicNumber;
   request.deviation = 10;
   request.type_filling = ORDER_FILLING_FOK;
   request.comment = "kiddies EA";

   if(!OrderSend(request,result))
      Print("Trade failed for ",symbol,". Retcode: ",result.retcode);
   else
      Print("Trade placed for ",symbol," Type:",type," Lot:",lot);
}

//+------------------------------------------------------------------+

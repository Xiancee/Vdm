
//+------------------------------------------------------------------+
//|                                                   XAUUSDm EA      |
//|           Aggressive Direction-Following EA (Gold)               |
//+------------------------------------------------------------------+
#property strict
#property script_show_inputs

input double RiskPercent = 50.0;            // Risk % of account balance
input ENUM_TIMEFRAMES TimeFrame = PERIOD_M1;
input double LotStep = 0.01;

// Indicator periods
input int EMA7 = 7;
input int EMA13 = 13;
input int EMA50 = 50;
input int EMA200 = 200;
input int CCI_Period = 34;
input int RSI_Period = 14;

// Global variables
double ema7, ema13, ema50, ema200, cci, rsi, macd_main, macd_signal;
bool tradeOpen = false;
ulong ticket;

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("🔥 XAUUSDm Aggressive EA initialized");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Calculate lot size                                               |
//+------------------------------------------------------------------+
double GetLotSize()
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskMoney = balance * (RiskPercent / 100.0);
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double stopLossPips = 100; // estimate for sizing
    double lot = riskMoney / (tickValue * stopLossPips);
    lot = MathMax(lot, LotStep);
    return(NormalizeDouble(lot, 2));
}

//+------------------------------------------------------------------+
//| Indicator updates                                                |
//+------------------------------------------------------------------+
void UpdateIndicators()
{
    ema7   = iMA(_Symbol, TimeFrame, EMA7, 0, MODE_EMA, PRICE_CLOSE, 0);
    ema13  = iMA(_Symbol, TimeFrame, EMA13, 0, MODE_EMA, PRICE_CLOSE, 0);
    ema50  = iMA(_Symbol, TimeFrame, EMA50, 0, MODE_EMA, PRICE_CLOSE, 0);
    ema200 = iMA(_Symbol, TimeFrame, EMA200, 0, MODE_EMA, PRICE_CLOSE, 0);

    cci = iCCI(_Symbol, TimeFrame, CCI_Period, PRICE_TYPICAL, 0);
    rsi = iRSI(_Symbol, TimeFrame, RSI_Period, PRICE_CLOSE, 0);

    macd_main   = iMACD(_Symbol, TimeFrame, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0);
    macd_signal = iMACD(_Symbol, TimeFrame, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0);
}

//+------------------------------------------------------------------+
//| Check trading conditions                                         |
//+------------------------------------------------------------------+
bool CheckBuySignal()
{
    return (ema7 > ema13 && ema13 > ema50 && ema50 > ema200 &&
            rsi > 50 && cci > 0 && macd_main > macd_signal);
}

bool CheckSellSignal()
{
    return (ema7 < ema13 && ema13 < ema50 && ema50 < ema200 &&
            rsi < 50 && cci < 0 && macd_main < macd_signal);
}

//+------------------------------------------------------------------+
//| Execute trade                                                    |
//+------------------------------------------------------------------+
void ExecuteTrade()
{
    UpdateIndicators();

    MqlTradeRequest request;
    MqlTradeResult  result;
    ZeroMemory(request);
    ZeroMemory(result);

    double lot = GetLotSize();

    if(!tradeOpen && CheckBuySignal())
    {
        request.action   = TRADE_ACTION_DEAL;
        request.symbol   = _Symbol;
        request.volume   = lot;
        request.type     = ORDER_TYPE_BUY;
        request.price    = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
        request.deviation= 10;
        request.magic    = 123456;
        request.comment  = "Buy Order";

        if(OrderSend(request,result))
            tradeOpen = true;
    }
    else if(!tradeOpen && CheckSellSignal())
    {
        request.action   = TRADE_ACTION_DEAL;
        request.symbol   = _Symbol;
        request.volume   = lot;
        request.type     = ORDER_TYPE_SELL;
        request.price    = SymbolInfoDouble(_Symbol,SYMBOL_BID);
        request.deviation= 10;
        request.magic    = 123456;
        request.comment  = "Sell Order";

        if(OrderSend(request,result))
            tradeOpen = true;
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    ExecuteTrade();
}

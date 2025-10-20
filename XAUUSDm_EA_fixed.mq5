
//+------------------------------------------------------------------+
//|                                                   XAUUSDm EA      |
//|           Aggressive Direction-Following EA (Gold)               |
//+------------------------------------------------------------------+
#property strict
#include <Trade\Trade.mqh>
CTrade trade;

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

// Indicator handles
int handleEMA7, handleEMA13, handleEMA50, handleEMA200;
int handleCCI, handleRSI, handleMACD;

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("🔥 XAUUSDm Aggressive EA initialized");

    // Create indicator handles
    handleEMA7   = iMA(_Symbol, TimeFrame, EMA7, 0, MODE_EMA, PRICE_CLOSE);
    handleEMA13  = iMA(_Symbol, TimeFrame, EMA13, 0, MODE_EMA, PRICE_CLOSE);
    handleEMA50  = iMA(_Symbol, TimeFrame, EMA50, 0, MODE_EMA, PRICE_CLOSE);
    handleEMA200 = iMA(_Symbol, TimeFrame, EMA200, 0, MODE_EMA, PRICE_CLOSE);
    handleCCI    = iCCI(_Symbol, TimeFrame, CCI_Period, PRICE_TYPICAL);
    handleRSI    = iRSI(_Symbol, TimeFrame, RSI_Period, PRICE_CLOSE);
    handleMACD   = iMACD(_Symbol, TimeFrame, 12, 26, 9, PRICE_CLOSE);

    if(handleEMA7==INVALID_HANDLE || handleEMA13==INVALID_HANDLE || handleEMA50==INVALID_HANDLE ||
       handleEMA200==INVALID_HANDLE || handleCCI==INVALID_HANDLE || handleRSI==INVALID_HANDLE || handleMACD==INVALID_HANDLE)
    {
        Print("Error creating indicator handles");
        return(INIT_FAILED);
    }

    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Update indicator values                                           |
//+------------------------------------------------------------------+
void UpdateIndicators()
{
    double emaBuf[1], buf[1];
    // EMA
    CopyBuffer(handleEMA7, 0, 0, 1, emaBuf); ema7 = emaBuf[0];
    CopyBuffer(handleEMA13,0,0,1, emaBuf); ema13= emaBuf[0];
    CopyBuffer(handleEMA50,0,0,1, emaBuf); ema50= emaBuf[0];
    CopyBuffer(handleEMA200,0,0,1, emaBuf); ema200= emaBuf[0];
    // CCI
    CopyBuffer(handleCCI,0,0,1, buf); cci = buf[0];
    // RSI
    CopyBuffer(handleRSI,0,0,1, buf); rsi = buf[0];
    // MACD
    double macdMain[1], macdSignal[1];
    CopyBuffer(handleMACD,0,0,1, macdMain); macd_main=macdMain[0];
    CopyBuffer(handleMACD,1,0,1, macdSignal); macd_signal=macdSignal[0];
}

//+------------------------------------------------------------------+
//| Signals check                                                    |
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
    double lot = MathMax(LotStep, AccountInfoDouble(ACCOUNT_BALANCE) * RiskPercent/100.0 / 100);
    
    if(!tradeOpen && CheckBuySignal())
    {
        if(trade.Buy(lot,_Symbol))
            tradeOpen = true;
    }
    else if(!tradeOpen && CheckSellSignal())
    {
        if(trade.Sell(lot,_Symbol))
            tradeOpen = true;
    }
}

//+------------------------------------------------------------------+
//| Expert tick                                                      |
//+------------------------------------------------------------------+
void OnTick()
{
    ExecuteTrade();
}

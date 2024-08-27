#property link          "https://www.earnforex.com/metatrader-indicators/macd-alert/"
#property version       "1.02"

#property copyright     "EarnForex.com - 2019-2023"
#property description   "The MACD indicator with alerts."
#property description   " "
#property description   "WARNING: Use this software at your own risk."
#property description   "The creator of these plugins cannot be held responsible for any damage or loss."
#property description   " "
#property description   "Find More on www.EarnForex.com"
#property icon          "\\Files\\EF-Icon-64x64px.ico"

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots 2
#property indicator_color1 clrGray
#property indicator_color2 clrRed
#property indicator_level1 0
#property indicator_levelcolor clrGray
#property indicator_levelstyle STYLE_DOT

#include <MQLTA ErrorHandling.mqh>
#include <MQLTA Utils.mqh>

enum ENUM_TRADE_SIGNAL
{
    SIGNAL_BUY_SWITCH = 1,   // BUY (SWITCH)
    SIGNAL_SELL_SWITCH = -1, // SELL (SWITCH)
    SIGNAL_BUY_CROSS = 2,    // BUY (CROSS)
    SIGNAL_SELL_CROSS = -2,  // SELL (CROSS)
    SIGNAL_NEUTRAL = 0       // NEUTRAL
};

enum ENUM_CANDLE_TO_CHECK
{
    CURRENT_CANDLE = 0, // CURRENT CANDLE
    CLOSED_CANDLE = 1   // PREVIOUS CANDLE
};

enum ENUM_ALERT_SIGNAL
{
    MACD_MAIN_SWITCH_SIDE = 0,  // MACD MAIN SWITCH SIDE
    MACD_MAIN_SIGNAL_CROSS = 1, // MACD MAIN AND SIGNAL CROSS
    MACD_MAIN_ALL = 2           // ALL SIGNALS
};

enum ENUM_MACD_TYPE
{
    MACD_TYPE_HISTOGRAM, // Histogram
    MACD_TYPE_LINE       // Line
};

input string Comment1 = "========================";           // MQLTA MACD With Alert
input string IndicatorName = "MQLTA-MACDWA";                  // Indicator Short Name
input string Comment2 = "========================";           // Indicator Parameters
input int MACDFastEMA = 12;                                   // MACD Fast EMA Period
input int MACDSlowEMA = 26;                                   // MACD Slow EMA Period
input int MACDSMA = 9;                                        // MACD SMA Period
input ENUM_APPLIED_PRICE MACDAppliedPrice = PRICE_CLOSE;      // MACD Applied Price
input ENUM_ALERT_SIGNAL AlertSignal = MACD_MAIN_SIGNAL_CROSS; // Alert Signal When
input ENUM_CANDLE_TO_CHECK CandleToCheck = CURRENT_CANDLE;    // Candle To Use For Analysis
input ENUM_MACD_TYPE MACDType = MACD_TYPE_HISTOGRAM;          // MACD Type
input int BarsToScan = 500;                                   // Number Of Candles To Analyse
input string Comment_3 = "===================="; // Notification Options
input bool EnableNotify = false;                 // Enable Notifications Feature
input bool SendAlert = true;                     // Send Alert Notification
input bool SendApp = false;                      // Send Notification to Mobile
input bool SendEmail = false;                    // Send Notification via Email
input string Comment_4 = "===================="; // Drawing Options
input bool EnableDrawArrows = true;              // Draw Signal Arrows
input int ArrowBuySwitch = 241;                  // Buy Arrow Code (Switch)
input int ArrowSellSwitch = 242;                 // Sell Arrow Code (Switch)
input int ArrowSizeSwitch = 3;                   // Arrow Size (1-5) (Switch)
input color ArrowColorBuySwitch = clrGreen;      // Arrow Color Sell (Switch)
input color ArrowColorSellSwitch = clrRed;       // Arrow Color Sell (Switch)
input int ArrowBuyCross = 233;                   // Buy Arrow Code (Cross)
input int ArrowSellCross = 234;                  // Sell Arrow Code (Cross)
input int ArrowSizeCross = 3;                    // Arrow Size (1-5) (Cross)
input color ArrowColorBuyCross = clrGreen;       // Arrow Color Sell (Switch)
input color ArrowColorSellCross = clrRed;        // Arrow Color Sell (Switch)

double BufferMain[];
double BufferSignal[];

int BufferMACDHandle;

double Open[], Close[], High[], Low[];
datetime Time[];

datetime LastNotificationTime;
ENUM_TRADE_SIGNAL LastNotificationDirection;
int Shift = 0;

int OnInit(void)
{
    IndicatorSetString(INDICATOR_SHORTNAME, IndicatorName);

    OnInitInitialization();
    if (!OnInitPreChecksPass())
    {
        return INIT_FAILED;
    }

    InitialiseHandles();
    InitialiseBuffers();

    return INIT_SUCCEEDED;
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    bool IsNewCandle = CheckIfNewCandle();

    int counted_bars = 0;
    if (prev_calculated > 0) counted_bars = prev_calculated - 1;

    if (counted_bars < 0) return -1;
    if (counted_bars > 0) counted_bars--;
    int limit = rates_total - counted_bars;
    if (limit > BarsToScan)
    {
        limit = BarsToScan;
        if (rates_total < BarsToScan + MACDSlowEMA) limit = rates_total - MACDSlowEMA;
    }
    if (limit > rates_total - MACDSlowEMA) limit = rates_total - MACDSlowEMA;

    if ((CopyBuffer(BufferMACDHandle, 0, 0, limit, BufferMain)   <= 0) ||
        (CopyBuffer(BufferMACDHandle, 1, 0, limit, BufferSignal) <= 0))
    {
        Print("Failed to create the indicator! Error: ", GetLastErrorText(GetLastError()), " - ", GetLastError());
        return 0;
    }

    if (IsStopped()) return 0;

    for (int i = limit - 1; (i >= 0) && (!IsStopped()); i--)
    {
        Open[i] = iOpen(Symbol(), PERIOD_CURRENT, i);
        Low[i] = iLow(Symbol(), PERIOD_CURRENT, i);
        High[i] = iHigh(Symbol(), PERIOD_CURRENT, i);
        Close[i] = iClose(Symbol(), PERIOD_CURRENT, i);
        Time[i] = iTime(Symbol(), PERIOD_CURRENT, i);
    }

    if ((IsNewCandle) || (prev_calculated == 0))
    {
        if (EnableDrawArrows) DrawArrows(limit);
        CleanUpOldArrows();
    }

    if (EnableDrawArrows) DrawArrow(0);

    if (EnableNotify) NotifyHit();

    return rates_total;
}

void OnDeinit(const int reason)
{
    CleanChart();
}

void OnInitInitialization()
{
    LastNotificationTime = TimeCurrent();
    Shift = CandleToCheck;
}

bool OnInitPreChecksPass()
{
    if ((MACDFastEMA <= 0) || (MACDFastEMA > MACDSlowEMA) || (MACDSMA <= 0))
    {
        Print("Wrong input parameters.");
        return false;
    }
    if ((Bars(Symbol(), PERIOD_CURRENT) < MACDSlowEMA) || (Bars(Symbol(), PERIOD_CURRENT) < MACDSMA))
    {
        Print("Not enough historical candles.");
        return false;
    }
    return true;
}

void CleanChart()
{
    ObjectsDeleteAll(ChartID(), IndicatorName);
}

void InitialiseHandles()
{
    BufferMACDHandle = iMACD(Symbol(), PERIOD_CURRENT, MACDFastEMA, MACDSlowEMA, MACDSMA, MACDAppliedPrice);
    ArrayResize(Open, BarsToScan);
    ArrayResize(High, BarsToScan);
    ArrayResize(Low, BarsToScan);
    ArrayResize(Close, BarsToScan);
    ArrayResize(Time, BarsToScan);
}

void InitialiseBuffers()
{
    IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
    ArraySetAsSeries(BufferMain, true);
    ArraySetAsSeries(BufferSignal, true);
    SetIndexBuffer(0, BufferMain, INDICATOR_DATA);
    SetIndexBuffer(1, BufferSignal, INDICATOR_DATA);
    if (MACDType == MACD_TYPE_HISTOGRAM) PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_HISTOGRAM);
    else PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
    PlotIndexSetString(0, PLOT_LABEL, "MACD MAIN");
    PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, MACDSlowEMA);
    PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_LINE);
    PlotIndexSetString(1, PLOT_LABEL, "MACD SIGNAL");
    PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, MACDSMA);
}

datetime NewCandleTime = TimeCurrent();
bool CheckIfNewCandle()
{
    if (NewCandleTime == iTime(Symbol(), 0, 0)) return false;
    else
    {
        NewCandleTime = iTime(Symbol(), 0, 0);
        return true;
    }
}

// Check whether there is a trade signal and return it.
ENUM_TRADE_SIGNAL IsSignal(int i)
{
    int j = i + Shift;
    if ((AlertSignal == MACD_MAIN_SWITCH_SIDE) || (AlertSignal == MACD_MAIN_ALL))
    {
        if ((BufferMain[j + 1] < 0) && (BufferMain[j] > 0)) return SIGNAL_BUY_SWITCH;
        if ((BufferMain[j + 1] > 0) && (BufferMain[j] < 0)) return SIGNAL_SELL_SWITCH;
    }
    if ((AlertSignal == MACD_MAIN_SIGNAL_CROSS) || (AlertSignal == MACD_MAIN_ALL))
    {
        if ((BufferMain[j + 1] < BufferSignal[j + 1]) && (BufferMain[j] > BufferSignal[j])) return SIGNAL_BUY_CROSS;
        if ((BufferMain[j + 1] > BufferSignal[j + 1]) && (BufferMain[j] < BufferSignal[j])) return SIGNAL_SELL_CROSS;
    }

    return SIGNAL_NEUTRAL;
}

void NotifyHit()
{
    if (!EnableNotify) return;
    if ((!SendAlert) && (!SendApp) && (!SendEmail)) return;
    if ((CandleToCheck == CLOSED_CANDLE) && (Time[0] <= LastNotificationTime)) return;
    ENUM_TRADE_SIGNAL Signal = IsSignal(0);
    if (Signal == SIGNAL_NEUTRAL)
    {
        LastNotificationDirection = Signal;
        return;
    }
    if (Signal == LastNotificationDirection) return;
    string EmailSubject = IndicatorName + " " + Symbol() + " Notification";
    string EmailBody = AccountCompany() + " - " + AccountName() + " - " + IntegerToString(AccountNumber()) + "\r\n" + IndicatorName + " Notification for " + Symbol() + " @ " + EnumToString((ENUM_TIMEFRAMES)Period()) + "\r\n";
    string AlertText = "";
    string AppText = AccountCompany() + " - " + AccountName() + " - " + IntegerToString(AccountNumber()) + " - " + IndicatorName + " - " + Symbol() + " @ " + EnumToString((ENUM_TIMEFRAMES)Period()) + " - ";
    string Text = "";

    Text += EnumToString(Signal);

    EmailBody += Text;
    AlertText += Text;
    AppText += Text;
    if (SendAlert) Alert(AlertText);
    if (SendEmail)
    {
        if (!SendMail(EmailSubject, EmailBody)) Print("Error sending email " + IntegerToString(GetLastError()));
    }
    if (SendApp)
    {
        if (!SendNotification(AppText)) Print("Error sending notification " + IntegerToString(GetLastError()));
    }
    LastNotificationTime = Time[0];
    LastNotificationDirection = Signal;
}

void DrawArrows(int limit)
{
    for (int i = limit - 1; i >= 1; i--)
    {
        DrawArrow(i);
    }
}

void RemoveArrows()
{
    ObjectsDeleteAll(ChartID(), IndicatorName + "-ARWS-");
}

void DrawArrow(int i)
{
    RemoveArrowCurr();
    ENUM_TRADE_SIGNAL Signal = IsSignal(i);
    if (Signal == SIGNAL_NEUTRAL) return;
    datetime ArrowDate = iTime(Symbol(), 0, i);
    string ArrowName = IndicatorName + "-ARWS-" + IntegerToString(ArrowDate);
    double ArrowPrice = 0;
    int ArrowType = 0;
    color ArrowColor = 0;
    int ArrowAnchor = 0;
    string ArrowDesc = "";
    int ArrowSize = 0;
    
    if (Signal == SIGNAL_BUY_SWITCH)
    {
        ArrowPrice = Low[i];
        ArrowType = ArrowBuySwitch;
        ArrowColor = ArrowColorBuySwitch;
        ArrowSize = ArrowSizeSwitch;
        ArrowAnchor = ANCHOR_TOP;
        ArrowDesc = "BUY (SWITCH)";
    }
    else if (Signal == SIGNAL_SELL_SWITCH)
    {
        ArrowPrice = High[i];
        ArrowType = ArrowSellSwitch;
        ArrowColor = ArrowColorSellSwitch;
        ArrowSize = ArrowSizeSwitch;
        ArrowAnchor = ANCHOR_BOTTOM;
        ArrowDesc = "SELL (SWITCH)";
    }
    else if (Signal == SIGNAL_BUY_CROSS)
    {
        ArrowPrice = Low[i];
        ArrowType = ArrowBuyCross;
        ArrowColor = ArrowColorBuyCross;
        ArrowSize = ArrowSizeCross;
        ArrowAnchor = ANCHOR_TOP;
        ArrowDesc = "BUY (CROSS)";
    }
    else if (Signal == SIGNAL_SELL_CROSS)
    {
        ArrowPrice = High[i];
        ArrowType = ArrowSellCross;
        ArrowColor = ArrowColorSellCross;
        ArrowSize = ArrowSizeCross;
        ArrowAnchor = ANCHOR_BOTTOM;
        ArrowDesc = "SELL (CROSS)";
    }
    ObjectCreate(0, ArrowName, OBJ_ARROW, 0, ArrowDate, ArrowPrice);
    ObjectSetInteger(0, ArrowName, OBJPROP_COLOR, ArrowColor);
    ObjectSetInteger(0, ArrowName, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, ArrowName, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, ArrowName, OBJPROP_ANCHOR, ArrowAnchor);
    ObjectSetInteger(0, ArrowName, OBJPROP_ARROWCODE, ArrowType);
    ObjectSetInteger(0, ArrowName, OBJPROP_WIDTH, ArrowSize);
    ObjectSetInteger(0, ArrowName, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, ArrowName, OBJPROP_BGCOLOR, ArrowColor);
    ObjectSetString(0, ArrowName, OBJPROP_TEXT, ArrowDesc);
}

void RemoveArrowCurr()
{
    datetime ArrowDate = iTime(Symbol(), 0, 0);
    string ArrowName = IndicatorName + "-ARWS-" + IntegerToString(ArrowDate);
    ObjectDelete(0, ArrowName);
}

// Delete all arrows that are older than BarsToScan bars.
void CleanUpOldArrows()
{
    int total = ObjectsTotal(ChartID(), 0, OBJ_ARROW);
    for (int i = total - 1; i >= 0; i--)
    {
        string ArrowName = ObjectName(ChartID(), i, 0, OBJ_ARROW);
        datetime time = (datetime)ObjectGetInteger(ChartID(), ArrowName, OBJPROP_TIME);
        int bar = iBarShift(Symbol(), Period(), time);
        if (bar >= BarsToScan) ObjectDelete(ChartID(), ArrowName);
    }
}
//+------------------------------------------------------------------+
//+--------------------------------------------------------------------------+
//|                                              Bollinger Squeeze Basic.mq5 |
//|                                          Copyright © 2022, EarnForex.com |
//| https://www.earnforex.com/metatrader-indicators/Bollinger-Squeeze-Basic/ |
//+--------------------------------------------------------------------------+
#property copyright "Copyright © 2022, EarnForex.com"
#property link      "https://www.earnforex.com/metatrader-indicators/Bollinger-Squeeze-Basic/"
#property version   "1.00"

#property description "Bollinger Squeeze Basic shows the change of momentum histogram and BB / Keltner channel dots."
#property description "Red dots are shown when Bollinger bands are outside of the Keltner channel."
#property description "Blue dots are shown when Bollinger bands are inside the Keltner channel."

#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots 2
#property indicator_type1  DRAW_COLOR_HISTOGRAM
#property indicator_color1 clrLimeGreen, clrIndianRed, clrLightGreen, clrLightPink
#property indicator_width1 2
#property indicator_label1 "Momentum Histo"
#property indicator_type2  DRAW_COLOR_ARROW
#property indicator_width2 1
#property indicator_color2 clrBlue, clrRed
#property indicator_label2 "BB/Keltner"

enum enum_candle_to_check
{
    Current,
    Previous
};

input int                  MaxBars              = 300;
input int                  BB_Period            = 20; // BB Period
input double               BB_Deviation         = 1.6185; // BB Deviation
input ENUM_MA_METHOD       BB_MA_Method         = MODE_SMA;
input ENUM_APPLIED_PRICE   BB_Price             = PRICE_CLOSE;
input int                  Keltner_Period       = 20; // Keltner Period
input double               Keltner_Factor       = 1.5; // Keltner Factor
input int                  Momentum_Period      = 12; // Momentum Period
input ENUM_APPLIED_PRICE   Momentum_Price       = PRICE_CLOSE;
input int                  SqueezeWingDingsCode = 167;
input bool                 EnableNativeAlerts   = false;
input bool                 EnableEmailAlerts    = false;
input bool                 EnablePushAlerts     = false;
input enum_candle_to_check TriggerCandle = Previous;

// Indicator buffers:
double Histogram[];
double Histogram_Color[];
double Arrows[];
double Arrows_Color[];

// Internal intidcator buffers:
double Momentum_Buffer[];
double ATR_Buffer[];
double StdDev_Buffer[];

// Global variables:
int Momentum_Handle, ATR_Handle, StdDev_Handle;
datetime LastAlertTime = D'01.01.1970';
int LastAlertDirection = 0;

//+------------------------------------------------------------------+
//| Получение таймфрейма в виде строки                               |
//+------------------------------------------------------------------+
string GetStringTimeframe(ENUM_TIMEFRAMES timeframe)
  {return(StringSubstr(EnumToString(timeframe),7,-1));}

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
{
    SetIndexBuffer(0, Histogram, INDICATOR_DATA);
    SetIndexBuffer(1, Histogram_Color, INDICATOR_COLOR_INDEX);
    SetIndexBuffer(2, Arrows, INDICATOR_DATA);
    SetIndexBuffer(3, Arrows_Color, INDICATOR_COLOR_INDEX);

    PlotIndexSetInteger(1, PLOT_ARROW, SqueezeWingDingsCode); // Arrow code.
    
    ArraySetAsSeries(Histogram, true);
    ArraySetAsSeries(Histogram_Color, true);
    ArraySetAsSeries(Arrows, true);
    ArraySetAsSeries(Arrows_Color, true);
    
    Momentum_Handle = iMomentum(Symbol(), Period(), Momentum_Period, Momentum_Price);
    ATR_Handle      = iATR(Symbol(), Period(), Keltner_Period);
    StdDev_Handle   = iStdDev(Symbol(), Period(), BB_Period, BB_MA_Method, 0, BB_Price);

    ArraySetAsSeries(Momentum_Buffer, true);
    ArraySetAsSeries(ATR_Buffer, true);
    ArraySetAsSeries(StdDev_Buffer, true);

//---- инициализации переменной для короткого имени индикатора  
//---- initializing a variable for the short name of the indicator    
   string shortName="["+GetStringTimeframe(_Period)+"] [" + Symbol() + "] Bollinger Squeeze Basic";
   
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
//--- creating a name to display in a separate subwindow and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortName);

//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    ArraySetAsSeries(Time, true);

    int limit = MaxBars;
    if (limit > rates_total) limit = rates_total;

    double d = 0, prev_d = 0;
    
    if (CopyBuffer(Momentum_Handle, 0, 0, limit, Momentum_Buffer) != limit) return 0; // Data not ready yet.
    if (CopyBuffer(ATR_Handle, 0, 0, limit, ATR_Buffer) != limit) return 0; // Data not ready yet.
    if (CopyBuffer(StdDev_Handle, 0, 0, limit, StdDev_Buffer) != limit) return 0; // Data not ready yet.
    
    for (int shift = limit - 1; shift >= 0; shift--)
    {
        d = Momentum_Buffer[shift] - 100;

        if (d > 0)
        {
            if (d >= prev_d)
            {
                Histogram_Color[shift] = 0;
            }
            else
            {
                Histogram_Color[shift] = 2;
            }
            Histogram[shift] = d;
        }
        else if (d < 0)
        {

            if (d <= prev_d)
            {
                Histogram_Color[shift] = 1;
            }
            else
            {
                Histogram_Color[shift] = 3;
            }
            Histogram[shift] = d;
        }
        else
        {
            Histogram[shift] = 0;
            Histogram_Color[shift] = 0;
        }
        prev_d = d;

        double diff = ATR_Buffer[shift] * Keltner_Factor;
        double std = StdDev_Buffer[shift];
        double bbs = BB_Deviation * std / diff;

        Arrows[shift] = 0;
        if (bbs < 1)
        {
            Arrows_Color[shift] = 0;
        }
        else
        {
            Arrows_Color[shift] = 1;
        }
    }

    if (((TriggerCandle > 0) && (Time[0] > LastAlertTime)) || (TriggerCandle == 0))
    {
        string Text;
        // Outside Alert
        if ((Arrows_Color[TriggerCandle] == 1) && (LastAlertDirection != 1))
        {
            if (LastAlertDirection != 0) // Skip actual alerts if it is the first run after attachment.
            {
                Text = "BB Squeeze: " + Symbol() + " - " + StringSubstr(EnumToString((ENUM_TIMEFRAMES)Period()), 7) + " - BB Outside Keltner.";
                if (EnableNativeAlerts) Alert(Text);
                if (EnableEmailAlerts) SendMail("BB Squeeze Alert", Text);
                if (EnablePushAlerts) SendNotification(Text);
            }
            LastAlertTime = Time[0];
            LastAlertDirection = 1;
        }
        // Inside Alert
        if ((Arrows_Color[TriggerCandle] == 0) && (LastAlertDirection != -1))
        {
            if (LastAlertDirection != 0) // Skip actual alerts if it is the first run after attachment.
            {
                Text = "BB Squeeze: " + Symbol() + " - " + StringSubstr(EnumToString((ENUM_TIMEFRAMES)Period()), 7) + " - BB Inside Keltner.";
                if (EnableNativeAlerts) Alert(Text);
                if (EnableEmailAlerts) SendMail("BB Squeeze Alert", Text);
                if (EnablePushAlerts) SendNotification(Text);
            }
            LastAlertTime = Time[0];
            LastAlertDirection = -1;
        }
    }

    return rates_total;
}
//+------------------------------------------------------------------+
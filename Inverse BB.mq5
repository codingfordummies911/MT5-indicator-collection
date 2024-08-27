//+------------------------------------------------------------------+
//|                                                         PEMA.mq5 |
//+------------------------------------------------------------------+
#property copyright   "2022 IonOne"
#property link      "forex-station.com"
#property version   "1.00"
#property description "Inverse BB"

//--- indicator settings
#property indicator_chart_window

#property indicator_buffers 3
#property indicator_plots   3

#property indicator_type1   DRAW_LINE
#property indicator_color1  Red
#property indicator_width1  2
#property indicator_label1  "Main"

#property indicator_type2   DRAW_LINE
#property indicator_color2  Yellow
#property indicator_width2  2
#property indicator_label2  "Top"

#property indicator_type3   DRAW_LINE
#property indicator_color3  Orange
#property indicator_width3  2
#property indicator_label3  "Bot"


input int bars = 10000;

input int BBPeriod = 200;
input ENUM_MA_METHOD BBMAMode = MODE_SMA;
input ENUM_APPLIED_PRICE BBPrice = PRICE_CLOSE;

input int StdDevPeriod = 200;
input ENUM_MA_METHOD StdDevMAMode = MODE_SMA;
input ENUM_APPLIED_PRICE StdDevPrice = PRICE_CLOSE;

input double StdDevMul = 1.0;

input int InversePeriod = 200;

double BBMain[];
double BBTop[];
double BBBot[];
  
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

int HandleMA;
int HandleStdDev;


void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,BBMain,INDICATOR_DATA);
   SetIndexBuffer(1,BBTop,INDICATOR_DATA);
   SetIndexBuffer(2,BBBot,INDICATOR_DATA);
   
   PlotIndexSetInteger(0,PLOT_LINE_WIDTH,2);
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,clrRed);
   PlotIndexSetInteger(0,PLOT_LINE_STYLE,STYLE_SOLID);
   
   PlotIndexSetInteger(1,PLOT_LINE_WIDTH,2);
   PlotIndexSetInteger(1,PLOT_LINE_COLOR,clrYellow);
   PlotIndexSetInteger(1,PLOT_LINE_STYLE,STYLE_SOLID);
   
   PlotIndexSetInteger(2,PLOT_LINE_WIDTH,2);
   PlotIndexSetInteger(2,PLOT_LINE_COLOR,clrOrange);
   PlotIndexSetInteger(2,PLOT_LINE_STYLE,STYLE_SOLID);
   
   IndicatorSetString(INDICATOR_SHORTNAME,"Inverse BB");
   
   HandleMA = iMA(NULL,0,BBPeriod,0,BBMAMode,BBPrice);
   HandleStdDev = iStdDev(NULL,0,StdDevPeriod,0,StdDevMAMode,StdDevPrice);
//--- initialization done
  }
double GetIndi(int i, int bufnum, int handle)
{
   double Buffer[1];
   Buffer[0] = 0;
   int retries = 5;
   while (retries >= 0 && CopyBuffer(handle,bufnum,i,1,Buffer) <= 0) 
   {
      retries--;
   }
   
   return Buffer[0];
} 
//+------------------------------------------------------------------+
//| Triple Exponential Moving Average                                |
//+------------------------------------------------------------------+
int limit;
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

   limit = prev_calculated <= 0 ? 0 : prev_calculated-1;
   limit = MathMax(limit, rates_total-1-bars); 
   limit = MathMax(limit, BBPeriod+1);
   limit = MathMax(limit, StdDevPeriod+1);
   limit = MathMax(limit, InversePeriod+1);
 
   for(int i=limit;i<rates_total && !IsStopped();i++)      
   {
      static datetime tim;
      if (tim != iTime(NULL,0,rates_total-1-i))
      {
         int shift = rates_total-1-i+1;
         double ma0 = GetIndi(shift,0,HandleMA); 
         double stdDev0 = GetIndi(shift,0,HandleStdDev); 
                
         double ma = 0;
         for (int j = 0; j < InversePeriod; j++)
         {
            double stdDev = GetIndi(shift+j,0,HandleStdDev);           
            ma += stdDev;
         }
         ma /= double(InversePeriod);
         
         BBMain[i-1] = ma0;
         BBTop[i-1] = BBMain[i-1] + StdDevMul * (ma - (stdDev0 - ma));
         BBBot[i-1] = BBMain[i-1] - StdDevMul * (ma + (ma - stdDev0)); 
         BBMain[i] = EMPTY_VALUE;
         BBTop[i] = EMPTY_VALUE;
         BBBot[i] = EMPTY_VALUE;         
      }      
   }      
   return(rates_total);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+ 
//|                                                    BBSqueeze.mq5 | 
//|                                     Copyright © 2005, Nick Bilak |
//|                                              beluck[AT]gmail.com |
//+------------------------------------------------------------------+
//| Place the SmoothAlgorithms.mqh file                              |
//| to the terminal_data_folder\MQL5\Include                         |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, Nick Bilak"
#property link      "http://metatrader.50webs.com/" 
//---- indicator version
#property version   "1.00"
//---- drawing the indicator in a separate window
#property indicator_separate_window 
//---- number of indicator buffers 4
#property indicator_buffers 4 
//---- 4 plots are used
#property indicator_plots   4
//+-----------------------------------+ 
//|  Declaration of constants         |
//+-----------------------------------+
#define RESET  0   // the constant for getting the command for the indicator recalculation back to the terminal
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as a histogram
#property indicator_type1 DRAW_HISTOGRAM
//---- teal color is used
#property indicator_color1 Teal
//---- indicator line is a solid one
#property indicator_style1 STYLE_SOLID
//---- indicator line width is equal to 2
#property indicator_width1 2
//---- displaying the indicator label
#property indicator_label1 "Uptrend"

//---- drawing the indicator as a histogram
#property indicator_type2 DRAW_HISTOGRAM
//---- magenta color is used
#property indicator_color2 Magenta
//---- indicator line is a solid one
#property indicator_style2 STYLE_SOLID
//---- indicator line width is equal to 2
#property indicator_width2 2
//---- displaying the indicator label
#property indicator_label2  "Downtrend"
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as labels
#property indicator_type3 DRAW_ARROW
//---- blue color is used
#property indicator_color3 Blue
//---- indicator line width is equal to 2
#property indicator_width3 2
//---- displaying the indicator label
#property indicator_label3 "Strong trend"
//+-----------------------------------+
//|  Indicator drawing parameters     |
//+-----------------------------------+
//---- drawing the indicator as labels
#property indicator_type4 DRAW_ARROW
//---- MediumPurple color is used
#property indicator_color4 MediumPurple
//---- indicator line width is equal to 2
#property indicator_width4 2
//---- displaying the indicator label
#property indicator_label4  "Weak trend"
//+-----------------------------------+
//|  Smoothings classes description   |
//+-----------------------------------+
#include <SmoothAlgorithms.mqh> 
//+-----------------------------------+
//---- declaration of the CXMA class variables from the SmoothAlgorithms.mqh file
CXMA XMA1;
//+-----------------------------------+
//|  Declaration of enumerations      |
//+-----------------------------------+
enum Applied_price_      // Type of constant
  {
   PRICE_CLOSE_ = 1,     // Close
   PRICE_OPEN_,          // Open
   PRICE_HIGH_,          // High
   PRICE_LOW_,           // Low
   PRICE_MEDIAN_,        // Median Price (HL/2)
   PRICE_TYPICAL_,       // Typical Price (HLC/3)
   PRICE_WEIGHTED_,      // Weighted Close (HLCC/4)
   PRICE_SIMPLE,         // Simple Price (OC/2)
   PRICE_QUARTER_,       // Quarted Price (HLOC/4) 
   PRICE_TRENDFOLLOW0_,  // TrendFollow_1 Price 
   PRICE_TRENDFOLLOW1_   // TrendFollow_2 Price 
  };
/*enum Smooth_Method - enumeration is declared in the SmoothAlgorithms.mqh file
  {
   MODE_SMA_,  // SMA
   MODE_EMA_,  // EMA
   MODE_SMMA_, // SMMA
   MODE_LWMA_, // LWMA
   MODE_JJMA,  // JJMA
   MODE_JurX,  // JurX
   MODE_ParMA, // ParMA
   MODE_T3,    // T3
   MODE_VIDYA, // VIDYA
   MODE_AMA,   // AMA
  }; */
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input Smooth_Method BB_Method=MODE_EMA_;        // Histogram smoothing method
input int BB_Period = 20;                       // Bollinger Bands period
input int BB_Phase= 100;                        // Bollinger Bands smoothing parameter
input double BB_Deviation=2.0;                  // Number of deviations
input Applied_price_ AppliedPrice=PRICE_CLOSE_; // Applied price
input double ATR_Period=20;                     // ATR period
input double ATR_Factor=1.5;                    // ATR ratio
//+-----------------------------------+
//---- declaration of the integer variables for the start of data calculation
int min_rates_total,min_rates_xma;
//---- declaration of global variables
int Count[];
double Xma[];
//---- declaration of integer variables for the indicators handles
int ATR_Handle,STD_Handle;
//---- declaration of dynamic arrays that
//---- will be used as indicator buffers
double UpHistBuffer[],DnHistBuffer[],UpArrBuffer[],DnArrBuffer[];
//+------------------------------------------------------------------+    
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//---- initialization of variables of the start of data calculation
   min_rates_xma=XMA1.GetStartBars(BB_Method,BB_Period,BB_Phase);
   min_rates_total=int(MathMax(min_rates_xma,ATR_Period));

//---- getting handle of the iStdDev indicator
   STD_Handle=iStdDev(NULL,0,BB_Period,0,MODE_SMA,PRICE_CLOSE);
   if(STD_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get handle of the iStdDev indicator");
      return(1);
     }

//---- getting handle of the ATR indicator
   ATR_Handle=iATR(NULL,0,15);
   if(ATR_Handle==INVALID_HANDLE)
     {
      Print(" Failed to get handle of the iATR indicator");
      return(1);
     }

//---- memory distribution for variables' arrays
   if(ArrayResize(Count,BB_Period)<BB_Period) Print("Failed to distribute the memory for Count[] array");
   if(ArrayResize(Xma,BB_Period)<BB_Period) Print("Failed to distribute the memory for Xma[] array");

   ArrayInitialize(Count,0);
   ArrayInitialize(Xma,0);

//---- set UpHistBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(0,UpHistBuffer,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing the elements in the buffer as timeseries
   ArraySetAsSeries(UpHistBuffer,true);

//---- set DnHistBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(1,DnHistBuffer,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing the elements in the buffer as timeseries
   ArraySetAsSeries(DnHistBuffer,true);

//---- set UpArrBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(2,UpArrBuffer,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indicator symbol
   PlotIndexSetInteger(2,PLOT_ARROW,159);
//---- indexing the elements in the buffer as timeseries
   ArraySetAsSeries(UpArrBuffer,true);

//---- set DnArrBuffer[] dynamic array as an indicator buffer
   SetIndexBuffer(3,DnArrBuffer,INDICATOR_DATA);
//---- performing the shift of the beginning of the indicator drawing
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indicator symbol
   PlotIndexSetInteger(3,PLOT_ARROW,159);
//---- indexing the elements in the buffer as timeseries
   ArraySetAsSeries(DnArrBuffer,true);

//--- creation of the name to be displayed in a separate sub-window and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,"BBSqueeze");
//--- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- initialization end
   return(0);
  }
//+------------------------------------------------------------------+  
//| Custom iteration function                                        | 
//+------------------------------------------------------------------+  
int OnCalculate(const int rates_total,    // number of bars in history at the current tick
                const int prev_calculated,// number of bars calculated at previous call
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- checking the number of bars to be enough for the calculation
   if(BarsCalculated(ATR_Handle)<rates_total
      || BarsCalculated(STD_Handle)<rates_total
      || rates_total<min_rates_total) return(RESET);

//---- declarations of local variables 
   int to_copy,limit,bar,maxbar,maxbar1;
   double STD[],ATR[],lregress,bbs,price_;

   maxbar=rates_total-1;
   maxbar1=maxbar-min_rates_xma-2*BB_Period;

//---- calculation of the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
      limit=rates_total-1;                 // starting index for calculation of all bars
   else limit=rates_total-prev_calculated; // starting index for calculation of new bars

//---- calculation of the necessary amount of data to be copied
   to_copy=limit+1;
//---- copy the newly appeared data into the STD[] and ATR[] arrays
   if(CopyBuffer(STD_Handle,0,0,to_copy,STD)<=0) return(RESET);
   if(CopyBuffer(ATR_Handle,0,0,to_copy,ATR)<=0) return(RESET);

//---- indexing elements in arrays as time series  
   ArraySetAsSeries(STD,true);
   ArraySetAsSeries(ATR,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(close,true);

//---- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      price_=PriceSeries(AppliedPrice,bar,open,low,high,close);
      Xma[Count[0]]=XMA1.XMASeries(maxbar,prev_calculated,rates_total,BB_Method,BB_Phase,BB_Period,price_,bar,true);
      if(bar>maxbar1)
        {
         Recount_ArrayZeroPos(Count,BB_Period);
         continue;
        }

      lregress=LinearRegressionValue(BB_Period,bar,open,low,high,close);

      if(lregress<0)
        {
         UpHistBuffer[bar]=EMPTY_VALUE;
         DnHistBuffer[bar]=lregress;
        }
      else
        {
         UpHistBuffer[bar]=lregress;
         DnHistBuffer[bar]=EMPTY_VALUE;
        }

      bbs=BB_Deviation*STD[bar]/(ATR[bar]*ATR_Factor);

      if(bbs<1)
        {
         DnArrBuffer[bar]=0;
         UpArrBuffer[bar]=EMPTY_VALUE;
        }
      else
        {
         UpArrBuffer[bar]=0;
         DnArrBuffer[bar]=EMPTY_VALUE;
        }

      if(bar) Recount_ArrayZeroPos(Count,BB_Period);
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+    
//| Linear regression calculation                                    | 
//+------------------------------------------------------------------+ 
double LinearRegressionValue(int Len,
                             int index,
                             const double &Open[],
                             const double &Low[],
                             const double &High[],
                             const double &Close[])
  {
//----
   double SumBars,Sum1,Sum2,SumY,Slope,SumSqrBars;
   double dxma,Num1,Num2,HH,LL,Intercept,LinearRegValue;

   SumY=0;
   Sum1=0;
//----
   SumBars=Len *(Len-1)*0.5;
   SumSqrBars=(Len-1)*Len *(2*Len-1)/6;
//----
   for(int x=0; x<Len;x++)
     {
      HH=Low[index+x];
      LL=High[index+x];

      for(int y=x; y<x+Len; y++)
        {
         HH=MathMax(HH,High[index+y]);
         LL=MathMin(LL,Low[index+y]);
        }

      dxma=Close[index+x]-((HH+LL)/2+Xma[Count[x]])/2;
      Sum1+=x*dxma;
      SumY+=dxma;
     }

   Sum2=SumBars*SumY;
   Num1=Len*Sum1-Sum2;
   Num2=SumBars*SumBars-Len*SumSqrBars;
//----
   if(Num2!=0.0) Slope=Num1/Num2;
   else Slope=0;

   Intercept=(SumY-Slope*SumBars)/Len;
   LinearRegValue=Intercept+Slope*(Len-1);
//----     
   return(LinearRegValue);
  }
//+------------------------------------------------------------------+
//|  Recalculation of position of the newest element in the array    |
//+------------------------------------------------------------------+   
void Recount_ArrayZeroPos(int &CoArr[],// Return the current value of the price series by the link
                          uint Size)
  {
//----
   int numb,Max1,Max2;
   static int count=1;

   Max1=int(Size-1);
   Max2=int(Size);

   count--;
   if(count<0) count=Max1;

   for(int iii=0; iii<Max2; iii++)
     {
      numb=iii+count;
      if(numb>Max1) numb-=Max2;
      CoArr[iii]=numb;
     }
//----
  }
//+------------------------------------------------------------------+

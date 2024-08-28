//+------------------------------------------------------------------+
//|                                              MultiMACDSignal.mq5 | 
//|                             Copyright © 2012,   Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2012, Nikolay Kositsin"
#property link "farria@mail.redcom.ru"
#property description ""
//---- indicator version number
#property version   "1.00"
//---- drawing indicator in a separate window
#property indicator_separate_window
//+-----------------------------------+
//|  declaration of constants              |
//+-----------------------------------+
#define RESET 0 // The constant for returning the indicator recalculation command to the terminal
#define INDTOTAL 6// The constant for the number of displayed indicators
//+-----------------------------------+
//---- number of indicator buffers
#property indicator_buffers 24 // INDTOTAL*4
//---- total plots used
#property indicator_plots   18 // INDTOTAL*3

//+-----------------------------------+
//|  Indicator 1 drawing parameters |
//+-----------------------------------+
//---- drawing indicator 1 as a line
#property indicator_type1   DRAW_COLOR_LINE
//---- the following colors are used as the indicator line color
#property indicator_color1 Gray,Magenta,Lime
//---- the indicator line is dashed
#property indicator_style1  STYLE_SOLID
//---- the indicator line width is 3
#property indicator_width1  3
//---- displaying the indicator label
#property indicator_label1  "Signal line 1"
//+-----------------------------------+
//|  Indicator 1 drawing parameters |
//+-----------------------------------+
//---- drawing the indicator 1 as a label
#property indicator_type2   DRAW_ARROW
//---- the color used as a label color
#property indicator_color2 Teal
//---- the indicator line width is 5
#property indicator_width2  5
//---- displaying the indicator label
#property indicator_label2  "Up MACD 1"
//+-----------------------------------+
//|  Indicator 1 drawing parameters |
//+-----------------------------------+
//---- drawing the indicator 1 as a label
#property indicator_type3   DRAW_ARROW
//---- the color used as a label color
#property indicator_color3 Red
//---- the indicator line width is 5
#property indicator_width3  5
//---- displaying the indicator label
#property indicator_label3  "Down MACD 1"

//+-----------------------------------+
//|  Indicator 2 drawing parameters |
//+-----------------------------------+
//---- drawing the indicator 2 as a line
#property indicator_type4   DRAW_COLOR_LINE
//---- the following colors are used as the indicator line color
#property indicator_color4 Gray,Magenta,Lime
//---- the indicator line is dashed
#property indicator_style4  STYLE_SOLID
//---- the indicator line width is 3
#property indicator_width4  3
//---- displaying the indicator label
#property indicator_label4  "Signal line 2"
//+-----------------------------------+
//|  Indicator 2 drawing parameters |
//+-----------------------------------+
//---- drawing the indicator 2 as a label
#property indicator_type5   DRAW_ARROW
//---- the color used as a label color
#property indicator_color5 Teal
//---- the indicator line width is 5
#property indicator_width5  5
//---- displaying the indicator label
#property indicator_label5  "Up MACD 2"
//+-----------------------------------+
//|  Indicator 2 drawing parameters |
//+-----------------------------------+
//---- drawing the indicator 2 as a label
#property indicator_type6   DRAW_ARROW
//---- the color used as a label color
#property indicator_color6 Red
//---- the indicator line width is 5
#property indicator_width6  5
//---- displaying the indicator label
#property indicator_label6  "Down MACD 2"

//+-----------------------------------+
//|  Indicator 3 drawing parameters |
//+-----------------------------------+
//---- drawing the indicator 3 as a line
#property indicator_type7   DRAW_COLOR_LINE
//---- the following colors are used as the indicator line color
#property indicator_color7 Gray,Magenta,Lime
//---- the indicator line is dashed
#property indicator_style7  STYLE_SOLID
//---- the indicator line width is 3
#property indicator_width7  3
//---- displaying the indicator label
#property indicator_label7  "Signal line 3"
//+-----------------------------------+
//|  Indicator 3 drawing parameters |
//+-----------------------------------+
//---- drawing the indicator 3 as a label
#property indicator_type8   DRAW_ARROW
//---- the color used as a label color
#property indicator_color8 Teal
//---- the indicator line width is 5
#property indicator_width8  5
//---- displaying the indicator label
#property indicator_label8  "Up MACD 3"
//+-----------------------------------+
//|  Indicator 3 drawing parameters |
//+-----------------------------------+
//---- drawing the indicator 3 as a label
#property indicator_type9   DRAW_ARROW
//---- the color used as a label color
#property indicator_color9 Red
//---- the indicator line width is 5
#property indicator_width9  5
//---- displaying the indicator label
#property indicator_label9  "Down MACD 3"

//+-----------------------------------+
//|  Indicator 4 drawing parameters |
//+-----------------------------------+
//---- drawing the indicator 4 as a line
#property indicator_type10   DRAW_COLOR_LINE
//---- the following colors are used as the indicator line color
#property indicator_color10 Gray,Magenta,Lime
//---- the indicator line is dashed
#property indicator_style10 STYLE_SOLID
//---- the indicator line width is 3
#property indicator_width10  3
//---- displaying the indicator label
#property indicator_label10  "Signal line 4"
//+-----------------------------------+
//|  Indicator 4 drawing parameters |
//+-----------------------------------+
//---- drawing the indicator 4 as a label
#property indicator_type11   DRAW_ARROW
//---- the color used as a label color
#property indicator_color11 Teal
//---- the indicator line width is 5
#property indicator_width11  5
//---- displaying the indicator label
#property indicator_label11  "Up MACD 4"
//+-----------------------------------+
//|  Indicator 4 drawing parameters |
//+-----------------------------------+
//---- drawing the indicator 4 as a label
#property indicator_type12   DRAW_ARROW
//---- the color used as a label color
#property indicator_color12 Red
//---- the indicator line width is 5
#property indicator_width12  5
//---- displaying the indicator label
#property indicator_label12  "Down MACD 4"

//+-----------------------------------+
//| Indicator 5 drawing parameters |
//+-----------------------------------+
//---- drawing the indicator 5 as a line
#property indicator_type13   DRAW_COLOR_LINE
//---- the following colors are used as the indicator line color
#property indicator_color13 Gray,Magenta,Lime
//---- the indicator line is dashed
#property indicator_style13  STYLE_SOLID
//---- the indicator line width is 3
#property indicator_width13  3
//---- displaying the indicator label
#property indicator_label13  "Signal line 5"
//+-----------------------------------+
//| Indicator 5 drawing parameters |
//+-----------------------------------+
//---- drawing the indicator 5 as a label
#property indicator_type14   DRAW_ARROW
//---- the color used as a label color
#property indicator_color14 Teal
//---- the indicator line width is 5
#property indicator_width14  5
//---- displaying the indicator label
#property indicator_label14  "Up MACD 5"
//+-----------------------------------+
//| Indicator 5 drawing parameters |
//+-----------------------------------+
//---- drawing the indicator 5 as a label
#property indicator_type15   DRAW_ARROW
//---- the color used as a label color
#property indicator_color15 Red
//---- the indicator line width is 5
#property indicator_width15  5
//---- displaying the indicator label
#property indicator_label15  "Down MACD 5"

//+-----------------------------------+
//|  Indicator 6 drawing parameters |
//+-----------------------------------+
//---- drawing the indicator 6 as a line
#property indicator_type16   DRAW_COLOR_LINE
//---- the following colors are used as the indicator line color
#property indicator_color16 Gray,Magenta,Lime
//---- the indicator line is dashed
#property indicator_style16  STYLE_SOLID
//---- the indicator line width is 3
#property indicator_width16  3
//---- displaying the indicator label
#property indicator_label16  "Signal line 6"
//+-----------------------------------+
//|  Indicator 6 drawing parameters |
//+-----------------------------------+
//---- drawing the indicator 6 as a label
#property indicator_type17   DRAW_ARROW
//---- the color used as a label color
#property indicator_color17 Teal
//---- the indicator line width is 5
#property indicator_width17  5
//---- displaying the indicator label
#property indicator_label17  "Up MACD 6"
//+-----------------------------------+
//| Indicator 5 drawing parameters |
//+-----------------------------------+
//---- drawing the indicator 6 as a label
#property indicator_type18   DRAW_ARROW
//---- the color used as a label color
#property indicator_color18 Red
//---- the indicator line width is 5
#property indicator_width18  5
//---- displaying the indicator label
#property indicator_label18  "Down MACD 6"

//+-----------------------------------+
//|  INDICATOR INPUT PARAMETERS     |
//+-----------------------------------+
input ENUM_TIMEFRAMES TimeFrame0=PERIOD_W1;  //0 Chart period
input ENUM_TIMEFRAMES TimeFrame1=PERIOD_D1;  //1 Chart period
input ENUM_TIMEFRAMES TimeFrame2=PERIOD_H12; //2 Chart period
input ENUM_TIMEFRAMES TimeFrame3=PERIOD_H6;  //3 Chart period
input ENUM_TIMEFRAMES TimeFrame4=PERIOD_H3;  //4 Chart period
input ENUM_TIMEFRAMES TimeFrame5=PERIOD_H1;  //5 Chart period
//+-----------------------------------+
//|  INDICATOR INPUT PARAMETERS     |
//+-----------------------------------+
input uint Fast_MA = 12; //fast moving average period
input uint Slow_MA = 26; //depth of the SMMA smoothing
input ENUM_MA_METHOD MA_Method_=MODE_EMA; //indicator smoothing method
input uint Signal_MA=9; //signal line period 
input ENUM_APPLIED_PRICE Applied_Price=PRICE_CLOSE;//price constant
//+-----------------------------------+

//---- Declaration of a variable for storing the indicator initialization result
bool Init;
//---- Declaration of integer variables of data starting point
int min_rates_total;
//+------------------------------------------------------------------+
//|  Getting string time frame                                |
//+------------------------------------------------------------------+
string GetStringTimeframe(ENUM_TIMEFRAMES timeframe)
  {
//----
   return(StringSubstr(EnumToString(timeframe),7,-1));
//----
  }
//+------------------------------------------------------------------+
//|  Indicator buffer class                                      |
//+------------------------------------------------------------------+  
class CIndBuffers
  {
   //----
public:
   double            m_UpBuffer[];
   double            m_DnBuffer[];
   double            m_LineBuffer[];
   double            m_ColorLineBuffer[];
   int               m_Handle;
   ENUM_TIMEFRAMES   m_TimeFrame;
   //---- 
  };

//---- declaration of dynamic arrays that will further be 
// used as indicator buffers
CIndBuffers Ind[INDTOTAL];
//+------------------------------------------------------------------+   
//| MACD indicator initialization function                           | 
//+------------------------------------------------------------------+ 
bool IndInit(uint Number,uint FastMA,uint SlowMA,uint SignalMA,ENUM_APPLIED_PRICE AppliedPrice)
  {
//---- checking the chart periods for correctness
   if(Ind[Number].m_TimeFrame<Period() && Ind[Number].m_TimeFrame!=PERIOD_CURRENT)
     {
      Print("IndInit(",Number,"): The MACD indicator chart period cannot be less than the current chart period");
      Init=false;
      return(false);
     }

//---- Getting indicator handles  
   Ind[Number].m_Handle=iMACD(NULL,Ind[Number].m_TimeFrame,FastMA,SlowMA,SignalMA,AppliedPrice);

   if(Ind[Number].m_Handle==INVALID_HANDLE)
     {
      Print("IndInit(",Number,"): Failed to get the MACD indicator handle");
      Init=false;
      return(false);
     }
     
   uint Numb=Number*4+0;
//---- setting dynamic array as indicator buffer
   SetIndexBuffer(Numb,Ind[Number].m_LineBuffer,INDICATOR_DATA);
//---- shifting the starting point of the indicator drawing
   PlotIndexSetInteger(Numb,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that will be invisible on the chart
   PlotIndexSetDouble(Numb,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(Ind[Number].m_LineBuffer,true);
   
   Numb++;
//---- set dynamic array as a color index buffer   
   SetIndexBuffer(Numb,Ind[Number].m_ColorLineBuffer,INDICATOR_COLOR_INDEX);
//---- shifting the starting point of the indicator drawing
   PlotIndexSetInteger(Numb,PLOT_DRAW_BEGIN,min_rates_total);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(Ind[Number].m_ColorLineBuffer,true);

   Numb++;
//---- setting dynamic array as indicator buffer
   if(!SetIndexBuffer(Numb,Ind[Number].m_UpBuffer,INDICATOR_DATA))
//---- shifting the starting point of the indicator drawing
   PlotIndexSetInteger(Numb,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that will be invisible on the chart
   PlotIndexSetDouble(Numb,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(Ind[Number].m_UpBuffer,true);

   Numb++;
//---- setting dynamic array as indicator buffer
   SetIndexBuffer(Numb,Ind[Number].m_DnBuffer,INDICATOR_DATA);
//---- shifting the starting point of the indicator drawing
   PlotIndexSetInteger(Numb,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that will be invisible on the chart
   PlotIndexSetDouble(Numb,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- indexing elements in the buffer as time series
   ArraySetAsSeries(Ind[Number].m_DnBuffer,true);
   
//---- end of initialization of one indicator
   return(true);
  }
//+------------------------------------------------------------------+   
//| MACD indicator initialization function                           | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- Initialization of variables of data starting point
   min_rates_total=3;
   Init=true;

//---- Initialization of variables 
   Ind[0].m_TimeFrame=TimeFrame0;
   Ind[1].m_TimeFrame=TimeFrame1;
   Ind[2].m_TimeFrame=TimeFrame2;
   Ind[3].m_TimeFrame=TimeFrame3;
   Ind[4].m_TimeFrame=TimeFrame4;
   Ind[5].m_TimeFrame=TimeFrame5;

//---- Initialization of indicator buffers
   for(int count=0; count<INDTOTAL; count++)
      if(!IndInit(count,Fast_MA,Slow_MA,Signal_MA,Applied_Price))
        {
         Init=false;
         return;
        }

string shortname;
   StringConcatenate(shortname,"MultiMACDSignal( ",Fast_MA,", ",Slow_MA,", ",Signal_MA," )");
//--- creating a name to be displayed in a separate subwindow and in a tooltip
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
   
//--- determining the accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//---- end of initialization
  }
//+------------------------------------------------------------------+ 
//| MACD iteration function                                          | 
//+------------------------------------------------------------------+ 
bool IndOnCalculate(uint Number,uint Limit,const datetime &Time[],uint Rates_Total,uint Prev_Calculated)
  {
//---- Declaration of integer variables
   uint limit_;
//---- Declaration of variables with a floating point  
   double Main[1],Signal[1];
   datetime Time_[1],Time0;
   static uint LastCountBar[INDTOTAL];

//---- calculations of the necessary amount of data to be copied and
//the starting number limit for the bar recalculation loop
   if(Prev_Calculated>Rates_Total || Prev_Calculated<=0)// checking for the first start of the indicator calculation
     {
      LastCountBar[Number]=Rates_Total;
      limit_=Limit;
     }
   else limit_=int(LastCountBar[Number])+Limit; // starting index for the calculation of new bars 

//---- Main indicator calculation loop
   for(int bar=int(limit_); bar>=0 && !IsStopped(); bar--)
     {
      //---- zero out the contents of the indicator buffers for the calculation
      Ind[Number].m_UpBuffer[bar]=EMPTY_VALUE;
      Ind[Number].m_DnBuffer[bar]=EMPTY_VALUE;
      Ind[Number].m_LineBuffer[bar]=Number;
      Ind[Number].m_ColorLineBuffer[bar]=0;
      Time0=Time[bar];

      //---- copy the new data into the array
      if(CopyTime(Symbol(),Ind[Number].m_TimeFrame,Time0,1,Time_)<=0) return(RESET);

      if(Time0>=Time_[0] && Time[bar+1]<Time_[0])
        {
         LastCountBar[Number]=bar;
         
         //---- copy new data into the arrays
         if(CopyBuffer(Ind[Number].m_Handle,MAIN_LINE,Time0,1,Main)<=0) return(RESET);
         if(CopyBuffer(Ind[Number].m_Handle,SIGNAL_LINE,Time0,1,Signal)<=0) return(RESET);

         if(Main[0]>Signal[0])
           {
            Ind[Number].m_UpBuffer[bar]=Number;
            Ind[Number].m_ColorLineBuffer[bar]=2;
           }
         if(Main[0]<Signal[0])
           {
            Ind[Number].m_DnBuffer[bar]=Number;
            Ind[Number].m_ColorLineBuffer[bar]=1;
           }
        }
        
      if(Ind[Number].m_ColorLineBuffer[bar+1]&&!Ind[Number].m_ColorLineBuffer[bar])
        Ind[Number].m_ColorLineBuffer[bar]=Ind[Number].m_ColorLineBuffer[bar+1];
     }
//----     
   return(true);
  }
//+------------------------------------------------------------------+ 
//| MACD iteration function                                          | 
//+------------------------------------------------------------------+ 
int OnCalculate(
                const int rates_total,    // history in bars at the current tick
                const int prev_calculated,// history in bars at the previous tick
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
//---- checking for the sufficiency of the number of bars for the calculation
   if(rates_total<min_rates_total || !Init) return(RESET);
//---- Declaration of integer variables
   int limit;
//---- calculations of the necessary amount of data to be copied and
//the starting number limit for the bar recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
      limit=rates_total-min_rates_total-1; // starting index for the calculation of all bars
   else limit=rates_total-prev_calculated; // starting index for the calculation of new bars 

//---- indexing array elements as time series  
   ArraySetAsSeries(time,true);

   for(int count=0; count<INDTOTAL; count++) if(!IndOnCalculate(count,limit,time,rates_total,prev_calculated)) return(RESET);
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+

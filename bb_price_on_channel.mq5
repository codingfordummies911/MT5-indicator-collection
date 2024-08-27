//+------------------------------------------------------------------+
//|                                          BB_Price_on_channel.mq5 |
//|                        Copyright 2009, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2009, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots   3
//---- plot MA
#property indicator_label1  "Bollinger High"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_label2  "Open;High;Low;Close"
#property indicator_type2   DRAW_BARS
#property indicator_color2  clrBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

#property indicator_label3  "Bollinger Low"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrRed
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
#property indicator_level1  50
#property indicator_level2  -50

//--- input parameters
input int                period=15;
input double             deviation=2;
input ENUM_APPLIED_PRICE price=PRICE_WEIGHTED;

//--- indicator buffers
double MABuffer[];
double MABuffer2[];
double BolingerBuffer[];
double BolingerBuffer_l[];
double BarsBuffer1[];
double BarsBuffer2[];
double BarsBuffer3[];
double BarsBuffer4[];
int ma_handle;
string symbol;
int indx1=100000;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,BolingerBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,BarsBuffer1,INDICATOR_DATA);
   SetIndexBuffer(2,BarsBuffer2,INDICATOR_DATA);
   SetIndexBuffer(3,BarsBuffer3,INDICATOR_DATA);
   SetIndexBuffer(4,BarsBuffer4,INDICATOR_DATA);
   SetIndexBuffer(5,BolingerBuffer_l,INDICATOR_DATA);
   IndicatorSetInteger(INDICATOR_DIGITS,0);

   SetIndexBuffer(6,MABuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,MABuffer2,INDICATOR_CALCULATIONS);

   symbol=_Symbol;
//--- set short name
   IndicatorSetString(INDICATOR_SHORTNAME,"Bolkinger View ("+symbol+"): "" ");
//---
   ma_handle=iBands(Symbol(),0,period,0,deviation,price);
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
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
//--- check if all data calculated
   if(BarsCalculated(ma_handle)<rates_total) return(0);
//--- we can copy not all data
   int to_copy;
   if(prev_calculated>rates_total || prev_calculated<=0) to_copy=rates_total;
   else
     {
      to_copy=rates_total-prev_calculated;
      //--- last value is always copied
      to_copy++;
     }
//--- try to copy
   CopyBuffer(ma_handle,0,0,to_copy,MABuffer);
   CopyBuffer(ma_handle,1,0,to_copy,MABuffer2);
//--- calculate 
   for(int i=0;i<rates_total && !IsStopped();i++)
     {
      BolingerBuffer[i]=(MABuffer2[i]-MABuffer[i])*indx1;
      BolingerBuffer_l[i]=-BolingerBuffer[i];

      BarsBuffer1[i]=(open[i]-MABuffer[i])*indx1;
      BarsBuffer2[i]=(high[i]-MABuffer[i])*indx1;
      BarsBuffer3[i]=(low[i]-MABuffer[i])*indx1;
      BarsBuffer4[i]=(close[i]-MABuffer[i])*indx1;
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+

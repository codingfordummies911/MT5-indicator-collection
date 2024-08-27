//+------------------------------------------------------------------+
//|                                            MACD_AnyTimeFrame.mq5 |
//|                                      Copyright 2010, Slacktrader |
//+------------------------------------------------------------------+
#property copyright   "Slacktrader"
#property description "Moving Average Convergence/Divergence - Any higher timeframe"
//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_type2   DRAW_LINE
#property indicator_color1  Silver
#property indicator_color2  Red
#property indicator_width1  2
#property indicator_width2  1
#property indicator_label1  "MACD"
#property indicator_label2  "Signal"
//--- input parameters
input ENUM_TIMEFRAMES    ANY_TIMEFRAME = PERIOD_H1;   //Timeframe of MACD which we want to see instead of current Period
                                                      //It has to be a higher timeframe as currently displayed
input int                InpFastEMA=12;               // Fast EMA period
input int                InpSlowEMA=26;               // Slow EMA period
input int                InpSignalSMA=9;              // Signal SMA period
input ENUM_APPLIED_PRICE InpAppliedPrice=PRICE_CLOSE; // Applied price
//--- indicator buffers
double                   ExtMacdBuffer[];
double                   ExtSignalBuffer[];
double                   ExtMacdBuffer2pom[];
double                   ExtSignalBuffer2pom[];
//--- MACD Handle
int                      MacdHandle;
//--- variable to hold ratio between current chart timeframe and MACD timeframe
int                      PeriodRatio;
//+------------------------------------------------------------------+
//| PeriodStr                                                        |
//+------------------------------------------------------------------+
string PeriodStr(int val)
  {
   int i;
//--- arrays to convert ENUM_TIMEFRAMES to string
   static string _p_str[]=
     {
      "M1","M2","M3","M4","M5","M6","M10","M12","M15","M20","M30",
      "H1","H2","H3","H4","H6","H12","D1","W1","MN","UNKNOWN"
     };
   static int    _p_int[]={1,2,3,4,5,6,10,12,15,20,30,0x4001,0x4002,0x4003,0x4004,0x4006,0x400c,0x4018,0x8001,0xc001};
//--- checking
   if(val<0) return("ERROR");
//---
   if(val==(int)PERIOD_CURRENT) val=ChartPeriod();
   for(i=0;i<20;i++)
      if(val==_p_int[i])
        {
         break;
        }
//---
   return(_p_str[i]);
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtMacdBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtSignalBuffer,INDICATOR_DATA);

   MacdHandle=iMACD(NULL,ANY_TIMEFRAME,InpFastEMA,InpSlowEMA,InpSignalSMA,InpAppliedPrice);

   PeriodRatio=PeriodSeconds(ANY_TIMEFRAME)/PeriodSeconds();
   IndicatorSetString(INDICATOR_SHORTNAME,"MACD - Any Timeframe - "+PeriodStr(ANY_TIMEFRAME));

   Comment("");

   if(PeriodRatio<1)
     {
      Comment("Variable ANY_TIMEFRAME has to be a Timeframe equal or higher then current chart!","Please coose right timeframe!");
      return(-1);
     }

   return(0);
//--- initialization done
  }
//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
//+------------------------------------------------------------------+
int OnCalculate (const int rates_total,      // size of the price[] array
                 const int prev_calculated,  // bars handled on a previous call
                 const int begin,            // where the significant data start from
                 const double& price[])      // array to calculate
  {
//--- check if all data calculated
   if(BarsCalculated(MacdHandle)<rates_total/PeriodRatio) return(0);
//--- we can copy not all data
   int to_copy;
   if(prev_calculated>rates_total || prev_calculated<=0) to_copy=rates_total;
   else
     {
      to_copy=rates_total-prev_calculated;
      //--- last value is always copied
      to_copy++;
     }

   CopyBuffer(MacdHandle,0,0,to_copy/PeriodRatio,ExtMacdBuffer2pom);
   CopyBuffer(MacdHandle,1,0,to_copy/PeriodRatio,ExtSignalBuffer2pom);

   ArrayResize(ExtMacdBuffer,ArraySize(ExtMacdBuffer2pom)*PeriodRatio);

   for(int i=0; i<ArraySize(ExtMacdBuffer2pom); i++)
      for(int j=0; j<PeriodRatio; j++)
         ExtMacdBuffer[int(fmod(to_copy,PeriodRatio))+i*PeriodRatio+j]=ExtMacdBuffer2pom[i];

   ArrayResize(ExtSignalBuffer,ArraySize(ExtSignalBuffer2pom)*PeriodRatio);

   for(int i=0; i<ArraySize(ExtSignalBuffer2pom); i++)
      for(int j=0; j<PeriodRatio; j++)
         ExtSignalBuffer[int(fmod(to_copy,PeriodRatio))+i*PeriodRatio+j]=ExtSignalBuffer2pom[i];

   return(rates_total);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                           Bollinger bands %b.mq5 |
//|                                   Copyright 2014, mohsen khashei |
//|                                               mkhashei@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, mohsen khashei"
#property link      "mkhashei@gmail.com"
#property version   "1.10"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   1
//--- plot Label1
#property indicator_label1  "Bollinger bands %b"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrYellow
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_level1 0.0
#property indicator_level2 0.5
#property indicator_level3 1.0

//---- input parameters
input int    BBPeriod=20;        //Period
input int    BBShift=0;         // Shift
input double StdDeviation=2.0;  //Standard Deviation
input ENUM_APPLIED_PRICE appliedprc=PRICE_CLOSE; //Applied Price
//--- indicator buffers
double         UpperBuffer[];
double         LowerBuffer[];
double         MiddleBuffer[];
double         BLGBuffer[];
int    bbhandle;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,BLGBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,MiddleBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,UpperBuffer ,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,LowerBuffer ,INDICATOR_CALCULATIONS); 
   ArraySetAsSeries(BLGBuffer,true);
   ArraySetAsSeries(MiddleBuffer,true);
   ArraySetAsSeries(UpperBuffer,true);
   ArraySetAsSeries(LowerBuffer,true);
    if(Bars(_Symbol,_Period)<60)
  {
  Alert("We have less than 60 bars for Indicator exited now!!");
  return (-1);
  
  }
   bbhandle=iBands(NULL,0,BBPeriod,BBShift,StdDeviation,appliedprc);
    if(bbhandle<0){
  Alert("Can not create handle ",GetLastError(),"!!");
  return (-1);
  }
 //---
   return(INIT_SUCCEEDED);
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
//---
   ArraySetAsSeries(close,true);
   if(BarsCalculated(bbhandle)<rates_total) return(0);
   if(CopyBuffer(bbhandle,0,0,rates_total,MiddleBuffer)<=0) return (0);
   if(CopyBuffer(bbhandle,1,0,rates_total,UpperBuffer)<=0) return (0);
   if(CopyBuffer(bbhandle,2,0,rates_total,LowerBuffer)<=0) return (0); 
   
   int pos=prev_calculated-1;
   if(pos<0) pos=0;
   for(int i=pos; i<rates_total-(BBPeriod+BBShift+1); i++)
     {
    
     BLGBuffer[i]=(close[i]-LowerBuffer[i])/(UpperBuffer[i]-LowerBuffer[i]);

     }
   return(rates_total);
  }
//+------------------------------------------------------------------+

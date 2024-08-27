//+------------------------------------------------------------------+
//|                                                      iBBFill.mq5 |
//|                                                Copyright Integer |
//|                                                 http://dmffx.com |
//+------------------------------------------------------------------+
#property copyright "Integer"
#property link      "http://dmffx.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 10
#property indicator_plots   6
//--- plot Label1
#property indicator_label1  "UpTrend"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  C'10,10,70'
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Label2
#property indicator_label2  "DnTrend"
#property indicator_type2   DRAW_FILLING
#property indicator_color2  C'70,10,10'
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot Label3
#property indicator_label3  "Flat"
#property indicator_type3   DRAW_FILLING
#property indicator_color3  C'50,50,50'
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- plot Label4
#property indicator_label4  "BB MA"
#property indicator_type4   DRAW_LINE
#property indicator_color4  Yellow
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
//--- plot Label5
#property indicator_label5  "BB Upper"
#property indicator_type5   DRAW_LINE
#property indicator_color5  DodgerBlue
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1
//--- plot Label6
#property indicator_label6  "BB Lower"
#property indicator_type6   DRAW_LINE
#property indicator_color6  Red
#property indicator_style6  STYLE_SOLID
#property indicator_width4  1
//--- input parameters
input int                 BBPeriod    =  20;          // Период BB
input double              BBDeviation =  2;           // Ширина BB
input ENUM_APPLIED_PRICE  BBPrice     =  PRICE_CLOSE; // Цена BB
//--- indicator buffers
double Upper1[];
double Lower1[];
double Upper2[];
double Lower2[];
double Upper3[];
double Lower3[];
double BCBuf[];
double BUBuf[];
double BLBuf[];
double Trend[];
int BBHand;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0,Upper1,INDICATOR_DATA);
   SetIndexBuffer(1,Lower1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,Upper2,INDICATOR_DATA);
   SetIndexBuffer(3,Lower2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,Upper3,INDICATOR_DATA);
   SetIndexBuffer(5,Lower3,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,BCBuf,INDICATOR_DATA);
   SetIndexBuffer(7,BUBuf,INDICATOR_DATA);
   SetIndexBuffer(8,BLBuf,INDICATOR_DATA);
   SetIndexBuffer(9,Trend,INDICATOR_CALCULATIONS);

   BBHand=iBands(NULL,PERIOD_CURRENT,BBPeriod,0,BBDeviation,BBPrice);

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
   int limit=0,limit1=0;
   if(prev_calculated>0)
     {
      limit=prev_calculated-1;
      limit1=limit;
     }
   else
     {
      limit=0;
      limit1=1;
     }

   CopyBuffer(BBHand,0,0,rates_total-limit,BCBuf);
   CopyBuffer(BBHand,1,0,rates_total-limit,BUBuf);
   CopyBuffer(BBHand,2,0,rates_total-limit,BLBuf);

   for(int i=limit1;i<rates_total;i++)
     {
      Trend[i]=Trend[i-1];
      Upper1[i]=0;
      Lower1[i]=0;
      Upper2[i]=0;
      Lower2[i]=0;
      Upper3[i]=0;
      Lower3[i]=0;

      if(Trend[i]==1 && close[i]<BCBuf[i])
        {
         Trend[i]=0;
        }
      if(Trend[i]==-1 && close[i]>BCBuf[i])
        {
         Trend[i]=0;
        }

      if(close[i]>BUBuf[i])
        {
         Trend[i]=1;
        }
      if(close[i]<BLBuf[i])
        {
         Trend[i]=-1;
        }

      switch((int)Trend[i])
        {
         case 1:
            Upper1[i]=BUBuf[i];
            Lower1[i]=BLBuf[i];
            if(Trend[i-1]!=1)
              {
               Upper1[i-1]=BUBuf[i-1];
               Lower1[i-1]=BLBuf[i-1];
              }
            break;
         case -1:
            Upper2[i]=BUBuf[i];
            Lower2[i]=BLBuf[i];
            if(Trend[i-1]!=-1)
              {
               Upper2[i-1]=BUBuf[i-1];
               Lower2[i-1]=BLBuf[i-1];
              }
            break;
         case 0:
            Upper3[i]=BUBuf[i];
            Lower3[i]=BLBuf[i];
            if(Trend[i-1]!=0)
              {
               Upper3[i-1]=BUBuf[i-1];
               Lower3[i-1]=BLBuf[i-1];
              }
            break;
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+

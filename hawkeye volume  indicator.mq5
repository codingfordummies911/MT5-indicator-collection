//+------------------------------------------------------------------+
//|                                                  VOLUME TYPE.mq4 |
//|                                    Copyright © 2008, FOREXflash. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""

#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   4
#property indicator_color1  clrDimGray
#property indicator_color2  clrLime
#property indicator_color3  clrRed
#property indicator_color4  clrWhite
#property indicator_width1  2
#property indicator_width2  2
#property indicator_width3  2
#property indicator_width4  2
#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_type3   DRAW_HISTOGRAM
#property indicator_type4   DRAW_HISTOGRAM


//
//
//

input ENUM_APPLIED_VOLUME inpVol        = VOLUME_TICK;         // Volume type
input int                 Length        = 50;                  // Ma length
enum  enMaTypes
      {
         ma_sma,                                               // Simple moving average
         ma_ema,                                               // Exponential moving average
         ma_smma,                                              // Smoothed MA
         ma_lwma,                                              // Linear weighted MA
      };
input enMaTypes           MaMode       = ma_ema;               // Ma mode
input int                 NumberOfBars = 500;                  // Number of bars to display

double v4[],GREEN[],RED[],WHITE[],trend[];
struct sGlobalStruct
{
   double mi;
   double up;
   double dn;
   long   vol;
};
sGlobalStruct glo;

//
//
//

int OnInit()   
{
   SetIndexBuffer(0,v4,   INDICATOR_DATA);
   SetIndexBuffer(1,GREEN,INDICATOR_DATA);
   SetIndexBuffer(2,RED,  INDICATOR_DATA);   
   SetIndexBuffer(3,WHITE,INDICATOR_DATA); 
   SetIndexBuffer(4,trend,INDICATOR_CALCULATIONS);
   
   IndicatorSetString(INDICATOR_SHORTNAME,"VOLUME with "+getAvgName(MaMode)+"");
return(INIT_SUCCEEDED);
}

//
//
//

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
   int _limit = (prev_calculated>0) ? prev_calculated-1 : 0;
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,(NumberOfBars<=0?0:rates_total-NumberOfBars+1));
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,(NumberOfBars<=0?0:rates_total-NumberOfBars+1));
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,(NumberOfBars<=0?0:rates_total-NumberOfBars+1));
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,(NumberOfBars<=0?0:rates_total-NumberOfBars+1));
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,(NumberOfBars<=0?0:rates_total-NumberOfBars+1));
   
   //
   //
   //
   
   for (int i=_limit; i<rates_total && !_StopFlag; i++)
   {
      glo.mi   = (high[i]+low[i])/2;                           // EXACT MIDDLE
      glo.up   = (high[i]+low[i])/2 + (high[i]-low[i])/6;      // UP CLOSE
      glo.dn   = (high[i]+low[i])/2 - (high[i]-low[i])/6;      // DOWN CLOSE
      trend[i] = (i>0) ? (close[i]>glo.up && open[i]<close[i] && close[i]>high[i-1]) ?  1 : 
                         (close[i]<glo.dn && open[i]>close[i] && close[i]< low[i-1]) ? -1 : 0 : 0;
         
      glo.vol  = (inpVol==VOLUME_TICK) ? tick_volume[i] : volume[i];  
      GREEN[i] = (trend[i] == 1) ? NormalizeDouble(glo.vol,0) : EMPTY_VALUE;
      RED[i]   = (trend[i] ==-1) ? NormalizeDouble(glo.vol,0) : EMPTY_VALUE;   
      WHITE[i] = (trend[i] == 0) ? NormalizeDouble(glo.vol,0) : EMPTY_VALUE;  
      v4[i]    = NormalizeDouble(iCustomMa(MaMode,glo.vol,Length,i,rates_total),0);     
    }
return(rates_total);
}

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------

string getAvgName(int method)
{
      switch(method)
      {
         case ma_ema:    return("EMA");
         case ma_lwma:   return("LWMA");
         case ma_sma:    return("SMA");
         case ma_smma:   return("SMMA");
      }
return("");      
}

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------

#define _maInstances 1
#define _maWorkBufferx1 1*_maInstances
#define _maWorkBufferx2 2*_maInstances
#define _maWorkBufferx3 3*_maInstances

double iCustomMa(int mode, double price, double length, int r, int bars, int instanceNo=0)
{
   //r = bars-r-1;
   switch (mode)
   {
      case ma_sma   : return(iSma(price,(int)ceil(length),r,bars,instanceNo));
      case ma_ema   : return(iEma(price,length,r,bars,instanceNo));
      case ma_smma  : return(iSmma(price,(int)ceil(length),r,bars,instanceNo));
      case ma_lwma  : return(iLwma(price,(int)ceil(length),r,bars,instanceNo));
      default       : return(price);
   }
}

//
//
//
//
//

double workSma[][_maWorkBufferx1];
double iSma(double price, int period, int r, int _bars, int instanceNo=0)
{
   if (ArrayRange(workSma,0)!= _bars) ArrayResize(workSma,_bars);

   workSma[r][instanceNo+0] = price;
   double avg = price; int k=1;  for(; k<period && (r-k)>=0; k++) avg += workSma[r-k][instanceNo+0];  
   return(avg/(double)k);
}

//
//
//
//
//

double workEma[][_maWorkBufferx1];
double iEma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (ArrayRange(workEma,0)!= _bars) ArrayResize(workEma,_bars);

   workEma[r][instanceNo] = price;
   if (r>0 && period>1)
          workEma[r][instanceNo] = workEma[r-1][instanceNo]+(2.0/(1.0+period))*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
}

//
//
//
//
//

double workSmma[][_maWorkBufferx1];
double iSmma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (ArrayRange(workSmma,0)!= _bars) ArrayResize(workSmma,_bars);

   workSmma[r][instanceNo] = price;
   if (r>1 && period>1)
          workSmma[r][instanceNo] = workSmma[r-1][instanceNo]+(price-workSmma[r-1][instanceNo])/period;
   return(workSmma[r][instanceNo]);
}

//
//
//
//
//

double workLwma[][_maWorkBufferx1];
double iLwma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (ArrayRange(workLwma,0)!= _bars) ArrayResize(workLwma,_bars);
   
   workLwma[r][instanceNo] = price; if (period<=1) return(price);
      double sumw = period;
      double sum  = period*price;

      for(int k=1; k<period && (r-k)>=0; k++)
      {
         double weight = period-k;
                sumw  += weight;
                sum   += weight*workLwma[r-k][instanceNo];  
      }             
      return(sum/sumw);
}
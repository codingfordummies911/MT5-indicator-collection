//------------------------------------------------------------------
#property copyright   "© mladen, 2017, @ mladenfx@gmail.com"
#property link        "www.forex-station.com"
#property version     "1.00"
//------------------------------------------------------------------
#property description "Moving Average Convergence/Divergence"
#property indicator_separate_window
#property indicator_buffers 9
#property indicator_plots   4
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_type3   DRAW_COLOR_LINE
#property indicator_type4   DRAW_COLOR_ARROW
#property indicator_color1  clrLimeGreen, clrGreen, clrRed, clrFireBrick
#property indicator_color2  clrLimeGreen, clrGreen, clrRed, clrFireBrick
#property indicator_color3  clrLimeGreen, clrRed
#property indicator_color3  clrLimeGreen, clrRed
#property indicator_color4  clrLimeGreen, clrGreen, clrRed, clrFireBrick
#property indicator_width1  2
#property indicator_width2  3
#property indicator_width3  2
#property indicator_label1  "MACD"
#property indicator_label2  "MACD line"
#property indicator_label3  "Signal"
#property indicator_label4  "dots"

//
//
//
//
//

enum enPrices
{
   pr_close,      // Close
   pr_open,       // Open
   pr_high,       // High
   pr_low,        // Low
   pr_median,     // Median
   pr_typical,    // Typical
   pr_weighted,   // Weighted
   pr_average,    // Average (high+low+open+close)/4
   pr_medianb,    // Average median body (open+close)/2
   pr_tbiased,    // Trend biased price
   pr_haclose,    // Heiken ashi close
   pr_haopen ,    // Heiken ashi open
   pr_hahigh,     // Heiken ashi high
   pr_halow,      // Heiken ashi low
   pr_hamedian,   // Heiken ashi median
   pr_hatypical,  // Heiken ashi typical
   pr_haweighted, // Heiken ashi weighted
   pr_haaverage,  // Heiken ashi average
   pr_hamedianb,  // Heiken ashi median body
   pr_hatbiased   // Heiken ashi trend biased price
};

input ENUM_TIMEFRAMES  TimeFrame       = PERIOD_CURRENT; // Time frame
input int              InpFastEMA      = 12;             // Macd fast period
input int              InpSlowEMA      = 26;             // Macd slow period
input int              InpSignalEMA    =  9;             // Signal period 
input enPrices         InpAppliedPrice = pr_close;       // Price to use
input bool             Interpolate     = true;           // Interpolate in multi time frame mode?

//
//
//
//
//

double  ExtMacdBuffer[],ExtMacdBufferl[],ExtSignalBuffer[],ExtFastMaBuffer[],ExtSlowMaBuffer[],dots[],Colors[],Colorsl[],Colorss[],Colorsd[],count[];
int     _mtfHandle = INVALID_HANDLE; ENUM_TIMEFRAMES timeFrame;
#define _mtfCall iCustom(_Symbol,timeFrame,getIndicatorName(),PERIOD_CURRENT,InpFastEMA,InpSlowEMA,InpSignalEMA,InpAppliedPrice)

//------------------------------------------------------------------
//
//------------------------------------------------------------------
void OnInit()
{
   SetIndexBuffer(0,ExtMacdBuffer,  INDICATOR_DATA);
   SetIndexBuffer(1,Colors         ,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,ExtMacdBufferl, INDICATOR_DATA);
   SetIndexBuffer(3,Colorsl        ,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(4,ExtSignalBuffer,INDICATOR_DATA);
   SetIndexBuffer(5,Colorss        ,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(6,dots           ,INDICATOR_DATA);
   SetIndexBuffer(7,Colorsd        ,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(8,count          ,INDICATOR_CALCULATIONS);
   PlotIndexSetInteger(3,PLOT_ARROW,158);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,InpSignalEMA-1);
      timeFrame = MathMax(_Period,TimeFrame);
   IndicatorSetString(INDICATOR_SHORTNAME,"MACD original("+string(InpFastEMA)+","+string(InpSlowEMA)+","+string(InpSignalEMA)+")");
}
int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &TickVolume[],
                const long &Volume[],
                const int &Spread[])
{
   if (Bars(_Symbol,_Period)<rates_total) return(-1);

      //
      //
      //
      //
      //

      if (timeFrame!=_Period)
      {
         double result[]; datetime currTime[],nextTime[]; 
            if (!timeFrameCheck(timeFrame,time))         return(0);
            if (_mtfHandle==INVALID_HANDLE) _mtfHandle = _mtfCall;
            if (_mtfHandle==INVALID_HANDLE)              return(0);
            if (CopyBuffer(_mtfHandle,8,0,1,result)==-1) return(0); 
      
                //
                //
                //
                //
                //
              
                #define _mtfRatio PeriodSeconds(timeFrame)/PeriodSeconds(_Period)
                int k,n,i = MathMin(MathMax(prev_calculated-1,0),MathMax(rates_total-(int)result[0]*_mtfRatio-1,0));
                for (; i<rates_total && !_StopFlag; i++ )
                {
                  #define _mtfCopy(_buff,_buffNo) if (CopyBuffer(_mtfHandle,_buffNo,time[i],1,result)==-1) break; _buff[i] = result[0]
                          _mtfCopy(ExtMacdBuffer    ,0);
                          _mtfCopy(Colors           ,1);
                          _mtfCopy(ExtMacdBufferl   ,2);
                          _mtfCopy(Colorsl          ,3);
                          _mtfCopy(ExtSignalBuffer  ,4);
                          _mtfCopy(Colorss          ,5);
                          _mtfCopy(dots             ,6);
                          _mtfCopy(Colorsd          ,7);
                   
                          //
                          //
                          //
                          //
                          //
                   
                          if (!Interpolate) continue;  CopyTime(_Symbol,timeFrame,time[i  ],1,currTime); 
                              if (i<(rates_total-1)) { CopyTime(_Symbol,timeFrame,time[i+1],1,nextTime); if (currTime[0]==nextTime[0]) continue; }
                              for(n=1; (i-n)> 0 && time[i-n] >= currTime[0]; n++) continue;	
                              for(k=1; (i-k)>=0 && k<n; k++)
                              {
                                 #define _mtfInterpolate(_buff) _buff[i-k] = _buff[i]+(_buff[i-n]-_buff[i])*k/n
                                 _mtfInterpolate(ExtMacdBuffer);
                                 _mtfInterpolate(ExtMacdBufferl);
                                 _mtfInterpolate(ExtSignalBuffer);
                              }                              
                }
                return(i);
      }

   //
   //
   //
   //
   //
   
      int i=(int)MathMax(prev_calculated-1,0); for (; i<rates_total  && !_StopFlag; i++)
      {
         double price = getPrice(InpAppliedPrice,Open,Close,High,Low,rates_total,i);
         ExtMacdBuffer[i]   = iEma(price,InpFastEMA,i,rates_total,0)-iEma(price,InpSlowEMA,i,rates_total,1);
         ExtMacdBufferl[i]  = ExtMacdBuffer[i];
         ExtSignalBuffer[i] = iEma(ExtMacdBuffer[i],InpSignalEMA,i,rates_total,2);
         dots[i]            = EMPTY_VALUE;
         Colorsd[i]         = -1;
         if (i>0)
         {
            if (ExtMacdBuffer[i]>0)
            {
               if (ExtMacdBuffer[i]>ExtMacdBuffer[i-1]) Colors[i] = 0;
               if (ExtMacdBuffer[i]<ExtMacdBuffer[i-1]) Colors[i] = 1;
               if (Colors[i]==1 && ExtMacdBuffer[i]>ExtSignalBuffer[i]) Colorsd[i] = 1;
               if (Colors[i]==0 && ExtMacdBuffer[i]<ExtSignalBuffer[i]) Colorsd[i] = 2;
            }
            if (ExtMacdBuffer[i]<0)
            {
               if (ExtMacdBuffer[i]<ExtMacdBuffer[i-1]) Colors[i] = 2;
               if (ExtMacdBuffer[i]>ExtMacdBuffer[i-1]) Colors[i] = 3;
               if (Colors[i]==3 && ExtMacdBuffer[i]<ExtSignalBuffer[i]) Colorsd[i] = 2;
               if (Colors[i]==2 && ExtMacdBuffer[i]>ExtSignalBuffer[i]) Colorsd[i] = 1;
            }
            if (ExtMacdBuffer[i]<ExtSignalBuffer[i]) Colorss[i] = 1;
            if (ExtMacdBuffer[i]>ExtSignalBuffer[i]) Colorss[i] = 0;
         }         
         if (Colorsd[i]!=-1) 
         {
            if (ExtMacdBuffer[i]>0) dots[i] = ExtMacdBuffer[i]+5*_Point;
            if (ExtMacdBuffer[i]<0) dots[i] = ExtMacdBuffer[i]-5*_Point;
         }            
         Colorsl[i] = Colors[i];
      }         
   count[rates_total-1] = MathMax(rates_total-prev_calculated+1,1);
   return(i);
}
  
//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//

double workEma[][3];
double iEma(double price, double period, int r, int totalBars, int instanceNo=0)
{
   if (ArrayRange(workEma,0)!= totalBars) ArrayResize(workEma,totalBars);

   //
   //
   //
   //
   //
      
   double alpha = 2.0 / (1.0+period);
   workEma[r][instanceNo] = price;
   if (r>0)
          workEma[r][instanceNo] = workEma[r-1][instanceNo]+alpha*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//
//


double workHa[][4];
double getPrice(int price, const double& open[], const double& close[], const double& high[], const double& low[], int bars, int i,  int instanceNo=0)
{
  if (price>=pr_haclose)
   {
      if (ArrayRange(workHa,0)!= bars) ArrayResize(workHa,bars);
         
         //
         //
         //
         //
         //
         
         double haOpen;
         if (i>0)
                haOpen  = (workHa[i-1][instanceNo+2] + workHa[i-1][instanceNo+3])/2.0;
         else   haOpen  = (open[i]+close[i])/2;
         double haClose = (open[i] + high[i] + low[i] + close[i]) / 4.0;
         double haHigh  = MathMax(high[i], MathMax(haOpen,haClose));
         double haLow   = MathMin(low[i] , MathMin(haOpen,haClose));

         if(haOpen  <haClose) { workHa[i][instanceNo+0] = haLow;  workHa[i][instanceNo+1] = haHigh; } 
         else                 { workHa[i][instanceNo+0] = haHigh; workHa[i][instanceNo+1] = haLow;  } 
                                workHa[i][instanceNo+2] = haOpen;
                                workHa[i][instanceNo+3] = haClose;
         //
         //
         //
         //
         //
         
         switch (price)
         {
            case pr_haclose:     return(haClose);
            case pr_haopen:      return(haOpen);
            case pr_hahigh:      return(haHigh);
            case pr_halow:       return(haLow);
            case pr_hamedian:    return((haHigh+haLow)/2.0);
            case pr_hamedianb:   return((haOpen+haClose)/2.0);
            case pr_hatypical:   return((haHigh+haLow+haClose)/3.0);
            case pr_haweighted:  return((haHigh+haLow+haClose+haClose)/4.0);
            case pr_haaverage:   return((haHigh+haLow+haClose+haOpen)/4.0);
            case pr_hatbiased:
               if (haClose>haOpen)
                     return((haHigh+haClose)/2.0);
               else  return((haLow+haClose)/2.0);        
         }
   }
   
   //
   //
   //
   //
   //
   
   switch (price)
   {
      case pr_close:     return(close[i]);
      case pr_open:      return(open[i]);
      case pr_high:      return(high[i]);
      case pr_low:       return(low[i]);
      case pr_median:    return((high[i]+low[i])/2.0);
      case pr_medianb:   return((open[i]+close[i])/2.0);
      case pr_typical:   return((high[i]+low[i]+close[i])/3.0);
      case pr_weighted:  return((high[i]+low[i]+close[i]+close[i])/4.0);
      case pr_average:   return((high[i]+low[i]+close[i]+open[i])/4.0);
      case pr_tbiased:   
               if (close[i]>open[i])
                     return((high[i]+close[i])/2.0);
               else  return((low[i]+close[i])/2.0);        
   }
   return(0);
}

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------
//
//
//
//
//

string getIndicatorName()
{
   string path = MQL5InfoString(MQL5_PROGRAM_PATH);
   string data = TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL5\\Indicators\\";
   string name = StringSubstr(path,StringLen(data));
      return(name);
}

//
//
//
//
//

int    _tfsPer[]={PERIOD_M1,PERIOD_M2,PERIOD_M3,PERIOD_M4,PERIOD_M5,PERIOD_M6,PERIOD_M10,PERIOD_M12,PERIOD_M15,PERIOD_M20,PERIOD_M30,PERIOD_H1,PERIOD_H2,PERIOD_H3,PERIOD_H4,PERIOD_H6,PERIOD_H8,PERIOD_H12,PERIOD_D1,PERIOD_W1,PERIOD_MN1};
string _tfsStr[]={"1 minute","2 minutes","3 minutes","4 minutes","5 minutes","6 minutes","10 minutes","12 minutes","15 minutes","20 minutes","30 minutes","1 hour","2 hours","3 hours","4 hours","6 hours","8 hours","12 hours","daily","weekly","monthly"};
string timeFrameToString(int period)
{
   if (period==PERIOD_CURRENT) 
       period = _Period;   
         int i; for(i=0;i<ArraySize(_tfsPer);i++) if(period==_tfsPer[i]) break;
   return(_tfsStr[i]);   
}

//
//
//
//
//

bool timeFrameCheck(ENUM_TIMEFRAMES _timeFrame,const datetime& time[])
{
   static bool warned=false;
   if (time[0]<SeriesInfoInteger(_Symbol,_timeFrame,SERIES_FIRSTDATE))
   {
      datetime startTime,testTime[]; 
         if (SeriesInfoInteger(_Symbol,PERIOD_M1,SERIES_TERMINAL_FIRSTDATE,startTime))
         if (startTime>0)                       { CopyTime(_Symbol,_timeFrame,time[0],1,testTime); SeriesInfoInteger(_Symbol,_timeFrame,SERIES_FIRSTDATE,startTime); }
         if (startTime<=0 || startTime>time[0]) { Comment(MQL5InfoString(MQL5_PROGRAM_NAME)+"\nMissing data for "+timeFrameToString(_timeFrame)+" time frame\nRe-trying on next tick"); warned=true; return(false); }
   }
   if (warned) { Comment(""); warned=false; }
   return(true);
}
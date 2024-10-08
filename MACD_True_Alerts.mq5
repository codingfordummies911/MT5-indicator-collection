//+------------------------------------------------------------------+
//|                                                         MACD.mq4 |
//|                                Copyright © 2005, David W. Thomas |
//|                                           mailto:davidwt@usa.net |
//+------------------------------------------------------------------+
// This is the correct computation and display of MACD.
#property copyright "Copyright © 2005, David W. Thomas"
#property link      "mailto:davidwt@usa.net"
#property description "MACD True"
#property strict
//---
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots 3
//--- macd & signal lines
#property indicator_color1 clrBlue
#property indicator_color2 clrRed
//--- macd histogram
#property indicator_color3 clrForestGreen,clrFireBrick
#property indicator_width3 2
//--- input parameters
input string  str2zs = "================================================"; //---
input string  str5sj = "==== MACD Settings ===="; //---
input string  str2el = "================================================"; //---
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT;
input int     FastMAPeriod = 12;
input int     SlowMAPeriod = 26;
input int     SignalMAPeriod = 9;
input ENUM_MA_METHOD MAMethod = MODE_EMA;
input ENUM_APPLIED_PRICE AppliedPrice = PRICE_CLOSE;
//--- signal line
input string  str6as = "================================================"; //---
input string  str3yf = "==== Arrows & Alerts For Signal Line Cross ===="; //---
input string  str7kp = "================================================"; //---
input bool    ShowSignalLineCrossArrows = true;
input bool    SendSignalLineCrossAlert = false;
input bool    SendSignalLineCrossText = false;
input double  SignalLineGap = 3.5; //gap needed to trigger alert, 0=off
input color   BullishSignalLineCrossArrowColor = clrGreen;
input int     BullishSignalLineCrossArrowCode = 233;
input int     BullishSignalLineCrossArrowWidth = 2;
input color   BearishSignalLineCrossArrowColor = clrRed;
input int     BearishSignalLineCrossArrowCode = 234;
input int     BearishSignalLineCrossArrowWidth = 2;
//--- zero line
input string  str6st = "================================================"; //---
input string  str3yk = "==== Arrows & Alerts For Zero Line Cross ===="; //---
input string  str7im = "================================================"; //---
input bool    ShowZeroLineCrossArrows = true;
input bool    SendZeroLineCrossAlert = false;
input bool    SendZeroLineCrossText = false;
input double  ZeroLineGap = 2.5; //gap needed to trigger alert, 0=off
input color   BullishZeroLineCrossArrowColor = clrGreen;
input int     BullishZeroLineCrossArrowCode = 139;
input int     BullishZeroLineCrossArrowWidth = 2;
input color   BearishZeroLineCrossArrowColor = clrRed;
input int     BearishZeroLineCrossArrowCode = 139;
input int     BearishZeroLineCrossArrowWidth = 2;
//--- arrow spacing
input string  str6dv = "================================================"; //---
input string  str3hf = "==== Arrow Spacing ===="; //---
input string  str7hp = "================================================"; //---
input int     ATRPeriodArrows = 20;
input double  ATRMultiplierArrows = 1.25;
////////////////////////////////////////////////////////////////////////////////////////
double ArrowSpacing;
string ObjDel="_macdta"; // unique to this indicator
double ATR[];
////////////////////////////////////////////////////////////////////////////////////////

//--- buffers
double MACDLineBuffer[];
double SignalLineBuffer[];
double HistogramHighBuffer[];
double HistogramLowBuffer[];
double HistogramColorBuffer[];

//--- MA handles
int handleFastMa;
int handleSlowMa;
int handleATR;

//--- variables
double alpha = 0;
double alpha_1 = 0;
bool isBullishSignalLineCrossActive=false;
bool isBearishSignalLineCrossActive=false;
bool isBullishZeroLineCrossActive=false;
bool isBearishZeroLineCrossActive=false;
double fastMA[], slowMA[];
bool arrowsWereDrawnInHistory=false;

/////////////////////////////////////////////////////////////////////////////////////////////
//Calculating the factor needed to turn pip values into their correct points value to accommodate different Digit size.
//Thanks to Lifesys for providing this code. Coders, you need to briefly turn off Wrap and turn on a mono-spaced font to view this properly and see how easy it is to make changes.
string pipFactor[]  = {"JPY","XAG","SILVER","BRENT","WTI","XAU","GOLD","SP500","S&P","UK100","WS30","DAX30","DJ30","NAS100","CAC400"};
double pipFactors[] = { 100,  100,  100,     100,    100,  10,   10,    10,     10,   1,      1,     1,      1,     1,       1};
double factor;//For pips/points stuff. Set up in int init()
/////////////////////////////////////////////////////////////////////////////////////////////

//Time frame arrays
string          TFstr[]  = {"Current","M1","M2","M3","M4","M5","M6","M10","M12","M15",
                            "M20","M30","H1","H2","H3","H4","H6","H8","H12","D1","W1","MN1"};
ENUM_TIMEFRAMES TFenum[] = {PERIOD_CURRENT,PERIOD_M1,PERIOD_M2,PERIOD_M3,PERIOD_M4,PERIOD_M5,PERIOD_M6,
                            PERIOD_M10,PERIOD_M12,PERIOD_M15,PERIOD_M20,PERIOD_M30,PERIOD_H1,PERIOD_H2,
                            PERIOD_H3,PERIOD_H4,PERIOD_H6,PERIOD_H8,PERIOD_H12,PERIOD_D1,PERIOD_W1,PERIOD_MN1};
int             TFint[]  = {0,1,2,3,4,5,6,10,12,15,20,30,16385,16386,16387,16388,16390,16392,16396,16408,32769,49153};

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
//--- name for DataWindow and indicator subwindow label
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
   string short_name=StringFormat("MACD(%s/%s, %d, %d, %d)",_Symbol,TFEnumToStr(TimeFrame),
                           FastMAPeriod,SlowMAPeriod,SignalMAPeriod);
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
   
//--- macd line
   SetIndexBuffer(0,MACDLineBuffer,INDICATOR_DATA);
   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_LINE);
   PlotIndexSetInteger(0,PLOT_LINE_STYLE,STYLE_SOLID);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,SlowMAPeriod);
   PlotIndexSetString(0,PLOT_LABEL,"MACD Line");
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   
//--- signal line
   SetIndexBuffer(1,SignalLineBuffer,INDICATOR_DATA);
   PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_LINE);
   PlotIndexSetInteger(1,PLOT_LINE_STYLE,STYLE_DOT);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,SlowMAPeriod+SignalMAPeriod);
   PlotIndexSetString(1,PLOT_LABEL,"Signal Line");
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);
   
//--- Histogram 
   SetIndexBuffer(2,HistogramHighBuffer,INDICATOR_DATA); 
   PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_COLOR_HISTOGRAM2);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,SlowMAPeriod+SignalMAPeriod);
   PlotIndexSetString(2,PLOT_LABEL,"MACD Histogram");
   
//--- Histogram color    
   SetIndexBuffer(3,HistogramLowBuffer,INDICATOR_DATA);   
   SetIndexBuffer(4,HistogramColorBuffer,INDICATOR_COLOR_INDEX);
   
//--- get MA handles
   handleFastMa=iMA(_Symbol,TimeFrame,FastMAPeriod,0,MAMethod,AppliedPrice);
   //--- if the handle is not created
   if(handleFastMa==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iMA Fast indicator for the symbol %s/%s, error code %d",
                  _Symbol,
                  EnumToString(_Period),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }
   
   handleSlowMa=iMA(_Symbol,TimeFrame,SlowMAPeriod,0,MAMethod,AppliedPrice);
   //--- if the handle is not created
   if(handleSlowMa==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iMA Slow indicator for the symbol %s/%s, error code %d",
                  _Symbol,
                  EnumToString(_Period),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }
     
//--- ATR handle   
   handleATR = iATR(_Symbol,_Period,ATRPeriodArrows);
   //--- if the handle is not created
   if(handleATR==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the ATR indicator for the symbol %s/%s, error code %d",
                  _Symbol,
                  EnumToString(_Period),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }
     
//---
	alpha = 2.0 / (SignalMAPeriod + 1.0);
	alpha_1 = 1.0 - alpha;
	
//--- pips factor
   factor = PFactor(_Symbol);
	
//--- initialization done
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| custom deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{ 
//--- Delete objects when indicator is removed from chart
//--- Add "+ObjDel" to end of object's name
//--- ObjDel --> unique indicator identifier   
   DeleteChartObjects(ObjDel);
   
   if(handleFastMa!=INVALID_HANDLE)
      IndicatorRelease(handleFastMa);
      
   if(handleSlowMa!=INVALID_HANDLE)
      IndicatorRelease(handleSlowMa);
      
   if(handleATR!=INVALID_HANDLE)
      IndicatorRelease(handleATR);
           
//--- clear comment
   Comment("");
   
//---  
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
//--- local variables
   int limit=0;
   bool isNewBar = IsNewBar();
   
//--- array set as series   
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(MACDLineBuffer,true);
   ArraySetAsSeries(SignalLineBuffer,true);
   ArraySetAsSeries(HistogramHighBuffer,true);
   ArraySetAsSeries(HistogramLowBuffer,true);
   ArraySetAsSeries(HistogramColorBuffer,true);
      
//--- must wait for OnCalculate() before working with MTF handles
//--- https://www.mql5.com/en/forum/168437
   if (!arrowsWereDrawnInHistory && prev_calculated>0)
   {
      int calculated=BarsCalculated(handleFastMa);
      if(calculated<=0)
      {
         Print("Not all data of handleFastMa is calculated (",calculated,"bars ). Error",GetLastError());
         return(0);
      }
      calculated=BarsCalculated(handleSlowMa);
      if(calculated<=0)
      {
         Print("Not all data of handleSlowMa is calculated (",calculated,"bars ). Error",GetLastError());
         return(0);
      }
   }      
   
//--- check for possible errors
   if (prev_calculated<0) return(-1);
//--- starting index (limit) for bars recalculation loop
   if(prev_calculated==0)// checking the first call
      limit=rates_total-4-MathMax(ATRPeriodArrows,SlowMAPeriod); // starting index first call
   else
      limit=rates_total-prev_calculated; // starting index    
      
//--- draw arrows in history
   if (!arrowsWereDrawnInHistory && prev_calculated>0)
   {
      for(int i=rates_total-4-MathMax(ATRPeriodArrows,SlowMAPeriod); i>=0; i--)
      {
         CalculateMACD(i);      
         DrawArrowsAndSendAlerts(i, time, open, close, high, low, false); 
      }
      
      // set flag
      arrowsWereDrawnInHistory = true;    
   }
         
//--- draw arrows and send alerts
   if (arrowsWereDrawnInHistory)
   {
      for(int i=limit; i>=0; i--)
      {         
         CalculateMACD(i);
               
         if (isNewBar)
            DrawArrowsAndSendAlerts(i+1, time, open, close, high, low, true);         
      }  
   }
      
//--- 
   return(rates_total);
}

//+------------------------------------------------------------------+
//| CalculateMACD()                                                  |
//+------------------------------------------------------------------+
void CalculateMACD(int i)
{   
   //--- bar shift
   int bar = iBarShift(_Symbol,TimeFrame,iTime(_Symbol,_Period,i));
   if (bar < 0) bar = 0;   

   //iMA(_Symbol,TimeFrame,FastMAPeriod,0,MODE_EMA,PRICE_CLOSE,bar)
   //iMA(_Symbol,TimeFrame,SlowMAPeriod,0,MODE_EMA,PRICE_CLOSE,bar)
   FillArrayFromBuffer(handleFastMa,0,bar,1,fastMA,true,"iMA Fast"); 
   FillArrayFromBuffer(handleSlowMa,0,bar,1,slowMA,true,"iMA Slow");
   
   //--- MACD Line
   MACDLineBuffer[i] = fastMA[0] - slowMA[0];
   
   //--- Signal Line
   SignalLineBuffer[i] = alpha*MACDLineBuffer[i] + alpha_1*SignalLineBuffer[i+1];
   
   //--- Histogram
   double hist = MACDLineBuffer[i] - SignalLineBuffer[i];
   if (hist >= 0)
   {
      HistogramHighBuffer[i] = hist;
      HistogramLowBuffer[i] = 0;
      HistogramColorBuffer[i] = 0;
   }
   if (hist < 0)
   {
      HistogramHighBuffer[i] = 0;
      HistogramLowBuffer[i] = hist;         
      HistogramColorBuffer[i] = 1;
   }
}

//+------------------------------------------------------------------+
//| DrawArrowsAndSendAlerts()                                        |
//+------------------------------------------------------------------+
void DrawArrowsAndSendAlerts(int i, 
                             const datetime &myTime[], 
                             const double &myOpen[], 
                             const double &myClose[], 
                             const double &myHigh[], 
                             const double &myLow[], 
                             bool isNewBar)
{
//--- ATR arrow spacing
    FillArrayFromBuffer(handleATR,0,i,1,ATR,true,"ATR");
    ArrowSpacing = ATR[0] * ATRMultiplierArrows;
   
//--- signal line cross
   bool isBullishSignalLineCross = false;
   bool isBearishSignalLineCross = false;
   
   //isBullishSignalLineCross = (MACDLineBuffer[i+1] <= SignalLineBuffer[i+1] && MACDLineBuffer[i] > SignalLineBuffer[i]);
   //isBearishSignalLineCross = (MACDLineBuffer[i+1] >= SignalLineBuffer[i+1] && MACDLineBuffer[i] < SignalLineBuffer[i]);

//--- reset bullish 'active' flag 
   //if (MACDLineBuffer[i+1] >= SignalLineBuffer[i+1] && MACDLineBuffer[i] < SignalLineBuffer[i])
      //isBullishSignalLineCrossActive = false;
      
//--- reset bearish 'active' flag  
   //if (MACDLineBuffer[i+1] <= SignalLineBuffer[i+1] && MACDLineBuffer[i] > SignalLineBuffer[i])
      //isBearishSignalLineCrossActive = false;

//--- bullish cross
   if (MACDLineBuffer[i] > SignalLineBuffer[i]+SignalLineGap/factor && !isBullishSignalLineCrossActive)
   {
      isBullishSignalLineCross = true;
      isBullishSignalLineCrossActive = true;
      isBearishSignalLineCrossActive = false;
   }
   
//--- bearish cross
   if (MACDLineBuffer[i] < SignalLineBuffer[i]-SignalLineGap/factor && !isBearishSignalLineCrossActive)
   {
      isBearishSignalLineCross = true;
      isBearishSignalLineCrossActive = true;
      isBullishSignalLineCrossActive = false;
   }
   
//--- bullish arrow and alert
   if (isBullishSignalLineCross)
   {          
      // send alert
      if (SendSignalLineCrossAlert && isNewBar)
      {
         string str = "Bullish Signal Line Cross "+_Symbol+" "+TFToStr(_Period)+" | "+TimeToString(TimeCurrent(),TIME_DATE)+" "+TimeToString(TimeCurrent(),TIME_MINUTES);
         SendAlert(str,SendSignalLineCrossAlert,SendSignalLineCrossText);
      }
         
      // draw arrow 
      if (ShowSignalLineCrossArrows)
      {
         string str = "Bullish_Signal_Line_Cross_Arrow";
         drawArrow(i, myLow[i], myHigh[i], myTime[i], true, ArrowSpacing, BullishSignalLineCrossArrowColor, BullishSignalLineCrossArrowCode, BullishSignalLineCrossArrowWidth, str);
      }
   }
   
//--- bearish arrow and alert
   if (isBearishSignalLineCross)
   {          
      // send alert
      if (SendSignalLineCrossAlert && isNewBar)
      {
         string str = "Bearish Signal Line Cross "+_Symbol+" "+TFToStr(_Period)+" | "+TimeToString(TimeCurrent(),TIME_DATE)+" "+TimeToString(TimeCurrent(),TIME_MINUTES);
         SendAlert(str,SendSignalLineCrossAlert,SendSignalLineCrossText);
      }
        
      // draw arrow 
      if (ShowSignalLineCrossArrows)
      {
         string str = "Bearish_Signal_Line_Cross_Arrow";
         drawArrow(i, myLow[i], myHigh[i], myTime[i], false, ArrowSpacing, BearishSignalLineCrossArrowColor, BearishSignalLineCrossArrowCode, BearishSignalLineCrossArrowWidth, str);
      }
   }
   
   //
   //
   //

//--- zero line cross
   bool isBullishZeroLineCross = false;
   bool isBearishZeroLineCross = false;
   
   //isBullishZeroLineCross = (MACDLineBuffer[i+1] <= 0 && MACDLineBuffer[i] > 0);
   //isBearishZeroLineCross = (MACDLineBuffer[i+1] >= 0 && MACDLineBuffer[i] < 0);

//--- bullish cross
   if (MACDLineBuffer[i] > ZeroLineGap/factor && !isBullishZeroLineCrossActive)
   {
      isBullishZeroLineCross = true;
      isBullishZeroLineCrossActive = true;
      isBearishZeroLineCrossActive = false;
   }
   
//--- bearish cross
   if (MACDLineBuffer[i] < -ZeroLineGap/factor && !isBearishZeroLineCrossActive)
   {
      isBearishZeroLineCross = true;
      isBearishZeroLineCrossActive = true;
      isBullishZeroLineCrossActive = false;
   }

//--- bullish arrow and alert
   if (isBullishZeroLineCross)
   {          
      // send alert
      if (SendZeroLineCrossAlert && isNewBar)
      {
         string str = "Bullish Zero Line Cross "+_Symbol+" "+TFToStr(_Period)+" | "+TimeToString(TimeCurrent(),TIME_DATE)+" "+TimeToString(TimeCurrent(),TIME_MINUTES);
         SendAlert(str,SendZeroLineCrossAlert,SendZeroLineCrossText);
      }
         
      // draw arrow 
      if (ShowZeroLineCrossArrows)
      {
         string str = "Bullish_Zero_Line_Cross_Arrow";
         drawArrow(i, myLow[i], myHigh[i], myTime[i], true, ArrowSpacing, BullishZeroLineCrossArrowColor, BullishZeroLineCrossArrowCode, BullishZeroLineCrossArrowWidth, str);
      }
   }
   
//--- bearish arrow and alert
   if (isBearishZeroLineCross)
   {          
      // send alert
      if (SendZeroLineCrossAlert && isNewBar)
      {
         string str = "Bearish Zero Line Cross "+_Symbol+" "+TFToStr(_Period)+" | "+TimeToString(TimeCurrent(),TIME_DATE)+" "+TimeToString(TimeCurrent(),TIME_MINUTES);
         SendAlert(str,SendZeroLineCrossAlert,SendZeroLineCrossText);
      }
        
      // draw arrow 
      if (ShowZeroLineCrossArrows)
      {
         string str = "Bearish_Zero_Line_Cross_Arrow";
         drawArrow(i, myLow[i], myHigh[i], myTime[i], false, ArrowSpacing, BearishZeroLineCrossArrowColor, BearishZeroLineCrossArrowCode, BearishZeroLineCrossArrowWidth, str);
      }
   }
}

//+------------------------------------------------------------------+
//| drawArrow()                                                      |
//+------------------------------------------------------------------+
void drawArrow(int i, 
               double myLow, 
               double myHigh,
               datetime myTime, 
               bool upArrow, 
               double arrowSpacing, 
               color myColor, 
               int myArrowCode, 
               int myWidth, 
               string myName)
{    
   string name = myName+"_"+TimeToString(myTime)+ObjDel; 
   ObjectCreate(0,name,OBJ_ARROW,0,0,0,0,0);   
   ObjectSetInteger(0,name,OBJPROP_ARROWCODE,myArrowCode);
   ObjectSetInteger(0,name,OBJPROP_COLOR,myColor);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,myWidth);
   ObjectSetInteger(0,name,OBJPROP_TIME,myTime);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   if (upArrow)
      ObjectSetDouble(0,name,OBJPROP_PRICE,myLow-arrowSpacing);
   else  
      ObjectSetDouble(0,name,OBJPROP_PRICE,myHigh+arrowSpacing);
}

//+------------------------------------------------------------------+
// IsNewBar()                                                        |
//+------------------------------------------------------------------+
bool IsNewBar()
{
    static datetime lastTime;
    bool isNewBar = (iTime(_Symbol,_Period,0) != lastTime);
    lastTime = iTime(_Symbol,_Period,0);
    
    return(isNewBar);
}

//+------------------------------------------------------------------+
// StringUpper(string str)                                           |
//+------------------------------------------------------------------+
// Converts any lowercase characters in a string to uppercase
// Usage:    string x=StringUpper("The Quick Brown Fox")  returns x = "THE QUICK BROWN FOX"
string StringUpper(string str)
{
  string outstr = "";
  string lower  = "abcdefghijklmnopqrstuvwxyz";
  string upper  = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  for(int i=0; i<StringLen(str); i++)  {
    int t1 = StringFind(lower,StringSubstr(str,i,1),0);
    if (t1 >=0)  
      outstr = outstr + StringSubstr(upper,t1,1);
    else
      outstr = outstr + StringSubstr(str,i,1);
  }
  return(outstr);
  
} //End StringUpper(string str)

//+------------------------------------------------------------------+
//| StrToTF()                                                        |
//+------------------------------------------------------------------+
int StrToTF(string tfs)
{
   StringToUpper(tfs);
   
   for(int i=ArraySize(TFenum)-1; i>=0; i--)
      if(tfs==TFstr[i]) 
         return(TFenum[i]);
         
   return(_Period);
}

//+------------------------------------------------------------------+
//| TFToStr()                                                        |
//+------------------------------------------------------------------+
string TFToStr(int tf)
{
   for(int i=ArraySize(TFint)-1; i>=0; i--) 
      if(tf==TFint[i]) 
         return(TFstr[i]);
   
   return("Current");
}

//+------------------------------------------------------------------+
//| TFEnumToStr()                                                        |
//+------------------------------------------------------------------+
string TFEnumToStr(ENUM_TIMEFRAMES tf)
{
   string str="Current";
   
   for (int i=ArraySize(TFenum)-1; i>=0; i--) 
      if (tf==TFenum[i]) 
         str=TFstr[i];
         
   if (str=="Current")
      str=TFToStr(_Period);
   
   return(str);
}

//+------------------------------------------------------------------+
//| TFCurrentToEnum()                                                |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES TFCurrentToEnum(ENUM_TIMEFRAMES tf)
{
   if(tf == PERIOD_CURRENT)
   {
      int period=_Period;
      
      for(int i=ArraySize(TFint)-1; i>=0; i--) 
      if(period==TFint[i]) 
         return(TFenum[i]);   
   }
   
   return(tf);
}

//+------------------------------------------------------------------+
//| SendAlert()                                                      |
//+------------------------------------------------------------------+
void SendAlert(string sMsg, bool popAlert, bool textMsg)
{
   if(popAlert)
      Alert(sMsg);
   if(textMsg)
      SendNotification(sMsg);   
}

//+------------------------------------------------------------------+
//| Pip Factor                                                       |
//+------------------------------------------------------------------+
double PFactor(string symbol)
{
   //This code supplied by Lifesys. Many thanks Paul - we all owe you. 
   //Gary was trying to make me see this, but I could not understand his explanation. 
   //Paul used Janet and John words.
   
   for ( int i = ArraySize(pipFactor)-1; i >=0; i-- ) 
      if (StringFind(symbol,pipFactor[i],0) != -1) 
         return (pipFactors[i]);
   return(10000);

}//End double PFactor(string pair)


//+------------------------------------------------------------------+
//| CloseEnough()                                                    |
//+------------------------------------------------------------------+
bool CloseEnough(double num1, double num2)
{
   /*
   This function addresses the problem of the way in which mql4 compares doubles. It often messes up the 8th
   decimal point.
   For example, if A = 1.5 and B = 1.5, then these numbers are clearly equal. Unseen by the coder, mql4 may
   actually be giving B the value of 1.50000001, and so the variable are not equal, even though they are.
   This nice little quirk explains some of the problems I have endured in the past when comparing doubles. This
   is common to a lot of program languages, so watch out for it if you program elsewhere.
   Gary (garyfritz) offered this solution, so our thanks to him.
   */
   
   if (num1 == 0 && num2 == 0) return(true); //0==0
   if (MathAbs(num1 - num2) / (MathAbs(num1) + MathAbs(num2)) < 0.00000001) return(true);
   
   //Doubles are unequal
   return(false);

}//End bool CloseEnough(double num1, double num2)

//+------------------------------------------------------------------+
//| DeleteChartObjects()                                             |
//+------------------------------------------------------------------+
void DeleteChartObjects(string str)
{
   // Delete objects when indicator is removed from chart
   // Add "+ObjDel" to end of object's name
   // ObjDel --> unique indicator identifier 
   for(int i=ObjectsTotal(0)-1; i>=0; i--)
   {
      string name=ObjectName(0,i);
      if(StringFind(name, str, 0) != -1)
      {
         ObjectDelete(0,name);
      }
   }
}

//+------------------------------------------------------------------+ 
//|                                                                  | 
//+------------------------------------------------------------------+ 
bool FillArrayFromBuffer(int    ind_handle,  // handle of the indicator 
                         int    ind_buff,    // indicator buffer number
                         int    start,       // start 
                         int    count,       // number of copied values
                         double &arr[],      // array for indicator values
                         bool   as_series,   // index elements as series 
                         string ind_name)    // name of indicator 
{ 
//--- set as series
   if(as_series) ArraySetAsSeries(arr, true);
//--- reset error code 
   ResetLastError(); 
//--- fill a part of the iMABuffer array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(ind_handle,ind_buff,start,count,arr)<0) 
   { 
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the "+ind_name+" indicator, error code %d",_LastError); 
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(false); 
   } 
//--- everything is fine 
   return(true); 
}

//+------------------------------------------------------------------+

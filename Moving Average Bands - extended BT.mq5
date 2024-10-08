//https://forex-station.com/viewtopic.php?f=579495&t=8474816
//------------------------------------------------------------------
#property copyright   "© mladen, 2021"
#property link        "mladenfx@gmail.com"
#property description "Moving Average Bands"
#property description "Based on work published by Vitali Apirine"
#property version     "1.00"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers  9
#property indicator_plots    5
#property indicator_label1   "Candles"
#property indicator_type1    DRAW_COLOR_CANDLES
#property indicator_color1   clrDimGray,clrAqua,clrMagenta
#property indicator_label2   "MidLine - long term ema"
#property indicator_type2    DRAW_LINE
#property indicator_color2   clrNONE         //clrDarkGray
#property indicator_label3   "Short term ema"
#property indicator_type3    DRAW_LINE
#property indicator_color3   clrNONE         //clrRed
#property indicator_style3   STYLE_DASHDOTDOT
#property indicator_label4   "Upper band"
#property indicator_type4    DRAW_LINE
#property indicator_color4   clrNONE         //clrMediumSeaGreen
#property indicator_label5   "Lower band"
#property indicator_type5    DRAW_LINE
#property indicator_color5   clrNONE         //clrCoral

//
//
//

input double             inpPeriodSlow      = 50;          // Slow period
input double             inpPeriodFast      = 10;          // Fast period
input double             inpBandMultiplier  = 1.0;         // Bands multiplier
input ENUM_APPLIED_PRICE inpPrice           = PRICE_CLOSE; // Price
//
//
//
//Forex-Station copy & paste code; Button code start 11
input string             button_note1          = "------------------------------";
input int                btn_Subwindow         = 0;
input ENUM_BASE_CORNER   btn_corner            = CORNER_LEFT_LOWER;
input string             btn_text              = "MA Bands";
input string             btn_Font              = "Arial";
input int                btn_FontSize          = 8; 
input color              btn_text_ON_color     = clrWhite;
input color              btn_text_OFF_color    = clrRed;
input color              btn_background_color  = clrDimGray;
input color              btn_border_color      = clrDarkGray;  
input int                button_x              = 465; 
input int                button_y              = 25; 
input int                btn_Width             = 65;
input int                btn_Height            = 20;
input string             soundBT               = "tick.wav";  
input string             UniqueButtonID        = "MAbands";                               
input string             button_note2          = "------------------------------";

bool show_data = true, recalc = true;
string indicatorFileName, IndicatorName, IndicatorObjPrefix, buttonId;
//Forex-Station copy & paste code; Button code end 11

//
//
//

double emaSlow[],emaFast[],bandup[],banddn[],candleO[],candleH[],candleL[],candleC[],candlec[];
struct sGlobalStruct
{
   int    periodSum;
   double periodDiv;
   double alphaFast;
   double alphaSlow;
};
sGlobalStruct global;
//+------------------------------------------------------------------------------------------------------------------+
//Forex-Station copy & paste code; Button code start 12
string GenerateIndicatorName(const string target) //don't change anything here
   {
    string name = target;
    int try     = 2;
    while(ChartWindowFind(0, name) != -1)
       {
        name = target + " #" + IntegerToString(try++);
       }
    return name;
   }
//+------------------------------------------------------------------------------------------------------------------+
int OnInit(void)
   {
    IndicatorName = GenerateIndicatorName(btn_text);
    IndicatorObjPrefix = "__" + IndicatorName + "__";
    IndicatorSetString(INDICATOR_SHORTNAME, IndicatorName);
    IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
    
    double val;
    if(GlobalVariableGet(IndicatorName + "_visibility", val))
        show_data = val != 0;
        
    ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, 1);
    buttonId = IndicatorObjPrefix + UniqueButtonID;
    createButton(buttonId, btn_text, btn_Width, btn_Height, btn_Font, btn_FontSize, btn_background_color, btn_border_color, btn_text_ON_color);
    ObjectSetInteger(0, buttonId, OBJPROP_YDISTANCE, button_y);
    ObjectSetInteger(0, buttonId, OBJPROP_XDISTANCE, button_x);

    Init2();
    return(INIT_SUCCEEDED);
   }
//+------------------------------------------------------------------------------------------------------------------+
void OnDeinit(const int reason) { 
     ObjectsDeleteAll(0, buttonId, -1, -1);
}
//+------------------------------------------------------------------------------------------------------------------+
void createButton(string buttonID, string buttonText, int width, int height, string font, int fontSize, color bgColor, color borderColor, color txtColor)
   {
    ObjectDelete    (0, buttonID);
    ObjectCreate    (0, buttonID, OBJ_BUTTON, btn_Subwindow, 0, 0);
    ObjectSetInteger(0, buttonID, OBJPROP_COLOR, txtColor);
    ObjectSetInteger(0, buttonID, OBJPROP_BGCOLOR, bgColor);
    ObjectSetInteger(0, buttonID, OBJPROP_BORDER_COLOR, borderColor);
    ObjectSetInteger(0, buttonID, OBJPROP_BORDER_TYPE, BORDER_RAISED);
    ObjectSetInteger(0, buttonID, OBJPROP_XSIZE, width);
    ObjectSetInteger(0, buttonID, OBJPROP_YSIZE, height);
    ObjectSetString (0, buttonID, OBJPROP_FONT, font);
    ObjectSetString (0, buttonID, OBJPROP_TEXT, buttonText);
    ObjectSetInteger(0, buttonID, OBJPROP_FONTSIZE, fontSize);
    ObjectSetInteger(0, buttonID, OBJPROP_SELECTABLE, 0);
    ObjectSetInteger(0, buttonID, OBJPROP_CORNER, btn_corner);
    ObjectSetInteger(0, buttonID, OBJPROP_HIDDEN, 1);
    ObjectSetInteger(0, buttonID, OBJPROP_XDISTANCE, 9999);
    ObjectSetInteger(0, buttonID, OBJPROP_YDISTANCE, 9999);
   }
//+------------------------------------------------------------------------------------------------------------------+
void handleButtonClicks()
   {
    if(ObjectGetInteger(0, buttonId, OBJPROP_STATE))
       {
        ObjectSetInteger(0, buttonId, OBJPROP_STATE, false);
        show_data = !show_data;
        GlobalVariableSet(IndicatorName + "_visibility", show_data ? 1.0 : 0.0);
        recalc = true;
       }
   }
//+------------------------------------------------------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
   {
    handleButtonClicks();
    bool ForexStation = ObjectGetInteger(0,sparam,OBJPROP_TYPE);
    int banzai;
    if (id==CHARTEVENT_OBJECT_CLICK && ForexStation==OBJ_BUTTON)
    {
      if (soundBT!="") PlaySound(soundBT);     
    }

    if (show_data)
       {
         ObjectSetInteger(0,buttonId,OBJPROP_COLOR,btn_text_ON_color);          
         PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_COLOR_CANDLES);
         for(banzai = 1; banzai < 6; banzai++)
            PlotIndexSetInteger(banzai, PLOT_DRAW_TYPE, DRAW_LINE);
       }
    else
       {
        ObjectSetInteger(0,buttonId,OBJPROP_COLOR,btn_text_OFF_color);
        for(banzai = 0; banzai < 6; banzai++)
            PlotIndexSetInteger(banzai, PLOT_DRAW_TYPE, DRAW_NONE);
       }
   }
//Forex-Station copy & paste code; Button code end 12
//+------------------------------------------------------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int Init2()
{
   SetIndexBuffer(0,candleO,INDICATOR_DATA);
   SetIndexBuffer(1,candleH,INDICATOR_DATA);
   SetIndexBuffer(2,candleL,INDICATOR_DATA);
   SetIndexBuffer(3,candleC,INDICATOR_DATA);
   SetIndexBuffer(4,candlec,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(5,emaSlow,INDICATOR_DATA);
   SetIndexBuffer(6,emaFast,INDICATOR_DATA);
   SetIndexBuffer(7,bandup ,INDICATOR_DATA);
   SetIndexBuffer(8,banddn ,INDICATOR_DATA);
   
      //
      //
      //
      
      double _fast = MathMin(inpPeriodFast,inpPeriodSlow);
      double _slow = MathMax(inpPeriodFast,inpPeriodSlow);
               global.alphaFast = 2.0 / (1.0 + MathMax(_fast,1));
               global.alphaSlow = 2.0 / (1.0 + MathMax(_slow,1));
               global.periodSum = (int)MathMax(_fast,1);
               global.periodDiv =      MathMax(_fast,1);

      //
      //
      //
            
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double   &open[],
                const double   &high[],
                const double   &low[],
                const double   &close[],
                const long     &tick_volume[],
                const long     &volume[],
                const int &spread[])
{
   int _limit = (prev_calculated>0) ? prev_calculated-1 : 0;

   //
   //
   //

      struct sWorkStruct
            {
               double emaFast;
               double emaSlow;
               double emaDiff;
               double sumDiff;
               int    state;
            };   
      static sWorkStruct m_work[];
      static int         m_workSize = -1;
                     if (m_workSize<rates_total) m_workSize = ArrayResize(m_work,rates_total+500,2000);

      //
      //
      //

      for (int i=_limit; i<rates_total; i++)
         {
            double _price = iGetPrice(inpPrice,open,high,low,close,i);
               m_work[i].emaFast = (i>0) ? m_work[i-1].emaFast + global.alphaFast*(_price-m_work[i-1].emaFast) : _price;
               m_work[i].emaSlow = (i>0) ? m_work[i-1].emaSlow + global.alphaSlow*(_price-m_work[i-1].emaSlow) : _price;
               m_work[i].emaDiff = (m_work[i].emaFast-m_work[i].emaSlow)*(m_work[i].emaFast-m_work[i].emaSlow);
               if (i>global.periodSum)
                     { m_work[i].sumDiff = m_work[i-1].sumDiff + m_work[i].emaDiff - m_work[i-global.periodSum].emaDiff; }
               else  { m_work[i].sumDiff = m_work[i].emaDiff; for (int k=1; k<global.periodSum && i>=k; k++) m_work[i].sumDiff += m_work[i-k].emaDiff; }

            //
            //
            //

            double _dv         = m_work[i].sumDiff/global.periodDiv;
            double _deviation  = (_dv) ? MathSqrt(_dv) * inpBandMultiplier : 0;
               emaSlow[i] = m_work[i].emaSlow;
               emaFast[i] = m_work[i].emaFast;
               bandup[i]  = m_work[i].emaSlow + _deviation;
               banddn[i]  = m_work[i].emaSlow - _deviation;
               
               m_work[i].state = (emaFast[i]>bandup[i]) ? 1 : (emaFast[i]<banddn[i]) ? -1 : 0;
               
                  if (m_work[i].state!=0)
                     {
                        candleO[i] = open[i];
                        candleH[i] = high[i];
                        candleL[i] = low[i];
                        candleC[i] = close[i];
                        candlec[i] = m_work[i].state == 1 ?  1 : 2;
                     }
                  else 
                     {                        
                        candleO[i] =
                        candleH[i] =
                        candleL[i] =
                        candleC[i] = EMPTY_VALUE;
                        candlec[i] = 0;
                     }                        
         }

   //
   //
   //

   return(rates_total);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//

double iGetPrice(ENUM_APPLIED_PRICE price,const double& open[], const double& high[], const double& low[], const double& close[], int i)
{
   switch (price)
   {
      case PRICE_CLOSE:     return(close[i]);
      case PRICE_OPEN:      return(open[i]);
      case PRICE_HIGH:      return(high[i]);
      case PRICE_LOW:       return(low[i]);
      case PRICE_MEDIAN:    return((high[i]+low[i])/2.0);
      case PRICE_TYPICAL:   return((high[i]+low[i]+close[i])/3.0);
      case PRICE_WEIGHTED:  return((high[i]+low[i]+close[i]+close[i])/4.0);
   }
   return(0);
}
//+------------------------------------------------------------------------------------------------------------------+
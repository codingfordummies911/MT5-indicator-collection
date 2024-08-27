// More information about this indicator can be found at:
// http://fxcodebase.com/code/viewtopic.php?f=38&t=69358
// More information about this indicator can be found at:
//http://fxcodebase.com/code/viewtopic.php?f=38&t=69358

//+------------------------------------------------------------------+
//|                               Copyright © 2020, Gehtsoft USA LLC | 
//|                                            http://fxcodebase.com |
//+------------------------------------------------------------------+
//|                                      Developed by : Mario Jemic  |
//|                                          mario.jemic@gmail.com   |
//|                         https://AppliedMachineLearning.systems   |
//+------------------------------------------------------------------+
//|                                 Support our efforts by donating  |
//|                                  Paypal : https://goo.gl/9Rj74e  |
//+------------------------------------------------------------------+
//|                                Patreon :  https://goo.gl/GdXWeN  |
//|                    BitCoin : 15VCJTLaz12Amr7adHSBtL9v8XomURo9RF  |
//|               BitCoin Cash : 1BEtS465S3Su438Kc58h2sqvVvHK9Mijtg  |
//|           Ethereum : 0x8C110cD61538fb6d7A2B47858F0c0AaBd663068D  |
//|                   LiteCoin : LLU8PSY2vsq7B9kRELLZQcKf5nJQrdeqwD  |
//+------------------------------------------------------------------+

#property copyright "Copyright © 2020, Gehtsoft USA LLC"
#property link      "http://fxcodebase.com"
#property version   "1.0"
#property strict

input string   Comment1                 = "- Comma Separated Pairs - Ex: EURUSD,EURJPY,GBPUSD - ";
input string   Pairs                    = "EURUSD,EURJPY,USDJPY,GBPUSD";
input color button_with_trades_color = Green; // Color of button with trades
input ENUM_BASE_CORNER corner = CORNER_RIGHT_UPPER; // Corner
input int x_start = 50;
input int y_start = 20;
int button_width = 50;
int button_height = 20;

string IndicatorName;
string IndicatorObjPrefix;
string GenerateIndicatorName(const string target)
{
   string name = target;
   return name;
}

string _symbols[];
void split(string& arr[], string str, string sym) 
{
   ArrayResize(arr, 0);
   int len = StringLen(str);
   for (int i=0; i < len;)
   {
      int pos = StringFind(str, sym, i);
      if (pos == -1)
         pos = len;

      string item = StringSubstr(str, i, pos-i);
      StringTrimLeft(item);
      StringTrimRight(item);

      int size = ArraySize(arr);
      ArrayResize(arr, size+1);
      arr[size] = item;

      i = pos+1;
   }
}

int OnInit(void)
{
   IndicatorName = GenerateIndicatorName("Symbol Changer");
   IndicatorObjPrefix = "__" + IndicatorName + "__";
   IndicatorSetString(INDICATOR_SHORTNAME, IndicatorName);
   IndicatorSetInteger(INDICATOR_DIGITS, Digits());

   split(_symbols, Pairs, ",");

   DoInit();
   
   return INIT_SUCCEEDED;
}

void DoInit()
{
   guiCreate();
   guiRefresh();
}

void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, IndicatorObjPrefix);
}

int OnCalculate(const int rates_total,       // size of input time series
                const int prev_calculated,   // number of handled bars at the previous call
                const datetime& time[],      // Time array
                const double& open[],        // Open array
                const double& high[],        // High array
                const double& low[],         // Low array
                const double& close[],       // Close array
                const long& tick_volume[],   // Tick Volume array
                const long& volume[],        // Real Volume array
                const int& spread[]          // Spread array
)
{
   guiRefresh();

   return rates_total;
}

bool TradesExist(string symbol)
{
   for (int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if (PositionGetSymbol(i) == symbol)
      {
         return true;
      }
   }
   return false;
}

void guiRefresh() 
{
   for (int i = 0; i < ArraySize(_symbols); ++i)
   {
      string item = _symbols[i];
      if (_Symbol == item)
         ObjectSetInteger(0, IndicatorObjPrefix + "_BT_" + item, OBJPROP_STATE, true);
      else
         ObjectSetInteger(0, IndicatorObjPrefix + "_BT_" + item, OBJPROP_STATE, false);
      if (TradesExist(item))
      {
         ObjectSetInteger(0, IndicatorObjPrefix + "_BT_" + item, OBJPROP_BGCOLOR, button_with_trades_color);
      }
      else
      {
         ObjectSetInteger(0, IndicatorObjPrefix + "_BT_" + item, OBJPROP_BGCOLOR, clrLightGray);
      }
   }
}

void guiCreate() 
{
   for (int i = 0; i < ArraySize(_symbols); ++i)
   {
      string item = _symbols[i];
      ButtonCreate(IndicatorObjPrefix + "_BT_" + item, x_start + (button_width * i), y_start, button_width, button_height, item); 
   }
}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam
                 )
{
   if (id == CHARTEVENT_OBJECT_CLICK)
   {
      if (StringFind(sparam,"_BT_",0) != -1)
      {
         for (int i = 0; i < ArraySize(_symbols); ++i)
         {
            string item = _symbols[i];
            if (StringFind(sparam, item, 0) != -1)
            {
               ChartSetSymbolPeriod(0, item, _Period);
               return;
            }
         }
      }
   }     
}

bool ButtonCreate(const string name = "Button",            // button name
                         const int               x=10,                     // X coordinate
                         const int               y=10,                     // Y coordinate
                         const int               width=20,                 // button width
                         const int               height=20,                // button height
                         const string            text="",                  // text
                         const string            tooltip="\n",             // tooltip
                         const int               font_size=8,              // font size
                         const string            font="Arial",             // font
                         const color             clr=clrBlack,             // text color
                         const color             back_clr=clrLightGray     // background color
                         )
{
   ResetLastError();
   if(ObjectFind(0,name)>-1)  
      return(false); 

   if(!ObjectCreate(0,name,OBJ_BUTTON,0,0,0))
   {
      Print(__FUNCTION__,
            ": failed to create button! Error code = ",GetLastError());
      return(false);
   }
   ObjectCreate(0,name,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,height);
   ObjectSetInteger(0,name,OBJPROP_CORNER, corner);
   ObjectSetString(0,name,OBJPROP_FONT,font);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,font_size);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,back_clr);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_STATE,false);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,10);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,tooltip);
   return(true);
} 
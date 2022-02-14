//+------------------------------------------------------------------+
//|                                                         HiLo.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property description "HiLo"
#property version   "1.00"

#property indicator_chart_window
#property indicator_buffers 7
#property indicator_plots 1

#property indicator_label1 "Hilo"
#property indicator_type1 DRAW_COLOR_BARS
#property indicator_style1  STYLE_DASH
#property indicator_color1 clrGreen,clrRed
#property indicator_width1 1

input int HiloPeriod = 4; // Period

// indicators buffers
double OpenBuffer[], HighBuffer[], LowBuffer[], CloseBuffer[];
double HighMABuffer[], LowMABuffer[];

// color buffer
double ColorBuffer[];

//--- declaration of the integer variables for the start of data calculation
int  min_rates_total;

// handles
int HighMAHandle, LowMAHandle;

//--- Declaration of constants
#define RESET  0 // the constant for getting the command for the indicator recalculation back to the terminal

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- initialization of variables of the start of data calculation
   min_rates_total=HiloPeriod;

//--= get indicator handles
   HighMAHandle = iMA(NULL, 0, HiloPeriod, 0, MODE_SMA, PRICE_HIGH);
   if(HighMAHandle==INVALID_HANDLE)
      Print(" Failed to get handle of the high indicator");
   LowMAHandle = iMA(NULL, 0, HiloPeriod, 0, MODE_SMA, PRICE_LOW);
   if(LowMAHandle==INVALID_HANDLE)
      Print(" Failed to get handle of the low indicator");

//--- set the index for buffers
   SetIndexBuffer(0, OpenBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, HighBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, LowBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, CloseBuffer, INDICATOR_DATA);
   SetIndexBuffer(4, ColorBuffer, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(5, HighMABuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(6, LowMABuffer, INDICATOR_CALCULATIONS);

//--- set indicator digits
   IndicatorSetInteger(INDICATOR_DIGITS, 2);

//--- indexing elements in arrays as time series
   ArraySetAsSeries(OpenBuffer,true);
   ArraySetAsSeries(HighBuffer,true);
   ArraySetAsSeries(LowBuffer,true);
   ArraySetAsSeries(CloseBuffer,true);
   ArraySetAsSeries(ColorBuffer,true);
   ArraySetAsSeries(HighMABuffer,true);
   ArraySetAsSeries(LowMABuffer,true);

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
//--- declarations of local variables
   int limit, to_copy, bar, Hld = 0, Hlv = 0;

//--- calculations of the necessary amount of data to be copied
//--- and the 'limit' starting index for the bars recalculation loop
   if(prev_calculated>rates_total || prev_calculated<=0)// checking for the first start of the indicator calculation
     {
      limit=rates_total-min_rates_total-1; // starting index for calculation of all bars
     }
   else
     {
      limit=rates_total-prev_calculated; // starting index for calculation of new bars
     }

   to_copy=limit+1;

//--- copy newly appeared data in the arrays
   if(CopyBuffer(HighMAHandle, 0, 0, to_copy, HighMABuffer)<=0)
      return(RESET);
   if(CopyBuffer(LowMAHandle, 0, 0, to_copy, LowMABuffer)<=0)
      return(RESET);

//--- indexing elements in arrays as in timeseries
   ArraySetAsSeries(close,true);

//--- main indicator calculation loop
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      OpenBuffer[bar] = EMPTY_VALUE;
      HighBuffer[bar] = EMPTY_VALUE;
      LowBuffer[bar] = EMPTY_VALUE;
      CloseBuffer[bar] = EMPTY_VALUE;

      if(close[bar] > HighMABuffer[bar + 1])
        {
         Hld = 1;
        }
      else
        {
         if(close[bar] < LowMABuffer[bar + 1])
           {
            Hld = -1;
           }
         else
           {
            Hld = 0;
           }
        }

      if(Hld != 0)
         Hlv = Hld;

      if(Hlv == -1)
        {
         OpenBuffer[bar] = HighMABuffer[bar + 1];
         HighBuffer[bar] = HighMABuffer[bar + 1];
         LowBuffer[bar] = HighMABuffer[bar];
         CloseBuffer[bar] = HighMABuffer[bar];
         ColorBuffer[bar] = 1;
        }
      else
        {
         OpenBuffer[bar] = LowMABuffer[bar + 1];
         HighBuffer[bar] = LowMABuffer[bar];
         LowBuffer[bar] = LowMABuffer[bar + 1];
         CloseBuffer[bar] = LowMABuffer[bar];
         ColorBuffer[bar] = 0;
        }
     }
//--- Return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

  
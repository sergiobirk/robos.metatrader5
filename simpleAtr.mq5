//+------------------------------------------------------------------+
//|                                                    simpleAtr.mq5 |
//|                                           Copyright 2018, Daniel |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Daniel"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
//#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2
//--- plot DownTrend
#property indicator_label1  "DownTrend"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot UpTrend
#property indicator_label2  "UpTrend"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrGreen
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- input parameters
input int      PeriodAtr=14;           //ATR Period
input double      factor=2;               //Coeficient
//--- indicator buffers
double         DownTrendBuffer[];
double         UpTrendBuffer[];
//---global
int AtrHandle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,DownTrendBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,UpTrendBuffer,INDICATOR_DATA);

   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,PeriodAtr );
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,PeriodAtr );
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0 );
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0 );
   PlotIndexSetString(0,PLOT_LABEL,"Down Trend");
   PlotIndexSetString(1,PLOT_LABEL,"Up Trend");

   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   IndicatorSetString(INDICATOR_SHORTNAME,"Simple Stop ATR");

   AtrHandle=iATR(NULL,0,PeriodAtr);

   if(AtrHandle==INVALID_HANDLE)
     {
      Print(" Handle iATR is invalid ",GetLastError());
      return (INIT_FAILED);
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
   // Number of bars to calculate
   int begin=(prev_calculated<=0 || prev_calculated>rates_total) ?
             0 : prev_calculated-1;

   //The atr array size must be in accordance with number of bars
   //to calculate on each call
   double atr[];
   ArraySetAsSeries(atr,true);
   CopyBuffer(AtrHandle,0,0,rates_total-begin,atr); 

   for(int i=begin; i<rates_total;i++)
     {
      int forAsSeries=rates_total-1-i; //to access atr array

      if(i<PeriodAtr)                  //the first elements of array
        {                              //are initiate with zeros
         DownTrendBuffer[i]=0.0;
         UpTrendBuffer[i]=0.0;
         continue;
        }
      else if(i==PeriodAtr)            //after that, put the first values
        {
         DownTrendBuffer[i]=close[i]+atr[forAsSeries]*factor;
         UpTrendBuffer[i]=close[i]-atr[forAsSeries]*factor;
         continue;
        }

      //Values to atr stops
      double preDownTrend=close[i]+atr[forAsSeries]*factor;
      double preUpTrend=close[i]-atr[forAsSeries]*factor;

      if(close[i-1]>DownTrendBuffer[i-1]     
         && DownTrendBuffer[i -1]>0)
        {
         //Change to up trend
         DownTrendBuffer[i]=0.0;    
         UpTrendBuffer[i]=preUpTrend;
        }

      else if(close[i -1]<UpTrendBuffer[i -1]
         && UpTrendBuffer[i -1]>0)
         {
          //Change to down trend
          DownTrendBuffer[i]=preDownTrend;
          UpTrendBuffer[i]=0.0;
         }

      else
         {
          //Continue with trend activated
          //Once activated, DownTrend can't move up and UpTrend can't move down
          //and MathMin and MathMax solve this
          //Ternary operator ?: put indicator data if previous element is non zero
          DownTrendBuffer[i]=DownTrendBuffer[i -1]==0.0 ? 0.0 :
                             MathMin(preDownTrend,DownTrendBuffer[i -1]);
          UpTrendBuffer[i]=UpTrendBuffer[i-1]==0.0 ? 0.0 :
                           MathMax(preUpTrend,UpTrendBuffer[i-1]);
         }

     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

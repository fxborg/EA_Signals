//+------------------------------------------------------------------+
//|                                                      TrendMa.mq5 |
//|                                           Copyright 2015, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"

#include <MovingAverages.mqh>

#property indicator_chart_window

#property indicator_buffers 4
#property indicator_plots   1

#property indicator_type1 DRAW_COLOR_LINE
#property indicator_type2 DRAW_LINE
#property indicator_type3 DRAW_LINE

#property indicator_color1 clrRed,clrGainsboro,clrDodgerBlue
#property indicator_width1 3

#property indicator_color2 clrSilver
#property indicator_width2 1
#property indicator_style2 STYLE_DOT

#property indicator_color3 clrSilver
#property indicator_width3 1
#property indicator_style3 STYLE_DOT

input int InpMaPeriod=20;       // Ma Period
input ENUM_MA_METHOD InpMaMethod=MODE_EMA;       // Ma Method

int InpAtrPeriod=10;   // Calc Bar Count 
double InpThreshold=0.5;// Threshold Level

double MaBuffer[];
double UBBuffer[];
double DBBuffer[];
double ColorBuffer[];
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   min_rates_total=1;
//--- indicator buffers mapping
   SetIndexBuffer(0,MaBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,UBBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,DBBuffer,INDICATOR_DATA);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);

   string short_name="Moving Average Regr";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
//---

//---
   int i,first,begin_pos;
   begin_pos=min_rates_total;

   first=begin_pos;
   if(first+1<prev_calculated) first=prev_calculated-2;

//---
   for(i=first; i<rates_total && !IsStopped(); i++)
     {
      double prev_price=0;
      if(InpMaMethod==MODE_EMA || InpMaMethod==MODE_SMMA)
         prev_price=(MaBuffer[i-1]!=EMPTY_VALUE) ? MaBuffer[i-1]: price[i-1];

      switch(InpMaMethod)
        {
         //---
         case MODE_SMA: MaBuffer[i]=SimpleMA(i,InpMaPeriod,price); break;
         case MODE_EMA: MaBuffer[i]=ExponentialMA(i,InpMaPeriod,prev_price,price); break;
         case MODE_LWMA: MaBuffer[i]=LinearWeightedMA(i,InpMaPeriod,price); break;
         case MODE_SMMA: MaBuffer[i]=SmoothedMA(i,InpMaPeriod,prev_price,price);  break;
         default: MaBuffer[i]=SimpleMA(i,InpMaPeriod,price); break;
         //---
        }
      int i1st=begin_pos+InpAtrPeriod+InpAtrPeriod*7+5;
      if(i<=i1st)continue;
      double atr=0;
      for(int j=0;j<InpAtrPeriod*7;j++)
        {
         double atr1=0;
         for(int k=0;k<InpAtrPeriod;k++)
            atr1+=MathAbs(MaBuffer[(i-j)-k]-MaBuffer[(i-j)-k-1]);

         atr+=atr1/InpAtrPeriod;
        }
      atr/=InpAtrPeriod*7;
      double th=atr*InpThreshold;
      //---

      double sign=1;
      double ma=(MaBuffer[i-1]+MaBuffer[i-2]+MaBuffer[i-3])/3;
      //---
      if(MaBuffer[i]<=ma+th && MaBuffer[i]>=ma-th)sign=1;
      else if( MaBuffer[i]>ma)sign=2;
      else if( MaBuffer[i]<ma)sign=0;
      ColorBuffer[i]=sign;
      UBBuffer[i]=MaBuffer[i]+atr;
      DBBuffer[i]=MaBuffer[i]-atr;
     }
//---

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

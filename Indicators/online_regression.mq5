//+------------------------------------------------------------------+
//|                                           Online_Regression.mq5  |
//| Online Regression                         Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"
#include <online_regression.mqh>
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots 3

#property indicator_type1         DRAW_LINE
#property indicator_color1        clrBlue
#property indicator_width1 3

#property indicator_type2         DRAW_LINE
#property indicator_color2        clrLimeGreen
#property indicator_width2 3
#property indicator_type3         DRAW_LINE
#property indicator_color3        clrRed
#property indicator_width3 3
input double InpAlpha1=0.9; // Alpha1 
input double InpAlpha2=0.99; // Alpha2
double REG1[];
double REG2[];
double MOM[];


COnlineRegression OReg1;
COnlineRegression OReg2;
COnlineRegression OReg3;
int min_rates_total=5;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- 
   SetIndexBuffer(0,MOM,INDICATOR_DATA);
   SetIndexBuffer(1,REG1,INDICATOR_DATA);
   SetIndexBuffer(2,REG2,INDICATOR_DATA);
//--- 
   OReg1.Init(InpAlpha1); // initialize expert
   OReg2.Init(InpAlpha2); // initialize expert

//---
   return(0);
  }

void OnDeinit(const int reason)
{
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
   int i,first;
   if(rates_total<=min_rates_total) return(0);
//---
   int begin_pos=min_rates_total;

   first=begin_pos;
   if(first+1<prev_calculated) first=prev_calculated-2;
//---
   for(i=first; i<rates_total && !IsStopped(); i++)
     {
      REG1[i]=EMPTY_VALUE;
      REG2[i]=EMPTY_VALUE;
      double mom=close[i]-close[i-1];
      double beta,intersept;
      OReg1.Push(mom,begin_pos,rates_total,i,intersept,beta);
      REG1[i] =  intersept;
      OReg2.Push(mom,begin_pos,rates_total,i,intersept,beta);
      REG2[i] = intersept ;
      MOM[i]=mom;
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

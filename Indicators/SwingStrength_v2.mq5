//+------------------------------------------------------------------+
//|                                               Swing Strength.mq5 |
//| Swing Strength v2.0                      Copyright 2015, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "2.0"
#include <MovingAverages.mqh>

#property indicator_separate_window
#property indicator_buffers 12
#property indicator_plots   1

#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  Red,Gray,DodgerBlue
#property indicator_type2   DRAW_FILLING
#property indicator_color2  DarkSlateGray
#property indicator_width1 2
//--- input parameters
input int Inp1stPeriod=7; // 1st Period 
input int Inp2ndPeriod=21;// 2nd Period 
input int InpSMoothing=2;// Smoothing Period 
int InpAtrPeriod=100; // SATR
double InpThreshold=0.05;// Threshold Level
double  tema_alpha = 2.0 /(1.0 + InpAtrPeriod);


int InpThresholdPeriod=100;// ThreshHold Period 
//---- will be used as indicator buffers
double EMA1[];
double EMA2[];
double EMA3[];
double TEMA[];
double TR[];
double ATR[];
double UpBuffer[];
double DnBuffer[];
double RawBuffer[];
double SmoothBuffer[];
double MainBuffer[];
double ColorBuffer[];
double SigBuffer[];
double SlowBuffer[];
//---- declaration of global variables
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Initialization of variables of data calculation starting point
   min_rates_total=Inp1stPeriod+Inp2ndPeriod;
//--- indicator buffers mapping
   int i=0;
   SetIndexBuffer(i++,MainBuffer,INDICATOR_DATA);
   SetIndexBuffer(i++,ColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(i++,SlowBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,SigBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,RawBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,SmoothBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,ATR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,TEMA,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,TR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,EMA1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,EMA2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,EMA3,INDICATOR_CALCULATIONS);

//---

//---
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---

   string short_name="Swing Strength v2.00";

   IndicatorSetString(INDICATOR_SHORTNAME,short_name);

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
   int i,first;
   if(rates_total<=min_rates_total)
      return(0);
//---

//+----------------------------------------------------+
//|Set Median Buffeer                                |
//+----------------------------------------------------+
   int begin_pos=min_rates_total;

   first=begin_pos;
   if(first+1<prev_calculated) first=prev_calculated-2;

//---
   for(i=first; i<rates_total && !IsStopped(); i++)
     {
      SmoothBuffer[i]=0;
      TR[i]=(MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]));
      int i1st=begin_pos+10;
      if(i<=i1st)continue;
      double maH=(high[i-2] +close[i-2] + high[i-1] +close[i-1])/4;
      double maL=( low[i-2] +close[i-2] +  low[i-1] +close[i-1])/4;
      //---
      double dup=MathMax(0,   (  (high[i] + close[i])/2  - maL)  );
      double ddn=MathMax(0,   (maH -(low[i]+close[i ])/2      )  );      
      if((dup+ddn)==0)
         SigBuffer[i] =0;
      else
         SigBuffer[i] = (dup-ddn)*MathAbs((dup-ddn)/(dup+ddn));
      
      int i2nd=i1st+MathMax(Inp1stPeriod,Inp2ndPeriod);
      if(i<=i2nd) continue;
      double sig1=0.0;
      double sig2=0.0;
      for(int j=0; j<Inp1stPeriod; j++) sig1+=SigBuffer[i-j];
      for(int j=0; j<Inp2ndPeriod; j++) sig2+=SigBuffer[i-j];
      sig1/=Inp1stPeriod;
      sig2/=Inp2ndPeriod;
      RawBuffer[i]=(sig1+sig2)/2;

      //--- ATR     
      if(i<=i2nd+1)continue;
      EMA1[i] = EMA1[i-1]+tema_alpha*(TR[i]-EMA1[i-1]);     
      if(i<=i2nd+2)continue;
      EMA2[i] = EMA2[i-1]+tema_alpha*(EMA1[i]-EMA2[i-1]);     
      if(i<=i2nd+3)continue;
      EMA3[i] = EMA3[i-1]+tema_alpha*(EMA2[i]-EMA3[i-1]);     
      TEMA[i]=(3.0*EMA1[i] - 3.0*EMA2[i] + EMA3[i]);
      //---
      int i3rd=i2nd+4+InpAtrPeriod;
      if(i<=i3rd)continue;
      if(i==i3rd+1)
         {
         double atr=0;
         for(int j=0;j<InpAtrPeriod;j++) atr+=TEMA[i-j];
         ATR[i] = atr/InpAtrPeriod;
         }
      else
      {    
         ATR[i] = ATR[i-1]+ (TEMA[i]-TEMA[i-InpAtrPeriod])/InpAtrPeriod;
      }

      //---
      int i4th=i3rd+InpSMoothing*3;
      if(i<=i4th) continue;

      double avg2=0;
      for(int j=0;j<InpSMoothing;j++) 
        {
        int ii=i-j;
        double avg1=0;
        for(int k=0;k<InpSMoothing;k++)
          {
           int iii=ii-k;
           double avg0=0;
           for(int l=0;l<InpSMoothing;l++) avg0+=RawBuffer[iii-l];
           avg1 += avg0/InpSMoothing;
          }              
        avg2 += avg1/InpSMoothing;
        }
      SmoothBuffer[i]=(avg2/InpSMoothing); 
      MainBuffer[i]=SmoothBuffer[i]/(2*ATR[i]);
      int i5th=i4th+4;
      if(i<=i5th) continue;

      double th=ATR[i]*InpThreshold;
      //---
  
      double sign=1;
      double ma=(SmoothBuffer[i-1]+SmoothBuffer[i-2]+SmoothBuffer[i-3])/3;
      //---
      if(SmoothBuffer[i]<=ma+th && SmoothBuffer[i]>=ma-th)sign=1;
      else if( SmoothBuffer[i]>ma)sign=2;
      else if( SmoothBuffer[i]<ma)sign=0;      
      ColorBuffer[i]=sign;

     }

//----    

   return(rates_total);
  }
//+------------------------------------------------------------------+

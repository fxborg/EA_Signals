//+------------------------------------------------------------------+
//|                                                RSI_ZONE.mq5      |
//| RSI_ZONE                                  Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.01"
#include <MovingAverages.mqh>
#property indicator_separate_window
const double PI=3.14159265359;
double SQ2=sqrt(2);

#property indicator_levelcolor Silver

#property indicator_buffers 11
#property indicator_plots 4


#property indicator_type1         DRAW_LINE
#property indicator_color1        clrRed
#property indicator_width1 2

#property indicator_type2         DRAW_LINE
#property indicator_color2        clrSilver
#property indicator_width2 1
#property indicator_style2 STYLE_DOT

#property indicator_type3         DRAW_LINE 
#property indicator_color3        clrSilver
#property indicator_width3 1
#property indicator_style3 STYLE_DOT
#property indicator_type4         DRAW_LINE 
#property indicator_color4        clrGold
#property indicator_width4 1
#property indicator_style4 STYLE_DOT






input int InpRSIPeriod=20; // RSIPeriod
input int InpHistPeriod=80; // Histogram Period
input int InpSmoothing=20; // Smoothing



double L1[];
double H1[];
double L2[];
double H2[];
double MID1[];
double MID2[];
double MAIN[];
double OSC[];
double POS[];
double NEG[];

int min_rates_total=InpRSIPeriod;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

//--- 
//---
   int i=0;
   SetIndexBuffer(i++,MAIN,INDICATOR_DATA);
   SetIndexBuffer(i++,H2,INDICATOR_DATA);
   SetIndexBuffer(i++,L2,INDICATOR_DATA);
   SetIndexBuffer(i++,MID2,INDICATOR_DATA);
   SetIndexBuffer(i,POS,INDICATOR_CALCULATIONS);
   PlotIndexSetDouble(i++,PLOT_EMPTY_VALUE,0);
   SetIndexBuffer(i,NEG,INDICATOR_CALCULATIONS);
   PlotIndexSetDouble(i++,PLOT_EMPTY_VALUE,0);
   SetIndexBuffer(i++,OSC,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,H1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,L1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,MID1,INDICATOR_CALCULATIONS);

///  --- 
//--- digits
   IndicatorSetInteger(INDICATOR_DIGITS,2);
   return(0);
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
      double diff;
      double pos=0;
      double neg=0;
      if(i==begin_pos)
        {
         for(int j=0;j<InpRSIPeriod;j++)
           {
            diff=close[i-j]-close[i-j-1];
            if(diff==0)continue;
            if(diff>0) pos+=diff;
            if(diff<0) neg-=diff;
           }

         POS[i]=pos/InpRSIPeriod;
         NEG[i]=neg/InpRSIPeriod;
         continue;
        }
      diff=close[i]-close[i-1];
      if(diff>0) pos+=diff;
      if(diff<0) neg-=diff;

      POS[i]=(POS[i-1]*(InpRSIPeriod-1) + pos)/InpRSIPeriod;
      NEG[i]=(NEG[i-1]*(InpRSIPeriod-1) + neg)/InpRSIPeriod;

      if(NEG[i]!=0.0 && NEG[i]!=EMPTY_VALUE)
         OSC[i]=50-50/(1+POS[i]/NEG[i]);
      else
      if(POS[i]!=0.0)
                 OSC[i]=100.0;
      else
         OSC[i]=50.0;

      int i1st=begin_pos+2;
      if(i<=i1st)continue;

      double a1,b1,c2,c3,c1;

      // SuperSmoother Filter
      a1 = MathExp( -SQ2  * PI / InpSmoothing );
      b1 = 2 * a1 * MathCos( SQ2 *PI / InpSmoothing );
      c2 = b1;
      c3 = -a1 * a1;
      c1 = 1 - c2 - c3;
      MAIN[i]=c1 *(OSC[i]+OSC[i-1])/2+c2*MAIN[i-1]+c3*MAIN[i-2];

      int i2nd=i1st+InpHistPeriod+1;
      if(i<=i2nd)continue;
      int hist[100];
      ArrayFill(hist,0,100,0);
      int total=calcHistogram(hist,OSC,i,InpHistPeriod);
      int peak=ArrayMaximum(hist);
      calcRange(L1[i],H1[i],hist,peak,0.2*total);
      MID1[i]=peak+0.5;

      int i3rd=i2nd+InpSmoothing+1;
      if(i<=i3rd)continue;
      L2[i]=LinearWeightedMA(i,InpSmoothing/2,L1);
      H2[i]=LinearWeightedMA(i,InpSmoothing/2,H1);
      MID2[i]=LinearWeightedMA(i,InpSmoothing/2,MID1);

     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

int calcHistogram(int &hist[],const double  &osc[],const int i,const int len)
  {
   int wcnt=len;
   
   for(int j=0;j<len;j++)
     {
      double dmin=MathMin(osc[i-j],osc[i-j-1]);
      double dmax=MathMax(osc[i-j],osc[i-j-1]);
      int w=MathMax(1,wcnt);
      int from_p=MathMax(0,int(dmin));
      int to_p=MathMin(100,int(dmax+1));
      for(int p=from_p;p<to_p;p++)
        {
         if(dmin<((p+1)) && (p)<=dmax) hist[p]+=w;
        }
      wcnt--;
     }
   int total=0;
   for(int p=0;p<100;p++)
     {
      total+=hist[p];
     }
   return total;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calcRange(double &dmin,double &dmax,const int  &hist[],const int peak,const double lmt)
  {
   int lo=0;
   int lo_cut=0;
   int hi=99;
   int hi_cut=0;
   for(int p=0;p<peak;p++)
     {
      if(lo_cut+hist[p]>=lmt)break;
      lo_cut+=hist[p];
      lo=p;
     }
   for(int p=99;p>peak;p--)
     {
      if(hi_cut+hist[p]>=lmt)break;
      hi_cut+=hist[p];
      hi=p;
     }

   dmin=lo+0.5;
   dmax=hi+0.5;
  }
//+------------------------------------------------------------------+

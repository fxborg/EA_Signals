//+------------------------------------------------------------------+
//|                                         LogicalStops.mq5 |
//|                                           Copyright 2015, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"

#include <MovingAverages.mqh>

#property indicator_chart_window

#property indicator_buffers 12
#property indicator_plots   4
#property indicator_type1   DRAW_COLOR_ARROW
#property indicator_type2   DRAW_COLOR_ARROW
#property indicator_type3 DRAW_LINE
#property indicator_type4 DRAW_LINE
#property indicator_type5 DRAW_LINE
#property indicator_type6 DRAW_LINE

#property indicator_color1  clrNONE,clrRed,clrGold,clrDodgerBlue,clrGreen,clrPink
#property indicator_width1  2

#property indicator_color2  clrNONE,clrRed,clrGold,clrDodgerBlue,clrGreen,clrPink
#property indicator_width2  2


#property indicator_color3 clrRed
#property indicator_width3 2

#property indicator_color4 clrDodgerBlue
#property indicator_width4 2


input int InpMaPeriod=12;         // Ma Period
input int InpChannelPeriod=2;     // Channel Period
input bool InpShowArrow=false;    // Show Arrow
int HiLoPeriod=4;
double MaBuffer[];
double BodyBuffer[];
double UpChBuffer[];
double DnChBuffer[];

double HighBuffer[];
double LowBuffer[];
double UpperBuffer[];
double LowerBuffer[];
double HSignBuffer[];
double LSignBuffer[];
double HColorBuffer[];
double LColorBuffer[];

int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   min_rates_total=HiLoPeriod+InpMaPeriod;
//--- indicator buffers mapping
   SetIndexBuffer(0,HSignBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,HColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,LSignBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,LColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(4,UpChBuffer,INDICATOR_DATA);
   SetIndexBuffer(5,DnChBuffer,INDICATOR_DATA);
   SetIndexBuffer(6,HighBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,LowBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,MaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,BodyBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,UpperBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,LowerBuffer,INDICATOR_CALCULATIONS);

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(7,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(8,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(9,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(10,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(11,PLOT_EMPTY_VALUE,0);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);

   string short_name="Logical Stops";
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

//---
   int i,first,begin_pos;
   begin_pos=min_rates_total;

   first=begin_pos;
   if(first+1<prev_calculated) first=prev_calculated-2;

//---
   for(i=first; i<rates_total && !IsStopped(); i++)
     {
      UpChBuffer[i]=0;
      DnChBuffer[i]=0;
      MaBuffer[i]=SimpleMA(i,InpMaPeriod,close);
      double avg=0;
      for(int j=0;j<InpMaPeriod;j++) avg+=MathAbs(close[i-j]-open[i-j]);
      BodyBuffer[i]=avg/InpMaPeriod;

      int i1st=begin_pos+InpMaPeriod+HiLoPeriod;
      if(i<=i1st)continue;
      bool up_done=false;
      bool dn_done=false;

      int imax=ArrayMaximum(high,i-3,4);
      int imin=ArrayMinimum(low,i-3,4);
      if(imax==i || imin==i)
        {
         //Pin Bar
         int pinbar=chkPinBar(open[i],high[i],low[i],close[i],BodyBuffer[i-1]);
         if(pinbar==1)
           {
            HighBuffer[i]=high[i];
            if(InpShowArrow)
              {
               HSignBuffer[i]=high[i];
               HColorBuffer[i]=1;
              }
            up_done=true;
           }
         if(pinbar==-1)
           {
            LowBuffer[i]=low[i];
            if(InpShowArrow)
              {
               LSignBuffer[i]=low[i];
               LColorBuffer[i]=1;
              }
            dn_done=true;
           }

         if(!up_done && !dn_done)
           {
            int rev=chkReversal(open,high,low,close,i,BodyBuffer[i],MaBuffer[i-1]);
            if(rev==1)
              {
               HighBuffer[i]=high[i];
               if(InpShowArrow)
                 {
                  HSignBuffer[i]=high[i];
                  HColorBuffer[i]=2;
                 }
               up_done=true;

              }
            else if(rev==-1)
              {
               LowBuffer[i]=low[i];
               if(InpShowArrow)
                 {
                  LSignBuffer[i]=low[i];
                  LColorBuffer[i]=2;
                 }
               dn_done=true;
              }
           }
        }

      if(!dn_done)
        {
         if((close[i]-open[i])>BodyBuffer[i-1]*3 && low[i-1]<low[i])
           {

            LowBuffer[i]=low[i];
            if(InpShowArrow)
              {
               LSignBuffer[i]=low[i];
               LColorBuffer[i]=3;
              }
            dn_done=true;
           }
         else if((close[i]-close[i-2])>BodyBuffer[i-1]*1.5 && low[i-2]<low[i-1] && low[i-1]<low[i])
           {

            LowBuffer[i]=low[i-1];
            if(InpShowArrow)
              {
               LSignBuffer[i]=low[i-1];
               LColorBuffer[i]=3;
              }
            dn_done=true;
           }
        }

      if(!up_done)
        {
         if((open[i]-close[i])>BodyBuffer[i-1]*3 && high[i-1]>high[i])
           {
            HighBuffer[i]=high[i];
            if(InpShowArrow)
              {
               HSignBuffer[i]=high[i];
               HColorBuffer[i]=3;
              }
            up_done=true;
           }
         else if((close[i-2]-close[i])>BodyBuffer[i-1]*1.5 && high[i-2]>high[i-1] && high[i-1]>high[i])
           {
            HighBuffer[i]=high[i-1];
            if(InpShowArrow)
              {
               HSignBuffer[i]=high[i-1];
               HColorBuffer[i]=3;
              }
            up_done=true;
           }
        }

      double prev_h=MathMax(high[i-3],high[i-2]);
      double prev_l=MathMin(low[i-3],low[i-2]);

      if(!up_done || !dn_done)
        {
         // in side bar brake
         int brakeout=chkBrakeOut(high,low,close,i);
         if(!dn_done && brakeout==1)
           {
            LowBuffer[i]=(prev_h+prev_l)*0.5;
            if(InpShowArrow)
              {
               LSignBuffer[i]=LowBuffer[i];
               LColorBuffer[i]=3;
              }
            dn_done=true;

           }
         else if(!up_done && brakeout==-1)
           {
            HighBuffer[i]=(prev_h+prev_l)*0.5;
            if(InpShowArrow)
              {
               HSignBuffer[i]=HighBuffer[i];
               HColorBuffer[i]=3;
              }
            up_done=true;

           }

        }

      if(!up_done || !dn_done)
        {
         if(chkInSide(high,low,i,BodyBuffer[i-1]))
           {
            if(!up_done)
              {
               HighBuffer[i]=high[i-1];
               if(InpShowArrow)
                 {
                  HSignBuffer[i]=high[i-1];
                  HColorBuffer[i]=4;
                 }
               up_done=true;
              }
            if(!dn_done)
              {
               LowBuffer[i]=low[i-1];
               if(InpShowArrow)
                 {
                  LSignBuffer[i]=low[i-1];
                  LColorBuffer[i]=4;
                 }
               dn_done=true;
              }
           }
        }

      if(!dn_done)
        {
         LowBuffer[i]=LowBuffer[i-1];
        }

      if(!up_done)
        {
         HighBuffer[i]=HighBuffer[i-1];
        }

      int i2nd=i1st+InpChannelPeriod;
      if(i<=i2nd)continue;
      double dmax=-999999999;
      double dmin= 999999999;
      for(int j=0;j<InpChannelPeriod;j++)
        {
         if(dmax<HighBuffer[i-j] && HighBuffer[i-j]!=0)dmax=HighBuffer[i-j];
         if(dmin>LowBuffer[i-j] && LowBuffer[i-j]!=0)dmin=LowBuffer[i-j];
        }

      UpperBuffer[i]=(dmax==-999999999 || dmax==0)?UpperBuffer[i-1]:dmax;
      LowerBuffer[i]=(dmin==999999999||dmin==0)?LowerBuffer[i-1]:dmin;
      if(UpperBuffer[i-1]>=UpperBuffer[i]) UpChBuffer[i]=UpperBuffer[i];
      if(LowerBuffer[i-1]<=LowerBuffer[i])DnChBuffer[i]=LowerBuffer[i];
     }
//---

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

int chkPinBar(double o,double h,double l,double c,double avgBody1)
  {
   double body=NormalizeDouble((h-l)*0.4,Digits());
   double spread=h-l;
   if(spread<avgBody1 * 3)return (0);

//--- Bearish Pin Bar
   double tail=h-MathMax(o,c);
   double not_tail=MathMax((spread-tail),_Point);
   if(tail/not_tail > 1.3 && o >c-body*0.1 && c <=(l + (h-l)*0.3)) return (1);
   if(tail/not_tail > 1.1 && (o-c)>body*0.5 && c <=(l + (h-l)*0.6)) return (1);
   if(tail/not_tail > 1.3 && MathMax(o,c) <=(l + (h-l)*0.2)) return (1);


//--- Bullish Pin Bar
   tail=MathMin(o,c)-l;
   not_tail=MathMax((spread-tail),_Point);
   if(tail/not_tail > 1.3 && o<c+body*0.1 && c >=(h - (h-l)*0.3)) return (-1);
   if(tail/not_tail > 1.1 && (c-o)>body*0.5 && c >=(h - (h-l)*0.6)) return (-1);
   if(tail/not_tail > 1.3 && MathMin(o,c) >=(h - (h-l)*0.6)) return (-1);

   return (0);
  }
//+------------------------------------------------------------------+
int chkReversal(const double &o[],const double &h[],const double &l[],const double &c[],const int i,double avgBody1,double ma2)
  {

   if(h[i-2]<MathMin(h[i],h[i-1]) && 
      o[i-1]<c[i-1] && 
      o[i]>c[i] && 
      c[i-1]>ma2 && 
      MathMax(c[i-1]-o[i-1],o[i]-c[i])>avgBody1)
      return(1);

   if(l[i-2]>MathMax(l[i],l[i-1]) && 
      o[i-1]>c[i-1] && 
      o[i]<c[i] && 
      c[i-1]<ma2 && 
      MathMax(c[i]-o[i],o[i-1]-c[i-1])>avgBody1)
      return(-1);

   if(o[i]>c[i] && 
      c[i-1]>ma2 && 
      o[i]-c[i]>avgBody1*2)
      return(1);

   if(o[i]<c[i] && 
      c[i-1]<ma2 && 
      c[i]-o[i]>avgBody1*2)
      return(-1);

   if((o[i]+c[i])*0.5>ma2 && o[i]>c[i] && (h[i]-c[i])>avgBody1*0.5)
     {
      if(MathAbs(h[i]-h[i-1])<avgBody1*0.2)return 1;
      if(MathAbs(h[i]-h[i-2])<avgBody1*0.2)return 1;
      if(MathAbs(h[i]-h[i-3])<avgBody1*0.2)return 1;
     }

   if((o[i]+c[i])*0.5<ma2 && o[i]<c[i] && (c[i]-l[i])>avgBody1*0.5)
     {
      if(MathAbs(l[i]-l[i-1])<avgBody1*0.2)return -1;
      if(MathAbs(l[i]-l[i-2])<avgBody1*0.2)return -1;
      if(MathAbs(l[i]-l[i-3])<avgBody1*0.2)return -1;
     }

   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool chkInSide(const double &h[],const double &l[],const int i,const double avgBoby)
  {

   if(h[i]<h[i-1] && l[i]>l[i-1] && (h[i-1]-l[i-1])>avgBoby*1.5)
      return true;
   else
      return false;


  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int chkBrakeOut(const double &h[],const double &l[],const double &c[],const int i)
  {

   double prev_h;
   double prev_l;
   if(h[i-3]>=h[i-2] && l[i-3]<=l[i-2])
     {
      prev_h=h[i-3];
      prev_l=l[i-3];
     }
   else if(h[i-2]>h[i-3] && l[i-2]<l[i-3])
     {
      prev_h=h[i-2];
      prev_l=l[i-2];
     }
   else

      return 0;

   double mini=(prev_h-prev_l)*0.25;
   double mid=(prev_h+prev_l)*0.5;
   if(prev_l<l[i-1] && mid<l[i] &&  prev_h+mini<c[i])return 1;
   if(prev_h>h[i-1] && mid>h[i] &&  prev_l-mini>c[i])return -1;
   return 0;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                Boundary_line.mq5 |
//| Boundary Line v1.00                       Copyright 2015, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.04"

#include <MovingAverages.mqh>

#property indicator_buffers 12
#property indicator_plots   2

#property indicator_separate_window
#property indicator_type1 DRAW_LINE
#property indicator_type2 DRAW_COLOR_HISTOGRAM

#property indicator_color1 DimGray
#property indicator_label1 "CCI"
#property indicator_width1 1
#property indicator_style1 STYLE_SOLID
#property indicator_color2 DarkGray,DodgerBlue,DeepPink
#property indicator_label2 "CCI"
#property indicator_width2 2
#property indicator_style2 STYLE_SOLID

//--- input parameters
input double InpScaleFactor=2.25; // Scale factor
input int    InpMaPeriod=3;       // Smooth Period
input int    InpVolatilityPeriod=70; //  Volatility Period
input int InpCCIPeriod=32; // CCI Period

ENUM_APPLIED_PRICE InpAppliedPrice = PRICE_TYPICAL; // CCI Applied Price 


//---
int    InpFastPeriod=int(InpVolatilityPeriod/7); //  Fast Period
//---


//---- will be used as indicator buffers
double CCI_Buffer[];
double CCI_Hist_Buffer[];
double CCI_Color_Buffer[];
double MainBuffer[];
double MiddleBuffer[];
double HighBuffer[];
double LowBuffer[];
double CloseBuffer[];
double VolatBuffer[];
double VolatMaBuffer[];
double SmMaBuffer[];
double PriceBuffer[];
//---- declaration of global variables
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Initialization of variables of data calculation starting point
   min_rates_total=1+InpFastPeriod+InpVolatilityPeriod+InpMaPeriod+InpMaPeriod+1;
//--- indicator buffers mapping

//--- indicator buffers
   SetIndexBuffer(0,CCI_Buffer);
   SetIndexBuffer(1,CCI_Hist_Buffer);
   SetIndexBuffer(2,CCI_Color_Buffer);
   SetIndexBuffer(3,MainBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,MiddleBuffer,INDICATOR_DATA);
   SetIndexBuffer(5,SmMaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,HighBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,LowBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,CloseBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,VolatBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,VolatMaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,PriceBuffer,INDICATOR_CALCULATIONS);

//---
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
//---

   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---
   string short_name="CCI on Step Channel";

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
        switch(InpAppliedPrice)
        {
         //---
         case PRICE_CLOSE: PriceBuffer[i]=close[i]; break;
         case PRICE_HIGH: PriceBuffer[i]=high[i]; break;
         case PRICE_LOW: PriceBuffer[i]=low[i]; break;
         case PRICE_MEDIAN: PriceBuffer[i]=(high[i]+low[i])/2; break;
         case PRICE_OPEN: PriceBuffer[i]=open[i]; break;
         case PRICE_TYPICAL: PriceBuffer[i]=(high[i]+low[i]+close[i])/3; break;
         case PRICE_WEIGHTED: PriceBuffer[i]=(high[i]+low[i]+close[i]*2)/4; break;
         default : PriceBuffer[i]=close[i]; break;
         //---
        }

     
      int i1st=begin_pos+InpMaPeriod+InpFastPeriod+1;
      if(i<=i1st)continue;
      //---
      double h,l,c;
      //---
      h=SimpleMA(i,InpMaPeriod,high);
      l=SimpleMA(i,InpMaPeriod,low);
      c=SimpleMA(i,InpMaPeriod,close);
      //---
      double prev_ma=(SmMaBuffer[i-1]==0)? SimpleMA(i-1,InpFastPeriod,close):SmMaBuffer[i-1];
      SmMaBuffer[i]=SmoothedMA(i,InpFastPeriod,prev_ma,close);
      //---
      int i2nd=i1st+InpFastPeriod+1;
      if(i<=i2nd)continue;
      //---
      double sum=0.0;
      for(int j=0;j<InpFastPeriod;j++)
         sum+=MathPow(close[i-j]-SmMaBuffer[i],2);
      VolatBuffer[i]=MathSqrt(sum/InpFastPeriod);
      //---
      int i3rd=i2nd+InpVolatilityPeriod+1;
      if(i<=i3rd)continue;
      VolatMaBuffer[i]=SimpleMA(i,InpVolatilityPeriod,VolatBuffer);
      //---
      double v=VolatMaBuffer[i];
      double base=v*InpScaleFactor;
      //--- high
      if((h-base)>HighBuffer[i-1]) HighBuffer[i]=h;
      else if(h+base<HighBuffer[i-1]) HighBuffer[i]=h+base;
      else HighBuffer[i]=HighBuffer[i-1];
      //--- low
      if(l+base<LowBuffer[i-1]) LowBuffer[i]=l;
      else if((l-base)>LowBuffer[i-1]) LowBuffer[i]=l-base;
      else LowBuffer[i]=LowBuffer[i-1];
      //--- middle
      if((c-base/2)>CloseBuffer[i-1]) CloseBuffer[i]=c-base/2;
      else if(c+base/2<CloseBuffer[i-1]) CloseBuffer[i]=c+base/2;
      else CloseBuffer[i]=CloseBuffer[i-1];
      //---
      MiddleBuffer[i]=(HighBuffer[i]+LowBuffer[i]+CloseBuffer[i]*2)/4;
      int i4th=i3rd+InpMaPeriod+1;
      if(i<=i4th)continue;
      //---
      MainBuffer[i]=SimpleMA(i,InpMaPeriod,MiddleBuffer);

      //---
      int i5th=i4th+InpCCIPeriod;
      if(i<=i5th)continue;
      //---
      calc_CCI(MainBuffer,PriceBuffer,InpCCIPeriod, i);

     }
//----    

   return(rates_total);
  }
//+------------------------------------------------------------------+

void calc_CCI(const double  &ma[],const double &p[],const int span,const int i)
  {
   int j;
   
   double sum=0;
   for(j=0;j<span;j++) sum+=MathAbs(p[i-j]-ma[i]);
   
   sum*=0.015/span;
   
   CCI_Buffer[i]=(sum!=0.0) ? (p[i]-ma[i])/sum :0.0;
   CCI_Hist_Buffer[i]=CCI_Buffer[i];
   CCI_Color_Buffer[i]=(0<=CCI_Buffer[i]) ? 1.0 :2.0;
  }
//+------------------------------------------------------------------+

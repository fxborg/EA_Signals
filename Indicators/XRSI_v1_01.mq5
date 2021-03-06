//+------------------------------------------------------------------+
//|                                                  XRSI_v1_01.mq5  |
//| XRSI_v1_01                                Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.01"
#property indicator_separate_window
#property indicator_levelcolor Silver

#property indicator_minimum -20
#property indicator_maximum 120

#property indicator_level1 100.0
#property indicator_level2 50.0

#property indicator_buffers 13
#property indicator_plots 1

#property indicator_type1         DRAW_COLOR_LINE
#property indicator_color1        clrRed,clrSilver,clrDodgerBlue
#property indicator_width1 2

#property indicator_type2         DRAW_LINE
#property indicator_color2        clrRed
#property indicator_width2 1
#property indicator_style2        STYLE_SOLID

#property indicator_type3         DRAW_LINE
#property indicator_color3        clrDodgerBlue
#property indicator_width3 1
#property indicator_style3        STYLE_SOLID


input int InpRSIPeriod=20;// RSI Period
input int InpTemaPeriod=50;// Tema Period
input int InpThreshold=0; //Threshold
double MAIN[];
double SIG[];
double TOP[];
double BTM[];

double OSC[];
double POS[];
double NEG[];
double SPOS[];
double SNEG[];

double EMA1[];
double EMA2[];
double EMA3[];
double EMA4[];
double EMA5[];
double TEMA[];

int min_rates_total=10;
// SuperSmoother Filter
double SQ2=sqrt(2);
double A1 = MathExp( -SQ2  * M_PI / InpRSIPeriod );
double B1 = 2 * A1 * MathCos( SQ2 *M_PI / InpRSIPeriod );
double C2 = B1;
double C3 = -A1 * A1;
double C1 = 1 - C2 - C3;

//--- Tema factor
double  tema_alpha=2.0/(1.0+InpTemaPeriod);
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

//--- 
//---
   int i=0;
   SetIndexBuffer(i++,MAIN,INDICATOR_DATA);
   SetIndexBuffer(i++,SIG,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(i++,TOP,INDICATOR_DATA);
   SetIndexBuffer(i++,BTM,INDICATOR_DATA);
   SetIndexBuffer(i++,TEMA,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,OSC,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,POS,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,NEG,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,SPOS,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,SNEG,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,EMA1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,EMA2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,EMA3,INDICATOR_CALCULATIONS);
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
      //---
      EMA1[i]=close[i];
      EMA2[i]=close[i];
      EMA3[i]=close[i];
      TEMA[i]=close[i];
      //---

      POS[i]=0;
      NEG[i]=0;

      if(i<=begin_pos+1)continue;
      EMA1[i]=EMA1[i-1]+tema_alpha*(close[i]-EMA1[i-1]);
      EMA2[i]=EMA2[i-1]+tema_alpha*(EMA1[i]-EMA2[i-1]);
      EMA3[i]=EMA3[i-1]+tema_alpha*(EMA2[i]-EMA3[i-1]);
      TEMA[i]=(3.0*EMA1[i]-3.0*EMA2[i]+EMA3[i]);

      SPOS[i]=0;
      SNEG[i]=0;
      int i1st=begin_pos+6;
      if(i<=i1st)continue;
      //---
      double diff=TEMA[i]-TEMA[i-1];
      if(diff>0) POS[i] = diff;
      if(diff<0) NEG[i] = -diff;
      if(i<=i1st+2)continue;
      SPOS[i]=C1*POS[i]+C2*SPOS[i-1]+C3*SPOS[i-2];
      SNEG[i]=C1*NEG[i]+C2*SNEG[i-1]+C3*SNEG[i-2];
      //---
      if(SNEG[i]!=0.0) OSC[i]=100-100/(1+SPOS[i]/SNEG[i]);
      else  if(SPOS[i]!=0.0) OSC[i]=100.0;
      else  OSC[i]=50.0;
      
      int i2nd=i1st+5;     

      if(i<=i2nd) continue;
      
      if((MAIN[i-1]+InpThreshold)<OSC[i])MAIN[i]=OSC[i];
      else if((MAIN[i-1]-InpThreshold)>OSC[i])MAIN[i]=OSC[i];
      else MAIN[i]=MAIN[i-1];

      //---
      if(i<=i2nd+1) continue;
      //---
      if(MAIN[i]>MAIN[i-1])SIG[i]=2;
      else if(MAIN[i]<MAIN[i-1])SIG[i]=0;
      else SIG[i]=SIG[i-1];

      if(SIG[i]==SIG[i-1])
      {
         TOP[i]=TOP[i-1];
         BTM[i]=BTM[i-1];
      }
      else
      {
         if(SIG[i]==2)
         {
            TOP[i]=EMPTY_VALUE;
            BTM[i]=MAIN[i-1];
         }
         else
         {
            BTM[i]=EMPTY_VALUE;
            TOP[i]=MAIN[i-1];
         }
      }
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|
//+------------------------------------------------------------------+
double nd(const double x,const int n)
  {
   return(NormalizeDouble(x,n));
  }
//+------------------------------------------------------------------+

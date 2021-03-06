//+------------------------------------------------------------------+
//|                                                     XRSI_v1.mq5  |
//| XRSI_v1                                   Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"
#property indicator_separate_window

#property indicator_levelcolor Silver
#property indicator_minimum 0
#property indicator_maximum 100

#property indicator_level1 80.0
#property indicator_level2 20.0

#property indicator_buffers 13
#property indicator_plots 1

#property indicator_type1         DRAW_COLOR_LINE
#property indicator_color1        clrRed,clrSilver,clrDodgerBlue
#property indicator_width1 2



input int InpRSIPeriod=11; // RSIPeriod
input int InpTemaFactor=100;// TemaFactor
input int InpThreshold=0; //Threshold
double MAIN[];
double SIG[];

double OSC[];
double POS[];
double NEG[];

double EMA1[];
double EMA2[];
double EMA3[];
double EMA4[];
double EMA5[];
double QEMA[];

int min_rates_total=InpTemaFactor+InpRSIPeriod+1;

double  tema_alpha=2.0/(1.0+InpTemaFactor);
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
   SetIndexBuffer(i++,OSC,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,QEMA,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,POS,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,NEG,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,EMA1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,EMA2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,EMA3,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,EMA4,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,EMA5,INDICATOR_CALCULATIONS);
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

      POS[i]=0;
      NEG[i]=0;

      if(i<=begin_pos+1)continue;
      EMA1[i]=EMA1[i-1]+tema_alpha*(close[i]-EMA1[i-1]);
      if(i<=begin_pos+2)continue;
      EMA2[i]=EMA2[i-1]+tema_alpha*(EMA1[i]-EMA2[i-1]);
      if(i<=begin_pos+3)continue;
      EMA3[i]=EMA3[i-1]+tema_alpha*(EMA2[i]-EMA3[i-1]);
      if(i<=begin_pos+4)continue;
      EMA4[i]=EMA4[i-1]+tema_alpha*(EMA3[i]-EMA4[i-1]);
      if(i<=begin_pos+5)continue;
      EMA5[i]= EMA5[i-1]+tema_alpha*(EMA4[i]-EMA5[i-1]);
      QEMA[i]=(5.0*EMA1[i]-10.0* EMA2[i]+10*EMA3[i]-5*EMA4[i]+EMA5[i]);


      int i1st=begin_pos+6;
      if(i<=i1st)continue;
      double diff;
      double pos=0;
      double neg=0;
      for(int j=0;j<InpRSIPeriod;j++)
        {
         diff=QEMA[i-j]-QEMA[i-j-1];
         if(diff==0)continue;
         if(diff>0) pos+=diff;
         if(diff<0) neg-=diff;
        }

      POS[i]=pos/InpRSIPeriod;
      NEG[i]=neg/InpRSIPeriod;
      //---
      if(i<=i1st+1)continue;
      //---
      diff=QEMA[i]-QEMA[i-1];
      if(diff>0) pos+=diff;
      if(diff<0) neg-=diff;
      //---
      POS[i]=(POS[i-1]*(InpRSIPeriod-1) + pos)/InpRSIPeriod;
      NEG[i]=(NEG[i-1]*(InpRSIPeriod-1) + neg)/InpRSIPeriod;
      //---
      if(NEG[i]!=0.0 && NEG[i]!=EMPTY_VALUE) OSC[i]=100-100/(1+POS[i]/NEG[i]);
      else  if(POS[i]!=0.0) OSC[i]=100.0;
      else  OSC[i]=50.0;

      int i2nd=i1st+2;
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

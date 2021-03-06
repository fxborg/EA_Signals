//+------------------------------------------------------------------+
//|                                             Jurik_RSX_v1_00.mq5  |
//| Jurik RSX v1.00                           Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"
#property indicator_separate_window

#property indicator_levelcolor Silver
#property indicator_minimum 0
#property indicator_maximum 100

#property indicator_level1 70.0
#property indicator_level2 30.0
#property indicator_buffers 22
#property indicator_plots 1
#property indicator_type1         DRAW_COLOR_LINE
#property indicator_color1        clrRed,clrSilver,clrDodgerBlue
#property indicator_width1 2



input int InpRSIPeriod=10; // RSIPeriod 
input int InpSmoothing=15;// Smoothing
input int InpThreshold=0; //Threshold


double MAIN[];
double SIG[];

double OSC[];

double POS[];
double NEG[];

double P_JMA1a[];
double P_JMA1b[];
double P_JMA1v[];

double P_JMA2a[];
double P_JMA2b[];
double P_JMA2v[];

double P_JMA3a[];
double P_JMA3b[];
double P_JMA[];

double N_JMA1a[];
double N_JMA1b[];
double N_JMA1v[];

double N_JMA2a[];
double N_JMA2b[];
double N_JMA2v[];

double N_JMA3a[];
double N_JMA3b[];
double N_JMA[];

int min_rates_total=InpRSIPeriod+2;
//--- JURIX Params
double KG = 3 / (InpSmoothing + 2.0);
double HG = 1.0 - KG;
double AB = 0.5;
double AC = 1.5;
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
   SetIndexBuffer(i++,POS,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,NEG,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,P_JMA1a,INDICATOR_DATA);
   SetIndexBuffer(i++,P_JMA1b,INDICATOR_DATA);
   SetIndexBuffer(i++,P_JMA1v,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,P_JMA2a,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,P_JMA2b,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,P_JMA2v,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,P_JMA3a,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,P_JMA3b,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,N_JMA1a,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,N_JMA1b,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,N_JMA1v,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,N_JMA2a,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,N_JMA2b,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,N_JMA2v,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,N_JMA3a,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,N_JMA3b,INDICATOR_CALCULATIONS);

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
      P_JMA1a[i]=0;      P_JMA1b[i]=0;      P_JMA1v[i]=0;
      P_JMA2a[i]=0;      P_JMA2b[i]=0;      P_JMA2v[i]=0;
      P_JMA3a[i]=0;      P_JMA3b[i]=0;      POS[i]=0;
      N_JMA1a[i]=0;      N_JMA1b[i]=0;      N_JMA1v[i]=0;
      N_JMA2a[i]=0;      N_JMA2b[i]=0;      N_JMA2v[i]=0;
      N_JMA3a[i]=0;      N_JMA3b[i]=0;      NEG[i]=0;

      //---
      if(i<=begin_pos+1)continue;
      double df=close[i]-close[i-1];
      double pos =MathMax(0,df);
      double neg =MathMax(0,-df);

      //-- 1st
      P_JMA1a[i]=HG*P_JMA1a[i-1] + KG*pos;
      P_JMA1b[i]=KG*P_JMA1a[i]   + HG*P_JMA1b[i-1];
      P_JMA1v[i]=AC*P_JMA1a[i]   - AB*P_JMA1b[i];

      N_JMA1a[i]=HG*N_JMA1a[i-1] + KG*neg;
      N_JMA1b[i]=KG*N_JMA1a[i]   + HG*N_JMA1b[i-1];
      N_JMA1v[i]=AC*N_JMA1a[i]   - AB*N_JMA1b[i];
      //--

      //-- 2nd
      P_JMA2a[i]=HG*P_JMA2a[i-1] + KG*P_JMA1v[i];
      P_JMA2b[i]=KG*P_JMA2a[i]   + HG*P_JMA2b[i-1];
      P_JMA2v[i]=AC*P_JMA2a[i]   - AB*P_JMA2b[i];

      N_JMA2a[i]=HG*N_JMA2a[i-1] + KG*N_JMA1v[i];
      N_JMA2b[i]=KG*N_JMA2a[i]   + HG*N_JMA2b[i-1];
      N_JMA2v[i]=AC*N_JMA2a[i]   - AB*N_JMA2b[i];
      //--

      //-- 3rd
      P_JMA3a[i]=HG*P_JMA3a[i-1] + KG*P_JMA2v[i];
      P_JMA3b[i]=KG*P_JMA3a[i]   + HG*P_JMA3b[i-1];
      POS[i]=AC*P_JMA3a[i]-AB*P_JMA3b[i];

      N_JMA3a[i]=HG*N_JMA3a[i-1] + KG*N_JMA2v[i];
      N_JMA3b[i]=KG*N_JMA3a[i]   + HG*N_JMA3b[i-1];
      NEG[i]=AC*N_JMA3a[i]-AB*N_JMA3b[i];
      //--

      int i1st=begin_pos+10;
      if(i<=i1st)continue;
      //---
      if(NEG[i]!=0.0) OSC[i]=100-100/(1+(POS[i]/NEG[i]));
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

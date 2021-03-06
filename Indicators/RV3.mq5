//+------------------------------------------------------------------+
//|                                                           RV.mq5 |
//| Realized volatillity v1.00                Copyright 2015, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"

#property indicator_buffers 18
#property indicator_plots   3
#property indicator_separate_window

#property indicator_label1 "GarmanKlass"
#property indicator_type1 DRAW_LINE
#property indicator_color1 clrRed
#property indicator_width1 2

#property indicator_label2 "Simple RV"
#property indicator_type2 DRAW_LINE
#property indicator_color2 clrYellow
#property indicator_width2 2

#property indicator_label3 "Log Return"
#property indicator_type3 DRAW_LINE
#property indicator_color3 clrBlue
#property indicator_width3 2

//--- input parameters
input ENUM_TIMEFRAMES InpTF=PERIOD_M5; // K  
input int InpPeriod=100; // Period
input int InpBarLimit=5000; // BarLimit

double V[];
double RV1[];
double RV2[];
//---- declaration of global variables
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Initialization of variables of data calculation starting point
   min_rates_total=2;
//--- indicator buffers mapping

//--- indicator buffers
   int i=0;
   SetIndexBuffer(i++,RV1,INDICATOR_DATA);
   SetIndexBuffer(i++,RV2,INDICATOR_DATA);
   SetIndexBuffer(i++,V,INDICATOR_DATA);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);

//---
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
   ArraySetAsSeries(time, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(RV1, true);
   ArraySetAsSeries(RV2, true);
   ArraySetAsSeries(V, true);
   
   int i;
   if(rates_total<=min_rates_total)
      return(0);
//---
   int limit = fmin(rates_total,InpBarLimit);
//+----------------------------------------------------+
//|Set Median Buffeer                                |
//+----------------------------------------------------+
   ArraySetAsSeries(time, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(RV1, true);
   ArraySetAsSeries(RV2, true);
   ArraySetAsSeries(V, true);


   for(i=limit-1;i>=0;i--)

//---
     {
         RV1[i]=0;
         RV2[i]=0;
         V[i]=0;
         double High[];
         double Low[];
         double Close[];
         double Open[];
         int tf_len=CopyHigh(Symbol(),InpTF,time[i]+InpTF,InpPeriod,High);
         int tf_len2=CopyLow(Symbol(),InpTF,time[i]+InpTF,InpPeriod,Low);
         int tf_len3=CopyClose(Symbol(),InpTF,time[i]+InpTF,InpPeriod,Close);
         int tf_len4=CopyOpen(Symbol(),InpTF,time[i]+InpTF,InpPeriod,Open);
         if(tf_len != InpPeriod)continue;
         double v=0.0;
         double hilo=0.0;
         double co=0.0;
         double oc=0.0;
         double k = (2*log(2) - 1);
         for(int j=0;j<tf_len;j++)
         {
           
           hilo+= 0.5*pow(log(High[j]/Low[j]),2);
           if(j>0)oc+= pow(log(Open[j]/Close[j-1]),2);
           co+=k * pow(log(Close[j]/Open[j]),2);
         }
         
         RV1[i+1]=sqrt((oc+hilo-co));
         v=0.0;
         for(int j=1;j<tf_len;j++)
         {
          v+=pow(log(Close[j]/Close[j-1]),2);
         }
         RV2[i+1]=sqrt(v);
         V[i]=sqrt(pow(log(close[i]/close[i+1]),2));
 
     }
//----    

   return(rates_total);
  }

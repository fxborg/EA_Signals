//+------------------------------------------------------------------+
//|                                                convex_v1.00.mq5  |
//| convex_v1.00                             Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"
#property indicator_chart_window


#property indicator_buffers 3
#property indicator_plots 1

#property indicator_type1         DRAW_ARROW 
#property indicator_color1        clrDodgerBlue
#property indicator_width1 2
#property indicator_type2         DRAW_ARROW
#property indicator_color2        clrSilver
#property indicator_width2 1
#property indicator_type3         DRAW_ARROW
#property indicator_color3        clrSilver
#property indicator_width3 1


input int InpPeriod=20; //     Period

double R1[];
double S1[];
double OSC[];
double POS[];
double NEG[];
double CNT[];

int WinNo=ChartWindowFind();
int min_rates_total=InpPeriod;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   ObjectsDeleteAll(0,WinNo);

//--- 
//---
   int i=0;
   SetIndexBuffer(i++,CNT,INDICATOR_DATA);
   SetIndexBuffer(i++,R1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,S1,INDICATOR_CALCULATIONS);

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
      
      if(i<rates_total-201)ObjectsDeleteAll(0,WinNo);
   
      S1[i]=EMPTY_VALUE;
      R1[i]=EMPTY_VALUE;
      CNT[i]=EMPTY_VALUE;
      int i1st=begin_pos+InpPeriod*2;
      if(i<=i1st)continue;
      calc_convex(R1,S1,high,low,i,time);

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
//|
//+------------------------------------------------------------------+
void convex_hull(double  &upper[][2],double  &lower[][2],const double &points[][2],const int len)
  {

   int k=0;
   if(len<=2)return;
   double temp[][2];
   ArrayResize(temp,k,len);
   ArrayResize(lower,k,len);
   
   for(int i=0;i<len;i++)
     {
   
   
      while(k>=2 && 
            (cross(temp[k-2][0],temp[k-2][1],
            temp[k-1][0],temp[k-1][1],
            points[i][0],points[i][1]))>=0)
        {
         k--;
        }
      if(points[i][0]!=EMPTY_VALUE)
        {
         ArrayResize(temp,k+1,len);
         temp[k][0]= points[i][0];
         temp[k][1]= points[i][1];
         k++;
        }
     }

   ArrayCopy(upper,temp,0,2);
   ArrayResize(temp,0,len);

   k=0;
   for(int i=len-1;i>=0;i--)
     {
      while(k>=2 && 
            (cross(temp[k-2][0],temp[k-2][1],
            temp[k-1][0],temp[k-1][1],
            points[i][0],points[i][1]))>=0)
        {
         k--;
        }
      if(points[i][0]!=EMPTY_VALUE)
        {
         ArrayResize(temp,k+1,len);
         temp[k][0]= points[i][0];
         temp[k][1]= points[i][1];
         k++;
        }
     }

   ArrayCopy(lower,temp,0,2);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double cross(const double ox,double oy,
             const double ax,double ay,
             const double bx,double by)
  {
   return ((ax - ox) * (by - oy) - (ay - oy) * (bx - ox));
  }
//+------------------------------------------------------------------+
void calc_convex(double  &R[],double &S[],const double &High[],const double &Low[],const int i,const datetime &time[])
  {
   double vertex[][2];
   ArrayResize(vertex,0,InpPeriod*3);
   int i_vtx=0;
   double upper[][2];
   double lower[][2];
   int up_sz=0;
   int lo_sz=0;
   for(int j=0;j<InpPeriod;j++)
     {
      int ii=i-(InpPeriod-1)+j;

      ArrayResize(vertex,i_vtx+1,InpPeriod*2);
      vertex[i_vtx][0] = ii;
      vertex[i_vtx][1] = Low[ii];
      i_vtx++;

      if(Low[ii]<High[ii])
        {
         ArrayResize(vertex,i_vtx+1,InpPeriod*2);
         vertex[i_vtx][0] = ii;
         vertex[i_vtx][1] = High[ii];
         i_vtx++;
        }

     }
   convex_hull(upper,lower,vertex,i_vtx);
   up_sz=int(ArraySize(upper)*0.5);
   lo_sz=int(ArraySize(lower)*0.5);

   double mx,my;
   calc_centroid(mx,my,upper,lower);
   if(mx<i)
     {
      CNT[int(mx+0.5)]=my;

      for(int k=1;k<up_sz;k++)
        {
         int t1=(int)upper[k-1][0];
         double y1=upper[k-1][1];
         int t2=(int)upper[k][0];
         double y2=upper[k][1];
         //R[t2]=y2;
         drawR(0,i%200,t1,y1,t2,y2,time);
        }
      for(int k=1;k<lo_sz;k++)
        {
         int t1=(int)lower[k-1][0];
         double y1=lower[k-1][1];
         int t2=(int)lower[k][0];
         double y2=lower[k][1];
         //S[t2]=y2;
         drawS(0,i%200,t1,y1,t2,y2,time);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool check_distance(double  &vertex[][2],const int x,const double y,const double limit)
  {
   int sz=int(ArraySize(vertex)/2);
   double dmin=0;
   for(int j=0;j<sz;j++)
     {
      double dst=distance(vertex[j][0],vertex[j][1],x,y);
      if(dmin==0 || dmin>dst) dmin=dst;
     }
   return(dmin<=limit);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double distance(const double ax,const double ay,const double  bx,const double by)
  {
   double dx = ax-bx;
   double dy = ay-by;
   return MathSqrt((dx * dx) + (dy * dy));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void regression(double  &a,double  &b,double &dev,const double &data[],const int from,const int to)
  {

   int temp_sz=to-from;
   double temp[][2];
   ArrayResize(temp,temp_sz+1);
   int n=0;
   for(int k=from;k<=to;k++)
     {
      temp[n][0]=k;
      temp[n][1]=data[k];
      n++;
     }
   _regression(a,b,temp,n);
   dev=0;
   for(int i=0; i<n; i++)
      dev+=MathPow((temp[i][0]*a+b)-temp[i][1],2);
   dev=MathSqrt(dev/n);
  }
//+------------------------------------------------------------------+
//|
//+------------------------------------------------------------------+
void _regression(double  &a,double  &b,const double &data[][2],const int cnt)
  {

   if(cnt==0)
     {
      a=EMPTY_VALUE;
      b=EMPTY_VALUE;
      return;
     }
//--- 
   double sumy=0.0; double sumx=0.0;
   double sumxy=0.0; double sumx2=0.0;

//--- 
   for(int n=0; n<cnt; n++)
     {
      //---
      sumx+=data[n][0];
      sumx2+= data[n][0]*data[n][0];
      sumy += data[n][1];
      sumxy+= data[n][0]*data[n][1];

     }
//---
   double c=sumx2-sumx*sumx/cnt;
   if(c==0.0)
     {
      a=0.0;
      b=sumy/cnt;
     }
   else
     {
      a=(sumxy-sumx*sumy/cnt)/c;
      b=(sumy-sumx*a)/cnt;
     }
  }
//+------------------------------------------------------------------+

void calc_centroid(double  &x,double  &y,const double  &upper[][2],const double  &lower[][2])
  {
   double vertices[][2];
   int up_sz=int(ArraySize(upper)*0.5);
   int lo_sz=int(ArraySize(lower)*0.5);
   int sz=up_sz+lo_sz;
   ArrayResize(vertices,0,sz);
   int n=0;
   for(int j=0;j<up_sz;j++)
     {
      ArrayResize(vertices,n+1,sz);
      vertices[n][0]=upper[j][0];
      vertices[n][1]=upper[j][1];
      n++;
     }
   for(int j=0;j<lo_sz;j++)
     {
      ArrayResize(vertices,n+1,sz);
      vertices[n][0]=lower[j][0];
      vertices[n][1]=lower[j][1];
      n++;
     }

   int v_cnt=n;
   y=0;
   x=0;
   double signedArea=0.0;
   double x0 = 0.0; // Current vertex X
   double y0 = 0.0; // Current vertex Y
   double x1 = 0.0; // Next vertex X
   double y1 = 0.0; // Next vertex Y
   double a = 0.0;  // Partial signed area

                    // For all vertices
   int i=0;
   for(i=0; i<v_cnt-1; i++)
     {
      x0 = vertices[i][0];
      y0 = vertices[i][1];
      if(i==v_cnt-2)
        {
         x1 = vertices[0][0];
         y1 = vertices[0][1];
        }
      else
        {
         x1 = vertices[i+1][0];
         y1 = vertices[i+1][1];
        }
      a=x0*y1-x1*y0;
      signedArea+=a;
      x += (x0 + x1)*a;
      y += (y0 + y1)*a;
     }
   if(signedArea!=0.0)
     {
      signedArea*=0.5;
      x /= (6.0*signedArea);
      y /= (6.0*signedArea);
     }
  }
//+------------------------------------------------------------------+
void drawR(const int id,const int n,const int x0,const double y0,const int x1,const double y1,const datetime &time[])
  {
   ObjectCreate(0,"R"+StringFormat("%d_%d",id,n),OBJ_TREND,WinNo,time[x0],y0,time[x1],y1);
   ObjectSetInteger(0,"R"+StringFormat("%d_%d",id,n),OBJPROP_COLOR,clrRed);
   ObjectSetInteger(0,"R"+StringFormat("%d_%d",id,n),OBJPROP_WIDTH,1);
   ObjectSetInteger(0,"R"+StringFormat("%d_%d",id,n),OBJPROP_STYLE,STYLE_DOT);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawS(const int id,const int n,const int x0,const double y0,const int x1,const double y1,const datetime &time[])
  {
   ObjectCreate(0,"S"+StringFormat("%d_%d",id,n),OBJ_TREND,WinNo,time[x0],y0,time[x1],y1);
   ObjectSetInteger(0,"S"+StringFormat("%d_%d",id,n),OBJPROP_COLOR,clrYellow);
   ObjectSetInteger(0,"S"+StringFormat("%d_%d",id,n),OBJPROP_WIDTH,1);
   ObjectSetInteger(0,"S"+StringFormat("%d_%d",id,n),OBJPROP_STYLE,STYLE_DOT);

  }
//+------------------------------------------------------------------+

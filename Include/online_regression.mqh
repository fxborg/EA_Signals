//+------------------------------------------------------------------+
//|                                            Online_Regression.mqh |
//| Online Regression v1.00                   Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"
#include <incMatrix.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class COnlineRegression
  {

protected:
   int               m_CurrentBar;
   int               m_PrevBar;
   double            m_Alpha;
   double            m_Series;
   double            m_M[6];
   double            m_V[4];
   double            m_Series_bk;
   double            m_M_bk[6];
   double            m_V_bk[4];
   CIntMatrix        m_MX;
public:
   //--- Initialization
   void              COnlineRegression();                   // constructor
   void             ~COnlineRegression();                   // destructor
   void              Init(const double alpha);
   void              Push(const double series,const int begin,const int rates_total,const int bar,double  &intersept,double  &beta);
protected:
   void              Dot(const double x1,const double y1,const double x2,const double y2,double &v[]);
   bool              Solver(const double &m[],const double &v[],double &res[]);

  };
void COnlineRegression::COnlineRegression(){}
void COnlineRegression::~COnlineRegression(){}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void COnlineRegression::Init(const double alpha)
  {
//---
   m_Alpha=alpha;
//---
   m_CurrentBar=-1;
   m_PrevBar=-1;
   m_M[0]=0;
   m_M[1]=0;
   m_M[2]=0;
   m_M[3]=0;
   m_M[4]=2;
   m_M[5]=2;

//---
   m_V[0]=0;
   m_V[1]=0;
   m_V[2]=2;
   m_V[3]=1;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void COnlineRegression::Push(const double series,const int begin,const int rates_total,const int bar,double  &intersept,double  &beta)
  {
   double _M[6];
   double _V[6];
   _M[0]=0;
   _M[1]=0;
   _M[2]=0;
   _M[3]=0;
   _M[4]=2;
   _M[5]=2;
   _V[0]=0;
   _V[1]=0;
   _V[2]=2;
   _V[3]=1;
   double x[4];
   x[0]=1;
   x[1]=0;
   x[2]=2;
   x[3]=1;


   if(bar<begin)return;
   m_PrevBar=m_CurrentBar;
   m_CurrentBar=bar;

   if(m_PrevBar<m_CurrentBar && bar==rates_total-2)
     {
      m_Series=m_Series_bk;
      ArrayCopy(m_M,m_M_bk);
      ArrayCopy(m_V,m_V_bk);
     }
   
//---
//---

//---
   if(bar==begin)
     {
      x[1]=series;
     }
   else
     {
      x[1]=m_Series;
     }
   double tmp_m[],tmp_x1[],tmp_x2[];
//---

   m_MX.MultNum(m_M,m_Alpha,tmp_m);

   COnlineRegression::Dot(x[0],x[1],x[0],x[1],tmp_x1);

   m_MX.MultNum(tmp_x1,(1.0-m_Alpha),tmp_x2);

//---
   m_MX.AddMx(tmp_m,tmp_x2,_M);

//---
   double tmp_v[],tmp_x3[],tmp_x4[];
   m_MX.MultNum(m_V,m_Alpha,tmp_v);
   m_MX.MultNum(x,(1.0-m_Alpha),tmp_x3);
   m_MX.MultNum(tmp_x3,series,tmp_x4);
//---
   m_MX.AddMx(tmp_v,tmp_x4,_V);
//---

   double result[];
   COnlineRegression::Solver(_M,_V,result);
   beta=result[1];
   intersept=result[0];
//---
   if(bar<rates_total-3)
     {
      m_Series=series;
      ArrayCopy(m_M,_M);
      ArrayCopy(m_V,_V);
     }
   if(bar==rates_total-3)
     {
      m_Series_bk=series;
      ArrayCopy(m_M_bk,_M);
      ArrayCopy(m_V_bk,_V);
     }

//---

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void  COnlineRegression::Dot(double x1,double y1,double x2,double y2,double &v[])
  {
   ArrayResize(v,6);
   v[0]=x1*x2;
   v[1]=x1*y2;
   v[2]=x2*y1;
   v[3]=y1*y2;
   v[4]=2;
   v[5]=2;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool COnlineRegression::Solver(const double &m[],const double &v[],double &res[])
  {
   ArrayResize(res,4);
   res[0]=0;
   res[1]=0;
   res[2]=2;
   res[3]=1;
   double x,y;
   if(m[0]*m[3]-m[2]*m[1] == 0) return false;
   y=(v[1]*m[0]-m[2]*v[0])/(m[0]*m[3]-m[2]*m[1]);
   if(m[0]!=0) x=(v[0]-m[1]*y)/(m[0]);
   else               x=(v[1]-m[3]*y)/(m[2]);
   res[0]=x;
   res[1]=y;
   return true;
  }
//+------------------------------------------------------------------+

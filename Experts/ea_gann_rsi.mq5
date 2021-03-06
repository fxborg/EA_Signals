//+------------------------------------------------------------------+
//|                                                  ea_gann_rsi.mq5 |
//| ea_gann_rsi v1.00                         Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"

#include <ExpertAdvisor.mqh>
enum ENUM_MY_METHOD {SMA = 0, LWMA = 1} ;
input string description1="1.-------------------------------";
input double Risk=0.1; // Risk
input int    SL        = 1000; // Stop Loss distance
input int    TP        = 2500; // Take Profit distance
input int    HourStart =   7; // Hour of trade start
input int    HourEnd   =  21; // Hour of trade end
input string description2="2.-------------------------------";
input int Gann1stBars=1; // 1st Gann Bars
input int Gann2ndBars=8; // 2nd Gann Bars

input string description3="3.-------------------------------";
input ENUM_MY_METHOD    RSI_Method=LWMA;    
input ENUM_TIMEFRAMES   RSI_TimeFrame=PERIOD_H8; // RSI Time Frame
input int    RSI_Period=20; // RSI period


input string description4="4.-------------------------------";//
input int    Trail_Size    =  380; // Trailing Stop Size
input int    Trail_Period  =  2;   // Trailing Stop Period
input int    Trail_Minimum    =  250; // Trailing Stop Minimum Size
input int    Trail_Maximum    =  750; // Trailing Stop Maximum Size
//---
class CMyEA : public CExpertAdvisor
  {
protected:
   double            m_risk;          // size of risk
   int               m_sl;            // Stop Loss
   int               m_tp;            // Take Profit
   int               m_ts;            // Trailing Stop
   int               m_hourStart;     // Hour of trade start
   int               m_hourEnd;       // Hour of trade end


   int               m_gann1_handle;   // 1st GANN Handle
   int               m_gann2_handle;  // 2nd GANN Handle

   int               m_rsi_handle;  // RSI Handle
   ENUM_TIMEFRAMES   m_rsi_tf;      // RSI Timeframe
   int               m_rsi_period;  // RSI period
   ENUM_MY_METHOD    m_rsi_method;  // RSI MaMethod

   int               m_gann_1st_bars;  // Gann 1st bars
   int               m_gann_2nd_bars;  // Gann 2nd bars

   int               m_trail_handle;
   int               m_trail_size;
   int               m_trail_period;
   int               m_trail_minimum;
   int               m_trail_maximum;

public:
   void              CMyEA();
   void             ~CMyEA();
   virtual bool      Init(string smb,ENUM_TIMEFRAMES tf); // initialization
   virtual bool      Main();                              // main function
   virtual void      OpenPosition(long dir);              // open position on signal
   virtual void      ClosePosition(long dir);             // close position on signal
  };
//------------------------------------------------------------------	CMyEA
void CMyEA::CMyEA(void) { }
//------------------------------------------------------------------	~CMyEA
void CMyEA::~CMyEA(void)
  {
   IndicatorRelease(m_rsi_handle);
   IndicatorRelease(m_trail_handle);
   IndicatorRelease(m_gann1_handle);
   IndicatorRelease(m_gann2_handle);
  }
//------------------------------------------------------------------	Init
bool CMyEA::Init(string smb,ENUM_TIMEFRAMES tf)
  {
   if(!CExpertAdvisor::Init(0,smb,tf)) return(false);  // initialize parent class
                                                       // copy parameters
   m_risk=Risk;
   m_tp=TP;
   m_sl=SL;
   m_hourStart=HourStart;
   m_hourEnd=HourEnd;

//---
   m_gann_1st_bars=Gann1stBars;
   m_gann_2nd_bars=Gann2ndBars;
//---

   m_rsi_period=RSI_Period;
   m_rsi_tf=RSI_TimeFrame;
   m_rsi_method=RSI_Method;
   

//---
   m_trail_size=Trail_Size;
   m_trail_period=Trail_Period;
   m_trail_minimum=Trail_Minimum;
   m_trail_maximum=Trail_Maximum;
//---
   m_gann1_handle=iCustom(m_smb,m_tf,"GannSwingBars",m_gann_1st_bars);
   if(m_gann1_handle==INVALID_HANDLE) return(false);            // if there is an error, then exit

   m_gann2_handle=iCustom(m_smb,m_tf,"GannSwingBars",m_gann_2nd_bars);
   if(m_gann2_handle==INVALID_HANDLE) return(false);            // if there is an error, then exit

   m_rsi_handle=iCustom(m_smb,m_rsi_tf,"Digital_RSI",m_rsi_period,m_rsi_method);
   if(m_rsi_handle==INVALID_HANDLE) return(false);            // if there is an error, then exit


   m_trail_handle=iCustom(m_smb,m_tf,"LogicalStops",m_trail_size,m_trail_period);
   if(m_trail_handle==INVALID_HANDLE) return(false);            // if there is an error, then exit


   m_bInit=true; return(true);                         // "trade allowed"
  }
//------------------------------------------------------------------	Main
bool CMyEA::Main() // main function
  {
   if(!CExpertAdvisor::Main()) return(false); // call function of parent class

   if(Bars(m_smb,m_rsi_tf)<=m_rsi_period*2) return(false); // if there are insufficient number of bars
   static CIsNewBar NB;
   if(!NB.IsNewBar(m_smb,m_tf))return (true);

// check each direction

   MqlRates rt[2];
   if(CopyRates(m_smb,m_tf,1,2,rt)!=2)
     { Print("CopyRates ",m_smb," history is not loaded"); return(WRONG_VALUE); }


   double GANN1[3];
   double GANN2[7];
   double RSI[2];
   double RSI_SIG[2];

   double TRAIL_UP[2];
   double TRAIL_DN[2];

   if(CopyBuffer(m_rsi_handle,0,1,2,RSI)!=2)
     { Print("CopyBuffer RSI - no data"); return(WRONG_VALUE); }
   if(CopyBuffer(m_rsi_handle,1,1,2,RSI_SIG)!=2)
     { Print("CopyBuffer RSI - no data"); return(WRONG_VALUE); }

   if(CopyBuffer(m_gann1_handle,4,1,3,GANN1) != 3) 
     { Print("CopyBuffer Gann - no data"); return(WRONG_VALUE); }

   if(CopyBuffer(m_gann2_handle,4,1,7,GANN2) != 7) 
     { Print("CopyBuffer Gann - no data"); return(WRONG_VALUE); }
     
   if(CopyBuffer(m_trail_handle,0,1,2,TRAIL_UP)!=2)
     { Print("CopyBuffer LogicalStops - no data"); return(WRONG_VALUE); }

   if(CopyBuffer(m_trail_handle,1,1,2,TRAIL_DN)!=2)
     { Print("CopyBuffer LogicalStops - no data"); return(WRONG_VALUE); }

   double min_gann = MathMin(MathMin(GANN2[5],GANN2[3]),GANN2[1]);
   double max_gann = MathMax(MathMax(GANN2[5],GANN2[3]),GANN2[1]);
// OPEN BUY

   if(RSI[1]<70 && RSI_SIG[1]==2 && max_gann == 1 && GANN2[6] == 0 &&  GANN1[1] == 1 && GANN1[2] == 0 )  
       OpenPosition(ORDER_TYPE_BUY);

   if(RSI_SIG[1]==0 && GANN2[6] == 1 ) ClosePosition(ORDER_TYPE_BUY);

   CheckTrailingStopLong(TRAIL_DN[1],rt[1].low,m_trail_minimum,m_trail_maximum);

// DOWN TREND
   if(RSI[1]>30 && RSI_SIG[1]==0 &&  min_gann == 0 && GANN2[6] == 1 && GANN1[1] == 0 && GANN1[2] == 1 )
      OpenPosition(ORDER_TYPE_SELL);

// CLOSE SELL
   if(RSI_SIG[1]==2 &&  GANN2[6] == 0 ) ClosePosition(ORDER_TYPE_SELL);

   CheckTrailingStopShort(TRAIL_UP[1],rt[1].high,m_trail_minimum,m_trail_maximum);

   return(true);
  }
//------------------------------------------------------------------	OpenPos
void CMyEA::OpenPosition(long dir)
  {
   if(PositionSelect(m_smb)) return;
   if(!CheckTime(StringToTime(IntegerToString(m_hourStart)+":00"),
      StringToTime(IntegerToString(m_hourEnd)+":00"))) return;
   double lot=CountLotByRisk(m_sl,m_risk,0);
   if(lot<=0) return;
   DealOpen(dir,lot,m_sl,m_tp);
  }
//------------------------------------------------------------------	ClosePos
void CMyEA::ClosePosition(long dir)
  {
   if(!PositionSelect(m_smb)) return;
   if(dir!=PositionGetInteger(POSITION_TYPE)) return;
   m_trade.PositionClose(m_smb,1);
  }

CMyEA ea; // class instance
//------------------------------------------------------------------	OnInit
int OnInit()
  {
   ea.Init(Symbol(),Period()); // initialize expert

                               // initialization example
// ea.Init(Symbol(), PERIOD_M5); // for fixed timeframe
// ea.Init("USDJPY", PERIOD_H2); // for fixed symbol and timeframe

   return(0);
  }
//------------------------------------------------------------------	OnDeinit
void OnDeinit(const int reason) { }
//------------------------------------------------------------------	OnTick
void OnTick()
  {
   ea.Main(); // process incoming tick
  }
//+------------------------------------------------------------------+

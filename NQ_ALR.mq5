//+------------------------------------------------------------------+
//|                                                       NQ_ALR.mq5 |
//|                                     Copyright 2023, Neto Queiroz |
//|                                  https://github.com/Neto-Queiroz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Neto Queiroz"
#property description "ATR + Laguerre + RSI"
#property link      "https://github.com/Neto-Queiroz"
#property version   "1.00"

//------------------------------------------------------------------+

#property indicator_separate_window
#property indicator_buffers 12
#property indicator_plots   3

#property indicator_type1   DRAW_COLOR_HISTOGRAM2
#property indicator_color1  clrGray,clrDarkGreen,clrMaroon
#property indicator_width1  2

#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrGray,clrDodgerBlue,clrTomato,clrSteelBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

#property indicator_type3   DRAW_LINE
#property indicator_color3  clrYellow
#property indicator_style3  STYLE_DOT
#property indicator_width3  1

//------------------------------------------------------------------+

input int                inpAtrFastPeriod    = 3;              // ATR - Período Rápido
input int                inpAtrSlowPeriod    = 33;             // ATR - Período Lento

input ENUM_APPLIED_PRICE inpRsiPrice         = PRICE_CLOSE;    // Preço Aplicado

//------------------------------------------------------------------+

double HistBufferX[],HistBufferY[], HistColorBuffer[];
double MainBuffer[], MainColorBuffer[];
double val[];
double Fval[],Fatr[];
double Mval[],Matr[];
double Sval[],Satr[];

//------------------------------------------------------------------+

int  _FatrHandle,_FatrPeriod;
int  _MatrHandle,_MatrPeriod;
int  _SatrHandle,_SatrPeriod;

double _FsmoothPeriod,_MsmoothPeriod,_SsmoothPeriod; 

//------------------------------------------------------------------

int OnInit()
{ 
   SetIndexBuffer( 0,HistBufferX       ,INDICATOR_DATA); 
   SetIndexBuffer( 1,HistBufferY       ,INDICATOR_DATA); 
   SetIndexBuffer( 2,HistColorBuffer   ,INDICATOR_COLOR_INDEX);
   SetIndexBuffer( 3,MainBuffer        ,INDICATOR_DATA); 
   SetIndexBuffer( 4,MainColorBuffer   ,INDICATOR_COLOR_INDEX);
   SetIndexBuffer( 5,val               ,INDICATOR_DATA);
   SetIndexBuffer( 6,Fval              ,INDICATOR_CALCULATIONS);
   SetIndexBuffer( 7,Fatr              ,INDICATOR_CALCULATIONS);
   SetIndexBuffer( 8,Mval              ,INDICATOR_CALCULATIONS);
   SetIndexBuffer( 9,Matr              ,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,Sval              ,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,Satr              ,INDICATOR_CALCULATIONS);
   
   IndicatorSetInteger(INDICATOR_HEIGHT,115);
   
   IndicatorSetDouble(INDICATOR_MAXIMUM,1.7);
   IndicatorSetDouble(INDICATOR_MINIMUM,-0.2);
   
   IndicatorSetInteger(INDICATOR_LEVELS,3);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,1.5);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,0.75);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,2,0.00);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,0,clrDimGray);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,1,clrDimGray);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,2,clrDimGray);

   _FatrPeriod    = (int)((inpAtrFastPeriod > 1) ? inpAtrFastPeriod : 1);
   _MatrPeriod    = (int)((inpAtrSlowPeriod-inpAtrFastPeriod)/2);
   _SatrPeriod    = (int)(inpAtrSlowPeriod);
   
   _SsmoothPeriod  = (double)_FatrPeriod;
   _MsmoothPeriod  = _SsmoothPeriod*2;
   _FsmoothPeriod  = _MsmoothPeriod*2;
   
   _ema.init((int)((_FatrPeriod+_MatrPeriod+_SatrPeriod)*0.5)/2);
   
   _FatrHandle    = iATR(_Symbol,0,_FatrPeriod); if (!_checkHandle(_FatrHandle)) return(INIT_FAILED);
   _MatrHandle    = iATR(_Symbol,0,_MatrPeriod); if (!_checkHandle(_MatrHandle)) return(INIT_FAILED);
   _SatrHandle    = iATR(_Symbol,0,_SatrPeriod); if (!_checkHandle(_SatrHandle)) return(INIT_FAILED);
   
   IndicatorSetInteger(INDICATOR_DIGITS,2);

   IndicatorSetString(INDICATOR_SHORTNAME,"ALR");
   for (int i=0;i<3;i++) PlotIndexSetInteger(i,PLOT_SHOW_DATA,false);
   
   return(0);
}

//------------------------------------------------------------------

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
{
   int _copyCount = rates_total-prev_calculated+1;
   if (_copyCount>rates_total) _copyCount=rates_total;
     
   if (CopyBuffer(_FatrHandle,0,0,_copyCount,Fatr)!=_copyCount) return(prev_calculated);

   if (CopyBuffer(_MatrHandle,0,0,_copyCount,Matr)!=_copyCount) return(prev_calculated);

   if (CopyBuffer(_SatrHandle,0,0,_copyCount,Satr)!=_copyCount) return(prev_calculated);

   int i=(prev_calculated>0?prev_calculated-1:0); for (; i<rates_total && !_StopFlag; i++) {
      int    Fstart = (i>_FatrPeriod) ? i-_FatrPeriod+1 : 0;
      int    Mstart = (i>_MatrPeriod) ? i-_MatrPeriod+1 : 0;
      int    Sstart = (i>_SatrPeriod) ? i-_SatrPeriod+1 : 0;
      
      double Fmax   = Fatr[ArrayMaximum(Fatr,Fstart,_FatrPeriod)];
      double Fmin   = Fatr[ArrayMinimum(Fatr,Fstart,_FatrPeriod)];
      
      double Mmax   = Matr[ArrayMaximum(Matr,Mstart,_MatrPeriod)];
      double Mmin   = Matr[ArrayMinimum(Matr,Mstart,_MatrPeriod)];
      
      double Smax   = Satr[ArrayMaximum(Satr,Sstart,_SatrPeriod)];
      double Smin   = Satr[ArrayMinimum(Satr,Sstart,_SatrPeriod)];
      
      double Fcoeff = (Fmin!=Fmax) ? 1.-((Fatr[i]-Fmin)/(Fmax-Fmin)) : 0.5;
      double Mcoeff = (Mmin!=Mmax) ? 1.-((Matr[i]-Mmin)/(Mmax-Mmin)) : 0.5;
      double Scoeff = (Smin!=Smax) ? 1.-((Satr[i]-Smin)/(Smax-Smin)) : 0.5;
      
      Fval[i] = iLaGuerreRsi(getPrice(inpRsiPrice,open,close,high,low,i),_FatrPeriod*(Fcoeff+0.75),_FsmoothPeriod,i,0);
      Mval[i] = iLaGuerreRsi(getPrice(inpRsiPrice,open,close,high,low,i),_MatrPeriod*(Mcoeff+0.75),_MsmoothPeriod,i,1);
      Sval[i] = iLaGuerreRsi(getPrice(inpRsiPrice,open,close,high,low,i),_SatrPeriod*(Scoeff+0.75),_SsmoothPeriod,i,2);
      
      double Calc1 = (i>0) ? (Fval[i] + Fval[i-1])/2 : Fval[i];
      double Calc2 = (i>0) ? (Mval[i] + Mval[i-1])/2 : Mval[i];
      double Calc3 = (i>0) ? (Sval[i] + Sval[i-1])/2 : Sval[i];
      
      double MainTemp = (i>0) ? (MainBuffer[i-1] + Calc1 + Calc2 + Calc3)/3 : (Calc1 + Calc2 + Calc3)/3;
      double ValTemp  = _ema.calculate(MainTemp,i,rates_total);
      
      double HistTemp = (MainTemp - ValTemp) + 0.75;
              
      if (HistTemp > 0.75) {
         HistBufferX[i] = HistTemp;
         HistBufferY[i] = 0.75;
         HistColorBuffer[i] = 1;
      } else if (HistTemp < 0.75) {
         HistBufferX[i] = 0.75;
         HistBufferY[i] = HistTemp;
         HistColorBuffer[i] = 2;
      }
           
      MainBuffer[i] = MainTemp;
      MainColorBuffer[i] = (i>0) ? (MainBuffer[i] > MainBuffer[i-1]) ? 1 : (MainBuffer[i] < MainBuffer[i-1]) ? 2 : MainColorBuffer[i-1] : 0;
      
      val[i]  = ValTemp;
      
      //if (MainBuffer[i] > val[i]) Label( (MainColorBuffer[i]==1) ? 0 : 1 );
      //else if (MainBuffer[i] < val[i]) Label( (MainColorBuffer[i]==2) ? 2 : 3 );
      //Label(1);
   }

   return(i);
}

//------------------------------------------------------------------

#define _lagRsiInstancesSize 5
#define _lagRsiRingSize 6
double FworkLagRsi[_lagRsiRingSize][_lagRsiInstancesSize];
double MworkLagRsi[_lagRsiRingSize][_lagRsiInstancesSize];
double SworkLagRsi[_lagRsiRingSize][_lagRsiInstancesSize];

double iLaGuerreRsi(double price, double period, double smooth, int i, int velocity, int instance=0)
{
   int k;
   
   int _indC = (i  )%_lagRsiRingSize;
   int _inst = instance*_lagRsiInstancesSize;

   double CU = 0;
   double CD = 0;
   
   double Val0 = 0;
   double Val1 = 0;
   double Val2 = 0;
   double Val3 = 0;

   if (i>0 && period>1) {      
      int    _indP  = (i-1)%_lagRsiRingSize;
      double _gamma = 1.0 - 10.0/(period+9.0);
      
      switch(velocity) {
         case 0:
            FworkLagRsi[_indC][_inst+4] = (smooth>1.0) ? FworkLagRsi[_indP][_inst+4] + (2.0/(1.0+smooth))*(price-FworkLagRsi[_indP][_inst+4]) : price;
            FworkLagRsi[_indC][_inst  ] = FworkLagRsi[_indC][_inst+4] + _gamma*(FworkLagRsi[_indP][_inst  ] - FworkLagRsi[_indC][_inst+4]);
            FworkLagRsi[_indC][_inst+1] = FworkLagRsi[_indP][_inst  ] + _gamma*(FworkLagRsi[_indP][_inst+1] - FworkLagRsi[_indC][_inst  ]);
            FworkLagRsi[_indC][_inst+2] = FworkLagRsi[_indP][_inst+1] + _gamma*(FworkLagRsi[_indP][_inst+2] - FworkLagRsi[_indC][_inst+1]);
            FworkLagRsi[_indC][_inst+3] = FworkLagRsi[_indP][_inst+2] + _gamma*(FworkLagRsi[_indP][_inst+3] - FworkLagRsi[_indC][_inst+2]);
            Val0 = FworkLagRsi[_indC][_inst];
            Val1 = FworkLagRsi[_indC][_inst+1];
            Val2 = FworkLagRsi[_indC][_inst+2];
            Val3 = FworkLagRsi[_indC][_inst+3];
            break;
         case 1:
            MworkLagRsi[_indC][_inst+4] = (smooth>1.0) ? MworkLagRsi[_indP][_inst+4] + (2.0/(1.0+smooth))*(price-MworkLagRsi[_indP][_inst+4]) : price;
            MworkLagRsi[_indC][_inst  ] = MworkLagRsi[_indC][_inst+4] + _gamma*(MworkLagRsi[_indP][_inst  ] - MworkLagRsi[_indC][_inst+4]);
            MworkLagRsi[_indC][_inst+1] = MworkLagRsi[_indP][_inst  ] + _gamma*(MworkLagRsi[_indP][_inst+1] - MworkLagRsi[_indC][_inst  ]);
            MworkLagRsi[_indC][_inst+2] = MworkLagRsi[_indP][_inst+1] + _gamma*(MworkLagRsi[_indP][_inst+2] - MworkLagRsi[_indC][_inst+1]);
            MworkLagRsi[_indC][_inst+3] = MworkLagRsi[_indP][_inst+2] + _gamma*(MworkLagRsi[_indP][_inst+3] - MworkLagRsi[_indC][_inst+2]);
            Val0 = MworkLagRsi[_indC][_inst];
            Val1 = MworkLagRsi[_indC][_inst+1];
            Val2 = MworkLagRsi[_indC][_inst+2];
            Val3 = MworkLagRsi[_indC][_inst+3];
            break;
         case 2:
            SworkLagRsi[_indC][_inst+4] = (smooth>1.0) ? SworkLagRsi[_indP][_inst+4] + (2.0/(1.0+smooth))*(price-SworkLagRsi[_indP][_inst+4]) : price;
            SworkLagRsi[_indC][_inst  ] = SworkLagRsi[_indC][_inst+4] + _gamma*(SworkLagRsi[_indP][_inst  ] - SworkLagRsi[_indC][_inst+4]);
            SworkLagRsi[_indC][_inst+1] = SworkLagRsi[_indP][_inst  ] + _gamma*(SworkLagRsi[_indP][_inst+1] - SworkLagRsi[_indC][_inst  ]);
            SworkLagRsi[_indC][_inst+2] = SworkLagRsi[_indP][_inst+1] + _gamma*(SworkLagRsi[_indP][_inst+2] - SworkLagRsi[_indC][_inst+1]);
            SworkLagRsi[_indC][_inst+3] = SworkLagRsi[_indP][_inst+2] + _gamma*(SworkLagRsi[_indP][_inst+3] - SworkLagRsi[_indC][_inst+2]);
            Val0 = SworkLagRsi[_indC][_inst];
            Val1 = SworkLagRsi[_indC][_inst+1];
            Val2 = SworkLagRsi[_indC][_inst+2];
            Val3 = SworkLagRsi[_indC][_inst+3];
            break;
      }
         
      
      
      if (Val0 >= Val1)    CU =  Val0 - Val1;
      else                 CD =  Val1 - Val0;
      
      if (Val1 >= Val2)    CU += Val1 - Val2;
      else                 CD += Val2 - Val1;
      
      if (Val2 >= Val3)    CU += Val2 - Val3;
      else                 CD += Val3 - Val2;
   
   } else {
      switch(velocity) {
         case 0:
            for (k=0; k<_lagRsiInstancesSize; k++) FworkLagRsi[_indC][_inst+k]=price;
            break;
         case 1:
            for (k=0; k<_lagRsiInstancesSize; k++) MworkLagRsi[_indC][_inst+k]=price;
            break;
         case 2:
            for (k=0; k<_lagRsiInstancesSize; k++) SworkLagRsi[_indC][_inst+k]=price;
            break;
      }
      
   }
   
   return((CU+CD!=0) ? CU/(CU+CD) : 0);
}

// -------------------------------


double getPrice(ENUM_APPLIED_PRICE tprice,const double &open[],const double &close[],const double &high[],const double &low[],int i)
{
   switch(tprice) {
      case PRICE_CLOSE:     return(close[i]);
      case PRICE_OPEN:      return(open[i]);
      case PRICE_HIGH:      return(high[i]);
      case PRICE_LOW:       return(low[i]);
      case PRICE_MEDIAN:    return((high[i]+low[i])/2.0);
      case PRICE_TYPICAL:   return((high[i]+low[i]+close[i])/3.0);
      case PRICE_WEIGHTED:  return((high[i]+low[i]+close[i]+close[i])/4.0);
   }

   return(0);
}

//------------------------------------------------------------------
  
bool _checkHandle(int _handle)
{
   static int _handles[];
   
   int _size = ArraySize(_handles);
          
   if (_handle!=INVALID_HANDLE) { 
      ArrayResize(_handles,_size+1); 
      _handles[_size]=_handle; 
      return(true); 
   }
   
   for (int i=_size-1; i>0; i--)
      IndicatorRelease(_handles[i]); ArrayResize(_handles,0);

   return(false);
}  

//------------------------------------------------------------------

class CEma
{
   private :
         double m_period;
         double m_alpha;
         double m_array[];
         int    m_arraySize;
   public :
      CEma() : m_period(1), m_alpha(1), m_arraySize(-1) { return; }
     ~CEma()                                            { return; }
     
     void init(int period)
      {
            m_period = (period>1) ? period : 1;
            m_alpha  = 2.0/(1.0+m_period);
      }
      double calculate(double value, int i, int bars)
      {
        if (m_arraySize<bars) {
           m_arraySize=ArrayResize(m_array,bars+500);
        
           if (m_arraySize<bars) return(0); 
        }

        if (i>0)
           m_array[i] = m_array[i-1]+m_alpha*(value-m_array[i-1]); 
        else
           m_array[i] = value;
           
        return (m_array[i]);
      }   
};
CEma _ema;

//------------------------------------------------------------------

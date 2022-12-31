//+------------------------------------------------------------------+
//|                                               NQ_EMA-Channel.mq5 |
//|                                     Copyright 2023, Neto Queiroz |
//|                                  https://github.com/Neto-Queiroz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Neto Queiroz"
#property link      "https://github.com/Neto-Queiroz"
#property version   "1.00"
//+------------------------------------------------------------------+

#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   3

#property indicator_label1  "Middle EMA"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrNONE,clrDeepSkyBlue,clrOrange
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_label2  "High EMA"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrGray
#property indicator_style2  STYLE_DOT
#property indicator_width2  1

#property indicator_label3  "Low EMA"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrGray
#property indicator_style3  STYLE_DOT
#property indicator_width3  1

//+------------------------------------------------------------------+

input int inpPeriod = 48;

//+------------------------------------------------------------------+

double valx[], valxc[], valy[], valz[];

//+------------------------------------------------------------------+

datetime Ytime, Ztime;
double valY = 0, valZ = 0;
bool Ystate = false;
bool Zstate = false;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer( 0,valx,  INDICATOR_DATA);
   SetIndexBuffer( 1,valxc, INDICATOR_COLOR_INDEX);
   SetIndexBuffer( 2,valy,  INDICATOR_DATA);
   SetIndexBuffer( 3,valz,  INDICATOR_DATA);

   _ema.init(inpPeriod);

   IndicatorSetString(INDICATOR_SHORTNAME,"EMA Channel");
   return (INIT_SUCCEEDED);
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
   int i=prev_calculated-1; if(i<0) i=0; for(; i<rates_total && !_StopFlag; i++)
     {
      valx[i]  = _ema.calcX(((high[i]+low[i])/2.0),i,rates_total);
      valxc[i] = (i>0) ? (valx[i]>valx[i-1]) ? 1 : (valx[i]<valx[i-1]) ? 2 : valxc[i-1] : 0;

      valy[i]  = _ema.calcY(high[i],i,rates_total);

      valz[i]  = _ema.calcZ(low[i],i,rates_total);

      if(close[i] > valy[i] && !Ystate)
        {
         Ytime = time[i];
         valY = high[i];
         Ystate = true;
         Zstate = false;
        }

      if(close[i] < valz[i] && !Zstate)
        {
         Ztime = time[i];
         valZ = low[i];
         Zstate = true;
         Ystate = false;
        }

      if(Ystate)
        {
         _srHandler.update(valY,time[i],1,i,rates_total);
        }
      else
         if(Zstate)
           {
            _srHandler.update(valZ,time[i],2,i,rates_total);
           }
     }

   return(rates_total);
  }

//+------------------------------------------------------------------+

class CEma
  {
private :
   double            m_period;
   double            m_alpha;
   double            m_arrayX[];
   double            m_arrayY[];
   double            m_arrayZ[];
   int               m_arrayXSize;
   int               m_arrayYSize;
   int               m_arrayZSize;

public :
   CEma() : m_period(1), m_alpha(1), m_arrayXSize(-1), m_arrayYSize(-1), m_arrayZSize(-1) { return; }
   ~CEma() { return; }

   void init(int period)
     {
      m_period = (period>1) ? period : 1;
      m_alpha  = 2.0/(1.0+m_period);
     }

   double calcX(double value, int i, int bars)
     {
      if(m_arrayXSize<bars)
        {
         m_arrayXSize=ArrayResize(m_arrayX,bars+500);
         if(m_arrayXSize<bars)
            return(0);
        }

      if(i>0)
         m_arrayX[i] = m_arrayX[i-1]+m_alpha*(value-m_arrayX[i-1]);
      else
         m_arrayX[i] = value;

      return (m_arrayX[i]);
     }

   double calcY(double value, int i, int bars)
     {
      if(m_arrayYSize<bars)
        {
         m_arrayYSize=ArrayResize(m_arrayY,bars+500);
         if(m_arrayYSize<bars)
            return(0);
        }

      if(i>0)
         m_arrayY[i] = m_arrayY[i-1]+m_alpha*(value-m_arrayY[i-1]);
      else
         m_arrayY[i] = value;

      return (m_arrayY[i]);
     }

   double calcZ(double value, int i, int bars)
     {
      if(m_arrayZSize<bars)
        {
         m_arrayZSize=ArrayResize(m_arrayZ,bars+500);
         if(m_arrayZSize<bars)
            return(0);
        }

      if(i>0)
         m_arrayZ[i] = m_arrayZ[i-1]+m_alpha*(value-m_arrayZ[i-1]);
      else
         m_arrayZ[i] = value;

      return (m_arrayZ[i]);
     }
  };
CEma _ema;

//+------------------------------------------------------------------+

class SRonChart
  {
private :
   string            m_uniqueID;
   color             m_colorSup;
   color             m_colorRes;
   int               m_linesWidth;
   int               m_linesStyle;
   int               m_arraySize;
   struct sOnChartSRStruct
     {
      datetime       time;
      double         state;
     };
   sOnChartSRStruct  m_array[];

public :
   SRonChart() : m_colorSup(clrOrangeRed), m_colorRes(clrMediumSeaGreen), m_linesWidth(1), m_linesStyle(STYLE_DOT), m_arraySize(-1) { return; }
   ~SRonChart() { ObjectsDeleteAll(0,m_uniqueID+":"); ChartRedraw(0); return; }

   void setUniqueID(string _id)          { m_uniqueID = _id; return; }
   void setSupportColor(color _color)    { m_colorSup = _color; return; }
   void setResistanceColor(color _color) { m_colorRes = _color; return; }
   void setLinesWidth(int _width)        { m_linesWidth = _width; return; }
   void setLinesStyle(int _style)        { m_linesStyle = _style; return; }
   
   void update(double price, datetime time, double state, int i, int bars)
     {
      if(m_arraySize<bars)
        {
         m_arraySize = ArrayResize(m_array,bars+500);
         if(m_arraySize<bars)
            return;
        }

      m_array[i].state = state;

      if(i>0)
        {
         if(m_array[i].state!=m_array[i-1].state)
           {
            m_array[i].time = time;

            if(m_array[i].state!=0)
              {
               string _name = m_uniqueID+":"+(string)time;

               ObjectCreate(0,_name,OBJ_TREND,0,0,0);
               ObjectSetInteger(0,_name,OBJPROP_WIDTH,m_linesWidth);
               ObjectSetInteger(0,_name,OBJPROP_STYLE,m_linesStyle);
               ObjectSetInteger(0,_name,OBJPROP_COLOR,(state==1 ? m_colorRes : m_colorSup));
               ObjectSetInteger(0,_name,OBJPROP_HIDDEN,true);
               ObjectSetInteger(0,_name,OBJPROP_BACK,true);
               ObjectSetInteger(0,_name,OBJPROP_SELECTABLE,false);
               ObjectSetInteger(0,_name,OBJPROP_RAY,false);
               ObjectSetInteger(0,_name,OBJPROP_TIME,0,time);
               ObjectSetInteger(0,_name,OBJPROP_TIME,1,time+PeriodSeconds(_Period));
               ObjectSetDouble(0,_name,OBJPROP_PRICE,0,price);
               ObjectSetDouble(0,_name,OBJPROP_PRICE,1,price);
              }
           }
         else
           {
            m_array[i].time = m_array[i-1].time;

            string _name = m_uniqueID+":"+(string)m_array[i].time;

            if(m_array[i].state!=0)
               ObjectSetInteger(0,_name,OBJPROP_TIME,1,time+PeriodSeconds(_Period));
            else
               if(ObjectFind(0,_name)>=0)
                  ObjectDelete(0,_name);
           }
        }
      else
         m_array[i].time = time;
     }
  };
SRonChart _srHandler;
//+------------------------------------------------------------------+

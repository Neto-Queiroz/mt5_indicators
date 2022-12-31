//+------------------------------------------------------------------+
//|                                                 Flow-n-Force.mq5 |
//|                                     Copyright 2023, Neto Queiroz |
//|                                  https://github.com/Neto-Queiroz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Neto Queiroz"
#property link      "https://github.com/Neto-Queiroz"
#property version   "1.00"
//+------------------------------------------------------------------+

#property indicator_separate_window
#property indicator_buffers    7
#property indicator_plots      2

#property indicator_label1     "Flow"
#property indicator_type1      DRAW_COLOR_HISTOGRAM
#property indicator_color1     clrYellow,clrDarkGreen,clrMaroon
#property indicator_width1     2

#property indicator_label2     "Force"
#property indicator_type2      DRAW_LINE
#property indicator_color2     clrYellow
#property indicator_width2     1

//+------------------------------------------------------------------+

#property indicator_maximum    100.0
#property indicator_minimum    -100.0

#property indicator_level1     40.0
#property indicator_level2     -40.0

#property indicator_levelcolor Silver
#property indicator_levelstyle 2
#property indicator_levelwidth 1

//+------------------------------------------------------------------+

input ENUM_APPLIED_VOLUME InpVolumeType = VOLUME_REAL;  // Applied Volume
input group "FLOW"
input int                 InpFastPeriod = 5;            // Fast Period
input int                 InpSlowPeriod = 55;           // Slow Period
input group "FORCE"
input int                 InpRSIPeriod  = 14;           // Period

//+------------------------------------------------------------------+

double HistogramBuffer[];
double HistogramColor[];
double ExtRSIBuffer[];

double ExtFastBuffer[];
double ExtSlowBuffer[];
double ExtPosBuffer[];
double ExtNegBuffer[];

//+------------------------------------------------------------------+

int    ExtFastPeriod;
int    ExtSlowPeriod;
int    ExtRSIPeriod;

string         prefix;

//+------------------------------------------------------------------+

void OnInit()
{
   prefix=MQLInfoString(MQL_PROGRAM_NAME)+"_";
      
   if(InpFastPeriod<=0) {
      ExtFastPeriod=5;
   } else ExtFastPeriod=InpFastPeriod;

   if(InpSlowPeriod<=ExtFastPeriod) {
      ExtSlowPeriod=ExtFastPeriod*2;
   } else ExtSlowPeriod=InpSlowPeriod;
   
   if(InpRSIPeriod < 1) {
      ExtRSIPeriod = 14;
   } else ExtRSIPeriod = InpRSIPeriod;

   SetIndexBuffer( 0,HistogramBuffer,INDICATOR_DATA);
   SetIndexBuffer( 1,HistogramColor, INDICATOR_COLOR_INDEX);
   SetIndexBuffer( 2,ExtRSIBuffer,   INDICATOR_DATA);
   SetIndexBuffer( 3,ExtFastBuffer,  INDICATOR_CALCULATIONS);
   SetIndexBuffer( 4,ExtSlowBuffer,  INDICATOR_CALCULATIONS);
   SetIndexBuffer( 5,ExtPosBuffer,   INDICATOR_CALCULATIONS);
   SetIndexBuffer( 6,ExtNegBuffer,   INDICATOR_CALCULATIONS);

   IndicatorSetString(INDICATOR_SHORTNAME,"Flow'n'Force");
   for(int i=0;i<2;i++)
      PlotIndexSetInteger(i,PLOT_SHOW_DATA,false);

   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,ExtRSIPeriod);

   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
}

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
   if(rates_total<ExtSlowPeriod) return(0);
   if(rates_total<=ExtRSIPeriod) return(0);

   int start_Fposition;
   int start_Sposition;
   
   int pos=prev_calculated-1;

   if(prev_calculated<ExtFastPeriod)   start_Fposition=ExtFastPeriod;
   else                                start_Fposition=prev_calculated-1;
   
   if(prev_calculated<ExtSlowPeriod)   start_Sposition=ExtSlowPeriod;
   else                                start_Sposition=prev_calculated-1;
     
   if(pos<=ExtRSIPeriod) {
      double sum_pos=0.0;
      double sum_neg=0.0;

      ExtRSIBuffer[0]=0.0;
      ExtPosBuffer[0]=0.0;
      ExtNegBuffer[0]=0.0;

      for(int i=1; i<=ExtRSIPeriod; i++) {
         ExtRSIBuffer[i]=0.0;
         ExtPosBuffer[i]=0.0;
         ExtNegBuffer[i]=0.0;
         
         double price1 = TypicalPrice(high[i],low[i],close[i]);
         double price2 = TypicalPrice(high[i-1],low[i-1],close[i-1]);
         double diff=price1-price2;
         
         sum_pos+=(diff>0?diff:0);
         sum_neg+=(diff<0?-diff:0);
      }
      
      ExtPosBuffer[ExtRSIPeriod]=sum_pos/ExtRSIPeriod;
      ExtNegBuffer[ExtRSIPeriod]=sum_neg/ExtRSIPeriod;
      
      if(ExtNegBuffer[ExtRSIPeriod]!=0.0) {
         double value = 100.0-(100.0/(1.0+ExtPosBuffer[ExtRSIPeriod]/ExtNegBuffer[ExtRSIPeriod]));
         ExtRSIBuffer[ExtRSIPeriod]= value - (value-100);
      } else {
         if(ExtPosBuffer[ExtRSIPeriod]!=0.0)
            ExtRSIBuffer[ExtRSIPeriod]=100.0;
         else
            ExtRSIBuffer[ExtRSIPeriod]=0.0;
      }

      pos=ExtRSIPeriod+1;
   } 

   if(InpVolumeType==VOLUME_TICK) {
      CalculateFast(start_Fposition,rates_total,high,low,close,tick_volume);
      CalculateSlow(start_Sposition,rates_total,high,low,close,tick_volume);
   } else {
      CalculateFast(start_Fposition,rates_total,high,low,close,volume);
      CalculateSlow(start_Sposition,rates_total,high,low,close,volume);
   }
   
   for(int i=start_Sposition; i<rates_total && !IsStopped(); i++) {
      HistogramBuffer[i] = ExtFastBuffer[i] - ExtSlowBuffer[i];
      HistogramColor[i] = (HistogramBuffer[i]>0) ? 1 : (HistogramBuffer[i]<0) ? 2 : 0;
      
      if(i>4) {        
         if(HistogramBuffer[i-2] > HistogramBuffer[i-3]) ObjectSetInteger(0,prefix+"label0_val1",OBJPROP_COLOR,clrGreen);
         else if(HistogramBuffer[i-2] < HistogramBuffer[i-3]) ObjectSetInteger(0,prefix+"label0_val1",OBJPROP_COLOR,clrRed);
         else ObjectSetInteger(0,prefix+"label0_val1",OBJPROP_COLOR,clrYellow);
         
         if(HistogramBuffer[i-1] > HistogramBuffer[i-2]) ObjectSetInteger(0,prefix+"label0_val2",OBJPROP_COLOR,clrGreen);
         else if(HistogramBuffer[i-1] < HistogramBuffer[i-2]) ObjectSetInteger(0,prefix+"label0_val2",OBJPROP_COLOR,clrRed);
         else ObjectSetInteger(0,prefix+"label0_val2",OBJPROP_COLOR,clrYellow);
         
         if(HistogramBuffer[i] > HistogramBuffer[i-1]) ObjectSetInteger(0,prefix+"label0_val3",OBJPROP_COLOR,clrGreen);
         else if(HistogramBuffer[i] < HistogramBuffer[i-1]) ObjectSetInteger(0,prefix+"label0_val3",OBJPROP_COLOR,clrRed);
         else ObjectSetInteger(0,prefix+"label0_val3",OBJPROP_COLOR,clrYellow);
      }
   }
   
   for(int i=pos; i<rates_total && !IsStopped(); i++) {
      double price1 = TypicalPrice(high[i],low[i],close[i]);
      double price2 = TypicalPrice(high[i-1],low[i-1],close[i-1]);
      double diff=price1-price2;
      
      ExtPosBuffer[i]=(ExtPosBuffer[i-1]*(ExtRSIPeriod-1)+(diff>0.0?diff:0.0))/ExtRSIPeriod;
      ExtNegBuffer[i]=(ExtNegBuffer[i-1]*(ExtRSIPeriod-1)+(diff<0.0?-diff:0.0))/ExtRSIPeriod;
      
      if(ExtNegBuffer[i]!=0.0) {
         double value = 100.0-100.0/(1+ExtPosBuffer[i]/ExtNegBuffer[i]);
         ExtRSIBuffer[i]= value + (value-100);
      } else {
         if(ExtPosBuffer[i]!=0.0)
            ExtRSIBuffer[i]=100.0;
         else
            ExtRSIBuffer[i]=0.0;
      }
      
      if(i>4) {  
         if(ExtRSIBuffer[i-2] > ExtRSIBuffer[i-3]) ObjectSetInteger(0,prefix+"label1_val1",OBJPROP_COLOR,clrGreen);
         else if(ExtRSIBuffer[i-2] < ExtRSIBuffer[i-3]) ObjectSetInteger(0,prefix+"label1_val1",OBJPROP_COLOR,clrRed);
         else ObjectSetInteger(0,prefix+"label1_val1",OBJPROP_COLOR,clrYellow);
         
         if(ExtRSIBuffer[i-1] > ExtRSIBuffer[i-2]) ObjectSetInteger(0,prefix+"label1_val2",OBJPROP_COLOR,clrGreen);
         else if(ExtRSIBuffer[i-1] < ExtRSIBuffer[i-2]) ObjectSetInteger(0,prefix+"label1_val2",OBJPROP_COLOR,clrRed);
         else ObjectSetInteger(0,prefix+"label1_val2",OBJPROP_COLOR,clrYellow);
         
         if(ExtRSIBuffer[i] > ExtRSIBuffer[i-1]) ObjectSetInteger(0,prefix+"label1_val3",OBJPROP_COLOR,clrGreen);
         else if(ExtRSIBuffer[i] < ExtRSIBuffer[i-1]) ObjectSetInteger(0,prefix+"label1_val3",OBJPROP_COLOR,clrRed);
         else ObjectSetInteger(0,prefix+"label1_val3",OBJPROP_COLOR,clrYellow);
      }
   }

   return(rates_total);
}

//+------------------------------------------------------------------+

void CalculateFast(const int start_position,
                  const int rates_total,
                  const double &high[],
                  const double &low[],
                  const double &close[],
                  const long &volume[])
{
   for(int i=start_position; i<rates_total && !IsStopped(); i++) {
      double positive=0.0;
      double negative=0.0;
      double current_tp=TypicalPrice(high[i],low[i],close[i]);
      
      for(int j=1; j<=ExtFastPeriod; j++) {
         int    index=i-j;
         double previous_tp=TypicalPrice(high[index],low[index],close[index]);
         
         if(current_tp>previous_tp)
            positive+=volume[index+1]*current_tp;
         
         if(current_tp<previous_tp)
            negative+=volume[index+1]*current_tp;
         
         current_tp=previous_tp;
      }
      
      if(negative!=0.0)
         ExtFastBuffer[i]=100.0-100.0/(1+positive/negative);
      else
         ExtFastBuffer[i]=100.0;
   }
}

//+------------------------------------------------------------------+

void CalculateSlow(const int start_position,
                  const int rates_total,
                  const double &high[],
                  const double &low[],
                  const double &close[],
                  const long &volume[])
{
   for(int i=start_position; i<rates_total && !IsStopped(); i++) {
      double positive=0.0;
      double negative=0.0;
      double current_tp=TypicalPrice(high[i],low[i],close[i]);
      
      for(int j=1; j<=ExtSlowPeriod; j++) {
         int    index=i-j;
         double previous_tp=TypicalPrice(high[index],low[index],close[index]);
      
         if(current_tp>previous_tp)
            positive+=volume[index+1]*current_tp;
      
         if(current_tp<previous_tp)
            negative+=volume[index+1]*current_tp;
      
         current_tp=previous_tp;
      }
      
      if(negative!=0.0)
         ExtSlowBuffer[i]=100.0-100.0/(1+positive/negative);
      else
         ExtSlowBuffer[i]=100.0;
   }
}

//+------------------------------------------------------------------+

double TypicalPrice(const double high_price,const double low_price,const double close_price)
{
   return((high_price+low_price+close_price)/3.0);
}

//+------------------------------------------------------------------+

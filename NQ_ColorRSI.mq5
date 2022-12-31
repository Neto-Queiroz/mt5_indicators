//+------------------------------------------------------------------+
//|                                                  NQ_ColorRSI.mq5 |
//|                                     Copyright 2023, Neto Queiroz |
//|                                  https://github.com/Neto-Queiroz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Neto Queiroz"
#property link      "https://github.com/Neto-Queiroz"
#property version   "1.00"
//+------------------------------------------------------------------+

#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   1

#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrYellow,clrDarkGreen,clrMaroon
#property indicator_width1  2

//+------------------------------------------------------------------+

#property indicator_minimum 0
#property indicator_maximum 100

//+------------------------------------------------------------------+

input int                InpPeriodRSI         = 7;            // Period
input double             LevelUp              = 78;           // Level up
input double             LevelDown            = 22;           // Level down

//+------------------------------------------------------------------+

double    ExtRSIBuffer[];
double    ColorBuffer[];
double    ExtPosBuffer[];
double    ExtNegBuffer[];

//+------------------------------------------------------------------+

int       ExtPeriodRSI;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpPeriodRSI<1) {
      ExtPeriodRSI=7;
      PrintFormat("Incorrect value for input variable InpPeriodRSI = %d. Indicator will use value %d for calculations.",InpPeriodRSI,ExtPeriodRSI);
   } else ExtPeriodRSI=InpPeriodRSI;
   
   SetIndexBuffer( 0,ExtRSIBuffer,  INDICATOR_DATA);
   SetIndexBuffer( 1,ColorBuffer,   INDICATOR_COLOR_INDEX);
   SetIndexBuffer( 2,ExtPosBuffer,  INDICATOR_CALCULATIONS);
   SetIndexBuffer( 3,ExtNegBuffer,  INDICATOR_CALCULATIONS);
   
   IndicatorSetInteger(INDICATOR_LEVELS,3);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,LevelUp);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,50);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,2,LevelDown);

   IndicatorSetInteger(INDICATOR_DIGITS,2);

   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtPeriodRSI);

   IndicatorSetString(INDICATOR_SHORTNAME,"Color RSI");
   for (int i=0;i<1;i++) PlotIndexSetInteger(i,PLOT_SHOW_DATA,false);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
{
   if(rates_total<=ExtPeriodRSI) return(0);

   int pos=prev_calculated-1;

   if(pos<=ExtPeriodRSI) {
      double sum_pos=0.0;
      double sum_neg=0.0;

      ExtRSIBuffer[0]=0.0;
      ExtPosBuffer[0]=0.0;
      ExtNegBuffer[0]=0.0;

      for(int i=1; i<=ExtPeriodRSI; i++) {
         ExtRSIBuffer[i]=0.0;
         ExtPosBuffer[i]=0.0;
         ExtNegBuffer[i]=0.0;
         
         double diff=price[i]-price[i-1];
         
         sum_pos+=(diff>0?diff:0);
         sum_neg+=(diff<0?-diff:0);
      }

      ExtPosBuffer[ExtPeriodRSI]=sum_pos/ExtPeriodRSI;
      ExtNegBuffer[ExtPeriodRSI]=sum_neg/ExtPeriodRSI;
      
      if(ExtNegBuffer[ExtPeriodRSI]!=0.0) {
         ExtRSIBuffer[ExtPeriodRSI]=100.0-(100.0/(1.0+ExtPosBuffer[ExtPeriodRSI]/ExtNegBuffer[ExtPeriodRSI]));
      } else {
         if(ExtPosBuffer[ExtPeriodRSI]!=0.0)
            ExtRSIBuffer[ExtPeriodRSI]=100.0;
         else
            ExtRSIBuffer[ExtPeriodRSI]=50.0;
      }

      pos=ExtPeriodRSI+1;
   }

   for(int i=pos; i<rates_total && !IsStopped(); i++) {
      double diff=price[i]-price[i-1];
      
      ExtPosBuffer[i]=(ExtPosBuffer[i-1]*(ExtPeriodRSI-1)+(diff>0.0?diff:0.0))/ExtPeriodRSI;
      ExtNegBuffer[i]=(ExtNegBuffer[i-1]*(ExtPeriodRSI-1)+(diff<0.0?-diff:0.0))/ExtPeriodRSI;
      
      if(ExtNegBuffer[i]!=0.0) {
         ExtRSIBuffer[i]=100.0-100.0/(1+ExtPosBuffer[i]/ExtNegBuffer[i]);
      } else {
         if(ExtPosBuffer[i]!=0.0)
            ExtRSIBuffer[i]=100.0;
         else
            ExtRSIBuffer[i]=50.0;
      }
        
      if(ExtRSIBuffer[i]>50) {
         ColorBuffer[i] = 1;
         if(ExtRSIBuffer[i]>LevelUp) ColorBuffer[i] = 0;
      } else if(ExtRSIBuffer[i]<50) {
         ColorBuffer[i] = 2;
         if(ExtRSIBuffer[i]<LevelDown) ColorBuffer[i] = 0;
      }
   }

   return(rates_total);
}
//+------------------------------------------------------------------+

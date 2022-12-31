//+------------------------------------------------------------------+
//|                                                  NQ_CaixxaV3.mq5 |
//|                                     Copyright 2023, Neto Queiroz |
//|                                  https://github.com/Neto-Queiroz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Neto Queiroz"
#property link      "https://github.com/Neto-Queiroz"
#property version   "1.00"
//+------------------------------------------------------------------+

#include <MovingAverages.mqh>

//+------------------------------------------------------------------+

#property indicator_separate_window

#property indicator_buffers 1
#property indicator_plots   1

#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed

//+------------------------------------------------------------------+

input int            Processed         = 2000;
input int            Control_Period    = 14;

input double         levelOb           = 6;
input double         levelOs           = -6;

//+------------------------------------------------------------------+

double values[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0, values,  INDICATOR_DATA);
   
   ArraySetAsSeries(values,true);
   
   IndicatorSetInteger(INDICATOR_LEVELS,2);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,levelOb);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,levelOs);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,0,clrDarkOrange);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,1,clrDarkOrange);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,0,STYLE_SOLID);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,1,STYLE_SOLID);
   
   IndicatorSetString(INDICATOR_SHORTNAME,"Caixxa V3");
   for (int i=0;i<1;i++) PlotIndexSetInteger(i,PLOT_SHOW_DATA,false);

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
   datetime    bar_time;
   int         idx, counter, offset, bar_shift, bar_cont;
   double      price_high, price_close, price_low, trigger_high, trigger_low;
   double      sum_up, sum_dn, complex_up, complex_dn;
   
   int counted = prev_calculated;
   
   if (counted < 0) return (-1);
   if (counted > 0) counted--;
   int limit = rates_total - counted;
   if (limit > Processed) limit = Processed;
   
   for (idx = limit; idx >= 0; idx--) {  // idx vai de 2000 a 0
      PrintFormat("IDX: %i / Limit: %i", idx, limit);
      counter = 0;
    
	   complex_up = 0;
	   complex_dn = 0;
    
	   trigger_high = -999999;
	   trigger_low  = 999999;

      while (counter < Control_Period) {  // Counter vai de 0 a 13
         PrintFormat("-- Counter: %i / Control Period: %i", counter, Control_Period);
		   sum_up = 0;
		   sum_dn = 0;
         
		   offset = idx + counter;
		   
		   bar_time = iTime(_Symbol, 0, offset);
		   bar_shift = iBarShift(_Symbol, PERIOD_CURRENT, bar_time, false);
		   bar_cont = bar_shift - Period();
		   
		   if (bar_cont < 0) bar_cont = 0;
         
		   for (int jdx = bar_shift; jdx >= bar_cont; jdx--) {   
			   price_high  = iHigh(Symbol(), 0, jdx); 
			   price_close = iClose(Symbol(), 0, jdx); 
			   price_low   = iLow(Symbol(), 0, jdx);
		
			   if (price_high > trigger_high) {
				   trigger_high = price_high;
				   sum_up += price_close;
			   }

			   if (price_low  < trigger_low ) {
				   trigger_low  = price_low;
				   sum_dn += price_close;
			   }
		   }
     
		   counter++;

		   complex_up += sum_up;
		   complex_dn += sum_dn;        
      }
	
      if (complex_dn != 0.0 && complex_up != 0.0) {
		   values[idx] = (complex_dn / complex_up) - (complex_up / complex_dn);
		}
   }
  
   return(rates_total);
  }
//+------------------------------------------------------------------+

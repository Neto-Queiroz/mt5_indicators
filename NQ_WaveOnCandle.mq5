//+------------------------------------------------------------------+
//|                                              NQ_WaveOnCandle.mq5 |
//|                                     Copyright 2023, Neto Queiroz |
//|                                  https://github.com/Neto-Queiroz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Neto Queiroz"
#property link      "https://github.com/Neto-Queiroz"
#property version   "1.00"
//+------------------------------------------------------------------+

#property indicator_chart_window
#property indicator_buffers 9
#property indicator_plots 1

#property indicator_label1 "Candle"
#property indicator_type1 DRAW_COLOR_CANDLES

//+------------------------------------------------------------------+

#property indicator_minimum 0 

//+------------------------------------------------------------------+

color ExtColor[5]={clrYellow,clrGreen,clrPaleGreen,clrSalmon,clrCrimson};

//+------------------------------------------------------------------+

enum ENUM_DISPLAY_DATA
{
   total_volume,  // Total Volume Wave
   range,         // Range Wave
   Average        // Average Volume
};

//+------------------------------------------------------------------+

input ENUM_DISPLAY_DATA    SubDisplayType = total_volume;
input ENUM_APPLIED_VOLUME  InpVolumeType  = VOLUME_TICK;    // Volume Type
input int                  Direction      = 15;             // Wave Tick´s
input int                  Percent        = 50;             // Percentage of Bar´s
input color                Up             = clrAqua;        // Up Wave Color
input color                Dn             = clrRed;         // Donw Wave Color

//+------------------------------------------------------------------+

double ExtOpenBuffer[], ExtHighBuffer[], ExtLowBuffer[], ExtCloseBuffer[], ExtColorsBuffer[], HistoBuffer[];
double RangeC[], Xtrend[], Ytrend[], bufferWW[];
int    Ext[];

//+------------------------------------------------------------------+

int    BarStarting, PercentTrue;
double tick;

int    trend     = 0;
int    MinIndex  = 1;
int    MaxIndex  = 1;
int    LastIndex = 1;
double Cumulated = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0,ExtOpenBuffer   ,INDICATOR_DATA);
   SetIndexBuffer(1,ExtHighBuffer   ,INDICATOR_DATA);
   SetIndexBuffer(2,ExtLowBuffer    ,INDICATOR_DATA);
   SetIndexBuffer(3,ExtCloseBuffer  ,INDICATOR_DATA);
   SetIndexBuffer(4,ExtColorsBuffer ,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(5,HistoBuffer     ,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,bufferWW        ,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,Xtrend          ,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,Ytrend          ,INDICATOR_CALCULATIONS);

   PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,5);
   
   for(int i=0; i<5; i++)
      PlotIndexSetInteger(0,PLOT_LINE_COLOR,i,ExtColor[i]);

   if (SymbolInfoDouble( _Symbol, SYMBOL_TRADE_TICK_SIZE )> 1) {
      tick = Direction * SymbolInfoDouble( _Symbol, SYMBOL_TRADE_TICK_SIZE );
   } else {
      tick = Direction * (SymbolInfoDouble( _Symbol, SYMBOL_TRADE_TICK_SIZE )*1000);
   }
   
   if (SymbolInfoDouble( _Symbol, SYMBOL_TRADE_TICK_SIZE) == 1e-05)
      tick = Direction;

   if (Percent > 100 || Percent < 0 ) {
      PercentTrue = 50;
      Alert ( " Percentage of Bar´s out Of Range, Select 1..100% ");
   } else PercentTrue = Percent;


   IndicatorSetInteger(INDICATOR_DIGITS,0);

   IndicatorSetString(INDICATOR_SHORTNAME,"Wave");

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
   if (true) {
      ArrayResize(Ext, rates_total+1);
      ArrayResize(RangeC, rates_total+1);
      
      int i, barsToProcess, shouldStartIn = 2;
      if (rates_total < shouldStartIn)  { return 0; }
      
      double vol;
      
      if (prev_calculated == 0 || rates_total > prev_calculated+1) {
         bufferWW[0] = ( InpVolumeType==VOLUME_TICK ? (double)tick_volume[0] : (double)volume[0] );
         barsToProcess = rates_total;
      } else {
         barsToProcess = (rates_total-prev_calculated) + 1;
      }
      
      for (i=rates_total-MathMax(shouldStartIn,barsToProcess-shouldStartIn);  i<rates_total && !IsStopped();  i++)  {
         vol = ( InpVolumeType==VOLUME_TICK ? (double)tick_volume[i] : (double)volume[i] );   // type casts to the correct format of the buffer...

         if (close[i] >= close[i-1]) {      // Closing UP?
            if (close[i-1]>=close[i-2]) {  // continuing closing UP?
                bufferWW[i]     = bufferWW[i-1] + vol;
                Ytrend[i] = 0;
            } else {                       // no? resets the volume...
                bufferWW[i]     = vol;
                Ytrend[i] = 0;
            }
         } else {                           // Closing DOWN ?
            if (close[i-1]<close[i-2]) {   // continuing closing DOWN?
                bufferWW[i]     = bufferWW[i-1] + vol;
                Ytrend[i] = 1;
            } else {                       // no? resets the volume...
                bufferWW[i]     = vol;
                Ytrend[i] = 1;
            }
         }       
      }
      
      for (i=0; i<rates_total; i++) {
         Ext[i] = 0;
         HistoBuffer[i] = 0;
         RangeC[i] = 0;
      }

      GetExtremumsByClose(rates_total, close);

      BarStarting = (rates_total) - (rates_total *PercentTrue)/100;

      for (i=BarStarting; i<rates_total; i++) {
         ExtOpenBuffer[i]=open[i];
         ExtHighBuffer[i]=high[i];
         ExtLowBuffer[i]=low[i];
         ExtCloseBuffer[i]=close[i];
         
         ExtColorsBuffer[i] = 0;
      
         Cumulated = 0; 
         
         if (SubDisplayType==total_volume)
            if(InpVolumeType==VOLUME_TICK) 
               for (int j=LastIndex+1; j<=i; j++)
                  Cumulated += (double)tick_volume[j];

            else
               for (int j=LastIndex+1; j<=i; j++)
                  Cumulated += (double)volume[j];
         else if (SubDisplayType==range){
            RangeC[i]=(double)(long)MathAbs((close[i] - close[LastIndex])/_Point + 1);
            Cumulated=RangeC[i]=(i-LastIndex);

         } else if (SubDisplayType==Average)
            for (int j=LastIndex+1; j<=i; j++)
               Cumulated += (double)tick_volume[j]/(i-LastIndex);

         else
            for (int j=LastIndex+1; j<=i; j++)
               Cumulated += (double)volume[j]/ (i-LastIndex);

         HistoBuffer[i] = Cumulated;

         if (Ext[LastIndex] == 1)
            Xtrend[i] = 0;
         else 
            Xtrend[i] = 1;

         if (Ext[i]!=0)
            LastIndex = i;
            
         if (Xtrend[i] == 1) {
            ExtColorsBuffer[i] = (Ytrend[i] == 1) ? 2 : (Ytrend[i] == 0) ? 1 : 0;
         } else if (Xtrend[i] == 0) {
            ExtColorsBuffer[i] = (Ytrend[i] == 1) ? 4 : (Ytrend[i] == 0) ? 3 : 0;
         }
      }
   }
   
   return(rates_total);
  }
//+------------------------------------------------------------------+

void GetExtremumsByClose(const int rates_total,
const double &close[])
{
   LastIndex = 1;
   MinIndex=1;
   MaxIndex=1;
   BarStarting = (rates_total) - (rates_total * PercentTrue)/100;
   
   for (int i=BarStarting; i<rates_total; i++) {
      if (close[i] > close[MaxIndex])
         MaxIndex = i;

      if (close[i] < close[MinIndex])
         MinIndex = i;

      if ((close[MaxIndex] - close[i])>(tick*_Point))
         if ((close[MaxIndex] - close[LastIndex]) > (tick*_Point)) {
            if (trend == 1)
               Ext[MinIndex] = -1;

            Ext[MaxIndex] = 1;
            LastIndex = MaxIndex;
            MinIndex = i;
            trend = 1;
            
            continue;
         }

         if ((close[i] - close[MinIndex])>(tick*_Point))
            if ((close[LastIndex] - close[MinIndex]) > (tick*_Point)) {
               if (trend == -1)
                  Ext[MaxIndex] = 1;

               Ext[MinIndex] = -1;
               LastIndex = MinIndex;
               MaxIndex = i;
               trend = -1;

               continue;
            }
   }
}

//+------------------------------------------------------------------+
//|                                             Distance from MA.mq5 |
//|                                Copyright 2019, Leonardo Sposina. |
//|           https://www.mql5.com/en/users/leonardo_splinter/seller |
//+------------------------------------------------------------------+

#include "MovingAverage.mqh"
#include "ColorHistogram.mqh"
#include "AverageLevel.mqh"

enum ENUM_COUNT_DAYS {
  today       = 0,  // today
  one_day     = 1,  // today + yesterday
  two_days    = 2,  // today + past 2 days
  three_days  = 3,  // today + past 3 days
  four_days   = 4,  // today + past 4 days
  five_days   = 5,  // today + past 5 days
  six_days    = 6,  // today + past 6 days
};

input group "-=[ Moving Average ]=-";
input int MA_Period = 20;                   // Moving average period
input ENUM_MA_METHOD MA_Method = MODE_SMA;  // Moving average method
input group "-=[ Average Distance ]=-";
input ENUM_COUNT_DAYS AD_Period = 1;        // Average distance calculation period

ColorHistogram* colorHistogram;
MovingAverage* movingAverage;

MqlDateTime candleDatetime, currentDatetime;

int OnInit() {
  colorHistogram = new ColorHistogram(0, 1);
  movingAverage = new MovingAverage(2, MA_Period, MA_Method);

  string indicatorLabel = StringFormat("Distance from %s(%d)", enumMAMethodToString(MA_Method), MA_Period);

  PlotIndexSetString(0, PLOT_LABEL, indicatorLabel);
  IndicatorSetString(INDICATOR_SHORTNAME, indicatorLabel);
  IndicatorSetInteger(INDICATOR_LEVELS, 2);

  return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
  delete colorHistogram;
  delete movingAverage;
  ChartRedraw();
}

int OnCalculate(
  const int rates_total,
  const int prev_calculated,
  const datetime &time[],
  const double &open[],
  const double &high[],
  const double &low[],
  const double &close[],
  const long &tick_volume[],
  const long &volume[],
  const int &spread[]
) {

  if (movingAverage.update(rates_total) && !IsStopped()) {
    AverageLevel averageDistanceAbove(0, "Average distance above");
    AverageLevel averageDistanceBelow(1, "Average distance below");

    TimeCurrent(currentDatetime);

    for (int i = 0; i < rates_total; i++) {
      double movingAverageValue = movingAverage.getvalue(i);
      double highDiff = MathAbs(movingAverageValue - high[i]);
      double lowDiff = MathAbs(movingAverageValue - low[i]);

      TimeToStruct(time[i], candleDatetime);
      
      if (highDiff >= lowDiff && high[i] > movingAverageValue) {
        colorHistogram.setValue(i, highDiff);

        if (isWithinPeriod(candleDatetime, currentDatetime))
          averageDistanceAbove.push(highDiff);

      } else if (highDiff <= lowDiff && low[i] < movingAverageValue) {
        colorHistogram.setValue(i, -lowDiff);

        if (isWithinPeriod(candleDatetime, currentDatetime))
          averageDistanceBelow.push(-lowDiff);
      }

    }

    averageDistanceAbove.calculate();
    averageDistanceBelow.calculate();
  }

  return(rates_total);
}

string enumMAMethodToString(ENUM_MA_METHOD movingAverageMethod) {
  string methodNameString = EnumToString(movingAverageMethod);
  return StringSubstr(methodNameString, 5);
}

bool isWithinPeriod(MqlDateTime &candle, MqlDateTime &current) {
  return ((candle.day_of_year >= current.day_of_year - AD_Period) && (candle.year == current.year));
}

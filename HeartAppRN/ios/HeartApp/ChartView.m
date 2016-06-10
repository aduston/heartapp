#import "ChartView.h"

@implementation ChartView

- (void)setData:(NSArray *)data {
  NSLog(@"I am getting called");
  _data = data;
  [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
  [[UIColor whiteColor] setFill];
  UIRectFill(rect);
  
  int i;
  
  CGFloat padding = 3.0;
  CGFloat barLeft = 0.0;
  CGFloat barWidth = ((rect.size.width - barLeft) / _data.count) - padding;
  
  int minValue = 999;
  int maxValue = 0;
  for (i = 0; i < _data.count; i++) {
    int intValue = [[_data objectAtIndex:i] intValue];
    if (intValue < minValue) {
      minValue = intValue;
    }
    if (intValue > maxValue) {
      maxValue = intValue;
    }
  }
  
  [[UIColor blueColor] setFill];
  for (i = 0; i < [_data count]; i++) {
    CGFloat barHeight = rect.size.height * ((CGFloat)[[_data objectAtIndex:i] intValue] / (CGFloat)(maxValue - minValue));
    UIRectFill(CGRectMake(barLeft + (barWidth + padding) * i,
                          rect.size.height - barHeight,
                          barWidth,
                          barHeight));
  }
}

@end
#import "ChartView.h"

CGFloat BarHeight(CGFloat rectHeight, CGFloat minBarHeight, int minValue, int maxValue, int barValue) {
  return (rectHeight - minBarHeight) * ((CGFloat)(barValue - minValue) / (CGFloat)(maxValue - minValue)) + minBarHeight;
}

@implementation ChartView

- (void)setData:(NSArray *)data {
  _data = data;
  [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
  [[UIColor whiteColor] setFill];
  UIRectFill(rect);
  
  int i;
  
  NSUInteger count = _data.count;
  
  CGFloat padding = 1.0;
  CGFloat barLeft = 30.0;
  CGFloat minBarHeight = 12.0;
  CGFloat barWidth = ((rect.size.width - barLeft) / count) - padding;
  
  int minValue = 999;
  int maxValue = 0;
  for (i = 0; i < count; i++) {
    int intValue = [[_data objectAtIndex:i] intValue];
    if (intValue < minValue) {
      minValue = intValue;
    }
    if (intValue > maxValue) {
      maxValue = intValue;
    }
  }
  
  // draw horizontal lines
  CGFloat dark = 0.1f;
  CGFloat light = 0.7f;
  CGFloat darkLine[4] = {dark, dark, dark, 1.0f};
  CGFloat lightLine[4] = {light, light, light, 1.0f};
  CGFloat beatHeight = (rect.size.height - minBarHeight) / (CGFloat)(maxValue - minValue);
  CGContextRef c = UIGraphicsGetCurrentContext();
  NSDictionary *textAttributes = @{NSFontAttributeName:[UIFont fontWithName:@"Helvetica"  size:14]};
  BOOL stateSaved = FALSE;
  BOOL labeledLine = FALSE;
  for (i = minValue; i <= maxValue; i++) {
    if (maxValue - minValue > 40 && i % 5 != 0) {
      continue;
    }
    labeledLine = (maxValue - minValue < 60 && i % 5 == 0) || i % 10 == 0;
    if (stateSaved) {
      // drawing text messes up the state.
      CGContextRestoreGState(c);
    }
    CGFloat lineY = rect.size.height - (minBarHeight + (i - minValue) * beatHeight);
    CGContextSetStrokeColor(c, labeledLine ? darkLine : lightLine);
    CGContextMoveToPoint(c, barLeft, lineY);
    CGContextAddLineToPoint(c, rect.size.width, lineY);
    CGContextStrokePath(c);
    CGContextSaveGState(c);
    stateSaved = TRUE;
    if (labeledLine) {
      NSString *label = [NSString stringWithFormat:@"%d", i];
      CGSize textSize = [label sizeWithAttributes:textAttributes];
      [label drawAtPoint:CGPointMake(barLeft - 2.5 - textSize.width, lineY - (textSize.height / 2.0)) withAttributes:textAttributes];
    }
  }
  
  // draw bars
  [[UIColor blueColor] setFill];
  for (i = 0; i < count; i++) {
    CGFloat barHeight = BarHeight(rect.size.height, minBarHeight, minValue, maxValue, [[_data objectAtIndex:i] intValue]);
    UIRectFill(CGRectMake(barLeft + (barWidth + padding) * i,
                          rect.size.height - barHeight,
                          barWidth,
                          barHeight));
  }
}

@end
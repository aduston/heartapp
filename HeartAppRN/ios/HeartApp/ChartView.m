#import "ChartView.h"

#define TOP_MARGIN 10.0
#define BOTTOM_MARGIN 0.0
#define BAR_LEFT 30.0
#define BAR_PADDING 1.0
#define MIN_BAR_HEIGHT 12.0

@implementation ChartView

- (void)setData:(NSArray<NSDictionary *>*)data {
  _data = data;
  [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
  [[UIColor whiteColor] setFill];
  UIRectFill(rect);
  
  int i;
  
  NSUInteger count = _data.count;
  
  CGFloat barWidth = ((rect.size.width - BAR_LEFT - BAR_PADDING) / count) - BAR_PADDING;
  
  int minValue = 999;
  int maxValue = 0;
  for (i = 0; i < count; i++) {
    int intValue = [[[_data objectAtIndex:i] objectForKey:@"hr"] intValue];
    if (intValue < minValue) {
      minValue = intValue;
    }
    if (intValue > maxValue) {
      maxValue = intValue;
    }
  }
  if ((maxValue % 10) != 0) {
    maxValue += (10 - (maxValue % 10));
  }
  if ((minValue % 10) != 0) {
    minValue -= (minValue % 10);
  }
  
  // draw horizontal lines
  CGFloat dark = 0.1f;
  CGFloat light = 0.7f;
  CGFloat darkLine[4] = {dark, dark, dark, 1.0f};
  CGFloat lightLine[4] = {light, light, light, 1.0f};
  CGFloat beatHeight = (rect.size.height - TOP_MARGIN - BOTTOM_MARGIN - MIN_BAR_HEIGHT) / (CGFloat)(maxValue - minValue);
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
    CGFloat lineY = rect.size.height - (BOTTOM_MARGIN + MIN_BAR_HEIGHT + (i - minValue) * beatHeight);
    CGContextSetStrokeColor(c, labeledLine ? darkLine : lightLine);
    CGContextMoveToPoint(c, BAR_LEFT, lineY);
    CGContextAddLineToPoint(c, rect.size.width, lineY);
    CGContextStrokePath(c);
    CGContextSaveGState(c);
    stateSaved = TRUE;
    if (labeledLine) {
      NSString *label = [NSString stringWithFormat:@"%d", i];
      CGSize textSize = [label sizeWithAttributes:textAttributes];
      [label drawAtPoint:CGPointMake(BAR_LEFT - 2.5 - textSize.width, lineY - (textSize.height / 2.0)) withAttributes:textAttributes];
    }
  }
  
  // draw bars
  [[UIColor blueColor] setFill];
  NSDictionary *objectAtIndex;
  for (i = 0; i < count; i++) {
    objectAtIndex = [_data objectAtIndex:i];
    int hr = [[objectAtIndex objectForKey:@"hr"] intValue];
    CGFloat barHeight = beatHeight * (hr - minValue) + MIN_BAR_HEIGHT;
    CGFloat barLeft = BAR_LEFT + BAR_PADDING + (barWidth + BAR_PADDING) * i;
    UIRectFill(CGRectMake(barLeft,
                          rect.size.height - (BOTTOM_MARGIN + MIN_BAR_HEIGHT + (hr - minValue) * beatHeight),
                          barWidth,
                          barHeight));
  }
}

@end
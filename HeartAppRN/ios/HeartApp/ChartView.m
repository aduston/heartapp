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
  
  [[UIColor blueColor] setFill];
  UIRectFill(CGRectMake(10, 10, 100, 300));
  
  [[UIColor redColor] setFill];
  UIRectFill(CGRectMake(120, 50, 100, 250));
}

@end
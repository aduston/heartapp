#import "RCTViewManager.h"
#import "ChartView.h"
#import "RCTBridge.h"
#import "RCTConvert.h"

@interface RCTChartManager : RCTViewManager
@end

@implementation RCTChartManager

RCT_EXPORT_MODULE()

- (UIView *)view {
  return [[ChartView alloc] init];
}

RCT_EXPORT_VIEW_PROPERTY(data, NSArray<NSDictionary *>)

@end
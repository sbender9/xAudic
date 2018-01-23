#import <AppKit/AppKit.h>
#import "StereoConfigure.h"

extern float stereo_value;

@implementation StereoConfigure

- (void)updateDisplay
{
  [intensitySlider setIntValue:stereo_value*10];
  [intensityText setStringValue:[NSString stringWithFormat:@"%.1f", 
				  stereo_value]];
}

- (void)ok:sender
{
  [super ok:sender];
}

- (void)intensityChanged:sender
{
  stereo_value = [intensitySlider intValue]/10.0;
  [intensityText setStringValue:[NSString stringWithFormat:@"%.1f", 
				  stereo_value]];
}

@end



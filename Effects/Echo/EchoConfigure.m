#import <AppKit/AppKit.h>
#import "EchoConfigure.h"
#import "echo.h"

@implementation EchoConfigure

- (void)updateDisplay
{
  [delaySlider setIntValue:echo_delay];
  [delayText setIntValue:echo_delay];
  [feedbackSlider setIntValue:echo_feedback];
  [feedbackText setIntValue:echo_feedback];
  [volumeSlider setIntValue:echo_volume];
  [volumeText setIntValue:echo_volume];
}

+ (void)loadConfig
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  if ( [ud objectForKey:@"echo.delay"] ) {
    echo_delay = [ud integerForKey:@"echo.delay"];
    echo_feedback = [ud integerForKey:@"echo.feedback"];
    echo_volume = [ud integerForKey:@"echo.volume"];
  }
}

- (void)saveConfig
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  [ud setInteger:echo_volume forKey:@"echo.volume"];
  [ud setInteger:echo_feedback forKey:@"echo.feedback"];
  [ud setInteger:echo_delay forKey:@"echo.delay"];
}

- (void)ok:sender
{
  [self saveConfig];
  [super ok:sender];
}

- (void)valueChanged:sender
{
  int *val;
  id txt;
  
  if ( sender == delaySlider ) {
    val = &echo_delay;
    txt = delayText;
  } else if ( sender == feedbackSlider ) {
    val = &echo_feedback;
    txt = feedbackText;
  } else if ( sender == volumeSlider ) {
    val = &echo_volume;
    txt = volumeText;
  }
  
  *val = [sender intValue];
  [txt setIntValue:*val];
}


@end

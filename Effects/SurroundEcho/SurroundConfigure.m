#import <AppKit/AppKit.h>
#import "SurroundConfigure.h"
#import "echo.h"

@implementation SurroundConfigure

- (void)updateDisplay
{
  [delaySlider setIntValue:surround_delay];
  [delayText setIntValue:surround_delay];
  [feedbackSlider setIntValue:surround_feedback];
  [feedbackText setIntValue:surround_feedback];
  [volumeSlider setIntValue:surround_volume];
  [volumeText setIntValue:surround_volume];
}

+ (void)loadConfig
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  if ( [ud objectForKey:@"surround.delay"] ) {
    surround_delay = [ud integerForKey:@"surround.delay"];
    surround_feedback = [ud integerForKey:@"surround.feedback"];
    surround_volume = [ud integerForKey:@"surround.volume"];
  }
}

- (void)saveConfig
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

  [ud setInteger:surround_volume forKey:@"surround.volume"];
  [ud setInteger:surround_feedback forKey:@"surround.feedback"];
  [ud setInteger:surround_delay forKey:@"surround.delay"];
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
    val = &surround_delay;
    txt = delayText;
  } else if ( sender == feedbackSlider ) {
    val = &surround_feedback;
    txt = feedbackText;
  } else if ( sender == volumeSlider ) {
    val = &surround_volume;
    txt = volumeText;
  }
  
  *val = [sender intValue];
  [txt setIntValue:*val];
}


@end

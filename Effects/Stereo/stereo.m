#import <MXA/Plugins.h>
#import "StereoConfigure.h"

@interface Stereo : Effect
@end

@implementation Stereo

float stereo_value = 1.0;

+ (void)load
{
  [Plugin registerPluginClass:[self class]];
}

- init
{
  return [super initWithDescription:@"Extra Stereo Plugin"];
}

- (void)cleanup
{
}



- (int)modSampleData:(short int *)data
	      length:(int)ds
       bitsPerSample:(int)bps
	 numChannels:(int)nch
		freq:(int)srate
{
  int	i;
  double	avg, ldiff, rdiff, tmp, mul;

  if (nch != 2 || bps != 16)
    return ds;
  
  mul = stereo_value;
	
  for (i=0; i<ds/2; i+=2) {
    avg = (data[i] + data[i+1]) / 2;
    ldiff = data[i] - avg;
    rdiff = data[i+1] - avg;
    
    tmp = avg + ldiff * mul;
    if (tmp < -32768)
      tmp = -32768;
    if (tmp > 32767)
      tmp = 32767;
    data[i] = tmp;
    
    tmp = avg + rdiff * mul;
    if (tmp < -32768)
      tmp = -32768;
    if (tmp > 32767)
      tmp = 32767;
    data[i+1] = tmp;
  }
  return ds;
}

- (BOOL)hasAbout
{
  return YES;
}

- (void)about
{
  static NibObject *aboutBox = nil;

  if (aboutBox == nil) {
    aboutBox = [[NibObject alloc] 
	 initWithNibName:@"StereoAbout" 
			  bundle:[NSBundle bundleForClass:[self class]]];
  }
  [aboutBox show];
}

- (void)configure
{
  static StereoConfigure *configure = nil;
  
  if ( configure == nil )
    configure = [[StereoConfigure alloc] init];
  
  [configure show];
}

- (BOOL)hasConfigure
{
  return YES;
}


@end

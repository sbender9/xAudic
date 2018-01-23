/* A voice removal plugin 
   by Anders Carlsson <anders.carlsson@tordata.se> */

#import <MXA/Plugins.h>
#import <MXA/NibObject.h>

@interface Voice : Effect
@end

@implementation Voice

+ (void)load
{
  [Plugin registerPluginClass:[self class]];
}

- init
{
  return [super initWithDescription:@"Voice removal plugin"];
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
	 initWithNibName:@"VoiceAbout" 
			  bundle:[NSBundle bundleForClass:[self class]]];
  }
  [aboutBox show];
}

- (int)modSampleData:(short int *)data
	      length:(int)datasize
       bitsPerSample:(int)bps
	 numChannels:(int)nch
		freq:(int)srate
{
  int x;
  int left,right;
  short *dataptr = data;

  if (nch==2)
    {
      if (bps==16)
	{
	  for (x=0;x<datasize;x+=2)
	    {
	      left = dataptr[1]-dataptr[0];
	      right = dataptr[0]-dataptr[1];
	      if (left < -32768) left = -32768;
	      if (left > 32767) left = 32767;
	      if (right < -32768) right = -32768;
	      if (right > 32767) right = 32767;
	      dataptr[0] = left;
	      dataptr[1] = right;
	      dataptr+=2;
	    }
	}
    }
  
  return datasize;
}

@end

#import <MXA/Plugins.h>
#import <stdlib.h>
#import <stdio.h>
#import <string.h>
#import "EchoConfigure.h"
#import "echo.h"

@interface Echo : Effect
@end


static void	clear_buffer(void);

#define MAX_SRATE 50000
#define MAX_CHANNELS 2
#define BYTES_PS 2
#define BUFFER_SAMPLES (MAX_SRATE * MAX_DELAY / 1000)
#define BUFFER_SHORTS (BUFFER_SAMPLES * MAX_CHANNELS)
#define BUFFER_BYTES (BUFFER_SHORTS * BYTES_PS)

short	*buffer;
int	echo_delay = 500, echo_feedback = 50, echo_volume = 50;
int	w_ofs;
int	old_srate, old_nch;

@implementation Echo

+ (void)load
{
  [Plugin registerPluginClass:[self class]];
}

- init
{
  buffer = (short *)malloc(BUFFER_BYTES);
  clear_buffer();
  [EchoConfigure loadConfig];
  return [super initWithDescription:@"Echo plugin"];
}

static void	clear_buffer(void)
{
  bzero(buffer, BUFFER_BYTES);
  w_ofs = 0;	// short[] index
}

- (void)cleanup
{
  free(buffer);
}

static void	range(int *v)
{
  if (*v < -32768)
    *v = -32768;
  if (*v > 32767)
    *v = 32767;
}

- (int)modSampleData:(short int *)data
	      length:(int)ds
       bitsPerSample:(int)bps
	 numChannels:(int)nch
		freq:(int)srate
{
  int	i, in, out, buf, tmp, r_ofs;
	
  if (bps != 16)
    return ds;
  
  if (nch != old_nch || srate != old_srate) {
    clear_buffer();
    old_nch = nch;
    old_srate = srate;
  }
  
  r_ofs = w_ofs - (srate * echo_delay / 1000) * nch;
  if (r_ofs < 0)
    r_ofs += BUFFER_SHORTS;
  
  for (i=0; i < ds/BYTES_PS; i++) {
    in = data[i];
    buf = buffer[r_ofs];
    out = in + buf * echo_volume / 100;
    buf = in + buf * echo_feedback / 100;
    range(&out);
    range(&buf);
    buffer[w_ofs] = buf;
    data[i] = out;
    tmp = data[i];
    if (++r_ofs >= BUFFER_SHORTS)
      r_ofs -= BUFFER_SHORTS;
    if (++w_ofs >= BUFFER_SHORTS)
      w_ofs -= BUFFER_SHORTS;
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
	 initWithNibName:@"EchoAbout" 
			  bundle:[NSBundle bundleForClass:[self class]]];
  }
  [aboutBox show];
}

- (void)configure
{
  static EchoConfigure *configure = nil;
  
  if ( configure == nil )
    configure = [[EchoConfigure alloc] init];
  
  [configure show];
}

- (BOOL)hasConfigure
{
  return YES;
}

@end

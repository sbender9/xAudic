#import <MXA/Plugins.h>
#import "echo.h"
#import "SurroundConfigure.h"

@interface SurroundEcho : Effect
@end

static void	clear_buffer(void);

#define MAX_SRATE 50000
#define MAX_CHANNELS 2
#define BYTES_PS 2
#define BUFFER_SAMPLES (MAX_SRATE * MAX_DELAY / 1000)
#define BUFFER_SHORTS (BUFFER_SAMPLES * MAX_CHANNELS)
#define BUFFER_BYTES (BUFFER_SHORTS * BYTES_PS)

static short	*surround_buffer;
static short	*surround_buffer2;
int surround_delay = 500, surround_feedback = 50, surround_volume = 50;
static int	w_ofs;
static int	old_srate, old_nch;

@implementation SurroundEcho

+ (void)load
{
  [Plugin registerPluginClass:[self class]];
}

- init
{
  surround_buffer = (short *)malloc(BUFFER_BYTES+1);
  surround_buffer2 = (short *)malloc(BUFFER_BYTES+1);
  clear_buffer();
  [SurroundConfigure loadConfig];
  return [super initWithDescription:@"Pro-Logic Surround Echo Plugin"];
}

static void	clear_buffer(void)
{
  bzero(surround_buffer, BUFFER_BYTES);
  bzero(surround_buffer2, BUFFER_BYTES);
  w_ofs = 0;	// short[] index
}

- (void)cleanup
{
  free(surround_buffer);
  free(surround_buffer2);
}

static void range(int *v)
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
  int	x,i, in, out, buf, tmp, r_ofs, left, right;
  int inl, inr, outl, outr, bufl, bufr;
  
  if (bps != 16)
    return ds;
  
  if (nch != old_nch || srate != old_srate) {
    clear_buffer();
    old_nch = nch;
    old_srate = srate;
  }
  
  r_ofs = w_ofs - (srate * surround_delay / 1000) * nch;
  if (r_ofs < 0)
    r_ofs += BUFFER_SHORTS;
  
  if (nch==1)
    {
      for (i=0; i < ds/BYTES_PS; i++)
	{
	  in = data[i];
	  buf = surround_buffer[r_ofs];
	  out = in + buf * surround_volume / 100;
	  buf = in + buf * surround_feedback / 100;
	  range(&out);
	  range(&buf);
	  surround_buffer[w_ofs] = buf;
	  data[i] = out;
	  tmp = data[i];
	  if (++r_ofs >= BUFFER_SHORTS)
	    r_ofs -= BUFFER_SHORTS;
	  if (++w_ofs >= BUFFER_SHORTS)
	    w_ofs -= BUFFER_SHORTS;
	}
    }
  else
    {
      short *datas = data;
      for (x=0;x<ds/BYTES_PS/2; x++)
	{
	  bufl = surround_buffer[r_ofs];
	  bufr = surround_buffer2[r_ofs];
	  left = bufl-bufr;
	  right = bufr-bufl;
	  bufl = left;
	  bufr = right;
	  
	  inl = datas[x*2];
	  inr = datas[x*2+1];
	  outl = inl + bufl * surround_volume / 100;
	  outr = inr + bufr * surround_volume / 100;
	  bufl = inl + bufl * surround_feedback / 200;
	  bufr = inr + bufr * surround_feedback / 200;
	  range(&outl);
	  range(&outr);
	  range(&bufl);
	  range(&bufr);
	  surround_buffer[w_ofs] = bufl;
	  surround_buffer2[w_ofs] = bufr;
	  datas[x*2] = outl;
	  datas[x*2+1] = outr;
	  if (++r_ofs >= BUFFER_SHORTS)
	    r_ofs -= BUFFER_SHORTS;
	  if (++w_ofs >= BUFFER_SHORTS)
	    w_ofs -= BUFFER_SHORTS;
	}
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
	 initWithNibName:@"SurroundAbout" 
			  bundle:[NSBundle bundleForClass:[self class]]];
  }
  [aboutBox show];
}

- (void)configure
{
  static SurroundConfigure *configure = nil;
  
  if ( configure == nil )
    configure = [[SurroundConfigure alloc] init];
  
  [configure show];
}

- (BOOL)hasConfigure
{
  return YES;
}

@end

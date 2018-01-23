/*  
 *  xAudic - an audio player for MacOS X
 *  Copyright (C) 1999-2001  Scott P. Bender (sbender@harmony-ds.com)
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; see the file COPYING if not, write to 
 *  the Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
 *  Boston, MA 02111-1307, USA.
 */
#import <Foundation/NSRunLoop.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import "Visualization.h"
#import "Control.h"
#import "MXAConfig.h"
#import "Common.h"
#import "fft.h"

static NSMutableArray *vis_plugins = nil;
static Visualization *defaultVisualization = nil;

static NSMutableArray *vis_list = nil;
static NSLock *vis_lock = nil;
static NSTimer *timer = nil;

NSString *UIWindowDidShow = @"UIWindowDidShow";

@interface VisEntry : NSObject
{
@public
  int time;
  gint16 data[2][512];
  int numChannels;
}
@end
@implementation VisEntry
@end

@implementation Visualization

+ (void)registerPlugin:(Plugin *)op
{
  if ( vis_plugins == nil )
    vis_plugins = [[NSMutableArray array] retain];
  [vis_plugins addObject:op];
}

+ (NSArray *)plugins
{
  return vis_plugins;
}

+ (Visualization *)pluginWithName:(NSString *)name
{
  int i;
  for ( i = 0; i < [vis_plugins count]; i++ )
    {
      Visualization *plugin = [vis_plugins objectAtIndex:i];
      if ( [[plugin name] isEqualToString:name] )
	return plugin;
    }
  return nil;
}

- (void)dealloc
{
  [views release];
  [super dealloc];
}

+ (Visualization *)defaultVisualization
{
  if ( defaultVisualization == nil )
    {
      NSString *cfg = [config stringValueForKey:CFGDefaultVisualization];
      if ( cfg == nil || [cfg isEqualToString:@"(none)"] == NO )
	{
	  if ( cfg != nil )
	    {
	      defaultVisualization = [self pluginWithName:cfg];
	    }
	  if ( defaultVisualization == nil )
	    {
	      defaultVisualization = [self pluginWithName:@"Spectrum"];
	    }
	  
	  if ( defaultVisualization != nil )
	    [self setDefaultVisualization:defaultVisualization];
	}
    }
  return defaultVisualization;
}

+ (void)setDefaultVisualization:(Visualization *)vis
{
  NSString *val;
  defaultVisualization = vis;
  
  if ( vis != nil )
    val = NSStringFromClass([vis class]);
  else
    val = @"(none)";
  [config setStringValue:val forKey:CFGDefaultVisualization];

  [[NSNotificationCenter defaultCenter]
    postNotificationName:DefaultVisualizationChangedNotification
    object:nil
    userInfo:[NSDictionary dictionaryWithObjectsAndKeys:vis,
			   @"visualization", nil]];
}

+ (void)initializeVisualizations
{
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
    selector:@selector(songStarted:)
    name:SongStartedNotification
    object:nil];
      
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
    selector:@selector(songEnded:)
    name:SongEndedNotification
    object:nil];
}

/*
+ (void)initialize
{
  if ( [self class] == [Visualization class] )
    {
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      [self initializeVisualizations];
      [pool release];
    }
}
*/

static void convert_to_s16_ne(AFormat fmt, gpointer ptr, gint16 *left, 
			      gint16 *right,gint nch,gint max)
{
  gint16 	*ptr16;
  guint16	*ptru16;
  guint8	*ptru8;
  gint	i;
	
  switch (fmt)
    {
    case FMT_U8:
      ptru8 = ptr;
      if (nch == 1)
	for (i = 0; i < max; i++)
	  left[i] = ((*ptru8++) ^ 128) << 8;
      else
	for (i = 0; i < max; i++)
	  {
	    left[i] = ((*ptru8++) ^ 128) << 8;
	    right[i] = ((*ptru8++) ^ 128) << 8;
	  }
      break;
    case FMT_S8:
      ptru8 = ptr;
      if (nch == 1)
	for (i = 0; i < max; i++)
	  left[i] = (*ptru8++) << 8;
      else
	for (i = 0; i < max; i++)
	  {
	    left[i] = (*ptru8++) << 8;
	    right[i] = (*ptru8++) << 8;
	  }
      break;
    case FMT_U16_LE:
      ptru16 = ptr;
      if (nch == 1)
	for (i = 0; i < max; i++, ptru16++)
	  left[i] = GUINT16_FROM_LE(*ptru16) ^ 32768;
      else
	for (i = 0; i < max; i++)
	  {
	    left[i] = GUINT16_FROM_LE(*ptru16) ^ 32768;
	    ptru16++;
	    right[i] = GUINT16_FROM_LE(*ptru16) ^ 32768;
	    ptru16++;
	  }
      break;
    case FMT_U16_BE:
      ptru16 = ptr;
      if (nch == 1)
	for (i = 0; i < max; i++, ptru16++)
	  left[i] = GUINT16_FROM_BE(*ptru16) ^ 32768;
      else
	for (i = 0; i < max; i++)
	  {
	    left[i] = GUINT16_FROM_BE(*ptru16) ^ 32768;
	    ptru16++;
	    right[i] = GUINT16_FROM_BE(*ptru16) ^ 32768;
	    ptru16++;
	  }
      break;
    case FMT_U16_NE:
      ptru16 = ptr;
      if (nch == 1)
	for (i = 0; i < max; i++)
	  left[i] = (*ptru16++) ^ 32768;
      else
	for (i = 0; i < max; i++)
	  {
	    left[i] = (*ptru16++) ^ 32768;
	    right[i] = (*ptru16++) ^ 32768;
	  }
      break;
    case FMT_S16_LE:
      ptr16 = ptr;
      if (nch == 1)
	for (i = 0; i < max; i++, ptr16++)
	  left[i] = GINT16_FROM_LE(*ptr16);
      else
	for (i = 0; i < max; i++)
	  {
	    left[i] = GINT16_FROM_LE(*ptr16);
	    ptr16++;
	    right[i] = GINT16_FROM_LE(*ptr16);
	    ptr16++;
	  }
      break;
    case FMT_S16_BE:
      ptr16 = ptr;
      if (nch == 1)
	for (i = 0; i < max; i++, ptr16++)
	  left[i] = GINT16_FROM_BE(*ptr16);
      else
	for (i = 0; i < max; i++)
	  {
	    left[i] = GINT16_FROM_BE(*ptr16);
	    ptr16++;
	    right[i] = GINT16_FROM_BE(*ptr16);
	    ptr16++;
	  }
      break;
    case FMT_S16_NE:
      ptr16 = ptr;
      if (nch == 1)
	for (i = 0; i < max; i++)
	  left[i] = (*ptr16++);
      else
	for (i = 0; i < max; i++)
	  {
	    left[i] = (*ptr16++);
	    right[i] = (*ptr16++);
	  }
      break;
    }
}

+ (void)addVisPcmTime:(int)time 
	       format:(AFormat)fmt
	  numChannels:(int)nch
	      length:(int)length
	        data:(void *)ptr;
{
  VisEntry *vis;
  int max;
	
  max = length / nch;
  if ( fmt == FMT_U16_LE 
       || fmt == FMT_U16_BE
       || fmt == FMT_U16_NE
       || fmt == FMT_S16_LE
       || fmt == FMT_S16_BE
       || fmt == FMT_S16_NE)
    max /= 2;
  if ( max > 512 )
    max = 512;

  vis = [[[VisEntry alloc] init] autorelease];
  vis->time = time;
  vis->numChannels = nch;
  
  convert_to_s16_ne(fmt, ptr, vis->data[0], vis->data[1], nch, max);

  if ( vis_lock == nil )
    {
      vis_lock = [[NSLock alloc] init];
    }

  if ( vis_list == nil )
    {
      vis_list = [[NSMutableArray array] retain];
    }


  [vis_lock lock];
  [vis_list addObject:vis];
  [vis_lock unlock];
}
 
static void calc_stereo_pcm(gint16 dest[2][512], gint16 src[2][512], gint nch)
{
  memcpy(dest[0], src[0], 512 * sizeof(gint16));
  if(nch == 1)
    memcpy(dest[1], src[0], 512 * sizeof(gint16));
  else
    memcpy(dest[1], src[1], 512 * sizeof(gint16));
}

static void calc_mono_pcm(gint16 dest[2][512], gint16 src[2][512], gint nch)
{
  gint i;
  gint16 *d, *sl, *sr;
	
  if(nch == 1)
    memcpy(dest[0], src[0], 512 * sizeof(gint16));
  else
    {
      d = dest[0];
      sl = src[0];
      sr = src[1];
      for(i = 0; i < 512; i++)
	{
	  *(d++) = (*(sl++) + *(sr++)) >> 1;
	}
    }
}

static void calc_freq(gint16 *dest, gint16 *src)
{
  static fft_state *state = NULL;
  gfloat tmp_out[257];
  gint i;
	
  if(!state)
    state = fft_init();

  fft_perform(src,tmp_out,state);
	
  for(i = 0; i < 256; i++)
    dest[i] = ((gint)sqrt(tmp_out[i + 1])) >> 8;
}

static void calc_mono_freq(gint16 dest[2][256], gint16 src[2][512], gint nch)
{
  gint i;
  gint16 *d, *sl, *sr, tmp[512];
	
  if(nch == 1)
    calc_freq(dest[0], src[0]);
  else
    {
      d = tmp;
      sl = src[0];
      sr = src[1];
      for(i = 0; i < 512; i++)
	{
	  *(d++) = (*(sl++) + *(sr++)) >> 1;
	}
      calc_freq(dest[0], tmp);
    }
}

static void calc_stereo_freq(gint16 dest[2][256], gint16 src[2][512], gint nch)
{
  calc_freq(dest[0], src[0]);

  if(nch == 2)
    calc_freq(dest[1], src[1]);
  else
    memcpy(dest[1], dest[0], 256 * sizeof(gint16));
}


+ (void)sendData:(gint16[2][512])pcm_data :(gint)nch
{
  Visualization *vp;
  gint16 mono_freq[2][256], stereo_freq[2][256];
  gboolean mono_freq_calced = FALSE, stereo_freq_calced = FALSE;
  gint16 mono_pcm[2][512], stereo_pcm[2][512];
  gboolean mono_pcm_calced = FALSE, stereo_pcm_calced = FALSE;
  int j;

  if(pcm_data && nch > 0)
    {
      for ( j = 0; j < [vis_plugins count]; j++ )
	{
	  vp = [vis_plugins objectAtIndex:j];

	  if ( [vp anyVisableViews] == NO )
	    continue;
			    
	  if ([vp numPCMChannelsWanted] > 0 )
	  {
	    if ( [vp numPCMChannelsWanted] == 1)
	      {
		if(!mono_pcm_calced)
		  {
		    calc_mono_pcm(mono_pcm, pcm_data, nch);
		    mono_pcm_calced = TRUE;
		  }
		[vp renderPCM:mono_pcm];
	      }
	    else
	      {
		if(!stereo_pcm_calced)
		  {
		    calc_stereo_pcm(stereo_pcm, pcm_data, nch);
		    stereo_pcm_calced = TRUE;
		  }
		[vp renderPCM:stereo_pcm];
	      }
	  }
	  if ( [vp numFREQChannelsWanted] > 0 )
	    {
	      if ( [vp numFREQChannelsWanted] == 1)
		{
		  if ( !mono_freq_calced )
		    {
		      calc_mono_freq(mono_freq, pcm_data, nch);
		      mono_freq_calced = TRUE;
		    }
		  [vp renderFREQ:mono_freq];
		}
	      else
		{
		  if ( !stereo_freq_calced )
		    {
		      calc_stereo_freq(stereo_freq, pcm_data, nch);
		      stereo_freq_calced = TRUE;
		    }
		  [vp renderFREQ:stereo_freq];
		}
	    }
	}
    }
}

+ (void)timer:nothing
{
  VisEntry *vis = nil, *next_vis;
  BOOL found;
  int i;

  int time = [Input getTime];

  if ( time == -1 )
    return;

  [vis_lock lock];

  found=FALSE;
  for ( i = 0; i < [vis_list count] && !found; i++ ) 
    {
      vis = [vis_list objectAtIndex:i];

      next_vis = nil;
      
      if ( i < [vis_list count]-1 )
	next_vis = [vis_list objectAtIndex:i+1];

      if ( (next_vis == nil || next_vis->time >= time) && vis->time < time) 
	{
	  found = TRUE;
	  break;
	}
    }

  if ( found ) 
    {
      BOOL done = FALSE;
      while (!done)
	{
	  next_vis = [vis_list objectAtIndex:0];
	  if ( next_vis == vis )
	    done = TRUE;
	  [vis_list removeObject:next_vis];
	}
      [vis_lock unlock];
      [self sendData:vis->data :vis->numChannels];
    }
  else
    {
      [vis_lock unlock];
      [self sendData:0 :0];
    }
}

- initWithDescription:(NSString *)desc
{
  views = [[NSMutableArray array] retain];
  return [super initWithDescription:desc];
}

- (void)registerNotifications
{
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(songStarted:)
	   name:SongStartedNotification
	 object:nil];

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(songEnded:)
	   name:SongEndedNotification
	 object:nil];
}

- (void)unRegisterNotifications
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSRect)visFrameForRect:(NSRect)rect
{
  NSRect res;
  if ( [self isSizable] )
    return rect;

  res.size = [self defaultSize];

  res.origin.x = rect.origin.x+((rect.size.width/2.0)-(res.size.width/2.0));
  res.origin.y = rect.origin.y+((rect.size.height/2.0)-(res.size.height/2.0));

  return res;
}


- (NSSize)defaultSize
{
  return NSMakeSize(0, 0);
}

- (NSSize)maxSize
{
  return NSMakeSize(0,0);
}

- (NSSize)minSize
{
  return NSMakeSize(0,0);
}


- (BOOL)isSizable
{
  return YES;
}

- (VisualizationView *)getViewWithFrame:(NSRect)frame owner:(id)owner
{
  return [self getViewWithFrame:frame owner:owner autohide:YES];
}

- (Class)viewClass
{
  return [VisualizationView class];
}

- (void)drawInView:(VisualizationView *)view
{
}

- (void)viewWasCreated:(VisualizationView *)view
{
}

- (VisualizationView *)getViewWithFrame:(NSRect)frame 
				  owner:(id)owner
			       autohide:(BOOL)autohide
{
  VisualizationView *view = [[[self viewClass] alloc] initWithFrame:frame 
						      plugin:self
						      owner:owner
						      autohide:autohide];

  //NSLog(@"%@ view created for: %@", self, owner);

  [self viewWasCreated:view];

  [self addView:view];

  return [view autorelease];
}

- (BOOL)anyVisableViews
{
  int i;
  for ( i = 0; i < [views count]; i++ )
    {
      VisualizationView *view = [views objectAtIndex:i];
      if ( [view superview] != nil && [[view window] isVisible] )
	return YES;
    }
  return NO;
}

+ (BOOL)anyVisableViews
{
  int i;
  for ( i = 0; i < [vis_plugins count]; i++ )
    {
      Visualization *plugin = [vis_plugins objectAtIndex:i];
      if ( [plugin anyVisableViews] )
	return YES;
    }
  return NO;
}

- (void)addView:(VisualizationView *)view
{
  [views addObject:view];
  [self start];
}

- (void)removeView:(VisualizationView *)view
{
  if ( [views containsObject:view] == NO )
    {
      //NSLog(@"view: %@(%@) owner: %@", view, self, [view owner]);
      return;
    }

  [views removeObject:view];
  if ( [view superview] != nil )
    [view removeFromSuperview];
  if ( [views count] == 0 && [self isRunning] )
    [self stop];
  //NSLog(@"%@: removeView: %@, owned by %@ (cound %d)", self, view, 
  //[view owner], [views count]);
}

+ (NSTimeInterval)getTimerInterval
{
  return [config slow_cpu] ? 0.1 : 0.05;
}

- (BOOL)embedOnly
{
  return NO;
}

- (BOOL)isRunning
{
  return isRunning;
}

- (BOOL)canEmbed
{
  return YES;
}

+ (void)stopTimer
{
  if ( timer != nil )
    {
      //NSLog(@"stopTimer: %@", NSStringFromClass([self class]));

      [timer invalidate];
      [timer release];
      timer = nil;
    }
}

+ (void)songEnded:(NSNotification *)notification
{
  [self stopTimer];
  [vis_list release];
  vis_list = nil;
}

+ (void)startTimer
{
  if ( timer == nil )
    {
      NSTimeInterval interval = [self getTimerInterval];

      //NSLog(@"startTimer: %@, %f", NSStringFromClass([self class]),
      //interval);

      timer = [NSTimer timerWithTimeInterval:interval
		       target:[self class]
		       selector:@selector(timer:)
		       userInfo:nil
		       repeats:YES];
      [timer retain];

      // make sure our timer is run in the main apps thread and not the
      // decoders thread, which we are most likely running in here.
      [[[NSApp delegate] getMainRunLoop] addTimer:timer
					 forMode:NSDefaultRunLoopMode];
    }
}
  
+ (void)songStarted:(NSNotification *)notification
{
  if ( [self anyVisableViews] )
    [self startTimer];
}

- (void)songStarted:(NSNotification *)notification
{
}

- (void)songEnded:(NSNotification *)notification
{
}

- (void)startInWindow
{
  if ( window == nil )
    {
      NSView *view;
      int mask;
      NSSize size = [self defaultSize];
      NSRect frame = NSMakeRect(0, 0, size.width, size.height);

      mask = NSClosableWindowMask|NSTitledWindowMask;

      if ( [self isSizable] )
	mask |= NSResizableWindowMask;

      window = [[NSWindow alloc] initWithContentRect:frame
				 styleMask:mask
				 backing:NSBackingStoreBuffered
				 defer:NO];
      [window setReleasedWhenClosed:YES];
      [window setTitle:[self description]];
      [window setFrameAutosaveName:NSStringFromClass([self class])];
      [window setDelegate:self];
      view = [self getViewWithFrame:frame owner:window autohide:NO];
      [window setContentView:view];

      if ( [self isSizable] )
	{
	  NSSize size = [self maxSize];
	  if ( size.height != 0 || size.width != 0 )
	    [window setMaxSize:size];
	  size = [self minSize];
	  if ( size.height != 0 || size.width != 0 )
	    [window setMinSize:size];
	}

      [[NSNotificationCenter defaultCenter] 
	addObserver:self
	selector:@selector(windowWillClose:)
	name:NSWindowWillCloseNotification
	object:window];


      [window makeKeyAndOrderFront:self];
      [self start];
    }
}

- (void)stopInWindow
{
  if ( window != nil )
    {
      [[NSNotificationCenter defaultCenter] removeObserver:self 
					    name:NSWindowWillCloseNotification
					    object:window];
      [window close];
    }
}

- (void)windowWillClose:(NSNotification *)notification
{
  NSLog(@"windowWillClose");
  [self removeView:[window contentView]];
  window = nil;
  if ( [self anyVisableViews] == NO )
    [self stop];
}

- (void)start
{
  isRunning = YES;

  if ( isRunning == NO )
    [self registerNotifications];

  if ( [Control songIsPlaying] && [[self class] anyVisableViews] )
    [[self class] startTimer];
}

- (void)stop
{
  isRunning = NO;
  [self unRegisterNotifications];
}

- (void)viewStatusChanged:(VisualizationView *)view
{
  BOOL anyVisableViews = [self anyVisableViews];

  if ( anyVisableViews == NO )
    [[self class] stopTimer];
  else if ( [Input isPlaying] )
    [[self class] startTimer];
}

- (int)numPCMChannelsWanted
{
  return 0;
}

- (int)numFREQChannelsWanted
{
  return 0;
}

- (void)renderPCM:(short[2][512])data
{
}

- (void)renderFREQ:(short[2][256])data
{
}

- (BOOL)isPublic
{
  return YES;
}

- (BOOL)allowsMultipleViews
{
  return YES;
}

- (BOOL)goodForSmallView
{
  return NO;
}

@end


@implementation VisualizationView

- (void)registerNotifications
{
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
    selector:@selector(songStarted:)
    name:SongStartedNotification
    object:nil];
      
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
    selector:@selector(songEnded:)
    name:SongEndedNotification
    object:nil];

  {
    NSWindow *window = [self window] ? [self window] : prevWindow;
    if ( window != nil )
      {
	[[NSNotificationCenter defaultCenter] 
	  addObserver:self
	  selector:@selector(windowWillClose:)
	  name:NSWindowWillCloseNotification
	  object:window];
      }
  }
}

- initWithFrame:(NSRect)frame 
	 plugin:(Visualization *)plugina
	  owner:(id)aowner
       autohide:(BOOL)autohidea
{
  plugin = plugina;
  autohide = autohidea;
  owner = aowner;

  [self registerNotifications];

  return [super initWithFrame:frame];
}

- (void)songStarted:sender
{
  //NSLog(@"%@(%@): songStarted",  self, owner);
  if ( autohide )
    [prevSuperview addSubview:self];
}

- (void)dealloc
{
  //NSLog(@"%@: dealloc",  self);
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [plugin removeView:self];
  [super dealloc];
}

- (void)songEnded:sender
{
  //NSLog(@"%@(%@): songEnded",  self, owner);
  if ( autohide )
    [self removeFromSuperview];
}

- (void)statusChange
{
  if ( autohide )
    {
      if ( [self superview] != nil )
	{
	  prevSuperview = [self superview];
	  if ( [Control songIsPlaying] == FALSE )
	    [self removeFromSuperview];
	}
    }
  [plugin viewStatusChanged:self];
}

- (void)viewDidMoveToSuperview
{
  //NSLog(@"%@(%@): moved to superview %@", self, owner, [self superview]);
  [self statusChange];
}

- (void)viewDidMoveToWindow
{
  //NSLog(@"%@(%@): moved to window: %@", self, owner, [self window]);
  if ( [self window] != nil )
    prevWindow = [self window];
  [self statusChange];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self registerNotifications];
}

- (void)windowWillClose:(NSNotification *)notification
{
  //NSLog(@"%@(%@): windowWillClose: %@", self, owner, [self window]);
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [plugin removeView:self];
}

- (void)setAutohide:(BOOL)val
{
  autohide = val;
}

- (void)drawRect:(NSRect )rect
{
  [plugin drawInView:self];
}

- (id)owner
{
  return owner;
}

@end

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

#import "Sample.h"
#import <AppKit/AppKit.h>
#import <MXA/Control.h>
#import <MXA/Config.h>
#import <MXA/PlaylistEditor.h>

@implementation Sample

+ (void)load
{
  [Plugin registerPluginClass:[self class]];
}

- init
{
  return [super initWithDescription:[NSString stringWithFormat:@"Sample UI %@",
					      getVersion()]];
}

- (void)removeVisualization
{
  if ( visPlugin != nil )
    {

      if ( visView != nil )
	{
	  [visPlugin removeView:visView];

	  if ( [visView superview] != nil )
	    [visView removeFromSuperview];
      
	  [visView release];
	  visView = nil;
	}

      [visPlugin release];
      visPlugin = nil;
    }
}

- (void)loadVisualization
{
  [self removeVisualization];

  visPlugin = [Visualization defaultVisualization];
  if ( visPlugin != nil && [visPlugin canEmbed] )
    {
      NSRect frame = [visbox frame];
      frame.origin.x = 0;
      frame.origin.y = 0;
      frame = [visPlugin visFrameForRect:frame];
      visView = [visPlugin getViewWithFrame:frame];
      [visView retain];
      [visbox addSubview:visView];
    }
  else
    visPlugin = nil;
}


- (void)run
{
  if ( nibLoaded == NO )
    {
      [NSBundle loadNibNamed:@"Sample" owner:self];    
      //[vis retain]; // so it doesn't get released when we remove from view
      nibLoaded = YES;
    }

  {
    NSRect rect = [playlistbox frame];
    NSView *playlist;
    [playlistbox removeFromSuperview];
    editor = [[PlaylistEditor loadForInclusion] retain];
    playlist = [editor view];
    [playlist setFrame:rect];
    [[mainWindow contentView] addSubview:playlist];
  }

  
  [self loadVisualization];

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(songStarted:)
	   name:SongStartedNotification
	 object:nil];

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(bitrateChanged:)
	   name:BitrateChangedNotification
	 object:nil];

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(songEnded:)
	   name:SongEndedNotification
	 object:nil];

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(repeatValueChanged:)
	   name:RepeatValueChangedNotification
	 object:nil];

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(shuffleValueChanged:)
	   name:ShuffleValueChangedNotification
	 object:nil];

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(playStatusChanged:)
	   name:PlayStatusChangedNotification
	 object:nil];

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(visTypeChanged:)
	   name:DefaultVisualizationChangedNotification
	 object:nil];

  [volume setIntValue:[Control getVolume]];

  [mainWindow makeKeyAndOrderFront:self];

  timer = [[NSTimer scheduledTimerWithTimeInterval:1.0
				   target:self 
				 selector:@selector(timeTimer:)
				 userInfo:nil
				  repeats:YES] retain];
  [super run];
}

- (void)stop
{
  [timer invalidate];
  [timer release];
  timer = nil;

  [self removeVisualization];

  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [mainWindow orderOut:self];
  [super stop];
}

- (void)dealloc
{
  [editor release];
  [self removeVisualization];
  [super dealloc];
}

- (void)songStarted:(NSNotification *)notification
{
  NSDictionary *info = [notification userInfo];

  [title setStringValue:[info objectForKey:@"title"]];

  [bit_rate setIntValue:[[info objectForKey:@"rate"] intValue]];
  [sample_rate setIntValue:[[info objectForKey:@"frequency"] intValue]];
  [stereo setStringValue:[[info objectForKey:@"numChannels"] intValue] 
	  == 2 ? @"Stereo" : @"Mono"];
  [song_position setMaxValue:[[info objectForKey:@"length"] intValue]];
}

- (void)bitrateChanged:(NSNotification *)notification
{
  NSDictionary *info = [notification userInfo];
  int rate = [[info objectForKey:@"rate"] intValue];
  [bit_rate setIntValue:rate];
}

- (void)songEnded:(NSNotification *)notification
{
  [title setStringValue:@""];
  [bit_rate setStringValue:@""];
  [sample_rate setStringValue:@""];
  [stereo setStringValue:@""];
  [time setStringValue:@""];
  [song_position setIntValue:0];
}

- (void)shuffleValueChanged:(NSNotification *)notification
{
  BOOL val = [[[notification userInfo] objectForKey:@"shuffle"] boolValue];
  [shuffle setState:val];
}

- (void)repeatValueChanged:(NSNotification *)notification
{
  BOOL val = [[[notification userInfo] objectForKey:@"repeat"] boolValue];
  [repeat setState:val];
}

- (void)playStatusChanged:(NSNotification *)notification
{
  PStatus s = [[[notification userInfo] objectForKey:@"status"] intValue];

  [pause setState:s == STATUS_PAUSE];
}

- (void)visTypeChanged:(NSNotification *)notification
{
  [self loadVisualization];
}

- (void)timeTimer:nothing
{
  int itime;

  if ( [Input isPlaying] ) 
    {
      itime = [Input getTime];
      if ( itime != -1 ) 
	{
	  //NSLog(@"times: %@", [Control getTimeString]);
	  [time setStringValue:[Control getTimeString]];
	  [song_position setIntValue:itime];
	}
    }
}

@end






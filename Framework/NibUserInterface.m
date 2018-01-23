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

#import "NibUserInterface.h"
#import <AppKit/AppKit.h>
#import "Control.h"
#import "MXAConfig.h"
#import "WindowMovingView.h"

@interface UserInterfaceWindow : NSWindow
@end


@implementation NibUserInterface

+ (void)initialize
{
  if (self == [NibUserInterface class])
    [self setVersion:1];
}

+ (void)loadPlugin:(NSString *)path
{
  NSDictionary *context;
  context = [NSDictionary dictionaryWithObjectsAndKeys:
			    [[NSObject alloc] init], @"NSOwner", nil];
  [NSBundle loadNibFile:path
	    externalNameTable:context withZone:[self zone]];
}

- init
{
  windowAlpha = 0.0;
  noTitleBar = NO;
  clickToMove = NO;
  windowOpaque = YES;
  windowBackgroundColor = [NSColor windowBackgroundColor];
  pluginName = @"No Name";

  buttonShowsBorderOnlyWhileMouseInside = NO;
  buttonImageDimsWhenDisabled = YES;
  buttonHighlightsBy = NSNoCellMask;
  buttonShowsStateBy  = NSNoCellMask;
  buttonOptionsApplyTo = 0;

  return [super init];
}

- (NSString *)name
{
  return pluginName;
}

- (void)setItemTarget:view :(SEL)action
{
  if ( [view target] == nil )
    {
      [view setTarget:self];
      [view setAction:action];
    }
}

- (void)setButtonOptions:button
{
  if ( [button isKindOfClass:[NSButton class]] )
    button = [button cell];

  [button setImageDimsWhenDisabled:[self getButtonImageDimsWhenDisabled]];
  [button setShowsBorderOnlyWhileMouseInside:[self getButtonShowsBorderOnlyWhileMouseInside]];
  [button setHighlightsBy:[self getButtonHighlightsBy]];
  [button setShowsStateBy:[self getButtonShowsStateBy]];
}


- (void)setButtonOptions
{
  int mask = [self getButtonOptionsApplyTo];
  if ( mask & BUTTON_PLAY )
    [self setButtonOptions:playButton];
  if ( mask & BUTTON_PAUSE )
    [self setButtonOptions:pauseButton];
  if ( mask & BUTTON_STOP )
    [self setButtonOptions:stopButton];
  if ( mask & BUTTON_PREV )
    [self setButtonOptions:prevButton];
  if ( mask & BUTTON_NEXT )
    [self setButtonOptions:nextButton];
}

- (void)setStereo:(int)val
{
  if ( stereoText )
    {
      [stereoText setStringValue: val  == 2 ? @"Stereo" : 
		    (val == 1 ? @"Mono" : @"")];
    }

  if ( stereoCheckBox )
    {
      if ( val == -1 )
	{
	  [stereoCheckBox setState:0];
	}
      else
	{
	  [stereoCheckBox setState:val == 2];
	}
    }

  if ( stereoRadioBox )
    {
      if ( val == -1 )
	{
	  [stereoRadioBox deselectAllCells];
	}
      else
	{
	  [stereoRadioBox selectCellWithTag:val];
	}
    }
}

- (void)updateGUI
{
  NSDictionary *info;
  BOOL isPaused = [Control songIsPaused], isPlaying = [Control songIsPlaying];

  if ( isPlaying && (info = [Input getCurrentSongInfo]) )
    {
      [songTitle setStringValue:[info objectForKey:@"title"]];
      
      [bitRateText setIntValue:[[info objectForKey:@"rate"] intValue]];
      [sampleRateText setIntValue:[[info objectForKey:@"frequency"] intValue]];
      [songPositionSlider setMaxValue:100];
      [songPositionSlider setIntValue:[Input getTime]];
      [self setStereo:[[info objectForKey:@"numChannels"] intValue]];
    }
  else
    {
      [songTitle setStringValue:@""];
      [bitRateText setStringValue:@""];
      [sampleRateText setStringValue:@""];
      [self setStereo:-1];
      [timeText setStringValue:@"00:00"];
      [songPositionSlider setIntValue:0];
    }

  [playButton setState:isPaused == NO && isPlaying];
  [playButton setEnabled:isPaused || isPlaying == NO];

  [pauseButton setState:isPaused];
  [pauseButton setEnabled:isPaused || isPlaying];

  [stopButton setState:isPlaying == NO];
  [stopButton setEnabled:isPlaying];
}

- (void)awakeFromNib
{
  WindowMovingView *mover = nil;

  [volumeSlider setMinValue:0.0];
  [volumeSlider setMaxValue:100.0];
  [volumeSlider setIntValue:[Control getVolume]];
  [self setItemTarget:volumeSlider :@selector(volume_slider:)];
      
  [songPositionSlider setMinValue:0.0];
  [self setItemTarget:songPositionSlider :@selector(songposition_slider:)];
      
  [self setItemTarget:repeatCheckBox :@selector(repeat:)];
  [self setItemTarget:shuffleCheckBox :@selector(shuffle:)];

  [stereoRadioBox setAllowsEmptySelection:YES];

  if ( clickToMove )
    {
      NSView *contents = [window contentView];
      NSRect cframe = [contents frame];
	
      mover = [[WindowMovingView alloc] initWithFrame:cframe];
      cframe.origin.x = 0;
      cframe.origin.y = 0;
      [mover setFrame:cframe];
      [mover setImageFrameStyle:NSImageFrameNone];
      [mover setEditable:NO];
      [(NSWindow *)window setContentView:mover];
      [mover addSubview:contents];
      [mover setMovingEnabled:clickToMove];
    }

  {
    //Center the window
    NSRect wframe, sframe;
    sframe = [[window screen] visibleFrame];
    wframe = [window frame];
    [window setFrameOrigin:NSMakePoint((sframe.size.width/2)
				       -(wframe.size.width/2),
				       (sframe.size.height/2)
				       -(wframe.size.height/2))];
  }

  [window setFrameAutosaveName:[self description]];

  if ( noTitleBar )
    {
      NSWindow *newwidow;
      NSView *contents;
      contents = [window contentView];
      newwidow = [[UserInterfaceWindow alloc] initWithContentRect:[contents frame]
					      styleMask:0
					      backing:NSBackingStoreBuffered
					      defer:NO];
      [newwidow setAcceptsMouseMovedEvents:YES];

      [contents removeFromSuperview];
      [newwidow setContentView:contents];
      [newwidow setFrame:[window frame] display:NO];
      [newwidow setFrameAutosaveName:[self description]];
      [window close];
      window = newwidow;
    }

  [window setBackgroundColor:[self getWindowBackgroundColor]];
  [window setOpaque:[self getWindowOpaque]];
  [window setAlphaValue:[self getWindowAlpha]];
  [self setButtonOptions];

  [window setDelegate:self];

  [UserInterface registerPlugin:self];
}

- (void)run
{
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

  [self updateGUI];

  [window makeKeyAndOrderFront:self];

  [[NSNotificationCenter defaultCenter]
    postNotificationName:UIWindowDidShow
    object:window
    userInfo:nil];
  
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

  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [window orderOut:self];
  [super stop];
}

- (void)dealloc
{
  [super dealloc];
}



- (BOOL)windowShouldClose:(id)sender;
{
  [NSApp terminate:self];
  return NO;
}

- (void)songStarted:(NSNotification *)notification
{
  [self updateGUI];
  /*
  NSDictionary *info = [notification userInfo];

  [songTitle setStringValue:[info objectForKey:@"title"]];

  [bitRateText setIntValue:[[info objectForKey:@"rate"] intValue]];
  [sampleRateText setIntValue:[[info objectForKey:@"frequency"] intValue]];
  [songPositionSlider setMaxValue:[[info objectForKey:@"length"] intValue]];
  [self setStereo:[[info objectForKey:@"numChannels"] intValue]];

  [playButton setState:1];
  [playButton setEnabled:NO];

  [pauseButton setState:0];
  [pauseButton setEnabled:YES];

  [stopButton setState:0];
  [stopButton setEnabled:YES];
  */
}

- (void)bitrateChanged:(NSNotification *)notification
{
  NSDictionary *info = [notification userInfo];
  int rate = [[info objectForKey:@"rate"] intValue];
  [bitRateText setIntValue:rate];
}

- (void)songEnded:(NSNotification *)notification
{
  [self updateGUI];
  /*
  [songTitle setStringValue:@""];
  [bitRateText setStringValue:@""];
  [sampleRateText setStringValue:@""];
  [self setStereo:-1];
  [timeText setStringValue:@"00:00"];
  [songPositionSlider setIntValue:0];

  [playButton setState:0];
  [playButton setEnabled:YES];

  [pauseButton setState:0];
  [pauseButton setEnabled:NO];

  [stopButton setState:1];
  [stopButton setEnabled:NO];
  */
}

- (void)shuffleValueChanged:(NSNotification *)notification
{
  BOOL val = [[[notification userInfo] objectForKey:@"shuffle"] boolValue];
  [shuffleCheckBox setState:val];
}

- (void)repeatValueChanged:(NSNotification *)notification
{
  BOOL val = [[[notification userInfo] objectForKey:@"repeat"] boolValue];
  [repeatCheckBox setState:val];
}

- (void)playStatusChanged:(NSNotification *)notification
{
  if ( pauseButton != nil )
    {
      PStatus s = [[[notification userInfo] objectForKey:@"status"] intValue];

      [pauseButton setState:s == STATUS_PAUSE];
      [playButton setState:s == STATUS_PLAY];
      [playButton setEnabled:s != STATUS_PLAY];
    }
}

- (void)timeTimer:nothing
{
  int itime;

  if ( [Input isPlaying] ) 
    {
      itime = [Input getTime];
      if ( itime != -1 ) 
	{
	  int length = [Control getPlayingSongLength];
	  [timeText setStringValue:[Control getTimeString]];
	  [songPositionSlider setIntValue:(itime*100)/length];
	}
    }
}

- (void)setNoTitleBar:(BOOL)val
{
  noTitleBar = val;
}

- (BOOL)getNoTitleBar
{
  return noTitleBar;
}

- (void)setClickAnywhereToMove:(BOOL)val
{
  clickToMove = val;
}

- (BOOL)getClickAnywhereToMove
{
  return clickToMove;
}

- (void)setWindowBackgroundColor:(NSColor *)val
{
  windowBackgroundColor = [val retain];
}

- (NSColor *)getWindowBackgroundColor
{
  return windowBackgroundColor;
}

- (void)setWindowAlpha:(float)alpha
{
  windowAlpha = alpha;
}

- (float)getWindowAlpha
{
  return windowAlpha;
}

- (void)setPluginName:(NSString *)name
{
  pluginName = [name retain];
  description = [name retain];
}

- (NSString *)getPluginName
{
  return pluginName;
}

- (void)setWindowOpaque:(BOOL)val
{
  windowOpaque = val;
}

- (BOOL)getWindowOpaque
{
  return windowOpaque;
}

- (void)setButtonShowsBorderOnlyWhileMouseInside:(BOOL)val
{
  buttonShowsBorderOnlyWhileMouseInside = val;
}

- (BOOL)getButtonShowsBorderOnlyWhileMouseInside
{
  return buttonShowsBorderOnlyWhileMouseInside;
}

- (void)setButtonImageDimsWhenDisabled:(BOOL)val
{
  buttonImageDimsWhenDisabled = val;
}

- (BOOL)getButtonImageDimsWhenDisabled
{
  return buttonImageDimsWhenDisabled;
}

- (void)setButtonHighlightsBy:(int)val
{
  buttonHighlightsBy = val;
}

- (int)getButtonHighlightsBy
{
  return buttonHighlightsBy;
}

- (void)setButtonShowsStateBy:(int)val
{
  buttonShowsStateBy = val;
}

- (int)getButtonShowsStateBy
{
  return buttonShowsStateBy;
}

- (void)setButtonOptionsApplyTo:(int)mask
{
  buttonOptionsApplyTo = mask;
}

- (int)getButtonOptionsApplyTo
{
  return buttonOptionsApplyTo;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:[self getWindowBackgroundColor]];
  [encoder encodeValueOfObjCType:@encode(BOOL) at:&noTitleBar];
  [encoder encodeValueOfObjCType:@encode(BOOL) at:&clickToMove];
  [encoder encodeValueOfObjCType:@encode(BOOL) at:&windowOpaque];
  [encoder encodeValueOfObjCType:@encode(float) at:&windowAlpha];

  [encoder encodeValueOfObjCType:@encode(BOOL) 
	   at:&buttonShowsBorderOnlyWhileMouseInside];
  [encoder encodeValueOfObjCType:@encode(BOOL) 
	   at:&buttonImageDimsWhenDisabled];
  [encoder encodeValueOfObjCType:@encode(int) at:&buttonHighlightsBy];
  [encoder encodeValueOfObjCType:@encode(int) at:&buttonShowsStateBy];
  [encoder encodeValueOfObjCType:@encode(int) at:&buttonOptionsApplyTo];

  [encoder encodeObject:pluginName];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    int	version;
    
    self = [self init];
    version = [decoder versionForClassName:@"NibUserInterface"];
    switch (version) 
      {
      case 1:
	{
	  [self setWindowBackgroundColor:[decoder decodeObject]];
	  [decoder decodeValueOfObjCType:@encode(BOOL) at:&noTitleBar];
	  [decoder decodeValueOfObjCType:@encode(BOOL) at:&clickToMove];
	  [decoder decodeValueOfObjCType:@encode(BOOL) at:&windowOpaque];
	  [decoder decodeValueOfObjCType:@encode(float) at:&windowAlpha];
	  [decoder decodeValueOfObjCType:@encode(BOOL) 
		   at:&buttonShowsBorderOnlyWhileMouseInside];
	  [decoder decodeValueOfObjCType:@encode(BOOL) 
		   at:&buttonImageDimsWhenDisabled];
	  [decoder decodeValueOfObjCType:@encode(int) at:&buttonHighlightsBy];
	  [decoder decodeValueOfObjCType:@encode(int) at:&buttonShowsStateBy];
	  [decoder decodeValueOfObjCType:@encode(int) 
		   at:&buttonOptionsApplyTo];

	  [self setPluginName:[decoder decodeObject]];
	}
	break;
      default:
	NSAssert1(NO, @"Invalid NibUserInterface version: %d", version);
	break;
      }
    return self;
}

/*
- (NSString *)description
{
  return [NSString stringWithFormat:@"%@(NibUserInterface)", pluginName];
}
*/

@end

@implementation UserInterfaceWindow 
- (void)mouseEntered:(NSEvent *)e
{
  NSLog(@"mouseEntered");
}

- (void)mouseExited:(NSEvent *)e
{
  NSLog(@"mouseExited");
}


@end

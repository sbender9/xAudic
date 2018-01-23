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

#import <MXA/Common.h>
#import <MXA/Control.h>
#import "Configure.h"
#import "Skin.h"
#import "WinAmp.h"
#import "MainView.h"
#import "Button.h"
#import "TextBox.h"
#import "MenuRow.h"
#import "Slider.h"
#import "MonoStereo.h"
#import "Number.h"
#import "EqView.h"
#import "PlayStatus.h"
#import "MainWindow.h"
#import <MXA/PlaylistEntry.h>
#import <MXA/Plugins.h>
#import "PlaylistView.h"

@implementation MainView

- (BOOL)isFlipped
{
  return YES;
}

+ (NSSize)calcSize
{
  NSSize size;

  size.width = 275;
  size.height = [config boolValueForKey:player_shaded] ? 14 : 116;
  return size;
}

- (void)removeIfNeeded:(NSView *)view
{
  if ( [view superview] != nil )
    [view removeFromSuperviewWithoutNeedingDisplay];
}

- (void)addSubviewIfNeeded:(NSView *)view
{
  if ( [view superview] == nil )
    [self addSubview:view];
}

- (void)toggleShaded
{
  NSSize size;
  NSRect frame;
  NSPoint new_pos;
  WAView *eqView, *plView;
  MainWindow *eqWindow, *plWindow;
  BOOL eqDocked, plDocked;

  plWindow = [[WinAmp instance] playlistWindow];
  plView = [[WinAmp instance] playlistView];
  eqWindow = [[WinAmp instance] eqWindow];
  eqView = [[WinAmp instance] eqView];
  eqDocked = [eqView isDockedToBotton:self];
  plDocked = [plView isDockedToBotton:self];
  
  frame = [[self window] frame];
  new_pos = frame.origin;
  [config setBoolValue:![config boolValueForKey:player_shaded]
	        forKey:player_shaded];
  size = [MainView calcSize];

  if ( ![config boolValueForKey:player_shaded] ) {
    [sprev removeFromSuperview];
    [splay removeFromSuperview];
    [spause removeFromSuperview];
    [sstop removeFromSuperview];
    [sfwd removeFromSuperview];
    [seject removeFromSuperview];
    [self removeIfNeeded:sposbar];
    [self removeIfNeeded:stime_min];
    [self removeIfNeeded:stime_sec];
    [visView setAutohide:YES];
    [self addSubview:visView];
    new_pos.y = new_pos.y + frame.size.height - size.height;
  } else {
    [self addSubview:sprev];
    [self addSubview:splay];
    [self addSubview:spause];
    [self addSubview:sstop];
    [self addSubview:sfwd];
    [self addSubview:seject];
    if ( [Input isPlaying] ) 
      {
	[self addSubview:sposbar];
	[self addSubview:stime_min];
	[self addSubview:stime_sec];
      }
    [self removeIfNeeded:visView];
    [visView setAutohide:NO];
    new_pos.y = new_pos.y - size.height + frame.size.height;
  }
  frame = NSMakeRect(new_pos.x, new_pos.y, size.width,size.height);
  [[self window] setFrame:frame display:YES];

  [self loadVisualization];

  if ( eqDocked )
    {
      NSRect his = [eqWindow frame];

      plDocked = [plView isDockedToBotton:eqView];
      his.origin.y = frame.origin.y - his.size.height;
      [eqWindow setFrame:his display:YES];
      //[eqWindow saveFrameUsingName:[eqWindow name]];

      if ( plDocked )
	{
	  NSRect pl = [plWindow frame];
	  pl.origin.y = his.origin.y - pl.size.height;
	  [plWindow setFrame:pl display:YES];
	  //[plWindow saveFrameUsingName:[plWindow name]];
	}
    }
  else if ( plDocked )
    {
      NSRect his = [plWindow frame];

      eqDocked = [eqView isDockedToBotton:plView];
      his.origin.y = frame.origin.y - his.size.height;
      [plWindow setFrame:his display:YES];
      //[plWindow saveFrameUsingName:[plWindow name]];

      if ( eqDocked )
	{
	  NSRect pl = [eqWindow frame];
	  pl.origin.y = his.origin.y - pl.size.height;
	  [eqWindow setFrame:pl display:YES];
	  //[eqWindow saveFrameUsingName:[eqWindow name]];
	}
    }
}

- (void)shade_pressed:button
{
  [self toggleShaded];
}

- (void)button_pressed:button
{
}

- (void)showMenu:(NSMenu *)amenu origin:(NSPoint)origin 
{
  [NSMenu popUpContextMenu:amenu 
	         withEvent:[NSApp currentEvent]
	           forView:self];
}

- (void)menu_pressed:button
{
  NSPoint o;
  o = [button frame].origin;
  o.y = [[self window] frame].origin.y - 14;
  o.x += [[self window] frame].origin.x;
  [self showMenu:[NSApp mainMenu] origin:o];
}

- (Button *)playlistButton
{
  return playlist;
}

- (Button *)eqButton
{
  return eq;
}

- (void)close_button:button
{
  [NSApp terminate:self];
}


- (int)volume_frame_cb:(int)pos
{
  return (int)rint((pos/52.0)*28);  
}


- (void)volume_motion_cb:(id)slider
{
  int v = (int)rint(([slider intValue]/51.0)*100);
  [self lockInfoText:[NSString stringWithFormat:@"VOLUME: %d%%", v]];
  [Control setVolume:v];
}

- (void)volume_release_cb:(id)slider
{
  [self unlockInfoText];
}

- (void)volumeChanged:(NSNotification *)notification
{
  int val = [[[notification userInfo] objectForKey:@"volume"] intValue];
  val = val > 0 ? (val*51)/100 : 0;
  [volume setIntValue:val];
}

- (int)balance_frame_cb:(int)pos
{
  return ((abs(pos-12)*28)/13);
}

- (void)balance_motion_cb:(id)slider
{
  int pos = [slider intValue];
  int prct = (((float)pos/12.0) * 100.0) - 100;
  NSString *s = nil;

  if ( prct < 0 ) 
    {
      s = [NSString stringWithFormat:@"BALANCE: %d%% LEFT", -prct];
    } 
  else if ( prct == 0 ) 
    {
      s = @"BALANCE: CENTER";
    }  
  else if ( prct > 0 ) 
    {
      s = [NSString stringWithFormat:@"BALANCE: %d%% RIGHT", prct];
    }
  [self lockInfoText:s];
  [Control setBalance:prct];
}

- (void)balanceChanged:(NSNotification *)notification
{
  int val = [[[notification userInfo] objectForKey:@"balance"] intValue];
  val = ((val+100)*24)/200;
  [balance setIntValue:val];
}

- (void)balance_release_cb:(id)slider
{
  [self unlockInfoText];
}

- (void)pos_motion_cb:(id)slider
{
  int length,time;
  NSString *s;
//  length=playlist_get_current_length()/1000;
  length = [Control getPlayingSongLength]/1000;
  time=(length*[slider intValue])/100;
  s = [NSString stringWithFormat:@"SEEK TO: %d:%-2.2d/%d:%-2.2d (%d%%)",
    time/60,time%60,length/60,length%60,(length!=0)?(time*100)/length:0];
  [self lockInfoText:s];
}

- (void)pos_release_cb:(id)slider
{
  int length, time;
  [self unlockInfoText];

  length = [Control getPlayingSongLength]/1000;
  time=(length*[slider intValue])/100;
  [Control seekToTime:time];
}

- (int)spos_frame_cb:(int)pos
{
#if 0
  if(pos<6)
    mainwin_sposition->hs_knob_nx = mainwin_sposition->hs_knob_px = 17;
  else if(pos<9)
    mainwin_sposition->hs_knob_nx = mainwin_sposition->hs_knob_px = 20;
  else
    mainwin_sposition->hs_knob_nx = mainwin_sposition->hs_knob_px = 23;
#endif
  return 1;
}

- (void)spos_motion_cb:(id)slider
{
}

- (void)spos_release_cb:(id)slider
{
  int length, time;
  [self unlockInfoText];

  length = [Control getPlayingSongLength]/1000;
  time=(length*[slider intValue])/100;
  [Control seekToTime:time];
}

- (void)showFileInfoBox:(NSString *)filename
{
  if ( filename != nil ) {
    [Control popupFileInfoBox:filename];
  }
}

- (void)clutter_press:sender
{
  int sel = [sender selectedMenuItem];
  NSPoint o = [[self window] frame].origin;
  int idx;
  id <NSMenuItem> item;
  
  switch ( sel ) {
  case MENUROW_OPTIONS:
    o.x = [sender frame].origin.x+o.x + 8;
    o.y = o.y - [sender frame].origin.y;
    idx = [[NSApp menu] indexOfItemWithTitle:@"Options"];
    item = [[NSApp menu] itemAtIndex:idx];
    [self showMenu:[item submenu] origin:o];
    [sender clearSelection];
    break;
    
  case MENUROW_ALWAYS:
    [config toggleBoolValueForKey:always_on_top];
    [((MainWindow *)[self window]) updateAlwaysOnTop];
    break;
    
  case MENUROW_FILEINFOBOX:
    [self showFileInfoBox:[Input playingFile]];
    break;

  case MENUROW_DOUBLESIZE:
    break;
    
  case MENUROW_VISUALIZATION:
    o.x = [sender frame].origin.x+o.x + 8;
    o.y = o.y - [sender frame].origin.y - 36;
    idx = [[NSApp menu] indexOfItemWithTitle:@"Visualization"];
    item = [[NSApp menu] itemAtIndex:idx];
    [self showMenu:[item submenu] origin:o];
    [sender clearSelection];
    break;
  }
}

- (void)removeVisualization
{
  if ( visPlugin != nil )
    {
      if ( visView != nil )
	{
	  [visPlugin removeView:visView];
	  [visView release];
	  visView = nil;
	}

      [visPlugin release];
      visPlugin = nil;
    }

  if ( svisPlugin != nil )
    {
      if ( svisView != nil )
	{
	  [svisPlugin removeView:svisView];
	  [svisView release];
	  svisView = nil;
	}

      [svisPlugin release];
      svisPlugin = nil;
    }

}

- (void)loadVisualization
{
  [self removeVisualization];

  if ( [config boolValueForKey:player_shaded] )
    {
      svisPlugin = [Visualization defaultVisualization];
      if ( svisPlugin != nil && [svisPlugin goodForSmallView] == NO )
	svisPlugin = [Visualization pluginWithName:@"VU"];
      if ( svisPlugin != nil )
	{
	  NSRect frame = [svisPlugin visFrameForRect:NSMakeRect(79,4, 38, 7)];

	  [svisPlugin retain];
	  svisView = [svisPlugin getViewWithFrame:frame owner:self];
	  [svisView retain];
	  
	  [self addSubview:svisView];
	}
    }
  else
    {
      visPlugin = [Visualization defaultVisualization];
      if ( visPlugin != nil && [visPlugin canEmbed] )
	{
	  NSRect frame = [visPlugin visFrameForRect:NSMakeRect(24, 43, 76, 16)];
	  visView = [visPlugin getViewWithFrame:frame owner:self];
	  [visView retain];
	  [self addSubview:visView];
	  [visPlugin retain];
	}
      else
	visPlugin = nil;
    }
}
  
- initWithFrame:(NSRect)frame
{
  id left, right;
  NSPoint menuNormal, menuPushed, closeNormol, closePushed;
  NSPoint leftPushed, leftNormal, rightNormal, rightPushed;
  SEL leftSel, rightSel;
  id ui = [WinAmp instance];
  
  menuNormal = NSMakePoint(0,0);
  menuPushed = NSMakePoint(0,9);
  closeNormol = NSMakePoint(18,0);
  closePushed = NSMakePoint(18,9);

  if ( [config boolValueForKey:close_box_on_left] ) {
    leftSel = @selector(close_button:);
    leftNormal = closeNormol;
    leftPushed = closePushed;
    rightSel = @selector(menu_pressed:);
    rightNormal = menuNormal;
    rightPushed = menuPushed;
  } else {
    rightSel = @selector(close_button:);
    rightNormal = closeNormol;
    rightPushed = closePushed;
    leftSel = @selector(menu_pressed:);
    leftNormal = menuNormal;
    leftPushed = menuPushed;
  }

  [super initWithFrame:frame];

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
       selector:@selector(playStatusChanged:)
	   name:PlayStatusChangedNotification
	 object:nil];

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(visTypeChanged:)
	   name:DefaultVisualizationChangedNotification
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
       selector:@selector(volumeChanged:)
	   name:VolumeChangedNotification
	 object:nil];

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(balanceChanged:)
	   name:BalanceChangedNotification
	 object:nil];


  left = [[Button alloc] init:NSMakeRect(6,3,9,9)
			     :leftNormal
			     :leftPushed
			     :self
			     :leftSel
			     :@selector(titlebar)];
  [left setAllowDraw:NO];
  [self addSubview:left];

  right = [[Button alloc] init:NSMakeRect(264,3,9,9)
			      :rightNormal
			      :rightPushed
			      :self
			      :rightSel
			      :@selector(titlebar)];
  [right setAllowDraw:NO];
  [self addSubview:right];

  if ( [config boolValueForKey:close_box_on_left] ) {
    menu = right;
    quit = left;
  } else {
    menu = left;
    quit = right;
  }
  [menu sendActionOn:NSLeftMouseDownMask];


  minimize = [[Button alloc] init:NSMakeRect(244,3,9,9)
					:NSMakePoint(9,0)
					:NSMakePoint(9,9)
					:self
					:@selector(button_pressed:)
					:@selector(titlebar)];
  [minimize setAllowDraw:NO];
  [self addSubview:minimize];

  shade = [[Button alloc] init:NSMakeRect(254,3,9,9)
			      :NSMakePoint(0,[config boolValueForKey:player_shaded] ? 27 : 18)
			      :NSMakePoint(9,[config boolValueForKey:player_shaded] ? 27 : 18 )
			      :self
			      :@selector(shade_pressed:)
			      :@selector(titlebar)];
  [shade setAllowDraw:NO];
  [self addSubview:shade];


  playlist_prev = [[Button alloc] init:NSMakeRect(16,88,23,18)
					     :NSMakePoint(0,0)
					     :NSMakePoint(0,18)
					     :ui
					     :@selector(previous:)
					     :@selector(cbuttons)];
  [self addSubview:playlist_prev];
  play = [[Button alloc] init:NSMakeRect(39,88,23,18)
				    :NSMakePoint(23,0)
				    :NSMakePoint(23,18)
				    :ui
				    :@selector(play:)
				    :@selector(cbuttons)];
  [self addSubview:play];
  pause = [[Button alloc] init:NSMakeRect(62,88,23,18)
				     :NSMakePoint(46,0)
				     :NSMakePoint(46,18)
				     :ui
				     :@selector(pause:)
				     :@selector(cbuttons)];
  [self addSubview:pause];
  stop = [[Button alloc] init:NSMakeRect(85,88,23,18)
				    :NSMakePoint(69,0)
				    :NSMakePoint(69,18)
				    :ui
				    :@selector(stop:)
				    :@selector(cbuttons)];
  [self addSubview:stop];
  fwd =   [[Button alloc] init:NSMakeRect(108,88,22,18)
				     :NSMakePoint(92,0)
				     :NSMakePoint(92,18)
				     :ui
				     :@selector(next:)
				     :@selector(cbuttons)];
  [self addSubview:fwd];
  eject = [[Button alloc] init:NSMakeRect(136,89,22,16)
				     :NSMakePoint(114,0)
				     :NSMakePoint(114,16)
				     :ui
				     :@selector(eject:)
				     :@selector(cbuttons)];
  [self addSubview:eject];


  sprev = [[Button alloc] init:NSMakeRect(169,4,8,7)
			      :ui
			      :@selector(previous:)];
  if ( [config boolValueForKey:player_shaded] )
    [self addSubview:sprev];

  splay = [[Button alloc] init:NSMakeRect(177,4,10,7)
			      :ui
			      :@selector(play:)];
  if ( [config boolValueForKey:player_shaded] )
    [self addSubview:splay];

  spause = [[Button alloc] init:NSMakeRect(187,4,10,7)
			       :ui
			       :@selector(pause:)];
  if ( [config boolValueForKey:player_shaded] )
    [self addSubview:spause];

  sstop = [[Button alloc] init:NSMakeRect(197,4,9,7)
			       :ui
			       :@selector(stop:)];
  if ( [config boolValueForKey:player_shaded] )
    [self addSubview:sstop];

  sfwd  = [[Button alloc] init:NSMakeRect(206,4,8,7)
			       :ui
			       :@selector(next:)];
  if ( [config boolValueForKey:player_shaded] )
    [self addSubview:sfwd];

  seject = [[Button alloc] init:NSMakeRect(216,4,9,7)
			       :ui
			       :@selector(eject:)];
  if ( [config boolValueForKey:player_shaded] )
    [self addSubview:seject];
  

  shuffle = [[Button alloc] init:NSMakeRect(164,89,46,15)
				:NSMakePoint(28,0)
				:NSMakePoint(28,15)
				:NSMakePoint(28,30)
				:NSMakePoint(28,45)
				:ui
				:@selector(shuffle:)
				:@selector(shufrep)];
  [self addSubview:shuffle];

  repeat = [[Button alloc] init:NSMakeRect(210,89,28,15)
			       :NSMakePoint(0,0)
			       :NSMakePoint(0,15)
			       :NSMakePoint(0,30)
			       :NSMakePoint(0,45)
			       :ui
			       :@selector(repeat:)
			       :@selector(shufrep)];
  [self addSubview:repeat];

  eq = [[Button alloc] init:NSMakeRect(219,58,23,12)
			       :NSMakePoint(0,61)
			       :NSMakePoint(46,61)
			       :NSMakePoint(0,73)
			       :NSMakePoint(46,73)
			       :ui
			       :@selector(hideShowEq:)
			       :@selector(shufrep)];
  [self addSubview:eq];
  [eq toggle:[config boolValueForKey:equalizer_visible]];

  playlist = [[Button alloc] init:NSMakeRect(242,58,23,12)
			       :NSMakePoint(23,61)
			       :NSMakePoint(69,61)
			       :NSMakePoint(23,73)
			       :NSMakePoint(69,73)
			       :ui
			       :@selector(hideShowPlaylist:)
			       :@selector(shufrep)];
  [self addSubview:playlist];
  [playlist toggle:[config boolValueForKey:playlist_visible]];


  info_box = [[TextBox alloc] initWithFrame:NSMakeRect(112, 27, 153, 1)
					   :self
					   :@selector(text)];
  [self addSubview:info_box];
  [info_box setScroll:[config boolValueForKey:autoscroll]];
  [self updateInfoText];

  rate_box = [[TextBox alloc] initWithFrame:NSMakeRect(111, 43, 15, 0)
					   :self
					   :@selector(text)];
  [self addSubview:rate_box];

  freq_box = [[TextBox alloc] initWithFrame:NSMakeRect(156, 43, 10, 0)
					   :self
					   :@selector(text)];
  [self addSubview:freq_box];

  menurow = [[MenuRow alloc] initWithPoint:NSMakePoint(10,22)
					  :NSMakePoint(304,0)
					  :NSMakePoint(304,44)
					  :self
					  :@selector(clutter_press:)
					  :@selector(titlebar)];
  [self addSubview:menurow];

  volume = [[Slider alloc] initWithFrame:NSMakeRect(107,57,68,13)
					:NSMakePoint(15,420)
					:NSMakePoint(0, 420) 
					:NSMakeSize(14,11)
					:15
					:0
					:0
					:51
					:self
					:@selector(volume_frame_cb:)
					:@selector(volume_motion_cb:)
					:@selector(volume_release_cb:)
					:@selector(volume)];
  [self addSubview:volume];

  balance = [[Slider alloc] initWithFrame:NSMakeRect(177,57,38,13)
					 :NSMakePoint(15,420)
					 :NSMakePoint(0, 420)
					 :NSMakeSize(14,11)
					 :15
					 :9
					 :0
					 :24
					 :self
					 :@selector(balance_frame_cb:)
					 :@selector(balance_motion_cb:)
					 :@selector(balance_release_cb:)
					 :@selector(balance)];
  [self addSubview:balance];

  monostereo = [[MonoStereo alloc] initPos:NSMakePoint(212, 41)
					  :@selector(monostereo)];
  [self addSubview:monostereo];

  playstatus = [[PlayStatus alloc] initWithPos:NSMakePoint(24,28)];
  [self addSubview:playstatus];

  minus_num = [[Number alloc] initPos:NSMakePoint(36,26) 
				     :@selector(numbers)];
  tenmin_num = [[Number alloc] initPos:NSMakePoint(48,26) 
				     :@selector(numbers)];
  min_num = [[Number alloc] initPos:NSMakePoint(60,26) 
				     :@selector(numbers)];
  tensec_num = [[Number alloc] initPos:NSMakePoint(78,26) 
				     :@selector(numbers)];
  sec_num = [[Number alloc] initPos:NSMakePoint(90,26) 
				     :@selector(numbers)];

  posbar = [[Slider alloc] initWithFrame:NSMakeRect(16,72,248,10)
					 :NSMakePoint(248,0)
					 :NSMakePoint(278, 0)
					 :NSMakeSize(29,10)
					 :10
					 :0
					 :0
					 :100
					 :self
					 :0
					 :@selector(pos_motion_cb:)
					 :@selector(pos_release_cb:)
					 :@selector(posbar)];
  
//  [self addSubview:posbar];

  sposbar = [[Slider alloc] initWithFrame:NSMakeRect(226,4,17,7)
					 :NSMakePoint(17,36)
					 :NSMakePoint(17,36)
					 :NSMakeSize(3,7)
					 :36
					 :0
					 :0
					 :100
					 :self
					 :@selector(spos_frame_cb:)
					 :@selector(spos_motion_cb:)
					 :@selector(spos_release_cb:)
					 :@selector(titlebar)];
  stime_min = [[TextBox alloc] initWithFrame:NSMakeRect(130, 4, 15, 1)
					   :self
					   :@selector(text)];
  stime_sec = [[TextBox alloc] initWithFrame:NSMakeRect(147, 4, 10, 1)
					   :self
					   :@selector(text)];
  if ( [config boolValueForKey:player_shaded] ) {
    [self addSubview:stime_min];
    [self addSubview:stime_sec];
  }
  

  [self loadVisualization];

  return self;
}


- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [self removeVisualization];

  [menu release];
  [minimize release];
  [shade release];
  [quit release];
  [playlist_prev release];
  [play release];
  [pause release];
  [stop release];
  [fwd release];
  [eject release];
  [sprev release];
  [splay release];
  [spause release];
  [sstop release];
  [sfwd release];
  [seject release];
  [shuffle release];
  [repeat release];
  [playlist release];
  [eq release];

  [info_box release];
  [freq_box release];
  [rate_box release];
  [menurow release];
  [volume release];
  [balance release];
  [monostereo release];
  [playstatus release];
  [minus_num release];
  [tenmin_num release];
  [min_num release];
  [tensec_num release];
  [sec_num release];
  [stime_min release];
  [stime_sec release];

  [posbar release];
  [sposbar release];

  [info_text release];

  [super dealloc];
}

- (void)drawRect:(NSRect)rect 
{
  float h = [self frame].size.height;
  //float ih = [[currentSkin main] size].height;

  [[currentSkin main] 
    compositeToPoint:NSMakePoint(0,h)
	   operation:NSCompositeCopy];  

  if([[self window] isKeyWindow] || ![config boolValueForKey:dim_titlebar])
    [[currentSkin titlebar] compositeToPoint:NSMakePoint(0,14)
	   fromRect:flipRect(NSMakeRect(27,29*[config boolValueForKey:player_shaded], 275, 14),
			     [currentSkin titlebar])
	  operation:NSCompositeCopy];
  else
    [[currentSkin titlebar] compositeToPoint:NSMakePoint(0,14)
	   fromRect:flipRect(NSMakeRect(27,(27*[config boolValueForKey:player_shaded])+15, 275,
					14), [currentSkin titlebar])
	  operation:NSCompositeCopy];
}

- (void)mouseDown:(NSEvent *)theEvent 
{
  NSPoint startPoint, curPoint;
  NSRect frame = [[self window] frame], eqFrame, plFrame;
  int xdif, ydif;
  BOOL move_eq = NO, move_playlist = NO;
  MainWindow *plWindow, *eqWindow;
  WAView *plView, *eqView;
  int sd = [config intValueForKey:snap_distance];
  int w = frame.size.width;
  int h = frame.size.height;
  int sw = [[NSScreen mainScreen] frame].size.width;
  int sh = [[NSScreen mainScreen] frame].size.height;
  BOOL playlistDockedToMain = NO,  
    playlistDockedToEq = NO, 
    eqDockedToMain = NO,
    eqDockedToPlaylist = NO;


  if ([theEvent type] == NSLeftMouseDown) 
    [[WinAmp instance] windowCameToFront];

  startPoint = [theEvent locationInWindow];

  plWindow = [[WinAmp instance] playlistWindow];
  eqWindow = [[WinAmp instance] eqWindow];
  plView = [[WinAmp instance] playlistView];
  eqView = [[WinAmp instance] eqView];

  eqDockedToMain = [eqView isDockedTo:self];
  eqDockedToPlaylist = [eqView isDockedTo:plView];
  playlistDockedToMain = [plView isDockedTo:self];
  playlistDockedToEq = [plView isDockedTo:eqView];
  
  if ( eqDockedToMain )
    move_eq = YES;
  else if ( eqDockedToPlaylist && playlistDockedToMain )
    move_eq = YES;

  if ( playlistDockedToMain )
    move_playlist = YES;
  else if ( playlistDockedToEq && eqDockedToMain )
    move_playlist = YES;

  if (startPoint.y > frame.size.height-14 
      || [config boolValueForKey:easy_move] ) {
    startPoint = [[self window] convertBaseToScreen:startPoint];
    xdif = startPoint.x - frame.origin.x;
    ydif = startPoint.y - frame.origin.y;
    while (1) {
      theEvent = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
      curPoint = [theEvent locationInWindow];
      curPoint = [[self window] convertBaseToScreen:curPoint];
      curPoint.x = curPoint.x-xdif;
      curPoint.y = curPoint.y-ydif;

      frame = [[self window] frame];

      if ( [config boolValueForKey:snap_windows] ) {
	if(curPoint.x > -sd && curPoint.x < sd)
	  curPoint.x = 0;
	if((curPoint.x + w) > sw - sd && (curPoint.x + w) < sw + sd)
	  curPoint.x = sw - w;
	if(curPoint.y > -sd && curPoint.y < sd)
	  curPoint.y = 0;
	if((curPoint.y + h) > sh - sd && (curPoint.y + h) < sh + sd) 
	  curPoint.y = sh - h;
      }

      if ( [config boolValueForKey:playlist_visible] ) {
	plFrame = [plWindow frame];

	if(move_playlist) {
	  [plWindow setFrameOrigin:NSMakePoint(
	    (plFrame.origin.x - frame.origin.x) + curPoint.x,
	    (plFrame.origin.y - frame.origin.y) + curPoint.y)];
	} else {
	  dock(&curPoint.x, &curPoint.y, w, h, plFrame.origin.x, 
	       plFrame.origin.y, plFrame.size.width, 
	       plFrame.size.height);
	}
      }
      

      if ( [config boolValueForKey:equalizer_visible] ) {
	eqFrame = [eqWindow frame];

	if(move_eq) {
	  [eqWindow setFrameOrigin:NSMakePoint(
	    (eqFrame.origin.x - frame.origin.x) + curPoint.x,
	    (eqFrame.origin.y - frame.origin.y) + curPoint.y)];
	} else {
	  dock(&curPoint.x, &curPoint.y, w, h, eqFrame.origin.x, 
	       eqFrame.origin.y, eqFrame.size.width, 
	       eqFrame.size.height);
	}
      }

      [[self window] setFrameOrigin:NSMakePoint(curPoint.x, curPoint.y)];
      

      if ([theEvent type] == NSLeftMouseUp)
	break;
    }
  }

  // no save when we move the window
  /*
    [[self window] saveFrameUsingName:[(MainWindow *)[self window] name]];
  if ( move_eq )
    [eqWindow saveFrameUsingName:[eqWindow name]];
  if ( move_playlist )
    [plWindow saveFrameUsingName:[plWindow name]];
  */
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
  return YES;
}

- (void)updateInfoText
{
  static NSString *version_text = nil; 

  if ( version_text == nil )
    version_text = [[NSString stringWithFormat:@"%@ %@", getPackageName(),
			      getVersion()]
		     retain];
  
  if ( infoTextLocked == NO ) 
    {
      [info_box setStringValue:info_text ? info_text : version_text];
    }
}

- (void)lockInfoText:(NSString *)string
{
  infoTextLocked = YES;
  [info_box setStringValue:string];
}


- (void)unlockInfoText
{
  infoTextLocked = NO;
  [self updateInfoText];
}

- (void)setInfoText:(NSString *)string
{
  [info_text release];
  info_text = [string retain];
  [self updateInfoText];
}

- (void)setRate:(int)rate
{
  NSString *rate_string;
  if( rate != -1)
    {
      rate_string = [NSString stringWithFormat:@"%d", rate];
      [rate_box setStringValue:rate_string];
    }
}

- (void)setRate:(int)rate
	  freq:(int)freq
   numChannels:(int)channels;

{
  if ( rate == 0 && freq == 0 && channels == 0 ) {
    [rate_box setStringValue:@""];
    [freq_box setStringValue:@""];
    [self setInfoText:nil];
    [monostereo setNumChannels:0];

    [playstatus setStatus:STATUS_STOP];
    [self removeIfNeeded:minus_num];
    [self removeIfNeeded:tenmin_num];
    [self removeIfNeeded:min_num];
    [self removeIfNeeded:tenmin_num];
    [self removeIfNeeded:sec_num];
    [self removeIfNeeded:tensec_num];
    [self removeIfNeeded:posbar];
    [self removeIfNeeded:sposbar];
    [self removeIfNeeded:stime_min];
    [self removeIfNeeded:stime_sec];
    [self setNeedsDisplay:YES];
  } else {
    [self addSubviewIfNeeded:min_num];
    [self addSubviewIfNeeded:tenmin_num];
    [self addSubviewIfNeeded:min_num];
    [self addSubviewIfNeeded:sec_num];
    [self addSubviewIfNeeded:minus_num];
    [self addSubviewIfNeeded:tensec_num];

    [self setRate:rate];
    [freq_box setIntValue:freq];
    [monostereo setNumChannels:channels];
    [playstatus setStatus:STATUS_PLAY];
    [self addSubviewIfNeeded:posbar];
    if ( [config boolValueForKey:player_shaded] ) 
      {
	[self addSubviewIfNeeded:sposbar];
	[self addSubviewIfNeeded:stime_min];
	[self addSubviewIfNeeded:stime_sec];
      }
  }
}


- (void)setNumbers:(int)minus 
		  :(int)_tenmin_num 
		  :(int)_min_num 
		  :(int)_tensec_num
		  :(int)_sec_num
{
  if ( ![config boolValueForKey:player_shaded] ) {
    [minus_num setNumber:minus];
    [tenmin_num setNumber:_tenmin_num];
    [min_num setNumber:_min_num];
    [tensec_num setNumber:_tensec_num];
    [sec_num setNumber:_sec_num];
  }
}

- (void)setSNumbers:(NSString *)min :(NSString *)sec
{
  if ( [config boolValueForKey:player_shaded] ) {
    [stime_min setStringValue:min];
    [stime_sec setStringValue:sec];
  }
}

- (void)songStarted:(NSNotification *)notification
{
  NSDictionary *info = [notification userInfo];

  [self setInfoText:[info objectForKey:@"title"]];

  [self setRate:[[info objectForKey:@"rate"] intValue]
	   freq:[[info objectForKey:@"frequency"] intValue]
    numChannels:[[info objectForKey:@"numChannels"] intValue]];
}

- (void)bitrateChanged:(NSNotification *)notification
{
  NSDictionary *info = [notification userInfo];
  int rate = [[info objectForKey:@"rate"] intValue];
  [self setRate:rate];
}

- (void)songEnded:(NSNotification *)notification
{
  [self setRate:0 freq:0 numChannels:0];
  [self setInfoText:nil];
}

- (void)setPosbar:(int)val
{
  if ( ![config boolValueForKey:player_shaded] )
    [posbar setIntValue:val];
}

- (void)setSposbar:(int)val
{
  if ( [config boolValueForKey:player_shaded] )
    [sposbar setIntValue:val];
}

- (void)playStatusChanged:(NSNotification *)notification
{
  NSNumber *status = [[notification userInfo] objectForKey:@"status"];
  [playstatus setStatus:[status intValue]];
}

- (void)visTypeChanged:(NSNotification *)notification
{
  [self loadVisualization];
}

- (void)shuffleValueChanged:(NSNotification *)notification
{
  BOOL val = [[[notification userInfo] objectForKey:@"shuffle"] boolValue];
  [shuffle toggle:val];
}

- (void)repeatValueChanged:(NSNotification *)notification
{
  BOOL val = [[[notification userInfo] objectForKey:@"repeat"] boolValue];
  [repeat toggle:val];
}

- (BOOL)becomeFirstResponder
{
  return YES;
}

- (BOOL)resignFirstResponder
{
  return YES;
}

- (BOOL)acceptsFirstResponder
{
  return YES;
}

- (BOOL)isVisible
{
  return [config boolValueForKey:player_visible];
}

@end

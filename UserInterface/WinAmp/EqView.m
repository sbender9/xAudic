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
#import "EqView.h"
#import <MXA/Control.h>
#import <MXA/Plugins.h>
#import "Configure.h"
#import "Skin.h"
#import "WinAmp.h"
#import "Button.h"
#import "TextBox.h"
#import "MenuRow.h"
#import "Slider.h"
#import "MonoStereo.h"
#import "Number.h"
#import "EqGraph.h"
#import "EqSlider.h"
#import "MainView.h"
#import "PlaylistView.h"


@implementation EqView

+ (NSSize)calcSize
{
  NSSize size;
  size.width = 275;
  size.height = [config boolValueForKey:eq_shaded] ? 14 : 116;
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
  WAView *mView, *plView;
  MainWindow *mWindow, *plWindow;
  BOOL mDocked, plDocked;

  plWindow = [[WinAmp instance] playlistWindow];
  plView = [[WinAmp instance] playlistView];
  mWindow = [[WinAmp instance] mainWindow];
  mView = [[WinAmp instance] mainView];
  mDocked = [mView isDockedToBotton:self];
  plDocked = [plView isDockedToBotton:self];

  
  frame = [[self window] frame];
  new_pos = frame.origin;
  [config setBoolValue:![config boolValueForKey:eq_shaded]
	        forKey:eq_shaded];
  size = [EqView calcSize];

  if ( ![config boolValueForKey:eq_shaded] ) 
    {
      [svol removeFromSuperview];
      [sbal removeFromSuperview];
      new_pos.y = new_pos.y + frame.size.height - size.height;
    } 
  else 
    {
      [self addSubview:svol];
      [self addSubview:sbal];
      new_pos.y = new_pos.y - size.height + frame.size.height;
    }
  frame = NSMakeRect(new_pos.x, new_pos.y, size.width,size.height);
  [[self window] setFrame:frame display:YES];

  if ( mDocked )
    {
      NSRect his = [mWindow frame];

      plDocked = [plView isDockedToBotton:mView];
      his.origin.y = frame.origin.y - his.size.height;
      [mWindow setFrame:his display:YES];
      //[mWindow saveFrameUsingName:[mWindow name]];

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

      mDocked = [mView isDockedToBotton:plView];
      his.origin.y = frame.origin.y - his.size.height;
      [plWindow setFrame:his display:YES];
      //[plWindow saveFrameUsingName:[plWindow name]];

      if ( mDocked )
	{
	  NSRect pl = [mWindow frame];
	  pl.origin.y = his.origin.y - pl.size.height;
	  [mWindow setFrame:pl display:YES];
	  //[mWindow saveFrameUsingName:[mWindow name]];
	}
    }

}

- (void)shade_pressed:button
{
  [self toggleShaded];
}

- (BOOL)isFlipped
{
  return YES;
}

- (void)button_pressed:button
{
}

- (void)on_pressed:button
{
  [config setequalizer_active:[button intValue]];
  [Control applyEQ];
}

- (void)auto_pressed:button
{
  [config setequalizer_autoload:[button intValue]];
}

- (void)close_button:sender
{
  [[WinAmp instance] hideShowEq:sender];
}

- (void)preset_pressed:button
{
  [NSMenu popUpContextMenu:[[WinAmp instance] eqMenu]
	         withEvent:[NSApp currentEvent]
	           forView:self];
}


- (void)motion:slider
{
  NSString *bandname[11]={@"PREAMP",@"60HZ",@"170HZ",@"310HZ",@"600HZ",
			 @"1KHZ",@"3KHZ",@"6KHZ",@"12KHZ",@"14KHZ",@"16KHZ"};


  [[WinAmp instance] lockInfoText:
	  [NSString stringWithFormat:@"EQ: %@: %+.1f DB",
	    bandname[[slider band]],
	    [slider position]]];

  if ( [slider band] == 0 )
    [config setequalizer_preamp:[slider position]];
  else {
    int band = [slider band]-1;
    [config seteq_band:[slider position] :band];
  }

  [graph setNeedsDisplay:YES];
  [Control applyEQ];
}

- (int)svol_frame_cb:(int)pos
{
  return 1;
  /*
  if (pos < 32)
    return 1;
  else if (pos < 63)
    return 4;
  else
    return 7;
  */
}

- (void)svol_motion_cb:slider
{
  MainView *mainv = [[WinAmp instance] mainView];
  int v = (int)rint(([slider intValue]/94.0)*100);
  [mainv lockInfoText:[NSString stringWithFormat:@"VOLUME: %d%%", v]];
  [Control setVolume:v];
}

- (void)svol_release_cb:sender
{
  [[[WinAmp instance] mainView] unlockInfoText];
}

- (void)volumeChanged:(NSNotification *)notification
{
  int val = [[[notification userInfo] objectForKey:@"volume"] intValue];
  val = val > 0 ? (val*94.0)/100.0 : 0;
  [svol setIntValue:val];
}

- (int)sbal_frame_cb:(int)pos
{
  return 1;
  /*
  if(pos < 10)
    return 11;
  else if (pos < 14)
    return 14;
  else
    return 17;
  */
}

- (void)sbal_motion_cb:slider
{
  int pos = [slider intValue];
  int prct = (((float)pos/19.0) * 100.0)-100;
  NSString *s = nil;

  if ( prct < 0  ) 
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
  [[[WinAmp instance] mainView] lockInfoText:s];
  [Control setBalance:prct];
}

- (void)sbal_release_cb:sender
{
  [[[WinAmp instance] mainView] unlockInfoText];
}

- (void)balanceChanged:(NSNotification *)notification
{
  int val = [[[notification userInfo] objectForKey:@"balance"] intValue];
  val = ((val+100)*38.0)/200.0;
  [sbal setIntValue:val];
}

- initWithFrame:(NSRect)frame
{
  int i;
  [super initWithFrame:frame];

  on = [[Button alloc] init:NSMakeRect(14,18,25,12)
			       :NSMakePoint(10,119)
			       :NSMakePoint(128,119)
			       :NSMakePoint(69,119)
			       :NSMakePoint(187,119)
			       :self
			       :@selector(on_pressed:)
			       :@selector(eqmain)];
  [self addSubview:on];
  [on toggle:[config equalizer_active]];

  autob = [[Button alloc] init:NSMakeRect(39,18,33,12)
				 :NSMakePoint(35,119)
				 :NSMakePoint(153,119)
				 :NSMakePoint(94,119)
				 :NSMakePoint(212,119)
				 :self
				 :@selector(auto_pressed:)
			         :@selector(eqmain)];
  [self addSubview:autob];
  [autob toggle:[config equalizer_autoload]];

  presets = [[Button alloc] init:NSMakeRect(217,18,44,12)
				:NSMakePoint(224,164)
				:NSMakePoint(224,176)
				:self
				:@selector(preset_pressed:)
				:@selector(eqmain)];
  [self addSubview:presets];

  close = [[Button alloc] init:NSMakeRect(264,3,9,9)
			      :NSMakePoint(0,116)
			      :NSMakePoint(0,125)
			      :self
			      :@selector(close_button:)
			      :@selector(eqmain)];
  [close setAllowDraw:NO];
  [self addSubview:close];

  shade = [[Button alloc] init:NSMakeRect(254,3,9,9)
			      :NSMakePoint(254,3)
			      :NSMakePoint(1,38)
			      :self
			      :@selector(shade_pressed:)
			      :@selector(eq_ex)];
  [shade setAllowDraw:NO];
  [self addSubview:shade];
  

  graph = [[EqGraph alloc] initWithPoint:NSMakePoint(86,17)];
  [self addSubview:graph];


  preamp = [[EqSlider alloc] initWithPos:NSMakePoint(21, 38) 
				    band:0
				  target:self
				      cb:@selector(motion:)];
  [self addSubview:preamp];
  [preamp setPosition:[config equalizer_preamp]];

  for( i = 0; i < 10; i++ ) {
    bands[i] = [[EqSlider alloc] initWithPos:NSMakePoint(78+(i*18), 38)
					band:i+1
				      target:self
				      cb:@selector(motion:)];
    [self addSubview:bands[i]];
    [bands[i] setPosition:[config eq_bands][i]];
  }

  svol = [[Slider alloc] initWithFrame:NSMakeRect(61,2,97,8)
			 :NSMakePoint(1,29)
			 :NSMakePoint(1,29)
			 :NSMakeSize(3,7)
			 :4
			 :61
			 :0
			 :94
			 :self
			 :@selector(svol_frame_cb:)
			 :@selector(svol_motion_cb:)
			 :@selector(svol_release_cb:)
			 :@selector(eq_ex)];


  sbal = [[Slider alloc] initWithFrame:NSMakeRect(164,2,42,8)
			 :NSMakePoint(11,29)
			 :NSMakePoint(11,29)
			 :NSMakeSize(3,7)
			 :4
			 :164
			 :0
			 :38
			 :self
			 :@selector(sbal_frame_cb:)
			 :@selector(sbal_motion_cb:)
			 :@selector(sbal_release_cb:)
			 :@selector(eq_ex)];

  if ( [config boolValueForKey:eq_shaded] )
    {
      [self addSubview:svol];
      [self addSubview:sbal];
    }

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
  
  return self;
}

- (void)dealloc
{
  int i;
  
  [on release];
  [autob release];
  [presets release];
  [close release];
  [graph release];
  [preamp release];

  for( i = 0; i < 10; i++ ) 
    {
      [bands[i] release];
    }

  [super dealloc];
}

- (void)drawRect:(NSRect)rect 
{
  [[currentSkin eqmain] 
    compositeToPoint:NSMakePoint(0, [self frame].size.height)
	    fromRect:flipRect(NSMakeRect(0, 0, 275, 116), 
			      [currentSkin eqmain])
	   operation:NSCompositeCopy];

  if([[self window] isKeyWindow] || ![config boolValueForKey:dim_titlebar])
    {
      if ( ![config boolValueForKey:eq_shaded] )
	{
	  [[currentSkin eqmain] 
	    compositeToPoint:NSMakePoint(0,14)
	    fromRect:flipRect(NSMakeRect(0, 134, 275, 14), 
			      [currentSkin eqmain])
	    operation:NSCompositeCopy];
	}
      else
	{
	  [[currentSkin eq_ex] 
	    compositeToPoint:NSMakePoint(0,14)
	    fromRect:flipRect(NSMakeRect(0, 0, 275, 14), 
			      [currentSkin eq_ex])
	    operation:NSCompositeCopy];
	  
	}
    }
  else
    {
      if ( ![config boolValueForKey:eq_shaded] )
	{
	  [[currentSkin eqmain] 
	    compositeToPoint:NSMakePoint(0,14)
	    fromRect:flipRect(NSMakeRect(0, 149, 275, 14), 
			      [currentSkin eqmain])
	    operation:NSCompositeCopy];
	}
      else
	{
	  [[currentSkin eq_ex] 
	    compositeToPoint:NSMakePoint(0,14)
	    fromRect:flipRect(NSMakeRect(0, 15, 275, 14), 
			      [currentSkin eq_ex])
	    operation:NSCompositeCopy];
	}
    }

}

- (void)mouseDown:(NSEvent *)theEvent 
{
  NSPoint startPoint, curPoint, new;
  NSRect frame = [[self window] frame], playerFrame, playlistFrame;
  int xdif, ydif;
  int sd = [config intValueForKey:snap_distance];
  int w = frame.size.width;
  int h = frame.size.height;
  int sw = [[NSScreen mainScreen] frame].size.width;
  int sh = [[NSScreen mainScreen] frame].size.height;
  BOOL done = NO;

  if ([theEvent type] == NSLeftMouseDown) 
    [[WinAmp instance] windowCameToFront];

  startPoint = [theEvent locationInWindow];

  if (startPoint.y > frame.size.height-14 
      || [config boolValueForKey:easy_move] ) {
    startPoint = [[self window] convertBaseToScreen:startPoint];
    xdif = startPoint.x - frame.origin.x;
    ydif = startPoint.y - frame.origin.y;

    if( [config boolValueForKey:player_visible] )
      playerFrame = [[[WinAmp instance] mainWindow] frame];
    if ( [config boolValueForKey:playlist_visible] )
      playlistFrame = [[[WinAmp instance] playlistWindow] frame];

    while (!done) {
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      theEvent = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
      curPoint = [theEvent locationInWindow];

      curPoint = [[self window] convertBaseToScreen:curPoint];
      new = NSMakePoint(curPoint.x-xdif, curPoint.y-ydif);

      if ( [config boolValueForKey:snap_windows] ) {
	if(new.x > -sd && new.x < sd)
	  new.x = 0;
	if((new.x + w) > sw - sd && (new.x + w) < sw + sd)
	  new.x = sw - w;
	if(new.y > -sd && new.y < sd)
	  new.y = 0;
	if((new.y + h) > sh - sd && (new.y + h) < sh + sd) 
	  new.y = sh - h;
      }

      if( [config boolValueForKey:player_visible] ) {
	dock(&new.x, &new.y, w, h, playerFrame.origin.x, 
	     playerFrame.origin.y, playerFrame.size.width, 
	     playerFrame.size.height);
      }
	  
      if([config boolValueForKey:playlist_visible]) {
	dock(&new.x, &new.y, w, h, playlistFrame.origin.x, 
	     playlistFrame.origin.y, playlistFrame.size.width,
	     playlistFrame.size.height);
      }

      [[self window] setFrameOrigin:new];

      if ([theEvent type] == NSLeftMouseUp)
	done = YES;

      [pool release];

    }
  }
  //[[self window] saveFrameUsingName:[(MainWindow *)[self window] name]];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
  return YES;
}

- (BOOL)isVisible
{
  return [config boolValueForKey:equalizer_visible];
}

@end

void dock(float *rx,float *ry,int w,int h,int ox,int oy,int ow,int oh)
{
  int snapd;
  int x = *rx, y = *ry;
  
  if(![config boolValueForKey:snap_windows])
    return;

  snapd = [config intValueForKey:snap_distance];

  if(x+w>ox-snapd && x+w<ox+snapd && y>oy-h && y<oy+oh)
    {
      x=ox-w;
      if(y>oy-snapd && y<oy+snapd) y=oy;
      if(y+h>oy+oh-snapd && y+h<oy+oh+snapd) y=oy+oh-h;
    }
	
  if(x>ox+ow-snapd && x<ox+ow+snapd && y>oy-h && y<oy+oh) 
    {
      x=ox+ow;
      if(y>oy-snapd && y<oy+snapd) y=oy;
      if(y+h>oy+oh-snapd && y+h<oy+oh+snapd) y=oy+oh-h;
    }
  if(y+h>oy-snapd && y+h<oy+snapd && x>ox-w && x<ox+ow) 
    {
      y=oy-h;
      if(x>ox-snapd && x<ox+snapd) x=ox;
      if(x+w>ox+ow-snapd && x+w<ox+ow+snapd) x=ox+ow-w;
    }
  if(y>oy+oh-snapd && y<oy+oh+snapd && x>ox-w && x<ox+ow) 
    {
      y=oy+oh;
      if(x>ox-snapd && x<ox+snapd) x=ox;
      if(x+w>ox+ow-snapd && x+w<ox+ow+snapd) x=ox+ow-w;
    }
  *rx = x;
  *ry = y;
}

BOOL is_docked(int x,int y,int w, int h,int ox,int oy,int ow,int oh)
{
  if((x==ox||x==ox+ow||x+w==ox||x+w==ox+ow)&&oy>=y-oh&&oy<=y+h) 
    return YES;
  if((y==oy||y==oy+oh||y+h==oy||y+h==oy+oh)&&ox>=x-ow&&ox<=x+w) 
    return YES;
  return NO;
}

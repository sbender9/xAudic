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
#import <Foundation/NSArray.h>
#import "Skin.h"
#import <MXA/PlaylistEntry.h>
#import <MXA/Plugins.h>
#import <MXA/Control.h>
#import "Configure.h"
#import "PlaylistView.h"
#import "EqView.h"
#import "Button.h"
#import "TextBox.h"
#import "MenuRow.h"
#import "Slider.h"
#import "MonoStereo.h"
#import "Number.h"
#import "EqGraph.h"
#import "EqSlider.h"
#import "NormPlaylistList.h"
#import "BrowserPlaylistList.h"
#import "PlaylistSlider.h"
#import "PlaylistPopup.h"
#import "MainView.h"
#import "WinAmp.h"

@implementation PlaylistView

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

- (void)showVisualization
{
  /*FIXME

  if ( [config boolValueForKey:player_visible] == NO
       && [config boolValueForKey:playlist_visible]
       && [Control getVisType] != VIS_OFF 
       && [Control songIsPlaying] )
    {
      NSRect frame = [self frame];
      if ( ((frame.size.width-275)/25) >= 3 ) {
	  [self addSubviewIfNeeded:vis];
	[vis setFrame:NSMakeRect(frame.size.width-223,
				 frame.size.height-26,72, 16)];
      } else

	[self removeIfNeeded:vis];
    }
  */
}

- (void)hideVisualization
{
  //FIXME: [self removeIfNeeded:vis];
}

- (void)repositionViews
{
  NSRect frame = [self frame];
  int y = frame.size.height-31;
  NSPoint o;

  [shade setFrame:NSMakeRect(frame.size.width-21,3,9,9)];
  [close setFrame:NSMakeRect(frame.size.width-11,3,9,9)];
  [slider setFrame:NSMakeRect(frame.size.width-15, 20,
			      8, frame.size.height-58)];
  [playlistList setFrame:NSMakeRect(12,20, frame.size.width-31,
				    frame.size.height-58)];
  [time_min setFrame:NSMakeRect(frame.size.width-82,
				frame.size.height-15, 15, 6)];
  [time_sec setFrame:NSMakeRect(frame.size.width-64,
				frame.size.height-15, 10, 6)];
  [info setFrame:NSMakeRect(frame.size.width-143,
			    frame.size.height-28, 85, 6)];
  [srew setFrame:NSMakeRect(frame.size.width-144,
			    frame.size.height-16,8,7)];
  [splay setFrame:NSMakeRect(frame.size.width-138,
			     frame.size.height-16,10,7)];
  [spause setFrame:NSMakeRect(frame.size.width-128,
			      frame.size.height-16,10,7)];
  [sstop setFrame:NSMakeRect(frame.size.width-118,
			     frame.size.height-16,9,7)];
  [sfwd setFrame:NSMakeRect(frame.size.width-109,
			    frame.size.height-16,8,7)];
  [seject setFrame:NSMakeRect(frame.size.width-100, 
			      frame.size.height-16,9,7)];
  [sscroll_up setFrame:NSMakeRect(frame.size.width-14,
				  frame.size.height-35, 8,5)];
  [sscroll_down setFrame:NSMakeRect(frame.size.width-14,
				    frame.size.height-30, 8,5)];

#define reset_popup(pop)\
  o.y = y; \
  o.x = [pop frame].origin.x; \
  [pop setFrameOrigin:o];

  reset_popup(add_popup);
  reset_popup(sub_popup);
  reset_popup(misc_popup);
  reset_popup(sel_popup);
  
  o = NSMakePoint(frame.size.width-46,y);
  [plist_popup setFrameOrigin:o];
}

- (void)updateShaded:(BOOL)shaded updatePos:(BOOL)updatePos
{
  NSSize size;
  NSRect frame;
  NSPoint new_pos;
  WAView *eqView, *mView;
  MainWindow *eqWindow, *mWindow;
  BOOL eqDocked, mDocked;

  mWindow = [[WinAmp instance] mainWindow];
  mView = [[WinAmp instance] mainView];
  eqWindow = [[WinAmp instance] eqWindow];
  eqView = [[WinAmp instance] eqView];
  mDocked = [mView isDockedToBotton:self];
  eqDocked = [eqView isDockedToBotton:self];

  [config setBoolValue:shaded forKey:playlist_shaded];

  frame = [[self window] frame];  
  size = frame.size;
  new_pos = frame.origin;

  if ( !shaded ) {
    [self removeIfNeeded:sinfo];
    size.height = [config sizeValueForKey:playlist_size].height;
    if ( updatePos )
      new_pos.y = new_pos.y + frame.size.height - size.height;
    [shade setNormal:NSMakePoint(157, 3)];
    [shade setPushed:NSMakePoint(62, 42)];
    [close setNormal:NSMakePoint(167, 3)];
  } else {
    size.height = 14;
    if ( updatePos )
      new_pos.y = new_pos.y - size.height + frame.size.height;
    [shade setNormal:NSMakePoint(128, 45)];
    [shade setPushed:NSMakePoint(150, 42)];
    [close setNormal:NSMakePoint(138, 45)];


    [self removeIfNeeded:info];
    [self removeIfNeeded:playlistList];
    [self removeIfNeeded:time_min];
    [self removeIfNeeded:time_sec];
    [self removeIfNeeded:srew];
    [self removeIfNeeded:splay];
    [self removeIfNeeded:sstop];
    [self removeIfNeeded:sfwd];
    [self removeIfNeeded:seject];
    [self removeIfNeeded:sscroll_up];
    [self removeIfNeeded:sscroll_down];
    [self removeIfNeeded:spause];
    [self removeIfNeeded:slider];
    [self removeIfNeeded:add_popup];
    [self removeIfNeeded:sub_popup];
    [self removeIfNeeded:misc_popup];
    [self removeIfNeeded:plist_popup];
    [self removeIfNeeded:sel_popup];
  }
  frame = NSMakeRect(new_pos.x, new_pos.y, size.width,size.height);
  [[self window] setFrame:frame display:NO];

  if ( !shaded ) {
    [self addSubviewIfNeeded:info];
    [self addSubviewIfNeeded:playlistList];
    [self addSubviewIfNeeded:time_min];
    [self addSubviewIfNeeded:time_sec];
    [self addSubviewIfNeeded:srew];
    [self addSubviewIfNeeded:splay];
    [self addSubviewIfNeeded:sstop];
    [self addSubviewIfNeeded:sfwd];
    [self addSubviewIfNeeded:seject];
    [self addSubviewIfNeeded:sscroll_up];
    [self addSubviewIfNeeded:sscroll_down];
    [self addSubviewIfNeeded:spause];
    [self addSubviewIfNeeded:slider];
    [self addSubviewIfNeeded:add_popup];
    [self addSubviewIfNeeded:sub_popup];
    [self addSubviewIfNeeded:misc_popup];
    [self addSubviewIfNeeded:plist_popup];
    [self addSubviewIfNeeded:sel_popup];
    [self showVisualization];
    [self repositionViews];
  } else {
    [sinfo setFrame:NSMakeRect(4, 4, frame.size.width-35, 6)];
    [self addSubviewIfNeeded:sinfo];
  }

  if ( updatePos )
    {
      if ( eqDocked )
	{
	  NSRect his = [eqWindow frame];
	  
	  mDocked = [mView isDockedToBotton:eqView];
	  his.origin.y = frame.origin.y - his.size.height;
	  [eqWindow setFrame:his display:YES];
	  //[eqWindow saveFrameUsingName:[eqWindow name]];
	  
	  if ( mDocked )
	    {
	      NSRect pl = [mWindow frame];
	      pl.origin.y = his.origin.y - pl.size.height;
	      [mWindow setFrame:pl display:YES];
	      //[mWindow saveFrameUsingName:[mWindow name]];
	}
	}
      else if ( mDocked )
	{
	  NSRect his = [mWindow frame];

	  eqDocked = [eqView isDockedToBotton:mView];
	  his.origin.y = frame.origin.y - his.size.height;
	  [mWindow setFrame:his display:YES];
	  //[mWindow saveFrameUsingName:[mWindow name]];
	  
	  if ( eqDocked )
	    {
	      NSRect pl = [eqWindow frame];
	      pl.origin.y = his.origin.y - pl.size.height;
	      [eqWindow setFrame:pl display:YES];
	      //[eqWindow saveFrameUsingName:[eqWindow name]];
	    }
	}
    }
}


- (void)shade_pushed:button
{
  [self updateShaded:![config boolValueForKey:playlist_shaded]
	updatePos:YES];
}

- (BOOL)isFlipped
{
  return YES;
}

- (void)close_button:sender
{
  [[WinAmp instance] hideShowPlaylist:sender];
}

- (void)button_pressed:button
{
}

- (void)scrollDown:button
{
  [playlistList scrollDown];
}

- (void)scrollUp:button
{
  [playlistList scrollUp];
}

- (void)scrollList:aslider
{
  [playlistList sliderAction];
}

- (void)showMenu:(NSMenu *)menu :(NSPopUpButton *)button
{
  [NSMenu popUpContextMenu:menu 
	         withEvent:[NSApp currentEvent]
	           forView:self];
}

- (void)opts_menu:popup
{
  //[self showMenu:[[WinAmp instance] miscOptsMenu] :misc_popup];
}

- (void)file_menu:popup
{
  NSArray *items = [Playlist selectedItems];
  if ( [items count] )
    [Input fileInfoBox:[[items objectAtIndex:0] filename]];
}

- (void)sort_menu:popup
{
  [self showMenu:[[WinAmp instance] sortMenu] :misc_popup];
}

- (void)load_list:popup
{
  [[WinAmp instance] playlistOpen:popup];
}

- (void)save_list:popup
{
  [[WinAmp instance] playlistSave:popup];
}

- (void)add_file:popup
{
  [[WinAmp instance] playlistAddFile:popup];
}

- (void)add_dir:popup
{
  [[WinAmp instance] playlistAddDir:popup];
}

- (void)add_url:popup
{
  [[WinAmp instance] playlistAddURL:popup];
}

- (void)new_list:popup
{
  [[WinAmp instance] playlistNew:popup];
}

- (void)sel_all:popup
{
  [[WinAmp instance] playlistSelectAll:popup];
}

- (void)sel_invert:popup
{
  [[WinAmp instance] playlistInvertSelection:popup];
}

- (void)sel_zero:popup
{
  [[WinAmp instance] playlistZeroSelection:popup];
}

- (void)sub_file:popup
{
  [[WinAmp instance] playlistRemoveSelected:popup];
}

- (void)sub_crop:popup
{
  [[WinAmp instance] playlistCropSelection:popup];
}

- (void)sub_all:popup
{
  [[WinAmp instance] playlistRemoveAll:popup];
}

- (void)sub_misc:popup
{
}

#if 0
- (NSImage *)createPopupImage:(int)x :(int)y
{
  NSImage *new_image;
  
  new_image = [[NSImage allocWithZone:[self zone]] 
			 initWithSize:NSMakeSize(22, 18)];

  [new_image lockFocus];
  PSgsave();
  [[currentSkin pledit] 
    compositeToPoint:NSMakePoint(0,0)
	    fromRect:flipRect(NSMakeRect(x,y, 22, 18),
			      [currentSkin pledit])
	   operation:NSCompositeCopy];
  PSgrestore();
  [new_image unlockFocus];
  return new_image;
}
#endif

- (NSPopUpButton *)createPopup:(NSPoint)pos
			      :(int)num_items
			      :(int *)nx
			      :(int *)ny
			      :(int *)sx
			      :(int *)sy
			      :(SEL *)actions
			      :(int)barx
			      :(int)bary
			      :(SEL)cb
{
  pos.x -= 3;
  return [[PlaylistPopup alloc] initWithPos:pos 
					   :num_items 
					   :nx 
					   :ny 
					   :sx
					   :sy
					   :actions
					   :barx
					   :bary
					   :self];
}

- (void)createPopupButtons
{
  int add_nx[]={0,0,0},add_ny[]={111,130,149},add_sx[]={23,23,23},add_sy[]={111,130,149},add_barx=48,add_bary=111;
  int sub_nx[]={54,54,54,54},sub_ny[]={168,111,130,149},sub_sx[]={77,77,77,77},sub_sy[]={168,111,130,149},sub_barx=100,sub_bary=111;
  int sel_nx[]={104,104,104},sel_ny[]={111,130,149},sel_sx[]={127,127,127},sel_sy[]={111,130,149},sel_barx=150,sel_bary=111;
  int misc_nx[]={154,154,154},misc_ny[]={111,130,149},misc_sx[]={177,177,177},misc_sy[]={111,130,149},misc_barx=200,misc_bary=111;
  int plist_nx[]={204,204,204},plist_ny[]={111,130,149},plist_sx[]={227,227,227},plist_sy[]={111,130,149},plist_barx=250,plist_bary=111;
  SEL misc_actions[] = 
  { @selector(opts_menu:), @selector(file_menu:), @selector(sort_menu:) };
  SEL list_actions[] =
  { @selector(load_list:), @selector(save_list:), @selector(new_list:) };
  SEL sel_actions[] =
  { @selector(sel_all:),  @selector(sel_zero:), @selector(sel_invert:) };
  SEL add_actions[] = 
  { @selector(add_file:), @selector(add_dir:), @selector(add_url:) };
  SEL sub_actions[] =
  { @selector(sub_file:), @selector(sub_crop:), @selector(sub_all:),
    @selector(sub_crop:) };
  
  int y;
  NSRect frame = [self frame];

  y = frame.size.height-31;

  add_popup = [self createPopup:NSMakePoint(14, y)
			       :3 :add_nx :add_ny :add_sx :add_sy
				 :add_actions
			         :add_barx :add_bary
			         :@selector(button_pressed:)];
  [add_popup setAutoresizingMask:NSViewMinYMargin];
  [self addSubview:add_popup];
 
 
  sub_popup = [self createPopup:NSMakePoint(43, y)
				 :4 :sub_nx :sub_ny :sub_sx :sub_sy
				 :sub_actions
			         :sub_barx :sub_bary
			         :@selector(button_pressed:)];
  [sub_popup setAutoresizingMask:NSViewMinYMargin];
  [self addSubview:sub_popup];

  sel_popup = [self createPopup:NSMakePoint(72, y)
				 :3 :sel_nx :sel_ny :sel_sx :sel_sy
				 :sel_actions
			         :sel_barx :sel_bary
			         :@selector(button_pressed:)];
  [sel_popup setAutoresizingMask:NSViewMinYMargin];
  [self addSubview:sel_popup];

  misc_popup = [self createPopup:NSMakePoint(101, y)
				 :3 :misc_nx :misc_ny :misc_sx :misc_sy
				 :misc_actions
			         :misc_barx :misc_bary
			         :@selector(button_pressed:)];
  [misc_popup setAutoresizingMask:NSViewMinYMargin];
  [self addSubview:misc_popup];

  plist_popup = [self createPopup:NSMakePoint(frame.size.width-46,
						y)
				 :3 :plist_nx :plist_ny :plist_sx :plist_sy
				 :list_actions
			         :plist_barx :plist_bary
			         :@selector(button_pressed:)];
  [plist_popup setAutoresizingMask:NSViewMinXMargin|NSViewMinYMargin];
  [self addSubview:plist_popup];
}

- (void)skinChanged:(NSNotification *)notification
{
  [add_popup removeFromSuperview];
  [sub_popup removeFromSuperview];
  [sel_popup removeFromSuperview];
  [misc_popup removeFromSuperview];
  [plist_popup removeFromSuperview];
  [self createPopupButtons];
}


- initWithFrame:(NSRect)frame
{
  id ui = [WinAmp instance];
  
  [super initWithFrame:frame];

  [self setAutoresizesSubviews:YES];

  sinfo = [[TextBox alloc] 
	    initWithFrame:NSMakeRect(4, 4, frame.size.width-35, 0)
			 :self
			 :@selector(text)];
  [sinfo setAutoresizingMask:NSViewWidthSizable];

  shade = [[Button alloc] init:NSMakeRect(frame.size.width-21,3,9,9)
			      :NSMakePoint(157,3)
			      :NSMakePoint(62,42)
			      :self
			      :@selector(shade_pushed:)
			      :@selector(pledit)];
  [shade setAutoresizingMask:NSViewMinXMargin];
  [shade setAllowDraw:NO];
  [self addSubview:shade];


  close = [[Button alloc] init:NSMakeRect(frame.size.width-11,3,9,9)
			      :NSMakePoint(167,3)
			      :NSMakePoint(52,42)
			      :self
			      :@selector(close_button:)
			      :@selector(pledit)];
  [close setAutoresizingMask:NSViewMinXMargin];
  [close setAllowDraw:NO];
  [self addSubview:close];



  slider = [[PlaylistSlider alloc] initWithParentFrame:frame 
						target:self 
					    cb:@selector(scrollList:)];
  [slider setMaxValue:100];
  [slider setIntValue:100];
  [slider setAutoresizingMask:NSViewHeightSizable|NSViewMinXMargin];
  [self addSubview:slider];

  {
    Class lclass;

    lclass = [NormPlaylistList class];
    
    playlistList = [[lclass alloc] 
		   initWithFrame:NSMakeRect(12,20,
					    frame.size.width-31,
					    frame.size.height-58)
			  target:self
			  action:@selector(playlistListClicked:)
			  slider:slider];
    [playlistList setAutoresizingMask:
      NSViewHeightSizable|NSViewWidthSizable];
    [self addSubview:playlistList];
  }
  

  time_min = [[TextBox alloc] 
	       initWithFrame:NSMakeRect(frame.size.width-82,
					frame.size.height-15, 15, 1)
			    :self
			    :@selector(text)];
  [time_min setAutoresizingMask:NSViewMinXMargin|NSViewMinYMargin];
  [self addSubview:time_min];

  time_sec = [[TextBox alloc] 
	       initWithFrame:NSMakeRect(frame.size.width-64,
					frame.size.height-15, 10, 1)
			    :self
			    :@selector(text)];
  [time_sec setAutoresizingMask:NSViewMinXMargin|NSViewMinYMargin];
  [self addSubview:time_sec];

  info = [[TextBox alloc] 
	       initWithFrame:NSMakeRect(frame.size.width-143,
					frame.size.height-28, 85, 1)
			    :self
			    :@selector(text)];
  [info setAutoresizingMask:NSViewMinXMargin|NSViewMinYMargin];
  [self addSubview:info];


  /*
  vis = [[Visualization alloc] initWithFrame:NSMakeRect(frame.size.width-223,frame.size.height-26,72, 16)];
  [vis setAutoresizingMask:NSViewMinXMargin|NSViewMinYMargin];
  */

  [self showVisualization];

  srew = [[Button alloc] init:NSMakeRect(frame.size.width-144,
					 frame.size.height-16,8,7)
			      :ui
			      :@selector(previous:)];
  [srew setAutoresizingMask:NSViewMinXMargin|NSViewMinYMargin];
  [self addSubview:srew];

  splay = [[Button alloc] init:NSMakeRect(frame.size.width-138,
					  frame.size.height-16,10,7)
			      :ui
			      :@selector(play:)];
  [splay setAutoresizingMask:NSViewMinXMargin|NSViewMinYMargin];
  [self addSubview:splay];
  
  spause = [[Button alloc] init:NSMakeRect(frame.size.width-128,
					   frame.size.height-16,10,7)
			       :ui
			       :@selector(pause:)];
  [spause setAutoresizingMask:NSViewMinXMargin|NSViewMinYMargin];
  [self addSubview:spause];

  sstop = [[Button alloc] init:NSMakeRect(frame.size.width-118,
					  frame.size.height-16,9,7)
			      :ui
			      :@selector(stop:)];
  [sstop setAutoresizingMask:NSViewMinXMargin|NSViewMinYMargin];
  [self addSubview:sstop];

  sfwd = [[Button alloc] init:NSMakeRect(frame.size.width-109,
					 frame.size.height-16,8,7)
			     :ui
			     :@selector(next:)];
  [sfwd setAutoresizingMask:NSViewMinXMargin|NSViewMinYMargin];
  [self addSubview:sfwd];

  seject = [[Button alloc] init:NSMakeRect(frame.size.width-100,
					   frame.size.height-16,9,7)
			       :ui
			       :@selector(eject:)];
  [seject setAutoresizingMask:NSViewMinXMargin|NSViewMinYMargin];
  [self addSubview:seject];

  sscroll_up = [[Button alloc] init:NSMakeRect(frame.size.width-14,
					       frame.size.height-35,
					       8,5)
				   :self
				   :@selector(scrollUp:)];
  [sscroll_up setAutoresizingMask:NSViewMinXMargin|NSViewMinYMargin];
  [self addSubview:sscroll_up];

  sscroll_down= [[Button alloc] init:NSMakeRect(frame.size.width-14,
						frame.size.height-30,
						8,5)
				    :self
				    :@selector(scrollDown:)];
  [sscroll_down setAutoresizingMask:NSViewMinXMargin|NSViewMinYMargin];
  [self addSubview:sscroll_down];
  [self createPopupButtons];

  [self update_sinfo];
  [self update_info];

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(playlistChanged:)
	   name:PlaylistSelectionChangedNotification
	 object:nil];
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(playlistChanged:)
	   name:PlaylistChangedNotification
	 object:nil];
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(playlistChanged:)
	   name:NewPlaylistNotification
	 object:nil];
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(skinChanged:)
	   name:SkinChangedNotification
	 object:nil];
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
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(visTypeChanged:)
	   name:DefaultVisualizationChangedNotification
	 object:nil];
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(playStatusChanged:)
	   name:PlayStatusChangedNotification
	 object:nil];

  [self showVisualization];

  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [info release];
  [sinfo release];
  [shade release];
  [close release];
  [playlistList release];
  [time_min release];
  [time_sec release];
  [srew release];
  [splay release];
  [sstop release];
  [sfwd release];
  [seject release];
  [sscroll_up release];
  [sscroll_down release];
  [spause release];
  [slider release];
  [add_popup release];
  [sub_popup release];
  [misc_popup release];
  [plist_popup release];
  [sel_popup release];
  [vis release];

  [super dealloc];
}

- (void)drawRect:(NSRect)rect 
{
  int w,h,y,i,c;
  NSImage *src;
  BOOL drawFocus = [[self window] isKeyWindow] || ![config boolValueForKey:dim_titlebar];
  NSRect frame = [self frame];
  
  w = frame.size.width;
  h = frame.size.height;
  src = [currentSkin pledit];
  
  if([config boolValueForKey:playlist_shaded]) {
    [src compositeToPoint:NSMakePoint(0, 14)
		 fromRect:flipRect(NSMakeRect(72, 42, 25, 14), src)
		operation:NSCompositeCopy];

    c = (w-75) / 25;
    for(i = 0; i < c; i++)
      [src compositeToPoint:NSMakePoint((i * 25) + 25, 14)
		   fromRect:flipRect(NSMakeRect(72, 57, 25, 14), src)
		  operation:NSCompositeCopy];

    [src compositeToPoint:NSMakePoint(w-50, 14)
		 fromRect:flipRect(NSMakeRect(99, drawFocus?57:42, 
					      50, 14), src)
		operation:NSCompositeCopy];
  } else {
    y = drawFocus ? 0 : 21;
    [src compositeToPoint:NSMakePoint(0,20)
		 fromRect:flipRect(NSMakeRect(0, y, 25, 20),src)
		operation:NSCompositeCopy];


    /** titlebar lines **/
    c=(w-150)/25;
    for(i=0;i<c/2;i++) {
      [src compositeToPoint:NSMakePoint((i*25)+25, 20)
		   fromRect:flipRect(NSMakeRect(127, y, 25, 20), src)
		  operation:NSCompositeCopy];
      [src compositeToPoint:NSMakePoint((i*25)+(w/2)+50, 20)
		   fromRect:flipRect(NSMakeRect(127, y, 25, 20), src)
		  operation:NSCompositeCopy];
    }
    if(c&1) {
      [src compositeToPoint:NSMakePoint(((c/2)*25)+25, 20)
		   fromRect:flipRect(NSMakeRect(127, y, 12, 20), src)
		  operation:NSCompositeCopy];

      [src compositeToPoint:NSMakePoint((w/2)+((c/2)*25)+50, 20)
		   fromRect:flipRect(NSMakeRect(127, y, 13, 20), src)
		  operation:NSCompositeCopy];
    }
    /****/

    /** title **/
    [src compositeToPoint:NSMakePoint((w/2)-50, 20)
		 fromRect:flipRect(NSMakeRect(26, y, 100, 20), src)
		operation:NSCompositeCopy];
    /** title button area **/
    [src compositeToPoint:NSMakePoint(w-25, 20)
		 fromRect:flipRect(NSMakeRect(153, y, 25, 20), src)
		operation:NSCompositeCopy];

    /** sides **/
    for(i=0;i<(h-58)/29;i++) {
      [src compositeToPoint:NSMakePoint(0, (i*29)+20+29)
		   fromRect:flipRect(NSMakeRect(0, 42, 12, 29), src)
		  operation:NSCompositeCopy];
      [src compositeToPoint:NSMakePoint(w-19, (i*29)+20+29)
		   fromRect:flipRect(NSMakeRect(32, 42, 19, 29), src)
		  operation:NSCompositeCopy];
    }
    /****/

    /** bottom left **/
    [src compositeToPoint:NSMakePoint(0, h)
		 fromRect:flipRect(NSMakeRect(0, 72, 125, 38), src)
		operation:NSCompositeCopy];

    /** vis **/
    c=(w-275)/25;
    if(c>=3) {
      c-=3;
      [src compositeToPoint:NSMakePoint(w-225, h)
		   fromRect:flipRect(NSMakeRect(205, 0, 75, 38), src)
		  operation:NSCompositeCopy];
    }


    /** bottom left of vis **/
    for(i=0;i<c;i++)
      [src compositeToPoint:NSMakePoint((i*25)+125, h)
		   fromRect:flipRect(NSMakeRect(179, 0, 25, 38), src)
		  operation:NSCompositeCopy];

    /** bottom right **/
    [src compositeToPoint:NSMakePoint(w-150, h)
		 fromRect:flipRect(NSMakeRect(126, 72, 150, 38), src)
		operation:NSCompositeCopy];
  }
}

- (void)mouseDown:(NSEvent *)theEvent 
{
  NSPoint startPoint, curPoint, new;
  NSRect frame = [[self window] frame], playerFrame, eqFrame;
  int xdif, ydif;
  int sd = [config intValueForKey:snap_distance];
  int w = frame.size.width;
  int h = frame.size.height;
  int sw = [[NSScreen mainScreen] frame].size.width;
  int sh = [[NSScreen mainScreen] frame].size.height;
  BOOL done = NO;

  if ([theEvent type] == NSLeftMouseDown) 
    [[WinAmp instance] windowCameToFront];

  new.x = new.y = 0;

  startPoint = [theEvent locationInWindow];
  
  if(([config boolValueForKey:playlist_shaded] == NO && 
      startPoint.x > frame.size.width-20 
      && startPoint.y < 20)
     || ([config boolValueForKey:playlist_shaded] && startPoint.x >= frame.size.width-31 
	 && startPoint.x < frame.size.width - 22)) {
    // Size Window
    int w, bx, nw, h, by, nh, ny;
    float ysave;
    NSRect new_frame = frame;
    NSPoint sPoint;
    NSSize save_size;

    while (!done) {
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      theEvent = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
      curPoint = [theEvent locationInWindow];

      ysave = 0;
      if (curPoint.y < 0 ) {
	ysave = curPoint.y;
	curPoint.y = 0;
      }

      sPoint = [[self window] convertBaseToScreen:curPoint];
      sPoint.y += ysave;

      w = curPoint.x + (frame.size.width-startPoint.x);
      bx = (w-275) / 25;
      nw = (bx * 25) + 275;
      if( nw < 275 ) 
	nw = 275;
		
      if(![config boolValueForKey:playlist_shaded]) {
	int y = sPoint.y - startPoint.y;
	h = new_frame.size.height - (y-new_frame.origin.y);
	by = (h-58) / 29;
	nh = (by * 29) + 58;
	if ( nh < 116 )
	  nh = 116;
	ny = new_frame.origin.y + (new_frame.size.height-nh);
      } else {
	nh = frame.size.height;
	ny = frame.origin.y;
      }

      if ( nh != frame.size.height || nw != frame.size.width ) {
	new_frame.origin.x = frame.origin.x;
	new_frame.size.width = nw;

	new_frame.size.height = nh;
	new_frame.origin.y = ny;
	save_size = new_frame.size;
	if ( [config boolValueForKey:playlist_shaded] )
	  save_size.height = [config sizeValueForKey:playlist_size].height;
	[config setSizeValue:save_size forKey:playlist_size];
	[[self window] setFrame:new_frame display:YES];
	[self showVisualization];
      }

      if ([theEvent type] == NSLeftMouseUp) {
	if ( [config boolValueForKey:playlist_shaded] )
	  [self update_sinfo];
	done = YES;
      }

      [pool release];
    }
    
  } else if (startPoint.y > frame.size.height-14 
	     || [config boolValueForKey:easy_move] ) {
    // Move window
    startPoint = [[self window] convertBaseToScreen:startPoint];
    xdif = startPoint.x - frame.origin.x;
    ydif = startPoint.y - frame.origin.y;

    if( [config boolValueForKey:player_visible] )
      playerFrame = [[[WinAmp instance] mainWindow] frame];
    if ( [config boolValueForKey:equalizer_visible] )
      eqFrame = [[[WinAmp instance] eqWindow] frame];

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
	  
      if([config boolValueForKey:equalizer_visible]) {
	dock(&new.x, &new.y, w, h, eqFrame.origin.x, 
	     eqFrame.origin.y, eqFrame.size.width,
	     eqFrame.size.height);
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

- (void)playlistChanged:(NSNotification *)notification
{
  if ( [config playlist_position] > [Playlist count] )
    [config setplaylist_position:0];

  
  [self update_sinfo];
  [self update_info];
}

- (void)setTime:(int)time length:(int)length
{
  NSString *text;
  char sign;
		
  if([config timer_mode] == TIMER_REMAINING && length != -1) 
    {
      time = length-time;
      sign = '-';
    } 
  else
    sign = ' ';
  
  time /= 1000;
	
  if(time < 0)
    time = 0;
  if(time > 99 * 60)
    time /= 60;
	
  text = [NSString stringWithFormat:@"%c%-2.2d", sign, time/60];
  [time_min setStringValue:text];
  text = [NSString stringWithFormat:@"%-2.2d", time%60];
  [time_sec setStringValue:text];
}

- (void)update_sinfo
{
  NSString *time = nil, *pos, *title, *infot;
  int max_len;
  PlaylistEntry *entry;
  
  if( [Control getPlaylistLength] == 0 ) 
    {
      [sinfo setStringValue:@""];
      return;
    }
  
  if ( [config playlist_position] >= [Playlist count] )
    [config setplaylist_position:0];
  
  entry = [Control getPlaylistEntryAt:[config playlist_position]];
	
  title = [entry title];
  if ( title == nil ) 
    {
      title = [[entry filename] lastPathComponent];
    }
	
  max_len = ([self frame].size.width - 35) / 5;
	
  pos = [NSString stringWithFormat:@"%d. ", [config playlist_position]+1];
	
  if ( [entry length] != -1 ) {
    time = [NSString stringWithFormat:@"%d:%-2.2d",
	     [entry length]/60000, ([entry length]/1000)%60];
    max_len -= [time length];
    infot = [NSString stringWithFormat:@"%s%-*.*s%s",
	     [pos cString], max_len-[pos length], max_len-[pos length], 
	     [title cString], [time cString]];
    
  } else
    infot = [NSString stringWithFormat:@"%s%-*.*s",
	     [pos cString], max_len-[pos length], max_len-[pos length],
	     [title cString]];
  
  [sinfo setStringValue:infot];
}

- (void)update_info
{
  PlaylistEntry *entry;
  NSString *sel_text, *tot_text;
  int i, selection=0, total=0;
  BOOL selection_more = FALSE, total_more = FALSE;

  for ( i = 0; i < [Control getPlaylistLength]; i++ ) {
    entry = [Control getPlaylistEntryAt:i];
    if ( [entry length] != -1 )
      total += [entry length];
    else
      total_more = TRUE;
    if([entry selected]) {
      if ( [entry length] != -1)
	selection += [entry length];
      else
	selection_more = TRUE;
    }
  }

  selection/=1000;
	
  if ( selection > 0 || (selection == 0 && !selection_more) ) {
    if(selection>3600)
      sel_text = [NSString stringWithFormat:@"%d:%-2.2d:%-2.2d%s",
		   selection/3600,
		   (selection/60)%60,
		      selection%60, (selection_more?"+":"")];
    else
      sel_text = [NSString stringWithFormat:@"%d:%-2.2d%s",
		   selection/60, selection%60,
			     (selection_more?"+":"")];
  } else
    sel_text = @"?";

  total /= 1000;
  if ( total > 0 || (total==0 && !total_more )) {
    if(total>3600)
      tot_text = [NSString stringWithFormat:@"%d:%-2.2d:%-2.2d%s",
       total/3600,(total/60)%60,total%60,total_more?"+":""];
    else
      tot_text = [NSString stringWithFormat:@"%d:%-2.2d%s",
		total/60,total%60,total_more?"+":""];
  }
  else
    tot_text = @"?";
  [info setStringValue:[NSString stringWithFormat:@"%@/%@", sel_text, 
			 tot_text]];
}


- (void)playlistListClicked:sender
{
  if ( [sender selected] != -1 ) 
    {
      [config setplaylist_position:[sender selected]];
      [Control play];
    }
}

- (void)songStarted:(NSNotification *)notification
{
  [playlistList centerCurrentIfNeeded];
  [playlistList setNeedsDisplay:YES];
  [self showVisualization];
}

- (void)playStatusChanged:(NSNotification *)notification
{
  NSNumber *status = [[notification userInfo] objectForKey:@"status"];
  if ( [status intValue] == STATUS_PLAY )
    [self showVisualization];
  else 
    [self hideVisualization];
}

- (void)visTypeChanged:(NSNotification *)notification
{
  /* FIXME
  VisType t = [[[notification userInfo] objectForKey:@"type"] intValue];
  if ( t != VIS_OFF )
    [self showVisualization];
  else
    [self hideVisualization];
  */
}


- (void)songEnded:(NSNotification *)notification
{
  [self hideVisualization];
}

- (BOOL)isVisible
{
  return [config boolValueForKey:playlist_visible];
}

/*
FIXME
- (void)vis_timeout:(unsigned char *)data
{
  if ( (([self frame].size.width-275)/25) >= 3 )
    [vis timeout:data];
}
*/

@end

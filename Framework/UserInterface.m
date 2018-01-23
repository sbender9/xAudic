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

#import "UserInterface.h"

#import <AppKit/AppKit.h>
#import "Control.h"
#import "PlaylistEntry.h"
#import "MXAConfig.h"

static NSMutableArray *ui_plugins = nil;
static UserInterface *selectedUiPlugin = nil;


@implementation UserInterface

- initWithDescription:(NSString *)desc
{
  addedOptionMenuItems = [[NSMutableArray array] retain];
  addedWindowMenuItems = [[NSMutableArray array] retain];
  return [super initWithDescription:desc];
}

+ (void)registerPlugin:(Plugin *)op
{
  if ( ui_plugins == nil )
    ui_plugins = [[NSMutableArray array] retain];
  [ui_plugins addObject:op];
}

+ (NSArray *)plugins
{
  return ui_plugins;
}

+ (void)updateSelectedUIPlugin
{
  int i;
  for ( i = 0; i < [ui_plugins count]; i++ ) 
    {
      if ( [[ui_plugins objectAtIndex:i] enabled] )
	selectedUiPlugin = [ui_plugins objectAtIndex:i];
    }
  if ( selectedUiPlugin == nil && [ui_plugins count] > 0 ) 
    {
      UserInterface *pl;
      for ( i = 0; i < [ui_plugins count]; i++ ) 
	{
	  pl = [ui_plugins objectAtIndex:i];
	  if ([pl enabledByDefault] ) 
	    {
	      selectedUiPlugin = pl;
	      [pl setEnabled:YES];
	      break;
	    }
	}
    }
}

+ (UserInterface *)ui
{
  if ( selectedUiPlugin == nil )
    [self updateSelectedUIPlugin];
  return selectedUiPlugin;
}

- (void)run
{
}

- (void)stop
{
  int i;
  NSMenu *menu;

  menu = [[[NSApp mainMenu] itemWithTitle:@"Window"] submenu];

  for ( i = 0; i < [addedWindowMenuItems count]; i++ )
    {
      [menu removeItem:[addedWindowMenuItems objectAtIndex:i]];
    }
  [addedWindowMenuItems removeAllObjects];

  menu = [[[NSApp mainMenu] itemWithTitle:@"Options"] submenu];
  for ( i = 0; i < [addedOptionMenuItems count]; i++ )
    {
      [menu removeItem:[addedOptionMenuItems objectAtIndex:i]];
    }
  [addedOptionMenuItems removeAllObjects];
}

- (void)addOptionMenuItem:(NSMenuItem *)item
{
  NSMenuItem *menu;
  menu = [[NSApp mainMenu] itemWithTitle:@"Options"];
  [[menu submenu] addItem:item];
  [addedOptionMenuItems addObject:item];
}

- (void)addWindowMenuItem:(NSMenuItem *)item
{
  NSMenuItem *menu;
  menu = [[NSApp mainMenu] itemWithTitle:@"Window"];
  [[menu submenu] addItem:item];
  [addedWindowMenuItems addObject:item];
}

- (void)setInfoText:(NSString *)string
{
}

- (void)lockInfoText:(NSString *)string
{
}

- (void)unlockInfoText
{
}

- (void)updateInfoText
{
}

static unsigned char default_viscolor[24][3]=
{
  {0,0,0 },
  { 24,33,41 }, 
  { 239,49,16 },
  { 206,41,16 },
  { 214,90,0 }, 
  { 214,102,0 },
  { 214,115,0 },
  { 198,123,8 },
  { 222,165,24 },
  { 214,181,33 },
  { 189,222,41 },
  { 148,222,33 },
  { 41,206,16 },
  { 50,190,16 },
  { 57,181,16 },
  { 49,156,8 },
  { 41,148,0 },
  { 24,132,8 },
  { 255,255,255 },
  { 214,214,222 },
  { 181,189,189 },
  { 160,170,175 },  
  { 148,156,165 },  
  { 150, 150, 150 }
};

- (unsigned char (*)[24][3])getVisualizationColors
{
  return &default_viscolor;
}

- (void)vis_timeout:(unsigned char *)data
{
}

- (void)vis_clear
{
}

- (void)openFilePanel:sender
{
  NSOpenPanel *panel;
  
  panel = [NSOpenPanel openPanel];
  
  [panel setAllowsMultipleSelection:NO];
  [panel setCanChooseDirectories:NO];
  
  if ( [panel runModalForTypes:nil] == NSOKButton ) 
    {
      [Control addAndPlayFile:[[panel filenames] objectAtIndex:0]];
    }
}

- (void)eject:sender
{
  [self openFilePanel:self];
}

- (void)play:sender
{
  if ( [Control songIsPlaying] && [Control songIsPaused] )
    [Control pause];
  else if ( [Control getPlaylistLength] )
    {
      if ( [Control songIsPlaying] == NO )
	[Control play];
    }
  else
    [self eject:self];
}

- (void)stop:sender
{
  [Control stop];
}

- (void)pause:sender
{
  [Control pause];
}

- (void)next:sender
{
  [Control nextSong];
}

- (void)previous:sender
{
  [Control previousSong];
}

- (void)volume_slider:sender
{
  [Control setVolume:[sender intValue]];
}

- (void)songposition_slider:sender
{
  int length, time;

  length = [Control getPlayingSongLength]/1000;
  time=(length*[sender intValue])/100;

  [Control seekToTime:time];
}

- (void)toggleShuffle:sender
{
  BOOL shuff = ![Control getPlaylistShuffle];
  [Control setPlaylistShuffle:shuff];
}

- (void)toggleRepeat:sender
{
  BOOL shuff = ![Control getRepeat];
  [Control setRepeat:shuff];
}

- (void)toggleNoPlaylistAdvance:sender
{
  [config setnoplaylist_advance:![config noplaylist_advance]];
  [sender setState:[config noplaylist_advance]];
}

- (void)showElapsedTime:sender
{
  [Control setTimerMode:TIMER_ELAPSED];
}

- (void)showRemainingTime:sender
{
  [Control setTimerMode:TIMER_REMAINING];
}

- (void)shuffle:sender
{
  [Control setPlaylistShuffle:[sender state]];
}

- (void)repeat:sender
{
  [Control setRepeat:[sender state]];
}

- (void)playlistOpen:sender
{
  NSOpenPanel *panel;
  
  panel = [NSOpenPanel openPanel];
  
  [panel setAllowsMultipleSelection:NO];
  [panel setCanChooseDirectories:NO];
  
  if ( [panel runModalForTypes:nil] == NSOKButton ) 
    {
      NSString *fn = [[panel filenames] objectAtIndex:0];
      if ( [Playlist loadPlaylist:fn] ) 
	{
	  [config setcurrent_playlist:fn];
	}
      else
	{
	  NSRunAlertPanel(getPackageName(), 
			  @"Unable to load playlist: %@", 
			  @"OK", nil, nil, fn);      
	  
	}
  }
}

- (void)playlistAddFile:sender
{
  NSOpenPanel *panel;
  
  panel = [NSOpenPanel openPanel];
  
  [panel setAllowsMultipleSelection:YES];
  [panel setCanChooseDirectories:NO];
  
  if ( [panel runModalForTypes:nil] == NSOKButton ) 
    {
      [Control addFilesToPlaylist:[panel filenames]];
    }
}

- (void)playlistAddDir:sender
{
  NSOpenPanel *panel;
  
  panel = [NSOpenPanel openPanel];
  
  [panel setAllowsMultipleSelection:YES];
  [panel setCanChooseDirectories:YES];
  [panel setCanChooseFiles:NO];
  
  if ( [panel runModalForTypes:nil] == NSOKButton ) 
    {
      [Control addFilesToPlaylist:[panel filenames]];
    }
}

- (void)playlistAddURL:sender
{
}

- (void)playlistNew:sender
{
  [Control newPlaylist];
}

- (void)playlistSave:sender
{
  [self savePlaylist];
}

- (BOOL)savePlaylist
{
  NSSavePanel *panel;
  NSString *cf;
  int res;
  
  panel = [NSSavePanel savePanel];

  cf = [config current_playlist];
  if ( [cf length] )
    res = [panel runModalForDirectory:[cf stringByDeletingLastPathComponent]
				 file:[cf lastPathComponent]];
  else
    res = [panel runModal];
  
  if ( res == NSOKButton ) {
    if ( [Playlist savePlaylist:[panel filename]] == NO ) {
      NSRunAlertPanel(getPackageName(), @"Unable to save playlist file: %@", 
		      @"OK", nil, nil, [panel filename]);      
      return NO;
    } else {
      [config setcurrent_playlist:[panel filename]];
      return YES;
    }
  }
  return NO;
}


- (void)playlistSelectAll:sender
{
  [Playlist selectAll];
}

- (void)playlistInvertSelection:sender
{
  [Playlist invertSelection];
}

- (void)playlistZeroSelection:popup
{
  [Playlist clearSelection];
}

- (void)playlistRemoveSelected:sender
{
  [Playlist removeSelected];
}

- (void)playlistCropSelection:sender
{
  [Playlist crop];
}

- (void)playlistRemoveAll:sender
{
  [Playlist removeAll];
}

- (void)showFileInfoBox:sender
{
  [Control popupFileInfoBox];
}

- (void)playlistSortByTitle:sender
{
  [Control sortPlaylistByTitle];
}

- (void)playlistSortByFilename:sender
{
  [Control sortPlaylistByFilename];
}

- (void)playlistSortByPathPlusFileName:sender
{
  [Control sortPlaylistByPathPlusFileName];
}

- (void)playlistRandomize:sender
{
  [Control randomizePlaylist];
}

- (void)playlistReverse:sender
{
  [Control reversePlaylist];
}

- (BOOL)enabledByDefault
{
  return NO;
}
@end



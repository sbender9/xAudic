/*  
 *  Xaudic - an audio player for MacOS X
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

#import "AppDelegate.h"
#import <MXA/Common.h>
#import <MXA/Control.h>
#import <AppKit/AppKit.h>
#import "Preferences.h"
#import <MXA/Plugins.h>
#import <MXA/PlaylistEntry.h>
#import <MXA/PlaylistEditor.h>
#import <MXA/Visualization.h>
#import <MXA/MXAConfig.h>

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
  mainRunLoop = [NSRunLoop currentRunLoop];

  [Control initializeControl];
  [Config load_configuration];
  [Visualization initializeVisualizations];
  [Plugin loadAllPluginBundles];
  [Visualization defaultVisualization]; //get the visTypeChanged notification tp gp out now that everything is loaded

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
       selector:@selector(timerModeValueChanged:)
	   name:TimerModeValueChangedNotification
	 object:nil];

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(userInterfaceChanged:)
	   name:UserInterfaceChangedNotification
	 object:nil];

  {
    NSArray *visualizations;
    Visualization *defaultV = [Visualization defaultVisualization];
    int i;
    visualizations = [Visualization plugins];
    for ( i = 0; i < [visualizations count]; i++ )
      {
	NSMenuItem *item;
	Visualization *vis = [visualizations objectAtIndex:i];
	if ( [vis isPublic] && [vis canEmbed] )
	  {
	    item = [visualizationMenu addItemWithTitle:[vis description]
				      action:@selector(visAction:)
				      keyEquivalent:@""];
	    [item setTag:i+1];
	    if ( defaultV == vis )
	      [item setState:1];
	  }
      }
    if ( defaultV == nil )
      [[visualizationMenu itemWithTag:-1] setState:1];
  }

  {
    NSArray *uis = [UserInterface plugins];
    UserInterface *interface, *current = [UserInterface ui];
    NSMenuItem *item;
    int i;
    for ( i = 0; i < [uis count]; i++ )
      {
	interface = [uis objectAtIndex:i];
	item = [userInterfacesMenu addItemWithTitle:[interface description]
				   action:@selector(userInterfacesAction:)
				   keyEquivalent:@""];
	[item setTag:i+1];
	if ( current == interface )
	  [item setState:1];
      }
  }

  ui = [UserInterface ui];
  [ui run];
  [uiConfigMenuItem setEnabled:[ui hasConfigure]];

  // Get the notifications to go out so ui's get updated
  [Control setRepeat:[Control getRepeat]];
  [Control setPlaylistShuffle:[Control getPlaylistShuffle]];
  [noAdvanceMenuItem setState:[config noplaylist_advance]];

  //update the volue settings
  [Control setVolume:[Control getVolume]];
  [Control setBalance:[Control getBalance]];

  initialized = YES;

  if ( startupPlayFile ) 
    {
      [Control addAndPlayFile:startupPlayFile];
      [startupPlayFile release];
      startupPlayFile = nil;
    }

  /*
  [NSTimer scheduledTimerWithTimeInterval:0.05
				   target:self 
				 selector:@selector(timer:)
				 userInfo:nil
				  repeats:YES];
  */
}

- (void)timer:nothing
{
  NSLog(@"timer");
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
  NSApplicationTerminateReply res = NSTerminateNow;
  
  if ( [Playlist modified] ) 
    {
      int ret = NSRunAlertPanel(getPackageName(), @"Your playlist has been changed. Would you like to save it?", @"Save", @"Cancel", @"Don't Save");    
      if ( ret == NSAlertDefaultReturn )
	res = [[UserInterface ui] savePlaylist] == YES ? NSTerminateNow : NSTerminateCancel;
      else if ( ret == NSAlertAlternateReturn )
	res = NSTerminateCancel;
    }
  return res;
}

- (void)configureVisualization:sender
{
  Visualization *plugin = [Visualization defaultVisualization];
  [plugin configure];
}

- (void)configureUserInterface:sender
{
  [[UserInterface ui] configure];
}

- (void)visAction:sender
{
  NSArray *visualizations;
  Visualization *defaultV = nil;
  int i;
  visualizations = [Visualization plugins];
  for ( i = 0; i < [visualizations count]; i++ )
    {
      Visualization *vis = [visualizations objectAtIndex:i];
      if ([sender tag]-1 == i )
	{
	  defaultV = vis;
	  [[visualizationMenu itemWithTag:(i+1)] setState:1];
	}
      else
	{
	  [[visualizationMenu itemWithTag:(i+1)] setState:0];
	}
    }
  if ( defaultV == nil )
    [[visualizationMenu itemWithTag:-1] setState:1];
  else
    [[visualizationMenu itemWithTag:-1] setState:0];
  [Visualization setDefaultVisualization:defaultV];
}

- (void)userInterfacesAction:sender
{
  NSArray *uis;
  UserInterface *current = nil;
  UserInterface *orig = [UserInterface ui];
  int i;
  uis = [UserInterface plugins];
  for ( i = 0; i < [uis count]; i++ )
    {
      UserInterface *interface = [uis objectAtIndex:i];
      if ([sender tag]-1 == i )
	{
	  current = interface;
	  [[userInterfacesMenu itemWithTag:(i+1)] setState:1];
	  [interface setEnabled:YES];
	}
      else
	{
	  [[userInterfacesMenu itemWithTag:(i+1)] setState:0];
	  [interface setEnabled:NO];
	}
    }
  
  [UserInterface updateSelectedUIPlugin];
  [self changeUI:orig];
}

- (void)userInterfaceChanged:(NSNotification *)notification
{
  NSArray *uis;
  UserInterface *current = [[notification userInfo] objectForKey:@"new"];
  int i;
  uis = [UserInterface plugins];
  for ( i = 0; i < [uis count]; i++ )
    {
      UserInterface *interface = [uis objectAtIndex:i];
      if ( interface == current )
	{
	  [[userInterfacesMenu itemWithTag:i+1] setState:1];
	}
      else
	[[userInterfacesMenu itemWithTag:i+1] setState:0];
    }
}


- (BOOL)application:sender openFile:(NSString *)file
{
  if ( initialized )
    [Control addAndPlayFile:file];
  else
    startupPlayFile = [file retain];
  return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
  if ( [Input isPlaying] )
    [Input stop];
  [config save_config];
}

- (void)set_menustate:mitem value:(int)val tagMin:(int)min tagMax:(int)max
{
  NSMenu *menu = [mitem submenu];
  NSArray *items = [menu itemArray];
  NSMenuItem *item;
  int i;
  
  for ( i = 0; i < [items count]; i++ ) {
    item = [items objectAtIndex:i];
    if ( min == -1 || ([item tag] >= min && [item tag] <= max) ) {
      [item setState:[item tag] == val];
    }
  }
}

- (void)about:sender
{
  NSString *s = [NSString stringWithFormat:@"Version %@", getVersion()];
  [aboutText setStringValue:s];
  [aboutPanel makeKeyAndOrderFront:sender];
}

- (void)_openFile:(NSString *)name
{
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  NSString *path;

  path = [bundle pathForResource:name ofType:nil];

  [[NSWorkspace sharedWorkspace] openFile:path];
}

- (void)showREADME:sender
{
  [self _openFile:@"Readme.html"];
}

- (void)showBUGS:sender
{
  [self _openFile:@"Bugs.html"];
}

- (void)showCHANGES:sender
{
  [self _openFile:@"Changes.html"];
}

- (void)showCOPYING:sender
{
  [self _openFile:@"Copying.html"];
}

- (void)showUICreation:sender
{
  [self _openFile:@"UICreation.html"];
}

- (void)shuffleValueChanged:(NSNotification *)notification
{
  BOOL val = [[[notification userInfo] objectForKey:@"shuffle"] boolValue];
  [shuffleMenuItem setState:val];
}

- (void)repeatValueChanged:(NSNotification *)notification
{
  BOOL val = [[[notification userInfo] objectForKey:@"repeat"] boolValue];
  [repeatMenuItem setState:val];
}

- (void)timerModeValueChanged:(NSNotification *)notification
{
  TimerMode val;

  val = (TimerMode)[[[notification userInfo] objectForKey:@"mode"] intValue];

  [timeElapsedMenuItem setState:val == TIMER_ELAPSED];
  [timeRemainingMenuItem setState:val == TIMER_REMAINING];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
  NSMenu  *menu = [menuItem menu];
  SEL options[] = { 0, 
		    @selector(repeat), 
		    @selector(shuffle),
		    @selector(noplaylist_advance), 
		    @selector(player_visible),
		    @selector(playlist_visible),
		    @selector(equalizer_visible) 
  };

  if ( [[menu title] isEqualToString:@"Visualization"] )
    {
      if ( [menuItem tag] == -2 )
	{
	  Visualization *plugin = [Visualization defaultVisualization];
	  if (plugin == nil || [plugin hasConfigure] == NO)
	    {
	      return NO;
	    }
	}
      return YES;
    }
  else if ( menu != [[NSApp mainMenu] itemWithTitle:@"Options"] )
    return YES;


  if ( [menuItem tag] == 101 ) 
    {
      [menuItem setState:[Input isPlaying]];
    } 
  else if ( [menuItem tag] > 0 && [menuItem tag] < 7 )
    [menuItem setState:(int)[config performSelector:options[[menuItem tag]]]];

  return YES;
}

- (void)changeUI:(UserInterface *)old
{
  NSDictionary *info;

  [old stop];

  ui = [UserInterface ui];
  [ui run];

  info = [NSDictionary dictionaryWithObjectsAndKeys:old, @"old", 
		       ui, @"new", nil];

  [uiConfigMenuItem setEnabled:[ui hasConfigure]];

  [[NSNotificationCenter defaultCenter]
    postNotificationName:UserInterfaceChangedNotification
                  object:nil
                userInfo:info];
}

- (NSRunLoop *)getMainRunLoop
{
  return mainRunLoop;
}

- (void)showPlaylistEditor:sender
{
  static NibObject *playlistEditor = nil;

  if (playlistEditor == nil) {
    playlistEditor = [[NibObject alloc] 
	 initWithNibName:@"PlaylistEditor"
		  bundle:[NSBundle bundleForClass:[self class]]];
  }
  [playlistEditor show];
  
}

- (void)addFilesToPlaylist:(NSArray *)files
{
}

@end




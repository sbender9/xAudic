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

#import "Configure.h"
#import <AppKit/AppKit.h>
#import <MXA/MXAConfig.h>

NSString *PreferencesChangedNotification = @"PreferencesChangedNotification";

NSString *keysForTags[] = { 
  @"load", @"snap_distance",
  @"default_extension" 
};
int numKeysForTags = (sizeof (keysForTags) / sizeof (keysForTags[0]));

@interface ControlToConfigKey : NSObject
{
@public
  NSControl *control;
  id key;
}
@end
@implementation ControlToConfigKey
@end


@implementation WinAmpConfigure

- (id)configKeyForControl:(NSControl *)control
{
  int i;
  ControlToConfigKey *ctck;

  for ( i = 0; i < [controlsToConfigKeys count]; i++ ) {
    ctck = [controlsToConfigKeys objectAtIndex:i];
    if ( ctck->control == control )
      return ctck->key;
  }
  return nil;
}

- (void)createButtonsToKeysForObject:view
{
  NSArray *views = nil;
  ControlToConfigKey *ctck;
  int i, tag;
  id key, control;

  if ( [view isKindOfClass:[NSMatrix class]] )
    views = [view cells];
  else if ( [view isKindOfClass:[NSView class]] )
    views = [view subviews];  
  
  for ( i = 0; i < [views count]; i++ ) 
    {
      control = [views objectAtIndex:i];
      [self createButtonsToKeysForObject:control];
      key = nil;
      if ( [control respondsToSelector:@selector(alternateTitle)] ) 
	{
	  key = [control alternateTitle];
	  [control setAlternateTitle:@""];
	} 
      else if ( [control respondsToSelector:@selector(tag)] ) 
	{
	  tag = [control tag];
	  if ( tag > 0 && tag <= numKeysForTags )
	    key = keysForTags[tag-1];
	}
      if ( key != nil ) 
	{
	  ctck = [[ControlToConfigKey alloc] init];
	  ctck->key = [key retain];
	  ctck->control = control;
	  [controlsToConfigKeys addObject:ctck];
	}
    }
}

- (void)setupPreferences
{
  controlsToConfigKeys = [[NSMutableArray array] retain];

  [self createButtonsToKeysForObject:[window contentView]];
}

- (void)updateObject:view
{
  NSArray *views = nil;
  int i;
  id control, key, val;

  if ( [view isKindOfClass:[NSMatrix class]] )
    views = [view cells];
  else if ( [view isKindOfClass:[NSView class]] )
    views = [view subviews];  
  
  for ( i = 0; i < [views count]; i++ ) 
    {
      control = [views objectAtIndex:i];
      [self updateObject:control];
      key = [self configKeyForControl:control];
      if ( key != nil ) 
	{
	  val = [config objectForKey:key];
	  if ( val != nil ) 
	    {
	      if ( [control isKindOfClass:[NSButton class]] 
		   || [control isKindOfClass:[NSButtonCell class]] )
		[control setState:[val isEqualToString:@"YES"]];
	      else
		[control setStringValue:val];
	    }
	}
    }
}

- (void)updateDisplay
{
  [self updateObject:[window contentView]];
}

- (void)awakeFromNib
{
  [self setupPreferences];
}

- (void)valueChanged:sender
{
  id key;
  id control;
  
  if ( [sender isKindOfClass:[NSMatrix class]] )
    control = [sender selectedCell];
  else
    control = sender;

  key = [self configKeyForControl:control];
  if ( key != nil ) 
    {
      if ( [control isKindOfClass:[NSButtonCell class]]
	   || [control isKindOfClass:[NSButton class]] )
	[config setObject:[control state] ? @"YES" : @"NO" forKey:key];
      else if ( [control isKindOfClass:[NSTextField class]] ) {
	[config setObject:[control stringValue] forKey:key];
      }
    }
}

- (void)ok:sender
{
  [[NSNotificationCenter defaultCenter]
    postNotificationName:PreferencesChangedNotification object:nil];
  [config save_config];
  [super ok:sender];
}

+ (void)initConfiguration
{
  [config setDefaultBoolValue:YES forKey:easy_move];
  [config setDefaultBoolValue:YES forKey:player_visible];
  [config setDefaultBoolValue:YES forKey:equalizer_visible];
  [config setDefaultBoolValue:YES forKey:playlist_visible];
  [config setDefaultBoolValue:YES forKey:dim_titlebar];
  [config setDefaultBoolValue:YES forKey:autoscroll];
  [config setDefaultBoolValue:NO forKey:player_shaded];
  [config setDefaultIntValue:10 forKey:snap_distance];
  [config setDefaultBoolValue:YES forKey:snap_windows];
  [config setDefaultBoolValue:NO forKey:always_on_top];
  [config setDefaultObject:@"(none)" forKey:skin_file_name];
  [config setDefaultBoolValue:YES forKey:always_show_cb];
  [config setDefaultBoolValue:YES forKey:smooth_title_scroll];
  [config setDefaultIntValue:300 forKey:@"winampui.playlist_size_x"];
  [config setDefaultIntValue:232 forKey:@"winampui.playlist_size_y"];
  [config setDefaultBoolValue:NO forKey:playlist_shaded];
  [config setDefaultBoolValue:NO forKey:eq_shaded];
  [config setDefaultBoolValue:NO forKey:close_box_on_left];
}

+ (void)setSkinFileName:(NSString *)val
{
  NSString *appPath = [[NSBundle mainBundle] bundlePath];
  NSString *filename = val;

  // If the skin's path is in our app wrapper then don't
  // write the full path. That way it will still work
  // if the app is moved somewhere else.
  if ([filename hasPrefix:appPath]) {
    NSRange relativeFileRange;
    relativeFileRange.location = [appPath length] + 1;
    relativeFileRange.length = [filename length] - [appPath length] - 1;

    filename = [filename substringWithRange:relativeFileRange];
    filename = [@"$(APP_WRAPPER)" stringByAppendingPathComponent:filename];
  }

  [config setObject:filename forKey:skin_file_name];
}


@end

NSString *player_visible = @"winampui.player_visible";
NSString *player_shaded = @"winampui.player_shaded";
NSString *playlist_shaded = @"winampui.playlist_shaded";
NSString *eq_shaded = @"winampui.eq_shaded";
NSString *dim_titlebar = @"winampui.dim_titlebar";
NSString *equalizer_visible = @"winampui.equalizer_visible";
NSString *playlist_visible = @"winampui.playlist_visible";
NSString *autoscroll = @"winampui.autoscroll";
NSString *always_on_top = @"winampui.always_on_top";
NSString *easy_move = @"winampui.easy_move";
NSString *snap_distance = @"winampui.snap_distance";
NSString *snap_windows = @"winampui.snap_windows";
NSString *skin_file_name = @"winampui.skin_file_name";
NSString *playlist_size = @"winampui.playlist_size";
NSString *always_show_cb = @"winampui.always_show_cb";
NSString *smooth_title_scroll = @"winampui.smooth_title_scroll";
NSString *close_box_on_left = @"winampui.close_box_on_left";


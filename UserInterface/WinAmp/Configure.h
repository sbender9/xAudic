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

#import <MXA/NibObject.h>
#import <MXA/MXAConfig.h>

@class NSMutableArray;

@interface WinAmpConfigure : NibObject
{
  id snapDistance;

  NSMutableArray *controlsToConfigKeys;
}

+ (void)initConfiguration;

+ (void)setSkinFileName:(NSString *)val;

@end

extern NSString *PreferencesChangedNotification;

extern NSString *player_visible;
extern NSString *player_shaded;
extern NSString *playlist_shaded;
extern NSString *eq_shaded;
extern NSString *eq_doublesize_linked;
extern NSString *dim_titlebar;
extern NSString *equalizer_visible;
extern NSString *playlist_visible;
extern NSString *autoscroll;
extern NSString *always_on_top;
extern NSString *easy_move;
extern NSString *snap_distance;
extern NSString *snap_windows;
extern NSString *skin_file_name;
extern NSString *playlist_size;
extern NSString *always_show_cb;
extern NSString *smooth_title_scroll;
extern NSString *close_box_on_left;

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
#import <Foundation/NSDictionary.h>
#import <Foundation/NSGeometry.h>
#import "Plugins.h"
#import "Visualization.h"
#import "Common.h"

@class NSFont;

#define NUM_EQ_BANDS 10

@interface Config : NSObject <NSCopying>
{
  float eq_bands[NUM_EQ_BANDS];
  NSMutableDictionary *dict;
}

- (id)objectForKey:(id)aKey;
- (BOOL)boolValueForKey:(NSString *)key;
- (int)intValueForKey:(NSString *)key;
- (NSString *)stringValueForKey:(NSString *)key;
- (NSSize)sizeValueForKey:(NSString *)key;

- (void)setObject:(id)anObject forKey:(id)aKey;
- (void)setStringValue:(NSString *)anObject forKey:(id)aKey;
- (void)setIntValue:(int)val forKey:(NSString *)key;
- (void)setBoolValue:(BOOL)val forKey:(NSString *)key;
- (void)setSizeValue:(NSSize)val forKey:(NSString *)key;
- (void)toggleBoolValueForKey:(NSString *)key;

- (void)setDefaultObject:(id)anObject forKey:(id)aKey;
- (void)setDefaultIntValue:(int)val forKey:(NSString *)key;
- (void)setDefaultBoolValue:(BOOL)val forKey:(NSString *)key;
- (void)setDefaultSizeValue:(NSSize)val forKey:(NSString *)key;


+ (void)load_configuration;

- (BOOL)pluginEnabled:(Plugin *)plugin;
- (BOOL)pluginEnabledIsSet:(Plugin *)plugin;
- (void)setPluginEnabled:(Plugin *)plugin value:(BOOL)val;

- (BOOL)shuffle;
- (BOOL)repeat;

- (BOOL)equalizer_active;
- (BOOL)equalizer_autoload;
- (float)equalizer_preamp;

- (int)volume;
- (int)balance;
- (int)playlist_position;
- (BOOL)show_numbers_in_pl;

- (float)eq_band:(int)band;
- (float *)eq_bands;
- (BOOL)read_titles_on_load;

- (TimerMode)timer_mode;
- (NSString *)current_playlist;
- (BOOL)noplaylist_advance;
- (BOOL)slow_cpu;
- (NSString *)default_extension;

- (void)setshuffle:(BOOL)val;
- (void)setrepeat:(BOOL)val;
- (void)setequalizer_active:(BOOL)val;
- (void)setequalizer_autoload:(BOOL)val;
- (void)setequalizer_preamp:(float)val;
- (void)setvolume:(int)val;
- (void)setbalance:(int)val;
- (void)setplaylist_position:(int)val;
- (void)setshow_numbers_in_pl:(BOOL)val;
- (void)seteq_band:(float)val :(int)band;
- (void)setread_titles_on_load:(BOOL)val;
- (void)settimer_mode:(TimerMode)val;
- (void)setcurrent_playlist:(NSString *)val;
- (void)setnoplaylist_advance:(BOOL)val;
- (void)setslow_cpu:(BOOL)val;
- (void)setdefault_extension:(NSString *)val;

- (void)save_config;
- (void)load_config;


@end

extern Config *config;

extern NSString *CFGDefaultVisualization;

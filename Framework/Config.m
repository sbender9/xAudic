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

#import "MXAConfig.h"
#import <AppKit/AppKit.h>

Config *config = nil;

@implementation Config

- (id)copyWithZone:(NSZone *)zone
{
  Config *copy = [[[Config alloc] init] autorelease];
  copy->dict = [dict mutableCopyWithZone:zone];
  memcpy(copy->eq_bands, eq_bands, sizeof(float)*NUM_EQ_BANDS);
  return copy;
}

- (void)save_config
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSArray *keys;
  id key, obj;
  int i;

  keys = [dict allKeys];
  for ( i = 0; i < [keys count]; i++ ) 
    {
      key = [keys objectAtIndex:i];
      obj = [dict objectForKey:key];
      if ( [obj isKindOfClass:[NSString class]] 
	   || [obj isKindOfClass:[NSDictionary class]] )
	[ud setObject:obj forKey:key];
    }
  
  {
    NSMutableArray *eqs = [NSMutableArray array];
    int i;
    for ( i = 0; i < NUM_EQ_BANDS; i++ ) {
      [eqs addObject:[[NSNumber numberWithFloat:eq_bands[i]] description]];
    }
    [ud setObject:eqs forKey:@"eq_bands"];
  }
  [ud synchronize];
}
  

- (void)load_config
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  id obj;
  NSArray *keys;
  id key;
  int i;
  NSMutableDictionary *newd;
  NSDictionary *rep = [ud dictionaryRepresentation];

  keys = [rep allKeys];
  for ( i = 0; i < [keys count]; i++ ) {
    key = [keys objectAtIndex:i];
    if ( [key hasPrefix:getPackageName()] )
      {
	obj = [ud objectForKey:key];
	if ( [obj isKindOfClass:[NSDictionary class]] ) 
	  {
	    newd = [NSMutableDictionary dictionaryWithDictionary:obj];
	    [dict setObject:newd forKey:key];
	  } 
	else if ( obj != nil )
	  [dict setObject:obj forKey:key];
      }
  }
  
  
  if ( [ud objectForKey:@"eq_bands"] ) {
    NSArray *eqs;
    int i;

    eqs = [ud objectForKey:@"eq_bands"];
    for ( i = 0; i < NUM_EQ_BANDS; i++ ) {
      eq_bands[i] = [[eqs objectAtIndex:i] floatValue];
    }
  }
  if( [self objectForKey:@"plugins"] == nil )
    {
      NSMutableDictionary *newd;
      newd = [NSMutableDictionary dictionary];
      [self setObject:newd forKey:@"plugins"];
    }
}

- init
{
  int i;

  dict = [[NSMutableDictionary dictionary] retain];

  [self setequalizer_preamp:0.0];
  [self setbalance:0];
  [self setvolume:50];
  [self setshow_numbers_in_pl:YES];
  [self setequalizer_active:NO];
  [self setequalizer_autoload:NO];
  [self setshuffle:NO];
  [self setrepeat:NO];
  [self setread_titles_on_load:NO];
  [self settimer_mode:TIMER_ELAPSED];
  [self setcurrent_playlist:@""];
  [self setnoplaylist_advance:NO];

  [self setObject:[NSMutableDictionary dictionary] forKey:@"plugins"];
  [self setslow_cpu:NO];
  [self setdefault_extension:@"mp3"];
  
  for ( i = 0; i < NUM_EQ_BANDS; i++ ) {
    eq_bands[i] = 0.0;
  }

  return [super init];
}

+ (void)load_configuration
{
  config = [[Config alloc] init];
  [config load_config];
}

/*
+ (void)initialize
{
  if ( [self class] == [Config class] )
    {
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      [self load_configuration];
      [pool release];
    }
}
*/

- (void)setObject:(id)anObject forKey:(id)aKey
{
  NSString *real_key = [NSString stringWithFormat:@"%@.%@", getPackageName(),
			    aKey];
  [dict setObject:anObject forKey:real_key];
}

- (void)setStringValue:(NSString *)anObject forKey:(id)aKey
{
  [self setObject:anObject forKey:aKey];
}

- (NSString *)stringValueForKey:(NSString *)key
{
  return (NSString *)[self objectForKey:key];
}

- (id)objectForKey:(id)aKey
{
  NSString *real_key = [NSString stringWithFormat:@"%@.%@", getPackageName(),
			    aKey];
  return [dict objectForKey:real_key];
}

- (BOOL)boolValueForKey:(NSString *)key
{
  NSString *val = [self objectForKey:key];
  return [val isEqualToString:@"YES"] ? YES : NO;
}

- (int)intValueForKey:(NSString *)key
{
  return [[self objectForKey:key] intValue];
}

- (void)setIntValue:(int)val forKey:(NSString *)key
{
  [self setObject:[NSString stringWithFormat:@"%d", val] forKey:key];
}

- (void)setBoolValue:(BOOL)val forKey:(NSString *)key
{
  [self setObject:val ? @"YES" : @"NO" forKey:key];
}

- (void)toggleBoolValueForKey:(NSString *)key
{
  [self setBoolValue:![self boolValueForKey:key]
	      forKey:key];
}

- (float)floatValueForKey:(NSString *)key
{
  return [[self objectForKey:key] floatValue];
}

- (void)setFloatValue:(float)val forKey:(NSString *)key
{
  [self setObject:[NSString stringWithFormat:@"%f", val] forKey:key];
}

- (NSSize)sizeValueForKey:(NSString *)key
{
  NSString *keyx, *keyy;
  keyx = [NSString stringWithFormat:@"%@_x", key];
  keyy = [NSString stringWithFormat:@"%@_y", key];

  return NSMakeSize([self intValueForKey:keyx],
		    [self intValueForKey:keyy]);
}

- (void)setSizeValue:(NSSize)size forKey:(NSString *)key
{
  NSString *keyx, *keyy;
  keyx = [NSString stringWithFormat:@"%@_x", key];
  keyy = [NSString stringWithFormat:@"%@_y", key];

  [self setFloatValue:size.width forKey:keyx];
  [self setFloatValue:size.height forKey:keyy];
}

- (void)setDefaultObject:(id)anObject forKey:(id)aKey
{
  if ( [self objectForKey:aKey] == nil )
    [self setObject:anObject forKey:aKey];
}

- (void)setDefaultIntValue:(int)val forKey:(NSString *)key
{
  if ( [self objectForKey:key] == nil )
    [self setIntValue:val forKey:key];
}

- (void)setDefaultBoolValue:(BOOL)val forKey:(NSString *)key
{
  if ( [self objectForKey:key] == nil )
    {
      [self setBoolValue:val forKey:key];
    }
}

- (void)setDefaultSizeValue:(NSSize)val forKey:(NSString *)key
{
  NSString *keyx = [NSString stringWithFormat:@"%@_x", key];  
  if ( [self objectForKey:keyx] == nil )
    [self setSizeValue:val forKey:key];
}

- (BOOL)shuffle
{
  return [self boolValueForKey:@"shuffle"];
}

- (BOOL)repeat
{
  return [self boolValueForKey:@"repeat"];
}

- (BOOL)equalizer_active
{
  return [self boolValueForKey:@"equalizer_active"];
}

- (BOOL)equalizer_autoload
{
  return [self boolValueForKey:@"equalizer_autoload"];
}

- (float)equalizer_preamp
{
  return [self floatValueForKey:@"equalizer_preamp"];
}

- (int)volume
{
  return [self intValueForKey:@"volume"];
}

- (int)balance
{
  return [self intValueForKey:@"balance"];
}

- (int)playlist_position
{
  return [self intValueForKey:@"playlist_position"];
}

- (BOOL)show_numbers_in_pl
{
  return [self boolValueForKey:@"show_numbers_in_pl"];
}

- (float)eq_band:(int)band
{
  return eq_bands[band];
}

- (float *)eq_bands
{
  return eq_bands;
}

- (BOOL)read_titles_on_load
{
  return [self boolValueForKey:@"read_titles_on_load"];
}

- (NSString *)current_playlist
{
  return [self objectForKey:@"current_playlist"];
}

- (TimerMode)timer_mode
{
  return (TimerMode)[self intValueForKey:@"timer_mode"];
}

- (BOOL)noplaylist_advance
{
  return [self boolValueForKey:@"noplaylist_advance"];
}

- (BOOL)pluginEnabled:(Plugin *)plugin
{
  NSDictionary *pdict = [self objectForKey:@"plugins"];
  NSString *val;
  val = [pdict objectForKey:[plugin name]];
  return val && [val isEqualToString:@"YES"] ? YES : NO;
}

- (BOOL)pluginEnabledIsSet:(Plugin *)plugin
{
  NSDictionary *pdict = [self objectForKey:@"plugins"];
  NSString *val;
  val = [pdict objectForKey:[plugin name]];
  return val != nil;
}

- (BOOL)slow_cpu
{
  return [self boolValueForKey:@"slow_cpu"];
}

- (NSString *)default_extension
{
  return [self objectForKey:@"default_extension"];
}

- (void)setPluginEnabled:(Plugin *)plugin value:(BOOL)val
{
  NSMutableDictionary *pdict = [self objectForKey:@"plugins"];
  [pdict setObject:val ? @"YES" : @"NO"
	    forKey:[plugin name]];
}

- (void)setshuffle:(BOOL)val
{
  [self setBoolValue:val forKey:@"shuffle"];
}

- (void)setrepeat:(BOOL)val
{
  [self setBoolValue:val forKey:@"repeat"];
}

- (void)setequalizer_active:(BOOL)val
{
  [self setBoolValue:val forKey:@"equalizer_active"];
}

- (void)setequalizer_autoload:(BOOL)val
{
  [self setBoolValue:val forKey:@"equalizer_autoload"];
}

- (void)setequalizer_preamp:(float)val
{
  [self setFloatValue:val forKey:@"equalizer_preamp"];
}

- (void)setvolume:(int)val
{
  [self setIntValue:val forKey:@"volume"];
}

- (void)setbalance:(int)val
{
  [self setIntValue:val forKey:@"balance"];
}

- (void)setplaylist_position:(int)val
{
  [self setIntValue:val forKey:@"playlist_position"];
}

- (void)setshow_numbers_in_pl:(BOOL)val
{
  [self setBoolValue:val forKey:@"show_numbers_in_pl"];
}

- (void)seteq_band:(float)val :(int)band
{
  eq_bands[band] = val;
}

- (void)setread_titles_on_load:(BOOL)val
{
  [self setBoolValue:val forKey:@"read_titles_on_load"];
}

- (void)setcurrent_playlist:(NSString *)val
{
  [self setObject:val forKey:@"current_playlist"];
}

- (void)setnoplaylist_advance:(BOOL)val
{
  [self setBoolValue:val forKey:@"noplaylist_advance"];
}

- (void)setslow_cpu:(BOOL)val
{
  [self setBoolValue:val forKey:@"slow_cpu"];
}

- (void)setdefault_extension:(NSString *)val
{
  [self setObject:val forKey:@"default_extension"];
}

- (void)settimer_mode:(TimerMode)val
{
  [self setIntValue:(int)val forKey:@"timer_mode"];
}

@end

NSString *CFGDefaultVisualization = @"embededVisualization";

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

#import <AppKit/AppKit.h>
#import "Configure.h"


static NSMutableDictionary *config = nil;

@implementation Configure

- (NSString *)nibName
{
  return @"XingConfigure";
}

+ (void)loadValueForKey:(NSString *)key
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  id val;
  
  val = [ud objectForKey:key];
  if( val != nil )
    [[self config] setObject:val forKey:key];
}

+ (void)loadConfig
{
  NSArray *keys;
  id key;
  int i;

  keys = [[self config] allKeys];
  for ( i = 0; i < [keys count]; i++ ) {
    key = [keys objectAtIndex:i];
    [self loadValueForKey:key];
  }
}

+ (NSMutableDictionary *)config
{
  if ( config == nil ) {
    config = [[NSMutableDictionary dictionary] retain];
    [self setHttpBufferSize:128];
    [self setHttpPreBuffer:25];
    [self setProxyPort:8080];
    [self setUseProxy:NO];
    [self setProxyHost:@"localhost"];
    [self setUseId3:YES];
    [self setId3Format:@"%W - %V"];
    [self setHttpTimeout:10.0];
    [self loadConfig];
  }
  return config;
}

+ (void)setHttpBufferSize:(int)val
{
  [[self config] setObject:[NSNumber numberWithInt:val] 
		    forKey:@"xing.httpBufferSize"];
}

+ (void)setHttpPreBuffer:(int)val
{
  [[self config] setObject:[NSNumber numberWithInt:val] 
		    forKey:@"xing.httpPreBuffer"];
}

+ (void)setHttpTimeout:(NSTimeInterval)val
{
  [[self config] setObject:[NSNumber numberWithDouble:val]
	            forKey:@"xing.httpTimeout"];
}

+ (void)setProxyPort:(int)val
{
  [[self config] setObject:[NSNumber numberWithInt:val] 
		    forKey:@"xing.proxyPort"];
}

+ (void)setUseProxy:(BOOL)val
{
  [[self config] setObject:val ? @"YES" : @"NO" 
		    forKey:@"xing.useProxy"];
}

+ (void)setProxyHost:(NSString *)val
{
  [[self config] setObject:val 
		    forKey:@"xing.proxyHost"];
}

+ (void)setUseId3:(BOOL)val
{
  [[self config] setObject:val ? @"YES" : @"NO"
		    forKey:@"xing.useId3"];
}

+ (void)setId3Format:(NSString *)val
{
  [[self config] setObject:val forKey:@"xing.id3Format"];
}

+ (int)httpBufferSize
{
  return [[[self config] objectForKey:@"xing.httpBufferSize"] intValue];
}

+ (int)httpPreBuffer
{
  return [[[self config] objectForKey:@"xing.httpPreBuffer"] intValue];
}

+ (NSTimeInterval)httpTimeout
{
  return [[[self config] objectForKey:@"xing.httpTimeout"] doubleValue];
}

+ (int)proxyPort
{
  return [[[self config] objectForKey:@"xing.proxyPort"] intValue];
}

+ (BOOL)useProxy
{
  return [[[self config] objectForKey:@"xing.useProxy"] 
		      isEqualToString:@"YES"];
}

+ (NSString *)proxyHost
{
  return [[self config] objectForKey:@"xing.proxyHost"];
}

+ (BOOL)useId3
{
  return [[[self config] objectForKey:@"xing.useId3"] 
		      isEqualToString:@"YES"];
}

+ (NSString *)id3Format
{
  return [[self config] objectForKey:@"xing.id3Format"];
}

+ (void)saveConfig
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSArray *keys;
  id key, obj;
  int i;

  keys = [[self config] allKeys];
  for ( i = 0; i < [keys count]; i++ ) {
    key = [keys objectAtIndex:i];
    obj = [[self config] objectForKey:key];
    if ( [obj isKindOfClass:[NSString class]] 
	 || [obj isKindOfClass:[NSDictionary class]] )
      [ud setObject:obj forKey:key];
    else if ( [obj isKindOfClass:[NSNumber class]] )
      [ud setObject:[obj description] forKey:key];
  }
}

- (void)updateDisplay
{
  [bufferSize setIntValue:[[self class] httpBufferSize]];
  [preBuffer setIntValue:[[self class] httpPreBuffer]];
  [timeOut setDoubleValue:[[self class] httpTimeout]];
  [useProxy setState:[[self class] useProxy]];
  [host setStringValue:[[self class] proxyHost]];
  [port setIntValue:[[self class] proxyPort]];
  [useTags setState:[[self class] useId3]];
  [tagFormat setStringValue:[[self class] id3Format]];
  [host setEnabled:[[self class] useProxy]];
  [port setEnabled:[[self class] useProxy]];
  [tagFormat setEnabled:[[self class] useId3]];
  [hostT setEnabled:[[self class] useProxy]];
  [portT setEnabled:[[self class] useProxy]];
  [tagFormatT setEnabled:[[self class] useId3]];
}

- (void)readValues
{
  [[self class] setHttpBufferSize:[bufferSize intValue]];
  [[self class] setHttpPreBuffer:[preBuffer intValue]];
  [[self class] setHttpTimeout:[timeOut doubleValue]];
  [[self class] setProxyHost:[host stringValue]];
  [[self class] setProxyPort:[port intValue]];
  [[self class] setId3Format:[tagFormat stringValue]];
  [[self class] setUseId3:[useTags state]];
  [[self class] setUseProxy:[useProxy state]];
}

- (void)useProxy:sender
{
  [host setEnabled:[sender state]];
  [port setEnabled:[sender state]];
  [hostT setEnabled:[sender state]];
  [portT setEnabled:[sender state]];
}

- (void)useId3:sender
{
  [tagFormat setEnabled:[sender state]];
  [tagFormatT setEnabled:[sender state]];
}

- (void)ok:sender
{
  [self readValues];
  [[self class] saveConfig];
  [super ok:sender];
}

@end


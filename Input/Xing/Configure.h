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

@class NSMutableDictionary;
@class NSString;

@interface Configure : NibObject
{
  id bufferSize;
  id preBuffer;
  id timeOut;
  id useProxy;
  id host;
  id port;
  id useTags;
  id tagFormat;
  id tagFormatT;
  id hostT;
  id portT;
}

- (void)useId3:sender;
- (void)useProxy:sender;

+ (NSMutableDictionary *)config;
+ (void)setId3Format:(NSString *)val;
+ (void)setUseId3:(BOOL)val;
+ (void)setProxyHost:(NSString *)val;
+ (void)setUseProxy:(BOOL)val;
+ (void)setProxyPort:(int)val;
+ (void)setHttpPreBuffer:(int)val;
+ (void)setHttpBufferSize:(int)val;
+ (void)setHttpTimeout:(NSTimeInterval)val;

+ (NSString *)id3Format;
+ (BOOL)useId3;
+ (NSString *)proxyHost;
+ (BOOL)useProxy;
+ (int)proxyPort;
+ (int)httpPreBuffer;
+ (int)httpBufferSize;
+ (NSTimeInterval)httpTimeout;

@end

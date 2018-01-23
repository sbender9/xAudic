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
#import <Foundation/Foundation.h>
#import <MXA/Common.h>

typedef enum
{
  FMT_U8,FMT_S8,FMT_U16_LE,FMT_U16_BE,FMT_U16_NE,FMT_S16_LE,FMT_S16_BE,FMT_S16_NE
} AFormat;



@class PlaylistEntry;
@class Output;

@protocol PluginProtocol
// Just used so the bundle loading stuff can tell if a class is a plugin
@end

@interface Plugin : NSObject <PluginProtocol>
{
  NSString *description;
}

- initWithDescription:(NSString *)_description;
- (void)setEnabled:(BOOL)val;
- (BOOL)enabled;
- (NSString *)description;
- (NSString *)name;
- (BOOL)hasAbout;
- (BOOL)hasConfigure;
- (void)about;
- (void)configure;

+ (void)registerPluginClass:(Class)aClass;
+ (void)loadAllPluginBundles;

+ (void)loadPluginsAtPath:(NSString *)path
              includeNibs:(BOOL)val;
+ (void)updateOutputPlugin;

+ (void)sendNotification:(NSString *)name 
	      withNumber:(NSNumber *)num 
                   named:(NSString *)numberNamel;
@end

@interface Input : Plugin

+ (NSArray *)plugins;
+ (void)registerPlugin:(Plugin *)op;

+ (void)playFile:(NSString *)filename;
+ (NSString *)playingFile;
+ (BOOL)isPlaying;
+ (BOOL)isPaused;
+ (int)getTime;
+ (void)stop;
+ (void)pause;
+ (void)seek:(int)percent;
+ (void)setEq;
+ (void)getSongInfo:(NSString *)fileName entry:(PlaylistEntry *)entry;
+ (void)setInfoTitle:(NSString *)title 
	      length:(int)length
		rate:(int)rate
	   frequency:(int)frequency
	 numChannels:(int)numChannels;
+ (NSDictionary *)getCurrentSongInfo;
+ (void)setBitrateChange:(int)rate;
+ (void)setInfoText:(NSString *)text;
+ (void)lockInfoText:(NSString *)text;
+ (void)unlockInfoText;
+ (void)getVolumeLeft:(int *)l right:(int*)r;
+ (void)setVolumeLeft:(int)l right:(int)r;
+ (void)fileInfoBox:(NSString *)filename;
+ (void)updateVolume;
+ (void)donePlaying:(BOOL)stopped;

- (void)donePlaying:(BOOL)stopped;
- (void)setInfoText:(NSString *)text;
- (void)lockInfoText:(NSString *)text;
- (void)unlockInfoText;
- (BOOL)isOurFile:(NSString *)filename;
- (void)playFile:(NSString *)filename;
- (int)getTime;
- (void)setEq:(BOOL)on preamp:(float)preamp bands:(float *)bands;
- (NSArray *)scanDir:(NSString *)dirname;
- (void)stop;
- (void)pause:(BOOL)paused;
- (void)seek:(int)percent;
- (BOOL)getVolumeLeft:(int *)l right:(int*)r;
- (BOOL)setVolumeLeft:(int)l right:(int)r;
- (NSDictionary *)getSongInfoForFile:(NSString *)filename;
- (void)fileInfoBox:(NSString *)filename;
- (BOOL)enabledByDefault;

@end

@interface Output : Plugin

+ (NSArray *)plugins;
+ (void)registerPlugin:(Plugin *)op;
+ (Output *)output;

- (void)getVolumeLeft:(int *)l right:(int *)r;
- (void)setVolumeLeft:(int )l right:(int)r;
- (BOOL)openAudioFormat:(AFormat )fmt rate:(int)rate numChannels:(int)nch;
- (void)writeAudioData:(const void *)ptr length:(int)length;
- (void)wait;
- (void)closeAudio;
- (void)flush:(int)time;
- (void)pause:(BOOL) paused;
- (void)cancelWrite;
- (int)outputTime;
- (int)writtenTime;
- (void)stop;

- (BOOL)bufferPlaying;
- (BOOL)enabledByDefault;

@end

@interface Effect : Plugin
{
}

+ (void)registerPlugin:(Plugin *)op;
+ (NSArray *)plugins;

- (void)cleanup;

+ (int)modSampleData:(short int *)data
	      length:(int)length
       bitsPerSample:(int)bps
	 numChannels:(int)numChannels
		freq:(int)srate;

- (int)modSampleData:(short int *)data
	      length:(int)length
       bitsPerSample:(int)bps
	 numChannels:(int)numChannels
		freq:(int)srate;

@end

@interface General : Plugin
{
}

+ (void)registerPlugin:(Plugin *)op;
+ (NSArray *)plugins;
@end

extern void mysleep(unsigned int microseconds);


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

#import <AppKit/NSPanel.h>
#import "Common.h"
#import "Plugins.h"
#import "UserInterface.h"
#import "Visualization.h"
#import "MXAConfig.h"
#import "PlaylistEntry.h"
#import "NibUserInterface.h"

static NSMutableArray *input_plugins = nil;
static NSMutableArray *output_plugins = nil;
static NSMutableArray *effect_plugins = nil;
static NSMutableArray *registeredClasses = nil;
static BOOL input_playing = NO;
static BOOL input_paused = NO;
static NSDictionary *currentSongInfo = nil;
static Input *current_input_plugin = nil;
static Output *selectedOutputPlugin = nil;
static NSString *playingFile = nil;

NSString *SongStartedNotification = @"SongStartedNotification";
NSString *SongEndedNotification = @"SongEndedNotification";
NSString *SongCompletedNotification = @"SongCompletedNotification";
NSString *PlayStatusChangedNotification = @"PlayStatusChangedNotification";
NSString *BitrateChangedNotification = @"BitrateChangedNotification";

@implementation Input


+ (void)registerPlugin:(Plugin *)op
{
  if ( input_plugins == nil )
    input_plugins = [[NSMutableArray array] retain];
  [input_plugins addObject:op];
}

+ (NSArray *)plugins
{
  return input_plugins;
}

+ (void)setInfoTitle:(NSString *)title 
	      length:(int)length
		rate:(int)rate
	   frequency:(int)frequency
	 numChannels:(int)numChannels;
{
  NSMutableDictionary *info = [NSMutableDictionary dictionary];

  [info setObject:title forKey:@"title"];

  [info setObject:[NSNumber numberWithInt:length]
	forKey:@"length"];
  [info setObject:[NSNumber numberWithInt:frequency]
	forKey:@"frequency"];
  [info setObject:[NSNumber numberWithInt:numChannels]
	forKey:@"numChannels"];

  rate /= 1000; 
  if( rate >= 1000) 
    {
      rate /= 100;
    }

  [info setObject:[NSNumber numberWithInt:rate] forKey:@"rate"];

  [currentSongInfo release];
  currentSongInfo = [info retain];

  [[NSNotificationCenter defaultCenter]
     postNotificationName:SongStartedNotification
		   object:nil
		 userInfo:info];
}

+ (NSDictionary *)getCurrentSongInfo
{
  return currentSongInfo;
}

+ (void)setBitrateChange:(int)rate
{
  static NSDate *lastUpdate = nil;


  if ( lastUpdate == nil 
       || [[NSDate date] timeIntervalSinceDate:lastUpdate] > 1.0 )
    {
      rate /= 1000; 
      if( rate >= 1000) 
	{
	  rate /= 100;
	}

      [self sendNotification:BitrateChangedNotification
	          withNumber:[NSNumber numberWithInt:rate]
	               named:@"rate"];
      [lastUpdate release];
      lastUpdate = [[NSDate date] retain];
    }
}

+ (void)setInfoText:(NSString *)text
{
  [[UserInterface ui] setInfoText:text];
}

+ (void)lockInfoText:(NSString *)text
{
  [[UserInterface ui] lockInfoText:text];
}

+ (void)unlockInfoText
{
  [[UserInterface ui] unlockInfoText];
}

- (void)setInfoText:(NSString *)text
{
  [[self class] setInfoText:text];
}

- (void)lockInfoText:(NSString *)text
{
  [[self class] lockInfoText:text];
}

- (void)unlockInfoText
{
  [[self class] unlockInfoText];
}

+ (void)setEq
{
  if ( input_playing && current_input_plugin != nil )
    [current_input_plugin setEq:[config equalizer_active]
			 preamp:[config equalizer_preamp]
			  bands:[config eq_bands]];
}

+ (NSString *)playingFile
{
  return playingFile;
}

+ (Input *)epluginForFile:(NSString *)filename
{
  NSArray *inputps;
  Input *ip;
  int i;

  inputps = [Input plugins];
    
  for ( i = 0; i < [inputps count]; i++ ) {
    ip = [inputps objectAtIndex:i];
    if ( [ip enabled] && [ip isOurFile:filename] ) {
      return ip;
    }
  }
  return nil;
}

+ (Input *)pluginForFile:(NSString *)filename
{
  Input *ip;

  ip = [self epluginForFile:filename];
  if ( ip == nil && [[config default_extension] length] > 0 ) {
    ip = [self epluginForFile:[filename stringByAppendingFormat:@".%@",
				[config default_extension]]];
  }
  return ip;
}

+ (void)playFile:(NSString *)filename
{
  Input *ip;

  if ( input_playing )
    [Input stop];

  ip = [self pluginForFile:filename];

  if ( ip != nil ) {
    input_playing = YES;
    current_input_plugin = ip;
    playingFile = [filename retain];

    [ip playFile:filename];

    [ip setEq:[config equalizer_active]
       preamp:[config equalizer_preamp]
	bands:[config eq_bands]];
  } else {
    NSRunAlertPanel(getPackageName(), 
		    @"No input plugin found for file: %@", @"OK", 
		    nil, nil, filename);    
  }
}

+ (void)updateVolume
{
  int l, r;
  int v = [config volume];
  if ( [config balance] < 0 )
    {
      l = v;
      r = ((100.0 + [config balance])/100.0) * v;
    }
  else if ( [config balance] > 0)
    {
      r = v;
      l = ((100.0 - [config balance])/100.0) * v;
    } 
  else 
    {
      l = r = v;
    }
  [Input setVolumeLeft:l right:r];
  //NSLog(@"Volume: l:%d r:%d, balance:%d", l, r, [config balance]);
}

+ (BOOL)isPlaying
{
  return input_playing;
}

  
+ (BOOL)isPaused
{
  return input_paused;
}

+ (void)donePlaying:(BOOL)stopped
{
  input_playing = NO;
  input_paused = NO;
  [playingFile release];
  playingFile = nil;

  [[NSNotificationCenter defaultCenter]
    postNotificationName:SongEndedNotification
                  object:nil
                userInfo:nil];

  [self sendNotification:PlayStatusChangedNotification
	withNumber:[NSNumber numberWithInt:STATUS_STOP]
	named:@"status"];

  if ( stopped == NO )
    [[NSNotificationCenter defaultCenter]
      postNotificationName:SongCompletedNotification
                    object:nil
                  userInfo:nil];
}

- (void)donePlaying:(BOOL)stopped
{
  [[self class] donePlaying:stopped];
}

+ (int)getTime
{
  return [current_input_plugin getTime];
}

+ (void)stop
{
  if ( input_playing ) 
    {
      [current_input_plugin stop];
    }
}

+ (void)pause
{
  if  ( input_playing ) 
    {
      input_paused = !input_paused;
      [current_input_plugin pause:input_paused];

      [self sendNotification:PlayStatusChangedNotification
	          withNumber:[NSNumber numberWithInt:input_paused ? STATUS_PAUSE : STATUS_PLAY]
	           named:@"status"];
    }
}

+ (void)seek:(int)percent
{
  if  ( input_playing ) 
    {
      [current_input_plugin seek:percent];
    }
}

+ (void)getSongInfo:(NSString *)fileName entry:(PlaylistEntry *)entry
{
  Input *ip;
  NSDictionary *res = nil;

  ip = [self pluginForFile:fileName];
  if ( ip != nil ) {
    res = [ip getSongInfoForFile:fileName];
    if ( res != 0 ) {
      [entry setTitle:[res objectForKey:@"title"]];
      [entry setLength:[[res objectForKey:@"length"] intValue]];
      [entry setAlbumName:[res objectForKey:@"albumName"]];
      [entry setArtistName:[res objectForKey:@"artistName"]];      
      [entry setSongName:[res objectForKey:@"songName"]];
    }
  }
}


+ (void)getVolumeLeft:(int *)l right:(int*)r
{
  if ( input_playing ) {
    if ( [current_input_plugin getVolumeLeft:l right:r] )
      return;
    [selectedOutputPlugin getVolumeLeft:l right:r];
  }
}

+ (void)setVolumeLeft:(int)l right:(int)r
{
  if ( input_playing ) {
    if ( [current_input_plugin setVolumeLeft:l right:r] )
      return;
    [selectedOutputPlugin setVolumeLeft:l right:r];
  }
}

+ (void)fileInfoBox:(NSString *)filename
{
  Input *ip;

  ip = [self pluginForFile:filename];
  if ( ip != nil )
    [ip fileInfoBox:filename];
}

- (BOOL)enabledByDefault
{
  return YES;
}

- (NSArray *)scanDir:(NSString *)dirname
{
  return nil;
}

- (void)stop
{
}

- (void)pause:(BOOL)paused
{
}

- (void)seek:(int)percent
{
}

- (BOOL)getVolumeLeft:(int *)l right:(int*)r
{
  return NO;
}

- (BOOL)setVolumeLeft:(int)l right:(int)r
{
  return NO;
}


- (NSDictionary *)getSongInfoForFile:(NSString *)filename
{
  return nil;
}

- (void)fileInfoBox:(NSString *)filename
{
}

- (void)setEq:(BOOL)on preamp:(float)preamp bands:(float *)bands
{
}

- (BOOL)isOurFile:(NSString *)filename
{
  return NO;
}

- (void)playFile:(NSString *)filename
{
}

- (int)getTime
{
  return -1;
}

@end


@implementation Output

+ (void)registerPlugin:(Plugin *)ip
{
  if ( output_plugins == nil )
    output_plugins = [[NSMutableArray array] retain];
  
  [output_plugins addObject:ip];
}


+ (NSArray *)plugins
{

  return output_plugins;
}

- (void)getVolumeLeft:(int *)l right:(int *)r
{
}

- (void)setVolumeLeft:(int )l right:(int)r
{
}

- (BOOL)openAudioFormat:(AFormat )fmt rate:(int)rate numChannels:(int)nch
{
  return NO;
}

- (void)writeAudioData:(const void *)ptr length:(int)length
{
}

- (void)closeAudio
{
}

- (void)flush:(int)time
{
}

- (void)pause:(BOOL) paused
{
}

- (int)outputTime
{
  return 0;
}

- (int)writtenTime
{
  return 0;
}

+ (Output *)output
{
  return selectedOutputPlugin;
}

- (void)wait
{
}

- (BOOL)enabledByDefault
{
  return NO;
}

- (void)stop
{
}

- (void)cancelWrite
{
}

- (BOOL)bufferPlaying
{
  return NO;
}

@end

@implementation General

+ (void)registerPlugin:(Plugin *)op
{
}

+ (NSArray *)plugins
{
  return nil;
}
@end


@implementation Effect
+ (void)registerPlugin:(Plugin *)op
{
  if ( effect_plugins == nil )
    effect_plugins = [[NSMutableArray array] retain];
  [effect_plugins addObject:op];
}

+ (NSArray *)plugins
{
  return effect_plugins;
}

+ (int)modSampleData:(short int *)data
	      length:(int)length
       bitsPerSample:(int)bps
	 numChannels:(int)numChannels
		freq:(int)srate
{
  int new_len = length;
  int i;
  Effect *ep;
  
  for ( i = 0; i < [effect_plugins count]; i++ ) {
    ep = [effect_plugins objectAtIndex:i];
    if ( [ep enabled] )
      new_len = [ep modSampleData:data
			   length:new_len
		    bitsPerSample:bps
		      numChannels:numChannels
			     freq:srate];
    
  }
  return new_len;
}

- (void)cleanup
{
}

- (int)modSampleData:(short int *)data
	      length:(int)length
       bitsPerSample:(int)bps
	 numChannels:(int)numChannels
		freq:(int)srate
{
  return length;
}

@end

@implementation Plugin

/*
+ (void)initialize
{
  if ( [self class] == [Plugin class] )
    {
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      [self loadAllPluginBundles];
      [pool release];
    }
}
*/

- initWithDescription:(NSString *)_description
{
  description = [_description retain];
  return [super init];
}

- (void)setEnabled:(BOOL)val
{
  [config setPluginEnabled:self value:val];
}

- (BOOL)enabled
{
  return [config pluginEnabled:self];
}

- (NSString *)name
{
  return NSStringFromClass([self class]);
}

- (NSString *)description
{
  return [NSString stringWithString:description];
}

- (void)about
{
}

- (void)configure
{
}

- (BOOL)hasAbout
{
  return NO;
}

- (BOOL)hasConfigure
{
  return NO;
}

+ (void)registerPluginClass:(Class)aClass
{
  if ( registeredClasses == nil )
    registeredClasses = [[NSMutableArray alloc] init];
  [registeredClasses addObject:aClass];
}

+ (BOOL)_registerPluginClass:(Class)aClass
{

  BOOL res = NO;
  //we might be called from +load so:
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  Plugin *plugin = [[aClass alloc] init];

  if ( [plugin isKindOfClass:[Output class]] ) 
    {
      [Output registerPlugin:plugin];
      res = YES;
    } 
  else if ( [plugin isKindOfClass:[Input class]] ) 
    {
      [Input registerPlugin:plugin];
      res = YES;
    } 
  else if ( [plugin isKindOfClass:[General class]] ) 
    {
      [General registerPlugin:plugin];
      res = YES;
    }
  else if ( [plugin isKindOfClass:[Effect class]] ) 
    {
      [Effect registerPlugin:plugin];
      res = YES;
    } 
  else if ( [plugin isKindOfClass:[UserInterface class]] ) 
    {
      [UserInterface registerPlugin:plugin];
      res = YES;
    } 
  else if ( [plugin isKindOfClass:[Visualization class]] ) 
    {
      [Visualization registerPlugin:plugin];
      res = YES;
    }
  if ( res == NO )
    NSLog(@"%@: unknow plugin type '%@'", getPackageName(), 
	  NSStringFromClass(aClass));
  [pool release];
  return res;
}

+ (void)bundleDidLoad:(NSNotification *)notification
{
  NSArray *classes;
  int i;
  NSString *className, *bundlePath;
  BOOL gotOne = YES;
  Class aClass;

  bundlePath = [[notification object] bundlePath];
  classes = [[notification userInfo] objectForKey:@"NSLoadedClasses"];

  for ( i = 0; i < [classes count]; i++ ) {
    className = [classes objectAtIndex:i];
    aClass = NSClassFromString(className);
    if ( [aClass conformsToProtocol:@protocol(PluginProtocol)] ) 
      {
	if ( [self _registerPluginClass:aClass] )
	  gotOne = YES;
      }
  }
  if ( gotOne == NO )
    NSLog(@"%@: loaded a plugin bundle(%@) with no plugin classes",
	  getPackageName(), bundlePath);
}

+ (void)loadPluginsAtPath:(NSString *)path
	      includeNibs:(BOOL)includeNibs
{
  NSString *ext, *entry, *fullPath, *bname, *dname;
  NSBundle *bundle;
  NSFileManager *fm = [NSFileManager defaultManager];
  NSArray *files;
  int i;

  files = [fm directoryContentsAtPath:path];

  for ( i = 0; i < [files count]; i++ ) {
    entry = [files objectAtIndex:i];
    ext = [entry pathExtension];
    fullPath = [path stringByAppendingPathComponent:entry];

    if ( [ext isEqualToString:@"bundle"] ) 
      {

	//seems to be a bug in NSBundle, if only a _debug executable exists
	//it will not be loaded, so we'll trick it
	//Scott: is this still true??
	bname = [entry stringByDeletingPathExtension];
	bname = [fullPath stringByAppendingPathComponent:bname];
	dname = [bname stringByAppendingString:@"_debug"];
	
	if ( [fm fileExistsAtPath:bname] == NO
	     && [fm fileExistsAtPath:dname] ) {
	  [fm createSymbolicLinkAtPath:bname pathContent:dname];
	}
	
	bundle = [NSBundle bundleWithPath:fullPath];
	[bundle principalClass];
      }
    else if ( includeNibs && [ext isEqualToString:@"nib"] )
      {
	[NibUserInterface loadPlugin:fullPath];
      }
  }
}

+ (void)updateOutputPlugin
{
  int i;
  for ( i = 0; i < [output_plugins count]; i++ ) {
    if ( [[output_plugins objectAtIndex:i] enabled] )
      selectedOutputPlugin = [output_plugins objectAtIndex:i];
  }
  if ( selectedOutputPlugin == nil && [output_plugins count] > 0 ) {
    Output *pl;
    for ( i = 0; i < [output_plugins count]; i++ ) {
      pl = [output_plugins objectAtIndex:i];
      if ([pl enabledByDefault] ) {
	selectedOutputPlugin = pl;
	[selectedOutputPlugin setEnabled:YES];
	break;
      }
    }
  }
}



+ (void)loadAllPluginBundles
{
  NSArray *searchPath;
  int i;

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
       selector:@selector(bundleDidLoad:)
	   name:NSBundleDidLoadNotification
	 object:nil];
  

  searchPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, 
						   NSAllDomainsMask, YES);

  [self loadPluginsAtPath:[[NSBundle mainBundle] resourcePath]
	includeNibs:NO];

  [self loadPluginsAtPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"UIPlugins"]
	includeNibs:YES];
  
  for ( i = 0; i < [searchPath count]; i++ ) {
    [self loadPluginsAtPath:[[[searchPath objectAtIndex:i] 
			 stringByAppendingPathComponent:getPackageName()] 
			 stringByAppendingPathComponent:@"Plugins"]
	  includeNibs:YES];
  }

  for ( i = 0; i < [registeredClasses count]; i++ )
    {
      [self _registerPluginClass:[registeredClasses objectAtIndex:i]];
    }

  [self updateOutputPlugin];
    
  {
    Input *plugin;
    
    for ( i = 0; i < [input_plugins count]; i++ ) {
      plugin = [input_plugins objectAtIndex:i];
      if ( [config pluginEnabledIsSet:plugin] == NO 
	   && [plugin enabledByDefault] )
	[plugin setEnabled:YES];
    }
  }
}

+ (void)sendNotification:(NSString *)name 
	      withNumber:(NSNumber *)num 
                   named:(NSString *)numberName
{
  NSDictionary *info;
  info = [NSDictionary dictionaryWithObjectsAndKeys:num, numberName, nil];
  [[NSNotificationCenter defaultCenter]
    postNotificationName:name
                  object:nil
                userInfo:info];
}

 
@end

void mysleep(unsigned int microseconds)
{
  NSDate *date;
  date = [NSDate dateWithTimeIntervalSinceNow:microseconds/10000];    
  [NSThread sleepUntilDate:date];
}

#import "Control.h"
#import "MXAConfig.h"
#import "PlaylistEntry.h"
#import "Plugins.h"


static NSDictionary *currentSongInfo = nil;

NSString *ShuffleValueChangedNotification = @"ShuffleValueChangedNotification";
NSString *RepeatValueChangedNotification = @"RepeatValueChangedNotification";
NSString *TimerModeValueChangedNotification = @"RepeatValueChangedNotification";
NSString *DefaultVisualizationChangedNotification = @"DefaultVisualizationChangedNotification";
NSString *UserInterfaceChangedNotification = @"UserInterfaceChangedNotification";
NSString *VolumeChangedNotification = @"VolumeChangedNotification";
NSString *BalanceChangedNotification = @"BalanceChangedNotification";

@implementation Control

+ (void)initializeControl
{
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
    selector:@selector(songEnded:)
    name:SongEndedNotification
    object:nil];

  [[NSNotificationCenter defaultCenter] 
    addObserver:self
    selector:@selector(songCompleted:)
    name:SongCompletedNotification
    object:nil];
  
  [[NSNotificationCenter defaultCenter] 
    addObserver:self
    selector:@selector(songStarted:)
    name:SongStartedNotification
    object:nil];
}

/*
+ (void)initialize
{
  if ( [self class] == [Control class] )
    {
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      [self initializeControl];
      [pool release];
    }
}
*/

+ (void)songStarted:(NSNotification *)notification
{
  [currentSongInfo release];
  currentSongInfo = [[notification userInfo] retain];
}

+ (void)songEnded:(NSNotification *)notification
{
  [currentSongInfo release];
  currentSongInfo = nil;
}

+ (void)songCompleted:(NSNotification *)notification
{
  if ( [config noplaylist_advance] == YES ) 
    {
      if ( [config repeat] )
	[self play];
    } 
  else
    {
      if ( [config repeat] )
	[self play];
      else
	[self nextSong];
    }
}

+ (void)setVolume:(int)value
{
  [config setvolume:value];
  [Input updateVolume];
  [Plugin sendNotification:VolumeChangedNotification
	        withNumber:[NSNumber numberWithInt:value]
	             named:@"volume"];
}

+ (int)getVolume
{
  return [config volume];
}

+ (void)setBalance:(int)value
{
  [config setbalance:value];
  [Input updateVolume];
  [Plugin sendNotification:BalanceChangedNotification
	        withNumber:[NSNumber numberWithInt:value]
	             named:@"balance"];
}

+ (int)getBalance
{
  return [config balance];
}


+ (int)getPlayingSongLength
{
  NSNumber *num =  [currentSongInfo objectForKey:@"length"];
  return num != nil ? [num intValue] : -1;
}

+ (void)seekToTime:(int)time
{
  [Input seek:time];
}

+ (void)popupFileInfoBox:(NSString *)filename
{
  [Input fileInfoBox:filename];
}

+ (void)popupFileInfoBox
{
  if ( [Input isPlaying] )
    [self popupFileInfoBox:[Input playingFile]];
}

+ (void)applyEQ
{
  [Input setEq];
}

+ (void)addFilesToPlaylist:(NSArray *)files
{
  [Playlist addFiles:files];
}

+ (void)addAndPlayFile:(NSString *)file
{
  unsigned int pos = [self getPlaylistLength];
  [Playlist addFile:file];
  [config setplaylist_position:pos];
  [Control play];
}

+ (void)newPlaylist
{
  [Playlist newPlaylist];
  [config setcurrent_playlist:@""];  
}

+ (unsigned int)getPlaylistLength
{
  return [Playlist count];
}

+ (unsigned int)getPlaylistPosition
{
  return [config playlist_position];
}

+ (PlaylistEntry *)getPlaylistEntryAt:(int)idx
{
  return [Playlist entryAtIndex:idx];
}

+ (void)randomizePlaylist
{
  [Playlist randomize];
}

+ (void)reversePlaylist
{
  [Playlist reverse];
}

+ (void)sortPlaylistByPathPlusFileName
{
  [Playlist sortByPathPlusFileName];
}

+ (void)sortPlaylistByFilename
{
  [Playlist sortByFilename];
}

+ (void)sortPlaylistByTitle
{
  [Playlist sortByTitle];
}

+ (NSArray *)getPlaylistSelection
{
  return [Playlist selectedItems];
}

+ (void)updatePlaylistInfoInThread:(int)startidx :(int)endidx :forObject
{
  [Playlist updateEntryInfoInThread:startidx :endidx :forObject];
}

+ (void)selectPlaylistEntriesWithIndexes:(NSArray *)nsnumbers
{
  [Playlist selectItemsWithIndexes:nsnumbers];
}

+ (void)clearPlaylistSelection
{
  [Playlist clearSelection];
}

+ (void)setPlaylistShuffle:(BOOL)isOn
{
  [config setshuffle:isOn];
  [Playlist setShuffle:isOn];

  [Plugin sendNotification:ShuffleValueChangedNotification
	        withNumber:[NSNumber numberWithBool:isOn]
	             named:@"shuffle"];
}

+ (BOOL)getPlaylistShuffle
{
  return [config shuffle];
}

+ (void)setRepeat:(BOOL)val
{
  [config setrepeat:val];
  
  [Plugin sendNotification:RepeatValueChangedNotification
	        withNumber:[NSNumber numberWithBool:val]
	             named:@"repeat"];
}

+ (BOOL)getRepeat
{
  return [config repeat];
}

+ (void)setTimerMode:(TimerMode)mode
{
  [config settimer_mode:mode];
  [Plugin sendNotification:TimerModeValueChangedNotification
	  withNumber:[NSNumber numberWithInt:mode]
	  named:@"mode"];
}

+ (TimerMode)getTimerMode
{
  return [config timer_mode];
}

+ (void)play
{
  if ( [Playlist count] ) 
    {
      if ( [config playlist_position] > [Playlist count] ) 
	{
	  [config setplaylist_position:0];
	}
    
      [Input playFile:
	       [[Playlist entryAtIndex:[config playlist_position]] filename]];
    }
}

+ (void)stop
{
  [Input stop];
}

+ (void)pause
{
  [Input pause];
}

+ (void)nextSong
{
  if ( [Playlist count] ) 
    {
      if ( [Input isPlaying] )
	[Input stop];
      [Playlist next];
      [self play];
    }
}

+ (void)previousSong
{
  if ( [Playlist count] ) 
    {
      if ( [Input isPlaying] )
	[Input stop];
      [Playlist prev];
      [self play];
    }
}

+ (BOOL)songIsPlaying
{
  return [Input isPlaying];
}

+ (BOOL)songIsPaused
{
  return [Input isPaused];
}

+ (NSString *)getTimeString
{
  int time, length;
  char sign;

  if ( [Input isPlaying] ) 
    {
      time = [Input getTime];
      if ( time != -1 ) 
	{
	  length = [Control getPlayingSongLength];

		
	  if ( [config timer_mode] == TIMER_REMAINING && length != -1 ) 
	    {
	      time = length-time;
	      sign = '-';
	    } 
	  else
	    sign = ' ';
  
	  time /= 1000;
	
	  if(time < 0)
	    time = 0;
	  if(time > 99 * 60)
	    time /= 60;
	
	  return [NSString stringWithFormat:@"%c%-2.2d:%-2.2d", 
			   sign, 
			   time/60,
			   time%60];
	}
    }
  return @"00:00";
}


@end

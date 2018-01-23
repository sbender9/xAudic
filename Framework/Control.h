#import <Foundation/NSString.h>
#import "Common.h"

@class PlaylistEntry;

@interface Control : NSObject

+ (void)initializeControl;

// values: 0 - 100
+ (void)setVolume:(int)value;

+ (int)getVolume;

// values: -100 - 100, 0 is center
+ (void)setBalance:(int)value;

+ (int)getBalance;

+ (int)getPlayingSongLength;

+ (void)seekToTime:(int)time;

+ (void)popupFileInfoBox:(NSString *)filename;

+ (void)popupFileInfoBox;

+ (void)applyEQ;

+ (void)addFilesToPlaylist:(NSArray *)files;

+ (void)addAndPlayFile:(NSString *)file;

+ (void)newPlaylist;

+ (unsigned int)getPlaylistLength;

+ (PlaylistEntry *)getPlaylistEntryAt:(int)idx;

+ (unsigned int)getPlaylistPosition;

+ (void)updatePlaylistInfoInThread:(int)startidx :(int)endidx :forObject;

+ (void)randomizePlaylist;

+ (void)reversePlaylist;

+ (void)sortPlaylistByPathPlusFileName;

+ (void)sortPlaylistByFilename;

+ (void)sortPlaylistByTitle;

+ (NSArray *)getPlaylistSelection;

+ (void)selectPlaylistEntriesWithIndexes:(NSArray *)nsnumbers;

+ (void)clearPlaylistSelection;

+ (void)setPlaylistShuffle:(BOOL)isOn;

+ (BOOL)getPlaylistShuffle;

+ (void)setRepeat:(BOOL)val;

+ (BOOL)getRepeat;

+ (TimerMode)getTimerMode;

+ (void)setTimerMode:(TimerMode)mode;

+ (void)play;

+ (void)stop;

+ (void)pause;

+ (void)nextSong;

+ (void)previousSong;

+ (BOOL)songIsPlaying;

+ (BOOL)songIsPaused;

+ (NSString *)getTimeString;

@end

// Sent when a song starts playing.
//
//  userInfo:
//    title = the title of the song
//    length = the length of the song in seconds FIXME:??seconds
//    frequency = the sample rate
//    numChannels = the number of channels (1 or 2)
//    fileName = the path to the file

extern NSString *SongStartedNotification;


// Sent when a song stops for any reason
// no userInfo

extern NSString *SongEndedNotification;


// Sent when a song plays all the way to the end
// no userInfo

extern NSString *SongCompletedNotification;

// Sent when a song is paused or un-paused
// 
// userInfo:
//   status = STATUS_PAUSED or STATUS_PLAY or STATUS_STOP

extern NSString *PlayStatusChangedNotification;


// Sent when the bitrate changes for a VBR MP3
//
// userInfo:
//   rate = the new bitrate

extern NSString *BitrateChangedNotification;

// Send when song suffling is turned on or off
// userInfo:
//   shuffle = true or false

extern NSString *ShuffleValueChangedNotification;

// Send when repeat turned on or off
// userInfo:
//   repeat = true or false

extern NSString *RepeatValueChangedNotification;

// Send when the timer mode is changed
// userInfo:
//  mode  = TIMER_ELAPSED or TIMER_REMAINING

extern NSString *TimerModeValueChangedNotification;

// Send when the visualization type is changed
// userInfo:
//  visualization = the Visualization plugin

extern NSString *DefaultVisualizationChangedNotification;

// Sent when the selected user interface changes
// userInfo:
//   old = the old UserInterface
//   new = the new UserInterface

extern NSString *UserInterfaceChangedNotification;

// Sent when the volume changes
// userInfo:
//   volume = NSNumber between 0 and 100%

extern NSString *VolumeChangedNotification;

// Sent when the volume changes
// userInfo:
//   balance = NSNumber between -100 and 100, 0 being center

extern NSString *BalanceChangedNotification;


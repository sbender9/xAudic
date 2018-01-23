/*  
 *  xAudic - an audio player for MacOS X
 *  Copyright (C) 1999  Scott P. Bender (sbender@harmony-ds.com)
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
#import "PlaylistEntry.h"
#import "Common.h"
#import "MXAConfig.h"
#import "Plugins.h"
#import "id3funcs.h"
#import <AppKit/NSView.h>

NSMutableArray *playlist = nil, *shuffleList = nil;
NSMutableArray *artists = nil;
int shufflePos = 0;

NSString *PlaylistChangedNotification = @"PlaylistChangedNotification";
NSString *PlaylistSelectionChangedNotification = 
   @"PlaylistSelectionChangedNotification";
NSString *NewPlaylistNotification = @"NewPlaylistNotification";

static BOOL disableNotifications = NO;
static BOOL playlistModified = NO;

@implementation PlaylistEntry

- initWithFileName:(NSString *)_filename
	     title:(NSString *)_title
	    length:(int)_length
{
  [self setFilename:_filename];
  [self setTitle:_title];
  [self setLength:_length];
  return [super init];
}

- initWithFileName:(NSString *)_filename
{
  return [self initWithFileName:_filename title:nil length:-1];
}

- (BOOL)infoLoaded
{
  return info_loaded;
}

- (void)loadInfo
{
  if ( info_loaded == NO ) {
    [Input getSongInfo:filename entry:self];
    info_loaded = YES;
  }
}

- (NSString *)filename
{
  return filename;
}

- (NSString *)title
{
  return title;
}

- (int)length
{
  return length;
}

- (void)setFilename:(NSString *)val
{
  [filename release];
  filename = [val retain];
}

 - (void)setTitle:(NSString *)val
{
  [title release];
  title = [val retain];
}

- (void)setLength:(int)val
{
  length = val;
}

- (int)selected
{
  return selected;
}

- (void)setSelected:(BOOL)val
{
  selected = val;
}

- (void)setAlbum:(Album *)val
{
  album = val;
}

- (void)setArtistName:(NSString *)val
{
  artistName = [val retain];
  
}

- (void)setAlbumName:(NSString *)val
{
  albumName = [val retain];
}

- (void)setSongName:(NSString *)val
{
  songName = [val retain];
}

- (NSString *)albumName
{
  return albumName;
}

- (NSString *)artistName
{
  return artistName;
}

- (NSString *)songName
{
  return songName;
}

- (void)dealloc
{
  [artistName release];
  [albumName release];
  [title release];
  [filename release];
  [songName release];
  [super dealloc];
}

- properyList
{
  return [NSDictionary dictionaryWithObjectsAndKeys:filename, @"filename",
	   songName ? songName : @"", @"songName", nil];
}

- (NSString *)description
{
  return [[self properyList] description];
}


@end

@interface InfoUpdaterThreadInfo : NSObject
{
@public
  NSLock *lock;
  BOOL stopRequested; 
  unsigned int start_idx;
  unsigned int end_idx;
  id forObject;
}
@end
@implementation InfoUpdaterThreadInfo
@end

@implementation Playlist

+ (NSMutableArray *)playlist
{
  if ( playlist == nil && config != nil )  
    {
      if ( [[config current_playlist] length] )
	[self loadPlaylist:[config current_playlist]];
      else
	playlist = [[NSMutableArray array] retain];
    }
  return playlist;
}

+ (NSArray *)artists
{
  return artists;
}

+ (NSMutableArray *)makeShuffledList
{
  int i, rannum, *order;
  NSMutableArray *res;
  
  srand(time(0));
  res = [[NSMutableArray array] retain];

  if ( [playlist count] > 1 ) {
    order = (int *)malloc(([playlist count] + 1) * sizeof(int));

    for (i = 0; i < [playlist count]; i++) {
      order[i] = i;
    }
    
    for (i = 0; i < [playlist count]; i++) {
      rannum = (rand() % ([playlist count] * 4 - 4)) / 4;
      rannum += (rannum >= i);
      order[i] ^= order[rannum];
      order[rannum] ^= order[i];
      order[i] ^= order[rannum];
    }
    
    for ( i = 0; i < [playlist count]; i++ ) {
      [res addObject:[NSNumber numberWithInt:order[i]]];
    }

    free(order);

  } else if ( [playlist count] )
    [res addObject:[NSNumber numberWithInt:0]];
   
  return res;
}

+ (void)makeShuffleList
{
  if ( [config shuffle] == NO )
    return;

  [shuffleList release];
  shuffleList = [self makeShuffledList];
}

+ (void)randomize
{
  NSMutableArray *s, *shuffled;
  int i;

  [self clearSelection];

  shuffled = [NSMutableArray array];
  s = [self makeShuffledList];
  for ( i = 0; i < [s count]; i++ )
    {
      NSNumber *idx = [s objectAtIndex:i];
      [shuffled addObject:[playlist objectAtIndex:[idx intValue]]];
    }
  [playlist release];
  playlist = [shuffled retain];
  [self playlistChanged];
}

+ (void)reverse
{
  NSMutableArray *reversed;
  int i;

  [self clearSelection];

  reversed = [NSMutableArray array];
  for ( i = [playlist count]-1; i >= 0; i--)
    {
      [reversed addObject:[playlist objectAtIndex:i]];
    }
  [playlist release];
  playlist = [reversed retain];
  [self playlistChanged];
}

int sort_func(id _one, id _two, void *context)
{
  int by = (int)context;
  NSString *left, *right;
  PlaylistEntry *one = _one, *two = _two;

  switch(by)
    {
    case 0:
      {
	ID3Tag *tag;

	if ( [one infoLoaded] == NO )
	  {
	    tag = id3_create_tag([one filename]);
	    left = id3_get_field_text(tag, ID3FID_TITLE);
	    id3_delete_tag(tag);
	  }
	else
	  left = [one title];

	if ( left == nil )
	  left = [one filename];

	if ( [two infoLoaded] == NO )
	  {
	    tag = id3_create_tag([two filename]);
	    right = id3_get_field_text(tag, ID3FID_TITLE);
	    id3_delete_tag(tag);
	  }
	else
	  right = [two title];

	if ( right == nil )
	  right = [two filename];
      }
      break;
    case 1:
      left = [[one filename] lastPathComponent];
      right = [[two filename] lastPathComponent];
      break;
    default:
    case 2:
      left = [one filename];
      right = [two filename];
      break;
    }

  return [left compare:right];
}

+ (void)sortBy:(int)type
{
  NSData *hint = [playlist sortedArrayHint];
  NSMutableArray *res;
  NSArray *sorted;

  [self clearSelection];

  sorted = [playlist sortedArrayUsingFunction:sort_func 
		                      context:(void*)0
 		                         hint:hint];

  res = [NSMutableArray array];
  [res addObjectsFromArray:sorted];
  [playlist release];
  playlist = [res retain];
  [self playlistChanged];
}

+ (void)sortByTitle
{
  [self sortBy:0];
}

+ (void)sortByFilename
{
  [self sortBy:1];
}

+ (void)sortByPathPlusFileName
{
  [self sortBy:2];
}

+ (void)addFile:(NSString *)path
{
  PlaylistEntry *entry;

  if ( [[path pathExtension] isEqualToString:@"pls"] ) {
    // SHOUTCAST playlist
    char *line;
    const char *cpath = [path fileSystemRepresentation];
    int numEntries, i;
    NSString *key;
    
    line = read_ini_string(cpath, "playlist", "NumberOfEntries");
    if ( line == 0 )
      return;
    numEntries = atoi(line);
    free(line);
    for ( i = 1; i <= numEntries; i++ ) {
      key = [NSString stringWithFormat:@"File%d", i];
      line = read_ini_string(cpath, "playlist", [key cString]);
      if ( line != 0 ) {
	[self addFile:[NSString stringWithCString:line]];
	free(line);
      }
    }
  } else {
    entry = [[PlaylistEntry alloc] initWithFileName:path];
    [[self playlist] addObject:entry];

    if ( disableNotifications == NO )
      [entry loadInfo];

    /*
    if ( [config useArtistBrowser] ) {
      Artist *artist;
      NSString *artistName;

      [entry loadInfo];

      if ( artists == nil )
	artists = [[NSMutableArray array] retain];

      artistName = [entry artistName];
      if ( artistName == nil ) {
	artistName = @"Unknown";
      }
      artist = [self findArtist:artistName];
      if ( artist == nil ) {
	artist = [[Artist alloc] initWithName:artistName];
	[artists addObject:artist];
      }
      [artist addSong:entry];
    }
    */
  }

  [self playlistChanged];
}

+ (Artist *)findArtist:(NSString *)name
{
  int i;
  Artist *artist;
  
  for ( i = 0; i < [artists count]; i++ ) {
    artist = [artists objectAtIndex:i];
    if ( [[artist name] isEqualToString:name] )
      return artist;
  }
  return nil;
}

+ (void)addFiles:(NSArray *)files
{
  int i;
  NSFileManager *fm = [NSFileManager defaultManager];

  disableNotifications = YES;
  for ( i = 0; i < [files count]; i++ ) 
    {
      BOOL isDir;
      NSString *path = [files objectAtIndex:i];
      [fm fileExistsAtPath:path isDirectory:&isDir];
      if ( isDir )
	[self addDirectory:path];
      else
	[self addFile:path];
    }
  disableNotifications = NO;
  [self playlistChanged];
}

+ (void)addDirectory:(NSString *)path
{
  NSDirectoryEnumerator *de;
  NSString *entry;
  NSDictionary *attrs;

  de = [[NSFileManager defaultManager] enumeratorAtPath:path];
  
  disableNotifications = YES;

  while ( entry = [de nextObject] ) {
    attrs = [de fileAttributes];
    if ( [attrs fileType] == NSFileTypeDirectory ) {
      [self addDirectory:[path stringByAppendingPathComponent:entry]];
    } else {
      [self addFile:[path stringByAppendingPathComponent:entry]];
    }
  }

  disableNotifications = NO;
  [self playlistChanged];
  [self selectionChanged];
}

+ (void)removeSelected
{
  NSArray *sel = [self selectedItems];
  int i;

  for ( i = 0; i < [sel count]; i++ ) 
    {
      PlaylistEntry *entry = [sel objectAtIndex:i];
      [[self playlist] removeObject:entry];
    }

  if ( [config playlist_position] > [[self playlist] count] )
    [config setplaylist_position:[[self playlist] count]-1];

  [self playlistChanged];
  [self selectionChanged];
}

+ (void)removeAll
{
  [[self playlist] removeAllObjects];
  [config setplaylist_position:0];
  [self playlistChanged];
  [self selectionChanged];
}

+ (void)crop
{
  NSArray *np;
  np = [self selectedItems];
  [playlist release];
  playlist = [np retain];
  [config setplaylist_position:0];
  [self playlistChanged];
}


+ (void)selectAll
{
  int i;
  
  for ( i = 0; i < [playlist count]; i++ ) {
    [[[self playlist] objectAtIndex:i] setSelected:YES];
  }
  [self selectionChanged];
}

+ (void)selectItemsWithIndexes:(NSArray *)nsnumbers
{
  int i;
  NSNumber *_idx;
  NSArray *playlist = [self playlist];

  disableNotifications = YES;
  [self clearSelection];

  for ( i = 0; i < [nsnumbers count]; i++ )
    {
      int idx;
      _idx = [nsnumbers objectAtIndex:i];
      idx = [_idx intValue];
      if ( idx < 0 || idx > [playlist count] )
	NSLog(@"%@: Invalid playlist selection index: %d", 
	      getPackageName(), idx);
      else
	[[self entryAtIndex:idx] setSelected:YES];
    }
  disableNotifications = NO;
  [self selectionChanged];
}

+ (void)clearSelection
{
  NSArray *s = [self selectedItems];
  int i;
  
  for ( i = 0; i < [s count]; i++ ) {
    [[s objectAtIndex:i] setSelected:NO];
  }
  [self selectionChanged];
}

+ (void)invertSelection
{
  int i;
  PlaylistEntry *e;

  for ( i = 0; i < [self count]; i++ ) {
    e = [self entryAtIndex:i];
    [e setSelected:![e selected]];
  }
  [self selectionChanged];
}

+ (void)selectionChanged
{
  if ( disableNotifications == NO )
    [[NSNotificationCenter defaultCenter]
      postNotificationName:PlaylistSelectionChangedNotification object:nil];
}

+ (void)playlistChanged
{
  playlistModified = YES;
  if ( disableNotifications == NO ) {
    [self makeShuffleList];
    [[NSNotificationCenter defaultCenter]
      postNotificationName:PlaylistChangedNotification object:nil];
  }
}

+ (void)newPlaylistNotification
{
  if ( disableNotifications == NO ) {
    [self makeShuffleList];
    [[NSNotificationCenter defaultCenter]
      postNotificationName:NewPlaylistNotification object:nil];
  }
}


+ (NSArray *)selectedItems
{
  int i;
  PlaylistEntry *entry;
  NSMutableArray *array = [NSMutableArray array];
  
  for ( i = 0; i < [self count]; i++ ) {
    entry = [self entryAtIndex:i];
    if ( [entry selected] )
      [array addObject:entry];
  }
  return array;
}

+ (NSArray *)selectedItemIndexes
{
  int i;
  PlaylistEntry *entry;
  NSMutableArray *array = [NSMutableArray array];
  
  for ( i = 0; i < [self count]; i++ ) {
    entry = [self entryAtIndex:i];
    if ( [entry selected] )
      [array addObject:[NSNumber numberWithInt:i]];
  }
  return array;
}

+ (unsigned int)minSelectedIndex
{
  return [[[self selectedItemIndexes] objectAtIndex:0] intValue];
}

+ (unsigned int)maxSelectedIndex
{
  NSArray *idxs = [self selectedItemIndexes];
  
  return [[idxs objectAtIndex:[idxs count]-1] intValue];
}

+ (void)moveSelectionToIndex:(unsigned int)idx
{
  NSArray *selected;
  NSArray *selectedIndexes;
  int i, off, c;

  if ( idx < 0 || idx >= [self count] )
    return;

  selectedIndexes = [self selectedItemIndexes];
  selected = [self selectedItems];
  disableNotifications = YES;
  [self removeSelected];

  off = [[selectedIndexes objectAtIndex:0] intValue];
  for ( i = 0; i < [selectedIndexes count]; i++ ) {
    c = [[selectedIndexes objectAtIndex:i] intValue];
    [playlist insertObject:[selected objectAtIndex:i] atIndex:idx+c-off];
  }

  disableNotifications = NO;
  [self playlistChanged];
}

+ (NSArray *)loadPlaylist:(NSString *)path
{
  NSFileHandle *fh;
  int i, start;
  NSString *s;
  NSString *playlist_directory;

  playlist_directory = [path stringByDeletingLastPathComponent];
  [playlist release];
  playlist = [[NSMutableArray array] retain];

  disableNotifications = YES;
  fh = [NSFileHandle fileHandleForReadingAtPath:path];
  if ( fh != nil ) {
    NSData *data;
    const char *bytes;
    data = [fh readDataToEndOfFile];
    [fh closeFile];
    bytes = [data bytes];
    i = 0;
    while (i < [data length] ) {
      char c;
      start = i;
      while (bytes[i] != '\n' && i < [data length])
	i++;
      s = [NSString stringWithCString:bytes+start length:i-start];
      c = [s characterAtIndex:0];
      if ( c != '#' )
	{
	  if ( c == '.' || c != '/' )
	    {
	      s = [playlist_directory stringByAppendingPathComponent:s];
	      s = [s stringByStandardizingPath];
	    }
	  [self addFile:s];
	}
      i++;
    }
  }
  disableNotifications = NO;
  [self newPlaylistNotification];
  playlistModified = NO;

  return playlist;
}

+ (BOOL)savePlaylist:(NSString *)path
{
  NSFileHandle *fh;
  NSFileManager *fm = [NSFileManager defaultManager];
  int i;

  if ( [fm fileExistsAtPath:path] == NO ) {
    if ( [fm createFileAtPath:path contents:nil attributes:nil] == NO )
      return NO;
  }

  fh = [NSFileHandle fileHandleForWritingAtPath:path];
  if ( fh != nil ) {
    [fh truncateFileAtOffset:0];
    for ( i = 0; i < [playlist count]; i++ ) {
      [fh writeData:[[[[playlist objectAtIndex:i] filename] 
		       stringByAppendingString:@"\n"]
			     dataUsingEncoding:[NSString defaultCStringEncoding]]];
    }
    [fh closeFile];
    playlistModified = NO;
    return YES;
  }
  return NO;
}

+ (void)newPlaylist
{
  [playlist release];
  playlist = [[NSMutableArray array] retain];
  [self playlistChanged];
}

+ (PlaylistEntry *)entryAtIndex:(unsigned int)idx
{
  return [[self playlist] objectAtIndex:idx];
}

+ (void)next
{
  if ( [self count] ) {
    if ( shuffleList == nil ) {
      if ( [config playlist_position] >= [Playlist count]-1 )
	[config setplaylist_position:0];
      else
	[config setplaylist_position:[config playlist_position]+1];
    } else {
      if ( shufflePos >= [Playlist count]-1 ) {
	[config setplaylist_position:[[shuffleList objectAtIndex:0] intValue]];
	shufflePos = 0;
      } else {
	[config setplaylist_position:[[shuffleList objectAtIndex:++shufflePos]
				    intValue]];
      }
    }
  }
}

+ (void)prev
{
  if ( [self count] ) {
    if ( shuffleList == nil ) {
      if ( [config playlist_position] == 0 
	   || [config playlist_position] > [Playlist count] )
	[config setplaylist_position:[Playlist count]-1];
      else
	[config setplaylist_position:[config playlist_position]-1];
    } else {
      if ( shufflePos == 0 || shufflePos > [Playlist count] ) {
	[config setplaylist_position:
      	       [[shuffleList objectAtIndex:[shuffleList count]-1] intValue]];
	shufflePos = [shuffleList count]-1;
      } else {
	[config setplaylist_position:[[shuffleList objectAtIndex:--shufflePos]
				    intValue]];
      }
    }
  }
}
 
+ (void)setShuffle:(BOOL)val
{
  if ( val ) {
    [self makeShuffleList];
  } else {
    [shuffleList release];
    shuffleList = nil;
  }
  shufflePos = 0;
}

+ (unsigned int)count
{
  return [[self playlist] count];
}

+ (BOOL)modified
{
  return playlistModified;
}

static NSMutableDictionary *updaterInfo = nil;

+ (void)entryInfoUpdaterThread:(InfoUpdaterThreadInfo *)info
{
  int i;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  [info->lock lock];

  for ( i = info->start_idx; i < info->end_idx 
	  && info->stopRequested == NO; i++ ) 
    {
      if ( i < [self count] ) 
	{
	  [[self entryAtIndex:i] loadInfo];
	  if ( [info->forObject isKindOfClass:[NSView class]] )
	    [info->forObject setNeedsDisplay:YES];
	}
    }
  [info->lock unlock];
  [pool release];
}

+ (void)updateEntryInfoInThread:(int)startidx :(int)endidx :forObject
{
  InfoUpdaterThreadInfo *info;
  NSString *key = NSStringFromClass([forObject class]);

  if ( updaterInfo == nil )
    updaterInfo = [[NSMutableDictionary dictionary] retain];
  
  info = [updaterInfo objectForKey:key];
  
  if ( info != nil )
    {
      if ( [info->lock tryLock] == NO ) 
	{
	  info->stopRequested = YES;
	  [info->lock lock];
	  [info->lock unlock];
	} 
      else
	[info->lock unlock];
    }
 else
   {
     info = [[[InfoUpdaterThreadInfo alloc] init] autorelease];
     info->lock = [[NSLock alloc] init];
     [updaterInfo setObject:info forKey:key];
  }

 info->stopRequested = NO;
 info->start_idx = startidx;
 info->end_idx = endidx;
 info->forObject = forObject;

  [NSThread detachNewThreadSelector:@selector(entryInfoUpdaterThread:)
	    toTarget:self
	    withObject:info];
}


@end

@implementation Artist

- initWithName:(NSString *)_name
{
  name = [_name retain];
  items = [[NSMutableArray array] retain];
  return [super init];
}

- (void)addAlbum:(Album *)album
{
  [items addObject:album];
  [album setArtist:self];
}

- (void)addSong:(PlaylistEntry *)song
{
  Album *album;
  NSString *albumName;

  albumName = [song albumName];
  if ( albumName == nil )
    albumName = @"Unkown";
  
  album = [self findAlbum:albumName];
  if ( album == nil ) {
    album = [[Album alloc] initWithName:albumName];
    [self addAlbum:album];
  }
  [album addSong:song];
}

- objectAtIndex:(unsigned int)idx
{
  return [items objectAtIndex:idx];
}

- (unsigned int)count
{
  return [items count];
}

- (Album *)findAlbum:(NSString *)_name
{
  int i;
  Album *album;
  
  for ( i = 0; i < [items count]; i++ ) {
    album = [items objectAtIndex:i];
    if ( [[album name] isEqualToString:_name] )
      return album;
  }
  return nil;
}

- (NSString *)name
{
  return name;
}

- (void)dealloc
{
  [name release];
  [items release];
  [super dealloc];
}

- properyList
{
  int i;
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  NSMutableArray *songs = [NSMutableArray array];

  [dict setObject:name forKey:@"name"];

  for ( i = 0; i < [items count]; i++ ) {
    [songs addObject:[[items objectAtIndex:i] properyList]];
  }
  [dict setObject:songs forKey:@"albums"];
  return dict;
}

- (NSString *)description
{
  return [[self properyList] description];
}

@end

@implementation Album


- initWithName:(NSString *)_name
{
  name = [_name retain];
  items = [[NSMutableArray array] retain];
  return [super init];
}

- (void)addSong:(PlaylistEntry *)song
{
  [items addObject:song];
  [song setAlbum:self];
}

- objectAtIndex:(unsigned int)idx
{
  return [items objectAtIndex:idx];
}

- (unsigned int)count
{
  return [items count];
}

- (NSString *)name
{
  return name;
}

- (void)setArtist:(Artist *)val
{
  artist = val;
}

- (void)dealloc
{
  [name release];
  [items release];
  [super dealloc];
}

- properyList
{
  int i;
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  NSMutableArray *songs = [NSMutableArray array];

  [dict setObject:name forKey:@"name"];

  for ( i = 0; i < [items count]; i++ ) {
    [songs addObject:[[items objectAtIndex:i] properyList]];
  }
  [dict setObject:songs forKey:@"songs"];
  return dict;
}

- (NSString *)description
{
  return [[self properyList] description];
}

@end

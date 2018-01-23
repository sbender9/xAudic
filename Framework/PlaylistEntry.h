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
#import <Foundation/Foundation.h>


@class Album;
@class PlaylistEntry;

@interface Artist : NSObject
{
  NSString *name;
  NSMutableArray *items;
}

- initWithName:(NSString *)name;
- (void)addAlbum:(Album *)album;
- (void)addSong:(PlaylistEntry *)song;
- objectAtIndex:(unsigned int)idx;
- (unsigned int)count;
- (Album *)findAlbum:(NSString *)name;
- (NSString *)name;
- properyList;

@end


@interface Album : NSObject
{
  NSString *name;
  NSMutableArray *items;
  Artist *artist;
}

- initWithName:(NSString *)name;
- (void)addSong:(PlaylistEntry *)song;
- objectAtIndex:(unsigned int)idx;
- (unsigned int)count;
- (NSString *)name;
- (void)setArtist:(Artist *)val;
- properyList;
@end

@interface PlaylistEntry : NSObject
{
  NSString *filename;
  NSString *title;
  NSString *artistName;
  NSString *albumName;
  NSString *songName;
  int length;
  int selected;
  BOOL info_loaded;
  Album *album;
}

- (NSString *)filename;
- (NSString *)title;
- (NSString *)albumName;
- (NSString *)artistName;
- (NSString *)songName;
- (int)length;
- (int)selected;
- (void)loadInfo;
- (BOOL)infoLoaded;
- properyList;

- (void)setFilename:(NSString *)val;
- (void)setTitle:(NSString *)val;
- (void)setLength:(int)val;
- (void)setSelected:(BOOL)val;
- (void)setAlbum:(Album *)val;
- (void)setArtistName:(NSString *)val;
- (void)setAlbumName:(NSString *)val;
- (void)setSongName:(NSString *)val;

- initWithFileName:(NSString *)_filename
	     title:(NSString *)_title
	    length:(int)_length;
- initWithFileName:(NSString *)_filename;

@end

@interface Playlist : NSObject

+ (NSArray *)selectedItems;
+ (NSArray *)selectedItemIndexes;
+ (unsigned int)minSelectedIndex;
+ (unsigned int)maxSelectedIndex;

+ (void)moveSelectionToIndex:(unsigned int)idx;

+ (void)addFile:(NSString *)path;
+ (void)addFiles:(NSArray *)files;
+ (void)addDirectory:(NSString *)path;
+ (BOOL)savePlaylist:(NSString *)path;
+ (NSArray *)loadPlaylist:(NSString *)path;
+ (void)newPlaylist;

+ (void)removeSelected;
+ (void)removeAll;
+ (void)crop;

+ (void)updateEntryInfoInThread:(int)startidx :(int)endidx :forObject;

+ (void)selectAll;
+ (void)selectItemsWithIndexes:(NSArray *)nsnumbers;
+ (void)clearSelection;
+ (void)invertSelection;
+ (void)selectionChanged;
+ (void)playlistChanged;

+ (PlaylistEntry *)entryAtIndex:(unsigned int)idx;
+ (unsigned int)count;

+ (void)setShuffle:(BOOL)val;

+ (void)next;
+ (void)prev;

+ (BOOL)modified;

+ (Artist *)findArtist:(NSString *)name;

+ (NSArray *)artists;

+ (void)randomize;
+ (void)reverse;

+ (void)sortByPathPlusFileName;
+ (void)sortByFilename;
+ (void)sortByTitle;

@end

extern NSString *PlaylistChangedNotification;
extern NSString *NewPlaylistNotification;
extern NSString *PlaylistSelectionChangedNotification;

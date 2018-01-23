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

#import "BrowserPlaylistList.h"
#import <MXA/PlaylistEntry.h>

@implementation BrowserPlaylistList

- initWithFrame:(NSRect)frame target:target action:(SEL)_action 
					    slider:_slider
{
  [super initWithFrame:frame];
  [self setDelegate:self];
  [self loadColumnZero];
  [self setHasHorizontalScroller:YES];
  [self setMaxVisibleColumns:3];
  [self setTakesTitleFromPreviousColumn:YES];
  return self;
}

- (void)centerCurrentIfNeeded
{
}

- (void)centerCurrent:(BOOL)force
{
}

- (void)scrollUp
{
}

- (void)scrollDown
{
}

- (void)scrollTo:(int)pos
{
}

- (int)selected
{
  return 0;
}

- (Artist *)selectedArtist
{
  int sel = [self selectedRowInColumn:0];
  Artist *artist;
  
  if ( sel != -1 ) {
    artist = [[Playlist artists] objectAtIndex:sel];
    return artist;
  }
  return nil;
}

- (Album *)selectedAlbum
{
  Artist *artist;

  int sel = [self selectedRowInColumn:1];
  if ( sel != -1 ) {
    artist = [self selectedArtist];
    return [artist objectAtIndex:sel];
  }
  return nil;
}

- (PlaylistEntry *)selectedSong
{
  Album *album;
  int sel;
  
  sel = [self selectedRowInColumn:2];
  if ( sel != -1 ) {
    album = [self selectedAlbum];
    if ( album != nil ) {
      return [album objectAtIndex:sel];
    }
  }
  return nil;
}

- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column
{
  if ( column == 0 )
    return [[Playlist artists] count];
  
  else if ( column == 1 ) {
    Artist *selected;
    
    selected = [self selectedArtist];
    if ( selected != nil )
      return [selected count];
  } else if ( column == 2 ) {
    Album *album = [self selectedAlbum];
    if ( album != nil )
      return [album count];
  }
  
  return 0;
}

- (void)browser:(NSBrowser *)sender 
willDisplayCell:(id)cell 
	  atRow:(int)row 
	 column:(int)column
{
  id obj;
  if ( column == 0 ) {
    obj = [[Playlist artists] objectAtIndex:row];
    [cell setStringValue:[obj name]];
    [cell setLeaf:NO];
  } else if ( column == 1 ) {
    obj = [[self selectedArtist] objectAtIndex:row];
    [cell setStringValue:[obj name]];
    [cell setLeaf:NO];
  } else if ( column == 2 ) {
    obj = [[self selectedAlbum] objectAtIndex:row];
    [cell setStringValue:[obj songName]];
    [cell setLeaf:YES];
  }
}

- (NSString *)browser:(NSBrowser *)sender titleOfColumn:(int)column
{
  if ( column == 0 )
    return @"Artists";
/*
  else if ( column == 1 )
    return [[self selectedArtist] name];
  else if ( column == 2 )
    return [[self selectedAlbum] name];
*/
}

@end
